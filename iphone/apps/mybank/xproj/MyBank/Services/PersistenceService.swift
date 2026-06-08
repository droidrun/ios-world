import Foundation

final class PersistenceService {
    private let fileName = "mybank_state.json"

    private var stateFileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }

    func loadState() -> BankState? {
        guard let data = try? Data(contentsOf: stateFileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BankState.self, from: data)
    }

    func saveState(_ state: BankState) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(state)
            try data.write(to: stateFileURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("[Persistence] Failed to save state: \(error)")
            #endif
        }
    }

    func clearState() {
        do {
            try FileManager.default.removeItem(at: stateFileURL)
        } catch {
            #if DEBUG
            print("[Persistence] Failed to clear state: \(error)")
            #endif
        }
    }
}
