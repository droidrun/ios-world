import Foundation

final class BankStore: ObservableObject {
    @Published var accounts: [Account]
    @Published var transactions: [Transaction]
    @Published var payees: [Payee]
    @Published var scheduledPayments: [ScheduledPayment]
    @Published var activatedOfferIds: Set<String>
    @Published var redeemedRewardPoints: Int
    @Published var creditScore: Int
    @Published var userName: String
    @Published var lastName: String
    @Published var toast: Toast?

    let ledgerService: LedgerService

    private let persistence: PersistenceService
    private let accountsService: SharedAccountsService
    private let deepLinkService: DeepLinkService
    private let transactionEngine: TransactionEngine
    private var scheduledTimer: Timer?
    private var ledgerSyncTimer: Timer?

    init(
        persistence: PersistenceService = PersistenceService(),
        ledgerService: LedgerService = LedgerService(),
        accountsService: SharedAccountsService = SharedAccountsService(),
        deepLinkService: DeepLinkService = DeepLinkService(),
        transactionEngine: TransactionEngine = TransactionEngine()
    ) {
        self.persistence = persistence
        self.ledgerService = ledgerService
        self.accountsService = accountsService
        self.deepLinkService = deepLinkService
        self.transactionEngine = transactionEngine

        if let state = persistence.loadState(), state.version >= BankState.currentVersion {
            self.accounts = state.accounts
            self.transactions = state.transactions
            self.payees = state.payees
            self.scheduledPayments = state.scheduledPayments
            self.activatedOfferIds = state.activatedOfferIds
            self.redeemedRewardPoints = state.redeemedRewardPoints
            self.creditScore = state.creditScore
            self.userName = state.userName
            self.lastName = state.lastName
        } else {
            ledgerService.clearLedger()
            self.accounts = []
            self.transactions = []
            self.payees = []
            self.scheduledPayments = []
            self.activatedOfferIds = []
            self.redeemedRewardPoints = 0
            self.creditScore = 742
            self.userName = "Jordan"
            self.lastName = "Avery"
            seedState()
        }
        accountsService.saveAccounts(accounts)

        schedulePendingPostings()
        startScheduledPaymentsTimer()
        importFromSharedLedger(silent: true)
        startLedgerSyncTimer()
    }

    deinit {
        scheduledTimer?.invalidate()
        ledgerSyncTimer?.invalidate()
    }

    func handleDeepLink(_ url: URL) {
        switch deepLinkService.parse(url: url) {
        case .success(let request):
            ingest(request: request, rawSource: url.absoluteString)
        case .failure(let error):
            showToast(message: error.localizedDescription, style: .error)
            #if DEBUG
            print("[DeepLink] Failed: \(error.localizedDescription)")
            #endif
        }
    }

    func ingest(request: IngestRequest, rawSource: String) {
        if transactions.contains(where: { $0.externalId == request.externalId }) {
            showToast(message: "Transaction already imported.", style: .info)
            #if DEBUG
            print("[Ingest] Duplicate external_id \(request.externalId)")
            #endif
            return
        }

        guard let accountId = transactionEngine.defaultAccountId(for: request.category, accounts: accounts) else {
            showToast(message: "No account available for ingestion.", style: .error)
            return
        }

        let normalizedAmount = transactionEngine.normalizedIngestAmount(request.amount)
        let transaction = Transaction(
            id: UUID(),
            externalId: request.externalId,
            accountId: accountId,
            vendor: request.vendor,
            amount: normalizedAmount,
            currency: request.currency,
            category: request.category,
            note: request.note,
            timestamp: request.timestamp,
            status: .pending,
            sourceApp: request.vendor,
            rawSource: rawSource
        )

        transactions.insert(transaction, at: 0)
        saveState()
        ledgerService.upsertRecord(transaction)
        transactionEngine.schedulePosting(for: transaction.id, in: self)
        showToast(message: "Imported transaction from \(request.vendor)", style: .success)
        #if DEBUG
        print("[Ingest] Imported \(transaction.externalId) from \(request.vendor)")
        #endif
    }

    func importFromSharedLedger(silent: Bool = false) {
        let records = ledgerService.loadLedger()
        if records.isEmpty {
            if !silent {
                showToast(message: "Shared ledger is empty.", style: .info)
            }
            return
        }

        let existingIds = Set(transactions.map { $0.externalId })
        var imported = 0
        var updatedAccounts = accounts

        for record in records where !existingIds.contains(record.externalId) && record.rawSource != "seed" {
            var adjusted = record
            if !accounts.contains(where: { $0.id == record.accountId }) {
                adjusted.accountId = transactionEngine.defaultAccountId(for: record.category, accounts: accounts) ?? accounts.first?.id ?? record.accountId
            }

            transactions.append(adjusted)
            if adjusted.status == .posted {
                transactionEngine.applyTransaction(adjusted, accounts: &updatedAccounts)
            } else {
                transactionEngine.schedulePosting(for: adjusted.id, in: self)
            }
            imported += 1
        }

        if imported > 0 {
            accounts = updatedAccounts
            saveState()
        }

        if !silent || imported > 0 {
            showToast(message: "Imported \(imported) new record(s).", style: .success)
        }
        #if DEBUG
        print("[Ledger] Imported \(imported) record(s) from shared ledger")
        #endif
    }

    func exportLedger() {
        let exportableTransactions = transactions.filter { $0.rawSource != "seed" }
        ledgerService.saveLedger(exportableTransactions)
        showToast(message: "Exported \(exportableTransactions.count) records.", style: .success)
        #if DEBUG
        print("[Ledger] Exported \(exportableTransactions.count) record(s)")
        #endif
    }

    func simulateInboundTransaction() {
        let vendors = ["QuickBite", "CityRide", "FreshCart", "Spotify", "Blue Bottle Coffee", "StayFinder"]
        let categories = ["Food", "Transport", "Groceries", "Entertainment", "Coffee", "Travel"]
        let vendor = vendors.randomElement() ?? "Vendor"
        let category = categories.randomElement() ?? "General"
        let amount = Double.random(in: 6.0...64.0)
        let request = IngestRequest(
            amount: amount,
            currency: "USD",
            vendor: vendor,
            category: category,
            note: "Simulated inbound charge",
            timestamp: Date(),
            externalId: UUID().uuidString
        )
        ingest(request: request, rawSource: "simulated")
    }

    func resetLocalState() {
        persistence.clearState()
        seedState()
        schedulePendingPostings()
        showToast(message: "Local state reset.", style: .info)
    }

    func resetAllState() {
        persistence.clearState()
        ledgerService.clearLedger()
        seedState()
        schedulePendingPostings()
        showToast(message: "Local + shared ledger reset.", style: .info)
    }

    @discardableResult
    func createTransfer(from fromId: UUID, to toId: UUID, amount: Double, note: String?) -> Bool {
        guard fromId != toId else {
            showToast(message: "Choose two different accounts.", style: .error)
            return false
        }
        guard amount > 0 else {
            showToast(message: "Enter a valid amount.", style: .error)
            return false
        }
        guard let fromAccount = accounts.first(where: { $0.id == fromId }),
              let toAccount = accounts.first(where: { $0.id == toId }) else {
            showToast(message: "Account selection not found.", style: .error)
            return false
        }
        guard fromAccount.availableBalance >= amount else {
            showToast(message: "Insufficient available balance.", style: .error)
            return false
        }

        let timestamp = Date()
        let externalIdOut = UUID().uuidString
        let externalIdIn = UUID().uuidString

        let outgoing = Transaction(
            id: UUID(),
            externalId: externalIdOut,
            accountId: fromId,
            vendor: "Transfer to \(toAccount.name)",
            amount: -amount,
            currency: fromAccount.currency,
            category: "Transfer",
            note: note,
            timestamp: timestamp,
            status: .posted,
            sourceApp: "MyBank",
            rawSource: "transfer"
        )

        let incoming = Transaction(
            id: UUID(),
            externalId: externalIdIn,
            accountId: toId,
            vendor: "Transfer from \(fromAccount.name)",
            amount: amount,
            currency: toAccount.currency,
            category: "Transfer",
            note: note,
            timestamp: timestamp,
            status: .posted,
            sourceApp: "MyBank",
            rawSource: "transfer"
        )

        transactions.insert(contentsOf: [outgoing, incoming], at: 0)
        transactionEngine.applyTransaction(outgoing, accounts: &accounts)
        transactionEngine.applyTransaction(incoming, accounts: &accounts)
        ledgerService.upsertRecord(outgoing)
        ledgerService.upsertRecord(incoming)
        saveState()
        showToast(message: "Transfer complete.", style: .success)
        let fromName = accounts.first(where: { $0.id == fromId })?.name ?? "account"
        let toName = accounts.first(where: { $0.id == toId })?.name ?? "account"
        BankMailOutboxWriter.recordTransferEmail(amount: amount, from: fromName, to: toName)
        return true
    }

    @discardableResult
    func createDeposit(to accountId: UUID, amount: Double, note: String?) -> Bool {
        guard amount > 0 else {
            showToast(message: "Enter a valid amount.", style: .error)
            return false
        }

        guard let account = accounts.first(where: { $0.id == accountId }) else {
            showToast(message: "Account not found.", style: .error)
            return false
        }

        let transaction = Transaction(
            id: UUID(),
            externalId: UUID().uuidString,
            accountId: accountId,
            vendor: "Mobile Check Deposit",
            amount: amount,
            currency: account.currency,
            category: "Deposit",
            note: note,
            timestamp: Date(),
            status: .posted,
            sourceApp: "MyBank",
            rawSource: "deposit"
        )

        transactions.insert(transaction, at: 0)
        transactionEngine.applyTransaction(transaction, accounts: &accounts)
        ledgerService.upsertRecord(transaction)
        saveState()
        showToast(message: "Deposit added.", style: .success)
        return true
    }

    @discardableResult
    func payBill(to payeeId: UUID, amount: Double, note: String?) -> Bool {
        guard amount > 0 else {
            showToast(message: "Enter a valid amount.", style: .error)
            return false
        }

        guard let payee = payees.first(where: { $0.id == payeeId }) else {
            showToast(message: "Payee not found.", style: .error)
            return false
        }

        let succeeded = submitPayment(
            payee: payee,
            amount: amount,
            note: note,
            status: .posted,
            rawSource: "bill_pay"
        )
        if succeeded {
            showToast(message: payee.category == "Credit Card" ? "Card payment complete." : "Bill paid.", style: .success)
        }
        return succeeded
    }

    @discardableResult
    func sendZelle(to payeeId: UUID, amount: Double, note: String?) -> Bool {
        guard amount > 0 else {
            showToast(message: "Enter a valid amount.", style: .error)
            return false
        }

        guard let payee = payees.first(where: { $0.id == payeeId }) else {
            showToast(message: "Recipient not found.", style: .error)
            return false
        }

        guard let account = accounts.first(where: { $0.type == .checking }) else {
            showToast(message: "Checking account not available.", style: .error)
            return false
        }
        guard account.availableBalance >= amount else {
            showToast(message: "Insufficient available balance.", style: .error)
            return false
        }

        let transaction = Transaction(
            id: UUID(),
            externalId: UUID().uuidString,
            accountId: account.id,
            vendor: payee.name,
            amount: -amount,
            currency: account.currency,
            category: "Zelle",
            note: note,
            timestamp: Date(),
            status: .posted,
            sourceApp: "Zelle",
            rawSource: "zelle"
        )

        transactions.insert(transaction, at: 0)
        transactionEngine.applyTransaction(transaction, accounts: &accounts)
        ledgerService.upsertRecord(transaction)
        saveState()
        showToast(message: "Zelle sent.", style: .success)
        let payeeName = payees.first(where: { $0.id == payeeId })?.name ?? "recipient"
        BankMailOutboxWriter.recordZelleEmail(amount: amount, to: payeeName)
        return true
    }

    @discardableResult
    func schedulePayment(payeeId: UUID, amount: Double, scheduleDate: Date, note: String? = nil) -> Bool {
        guard amount > 0 else {
            showToast(message: "Enter a valid amount.", style: .error)
            return false
        }
        guard payees.contains(where: { $0.id == payeeId }) else {
            showToast(message: "Payee not found.", style: .error)
            return false
        }
        guard scheduleDate >= Calendar.current.startOfDay(for: Date()) else {
            showToast(message: "Choose a future payment date.", style: .error)
            return false
        }

        let scheduled = ScheduledPayment(
            id: UUID(),
            payeeId: payeeId,
            amount: amount,
            scheduleDate: scheduleDate,
            note: note,
            status: .scheduled
        )
        scheduledPayments.append(scheduled)
        saveState()
        showToast(message: "Payment scheduled.", style: .success)
        return true
    }

    func runDueScheduledPayments(reason: String) {
        guard !scheduledPayments.isEmpty else { return }
        let now = Date()
        var updated = scheduledPayments
        var executedCount = 0

        for index in updated.indices {
            if updated[index].status == .scheduled && updated[index].scheduleDate <= now {
                let payment = updated[index]
                guard canExecuteScheduledPayment(payment) else {
                    showToast(message: "Skipped a scheduled payment due to insufficient available balance.", style: .error)
                    continue
                }
                executeScheduledPayment(payment)
                updated[index].status = .executed
                executedCount += 1
            }
        }

        if executedCount > 0 {
            scheduledPayments = updated
            saveState()
            #if DEBUG
            print("[Payments] Executed \(executedCount) scheduled payment(s) (\(reason))")
            #endif
        }
    }

