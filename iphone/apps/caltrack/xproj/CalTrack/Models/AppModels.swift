import Foundation

enum FitnessTab: String, Codable, CaseIterable, Identifiable {
    case today
    case progress
    case more

    var id: String { rawValue }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"

    var id: String { rawValue }

    var accessibilitySlug: String {
        switch self {
        case .breakfast:
            return "breakfast"
        case .lunch:
            return "lunch"
        case .dinner:
            return "dinner"
        case .snacks:
            return "snacks"
        }
    }

    var systemImage: String {
        switch self {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "fork.knife.circle.fill"
        case .dinner:
            return "moon.stars.fill"
        case .snacks:
            return "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case pounds
    case kilograms

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pounds:
            return "Imperial"
        case .kilograms:
            return "Metric"
        }
    }

    var shortLabel: String {
        switch self {
        case .pounds:
            return "lb"
        case .kilograms:
            return "kg"
        }
    }
}

enum ProgressRange: Int, Codable, CaseIterable, Identifiable {
    case days7 = 7
    case days30 = 30
    case days90 = 90

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .days7:
            return "7 days"
        case .days30:
            return "30 days"
        case .days90:
            return "90 days"
        }
    }
}

struct NutritionInfo: Codable, Hashable {
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sodium: Double

    static let zero = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sodium: 0)

    func scaled(by quantity: Double) -> NutritionInfo {
        NutritionInfo(
            calories: Int((Double(calories) * quantity).rounded()),
            protein: protein * quantity,
            carbs: carbs * quantity,
            fat: fat * quantity,
            fiber: fiber * quantity,
            sodium: sodium * quantity
        )
    }

    static func +(lhs: NutritionInfo, rhs: NutritionInfo) -> NutritionInfo {
        NutritionInfo(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sodium: lhs.sodium + rhs.sodium
        )
    }
}

struct FoodDatabaseEntry: Codable, Identifiable, Hashable {
    let id: String
    let foodName: String
    let servingSize: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sodium: Double
    let category: String
    let searchKeywords: [String]

    var nutritionInfo: NutritionInfo {
        NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sodium: sodium
        )
    }

    var foodItem: FoodItem {
        FoodItem(
            id: id,
            foodName: foodName,
            servingSize: servingSize,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sodium: sodium
        )
    }

    var systemImageName: String {
        switch category.lowercased() {
        case "protein":
            return "dumbbell.fill"
        case "breakfast":
            return "sun.max.fill"
        case "fruit":
            return "apple.logo"
        case "vegetables":
            return "leaf.fill"
        case "grains":
            return "circle.grid.2x2.fill"
        case "healthy fats":
            return "drop.fill"
        case "dairy":
            return "carton.fill"
        case "snacks":
            return "popcorn.fill"
        case "lunch":
            return "bag.fill"
        case "dinner":
            return "fork.knife"
        case "beverages":
            return "cup.and.saucer.fill"
        case "dessert":
            return "birthday.cake.fill"
        case "legumes":
            return "bolt.heart.fill"
        case "sides":
            return "square.stack.3d.down.right.fill"
        case "condiments":
            return "sparkles"
        default:
            return "circle.fill"
        }
    }
}

struct FoodItem: Codable, Identifiable, Hashable {
    let id: String
    let foodName: String
    let servingSize: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sodium: Double

    var nutritionInfo: NutritionInfo {
        NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sodium: sodium
        )
    }
}

struct MealEntry: Codable, Identifiable, Hashable {
    let id: String
    var foodItem: FoodItem
    var mealType: MealType
    var quantity: Double
    var date: Date

    var foodName: String { foodItem.foodName }
    var servingSize: String { foodItem.servingSize }
    var calories: Int { nutrition.calories }
    var protein: Double { nutrition.protein }
    var carbs: Double { nutrition.carbs }
    var fat: Double { nutrition.fat }
    var fiber: Double { nutrition.fiber }
    var sodium: Double { nutrition.sodium }

