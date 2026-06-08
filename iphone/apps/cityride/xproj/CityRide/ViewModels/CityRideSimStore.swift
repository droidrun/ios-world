import CoreLocation
import Foundation

// MARK: - Device Location Manager

final class DeviceLocationManager: NSObject, ObservableObject {
    @Published private(set) var currentPlace: LocationPlace?
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private var manager: CLLocationManager?
    private let geocoder = CLGeocoder()

    func requestLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            applyFallback()
            return
        }
        if manager == nil {
            let mgr = CLLocationManager()
            mgr.delegate = self
            mgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.manager = mgr
        }
        guard let manager else { return }
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            applyFallback()
        }
    }

    private func applyFallback() {
        let place = LocationPlace(
            id: "device_location",
            displayName: "Current location",
            address: "San Francisco, CA",
            latitudePlaceholder: 37.7749,
            longitudePlaceholder: -122.4194
        )
        currentPlace = place
        currentCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }

    private func resolveLocation(_ location: CLLocation) {
        currentCoordinate = location.coordinate
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let coord = location.coordinate
                let placemark = placemarks?.first
                let street = placemark?.thoroughfare ?? ""
                let city = placemark?.locality ?? "San Francisco"
                let state = placemark?.administrativeArea ?? "CA"
                let addressParts = [street, city, state].filter { !$0.isEmpty }
                let address = addressParts.joined(separator: ", ")
                let displayName = street.isEmpty ? "Current location" : street

                self.currentPlace = LocationPlace(
                    id: "device_location",
                    displayName: displayName,
                    address: address,
                    latitudePlaceholder: coord.latitude,
                    longitudePlaceholder: coord.longitude
                )
            }
        }
    }
}

extension DeviceLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            self?.resolveLocation(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.applyFallback()
        }
    }
}

// MARK: - MyBank Checkout Account Types

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

// MARK: - MyBank Ledger Writer

struct CityRideMyBankLedgerWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mybank_ledger.json"
    private static let ioQueue = DispatchQueue(label: "cityride.uber_ledger.io", qos: .utility)

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
            case vendor
            case amount
            case currency
            case category
            case note
            case timestamp
            case status
            case sourceApp = "source_app"
            case rawSource = "raw_source"
        }
    }

    static func recordRide(_ trip: Trip, total: Double, paymentAccountId: UUID) {
        guard let url = ledgerURL() else {
            print("[MyBank] App Group unavailable; CityRide ledger write skipped.")
            return
        }

        let note = "\(trip.rideType): \(trip.pickupName) → \(trip.destinationName)"

        let record = LedgerTransaction(
            id: UUID(),
            externalId: trip.id,
            accountId: paymentAccountId,
            vendor: "CityRide",
            amount: -abs(total),
            currency: trip.currency,
            category: "Transportation",
            note: note.isEmpty ? nil : note,
            timestamp: Date(),
            status: "pending",
            sourceApp: "CityRide",
            rawSource: "cityride_ride"
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
            print("[MyBank] Failed to write CityRide ledger: \(error)")
        }
    }
}

// MARK: - Mail Outbox Writer

struct CityRideMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "cityride.uber_outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordRideEmail(_ trip: Trip, receipt: RideReceipt) {
        guard let url = inboxURL() else {
            print("[Mail] App Group unavailable; CityRide email write skipped.")
            return
        }

        let totalText = String(format: "$%.2f", receipt.receiptTotal)
        let baseFareText = String(format: "$%.2f", receipt.baseFare)
        let feesText = String(format: "$%.2f", receipt.fees)
        let taxesText = String(format: "$%.2f", receipt.taxes)
        let subject = "Your CityRide receipt"
        let body = """
        Thanks for riding with CityRide.

        Ride type: \(trip.rideType)
        Route: \(trip.pickupName) → \(trip.destinationName)

        Fare breakdown:
        Base fare: \(baseFareText)
        Fees: \(feesText)
        Taxes: \(taxesText)
        Total: \(totalText)

        Payment: \(trip.paymentMethodId)
        Receipt: \(receipt.id)

        Thanks,
        CityRide
        """

        let record = MailRecord(
            id: UUID(uuidString: receipt.tripId.replacingOccurrences(of: "trip_", with: "00000000-0000-0000-0000-0000000").prefix(36).description) ?? UUID(),
            from: "CityRide",
            subject: subject,
            body: body,
            category: 1,
            date: Date()
        )

        let receiptId = receipt.id
        ioQueue.async {
            var records = loadRecords(from: url)
            if records.contains(where: { $0.subject == subject && $0.body.contains(receiptId) }) {
                return
            }
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
            print("[Mail] Failed to write CityRide email: \(error)")
        }
    }
}

