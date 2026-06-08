import Foundation
import Observation

enum CheckoutPlacementError: LocalizedError {
    case emptyCart
    case missingPaymentMethod
    case insufficientFunds(required: Double, available: Double)

    var errorDescription: String? {
        switch self {
        case .emptyCart:
            return "Your cart is empty."
        case .missingPaymentMethod:
            return "No saved card is available."
        case .insufficientFunds(let required, let available):
            return String(format: "Insufficient funds. Total: $%.2f, Available: $%.2f", required, available)
        }
    }
}

enum PromoRedemptionError: LocalizedError {
    case invalidCode
    case alreadyRedeemed
    case alreadyConsumed

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "That promo code isn't valid or has expired."
        case .alreadyRedeemed:
            return "That promo code is already in your wallet."
        case .alreadyConsumed:
            return "That promo code was already used."
        }
    }
}

struct CheckoutPreview: Hashable {
    let subtotal: Double
    let fees: Double
    let discount: Double
    let total: Double
    let appliedPromo: PromoCode?
}

enum CheckoutPaymentAccountType: String, Codable {
    case checking
    case savings
    case credit
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
        case .checking:
            return "**** **** **** 6645"
        case .savings:
            return "**** **** **** 7814"
        case .credit:
            return "**** **** **** 2095"
        }
    }

    var network: String {
        switch type {
        case .credit:
            return "MASTERCARD"
        case .checking:
            return "VISA DEBIT"
        case .savings:
            return "MASTERCARD DEBIT"
        }
    }

    var displayName: String {
        "\(network) \(maskedNumber)"
    }
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
        guard let data = try? Data(contentsOf: accountsURL) else {
            return defaultAccounts()
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([CheckoutPaymentAccount].self, from: data), !decoded.isEmpty {
            return decoded
        }

        return defaultAccounts()
    }

    private func defaultAccounts() -> [CheckoutPaymentAccount] {
        let now = Date()
        return [
            CheckoutPaymentAccount(
                id: UUID(),
                name: "Total Checking (...6645)",
                type: .checking,
                balance: 2150.32,
                availableBalance: 2150.32,
                currency: "USD",
                lastUpdated: now,
                creditLimit: nil
            ),
            CheckoutPaymentAccount(
                id: UUID(),
                name: "Savings (...1032)",
                type: .savings,
                balance: 9400.00,
                availableBalance: 9400.00,
                currency: "USD",
                lastUpdated: now,
                creditLimit: nil
            ),
            CheckoutPaymentAccount(
                id: UUID(),
                name: "Freedom Unlimited (...2095)",
                type: .credit,
                balance: -642.13,
                availableBalance: 5357.87,
                currency: "USD",
                lastUpdated: now,
                creditLimit: 6000.0
            )
        ]
    }
}

struct TicketBoxMyBankLedgerWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mybank_ledger.json"
    private static let ioQueue = DispatchQueue(label: "ticketbox.seatgeek_ledger.io", qos: .utility)

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

    static func recordOrder(_ order: Order, total: Double, paymentAccountId: UUID) {
        guard let url = ledgerURL() else {
            print("[MyBank] App Group unavailable; SeatGeek ledger write skipped.")
            return
        }

        let firstItem = order.items.first
        let vendor = firstItem?.venueName.isEmpty == false ? firstItem?.venueName ?? "TicketBox" : "TicketBox"
        let note = order.items.map { "\($0.quantity)x \($0.eventTitle)" }.joined(separator: ", ")

        let record = LedgerTransaction(
            id: UUID(),
            externalId: order.id.uuidString,
            accountId: paymentAccountId,
            vendor: vendor,
            amount: -abs(total),
            currency: "USD",
            category: "Tickets",
            note: note.isEmpty ? nil : note,
            timestamp: Date(),
            status: "pending",
            sourceApp: "TicketBox",
            rawSource: "ticketbox_checkout"
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

    /// Removes ledger entries this app wrote (sourceApp == "TicketBox") from the shared ledger.
    /// Called by MockTicketBoxStore.resetState() so a manual reset doesn't leave orphaned rows.
    static func clearOwnRecords() {
        guard let url = ledgerURL() else { return }
        ioQueue.async {
            let records = loadLedger(from: url).filter { $0.sourceApp != "TicketBox" }
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
            print("[MyBank] Failed to write SeatGeek ledger: \(error)")
        }
    }
}

struct TicketBoxMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "ticketbox.seatgeek_outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordOrderEmail(_ order: Order, total: Double, recipientName: String) {
        guard let url = inboxURL() else {
            print("[Mail] App Group unavailable; SeatGeek email write skipped.")
            return
        }

        let totalText = String(format: "$%.2f", total)
        let subject = "Your TicketBox order is confirmed"
        let ticketSummary = order.items.map { "\($0.quantity)x \($0.eventTitle)" }.joined(separator: ", ")
        let body = """
        Hi \(recipientName),

        Your TicketBox order is confirmed.

        Order number: \(order.orderNumber)
        Total: \(totalText)
        Tickets: \(ticketSummary)

        Thanks,
        TicketBox
        """

        let record = MailRecord(
            id: order.id,
            from: "TicketBox",
            subject: subject,
            body: body,
            category: 1,
            date: Date()
        )

        ioQueue.async {
            var records = loadRecords(from: url)
            if records.contains(where: { $0.id == record.id }) {
                return
            }
            records.append(record)
            saveRecords(records, to: url)
        }
    }

    /// Removes records this app wrote (from == "TicketBox") from the shared inbox.
    /// Called by MockTicketBoxStore.resetState() so a manual reset doesn't leave orphaned emails.
    static func clearOwnRecords() {
        guard let url = inboxURL() else { return }
        ioQueue.async {
            let records = loadRecords(from: url).filter { $0.from != "TicketBox" }
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
            print("[Mail] Failed to write SeatGeek email: \(error)")
        }
    }
}

