import Foundation

@MainActor
struct SpreadsheetEditorViewModel {
    let store: WorkspaceStore
    let fileId: String

    var file: WorkspaceFile? {
        store.file(id: fileId)
    }

    var spreadsheet: SpreadsheetFile? {
        store.spreadsheet(id: fileId)
    }
}
