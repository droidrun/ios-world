import Foundation

enum AppTab: String, CaseIterable, Codable, Hashable, Identifiable {
    case feed
    case routes
    case record
    case clubs
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: return "Home"
        case .routes: return "Maps"
        case .record: return "Record"
        case .clubs: return "Groups"
        case .profile: return "You"
        }
    }

    var systemImage: String {
        switch self {
        case .feed: return "house.fill"
        case .routes: return "map.fill"
        case .record: return "record.circle.fill"
        case .clubs: return "square.grid.2x2.fill"
        case .profile: return "chart.bar.fill"
        }
    }
}

enum ActivityDataMode: String, CaseIterable, Codable, Hashable, Identifiable {
    case seeded
    case bundledSnapshot
    case sandboxSnapshot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .seeded: return "Standard"
        case .bundledSnapshot: return "Bundled Snapshot"
        case .sandboxSnapshot: return "Sandbox Snapshot"
        }
    }
}

enum ActivityType: String, CaseIterable, Codable, Hashable, Identifiable {
    case run
    case ride
    case walk
    case hike
    case indoorRide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .run: return "Run"
        case .ride: return "Ride"
        case .walk: return "Walk"
        case .hike: return "Hike"
        case .indoorRide: return "Indoor Ride"
        }
    }

    var systemImage: String {
        switch self {
        case .run: return "figure.run"
        case .ride: return "bicycle"
        case .walk: return "figure.walk"
        case .hike: return "figure.hiking"
        case .indoorRide: return "bolt.heart.fill"
        }
    }

    var defaultSpeedKilometersPerHour: Double {
        switch self {
        case .run: return 10.6
        case .ride: return 28.4
        case .walk: return 5.2
        case .hike: return 4.4
        case .indoorRide: return 31.8
        }
    }

    var caloriesPerMinute: Int {
        switch self {
        case .run: return 13
        case .ride: return 11
        case .walk: return 5
        case .hike: return 8
        case .indoorRide: return 10
        }
    }
}

enum BenchmarkLocation {
    static let city = "San Francisco, CA"
    static let currentLocationLabel = "Current Location · San Francisco"
    static let referenceLatitude = 37.7749
    static let referenceLongitude = -122.4194

    static func fallbackRoutePoints(routeId: String) -> [RoutePoint] {
        [
            RoutePoint(id: "\(routeId)_point_1", latitude: 37.7749, longitude: -122.4194),
            RoutePoint(id: "\(routeId)_point_2", latitude: 37.7798, longitude: -122.4149),
            RoutePoint(id: "\(routeId)_point_3", latitude: 37.7842, longitude: -122.4081)
        ]
    }
}

struct WorkoutPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let durationSeconds: Int
    let systemImage: String
    let activityType: ActivityType
}

enum WorkoutCatalog {
    static let presets: [WorkoutPreset] = [
        WorkoutPreset(
            id: "foundation_strength",
            title: "Foundation Strength",
            subtitle: "Build a strong foundation with bodyweight exercises. Develop overall strength and consistency.",
            durationSeconds: 30 * 60,
            systemImage: "dumbbell.fill",
            activityType: .run
        ),
        WorkoutPreset(
            id: "recovery_mobility",
            title: "Recovery Mobility",
            subtitle: "Open up tight hips, reset after hard workouts, and stay ready for the next block.",
            durationSeconds: 18 * 60,
            systemImage: "figure.cooldown",
            activityType: .walk
        ),
        WorkoutPreset(
            id: "speed_starter",
            title: "Speed Starter",
            subtitle: "Short intervals with plenty of recovery to sharpen turnover and wake up the legs.",
            durationSeconds: 22 * 60,
            systemImage: "bolt.fill",
            activityType: .run
        ),
        WorkoutPreset(
            id: "core_reset",
            title: "Core Reset",
            subtitle: "A quick circuit to reinforce posture and form before your next run or ride.",
            durationSeconds: 14 * 60,
            systemImage: "figure.core.training",
            activityType: .ride
        )
    ]
}

enum ActivityContext: String, Codable, Hashable {
    case personal
    case friend
    case club
}

enum NotificationKind: String, Codable, Hashable {
    case kudos
    case commentReply
    case challenge
    case clubAnnouncement
    case weeklySummary

    var title: String {
        switch self {
        case .kudos: return "Kudos"
        case .commentReply: return "Comment"
        case .challenge: return "Challenge"
        case .clubAnnouncement: return "Club"
        case .weeklySummary: return "Weekly"
        }
    }
}

