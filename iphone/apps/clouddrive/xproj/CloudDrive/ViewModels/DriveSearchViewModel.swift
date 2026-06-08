import Foundation

@MainActor
struct DriveSearchViewModel {
    let store: WorkspaceStore
    let query: String
    let filter: WorkspaceSearchFilter
    let sort: WorkspaceSortOption

    var results: [BrowserItem] {
        store.search(query: query, filter: filter, sort: sort)
    }
}