// MARK: - Sim Store

final class CityRideStore: ObservableObject {
    @Published private(set) var state: CityRideSimState
    @Published private(set) var currentRideOptions: [RideOption] = []
    @Published var inlineStatusMessage: String?
    @Published var lifecycleAutoAdvanceEnabled: Bool = true
    @Published private(set) var paymentAccounts: [CheckoutPaymentAccount] = []

    private let persistence: AppPersistence
    private let seededFareRepository: SeededFareRepository
    private let snapshotFareRepository: SnapshotFareRepository
    private var lifecycleTimer: Timer?
    private let myBankAccountsService = MyBankCheckoutAccountsService()
    let locationManager = DeviceLocationManager()

    var selectedMyBankAccountId: UUID? {
        guard let method = selectedPaymentMethod else { return nil }
        if method.last4 == "6645" {
            return paymentAccounts.first(where: { $0.type == .checking })?.id
        }
        if method.last4 == "2095" {
            return paymentAccounts.first(where: { $0.type == .credit })?.id
        }
        return nil
    }

    func myBankAccountForPaymentMethod(_ method: PaymentMethod) -> CheckoutPaymentAccount? {
        if method.last4 == "6645" {
            return paymentAccounts.first(where: { $0.type == .checking })
        }
        if method.last4 == "2095" {
            return paymentAccounts.first(where: { $0.type == .credit })
        }
        return nil
    }

    private static let currentSeedVersion = 1

    private static func requiresSeedReset(_ state: CityRideSimState) -> Bool {
        (state.seedVersion ?? 0) < currentSeedVersion
    }

    init(
        persistence: AppPersistence = AppPersistence(),
        seededFareRepository: SeededFareRepository = SeededFareRepository()
    ) {
        self.persistence = persistence
        self.seededFareRepository = seededFareRepository
        self.snapshotFareRepository = SnapshotFareRepository(persistence: persistence)

        if let loadedState = persistence.loadState(), !Self.requiresSeedReset(loadedState) {
            self.state = loadedState
        } else {
            self.state = SeedData.initialState()
            persistence.saveState(self.state)
        }

        paymentAccounts = myBankAccountsService.loadAccounts()

        if state.fareMode == .snapshot {
            _ = snapshotFareRepository.load(location: state.snapshotLocation)
            state.currentSnapshotMetadata = snapshotFareRepository.metadata()
        }

        refreshRideOptions()
        startLifecycleTimer()

        // Request device location on launch so the simulated coordinates are available
        locationManager.requestLocation()
    }

    deinit {
        lifecycleTimer?.invalidate()
    }

    var rideTypes: [RideTypeDefinition] {
        SeedData.rideTypes
    }

    var activeTrips: [Trip] {
        state.trips
            .filter { $0.isActive }
            .sorted(by: { $0.requestedAt > $1.requestedAt })
    }

    var activeTrip: Trip? {
        activeTrips.first
    }

    var upcomingTrips: [Trip] {
        state.trips
            .filter { $0.tripStatus == .reserved }
            .sorted(by: { ($0.reservedFor ?? .distantFuture) < ($1.reservedFor ?? .distantFuture) })
    }

    var pastTrips: [Trip] {
        state.trips
            .filter { $0.tripStatus == .tripCompleted || $0.tripStatus == .canceled }
            .sorted(by: { ($0.dropoffTime ?? $0.requestedAt) > ($1.dropoffTime ?? $1.requestedAt) })
    }

    var fareSourceLabel: String {
        switch state.fareMode {
        case .seeded:
            return "Standard Pricing"
        case .snapshot:
            return "Regional Pricing (\(state.snapshotLocation.label))"
        }
    }

