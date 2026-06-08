import SwiftUI

struct ChatDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let conversation: Conversation
    @State private var messageText: String = ""
    @State private var showProfile: Bool = false
    @State private var showChatActions: Bool = false
    @State private var isStarred: Bool = false
    @State private var reactedMessages: Set<String> = []
    @State private var showAttachmentAlert: Bool = false
    @State private var showVoiceAlert: Bool = false
    @State private var showTypingIndicator: Bool = false

    private var currentConversation: Conversation {
        appState.conversations.first(where: { $0.id == conversation.id }) ?? conversation
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                messagesScrollView

                // Smart replies
                if currentConversation.messages.last?.isFromCurrentUser == false {
                    smartReplies
                }

                // Input bar
                inputBar
            }
            .background(LockedInTheme.cardBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        showProfile = true
                    } label: {
                        VStack(spacing: 1) {
                            Text(conversation.participantName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText)
                            if conversation.isActive {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(LockedInTheme.greenButton)
                                        .frame(width: 6, height: 6)
                                    Text("Active now")
                                        .font(.system(size: 11))
                                        .foregroundColor(LockedInTheme.greenButton)
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("chat_profile_button")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showChatActions = true } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        Button { isStarred.toggle() } label: {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundColor(isStarred ? LockedInTheme.premiumGold : LockedInTheme.secondaryText)
                        }
                    }
                }
            }
            .confirmationDialog("", isPresented: $showChatActions) {
                Button("Mute conversation") {
                    appState.markConversationRead(conversation.id)
                }
                Button("Delete conversation", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Add Attachment", isPresented: $showAttachmentAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Photo, video, and file attachments are not available in this version.")
            }
            .alert("Voice Message", isPresented: $showVoiceAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Voice messages are not available in this version. Try typing your message instead.")
            }
            .sheet(isPresented: $showProfile) {
                let conn = appState.connections.first(where: {
                    $0.fullName == conversation.participantName
                })
                ProfileView(connection: conn, isCurrentUser: false)
            }
            .onAppear {
                appState.markConversationRead(conversation.id)
            }
        }
    }

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Profile card at top
                    profileCard

                    // Date separator
                    if let firstMsg = currentConversation.messages.first {
                        dateSeparator(firstMsg.timestamp)
                    }

                    // Messages
                    ForEach(currentConversation.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    // Read receipt under last user message
                    if let lastMsg = currentConversation.messages.last, lastMsg.isFromCurrentUser {
                        HStack {
                            Spacer()
                            Text("Seen")
                                .font(.system(size: 11))
                                .foregroundColor(LockedInTheme.tertiaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
                    }

                    // Typing indicator
                    if showTypingIndicator {
                        HStack(spacing: 8) {
                            AvatarView(
                                name: conversation.participantName,
                                initials: conversation.participantInitials,
                                topHex: conversation.participantAvatarTopHex,
                                bottomHex: conversation.participantAvatarBottomHex,
                                size: 28
                            )
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { i in
                                    Circle()
                                        .fill(LockedInTheme.tertiaryText)
                                        .frame(width: 6, height: 6)
                                        .opacity(0.6)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: 0xF2F2F2))
                            )
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.opacity)
                        .id("typing-indicator")
                    }

                    Spacer().frame(height: 16)
                }
            }
            .onAppear {
                if let lastId = currentConversation.messages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
            .onChange(of: currentConversation.messages.count) { _, _ in
                if let lastMsg = currentConversation.messages.last, !lastMsg.isFromCurrentUser {
                    withAnimation { showTypingIndicator = false }
                }
                if let lastId = currentConversation.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: showTypingIndicator) { _, isShowing in
                if isShowing {
                    withAnimation {
                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)

            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    name: conversation.participantName,
                    initials: conversation.participantInitials,
                    topHex: conversation.participantAvatarTopHex,
                    bottomHex: conversation.participantAvatarBottomHex,
                    size: 80
                )
                if conversation.isActive {
                    Circle()
                        .fill(LockedInTheme.greenButton)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                }
            }

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(conversation.participantName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.linkedInBlue)

                    Text("\u{2022} 1st")
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.secondaryText)
                }

                Text(conversation.participantHeadline)
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Date Separator

    private func dateSeparator(_ date: Date) -> some View {
        HStack {
            Rectangle()
                .fill(LockedInTheme.separator)
                .frame(height: 0.5)
            Text(date.linkedInDateLabel())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(LockedInTheme.tertiaryText)
                .padding(.horizontal, 8)
            Rectangle()
                .fill(LockedInTheme.separator)
                .frame(height: 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: LockedInMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            } else {
                AvatarView(
                    name: conversation.participantName,
                    initials: conversation.participantInitials,
                    topHex: conversation.participantAvatarTopHex,
                    bottomHex: conversation.participantAvatarBottomHex,
                    size: 28
                )
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if !message.isFromCurrentUser {
                        Text(conversation.participantName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(LockedInTheme.primaryText)
                        Text("\u{2022}")
                            .font(.system(size: 6))
                            .foregroundColor(LockedInTheme.tertiaryText)
                    }
                    Text(message.timestamp.linkedInMessageTime())
                        .font(.system(size: 11))
                        .foregroundColor(LockedInTheme.tertiaryText)
                }

                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(LockedInTheme.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isFromCurrentUser ? Color(hex: 0xD8E8F8) : Color(hex: 0xF2F2F2))
                    )

                // Reaction emoji button
                HStack(spacing: 4) {
                    Button {
                        if reactedMessages.contains(message.id) {
                            reactedMessages.remove(message.id)
                        } else {
                            reactedMessages.insert(message.id)
                        }
                    } label: {
                        if reactedMessages.contains(message.id) {
                            Text("\u{1F44D}")
                                .font(.system(size: 14))
                        } else {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 14))
                                .foregroundColor(LockedInTheme.tertiaryText)
                        }
                    }
                }
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - Smart Replies

    private var smartReplies: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                smartReplyButton("Thanks, \(conversation.participantName.components(separatedBy: " ").first ?? "")!")
                smartReplyButton("Sounds great!")
                smartReplyButton("Let's connect")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(hex: 0xF8F8F8))
    }

    private func smartReplyButton(_ text: String) -> some View {
        Button {
            appState.sendMessage(in: conversation.id, content: text)
            let convoId = conversation.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                if currentConversation.messages.last?.isFromCurrentUser == true {
                    withAnimation { showTypingIndicator = true }
                }
            }
            appState.generateReply(in: convoId, userMessage: text)
        } label: {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(LockedInTheme.linkedInBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                )
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                Button(action: { showAttachmentAlert = true }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 20))
                        .foregroundColor(LockedInTheme.secondaryText)
                }

                HStack {
                    TextField("Write a message...", text: $messageText)
                        .font(.system(size: 14))
                        .accessibilityIdentifier("chat_message_field")
                        .onSubmit {
                            let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }
                            appState.sendMessage(in: conversation.id, content: text)
                            messageText = ""
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                                if currentConversation.messages.last?.isFromCurrentUser == true {
                                    withAnimation { showTypingIndicator = true }
                                }
                            }
                            appState.generateReply(in: conversation.id, userMessage: text)
                        }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LockedInTheme.separator, lineWidth: 1)
                )

                if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: { showVoiceAlert = true }) {
                        Image(systemName: "mic")
                            .font(.system(size: 20))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                } else {
                    Button {
                        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        appState.sendMessage(in: conversation.id, content: text)
                        messageText = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                            if currentConversation.messages.last?.isFromCurrentUser == true {
                                withAnimation { showTypingIndicator = true }
                            }
                        }
                        appState.generateReply(in: conversation.id, userMessage: text)
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                    }
                    .accessibilityIdentifier("chat_send_button")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Date Label Extension

extension Date {
    func linkedInDateLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self).uppercased()
    }
}
