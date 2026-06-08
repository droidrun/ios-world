import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var store: SplitPayStore
    @State private var searchText = ""
    @State private var activeSheet: FeedSheet?
    @State private var selectedTransaction: Transaction?
    @State private var selectedProfileUser: User?
    @State private var activeFilter: FeedFilter = .all

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                topSearchRow
                filterPicker
                DoorDashPromoCard {
                    activeSheet = .doorDash
                }

                if filteredTransactions.isEmpty {
                    EmptyStateView(
                        title: "No matching activity",
                        subtitle: "Try a different person, business, or memo."
                    )
                } else {
                    ForEach(Array(filteredTransactions.enumerated()), id: \.element.id) { index, transaction in
                        Button {
                            selectedTransaction = transaction
                        } label: {
                            TransactionRowView(transaction: transaction) { user in
                                selectedProfileUser = user
                            }
                            // Make the WHOLE row hittable: without an explicit
                            // content shape the plain Button only registers taps
                            // on its drawn text/glyphs, leaving the gaps between
                            // them (and most of the row) dead — so a tap on the
                            // row no-ops and the detail sheet never opens.
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("splitpay_feed_row_\(transaction.id.uuidString)")

                        if index == 1 {
                            MerchantSpotlightCard {
                                activeSheet = .merchant
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 112)
        }
        .background(SplitPayTheme.background.ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            FeedInfoSheet(sheet: sheet, user: store.you)
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
        .sheet(item: $selectedProfileUser) { user in
            NavigationStack {
                UserProfileView(user: user)
                    .environmentObject(store)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                selectedProfileUser = nil
                            }
                        }
                    }
            }
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 0) {
            ForEach(FeedFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(SplitPayTheme.bodyFont(size: 15, weight: .semibold))
                        .foregroundStyle(activeFilter == filter ? SplitPayTheme.textPrimary : SplitPayTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(activeFilter == filter ? Color.white : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("feed_filter_\(filter.rawValue.lowercased())")
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.06))
        )
    }

    private var topSearchRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.iconSecondary)

                TextField("Find a person or business", text: $searchText)
                    .font(SplitPayTheme.titleFont(size: 18, weight: .regular))
                    .foregroundStyle(SplitPayTheme.textPrimary)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SplitPayTheme.cardSecondary)
            )

            Button {
                activeSheet = .qr
            } label: {
                ZStack {
                    Circle()
                        .fill(SplitPayTheme.cardSecondary)
                        .frame(width: 60, height: 60)
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var filteredTransactions: [Transaction] {
        // Apply feed filter first (All/Friends/Me), excluding system transactions from the public feed
        let filterBase = store.filteredTransactions(filter: activeFilter)
            .filter { $0.fromUserID != SeedData.systemID && $0.toUserID != SeedData.systemID }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return filterBase }

        let lowered = trimmed.lowercased()
        return filterBase.filter { transaction in
            let from = store.user(for: transaction.fromUserID)?.displayName.lowercased() ?? ""
            let to = store.user(for: transaction.toUserID)?.displayName.lowercased() ?? ""
            return from.contains(lowered) || to.contains(lowered) || transaction.memo.lowercased().contains(lowered)
        }
    }
}

struct TransactionRowView: View {
    @EnvironmentObject private var store: SplitPayStore
    let transaction: Transaction
    var onAvatarTap: ((User) -> Void)? = nil
    @State private var isLiked = false
    @State private var showCommentField = false
    @State private var commentText = ""
    @State private var comments: [String] = []

