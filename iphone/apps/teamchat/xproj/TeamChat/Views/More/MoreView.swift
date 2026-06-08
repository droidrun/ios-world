import SwiftUI

private enum MoreDestination: Hashable {
    case canvases
    case lists
    case assigned
    case externalConnections
    case savedItems
    case drafts
    case huddles
}

struct MoreView: View {
    @StateObject private var viewModel: MoreViewModel
    @State private var navigationPath: [MoreDestination] = []
    @State private var showCreateActions = false
    @State private var showProfileSheet = false

    init(store: WorkspaceStore) {
        _viewModel = StateObject(wrappedValue: MoreViewModel(store: store))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                TeamChatPalette.screen.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(spacing: TeamChatMetrics.sectionSpacing) {
                            topUtilityRows
                            profileCard
                            workspaceCard
                            preferencesCard
                            toolsCard
                            maintenanceCard
                        }
                        .padding(.horizontal, TeamChatMetrics.pagePadding)
                        .padding(.top, TeamChatMetrics.pagePadding)
                        .padding(.bottom, TeamChatMetrics.pageBottomPadding)
                    }
                }

                Button {
                    showCreateActions = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TeamChatPalette.accent)
                        .frame(width: TeamChatMetrics.floatingButtonSize, height: TeamChatMetrics.floatingButtonSize)
                        .background(Circle().fill(TeamChatPalette.avatarRing))
                        .overlay(Circle().strokeBorder(TeamChatPalette.divider, lineWidth: 1))
                }
                .padding(.trailing, TeamChatMetrics.floatingButtonTrailingPadding)
                .padding(.bottom, TeamChatMetrics.floatingButtonBottomPadding)
                .accessibilityIdentifier("more_create_button")
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MoreDestination.self) { destination in
                switch destination {
                case .canvases:
                    MoreStaticCollectionView(
                        title: "Canvases",
                        subtitle: "Curate content and collaborate",
                        rows: [
                            .init(title: "Launch notes canvas", subtitle: "Edited by Alex Kim in #launch-war-room"),
                            .init(title: "Support escalation brief", subtitle: "Edited by Jordan Lee in #support-ops"),
                            .init(title: "Design handoff canvas", subtitle: "Edited by Samira Patel in #design")
                        ]
                    )
                case .lists:
                    MoreStaticCollectionView(
                        title: "Lists",
                        subtitle: "Track and manage projects",
                        rows: [
                            .init(title: "Launch blockers", subtitle: "7 open items, 3 due today"),
                            .init(title: "App store follow-ups", subtitle: "5 open items, owned by Product"),
                            .init(title: "Support quality audits", subtitle: "4 open items, reviewed weekly")
                        ]
                    )
                case .assigned:
                    MoreActivityListView(
                        title: "Assigned to you",
                        items: viewModel.store.assignedItems(),
                        store: viewModel.store,
                        emptyMessage: "No assigned items"
                    )
                case .externalConnections:
                    MoreStaticCollectionView(
                        title: "External Connections",
                        subtitle: "Work with people from other organizations",
                        rows: [
                            .init(title: "browsergym-colab", subtitle: "Shared channel with 14 external participants"),
                            .init(title: "community-agents-lab", subtitle: "Community workspace bridge"),
                            .init(title: "visual-web-arena", subtitle: "Partner channel for performance ops")
                        ]
                    )
                case .savedItems:
                    MoreActivityListView(
                        title: "Saved items",
                        items: viewModel.store.savedItems(),
                        store: viewModel.store,
                        emptyMessage: "No saved items"
                    )
                case .drafts:
                    MoreDraftsView(store: viewModel.store, draftsCount: viewModel.draftsCount)
                case .huddles:
                    HuddlePlaceholderView(
                        title: "Huddles",
                        contextName: viewModel.store.activeWorkspace?.workspaceName ?? "Workspace",
                        participantNames: viewModel.store.activeWorkspace?.members.prefix(4).map(\.displayName) ?? [],
                        accessibilityPrefix: "more_huddle_placeholder"
                    )
                }
            }
        }
        .confirmationDialog("Create", isPresented: $showCreateActions, titleVisibility: .visible) {
            Button("New message") {
                viewModel.store.openNewDMComposer()
            }
            Button("Browse channels") {
                viewModel.store.switchTab(.channels)
            }
            Button("Search") {
                viewModel.store.switchTab(.search)
            }
            Button("Start a huddle") {
                navigationPath.append(.huddles)
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(store: viewModel.store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text("More")
                .font(.system(size: TeamChatMetrics.headerTitleSize, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("more_header_title")

            Spacer()

            Button {
                showProfileSheet = true
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: TeamChatMetrics.headerProfileIconSize))
                    .foregroundStyle(.white.opacity(0.96))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("more_profile_avatar")
        }
        .padding(.horizontal, TeamChatMetrics.headerHorizontalPadding)
        .padding(.top, TeamChatMetrics.headerTopPadding)
        .padding(.bottom, TeamChatMetrics.headerBottomPadding)
        .background(TeamChatPalette.header)
    }

    private var topUtilityRows: some View {
        VStack(spacing: 0) {
            utilityRow(
                destination: .canvases,
                icon: "square.on.square",
                title: "Canvases",
                subtitle: "Curate content and collaborate",
                id: "more_canvases_row"
            )
            utilityRow(
                destination: .lists,
                icon: "checklist",
                title: "Lists",
                subtitle: "Track and manage projects",
                id: "more_lists_row"
            )
            utilityRow(
                destination: .assigned,
                icon: "person.2",
                title: "Assigned to you",
                subtitle: "Check off your tasks",
                id: "more_assigned_row"
            )
            utilityRow(
                destination: .externalConnections,
                icon: "building.2",
                title: "External Connections",
                subtitle: "Work with people from other organizations",
                id: "more_external_connections_row"
            )
        }
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
    }

    private func utilityRow(destination: MoreDestination, icon: String, title: String, subtitle: String, id: String) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(TeamChatPalette.subtleText)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profile")
                .font(.headline)
                .foregroundStyle(.white)

            if let profile = viewModel.profile {
                NavigationLink {
                    MemberDetailView(store: viewModel.store, memberId: profile.id)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("profile_name_label")
                        Text("@\(profile.username) - \(profile.title)")
                            .font(.subheadline)
                            .foregroundStyle(TeamChatPalette.subtleText)
                            .accessibilityIdentifier("profile_username_label")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profile_summary_card")
            } else {
                Text("No profile")
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .accessibilityIdentifier("profile_missing_state")
            }
        }
        .padding(12)
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
    }

    private var workspaceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workspace switcher")
                .font(.headline)
                .foregroundStyle(.white)

            if viewModel.workspaces.isEmpty {
                Text("No workspaces available")
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .accessibilityIdentifier("workspace_switcher_empty_state")
            } else {
                ForEach(viewModel.workspaces) { workspace in
                    Button {
                        viewModel.switchWorkspace(workspace.id)
                    } label: {
                        HStack {
                            Text(workspace.workspaceName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("workspace_name_\(workspace.workspaceName.accessibilitySlug)")
                            Spacer()
                            if workspace.id == viewModel.store.activeWorkspaceId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(TeamChatPalette.accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("workspace_switch_row_\(workspace.workspaceName.accessibilitySlug)")
                }
            }
        }
        .padding(12)
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notifications / Preferences")
                .font(.headline)
                .foregroundStyle(.white)

            Toggle(
                "Push notifications",
                isOn: Binding(
                    get: { viewModel.profile?.notificationPreference.pushEnabled ?? false },
                    set: { viewModel.updatePushEnabled($0) }
                )
            )
            .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
            .foregroundStyle(.white)
            .accessibilityIdentifier("settings_toggle_push_notifications")

            Toggle(
                "Mentions only",
                isOn: Binding(
                    get: { viewModel.profile?.notificationPreference.mentionOnly ?? false },
                    set: { viewModel.updateMentionOnly($0) }
                )
            )
            .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
            .foregroundStyle(.white)
            .accessibilityIdentifier("settings_toggle_mentions_only")

            Toggle(
                "Thread replies",
                isOn: Binding(
                    get: { viewModel.profile?.notificationPreference.threadRepliesEnabled ?? false },
                    set: { viewModel.updateThreadReplies($0) }
                )
            )
            .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
            .foregroundStyle(.white)
            .accessibilityIdentifier("settings_toggle_thread_replies")

            Toggle(
                "Huddle invites",
                isOn: Binding(
                    get: { viewModel.profile?.notificationPreference.huddleInvitesEnabled ?? false },
                    set: { viewModel.updateHuddleInvites($0) }
                )
            )
            .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
            .foregroundStyle(.white)
            .accessibilityIdentifier("settings_toggle_huddle_invites")
        }
        .padding(12)
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
    }

    private var toolsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tools")
                .font(.headline)
                .foregroundStyle(.white)

            NavigationLink {
                ActivityCenterView(store: viewModel.store, initialFilter: .all)
            } label: {
                Text("Activity")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("more_activity_button")

            NavigationLink(value: MoreDestination.savedItems) {
                Text("Saved items")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
                .accessibilityIdentifier("saved_items_placeholder")

            NavigationLink(value: MoreDestination.drafts) {
                Text("Drafts: \(viewModel.draftsCount)")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
                .accessibilityIdentifier("drafts_placeholder")

            NavigationLink {
                DebugImportView(viewModel: viewModel)
            } label: {
                Text("Preferences")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("offline_debug_import_button")
        }
        .padding(12)
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
    }

    private var maintenanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Maintenance")
                .font(.headline)
                .foregroundStyle(.white)

            Button("Reset app state") {
                viewModel.resetAppState()
            }
            .foregroundStyle(.red)
            .accessibilityIdentifier("profile_reset_app_state")
        }
        .padding(12)
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
    }
}

struct MoreStaticRow: Hashable {
    let title: String
    let subtitle: String
}

struct MoreStaticCollectionView: View {
    let title: String
    let subtitle: String
    let rows: [MoreStaticRow]

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(TeamChatPalette.subtleText)
                    }

                    ForEach(rows, id: \.self) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(row.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(TeamChatPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .hidesRootChrome()
    }
}

struct MoreActivityListView: View {
    let title: String
    let items: [ActivityItem]
    @ObservedObject var store: WorkspaceStore
    let emptyMessage: String

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            if items.isEmpty {
                ContentUnavailableView(emptyMessage, systemImage: "tray")
                    .accessibilityIdentifier("\(title.accessibilitySlug)_empty_state")
            } else {
                List(items) { item in
                    if let target = store.navigationTarget(for: item) {
                        NavigationLink {
                            destinationView(for: target)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(item.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(TeamChatPalette.secondaryText)
                                    .lineLimit(2)
                                Text(item.channelOrDMName)
                                    .font(.caption)
                                    .foregroundStyle(TeamChatPalette.subtleText)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(TeamChatPalette.screen)
                        .listRowSeparatorTint(TeamChatPalette.divider)
                    } else {
                        Text(item.title)
                            .foregroundStyle(.white)
                            .listRowBackground(TeamChatPalette.screen)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .hidesRootChrome()
    }

    @ViewBuilder
    private func destinationView(for target: NavigationTarget) -> some View {
        switch target {
        case .channel(let channelId, let focusMessageId):
            ChannelDetailView(store: store, channelId: channelId, focusMessageId: focusMessageId)
        case .dm(let dmId, let focusMessageId):
            DMDetailView(store: store, dmId: dmId, focusMessageId: focusMessageId)
        case .member(let memberId):
            MemberDetailView(store: store, memberId: memberId)
        }
    }
}

struct MoreDraftsView: View {
    @ObservedObject var store: WorkspaceStore
    let draftsCount: Int

    private var draftRows: [MoreStaticRow] {
        let channels = store.recentChannels(limit: max(draftsCount, 1))
        if channels.isEmpty {
            return [MoreStaticRow(title: "No drafts", subtitle: "Compose in a channel or DM to start a draft")]
        }

        return Array(channels.prefix(max(draftsCount, 1)).enumerated()).map { index, channel in
            MoreStaticRow(
                title: "Draft in \(channel.displayName)",
                subtitle: index % 2 == 0
                    ? "Following up on \(channel.lastMessagePreview)"
                    : "Need to circle back on the latest thread before sending"
            )
        }
    }

    var body: some View {
        MoreStaticCollectionView(
            title: "Drafts",
            subtitle: "\(draftsCount) local draft(s)",
            rows: draftRows
        )
    }
}