    var nutrition: NutritionInfo {
        foodItem.nutritionInfo.scaled(by: quantity)
    }
}

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let exerciseName: String
    let durationMinutes: Int
    let caloriesBurned: Int
    let category: String

    func calories(for duration: Int) -> Int {
        guard durationMinutes > 0 else { return caloriesBurned }
        let perMinute = Double(caloriesBurned) / Double(durationMinutes)
        return Int((perMinute * Double(duration)).rounded())
    }

    var systemImageName: String {
        switch category.lowercased() {
        case "cardio":
            return "figure.run"
        case "strength":
            return "dumbbell.fill"
        case "recovery":
            return "figure.cooldown"
        default:
            return "figure.mixed.cardio"
        }
    }
}

struct ExerciseEntry: Codable, Identifiable, Hashable {
    let id: String
    var exerciseName: String
    var durationMinutes: Int
    var caloriesBurned: Int
    var date: Date
}

struct DailyLog: Codable, Identifiable, Hashable {
    let id: String
    var date: Date
    var mealEntries: [MealEntry]
    var exerciseEntries: [ExerciseEntry]
    var waterCups: Int
    var stepCount: Int

    var nutritionTotals: NutritionInfo {
        mealEntries.reduce(.zero) { $0 + $1.nutrition }
    }

    var consumedCalories: Int {
        nutritionTotals.calories
    }

    var burnedCalories: Int {
        exerciseEntries.reduce(0) { $0 + $1.caloriesBurned }
    }

    var remainingCalories: Int {
        consumedCalories - burnedCalories
    }

    func mealEntries(for mealType: MealType) -> [MealEntry] {
        mealEntries
            .filter { $0.mealType == mealType }
            .sorted { $0.foodName < $1.foodName }
    }
}

struct WeightEntry: Codable, Identifiable, Hashable {
    let id: String
    var date: Date
    var weight: Double
}

struct UserProfile: Codable, Hashable {
    var id: String
    var userName: String
    var height: Double
    var weight: Double
    var goalWeight: Double
    var activityLevel: String
    var dailyCalorieGoal: Int
    var unitSystem: UnitSystem
}

struct NutritionGoal: Codable, Hashable {
    var goalCalories: Int
    var goalProtein: Double
    var goalCarbs: Double
    var goalFat: Double
    var targetWeight: Double
    var weeklyWeightChange: Double
}

struct ProgressSummary: Hashable {
    var streakCount: Int
    var averageCalories: Int
    var averageBurned: Int
    var averageWaterCups: Int
    var averageSteps: Int
    var latestWeight: Double?
    var weightChange: Double
}

struct MealSummary: Identifiable, Hashable {
    var id: String { mealType.id }
    let mealType: MealType
    let totalCalories: Int
    let itemCount: Int
}

struct FrequentMealTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let mealType: MealType
    let foods: [String]
    let averageCalories: Int
}

struct HistoryPoint: Identifiable, Hashable {
    let id: String
    let date: Date
    let label: String
    let value: Double
}

struct DailyHistorySummary: Identifiable, Hashable {
    let id: String
    let date: Date
    let consumedCalories: Int
    let burnedCalories: Int
    let mealCount: Int
    let exerciseCount: Int
}

struct FitnessAppState: Codable, Hashable {
    var selectedTab: FitnessTab
    var userProfile: UserProfile
    var nutritionGoal: NutritionGoal
    var dailyLogs: [DailyLog]
    var weightEntries: [WeightEntry]
    var foodDatabase: [FoodDatabaseEntry]
    var exerciseCatalog: [Exercise]
    var recentFoodIDs: [String]
    var pushNotificationsEnabled: Bool
    var reminderNotificationsEnabled: Bool
    var nextMealEntrySequence: Int
    var nextExerciseEntrySequence: Int
    var nextWeightEntrySequence: Int
}
