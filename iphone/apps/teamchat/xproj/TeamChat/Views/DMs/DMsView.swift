import SwiftUI

private enum DMListFilter: String, CaseIterable {
    case all
    case unread
    case groups
    case muted

    var label: String {
        switch self {
        case .all:
            return "All"
        case .unread:
            return "Unread"
        case .groups:
            return "Groups"
        case .muted:
            return "Muted"
        }
    }
}

struct DMsView: View {
    @StateObject private var viewModel: DMsViewModel
    @State private var showNewDMSheet = false
    @State private var navigationPath: [String] = []
    @State private var selectedFilter: DMListFilter = .all
    @State private var showProfileSheet = false

    init(store: WorkspaceStore) {
        _viewModel = StateObject(wrappedValue: DMsViewModel(store: store))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                TeamChatPalette.screen
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    participantStrip

                    List {
                        if filteredDMs.isEmpty {
                            Text("No direct messages yet")
                                .foregroundStyle(TeamChatPalette.subtleText)
                                .listRowBackground(TeamChatPalette.screen)
                                .accessibilityIdentifier("no_dms_state")
                        } else {
                            ForEach(filteredDMs) { dm in
                                NavigationLink {
                                    DMDetailView(store: viewModel.store, dmId: dm.id)
                                } label: {
                                    DMRowView(dm: dm, store: viewModel.store)
                                }
                                .listRowBackground(TeamChatPalette.screen)
                                .listRowSeparatorTint(TeamChatPalette.divider)
                                .accessibilityIdentifier("dm_row_\(dm.name.accessibilitySlug)")
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(dm.isMuted ? "Unmute" : "Mute") {
                                        viewModel.toggleMute(dm.id)
                                    }
                                    .tint(.orange)
                                    .accessibilityIdentifier("dm_mute_action_\(dm.name.accessibilitySlug)")
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button(dm.unreadCount > 0 ? "Mark Read" : "Mark Unread") {
                                        if dm.unreadCount > 0 {
                                            viewModel.markRead(dm.id)
                                        } else {
                                            viewModel.markUnread(dm.id)
                                        }
                                    }
                                    .tint(.blue)
                                    .accessibilityIdentifier("dm_read_action_\(dm.name.accessibilitySlug)")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Button {
                    showNewDMSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: TeamChatMetrics.floatingButtonSize, height: TeamChatMetrics.floatingButtonSize)
                        .background(Circle().fill(TeamChatPalette.avatarRing))
                }
                .padding(.trailing, TeamChatMetrics.floatingButtonTrailingPadding)
                .padding(.bottom, TeamChatMetrics.floatingButtonBottomPadding)
                .accessibilityIdentifier("new_dm_button")
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { dmId in
                DMDetailView(store: viewModel.store, dmId: dmId)
            }
        }
        .sheet(isPresented: $showNewDMSheet) {
            NewDMSheetView(viewModel: viewModel) { dmId in
                navigationPath.append(dmId)
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(store: viewModel.store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            presentComposerIfRequested()
        }
        .onChange(of: viewModel.store.pendingUIAction) {
            presentComposerIfRequested()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("DMs")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("dms_title_label")

            Spacer()

            Menu {
                ForEach(DMListFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        if selectedFilter == filter {
                            Label(filter.label, systemImage: "checkmark")
                        } else {
                            Text(filter.label)
                        }
                    }
                    .accessibilityIdentifier("dm_filter_\(filter.rawValue)")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
            }
            .accessibilityIdentifier("dm_filter_sort_button")

            Button {
                showProfileSheet = true
            } label: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(TeamChatPalette.surface)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.85))
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dm_profile_avatar")
        }
        .padding(.horizontal, TeamChatMetrics.headerHorizontalPadding)
        .padding(.top, TeamChatMetrics.headerTopPadding)
        .padding(.bottom, TeamChatMetrics.headerBottomPadding)
        .background(TeamChatPalette.header)
    }

    private var participantStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(viewModel.members) { member in
                    Button {
                        if let dmId = viewModel.createDM(memberIds: [member.id]) {
                            navigationPath.append(dmId)
                        }
                    } label: {
                        VStack(spacing: 5) {
                            ZStack(alignment: .bottomTrailing) {
                                TeamChatUserAvatar(displayName: member.displayName, fallbackInitials: initials(for: member.displayName), size: 60)

                                Circle()
                                    .fill(member.presenceState.color)
                                    .frame(width: 13, height: 13)
                                    .overlay(Circle().stroke(TeamChatPalette.screen, lineWidth: 2))
                                    .offset(x: 2, y: 2)
                            }
                            .accessibilityIdentifier("dm_member_avatar_\(member.username)")

                            Text(member.displayName.components(separatedBy: " ").first ?? member.displayName)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(maxWidth: 60)
                                .lineLimit(1)
                                .accessibilityIdentifier("dm_member_name_\(member.username)")
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("dm_member_quick_open_\(member.username)")
                }
            }
            .padding(.horizontal, TeamChatMetrics.pagePadding)
            .padding(.vertical, 10)
        }
        .background(TeamChatPalette.screen)
        .accessibilityIdentifier("dm_member_strip")
    }

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var filteredDMs: [DMConversation] {
        switch selectedFilter {
        case .all:
            return viewModel.dms
        case .unread:
            return viewModel.dms.filter { $0.unreadCount > 0 }
        case .groups:
            return viewModel.dms.filter(\.isGroup)
        case .muted:
            return viewModel.dms.filter(\.isMuted)
        }
    }