    var body: some View {
        let fromUser = store.user(for: transaction.fromUserID)
        let toUser = store.user(for: transaction.toUserID)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                if let fromUser {
                    if let onAvatarTap {
                        Button {
                            onAvatarTap(fromUser)
                        } label: {
                            SplitPayAvatarView(user: fromUser, size: 54)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("profile_avatar_\(fromUser.id)")
                    } else {
                        SplitPayAvatarView(user: fromUser, size: 54)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    header(fromUser: fromUser, toUser: toUser)

                    HStack(spacing: 6) {
                        Text(RelativeTimeLabel.string(from: transaction.timestamp))
                            .font(SplitPayTheme.bodyFont(size: 14))
                            .foregroundStyle(SplitPayTheme.textSecondary)

                        Image(systemName: privacySymbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SplitPayTheme.iconSecondary)
                    }

                    Text(transaction.memo)
                        .font(SplitPayTheme.bodyFont(size: 16, weight: .regular))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                        .padding(.top, 4)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 22) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? Color.red : SplitPayTheme.iconSecondary)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCommentField.toggle()
                    }
                } label: {
                    Image(systemName: "bubble.left")
                        .foregroundStyle(SplitPayTheme.iconSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Menu {
                    Button {
                        // Share action
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        // Report action
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(SplitPayTheme.iconSecondary)
                }
                .accessibilityIdentifier("feed_row_more_button")
            }
            .font(.system(size: 18, weight: .regular))
            .padding(.leading, 66)

            if !comments.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(comments, id: \.self) { comment in
                        HStack(spacing: 8) {
                            Text(store.you.displayName)
                                .font(SplitPayTheme.bodyFont(size: 14, weight: .semibold))
                                .foregroundStyle(SplitPayTheme.textPrimary)
                            Text(comment)
                                .font(SplitPayTheme.bodyFont(size: 14))
                                .foregroundStyle(SplitPayTheme.textSecondary)
                        }
                    }
                }
                .padding(.leading, 66)
            }

            if showCommentField {
                HStack(spacing: 10) {
                    TextField("Add a comment...", text: $commentText)
                        .font(SplitPayTheme.bodyFont(size: 15))
                        .textFieldStyle(.roundedBorder)

                    Button {
                        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        comments.append(trimmed)
                        commentText = ""
                        showCommentField = false
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(SplitPayTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 66)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func header(fromUser: User?, toUser: User?) -> some View {
        (
            Text(fromUser?.displayName ?? "Unknown")
                .font(SplitPayTheme.titleFont(size: 18, weight: .regular))
                .foregroundStyle(SplitPayTheme.textPrimary)
            +
            Text(" paid ")
                .font(SplitPayTheme.titleFont(size: 18, weight: .regular))
                .foregroundStyle(SplitPayTheme.textPrimary)
            +
            Text(toUser?.displayName ?? "Unknown")
                .font(SplitPayTheme.titleFont(size: 18, weight: .regular))
                .foregroundStyle(SplitPayTheme.textPrimary)
        )
        .lineLimit(2)
        .multilineTextAlignment(.leading)
    }

    private var privacySymbol: String {
        switch transaction.privacy {
        case .public, .friends:
            return "person.2.fill"
        case .private:
            return "lock.fill"
        }
    }
}

struct UserRowView: View {
    @EnvironmentObject private var store: SplitPayStore
    let user: User

    var body: some View {
        HStack(spacing: 16) {
            SplitPayAvatarView(user: user, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(SplitPayTheme.titleFont(size: 18, weight: .regular))
                    .foregroundStyle(SplitPayTheme.textPrimary)
                Text("@\(user.username)")
                    .font(SplitPayTheme.bodyFont(size: 15))
                    .foregroundStyle(SplitPayTheme.textSecondary)
            }

            Spacer()

            if store.isFriend(user.id) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.accent)
            }
        }
    }
}

private struct DoorDashPromoCard: View {
    let onLinkAccount: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CardSurface(radius: 24)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Next time you order QuickBite, pay with SplitPay for an easy checkout")
                        .font(SplitPayTheme.titleFont(size: 18, weight: .regular))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)

                    Button(action: onLinkAccount) {
                        Text("Link my account")
                            .font(SplitPayTheme.titleFont(size: 15))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(SplitPayTheme.accent)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)

                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 132, height: 192)
                        .rotationEffect(.degrees(-6))

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                        }

                        Text("Add Payment Method")
                            .font(SplitPayTheme.titleFont(size: 15, weight: .regular))
                            .lineLimit(2)

                        paymentMethodRow(icon: "creditcard", title: "Credit or Debit Card")
                        paymentMethodRow(icon: "v.circle.fill", title: "SplitPay")
                        paymentMethodRow(icon: "p.circle.fill", title: "PaySphere")
                    }
                    .padding(14)
                    .frame(width: 132, height: 192, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(SplitPayTheme.border, lineWidth: 1)
                    )

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 66, height: 66)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(SplitPayTheme.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                        .overlay(
                            Image(systemName: "d.square.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(Color(red: 0.96, green: 0.23, blue: 0.12))
                        )
                        .offset(x: 10, y: -12)
                }
            }
            .padding(16)
        }
        .frame(height: 278)
    }

    private func paymentMethodRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(SplitPayTheme.iconSecondary)
            Text(title)
                .font(SplitPayTheme.bodyFont(size: 11))
            Spacer()
        }
        .foregroundStyle(SplitPayTheme.textPrimary)
    }
}

