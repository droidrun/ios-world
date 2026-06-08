import SwiftUI
import UniformTypeIdentifiers

struct MoreView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DocumentActionCoordinator

    @State private var showImporter = false

    private var trashedDocuments: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .document && $0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Workspace data") {
                    ForEach(WorkspaceSourceType.allCases) { sourceType in
                        Button {
                            store.switchSourceType(sourceType)
                        } label: {
                            HStack {
                                Text(sourceType.title)
                                Spacer()
                                if store.envelope.selectedSourceType == sourceType {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }

                    if let metadata = store.currentMetadata {
                        Text(metadata.providerLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Snapshot import") {
                    Button("Import sandbox snapshot JSON") {
                        showImporter = true
                    }

                    Button("Reload snapshot state") {
                        store.reloadSnapshots()
                    }
                }

                Section("Trash") {
                    if trashedDocuments.isEmpty {
                        EmptyStateCard(
                            title: "No trashed docs",
                            message: "Trashed documents can be restored from here.",
                            systemImage: "trash",
                            accessibilityIdentifier: AccessibilityID.emptyState("docs_trash")
                        )
                    } else {
                        ForEach(trashedDocuments) { file in
                            DocumentRowView(
                                file: file,
                                preview: store.contentPreview(for: file),
                                subtitle: "Trashed \(AppFormatters.shortDate.string(from: file.updatedAt))",
                                onOpen: { openDocument(file) },
                                onRename: { coordinator.beginRename(file: file) },
                                onMove: { coordinator.beginMove(file: file) },
                                onDuplicate: { _ = store.duplicateFile(id: file.id) },
                                onShare: { coordinator.beginShare(file: file) },
                                onTrashOrRestore: { store.restoreItem(id: file.id) }
                            )
                        }
                    }
                }

                Section("Profile") {
                    Button("Reset app state") {
                        store.resetAppState()
                    }
                    .foregroundStyle(.red)
                    .accessibilityIdentifier(AccessibilityID.profileResetAppState)
                }
            }
            .navigationTitle("More")
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    store.importSnapshot(from: url)
                case .failure(let error):
                    store.activeAlert = AppAlert(id: "docs_import_failed", title: "Import failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func openDocument(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudDocs", targetApp: "Docs")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}
