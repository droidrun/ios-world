import Foundation

@MainActor
struct DocumentEditorViewModel {
    let store: WorkspaceStore
    let fileId: String

    var file: WorkspaceFile? {
        store.file(id: fileId)
    }

    var document: DocumentFile? {
        store.document(id: fileId)
    }

    var pathText: String {
        guard let file else { return "Unavailable" }
        return store.pathString(for: file)
    }
}
