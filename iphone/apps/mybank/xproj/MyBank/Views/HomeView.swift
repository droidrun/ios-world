import SwiftUI

struct MyBankHomeView: View {
    @ObservedObject var store: BankStore
    @State private var showTransferSheet = false
    @State private var showZelleSheet = false
    @State private var showDepositSheet = false
    @State private var defaultDepositAccountId: UUID?
    @State private var showBillPaySheet = false
    @State private var billPayMode: BillPayMode = .payNow
    @State private var defaultBillPayeeId: UUID?
    @State private var selectedAccount: Account?
    @State private var selectedTransaction: Transaction?
    @State private var showInboxSheet = false
    @State private var showShortcutsSheet = false
    @State private var showSearchSheet = false
    @State private var showLinkAccountsSheet = false
    @State private var showManageSheet = false
    @State private var showStatementsSheet = false
    @State private var showPreferencesSheet = false
    @State private var showOffersSheet = false
    @State private var showCreditJourneySheet = false

    private var checkingAccount: Account? {
        store.accounts.first(where: { $0.type == .checking })
    }

    private var savingsAccount: Account? {
        store.accounts.first(where: { $0.type == .savings })
    }

    private var creditAccount: Account? {
        store.accounts.first(where: { $0.type == .credit })
    }

    private var bankAccounts: [Account] {
        store.accounts.filter { $0.type != .credit }
    }

    private var creditAccounts: [Account] {
        store.accounts.filter { $0.type == .credit }
    }

    private var zelleContacts: [Payee] {
        store.payees.filter { $0.category == "Zelle" }
    }

    private var billPayees: [Payee] {
        store.payees.filter { $0.category != "Zelle" }
    }

    private var creditCardPayee: Payee? {
        store.payees.first(where: { $0.category == "Credit Card" })
    }

    private var recentTransactions: [Transaction] {
        store.transactions.sorted(by: { $0.timestamp > $1.timestamp })
    }

    private var bankAccountsTotal: Double {
        bankAccounts.reduce(0) { $0 + $1.balance }
    }

    private var creditAccountsTotal: Double {
        creditAccounts.reduce(0) { $0 + $1.balance }
    }

