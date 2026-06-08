import Foundation

struct SnapshotWorkspaceRepository: WorkspaceRepository {
    private let loader: SnapshotLoader

    init(loader: SnapshotLoader = SnapshotLoader()) {
        self.loader = loader
    }

    func loadWorkspaces() throws -> [Workspace] {
        let payload = try loader.loadSnapshotPayload()
        return payload.workspaces.map { workspace in
            var updated = workspace
            updated.sourceType = .snapshot
            updated.metadata = payload.metadata
            return updated
        }
    }
}
