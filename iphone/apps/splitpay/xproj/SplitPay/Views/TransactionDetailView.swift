import SwiftUI

struct TransactionDetailView: View {
    @EnvironmentObject var store: SplitPayStore
    let transaction: Transaction

    var body: some View {
        let fromUser = store.user(for: transaction.fromUserID)
        let toUser = store.user(for: transaction.toUserID)
        let isIncoming = transaction.toUserID == store.you.id
        let amountText = AmountFormatter.format(transaction.amount, showSigned: store.settings.showSignedAmounts, isIncoming: isIncoming)

        VStack(spacing: 16) {
            Text("Transaction")
                .font(SplitPayTheme.titleFont(size: 20))
                .accessibilityIdentifier("transaction_detail_title")

            VStack(spacing: 8) {
                Text(amountText)
                    .font(SplitPayTheme.titleFont(size: 28))
                    .accessibilityIdentifier("transaction_detail_amount")
                Text(transaction.memo.isEmpty ? "(No memo)" : transaction.memo)
                    .font(SplitPayTheme.bodyFont(size: 14))
                    .foregroundColor(SplitPayTheme.textSecondary)
                    .accessibilityIdentifier("transaction_detail_memo")
            }

            VStack(alignment: .leading, spacing: 8) {
                UserInfoRow(title: "From", user: fromUser)
                UserInfoRow(title: "To", user: toUser)
                InfoRow(title: "Privacy", value: transaction.privacy.rawValue)
                InfoRow(title: "Funding", value: store.fundingSources.first(where: { $0.id == transaction.fundingSourceID })?.name ?? "Unknown")
                InfoRow(title: "Date", value: DateFormatter.shortDateTime.string(from: transaction.timestamp))
                InfoRow(title: "Transaction ID", value: transaction.id.uuidString)
            }
            .padding(16)
            .background(CardSurface())

            Spacer()
        }
        .padding(20)
        .background(SplitPayTheme.background.ignoresSafeArea())
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(SplitPayTheme.bodyFont(size: 12))
                .foregroundColor(SplitPayTheme.textSecondary)
            Spacer()
            Text(value)
                .font(SplitPayTheme.bodyFont(size: 12))
        }
        .accessibilityIdentifier("transaction_detail_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
}

struct UserInfoRow: View {
    @EnvironmentObject var store: SplitPayStore
    let title: String
    let user: User?

    private var rowID: String {
        "transaction_detail_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    var body: some View {
        if let user {
            // Make the WHOLE row a single NavigationLink so it is a real,
            // tappable element (a nested NavigationLink inside a row that also
            // carried an accessibilityIdentifier was getting flattened, leaving
            // no reachable control to open the profile sheet). The link's id is
            // the canonical transaction_detail_<from/to> the tools key off of;
            // tapping it pushes UserProfileView (profile_name_<id>, etc.).
            NavigationLink {
                UserProfileView(user: user)
                    .environmentObject(store)
            } label: {
                HStack {
                    Text(title)
                        .font(SplitPayTheme.bodyFont(size: 12))
                        .foregroundColor(SplitPayTheme.textSecondary)
                    Spacer()
                    Text(user.displayName)
                        .font(SplitPayTheme.bodyFont(size: 12))
                        .foregroundColor(SplitPayTheme.accent)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(rowID)
            .accessibilityElement(children: .combine)
        } else {
            HStack {
                Text(title)
                    .font(SplitPayTheme.bodyFont(size: 12))
                    .foregroundColor(SplitPayTheme.textSecondary)
                Spacer()
                Text("Unknown")
                    .font(SplitPayTheme.bodyFont(size: 12))
            }
            .accessibilityIdentifier(rowID)
        }
    }
}

struct UserProfileView: View {
    @EnvironmentObject var store: SplitPayStore
    let user: User

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(SplitPayTheme.accentLight)
                        .frame(width: 80, height: 80)
                        .overlay(Text(user.displayName.prefix(1)).font(SplitPayTheme.titleFont(size: 28)))
                        .accessibilityIdentifier("profile_avatar_\(user.id)")
                    Text(user.displayName)
                        .font(SplitPayTheme.titleFont(size: 20))
                        .accessibilityIdentifier("profile_name_\(user.id)")
                    Text("@\(user.username)")
                        .font(SplitPayTheme.bodyFont(size: 14))
                        .foregroundColor(SplitPayTheme.textSecondary)
                        .accessibilityIdentifier("profile_username_\(user.id)")
                    Button(store.isFriend(user.id) ? "Remove Friend" : "Add Friend") {
                        store.toggleFriend(user.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("profile_friend_toggle_\(user.id)")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent activity")
                        .font(SplitPayTheme.titleFont(size: 16))
                        .accessibilityIdentifier("profile_recent_header")

                    let recent = store.transactions(for: user.id)
                    if recent.isEmpty {
                        EmptyStateView(title: "No activity", subtitle: "No transactions yet.")
                            .accessibilityIdentifier("profile_recent_empty")
                    } else {
                        ForEach(recent) { transaction in
                            TransactionRowView(transaction: transaction)
                                .accessibilityIdentifier("profile_recent_\(transaction.id.uuidString)")
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(SplitPayTheme.background.ignoresSafeArea())
        .navigationTitle("Profile")
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView(transaction: SplitPayStore().transactions.first!)
            .environmentObject(SplitPayStore())
    }
}