    private var anySheetPresented: Bool {
        showTransferSheet || showZelleSheet || showDepositSheet ||
        showBillPaySheet || selectedAccount != nil || selectedTransaction != nil ||
        showSearchSheet || showLinkAccountsSheet || showManageSheet ||
        showStatementsSheet || showPreferencesSheet || showInboxSheet ||
        showShortcutsSheet || showOffersSheet || showCreditJourneySheet
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Top nav bar
                MyBankHomeToolbar(onLeftTap: { showShortcutsSheet = true }, onInboxTap: { showInboxSheet = true })
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // MARK: - Search bar
                Button { showSearchSheet = true } label: {
                    MyBankSearchBar()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .accessibilityIdentifier("home_search_bar")

                // MARK: - Action chips row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Plus button
                        Button(action: { showTransferSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(BankPalette.chaseBlue)
                                .frame(width: 44, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home_add_action_button")

                        MyBankChipButton(title: "Send | Zelle\u{00AE}") {
                            showZelleSheet = true
                        }
                        .accessibilityIdentifier("home_chip_zelle")
                        MyBankChipButton(title: "Deposit checks") {
                            defaultDepositAccountId = checkingAccount?.id
                            showDepositSheet = true
                        }
                        .accessibilityIdentifier("home_chip_deposit")
                        MyBankChipButton(title: "Pay bills") {
                            defaultBillPayeeId = nil
                            billPayMode = .payNow
                            showBillPaySheet = true
                        }
                        .accessibilityIdentifier("home_chip_pay_bills")
                        MyBankChipButton(title: "Pay credit card") {
                            defaultBillPayeeId = creditCardPayee?.id
                            billPayMode = .payNow
                            showBillPaySheet = true
                        }
                        .accessibilityIdentifier("home_chip_pay_credit_card")
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)

                // MARK: - Accounts header
                HStack {
                    Text("Accounts")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(BankPalette.ink)
                    Spacer()
                    Menu {
                        Button(action: { showManageSheet = true }) {
                            Label("Manage accounts", systemImage: "slider.horizontal.3")
                        }
                        Button(action: { showStatementsSheet = true }) {
                            Label("Account statements", systemImage: "doc.text")
                        }
                        Button(action: { showPreferencesSheet = true }) {
                            Label("Account preferences", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                    }
                    .accessibilityIdentifier("home_accounts_menu")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // MARK: - Bank Accounts card
                VStack(spacing: 0) {
                    // Blue header
                    HStack {
                        Text("Bank accounts (\(bankAccounts.count))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(Formatters.currencyString(amount: bankAccountsTotal, currencyCode: "USD"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(BankPalette.chaseNavy)

                    // Account rows
                    ForEach(Array(bankAccounts.enumerated()), id: \.element.id) { index, account in
                        Button {
                            selectedAccount = account
                        } label: {
                            VStack(spacing: 0) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 4) {
                                            Text(account.name.uppercased())
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(BankPalette.chaseBlue)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(BankPalette.chaseBlue)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.top, 16)
                                .padding(.horizontal, 16)

                                HStack {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(Formatters.currencyString(amount: account.balance, currencyCode: account.currency))
                                            .font(.system(size: 34, weight: .regular))
                                            .foregroundColor(BankPalette.ink)
                                        Text("Available balance")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)

                                if index < bankAccounts.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home_\(account.type == .checking ? "checking" : "savings")_card")
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // MARK: - Credit Cards card
                VStack(spacing: 0) {
                    // Blue header
                    HStack {
                        Text("Credit cards (\(creditAccounts.count))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(Formatters.currencyString(amount: creditAccountsTotal, currencyCode: "USD"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(BankPalette.chaseNavy)

                    ForEach(creditAccounts) { account in
                        Button {
                            selectedAccount = account
                        } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 4) {
                                    Text(account.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(BankPalette.chaseBlue)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(BankPalette.chaseBlue)
                                }
                                .padding(.top, 16)
                                .padding(.horizontal, 16)

                                HStack(alignment: .bottom, spacing: 16) {
                                    FreedomUnlimitedCardArtwork(height: 100)
                                        .frame(width: 158, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(Formatters.currencyString(amount: account.balance, currencyCode: account.currency))
                                            .font(.system(size: 34, weight: .regular))
                                            .foregroundColor(BankPalette.ink)
                                        Text("Current balance")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                                // Available credit
                                if let limit = account.creditLimit {
                                    HStack {
                                        Text("Available credit")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(Formatters.currencyString(amount: limit - account.balance, currencyCode: account.currency))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(BankPalette.ink)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 6)
                                }

                                // Automatic payments notice
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(BankPalette.positiveGreen)
                                    Text("You've set up automatic payments.")
                                        .font(.system(size: 14))
                                        .foregroundColor(BankPalette.chaseBlue)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 16)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home_credit_card")
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // MARK: - Direct credit-card payment commit button
                // Submits a credit-card payment in one tap (no separate sheet)
                // using the registered Credit Card payee and the current
                // credit-card balance. Preserves the chip-driven sheet flow
                // above; this is an additive, dedicated commit target.
                if let payee = creditCardPayee,
                   let credit = creditAccount, credit.balance > 0 {
                    Button(action: {
                        let amount = min(credit.balance, checkingAccount?.availableBalance ?? credit.balance)
                        if amount > 0 {
                            _ = store.payBill(to: payee.id, amount: amount, note: "Pay credit card")
                        }
                    }) {
                        HStack {
                            Text("Pay credit card now")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text(Formatters.currencyString(amount: credit.balance, currencyCode: credit.currency))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(BankPalette.chaseBlue)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("pay_credit_card_submit_button")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                // MARK: - Link external accounts
                Button(action: { showLinkAccountsSheet = true }) {
                    HStack {
                        Text("Link external accounts")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(BankPalette.ink)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home_link_external_accounts")
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

                // MARK: - Credit Journey
                Button { showCreditJourneySheet = true } label: {
                    CreditJourneyCard(
                        creditScore: store.creditScore,
                        updatedDate: store.accounts.map(\.lastUpdated).max() ?? Date()
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .accessibilityIdentifier("home_credit_journey_card")

                // MARK: - Offers
                MyBankInlineOffers(store: store, onViewAll: { showOffersSheet = true })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // MARK: - Recent activity
                if !recentTransactions.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Recent activity")
                                .font(.system(size: 22, weight: .bold))

                            ForEach(Array(recentTransactions.prefix(15).enumerated()), id: \.element.id) { index, transaction in
                                Button {
                                    selectedTransaction = transaction
                                } label: {
                                    MyBankActivityRow(
                                        transaction: transaction,
                                        accountName: accountName(for: transaction.accountId)
                                    )
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                                .accessibilityElement(children: .combine)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityIdentifier("transaction_cell_\(transaction.id.uuidString)")

                                if index < min(recentTransactions.count, 15) - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(BankPalette.pageBackground)
        .refreshable {
            try? await Task.sleep(nanoseconds: 600_000_000)
            store.importFromSharedLedger(silent: true)
        }
        .accessibilityHidden(anySheetPresented)
        .sheet(isPresented: $showTransferSheet) {
            TransferSheetView(
                accounts: bankAccounts,
                onTransfer: { fromId, toId, amount, note in
                    store.createTransfer(from: fromId, to: toId, amount: amount, note: note)
                }
            )
        }
        .sheet(isPresented: $showZelleSheet) {
            ZelleComposerSheet(payees: zelleContacts, availableBalance: checkingAccount?.availableBalance) { payeeId, amount, memo in
                store.sendZelle(to: payeeId, amount: amount, note: memo)
            }
        }
        .sheet(isPresented: $showDepositSheet) {
            DepositSheetView(
                accounts: bankAccounts,
                defaultAccountId: defaultDepositAccountId ?? checkingAccount?.id,
                onDeposit: { accountId, amount, note in
                    store.createDeposit(to: accountId, amount: amount, note: note)
                }
            )
        }
        .sheet(isPresented: $showBillPaySheet) {
            BillPayComposerSheet(
                payees: billPayees,
                defaultPayeeId: defaultBillPayeeId,
                defaultMode: billPayMode,
                availableBalance: checkingAccount?.availableBalance,
                onPay: { payeeId, amount, memo in
                    store.payBill(to: payeeId, amount: amount, note: memo)
                },
                onSchedule: { payeeId, amount, scheduleDate, memo in
                    store.schedulePayment(payeeId: payeeId, amount: amount, scheduleDate: scheduleDate, note: memo)
                }
            )
        }
        .sheet(item: $selectedAccount) { account in
            AccountDetailSheet(
                account: account,
                transactions: recentTransactions.filter { $0.accountId == account.id },
                primaryActionTitle: primaryActionTitle(for: account),
                primaryAction: {
                    selectedAccount = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        routePrimaryAction(for: account)
                    }
                },
                onSelectTransaction: { transaction in
                    selectedAccount = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        selectedTransaction = transaction
                    }
                }
            )
        }
        .sheet(item: $selectedTransaction) { transaction in
            NavigationStack {
                TransactionDetailView(
                    transaction: transaction,
                    account: store.accounts.first(where: { $0.id == transaction.accountId }),
                    onDispute: { store.disputeTransaction(id: transaction.id) }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { selectedTransaction = nil }
                    }
                }
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            MyBankSearchSheet(store: store)
        }
        .sheet(isPresented: $showLinkAccountsSheet) {
            LinkAccountsSheet()
        }
        .sheet(isPresented: $showManageSheet) {
            ManageAccountsSheet(accounts: store.accounts)
        }
        .sheet(isPresented: $showStatementsSheet) {
            StatementsSheet(accounts: store.accounts)
        }
        .sheet(isPresented: $showPreferencesSheet) {
            AccountPreferencesSheet()
        }
        .sheet(isPresented: $showInboxSheet) {
            MyBankInboxSheet(store: store)
        }
        .sheet(isPresented: $showShortcutsSheet) {
            MyBankShortcutSheet()
        }
        .sheet(isPresented: $showOffersSheet) {
            NavigationStack {
                MyBankOffersView(store: store)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showOffersSheet = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showCreditJourneySheet) {
            CreditJourneyDetailSheet(creditScore: store.creditScore, updatedDate: store.accounts.map(\.lastUpdated).max() ?? Date())
        }
    }

    private func accountName(for accountId: UUID) -> String {
        store.accounts.first(where: { $0.id == accountId })?.name ?? "MyBank account"
    }

    private func primaryActionTitle(for account: Account) -> String {
        switch account.type {
        case .checking: return "Transfer money"
        case .savings: return "Add a deposit"
        case .credit: return "Pay card"
        }
    }

    private func routePrimaryAction(for account: Account) {
        switch account.type {
        case .checking:
            showTransferSheet = true
        case .savings:
            defaultDepositAccountId = account.id
            showDepositSheet = true
        case .credit:
            defaultBillPayeeId = creditCardPayee?.id
            billPayMode = .payNow
            showBillPaySheet = true
        }
    }
}

// MARK: - Nav Bar (matches real MyBank: left icon, center logo, right profile)

// MARK: - Search Bar

private struct MyBankSearchBar: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Search transactions, payees, and more")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            Spacer()

            Image(systemName: "message")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(BankPalette.chaseBlue))
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
        )
    }
}

// MARK: - Chip Button (outlined pill, no icon)

private struct MyBankChipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(BankPalette.ink)
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .stroke(Color.gray.opacity(0.35), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Credit Journey Card

struct CreditJourneyCard: View {
    let creditScore: Int
    var updatedDate: Date = Date()

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "Updated \(formatter.string(from: updatedDate))"
    }

    private var scoreLabel: String {
        if creditScore >= 740 { return "Very Good" }
        if creditScore >= 670 { return "Good" }
        if creditScore >= 580 { return "Fair" }
        return "Needs Work"
    }

    private var scoreColor: Color {
        if creditScore >= 740 { return BankPalette.positiveGreen }
        if creditScore >= 670 { return Color.yellow }
        return Color.orange
    }

    private var progress: Double {
        Double(creditScore - 300) / Double(850 - 300)
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Credit Journey")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(BankPalette.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 20) {
                    CreditScoreGauge(score: creditScore, progress: progress, color: scoreColor)
                        .frame(width: 90, height: 90)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(creditScore)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(scoreColor)

                        Text(scoreLabel)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(scoreColor)

                        Text(formattedDate)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Text("Your VantageScore 3.0 by TransUnion")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct CreditScoreGauge: View {
    let score: Int
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(0))

            Circle()
                .trim(from: 0.15, to: 0.15 + (0.70 * progress))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(0))

            VStack {
                Spacer()
                HStack {
                    Text("300")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("850")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Inline Offers

private struct MyBankInlineOffers: View {
    @ObservedObject var store: BankStore
    var onViewAll: (() -> Void)? = nil

    private let topOffers: [(id: String, name: String, reward: String, icon: String)] = [
        ("turbotax", "TurboTax", "30% cash back", "percent"),
        ("eight_sleep", "Eight Sleep", "$100 cash back", "bed.double"),
        ("tonal", "Tonal", "$250 cash back", "dumbbell")
    ]

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Your offers")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button("View all") {
                        onViewAll?()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BankPalette.chaseBlue)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_offers_view_all_button")
                }

                ForEach(topOffers, id: \.id) { offer in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(BankPalette.chaseBlue.opacity(0.10))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: offer.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(BankPalette.chaseBlue)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(offer.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(BankPalette.ink)
                            Text(offer.reward)
                                .font(.system(size: 14))
                                .foregroundColor(BankPalette.positiveGreen)
                        }

                        Spacer()

                        Button(store.activatedOfferIds.contains(offer.id) ? "Added" : "Add") {
                            store.toggleOffer(offer.id)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(store.activatedOfferIds.contains(offer.id) ? BankPalette.positiveGreen : BankPalette.chaseBlue)
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home_offer_\(offer.id)_button")
                    }
                }
            }
        }
    }
}

// MARK: - Activity Row

struct MyBankActivityRow: View {
    let transaction: Transaction
    let accountName: String

    private var iconName: String {
        switch transaction.category.lowercased() {
        case "zelle": return "bolt.horizontal"
        case "deposit", "income": return "arrow.down.circle"
        case "transfer": return "arrow.left.arrow.right"
        case "payment": return "creditcard"
        case "food", "food & drink": return "fork.knife"
        case "groceries": return "cart"
        case "coffee": return "cup.and.saucer"
        case "transport", "rideshare": return "car"
        case "gas", "auto & gas": return "fuelpump"
        case "shopping": return "bag"
        case "entertainment": return "ticket"
        case "subscription", "subscriptions": return "tv"
        case "utilities": return "bolt"
        case "rent", "housing": return "house"
        case "health", "fitness": return "heart"
        case "travel": return "airplane"
        default: return "dollarsign.circle"
        }
    }

    private var iconTint: Color {
        switch transaction.category.lowercased() {
        case "zelle": return BankPalette.zelleViolet
        case "deposit", "income": return BankPalette.positiveGreen
        case "payment": return BankPalette.accentRed
        default: return BankPalette.chaseBlue
        }
    }

    private var signedAmount: String {
        Formatters.signedCurrencyString(amount: transaction.amount, currencyCode: transaction.currency)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Circle()
                .fill(iconTint.opacity(0.12))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconTint)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.vendor)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BankPalette.ink)

                Text(transaction.note ?? accountName)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Text(Formatters.monthDayYear.string(from: transaction.timestamp))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(signedAmount)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(transaction.amount < 0 ? BankPalette.ink : BankPalette.positiveGreen)

                Text(accountName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Account Detail Sheet

private struct AccountDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let account: Account
    let transactions: [Transaction]
    let primaryActionTitle: String
    let primaryAction: () -> Void
    var onSelectTransaction: ((Transaction) -> Void)? = nil

    private var subtitle: String {
        switch account.type {
        case .checking: return "Everyday spending and incoming deposits"
        case .savings: return "Savings progress and transfers"
        case .credit: return "Card activity, payments and utilization"
        }
    }

    private var metricTitle: String {
        switch account.type {
        case .checking: return "Available balance"
        case .savings: return "Available to transfer"
        case .credit: return "Available credit"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(account.name)
                                .font(.system(size: 28, weight: .bold))

                            Text(subtitle)
                                .font(.system(size: 17))
                                .foregroundColor(.secondary)

                            Text(Formatters.currencyString(amount: account.balance, currencyCode: account.currency))
                                .font(.system(size: 40, weight: .bold))

                            HStack {
                                Text(metricTitle)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(Formatters.currencyString(amount: account.availableBalance, currencyCode: account.currency))
                                    .fontWeight(.semibold)
                            }

                            Button(primaryActionTitle) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    primaryAction()
                                }
                            }
                            .buttonStyle(FilledPillButtonStyle(tint: BankPalette.chaseBlue))
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent activity")
                                .font(.system(size: 22, weight: .bold))

                            if transactions.isEmpty {
                                Text("No recent activity for this account.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(Array(transactions.prefix(15).enumerated()), id: \.element.id) { index, transaction in
                                    Button {
                                        onSelectTransaction?(transaction)
                                    } label: {
                                        MyBankActivityRow(transaction: transaction, accountName: account.name)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("account_activity_row_\(index)")

                                    if index < min(transactions.count, 15) - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(BankPalette.pageBackground)
            .navigationTitle("Account detail")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Notification Badge

struct NotificationBadge: View {
    let count: String

    var body: some View {
        Text(count)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(BankPalette.chaseBlue)
            )
    }
}

// MARK: - Toolbar (reusable for other views)

struct MyBankHomeToolbar: View {
    var onLeftTap: (() -> Void)? = nil
    var onInboxTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Button(action: { onLeftTap?() }) {
                Image(systemName: "list.clipboard")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("toolbar_clipboard")

            Spacer()

            MyBankPinwheelLogo(size: 34)
                .accessibilityIdentifier("toolbar_chase_logo")

            Spacer()

            Button(action: { onInboxTap?() }) {
                Image(systemName: "person.circle")
                    .font(.system(size: 26, weight: .thin))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("toolbar_profile")
        }
    }
}

// MARK: - Inbox Sheet

struct MyBankInboxSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: BankStore

    private var messages: [InboxMessage] {
        var result: [InboxMessage] = []

        if let nextScheduled = store.scheduledPayments
            .filter({ $0.status == .scheduled })
            .sorted(by: { $0.scheduleDate < $1.scheduleDate })
            .first,
           let payee = store.payees.first(where: { $0.id == nextScheduled.payeeId }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            result.append(InboxMessage(
                title: "Card payment scheduled",
                detail: "Your \(payee.name) payment is set for \(formatter.string(from: nextScheduled.scheduleDate)).",
                icon: "calendar",
                tint: BankPalette.chaseBlue
            ))
        }

        result.append(contentsOf: [
            InboxMessage(title: "Zelle reminder", detail: "Rohan Mehta is ready to receive money with Zelle.", icon: "bolt.horizontal", tint: BankPalette.zelleViolet),
            InboxMessage(title: "Rewards update", detail: "Your latest card purchases increased your available Ultimate Rewards points.", icon: "star", tint: BankPalette.positiveGreen),
            InboxMessage(title: "Credit score updated", detail: "Your VantageScore 3.0 has been refreshed. Check Credit Journey for details.", icon: "chart.line.uptrend.xyaxis", tint: BankPalette.positiveGreen),
            InboxMessage(title: "Direct deposit received", detail: "Northstar Studio Payroll deposited $3,200.00 into your checking account.", icon: "arrow.down.circle", tint: BankPalette.chaseBlue)
        ])

        return result
    }

    var body: some View {
        NavigationStack {
            List(messages) { message in
                HStack(spacing: 14) {
                    Circle()
                        .fill(message.tint.opacity(0.14))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: message.icon)
                                .foregroundColor(message.tint)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.title)
                            .font(.system(size: 17, weight: .semibold))
                        Text(message.detail)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct InboxMessage: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let tint: Color
}

// MARK: - Shortcut Sheet

private struct MyBankShortcutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let shortcuts: [(String, String)] = [
        ("Move money fast", "Use Transfer to move funds between checking and savings instantly."),
        ("Send with Zelle", "Pick a saved contact, enter an amount and send money from checking."),
        ("Handle bills", "Pay a bill now or schedule it for a future date from Pay & transfer."),
        ("Track activity", "Open any account card to see that account's recent activity."),
        ("Check your credit", "Scroll down on Home to see your Credit Journey score.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick shortcuts")
                                .font(.system(size: 24, weight: .bold))

                            ForEach(shortcuts, id: \.0) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.0)
                                        .font(.system(size: 17, weight: .semibold))
                                    Text(item.1)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Contact us")
                                .font(.system(size: 20, weight: .bold))
                            Text("Call 1-800-555-0198 for 24/7 customer support, or visit mybank.example/help for FAQs and live chat.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(BankPalette.pageBackground)
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Sapphire Preferred Card Artwork

struct SapphirePreferredCardArtwork: View {
    var height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack(alignment: .topLeading) {
                // Base card gradient - dark navy to sapphire blue
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.04, green: 0.08, blue: 0.22),
                                Color(red: 0.06, green: 0.14, blue: 0.36),
                                Color(red: 0.04, green: 0.10, blue: 0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Subtle metallic sheen overlay
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.clear,
                                Color(red: 0.2, green: 0.3, blue: 0.7).opacity(0.12),
                                Color.clear,
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Diagonal swoosh lines
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.6))
                    path.addQuadCurve(
                        to: CGPoint(x: w, y: h * 0.2),
                        control: CGPoint(x: w * 0.5, y: h * 0.25)
                    )
                    path.addLine(to: CGPoint(x: w, y: h * 0.28))
                    path.addQuadCurve(
                        to: CGPoint(x: 0, y: h * 0.68),
                        control: CGPoint(x: w * 0.5, y: h * 0.33)
                    )
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.06))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.72))
                    path.addQuadCurve(
                        to: CGPoint(x: w, y: h * 0.35),
                        control: CGPoint(x: w * 0.5, y: h * 0.4)
                    )
                    path.addLine(to: CGPoint(x: w, y: h * 0.42))
                    path.addQuadCurve(
                        to: CGPoint(x: 0, y: h * 0.79),
                        control: CGPoint(x: w * 0.5, y: h * 0.47)
                    )
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.04))

                // Card content
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        // MyBank pinwheel in white
                        MyBankPinwheelLogoWhite(size: h * 0.18)

                        Spacer()
                    }
                    .padding(.top, h * 0.12)
                    .padding(.leading, h * 0.14)

                    Spacer()

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("SAPPHIRE")
                                .font(.system(size: max(7, h * 0.10), weight: .medium, design: .default))
                                .foregroundColor(Color(red: 0.65, green: 0.72, blue: 0.85))
                                .kerning(1.5)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("PREFERRED")
                                .font(.system(size: max(5, h * 0.07), weight: .regular, design: .default))
                                .foregroundColor(Color(red: 0.55, green: 0.62, blue: 0.75))
                                .kerning(1.2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }

                        Spacer()

                        Text("VISA")
                            .font(.system(size: max(10, h * 0.14), weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .kerning(0.5)
                            .lineLimit(1)
                    }
                    .padding(.bottom, h * 0.10)
                    .padding(.horizontal, h * 0.14)
                }
            }
        }
        .frame(height: height)
        .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
    }
}

// White variant of the pinwheel for on-card use
private struct MyBankPinwheelLogoWhite: View {
    var size: CGFloat = 18

    var body: some View {
        MyBankPinwheelLogo(size: size, color: .white.opacity(0.9))
    }
}

// MARK: - Freedom Unlimited Card Artwork (kept for other views)

// MARK: - Search Sheet

private struct MyBankSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: BankStore
    @State private var searchText = ""

    private var filteredTransactions: [Transaction] {
        guard !searchText.isEmpty else { return [] }
        return store.transactions
            .filter {
                $0.vendor.localizedCaseInsensitiveContains(searchText) ||
                ($0.note ?? "").localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
            .sorted(by: { $0.timestamp > $1.timestamp })
            .prefix(20)
            .map { $0 }
    }

    private func accountName(for id: UUID) -> String {
        store.accounts.first(where: { $0.id == id })?.name ?? "MyBank account"
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section("Suggestions") {
                        ForEach(["Food & drink", "Transfer", "Zelle", "Coffee", "Groceries"], id: \.self) { term in
                            Button {
                                searchText = term
                            } label: {
                                Label(term, systemImage: "magnifyingglass")
                            }
                        }
                    }
                } else if filteredTransactions.isEmpty {
                    Text("No results for \"\(searchText)\"")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredTransactions) { txn in
                        NavigationLink {
                            TransactionDetailView(
                                transaction: txn,
                                account: store.accounts.first(where: { $0.id == txn.accountId })
                            )
                        } label: {
                            MyBankActivityRow(transaction: txn, accountName: accountName(for: txn.accountId))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search transactions")
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Link Accounts Sheet

private struct LinkAccountsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let institutions = ["FirstTrust Bank", "Pinnacle Financial", "Summit Credit", "Meridian Bank", "CoastalOne"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(BankPalette.chaseBlue)

                    Text("Link External Accounts")
                        .font(.system(size: 24, weight: .bold))

                    Text("View balances from other banks alongside your MyBank accounts. We use secure, encrypted connections to access your information.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Supported institutions")
                                .font(.system(size: 18, weight: .semibold))

                            ForEach(institutions, id: \.self) { bank in
                                HStack {
                                    Image(systemName: "building.columns")
                                        .foregroundColor(BankPalette.chaseBlue)
                                        .frame(width: 28)
                                    Text(bank)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    Button("Connect an account") {
                        dismiss()
                    }
                    .buttonStyle(FilledPillButtonStyle(tint: BankPalette.chaseBlue))
                }
                .padding(20)
            }
            .background(BankPalette.pageBackground)
            .navigationTitle("Link accounts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Manage Accounts Sheet

private struct ManageAccountsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]

    var body: some View {
        NavigationStack {
            List(accounts) { account in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(account.name)
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Text(account.type.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.gray.opacity(0.12)))
                    }
                    HStack {
                        Text("Balance")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(Formatters.currencyString(amount: account.balance, currencyCode: account.currency))
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 15))
                    HStack {
                        Text("Available")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(Formatters.currencyString(amount: account.availableBalance, currencyCode: account.currency))
                    }
                    .font(.system(size: 15))
                    HStack {
                        Text("Last updated")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(Formatters.monthDayYear.string(from: account.lastUpdated))
                    }
                    .font(.system(size: 15))
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Manage accounts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Statements Sheet

private struct StatementsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]

    private let periods = ["February 2026", "January 2026", "December 2025", "November 2025", "October 2025"]

    @State private var downloadedStatement: String?
    @State private var showDownloadAlert = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(accounts) { account in
                    Section(account.name) {
                        ForEach(periods, id: \.self) { period in
                            Button {
                                downloadedStatement = "\(account.name) \u{2013} \(period)"
                                showDownloadAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(BankPalette.chaseBlue)
                                        .frame(width: 24)
                                    Text(period)
                                    Spacer()
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(BankPalette.chaseBlue)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("statement_row_\(period.replacingOccurrences(of: " ", with: "_").lowercased())")
                        }
                    }
                }
            }
            .navigationTitle("Statements")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Statement downloaded", isPresented: $showDownloadAlert, presenting: downloadedStatement) { _ in
                Button("OK") {}
            } message: { statement in
                Text("Your \(statement) statement has been saved to Files.")
            }
        }
    }
}

// MARK: - Account Preferences Sheet

private struct AccountPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var paperlessStatements = true
    @State private var overdraftProtection = true
    @State private var roundUpSavings = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Statements") {
                    Toggle("Paperless statements", isOn: $paperlessStatements)
                }
                Section("Overdraft") {
                    Toggle("Overdraft protection", isOn: $overdraftProtection)
                }
                Section("Savings") {
                    Toggle("Round-up transfers to savings", isOn: $roundUpSavings)
                }
            }
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FreedomUnlimitedCardArtwork: View {
    var height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let minDimension = min(geometry.size.width, geometry.size.height)
            let cornerRadius = max(10, minDimension * 0.18)
            let inset = max(8, minDimension * 0.14)
            let freedomSize = max(10, minDimension * 0.22)
            let unlimitedSize = max(6, minDimension * 0.12)
            let visaSize = max(12, minDimension * 0.26)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.03, green: 0.29, blue: 0.59),
                                Color(red: 0.02, green: 0.53, blue: 0.86),
                                Color(red: 0.10, green: 0.18, blue: 0.39)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), .clear, Color.cyan.opacity(0.28), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: max(2, minDimension * 0.03)) {
                    Text("freedom")
                        .font(.system(size: freedomSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text("UNLIMITED")
                        .font(.system(size: unlimitedSize, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.69, green: 0.82, blue: 0.22))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .padding(inset)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("VISA")
                            .font(.system(size: visaSize, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .padding(inset)
                    }
                }
            }
        }
        .frame(height: height)
        .shadow(color: Color.black.opacity(0.14), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Credit Journey Detail Sheet

private struct CreditJourneyDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let creditScore: Int
    var updatedDate: Date = Date()

    private var scoreLabel: String {
        if creditScore >= 740 { return "Very Good" }
        if creditScore >= 670 { return "Good" }
        if creditScore >= 580 { return "Fair" }
        return "Needs Work"
    }

    private var scoreColor: Color {
        if creditScore >= 740 { return BankPalette.positiveGreen }
        if creditScore >= 670 { return Color.yellow }
        return Color.orange
    }

    private var progress: Double {
        Double(creditScore - 300) / Double(850 - 300)
    }

    private let factors: [(String, String, String)] = [
        ("Payment history", "On-time payments", "checkmark.circle.fill"),
        ("Credit utilization", "Below 30%", "chart.pie"),
        ("Credit age", "Good average age", "clock"),
        ("New credit", "No recent inquiries", "plus.circle"),
        ("Credit mix", "Healthy account types", "rectangle.on.rectangle")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Your VantageScore\u{00AE} 3.0")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack(spacing: 20) {
                                CreditScoreGauge(score: creditScore, progress: progress, color: scoreColor)
                                    .frame(width: 100, height: 100)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\(creditScore)")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(scoreColor)
                                    Text(scoreLabel)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(scoreColor)
                                    let formatter: DateFormatter = {
                                        let f = DateFormatter()
                                        f.dateFormat = "MMM d, yyyy"
                                        return f
                                    }()
                                    Text("Updated \(formatter.string(from: updatedDate))")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("Provided by TransUnion. Updated monthly.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Score factors")
                                .font(.system(size: 20, weight: .bold))

                            ForEach(factors, id: \.0) { factor in
                                HStack(spacing: 12) {
                                    Image(systemName: factor.2)
                                        .font(.system(size: 20))
                                        .foregroundColor(BankPalette.positiveGreen)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(factor.0)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(factor.1)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About this score")
                                .font(.system(size: 18, weight: .bold))
                            Text("VantageScore 3.0 is calculated using your TransUnion credit report. It ranges from 300 to 850. Checking your score here does not affect it.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(BankPalette.pageBackground)
            .navigationTitle("Credit Journey")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
