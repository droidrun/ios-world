import Foundation

struct WorkspaceSnapshotMetadata: Codable, Hashable {
    var sourceLabel: String
    var sourceType: WorkspaceSourceType
    var snapshotTimestamp: Date
    var lastUpdated: Date
}
