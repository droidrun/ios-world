import SwiftUI
import UIKit

struct RootTabView: View {
    @ObservedObject var store: WorkspaceStore
    @StateObject private var coordinator = SpreadsheetActionCoordinator()
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        HomeView(store: store, coordinator: coordinator)
            .preferredColorScheme(.dark)
            .task {
                if store.envelope.selectedSourceType != .seeded {
                    store.switchSourceType(.seeded)
                }
            }
            .fullScreenCover(item: $store.activeEditorRoute) { route in
                SpreadsheetEditorView(store: store, coordinator: coordinator, fileId: route.fileId)
                    .sheet(item: Binding(
                        get: { coordinator.renameTargetId.map(EditorRoute.init(fileId:)) },
                        set: { coordinator.renameTargetId = $0?.fileId }
                    )) { renameRoute in
                        RenameItemSheet(title: "Rename spreadsheet", name: $coordinator.renameValue, onCancel: coordinator.resetRename) {
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
                            onCancel: coordinator.resetShare,
                            onCopyLink: {
                                UIPasteboard.general.string = store.shareLink(for: shareRoute.fileId)
                                store.transientMessage = "Share link copied"
                            }
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
                RenameItemSheet(title: "Rename spreadsheet", name: $coordinator.renameValue, onCancel: coordinator.resetRename) {
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
                    onCancel: coordinator.resetShare,
                    onCopyLink: {
                        UIPasteboard.general.string = store.shareLink(for: route.fileId)
                        store.transientMessage = "Share link copied"
                    }
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
            .overlay(alignment: .bottom) {
                if let message = store.transientMessage {
                    Text(message)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(SheetsTheme.chrome.opacity(0.96), in: Capsule())
                        .shadow(color: SheetsTheme.shadow, radius: 14, y: 8)
                        .padding(.bottom, 26)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: store.transientMessage)
            .onChange(of: store.transientMessage) { _, newMessage in
                toastTask?.cancel()
                guard newMessage != nil else { return }
                toastTask = Task {
                    try? await Task.sleep(for: .seconds(2.2))
                    if Task.isCancelled == false {
                        await MainActor.run {
                            store.transientMessage = nil
                        }
                    }
                }
            }
    }
}
