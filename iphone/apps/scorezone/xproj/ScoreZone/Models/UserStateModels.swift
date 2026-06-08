import Foundation

struct FavoriteTeam: Identifiable, Codable, Hashable {
    let id: String
    let teamID: String
    let addedAt: Date
}

struct RecentSearch: Identifiable, Codable, Hashable {
    let id: String
    let query: String
    let createdAt: Date
}

struct UserProfile: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let favoriteSport: String
    let homeMarket: String
}

struct AlertMessage: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let message: String
    let severity: String
    let createdAt: Date
}

struct CachedResponseMetadata: Identifiable, Codable, Hashable {
    let id: String
    let cacheKey: String
    let fetchedAt: Date
    let expiresAt: Date?
    let origin: DataOrigin
    let note: String
}

struct FetchResult<T> {
    let value: T
    let metadata: CachedResponseMetadata
    let origin: DataOrigin
    let warningMessage: String?
    let adjustedDate: Date?

    init(value: T, metadata: CachedResponseMetadata, origin: DataOrigin, warningMessage: String?, adjustedDate: Date? = nil) {
        self.value = value
        self.metadata = metadata
        self.origin = origin
        self.warningMessage = warningMessage
        self.adjustedDate = adjustedDate
    }
}
