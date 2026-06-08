import Foundation

enum AppFormatters {
    private static let milesPerKilometer = 0.621371
    private static let feetPerMeter = 3.28084

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    private static let shortMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let shortMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    static func distance(_ kilometers: Double) -> String {
        "\(decimal(kilometers * milesPerKilometer)) mi"
    }

    static func duration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    static func elevation(_ meters: Double) -> String {
        "\(integer(meters * feetPerMeter)) ft"
    }

    static func pace(secondsPerKilometer: Int) -> String {
        let secondsPerMile = Int((Double(secondsPerKilometer) * 1.60934).rounded())
        let minutes = secondsPerMile / 60
        let seconds = secondsPerMile % 60
        return String(format: "%d:%02d /mi", minutes, seconds)
    }

    static func speed(distanceKilometers: Double, durationSeconds: Int) -> String {
        guard durationSeconds > 0 else { return "0.0 mph" }
        let speed = (distanceKilometers * milesPerKilometer) / (Double(durationSeconds) / 3600)
        return "\(decimal(speed)) mph"
    }

    static func primaryPerformanceMetric(for activity: Activity) -> String {
        switch activity.activityType {
        case .ride, .indoorRide:
            return speed(distanceKilometers: activity.distanceKilometers, durationSeconds: activity.durationSeconds)
        case .run, .walk, .hike:
            return pace(secondsPerKilometer: activity.avgPaceSecondsPerKilometer)
        }
    }

    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    static func fullDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func monthYear(_ date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    static func monthAbbreviation(_ date: Date) -> String {
        shortMonthFormatter.string(from: date).uppercased()
    }

    static func monthDateRange(for date: Date) -> String {
        let calendar = Calendar.current
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: date),
            let lastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end)
        else {
            return monthYear(date)
        }

        return "\(shortMonthDayFormatter.string(from: monthInterval.start)) to \(shortMonthDayFormatter.string(from: lastDay)), \(yearFormatter.string(from: date))"
    }

    static func percent(progress: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return "\(integer((progress / total) * 100))%"
    }

    static func integer(_ value: Double) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func integer(_ value: Int) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func decimal(_ value: Double) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? "0.0"
    }

    static func durationMinutes(_ seconds: Int) -> String {
        let minutes = max(Int((Double(seconds) / 60).rounded()), 1)
        return "\(minutes)m"
    }

    static func relativeDate(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 60 { return "\(max(minutes, 1))m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        if days < 7 { return "\(days)d ago" }
        return shortDateFormatter.string(from: date)
    }

    static func milesValue(_ kilometers: Double) -> Double {
        kilometers * milesPerKilometer
    }

    static func feetValue(_ meters: Double) -> Double {
        meters * feetPerMeter
    }
}
