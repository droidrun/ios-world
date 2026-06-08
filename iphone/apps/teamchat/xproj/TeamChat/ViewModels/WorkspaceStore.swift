import Foundation

enum PendingUIAction: Equatable {
    case presentNewDMComposer
}

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var seededWorkspaces: [Workspace] = []
    @Published private(set) var snapshotWorkspaces: [Workspace] = []
    @Published var sourceType: WorkspaceSourceType = .seeded
    @Published var seededWorkspaceId: String = ""
    @Published var snapshotWorkspaceId: String = ""
    @Published var selectedTab: AppTab = .home
    @Published var recentSearches: [String] = []
    @Published var appAlert: AppAlert?
    @Published var pendingUIAction: PendingUIAction?

    private let seededRepository: WorkspaceRepository
    private let snapshotRepository: WorkspaceRepository
    private let persistence: AppStatePersistence

    init(
        seededRepository: WorkspaceRepository = SeededWorkspaceRepository(),
        snapshotRepository: WorkspaceRepository = SnapshotWorkspaceRepository(),
        persistence: AppStatePersistence = AppStatePersistence()
    ) {
        self.seededRepository = seededRepository
        self.snapshotRepository = snapshotRepository
        self.persistence = persistence
        bootstrap()
    }

    var activeWorkspace: Workspace? {
        switch sourceType {
        case .seeded:
            return seededWorkspaces.first(where: { $0.id == seededWorkspaceId }) ?? seededWorkspaces.first
        case .snapshot:
            return snapshotWorkspaces.first(where: { $0.id == snapshotWorkspaceId }) ?? snapshotWorkspaces.first
        }
    }

    var activeWorkspaceId: String {
        switch sourceType {
        case .seeded:
            return seededWorkspaceId
        case .snapshot:
            return snapshotWorkspaceId
        }
    }

    var currentSourceLabel: String {
        sourceType.label
    }

    var availableWorkspaces: [Workspace] {
        switch sourceType {
        case .seeded:
            return seededWorkspaces
        case .snapshot:
            return snapshotWorkspaces
        }
    }

    var currentUser: WorkspaceMember? {
        guard let workspace = activeWorkspace else {
            return nil
        }
        return workspace.members.first(where: { $0.id == workspace.currentUserId })
    }

    var unreadChannelCount: Int {
        activeWorkspace?.channels.reduce(0) { $0 + $1.unreadCount } ?? 0
    }

    var unreadDMCount: Int {
        activeWorkspace?.dmConversations.reduce(0) { $0 + $1.unreadCount } ?? 0
    }

    var mentionCount: Int {
        let channelMentions = activeWorkspace?.channels.reduce(0) { $0 + $1.mentionCount } ?? 0
        let dmMentions = activeWorkspace?.dmConversations.reduce(0) { $0 + $1.mentionCount } ?? 0
        return channelMentions + dmMentions
    }

    func switchTab(_ tab: AppTab) {
        selectedTab = tab
        saveState()
    }

    func dismissAlert() {
        appAlert = nil
    }

    func openNewDMComposer() {
        selectedTab = .dms
        pendingUIAction = .presentNewDMComposer
        saveState()
    }

    func consumePendingUIAction(_ action: PendingUIAction) {
        guard pendingUIAction == action else {
            return
        }
        pendingUIAction = nil
    }

    func switchWorkspace(to workspaceId: String) {
        switch sourceType {
        case .seeded:
            guard seededWorkspaces.contains(where: { $0.id == workspaceId }) else {
                return
            }
            seededWorkspaceId = workspaceId
        case .snapshot:
            guard snapshotWorkspaces.contains(where: { $0.id == workspaceId }) else {
                return
            }
            snapshotWorkspaceId = workspaceId
        }
        saveState()
    }

    @discardableResult
    func addWorkspace(named name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            setAlert(
                id: "workspace_add_empty_name",
                title: "Unable to add workspace",
                message: "Enter a workspace name.",
                confirmButtonTitle: "OK"
            )
            return false
        }

        guard let template = activeWorkspace ?? seededWorkspaces.first else {
            return false
        }

        let baseSlug = trimmed.accessibilitySlug
        var workspaceId = "workspace_local_\(baseSlug)"
        var suffix = 1
        while seededWorkspaces.contains(where: { $0.id == workspaceId }) {
            suffix += 1
            workspaceId = "workspace_local_\(baseSlug)_\(suffix)"
        }

        var workspace = template
        workspace.id = workspaceId
        workspace.workspaceName = trimmed
        workspace.sourceType = .seeded
        workspace.metadata = WorkspaceSnapshotMetadata(
            sourceLabel: "Local Workspace",
            sourceType: .seeded,
            snapshotTimestamp: Date(),
            lastUpdated: template.lastUpdated
        )
        workspace.recalculateDerivedFields()
        workspace.ensureNextSequence()

        seededWorkspaces.insert(workspace, at: 0)
        sourceType = .seeded
        seededWorkspaceId = workspaceId
        saveState()
        return true
    }

    func updateNotificationPreference(
        pushEnabled: Bool? = nil,
        mentionOnly: Bool? = nil,
        threadRepliesEnabled: Bool? = nil,
        huddleInvitesEnabled: Bool? = nil
    ) {
        mutateActiveWorkspace { workspace in
            var preference = workspace.userProfile.notificationPreference
            if let pushEnabled {
                preference.pushEnabled = pushEnabled
            }
            if let mentionOnly {
                preference.mentionOnly = mentionOnly
            }
            if let threadRepliesEnabled {
                preference.threadRepliesEnabled = threadRepliesEnabled
            }
            if let huddleInvitesEnabled {
                preference.huddleInvitesEnabled = huddleInvitesEnabled
            }
            workspace.userProfile.notificationPreference = preference
        }
    }

    func updateCurrentUserStatus(_ statusText: String) {
        mutateActiveWorkspace { workspace in
            workspace.userProfile.statusText = statusText
        }
    }

    func updateCurrentUserPresence(_ presence: PresenceState) {
        mutateActiveWorkspace { workspace in
            workspace.userProfile.presenceState = presence
            if let memberIndex = workspace.members.firstIndex(where: { $0.id == workspace.currentUserId }) {
                workspace.members[memberIndex].presenceState = presence
            }
        }
    }

    func showPlaceholderAlert(id: String, title: String, message: String) {
        setAlert(id: id, title: title, message: message, confirmButtonTitle: "OK")
    }

    func switchDataSource(to source: WorkspaceSourceType) {
        guard sourceType != source else {
            return
        }

        if source == .snapshot, snapshotWorkspaces.isEmpty {
            setAlert(
                id: "snapshot_unavailable",
                title: "Snapshot unavailable",
                message: "No snapshot workspace data could be loaded.",
                confirmButtonTitle: "OK"
            )
            return
        }

        sourceType = source
        saveState()
    }

    func reloadBundledSnapshotData() {
        do {
            snapshotWorkspaces = try snapshotRepository.loadWorkspaces()
            if snapshotWorkspaceId.isEmpty || snapshotWorkspaces.contains(where: { $0.id == snapshotWorkspaceId }) == false {
                snapshotWorkspaceId = snapshotWorkspaces.first?.id ?? ""
            }
            if sourceType == .snapshot && snapshotWorkspaces.isEmpty {
                sourceType = .seeded
            }
            saveState()
        } catch {
            setAlert(
                id: "snapshot_reload_failed",
                title: "Snapshot load failed",
                message: error.localizedDescription,
                confirmButtonTitle: "OK"
            )
        }
    }

    func resetAppState() {
        persistence.clearState()
        bootstrap(forceSeedReset: true)
    }

    func channel(with id: String) -> Channel? {
        activeWorkspace?.channels.first(where: { $0.id == id })
    }

    func dm(with id: String) -> DMConversation? {
        activeWorkspace?.dmConversations.first(where: { $0.id == id })
    }

    func member(with id: String) -> WorkspaceMember? {
        activeWorkspace?.members.first(where: { $0.id == id })
    }

    func recentChannels(limit: Int = 5) -> [Channel] {
        guard let workspace = activeWorkspace else {
            return []
        }
        return workspace.channels.sorted(by: { $0.lastMessageAt > $1.lastMessageAt }).prefix(limit).map { $0 }
    }

    func recentDMs(limit: Int = 5) -> [DMConversation] {
        guard let workspace = activeWorkspace else {
            return []
        }
        return workspace.dmConversations.sorted(by: { $0.lastMessageAt > $1.lastMessageAt }).prefix(limit).map { $0 }
    }

    func assignedItems() -> [ActivityItem] {
        guard let workspace = activeWorkspace else {
            return []
        }
        return workspace.assignedItemMessageIds.compactMap { messageId in
            makeActivityItemForMessage(messageId: messageId, type: .threads, titlePrefix: "Assigned")
        }
    }

    func savedItems() -> [ActivityItem] {
        guard let workspace = activeWorkspace else {
            return []
        }
        return workspace.savedItemMessageIds.compactMap { messageId in
            makeActivityItemForMessage(messageId: messageId, type: .saved, titlePrefix: "Saved")
        }
    }

    @discardableResult
    func sendChannelMessage(channelId: String, text: String, attachments: [MessageAttachment] = []) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false || attachments.isEmpty == false else {
            setAlert(
                id: "send_empty_channel_message",
                title: "Unable to send",
                message: "Unable to send empty message.",
                confirmButtonTitle: "OK"
            )
            return false
        }

        var didSend = false
        mutateActiveWorkspace { workspace in
            guard let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }) else {
                return
            }
            let sender = workspace.members.first(where: { $0.id == workspace.currentUserId })
            let messageId = workspace.nextMessageId()
            let timestamp = Date()
            let previewText = trimmed.isEmpty ? attachmentPreviewText(for: attachments) : trimmed

            let message = Message(
                id: messageId,
                senderId: workspace.currentUserId,
                messageText: trimmed,
                timestamp: timestamp,
                editedAt: nil,
                senderDisplayName: sender?.displayName ?? "You",
                replyCount: 0,
                reactions: [],
                attachments: attachments,
                threadReplies: [],
                mentionUserIds: extractMentionUserIds(in: trimmed, workspace: workspace),
                isUnread: false
            )

            workspace.channels[channelIndex].messages.append(message)
            workspace.channels[channelIndex].lastMessageAt = timestamp
            workspace.channels[channelIndex].lastMessagePreview = previewText
            didSend = true
        }
        if didSend {
            scheduleChannelReply(channelId: channelId)
        }
        return didSend
    }

    @discardableResult
    func sendDMMessage(dmId: String, text: String, attachments: [MessageAttachment] = []) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false || attachments.isEmpty == false else {
            setAlert(
                id: "send_empty_dm_message",
                title: "Unable to send",
                message: "Unable to send empty message.",
                confirmButtonTitle: "OK"
            )
            return false
        }

        var didSend = false
        mutateActiveWorkspace { workspace in
            guard let dmIndex = workspace.dmConversations.firstIndex(where: { $0.id == dmId }) else {
                return
            }
            let sender = workspace.members.first(where: { $0.id == workspace.currentUserId })
            let messageId = workspace.nextMessageId()
            let timestamp = Date()
            let previewText = trimmed.isEmpty ? attachmentPreviewText(for: attachments) : trimmed

            let message = Message(
                id: messageId,
                senderId: workspace.currentUserId,
                messageText: trimmed,
                timestamp: timestamp,
                editedAt: nil,
                senderDisplayName: sender?.displayName ?? "You",
                replyCount: 0,
                reactions: [],
                attachments: attachments,
                threadReplies: [],
                mentionUserIds: extractMentionUserIds(in: trimmed, workspace: workspace),
                isUnread: false
            )

            workspace.dmConversations[dmIndex].messages.append(message)
            workspace.dmConversations[dmIndex].lastMessageAt = timestamp
            workspace.dmConversations[dmIndex].lastMessagePreview = previewText
            didSend = true
        }
        if didSend {
            scheduleDMReply(dmId: dmId)
        }
        return didSend
    }

    @discardableResult
    func sendThreadReply(channelId: String?, dmId: String?, parentMessageId: String, text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            setAlert(
                id: "send_empty_thread_reply",
                title: "Unable to send",
                message: "Unable to send empty message.",
                confirmButtonTitle: "OK"
            )
            return false
        }

        var didSend = false
        mutateActiveWorkspace { workspace in
            let senderName = workspace.members.first(where: { $0.id == workspace.currentUserId })?.displayName ?? "You"

            if let channelId,
               let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }),
               let messageIndex = workspace.channels[channelIndex].messages.firstIndex(where: { $0.id == parentMessageId }) {
                var message = workspace.channels[channelIndex].messages[messageIndex]
                let replyId = "\(parentMessageId)_r\(message.threadReplies.count + 1)"
                let reply = ThreadReply(
                    id: replyId,
                    parentMessageId: parentMessageId,
                    senderId: workspace.currentUserId,
                    messageText: trimmed,
                    timestamp: Date(),
                    editedAt: nil,
                    reactions: [],
                    attachments: []
                )
                message.threadReplies.append(reply)
                message.replyCount = message.threadReplies.count
                message.senderDisplayName = message.senderDisplayName.isEmpty ? senderName : message.senderDisplayName
                workspace.channels[channelIndex].messages[messageIndex] = message
                didSend = true
                return
            }

            if let dmId,
               let dmIndex = workspace.dmConversations.firstIndex(where: { $0.id == dmId }),
               let messageIndex = workspace.dmConversations[dmIndex].messages.firstIndex(where: { $0.id == parentMessageId }) {
                var message = workspace.dmConversations[dmIndex].messages[messageIndex]
                let replyId = "\(parentMessageId)_r\(message.threadReplies.count + 1)"
                let reply = ThreadReply(
                    id: replyId,
                    parentMessageId: parentMessageId,
                    senderId: workspace.currentUserId,
                    messageText: trimmed,
                    timestamp: Date(),
                    editedAt: nil,
                    reactions: [],
                    attachments: []
                )
                message.threadReplies.append(reply)
                message.replyCount = message.threadReplies.count
                workspace.dmConversations[dmIndex].messages[messageIndex] = message
                didSend = true
            }
        }
        return didSend
    }

    func toggleReactionOnChannelMessage(channelId: String, messageId: String, emoji: String = "👍") {
        mutateActiveWorkspace { workspace in
            guard let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }),
                  let messageIndex = workspace.channels[channelIndex].messages.firstIndex(where: { $0.id == messageId }) else {
                return
            }
            var message = workspace.channels[channelIndex].messages[messageIndex]
            toggleReaction(
                reactions: &message.reactions,
                emoji: emoji,
                userId: workspace.currentUserId
            )
            workspace.channels[channelIndex].messages[messageIndex] = message
        }
    }

    func toggleReactionOnDMMessage(dmId: String, messageId: String, emoji: String = "👍") {
        mutateActiveWorkspace { workspace in
            guard let dmIndex = workspace.dmConversations.firstIndex(where: { $0.id == dmId }),
                  let messageIndex = workspace.dmConversations[dmIndex].messages.firstIndex(where: { $0.id == messageId }) else {
                return
            }
            var message = workspace.dmConversations[dmIndex].messages[messageIndex]
            toggleReaction(
                reactions: &message.reactions,
                emoji: emoji,
                userId: workspace.currentUserId
            )
            workspace.dmConversations[dmIndex].messages[messageIndex] = message
        }
    }

    func toggleReactionOnThreadReply(
        channelId: String?,
        dmId: String?,
        parentMessageId: String,
        replyId: String,
        emoji: String = "👍"
    ) {
        mutateActiveWorkspace { workspace in
            if let channelId,
               let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }),
               let messageIndex = workspace.channels[channelIndex].messages.firstIndex(where: { $0.id == parentMessageId }),
               let replyIndex = workspace.channels[channelIndex].messages[messageIndex].threadReplies.firstIndex(where: { $0.id == replyId }) {
                var message = workspace.channels[channelIndex].messages[messageIndex]
                var reply = message.threadReplies[replyIndex]
                toggleReaction(reactions: &reply.reactions, emoji: emoji, userId: workspace.currentUserId)
                message.threadReplies[replyIndex] = reply
                workspace.channels[channelIndex].messages[messageIndex] = message
                return
            }

            if let dmId,
               let dmIndex = workspace.dmConversations.firstIndex(where: { $0.id == dmId }),
               let messageIndex = workspace.dmConversations[dmIndex].messages.firstIndex(where: { $0.id == parentMessageId }),
               let replyIndex = workspace.dmConversations[dmIndex].messages[messageIndex].threadReplies.firstIndex(where: { $0.id == replyId }) {
                var message = workspace.dmConversations[dmIndex].messages[messageIndex]
                var reply = message.threadReplies[replyIndex]
                toggleReaction(reactions: &reply.reactions, emoji: emoji, userId: workspace.currentUserId)
                message.threadReplies[replyIndex] = reply
                workspace.dmConversations[dmIndex].messages[messageIndex] = message
            }
        }
    }

    func markChannelRead(_ channelId: String) {
        mutateActiveWorkspace { workspace in
            guard let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }) else {
                return
            }
            var channel = workspace.channels[channelIndex]
            channel.messages = channel.messages.map { message in
                var updated = message
                updated.isUnread = false
                return updated
            }
            workspace.channels[channelIndex] = channel
        }
    }

    func markChannelUnread(_ channelId: String) {
        mutateActiveWorkspace { workspace in
            guard let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }),
                  let lastMessageIndex = workspace.channels[channelIndex].messages.indices.last else {
                return
            }
            workspace.channels[channelIndex].messages[lastMessageIndex].isUnread = true
        }
    }

    func markDMRead(_ dmId: String) {
        mutateActiveWorkspace { workspace in
            guard let dmIndex = workspace.dmConversations.firstIndex(where: { $0.id == dmId }) else {
                return
            }
            var dm = workspace.dmConversations[dmIndex]
            dm.messages = dm.messages.map { message in
                var updated = message
                updated.isUnread = false
                return updated
            }
            workspace.dmConversations[dmIndex] = dm
        }
    }

    func markDMUnread(_ dmId: String) {
        mutateActiveWorkspace { workspace in
            guard let dmIndex = workspace.dmConversations.firstIndex(where: { $0.id == dmId }),
                  let lastMessageIndex = workspace.dmConversations[dmIndex].messages.indices.last else {
                return
            }
            workspace.dmConversations[dmIndex].messages[lastMessageIndex].isUnread = true
        }
    }

    func toggleChannelMute(_ channelId: String) {
        mutateActiveWorkspace { workspace in
            guard let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }) else {
                return
            }
            workspace.channels[channelIndex].isMuted.toggle()
        }
    }

    func toggleChannelStar(_ channelId: String) {
        mutateActiveWorkspace { workspace in
            guard let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }) else {
                return
            }
            workspace.channels[channelIndex].isStarred.toggle()
        }
    }

    func toggleChannelNotificationPreference(_ channelId: String) {
        mutateActiveWorkspace { workspace in
            guard let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }) else {
                return
            }
            workspace.channels[channelIndex].notifyOnAllMessages.toggle()
        }
    }

    @discardableResult
    func leaveChannel(_ channelId: String) -> Bool {
        guard let channel = activeWorkspace?.channels.first(where: { $0.id == channelId }) else {
            return false
        }

        if channel.channelName == "general" {
            setAlert(
                id: "leave_general_channel_blocked",
                title: "Can't leave #general",
                message: "This workspace keeps #general as a required channel.",
                confirmButtonTitle: "OK"
            )
            return false
        }

        mutateActiveWorkspace { workspace in
            workspace.channels.removeAll(where: { $0.id == channelId })
        }
        return true
    }

    func toggleDMMute(_ dmId: String) {
        mutateActiveWorkspace { workspace in
            guard let dmIndex = workspace.dmConversations.firstIndex(where: { $0.id == dmId }) else {
                return
            }
            workspace.dmConversations[dmIndex].isMuted.toggle()
        }
    }

    @discardableResult
    func createMockDM(with memberIds: [String]) -> String? {
        var createdId: String?

        mutateActiveWorkspace { workspace in
            var participants = Set(memberIds)
            participants.insert(workspace.currentUserId)
            guard participants.count >= 2 else {
                return
            }
            let participantList = Array(participants).sorted()

            if let existing = workspace.dmConversations.first(where: { Set($0.participantIds) == participants }) {
                createdId = existing.id
                return
            }

            let displayNames = participantList.compactMap { id in
                workspace.members.first(where: { $0.id == id })?.displayName
            }

            let isGroup = participantList.count > 2
            let name: String
            if isGroup {
                name = displayNames.prefix(3).joined(separator: ", ")
            } else {
                name = displayNames.first(where: { $0 != workspace.userProfile.displayName }) ?? "New DM"
            }

            let dmId = "dm_custom_\(workspace.dmConversations.count + 1)"
            let conversation = DMConversation(
                id: dmId,
                name: name,
                participantIds: participantList,
                isGroup: isGroup,
                isMuted: false,
                unreadCount: 0,
                mentionCount: 0,
                messages: [],
                lastMessagePreview: "No messages yet",
                lastMessageAt: Date()
            )
            workspace.dmConversations.insert(conversation, at: 0)
            createdId = dmId
        }

        if createdId == nil {
            setAlert(
                id: "dm_create_failed",
                title: "No members found",
                message: "Select at least one member to create a DM.",
                confirmButtonTitle: "OK"
            )
        }

        return createdId
    }

    func search(
        query: String,
        filter: SearchFilter,
        mentionsOnly: Bool,
        hasLink: Bool,
        hasFile: Bool
    ) -> [SearchResult] {
        guard let workspace = activeWorkspace else {
            return []
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return []
        }

        let queryValue = trimmed.lowercased()
        var results: [SearchResult] = []

        if filter == .all || filter == .channels {
            for channel in workspace.channels where channel.channelName.lowercased().contains(queryValue) || channel.descriptionTopic.lowercased().contains(queryValue) {
                results.append(
                    SearchResult(
                        id: "search_channel_\(channel.id)",
                        type: .channels,
                        title: channel.displayName,
                        searchSnippet: channel.descriptionTopic,
                        sender: "",
                        contextName: workspace.workspaceName,
                        timestamp: channel.lastMessageAt,
                        isUnread: channel.unreadCount > 0,
                        channelId: channel.id,
                        dmId: nil,
                        messageId: nil,
                        memberId: nil
                    )
                )
            }
        }

        if filter == .all || filter == .people {
            for member in workspace.members where member.displayName.lowercased().contains(queryValue) || member.username.lowercased().contains(queryValue) {
                results.append(
                    SearchResult(
                        id: "search_member_\(member.id)",
                        type: .people,
                        title: member.displayName,
                        searchSnippet: "@\(member.username) - \(member.title)",
                        sender: "",
                        contextName: member.role,
                        timestamp: nil,
                        isUnread: false,
                        channelId: nil,
                        dmId: nil,
                        messageId: nil,
                        memberId: member.id
                    )
                )
            }
        }

        if filter == .all || filter == .messages {
            for channel in workspace.channels {
                for message in channel.messages where message.messageText.lowercased().contains(queryValue) {
                    if mentionsOnly && message.mentionUserIds.contains(workspace.currentUserId) == false {
                        continue
                    }
                    if hasLink && message.attachments.contains(where: { $0.attachmentType == .link }) == false {
                        continue
                    }
                    if hasFile && message.attachments.contains(where: { $0.attachmentType == .pdf || $0.attachmentType == .image }) == false {
                        continue
                    }

                    results.append(
                        SearchResult(
                            id: "search_message_\(message.id)",
                            type: .messages,
                            title: message.senderDisplayName,
                            searchSnippet: message.messageText,
                            sender: message.senderDisplayName,
                            contextName: channel.displayName,
                            timestamp: message.timestamp,
                            isUnread: message.isUnread,
                            channelId: channel.id,
                            dmId: nil,
                            messageId: message.id,
                            memberId: nil
                        )
                    )
                }
            }

            for dm in workspace.dmConversations {
                for message in dm.messages where message.messageText.lowercased().contains(queryValue) {
                    if mentionsOnly && message.mentionUserIds.contains(workspace.currentUserId) == false {
                        continue
                    }
                    if hasLink && message.attachments.contains(where: { $0.attachmentType == .link }) == false {
                        continue
                    }
                    if hasFile && message.attachments.contains(where: { $0.attachmentType == .pdf || $0.attachmentType == .image }) == false {
                        continue
                    }

                    results.append(
                        SearchResult(
                            id: "search_message_\(message.id)",
                            type: .messages,
                            title: message.senderDisplayName,
                            searchSnippet: message.messageText,
                            sender: message.senderDisplayName,
                            contextName: dm.name,
                            timestamp: message.timestamp,
                            isUnread: message.isUnread,
                            channelId: nil,
                            dmId: dm.id,
                            messageId: message.id,
                            memberId: nil
                        )
                    )
                }
            }
        }

        return results.sorted {
            ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast)
        }
    }

    func rememberSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return
        }

        recentSearches.removeAll(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        recentSearches.insert(trimmed, at: 0)
        recentSearches = Array(recentSearches.prefix(8))
        saveState()
    }

    func activityItems(for filter: ActivityType) -> [ActivityItem] {
        guard let workspace = activeWorkspace else {
            return []
        }

        var allItems: [ActivityItem] = []
        for channel in workspace.channels {
            for message in channel.messages {
                if message.mentionUserIds.contains(workspace.currentUserId) {
                    allItems.append(
                        ActivityItem(
                            id: "activity_mention_\(message.id)",
                            type: .mentions,
                            title: "Mention in \(channel.displayName)",
                            subtitle: message.messageText,
                            channelOrDMName: channel.displayName,
                            timestamp: message.timestamp,
                            channelId: channel.id,
                            dmId: nil,
                            messageId: message.id,
                            isUnread: message.isUnread
                        )
                    )
                }

                if message.replyCount > 0 {
                    allItems.append(
                        ActivityItem(
                            id: "activity_thread_\(message.id)",
                            type: .threads,
                            title: "Thread update in \(channel.displayName)",
                            subtitle: message.threadReplies.last?.messageText ?? message.messageText,
                            channelOrDMName: channel.displayName,
                            timestamp: message.threadReplies.last?.timestamp ?? message.timestamp,
                            channelId: channel.id,
                            dmId: nil,
                            messageId: message.id,
                            isUnread: message.isUnread
                        )
                    )
                }

                if message.reactions.isEmpty == false {
                    allItems.append(
                        ActivityItem(
                            id: "activity_reaction_\(message.id)",
                            type: .reactions,
                            title: "Reaction activity",
                            subtitle: message.messageText,
                            channelOrDMName: channel.displayName,
                            timestamp: message.timestamp,
                            channelId: channel.id,
                            dmId: nil,
                            messageId: message.id,
                            isUnread: message.isUnread
                        )
                    )
                }
            }

            if channel.unreadCount > 0 {
                let unreadMessages = channel.messages.filter(\.isUnread)
                let focusMessage = unreadMessages.first
                let previewText = unreadMessages.last?.previewText ?? "\(channel.unreadCount) unread message(s)"
                allItems.append(
                    ActivityItem(
                        id: "activity_unread_\(channel.id)",
                        type: .unreads,
                        title: channel.unreadCount == 1
                            ? "1 unread in \(channel.displayName)"
                            : "\(channel.unreadCount) unread in \(channel.displayName)",
                        subtitle: previewText,
                        channelOrDMName: channel.displayName,
                        timestamp: channel.lastMessageAt,
                        channelId: channel.id,
                        dmId: nil,
                        messageId: focusMessage?.id,
                        isUnread: true
                    )
                )
            }
        }

        for dm in workspace.dmConversations {
            for message in dm.messages {
                if message.mentionUserIds.contains(workspace.currentUserId) {
                    allItems.append(
                        ActivityItem(
                            id: "activity_dm_mention_\(message.id)",
                            type: .mentions,
                            title: "Mention in \(dm.name)",
                            subtitle: message.messageText,
                            channelOrDMName: dm.name,
                            timestamp: message.timestamp,
                            channelId: nil,
                            dmId: dm.id,
                            messageId: message.id,
                            isUnread: message.isUnread
                        )
                    )
                }

                if message.replyCount > 0 {
                    allItems.append(
                        ActivityItem(
                            id: "activity_dm_thread_\(message.id)",
                            type: .threads,
                            title: "Thread update in \(dm.name)",
                            subtitle: message.threadReplies.last?.messageText ?? message.messageText,
                            channelOrDMName: dm.name,
                            timestamp: message.threadReplies.last?.timestamp ?? message.timestamp,
                            channelId: nil,
                            dmId: dm.id,
                            messageId: message.id,
                            isUnread: message.isUnread
                        )
                    )
                }

                if message.reactions.isEmpty == false {
                    allItems.append(
                        ActivityItem(
                            id: "activity_dm_reaction_\(message.id)",
                            type: .reactions,
                            title: "Reaction activity",
                            subtitle: message.messageText,
                            channelOrDMName: dm.name,
                            timestamp: message.timestamp,
                            channelId: nil,
                            dmId: dm.id,
                            messageId: message.id,
                            isUnread: message.isUnread
                        )
                    )
                }
            }

            if dm.unreadCount > 0 {
                let unreadMessages = dm.messages.filter(\.isUnread)
                let focusMessage = unreadMessages.first
                let previewText = unreadMessages.last?.previewText ?? "\(dm.unreadCount) unread message(s)"
                let preposition = dm.isGroup ? "in" : "from"
                allItems.append(
                    ActivityItem(
                        id: "activity_unread_\(dm.id)",
                        type: .unreads,
                        title: dm.unreadCount == 1
                            ? "1 unread \(preposition) \(dm.name)"
                            : "\(dm.unreadCount) unread \(preposition) \(dm.name)",
                        subtitle: previewText,
                        channelOrDMName: dm.name,
                        timestamp: dm.lastMessageAt,
                        channelId: nil,
                        dmId: dm.id,
                        messageId: focusMessage?.id,
                        isUnread: true
                    )
                )
            }
        }

        let savedItems = workspace.savedItemMessageIds.compactMap { messageId in
            makeActivityItemForMessage(messageId: messageId, type: .saved, titlePrefix: "Saved")
        }
        allItems.append(contentsOf: savedItems)

        let filteredItems = allItems.filter { item in
            switch filter {
            case .all:
                return true
            case .saved:
                return item.type == .saved
            case .mentions, .threads, .reactions, .unreads:
                return item.type == filter
            }
        }

        return filteredItems.sorted(by: { $0.timestamp > $1.timestamp })
    }

    func navigationTarget(for searchResult: SearchResult) -> NavigationTarget? {
        if let channelId = searchResult.channelId {
            return .channel(channelId: channelId, focusMessageId: searchResult.messageId)
        }
        if let dmId = searchResult.dmId {
            return .dm(dmId: dmId, focusMessageId: searchResult.messageId)
        }
        if let memberId = searchResult.memberId {
            return .member(memberId: memberId)
        }
        return nil
    }

    func navigationTarget(for activityItem: ActivityItem) -> NavigationTarget? {
        if let channelId = activityItem.channelId {
            return .channel(channelId: channelId, focusMessageId: activityItem.messageId)
        }
        if let dmId = activityItem.dmId {
            return .dm(dmId: dmId, focusMessageId: activityItem.messageId)
        }
        return nil
    }

    private func bootstrap(forceSeedReset: Bool = false) {
        let seededDefaults = (try? seededRepository.loadWorkspaces()) ?? []
        let snapshotDefaults = (try? snapshotRepository.loadWorkspaces()) ?? []

        if forceSeedReset == false,
           let stored = persistence.loadState() {
            if stored.appDataVersion != SeedDataFactory.appDataVersion {
                bootstrap(forceSeedReset: true)
                return
            }
            seededWorkspaces = stored.seededWorkspaces
            snapshotWorkspaces = stored.snapshotWorkspaces
            sourceType = stored.sourceType
            seededWorkspaceId = stored.seededWorkspaceId
            snapshotWorkspaceId = stored.snapshotWorkspaceId
            recentSearches = stored.recentSearches
            selectedTab = stored.selectedTab

            if seededWorkspaces.isEmpty {
                seededWorkspaces = seededDefaults
            }
            if snapshotWorkspaces.isEmpty {
                snapshotWorkspaces = snapshotDefaults
            }
            enforceValidWorkspaceSelection()
            if sourceType == .snapshot && snapshotWorkspaces.isEmpty {
                sourceType = .seeded
            }
            saveState()
            return
        }

        seededWorkspaces = seededDefaults
        snapshotWorkspaces = snapshotDefaults
        sourceType = .seeded
        seededWorkspaceId = seededWorkspaces.first?.id ?? ""
        snapshotWorkspaceId = snapshotWorkspaces.first?.id ?? ""
        recentSearches = []
        selectedTab = .home
        saveState()
    }

    private func enforceValidWorkspaceSelection() {
        if seededWorkspaces.contains(where: { $0.id == seededWorkspaceId }) == false {
            seededWorkspaceId = seededWorkspaces.first?.id ?? ""
        }
        if snapshotWorkspaces.contains(where: { $0.id == snapshotWorkspaceId }) == false {
            snapshotWorkspaceId = snapshotWorkspaces.first?.id ?? ""
        }
    }

    private func mutateActiveWorkspace(_ mutate: (inout Workspace) -> Void) {
        switch sourceType {
        case .seeded:
            guard let index = seededWorkspaces.firstIndex(where: { $0.id == seededWorkspaceId }) else {
                return
            }
            var workspace = seededWorkspaces[index]
            mutate(&workspace)
            workspace.recalculateDerivedFields()
            workspace.ensureNextSequence()
            seededWorkspaces[index] = workspace
        case .snapshot:
            guard let index = snapshotWorkspaces.firstIndex(where: { $0.id == snapshotWorkspaceId }) else {
                return
            }
            var workspace = snapshotWorkspaces[index]
            mutate(&workspace)
            workspace.recalculateDerivedFields()
            workspace.ensureNextSequence()
            snapshotWorkspaces[index] = workspace
        }
        saveState()
    }

    private func saveState() {
        let state = TeamChatSimState(
            appDataVersion: SeedDataFactory.appDataVersion,
            seededWorkspaces: seededWorkspaces,
            snapshotWorkspaces: snapshotWorkspaces,
            sourceType: sourceType,
            seededWorkspaceId: seededWorkspaceId,
            snapshotWorkspaceId: snapshotWorkspaceId,
            recentSearches: recentSearches,
            selectedTab: selectedTab,
            lastUpdated: Date()
        )
        persistence.saveState(state)
    }

    private func setAlert(id: String, title: String, message: String, confirmButtonTitle: String) {
        appAlert = AppAlert(
            id: id,
            title: title,
            message: message,
            confirmButtonTitle: confirmButtonTitle
        )
    }

    private func extractMentionUserIds(in text: String, workspace: Workspace) -> [String] {
        let lowered = text.lowercased()
        return workspace.members.compactMap { member in
            lowered.contains("@\(member.username.lowercased())") ? member.id : nil
        }
    }

    private func toggleReaction(reactions: inout [Reaction], emoji: String, userId: String) {
        if let index = reactions.firstIndex(where: { $0.reactionEmoji == emoji }) {
            var reaction = reactions[index]
            if reaction.userIds.contains(userId) {
                reaction.userIds.removeAll(where: { $0 == userId })
            } else {
                reaction.userIds.append(userId)
            }
            reaction.syncCount()
            if reaction.userIds.isEmpty {
                reactions.remove(at: index)
            } else {
                reactions[index] = reaction
            }
            return
        }

        reactions.append(
            Reaction(
                reactionEmoji: emoji,
                userIds: [userId],
                reactionCount: 1
            )
        )
    }

    private func attachmentPreviewText(for attachments: [MessageAttachment]) -> String {
        guard attachments.isEmpty == false else {
            return ""
        }

        if attachments.count == 1, let attachment = attachments.first {
            return "Shared \(attachment.title)"
        }

        return "Shared \(attachments.count) attachments"
    }

    private func scheduleDMReply(dmId: String) {
        guard let workspace = activeWorkspace,
              let dm = workspace.dmConversations.first(where: { $0.id == dmId }) else {
            return
        }

        let otherParticipants = dm.participantIds.filter { $0 != workspace.currentUserId }

        if dm.isGroup {
            scheduleGroupDMReplies(dmId: dmId, dm: dm, otherParticipants: otherParticipants, workspace: workspace)
        } else {
            guard let responderId = otherParticipants.first,
                  let responder = workspace.members.first(where: { $0.id == responderId }) else {
                return
            }
            scheduleSingleDMReply(dmId: dmId, dm: dm, responderId: responderId, responder: responder, workspace: workspace, delay: 1.2)
        }
    }

    private func scheduleGroupDMReplies(dmId: String, dm: DMConversation, otherParticipants: [String], workspace: Workspace) {
        let replyCount = min(otherParticipants.count, Int.random(in: 1...3))
        let responders = Array(otherParticipants.shuffled().prefix(replyCount))

        for (index, responderId) in responders.enumerated() {
            guard let responder = workspace.members.first(where: { $0.id == responderId }) else { continue }
            let delay = 1.2 + Double(index) * Double.random(in: 1.5...3.0)
            scheduleSingleDMReply(dmId: dmId, dm: dm, responderId: responderId, responder: responder, workspace: workspace, delay: delay)
        }
    }

    private func scheduleSingleDMReply(dmId: String, dm: DMConversation, responderId: String, responder: WorkspaceMember, workspace: Workspace, delay: Double) {
        guard let apiKey = TeamChatOpenAISettings.shared.validatedAPIKey() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.deliverFallbackDMReply(dmId: dmId, responderId: responderId, responderName: responder.displayName, lastText: dm.messages.last?.messageText ?? "")
            }
            return
        }

        let recentMessages = dm.messages.suffix(8).map { msg in
            let name = workspace.members.first(where: { $0.id == msg.senderId })?.displayName ?? msg.senderDisplayName
            return (name: name, text: msg.messageText)
        }

        let conversationName = dm.name
        let isGroup = dm.isGroup

        TeamChatReplyGenerator(apiKey: apiKey).generateReply(
            as: responder.displayName,
            role: responder.title,
            conversationName: conversationName,
            isGroup: isGroup,
            recentMessages: recentMessages
        ) { [weak self] result in
            switch result {
            case .success(let text):
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.appendDMReply(dmId: dmId, senderId: responderId, senderName: responder.displayName, text: text)
                }
            case .failure:
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.deliverFallbackDMReply(dmId: dmId, responderId: responderId, responderName: responder.displayName, lastText: dm.messages.last?.messageText ?? "")
                }
            }
        }
    }

    private func deliverFallbackDMReply(dmId: String, responderId: String, responderName: String, lastText: String) {
        let lower = lastText.lowercased()
        let reply: String
        if lower.contains("?") || lower.contains("how") || lower.contains("what") || lower.contains("when") || lower.contains("where") {
            reply = ["Good question, let me check on that", "Hmm I'll have to look into that and get back to you", "Not sure off the top of my head, let me find out"].randomElement() ?? "Good question, let me check on that"
        } else if lower.contains("thanks") || lower.contains("thank") || lower.contains("appreciate") {
            reply = ["No problem!", "Anytime!", "Happy to help", "Of course!"].randomElement() ?? "No problem!"
        } else if lower.contains("update") || lower.contains("status") || lower.contains("progress") {
            reply = ["I'll pull together an update and share it shortly", "Let me sync with the team and get back to you", "Working on it, will have an update soon"].randomElement() ?? "Working on it, will have an update soon"
        } else if lower.contains("meeting") || lower.contains("sync") || lower.contains("call") {
            reply = ["Sure, let me check my calendar", "Works for me, I'll send an invite", "Let me find a time that works"].randomElement() ?? "Sure, let me check my calendar"
        } else if lower.contains("lgtm") || lower.contains("ship") || lower.contains("merge") || lower.contains("approve") {
            reply = ["Sounds good, going ahead with it", "Great, I'll get that merged", "On it!"].randomElement() ?? "On it!"
        } else {
            reply = ["Sounds good", "Got it, thanks", "Makes sense", "Noted, will follow up", "Acknowledged"].randomElement() ?? "Sounds good"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.appendDMReply(dmId: dmId, senderId: responderId, senderName: responderName, text: reply)
        }
    }

    private func appendDMReply(dmId: String, senderId: String, senderName: String, text: String) {
        mutateActiveWorkspace { workspace in
            guard let dmIndex = workspace.dmConversations.firstIndex(where: { $0.id == dmId }) else {
                return
            }
            let messageId = workspace.nextMessageId()
            let timestamp = Date()
            let message = Message(
                id: messageId,
                senderId: senderId,
                messageText: text,
                timestamp: timestamp,
                editedAt: nil,
                senderDisplayName: senderName,
                replyCount: 0,
                reactions: [],
                attachments: [],
                threadReplies: [],
                mentionUserIds: [],
                isUnread: true
            )
            workspace.dmConversations[dmIndex].messages.append(message)
            workspace.dmConversations[dmIndex].lastMessageAt = timestamp
            workspace.dmConversations[dmIndex].lastMessagePreview = text
        }
    }

    // MARK: - Channel Reply Generation

    private func scheduleChannelReply(channelId: String) {
        guard let workspace = activeWorkspace,
              let channel = workspace.channels.first(where: { $0.id == channelId }) else {
            return
        }

        let otherMembers = channel.memberIds.filter { $0 != workspace.currentUserId }
        guard !otherMembers.isEmpty else { return }

        let replyCount = min(otherMembers.count, Int.random(in: 1...3))
        let responders = Array(otherMembers.shuffled().prefix(replyCount))

        for (index, responderId) in responders.enumerated() {
            guard let responder = workspace.members.first(where: { $0.id == responderId }) else { continue }
            let delay = 1.2 + Double(index) * Double.random(in: 1.5...3.0)
            scheduleSingleChannelReply(channelId: channelId, channel: channel, responderId: responderId, responder: responder, workspace: workspace, delay: delay)
        }
    }

    private func scheduleSingleChannelReply(channelId: String, channel: Channel, responderId: String, responder: WorkspaceMember, workspace: Workspace, delay: Double) {
        guard let apiKey = TeamChatOpenAISettings.shared.validatedAPIKey() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.deliverFallbackChannelReply(channelId: channelId, responderId: responderId, responderName: responder.displayName, lastText: channel.messages.last?.messageText ?? "")
            }
            return
        }

        let recentMessages = channel.messages.suffix(8).map { msg in
            let name = workspace.members.first(where: { $0.id == msg.senderId })?.displayName ?? msg.senderDisplayName
            return (name: name, text: msg.messageText)
        }

        TeamChatReplyGenerator(apiKey: apiKey).generateReply(
            as: responder.displayName,
            role: responder.title,
            conversationName: channel.displayName,
            isGroup: true,
            recentMessages: recentMessages
        ) { [weak self] result in
            switch result {
            case .success(let text):
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.appendChannelReply(channelId: channelId, senderId: responderId, senderName: responder.displayName, text: text)
                }
            case .failure:
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.deliverFallbackChannelReply(channelId: channelId, responderId: responderId, responderName: responder.displayName, lastText: channel.messages.last?.messageText ?? "")
                }
            }
        }
    }

    private func deliverFallbackChannelReply(channelId: String, responderId: String, responderName: String, lastText: String) {
        let lower = lastText.lowercased()
        let reply: String
        if lower.contains("?") || lower.contains("how") || lower.contains("what") || lower.contains("when") || lower.contains("where") {
            reply = ["Good question, let me check on that", "Hmm I'll have to look into that and get back to you", "Not sure off the top of my head, let me find out"].randomElement()!
        } else if lower.contains("thanks") || lower.contains("thank") || lower.contains("appreciate") {
            reply = ["No problem!", "Anytime!", "Happy to help", "Of course!"].randomElement()!
        } else if lower.contains("update") || lower.contains("status") || lower.contains("progress") {
            reply = ["I'll pull together an update and share it shortly", "Let me sync with the team and get back to you", "Working on it, will have an update soon"].randomElement()!
        } else if lower.contains("meeting") || lower.contains("sync") || lower.contains("call") {
            reply = ["Sure, let me check my calendar", "Works for me, I'll send an invite", "Let me find a time that works"].randomElement()!
        } else if lower.contains("lgtm") || lower.contains("ship") || lower.contains("merge") || lower.contains("approve") {
            reply = ["Sounds good, going ahead with it", "Great, I'll get that merged", "On it!"].randomElement()!
        } else {
            reply = ["Sounds good", "Got it, thanks", "Makes sense", "Noted, will follow up", "Acknowledged"].randomElement()!
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.appendChannelReply(channelId: channelId, senderId: responderId, senderName: responderName, text: reply)
        }
    }

    private func appendChannelReply(channelId: String, senderId: String, senderName: String, text: String) {
        mutateActiveWorkspace { workspace in
            guard let channelIndex = workspace.channels.firstIndex(where: { $0.id == channelId }) else {
                return
            }
            let messageId = workspace.nextMessageId()
            let timestamp = Date()
            let message = Message(
                id: messageId,
                senderId: senderId,
                messageText: text,
                timestamp: timestamp,
                editedAt: nil,
                senderDisplayName: senderName,
                replyCount: 0,
                reactions: [],
                attachments: [],
                threadReplies: [],
                mentionUserIds: [],
                isUnread: true
            )
            workspace.channels[channelIndex].messages.append(message)
            workspace.channels[channelIndex].lastMessageAt = timestamp
            workspace.channels[channelIndex].lastMessagePreview = text
        }
    }

    private func makeActivityItemForMessage(
        messageId: String,
        type: ActivityType,
        titlePrefix: String
    ) -> ActivityItem? {
        guard let workspace = activeWorkspace else {
            return nil
        }

        for channel in workspace.channels {
            if let message = channel.messages.first(where: { $0.id == messageId }) {
                return ActivityItem(
                    id: "activity_\(type.rawValue)_\(message.id)",
                    type: type,
                    title: "\(titlePrefix) in \(channel.displayName)",
                    subtitle: message.messageText,
                    channelOrDMName: channel.displayName,
                    timestamp: message.timestamp,
                    channelId: channel.id,
                    dmId: nil,
                    messageId: message.id,
                    isUnread: message.isUnread
                )
            }
        }

        for dm in workspace.dmConversations {
            if let message = dm.messages.first(where: { $0.id == messageId }) {
                return ActivityItem(
                    id: "activity_\(type.rawValue)_\(message.id)",
                    type: type,
                    title: "\(titlePrefix) in \(dm.name)",
                    subtitle: message.messageText,
                    channelOrDMName: dm.name,
                    timestamp: message.timestamp,
                    channelId: nil,
                    dmId: dm.id,
                    messageId: message.id,
                    isUnread: message.isUnread
                )
            }
        }

        return nil
    }
}

