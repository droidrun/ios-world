import Foundation
import SwiftUI

enum AppFormatters {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = .current
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = .current
        return formatter
    }()

    private static let fullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        formatter.timeZone = .current
        return formatter
    }()

    static func date(_ value: Date) -> String {
        dateFormatter.string(from: value)
    }

    static func time(_ value: Date) -> String {
        timeFormatter.string(from: value)
    }

    static func full(_ value: Date) -> String {
        fullFormatter.string(from: value)
    }

    static func duration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }

    static func currency(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: value)) ?? "\(code) \(value)"
    }
}

enum StatusBadgeStyle {
    static func color(for status: FlightOperationalStatus) -> Color {
        switch status {
        case .onTime:
            return Color(red: 225 / 255, green: 244 / 255, blue: 234 / 255)
        case .boarding:
            return Color(red: 225 / 255, green: 236 / 255, blue: 252 / 255)
        case .delayed:
            return Color(red: 254 / 255, green: 242 / 255, blue: 224 / 255)
        case .departed:
            return Color(red: 237 / 255, green: 238 / 255, blue: 242 / 255)
        }
    }

    static func textColor(for status: FlightOperationalStatus) -> Color {
        switch status {
        case .onTime:
            return Color(red: 16 / 255, green: 118 / 255, blue: 62 / 255)
        case .boarding:
            return SkyTripTheme.navy
        case .delayed:
            return Color(red: 168 / 255, green: 95 / 255, blue: 0 / 255)
        case .departed:
            return Color(red: 84 / 255, green: 88 / 255, blue: 100 / 255)
        }
    }
}

enum SkyTripTheme {
    static let navy = Color(red: 0 / 255, green: 23 / 255, blue: 61 / 255)
    static let navyLight = Color(red: 31 / 255, green: 55 / 255, blue: 102 / 255)
    static let red = Color(red: 224 / 255, green: 30 / 255, blue: 63 / 255)
    static let surface = Color(red: 243 / 255, green: 245 / 255, blue: 249 / 255)
    static let card = Color.white
    static let textPrimary = Color(red: 11 / 255, green: 25 / 255, blue: 52 / 255)
    static let textSecondary = Color(red: 78 / 255, green: 90 / 255, blue: 116 / 255)

    static func alertChipColor(for severity: AlertSeverity) -> Color {
        switch severity {
        case .info:
            return Color(red: 226 / 255, green: 237 / 255, blue: 254 / 255)
        case .caution:
            return Color(red: 254 / 255, green: 242 / 255, blue: 224 / 255)
        case .warning:
            return Color(red: 255 / 255, green: 232 / 255, blue: 232 / 255)
        }
    }

    static func alertTextColor(for severity: AlertSeverity) -> Color {
        switch severity {
        case .info:
            return navy
        case .caution:
            return Color(red: 168 / 255, green: 95 / 255, blue: 0 / 255)
        case .warning:
            return Color(red: 157 / 255, green: 31 / 255, blue: 31 / 255)
        }
    }
}
