import SwiftUI

struct MyBankPayTransferView: View {
    @ObservedObject var store: BankStore
    @State private var showTransferSheet = false
    @State private var showZelleSheet = false
    @State private var showBillPaySheet = false
    @State private var showDepositSheet = false
    @State private var billPayMode: BillPayMode = .payNow
    @State private var defaultBillPayeeId: UUID?
    @State private var showWireSheet = false
    @State private var showExternalSheet = false
    @State private var showRequestSheet = false

    private var checkingAccount: Account? {
        store.accounts.first(where: { $0.type == .checking })
    }

    private var bankAccounts: [Account] {
        store.accounts.filter { $0.type != .credit }
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

    private var householdPayees: [Payee] {
        billPayees.filter { $0.category != "Credit Card" }
    }

    private var upcomingPayments: [(payment: ScheduledPayment, payee: Payee)] {
        store.scheduledPayments
            .filter { $0.status == .scheduled }
            .compactMap { payment in
                guard let payee = store.payees.first(where: { $0.id == payment.payeeId }) else { return nil }
                return (payment, payee)
            }
            .sorted(by: { $0.payment.scheduleDate < $1.payment.scheduleDate })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero banner (matches Rewards style)
                ZStack(alignment: .topLeading) {
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 0.04, green: 0.22, blue: 0.50),
                                Color(red: 0.06, green: 0.32, blue: 0.62),
                                Color(red: 0.04, green: 0.18, blue: 0.44)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 160, height: 160)
                            .offset(x: 100, y: 30)

                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 100, height: 100)
                            .offset(x: -80, y: -10)

                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 48, weight: .regular))
                            .foregroundColor(Color(red: 0.72, green: 0.78, blue: 0.90))
                            .rotationEffect(.degrees(-15))
                            .offset(x: 20, y: 15)

                        LinearGradient(
                            colors: [Color.black.opacity(0.20), Color.black.opacity(0.05), Color.black.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .frame(height: 240)
                    .ignoresSafeArea(edges: .top)
                    .clipped()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pay & transfer")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Send, pay, and manage your money")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 60)
                    .padding(.leading, 20)
                }

                VStack(alignment: .leading, spacing: 18) {
                    // Action grid overlapping header
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        PayTransferActionCard(
                            title: "Transfer",
                            subtitle: "Between accounts",
                            icon: "arrow.left.arrow.right",
                            accent: BankPalette.chaseBlue
                        ) {
                            showTransferSheet = true
                        }

                        PayTransferActionCard(
                            title: "Send with Zelle",
                            subtitle: "To people you know",
                            icon: "bolt.horizontal",
                            accent: BankPalette.zelleViolet
                        ) {
                            showZelleSheet = true
                        }

                        PayTransferActionCard(
                            title: "Pay bills",
                            subtitle: "Utilities & services",
                            icon: "doc.text",
                            accent: BankPalette.chaseTeal
                        ) {
                            defaultBillPayeeId = nil
                            billPayMode = .payNow
                            showBillPaySheet = true
                        }

                        PayTransferActionCard(
                            title: "Pay credit card",
                            subtitle: "Make a payment",
                            icon: "creditcard",
                            accent: BankPalette.accentRed
                        ) {
                            defaultBillPayeeId = creditCardPayee?.id
                            billPayMode = .payNow
                            showBillPaySheet = true
                        }
                    }
                    .offset(y: -40)
                    .padding(.bottom, -40)

                    SurfaceCard(padding: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            PayTransferListRow(title: "Deposit checks", icon: "camera.viewfinder", accessId: "pay_deposit_checks") {
                                showDepositSheet = true
                            }
                            Divider().padding(.leading, 56)
                            PayTransferListRow(title: "Wire transfers", icon: "globe", accessId: "pay_wire_transfers") {
                                showWireSheet = true
                            }
                            Divider().padding(.leading, 56)
                            PayTransferListRow(title: "External transfers", icon: "building.2", accessId: "pay_external_transfers") {
                                showExternalSheet = true
                            }
                            Divider().padding(.leading, 56)
                            PayTransferListRow(title: "Request money with Zelle", icon: "arrow.down.circle", accessId: "pay_request_zelle") {
                                showRequestSheet = true
                            }
                        }
                    }

                    if !zelleContacts.isEmpty {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Zelle contacts")
                                    .font(.system(size: 20, weight: .bold))

                                ForEach(zelleContacts) { contact in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(BankPalette.zelleViolet.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(String(contact.name.prefix(1)))
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(BankPalette.zelleViolet)
                                            )

                                        Text(contact.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(BankPalette.ink)

                                        Spacer()

                                        Button("Send") {
                                            showZelleSheet = true
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(BankPalette.chaseBlue)
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    if !upcomingPayments.isEmpty {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Upcoming payments")
                                        .font(.system(size: 20, weight: .bold))
                                    Spacer()
                                    Button("Schedule") {
                                        defaultBillPayeeId = nil
                                        billPayMode = .schedule
                                        showBillPaySheet = true
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(BankPalette.chaseBlue)
                                    .buttonStyle(.plain)
                                }

                                ForEach(upcomingPayments, id: \.payment.id) { item in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(BankPalette.chaseBlue.opacity(0.12))
                                            .frame(width: 38, height: 38)
                                            .overlay(
                                                Image(systemName: "calendar")
                                                    .foregroundColor(BankPalette.chaseBlue)
                                            )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.payee.name)
                                                .font(.system(size: 16, weight: .semibold))
                                            Text(Formatters.monthDayYear.string(from: item.payment.scheduleDate))
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text(Formatters.currencyString(amount: item.payment.amount, currencyCode: "USD"))
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                            }
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Bill payees")
                                .font(.system(size: 20, weight: .bold))

                            ForEach(householdPayees) { payee in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(BankPalette.chaseBlue.opacity(0.10))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: iconName(for: payee.category))
                                                .font(.system(size: 14))
                                                .foregroundColor(BankPalette.chaseBlue)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(payee.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(BankPalette.ink)
                                        Text(payee.category)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button("Pay") {
                                        defaultBillPayeeId = payee.id
                                        billPayMode = .payNow
                                        showBillPaySheet = true
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(BankPalette.chaseBlue)
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(BankPalette.pageBackground)
        .sheet(isPresented: $showWireSheet) {
            WireTransferSheet(accounts: bankAccounts)
        }
        .sheet(isPresented: $showExternalSheet) {
            ExternalTransferSheet(accounts: bankAccounts)
        }
        .sheet(isPresented: $showRequestSheet) {
            RequestMoneySheet(contacts: zelleContacts)
        }
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
        .sheet(isPresented: $showDepositSheet) {
            DepositSheetView(
                accounts: bankAccounts,
                defaultAccountId: checkingAccount?.id,
                onDeposit: { accountId, amount, note in
                    store.createDeposit(to: accountId, amount: amount, note: note)
                }
            )
        }
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "Utilities": return "bolt"
        case "Internet": return "wifi"
        case "Phone": return "iphone"
        case "Insurance": return "shield"
        default: return "doc.text"
        }
    }
}

private struct PayTransferActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(accent)
                    )

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(BankPalette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(BankPalette.outline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PayTransferListRow: View {
    let title: String
    let icon: String
    var accessId: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(BankPalette.chaseBlue)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(BankPalette.ink)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessId)
    }
}

// MARK: - Wire Transfer Sheet

private struct WireTransferSheet: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]

    @State private var selectedAccountId: UUID?
    @State private var recipientName = ""
    @State private var routingNumber = ""
    @State private var accountNumber = ""
    @State private var amount = ""
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    Picker("Account", selection: $selectedAccountId) {
                        Text("Select account").tag(UUID?.none)
                        ForEach(accounts) { account in
                            Text("\(account.name) \u{2013} \(Formatters.currencyString(amount: account.availableBalance, currencyCode: account.currency))")
                                .tag(Optional(account.id))
                        }
                    }
                }
                Section("Recipient") {
                    TextField("Recipient name", text: $recipientName)
                    TextField("Routing number (ABA)", text: $routingNumber)
                        .keyboardType(.numberPad)
                    TextField("Account number", text: $accountNumber)
                        .keyboardType(.numberPad)
                }
                Section("Amount") {
                    TextField("$0.00", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section("Memo (optional)") {
                    TextField("Reference or memo", text: $memo)
                }
                Section {
                    Button("Send wire transfer") {
                        dismiss()
                    }
                    .disabled(selectedAccountId == nil || recipientName.isEmpty || routingNumber.isEmpty || accountNumber.isEmpty || (Double(amount) ?? 0) <= 0)
                }
            }
            .navigationTitle("Wire transfer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { selectedAccountId = accounts.first?.id }
        }
    }
}

