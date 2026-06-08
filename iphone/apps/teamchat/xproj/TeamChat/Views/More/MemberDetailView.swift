import SwiftUI

struct MemberDetailView: View {
    @ObservedObject var store: WorkspaceStore
    let memberId: String

    @Environment(\.dismiss) private var dismiss
    @State private var showDMCreatedAlert = false
    @State private var createdDMId: String?

    private var member: WorkspaceMember? {
        store.member(with: memberId)
    }

    private var isCurrentUser: Bool {
        memberId == store.activeWorkspace?.currentUserId
    }

    private var currentUserProfile: UserProfile? {
        store.activeWorkspace?.userProfile
    }

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            if let member {
                ScrollView {
                    VStack(spacing: 0) {
                        // Avatar + name header
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                TeamChatUserAvatar(
                                    displayName: member.displayName,
                                    fallbackInitials: String(member.displayName.prefix(1)).uppercased(),
                                    size: 84,
                                    cornerRadius: 22
                                )
                                .accessibilityIdentifier("member_detail_avatar")

                                Circle()
                                    .fill(member.presenceState.color)
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().stroke(TeamChatPalette.screen, lineWidth: 2))
                                    .accessibilityIdentifier("member_detail_presence_dot")
                            }

                            VStack(spacing: 4) {
                                Text(member.displayName)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .accessibilityIdentifier("member_detail_name")

                                Text("@\(member.username)")
                                    .font(.subheadline)
                                    .foregroundStyle(TeamChatPalette.subtleText)
                                    .accessibilityIdentifier("member_detail_username")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                        // Quick actions for other members
                        if !isCurrentUser {
                            Button {
                                let dmId = store.createMockDM(with: [memberId])
                                if let dmId {
                                    createdDMId = dmId
                                    store.switchTab(.dms)
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Message")
                                        .font(.headline.weight(.semibold))
                                }
                                .foregroundStyle(TeamChatPalette.screen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(TeamChatPalette.accent, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                            .accessibilityIdentifier("member_detail_message_button")
                        }

                        // Profile info card
                        VStack(alignment: .leading, spacing: 0) {
                            memberInfoRow(
                                label: "Title",
                                value: member.title,
                                id: "member_detail_title"
                            )
                            Divider().overlay(TeamChatPalette.divider)
                            memberInfoRow(
                                label: "Role",
                                value: member.role,
                                id: "member_detail_role"
                            )
                            Divider().overlay(TeamChatPalette.divider)
                            memberInfoRow(
                                label: "Presence",
                                value: member.presenceState.label,
                                valueColor: member.presenceState.color,
                                id: "member_detail_presence"
                            )
                        }
                        .background(TeamChatPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                        // Notification preferences section (current user only)
                        if isCurrentUser, let profile = currentUserProfile {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Notifications")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(TeamChatPalette.subtleText)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 6)

                                VStack(alignment: .leading, spacing: 0) {
                                    notificationRow(
                                        label: "Push notifications",
                                        isOn: profile.notificationPreference.pushEnabled,
                                        id: "member_detail_pref_push"
                                    )
                                    Divider().overlay(TeamChatPalette.divider)
                                    notificationRow(
                                        label: "Mentions only",
                                        isOn: profile.notificationPreference.mentionOnly,
                                        id: "member_detail_pref_mentions"
                                    )
                                    Divider().overlay(TeamChatPalette.divider)
                                    notificationRow(
                                        label: "Thread replies",
                                        isOn: profile.notificationPreference.threadRepliesEnabled,
                                        id: "member_detail_pref_threads"
                                    )
                                    Divider().overlay(TeamChatPalette.divider)
                                    notificationRow(
                                        label: "Huddle invites",
                                        isOn: profile.notificationPreference.huddleInvitesEnabled,
                                        id: "member_detail_pref_huddles"
                                    )
                                }
                                .background(TeamChatPalette.card)
                                .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 12)
                        }

                        // Status text (if any)
                        if isCurrentUser, let statusText = currentUserProfile?.statusText, !statusText.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Status")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(TeamChatPalette.subtleText)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 2)

                                HStack(spacing: 10) {
                                    Image(systemName: "face.smiling")
                                        .foregroundStyle(TeamChatPalette.subtleText)
                                    Text(statusText)
                                        .foregroundStyle(.white)
                                        .accessibilityIdentifier("member_detail_status_text")
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(TeamChatPalette.card)
                                .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 12)
                        }
                    }
                }
            } else {
                ContentUnavailableView("Member not found", systemImage: "person.slash")
                    .accessibilityIdentifier("no_members_found_state")
            }
        }
        .navigationTitle(isCurrentUser ? "Your Profile" : "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hidesRootChrome()
    }

    private func memberInfoRow(label: String, value: String, valueColor: Color = .white, id: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(TeamChatPalette.subtleText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .accessibilityIdentifier(id)
    }

    private func notificationRow(label: String, isOn: Bool, id: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isOn ? TeamChatPalette.accent : TeamChatPalette.subtleText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .accessibilityIdentifier(id)
    }
}
