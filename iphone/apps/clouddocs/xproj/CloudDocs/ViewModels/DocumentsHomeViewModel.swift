import Foundation

@MainActor
struct DocumentsHomeViewModel {
    let store: WorkspaceStore

    var recentDocuments: [WorkspaceFile] {
        store.recentFiles().filter { $0.fileType == .document }
    }

    var ownedDocuments: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .document && !$0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var sharedDocuments: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .document && $0.shared && !$0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
