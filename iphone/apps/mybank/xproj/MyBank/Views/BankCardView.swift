import SwiftUI

struct BankCardView: View {
    let account: Account
    let title: String

    var body: some View {
        let descriptor = CardDescriptor.forAccount(account)
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: descriptor.colors, startPoint: .topLeading, endPoint: .bottomTrailing))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.85))
                        Text(Formatters.currencyString(amount: account.balance, currencyCode: account.currency))
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                            .accessibilityIdentifier("card_balance_\(account.type.rawValue)")
                    }
                    Spacer()
                    Text(descriptor.network)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Text(descriptor.maskedNumber)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .accessibilityIdentifier("card_number_\(account.type.rawValue)")

                Text("Updated \(Formatters.dateTime.string(from: account.lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(18)
        }
        .frame(height: 180)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
        .accessibilityIdentifier("card_view_\(account.type.rawValue)")
    }
}

private struct CardDescriptor {
    let maskedNumber: String
    let network: String
    let colors: [Color]

    static func forAccount(_ account: Account) -> CardDescriptor {
        switch account.type {
        case .checking:
            return CardDescriptor(
                maskedNumber: "**** **** **** 6645",
                network: "VISA",
                colors: [Color(red: 0.12, green: 0.24, blue: 0.58), Color(red: 0.25, green: 0.47, blue: 0.88)]
            )
        case .savings:
            return CardDescriptor(
                maskedNumber: "**** **** **** 7814",
                network: "VISA",
                colors: [Color(red: 0.12, green: 0.55, blue: 0.46), Color(red: 0.22, green: 0.73, blue: 0.62)]
            )
        case .credit:
            return CardDescriptor(
                maskedNumber: "**** **** **** 2095",
                network: "VISA",
                colors: [Color(red: 0.23, green: 0.33, blue: 0.82), Color(red: 0.35, green: 0.55, blue: 0.95)]
            )
        }
    }
}
