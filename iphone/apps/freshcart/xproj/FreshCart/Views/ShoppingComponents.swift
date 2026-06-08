import SwiftUI

extension Color {
    static let instacartGreen = Color(red: 0.039, green: 0.678, blue: 0.020)    // #0AAD05
    static let instacartGreenDark = Color(red: 0.0, green: 0.239, blue: 0.161)  // #003D29
    static let instacartBlue = Color(red: 0.05, green: 0.40, blue: 0.73)
    static let instacartBackground = Color(red: 0.969, green: 0.957, blue: 0.933) // warm cream #F7F4EE
    static let instacartChip = Color(red: 0.93, green: 0.92, blue: 0.90)
    static let instacartYellow = Color(red: 0.99, green: 0.87, blue: 0.12)
    static let instacartCream = Color(red: 0.980, green: 0.945, blue: 0.898)     // #FAF1E5
    static let instacartOrange = Color(red: 1.0, green: 0.439, blue: 0.035)      // #FF7009
}

struct InsetIconButton: View {
    let systemImage: String
    let filled: Bool
    let action: () -> Void

    init(systemImage: String, filled: Bool = false, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.filled = filled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(filled ? Color.white : Color.primary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(filled ? Color.black.opacity(0.16) : Color.white.opacity(0.94)))
        }
        .buttonStyle(.plain)
    }
}

struct MarketplaceServiceTile: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct MarketplaceFilterPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.instacartChip))
    }
}

struct StoreLogoBadge: View {
    let store: Store

    var body: some View {
        Group {
            if let uiImage = UIImage(named: "StoreLogos/store_\(store.id)") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundColor)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        logoContent
                            .padding(6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : 1.5)
                    )
            }
        }
    }

    private var backgroundColor: Color {
        switch store.id {
        case "costco":
            return .white
        case "panera":
            return Color(red: 0.96, green: 0.93, blue: 0.86)
        case "chipotle":
            return Color(red: 0.49, green: 0.11, blue: 0.07)
        case "target":
            return Color(red: 0.80, green: 0.12, blue: 0.15)
        case "lowes":
            return Color(red: 0.01, green: 0.16, blue: 0.53)
        case "walmart":
            return Color(red: 0.00, green: 0.44, blue: 0.81)
        case "whole_foods":
            return Color(red: 0.00, green: 0.40, blue: 0.29)
        case "trader_joes":
            return Color(red: 0.78, green: 0.06, blue: 0.18)
        case "walgreens":
            return Color(red: 0.89, green: 0.10, blue: 0.22)
        case "sams_club":
            return Color(red: 0.00, green: 0.38, blue: 0.66)
        case "sprouts":
            return Color(red: 0.96, green: 0.97, blue: 0.93)
        case "giant_eagle":
            return .white
        case "market_district":
            return Color(red: 0.97, green: 0.95, blue: 0.92)
        case "jewel_osco":
            return .white
        case "family_dollar":
            return Color(red: 0.98, green: 0.96, blue: 0.93)
        case "cvs":
            return .white
        case "dollar_tree":
            return .white
        case "michaels":
            return .white
        case "petco":
            return .white
        default:
            return Color(red: 0.94, green: 0.94, blue: 0.96)
        }
    }

    private var borderColor: Color {
        switch store.id {
        case "aldi":
            return Color(red: 0.93, green: 0.72, blue: 0.07)
        case "costco", "giant_eagle", "cvs", "dollar_tree", "michaels", "petco", "jewel_osco", "sprouts", "market_district", "family_dollar":
            return Color.black.opacity(0.08)
        default:
            return .clear
        }
    }

    @ViewBuilder
    private var logoContent: some View {
        switch store.id {
        case "costco":
            VStack(spacing: -2) {
                Text("Costco")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Color(red: 0.88, green: 0.16, blue: 0.17))
                Text("WHOLESALE")
                    .font(.system(size: 6, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(Color(red: 0.10, green: 0.34, blue: 0.74))
            }
        case "petco":
            Text("petco")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(red: 0.04, green: 0.19, blue: 0.47))
        case "aldi":
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.03, green: 0.19, blue: 0.53))
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color(red: 0.98, green: 0.46, blue: 0.12), lineWidth: 2)
                    .padding(4)
                Text("ALDI")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
            }
        case "giant_eagle":
            Text("giant\neagle")
                .font(.system(size: 14, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.75, green: 0.21, blue: 0.23))
        case "target":
            Text("Target")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)
        case "market_district":
            VStack(spacing: 1) {
                Text("Market")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                Text("DISTRICT")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
            }
            .foregroundStyle(Color(red: 0.48, green: 0.20, blue: 0.15))
        case "panera":
            Text("Panera")
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.37, green: 0.22, blue: 0.12))
        case "chipotle":
            Text("CHIPOTLE")
                .font(.system(size: 14, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.white)
        case "cvs":
            HStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("CVS")
                    .font(.system(size: 17, weight: .heavy))
            }
            .foregroundStyle(Color(red: 0.78, green: 0.17, blue: 0.16))
        case "lowes":
            Text("Lowe's")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)
        case "dollar_tree":
            Text("DOLLAR\nTREE")
                .font(.system(size: 13, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.11, green: 0.62, blue: 0.25))
        case "michaels":
            VStack(spacing: 0) {
                Text("Michaels")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                Text("Made by you")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundStyle(Color(red: 0.87, green: 0.18, blue: 0.24))
        case "family_dollar":
            Text("FAMILY\nDOLLAR")
                .font(.system(size: 13, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.94, green: 0.16, blue: 0.14),
                            Color(red: 0.98, green: 0.56, blue: 0.11)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        case "walmart":
            VStack(spacing: -1) {
                Text("Walmart")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.0))
            }
        case "whole_foods":
            VStack(spacing: 0) {
                Text("WHOLE")
                    .font(.system(size: 12, weight: .heavy))
                Text("FOODS")
                    .font(.system(size: 12, weight: .heavy))
                Text("M A R K E T")
                    .font(.system(size: 5, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(.white)
        case "trader_joes":
            VStack(spacing: 0) {
                Text("TRADER")
                    .font(.system(size: 12, weight: .heavy))
                Text("JOE'S")
                    .font(.system(size: 14, weight: .heavy))
            }
            .foregroundStyle(.white)
        case "walgreens":
            Text("Walgreens")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(.white)
        case "jewel_osco":
            VStack(spacing: 0) {
                Text("jewel")
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                Text("OSCO")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
            }
            .foregroundStyle(Color(red: 0.84, green: 0.10, blue: 0.13))
        case "sprouts":
            VStack(spacing: 0) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.42, green: 0.56, blue: 0.14))
                Text("Sprouts")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(red: 0.42, green: 0.56, blue: 0.14))
            }
        case "sams_club":
            VStack(spacing: -1) {
                Text("SAM'S")
                    .font(.system(size: 14, weight: .heavy))
                Text("CLUB")
                    .font(.system(size: 11, weight: .heavy))
            }
            .foregroundStyle(.white)
        default:
            Text(store.storeName)
                .font(.system(size: 13, weight: .heavy))
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
        }
    }
}

struct MarketplaceStoreTile: View {
    let store: Store
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                StoreLogoBadge(store: store)
                    .frame(width: 64, height: 64)

                Text(store.storeName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let badgeText {
                    Text(badgeText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.instacartGreenDark)
                        .lineLimit(1)
                } else {
                    Text(store.dynamicETA)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.storeCard(store.id))
    }

