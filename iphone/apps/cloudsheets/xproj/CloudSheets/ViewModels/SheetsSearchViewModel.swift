import Foundation

@MainActor
struct SheetsSearchViewModel {
    let store: WorkspaceStore
    let query: String

    var results: [WorkspaceFile] {
        store.search(query: query, filter: .spreadsheets, sort: .recent).compactMap {
            guard case .file(let file) = $0 else { return nil }
            return file
        }
    }
}
