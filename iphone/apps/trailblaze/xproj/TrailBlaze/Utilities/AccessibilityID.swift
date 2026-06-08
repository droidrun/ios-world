import Foundation

enum AccessibilityID {
    static let tabFeed = "tab_feed"
    static let tabRecord = "tab_record"
    static let tabRoutes = "tab_routes"
    static let tabClubs = "tab_clubs"
    static let tabProfile = "tab_profile"

    static let recordStartButton = "record_start_button"
    static let recordPauseButton = "record_pause_button"
    static let recordResumeButton = "record_resume_button"
    static let recordStopButton = "record_stop_button"
    static let recordSaveButton = "record_save_button"
    static let recordDiscardButton = "record_discard_button"

    static let activityDetailView = "activity_detail_view"
    static let debugSwitchActivitySource = "debug_switch_activity_source"
    static let profileResetAppState = "profile_reset_app_state"
    static let feedEmptyState = "feed_empty_state"
    static let notificationsEmptyState = "notifications_empty_state"
    static let clubsEmptyMembershipState = "clubs_empty_membership_state"
    static let routesEmptySavedState = "routes_empty_saved_state"
    static let snapshotUnavailableState = "snapshot_unavailable_state"

    static func activityRow(_ activityId: String) -> String {
        "activity_row_\(suffix(for: activityId))"
    }

    static func activityOpenButton(_ activityId: String) -> String {
        "activity_open_button_\(suffix(for: activityId))"
    }

    static func kudosButton(_ activityId: String) -> String {
        "kudos_button_activity_\(suffix(for: activityId))"
    }

    static func commentField(_ activityId: String) -> String {
        "comment_field_activity_\(suffix(for: activityId))"
    }

    static func commentSendButton(_ activityId: String) -> String {
        "comment_send_button_activity_\(suffix(for: activityId))"
    }

    static func routeRow(_ routeId: String) -> String {
        "route_row_\(suffix(for: routeId))"
    }

    static func routeSaveButton(_ routeId: String) -> String {
        "route_save_button_\(suffix(for: routeId))"
    }

    static func routeBookmarkButton(_ routeId: String) -> String {
        "route_bookmark_button_\(suffix(for: routeId))"
    }

    static func routeStartButton(_ routeId: String) -> String {
        "route_start_activity_button_\(suffix(for: routeId))"
    }

    static func clubRow(_ clubId: String) -> String {
        "club_row_\(suffix(for: clubId))"
    }

    static func clubJoinButton(_ clubId: String) -> String {
        "club_join_button_\(suffix(for: clubId))"
    }

    static func segmentRow(_ segmentId: String) -> String {
        "segment_row_\(suffix(for: segmentId))"
    }

    static func segmentLeaderboardRow(_ entryId: String) -> String {
        "segment_leaderboard_row_\(suffix(for: entryId))"
    }

    static func notificationRow(_ notificationId: String) -> String {
        "notification_row_\(suffix(for: notificationId))"
    }

    static func dataModeOption(_ mode: ActivityDataMode) -> String {
        "data_mode_\(mode.rawValue)"
    }

    static func athleteProfileButton(_ athleteId: String) -> String {
        "athlete_profile_button_\(suffix(for: athleteId))"
    }

    private static func suffix(for rawId: String) -> String {
        rawId.components(separatedBy: "_").last ?? rawId
    }
}
