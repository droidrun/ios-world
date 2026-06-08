import Foundation
import Observation

@Observable final class SearchViewModel {
    var query: String = ""
    var filterState: FilterState = .default

    func filteredEvents(store: MockTicketBoxStore) -> [Event] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let now = Date()

        var filtered = store.upcomingEvents.filter { event in
            if !trimmedQuery.isEmpty {
                let venueName = store.venue(for: event.venueID)?.name.lowercased() ?? ""
                let performerNames = event.performers.map { $0.name.lowercased() }.joined(separator: " ")
                let searchable = [event.title.lowercased(), event.city.lowercased(), venueName, performerNames]
                guard searchable.contains(where: { $0.contains(trimmedQuery) }) else { return false }
            }

            if let category = filterState.category, event.category != category {
                return false
            }

            if let city = filterState.city, event.city != city {
                return false
            }

            if !matchesDateRange(event.date, now: now, filter: filterState.dateRange) {
                return false
            }

            let minPrice = store.minPrice(for: event)
            if minPrice < filterState.minPrice || minPrice > filterState.maxPrice {
                return false
            }

            if filterState.instantOnly, !event.listings.contains(where: { $0.deliveryType == .instant }) {
                return false
            }

            return true
        }

        switch filterState.sortOption {
        case .recommended:
            filtered.sort { lhs, rhs in
                averageDealScore(for: lhs) > averageDealScore(for: rhs)
            }
        case .lowestPrice:
            filtered.sort { store.minPrice(for: $0) < store.minPrice(for: $1) }
        case .bestValue:
            filtered.sort {
                if averageDealScore(for: $0) == averageDealScore(for: $1) {
                    return store.minPrice(for: $0) < store.minPrice(for: $1)
                }
                return averageDealScore(for: $0) > averageDealScore(for: $1)
            }
        case .soonestDate:
            filtered.sort { $0.date < $1.date }
        }

        return filtered
    }

    private func averageDealScore(for event: Event) -> Double {
        guard !event.listings.isEmpty else { return 0 }
        let total = event.listings.map { Double($0.dealScore) }.reduce(0, +)
        return total / Double(event.listings.count)
    }

    private func matchesDateRange(_ date: Date, now: Date, filter: DateRangeFilter) -> Bool {
        let calendar = Calendar.current
        switch filter {
        case .any:
            return true
        case .weekend:
            guard let nextSaturday = calendar.nextDate(
                after: now,
                matching: DateComponents(weekday: 7),
                matchingPolicy: .nextTimePreservingSmallerComponents
            ) else { return false }
            let start = calendar.startOfDay(for: nextSaturday)
            guard let end = calendar.date(byAdding: .day, value: 2, to: start) else { return false }
            return (start...end).contains(date)
        case .next7:
            guard let end = calendar.date(byAdding: .day, value: 7, to: now) else { return true }
            return (now...end).contains(date)
        case .next30:
            guard let end = calendar.date(byAdding: .day, value: 30, to: now) else { return true }
            return (now...end).contains(date)
        }
    }
}
