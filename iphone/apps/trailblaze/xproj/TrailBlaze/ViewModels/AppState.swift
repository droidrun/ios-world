import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var persistedState: PersistedState
    @Published var pendingRouteId: String?
    @Published var pendingWorkoutPreset: WorkoutPreset?
    @Published var lastErrorMessage: String?
    @Published var transientMessage: String?

    private let persistence: AppPersistence
    private let seededTemplate: SimulationData
    private let bundledSnapshotTemplate: SimulationData?

    init(persistence: AppPersistence = AppPersistence()) {
        self.persistence = persistence
        let seededTemplate = SeedData.makeSeededData()
        self.seededTemplate = seededTemplate

        let bundledSnapshotTemplate = (try? persistence.loadBundledSnapshot()).map { SeedData.mergedSnapshot($0, fallback: seededTemplate) }
        self.bundledSnapshotTemplate = bundledSnapshotTemplate

        let sandboxSnapshotTemplate = (try? persistence.loadImportedSandboxSnapshot()).map { SeedData.mergedSnapshot($0, fallback: seededTemplate) }

        if var saved = persistence.loadState() {
            if saved.bundledSnapshotData == nil {
                saved.bundledSnapshotData = bundledSnapshotTemplate
            }
            if saved.sandboxSnapshotData == nil {
                saved.sandboxSnapshotData = sandboxSnapshotTemplate ?? saved.sandboxSnapshotData
            }
            if saved.importedSandboxSnapshotName == nil {
                saved.importedSandboxSnapshotName = persistence.importedSnapshotFilename()
            }
            self.persistedState = saved
        } else {
            self.persistedState = PersistedState(
                selectedTab: .feed,
                selectedDataMode: .seeded,
                seededData: seededTemplate,
                bundledSnapshotData: bundledSnapshotTemplate,
                sandboxSnapshotData: sandboxSnapshotTemplate ?? nil,
                importedSandboxSnapshotName: persistence.importedSnapshotFilename()
            )
            saveState()
        }
    }

    var selectedTab: AppTab {
        get { persistedState.selectedTab }
        set {
            persistedState.selectedTab = newValue
            saveState()
        }
    }

    var selectedDataMode: ActivityDataMode {
        get { persistedState.selectedDataMode }
        set {
            persistedState.selectedDataMode = newValue
            saveState()
        }
    }

    var currentData: SimulationData {
        data(for: persistedState.selectedDataMode) ?? fallbackEmptyData()
    }

    var currentUser: Athlete? {
        currentData.athletes.first(where: { $0.id == currentData.currentUserAthleteId })
    }

    var unreadNotificationCount: Int {
        currentData.notifications.filter { !$0.isRead }.count
    }

    var bundledSnapshotAvailable: Bool {
        persistedState.bundledSnapshotData != nil
    }

    var sandboxSnapshotAvailable: Bool {
        persistedState.sandboxSnapshotData != nil
    }

    var importedSandboxSnapshotName: String? {
        persistedState.importedSandboxSnapshotName
    }

    func athlete(id: String) -> Athlete? {
        currentData.athletes.first(where: { $0.id == id })
    }

    func activity(id: String) -> Activity? {
        currentData.activities.first(where: { $0.id == id })
    }

    func route(id: String) -> Route? {
        currentData.routes.first(where: { $0.id == id })
    }

    func segment(id: String) -> Segment? {
        currentData.segments.first(where: { $0.id == id })
    }

    func club(id: String) -> Club? {
        currentData.clubs.first(where: { $0.id == id })
    }

    func activities(for athleteId: String) -> [Activity] {
        currentData.activities
            .filter { $0.athleteId == athleteId }
            .sorted(by: { $0.startTime > $1.startTime })
    }

    func startActivity(using routeId: String) {
        pendingRouteId = routeId
        selectedTab = .record
        transientMessage = "Loaded route into Record."
    }

    func startWorkout(_ preset: WorkoutPreset) {
        pendingWorkoutPreset = preset
        selectedTab = .record
        transientMessage = "Loaded \(preset.title) into Record."
    }

    func consumePendingRoute() -> Route? {
        guard let pendingRouteId else { return nil }
        self.pendingRouteId = nil
        return route(id: pendingRouteId)
    }

    func consumePendingWorkoutPreset() -> WorkoutPreset? {
        defer { pendingWorkoutPreset = nil }
        return pendingWorkoutPreset
    }

    func switchDataMode(_ mode: ActivityDataMode) {
        persistedState.selectedDataMode = mode
        if mode == .bundledSnapshot, persistedState.bundledSnapshotData == nil {
            lastErrorMessage = AppPersistenceError.bundledSnapshotMissing.errorDescription
        }
        if mode == .sandboxSnapshot, persistedState.sandboxSnapshotData == nil {
            lastErrorMessage = AppPersistenceError.sandboxSnapshotMissing.errorDescription
        }
        saveState()
    }

    func reloadSelectedSnapshot() {
        do {
            switch persistedState.selectedDataMode {
            case .seeded:
                transientMessage = "Default data does not need reloading."
            case .bundledSnapshot:
                let snapshot = try persistence.loadBundledSnapshot()
                persistedState.bundledSnapshotData = SeedData.mergedSnapshot(snapshot, fallback: seededTemplate)
                transientMessage = "Bundled snapshot reloaded."
            case .sandboxSnapshot:
                guard let snapshot = try persistence.loadImportedSandboxSnapshot() else {
                    throw AppPersistenceError.sandboxSnapshotMissing
                }
                persistedState.sandboxSnapshotData = SeedData.mergedSnapshot(snapshot, fallback: seededTemplate)
                transientMessage = "Sandbox snapshot reloaded."
            }
            lastErrorMessage = nil
            saveState()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func importSandboxSnapshot(from url: URL) {
        do {
            let snapshot = try persistence.importSandboxSnapshot(from: url)
            persistedState.sandboxSnapshotData = SeedData.mergedSnapshot(snapshot, fallback: seededTemplate)
            persistedState.importedSandboxSnapshotName = persistence.importedSnapshotFilename()
            persistedState.selectedDataMode = .sandboxSnapshot
            lastErrorMessage = nil
            transientMessage = "Sandbox snapshot imported."
            saveState()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func resetAppState() {
        do {
            try persistence.resetPersistence()
            persistedState = PersistedState(
                selectedTab: .feed,
                selectedDataMode: .seeded,
                seededData: seededTemplate,
                bundledSnapshotData: bundledSnapshotTemplate,
                sandboxSnapshotData: nil,
                importedSandboxSnapshotName: nil
            )
            pendingRouteId = nil
            pendingWorkoutPreset = nil
            transientMessage = "App state has been reset."
            lastErrorMessage = nil
            saveState()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func toggleKudos(for activityId: String) {
        withMutableCurrentData { data in
            guard let index = data.activities.firstIndex(where: { $0.id == activityId }) else { return }
            data.activities[index].hasCurrentUserKudo.toggle()
            data.activities[index].kudosCount += data.activities[index].hasCurrentUserKudo ? 1 : -1
            data.activities[index].kudosCount = max(0, data.activities[index].kudosCount)
            data.activities[index].lastUpdated = Date()
        }
    }

    func addComment(to activityId: String, message: String) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withMutableCurrentData { data in
            guard let index = data.activities.firstIndex(where: { $0.id == activityId }) else { return }
            let newComment = Comment(
                id: nextIdentifier(prefix: "comment", existingIds: data.activities.flatMap(\.comments).map(\.id)),
                athleteId: data.currentUserAthleteId,
                message: trimmed,
                createdAt: Date()
            )
            data.activities[index].comments.append(newComment)
            data.activities[index].lastUpdated = Date()
        }
    }

    func saveRecordedActivity(_ activity: Activity) {
        withMutableCurrentData { data in
            data.activities.insert(activity, at: 0)
        }
        selectedTab = .feed
        transientMessage = "Activity saved to Home and You."
    }

    func deleteActivity(_ activityId: String) {
        withMutableCurrentData { data in
            data.activities.removeAll(where: { $0.id == activityId })
            data.notifications.removeAll(where: { $0.relatedActivityId == activityId })
            for clubIndex in data.clubs.indices {
                data.clubs[clubIndex].activityIds.removeAll(where: { $0 == activityId })
            }
        }
        transientMessage = "Activity deleted."
    }

    func updateActivity(_ activityId: String, title: String, type: ActivityType) {
        withMutableCurrentData { data in
            guard let index = data.activities.firstIndex(where: { $0.id == activityId }) else { return }
            data.activities[index].title = title
            data.activities[index].activityType = type
            data.activities[index].lastUpdated = Date()
        }
        transientMessage = "Activity updated."
    }

    func toggleRouteSaved(_ routeId: String) {
        var isSaved = false
        withMutableCurrentData { data in
            guard let index = data.routes.firstIndex(where: { $0.id == routeId }) else { return }
            data.routes[index].isSaved.toggle()
            isSaved = data.routes[index].isSaved
        }
        transientMessage = isSaved ? "Route saved." : "Route removed from saved."
    }

    func toggleRouteBookmarked(_ routeId: String) {
        var isBookmarked = false
        withMutableCurrentData { data in
            guard let index = data.routes.firstIndex(where: { $0.id == routeId }) else { return }
            data.routes[index].isBookmarked.toggle()
            isBookmarked = data.routes[index].isBookmarked
        }
        transientMessage = isBookmarked ? "Route bookmarked." : "Route bookmark removed."
    }

    @discardableResult
    func createRoute(title: String, basedOn templateRouteId: String?, activityType: ActivityType) -> Route? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        var createdRoute: Route?

        withMutableCurrentData { data in
            let template = templateRouteId.flatMap { templateId in
                data.routes.first(where: { $0.id == templateId })
            } ?? data.routes.first

            let newRouteId = nextIdentifier(prefix: "route", existingIds: data.routes.map(\.id))
            let points = (template?.points ?? []).enumerated().map { index, point in
                RoutePoint(id: "\(newRouteId)_point_\(index + 1)", latitude: point.latitude, longitude: point.longitude)
            }

            let route = Route(
                id: newRouteId,
                name: trimmedTitle,
                distanceKilometers: template?.distanceKilometers ?? 8.0,
                elevationGainMeters: template?.elevationGainMeters ?? 120,
                estimatedTimeSeconds: template?.estimatedTimeSeconds ?? 3000,
                popularityScore: template?.popularityScore ?? 78,
                startLocation: template?.startLocation ?? BenchmarkLocation.currentLocationLabel,
                points: points.isEmpty ? BenchmarkLocation.fallbackRoutePoints(routeId: newRouteId) : points,
                elevationProfile: template?.elevationProfile ?? [12, 18, 26, 33, 24, 14],
                segmentIds: template?.segmentIds ?? [],
                isSaved: true,
                isBookmarked: true,
                recommendedActivityType: activityType
            )

            data.routes.insert(route, at: 0)

            let notification = Notification(
                id: nextIdentifier(prefix: "notification", existingIds: data.notifications.map(\.id)),
                kind: .challenge,
                title: "Route saved",
                body: "\"\(trimmedTitle)\" was added to your saved routes.",
                createdAt: Date(),
                isRead: false,
                relatedActivityId: nil,
                relatedClubId: nil
            )
            data.notifications.insert(notification, at: 0)
            createdRoute = route
        }

        if createdRoute != nil {
            transientMessage = "Saved route created."
        }

        return createdRoute
    }

    func toggleClubMembership(_ clubId: String) {
        var joinedClubName = "Club"
        var isJoined = false
        withMutableCurrentData { data in
            guard let clubIndex = data.clubs.firstIndex(where: { $0.id == clubId }) else { return }
            data.clubs[clubIndex].isJoined.toggle()
            joinedClubName = data.clubs[clubIndex].name
            isJoined = data.clubs[clubIndex].isJoined

            if data.clubs[clubIndex].isJoined {
                data.clubs[clubIndex].memberCount += 1
                let newMember = ClubMember(
                    id: nextIdentifier(prefix: "clubmember", existingIds: data.clubs.flatMap(\.members).map(\.id)),
                    athleteId: data.currentUserAthleteId,
                    weeklyDistanceKilometers: 21.3,
                    isAdmin: false
                )
                data.clubs[clubIndex].members.append(newMember)
            } else {
                data.clubs[clubIndex].memberCount = max(0, data.clubs[clubIndex].memberCount - 1)
                data.clubs[clubIndex].members.removeAll(where: { $0.athleteId == data.currentUserAthleteId })
            }
        }
        transientMessage = isJoined ? "Joined \(joinedClubName)." : "Left \(joinedClubName)."
    }

    func markNotificationRead(_ notificationId: String) {
        withMutableCurrentData { data in
            guard let index = data.notifications.firstIndex(where: { $0.id == notificationId }) else { return }
            data.notifications[index].isRead = true
        }
    }

    func markAllNotificationsRead() {
        withMutableCurrentData { data in
            for index in data.notifications.indices {
                data.notifications[index].isRead = true
            }
        }
        transientMessage = "All notifications marked read."
    }

    private func data(for mode: ActivityDataMode) -> SimulationData? {
        switch mode {
        case .seeded:
            return persistedState.seededData
        case .bundledSnapshot:
            return persistedState.bundledSnapshotData
        case .sandboxSnapshot:
            return persistedState.sandboxSnapshotData
        }
    }

    private func fallbackEmptyData() -> SimulationData {
        SimulationData.empty(currentUserAthleteId: seededTemplate.currentUserAthleteId)
    }

    private func withMutableCurrentData(_ mutate: (inout SimulationData) -> Void) {
        switch persistedState.selectedDataMode {
        case .seeded:
            mutate(&persistedState.seededData)
            normalize(&persistedState.seededData)
        case .bundledSnapshot:
            var data = persistedState.bundledSnapshotData ?? bundledSnapshotTemplate ?? fallbackEmptyData()
            mutate(&data)
            normalize(&data)
            persistedState.bundledSnapshotData = data
        case .sandboxSnapshot:
            var data = persistedState.sandboxSnapshotData ?? fallbackEmptyData()
            mutate(&data)
            normalize(&data)
            persistedState.sandboxSnapshotData = data
        }
        saveState()
    }

    private func normalize(_ data: inout SimulationData) {
        data.activities.sort(by: { $0.startTime > $1.startTime })
        data.notifications.sort(by: { $0.createdAt > $1.createdAt })
        for index in data.activities.indices {
            data.activities[index].comments.sort(by: { $0.createdAt < $1.createdAt })
        }
    }

    private func saveState() {
        do {
            try persistence.saveState(persistedState)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func nextIdentifier(prefix: String, existingIds: [String]) -> String {
        let maxValue = existingIds
            .compactMap { id -> Int? in
                guard let suffix = id.components(separatedBy: "_").last else { return nil }
                return Int(suffix)
            }
            .max() ?? 0
        return "\(prefix)_\(String(format: "%03d", maxValue + 1))"
    }
}
