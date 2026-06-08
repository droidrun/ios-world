import Foundation

/// Fetches full-season schedules for Bay Area teams from the public sports data API
/// and converts them into SeatGeek `Event` objects with generated ticket listings.
final class LiveSportsService {

    // MARK: - Bay Area Team Configuration

    private struct TeamConfig {
        let name: String
        let sportSlug: String
        let leagueSlug: String
        let espnTeamID: String
        let venueUUIDSeed: Int
        let city: String
        let sectionPool: [String]
        let priceRange: ClosedRange<Int>
        let listingCount: Int
        let imageName: String
    }

    private static let bayAreaTeams: [TeamConfig] = [
        TeamConfig(
            name: "Golden State Warriors",
            sportSlug: "basketball",
            leagueSlug: "nba",
            espnTeamID: "9",
            venueUUIDSeed: 1000,   // Chase Center
            city: "San Francisco",
            sectionPool: ["106", "107", "109", "112", "118", "210", "214", "219"],
            priceRange: 45...320,
            listingCount: 30,
            imageName: "featured_warriors"
        ),
        TeamConfig(
            name: "San Francisco Giants",
            sportSlug: "baseball",
            leagueSlug: "mlb",
            espnTeamID: "26",
            venueUUIDSeed: 1002,   // Oracle Park
            city: "San Francisco",
            sectionPool: ["101", "109", "115", "122", "130", "202", "208", "221", "LB", "VR", "Bleachers"],
            priceRange: 28...260,
            listingCount: 25,
            imageName: "oracle_baseball"
        ),
        TeamConfig(
            name: "San Jose Sharks",
            sportSlug: "hockey",
            leagueSlug: "nhl",
            espnTeamID: "18",
            venueUUIDSeed: 1001,   // SAP Center
            city: "San Jose",
            sectionPool: ["101", "103", "106", "110", "114", "118", "120", "124", "126", "203", "214", "215", "216", "217", "220", "221", "224", "225", "228"],
            priceRange: 25...200,
            listingCount: 25,
            imageName: "sharks_map"
        ),
        TeamConfig(
            name: "San Francisco 49ers",
            sportSlug: "football",
            leagueSlug: "nfl",
            espnTeamID: "25",
            venueUUIDSeed: 1009,   // Levi's Stadium
            city: "Santa Clara",
            sectionPool: ["101", "108", "115", "122", "130", "210", "218", "225", "301", "310", "320"],
            priceRange: 85...550,
            listingCount: 35,
            imageName: "levis_stadium"
        )
    ]

    // MARK: - Public API

