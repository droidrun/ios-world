import SwiftUI

struct ChannelInfoView: View {
    @ObservedObject var viewModel: ChannelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            List {
                if let channel = viewModel.channel {
                    Section("Channel") {
                        Text(channel.displayName)
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("channel_info_name")
                        Text(channel.descriptionTopic)
                            .font(.subheadline)
                            .foregroundStyle(TeamChatPalette.subtleText)
                            .accessibilityIdentifier("channel_info_description")
                        HStack {
                            Text("Privacy")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(channel.isPrivate ? "Private" : "Public")
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        .accessibilityIdentifier("channel_info_privacy")
                        HStack {
                            Text("Member count")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(viewModel.memberCount)")
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        .accessibilityIdentifier("channel_info_member_count")
                    }

                    Section("Preferences") {
                        Toggle(
                            isOn: Binding(
                                get: { channel.notifyOnAllMessages },
                                set: { _ in viewModel.toggleNotificationPreference() }
                            )
                        ) {
                            Text("Notify for all messages")
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
                        .accessibilityIdentifier("channel_notifications_toggle")

                        Toggle(
                            isOn: Binding(
                                get: { channel.isMuted },
                                set: { _ in viewModel.toggleMute() }
                            )
                        ) {
                            Text("Mute channel")
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: TeamChatPalette.accent))
                        .accessibilityIdentifier("channel_mute_toggle")
                    }

                    Section("Pinned / Files / Links") {
                        NavigationLink {
                            MoreStaticCollectionView(
                                title: "Pinned items",
                                subtitle: "Saved references for \(channel.displayName)",
                                rows: staticInfoRows(prefix: "Pinned item", count: channel.pinnedItemsPlaceholderCount)
                            )
                        } label: {
                            HStack {
                                Text("Pinned items")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(channel.pinnedItemsPlaceholderCount)")
                                    .foregroundStyle(TeamChatPalette.subtleText)
                            }
                        }
                        .accessibilityIdentifier("channel_pinned_placeholder")

                        NavigationLink {
                            MoreStaticCollectionView(
                                title: "Files",
                                subtitle: "Recent files shared in \(channel.displayName)",
                                rows: staticInfoRows(prefix: "File", count: channel.filesPlaceholderCount)
                            )
                        } label: {
                            HStack {
                                Text("Files")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(channel.filesPlaceholderCount)")
                                    .foregroundStyle(TeamChatPalette.subtleText)
                            }
                        }
                        .accessibilityIdentifier("channel_files_placeholder")

                        NavigationLink {
                            MoreStaticCollectionView(
                                title: "Links",
                                subtitle: "Shared references for \(channel.displayName)",
                                rows: staticInfoRows(prefix: "Link", count: channel.linksPlaceholderCount)
                            )
                        } label: {
                            HStack {
                                Text("Links")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(channel.linksPlaceholderCount)")
                                    .foregroundStyle(TeamChatPalette.subtleText)
                            }
                        }
                        .accessibilityIdentifier("channel_links_placeholder")
                    }

                    Section("Members") {
                        ForEach(viewModel.members) { member in
                            NavigationLink {
                                MemberDetailView(store: viewModel.store, memberId: member.id)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(member.presenceState.color)
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.displayName)
                                            .foregroundStyle(.white)
                                            .accessibilityIdentifier("member_name_\(member.username)")
                                        Text("@\(member.username) - \(member.title)")
                                            .font(.caption)
                                            .foregroundStyle(TeamChatPalette.subtleText)
                                            .accessibilityIdentifier("member_title_\(member.username)")
                                    }
                                }
                            }
                            .accessibilityIdentifier("member_row_\(member.username)")
                        }
                    }

                    Section {
                        Button("Leave channel") {
                            if viewModel.leaveChannel() {
                                dismiss()
                            }
                        }
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("leave_channel_placeholder_button")
                    }
                } else {
                    Text("Channel not found")
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("channel_not_found_state")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Channel Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hidesRootChrome()
    }

    private func staticInfoRows(prefix: String, count: Int) -> [MoreStaticRow] {
        let channelName = viewModel.channel?.displayName ?? "channel"
        let safeCount = max(count, 1)

        let pinnedTitles = [
            "Launch checklist — updated March 10",
            "On-call rotation schedule Q2",
            "API versioning decision doc",
            "Sprint retro action items",
            "Release readiness criteria",
            "Incident response playbook",
            "Team OKRs — 2026 H1",
            "Design system component inventory"
        ]
        let fileTitles = [
            "architecture-diagram.pdf",
            "q1-metrics-dashboard.xlsx",
            "onboarding-guide-v3.docx",
            "api-spec-v2.yaml",
            "test-coverage-report.html",
            "mobile-wireframes.fig",
            "deployment-runbook.md",
            "budget-forecast-2026.xlsx"
        ]
        let linkTitles = [
            "Figma — Mobile App Redesign",
            "Jira — Sprint Board",
            "Confluence — Architecture Docs",
            "Grafana — API Latency Dashboard",
            "GitHub — Release Branch",
            "Notion — Team Wiki",
            "Linear — Bug Tracker",
            "Datadog — Error Monitoring"
        ]

        let titles: [String]
        switch prefix {
        case "Pinned item": titles = pinnedTitles
        case "File": titles = fileTitles
        case "Link": titles = linkTitles
        default: titles = (1...8).map { "\(prefix) \($0)" }
        }

        return (0..<safeCount).map { index in
            MoreStaticRow(
                title: titles[index % titles.count],
                subtitle: "Shared in #\(channelName)"
            )
        }
    }
}
