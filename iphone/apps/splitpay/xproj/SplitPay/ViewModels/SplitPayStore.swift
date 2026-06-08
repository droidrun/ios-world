import Foundation

private extension Double {
    var roundedToCents: Double {
        (self * 100).rounded() / 100
    }
}

final class SplitPayStore: ObservableObject {
    // Bumped 3 -> 4: prior builds saved seedVersion but never persisted the seeded
    // transactions (didSet doesn't fire in init), so installs sit in a "version
    // matches, no stored transactions" state that re-mints UUIDs every launch. The
    // bump forces a one-time re-seed that now also persists the data (below).
    private static let currentSeedVersion = 4

    @Published private(set) var users: [User]
    @Published private(set) var fundingSources: [FundingSource]
    @Published var transactions: [Transaction] {
        didSet { Persistence.save(transactions, key: .transactions) }
    }
    @Published var requests: [Request] {
        didSet { Persistence.save(requests, key: .requests) }
    }
    @Published var balance: Double {
        didSet { Persistence.save(balance, key: .balance) }
    }
    @Published var friendIDs: Set<String> {
        didSet { Persistence.save(Array(friendIDs), key: .friends) }
    }
    @Published var settings: SettingsState {
        didSet { Persistence.save(settings, key: .settings) }
    }

    init() {
        let seededUsers = SeedData.users()
        let seededFunding = SeedData.fundingSources()
        let seededTransactions = SeedData.transactions(users: seededUsers)
        let seededRequests = SeedData.requests(users: seededUsers)
        let storedSeedVersion = Persistence.load(Int.self, key: .seedVersion, fallback: 0)
        let shouldResetToSeed = storedSeedVersion != Self.currentSeedVersion

        users = seededUsers
        fundingSources = seededFunding

        transactions = shouldResetToSeed
            ? seededTransactions
            : Persistence.load([Transaction].self, key: .transactions, fallback: seededTransactions)
        requests = shouldResetToSeed
            ? seededRequests
            : Persistence.load([Request].self, key: .requests, fallback: seededRequests)
        balance = shouldResetToSeed
            ? 250
            : Persistence.load(Double.self, key: .balance, fallback: 250)
        let defaultFriends = seededUsers
            .filter { ["user_brian", "user_trevor", "user_chenchen"].contains($0.id) }
            .prefix(5)
            .map(\.id)
        let savedFriends = shouldResetToSeed
            ? defaultFriends
            : Persistence.load([String].self, key: .friends, fallback: defaultFriends)
        let validFriendIDs = Self.validFriendIDSet(from: seededUsers)
        let filteredFriends = savedFriends.filter { validFriendIDs.contains($0) }
        friendIDs = filteredFriends.isEmpty ? Set(defaultFriends) : Set(filteredFriends)
        settings = shouldResetToSeed
            ? .default
            : Persistence.load(SettingsState.self, key: .settings, fallback: .default)

        Persistence.save(Self.currentSeedVersion, key: .seedVersion)

        // Property `didSet` observers DO NOT fire for assignments made inside an
        // initializer, so the freshly-seeded transactions/requests/etc. above are
        // held in memory but never written to UserDefaults on a seed reset. The
        // next launch then sees the matching seedVersion, tries to LOAD them, finds
        // nothing, and falls back to SeedData.transactions(...) — which mints brand
        // new UUID()s every call. That made every feed-row id (splitpay_feed_row_<uuid>)
        // change on each launch, so a uuid scraped by list_feed_transactions no longer
        // existed after open_transaction relaunched to a clean Home — the live-eval
        // open_transaction failure. Persist the seed explicitly here so the ids are
        // stable across launches (and a stored seed is loaded verbatim next time).
        if shouldResetToSeed {
            Persistence.save(transactions, key: .transactions)
            Persistence.save(requests, key: .requests)
            Persistence.save(balance, key: .balance)
            Persistence.save(Array(friendIDs), key: .friends)
            Persistence.save(settings, key: .settings)
        }

        refreshUsersFromContacts()
    }

    var you: User {
        users.first { $0.isYou } ?? users[0]
    }

    func user(for id: String) -> User? {
        users.first { $0.id == id }
    }

    func fundingSource(for id: String) -> FundingSource? {
        fundingSources.first { $0.id == id }
    }

