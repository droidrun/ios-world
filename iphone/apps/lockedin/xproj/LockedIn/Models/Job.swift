import Foundation

struct Job: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var company: String
    var companyLogoInitials: String
    var companyLogoTopHex: String
    var companyLogoBottomHex: String
    var location: String
    var locationType: JobLocationType
    var employmentType: JobEmploymentType = .fullTime
    var salaryRange: String?
    var benefits: [String]
    var postedTimeAgo: String
    var connectionsAtCompany: Int
    var isPromoted: Bool
    var isVerified: Bool
    var isActivelyRecruiting: Bool
    var isEasyApply: Bool
    var isSaved: Bool
}

struct JobNotification: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var companies: String
    var location: String?
    var timeAgo: String
}
