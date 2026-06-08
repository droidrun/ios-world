import SwiftUI

private enum OfferCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case shopping = "Shopping"
    case groceries = "Groceries"
    case homePet = "Home & pet"
    case travel = "Travel"

    var id: Self { self }
}

private struct MyBankOffer: Identifiable {
    let id: String
    let name: String
    let reward: String
    let accent: Color
    let imageName: String
    let category: OfferCategory
    let estimatedValue: Double
    let isFeatured: Bool
    let expiresSoon: Bool
}

struct MyBankOffersView: View {
    @ObservedObject var store: BankStore
    @State private var selectedFilter: OfferCategory = .all
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let offers: [MyBankOffer] = [
        MyBankOffer(id: "turbotax", name: "TurboTax", reward: "30% cash back", accent: .red, imageName: "OfferShopping", category: .shopping, estimatedValue: 45, isFeatured: true, expiresSoon: false),
        MyBankOffer(id: "eight_sleep", name: "Eight Sleep", reward: "$100 cash back", accent: .green, imageName: "OfferWellness", category: .homePet, estimatedValue: 100, isFeatured: true, expiresSoon: true),
        MyBankOffer(id: "tonal", name: "Tonal", reward: "$250 cash back", accent: .orange, imageName: "OfferWellness", category: .homePet, estimatedValue: 250, isFeatured: true, expiresSoon: false),
        MyBankOffer(id: "iherb", name: "iHerb", reward: "8% cash back", accent: .mint, imageName: "OfferHome", category: .groceries, estimatedValue: 24, isFeatured: false, expiresSoon: false),
        MyBankOffer(id: "gilt", name: "Gilt", reward: "12% cash back", accent: .purple, imageName: "OfferShopping", category: .shopping, estimatedValue: 70, isFeatured: false, expiresSoon: true),
        MyBankOffer(id: "marriott", name: "Marriott", reward: "10% cash back", accent: .blue, imageName: "TravelHero", category: .travel, estimatedValue: 160, isFeatured: false, expiresSoon: false)
    ]

    private var filteredOffers: [MyBankOffer] {
        if selectedFilter == .all {
            return offers
        }
        return offers.filter { $0.category == selectedFilter }
    }

    private var featuredOffers: [MyBankOffer] {
        filteredOffers.filter(\.isFeatured)
    }

    private var addedOffers: [MyBankOffer] {
        offers.filter { store.activatedOfferIds.contains($0.id) }
    }

    private var totalPotentialValue: Double {
        addedOffers.reduce(0) { $0 + $1.estimatedValue }
    }

    private var expiringCount: Int {
        addedOffers.filter(\.expiresSoon).count
    }

    private var usesCompactLayout: Bool {
        dynamicTypeSize >= .xLarge
    }

    private var offerGridColumns: [GridItem] {
        usesCompactLayout ? [GridItem(.flexible())] : [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("MyBank Offers")
                    .font(.system(size: usesCompactLayout ? 34 : 40, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.top, 20)

                ViewThatFits {
                    HStack(spacing: 12) {
                        FreedomUnlimitedCardArtwork(height: 72)
                            .frame(width: 124, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text("Freedom Unlimited (...2095)")
                            .font(.system(size: usesCompactLayout ? 20 : 22, weight: .medium))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        FreedomUnlimitedCardArtwork(height: 72)
                            .frame(width: 124, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text("Freedom Unlimited (...2095)")
                            .font(.system(size: 20, weight: .medium))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                    }
                }

                SurfaceCard {
                    ViewThatFits(in: .vertical) {
                        HStack(alignment: .center, spacing: 18) {
                            PotentialValueBlock(totalPotentialValue: totalPotentialValue)

                            Divider()
                                .frame(height: 92)

                            MyBankOfferMetric(value: "\(store.activatedOfferIds.count)", label: "Added offers")
                            MyBankOfferMetric(value: "\(expiringCount)", label: "Expiring soon")
                        }

                        VStack(alignment: .leading, spacing: 18) {
                            PotentialValueBlock(totalPotentialValue: totalPotentialValue)

                            Divider()

                            HStack(spacing: 14) {
                                MyBankOfferMetric(value: "\(store.activatedOfferIds.count)", label: "Added offers")
                                MyBankOfferMetric(value: "\(expiringCount)", label: "Expiring soon")
                            }
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(OfferCategory.allCases) { category in
                            OfferFilterChip(
                                label: category.rawValue,
                                isSelected: category == selectedFilter
                            ) {
                                selectedFilter = category
                            }
                        }
                    }
                }

                if !featuredOffers.isEmpty {
                    Text("Featured for you")
                        .font(.system(size: 26, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(featuredOffers) { offer in
                                MyBankOfferCard(
                                    offer: offer,
                                    isLarge: true,
                                    isAdded: store.activatedOfferIds.contains(offer.id)
                                ) {
                                    toggleOffer(offer.id)
                                }
                                .frame(width: 314)
                            }
                        }
                    }
                }

                Text("All offers")
                    .font(.system(size: 26, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                LazyVGrid(columns: offerGridColumns, spacing: 18) {
                    ForEach(filteredOffers) { offer in
                        MyBankOfferCard(
                            offer: offer,
                            isLarge: false,
                            isAdded: store.activatedOfferIds.contains(offer.id)
                        ) {
                            toggleOffer(offer.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(BankPalette.pageBackground)
    }

    private func toggleOffer(_ id: String) {
        store.toggleOffer(id)
    }
}

private struct MyBankOfferMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 30, weight: .medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(BankPalette.chaseBlue)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct OfferFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : BankPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? BankPalette.chaseBlue : .white)
                )
                .overlay(
                    Capsule()
                        .stroke(BankPalette.outline, lineWidth: isSelected ? 0 : 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct MyBankOfferCard: View {
    let offer: MyBankOffer
    let isLarge: Bool
    let isAdded: Bool
    let onToggle: () -> Void

    var body: some View {
        SurfaceCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Image(offer.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: isLarge ? 170 : 150)
                        .overlay(
                            LinearGradient(
                                colors: [offer.accent.opacity(0.15), offer.accent.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.28))
                                .padding(16)
                                .overlay(
                                    Text(offer.name.prefix(1))
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        )

                    Text(offer.expiresSoon ? "Soon" : "New")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(offer.expiresSoon ? Color.orange.opacity(0.9) : Color.green.opacity(0.9))
                        )
                        .padding(12)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(offer.name)
                        .font(.system(size: isLarge ? 22 : 20, weight: .medium))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text(offer.reward)
                        .font(.system(size: isLarge ? 18 : 17, weight: .semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text("Estimated value \(Formatters.currencyString(amount: offer.estimatedValue, currencyCode: "USD"))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Button(action: onToggle) {
                        HStack(spacing: 8) {
                            Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                            Text(isAdded ? "Added" : "Add offer")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(BankPalette.chaseBlue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
    }
}

private struct PotentialValueBlock: View {
    let totalPotentialValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Formatters.currencyString(amount: totalPotentialValue, currencyCode: "USD"))
                .font(.system(size: 34, weight: .medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text("Potential value")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
