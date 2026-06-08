import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let accountName: String

    private var categoryIcon: String {
        switch transaction.category.lowercased() {
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
        case "zelle": return "bolt.horizontal"
        case "deposit", "income": return "arrow.down.circle"
        case "transfer": return "arrow.left.arrow.right"
        case "payment": return "creditcard"
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

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(iconTint.opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconTint)
                )
                .accessibilityIdentifier("transaction_status_dot_\(transaction.id.uuidString)")

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.vendor)
                    .font(.headline)
                    .accessibilityIdentifier("transaction_vendor_\(transaction.id.uuidString)")

                Text("\(transaction.category) • \(accountName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("transaction_category_\(transaction.id.uuidString)")

                if transaction.status == .pending {
                    Text("Pending")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.orange)
                        .accessibilityIdentifier("transaction_source_\(transaction.id.uuidString)")
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Formatters.signedCurrencyString(amount: transaction.amount, currencyCode: transaction.currency))
                    .font(.headline)
                    .foregroundColor(transaction.amount < 0 ? .primary : BankPalette.positiveGreen)
                    .accessibilityIdentifier("transaction_amount_\(transaction.id.uuidString)")

                Text(Formatters.monthDayYear.string(from: transaction.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("transaction_timestamp_\(transaction.id.uuidString)")
            }
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("transaction_cell_\(transaction.id.uuidString)")
    }
}
