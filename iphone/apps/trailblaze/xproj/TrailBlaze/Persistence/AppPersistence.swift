import Foundation

enum AppPersistenceError: LocalizedError {
    case bundledSnapshotMissing
    case sandboxSnapshotMissing
    case unreadableSnapshot
    case invalidSnapshot

    var errorDescription: String? {
        switch self {
        case .bundledSnapshotMissing:
            return "The bundled activity snapshot could not be found."
        case .sandboxSnapshotMissing:
            return "No sandbox snapshot has been imported yet."
        case .unreadableSnapshot:
            return "The selected snapshot file could not be read."
        case .invalidSnapshot:
            return "The snapshot file is not valid for TrailBlazeSim."
        }
    }
}

struct AppPersistence {
    private let fileManager = FileManager.default
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadState() -> PersistedState? {
        guard let data = try? Data(contentsOf: stateURL()) else {
            return nil
        }
        return try? decoder.decode(PersistedState.self, from: data)
    }

    func saveState(_ state: PersistedState) throws {
        try ensureDirectory()
        let data = try encoder.encode(state)
        try data.write(to: stateURL(), options: .atomic)
    }

    func resetPersistence() throws {
        let urls = [stateURL(), importedSnapshotURL()]
        for url in urls where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func bundledSnapshotExists() -> Bool {
        Bundle.main.url(forResource: "activity_snapshot", withExtension: "json") != nil
    }

    func loadBundledSnapshot() throws -> ActivitySnapshot {
        guard let url = Bundle.main.url(forResource: "activity_snapshot", withExtension: "json") else {
            throw AppPersistenceError.bundledSnapshotMissing
        }
        return try decodeSnapshot(at: url)
    }

    func importSandboxSnapshot(from sourceURL: URL) throws -> ActivitySnapshot {
        try ensureDirectory()
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let data = try? Data(contentsOf: sourceURL) else {
            throw AppPersistenceError.unreadableSnapshot
        }

        try data.write(to: importedSnapshotURL(), options: .atomic)
        return try decodeSnapshot(data: data)
    }

    func loadImportedSandboxSnapshot() throws -> ActivitySnapshot? {
        let url = importedSnapshotURL()
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        return try decodeSnapshot(at: url)
    }

    func importedSnapshotFilename() -> String? {
        let url = importedSnapshotURL()
        return fileManager.fileExists(atPath: url.path) ? url.lastPathComponent : nil
    }

    private func decodeSnapshot(at url: URL) throws -> ActivitySnapshot {
        guard let data = try? Data(contentsOf: url) else {
            throw AppPersistenceError.unreadableSnapshot
        }
        return try decodeSnapshot(data: data)
    }

    private func decodeSnapshot(data: Data) throws -> ActivitySnapshot {
        do {
            return try decoder.decode(ActivitySnapshot.self, from: data)
        } catch {
            throw AppPersistenceError.invalidSnapshot
        }
    }

    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: appSupportURL(), withIntermediateDirectories: true, attributes: nil)
    }

    private func appSupportURL() -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL.appendingPathComponent("TrailBlazeSim", isDirectory: true)
    }

    private func stateURL() -> URL {
        appSupportURL().appendingPathComponent("app_state.json")
    }

    private func importedSnapshotURL() -> URL {
        appSupportURL().appendingPathComponent("imported_activity_snapshot.json")
    }
}
