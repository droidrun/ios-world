import Foundation

enum CheckoutPaymentAccountType: String, Codable {
    case checking, savings, credit
}

struct CheckoutPaymentAccount: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: CheckoutPaymentAccountType
    let balance: Double
    let availableBalance: Double
    let currency: String
    let lastUpdated: Date
    let creditLimit: Double?

    var maskedNumber: String {
        switch type {
        case .checking: return "**** **** **** 6645"
        case .savings: return "**** **** **** 7814"
        case .credit: return "**** **** **** 2095"
        }
    }
    var network: String {
        switch type {
        case .credit: return "MASTERCARD"
        case .checking: return "VISA DEBIT"
        case .savings: return "MASTERCARD DEBIT"
        }
    }
    var displayName: String { "\(network) \(maskedNumber)" }
}

final class MyBankCheckoutAccountsService {
    private let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private let fileName = "mybank_accounts.json"
    private var accountsURL: URL {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }
    func loadAccounts() -> [CheckoutPaymentAccount] {
        guard let data = try? Data(contentsOf: accountsURL) else { return defaultAccounts() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([CheckoutPaymentAccount].self, from: data), !decoded.isEmpty { return decoded }
        return defaultAccounts()
    }
    private func defaultAccounts() -> [CheckoutPaymentAccount] {
        let now = Date()
        return [
            CheckoutPaymentAccount(id: UUID(), name: "Total Checking (...6645)", type: .checking, balance: 2150.32, availableBalance: 2150.32, currency: "USD", lastUpdated: now, creditLimit: nil),
            CheckoutPaymentAccount(id: UUID(), name: "Savings (...1032)", type: .savings, balance: 9400.00, availableBalance: 9400.00, currency: "USD", lastUpdated: now, creditLimit: nil),
            CheckoutPaymentAccount(id: UUID(), name: "Freedom Unlimited (...2095)", type: .credit, balance: -642.13, availableBalance: 5357.87, currency: "USD", lastUpdated: now, creditLimit: 6000.0)
        ]
    }
}

@MainActor
final class AppStore: ObservableObject {
    enum StoreError: LocalizedError {
        case message(String)

        var errorDescription: String? {
            switch self {
            case let .message(message):
                return message
            }
        }
    }

    @Published private(set) var airports: [Airport] = SeedDataFactory.airports
    @Published private(set) var fareSourceType: FareSourceType = .seeded
    @Published private(set) var trips: [Trip] = []
    @Published private(set) var boardingPasses: [BoardingPass] = []
    @Published private(set) var alerts: [TravelAlert] = []
    @Published private(set) var recentSearches: [RecentSearch] = []
    @Published private(set) var userProfile: UserProfile = SeedDataFactory.userProfile
    @Published private(set) var skyMilesAccount: SkyMilesAccount = SeedDataFactory.skyMilesAccount
    @Published private(set) var paymentAccounts: [CheckoutPaymentAccount] = []
    @Published var selectedPaymentAccountID: UUID?

    @Published private(set) var snapshotMetadata: FareSnapshotMetadata?
    @Published private(set) var snapshotSourcePath: String?
    @Published private(set) var snapshotError: String?

    @Published var selectedTab: AppTab = .home
    @Published var walletTabSection: WalletTabSection = .skymiles

    /// When set, the Search tab picks this up on next appear to pre-populate origin/destination.
    @Published var pendingSearchPreset: (originCode: String, destinationCode: String, tripType: TripType, departureDate: Date)?

    private let persistence: AppPersistence
    private let seededRepository: SeededFareRepository
    private let snapshotRepository: SnapshotFareRepository
    private let myBankAccountsService = MyBankCheckoutAccountsService()

    init(
        persistence: AppPersistence = AppPersistence(),
        snapshotRepository: SnapshotFareRepository = SnapshotFareRepository()
    ) {
        self.persistence = persistence
        self.snapshotRepository = snapshotRepository
        self.seededRepository = SeededFareRepository(itineraries: SeedDataFactory.seededItineraries())

        if let restored = persistence.load() {
            applyPersistedState(restored)
        } else {
            applyPersistedState(SeedDataFactory.seededState())
            persist()
        }

        refreshSnapshotStatus()

        paymentAccounts = myBankAccountsService.loadAccounts()
        selectedPaymentAccountID = paymentAccounts.first(where: { $0.type == .credit })?.id ?? paymentAccounts.first?.id
    }

    var selectedPaymentAccount: CheckoutPaymentAccount? {
        paymentAccounts.first(where: { $0.id == selectedPaymentAccountID })
    }

