import Foundation

struct MonthlyVisitCount: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

struct ProfileStats {
    let totalVisits: Int
    let averageRating: Double?
    let topCuisines: [(String, Int)]
    let monthlyCounts: [MonthlyVisitCount]
    let neighborhoodCounts: [(String, Int)]
}

final class ProfileViewModel: ObservableObject {
    func stats(store: MockTasteRankStore) -> ProfileStats {
        let logs = store.visitLogs
        let totalVisits = logs.count
        let averageRating: Double?
        if logs.isEmpty {
            averageRating = nil
        } else {
            averageRating = logs.map { Double($0.rating) }.reduce(0, +) / Double(logs.count)
        }

        let cuisines = logs.compactMap { store.restaurant(for: $0.restaurantID)?.cuisine.name }
        let cuisineCounts = Dictionary(grouping: cuisines, by: { $0 }).mapValues { $0.count }
        let topCuisines = cuisineCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }

        let monthlyCounts = ProfileViewModel.monthlyCounts(from: logs)

        let neighborhoodNames = logs.compactMap { store.restaurant(for: $0.restaurantID)?.neighborhood.name }
        let neighborhoodCounts = Dictionary(grouping: neighborhoodNames, by: { $0 }).mapValues { $0.count }
        let neighborhoodSorted = neighborhoodCounts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }

        return ProfileStats(
            totalVisits: totalVisits,
            averageRating: averageRating,
            topCuisines: topCuisines,
            monthlyCounts: monthlyCounts,
            neighborhoodCounts: neighborhoodSorted
        )
    }

    private static func monthlyCounts(from logs: [VisitLog]) -> [MonthlyVisitCount] {
        let calendar = Calendar.current
        let now = Date()
        var results: [MonthlyVisitCount] = []

        for offset in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
            let month = calendar.component(.month, from: monthDate)
            let year = calendar.component(.year, from: monthDate)
            let label = DateFormatter.shortMonthYear.string(from: monthDate)
            let count = logs.filter {
                let logMonth = calendar.component(.month, from: $0.dateVisited)
                let logYear = calendar.component(.year, from: $0.dateVisited)
                return logMonth == month && logYear == year
            }.count
            results.append(MonthlyVisitCount(label: label, count: count))
        }

        return results
    }
}

private extension DateFormatter {
    static let shortMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
}
