import Foundation

@MainActor
final class ProfileViewModel: StoreBackedViewModel {
    let activityLevels = [
        "Sedentary",
        "Lightly Active",
        "Moderately Active",
        "Very Active"
    ]

    var profile: UserProfile {
        store.state.userProfile
    }

    var currentGoalCalories: Int {
        store.state.nutritionGoal.goalCalories
    }

    func saveProfile(
        userName: String,
        height: Double,
        weight: Double,
        goalWeight: Double,
        activityLevel: String,
        unitSystem: UnitSystem
    ) {
        store.updateProfile(
            userName: userName,
            height: height,
            weight: weight,
            goalWeight: goalWeight,
            activityLevel: activityLevel,
            unitSystem: unitSystem
        )
    }

    func resetAppState() {
        store.resetAppState()
    }
}
