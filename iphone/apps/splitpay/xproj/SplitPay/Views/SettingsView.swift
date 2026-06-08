import SwiftUI

struct SettingsView: View {
    @State private var activeSheet: CryptoSheet?

    private let holdings: [CryptoHolding] = [
        CryptoHolding(symbol: "BTC", name: "Bitcoin", value: "$421.18", price: "$63,942.20", change: "+2.8%"),
        CryptoHolding(symbol: "ETH", name: "Ethereum", value: "$267.42", price: "$3,318.94", change: "+1.2%"),
        CryptoHolding(symbol: "LTC", name: "Litecoin", value: "$153.58", price: "$88.12", change: "-0.4%")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Text("Crypto")
                    .font(SplitPayTheme.titleFont(size: 34))
                    .foregroundStyle(SplitPayTheme.textPrimary)

                Button {
                    activeSheet = .portfolio
                } label: {
                    portfolioCard
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("crypto_portfolio_button")

                Text("Holdings")
                    .font(SplitPayTheme.titleFont(size: 24))
                    .foregroundStyle(SplitPayTheme.textPrimary)

                VStack(spacing: 14) {
                    ForEach(holdings) { holding in
                        Button {
                            activeSheet = .holding(holding)
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(SplitPayTheme.cardSecondary)
                                        .frame(width: 56, height: 56)
                                    Text(holding.symbol)
                                        .font(SplitPayTheme.bodyFont(size: 16, weight: .bold))
                                        .foregroundStyle(SplitPayTheme.textPrimary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(holding.name)
                                        .font(SplitPayTheme.titleFont(size: 20, weight: .regular))
                                        .foregroundStyle(SplitPayTheme.textPrimary)
                                    Text(holding.price)
                                        .font(SplitPayTheme.bodyFont(size: 16))
                                        .foregroundStyle(SplitPayTheme.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(holding.value)
                                        .font(SplitPayTheme.titleFont(size: 20, weight: .regular))
                                        .foregroundStyle(SplitPayTheme.textPrimary)
                                    Text(holding.change)
                                        .font(SplitPayTheme.bodyFont(size: 16, weight: .semibold))
                                        .foregroundStyle(holding.change.hasPrefix("-") ? .red : SplitPayTheme.success)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(SplitPayTheme.iconSecondary)
                            }
                            .padding(18)
                            .background(CardSurface(radius: 24))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("crypto_holding_\(holding.symbol.lowercased())")
                    }
                }

                Button {
                    activeSheet = .learn
                } label: {
                    learnCard
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("crypto_learn_button")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 124)
        }
        .background(SplitPayTheme.background.ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            CryptoInfoSheet(sheet: sheet)
        }
    }

    private var portfolioCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your portfolio")
                .font(SplitPayTheme.bodyFont(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.82))

            Text("$842.18")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.white)

            Text("Trade BTC, ETH, LTC, and BCH with as little as $1.")
                .font(SplitPayTheme.bodyFont(size: 18))
                .foregroundStyle(Color.white.opacity(0.88))

            HStack(spacing: 10) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 56, height: 8)
                Capsule()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 80, height: 8)
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 42, height: 8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.07, green: 0.15, blue: 0.33), SplitPayTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var learnCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learn before you trade")
                .font(SplitPayTheme.titleFont(size: 22))
                .foregroundStyle(SplitPayTheme.textPrimary)

            Text("Crypto values can go up and down quickly. SplitPay keeps the experience simple, but the risk is real.")
                .font(SplitPayTheme.bodyFont(size: 17))
                .foregroundStyle(SplitPayTheme.textSecondary)

            Text("Read the basics")
                .font(SplitPayTheme.bodyFont(size: 17, weight: .semibold))
                .foregroundStyle(SplitPayTheme.accent)
        }
        .padding(20)
        .background(CardSurface(radius: 24))
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 18))
                .foregroundColor(SplitPayTheme.textPrimary)
            Text(subtitle)
                .font(SplitPayTheme.bodyFont(size: 13))
                .foregroundColor(SplitPayTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(CardSurface(radius: 20))
    }
}

private struct CryptoHolding: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let value: String
    let price: String
    let change: String
}

private enum CryptoSheet: Identifiable {
    case portfolio
    case learn
    case holding(CryptoHolding)

    var id: String {
        switch self {
        case .portfolio:
            return "portfolio"
        case .learn:
            return "learn"
        case .holding(let holding):
            return "holding_\(holding.id.uuidString)"
        }
    }
}

private struct CryptoInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sheet: CryptoSheet
    @State private var tradeAmount = ""
    @State private var tradeConfirmation: String?

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
            .overlay {
                if let tradeConfirmation {
                    VStack {
                        Spacer()
                        Text(tradeConfirmation)
                            .font(SplitPayTheme.titleFont(size: 15))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.black.opacity(0.82)))
                            .padding(.bottom, 34)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var title: String {
        switch sheet {
        case .portfolio:
            return "Portfolio"
        case .learn:
            return "Crypto Basics"
        case .holding(let holding):
            return holding.name
        }
    }

    @ViewBuilder
    private var content: some View {
        switch sheet {
        case .portfolio:
            infoCard(
                title: "Your crypto overview",
                body: "Your portfolio holds BTC, ETH, and LTC with a combined value of $842.18."
            )
        case .learn:
            infoCard(
                title: "Learn before you trade",
                body: "Crypto prices can move quickly, and trades may involve fees and tax consequences. Always research before investing."
            )
        case .holding(let holding):
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(holding.name)
                        .font(SplitPayTheme.titleFont(size: 26))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                    Text(holding.price)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                    Text(holding.change)
                        .font(SplitPayTheme.bodyFont(size: 17, weight: .semibold))
                        .foregroundStyle(holding.change.hasPrefix("-") ? .red : SplitPayTheme.success)
                }

                Divider()

                HStack {
                    Text("Your position")
                        .font(SplitPayTheme.bodyFont(size: 17, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textSecondary)
                    Spacer()
                    Text(holding.value)
                        .font(SplitPayTheme.titleFont(size: 18))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                }

                Divider()

                TextField("$0.00", text: $tradeAmount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.textPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(SplitPayTheme.border, lineWidth: 1.5)
                    )
                    .accessibilityIdentifier("crypto_trade_amount_field")

                HStack(spacing: 14) {
                    SplitPaySecondaryButton(title: "Sell") {
                        executeTrade(action: "Sold", holding: holding)
                    }
                    .accessibilityIdentifier("crypto_sell_button")
                    SplitPayPrimaryButton(title: "Buy") {
                        executeTrade(action: "Bought", holding: holding)
                    }
                    .accessibilityIdentifier("crypto_buy_button")
                }
            }
            .padding(24)
            .background(CardSurface(radius: 24))
        }
    }

    private func executeTrade(action: String, holding: CryptoHolding) {
        let amount = Double(tradeAmount) ?? 0
        guard amount > 0 else { return }
        tradeAmount = ""
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            tradeConfirmation = "\(action) $\(String(format: "%.2f", amount)) of \(holding.symbol)"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                tradeConfirmation = nil
            }
        }
    }

    private func infoCard(title: String, body: String) -> some View {
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
