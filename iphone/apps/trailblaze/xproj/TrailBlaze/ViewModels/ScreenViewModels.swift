import Foundation

enum FeedFilter: String, CaseIterable, Identifiable {
    case all
    case personal
    case friends
    case clubs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .personal: return "You"
        case .friends: return "Friends"
        case .clubs: return "Clubs"
        }
    }
}

enum RouteFilter: String, CaseIterable, Identifiable {
    case all
    case saved
    case bookmarked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .saved: return "Saved"
        case .bookmarked: return "Bookmarked"
        }
    }
}

enum ClubFilter: String, CaseIterable, Identifiable {
    case all
    case joined

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All Clubs"
        case .joined: return "Joined"
        }
    }
}

@MainActor
struct FeedViewModel {
    let appState: AppState

    var challenges: [Challenge] { appState.currentData.challenges }

    func activities(filter: FeedFilter) -> [Activity] {
        let activities = appState.currentData.activities

        switch filter {
        case .all:
            return activities
        case .personal:
            return activities.filter { $0.athleteId == appState.currentData.currentUserAthleteId }
        case .friends:
            return activities.filter { $0.sourceType == .friend }
        case .clubs:
            return activities.filter { $0.clubId != nil }
        }
    }
}

@MainActor
struct ActivityDetailViewModel {
    let appState: AppState
    let activityId: String

    var activity: Activity? { appState.activity(id: activityId) }

    var athlete: Athlete? {
        guard let activity else { return nil }
        return appState.athlete(id: activity.athleteId)
    }

    var route: Route? {
        guard let routeId = activity?.routeId else { return nil }
        return appState.route(id: routeId)
    }

    var segments: [Segment] {
        guard let activity else { return [] }
        return activity.segmentResults.compactMap { appState.segment(id: $0.segmentId) }
    }

    var isOwnedByCurrentUser: Bool {
        activity?.athleteId == appState.currentData.currentUserAthleteId
    }
}

@MainActor
struct RoutesViewModel {
    let appState: AppState

    func routes(filter: RouteFilter) -> [Route] {
        let routes = appState.currentData.routes
        switch filter {
        case .all:
            return routes
        case .saved:
            return routes.filter(\.isSaved)
        case .bookmarked:
            return routes.filter(\.isBookmarked)
        }
    }
}

@MainActor
struct RouteDetailViewModel {
    let appState: AppState
    let routeId: String

    var route: Route? { appState.route(id: routeId) }

    var segments: [Segment] {
        guard let route else { return [] }
        return route.segmentIds.compactMap { appState.segment(id: $0) }
    }
}

@MainActor
struct ClubsViewModel {
    let appState: AppState

    func clubs(filter: ClubFilter) -> [Club] {
        let clubs = appState.currentData.clubs
        switch filter {
        case .all:
            return clubs
        case .joined:
            return clubs.filter(\.isJoined)
        }
    }
}

@MainActor
struct ClubDetailViewModel {
    let appState: AppState
    let clubId: String

    var club: Club? { appState.club(id: clubId) }

    var activities: [Activity] {
        guard let club else { return [] }
        return club.activityIds.compactMap { appState.activity(id: $0) }
    }
}

@MainActor
struct AthleteProfileViewModel {
    let appState: AppState
    let athleteId: String

    var athlete: Athlete? { appState.athlete(id: athleteId) }

    var activities: [Activity] { appState.activities(for: athleteId) }

    var totalDistanceKilometers: Double {
        activities.reduce(0) { $0 + $1.distanceKilometers }
    }
}

@MainActor
struct ProfileViewModel {
    let appState: AppState

    var athlete: Athlete? { appState.currentUser }
    var activities: [Activity] { appState.activities(for: appState.currentData.currentUserAthleteId) }
    var savedRoutes: [Route] { appState.currentData.routes.filter(\.isSaved) }
    var joinedClubs: [Club] { appState.currentData.clubs.filter(\.isJoined) }
    var challenges: [Challenge] { appState.currentData.challenges }

    var totalDistanceKilometers: Double {
        activities.reduce(0) { $0 + $1.distanceKilometers }
    }

    var yearlyDistanceKilometers: Double {
        let year = Calendar.current.component(.year, from: Date())
        return activities
            .filter { Calendar.current.component(.year, from: $0.startTime) == year }
            .reduce(0) { $0 + $1.distanceKilometers }
    }
}

@MainActor
struct NotificationsViewModel {
    let appState: AppState

    var notifications: [Notification] {
        appState.currentData.notifications
    }
}

@MainActor
struct MoreViewModel {
    let appState: AppState

    var selectedMode: ActivityDataMode { appState.selectedDataMode }
    var importedSnapshotName: String? { appState.importedSandboxSnapshotName }
}
