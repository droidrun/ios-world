import SwiftUI

struct RequestsView: View {
    @EnvironmentObject private var store: SplitPayStore
    @State private var selectedSection: ProfileSection = .wallet
    @State private var balanceAction: BalanceAction?
    @State private var profileSheet: ProfileSheet?
    @State private var showAccountNumbers = false
    @State private var selectedTransaction: Transaction?
    @State private var requestErrorMessage: String?
    @State private var pendingRequestPayment: Request?
    @State private var bannerText: String?

    var body: some View {
        ZStack {
            SplitPayTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    profileHeader

                    VStack(spacing: 16) {
                        quickActions
                        sectionPicker
                        stashCard

                        if selectedSection == .wallet {
                            balanceCard
                        } else {
                            transactionsCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 112)
                }
            }

            if let bannerText {
                toast(text: bannerText)
            }
        }
        .sheet(item: $balanceAction) { action in
            BalanceSheet(action: action)
                .environmentObject(store)
        }
        .sheet(item: $profileSheet) { sheet in
            ProfileActionSheet(sheet: sheet)
                .environmentObject(store)
        }
        .sheet(item: $selectedTransaction) { transaction in
            NavigationStack {
                TransactionDetailView(transaction: transaction)
                    .environmentObject(store)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                selectedTransaction = nil
                            }
                        }
                    }
            }
        }
        .alert(
            "Confirm payment",
            isPresented: Binding(
                get: { pendingRequestPayment != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingRequestPayment = nil
                    }
                }
            ),
            presenting: pendingRequestPayment
        ) { request in
            Button("Cancel", role: .cancel) {
                pendingRequestPayment = nil
            }
            Button("Pay") {
                payPendingRequest(request)
                pendingRequestPayment = nil
            }
        } message: { request in
            Text(requestConfirmationMessage(for: request))
        }
    }

    private var profileHeader: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(SplitPayTheme.accent)
                    .frame(height: 194)

                Ellipse()
                    .fill(SplitPayTheme.accent)
                    .frame(height: 96)
                    .offset(y: -48)
            }
            .overlay(alignment: .bottom) {
                Ellipse()
                    .fill(SplitPayTheme.background)
                    .frame(height: 104)
                    .offset(y: 54)
            }

            VStack(spacing: 26) {
                HStack(alignment: .center) {
                    Button {
                        profileSheet = .account
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Text(store.you.displayName)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .layoutPriority(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.white)
                            }

                            Text("@\(store.you.username)")
                                .font(SplitPayTheme.bodyFont(size: 15, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.92))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack(spacing: 10) {
                        profileCircleButton(systemImage: "bell.fill") {
                            profileSheet = .notifications
                        }
                        profileCircleButton(systemImage: "gearshape.fill") {
                            profileSheet = .account
                        }
                    }
                }
                .padding(.top, 58)

                ZStack(alignment: .bottomTrailing) {
                    SplitPayAvatarView(user: store.you, size: 108)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                        )

                    Button {
                        profileSheet = .qr
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundStyle(SplitPayTheme.textPrimary)
                            )
                            .offset(x: 6, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 258)
    }

    private func profileCircleButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.accent)
                )
        }
        .buttonStyle(.plain)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickActionCard(
                title: "Create group",
                action: { profileSheet = .group },
                content: AnyView(
                    Circle()
                        .fill(SplitPayTheme.cardSecondary)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .regular))
                                .foregroundStyle(SplitPayTheme.accent)
                        )
                )
            )

            quickActionCard(
                title: "Friends",
                action: { profileSheet = .friends },
                content: AnyView(friendAvatars)
            )

            quickActionCard(
                title: "Add a teen",
                action: { profileSheet = .teen },
                content: AnyView(
                    Circle()
                        .fill(SplitPayTheme.cardSecondary)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .regular))
                                .foregroundStyle(SplitPayTheme.accent)
                        )
                )
            )
        }
    }

    private func quickActionCard(title: String, action: @escaping () -> Void, content: AnyView) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                content
                Text(title)
                    .font(SplitPayTheme.titleFont(size: 16))
                    .foregroundStyle(SplitPayTheme.accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(CardSurface(radius: 20))
        }
        .buttonStyle(.plain)
    }

    private var friendAvatars: some View {
        let friends = store.friendIDs.compactMap(store.user(for:)).prefix(3)

        return ZStack(alignment: .trailing) {
            HStack(spacing: -10) {
                ForEach(Array(friends.enumerated()), id: \.offset) { _, user in
                    SplitPayAvatarView(user: user, size: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }

            Circle()
                .fill(SplitPayTheme.cardSecondary)
                .frame(width: 44, height: 44)
                .overlay(
                    Text("+134")
                        .font(SplitPayTheme.titleFont(size: 14, weight: .regular))
                        .foregroundStyle(SplitPayTheme.textSecondary)
                )
                .overlay(
                    Circle()
                        .stroke(SplitPayTheme.border, lineWidth: 1)
                )
                .offset(x: 14)
        }
        .frame(height: 52)
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            sectionButton(title: "Wallet", section: .wallet)
            sectionButton(title: "Transactions", section: .transactions)
        }
        .padding(8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.06))
        )
    }

    private func sectionButton(title: String, section: ProfileSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        } label: {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 20))
                .foregroundStyle(selectedSection == section ? SplitPayTheme.textPrimary : SplitPayTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    Capsule()
                        .fill(selectedSection == section ? Color.white : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var stashCard: some View {
        Button {
            profileSheet = .stash
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-18))
                        .offset(x: -10, y: 10)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.98, green: 0.16, blue: 0.09))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "bag.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.white)
                        )
                        .rotationEffect(.degrees(10))
                        .offset(x: 14, y: 14)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.39, blue: 0.97))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.yellow)
                        )
                        .offset(x: 8, y: -10)
                }
                .frame(width: 84, height: 64)

                Text("Earn up to 5% back at your favorite brands with SplitPay Stash")
                    .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.72, green: 0.34, blue: 0.22),
                                Color(red: 0.37, green: 0.25, blue: 0.84),
                                Color(red: 0.09, green: 0.47, blue: 0.67)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text("Balance")
                    .font(SplitPayTheme.titleFont(size: 22))
                    .foregroundStyle(SplitPayTheme.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAccountNumbers.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(showAccountNumbers ? "031300012 • 9001047832" : "Account & Routing")
                            .font(SplitPayTheme.bodyFont(size: 16, weight: .medium))
                            .foregroundStyle(SplitPayTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Image(systemName: showAccountNumbers ? "eye.slash" : "eye")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SplitPayTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("$")
                    .font(SplitPayTheme.titleFont(size: 26, weight: .regular))
                    .foregroundStyle(SplitPayTheme.textPrimary)
                Text(String(format: "%.2f", store.balance))
                    .font(.system(size: 58, weight: .regular))
                    .foregroundStyle(SplitPayTheme.textPrimary)
            }

            if showAccountNumbers {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Routing 031300012")
                    Text("Account 9001047832")
                }
                .font(SplitPayTheme.bodyFont(size: 16))
                .foregroundStyle(SplitPayTheme.textSecondary)
            }

            HStack(spacing: 16) {
                SplitPaySecondaryButton(title: "Transfer") {
                    balanceAction = .transfer
                }

                SplitPayPrimaryButton(title: "Add money") {
                    balanceAction = .addMoney
                }
            }

            Divider()

            Button {
                profileSheet = .applePay
            } label: {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(SplitPayTheme.textPrimary, lineWidth: 1.5)
                        .frame(width: 92, height: 58)
                        .overlay(
                            HStack(spacing: 4) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 22, weight: .medium))
                                Text("Pay")
                                    .font(SplitPayTheme.titleFont(size: 21, weight: .regular))
                            }
                            .foregroundStyle(SplitPayTheme.textPrimary)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pay with SplitPay in a tap")
                            .font(SplitPayTheme.titleFont(size: 18))
                            .foregroundStyle(SplitPayTheme.textPrimary)
                            .lineLimit(2)
                        Text("Add your debit card to your wallet")
                            .font(SplitPayTheme.bodyFont(size: 15, weight: .regular))
                            .foregroundStyle(SplitPayTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.border)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(CardSurface(radius: 24))
    }

    private var transactionsCard: some View {
        VStack(spacing: 16) {
            if !incomingPendingRequests.isEmpty || !outgoingPendingRequests.isEmpty {
                pendingRequestsCard
            }

            recentTransactionsCard
        }
    }

    private var pendingRequestsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Pending requests")
                    .font(SplitPayTheme.titleFont(size: 20))
                    .foregroundStyle(SplitPayTheme.textPrimary)

                Spacer()

                Text("\(incomingPendingRequests.count + outgoingPendingRequests.count)")
                    .font(SplitPayTheme.bodyFont(size: 15, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(SplitPayTheme.cardSecondary))
            }

            if let requestErrorMessage {
                Text(requestErrorMessage)
                    .font(SplitPayTheme.bodyFont(size: 14))
                    .foregroundStyle(.red)
            }

            if !incomingPendingRequests.isEmpty {
                requestGroup(title: "You owe", requests: incomingPendingRequests, incoming: true)
            }

            if !outgoingPendingRequests.isEmpty {
                requestGroup(title: "Awaiting payment", requests: outgoingPendingRequests, incoming: false)
            }
        }
        .padding(18)
        .background(CardSurface(radius: 24))
    }

    private func requestGroup(title: String, requests: [Request], incoming: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(SplitPayTheme.bodyFont(size: 16, weight: .semibold))
                .foregroundStyle(SplitPayTheme.textSecondary)

            ForEach(Array(requests.enumerated()), id: \.element.id) { index, request in
                pendingRequestRow(request, incoming: incoming)

                if index != requests.count - 1 {
                    Divider()
                }
            }
        }
    }

    private func pendingRequestRow(_ request: Request, incoming: Bool) -> some View {
        let user = store.user(for: incoming ? request.fromUserID : request.toUserID) ?? store.you

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SplitPayAvatarView(user: user, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(incoming ? "\(user.displayName) requested" : "You requested \(user.displayName)")
                        .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                        .lineLimit(2)
                    Text("\(relativeTimeText(from: request.timestamp)) · \(request.memo)")
                        .font(SplitPayTheme.bodyFont(size: 14))
                        .foregroundStyle(SplitPayTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(String(format: "$%.2f", request.amount))
                    .font(SplitPayTheme.titleFont(size: 16, weight: .regular))
                    .foregroundStyle(SplitPayTheme.textPrimary)
            }

            HStack(spacing: 10) {
                if incoming {
                    requestActionButton(title: "Decline", filled: false) {
                        declineRequest(request)
                    }
                    requestActionButton(title: "Pay", filled: true) {
                        requestErrorMessage = nil
                        if store.settings.requireConfirmation {
                            pendingRequestPayment = request
                        } else {
                            payPendingRequest(request)
                        }
                    }
                } else {
                    requestActionButton(title: "Cancel", filled: false) {
                        cancelRequest(request)
                    }
                }
            }
            .padding(.leading, 56)
        }
    }

    private func requestActionButton(title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SplitPayTheme.bodyFont(size: 13, weight: .semibold))
                .foregroundStyle(filled ? Color.white : SplitPayTheme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(filled ? SplitPayTheme.accent : Color.white)
                        .overlay(
                            Capsule()
                                .stroke(SplitPayTheme.accent, lineWidth: filled ? 0 : 1.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var recentTransactionsCard: some View {
        let recentTransactions = Array(myTransactions.prefix(20))

        return VStack(alignment: .leading, spacing: 14) {
            Text("Recent transactions")
                .font(SplitPayTheme.titleFont(size: 20))
                .foregroundStyle(SplitPayTheme.textPrimary)

            if recentTransactions.isEmpty {
                EmptyStateView(
                    title: "No transactions yet",
                    subtitle: "Payments, requests, and balance activity will show up here."
                )
            } else {
                ForEach(recentTransactions) { transaction in
                    Button {
                        selectedTransaction = transaction
                    } label: {
                        HStack(spacing: 12) {
                            SplitPayAvatarView(user: otherUser(for: transaction), size: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(transactionTitle(for: transaction))
                                    .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                                    .foregroundStyle(SplitPayTheme.textPrimary)
                                    .lineLimit(2)
                                Text(transaction.memo)
                                    .font(SplitPayTheme.bodyFont(size: 14))
                                    .foregroundStyle(SplitPayTheme.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(transactionAmount(for: transaction))
                                    .font(SplitPayTheme.titleFont(size: 16, weight: .regular))
                                    .foregroundStyle(transaction.toUserID == store.you.id ? SplitPayTheme.success : SplitPayTheme.textPrimary)
                                    .multilineTextAlignment(.trailing)
                                Text(relativeTimeText(from: transaction.timestamp))
                                    .font(SplitPayTheme.bodyFont(size: 13))
                                    .foregroundStyle(SplitPayTheme.textSecondary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SplitPayTheme.iconSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if recentTransactions.last?.id != transaction.id {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .background(CardSurface(radius: 24))
    }

    private var myTransactions: [Transaction] {
        store.transactions.filter { $0.fromUserID == store.you.id || $0.toUserID == store.you.id }
    }

    private var incomingPendingRequests: [Request] {
        store.requests
            .filter { $0.toUserID == store.you.id && $0.status == .pending }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var outgoingPendingRequests: [Request] {
        store.requests
            .filter { $0.fromUserID == store.you.id && $0.status == .pending }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private func otherUser(for transaction: Transaction) -> User {
        let otherID = transaction.fromUserID == store.you.id ? transaction.toUserID : transaction.fromUserID
        return store.user(for: otherID) ?? store.you
    }

    private func transactionTitle(for transaction: Transaction) -> String {
        let other = otherUser(for: transaction)
        return transaction.toUserID == store.you.id ? "\(other.displayName) paid you" : "You paid \(other.displayName)"
    }

    private func transactionAmount(for transaction: Transaction) -> String {
        AmountFormatter.format(
            transaction.amount,
            showSigned: store.settings.showSignedAmounts,
            isIncoming: transaction.toUserID == store.you.id
        )
    }

    private func relativeTimeText(from date: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        if seconds < 3600 {
            return "\(max(1, seconds / 60))m"
        }
        if seconds < 86_400 {
            return "\(seconds / 3600)h"
        }
        return "\(seconds / 86_400)d"
    }

    private func payPendingRequest(_ request: Request) {
        requestErrorMessage = nil

        let fundingSource = store.preferredPaymentSource(for: request.amount)
        let transaction = store.payRequest(request, fundingSourceID: fundingSource.id)
        guard transaction != nil else {
            requestErrorMessage = "Payment couldn't be completed right now."
            return
        }

        let user = store.user(for: request.fromUserID)?.displayName ?? "Unknown"
        showBanner("Paid \(user)")
    }

    private func declineRequest(_ request: Request) {
        requestErrorMessage = nil
        store.declineRequest(request.id)
        let user = store.user(for: request.fromUserID)?.displayName ?? "Unknown"
        showBanner("Declined \(user)'s request")
    }

    private func cancelRequest(_ request: Request) {
        requestErrorMessage = nil
        store.cancelRequest(request.id)
        let user = store.user(for: request.toUserID)?.displayName ?? "Unknown"
        showBanner("Canceled request to \(user)")
    }

    private func requestConfirmationMessage(for request: Request) -> String {
        let user = store.user(for: request.fromUserID)?.displayName ?? "Unknown"
        let fundingSource = store.preferredPaymentSource(for: request.amount)
        return String(
            format: "Pay %@ $%.2f using %@?",
            user,
            request.amount,
            fundingSource.name
        )
    }

    private func showBanner(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            bannerText = text
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                if bannerText == text {
                    bannerText = nil
                }
            }
        }
    }

    private func toast(text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(SplitPayTheme.titleFont(size: 15))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.82))
                )
                .padding(.bottom, 96)
        }
    }
}

private enum ProfileSection {
    case wallet
    case transactions
}

private enum ProfileSheet: String, Identifiable {
    case notifications
    case account
    case qr
    case group
    case friends
    case teen
    case stash
    case applePay

    var id: String { rawValue }
}

private enum BalanceAction: String, Identifiable {
    case transfer
    case addMoney

    var id: String { rawValue }

    var title: String {
        switch self {
        case .transfer:
            return "Transfer to bank"
        case .addMoney:
            return "Add money"
        }
    }

    var buttonTitle: String {
        switch self {
        case .transfer:
            return "Transfer"
        case .addMoney:
            return "Add money"
        }
    }
}

private struct BalanceSheet: View {
    @EnvironmentObject private var store: SplitPayStore
    @Environment(\.dismiss) private var dismiss

    let action: BalanceAction
    @State private var amountText = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.textPrimary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(SplitPayTheme.bodyFont(size: 14))
                        .foregroundStyle(.red)
                }

                Text(action == .transfer ? "Transfer money from your SplitPay balance to your bank." : "Move money into your SplitPay balance instantly.")
                    .font(SplitPayTheme.bodyFont(size: 17))
                    .foregroundStyle(SplitPayTheme.textSecondary)

                SplitPayPrimaryButton(title: action.buttonTitle) {
                    submit()
                }

                Spacer()
            }
            .padding(24)
            .background(SplitPayTheme.background.ignoresSafeArea())
            .navigationTitle(action.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submit() {
        let amount = Double(amountText) ?? 0
        guard amount > 0 else {
            errorMessage = "Enter an amount greater than $0."
            return
        }

        let success: Transaction?
        switch action {
        case .transfer:
            success = store.cashOut(amount: amount)
        case .addMoney:
            success = store.addFunds(amount: amount)
        }

        guard success != nil else {
            errorMessage = "That amount isn't available right now."
            return
        }

        dismiss()
    }
}

private struct ProfileActionSheet: View {
    @EnvironmentObject private var store: SplitPayStore
    @Environment(\.dismiss) private var dismiss

    let sheet: ProfileSheet

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    content
                }
                .padding(24)
            }
            .background(SplitPayTheme.background.ignoresSafeArea())
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var title: String {
        switch sheet {
        case .notifications:
            return "Notifications"
        case .account:
            return "Account"
        case .qr:
            return "SplitPay Code"
        case .group:
            return "Create Group"
        case .friends:
            return "Friends"
        case .teen:
            return "Add a Teen"
        case .stash:
            return "SplitPay Stash"
        case .applePay:
            return "Apple Pay"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch sheet {
        case .notifications:
            VStack(spacing: 14) {
                notificationRow(title: "Maya Patel paid you $18", subtitle: "coffee before standup")
                notificationRow(title: "Maya Patel requested $42", subtitle: "dinner split")
                notificationRow(title: "Leo Chen requested $17", subtitle: "parking")
                notificationRow(title: "Kai Santos requested $33", subtitle: "brunch")
            }
        case .account:
            VStack(alignment: .leading, spacing: 18) {
                Text("Manage your account preferences.")
                    .font(SplitPayTheme.bodyFont(size: 18))
                    .foregroundStyle(SplitPayTheme.textSecondary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Default privacy")
                        .font(SplitPayTheme.bodyFont(size: 16, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                    Picker("Default privacy", selection: $store.settings.defaultPrivacy) {
                        ForEach(TransactionPrivacy.allCases, id: \.self) { privacy in
                            Text(privacy.rawValue).tag(privacy)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Show signed amounts", isOn: $store.settings.showSignedAmounts)
                Toggle("Require payment confirmation", isOn: $store.settings.requireConfirmation)

                Divider()

                Button(role: .destructive) {
                    store.resetState()
                    dismiss()
                } label: {
                    Text("Reset account")
                        .font(SplitPayTheme.titleFont(size: 18))
                }
            }
            .toggleStyle(.switch)
        case .qr:
            VStack(spacing: 18) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(SplitPayTheme.cardSecondary)
                    .frame(height: 260)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 140, weight: .medium))
                                .foregroundStyle(SplitPayTheme.textPrimary)
                            Text("@\(store.you.username)")
                                .font(SplitPayTheme.titleFont(size: 24))
                                .foregroundStyle(SplitPayTheme.textPrimary)
                        }
                    )
                Text("Friends can scan this code to pay or request you.")
                    .font(SplitPayTheme.bodyFont(size: 18))
                    .foregroundStyle(SplitPayTheme.textSecondary)
            }
        case .group:
            infoCard(
                title: "Create a shared group",
                message: "Group flows are coming soon. Stay tuned for shared expenses with multiple friends."
            )
        case .friends:
            FriendsListView()
        case .teen:
            infoCard(
                title: "Add a teen account",
                message: "Teen accounts let a parent or guardian add their teen to SplitPay. This feature is coming soon."
            )
        case .stash:
            infoCard(
                title: "SplitPay Stash",
                message: "Stash offers up to 5% back at eligible merchants. Check back for new offers from your favorite brands."
            )
        case .applePay:
            infoCard(
                title: "Apple Pay setup",
                message: "Your SplitPay debit card is ready to add to Apple Wallet. Tap to pay anywhere contactless is accepted."
            )
        }
    }

    private func notificationRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 20, weight: .regular))
                .foregroundStyle(SplitPayTheme.textPrimary)
            Text(subtitle)
                .font(SplitPayTheme.bodyFont(size: 16))
                .foregroundStyle(SplitPayTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(CardSurface(radius: 22))
    }

    private func infoCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 24))
                .foregroundStyle(SplitPayTheme.textPrimary)
            Text(message)
                .font(SplitPayTheme.bodyFont(size: 18))
                .foregroundStyle(SplitPayTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(CardSurface(radius: 24))
    }
}

private struct FriendsListView: View {
    @EnvironmentObject private var store: SplitPayStore
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.iconSecondary)
                TextField("Search people", text: $searchText)
                    .font(SplitPayTheme.bodyFont(size: 16))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SplitPayTheme.cardSecondary)
            )

            let friends = store.friendIDs.compactMap(store.user(for:)).sorted { $0.displayName < $1.displayName }
            let businessIDs: Set<String> = ["user_doordash", "user_sharp"]
            let nonFriends = store.users.filter { !$0.isYou && $0.id != SeedData.systemID && !businessIDs.contains($0.id) && !store.isFriend($0.id) }.sorted { $0.displayName < $1.displayName }

            let filteredFriends = filterUsers(friends)
            let filteredNonFriends = filterUsers(nonFriends)

            if !filteredFriends.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your friends (\(friends.count))")
                        .font(SplitPayTheme.bodyFont(size: 16, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textSecondary)

                    ForEach(filteredFriends) { user in
                        friendRow(user: user, isFriend: true)
                    }
                }
            }

            if filteredFriends.isEmpty && filteredNonFriends.isEmpty {
                EmptyStateView(title: "No matches", subtitle: "Try a different name or username.")
            }

            if !filteredNonFriends.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested")
                        .font(SplitPayTheme.bodyFont(size: 16, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textSecondary)

                    ForEach(filteredNonFriends.prefix(10)) { user in
                        friendRow(user: user, isFriend: false)
                    }
                }
            }
        }
    }

    private func filterUsers(_ users: [User]) -> [User] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return users }
        let lower = trimmed.lowercased()
        return users.filter {
            $0.displayName.lowercased().contains(lower) ||
            $0.username.lowercased().contains(lower)
        }
    }

    private func friendRow(user: User, isFriend: Bool) -> some View {
        HStack(spacing: 14) {
            SplitPayAvatarView(user: user, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(user.displayName)
                    .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                    .foregroundStyle(SplitPayTheme.textPrimary)
                Text("@\(user.username)")
                    .font(SplitPayTheme.bodyFont(size: 14))
                    .foregroundStyle(SplitPayTheme.textSecondary)
            }

            Spacer()

            Button {
                store.toggleFriend(user.id)
            } label: {
                Text(isFriend ? "Remove" : "Add")
                    .font(SplitPayTheme.bodyFont(size: 14, weight: .semibold))
                    .foregroundStyle(isFriend ? .red : SplitPayTheme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(isFriend ? Color.red : SplitPayTheme.accent, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    RequestsView()
        .environmentObject(SplitPayStore())
}
