import Foundation

final class AppPersistence {
    private let defaults: UserDefaults
    private let stateKey = "amazonsim.state.v3"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadState() -> MegaMartSimState? {
        guard let data = defaults.data(forKey: stateKey) else {
            return nil
        }

        do {
            return try makeDecoder().decode(MegaMartSimState.self, from: data)
        } catch {
            #if DEBUG
            print("[AppPersistence] Failed to decode MegaMartSimState: \(error)")
            #endif
            return nil
        }
    }

    func saveState(_ state: MegaMartSimState) {
        do {
            let data = try makeEncoder().encode(state)
            defaults.set(data, forKey: stateKey)
        } catch {
            print("[Persistence] Failed to save state: \(error)")
        }
    }

    func clearState() {
        defaults.removeObject(forKey: stateKey)
    }

    var sandboxSnapshotURL: URL {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return (docsURL ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("catalog_snapshot.json")
    }

    func readSandboxSnapshotData() -> Data? {
        try? Data(contentsOf: sandboxSnapshotURL)
    }

    func writeSandboxSnapshotData(_ data: Data) throws {
        try data.write(to: sandboxSnapshotURL, options: .atomic)
    }

    func removeSandboxSnapshotData() {
        try? FileManager.default.removeItem(at: sandboxSnapshotURL)
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