    var availablePlaces: [LocationPlace] {
        state.places
    }

    var suggestedDestinations: [LocationPlace] {
        state.suggestedDestinations
    }

    var recentDestinations: [LocationPlace] {
        state.recentDestinations
    }

    var commuteShortcuts: [LocationPlace] {
        SeedData.commuteShortcuts
    }

    var walletPaymentMethods: [PaymentMethod] {
        state.walletState.paymentMethods
    }

    var selectedPaymentMethod: PaymentMethod? {
        state.walletState.paymentMethods.first(where: { $0.id == state.selectedPaymentMethodId })
    }

    var travelAlerts: [TravelAlert] {
        state.travelAlerts
    }

    func receipt(for tripID: String) -> RideReceipt? {
        state.receipts.first(where: { $0.tripId == tripID })
    }

    func setPickup(_ place: LocationPlace) {
        mutateState { draftState in
            draftState.requestDraft.pickup = place
            draftState.requestDraft.selectedRideTypeId = nil
            if !draftState.places.contains(where: { $0.id == place.id }) {
                draftState.places.append(place)
            }
        }
        refreshRideOptions()
    }

    func setPickupFromCurrentLocation() {
        locationManager.requestLocation()
        if let place = locationManager.currentPlace {
            setPickup(place)
        }
    }

    func setDestinationFromCurrentLocation() {
        locationManager.requestLocation()
        if let place = locationManager.currentPlace {
            setDestination(place)
        }
    }

    func setDestination(_ place: LocationPlace) {
        mutateState { draftState in
            draftState.requestDraft.destination = place
            draftState.requestDraft.selectedRideTypeId = nil
            draftState.recentDestinations = SeedData.addRecentDestination(place, to: draftState.recentDestinations)
            if !draftState.places.contains(where: { $0.id == place.id }) {
                draftState.places.append(place)
            }
        }
        refreshRideOptions()
    }

    func setDestination(from savedPlace: SavedPlace) {
        if let knownPlace = state.places.first(where: { $0.displayName == savedPlace.displayName }) {
            setDestination(knownPlace)
            return
        }

        let convertedPlace = LocationPlace(
            id: "saved_\(savedPlace.id)",
            displayName: savedPlace.displayName,
            address: savedPlace.address,
            latitudePlaceholder: savedPlace.latitudePlaceholder,
            longitudePlaceholder: savedPlace.longitudePlaceholder
        )
        setDestination(convertedPlace)
    }

    func renameSavedPlace(savedPlaceID: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        mutateState { draftState in
            guard let idx = draftState.savedPlaces.firstIndex(where: { $0.id == savedPlaceID }) else {
                return
            }
            draftState.savedPlaces[idx].displayName = trimmed
        }
    }

    func addSavedPlace(from place: LocationPlace, preferredName: String? = nil) {
        let trimmedPreferredName = preferredName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let displayName = trimmedPreferredName.isEmpty ? place.displayName : trimmedPreferredName

        if state.savedPlaces.contains(where: {
            $0.displayName.caseInsensitiveCompare(displayName) == .orderedSame &&
            $0.address.caseInsensitiveCompare(place.address) == .orderedSame
        }) {
            inlineStatusMessage = "Saved place already exists."
            return
        }

        let nextFavoriteCount = state.savedPlaces.filter { $0.type == .favorite }.count + 1
        let newSavedPlace = SavedPlace(
            id: "saved_favorite_\(nextFavoriteCount)",
            type: .favorite,
            displayName: displayName,
            address: place.address,
            latitudePlaceholder: place.latitudePlaceholder,
            longitudePlaceholder: place.longitudePlaceholder
        )

        mutateState { draftState in
            draftState.savedPlaces.append(newSavedPlace)
        }
        inlineStatusMessage = "Added \(displayName) to saved places."
    }

    func swapPickupAndDestination() {
        mutateState { draftState in
            let oldPickup = draftState.requestDraft.pickup
            draftState.requestDraft.pickup = draftState.requestDraft.destination
            draftState.requestDraft.destination = oldPickup
            draftState.requestDraft.selectedRideTypeId = nil
        }
        refreshRideOptions()
    }

