import Foundation
import SwiftUI

enum DateFormatters {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let dateAndTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let weekdayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    static let timestampID: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let monthDayYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

enum AppFormat {
    static func partySizeLabel(_ size: Int) -> String {
        size == 1 ? "1 guest" : "\(size) guests"
    }

    static func priceTierLabel(_ tier: Int) -> String {
        String(repeating: "$", count: max(1, min(tier, 4)))
    }

    static func priceRangeLabel(for tier: Int) -> String {
        switch max(1, min(tier, 4)) {
        case 1:
            return "$1 to $15"
        case 2:
            return "$16 to $30"
        case 3:
            return "$31 to $50"
        default:
            return "$50+"
        }
    }

    static func reservationStatusTitle(_ status: ReservationStatus) -> String {
        switch status {
        case .upcoming:
            return "Upcoming"
        case .past:
            return "Past"
        case .canceled:
            return "Canceled"
        }
    }

    static func reservationStatusColor(_ status: ReservationStatus) -> Color {
        switch status {
        case .upcoming:
            return .green
        case .past:
            return .gray
        case .canceled:
            return .red
        }
    }

    static func accessibilitySlug(_ value: String) -> String {
        let lowered = value.lowercased()
        let allowed = lowered.map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            return "_"
        }
        let compact = String(allowed)
            .replacingOccurrences(of: "__", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return compact
    }

    static func distanceLabel(miles: Double) -> String {
        return String(format: "%.1f mi", miles)
    }

    static func reviewCount(for restaurantID: String) -> Int {
        let digits = Int(restaurantID.split(separator: "_").last ?? "0") ?? 0
        return 920 + (digits * 37)
    }

    static func starSymbols(for rating: Double) -> String {
        let rounded = Int((rating * 2.0).rounded())
        let fullStars = rounded / 2
        let halfStar = rounded % 2 == 1
        var output = String(repeating: "★", count: max(0, min(5, fullStars)))
        if halfStar && output.count < 5 {
            output += "☆"
        }
        if output.count < 5 {
            output += String(repeating: "✩", count: 5 - output.count)
        }
        return output
    }

    static func colorFromHex(_ hex: String) -> Color {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") {
            value.removeFirst()
        }

        guard value.count == 6, let rgb = Int(value, radix: 16) else {
            return Color.gray
        }

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
}

extension Date {
    func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Menu item visual appearance

/// Maps a menu item name to an SF Symbol and a tint colour so that menu cards
/// get a food-category thumbnail consistent with the DiningTheme palette.
struct MenuItemAppearance {
    let symbol: String
    let tint: Color
    /// Rough price estimate used to decorate cards when the restaurant does not
    /// carry per-item prices.  The value is only a display hint (e.g. "$24").
    let estimatedPrice: String
    /// Course category label displayed as a badge on the card.
    let courseLabel: String

