import SwiftUI

struct AccountCardView: View {
    let account: Account

    private var availableLabel: String {
        account.type == .credit ? "Available credit" : "Available"
    }

    private var utilizationPercent: Int? {
        guard account.type == .credit, let limit = account.creditLimit, limit > 0 else { return nil }
        return Int(round((account.balance / limit) * 100))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(account.name)
                    .font(.headline.weight(.semibold))
                    .accessibilityIdentifier("account_name_\(account.type.rawValue)")
                Spacer()
                Text(account.type.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("account_type_\(account.type.rawValue)")
            }

            Text(Formatters.currencyString(amount: account.balance, currencyCode: account.currency))
                .font(.title.weight(.bold))
                .accessibilityIdentifier("account_balance_\(account.type.rawValue)")

            HStack {
                Text(availableLabel)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(Formatters.currencyString(amount: account.availableBalance, currencyCode: account.currency))
                    .font(.footnote.weight(.semibold))
                    .accessibilityIdentifier("account_available_\(account.type.rawValue)")
            }

            if let utilization = utilizationPercent {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Credit utilization")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(utilization)%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(utilization > 30 ? .orange : BankPalette.positiveGreen)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(utilization > 30 ? Color.orange : BankPalette.positiveGreen)
                                .frame(width: geo.size.width * min(Double(utilization) / 100.0, 1.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }

            Text("Updated \(Formatters.relativeString(from: account.lastUpdated))")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("account_updated_\(account.type.rawValue)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("account_card_\(account.type.rawValue)")
    }
}
