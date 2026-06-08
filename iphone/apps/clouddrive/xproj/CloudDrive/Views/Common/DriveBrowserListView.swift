import SwiftUI

struct DriveBrowserListView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DriveActionCoordinator
    let items: [BrowserItem]
    let showPath: Bool
    let emptyTitle: String
    let emptyMessage: String
    let emptyAccessibilityID: String
    let openFile: (WorkspaceFile) -> Void

    var body: some View {
        if items.isEmpty {
            EmptyStateCard(
                title: emptyTitle,
                message: emptyMessage,
                systemImage: "tray",
                accessibilityIdentifier: emptyAccessibilityID
            )
        } else {
            ForEach(items, id: \.id) { item in
                switch item {
                case .folder(let folder):
                    NavigationLink {
                        FolderBrowserView(store: store, coordinator: coordinator, folderId: folder.id)
                    } label: {
                        DriveFolderRowView(
                            folder: folder,
                            onRename: {
                                coordinator.beginRename(itemId: folder.id, currentName: folder.name)
                            },
                            onMove: {
                                coordinator.beginMove(itemId: folder.id, currentParentId: folder.parentFolderId)
                            },
                            onToggleStar: {
                                store.toggleStar(itemId: folder.id)
                            },
                            onTrashOrRestore: {
                                folder.trashed ? store.restoreItem(id: folder.id) : store.trashItem(id: folder.id)
                            }
                        )
                    }
                    .buttonStyle(.plain)

                case .file(let file):
                    DriveFileRowView(
                        file: file,
                        preview: preview(for: file),
                        onOpen: {
                            openFile(file)
                        },
                        onDetails: {
                            coordinator.detailFileId = file.id
                        },
                        onRename: {
                            coordinator.beginRename(itemId: file.id, currentName: file.name)
                        },
                        onMove: {
                            coordinator.beginMove(itemId: file.id, currentParentId: file.parentFolderId)
                        },
                        onShare: {
                            coordinator.beginShare(file: file)
                        },
                        onDuplicate: {
                            _ = store.duplicateFile(id: file.id)
                        },
                        onToggleStar: {
                            store.toggleStar(itemId: file.id)
                        },
                        onTrashOrRestore: {
                            file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id)
                        }
                    )
                }
            }
        }
    }

    private func preview(for file: WorkspaceFile) -> String {
        let content = store.contentPreview(for: file)
        guard showPath else {
            return content
        }
        return "\(store.pathString(for: file)) • \(content)"
    }
}
