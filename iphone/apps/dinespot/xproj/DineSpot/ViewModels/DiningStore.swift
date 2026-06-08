import Foundation

@MainActor
final class DiningStore: ObservableObject {
    let cities: [City]
    let neighborhoods: [Neighborhood]
    let restaurants: [Restaurant]

    @Published var reservations: [Reservation] {
        didSet { persistIfNeeded() }
    }
    @Published var savedRestaurants: [SavedRestaurant] {
        didSet { persistIfNeeded() }
    }
    @Published var waitlistEntries: [WaitlistEntry] {
        didSet { persistIfNeeded() }
    }
    @Published var diningAlerts: [DiningAlert] {
        didSet { persistIfNeeded() }
    }
    @Published var userProfile: UserProfile {
        didSet { persistIfNeeded() }
    }
    @Published var recentSearches: [String] {
        didSet { persistIfNeeded() }
    }
    @Published var selectedCityID: String {
        didSet {
            persistIfNeeded()
            if !isHydrating { reloadAvailability() }
        }
    }
    @Published var availabilityMode: AvailabilityMode {
        didSet {
            guard !isHydrating else { return }
            reloadAvailability()
            persistIfNeeded()
        }
    }

    @Published private(set) var availabilityByRestaurant: [String: RestaurantAvailability] = [:]
    @Published private(set) var availabilitySourceLabel: String = "Standard Data"
    @Published private(set) var availabilityMetadata: AvailabilitySnapshotMetadata?
    @Published private(set) var snapshotErrorMessage: String?

    private var confirmationSequence: Int
    private var waitlistSequence: Int
    private var isHydrating = true

    private let seededRepository: SeededAvailabilityRepository
    private let snapshotLoader = SnapshotAvailabilityLoader()

    init() {
        let seededCities = SeedData.cities()
        let seededNeighborhoods = SeedData.neighborhoods()
        let seededRestaurants = SeedData.restaurants()

        cities = seededCities
        neighborhoods = seededNeighborhoods
        restaurants = seededRestaurants
        seededRepository = SeededAvailabilityRepository(restaurants: seededRestaurants)

        let defaultCityID = seededCities.first?.id ?? "city_new_york"
        let defaultProfile = SeedData.seededProfile(defaultCityID: defaultCityID)

        if let persisted = PersistenceManager.loadState() {
            reservations = persisted.reservations
            savedRestaurants = persisted.savedRestaurants
            waitlistEntries = persisted.waitlistEntries
            diningAlerts = persisted.diningAlerts
            userProfile = persisted.userProfile
            recentSearches = persisted.recentSearches
            selectedCityID = seededCities.contains(where: { $0.id == persisted.selectedCityID }) ? persisted.selectedCityID : defaultCityID
            availabilityMode = persisted.availabilityMode
            confirmationSequence = max(persisted.confirmationSequence, SeedData.seededConfirmationSequence())
            waitlistSequence = max(persisted.waitlistSequence, SeedData.seededWaitlistSequence())
        } else {
            reservations = SeedData.seededReservations()
            savedRestaurants = SeedData.seededSavedRestaurants()
            waitlistEntries = SeedData.defaultWaitlistEntries()
            diningAlerts = SeedData.seededAlerts()
            userProfile = defaultProfile
            recentSearches = SeedData.seededRecentSearches()
            selectedCityID = defaultCityID
            availabilityMode = .seeded
            confirmationSequence = SeedData.seededConfirmationSequence()
            waitlistSequence = SeedData.seededWaitlistSequence()
        }

        refreshTemporalReservationStatuses()
        isHydrating = false
        reloadAvailability()
    }

    func city(for cityID: String) -> City? {
        cities.first(where: { $0.id == cityID })
    }

    func neighborhood(for neighborhoodID: String) -> Neighborhood? {
        neighborhoods.first(where: { $0.id == neighborhoodID })
    }

    func restaurant(for restaurantID: String) -> Restaurant? {
        restaurants.first(where: { $0.id == restaurantID })
    }

    func restaurants(in cityID: String) -> [Restaurant] {
        restaurants.filter { $0.cityID == cityID }
    }

    func isFavorite(restaurantID: String) -> Bool {
        savedRestaurants.contains(where: { $0.restaurantID == restaurantID })
    }

