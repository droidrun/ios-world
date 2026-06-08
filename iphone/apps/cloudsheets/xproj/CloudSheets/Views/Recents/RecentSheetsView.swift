import SwiftUI

struct RecentSheetsView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SpreadsheetActionCoordinator
    let files: [WorkspaceFile]
    let openSheet: (WorkspaceFile) -> Void

    var body: some View {
        if files.isEmpty {
            EmptyStateCard(
                title: "No recent spreadsheets",
                message: "Open or edit a spreadsheet to populate this list.",
                systemImage: "clock.arrow.circlepath",
                accessibilityIdentifier: AccessibilityID.emptyState("sheets_recent")
            )
        } else {
            ForEach(files) { file in
                SpreadsheetRowView(
                    file: file,
                    preview: store.contentPreview(for: file),
                    subtitle: AppFormatters.shortDateTime.string(from: file.updatedAt),
                    onOpen: { openSheet(file) },
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