    private static let baseURL = URL(string: "https://site.api.espn.com/apis/site/v2/sports/")!

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 15
        self.session = URLSession(configuration: config)
    }

    /// Fetches full-season home schedules for all Bay Area teams concurrently,
    /// then maps the results to SeatGeek `Event` objects.
    func fetchSeasonEvents(
        performers: [Performer],
        venues: [Venue]
    ) async -> [Event] {
        let venueByUUID = Dictionary(uniqueKeysWithValues: venues.map { ($0.id, $0) })
        let performerByName = Dictionary(
            performers.filter { $0.category == .sports }.map { (normalizedTeamKey($0.name), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return await withTaskGroup(of: [Event].self) { group in
            for teamConfig in Self.bayAreaTeams {
                group.addTask { [self] in
                    await self.fetchTeamSchedule(
                        config: teamConfig,
                        venueByUUID: venueByUUID,
                        performerByName: performerByName
                    )
                }
            }

            var allEvents: [Event] = []
            for await teamEvents in group {
                allEvents.append(contentsOf: teamEvents)
            }
            return allEvents.sorted { $0.date < $1.date }
        }
    }

    // MARK: - Per-Team Fetch & Parse

    private func fetchTeamSchedule(
        config: TeamConfig,
        venueByUUID: [UUID: Venue],
        performerByName: [String: Performer]
    ) async -> [Event] {
        let path = "\(config.sportSlug)/\(config.leagueSlug)/teams/\(config.espnTeamID)/schedule"
        guard let url = URL(string: path, relativeTo: Self.baseURL) else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("[LiveSports] Bad status for \(config.name)")
                return []
            }

            let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            guard let json = object as? [String: Any] else { return [] }

            return parseSchedule(json: json, config: config, venueByUUID: venueByUUID, performerByName: performerByName)
        } catch {
            print("[LiveSports] Fetch failed for \(config.name): \(error.localizedDescription)")
            return []
        }
    }

    private func parseSchedule(
        json: [String: Any],
        config: TeamConfig,
        venueByUUID: [UUID: Venue],
        performerByName: [String: Performer]
    ) -> [Event] {
        guard let events = json["events"] as? [[String: Any]] else { return [] }

        let venueUUID = stableUUID(config.venueUUIDSeed)

        return events.compactMap { event -> Event? in
            guard let competition = (event["competitions"] as? [[String: Any]])?.first,
                  let competitors = competition["competitors"] as? [[String: Any]],
                  let homeCompetitor = competitors.first(where: { ($0["homeAway"] as? String) == "home" }),
                  let awayCompetitor = competitors.first(where: { ($0["homeAway"] as? String) == "away" })
            else { return nil }

            // Only include home games for this team
            let homeTeamDict = homeCompetitor["team"] as? [String: Any] ?? [:]
            let homeTeamID = homeTeamDict["id"] as? String
            guard homeTeamID == config.espnTeamID else { return nil }

            // Parse date
            guard let dateString = event["date"] as? String,
                  let startDate = parseISO8601(dateString)
            else { return nil }

            // Extract team names
            let awayTeamDict = awayCompetitor["team"] as? [String: Any] ?? [:]
            let awayName = (awayTeamDict["displayName"] as? String) ?? "Opponent"
            let homeName = (homeTeamDict["displayName"] as? String) ?? config.name

            // Build title
            let title = "\(awayName) at \(homeName)"

            // Resolve performers
            let homePerformer = resolvePerformer(name: homeName, existing: performerByName)
            let awayPerformer = resolvePerformer(name: awayName, existing: performerByName)

            // Stable event ID derived from source event ID
            let espnEventID = (event["id"] as? String) ?? "\(config.espnTeamID)_\(dateString)"
            let eventUUID = deterministicUUID(from: "seatgeek_\(espnEventID)")

            // Parse venue name for description
            let venueName = ((competition["venue"] as? [String: Any])?["fullName"] as? String)
                ?? venueByUUID[venueUUID]?.name
                ?? "Venue"

            let description = "\(awayName) vs \(homeName) at \(venueName)."

            // Generate listings with a deterministic seed derived from the source event ID
            // (Swift's .hashValue is randomized per process, so use our own stable hash)
            let listingSeed = stableHash(espnEventID) % 900000 + 100000
            let listings = SeedData.makeListings(
                eventID: eventUUID,
                eventSeed: listingSeed,
                count: config.listingCount,
                category: .sports,
                sectionPool: config.sectionPool,
                priceRange: config.priceRange
            )

            return Event(
                id: eventUUID,
                title: title,
                date: startDate,
                venueID: venueUUID,
                city: config.city,
                category: .sports,
                performers: [awayPerformer, homePerformer],
                imageName: config.imageName,
                description: description,
                listings: listings
            )
        }
    }

    // MARK: - Performer Resolution

    private func resolvePerformer(name: String, existing: [String: Performer]) -> Performer {
        let key = normalizedTeamKey(name)
        if let match = existing[key] {
            return match
        }
        // Create a dynamic performer for teams not in the seeded list
        return Performer(
            id: deterministicUUID(from: "performer_\(key)"),
            name: name,
            category: .sports,
            imageName: "sports_generic",
            eventCount: 0
        )
    }

    private func normalizedTeamKey(_ name: String) -> String {
        name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helpers

    /// Deterministic hash that doesn't change across process launches (unlike Swift's .hashValue).
    private func stableHash(_ string: String) -> Int {
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(byte)
        }
        return Int(hash & 0x7FFFFFFF)
    }

    private func stableUUID(_ seed: Int) -> UUID {
        let hex = String(format: "%012x", seed)
        return UUID(uuidString: "00000000-0000-0000-0000-\(hex)") ?? UUID()
    }

    private func deterministicUUID(from string: String) -> UUID {
        // Use a simple hash-based approach for reproducible UUIDs
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(byte)
        }
        let a = UInt32(hash & 0xFFFFFFFF)
        let b = UInt32((hash >> 32) & 0xFFFFFFFF)
        let hex = String(format: "%08x-%04x-%04x-%04x-%08x%04x",
                         a,
                         UInt16(b & 0xFFFF),
                         UInt16(0x4000 | (b >> 16) & 0x0FFF),   // version 4
                         UInt16(0x8000 | (a >> 16) & 0x3FFF),   // variant 1
                         b,
                         UInt16(a & 0xFFFF))
        return UUID(uuidString: hex) ?? UUID()
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601FallbackFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private func parseISO8601(_ string: String) -> Date? {
        Self.iso8601Formatter.date(from: string)
            ?? Self.iso8601FallbackFormatter.date(from: string)
    }
}
