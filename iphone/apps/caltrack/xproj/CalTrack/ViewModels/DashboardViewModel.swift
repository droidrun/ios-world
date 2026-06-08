import Foundation

@MainActor
final class DashboardViewModel: StoreBackedViewModel {
    let waterGoal = 8
    let stepGoal = 10_000

    var todayLog: DailyLog {
        store.todayLog
    }

    var goal: NutritionGoal {
        store.state.nutritionGoal
    }

    var consumedCalories: Int {
        todayLog.consumedCalories
    }

    var burnedCalories: Int {
        todayLog.burnedCalories
    }

    var remainingCalories: Int {
        goal.goalCalories - consumedCalories + burnedCalories
    }

    var mealSummaries: [MealSummary] {
        MealType.allCases.map { store.mealSummary(for: $0) }
    }

    var weeklySummary: ProgressSummary {
        store.progressSummary(days: 7)
    }

    var calorieProgress: Double {
        guard goal.goalCalories > 0 else { return 0 }
        return min(Double(consumedCalories) / Double(goal.goalCalories), 1)
    }

    var waterProgress: Double {
        guard waterGoal > 0 else { return 0 }
        return min(Double(todayLog.waterCups) / Double(waterGoal), 1)
    }

    var stepProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return min(Double(todayLog.stepCount) / Double(stepGoal), 1)
    }

    var preferredName: String {
        let components = store.state.userProfile.userName.split(separator: " ")
        return components.first.map(String.init) ?? store.state.userProfile.userName
    }

    func mealEntries(for mealType: MealType) -> [MealEntry] {
        store.mealEntries(for: mealType)
    }

    @discardableResult
    func logWeight(_ weight: Double) -> Bool {
        store.logWeight(weight)
    }

    @discardableResult
    func updateWaterCups(_ cups: Int) -> Bool {
        store.updateWaterCups(cups)
    }

    @discardableResult
    func adjustWaterCups(by delta: Int) -> Int {
        store.adjustWaterCups(by: delta)
    }

    @discardableResult
    func updateStepCount(_ stepCount: Int) -> Bool {
        store.updateStepCount(stepCount)
    }

    @discardableResult
    func adjustStepCount(by delta: Int) -> Int {
        store.adjustStepCount(by: delta)
    }
}
