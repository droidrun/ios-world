import Foundation

protocol FareRepository {
    var sourceType: FareSourceType { get }
    func estimates(pickup: LocationPlace, destination: LocationPlace) -> [RouteEstimate]
    func metadata() -> FareSnapshotMetadata?
}

final class SeededFareRepository: FareRepository {
    var sourceType: FareSourceType { .seeded }

    func estimates(pickup: LocationPlace, destination: LocationPlace) -> [RouteEstimate] {
        SeedData.routeEstimates(pickup: pickup, destination: destination, sourceType: .seeded, lastUpdated: Date())
    }

    func metadata() -> FareSnapshotMetadata? {
        nil
    }
}

struct SnapshotPayload: Codable {
    var metadata: FareSnapshotMetadata
    var routeEstimates: [RouteEstimate]
}

final class SnapshotFareRepository: FareRepository {
    var sourceType: FareSourceType { .snapshot }

    private let persistence: AppPersistence
    private(set) var payload: SnapshotPayload?
    private(set) var lastErrorMessage: String?

    init(persistence: AppPersistence) {
        self.persistence = persistence
    }

    func estimates(pickup: LocationPlace, destination: LocationPlace) -> [RouteEstimate] {
        guard let payload else {
            return []
        }

        return payload.routeEstimates.filter {
            $0.pickupName.caseInsensitiveCompare(pickup.displayName) == .orderedSame &&
            $0.destinationName.caseInsensitiveCompare(destination.displayName) == .orderedSame
        }
    }

    func metadata() -> FareSnapshotMetadata? {
        payload?.metadata
    }

    @discardableResult
    func load(location: SnapshotLocation) -> Bool {
        switch location {
        case .bundled:
            guard let url = Bundle.main.url(forResource: "fare_snapshot", withExtension: "json") else {
                payload = nil
                lastErrorMessage = "fare data unavailable"
                return false
            }
            do {
                let data = try Data(contentsOf: url)
                let decoded = try decodeSnapshot(data)
                payload = decoded
                lastErrorMessage = nil
                return true
            } catch {
                payload = nil
                lastErrorMessage = "fare data unavailable"
                return false
            }

        case .sandbox:
            guard let data = persistence.readSandboxSnapshotData() else {
                payload = nil
                lastErrorMessage = "fare data unavailable"
                return false
            }
            do {
                let decoded = try decodeSnapshot(data)
                payload = decoded
                lastErrorMessage = nil
                return true
            } catch {
                payload = nil
                lastErrorMessage = "fare data unavailable"
                return false
            }
        }
    }

    @discardableResult
    func copyBundledSnapshotToSandbox() -> Bool {
        guard let url = Bundle.main.url(forResource: "fare_snapshot", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return false
        }

        do {
            try persistence.writeSandboxSnapshotData(data)
            return true
        } catch {
            return false
        }
    }

    private func decodeSnapshot(_ data: Data) throws -> SnapshotPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SnapshotPayload.self, from: data)
    }
}
