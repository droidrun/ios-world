import Foundation

struct BankState: Codable {
    static let currentVersion = 9

    var version: Int
    var accounts: [Account]
    var transactions: [Transaction]
    var payees: [Payee]
    var scheduledPayments: [ScheduledPayment]
    var activatedOfferIds: Set<String>
    var redeemedRewardPoints: Int
    var creditScore: Int
    var userName: String
    var lastName: String

    init(
        version: Int = BankState.currentVersion,
        accounts: [Account],
        transactions: [Transaction],
        payees: [Payee],
        scheduledPayments: [ScheduledPayment],
        activatedOfferIds: Set<String> = [],
        redeemedRewardPoints: Int = 0,
        creditScore: Int = 742,
        userName: String = "Jordan",
        lastName: String = "Avery"
    ) {
        self.version = version
        self.accounts = accounts
        self.transactions = transactions
        self.payees = payees
        self.scheduledPayments = scheduledPayments
        self.activatedOfferIds = activatedOfferIds
        self.redeemedRewardPoints = redeemedRewardPoints
        self.creditScore = creditScore
        self.userName = userName
        self.lastName = lastName
    }

    enum CodingKeys: String, CodingKey {
        case version
        case accounts
        case transactions
        case payees
        case scheduledPayments
        case activatedOfferIds
        case redeemedRewardPoints
        case creditScore
        case userName
        case lastName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        accounts = try container.decode([Account].self, forKey: .accounts)
        transactions = try container.decode([Transaction].self, forKey: .transactions)
        payees = try container.decode([Payee].self, forKey: .payees)
        scheduledPayments = try container.decode([ScheduledPayment].self, forKey: .scheduledPayments)
        activatedOfferIds = try container.decodeIfPresent(Set<String>.self, forKey: .activatedOfferIds) ?? []
        redeemedRewardPoints = try container.decodeIfPresent(Int.self, forKey: .redeemedRewardPoints) ?? 0
        creditScore = try container.decodeIfPresent(Int.self, forKey: .creditScore) ?? 742
        userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? "Jordan"
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? "Avery"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(accounts, forKey: .accounts)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(payees, forKey: .payees)
        try container.encode(scheduledPayments, forKey: .scheduledPayments)
        try container.encode(activatedOfferIds, forKey: .activatedOfferIds)
        try container.encode(redeemedRewardPoints, forKey: .redeemedRewardPoints)
        try container.encode(creditScore, forKey: .creditScore)
        try container.encode(userName, forKey: .userName)
        try container.encode(lastName, forKey: .lastName)
    }
}