    func setRideTiming(_ timing: RideTimingOption) {
        mutateState { draftState in
            draftState.requestDraft.rideTiming = timing
            if timing == .now {
                draftState.requestDraft.reservedDate = nil
            } else if draftState.requestDraft.reservedDate == nil {
                draftState.requestDraft.reservedDate = Date().addingTimeInterval(90 * 60)
            }
        }
    }

    func setReservedDate(_ date: Date) {
        mutateState { draftState in
            draftState.requestDraft.reservedDate = date
        }
    }

    func setSortOption(_ option: RideSortOption) {
        mutateState { draftState in
            draftState.requestDraft.sortOption = option
        }
        refreshRideOptions()
    }

    func setFilterCategory(_ category: RideFilterCategory) {
        mutateState { draftState in
            draftState.requestDraft.filterCategory = category
        }
        refreshRideOptions()
    }

    func setMaxETA(minutes: Int) {
        mutateState { draftState in
            draftState.requestDraft.maxETAMinutes = minutes
        }
        refreshRideOptions()
    }

    func setLowerPriceOnly(_ enabled: Bool) {
        mutateState { draftState in
            draftState.requestDraft.lowerPriceOnly = enabled
        }
        refreshRideOptions()
    }

    func setPromoCode(_ code: String) {
        mutateState { draftState in
            draftState.requestDraft.promoCode = code
        }
        refreshRideOptions()
    }

    func selectRideType(id: String) {
        mutateState { draftState in
            draftState.requestDraft.selectedRideTypeId = id
        }
    }

    func setPaymentMethod(id: String) {
        guard let method = state.walletState.paymentMethods.first(where: { $0.id == id }) else {
            return
        }
        guard method.isAvailable else {
            inlineStatusMessage = "payment method unavailable"
            return
        }
        mutateState { draftState in
            draftState.selectedPaymentMethodId = id
        }
    }

    func setFareMode(_ mode: FareSourceType) {
        mutateState { draftState in
            draftState.fareMode = mode
            if mode == .seeded {
                draftState.currentSnapshotMetadata = nil
            }
        }
        if mode == .snapshot {
            _ = snapshotFareRepository.load(location: state.snapshotLocation)
            mutateState { draftState in
                draftState.currentSnapshotMetadata = snapshotFareRepository.metadata()
            }
            if snapshotFareRepository.metadata() == nil {
                inlineStatusMessage = "fare data unavailable"
            }
        }
        refreshRideOptions()
    }

    func setSnapshotLocation(_ location: SnapshotLocation) {
        mutateState { draftState in
            draftState.snapshotLocation = location
        }

        if state.fareMode == .snapshot {
            let loaded = snapshotFareRepository.load(location: location)
            mutateState { draftState in
                draftState.currentSnapshotMetadata = snapshotFareRepository.metadata()
            }
            inlineStatusMessage = loaded ? "Fare data updated." : "fare data unavailable"
            refreshRideOptions()
        }
    }

    func reloadBundledSnapshotData() {
        let loaded = snapshotFareRepository.load(location: .bundled)
        mutateState { draftState in
            draftState.currentSnapshotMetadata = snapshotFareRepository.metadata()
        }
        inlineStatusMessage = loaded ? "Fare data reloaded." : "fare data unavailable"
        if state.fareMode == .snapshot {
            refreshRideOptions()
        }
    }

    func copyBundledSnapshotToSandbox() {
        let copied = snapshotFareRepository.copyBundledSnapshotToSandbox()
        inlineStatusMessage = copied ? "Fare data copied." : "fare data unavailable"
    }

    func loadSandboxSnapshotData() {
        let loaded = snapshotFareRepository.load(location: .sandbox)
        if loaded {
            mutateState { draftState in
                draftState.snapshotLocation = .sandbox
                draftState.currentSnapshotMetadata = snapshotFareRepository.metadata()
                draftState.fareMode = .snapshot
            }
            inlineStatusMessage = "Fare data loaded."
        } else {
            inlineStatusMessage = "fare data unavailable"
        }
        refreshRideOptions()
    }