    func favoriteRestaurants() -> [Restaurant] {
        savedRestaurants
            .sorted(by: { $0.savedAt > $1.savedAt })
            .compactMap { saved in
                restaurants.first(where: { $0.id == saved.restaurantID })
            }
    }

    func toggleFavorite(restaurantID: String) {
        if let index = savedRestaurants.firstIndex(where: { $0.restaurantID == restaurantID }) {
            savedRestaurants.remove(at: index)
        } else {
            savedRestaurants.insert(SavedRestaurant(restaurantID: restaurantID, savedAt: Date()), at: 0)
        }
    }

    func upcomingReservations() -> [Reservation] {
        refreshTemporalReservationStatuses()
        return reservations
            .filter { $0.status == .upcoming }
            .sorted(by: { $0.date < $1.date })
    }

    func pastReservations() -> [Reservation] {
        refreshTemporalReservationStatuses()
        return reservations
            .filter { $0.status == .past }
            .sorted(by: { $0.date > $1.date })
    }

    func canceledReservations() -> [Reservation] {
        reservations
            .filter { $0.status == .canceled }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    func availability(for restaurantID: String) -> RestaurantAvailability? {
        availabilityByRestaurant[restaurantID]
    }

    func availableSlots(for restaurantID: String, date: Date, partySize: Int) -> [ReservationSlot] {
        let calendar = Calendar.current
        let filtered = (availabilityByRestaurant[restaurantID]?.availableSlots ?? [])
            .filter { slot in
                slot.isBookable
                && slot.partySize >= partySize
                && calendar.isDate(slot.date, inSameDayAs: date)
                && slot.date >= Date().addingTimeInterval(-60 * 30)
            }
            .sorted(by: { $0.date < $1.date })
        var seenDates = Set<Date>()
        return filtered.filter { seenDates.insert($0.date).inserted }
    }

    func allFutureSlots(for restaurantID: String, partySize: Int? = nil) -> [ReservationSlot] {
        let filtered = (availabilityByRestaurant[restaurantID]?.availableSlots ?? [])
            .filter { slot in
                slot.isBookable
                && slot.date >= Date().addingTimeInterval(-60 * 30)
                && (partySize == nil || slot.partySize >= (partySize ?? 0))
            }
            .sorted(by: { $0.date < $1.date })
        var seenDates = Set<Date>()
        return filtered.filter { seenDates.insert($0.date).inserted }
    }

    func nextAvailableSlots(for restaurantID: String, partySize: Int, limit: Int) -> [ReservationSlot] {
        Array(allFutureSlots(for: restaurantID, partySize: partySize).prefix(limit))
    }

    func earliestAvailabilityDate(for restaurantID: String, partySize: Int) -> Date? {
        nextAvailableSlots(for: restaurantID, partySize: partySize, limit: 1).first?.date
    }

    @discardableResult
    func createReservation(
        restaurant: Restaurant,
        slot: ReservationSlot,
        partySize: Int,
        diningPreference: String,
        notes: String
    ) -> Reservation {
        confirmationSequence += 1
        let code = String(format: "RSV%04d", confirmationSequence)
        let now = Date()

        let reservation = Reservation(
            id: "reservation_\(confirmationSequence)",
            reservationCode: code,
            restaurantID: restaurant.id,
            date: slot.date,
            partySize: partySize,
            status: .upcoming,
            diningPreference: diningPreference,
            sourceType: slot.sourceType,
            policySummary: restaurant.policy.cancellationPolicy,
            notes: notes,
            createdAt: now,
            updatedAt: now
        )

        reservations.append(reservation)
        diningAlerts.insert(
            DiningAlert(
                id: "alert_reservation_\(confirmationSequence)",
                title: "Reservation confirmed",
                message: "\(restaurant.name) on \(DateFormatters.weekdayDate.string(from: slot.date)) at \(DateFormatters.shortTime.string(from: slot.date)).",
                restaurantID: restaurant.id,
                date: now,
                isRead: false
            ),
            at: 0
        )
        DiningMailOutboxWriter.recordReservationEmail(
            restaurant: restaurant.name,
            date: slot.date,
            partySize: partySize,
            confirmationCode: code
        )
        return reservation
    }

    @discardableResult
    func modifyReservation(
        reservationID: String,
        newSlot: ReservationSlot,
        newPartySize: Int,
        newDiningPreference: String
    ) -> Bool {
        guard let index = reservations.firstIndex(where: { $0.id == reservationID }) else { return false }
        guard reservations[index].status == .upcoming else { return false }

        reservations[index].date = newSlot.date
        reservations[index].partySize = newPartySize
        reservations[index].diningPreference = newDiningPreference
        reservations[index].updatedAt = Date()
        return true
    }

    @discardableResult
    func cancelReservation(reservationID: String) -> Bool {
        guard let index = reservations.firstIndex(where: { $0.id == reservationID }) else { return false }
        guard reservations[index].status == .upcoming else { return false }
        guard canCancelReservation(reservations[index]) else { return false }

        reservations[index].status = .canceled
        reservations[index].updatedAt = Date()
        return true
    }

    func canModifyReservation(_ reservation: Reservation) -> Bool {
        reservation.status == .upcoming && reservation.date > Date().addingTimeInterval(60 * 60)
    }

    func canCancelReservation(_ reservation: Reservation) -> Bool {
        reservation.status == .upcoming && reservation.date > Date().addingTimeInterval(60 * 60 * 2)
    }

    func cancellationWindowClosed(_ reservation: Reservation) -> Bool {
        reservation.status == .upcoming && !canCancelReservation(reservation)
    }

    @discardableResult
    func rebookReservation(_ reservation: Reservation) -> Reservation? {
        guard let restaurant = restaurant(for: reservation.restaurantID) else { return nil }
        guard let slot = nextAvailableSlots(for: restaurant.id, partySize: reservation.partySize, limit: 1).first else { return nil }

        return createReservation(
            restaurant: restaurant,
            slot: slot,
            partySize: reservation.partySize,
            diningPreference: reservation.diningPreference,
            notes: "Rebooked from \(reservation.reservationCode)"
        )
    }

    @discardableResult
    func createWaitlistEntry(
        restaurantID: String,
        requestType: WaitlistRequestType,
        date: Date,
        partySize: Int,
        preferredWindow: String
    ) -> WaitlistEntry {
        waitlistSequence += 1
        let entry = WaitlistEntry(
            id: "WL\(waitlistSequence)",
            restaurantID: restaurantID,
            requestType: requestType,
            date: date,
            partySize: partySize,
            preferredWindow: preferredWindow,
            createdAt: Date(),
            status: "Active"
        )
        waitlistEntries.insert(entry, at: 0)

        diningAlerts.insert(
            DiningAlert(
                id: "alert_waitlist_\(waitlistSequence)",
                title: requestType == .waitlist ? "Waitlist joined" : "Notify request created",
                message: "We'll notify you if \(preferredWindow) opens.",
                restaurantID: restaurantID,
                date: Date(),
                isRead: false
            ),
            at: 0
        )

        return entry
    }

    func markAlertRead(alertID: String) {
        guard let index = diningAlerts.firstIndex(where: { $0.id == alertID }) else { return }
        diningAlerts[index].isRead = true
    }

    func reviews(for restaurantID: String) -> [DinerReview] {
        SeedData.reviews.filter { $0.restaurantID == restaurantID }
            .sorted { $0.date > $1.date }
    }

    func popularDishes(for restaurantID: String) -> [PopularDish] {
        SeedData.popularDishes.filter { $0.restaurantID == restaurantID }
            .sorted { $0.mentionCount > $1.mentionCount }
    }

    func addRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 8 {
            recentSearches = Array(recentSearches.prefix(8))
        }
    }

