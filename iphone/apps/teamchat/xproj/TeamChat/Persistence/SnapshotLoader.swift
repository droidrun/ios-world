import Foundation

struct SnapshotLoader {
    private let fileName = "workspace_snapshot"
    private let fileExtension = "json"

    var sandboxSnapshotURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsDirectory?.appendingPathComponent("workspace_snapshot.json") ?? URL(fileURLWithPath: "")
    }

    func loadSnapshotPayload() throws -> WorkspaceSnapshotPayload {
        if let payload = try loadPayloadFromSandbox() {
            return payload
        }
        if let payload = try loadPayloadFromBundle() {
            return payload
        }
        throw SnapshotRepositoryError.snapshotNotFound
    }

    private func loadPayloadFromSandbox() throws -> WorkspaceSnapshotPayload? {
        guard sandboxSnapshotURL.path.isEmpty == false,
              FileManager.default.fileExists(atPath: sandboxSnapshotURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: sandboxSnapshotURL)
            return try JSONCoding.decoder().decode(WorkspaceSnapshotPayload.self, from: data)
        } catch {
            throw SnapshotRepositoryError.invalidSnapshot(error.localizedDescription)
        }
    }

    private func loadPayloadFromBundle() throws -> WorkspaceSnapshotPayload? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONCoding.decoder().decode(WorkspaceSnapshotPayload.self, from: data)
        } catch {
            throw SnapshotRepositoryError.invalidSnapshot(error.localizedDescription)
        }
    }
}
