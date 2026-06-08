import Foundation

enum SeedDataFactory {
    static let appDataVersion = 4

    private static let currentUserId = "member_jordan_avery"

    private struct ChannelDefinition {
        let id: String
        let name: String
        let topic: String
        let isPrivate: Bool
        let memberIds: [String]
        let isMutedByDefault: Bool
        let isStarredByDefault: Bool
    }

    private struct DMDefinition {
        let id: String
        let name: String
        let participantIds: [String]
        let isGroup: Bool
        let startsEmpty: Bool
        let isMutedByDefault: Bool
    }

    static func makeSeededWorkspaces() -> [Workspace] {
        [
            makeWorkspace(
                workspaceId: "workspace_delta_ops",
                workspaceName: "Delta Ops",
                sourceType: .seeded,
                sourceLabel: "Default",
                dateSeedOffsetHours: 0,
                channelMessageCount: 20,
                dmMessageCount: 12,
                draftsCount: 4
            ),
            makeWorkspace(
                workspaceId: "workspace_northstar_mobile",
                workspaceName: "Northstar Mobile",
                sourceType: .seeded,
                sourceLabel: "Default",
                dateSeedOffsetHours: 42,
                channelMessageCount: 18,
                dmMessageCount: 10,
                draftsCount: 3
            )
        ]
    }

    static func makeSnapshotPayload() -> WorkspaceSnapshotPayload {
        var workspace = makeWorkspace(
            workspaceId: "workspace_launch_systems_team",
            workspaceName: "Launch Systems Team",
            sourceType: .snapshot,
            sourceLabel: "Bundled Snapshot Workspace",
            dateSeedOffsetHours: 18,
            channelMessageCount: 15,
            dmMessageCount: 8,
            draftsCount: 5
        )
        let metadata = WorkspaceSnapshotMetadata(
            sourceLabel: "Bundled Snapshot Workspace",
            sourceType: .snapshot,
            snapshotTimestamp: seededDate(offsetHours: 188),
            lastUpdated: workspace.lastUpdated
        )
        workspace.metadata = nil
        workspace.sourceType = .snapshot
        return WorkspaceSnapshotPayload(metadata: metadata, workspaces: [workspace])
    }

    private static func makeWorkspace(
        workspaceId: String,
        workspaceName: String,
        sourceType: WorkspaceSourceType,
        sourceLabel: String,
        dateSeedOffsetHours: Int,
        channelMessageCount: Int,
        dmMessageCount: Int,
        draftsCount: Int
    ) -> Workspace {
        let members = makeMembers()
        let currentMember = members.first(where: { $0.id == currentUserId }) ?? members[0]
        let channels = channelDefinitions(allMemberIds: members.map(\.id))
        let dms = dmDefinitions()

        let userProfile = UserProfile(
            id: currentMember.id,
            displayName: currentMember.displayName,
            username: currentMember.username,
            title: currentMember.title,
            role: currentMember.role,
            statusText: sourceType == .snapshot ? "On launch coverage" : "Focused work block",
            presenceState: .active,
            notificationPreference: NotificationPreference(
                pushEnabled: true,
                mentionOnly: false,
                threadRepliesEnabled: true,
                huddleInvitesEnabled: true
            )
        )

        var nextSequence = 1
        var builtChannels: [Channel] = []
        var builtDMs: [DMConversation] = []
        var trackedMessageIds: [String] = []

        for (channelIndex, definition) in channels.enumerated() {
            let participants = definition.memberIds.compactMap { memberId in
                members.first(where: { $0.id == memberId })
            }

            var messages: [Message] = []
            for messageIndex in 0..<channelMessageCount {
                guard let sender = participants[safe: (channelIndex + messageIndex + 1) % max(participants.count, 1)] else {
                    continue
                }

                let messageId = String(format: "msg_%03d", nextSequence)
                nextSequence += 1

                let timestamp = seededDate(offsetHours: dateSeedOffsetHours + channelIndex * 10 + messageIndex * 2)
                let mentionCurrentUser = shouldMentionCurrentUser(channelName: definition.name, messageIndex: messageIndex, channelMessageCount: channelMessageCount)
                let attachments = seededAttachments(channelName: definition.name, messageIndex: messageIndex, messageId: messageId)
                let reactions = seededReactions(
                    channelIndex: channelIndex,
                    messageIndex: messageIndex,
                    currentUserId: currentUserId,
                    participants: participants
                )
                let threadReplies = seededThreadReplies(
                    parentMessageId: messageId,
                    channelName: definition.name,
                    messageIndex: messageIndex,
                    participants: participants,
                    timestamp: timestamp
                )

                let message = Message(
                    id: messageId,
                    senderId: sender.id,
                    messageText: channelMessageTemplate(
                        workspaceName: workspaceName,
                        channelName: definition.name,
                        messageIndex: messageIndex,
                        currentUsername: currentMember.username,
                        mentionCurrentUser: mentionCurrentUser
                    ),
                    timestamp: timestamp,
                    editedAt: shouldEditMessage(channelIndex: channelIndex, messageIndex: messageIndex)
                        ? timestamp.addingTimeInterval(540)
                        : nil,
                    senderDisplayName: sender.displayName,
                    replyCount: threadReplies.count,
                    reactions: reactions,
                    attachments: attachments,
                    threadReplies: threadReplies,
                    mentionUserIds: mentionCurrentUser ? [currentUserId] : [],
                    isUnread: isUnreadMessage(channelIndex: channelIndex, messageIndex: messageIndex, channelMessageCount: channelMessageCount)
                )
                messages.append(message)
                trackedMessageIds.append(messageId)
            }

            let latest = messages.max(by: { $0.timestamp < $1.timestamp })
            builtChannels.append(
                Channel(
                    id: definition.id,
                    channelName: definition.name,
                    descriptionTopic: definition.topic,
                    isPrivate: definition.isPrivate,
                    notifyOnAllMessages: definition.name == "general" || definition.name == "launch-war-room",
                    isMuted: definition.isMutedByDefault,
                    isStarred: definition.isStarredByDefault,
                    unreadCount: messages.filter(\.isUnread).count,
                    mentionCount: messages.filter { $0.isUnread && $0.mentionUserIds.contains(currentUserId) }.count,
                    memberIds: definition.memberIds,
                    messages: messages,
                    pinnedItemsPlaceholderCount: pinnedPlaceholderCount(for: definition.name),
                    filesPlaceholderCount: filesPlaceholderCount(for: definition.name),
                    linksPlaceholderCount: linksPlaceholderCount(for: definition.name),
                    lastMessagePreview: latest?.messageText ?? "No messages yet",
                    lastMessageAt: latest?.timestamp ?? seededDate(offsetHours: dateSeedOffsetHours),
                    bookmarks: seededBookmarks(for: definition.name)
                )
            )
        }

        for (dmIndex, definition) in dms.enumerated() {
            let participants = definition.participantIds.compactMap { memberId in
                members.first(where: { $0.id == memberId })
            }

            var messages: [Message] = []
            if definition.startsEmpty == false {
                for messageIndex in 0..<dmMessageCount {
                    guard let sender = participants[safe: (dmIndex + messageIndex + 1) % max(participants.count, 1)] else {
                        continue
                    }

                    let messageId = String(format: "msg_%03d", nextSequence)
                    nextSequence += 1
                    let timestamp = seededDate(offsetHours: dateSeedOffsetHours + 140 + dmIndex * 4 + messageIndex)
                    let mentionCurrentUser = dmIndex == 0 && messageIndex == 2

                    let message = Message(
                        id: messageId,
                        senderId: sender.id,
                        messageText: dmMessageTemplate(dmName: definition.name, messageIndex: messageIndex),
                        timestamp: timestamp,
                        editedAt: nil,
                        senderDisplayName: sender.displayName,
                        replyCount: seededDMThreadReplies(
                            parentMessageId: messageId,
                            dmName: definition.name,
                            messageIndex: messageIndex,
                            participants: participants,
                            timestamp: timestamp
                        ).count,
                        reactions: seededDMReactions(dmIndex: dmIndex, messageIndex: messageIndex, participants: participants),
                        attachments: seededDMAttachments(dmName: definition.name, messageIndex: messageIndex, messageId: messageId),
                        threadReplies: seededDMThreadReplies(
                            parentMessageId: messageId,
                            dmName: definition.name,
                            messageIndex: messageIndex,
                            participants: participants,
                            timestamp: timestamp
                        ),
                        mentionUserIds: mentionCurrentUser ? [currentUserId] : [],
                        isUnread: isUnreadDMMessage(dmIndex: dmIndex, messageIndex: messageIndex, dmMessageCount: dmMessageCount)
                    )
                    messages.append(message)
                    trackedMessageIds.append(messageId)
                }
            }

            let latest = messages.max(by: { $0.timestamp < $1.timestamp })
            builtDMs.append(
                DMConversation(
                    id: definition.id,
                    name: definition.name,
                    participantIds: definition.participantIds,
                    isGroup: definition.isGroup,
                    isMuted: definition.isMutedByDefault,
                    unreadCount: messages.filter(\.isUnread).count,
                    mentionCount: messages.filter { $0.isUnread && $0.mentionUserIds.contains(currentUserId) }.count,
                    messages: messages,
                    lastMessagePreview: latest?.messageText ?? "No messages yet",
                    lastMessageAt: latest?.timestamp ?? seededDate(offsetHours: dateSeedOffsetHours + 180)
                )
            )
        }

        let lastUpdated = (builtChannels.flatMap(\.messages) + builtDMs.flatMap(\.messages))
            .map(\.timestamp)
            .max() ?? seededDate(offsetHours: dateSeedOffsetHours + 180)

        var workspace = Workspace(
            id: workspaceId,
            workspaceName: workspaceName,
            sourceType: sourceType,
            lastUpdated: lastUpdated,
            metadata: WorkspaceSnapshotMetadata(
                sourceLabel: sourceLabel,
                sourceType: sourceType,
                snapshotTimestamp: seededDate(offsetHours: dateSeedOffsetHours + 196),
                lastUpdated: lastUpdated
            ),
            currentUserId: currentUserId,
            userProfile: userProfile,
            members: members,
            channels: builtChannels,
            dmConversations: builtDMs,
            assignedItemMessageIds: Array(trackedMessageIds.prefix(6)),
            savedItemMessageIds: Array(trackedMessageIds.dropFirst(6).prefix(8)),
            draftsCount: draftsCount,
            nextMessageSequence: nextSequence
        )
        workspace.recalculateDerivedFields()
        return workspace
    }