    func postAllPending(reason: String) {
        transactionEngine.postAllPending(in: self, reason: reason)
    }

    func saveState() {
        let state = BankState(
            accounts: accounts,
            transactions: transactions,
            payees: payees,
            scheduledPayments: scheduledPayments,
            activatedOfferIds: activatedOfferIds,
            redeemedRewardPoints: redeemedRewardPoints,
            creditScore: creditScore,
            userName: userName,
            lastName: lastName
        )
        persistence.saveState(state)
        accountsService.saveAccounts(accounts)
    }

    func toggleOffer(_ offerId: String) {
        if activatedOfferIds.contains(offerId) {
            activatedOfferIds.remove(offerId)
            showToast(message: "Offer removed.", style: .info)
        } else {
            activatedOfferIds.insert(offerId)
            showToast(message: "Offer added.", style: .success)
        }
        saveState()
    }

    @discardableResult
    func disputeTransaction(id: UUID) -> Bool {
        guard let index = transactions.firstIndex(where: { $0.id == id }) else {
            return false
        }
        transactions[index].status = .disputed
        saveState()
        showToast(message: "Dispute submitted for \(transactions[index].vendor).", style: .success)
        return true
    }

    @discardableResult
    func redeemRewards(points: Int, context: String) -> Bool {
        guard points > 0 else {
            showToast(message: "Choose a reward amount.", style: .error)
            return false
        }

        let availablePoints = max(0, Int(earnedRewardPoints) - redeemedRewardPoints)
        guard points <= availablePoints else {
            showToast(message: "Not enough available points.", style: .error)
            return false
        }

        redeemedRewardPoints += points
        saveState()
        showToast(message: "Redeemed \(points) points for \(context.lowercased()).", style: .success)
        return true
    }

    private func executeScheduledPayment(_ payment: ScheduledPayment) {
        guard let payee = payees.first(where: { $0.id == payment.payeeId }) else { return }
        submitPayment(
            payee: payee,
            amount: payment.amount,
            note: payment.note ?? "Scheduled payment",
            status: .pending,
            rawSource: "scheduled_payment"
        )
    }

    private func schedulePendingPostings() {
        for transaction in transactions where transaction.status == .pending {
            transactionEngine.schedulePosting(for: transaction.id, in: self)
        }
    }