    func refreshPaymentAccounts() {
        paymentAccounts = myBankAccountsService.loadAccounts()
        if selectedPaymentAccountID == nil || !paymentAccounts.contains(where: { $0.id == selectedPaymentAccountID }) {
            selectedPaymentAccountID = paymentAccounts.first(where: { $0.type == .credit })?.id ?? paymentAccounts.first?.id
        }
    }

    var upcomingTrips: [Trip] {
        trips
            .filter { $0.category == .upcoming }
            .sorted { $0.departureTime < $1.departureTime }
    }

    var pastTrips: [Trip] {
        trips
            .filter { $0.category == .past || $0.category == .canceled }
            .sorted { $0.departureTime > $1.departureTime }
    }

    var eligibleCheckInTrips: [Trip] {
        upcomingTrips.filter { $0.checkInEligible && !$0.checkedIn }
    }

    func setFareSource(_ sourceType: FareSourceType) {
        fareSourceType = sourceType
        persist()
        refreshSnapshotStatus()
    }

    func search(criteria: FlightSearchCriteria) -> [FlightItinerary] {
        let results: [FlightItinerary]
        switch fareSourceType {
        case .seeded:
            results = seededRepository.search(criteria: criteria)
            snapshotError = nil
        case .snapshot:
            results = snapshotRepository.search(criteria: criteria)
            syncSnapshotDiagnostics()
        }

        addRecentSearch(criteria)
        return results
    }

    func createBooking(from itinerary: FlightItinerary, passengers: Int = 1, paymentAccountID: UUID) -> Trip {
        let indexValue = trips.count + 1
        let confirmationCode = "D\(String(format: "%05d", indexValue + 300))"
        let assignedSeat = itinerary.tripType == .oneWay ? "19C" : "21D"
        let createdAt = Calendar(identifier: .gregorian).date(byAdding: .day, value: -2, to: itinerary.departureTime) ?? itinerary.departureTime

        let seatRow = Int(assignedSeat.dropLast()) ?? 20
        let boardingGroup = Self.boardingGroup(for: seatRow)

        let createdTrip = Trip(
            id: "TRIP_BOOKED_\(String(format: "%03d", indexValue))",
            confirmationCode: confirmationCode,
            passenger: Passenger(
                id: "PAX_MAIN",
                firstName: userProfile.firstName,
                lastName: userProfile.lastName,
                skyMilesNumber: skyMilesAccount.memberNumber
            ),
            tripType: itinerary.tripType,
            outboundSegments: itinerary.outboundSegments,
            returnSegments: itinerary.returnSegments,
            seatAssignment: assignedSeat,
            boardingGroup: boardingGroup,
            checkedIn: false,
            baggageStatus: "No checked bags",
            category: .upcoming,
            operationalStatus: .onTime,
            checkInEligible: true,
            fareSourceType: fareSourceType,
            totalPrice: itinerary.fare.price * Double(passengers),
            currency: itinerary.fare.currency,
            seatMap: generateSeatMap(id: "SEATMAP_BOOKED_\(indexValue)", assignedSeat: assignedSeat),
            createdAt: createdAt,
            passengerCount: passengers
        )

        trips.insert(createdTrip, at: 0)
        persist()
        SkyTripMyBankLedgerWriter.recordBooking(createdTrip, paymentAccountId: paymentAccountID)
        SkyTripMailOutboxWriter.recordBookingEmail(createdTrip)
        return createdTrip
    }

    func cancelTrip(tripID: String) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else {
            return
        }

        var trip = trips[index]
        trip.category = .canceled
        trip.checkInEligible = false
        trip.checkedIn = false
        trips[index] = trip

        boardingPasses.removeAll { $0.tripId == tripID }
        persist()
    }

    func completeCheckIn(tripID: String, preferredSeat: String?) -> Result<BoardingPass, StoreError> {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else {
            return .failure(.message("Trip not found"))
        }

        var trip = trips[index]

        guard trip.category == .upcoming else {
            return .failure(.message("check-in unavailable"))
        }

        if !trip.checkedIn && !trip.checkInEligible {
            return .failure(.message("check-in unavailable"))
        }

        if let preferredSeat {
            let seatResult = selectSeat(tripID: tripID, seatNumber: preferredSeat)
            if case let .failure(message) = seatResult {
                return .failure(message)
            }
            if let refreshedTrip = trips.first(where: { $0.id == tripID }) {
                trip = refreshedTrip
            }
        }

        if trip.seatAssignment == nil {
            guard let firstAvailable = trip.seatMap.seats.first(where: { $0.availability == .available }) else {
                return .failure(.message("no seat available"))
            }
            if case let .failure(message) = selectSeat(tripID: tripID, seatNumber: firstAvailable.seatNumber) {
                return .failure(message)
            }
            if let refreshedTrip = trips.first(where: { $0.id == tripID }) {
                trip = refreshedTrip
            }
        }

        trip.checkedIn = true
        trip.checkInEligible = true
        trip.operationalStatus = .boarding
        trips[index] = trip

        let boardingPass = SeedDataFactory.boardingPass(for: trip)
        if let existingIndex = boardingPasses.firstIndex(where: { $0.tripId == trip.id }) {
            boardingPasses[existingIndex] = boardingPass
        } else {
            boardingPasses.insert(boardingPass, at: 0)
        }

        persist()
        return .success(boardingPass)
    }