    private var badgeText: String? {
        switch store.id {
        case "petco":
            return "$10 off"
        case "cvs", "lowes", "dollar_tree", "michaels", "walgreens":
            return "In-store prices"
        case "walmart":
            return "Low prices"
        case "whole_foods":
            return "Prime deals"
        default:
            return nil
        }
    }
}

struct StorefrontShortcutTile: View {
    let title: String
    let subtitle: String?
    let product: Product?
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                    if let product {
                        ProductArtView(product: product, cornerRadius: 20)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(6)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.instacartGreen)
                    }
                }
                .frame(width: 104, height: 84)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 108)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SearchSuggestionChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.instacartChip))
        }
        .buttonStyle(.plain)
    }
}

struct PopularSearchTile: View {
    let product: Product
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                    ProductArtView(product: product, cornerRadius: 18)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(6)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 96)

                Text(product.productName)
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .top)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SearchStoreMatchCard: View {
    let match: SearchViewModel.StoreSearchMatch
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    StoreLogoBadge(store: match.store)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(match.store.storeName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text("\(match.resultCount) matches")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if let previewProduct = match.previewProduct {
                    Text(previewProduct.productName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(width: 196, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.storeCard(match.store.id))
    }
}

struct SearchResultCard: View {
    let product: Product
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onOpen) {
                ZStack {
                    ProductArtView(product: product)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)

                    // Buy it again badge
                    if product.isBuyAgain {
                        VStack {
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 9, weight: .bold))
                                    Text("Buy it again")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundStyle(Color.instacartGreenDark)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.92)))
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(8)
                    }

                    // Green + button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: onAdd) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(product.inStock ? Color.instacartGreen : Color.gray))
                            }
                            .buttonStyle(.plain)
                            .disabled(product.inStock == false)
                            .accessibilityIdentifier(AccessibilityID.addToCart(product.id))
                        }
                    }
                    .padding(8)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.productRow(product.id))

            if product.isOnSale {
                HStack(spacing: 6) {
                    Text(AppFormatters.currencyString(product.price))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.instacartGreen)
                    Text(product.saleLabel ?? "")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
                .accessibilityIdentifier(AccessibilityID.priceLabel("search_\(product.id)"))
            } else {
                Text(AppFormatters.currencyString(product.price))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier(AccessibilityID.priceLabel("search_\(product.id)"))
            }

            Text(product.productName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(3)

            Text(product.brand)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Text(product.packageSize)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

struct StorefrontProductCard: View {
    let product: Product
    let badgeText: String?
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onOpen) {
                ZStack(alignment: .topLeading) {
                    ProductArtView(product: product)
                        .frame(width: 164, height: 150)

                    // Buy it again badge
                    if product.isBuyAgain {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .bold))
                            Text("Buy it again")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Color.instacartGreenDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.white.opacity(0.92))
                        )
                        .padding(8)
                    } else if let badgeText {
                        Text(badgeText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.instacartGreenDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color.white.opacity(0.92))
                            )
                            .padding(8)
                    }

                    // Green + button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: onAdd) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.instacartGreen))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.addToCart(product.id))
                        }
                    }
                    .padding(8)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.productRow(product.id))

            VStack(alignment: .leading, spacing: 3) {
                if product.isOnSale {
                    HStack(spacing: 6) {
                        Text(AppFormatters.currencyString(product.price))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.instacartGreen)
                        Text(product.saleLabel ?? "")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }
                } else {
                    Text(AppFormatters.currencyString(product.price))
                        .font(.system(size: 16, weight: .bold))
                }
                Text(product.productName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                Text(product.brand)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(product.packageSize)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 164, alignment: .leading)
    }
}

struct RelatedProductCard: View {
    let product: Product
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Button(action: onOpen) {
                    ProductArtView(product: product)
                        .frame(width: 124, height: 124)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.productRow(product.id))

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: onAdd) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.instacartGreen))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityID.addToCart(product.id))
                    }
                }
                .padding(6)
            }
            .frame(width: 124, height: 124)

            Text(AppFormatters.currencyString(product.price))
                .font(.system(size: 15, weight: .bold))
                .accessibilityIdentifier(AccessibilityID.priceLabel("related_\(product.id)"))

            Text(product.productName)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)

            Text(product.packageSize)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(width: 124, alignment: .leading)
    }
}

struct FloatingCartBar: View {
    let subtotal: Double
    let cartCount: Int
    let action: () -> Void

    private let unlockTarget = 10.0

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(message)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.instacartGreenDark.opacity(0.5))
                            Capsule()
                                .fill(Color.instacartYellow)
                                .frame(width: max(12, geometry.size.width * progress))
                        }
                    }
                    .frame(height: 8)
                }

                HStack(spacing: 10) {
                    Image(systemName: "cart")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Cart")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.instacartGreen)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var progress: CGFloat {
        CGFloat(min(max(subtotal / unlockTarget, 0), 1))
    }

    private var message: String {
        let remaining = max(0, unlockTarget - subtotal)
        if remaining > 0 {
            return "$0 delivery fee, spend \(compactCurrency(remaining))"
        }
        return "Free delivery unlocked for \(cartCount) item\(cartCount == 1 ? "" : "s")"
    }

    private func compactCurrency(_ value: Double) -> String {
        let rounded = round(value)
        if abs(rounded - value) < 0.01 {
            return "$\(Int(rounded))"
        }
        return AppFormatters.currencyString(value)
    }
}

struct CartIllustrationView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.instacartGreenDark)
                .frame(width: 116, height: 82)
                .offset(x: 8, y: 18)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Path { path in
                path.move(to: CGPoint(x: 34, y: 74))
                path.addLine(to: CGPoint(x: 68, y: 74))
                path.addLine(to: CGPoint(x: 88, y: 118))
                path.addLine(to: CGPoint(x: 160, y: 118))
            }
            .stroke(Color.instacartGreen, lineWidth: 12)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.instacartGreen)
                .frame(width: 118, height: 86)
                .offset(x: -2, y: 16)
                .rotationEffect(.degrees(6))

            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { _ in
                    Capsule()
                        .fill(Color.instacartGreenDark)
                        .frame(width: 12, height: 46)
                }
            }
            .offset(x: -4, y: 18)

            VStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.instacartGreenDark)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            .offset(x: -6, y: 16)

            Circle()
                .fill(Color.instacartGreen)
                .frame(width: 74, height: 74)
                .offset(x: -4, y: -62)

            Circle()
                .fill(Color(red: 0.95, green: 0.92, blue: 0.85))
                .frame(width: 56, height: 56)
                .offset(x: -4, y: -62)

            Ellipse()
                .fill(Color(red: 0.63, green: 0.88, blue: 0.20))
                .frame(width: 22, height: 54)
                .rotationEffect(.degrees(24))
                .offset(x: -2, y: -62)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.63, green: 0.88, blue: 0.20))
                .frame(width: 52, height: 98)
                .offset(x: 56, y: -6)
                .rotationEffect(.degrees(-2))

            VStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(Color.instacartGreen.opacity(0.65))
                        .frame(width: 38, height: 3)
                }
            }
            .offset(x: 56, y: -2)

            Circle()
                .fill(Color.instacartGreen)
                .frame(width: 36, height: 36)
                .offset(x: 44, y: -96)

            Circle()
                .fill(Color(red: 0.89, green: 0.94, blue: 0.78))
                .frame(width: 16, height: 16)
                .offset(x: 48, y: -96)

            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.instacartGreen)
                    .frame(width: 2, height: 18)
                    .rotationEffect(.degrees(Double(-40 + index * 35)))
                    .offset(x: 74 + CGFloat(index * 8), y: -116 + CGFloat(index * 2))
            }

            HStack(spacing: 40) {
                Circle().fill(Color.instacartGreenDark)
                Circle().fill(Color.instacartGreenDark)
                Circle().fill(Color.instacartGreenDark)
            }
            .frame(width: 160)
            .overlay(
                HStack(spacing: 40) {
                    Circle().stroke(Color.instacartGreen, lineWidth: 6)
                    Circle().stroke(Color.instacartGreen, lineWidth: 6)
                    Circle().stroke(Color.instacartGreen, lineWidth: 6)
                }
                .frame(width: 160)
            )
            .offset(x: 6, y: 98)
        }
        .frame(width: 260, height: 240)
    }
}

