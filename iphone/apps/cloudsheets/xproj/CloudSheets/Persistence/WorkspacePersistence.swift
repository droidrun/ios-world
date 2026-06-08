import Foundation

protocol WorkspaceRepository {
    func loadWorkspaceData() throws -> WorkspaceData
}

struct SeededWorkspaceRepository: WorkspaceRepository {
    func loadWorkspaceData() throws -> WorkspaceData {
        SeedDataFactory.makeSeededData()
    }
}

struct SnapshotWorkspaceRepository {
    let persistence: SharedWorkspacePersistence

    init(persistence: SharedWorkspacePersistence = SharedWorkspacePersistence()) {
        self.persistence = persistence
    }

    func loadBundledSnapshot() throws -> WorkspaceSnapshotPayload {
        try persistence.loadBundledSnapshotPayload()
    }

    func loadImportedSnapshot() throws -> WorkspaceSnapshotPayload? {
        try persistence.loadImportedSnapshotPayload()
    }
}

enum WorkspaceStorageMode: String {
    case appGroup = "App Group"
    case sharedDefaults = "Shared Defaults"
    case localFallback = "Local Fallback"
}

enum WorkspacePersistenceError: LocalizedError {
    case bundledSnapshotMissing
    case importedSnapshotMissing
    case unreadableSnapshot
    case invalidSnapshot

    var errorDescription: String? {
        switch self {
        case .bundledSnapshotMissing:
            return "The bundled workspace snapshot could not be found."
        case .importedSnapshotMissing:
            return "No imported workspace snapshot is available yet."
        case .unreadableSnapshot:
            return "The selected snapshot file could not be read."
        case .invalidSnapshot:
            return "The snapshot file is not valid for this workspace."
        }
    }
}

enum JSONCoding {
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

struct SharedWorkspacePersistence {
    static let appGroupID = "group.com.iosworld.benchmark.workspacesuite"

    private let stateFileName = "workspace_envelope.json"
    private let importedSnapshotFileName = "workspace_snapshot.imported.json"
    private let bundleSnapshotFileName = "workspace_snapshot"
    private let bundleSnapshotExtension = "json"
    private let defaultsEnvelopeKey = "workspace_envelope"
    private let defaultsImportedSnapshotKey = "workspace_snapshot_imported"
    private let fileManager = FileManager.default

    private enum BackingStore {
        case file(url: URL, mode: WorkspaceStorageMode)
        case defaults(UserDefaults)
    }

    var storageMode: WorkspaceStorageMode {
        switch backingStore() {
        case .file(_, let mode):
            return mode
        case .defaults:
            return .sharedDefaults
        }
    }

    func loadEnvelope() -> PersistedWorkspaceEnvelope? {
        switch backingStore() {
        case .file(let baseURL, _):
            let url = baseURL.appendingPathComponent(stateFileName)
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            return try? JSONCoding.decoder().decode(PersistedWorkspaceEnvelope.self, from: data)
        case .defaults(let defaults):
            guard let data = defaults.data(forKey: defaultsEnvelopeKey) else {
                return nil
            }
            return try? JSONCoding.decoder().decode(PersistedWorkspaceEnvelope.self, from: data)
        }
    }

    func saveEnvelope(_ envelope: PersistedWorkspaceEnvelope) throws {
        let data = try JSONCoding.encoder().encode(envelope)
        switch backingStore() {
        case .file(let baseURL, _):
            try ensureDirectory(baseURL)
            try data.write(to: baseURL.appendingPathComponent(stateFileName), options: .atomic)
        case .defaults(let defaults):
            defaults.set(data, forKey: defaultsEnvelopeKey)
        }
    }

    func resetPersistence() throws {
        switch backingStore() {
        case .file(let baseURL, _):
            let urls = [
                baseURL.appendingPathComponent(stateFileName),
                baseURL.appendingPathComponent(importedSnapshotFileName)
            ]
            for url in urls where fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        case .defaults(let defaults):
            defaults.removeObject(forKey: defaultsEnvelopeKey)
            defaults.removeObject(forKey: defaultsImportedSnapshotKey)
        }
    }

    func loadBundledSnapshotPayload() throws -> WorkspaceSnapshotPayload {
        guard let url = Bundle.main.url(forResource: bundleSnapshotFileName, withExtension: bundleSnapshotExtension),
              let data = try? Data(contentsOf: url) else {
            throw WorkspacePersistenceError.bundledSnapshotMissing
        }
        return try decodeSnapshot(from: data)
    }

    func loadImportedSnapshotPayload() throws -> WorkspaceSnapshotPayload? {
        switch backingStore() {
        case .file(let baseURL, _):
            let url = baseURL.appendingPathComponent(importedSnapshotFileName)
            guard fileManager.fileExists(atPath: url.path),
                  let data = try? Data(contentsOf: url) else {
                return nil
            }
            return try decodeSnapshot(from: data)
        case .defaults(let defaults):
            guard let data = defaults.data(forKey: defaultsImportedSnapshotKey) else {
                return nil
            }
            return try decodeSnapshot(from: data)
        }
    }

    func importedSnapshotFilename() -> String? {
        switch backingStore() {
        case .file(let baseURL, _):
            let url = baseURL.appendingPathComponent(importedSnapshotFileName)
            return fileManager.fileExists(atPath: url.path) ? url.lastPathComponent : nil
        case .defaults(let defaults):
            return defaults.data(forKey: defaultsImportedSnapshotKey) == nil ? nil : importedSnapshotFileName
        }
    }

    func importSnapshot(from sourceURL: URL) throws -> WorkspaceSnapshotPayload {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let data = try? Data(contentsOf: sourceURL) else {
            throw WorkspacePersistenceError.unreadableSnapshot
        }

        let payload = try decodeSnapshot(from: data)

        switch backingStore() {
        case .file(let baseURL, _):
            try ensureDirectory(baseURL)
            try data.write(to: baseURL.appendingPathComponent(importedSnapshotFileName), options: .atomic)
        case .defaults(let defaults):
            defaults.set(data, forKey: defaultsImportedSnapshotKey)
        }

        return payload
    }

    private func decodeSnapshot(from data: Data) throws -> WorkspaceSnapshotPayload {
        do {
            return try JSONCoding.decoder().decode(WorkspaceSnapshotPayload.self, from: data)
        } catch {
            throw WorkspacePersistenceError.invalidSnapshot
        }
    }

    private func ensureDirectory(_ baseURL: URL) throws {
        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    private func backingStore() -> BackingStore {
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) {
            return .file(url: containerURL.appendingPathComponent("WorkspaceSuite", isDirectory: true), mode: .appGroup)
        }

        if let defaults = UserDefaults(suiteName: Self.appGroupID) {
            return .defaults(defaults)
        }

        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return .file(url: appSupportDirectory.appendingPathComponent("WorkspaceSuiteLocal", isDirectory: true), mode: .localFallback)
    }
}
