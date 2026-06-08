import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var appState: AppState

    private var viewModel: NotificationsViewModel {
        NotificationsViewModel(appState: appState)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        title: "No notifications",
                        subtitle: "Kudos, comments, challenge updates, and club announcements will appear here.",
                        systemImage: "bell.slash",
                        identifier: AccessibilityID.notificationsEmptyState
                    )
                } else {
                    ForEach(viewModel.notifications) { notification in
                        notificationRow(notification)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if appState.unreadNotificationCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Read All") {
                        appState.markAllNotificationsRead()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func notificationRow(_ notification: Notification) -> some View {
        let destination = destinationView(for: notification)

        if let destination {
            NavigationLink(destination: destination) {
                notificationContent(notification)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                appState.markNotificationRead(notification.id)
            })
            .accessibilityIdentifier(AccessibilityID.notificationRow(notification.id))
        } else {
            Button {
                appState.markNotificationRead(notification.id)
            } label: {
                notificationContent(notification)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.notificationRow(notification.id))
        }
    }

    private func notificationContent(_ notification: Notification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notification.isRead ? AppTheme.backgroundMuted : AppTheme.accentMuted)
                Image(systemName: icon(for: notification.kind))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(notification.isRead ? AppTheme.textSecondary : AppTheme.accent)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 6) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(AppFormatters.fullDate(notification.createdAt))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }

    private func icon(for kind: NotificationKind) -> String {
        switch kind {
        case .kudos: return "hand.thumbsup.fill"
        case .commentReply: return "ellipsis.bubble.fill"
        case .challenge: return "flag.checkered"
        case .clubAnnouncement: return "megaphone.fill"
        case .weeklySummary: return "calendar"
        }
    }

    private func destinationView(for notification: Notification) -> AnyView? {
        if let activityId = notification.relatedActivityId {
            return AnyView(ActivityDetailView(activityId: activityId))
        }
        if let clubId = notification.relatedClubId {
            return AnyView(ClubDetailView(clubId: clubId))
        }
        switch notification.kind {
        case .challenge:
            return AnyView(ClubsView())
        case .weeklySummary:
            return AnyView(ProfileView())
        case .kudos, .commentReply, .clubAnnouncement:
            return nil
        }
    }
}

struct InboxView: View {
    @EnvironmentObject private var appState: AppState

    private var inboxNotifications: [Notification] {
        appState.currentData.notifications.filter {
            switch $0.kind {
            case .kudos, .commentReply, .clubAnnouncement:
                return true
            case .challenge, .weeklySummary:
                return false
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if inboxNotifications.isEmpty {
                    EmptyStateView(
                        title: "No inbox activity",
                        subtitle: "Replies, club announcements, and reactions will appear here.",
                        systemImage: "bubble.left.and.bubble.right",
                        identifier: "inbox_empty_state"
                    )
                } else {
                    ForEach(inboxNotifications) { notification in
                        inboxRow(notification)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func inboxRow(_ notification: Notification) -> some View {
        let destination = inboxDestination(for: notification)

        if let destination {
            NavigationLink(destination: destination) {
                inboxContent(notification)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                appState.markNotificationRead(notification.id)
            })
        } else {
            Button {
                appState.markNotificationRead(notification.id)
            } label: {
                inboxContent(notification)
            }
            .buttonStyle(.plain)
        }
    }

    private func inboxContent(_ notification: Notification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notification.isRead ? AppTheme.backgroundMuted : AppTheme.accentMuted)
                Image(systemName: inboxIcon(for: notification.kind))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(notification.isRead ? AppTheme.textSecondary : AppTheme.accent)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 6) {
                Text(inboxTitle(for: notification))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                Text(AppFormatters.fullDate(notification.createdAt))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }

    private func inboxTitle(for notification: Notification) -> String {
        switch notification.kind {
        case .commentReply:
            return "Activity Replies"
        case .clubAnnouncement:
            return notification.relatedClubId.flatMap { appState.club(id: $0)?.name } ?? notification.title
        case .kudos:
            return "Activity Reactions"
        case .challenge, .weeklySummary:
            return notification.title
        }
    }

    private func inboxIcon(for kind: NotificationKind) -> String {
        switch kind {
        case .commentReply:
            return "bubble.left.and.bubble.right.fill"
        case .clubAnnouncement:
            return "person.3.fill"
        case .kudos:
            return "hand.thumbsup.fill"
        case .challenge:
            return "flag.checkered"
        case .weeklySummary:
            return "calendar"
        }
    }

    private func inboxDestination(for notification: Notification) -> AnyView? {
        if let activityId = notification.relatedActivityId {
            return AnyView(ActivityDetailView(activityId: activityId))
        }
        if let clubId = notification.relatedClubId {
            return AnyView(ClubDetailView(clubId: clubId))
        }
        return nil
    }
}
