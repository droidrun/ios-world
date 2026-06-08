import SwiftUI

struct MessagingListView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: MessageFilter = .focused
    @State private var searchText: String = ""
    @State private var selectedConversation: Conversation?
    @State private var showNewMessageSheet: Bool = false
    @State private var showMessageActions: Bool = false
    @State private var isSearching: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter pills
                filterPills

                // Conversation list
                if filteredConversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .background(LockedInTheme.cardBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if isSearching {
                            isSearching = false
                            searchText = ""
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: isSearching ? "chevron.left" : "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSearching ? LockedInTheme.primaryText : LockedInTheme.secondaryText)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if isSearching {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(LockedInTheme.secondaryText)
                                .font(.system(size: 14))
                            TextField("Search messages", text: $searchText)
                                .font(.system(size: 15))
                                .accessibilityIdentifier("messaging_search_field")
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(LockedInTheme.tertiaryText)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0xEDF3F8))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Button {
                            isSearching = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(LockedInTheme.secondaryText)
                                    .font(.system(size: 14))
                                Text("Search messages")
                                    .font(.system(size: 15))
                                    .foregroundColor(LockedInTheme.secondaryText)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: 0xEDF3F8))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            showMessageActions = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        Button {
                            showNewMessageSheet = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 18))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                }
            }
            .sheet(item: $selectedConversation) { conversation in
                ChatDetailView(conversation: conversation)
            }
            .sheet(isPresented: $showNewMessageSheet) {
                NewMessagePickerView(
                    selectedConversation: $selectedConversation,
                    showNewMessageSheet: $showNewMessageSheet
                )
            }
            .confirmationDialog("", isPresented: $showMessageActions) {
                Button("Mark all as read") {
                    for i in appState.conversations.indices {
                        appState.conversations[i].unreadCount = 0
                    }
                }
                Button("Manage messages") {
                    // Filters to unread
                    selectedFilter = .unread
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MessageFilter.allCases) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(filter.rawValue)
                                    .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .regular))
                                if filter == .focused && selectedFilter == filter {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9))
                                }
                            }
                            .foregroundColor(selectedFilter == filter ? .white : LockedInTheme.secondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? LockedInTheme.greenButton : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == filter ? Color.clear : LockedInTheme.separator, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider()
        }
    }

    // MARK: - Filtered Conversations

    private var filteredConversations: [Conversation] {
        var result: [Conversation]
        switch selectedFilter {
        case .focused: result = appState.conversations.filter { !$0.isSponsored }
        case .jobs: result = appState.conversations.filter { $0.isInMail && !$0.isSponsored }
        case .unread: result = appState.conversations.filter { $0.unreadCount > 0 }
        case .drafts: result = []
        case .inMail: result = appState.conversations.filter { $0.isInMail }
        }
        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.participantName.lowercased().contains(query) ||
                $0.messages.contains(where: { $0.content.lowercased().contains(query) })
            }
        }
        return result
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredConversations) { conversation in
                    conversationRow(conversation)
                }
            }
        }
    }

    private func conversationRow(_ conversation: Conversation) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar with active indicator
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        name: conversation.participantName,
                        initials: conversation.participantInitials,
                        topHex: conversation.participantAvatarTopHex,
                        bottomHex: conversation.participantAvatarBottomHex,
                        size: 48
                    )

                    if conversation.isActive {
                        Circle()
                            .fill(LockedInTheme.greenButton)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 2)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(conversation.participantName)
                            .font(.system(size: 15, weight: conversation.unreadCount > 0 ? .bold : .regular))
                            .foregroundColor(LockedInTheme.primaryText)
                            .lineLimit(1)

                        Spacer()

                        Text(conversation.lastMessageTimeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(conversation.unreadCount > 0 ? LockedInTheme.primaryText : LockedInTheme.tertiaryText)
                    }

                    HStack {
                        if conversation.isInMail {
                            Text("InMail")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(LockedInTheme.secondaryText)
                            Text("\u{2022}")
                                .font(.system(size: 6))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        if conversation.isSponsored {
                            Text("Sponsored")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(LockedInTheme.secondaryText)
                            Text("\u{2022}")
                                .font(.system(size: 6))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }

                        Text(conversation.lastMessagePreview)
                            .font(.system(size: 13))
                            .foregroundColor(conversation.unreadCount > 0 ? LockedInTheme.primaryText : LockedInTheme.secondaryText)
                            .lineLimit(2)

                        Spacer()

                        if conversation.unreadCount > 0 {
                            Circle()
                                .fill(LockedInTheme.linkedInBlue)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("\(conversation.unreadCount)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedConversation = conversation
            }
            .accessibilityIdentifier("messaging_conversation_row_" + conversation.participantName.lowercased().replacingOccurrences(of: " ", with: "_"))

            Divider()
                .padding(.leading, 76)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(LockedInTheme.tertiaryText)
            Text("No messages")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(LockedInTheme.primaryText)
            Text("Messages matching this filter will appear here.")
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - New Message Picker View

private struct NewMessagePickerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedConversation: Conversation?
    @Binding var showNewMessageSheet: Bool
    @State private var searchText: String = ""

    private var filteredConnections: [Connection] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return appState.connections
        }
        let query = searchText.lowercased()
        return appState.connections.filter {
            $0.fullName.lowercased().contains(query) ||
            $0.headline.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(LockedInTheme.secondaryText)
                        .font(.system(size: 14))
                    TextField("Search connections...", text: $searchText)
                        .font(.system(size: 15))
                        .accessibilityIdentifier("new_message_search_field")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: 0xEDF3F8))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()

                // Connections list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredConnections) { connection in
                            connectionRow(connection)
                        }
                    }
                }
            }
            .background(LockedInTheme.cardBackground)
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(LockedInTheme.primaryText)
                    }
                }
            }
        }
    }

    private func connectionRow(_ connection: Connection) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                AvatarView(
                    name: connection.fullName,
                    initials: connection.avatarInitials,
                    topHex: connection.avatarTopHex,
                    bottomHex: connection.avatarBottomHex,
                    size: 48
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(connection.fullName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                        .lineLimit(1)

                    Text(connection.headline)
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                let conversationId = appState.startNewConversation(with: connection)
                if let conversation = appState.conversations.first(where: { $0.id == conversationId }) {
                    showNewMessageSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedConversation = conversation
                    }
                }
            }
            .accessibilityIdentifier("new_message_connection_row_" + connection.fullName.lowercased().replacingOccurrences(of: " ", with: "_"))

            Divider()
                .padding(.leading, 76)
        }
    }
}
