import SwiftUI

private enum HomeDestination: Hashable {
    case channel(String)
    case dm(String)
}

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    @State private var showWorkspaceSheet = false
    @State private var showProfileSheet = false
    @State private var path: [HomeDestination] = []
    @State private var channelsExpanded = true
    @State private var dmsExpanded = true

    init(store: WorkspaceStore) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                TeamChatPalette.screen
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(spacing: 0) {
                            quickAccessCards
                                .padding(.top, 12)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                channelsSection
                                dmsSection
                            }
                            .padding(.horizontal, TeamChatMetrics.pagePadding)
                            .padding(.bottom, 80)
                        }
                    }
                    .background(TeamChatPalette.screen)
                }

                Button {
                    viewModel.store.openNewDMComposer()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: TeamChatMetrics.floatingButtonSize, height: TeamChatMetrics.floatingButtonSize)
                        .background(Circle().fill(TeamChatPalette.accent))
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                }
                .padding(.trailing, TeamChatMetrics.floatingButtonTrailingPadding)
                .padding(.bottom, TeamChatMetrics.floatingButtonBottomPadding)
                .accessibilityIdentifier("home_new_message_fab")
            }
            .navigationBarHidden(true)
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .channel(let channelId):
                    ChannelDetailView(store: viewModel.store, channelId: channelId)
                case .dm(let dmId):
                    DMDetailView(store: viewModel.store, dmId: dmId)
                }
            }
        }
        .sheet(isPresented: $showWorkspaceSheet) {
            WorkspacePickerSheet(store: viewModel.store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(store: viewModel.store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                showWorkspaceSheet = true
            } label: {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(TeamChatPalette.avatarRing)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text(String(viewModel.workspaceName.prefix(1)).uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }

                    Text(viewModel.workspaceName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .accessibilityIdentifier("home_workspace_name")
                }
            }
            .accessibilityIdentifier("workspace_switcher_button")

            Spacer()

            Button {
                viewModel.goToChannels()
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
            }
            .accessibilityIdentifier("home_filter_channels_button")

            Button {
                showProfileSheet = true
            } label: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(TeamChatPalette.surface)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Text(String((viewModel.currentUser?.displayName ?? "Y").prefix(1)).uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(viewModel.currentUser?.presenceState.color ?? .gray)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(TeamChatPalette.header, lineWidth: 2))
                            .offset(x: 3, y: 3)
                    }
            }
            .accessibilityIdentifier("home_profile_button")
        }
        .padding(.horizontal, 16)
        .padding(.top, TeamChatMetrics.headerTopPadding)
        .padding(.bottom, 14)
        .background(TeamChatPalette.header)
    }

    private var quickAccessCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickAccessCard(
                    icon: "tray.full.fill",
                    title: "Catch up",
                    subtitle: "\(viewModel.catchUpCount) unread",
                    id: "home_catch_up_card"
                ) {
                    viewModel.store.selectedTab = .activity
                }
                quickAccessCard(
                    icon: "bubble.left.and.text.bubble.right",
                    title: "Threads",
                    subtitle: "\(viewModel.threadCount) new",
                    id: "home_threads_card"
                ) {
                    viewModel.store.switchTab(.activity)
                }
                quickAccessCard(
                    icon: "headphones",
                    title: "Huddles",
                    subtitle: "0 live",
                    id: "home_huddles_card"
                ) {
                    viewModel.store.showPlaceholderAlert(
                        id: "huddles_placeholder",
                        title: "Huddles",
                        message: "No active huddles in this workspace."
                    )
                }
                quickAccessCard(
                    icon: "bookmark",
                    title: "Later",
                    subtitle: "\(viewModel.savedCount) items",
                    id: "home_later_card"
                ) {
                    viewModel.store.switchTab(.activity)
                }
                quickAccessCard(
                    icon: "square.and.pencil",
                    title: "Drafts",
                    subtitle: "\(viewModel.draftsCount) items",
                    id: "home_drafts_card"
                ) {
                    viewModel.store.switchTab(.more)
                }
            }
            .padding(.horizontal, TeamChatMetrics.pagePadding)
        }
    }

    private func quickAccessCard(icon: String, title: String, subtitle: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TeamChatPalette.subtleText)
            }
            .frame(width: 110, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(TeamChatPalette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(TeamChatPalette.divider, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var channelsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsibleSectionHeader(
                title: "Channels",
                isExpanded: $channelsExpanded,
                id: "home_channels_title"
            )

            if channelsExpanded {
                let channels = (viewModel.store.activeWorkspace?.channels ?? [])
                    .sorted(by: { lhs, rhs in
                        if lhs.unreadCount == rhs.unreadCount {
                            return lhs.lastMessageAt > rhs.lastMessageAt
                        }
                        return lhs.unreadCount > rhs.unreadCount
                    })

                if channels.isEmpty {
                    Text("No channels in workspace")
                        .font(.subheadline)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .padding(.vertical, 12)
                        .accessibilityIdentifier("no_channels_in_workspace_state")
                } else {
                    VStack(spacing: 0) {
                        ForEach(channels) { channel in
                            Button {
                                path.append(HomeDestination.channel(channel.id))
                            } label: {
                                channelRow(channel)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("channel_row_\(channel.channelName.accessibilitySlug)")
                        }
                    }
                }
            }
        }
    }

    private func channelRow(_ channel: Channel) -> some View {
        let hasUnread = channel.unreadCount > 0

        return HStack(spacing: 12) {
            Image(systemName: channel.isPrivate ? "lock.fill" : "number")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(hasUnread ? .white : TeamChatPalette.subtleText)
                .frame(width: 20)

            Text(channel.displayName)
                .font(.system(size: 16, weight: hasUnread ? .semibold : .regular))
                .foregroundStyle(hasUnread ? .white : TeamChatPalette.subtleText)
                .lineLimit(1)
                .accessibilityIdentifier("channel_name_\(channel.channelName.accessibilitySlug)")

            if channel.isMuted {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .accessibilityIdentifier("channel_muted_indicator_\(channel.channelName.accessibilitySlug)")
            }

            Spacer()

            if channel.mentionCount > 0 {
                Text("\(channel.mentionCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color.red, in: Circle())
                    .accessibilityIdentifier("mention_chip_channel_\(channel.channelName.accessibilitySlug)")
            } else if hasUnread {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                    .accessibilityIdentifier("unread_badge_channel_\(channel.channelName.accessibilitySlug)")
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 4)
    }

    private var dmsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsibleSectionHeader(
                title: "Direct Messages",
                isExpanded: $dmsExpanded,
                id: "home_recent_dms_title"
            )

            if dmsExpanded {
                let dms = viewModel.recentDMs
                if dms.isEmpty {
                    Text("No direct messages")
                        .font(.subheadline)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .padding(.vertical, 12)
                        .accessibilityIdentifier("home_no_recent_dms")
                } else {
                    VStack(spacing: 0) {
                        ForEach(dms) { dm in
                            Button {
                                path.append(HomeDestination.dm(dm.id))
                            } label: {
                                dmRow(dm)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("home_recent_dm_\(dm.name.accessibilitySlug)")
                        }
                    }
                }
            }
        }
    }

    private func dmRow(_ dm: DMConversation) -> some View {
        let hasUnread = dm.unreadCount > 0

        return HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if dm.isGroup {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(TeamChatPalette.surface)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text(dmInitials(dm.name))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                } else {
                    TeamChatUserAvatar(displayName: dm.name, fallbackInitials: dmInitials(dm.name), size: 28, cornerRadius: 8)

                    Circle()
                        .fill(dmPresenceColor(for: dm))
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(TeamChatPalette.screen, lineWidth: 1.5))
                        .offset(x: 2, y: 2)
                }
            }

            Text(dm.name)
                .font(.system(size: 16, weight: hasUnread ? .semibold : .regular))
                .foregroundStyle(hasUnread ? .white : TeamChatPalette.subtleText)
                .lineLimit(1)
                .accessibilityIdentifier("home_recent_dm_name_\(dm.name.accessibilitySlug)")

            if dm.isGroup {
                Text("\(dm.participantIds.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(TeamChatPalette.subtleText)
            }

            Spacer()

            if hasUnread {
                Text("\(dm.unreadCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color.red, in: Circle())
                    .accessibilityIdentifier("unread_badge_dm_\(dm.name.accessibilitySlug)")
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 4)
    }

    private func dmInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func dmPresenceColor(for dm: DMConversation) -> Color {
        let nonCurrentParticipants = dm.participantIds.filter { $0 != viewModel.store.activeWorkspace?.currentUserId }
        let member = nonCurrentParticipants.compactMap { viewModel.store.member(with: $0) }.first
        return member?.presenceState.color ?? .gray
    }

    private func collapsibleSectionHeader(title: String, isExpanded: Binding<Bool>, id: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier(id)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

}

private struct WorkspacePickerSheet: View {
    @ObservedObject var store: WorkspaceStore

    @Environment(\.dismiss) private var dismiss
    @State private var showAddWorkspaceSheet = false
    @State private var showHelpSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                TeamChatPalette.screen.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("Workspaces")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("workspace_picker_title")
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        .accessibilityIdentifier("workspace_picker_close_button")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(store.availableWorkspaces) { workspace in
                                Button {
                                    store.switchWorkspace(to: workspace.id)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(workspace.id == store.activeWorkspaceId ? TeamChatPalette.presenceActive : TeamChatPalette.surface)
                                            .frame(width: 48, height: 48)
                                            .overlay {
                                                Text(String(workspace.workspaceName.prefix(2)).uppercased())
                                                    .font(.headline.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(workspace.workspaceName)
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                                .accessibilityIdentifier("workspace_name_\(workspace.workspaceName.accessibilitySlug)")
                                            Text("\(workspace.workspaceName.accessibilitySlug).slack.com")
                                                .font(.subheadline)
                                                .foregroundStyle(TeamChatPalette.subtleText)
                                        }

                                        Spacer()

                                        if workspace.id == store.activeWorkspaceId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(TeamChatPalette.accent)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("workspace_switch_row_\(workspace.workspaceName.accessibilitySlug)")

                                Divider().overlay(TeamChatPalette.divider)
                            }
                        }
                        .padding(.top, 4)
                    }

                    VStack(spacing: 0) {
                        Divider().overlay(TeamChatPalette.divider)

                        workspaceActionRow(icon: "plus", title: "Add a Workspace", id: "workspace_add_button") {
                            showAddWorkspaceSheet = true
                        }
                        workspaceActionRow(icon: "gearshape", title: "Preferences", id: "workspace_preferences_button") {
                            store.switchTab(.more)
                            dismiss()
                        }
                        workspaceActionRow(icon: "questionmark.circle", title: "Help", id: "workspace_help_button") {
                            showHelpSheet = true
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showAddWorkspaceSheet) {
            AddWorkspaceSheetView(store: store)
        }
        .sheet(isPresented: $showHelpSheet) {
            WorkspaceHelpView()
        }
    }

    private func workspaceActionRow(icon: String, title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(TeamChatPalette.subtleText)
                Text(title)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

struct ProfileSheetView: View {
    @ObservedObject var store: WorkspaceStore

    @Environment(\.dismiss) private var dismiss
    @State private var statusText: String = ""
    @State private var showInvitationsSheet = false
    @State private var showVIPSheet = false
    @State private var showMemberProfileSheet = false
    @State private var showNotificationsSheet = false
    @State private var showPreferencesSheet = false

    private var profile: UserProfile? {
        store.activeWorkspace?.userProfile
    }

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                            .overlay(Circle().strokeBorder(TeamChatPalette.divider, lineWidth: 1))
                    }
                    .accessibilityIdentifier("profile_sheet_close_button")

                    Spacer()

                    Text("You")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .accessibilityIdentifier("profile_sheet_title")

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(TeamChatPalette.surface)
                            .frame(width: 64, height: 64)
                            .overlay {
                                Text(String((profile?.displayName ?? "Y").prefix(1)).uppercased())
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(profile?.presenceState.color ?? .gray)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile?.displayName ?? "Profile")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("profile_name_label")
                            Text(profile?.presenceState.label ?? "Away")
                                .font(.subheadline)
                                .foregroundStyle(TeamChatPalette.subtleText)
                                .accessibilityIdentifier("profile_status_presence_label")
                        }

                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "face.smiling")
                            .foregroundStyle(TeamChatPalette.subtleText)
                        TextField("What's your status?", text: $statusText)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("profile_status_field")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(TeamChatPalette.row))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(TeamChatPalette.divider, lineWidth: 1))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                VStack(spacing: 0) {
                    profileAction(
                        icon: "bell.slash",
                        title: (profile?.notificationPreference.pushEnabled ?? true) ? "Pause notifications" : "Resume notifications",
                        id: "profile_pause_notifications_button"
                    )
                    profileAction(
                        icon: "person.badge.plus",
                        title: (profile?.presenceState ?? .away) == .active ? "Set yourself as away" : "Set yourself as active",
                        id: "profile_set_active_button"
                    )

                    Divider().overlay(TeamChatPalette.divider)
                        .padding(.vertical, 6)

                    profileAction(icon: "building.2", title: "Invitations to connect", id: "profile_invitations_button")
                    profileAction(icon: "person", title: "View profile", id: "profile_view_profile_button")
                    profileAction(icon: "rectangle.badge.checkmark", title: "VIP", id: "profile_vip_button")
                    profileAction(icon: "bell", title: "Notifications", id: "profile_notifications_button")
                    profileAction(icon: "gearshape", title: "Preferences", id: "profile_preferences_button")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()
            }
        }
        .onAppear {
            statusText = profile?.statusText ?? ""
        }
        .onDisappear {
            store.updateCurrentUserStatus(statusText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        .sheet(isPresented: $showInvitationsSheet) {
            MoreStaticCollectionView(
                title: "Invitations to connect",
                subtitle: "External requests waiting for your review",
                rows: [
                    .init(title: "Acme Product Ops", subtitle: "Shared support channel invite"),
                    .init(title: "BrowserGym Partners", subtitle: "External collaboration request"),
                    .init(title: "Meridian Agents Lab", subtitle: "Workspace invite pending")
                ]
            )
        }
        .sheet(isPresented: $showVIPSheet) {
            MoreStaticCollectionView(
                title: "VIP",
                subtitle: "Priority controls for critical work",
                rows: [
                    .init(title: "Escalation routing", subtitle: "Priority notifications for launch and incident channels"),
                    .init(title: "Priority mentions", subtitle: "Surface high-signal alerts first"),
                    .init(title: "Exec visibility", subtitle: "Share updates to leadership-only channels")
                ]
            )
        }
        .sheet(isPresented: $showMemberProfileSheet) {
            if let profile {
                NavigationStack {
                    MemberDetailView(store: store, memberId: profile.id)
                }
            }
        }
        .sheet(isPresented: $showNotificationsSheet) {
            ProfileNotificationsSheetView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPreferencesSheet) {
            ProfilePreferencesSheetView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func profileAction(icon: String, title: String, id: String) -> some View {
        Button {
            switch id {
            case "profile_pause_notifications_button":
                let isPushEnabled = profile?.notificationPreference.pushEnabled ?? true
                store.updateNotificationPreference(pushEnabled: !isPushEnabled)
            case "profile_set_active_button":
                let nextPresence: PresenceState = (profile?.presenceState ?? .away) == .active ? .away : .active
                store.updateCurrentUserPresence(nextPresence)
            case "profile_invitations_button":
                showInvitationsSheet = true
            case "profile_view_profile_button":
                showMemberProfileSheet = true
            case "profile_vip_button":
                showVIPSheet = true
            case "profile_notifications_button":
                showNotificationsSheet = true
            case "profile_preferences_button":
                showPreferencesSheet = true
            default:
                store.showPlaceholderAlert(
                    id: "\(id)_placeholder",
                    title: title,
                    message: "This workflow is only available in online mode."
                )
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.93))
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

private struct ProfileNotificationsSheetView: View {
    @ObservedObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss

    private var profile: UserProfile? {
        store.activeWorkspace?.userProfile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TeamChatPalette.screen.ignoresSafeArea()

                List {
                    Section("Push Notifications") {
                        Toggle(
                            "Enable push notifications",
                            isOn: Binding(
                                get: { profile?.notificationPreference.pushEnabled ?? false },
                                set: { store.updateNotificationPreference(pushEnabled: $0) }
                            )
                        )
                        .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("profile_notifications_push_toggle")

                        Toggle(
                            "Mentions only",
                            isOn: Binding(
                                get: { profile?.notificationPreference.mentionOnly ?? false },
                                set: { store.updateNotificationPreference(mentionOnly: $0) }
                            )
                        )
                        .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("profile_notifications_mentions_toggle")
                    }

                    Section("Activity") {
                        Toggle(
                            "Thread reply notifications",
                            isOn: Binding(
                                get: { profile?.notificationPreference.threadRepliesEnabled ?? false },
                                set: { store.updateNotificationPreference(threadRepliesEnabled: $0) }
                            )
                        )
                        .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("profile_notifications_threads_toggle")

                        Toggle(
                            "Huddle invite notifications",
                            isOn: Binding(
                                get: { profile?.notificationPreference.huddleInvitesEnabled ?? false },
                                set: { store.updateNotificationPreference(huddleInvitesEnabled: $0) }
                            )
                        )
                        .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("profile_notifications_huddles_toggle")
                    }

                    Section {
                        Text("Changes take effect immediately. Notifications are managed per-workspace.")
                            .font(.footnote)
                            .foregroundStyle(TeamChatPalette.subtleText)
                            .accessibilityIdentifier("profile_notifications_footer_note")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TeamChatPalette.accent)
                        .accessibilityIdentifier("profile_notifications_done_button")
                }
            }
        }
    }
}

private struct ProfilePreferencesSheetView: View {
    @ObservedObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss

    private var profile: UserProfile? {
        store.activeWorkspace?.userProfile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TeamChatPalette.screen.ignoresSafeArea()

                List {
                    Section("Presence") {
                        HStack {
                            Text("Current status")
                                .foregroundStyle(.white)
                            Spacer()
                            Circle()
                                .fill(profile?.presenceState.color ?? .gray)
                                .frame(width: 10, height: 10)
                            Text(profile?.presenceState.label ?? "Unknown")
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        .accessibilityIdentifier("profile_prefs_presence_row")

                        Button {
                            let nextPresence: PresenceState = (profile?.presenceState ?? .away) == .active ? .away : .active
                            store.updateCurrentUserPresence(nextPresence)
                        } label: {
                            Text((profile?.presenceState ?? .away) == .active ? "Set yourself as away" : "Set yourself as active")
                                .foregroundStyle(TeamChatPalette.accent)
                        }
                        .accessibilityIdentifier("profile_prefs_toggle_presence_button")
                    }

                    Section("Workspace") {
                        if let workspaceName = store.activeWorkspace?.workspaceName {
                            HStack {
                                Text("Active workspace")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(workspaceName)
                                    .foregroundStyle(TeamChatPalette.subtleText)
                            }
                            .accessibilityIdentifier("profile_prefs_workspace_row")
                        }

                        HStack {
                            Text("Role")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(profile?.role ?? "Member")
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        .accessibilityIdentifier("profile_prefs_role_row")
                    }

                    Section("Account") {
                        HStack {
                            Text("Username")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("@\(profile?.username ?? "")")
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        .accessibilityIdentifier("profile_prefs_username_row")

                        HStack {
                            Text("Title")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(profile?.title ?? "")
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        .accessibilityIdentifier("profile_prefs_title_row")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TeamChatPalette.accent)
                        .accessibilityIdentifier("profile_preferences_done_button")
                }
            }
        }
    }
}

private struct AddWorkspaceSheetView: View {
    @ObservedObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var workspaceName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                TeamChatPalette.screen.ignoresSafeArea()

                Form {
                    Section("Workspace") {
                        TextField("Workspace name", text: $workspaceName)
                            .accessibilityIdentifier("add_workspace_name_field")
                    }

                    Section("What gets created") {
                        Text("A local offline workspace is added using the current workspace as a template so you can switch immediately.")
                            .foregroundStyle(TeamChatPalette.subtleText)
                            .accessibilityIdentifier("add_workspace_description")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("add_workspace_cancel_button")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        if store.addWorkspace(named: workspaceName) {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("add_workspace_confirm_button")
                }
            }
            .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

private struct WorkspaceHelpView: View {
    var body: some View {
        MoreStaticCollectionView(
            title: "Help",
            subtitle: "Tips and guidance for your workspace",
            rows: [
                .init(title: "Browse channels", subtitle: "Use Home or Search to move through public and private channels"),
                .init(title: "Start a DM", subtitle: "Open DMs and use the compose button or member strip"),
                .init(title: "Manage data", subtitle: "Open More > Preferences to switch data sources")
            ]
        )
    }
}

private extension TeamChatPalette {
    static let presenceActive = Color(red: 0.24, green: 0.58, blue: 0.36)
}