@Observable final class MockTicketBoxStore {
    private(set) var performers: [Performer]
    private(set) var venues: [Venue]
    private(set) var events: [Event]
    private(set) var pastTickets: [TicketArchiveItem]

    var upcomingEvents: [Event] {
        let now = Date()
        return events.filter { $0.date >= now }
    }

    var selectedTab: TicketBoxTab = .browse

    var favoriteEventIDs: Set<UUID> {
        didSet { Persistence.save(Array(favoriteEventIDs), key: .favoriteEvents) }
    }

    var favoritePerformerIDs: Set<UUID> {
        didSet { Persistence.save(Array(favoritePerformerIDs), key: .favoritePerformers) }
    }

    var favoriteVenueIDs: Set<UUID> {
        didSet { Persistence.save(Array(favoriteVenueIDs), key: .favoriteVenues) }
    }

    var recentSearches: [SearchRecord] {
        didSet { Persistence.save(recentSearches, key: .recentSearches) }
    }

    var recentlyViewedEventIDs: [UUID] {
        didSet { Persistence.save(recentlyViewedEventIDs, key: .recentlyViewedEvents) }
    }

    var cartItems: [CartItem] {
        didSet { Persistence.save(cartItems, key: .cartItems) }
    }

    var orders: [Order] {
        didSet { Persistence.save(orders, key: .orders) }
    }

    private(set) var listedOrderIDs: Set<UUID>

    var saleListings: [SaleListing] {
        didSet {
            listedOrderIDs = Set(saleListings.map(\.orderID))
            Persistence.save(Array(listedOrderIDs), key: .listedOrders)
            Persistence.save(saleListings, key: .saleListings)
        }
    }

    var promoCodes: [PromoCode] {
        didSet { Persistence.save(promoCodes, key: .promoCodes) }
    }

    var settings: SettingsState {
        didSet { Persistence.save(settings, key: .settings) }
    }

    private(set) var paymentAccounts: [CheckoutPaymentAccount]
    var selectedPaymentAccountID: UUID?

    private let myBankAccountsService = MyBankCheckoutAccountsService()

