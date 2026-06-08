import Foundation

@MainActor
final class ProgressViewModel: StoreBackedViewModel {
    @Published var selectedRange: ProgressRange = .days7

    var summary: ProgressSummary {
        store.progressSummary(days: selectedRange.rawValue)
    }

    var caloriePoints: [HistoryPoint] {
        store.calorieHistory(days: selectedRange.rawValue)
    }

    var weightPoints: [HistoryPoint] {
        store.weightHistory(days: selectedRange.rawValue)
    }

    var exercisePoints: [HistoryPoint] {
        store.exerciseFrequencyHistory(days: selectedRange.rawValue)
    }

    var weightEntries: [WeightEntry] {
        store.weightEntriesInRange(days: selectedRange.rawValue).sorted { $0.date > $1.date }
    }

    var dailyHistory: [DailyHistorySummary] {
        store.dailyHistory(days: selectedRange.rawValue)
    }

    var exerciseHistory: [ExerciseEntry] {
        store.exerciseEntriesInRange(days: selectedRange.rawValue)
    }

    @discardableResult
    func logWeight(_ weight: Double) -> Bool {
        store.logWeight(weight)
    }

    @discardableResult
    func updateWeightEntry(entryID: String, weight: Double, date: Date) -> Bool {
        store.updateWeightEntry(entryID: entryID, weight: weight, date: date)
    }

    func removeWeightEntry(entryID: String) {
        store.removeWeightEntry(entryID: entryID)
    }
}
