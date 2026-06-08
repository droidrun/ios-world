import Foundation

struct LockedInProfile: Identifiable, Codable, Hashable {
    var id: String
    var firstName: String
    var lastName: String
    var headline: String
    var location: String
    var about: String
    var avatarInitials: String
    var avatarTopHex: String
    var avatarBottomHex: String
    var connectionCount: Int
    var followerCount: Int
    var isOpenToWork: Bool
    var isPremium: Bool
    var experiences: [Experience]
    var educations: [Education]
    var skills: [String]
    var profileViewsThisWeek: Int

    var fullName: String { "\(firstName) \(lastName)" }
}

struct Experience: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var company: String
    var companyLogoInitials: String
    var locationType: String
    var location: String
    var startDate: String
    var endDate: String?
    var description: String
    var isCurrent: Bool
}

struct Education: Identifiable, Codable, Hashable {
    var id: String
    var school: String
    var degree: String
    var field: String
    var startYear: Int
    var endYear: Int
    var activities: String
}
