import SwiftUI

struct SearchView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DocumentActionCoordinator

    @State private var query = ""

    private var viewModel: DocumentsSearchViewModel {
        DocumentsSearchViewModel(store: store, query: query)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search Docs", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("docs_search_field")
                }

                Section("Results") {
                    if viewModel.results.isEmpty {
                        EmptyStateCard(
                            title: query.isEmpty ? "Search Docs" : "No search results",
                            message: query.isEmpty ? "Search by document name or content preview text." : "Try a different query.",
                            systemImage: "magnifyingglass",
                            accessibilityIdentifier: AccessibilityID.emptyState(query.isEmpty ? "docs_search_idle" : "docs_search_empty")
                        )
                    } else {
                        ForEach(viewModel.results) { file in
                            DocumentRowView(
                                file: file,
                                preview: store.contentPreview(for: file),
                                subtitle: store.pathString(for: file),
                                onOpen: { openDocument(file) },
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

    private func openDocument(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudDocs", targetApp: "Docs")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}
