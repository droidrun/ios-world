import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showMyProfile: Bool = false
    @State private var selectedConnection: Connection?
    @State private var selectedPost: Post?
    @State private var showNotifSettings: Bool = false
    @State private var showJobNotifActions: Bool = false
    @State private var notifJobRecommendations: Bool = true
    @State private var notifConnectionUpdates: Bool = true
    @State private var notifPostReactions: Bool = true
    @State private var notifMessages: Bool = true
    @State private var notifInMail: Bool = false
    @State private var notifActionTarget: String?

    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs
            filterTabs

            // Content
            if appState.filteredNotifications.isEmpty && appState.selectedNotificationFilter != .jobs {
                emptyState
            } else {
                notificationsList
            }
        }
        .background(LockedInTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showMyProfile = true
                } label: {
                    AvatarView(
                        name: appState.currentUser.fullName,
                        initials: appState.currentUser.avatarInitials,
                        topHex: appState.currentUser.avatarTopHex,
                        bottomHex: appState.currentUser.avatarBottomHex,
                        size: 30
                    )
                }
            }
            ToolbarItem(placement: .principal) {
                Button {
                    appState.showSearch = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(LockedInTheme.secondaryText)
                            .font(.system(size: 14))
                        Text("I'm looking for...")
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
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { showNotifSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                    Button(action: { appState.showMessaging = true }) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 18))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
            }
        }
        .sheet(isPresented: $showMyProfile) {
            ProfileMenuView()
        }
        .sheet(item: $selectedConnection) { conn in
            ProfileView(connection: conn, isCurrentUser: false)
        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
        .sheet(isPresented: $showNotifSettings) {
            NavigationStack {
                List {
                    Section("Notification preferences") {
                        Toggle("Job recommendations", isOn: $notifJobRecommendations)
                        Toggle("Connection updates", isOn: $notifConnectionUpdates)
                        Toggle("Post reactions", isOn: $notifPostReactions)
                        Toggle("Messages", isOn: $notifMessages)
                        Toggle("InMail", isOn: $notifInMail)
                    }
                }
                .navigationTitle("Notification Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showNotifSettings = false }
                    }
                }
            }
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NotificationFilter.allCases) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.selectedNotificationFilter = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 14, weight: appState.selectedNotificationFilter == filter ? .semibold : .regular))
                                .foregroundColor(appState.selectedNotificationFilter == filter ? .white : LockedInTheme.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(appState.selectedNotificationFilter == filter ? LockedInTheme.greenButton : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(appState.selectedNotificationFilter == filter ? Color.clear : LockedInTheme.separator, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(LockedInTheme.cardBackground)

            Divider()
        }
    }

    // MARK: - Notifications List

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Show job notifications if in Jobs filter
                if appState.selectedNotificationFilter == .jobs {
                    ForEach(appState.jobNotifications) { jn in
                        jobNotificationRow(jn)
                    }
                } else {
                    ForEach(appState.filteredNotifications) { notification in
                        notificationRow(notification)
                    }
                }
            }
            .background(LockedInTheme.cardBackground)
        }
    }

    private func notificationRow(_ notification: LockedInNotification) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Unread indicator
                Circle()
                    .fill(notification.isRead ? Color.clear : LockedInTheme.linkedInBlue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                // Avatar
                if notification.isCompanyNotification {
                    CompanyLogoView(
                        initials: notification.companyLogoInitials ?? notification.actorInitials,
                        topHex: notification.actorAvatarTopHex,
                        bottomHex: notification.actorAvatarBottomHex,
                        size: 44
                    )
                } else {
                    AvatarView(
                        name: notification.actorName,
                        initials: notification.actorInitials,
                        topHex: notification.actorAvatarTopHex,
                        bottomHex: notification.actorAvatarBottomHex,
                        size: 44
                    )
                    .overlay(alignment: .bottomTrailing) {
                        notificationTypeIcon(notification.type)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    formattedNotificationMessage(notification)

                    if let actionLabel = notification.actionLabel {
                        Button(action: {
                            if actionLabel == "View jobs" {
                                appState.selectedTab = .jobs
                            } else if let conn = appState.connections.first(where: { $0.fullName == notification.actorName }) {
                                selectedConnection = conn
                            }
                        }) {
                            Text(actionLabel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                                )
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer()

                // Time and actions on right
                VStack(alignment: .trailing, spacing: 6) {
                    Text(notification.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.tertiaryText)

                    Button(action: { notifActionTarget = notification.id }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(notification.isRead ? LockedInTheme.cardBackground : Color(hex: 0xEDF3F8).opacity(0.5))
            .onTapGesture {
                appState.markNotificationRead(notification.id)
                // Navigate to the related post or connection profile
                if let postId = notification.relatedPostId,
                   let post = appState.posts.first(where: { $0.id == postId }) {
                    selectedPost = post
                } else if notification.type == .connectionAccepted || notification.type == .profileView {
                    if let conn = appState.connections.first(where: { $0.fullName == notification.actorName }) {
                        selectedConnection = conn
                    }
                }
            }
            .confirmationDialog("", isPresented: Binding(
                get: { notifActionTarget == notification.id },
                set: { if !$0 { notifActionTarget = nil } }
            )) {
                Button("Mark as read") { appState.markNotificationRead(notification.id) }
                Button("Turn off this notification type") { appState.markNotificationRead(notification.id) }
                Button("Delete notification", role: .destructive) {
                    withAnimation { appState.notifications.removeAll { $0.id == notification.id } }
                }
                Button("Cancel", role: .cancel) {}
            }

            Divider()
                .padding(.leading, 76)
        }
    }

    @ViewBuilder
    private func formattedNotificationMessage(_ notification: LockedInNotification) -> some View {
        let message = notification.message
        let actorName = notification.actorName

        if let range = message.range(of: actorName) {
            let before = String(message[message.startIndex..<range.lowerBound])
            let after = String(message[range.upperBound...])

            (
                Text(before) +
                Text(actorName).bold() +
                Text(after)
            )
            .font(.system(size: 13))
            .foregroundColor(notification.isRead ? LockedInTheme.secondaryText : LockedInTheme.primaryText)
            .lineLimit(3)
        } else {
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(notification.isRead ? LockedInTheme.secondaryText : LockedInTheme.primaryText)
                .lineLimit(3)
        }
    }

    @ViewBuilder
    private func notificationTypeIcon(_ type: NotificationType) -> some View {
        let (icon, bgColor): (String, Color) = {
            switch type {
            case .postReaction: return ("hand.thumbsup.fill", LockedInTheme.linkedInBlue)
            case .postComment: return ("bubble.left.fill", LockedInTheme.greenButton)
            case .connectionAccepted: return ("person.badge.plus", LockedInTheme.linkedInBlue)
            case .profileView: return ("eye.fill", Color(hex: 0x666666))
            case .mention: return ("at", LockedInTheme.linkedInBlue)
            case .postShared: return ("arrow.2.squarepath", LockedInTheme.linkedInBlue)
            case .workAnniversary: return ("star.fill", Color(hex: 0x9B59B6))
            case .birthday: return ("gift.fill", Color(hex: 0xFF6B35))
            default: return ("bell.fill", LockedInTheme.linkedInBlue)
            }
        }()

        Image(systemName: icon)
            .font(.system(size: 7))
            .foregroundColor(.white)
            .padding(3)
            .background(Circle().fill(bgColor))
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .offset(x: 2, y: 2)
    }

    private func jobNotificationRow(_ jn: JobNotification) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(LockedInTheme.linkedInBlue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                CompanyLogoView(
                    initials: "in",
                    topHex: "0x004182",
                    bottomHex: "0x0077B5",
                    size: 44
                )

                VStack(alignment: .leading, spacing: 4) {
                    (
                        Text(jn.title)
                            .bold() +
                        Text(": \(jn.companies)") +
                        Text(jn.location != nil ? " in " : ".") +
                        Text(jn.location != nil ? "\(jn.location!)." : "").bold()
                    )
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.primaryText)

                    Button(action: {
                        appState.selectedTab = .jobs
                        dismiss()
                    }) {
                        Text("View jobs")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                            )
                    }
                    .padding(.top, 4)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(jn.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.tertiaryText)

                    Button(action: { showJobNotifActions = true }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                    .confirmationDialog("", isPresented: $showJobNotifActions) {
                        Button("Turn off this alert", role: .destructive) {
                            appState.jobAlertEnabled = false
                        }
                        Button("View job settings") {
                            appState.selectedTab = .jobs
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, 76)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(LockedInTheme.tertiaryText)

            Text(emptyStateTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(LockedInTheme.primaryText)

            Text(emptyStateMessage)
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if appState.selectedNotificationFilter == .myPosts {
                Button { appState.selectedNotificationFilter = .all } label: {
                    Text("View previous activity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                        )
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(LockedInTheme.cardBackground)
    }

    private var emptyStateIcon: String {
        switch appState.selectedNotificationFilter {
        case .all: return "bell.slash"
        case .jobs: return "briefcase"
        case .myPosts: return "doc.text"
        case .mentions: return "at"
        }
    }

    private var emptyStateTitle: String {
        switch appState.selectedNotificationFilter {
        case .all: return "No notifications"
        case .jobs: return "No job notifications"
        case .myPosts: return "No new post activities"
        case .mentions: return "No new mentions"
        }
    }

    private var emptyStateMessage: String {
        switch appState.selectedNotificationFilter {
        case .all: return "When you have notifications, they'll appear here."
        case .jobs: return "Job alerts and recommendations will appear here."
        case .myPosts: return "View your previous post activity on your profile"
        case .mentions: return "When someone tags you in a post or comment, that notification will appear here."
        }
    }
}
