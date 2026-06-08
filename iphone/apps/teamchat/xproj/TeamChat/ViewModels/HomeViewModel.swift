import Foundation

@MainActor
final class HomeViewModel: StoreBackedViewModel {
    var workspaceName: String {
        store.activeWorkspace?.workspaceName ?? "Workspace"
    }

    var recentDMs: [DMConversation] {
        store.recentDMs()
    }

    var currentUser: WorkspaceMember? {
        store.currentUser
    }

    var threadCount: Int {
        store.activityItems(for: .threads).count
    }

    var savedCount: Int {
        store.savedItems().count
    }

    var draftsCount: Int {
        store.activeWorkspace?.draftsCount ?? 0
    }

    var catchUpCount: Int {
        let channelUnreads = store.activeWorkspace?.channels.reduce(0) { $0 + $1.unreadCount } ?? 0
        let dmUnreads = store.activeWorkspace?.dmConversations.reduce(0) { $0 + $1.unreadCount } ?? 0
        return channelUnreads + dmUnreads
    }

    func goToChannels() {
        store.switchTab(.channels)
    }
}
