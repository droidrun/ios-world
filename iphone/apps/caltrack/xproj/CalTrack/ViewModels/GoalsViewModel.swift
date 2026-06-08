import Foundation

@MainActor
final class GoalsViewModel: StoreBackedViewModel {
    var goals: NutritionGoal {
        store.state.nutritionGoal
    }

    var unitSystem: UnitSystem {
        store.state.userProfile.unitSystem
    }

    func saveGoals(
        goalCalories: Int,
        goalProtein: Double,
        goalCarbs: Double,
        goalFat: Double,
        targetWeight: Double,
        weeklyWeightChange: Double
    ) {
        store.updateGoals(
            goalCalories: goalCalories,
            goalProtein: goalProtein,
            goalCarbs: goalCarbs,
            goalFat: goalFat,
            targetWeight: targetWeight,
            weeklyWeightChange: weeklyWeightChange
        )
    }
}
