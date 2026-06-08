import Foundation

final class AppPersistence {
    private let fileName = "fitnesssim_state.json"
    private let queue = DispatchQueue(label: "caltrack.persistence", qos: .utility)

    private var stateURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return (directory ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent(fileName)
    }

    /// Synchronous load — called once at FitnessStore init before first render.
    func loadState() -> FitnessAppState? {
        guard let data = try? Data(contentsOf: stateURL) else {
            return nil
        }

        do {
            return try makeDecoder().decode(FitnessAppState.self, from: data)
        } catch {
            print("[Persistence] Failed to load state: \(error)")
            return nil
        }
    }

    /// Synchronous save — use sparingly (e.g. first-launch seed).
    func saveState(_ state: FitnessAppState) {
        performSave(state)
    }

    /// Non-blocking save serialized on a background queue.
    /// Call from the main thread to keep UI responsive; writes preserve call order.
    func saveStateAsync(_ state: FitnessAppState) {
        queue.async { [weak self] in
            self?.performSave(state)
        }
    }

    /// Synchronously reset the persisted file, flushing any pending background writes first.
    func clearState() {
        queue.sync {
            do {
                if FileManager.default.fileExists(atPath: stateURL.path) {
                    try FileManager.default.removeItem(at: stateURL)
                }
            } catch {
                print("[Persistence] Failed to clear state: \(error)")
            }
        }
    }

    private func performSave(_ state: FitnessAppState) {
        do {
            let data = try makeEncoder().encode(state)
            try data.write(to: stateURL, options: [.atomic])
        } catch {
            print("[Persistence] Failed to save state: \(error)")
        }
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
