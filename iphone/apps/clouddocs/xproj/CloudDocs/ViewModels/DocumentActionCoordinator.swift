import Foundation

@MainActor
final class DocumentActionCoordinator: ObservableObject {
    @Published var renameTargetId: String?
    @Published var renameValue = ""

    @Published var moveTargetId: String?
    @Published var moveSelection = ""

    @Published var shareFileId: String?
    @Published var sharePeopleText = ""
    @Published var shareRole: AccessRole = .viewer
    @Published var shareVisibility: SharedLinkVisibility = .restricted

    func beginRename(file: WorkspaceFile) {
        renameTargetId = file.id
        renameValue = file.name
    }

    func resetRename() {
        renameTargetId = nil
        renameValue = ""
    }

    func beginMove(file: WorkspaceFile) {
        moveTargetId = file.id
        moveSelection = file.parentFolderId ?? ""
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
