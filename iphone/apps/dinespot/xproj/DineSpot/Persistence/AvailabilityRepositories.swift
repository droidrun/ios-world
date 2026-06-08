import Foundation

protocol AvailabilityRepository {
    var sourceType: AvailabilitySourceType { get }
    var sourceLabel: String { get }
    var metadata: AvailabilitySnapshotMetadata? { get }
    func loadAvailability() -> [RestaurantAvailability]
}

struct SeededAvailabilityRepository: AvailabilityRepository {
    let restaurants: [Restaurant]

    var sourceType: AvailabilitySourceType { .seeded }
    var sourceLabel: String { "Standard Data" }
    var metadata: AvailabilitySnapshotMetadata? { nil }

    func loadAvailability() -> [RestaurantAvailability] {
        SeedData.seededAvailability(for: restaurants)
    }
}

struct SnapshotAvailabilityRepository: AvailabilityRepository {
    let snapshot: AvailabilitySnapshot
    let labelSuffix: String

    var sourceType: AvailabilitySourceType { .snapshot }
    var sourceLabel: String { "Snapshot Availability Data\(labelSuffix)" }
    var metadata: AvailabilitySnapshotMetadata? { snapshot.metadata }

    func loadAvailability() -> [RestaurantAvailability] {
        snapshot.availability
    }
}

enum SnapshotLoadError: LocalizedError {
    case bundledSnapshotMissing
    case bundledSnapshotUnreadable
    case sandboxSnapshotMissing
    case sandboxSnapshotUnreadable

    var errorDescription: String? {
        switch self {
        case .bundledSnapshotMissing:
            return "Bundled snapshot data unavailable"
        case .bundledSnapshotUnreadable:
            return "Bundled snapshot could not be decoded"
        case .sandboxSnapshotMissing:
            return "Sandbox snapshot file unavailable"
        case .sandboxSnapshotUnreadable:
            return "Sandbox snapshot could not be decoded"
        }
    }
}

struct SnapshotAvailabilityLoader {
    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func sandboxURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return documents.appendingPathComponent("availability_snapshot.json")
    }

    func loadBundledSnapshot() throws -> AvailabilitySnapshot {
        guard let url = Bundle.main.url(forResource: "availability_snapshot", withExtension: "json") else {
            throw SnapshotLoadError.bundledSnapshotMissing
        }
        guard let data = try? Data(contentsOf: url) else {
            throw SnapshotLoadError.bundledSnapshotUnreadable
        }
        guard let snapshot = try? decoder().decode(AvailabilitySnapshot.self, from: data) else {
            throw SnapshotLoadError.bundledSnapshotUnreadable
        }
        return snapshot
    }

    func loadSandboxSnapshot() throws -> AvailabilitySnapshot {
        let url = sandboxURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SnapshotLoadError.sandboxSnapshotMissing
        }
        guard let data = try? Data(contentsOf: url) else {
            throw SnapshotLoadError.sandboxSnapshotUnreadable
        }
        guard let snapshot = try? decoder().decode(AvailabilitySnapshot.self, from: data) else {
            throw SnapshotLoadError.sandboxSnapshotUnreadable
        }
        return snapshot
    }

    func loadPreferredSnapshot() throws -> (snapshot: AvailabilitySnapshot, suffix: String) {
        if let sandbox = try? loadSandboxSnapshot() {
            return (sandbox, " (Sandbox)")
        }
        let bundled = try loadBundledSnapshot()
        return (bundled, " (Bundled)")
    }

    func sandboxSnapshotPath() -> String {
        sandboxURL().path
    }
}
