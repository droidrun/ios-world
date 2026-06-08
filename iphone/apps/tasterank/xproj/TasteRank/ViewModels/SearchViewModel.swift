import Foundation

final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var filterState: FilterState = .default
    @Published var sortOption: SortOption = .recommended

    func results(store: MockTasteRankStore) -> [Restaurant] {
        store.filteredRestaurants(query: query, filters: filterState, sort: sortOption)
    }
}
