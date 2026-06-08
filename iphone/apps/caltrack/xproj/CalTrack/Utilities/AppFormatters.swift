import Foundation
import SwiftUI

enum AppFormatters {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "EEE"
        return formatter
    }()

    static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    static func dateKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: calendar.startOfDay(for: date))
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func displayNumber(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.05 {
            return String(Int(rounded))
        }
        return String(format: "%.1f", value)
    }

    static func displayWeight(_ valueInPounds: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .pounds:
            return "\(displayNumber(valueInPounds)) lb"
        case .kilograms:
            return "\(displayNumber(valueInPounds * 0.453592)) kg"
        }
    }

    static func editableWeight(_ valueInPounds: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .pounds:
            return displayNumber(valueInPounds)
        case .kilograms:
            return displayNumber(valueInPounds * 0.453592)
        }
    }

    static func pounds(fromEditableWeight value: Double, unitSystem: UnitSystem) -> Double {
        switch unitSystem {
        case .pounds:
            return value
        case .kilograms:
            return value / 0.453592
        }
    }

    static func displayHeight(_ inches: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .pounds:
            let feet = Int(inches) / 12
            let remainder = Int(inches) % 12
            return "\(feet) ft \(remainder) in"
        case .kilograms:
            return "\(displayNumber(inches * 2.54)) cm"
        }
    }

    static func editableHeight(_ inches: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .pounds:
            return displayNumber(inches)
        case .kilograms:
            return displayNumber(inches * 2.54)
        }
    }

    static func inches(fromEditableHeight value: Double, unitSystem: UnitSystem) -> Double {
        switch unitSystem {
        case .pounds:
            return value
        case .kilograms:
            return value / 2.54
        }
    }
}

enum FitnessTheme {
    static let accent = Color(red: 0.0, green: 0.44, blue: 0.95)
    static let accentBlue = Color(red: 0.0, green: 0.44, blue: 0.95)
    static let accentWarm = Color(red: 0.89, green: 0.57, blue: 0.20)
    static let accentRose = Color(red: 0.82, green: 0.35, blue: 0.39)
    static let canvasTop = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let canvasBottom = Color(red: 0.97, green: 0.97, blue: 0.99)
    static let cardBackground = Color.white
    static let mutedCard = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let dashboardBackground = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let subtleFill = Color(red: 0.93, green: 0.93, blue: 0.94)
    static let deepText = Color(red: 0.13, green: 0.16, blue: 0.17)
    static let secondaryText = Color(red: 0.39, green: 0.45, blue: 0.46)

    static let canvasGradient = LinearGradient(
        colors: [canvasTop, canvasBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.0, green: 0.30, blue: 0.72),
            Color(red: 0.0, green: 0.40, blue: 0.88),
            Color(red: 0.0, green: 0.48, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func color(for food: FoodDatabaseEntry) -> Color {
        color(forCategory: food.category)
    }

    static func color(forMeal mealType: MealType) -> Color {
        switch mealType {
        case .breakfast:
            return accentWarm
        case .lunch:
            return accentBlue
        case .dinner:
            return accent
        case .snacks:
            return accentRose
        }
    }

    static func color(forExercise exercise: Exercise) -> Color {
        switch exercise.category.lowercased() {
        case "cardio":
            return accentBlue
        case "strength":
            return accent
        case "recovery":
            return accentWarm
        default:
            return accentRose
        }
    }

    static func color(forCategory category: String) -> Color {
        switch category.lowercased() {
        case "protein", "legumes":
            return accent
        case "fruit", "breakfast", "beverages":
            return accentWarm
        case "vegetables":
            return accentBlue
        case "dinner", "lunch", "grains":
            return Color(red: 0.41, green: 0.53, blue: 0.86)
        case "healthy fats", "snacks", "dessert":
            return accentRose
        default:
            return secondaryText
        }
    }
}