    func preferredPaymentSource(for amount: Double) -> FundingSource {
        if canUseBalance(amount: amount), let balanceSource = fundingSources.first(where: { $0.isBalance }) {
            return balanceSource
        }
        if let externalSource = fundingSources.first(where: { !$0.isBalance }) {
            return externalSource
        }
        return FundingSource(
            id: "balance",
            name: "SplitPay balance",
            subtitle: "Available instantly",
            isBalance: true
        )
    }

    func isFriend(_ userID: String) -> Bool {
        friendIDs.contains(userID)
    }

    func toggleFriend(_ userID: String) {
        if friendIDs.contains(userID) {
            friendIDs.remove(userID)
        } else {
            friendIDs.insert(userID)
        }
    }

    func filteredTransactions(filter: FeedFilter) -> [Transaction] {
        switch filter {
        case .all:
            return transactions
        case .friends:
            return transactions.filter { isFriend($0.fromUserID == you.id ? $0.toUserID : $0.fromUserID) }
        case .me:
            return transactions.filter { $0.fromUserID == you.id || $0.toUserID == you.id }
        }
    }

    func transactions(for userID: String) -> [Transaction] {
        transactions.filter { $0.fromUserID == userID || $0.toUserID == userID }
            .prefix(5)
            .map { $0 }
    }

    func canUseBalance(amount: Double) -> Bool {
        balance >= amount
    }

    func addTransaction(from fromID: String, to toID: String, amount: Double, memo: String, privacy: TransactionPrivacy, fundingSourceID: String) -> Transaction {
        let transaction = Transaction(
            id: UUID(),
            fromUserID: fromID,
            toUserID: toID,
            amount: amount,
            memo: memo,
            timestamp: Date(),
            privacy: privacy,
            fundingSourceID: fundingSourceID
        )
        transactions.insert(transaction, at: 0)
        return transaction
    }

    func pay(recipientID: String, amount: Double, memo: String, privacy: TransactionPrivacy, fundingSourceID: String) -> Transaction? {
        guard amount > 0 else { return nil }
        if fundingSourceID == "balance", !canUseBalance(amount: amount) { return nil }

        if fundingSourceID == "balance" {
            balance = (balance - amount).roundedToCents
        }
        let transaction = addTransaction(from: you.id, to: recipientID, amount: amount, memo: memo, privacy: privacy, fundingSourceID: fundingSourceID)
        let recipientName = user(for: recipientID)?.displayName ?? "someone"
        SplitPayMailOutboxWriter.recordPaymentEmail(amount: amount, to: recipientName, memo: memo)
        print("[MockSplitPay] Pay confirmed: \(transaction.id)")
        return transaction
    }

    func createRequest(to recipientID: String, amount: Double, memo: String, privacy: TransactionPrivacy) -> Request? {
        guard amount > 0 else { return nil }
        let request = Request(
            id: UUID(),
            fromUserID: you.id,
            toUserID: recipientID,
            amount: amount,
            memo: memo,
            timestamp: Date(),
            privacy: privacy,
            status: .pending
        )
        requests.insert(request, at: 0)
        let recipientName = user(for: recipientID)?.displayName ?? "someone"
        SplitPayMailOutboxWriter.recordRequestEmail(amount: amount, from: recipientName, memo: memo)
        print("[MockSplitPay] Request created: \(request.id)")
        return request
    }

    func createInboundRequest(from senderID: String, amount: Double, memo: String, privacy: TransactionPrivacy) -> Request {
        let request = Request(
            id: UUID(),
            fromUserID: senderID,
            toUserID: you.id,
            amount: amount,
            memo: memo,
            timestamp: Date(),
            privacy: privacy,
            status: .pending
        )
        requests.insert(request, at: 0)
        return request
    }

    func payRequest(_ request: Request, fundingSourceID: String) -> Transaction? {
        guard request.status == .pending else { return nil }
        if fundingSourceID == "balance", !canUseBalance(amount: request.amount) { return nil }

        if fundingSourceID == "balance" {
            balance = (balance - request.amount).roundedToCents
        }
        let transaction = addTransaction(from: you.id, to: request.fromUserID, amount: request.amount, memo: request.memo, privacy: request.privacy, fundingSourceID: fundingSourceID)
        updateRequest(requestID: request.id, status: .paid)
        print("[MockSplitPay] Request paid: \(request.id)")
        return transaction
    }

