import Foundation

@MainActor
final class ActivityViewModel: StoreBackedViewModel {
    @Published var selectedFilter: ActivityType = .all

    var items: [ActivityItem] {
        store.activityItems(for: selectedFilter)
    }

    func navigationTarget(for item: ActivityItem) -> NavigationTarget? {
        store.navigationTarget(for: item)
    }
}
