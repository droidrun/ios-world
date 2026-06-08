import Foundation

enum LedgerStorageMode: String {
    case appGroup = "App Group"
    case localFallback = "Local (Documents)"
}

final class LedgerService {
    static let appGroupID = "group.com.iosworld.benchmark.personalsuite"

    private let ledgerFileName = "mybank_ledger.json"

    /// Shared ledger JSON schema (array of objects):
    /// Required fields: id (UUID), external_id (String), account_id (UUID), vendor (String), amount (Number),
    /// currency (String), category (String), timestamp (ISO8601), status ("pending"|"posted"), source_app (String).
    /// Optional fields: note (String), raw_source (String).
    /// Example entry:
    /// {"id":"UUID","external_id":"UUID","account_id":"UUID","vendor":"MockDoorDash","amount":-24.99,
    ///  "currency":"USD","category":"Food","note":"Chicken bowl","timestamp":"2024-09-10T12:00:00Z",
    ///  "status":"pending","source_app":"MockDoorDash","raw_source":"mybank://ingest?..."}
    var ledgerFileURL: URL {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) {
            return appGroupURL.appendingPathComponent(ledgerFileName)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(ledgerFileName)
    }

    var storageMode: LedgerStorageMode {
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) != nil {
            return .appGroup
        }
        return .localFallback
    }

    func loadLedger() -> [Transaction] {
        guard let data = try? Data(contentsOf: ledgerFileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Transaction].self, from: data)) ?? []
    }

    func saveLedger(_ records: [Transaction]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: ledgerFileURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("[Ledger] Failed to write ledger: \(error)")
            #endif
        }
    }

    func upsertRecord(_ record: Transaction) {
        var records = loadLedger()
        if let index = records.firstIndex(where: { $0.externalId == record.externalId }) {
            records[index] = record
        } else {
            records.append(record)
        }
        saveLedger(records)
    }

    func clearLedger() {
        saveLedger([])
    }
}