    func declineRequest(_ requestID: UUID) {
        updateRequest(requestID: requestID, status: .declined)
        print("[MockSplitPay] Request declined: \(requestID)")
    }

    func cancelRequest(_ requestID: UUID) {
        updateRequest(requestID: requestID, status: .canceled)
        print("[MockSplitPay] Request canceled: \(requestID)")
    }

    private func updateRequest(requestID: UUID, status: RequestStatus) {
        guard let index = requests.firstIndex(where: { $0.id == requestID }) else { return }
        requests[index].status = status
    }

    func addFunds(amount: Double) -> Transaction? {
        guard amount > 0 else { return nil }
        balance = (balance + amount).roundedToCents
        let transaction = addTransaction(from: SeedData.systemID, to: you.id, amount: amount, memo: "Added funds", privacy: .private, fundingSourceID: "balance")
        print("[MockSplitPay] Add funds: \(amount)")
        return transaction
    }

    func cashOut(amount: Double) -> Transaction? {
        guard amount > 0, balance >= amount else { return nil }
        balance = (balance - amount).roundedToCents
        let transaction = addTransaction(from: you.id, to: SeedData.systemID, amount: amount, memo: "Cash out", privacy: .private, fundingSourceID: "balance")
        print("[MockSplitPay] Cash out: \(amount)")
        return transaction
    }

    private static func validFriendIDSet(from users: [User]) -> Set<String> {
        Set(users.filter { !$0.isYou && $0.id != SeedData.systemID }.map(\.id))
    }

    private func refreshUsersFromContacts() {
        // Keep the mock app deterministic so screenshots and automation remain stable.
    }

    func resetState() {
        let seededUsers = SeedData.users()
        users = seededUsers
        fundingSources = SeedData.fundingSources()
        transactions = SeedData.transactions(users: seededUsers)
        requests = SeedData.requests(users: seededUsers)
        balance = 250
        friendIDs = Set(["user_brian", "user_trevor", "user_chenchen"])
        settings = .default
        Persistence.clearAll()
        Persistence.save(Self.currentSeedVersion, key: .seedVersion)
        SplitPayMailOutboxWriter.clearOwnRecords()
        print("[MockSplitPay] Reset app state")
    }
}

struct SplitPayMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "splitpay.venmo_outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordPaymentEmail(amount: Double, to recipient: String, memo: String) {
        guard let url = inboxURL() else { return }
        let amountText = String(format: "$%.2f", amount)
        let record = MailRecord(
            id: UUID(),
            from: "Venmo",
            subject: "You paid \(recipient) \(amountText)",
            body: "You paid \(recipient) \(amountText) for \"\(memo)\".\n\nThanks,\nVenmo",
            category: 1,
            date: Date()
        )
        appendRecord(record, to: url)
    }

    static func recordRequestEmail(amount: Double, from requester: String, memo: String) {
        guard let url = inboxURL() else { return }
        let amountText = String(format: "$%.2f", amount)
        let record = MailRecord(
            id: UUID(),
            from: "Venmo",
            subject: "You requested \(amountText) from \(requester)",
            body: "You requested \(amountText) from \(requester) for \"\(memo)\".\n\nThanks,\nVenmo",
            category: 1,
            date: Date()
        )
        appendRecord(record, to: url)
    }

    /// Serialized background append: load → append → save on a utility queue so the calling
    /// thread (typically main) doesn't block on file I/O. Ordering matches call order.
    private static func appendRecord(_ record: MailRecord, to url: URL) {
        ioQueue.async {
            var records = loadRecords(from: url)
            records.append(record)
            saveRecords(records, to: url)
        }
    }

    /// Removes records this app wrote (from == "Venmo") from the shared inbox.
    /// Called by SplitPayStore.resetState() so a manual reset doesn't leave orphaned emails.
    /// Serialized on the same ioQueue to barrier against in-flight appends.
    static func clearOwnRecords() {
        guard let url = inboxURL() else { return }
        ioQueue.async {
            let records = loadRecords(from: url).filter { $0.from != "Venmo" }
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
