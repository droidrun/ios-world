import Foundation

@MainActor
struct SheetsHomeViewModel {
    let store: WorkspaceStore

    var recentFiles: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .spreadsheet && !$0.trashed }
            .sorted { ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt) }
    }

    var ownedFiles: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .spreadsheet && !$0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var sharedFiles: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .spreadsheet && $0.shared && !$0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
