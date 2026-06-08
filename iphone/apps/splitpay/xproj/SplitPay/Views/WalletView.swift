import SwiftUI

struct WalletView: View {
    @EnvironmentObject private var store: SplitPayStore
    @State private var activeSheet: WalletSheet?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Text("Cards")
                    .font(SplitPayTheme.titleFont(size: 34))
                    .foregroundStyle(SplitPayTheme.textPrimary)

                debitCard
                cardActions
                paymentMethods
                perksSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 124)
        }
        .background(SplitPayTheme.background.ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            WalletActionSheet(sheet: sheet)
                .environmentObject(store)
        }
    }

    private var debitCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SplitPayTheme.accentDark, SplitPayTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("SplitPay Debit Card")
                        .font(SplitPayTheme.titleFont(size: 22))
                        .foregroundStyle(Color.white)
                    Spacer()
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.white.opacity(0.95))
                }

                Spacer()

                Text(store.you.displayName.uppercased())
                    .font(SplitPayTheme.bodyFont(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.92))

                HStack {
                    Text("•••• 1843")
                        .font(SplitPayTheme.titleFont(size: 26, weight: .regular))
                        .foregroundStyle(Color.white)
                    Spacer()
                    Text(String(format: "$%.2f", store.balance))
                        .font(SplitPayTheme.titleFont(size: 28))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(24)
        }
        .frame(height: 220)
    }

    private var cardActions: some View {
        HStack(spacing: 12) {
            cardAction(title: "Show number", systemImage: "eye") {
                activeSheet = .showNumber
            }
            cardAction(title: "Wallet", systemImage: "wallet.pass") {
                activeSheet = .wallet
            }
        }
    }

    private func cardAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.accent)
                Text(title)
                    .font(SplitPayTheme.bodyFont(size: 15, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(CardSurface(radius: 24))
        }
        .buttonStyle(.plain)
    }

    private var paymentMethods: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Payment methods")
                .font(SplitPayTheme.titleFont(size: 24))
                .foregroundStyle(SplitPayTheme.textPrimary)

            ForEach(store.fundingSources) { source in
                Button {
                    activeSheet = .source(source)
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SplitPayTheme.cardSecondary)
                                .frame(width: 56, height: 56)
                            Image(systemName: source.isBalance ? "v.circle.fill" : "creditcard.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(source.isBalance ? SplitPayTheme.accent : SplitPayTheme.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.name)
                                .font(SplitPayTheme.titleFont(size: 20, weight: .regular))
                                .foregroundStyle(SplitPayTheme.textPrimary)
                            Text(source.subtitle)
                                .font(SplitPayTheme.bodyFont(size: 16))
                                .foregroundStyle(SplitPayTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(SplitPayTheme.iconSecondary)
                    }
                    .padding(18)
                    .background(CardSurface(radius: 24))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var perksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Card perks")
                .font(SplitPayTheme.titleFont(size: 24))
                .foregroundStyle(SplitPayTheme.textPrimary)

            VStack(alignment: .leading, spacing: 14) {
                perkRow(
                    title: "Instant transfers",
                    subtitle: "Move money to your bank in minutes.",
                    systemImage: "bolt.circle.fill"
                )
                Divider()
                perkRow(
                    title: "Tap to pay",
                    subtitle: "Use Apple Pay with your SplitPay card anywhere contactless is accepted.",
                    systemImage: "iphone.gen3.radiowaves.left.and.right"
                )
                Divider()
                perkRow(
                    title: "Cash back offers",
                    subtitle: "Unlock rotating offers from brands you already use.",
                    systemImage: "sparkles"
                )
            }
            .padding(20)
            .background(CardSurface(radius: 24))
        }
    }

    private func perkRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(SplitPayTheme.accent)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SplitPayTheme.titleFont(size: 19, weight: .regular))
                    .foregroundStyle(SplitPayTheme.textPrimary)
                Text(subtitle)
                    .font(SplitPayTheme.bodyFont(size: 16))
                    .foregroundStyle(SplitPayTheme.textSecondary)
            }
        }
    }
}

private enum WalletSheet: Identifiable {
    case showNumber
    case wallet
    case source(FundingSource)

    var id: String {
        switch self {
        case .showNumber:
            return "show_number"
        case .wallet:
            return "wallet"
        case .source(let source):
            return "source_\(source.id)"
        }
    }
}

private struct WalletActionSheet: View {
    @EnvironmentObject private var store: SplitPayStore
    @Environment(\.dismiss) private var dismiss

    let sheet: WalletSheet

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch sheet {
                    case .showNumber:
                        detailCard(
                            title: "Card details",
                            rows: [
                                ("Number", "4111 8432 1984 5512"),
                                ("Expiration", "09/29"),
                                ("CVV", "482")
                            ]
                        )
                    case .wallet:
                        detailCard(
                            title: "Apple Wallet",
                            rows: [
                                ("Status", "Ready to add"),
                                ("Default card", "SplitPay Debit Card"),
                                ("Contactless", "Enabled")
                            ]
                        )
                    case .source(let source):
                        detailCard(
                            title: source.name,
                            rows: [
                                ("Type", source.isBalance ? "SplitPay balance" : "External funding source"),
                                ("Details", source.subtitle),
                                ("Available", source.isBalance ? String(format: "$%.2f", store.balance) : "Approved")
                            ]
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
        case .showNumber:
            return "Card Number"
        case .wallet:
            return "Wallet"
        case .source(let source):
            return source.name
        }
    }

    private func detailCard(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 24))
                .foregroundStyle(SplitPayTheme.textPrimary)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text(row.0)
                        .font(SplitPayTheme.bodyFont(size: 17, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textSecondary)
                    Spacer()
                    Text(row.1)
                        .font(SplitPayTheme.bodyFont(size: 17))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                }

                if index != rows.count - 1 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(CardSurface(radius: 24))
    }
}

#Preview {
    WalletView()
        .environmentObject(SplitPayStore())
}