// MARK: - External Transfer Sheet

private struct ExternalTransferSheet: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]

    @State private var selectedAccountId: UUID?
    @State private var bankName = ""
    @State private var externalAccountNumber = ""
    @State private var externalRoutingNumber = ""
    @State private var amount = ""

    private let institutions = ["FirstTrust Bank", "Pinnacle Financial", "Summit Credit", "Meridian Bank", "CoastalOne", "NorthPoint", "Evergreen Bank"]

    var body: some View {
        NavigationStack {
            Form {
                Section("From MyBank account") {
                    Picker("Account", selection: $selectedAccountId) {
                        Text("Select account").tag(UUID?.none)
                        ForEach(accounts) { account in
                            Text("\(account.name) \u{2013} \(Formatters.currencyString(amount: account.availableBalance, currencyCode: account.currency))")
                                .tag(Optional(account.id))
                        }
                    }
                }
                Section("To external account") {
                    Picker("Institution", selection: $bankName) {
                        Text("Select a bank").tag("")
                        ForEach(institutions, id: \.self) { bank in
                            Text(bank).tag(bank)
                        }
                    }
                    TextField("Routing number", text: $externalRoutingNumber)
                        .keyboardType(.numberPad)
                    TextField("Account number", text: $externalAccountNumber)
                        .keyboardType(.numberPad)
                }
                Section("Amount") {
                    TextField("$0.00", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Button("Submit transfer") {
                        dismiss()
                    }
                    .disabled(selectedAccountId == nil || bankName.isEmpty || externalAccountNumber.isEmpty || (Double(amount) ?? 0) <= 0)
                }
            }
            .navigationTitle("External transfer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { selectedAccountId = accounts.first?.id }
        }
    }
}

// MARK: - Request Money Sheet

private struct RequestMoneySheet: View {
    @Environment(\.dismiss) private var dismiss
    let contacts: [Payee]

    @State private var selectedContactId: UUID?
    @State private var amount = ""
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Request from") {
                    Picker("Contact", selection: $selectedContactId) {
                        Text("Select a contact").tag(UUID?.none)
                        ForEach(contacts) { contact in
                            Text(contact.name).tag(Optional(contact.id))
                        }
                    }
                }
                Section("Amount") {
                    TextField("$0.00", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section("What's it for?") {
                    TextField("Add a note", text: $memo)
                }
                Section {
                    Button("Request with Zelle") {
                        dismiss()
                    }
                    .disabled(selectedContactId == nil || (Double(amount) ?? 0) <= 0)
                }
            }
            .navigationTitle("Request money")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