    private func presentComposerIfRequested() {
        guard viewModel.store.pendingUIAction == .presentNewDMComposer else {
            return
        }
        showNewDMSheet = true
        viewModel.store.consumePendingUIAction(.presentNewDMComposer)
    }
}

private struct DMRowView: View {
    let dm: DMConversation
    @ObservedObject var store: WorkspaceStore

    private var hasUnread: Bool { dm.unreadCount > 0 }

    private var lastMessageIsFromCurrentUser: Bool {
        guard let lastMessage = dm.messages.last,
              let workspace = store.activeWorkspace else {
            return false
        }
        return lastMessage.senderId == workspace.currentUserId
    }

    private var previewText: String {
        if lastMessageIsFromCurrentUser {
            return "You: \(dm.lastMessagePreview)"
        }
        return dm.lastMessagePreview
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if dm.isGroup {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(TeamChatPalette.surface)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Text(initials)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                } else {
                    TeamChatUserAvatar(displayName: dm.name, fallbackInitials: initials, size: 44, cornerRadius: 12)

                    Circle()
                        .fill(presenceColor)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(TeamChatPalette.screen, lineWidth: 2))
                        .offset(x: 2, y: 2)
                        .accessibilityIdentifier("dm_presence_indicator_\(dm.name.accessibilitySlug)")
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(dm.name)
                        .font(.system(size: 16, weight: hasUnread ? .bold : .regular))
                        .foregroundStyle(hasUnread ? .white : .white.opacity(0.85))
                        .lineLimit(1)
                        .accessibilityIdentifier("dm_name_\(dm.name.accessibilitySlug)")

                    Spacer()

                    Text(DateFormatters.relative.localizedString(for: dm.lastMessageAt, relativeTo: Date()))
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("dm_timestamp_\(dm.name.accessibilitySlug)")
                }

                Text(previewText)
                    .font(.subheadline)
                    .foregroundStyle(hasUnread ? TeamChatPalette.secondaryText : TeamChatPalette.subtleText)
                    .lineLimit(1)
                    .accessibilityIdentifier("dm_preview_\(dm.name.accessibilitySlug)")
            }
        }
        .padding(.vertical, 4)
    }

    private var initials: String {
        let words = dm.name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(dm.name.prefix(2)).uppercased()
    }

    private var presenceColor: Color {
        let nonCurrentParticipants = dm.participantIds.filter { $0 != store.activeWorkspace?.currentUserId }
        let member = nonCurrentParticipants.compactMap { store.member(with: $0) }.first
        return member?.presenceState.color ?? .gray
    }
}
