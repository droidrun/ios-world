import SwiftUI

struct RecentDocumentsView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DocumentActionCoordinator
    let files: [WorkspaceFile]
    let openDocument: (WorkspaceFile) -> Void

    var body: some View {
        if files.isEmpty {
            EmptyStateCard(
                title: "No recent documents",
                message: "Open or edit a document to populate this list.",
                systemImage: "clock.arrow.circlepath",
                accessibilityIdentifier: AccessibilityID.emptyState("docs_recent")
            )
        } else {
            ForEach(files) { file in
                DocumentRowView(
                    file: file,
                    preview: store.contentPreview(for: file),
                    subtitle: AppFormatters.shortDateTime.string(from: file.updatedAt),
                    onOpen: { openDocument(file) },
                    onRename: { coordinator.beginRename(file: file) },
                    onMove: { coordinator.beginMove(file: file) },
                    onDuplicate: { _ = store.duplicateFile(id: file.id) },
                    onShare: { coordinator.beginShare(file: file) },
                    onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                )
                .accessibilityIdentifier(AccessibilityID.recentRow(file))
            }
        }
    }
}
