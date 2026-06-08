import Foundation

protocol FareRepository {
    var sourceType: FareSourceType { get }
    func search(criteria: FlightSearchCriteria) -> [FlightItinerary]
}

struct SeededFareRepository: FareRepository {
    let sourceType: FareSourceType = .seeded
    private let itineraries: [FlightItinerary]

    init(itineraries: [FlightItinerary]) {
        self.itineraries = itineraries
    }

    func search(criteria: FlightSearchCriteria) -> [FlightItinerary] {
        // For seeded data: match route + trip type + nonstop only.
        // Cabin and date are NOT filtered here so searches always return results.
        // Dates are shifted to match the search criteria.
        let matched = itineraries.filter { itinerary in
            itinerary.origin.code == criteria.originCode.uppercased() &&
            itinerary.destination.code == criteria.destinationCode.uppercased() &&
            itinerary.tripType == criteria.tripType &&
            (!criteria.nonstopOnly || itinerary.totalStops == 0)
        }
        return matched.map { Self.shiftToSearchDate($0, departure: criteria.departureDate, returnDate: criteria.returnDate) }
    }

    private static func shiftToSearchDate(_ itinerary: FlightItinerary, departure: Date, returnDate: Date?) -> FlightItinerary {
        let calendar = Calendar(identifier: .gregorian)
        guard let firstDeparture = itinerary.outboundSegments.first?.departureTime else { return itinerary }

        let dayDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstDeparture), to: calendar.startOfDay(for: departure)).day ?? 0
        guard dayDiff != 0 || returnDate != nil else { return itinerary }

        let shiftedOutbound = itinerary.outboundSegments.map { seg in
            FlightSegment(
                id: seg.id, carrierCode: seg.carrierCode, flightNumber: seg.flightNumber,
                origin: seg.origin, destination: seg.destination,
                departureTime: calendar.date(byAdding: .day, value: dayDiff, to: seg.departureTime) ?? seg.departureTime,
                arrivalTime: calendar.date(byAdding: .day, value: dayDiff, to: seg.arrivalTime) ?? seg.arrivalTime,
                durationMinutes: seg.durationMinutes, terminal: seg.terminal, gate: seg.gate,
                stops: seg.stops, status: seg.status
            )
        }

        var shiftedReturn: [FlightSegment] = itinerary.returnSegments
        if let returnDate, let firstReturn = itinerary.returnSegments.first?.departureTime {
            let returnDayDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstReturn), to: calendar.startOfDay(for: returnDate)).day ?? 0
            shiftedReturn = itinerary.returnSegments.map { seg in
                FlightSegment(
                    id: seg.id, carrierCode: seg.carrierCode, flightNumber: seg.flightNumber,
                    origin: seg.origin, destination: seg.destination,
                    departureTime: calendar.date(byAdding: .day, value: returnDayDiff, to: seg.departureTime) ?? seg.departureTime,
                    arrivalTime: calendar.date(byAdding: .day, value: returnDayDiff, to: seg.arrivalTime) ?? seg.arrivalTime,
                    durationMinutes: seg.durationMinutes, terminal: seg.terminal, gate: seg.gate,
                    stops: seg.stops, status: seg.status
                )
            }
        }

        return FlightItinerary(
            id: itinerary.id, tripType: itinerary.tripType,
            origin: itinerary.origin, destination: itinerary.destination,
            outboundSegments: shiftedOutbound, returnSegments: shiftedReturn,
            fare: itinerary.fare, badges: itinerary.badges, sourceType: itinerary.sourceType
        )
    }
}

struct SnapshotLoadResult {
    let metadata: FareSnapshotMetadata
    let itineraries: [FlightItinerary]
    let sourceURL: URL
}

struct SnapshotLoader {
    static let sandboxFileName = "fare_snapshot.json"