// MARK: - OpenAI LLM Integration

final class TeamChatOpenAISettings {
    static let shared = TeamChatOpenAISettings()

    private init() {}

    func validatedAPIKey() -> String? {
        let candidate = keyFromEnvironment() ?? keyFromInfoPlist() ?? keyFromEnvFile() ?? keyFromUserDefaults()
        guard let rawKey = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !rawKey.isEmpty else {
            return nil
        }
        return rawKey
    }

    private func keyFromEnvironment() -> String? {
        guard let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty else {
            return nil
        }
        return envKey
    }

    private func keyFromInfoPlist() -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !value.isEmpty, !value.contains("$(") else {
            return nil
        }
        return value
    }

    private func keyFromEnvFile() -> String? {
        var dir = Bundle.main.bundleURL.deletingLastPathComponent()
        for _ in 0..<10 {
            let envFile = dir.appendingPathComponent(".env")
            if let contents = try? String(contentsOf: envFile, encoding: .utf8) {
                for line in contents.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.hasPrefix("OPENAI_API_KEY"), let eqIdx = trimmed.firstIndex(of: "=") else { continue }
                    var val = String(trimmed[trimmed.index(after: eqIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                        val = String(val.dropFirst().dropLast())
                    }
                    if !val.isEmpty { return val }
                }
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }
        return nil
    }

    private func keyFromUserDefaults() -> String? {
        guard let value = UserDefaults.standard.string(forKey: "openai_api_key"), !value.isEmpty else {
            return nil
        }
        return value
    }
}

struct TeamChatReplyError: Error {
    let message: String
}

final class TeamChatReplyGenerator {
    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    private let session: URLSession
    private let apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func generateReply(
        as senderName: String,
        role: String,
        conversationName: String,
        isGroup: Bool,
        recentMessages: [(name: String, text: String)],
        completion: @escaping (Result<String, TeamChatReplyError>) -> Void
    ) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(TeamChatReplyError(message: "Invalid OpenAI endpoint.")))
            return
        }

        let transcript = recentMessages.map { "\($0.name): \($0.text)" }.joined(separator: "\n")

        let systemPrompt = """
        You are simulating a TeamChat reply from \(senderName).
        Role: \(role)
        Conversation: \(isGroup ? "group DM" : "direct message") named "\(conversationName)".
        Reply like a real coworker messaging on TeamChat.
        Keep it concise, natural, and specific to the conversation.
        Use 1 to 3 short sentences.
        Never mention being an AI, assistant, or language model.
        Return only the message text.
        """

        let userPrompt = """
        Recent conversation, oldest to newest:
        \(transcript)

        Write \(senderName)'s next reply.
        """

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.8,
            "max_tokens": 120
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            completion(.failure(TeamChatReplyError(message: "Failed to encode request payload.")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        session.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(TeamChatReplyError(message: "Network error: \(error.localizedDescription)")))
                return
            }
            guard let data,
                  let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data),
                  let reply = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
                  !reply.isEmpty else {
                completion(.failure(TeamChatReplyError(message: "OpenAI response was empty.")))
                return
            }
            completion(.success(reply))
        }.resume()
    }
}
