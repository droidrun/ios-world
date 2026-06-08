import Foundation

enum DateFormatting {
    static let apiDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let gameTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Handles ISO 8601 dates with or without seconds (the source omits seconds, e.g. "2025-10-22T02:00Z").
    static let iso8601NoSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mmX"
        return formatter
    }()

    static func parseISO(_ value: String) -> Date? {
        if let withFractional = iso8601WithFractional.date(from: value) {
            return withFractional
        }
        if let standard = iso8601.date(from: value) {
            return standard
        }
        return iso8601NoSeconds.date(from: value)
    }

    static func date(from string: String) -> Date {
        guard let parsed = parseISO(string) else {
            print("[DateFormatting] Invalid static ISO date: \(string)")
            return Date()
        }
        return parsed
    }
}