struct Athlete: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var handle: String
    var city: String
    var bio: String
    var followingCount: Int
    var followerCount: Int
    var achievements: [String]
    var personalRecords: [String]
    var isCurrentUser: Bool
}

struct ActivitySplit: Identifiable, Codable, Hashable {
    let id: String
    var index: Int
    var distanceKilometers: Double
    var durationSeconds: Int
}

struct SegmentResult: Identifiable, Codable, Hashable {
    let id: String
    var segmentId: String
    var timeSeconds: Int
    var rank: Int
}

struct RoutePoint: Identifiable, Codable, Hashable {
    let id: String
    var latitude: Double
    var longitude: Double
}

struct LeaderboardEntry: Identifiable, Codable, Hashable {
    let id: String
    var athleteId: String
    var athleteName: String
    var timeSeconds: Int
    var rank: Int
}

struct Segment: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var distanceKilometers: Double
    var gradePercent: Double
    var routeId: String
    var leaderboard: [LeaderboardEntry]
}

struct Comment: Identifiable, Codable, Hashable {
    let id: String
    var athleteId: String
    var message: String
    var createdAt: Date
}

struct Activity: Identifiable, Codable, Hashable {
    let id: String
    var athleteId: String
    var title: String
    var distanceKilometers: Double
    var durationSeconds: Int
    var elevationGainMeters: Double
    var avgPaceSecondsPerKilometer: Int
    var startTime: Date
    var activityType: ActivityType
    var routeId: String?
    var segmentResults: [SegmentResult]
    var kudosCount: Int
    var hasCurrentUserKudo: Bool
    var comments: [Comment]
    var sourceType: ActivityContext
    var clubId: String?
    var calories: Int
    var splits: [ActivitySplit]
    var lastUpdated: Date

    var commentCount: Int { comments.count }
}

struct Route: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var distanceKilometers: Double
    var elevationGainMeters: Double
    var estimatedTimeSeconds: Int
    var popularityScore: Int
    var startLocation: String
    var points: [RoutePoint]
    var elevationProfile: [Double]
    var segmentIds: [String]
    var isSaved: Bool
    var isBookmarked: Bool
    var recommendedActivityType: ActivityType
}

struct ClubMember: Identifiable, Codable, Hashable {
    let id: String
    var athleteId: String
    var weeklyDistanceKilometers: Double
    var isAdmin: Bool
}

struct Club: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String
    var memberCount: Int
    var members: [ClubMember]
    var weeklyLeaderboard: [LeaderboardEntry]
    var activityIds: [String]
    var isJoined: Bool
}

struct Notification: Identifiable, Codable, Hashable {
    let id: String
    var kind: NotificationKind
    var title: String
    var body: String
    var createdAt: Date
    var isRead: Bool
    var relatedActivityId: String?
    var relatedClubId: String?
}

struct Challenge: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var subtitle: String
    var progress: Double
    var goal: Double
    var reward: String
    var isCompleted: Bool
}

struct ActivitySnapshotMetadata: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var generatedAt: Date
    var sourceType: String
    var version: String
    var lastUpdated: Date
    var activityCount: Int
    var athleteCount: Int
}

struct ActivitySnapshot: Codable, Hashable {
    var metadata: ActivitySnapshotMetadata
    var currentUserAthleteId: String?
    var athletes: [Athlete]
    var activities: [Activity]
    var routes: [Route]
    var segments: [Segment]
    var clubs: [Club]?
    var notifications: [Notification]?
    var challenges: [Challenge]?
}

struct SimulationData: Codable, Hashable {
    var metadata: ActivitySnapshotMetadata?
    var currentUserAthleteId: String
    var athletes: [Athlete]
    var activities: [Activity]
    var routes: [Route]
    var segments: [Segment]
    var clubs: [Club]
    var notifications: [Notification]
    var challenges: [Challenge]

    static func empty(currentUserAthleteId: String) -> SimulationData {
        SimulationData(
            metadata: nil,
            currentUserAthleteId: currentUserAthleteId,
            athletes: [],
            activities: [],
            routes: [],
            segments: [],
            clubs: [],
            notifications: [],
            challenges: []
        )
    }
}

struct PersistedState: Codable, Hashable {
    var selectedTab: AppTab
    var selectedDataMode: ActivityDataMode
    var seededData: SimulationData
    var bundledSnapshotData: SimulationData?
    var sandboxSnapshotData: SimulationData?
    var importedSandboxSnapshotName: String?
}