    func requestRide() -> Trip? {
        guard let pickup = state.requestDraft.pickup else {
            inlineStatusMessage = "invalid pickup/destination"
            return nil
        }
        guard let destination = state.requestDraft.destination else {
            inlineStatusMessage = "invalid pickup/destination"
            return nil
        }
        guard pickup.id != destination.id else {
            inlineStatusMessage = "same pickup and destination"
            return nil
        }
        guard let selectedRide = selectedRideOption else {
            inlineStatusMessage = "no ride options found"
            return nil
        }
        guard state.walletState.paymentMethods.contains(where: { $0.id == state.selectedPaymentMethodId && $0.isAvailable }) else {
            inlineStatusMessage = "payment method unavailable"
            return nil
        }

        let now = Date()
        let rideStatus: TripStatus = state.requestDraft.rideTiming == .reserve ? .reserved : .requesting
        let tripID = "trip_\(UUID().uuidString.prefix(8).lowercased())"
        let minimumReserveDate = now.addingTimeInterval(5 * 60)
        let proposedReserveDate = state.requestDraft.reservedDate ?? now.addingTimeInterval(3600)
        let reservedAt = state.requestDraft.rideTiming == .reserve ? max(proposedReserveDate, minimumReserveDate) : nil

        let newTrip = Trip(
            id: tripID,
            pickupName: pickup.displayName,
            destinationName: destination.displayName,
            rideType: selectedRide.rideTypeName,
            rideTypeId: selectedRide.rideTypeIdentifier,
            etaMinutes: selectedRide.etaMinutes,
            estimatedPrice: selectedRide.estimatedPrice,
            currency: selectedRide.currency,
            routeLabel: firstRouteLabel(for: selectedRide) ?? "Main route",
            tripStatus: rideStatus,
            requestedAt: now,
            reservedFor: reservedAt,
            pickupTime: nil,
            dropoffTime: nil,
            paymentMethodId: state.selectedPaymentMethodId,
            sourceType: selectedRide.sourceType,
            driver: nil,
            vehicle: nil,
            pickupNotes: "",
            dropoffNotes: ""
        )

        mutateState { draftState in
            draftState.trips.insert(newTrip, at: 0)
            draftState.requestDraft.selectedRideTypeId = selectedRide.id
            if draftState.requestDraft.rideTiming == .reserve {
                draftState.requestDraft.reservedDate = reservedAt
            }
            if let destination = draftState.requestDraft.destination {
                draftState.recentDestinations = SeedData.addRecentDestination(destination, to: draftState.recentDestinations)
            }
        }
        inlineStatusMessage = rideStatus == .reserved ? "Ride reserved." : "Ride requested."
        if lifecycleTimer == nil { startLifecycleTimer() }
        refreshRideOptions()
        return newTrip
    }

    func startReservedTrip(_ tripID: String) {
        updateTrip(tripID: tripID) { trip, state in
            guard trip.tripStatus == .reserved else { return }
            trip.tripStatus = .requesting
            trip.reservedFor = nil
            trip.requestedAt = Date()
            assignDriverIfNeeded(to: &trip, state: &state)
            trip.tripStatus = .driverAssigned
            inlineStatusMessage = "Reserved ride started."
        }
        if lifecycleTimer == nil { startLifecycleTimer() }
    }

    func advanceActiveTrip() {
        guard let activeTrip else {
            inlineStatusMessage = "no active trips"
            return
        }
        advanceTrip(tripID: activeTrip.id)
    }

    func advanceTrip(tripID: String) {
        updateTrip(tripID: tripID) { trip, state in
            guard trip.tripStatus.canAdvance else {
                return
            }

            let nextStatus = trip.tripStatus.next()
            switch nextStatus {
            case .driverAssigned:
                assignDriverIfNeeded(to: &trip, state: &state)
            case .driverAtPickup:
                trip.pickupTime = Date()
            case .tripInProgress:
                if trip.pickupTime == nil {
                    trip.pickupTime = Date()
                }
            case .tripCompleted:
                if trip.pickupTime == nil {
                    trip.pickupTime = Date().addingTimeInterval(-12 * 60)
                }
                trip.dropoffTime = Date()
                trip.tripStatus = .tripCompleted
                createReceiptIfNeeded(for: trip, state: &state)
            case .requesting, .driverArriving, .canceled, .reserved:
                break
            }

            trip.tripStatus = nextStatus
            inlineStatusMessage = "Trip status moved to \(nextStatus.label)."
        }
    }

