import Foundation

struct IngestRequest {
    var amount: Double
    var currency: String
    var vendor: String
    var category: String
    var note: String?
    var timestamp: Date
    var externalId: String
}

enum DeepLinkError: LocalizedError {
    case invalidScheme
    case invalidAction
    case missingField(String)
    case invalidField(String)

    var errorDescription: String? {
        switch self {
        case .invalidScheme:
            return "Unsupported URL scheme."
        case .invalidAction:
            return "Unsupported deep link action."
        case .missingField(let name):
            return "Missing field: \(name)."
        case .invalidField(let name):
            return "Invalid field: \(name)."
        }
    }
}

final class DeepLinkService {
    func parse(url: URL) -> Result<IngestRequest, DeepLinkError> {
        guard url.scheme == "mybank" else { return .failure(.invalidScheme) }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .failure(.invalidAction)
        }

        let action = components.host ?? components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard action == "ingest" else { return .failure(.invalidAction) }

        let queryItems = components.queryItems ?? []
        func value(_ name: String) -> String? {
            queryItems.first(where: { $0.name == name })?.value
        }

        guard let amountValue = value("amount") else { return .failure(.missingField("amount")) }
        guard let amount = Double(amountValue) else { return .failure(.invalidField("amount")) }

        guard let currency = value("currency"), !currency.isEmpty else {
            return .failure(.missingField("currency"))
        }
        guard let vendor = value("vendor"), !vendor.isEmpty else {
            return .failure(.missingField("vendor"))
        }
        guard let category = value("category"), !category.isEmpty else {
            return .failure(.missingField("category"))
        }
        guard let timestampValue = value("timestamp"), !timestampValue.isEmpty else {
            return .failure(.missingField("timestamp"))
        }
        let timestamp = Formatters.iso8601.date(from: timestampValue)
            ?? ISO8601DateFormatter().date(from: timestampValue)
        guard let parsedTimestamp = timestamp else { return .failure(.invalidField("timestamp")) }

        guard let externalId = value("external_id"), !externalId.isEmpty else {
            return .failure(.missingField("external_id"))
        }
        guard UUID(uuidString: externalId) != nil else {
            return .failure(.invalidField("external_id"))
        }

        let note = value("note")

        let request = IngestRequest(
            amount: amount,
            currency: currency,
            vendor: vendor,
            category: category,
            note: note,
            timestamp: parsedTimestamp,
            externalId: externalId
        )
        return .success(request)
    }
}
