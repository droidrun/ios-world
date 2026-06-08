import SwiftUI

private enum TrackMetric: String, CaseIterable, Identifiable {
    case spending = "Monthly spending"
    case netWorth = "Net worth"

    var id: Self { self }
}

// MARK: - Plan & Track Tab

struct MyBankPlanTrackView: View {
    @ObservedObject var store: BankStore
    @State private var selectedMetric: TrackMetric = .spending
    @State private var showAdvisorSheet = false
    @State private var showTransfersSheet = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var reportingDate: Date {
        store.transactions.map(\.timestamp).max() ?? Date()
    }

    private var monthStart: Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: calendar.dateComponents([.year, .month], from: reportingDate)) ?? reportingDate
    }

    private var spendingTransactions: [Transaction] {
        store.transactions.filter {
            $0.timestamp >= monthStart &&
            $0.amount < 0 &&
            !["Transfer", "Payment", "Deposit"].contains($0.category)
        }
    }

    private var monthlySpending: Double {
        spendingTransactions.reduce(0) { $0 + abs($1.amount) }
    }

    private var spendingBreakdown: [(String, Double)] {
        Dictionary(grouping: spendingTransactions, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + abs($1.amount) }) }
            .sorted(by: { $0.1 > $1.1 })
            .prefix(3)
            .map { $0 }
    }

    private var netWorthBreakdown: [(String, Double)] {
        store.accounts.map { account in
            let value = account.type == .credit ? -account.balance : account.balance
            return (account.type.displayName, value)
        }
    }

    private var netWorth: Double {
        netWorthBreakdown.reduce(0) { $0 + $1.1 }
    }

    private var usesCompactLayout: Bool {
        dynamicTypeSize >= .xLarge
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero banner (matches Rewards style)
                ZStack(alignment: .topLeading) {
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.28, blue: 0.22),
                                Color(red: 0.08, green: 0.36, blue: 0.28),
                                Color(red: 0.04, green: 0.22, blue: 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 140, height: 140)
                            .offset(x: 90, y: 40)

                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 100, height: 100)
                            .offset(x: -70, y: -10)

                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48, weight: .regular))
                            .foregroundColor(Color(red: 0.85, green: 0.68, blue: 0.25))
                            .offset(x: 20, y: 15)

                        LinearGradient(
                            colors: [Color.black.opacity(0.20), Color.black.opacity(0.05), Color.black.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .frame(height: 280)
                    .ignoresSafeArea(edges: .top)
                    .clipped()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plan & track")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Track your spending and goals")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 60)
                    .padding(.leading, 20)
                }

                VStack(spacing: 18) {
                    // Hero card overlapping the header
                    SurfaceCard {
                        VStack(alignment: .center, spacing: 18) {
                            Text("Turn your plans\ninto actions")
                                .font(.system(size: usesCompactLayout ? 24 : 28, weight: .bold))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.8)

                            Text("Use your MyBank activity to understand spending, track progress and keep moving toward your next goal.")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Review money moves") {
                                selectedMetric = .spending
                            }
                            .buttonStyle(FilledPillButtonStyle(tint: BankPalette.chaseBlue))
                        }
                    }
                    .offset(y: -72)
                    .padding(.bottom, -72)

                    // Advisor card with chart icon
                    Button { showAdvisorSheet = true } label: {
                        SurfaceCard {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color(red: 0.90, green: 0.94, blue: 1.0))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.system(size: 22))
                                            .foregroundColor(BankPalette.chaseBlue)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Meet with a MyBank advisor")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(BankPalette.ink)
                                    Text("Get a plan built around your activity.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Track your money section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Track your money")
                            .font(.system(size: 24, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        SurfaceCard(padding: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) {
                                    ForEach(TrackMetric.allCases) { metric in
                                        Button {
                                            selectedMetric = metric
                                        } label: {
                                            Text(metric.rawValue)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(selectedMetric == metric ? BankPalette.chaseBlue : .secondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.75)
                                                .overlay(alignment: .bottom) {
                                                    Rectangle()
                                                        .fill(selectedMetric == metric ? BankPalette.chaseBlue : .clear)
                                                        .frame(height: 3)
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Divider()

                                VStack(alignment: .leading, spacing: 16) {
                                    Text(selectedMetric == .spending
                                         ? Formatters.currencyString(amount: monthlySpending, currencyCode: "USD")
                                         : Formatters.currencyString(amount: netWorth, currencyCode: "USD"))
                                        .font(.system(size: usesCompactLayout ? 38 : 44, weight: .regular))
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.55)

                                    Text(selectedMetric == .spending
                                         ? "Spending in \(DateFormatter.monthAndYear.string(from: reportingDate))"
                                         : "Estimated net worth across your MyBank accounts")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    VStack(spacing: 12) {
                                        if selectedMetric == .spending {
                                            ForEach(spendingBreakdown, id: \.0) { item in
                                                TrackBreakdownRow(title: item.0, value: -item.1, currencyCode: "USD", positive: false)
                                            }
                                        } else {
                                            ForEach(netWorthBreakdown, id: \.0) { item in
                                                TrackBreakdownRow(title: item.0, value: item.1, currencyCode: "USD", positive: item.1 >= 0)
                                            }
                                        }
                                    }
                                }
                                .padding(20)
                            }
                        }
                    }

                    // Stay on top of transfers card
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Circle()
                                .fill(Color(red: 0.90, green: 0.94, blue: 1.0))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(BankPalette.chaseBlue)
                                )

                            Text("Stay on top of transfers")
                                .font(.system(size: 20, weight: .semibold))

                            Text("Move money between accounts and keep your savings on track.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)

                            Button("Review transfers") {
                                showTransfersSheet = true
                            }
                            .buttonStyle(FilledPillButtonStyle(tint: BankPalette.chaseBlue))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(BankPalette.pageBackground)
        .sheet(isPresented: $showAdvisorSheet) {
            AdvisorSheet()
        }
        .sheet(isPresented: $showTransfersSheet) {
            TransfersSheet(store: store)
        }
    }
}