    func cancelTrip(tripID: String) {
        updateTrip(tripID: tripID) { trip, _ in
            guard trip.isCancelable else {
                inlineStatusMessage = "ride cancellation unavailable"
                return
            }
            trip.tripStatus = .canceled
            trip.reservedFor = nil
            trip.dropoffTime = Date()
            inlineStatusMessage = "Ride canceled."
        }
    }

    func completeTrip(tripID: String) {
        updateTrip(tripID: tripID) { trip, state in
            guard trip.tripStatus != .tripCompleted && trip.tripStatus != .canceled else {
                return
            }
            if trip.driver == nil || trip.vehicle == nil {
                assignDriverIfNeeded(to: &trip, state: &state)
            }
            if trip.pickupTime == nil {
                trip.pickupTime = Date().addingTimeInterval(-15 * 60)
            }
            trip.tripStatus = .tripCompleted
            trip.dropoffTime = Date()
            createReceiptIfNeeded(for: trip, state: &state)
            inlineStatusMessage = "Trip marked completed."
        }
    }

    func addTipToReceipt(tripID: String, tip: Double) {
        if let index = state.receipts.firstIndex(where: { $0.tripId == tripID }) {
            state.receipts[index].tip = tip
            state.receipts[index].receiptTotal += tip
        }
    }

    func postStatusMessage(_ message: String) {
        inlineStatusMessage = message
    }

    func clearStatusMessage() {
        inlineStatusMessage = nil
    }

    func setAutoLifecycleProgression(_ enabled: Bool) {
        lifecycleAutoAdvanceEnabled = enabled
    }

    func resetAppState() {
        persistence.clearState()
        let refreshed = SeedData.initialState(referenceDate: SeedData.seedReferenceDate)
        lifecycleAutoAdvanceEnabled = true
        state = refreshed
        inlineStatusMessage = "App state reset."
        persistence.saveState(state)
        refreshRideOptions()
    }

    func refreshRideOptions() {
        guard let pickup = state.requestDraft.pickup,
              let destination = state.requestDraft.destination else {
            currentRideOptions = []
            return
        }

        if pickup.id == destination.id {
            currentRideOptions = []
            inlineStatusMessage = "same pickup and destination"
            return
        }

        let repository = activeRepository()
        var estimates = repository.estimates(pickup: pickup, destination: destination)

        if estimates.isEmpty {
            currentRideOptions = []
            inlineStatusMessage = state.fareMode == .snapshot ? "fare data unavailable" : "no ride options found"
            return
        }

        if state.requestDraft.filterCategory != .all {
            estimates = estimates.filter { $0.category == state.requestDraft.filterCategory }
        }

        estimates = estimates.filter { $0.etaMinutes <= state.requestDraft.maxETAMinutes }

        if state.requestDraft.lowerPriceOnly, let cheapest = estimates.map(\.estimatedPrice).min() {
            let threshold = cheapest + 8.0
            estimates = estimates.filter { $0.estimatedPrice <= threshold }
        }

        if estimates.isEmpty {
            currentRideOptions = []
            inlineStatusMessage = "no matching filters"
            return
        }

        let sorted: [RouteEstimate]
        switch state.requestDraft.sortOption {
        case .lowestPrice:
            sorted = estimates.sorted(by: { $0.estimatedPrice < $1.estimatedPrice })
        case .highestPrice:
            sorted = estimates.sorted(by: { $0.estimatedPrice > $1.estimatedPrice })
        case .fastestETA:
            sorted = estimates.sorted(by: { $0.etaMinutes < $1.etaMinutes })
        }

        // Apply promo code discount if set
        let promoDiscount = Self.promoDiscount(for: state.requestDraft.promoCode)

        currentRideOptions = sorted.map {
            let discountedPrice = promoDiscount > 0
                ? max(1.0, ($0.estimatedPrice * (1.0 - promoDiscount) * 100).rounded() / 100)
                : $0.estimatedPrice
            return RideOption(
                id: $0.rideTypeId,
                rideTypeName: $0.rideType,
                seats: $0.seats,
                etaMinutes: $0.etaMinutes,
                estimatedPrice: discountedPrice,
                currency: $0.currency,
                serviceLabel: $0.serviceLabel,
                badges: $0.badges,
                category: $0.category,
                sourceType: $0.sourceType
            )
        }

        let previousSelection = state.requestDraft.selectedRideTypeId
        if let selected = previousSelection,
           currentRideOptions.contains(where: { $0.id == selected }) {
            // Keep current selection.
        } else {
            mutateState { draftState in
                draftState.requestDraft.selectedRideTypeId = currentRideOptions.first?.id
            }
            if previousSelection != nil, let fallback = currentRideOptions.first {
                inlineStatusMessage = "Switched to \(fallback.rideTypeName)."
            }
        }

        if state.fareMode == .snapshot {
            mutateState { draftState in
                draftState.currentSnapshotMetadata = snapshotFareRepository.metadata()
            }
        }
    }

