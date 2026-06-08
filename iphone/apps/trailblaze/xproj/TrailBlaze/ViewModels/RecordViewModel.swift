import Foundation

@MainActor
final class RecordViewModel: ObservableObject {
    enum RecordingPhase {
        case idle
        case recording
        case paused
        case review
    }

    @Published var selectedActivityType: ActivityType = .run
    @Published var selectedRoute: Route?
    @Published var reviewTitle: String = "Morning Workout"
    @Published private(set) var phase: RecordingPhase = .idle
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var distanceKilometers: Double = 0
    @Published private(set) var elevationGainMeters: Double = 0

    private var timer: Timer?

    deinit {
        timer?.invalidate()
    }

    var isRecording: Bool { phase == .recording }
    var isPaused: Bool { phase == .paused }
    var isReviewing: Bool { phase == .review }

    var calories: Int {
        let minutes = Double(elapsedSeconds) / 60
        return Int(minutes * Double(selectedActivityType.caloriesPerMinute))
    }

    var averagePaceSecondsPerKilometer: Int {
        guard distanceKilometers > 0 else { return 0 }
        return Int((Double(elapsedSeconds) / distanceKilometers).rounded())
    }

    var splits: [ActivitySplit] {
        let splitDistance = selectedActivityType == .ride || selectedActivityType == .indoorRide ? 5.0 : 1.0
        let splitCount = max(Int(ceil(distanceKilometers / splitDistance)), distanceKilometers > 0 ? 1 : 0)
        guard splitCount > 0 else { return [] }

        let baseDuration = elapsedSeconds / splitCount
        let remainder = elapsedSeconds % splitCount

        return (0..<splitCount).map { index in
            let remainingDistance = distanceKilometers - (Double(index) * splitDistance)
            return ActivitySplit(
                id: "record_split_\(index + 1)",
                index: index + 1,
                distanceKilometers: min(splitDistance, max(remainingDistance, 0.1)),
                durationSeconds: baseDuration + (index < remainder ? 1 : 0)
            )
        }
    }

    func applyRoute(_ route: Route?) {
        guard phase == .idle || phase == .review else { return }
        selectedRoute = route
        if let route {
            selectedActivityType = route.recommendedActivityType
            reviewTitle = route.name
        }
    }

    func applyWorkoutPreset(_ preset: WorkoutPreset?) {
        guard phase == .idle || phase == .review else { return }
        guard let preset else { return }
        selectedActivityType = preset.activityType
        reviewTitle = preset.title
        if selectedRoute?.recommendedActivityType != preset.activityType {
            selectedRoute = nil
        }
    }

    func start() {
        if elapsedSeconds == 0 {
            phase = .recording
            reviewTitle = selectedRoute?.name ?? "\(selectedActivityType.title) Workout"
        } else {
            phase = .recording
        }
        startTimer()
    }

    func pause() {
        timer?.invalidate()
        phase = .paused
    }

    func resume() {
        phase = .recording
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        phase = .review
        if reviewTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reviewTitle = selectedRoute?.name ?? "\(selectedActivityType.title) Workout"
        }
    }

    func discard() {
        reset()
    }

    func reset() {
        timer?.invalidate()
        elapsedSeconds = 0
        distanceKilometers = 0
        elevationGainMeters = 0
        phase = .idle
        reviewTitle = selectedRoute?.name ?? "\(selectedActivityType.title) Workout"
    }

    func makeActivity(currentUserAthleteId: String) -> Activity {
        let now = Date()
        let identifier = "activity_\(Int(now.timeIntervalSince1970))"

        return Activity(
            id: identifier,
            athleteId: currentUserAthleteId,
            title: reviewTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(selectedActivityType.title) Workout" : reviewTitle,
            distanceKilometers: distanceKilometers,
            durationSeconds: elapsedSeconds,
            elevationGainMeters: elevationGainMeters,
            avgPaceSecondsPerKilometer: max(averagePaceSecondsPerKilometer, 1),
            startTime: now,
            activityType: selectedActivityType,
            routeId: selectedRoute?.id,
            segmentResults: (selectedRoute?.segmentIds ?? []).enumerated().map { index, segmentId in
                SegmentResult(
                    id: "\(identifier)_segment_\(index + 1)",
                    segmentId: segmentId,
                    timeSeconds: max(90, Int(Double(elapsedSeconds) * (0.06 + Double(index) * 0.03))),
                    rank: index + 4
                )
            },
            kudosCount: 0,
            hasCurrentUserKudo: false,
            comments: [],
            sourceType: .personal,
            clubId: nil,
            calories: calories,
            splits: splits.enumerated().map { offset, split in
                ActivitySplit(
                    id: "\(identifier)_split_\(offset + 1)",
                    index: split.index,
                    distanceKilometers: split.distanceKilometers,
                    durationSeconds: split.durationSeconds
                )
            },
            lastUpdated: now
        )
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        elapsedSeconds += 1

        let routeAdjustment = selectedRoute == nil ? 1.0 : 0.94
        let kilometersPerSecond = (selectedActivityType.defaultSpeedKilometersPerHour * routeAdjustment) / 3600
        distanceKilometers += kilometersPerSecond

        let elevationPerSecond: Double
        if let selectedRoute, selectedRoute.estimatedTimeSeconds > 0 {
            elevationPerSecond = selectedRoute.elevationGainMeters / Double(selectedRoute.estimatedTimeSeconds)
        } else {
            switch selectedActivityType {
            case .run: elevationPerSecond = 0.11
            case .ride: elevationPerSecond = 0.18
            case .walk: elevationPerSecond = 0.03
            case .hike: elevationPerSecond = 0.08
            case .indoorRide: elevationPerSecond = 0
            }
        }
        elevationGainMeters += elevationPerSecond
    }
}
