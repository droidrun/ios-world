import SwiftUI
import UIKit

struct SharedView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DriveActionCoordinator

    var body: some View {
        NavigationStack {
            List {
                DriveBrowserListView(
                    store: store,
                    coordinator: coordinator,
                    items: store.sharedItems(),
                    showPath: true,
                    emptyTitle: "No shared files",
                    emptyMessage: "Shared items will appear here when access is granted locally.",
                    emptyAccessibilityID: AccessibilityID.emptyState("no_shared_files"),
                    openFile: openFile
                )
            }
            .navigationTitle("Shared")
        }
        .sheet(item: Binding(
            get: { coordinator.detailFileId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.detailFileId = $0?.fileId }
        )) { route in
            NavigationStack {
                FileDetailView(
                    store: store,
                    fileId: route.fileId,
                    onOpen: {
                        if let file = store.file(id: route.fileId) {
                            openFile(file)
                        }
                    },
                    onShare: {
                        if let file = store.file(id: route.fileId) {
                            coordinator.beginShare(file: file)
                            coordinator.detailFileId = nil
                        }
                    }
                )
            }
        }
        .sheet(item: Binding(
            get: { coordinator.renameTargetId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.renameTargetId = $0?.fileId }
        )) { route in
            RenameItemSheet(title: "Rename", name: $coordinator.renameValue, onCancel: coordinator.resetRename) {
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
                linkDescription: shareLinkText(for: route.fileId),
                onCancel: coordinator.resetShare,
                onCopyLink: { copyShareLink(fileId: route.fileId) }
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
    }

    private func shareLinkText(for fileId: String) -> String {
        "clouddrive.example/file/d/\(fileId)/view"
    }

    private func copyShareLink(fileId: String) {
        UIPasteboard.general.string = "https://\(shareLinkText(for: fileId))"
        store.registerShareLinkCopy(fileId: fileId)
    }

    private func openFile(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudDrive", targetApp: file.fileType.title)
        guard let url = URL(string: "\(file.fileType.editorScheme)://open?file=\(file.id)") else { return }
        UIApplication.shared.open(url) { success in
            if success == false {
                store.activeAlert = AppAlert(id: "handoff_target_unavailable_\(file.id)", title: "Handoff target unavailable", message: "Launch the matching editor app to open this file.")
            }
        }
    }
}
