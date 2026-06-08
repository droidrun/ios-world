import Foundation

@MainActor
final class DMsViewModel: StoreBackedViewModel {
    var dms: [DMConversation] {
        (store.activeWorkspace?.dmConversations ?? []).sorted { $0.lastMessageAt > $1.lastMessageAt }
    }

    var members: [WorkspaceMember] {
        (store.activeWorkspace?.members ?? []).filter { $0.isCurrentUser == false }
    }

    func createDM(memberIds: [String]) -> String? {
        store.createMockDM(with: memberIds)
    }

    func markRead(_ dmId: String) {
        store.markDMRead(dmId)
    }

    func markUnread(_ dmId: String) {
        store.markDMUnread(dmId)
    }

    func toggleMute(_ dmId: String) {
        store.toggleDMMute(dmId)
    }
}
