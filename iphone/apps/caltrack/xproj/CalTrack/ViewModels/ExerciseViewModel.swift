import Foundation

@MainActor
final class ExerciseViewModel: StoreBackedViewModel {
    var exerciseCatalog: [Exercise] {
        store.state.exerciseCatalog.sorted { $0.exerciseName < $1.exerciseName }
    }

    var todayEntries: [ExerciseEntry] {
        store.todayLog.exerciseEntries.sorted { $0.date > $1.date }
    }

    var todayBurnedCalories: Int {
        store.todayLog.burnedCalories
    }

    var weeklyBurnedCalories: Int {
        store.exerciseEntriesInRange(days: 7).reduce(0) { $0 + $1.caloriesBurned }
    }

    var weeklySessionCount: Int {
        store.exerciseEntriesInRange(days: 7).count
    }

    var featuredExercises: [Exercise] {
        let categoryOrder = ["Cardio", "Strength", "Recovery"]
        return store.state.exerciseCatalog
            .sorted { lhs, rhs in
                let lhsRank = categoryOrder.firstIndex(of: lhs.category) ?? Int.max
                let rhsRank = categoryOrder.firstIndex(of: rhs.category) ?? Int.max
                if lhsRank == rhsRank {
                    return lhs.exerciseName < rhs.exerciseName
                }
                return lhsRank < rhsRank
            }
            .prefix(3)
            .map { $0 }
    }

    func searchExercises(_ query: String) -> [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return exerciseCatalog
        }

        let needle = trimmed.lowercased()
        return exerciseCatalog.filter { exercise in
            exercise.exerciseName.lowercased().contains(needle)
                || exercise.category.lowercased().contains(needle)
        }
    }

    @discardableResult
    func logExercise(_ exercise: Exercise, durationMinutes: Int, caloriesBurned: Int) -> Bool {
        store.logExercise(exercise, durationMinutes: durationMinutes, caloriesBurned: caloriesBurned)
    }

    @discardableResult
    func quickLog(_ exercise: Exercise) -> Bool {
        store.logExercise(exercise, durationMinutes: exercise.durationMinutes, caloriesBurned: exercise.caloriesBurned)
    }

    @discardableResult
    func updateExerciseEntry(entryID: String, durationMinutes: Int, caloriesBurned: Int) -> Bool {
        store.updateExerciseEntry(entryID: entryID, durationMinutes: durationMinutes, caloriesBurned: caloriesBurned)
    }

    func removeExerciseEntry(entryID: String) {
        store.removeExerciseEntry(entryID: entryID)
    }
}
