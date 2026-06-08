import Foundation

@MainActor
final class MoreViewModel: StoreBackedViewModel {
    var pushNotificationsEnabled: Bool {
        store.state.pushNotificationsEnabled
    }

    var reminderNotificationsEnabled: Bool {
        store.state.reminderNotificationsEnabled
    }

    var unitSystem: UnitSystem {
        store.state.userProfile.unitSystem
    }

    var currentCalorieGoal: Int {
        store.state.nutritionGoal.goalCalories
    }

    var foodDatabaseCount: Int {
        store.state.foodDatabase.count
    }

    var statusMessage: String? {
        store.inlineStatusMessage
    }

    func setPushNotifications(_ enabled: Bool) {
        store.updatePushNotifications(enabled)
    }

    func setReminderNotifications(_ enabled: Bool) {
        store.updateReminderNotifications(enabled)
    }

    func setUnitSystem(_ unitSystem: UnitSystem) {
        store.updateUnitSystem(unitSystem)
    }

    func reloadSeededFoodDatabase() {
        store.reloadSeededFoodDatabase()
    }

    func resetPersistence() {
        store.resetPersistence()
    }

    func resetAppState() {
        store.resetAppState()
    }
}