    init() {
        let seededPerformers = SeedData.makePerformers()
        let seededVenues = SeedData.makeVenues()
        let seededEvents = SeedData.makeEvents(venues: seededVenues, performers: seededPerformers)
        let seededPastTickets = SeedData.makePastTickets()

        performers = seededPerformers
        venues = seededVenues
        events = seededEvents
        pastTickets = seededPastTickets

        let performerIDs = Set(seededPerformers.map(\.id))
        let venueIDs = Set(seededVenues.map(\.id))
        let eventIDs = Set(seededEvents.map(\.id))

        let savedEventFavorites = Persistence.load([UUID].self, key: .favoriteEvents, fallback: SeedData.defaultFavoriteEventIDs())
        let savedPerformerFavorites = Persistence.load([UUID].self, key: .favoritePerformers, fallback: SeedData.defaultFavoritePerformerIDs())
        let savedVenueFavorites = Persistence.load([UUID].self, key: .favoriteVenues, fallback: SeedData.defaultFavoriteVenueIDs())
        let savedRecentSearches = Persistence.load(
            [SearchRecord].self,
            key: .recentSearches,
            fallback: SeedData.defaultRecentSearches(events: seededEvents, performers: seededPerformers, venues: seededVenues)
        )
        let savedRecentlyViewed = Persistence.load([UUID].self, key: .recentlyViewedEvents, fallback: SeedData.defaultRecentlyViewedEvents())
        let savedCart = Persistence.load([CartItem].self, key: .cartItems, fallback: [])
        let savedOrders = Persistence.load([Order].self, key: .orders, fallback: SeedData.defaultOrders(events: seededEvents, venues: seededVenues))
        let savedListedOrders = Persistence.load([UUID].self, key: .listedOrders, fallback: [])
        let savedSaleListings = Persistence.load([SaleListing].self, key: .saleListings, fallback: [])
        let savedPromoCodes = Persistence.load([PromoCode].self, key: .promoCodes, fallback: SeedData.defaultPromoCodes())
        var initialSettings = Persistence.load(SettingsState.self, key: .settings, fallback: .default)
        let availableCities = ["San Francisco, CA", "San Jose, CA", "Oakland, CA", "Stanford, CA", "Mountain View, CA"]

        if !availableCities.contains(initialSettings.selectedCity) {
            initialSettings.selectedCity = SettingsState.default.selectedCity
            initialSettings.hasManualLocationOverride = false
        }

        let seededFavoriteEvents = Set(SeedData.defaultFavoriteEventIDs().filter { eventIDs.contains($0) })
        let seededFavoritePerformers = Set(SeedData.defaultFavoritePerformerIDs().filter { performerIDs.contains($0) })
        let seededFavoriteVenues = Set(SeedData.defaultFavoriteVenueIDs().filter { venueIDs.contains($0) })

        favoriteEventIDs = Persistence.contains(.favoriteEvents)
            ? Set(savedEventFavorites.filter { eventIDs.contains($0) })
            : seededFavoriteEvents
        favoritePerformerIDs = Persistence.contains(.favoritePerformers)
            ? Set(savedPerformerFavorites.filter { performerIDs.contains($0) })
            : seededFavoritePerformers
        favoriteVenueIDs = Persistence.contains(.favoriteVenues)
            ? Set(savedVenueFavorites.filter { venueIDs.contains($0) })
            : seededFavoriteVenues
        recentSearches = savedRecentSearches.filter { record in
            guard let referenceID = record.referenceID else {
                return record.kind == .suggestion
            }
            return eventIDs.contains(referenceID) || performerIDs.contains(referenceID) || venueIDs.contains(referenceID)
        }
        recentlyViewedEventIDs = savedRecentlyViewed.filter { eventIDs.contains($0) }
        cartItems = savedCart
        orders = savedOrders
        let validOrderIDs = Set(savedOrders.map(\.id))
        let initialSaleListings: [SaleListing]
        if Persistence.contains(.saleListings) {
            initialSaleListings = savedSaleListings.filter { validOrderIDs.contains($0.orderID) }
        } else {
            initialSaleListings = savedListedOrders.compactMap { listedID in
                guard validOrderIDs.contains(listedID),
                      let order = savedOrders.first(where: { $0.id == listedID }) else {
                    return nil
                }
                return SaleListing(
                    orderID: listedID,
                    askingPrice: Self.recommendedSalePrice(for: order),
                    lastUpdated: order.createdAt
                )
            }
        }
        listedOrderIDs = Set(initialSaleListings.map(\.orderID))
        saleListings = initialSaleListings
        promoCodes = savedPromoCodes
        settings = initialSettings

        paymentAccounts = myBankAccountsService.loadAccounts()
        selectedPaymentAccountID = paymentAccounts.first(where: { $0.type == .credit })?.id ?? paymentAccounts.first?.id
    }

    var cities: [String] {
        ["San Francisco, CA", "San Jose, CA", "Oakland, CA", "Stanford, CA", "Mountain View, CA"]
    }

    var shouldAutoDetectLocation: Bool {
        !settings.hasManualLocationOverride
    }

    var searchSuggestions: [SearchSuggestion] {
        SeedData.searchSuggestions()
    }

    var featuredEvent: Event? {
        let localEvents = browseEvents(for: nil)
        return localEvents.first(where: { $0.title == "Chicago Bulls at Golden State Warriors" }) ?? localEvents.first
    }

    var trendingEvents: [Event] {
        let localTrending = eventsMatching(ids: [eventID(3001), eventID(3002), eventID(3003)])
            .filter { cityMatches(selection: settings.selectedCity, eventCity: $0.city) }
        if !localTrending.isEmpty {
            return sort(events: localTrending, by: settings.preferredSort)
        }
        return Array(browseEvents(for: nil).prefix(3))
    }

