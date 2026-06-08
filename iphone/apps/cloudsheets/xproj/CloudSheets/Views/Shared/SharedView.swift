import SwiftUI

struct SharedView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SpreadsheetActionCoordinator

    private var files: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .spreadsheet && $0.shared && !$0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            List {
                if files.isEmpty {
                    EmptyStateCard(
                        title: "No shared sheets",
                        message: "Sheets shared with you or by you will appear here.",
                        systemImage: "person.2",
                        accessibilityIdentifier: AccessibilityID.emptyState("sheets_shared_tab")
                    )
                } else {
                    ForEach(files) { file in
                        SpreadsheetRowView(
                            file: file,
                            preview: store.contentPreview(for: file),
                            subtitle: "Shared by \(file.ownerName)",
                            onOpen: { openSheet(file) },
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

    private func openSheet(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudSheets", targetApp: "Sheets")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}
