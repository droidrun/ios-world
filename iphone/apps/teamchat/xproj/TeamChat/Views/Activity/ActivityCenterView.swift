import SwiftUI

struct ActivityCenterView: View {
    @StateObject private var viewModel: ActivityViewModel
    let initialFilter: ActivityType

    @State private var didApplyInitialFilter = false
    @State private var showProfileSheet = false

    init(store: WorkspaceStore, initialFilter: ActivityType = .all) {
        _viewModel = StateObject(wrappedValue: ActivityViewModel(store: store))
        self.initialFilter = initialFilter
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TeamChatPalette.screen.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            filterButtons
                                .padding(.horizontal, TeamChatMetrics.pagePadding)
                                .padding(.top, TeamChatMetrics.pagePadding)
                                .padding(.bottom, 8)

                            if viewModel.items.isEmpty {
                                Text(emptyMessage)
                                    .foregroundStyle(TeamChatPalette.subtleText)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityIdentifier("activity_empty_state")
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.items) { item in
                                        if let target = viewModel.navigationTarget(for: item) {
                                            NavigationLink {
                                                destinationView(for: target)
                                            } label: {
                                                ActivityRow(item: item)
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            ActivityRow(item: item)
                                        }
                                        Divider().overlay(TeamChatPalette.divider)
                                            .padding(.leading, 52)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if didApplyInitialFilter == false {
                viewModel.selectedFilter = initialFilter
                didApplyInitialFilter = true
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(store: viewModel.store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text("Activity")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("activity_header_title")

            Spacer()

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
            .accessibilityIdentifier("activity_profile_button")
        }
        .padding(.horizontal, TeamChatMetrics.headerHorizontalPadding)
        .padding(.top, TeamChatMetrics.headerTopPadding)
        .padding(.bottom, TeamChatMetrics.headerBottomPadding)
        .background(TeamChatPalette.header)
    }

    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(.all, title: "All", icon: nil, id: "activity_all_filter")
                filterButton(.mentions, title: "Mentions", icon: "at", id: "activity_mentions_filter")
                filterButton(.threads, title: "Threads", icon: "bubble.left.and.bubble.right", id: "activity_threads_filter")
                filterButton(.reactions, title: "Reactions", icon: nil, id: "activity_reactions_filter")
                filterButton(.unreads, title: "Unreads", icon: nil, id: "activity_unreads_filter")
                filterButton(.saved, title: "Saved", icon: "bookmark", id: "activity_saved_filter")
            }
        }
    }

    private func filterButton(_ filter: ActivityType, title: String, icon: String?, id: String) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            viewModel.selectedFilter = filter
        } label: {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : TeamChatPalette.secondaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? TeamChatPalette.avatarRing : Color.clear)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : TeamChatPalette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    @ViewBuilder
    private func destinationView(for target: NavigationTarget) -> some View {
        switch target {
        case .channel(let channelId, let focusMessageId):
            ChannelDetailView(store: viewModel.store, channelId: channelId, focusMessageId: focusMessageId)
        case .dm(let dmId, let focusMessageId):
            DMDetailView(store: viewModel.store, dmId: dmId, focusMessageId: focusMessageId)
        case .member(let memberId):
            MemberDetailView(store: viewModel.store, memberId: memberId)
        }
    }

    private var emptyMessage: String {
        switch viewModel.selectedFilter {
        case .all:
            return "No activity"
        case .mentions:
            return "No mentions"
        case .threads:
            return "No thread updates"
        case .reactions:
            return "No reaction activity"
        case .unreads:
            return "No unread items"
        case .saved:
            return "No saved items"
        }
    }
}

private struct ActivityRow: View {
    let item: ActivityItem

    private var leadingIcon: String {
        switch item.type {
        case .all:
            return "line.3.horizontal"
        case .mentions:
            return "at"
        case .threads:
            return "arrowshape.turn.up.left.fill"
        case .reactions:
            return "face.smiling.inverse"
        case .unreads:
            return item.dmId == nil ? "number" : "bubble.left.fill"
        case .saved:
            return "bookmark.fill"
        }
    }

    private var leadingColor: Color {
        switch item.type {
        case .mentions:
            return TeamChatPalette.accent
        case .threads:
            return Color(red: 0.37, green: 0.77, blue: 0.59)
        case .reactions:
            return Color(red: 0.92, green: 0.75, blue: 0.26)
        case .unreads:
            return Color(red: 0.42, green: 0.58, blue: 0.86)
        case .saved:
            return Color(red: 0.86, green: 0.33, blue: 0.40)
        case .all:
            return TeamChatPalette.subtleText
        }
    }

    private var contextLabel: String {
        switch item.type {
        case .threads:
            if item.dmId != nil {
                return "Thread in Direct Message"
            }
            return "Thread in \(item.channelOrDMName)"
        case .reactions:
            return "Reaction in \(item.channelOrDMName)"
        case .mentions:
            return "Mention in \(item.channelOrDMName)"
        case .unreads:
            return item.channelOrDMName
        case .saved:
            return "Saved from \(item.channelOrDMName)"
        case .all:
            return item.channelOrDMName
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(leadingColor.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(leadingColor)
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top) {
                    Text(contextLabel)
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                    Spacer()
                    Text(DateFormatters.relative.localizedString(for: item.timestamp, relativeTo: Date()))
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                }

                Text(item.title)
                    .font(.subheadline.weight(item.isUnread ? .bold : .semibold))
                    .foregroundStyle(item.isUnread ? .white : .white.opacity(0.9))
                    .lineLimit(1)
                    .accessibilityIdentifier("activity_title_\(item.id.accessibilitySlug)")

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(item.isUnread ? TeamChatPalette.secondaryText : TeamChatPalette.subtleText)
                    .lineLimit(2)
                    .accessibilityIdentifier("activity_subtitle_\(item.id.accessibilitySlug)")
            }
        }
        .padding(.horizontal, TeamChatMetrics.pagePadding)
        .padding(.vertical, 10)
        .accessibilityIdentifier("activity_row_\(item.id.accessibilitySlug)")
    }
}