    func setAvailabilityMode(_ mode: AvailabilityMode) {
        availabilityMode = mode
    }

    func reloadBundledSnapshot() {
        do {
            let snapshot = try snapshotLoader.loadBundledSnapshot()
            if availabilityMode == .snapshot {
                applySnapshot(snapshot, suffix: " (Bundled)")
            } else {
                snapshotErrorMessage = nil
            }
        } catch {
            snapshotErrorMessage = error.localizedDescription
        }
    }

    func reloadSandboxSnapshot() {
        do {
            let snapshot = try snapshotLoader.loadSandboxSnapshot()
            if availabilityMode == .snapshot {
                applySnapshot(snapshot, suffix: " (Sandbox)")
            } else {
                snapshotErrorMessage = nil
            }
        } catch {
            snapshotErrorMessage = error.localizedDescription
        }
    }

    func sandboxSnapshotPath() -> String {
        snapshotLoader.sandboxSnapshotPath()
    }

    func resetAppState() {
        isHydrating = true
        PersistenceManager.clearAll()

        reservations = SeedData.seededReservations()
        savedRestaurants = SeedData.seededSavedRestaurants()
        waitlistEntries = SeedData.defaultWaitlistEntries()
        diningAlerts = SeedData.seededAlerts()
        recentSearches = SeedData.seededRecentSearches()

        let defaultCityID = cities.first?.id ?? "city_new_york"
        userProfile = SeedData.seededProfile(defaultCityID: defaultCityID)
        selectedCityID = defaultCityID
        availabilityMode = .seeded
        confirmationSequence = SeedData.seededConfirmationSequence()
        waitlistSequence = SeedData.seededWaitlistSequence()

        isHydrating = false
        reloadAvailability()
        persistIfNeeded()
    }

