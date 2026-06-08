import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: WorkspaceStore
    @StateObject private var coordinator = DocumentActionCoordinator()

    var body: some View {
        HomeView(store: store, coordinator: coordinator)
            .preferredColorScheme(.dark)
            .fullScreenCover(item: $store.activeEditorRoute) { route in
                DocumentEditorView(store: store, coordinator: coordinator, fileId: route.fileId)
                    .preferredColorScheme(.dark)
                    .sheet(item: Binding(
                        get: { coordinator.renameTargetId.map(EditorRoute.init(fileId:)) },
                        set: { coordinator.renameTargetId = $0?.fileId }
                    )) { renameRoute in
                        RenameItemSheet(
                            title: "Rename document",
                            name: $coordinator.renameValue,
                            onCancel: coordinator.resetRename
                        ) {
                            store.renameItem(id: renameRoute.fileId, newName: coordinator.renameValue)
                            coordinator.resetRename()
                        }
                    }
                    .sheet(item: Binding(
                        get: { coordinator.moveTargetId.map(EditorRoute.init(fileId:)) },
                        set: { coordinator.moveTargetId = $0?.fileId }
                    )) { moveRoute in
                        MoveItemSheet(
                            destinations: store.availableMoveDestinations(excluding: moveRoute.fileId),
                            selection: $coordinator.moveSelection,
                            onCancel: coordinator.resetMove
                        ) {
                            let destination = coordinator.moveSelection.isEmpty ? nil : coordinator.moveSelection
                            store.moveItem(id: moveRoute.fileId, toFolderId: destination)
                            coordinator.resetMove()
                        }
                    }
                    .sheet(item: Binding(
                        get: { coordinator.shareFileId.map(EditorRoute.init(fileId:)) },
                        set: { coordinator.shareFileId = $0?.fileId }
                    )) { shareRoute in
                        ShareSettingsSheet(
                            peopleText: $coordinator.sharePeopleText,
                            role: $coordinator.shareRole,
                            visibility: $coordinator.shareVisibility,
                            contacts: store.contacts,
                            shareLink: "https://clouddocs.example/document/d/\(shareRoute.fileId)/edit?usp=sharing",
                            onCancel: coordinator.resetShare
                        ) {
                            store.updateShareSettings(
                                fileId: shareRoute.fileId,
                                peopleNames: coordinator.sharePeopleText,
                                role: coordinator.shareRole,
                                visibility: coordinator.shareVisibility
                            )
                            coordinator.resetShare()
                        }
                    }
            }
            .sheet(item: Binding(
                get: { coordinator.renameTargetId.map(EditorRoute.init(fileId:)) },
                set: { coordinator.renameTargetId = $0?.fileId }
            )) { route in
                RenameItemSheet(
                    title: "Rename document",
                    name: $coordinator.renameValue,
                    onCancel: coordinator.resetRename
                ) {
                    store.renameItem(id: route.fileId, newName: coordinator.renameValue)
                    coordinator.resetRename()
                }
            }
            .sheet(item: Binding(
                get: { coordinator.moveTargetId.map(EditorRoute.init(fileId:)) },
                set: { coordinator.moveTargetId = $0?.fileId }
            )) { route in
                MoveItemSheet(
                    destinations: store.availableMoveDestinations(excluding: route.fileId),
                    selection: $coordinator.moveSelection,
                    onCancel: coordinator.resetMove
                ) {
                    let destination = coordinator.moveSelection.isEmpty ? nil : coordinator.moveSelection
                    store.moveItem(id: route.fileId, toFolderId: destination)
                    coordinator.resetMove()
                }
            }
            .sheet(item: Binding(
                get: { coordinator.shareFileId.map(EditorRoute.init(fileId:)) },
                set: { coordinator.shareFileId = $0?.fileId }
            )) { route in
                ShareSettingsSheet(
                    peopleText: $coordinator.sharePeopleText,
                    role: $coordinator.shareRole,
                    visibility: $coordinator.shareVisibility,
                    contacts: store.contacts,
                    shareLink: "https://clouddocs.example/document/d/\(route.fileId)/edit?usp=sharing",
                    onCancel: coordinator.resetShare
                ) {
                    store.updateShareSettings(
                        fileId: route.fileId,
                        peopleNames: coordinator.sharePeopleText,
                        role: coordinator.shareRole,
                        visibility: coordinator.shareVisibility
                    )
                    coordinator.resetShare()
                }
            }
            .alert(item: $store.activeAlert) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")) {
                    store.dismissAlert()
                })
            }
    }
}
