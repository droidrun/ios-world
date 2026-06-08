import Foundation

enum Formatters {
    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func price(_ value: Double) -> String {
        priceFormatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    static func priceDisplay(price basePrice: Double, fees: Double, showFeesUpfront: Bool) -> String {
        let total = showFeesUpfront ? basePrice + fees : basePrice
        return Formatters.price(total)
    }

    static func feeDetail(fees: Double) -> String {
        "Fees \(Formatters.price(fees))"
    }

    static func compactMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func browseHeaderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    static func seatGeekEventSubtitle(_ date: Date, venue: String) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Tonight · \(venue)"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE M/d"
        return "\(formatter.string(from: date)) · \(venue)"
    }

    static func seatGeekListDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d · h:mm a"
        return formatter.string(from: date)
    }

    static func ticketArchiveDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy · h:mm a"
        return formatter.string(from: date)
    }

    static func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    static func eventDate(_ date: Date, use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        if use24Hour {
            formatter.dateFormat = "MMM d, yyyy HH:mm"
        }
        return formatter.string(from: date)
    }

    static func timeOnly(_ date: Date, use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        if use24Hour {
            formatter.dateFormat = "HH:mm"
        }
        return formatter.string(from: date)
    }
}
