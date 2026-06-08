import Foundation

final class AppPersistence {
    private let stateFileName = "instacartsim_state.json"

    private static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }

    private var stateFileURL: URL {
        Self.documentsDirectory().appendingPathComponent(stateFileName)
    }

    var sandboxSnapshotURL: URL {
        Self.documentsDirectory().appendingPathComponent("catalog_snapshot.json")
    }

    func loadState() -> FreshCartState? {
        guard let data = try? Data(contentsOf: stateFileURL) else {
            return nil
        }
        return try? decoder().decode(FreshCartState.self, from: data)
    }

    func saveState(_ state: FreshCartState) {
        do {
            let data = try encoder().encode(state)
            try data.write(to: stateFileURL, options: [.atomic])
        } catch {
            print("[Persistence] Failed to save app state: \(error.localizedDescription)")
        }
    }

    func clearState() {
        guard FileManager.default.fileExists(atPath: stateFileURL.path) else {
            return
        }
        try? FileManager.default.removeItem(at: stateFileURL)
    }

    func readSandboxSnapshotData() -> Data? {
        try? Data(contentsOf: sandboxSnapshotURL)
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
