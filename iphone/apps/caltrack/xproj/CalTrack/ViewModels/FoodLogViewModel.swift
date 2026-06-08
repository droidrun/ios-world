import Foundation

@MainActor
final class FoodLogViewModel: StoreBackedViewModel {
    var todayLog: DailyLog {
        store.todayLog
    }

    var mealSummaries: [MealSummary] {
        MealType.allCases.map { store.mealSummary(for: $0) }
    }

    var nutritionGoal: NutritionGoal {
        store.state.nutritionGoal
    }

    var remainingCalories: Int {
        nutritionGoal.goalCalories - todayLog.consumedCalories + todayLog.burnedCalories
    }

    var recentFoods: [FoodDatabaseEntry] {
        store.recentFoods(limit: 6)
    }

    var commonFoods: [FoodDatabaseEntry] {
        store.commonFoods(limit: 8)
    }

    func mealEntries(for mealType: MealType) -> [MealEntry] {
        store.mealEntries(for: mealType)
    }

    func searchFoods(_ query: String) -> [FoodDatabaseEntry] {
        Array(store.searchFoods(query).prefix(25))
    }

    func foodReference(for mealEntry: MealEntry) -> FoodDatabaseEntry? {
        store.state.foodDatabase.first { $0.id == mealEntry.foodItem.id }
    }

    func suggestedFoods(for mealType: MealType) -> [FoodDatabaseEntry] {
        let preferredCategories: Set<String>
        switch mealType {
        case .breakfast:
            preferredCategories = ["Breakfast", "Fruit", "Protein", "Dairy", "Beverages"]
        case .lunch:
            preferredCategories = ["Lunch", "Protein", "Vegetables", "Grains", "Legumes"]
        case .dinner:
            preferredCategories = ["Dinner", "Protein", "Vegetables", "Grains", "Sides"]
        case .snacks:
            preferredCategories = ["Snacks", "Fruit", "Dairy", "Healthy Fats", "Beverages"]
        }

        let seededMatches = store.state.foodDatabase
            .filter { preferredCategories.contains($0.category) }
            .sorted { lhs, rhs in
                if lhs.category == rhs.category {
                    return lhs.foodName < rhs.foodName
                }
                return lhs.category < rhs.category
            }

        let recent = store.recentFoods(limit: 8)
        let common = store.commonFoods(limit: 8)
        let merged = recent + common + seededMatches

        var seen = Set<String>()
        return merged.filter { entry in
            seen.insert(entry.id).inserted
        }
        .prefix(6)
        .map { $0 }
    }

    @discardableResult
    func addFood(_ food: FoodDatabaseEntry, quantity: Double, to mealType: MealType) -> Bool {
        store.addFood(food, quantity: quantity, to: mealType)
    }

    @discardableResult
    func updateMealEntry(entryID: String, quantity: Double, mealType: MealType) -> Bool {
        store.updateMealEntry(entryID: entryID, quantity: quantity, mealType: mealType)
    }

    func removeMealEntry(entryID: String) {
        store.removeMealEntry(entryID: entryID)
    }
}