    // swiftlint:disable function_body_length
    static func lookup(name: String) -> MenuItemAppearance {
        let hay = name.lowercased()

        // ── desserts ──────────────────────────────────────────────────────────
        if hay.contains("cake") || hay.contains("tart") || hay.contains("mille-feuille")
            || hay.contains("tiramisu") || hay.contains("brûlée") || hay.contains("brulee")
            || hay.contains("panna cotta") || hay.contains("paris-brest")
            || hay.contains("vol-au-vent") || hay.contains("semifreddo")
            || hay.contains("gelato") || hay.contains("sorbet") || hay.contains("mousse")
            || hay.contains("pudding") || hay.contains("flan") || hay.contains("custard")
            || hay.contains("pie") || hay.contains("cheesecake") || hay.contains("brownie")
            || hay.contains("churro") || hay.contains("mochi") || hay.contains("cannoli")
            || hay.contains("sundae") || hay.contains("bun") || hay.contains("doughnut")
            || hay.contains("granita") || hay.contains("éclair") || hay.contains("macaron")
            || hay.contains("pancake") || hay.contains("pecan tart") {
            return MenuItemAppearance(
                symbol: "birthday.cake.fill",
                tint: Color(red: 0.88, green: 0.42, blue: 0.58),
                estimatedPrice: "$16",
                courseLabel: "Dessert"
            )
        }

        // ── seafood & shellfish ───────────────────────────────────────────────
        if hay.contains("oyster") || hay.contains("lobster") || hay.contains("crab")
            || hay.contains("scallop") || hay.contains("shrimp") || hay.contains("prawn")
            || hay.contains("clam") || hay.contains("calamari") || hay.contains("octopus")
            || hay.contains("cioppino") || hay.contains("chowder") || hay.contains("crudo")
            || hay.contains("halibut") || hay.contains("branzino") || hay.contains("cod")
            || hay.contains("salmon") || hay.contains("tuna") || hay.contains("mahi")
            || hay.contains("swordfish") || hay.contains("trout") || hay.contains("anchov")
            || hay.contains("sardine") {
            return MenuItemAppearance(
                symbol: "fish.fill",
                tint: Color(red: 0.25, green: 0.55, blue: 0.82),
                estimatedPrice: "$38",
                courseLabel: "Seafood"
            )
        }

        // ── sushi / nigiri ────────────────────────────────────────────────────
        if hay.contains("nigiri") || hay.contains("sashimi") || hay.contains("maki")
            || hay.contains("uni") || hay.contains("toro") || hay.contains("otoro")
            || hay.contains("hand roll") || hay.contains("poke") {
            return MenuItemAppearance(
                symbol: "fish.fill",
                tint: Color(red: 0.52, green: 0.25, blue: 0.50),
                estimatedPrice: "$32",
                courseLabel: "Sushi"
            )
        }

        // ── beef & steak ──────────────────────────────────────────────────────
        if hay.contains("steak") || hay.contains("ribeye") || hay.contains("rib eye")
            || hay.contains("prime rib") || hay.contains("prime strip") || hay.contains("brisket")
            || hay.contains("wagyu") || hay.contains("porterhouse") || hay.contains("strip")
            || hay.contains("beef") || hay.contains("bone-in") || hay.contains("short rib") {
            return MenuItemAppearance(
                symbol: "flame.fill",
                tint: Color(red: 0.72, green: 0.20, blue: 0.18),
                estimatedPrice: "$52",
                courseLabel: "Main"
            )
        }

        // ── duck & poultry ────────────────────────────────────────────────────
        if hay.contains("duck") || hay.contains("chicken") || hay.contains("quail")
            || hay.contains("poultry") || hay.contains("turkey") || hay.contains("yakitori") {
            return MenuItemAppearance(
                symbol: "bird.fill",
                tint: Color(red: 0.75, green: 0.42, blue: 0.15),
                estimatedPrice: "$38",
                courseLabel: "Main"
            )
        }

        // ── pasta ─────────────────────────────────────────────────────────────
        if hay.contains("pasta") || hay.contains("tagliolini") || hay.contains("tagliatelle")
            || hay.contains("rigatoni") || hay.contains("spaghetti") || hay.contains("linguine")
            || hay.contains("mafaldini") || hay.contains("fettuccine") || hay.contains("agnolotti")
            || hay.contains("ravioli") || hay.contains("lasagna") || hay.contains("gnocchi")
            || hay.contains("cacio e pepe") || hay.contains("carbonara") || hay.contains("noodle") {
            return MenuItemAppearance(
                symbol: "tornado",
                tint: Color(red: 0.85, green: 0.52, blue: 0.18),
                estimatedPrice: "$28",
                courseLabel: "Pasta"
            )
        }

        // ── vegetable / salad / plant ─────────────────────────────────────────
        if hay.contains("salad") || hay.contains("eggplant") || hay.contains("carrot")
            || hay.contains("broccoli") || hay.contains("artichoke") || hay.contains("mushroom")
            || hay.contains("vegetable") || hay.contains("veggie") || hay.contains("tofu")
            || hay.contains("greens") || hay.contains("kale") || hay.contains("arugula")
            || hay.contains("tartine") || hay.contains("toast") || hay.contains("grain") {
            return MenuItemAppearance(
                symbol: "leaf.fill",
                tint: Color(red: 0.28, green: 0.62, blue: 0.35),
                estimatedPrice: "$18",
                courseLabel: "Vegetable"
            )
        }

        // ── cheese / burrata / ricotta ────────────────────────────────────────
        if hay.contains("burrata") || hay.contains("mozzarella") || hay.contains("ricotta")
            || hay.contains("cheese") || hay.contains("feta") || hay.contains("parmesan") {
            return MenuItemAppearance(
                symbol: "square.fill",
                tint: Color(red: 0.92, green: 0.82, blue: 0.38),
                estimatedPrice: "$18",
                courseLabel: "Starter"
            )
        }

        // ── bread / dough ─────────────────────────────────────────────────────
        if hay.contains("bread") || hay.contains("sourdough") || hay.contains("focaccia")
            || hay.contains("baguette") || hay.contains("naan") || hay.contains("knish")
            || hay.contains("garlic bread") {
            return MenuItemAppearance(
                symbol: "rectangle.fill",
                tint: Color(red: 0.78, green: 0.58, blue: 0.32),
                estimatedPrice: "$12",
                courseLabel: "Bread"
            )
        }

        // ── tacos / burritos / Mexican ────────────────────────────────────────
        if hay.contains("taco") || hay.contains("burrito") || hay.contains("quesadilla")
            || hay.contains("nacho") || hay.contains("pozole") || hay.contains("tamale")
            || hay.contains("ceviche") || hay.contains("tostada") || hay.contains("nopal") {
            return MenuItemAppearance(
                symbol: "rectangle.stack.fill",
                tint: Color(red: 0.85, green: 0.52, blue: 0.25),
                estimatedPrice: "$22",
                courseLabel: "Main"
            )
        }

        // ── soup & dumpling ───────────────────────────────────────────────────
        if hay.contains("soup") || hay.contains("broth") || hay.contains("ramen")
            || hay.contains("pho") || hay.contains("bisque") || hay.contains("miso")
            || hay.contains("dumpling") || hay.contains("bun") || hay.contains("gyoza")
            || hay.contains("chowder") || hay.contains("matzo") {
            return MenuItemAppearance(
                symbol: "cup.and.saucer.fill",
                tint: Color(red: 0.68, green: 0.38, blue: 0.18),
                estimatedPrice: "$18",
                courseLabel: "Soup"
            )
        }

        // ── drinks / coffee ───────────────────────────────────────────────────
        if hay.contains("coffee") || hay.contains("espresso") || hay.contains("affogato")
            || hay.contains("martini") || hay.contains("wine") || hay.contains("cocktail")
            || hay.contains("beer") || hay.contains("sake") || hay.contains("juice") {
            return MenuItemAppearance(
                symbol: "wineglass.fill",
                tint: Color(red: 0.50, green: 0.12, blue: 0.22),
                estimatedPrice: "$16",
                courseLabel: "Drink"
            )
        }

        // ── default ───────────────────────────────────────────────────────────
        return MenuItemAppearance(
            symbol: "fork.knife",
            tint: Color(red: 0.44, green: 0.46, blue: 0.50),
            estimatedPrice: "$28",
            courseLabel: "Main"
        )
    }
    // swiftlint:enable function_body_length
}

enum DiningTheme {
    // OTKit token: white (#FFFFFF)
    static let background = Color.white
    // OTKit token: ash-background (#F1F2F4)
    static let surface = Color(red: 241 / 255, green: 242 / 255, blue: 244 / 255)
    // White card surface
    static let elevatedSurface = Color.white
    // OTKit token: ash-lightest (#D8D9DB)
    static let border = Color(red: 216 / 255, green: 217 / 255, blue: 219 / 255)
    // OTKit token: ash-lighter (#91949A)
    static let chipBorder = Color(red: 145 / 255, green: 148 / 255, blue: 154 / 255)
    // OTKit token: ash (#2D333F)
    static let textPrimary = Color(red: 45 / 255, green: 51 / 255, blue: 63 / 255)
    // OTKit token: ash-light (#6F737B)
    static let textSecondary = Color(red: 111 / 255, green: 115 / 255, blue: 123 / 255)
    // OTKit token: red (#DA3743)
    static let slotRed = Color(red: 218 / 255, green: 55 / 255, blue: 67 / 255)
    // OTKit token: red (#DA3743)
    static let accentRed = Color(red: 218 / 255, green: 55 / 255, blue: 67 / 255)
    // OTKit token: ash-lighter (#91949A)
    static let muted = Color(red: 145 / 255, green: 148 / 255, blue: 154 / 255)
}
