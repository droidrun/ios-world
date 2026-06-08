import Foundation

@MainActor
struct SlidesEditorViewModel {
    let store: WorkspaceStore
    let fileId: String

    var file: WorkspaceFile? {
        store.file(id: fileId)
    }

    var presentation: PresentationFile? {
        store.presentation(id: fileId)
    }
}
