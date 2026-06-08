import SwiftUI

struct ThreadView: View {
    @ObservedObject var store: WorkspaceStore
    let channelId: String?
    let dmId: String?
    let messageId: String

    @State private var replyText: String = ""

    private var rootMessage: Message? {
        if let channelId,
           let channel = store.channel(with: channelId) {
            return channel.messages.first(where: { $0.id == messageId })
        }
        if let dmId,
           let dm = store.dm(with: dmId) {
            return dm.messages.first(where: { $0.id == messageId })
        }
        return nil
    }

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            VStack(spacing: 0) {
                if let rootMessage {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                MessageRowView(
                                    message: rootMessage,
                                    showThreadButton: false,
                                    mentionCurrentUser: rootMessage.mentionUserIds.contains(store.activeWorkspace?.currentUserId ?? ""),
                                    onToggleReaction: { emoji in
                                        if let channelId {
                                            store.toggleReactionOnChannelMessage(channelId: channelId, messageId: rootMessage.id, emoji: emoji)
                                        }
                                        if let dmId {
                                            store.toggleReactionOnDMMessage(dmId: dmId, messageId: rootMessage.id, emoji: emoji)
                                        }
                                    },
                                    onOpenThread: {}
                                )
                                .padding(.horizontal)

                                Divider().overlay(TeamChatPalette.divider)

                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(rootMessage.threadReplies) { reply in
                                        ThreadReplyRowView(
                                            reply: reply,
                                            senderName: store.member(with: reply.senderId)?.displayName ?? "Member",
                                            onToggleReaction: { emoji in
                                                store.toggleReactionOnThreadReply(
                                                    channelId: channelId,
                                                    dmId: dmId,
                                                    parentMessageId: rootMessage.id,
                                                    replyId: reply.id,
                                                    emoji: emoji
                                                )
                                            }
                                        )
                                        .id(reply.id)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 12)
                        }
                        .onAppear {
                            if let lastReply = rootMessage.threadReplies.last {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    proxy.scrollTo(lastReply.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: rootMessage.threadReplies.count) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                if let lastReply = rootMessage.threadReplies.last {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        proxy.scrollTo(lastReply.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }

                    Divider().overlay(TeamChatPalette.divider)

                    HStack(spacing: 8) {
                        TextField("Reply in thread", text: $replyText, axis: .vertical)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(TeamChatPalette.row))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(TeamChatPalette.divider, lineWidth: 1))
                            .submitLabel(.send)
                            .onSubmit {
                                if store.sendThreadReply(channelId: channelId, dmId: dmId, parentMessageId: messageId, text: replyText) {
                                    replyText = ""
                                }
                            }
                            .accessibilityIdentifier("thread_reply_composer_field")

                        Button("Send") {
                            let text = replyText
                            if store.sendThreadReply(channelId: channelId, dmId: dmId, parentMessageId: messageId, text: text) {
                                replyText = ""
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(TeamChatPalette.avatarRing, in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityIdentifier("thread_send_reply_button")
                    }
                    .padding()
                } else {
                    ContentUnavailableView("Thread not found", systemImage: "bubble.left.and.bubble.right")
                        .accessibilityIdentifier("thread_not_found_state")
                }
            }
        }
        .navigationTitle("Thread")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hidesRootChrome()
    }
}