    private static func makeMembers() -> [WorkspaceMember] {
        [
            WorkspaceMember(id: "member_jordan_avery", displayName: "Jordan Avery", username: "jordana", title: "Staff Automation Engineer", role: "Engineering", presenceState: .active, isCurrentUser: true),
            WorkspaceMember(id: "member_blair_morgan", displayName: "Blair Morgan", username: "blairm", title: "Engineering Manager", role: "Management", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_devon_hart", displayName: "Devon Hart", username: "devonh", title: "Product Lead", role: "Product", presenceState: .away, isCurrentUser: false),
            WorkspaceMember(id: "member_imani_brooks", displayName: "Imani Brooks", username: "imanib", title: "Senior iOS Engineer", role: "Engineering", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_jules_park", displayName: "Jules Park", username: "julesp", title: "Android Engineer", role: "Engineering", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_kai_santos", displayName: "Kai Santos", username: "kais", title: "Design Lead", role: "Design", presenceState: .away, isCurrentUser: false),
            WorkspaceMember(id: "member_lena_ortiz", displayName: "Lena Ortiz", username: "lenao", title: "Support Operations Lead", role: "Support", presenceState: .doNotDisturb, isCurrentUser: false),
            WorkspaceMember(id: "member_micah_chen", displayName: "Micah Chen", username: "micahc", title: "Site Reliability Engineer", role: "Operations", presenceState: .offline, isCurrentUser: false),
            WorkspaceMember(id: "member_nora_bennett", displayName: "Nora Bennett", username: "norab", title: "QA Engineer", role: "Quality", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_owen_price", displayName: "Owen Price", username: "owenp", title: "Data Analyst", role: "Analytics", presenceState: .away, isCurrentUser: false),
            WorkspaceMember(id: "member_riley_shah", displayName: "Riley Shah", username: "rileys", title: "Director of Product Operations", role: "Leadership", presenceState: .doNotDisturb, isCurrentUser: false),
            WorkspaceMember(id: "member_tessa_monroe", displayName: "Tessa Monroe", username: "tessam", title: "Recruiter", role: "People", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_maya_patel", displayName: "Maya Patel", username: "mayap", title: "Marketing Lead", role: "Marketing", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_leo_chen", displayName: "Leo Chen", username: "leoc", title: "Backend Engineer", role: "Engineering", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_wyatt_lin", displayName: "Wyatt Lin", username: "wyattl", title: "DevOps Engineer", role: "Engineering", presenceState: .away, isCurrentUser: false),
            WorkspaceMember(id: "member_sasha_volkov", displayName: "Sasha Volkov", username: "sashav", title: "Security Engineer", role: "Engineering", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_naomi_tanaka", displayName: "Naomi Tanaka", username: "naomit", title: "Frontend Engineer", role: "Engineering", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_rowan_byrne", displayName: "Rowan Byrne", username: "rowanb", title: "Agile Coach", role: "Operations", presenceState: .away, isCurrentUser: false),
            WorkspaceMember(id: "member_zara_okonkwo", displayName: "Zara Okonkwo", username: "zarao", title: "Growth Analyst", role: "Analytics", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_aiden_cross", displayName: "Aiden Cross", username: "aidenc", title: "Infrastructure Lead", role: "Engineering", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_petra_johansson", displayName: "Petra Johansson", username: "petraj", title: "UX Researcher", role: "Design", presenceState: .away, isCurrentUser: false),
            WorkspaceMember(id: "member_mateo_fuentes", displayName: "Mateo Fuentes", username: "mateof", title: "Release Manager", role: "Operations", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_quinn_harlow", displayName: "Quinn Harlow", username: "quinnh", title: "Technical Writer", role: "Documentation", presenceState: .active, isCurrentUser: false),
            WorkspaceMember(id: "member_devi_anand", displayName: "Devi Anand", username: "devia", title: "Mobile QA Lead", role: "Quality", presenceState: .doNotDisturb, isCurrentUser: false),
            WorkspaceMember(id: "member_samir_patel", displayName: "Samir Patel", username: "samirp", title: "Platform Engineer", role: "Engineering", presenceState: .offline, isCurrentUser: false)
        ]
    }

    private static func channelDefinitions(allMemberIds: [String]) -> [ChannelDefinition] {
        [
            ChannelDefinition(id: "channel_general", name: "general", topic: "Daily coordination, rollups, and team-wide updates", isPrivate: false, memberIds: allMemberIds, isMutedByDefault: false, isStarredByDefault: true),
            ChannelDefinition(id: "channel_announcements", name: "announcements", topic: "Milestones, stakeholder updates, and executive notes", isPrivate: false, memberIds: allMemberIds, isMutedByDefault: false, isStarredByDefault: false),
            ChannelDefinition(id: "channel_product", name: "product", topic: "Roadmap decisions, launch scope, and release readiness", isPrivate: false, memberIds: allMemberIds, isMutedByDefault: false, isStarredByDefault: false),
            ChannelDefinition(id: "channel_eng_mobile", name: "eng-mobile", topic: "iOS and Android implementation details, QA, and release blockers", isPrivate: false, memberIds: allMemberIds.filter { $0 != "member_tessa_monroe" }, isMutedByDefault: false, isStarredByDefault: true),
            ChannelDefinition(id: "channel_design", name: "design", topic: "Prototypes, accessibility reviews, and design handoff threads", isPrivate: false, memberIds: allMemberIds.filter { $0 != "member_micah_chen" }, isMutedByDefault: false, isStarredByDefault: false),
            ChannelDefinition(id: "channel_support_ops", name: "support-ops", topic: "Escalations, customer impact, and incident coordination", isPrivate: false, memberIds: allMemberIds.filter { $0 != "member_tessa_monroe" }, isMutedByDefault: false, isStarredByDefault: false),
            ChannelDefinition(id: "channel_launch_war_room", name: "launch-war-room", topic: "Cross-functional launch command channel", isPrivate: false, memberIds: allMemberIds.filter { $0 != "member_tessa_monroe" }, isMutedByDefault: false, isStarredByDefault: true),
            ChannelDefinition(id: "channel_random", name: "random", topic: "Lightweight team chatter and non-critical updates", isPrivate: false, memberIds: allMemberIds, isMutedByDefault: true, isStarredByDefault: false),
            ChannelDefinition(id: "channel_leadership", name: "leadership", topic: "Private staffing, launch tradeoffs, and cross-org decisions", isPrivate: true, memberIds: [currentUserId, "member_blair_morgan", "member_devon_hart", "member_riley_shah"], isMutedByDefault: false, isStarredByDefault: false),
            ChannelDefinition(id: "channel_incident_bridge", name: "incident-bridge", topic: "Private incident response bridge for high-severity issues", isPrivate: true, memberIds: [currentUserId, "member_blair_morgan", "member_lena_ortiz", "member_micah_chen", "member_nora_bennett", "member_riley_shah"], isMutedByDefault: false, isStarredByDefault: true),
            ChannelDefinition(id: "channel_hiring_panel", name: "hiring-panel", topic: "Private candidate review notes and interview synthesis", isPrivate: true, memberIds: [currentUserId, "member_blair_morgan", "member_kai_santos", "member_tessa_monroe"], isMutedByDefault: true, isStarredByDefault: false)
        ]
    }

    private static func dmDefinitions() -> [DMDefinition] {
        [
            DMDefinition(id: "dm_blair_morgan", name: "Blair Morgan", participantIds: [currentUserId, "member_blair_morgan"], isGroup: false, startsEmpty: false, isMutedByDefault: false),
            DMDefinition(id: "dm_devon_hart", name: "Devon Hart", participantIds: [currentUserId, "member_devon_hart"], isGroup: false, startsEmpty: false, isMutedByDefault: false),
            DMDefinition(id: "dm_imani_brooks", name: "Imani Brooks", participantIds: [currentUserId, "member_imani_brooks"], isGroup: false, startsEmpty: false, isMutedByDefault: false),
            DMDefinition(id: "dm_lena_ortiz", name: "Lena Ortiz", participantIds: [currentUserId, "member_lena_ortiz"], isGroup: false, startsEmpty: false, isMutedByDefault: false),
            DMDefinition(id: "dm_nora_bennett", name: "Nora Bennett", participantIds: [currentUserId, "member_nora_bennett"], isGroup: false, startsEmpty: false, isMutedByDefault: false),
            DMDefinition(id: "dm_riley_shah", name: "Riley Shah", participantIds: [currentUserId, "member_riley_shah"], isGroup: false, startsEmpty: false, isMutedByDefault: false),
            DMDefinition(id: "dm_launch_core", name: "Launch Core", participantIds: [currentUserId, "member_blair_morgan", "member_devon_hart", "member_imani_brooks"], isGroup: true, startsEmpty: false, isMutedByDefault: false),
            DMDefinition(id: "dm_support_triage", name: "Support Triage", participantIds: [currentUserId, "member_lena_ortiz", "member_micah_chen", "member_nora_bennett"], isGroup: true, startsEmpty: true, isMutedByDefault: true)
        ]
    }

    private static func seededDate(offsetHours: Int) -> Date {
        Date(timeIntervalSince1970: 1_770_321_600).addingTimeInterval(TimeInterval(offsetHours * 3600))
    }

    private static func shouldMentionCurrentUser(channelName: String, messageIndex: Int, channelMessageCount: Int) -> Bool {
        let mentionChannels = ["general", "product", "eng-mobile", "support-ops", "launch-war-room", "incident-bridge"]
        let mentionIndices = [1, 5, max(channelMessageCount - 3, 2), max(channelMessageCount - 1, 1)]
        return mentionChannels.contains(channelName) && mentionIndices.contains(messageIndex)
    }

    private static func shouldEditMessage(channelIndex: Int, messageIndex: Int) -> Bool {
        (channelIndex + messageIndex).isMultiple(of: 4) && messageIndex > 0
    }

    private static func isUnreadMessage(channelIndex: Int, messageIndex: Int, channelMessageCount: Int) -> Bool {
        messageIndex >= max(channelMessageCount - 3, 0) && channelIndex.isMultiple(of: 2)
    }

    private static func isUnreadDMMessage(dmIndex: Int, messageIndex: Int, dmMessageCount: Int) -> Bool {
        dmIndex < 4 && messageIndex >= max(dmMessageCount - 2, 0)
    }

    private static func channelMessageTemplate(
        workspaceName: String,
        channelName: String,
        messageIndex: Int,
        currentUsername: String,
        mentionCurrentUser: Bool
    ) -> String {
        let templates: [String]
        switch channelName {
        case "general":
            templates = [
                "\(workspaceName) launch checklist is refreshed with the overnight updates.",
                "Please drop blockers before the 10:30 sync so the rollup stays clean.",
                "The mobile release branch is green and the support macros are synced.",
                "Posting the handoff summary here so everyone has one source of truth.",
                "Reminder: if you update a customer-facing workflow, note it in the pinned checklist.",
                "I added the latest launch note draft and the fallback owner list.",
                "Quick heads-up: the staging environment will be down for maintenance from 2-3pm today.",
                "Retro action items from last sprint are posted in the pinned doc. Please check your assignments.",
                "FYI the new PTO policy is live in the wiki. Reach out to People Ops with questions.",
                "All-hands recording is uploaded if you missed it. Key takeaway: Q2 targets are unchanged.",
                "Shoutout to the mobile team for shipping the accessibility fixes ahead of schedule.",
                "CI pipeline is fully green across all branches. Nice work everyone.",
                "Weekly metrics digest is pinned. Activation rate is trending up for the second week.",
                "Office hours for the platform migration are Thursday at 2pm in the usual Zoom room.",
                "Parking lot items from today's standup: API versioning strategy, cache invalidation approach.",
                "Onboarding doc for new team members has been refreshed. Please review if you're a buddy.",
                "Security review for the release is complete. No blockers found.",
                "Heads-up: TeamChat maintenance window tonight between 11pm-1am, messages may be delayed.",
                "The cross-team dependency tracker is updated. Three items need follow-up this week.",
                "Happy Friday. Don't forget to submit your weekly status by end of day.",
                "Vendor integration testing is scheduled for next Tuesday. Owners please confirm your slots.",
                "The shared drive has been reorganized. Old links will redirect automatically.",
                "Bug bash results are in: 14 issues filed, 9 already triaged. Great turnout.",
                "Reminder: design review for the settings overhaul is tomorrow at 11am.",
                "Infrastructure cost report for this month is looking good, 12% under budget."
            ]
        case "announcements":
            templates = [
                "Leadership approved the staged rollout plan for tomorrow morning.",
                "Publishing the final stakeholder brief after QA signs off the release candidate.",
                "Please keep this channel high signal; operational chatter should stay in the working channels.",
                "The status page copy and customer note are both finalized.",
                "The finalized brief PDF is attached for offline review.",
                "We are officially code-complete for v3.2. Release candidate is being cut tonight.",
                "Company town hall is next Wednesday at 10am. Submit questions via the form in the pinned post.",
                "The board presentation went well. Positive feedback on our delivery cadence.",
                "New hire announcement: welcome Priya Mehta to the platform engineering team starting Monday.",
                "Q1 OKR scores are published. Engineering scored 0.82 overall.",
                "The partner integration launch is confirmed for March 15th. Marketing blast goes out same day.",
                "Compliance audit passed with zero critical findings. Thanks to everyone who contributed docs.",
                "Annual team survey is open through Friday. Your feedback shapes next quarter's priorities.",
                "Budget approval for the new monitoring tooling came through. Procurement starts next week.",
                "Customer Advisory Board session is scheduled for the 20th. Product team will present the roadmap.",
                "Engineering blog post about our migration is live. Feel free to share externally.",
                "Performance review cycle kicks off next Monday. Managers please prep your direct reports.",
                "We hit 99.97% uptime this quarter. Best number since launch.",
                "The internationalization effort is officially greenlit for Q2. More details in the product channel.",
                "Congratulations to the support team for achieving a 94% CSAT score this month."
            ]
        case "product":
            templates = [
                "Scope is locked for the first rollout wave; only regression fixes can be added now.",
                "Need confirmation on whether the onboarding nudge ships to all cohorts or only the pilot.",
                "The experiment flags are documented and ready for the launch runbook.",
                "I updated the backlog with the final owner map and rollout gates.",
                "Please review the feature link card before it gets pinned.",
                "User research findings from the beta cohort are summarized in the linked doc.",
                "We're seeing a 15% uplift in activation from the new onboarding flow. Keeping the experiment running another week.",
                "The feature flag for dark mode is ready for gradual rollout. Starting at 5% tomorrow.",
                "Competitive analysis deck is updated with the latest market moves. Worth a quick scan.",
                "PRD for the notification preferences redesign is ready for engineering review.",
                "Sprint planning output: 34 story points committed, 8 carry-over from last sprint.",
                "The A/B test on the checkout flow reached significance. Variant B wins by 8%.",
                "Customer feedback theme this month: search relevance and faster load times.",
                "Deprecation timeline for v2 API is finalized. Communication plan is in the thread.",
                "Roadmap prioritization session is Thursday. Please rank your top 3 items in the survey.",
                "Launch criteria checklist has been updated based on the go/no-go meeting.",
                "We need to decide on the default notification frequency before the release freeze.",
                "Analytics instrumentation for the new screens is complete. Dashboards are live.",
                "The localization vendor delivered translations for 12 languages. QA pass starts Monday.",
                "Feature usage data shows the quick-actions menu is used by 68% of daily active users."
            ]
        case "eng-mobile":
            templates = [
                "Latest CI pass is clean on the release branch and analytics are firing.",
                "We still have one flaky notification test, but the fallback path is verified.",
                "Posting the final build verification notes so QA can cross-check device coverage.",
                "If anyone sees launch animation jitter on older devices, note the exact build here.",
                "I attached a screenshot of the regression capture for reference.",
                "Can someone sanity-check the release build size before we freeze?",
                "iOS build 847 is up on TestFlight. Android build 302 is on the internal track.",
                "Memory profiling results: peak usage dropped from 280MB to 210MB after the image cache fix.",
                "The deep link handler refactor is merged. All existing routes are preserved.",
                "Crash-free rate is at 99.4% on the latest beta. The remaining crashes are in the media picker.",
                "Code review backlog is at 6 PRs. If you have bandwidth, please help clear the queue.",
                "The new SwiftUI list implementation is 40% faster on scroll benchmarks.",
                "Android Compose migration for the settings screen is complete. Needs a design review pass.",
                "Push notification token refresh logic has been updated to handle edge cases on iOS 17.",
                "Build time optimization: incremental builds are down to 45 seconds from 2 minutes.",
                "The accessibility audit flagged 3 missing labels on the profile screen. PR is up.",
                "Network layer retry logic now handles 429 responses with proper backoff.",
                "App startup time improved by 200ms after lazy-loading the analytics SDK.",
                "The biometric auth flow has been tested on Face ID and Touch ID devices. All green.",
                "Release branch has been cut. Only cherry-picks for P0 bugs from this point.",
                "Widget extension is now sharing data correctly via the app group container.",
                "Automated screenshot tests are passing on all 8 device configurations.",
                "The offline mode sync queue is handling conflicts correctly after the latest fix.",
                "Xcode 16.2 migration is complete. No deprecation warnings remaining."
            ]
        case "design":
            templates = [
                "Updated the confirmation states to tighten spacing on the compact layouts.",
                "Accessibility contrast pass is done for the launch banner and settings screens.",
                "Attaching the latest handoff boards so mobile can compare final spacing.",
                "Please keep iconography feedback in-thread so the implementation notes stay readable.",
                "Content review is complete except for the fallback empty-state copy.",
                "The component library has been updated with the new button variants.",
                "Motion spec for the transition animations is ready for engineering handoff.",
                "Dark mode color tokens are finalized. Preview link is in the thread.",
                "User testing results: 8 out of 10 participants completed the task without assistance.",
                "The icon set has been exported at 1x, 2x, and 3x. Asset catalog is updated.",
                "Typography scale adjustments are minimal. Only the caption size changed from 11pt to 12pt.",
                "The loading skeleton screens are designed. They follow the same layout as the loaded state.",
                "Error state illustrations are done for the 4 main error categories.",
                "Spacing audit revealed 3 inconsistencies between iOS and Android. Fixes are documented.",
                "The settings redesign mockups are in Figma. Comment directly on the frames.",
                "Color contrast ratios all meet WCAG AA. Two screens now meet AAA as well.",
                "The onboarding carousel has been simplified from 5 steps to 3 based on analytics.",
                "Interaction patterns for swipe-to-archive are spec'd. Haptic feedback is included.",
                "Design system versioning: we're on v2.4 as of this morning.",
                "The empty state for search results has a new illustration. Feedback welcome."
            ]
        case "support-ops":
            templates = [
                "Escalation volume is stable; only two tickets are waiting on engineering follow-up.",
                "The latest support macro set is uploaded for review.",
                "Please tag anything customer-visible so we can track it in the handoff note.",
                "Attaching the updated escalation rubric PDF for the team.",
                "The contact center brief is ready once launch timing is confirmed.",
                "Average first response time this week: 4 minutes. Down from 7 last week.",
                "Three enterprise customers flagged the same search issue. Engineering is aware.",
                "The knowledge base article for the new billing flow is published and linked in macros.",
                "Weekend coverage schedule is confirmed. Lena and Jordan have primary/secondary.",
                "Ticket backlog is at 23, down from 41 at the start of the week.",
                "Customer sentiment analysis for this release cycle is positive. NPS up 6 points.",
                "The chatbot deflection rate improved to 34% after the last training update.",
                "VIP customer list has been updated. Routing rules are active.",
                "The internal support tool got a speed improvement. Page load is under 2 seconds now.",
                "Training session for the new triage workflow is recorded and posted in the wiki.",
                "Common issue tracker: password reset flow accounts for 28% of all tickets this month.",
                "SLA compliance is at 97.3%. Two breaches were due to the overnight queue delay.",
                "Feature request roundup: top 3 asks are bulk actions, export to CSV, and dark mode.",
                "The canned response library has 12 new templates for the upcoming features.",
                "End-of-month support metrics report is ready for leadership review."
            ]
        case "launch-war-room":
            templates = [
                "The command timeline is live. Please keep owner updates short and timestamped.",
                "Monitoring dashboards are healthy and the rollback gate is still open.",
                "Shared the rollback dashboard link for offline review.",
                "If the launch slips, we can hold the support macro update until the next window.",
                "Need explicit sign-off from mobile, QA, and support before the final switch.",
                "T-minus 4 hours. All pre-launch checks are green. Feature flags are staged.",
                "Database migration completed successfully. Read replicas are synced.",
                "CDN cache has been warmed for all regions. Latency looks normal.",
                "Marketing email is queued and will fire 30 minutes after the feature flag goes live.",
                "Status page is updated to reflect the maintenance window.",
                "Load test results from this morning: 3x normal traffic handled without degradation.",
                "Rollout plan: 1% at launch, 10% at +1h, 50% at +4h, 100% at +24h if metrics hold.",
                "Comms channel with the executive team is open. Updates every 30 minutes during rollout.",
                "The canary deployment is live and processing traffic. No anomalies in the first 15 minutes.",
                "App Store and Play Store listings are updated. Screenshots reflect the new UI.",
                "Backend services are all running the new version. Backward compatibility is confirmed.",
                "Customer support is on standby with the prepared FAQ and escalation paths.",
                "Datadog alerts are configured for error rate > 0.5% and p99 latency > 2s.",
                "First 1% rollout metrics: error rate 0.02%, p99 latency 340ms. Looking good.",
                "Expanding to 10%. Will hold here for one hour before the next increment."
            ]
        case "random":
            templates = [
                "Team coffee order closes in ten minutes if anyone wants in.",
                "The launch playlist is somehow mostly acceptable this time.",
                "Sharing a low-stakes morale win: zero merge conflicts this morning.",
                "Reminder that the post-launch retro snacks are still undecided.",
                "Anyone else's IDE theme look different after the update? Asking for a friend.",
                "TIL you can hold Option and click in Xcode to get inline docs. Life changed.",
                "The office plants are thriving. Whatever the cleaning crew is doing, keep it up.",
                "Friday lunch poll: Thai or Mediterranean? Reply with your vote.",
                "Found a great article on SwiftUI performance tips. Link in thread.",
                "Happy birthday to Jules! Virtual cake in the break room.",
                "The new standing desks arrived. First come, first served on the adjustable ones.",
                "Who left a rubber duck on every desk? Not complaining, just curious.",
                "Movie night suggestion thread: drop your picks below.",
                "The vending machine now has sparkling water. This is not a drill.",
                "Trivia question of the day: what year was the first iPhone released? No googling.",
                "Book club pick for this month: Designing Data-Intensive Applications.",
                "The building AC is fixed. No more wearing hoodies indoors in July.",
                "Someone's lunch smells incredible. Whoever made curry, I need the recipe.",
                "Game night this Thursday. Board games and snacks. RSVP in thread.",
                "The sunset from the office today was unreal. Photo in thread."
            ]
        case "leadership":
            templates = [
                "Staffing coverage is confirmed for the launch weekend follow-the-sun rotation.",
                "Need a final call on whether we expand the pilot after the first twelve hours.",
                "The board-facing summary is ready once the rollout window starts.",
                "Please keep external messaging notes in this thread only.",
                "Headcount request for Q2 has been submitted. Expecting approval by end of week.",
                "The reorg proposal is drafted. Let's review before sharing with the broader team.",
                "Budget variance for this quarter: 3% under on engineering, 1% over on infrastructure.",
                "Performance calibration session is next Wednesday. Please prep your team's ratings.",
                "The competitor launched their equivalent feature yesterday. Our differentiation points are clear.",
                "Retention metrics look solid. Voluntary attrition is at 4% annualized.",
                "Cross-team resource conflict on the data pipeline project needs resolution this week.",
                "Executive sponsor for the platform initiative confirmed. Kickoff is next Monday.",
                "Risk assessment for the launch: two medium items, both with mitigation plans.",
                "The engineering culture survey results are in. High marks on autonomy, lower on tooling satisfaction.",
                "Strategic planning offsite is confirmed for April 10-11. Agenda draft is in the doc.",
                "The vendor contract renewal is up. Negotiation points are summarized in thread.",
                "Succession planning document has been updated for all director-level roles.",
                "Customer escalation from the enterprise segment needs executive visibility.",
                "The hiring pipeline has 12 candidates in final rounds across 3 roles.",
                "Quarterly business review deck is 80% done. Need finance inputs by Thursday."
            ]
        case "incident-bridge":
            templates = [
                "Keeping this bridge warm until the final monitoring checks are complete.",
                "If the error budget moves, post the exact metric and timestamp immediately.",
                "The customer escalation path is documented and owned for the next six hours.",
                "Logging a runbook reference so every responder has the same fallback steps.",
                "Incident commander for this shift: Blair. On-call secondary: Micah.",
                "Error rate spike at 14:32 UTC. Investigating. Currently at 0.8%, threshold is 1%.",
                "Root cause identified: a misconfigured rate limiter on the auth service. Fix is being deployed.",
                "Customer impact assessment: approximately 200 users saw login failures over a 12-minute window.",
                "Fix deployed at 14:51 UTC. Error rate returning to baseline. Monitoring for 30 minutes.",
                "All-clear at 15:22 UTC. Error rate is back to 0.03%. Incident downgraded to P3.",
                "Post-incident review is scheduled for tomorrow at 2pm. Timeline draft is in the doc.",
                "Action items from last incident: improve alerting granularity and add circuit breaker to auth flow.",
                "The monitoring gap that delayed detection has been closed. New alert rule is active.",
                "Communication timeline: status page updated at +3min, customer email at +15min, all-clear at +50min.",
                "Failover test results: secondary region picked up traffic in under 90 seconds.",
                "The runbook has been updated with lessons learned from the last three incidents.",
                "Database connection pool exhaustion alert fired but self-healed. Adding it to the watch list.",
                "Capacity planning review: current headroom is 3x normal peak. Comfortable for the launch.",
                "The on-call handoff checklist has been updated. Please review before your next rotation.",
                "Dependency health check: all third-party services are reporting green."
            ]
        case "hiring-panel":
            templates = [
                "Consolidated the candidate debrief notes into one summary.",
                "Please leave calibration feedback before tomorrow's committee review.",
                "Sharing the interview packet PDF for reference.",
                "Need one final thumbs-up on the rubric wording.",
                "Candidate A showed strong system design skills. Full scorecard is in the doc.",
                "Phone screen conversion rate this month: 62%. Above our 55% target.",
                "The take-home assignment rubric has been simplified. Two criteria were redundant.",
                "Interview panel for the senior role next week: Blair, Kai, and Jordan.",
                "Candidate B withdrew. They accepted another offer. Adjusting the pipeline.",
                "Diversity sourcing initiative generated 8 new candidates this week.",
                "Reference check for Candidate C came back very positive. Strong recommendation from former manager.",
                "The job description for the platform role has been updated based on feedback.",
                "Offer letter template has been refreshed with the new equity bands.",
                "Hiring committee meeting moved to Thursday at 3pm. Please confirm attendance.",
                "We need to close the mobile QA role by end of month. Two finalists remain.",
                "The recruiter screen questions have been updated to better assess cultural alignment.",
                "Candidate pipeline dashboard is refreshed. 23 active candidates across 4 roles.",
                "Interview feedback turnaround time has improved to 24 hours. Keep it up.",
                "The campus recruiting event is next month. Need 3 volunteers for the booth.",
                "Compensation benchmarking data is updated. Our offers are competitive at the 65th percentile."
            ]
        default:
            templates = [
                "\(workspaceName) update posted for #\(channelName).",
                "Please keep follow-ups in thread so the channel stays readable.",
                "Cross-posting the relevant update from the main working channel.",
                "Added context to the pinned items. Please review when you have a moment.",
                "Quick status update: everything is tracking on schedule.",
                "FYI: the shared doc has been updated with the latest decisions.",
                "Tagging the relevant owners for visibility.",
                "End-of-day summary posted. Key items are highlighted at the top.",
                "Linking the related discussion for context.",
                "No blockers on our end. Will update if anything changes."
            ]
        }

        var message = templates[messageIndex % templates.count]
        if mentionCurrentUser {
            message += " @\(currentUsername)"
        }
        return message
    }

    private static func dmMessageTemplate(dmName: String, messageIndex: Int) -> String {
        let templates: [String]
        switch dmName {
        case "Blair Morgan":
            templates = [
                "Hey, can you take a look at the staffing plan before I send it out?",
                "The 1:1 agenda is updated. I added the topic about the sprint retro feedback.",
                "Quick question: do we need sign-off from Riley before moving forward on the reorg?",
                "Thanks for the context on the hiring timeline. I'll adjust the roadmap accordingly.",
                "Heads up, I'm going to push back on the deadline in tomorrow's meeting. Wanted you to know first.",
                "The performance review drafts are ready. Can you do a final pass by Thursday?",
                "I spoke with Devon about the scope change. They're aligned with our approach.",
                "Do you have 15 minutes today? Want to walk through the incident response improvements.",
                "The team morale check-in went well. A few action items I'll share in our 1:1.",
                "FYI I approved the PTO requests. Coverage is handled.",
                "The budget numbers look good. We're under by about 8% which gives us room for the new tooling.",
                "Can we move our Thursday sync to 3pm? I have a conflict with the leadership meeting.",
                "Good call on flagging the dependency risk early. It saved us at least a week.",
                "I finished the draft for the engineering blog post. Mind giving it a read?",
                "The new hire's onboarding plan is set. Their buddy is Imani."
            ]
        case "Devon Hart":
            templates = [
                "Can you sanity-check the latest scope doc before I share it with the team?",
                "The PRD feedback from engineering is incorporated. Ready for your final review.",
                "If the timeline slips, I can pick up the first pass after the standup window.",
                "The user research results are interesting. Let's discuss in our next sync.",
                "Quick update: the feature flag is ready for the A/B test whenever product gives the green light.",
                "Do we have a final decision on the notification frequency? Engineering needs to know by Friday.",
                "I updated the launch criteria doc based on our conversation yesterday.",
                "The competitive analysis is done. Short version: we're ahead on features, behind on onboarding.",
                "Wanted to flag that the beta feedback is overwhelmingly positive on the new search.",
                "The roadmap presentation for the board is looking great. Small tweak on slide 7.",
                "Can we prioritize the export feature? Three enterprise customers asked about it this week.",
                "The analytics dashboard for the new flow is live. Early numbers look promising.",
                "I think we should defer the settings redesign to next quarter. Too much in flight.",
                "Thanks for pushing back on the scope creep. The team appreciates the clarity.",
                "Meeting notes from the partner call are in the shared doc."
            ]
        case "Imani Brooks":
            templates = [
                "The PR for the SwiftUI migration is up. Would love your review when you get a chance.",
                "Found a workaround for the iOS 17 keyboard issue. Posting details in eng-mobile.",
                "Can you pair on the network layer refactor tomorrow morning?",
                "Thanks for the code review feedback. I addressed all the comments and pushed a new commit.",
                "The build comparison screenshot shows the memory improvement clearly.",
                "Quick question: are you using the new Xcode instruments template for profiling?",
                "I'm stuck on a concurrency issue with the sync queue. Mind taking a look?",
                "The unit test coverage for the auth module is now at 87%. Up from 72%.",
                "FYI the crash we were tracking is fixed in build 849. Can you verify on your device?",
                "Great catch on the retain cycle. That would have been a nasty bug in production.",
                "The app startup benchmark is consistently under 1.2 seconds now.",
                "I pushed the accessibility fixes for VoiceOver. Can you test on your end?",
                "Do you have the device matrix for the final QA pass? I want to make sure we cover the iPad mini.",
                "The widget extension is working on my end. Let me know if you see any issues.",
                "Lunch today? I want to pick your brain about the architecture for the offline sync."
            ]
        case "Lena Ortiz":
            templates = [
                "The escalation from this morning has been resolved. Customer confirmed the fix.",
                "Can you review the updated support macros before we push them live?",
                "The CSAT scores for this week are looking really good. Nice work on the training updates.",
                "Heads up: we might get a surge of tickets after the rollout tomorrow.",
                "I drafted the customer communication for the scheduled maintenance. Take a look?",
                "The VIP customer flagged an issue with the export feature. Engineering is looking into it.",
                "Weekend coverage is set. I'll take Saturday, you have Sunday.",
                "The knowledge base migration is almost done. 95% of articles are moved over.",
                "Quick sync on the support tool improvements? I have some ideas from the team feedback.",
                "The chatbot training data has been updated. Deflection rate should improve.",
                "Thanks for handling the overnight escalation. That was a tricky one.",
                "The quarterly support metrics report is ready. Highlights: response time down 40%.",
                "Can we discuss the tier structure changes? I think we need one more level.",
                "The integration with the CRM is live. Ticket context is now pulling in automatically.",
                "Customer feedback roundup is in the shared doc. A few recurring themes to address."
            ]
        case "Nora Bennett":
            templates = [
                "The regression suite passed on all configurations. Green across the board.",
                "Found a new edge case in the payment flow. Filing a bug now.",
                "Can we go over the test plan for the upcoming release? I want to make sure nothing slips.",
                "The automated test coverage report is attached. We're at 84% overall.",
                "Quick heads up: the staging environment is flaky today. Tests might need reruns.",
                "I wrote new test cases for the offline sync feature. Ready for review.",
                "The performance test results look solid. No regressions from the last build.",
                "Do you want me to add the new screens to the screenshot test suite?",
                "The accessibility testing checklist has been updated for the latest WCAG guidelines.",
                "Found and logged 3 issues during exploratory testing. All P2 or lower.",
                "The test environment is refreshed with production-like data. Should be more realistic now.",
                "Can you check if the flaky test on line 247 is still failing? I think my fix went in.",
                "Device lab is reserved for Thursday afternoon. I booked 4 hours for the full pass.",
                "The load testing script needs an update for the new API endpoints.",
                "Great news: zero new bugs found in the smoke test for the release candidate."
            ]
        case "Riley Shah":
            templates = [
                "The ops review deck is ready. Want to do a dry run before the leadership meeting?",
                "Quick question on the resource allocation for Q2. Do we have flexibility on headcount?",
                "The vendor evaluation is complete. Recommendation is in the shared doc.",
                "Thanks for advocating for the tooling budget. The team is excited about the new monitoring stack.",
                "The process improvement initiative is showing results. Cycle time is down 20%.",
                "Can we sync on the cross-team dependency before the planning session?",
                "I need your input on the escalation policy changes. A few edge cases to discuss.",
                "The launch readiness review went smoothly. All workstreams are green.",
                "FYI the quarterly business review is moved to next week. Same time.",
                "The team health survey results are encouraging. Two areas to focus on for next quarter.",
                "Budget reforecast is done. We're in good shape unless scope changes significantly.",
                "The stakeholder communication plan for the launch is drafted. Your review would be helpful.",
                "Interesting data point: our deployment frequency doubled this quarter vs last.",
                "The risk register has been updated. One new item related to the third-party API dependency.",
                "Meeting with the partner team went well. Follow-up actions are in the notes."
            ]
        case "Launch Core":
            templates = [
                "Sync check: everyone still good for the launch window tomorrow?",
                "I left the main decision in thread so the context stays searchable later.",
                "The rollout owners doc is attached. Please confirm your sections by end of day.",
                "Quick status round: any blockers or concerns before we lock the timeline?",
                "The rehearsal went smoothly. Only one minor adjustment to the rollback procedure.",
                "Updated the communication plan. Customer email goes out 30 minutes post-launch.",
                "Can everyone join 15 minutes early tomorrow for the final checklist review?",
                "Monitoring thresholds are configured. We'll get alerts if anything crosses the red line.",
                "The go/no-go decision is confirmed. We are a go for tomorrow at 9am.",
                "Post-launch retro is scheduled for Thursday at 2pm. Please add topics to the doc.",
                "All pre-launch tasks are complete. The checklist is fully green.",
                "Thanks team. That was one of the smoothest launches we've done.",
                "Day 1 metrics are in: 0 P0 bugs, error rate at 0.01%, activation up 12%.",
                "The 24-hour stability report looks great. Expanding to 100% as planned.",
                "Celebrating this one. Everyone's contributions made a real difference."
            ]
        default:
            templates = [
                "Can you sanity-check the latest note before I post it?",
                "I left the main decision in thread so the context stays searchable later.",
                "If this slips, I can pick up first pass after the standup window.",
                "Thanks - I updated the checklist and the shared document.",
                "Quick follow-up on our earlier conversation. I think we're aligned.",
                "Let me know if you need anything else from my end.",
                "Sounds good. I'll update the doc and circle back.",
                "The notes from our last sync are in the shared folder.",
                "Just wanted to confirm: we're still on for the review tomorrow?",
                "Appreciate the quick turnaround on that. Really helpful.",
                "I'll take the first action item. Can you handle the second one?",
                "FYI I updated the timeline based on our discussion.",
                "Makes sense. Let's revisit this after the release.",
                "All good on my end. Let me know if anything changes.",
                "Thanks for the heads up. I'll adjust my plans accordingly."
            ]
        }
        return templates[messageIndex % templates.count]
    }

    private static func pinnedPlaceholderCount(for channelName: String) -> Int {
        switch channelName {
        case "general", "launch-war-room":
            return 3
        case "product", "support-ops":
            return 2
        default:
            return 1
        }
    }

    private static func filesPlaceholderCount(for channelName: String) -> Int {
        switch channelName {
        case "eng-mobile":
            return 5
        case "design", "support-ops":
            return 4
        default:
            return 2
        }
    }

    private static func linksPlaceholderCount(for channelName: String) -> Int {
        switch channelName {
        case "product":
            return 8
        case "launch-war-room", "incident-bridge":
            return 6
        default:
            return 3
        }
    }

    private static func seededBookmarks(for channelName: String) -> [ChannelBookmark] {
        switch channelName {
        case "general":
            return [
                ChannelBookmark(id: "bk_general_1", title: "Meeting Notes", emoji: "\u{1F4DD}", type: "canvas"),
                ChannelBookmark(id: "bk_general_2", title: "Standup", emoji: "\u{1F4CB}", type: "workflow"),
                ChannelBookmark(id: "bk_general_3", title: "Team Wiki", emoji: "\u{1F4D6}", type: "link")
            ]
        case "eng-mobile":
            return [
                ChannelBookmark(id: "bk_eng_1", title: "Release Checklist", emoji: "\u{2705}", type: "canvas"),
                ChannelBookmark(id: "bk_eng_2", title: "Docs", emoji: "\u{1F4C4}", type: "link"),
                ChannelBookmark(id: "bk_eng_3", title: "CI Dashboard", emoji: "\u{1F4CA}", type: "link")
            ]
        case "product":
            return [
                ChannelBookmark(id: "bk_product_1", title: "Roadmap", emoji: "\u{1F5FA}", type: "canvas"),
                ChannelBookmark(id: "bk_product_2", title: "PRD Template", emoji: "\u{1F4DD}", type: "link")
            ]
        case "launch-war-room":
            return [
                ChannelBookmark(id: "bk_launch_1", title: "Runbook", emoji: "\u{1F4D3}", type: "canvas"),
                ChannelBookmark(id: "bk_launch_2", title: "Rollout Plan", emoji: "\u{1F680}", type: "canvas"),
                ChannelBookmark(id: "bk_launch_3", title: "Status Page", emoji: "\u{1F4CA}", type: "link")
            ]
        case "design":
            return [
                ChannelBookmark(id: "bk_design_1", title: "Figma Board", emoji: "\u{1F3A8}", type: "link"),
                ChannelBookmark(id: "bk_design_2", title: "Design System", emoji: "\u{1F4D0}", type: "link")
            ]
        case "support-ops":
            return [
                ChannelBookmark(id: "bk_support_1", title: "Escalation Rubric", emoji: "\u{1F6A8}", type: "canvas"),
                ChannelBookmark(id: "bk_support_2", title: "Standup", emoji: "\u{1F4CB}", type: "workflow"),
                ChannelBookmark(id: "bk_support_3", title: "Macro Library", emoji: "\u{1F4DA}", type: "link")
            ]
        case "incident-bridge":
            return [
                ChannelBookmark(id: "bk_incident_1", title: "Incident Runbook", emoji: "\u{1F4D3}", type: "canvas"),
                ChannelBookmark(id: "bk_incident_2", title: "Status Page", emoji: "\u{1F4CA}", type: "link")
            ]
        case "announcements":
            return [
                ChannelBookmark(id: "bk_announce_1", title: "Project Plan", emoji: "\u{1F4CA}", type: "canvas"),
                ChannelBookmark(id: "bk_announce_2", title: "Docs", emoji: "\u{1F4C4}", type: "link")
            ]
        default:
            return [
                ChannelBookmark(id: "bk_\(channelName)_1", title: "Meeting Notes", emoji: "\u{1F4DD}", type: "canvas"),
                ChannelBookmark(id: "bk_\(channelName)_2", title: "Docs", emoji: "\u{1F4C4}", type: "link")
            ]
        }
    }

    private static let reactionEmojiPool = ["👍", "👀", "✅", "🎉", "🙌", "💯", "🚀", "❤️", "👏", "🔥", "💪", "⭐"]

    private static func seededReactions(
        channelIndex: Int,
        messageIndex: Int,
        currentUserId: String,
        participants: [WorkspaceMember]
    ) -> [Reaction] {
        var reactions: [Reaction] = []
        let seed = channelIndex * 31 + messageIndex * 7

        // Primary reaction: thumbs up on every 2nd message
        if (channelIndex + messageIndex).isMultiple(of: 2), let teammate = participants[safe: (messageIndex + 1) % max(participants.count, 1)] {
            let emoji = reactionEmojiPool[seed % reactionEmojiPool.count]
            var userIds = [currentUserId, teammate.id]
            // Sometimes add a third reactor
            if messageIndex.isMultiple(of: 3), let extra = participants[safe: (messageIndex + 3) % max(participants.count, 1)], extra.id != currentUserId && extra.id != teammate.id {
                userIds.append(extra.id)
            }
            reactions.append(Reaction(reactionEmoji: emoji, userIds: userIds, reactionCount: userIds.count))
        }

        // Secondary reaction: eyes or fire on every 3rd message
        if (channelIndex + messageIndex).isMultiple(of: 3), let teammate = participants[safe: (messageIndex + 2) % max(participants.count, 1)] {
            let emoji = reactionEmojiPool[(seed + 3) % reactionEmojiPool.count]
            // Avoid duplicate emoji
            if reactions.first?.reactionEmoji != emoji {
                let userIds = [teammate.id]
                reactions.append(Reaction(reactionEmoji: emoji, userIds: userIds, reactionCount: userIds.count))
            }
        }

        // Tertiary reaction: celebration on every 5th message
        if messageIndex.isMultiple(of: 5) && messageIndex > 0, let teammate = participants[safe: (messageIndex + 4) % max(participants.count, 1)] {
            let emoji = reactionEmojiPool[(seed + 7) % reactionEmojiPool.count]
            if !reactions.contains(where: { $0.reactionEmoji == emoji }) {
                var userIds = [teammate.id, currentUserId]
                if let extra = participants[safe: (messageIndex + 5) % max(participants.count, 1)], !userIds.contains(extra.id) {
                    userIds.append(extra.id)
                }
                reactions.append(Reaction(reactionEmoji: emoji, userIds: userIds, reactionCount: userIds.count))
            }
        }

        return reactions
    }

    private static func seededDMReactions(
        dmIndex: Int,
        messageIndex: Int,
        participants: [WorkspaceMember]
    ) -> [Reaction] {
        guard let teammate = participants[safe: min(1, max(participants.count - 1, 0))] else {
            return []
        }

        var reactions: [Reaction] = []
        let seed = dmIndex * 13 + messageIndex * 5

        // React on every 3rd message
        if messageIndex.isMultiple(of: 3) || messageIndex == 0 {
            let emoji = reactionEmojiPool[seed % reactionEmojiPool.count]
            reactions.append(Reaction(reactionEmoji: emoji, userIds: [currentUserId, teammate.id], reactionCount: 2))
        }

        // Additional reaction on some messages
        if (dmIndex + messageIndex).isMultiple(of: 4) && messageIndex > 0 {
            let emoji = reactionEmojiPool[(seed + 5) % reactionEmojiPool.count]
            if !reactions.contains(where: { $0.reactionEmoji == emoji }) {
                reactions.append(Reaction(reactionEmoji: emoji, userIds: [teammate.id], reactionCount: 1))
            }
        }

        return reactions
    }

    private static func seededAttachments(channelName: String, messageIndex: Int, messageId: String) -> [MessageAttachment] {
        switch (channelName, messageIndex) {
        case ("announcements", 4):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Executive launch brief.pdf",
                    subtitle: "3 pages - Updated today",
                    localPath: "Resources/placeholder_launch_brief.pdf"
                )
            ]
        case ("announcements", 11):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Compliance audit report.pdf",
                    subtitle: "5 pages - Audit findings",
                    localPath: "Resources/placeholder_launch_brief.pdf"
                )
            ]
        case ("product", 4):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Launch tracker",
                    subtitle: "internal://launch/tracker",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        case ("product", 8):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Competitive analysis deck",
                    subtitle: "internal://product/competitive-analysis",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        case ("product", 15):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Launch criteria checklist.pdf",
                    subtitle: "1 page - Go/no-go criteria",
                    localPath: "Resources/placeholder_launch_brief.pdf"
                )
            ]
        case ("eng-mobile", 4):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Regression capture.png",
                    subtitle: "Screenshot - 1242x2688",
                    localPath: "Resources/placeholder_regression_capture.png"
                )
            ]
        case ("eng-mobile", 7):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Memory profiling results.png",
                    subtitle: "Screenshot - Instruments output",
                    localPath: "Resources/placeholder_regression_capture.png"
                )
            ]
        case ("eng-mobile", 14):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Build time optimization PR",
                    subtitle: "internal://eng/pr/1847",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        case ("design", 2):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Final handoff boards.png",
                    subtitle: "Image - 2400x1600",
                    localPath: "Resources/placeholder_handoff_boards.png"
                )
            ]
        case ("design", 7):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Dark mode token preview",
                    subtitle: "internal://design/dark-mode-tokens",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        case ("design", 12):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Error state illustrations.png",
                    subtitle: "Image - 4 error categories",
                    localPath: "Resources/placeholder_handoff_boards.png"
                )
            ]
        case ("support-ops", 3):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Escalation rubric.pdf",
                    subtitle: "2 pages - Escalation matrix v3",
                    localPath: "Resources/placeholder_escalation_rubric.pdf"
                )
            ]
        case ("support-ops", 11):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "CSAT dashboard",
                    subtitle: "internal://support/csat-dashboard",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        case ("launch-war-room", 2):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Rollback dashboard",
                    subtitle: "internal://ops/rollback-dashboard",
                    localPath: "Resources/placeholder_rollback_dashboard.link"
                )
            ]
        case ("launch-war-room", 10):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Load test results",
                    subtitle: "internal://ops/load-test-report",
                    localPath: "Resources/placeholder_rollback_dashboard.link"
                )
            ]
        case ("launch-war-room", 17):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Datadog alert configuration.png",
                    subtitle: "Screenshot - Alert thresholds",
                    localPath: "Resources/placeholder_regression_capture.png"
                )
            ]
        case ("incident-bridge", 6):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Error rate graph.png",
                    subtitle: "Screenshot - Error rate spike and recovery",
                    localPath: "Resources/placeholder_regression_capture.png"
                )
            ]
        case ("incident-bridge", 15):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Updated runbook.pdf",
                    subtitle: "4 pages - Incident response v2",
                    localPath: "Resources/placeholder_escalation_rubric.pdf"
                )
            ]
        case ("hiring-panel", 2):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Interview packet.pdf",
                    subtitle: "6 pages - Candidate materials",
                    localPath: "Resources/placeholder_launch_brief.pdf"
                )
            ]
        case ("hiring-panel", 12):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Offer letter template",
                    subtitle: "internal://hr/offer-template",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        default:
            return []
        }
    }

    private static func seededDMAttachments(dmName: String, messageIndex: Int, messageId: String) -> [MessageAttachment] {
        switch (dmName, messageIndex) {
        case ("Blair Morgan", 3):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Staffing plan Q2.pdf",
                    subtitle: "2 pages - Headcount proposals",
                    localPath: "Resources/placeholder_rollout_owners.pdf"
                )
            ]
        case ("Blair Morgan", 10):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Budget tracker",
                    subtitle: "internal://finance/eng-budget",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        case ("Devon Hart", 2):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Scope recap",
                    subtitle: "internal://product/scope-recap",
                    localPath: "Resources/placeholder_scope_recap.link"
                )
            ]
        case ("Devon Hart", 7):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Competitive analysis",
                    subtitle: "internal://product/competitive-deck",
                    localPath: "Resources/placeholder_scope_recap.link"
                )
            ]
        case ("Imani Brooks", 3):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Build comparison.png",
                    subtitle: "Image - Side-by-side comparison",
                    localPath: "Resources/placeholder_build_comparison.png"
                )
            ]
        case ("Imani Brooks", 7):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Test coverage report.png",
                    subtitle: "Image - Coverage breakdown",
                    localPath: "Resources/placeholder_build_comparison.png"
                )
            ]
        case ("Lena Ortiz", 5):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Customer communication draft.pdf",
                    subtitle: "1 page - Maintenance notice",
                    localPath: "Resources/placeholder_escalation_rubric.pdf"
                )
            ]
        case ("Nora Bennett", 3):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Test coverage report.pdf",
                    subtitle: "3 pages - Coverage by module",
                    localPath: "Resources/placeholder_escalation_rubric.pdf"
                )
            ]
        case ("Riley Shah", 4):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Vendor evaluation",
                    subtitle: "internal://ops/vendor-eval",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        case ("Launch Core", 1):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_pdf",
                    attachmentType: .pdf,
                    title: "Rollout owners.pdf",
                    subtitle: "1 page - Owner assignments",
                    localPath: "Resources/placeholder_rollout_owners.pdf"
                )
            ]
        case ("Launch Core", 5):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_link",
                    attachmentType: .link,
                    title: "Communication plan",
                    subtitle: "internal://launch/comms-plan",
                    localPath: "Resources/placeholder_launch_tracker.link"
                )
            ]
        case ("Launch Core", 12):
            return [
                MessageAttachment(
                    id: "\(messageId)_a_image",
                    attachmentType: .image,
                    title: "Day 1 metrics dashboard.png",
                    subtitle: "Screenshot - Launch day metrics",
                    localPath: "Resources/placeholder_build_comparison.png"
                )
            ]
        default:
            return []
        }
    }

    private static func seededThreadReplies(
        parentMessageId: String,
        channelName: String,
        messageIndex: Int,
        participants: [WorkspaceMember],
        timestamp: Date
    ) -> [ThreadReply] {
        // Threads on messages at indices 1, 3, 4, 7, 10, 13, 16, 19
        let threadedIndices = [1, 3, 4, 7, 10, 13, 16, 19]
        guard threadedIndices.contains(messageIndex), participants.count >= 2 else {
            return []
        }

        // Determine reply count: 3-6 replies based on message index
        let replyCount: Int
        switch messageIndex {
        case 1, 7, 13:
            replyCount = 5
        case 4, 10, 19:
            replyCount = 4
        case 3, 16:
            replyCount = 3
        default:
            replyCount = 3
        }

        var replies: [ThreadReply] = []
        for replyIdx in 0..<replyCount {
            let responder = participants[(messageIndex + replyIdx + 1) % participants.count]
            let replyReactions: [Reaction]
            if replyIdx == 0 {
                replyReactions = [Reaction(reactionEmoji: "✅", userIds: [currentUserId], reactionCount: 1)]
            } else if replyIdx == 2, let reactor = participants[safe: (messageIndex + replyIdx + 3) % participants.count] {
                replyReactions = [Reaction(reactionEmoji: "👍", userIds: [reactor.id], reactionCount: 1)]
            } else {
                replyReactions = []
            }

            let reply = ThreadReply(
                id: "\(parentMessageId)_r\(replyIdx + 1)",
                parentMessageId: parentMessageId,
                senderId: responder.id,
                messageText: threadReplyTemplate(channelName: channelName, replyIndex: replyIdx),
                timestamp: timestamp.addingTimeInterval(TimeInterval((replyIdx + 1) * 900)),
                editedAt: replyIdx == 1 && messageIndex.isMultiple(of: 4) ? timestamp.addingTimeInterval(TimeInterval((replyIdx + 1) * 900 + 300)) : nil,
                reactions: replyReactions,
                attachments: []
            )
            replies.append(reply)
        }

        return replies
    }

    private static func seededDMThreadReplies(
        parentMessageId: String,
        dmName: String,
        messageIndex: Int,
        participants: [WorkspaceMember],
        timestamp: Date
    ) -> [ThreadReply] {
        // More DMs get threads: indices 1, 4, 7, 10
        let threadedIndices = [1, 4, 7, 10]
        guard threadedIndices.contains(messageIndex), participants.count >= 2 else {
            return []
        }

        let replyCount: Int
        switch messageIndex {
        case 1:
            replyCount = 4
        case 4, 7:
            replyCount = 3
        case 10:
            replyCount = 3
        default:
            replyCount = 2
        }

        let dmReplyTemplates: [String]
        switch dmName {
        case "Blair Morgan":
            dmReplyTemplates = [
                "Good point. Let me adjust the plan and circle back.",
                "I checked with the team. We're aligned on that approach.",
                "Updated the doc with the changes we discussed.",
                "Makes sense. I'll send the revised version by end of day.",
                "Agreed. Let's lock this in and move forward."
            ]
        case "Launch Core":
            dmReplyTemplates = [
                "Keeping the decision in thread so the follow-up stays searchable.",
                "All confirmed on my end. Ready to proceed.",
                "I'll own the follow-up action and report back tomorrow.",
                "Checked the timeline. We have enough buffer for this change.",
                "Good catch. Updated the shared doc with the correction."
            ]
        case "Devon Hart":
            dmReplyTemplates = [
                "The product side is covered. Engineering can proceed.",
                "I'll add this to the next sprint planning agenda.",
                "Good feedback. Incorporating it into the PRD now.",
                "Let's revisit the priority after the launch settles.",
                "Sounds right. I'll update the roadmap accordingly."
            ]
        case "Imani Brooks":
            dmReplyTemplates = [
                "Just ran the tests. All passing after the fix.",
                "The build looks clean. I'll approve the PR.",
                "Found one more edge case. Let me add a test for it.",
                "Performance numbers are in. Looks like a solid improvement.",
                "I'll pair with you on it tomorrow morning."
            ]
        default:
            dmReplyTemplates = [
                "Sounds good. I'll take care of it.",
                "Thanks for the update. Noted.",
                "Let me check on that and get back to you.",
                "All clear on my end. Moving forward.",
                "Agreed. Let's sync again after the next review."
            ]
        }

        var replies: [ThreadReply] = []
        for replyIdx in 0..<replyCount {
            let responder = participants[(messageIndex + replyIdx + 1) % participants.count]
            let replyReactions: [Reaction] = replyIdx == 0 ? [Reaction(reactionEmoji: "👍", userIds: [currentUserId], reactionCount: 1)] : []

            let reply = ThreadReply(
                id: "\(parentMessageId)_r\(replyIdx + 1)",
                parentMessageId: parentMessageId,
                senderId: responder.id,
                messageText: dmReplyTemplates[replyIdx % dmReplyTemplates.count],
                timestamp: timestamp.addingTimeInterval(TimeInterval((replyIdx + 1) * 1_200)),
                editedAt: nil,
                reactions: replyReactions,
                attachments: []
            )
            replies.append(reply)
        }

        return replies
    }

    private static func threadReplyTemplate(channelName: String, replyIndex: Int) -> String {
        let followUps: [String]
        switch channelName {
        case "eng-mobile":
            followUps = [
                "Threading the concrete owner and device coverage here.",
                "I can post the final testing notes after the next build finishes.",
                "Confirmed on my device. The fix looks good.",
                "Adding the benchmark numbers for comparison. Before: 280ms, after: 190ms.",
                "I'll update the release notes with this change.",
                "Good idea. Let me also check the Android equivalent."
            ]
        case "launch-war-room", "incident-bridge":
            followUps = [
                "Adding the owner, ETA, and fallback plan in this thread.",
                "Acknowledged. I'll post a short incident-style summary once it's verified.",
                "Metrics are stable. Continuing to monitor.",
                "The rollback script is tested and ready if needed.",
                "Customer comms are drafted. Will send on your go.",
                "All clear from the SRE side. Systems nominal."
            ]
        case "support-ops":
            followUps = [
                "Support impact is low for now, but I'll keep the customer-facing note ready.",
                "I'll update the escalation tracker after we confirm rollout timing.",
                "Customer confirmed the workaround is acceptable.",
                "The macro has been updated. Agents can use it starting now.",
                "Ticket volume is within normal range. No spike from this issue.",
                "Added the FAQ entry for this scenario."
            ]
        case "design":
            followUps = [
                "Threading this so the channel stays readable for everyone else.",
                "The updated mockup addresses the spacing issue. Take another look.",
                "Accessibility check passed on the revised version.",
                "I exported the assets at all density buckets.",
                "The animation timing feels better at 250ms. What do you think?",
                "Motion spec is updated in the design system doc."
            ]
        case "product":
            followUps = [
                "Threading this so the channel stays readable for everyone else.",
                "I updated the PRD with the clarification.",
                "The data supports the hypothesis. Let's move forward.",
                "Added the edge case to the acceptance criteria.",
                "Good question. Let me check with engineering and report back.",
                "The experiment results are conclusive. Recommending variant B."
            ]
        case "random":
            followUps = [
                "Count me in!",
                "This is the content I subscribe to this channel for.",
                "Seconded. Great idea.",
                "Adding my vote for Thai.",
                "That's amazing. Sharing with my team.",
                "Haha, needed this today. Thanks for posting."
            ]
        default:
            followUps = [
                "Threading this so the channel stays readable for everyone else.",
                "I'll circle back with a short summary once the next step is complete.",
                "Confirmed. This matches what I was seeing on my end.",
                "Good call. Let me update the tracking doc.",
                "I'll take the action item and follow up by end of day.",
                "Thanks for the context. That clarifies things."
            ]
        }
        return followUps[replyIndex % followUps.count]
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}
