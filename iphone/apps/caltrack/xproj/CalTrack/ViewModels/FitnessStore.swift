import Combine
import Foundation

@MainActor
final class FitnessStore: ObservableObject {
    @Published private(set) var state: FitnessAppState
    @Published var inlineStatusMessage: String?

    private let persistence: AppPersistence
    private let calendar = AppFormatters.calendar

    init(persistence: AppPersistence = AppPersistence()) {
        self.persistence = persistence

        if let loaded = persistence.loadState() {
            state = loaded
        } else {
            state = SeedData.seededState()
            persistence.saveState(state)
        }

        refreshBundledReferenceDataIfNeeded()
        backfillSeedHistoryIfNeeded()
        repairSequencesIfNeeded()
        ensureDailyLogExists(for: Date())
        synchronizeCurrentWeight()
    }

    var todayLog: DailyLog {
        dailyLog(for: Date()) ?? blankLog(for: Date())
    }

    var latestWeightEntry: WeightEntry? {
        state.weightEntries.sorted { $0.date > $1.date }.first
    }

    func setSelectedTab(_ tab: FitnessTab) {
        mutateState { draft in
            draft.selectedTab = tab
        }
    }

    func mealSummary(for mealType: MealType, on date: Date = Date()) -> MealSummary {
        let entries = (dailyLog(for: date)?.mealEntries(for: mealType) ?? [])
        return MealSummary(
            mealType: mealType,
            totalCalories: entries.reduce(0) { $0 + $1.calories },
            itemCount: entries.count
        )
    }

    func recentMealEntries(limit: Int) -> [MealEntry] {
        state.dailyLogs
            .sorted { $0.date > $1.date }
            .flatMap { $0.mealEntries.sorted { $0.date > $1.date } }
            .prefix(limit)
            .map { $0 }
    }

    func recentFoods(limit: Int) -> [FoodDatabaseEntry] {
        let lookup = Dictionary(uniqueKeysWithValues: state.foodDatabase.map { ($0.id, $0) })
        return state.recentFoodIDs
            .compactMap { lookup[$0] }
            .prefix(limit)
            .map { $0 }
    }

    func commonFoods(limit: Int) -> [FoodDatabaseEntry] {
        let counts = state.dailyLogs
            .flatMap(\.mealEntries)
            .reduce(into: [String: Int]()) { counts, entry in
                counts[entry.foodItem.id, default: 0] += 1
            }

        let lookup = Dictionary(uniqueKeysWithValues: state.foodDatabase.map { ($0.id, $0) })
        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .compactMap { lookup[$0.key] }
            .prefix(limit)
            .map { $0 }
    }

    func frequentMeals(limit: Int) -> [FrequentMealTemplate] {
        let allEntries = state.dailyLogs.flatMap(\.mealEntries)

        return MealType.allCases.compactMap { mealType in
            let entries = allEntries.filter { $0.mealType == mealType }
            guard !entries.isEmpty else { return nil }

            let foodCounts = entries.reduce(into: [String: Int]()) { counts, entry in
                counts[entry.foodName, default: 0] += 1
            }

            let topFoods = foodCounts
                .sorted { lhs, rhs in
                    if lhs.value == rhs.value {
                        return lhs.key < rhs.key
                    }
                    return lhs.value > rhs.value
                }
                .prefix(3)
                .map(\.key)

            let averageCalories = Int((Double(entries.reduce(0) { $0 + $1.calories }) / Double(entries.count)).rounded())

            return FrequentMealTemplate(
                id: "template_\(mealType.accessibilitySlug)",
                title: "\(mealType.rawValue) routine",
                mealType: mealType,
                foods: topFoods,
                averageCalories: averageCalories
            )
        }
        .sorted { lhs, rhs in
            lhs.averageCalories > rhs.averageCalories
        }
        .prefix(limit)
        .map { $0 }
    }

    func mealEntries(for mealType: MealType, on date: Date = Date()) -> [MealEntry] {
        dailyLog(for: date)?.mealEntries(for: mealType) ?? []
    }

