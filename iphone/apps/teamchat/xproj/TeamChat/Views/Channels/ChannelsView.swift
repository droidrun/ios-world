import SwiftUI

struct ChannelsView: View {
    @StateObject private var viewModel: ChannelsViewModel
    @State private var showProfileSheet = false

    init(store: WorkspaceStore) {
        _viewModel = StateObject(wrappedValue: ChannelsViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TeamChatPalette.screen.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    List {
                        sectionView(title: "Starred", channels: viewModel.starredChannels, emptyId: "starred_channels_empty_state")
                        sectionView(title: "Unreads", channels: viewModel.unreadChannels, emptyId: "unread_channels_empty_state")
                        sectionView(title: "Channels", channels: viewModel.publicChannels, emptyId: "public_channels_empty_state")
                        sectionView(title: "Private Channels", channels: viewModel.privateChannels, emptyId: "private_channels_empty_state")
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(store: viewModel.store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Channels")
                    .font(.system(size: TeamChatMetrics.headerTitleSize, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                Text(viewModel.workspaceName)
                    .font(.subheadline)
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .accessibilityIdentifier("channels_workspace_label")
            }

            Spacer()

            Button {
                showProfileSheet = true
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: TeamChatMetrics.headerProfileIconSize))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("channels_profile_button")
        }
        .padding(.horizontal, TeamChatMetrics.headerHorizontalPadding)
        .padding(.top, TeamChatMetrics.headerTopPadding)
        .padding(.bottom, TeamChatMetrics.headerBottomPadding)
        .background(TeamChatPalette.header)
    }

    @ViewBuilder
    private func sectionView(title: String, channels: [Channel], emptyId: String) -> some View {
        Section(title) {
            if channels.isEmpty {
                Text("No channels in this section")
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .listRowBackground(TeamChatPalette.screen)
                    .accessibilityIdentifier(emptyId)
            } else {
                ForEach(channels) { channel in
                    NavigationLink {
                        ChannelDetailView(store: viewModel.store, channelId: channel.id)
                    } label: {
                        ChannelRowView(channel: channel)
                    }
                    .listRowBackground(TeamChatPalette.screen)
                    .listRowSeparatorTint(TeamChatPalette.divider)
                    .accessibilityIdentifier("channel_row_\(channel.channelName.accessibilitySlug)")
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(channel.isMuted ? "Unmute" : "Mute") {
                            viewModel.toggleMute(channel.id)
                        }
                        .tint(.orange)
                        .accessibilityIdentifier("channel_mute_action_\(channel.channelName.accessibilitySlug)")

                        Button(channel.isStarred ? "Unstar" : "Star") {
                            viewModel.toggleStar(channel.id)
                        }
                        .tint(.yellow)
                        .accessibilityIdentifier("channel_star_action_\(channel.channelName.accessibilitySlug)")
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button(channel.unreadCount > 0 ? "Mark Read" : "Mark Unread") {
                            if channel.unreadCount > 0 {
                                viewModel.markRead(channel.id)
                            } else {
                                viewModel.markUnread(channel.id)
                            }
                        }
                        .tint(.blue)
                        .accessibilityIdentifier("channel_read_action_\(channel.channelName.accessibilitySlug)")
                    }
                }
            }
        }
        .headerProminence(.increased)
        .listSectionSeparatorTint(TeamChatPalette.divider)
    }
}

private struct ChannelRowView: View {
    let channel: Channel

    private var hasUnread: Bool { channel.unreadCount > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(channel.displayName)
                    .font(.headline.weight(hasUnread ? .bold : .regular))
                    .foregroundStyle(hasUnread ? .white : TeamChatPalette.subtleText)
                    .accessibilityIdentifier("channel_name_\(channel.channelName.accessibilitySlug)")

                if channel.isPrivate {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("channel_private_indicator_\(channel.channelName.accessibilitySlug)")
                }

                if channel.isMuted {
                    Image(systemName: "bell.slash")
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("channel_muted_indicator_\(channel.channelName.accessibilitySlug)")
                }

                Spacer()

                Text(DateFormatters.relative.localizedString(for: channel.lastMessageAt, relativeTo: Date()))
                    .font(.caption)
                    .foregroundStyle(TeamChatPalette.subtleText)
            }

            Text(channel.lastMessagePreview)
                .font(.callout)
                .foregroundStyle(hasUnread ? TeamChatPalette.secondaryText : TeamChatPalette.subtleText)
                .lineLimit(2)
                .accessibilityIdentifier("channel_preview_\(channel.channelName.accessibilitySlug)")

            HStack(spacing: 6) {
                if channel.unreadCount > 0 {
                    Text("\(channel.unreadCount)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(TeamChatPalette.unreadBadge, in: Capsule())
                        .accessibilityIdentifier("unread_badge_channel_\(channel.channelName.accessibilitySlug)")
                }

                if channel.mentionCount > 0 {
                    Text("\(channel.mentionCount) mention")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(TeamChatPalette.avatarRing, in: Capsule())
                        .accessibilityIdentifier("mention_chip_channel_\(channel.channelName.accessibilitySlug)")
                }
            }
        }
        .padding(.vertical, 4)
    }
}
