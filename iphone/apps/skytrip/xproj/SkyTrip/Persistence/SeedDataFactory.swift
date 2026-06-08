import Foundation

enum SeedDataFactory {
    static let airports: [Airport] = [
        Airport(id: "ATL", code: "ATL", city: "Atlanta", name: "Hartsfield-Jackson Atlanta International Airport", state: "GA"),
        Airport(id: "JFK", code: "JFK", city: "New York", name: "John F. Kennedy International Airport", state: "NY"),
        Airport(id: "LGA", code: "LGA", city: "New York", name: "LaGuardia Airport", state: "NY"),
        Airport(id: "LAX", code: "LAX", city: "Los Angeles", name: "Los Angeles International Airport", state: "CA"),
        Airport(id: "SFO", code: "SFO", city: "San Francisco", name: "San Francisco International Airport", state: "CA"),
        Airport(id: "SEA", code: "SEA", city: "Seattle", name: "Seattle-Tacoma International Airport", state: "WA"),
        Airport(id: "BOS", code: "BOS", city: "Boston", name: "Boston Logan International Airport", state: "MA"),
        Airport(id: "ORD", code: "ORD", city: "Chicago", name: "Chicago O'Hare International Airport", state: "IL"),
        Airport(id: "DCA", code: "DCA", city: "Washington", name: "Ronald Reagan Washington National Airport", state: "DC"),
        Airport(id: "MIA", code: "MIA", city: "Miami", name: "Miami International Airport", state: "FL"),
        Airport(id: "DFW", code: "DFW", city: "Dallas", name: "Dallas/Fort Worth International Airport", state: "TX"),
        Airport(id: "DEN", code: "DEN", city: "Denver", name: "Denver International Airport", state: "CO"),
        Airport(id: "LAS", code: "LAS", city: "Las Vegas", name: "Harry Reid International Airport", state: "NV"),
        Airport(id: "MSP", code: "MSP", city: "Minneapolis", name: "Minneapolis-Saint Paul International Airport", state: "MN"),
        Airport(id: "DTW", code: "DTW", city: "Detroit", name: "Detroit Metropolitan Wayne County Airport", state: "MI"),
        Airport(id: "SLC", code: "SLC", city: "Salt Lake City", name: "Salt Lake City International Airport", state: "UT"),
        Airport(id: "PIT", code: "PIT", city: "Pittsburgh", name: "Pittsburgh International Airport", state: "PA"),
        Airport(id: "MCO", code: "MCO", city: "Orlando", name: "Orlando International Airport", state: "FL"),
        Airport(id: "PHX", code: "PHX", city: "Phoenix", name: "Phoenix Sky Harbor International Airport", state: "AZ"),
        Airport(id: "MSY", code: "MSY", city: "New Orleans", name: "Louis Armstrong New Orleans International Airport", state: "LA"),
        Airport(id: "EWR", code: "EWR", city: "Newark", name: "Newark Liberty International Airport", state: "NJ"),
        Airport(id: "SAN", code: "SAN", city: "San Diego", name: "San Diego International Airport", state: "CA"),
        Airport(id: "TPA", code: "TPA", city: "Tampa", name: "Tampa International Airport", state: "FL"),
        Airport(id: "AUS", code: "AUS", city: "Austin", name: "Austin-Bergstrom International Airport", state: "TX"),
        Airport(id: "BNA", code: "BNA", city: "Nashville", name: "Nashville International Airport", state: "TN"),
        Airport(id: "RDU", code: "RDU", city: "Raleigh", name: "Raleigh-Durham International Airport", state: "NC"),
        Airport(id: "HNL", code: "HNL", city: "Honolulu", name: "Daniel K. Inouye International Airport", state: "HI"),

        // ── International ───────────────────────────────────────────
        Airport(id: "LHR", code: "LHR", city: "London", name: "London Heathrow Airport", state: "UK"),
        Airport(id: "CDG", code: "CDG", city: "Paris", name: "Paris Charles de Gaulle Airport", state: "France"),
        Airport(id: "AMS", code: "AMS", city: "Amsterdam", name: "Amsterdam Schiphol Airport", state: "Netherlands"),
        Airport(id: "FCO", code: "FCO", city: "Rome", name: "Leonardo da Vinci–Fiumicino Airport", state: "Italy"),
        Airport(id: "NRT", code: "NRT", city: "Tokyo", name: "Narita International Airport", state: "Japan"),
        Airport(id: "ICN", code: "ICN", city: "Seoul", name: "Incheon International Airport", state: "South Korea"),
        Airport(id: "CUN", code: "CUN", city: "Cancun", name: "Cancun International Airport", state: "Mexico"),
        Airport(id: "MEX", code: "MEX", city: "Mexico City", name: "Mexico City International Airport", state: "Mexico"),
        Airport(id: "GRU", code: "GRU", city: "Sao Paulo", name: "Sao Paulo/Guarulhos International Airport", state: "Brazil"),
        Airport(id: "YYZ", code: "YYZ", city: "Toronto", name: "Toronto Pearson International Airport", state: "Canada"),
        Airport(id: "BOG", code: "BOG", city: "Bogota", name: "El Dorado International Airport", state: "Colombia")
    ]

    static let userProfile = UserProfile(
        firstName: "Jordan",
        lastName: "Avery",
        email: "jordan.avery@email.com",
        homeAirportCode: "SFO"
    )

    static let skyMilesAccount = SkyMilesAccount(
        memberNumber: "SM12345678",
        medallionLevel: "Gold Medallion",
        redeemableMiles: 127_450,
        mqds: 9_820
    )

    static func seededState() -> PersistedAppState {
        let trips = seededTrips()
        return PersistedAppState(
            fareSourceType: .seeded,
            trips: trips,
            boardingPasses: seededBoardingPasses(from: trips),
            alerts: seededAlerts(),
            recentSearches: seededRecentSearches(),
            userProfile: userProfile,
            skyMilesAccount: skyMilesAccount
        )
    }

    static func seededItineraries() -> [FlightItinerary] {
        oneWayItineraries() + roundTripItineraries()
    }

    static func defaultDepartureDate(for type: TripType) -> Date {
        let itineraries = seededItineraries().filter { $0.tripType == type }
        return itineraries.first?.departureTime ?? futureDate(daysFromNow: 7, hour: 8, minute: 0)
    }

