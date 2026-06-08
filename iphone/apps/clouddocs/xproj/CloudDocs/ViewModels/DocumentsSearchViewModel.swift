import Foundation

@MainActor
struct DocumentsSearchViewModel {
    let store: WorkspaceStore
    let query: String

    var results: [WorkspaceFile] {
        store.search(query: query, filter: .documents, sort: .recent).compactMap {
            guard case .file(let file) = $0 else { return nil }
            return file
        }
    }
}
