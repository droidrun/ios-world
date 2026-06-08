import SwiftUI

struct DMDetailView: View {
    @StateObject private var viewModel: DMDetailViewModel
    let focusMessageId: String?

    @State private var draftText: String = ""
    @State private var pendingAttachments: [MessageAttachment] = []
    @State private var threadMessageId: String?
    @State private var showCallSheet = false

    init(store: WorkspaceStore, dmId: String, focusMessageId: String? = nil) {
        _viewModel = StateObject(wrappedValue: DMDetailViewModel(store: store, dmId: dmId))
        self.focusMessageId = focusMessageId
    }

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            VStack(spacing: 0) {
                participantHeader

                Divider().overlay(TeamChatPalette.divider)

                if viewModel.messages.isEmpty {
                    emptyDMState
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.messages) { message in
                                    MessageRowView(
                                        message: message,
                                        showThreadButton: true,
                                        mentionCurrentUser: message.mentionUserIds.contains(viewModel.store.activeWorkspace?.currentUserId ?? ""),
                                        onToggleReaction: { emoji in
                                            viewModel.toggleMessageReaction(messageId: message.id, emoji: emoji)
                                        },
                                        onOpenThread: {
                                            threadMessageId = message.id
                                        }
                                    )
                                    .id(message.id)
                                    .padding(.horizontal)
                                    .background(message.id == focusMessageId ? Color.yellow.opacity(0.18) : Color.clear)
                                }
                            }
                        }
                        .onAppear {
                            if let focusMessageId {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        proxy.scrollTo(focusMessageId, anchor: .center)
                                    }
                                }
                            } else if let lastMessage = viewModel.messages.last {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.messages.count) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }

                Divider().overlay(TeamChatPalette.divider)

                composer
            }
        }
        .navigationTitle(viewModel.conversation?.name ?? "DM")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("Mark read") {
                        viewModel.markRead()
                    }
                    .accessibilityIdentifier("mark_dm_read_button")

                    Button("Mark unread") {
                        viewModel.markUnread()
                    }
                    .accessibilityIdentifier("mark_dm_unread_button")

                    Button((viewModel.conversation?.isMuted ?? false) ? "Unmute" : "Mute") {
                        viewModel.toggleMute()
                    }
                    .accessibilityIdentifier("toggle_dm_mute_button")
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.white)
                }

                Button("Call") {
                    showCallSheet = true
                }
                .foregroundStyle(.white)
                .accessibilityIdentifier("huddle_placeholder_button_dm")
            }
        }
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: Binding(
            get: {
                threadMessageId.map { IdentifiedString(id: $0) }
            },
            set: { value in
                threadMessageId = value?.id
            }
        )) { value in
            NavigationStack {
                ThreadView(store: viewModel.store, channelId: nil, dmId: viewModel.dmId, messageId: value.id)
            }
        }
        .sheet(isPresented: $showCallSheet) {
            NavigationStack {
                HuddlePlaceholderView(
                    title: "Call",
                    contextName: viewModel.conversation?.name ?? "Direct Message",
                    participantNames: viewModel.participants.map(\.displayName),
                    accessibilityPrefix: "dm_call_placeholder"
                )
            }
        }
        .hidesRootChrome()
        .onAppear {
            viewModel.markRead()
        }
    }

    private var participantHeader: some View {
        HStack(spacing: 10) {
            if let conversation = viewModel.conversation {
                if !conversation.isGroup, let other = otherParticipant {
                    TeamChatUserAvatar(displayName: other.displayName, fallbackInitials: initials(for: other.displayName), size: 28, cornerRadius: 8)
                        .accessibilityIdentifier("dm_header_avatar")
                    VStack(alignment: .leading, spacing: 0) {
                        Text(other.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("dm_header_name")
                        Text("Direct Message")
                            .font(.caption2)
                            .foregroundStyle(TeamChatPalette.subtleText)
                            .accessibilityIdentifier("dm_header_type")
                    }
                } else {
                    Text(conversation.isGroup ? "Group DM" : "Direct Message")
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("dm_header_type")
                }
                Spacer()
                Text("\(viewModel.participants.count) participant(s)")
                    .font(.caption)
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .accessibilityIdentifier("dm_header_participant_count")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var otherParticipant: WorkspaceMember? {
        let currentId = viewModel.store.activeWorkspace?.currentUserId
        return viewModel.participants.first(where: { $0.id != currentId })
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if pendingAttachments.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(pendingAttachments) { attachment in
                            Text(attachment.title)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(TeamChatPalette.row, in: Capsule())
                                .accessibilityIdentifier("composer_attachment_chip_\(attachment.id)")
                        }
                    }
                }
            }

            formattingToolbar

            HStack(spacing: 8) {
                TextField("Message", text: $draftText, axis: .vertical)
                    .lineLimit(1...4)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(TeamChatPalette.row))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(TeamChatPalette.divider, lineWidth: 1))
                    .submitLabel(.send)
                    .onSubmit {
                        if viewModel.sendMessage(text: draftText, attachments: pendingAttachments) {
                            draftText = ""
                            pendingAttachments.removeAll()
                        }
                    }
                    .accessibilityIdentifier("composer_text_field")

                Menu {
                    Button("Attach image") {
                        pendingAttachments.append(
                            MessageAttachment(
                                id: "draft_image_\(UUID().uuidString)",
                                attachmentType: .image,
                                title: "Screenshot.png",
                                subtitle: "Local attachment",
                                localPath: "Resources/draft_image.png"
                            )
                        )
                    }
                    .accessibilityIdentifier("composer_add_image_attachment_dm")
                    Button("Attach PDF") {
                        pendingAttachments.append(
                            MessageAttachment(
                                id: "draft_pdf_\(UUID().uuidString)",
                                attachmentType: .pdf,
                                title: "Document.pdf",
                                subtitle: "Local attachment",
                                localPath: "Resources/draft.pdf"
                            )
                        )
                    }
                    .accessibilityIdentifier("composer_add_pdf_attachment_dm")
                    Button("Attach link") {
                        pendingAttachments.append(
                            MessageAttachment(
                                id: "draft_link_\(UUID().uuidString)",
                                attachmentType: .link,
                                title: "Shared link",
                                subtitle: "internal://local/link",
                                localPath: "Resources/draft.link"
                            )
                        )
                    }
                    .accessibilityIdentifier("composer_add_link_attachment_dm")
                } label: {
                    Image(systemName: "paperclip")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(TeamChatPalette.row, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("composer_add_attachment_button_dm")

                Button("Send") {
                    if viewModel.sendMessage(text: draftText, attachments: pendingAttachments) {
                        draftText = ""
                        pendingAttachments = []
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(TeamChatPalette.avatarRing, in: RoundedRectangle(cornerRadius: 10))
                .accessibilityIdentifier("send_dm_message_button")
            }
        }
        .padding()
    }

    private var formattingToolbar: some View {
        HStack(spacing: 12) {
            Button {
                draftText += "*bold*"
            } label: {
                Text("B")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(TeamChatPalette.row, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("format_bold_button_dm")

            Button {
                draftText += "_italic_"
            } label: {
                Text("I")
                    .font(.subheadline.weight(.medium).italic())
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(TeamChatPalette.row, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("format_italic_button_dm")

            Button {
                draftText += "~strikethrough~"
            } label: {
                Text("S")
                    .font(.subheadline.weight(.medium))
                    .strikethrough()
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(TeamChatPalette.row, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("format_strikethrough_button_dm")

            Button {
                draftText += "`code`"
            } label: {
                Text("</>")
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(TeamChatPalette.row, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("format_code_button_dm")

            Spacer()
        }
        .accessibilityIdentifier("formatting_toolbar_dm")
    }

    private var emptyDMState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundStyle(TeamChatPalette.subtleText)

            Text("Start a new conversation")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Send a direct message, attach a file, or kick off a thread from the first reply.")
                .font(.subheadline)
                .foregroundStyle(TeamChatPalette.subtleText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .accessibilityIdentifier("empty_dm_history_state")
    }
}