private struct MerchantSpotlightCard: View {
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.62, green: 0.80, blue: 0.95),
                                    Color(red: 0.97, green: 0.82, blue: 0.50),
                                    Color(red: 0.98, green: 0.73, blue: 0.79)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    HStack(alignment: .bottom, spacing: 18) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                            .frame(width: 96, height: 58)
                            .overlay(
                                Text("OPEN")
                                    .font(SplitPayTheme.titleFont(size: 20, weight: .bold))
                                    .rotationEffect(.degrees(-18))
                                    .foregroundStyle(Color.white)
                            )

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.51, green: 0.72, blue: 0.85))
                            .frame(width: 108, height: 84)
                            .overlay(
                                VStack(spacing: 8) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.75))
                                        .frame(width: 62, height: 10)
                                    Rectangle()
                                        .fill(Color.white.opacity(0.55))
                                        .frame(width: 48, height: 34)
                                }
                            )

                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 88, height: 118)
                            .overlay(
                                Image(systemName: "scribble.variable")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundStyle(Color.white.opacity(0.7))
                            )
                    }
                }
                .frame(height: 146)

                HStack(alignment: .top, spacing: 12) {
                    SplitPayAvatarView(
                        user: User(id: "merchant", username: "sharp_sports", displayName: "Sharp Sports Consulting LLC", avatarSeed: "business_sharp", isYou: false),
                        size: 52
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sharp Sports\nConsulting LLC")
                            .font(SplitPayTheme.titleFont(size: 18, weight: .regular))
                            .foregroundStyle(SplitPayTheme.textPrimary)
                            .lineLimit(2)
                        Text("Sponsored")
                            .font(SplitPayTheme.bodyFont(size: 14))
                            .foregroundStyle(SplitPayTheme.textSecondary)
                        Text("Sports, events, and local leaders")
                            .font(SplitPayTheme.bodyFont(size: 14))
                            .foregroundStyle(SplitPayTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SplitPayTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private enum FeedSheet: String, Identifiable {
    case qr
    case doorDash
    case merchant

    var id: String { rawValue }
}

private struct FeedInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sheet: FeedSheet
    let user: User

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch sheet {
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
                                        Text("@\(user.username)")
                                            .font(SplitPayTheme.titleFont(size: 24))
                                            .foregroundStyle(SplitPayTheme.textPrimary)
                                    }
                                )
                            Text("Your SplitPay code")
                                .font(SplitPayTheme.titleFont(size: 26))
                            Text("Friends can scan this to pay you, request money, or add you faster.")
                                .font(SplitPayTheme.bodyFont(size: 18))
                                .foregroundStyle(SplitPayTheme.textSecondary)
                        }
                    case .doorDash:
                        infoSection(
                            title: "QuickBite linked",
                            body: "SplitPay is now ready to use for a faster QuickBite checkout."
                        )
                    case .merchant:
                        infoSection(
                            title: "Sharp Sports Consulting LLC",
                            body: "Sharp Sports Consulting LLC is a verified business on SplitPay. Pay them directly for a seamless experience."
                        )
                    }
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
        case .qr:
            return "SplitPay Code"
        case .doorDash:
            return "QuickBite"
        case .merchant:
            return "Merchant"
        }
    }

    private func infoSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 26))
                .foregroundStyle(SplitPayTheme.textPrimary)
            Text(body)
                .font(SplitPayTheme.bodyFont(size: 18))
                .foregroundStyle(SplitPayTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(CardSurface(radius: 24))
    }
}

private enum RelativeTimeLabel {
    static func string(from date: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        if seconds < 3600 {
            return "\(max(1, seconds / 60))m"
        }
        if seconds < 86_400 {
            return "\(seconds / 3600)h"
        }
        return "\(seconds / 86_400)d"
    }
}

#Preview {
    FeedView()
        .environmentObject(SplitPayStore())
}