    var recommendedPerformers: [Performer] {
        performersMatching(ids: [performerID(2007), performerID(2008), performerID(2032), performerID(2033), performerID(2034), performerID(2042)])
    }

    var favoriteEvents: [Event] {
        sort(events: eventsMatching(ids: Array(favoriteEventIDs)), by: .soonestDate)
    }

    var favoritePerformers: [Performer] {
        performersMatching(ids: Array(favoritePerformerIDs))
            .sorted { lhs, rhs in
                if lhs.eventCount == rhs.eventCount {
                    return lhs.name < rhs.name
                }
                return lhs.eventCount > rhs.eventCount
            }
    }

    var favoriteVenues: [Venue] {
        venuesMatching(ids: Array(favoriteVenueIDs))
            .sorted { $0.name < $1.name }
    }

    var recentlyViewedEvents: [Event] {
        eventsMatching(ids: recentlyViewedEventIDs)
    }

    var activePromoCodes: [PromoCode] {
        promoCodes
            .filter { $0.isRedeemed && !$0.isConsumed && $0.expiresAt >= Date() }
            .sorted { lhs, rhs in
                if lhs.discountAmount == rhs.discountAmount {
                    return lhs.expiresAt < rhs.expiresAt
                }
                return lhs.discountAmount > rhs.discountAmount
            }
    }

    var promoCatalog: [PromoCode] {
        SeedData.promoCatalog()
    }

    var usedPromoCodes: [PromoCode] {
        promoCodes
            .filter(\.isConsumed)
            .sorted { $0.expiresAt > $1.expiresAt }
    }

    var selectedPaymentAccount: CheckoutPaymentAccount? {
        guard let selectedPaymentAccountID else { return nil }
        return paymentAccounts.first(where: { $0.id == selectedPaymentAccountID })
    }

    func event(for id: UUID) -> Event? {
        events.first(where: { $0.id == id })
    }

    func venue(for id: UUID) -> Venue? {
        venues.first(where: { $0.id == id })
    }

    func performer(for id: UUID) -> Performer? {
        performers.first(where: { $0.id == id })
    }

    func browseEvents(for category: EventCategory?) -> [Event] {
        let upcoming = upcomingEvents
        let filteredByCity = upcoming.filter { cityMatches(selection: settings.selectedCity, eventCity: $0.city) }
        let filteredByCategory = category == nil ? filteredByCity : filteredByCity.filter { $0.category == category }
        let base = filteredByCategory.isEmpty ? events(for: category) : filteredByCategory
        return sort(events: base, by: settings.preferredSort)
    }

    func events(for category: EventCategory?) -> [Event] {
        let upcoming = upcomingEvents
        let filtered = category == nil ? upcoming : upcoming.filter { $0.category == category }
        return sort(events: filtered, by: settings.preferredSort)
    }

    func events(forPerformerID performerID: UUID) -> [Event] {
        sort(events: upcomingEvents.filter { event in
            event.performers.contains(where: { $0.id == performerID })
        }, by: .soonestDate)
    }

    func events(forVenueID venueID: UUID) -> [Event] {
        sort(events: upcomingEvents.filter { $0.venueID == venueID }, by: .soonestDate)
    }

    func minPrice(for event: Event) -> Double {
        event.listings.map(\.price).min() ?? 0
    }

    func minListing(for event: Event) -> TicketListing? {
        event.listings.min(by: { $0.price < $1.price })
    }

    func toggleFavoriteEvent(_ eventID: UUID) {
        if favoriteEventIDs.contains(eventID) {
            favoriteEventIDs.remove(eventID)
        } else {
            favoriteEventIDs.insert(eventID)
        }
    }

    func toggleFavoritePerformer(_ performerID: UUID) {
        if favoritePerformerIDs.contains(performerID) {
            favoritePerformerIDs.remove(performerID)
        } else {
            favoritePerformerIDs.insert(performerID)
        }
    }

    func toggleFavoriteVenue(_ venueID: UUID) {
        if favoriteVenueIDs.contains(venueID) {
            favoriteVenueIDs.remove(venueID)
        } else {
            favoriteVenueIDs.insert(venueID)
        }
    }

    func toggleMusicService(_ service: MusicServiceKind) {
        if settings.connectedMusicServices.contains(service) {
            settings.connectedMusicServices.remove(service)
        } else {
            settings.connectedMusicServices.insert(service)
        }
    }

    func updateLocation(_ location: String) {
        guard cities.contains(location) else { return }
        settings.selectedCity = location
        settings.hasManualLocationOverride = true
    }

