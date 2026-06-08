import Foundation

enum NavigationTarget: Hashable {
    case channel(channelId: String, focusMessageId: String?)
    case dm(dmId: String, focusMessageId: String?)
    case member(memberId: String)
}
