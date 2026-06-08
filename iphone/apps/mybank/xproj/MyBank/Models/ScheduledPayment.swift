import Foundation

enum ScheduledPaymentStatus: String, Codable, CaseIterable, Identifiable {
    case scheduled
    case executed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .executed: return "Executed"
        }
    }
}

struct ScheduledPayment: Identifiable, Codable, Hashable {
    var id: UUID
    var payeeId: UUID
    var amount: Double
    var scheduleDate: Date
    var note: String?
    var status: ScheduledPaymentStatus

    enum CodingKeys: String, CodingKey {
        case id
        case payeeId = "payee_id"
        case amount
        case scheduleDate = "schedule_date"
        case note
        case status
    }

    init(
        id: UUID,
        payeeId: UUID,
        amount: Double,
        scheduleDate: Date,
        note: String? = nil,
        status: ScheduledPaymentStatus
    ) {
        self.id = id
        self.payeeId = payeeId
        self.amount = amount
        self.scheduleDate = scheduleDate
        self.note = note
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        payeeId = try container.decode(UUID.self, forKey: .payeeId)
        amount = try container.decode(Double.self, forKey: .amount)
        scheduleDate = try container.decode(Date.self, forKey: .scheduleDate)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        status = try container.decode(ScheduledPaymentStatus.self, forKey: .status)
    }
}
