import Foundation

@MainActor
struct SlidesSearchViewModel {
    let store: WorkspaceStore
    let query: String

    var results: [WorkspaceFile] {
        store.search(query: query, filter: .presentations, sort: .recent).compactMap {
            guard case .file(let file) = $0 else { return nil }
            return file
        }
    }
}
