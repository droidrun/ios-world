import SwiftUI

struct SharedView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SlidesActionCoordinator

    private var files: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .presentation && $0.shared && !$0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            List {
                if files.isEmpty {
                    EmptyStateCard(
                        title: "No shared decks",
                        message: "Presentations shared with you or by you will appear here.",
                        systemImage: "person.2",
                        accessibilityIdentifier: AccessibilityID.emptyState("slides_shared_tab")
                    )
                } else {
                    ForEach(files) { file in
                        SlideDeckRowView(
                            file: file,
                            preview: store.contentPreview(for: file),
                            subtitle: "Shared by \(file.ownerName)",
                            onOpen: { openDeck(file) },
                            onRename: { coordinator.beginRename(file: file) },
                            onMove: { coordinator.beginMove(file: file) },
                            onDuplicate: { _ = store.duplicateFile(id: file.id) },
                            onShare: { coordinator.beginShare(file: file) },
                            onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                        )
                    }
                }
            }
            .navigationTitle("Shared")
        }
    }

    private func openDeck(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudSlides", targetApp: "Slides")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}