private struct TransfersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: BankStore

    private var transferTransactions: [Transaction] {
        store.transactions
            .filter { $0.category == "Transfer" || $0.category == "Zelle" }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private func accountName(for id: UUID) -> String {
        store.accounts.first(where: { $0.id == id })?.name ?? "MyBank account"
    }

    var body: some View {
        NavigationStack {
            List {
                if transferTransactions.isEmpty {
                    Text("No transfers found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(transferTransactions) { txn in
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
            .navigationTitle("Transfers")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Rewards Tab

struct MyBankRewardsView: View {
    @ObservedObject var store: BankStore
    @State private var selectedBenefitId = "travel"
    @State private var showRewardSheet = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let shortcuts: [BenefitShortcut] = [
        BenefitShortcut(id: "travel", title: "Book\ntravel", icon: "airplane", summary: "See flights, stays and trips tied to your rewards.", cta: "Explore travel"),
        BenefitShortcut(id: "cash_back", title: "Cash\nback", icon: "dollarsign.square", summary: "Turn points into a statement credit or deposit.", cta: "Use cash back"),
        BenefitShortcut(id: "gift_cards", title: "Gift\ncards", icon: "giftcard", summary: "Browse gift card redemptions across popular brands.", cta: "Browse gift cards"),
        BenefitShortcut(id: "shop", title: "Ways to\nshop", icon: "cart", summary: "Apply rewards directly at checkout when eligible.", cta: "View shopping options")
    ]

    private var creditAccount: Account? {
        store.accounts.first(where: { $0.type == .credit })
    }

    private var availablePoints: Int {
        let spending = store.transactions
            .filter { transaction in
                creditAccount.map { transaction.accountId == $0.id } ?? false &&
                transaction.amount < 0 &&
                transaction.status == .posted
            }
            .reduce(0) { $0 + abs($1.amount) }
        return max(0, Int((spending * 100).rounded()) - store.redeemedRewardPoints)
    }

    private var pendingPoints: Int {
        let pendingSpending = store.transactions
            .filter { transaction in
                creditAccount.map { transaction.accountId == $0.id } ?? false &&
                transaction.amount < 0 &&
                transaction.status == .pending
            }
            .reduce(0) { $0 + abs($1.amount) }
        return Int((pendingSpending * 100).rounded())
    }

    private var selectedBenefit: BenefitShortcut {
        shortcuts.first(where: { $0.id == selectedBenefitId }) ?? shortcuts[0]
    }

    private var usesCompactLayout: Bool {
        dynamicTypeSize >= .xLarge
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero banner with travel imagery
                ZStack(alignment: .topLeading) {
                    // Background gradient simulating travel photo
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.58, blue: 0.68),
                                Color(red: 0.55, green: 0.65, blue: 0.72),
                                Color(red: 0.50, green: 0.62, blue: 0.70)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        // Decorative clouds/circles
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 140, height: 140)
                            .offset(x: 80, y: 40)

                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 100, height: 100)
                            .offset(x: -60, y: -10)

                        // Airplane icon
                        Image(systemName: "airplane")
                            .font(.system(size: 48, weight: .regular))
                            .foregroundColor(Color(red: 0.72, green: 0.62, blue: 0.38))
                            .rotationEffect(.degrees(-25))
                            .offset(x: 20, y: 10)

                        // Gradient overlay for text readability
                        LinearGradient(
                            colors: [Color.black.opacity(0.25), Color.black.opacity(0.10), Color.black.opacity(0.20)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .frame(height: 280)
                    .ignoresSafeArea(edges: .top)
                    .clipped()

                    // Header text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Travel ready")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Rewards and card benefits")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 60)
                    .padding(.leading, 20)
                }

                VStack(spacing: 18) {
                    // Card artwork overlapping header
                    SurfaceCard {
                        VStack(alignment: .center, spacing: 14) {
                            FreedomUnlimitedCardArtwork(height: 90)
                                .frame(width: 150, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            Text(creditAccount?.name ?? "Freedom Unlimited (...2095)")
                                .font(.system(size: usesCompactLayout ? 18 : 20, weight: .semibold))
                                .foregroundColor(BankPalette.chaseBlue)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    .offset(y: -72)
                    .padding(.bottom, -72)

                    // Ultimate Rewards section
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Ultimate Rewards")
                                .font(.system(size: 24, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(availablePoints)")
                                        .font(.system(size: 38, weight: .regular))
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.55)
                                    Text("Available points")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Divider()
                                    .frame(height: 70)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(pendingPoints)")
                                        .font(.system(size: 38, weight: .regular))
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.55)
                                    Text("Pending points")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 18)
                            }

                            Button("Redeem rewards") {
                                showRewardSheet = true
                            }
                            .buttonStyle(OutlinePillButtonStyle(tint: BankPalette.chaseBlue))
                        }
                    }

                    // Benefit shortcut icons (horizontal row of 4)
                    HStack(spacing: 0) {
                        ForEach(shortcuts) { shortcut in
                            BenefitShortcutButton(
                                shortcut: shortcut,
                                isSelected: selectedBenefitId == shortcut.id
                            ) {
                                selectedBenefitId = shortcut.id
                            }
                            .accessibilityIdentifier("reward_shortcut_\(shortcut.id)_button")
                        }
                    }

                    // Selected benefit detail card
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(selectedBenefit.cta)
                                .font(.system(size: 22, weight: .semibold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Text(selectedBenefit.summary)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Button("Continue") {
                                showRewardSheet = true
                            }
                            .buttonStyle(FilledPillButtonStyle(tint: BankPalette.chaseBlue))
                            .accessibilityIdentifier("reward_\(selectedBenefitId)_continue_button")
                        }
                    }

                    // Rewards activity
                    if store.redeemedRewardPoints > 0 {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Rewards activity")
                                    .font(.system(size: 20, weight: .bold))
                                Text("\(store.redeemedRewardPoints) points redeemed so far across cash back, travel and shopping benefits.")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Travel promo banner
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.35, green: 0.48, blue: 0.58),
                                            Color(red: 0.42, green: 0.55, blue: 0.65)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Airplane decoration
                            Image(systemName: "airplane")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.15))
                                .rotationEffect(.degrees(-20))
                                .offset(x: -60, y: -30)
                        }
                        .frame(height: 180)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Use MyBank Travel to compare options, redeem rewards and keep card benefits in one place.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            HStack {
                                Spacer()
                                Button("Open travel tools") {
                                    selectedBenefitId = "travel"
                                    showRewardSheet = true
                                }
                                .buttonStyle(OutlinePillButtonStyle(tint: BankPalette.chaseBlue))
                                .background(Color.white.clipShape(Capsule()))
                            }
                        }
                        .padding(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(BankPalette.pageBackground)
        .sheet(isPresented: $showRewardSheet) {
            RewardRedemptionSheet(
                benefit: selectedBenefit,
                availablePoints: availablePoints
            ) { points in
                store.redeemRewards(points: points, context: selectedBenefit.cta)
            }
        }
    }
}

// MARK: - More Tab

struct MyBankMoreView: View {
    @ObservedObject var store: BankStore
    @State private var showResetConfirmation = false
    @State private var selectedService: MoreOption?
    @State private var moreDetail: MoreDetail?
    @State private var showSignOutConfirmation = false

    private let serviceOptions: [MoreOption] = [
        MoreOption(title: "Lock or\nunlock card", icon: "lock"),
        MoreOption(title: "Replace\ncard", icon: "arrow.2.circlepath"),
        MoreOption(title: "Digital\nwallets", icon: "wallet.pass"),
        MoreOption(title: "Stored\ncards", icon: "menucard"),
        MoreOption(title: "Statements", icon: "doc.text"),
        MoreOption(title: "Alerts", icon: "exclamationmark.circle"),
        MoreOption(title: "Profile", icon: "person"),
        MoreOption(title: "Security", icon: "shield")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(BankPalette.chaseBlue)
                        .frame(height: 220)
                        .ignoresSafeArea(edges: .top)

                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text((String(store.userName.prefix(1)) + String(store.lastName.prefix(1))).uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text((store.userName + " " + store.lastName).uppercased())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Personal accounts")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                    .padding(20)
                }

                VStack(alignment: .leading, spacing: 20) {
                    MoreSection(title: "Card services", options: serviceOptions, columns: 4) { option in
                        selectedService = option
                    }

                    SurfaceCard(padding: 0) {
                        VStack(spacing: 0) {
                            MoreListRow(icon: "phone", title: "Contact us") { moreDetail = .contact }
                            Divider().padding(.leading, 56)
                            MoreListRow(icon: "map", title: "ATM & branch") { moreDetail = .atm }
                            Divider().padding(.leading, 56)
                            MoreListRow(icon: "gearshape", title: "Settings") { moreDetail = .settings }
                            Divider().padding(.leading, 56)
                            MoreListRow(icon: "lock.shield", title: "Security & privacy") { moreDetail = .security }
                            Divider().padding(.leading, 56)
                            MoreListRow(icon: "questionmark.circle", title: "Help & support") { moreDetail = .help }
                            Divider().padding(.leading, 56)
                            MoreListRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign out") { showSignOutConfirmation = true }
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Account services")
                                .font(.system(size: 24, weight: .bold))

                            MoreActionButton(
                                title: "Refresh transactions",
                                subtitle: "Check for the latest activity across all accounts."
                            ) {
                                store.importFromSharedLedger()
                            }

                            MoreActionButton(
                                title: "Process pending",
                                subtitle: "Update pending transactions to their current status."
                            ) {
                                store.postAllPending(reason: "manual")
                            }

                            MoreActionButton(
                                title: "Download activity",
                                subtitle: "Export your recent account activity for your records."
                            ) {
                                store.exportLedger()
                            }

                            MoreActionButton(
                                title: "Reset preferences",
                                subtitle: "Restore default settings and clear cached data."
                            ) {
                                showResetConfirmation = true
                            }
                        }
                    }

                    Text("MyBank Mobile\u{00AE} v6.458")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .background(BankPalette.pageBackground)
        .confirmationDialog("Reset demo data?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) {
                store.resetAllState()
            }

            Button("Cancel", role: .cancel) {}
        }
        .alert(
            selectedService?.alertTitle ?? "",
            isPresented: Binding(
                get: { selectedService != nil },
                set: { if !$0 { selectedService = nil } }
            ),
            presenting: selectedService,
            actions: { _ in Button("OK") {} },
            message: { Text($0.alertMessage) }
        )
        .sheet(item: $moreDetail) { detail in
            MoreDetailSheet(detail: detail)
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                store.resetAllState()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again to access your accounts.")
        }
    }
}

// MARK: - Supporting Views

private struct TrackBreakdownRow: View {
    let title: String
    let value: Double
    let currencyCode: String
    let positive: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(BankPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            Text(Formatters.signedCurrencyString(amount: value, currencyCode: currencyCode))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(positive ? BankPalette.positiveGreen : BankPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

private struct BenefitShortcut: Identifiable {
    let id: String
    let title: String
    let icon: String
    let summary: String
    let cta: String
}

private struct BenefitShortcutButton: View {
    let shortcut: BenefitShortcut
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? BankPalette.chaseBlue.opacity(0.12) : Color(red: 0.94, green: 0.94, blue: 0.96))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: shortcut.icon)
                            .font(.system(size: 22))
                            .foregroundColor(isSelected ? BankPalette.chaseBlue : Color.gray)
                    )

                Text(shortcut.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? BankPalette.chaseBlue : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct MoreOption: Identifiable {
    let id = UUID()
    let title: String
    let icon: String

    var alertTitle: String {
        title.replacingOccurrences(of: "\n", with: " ")
    }

    var alertMessage: String {
        switch icon {
        case "lock":
            return "Manage your card lock settings, travel notifications, and spending limits."
        case "arrow.2.circlepath":
            return "Request a replacement card if yours is lost, stolen, or damaged. Your new card will arrive in 3-5 business days."
        case "wallet.pass":
            return "Add your MyBank card to Apple Wallet for easy tap-to-pay at supported merchants."
        case "menucard":
            return "Review and manage your saved payment methods, virtual card numbers, and authorized users."
        case "doc.text":
            return "View and download your monthly account statements and year-end tax documents."
        case "exclamationmark.circle":
            return "Customize alerts for transactions, balance thresholds, payment reminders, and security notifications."
        case "person":
            return "Update your name, email, phone number, and mailing address on file."
        default:
            return "Manage your security preferences including two-factor authentication and login settings."
        }
    }
}

private struct RewardRedemptionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let benefit: BenefitShortcut
    let availablePoints: Int
    let onRedeem: (Int) -> Bool

    @State private var selectedPoints: Int?
    // Travel-specific
    @State private var selectedDestination = "Europe"
    // Cash back-specific
    @State private var selectedCashBackTarget = "Statement credit"
    // Gift cards-specific
    @State private var selectedBrand = "Amazon"
    // Shop-specific
    @State private var selectedShopOption = "Eligible merchants"

    private var redemptionOptions: [Int] {
        [2500, 5000, 10000, 20000].filter { $0 <= availablePoints }
    }

    private let travelDestinations = ["Europe", "Caribbean", "Asia", "Domestic", "Mexico & Central America"]
    private let cashBackTargets = ["Statement credit", "Deposit to checking", "Deposit to savings"]
    private let giftCardBrands = ["Amazon", "Target", "Starbucks", "Apple", "Best Buy", "Home Depot"]
    private let shopOptions = ["Eligible merchants", "Apple Pay checkout", "Shop Through Chase"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Benefit") {
                    Text(benefit.cta)
                        .font(.system(size: 18, weight: .semibold))
                    LabeledContent("Available points") {
                        Text("\(availablePoints)")
                    }
                }

                // Per-benefit distinct options
                switch benefit.id {
                case "travel":
                    Section("Where are you headed?") {
                        Picker("Destination", selection: $selectedDestination) {
                            ForEach(travelDestinations, id: \.self) { dest in
                                Text(dest).tag(dest)
                            }
                        }
                        .accessibilityIdentifier("reward_travel_destination_picker")
                    }

                case "cash_back":
                    Section("Deposit to") {
                        Picker("Destination", selection: $selectedCashBackTarget) {
                            ForEach(cashBackTargets, id: \.self) { target in
                                Text(target).tag(target)
                            }
                        }
                        .accessibilityIdentifier("reward_cash_back_target_picker")
                    }

                case "gift_cards":
                    Section("Choose a brand") {
                        Picker("Brand", selection: $selectedBrand) {
                            ForEach(giftCardBrands, id: \.self) { brand in
                                Text(brand).tag(brand)
                            }
                        }
                        .accessibilityIdentifier("reward_gift_card_brand_picker")
                    }

                case "shop":
                    Section("Shopping option") {
                        Picker("Option", selection: $selectedShopOption) {
                            ForEach(shopOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .accessibilityIdentifier("reward_shop_option_picker")
                    }

                default:
                    EmptyView()
                }

                Section("Choose an amount") {
                    if redemptionOptions.isEmpty {
                        Text("Earn more points with card activity before redeeming rewards.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Points", selection: $selectedPoints) {
                            ForEach(redemptionOptions, id: \.self) { option in
                                Text("\(option) points").tag(Optional(option))
                            }
                        }
                        .accessibilityIdentifier("reward_points_picker")
                    }
                }

                Section {
                    Button("Redeem now") {
                        guard let selectedPoints else { return }
                        if onRedeem(selectedPoints) {
                            dismiss()
                        }
                    }
                    .disabled(selectedPoints == nil)
                    .accessibilityIdentifier("reward_redeem_button")
                }
            }
            .navigationTitle(benefit.cta)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedPoints = redemptionOptions.first
            }
        }
        .accessibilityIdentifier("reward_\(benefit.id)_sheet")
    }
}

private struct MoreSection: View {
    let title: String
    let options: [MoreOption]
    let columns: Int
    let action: (MoreOption) -> Void

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 24, weight: .bold))

            LazyVGrid(columns: gridColumns, spacing: 18) {
                ForEach(options) { option in
                    Button {
                        action(option)
                    } label: {
                        VStack(spacing: 10) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: option.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(BankPalette.chaseBlue)
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

                            Text(option.title)
                                .font(.system(size: 13, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(BankPalette.ink)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

private struct MoreListRow: View {
    let icon: String
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
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
    }
}

private struct MoreActionButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BankPalette.ink)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - More Detail Enum & Sheet

private enum MoreDetail: String, Identifiable, CaseIterable {
    case contact = "Contact us"
    case atm = "ATM & branch"
    case settings = "Settings"
    case security = "Security & privacy"
    case help = "Help & support"

    var id: String { rawValue }
}

private struct MoreDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let detail: MoreDetail
    @State private var notificationsEnabled = true
    @State private var emailAlerts = true
    @State private var faceIdEnabled = true
    @State private var rememberDevice = true
    @State private var biometricLogin = true
    @State private var loginAlerts = true
    @State private var largeTransactionAlerts = true
    @State private var locationStatus: String?
    @State private var internationalAlerts = true

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(detail.rawValue)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch detail {
        case .contact:
            List {
                Section("Phone") {
                    Label("1-800-555-0198", systemImage: "phone")
                    Label("1-800-555-0197 (International)", systemImage: "phone")
                }
                Section("Hours") {
                    Text("Monday \u{2013} Friday: 8 AM \u{2013} 11 PM ET")
                    Text("Saturday \u{2013} Sunday: 9 AM \u{2013} 6 PM ET")
                }
                Section("Other") {
                    Label("Secure message center", systemImage: "envelope")
                    Label("Schedule a callback", systemImage: "clock")
                }
            }

        case .atm:
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 56))
                        .foregroundColor(BankPalette.chaseBlue)

                    Text("Find ATMs & Branches")
                        .font(.system(size: 24, weight: .bold))

                    Text("Over 15,000 ATMs and 4,700 branches nationwide.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(BankPalette.chaseBlue)
                                Text("Map view")
                                    .foregroundColor(.secondary)
                            }
                        )

                    Button("Use current location") {
                        locationStatus = "Showing nearest ATMs & branches near San Francisco, CA."
                    }
                    .buttonStyle(FilledPillButtonStyle(tint: BankPalette.chaseBlue))

                    if let status = locationStatus {
                        Text(status)
                            .font(.system(size: 14))
                            .foregroundColor(BankPalette.chaseBlue)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .background(BankPalette.pageBackground)

        case .settings:
            Form {
                Section("Notifications") {
                    Toggle("Push notifications", isOn: $notificationsEnabled)
                    Toggle("Email alerts", isOn: $emailAlerts)
                }
                Section("Authentication") {
                    Toggle("Face ID login", isOn: $faceIdEnabled)
                    Toggle("Remember device", isOn: $rememberDevice)
                }
                Section("Display") {
                    LabeledContent("App icon") { Text("Default") }
                    LabeledContent("Language") { Text("English") }
                }
                Section("About") {
                    LabeledContent("Version") { Text("6.458") }
                    LabeledContent("Build") { Text("2026.03.1") }
                }
            }

        case .security:
            Form {
                Section("Login security") {
                    Toggle("Biometric login", isOn: $biometricLogin)
                    LabeledContent("Password") { Text("\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}") }
                }
                Section("Account alerts") {
                    Toggle("Login alerts", isOn: $loginAlerts)
                    Toggle("Large transaction alerts", isOn: $largeTransactionAlerts)
                    Toggle("International transaction alerts", isOn: $internationalAlerts)
                }
                Section("Privacy") {
                    LabeledContent("Data sharing") { Text("Limited") }
                    LabeledContent("Ad personalization") { Text("Off") }
                }
            }

        case .help:
            List {
                Section("Frequently asked") {
                    Label("How do I reset my password?", systemImage: "questionmark.circle")
                    Label("How do I dispute a charge?", systemImage: "questionmark.circle")
                    Label("How do I set up direct deposit?", systemImage: "questionmark.circle")
                    Label("How do I order new checks?", systemImage: "questionmark.circle")
                    Label("How do I update my address?", systemImage: "questionmark.circle")
                }
                Section("Resources") {
                    Label("Security center", systemImage: "shield")
                    Label("Accessibility", systemImage: "accessibility")
                    Label("Legal disclosures", systemImage: "doc.text")
                }
            }
        }
    }
}

// MARK: - Advisor Sheet

private struct AdvisorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date().addingTimeInterval(86400 * 2)
    @State private var selectedTopic = "Financial planning"

    private let topics = ["Financial planning", "Mortgage & home lending", "Auto loans", "Business banking", "Investment services"]

    var body: some View {
        NavigationStack {
            Form {
                Section("What can we help with?") {
                    Picker("Topic", selection: $selectedTopic) {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic).tag(topic)
                        }
                    }
                }
                Section("Preferred date") {
                    DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                }
                Section("Location") {
                    LabeledContent("Nearest branch") {
                        Text("MyBank \u{2013} Market Street")
                    }
                    LabeledContent("Address") {
                        Text("560 Market St, San Francisco, CA")
                    }
                }
                Section {
                    Button("Request appointment") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("MyBank Advisor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private extension DateFormatter {
    static let monthAndYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}
