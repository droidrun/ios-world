import Foundation

enum Formatters {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func currency(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? String(format: "$%.2f", amount)
    }

    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    static func detailDate(_ date: Date) -> String {
        detailDateFormatter.string(from: date)
    }

    static func rating(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    static func reviewCount(_ value: Int) -> String {
        if value >= 10_000 {
            return String(format: "%.1fk", Double(value) / 1_000.0)
        }
        return "\(value)"
    }

    static func variantSummary(_ values: [String: String]) -> String {
        values.keys.sorted().compactMap { key in
            guard let value = values[key] else { return nil }
            return "\(key): \(value)"
        }.joined(separator: " • ")
    }
}