    func searchFoods(_ query: String) -> [FoodDatabaseEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return state.foodDatabase.sorted { $0.foodName < $1.foodName }
        }

        let needle = trimmed.lowercased()

        return state.foodDatabase
            .filter { entry in
                entry.foodName.lowercased().contains(needle)
                    || entry.category.lowercased().contains(needle)
                    || entry.searchKeywords.contains(where: { $0.lowercased().contains(needle) })
            }
            .sorted { lhs, rhs in
                let lhsPrefix = lhs.foodName.lowercased().hasPrefix(needle)
                let rhsPrefix = rhs.foodName.lowercased().hasPrefix(needle)
                if lhsPrefix != rhsPrefix {
                    return lhsPrefix
                }
                return lhs.foodName < rhs.foodName
            }
    }

    @discardableResult
    func addFood(_ food: FoodDatabaseEntry, quantity: Double, to mealType: MealType, on date: Date = Date()) -> Bool {
        guard quantity > 0 else { return false }

        var succeeded = false
        mutateState { draft in
            let index = ensureDailyLogExists(for: date, in: &draft)
            let id = String(format: "meal_entry_%03d", draft.nextMealEntrySequence)
            draft.nextMealEntrySequence += 1

            let entry = MealEntry(
                id: id,
                foodItem: food.foodItem,
                mealType: mealType,
                quantity: quantity,
                date: calendar.startOfDay(for: date)
            )
            draft.dailyLogs[index].mealEntries.append(entry)
            draft.recentFoodIDs.removeAll { $0 == food.id }
            draft.recentFoodIDs.insert(food.id, at: 0)
            draft.recentFoodIDs = Array(draft.recentFoodIDs.prefix(20))
            succeeded = true
        }

        if succeeded {
            inlineStatusMessage = "\(food.foodName) added to \(mealType.rawValue)."
        }
        return succeeded
    }

    @discardableResult
    func updateMealEntry(entryID: String, quantity: Double, mealType: MealType) -> Bool {
        guard quantity > 0 else { return false }

        var updated = false
        mutateState { draft in
            for logIndex in draft.dailyLogs.indices {
                if let entryIndex = draft.dailyLogs[logIndex].mealEntries.firstIndex(where: { $0.id == entryID }) {
                    draft.dailyLogs[logIndex].mealEntries[entryIndex].quantity = quantity
                    draft.dailyLogs[logIndex].mealEntries[entryIndex].mealType = mealType
                    updated = true
                    return
                }
            }
        }

        if updated {
            inlineStatusMessage = "Food entry updated."
        }
        return updated
    }

    func removeMealEntry(entryID: String) {
        mutateState { draft in
            for logIndex in draft.dailyLogs.indices {
                draft.dailyLogs[logIndex].mealEntries.removeAll { $0.id == entryID }
            }
        }
        inlineStatusMessage = "Food entry removed."
    }

    @discardableResult
    func updateWaterCups(_ cups: Int, on date: Date = Date()) -> Bool {
        guard cups >= 0 else { return false }

        mutateState { draft in
            let index = ensureDailyLogExists(for: date, in: &draft)
            draft.dailyLogs[index].waterCups = cups
        }
        inlineStatusMessage = cups == 0 ? "Water intake cleared." : "Water intake updated."
        return true
    }

    @discardableResult
    func adjustWaterCups(by delta: Int, on date: Date = Date()) -> Int {
        let current = dailyLog(for: date)?.waterCups ?? 0
        let updated = max(current + delta, 0)
        _ = updateWaterCups(updated, on: date)
        return updated
    }

    @discardableResult
    func updateStepCount(_ stepCount: Int, on date: Date = Date()) -> Bool {
        guard stepCount >= 0 else { return false }

        mutateState { draft in
            let index = ensureDailyLogExists(for: date, in: &draft)
            draft.dailyLogs[index].stepCount = stepCount
        }
        inlineStatusMessage = stepCount == 0 ? "Step count cleared." : "Step count updated."
        return true
    }

    @discardableResult
    func adjustStepCount(by delta: Int, on date: Date = Date()) -> Int {
        let current = dailyLog(for: date)?.stepCount ?? 0
        let updated = max(current + delta, 0)
        _ = updateStepCount(updated, on: date)
        return updated
    }

    @discardableResult
    func logExercise(_ exercise: Exercise, durationMinutes: Int, caloriesBurned: Int, on date: Date = Date()) -> Bool {
        guard durationMinutes > 0, caloriesBurned > 0 else { return false }

        var succeeded = false
        mutateState { draft in
            let index = ensureDailyLogExists(for: date, in: &draft)
            let id = String(format: "exercise_entry_%03d", draft.nextExerciseEntrySequence)
            draft.nextExerciseEntrySequence += 1

            let entry = ExerciseEntry(
                id: id,
                exerciseName: exercise.exerciseName,
                durationMinutes: durationMinutes,
                caloriesBurned: caloriesBurned,
                date: calendar.startOfDay(for: date)
            )
            draft.dailyLogs[index].exerciseEntries.append(entry)
            succeeded = true
        }

        if succeeded {
            inlineStatusMessage = "\(exercise.exerciseName) logged."
        }
        return succeeded
    }

    @discardableResult
    func updateExerciseEntry(entryID: String, durationMinutes: Int, caloriesBurned: Int) -> Bool {
        guard durationMinutes > 0, caloriesBurned > 0 else { return false }

        var updated = false
        mutateState { draft in
            for logIndex in draft.dailyLogs.indices {
                if let entryIndex = draft.dailyLogs[logIndex].exerciseEntries.firstIndex(where: { $0.id == entryID }) {
                    draft.dailyLogs[logIndex].exerciseEntries[entryIndex].durationMinutes = durationMinutes
                    draft.dailyLogs[logIndex].exerciseEntries[entryIndex].caloriesBurned = caloriesBurned
                    updated = true
                    return
                }
            }
        }

        if updated {
            inlineStatusMessage = "Exercise entry updated."
        }
        return updated
    }

    func removeExerciseEntry(entryID: String) {
        mutateState { draft in
            for logIndex in draft.dailyLogs.indices {
                draft.dailyLogs[logIndex].exerciseEntries.removeAll { $0.id == entryID }
            }
        }
        inlineStatusMessage = "Exercise entry removed."
    }

    @discardableResult
    func logWeight(_ weight: Double, on date: Date = Date()) -> Bool {
        guard weight > 0 else { return false }

        let normalizedDate = calendar.startOfDay(for: date)

        var updated = false
        mutateState { draft in
            if let existingIndex = draft.weightEntries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
                draft.weightEntries[existingIndex].weight = weight
                updated = true
            } else {
                let id = String(format: "weight_entry_%03d", draft.nextWeightEntrySequence)
                draft.nextWeightEntrySequence += 1
                draft.weightEntries.insert(WeightEntry(id: id, date: normalizedDate, weight: weight), at: 0)
            }
            draft.userProfile.weight = weight
        }

        inlineStatusMessage = updated ? "Weight entry updated." : "Weight logged."
        return true
    }

    @discardableResult
    func updateWeightEntry(entryID: String, weight: Double, date: Date) -> Bool {
        guard weight > 0 else { return false }

        var updated = false
        mutateState { draft in
            if let index = draft.weightEntries.firstIndex(where: { $0.id == entryID }) {
                draft.weightEntries[index].weight = weight
                draft.weightEntries[index].date = calendar.startOfDay(for: date)
                updated = true
            }
            synchronizeCurrentWeight(in: &draft)
        }

        if updated {
            inlineStatusMessage = "Weight entry updated."
        }
        return updated
    }

    func removeWeightEntry(entryID: String) {
        mutateState { draft in
            draft.weightEntries.removeAll { $0.id == entryID }
            synchronizeCurrentWeight(in: &draft)
        }
        inlineStatusMessage = "Weight entry removed."
    }

    func updateGoals(
        goalCalories: Int,
        goalProtein: Double,
        goalCarbs: Double,
        goalFat: Double,
        targetWeight: Double,
        weeklyWeightChange: Double
    ) {
        mutateState { draft in
            draft.nutritionGoal.goalCalories = goalCalories
            draft.nutritionGoal.goalProtein = goalProtein
            draft.nutritionGoal.goalCarbs = goalCarbs
            draft.nutritionGoal.goalFat = goalFat
            draft.nutritionGoal.targetWeight = targetWeight
            draft.nutritionGoal.weeklyWeightChange = weeklyWeightChange
            draft.userProfile.goalWeight = targetWeight
            draft.userProfile.dailyCalorieGoal = goalCalories
        }
        inlineStatusMessage = "Goals updated."
    }

    func updateProfile(
        userName: String,
        height: Double,
        weight: Double,
        goalWeight: Double,
        activityLevel: String,
        unitSystem: UnitSystem
    ) {
        mutateState { draft in
            draft.userProfile.userName = userName
            draft.userProfile.height = height
            draft.userProfile.weight = weight
            draft.userProfile.goalWeight = goalWeight
            draft.userProfile.activityLevel = activityLevel
            draft.userProfile.unitSystem = unitSystem
            draft.nutritionGoal.targetWeight = goalWeight
            upsertWeightEntry(weight, for: Date(), in: &draft)
        }
        inlineStatusMessage = "Profile updated."
    }

    func updatePushNotifications(_ enabled: Bool) {
        mutateState { draft in
            draft.pushNotificationsEnabled = enabled
        }
    }

    func updateReminderNotifications(_ enabled: Bool) {
        mutateState { draft in
            draft.reminderNotificationsEnabled = enabled
        }
    }

    func updateUnitSystem(_ unitSystem: UnitSystem) {
        mutateState { draft in
            draft.userProfile.unitSystem = unitSystem
        }
    }

    func reloadSeededFoodDatabase() {
        mutateState { draft in
            draft.foodDatabase = SeedData.foodDatabase()
        }
        inlineStatusMessage = "Food library refreshed."
    }

    func resetPersistence() {
        persistence.clearState()
        state = SeedData.seededState()
        inlineStatusMessage = "App data has been reset."
    }

    func resetAppState() {
        persistence.clearState()
        state = SeedData.seededState()
        inlineStatusMessage = "App state reset."
    }

    func progressSummary(days: Int) -> ProgressSummary {
        let history = loggedDailyLogsInRange(days: days)
        let consumedValues = history.map(\.consumedCalories)
        let burnedValues = history.map(\.burnedCalories)
        let waterValues = history.map(\.waterCups)
        let stepValues = history.map(\.stepCount)
        let averageCalories = consumedValues.isEmpty ? 0 : Int((Double(consumedValues.reduce(0, +)) / Double(consumedValues.count)).rounded())
        let averageBurned = burnedValues.isEmpty ? 0 : Int((Double(burnedValues.reduce(0, +)) / Double(burnedValues.count)).rounded())
        let averageWater = waterValues.isEmpty ? 0 : Int((Double(waterValues.reduce(0, +)) / Double(waterValues.count)).rounded())
        let averageSteps = stepValues.isEmpty ? 0 : Int((Double(stepValues.reduce(0, +)) / Double(stepValues.count)).rounded())

        let weightEntries = weightEntriesInRange(days: days).sorted { $0.date < $1.date }
        let weightChange = (weightEntries.last?.weight ?? 0) - (weightEntries.first?.weight ?? weightEntries.last?.weight ?? 0)

        return ProgressSummary(
            streakCount: currentStreakCount(),
            averageCalories: averageCalories,
            averageBurned: averageBurned,
            averageWaterCups: averageWater,
            averageSteps: averageSteps,
            latestWeight: latestWeightEntry?.weight,
            weightChange: weightChange
        )
    }

    func calorieHistory(days: Int) -> [HistoryPoint] {
        loggedDailyLogsInRange(days: days).map { log in
            HistoryPoint(
                id: "calories_\(log.id)",
                date: log.date,
                label: AppFormatters.weekdayFormatter.string(from: log.date),
                value: Double(log.consumedCalories)
            )
        }
    }

    func exerciseFrequencyHistory(days: Int) -> [HistoryPoint] {
        loggedDailyLogsInRange(days: days).map { log in
            HistoryPoint(
                id: "exercise_\(log.id)",
                date: log.date,
                label: AppFormatters.weekdayFormatter.string(from: log.date),
                value: Double(log.exerciseEntries.count)
            )
        }
    }

    func weightHistory(days: Int) -> [HistoryPoint] {
        weightEntriesInRange(days: days)
            .sorted { $0.date < $1.date }
            .map { entry in
                HistoryPoint(
                    id: entry.id,
                    date: entry.date,
                    label: AppFormatters.monthDayFormatter.string(from: entry.date),
                    value: entry.weight
                )
            }
    }

    func dailyHistory(days: Int) -> [DailyHistorySummary] {
        loggedDailyLogsInRange(days: days)
            .sorted { $0.date > $1.date }
            .map { log in
                DailyHistorySummary(
                    id: log.id,
                    date: log.date,
                    consumedCalories: log.consumedCalories,
                    burnedCalories: log.burnedCalories,
                    mealCount: log.mealEntries.count,
                    exerciseCount: log.exerciseEntries.count
                )
            }
    }

    func exerciseEntriesInRange(days: Int) -> [ExerciseEntry] {
        let earliestDate = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: Date())) ?? Date()
        return state.dailyLogs
            .flatMap(\.exerciseEntries)
            .filter { $0.date >= earliestDate }
            .sorted { $0.date > $1.date }
    }

    func weightEntriesInRange(days: Int) -> [WeightEntry] {
        let earliestDate = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: Date())) ?? Date()
        return state.weightEntries.filter { $0.date >= earliestDate }
    }

    func dailyLog(for date: Date) -> DailyLog? {
        state.dailyLogs.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func exercise(named name: String) -> Exercise? {
        state.exerciseCatalog.first { $0.exerciseName == name }
    }

    private func currentStreakCount() -> Int {
        let logs = state.dailyLogs.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for log in logs {
            if calendar.isDate(log.date, inSameDayAs: currentDate) {
                if !log.mealEntries.isEmpty || !log.exerciseEntries.isEmpty {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            }
        }

        return streak
    }

    private func dailyLogsInRange(days: Int) -> [DailyLog] {
        let today = calendar.startOfDay(for: Date())
        return stride(from: days - 1, through: 0, by: -1).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return dailyLog(for: date) ?? blankLog(for: date)
        }
    }

    private func loggedDailyLogsInRange(days: Int) -> [DailyLog] {
        let earliestDate = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: Date())) ?? Date()
        return state.dailyLogs
            .filter { $0.date >= earliestDate }
            .sorted { $0.date < $1.date }
    }

    private func blankLog(for date: Date) -> DailyLog {
        DailyLog(
            id: AppFormatters.dateKey(for: date),
            date: calendar.startOfDay(for: date),
            mealEntries: [],
            exerciseEntries: [],
            waterCups: 0,
            stepCount: 0
        )
    }

    private func ensureDailyLogExists(for date: Date) {
        mutateState { draft in
            _ = ensureDailyLogExists(for: date, in: &draft)
        }
    }

    @discardableResult
    private func ensureDailyLogExists(for date: Date, in draft: inout FitnessAppState) -> Int {
        if let index = draft.dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            return index
        }

        let log = blankLog(for: date)
        draft.dailyLogs.insert(log, at: 0)
        return 0
    }

    private func synchronizeCurrentWeight() {
        mutateState { draft in
            synchronizeCurrentWeight(in: &draft)
        }
    }

    private func synchronizeCurrentWeight(in draft: inout FitnessAppState) {
        if let latest = draft.weightEntries.sorted(by: { $0.date > $1.date }).first {
            draft.userProfile.weight = latest.weight
        }
    }

    private func upsertWeightEntry(_ weight: Double, for date: Date, in draft: inout FitnessAppState) {
        let normalizedDate = calendar.startOfDay(for: date)
        if let index = draft.weightEntries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
            draft.weightEntries[index].weight = weight
            draft.weightEntries[index].date = normalizedDate
            return
        }

        let id = String(format: "weight_entry_%03d", draft.nextWeightEntrySequence)
        draft.nextWeightEntrySequence += 1
        draft.weightEntries.insert(
            WeightEntry(id: id, date: normalizedDate, weight: weight),
            at: 0
        )
    }

    private func refreshBundledReferenceDataIfNeeded() {
        let bundledFoods = SeedData.foodDatabase()
        let bundledExercises = SeedData.seededExercises()

        guard !bundledFoods.isEmpty else { return }

        let currentFoodIDs = Set(state.foodDatabase.map(\.id))
        let bundledFoodIDs = Set(bundledFoods.map(\.id))
        let shouldRefreshFoods = currentFoodIDs != bundledFoodIDs || state.foodDatabase.count != bundledFoods.count
        let shouldRefreshExercises = state.exerciseCatalog != bundledExercises

        guard shouldRefreshFoods || shouldRefreshExercises else { return }

        mutateState { draft in
            if shouldRefreshFoods {
                draft.foodDatabase = bundledFoods
            }
            if shouldRefreshExercises {
                draft.exerciseCatalog = bundledExercises
            }
        }
    }

    private func backfillSeedHistoryIfNeeded() {
        guard state.dailyLogs.count < 20 || state.weightEntries.count < 12 else {
            return
        }

        let seeded = SeedData.seededState(today: Date())
        let existingLogKeys = Set(state.dailyLogs.map(\.id))
        let existingWeightKeys = Set(state.weightEntries.map { AppFormatters.dateKey(for: $0.date) })

        let missingLogs = seeded.dailyLogs.filter { !existingLogKeys.contains($0.id) }
        let missingWeights = seeded.weightEntries.filter { !existingWeightKeys.contains(AppFormatters.dateKey(for: $0.date)) }

        guard !missingLogs.isEmpty || !missingWeights.isEmpty else {
            return
        }

        mutateState { draft in
            draft.dailyLogs.append(contentsOf: missingLogs)
            draft.weightEntries.append(contentsOf: missingWeights)
        }
    }

    private func repairSequencesIfNeeded() {
        let nextMeal = (state.dailyLogs.flatMap(\.mealEntries).compactMap { numericSuffix(from: $0.id) }.max() ?? 0) + 1
        let nextExercise = (state.dailyLogs.flatMap(\.exerciseEntries).compactMap { numericSuffix(from: $0.id) }.max() ?? 0) + 1
        let nextWeight = (state.weightEntries.compactMap { numericSuffix(from: $0.id) }.max() ?? 0) + 1

        guard state.nextMealEntrySequence != nextMeal
                || state.nextExerciseEntrySequence != nextExercise
                || state.nextWeightEntrySequence != nextWeight else {
            return
        }

        mutateState { draft in
            draft.nextMealEntrySequence = nextMeal
            draft.nextExerciseEntrySequence = nextExercise
            draft.nextWeightEntrySequence = nextWeight
        }
    }

    private func numericSuffix(from identifier: String) -> Int? {
        let digits = identifier.split(separator: "_").last ?? ""
        return Int(digits)
    }

    private func mutateState(_ mutation: (inout FitnessAppState) -> Void) {
        var draft = state
        mutation(&draft)
        draft.dailyLogs.sort { $0.date > $1.date }
        draft.weightEntries.sort { $0.date > $1.date }
        state = draft
        persistence.saveStateAsync(draft)
    }
}

@MainActor
class StoreBackedViewModel: ObservableObject {
    let store: FitnessStore
    private var storeChangeCancellable: AnyCancellable?

    init(store: FitnessStore) {
        self.store = store
        storeChangeCancellable = store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
