import SwiftUI

struct RecentDecksView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SlidesActionCoordinator
    let files: [WorkspaceFile]
    let openDeck: (WorkspaceFile) -> Void

    var body: some View {
        if files.isEmpty {
            EmptyStateCard(
                title: "No recent presentations",
                message: "Open or edit a deck to populate this list.",
                systemImage: "clock.arrow.circlepath",
                accessibilityIdentifier: AccessibilityID.emptyState("slides_recent")
            )
        } else {
            ForEach(files) { file in
                SlideDeckRowView(
                    file: file,
                    preview: store.contentPreview(for: file),
                    subtitle: AppFormatters.shortDateTime.string(from: file.updatedAt),
                    onOpen: { openDeck(file) },
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