    private func activeRepository() -> FareRepository {
        if state.fareMode == .snapshot {
            if snapshotFareRepository.metadata() == nil {
                _ = snapshotFareRepository.load(location: state.snapshotLocation)
            }
            return snapshotFareRepository
        }
        return seededFareRepository
    }

    private func firstRouteLabel(for option: RideOption) -> String? {
        guard let pickup = state.requestDraft.pickup,
              let destination = state.requestDraft.destination else {
            return nil
        }

        return activeRepository()
            .estimates(pickup: pickup, destination: destination)
            .first(where: { $0.rideTypeId == option.id })?
            .routeLabel
    }

    private var selectedRideOption: RideOption? {
        if let selectedRideTypeID = state.requestDraft.selectedRideTypeId {
            return currentRideOptions.first(where: { $0.id == selectedRideTypeID })
        }
        return currentRideOptions.first
    }

    private func createReceiptIfNeeded(for trip: Trip, state: inout CityRideSimState) {
        guard state.receipts.contains(where: { $0.tripId == trip.id }) == false,
              let newReceipt = SeedData.receipt(for: trip, generatedAt: trip.dropoffTime ?? Date()) else {
            return
        }
        state.receipts.append(newReceipt)

        if let accountId = selectedMyBankAccountId {
            CityRideMyBankLedgerWriter.recordRide(trip, total: newReceipt.receiptTotal, paymentAccountId: accountId)
        }
        CityRideMailOutboxWriter.recordRideEmail(trip, receipt: newReceipt)
    }

    private func assignDriverIfNeeded(to trip: inout Trip, state: inout CityRideSimState) {
        guard trip.driver == nil || trip.vehicle == nil else {
            return
        }
        let assignment = SeedData.nextDriverVehicle(index: state.nextDriverIndex)
        trip.driver = assignment.0
        trip.vehicle = assignment.1
        state.nextDriverIndex += 1
    }

    private func updateTrip(tripID: String, mutation: (inout Trip, inout CityRideSimState) -> Void) {
        var draft = state
        guard let tripIndex = draft.trips.firstIndex(where: { $0.id == tripID }) else {
            return
        }

        var trip = draft.trips[tripIndex]
        mutation(&trip, &draft)
        draft.trips[tripIndex] = trip
        state = draft
        persistence.saveState(state)
    }

    private func mutateState(_ mutation: (inout CityRideSimState) -> Void) {
        var draft = state
        mutation(&draft)
        state = draft
        persistence.saveState(state)
    }

    private func startLifecycleTimer() {
        lifecycleTimer?.invalidate()
        lifecycleTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.lifecycleAutoAdvanceEnabled else { return }
            guard let trip = self.activeTrip else {
                self.lifecycleTimer?.invalidate()
                self.lifecycleTimer = nil
                return
            }
            self.advanceTrip(tripID: trip.id)
        }
    }

    /// Returns a fractional discount (0.0–1.0) for a given promo code string.
    private static func promoDiscount(for code: String) -> Double {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { return 0 }
        // Deterministic discount based on code: 5–25% off
        let hash = abs(normalized.hashValue)
        return Double(5 + (hash % 21)) / 100.0
    }
}
