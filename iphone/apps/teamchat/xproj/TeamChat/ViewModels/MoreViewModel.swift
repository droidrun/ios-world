import Foundation

@MainActor
final class MoreViewModel: StoreBackedViewModel {
    var profile: UserProfile? {
        store.activeWorkspace?.userProfile
    }

    var workspaces: [Workspace] {
        store.availableWorkspaces
    }

    var sourceType: WorkspaceSourceType {
        store.sourceType
    }

    var metadata: WorkspaceSnapshotMetadata? {
        store.activeWorkspace?.metadata
    }

    var draftsCount: Int {
        store.activeWorkspace?.draftsCount ?? 0
    }

    func switchSource(_ source: WorkspaceSourceType) {
        store.switchDataSource(to: source)
    }

    func switchWorkspace(_ workspaceId: String) {
        store.switchWorkspace(to: workspaceId)
    }

    func reloadSnapshot() {
        store.reloadBundledSnapshotData()
    }

    func resetAppState() {
        store.resetAppState()
    }

    func updatePushEnabled(_ enabled: Bool) {
        store.updateNotificationPreference(pushEnabled: enabled)
    }

    func updateMentionOnly(_ enabled: Bool) {
        store.updateNotificationPreference(mentionOnly: enabled)
    }

    func updateThreadReplies(_ enabled: Bool) {
        store.updateNotificationPreference(threadRepliesEnabled: enabled)
    }

    func updateHuddleInvites(_ enabled: Bool) {
        store.updateNotificationPreference(huddleInvitesEnabled: enabled)
    }
}
