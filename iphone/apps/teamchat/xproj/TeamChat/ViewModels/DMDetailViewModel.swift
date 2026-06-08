import Foundation

@MainActor
final class DMDetailViewModel: StoreBackedViewModel {
    let dmId: String

    init(store: WorkspaceStore, dmId: String) {
        self.dmId = dmId
        super.init(store: store)
    }

    var conversation: DMConversation? {
        store.dm(with: dmId)
    }

    var messages: [Message] {
        (conversation?.messages ?? []).sorted(by: { $0.timestamp < $1.timestamp })
    }

    var participants: [WorkspaceMember] {
        guard let conversation else {
            return []
        }
        return conversation.participantIds.compactMap { store.member(with: $0) }
    }

    @discardableResult
    func sendMessage(text: String, attachments: [MessageAttachment]) -> Bool {
        store.sendDMMessage(dmId: dmId, text: text, attachments: attachments)
    }

    func toggleMessageReaction(messageId: String, emoji: String = "👍") {
        store.toggleReactionOnDMMessage(dmId: dmId, messageId: messageId, emoji: emoji)
    }

    @discardableResult
    func sendThreadReply(parentMessageId: String, text: String) -> Bool {
        store.sendThreadReply(channelId: nil, dmId: dmId, parentMessageId: parentMessageId, text: text)
    }

    func toggleThreadReplyReaction(parentMessageId: String, replyId: String, emoji: String = "👍") {
        store.toggleReactionOnThreadReply(channelId: nil, dmId: dmId, parentMessageId: parentMessageId, replyId: replyId, emoji: emoji)
    }

    func markRead() {
        store.markDMRead(dmId)
    }

    func markUnread() {
        store.markDMUnread(dmId)
    }

    func toggleMute() {
        store.toggleDMMute(dmId)
    }
}