    private func refreshTemporalReservationStatuses() {
        var didUpdate = false
        let now = Date()
        for index in reservations.indices {
            guard reservations[index].status == .upcoming else { continue }
            if reservations[index].date < now {
                reservations[index].status = .past
                reservations[index].updatedAt = now
                didUpdate = true
            }
        }

        if didUpdate {
            persistIfNeeded()
        }
    }

    private func reloadAvailability() {
        snapshotErrorMessage = nil
        availabilityMetadata = nil

        switch availabilityMode {
        case .seeded:
            let cityRestaurants = restaurants.filter { $0.cityID == selectedCityID }
            let label = seededRepository.sourceLabel
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let availability = SeedData.seededAvailability(for: cityRestaurants)
                DispatchQueue.main.async {
                    self?.availabilityByRestaurant = self?.dictionary(for: availability) ?? [:]
                    self?.availabilitySourceLabel = label
                }
            }
        case .snapshot:
            do {
                let loaded = try snapshotLoader.loadPreferredSnapshot()
                applySnapshot(loaded.snapshot, suffix: loaded.suffix)
            } catch {
                availabilityByRestaurant = [:]
                availabilitySourceLabel = "Snapshot Availability Data (Unavailable)"
                snapshotErrorMessage = error.localizedDescription
            }
        }
    }

    private func applySnapshot(_ snapshot: AvailabilitySnapshot, suffix: String) {
        let repository = SnapshotAvailabilityRepository(snapshot: snapshot, labelSuffix: suffix)
        let availability = repository.loadAvailability()
        availabilityByRestaurant = dictionary(for: availability)
        availabilitySourceLabel = repository.sourceLabel
        availabilityMetadata = repository.metadata
        snapshotErrorMessage = nil
    }

    private func dictionary(for availability: [RestaurantAvailability]) -> [String: RestaurantAvailability] {
        Dictionary(uniqueKeysWithValues: availability.map { ($0.restaurantID, $0) })
    }

    private func persistIfNeeded() {
        guard !isHydrating else { return }
        let state = PersistedState(
            reservations: reservations,
            savedRestaurants: savedRestaurants,
            waitlistEntries: waitlistEntries,
            diningAlerts: diningAlerts,
            userProfile: userProfile,
            recentSearches: recentSearches,
            selectedCityID: selectedCityID,
            availabilityMode: availabilityMode,
            confirmationSequence: confirmationSequence,
            waitlistSequence: waitlistSequence
        )
        PersistenceManager.save(state)
    }
}

struct DiningMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "dinespot.outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordReservationEmail(restaurant: String, date: Date, partySize: Int, confirmationCode: String) {
        guard let url = inboxURL() else { return }
        let dateText = DateFormatters.weekdayDate.string(from: date)
        let timeText = DateFormatters.shortTime.string(from: date)
        let record = MailRecord(
            id: UUID(),
            from: "DineSpot",
            subject: "Reservation Confirmed - \(restaurant)",
            body: "Your reservation at \(restaurant) is confirmed.\n\nDate: \(dateText)\nTime: \(timeText)\nParty size: \(partySize)\nConfirmation: \(confirmationCode)\n\nSee you there!\nDineSpot",
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
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
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
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