    func selectSeat(tripID: String, seatNumber: String) -> Result<Void, StoreError> {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else {
            return .failure(.message("Trip not found"))
        }

        var trip = trips[index]

        guard trip.seatMap.seats.contains(where: { $0.availability == .available || $0.availability == .selected }) else {
            return .failure(.message("no seat available"))
        }

        guard let selectedIndex = trip.seatMap.seats.firstIndex(where: { $0.seatNumber == seatNumber }) else {
            return .failure(.message("Seat not found"))
        }

        let targetSeat = trip.seatMap.seats[selectedIndex]
        guard targetSeat.availability == .available || targetSeat.availability == .selected else {
            return .failure(.message("Seat unavailable"))
        }

        if targetSeat.availability == .selected {
            trip.seatMap.seats[selectedIndex].availability = .available
            let remaining = trip.seatMap.seats.filter { $0.availability == .selected }
            trip.seatAssignment = remaining.first?.seatNumber
        } else {
            let currentlySelected = trip.seatMap.seats.indices.filter { trip.seatMap.seats[$0].availability == .selected }
            if currentlySelected.count >= trip.passengerCount {
                if let first = currentlySelected.first {
                    trip.seatMap.seats[first].availability = .available
                }
            }
            trip.seatMap.seats[selectedIndex].availability = .selected
            trip.seatAssignment = seatNumber
        }

        let selectedTags = trip.seatMap.seats.filter { $0.availability == .selected }.map(\.tag)
        let basePrice = trip.totalPrice - seatUpchargeTotal(for: trip)
        let newUpcharge = selectedTags.reduce(0.0) { $0 + Trip.seatUpcharge(for: $1) }
        trip.totalPrice = basePrice + newUpcharge

        if let assignment = trip.seatAssignment, let seatRow = Int(assignment.dropLast()) {
            trip.boardingGroup = Self.boardingGroup(for: seatRow)
        }

        trips[index] = trip

        if let passIndex = boardingPasses.firstIndex(where: { $0.tripId == tripID }) {
            boardingPasses[passIndex].seat = trip.seatAssignment ?? seatNumber
            boardingPasses[passIndex].boardingGroup = trip.boardingGroup
        }

        persist()
        return .success(())
    }

    private func seatUpchargeTotal(for trip: Trip) -> Double {
        trip.seatMap.seats
            .filter { $0.availability == .selected }
            .reduce(0.0) { $0 + Trip.seatUpcharge(for: $1.tag) }
    }

    static func boardingGroup(for seatRow: Int) -> String {
        if seatRow <= 12 { return "Comfort+" }
        if seatRow <= 17 { return "Main 1" }
        return "Main 2"
    }

    func confirmSeatUpgrade(tripID: String, paymentAccountID: UUID) {
        guard let trip = trip(with: tripID) else { return }
        let upcharge = seatUpchargeTotal(for: trip)
        guard upcharge > 0 else { return }
        SkyTripMyBankLedgerWriter.recordSeatUpgrade(trip, amount: upcharge, paymentAccountId: paymentAccountID)
        SkyTripMailOutboxWriter.recordSeatUpgradeEmail(trip, amount: upcharge)
    }

    func resetAppState() {
        persistence.clear()
        snapshotRepository.clearSandboxSnapshot()
        applyPersistedState(SeedDataFactory.seededState())
        selectedTab = .home
        walletTabSection = .skymiles
        refreshSnapshotStatus()
        persist()
    }

    func resetPersistenceOnly() {
        persistence.clear()
        applyPersistedState(SeedDataFactory.seededState())
        walletTabSection = .skymiles
        refreshSnapshotStatus()
        persist()
    }

    func showWalletSection(_ section: WalletTabSection) {
        walletTabSection = section
        selectedTab = .wallet
    }