    static func seededTrips() -> [Trip] {
        let itineraries = seededItineraries()

        // ── Upcoming trips — all from SFO (home), spread across different weeks ──

        // 2 days out — SFO→JFK one-way business trip (eligible for check-in)
        let upcomingCheckedIn = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "OW056" })!,
            tripID: "TRIP_UPCOMING_001",
            confirmationCode: "H7K2QX",
            category: .upcoming,
            status: .onTime,
            seatAssignment: "12A",
            boardingGroup: "Main 1",
            checkedIn: false,
            checkInEligible: true,
            baggageStatus: "1 checked bag tagged",
            dateShiftDays: -6
        )

        // 10 days out — SFO→SEA weekend round-trip (Comfort+)
        let upcomingNotCheckedIn = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT131" })!,
            tripID: "TRIP_UPCOMING_002",
            confirmationCode: "J9M4TL",
            category: .upcoming,
            status: .onTime,
            seatAssignment: "8C",
            boardingGroup: "Comfort+",
            checkedIn: false,
            checkInEligible: false,
            baggageStatus: "Carry-on only",
            dateShiftDays: 3
        )

        // 3 weeks out — SFO→ORD round-trip business
        let upcomingDelayed = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT073" })!,
            tripID: "TRIP_UPCOMING_003",
            confirmationCode: "P4L8WN",
            category: .upcoming,
            status: .onTime,
            seatAssignment: "22D",
            boardingGroup: "Main 2",
            checkedIn: false,
            checkInEligible: false,
            baggageStatus: "No checked bags",
            dateShiftDays: 13
        )

        // 5 weeks out — SFO→HNL Hawaii vacation round-trip
        let upcomingCheckedInSecondary = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT111" })!,
            tripID: "TRIP_UPCOMING_004",
            confirmationCode: "C3N7BR",
            category: .upcoming,
            status: .onTime,
            seatAssignment: "15F",
            boardingGroup: "Main 2",
            checkedIn: false,
            checkInEligible: false,
            baggageStatus: "No checked bags",
            dateShiftDays: 28
        )

        // 6 weeks out — SFO→LHR via JFK international connecting trip
        let upcomingInternational = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT227" })!,
            tripID: "TRIP_UPCOMING_005",
            confirmationCode: "X6R9JV",
            category: .upcoming,
            status: .onTime,
            seatAssignment: "9A",
            boardingGroup: "Comfort+",
            checkedIn: false,
            checkInEligible: false,
            baggageStatus: "No checked bags",
            dateShiftDays: 35,
            aircraftType: "Boeing 767-300ER"
        )

        let pastTripA = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT001" })!,
            tripID: "TRIP_PAST_001",
            confirmationCode: "A2F8MP",
            category: .past,
            status: .departed,
            seatAssignment: "15D",
            boardingGroup: "Main 1",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Delivered",
            dateShiftDays: -12
        )

        let pastTripB = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "OW010" })!,
            tripID: "TRIP_PAST_002",
            confirmationCode: "Q5R1NZ",
            category: .past,
            status: .departed,
            seatAssignment: "21B",
            boardingGroup: "Main 2",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Carry-on only",
            dateShiftDays: -9
        )

        let pastTripC = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT013" })!,
            tripID: "TRIP_PAST_003",
            confirmationCode: "L6T3VX",
            category: .past,
            status: .departed,
            seatAssignment: "14F",
            boardingGroup: "Comfort+",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Delivered",
            dateShiftDays: -15
        )

        let pastTripD = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "OW024" })!,
            tripID: "TRIP_PAST_004",
            confirmationCode: "Z1K9MH",
            category: .past,
            status: .departed,
            seatAssignment: "20D",
            boardingGroup: "Main 2",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Carry-on only",
            dateShiftDays: -11
        )

        let pastTripE = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT019" })!,
            tripID: "TRIP_PAST_005",
            confirmationCode: "R8Q2DP",
            category: .past,
            status: .departed,
            seatAssignment: "12F",
            boardingGroup: "Main 1",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Delivered",
            dateShiftDays: -14
        )

        // ── Extended past trip history (Sep 2025 – Mar 2026) ────────

        // Sep 15, 2025 — SFO→SEA business overnight (Comfort+)
        let pastTripF = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT131" })!,
            tripID: "TRIP_PAST_006",
            confirmationCode: "W4N8GT",
            category: .past,
            status: .departed,
            seatAssignment: "8A",
            boardingGroup: "Comfort+",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Carry-on only",
            dateShiftDays: -243
        )

        // Oct 8, 2025 — SFO→JFK business 2-night trip
        let pastTripG = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT132" })!,
            tripID: "TRIP_PAST_007",
            confirmationCode: "B6H3RV",
            category: .past,
            status: .departed,
            seatAssignment: "22A",
            boardingGroup: "Main 2",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Delivered",
            dateShiftDays: -219
        )

        // Nov 3, 2025 — SFO→ORD business overnight
        let pastTripH = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT133" })!,
            tripID: "TRIP_PAST_008",
            confirmationCode: "K9T2FJ",
            category: .past,
            status: .departed,
            seatAssignment: "19D",
            boardingGroup: "Main 1",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Delivered",
            dateShiftDays: -193
        )

        // Nov 25, 2025 — SFO→ATL Thanksgiving trip
        let pastTripI = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT134" })!,
            tripID: "TRIP_PAST_009",
            confirmationCode: "M5X1PL",
            category: .past,
            status: .departed,
            seatAssignment: "14B",
            boardingGroup: "Main 2",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Delivered",
            dateShiftDays: -171
        )

        // Dec 22, 2025 — SFO→BOS Christmas holiday (Comfort+)
        let pastTripJ = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT135" })!,
            tripID: "TRIP_PAST_010",
            confirmationCode: "D7Y4QC",
            category: .past,
            status: .departed,
            seatAssignment: "7F",
            boardingGroup: "Comfort+",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Delivered",
            dateShiftDays: -144
        )

        // Jan 9, 2026 — SFO→LAX weekend round-trip
        let pastTripK = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT136" })!,
            tripID: "TRIP_PAST_011",
            confirmationCode: "F2V6NK",
            category: .past,
            status: .departed,
            seatAssignment: "23C",
            boardingGroup: "Main 2",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Carry-on only",
            dateShiftDays: -126
        )

        // Jan 30, 2026 — SFO→LAS one-way weekend
        let pastTripL = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "OW303" })!,
            tripID: "TRIP_PAST_012",
            confirmationCode: "G8J5WA",
            category: .past,
            status: .departed,
            seatAssignment: "17E",
            boardingGroup: "Main 2",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Carry-on only",
            dateShiftDays: -105
        )

        // Feb 7, 2026 — SFO→SAN weekend round-trip
        let pastTripM = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT137" })!,
            tripID: "TRIP_PAST_013",
            confirmationCode: "T3P9HS",
            category: .past,
            status: .departed,
            seatAssignment: "20A",
            boardingGroup: "Main 1",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Carry-on only",
            dateShiftDays: -97
        )

        // Feb 20, 2026 — SFO→SEA business overnight
        let pastTripN = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT138" })!,
            tripID: "TRIP_PAST_014",
            confirmationCode: "V1L7ZE",
            category: .past,
            status: .departed,
            seatAssignment: "15C",
            boardingGroup: "Main 1",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "Delivered",
            dateShiftDays: -84
        )

        // Jan 15, 2026 — ATL→SFO canceled (eCredit origin: DL 1847 ATL-SFO)
        let pastTripCanceled = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "OW087" })!,
            tripID: "TRIP_PAST_015",
            confirmationCode: "N3W5YR",
            category: .canceled,
            status: .onTime,
            seatAssignment: "18A",
            boardingGroup: "Main 1",
            checkedIn: false,
            checkInEligible: false,
            baggageStatus: "Refunded",
            dateShiftDays: -67
        )

        // Oct 10, 2025 — SFO→NRT international vacation (Comfort+, 2 pax)
        let pastTripInternational = tripFrom(
            itinerary: itineraries.first(where: { $0.id == "RT213" })!,
            tripID: "TRIP_PAST_016",
            confirmationCode: "H4K8PN",
            category: .past,
            status: .departed,
            seatAssignment: "11A",
            boardingGroup: "Comfort+",
            checkedIn: true,
            checkInEligible: false,
            baggageStatus: "2 bags — Delivered",
            dateShiftDays: -159,
            passengerCount: 2,
            aircraftType: "Airbus A330-900neo"
        )

        return [
            upcomingCheckedIn,
            upcomingNotCheckedIn,
            upcomingDelayed,
            upcomingCheckedInSecondary,
            upcomingInternational,
            pastTripA,
            pastTripB,
            pastTripC,
            pastTripD,
            pastTripE,
            pastTripF,
            pastTripG,
            pastTripH,
            pastTripI,
            pastTripJ,
            pastTripK,
            pastTripL,
            pastTripM,
            pastTripN,
            pastTripCanceled,
            pastTripInternational
        ]
    }

    static func seededBoardingPasses(from trips: [Trip]) -> [BoardingPass] {
        trips
            .filter { ($0.checkedIn || $0.checkInEligible) && $0.category == .upcoming && $0.seatAssignment != nil }
            .sorted { $0.departureTime < $1.departureTime }
            .map(boardingPass(for:))
    }

    static func seededAlerts() -> [TravelAlert] {
        [
            TravelAlert(
                id: "ALERT_001",
                title: "Terminal Security Advisory",
                message: "ATL security wait times are elevated this morning. Arrive at least 2 hours before departure.",
                severity: .caution,
                publishedAt: futureDate(daysFromNow: -1, hour: 7, minute: 0),
                isActive: true
            ),
            TravelAlert(
                id: "ALERT_002",
                title: "Weather Watch: Northeast",
                message: "Potential weather delays for JFK, LGA, and BOS after 5:00 PM local time.",
                severity: .warning,
                publishedAt: futureDate(daysFromNow: -1, hour: 10, minute: 30),
                isActive: true
            ),
            TravelAlert(
                id: "ALERT_003",
                title: "Digital ID Lanes Available",
                message: "Eligible members can use Digital ID lanes at ATL and LAX checkpoints.",
                severity: .info,
                publishedAt: futureDate(daysFromNow: -2, hour: 9, minute: 45),
                isActive: true
            ),
            TravelAlert(
                id: "ALERT_004",
                title: "Boarding Gate Change",
                message: "Select ATL departures to the West Coast may board from concourse B instead of A. Confirm your gate before departure.",
                severity: .caution,
                publishedAt: futureDate(daysFromNow: -1, hour: 12, minute: 5),
                isActive: true
            ),
            TravelAlert(
                id: "ALERT_005",
                title: "Sky Club Capacity Advisory",
                message: "Temporary waitlists are in effect at JFK Terminal 4 and SEA lounges during peak evening departures.",
                severity: .info,
                publishedAt: futureDate(daysFromNow: -1, hour: 14, minute: 20),
                isActive: true
            ),
            TravelAlert(
                id: "ALERT_006",
                title: "SFO Terminal 2 Security Wait Times",
                message: "SFO International Terminal security lines are averaging 35 minutes. TSA PreCheck lanes at 12 minutes. Plan accordingly for your upcoming departure.",
                severity: .caution,
                publishedAt: futureDate(daysFromNow: 0, hour: 7, minute: 15),
                isActive: true
            ),
            TravelAlert(
                id: "ALERT_007",
                title: "SFO Sky Club Now Open",
                message: "The renovated SkyTrip Sky Club at SFO Terminal 2 is now open with expanded seating, premium dining, and shower suites. Open 5:00 AM–10:30 PM.",
                severity: .info,
                publishedAt: futureDate(daysFromNow: 0, hour: 9, minute: 0),
                isActive: true
            ),
            TravelAlert(
                id: "ALERT_008",
                title: "ORD Gate Change Advisory",
                message: "Due to terminal construction at O'Hare, some SkyTrip departures are temporarily relocated to Terminal 2 Concourse E. Check your gate before boarding.",
                severity: .caution,
                publishedAt: futureDate(daysFromNow: 0, hour: 11, minute: 30),
                isActive: true
            )
        ]
    }

    static func seededRecentSearches() -> [RecentSearch] {
        [
            // Most recent: SFO → NRT vacation search (user lives in SFO)
            RecentSearch(
                id: "RECENT_001",
                originCode: "SFO",
                destinationCode: "NRT",
                tripType: .roundTrip,
                departureDate: futureDate(daysFromNow: 21, hour: 13, minute: 0),
                returnDate: futureDate(daysFromNow: 30, hour: 17, minute: 0),
                passengers: 2
            ),
            // SFO → JFK business trip
            RecentSearch(
                id: "RECENT_002",
                originCode: "SFO",
                destinationCode: "JFK",
                tripType: .roundTrip,
                departureDate: futureDate(daysFromNow: 8, hour: 7, minute: 0),
                returnDate: futureDate(daysFromNow: 10, hour: 19, minute: 0),
                passengers: 1
            ),
            // SFO → LAX weekend trip
            RecentSearch(
                id: "RECENT_003",
                originCode: "SFO",
                destinationCode: "LAX",
                tripType: .oneWay,
                departureDate: futureDate(daysFromNow: 9, hour: 8, minute: 30),
                returnDate: nil,
                passengers: 1
            ),
            // ATL → LHR — searching for friend
            RecentSearch(
                id: "RECENT_004",
                originCode: "ATL",
                destinationCode: "LHR",
                tripType: .roundTrip,
                departureDate: futureDate(daysFromNow: 14, hour: 18, minute: 45),
                returnDate: futureDate(daysFromNow: 21, hour: 10, minute: 0),
                passengers: 1
            ),
            // JFK → CUN vacation research
            RecentSearch(
                id: "RECENT_005",
                originCode: "JFK",
                destinationCode: "CUN",
                tripType: .roundTrip,
                departureDate: futureDate(daysFromNow: 30, hour: 9, minute: 0),
                returnDate: futureDate(daysFromNow: 35, hour: 14, minute: 0),
                passengers: 2
            ),
            // SFO → SEA quick weekend getaway
            RecentSearch(
                id: "RECENT_006",
                originCode: "SFO",
                destinationCode: "SEA",
                tripType: .roundTrip,
                departureDate: futureDate(daysFromNow: 7, hour: 7, minute: 0),
                returnDate: futureDate(daysFromNow: 9, hour: 18, minute: 30),
                passengers: 1
            ),
            // SFO → ORD business trip
            RecentSearch(
                id: "RECENT_007",
                originCode: "SFO",
                destinationCode: "ORD",
                tripType: .roundTrip,
                departureDate: futureDate(daysFromNow: 12, hour: 9, minute: 0),
                returnDate: futureDate(daysFromNow: 14, hour: 17, minute: 30),
                passengers: 1
            ),
            // LAX → NRT — checking Asia prices
            RecentSearch(
                id: "RECENT_008",
                originCode: "LAX",
                destinationCode: "NRT",
                tripType: .roundTrip,
                departureDate: futureDate(daysFromNow: 28, hour: 11, minute: 30),
                returnDate: futureDate(daysFromNow: 38, hour: 17, minute: 0),
                passengers: 1
            ),
            // SFO → HNL — Hawaii trip planning
            RecentSearch(
                id: "RECENT_009",
                originCode: "SFO",
                destinationCode: "HNL",
                tripType: .roundTrip,
                departureDate: futureDate(daysFromNow: 35, hour: 8, minute: 30),
                returnDate: futureDate(daysFromNow: 42, hour: 11, minute: 0),
                passengers: 2
            ),
            // ATL → MIA one-way
            RecentSearch(
                id: "RECENT_010",
                originCode: "ATL",
                destinationCode: "MIA",
                tripType: .oneWay,
                departureDate: futureDate(daysFromNow: 10, hour: 8, minute: 0),
                returnDate: nil,
                passengers: 1
            )
        ]
    }

    static func boardingPass(for trip: Trip) -> BoardingPass {
        let first = trip.outboundSegments.first
        return BoardingPass(
            id: "BP_\(trip.confirmationCode)",
            tripId: trip.id,
            confirmationCode: trip.confirmationCode,
            passengerName: trip.passenger.fullName,
            route: trip.routeText,
            flightNumber: trip.primaryFlightNumber,
            date: trip.departureTime,
            boardingTime: first?.departureTime.addingTimeInterval(-35 * 60) ?? trip.departureTime,
            gate: first?.gate ?? "TBD",
            seat: trip.seatAssignment ?? "TBD",
            boardingGroup: trip.boardingGroup,
            qrPayload: "SIMULATED-QR-\(trip.confirmationCode)-\(trip.id)"
        )
    }

    private static func tripFrom(
        itinerary: FlightItinerary,
        tripID: String,
        confirmationCode: String,
        category: TripCategory,
        status: FlightOperationalStatus,
        seatAssignment: String?,
        boardingGroup: String,
        checkedIn: Bool,
        checkInEligible: Bool,
        baggageStatus: String,
        dateShiftDays: Int = 0,
        passengerCount: Int = 1,
        aircraftType: String = "Airbus A321neo"
    ) -> Trip {
        let outboundSegments = shiftedSegments(itinerary.outboundSegments, byDays: dateShiftDays)
        let returnSegments = shiftedSegments(itinerary.returnSegments, byDays: dateShiftDays)
        let firstDeparture = outboundSegments.first?.departureTime ?? futureDate(daysFromNow: 7, hour: 8, minute: 0)
        let createdAt = Calendar(identifier: .gregorian).date(byAdding: .day, value: -4, to: firstDeparture) ?? firstDeparture

        return Trip(
            id: tripID,
            confirmationCode: confirmationCode,
            passenger: Passenger(id: "PAX_MAIN", firstName: userProfile.firstName, lastName: userProfile.lastName, skyMilesNumber: skyMilesAccount.memberNumber),
            tripType: itinerary.tripType,
            outboundSegments: outboundSegments,
            returnSegments: returnSegments,
            seatAssignment: seatAssignment,
            boardingGroup: boardingGroup,
            checkedIn: checkedIn,
            baggageStatus: baggageStatus,
            category: category,
            operationalStatus: status,
            checkInEligible: checkInEligible,
            fareSourceType: itinerary.sourceType,
            totalPrice: itinerary.fare.price,
            currency: itinerary.fare.currency,
            seatMap: makeSeatMap(id: "SEATMAP_\(tripID)", assignedSeat: seatAssignment, aircraftType: aircraftType),
            createdAt: createdAt,
            passengerCount: passengerCount
        )
    }

    private static func shiftedSegments(_ segments: [FlightSegment], byDays days: Int) -> [FlightSegment] {
        guard days != 0 else { return segments }

        let calendar = Calendar(identifier: .gregorian)
        return segments.map { segment in
            let departure = calendar.date(byAdding: .day, value: days, to: segment.departureTime) ?? segment.departureTime
            let arrival = calendar.date(byAdding: .day, value: days, to: segment.arrivalTime) ?? segment.arrivalTime

            return FlightSegment(
                id: segment.id,
                carrierCode: segment.carrierCode,
                flightNumber: segment.flightNumber,
                origin: segment.origin,
                destination: segment.destination,
                departureTime: departure,
                arrivalTime: arrival,
                durationMinutes: segment.durationMinutes,
                terminal: segment.terminal,
                gate: segment.gate,
                stops: segment.stops,
                status: segment.status
            )
        }
    }

    private static func makeSeatMap(id: String, assignedSeat: String?, aircraftType: String = "Airbus A321neo") -> SeatMap {
        let rows = Array(10...24)
        let columns = ["A", "B", "C", "D", "E", "F"]
        let blockedSeats = Set(["10C", "10D", "13B", "13E", "22A"])

        var seats: [Seat] = []
        for row in rows {
            let rowColumns = seatColumns(for: row)
            for (index, column) in rowColumns.enumerated() {
                let seatNumber = "\(row)\(column)"
                let isAssigned = assignedSeat == seatNumber
                let isBlocked = blockedSeats.contains(seatNumber)
                let isOccupied = !isAssigned && !isBlocked && ((row + index) % 4 == 0)

                let availability: SeatAvailability
                if isAssigned {
                    availability = .selected
                } else if isBlocked {
                    availability = .blocked
                } else if isOccupied {
                    availability = .occupied
                } else {
                    availability = .available
                }

                let tag: SeatTag
                if row == 14 || row == 15 {
                    tag = .exitRow
                } else if row <= 12 {
                    tag = .premium
                } else if row <= 17 {
                    tag = .preferred
                } else {
                    tag = .standard
                }

                seats.append(
                    Seat(
                        id: seatNumber,
                        seatNumber: seatNumber,
                        row: row,
                        column: column,
                        availability: availability,
                        tag: tag
                    )
                )
            }
        }

        return SeatMap(id: id, aircraftType: aircraftType, rows: rows, columns: columns, seats: seats)
    }

    private static func seatColumns(for row: Int) -> [String] {
        if row <= 12 {
            return ["A", "C", "D", "F"]
        }
        return ["A", "B", "C", "D", "E", "F"]
    }

    private static func oneWayItineraries() -> [FlightItinerary] {
        [
            buildItinerary(id: "OW001", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 0, departureHour: 6, departureMinute: 10, durationMinutes: 125, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Best Value"]),
            buildItinerary(id: "OW002", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 287, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 419, badges: ["Main Cabin"]),
            buildItinerary(id: "OW003", tripType: .oneWay, origin: "JFK", destination: "SFO", departureDayOffset: 0, departureHour: 9, departureMinute: 20, durationMinutes: 320, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 762, badges: []),
            buildItinerary(id: "OW004", tripType: .oneWay, origin: "BOS", destination: "SEA", departureDayOffset: 0, departureHour: 11, departureMinute: 5, durationMinutes: 401, stops: 1, connection: "ORD", cabin: .mainCabin, fareBrand: "Main", price: 349, badges: ["Best Value"]),
            buildItinerary(id: "OW005", tripType: .oneWay, origin: "ORD", destination: "LAX", departureDayOffset: 0, departureHour: 12, departureMinute: 30, durationMinutes: 274, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 174, badges: []),
            buildItinerary(id: "OW006", tripType: .oneWay, origin: "LGA", destination: "ATL", departureDayOffset: 0, departureHour: 14, departureMinute: 25, durationMinutes: 152, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 169, badges: ["Main Cabin"]),
            buildItinerary(id: "OW007", tripType: .oneWay, origin: "SEA", destination: "JFK", departureDayOffset: 1, departureHour: 6, departureMinute: 55, durationMinutes: 312, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 980, badges: []),
            buildItinerary(id: "OW008", tripType: .oneWay, origin: "SFO", destination: "ORD", departureDayOffset: 1, departureHour: 10, departureMinute: 10, durationMinutes: 248, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 295, badges: []),
            buildItinerary(id: "OW009", tripType: .oneWay, origin: "ATL", destination: "BOS", departureDayOffset: 1, departureHour: 15, departureMinute: 35, durationMinutes: 154, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 259, badges: ["Best Value"]),
            buildItinerary(id: "OW010", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 2, departureHour: 7, departureMinute: 40, durationMinutes: 367, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 388, badges: ["Main Cabin"]),
            buildItinerary(id: "OW011", tripType: .oneWay, origin: "BOS", destination: "ATL", departureDayOffset: 2, departureHour: 13, departureMinute: 15, durationMinutes: 171, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 522, badges: []),
            buildItinerary(id: "OW012", tripType: .oneWay, origin: "ORD", destination: "SEA", departureDayOffset: 2, departureHour: 18, departureMinute: 5, durationMinutes: 270, stops: 1, connection: "LAX", cabin: .mainCabin, fareBrand: "Main", price: 312, badges: []),
            buildItinerary(id: "OW013", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 7, departureMinute: 5, durationMinutes: 283, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 326, badges: ["Best Value"]),
            buildItinerary(id: "OW014", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 11, departureMinute: 25, durationMinutes: 338, stops: 1, connection: "DFW", cabin: .mainCabin, fareBrand: "Main", price: 249, badges: []),
            buildItinerary(id: "OW015", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 18, departureMinute: 40, durationMinutes: 292, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 358, badges: ["Main Cabin"]),
            buildItinerary(id: "OW016", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 15, departureMinute: 5, durationMinutes: 287, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 228, badges: []),
            buildItinerary(id: "OW017", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 0, departureHour: 13, departureMinute: 40, durationMinutes: 132, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 214, badges: []),
            buildItinerary(id: "OW018", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 0, departureHour: 19, departureMinute: 15, durationMinutes: 179, stops: 1, connection: "DCA", cabin: .mainCabin, fareBrand: "Main", price: 176, badges: []),
            buildItinerary(id: "OW019", tripType: .oneWay, origin: "SEA", destination: "BOS", departureDayOffset: 2, departureHour: 7, departureMinute: 15, durationMinutes: 329, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 341, badges: ["Best Value"]),
            buildItinerary(id: "OW020", tripType: .oneWay, origin: "SEA", destination: "BOS", departureDayOffset: 2, departureHour: 12, departureMinute: 10, durationMinutes: 401, stops: 1, connection: "MSP", cabin: .mainCabin, fareBrand: "Main", price: 284, badges: []),
            buildItinerary(id: "OW021", tripType: .oneWay, origin: "MIA", destination: "JFK", departureDayOffset: 1, departureHour: 8, departureMinute: 30, durationMinutes: 185, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 246, badges: ["Main Cabin"]),
            buildItinerary(id: "OW022", tripType: .oneWay, origin: "MSP", destination: "LAX", departureDayOffset: 1, departureHour: 9, departureMinute: 50, durationMinutes: 232, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 389, badges: []),
            buildItinerary(id: "OW023", tripType: .oneWay, origin: "SLC", destination: "SEA", departureDayOffset: 2, departureHour: 16, departureMinute: 5, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: []),
            buildItinerary(id: "OW024", tripType: .oneWay, origin: "DCA", destination: "SFO", departureDayOffset: 3, departureHour: 7, departureMinute: 0, durationMinutes: 334, stops: 1, connection: "DTW", cabin: .mainCabin, fareBrand: "Main", price: 302, badges: []),
            buildItinerary(id: "OW025", tripType: .oneWay, origin: "LAS", destination: "ATL", departureDayOffset: 3, departureHour: 13, departureMinute: 20, durationMinutes: 256, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 312, badges: []),
            buildItinerary(id: "OW026", tripType: .oneWay, origin: "DTW", destination: "BOS", departureDayOffset: 1, departureHour: 17, departureMinute: 45, durationMinutes: 117, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW027", tripType: .oneWay, origin: "ATL", destination: "PIT", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 95, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 159, badges: ["Main Cabin"]),

            // ── ATL → LAX additional departures & cabins ──────────────
            buildItinerary(id: "OW028", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 55, durationMinutes: 289, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 618, badges: []),
            buildItinerary(id: "OW029", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 21, departureMinute: 10, durationMinutes: 296, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 892, badges: []),
            buildItinerary(id: "OW030", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 1, departureHour: 6, departureMinute: 30, durationMinutes: 281, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 312, badges: ["Best Value"]),
            buildItinerary(id: "OW031", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 1, departureHour: 14, departureMinute: 15, durationMinutes: 345, stops: 1, connection: "DEN", cabin: .mainCabin, fareBrand: "Main", price: 239, badges: []),
            buildItinerary(id: "OW032", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 2, departureHour: 7, departureMinute: 20, durationMinutes: 286, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 341, badges: ["Best Value"]),
            buildItinerary(id: "OW033", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 2, departureHour: 12, departureMinute: 40, durationMinutes: 291, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 449, badges: []),

            // ── ATL → JFK additional departures & cabins ──────────────
            buildItinerary(id: "OW034", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 20, durationMinutes: 128, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 289, badges: []),
            buildItinerary(id: "OW035", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 0, departureHour: 16, departureMinute: 45, durationMinutes: 131, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 468, badges: []),
            buildItinerary(id: "OW036", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 126, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: ["Best Value"]),
            buildItinerary(id: "OW037", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 1, departureHour: 12, departureMinute: 30, durationMinutes: 134, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 149, badges: []),

            // ── JFK → LAX additional departures & cabins ──────────────
            buildItinerary(id: "OW038", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 348, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 279, badges: []),
            buildItinerary(id: "OW039", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 0, departureHour: 11, departureMinute: 30, durationMinutes: 342, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 359, badges: ["Best Value"]),
            buildItinerary(id: "OW040", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 0, departureHour: 15, departureMinute: 0, durationMinutes: 355, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 824, badges: []),
            buildItinerary(id: "OW041", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 0, departureHour: 20, departureMinute: 30, durationMinutes: 338, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1149, badges: []),
            buildItinerary(id: "OW042", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 1, departureHour: 7, departureMinute: 15, durationMinutes: 344, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 329, badges: ["Best Value"]),

            // ── ATL → MIA ─────────────────────────────────────────────
            buildItinerary(id: "OW043", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: ["Best Value"]),
            buildItinerary(id: "OW044", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 0, departureHour: 12, departureMinute: 20, durationMinutes: 122, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 249, badges: []),
            buildItinerary(id: "OW045", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 0, departureHour: 17, departureMinute: 35, durationMinutes: 115, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW046", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 1, departureHour: 8, departureMinute: 10, durationMinutes: 121, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 128, badges: []),

            // ── ATL → ORD ─────────────────────────────────────────────
            buildItinerary(id: "OW047", tripType: .oneWay, origin: "ATL", destination: "ORD", departureDayOffset: 0, departureHour: 6, departureMinute: 40, durationMinutes: 122, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 186, badges: ["Best Value"]),
            buildItinerary(id: "OW048", tripType: .oneWay, origin: "ATL", destination: "ORD", departureDayOffset: 0, departureHour: 14, departureMinute: 50, durationMinutes: 118, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 138, badges: []),
            buildItinerary(id: "OW049", tripType: .oneWay, origin: "ATL", destination: "ORD", departureDayOffset: 1, departureHour: 10, departureMinute: 15, durationMinutes: 125, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 268, badges: []),

            // ── ATL → DEN ─────────────────────────────────────────────
            buildItinerary(id: "OW050", tripType: .oneWay, origin: "ATL", destination: "DEN", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 212, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: ["Best Value"]),
            buildItinerary(id: "OW051", tripType: .oneWay, origin: "ATL", destination: "DEN", departureDayOffset: 0, departureHour: 15, departureMinute: 10, durationMinutes: 218, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 359, badges: []),

            // ── JFK → MIA ─────────────────────────────────────────────
            buildItinerary(id: "OW052", tripType: .oneWay, origin: "JFK", destination: "MIA", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 188, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: ["Best Value"]),
            buildItinerary(id: "OW053", tripType: .oneWay, origin: "JFK", destination: "MIA", departureDayOffset: 0, departureHour: 14, departureMinute: 25, durationMinutes: 192, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 318, badges: []),

            // ── LAX → JFK ─────────────────────────────────────────────
            buildItinerary(id: "OW054", tripType: .oneWay, origin: "LAX", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 298, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 349, badges: ["Best Value"]),
            buildItinerary(id: "OW055", tripType: .oneWay, origin: "LAX", destination: "JFK", departureDayOffset: 0, departureHour: 17, departureMinute: 0, durationMinutes: 305, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1089, badges: []),

            // ── SFO → JFK ─────────────────────────────────────────────
            buildItinerary(id: "OW056", tripType: .oneWay, origin: "SFO", destination: "JFK", departureDayOffset: 1, departureHour: 7, departureMinute: 30, durationMinutes: 312, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 369, badges: ["Best Value"]),
            buildItinerary(id: "OW057", tripType: .oneWay, origin: "SFO", destination: "JFK", departureDayOffset: 1, departureHour: 14, departureMinute: 45, durationMinutes: 318, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 789, badges: []),

            // ── ATL → MCO (Orlando) ───────────────────────────────────
            buildItinerary(id: "OW058", tripType: .oneWay, origin: "ATL", destination: "MCO", departureDayOffset: 0, departureHour: 7, departureMinute: 20, durationMinutes: 92, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 149, badges: ["Best Value"]),
            buildItinerary(id: "OW059", tripType: .oneWay, origin: "ATL", destination: "MCO", departureDayOffset: 0, departureHour: 12, departureMinute: 45, durationMinutes: 88, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 98, badges: []),
            buildItinerary(id: "OW060", tripType: .oneWay, origin: "ATL", destination: "MCO", departureDayOffset: 0, departureHour: 18, departureMinute: 10, durationMinutes: 95, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 169, badges: []),

            // ── JFK → MCO ─────────────────────────────────────────────
            buildItinerary(id: "OW061", tripType: .oneWay, origin: "JFK", destination: "MCO", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: ["Best Value"]),
            buildItinerary(id: "OW062", tripType: .oneWay, origin: "JFK", destination: "MCO", departureDayOffset: 0, departureHour: 15, departureMinute: 15, durationMinutes: 168, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 279, badges: []),

            // ── ATL → BNA (Nashville) ─────────────────────────────────
            buildItinerary(id: "OW063", tripType: .oneWay, origin: "ATL", destination: "BNA", departureDayOffset: 0, departureHour: 7, departureMinute: 55, durationMinutes: 68, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 139, badges: ["Best Value"]),
            buildItinerary(id: "OW064", tripType: .oneWay, origin: "ATL", destination: "BNA", departureDayOffset: 0, departureHour: 16, departureMinute: 40, durationMinutes: 72, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 159, badges: []),

            // ── ATL → MSY (New Orleans) ───────────────────────────────
            buildItinerary(id: "OW065", tripType: .oneWay, origin: "ATL", destination: "MSY", departureDayOffset: 0, departureHour: 9, departureMinute: 10, durationMinutes: 93, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: ["Best Value"]),

            // ── ATL → EWR (Newark) ────────────────────────────────────
            buildItinerary(id: "OW066", tripType: .oneWay, origin: "ATL", destination: "EWR", departureDayOffset: 0, departureHour: 6, departureMinute: 50, durationMinutes: 132, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 192, badges: ["Best Value"]),

            // ── ATL → SAN (San Diego) ─────────────────────────────────
            buildItinerary(id: "OW067", tripType: .oneWay, origin: "ATL", destination: "SAN", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 278, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: ["Best Value"]),
            buildItinerary(id: "OW068", tripType: .oneWay, origin: "ATL", destination: "SAN", departureDayOffset: 0, departureHour: 13, departureMinute: 45, durationMinutes: 335, stops: 1, connection: "DFW", cabin: .mainCabin, fareBrand: "Main", price: 249, badges: []),

            // ── ATL → TPA (Tampa) ─────────────────────────────────────
            buildItinerary(id: "OW069", tripType: .oneWay, origin: "ATL", destination: "TPA", departureDayOffset: 0, departureHour: 8, departureMinute: 25, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 139, badges: ["Best Value"]),

            // ── ATL → AUS (Austin) ────────────────────────────────────
            buildItinerary(id: "OW070", tripType: .oneWay, origin: "ATL", destination: "AUS", departureDayOffset: 0, departureHour: 10, departureMinute: 40, durationMinutes: 158, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: ["Best Value"]),

            // ── JFK → SFO additional departures ───────────────────────
            buildItinerary(id: "OW071", tripType: .oneWay, origin: "JFK", destination: "SFO", departureDayOffset: 0, departureHour: 6, departureMinute: 30, durationMinutes: 362, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 379, badges: ["Best Value"]),
            buildItinerary(id: "OW072", tripType: .oneWay, origin: "JFK", destination: "SFO", departureDayOffset: 0, departureHour: 14, departureMinute: 15, durationMinutes: 358, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 289, badges: []),

            // ── ATL → PHX (Phoenix) ───────────────────────────────────
            buildItinerary(id: "OW073", tripType: .oneWay, origin: "ATL", destination: "PHX", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 232, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: ["Best Value"]),

            // ── LAX → SEA ─────────────────────────────────────────────
            buildItinerary(id: "OW074", tripType: .oneWay, origin: "LAX", destination: "SEA", departureDayOffset: 1, departureHour: 8, departureMinute: 45, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Best Value"]),

            // ── DEN → LAX ─────────────────────────────────────────────
            buildItinerary(id: "OW075", tripType: .oneWay, origin: "DEN", destination: "LAX", departureDayOffset: 1, departureHour: 10, departureMinute: 20, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: ["Best Value"]),

            // ── DTW → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW076", tripType: .oneWay, origin: "DTW", destination: "ATL", departureDayOffset: 1, departureHour: 6, departureMinute: 15, durationMinutes: 108, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),

            // ── MSP → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW077", tripType: .oneWay, origin: "MSP", destination: "ATL", departureDayOffset: 1, departureHour: 7, departureMinute: 50, durationMinutes: 152, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),

            // ── LAX → HNL (Honolulu) ──────────────────────────────────
            buildItinerary(id: "OW078", tripType: .oneWay, origin: "LAX", destination: "HNL", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 342, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: ["Best Value"]),
            buildItinerary(id: "OW079", tripType: .oneWay, origin: "LAX", destination: "HNL", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 338, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 892, badges: []),

            // ── ATL → RDU (Raleigh) ───────────────────────────────────
            buildItinerary(id: "OW080", tripType: .oneWay, origin: "ATL", destination: "RDU", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 78, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 142, badges: ["Best Value"]),

            // ── BOS → JFK ─────────────────────────────────────────────
            buildItinerary(id: "OW081", tripType: .oneWay, origin: "BOS", destination: "JFK", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 76, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),

            // ── DCA → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW082", tripType: .oneWay, origin: "DCA", destination: "ATL", departureDayOffset: 2, departureHour: 9, departureMinute: 20, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 172, badges: []),

            // ── MIA → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW083", tripType: .oneWay, origin: "MIA", destination: "ATL", departureDayOffset: 1, departureHour: 14, departureMinute: 30, durationMinutes: 124, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 186, badges: []),

            // ── ATL → DFW ─────────────────────────────────────────────
            buildItinerary(id: "OW084", tripType: .oneWay, origin: "ATL", destination: "DFW", departureDayOffset: 0, departureHour: 11, departureMinute: 5, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Best Value"]),

            // ── ORD → LAX ─────────────────────────────────────────────
            buildItinerary(id: "OW085", tripType: .oneWay, origin: "ORD", destination: "LAX", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 268, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 239, badges: ["Best Value"]),

            // ── SFO → SEA ─────────────────────────────────────────────
            buildItinerary(id: "OW086", tripType: .oneWay, origin: "SFO", destination: "SEA", departureDayOffset: 2, departureHour: 11, departureMinute: 30, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 179, badges: []),

            // ── ATL → SFO additional departures ───────────────────────
            buildItinerary(id: "OW087", tripType: .oneWay, origin: "ATL", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 298, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 339, badges: ["Best Value"]),
            buildItinerary(id: "OW088", tripType: .oneWay, origin: "ATL", destination: "SFO", departureDayOffset: 0, departureHour: 13, departureMinute: 20, durationMinutes: 305, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 459, badges: []),
            buildItinerary(id: "OW089", tripType: .oneWay, origin: "ATL", destination: "SFO", departureDayOffset: 0, departureHour: 19, departureMinute: 45, durationMinutes: 312, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 698, badges: []),

            // ── ATL → SEA ─────────────────────────────────────────────
            buildItinerary(id: "OW090", tripType: .oneWay, origin: "ATL", destination: "SEA", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 308, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: ["Best Value"]),
            buildItinerary(id: "OW091", tripType: .oneWay, origin: "ATL", destination: "SEA", departureDayOffset: 0, departureHour: 14, departureMinute: 50, durationMinutes: 365, stops: 1, connection: "MSP", cabin: .mainCabin, fareBrand: "Main", price: 259, badges: []),

            // ── DFW → LAX ─────────────────────────────────────────────
            buildItinerary(id: "OW092", tripType: .oneWay, origin: "DFW", destination: "LAX", departureDayOffset: 1, departureHour: 10, departureMinute: 0, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: ["Best Value"]),

            // ── ATL → DTW ─────────────────────────────────────────────
            buildItinerary(id: "OW093", tripType: .oneWay, origin: "ATL", destination: "DTW", departureDayOffset: 0, departureHour: 7, departureMinute: 35, durationMinutes: 108, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),

            // ── MSP → DEN ─────────────────────────────────────────────
            buildItinerary(id: "OW094", tripType: .oneWay, origin: "MSP", destination: "DEN", departureDayOffset: 2, departureHour: 8, departureMinute: 20, durationMinutes: 152, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Day 3–5 coverage on popular routes
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW095", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 3, departureHour: 7, departureMinute: 0, durationMinutes: 285, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: ["Best Value"]),
            buildItinerary(id: "OW096", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 3, departureHour: 13, departureMinute: 30, durationMinutes: 290, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 218, badges: []),
            buildItinerary(id: "OW097", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 4, departureHour: 8, departureMinute: 15, durationMinutes: 288, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"]),
            buildItinerary(id: "OW098", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 4, departureHour: 15, departureMinute: 45, durationMinutes: 286, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 428, badges: []),
            buildItinerary(id: "OW099", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 5, departureHour: 6, departureMinute: 45, durationMinutes: 282, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 339, badges: ["Best Value"]),
            buildItinerary(id: "OW100", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 2, departureHour: 8, departureMinute: 0, durationMinutes: 127, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 179, badges: ["Best Value"]),
            buildItinerary(id: "OW101", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 2, departureHour: 14, departureMinute: 20, durationMinutes: 130, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 309, badges: []),
            buildItinerary(id: "OW102", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 3, departureHour: 6, departureMinute: 30, durationMinutes: 124, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 139, badges: []),
            buildItinerary(id: "OW103", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 3, departureHour: 18, departureMinute: 0, durationMinutes: 133, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 229, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Reverse routes (return legs)
            // ═══════════════════════════════════════════════════════════

            // ── LAX → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW104", tripType: .oneWay, origin: "LAX", destination: "ATL", departureDayOffset: 0, departureHour: 6, departureMinute: 30, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: ["Best Value"]),
            buildItinerary(id: "OW105", tripType: .oneWay, origin: "LAX", destination: "ATL", departureDayOffset: 0, departureHour: 12, departureMinute: 15, durationMinutes: 255, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 428, badges: []),
            buildItinerary(id: "OW106", tripType: .oneWay, origin: "LAX", destination: "ATL", departureDayOffset: 0, departureHour: 18, departureMinute: 30, durationMinutes: 252, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 228, badges: []),
            buildItinerary(id: "OW107", tripType: .oneWay, origin: "LAX", destination: "ATL", departureDayOffset: 1, departureHour: 7, departureMinute: 45, durationMinutes: 250, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"]),
            buildItinerary(id: "OW108", tripType: .oneWay, origin: "LAX", destination: "ATL", departureDayOffset: 2, departureHour: 8, departureMinute: 0, durationMinutes: 253, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 598, badges: []),

            // ── JFK → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW109", tripType: .oneWay, origin: "JFK", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Best Value"]),
            buildItinerary(id: "OW110", tripType: .oneWay, origin: "JFK", destination: "ATL", departureDayOffset: 0, departureHour: 13, departureMinute: 45, durationMinutes: 138, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 279, badges: []),
            buildItinerary(id: "OW111", tripType: .oneWay, origin: "JFK", destination: "ATL", departureDayOffset: 0, departureHour: 19, departureMinute: 30, durationMinutes: 145, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 148, badges: []),
            buildItinerary(id: "OW112", tripType: .oneWay, origin: "JFK", destination: "ATL", departureDayOffset: 1, departureHour: 6, departureMinute: 15, durationMinutes: 135, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),

            // ── SFO → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW113", tripType: .oneWay, origin: "SFO", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 268, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 349, badges: ["Best Value"]),
            buildItinerary(id: "OW114", tripType: .oneWay, origin: "SFO", destination: "ATL", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 274, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 728, badges: []),

            // ── SEA → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW115", tripType: .oneWay, origin: "SEA", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 278, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 338, badges: ["Best Value"]),

            // ── ORD → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW116", tripType: .oneWay, origin: "ORD", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 112, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: ["Best Value"]),
            buildItinerary(id: "OW117", tripType: .oneWay, origin: "ORD", destination: "ATL", departureDayOffset: 0, departureHour: 16, departureMinute: 40, durationMinutes: 115, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 128, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  New airport routes (to/from MCO, PHX, BNA, MSY, EWR, etc.)
            // ═══════════════════════════════════════════════════════════

            // ── MCO → JFK ─────────────────────────────────────────────
            buildItinerary(id: "OW118", tripType: .oneWay, origin: "MCO", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 168, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Best Value"]),
            // ── MCO → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW119", tripType: .oneWay, origin: "MCO", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 94, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 149, badges: []),
            // ── MCO → ORD ─────────────────────────────────────────────
            buildItinerary(id: "OW120", tripType: .oneWay, origin: "MCO", destination: "ORD", departureDayOffset: 1, departureHour: 8, departureMinute: 15, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            // ── MCO → LAX ─────────────────────────────────────────────
            buildItinerary(id: "OW121", tripType: .oneWay, origin: "MCO", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 318, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),

            // ── PHX → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW122", tripType: .oneWay, origin: "PHX", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 218, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: ["Best Value"]),
            // ── PHX → LAX ─────────────────────────────────────────────
            buildItinerary(id: "OW123", tripType: .oneWay, origin: "PHX", destination: "LAX", departureDayOffset: 0, departureHour: 10, departureMinute: 45, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),
            // ── PHX → DEN ─────────────────────────────────────────────
            buildItinerary(id: "OW124", tripType: .oneWay, origin: "PHX", destination: "DEN", departureDayOffset: 1, departureHour: 9, departureMinute: 30, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            // ── PHX → SEA ─────────────────────────────────────────────
            buildItinerary(id: "OW125", tripType: .oneWay, origin: "PHX", destination: "SEA", departureDayOffset: 1, departureHour: 7, departureMinute: 15, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),

            // ── BNA → JFK ─────────────────────────────────────────────
            buildItinerary(id: "OW126", tripType: .oneWay, origin: "BNA", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: ["Best Value"]),
            // ── BNA → LAX via ATL ─────────────────────────────────────
            buildItinerary(id: "OW127", tripType: .oneWay, origin: "BNA", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 368, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 318, badges: []),
            // ── BNA → ORD ─────────────────────────────────────────────
            buildItinerary(id: "OW128", tripType: .oneWay, origin: "BNA", destination: "ORD", departureDayOffset: 1, departureHour: 8, departureMinute: 45, durationMinutes: 88, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 158, badges: []),

            // ── MSY → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW129", tripType: .oneWay, origin: "MSY", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 20, durationMinutes: 96, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 172, badges: []),
            // ── MSY → JFK via ATL ─────────────────────────────────────
            buildItinerary(id: "OW130", tripType: .oneWay, origin: "MSY", destination: "JFK", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 298, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 268, badges: []),
            // ── MSY → DFW ─────────────────────────────────────────────
            buildItinerary(id: "OW131", tripType: .oneWay, origin: "MSY", destination: "DFW", departureDayOffset: 0, departureHour: 14, departureMinute: 10, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),

            // ── EWR → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW132", tripType: .oneWay, origin: "EWR", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 135, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            // ── EWR → LAX ─────────────────────────────────────────────
            buildItinerary(id: "OW133", tripType: .oneWay, origin: "EWR", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 345, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 368, badges: []),
            // ── EWR → MIA ─────────────────────────────────────────────
            buildItinerary(id: "OW134", tripType: .oneWay, origin: "EWR", destination: "MIA", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),

            // ── TPA → JFK ─────────────────────────────────────────────
            buildItinerary(id: "OW135", tripType: .oneWay, origin: "TPA", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            // ── TPA → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW136", tripType: .oneWay, origin: "TPA", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 10, durationMinutes: 85, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 129, badges: []),

            // ── AUS → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW137", tripType: .oneWay, origin: "AUS", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 232, badges: []),
            // ── AUS → LAX ─────────────────────────────────────────────
            buildItinerary(id: "OW138", tripType: .oneWay, origin: "AUS", destination: "LAX", departureDayOffset: 1, departureHour: 10, departureMinute: 15, durationMinutes: 195, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            // ── AUS → DFW ─────────────────────────────────────────────
            buildItinerary(id: "OW139", tripType: .oneWay, origin: "AUS", destination: "DFW", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 58, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 118, badges: []),

            // ── RDU → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW140", tripType: .oneWay, origin: "RDU", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),
            // ── RDU → JFK ─────────────────────────────────────────────
            buildItinerary(id: "OW141", tripType: .oneWay, origin: "RDU", destination: "JFK", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: []),

            // ── HNL → LAX ────────────────────────────────────────────
            buildItinerary(id: "OW142", tripType: .oneWay, origin: "HNL", destination: "LAX", departureDayOffset: 1, departureHour: 11, departureMinute: 0, durationMinutes: 318, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 418, badges: ["Best Value"]),
            // ── HNL → SFO ────────────────────────────────────────────
            buildItinerary(id: "OW143", tripType: .oneWay, origin: "HNL", destination: "SFO", departureDayOffset: 1, departureHour: 13, departureMinute: 30, durationMinutes: 312, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 438, badges: []),

            // ── SAN → ATL ─────────────────────────────────────────────
            buildItinerary(id: "OW144", tripType: .oneWay, origin: "SAN", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 252, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: []),
            // ── SAN → LAX ─────────────────────────────────────────────
            buildItinerary(id: "OW145", tripType: .oneWay, origin: "SAN", destination: "SEA", departureDayOffset: 1, departureHour: 8, departureMinute: 45, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  More connecting flights
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW146", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 1, departureHour: 10, departureMinute: 30, durationMinutes: 348, stops: 1, connection: "MSP", cabin: .mainCabin, fareBrand: "Main", price: 259, badges: []),
            buildItinerary(id: "OW147", tripType: .oneWay, origin: "BOS", destination: "LAX", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 398, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 348, badges: []),
            buildItinerary(id: "OW148", tripType: .oneWay, origin: "BOS", destination: "LAX", departureDayOffset: 0, departureHour: 11, departureMinute: 45, durationMinutes: 375, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 498, badges: []),
            buildItinerary(id: "OW149", tripType: .oneWay, origin: "DCA", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 382, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 318, badges: []),
            buildItinerary(id: "OW150", tripType: .oneWay, origin: "MIA", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 328, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 368, badges: ["Best Value"]),
            buildItinerary(id: "OW151", tripType: .oneWay, origin: "MIA", destination: "LAX", departureDayOffset: 0, departureHour: 14, departureMinute: 15, durationMinutes: 395, stops: 1, connection: "ATL", cabin: .basicEconomy, fareBrand: "Basic", price: 248, badges: []),
            buildItinerary(id: "OW152", tripType: .oneWay, origin: "ORD", destination: "MIA", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: ["Best Value"]),
            buildItinerary(id: "OW153", tripType: .oneWay, origin: "ORD", destination: "SFO", departureDayOffset: 1, departureHour: 8, departureMinute: 30, durationMinutes: 262, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),
            buildItinerary(id: "OW154", tripType: .oneWay, origin: "DEN", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"]),
            buildItinerary(id: "OW155", tripType: .oneWay, origin: "DEN", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 45, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: []),
            buildItinerary(id: "OW156", tripType: .oneWay, origin: "BOS", destination: "MIA", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 205, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: []),
            buildItinerary(id: "OW157", tripType: .oneWay, origin: "MIA", destination: "BOS", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Red-eye and late-night flights
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW158", tripType: .oneWay, origin: "LAX", destination: "JFK", departureDayOffset: 0, departureHour: 23, departureMinute: 15, durationMinutes: 292, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 319, badges: []),
            buildItinerary(id: "OW159", tripType: .oneWay, origin: "SFO", destination: "JFK", departureDayOffset: 1, departureHour: 22, departureMinute: 30, durationMinutes: 308, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 259, badges: []),
            buildItinerary(id: "OW160", tripType: .oneWay, origin: "LAX", destination: "ATL", departureDayOffset: 1, departureHour: 22, departureMinute: 0, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),
            buildItinerary(id: "OW161", tripType: .oneWay, origin: "SEA", destination: "JFK", departureDayOffset: 0, departureHour: 22, departureMinute: 45, durationMinutes: 305, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 489, badges: []),
            buildItinerary(id: "OW162", tripType: .oneWay, origin: "LAX", destination: "SFO", departureDayOffset: 0, departureHour: 21, departureMinute: 30, durationMinutes: 78, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 138, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  More premium cabins on high-demand routes
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW163", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 6, departureMinute: 0, durationMinutes: 284, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 948, badges: []),
            buildItinerary(id: "OW164", tripType: .oneWay, origin: "JFK", destination: "SFO", departureDayOffset: 0, departureHour: 18, departureMinute: 30, durationMinutes: 365, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1098, badges: []),
            buildItinerary(id: "OW165", tripType: .oneWay, origin: "LAX", destination: "JFK", departureDayOffset: 0, departureHour: 12, departureMinute: 30, durationMinutes: 302, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 768, badges: []),
            buildItinerary(id: "OW166", tripType: .oneWay, origin: "ATL", destination: "SEA", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 312, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 628, badges: []),
            buildItinerary(id: "OW167", tripType: .oneWay, origin: "JFK", destination: "MIA", departureDayOffset: 0, departureHour: 18, departureMinute: 0, durationMinutes: 186, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 498, badges: []),
            buildItinerary(id: "OW168", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 0, departureHour: 20, departureMinute: 45, durationMinutes: 119, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 378, badges: []),
            buildItinerary(id: "OW169", tripType: .oneWay, origin: "ATL", destination: "ORD", departureDayOffset: 0, departureHour: 18, departureMinute: 30, durationMinutes: 120, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 398, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  More day 4–5 flights and ATL → BOS coverage
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW170", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 4, departureHour: 8, departureMinute: 30, durationMinutes: 120, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),
            buildItinerary(id: "OW171", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 5, departureHour: 7, departureMinute: 15, durationMinutes: 116, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 118, badges: []),
            buildItinerary(id: "OW172", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 3, departureHour: 8, departureMinute: 0, durationMinutes: 345, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 349, badges: ["Best Value"]),
            buildItinerary(id: "OW173", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 4, departureHour: 7, departureMinute: 30, durationMinutes: 348, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 498, badges: []),
            buildItinerary(id: "OW174", tripType: .oneWay, origin: "ATL", destination: "ORD", departureDayOffset: 3, departureHour: 9, departureMinute: 0, durationMinutes: 119, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW175", tripType: .oneWay, origin: "ATL", destination: "BOS", departureDayOffset: 0, departureHour: 7, departureMinute: 20, durationMinutes: 156, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: ["Best Value"]),
            buildItinerary(id: "OW176", tripType: .oneWay, origin: "ATL", destination: "BOS", departureDayOffset: 0, departureHour: 14, departureMinute: 40, durationMinutes: 152, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 149, badges: []),
            buildItinerary(id: "OW177", tripType: .oneWay, origin: "ATL", destination: "BOS", departureDayOffset: 2, departureHour: 8, departureMinute: 45, durationMinutes: 158, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 289, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Inter-city non-hub routes
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW178", tripType: .oneWay, origin: "DEN", destination: "SFO", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 162, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW179", tripType: .oneWay, origin: "DEN", destination: "SEA", departureDayOffset: 1, departureHour: 9, departureMinute: 10, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 208, badges: []),
            buildItinerary(id: "OW180", tripType: .oneWay, origin: "MSP", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 245, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: []),
            buildItinerary(id: "OW181", tripType: .oneWay, origin: "MSP", destination: "ORD", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),
            buildItinerary(id: "OW182", tripType: .oneWay, origin: "DTW", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW183", tripType: .oneWay, origin: "DTW", destination: "LAX", departureDayOffset: 1, departureHour: 8, departureMinute: 30, durationMinutes: 282, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: []),
            buildItinerary(id: "OW184", tripType: .oneWay, origin: "SLC", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 128, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW185", tripType: .oneWay, origin: "SLC", destination: "JFK", departureDayOffset: 1, departureHour: 7, departureMinute: 15, durationMinutes: 302, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 328, badges: []),
            buildItinerary(id: "OW186", tripType: .oneWay, origin: "LAS", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 298, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: []),
            buildItinerary(id: "OW187", tripType: .oneWay, origin: "LAS", destination: "SEA", departureDayOffset: 1, departureHour: 10, departureMinute: 20, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),
            buildItinerary(id: "OW188", tripType: .oneWay, origin: "DFW", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: ["Best Value"]),
            buildItinerary(id: "OW189", tripType: .oneWay, origin: "DFW", destination: "ORD", departureDayOffset: 0, departureHour: 11, departureMinute: 15, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW190", tripType: .oneWay, origin: "DFW", destination: "SFO", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 232, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: []),
            buildItinerary(id: "OW191", tripType: .oneWay, origin: "LAX", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 78, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 128, badges: []),
            buildItinerary(id: "OW192", tripType: .oneWay, origin: "LAX", destination: "SFO", departureDayOffset: 0, departureHour: 13, departureMinute: 0, durationMinutes: 82, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 89, badges: []),
            buildItinerary(id: "OW193", tripType: .oneWay, origin: "SFO", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 76, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 128, badges: []),
            buildItinerary(id: "OW194", tripType: .oneWay, origin: "MIA", destination: "ORD", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: []),
            buildItinerary(id: "OW195", tripType: .oneWay, origin: "ORD", destination: "DEN", departureDayOffset: 0, departureHour: 9, departureMinute: 45, durationMinutes: 168, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  LGA – fill out (currently 2 flights)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW196", tripType: .oneWay, origin: "LGA", destination: "MIA", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: ["Best Value"]),
            buildItinerary(id: "OW197", tripType: .oneWay, origin: "LGA", destination: "ORD", departureDayOffset: 1, departureHour: 8, departureMinute: 15, durationMinutes: 155, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW198", tripType: .oneWay, origin: "LGA", destination: "DCA", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 72, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),
            buildItinerary(id: "OW199", tripType: .oneWay, origin: "LGA", destination: "BOS", departureDayOffset: 0, departureHour: 13, departureMinute: 45, durationMinutes: 68, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 138, badges: []),
            buildItinerary(id: "OW200", tripType: .oneWay, origin: "LGA", destination: "DEN", departureDayOffset: 1, departureHour: 9, departureMinute: 30, durationMinutes: 302, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 298, badges: []),
            buildItinerary(id: "OW201", tripType: .oneWay, origin: "LGA", destination: "DTW", departureDayOffset: 2, departureHour: 7, departureMinute: 0, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 158, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  PIT – fill out (currently 2 flights)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW202", tripType: .oneWay, origin: "PIT", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 159, badges: []),
            buildItinerary(id: "OW203", tripType: .oneWay, origin: "PIT", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 20, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW204", tripType: .oneWay, origin: "PIT", destination: "ORD", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 92, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),
            buildItinerary(id: "OW205", tripType: .oneWay, origin: "ATL", destination: "PIT", departureDayOffset: 2, departureHour: 14, departureMinute: 10, durationMinutes: 97, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 129, badges: []),
            buildItinerary(id: "OW206", tripType: .oneWay, origin: "PIT", destination: "MIA", departureDayOffset: 1, departureHour: 8, departureMinute: 30, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            buildItinerary(id: "OW207", tripType: .oneWay, origin: "PIT", destination: "LAX", departureDayOffset: 0, departureHour: 6, departureMinute: 30, durationMinutes: 355, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 318, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  SLC – fill out (currently 4 flights)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW208", tripType: .oneWay, origin: "SLC", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"]),
            buildItinerary(id: "OW209", tripType: .oneWay, origin: "SLC", destination: "DEN", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 92, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),
            buildItinerary(id: "OW210", tripType: .oneWay, origin: "ATL", destination: "SLC", departureDayOffset: 1, departureHour: 8, departureMinute: 45, durationMinutes: 245, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: []),
            buildItinerary(id: "OW211", tripType: .oneWay, origin: "SLC", destination: "SFO", departureDayOffset: 1, departureHour: 9, departureMinute: 15, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW212", tripType: .oneWay, origin: "SLC", destination: "ORD", departureDayOffset: 2, departureHour: 7, departureMinute: 30, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  DCA – fill out (currently 7 flights)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW213", tripType: .oneWay, origin: "DCA", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 68, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW214", tripType: .oneWay, origin: "DCA", destination: "BOS", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW215", tripType: .oneWay, origin: "DCA", destination: "MIA", departureDayOffset: 1, departureHour: 9, departureMinute: 30, durationMinutes: 168, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW216", tripType: .oneWay, origin: "ATL", destination: "DCA", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 108, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: ["Best Value"]),
            buildItinerary(id: "OW217", tripType: .oneWay, origin: "DCA", destination: "ORD", departureDayOffset: 0, departureHour: 14, departureMinute: 20, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),
            buildItinerary(id: "OW218", tripType: .oneWay, origin: "DCA", destination: "DTW", departureDayOffset: 2, departureHour: 7, departureMinute: 30, durationMinutes: 92, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  LAS – fill out (currently 6 flights)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW219", tripType: .oneWay, origin: "LAS", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 68, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 98, badges: []),
            buildItinerary(id: "OW220", tripType: .oneWay, origin: "LAS", destination: "SFO", departureDayOffset: 1, departureHour: 9, departureMinute: 30, durationMinutes: 88, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 158, badges: []),
            buildItinerary(id: "OW221", tripType: .oneWay, origin: "ATL", destination: "LAS", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 262, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"]),
            buildItinerary(id: "OW222", tripType: .oneWay, origin: "LAS", destination: "DEN", departureDayOffset: 0, departureHour: 12, departureMinute: 15, durationMinutes: 128, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 128, badges: []),
            buildItinerary(id: "OW223", tripType: .oneWay, origin: "ATL", destination: "LAS", departureDayOffset: 1, departureHour: 14, departureMinute: 0, durationMinutes: 318, stops: 1, connection: "DEN", cabin: .mainCabin, fareBrand: "Main", price: 258, badges: []),
            buildItinerary(id: "OW224", tripType: .oneWay, origin: "LAS", destination: "ORD", departureDayOffset: 2, departureHour: 7, departureMinute: 15, durationMinutes: 218, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  EWR, PHX, MSY, BNA, AUS, TPA, RDU, SAN, HNL fill-outs
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW225", tripType: .oneWay, origin: "EWR", destination: "SFO", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 352, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 378, badges: []),
            buildItinerary(id: "OW226", tripType: .oneWay, origin: "EWR", destination: "ORD", departureDayOffset: 1, departureHour: 7, departureMinute: 30, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW227", tripType: .oneWay, origin: "ATL", destination: "EWR", departureDayOffset: 1, departureHour: 12, departureMinute: 30, durationMinutes: 128, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 289, badges: []),
            buildItinerary(id: "OW228", tripType: .oneWay, origin: "EWR", destination: "DEN", departureDayOffset: 0, departureHour: 11, departureMinute: 45, durationMinutes: 252, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),
            buildItinerary(id: "OW229", tripType: .oneWay, origin: "PHX", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 298, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 398, badges: []),
            buildItinerary(id: "OW230", tripType: .oneWay, origin: "PHX", destination: "ORD", departureDayOffset: 1, departureHour: 10, departureMinute: 0, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: []),
            buildItinerary(id: "OW231", tripType: .oneWay, origin: "ATL", destination: "PHX", departureDayOffset: 1, departureHour: 13, departureMinute: 30, durationMinutes: 236, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 358, badges: []),
            buildItinerary(id: "OW232", tripType: .oneWay, origin: "PHX", destination: "SFO", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 108, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 158, badges: []),
            buildItinerary(id: "OW233", tripType: .oneWay, origin: "MSY", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 338, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 328, badges: []),
            buildItinerary(id: "OW234", tripType: .oneWay, origin: "MSY", destination: "ORD", departureDayOffset: 1, departureHour: 9, departureMinute: 10, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),
            buildItinerary(id: "OW235", tripType: .oneWay, origin: "ATL", destination: "MSY", departureDayOffset: 1, departureHour: 14, departureMinute: 40, durationMinutes: 95, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW236", tripType: .oneWay, origin: "MSY", destination: "MIA", departureDayOffset: 0, departureHour: 11, departureMinute: 30, durationMinutes: 112, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW237", tripType: .oneWay, origin: "BNA", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 72, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 142, badges: []),
            buildItinerary(id: "OW238", tripType: .oneWay, origin: "BNA", destination: "MIA", departureDayOffset: 1, departureHour: 7, departureMinute: 30, durationMinutes: 218, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 268, badges: []),
            buildItinerary(id: "OW239", tripType: .oneWay, origin: "ATL", destination: "BNA", departureDayOffset: 1, departureHour: 12, departureMinute: 15, durationMinutes: 65, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 109, badges: []),
            buildItinerary(id: "OW240", tripType: .oneWay, origin: "BNA", destination: "DEN", departureDayOffset: 2, departureHour: 9, departureMinute: 0, durationMinutes: 168, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW241", tripType: .oneWay, origin: "AUS", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 318, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 348, badges: []),
            buildItinerary(id: "OW242", tripType: .oneWay, origin: "ATL", destination: "AUS", departureDayOffset: 1, departureHour: 15, departureMinute: 20, durationMinutes: 162, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 318, badges: []),
            buildItinerary(id: "OW243", tripType: .oneWay, origin: "AUS", destination: "ORD", departureDayOffset: 1, departureHour: 10, departureMinute: 45, durationMinutes: 158, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: []),
            buildItinerary(id: "OW244", tripType: .oneWay, origin: "AUS", destination: "DEN", departureDayOffset: 0, departureHour: 13, departureMinute: 0, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),
            buildItinerary(id: "OW245", tripType: .oneWay, origin: "TPA", destination: "BOS", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 188, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),
            buildItinerary(id: "OW246", tripType: .oneWay, origin: "ATL", destination: "TPA", departureDayOffset: 1, departureHour: 14, departureMinute: 0, durationMinutes: 78, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 98, badges: []),
            buildItinerary(id: "OW247", tripType: .oneWay, origin: "TPA", destination: "ORD", departureDayOffset: 1, departureHour: 7, departureMinute: 45, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            buildItinerary(id: "OW248", tripType: .oneWay, origin: "TPA", destination: "DCA", departureDayOffset: 0, departureHour: 11, departureMinute: 0, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW249", tripType: .oneWay, origin: "RDU", destination: "LAX", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 358, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 348, badges: []),
            buildItinerary(id: "OW250", tripType: .oneWay, origin: "RDU", destination: "BOS", departureDayOffset: 1, departureHour: 10, departureMinute: 0, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW251", tripType: .oneWay, origin: "RDU", destination: "ORD", departureDayOffset: 0, departureHour: 13, departureMinute: 30, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 208, badges: []),
            buildItinerary(id: "OW252", tripType: .oneWay, origin: "ATL", destination: "RDU", departureDayOffset: 1, departureHour: 16, departureMinute: 10, durationMinutes: 75, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 152, badges: []),
            buildItinerary(id: "OW253", tripType: .oneWay, origin: "SAN", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 318, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 368, badges: []),
            buildItinerary(id: "OW254", tripType: .oneWay, origin: "SAN", destination: "DEN", departureDayOffset: 1, departureHour: 9, departureMinute: 15, durationMinutes: 152, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),
            buildItinerary(id: "OW255", tripType: .oneWay, origin: "ATL", destination: "SAN", departureDayOffset: 1, departureHour: 15, departureMinute: 30, durationMinutes: 282, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 418, badges: []),
            buildItinerary(id: "OW256", tripType: .oneWay, origin: "SAN", destination: "PHX", departureDayOffset: 0, departureHour: 12, departureMinute: 0, durationMinutes: 62, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 98, badges: []),
            buildItinerary(id: "OW257", tripType: .oneWay, origin: "SFO", destination: "HNL", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 328, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 418, badges: ["Best Value"]),
            buildItinerary(id: "OW258", tripType: .oneWay, origin: "HNL", destination: "SEA", departureDayOffset: 2, departureHour: 10, departureMinute: 0, durationMinutes: 338, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 468, badges: []),
            buildItinerary(id: "OW259", tripType: .oneWay, origin: "SEA", destination: "HNL", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 362, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 448, badges: []),
            buildItinerary(id: "OW260", tripType: .oneWay, origin: "LAX", destination: "HNL", departureDayOffset: 1, departureHour: 7, departureMinute: 45, durationMinutes: 335, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 548, badges: []),
            buildItinerary(id: "OW261", tripType: .oneWay, origin: "LAX", destination: "HNL", departureDayOffset: 2, departureHour: 11, departureMinute: 0, durationMinutes: 340, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1148, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Day 3 coverage
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW262", tripType: .oneWay, origin: "ATL", destination: "SFO", departureDayOffset: 3, departureHour: 7, departureMinute: 15, durationMinutes: 301, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: ["Best Value"]),
            buildItinerary(id: "OW263", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 3, departureHour: 9, departureMinute: 0, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW264", tripType: .oneWay, origin: "JFK", destination: "SFO", departureDayOffset: 3, departureHour: 8, departureMinute: 30, durationMinutes: 360, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 389, badges: []),
            buildItinerary(id: "OW265", tripType: .oneWay, origin: "JFK", destination: "ATL", departureDayOffset: 3, departureHour: 11, departureMinute: 0, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW266", tripType: .oneWay, origin: "LAX", destination: "ATL", departureDayOffset: 3, departureHour: 7, departureMinute: 30, durationMinutes: 250, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 308, badges: []),
            buildItinerary(id: "OW267", tripType: .oneWay, origin: "ATL", destination: "DEN", departureDayOffset: 3, departureHour: 10, departureMinute: 30, durationMinutes: 214, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: []),
            buildItinerary(id: "OW268", tripType: .oneWay, origin: "ATL", destination: "SEA", departureDayOffset: 3, departureHour: 8, departureMinute: 0, durationMinutes: 310, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 338, badges: []),
            buildItinerary(id: "OW269", tripType: .oneWay, origin: "ATL", destination: "MCO", departureDayOffset: 3, departureHour: 14, departureMinute: 20, durationMinutes: 90, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 158, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Day 4 coverage
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW270", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 4, departureHour: 7, departureMinute: 0, durationMinutes: 126, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: ["Best Value"]),
            buildItinerary(id: "OW271", tripType: .oneWay, origin: "ATL", destination: "SFO", departureDayOffset: 4, departureHour: 8, departureMinute: 15, durationMinutes: 302, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: []),
            buildItinerary(id: "OW272", tripType: .oneWay, origin: "JFK", destination: "SFO", departureDayOffset: 4, departureHour: 9, departureMinute: 0, durationMinutes: 358, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 399, badges: []),
            buildItinerary(id: "OW273", tripType: .oneWay, origin: "ATL", destination: "ORD", departureDayOffset: 4, departureHour: 10, departureMinute: 30, durationMinutes: 120, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 172, badges: []),
            buildItinerary(id: "OW274", tripType: .oneWay, origin: "ATL", destination: "BOS", departureDayOffset: 4, departureHour: 7, departureMinute: 45, durationMinutes: 154, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW275", tripType: .oneWay, origin: "LAX", destination: "JFK", departureDayOffset: 4, departureHour: 8, departureMinute: 0, durationMinutes: 300, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 358, badges: []),
            buildItinerary(id: "OW276", tripType: .oneWay, origin: "JFK", destination: "MIA", departureDayOffset: 4, departureHour: 11, departureMinute: 30, durationMinutes: 188, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),
            buildItinerary(id: "OW277", tripType: .oneWay, origin: "ATL", destination: "SEA", departureDayOffset: 4, departureHour: 13, departureMinute: 0, durationMinutes: 315, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 338, badges: []),
            buildItinerary(id: "OW278", tripType: .oneWay, origin: "ATL", destination: "DFW", departureDayOffset: 4, departureHour: 9, departureMinute: 15, durationMinutes: 140, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 192, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Day 5 coverage
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW279", tripType: .oneWay, origin: "ATL", destination: "LAX", departureDayOffset: 5, departureHour: 11, departureMinute: 30, durationMinutes: 290, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 438, badges: []),
            buildItinerary(id: "OW280", tripType: .oneWay, origin: "ATL", destination: "JFK", departureDayOffset: 5, departureHour: 8, departureMinute: 0, durationMinutes: 128, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 209, badges: []),
            buildItinerary(id: "OW281", tripType: .oneWay, origin: "ATL", destination: "MIA", departureDayOffset: 5, departureHour: 9, departureMinute: 30, durationMinutes: 117, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW282", tripType: .oneWay, origin: "JFK", destination: "LAX", departureDayOffset: 5, departureHour: 7, departureMinute: 15, durationMinutes: 345, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 369, badges: ["Best Value"]),
            buildItinerary(id: "OW283", tripType: .oneWay, origin: "ATL", destination: "SFO", departureDayOffset: 5, departureHour: 13, departureMinute: 0, durationMinutes: 304, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 358, badges: []),
            buildItinerary(id: "OW284", tripType: .oneWay, origin: "ATL", destination: "ORD", departureDayOffset: 5, departureHour: 6, departureMinute: 45, durationMinutes: 118, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 148, badges: []),
            buildItinerary(id: "OW285", tripType: .oneWay, origin: "JFK", destination: "ATL", departureDayOffset: 5, departureHour: 10, departureMinute: 0, durationMinutes: 140, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 208, badges: []),
            buildItinerary(id: "OW286", tripType: .oneWay, origin: "LAX", destination: "ATL", departureDayOffset: 5, departureHour: 7, departureMinute: 0, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: []),
            buildItinerary(id: "OW287", tripType: .oneWay, origin: "ATL", destination: "DEN", departureDayOffset: 5, departureHour: 14, departureMinute: 0, durationMinutes: 216, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 262, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  More connecting flights & inter-city routes
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW288", tripType: .oneWay, origin: "ATL", destination: "SEA", departureDayOffset: 2, departureHour: 9, departureMinute: 30, durationMinutes: 358, stops: 1, connection: "DTW", cabin: .mainCabin, fareBrand: "Main", price: 279, badges: []),
            buildItinerary(id: "OW289", tripType: .oneWay, origin: "BOS", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 392, stops: 1, connection: "JFK", cabin: .mainCabin, fareBrand: "Main", price: 368, badges: []),
            buildItinerary(id: "OW290", tripType: .oneWay, origin: "DCA", destination: "DEN", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 328, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 298, badges: []),
            buildItinerary(id: "OW291", tripType: .oneWay, origin: "MIA", destination: "SFO", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 382, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 378, badges: []),
            buildItinerary(id: "OW292", tripType: .oneWay, origin: "ORD", destination: "JFK", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Best Value"]),
            buildItinerary(id: "OW293", tripType: .oneWay, origin: "ORD", destination: "BOS", departureDayOffset: 1, departureHour: 7, departureMinute: 45, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            buildItinerary(id: "OW294", tripType: .oneWay, origin: "JFK", destination: "ORD", departureDayOffset: 0, departureHour: 12, departureMinute: 0, durationMinutes: 165, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 208, badges: []),
            buildItinerary(id: "OW295", tripType: .oneWay, origin: "MIA", destination: "DEN", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 322, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 328, badges: []),
            buildItinerary(id: "OW296", tripType: .oneWay, origin: "ATL", destination: "LAS", departureDayOffset: 2, departureHour: 10, departureMinute: 0, durationMinutes: 318, stops: 1, connection: "DEN", cabin: .basicEconomy, fareBrand: "Basic", price: 218, badges: []),
            buildItinerary(id: "OW297", tripType: .oneWay, origin: "BOS", destination: "DEN", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 268, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: []),
            buildItinerary(id: "OW298", tripType: .oneWay, origin: "DEN", destination: "ORD", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 162, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW299", tripType: .oneWay, origin: "MSP", destination: "MIA", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 282, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 328, badges: []),
            buildItinerary(id: "OW300", tripType: .oneWay, origin: "SEA", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  SFO-based one-way routes (past trip history)
            // ═══════════════════════════════════════════════════════════

            // ── SFO → SEA ───────────────────────────────────────────
            buildItinerary(id: "OW301", tripType: .oneWay, origin: "SFO", destination: "SEA", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 189, badges: ["Best Value"]),
            // ── SFO → LAX ───────────────────────────────────────────
            buildItinerary(id: "OW302", tripType: .oneWay, origin: "SFO", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 139, badges: []),
            // ── SFO → LAS ───────────────────────────────────────────
            buildItinerary(id: "OW303", tripType: .oneWay, origin: "SFO", destination: "LAS", departureDayOffset: 0, departureHour: 18, departureMinute: 45, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 159, badges: []),
            // ── SFO → SAN ───────────────────────────────────────────
            buildItinerary(id: "OW304", tripType: .oneWay, origin: "SFO", destination: "SAN", departureDayOffset: 0, departureHour: 9, departureMinute: 10, durationMinutes: 88, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 129, badges: []),
            // ── LAS → SFO ───────────────────────────────────────────
            buildItinerary(id: "OW305", tripType: .oneWay, origin: "LAS", destination: "SFO", departureDayOffset: 1, departureHour: 14, departureMinute: 20, durationMinutes: 102, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 149, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  SFO cabin diversity (benchmark-critical routes)
            // ═══════════════════════════════════════════════════════════

            // ── SFO → JFK additional cabins ─────────────────────────
            buildItinerary(id: "OW306", tripType: .oneWay, origin: "SFO", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 315, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 539, badges: []),
            buildItinerary(id: "OW307", tripType: .oneWay, origin: "SFO", destination: "JFK", departureDayOffset: 0, departureHour: 18, departureMinute: 0, durationMinutes: 308, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1189, badges: []),
            buildItinerary(id: "OW308", tripType: .oneWay, origin: "SFO", destination: "JFK", departureDayOffset: 2, departureHour: 6, departureMinute: 45, durationMinutes: 322, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 349, badges: ["Best Value"]),
            buildItinerary(id: "OW309", tripType: .oneWay, origin: "SFO", destination: "JFK", departureDayOffset: 2, departureHour: 15, departureMinute: 30, durationMinutes: 318, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 559, badges: []),

            // ── SFO → SEA additional cabins ─────────────────────────
            buildItinerary(id: "OW310", tripType: .oneWay, origin: "SFO", destination: "SEA", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 145, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 249, badges: []),
            buildItinerary(id: "OW311", tripType: .oneWay, origin: "SFO", destination: "SEA", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 138, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 129, badges: []),
            buildItinerary(id: "OW312", tripType: .oneWay, origin: "SFO", destination: "SEA", departureDayOffset: 1, departureHour: 17, departureMinute: 30, durationMinutes: 142, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 429, badges: []),

            // ── SFO → LAX additional cabins ─────────────────────────
            buildItinerary(id: "OW313", tripType: .oneWay, origin: "SFO", destination: "LAX", departureDayOffset: 0, departureHour: 12, departureMinute: 0, durationMinutes: 78, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 189, badges: []),
            buildItinerary(id: "OW314", tripType: .oneWay, origin: "SFO", destination: "LAX", departureDayOffset: 0, departureHour: 18, departureMinute: 30, durationMinutes: 82, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 89, badges: []),
            buildItinerary(id: "OW315", tripType: .oneWay, origin: "SFO", destination: "LAX", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 75, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 298, badges: []),

            // ── SFO → ORD additional cabins ─────────────────────────
            buildItinerary(id: "OW316", tripType: .oneWay, origin: "SFO", destination: "ORD", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 252, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 389, badges: []),
            buildItinerary(id: "OW317", tripType: .oneWay, origin: "SFO", destination: "ORD", departureDayOffset: 0, departureHour: 14, departureMinute: 45, durationMinutes: 248, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 698, badges: []),

            // ── SFO → ATL additional cabins ─────────────────────────
            buildItinerary(id: "OW318", tripType: .oneWay, origin: "SFO", destination: "ATL", departureDayOffset: 0, departureHour: 11, departureMinute: 30, durationMinutes: 270, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 469, badges: []),
            buildItinerary(id: "OW319", tripType: .oneWay, origin: "SFO", destination: "ATL", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 265, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 259, badges: []),
            buildItinerary(id: "OW320", tripType: .oneWay, origin: "SFO", destination: "ATL", departureDayOffset: 1, departureHour: 16, departureMinute: 15, durationMinutes: 278, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 998, badges: []),

            // ── JFK → SFO additional cabins ─────────────────────────
            buildItinerary(id: "OW321", tripType: .oneWay, origin: "JFK", destination: "SFO", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 355, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 529, badges: []),
            buildItinerary(id: "OW322", tripType: .oneWay, origin: "JFK", destination: "SFO", departureDayOffset: 1, departureHour: 21, departureMinute: 0, durationMinutes: 362, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 349, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Transatlantic routes
            // ═══════════════════════════════════════════════════════════

            // ── JFK → LHR ───────────────────────────────────────────
            buildItinerary(id: "OW400", tripType: .oneWay, origin: "JFK", destination: "LHR", departureDayOffset: 0, departureHour: 19, departureMinute: 15, durationMinutes: 415, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 548, badges: ["Best Value"]),
            buildItinerary(id: "OW401", tripType: .oneWay, origin: "JFK", destination: "LHR", departureDayOffset: 0, departureHour: 22, departureMinute: 30, durationMinutes: 405, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 3248, badges: []),
            buildItinerary(id: "OW402", tripType: .oneWay, origin: "JFK", destination: "LHR", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 420, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 798, badges: []),
            // ── LHR → JFK ───────────────────────────────────────────
            buildItinerary(id: "OW403", tripType: .oneWay, origin: "LHR", destination: "JFK", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 490, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 528, badges: ["Best Value"]),
            buildItinerary(id: "OW404", tripType: .oneWay, origin: "LHR", destination: "JFK", departureDayOffset: 1, departureHour: 11, departureMinute: 0, durationMinutes: 485, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1898, badges: []),

            // ── ATL → LHR ───────────────────────────────────────────
            buildItinerary(id: "OW405", tripType: .oneWay, origin: "ATL", destination: "LHR", departureDayOffset: 0, departureHour: 18, departureMinute: 45, durationMinutes: 505, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 598, badges: ["Best Value"]),
            buildItinerary(id: "OW406", tripType: .oneWay, origin: "ATL", destination: "LHR", departureDayOffset: 1, departureHour: 21, departureMinute: 10, durationMinutes: 498, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 3498, badges: []),
            // ── LHR → ATL ───────────────────────────────────────────
            buildItinerary(id: "OW407", tripType: .oneWay, origin: "LHR", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 575, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 578, badges: []),

            // ── JFK → CDG ───────────────────────────────────────────
            buildItinerary(id: "OW408", tripType: .oneWay, origin: "JFK", destination: "CDG", departureDayOffset: 0, departureHour: 18, departureMinute: 30, durationMinutes: 440, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 578, badges: ["Best Value"]),
            buildItinerary(id: "OW409", tripType: .oneWay, origin: "JFK", destination: "CDG", departureDayOffset: 0, departureHour: 23, departureMinute: 0, durationMinutes: 432, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 3598, badges: []),
            // ── CDG → JFK ───────────────────────────────────────────
            buildItinerary(id: "OW410", tripType: .oneWay, origin: "CDG", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 510, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 548, badges: ["Best Value"]),

            // ── ATL → CDG ───────────────────────────────────────────
            buildItinerary(id: "OW411", tripType: .oneWay, origin: "ATL", destination: "CDG", departureDayOffset: 0, departureHour: 17, departureMinute: 50, durationMinutes: 530, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 628, badges: []),

            // ── JFK → AMS ───────────────────────────────────────────
            buildItinerary(id: "OW412", tripType: .oneWay, origin: "JFK", destination: "AMS", departureDayOffset: 0, departureHour: 19, departureMinute: 0, durationMinutes: 445, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 538, badges: ["Best Value"]),
            buildItinerary(id: "OW413", tripType: .oneWay, origin: "JFK", destination: "AMS", departureDayOffset: 1, departureHour: 22, departureMinute: 45, durationMinutes: 438, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 848, badges: []),
            // ── AMS → JFK ───────────────────────────────────────────
            buildItinerary(id: "OW414", tripType: .oneWay, origin: "AMS", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 520, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 518, badges: []),

            // ── JFK → FCO ───────────────────────────────────────────
            buildItinerary(id: "OW415", tripType: .oneWay, origin: "JFK", destination: "FCO", departureDayOffset: 0, departureHour: 20, departureMinute: 30, durationMinutes: 530, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 618, badges: ["Best Value"]),
            buildItinerary(id: "OW416", tripType: .oneWay, origin: "JFK", destination: "FCO", departureDayOffset: 1, departureHour: 17, departureMinute: 15, durationMinutes: 535, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 4198, badges: []),
            // ── FCO → JFK ───────────────────────────────────────────
            buildItinerary(id: "OW417", tripType: .oneWay, origin: "FCO", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 610, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 598, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Transpacific routes
            // ═══════════════════════════════════════════════════════════

            // ── LAX → NRT ───────────────────────────────────────────
            buildItinerary(id: "OW418", tripType: .oneWay, origin: "LAX", destination: "NRT", departureDayOffset: 0, departureHour: 11, departureMinute: 30, durationMinutes: 690, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 798, badges: ["Best Value"]),
            buildItinerary(id: "OW419", tripType: .oneWay, origin: "LAX", destination: "NRT", departureDayOffset: 1, departureHour: 13, departureMinute: 0, durationMinutes: 685, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 4898, badges: []),
            // ── NRT → LAX ───────────────────────────────────────────
            buildItinerary(id: "OW420", tripType: .oneWay, origin: "NRT", destination: "LAX", departureDayOffset: 0, departureHour: 17, departureMinute: 0, durationMinutes: 600, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 768, badges: []),

            // ── ATL → NRT via LAX ───────────────────────────────────
            buildItinerary(id: "OW421", tripType: .oneWay, origin: "ATL", destination: "NRT", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 1015, stops: 1, connection: "LAX", cabin: .mainCabin, fareBrand: "Main", price: 898, badges: []),

            // ── LAX → ICN ───────────────────────────────────────────
            buildItinerary(id: "OW422", tripType: .oneWay, origin: "LAX", destination: "ICN", departureDayOffset: 0, departureHour: 12, departureMinute: 45, durationMinutes: 745, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 848, badges: ["Best Value"]),
            buildItinerary(id: "OW423", tripType: .oneWay, origin: "LAX", destination: "ICN", departureDayOffset: 1, departureHour: 10, departureMinute: 30, durationMinutes: 750, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 5198, badges: []),
            // ── ICN → LAX ───────────────────────────────────────────
            buildItinerary(id: "OW424", tripType: .oneWay, origin: "ICN", destination: "LAX", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 650, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 828, badges: []),

            // ── SEA → NRT ───────────────────────────────────────────
            buildItinerary(id: "OW425", tripType: .oneWay, origin: "SEA", destination: "NRT", departureDayOffset: 0, departureHour: 12, departureMinute: 15, durationMinutes: 625, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 758, badges: []),

            // ── SFO → NRT ───────────────────────────────────────────
            buildItinerary(id: "OW426", tripType: .oneWay, origin: "SFO", destination: "NRT", departureDayOffset: 0, departureHour: 13, departureMinute: 0, durationMinutes: 660, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 778, badges: ["Best Value"]),
            buildItinerary(id: "OW427", tripType: .oneWay, origin: "SFO", destination: "NRT", departureDayOffset: 1, departureHour: 11, departureMinute: 30, durationMinutes: 668, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 2898, badges: []),

            // ── SFO → ICN ───────────────────────────────────────────
            buildItinerary(id: "OW428", tripType: .oneWay, origin: "SFO", destination: "ICN", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 715, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 818, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Latin America & Caribbean routes
            // ═══════════════════════════════════════════════════════════

            // ── ATL → CUN ───────────────────────────────────────────
            buildItinerary(id: "OW429", tripType: .oneWay, origin: "ATL", destination: "CUN", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 188, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"]),
            buildItinerary(id: "OW430", tripType: .oneWay, origin: "ATL", destination: "CUN", departureDayOffset: 0, departureHour: 14, departureMinute: 15, durationMinutes: 192, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 398, badges: []),
            // ── CUN → ATL ───────────────────────────────────────────
            buildItinerary(id: "OW431", tripType: .oneWay, origin: "CUN", destination: "ATL", departureDayOffset: 0, departureHour: 15, departureMinute: 30, durationMinutes: 195, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),
            // ── JFK → CUN ───────────────────────────────────────────
            buildItinerary(id: "OW432", tripType: .oneWay, origin: "JFK", destination: "CUN", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: ["Best Value"]),
            // ── LAX → CUN ───────────────────────────────────────────
            buildItinerary(id: "OW433", tripType: .oneWay, origin: "LAX", destination: "CUN", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 278, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 358, badges: []),

            // ── ATL → MEX ───────────────────────────────────────────
            buildItinerary(id: "OW434", tripType: .oneWay, origin: "ATL", destination: "MEX", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: ["Best Value"]),
            // ── MEX → ATL ───────────────────────────────────────────
            buildItinerary(id: "OW435", tripType: .oneWay, origin: "MEX", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 238, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: []),
            // ── LAX → MEX ───────────────────────────────────────────
            buildItinerary(id: "OW436", tripType: .oneWay, origin: "LAX", destination: "MEX", departureDayOffset: 1, departureHour: 8, departureMinute: 15, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: []),

            // ── ATL → GRU ───────────────────────────────────────────
            buildItinerary(id: "OW437", tripType: .oneWay, origin: "ATL", destination: "GRU", departureDayOffset: 0, departureHour: 21, departureMinute: 0, durationMinutes: 620, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 748, badges: ["Best Value"]),
            buildItinerary(id: "OW438", tripType: .oneWay, origin: "ATL", destination: "GRU", departureDayOffset: 1, departureHour: 22, departureMinute: 30, durationMinutes: 615, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 3898, badges: []),
            // ── GRU → ATL ───────────────────────────────────────────
            buildItinerary(id: "OW439", tripType: .oneWay, origin: "GRU", destination: "ATL", departureDayOffset: 0, departureHour: 22, departureMinute: 0, durationMinutes: 595, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 728, badges: []),

            // ── JFK → BOG ───────────────────────────────────────────
            buildItinerary(id: "OW440", tripType: .oneWay, origin: "JFK", destination: "BOG", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 332, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: ["Best Value"]),
            // ── MIA → BOG ───────────────────────────────────────────
            buildItinerary(id: "OW441", tripType: .oneWay, origin: "MIA", destination: "BOG", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 238, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Canada routes
            // ═══════════════════════════════════════════════════════════

            // ── JFK → YYZ ───────────────────────────────────────────
            buildItinerary(id: "OW442", tripType: .oneWay, origin: "JFK", destination: "YYZ", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 95, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: ["Best Value"]),
            // ── YYZ → JFK ───────────────────────────────────────────
            buildItinerary(id: "OW443", tripType: .oneWay, origin: "YYZ", destination: "JFK", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 208, badges: []),
            // ── ATL → YYZ ───────────────────────────────────────────
            buildItinerary(id: "OW444", tripType: .oneWay, origin: "ATL", destination: "YYZ", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 135, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: []),
            // ── DTW → YYZ ───────────────────────────────────────────
            buildItinerary(id: "OW445", tripType: .oneWay, origin: "DTW", destination: "YYZ", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 62, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Connecting international via hubs
            // ═══════════════════════════════════════════════════════════

            // ── SFO → LHR via JFK ───────────────────────────────────
            buildItinerary(id: "OW446", tripType: .oneWay, origin: "SFO", destination: "LHR", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 895, stops: 1, connection: "JFK", cabin: .mainCabin, fareBrand: "Main", price: 698, badges: []),
            // ── LAX → CDG via JFK ───────────────────────────────────
            buildItinerary(id: "OW447", tripType: .oneWay, origin: "LAX", destination: "CDG", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 920, stops: 1, connection: "JFK", cabin: .mainCabin, fareBrand: "Main", price: 748, badges: []),
            // ── MIA → LHR via ATL ───────────────────────────────────
            buildItinerary(id: "OW448", tripType: .oneWay, origin: "MIA", destination: "LHR", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 765, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 678, badges: []),
            // ── BOS → FCO via JFK ───────────────────────────────────
            buildItinerary(id: "OW449", tripType: .oneWay, origin: "BOS", destination: "FCO", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 695, stops: 1, connection: "JFK", cabin: .mainCabin, fareBrand: "Main", price: 718, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: BOG outbound (was zero OW from BOG)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW450", tripType: .oneWay, origin: "BOG", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 345, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 418, badges: ["Best Value"]),
            buildItinerary(id: "OW451", tripType: .oneWay, origin: "BOG", destination: "MIA", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 245, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: []),
            buildItinerary(id: "OW452", tripType: .oneWay, origin: "BOG", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 318, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 388, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: OW inbound to LGA (was zero OW arriving LGA)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW453", tripType: .oneWay, origin: "ATL", destination: "LGA", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: ["Best Value"]),
            buildItinerary(id: "OW454", tripType: .oneWay, origin: "ATL", destination: "LGA", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 152, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 289, badges: []),
            buildItinerary(id: "OW455", tripType: .oneWay, origin: "BOS", destination: "LGA", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 65, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 138, badges: []),
            buildItinerary(id: "OW456", tripType: .oneWay, origin: "ORD", destination: "LGA", departureDayOffset: 0, departureHour: 10, departureMinute: 45, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),
            buildItinerary(id: "OW457", tripType: .oneWay, origin: "DCA", destination: "LGA", departureDayOffset: 0, departureHour: 9, departureMinute: 20, durationMinutes: 68, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),
            buildItinerary(id: "OW458", tripType: .oneWay, origin: "MIA", destination: "LGA", departureDayOffset: 1, departureHour: 8, departureMinute: 30, durationMinutes: 188, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            buildItinerary(id: "OW459", tripType: .oneWay, origin: "DTW", destination: "LGA", departureDayOffset: 1, departureHour: 7, departureMinute: 45, durationMinutes: 95, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: OW inbound to MSP (was zero OW arriving MSP)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW460", tripType: .oneWay, origin: "ATL", destination: "MSP", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 152, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Best Value"]),
            buildItinerary(id: "OW461", tripType: .oneWay, origin: "ATL", destination: "MSP", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 158, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 318, badges: []),
            buildItinerary(id: "OW462", tripType: .oneWay, origin: "ORD", destination: "MSP", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 148, badges: []),
            buildItinerary(id: "OW463", tripType: .oneWay, origin: "DEN", destination: "MSP", departureDayOffset: 0, departureHour: 10, departureMinute: 45, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 178, badges: []),
            buildItinerary(id: "OW464", tripType: .oneWay, origin: "DTW", destination: "MSP", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW465", tripType: .oneWay, origin: "DFW", destination: "MSP", departureDayOffset: 1, departureHour: 7, departureMinute: 30, durationMinutes: 158, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW466", tripType: .oneWay, origin: "JFK", destination: "MSP", departureDayOffset: 0, departureHour: 11, departureMinute: 0, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),
            buildItinerary(id: "OW467", tripType: .oneWay, origin: "LAX", destination: "MSP", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 225, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: International reverse OW routes
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW468", tripType: .oneWay, origin: "CDG", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 595, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 608, badges: []),
            buildItinerary(id: "OW469", tripType: .oneWay, origin: "CDG", destination: "LAX", departureDayOffset: 0, departureHour: 11, departureMinute: 0, durationMinutes: 685, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 698, badges: []),
            buildItinerary(id: "OW470", tripType: .oneWay, origin: "AMS", destination: "ATL", departureDayOffset: 0, departureHour: 9, departureMinute: 45, durationMinutes: 608, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 578, badges: []),
            buildItinerary(id: "OW471", tripType: .oneWay, origin: "FCO", destination: "ATL", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 735, stops: 1, connection: "JFK", cabin: .mainCabin, fareBrand: "Main", price: 648, badges: []),
            buildItinerary(id: "OW472", tripType: .oneWay, origin: "NRT", destination: "ATL", departureDayOffset: 0, departureHour: 17, departureMinute: 30, durationMinutes: 865, stops: 1, connection: "LAX", cabin: .mainCabin, fareBrand: "Main", price: 878, badges: []),
            buildItinerary(id: "OW473", tripType: .oneWay, origin: "NRT", destination: "SEA", departureDayOffset: 0, departureHour: 18, departureMinute: 0, durationMinutes: 558, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 738, badges: []),
            buildItinerary(id: "OW474", tripType: .oneWay, origin: "NRT", destination: "SFO", departureDayOffset: 0, departureHour: 16, departureMinute: 30, durationMinutes: 585, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 758, badges: []),
            buildItinerary(id: "OW475", tripType: .oneWay, origin: "ICN", destination: "SFO", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 638, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 808, badges: []),
            buildItinerary(id: "OW476", tripType: .oneWay, origin: "CUN", destination: "JFK", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 258, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 308, badges: []),
            buildItinerary(id: "OW477", tripType: .oneWay, origin: "CUN", destination: "LAX", departureDayOffset: 0, departureHour: 12, departureMinute: 30, durationMinutes: 292, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: []),
            buildItinerary(id: "OW478", tripType: .oneWay, origin: "MEX", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 218, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),
            buildItinerary(id: "OW479", tripType: .oneWay, origin: "GRU", destination: "JFK", departureDayOffset: 0, departureHour: 21, departureMinute: 30, durationMinutes: 658, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 778, badges: []),
            buildItinerary(id: "OW480", tripType: .oneWay, origin: "LHR", destination: "SFO", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 668, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 618, badges: []),
            buildItinerary(id: "OW481", tripType: .oneWay, origin: "LHR", destination: "MIA", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 618, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 588, badges: []),
            buildItinerary(id: "OW482", tripType: .oneWay, origin: "YYZ", destination: "ATL", departureDayOffset: 0, departureHour: 13, departureMinute: 0, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: []),
            buildItinerary(id: "OW483", tripType: .oneWay, origin: "YYZ", destination: "DTW", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 65, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: ORD/DFW/DEN/MSP international routes
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW484", tripType: .oneWay, origin: "ORD", destination: "LHR", departureDayOffset: 0, departureHour: 18, departureMinute: 30, durationMinutes: 475, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 568, badges: ["Best Value"]),
            buildItinerary(id: "OW485", tripType: .oneWay, origin: "LHR", destination: "ORD", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 545, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 548, badges: []),
            buildItinerary(id: "OW486", tripType: .oneWay, origin: "ORD", destination: "CDG", departureDayOffset: 0, departureHour: 19, departureMinute: 15, durationMinutes: 498, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 598, badges: []),
            buildItinerary(id: "OW487", tripType: .oneWay, origin: "CDG", destination: "ORD", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 575, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 578, badges: []),
            buildItinerary(id: "OW488", tripType: .oneWay, origin: "ORD", destination: "NRT", departureDayOffset: 0, departureHour: 12, departureMinute: 0, durationMinutes: 745, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 818, badges: []),
            buildItinerary(id: "OW489", tripType: .oneWay, origin: "NRT", destination: "ORD", departureDayOffset: 0, departureHour: 17, departureMinute: 0, durationMinutes: 665, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 798, badges: []),
            buildItinerary(id: "OW490", tripType: .oneWay, origin: "ORD", destination: "CUN", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"]),
            buildItinerary(id: "OW491", tripType: .oneWay, origin: "CUN", destination: "ORD", departureDayOffset: 0, departureHour: 15, departureMinute: 0, durationMinutes: 238, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),
            buildItinerary(id: "OW492", tripType: .oneWay, origin: "ORD", destination: "YYZ", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW493", tripType: .oneWay, origin: "YYZ", destination: "ORD", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 88, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 158, badges: []),
            buildItinerary(id: "OW494", tripType: .oneWay, origin: "DFW", destination: "CUN", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 165, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: ["Best Value"]),
            buildItinerary(id: "OW495", tripType: .oneWay, origin: "CUN", destination: "DFW", departureDayOffset: 0, departureHour: 16, departureMinute: 0, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: []),
            buildItinerary(id: "OW496", tripType: .oneWay, origin: "DFW", destination: "MEX", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 155, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: []),
            buildItinerary(id: "OW497", tripType: .oneWay, origin: "MEX", destination: "DFW", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 148, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            buildItinerary(id: "OW498", tripType: .oneWay, origin: "DFW", destination: "LHR", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 715, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 698, badges: []),
            buildItinerary(id: "OW499", tripType: .oneWay, origin: "DFW", destination: "YYZ", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),
            buildItinerary(id: "OW500", tripType: .oneWay, origin: "DEN", destination: "CUN", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: ["Best Value"]),
            buildItinerary(id: "OW501", tripType: .oneWay, origin: "CUN", destination: "DEN", departureDayOffset: 0, departureHour: 13, departureMinute: 30, durationMinutes: 258, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: []),
            buildItinerary(id: "OW502", tripType: .oneWay, origin: "DEN", destination: "MEX", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),
            buildItinerary(id: "OW503", tripType: .oneWay, origin: "MEX", destination: "DEN", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 235, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: []),
            buildItinerary(id: "OW504", tripType: .oneWay, origin: "DEN", destination: "LHR", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 728, stops: 1, connection: "JFK", cabin: .mainCabin, fareBrand: "Main", price: 718, badges: []),
            buildItinerary(id: "OW505", tripType: .oneWay, origin: "DEN", destination: "YYZ", departureDayOffset: 1, departureHour: 10, departureMinute: 0, durationMinutes: 208, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: []),
            buildItinerary(id: "OW506", tripType: .oneWay, origin: "MSP", destination: "CUN", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 258, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: ["Best Value"]),
            buildItinerary(id: "OW507", tripType: .oneWay, origin: "CUN", destination: "MSP", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 268, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 308, badges: []),
            buildItinerary(id: "OW508", tripType: .oneWay, origin: "MSP", destination: "AMS", departureDayOffset: 0, departureHour: 18, departureMinute: 0, durationMinutes: 508, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 598, badges: []),
            buildItinerary(id: "OW509", tripType: .oneWay, origin: "AMS", destination: "MSP", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 585, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 578, badges: []),
            buildItinerary(id: "OW510", tripType: .oneWay, origin: "MSP", destination: "YYZ", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 132, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: OW for routes that only had RT
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW511", tripType: .oneWay, origin: "ATL", destination: "HNL", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 578, stops: 1, connection: "LAX", cabin: .mainCabin, fareBrand: "Main", price: 498, badges: []),
            buildItinerary(id: "OW512", tripType: .oneWay, origin: "BOS", destination: "MCO", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: ["Best Value"]),
            buildItinerary(id: "OW513", tripType: .oneWay, origin: "DTW", destination: "LAS", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 268, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: []),
            buildItinerary(id: "OW514", tripType: .oneWay, origin: "DTW", destination: "MIA", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 182, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),
            buildItinerary(id: "OW515", tripType: .oneWay, origin: "JFK", destination: "BNA", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            buildItinerary(id: "OW516", tripType: .oneWay, origin: "JFK", destination: "BOS", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 74, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 158, badges: []),
            buildItinerary(id: "OW517", tripType: .oneWay, origin: "JFK", destination: "SEA", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 358, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: ["Best Value"]),
            buildItinerary(id: "OW518", tripType: .oneWay, origin: "LAX", destination: "ORD", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 238, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: []),
            buildItinerary(id: "OW519", tripType: .oneWay, origin: "MSP", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: []),
            buildItinerary(id: "OW520", tripType: .oneWay, origin: "MSP", destination: "SEA", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 206, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            buildItinerary(id: "OW521", tripType: .oneWay, origin: "ORD", destination: "MCO", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 208, badges: []),
            buildItinerary(id: "OW522", tripType: .oneWay, origin: "SEA", destination: "SFO", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: []),
            buildItinerary(id: "OW523", tripType: .oneWay, origin: "SFO", destination: "BOS", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 332, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 358, badges: ["Best Value"]),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: Key missing hub reverse OW routes
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "OW524", tripType: .oneWay, origin: "SEA", destination: "ATL", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 282, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 438, badges: []),
            buildItinerary(id: "OW525", tripType: .oneWay, origin: "BOS", destination: "ORD", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 162, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW526", tripType: .oneWay, origin: "MIA", destination: "SEA", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 378, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 398, badges: []),
            buildItinerary(id: "OW527", tripType: .oneWay, origin: "SFO", destination: "DEN", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 158, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 188, badges: []),
            buildItinerary(id: "OW528", tripType: .oneWay, origin: "SFO", destination: "MIA", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 328, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 368, badges: []),
            buildItinerary(id: "OW529", tripType: .oneWay, origin: "LAX", destination: "MIA", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 298, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: []),
            buildItinerary(id: "OW530", tripType: .oneWay, origin: "LAX", destination: "DEN", departureDayOffset: 0, departureHour: 11, departureMinute: 0, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW531", tripType: .oneWay, origin: "SFO", destination: "DFW", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 218, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: []),
            buildItinerary(id: "OW532", tripType: .oneWay, origin: "LAX", destination: "DFW", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 188, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: []),
            buildItinerary(id: "OW533", tripType: .oneWay, origin: "SEA", destination: "DEN", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 168, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: []),
            buildItinerary(id: "OW534", tripType: .oneWay, origin: "SEA", destination: "ORD", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: []),
            buildItinerary(id: "OW535", tripType: .oneWay, origin: "SEA", destination: "SFO", departureDayOffset: 0, departureHour: 12, departureMinute: 0, durationMinutes: 135, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: [])
        ]
    }

    private static func roundTripItineraries() -> [FlightItinerary] {
        [
            buildItinerary(id: "RT001", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 7, departureMinute: 10, durationMinutes: 286, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 504, badges: ["Best Value"], returnDayOffset: 4, returnHour: 13, returnMinute: 40, returnDuration: 254, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT002", tripType: .roundTrip, origin: "JFK", destination: "SEA", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 372, stops: 1, connection: "ATL", cabin: .comfortPlus, fareBrand: "Comfort+", price: 612, badges: ["Main Cabin"], returnDayOffset: 3, returnHour: 12, returnMinute: 25, returnDuration: 335, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT003", tripType: .roundTrip, origin: "ATL", destination: "SFO", departureDayOffset: 1, departureHour: 8, departureMinute: 20, durationMinutes: 303, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 546, badges: ["Best Value"], returnDayOffset: 5, returnHour: 11, returnMinute: 10, returnDuration: 266, returnStops: 1, returnConnection: "ORD"),
            buildItinerary(id: "RT004", tripType: .roundTrip, origin: "BOS", destination: "LAX", departureDayOffset: 1, departureHour: 10, departureMinute: 15, durationMinutes: 390, stops: 1, connection: "ATL", cabin: .firstClass, fareBrand: "First", price: 1210, badges: [], returnDayOffset: 4, returnHour: 15, returnMinute: 45, returnDuration: 355, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT005", tripType: .roundTrip, origin: "ORD", destination: "JFK", departureDayOffset: 1, departureHour: 6, departureMinute: 40, durationMinutes: 124, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 278, badges: [], returnDayOffset: 2, returnHour: 19, returnMinute: 5, returnDuration: 131, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT006", tripType: .roundTrip, origin: "LGA", destination: "ATL", departureDayOffset: 2, departureHour: 7, departureMinute: 5, durationMinutes: 151, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 289, badges: ["Main Cabin"], returnDayOffset: 4, returnHour: 18, returnMinute: 35, returnDuration: 146, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT007", tripType: .roundTrip, origin: "SEA", destination: "ATL", departureDayOffset: 2, departureHour: 12, departureMinute: 30, durationMinutes: 271, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1265, badges: [], returnDayOffset: 6, returnHour: 9, returnMinute: 25, returnDuration: 300, returnStops: 1, returnConnection: "JFK"),
            buildItinerary(id: "RT008", tripType: .roundTrip, origin: "SFO", destination: "BOS", departureDayOffset: 2, departureHour: 14, departureMinute: 0, durationMinutes: 332, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 594, badges: ["Best Value"], returnDayOffset: 5, returnHour: 13, returnMinute: 15, returnDuration: 368, returnStops: 1, returnConnection: "ORD"),
            buildItinerary(id: "RT009", tripType: .roundTrip, origin: "ATL", destination: "ORD", departureDayOffset: 3, departureHour: 9, departureMinute: 30, durationMinutes: 118, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 332, badges: [], returnDayOffset: 4, returnHour: 21, returnMinute: 5, returnDuration: 108, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT010", tripType: .roundTrip, origin: "JFK", destination: "BOS", departureDayOffset: 3, departureHour: 16, departureMinute: 10, durationMinutes: 74, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 241, badges: ["Main Cabin"], returnDayOffset: 4, returnHour: 9, returnMinute: 0, returnDuration: 79, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT011", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 6, departureMinute: 50, durationMinutes: 289, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 468, badges: ["Best Value"], returnDayOffset: 3, returnHour: 14, returnMinute: 20, returnDuration: 261, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT012", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 12, departureMinute: 15, durationMinutes: 350, stops: 1, connection: "DFW", cabin: .mainCabin, fareBrand: "Main", price: 402, badges: [], returnDayOffset: 3, returnHour: 8, returnMinute: 35, returnDuration: 333, returnStops: 1, returnConnection: "SLC"),
            buildItinerary(id: "RT013", tripType: .roundTrip, origin: "JFK", destination: "SFO", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 365, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 624, badges: ["Best Value"], returnDayOffset: 5, returnHour: 13, returnMinute: 55, returnDuration: 332, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT014", tripType: .roundTrip, origin: "JFK", destination: "SFO", departureDayOffset: 1, departureHour: 15, departureMinute: 10, durationMinutes: 409, stops: 1, connection: "MSP", cabin: .comfortPlus, fareBrand: "Comfort+", price: 712, badges: [], returnDayOffset: 5, returnHour: 9, returnMinute: 20, returnDuration: 401, returnStops: 1, returnConnection: "ATL"),
            buildItinerary(id: "RT015", tripType: .roundTrip, origin: "ATL", destination: "MIA", departureDayOffset: 1, departureHour: 9, departureMinute: 45, durationMinutes: 121, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 286, badges: ["Main Cabin"], returnDayOffset: 4, returnHour: 17, returnMinute: 25, returnDuration: 126, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT016", tripType: .roundTrip, origin: "DCA", destination: "LAX", departureDayOffset: 2, departureHour: 7, departureMinute: 20, durationMinutes: 344, stops: 1, connection: "MSP", cabin: .comfortPlus, fareBrand: "Comfort+", price: 589, badges: [], returnDayOffset: 6, returnHour: 11, returnMinute: 5, returnDuration: 321, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT017", tripType: .roundTrip, origin: "MSP", destination: "SEA", departureDayOffset: 2, departureHour: 10, departureMinute: 30, durationMinutes: 206, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: [], returnDayOffset: 4, returnHour: 14, returnMinute: 5, returnDuration: 198, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT018", tripType: .roundTrip, origin: "BOS", destination: "DEN", departureDayOffset: 3, departureHour: 6, departureMinute: 45, durationMinutes: 301, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 437, badges: [], returnDayOffset: 6, returnHour: 15, returnMinute: 50, returnDuration: 278, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT019", tripType: .roundTrip, origin: "ATL", destination: "PIT", departureDayOffset: 0, departureHour: 9, departureMinute: 10, durationMinutes: 96, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 214, badges: ["Main Cabin"], returnDayOffset: 2, returnHour: 18, returnMinute: 30, returnDuration: 101, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT020", tripType: .roundTrip, origin: "DTW", destination: "LAS", departureDayOffset: 1, departureHour: 12, departureMinute: 20, durationMinutes: 276, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 954, badges: [], returnDayOffset: 5, returnHour: 8, returnMinute: 30, returnDuration: 242, returnStops: 1, returnConnection: "MSP"),

            // ── ATL → LAX additional round-trips ──────────────────────
            buildItinerary(id: "RT021", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 55, durationMinutes: 289, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1089, badges: [], returnDayOffset: 4, returnHour: 10, returnMinute: 30, returnDuration: 256, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT022", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 1, departureHour: 7, departureMinute: 30, durationMinutes: 284, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 489, badges: ["Best Value"], returnDayOffset: 5, returnHour: 15, returnMinute: 0, returnDuration: 258, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT023", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 1, departureHour: 16, departureMinute: 20, durationMinutes: 292, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1568, badges: [], returnDayOffset: 5, returnHour: 8, returnMinute: 45, returnDuration: 262, returnStops: 0, returnConnection: nil),

            // ── JFK → LAX round-trips ─────────────────────────────────
            buildItinerary(id: "RT024", tripType: .roundTrip, origin: "JFK", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 348, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 578, badges: ["Best Value"], returnDayOffset: 4, returnHour: 9, returnMinute: 15, returnDuration: 302, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT025", tripType: .roundTrip, origin: "JFK", destination: "LAX", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 352, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1428, badges: [], returnDayOffset: 4, returnHour: 16, returnMinute: 0, returnDuration: 308, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT026", tripType: .roundTrip, origin: "JFK", destination: "LAX", departureDayOffset: 1, departureHour: 7, departureMinute: 15, durationMinutes: 344, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 548, badges: [], returnDayOffset: 5, returnHour: 11, returnMinute: 30, returnDuration: 298, returnStops: 0, returnConnection: nil),

            // ── ATL → DEN round-trips ─────────────────────────────────
            buildItinerary(id: "RT027", tripType: .roundTrip, origin: "ATL", destination: "DEN", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 212, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 386, badges: ["Best Value"], returnDayOffset: 3, returnHour: 14, returnMinute: 20, returnDuration: 194, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT028", tripType: .roundTrip, origin: "ATL", destination: "DEN", departureDayOffset: 1, departureHour: 14, departureMinute: 0, durationMinutes: 218, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 512, badges: [], returnDayOffset: 4, returnHour: 9, returnMinute: 45, returnDuration: 198, returnStops: 0, returnConnection: nil),

            // ── ATL → SEA round-trips ─────────────────────────────────
            buildItinerary(id: "RT029", tripType: .roundTrip, origin: "ATL", destination: "SEA", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 308, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: ["Best Value"], returnDayOffset: 4, returnHour: 12, returnMinute: 0, returnDuration: 278, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT030", tripType: .roundTrip, origin: "ATL", destination: "SEA", departureDayOffset: 1, departureHour: 10, departureMinute: 45, durationMinutes: 365, stops: 1, connection: "MSP", cabin: .mainCabin, fareBrand: "Main", price: 389, badges: [], returnDayOffset: 5, returnHour: 14, returnMinute: 30, returnDuration: 342, returnStops: 1, returnConnection: "DTW"),

            // ── JFK → MIA round-trips ─────────────────────────────────
            buildItinerary(id: "RT031", tripType: .roundTrip, origin: "JFK", destination: "MIA", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 188, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 358, badges: ["Best Value"], returnDayOffset: 3, returnHour: 15, returnMinute: 30, returnDuration: 178, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT032", tripType: .roundTrip, origin: "JFK", destination: "MIA", departureDayOffset: 1, departureHour: 7, departureMinute: 30, durationMinutes: 185, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 478, badges: [], returnDayOffset: 4, returnHour: 18, returnMinute: 0, returnDuration: 182, returnStops: 0, returnConnection: nil),

            // ── ATL → MCO round-trips ─────────────────────────────────
            buildItinerary(id: "RT033", tripType: .roundTrip, origin: "ATL", destination: "MCO", departureDayOffset: 0, departureHour: 7, departureMinute: 20, durationMinutes: 92, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: ["Best Value"], returnDayOffset: 3, returnHour: 16, returnMinute: 40, returnDuration: 96, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT034", tripType: .roundTrip, origin: "ATL", destination: "MCO", departureDayOffset: 1, departureHour: 10, departureMinute: 15, durationMinutes: 88, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 158, badges: [], returnDayOffset: 4, returnHour: 14, returnMinute: 0, returnDuration: 92, returnStops: 0, returnConnection: nil),

            // ── ORD → LAX round-trip ──────────────────────────────────
            buildItinerary(id: "RT035", tripType: .roundTrip, origin: "ORD", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 268, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 428, badges: ["Best Value"], returnDayOffset: 4, returnHour: 10, returnMinute: 45, returnDuration: 242, returnStops: 0, returnConnection: nil),

            // ── ATL → BNA round-trip ──────────────────────────────────
            buildItinerary(id: "RT036", tripType: .roundTrip, origin: "ATL", destination: "BNA", departureDayOffset: 0, departureHour: 7, departureMinute: 55, durationMinutes: 68, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Main Cabin"], returnDayOffset: 2, returnHour: 17, returnMinute: 20, returnDuration: 72, returnStops: 0, returnConnection: nil),

            // ── ATL → MSY round-trip ──────────────────────────────────
            buildItinerary(id: "RT037", tripType: .roundTrip, origin: "ATL", destination: "MSY", departureDayOffset: 1, departureHour: 9, departureMinute: 10, durationMinutes: 93, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: [], returnDayOffset: 4, returnHour: 15, returnMinute: 45, returnDuration: 98, returnStops: 0, returnConnection: nil),

            // ── DFW → JFK round-trip ──────────────────────────────────
            buildItinerary(id: "RT038", tripType: .roundTrip, origin: "DFW", destination: "JFK", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 378, badges: ["Best Value"], returnDayOffset: 5, returnHour: 12, returnMinute: 30, returnDuration: 228, returnStops: 0, returnConnection: nil),

            // ── ATL → DFW round-trip ──────────────────────────────────
            buildItinerary(id: "RT039", tripType: .roundTrip, origin: "ATL", destination: "DFW", departureDayOffset: 0, departureHour: 11, departureMinute: 5, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Main Cabin"], returnDayOffset: 3, returnHour: 16, returnMinute: 20, returnDuration: 138, returnStops: 0, returnConnection: nil),

            // ── LAX → HNL round-trips ─────────────────────────────────
            buildItinerary(id: "RT040", tripType: .roundTrip, origin: "LAX", destination: "HNL", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 342, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 648, badges: ["Best Value"], returnDayOffset: 5, returnHour: 10, returnMinute: 30, returnDuration: 318, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT041", tripType: .roundTrip, origin: "LAX", destination: "HNL", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 338, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1548, badges: [], returnDayOffset: 5, returnHour: 16, returnMinute: 0, returnDuration: 322, returnStops: 0, returnConnection: nil),

            // ── ATL → EWR round-trip ──────────────────────────────────
            buildItinerary(id: "RT042", tripType: .roundTrip, origin: "ATL", destination: "EWR", departureDayOffset: 0, departureHour: 6, departureMinute: 50, durationMinutes: 132, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Main Cabin"], returnDayOffset: 3, returnHour: 18, returnMinute: 15, returnDuration: 128, returnStops: 0, returnConnection: nil),

            // ── JFK → MCO round-trip ──────────────────────────────────
            buildItinerary(id: "RT043", tripType: .roundTrip, origin: "JFK", destination: "MCO", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"], returnDayOffset: 4, returnHour: 13, returnMinute: 0, returnDuration: 168, returnStops: 0, returnConnection: nil),

            // ── BOS → SFO round-trip ──────────────────────────────────
            buildItinerary(id: "RT044", tripType: .roundTrip, origin: "BOS", destination: "SFO", departureDayOffset: 1, departureHour: 7, departureMinute: 45, durationMinutes: 378, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 548, badges: ["Best Value"], returnDayOffset: 5, returnHour: 11, returnMinute: 0, returnDuration: 342, returnStops: 0, returnConnection: nil),

            // ── ATL → PHX round-trip ──────────────────────────────────
            buildItinerary(id: "RT045", tripType: .roundTrip, origin: "ATL", destination: "PHX", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 232, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: ["Best Value"], returnDayOffset: 4, returnHour: 11, returnMinute: 30, returnDuration: 218, returnStops: 0, returnConnection: nil),

            // ── SEA → SFO round-trip ──────────────────────────────────
            buildItinerary(id: "RT046", tripType: .roundTrip, origin: "SEA", destination: "SFO", departureDayOffset: 2, departureHour: 9, departureMinute: 0, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: [], returnDayOffset: 5, returnHour: 15, returnMinute: 20, returnDuration: 138, returnStops: 0, returnConnection: nil),

            // ── DTW → MIA round-trip ──────────────────────────────────
            buildItinerary(id: "RT047", tripType: .roundTrip, origin: "DTW", destination: "MIA", departureDayOffset: 1, departureHour: 8, departureMinute: 40, durationMinutes: 182, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 368, badges: [], returnDayOffset: 5, returnHour: 13, returnMinute: 15, returnDuration: 178, returnStops: 0, returnConnection: nil),

            // ── MSP → LAX round-trip ──────────────────────────────────
            buildItinerary(id: "RT048", tripType: .roundTrip, origin: "MSP", destination: "LAX", departureDayOffset: 1, departureHour: 9, departureMinute: 50, durationMinutes: 232, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 418, badges: ["Best Value"], returnDayOffset: 5, returnHour: 14, returnMinute: 20, returnDuration: 218, returnStops: 0, returnConnection: nil),

            // ── ATL → SFO additional round-trips ──────────────────────
            buildItinerary(id: "RT049", tripType: .roundTrip, origin: "ATL", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 298, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 518, badges: ["Best Value"], returnDayOffset: 4, returnHour: 12, returnMinute: 30, returnDuration: 274, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT050", tripType: .roundTrip, origin: "ATL", destination: "SFO", departureDayOffset: 0, departureHour: 16, departureMinute: 40, durationMinutes: 305, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1198, badges: [], returnDayOffset: 4, returnHour: 8, returnMinute: 15, returnDuration: 268, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  New airport round-trips
            // ═══════════════════════════════════════════════════════════

            // ── ATL → AUS ─────────────────────────────────────────────
            buildItinerary(id: "RT051", tripType: .roundTrip, origin: "ATL", destination: "AUS", departureDayOffset: 0, departureHour: 10, departureMinute: 40, durationMinutes: 158, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: ["Best Value"], returnDayOffset: 3, returnHour: 14, returnMinute: 0, returnDuration: 148, returnStops: 0, returnConnection: nil),
            // ── ATL → TPA ─────────────────────────────────────────────
            buildItinerary(id: "RT052", tripType: .roundTrip, origin: "ATL", destination: "TPA", departureDayOffset: 0, departureHour: 8, departureMinute: 25, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Best Value"], returnDayOffset: 3, returnHour: 16, returnMinute: 10, returnDuration: 85, returnStops: 0, returnConnection: nil),
            // ── ATL → RDU ─────────────────────────────────────────────
            buildItinerary(id: "RT053", tripType: .roundTrip, origin: "ATL", destination: "RDU", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 78, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: ["Main Cabin"], returnDayOffset: 2, returnHour: 17, returnMinute: 30, returnDuration: 82, returnStops: 0, returnConnection: nil),
            // ── ATL → SAN ─────────────────────────────────────────────
            buildItinerary(id: "RT054", tripType: .roundTrip, origin: "ATL", destination: "SAN", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 278, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: ["Best Value"], returnDayOffset: 4, returnHour: 11, returnMinute: 45, returnDuration: 252, returnStops: 0, returnConnection: nil),
            // ── JFK → BNA ─────────────────────────────────────────────
            buildItinerary(id: "RT055", tripType: .roundTrip, origin: "JFK", destination: "BNA", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 378, badges: [], returnDayOffset: 4, returnHour: 15, returnMinute: 0, returnDuration: 138, returnStops: 0, returnConnection: nil),
            // ── BOS → MCO ─────────────────────────────────────────────
            buildItinerary(id: "RT056", tripType: .roundTrip, origin: "BOS", destination: "MCO", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: ["Best Value"], returnDayOffset: 4, returnHour: 14, returnMinute: 30, returnDuration: 192, returnStops: 0, returnConnection: nil),
            // ── ORD → MCO ─────────────────────────────────────────────
            buildItinerary(id: "RT057", tripType: .roundTrip, origin: "ORD", destination: "MCO", departureDayOffset: 1, departureHour: 8, departureMinute: 15, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: [], returnDayOffset: 5, returnHour: 12, returnMinute: 0, returnDuration: 182, returnStops: 0, returnConnection: nil),
            // ── PHX → JFK via ATL ─────────────────────────────────────
            buildItinerary(id: "RT058", tripType: .roundTrip, origin: "PHX", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 378, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 498, badges: [], returnDayOffset: 4, returnHour: 8, returnMinute: 30, returnDuration: 362, returnStops: 1, returnConnection: "ATL"),
            // ── MSY → JFK via ATL ─────────────────────────────────────
            buildItinerary(id: "RT059", tripType: .roundTrip, origin: "MSY", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 20, durationMinutes: 298, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 418, badges: [], returnDayOffset: 3, returnHour: 16, returnMinute: 0, returnDuration: 292, returnStops: 1, returnConnection: "ATL"),
            // ── EWR → LAX ─────────────────────────────────────────────
            buildItinerary(id: "RT060", tripType: .roundTrip, origin: "EWR", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 345, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 578, badges: ["Best Value"], returnDayOffset: 4, returnHour: 10, returnMinute: 0, returnDuration: 298, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Premium cabin round-trips
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "RT061", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 15, departureMinute: 10, durationMinutes: 287, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 368, badges: [], returnDayOffset: 3, returnHour: 9, returnMinute: 45, returnDuration: 254, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT062", tripType: .roundTrip, origin: "JFK", destination: "LAX", departureDayOffset: 0, departureHour: 20, departureMinute: 30, durationMinutes: 338, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1898, badges: [], returnDayOffset: 4, returnHour: 22, returnMinute: 0, returnDuration: 292, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT063", tripType: .roundTrip, origin: "JFK", destination: "SFO", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 362, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1348, badges: [], returnDayOffset: 4, returnHour: 10, returnMinute: 0, returnDuration: 332, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT064", tripType: .roundTrip, origin: "ATL", destination: "JFK", departureDayOffset: 0, departureHour: 6, departureMinute: 10, durationMinutes: 125, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 628, badges: [], returnDayOffset: 3, returnHour: 17, returnMinute: 30, returnDuration: 142, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT065", tripType: .roundTrip, origin: "ATL", destination: "SEA", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 312, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 648, badges: [], returnDayOffset: 4, returnHour: 8, returnMinute: 0, returnDuration: 275, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT066", tripType: .roundTrip, origin: "LAX", destination: "HNL", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 340, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 2198, badges: [], returnDayOffset: 5, returnHour: 12, returnMinute: 0, returnDuration: 320, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  More connecting round-trips
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "RT067", tripType: .roundTrip, origin: "BOS", destination: "LAX", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 398, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 478, badges: [], returnDayOffset: 4, returnHour: 9, returnMinute: 30, returnDuration: 372, returnStops: 1, returnConnection: "ATL"),
            buildItinerary(id: "RT068", tripType: .roundTrip, origin: "DCA", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 385, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 518, badges: [], returnDayOffset: 4, returnHour: 11, returnMinute: 0, returnDuration: 362, returnStops: 1, returnConnection: "ATL"),
            buildItinerary(id: "RT069", tripType: .roundTrip, origin: "MIA", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 328, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: ["Best Value"], returnDayOffset: 4, returnHour: 10, returnMinute: 15, returnDuration: 302, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT070", tripType: .roundTrip, origin: "ORD", destination: "SEA", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 262, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: [], returnDayOffset: 5, returnHour: 13, returnMinute: 0, returnDuration: 248, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  More inter-city round-trips
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "RT071", tripType: .roundTrip, origin: "ORD", destination: "MIA", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 388, badges: ["Best Value"], returnDayOffset: 4, returnHour: 14, returnMinute: 0, returnDuration: 198, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT072", tripType: .roundTrip, origin: "DEN", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 458, badges: ["Best Value"], returnDayOffset: 3, returnHour: 16, returnMinute: 30, returnDuration: 248, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT073", tripType: .roundTrip, origin: "SFO", destination: "ORD", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 252, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 418, badges: [], returnDayOffset: 5, returnHour: 10, returnMinute: 30, returnDuration: 262, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT074", tripType: .roundTrip, origin: "LAX", destination: "ORD", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 238, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 438, badges: [], returnDayOffset: 4, returnHour: 11, returnMinute: 0, returnDuration: 268, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT075", tripType: .roundTrip, origin: "MSP", destination: "JFK", departureDayOffset: 1, departureHour: 7, departureMinute: 30, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: [], returnDayOffset: 5, returnHour: 14, returnMinute: 45, returnDuration: 192, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT076", tripType: .roundTrip, origin: "DTW", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 282, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 478, badges: [], returnDayOffset: 4, returnHour: 9, returnMinute: 0, returnDuration: 258, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT077", tripType: .roundTrip, origin: "SLC", destination: "LAX", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 128, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: [], returnDayOffset: 4, returnHour: 15, returnMinute: 30, returnDuration: 138, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT078", tripType: .roundTrip, origin: "SLC", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 362, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 478, badges: [], returnDayOffset: 4, returnHour: 9, returnMinute: 30, returnDuration: 338, returnStops: 1, returnConnection: "ATL"),
            buildItinerary(id: "RT079", tripType: .roundTrip, origin: "LAS", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 298, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: [], returnDayOffset: 4, returnHour: 11, returnMinute: 0, returnDuration: 318, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT080", tripType: .roundTrip, origin: "LAS", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 428, badges: [], returnDayOffset: 3, returnHour: 15, returnMinute: 0, returnDuration: 262, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Day 2–5 round-trips on popular routes
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "RT081", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 2, departureHour: 7, departureMinute: 20, durationMinutes: 286, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 478, badges: ["Best Value"], returnDayOffset: 6, returnHour: 13, returnMinute: 30, returnDuration: 256, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT082", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 3, departureHour: 8, departureMinute: 0, durationMinutes: 288, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 358, badges: [], returnDayOffset: 7, returnHour: 11, returnMinute: 0, returnDuration: 252, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT083", tripType: .roundTrip, origin: "JFK", destination: "LAX", departureDayOffset: 2, departureHour: 9, departureMinute: 0, durationMinutes: 346, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 568, badges: [], returnDayOffset: 6, returnHour: 10, returnMinute: 0, returnDuration: 298, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT084", tripType: .roundTrip, origin: "ATL", destination: "JFK", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 126, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: ["Best Value"], returnDayOffset: 4, returnHour: 18, returnMinute: 0, returnDuration: 142, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT085", tripType: .roundTrip, origin: "ATL", destination: "MIA", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: ["Best Value"], returnDayOffset: 3, returnHour: 14, returnMinute: 0, returnDuration: 124, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT086", tripType: .roundTrip, origin: "ATL", destination: "SFO", departureDayOffset: 2, departureHour: 8, departureMinute: 30, durationMinutes: 302, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 698, badges: [], returnDayOffset: 6, returnHour: 10, returnMinute: 0, returnDuration: 272, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT087", tripType: .roundTrip, origin: "JFK", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 358, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 598, badges: ["Best Value"], returnDayOffset: 4, returnHour: 12, returnMinute: 30, returnDuration: 328, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT088", tripType: .roundTrip, origin: "ATL", destination: "ORD", departureDayOffset: 0, departureHour: 6, departureMinute: 40, durationMinutes: 122, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: ["Best Value"], returnDayOffset: 3, returnHour: 19, returnMinute: 0, returnDuration: 112, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT089", tripType: .roundTrip, origin: "ATL", destination: "DEN", departureDayOffset: 2, departureHour: 9, departureMinute: 0, durationMinutes: 215, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: [], returnDayOffset: 6, returnHour: 12, returnMinute: 30, returnDuration: 196, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT090", tripType: .roundTrip, origin: "ATL", destination: "BOS", departureDayOffset: 0, departureHour: 7, departureMinute: 20, durationMinutes: 156, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: ["Best Value"], returnDayOffset: 3, returnHour: 16, returnMinute: 0, returnDuration: 148, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Underserved airport round-trips
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "RT091", tripType: .roundTrip, origin: "LGA", destination: "MIA", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: ["Best Value"], returnDayOffset: 4, returnHour: 15, returnMinute: 0, returnDuration: 188, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT092", tripType: .roundTrip, origin: "LGA", destination: "ORD", departureDayOffset: 1, departureHour: 8, departureMinute: 15, durationMinutes: 155, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: [], returnDayOffset: 4, returnHour: 16, returnMinute: 30, returnDuration: 148, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT093", tripType: .roundTrip, origin: "PIT", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 20, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: [], returnDayOffset: 3, returnHour: 14, returnMinute: 0, returnDuration: 85, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT094", tripType: .roundTrip, origin: "ATL", destination: "PIT", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 95, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: [], returnDayOffset: 4, returnHour: 17, returnMinute: 45, returnDuration: 98, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT095", tripType: .roundTrip, origin: "SLC", destination: "SEA", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: [], returnDayOffset: 4, returnHour: 14, returnMinute: 0, returnDuration: 122, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT096", tripType: .roundTrip, origin: "ATL", destination: "SLC", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 245, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: ["Best Value"], returnDayOffset: 4, returnHour: 11, returnMinute: 0, returnDuration: 228, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT097", tripType: .roundTrip, origin: "DCA", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 68, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: [], returnDayOffset: 2, returnHour: 18, returnMinute: 30, returnDuration: 72, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT098", tripType: .roundTrip, origin: "DCA", destination: "MIA", departureDayOffset: 1, departureHour: 9, departureMinute: 30, durationMinutes: 168, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: [], returnDayOffset: 5, returnHour: 13, returnMinute: 0, returnDuration: 162, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT099", tripType: .roundTrip, origin: "ATL", destination: "LAS", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 262, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 448, badges: ["Best Value"], returnDayOffset: 4, returnHour: 10, returnMinute: 0, returnDuration: 248, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT100", tripType: .roundTrip, origin: "LAS", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 68, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 168, badges: [], returnDayOffset: 2, returnHour: 16, returnMinute: 0, returnDuration: 72, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT101", tripType: .roundTrip, origin: "EWR", destination: "MIA", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: [], returnDayOffset: 4, returnHour: 14, returnMinute: 30, returnDuration: 186, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT102", tripType: .roundTrip, origin: "ATL", destination: "EWR", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 130, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: [], returnDayOffset: 4, returnHour: 17, returnMinute: 0, returnDuration: 135, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT103", tripType: .roundTrip, origin: "PHX", destination: "LAX", departureDayOffset: 0, departureHour: 10, departureMinute: 45, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: [], returnDayOffset: 3, returnHour: 15, returnMinute: 0, returnDuration: 88, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT104", tripType: .roundTrip, origin: "PHX", destination: "DEN", departureDayOffset: 1, departureHour: 9, departureMinute: 30, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: [], returnDayOffset: 4, returnHour: 12, returnMinute: 0, returnDuration: 142, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT105", tripType: .roundTrip, origin: "ATL", destination: "MSY", departureDayOffset: 0, departureHour: 9, departureMinute: 10, durationMinutes: 93, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 328, badges: [], returnDayOffset: 3, returnHour: 16, returnMinute: 30, returnDuration: 98, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT106", tripType: .roundTrip, origin: "BNA", destination: "JFK", departureDayOffset: 1, departureHour: 7, departureMinute: 30, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: [], returnDayOffset: 4, returnHour: 15, returnMinute: 0, returnDuration: 142, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT107", tripType: .roundTrip, origin: "AUS", destination: "LAX", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 195, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: [], returnDayOffset: 4, returnHour: 13, returnMinute: 0, returnDuration: 202, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT108", tripType: .roundTrip, origin: "TPA", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: [], returnDayOffset: 3, returnHour: 16, returnMinute: 30, returnDuration: 168, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT109", tripType: .roundTrip, origin: "RDU", destination: "JFK", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: [], returnDayOffset: 3, returnHour: 14, returnMinute: 0, returnDuration: 102, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT110", tripType: .roundTrip, origin: "SAN", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 252, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: [], returnDayOffset: 4, returnHour: 10, returnMinute: 0, returnDuration: 278, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT111", tripType: .roundTrip, origin: "SFO", destination: "HNL", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 328, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 698, badges: ["Best Value"], returnDayOffset: 5, returnHour: 11, returnMinute: 0, returnDuration: 312, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT112", tripType: .roundTrip, origin: "ATL", destination: "HNL", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 578, stops: 1, connection: "LAX", cabin: .mainCabin, fareBrand: "Main", price: 798, badges: [], returnDayOffset: 5, returnHour: 9, returnMinute: 0, returnDuration: 548, returnStops: 1, returnConnection: "LAX"),

            // ═══════════════════════════════════════════════════════════
            //  Day 3–5 round-trips
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "RT113", tripType: .roundTrip, origin: "ATL", destination: "JFK", departureDayOffset: 3, departureHour: 8, departureMinute: 0, durationMinutes: 127, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: ["Best Value"], returnDayOffset: 6, returnHour: 17, returnMinute: 30, returnDuration: 140, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT114", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 4, departureHour: 7, departureMinute: 30, durationMinutes: 286, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: ["Best Value"], returnDayOffset: 8, returnHour: 12, returnMinute: 0, returnDuration: 254, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT115", tripType: .roundTrip, origin: "ATL", destination: "JFK", departureDayOffset: 5, departureHour: 9, departureMinute: 0, durationMinutes: 130, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: [], returnDayOffset: 8, returnHour: 18, returnMinute: 0, returnDuration: 138, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT116", tripType: .roundTrip, origin: "JFK", destination: "LAX", departureDayOffset: 5, departureHour: 8, departureMinute: 0, durationMinutes: 346, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 598, badges: [], returnDayOffset: 9, returnHour: 10, returnMinute: 0, returnDuration: 300, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT117", tripType: .roundTrip, origin: "ATL", destination: "MIA", departureDayOffset: 3, departureHour: 8, departureMinute: 0, durationMinutes: 118, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: [], returnDayOffset: 6, returnHour: 14, returnMinute: 0, returnDuration: 124, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT118", tripType: .roundTrip, origin: "ATL", destination: "SFO", departureDayOffset: 3, departureHour: 7, departureMinute: 15, durationMinutes: 301, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 528, badges: [], returnDayOffset: 7, returnHour: 11, returnMinute: 0, returnDuration: 272, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  More cabin diversity in round-trips (Basic, SkyTrip One)
            // ═══════════════════════════════════════════════════════════
            buildItinerary(id: "RT119", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 288, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 378, badges: [], returnDayOffset: 3, returnHour: 10, returnMinute: 0, returnDuration: 254, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT120", tripType: .roundTrip, origin: "JFK", destination: "LAX", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 345, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 448, badges: [], returnDayOffset: 5, returnHour: 8, returnMinute: 30, returnDuration: 298, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT121", tripType: .roundTrip, origin: "ATL", destination: "MIA", departureDayOffset: 0, departureHour: 11, departureMinute: 0, durationMinutes: 120, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 188, badges: [], returnDayOffset: 3, returnHour: 15, returnMinute: 0, returnDuration: 122, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT122", tripType: .roundTrip, origin: "ATL", destination: "ORD", departureDayOffset: 0, departureHour: 13, departureMinute: 0, durationMinutes: 118, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 198, badges: [], returnDayOffset: 2, returnHour: 19, returnMinute: 0, returnDuration: 112, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT123", tripType: .roundTrip, origin: "ATL", destination: "JFK", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 128, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 898, badges: [], returnDayOffset: 3, returnHour: 16, returnMinute: 0, returnDuration: 140, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT124", tripType: .roundTrip, origin: "ATL", destination: "SFO", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 300, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1498, badges: [], returnDayOffset: 5, returnHour: 10, returnMinute: 0, returnDuration: 272, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT125", tripType: .roundTrip, origin: "JFK", destination: "SFO", departureDayOffset: 1, departureHour: 7, departureMinute: 0, durationMinutes: 362, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1698, badges: [], returnDayOffset: 5, returnHour: 12, returnMinute: 0, returnDuration: 332, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT126", tripType: .roundTrip, origin: "ATL", destination: "LAX", departureDayOffset: 2, departureHour: 10, departureMinute: 0, durationMinutes: 288, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 618, badges: [], returnDayOffset: 6, returnHour: 9, returnMinute: 0, returnDuration: 254, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT127", tripType: .roundTrip, origin: "JFK", destination: "MIA", departureDayOffset: 0, departureHour: 15, departureMinute: 0, durationMinutes: 188, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 628, badges: [], returnDayOffset: 4, returnHour: 9, returnMinute: 30, returnDuration: 178, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT128", tripType: .roundTrip, origin: "ATL", destination: "DEN", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 215, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 628, badges: [], returnDayOffset: 3, returnHour: 10, returnMinute: 30, returnDuration: 196, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT129", tripType: .roundTrip, origin: "ATL", destination: "JFK", departureDayOffset: 0, departureHour: 15, departureMinute: 30, durationMinutes: 130, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 198, badges: [], returnDayOffset: 3, returnHour: 8, returnMinute: 0, returnDuration: 138, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT130", tripType: .roundTrip, origin: "ATL", destination: "SFO", departureDayOffset: 0, departureHour: 20, departureMinute: 0, durationMinutes: 308, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 398, badges: [], returnDayOffset: 4, returnHour: 7, returnMinute: 0, returnDuration: 268, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  SFO-based round-trips (past trip history)
            // ═══════════════════════════════════════════════════════════

            // ── SFO → SEA (business) ────────────────────────────────
            buildItinerary(id: "RT131", tripType: .roundTrip, origin: "SFO", destination: "SEA", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 145, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 348, badges: [], returnDayOffset: 1, returnHour: 18, returnMinute: 30, returnDuration: 138, returnStops: 0, returnConnection: nil),
            // ── SFO → JFK (business) ────────────────────────────────
            buildItinerary(id: "RT132", tripType: .roundTrip, origin: "SFO", destination: "JFK", departureDayOffset: 0, departureHour: 6, departureMinute: 45, durationMinutes: 318, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 489, badges: ["Best Value"], returnDayOffset: 2, returnHour: 19, returnMinute: 15, returnDuration: 352, returnStops: 0, returnConnection: nil),
            // ── SFO → ORD (business) ────────────────────────────────
            buildItinerary(id: "RT133", tripType: .roundTrip, origin: "SFO", destination: "ORD", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 255, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 412, badges: [], returnDayOffset: 1, returnHour: 17, returnMinute: 45, returnDuration: 268, returnStops: 0, returnConnection: nil),
            // ── SFO → ATL (Thanksgiving) ────────────────────────────
            buildItinerary(id: "RT134", tripType: .roundTrip, origin: "SFO", destination: "ATL", departureDayOffset: 0, departureHour: 6, departureMinute: 30, durationMinutes: 274, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 542, badges: [], returnDayOffset: 4, returnHour: 14, returnMinute: 0, returnDuration: 302, returnStops: 0, returnConnection: nil),
            // ── SFO → BOS (Christmas) ───────────────────────────────
            buildItinerary(id: "RT135", tripType: .roundTrip, origin: "SFO", destination: "BOS", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 338, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 598, badges: [], returnDayOffset: 5, returnHour: 12, returnMinute: 0, returnDuration: 362, returnStops: 0, returnConnection: nil),
            // ── SFO → LAX (weekend) ─────────────────────────────────
            buildItinerary(id: "RT136", tripType: .roundTrip, origin: "SFO", destination: "LAX", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 85, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: [], returnDayOffset: 2, returnHour: 17, returnMinute: 30, returnDuration: 88, returnStops: 0, returnConnection: nil),
            // ── SFO → SAN (weekend) ─────────────────────────────────
            buildItinerary(id: "RT137", tripType: .roundTrip, origin: "SFO", destination: "SAN", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 92, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 218, badges: [], returnDayOffset: 2, returnHour: 16, returnMinute: 45, returnDuration: 95, returnStops: 0, returnConnection: nil),
            // ── SFO → SEA (second business trip) ────────────────────
            buildItinerary(id: "RT138", tripType: .roundTrip, origin: "SFO", destination: "SEA", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 140, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: ["Best Value"], returnDayOffset: 1, returnHour: 19, returnMinute: 0, returnDuration: 135, returnStops: 0, returnConnection: nil),
            // ── SFO → JFK (second business trip) ────────────────────
            buildItinerary(id: "RT139", tripType: .roundTrip, origin: "SFO", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 322, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 568, badges: [], returnDayOffset: 2, returnHour: 20, returnMinute: 0, returnDuration: 348, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  SFO round-trip cabin diversity (benchmark-critical)
            // ═══════════════════════════════════════════════════════════

            // ── SFO → JFK additional cabins ─────────────────────────
            buildItinerary(id: "RT140", tripType: .roundTrip, origin: "SFO", destination: "JFK", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 312, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1298, badges: [], returnDayOffset: 3, returnHour: 18, returnMinute: 0, returnDuration: 348, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT141", tripType: .roundTrip, origin: "SFO", destination: "JFK", departureDayOffset: 1, departureHour: 7, departureMinute: 45, durationMinutes: 318, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 1798, badges: [], returnDayOffset: 4, returnHour: 19, returnMinute: 30, returnDuration: 352, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT142", tripType: .roundTrip, origin: "SFO", destination: "JFK", departureDayOffset: 0, departureHour: 16, departureMinute: 0, durationMinutes: 320, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 389, badges: [], returnDayOffset: 3, returnHour: 8, returnMinute: 0, returnDuration: 345, returnStops: 0, returnConnection: nil),

            // ── SFO → SEA additional cabins ─────────────────────────
            buildItinerary(id: "RT143", tripType: .roundTrip, origin: "SFO", destination: "SEA", departureDayOffset: 0, departureHour: 12, departureMinute: 30, durationMinutes: 142, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 198, badges: [], returnDayOffset: 2, returnHour: 16, returnMinute: 0, returnDuration: 138, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT144", tripType: .roundTrip, origin: "SFO", destination: "SEA", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 140, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 548, badges: [], returnDayOffset: 3, returnHour: 17, returnMinute: 30, returnDuration: 135, returnStops: 0, returnConnection: nil),

            // ── SFO → LAX additional cabins ─────────────────────────
            buildItinerary(id: "RT145", tripType: .roundTrip, origin: "SFO", destination: "LAX", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 82, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 318, badges: [], returnDayOffset: 2, returnHour: 12, returnMinute: 0, returnDuration: 85, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT146", tripType: .roundTrip, origin: "SFO", destination: "LAX", departureDayOffset: 0, departureHour: 20, departureMinute: 0, durationMinutes: 78, stops: 0, connection: nil, cabin: .basicEconomy, fareBrand: "Basic", price: 168, badges: [], returnDayOffset: 2, returnHour: 8, returnMinute: 0, returnDuration: 82, returnStops: 0, returnConnection: nil),

            // ── SFO → ATL additional cabins ─────────────────────────
            buildItinerary(id: "RT147", tripType: .roundTrip, origin: "SFO", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 268, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 698, badges: [], returnDayOffset: 4, returnHour: 11, returnMinute: 30, returnDuration: 298, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT148", tripType: .roundTrip, origin: "SFO", destination: "ATL", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 272, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1148, badges: [], returnDayOffset: 5, returnHour: 10, returnMinute: 0, returnDuration: 302, returnStops: 0, returnConnection: nil),

            // ── SFO → ORD additional cabins ─────────────────────────
            buildItinerary(id: "RT149", tripType: .roundTrip, origin: "SFO", destination: "ORD", departureDayOffset: 0, departureHour: 12, departureMinute: 0, durationMinutes: 255, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 548, badges: [], returnDayOffset: 3, returnHour: 16, returnMinute: 0, returnDuration: 268, returnStops: 0, returnConnection: nil),

            // ── SFO → HNL additional cabins ─────────────────────────
            buildItinerary(id: "RT150", tripType: .roundTrip, origin: "SFO", destination: "HNL", departureDayOffset: 0, departureHour: 13, departureMinute: 30, durationMinutes: 332, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 1398, badges: [], returnDayOffset: 5, returnHour: 15, returnMinute: 0, returnDuration: 318, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Transatlantic round-trips
            // ═══════════════════════════════════════════════════════════

            // ── JFK → LHR ───────────────────────────────────────────
            buildItinerary(id: "RT200", tripType: .roundTrip, origin: "JFK", destination: "LHR", departureDayOffset: 0, departureHour: 19, departureMinute: 15, durationMinutes: 415, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 898, badges: ["Best Value"], returnDayOffset: 5, returnHour: 9, returnMinute: 30, returnDuration: 490, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT201", tripType: .roundTrip, origin: "JFK", destination: "LHR", departureDayOffset: 0, departureHour: 22, departureMinute: 30, durationMinutes: 405, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 5498, badges: [], returnDayOffset: 5, returnHour: 11, returnMinute: 0, returnDuration: 485, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT202", tripType: .roundTrip, origin: "JFK", destination: "LHR", departureDayOffset: 1, departureHour: 8, departureMinute: 0, durationMinutes: 420, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 1198, badges: [], returnDayOffset: 6, returnHour: 10, returnMinute: 0, returnDuration: 488, returnStops: 0, returnConnection: nil),

            // ── ATL → LHR ───────────────────────────────────────────
            buildItinerary(id: "RT203", tripType: .roundTrip, origin: "ATL", destination: "LHR", departureDayOffset: 0, departureHour: 18, departureMinute: 45, durationMinutes: 505, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 948, badges: ["Best Value"], returnDayOffset: 5, returnHour: 10, returnMinute: 15, returnDuration: 575, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT204", tripType: .roundTrip, origin: "ATL", destination: "LHR", departureDayOffset: 1, departureHour: 21, departureMinute: 10, durationMinutes: 498, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 5898, badges: [], returnDayOffset: 6, returnHour: 9, returnMinute: 30, returnDuration: 580, returnStops: 0, returnConnection: nil),

            // ── JFK → CDG ───────────────────────────────────────────
            buildItinerary(id: "RT205", tripType: .roundTrip, origin: "JFK", destination: "CDG", departureDayOffset: 0, departureHour: 18, departureMinute: 30, durationMinutes: 440, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 928, badges: ["Best Value"], returnDayOffset: 5, returnHour: 10, returnMinute: 0, returnDuration: 510, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT206", tripType: .roundTrip, origin: "JFK", destination: "CDG", departureDayOffset: 0, departureHour: 23, departureMinute: 0, durationMinutes: 432, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 5998, badges: [], returnDayOffset: 5, returnHour: 12, returnMinute: 30, returnDuration: 505, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT207", tripType: .roundTrip, origin: "ATL", destination: "CDG", departureDayOffset: 0, departureHour: 17, departureMinute: 50, durationMinutes: 530, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 998, badges: [], returnDayOffset: 5, returnHour: 9, returnMinute: 0, returnDuration: 590, returnStops: 0, returnConnection: nil),

            // ── JFK → AMS ───────────────────────────────────────────
            buildItinerary(id: "RT208", tripType: .roundTrip, origin: "JFK", destination: "AMS", departureDayOffset: 0, departureHour: 19, departureMinute: 0, durationMinutes: 445, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 878, badges: ["Best Value"], returnDayOffset: 5, returnHour: 10, returnMinute: 30, returnDuration: 520, returnStops: 0, returnConnection: nil),

            // ── JFK → FCO ───────────────────────────────────────────
            buildItinerary(id: "RT209", tripType: .roundTrip, origin: "JFK", destination: "FCO", departureDayOffset: 0, departureHour: 20, departureMinute: 30, durationMinutes: 530, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 978, badges: ["Best Value"], returnDayOffset: 5, returnHour: 10, returnMinute: 0, returnDuration: 610, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT210", tripType: .roundTrip, origin: "JFK", destination: "FCO", departureDayOffset: 1, departureHour: 17, departureMinute: 15, durationMinutes: 535, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 6898, badges: [], returnDayOffset: 6, returnHour: 10, returnMinute: 30, returnDuration: 605, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Transpacific round-trips
            // ═══════════════════════════════════════════════════════════

            // ── LAX → NRT ───────────────────────────────────────────
            buildItinerary(id: "RT211", tripType: .roundTrip, origin: "LAX", destination: "NRT", departureDayOffset: 0, departureHour: 11, departureMinute: 30, durationMinutes: 690, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1198, badges: ["Best Value"], returnDayOffset: 6, returnHour: 17, returnMinute: 0, returnDuration: 600, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT212", tripType: .roundTrip, origin: "LAX", destination: "NRT", departureDayOffset: 1, departureHour: 13, departureMinute: 0, durationMinutes: 685, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 7498, badges: [], returnDayOffset: 7, returnHour: 18, returnMinute: 0, returnDuration: 595, returnStops: 0, returnConnection: nil),

            // ── SFO → NRT ───────────────────────────────────────────
            buildItinerary(id: "RT213", tripType: .roundTrip, origin: "SFO", destination: "NRT", departureDayOffset: 0, departureHour: 13, departureMinute: 0, durationMinutes: 660, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1148, badges: ["Best Value"], returnDayOffset: 6, returnHour: 16, returnMinute: 0, returnDuration: 585, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT214", tripType: .roundTrip, origin: "SFO", destination: "NRT", departureDayOffset: 1, departureHour: 11, departureMinute: 30, durationMinutes: 668, stops: 0, connection: nil, cabin: .firstClass, fareBrand: "First", price: 4298, badges: [], returnDayOffset: 7, returnHour: 17, returnMinute: 30, returnDuration: 590, returnStops: 0, returnConnection: nil),

            // ── LAX → ICN ───────────────────────────────────────────
            buildItinerary(id: "RT215", tripType: .roundTrip, origin: "LAX", destination: "ICN", departureDayOffset: 0, departureHour: 12, departureMinute: 45, durationMinutes: 745, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1248, badges: ["Best Value"], returnDayOffset: 6, returnHour: 10, returnMinute: 0, returnDuration: 650, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT216", tripType: .roundTrip, origin: "LAX", destination: "ICN", departureDayOffset: 1, departureHour: 10, departureMinute: 30, durationMinutes: 750, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 7898, badges: [], returnDayOffset: 7, returnHour: 11, returnMinute: 0, returnDuration: 645, returnStops: 0, returnConnection: nil),

            // ── SEA → NRT ───────────────────────────────────────────
            buildItinerary(id: "RT217", tripType: .roundTrip, origin: "SEA", destination: "NRT", departureDayOffset: 0, departureHour: 12, departureMinute: 15, durationMinutes: 625, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1098, badges: [], returnDayOffset: 6, returnHour: 16, returnMinute: 30, returnDuration: 580, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Latin America & Caribbean round-trips
            // ═══════════════════════════════════════════════════════════

            // ── ATL → CUN ───────────────────────────────────────────
            buildItinerary(id: "RT218", tripType: .roundTrip, origin: "ATL", destination: "CUN", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 188, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 448, badges: ["Best Value"], returnDayOffset: 4, returnHour: 15, returnMinute: 30, returnDuration: 195, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT219", tripType: .roundTrip, origin: "ATL", destination: "CUN", departureDayOffset: 0, departureHour: 14, departureMinute: 15, durationMinutes: 192, stops: 0, connection: nil, cabin: .comfortPlus, fareBrand: "Comfort+", price: 598, badges: [], returnDayOffset: 4, returnHour: 10, returnMinute: 0, returnDuration: 198, returnStops: 0, returnConnection: nil),
            // ── JFK → CUN ───────────────────────────────────────────
            buildItinerary(id: "RT220", tripType: .roundTrip, origin: "JFK", destination: "CUN", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: ["Best Value"], returnDayOffset: 5, returnHour: 14, returnMinute: 0, returnDuration: 258, returnStops: 0, returnConnection: nil),

            // ── ATL → MEX ───────────────────────────────────────────
            buildItinerary(id: "RT221", tripType: .roundTrip, origin: "ATL", destination: "MEX", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 528, badges: ["Best Value"], returnDayOffset: 4, returnHour: 7, returnMinute: 30, returnDuration: 238, returnStops: 0, returnConnection: nil),

            // ── ATL → GRU ───────────────────────────────────────────
            buildItinerary(id: "RT222", tripType: .roundTrip, origin: "ATL", destination: "GRU", departureDayOffset: 0, departureHour: 21, departureMinute: 0, durationMinutes: 620, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1198, badges: ["Best Value"], returnDayOffset: 6, returnHour: 22, returnMinute: 0, returnDuration: 595, returnStops: 0, returnConnection: nil),
            buildItinerary(id: "RT223", tripType: .roundTrip, origin: "ATL", destination: "GRU", departureDayOffset: 1, departureHour: 22, departureMinute: 30, durationMinutes: 615, stops: 0, connection: nil, cabin: .deltaOne, fareBrand: "SkyTrip One", price: 6498, badges: [], returnDayOffset: 7, returnHour: 21, returnMinute: 30, returnDuration: 600, returnStops: 0, returnConnection: nil),

            // ── JFK → BOG ───────────────────────────────────────────
            buildItinerary(id: "RT224", tripType: .roundTrip, origin: "JFK", destination: "BOG", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 332, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 598, badges: ["Best Value"], returnDayOffset: 5, returnHour: 8, returnMinute: 0, returnDuration: 345, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Canada round-trips
            // ═══════════════════════════════════════════════════════════

            // ── JFK → YYZ ───────────────────────────────────────────
            buildItinerary(id: "RT225", tripType: .roundTrip, origin: "JFK", destination: "YYZ", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 95, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 328, badges: ["Best Value"], returnDayOffset: 3, returnHour: 14, returnMinute: 0, returnDuration: 98, returnStops: 0, returnConnection: nil),
            // ── ATL → YYZ ───────────────────────────────────────────
            buildItinerary(id: "RT226", tripType: .roundTrip, origin: "ATL", destination: "YYZ", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 135, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 378, badges: [], returnDayOffset: 3, returnHour: 15, returnMinute: 30, returnDuration: 138, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Connecting international round-trips via hubs
            // ═══════════════════════════════════════════════════════════

            // ── SFO → LHR via JFK ───────────────────────────────────
            buildItinerary(id: "RT227", tripType: .roundTrip, origin: "SFO", destination: "LHR", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 895, stops: 1, connection: "JFK", cabin: .mainCabin, fareBrand: "Main", price: 1098, badges: [], returnDayOffset: 6, returnHour: 9, returnMinute: 30, returnDuration: 870, returnStops: 1, returnConnection: "JFK"),
            // ── LAX → CDG via ATL ───────────────────────────────────
            buildItinerary(id: "RT228", tripType: .roundTrip, origin: "LAX", destination: "CDG", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 945, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 1148, badges: [], returnDayOffset: 6, returnHour: 10, returnMinute: 0, returnDuration: 920, returnStops: 1, returnConnection: "ATL"),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: RT FROM international airports (all had zero)
            // ═══════════════════════════════════════════════════════════

            // ── LHR → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT300", tripType: .roundTrip, origin: "LHR", destination: "JFK", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 490, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 878, badges: ["Best Value"], returnDayOffset: 5, returnHour: 19, returnMinute: 15, returnDuration: 415, returnStops: 0, returnConnection: nil),
            // ── LHR → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT301", tripType: .roundTrip, origin: "LHR", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 575, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 928, badges: [], returnDayOffset: 5, returnHour: 18, returnMinute: 45, returnDuration: 505, returnStops: 0, returnConnection: nil),
            // ── LHR → ORD ───────────────────────────────────────────
            buildItinerary(id: "RT302", tripType: .roundTrip, origin: "LHR", destination: "ORD", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 545, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 898, badges: [], returnDayOffset: 5, returnHour: 18, returnMinute: 30, returnDuration: 475, returnStops: 0, returnConnection: nil),

            // ── CDG → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT303", tripType: .roundTrip, origin: "CDG", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 510, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 908, badges: ["Best Value"], returnDayOffset: 5, returnHour: 18, returnMinute: 30, returnDuration: 440, returnStops: 0, returnConnection: nil),
            // ── CDG → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT304", tripType: .roundTrip, origin: "CDG", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 595, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 978, badges: [], returnDayOffset: 5, returnHour: 17, returnMinute: 50, returnDuration: 530, returnStops: 0, returnConnection: nil),

            // ── AMS → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT305", tripType: .roundTrip, origin: "AMS", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 520, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 858, badges: ["Best Value"], returnDayOffset: 5, returnHour: 19, returnMinute: 0, returnDuration: 445, returnStops: 0, returnConnection: nil),
            // ── AMS → MSP ───────────────────────────────────────────
            buildItinerary(id: "RT306", tripType: .roundTrip, origin: "AMS", destination: "MSP", departureDayOffset: 0, departureHour: 10, departureMinute: 15, durationMinutes: 585, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 928, badges: [], returnDayOffset: 5, returnHour: 18, returnMinute: 0, returnDuration: 508, returnStops: 0, returnConnection: nil),

            // ── FCO → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT307", tripType: .roundTrip, origin: "FCO", destination: "JFK", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 610, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 958, badges: ["Best Value"], returnDayOffset: 5, returnHour: 20, returnMinute: 30, returnDuration: 530, returnStops: 0, returnConnection: nil),

            // ── NRT → LAX ───────────────────────────────────────────
            buildItinerary(id: "RT308", tripType: .roundTrip, origin: "NRT", destination: "LAX", departureDayOffset: 0, departureHour: 17, departureMinute: 0, durationMinutes: 600, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1178, badges: ["Best Value"], returnDayOffset: 6, returnHour: 11, returnMinute: 30, returnDuration: 690, returnStops: 0, returnConnection: nil),
            // ── NRT → SFO ───────────────────────────────────────────
            buildItinerary(id: "RT309", tripType: .roundTrip, origin: "NRT", destination: "SFO", departureDayOffset: 0, departureHour: 16, departureMinute: 30, durationMinutes: 585, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1128, badges: [], returnDayOffset: 6, returnHour: 13, returnMinute: 0, returnDuration: 660, returnStops: 0, returnConnection: nil),

            // ── ICN → LAX ───────────────────────────────────────────
            buildItinerary(id: "RT310", tripType: .roundTrip, origin: "ICN", destination: "LAX", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 650, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1228, badges: ["Best Value"], returnDayOffset: 6, returnHour: 12, returnMinute: 45, returnDuration: 745, returnStops: 0, returnConnection: nil),

            // ── CUN → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT311", tripType: .roundTrip, origin: "CUN", destination: "ATL", departureDayOffset: 0, departureHour: 15, departureMinute: 30, durationMinutes: 195, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 428, badges: ["Best Value"], returnDayOffset: 4, returnHour: 8, returnMinute: 30, returnDuration: 188, returnStops: 0, returnConnection: nil),
            // ── CUN → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT312", tripType: .roundTrip, origin: "CUN", destination: "JFK", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 258, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 478, badges: [], returnDayOffset: 5, returnHour: 9, returnMinute: 0, returnDuration: 248, returnStops: 0, returnConnection: nil),

            // ── MEX → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT313", tripType: .roundTrip, origin: "MEX", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 238, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 508, badges: ["Best Value"], returnDayOffset: 4, returnHour: 10, returnMinute: 0, returnDuration: 248, returnStops: 0, returnConnection: nil),

            // ── GRU → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT314", tripType: .roundTrip, origin: "GRU", destination: "ATL", departureDayOffset: 0, departureHour: 22, departureMinute: 0, durationMinutes: 595, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1178, badges: ["Best Value"], returnDayOffset: 6, returnHour: 21, returnMinute: 0, returnDuration: 620, returnStops: 0, returnConnection: nil),

            // ── BOG → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT315", tripType: .roundTrip, origin: "BOG", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 345, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 578, badges: ["Best Value"], returnDayOffset: 5, returnHour: 8, returnMinute: 45, returnDuration: 332, returnStops: 0, returnConnection: nil),
            // ── BOG → MIA ───────────────────────────────────────────
            buildItinerary(id: "RT316", tripType: .roundTrip, origin: "BOG", destination: "MIA", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 245, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 478, badges: [], returnDayOffset: 4, returnHour: 10, returnMinute: 30, returnDuration: 238, returnStops: 0, returnConnection: nil),

            // ── YYZ → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT317", tripType: .roundTrip, origin: "YYZ", destination: "JFK", departureDayOffset: 0, departureHour: 14, departureMinute: 0, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: ["Best Value"], returnDayOffset: 3, returnHour: 7, returnMinute: 30, returnDuration: 95, returnStops: 0, returnConnection: nil),
            // ── YYZ → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT318", tripType: .roundTrip, origin: "YYZ", destination: "ATL", departureDayOffset: 0, departureHour: 13, departureMinute: 0, durationMinutes: 138, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 368, badges: [], returnDayOffset: 3, returnHour: 9, returnMinute: 15, returnDuration: 135, returnStops: 0, returnConnection: nil),
            // ── YYZ → ORD ───────────────────────────────────────────
            buildItinerary(id: "RT319", tripType: .roundTrip, origin: "YYZ", destination: "ORD", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 88, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: [], returnDayOffset: 3, returnHour: 10, returnMinute: 0, returnDuration: 82, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: RT FROM HNL and MCO (domestic, had zero)
            // ═══════════════════════════════════════════════════════════

            // ── HNL → LAX ───────────────────────────────────────────
            buildItinerary(id: "RT320", tripType: .roundTrip, origin: "HNL", destination: "LAX", departureDayOffset: 0, departureHour: 11, departureMinute: 0, durationMinutes: 318, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 628, badges: ["Best Value"], returnDayOffset: 5, returnHour: 9, returnMinute: 0, returnDuration: 342, returnStops: 0, returnConnection: nil),
            // ── HNL → SFO ───────────────────────────────────────────
            buildItinerary(id: "RT321", tripType: .roundTrip, origin: "HNL", destination: "SFO", departureDayOffset: 0, departureHour: 13, departureMinute: 30, durationMinutes: 312, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 678, badges: [], returnDayOffset: 5, returnHour: 8, returnMinute: 30, returnDuration: 328, returnStops: 0, returnConnection: nil),

            // ── MCO → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT322", tripType: .roundTrip, origin: "MCO", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 94, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 208, badges: ["Best Value"], returnDayOffset: 3, returnHour: 7, returnMinute: 20, returnDuration: 92, returnStops: 0, returnConnection: nil),
            // ── MCO → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT323", tripType: .roundTrip, origin: "MCO", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 168, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 288, badges: [], returnDayOffset: 4, returnHour: 8, returnMinute: 30, returnDuration: 172, returnStops: 0, returnConnection: nil),
            // ── MCO → ORD ───────────────────────────────────────────
            buildItinerary(id: "RT324", tripType: .roundTrip, origin: "MCO", destination: "ORD", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 308, badges: [], returnDayOffset: 4, returnHour: 8, returnMinute: 15, returnDuration: 178, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: RT for ORD/DFW/DEN/MSP international
            // ═══════════════════════════════════════════════════════════

            // ── ORD → LHR ───────────────────────────────────────────
            buildItinerary(id: "RT325", tripType: .roundTrip, origin: "ORD", destination: "LHR", departureDayOffset: 0, departureHour: 18, departureMinute: 30, durationMinutes: 475, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 898, badges: ["Best Value"], returnDayOffset: 5, returnHour: 10, returnMinute: 0, returnDuration: 545, returnStops: 0, returnConnection: nil),
            // ── ORD → CDG ───────────────────────────────────────────
            buildItinerary(id: "RT326", tripType: .roundTrip, origin: "ORD", destination: "CDG", departureDayOffset: 0, departureHour: 19, departureMinute: 15, durationMinutes: 498, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 948, badges: [], returnDayOffset: 5, returnHour: 10, returnMinute: 30, returnDuration: 575, returnStops: 0, returnConnection: nil),
            // ── ORD → NRT ───────────────────────────────────────────
            buildItinerary(id: "RT327", tripType: .roundTrip, origin: "ORD", destination: "NRT", departureDayOffset: 0, departureHour: 12, departureMinute: 0, durationMinutes: 745, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 1248, badges: [], returnDayOffset: 6, returnHour: 17, returnMinute: 0, returnDuration: 665, returnStops: 0, returnConnection: nil),
            // ── ORD → CUN ───────────────────────────────────────────
            buildItinerary(id: "RT328", tripType: .roundTrip, origin: "ORD", destination: "CUN", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 448, badges: ["Best Value"], returnDayOffset: 4, returnHour: 15, returnMinute: 0, returnDuration: 238, returnStops: 0, returnConnection: nil),
            // ── ORD → YYZ ───────────────────────────────────────────
            buildItinerary(id: "RT329", tripType: .roundTrip, origin: "ORD", destination: "YYZ", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: [], returnDayOffset: 3, returnHour: 14, returnMinute: 30, returnDuration: 88, returnStops: 0, returnConnection: nil),

            // ── DFW → CUN ───────────────────────────────────────────
            buildItinerary(id: "RT330", tripType: .roundTrip, origin: "DFW", destination: "CUN", departureDayOffset: 0, departureHour: 9, departureMinute: 0, durationMinutes: 165, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 378, badges: ["Best Value"], returnDayOffset: 4, returnHour: 16, returnMinute: 0, returnDuration: 172, returnStops: 0, returnConnection: nil),
            // ── DFW → MEX ───────────────────────────────────────────
            buildItinerary(id: "RT331", tripType: .roundTrip, origin: "DFW", destination: "MEX", departureDayOffset: 0, departureHour: 10, departureMinute: 30, durationMinutes: 155, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 358, badges: [], returnDayOffset: 4, returnHour: 7, returnMinute: 15, returnDuration: 148, returnStops: 0, returnConnection: nil),
            // ── DFW → YYZ ───────────────────────────────────────────
            buildItinerary(id: "RT332", tripType: .roundTrip, origin: "DFW", destination: "YYZ", departureDayOffset: 1, departureHour: 9, departureMinute: 0, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: [], returnDayOffset: 4, returnHour: 14, returnMinute: 0, returnDuration: 178, returnStops: 0, returnConnection: nil),

            // ── DEN → CUN ───────────────────────────────────────────
            buildItinerary(id: "RT333", tripType: .roundTrip, origin: "DEN", destination: "CUN", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 478, badges: ["Best Value"], returnDayOffset: 4, returnHour: 13, returnMinute: 30, returnDuration: 258, returnStops: 0, returnConnection: nil),
            // ── DEN → MEX ───────────────────────────────────────────
            buildItinerary(id: "RT334", tripType: .roundTrip, origin: "DEN", destination: "MEX", departureDayOffset: 0, departureHour: 9, departureMinute: 30, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 418, badges: [], returnDayOffset: 4, returnHour: 8, returnMinute: 0, returnDuration: 235, returnStops: 0, returnConnection: nil),

            // ── MSP → CUN ───────────────────────────────────────────
            buildItinerary(id: "RT335", tripType: .roundTrip, origin: "MSP", destination: "CUN", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 258, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: ["Best Value"], returnDayOffset: 4, returnHour: 14, returnMinute: 0, returnDuration: 268, returnStops: 0, returnConnection: nil),
            // ── MSP → AMS ───────────────────────────────────────────
            buildItinerary(id: "RT336", tripType: .roundTrip, origin: "MSP", destination: "AMS", departureDayOffset: 0, departureHour: 18, departureMinute: 0, durationMinutes: 508, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 958, badges: [], returnDayOffset: 5, returnHour: 10, returnMinute: 15, returnDuration: 585, returnStops: 0, returnConnection: nil),

            // ═══════════════════════════════════════════════════════════
            //  Gap fills: Key missing hub RT pairs
            // ═══════════════════════════════════════════════════════════

            // ── MIA → LAX ───────────────────────────────────────────
            buildItinerary(id: "RT337", tripType: .roundTrip, origin: "MIA", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 328, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 478, badges: ["Best Value"], returnDayOffset: 4, returnHour: 10, returnMinute: 0, returnDuration: 298, returnStops: 0, returnConnection: nil),
            // ── MIA → SFO ───────────────────────────────────────────
            buildItinerary(id: "RT338", tripType: .roundTrip, origin: "MIA", destination: "SFO", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 382, stops: 1, connection: "ATL", cabin: .mainCabin, fareBrand: "Main", price: 548, badges: [], returnDayOffset: 4, returnHour: 7, returnMinute: 30, returnDuration: 328, returnStops: 0, returnConnection: nil),
            // ── MIA → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT339", tripType: .roundTrip, origin: "MIA", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 185, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: ["Best Value"], returnDayOffset: 3, returnHour: 9, returnMinute: 0, returnDuration: 188, returnStops: 0, returnConnection: nil),
            // ── MIA → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT340", tripType: .roundTrip, origin: "MIA", destination: "ATL", departureDayOffset: 0, departureHour: 14, departureMinute: 30, durationMinutes: 124, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: [], returnDayOffset: 3, returnHour: 7, returnMinute: 45, returnDuration: 118, returnStops: 0, returnConnection: nil),
            // ── LAX → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT341", tripType: .roundTrip, origin: "LAX", destination: "ATL", departureDayOffset: 0, departureHour: 6, departureMinute: 30, durationMinutes: 248, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 478, badges: ["Best Value"], returnDayOffset: 4, returnHour: 7, returnMinute: 0, returnDuration: 286, returnStops: 0, returnConnection: nil),
            // ── LAX → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT342", tripType: .roundTrip, origin: "LAX", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 15, durationMinutes: 298, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 558, badges: ["Best Value"], returnDayOffset: 4, returnHour: 8, returnMinute: 0, returnDuration: 348, returnStops: 0, returnConnection: nil),
            // ── LAX → SEA ───────────────────────────────────────────
            buildItinerary(id: "RT343", tripType: .roundTrip, origin: "LAX", destination: "SEA", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: [], returnDayOffset: 3, returnHour: 8, returnMinute: 30, returnDuration: 172, returnStops: 0, returnConnection: nil),
            // ── LAX → SFO ───────────────────────────────────────────
            buildItinerary(id: "RT344", tripType: .roundTrip, origin: "LAX", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 78, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 198, badges: [], returnDayOffset: 2, returnHour: 8, returnMinute: 30, returnDuration: 76, returnStops: 0, returnConnection: nil),
            // ── JFK → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT345", tripType: .roundTrip, origin: "JFK", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 0, durationMinutes: 142, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: ["Best Value"], returnDayOffset: 3, returnHour: 6, returnMinute: 10, returnDuration: 125, returnStops: 0, returnConnection: nil),
            // ── JFK → ORD ───────────────────────────────────────────
            buildItinerary(id: "RT346", tripType: .roundTrip, origin: "JFK", destination: "ORD", departureDayOffset: 0, departureHour: 12, departureMinute: 0, durationMinutes: 165, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: [], returnDayOffset: 3, returnHour: 9, returnMinute: 30, returnDuration: 148, returnStops: 0, returnConnection: nil),
            // ── SEA → LAX ───────────────────────────────────────────
            buildItinerary(id: "RT347", tripType: .roundTrip, origin: "SEA", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: [], returnDayOffset: 3, returnHour: 8, returnMinute: 45, returnDuration: 178, returnStops: 0, returnConnection: nil),
            // ── SEA → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT348", tripType: .roundTrip, origin: "SEA", destination: "JFK", departureDayOffset: 0, departureHour: 6, departureMinute: 55, durationMinutes: 312, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 498, badges: [], returnDayOffset: 4, returnHour: 8, returnMinute: 0, returnDuration: 358, returnStops: 0, returnConnection: nil),
            // ── SEA → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT349", tripType: .roundTrip, origin: "SEA", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 278, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 478, badges: ["Best Value"], returnDayOffset: 4, returnHour: 8, returnMinute: 15, returnDuration: 308, returnStops: 0, returnConnection: nil),
            // ── BOS → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT350", tripType: .roundTrip, origin: "BOS", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 171, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: ["Best Value"], returnDayOffset: 3, returnHour: 7, returnMinute: 20, returnDuration: 156, returnStops: 0, returnConnection: nil),
            // ── BOS → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT351", tripType: .roundTrip, origin: "BOS", destination: "JFK", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 76, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 238, badges: [], returnDayOffset: 2, returnHour: 7, returnMinute: 30, returnDuration: 74, returnStops: 0, returnConnection: nil),
            // ── BOS → MIA ───────────────────────────────────────────
            buildItinerary(id: "RT352", tripType: .roundTrip, origin: "BOS", destination: "MIA", departureDayOffset: 0, departureHour: 9, departureMinute: 15, durationMinutes: 205, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 378, badges: [], returnDayOffset: 4, returnHour: 8, returnMinute: 0, returnDuration: 198, returnStops: 0, returnConnection: nil),
            // ── ORD → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT353", tripType: .roundTrip, origin: "ORD", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 112, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: ["Best Value"], returnDayOffset: 3, returnHour: 6, returnMinute: 40, returnDuration: 122, returnStops: 0, returnConnection: nil),
            // ── ORD → SFO ───────────────────────────────────────────
            buildItinerary(id: "RT354", tripType: .roundTrip, origin: "ORD", destination: "SFO", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 262, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 428, badges: [], returnDayOffset: 4, returnHour: 7, returnMinute: 30, returnDuration: 252, returnStops: 0, returnConnection: nil),
            // ── DEN → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT355", tripType: .roundTrip, origin: "DEN", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 15, durationMinutes: 228, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 438, badges: ["Best Value"], returnDayOffset: 3, returnHour: 16, returnMinute: 30, returnDuration: 248, returnStops: 0, returnConnection: nil),
            // ── DEN → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT356", tripType: .roundTrip, origin: "DEN", destination: "ATL", departureDayOffset: 0, departureHour: 10, departureMinute: 45, durationMinutes: 192, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 378, badges: [], returnDayOffset: 3, returnHour: 8, returnMinute: 30, returnDuration: 212, returnStops: 0, returnConnection: nil),
            // ── DEN → LAX ───────────────────────────────────────────
            buildItinerary(id: "RT357", tripType: .roundTrip, origin: "DEN", destination: "LAX", departureDayOffset: 0, departureHour: 10, departureMinute: 20, durationMinutes: 178, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: [], returnDayOffset: 3, returnHour: 11, returnMinute: 0, returnDuration: 172, returnStops: 0, returnConnection: nil),
            // ── DEN → SFO ───────────────────────────────────────────
            buildItinerary(id: "RT358", tripType: .roundTrip, origin: "DEN", destination: "SFO", departureDayOffset: 0, departureHour: 8, departureMinute: 45, durationMinutes: 162, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 298, badges: [], returnDayOffset: 3, returnHour: 10, returnMinute: 0, returnDuration: 158, returnStops: 0, returnConnection: nil),
            // ── DEN → SEA ───────────────────────────────────────────
            buildItinerary(id: "RT359", tripType: .roundTrip, origin: "DEN", destination: "SEA", departureDayOffset: 0, departureHour: 9, departureMinute: 10, durationMinutes: 172, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 308, badges: [], returnDayOffset: 3, returnHour: 8, returnMinute: 0, returnDuration: 168, returnStops: 0, returnConnection: nil),
            // ── MSP → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT360", tripType: .roundTrip, origin: "MSP", destination: "ATL", departureDayOffset: 0, departureHour: 7, departureMinute: 50, durationMinutes: 152, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 318, badges: ["Best Value"], returnDayOffset: 3, returnHour: 7, returnMinute: 30, returnDuration: 152, returnStops: 0, returnConnection: nil),
            // ── MSP → ORD ───────────────────────────────────────────
            buildItinerary(id: "RT361", tripType: .roundTrip, origin: "MSP", destination: "ORD", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 82, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 228, badges: [], returnDayOffset: 2, returnHour: 9, returnMinute: 15, returnDuration: 82, returnStops: 0, returnConnection: nil),
            // ── MSP → DEN ───────────────────────────────────────────
            buildItinerary(id: "RT362", tripType: .roundTrip, origin: "MSP", destination: "DEN", departureDayOffset: 0, departureHour: 8, departureMinute: 20, durationMinutes: 152, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: [], returnDayOffset: 3, returnHour: 10, returnMinute: 45, returnDuration: 148, returnStops: 0, returnConnection: nil),
            // ── MSP → SFO ───────────────────────────────────────────
            buildItinerary(id: "RT363", tripType: .roundTrip, origin: "MSP", destination: "SFO", departureDayOffset: 0, departureHour: 7, departureMinute: 30, durationMinutes: 245, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 418, badges: [], returnDayOffset: 4, returnHour: 7, returnMinute: 30, returnDuration: 245, returnStops: 0, returnConnection: nil),
            // ── DFW → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT364", tripType: .roundTrip, origin: "DFW", destination: "ATL", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 132, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 278, badges: ["Best Value"], returnDayOffset: 3, returnHour: 11, returnMinute: 5, returnDuration: 142, returnStops: 0, returnConnection: nil),
            // ── DFW → LAX ───────────────────────────────────────────
            buildItinerary(id: "RT365", tripType: .roundTrip, origin: "DFW", destination: "LAX", departureDayOffset: 0, departureHour: 10, departureMinute: 0, durationMinutes: 198, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 348, badges: [], returnDayOffset: 4, returnHour: 10, returnMinute: 30, returnDuration: 188, returnStops: 0, returnConnection: nil),
            // ── DFW → SFO ───────────────────────────────────────────
            buildItinerary(id: "RT366", tripType: .roundTrip, origin: "DFW", destination: "SFO", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 232, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 398, badges: [], returnDayOffset: 4, returnHour: 9, returnMinute: 15, returnDuration: 218, returnStops: 0, returnConnection: nil),
            // ── DTW → ATL ───────────────────────────────────────────
            buildItinerary(id: "RT367", tripType: .roundTrip, origin: "DTW", destination: "ATL", departureDayOffset: 0, departureHour: 6, departureMinute: 15, durationMinutes: 108, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 258, badges: ["Best Value"], returnDayOffset: 3, returnHour: 7, returnMinute: 35, returnDuration: 108, returnStops: 0, returnConnection: nil),
            // ── DTW → JFK ───────────────────────────────────────────
            buildItinerary(id: "RT368", tripType: .roundTrip, origin: "DTW", destination: "JFK", departureDayOffset: 0, departureHour: 7, departureMinute: 45, durationMinutes: 98, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 268, badges: [], returnDayOffset: 3, returnHour: 17, returnMinute: 45, returnDuration: 117, returnStops: 0, returnConnection: nil),
            // ── DTW → LAX ───────────────────────────────────────────
            buildItinerary(id: "RT369", tripType: .roundTrip, origin: "DTW", destination: "LAX", departureDayOffset: 0, departureHour: 8, departureMinute: 30, durationMinutes: 282, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 458, badges: [], returnDayOffset: 4, returnHour: 9, returnMinute: 0, returnDuration: 258, returnStops: 0, returnConnection: nil),
            // ── DTW → YYZ ───────────────────────────────────────────
            buildItinerary(id: "RT370", tripType: .roundTrip, origin: "DTW", destination: "YYZ", departureDayOffset: 0, departureHour: 8, departureMinute: 0, durationMinutes: 62, stops: 0, connection: nil, cabin: .mainCabin, fareBrand: "Main", price: 248, badges: [], returnDayOffset: 3, returnHour: 10, returnMinute: 30, returnDuration: 65, returnStops: 0, returnConnection: nil)
        ]
    }

    private static func buildItinerary(
        id: String,
        tripType: TripType,
        origin: String,
        destination: String,
        departureDayOffset: Int,
        departureHour: Int,
        departureMinute: Int,
        durationMinutes: Int,
        stops: Int,
        connection: String?,
        cabin: CabinClass,
        fareBrand: String,
        price: Double,
        badges: [String],
        returnDayOffset: Int? = nil,
        returnHour: Int? = nil,
        returnMinute: Int? = nil,
        returnDuration: Int? = nil,
        returnStops: Int = 0,
        returnConnection: String? = nil
    ) -> FlightItinerary {
        let originAirport = airport(origin)
        let destinationAirport = airport(destination)

        let departure = futureDate(daysFromNow: 7 + departureDayOffset, hour: departureHour, minute: departureMinute)
        let outbound = segments(
            idPrefix: "\(id)_OUT",
            origin: originAirport,
            destination: destinationAirport,
            departure: departure,
            durationMinutes: durationMinutes,
            stops: stops,
            connectionCode: connection,
            flightSeed: id
        )

        var returns: [FlightSegment] = []
        if tripType == .roundTrip,
           let returnDayOffset,
           let returnHour,
           let returnMinute,
           let returnDuration {
            let returnDeparture = futureDate(daysFromNow: 7 + returnDayOffset, hour: returnHour, minute: returnMinute)
            returns = segments(
                idPrefix: "\(id)_RET",
                origin: destinationAirport,
                destination: originAirport,
                departure: returnDeparture,
                durationMinutes: returnDuration,
                stops: returnStops,
                connectionCode: returnConnection,
                flightSeed: "R\(id)"
            )
        }

        return FlightItinerary(
            id: id,
            tripType: tripType,
            origin: originAirport,
            destination: destinationAirport,
            outboundSegments: outbound,
            returnSegments: returns,
            fare: FareOption(cabin: cabin, fareBrand: fareBrand, price: price, currency: "USD"),
            badges: badges,
            sourceType: .seeded
        )
    }

    private static func segments(
        idPrefix: String,
        origin: Airport,
        destination: Airport,
        departure: Date,
        durationMinutes: Int,
        stops: Int,
        connectionCode: String?,
        flightSeed: String
    ) -> [FlightSegment] {
        if stops == 0 {
            return [
                segment(
                    id: "\(idPrefix)_1",
                    carrierCode: "DL",
                    flightNumber: flightNumber(from: flightSeed, leg: 1),
                    origin: origin,
                    destination: destination,
                    departure: departure,
                    durationMinutes: durationMinutes,
                    terminal: defaultTerminal(for: origin.code),
                    gate: defaultGate(for: origin.code, leg: 1),
                    stops: 0
                )
            ]
        }

        let connection = airport(connectionCode ?? "ATL")
        let firstDuration = max(65, durationMinutes / 2)
        let secondDuration = max(55, durationMinutes - firstDuration)
        let secondDeparture = departure.addingTimeInterval(TimeInterval((firstDuration + 55) * 60))

        return [
            segment(
                id: "\(idPrefix)_1",
                carrierCode: "DL",
                flightNumber: flightNumber(from: flightSeed, leg: 1),
                origin: origin,
                destination: connection,
                departure: departure,
                durationMinutes: firstDuration,
                terminal: defaultTerminal(for: origin.code),
                gate: defaultGate(for: origin.code, leg: 1),
                stops: 0
            ),
            segment(
                id: "\(idPrefix)_2",
                carrierCode: "DL",
                flightNumber: flightNumber(from: flightSeed, leg: 2),
                origin: connection,
                destination: destination,
                departure: secondDeparture,
                durationMinutes: secondDuration,
                terminal: defaultTerminal(for: connection.code),
                gate: defaultGate(for: connection.code, leg: 2),
                stops: 0
            )
        ]
    }

    private static func segment(
        id: String,
        carrierCode: String,
        flightNumber: String,
        origin: Airport,
        destination: Airport,
        departure: Date,
        durationMinutes: Int,
        terminal: String,
        gate: String,
        stops: Int
    ) -> FlightSegment {
        FlightSegment(
            id: id,
            carrierCode: carrierCode,
            flightNumber: flightNumber,
            origin: origin,
            destination: destination,
            departureTime: departure,
            arrivalTime: departure.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            durationMinutes: durationMinutes,
            terminal: terminal,
            gate: gate,
            stops: stops,
            status: .onTime
        )
    }

    private static func airport(_ code: String) -> Airport {
        guard let airport = airports.first(where: { $0.code == code }) else {
            print("[SeedData] Missing airport \(code), using fallback")
            return Airport(id: code, code: code, city: code, name: code, state: "")
        }
        return airport
    }

    private static func flightNumber(from seed: String, leg: Int) -> String {
        let digits = seed.unicodeScalars.map { Int($0.value) }.reduce(0, +)
        return String(format: "%04d", (digits + (leg * 37)) % 9000 + 1000)
    }

    private static func defaultTerminal(for airportCode: String) -> String {
        switch airportCode {
        case "ATL": return "S"
        case "JFK": return "4"
        case "LGA": return "C"
        case "LAX": return "3"
        case "SFO": return "2"
        case "SEA": return "A"
        case "BOS": return "A"
        case "ORD": return "2"
        case "DCA": return "2"
        case "MIA": return "H"
        case "DFW": return "E"
        case "DEN": return "A"
        case "LAS": return "D"
        case "MSP": return "1"
        case "DTW": return "M"
        case "SLC": return "A"
        case "PIT": return "B"
        case "MCO": return "B"
        case "PHX": return "3"
        case "MSY": return "D"
        case "EWR": return "B"
        case "SAN": return "2"
        case "TPA": return "F"
        case "AUS": return "E"
        case "BNA": return "B"
        case "RDU": return "2"
        case "HNL": return "E"
        case "LHR": return "3"
        case "CDG": return "2E"
        case "AMS": return "G"
        case "FCO": return "E"
        case "NRT": return "1"
        case "ICN": return "2"
        case "CUN": return "3"
        case "MEX": return "2"
        case "GRU": return "3"
        case "YYZ": return "3"
        case "BOG": return "1"
        default: return "T"
        }
    }

    private static func defaultGate(for airportCode: String, leg: Int) -> String {
        let prefix: String
        switch airportCode {
        case "ATL": prefix = "A"
        case "JFK": prefix = "B"
        case "LGA": prefix = "C"
        case "LAX": prefix = "D"
        case "SFO": prefix = "E"
        case "SEA": prefix = "N"
        case "BOS": prefix = "B"
        case "ORD": prefix = "H"
        case "DCA": prefix = "C"
        case "MIA": prefix = "H"
        case "DFW": prefix = "E"
        case "DEN": prefix = "A"
        case "LAS": prefix = "D"
        case "MSP": prefix = "F"
        case "DTW": prefix = "A"
        case "SLC": prefix = "A"
        case "PIT": prefix = "B"
        case "MCO": prefix = "B"
        case "PHX": prefix = "C"
        case "MSY": prefix = "D"
        case "EWR": prefix = "B"
        case "SAN": prefix = "A"
        case "TPA": prefix = "F"
        case "AUS": prefix = "E"
        case "BNA": prefix = "B"
        case "RDU": prefix = "A"
        case "HNL": prefix = "G"
        case "LHR": prefix = "A"
        case "CDG": prefix = "K"
        case "AMS": prefix = "G"
        case "FCO": prefix = "E"
        case "NRT": prefix = "N"
        case "ICN": prefix = "A"
        case "CUN": prefix = "C"
        case "MEX": prefix = "D"
        case "GRU": prefix = "A"
        case "YYZ": prefix = "D"
        case "BOG": prefix = "B"
        default: prefix = "G"
        }
        return "\(prefix)\(12 + leg)"
    }

    /// All seed dates are relative to today so upcoming flights are always in the future.
    private static let baseDate: Date = Calendar(identifier: .gregorian).startOfDay(for: Date())

    private static func futureDate(daysFromNow days: Int, hour: Int, minute: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.day = days
        components.hour = hour
        components.minute = minute
        return calendar.date(byAdding: components, to: baseDate) ?? Date()
    }
}
