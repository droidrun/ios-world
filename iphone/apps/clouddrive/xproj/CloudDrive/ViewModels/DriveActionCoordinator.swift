import Foundation

@MainActor
final class DriveActionCoordinator: ObservableObject {
    @Published var detailFileId: String?

    @Published var renameTargetId: String?
    @Published var renameValue: String = ""

    @Published var moveTargetId: String?
    @Published var moveSelection: String = ""

    @Published var shareFileId: String?
    @Published var sharePeopleText: String = ""
    @Published var shareRole: AccessRole = .viewer
    @Published var shareVisibility: SharedLinkVisibility = .restricted

    func beginRename(itemId: String, currentName: String) {
        renameTargetId = itemId
        renameValue = currentName
    }

    func resetRename() {
        renameTargetId = nil
        renameValue = ""
    }

    func beginMove(itemId: String, currentParentId: String?) {
        moveTargetId = itemId
        moveSelection = currentParentId ?? ""
    }

    func resetMove() {
        moveTargetId = nil
        moveSelection = ""
    }

    func beginShare(file: WorkspaceFile) {
        shareFileId = file.id
        sharePeopleText = file.permissions.map(\.personName).joined(separator: ", ")
        shareRole = file.linkSettings.defaultRole
        shareVisibility = file.linkSettings.visibility
    }

    func resetShare() {
        shareFileId = nil
        sharePeopleText = ""
        shareRole = .viewer
        shareVisibility = .restricted
    }
}
