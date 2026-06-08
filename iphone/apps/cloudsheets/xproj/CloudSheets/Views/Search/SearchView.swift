import SwiftUI

struct SearchView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SpreadsheetActionCoordinator

    @State private var query = ""

    private var viewModel: SheetsSearchViewModel {
        SheetsSearchViewModel(store: store, query: query)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search Sheets", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("sheets_search_field")
                }

                Section("Results") {
                    if viewModel.results.isEmpty {
                        EmptyStateCard(
                            title: query.isEmpty ? "Search Sheets" : "No search results",
                            message: query.isEmpty ? "Search by spreadsheet title or cell preview." : "Try another query.",
                            systemImage: "magnifyingglass",
                            accessibilityIdentifier: AccessibilityID.emptyState(query.isEmpty ? "sheets_search_idle" : "sheets_search_empty")
                        )
                    } else {
                        ForEach(viewModel.results) { file in
                            SpreadsheetRowView(
                                file: file,
                                preview: store.contentPreview(for: file),
                                subtitle: store.pathString(for: file),
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
            }
            .navigationTitle("Search")
        }
    }

    private func openSheet(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudSheets", targetApp: "Sheets")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}
