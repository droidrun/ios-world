import Foundation

@MainActor
final class ChannelsViewModel: StoreBackedViewModel {
    var workspaceName: String {
        store.activeWorkspace?.workspaceName ?? "Workspace"
    }

    var starredChannels: [Channel] {
        channels.filter(\.isStarred)
    }

    var unreadChannels: [Channel] {
        channels.filter { $0.unreadCount > 0 }
    }

    var publicChannels: [Channel] {
        channels.filter { $0.isPrivate == false }
    }

    var privateChannels: [Channel] {
        channels.filter(\.isPrivate)
    }

    private var channels: [Channel] {
        (store.activeWorkspace?.channels ?? []).sorted { $0.channelName < $1.channelName }
    }

    func toggleStar(_ channelId: String) {
        store.toggleChannelStar(channelId)
    }

    func toggleMute(_ channelId: String) {
        store.toggleChannelMute(channelId)
    }

    func markRead(_ channelId: String) {
        store.markChannelRead(channelId)
    }

    func markUnread(_ channelId: String) {
        store.markChannelUnread(channelId)
    }
}
