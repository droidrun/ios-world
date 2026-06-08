import Foundation

@MainActor
final class SearchViewModel: StoreBackedViewModel {
    @Published var query: String = ""
    @Published var filter: SearchFilter = .all
    @Published var mentionsMeOnly: Bool = false
    @Published var hasLinkOnly: Bool = false
    @Published var hasFileOnly: Bool = false

    var recentSearches: [String] {
        store.recentSearches
    }

    var results: [SearchResult] {
        store.search(
            query: query,
            filter: filter,
            mentionsOnly: mentionsMeOnly,
            hasLink: hasLinkOnly,
            hasFile: hasFileOnly
        )
    }

    func commitSearch() {
        store.rememberSearch(query)
    }

    func useRecentSearch(_ value: String) {
        query = value
    }

    func navigationTarget(for result: SearchResult) -> NavigationTarget? {
        store.navigationTarget(for: result)
    }
}
