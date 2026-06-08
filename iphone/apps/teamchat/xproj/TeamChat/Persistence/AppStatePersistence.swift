import Foundation

final class AppStatePersistence {
    private let stateFileName = "teamchatsim_state.json"

    private var stateFileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(stateFileName)
    }

    func loadState() -> TeamChatSimState? {
        guard let data = try? Data(contentsOf: stateFileURL) else {
            return nil
        }
        return try? JSONCoding.decoder().decode(TeamChatSimState.self, from: data)
    }

    func saveState(_ state: TeamChatSimState) {
        do {
            let data = try JSONCoding.encoder().encode(state)
            try data.write(to: stateFileURL, options: [.atomic])
        } catch {
            print("[Persistence] Failed to save app state: \(error.localizedDescription)")
        }
    }

    func clearState() {
        guard FileManager.default.fileExists(atPath: stateFileURL.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(at: stateFileURL)
        } catch {
            print("[Persistence] Failed to clear app state: \(error.localizedDescription)")
        }
    }
}
