import Foundation

@MainActor
final class ChannelDetailViewModel: StoreBackedViewModel {
    let channelId: String

    init(store: WorkspaceStore, channelId: String) {
        self.channelId = channelId
        super.init(store: store)
    }

    var channel: Channel? {
        store.channel(with: channelId)
    }

    var channelMessages: [Message] {
        (channel?.messages ?? []).sorted(by: { $0.timestamp < $1.timestamp })
    }

    var memberCount: Int {
        channel?.memberIds.count ?? 0
    }

    var members: [WorkspaceMember] {
        guard let channel else {
            return []
        }
        return channel.memberIds.compactMap { store.member(with: $0) }
    }

    @discardableResult
    func sendMessage(text: String, attachments: [MessageAttachment]) -> Bool {
        store.sendChannelMessage(channelId: channelId, text: text, attachments: attachments)
    }

    func toggleMessageReaction(messageId: String, emoji: String = "👍") {
        store.toggleReactionOnChannelMessage(channelId: channelId, messageId: messageId, emoji: emoji)
    }

    func markRead() {
        store.markChannelRead(channelId)
    }

    func markUnread() {
        store.markChannelUnread(channelId)
    }

    func toggleMute() {
        store.toggleChannelMute(channelId)
    }

    func toggleStar() {
        store.toggleChannelStar(channelId)
    }

    func toggleNotificationPreference() {
        store.toggleChannelNotificationPreference(channelId)
    }

    @discardableResult
    func leaveChannel() -> Bool {
        store.leaveChannel(channelId)
    }

    @discardableResult
    func sendThreadReply(parentMessageId: String, text: String) -> Bool {
        store.sendThreadReply(channelId: channelId, dmId: nil, parentMessageId: parentMessageId, text: text)
    }

    func toggleThreadReplyReaction(parentMessageId: String, replyId: String, emoji: String = "👍") {
        store.toggleReactionOnThreadReply(channelId: channelId, dmId: nil, parentMessageId: parentMessageId, replyId: replyId, emoji: emoji)
    }
}
