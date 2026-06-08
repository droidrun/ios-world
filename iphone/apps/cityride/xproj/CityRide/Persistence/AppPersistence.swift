import Foundation

final class AppPersistence {
    private let defaults: UserDefaults
    private let stateKey = "ubersim.state.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadState() -> CityRideSimState? {
        guard let data = defaults.data(forKey: stateKey) else {
            return nil
        }

        do {
            return try makeDecoder().decode(CityRideSimState.self, from: data)
        } catch {
            return nil
        }
    }

    func saveState(_ state: CityRideSimState) {
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
        let fileManager = FileManager.default
        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
           fileManager.isWritableFile(atPath: docsURL.path) {
            return docsURL.appendingPathComponent("fare_snapshot.json")
        }
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("fare_snapshot.json")
    }

    func readSandboxSnapshotData() -> Data? {
        try? Data(contentsOf: sandboxSnapshotURL)
    }

    func writeSandboxSnapshotData(_ data: Data) throws {
        try data.write(to: sandboxSnapshotURL, options: .atomic)
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