    func applyDetectedLocation(_ location: String) {
        guard cities.contains(location), shouldAutoDetectLocation else { return }
        settings.selectedCity = location
    }

    func revertToDeviceLocation() {
        settings.hasManualLocationOverride = false
        settings.selectedCity = SettingsState.default.selectedCity
    }

    func updatePreferredSort(_ sortOption: SortOption) {
        settings.preferredSort = sortOption
    }

    func updateProfile(name: String, email: String, phone: String) {
        settings.profileName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.profileEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.profilePhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func updateDeliveryAddress(_ address: String) {
        settings.deliveryAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func toggleListedOrder(_ orderID: UUID) {
        if saleListing(for: orderID) != nil {
            removeSaleListing(orderID: orderID)
        } else {
            guard let order = orders.first(where: { $0.id == orderID }) else { return }
            upsertSaleListing(orderID: orderID, askingPrice: Self.recommendedSalePrice(for: order))
        }
    }

    func saleListing(for orderID: UUID) -> SaleListing? {
        saleListings.first(where: { $0.orderID == orderID })
    }

    func upsertSaleListing(orderID: UUID, askingPrice: Double) {
        guard orders.contains(where: { $0.id == orderID }) else { return }
        let normalizedPrice = max(5, askingPrice.rounded())

        if let index = saleListings.firstIndex(where: { $0.orderID == orderID }) {
            saleListings[index].askingPrice = normalizedPrice
            saleListings[index].lastUpdated = Date()
        } else {
            saleListings.insert(
                SaleListing(
                    orderID: orderID,
                    askingPrice: normalizedPrice,
                    lastUpdated: Date()
                ),
                at: 0
            )
        }
    }

    func removeSaleListing(orderID: UUID) {
        saleListings.removeAll { $0.orderID == orderID }
    }

    func recommendedSalePrice(for order: Order) -> Double {
        Self.recommendedSalePrice(for: order)
    }

    func redeemPromoCode(_ rawCode: String) -> Result<PromoCode, PromoRedemptionError> {
        let normalizedCode = rawCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !normalizedCode.isEmpty else {
            return .failure(.invalidCode)
        }

        if let existingIndex = promoCodes.firstIndex(where: { $0.code == normalizedCode }) {
            if promoCodes[existingIndex].isConsumed {
                return .failure(.alreadyConsumed)
            }
            if promoCodes[existingIndex].isRedeemed {
                return .failure(.alreadyRedeemed)
            }
            promoCodes[existingIndex].isRedeemed = true
            return .success(promoCodes[existingIndex])
        }

        guard let matchingPromo = promoCatalog.first(where: { $0.code == normalizedCode }) else {
            return .failure(.invalidCode)
        }

        var redeemedPromo = matchingPromo
        redeemedPromo.isRedeemed = true
        promoCodes.insert(redeemedPromo, at: 0)
        return .success(redeemedPromo)
    }

    func checkoutPreview(for items: [CartItem]) -> CheckoutPreview {
        let subtotal = items.reduce(0.0) { partialResult, item in
            partialResult + (item.pricePerTicket * Double(item.quantity))
        }
        let fees = items.reduce(0.0) { partialResult, item in
            partialResult + (item.feesPerTicket * Double(item.quantity))
        }
        let appliedPromo = bestPromo(for: subtotal)
        let discount = min(appliedPromo?.discountAmount ?? 0, subtotal + fees)
        return CheckoutPreview(
            subtotal: subtotal,
            fees: fees,
            discount: discount,
            total: max(0, subtotal + fees - discount),
            appliedPromo: appliedPromo
        )
    }

    func importMLBTickets() -> Bool {
        guard settings.hasMLBAccountLinked,
              let order = SeedData.importedMLBOrder(events: events, venues: venues),
              !orders.contains(where: { $0.id == order.id }) else {
            return false
        }

        orders.insert(order, at: 0)
        return true
    }

    func recoverConcertOrder() -> Bool {
        guard let order = SeedData.recoverableConcertOrder(events: events, venues: venues),
              !orders.contains(where: { $0.id == order.id }) else {
            return false
        }

        orders.insert(order, at: 0)
        return true
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
    }

    func recordViewedEvent(_ eventID: UUID) {
        recentlyViewedEventIDs.removeAll { $0 == eventID }
        recentlyViewedEventIDs.insert(eventID, at: 0)
        recentlyViewedEventIDs = Array(recentlyViewedEventIDs.prefix(6))

        if let event = event(for: eventID), let venue = venue(for: event.venueID) {
            addSearchRecord(
                title: event.title,
                subtitle: venue.name,
                imageName: event.imageName,
                kind: .event,
                referenceID: event.id
            )
        }
    }

    func recordSearch(for performer: Performer) {
        addSearchRecord(
            title: performer.name,
            subtitle: performer.category.rawValue,
            imageName: performer.imageName,
            kind: .performer,
            referenceID: performer.id
        )
    }

    func recordSearch(for venue: Venue) {
        addSearchRecord(
            title: venue.name,
            subtitle: venue.city,
            imageName: venue.imageName,
            kind: .venue,
            referenceID: venue.id
        )
    }

    func recordSearch(for suggestion: SearchSuggestionKind) {
        addSearchRecord(
            title: suggestion.title,
            subtitle: "Suggestion",
            imageName: suggestion.rawValue,
            kind: .suggestion,
            referenceID: nil
        )
    }

    func filteredEvents(query: String) -> [Event] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        return sort(events: upcomingEvents.filter { event in
            let venueName = venue(for: event.venueID)?.name.lowercased() ?? ""
            let performerNames = event.performers.map(\.name).joined(separator: " ").lowercased()
            let searchable = [event.title.lowercased(), venueName, performerNames, event.city.lowercased()]
            return searchable.contains(where: { $0.contains(trimmed) })
        }, by: .soonestDate)
    }

    func filteredPerformers(query: String) -> [Performer] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        return performers.filter { $0.name.lowercased().contains(trimmed) }
            .sorted { lhs, rhs in
                if lhs.eventCount == rhs.eventCount {
                    return lhs.name < rhs.name
                }
                return lhs.eventCount > rhs.eventCount
            }
    }

