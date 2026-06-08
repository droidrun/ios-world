import Foundation

struct TeamChatSimState: Codable {
    var appDataVersion: Int?
    var seededWorkspaces: [Workspace]
    var snapshotWorkspaces: [Workspace]
    var sourceType: WorkspaceSourceType
    var seededWorkspaceId: String
    var snapshotWorkspaceId: String
    var recentSearches: [String]
    var selectedTab: AppTab
    var lastUpdated: Date
}

struct WorkspaceSnapshotPayload: Codable {
    var metadata: WorkspaceSnapshotMetadata
    var workspaces: [Workspace]
}