    var sandboxURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(Self.sandboxFileName) ?? URL(fileURLWithPath: "/tmp/fare_snapshot.json")
    }

    func bundledURL() -> URL? {
        if let direct = Bundle.main.url(forResource: "fare_snapshot", withExtension: "json") {
            return direct
        }
        return Bundle.main.url(forResource: "fare_snapshot", withExtension: "json", subdirectory: "Resources")
    }

    func activeSnapshotURL() -> URL? {
        if FileManager.default.fileExists(atPath: sandboxURL.path) {
            return sandboxURL
        }
        return bundledURL()
    }

    func loadSnapshot() throws -> SnapshotLoadResult {
        guard let url = activeSnapshotURL() else {
            throw NSError(domain: "SnapshotLoader", code: 404, userInfo: [NSLocalizedDescriptionKey: "snapshot data unavailable"])
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FareSnapshotFile.self, from: data)
        let stamped = decoded.itineraries.map { itinerary in
            FlightItinerary(
                id: itinerary.id,
                tripType: itinerary.tripType,
                origin: itinerary.origin,
                destination: itinerary.destination,
                outboundSegments: itinerary.outboundSegments,
                returnSegments: itinerary.returnSegments,
                fare: itinerary.fare,
                badges: itinerary.badges,
                sourceType: .snapshot
            )
        }

        return SnapshotLoadResult(metadata: decoded.metadata, itineraries: stamped, sourceURL: url)
    }

    func reloadBundledSnapshotToSandbox() throws {
        guard let bundled = bundledURL() else {
            throw NSError(domain: "SnapshotLoader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bundled snapshot data unavailable"])
        }

        let destination = sandboxURL
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: bundled, to: destination)
    }

    func clearSandboxSnapshot() {
        if FileManager.default.fileExists(atPath: sandboxURL.path) {
            try? FileManager.default.removeItem(at: sandboxURL)
        }
    }
}

final class SnapshotFareRepository: FareRepository {
    let sourceType: FareSourceType = .snapshot

    private let loader: SnapshotLoader
    private(set) var lastMetadata: FareSnapshotMetadata?
    private(set) var lastSourceURL: URL?
    private(set) var lastErrorMessage: String?

    init(loader: SnapshotLoader = SnapshotLoader()) {
        self.loader = loader
    }

    func search(criteria: FlightSearchCriteria) -> [FlightItinerary] {
        do {
            let snapshot = try loader.loadSnapshot()
            lastMetadata = snapshot.metadata
            lastSourceURL = snapshot.sourceURL
            lastErrorMessage = nil
            return snapshot.itineraries.filter { FareSearchMatcher.matches(itinerary: $0, criteria: criteria) }
        } catch {
            lastErrorMessage = error.localizedDescription
            return []
        }
    }

    func previewSnapshotStatus() -> (metadata: FareSnapshotMetadata?, sourceURL: URL?, error: String?) {
        do {
            let snapshot = try loader.loadSnapshot()
            lastMetadata = snapshot.metadata
            lastSourceURL = snapshot.sourceURL
            lastErrorMessage = nil
            return (snapshot.metadata, snapshot.sourceURL, nil)
        } catch {
            lastErrorMessage = error.localizedDescription
            return (nil, nil, error.localizedDescription)
        }
    }

    func reloadBundledSnapshot() -> Result<Void, Error> {
        do {
            try loader.reloadBundledSnapshotToSandbox()
            _ = previewSnapshotStatus()
            return .success(())
        } catch {
            lastErrorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    func sandboxPath() -> String {
        loader.sandboxURL.path
    }

    func clearSandboxSnapshot() {
        loader.clearSandboxSnapshot()
    }
}

struct FareSearchMatcher {
    static func matches(itinerary: FlightItinerary, criteria: FlightSearchCriteria) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let routeMatches = itinerary.origin.code == criteria.originCode.uppercased() &&
            itinerary.destination.code == criteria.destinationCode.uppercased()
        let tripTypeMatches = itinerary.tripType == criteria.tripType
        let cabinMatches = itinerary.fare.cabin == criteria.cabin
        let departureMatches = calendar.isDate(itinerary.departureTime, inSameDayAs: criteria.departureDate)

        var returnMatches = true
        if criteria.tripType == .roundTrip,
           let returnDate = criteria.returnDate,
           let itineraryReturn = itinerary.returnSegments.first?.departureTime {
            returnMatches = calendar.isDate(itineraryReturn, inSameDayAs: returnDate)
        }

        let nonstopMatches = !criteria.nonstopOnly || itinerary.totalStops == 0

        return routeMatches && tripTypeMatches && cabinMatches && departureMatches && returnMatches && nonstopMatches
    }
}