struct ProductArtView: View {
    let product: Product
    var cornerRadius: CGFloat = 20

    private enum ArtKind {
        case grapes
        case berries(Color)
        case avocados
        case leafyGreens(String)
        case croissants
        case breadLoaf
        case soupBowl
        case sandwichPlate
        case rotisserieChicken
        case salmonFresh
        case salmonFrozen
        case eggs
        case paperGoods
        case tissueCube
        case sparklingPack
        case yogurtPack
        case storageBins
        case vitamins
        case toolCase
        case paintCan
        case liquid(Color, String)
        case dogFood
        case bakery(Color, String)
        case boxed(Color, String)
        case generic(Color, String)
    }

    var body: some View {
        Group {
            if let uiImage = UIImage(named: "ProductImages/\(product.id)") {
                Color.clear
                    .overlay(
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    )
            } else {
                ZStack {
                    background
                    artContent
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch artKind {
        case .salmonFresh:
            LinearGradient(
                colors: [
                    Color(red: 0.37, green: 0.20, blue: 0.11),
                    Color(red: 0.46, green: 0.24, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .salmonFrozen:
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.48, blue: 0.84),
                    Color(red: 0.08, green: 0.34, blue: 0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .toolCase:
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.97, blue: 0.99),
                    Color(red: 0.90, green: 0.93, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.97, green: 0.97, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var artContent: some View {
        switch artKind {
        case .grapes:
            fruitBowlArt(color: Color(red: 0.74, green: 0.85, blue: 0.31), accent: Color(red: 0.55, green: 0.72, blue: 0.18))
        case .berries(let color):
            fruitBowlArt(color: color, accent: color.opacity(0.7))
        case .avocados:
            avocadoArt
        case .leafyGreens(let title):
            greensBagArt(title: title)
        case .croissants:
            croissantTrayArt
        case .breadLoaf:
            breadLoafArt
        case .soupBowl:
            soupBowlArt
        case .sandwichPlate:
            sandwichPlateArt
        case .rotisserieChicken:
            rotisserieChickenArt
        case .salmonFresh:
            salmonFreshArt
        case .salmonFrozen:
            frozenSalmonArt
        case .eggs:
            packageArt(bodyColor: Color(red: 0.92, green: 0.89, blue: 0.82), title: "EGGS", titleColor: .primary)
        case .paperGoods:
            packageArt(bodyColor: Color(red: 0.82, green: 0.88, blue: 0.97), title: packageLabel, titleColor: Color(red: 0.14, green: 0.29, blue: 0.56))
        case .tissueCube:
            tissueCubeArt
        case .sparklingPack:
            sparklingCanArt
        case .yogurtPack:
            yogurtPackArt
        case .storageBins:
            storageBinsArt
        case .vitamins:
            vitaminBottleArt
        case .toolCase:
            toolCaseArt
        case .paintCan:
            paintCanArt
        case .liquid(let color, let title):
            bottlePackArt(color: color, title: title)
        case .dogFood:
            dogFoodArt
        case .bakery(let color, let title):
            packageArt(bodyColor: color, title: title, titleColor: .white)
        case .boxed(let color, let title):
            packageArt(bodyColor: color, title: title, titleColor: .white)
        case .generic(let color, let title):
            packageArt(bodyColor: color, title: title, titleColor: .white)
        }
    }

    private var artKind: ArtKind {
        let name = product.productName.lowercased()
        if name.contains("grapes") {
            return .grapes
        }
        if name.contains("strawberr") {
            return .berries(Color(red: 0.82, green: 0.14, blue: 0.19))
        }
        if name.contains("blueberr") {
            return .berries(Color(red: 0.20, green: 0.31, blue: 0.56))
        }
        if name.contains("raspberr") {
            return .berries(Color(red: 0.78, green: 0.12, blue: 0.31))
        }
        if name.contains("avocado") {
            return .avocados
        }
        if name.contains("spinach") {
            return .leafyGreens("SPINACH")
        }
        if name.contains("salad") {
            return .leafyGreens("SALAD")
        }
        if name.contains("soup") {
            return .soupBowl
        }
        if name.contains("sushi") {
            return .boxed(Color(red: 0.19, green: 0.54, blue: 0.49), "SUSHI")
        }
        if name.contains("bowl") {
            return .boxed(Color(red: 0.36, green: 0.57, blue: 0.23), "BOWL")
        }
        if name.contains("burrito") {
            return .boxed(Color(red: 0.58, green: 0.34, blue: 0.18), "WRAP")
        }
        if name.contains("sandwich") {
            return .sandwichPlate
        }
        if name.contains("croissant") {
            return .croissants
        }
        if name.contains("bagel") {
            return .breadLoaf
        }
        if name.contains("bread") {
            return .breadLoaf
        }
        if name.contains("salmon") && name.contains("farmed atlantic salmon, 6 oz") {
            return .salmonFrozen
        }
        if name.contains("salmon") {
            return .salmonFresh
        }
        if name.contains("eggs") {
            return .eggs
        }
        if name.contains("paper plate") {
            return .boxed(Color(red: 0.90, green: 0.92, blue: 0.97), "PLATES")
        }
        if name.contains("paper") || name.contains("towel") {
            return .paperGoods
        }
        if name.contains("sparkling") {
            return .sparklingPack
        }
        if name.contains("pasta") || name.contains("penne") {
            return .boxed(Color(red: 0.85, green: 0.66, blue: 0.24), "PASTA")
        }
        if name.contains("marinara") || name.contains("sauce") {
            return .boxed(Color(red: 0.78, green: 0.20, blue: 0.19), "SAUCE")
        }
        if name.contains("water") {
            return .liquid(Color(red: 0.31, green: 0.69, blue: 0.93), "WATER")
        }
        if name.contains("juice") {
            return .liquid(Color(red: 0.95, green: 0.60, blue: 0.18), "JUICE")
        }
        if name.contains("coca-cola") {
            return .liquid(Color(red: 0.71, green: 0.15, blue: 0.15), "COLA")
        }
        if name.contains("tea") {
            return .liquid(Color(red: 0.76, green: 0.39, blue: 0.18), "TEA")
        }
        if name.contains("paint") {
            return .paintCan
        }
        if name.contains("milk") {
            return .liquid(Color(red: 0.93, green: 0.94, blue: 0.97), "MILK")
        }
        if name.contains("soap") {
            return .liquid(Color(red: 0.57, green: 0.86, blue: 0.67), "SOAP")
        }
        if name.contains("shampoo") {
            return .liquid(Color(red: 0.78, green: 0.86, blue: 0.98), "SHAM")
        }
        if name.contains("glue") {
            return .liquid(Color(red: 0.95, green: 0.95, blue: 0.98), "GLUE")
        }
        if name.contains("protein shake") {
            return .liquid(Color(red: 0.41, green: 0.26, blue: 0.17), "SHAKES")
        }
        if name.contains("coffee") {
            return .liquid(Color(red: 0.48, green: 0.30, blue: 0.17), "BREW")
        }
        if name.contains("yogurt") {
            return .yogurtPack
        }
        if name.contains("laundry") {
            return .liquid(Color(red: 0.79, green: 0.90, blue: 1.0), "ULTRA")
        }
        if name.contains("trash") {
            return .boxed(Color(red: 0.18, green: 0.28, blue: 0.21), "TRASH")
        }
        if name.contains("litter") {
            return .boxed(Color(red: 0.85, green: 0.83, blue: 0.74), "LITTER")
        }
        if name.contains("storage") {
            return .storageBins
        }
        if name.contains("candle") {
            return .boxed(Color(red: 0.92, green: 0.88, blue: 0.75), "CANDLE")
        }
        if name.contains("blanket") || name.contains("throw") {
            return .boxed(Color(red: 0.56, green: 0.66, blue: 0.88), "THROW")
        }
        if name.contains("vitamin") {
            return .vitamins
        }
        if name.contains("pain relief") || name.contains("cough") {
            return .vitamins
        }
        if name.contains("toothpaste") || name.contains("bandage") {
            return .boxed(Color(red: 0.88, green: 0.90, blue: 0.95), "CARE")
        }
        if name.contains("battery") {
            return .boxed(Color(red: 0.36, green: 0.39, blue: 0.45), "BATT")
        }
        if name.contains("tissue") {
            return .tissueCube
        }
        if name.contains("cleaner") {
            return .liquid(Color(red: 0.69, green: 0.93, blue: 0.79), "CLEAN")
        }
        if name.contains("chips") {
            return .boxed(Color(red: 0.96, green: 0.74, blue: 0.18), "CHIPS")
        }
        if name.contains("queso") {
            return .boxed(Color(red: 0.95, green: 0.84, blue: 0.52), "QUESO")
        }
        if name.contains("drill") || name.contains("tool") {
            return .toolCase
        }
        if name.contains("bulb") {
            return .boxed(Color(red: 0.98, green: 0.90, blue: 0.42), "LED")
        }
        if name.contains("planter") || name.contains("pot") {
            return .boxed(Color(red: 0.42, green: 0.63, blue: 0.36), "PLANT")
        }
        if name.contains("glove") {
            return .boxed(Color(red: 0.44, green: 0.48, blue: 0.53), "GLOVE")
        }
        if name.contains("cookie") || name.contains("snack") {
            return .boxed(Color(red: 0.74, green: 0.52, blue: 0.28), "SNACK")
        }
        if name.contains("cereal") {
            return .boxed(Color(red: 0.96, green: 0.78, blue: 0.28), "CEREAL")
        }
        if name.contains("yarn") {
            return .boxed(Color(red: 0.63, green: 0.45, blue: 0.84), "YARN")
        }
        if name.contains("frame") {
            return .boxed(Color(red: 0.55, green: 0.39, blue: 0.26), "FRAME")
        }
        if name.contains("wreath") {
            return .boxed(Color(red: 0.31, green: 0.59, blue: 0.33), "DECOR")
        }
        if name.contains("dog") {
            return .dogFood
        }
        if name.contains("rotisserie") {
            return .rotisserieChicken
        }
        if name.contains("biscuit") || name.contains("treat") {
            return .boxed(Color(red: 0.87, green: 0.67, blue: 0.28), "TREATS")
        }
        if name.contains("toy") {
            return .boxed(Color(red: 0.31, green: 0.70, blue: 0.44), "TOY")
        }
        if name.contains("cinnamon") {
            return .bakery(Color(red: 0.55, green: 0.17, blue: 0.46), "CINNAMON")
        }
        if name.contains("granola") {
            return .boxed(Color(red: 0.45, green: 0.31, blue: 0.72), "GRANOLA")
        }
        if name.contains("nuggets") {
            return .boxed(Color(red: 0.90, green: 0.89, blue: 0.84), "NUGGETS")
        }
        if name.contains("hamantaschen") {
            return .bakery(Color(red: 0.93, green: 0.72, blue: 0.22), "HAMAN")
        }
        if name.contains("caramel") {
            return .bakery(Color(red: 0.86, green: 0.80, blue: 0.73), "CAKE")
        }
        if name.contains("ribeye") || name.contains("steak") || name.contains("filet mignon") || name.contains("ny strip") {
            return .boxed(Color(red: 0.55, green: 0.14, blue: 0.12), "STEAK")
        }
        if name.contains("ground beef") || name.contains("ground turkey") {
            return .boxed(Color(red: 0.60, green: 0.22, blue: 0.16), "GROUND")
        }
        if name.contains("pork") {
            return .boxed(Color(red: 0.72, green: 0.48, blue: 0.34), "PORK")
        }
        if name.contains("shrimp") {
            return .boxed(Color(red: 0.90, green: 0.50, blue: 0.35), "SHRIMP")
        }
        if name.contains("bacon") {
            return .boxed(Color(red: 0.68, green: 0.18, blue: 0.14), "BACON")
        }
        if name.contains("sausage") || name.contains("hot dog") || name.contains("franks") {
            return .boxed(Color(red: 0.60, green: 0.30, blue: 0.16), "SAUSAGE")
        }
        if name.contains("turkey") {
            return .boxed(Color(red: 0.55, green: 0.36, blue: 0.22), "TURKEY")
        }
        if name.contains("lamb") {
            return .boxed(Color(red: 0.50, green: 0.18, blue: 0.15), "LAMB")
        }
        if name.contains("ham") && !name.contains("shampoo") {
            return .boxed(Color(red: 0.72, green: 0.36, blue: 0.28), "HAM")
        }
        if name.contains("crab") || name.contains("lobster") {
            return .boxed(Color(red: 0.80, green: 0.22, blue: 0.14), "SEAFOOD")
        }
        if name.contains("tilapia") || name.contains("cod") || name.contains("tuna") {
            return .boxed(Color(red: 0.30, green: 0.55, blue: 0.75), "FISH")
        }
        if name.contains("chicken") {
            return .boxed(Color(red: 0.80, green: 0.60, blue: 0.30), "CHICKEN")
        }
        if name.contains("pizza") {
            return .boxed(Color(red: 0.85, green: 0.30, blue: 0.18), "PIZZA")
        }
        if name.contains("ice cream") {
            return .boxed(Color(red: 0.88, green: 0.82, blue: 0.70), "ICE CRM")
        }
        if name.contains("waffle") {
            return .boxed(Color(red: 0.90, green: 0.78, blue: 0.42), "WAFFLE")
        }
        if name.contains("onion") {
            return .boxed(Color(red: 0.82, green: 0.72, blue: 0.42), "ONIONS")
        }
        if name.contains("potato") {
            return .boxed(Color(red: 0.72, green: 0.58, blue: 0.36), "POTATO")
        }
        if name.contains("tomato") {
            return .boxed(Color(red: 0.82, green: 0.22, blue: 0.18), "TOMATO")
        }
        if name.contains("orange") && !name.contains("chicken") {
            return .boxed(Color(red: 0.96, green: 0.60, blue: 0.16), "ORANGE")
        }
        if name.contains("apple") && !name.contains("bacon") {
            return .boxed(Color(red: 0.72, green: 0.18, blue: 0.16), "APPLE")
        }
        if name.contains("banana") {
            return .boxed(Color(red: 0.96, green: 0.88, blue: 0.32), "BANANA")
        }
        if name.contains("mushroom") {
            return .boxed(Color(red: 0.62, green: 0.50, blue: 0.38), "MUSHROOM")
        }
        if name.contains("broccoli") {
            return .leafyGreens("BROCCOLI")
        }
        if name.contains("pepper") {
            return .boxed(Color(red: 0.90, green: 0.30, blue: 0.12), "PEPPER")
        }
        if name.contains("kale") {
            return .leafyGreens("KALE")
        }
        if name.contains("lettuce") {
            return .leafyGreens("LETTUCE")
        }
        if name.contains("corn") && !name.contains("corner") {
            return .boxed(Color(red: 0.96, green: 0.82, blue: 0.22), "CORN")
        }
        if name.contains("butter") && !name.contains("peanut") && !name.contains("almond") {
            return .boxed(Color(red: 0.96, green: 0.90, blue: 0.60), "BUTTER")
        }
        if name.contains("cheese") {
            return .boxed(Color(red: 0.96, green: 0.82, blue: 0.22), "CHEESE")
        }
        if name.contains("hummus") {
            return .boxed(Color(red: 0.78, green: 0.68, blue: 0.48), "HUMMUS")
        }
        if name.contains("rice") && !name.contains("price") {
            return .boxed(Color(red: 0.92, green: 0.90, blue: 0.82), "RICE")
        }
        if name.contains("almond") {
            return .boxed(Color(red: 0.72, green: 0.56, blue: 0.36), "ALMOND")
        }
        if name.contains("kombucha") {
            return .liquid(Color(red: 0.76, green: 0.56, blue: 0.22), "BOOCH")
        }
        if name.contains("coconut") {
            return .liquid(Color(red: 0.92, green: 0.92, blue: 0.90), "COCO")
        }
        if name.contains("wine") || name.contains("charles shaw") {
            return .liquid(Color(red: 0.48, green: 0.12, blue: 0.18), "WINE")
        }
        if name.contains("soda") || name.contains("cola") || name.contains("sprite") {
            return .liquid(Color(red: 0.71, green: 0.15, blue: 0.15), "SODA")
        }
        if name.contains("detergent") || name.contains("laundry pod") {
            return .liquid(Color(red: 0.79, green: 0.90, blue: 1.0), "ULTRA")
        }
        if name.contains("dish soap") {
            return .liquid(Color(red: 0.50, green: 0.82, blue: 0.56), "DISH")
        }
        if name.contains("muffin") || name.contains("scone") {
            return .bakery(Color(red: 0.82, green: 0.60, blue: 0.28), "MUFFIN")
        }
        if name.contains("donut") || name.contains("danish") {
            return .bakery(Color(red: 0.88, green: 0.72, blue: 0.38), "PASTRY")
        }
        if name.contains("roll") && !name.contains("toilet") {
            return .bakery(Color(red: 0.78, green: 0.58, blue: 0.28), "ROLLS")
        }
        if name.contains("tortilla") || name.contains("crumpet") {
            return .bakery(Color(red: 0.90, green: 0.82, blue: 0.60), "FLAT")
        }
        if name.contains("baguette") || name.contains("sourdough") || name.contains("ciabatta") || name.contains("rye") {
            return .breadLoaf
        }
        if name.contains("cake") {
            return .bakery(Color(red: 0.86, green: 0.80, blue: 0.73), "CAKE")
        }
        if name.contains("ramen") || name.contains("noodle") {
            return .boxed(Color(red: 0.90, green: 0.72, blue: 0.22), "RAMEN")
        }
        if name.contains("nut") && !name.contains("donut") {
            return .boxed(Color(red: 0.62, green: 0.44, blue: 0.24), "NUTS")
        }
        if name.contains("cracker") {
            return .boxed(Color(red: 0.92, green: 0.78, blue: 0.42), "CRACKER")
        }
        if name.contains("candy") || name.contains("m&m") {
            return .boxed(Color(red: 0.80, green: 0.26, blue: 0.22), "CANDY")
        }
        if name.contains("sunscreen") {
            return .boxed(Color(red: 0.96, green: 0.82, blue: 0.22), "SPF")
        }
        if name.contains("bleach") {
            return .liquid(Color(red: 0.90, green: 0.92, blue: 0.98), "BLEACH")
        }
        if name.contains("cat") && !name.contains("catch") {
            return .boxed(Color(red: 0.60, green: 0.48, blue: 0.76), "CAT")
        }
        if name.contains("leash") || name.contains("collar") {
            return .boxed(Color(red: 0.22, green: 0.48, blue: 0.68), "PET")
        }
        if name.contains("bed") && name.contains("dog") {
            return .boxed(Color(red: 0.56, green: 0.42, blue: 0.32), "BED")
        }
        if name.contains("fish") && (name.contains("flake") || name.contains("food")) {
            return .boxed(Color(red: 0.22, green: 0.56, blue: 0.78), "FISH")
        }
        if name.contains("bird") || name.contains("parakeet") || name.contains("seed mix") {
            return .boxed(Color(red: 0.42, green: 0.68, blue: 0.36), "BIRD")
        }
        if name.contains("lemonade") {
            return .liquid(Color(red: 0.96, green: 0.88, blue: 0.28), "LEMON")
        }
        if name.contains("smoothie") {
            return .liquid(Color(red: 0.42, green: 0.78, blue: 0.36), "SMOOTH")
        }
        if name.contains("energy") || name.contains("red bull") {
            return .liquid(Color(red: 0.22, green: 0.36, blue: 0.68), "ENERGY")
        }
        if name.contains("quesadilla") {
            return .boxed(Color(red: 0.92, green: 0.78, blue: 0.38), "QUESA")
        }
        if name.contains("taco") {
            return .boxed(Color(red: 0.88, green: 0.62, blue: 0.22), "TACO")
        }
        if name.contains("guacamole") || name.contains("guac") {
            return .boxed(Color(red: 0.36, green: 0.62, blue: 0.22), "GUAC")
        }
        if name.contains("canvas") {
            return .boxed(Color(red: 0.92, green: 0.90, blue: 0.86), "CANVAS")
        }
        if name.contains("brush") {
            return .boxed(Color(red: 0.56, green: 0.42, blue: 0.82), "BRUSH")
        }
        if name.contains("marker") {
            return .boxed(Color(red: 0.32, green: 0.56, blue: 0.82), "MARKER")
        }
        if name.contains("bead") {
            return .boxed(Color(red: 0.78, green: 0.56, blue: 0.88), "BEADS")
        }
        if name.contains("ribbon") {
            return .boxed(Color(red: 0.82, green: 0.32, blue: 0.56), "RIBBON")
        }
        if name.contains("tape") {
            return .boxed(Color(red: 0.22, green: 0.68, blue: 0.42), "TAPE")
        }
        if name.contains("nail") {
            return .boxed(Color(red: 0.56, green: 0.58, blue: 0.62), "NAILS")
        }
        if name.contains("hose") {
            return .boxed(Color(red: 0.22, green: 0.62, blue: 0.32), "HOSE")
        }
        if name.contains("mulch") || name.contains("soil") || name.contains("potting") {
            return .boxed(Color(red: 0.42, green: 0.32, blue: 0.18), "SOIL")
        }
        if name.contains("gelato") {
            return .boxed(Color(red: 0.72, green: 0.88, blue: 0.62), "GELATO")
        }
        if name.contains("sponge") {
            return .boxed(Color(red: 0.42, green: 0.78, blue: 0.56), "SPONGE")
        }
        if name.contains("peanut butter") {
            return .boxed(Color(red: 0.72, green: 0.52, blue: 0.22), "PB")
        }
        if name.contains("bean") {
            return .boxed(Color(red: 0.56, green: 0.34, blue: 0.18), "BEANS")
        }
        if name.contains("mac") && name.contains("cheese") {
            return .boxed(Color(red: 0.92, green: 0.72, blue: 0.22), "MAC")
        }
        if name.contains("alfredo") || name.contains("frozen meal") {
            return .boxed(Color(red: 0.68, green: 0.56, blue: 0.38), "MEAL")
        }
        if name.contains("oreo") || name.contains("sandwich cookie") {
            return .boxed(Color(red: 0.14, green: 0.14, blue: 0.16), "OREO")
        }
        if name.contains("pepper") && name.contains("dr") {
            return .liquid(Color(red: 0.50, green: 0.12, blue: 0.14), "DRPPR")
        }
        if name.contains("mountain dew") || name.contains("dew") {
            return .liquid(Color(red: 0.48, green: 0.82, blue: 0.22), "DEW")
        }
        if name.contains("gatorade") {
            return .liquid(Color(red: 0.22, green: 0.68, blue: 0.38), "GATOR")
        }
        return .generic(Color(red: 0.22, green: 0.53, blue: 0.90), product.brand.uppercased())
    }

    private var packageLabel: String {
        let name = product.productName.lowercased()
        if name.contains("toilet") {
            return "BATH"
        }
        if name.contains("paper towel") {
            return "TOWEL"
        }
        return product.brand.uppercased()
    }

    private var salmonFreshArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let isCompact = w < 140
            let filletW1 = isCompact ? w * 0.85 : 160.0
            let filletW2 = isCompact ? w * 0.9 : 175.0
            let filletH: CGFloat = isCompact ? h * 0.35 : 64
            let stripeW1 = isCompact ? w * 0.7 : 130.0
            let stripeW2 = isCompact ? w * 0.75 : 145.0
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.97, green: 0.45, blue: 0.20))
                    .frame(width: filletW1, height: filletH)
                    .rotationEffect(.degrees(-6))
                    .offset(x: isCompact ? 0 : -8, y: -h * 0.18)
                    .overlay(
                        VStack(spacing: 6) {
                            ForEach(0..<5, id: \.self) { _ in
                                Capsule()
                                    .fill(Color.white.opacity(0.24))
                                    .frame(width: stripeW1, height: 2)
                            }
                        }
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.97, green: 0.45, blue: 0.20))
                    .frame(width: filletW2, height: filletH)
                    .rotationEffect(.degrees(5))
                    .offset(x: isCompact ? 0 : 10, y: h * 0.2)
                    .overlay(
                        VStack(spacing: 6) {
                            ForEach(0..<5, id: \.self) { _ in
                                Capsule()
                                    .fill(Color.white.opacity(0.24))
                                    .frame(width: stripeW2, height: 2)
                            }
                        }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var frozenSalmonArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 80
            ZStack {
                Color(red: 0.12, green: 0.45, blue: 0.82)
                VStack(spacing: isCompact ? 2 : 8) {
                    if !isCompact {
                        Text("Farm Raised")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text(isCompact ? "SALMON" : "ATLANTIC\nSALMON")
                        .font(.system(size: isCompact ? max(9, w * 0.22) : 18, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(isCompact ? 1 : 2)
                        .minimumScaleFactor(0.5)
                    RoundedRectangle(cornerRadius: isCompact ? 8 : 18, style: .continuous)
                        .fill(Color(red: 0.97, green: 0.63, blue: 0.47))
                        .frame(height: isCompact ? w * 0.35 : 44)
                        .padding(.horizontal, isCompact ? 4 : 14)
                }
                .padding(isCompact ? 4 : 10)
            }
        }
    }

    private func fruitBowlArt(color: Color, accent: Color) -> some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 140
            let dotSize: CGFloat = isCompact ? max(10, w * 0.12) : 24
            let dotCount = isCompact ? 4 : 6
            let rowCount = isCompact ? 3 : 4
            ZStack {
                Ellipse()
                    .fill(Color(red: 0.96, green: 0.95, blue: 0.92))
                    .frame(width: min(w * 0.9, 180), height: isCompact ? w * 0.25 : 62)
                    .offset(y: isCompact ? w * 0.25 : 46)

                HStack(spacing: 0) {
                    ForEach(0..<dotCount, id: \.self) { row in
                        VStack(spacing: -2) {
                            ForEach(0..<rowCount, id: \.self) { column in
                                Circle()
                                    .fill((row + column).isMultiple(of: 2) ? color : accent)
                                    .frame(width: dotSize, height: dotSize)
                            }
                        }
                        .offset(y: row.isMultiple(of: 2) ? -8 : 2)
                    }
                }
                .offset(y: 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var avocadoArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 140
            let avoW: CGFloat = isCompact ? w * 0.25 : 54
            let avoH: CGFloat = isCompact ? w * 0.36 : 78
            let innerW: CGFloat = isCompact ? w * 0.17 : 38
            let innerH: CGFloat = isCompact ? w * 0.26 : 58
            let count = isCompact ? 2 : 3
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.96, green: 0.98, blue: 0.93))
                    .padding(isCompact ? 8 : 16)

                HStack(spacing: isCompact ? 8 : 16) {
                    ForEach(0..<count, id: \.self) { index in
                        ZStack {
                            Ellipse()
                                .fill(Color(red: 0.18, green: 0.43, blue: 0.17))
                                .frame(width: avoW, height: avoH)
                            Ellipse()
                                .fill(Color(red: 0.78, green: 0.90, blue: 0.44))
                                .frame(width: innerW, height: innerH)
                            if index != count - 1 {
                                Circle()
                                    .fill(Color(red: 0.55, green: 0.35, blue: 0.19))
                                    .frame(width: isCompact ? 8 : 15, height: isCompact ? 8 : 15)
                                    .offset(y: 6)
                            }
                        }
                        .rotationEffect(.degrees(index == 1 ? -8 : 10))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var breadLoafArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 140
            let loafW: CGFloat = isCompact ? w * 0.8 : 146
            let loafH: CGFloat = isCompact ? w * 0.44 : 78
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: loafW, height: isCompact ? w * 0.14 : 28)
                    .offset(y: isCompact ? loafH * 0.4 : 34)

                RoundedRectangle(cornerRadius: isCompact ? 16 : 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.78, green: 0.55, blue: 0.28),
                                Color(red: 0.62, green: 0.40, blue: 0.19)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: loafW, height: loafH)
                    .overlay(
                        HStack(spacing: isCompact ? 10 : 18) {
                            ForEach(0..<3, id: \.self) { _ in
                                Capsule()
                                    .fill(Color(red: 0.90, green: 0.76, blue: 0.50).opacity(0.65))
                                    .frame(width: isCompact ? 4 : 6, height: isCompact ? loafH * 0.5 : 42)
                                    .rotationEffect(.degrees(18))
                            }
                        }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var soupBowlArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 140
            let bowlW: CGFloat = isCompact ? w * 0.8 : 154
            let bowlH: CGFloat = isCompact ? w * 0.38 : 70
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: bowlW, height: isCompact ? w * 0.12 : 26)
                    .offset(y: isCompact ? bowlH * 0.4 : 34)

                ZStack {
                    Ellipse()
                        .fill(Color.white)
                        .frame(width: bowlW, height: bowlH)
                    Ellipse()
                        .fill(Color(red: 0.86, green: 0.58, blue: 0.22))
                        .frame(width: bowlW * 0.85, height: bowlH * 0.7)
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color(red: 0.96, green: 0.86, blue: 0.56))
                            .frame(width: isCompact ? 10 : 16, height: isCompact ? 10 : 16)
                            .offset(x: CGFloat(index * (isCompact ? 18 : 28) - (isCompact ? 18 : 28)), y: CGFloat(index.isMultiple(of: 2) ? -4 : 6))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sandwichPlateArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 140
            let plateW: CGFloat = isCompact ? w * 0.85 : 160
            let plateH: CGFloat = isCompact ? w * 0.6 : 110
            let halfW: CGFloat = isCompact ? w * 0.28 : 56
            let halfH: CGFloat = isCompact ? w * 0.3 : 58
            ZStack {
                RoundedRectangle(cornerRadius: isCompact ? 14 : 22, style: .continuous)
                    .fill(Color(red: 0.97, green: 0.96, blue: 0.93))
                    .frame(width: plateW, height: plateH)

                HStack(spacing: 2) {
                    sandwichHalf(rotation: -8, halfW: halfW, halfH: halfH)
                    sandwichHalf(rotation: 10, halfW: halfW, halfH: halfH)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func sandwichHalf(rotation: Double, halfW: CGFloat = 56, halfH: CGFloat = 58) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.86, green: 0.69, blue: 0.43))
                .frame(width: halfW, height: halfH)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.43, green: 0.71, blue: 0.31))
                .frame(width: halfW * 0.93, height: halfH * 0.17)
                .offset(y: 6)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.90, green: 0.82, blue: 0.44))
                .frame(width: halfW * 0.96, height: halfH * 0.14)
                .offset(y: -2)
        }
        .rotationEffect(.degrees(rotation))
    }

    private var rotisserieChickenArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 140
            let trayW: CGFloat = isCompact ? w * 0.85 : 164
            let trayH: CGFloat = isCompact ? w * 0.55 : 108
            let chickenW: CGFloat = isCompact ? w * 0.6 : 112
            let chickenH: CGFloat = isCompact ? w * 0.38 : 72
            ZStack {
                RoundedRectangle(cornerRadius: isCompact ? 12 : 20, style: .continuous)
                    .fill(Color(red: 0.20, green: 0.20, blue: 0.22).opacity(0.08))
                    .frame(width: trayW, height: trayH)

                Ellipse()
                    .fill(Color(red: 0.68, green: 0.38, blue: 0.15))
                    .frame(width: chickenW, height: chickenH)
                    .overlay(
                        Ellipse()
                            .stroke(Color(red: 0.84, green: 0.56, blue: 0.29), lineWidth: isCompact ? 3 : 5)
                            .frame(width: chickenW * 0.84, height: chickenH * 0.75)
                    )
                Circle()
                    .fill(Color(red: 0.95, green: 0.90, blue: 0.78))
                    .frame(width: isCompact ? 8 : 12, height: isCompact ? 8 : 12)
                    .offset(x: chickenW * 0.4, y: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func greensBagArt(title: String) -> some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 80
            let iconSize = isCompact ? max(12, w * 0.3) : 30.0
            let textSize = isCompact ? max(9, w * 0.22) : 18.0
            ZStack {
                Color(red: 0.64, green: 0.87, blue: 0.34)
                VStack(spacing: isCompact ? 2 : 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(Color.instacartGreenDark)
                    Text(title)
                        .font(.system(size: textSize, weight: .heavy))
                        .foregroundStyle(Color.instacartGreenDark)
                        .minimumScaleFactor(0.5)
                }
            }
        }
    }

    private var tissueCubeArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 80
            ZStack {
                Color(red: 0.84, green: 0.90, blue: 0.98)

                if !isCompact {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 52, height: 22)
                        .offset(y: -10)

                    Capsule()
                        .fill(Color.white)
                        .frame(width: 34, height: 46)
                        .offset(y: -26)
                } else {
                    Capsule()
                        .fill(Color.white)
                        .frame(width: w * 0.4, height: w * 0.5)
                        .offset(y: -w * 0.15)
                }

                VStack {
                    Spacer()
                    Text("TISSUE")
                        .font(.system(size: isCompact ? max(8, w * 0.2) : 17, weight: .heavy))
                        .foregroundStyle(Color(red: 0.24, green: 0.36, blue: 0.63))
                        .minimumScaleFactor(0.5)
                        .padding(.bottom, isCompact ? 4 : 14)
                }
            }
        }
    }

    private var croissantTrayArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 140
            let cW: CGFloat = isCompact ? w * 0.24 : 54
            let cH: CGFloat = isCompact ? w * 0.12 : 26
            let count = isCompact ? 2 : 3
            ZStack {
                RoundedRectangle(cornerRadius: isCompact ? 12 : 20, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.95, blue: 0.88))
                    .padding(isCompact ? 8 : 18)

                HStack(spacing: isCompact ? 6 : 12) {
                    ForEach(0..<count, id: \.self) { index in
                        ZStack {
                            Capsule()
                                .fill(Color(red: 0.83, green: 0.57, blue: 0.24))
                                .frame(width: cW, height: cH)
                                .rotationEffect(.degrees(index == 1 ? -18 : 16))
                            Capsule()
                                .fill(Color(red: 0.94, green: 0.77, blue: 0.39))
                                .frame(width: cW * 0.74, height: cH * 0.62)
                                .rotationEffect(.degrees(index == 1 ? -18 : 16))
                        }
                    }
                }
                .offset(y: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sparklingCanArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 80
            let canCount = isCompact ? 3 : 4
            let canWidth: CGFloat = isCompact ? w * 0.2 : 24
            let canHeight: CGFloat = isCompact ? w * 0.65 : 76
            ZStack {
                HStack(spacing: isCompact ? 3 : 10) {
                    ForEach(0..<canCount, id: \.self) { index in
                        RoundedRectangle(cornerRadius: isCompact ? 4 : 10, style: .continuous)
                            .fill(index.isMultiple(of: 2) ? Color(red: 0.24, green: 0.73, blue: 0.95) : Color(red: 0.95, green: 0.42, blue: 0.58))
                            .frame(width: canWidth, height: canHeight)
                            .overlay(
                                Capsule()
                                    .fill(Color.white.opacity(0.82))
                                    .frame(width: isCompact ? 2 : 4, height: canHeight * 0.6)
                            )
                    }
                }

                VStack {
                    Spacer()
                    Text("SPARKLING")
                        .font(.system(size: isCompact ? max(7, w * 0.16) : 15, weight: .heavy))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .padding(.bottom, isCompact ? 2 : 10)
                }
            }
        }
    }

    private var yogurtPackArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 80
            let cupCount = isCompact ? 2 : 3
            let cupWidth: CGFloat = isCompact ? w * 0.3 : 42
            let lidWidth: CGFloat = isCompact ? w * 0.26 : 38
            ZStack {
                HStack(spacing: isCompact ? 4 : 12) {
                    ForEach(0..<cupCount, id: \.self) { index in
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: isCompact ? 4 : 8, style: .continuous)
                                .fill(index.isMultiple(of: 2) ? Color(red: 0.30, green: 0.58, blue: 0.97) : Color(red: 0.26, green: 0.72, blue: 0.53))
                                .frame(width: lidWidth, height: isCompact ? 8 : 18)
                            RoundedRectangle(cornerRadius: isCompact ? 6 : 12, style: .continuous)
                                .fill(Color.white)
                                .frame(width: cupWidth, height: isCompact ? w * 0.4 : 48)
                        }
                    }
                }
                .padding(.bottom, isCompact ? 4 : 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var storageBinsArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 140
            let binW: CGFloat = isCompact ? w * 0.6 : 104
            let binH: CGFloat = isCompact ? w * 0.22 : 40
            ZStack {
                Color(red: 0.93, green: 0.95, blue: 0.98)
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: isCompact ? 10 : 16, style: .continuous)
                        .fill(Color(red: 0.85, green: 0.90, blue: 0.96).opacity(0.95))
                        .frame(width: binW, height: binH)
                        .overlay(
                            RoundedRectangle(cornerRadius: isCompact ? 10 : 16, style: .continuous)
                                .stroke(Color(red: 0.63, green: 0.71, blue: 0.84), lineWidth: 2)
                        )
                        .offset(x: CGFloat(index * (isCompact ? 8 : 12) - (isCompact ? 8 : 10)), y: CGFloat(index * (isCompact ? 12 : 18) - (isCompact ? 12 : 18)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var vitaminBottleArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 80
            ZStack {
                Color(red: 0.99, green: 0.90, blue: 0.32)
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: isCompact ? 4 : 8, style: .continuous)
                        .fill(Color(red: 0.89, green: 0.23, blue: 0.17))
                        .frame(width: isCompact ? w * 0.5 : 48, height: isCompact ? 8 : 18)
                        .padding(.top, isCompact ? 4 : 10)
                    Spacer()
                    RoundedRectangle(cornerRadius: isCompact ? 4 : 8, style: .continuous)
                        .fill(Color.white)
                        .frame(width: isCompact ? w * 0.6 : 60, height: isCompact ? 16 : 40)
                    Text("MULTI")
                        .font(.system(size: isCompact ? max(8, w * 0.2) : 15, weight: .heavy))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .padding(.bottom, isCompact ? 3 : 10)
                }
                .padding(.horizontal, isCompact ? 4 : 10)
            }
        }
    }

    private var toolCaseArt: some View {
        ZStack {
            Color(red: 0.17, green: 0.21, blue: 0.28)
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.31, green: 0.39, blue: 0.50))
                    .frame(width: 68, height: 12)
                Capsule()
                    .fill(Color(red: 0.95, green: 0.76, blue: 0.18))
                    .frame(width: 80, height: 10)
                HStack(spacing: 12) {
                    Image(systemName: "hammer.fill")
                    Image(systemName: "wrench.adjustable.fill")
                }
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))
            }
        }
    }

    private var paintCanArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 80
            ZStack {
                Color(red: 0.93, green: 0.95, blue: 0.98)

                VStack(spacing: 0) {
                    ArcHandle()
                        .stroke(Color.gray.opacity(0.7), lineWidth: isCompact ? 2 : 4)
                        .frame(width: isCompact ? w * 0.5 : 56, height: isCompact ? w * 0.25 : 28)

                    ZStack {
                        RoundedRectangle(cornerRadius: isCompact ? 6 : 12, style: .continuous)
                            .fill(Color(red: 0.74, green: 0.82, blue: 0.96))
                            .padding(.horizontal, isCompact ? w * 0.12 : 16)

                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(red: 0.26, green: 0.52, blue: 0.87))
                                .frame(height: isCompact ? 8 : 16)
                                .padding(.horizontal, isCompact ? w * 0.12 : 16)
                            Spacer()
                            RoundedRectangle(cornerRadius: isCompact ? 4 : 8, style: .continuous)
                                .fill(Color.white)
                                .frame(height: isCompact ? 14 : 30)
                                .padding(.horizontal, isCompact ? w * 0.2 : 24)
                                .padding(.bottom, isCompact ? 4 : 10)
                        }
                    }
                }
                .padding(.vertical, isCompact ? 4 : 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func packageArt(bodyColor: Color, title: String, titleColor: Color) -> some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let isCompact = w < 80
            let fontSize = isCompact ? max(9, w * 0.22) : 20.0
            let padH = isCompact ? max(2, w * 0.08) : 16.0
            ZStack {
                bodyColor
                if !isCompact {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.22))
                        .frame(width: w * 0.82, height: 18)
                        .offset(y: -h * 0.2)
                }
                Text(title)
                    .font(.system(size: fontSize, weight: .heavy))
                    .foregroundStyle(titleColor)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, padH)
            }
        }
    }

    private func bottlePackArt(color: Color, title: String) -> some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let isCompact = w < 80
            let bottleCount = isCompact ? 3 : 5
            let bottleWidth: CGFloat = isCompact ? 10 : 22
            let bottleSpacing: CGFloat = isCompact ? 3 : 8
            let capWidth: CGFloat = isCompact ? 5 : 10
            let capHeight: CGFloat = isCompact ? 4 : 8
            let fontSize = isCompact ? max(9, w * 0.22) : 15.0
            ZStack {
                color.opacity(0.15)
                HStack(spacing: bottleSpacing) {
                    ForEach(0..<bottleCount, id: \.self) { _ in
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                                .frame(width: capWidth, height: capHeight)
                            RoundedRectangle(cornerRadius: isCompact ? 4 : 8, style: .continuous)
                                .fill(color)
                                .frame(width: bottleWidth, height: h * 0.48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: isCompact ? 3 : 6, style: .continuous)
                                        .fill(Color.white.opacity(0.42))
                                        .frame(width: bottleWidth * 0.55, height: h * 0.2)
                                        .offset(y: isCompact ? 4 : 8)
                                )
                        }
                    }
                }
                VStack {
                    Spacer()
                    Text(title)
                        .font(.system(size: fontSize, weight: .heavy))
                        .foregroundStyle(title == "MILK" ? Color.primary : Color.white)
                        .minimumScaleFactor(0.5)
                        .padding(.bottom, isCompact ? 4 : 10)
                }
            }
        }
    }

    private var dogFoodArt: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let isCompact = w < 80
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.80, green: 0.07, blue: 0.34),
                        Color(red: 0.58, green: 0.05, blue: 0.24)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(spacing: isCompact ? 3 : 8) {
                    Text("DOG FOOD")
                        .font(.system(size: isCompact ? max(8, w * 0.2) : 16, weight: .heavy))
                        .foregroundStyle(.yellow)
                        .minimumScaleFactor(0.5)
                    if !isCompact {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.16))
                            .frame(width: 72, height: 8)
                    }
                    Circle()
                        .fill(Color(red: 0.91, green: 0.71, blue: 0.39))
                        .frame(width: isCompact ? w * 0.5 : 46, height: isCompact ? w * 0.5 : 46)
                        .overlay(
                            VStack(spacing: isCompact ? 1 : 2) {
                                Circle().fill(.black).frame(width: isCompact ? 2 : 4, height: isCompact ? 2 : 4)
                                Circle().fill(.black).frame(width: isCompact ? 2 : 4, height: isCompact ? 2 : 4)
                                Capsule().fill(.black).frame(width: isCompact ? 8 : 16, height: isCompact ? 3 : 6)
                            }
                        )
                }
            }
        }
    }
}

private struct ArcHandle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2.5,
            startAngle: .degrees(200),
            endAngle: .degrees(340),
            clockwise: false
        )
        return path
    }
}

struct OrderStatusChipView: View {
    let status: OrderStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(chipColor.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(chipColor.background))
            .accessibilityIdentifier(AccessibilityID.orderStatusChip(status))
    }

    private var chipColor: (foreground: Color, background: Color) {
        switch status {
        case .scheduled:
            return (.orange, Color.orange.opacity(0.14))
        case .placed, .shopperAssigned, .shopping:
            return (.instacartGreenDark, Color.instacartGreen.opacity(0.16))
        case .outForDelivery, .readyForPickup:
            return (.blue, Color.blue.opacity(0.14))
        case .delivered, .pickedUp:
            return (.secondary, Color.gray.opacity(0.12))
        case .canceled:
            return (.red, Color.red.opacity(0.14))
        }
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String
    let accessibilityIdentifier: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "basket")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
