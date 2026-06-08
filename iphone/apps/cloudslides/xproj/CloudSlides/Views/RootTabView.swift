import SwiftUI
import UIKit

struct RootTabView: View {
    @ObservedObject var store: WorkspaceStore
    @StateObject private var coordinator = SlidesActionCoordinator()

    var body: some View {
        ZStack(alignment: .bottom) {
            HomeView(store: store, coordinator: coordinator)

            if let message = store.transientMessage {
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.88), in: Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .task(id: store.transientMessage) {
            guard store.transientMessage != nil else {
                return
            }

            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                store.transientMessage = nil
            }
        }
        .fullScreenCover(item: $store.activeEditorRoute) { route in
            SlidesEditorView(store: store, coordinator: coordinator, fileId: route.fileId)
                .sheet(item: Binding(
                    get: { coordinator.renameTargetId.map(EditorRoute.init(fileId:)) },
                    set: { coordinator.renameTargetId = $0?.fileId }
                )) { renameRoute in
                    RenameItemSheet(title: "Rename presentation", name: $coordinator.renameValue, onCancel: coordinator.resetRename) {
                        store.renameItem(id: renameRoute.fileId, newName: coordinator.renameValue)
                        coordinator.resetRename()
                    }
                }
                .sheet(item: Binding(
                    get: { coordinator.moveTargetId.map(EditorRoute.init(fileId:)) },
                    set: { coordinator.moveTargetId = $0?.fileId }
                )) { moveRoute in
                    MoveItemSheet(destinations: store.availableMoveDestinations(excluding: moveRoute.fileId), selection: $coordinator.moveSelection, onCancel: coordinator.resetMove) {
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
                        linkLabel: "slidessim://open?file=\(shareRoute.fileId)",
                        onCopyLink: {
                            UIPasteboard.general.string = "slidessim://open?file=\(shareRoute.fileId)"
                            store.transientMessage = "Local presentation link copied."
                        },
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
            RenameItemSheet(title: "Rename presentation", name: $coordinator.renameValue, onCancel: coordinator.resetRename) {
                store.renameItem(id: route.fileId, newName: coordinator.renameValue)
                coordinator.resetRename()
            }
        }
        .sheet(item: Binding(
            get: { coordinator.moveTargetId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.moveTargetId = $0?.fileId }
        )) { route in
            MoveItemSheet(destinations: store.availableMoveDestinations(excluding: route.fileId), selection: $coordinator.moveSelection, onCancel: coordinator.resetMove) {
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
                linkLabel: "slidessim://open?file=\(route.fileId)",
                onCopyLink: {
                    UIPasteboard.general.string = "slidessim://open?file=\(route.fileId)"
                    store.transientMessage = "Local presentation link copied."
                },
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
