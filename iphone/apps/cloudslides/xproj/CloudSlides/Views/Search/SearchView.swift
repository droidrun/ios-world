import SwiftUI

struct SearchView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SlidesActionCoordinator

    @State private var query = ""

    private var viewModel: SlidesSearchViewModel {
        SlidesSearchViewModel(store: store, query: query)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search Slides", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("slides_search_field")
                }

                Section("Results") {
                    if viewModel.results.isEmpty {
                        EmptyStateCard(
                            title: query.isEmpty ? "Search Slides" : "No search results",
                            message: query.isEmpty ? "Search by deck title or slide content preview." : "Try another query.",
                            systemImage: "magnifyingglass",
                            accessibilityIdentifier: AccessibilityID.emptyState(query.isEmpty ? "slides_search_idle" : "slides_search_empty")
                        )
                    } else {
                        ForEach(viewModel.results) { file in
                            SlideDeckRowView(
                                file: file,
                                preview: store.contentPreview(for: file),
                                subtitle: store.pathString(for: file),
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
            }
            .navigationTitle("Search")
        }
    }

    private func openDeck(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudSlides", targetApp: "Slides")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}