    func filteredVenues(query: String) -> [Venue] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        return venues.filter { venue in
            venue.name.lowercased().contains(trimmed) || venue.city.lowercased().contains(trimmed)
        }
        .sorted { $0.name < $1.name }
    }

    func eventsForSuggestion(_ suggestion: SearchSuggestionKind) -> [Event] {
        switch suggestion {
        case .popularEvents:
            return trendingEvents + eventsMatching(ids: [eventID(3004), eventID(3012), eventID(3013), eventID(3017), eventID(3033), eventID(3044)])
        case .favoritePerformers:
            let performerIDs = favoritePerformerIDs.isEmpty ? Set(recommendedPerformers.prefix(3).map(\.id)) : favoritePerformerIDs
            let filtered = upcomingEvents.filter { event in
                event.performers.contains(where: { performerIDs.contains($0.id) })
            }
            return sort(events: filtered, by: .soonestDate)
        case .justAnnounced:
            return eventsMatching(ids: [eventID(3033), eventID(3034), eventID(3044), eventID(3045), eventID(3023), eventID(3018), eventID(3015), eventID(3014)])
        }
    }

    func addToCart(listing: TicketListing, event: Event, quantity: Int) {
        let safeQuantity = max(1, min(quantity, listing.quantityAvailable))
        if let index = cartItems.firstIndex(where: { $0.listingID == listing.id }) {
            cartItems[index].quantity = min(listing.quantityAvailable, cartItems[index].quantity + safeQuantity)
        } else {
            let venueName = venue(for: event.venueID)?.name ?? "TicketBox"
            cartItems.append(
                CartItem(
                    id: listing.id,
                    listingID: listing.id,
                    eventID: event.id,
                    eventTitle: event.title,
                    venueName: venueName,
                    city: event.city,
                    eventDate: event.date,
                    section: listing.section,
                    row: listing.row,
                    seatRange: listing.seatRange,
                    quantityAvailable: listing.quantityAvailable,
                    pricePerTicket: listing.price,
                    feesPerTicket: listing.fees,
                    deliveryType: listing.deliveryType,
                    quantity: safeQuantity
                )
            )
        }
    }

    func updateCartItemQuantity(itemID: UUID, quantity: Int) {
        guard let index = cartItems.firstIndex(where: { $0.id == itemID }) else { return }
        let maxQuantity = cartItems[index].quantityAvailable
        cartItems[index].quantity = max(1, min(quantity, maxQuantity))
    }

    func removeCartItem(itemID: UUID) {
        cartItems.removeAll { $0.id == itemID }
    }

    func clearCart() {
        cartItems.removeAll()
    }

    func refreshPaymentAccounts() {
        paymentAccounts = myBankAccountsService.loadAccounts()
        if selectedPaymentAccountID == nil || !paymentAccounts.contains(where: { $0.id == selectedPaymentAccountID }) {
            selectedPaymentAccountID = paymentAccounts.first(where: { $0.type == .credit })?.id ?? paymentAccounts.first?.id
        }
    }

    func placeOrder(
        deliveryMethod: CheckoutDeliveryMethod,
        contactMethod: ContactMethod,
        paymentAccountID: UUID?
    ) -> Result<Order, CheckoutPlacementError> {
        guard !cartItems.isEmpty else {
            return .failure(.emptyCart)
        }

        let result = createOrder(
            items: cartItems,
            deliveryMethod: deliveryMethod,
            contactMethod: contactMethod,
            paymentAccountID: paymentAccountID
        )

        if case .success = result {
            cartItems.removeAll()
        }

        return result
    }

    func purchase(listing: TicketListing, event: Event, quantity: Int) -> Result<Order, CheckoutPlacementError> {
        let safeQuantity = max(1, min(quantity, listing.quantityAvailable))
        let venueName = venue(for: event.venueID)?.name ?? "TicketBox"
        let item = CartItem(
            id: UUID(),
            listingID: listing.id,
            eventID: event.id,
            eventTitle: event.title,
            venueName: venueName,
            city: event.city,
            eventDate: event.date,
            section: listing.section,
            row: listing.row,
            seatRange: listing.seatRange,
            quantityAvailable: listing.quantityAvailable,
            pricePerTicket: listing.price,
            feesPerTicket: listing.fees,
            deliveryType: listing.deliveryType,
            quantity: safeQuantity
        )

        let result = createOrder(
            items: [item],
            deliveryMethod: listing.isInstant ? .instant : .mobileTransfer,
            contactMethod: .email,
            paymentAccountID: selectedPaymentAccountID
        )

        if case .success = result {
            selectedTab = .tickets
        }

        return result
    }

    /// Fetches full-season schedules from the public sports data API for Bay Area teams
    /// and replaces the seeded sports events with live data.
    func loadLiveSportsEvents() async {
        let service = LiveSportsService()
        let liveEvents = await service.fetchSeasonEvents(
            performers: performers,
            venues: venues
        )

        guard !liveEvents.isEmpty else { return }

        // Collect any new performers from live data that aren't already in the list
        let existingPerformerIDs = Set(performers.map(\.id))
        var newPerformers: [Performer] = []
        for event in liveEvents {
            for performer in event.performers where !existingPerformerIDs.contains(performer.id) && !newPerformers.contains(where: { $0.id == performer.id }) {
                newPerformers.append(performer)
            }
        }

        // Remove seeded sports events, keep everything else
        let nonSportsEvents = events.filter { $0.category != .sports }
        events = nonSportsEvents + liveEvents
        performers = performers + newPerformers

        print("[LiveSports] Loaded \(liveEvents.count) live sports events, \(newPerformers.count) new performers")
    }

    func resetState() {
        performers = SeedData.makePerformers()
        venues = SeedData.makeVenues()
        events = SeedData.makeEvents(venues: venues, performers: performers)
        pastTickets = SeedData.makePastTickets()

        favoriteEventIDs = Set(SeedData.defaultFavoriteEventIDs())
        favoritePerformerIDs = Set(SeedData.defaultFavoritePerformerIDs())
        favoriteVenueIDs = Set(SeedData.defaultFavoriteVenueIDs())
        recentSearches = SeedData.defaultRecentSearches(events: events, performers: performers, venues: venues)
        recentlyViewedEventIDs = SeedData.defaultRecentlyViewedEvents()
        cartItems = []
        orders = SeedData.defaultOrders(events: events, venues: venues)
        saleListings = []
        listedOrderIDs = []
        promoCodes = SeedData.defaultPromoCodes()
        settings = .default
        selectedTab = .browse
        paymentAccounts = myBankAccountsService.loadAccounts()
        selectedPaymentAccountID = paymentAccounts.first(where: { $0.type == .credit })?.id ?? paymentAccounts.first?.id
        Persistence.clearAll()
        TicketBoxMailOutboxWriter.clearOwnRecords()
        TicketBoxMyBankLedgerWriter.clearOwnRecords()
        print("[SeatGeek] Account reset")
    }

    private func addSearchRecord(
        title: String,
        subtitle: String,
        imageName: String,
        kind: SearchRecordKind,
        referenceID: UUID?
    ) {
        recentSearches.removeAll { existing in
            existing.kind == kind && existing.referenceID == referenceID && existing.title == title
        }

        recentSearches.insert(
            SearchRecord(
                id: UUID(),
                title: title,
                subtitle: subtitle,
                imageName: imageName,
                kind: kind,
                referenceID: referenceID
            ),
            at: 0
        )

        recentSearches = Array(recentSearches.prefix(6))
    }

    private func createOrder(
        items: [CartItem],
        deliveryMethod: CheckoutDeliveryMethod,
        contactMethod: ContactMethod,
        paymentAccountID: UUID?
    ) -> Result<Order, CheckoutPlacementError> {
        if let paymentAccountID {
            selectedPaymentAccountID = paymentAccountID
        }

        let paymentAccount = selectedPaymentAccount
            ?? paymentAccounts.first(where: { $0.type == .credit })
            ?? paymentAccounts.first

        if let fallback = paymentAccount, selectedPaymentAccountID == nil {
            selectedPaymentAccountID = fallback.id
        }

        guard let paymentAccount else {
            return .failure(.missingPaymentMethod)
        }

        let checkout = checkoutPreview(for: items)

        guard paymentAccount.availableBalance >= checkout.total else {
            return .failure(.insufficientFunds(required: checkout.total, available: paymentAccount.availableBalance))
        }

        let created = Date()
        let estimatedDelivery = Calendar.current.date(byAdding: .minute, value: Int.random(in: 4...12), to: created) ?? created
        let order = Order(
            id: UUID(),
            orderNumber: "SG-\(Int.random(in: 100000...999999))",
            items: items,
            createdAt: created,
            estimatedDelivery: estimatedDelivery,
            deliveryMethod: deliveryMethod,
            contactMethod: contactMethod,
            appliedPromoCode: checkout.appliedPromo?.code,
            discountAmount: checkout.discount > 0 ? checkout.discount : nil,
            totalPaid: checkout.total
        )

        orders.insert(order, at: 0)
        if let appliedPromo = checkout.appliedPromo,
           let promoIndex = promoCodes.firstIndex(where: { $0.id == appliedPromo.id }) {
            promoCodes[promoIndex].isConsumed = true
        }
        TicketBoxMyBankLedgerWriter.recordOrder(order, total: checkout.total, paymentAccountId: paymentAccount.id)
        TicketBoxMailOutboxWriter.recordOrderEmail(order, total: checkout.total, recipientName: settings.profileName)
        print("[TicketBox] Order placed: \(order.orderNumber)")
        return .success(order)
    }

    private func sort(events: [Event], by sortOption: SortOption) -> [Event] {
        switch sortOption {
        case .recommended:
            return events.sorted { lhs, rhs in
                averageDealScore(for: lhs) > averageDealScore(for: rhs)
            }
        case .lowestPrice:
            return events.sorted { minPrice(for: $0) < minPrice(for: $1) }
        case .bestValue:
            return events.sorted { lhs, rhs in
                if averageDealScore(for: lhs) == averageDealScore(for: rhs) {
                    return minPrice(for: lhs) < minPrice(for: rhs)
                }
                return averageDealScore(for: lhs) > averageDealScore(for: rhs)
            }
        case .soonestDate:
            return events.sorted { $0.date < $1.date }
        }
    }

    private func averageDealScore(for event: Event) -> Double {
        guard !event.listings.isEmpty else { return 0 }
        let total = event.listings.map { Double($0.dealScore) }.reduce(0, +)
        return total / Double(event.listings.count)
    }

    private static func recommendedSalePrice(for order: Order) -> Double {
        let baseline = order.totalPaid ?? order.items.reduce(0.0) { partialResult, item in
            partialResult + ((item.pricePerTicket + item.feesPerTicket) * Double(item.quantity))
        }
        return max(10, (baseline * 1.08 / 5).rounded(.up) * 5)
    }

    private func bestPromo(for subtotal: Double) -> PromoCode? {
        activePromoCodes.first(where: { subtotal >= $0.minimumSpend })
    }

    private func cityMatches(selection: String?, eventCity: String) -> Bool {
        guard let selection, !selection.isEmpty else { return true }
        return normalizedCity(selection) == normalizedCity(eventCity)
    }

    private func normalizedCity(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: ", ca", with: "")
            .replacingOccurrences(of: ", california", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func eventID(_ seed: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", seed))") ?? UUID()
    }

    private func performerID(_ seed: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", seed))") ?? UUID()
    }

    private func eventsMatching(ids: [UUID]) -> [Event] {
        ids.compactMap { id in
            events.first(where: { $0.id == id })
        }
    }

    private func performersMatching(ids: [UUID]) -> [Performer] {
        ids.compactMap { id in
            performers.first(where: { $0.id == id })
        }
    }

    private func venuesMatching(ids: [UUID]) -> [Venue] {
        ids.compactMap { id in
            venues.first(where: { $0.id == id })
        }
    }
}