    func reloadBundledSnapshotData() -> Result<Void, StoreError> {
        switch snapshotRepository.reloadBundledSnapshot() {
        case .success:
            syncSnapshotDiagnostics()
            return .success(())
        case .failure(let error):
            syncSnapshotDiagnostics()
            return .failure(.message(error.localizedDescription))
        }
    }

    func refreshSnapshotStatus() {
        syncSnapshotDiagnostics()
    }

    func trip(with id: String) -> Trip? {
        trips.first(where: { $0.id == id })
    }

    func boardingPass(for tripID: String) -> BoardingPass? {
        boardingPasses.first(where: { $0.tripId == tripID })
    }

    private func syncSnapshotDiagnostics() {
        let diagnostics = snapshotRepository.previewSnapshotStatus()
        snapshotMetadata = diagnostics.metadata
        snapshotSourcePath = diagnostics.sourceURL?.path
        snapshotError = diagnostics.error
    }

    private func addRecentSearch(_ criteria: FlightSearchCriteria) {
        let recent = RecentSearch(
            id: "RECENT_\(criteria.originCode)_\(criteria.destinationCode)_\(Int(criteria.departureDate.timeIntervalSince1970))",
            originCode: criteria.originCode,
            destinationCode: criteria.destinationCode,
            tripType: criteria.tripType,
            departureDate: criteria.departureDate,
            returnDate: criteria.returnDate,
            passengers: criteria.passengers
        )

        var updated = recentSearches.filter {
            !($0.originCode == recent.originCode &&
              $0.destinationCode == recent.destinationCode &&
              Calendar(identifier: .gregorian).isDate($0.departureDate, inSameDayAs: recent.departureDate) &&
              $0.tripType == recent.tripType)
        }
        updated.insert(recent, at: 0)
        recentSearches = Array(updated.prefix(6))
        persist()
    }

    private func persist() {
        let state = PersistedAppState(
            fareSourceType: fareSourceType,
            trips: trips,
            boardingPasses: boardingPasses,
            alerts: alerts,
            recentSearches: recentSearches,
            userProfile: userProfile,
            skyMilesAccount: skyMilesAccount
        )
        persistence.save(state)
    }

    private func applyPersistedState(_ state: PersistedAppState) {
        fareSourceType = state.fareSourceType
        trips = state.trips
        boardingPasses = state.boardingPasses
        alerts = state.alerts
        recentSearches = state.recentSearches
        userProfile = state.userProfile
        skyMilesAccount = state.skyMilesAccount
    }

    private func generateSeatMap(id: String, assignedSeat: String?) -> SeatMap {
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

        return SeatMap(id: id, aircraftType: "Airbus A321neo", rows: rows, columns: columns, seats: seats)
    }

    private func seatColumns(for row: Int) -> [String] {
        if row <= 12 {
            return ["A", "C", "D", "F"]
        }
        return ["A", "B", "C", "D", "E", "F"]
    }
}

struct SkyTripMyBankLedgerWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mybank_ledger.json"
    private static let ioQueue = DispatchQueue(label: "skytrip.delta_ledger.io", qos: .utility)

    private struct LedgerTransaction: Codable {
        let id: UUID
        let externalId: String
        let accountId: UUID
        let vendor: String
        let amount: Double
        let currency: String
        let category: String
        let note: String?
        let timestamp: Date
        let status: String
        let sourceApp: String
        let rawSource: String

        enum CodingKeys: String, CodingKey {
            case id
            case externalId = "external_id"
            case accountId = "account_id"
            case vendor, amount, currency, category, note, timestamp, status
            case sourceApp = "source_app"
            case rawSource = "raw_source"
        }
    }

    static func recordBooking(_ trip: Trip, paymentAccountId: UUID) {
        guard let url = ledgerURL() else {
            print("[MyBank] App Group unavailable; SkyTrip ledger write skipped.")
            return
        }

        let note = trip.outboundSegments.map { seg in
            "\(seg.origin.code)\u{2192}\(seg.destination.code) \(seg.flightNumber)"
        }.joined(separator: ", ")

        let record = LedgerTransaction(
            id: UUID(),
            externalId: trip.id,
            accountId: paymentAccountId,
            vendor: "SkyTrip Airlines",
            amount: -abs(trip.totalPrice),
            currency: trip.currency,
            category: "Travel",
            note: note.isEmpty ? nil : note,
            timestamp: Date(),
            status: "pending",
            sourceApp: "SkyTrip",
            rawSource: "skytrip_booking"
        )

        ioQueue.async {
            var records = loadLedger(from: url)
            if records.contains(where: { $0.externalId == record.externalId }) {
                return
            }
            records.append(record)
            saveLedger(records, to: url)
        }
    }

    static func recordSeatUpgrade(_ trip: Trip, amount: Double, paymentAccountId: UUID) {
        guard let url = ledgerURL() else {
            print("[MyBank] App Group unavailable; SkyTrip seat upgrade ledger write skipped.")
            return
        }

        let seatLabel = trip.selectedSeats.joined(separator: ", ")
        let note = "Seat upgrade to \(seatLabel) on \(trip.primaryFlightNumber) (\(trip.routeText))"
        let externalId = "\(trip.id)_SEAT_UPGRADE_\(seatLabel.replacingOccurrences(of: ", ", with: "_"))"

        let record = LedgerTransaction(
            id: UUID(),
            externalId: externalId,
            accountId: paymentAccountId,
            vendor: "SkyTrip Airlines",
            amount: -abs(amount),
            currency: trip.currency,
            category: "Travel",
            note: note,
            timestamp: Date(),
            status: "pending",
            sourceApp: "SkyTrip",
            rawSource: "skytrip_seat_upgrade"
        )

        ioQueue.async {
            var records = loadLedger(from: url)
            if records.contains(where: { $0.externalId == record.externalId }) {
                return
            }
            records.append(record)
            saveLedger(records, to: url)
        }
    }

    private static func ledgerURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        return nil
    }

    private static func loadLedger(from url: URL) -> [LedgerTransaction] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([LedgerTransaction].self, from: data)) ?? []
    }

    private static func saveLedger(_ records: [LedgerTransaction], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[MyBank] Failed to write SkyTrip ledger: \(error)")
        }
    }
}

struct SkyTripMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "skytrip.delta_outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordBookingEmail(_ trip: Trip) {
        guard let url = inboxURL() else {
            print("[Mail] App Group unavailable; SkyTrip email write skipped.")
            return
        }

        let routes = trip.outboundSegments.map { "\($0.origin.code) \u{2192} \($0.destination.code)" }.joined(separator: ", ")
        let subject = "Your SkyTrip flight is confirmed"
        let body = """
        Hi \(trip.passenger.firstName),

        Your SkyTrip flight booking is confirmed.

        Confirmation: \(trip.confirmationCode)
        Route: \(routes)
        Seat: \(trip.seatAssignment ?? "Not assigned")
        Total: \(String(format: "$%.2f", trip.totalPrice))

        Check in online 24 hours before departure.

        Thanks,
        SkyTrip Airlines
        """

        let record = MailRecord(
            id: UUID(),
            from: "SkyTrip Airlines",
            subject: subject,
            body: body,
            category: 1,
            date: Date()
        )

        ioQueue.async {
            var records = loadRecords(from: url)
            if records.contains(where: { $0.from == "SkyTrip Airlines" && $0.subject == subject && Calendar.current.isDate($0.date, inSameDayAs: record.date) }) {
                // Avoid duplicate emails for same-day bookings with same subject
            } else {
                records.append(record)
                saveRecords(records, to: url)
            }
        }
    }

    static func recordSeatUpgradeEmail(_ trip: Trip, amount: Double) {
        guard let url = inboxURL() else {
            print("[Mail] App Group unavailable; SkyTrip seat upgrade email write skipped.")
            return
        }

        let seatLabel = trip.selectedSeats.joined(separator: ", ")
        let subject = "Your SkyTrip seat upgrade is confirmed"
        let body = """
        Hi \(trip.passenger.firstName),

        Your seat upgrade has been confirmed.

        Confirmation: \(trip.confirmationCode)
        Route: \(trip.routeText)
        Flight: \(trip.primaryFlightNumber)
        New Seat: \(seatLabel)
        Upgrade Fee: \(String(format: "$%.2f", amount))

        The charge will appear on your linked payment method.

        Thanks,
        SkyTrip Airlines
        """

        let record = MailRecord(
            id: UUID(),
            from: "SkyTrip Airlines",
            subject: subject,
            body: body,
            category: 1,
            date: Date()
        )

        ioQueue.async {
            var records = loadRecords(from: url)
            records.append(record)
            saveRecords(records, to: url)
        }
    }

    private static func inboxURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        return nil
    }

    private static func loadRecords(from url: URL) -> [MailRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MailRecord].self, from: data)) ?? []
    }

    private static func saveRecords(_ records: [MailRecord], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[Mail] Failed to write SkyTrip email: \(error)")
        }
    }
}