    private func startScheduledPaymentsTimer() {
        scheduledTimer?.invalidate()
        scheduledTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.runDueScheduledPayments(reason: "timer")
        }
    }

    private func startLedgerSyncTimer() {
        ledgerSyncTimer?.invalidate()
        ledgerSyncTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.importFromSharedLedger(silent: true)
        }
    }

    private func canExecuteScheduledPayment(_ payment: ScheduledPayment) -> Bool {
        guard let checkingAccount = accounts.first(where: { $0.type == .checking }) else { return false }
        return checkingAccount.availableBalance >= payment.amount
    }

    @discardableResult
    private func submitPayment(
        payee: Payee,
        amount: Double,
        note: String?,
        status: TransactionStatus,
        rawSource: String
    ) -> Bool {
        guard let checkingAccount = accounts.first(where: { $0.type == .checking }) else {
            showToast(message: "Checking account not available.", style: .error)
            return false
        }
        guard status != .posted || checkingAccount.availableBalance >= amount else {
            showToast(message: "Insufficient available balance.", style: .error)
            return false
        }

        let timestamp = Date()
        var newTransactions: [Transaction] = [
            Transaction(
                id: UUID(),
                externalId: UUID().uuidString,
                accountId: checkingAccount.id,
                vendor: payee.name,
                amount: -amount,
                currency: checkingAccount.currency,
                category: payee.category,
                note: note,
                timestamp: timestamp,
                status: status,
                sourceApp: "MyBank",
                rawSource: rawSource
            )
        ]

        if payee.category == "Credit Card",
           let creditAccount = accounts.first(where: { $0.type == .credit }) {
            newTransactions.append(
                Transaction(
                    id: UUID(),
                    externalId: UUID().uuidString,
                    accountId: creditAccount.id,
                    vendor: "Payment from \(checkingAccount.name)",
                    amount: amount,
                    currency: creditAccount.currency,
                    category: "Payment",
                    note: note,
                    timestamp: timestamp,
                    status: status,
                    sourceApp: "MyBank",
                    rawSource: rawSource
                )
            )
        }

        transactions.insert(contentsOf: newTransactions, at: 0)

        if status == .posted {
            for transaction in newTransactions {
                transactionEngine.applyTransaction(transaction, accounts: &accounts)
                ledgerService.upsertRecord(transaction)
            }
        } else {
            for transaction in newTransactions {
                ledgerService.upsertRecord(transaction)
                transactionEngine.schedulePosting(for: transaction.id, in: self)
            }
        }

        saveState()
        return true
    }

    private var earnedRewardPoints: Double {
        transactions
            .filter { transaction in
                guard let creditAccount = accounts.first(where: { $0.type == .credit }) else { return false }
                return transaction.accountId == creditAccount.id && transaction.amount < 0 && transaction.status == .posted
            }
            .reduce(0) { $0 + abs($1.amount) * 100 }
    }

    private func seedState() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()

        // All seed dates were authored relative to March 9 2026 19:22 ET.
        // Shift them so the most-recent transactions land on today.
        let anchorComponents = DateComponents(
            timeZone: TimeZone(identifier: "America/New_York"),
            year: 2026, month: 3, day: 9, hour: 19, minute: 22
        )
        let anchor = calendar.date(from: anchorComponents) ?? now
        let shift = now.timeIntervalSince(anchor)

        func fixedDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
            let components = DateComponents(
                timeZone: TimeZone(identifier: "America/New_York"),
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
            let raw = calendar.date(from: components) ?? Date()
            return min(raw.addingTimeInterval(shift), now)
        }

        func futureDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
            let components = DateComponents(
                timeZone: TimeZone(identifier: "America/New_York"),
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
            let raw = calendar.date(from: components) ?? Date()
            return raw.addingTimeInterval(shift)
        }
        let checkingId = UUID()
        let savingsId = UUID()
        let creditId = UUID()
        let zellePayeeId = UUID()
        let zelleRequestPayeeId = UUID()
        let utilitiesPayeeId = UUID()
        let internetPayeeId = UUID()
        let waterPayeeId = UUID()
        let phonePayeeId = UUID()
        let insurancePayeeId = UUID()
        let creditCardPayeeId = UUID()

        let checking = Account(
            id: checkingId,
            name: "Total Checking (...6645)",
            type: .checking,
            balance: 15621.00,
            availableBalance: 15621.00,
            currency: "USD",
            lastUpdated: now,
            creditLimit: nil
        )
        let savings = Account(
            id: savingsId,
            name: "Savings (...1032)",
            type: .savings,
            balance: 4920.50,
            availableBalance: 4920.50,
            currency: "USD",
            lastUpdated: now,
            creditLimit: nil
        )
        let creditLimit = 8000.00
        let creditBalance = 4588.98
        let credit = Account(
            id: creditId,
            name: "Freedom Unlimited (...2095)",
            type: .credit,
            balance: creditBalance,
            availableBalance: creditLimit - creditBalance,
            currency: "USD",
            lastUpdated: now,
            creditLimit: creditLimit
        )

        accounts = [checking, savings, credit]

        transactions = [
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_mar9",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -31.40,
                currency: "USD",
                category: "Food & drink",
                note: "Chipotle",
                timestamp: fixedDate(year: 2026, month: 3, day: 9, hour: 19, minute: 22),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_chase_card_payment_2095",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -240.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2026, month: 3, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_chase_card_payment_received_2095",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 240.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2026, month: 3, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_northstar",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2026, month: 3, day: 1, hour: 8, minute: 31),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_jordan_rivera",
                accountId: checkingId,
                vendor: "Rohan Mehta",
                amount: -55.00,
                currency: "USD",
                category: "Zelle",
                note: "Dinner split",
                timestamp: fixedDate(year: 2026, month: 2, day: 26, hour: 19, minute: 42),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_elena_brooks",
                accountId: checkingId,
                vendor: "Elena Brooks",
                amount: 30.00,
                currency: "USD",
                category: "Zelle",
                note: "Coffee reimbursement",
                timestamp: fixedDate(year: 2026, month: 3, day: 5, hour: 9, minute: 14),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_mobile_deposit_payroll",
                accountId: checkingId,
                vendor: "Mobile Check Deposit",
                amount: 620.00,
                currency: "USD",
                category: "Deposit",
                note: "Freelance invoice",
                timestamp: fixedDate(year: 2026, month: 3, day: 2, hour: 11, minute: 7),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_rainy_day_fund",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -400.00,
                currency: "USD",
                category: "Transfer",
                note: "Rainy day fund",
                timestamp: fixedDate(year: 2026, month: 3, day: 1, hour: 9, minute: 12),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_rainy_day_fund",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 400.00,
                currency: "USD",
                category: "Transfer",
                note: "Rainy day fund",
                timestamp: fixedDate(year: 2026, month: 3, day: 1, hour: 9, minute: 12),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 3.84,
                currency: "USD",
                category: "Interest",
                note: "March interest payment",
                timestamp: fixedDate(year: 2026, month: 3, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_bill",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -112.43,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2026, month: 3, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -84.56,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2026, month: 3, day: 5, hour: 18, minute: 22),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_harbor_air",
                accountId: creditId,
                vendor: "Harbor Air",
                amount: -322.40,
                currency: "USD",
                category: "Travel",
                note: "Weekend flight",
                timestamp: fixedDate(year: 2026, month: 2, day: 28, hour: 13, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_feb28",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -58.50,
                currency: "USD",
                category: "Food & drink",
                note: "Sugarfish",
                timestamp: fixedDate(year: 2026, month: 2, day: 28, hour: 20, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_feb28",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -9.44,
                currency: "USD",
                category: "Groceries",
                note: "ALDI",
                timestamp: fixedDate(year: 2026, month: 2, day: 28, hour: 11, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_blue_bottle",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -18.22,
                currency: "USD",
                category: "Food & drink",
                note: "Morning coffee",
                timestamp: fixedDate(year: 2026, month: 3, day: 3, hour: 8, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_metro_rail_pending",
                accountId: creditId,
                vendor: "Metro Rail",
                amount: -19.75,
                currency: "USD",
                category: "Transport",
                note: "Tap to ride",
                timestamp: fixedDate(year: 2026, month: 3, day: 6, hour: 8, minute: 12),
                status: .pending,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -47.83,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 3, day: 4, hour: 17, minute: 52),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2026, month: 3, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_trip",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.38,
                currency: "USD",
                category: "Transport",
                note: "Airport to downtown",
                timestamp: fixedDate(year: 2026, month: 3, day: 2, hour: 19, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_mar2",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -63.78,
                currency: "USD",
                category: "Groceries",
                note: "Costco",
                timestamp: fixedDate(year: 2026, month: 3, day: 2, hour: 14, minute: 38),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target",
                accountId: creditId,
                vendor: "Target",
                amount: -63.17,
                currency: "USD",
                category: "Shopping",
                note: "Household essentials",
                timestamp: fixedDate(year: 2026, month: 3, day: 3, hour: 14, minute: 22),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_chipotle",
                accountId: creditId,
                vendor: "Chipotle Mexican Grill",
                amount: -28.00,
                currency: "USD",
                category: "Food & drink",
                note: "Lunch",
                timestamp: fixedDate(year: 2026, month: 3, day: 5, hour: 12, minute: 38),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_mar5",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -33.18,
                currency: "USD",
                category: "Food & drink",
                note: "Shake Shack",
                timestamp: fixedDate(year: 2026, month: 3, day: 5, hour: 20, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2026, month: 2, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_walgreens",
                accountId: creditId,
                vendor: "Walgreens",
                amount: -8.49,
                currency: "USD",
                category: "Health",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 3, day: 4, hour: 9, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_gas",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -52.10,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2026, month: 3, day: 1, hour: 16, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_pending",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -34.99,
                currency: "USD",
                category: "Shopping",
                note: "Online order",
                timestamp: fixedDate(year: 2026, month: 3, day: 6, hour: 10, minute: 45),
                status: .pending,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_venmo_camille",
                accountId: checkingId,
                vendor: "SplitPay - Camille H.",
                amount: -42.00,
                currency: "USD",
                category: "Zelle",
                note: "Concert tickets split",
                timestamp: fixedDate(year: 2026, month: 3, day: 3, hour: 20, minute: 15),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_atm_withdrawal",
                accountId: checkingId,
                vendor: "MyBank ATM",
                amount: -60.00,
                currency: "USD",
                category: "ATM",
                note: "Cash withdrawal",
                timestamp: fixedDate(year: 2026, month: 3, day: 2, hour: 13, minute: 48),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -28.64,
                currency: "USD",
                category: "Food & drink",
                note: "Delivery order",
                timestamp: fixedDate(year: 2026, month: 2, day: 27, hour: 19, minute: 32),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_feb27",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -209.99,
                currency: "USD",
                category: "Shopping",
                note: "Sony headphones",
                timestamp: fixedDate(year: 2026, month: 2, day: 27, hour: 10, minute: 14),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_costco",
                accountId: creditId,
                vendor: "Costco Wholesale",
                amount: -142.56,
                currency: "USD",
                category: "Groceries",
                note: "Monthly Costco run",
                timestamp: fixedDate(year: 2026, month: 2, day: 25, hour: 11, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - February 2026 (historical, before Feb 25)

            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_feb24",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.75,
                currency: "USD",
                category: "Food & drink",
                note: "Drip coffee",
                timestamp: fixedDate(year: 2026, month: 2, day: 24, hour: 7, minute: 52),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb24",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -65.10,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL from SFO",
                timestamp: fixedDate(year: 2026, month: 2, day: 24, hour: 19, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_feb24",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -37.52,
                currency: "USD",
                category: "Groceries",
                note: "Panera",
                timestamp: fixedDate(year: 2026, month: 2, day: 24, hour: 13, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_feb23",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -78.34,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 2, day: 23, hour: 17, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb22a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Oracle Park",
                timestamp: fixedDate(year: 2026, month: 2, day: 22, hour: 12, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb22",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -18.42,
                currency: "USD",
                category: "Transport",
                note: "Ride to dinner",
                timestamp: fixedDate(year: 2026, month: 2, day: 22, hour: 19, minute: 28),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_feb21",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -7.45,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 2, day: 21, hour: 8, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_feb21",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -28.91,
                currency: "USD",
                category: "Groceries",
                note: "CVS",
                timestamp: fixedDate(year: 2026, month: 2, day: 21, hour: 15, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_feb20",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -29.99,
                currency: "USD",
                category: "Shopping",
                note: "Wireless charger",
                timestamp: fixedDate(year: 2026, month: 2, day: 20, hour: 14, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_feb20",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -249.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→SEA",
                timestamp: fixedDate(year: 2026, month: 2, day: 20, hour: 9, minute: 42),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_feb19",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -12.50,
                currency: "USD",
                category: "Food & drink",
                note: "Latte and pastry",
                timestamp: fixedDate(year: 2026, month: 2, day: 19, hour: 9, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_feb18",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -52.17,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 2, day: 18, hour: 18, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb18",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -79.95,
                currency: "USD",
                category: "Transport",
                note: "CityRide Black to SFO",
                timestamp: fixedDate(year: 2026, month: 2, day: 18, hour: 7, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_feb18",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -24.98,
                currency: "USD",
                category: "Shopping",
                note: "CeraVe moisturizer",
                timestamp: fixedDate(year: 2026, month: 2, day: 18, hour: 12, minute: 33),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_feb18",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -58.34,
                currency: "USD",
                category: "Groceries",
                note: "Trader Joe's",
                timestamp: fixedDate(year: 2026, month: 2, day: 18, hour: 16, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_maya_feb17",
                accountId: checkingId,
                vendor: "Maya Patel",
                amount: 45.00,
                currency: "USD",
                category: "Zelle",
                note: "Brunch reimbursement",
                timestamp: fixedDate(year: 2026, month: 2, day: 17, hour: 11, minute: 22),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_feb16",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -31.47,
                currency: "USD",
                category: "Food & drink",
                note: "Thai delivery",
                timestamp: fixedDate(year: 2026, month: 2, day: 16, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_feb16b",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -41.48,
                currency: "USD",
                category: "Food & drink",
                note: "Pizza Hut",
                timestamp: fixedDate(year: 2026, month: 2, day: 16, hour: 12, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_feb15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2026, month: 2, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb15",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -23.30,
                currency: "USD",
                category: "Transport",
                note: "Comfort from SoMa",
                timestamp: fixedDate(year: 2026, month: 2, day: 15, hour: 21, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_feb15",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -98.67,
                currency: "USD",
                category: "Groceries",
                note: "Whole Foods",
                timestamp: fixedDate(year: 2026, month: 2, day: 15, hour: 14, minute: 22),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_feb14",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -48.73,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2026, month: 2, day: 14, hour: 15, minute: 42),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_feb13",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -5.95,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 2, day: 13, hour: 7, minute: 48),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb13a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 2, day: 13, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_feb12",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -67.89,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2026, month: 2, day: 12, hour: 17, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_feb11",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.25,
                currency: "USD",
                category: "Food & drink",
                note: "Cortado",
                timestamp: fixedDate(year: 2026, month: 2, day: 11, hour: 8, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb11a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort to Marina",
                timestamp: fixedDate(year: 2026, month: 2, day: 11, hour: 18, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_feb11",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -85.00,
                currency: "USD",
                category: "Entertainment",
                note: "Clippers at Warriors",
                timestamp: fixedDate(year: 2026, month: 2, day: 11, hour: 10, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_theo_feb10",
                accountId: checkingId,
                vendor: "Theo Nguyen",
                amount: -35.00,
                currency: "USD",
                category: "Zelle",
                note: "Fantasy football dues",
                timestamp: fixedDate(year: 2026, month: 2, day: 10, hour: 20, minute: 5),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_sushi_feb9",
                accountId: creditId,
                vendor: "Sushi Kazu",
                amount: -62.30,
                currency: "USD",
                category: "Food & drink",
                note: "Dinner with friends",
                timestamp: fixedDate(year: 2026, month: 2, day: 9, hour: 19, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_feb",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -108.76,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2026, month: 2, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb5a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 2, day: 5, hour: 8, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_feb",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2026, month: 2, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_feb",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2026, month: 2, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_feb",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "February rent",
                timestamp: fixedDate(year: 2026, month: 2, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_feb1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2026, month: 2, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_feb",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -450.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2026, month: 2, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_feb",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 450.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2026, month: 2, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_feb",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 3.62,
                currency: "USD",
                category: "Interest",
                note: "February interest payment",
                timestamp: fixedDate(year: 2026, month: 2, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_feb",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2026, month: 2, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_feb",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2026, month: 1, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_feb",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -380.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2026, month: 2, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_feb",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 380.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2026, month: 2, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb8a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Hayes Valley",
                timestamp: fixedDate(year: 2026, month: 2, day: 8, hour: 12, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_feb7",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -91.23,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 2, day: 7, hour: 16, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_feb7",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -284.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→SAN",
                timestamp: fixedDate(year: 2026, month: 2, day: 7, hour: 11, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_feb8",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.30,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 2, day: 8, hour: 8, minute: 22),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_feb6",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -38.98,
                currency: "USD",
                category: "Shopping",
                note: "Dog treats",
                timestamp: fixedDate(year: 2026, month: 2, day: 6, hour: 14, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_feb5",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -22.19,
                currency: "USD",
                category: "Food & drink",
                note: "Chipotle",
                timestamp: fixedDate(year: 2026, month: 2, day: 5, hour: 19, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - January 2026 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan31a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Nob Hill",
                timestamp: fixedDate(year: 2026, month: 1, day: 31, hour: 18, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jan30",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.50,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 30, hour: 8, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_jan30",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -189.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→LAS",
                timestamp: fixedDate(year: 2026, month: 1, day: 30, hour: 14, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan29",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -65.10,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL from SFO",
                timestamp: fixedDate(year: 2026, month: 1, day: 29, hour: 20, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_jan28",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -44.92,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 28, hour: 17, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_grace_jan27",
                accountId: checkingId,
                vendor: "Grace Lin",
                amount: -25.00,
                currency: "USD",
                category: "Zelle",
                note: "Farmers market split",
                timestamp: fixedDate(year: 2026, month: 1, day: 27, hour: 12, minute: 30),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan26",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.15,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 26, hour: 22, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_jan25",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -47.82,
                currency: "USD",
                category: "Shopping",
                note: "Desk lamp",
                timestamp: fixedDate(year: 2026, month: 1, day: 25, hour: 10, minute: 33),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jan25",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -34.16,
                currency: "USD",
                category: "Food & drink",
                note: "DashMart",
                timestamp: fixedDate(year: 2026, month: 1, day: 25, hour: 20, minute: 12),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_jan25b",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -134.99,
                currency: "USD",
                category: "Shopping",
                note: "Cookware set",
                timestamp: fixedDate(year: 2026, month: 1, day: 25, hour: 15, minute: 48),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_jan24",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -8.10,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 24, hour: 7, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_jan23",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -55.18,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2026, month: 1, day: 23, hour: 14, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan23a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Castro",
                timestamp: fixedDate(year: 2026, month: 1, day: 23, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan23b",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: "CityRideX from Castro",
                timestamp: fixedDate(year: 2026, month: 1, day: 23, hour: 23, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_jan22",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -73.41,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2026, month: 1, day: 22, hour: 18, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jan21",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -13.00,
                currency: "USD",
                category: "Food & drink",
                note: "Coffee and scone",
                timestamp: fixedDate(year: 2026, month: 1, day: 21, hour: 9, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jan20",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -26.83,
                currency: "USD",
                category: "Food & drink",
                note: "Indian delivery",
                timestamp: fixedDate(year: 2026, month: 1, day: 20, hour: 20, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_noah_jan19",
                accountId: checkingId,
                vendor: "Noah Patel",
                amount: 40.00,
                currency: "USD",
                category: "Zelle",
                note: "Game tickets",
                timestamp: fixedDate(year: 2026, month: 1, day: 19, hour: 15, minute: 12),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_jan18",
                accountId: creditId,
                vendor: "Target",
                amount: -45.63,
                currency: "USD",
                category: "Shopping",
                note: "Household supplies",
                timestamp: fixedDate(year: 2026, month: 1, day: 18, hour: 13, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_jan17",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -5.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 17, hour: 8, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_jan16",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -82.67,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 16, hour: 17, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan16a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -40.80,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL to Inner Sunset",
                timestamp: fixedDate(year: 2026, month: 1, day: 16, hour: 11, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_jan15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2026, month: 1, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jan14",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.00,
                currency: "USD",
                category: "Food & drink",
                note: "Drip coffee",
                timestamp: fixedDate(year: 2026, month: 1, day: 14, hour: 8, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_venmo_spencer_jan13",
                accountId: checkingId,
                vendor: "SplitPay - Spencer B.",
                amount: -28.00,
                currency: "USD",
                category: "Zelle",
                note: "Pizza night split",
                timestamp: fixedDate(year: 2026, month: 1, day: 13, hour: 21, minute: 15),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_jan12",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -56.41,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 12, hour: 18, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_jan12",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -121.99,
                currency: "USD",
                category: "Shopping",
                note: "Running shoes",
                timestamp: fixedDate(year: 2026, month: 1, day: 12, hour: 10, minute: 22),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_lyft_jan11",
                accountId: creditId,
                vendor: "Lyft Ride",
                amount: -16.42,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 11, hour: 18, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jan11",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -32.45,
                currency: "USD",
                category: "Food & drink",
                note: "CVS Pharmacy",
                timestamp: fixedDate(year: 2026, month: 1, day: 11, hour: 14, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan11a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -79.95,
                currency: "USD",
                category: "Transport",
                note: "CityRide Black to Marina",
                timestamp: fixedDate(year: 2026, month: 1, day: 11, hour: 19, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan11b",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -79.95,
                currency: "USD",
                category: "Transport",
                note: "CityRide Black from Marina",
                timestamp: fixedDate(year: 2026, month: 1, day: 11, hour: 23, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_walgreens_jan10",
                accountId: creditId,
                vendor: "Walgreens",
                amount: -14.29,
                currency: "USD",
                category: "Health",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 10, hour: 12, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_jan10",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -78.50,
                currency: "USD",
                category: "Entertainment",
                note: "Hamilton",
                timestamp: fixedDate(year: 2026, month: 1, day: 10, hour: 16, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_jan9",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.85,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 9, hour: 7, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_jan9",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -312.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→LAX",
                timestamp: fixedDate(year: 2026, month: 1, day: 9, hour: 11, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan9a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Mission",
                timestamp: fixedDate(year: 2026, month: 1, day: 9, hour: 19, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_jan8",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -59.12,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2026, month: 1, day: 8, hour: 17, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_jan",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -118.92,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2026, month: 1, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jan7",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.25,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2026, month: 1, day: 7, hour: 8, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_jan",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -520.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2026, month: 1, day: 6, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_jan",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 520.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2026, month: 1, day: 6, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_jan",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2026, month: 1, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jan3",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort to SFO",
                timestamp: fixedDate(year: 2026, month: 1, day: 3, hour: 6, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_jan3",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -37.94,
                currency: "USD",
                category: "Shopping",
                note: "Planner + pens",
                timestamp: fixedDate(year: 2026, month: 1, day: 3, hour: 13, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_jan",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2026, month: 1, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_jan",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "January rent",
                timestamp: fixedDate(year: 2026, month: 1, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_jan1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2026, month: 1, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_jan",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2026, month: 1, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_jan",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2026, month: 1, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_jan",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 3.41,
                currency: "USD",
                category: "Interest",
                note: "January interest payment",
                timestamp: fixedDate(year: 2026, month: 1, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_jan",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2026, month: 1, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - December 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_jan",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 12, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_nordstrom_dec",
                accountId: creditId,
                vendor: "Nordstrom",
                amount: -189.50,
                currency: "USD",
                category: "Shopping",
                note: "Holiday gift",
                timestamp: fixedDate(year: 2025, month: 12, day: 23, hour: 14, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_dec22",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -124.37,
                currency: "USD",
                category: "Shopping",
                note: "Holiday gifts",
                timestamp: fixedDate(year: 2025, month: 12, day: 22, hour: 11, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_dec22",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -56.17,
                currency: "USD",
                category: "Food & drink",
                note: "Total Wine",
                timestamp: fixedDate(year: 2025, month: 12, day: 22, hour: 18, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_dec22",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -359.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→BOS",
                timestamp: fixedDate(year: 2025, month: 12, day: 22, hour: 8, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_williams_sonoma_dec",
                accountId: creditId,
                vendor: "Williams Sonoma",
                amount: -78.95,
                currency: "USD",
                category: "Shopping",
                note: "Kitchen gift set",
                timestamp: fixedDate(year: 2025, month: 12, day: 21, hour: 15, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_dec20",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -156.42,
                currency: "USD",
                category: "Groceries",
                note: "Holiday dinner supplies",
                timestamp: fixedDate(year: 2025, month: 12, day: 20, hour: 16, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec20a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 12, day: 20, hour: 8, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_camille_dec19",
                accountId: checkingId,
                vendor: "Camille Hart",
                amount: 75.00,
                currency: "USD",
                category: "Zelle",
                note: "Holiday party contribution",
                timestamp: fixedDate(year: 2025, month: 12, day: 19, hour: 18, minute: 10),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_dec18",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -14.75,
                currency: "USD",
                category: "Food & drink",
                note: "Holiday blend beans",
                timestamp: fixedDate(year: 2025, month: 12, day: 18, hour: 9, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_dec17",
                accountId: creditId,
                vendor: "Target",
                amount: -93.28,
                currency: "USD",
                category: "Shopping",
                note: "Gift wrapping supplies and stocking stuffers",
                timestamp: fixedDate(year: 2025, month: 12, day: 17, hour: 12, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_dec17",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -47.20,
                currency: "USD",
                category: "Food & drink",
                note: "Levain Bakery",
                timestamp: fixedDate(year: 2025, month: 12, day: 17, hour: 19, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_dec16",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -9.15,
                currency: "USD",
                category: "Food & drink",
                note: "Peppermint mocha",
                timestamp: fixedDate(year: 2025, month: 12, day: 16, hour: 8, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_dec16",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -64.98,
                currency: "USD",
                category: "Shopping",
                note: "LEGO + Crayola",
                timestamp: fixedDate(year: 2025, month: 12, day: 16, hour: 14, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_dec15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 12, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_dec14",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -61.28,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 12, day: 14, hour: 17, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec13",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -31.20,
                currency: "USD",
                category: "Transport",
                note: "Holiday party ride",
                timestamp: fixedDate(year: 2025, month: 12, day: 13, hour: 23, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_dec13",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -72.00,
                currency: "USD",
                category: "Entertainment",
                note: "Tyler the Creator",
                timestamp: fixedDate(year: 2025, month: 12, day: 13, hour: 10, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_restaurant_dec12",
                accountId: creditId,
                vendor: "Flour + Water",
                amount: -87.50,
                currency: "USD",
                category: "Food & drink",
                note: "Team dinner",
                timestamp: fixedDate(year: 2025, month: 12, day: 12, hour: 20, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_dec11",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -51.44,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 12, day: 11, hour: 15, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_dec11",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -19.98,
                currency: "USD",
                category: "Food & drink",
                note: "DashMart",
                timestamp: fixedDate(year: 2025, month: 12, day: 11, hour: 18, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec10",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort from SFO",
                timestamp: fixedDate(year: 2025, month: 12, day: 10, hour: 21, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_ava_dec10",
                accountId: checkingId,
                vendor: "Ava Torres",
                amount: -50.00,
                currency: "USD",
                category: "Zelle",
                note: "Secret Santa pool",
                timestamp: fixedDate(year: 2025, month: 12, day: 10, hour: 19, minute: 25),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_dec9",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.50,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 12, day: 9, hour: 8, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_dec8",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -71.36,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 12, day: 8, hour: 18, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_dec7",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -33.12,
                currency: "USD",
                category: "Food & drink",
                note: "Sushi delivery",
                timestamp: fixedDate(year: 2025, month: 12, day: 7, hour: 19, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_dec6",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -7.80,
                currency: "USD",
                category: "Food & drink",
                note: "Gingerbread latte",
                timestamp: fixedDate(year: 2025, month: 12, day: 6, hour: 9, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_dec",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -124.57,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 12, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_dec5",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -37.28,
                currency: "USD",
                category: "Food & drink",
                note: "Chipotle",
                timestamp: fixedDate(year: 2025, month: 12, day: 5, hour: 19, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_dec5",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -92.00,
                currency: "USD",
                category: "Entertainment",
                note: "Nuggets at Warriors",
                timestamp: fixedDate(year: 2025, month: 12, day: 5, hour: 11, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_dec",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -450.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 12, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_dec",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 450.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 12, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec4a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -79.95,
                currency: "USD",
                category: "Transport",
                note: "CityRide Black to Nob Hill",
                timestamp: fixedDate(year: 2025, month: 12, day: 4, hour: 18, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec4b",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -79.95,
                currency: "USD",
                category: "Transport",
                note: "CityRide Black from Nob Hill",
                timestamp: fixedDate(year: 2025, month: 12, day: 4, hour: 22, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_dec",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 12, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_dec3",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -40.98,
                currency: "USD",
                category: "Shopping",
                note: "Coffee + cookbook",
                timestamp: fixedDate(year: 2025, month: 12, day: 3, hour: 15, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_dec",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 12, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_dec",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "December rent",
                timestamp: fixedDate(year: 2025, month: 12, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_dec1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 12, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_dec",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -500.00,
                currency: "USD",
                category: "Transfer",
                note: "Holiday savings boost",
                timestamp: fixedDate(year: 2025, month: 12, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_dec",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 500.00,
                currency: "USD",
                category: "Transfer",
                note: "Holiday savings boost",
                timestamp: fixedDate(year: 2025, month: 12, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_dec",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 3.17,
                currency: "USD",
                category: "Interest",
                note: "December interest payment",
                timestamp: fixedDate(year: 2025, month: 12, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_dec",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 12, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_nov29",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -65.10,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL to Golden Gate Park",
                timestamp: fixedDate(year: 2025, month: 11, day: 29, hour: 14, minute: 22),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_dec",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 11, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_nov24",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -43.98,
                currency: "USD",
                category: "Shopping",
                note: "Paper towels + Tide",
                timestamp: fixedDate(year: 2025, month: 11, day: 24, hour: 10, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec27a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 12, day: 27, hour: 8, minute: 42),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec27b",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 12, day: 27, hour: 17, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_dec26",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -67.43,
                currency: "USD",
                category: "Shopping",
                note: "Post-holiday sale",
                timestamp: fixedDate(year: 2025, month: 12, day: 26, hour: 10, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_costco_dec27",
                accountId: creditId,
                vendor: "Costco Wholesale",
                amount: -138.91,
                currency: "USD",
                category: "Groceries",
                note: "Monthly Costco run",
                timestamp: fixedDate(year: 2025, month: 12, day: 27, hour: 11, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_dec29",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -11.25,
                currency: "USD",
                category: "Food & drink",
                note: "Latte and croissant",
                timestamp: fixedDate(year: 2025, month: 12, day: 29, hour: 10, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_dec29",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -96.30,
                currency: "USD",
                category: "Food & drink",
                note: "Nobu",
                timestamp: fixedDate(year: 2025, month: 12, day: 29, hour: 20, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_leo_dec30",
                accountId: checkingId,
                vendor: "Leo Chen",
                amount: -60.00,
                currency: "USD",
                category: "Zelle",
                note: "NYE party supplies",
                timestamp: fixedDate(year: 2025, month: 12, day: 30, hour: 16, minute: 40),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec31",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -38.75,
                currency: "USD",
                category: "Transport",
                note: "NYE ride",
                timestamp: fixedDate(year: 2025, month: 12, day: 31, hour: 23, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_dec25a",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Noe Valley",
                timestamp: fixedDate(year: 2025, month: 12, day: 25, hour: 13, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_atm_dec24",
                accountId: checkingId,
                vendor: "MyBank ATM",
                amount: -100.00,
                currency: "USD",
                category: "ATM",
                note: "Holiday cash",
                timestamp: fixedDate(year: 2025, month: 12, day: 24, hour: 11, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_rohan_dec15",
                accountId: checkingId,
                vendor: "Rohan Mehta",
                amount: 35.00,
                currency: "USD",
                category: "Zelle",
                note: "Lunch reimbursement",
                timestamp: fixedDate(year: 2025, month: 12, day: 15, hour: 13, minute: 20),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_restaurant_dec25",
                accountId: creditId,
                vendor: "Burma Superstar",
                amount: -72.60,
                currency: "USD",
                category: "Food & drink",
                note: "Christmas dinner",
                timestamp: fixedDate(year: 2025, month: 12, day: 25, hour: 19, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_chevron_dec28",
                accountId: creditId,
                vendor: "Chevron Gas",
                amount: -54.82,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 12, day: 28, hour: 14, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_dec28",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -119.99,
                currency: "USD",
                category: "Shopping",
                note: "Yoga mat",
                timestamp: fixedDate(year: 2025, month: 12, day: 28, hour: 11, minute: 33),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_venmo_marcus_dec8",
                accountId: checkingId,
                vendor: "SplitPay - Marcus V.",
                amount: 22.50,
                currency: "USD",
                category: "Zelle",
                note: "CityRide split",
                timestamp: fixedDate(year: 2025, month: 12, day: 8, hour: 10, minute: 35),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_dec2",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -8.45,
                currency: "USD",
                category: "Food & drink",
                note: "Eggnog latte",
                timestamp: fixedDate(year: 2025, month: 12, day: 2, hour: 8, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - November 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_nov1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 11, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_nov",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "November rent",
                timestamp: fixedDate(year: 2025, month: 11, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_nov",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 11, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_nov",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 11, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_nov",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 2.95,
                currency: "USD",
                category: "Interest",
                note: "November interest payment",
                timestamp: fixedDate(year: 2025, month: 11, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_nov",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 11, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_nov",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 11, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_nov",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 11, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_nov",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -420.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 11, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_nov",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 420.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 11, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_nov",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -131.28,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 11, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_nov6",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 11, day: 6, hour: 8, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_nov6",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -58.42,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 11, day: 6, hour: 17, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_nov8",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Dogpatch",
                timestamp: fixedDate(year: 2025, month: 11, day: 8, hour: 18, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_nov8",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -7.15,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 11, day: 8, hour: 8, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_nov9",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -38.76,
                currency: "USD",
                category: "Food & drink",
                note: "Popeyes",
                timestamp: fixedDate(year: 2025, month: 11, day: 9, hour: 19, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_nov10",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -72.15,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 11, day: 10, hour: 17, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_nov12",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 11, day: 12, hour: 8, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_nov12",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -54.99,
                currency: "USD",
                category: "Shopping",
                note: "Noise machine",
                timestamp: fixedDate(year: 2025, month: 11, day: 12, hour: 14, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_nov14",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -49.87,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 11, day: 14, hour: 15, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_nov15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 11, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_nov15",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -67.23,
                currency: "USD",
                category: "Groceries",
                note: "Whole Foods",
                timestamp: fixedDate(year: 2025, month: 11, day: 15, hour: 14, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_nov16",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -12.25,
                currency: "USD",
                category: "Food & drink",
                note: "Latte and muffin",
                timestamp: fixedDate(year: 2025, month: 11, day: 16, hour: 9, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_nov18",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -89.31,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 11, day: 18, hour: 17, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_nov18",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort to Presidio",
                timestamp: fixedDate(year: 2025, month: 11, day: 18, hour: 11, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_theo_nov19",
                accountId: checkingId,
                vendor: "Theo Nguyen",
                amount: -30.00,
                currency: "USD",
                category: "Zelle",
                note: "Warriors tickets split",
                timestamp: fixedDate(year: 2025, month: 11, day: 19, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_nov20",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -29.47,
                currency: "USD",
                category: "Food & drink",
                note: "Panda Express",
                timestamp: fixedDate(year: 2025, month: 11, day: 20, hour: 19, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_nov22",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.50,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 11, day: 22, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_nov22",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -68.00,
                currency: "USD",
                category: "Entertainment",
                note: "Lakers at Warriors",
                timestamp: fixedDate(year: 2025, month: 11, day: 22, hour: 10, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_nov25",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 11, day: 25, hour: 18, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_nov26",
                accountId: creditId,
                vendor: "Target",
                amount: -56.83,
                currency: "USD",
                category: "Shopping",
                note: "Thanksgiving supplies",
                timestamp: fixedDate(year: 2025, month: 11, day: 26, hour: 13, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_nov27",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -142.87,
                currency: "USD",
                category: "Groceries",
                note: "Thanksgiving dinner",
                timestamp: fixedDate(year: 2025, month: 11, day: 27, hour: 10, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - October 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_oct1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 10, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_oct",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "October rent",
                timestamp: fixedDate(year: 2025, month: 10, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_oct",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 10, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_oct",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 10, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_oct",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 2.78,
                currency: "USD",
                category: "Interest",
                note: "October interest payment",
                timestamp: fixedDate(year: 2025, month: 10, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_oct",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 10, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_oct",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 10, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_oct",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 10, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_oct",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -480.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 10, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_oct",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 480.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 10, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_oct",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -98.34,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 10, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_oct6",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.50,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 6, hour: 8, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_oct7",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -49.73,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 7, hour: 17, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_oct8",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 8, hour: 18, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_oct8",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -27.43,
                currency: "USD",
                category: "Food & drink",
                note: "Five Guys",
                timestamp: fixedDate(year: 2025, month: 10, day: 8, hour: 20, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_oct10",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -65.18,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 10, day: 10, hour: 17, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_walgreens_oct10",
                accountId: creditId,
                vendor: "Walgreens",
                amount: -11.49,
                currency: "USD",
                category: "Health",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 10, hour: 12, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_oct11",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to North Beach",
                timestamp: fixedDate(year: 2025, month: 10, day: 11, hour: 19, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_oct12",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -42.97,
                currency: "USD",
                category: "Shopping",
                note: "Halloween decorations",
                timestamp: fixedDate(year: 2025, month: 10, day: 12, hour: 10, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_oct12",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -8.95,
                currency: "USD",
                category: "Food & drink",
                note: "Pumpkin spice latte",
                timestamp: fixedDate(year: 2025, month: 10, day: 12, hour: 8, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_venmo_spencer_oct13",
                accountId: checkingId,
                vendor: "SplitPay - Spencer B.",
                amount: -32.00,
                currency: "USD",
                category: "Zelle",
                note: "Escape room split",
                timestamp: fixedDate(year: 2025, month: 10, day: 13, hour: 21, minute: 5),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_oct14",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -53.22,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 10, day: 14, hour: 15, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_oct15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 10, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_oct16",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.00,
                currency: "USD",
                category: "Food & drink",
                note: "Drip coffee",
                timestamp: fixedDate(year: 2025, month: 10, day: 16, hour: 8, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_oct17",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -76.42,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 17, hour: 16, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_oct18",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort to Japantown",
                timestamp: fixedDate(year: 2025, month: 10, day: 18, hour: 18, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_oct18",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -74.50,
                currency: "USD",
                category: "Entertainment",
                note: "Celtics at Warriors",
                timestamp: fixedDate(year: 2025, month: 10, day: 18, hour: 11, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_oct19",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -35.62,
                currency: "USD",
                category: "Food & drink",
                note: "Wingstop",
                timestamp: fixedDate(year: 2025, month: 10, day: 19, hour: 20, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_oct21",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 21, hour: 8, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_oct21",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -71.89,
                currency: "USD",
                category: "Groceries",
                note: "Safeway",
                timestamp: fixedDate(year: 2025, month: 10, day: 21, hour: 14, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_oct22",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.30,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 22, hour: 7, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_oct24",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -89.99,
                currency: "USD",
                category: "Shopping",
                note: "Air purifier filter",
                timestamp: fixedDate(year: 2025, month: 10, day: 24, hour: 11, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_oct25",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -65.10,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL from SFO",
                timestamp: fixedDate(year: 2025, month: 10, day: 25, hour: 20, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_oct25",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -44.18,
                currency: "USD",
                category: "Food & drink",
                note: "Sweetgreen",
                timestamp: fixedDate(year: 2025, month: 10, day: 25, hour: 12, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_oct27",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -53.16,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 27, hour: 18, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_maya_oct27",
                accountId: checkingId,
                vendor: "Maya Patel",
                amount: 50.00,
                currency: "USD",
                category: "Zelle",
                note: "Dinner reimbursement",
                timestamp: fixedDate(year: 2025, month: 10, day: 27, hour: 13, minute: 20),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_nov",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 10, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_chevron_oct29",
                accountId: creditId,
                vendor: "Chevron Gas",
                amount: -51.34,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 10, day: 29, hour: 14, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_oct30",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 10, day: 30, hour: 8, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_oct31",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -31.20,
                currency: "USD",
                category: "Transport",
                note: "Halloween night",
                timestamp: fixedDate(year: 2025, month: 10, day: 31, hour: 23, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_oct31",
                accountId: creditId,
                vendor: "Target",
                amount: -38.47,
                currency: "USD",
                category: "Shopping",
                note: "Halloween costume",
                timestamp: fixedDate(year: 2025, month: 10, day: 31, hour: 14, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - September 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_sep1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 9, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_sep",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "September rent",
                timestamp: fixedDate(year: 2025, month: 9, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_sep",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 9, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_sep",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 9, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_sep",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 2.61,
                currency: "USD",
                category: "Interest",
                note: "September interest payment",
                timestamp: fixedDate(year: 2025, month: 9, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_sep",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 9, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_sep",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 9, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_sep",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 9, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_sep",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -510.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 9, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_sep",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 510.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 9, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_sep",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -89.43,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 9, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_sep6",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.25,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 9, day: 6, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_sep6",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -55.18,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 9, day: 6, hour: 17, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_sep7",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 9, day: 7, hour: 18, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_sep8",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -31.24,
                currency: "USD",
                category: "Food & drink",
                note: "Chipotle",
                timestamp: fixedDate(year: 2025, month: 9, day: 8, hour: 19, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_sep8",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -68.42,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 9, day: 8, hour: 17, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_sep10",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -5.95,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 9, day: 10, hour: 7, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_sep10",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -34.99,
                currency: "USD",
                category: "Shopping",
                note: "Backpack",
                timestamp: fixedDate(year: 2025, month: 9, day: 10, hour: 14, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_sep11",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 9, day: 11, hour: 8, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_sep12",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -42.17,
                currency: "USD",
                category: "Food & drink",
                note: "Nobu",
                timestamp: fixedDate(year: 2025, month: 9, day: 12, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_sep13",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -228.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→PDX",
                timestamp: fixedDate(year: 2025, month: 9, day: 13, hour: 9, minute: 42),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_sep14",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "From PDX airport",
                timestamp: fixedDate(year: 2025, month: 9, day: 14, hour: 21, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_sep15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 9, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_sep16",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -12.50,
                currency: "USD",
                category: "Food & drink",
                note: "Latte and pastry",
                timestamp: fixedDate(year: 2025, month: 9, day: 16, hour: 9, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_sep17",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -83.67,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 9, day: 17, hour: 17, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_sep18",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Embarcadero",
                timestamp: fixedDate(year: 2025, month: 9, day: 18, hour: 18, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_restaurant_sep19",
                accountId: creditId,
                vendor: "Sushi Kazu",
                amount: -58.90,
                currency: "USD",
                category: "Food & drink",
                note: "Dinner with friends",
                timestamp: fixedDate(year: 2025, month: 9, day: 19, hour: 19, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_sep20",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -52.34,
                currency: "USD",
                category: "Groceries",
                note: "Costco",
                timestamp: fixedDate(year: 2025, month: 9, day: 20, hour: 14, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_sep22",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.85,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 9, day: 22, hour: 8, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_sep22",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -50.44,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 9, day: 22, hour: 15, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_sep23",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 9, day: 23, hour: 19, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_sep24",
                accountId: creditId,
                vendor: "Target",
                amount: -52.41,
                currency: "USD",
                category: "Shopping",
                note: "Household essentials",
                timestamp: fixedDate(year: 2025, month: 9, day: 24, hour: 13, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_sep25",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -28.63,
                currency: "USD",
                category: "Food & drink",
                note: "Thai delivery",
                timestamp: fixedDate(year: 2025, month: 9, day: 25, hour: 20, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_noah_sep26",
                accountId: checkingId,
                vendor: "Noah Patel",
                amount: 45.00,
                currency: "USD",
                category: "Zelle",
                note: "Concert tickets",
                timestamp: fixedDate(year: 2025, month: 9, day: 26, hour: 14, minute: 10),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_costco_sep27",
                accountId: creditId,
                vendor: "Costco Wholesale",
                amount: -128.43,
                currency: "USD",
                category: "Groceries",
                note: "Monthly Costco run",
                timestamp: fixedDate(year: 2025, month: 9, day: 27, hour: 11, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_sep27",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -40.80,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL to Sunset",
                timestamp: fixedDate(year: 2025, month: 9, day: 27, hour: 18, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_oct",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 9, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_sep29",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.25,
                currency: "USD",
                category: "Food & drink",
                note: "Cortado",
                timestamp: fixedDate(year: 2025, month: 9, day: 29, hour: 8, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - August 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_aug1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 8, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_aug",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "August rent",
                timestamp: fixedDate(year: 2025, month: 8, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_aug",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -350.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 8, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_aug",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 350.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 8, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_aug",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 2.44,
                currency: "USD",
                category: "Interest",
                note: "August interest payment",
                timestamp: fixedDate(year: 2025, month: 8, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_aug",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 8, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_aug",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 8, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_aug",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 8, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_aug",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -550.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 8, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_aug",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 550.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 8, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_aug",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -78.92,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 8, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_aug6",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.50,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 6, hour: 8, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_aug7",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -47.83,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 7, hour: 17, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_aug7",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 7, hour: 18, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_aug8",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -36.42,
                currency: "USD",
                category: "Food & drink",
                note: "Sweetgreen",
                timestamp: fixedDate(year: 2025, month: 8, day: 8, hour: 19, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_aug9",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -61.74,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 8, day: 9, hour: 17, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_aug10",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -7.45,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 10, hour: 8, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_aug10",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -389.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→JFK",
                timestamp: fixedDate(year: 2025, month: 8, day: 10, hour: 10, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_aug11",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -65.10,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL from JFK",
                timestamp: fixedDate(year: 2025, month: 8, day: 11, hour: 20, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_aug12",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -64.99,
                currency: "USD",
                category: "Shopping",
                note: "Beach towels + sunscreen",
                timestamp: fixedDate(year: 2025, month: 8, day: 12, hour: 14, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_aug13",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 13, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_aug13",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -29.18,
                currency: "USD",
                category: "Food & drink",
                note: "Taco Bell",
                timestamp: fixedDate(year: 2025, month: 8, day: 13, hour: 21, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_chevron_aug14",
                accountId: creditId,
                vendor: "Chevron Gas",
                amount: -52.67,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 8, day: 14, hour: 15, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_aug15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 8, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_aug16",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -13.00,
                currency: "USD",
                category: "Food & drink",
                note: "Cold brew and cookie",
                timestamp: fixedDate(year: 2025, month: 8, day: 16, hour: 9, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_aug16",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -92.18,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 16, hour: 17, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_aug17",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort to Golden Gate Park",
                timestamp: fixedDate(year: 2025, month: 8, day: 17, hour: 11, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_aug17",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -125.00,
                currency: "USD",
                category: "Entertainment",
                note: "Outside Lands",
                timestamp: fixedDate(year: 2025, month: 8, day: 17, hour: 10, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_aug18",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -45.67,
                currency: "USD",
                category: "Groceries",
                note: "Safeway",
                timestamp: fixedDate(year: 2025, month: 8, day: 18, hour: 14, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_aug19",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -33.91,
                currency: "USD",
                category: "Food & drink",
                note: "Shake Shack",
                timestamp: fixedDate(year: 2025, month: 8, day: 19, hour: 20, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_aug20",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.30,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 20, hour: 7, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_elena_aug20",
                accountId: checkingId,
                vendor: "Elena Brooks",
                amount: 35.00,
                currency: "USD",
                category: "Zelle",
                note: "Brunch split",
                timestamp: fixedDate(year: 2025, month: 8, day: 20, hour: 13, minute: 15),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_aug22",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 22, hour: 18, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_aug23",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -27.99,
                currency: "USD",
                category: "Shopping",
                note: "Phone case",
                timestamp: fixedDate(year: 2025, month: 8, day: 23, hour: 10, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_aug24",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -58.93,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 8, day: 24, hour: 17, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_aug25",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -41.52,
                currency: "USD",
                category: "Food & drink",
                note: "Sugarfish",
                timestamp: fixedDate(year: 2025, month: 8, day: 25, hour: 19, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_aug26",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 26, hour: 8, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_aug27",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 8, day: 27, hour: 19, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_sep",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 8, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_aug29",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -48.91,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 8, day: 29, hour: 14, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_aug30",
                accountId: creditId,
                vendor: "Target",
                amount: -41.28,
                currency: "USD",
                category: "Shopping",
                note: "Back to routine supplies",
                timestamp: fixedDate(year: 2025, month: 8, day: 30, hour: 13, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - July 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_jul1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 7, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_jul",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "July rent",
                timestamp: fixedDate(year: 2025, month: 7, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_jul",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -350.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 7, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_jul",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 350.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 7, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_jul",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 2.31,
                currency: "USD",
                category: "Interest",
                note: "July interest payment",
                timestamp: fixedDate(year: 2025, month: 7, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_jul",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 7, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_jul",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 7, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_jul",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 7, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_jul4",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -118.34,
                currency: "USD",
                category: "Groceries",
                note: "Fourth of July BBQ supplies",
                timestamp: fixedDate(year: 2025, month: 7, day: 4, hour: 10, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jul4",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort to Marina Green",
                timestamp: fixedDate(year: 2025, month: 7, day: 4, hour: 16, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_jul",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -72.18,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 7, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_jul",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -460.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 7, day: 6, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_jul",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 460.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 7, day: 6, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jul7",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.00,
                currency: "USD",
                category: "Food & drink",
                note: "Drip coffee",
                timestamp: fixedDate(year: 2025, month: 7, day: 7, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_jul8",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -51.27,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 7, day: 8, hour: 18, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jul9",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 7, day: 9, hour: 8, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jul9",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -27.84,
                currency: "USD",
                category: "Food & drink",
                note: "Chipotle",
                timestamp: fixedDate(year: 2025, month: 7, day: 9, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_jul10",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.85,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 7, day: 10, hour: 7, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_jul11",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -39.99,
                currency: "USD",
                category: "Shopping",
                note: "Portable speaker",
                timestamp: fixedDate(year: 2025, month: 7, day: 11, hour: 10, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_jul11",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -50.33,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 7, day: 11, hour: 15, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_jul12",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -64.51,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 7, day: 12, hour: 17, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jul13",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -35.67,
                currency: "USD",
                category: "Food & drink",
                note: "Panda Express",
                timestamp: fixedDate(year: 2025, month: 7, day: 13, hour: 19, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jul14",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -12.50,
                currency: "USD",
                category: "Food & drink",
                note: "Iced latte and scone",
                timestamp: fixedDate(year: 2025, month: 7, day: 14, hour: 9, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jul14",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 7, day: 14, hour: 18, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_jul15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 7, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_camille_jul16",
                accountId: checkingId,
                vendor: "Camille Hart",
                amount: -40.00,
                currency: "USD",
                category: "Zelle",
                note: "Beach house contribution",
                timestamp: fixedDate(year: 2025, month: 7, day: 16, hour: 14, minute: 20),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_jul17",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -58.91,
                currency: "USD",
                category: "Groceries",
                note: "Trader Joe's",
                timestamp: fixedDate(year: 2025, month: 7, day: 17, hour: 14, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jul17",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: "CityRideX to Pier 39",
                timestamp: fixedDate(year: 2025, month: 7, day: 17, hour: 18, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jul18",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -44.23,
                currency: "USD",
                category: "Food & drink",
                note: "Nobu",
                timestamp: fixedDate(year: 2025, month: 7, day: 18, hour: 20, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_jul19",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -198.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→SAN",
                timestamp: fixedDate(year: 2025, month: 7, day: 19, hour: 11, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jul20",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -40.80,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL from SAN",
                timestamp: fixedDate(year: 2025, month: 7, day: 20, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_jul20",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -7.45,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 7, day: 20, hour: 8, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_jul22",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -149.99,
                currency: "USD",
                category: "Shopping",
                note: "Instant Pot",
                timestamp: fixedDate(year: 2025, month: 7, day: 22, hour: 10, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_jul24",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -74.56,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 7, day: 24, hour: 17, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jul25",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.25,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 7, day: 25, hour: 8, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jul26",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 7, day: 26, hour: 19, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_jul26",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -85.00,
                currency: "USD",
                category: "Entertainment",
                note: "Giants vs Dodgers",
                timestamp: fixedDate(year: 2025, month: 7, day: 26, hour: 10, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_costco_jul27",
                accountId: creditId,
                vendor: "Costco Wholesale",
                amount: -135.67,
                currency: "USD",
                category: "Groceries",
                note: "Monthly Costco run",
                timestamp: fixedDate(year: 2025, month: 7, day: 27, hour: 11, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_aug",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 7, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jul29",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -31.42,
                currency: "USD",
                category: "Food & drink",
                note: "Pizza delivery",
                timestamp: fixedDate(year: 2025, month: 7, day: 29, hour: 20, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - June 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_jun1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 6, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_jun",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "June rent",
                timestamp: fixedDate(year: 2025, month: 6, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_jun",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 6, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_jun",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 6, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_jun",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 2.18,
                currency: "USD",
                category: "Interest",
                note: "June interest payment",
                timestamp: fixedDate(year: 2025, month: 6, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_jun",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 6, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_jun",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 6, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_jun",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 6, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_jun",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -490.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 6, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_jun",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 490.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 6, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_jun",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -82.56,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 6, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jun6",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.50,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 6, hour: 8, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_jun6",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -46.89,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 6, hour: 17, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jun7",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 7, hour: 18, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jun8",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -34.56,
                currency: "USD",
                category: "Food & drink",
                note: "Pad Thai delivery",
                timestamp: fixedDate(year: 2025, month: 6, day: 8, hour: 19, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_jun8",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -59.82,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 6, day: 8, hour: 17, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_jun9",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -5.95,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 9, hour: 7, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_jun10",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -32.99,
                currency: "USD",
                category: "Shopping",
                note: "Water bottle + vitamins",
                timestamp: fixedDate(year: 2025, month: 6, day: 10, hour: 14, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jun11",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 11, hour: 8, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_walgreens_jun11",
                accountId: creditId,
                vendor: "Walgreens",
                amount: -9.78,
                currency: "USD",
                category: "Health",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 11, hour: 12, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jun12",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -28.93,
                currency: "USD",
                category: "Food & drink",
                note: "Indian delivery",
                timestamp: fixedDate(year: 2025, month: 6, day: 12, hour: 20, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jun13",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -13.00,
                currency: "USD",
                category: "Food & drink",
                note: "Iced latte and pastry",
                timestamp: fixedDate(year: 2025, month: 6, day: 13, hour: 9, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_jun14",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -49.56,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 6, day: 14, hour: 15, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jun14",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort to Ocean Beach",
                timestamp: fixedDate(year: 2025, month: 6, day: 14, hour: 11, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_jun15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 6, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_jun16",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -81.34,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 16, hour: 17, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jun17",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 17, hour: 18, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jun18",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -39.74,
                currency: "USD",
                category: "Food & drink",
                note: "Sushi delivery",
                timestamp: fixedDate(year: 2025, month: 6, day: 18, hour: 20, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_grace_jun19",
                accountId: checkingId,
                vendor: "Grace Lin",
                amount: -30.00,
                currency: "USD",
                category: "Zelle",
                note: "Birthday gift pool",
                timestamp: fixedDate(year: 2025, month: 6, day: 19, hour: 15, minute: 10),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_jun20",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.30,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 20, hour: 8, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_jun20",
                accountId: creditId,
                vendor: "Target",
                amount: -47.62,
                currency: "USD",
                category: "Shopping",
                note: "Summer essentials",
                timestamp: fixedDate(year: 2025, month: 6, day: 20, hour: 13, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jun22",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 22, hour: 19, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_jun22",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.25,
                currency: "USD",
                category: "Food & drink",
                note: "Cortado",
                timestamp: fixedDate(year: 2025, month: 6, day: 22, hour: 9, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_jun24",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -63.41,
                currency: "USD",
                category: "Groceries",
                note: "Whole Foods",
                timestamp: fixedDate(year: 2025, month: 6, day: 24, hour: 14, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_jun25",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -54.99,
                currency: "USD",
                category: "Shopping",
                note: "Kindle book + case",
                timestamp: fixedDate(year: 2025, month: 6, day: 25, hour: 11, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_jun26",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -26.47,
                currency: "USD",
                category: "Food & drink",
                note: "Popeyes",
                timestamp: fixedDate(year: 2025, month: 6, day: 26, hour: 19, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_jun27",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -40.80,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL to Sausalito",
                timestamp: fixedDate(year: 2025, month: 6, day: 27, hour: 11, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_jul",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 6, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_jun29",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -7.45,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 6, day: 29, hour: 8, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - May 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_may1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 5, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_may",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "May rent",
                timestamp: fixedDate(year: 2025, month: 5, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_may",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 5, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_may",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 400.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 5, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_may",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 2.05,
                currency: "USD",
                category: "Interest",
                note: "May interest payment",
                timestamp: fixedDate(year: 2025, month: 5, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_may",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 5, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_may",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 5, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_may",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 5, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_may",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -430.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 5, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_may",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 430.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 5, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_may",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -87.31,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 5, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_may6",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 6, hour: 8, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_may7",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -53.48,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 7, hour: 17, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_may7",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 7, hour: 18, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_may8",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -33.71,
                currency: "USD",
                category: "Food & drink",
                note: "Shake Shack",
                timestamp: fixedDate(year: 2025, month: 5, day: 8, hour: 19, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_may9",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -5.95,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 9, hour: 8, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_may9",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -66.23,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 5, day: 9, hour: 17, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_may10",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -45.98,
                currency: "USD",
                category: "Shopping",
                note: "Mother's Day gift",
                timestamp: fixedDate(year: 2025, month: 5, day: 10, hour: 10, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_may11",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Mother's Day brunch ride",
                timestamp: fixedDate(year: 2025, month: 5, day: 11, hour: 10, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_restaurant_may11",
                accountId: creditId,
                vendor: "Foreign Cinema",
                amount: -94.50,
                currency: "USD",
                category: "Food & drink",
                note: "Mother's Day brunch",
                timestamp: fixedDate(year: 2025, month: 5, day: 11, hour: 12, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_may12",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -27.84,
                currency: "USD",
                category: "Food & drink",
                note: "Chipotle",
                timestamp: fixedDate(year: 2025, month: 5, day: 12, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_may13",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -12.50,
                currency: "USD",
                category: "Food & drink",
                note: "Latte and cookie",
                timestamp: fixedDate(year: 2025, month: 5, day: 13, hour: 9, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_may14",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -51.82,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 5, day: 14, hour: 15, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_may15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 5, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_may16",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -79.45,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 16, hour: 17, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_may16",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 16, hour: 18, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_may17",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -267.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→DEN",
                timestamp: fixedDate(year: 2025, month: 5, day: 17, hour: 9, minute: 42),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_may18",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -38.92,
                currency: "USD",
                category: "Food & drink",
                note: "Thai delivery",
                timestamp: fixedDate(year: 2025, month: 5, day: 18, hour: 19, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_rohan_may19",
                accountId: checkingId,
                vendor: "Rohan Mehta",
                amount: 40.00,
                currency: "USD",
                category: "Zelle",
                note: "CityRide split",
                timestamp: fixedDate(year: 2025, month: 5, day: 19, hour: 13, minute: 25),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_may20",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.85,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 20, hour: 7, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_may22",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 22, hour: 18, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_may22",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -71.34,
                currency: "USD",
                category: "Groceries",
                note: "Safeway",
                timestamp: fixedDate(year: 2025, month: 5, day: 22, hour: 14, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_may23",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -84.99,
                currency: "USD",
                category: "Shopping",
                note: "Noise-canceling earbuds",
                timestamp: fixedDate(year: 2025, month: 5, day: 23, hour: 10, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_may24",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.25,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 24, hour: 8, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_costco_may24",
                accountId: creditId,
                vendor: "Costco Wholesale",
                amount: -141.23,
                currency: "USD",
                category: "Groceries",
                note: "Monthly Costco run",
                timestamp: fixedDate(year: 2025, month: 5, day: 24, hour: 11, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_may25",
                accountId: creditId,
                vendor: "Target",
                amount: -39.87,
                currency: "USD",
                category: "Shopping",
                note: "Household supplies",
                timestamp: fixedDate(year: 2025, month: 5, day: 25, hour: 13, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_may26",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 5, day: 26, hour: 11, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_may27",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -31.56,
                currency: "USD",
                category: "Food & drink",
                note: "Wingstop",
                timestamp: fixedDate(year: 2025, month: 5, day: 27, hour: 20, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_jun",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 5, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_chevron_may30",
                accountId: creditId,
                vendor: "Chevron Gas",
                amount: -53.41,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 5, day: 30, hour: 14, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - April 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_apr1",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 4, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_apr",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "April rent",
                timestamp: fixedDate(year: 2025, month: 4, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_apr",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -350.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 4, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_apr",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 350.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 4, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_apr",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 1.92,
                currency: "USD",
                category: "Interest",
                note: "April interest payment",
                timestamp: fixedDate(year: 2025, month: 4, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_apr",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 4, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_apr",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 4, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_apr",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 4, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_apr",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -400.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 4, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_apr",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 400.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 4, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_apr",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -92.67,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 4, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_apr6",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.00,
                currency: "USD",
                category: "Food & drink",
                note: "Drip coffee",
                timestamp: fixedDate(year: 2025, month: 4, day: 6, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_apr7",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -48.91,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 7, hour: 17, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_apr8",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 8, hour: 18, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_apr8",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -29.43,
                currency: "USD",
                category: "Food & drink",
                note: "Five Guys",
                timestamp: fixedDate(year: 2025, month: 4, day: 8, hour: 20, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_apr9",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.30,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 9, hour: 7, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_apr10",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -62.47,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 4, day: 10, hour: 17, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_apr10",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -29.99,
                currency: "USD",
                category: "Shopping",
                note: "Umbrella + rain jacket",
                timestamp: fixedDate(year: 2025, month: 4, day: 10, hour: 10, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_apr11",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 11, hour: 8, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_apr12",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -35.18,
                currency: "USD",
                category: "Food & drink",
                note: "Sweetgreen",
                timestamp: fixedDate(year: 2025, month: 4, day: 12, hour: 19, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_apr12",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -48.73,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 4, day: 12, hour: 15, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_apr13",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -12.50,
                currency: "USD",
                category: "Food & drink",
                note: "Latte and scone",
                timestamp: fixedDate(year: 2025, month: 4, day: 13, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_apr15",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 4, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_apr16",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -87.12,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 16, hour: 17, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_apr16",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 16, hour: 18, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_seatgeek_apr17",
                accountId: creditId,
                vendor: "TicketBox",
                amount: -68.00,
                currency: "USD",
                category: "Entertainment",
                note: "Warriors playoff game",
                timestamp: fixedDate(year: 2025, month: 4, day: 17, hour: 11, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_apr18",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -42.67,
                currency: "USD",
                category: "Food & drink",
                note: "Nobu",
                timestamp: fixedDate(year: 2025, month: 4, day: 18, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_ava_apr19",
                accountId: checkingId,
                vendor: "Ava Torres",
                amount: -25.00,
                currency: "USD",
                category: "Zelle",
                note: "Parking split",
                timestamp: fixedDate(year: 2025, month: 4, day: 19, hour: 15, minute: 40),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_apr20",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -5.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 20, hour: 8, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_apr21",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -40.80,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL to Fisherman's Wharf",
                timestamp: fixedDate(year: 2025, month: 4, day: 21, hour: 11, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_apr22",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -67.98,
                currency: "USD",
                category: "Shopping",
                note: "Standing desk mat",
                timestamp: fixedDate(year: 2025, month: 4, day: 22, hour: 10, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_apr24",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -56.78,
                currency: "USD",
                category: "Groceries",
                note: "Trader Joe's",
                timestamp: fixedDate(year: 2025, month: 4, day: 24, hour: 14, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_apr25",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 25, hour: 8, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_apr26",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -26.93,
                currency: "USD",
                category: "Food & drink",
                note: "Pizza delivery",
                timestamp: fixedDate(year: 2025, month: 4, day: 26, hour: 19, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_apr27",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 27, hour: 19, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_may",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 4, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_apr29",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -44.56,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 4, day: 29, hour: 17, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - March 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_mar1_2025",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 3, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_mar_2025",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "March rent",
                timestamp: fixedDate(year: 2025, month: 3, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_mar_2025",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -350.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 3, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_mar_2025",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 350.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 3, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_mar_2025",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 1.78,
                currency: "USD",
                category: "Interest",
                note: "March interest payment",
                timestamp: fixedDate(year: 2025, month: 3, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_mar_2025",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 3, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_mar_2025",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 3, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_mar_2025",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 3, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_mar_2025",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -380.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 3, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_mar_2025",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 380.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 3, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_mar_2025",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -105.84,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 3, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_mar6_2025",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.50,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 6, hour: 8, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_mar6_2025",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -55.34,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 6, hour: 17, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_mar7_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 7, hour: 18, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_mar8_2025",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -31.24,
                currency: "USD",
                category: "Food & drink",
                note: "Panda Express",
                timestamp: fixedDate(year: 2025, month: 3, day: 8, hour: 19, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_mar8_2025",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -69.87,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 3, day: 8, hour: 17, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_mar9_2025",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -5.95,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 9, hour: 8, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_mar10_2025",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -43.98,
                currency: "USD",
                category: "Shopping",
                note: "Brita filter + vitamins",
                timestamp: fixedDate(year: 2025, month: 3, day: 10, hour: 14, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_mar11_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 11, hour: 8, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_mar12_2025",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -28.47,
                currency: "USD",
                category: "Food & drink",
                note: "Indian delivery",
                timestamp: fixedDate(year: 2025, month: 3, day: 12, hour: 20, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_mar13_2025",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -13.00,
                currency: "USD",
                category: "Food & drink",
                note: "Latte and pastry",
                timestamp: fixedDate(year: 2025, month: 3, day: 13, hour: 9, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_mar14_2025",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -52.17,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 3, day: 14, hour: 15, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_mar15_2025",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 3, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_mar16_2025",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -86.23,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 16, hour: 17, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_mar16_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -24.96,
                currency: "USD",
                category: "Transport",
                note: "Comfort to Twin Peaks",
                timestamp: fixedDate(year: 2025, month: 3, day: 16, hour: 14, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_mar17_2025",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -37.82,
                currency: "USD",
                category: "Food & drink",
                note: "Sushi delivery",
                timestamp: fixedDate(year: 2025, month: 3, day: 17, hour: 19, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_mar18_2025",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.85,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 18, hour: 7, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_maya_mar19_2025",
                accountId: checkingId,
                vendor: "Maya Patel",
                amount: 35.00,
                currency: "USD",
                category: "Zelle",
                note: "Coffee reimbursement",
                timestamp: fixedDate(year: 2025, month: 3, day: 19, hour: 13, minute: 30),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_mar20_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 20, hour: 18, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_mar20_2025",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -56.99,
                currency: "USD",
                category: "Shopping",
                note: "Bluetooth speaker",
                timestamp: fixedDate(year: 2025, month: 3, day: 20, hour: 10, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_delta_mar22_2025",
                accountId: creditId,
                vendor: "SkyTrip Airlines",
                amount: -245.00,
                currency: "USD",
                category: "Travel",
                note: "SFO→AUS",
                timestamp: fixedDate(year: 2025, month: 3, day: 22, hour: 9, minute: 42),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_mar24_2025",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -48.56,
                currency: "USD",
                category: "Groceries",
                note: "Whole Foods",
                timestamp: fixedDate(year: 2025, month: 3, day: 24, hour: 14, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_mar25_2025",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -7.25,
                currency: "USD",
                category: "Food & drink",
                note: "Cortado",
                timestamp: fixedDate(year: 2025, month: 3, day: 25, hour: 8, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_mar26_2025",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -33.14,
                currency: "USD",
                category: "Food & drink",
                note: "Chipotle",
                timestamp: fixedDate(year: 2025, month: 3, day: 26, hour: 19, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_costco_mar26_2025",
                accountId: creditId,
                vendor: "Costco Wholesale",
                amount: -132.89,
                currency: "USD",
                category: "Groceries",
                note: "Monthly Costco run",
                timestamp: fixedDate(year: 2025, month: 3, day: 26, hour: 11, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_mar27_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 27, hour: 18, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_apr_2025",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 3, day: 28, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_mar29_2025",
                accountId: creditId,
                vendor: "Target",
                amount: -43.21,
                currency: "USD",
                category: "Shopping",
                note: "Spring cleaning supplies",
                timestamp: fixedDate(year: 2025, month: 3, day: 29, hour: 13, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_mar30_2025",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -7.45,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 3, day: 30, hour: 8, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // MARK: - February 2025 (historical)

            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_feb1_2025",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 2, day: 1, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_rent_feb_2025",
                accountId: checkingId,
                vendor: "Avalon SF Apartments",
                amount: -2850.00,
                currency: "USD",
                category: "Rent",
                note: "February rent",
                timestamp: fixedDate(year: 2025, month: 2, day: 1, hour: 9, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_transfer_savings_feb_2025",
                accountId: checkingId,
                vendor: "Transfer to Savings (...1032)",
                amount: -300.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 2, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_transfer_feb_2025",
                accountId: savingsId,
                vendor: "Transfer from Total Checking (...6645)",
                amount: 300.00,
                currency: "USD",
                category: "Transfer",
                note: "Monthly savings",
                timestamp: fixedDate(year: 2025, month: 2, day: 1, hour: 9, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_savings_interest_feb_2025",
                accountId: savingsId,
                vendor: "Monthly interest",
                amount: 1.62,
                currency: "USD",
                category: "Interest",
                note: "February interest payment",
                timestamp: fixedDate(year: 2025, month: 2, day: 1, hour: 6, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_netflix_feb_2025",
                accountId: creditId,
                vendor: "Netflix",
                amount: -15.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 2, day: 1, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_icloud_feb_2025",
                accountId: creditId,
                vendor: "Apple iCloud",
                amount: -2.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly storage",
                timestamp: fixedDate(year: 2025, month: 2, day: 2, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_gym_feb_2025",
                accountId: creditId,
                vendor: "Bay Club Fitness",
                amount: -49.99,
                currency: "USD",
                category: "Health",
                note: "Monthly membership",
                timestamp: fixedDate(year: 2025, month: 2, day: 3, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_cc_payment_feb_2025",
                accountId: checkingId,
                vendor: "Freedom Unlimited (...2095)",
                amount: -350.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 2, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_cc_payment_received_feb_2025",
                accountId: creditId,
                vendor: "Payment from Total Checking (...6645)",
                amount: 350.00,
                currency: "USD",
                category: "Payment",
                note: "Statement payment",
                timestamp: fixedDate(year: 2025, month: 2, day: 4, hour: 10, minute: 18),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_pge_feb_2025",
                accountId: checkingId,
                vendor: "Pacific Gas & Electric",
                amount: -115.63,
                currency: "USD",
                category: "Utilities",
                note: "Auto pay",
                timestamp: fixedDate(year: 2025, month: 2, day: 5, hour: 7, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_feb6_2025",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 6, hour: 8, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_trader_joes_feb7_2025",
                accountId: creditId,
                vendor: "Trader Joe's",
                amount: -51.67,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 7, hour: 17, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb7_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -19.90,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 7, hour: 18, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_feb8_2025",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -33.18,
                currency: "USD",
                category: "Food & drink",
                note: "Thai delivery",
                timestamp: fixedDate(year: 2025, month: 2, day: 8, hour: 19, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bay_grocer_feb8_2025",
                accountId: creditId,
                vendor: "Bay Grocer",
                amount: -63.42,
                currency: "USD",
                category: "Groceries",
                note: "Weekly groceries",
                timestamp: fixedDate(year: 2025, month: 2, day: 8, hour: 17, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_feb9_2025",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -6.30,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 9, hour: 8, minute: 5),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_debit_amazon_feb10_2025",
                accountId: checkingId,
                vendor: "MegaMart",
                amount: -27.98,
                currency: "USD",
                category: "Shopping",
                note: "Chapstick + hand cream",
                timestamp: fixedDate(year: 2025, month: 2, day: 10, hour: 14, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb11_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 11, hour: 8, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_feb12_2025",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -29.56,
                currency: "USD",
                category: "Food & drink",
                note: "Chipotle",
                timestamp: fixedDate(year: 2025, month: 2, day: 12, hour: 20, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_feb13_2025",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -12.50,
                currency: "USD",
                category: "Food & drink",
                note: "Latte and scone",
                timestamp: fixedDate(year: 2025, month: 2, day: 13, hour: 9, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb13_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -22.40,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 13, hour: 18, minute: 25),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_restaurant_feb14_2025",
                accountId: creditId,
                vendor: "Zuni Cafe",
                amount: -128.50,
                currency: "USD",
                category: "Food & drink",
                note: "Valentine's Day dinner",
                timestamp: fixedDate(year: 2025, month: 2, day: 14, hour: 19, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_checking_payroll_feb15_2025",
                accountId: checkingId,
                vendor: "Northstar Studio Payroll",
                amount: 3200.00,
                currency: "USD",
                category: "Income",
                note: "Direct deposit",
                timestamp: fixedDate(year: 2025, month: 2, day: 15, hour: 8, minute: 30),
                status: .posted,
                sourceApp: "Northstar Studio Payroll",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_whole_foods_feb16_2025",
                accountId: creditId,
                vendor: "Whole Foods Market",
                amount: -78.91,
                currency: "USD",
                category: "Groceries",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 16, hour: 17, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_doordash_feb17_2025",
                accountId: creditId,
                vendor: "QuickBite",
                amount: -35.82,
                currency: "USD",
                category: "Food & drink",
                note: "Sugarfish",
                timestamp: fixedDate(year: 2025, month: 2, day: 17, hour: 19, minute: 45),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_starbucks_feb18_2025",
                accountId: creditId,
                vendor: "Starbucks",
                amount: -5.75,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 18, hour: 7, minute: 55),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_shell_feb18_2025",
                accountId: creditId,
                vendor: "Shell Gas Station",
                amount: -50.89,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 2, day: 18, hour: 15, minute: 20),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb19_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -40.80,
                currency: "USD",
                category: "Transport",
                note: "CityRideXL to Pac Heights",
                timestamp: fixedDate(year: 2025, month: 2, day: 19, hour: 18, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_amazon_feb20_2025",
                accountId: creditId,
                vendor: "MegaMart",
                amount: -34.99,
                currency: "USD",
                category: "Shopping",
                note: "Desk organizer",
                timestamp: fixedDate(year: 2025, month: 2, day: 20, hour: 10, minute: 30),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_zelle_leo_feb22_2025",
                accountId: checkingId,
                vendor: "Leo Chen",
                amount: -45.00,
                currency: "USD",
                category: "Zelle",
                note: "Ski trip gas money",
                timestamp: fixedDate(year: 2025, month: 2, day: 22, hour: 14, minute: 20),
                status: .posted,
                sourceApp: "Zelle",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_instacart_feb24_2025",
                accountId: creditId,
                vendor: "FreshCart",
                amount: -55.67,
                currency: "USD",
                category: "Groceries",
                note: "Safeway",
                timestamp: fixedDate(year: 2025, month: 2, day: 24, hour: 14, minute: 40),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_bb_feb25_2025",
                accountId: creditId,
                vendor: "Blue Bottle Coffee",
                amount: -6.25,
                currency: "USD",
                category: "Food & drink",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 25, hour: 8, minute: 35),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_target_feb25_2025",
                accountId: creditId,
                vendor: "Target",
                amount: -41.38,
                currency: "USD",
                category: "Shopping",
                note: "Household supplies",
                timestamp: fixedDate(year: 2025, month: 2, day: 25, hour: 13, minute: 10),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_spotify_mar_2025",
                accountId: creditId,
                vendor: "Spotify Premium",
                amount: -10.99,
                currency: "USD",
                category: "Entertainment",
                note: "Monthly subscription",
                timestamp: fixedDate(year: 2025, month: 2, day: 26, hour: 4, minute: 0),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_uber_feb27_2025",
                accountId: creditId,
                vendor: "CityRide Trip",
                amount: -16.50,
                currency: "USD",
                category: "Transport",
                note: nil,
                timestamp: fixedDate(year: 2025, month: 2, day: 27, hour: 19, minute: 15),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),
            Transaction(
                id: UUID(),
                externalId: "seed_credit_chevron_feb28_2025",
                accountId: creditId,
                vendor: "Chevron Gas",
                amount: -49.23,
                currency: "USD",
                category: "Auto & gas",
                note: "Fill up",
                timestamp: fixedDate(year: 2025, month: 2, day: 28, hour: 14, minute: 50),
                status: .posted,
                sourceApp: "MyBank",
                rawSource: "seed"
            ),

            // ── Hotel stays matching SkyTrip past trips ──────────────────

            // Oct 8-10, 2025 — JFK trip: Marriott NYC
            Transaction(id: UUID(), externalId: "seed_credit_marriott_nyc_oct", accountId: creditId,
                vendor: "Marriott Marquis NYC", amount: -776.44, currency: "USD", category: "Travel",
                note: "2 nights — King, City View",
                timestamp: fixedDate(year: 2025, month: 10, day: 10, hour: 12, minute: 0),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_jfk_oct8", accountId: creditId,
                vendor: "CityRide Trip", amount: -62.30, currency: "USD", category: "Transport",
                note: "JFK to Midtown Manhattan",
                timestamp: fixedDate(year: 2025, month: 10, day: 8, hour: 19, minute: 45),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_jfk_oct10", accountId: creditId,
                vendor: "CityRide Trip", amount: -58.15, currency: "USD", category: "Transport",
                note: "Midtown to JFK",
                timestamp: fixedDate(year: 2025, month: 10, day: 10, hour: 14, minute: 20),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),

            // Nov 3-4, 2025 — ORD trip: Hilton Chicago
            Transaction(id: UUID(), externalId: "seed_credit_hilton_chi_nov", accountId: creditId,
                vendor: "Hilton Chicago", amount: -305.62, currency: "USD", category: "Travel",
                note: "1 night — King, Lake View",
                timestamp: fixedDate(year: 2025, month: 11, day: 4, hour: 12, minute: 0),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_ord_nov3", accountId: creditId,
                vendor: "CityRide Trip", amount: -42.80, currency: "USD", category: "Transport",
                note: "O'Hare to Loop",
                timestamp: fixedDate(year: 2025, month: 11, day: 3, hour: 18, minute: 30),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_ord_nov4", accountId: creditId,
                vendor: "CityRide Trip", amount: -39.50, currency: "USD", category: "Transport",
                note: "Loop to O'Hare",
                timestamp: fixedDate(year: 2025, month: 11, day: 4, hour: 14, minute: 10),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),

            // Nov 25-29, 2025 — ATL trip: Marriott Atlanta
            Transaction(id: UUID(), externalId: "seed_credit_marriott_atl_nov", accountId: creditId,
                vendor: "Marriott Marquis Atlanta", amount: -939.28, currency: "USD", category: "Travel",
                note: "4 nights — Thanksgiving",
                timestamp: fixedDate(year: 2025, month: 11, day: 29, hour: 11, minute: 0),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_atl_nov25", accountId: creditId,
                vendor: "CityRide Trip", amount: -34.20, currency: "USD", category: "Transport",
                note: "ATL airport to downtown",
                timestamp: fixedDate(year: 2025, month: 11, day: 25, hour: 17, minute: 15),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_atl_nov29", accountId: creditId,
                vendor: "CityRide Trip", amount: -31.90, currency: "USD", category: "Transport",
                note: "Downtown to ATL airport",
                timestamp: fixedDate(year: 2025, month: 11, day: 29, hour: 8, minute: 45),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),

            // Dec 22-27, 2025 — BOS trip: Marriott Boston
            Transaction(id: UUID(), externalId: "seed_credit_marriott_bos_dec", accountId: creditId,
                vendor: "Marriott Copley Place Boston", amount: -1662.54, currency: "USD", category: "Travel",
                note: "5 nights — Christmas holiday",
                timestamp: fixedDate(year: 2025, month: 12, day: 27, hour: 11, minute: 0),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_bos_dec22", accountId: creditId,
                vendor: "CityRide Trip", amount: -38.70, currency: "USD", category: "Transport",
                note: "Logan Airport to Copley",
                timestamp: fixedDate(year: 2025, month: 12, day: 22, hour: 18, minute: 0),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_bos_dec27", accountId: creditId,
                vendor: "CityRide Trip", amount: -35.40, currency: "USD", category: "Transport",
                note: "Copley to Logan Airport",
                timestamp: fixedDate(year: 2025, month: 12, day: 27, hour: 13, minute: 30),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),

            // Jan 9-11, 2026 — LAX trip: Hilton Santa Monica
            Transaction(id: UUID(), externalId: "seed_credit_hilton_lax_jan", accountId: creditId,
                vendor: "Hilton Santa Monica", amount: -802.70, currency: "USD", category: "Travel",
                note: "2 nights — Ocean View",
                timestamp: fixedDate(year: 2026, month: 1, day: 11, hour: 12, minute: 0),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_lax_jan9", accountId: creditId,
                vendor: "CityRide Trip", amount: -45.60, currency: "USD", category: "Transport",
                note: "LAX to Santa Monica",
                timestamp: fixedDate(year: 2026, month: 1, day: 9, hour: 18, minute: 15),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_lax_jan11", accountId: creditId,
                vendor: "CityRide Trip", amount: -48.20, currency: "USD", category: "Transport",
                note: "Santa Monica to LAX",
                timestamp: fixedDate(year: 2026, month: 1, day: 11, hour: 14, minute: 30),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),

            // Feb 7-9, 2026 — SAN trip: Marriott San Diego
            Transaction(id: UUID(), externalId: "seed_credit_marriott_san_feb", accountId: creditId,
                vendor: "Marriott Marquis San Diego", amount: -641.70, currency: "USD", category: "Travel",
                note: "2 nights — Marina View",
                timestamp: fixedDate(year: 2026, month: 2, day: 9, hour: 11, minute: 0),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_san_feb7", accountId: creditId,
                vendor: "CityRide Trip", amount: -22.40, currency: "USD", category: "Transport",
                note: "SAN airport to Gaslamp",
                timestamp: fixedDate(year: 2026, month: 2, day: 7, hour: 17, minute: 45),
                status: .posted, sourceApp: "MyBank", rawSource: "seed"),
            Transaction(id: UUID(), externalId: "seed_credit_uber_san_feb9", accountId: creditId,
                vendor: "CityRide Trip", amount: -19.80, currency: "USD", category: "Transport",
                note: "Gaslamp to SAN airport",
                timestamp: fixedDate(year: 2026, month: 2, day: 9, hour: 13, minute: 0),
                status: .posted, sourceApp: "MyBank", rawSource: "seed")
        ]

        let zellePayee3Id = UUID()
        let zellePayee4Id = UUID()
        let zellePayee5Id = UUID()
        let zellePayee6Id = UUID()
        let zellePayee7Id = UUID()
        let zellePayee8Id = UUID()
        let zellePayee9Id = UUID()
        let zellePayee10Id = UUID()
        let zellePayee11Id = UUID()
        let gymPayeeId = UUID()

        payees = [
            Payee(id: creditCardPayeeId, name: "Freedom Unlimited (...2095)", category: "Credit Card"),
            Payee(id: zellePayeeId, name: "Maya Patel", category: "Zelle"),
            Payee(id: zelleRequestPayeeId, name: "Leo Chen", category: "Zelle"),
            Payee(id: zellePayee3Id, name: "Marcus Vale", category: "Zelle"),
            Payee(id: zellePayee4Id, name: "Camille Hart", category: "Zelle"),
            Payee(id: zellePayee5Id, name: "Theo Nguyen", category: "Zelle"),
            Payee(id: zellePayee6Id, name: "Ava Torres", category: "Zelle"),
            Payee(id: zellePayee7Id, name: "Spencer Bowman", category: "Zelle"),
            Payee(id: zellePayee8Id, name: "Noah Patel", category: "Zelle"),
            Payee(id: zellePayee9Id, name: "Grace Lin", category: "Zelle"),
            Payee(id: zellePayee10Id, name: "Rohan Mehta", category: "Zelle"),
            Payee(id: zellePayee11Id, name: "Elena Brooks", category: "Zelle"),
            Payee(id: utilitiesPayeeId, name: "Pacific Gas & Electric", category: "Utilities"),
            Payee(id: internetPayeeId, name: "Xfinity", category: "Internet"),
            Payee(id: waterPayeeId, name: "City Water Department", category: "Utilities"),
            Payee(id: phonePayeeId, name: "AT&T Wireless", category: "Phone"),
            Payee(id: insurancePayeeId, name: "Blue Oak Insurance", category: "Insurance"),
            Payee(id: gymPayeeId, name: "Bay Club Fitness", category: "Membership")
        ]

        scheduledPayments = [
            ScheduledPayment(
                id: UUID(),
                payeeId: creditCardPayeeId,
                amount: 240.00,
                scheduleDate: futureDate(year: 2026, month: 3, day: 27, hour: 9, minute: 0),
                note: "Monthly statement payment",
                status: .scheduled
            ),
            ScheduledPayment(
                id: UUID(),
                payeeId: internetPayeeId,
                amount: 89.99,
                scheduleDate: futureDate(year: 2026, month: 3, day: 18, hour: 8, minute: 0),
                note: "Home internet bill",
                status: .scheduled
            ),
            ScheduledPayment(
                id: UUID(),
                payeeId: waterPayeeId,
                amount: 64.12,
                scheduleDate: futureDate(year: 2026, month: 3, day: 21, hour: 8, minute: 0),
                note: "Monthly water service",
                status: .scheduled
            )
        ]

        activatedOfferIds = ["marriott", "iherb"]
        redeemedRewardPoints = 6800
        creditScore = 742
        userName = "Jordan"
        lastName = "Avery"

        saveState()
    }

    private func showToast(message: String, style: Toast.Style) {
        toast = Toast(message: message, style: style)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, self.toast?.message == message else { return }
            self.toast = nil
        }
    }
}

struct BankMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "mybank.outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordTransferEmail(amount: Double, from fromAccount: String, to toAccount: String) {
        guard let url = inboxURL() else { return }
        let amountText = String(format: "$%.2f", amount)
        let record = MailRecord(
            id: UUID(),
            from: "MyBank",
            subject: "Transfer Confirmation - \(amountText)",
            body: "Your transfer of \(amountText) from \(fromAccount) to \(toAccount) has been completed.\n\nThank you,\nMyBank",
            category: 1,
            date: Date()
        )
        ioQueue.async {
            var records = loadRecords(from: url)
            records.append(record)
            saveRecords(records, to: url)
        }
    }

    static func recordZelleEmail(amount: Double, to recipient: String) {
        guard let url = inboxURL() else { return }
        let amountText = String(format: "$%.2f", amount)
        let record = MailRecord(
            id: UUID(),
            from: "MyBank",
            subject: "Zelle Payment Sent - \(amountText) to \(recipient)",
            body: "You sent \(amountText) to \(recipient) via Zelle.\n\nThank you,\nMyBank",
            category: 1,
            date: Date()
        )
        ioQueue.async {
            var records = loadRecords(from: url)
            records.append(record)
            saveRecords(records, to: url)
        }
    }

    private static func inboxURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    private static func loadRecords(from url: URL) -> [MailRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MailRecord].self, from: data)) ?? []
    }

    private static func saveRecords(_ records: [MailRecord], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
