import Foundation

struct Workspace: Identifiable, Codable, Hashable {
    var id: String
    var workspaceName: String
    var sourceType: WorkspaceSourceType
    var lastUpdated: Date
    var metadata: WorkspaceSnapshotMetadata?
    var currentUserId: String
    var userProfile: UserProfile
    var members: [WorkspaceMember]
    var channels: [Channel]
    var dmConversations: [DMConversation]
    var assignedItemMessageIds: [String]
    var savedItemMessageIds: [String]
    var draftsCount: Int
    var nextMessageSequence: Int
}
