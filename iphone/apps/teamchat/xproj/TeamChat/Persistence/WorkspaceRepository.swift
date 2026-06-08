import Foundation

protocol WorkspaceRepository {
    func loadWorkspaces() throws -> [Workspace]
}

enum SnapshotRepositoryError: LocalizedError {
    case snapshotNotFound
    case invalidSnapshot(String)

    var errorDescription: String? {
        switch self {
        case .snapshotNotFound:
            return "Snapshot data unavailable. Add workspace_snapshot.json to Resources or Documents."
        case .invalidSnapshot(let detail):
            return "Invalid snapshot file: \(detail)"
        }
    }
}
