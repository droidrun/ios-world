import UIKit
import MapKit

struct SfStyle {
    static let accent = UIColor(red: 1.00, green: 0.35, blue: 0.36, alpha: 1)
    static let accentSoft = UIColor(red: 1.00, green: 0.86, blue: 0.87, alpha: 1)
    static let background = UIColor(white: 0.98, alpha: 1)
    static let cardBackground = UIColor.white
    static let textPrimary = UIColor(white: 0.1, alpha: 1)
    static let textSecondary = UIColor(white: 0.45, alpha: 1)
    static let textTertiary = UIColor(white: 0.65, alpha: 1)
    static let divider = UIColor(white: 0.9, alpha: 1)
}

enum SfUI {
    /// iOS 15+ scene-aware replacement for the deprecated `UIApplication.shared.keyWindow`.
    static func keyRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}

struct ListingImage {
    let title: String
    let assetName: String
    let fallbackColors: [UIColor]
}

struct Host {
    let name: String
    let isSuperhost: Bool
    let isVerified: Bool
    let responseRate: String
    let avatarColor: UIColor
}

struct Review {
    let author: String
    let rating: Double
    let date: String
    let text: String
}

enum ListingKind {
    case stay
    case experience
    case service
}

struct Listing {
    let id: String
    let title: String
    let location: String
    let price: Int
    let rating: Double
    let reviewCount: Int
    let beds: Int
    let baths: Int
    let guests: Int
    let categories: [String]
    let amenities: [String]
    let images: [ListingImage]
    let host: Host
    let description: String
    let kind: ListingKind
    let duration: String
    let highlights: [String]
    let reviews: [Review]
}

struct PriceBreakdown {
    let nightlyRate: Int
    let nights: Int
    let cleaningFee: Int
    let serviceFee: Int
    let taxes: Int

    var subtotal: Int { nightlyRate * nights }
    var total: Int { subtotal + cleaningFee + serviceFee + taxes }

    static func generate(for listing: Listing, nights: Int = 1) -> PriceBreakdown {
        var rng = SeededGenerator(seed: stableSeed(listing.id + ".price"))
        let cleaningPct = Double(rng.pick([12, 14, 16, 18, 20])) / 100.0
        let servicePct = Double(rng.pick([10, 12, 14])) / 100.0
        let taxPct = Double(rng.pick([8, 9, 10, 11, 12])) / 100.0
        let subtotal = listing.price * nights
        return PriceBreakdown(
            nightlyRate: listing.price,
            nights: nights,
            cleaningFee: Int(Double(listing.price) * cleaningPct),
            serviceFee: Int(Double(subtotal) * servicePct),
            taxes: Int(Double(subtotal) * taxPct)
        )
    }
}

struct DetailSection {
    let title: String
    let lines: [String]
}

struct ListingDetailInfo {
    let sections: [DetailSection]

    static func generate(for listing: Listing) -> ListingDetailInfo {
        var rng = SeededGenerator(seed: stableSeed(listing.id))

        let checkInWindow = rng.pick(["2 PM - 8 PM", "3 PM - 9 PM", "4 PM - 10 PM"])
        let checkoutTime = rng.pick(["10 AM", "11 AM", "12 PM"])
        let cancellation = rng.pick([
            "Free cancellation for 48 hours",
            "Cancel up to 5 days before check-in",
            "Cancel up to 7 days before check-in"
        ])
        let selfCheckIn = rng.pick(["Keypad entry", "Smart lock", "Lockbox"])
        let dateWindow = rng.pick(["Oct 12 - Oct 18", "Nov 3 - Nov 8", "Dec 6 - Dec 12", "Jan 10 - Jan 16"])
        let minStay = rng.pick([1, 2, 3])
        let typicalStay = rng.pick([2, 3, 4, 5])

        let neighborhood = rng.pick([
            "Quiet residential blocks with coffee shops and parks within a 10 minute walk.",
            "Central location with quick transit access and lively restaurants nearby.",
            "Beachside community with morning walks, casual cafes, and sunset views."
        ])

        let houseRules = rng.pickMany([
            "No smoking",
            "No parties or events",
            "Quiet hours 10 PM - 7 AM",
            "No unregistered guests",
            "Pets allowed with approval",
            "Remove shoes indoors"
        ], count: 3)

        let safetyNotes = rng.pickMany([
            "Exterior security camera at entry",
            "Stairs required",
            "Smoke and CO alarm installed",
            "Parking on street"
        ], count: 2)

        let hostLanguages = rng.pickMany([
            "English",
            "Spanish",
            "French",
            "Italian",
            "Japanese"
        ], count: 2).joined(separator: ", ")

        if listing.kind == .service {
            let prepNotes = rng.pickMany([
                "Host will message to confirm timing",
                "Setup happens at your stay",
                "Great for small groups and special occasions",
                "Can be adjusted to your preferences"
            ], count: 2)

            return ListingDetailInfo(sections: [
                DetailSection(title: "Service details", lines: [
                    "Duration: \(listing.duration)",
                    "For up to \(listing.guests) guests",
                    "Delivered at your stay"
                ]),
                DetailSection(title: "What's included", lines: Array(listing.amenities.prefix(3))),
                DetailSection(title: "Before you book", lines: prepNotes),
                DetailSection(title: "Cancellation", lines: [cancellation])
            ])
        }

        if listing.kind == .experience {
            let meetingPoint = rng.pick([
                "Meet at the main square fountain",
                "Meet outside the central market entrance",
                "Meet at the marina ticket booth"
            ])
            let bringItems = rng.pickMany([
                "Comfortable shoes",
                "Water bottle",
                "Light jacket",
                "Phone for photos"
            ], count: 2)
            let experienceNotes = rng.pickMany([
                "Family friendly and beginner friendly",
                "Weather dependent and rescheduled if needed",
                "Small group with time for questions"
            ], count: 2)

            return ListingDetailInfo(sections: [
                DetailSection(title: "Meeting point", lines: [meetingPoint, "Arrive 10 minutes early"]),
                DetailSection(title: "What to bring", lines: bringItems),
                DetailSection(title: "Group details", lines: [
                    "Group size: up to \(listing.guests)",
                    "Duration: \(listing.duration)"
                ]),
                DetailSection(title: "Notes", lines: experienceNotes),
                DetailSection(title: "Cancellation", lines: [cancellation])
            ])
        }

        return ListingDetailInfo(sections: [
            DetailSection(title: "Good to know", lines: [
                "Check-in: \(checkInWindow)",
                "Checkout: \(checkoutTime)",
                "Self check-in: \(selfCheckIn)",
                "Cancellation: \(cancellation)"
            ]),
            DetailSection(title: "House rules", lines: houseRules),
            DetailSection(title: "Neighborhood", lines: [neighborhood]),
            DetailSection(title: "Availability", lines: [
                "Minimum stay: \(minStay) nights",
                "Typical stay: \(typicalStay) nights",
                "Next open: \(dateWindow)"
            ]),
            DetailSection(title: "Host info", lines: [
                "Languages: \(hostLanguages)",
                "Response rate: \(listing.host.responseRate)"
            ]),
            DetailSection(title: "Safety", lines: safetyNotes)
        ])
    }
}

enum BookingStatus {
    case upcoming
    case canceled
    case completed
}

private func stableSeed(_ value: String) -> UInt64 {
    var hash: UInt64 = 1469598103934665603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return hash
}

struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9e3779b97f4a7c15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }

    mutating func pick<T>(_ items: [T]) -> T {
        items[Int(next() % UInt64(items.count))]
    }

    mutating func pickMany<T>(_ items: [T], count: Int) -> [T] {
        var remaining = items
        var result: [T] = []
        for _ in 0..<min(count, remaining.count) {
            let index = Int(next() % UInt64(remaining.count))
            result.append(remaining.remove(at: index))
        }
        return result
    }
}

struct Booking {
    let id: String
    let listingId: String
    var startDate: Date
    var endDate: Date
    var guests: Int
    var status: BookingStatus
    let createdAt: Date
}

struct Message {
    let id: String
    let text: String
    let isHost: Bool
    let timestamp: Date
}

enum ConversationCategory {
    case traveling
    case support
}

struct Conversation {
    let id: String
    let listingId: String
    let hostName: String
    let title: String
    let tripSummary: String
    let category: ConversationCategory
    var unreadCount: Int
    var messages: [Message]

    var lastActivityDate: Date {
        return messages.last?.timestamp ?? Date()
    }
}

struct SfUserProfile {
    let firstName: String
    let fullName: String
    let location: String
    let initials: String
    let yearsOnStayFinder: Int
    let reviewCount: Int
}

struct SfNotificationItem {
    let title: String
    let subtitle: String
    let relativeDate: String
    let symbolName: String
    let isUnread: Bool
    let destination: SfDestination
}

struct SfConnection {
    let name: String
    let subtitle: String
    let detail: String
    let initials: String
    let color: UIColor
    let destination: SfDestination
}

enum SfDestination {
    case listing(String)
    case conversation(String)
    case pastTrips
}

struct SearchCriteria {
    var query: String = ""
    var minPrice: Int?
    var maxPrice: Int?
    var guests: Int = 1
    var startDate: Date?
    var endDate: Date?
    var amenities: Set<String> = []
    var category: String?
}

struct Wishlist: Codable {
    let id: String
    var name: String
    var listingIDs: [String]
}

private func shortSlashDateString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M/d/yy"
    return formatter.string(from: date)
}

private func shortMonthDayString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}

private func bookingDateRangeString(start: Date, end: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
}

private func dateByAddingDays(_ days: Int, to date: Date) -> Date {
    return Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
}

private func normalizedSearchText(_ text: String) -> String {
    return text
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        .lowercased()
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
}

private func normalizedSearchTokens(_ text: String) -> [String] {
    return normalizedSearchText(text)
        .split(separator: " ")
        .map(String.init)
}

extension Notification.Name {
    static let bnbFavoritesChanged = Notification.Name("bnbFavoritesChanged")
    static let bnbBookingsChanged = Notification.Name("bnbBookingsChanged")
    static let bnbMessagesChanged = Notification.Name("bnbMessagesChanged")
}

// MARK: - LLM Service

final class LLMService {
    static let shared = LLMService()

    private let session = URLSession.shared

    private func resolveAPIKey() -> String? {
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !plistKey.isEmpty, !plistKey.contains("$(") {
            return plistKey
        }
        var dir = Bundle.main.bundleURL.deletingLastPathComponent()
        for _ in 0..<10 {
            let envFile = dir.appendingPathComponent(".env")
            if let contents = try? String(contentsOf: envFile, encoding: .utf8) {
                for line in contents.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.hasPrefix("OPENAI_API_KEY"), let eqIdx = trimmed.firstIndex(of: "=") else { continue }
                    var val = String(trimmed[trimmed.index(after: eqIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                        val = String(val.dropFirst().dropLast())
                    }
                    if !val.isEmpty { return val }
                }
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }
        if let udKey = UserDefaults.standard.string(forKey: "openai_api_key"), !udKey.isEmpty {
            return udKey
        }
        return nil
    }

    var isAvailable: Bool { resolveAPIKey() != nil }

    func generateHostReply(
        hostName: String,
        listingTitle: String,
        listingLocation: String,
        listingKind: String,
        amenities: [String],
        conversationHistory: [(role: String, text: String)],
        guestMessage: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let apiKey = resolveAPIKey() else {
            completion(nil)
            return
        }

        let systemPrompt = """
        You are \(hostName), a StayFinder host for "\(listingTitle)" in \(listingLocation). \
        This is a \(listingKind). Amenities include: \(amenities.joined(separator: ", ")). \
        Reply as the host in 1-3 short, warm sentences. Be helpful and specific to the property. \
        Do not use emojis. Do not break character. Do not mention AI or being an assistant.
        """

        var transcript = conversationHistory.suffix(10).map { entry in
            let name = entry.role == "host" ? hostName : "Guest"
            return "\(name): \(entry.text)"
        }.joined(separator: "\n")
        if !transcript.isEmpty { transcript += "\n" }
        transcript += "Guest: \(guestMessage)"

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Here is the conversation so far:\n\(transcript)\n\nReply as \(hostName):"]
        ]

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.8,
            "max_tokens": 256
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        session.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data,
                  let raw = try? JSONSerialization.jsonObject(with: data),
                  let json = raw as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                completion(nil)
                return
            }
            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}

final class SfStore {
    static let shared = SfStore()

    let categories = ["Beachfront", "Cabins", "Trending", "Design", "City", "Guest favorite", "Countryside", "Amazing views", "Lakefront", "Tropical"]
    let profile: SfUserProfile
    let notifications: [SfNotificationItem]
    let connections: [SfConnection]

    private(set) var listings: [Listing]
    private(set) var favorites = Set<String>()
    private(set) var wishlists: [Wishlist] = []
    private(set) var bookings: [Booking] = []
    private(set) var conversations: [Conversation] = []

    private let favoritesKey = "sf_favorites"
    private let wishlistsKey = "sf_wishlists"

    private func persistFavoritesAndWishlists() {
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
        if let data = try? JSONEncoder().encode(wishlists) {
            UserDefaults.standard.set(data, forKey: wishlistsKey)
        }
    }

    private func loadPersistedFavoritesAndWishlists() {
        if let savedFavorites = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favorites = Set(savedFavorites)
        }
        if let data = UserDefaults.standard.data(forKey: wishlistsKey),
           let decoded = try? JSONDecoder().decode([Wishlist].self, from: data) {
            wishlists = decoded
        }
    }

    private init() {
        let hostLena = Host(name: "Lena", isSuperhost: true, isVerified: true, responseRate: "98%", avatarColor: UIColor(red: 0.36, green: 0.58, blue: 0.98, alpha: 1))
        let hostMika = Host(name: "Mika", isSuperhost: true, isVerified: true, responseRate: "95%", avatarColor: UIColor(red: 0.96, green: 0.62, blue: 0.30, alpha: 1))
        let hostAndre = Host(name: "Andre", isSuperhost: false, isVerified: true, responseRate: "90%", avatarColor: UIColor(red: 0.45, green: 0.78, blue: 0.52, alpha: 1))
        let hostRina = Host(name: "Rina", isSuperhost: true, isVerified: true, responseRate: "99%", avatarColor: UIColor(red: 0.88, green: 0.40, blue: 0.61, alpha: 1))
        let hostLucia = Host(name: "Lucia", isSuperhost: false, isVerified: false, responseRate: "92%", avatarColor: UIColor(red: 0.68, green: 0.56, blue: 0.98, alpha: 1))
        let hostYuna = Host(name: "Yuna", isSuperhost: true, isVerified: true, responseRate: "97%", avatarColor: UIColor(red: 0.27, green: 0.60, blue: 0.92, alpha: 1))
        let hostKenji = Host(name: "Kenji", isSuperhost: true, isVerified: true, responseRate: "96%", avatarColor: UIColor(red: 0.96, green: 0.54, blue: 0.24, alpha: 1))
        let hostMateo = Host(name: "Mateo", isSuperhost: true, isVerified: true, responseRate: "94%", avatarColor: UIColor(red: 0.35, green: 0.66, blue: 0.55, alpha: 1))
        let hostSofia = Host(name: "Sofia", isSuperhost: true, isVerified: true, responseRate: "97%", avatarColor: UIColor(red: 0.80, green: 0.44, blue: 0.88, alpha: 1))
        let hostOmar = Host(name: "Omar", isSuperhost: false, isVerified: true, responseRate: "91%", avatarColor: UIColor(red: 0.30, green: 0.72, blue: 0.68, alpha: 1))
        let hostElsa = Host(name: "Elsa", isSuperhost: true, isVerified: true, responseRate: "99%", avatarColor: UIColor(red: 0.42, green: 0.56, blue: 0.82, alpha: 1))
        let hostDiego = Host(name: "Diego", isSuperhost: false, isVerified: true, responseRate: "88%", avatarColor: UIColor(red: 0.90, green: 0.58, blue: 0.34, alpha: 1))
        let hostAmara = Host(name: "Amara", isSuperhost: true, isVerified: true, responseRate: "97%", avatarColor: UIColor(red: 0.72, green: 0.42, blue: 0.56, alpha: 1))
        let hostHiro = Host(name: "Hiro", isSuperhost: true, isVerified: true, responseRate: "99%", avatarColor: UIColor(red: 0.28, green: 0.68, blue: 0.48, alpha: 1))
        let hostNadia = Host(name: "Nadia", isSuperhost: false, isVerified: true, responseRate: "93%", avatarColor: UIColor(red: 0.56, green: 0.48, blue: 0.84, alpha: 1))
        let hostTomas = Host(name: "Tomas", isSuperhost: true, isVerified: true, responseRate: "96%", avatarColor: UIColor(red: 0.84, green: 0.64, blue: 0.28, alpha: 1))
        let hostChen = Host(name: "Chen", isSuperhost: true, isVerified: true, responseRate: "98%", avatarColor: UIColor(red: 0.25, green: 0.52, blue: 0.65, alpha: 1))
        let hostZara = Host(name: "Zara", isSuperhost: true, isVerified: true, responseRate: "97%", avatarColor: UIColor(red: 0.78, green: 0.48, blue: 0.32, alpha: 1))
        let hostLina = Host(name: "Lina", isSuperhost: false, isVerified: true, responseRate: "94%", avatarColor: UIColor(red: 0.52, green: 0.62, blue: 0.38, alpha: 1))
        let hostJade = Host(name: "Jade", isSuperhost: true, isVerified: true, responseRate: "96%", avatarColor: UIColor(red: 0.40, green: 0.72, blue: 0.58, alpha: 1))
        let hostIsla = Host(name: "Isla", isSuperhost: false, isVerified: true, responseRate: "92%", avatarColor: UIColor(red: 0.44, green: 0.58, blue: 0.82, alpha: 1))
        let hostRavi = Host(name: "Ravi", isSuperhost: true, isVerified: true, responseRate: "95%", avatarColor: UIColor(red: 0.65, green: 0.38, blue: 0.52, alpha: 1))

        profile = SfUserProfile(
            firstName: "Jordan",
            fullName: "Jordan Avery",
            location: "San Francisco, CA",
            initials: "J",
            yearsOnStayFinder: 4,
            reviewCount: 7
        )

        notifications = [
            SfNotificationItem(
                title: "Check-in details are ready",
                subtitle: "Andre shared parking, gate, and arrival notes for the Catalina cliffside retreat.",
                relativeDate: "2h ago",
                symbolName: "key.fill",
                isUnread: true,
                destination: .conversation("stay-beach")
            ),
            SfNotificationItem(
                title: "Price drop on a saved stay",
                subtitle: "Hillside suite on Catalina is now $28 less for the weekend you viewed.",
                relativeDate: "Yesterday",
                symbolName: "tag.fill",
                isUnread: false,
                destination: .listing("stay-soho-suite")
            ),
            SfNotificationItem(
                title: "New host reply",
                subtitle: "Lena confirmed early bag drop at the ridge cabin if you arrive before check-in.",
                relativeDate: "Mar 3",
                symbolName: "message.fill",
                isUnread: false,
                destination: .conversation("stay-soma")
            ),
            SfNotificationItem(
                title: "Review reminder",
                subtitle: "Add a quick review for your redwood canyon stay when you have a minute.",
                relativeDate: "Feb 21",
                symbolName: "star.fill",
                isUnread: false,
                destination: .pastTrips
            ),
            SfNotificationItem(
                title: "Chef service confirmed",
                subtitle: "Lucia finalized menu preferences for your private chef dinner in Big Sur.",
                relativeDate: "Feb 14",
                symbolName: "fork.knife",
                isUnread: false,
                destination: .listing("service-chef")
            ),
            SfNotificationItem(
                title: "Experience itinerary updated",
                subtitle: "Rina added two new tasting stops to your coastal taco tasting.",
                relativeDate: "Jan 28",
                symbolName: "map.fill",
                isUnread: false,
                destination: .listing("exp-food")
            )
        ]

        connections = [
            SfConnection(
                name: "Mina",
                subtitle: "Met during your Catalina trip",
                detail: "1 shared stay · saves calm coastal weekends",
                initials: "M",
                color: UIColor(red: 0.16, green: 0.20, blue: 0.28, alpha: 1),
                destination: .listing("stay-beach")
            ),
            SfConnection(
                name: "Theo",
                subtitle: "Hosted your cove-view stay",
                detail: "Fast responder · keeps detailed arrival guides",
                initials: "T",
                color: UIColor(red: 0.22, green: 0.34, blue: 0.52, alpha: 1),
                destination: .listing("stay-cabin")
            ),
            SfConnection(
                name: "Ari",
                subtitle: "Joined a tasting experience with you",
                detail: "2 shared experiences · knows every low-key food stop on the coast",
                initials: "A",
                color: UIColor(red: 0.44, green: 0.56, blue: 0.35, alpha: 1),
                destination: .listing("exp-food")
            ),
            SfConnection(
                name: "June",
                subtitle: "Booked a photo session after your Catalina stay",
                detail: "Shared service booking · usually plans long-weekend island trips",
                initials: "J",
                color: UIColor(red: 0.60, green: 0.42, blue: 0.30, alpha: 1),
                destination: .listing("service-photo")
            )
        ]

        func image(_ title: String, _ asset: String, _ colors: [UIColor]) -> ListingImage {
            ListingImage(title: title, assetName: asset, fallbackColors: colors)
        }

        func reviews(_ items: [(String, Double, String, String)]) -> [Review] {
            return items.map { Review(author: $0.0, rating: $0.1, date: $0.2, text: $0.3) }
        }

        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            let components = DateComponents(year: year, month: month, day: day, hour: 12)
            return Calendar.current.date(from: components) ?? Date()
        }

        // Relative date helper so upcoming trips never become past-dated.
        func futureDate(daysFromNow: Int, hour: Int = 12) -> Date {
            let base = Calendar.current.startOfDay(for: Date())
            return Calendar.current.date(byAdding: .day, value: daysFromNow, to: base)?
                .addingTimeInterval(TimeInterval(hour * 3600)) ?? Date()
        }

        // Format a trip-summary string from a pair of dates + location.
        func tripSummaryString(start: Date, end: Date, location: String) -> String {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            let yearFmt = DateFormatter()
            yearFmt.dateFormat = "yyyy"
            let startStr = fmt.string(from: start)
            let endStr = fmt.string(from: end)
            let year = yearFmt.string(from: end)
            if Calendar.current.isDate(start, inSameDayAs: end) {
                return "\(startStr), \(year) · \(location)"
            }
            return "\(startStr) - \(endStr), \(year) · \(location)"
        }

        // Upcoming trip dates (relative to today, so always "upcoming")
        let catalinaStart = futureDate(daysFromNow: 6)     // ~6 days out
        let catalinaEnd = futureDate(daysFromNow: 9)       // 3-night stay
        let photoSessionDate = futureDate(daysFromNow: 8)  // during Catalina trip
        let sunsetSailDate = futureDate(daysFromNow: 27)   // ~4 weeks out

        listings = [
            // ── STAYS (67 total) ──────────────────────────────────────
            Listing(id: "stay-beach", title: "Clifftop retreat on Catalina", location: "Catalina Island, CA", price: 327, rating: 5.0, reviewCount: 48, beds: 5, baths: 3, guests: 8,
                categories: ["Beachfront", "Trending", "Amazing views"],
                amenities: ["Pool", "Kitchen", "Parking", "Outdoor dining"],
                images: [image("Main View", "sf_stay_1", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Interior", "sf_stay_2", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Detail", "sf_stay_3", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostAndre, description: "Coastal stay with wide ocean views, a quiet deck, and enough space for an easy long-weekend group trip.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jordan", 5.0, "Sep 2025", "The deck and ocean view made the whole trip."), ("Nora", 5.0, "Aug 2025", "Felt private, calm, and very polished.")])),
            Listing(id: "stay-soma", title: "Big Sur ridge cabin", location: "Big Sur, CA", price: 153, rating: 4.91, reviewCount: 128, beds: 3, baths: 1, guests: 4,
                categories: ["Cabins", "Countryside"],
                amenities: ["Wifi", "Kitchen", "Washer", "Workspace"],
                images: [image("Living Room", "sf_stay_4", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Bedroom View", "sf_stay_5", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Morning Light", "sf_stay_6", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostLena, description: "Bright cabin stay with a high ridge outlook, soft morning light, and a calm road down to the coast.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Alex", 5.0, "Nov 2025", "Quiet, clean, and close to everything."), ("Taylor", 4.8, "Oct 2025", "Great host and perfect location.")])),
            Listing(id: "stay-cabin", title: "Cove-view guest suite", location: "Catalina Island, CA", price: 86, rating: 4.93, reviewCount: 62, beds: 1, baths: 1, guests: 2,
                categories: ["Beachfront", "Guest favorite"],
                amenities: ["Wifi", "Workspace", "Kitchen", "Self check-in"],
                images: [image("Guest Room", "sf_stay_7", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Window View", "sf_stay_8", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Outdoor Space", "sf_stay_9", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostMika, description: "Simple guest suite with a bright shoreline outlook and a short walk down to quiet coves and morning coffee.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Casey", 4.9, "Oct 2025", "Exactly what I needed for a quick coastal trip."), ("Priya", 4.8, "Sep 2025", "Clean room and smooth self check-in.")])),
            Listing(id: "stay-paris", title: "Forest hideaway near the redwoods", location: "Sequoia, CA", price: 118, rating: 4.92, reviewCount: 89, beds: 1, baths: 1, guests: 2,
                categories: ["Cabins", "Countryside"],
                amenities: ["Wifi", "Kitchen", "Washer", "Free street parking"],
                images: [image("Bedroom", "sf_stay_10", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Common Area", "sf_stay_11", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Pathway", "sf_stay_12", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostLucia, description: "Quiet forest stay with filtered morning light, cooler evenings, and a tucked-away feel near the redwoods.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Dani", 5.0, "Aug 2025", "Felt restful and easy."), ("Jasper", 4.8, "Jul 2025", "Lovely host and a very comfortable bed.")])),
            Listing(id: "stay-london", title: "Valley overlook studio", location: "Carmel Valley, CA", price: 109, rating: 5.0, reviewCount: 41, beds: 1, baths: 1, guests: 2,
                categories: ["Design", "Guest favorite", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Elevator"],
                images: [image("Modern Interior", "sf_stay_13", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)]), image("Kitchen Area", "sf_stay_14", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Scenic View", "sf_stay_15", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostRina, description: "Compact studio with a wider valley view than you expect, ideal for a quiet reset with a few vineyard stops nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Sam", 5.0, "Oct 2025", "Compact but very polished."), ("Eli", 5.0, "Sep 2025", "Perfect for a two-night trip.")])),
            Listing(id: "stay-asheville", title: "Redwood canyon room", location: "Sequoia, CA", price: 96, rating: 4.89, reviewCount: 77, beds: 1, baths: 1, guests: 2,
                categories: ["Cabins", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Washer"],
                images: [image("Living Area", "sf_stay_16", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Quiet Corner", "sf_stay_17", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)]), image("Nature View", "sf_stay_18", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostAndre, description: "Comfortable room above a wooded canyon with just enough space to settle in between hikes and slower mornings.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("June", 4.8, "Jul 2025", "Really convenient for the price."), ("Mark", 4.9, "Jun 2025", "Easy check-in and a responsive host.")])),
            Listing(id: "stay-chelsea-hotel", title: "Boutique harbor stay", location: "Avalon, CA", price: 148, rating: 4.84, reviewCount: 233, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Elevator", "Air conditioning", "Front desk"],
                images: [image("Suite View", "sf_stay_19", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)]), image("Lounge", "sf_stay_20", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Harbor Scene", "sf_stay_21", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostLucia, description: "Harbor-side suite with a polished feel, a calmer palette, and enough space for a quick weekend by the water.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Maya", 4.9, "Aug 2025", "Felt boutique without being overdone."), ("Leo", 4.8, "Jul 2025", "Great base by the harbor.")])),
            Listing(id: "stay-midtown-hotel", title: "Weekend stay above the bay", location: "Monterey Bay, CA", price: 172, rating: 4.78, reviewCount: 189, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Air conditioning", "Elevator", "Gym"],
                images: [image("Bay Outlook", "sf_stay_22", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)]), image("Room Interior", "sf_stay_23", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Common Space", "sf_stay_24", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)])],
                host: hostRina, description: "Compact stay that trades extra square footage for a dramatic overlook and a very easy weekend base.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Bea", 4.8, "Oct 2025", "Clean and exactly where we needed to be."), ("Jon", 4.7, "Sep 2025", "A little tight, but very smooth overall.")])),
            Listing(id: "stay-soho-suite", title: "Hillside suite with ocean views", location: "Catalina Island, CA", price: 192, rating: 4.86, reviewCount: 142, beds: 1, baths: 1, guests: 2,
                categories: ["Design", "Beachfront", "Amazing views"],
                amenities: ["Wifi", "Kitchenette", "Elevator", "Workspace"],
                images: [image("Ocean View", "sf_stay_25", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)]), image("Styled Room", "sf_stay_26", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Work Corner", "sf_stay_27", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)])],
                host: hostLena, description: "Styled hillside suite with a quieter finish than a typical hotel stay and broad water views by golden hour.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ana", 4.9, "Oct 2025", "Beautifully laid out."), ("Chris", 4.8, "Sep 2025", "Very comfortable for two nights.")])),
            Listing(id: "stay-seoul-hanok", title: "Bukchon hanok loft", location: "Seoul, South Korea", price: 214, rating: 4.94, reviewCount: 176, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Courtyard", "sf_stay_28", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Bedroom", "sf_stay_29", [UIColor(red:0.26,green:0.65,blue:0.78,alpha:1), UIColor(red:0.70,green:0.86,blue:0.90,alpha:1)]), image("Rooftop View", "sf_stay_30", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)])],
                host: hostYuna, description: "Warm hanok-inspired stay with wood details, a quiet side street, and easy access to Bukchon cafes and galleries.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Min", 5.0, "Nov 2025", "Felt thoughtful and beautifully maintained."), ("Sasha", 4.9, "Oct 2025", "Great neighborhood and very smooth check-in.")])),
            Listing(id: "stay-seoul-gangnam", title: "Gangnam design apartment", location: "Seoul, South Korea", price: 186, rating: 4.88, reviewCount: 143, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Washer"],
                images: [image("Open Layout", "sf_stay_31", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Light Room", "sf_stay_32", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("City View", "sf_stay_33", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostYuna, description: "Clean-lined apartment near subway access and late-night dining, with a calmer interior than the neighborhood pace outside.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jae", 4.9, "Oct 2025", "Perfect base for a busy Seoul trip."), ("Imani", 4.8, "Sep 2025", "Very easy to settle into.")])),
            Listing(id: "stay-tokyo-shibuya", title: "Shibuya studio with soaking tub", location: "Tokyo, Japan", price: 228, rating: 4.9, reviewCount: 201, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchenette", "Elevator", "Self check-in"],
                images: [image("Studio", "sf_stay_34", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Bath Area", "sf_stay_35", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Evening Scene", "sf_stay_36", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostKenji, description: "Compact studio with a deep soaking tub, smooth check-in, and enough design detail to feel intentional instead of cramped.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ari", 5.0, "Nov 2025", "Small in the best Tokyo way."), ("Nadia", 4.8, "Oct 2025", "Loved the bath and the location.")])),
            Listing(id: "stay-lisbon-alfama", title: "Alfama tile apartment", location: "Lisbon, Portugal", price: 173, rating: 4.87, reviewCount: 134, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Balcony"],
                images: [image("Tile Interior", "sf_stay_37", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Bright Room", "sf_stay_38", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Balcony View", "sf_stay_39", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostNadia, description: "Tile-lined apartment with a breezy balcony, walkable tram access, and the kind of old-city texture that makes Lisbon feel local.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Clara", 4.9, "Sep 2025", "The balcony made breakfast feel special."), ("Owen", 4.8, "Aug 2025", "Great neighborhood and clear host instructions.")])),
            // ── NEW STAYS ──
            Listing(id: "stay-tahoe", title: "Lake Tahoe A-frame", location: "Lake Tahoe, CA", price: 279, rating: 4.96, reviewCount: 98, beds: 3, baths: 2, guests: 6,
                categories: ["Cabins", "Lakefront", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Fireplace", "Parking", "Hot tub"],
                images: [image("A-Frame Front", "sf_stay_40", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Lake View", "sf_stay_41", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Fireside", "sf_stay_42", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostLena, description: "Classic A-frame cabin with a wide lake view, a hot tub for stargazing, and trails starting from the driveway.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ben", 5.0, "Dec 2025", "The hot tub view at night was incredible."), ("Sara", 4.9, "Nov 2025", "Cozy, warm, and very well-stocked kitchen.")])),
            Listing(id: "stay-joshua-tree", title: "Desert dome retreat", location: "Joshua Tree, CA", price: 197, rating: 4.97, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["Trending", "Amazing views", "Design"],
                amenities: ["Wifi", "Kitchen", "Parking", "Outdoor shower"],
                images: [image("Dome View", "sf_stay_43", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)]), image("Dome Interior", "sf_stay_44", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Desert Sky", "sf_stay_45", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostSofia, description: "Geodesic dome with a private deck, outdoor shower, and unobstructed desert sky views for stargazing.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lila", 5.0, "Oct 2025", "Waking up in the desert dome was surreal."), ("Marco", 4.9, "Sep 2025", "Every detail was intentional.")])),
            Listing(id: "stay-savannah", title: "Historic district row house", location: "Savannah, GA", price: 167, rating: 4.91, reviewCount: 112, beds: 2, baths: 2, guests: 4,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Parking", "Washer", "Porch"],
                images: [image("Front Porch", "sf_stay_46", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Living Room", "sf_stay_47", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)]), image("Garden Path", "sf_stay_48", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostOmar, description: "Restored row house in the historic district with a wrap-around porch, original hardwoods, and walking access to everything.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Grace", 4.9, "Oct 2025", "The porch was our favorite part of the trip."), ("Derek", 4.9, "Sep 2025", "Perfectly located and beautifully restored.")])),
            Listing(id: "stay-austin", title: "South Congress bungalow", location: "Austin, TX", price: 137, rating: 4.88, reviewCount: 203, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Patio", "Bikes"],
                images: [image("Bungalow Front", "sf_stay_49", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)]), image("Back Patio", "sf_stay_50", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Cozy Interior", "sf_stay_51", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostDiego, description: "Colorful bungalow off South Congress with a backyard patio, loaner bikes, and walkable access to live music and tacos.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jules", 4.9, "Nov 2025", "The bikes were a game-changer for exploring."), ("Mia", 4.8, "Oct 2025", "Great vibes and perfect location.")])),
            Listing(id: "stay-portland", title: "Alberta Arts loft", location: "Portland, OR", price: 112, rating: 4.85, reviewCount: 94, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Workspace"],
                images: [image("Loft Space", "sf_stay_52", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)]), image("Kitchen", "sf_stay_53", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Brick Detail", "sf_stay_54", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)])],
                host: hostElsa, description: "Industrial loft conversion in the Alberta Arts district with exposed brick, high ceilings, and walkable coffee shops.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Kai", 4.9, "Sep 2025", "Industrial chic done right."), ("Zoe", 4.8, "Aug 2025", "Loved the neighborhood.")])),
            Listing(id: "stay-miami", title: "Art Deco studio on the beach", location: "Miami Beach, FL", price: 198, rating: 4.82, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["Beachfront", "City", "Trending"],
                amenities: ["Wifi", "Pool", "Air conditioning", "Gym"],
                images: [image("Beach View", "sf_stay_55", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)]), image("Deco Interior", "sf_stay_56", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Poolside", "sf_stay_57", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)])],
                host: hostRina, description: "Art Deco building steps from the sand, with a rooftop pool, pastel interiors, and South Beach energy outside.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ava", 4.8, "Nov 2025", "Steps from the beach and so stylish."), ("Luis", 4.8, "Oct 2025", "The pool and location were perfect.")])),
            Listing(id: "stay-napa", title: "Vineyard cottage", location: "Napa Valley, CA", price: 247, rating: 4.95, reviewCount: 83, beds: 2, baths: 1, guests: 4,
                categories: ["Countryside", "Guest favorite", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Parking", "Patio", "Fireplace"],
                images: [image("Cottage Front", "sf_stay_58", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Vineyard View", "sf_stay_59", [UIColor(red:0.26,green:0.65,blue:0.78,alpha:1), UIColor(red:0.70,green:0.86,blue:0.90,alpha:1)]), image("Patio Dining", "sf_stay_60", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)])],
                host: hostLena, description: "Quiet cottage surrounded by vineyards with a fireplace, outdoor dining patio, and tasting rooms within a short drive.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ellen", 5.0, "Oct 2025", "Woke up to vineyard views every morning."), ("Tom", 4.9, "Sep 2025", "The patio dinners were magical.")])),
            Listing(id: "stay-santa-fe", title: "Adobe casita with courtyard", location: "Santa Fe, NM", price: 159, rating: 4.93, reviewCount: 71, beds: 1, baths: 1, guests: 2,
                categories: ["Design", "Countryside"],
                amenities: ["Wifi", "Kitchen", "Parking", "Fireplace"],
                images: [image("Courtyard", "sf_stay_61", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Adobe Interior", "sf_stay_62", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Desert Sunset", "sf_stay_63", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostAmara, description: "Handmade adobe casita with a private courtyard, kiva fireplace, and the quiet warmth Santa Fe is known for.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Rosa", 4.9, "Sep 2025", "The fireplace made every evening special."), ("Adam", 4.9, "Aug 2025", "Authentic Santa Fe experience.")])),
            Listing(id: "stay-hudson", title: "Hudson Valley farmhouse", location: "Hudson Valley, NY", price: 189, rating: 4.87, reviewCount: 105, beds: 3, baths: 2, guests: 6,
                categories: ["Countryside", "Cabins"],
                amenities: ["Wifi", "Kitchen", "Parking", "Washer", "Fireplace", "Garden"],
                images: [image("Farmhouse", "sf_stay_64", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Garden", "sf_stay_65", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Country Kitchen", "sf_stay_66", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostOmar, description: "Renovated farmhouse on a quiet road with a large kitchen, garden, and weekend farmer's market nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Vera", 4.9, "Oct 2025", "The garden was a wonderful bonus."), ("Will", 4.8, "Sep 2025", "Perfect for our weekend group trip.")])),
            Listing(id: "stay-cape-cod", title: "Shingled seaside cottage", location: "Cape Cod, MA", price: 210, rating: 4.90, reviewCount: 88, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "Countryside"],
                amenities: ["Wifi", "Kitchen", "Parking", "Beach access"],
                images: [image("Cottage Exterior", "sf_stay_67", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Seaside Deck", "sf_stay_68", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Bright Interior", "sf_stay_69", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostElsa, description: "Classic New England cottage with weathered shingles, a beach path out back, and lobster rolls down the road.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Rhys", 4.9, "Aug 2025", "Quintessential Cape Cod."), ("Amy", 4.9, "Jul 2025", "The beach access was unbeatable.")])),
            Listing(id: "stay-barcelona", title: "Gothic Quarter apartment", location: "Barcelona, Spain", price: 158, rating: 4.86, reviewCount: 178, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Balcony"],
                images: [image("Balcony View", "sf_stay_70", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Living Area", "sf_stay_71", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Street Scene", "sf_stay_72", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostMateo, description: "Sunlit apartment in the Gothic Quarter with wrought-iron balcony, stone walls, and tapas bars steps away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lena", 4.9, "Oct 2025", "The balcony overlooking the alley was dreamy."), ("Oscar", 4.8, "Sep 2025", "Perfectly central and full of character.")])),
            Listing(id: "stay-amsterdam", title: "Canal house studio", location: "Amsterdam, Netherlands", price: 178, rating: 4.89, reviewCount: 121, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchenette", "Workspace", "Bike rental"],
                images: [image("Canal View", "sf_stay_73", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)]), image("Compact Studio", "sf_stay_74", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Bridge Path", "sf_stay_75", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostElsa, description: "Narrow canal house studio with steep stairs, bike rental, and a window view of the bridges below.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Freya", 4.9, "Nov 2025", "The canal view at sunrise was perfect."), ("James", 4.8, "Oct 2025", "Compact but very well designed.")])),
            Listing(id: "stay-bali", title: "Rice terrace villa", location: "Ubud, Bali", price: 145, rating: 4.98, reviewCount: 214, beds: 2, baths: 2, guests: 4,
                categories: ["Tropical", "Amazing views", "Guest favorite"],
                amenities: ["Pool", "Kitchen", "Wifi", "Parking", "Yoga deck"],
                images: [image("Villa Pool", "sf_stay_76", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Rice Terrace", "sf_stay_77", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)]), image("Yoga Deck", "sf_stay_78", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostSofia, description: "Open-air villa overlooking rice terraces with an infinity pool, outdoor shower, and morning yoga deck.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Isla", 5.0, "Nov 2025", "Waking up to rice terraces was life-changing."), ("Raj", 5.0, "Oct 2025", "The most peaceful place I have ever stayed.")])),
            Listing(id: "stay-kyoto", title: "Machiya townhouse", location: "Kyoto, Japan", price: 198, rating: 4.95, reviewCount: 159, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Garden"],
                images: [image("Garden Entry", "sf_stay_79", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)]), image("Tatami Room", "sf_stay_80", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Temple Path", "sf_stay_81", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostKenji, description: "Restored machiya townhouse with sliding screens, a small inner garden, and temple walks nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Sophie", 5.0, "Oct 2025", "Felt like stepping back in time."), ("Yuki", 4.9, "Sep 2025", "The garden was magical at dawn.")])),
            Listing(id: "stay-marrakech", title: "Medina riad with courtyard", location: "Marrakech, Morocco", price: 132, rating: 4.91, reviewCount: 187, beds: 2, baths: 2, guests: 4,
                categories: ["Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Pool", "Rooftop terrace"],
                images: [image("Courtyard Pool", "sf_stay_82", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)]), image("Tile Work", "sf_stay_83", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Rooftop Terrace", "sf_stay_84", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)])],
                host: hostOmar, description: "Traditional riad with a plunge pool courtyard, rooftop terrace with Atlas Mountain views, and the souks steps away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Liam", 4.9, "Nov 2025", "The rooftop sunset was unforgettable."), ("Aisha", 4.9, "Oct 2025", "Incredibly atmospheric and well-maintained.")])),
            Listing(id: "stay-copenhagen", title: "Nyhavn harbor flat", location: "Copenhagen, Denmark", price: 215, rating: 4.88, reviewCount: 96, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Bike rental"],
                images: [image("Harbor View", "sf_stay_85", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)]), image("Scandi Interior", "sf_stay_86", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Morning Nook", "sf_stay_87", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)])],
                host: hostElsa, description: "Bright Scandi flat overlooking colorful Nyhavn harbor with bike rental and a canal-side morning coffee spot below.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Nils", 4.9, "Sep 2025", "The perfect Copenhagen base."), ("Emma", 4.8, "Aug 2025", "Clean, bright, and right on the harbor.")])),
            Listing(id: "stay-buenos-aires", title: "Palermo Soho townhouse", location: "Buenos Aires, Argentina", price: 95, rating: 4.93, reviewCount: 138, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Patio"],
                images: [image("Street Front", "sf_stay_88", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Tiled Patio", "sf_stay_89", [UIColor(red:0.26,green:0.65,blue:0.78,alpha:1), UIColor(red:0.70,green:0.86,blue:0.90,alpha:1)]), image("Bright Lounge", "sf_stay_90", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)])],
                host: hostDiego, description: "Colorful Palermo Soho townhouse with a tiled patio, local art on the walls, and late-night dining everywhere.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Cami", 4.9, "Oct 2025", "The neighborhood energy was amazing."), ("Felix", 4.9, "Sep 2025", "Incredible value and beautiful space.")])),
            Listing(id: "stay-dubrovnik", title: "Old Town stone apartment", location: "Dubrovnik, Croatia", price: 168, rating: 4.90, reviewCount: 108, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Air conditioning"],
                images: [image("Stone Walls", "sf_stay_91", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Terrace View", "sf_stay_92", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Adriatic Sea", "sf_stay_93", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostTomas, description: "Stone apartment inside the Old Town walls with a terrace overlooking the Adriatic and the sounds of the city below.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Hannah", 4.9, "Sep 2025", "The terrace view was worth every penny."), ("Ivan", 4.9, "Aug 2025", "Location inside the walls is unbeatable.")])),
            Listing(id: "stay-amalfi", title: "Cliffside lemon house", location: "Amalfi Coast, Italy", price: 285, rating: 4.96, reviewCount: 74, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "Amazing views", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Balcony", "Sea access"],
                images: [image("Cliff View", "sf_stay_94", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Lemon Terrace", "sf_stay_95", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Amalfi Kitchen", "sf_stay_96", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostTomas, description: "Sun-drenched house carved into the cliffside with lemon trees on the terrace and steps down to the sea.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Valentina", 5.0, "Sep 2025", "The lemon terrace at sunset was a dream."), ("George", 4.9, "Aug 2025", "Worth the steep steps for the views.")])),
            Listing(id: "stay-reykjavik", title: "Harbor loft with northern views", location: "Reykjavik, Iceland", price: 205, rating: 4.87, reviewCount: 62, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Workspace"],
                images: [image("Loft Space", "sf_stay_97", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Harbor Dock", "sf_stay_98", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Northern Sky", "sf_stay_99", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostElsa, description: "Modern harbor loft with floor-to-ceiling windows, a chance at northern lights from the living room, and whale-watching tours below.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Olaf", 4.9, "Jan 2026", "Saw the northern lights from the sofa."), ("Brit", 4.8, "Dec 2025", "Clean, warm, and beautifully positioned.")])),
            Listing(id: "stay-bangkok", title: "Riverside studio with pool", location: "Bangkok, Thailand", price: 78, rating: 4.84, reviewCount: 245, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Tropical", "Trending"],
                amenities: ["Wifi", "Pool", "Air conditioning", "Gym", "Self check-in"],
                images: [image("Pool Deck", "sf_stay_100", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("River Studio", "sf_stay_101", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Night Market View", "sf_stay_102", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostHiro, description: "Compact riverside studio with rooftop pool, night market access, and surprisingly calm for central Bangkok.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Tanya", 4.9, "Nov 2025", "The rooftop pool was incredible at night."), ("Mike", 4.8, "Oct 2025", "Best value in Bangkok by far.")])),
            Listing(id: "stay-santorini", title: "Caldera cave suite", location: "Santorini, Greece", price: 312, rating: 4.99, reviewCount: 92, beds: 1, baths: 1, guests: 2,
                categories: ["Beachfront", "Amazing views", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchenette", "Plunge pool", "Air conditioning"],
                images: [image("Caldera View", "sf_stay_103", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)]), image("Cave Interior", "sf_stay_104", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Plunge Pool", "sf_stay_105", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostNadia, description: "Whitewashed cave suite carved into the caldera with a private plunge pool overlooking the Aegean sunset.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Elena", 5.0, "Sep 2025", "The sunset from the plunge pool was unreal."), ("Theo", 5.0, "Aug 2025", "Most romantic place we have ever stayed.")])),
            // ── NEW CITIES ──────────────────────────────────────────────
            // Paris, France (3)
            Listing(id: "stay-paris-marais", title: "Le Marais loft with courtyard", location: "Paris, France", price: 245, rating: 4.94, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Workspace"],
                images: [image("Courtyard", "sf_stay_106", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Loft Interior", "sf_stay_107", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Morning Light", "sf_stay_108", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostNadia, description: "Stone-floored Marais loft with a quiet inner courtyard, tall windows, and the best of the 3rd arrondissement at your door.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Marie", 5.0, "Jan 2026", "The courtyard was the highlight."), ("David", 4.9, "Dec 2025", "Perfect Paris base.")])),
            Listing(id: "stay-paris-montmartre", title: "Montmartre artist studio", location: "Paris, France", price: 189, rating: 4.91, reviewCount: 112, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Balcony"],
                images: [image("Studio View", "sf_stay_109", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Art Corner", "sf_stay_110", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Rooftop", "sf_stay_111", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostMateo, description: "Light-filled artist studio on a quiet Montmartre side street with a small balcony looking out over the rooftops.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Sophie", 4.9, "Dec 2025", "Charming and so well-located."), ("Liam", 4.9, "Nov 2025", "Loved waking up to the rooftop view.")])),
            Listing(id: "stay-paris-st-germain", title: "Saint-Germain pied-a-terre", location: "Paris, France", price: 312, rating: 4.97, reviewCount: 88, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Washer", "Air conditioning"],
                images: [image("Living Room", "sf_stay_112", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Bedroom", "sf_stay_113", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Street View", "sf_stay_114", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostLucia, description: "Elegant apartment on a tree-lined Saint-Germain boulevard with high ceilings, herringbone floors, and bookshop neighbors.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Anna", 5.0, "Jan 2026", "Every detail was perfect."), ("James", 4.9, "Dec 2025", "Quintessential Paris stay.")])),
            // London, UK (3)
            Listing(id: "stay-london-notting", title: "Notting Hill terrace flat", location: "London, UK", price: 228, rating: 4.88, reviewCount: 134, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in"],
                images: [image("Pastel Front", "sf_stay_115", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Living Space", "sf_stay_116", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Garden", "sf_stay_117", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostElsa, description: "Bright terrace flat on a pastel-painted Notting Hill street with Portobello Market around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Kate", 4.9, "Dec 2025", "Lovely flat, great location."), ("Tom", 4.8, "Nov 2025", "Felt like a local immediately.")])),
            Listing(id: "stay-london-shoreditch", title: "Shoreditch warehouse conversion", location: "London, UK", price: 195, rating: 4.85, reviewCount: 167, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Washer"],
                images: [image("Open Plan", "sf_stay_118", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)]), image("Exposed Brick", "sf_stay_119", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Skylight", "sf_stay_120", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostOmar, description: "Converted warehouse with exposed brick, high ceilings, and a skylight that fills the space with natural light.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Rich", 4.9, "Nov 2025", "Amazing space, very photogenic."), ("Jess", 4.8, "Oct 2025", "Perfect for a creative weekend.")])),
            Listing(id: "stay-london-camden", title: "Camden market townhouse", location: "London, UK", price: 172, rating: 4.82, reviewCount: 198, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Parking"],
                images: [image("Townhouse", "sf_stay_121", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Kitchen Area", "sf_stay_122", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)]), image("Roof Terrace", "sf_stay_123", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostOmar, description: "Victorian townhouse a short walk from Camden Market with a roof terrace and eclectic local character.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Beth", 4.8, "Oct 2025", "Camden is buzzing and this is a great base."), ("Sam", 4.8, "Sep 2025", "Roof terrace was a lovely surprise.")])),
            // New York, NY (3)
            Listing(id: "stay-nyc-west-village", title: "West Village brownstone floor", location: "New York, NY", price: 289, rating: 4.92, reviewCount: 143, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Air conditioning"],
                images: [image("Brownstone", "sf_stay_124", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)]), image("Living Room", "sf_stay_125", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Garden View", "sf_stay_126", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostAmara, description: "Full floor of a classic West Village brownstone with a garden-facing bedroom and cobblestone-street charm.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Nina", 5.0, "Jan 2026", "Dream NYC apartment."), ("Carlos", 4.8, "Dec 2025", "The neighborhood is perfect.")])),
            Listing(id: "stay-nyc-williamsburg", title: "Williamsburg loft with skyline view", location: "New York, NY", price: 215, rating: 4.86, reviewCount: 178, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Workspace"],
                images: [image("Skyline", "sf_stay_127", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)]), image("Loft Interior", "sf_stay_128", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Rooftop", "sf_stay_129", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)])],
                host: hostDiego, description: "Industrial loft in Williamsburg with Manhattan skyline views, rooftop access, and the best of Brooklyn at your feet.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Zoe", 4.9, "Dec 2025", "The skyline view at sunset was magical."), ("Pat", 4.8, "Nov 2025", "Great neighborhood energy.")])),
            Listing(id: "stay-nyc-harlem", title: "Harlem brownstone garden suite", location: "New York, NY", price: 178, rating: 4.83, reviewCount: 121, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Washer"],
                images: [image("Suite", "sf_stay_130", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)]), image("Garden", "sf_stay_131", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Stoop", "sf_stay_132", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)])],
                host: hostOmar, description: "Garden-level suite in a historic Harlem brownstone with a private entrance and quiet backyard.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Devon", 4.8, "Nov 2025", "Hidden gem in Harlem."), ("Ava", 4.8, "Oct 2025", "The garden was so peaceful.")])),
            // Rome, Italy (2)
            Listing(id: "stay-rome-trastevere", title: "Trastevere terrace apartment", location: "Rome, Italy", price: 198, rating: 4.93, reviewCount: 165, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Balcony"],
                images: [image("Terrace", "sf_stay_133", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Interior", "sf_stay_134", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Street Below", "sf_stay_135", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostTomas, description: "Sun-drenched terrace apartment in the heart of Trastevere with trattorias and piazzas steps away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lisa", 5.0, "Dec 2025", "The terrace breakfast was unforgettable."), ("Marco", 4.9, "Nov 2025", "Best neighborhood in Rome.")])),
            Listing(id: "stay-rome-monti", title: "Monti neighborhood studio", location: "Rome, Italy", price: 165, rating: 4.87, reviewCount: 98, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in"],
                images: [image("Studio", "sf_stay_136", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Window Nook", "sf_stay_137", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Cobblestone View", "sf_stay_138", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostNadia, description: "Cozy studio in the Monti quarter with vintage shops and wine bars lining the narrow streets outside.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Giulia", 4.9, "Nov 2025", "Monti is the best kept secret."), ("Ben", 4.8, "Oct 2025", "Small but perfectly formed.")])),
            // Sydney, Australia (2)
            Listing(id: "stay-sydney-bondi", title: "Bondi Beach apartment", location: "Sydney, Australia", price: 235, rating: 4.90, reviewCount: 187, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Balcony"],
                images: [image("Beach View", "sf_stay_139", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Open Plan", "sf_stay_140", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Sunrise", "sf_stay_141", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostHiro, description: "Bright apartment steps from Bondi Beach with ocean views from the balcony and the coastal walk at your doorstep.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Luke", 4.9, "Jan 2026", "Waking up to the ocean was incredible."), ("Amy", 4.9, "Dec 2025", "Best Bondi location we found.")])),
            Listing(id: "stay-sydney-surry", title: "Surry Hills terrace house", location: "Sydney, Australia", price: 185, rating: 4.86, reviewCount: 124, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in"],
                images: [image("Terrace Front", "sf_stay_142", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Interior", "sf_stay_143", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Courtyard", "sf_stay_144", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostRina, description: "Restored Victorian terrace in Surry Hills with cafes, galleries, and the city center a short walk away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Mel", 4.9, "Dec 2025", "Surry Hills is vibrant and this place fit right in."), ("Dan", 4.8, "Nov 2025", "Loved the terrace courtyard.")])),
            // Mexico City, Mexico (2)
            Listing(id: "stay-cdmx-condesa", title: "Condesa art deco apartment", location: "Mexico City, Mexico", price: 118, rating: 4.91, reviewCount: 201, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Balcony"],
                images: [image("Art Deco", "sf_stay_145", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)]), image("Living Area", "sf_stay_146", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Park View", "sf_stay_147", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostDiego, description: "Art deco apartment on a leafy Condesa boulevard with Parque Mexico around the corner and tacos al pastor a block away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Rosa", 4.9, "Jan 2026", "Condesa is magical and this apartment matched."), ("Jake", 4.9, "Dec 2025", "Incredible value for the location.")])),
            Listing(id: "stay-cdmx-roma", title: "Roma Norte courtyard studio", location: "Mexico City, Mexico", price: 95, rating: 4.89, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Courtyard", "sf_stay_148", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Studio Interior", "sf_stay_149", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)]), image("Street Scene", "sf_stay_150", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostAmara, description: "Tiled courtyard studio in Roma Norte with coffee shops, bookstores, and mezcal bars within walking distance.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Diego", 4.9, "Dec 2025", "Roma Norte is the perfect base."), ("Mia", 4.9, "Nov 2025", "Cozy, clean, and beautifully designed.")])),
            // ── ADDITIONS TO EXISTING CITIES ────────────────────────────
            // Seoul +1
            Listing(id: "stay-seoul-itaewon", title: "Itaewon rooftop apartment", location: "Seoul, South Korea", price: 168, rating: 4.86, reviewCount: 132, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Rooftop access"],
                images: [image("Rooftop", "sf_stay_151", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)]), image("Apartment", "sf_stay_152", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Night View", "sf_stay_153", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostYuna, description: "Modern apartment in Itaewon with rooftop access, city views, and the international dining scene at street level.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jin", 4.9, "Dec 2025", "The rooftop views were stunning."), ("Alex", 4.8, "Nov 2025", "Great area for nightlife and food.")])),
            // Tokyo +2
            Listing(id: "stay-tokyo-asakusa", title: "Asakusa temple-side flat", location: "Tokyo, Japan", price: 175, rating: 4.92, reviewCount: 189, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Washer"],
                images: [image("Temple View", "sf_stay_154", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)]), image("Tatami Room", "sf_stay_155", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Lantern Street", "sf_stay_156", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)])],
                host: hostKenji, description: "Traditional-meets-modern flat near Senso-ji with tatami accents, quiet mornings, and lively Nakamise-dori around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Yuki", 5.0, "Jan 2026", "Walking to the temple at dawn was unforgettable."), ("Ryan", 4.8, "Dec 2025", "Great host, immaculate space.")])),
            Listing(id: "stay-tokyo-shimokita", title: "Shimokitazawa vintage loft", location: "Tokyo, Japan", price: 142, rating: 4.88, reviewCount: 145, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Self check-in"],
                images: [image("Vintage Loft", "sf_stay_157", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)]), image("Record Corner", "sf_stay_158", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Street View", "sf_stay_159", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)])],
                host: hostHiro, description: "Eclectic loft in Shimokitazawa surrounded by vintage shops, indie theaters, and some of Tokyo's best coffee.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Kira", 4.9, "Dec 2025", "Shimokita is the coolest neighborhood."), ("Nate", 4.8, "Nov 2025", "Felt like a local from day one.")])),
            // Lisbon +1
            Listing(id: "stay-lisbon-belem", title: "Belem riverside studio", location: "Lisbon, Portugal", price: 148, rating: 4.85, reviewCount: 109, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Balcony", "Parking"],
                images: [image("River View", "sf_stay_160", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Studio", "sf_stay_161", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Pastel de Nata", "sf_stay_162", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostMateo, description: "Bright riverside studio near the Tower of Belem with a balcony overlooking the Tagus and pasteis de nata around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Hugo", 4.9, "Nov 2025", "The river view from the balcony was gorgeous."), ("Ella", 4.8, "Oct 2025", "Quiet area, easy tram access.")])),
            // Big Sur +1
            Listing(id: "stay-bigsur-treehouse", title: "Coastal treehouse cabin", location: "Big Sur, CA", price: 215, rating: 4.94, reviewCount: 76, beds: 1, baths: 1, guests: 2,
                categories: ["Cabins", "Amazing views", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Outdoor shower"],
                images: [image("Treehouse", "sf_stay_163", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Canopy View", "sf_stay_164", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Sunset Deck", "sf_stay_165", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostLena, description: "Elevated cabin tucked into the redwood canopy with a sunset deck and the sound of the Pacific below.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Drew", 5.0, "Dec 2025", "Sleeping in the trees was magical."), ("Ivy", 4.9, "Nov 2025", "The outdoor shower under the redwoods!")])),
            // Lake Tahoe +1
            Listing(id: "stay-tahoe-ski", title: "Ski-in lodge suite", location: "Lake Tahoe, CA", price: 310, rating: 4.93, reviewCount: 87, beds: 3, baths: 2, guests: 6,
                categories: ["Cabins", "Lakefront"],
                amenities: ["Wifi", "Kitchen", "Fireplace", "Parking", "Ski storage"],
                images: [image("Lodge Front", "sf_stay_166", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Fireside", "sf_stay_167", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Mountain View", "sf_stay_168", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostAndre, description: "Slope-side lodge suite with ski-in access, a stone fireplace, and views across the lake from the main room.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Chris", 5.0, "Feb 2026", "Ski right to the door. Can't beat it."), ("Katie", 4.9, "Jan 2026", "Cozy fireside evenings after skiing.")])),
            // Barcelona +1
            Listing(id: "stay-barcelona-gracia", title: "Gracia neighborhood flat", location: "Barcelona, Spain", price: 138, rating: 4.84, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Balcony"],
                images: [image("Flat Interior", "sf_stay_169", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Balcony", "sf_stay_170", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Plaza View", "sf_stay_171", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostDiego, description: "Cheerful flat in the Gracia quarter with a balcony overlooking a neighborhood plaza, far from the tourist crowds.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Pau", 4.8, "Nov 2025", "Gracia is the real Barcelona."), ("Lily", 4.8, "Oct 2025", "Loved the local vibe.")])),
            // Amsterdam +1
            Listing(id: "stay-amsterdam-jordaan", title: "Jordaan canal houseboat", location: "Amsterdam, Netherlands", price: 205, rating: 4.92, reviewCount: 134, beds: 1, baths: 1, guests: 2,
                categories: ["Design", "City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Workspace"],
                images: [image("Houseboat", "sf_stay_172", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)]), image("Cabin Interior", "sf_stay_173", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Canal View", "sf_stay_174", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostElsa, description: "Charming houseboat on a Jordaan canal with a compact but beautifully designed interior and ducks for neighbors.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Pia", 5.0, "Dec 2025", "Sleeping on the canal was dreamy."), ("Max", 4.8, "Nov 2025", "Unique Amsterdam experience.")])),
            // Bali +1
            Listing(id: "stay-bali-canggu", title: "Canggu surf villa", location: "Canggu, Bali", price: 175, rating: 4.95, reviewCount: 198, beds: 2, baths: 2, guests: 4,
                categories: ["Tropical", "Beachfront", "Trending"],
                amenities: ["Wifi", "Kitchen", "Pool", "Parking", "Outdoor shower"],
                images: [image("Villa Pool", "sf_stay_175", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Open Air", "sf_stay_176", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)]), image("Surf Break", "sf_stay_177", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostSofia, description: "Open-air surf villa in Canggu with a private pool, board storage, and the beach break a two-minute walk away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Surya", 5.0, "Jan 2026", "Best surf-and-stay setup in Bali."), ("Jade", 4.9, "Dec 2025", "The pool was our favorite spot.")])),
            // Kyoto +1
            Listing(id: "stay-kyoto-arashiyama", title: "Arashiyama bamboo retreat", location: "Kyoto, Japan", price: 245, rating: 4.96, reviewCount: 112, beds: 2, baths: 1, guests: 4,
                categories: ["Countryside", "Amazing views", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Self check-in"],
                images: [image("Bamboo Path", "sf_stay_178", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)]), image("Garden Room", "sf_stay_179", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Tea Space", "sf_stay_180", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostKenji, description: "Serene retreat at the edge of the bamboo grove with a private garden, tea room, and the sound of wind through bamboo.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Hana", 5.0, "Dec 2025", "The bamboo grove at dawn was transcendent."), ("Will", 4.9, "Nov 2025", "Most peaceful place I have ever stayed.")])),
            // Buenos Aires +1
            Listing(id: "stay-ba-san-telmo", title: "San Telmo tango loft", location: "Buenos Aires, Argentina", price: 82, rating: 4.90, reviewCount: 143, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Balcony"],
                images: [image("Loft", "sf_stay_181", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)]), image("Brick Walls", "sf_stay_182", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Market View", "sf_stay_183", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)])],
                host: hostDiego, description: "Exposed-brick loft above San Telmo's Sunday antique market with tango bars and parrillas lining the street.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lucia", 4.9, "Nov 2025", "San Telmo on Sunday is pure magic."), ("Adam", 4.9, "Oct 2025", "Great value and incredible neighborhood.")])),
            // Amalfi Coast +1
            Listing(id: "stay-amalfi-ravello", title: "Ravello hilltop garden suite", location: "Amalfi Coast, Italy", price: 265, rating: 4.97, reviewCount: 78, beds: 1, baths: 1, guests: 2,
                categories: ["Amazing views", "Countryside", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Air conditioning"],
                images: [image("Garden", "sf_stay_184", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)]), image("Suite Interior", "sf_stay_185", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Coast View", "sf_stay_186", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)])],
                host: hostTomas, description: "Garden suite perched above Ravello with lemon trees, sea breezes, and the Amalfi coastline stretching below.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Chiara", 5.0, "Oct 2025", "The garden view took my breath away."), ("Rob", 4.9, "Sep 2025", "Most beautiful place we have stayed in Italy.")])),
            // Bangkok +1
            Listing(id: "stay-bangkok-sukhumvit", title: "Sukhumvit sky loft", location: "Bangkok, Thailand", price: 105, rating: 4.82, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Tropical"],
                amenities: ["Wifi", "Kitchen", "Pool", "Elevator", "Gym"],
                images: [image("Sky View", "sf_stay_187", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Loft Interior", "sf_stay_188", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Pool Deck", "sf_stay_189", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostHiro, description: "High-floor loft in Sukhumvit with infinity pool, BTS access, and Bangkok's street food scene below.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Noi", 4.8, "Dec 2025", "Pool views were amazing."), ("Chris", 4.8, "Nov 2025", "Right next to BTS, super convenient.")])),
            // Savannah +1
            Listing(id: "stay-savannah-forsyth", title: "Forsyth Park Victorian", location: "Savannah, GA", price: 195, rating: 4.93, reviewCount: 98, beds: 2, baths: 2, guests: 4,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Washer", "Parking", "Porch"],
                images: [image("Victorian Front", "sf_stay_190", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Parlor Room", "sf_stay_191", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Park View", "sf_stay_192", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostAmara, description: "Restored Victorian overlooking Forsyth Park with period details, a wraparound porch, and Spanish moss outside.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Grace", 5.0, "Dec 2025", "Waking up to Forsyth Park was lovely."), ("James", 4.9, "Nov 2025", "Beautifully restored with modern comforts.")])),
            // Austin +1
            Listing(id: "stay-austin-east", title: "East Austin container home", location: "Austin, TX", price: 155, rating: 4.87, reviewCount: 134, beds: 1, baths: 1, guests: 2,
                categories: ["Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Outdoor space"],
                images: [image("Container Home", "sf_stay_193", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Interior", "sf_stay_194", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Patio", "sf_stay_195", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostSofia, description: "Converted shipping container in East Austin with clever design, a shaded patio, and tacos within walking distance.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Trev", 4.9, "Nov 2025", "So cool and surprisingly spacious."), ("Bri", 4.8, "Oct 2025", "East Austin is the place to be.")])),
            // Miami +1
            Listing(id: "stay-miami-wynwood", title: "Wynwood arts district studio", location: "Miami Beach, FL", price: 165, rating: 4.84, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Pool", "Air conditioning"],
                images: [image("Mural View", "sf_stay_196", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Studio Interior", "sf_stay_197", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Rooftop Pool", "sf_stay_198", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostRina, description: "Art-forward studio surrounded by Wynwood murals with a rooftop pool and the best galleries steps away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Art", 4.8, "Dec 2025", "Wynwood is incredible and this was the perfect base."), ("Jules", 4.8, "Nov 2025", "Loved the rooftop pool.")])),
            // ── BELI CROSS-REF STAYS ──────────────────────────────────
            // Hong Kong (Beli: The Chairman in Central)
            Listing(id: "stay-hk-central", title: "Central harbor-view apartment", location: "Hong Kong", price: 248, rating: 4.91, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Amazing views", "Design"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Air conditioning", "Gym"],
                images: [image("Harbor View", "sf_stay_199", [UIColor(red:0.20,green:0.31,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)]), image("Modern Interior", "sf_stay_200", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Night Skyline", "sf_stay_201", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostChen, description: "High-floor apartment in Central with Victoria Harbour views, MTR access below, and dim sum halls within walking distance.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ling", 5.0, "Jan 2026", "The harbour view at night was stunning."), ("Rachel", 4.8, "Dec 2025", "Perfect base for eating through Hong Kong.")])),
            // Singapore (Beli: Hawker Chan in Chinatown)
            Listing(id: "stay-sg-chinatown", title: "Chinatown heritage shophouse", location: "Singapore", price: 195, rating: 4.89, reviewCount: 132, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in"],
                images: [image("Shophouse Front", "sf_stay_202", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Interior", "sf_stay_203", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Street Scene", "sf_stay_204", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostJade, description: "Restored Peranakan shophouse in Chinatown with original tile work, hawker centres nearby, and MRT access around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Wei", 4.9, "Dec 2025", "Beautiful restoration, incredible food nearby."), ("Sarah", 4.9, "Nov 2025", "Hawker Chan was a five-minute walk.")])),
            // Lima (Beli: Maido in Miraflores)
            Listing(id: "stay-lima-miraflores", title: "Miraflores oceanfront studio", location: "Lima, Peru", price: 112, rating: 4.92, reviewCount: 178, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Beachfront", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Gym", "Balcony"],
                images: [image("Pacific View", "sf_stay_265", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)]), image("Studio Interior", "sf_stay_266", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Malecón Walk", "sf_stay_267", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)])],
                host: hostDiego, description: "Modern studio overlooking the Pacific along the Malecón with Miraflores parks, cevicherías, and Maido-caliber dining nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Carlos", 4.9, "Jan 2026", "The ocean sunset from the balcony was unforgettable."), ("Mei", 4.9, "Dec 2025", "Great access to Lima's food scene.")])),
            // Los Angeles (Beli: Holbox, Bestia in DTLA/South Central)
            Listing(id: "stay-la-silverlake", title: "Silver Lake hillside bungalow", location: "Los Angeles, CA", price: 178, rating: 4.87, reviewCount: 145, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Patio"],
                images: [image("Hillside View", "sf_stay_208", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Bungalow Interior", "sf_stay_209", [UIColor(red:0.26,green:0.65,blue:0.78,alpha:1), UIColor(red:0.70,green:0.86,blue:0.90,alpha:1)]), image("Reservoir Path", "sf_stay_210", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)])],
                host: hostSofia, description: "Mid-century bungalow on a quiet Silver Lake hillside with reservoir walks, Sunset Junction cafes, and quick freeway access to Bestia and the Arts District.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Tara", 4.9, "Dec 2025", "Silver Lake is the perfect LA neighborhood."), ("Miles", 4.8, "Nov 2025", "Great patio and really well designed.")])),
            Listing(id: "stay-la-dtla", title: "Arts District warehouse loft", location: "Los Angeles, CA", price: 215, rating: 4.85, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Parking", "Workspace"],
                images: [image("Loft Space", "sf_stay_211", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Exposed Beam", "sf_stay_212", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Street Art", "sf_stay_213", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostOmar, description: "Converted warehouse loft in the Arts District with concrete floors, gallery neighbors, and Bestia around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jess", 4.9, "Nov 2025", "The loft felt like a gallery."), ("Dan", 4.8, "Oct 2025", "Walking to Bestia for dinner was a highlight.")])),
            // Busan (Beli: Haemok Haeundae - highest Beli score 10.0)
            Listing(id: "stay-busan-haeundae", title: "Haeundae beachfront suite", location: "Busan, South Korea", price: 165, rating: 4.93, reviewCount: 134, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Air conditioning", "Pool"],
                images: [image("Beach View", "sf_stay_268", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)]), image("Suite Interior", "sf_stay_269", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Night Market", "sf_stay_270", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)])],
                host: hostYuna, description: "Beachfront suite with Haeundae views, fresh seafood markets below, and KTX access to Seoul in under three hours.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Soo", 5.0, "Jan 2026", "Haeundae beach at sunrise was stunning."), ("Kate", 4.9, "Dec 2025", "The seafood nearby was world-class.")])),
            // SF stays (cross-ref Beli's 24 SF restaurants — Mission, Hayes Valley, Chinatown neighborhoods)
            Listing(id: "stay-sf-mission", title: "Mission District Victorian flat", location: "San Francisco, CA", price: 198, rating: 4.91, reviewCount: 143, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in"],
                images: [image("Victorian Front", "sf_stay_217", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Bright Kitchen", "sf_stay_218", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Street Scene", "sf_stay_219", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostLena, description: "Bright Victorian flat in the heart of the Mission with La Taqueria, Tartine, and Flour + Water all within walking distance.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Alex", 4.9, "Jan 2026", "The food scene outside the door is unreal."), ("Rosa", 4.9, "Dec 2025", "Felt like a local from day one.")])),
            Listing(id: "stay-sf-hayes", title: "Hayes Valley garden apartment", location: "San Francisco, CA", price: 225, rating: 4.94, reviewCount: 98, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Garden access"],
                images: [image("Garden Gate", "sf_stay_220", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Living Room", "sf_stay_221", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Hayes Street", "sf_stay_222", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)])],
                host: hostAmara, description: "Garden-level apartment on a quiet Hayes Valley block with Rich Table, Souvla, and Zuni Cafe all nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Chloe", 5.0, "Dec 2025", "Hayes Valley is perfect and this apartment matched."), ("Evan", 4.9, "Nov 2025", "The garden was a lovely bonus.")])),
            Listing(id: "stay-sf-nob-hill", title: "Nob Hill classic apartment", location: "San Francisco, CA", price: 185, rating: 4.88, reviewCount: 112, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Workspace"],
                images: [image("City View", "sf_stay_223", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)]), image("Classic Interior", "sf_stay_224", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Cable Car", "sf_stay_225", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostRina, description: "Classic apartment on Nob Hill with bay views, cable car access, and Swan Oyster Depot just down the hill.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Tom", 4.9, "Nov 2025", "The bay view and cable car were magical."), ("Nina", 4.8, "Oct 2025", "Walking to Swan Oyster Depot was a highlight.")])),
            // ── EXPERIENCES (14 total) ──────────────────────────────────
            Listing(id: "exp-pastry", title: "Chef-led tasting workshop", location: "Carmel-by-the-Sea, CA", price: 94, rating: 4.99, reviewCount: 216, beds: 0, baths: 0, guests: 10,
                categories: ["Trending"],
                amenities: ["Ingredients", "Guided"],
                images: [image("Baking Lab", "sf_exp_1", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Chef Demo", "sf_exp_2", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)]), image("Plating", "sf_exp_3", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)])],
                host: hostLucia, description: "Hands-on tasting workshop with a local chef in a bright studio kitchen near the coast.", kind: .experience, duration: "2 hours",
                highlights: ["Meet your chef", "Prep and taste", "Plate two courses", "Take recipes home"],
                reviews: reviews([("Ella", 5.0, "Sep 2025", "Fun, delicious, and easy to follow."), ("Grant", 5.0, "Aug 2025", "Best workshop of the trip.")])),
            Listing(id: "exp-sail", title: "Sunset Sail on the Bay", location: "Barcelona, ES", price: 78, rating: 4.93, reviewCount: 184, beds: 0, baths: 0, guests: 8,
                categories: ["Trending"],
                amenities: ["Snacks", "Guide"],
                images: [image("Golden Hour", "sf_exp_4", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("City Harbor", "sf_exp_5", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)]), image("Sailing", "sf_exp_6", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)])],
                host: hostMika, description: "Sail the bay with snacks, music, and a sunset view of the skyline.", kind: .experience, duration: "2.5 hours",
                highlights: ["Meet at marina", "Sail with crew", "Sunset photos", "Local snacks"],
                reviews: reviews([("Tara", 4.9, "Oct 2025", "Great vibes and a gorgeous sunset."), ("Noah", 5.0, "Sep 2025", "Loved the route and the crew.")])),
            Listing(id: "exp-seoul-market", title: "Seoul night market tasting", location: "Seoul, South Korea", price: 62, rating: 4.97, reviewCount: 258, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "City"],
                amenities: ["Tastings", "Guide", "Small group"],
                images: [image("Market Stops", "sf_exp_7", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)]), image("Street Food", "sf_exp_8", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)]), image("Night Stalls", "sf_exp_9", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)])],
                host: hostYuna, description: "Taste skewers, dumplings, and late-night neighborhood favorites with a local guide who keeps the route moving.", kind: .experience, duration: "3 hours",
                highlights: ["Meet in Jongno", "Try 6 food stops", "Neighborhood history", "Small group pace"],
                reviews: reviews([("Evan", 5.0, "Oct 2025", "Best way to start a Seoul trip."), ("Hana", 4.9, "Sep 2025", "Great food and zero tourist-trap vibes.")])),
            Listing(id: "exp-tokyo-coffee", title: "Tokyo coffee and kissaten crawl", location: "Tokyo, Japan", price: 58, rating: 4.92, reviewCount: 144, beds: 0, baths: 0, guests: 6,
                categories: ["City", "Design"],
                amenities: ["Coffee tastings", "Guide", "Small group"],
                images: [image("Cafe Stops", "sf_exp_10", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Bar Seating", "sf_exp_11", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)]), image("Pour Over", "sf_exp_12", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)])],
                host: hostKenji, description: "Move between modern coffee bars and classic kissaten spots, with tastings and neighborhood context at each stop.", kind: .experience, duration: "2 hours",
                highlights: ["Meet in Shibuya", "Three tasting stops", "Coffee history", "Small group route"],
                reviews: reviews([("Mira", 4.9, "Oct 2025", "Well paced and surprisingly deep."), ("Paul", 4.9, "Sep 2025", "A very Tokyo experience in the best sense.")])),
            Listing(id: "exp-food", title: "Coastal taco tasting", location: "San Diego, CA", price: 68, rating: 4.95, reviewCount: 312, beds: 0, baths: 0, guests: 12,
                categories: ["Trending"],
                amenities: ["Tastings", "Guide"],
                images: [image("Taco Stand", "sf_exp_13", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Chef Picks", "sf_exp_14", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)]), image("Harbor Walk", "sf_exp_15", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)])],
                host: hostRina, description: "Taste standout taco spots with a local guide, quick walks between stops, and a small group pace.", kind: .experience, duration: "3 hours",
                highlights: ["Meet near the harbor", "Sample 5 stops", "Walk between neighborhoods", "Local tips"],
                reviews: reviews([("Milo", 5.0, "Oct 2025", "So many flavors and great stories."), ("Erin", 4.8, "Sep 2025", "Worth every minute.")])),
            Listing(id: "exp-barcelona-tapas", title: "Barcelona tapas crawl", location: "Barcelona, Spain", price: 72, rating: 4.94, reviewCount: 198, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "City"],
                amenities: ["Tastings", "Guide", "Small group"],
                images: [image("Tapas Bar", "sf_exp_16", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Market Walk", "sf_exp_17", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)]), image("Wine Pour", "sf_exp_18", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)])],
                host: hostDiego, description: "Taste your way through four hidden tapas bars in El Born and Raval with a local guide and regional wine pairings.", kind: .experience, duration: "3 hours",
                highlights: ["Meet in El Born", "Four tapas stops", "Wine pairing at each", "Market walk"],
                reviews: reviews([("Claire", 5.0, "Oct 2025", "The hidden bars were incredible."), ("Mateo", 4.9, "Sep 2025", "Best food experience in Barcelona.")])),
            Listing(id: "exp-bali-terrace", title: "Bali rice terrace walk", location: "Ubud, Bali", price: 45, rating: 4.96, reviewCount: 176, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "Tropical"],
                amenities: ["Guide", "Snacks", "Small group"],
                images: [image("Terrace Path", "sf_exp_19", [UIColor(red:0.26,green:0.65,blue:0.78,alpha:1), UIColor(red:0.70,green:0.86,blue:0.90,alpha:1)]), image("Sunrise Trek", "sf_exp_20", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)]), image("Farmer Visit", "sf_exp_21", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)])],
                host: hostSofia, description: "Early morning walk through ancient rice terraces with a local farmer, coconut refreshments, and volcano views.", kind: .experience, duration: "2.5 hours",
                highlights: ["Sunrise start", "Terrace walk", "Meet local farmers", "Coconut refreshments"],
                reviews: reviews([("Bri", 5.0, "Nov 2025", "The sunrise was absolutely magical."), ("Ravi", 4.9, "Oct 2025", "Learned so much about Balinese farming.")])),
            Listing(id: "exp-kyoto-temple", title: "Kyoto temple morning", location: "Kyoto, Japan", price: 55, rating: 4.93, reviewCount: 132, beds: 0, baths: 0, guests: 6,
                categories: ["City", "Design"],
                amenities: ["Guide", "Tea ceremony", "Small group"],
                images: [image("Temple Gate", "sf_exp_22", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Zen Garden", "sf_exp_23", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)]), image("Tea Ceremony", "sf_exp_24", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)])],
                host: hostKenji, description: "Visit three lesser-known temples before the crowds arrive, ending with a traditional tea ceremony in a moss garden.", kind: .experience, duration: "3 hours",
                highlights: ["Early temple access", "Three temples", "Tea ceremony", "Moss garden"],
                reviews: reviews([("Aya", 5.0, "Oct 2025", "The tea ceremony was so peaceful."), ("Soren", 4.9, "Sep 2025", "Seeing temples without crowds was special.")])),
            // ── BELI CROSS-REF EXPERIENCES ─────────────────────────────
            // SF Mission food crawl (Beli: La Taqueria 9.5, El Farolito 9.0, Tartine 9.1, Flour+Water 9.3)
            Listing(id: "exp-sf-mission", title: "Mission District food crawl", location: "San Francisco, CA", price: 82, rating: 4.96, reviewCount: 187, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "City"],
                amenities: ["Tastings", "Guide", "Small group"],
                images: [image("Taco Stop", "sf_exp_25", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)]), image("Bakery Visit", "sf_exp_26", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Street Mural", "sf_exp_27", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostAmara, description: "Walk the Mission's best bites from no-rice burritos to morning buns, with stops at the spots locals actually line up for.", kind: .experience, duration: "3 hours",
                highlights: ["Five food stops", "Burrito tasting", "Bakery visit", "Mural walk between stops"],
                reviews: reviews([("Jamie", 5.0, "Jan 2026", "The burrito stop alone was worth it."), ("Rosa", 4.9, "Dec 2025", "Best food tour I have ever done.")])),
            // SF Chinatown dim sum walk (Beli: Z & Y 9.0, Mister Jiu's 9.6)
            Listing(id: "exp-sf-chinatown", title: "Chinatown dim sum morning", location: "San Francisco, CA", price: 68, rating: 4.94, reviewCount: 156, beds: 0, baths: 0, guests: 6,
                categories: ["City"],
                amenities: ["Tastings", "Guide", "Small group"],
                images: [image("Dim Sum", "sf_exp_28", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Tea Service", "sf_exp_29", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)]), image("Lantern Alley", "sf_exp_30", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostChen, description: "Early morning dim sum tasting through SF's Chinatown with har gow, siu mai, and egg tarts at three generations-old spots.", kind: .experience, duration: "2 hours",
                highlights: ["Three dim sum stops", "Tea pairing", "Market walk", "Neighborhood history"],
                reviews: reviews([("Ming", 5.0, "Dec 2025", "The best way to experience Chinatown."), ("Julia", 4.9, "Nov 2025", "Learned so much about the neighborhood.")])),
            // Mexico City food tour (Beli: Pujol 9.9, Contramar 9.7, Quintonil 9.6)
            Listing(id: "exp-cdmx-food", title: "Mexico City taco and mezcal tour", location: "Mexico City, Mexico", price: 75, rating: 4.97, reviewCount: 234, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "City"],
                amenities: ["Tastings", "Guide", "Mezcal flight"],
                images: [image("Taco Stand", "sf_exp_31", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)]), image("Market Scene", "sf_exp_32", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Mezcal Bar", "sf_exp_33", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostDiego, description: "Eat through Roma Norte and Condesa with a local guide — from street tacos al pastor to a seated mezcal tasting at a hidden bar.", kind: .experience, duration: "3.5 hours",
                highlights: ["Four taco stops", "Market walk", "Mezcal tasting", "Neighborhood history"],
                reviews: reviews([("Carlos", 5.0, "Jan 2026", "The mezcal bar was a revelation."), ("Bri", 5.0, "Dec 2025", "Best food experience in CDMX.")])),
            // Paris morning market walk (Beli: Le Comptoir du Pantheon, Septime)
            Listing(id: "exp-paris-market", title: "Paris morning market breakfast", location: "Paris, France", price: 88, rating: 4.93, reviewCount: 142, beds: 0, baths: 0, guests: 6,
                categories: ["City", "Trending"],
                amenities: ["Tastings", "Guide", "Small group"],
                images: [image("Market Stall", "sf_exp_34", [UIColor(red:0.12,green:0.55,blue:0.47,alpha:1), UIColor(red:0.31,green:0.70,blue:0.59,alpha:1)]), image("Croissant Stop", "sf_exp_35", [UIColor(red:0.16,green:0.51,blue:0.43,alpha:1), UIColor(red:0.35,green:0.66,blue:0.55,alpha:1)]), image("Cheese Counter", "sf_exp_36", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)])],
                host: hostNadia, description: "Start with croissants at a neighborhood boulangerie, then walk a morning market with cheese, charcuterie, and wine tastings.", kind: .experience, duration: "2.5 hours",
                highlights: ["Boulangerie start", "Market walk", "Cheese tasting", "Wine pairing"],
                reviews: reviews([("Sophie", 5.0, "Jan 2026", "The croissants were life-changing."), ("Oliver", 4.9, "Dec 2025", "Perfect way to start a Paris morning.")])),
            // Hong Kong dim sum morning (Beli: The Chairman 9.8)
            Listing(id: "exp-hk-dimsum", title: "Hong Kong dim sum breakfast route", location: "Hong Kong", price: 72, rating: 4.95, reviewCount: 168, beds: 0, baths: 0, guests: 6,
                categories: ["City", "Trending"],
                amenities: ["Tastings", "Guide", "Small group"],
                images: [image("Bamboo Steamers", "sf_exp_37", [UIColor(red:0.24,green:0.31,blue:0.55,alpha:1), UIColor(red:0.39,green:0.51,blue:0.74,alpha:1)]), image("Tea House", "sf_exp_38", [UIColor(red:0.66,green:0.35,blue:0.20,alpha:1), UIColor(red:0.82,green:0.59,blue:0.35,alpha:1)]), image("Central Market", "sf_exp_39", [UIColor(red:0.20,green:0.59,blue:0.51,alpha:1), UIColor(red:0.39,green:0.74,blue:0.63,alpha:1)])],
                host: hostChen, description: "Taste cart-style dim sum at a legendary tea house, then walk through Central's wet market and end with egg waffles.", kind: .experience, duration: "2.5 hours",
                highlights: ["Classic tea house", "Dim sum tasting", "Wet market walk", "Egg waffle stop"],
                reviews: reviews([("Ling", 5.0, "Dec 2025", "The tea house was an unforgettable experience."), ("Ben", 4.9, "Nov 2025", "Best dim sum of my life.")])),
            // Lima ceviche walk (Beli: Maido 9.7)
            Listing(id: "exp-lima-ceviche", title: "Lima ceviche tasting walk", location: "Lima, Peru", price: 65, rating: 4.96, reviewCount: 143, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "City"],
                amenities: ["Tastings", "Guide", "Small group"],
                images: [image("Ceviche Plate", "sf_exp_40", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Market Scene", "sf_exp_41", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Pisco Bar", "sf_exp_42", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostDiego, description: "Walk Miraflores with a local chef, tasting ceviche at three neighborhood spots and ending with a pisco sour lesson.", kind: .experience, duration: "3 hours",
                highlights: ["Three ceviche stops", "Market visit", "Pisco sour lesson", "Chef-led"],
                reviews: reviews([("Camila", 5.0, "Jan 2026", "The ceviche was the freshest I have ever had."), ("Theo", 4.9, "Dec 2025", "Lima's food scene is world-class.")])),
            // ── SERVICES (9 total) ──────────────────────────────────
            Listing(id: "service-chef", title: "Private chef dinner setup", location: "Big Sur, CA", price: 145, rating: 4.97, reviewCount: 54, beds: 0, baths: 0, guests: 6,
                categories: ["Trending"],
                amenities: ["Chef", "Ingredients", "Setup"],
                images: [image("Private Chef", "sf_svc_1", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)]), image("Dinner Service", "sf_svc_2", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)])],
                host: hostLucia, description: "Book a chef to plan the menu, cook in your stay, and handle service for a relaxed dinner night in.", kind: .service, duration: "3 hours",
                highlights: ["Menu planning", "Prep at your stay", "Dinner service", "Kitchen cleanup"],
                reviews: reviews([("Nina", 5.0, "Oct 2025", "Felt effortless and very premium."), ("Drew", 4.9, "Sep 2025", "Great dinner and zero cleanup.")])),
            Listing(id: "service-photo", title: "Vacation photo session", location: "Catalina Island, CA", price: 120, rating: 4.94, reviewCount: 87, beds: 0, baths: 0, guests: 4,
                categories: ["Trending"],
                amenities: ["Photographer", "Edited photos", "Local route"],
                images: [image("Photo Walk", "sf_svc_3", [UIColor(red:0.85,green:0.80,blue:0.90,alpha:1), UIColor(red:0.64,green:0.54,blue:0.78,alpha:1)]), image("Golden Hour", "sf_svc_4", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)])],
                host: hostMika, description: "Guided photo session with a local photographer, lightly directed poses, and edited photos after the trip.", kind: .service, duration: "90 minutes",
                highlights: ["Choose a route", "Guided poses", "Edited gallery", "Delivered after the trip"],
                reviews: reviews([("Tori", 5.0, "Sep 2025", "The photos felt natural and expensive."), ("Max", 4.8, "Aug 2025", "Easygoing and very worth it.")])),
            Listing(id: "service-seoul-photo", title: "Seoul evening photo route", location: "Seoul, South Korea", price: 138, rating: 4.95, reviewCount: 72, beds: 0, baths: 0, guests: 4,
                categories: ["City", "Trending"],
                amenities: ["Photographer", "Edited gallery", "Route planning"],
                images: [image("Evening Portraits", "sf_svc_5", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Night Cityscape", "sf_svc_6", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)])],
                host: hostYuna, description: "Book a photographer for an evening route through calmer Seoul side streets, with an edited gallery delivered after.", kind: .service, duration: "90 minutes",
                highlights: ["Route planning", "Golden-hour timing", "Edited gallery", "Delivered after the trip"],
                reviews: reviews([("Lio", 5.0, "Oct 2025", "Relaxed direction and excellent edits."), ("Rae", 4.9, "Sep 2025", "Felt easy even though we never do photos.")])),
            Listing(id: "service-lisbon-chef", title: "Portuguese dinner at your stay", location: "Lisbon, Portugal", price: 158, rating: 4.96, reviewCount: 46, beds: 0, baths: 0, guests: 6,
                categories: ["Trending", "Design"],
                amenities: ["Chef", "Ingredients", "Setup", "Cleanup"],
                images: [image("Dinner Setup", "sf_svc_7", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)]), image("Wine Tasting", "sf_svc_8", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)])],
                host: hostMateo, description: "Have a local chef cook a relaxed multi-course Portuguese dinner in your StayFinder, with setup and cleanup included.", kind: .service, duration: "3 hours",
                highlights: ["Menu planning", "Local ingredients", "In-home service", "Cleanup included"],
                reviews: reviews([("Tess", 5.0, "Oct 2025", "One of our favorite nights in Lisbon."), ("Julian", 4.9, "Sep 2025", "Felt polished but still personal.")])),
            Listing(id: "service-massage", title: "In-home massage reset", location: "Monterey Bay, CA", price: 110, rating: 4.96, reviewCount: 39, beds: 0, baths: 0, guests: 2,
                categories: ["Trending"],
                amenities: ["Massage table", "Therapist", "Travel included"],
                images: [image("Reset Session", "sf_svc_9", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Calm Space", "sf_svc_10", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostRina, description: "A licensed therapist comes to your stay with a table and a calmer pace than most hotel spa appointments.", kind: .service, duration: "75 minutes",
                highlights: ["Therapist comes to you", "Table setup", "Custom pressure", "No travel after"],
                reviews: reviews([("Elle", 5.0, "Oct 2025", "Exactly what we wanted after a long flight."), ("Rob", 4.9, "Sep 2025", "Easy booking and very professional.")])),
            // ── BELI CROSS-REF SERVICES ──────────────────────────────
            // SF sommelier tasting (Beli: Mister Jiu's, Rich Table, Che Fico wine programs)
            Listing(id: "service-sf-wine", title: "Private sommelier tasting", location: "San Francisco, CA", price: 135, rating: 4.95, reviewCount: 67, beds: 0, baths: 0, guests: 6,
                categories: ["Trending", "City"],
                amenities: ["Sommelier", "Wine selection", "Tasting notes"],
                images: [image("Wine Selection", "sf_svc_13", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Tasting Setup", "sf_svc_14", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)])],
                host: hostLucia, description: "A certified sommelier brings a curated wine flight to your stay, with tasting notes and pairing suggestions for the SF dining scene.", kind: .service, duration: "90 minutes",
                highlights: ["Curated flight", "Tasting notes", "Pairing tips", "Local winery focus"],
                reviews: reviews([("Nina", 5.0, "Jan 2026", "Perfect way to start a dinner out."), ("Mark", 4.9, "Dec 2025", "Learned so much about California wines.")])),
            // Mexico City private chef (Beli: Pujol 9.9, Quintonil 9.6 inspired)
            Listing(id: "service-cdmx-chef", title: "Private Mexican chef dinner", location: "Mexico City, Mexico", price: 165, rating: 4.97, reviewCount: 48, beds: 0, baths: 0, guests: 6,
                categories: ["Trending"],
                amenities: ["Chef", "Ingredients", "Setup", "Cleanup"],
                images: [image("Chef Prep", "sf_svc_15", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Dinner Table", "sf_svc_16", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)])],
                host: hostDiego, description: "A local chef cooks a multi-course dinner at your stay — mole, handmade tortillas, and seasonal plates inspired by the city's top restaurants.", kind: .service, duration: "3 hours",
                highlights: ["Multi-course dinner", "Handmade tortillas", "Mole preparation", "Full cleanup"],
                reviews: reviews([("Eva", 5.0, "Dec 2025", "The mole was restaurant-quality."), ("Carlos", 4.9, "Nov 2025", "Felt like a private Pujol dinner.")])),
            // Tokyo ramen reservation concierge (Beli: Tsuta 9.2, Narisawa 9.8)
            Listing(id: "service-tokyo-concierge", title: "Tokyo dining concierge", location: "Tokyo, Japan", price: 95, rating: 4.94, reviewCount: 82, beds: 0, baths: 0, guests: 2,
                categories: ["City"],
                amenities: ["Concierge", "Reservations", "Dining guide"],
                images: [image("Restaurant Scene", "sf_svc_17", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)]), image("Counter Seating", "sf_svc_18", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)])],
                host: hostKenji, description: "A local dining concierge handles hard-to-get reservations at Tokyo's best counters, ramen bars, and omakase spots.", kind: .service, duration: "Ongoing",
                highlights: ["Reservation booking", "Personalized picks", "Counter seat access", "Neighborhood guide"],
                reviews: reviews([("Ari", 5.0, "Jan 2026", "Got into places I could not have booked myself."), ("Sasha", 4.9, "Dec 2025", "Worth every penny for the omakase alone.")])),
            Listing(id: "service-yoga", title: "Private yoga session", location: "Ubud, Bali", price: 65, rating: 4.93, reviewCount: 58, beds: 0, baths: 0, guests: 4,
                categories: ["Trending", "Tropical"],
                amenities: ["Yoga mats", "Instructor", "Meditation"],
                images: [image("Yoga Deck", "sf_svc_11", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Meditation", "sf_svc_12", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)])],
                host: hostSofia, description: "Private yoga and guided meditation session on an open-air deck overlooking the jungle canopy.", kind: .service, duration: "90 minutes",
                highlights: ["Private session", "Open-air deck", "Guided meditation", "Beginner-friendly"],
                reviews: reviews([("Luna", 5.0, "Nov 2025", "The jungle sounds during meditation were incredible."), ("Jake", 4.9, "Oct 2025", "Best yoga experience of our trip.")])),
            // ── NEW CITIES & EXPANDED LISTINGS ───────────────────────────
            // San Francisco, CA (3)
            Listing(id: "stay-sf-mission", title: "Mission District sunny flat", location: "San Francisco, CA", price: 189, rating: 4.91, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Workspace", "Self check-in"],
                images: [image("Flat Interior", "sf_stay_241", [UIColor(red:0.92,green:0.84,blue:0.72,alpha:1), UIColor(red:0.78,green:0.56,blue:0.43,alpha:1)]), image("Mural View", "sf_stay_242", [UIColor(red:0.86,green:0.48,blue:0.30,alpha:1), UIColor(red:0.96,green:0.62,blue:0.40,alpha:1)]), image("Morning Light", "sf_stay_243", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)])],
                host: hostRina, description: "Bright flat on a sunny Mission block with murals outside, a local bakery below, and Dolores Park two blocks away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Arjun", 4.9, "Jan 2026", "Best block in the Mission. Coffee and tacos within steps."), ("Mia", 4.9, "Dec 2025", "Sunny even on foggy SF days.")])),
            Listing(id: "stay-sf-marina", title: "Marina harbor-view apartment", location: "San Francisco, CA", price: 245, rating: 4.88, reviewCount: 167, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Parking", "Washer", "Balcony"],
                images: [image("Harbor View", "sf_stay_244", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)]), image("Living Room", "sf_stay_245", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Golden Gate", "sf_stay_246", [UIColor(red:0.86,green:0.36,blue:0.30,alpha:1), UIColor(red:0.98,green:0.52,blue:0.42,alpha:1)])],
                host: hostLena, description: "Spacious Marina apartment with a balcony overlooking the harbor, Golden Gate views, and a morning jog path along the waterfront.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Kate", 4.9, "Feb 2026", "Golden Gate sunsets from the balcony every evening."), ("Derek", 4.8, "Jan 2026", "Perfect for a family weekend in the city.")])),
            Listing(id: "stay-sf-hayes", title: "Hayes Valley designer studio", location: "San Francisco, CA", price: 168, rating: 4.93, reviewCount: 112, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Self check-in"],
                images: [image("Studio", "sf_stay_205", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Kitchen Detail", "sf_stay_206", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Street View", "sf_stay_207", [UIColor(red:0.20,green:0.27,blue:0.51,alpha:1), UIColor(red:0.35,green:0.47,blue:0.70,alpha:1)])],
                host: hostElsa, description: "Compact designer studio in Hayes Valley with boutique shopping, Blue Bottle coffee, and the symphony all walkable.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Olive", 5.0, "Jan 2026", "The tasteful design made the small space feel perfect."), ("Nate", 4.9, "Dec 2025", "Hayes Valley is underrated. Loved every minute.")])),
            // Los Angeles, CA (3)
            Listing(id: "stay-la-silver-lake", title: "Silver Lake hillside studio", location: "Los Angeles, CA", price: 155, rating: 4.87, reviewCount: 189, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Patio"],
                images: [image("Hillside View", "sf_stay_208", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Mid-Century Interior", "sf_stay_209", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Reservoir Path", "sf_stay_210", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.20,green:0.59,blue:0.51,alpha:1)])],
                host: hostDiego, description: "Mid-century studio perched on a Silver Lake hillside with reservoir walking paths and indie coffee shops nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Bri", 4.9, "Jan 2026", "The reservoir walks were the highlight."), ("Joss", 4.8, "Dec 2025", "Perfect intro to the eastside LA vibe.")])),
            Listing(id: "stay-la-venice", title: "Venice Beach bungalow", location: "Los Angeles, CA", price: 225, rating: 4.90, reviewCount: 201, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Bikes", "Outdoor shower"],
                images: [image("Bungalow Front", "sf_stay_211", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Beach View", "sf_stay_212", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)]), image("Patio", "sf_stay_213", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)])],
                host: hostSofia, description: "Laid-back Venice bungalow two blocks from the boardwalk with cruiser bikes, an outdoor shower, and Abbot Kinney around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Leo", 4.9, "Feb 2026", "Bikes made Venice so much fun to explore."), ("Quinn", 4.9, "Jan 2026", "Best beach base in LA.")])),
            Listing(id: "stay-la-dtla", title: "Arts District warehouse loft", location: "Los Angeles, CA", price: 195, rating: 4.85, reviewCount: 145, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Workspace", "Gym"],
                images: [image("Loft Space", "sf_stay_214", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Brick Detail", "sf_stay_215", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)]), image("Rooftop", "sf_stay_216", [UIColor(red:0.35,green:0.35,blue:0.39,alpha:1), UIColor(red:0.59,green:0.59,blue:0.63,alpha:1)])],
                host: hostAmara, description: "Converted warehouse loft in the DTLA Arts District with exposed concrete, gallery neighbors, and rooftop city views.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Tara", 4.9, "Jan 2026", "The Arts District is so walkable from here."), ("Miles", 4.8, "Dec 2025", "Industrial chic done really well.")])),
            // New Orleans, LA (3)
            Listing(id: "stay-nola-garden", title: "Garden District shotgun house", location: "New Orleans, LA", price: 142, rating: 4.94, reviewCount: 178, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Washer", "Porch", "Parking"],
                images: [image("Shotgun House", "sf_stay_652", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)]), image("Parlor Room", "sf_stay_653", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Porch View", "sf_stay_654", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)])],
                host: hostIsla, description: "Classic shotgun house on an oak-lined Garden District street with a rocking-chair porch and the streetcar one block over.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ray", 5.0, "Jan 2026", "The porch, the oaks, the streetcar. Perfect."), ("June", 4.9, "Dec 2025", "Felt like a movie set in the best way.")])),
            Listing(id: "stay-nola-quarter", title: "French Quarter courtyard suite", location: "New Orleans, LA", price: 198, rating: 4.89, reviewCount: 213, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Balcony"],
                images: [image("Courtyard", "sf_stay_220", [UIColor(red:0.26,green:0.65,blue:0.78,alpha:1), UIColor(red:0.70,green:0.86,blue:0.90,alpha:1)]), image("Iron Balcony", "sf_stay_221", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)]), image("Quarter Street", "sf_stay_222", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)])],
                host: hostRavi, description: "Hidden courtyard suite behind a wrought-iron gate in the French Quarter with a balcony over the quieter end of Royal Street.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jasmine", 4.9, "Feb 2026", "The courtyard was an oasis from Bourbon Street."), ("Kurt", 4.9, "Jan 2026", "Royal Street balcony breakfasts are a must.")])),
            Listing(id: "stay-nola-bywater", title: "Bywater artist cottage", location: "New Orleans, LA", price: 119, rating: 4.92, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Bikes", "Patio"],
                images: [image("Cottage Front", "sf_stay_223", [UIColor(red:0.92,green:0.54,blue:0.38,alpha:1), UIColor(red:0.98,green:0.72,blue:0.52,alpha:1)]), image("Colorful Interior", "sf_stay_224", [UIColor(red:0.42,green:0.56,blue:0.82,alpha:1), UIColor(red:0.64,green:0.78,blue:0.94,alpha:1)]), image("Bike Path", "sf_stay_225", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.55,green:0.86,blue:0.65,alpha:1)])],
                host: hostIsla, description: "Colorful Bywater cottage with a shaded patio, loaner bikes for the Crescent Park path, and live music spots nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Carmen", 4.9, "Dec 2025", "Bywater has the best energy in the city."), ("Pete", 4.9, "Nov 2025", "Biking the levee path was a daily highlight.")])),
            // Charleston, SC (2)
            Listing(id: "stay-charleston-battery", title: "Battery row house with garden", location: "Charleston, SC", price: 235, rating: 4.95, reviewCount: 98, beds: 2, baths: 2, guests: 4,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Parking", "Washer", "Garden", "Porch"],
                images: [image("Row House", "sf_stay_226", [UIColor(red:0.82,green:0.76,blue:0.72,alpha:1), UIColor(red:0.70,green:0.63,blue:0.59,alpha:1)]), image("Piazza", "sf_stay_227", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)]), image("Harbor Walk", "sf_stay_228", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostAmara, description: "Historic row house on the Battery with a private side garden, piazza dining, and harbor walks at sunset.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Evelyn", 5.0, "Jan 2026", "The garden dinner was the highlight of our trip."), ("Thomas", 4.9, "Dec 2025", "Most charming house on the Battery.")])),
            Listing(id: "stay-charleston-king", title: "King Street carriage house", location: "Charleston, SC", price: 178, rating: 4.91, reviewCount: 134, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Courtyard"],
                images: [image("Carriage House", "sf_stay_229", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Courtyard", "sf_stay_230", [UIColor(red:0.93,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Shopping Street", "sf_stay_231", [UIColor(red:0.20,green:0.31,blue:0.20,alpha:1), UIColor(red:0.43,green:0.55,blue:0.35,alpha:1)])],
                host: hostRavi, description: "Converted carriage house behind a main residence on upper King Street, with a shared courtyard and walkable boutiques.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Claire", 4.9, "Dec 2025", "King Street shopping right outside."), ("Ian", 4.9, "Nov 2025", "The courtyard was so peaceful.")])),
            // Berlin, Germany (3)
            Listing(id: "stay-berlin-mitte", title: "Mitte gallery loft", location: "Berlin, Germany", price: 145, rating: 4.89, reviewCount: 187, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Elevator", "Washer"],
                images: [image("Gallery Loft", "sf_stay_232", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Open Plan", "sf_stay_233", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Museum Island", "sf_stay_234", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)])],
                host: hostLina, description: "White-walled loft above a Mitte gallery with Museum Island a short walk and late-night kebab runs around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Kai", 4.9, "Jan 2026", "Right in the heart of Berlin's cultural scene."), ("Freya", 4.9, "Dec 2025", "Minimal, bright, and perfectly located.")])),
            Listing(id: "stay-berlin-kreuzberg", title: "Kreuzberg canal apartment", location: "Berlin, Germany", price: 118, rating: 4.86, reviewCount: 223, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Balcony", "Bikes"],
                images: [image("Canal View", "sf_stay_235", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.20,green:0.59,blue:0.51,alpha:1)]), image("Apartment", "sf_stay_236", [UIColor(red:0.74,green:0.66,blue:0.61,alpha:1), UIColor(red:0.86,green:0.80,blue:0.76,alpha:1)]), image("Market Scene", "sf_stay_237", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostLina, description: "Canal-side apartment in Kreuzberg with a sunny balcony, loaner bikes, and the Turkish Market on Tuesdays and Fridays.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Max", 4.9, "Feb 2026", "Kreuzberg has the best food scene in Berlin."), ("Lotte", 4.8, "Jan 2026", "Canal walks every morning were lovely.")])),
            Listing(id: "stay-berlin-neukolln", title: "Neukolln rooftop flat", location: "Berlin, Germany", price: 105, rating: 4.83, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Rooftop access"],
                images: [image("Rooftop", "sf_stay_238", [UIColor(red:0.86,green:0.48,blue:0.30,alpha:1), UIColor(red:0.96,green:0.62,blue:0.40,alpha:1)]), image("Compact Flat", "sf_stay_239", [UIColor(red:0.31,green:0.31,blue:0.35,alpha:1), UIColor(red:0.55,green:0.55,blue:0.59,alpha:1)]), image("Street Life", "sf_stay_240", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)])],
                host: hostOmar, description: "Budget-friendly flat in up-and-coming Neukolln with rooftop sunset views and some of Berlin's best bars downstairs.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Sam", 4.8, "Dec 2025", "Rooftop views and great nightlife nearby."), ("Anya", 4.8, "Nov 2025", "Great neighborhood energy.")])),
            // Tulum, Mexico (2)
            Listing(id: "stay-tulum-beach", title: "Beachfront palapa suite", location: "Tulum, Mexico", price: 275, rating: 4.96, reviewCount: 134, beds: 1, baths: 1, guests: 2,
                categories: ["Beachfront", "Tropical", "Design", "Guest favorite"],
                amenities: ["Wifi", "Plunge pool", "Air conditioning", "Outdoor shower", "Beach access"],
                images: [image("Palapa Suite", "sf_stay_247", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Plunge Pool", "sf_stay_248", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)]), image("Caribbean Sea", "sf_stay_249", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.20,green:0.59,blue:0.51,alpha:1)])],
                host: hostDiego, description: "Thatched-roof suite on the Tulum beach road with a private plunge pool, Caribbean turquoise out front, and cenotes nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ingrid", 5.0, "Feb 2026", "The turquoise water from the plunge pool was unreal."), ("Marco", 4.9, "Jan 2026", "Most beautiful beach stay we have had.")])),
            Listing(id: "stay-tulum-jungle", title: "Jungle treehouse retreat", location: "Tulum, Mexico", price: 195, rating: 4.93, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["Tropical", "Trending", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Pool", "Outdoor shower", "Bikes"],
                images: [image("Treehouse", "sf_stay_250", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)]), image("Jungle Canopy", "sf_stay_251", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Cenote Path", "sf_stay_252", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)])],
                host: hostAmara, description: "Elevated treehouse surrounded by jungle with a shared pool, bikes to the beach, and cenotes hidden in the trees.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jade", 4.9, "Jan 2026", "Waking up in the jungle canopy was magical."), ("Oscar", 4.9, "Dec 2025", "The cenote bike ride was a highlight.")])),
            // Cape Town, South Africa (2)
            Listing(id: "stay-capetown-bo-kaap", title: "Bo-Kaap colorful townhouse", location: "Cape Town, South Africa", price: 115, rating: 4.91, reviewCount: 189, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Parking", "Patio"],
                images: [image("Colorful Street", "sf_stay_253", [UIColor(red:0.92,green:0.54,blue:0.38,alpha:1), UIColor(red:0.98,green:0.72,blue:0.52,alpha:1)]), image("Interior", "sf_stay_254", [UIColor(red:0.42,green:0.56,blue:0.82,alpha:1), UIColor(red:0.64,green:0.78,blue:0.94,alpha:1)]), image("Table Mountain", "sf_stay_255", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)])],
                host: hostZara, description: "Bright townhouse on one of Bo-Kaap's iconic colorful streets with Table Mountain views from the rooftop and the spice quarter around you.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Thandi", 4.9, "Jan 2026", "The colors and the mountain views were incredible."), ("Jules", 4.9, "Dec 2025", "Best neighborhood in Cape Town.")])),
            Listing(id: "stay-capetown-camps", title: "Camps Bay ocean villa", location: "Cape Town, South Africa", price: 285, rating: 4.95, reviewCount: 87, beds: 3, baths: 2, guests: 6,
                categories: ["Beachfront", "Amazing views", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Pool", "Parking", "Balcony"],
                images: [image("Ocean View", "sf_stay_256", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)]), image("Infinity Pool", "sf_stay_257", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Sunset Deck", "sf_stay_258", [UIColor(red:0.86,green:0.48,blue:0.30,alpha:1), UIColor(red:0.96,green:0.62,blue:0.40,alpha:1)])],
                host: hostZara, description: "Hillside villa overlooking Camps Bay with an infinity pool, sundowner deck, and the Twelve Apostles mountain range behind.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Rory", 5.0, "Feb 2026", "The infinity pool with ocean views was breathtaking."), ("Amira", 4.9, "Jan 2026", "Best sunset spot in all of Cape Town.")])),
            // Chiang Mai, Thailand (2)
            Listing(id: "stay-chiangmai-old", title: "Old City teak house", location: "Chiang Mai, Thailand", price: 65, rating: 4.93, reviewCount: 267, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Parking", "Garden", "Bikes"],
                images: [image("Teak House", "sf_stay_259", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)]), image("Garden", "sf_stay_260", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Temple View", "sf_stay_261", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)])],
                host: hostJade, description: "Traditional teak house inside the Old City moat with a lush garden, temple neighbors, and the Sunday walking street market.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Noi", 5.0, "Jan 2026", "The teak wood and garden felt so peaceful."), ("Sam", 4.9, "Dec 2025", "Best value stay in Southeast Asia.")])),
            Listing(id: "stay-chiangmai-nimman", title: "Nimman design studio", location: "Chiang Mai, Thailand", price: 55, rating: 4.87, reviewCount: 312, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Pool", "Gym", "Self check-in"],
                images: [image("Design Studio", "sf_stay_262", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)]), image("Pool Deck", "sf_stay_263", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.20,green:0.59,blue:0.51,alpha:1)]), image("Coffee Street", "sf_stay_264", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)])],
                host: hostJade, description: "Sleek studio in Nimman with a rooftop pool, co-working cafe vibes downstairs, and the best specialty coffee in northern Thailand.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Alex", 4.9, "Feb 2026", "Digital nomad paradise. Pool and coffee all day."), ("Pim", 4.8, "Jan 2026", "Nimman has everything you need.")])),
            // Edinburgh, Scotland (2)
            Listing(id: "stay-edinburgh-old", title: "Old Town tenement flat", location: "Edinburgh, Scotland", price: 155, rating: 4.91, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in"],
                images: [image("Tenement View", "sf_stay_271", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Flat Interior", "sf_stay_272", [UIColor(red:0.88,green:0.81,blue:0.79,alpha:1), UIColor(red:0.70,green:0.56,blue:0.54,alpha:1)]), image("Castle View", "sf_stay_273", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostIsla, description: "Stone tenement flat on a Royal Mile close with castle views from the kitchen window and whisky bars at street level.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Fiona", 4.9, "Jan 2026", "Castle views while making tea. Perfection."), ("Ben", 4.9, "Dec 2025", "The close was atmospheric and so central.")])),
            Listing(id: "stay-edinburgh-stockbridge", title: "Stockbridge garden flat", location: "Edinburgh, Scotland", price: 138, rating: 4.88, reviewCount: 134, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Countryside"],
                amenities: ["Wifi", "Kitchen", "Washer", "Garden"],
                images: [image("Garden Flat", "sf_stay_274", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Living Room", "sf_stay_275", [UIColor(red:0.70,green:0.63,blue:0.59,alpha:1), UIColor(red:0.82,green:0.76,blue:0.72,alpha:1)]), image("Village Walk", "sf_stay_276", [UIColor(red:0.42,green:0.56,blue:0.82,alpha:1), UIColor(red:0.64,green:0.78,blue:0.94,alpha:1)])],
                host: hostIsla, description: "Charming garden flat in village-like Stockbridge with a Sunday farmers market, the Water of Leith path, and the Botanics nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Moira", 4.9, "Dec 2025", "Stockbridge is Edinburgh's hidden gem."), ("Jack", 4.8, "Nov 2025", "The garden was lovely even in autumn.")])),
            // Maui, HI (2)
            Listing(id: "stay-maui-paia", title: "Paia surf cottage", location: "Maui, HI", price: 215, rating: 4.94, reviewCount: 156, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "Tropical", "Trending"],
                amenities: ["Wifi", "Kitchen", "Parking", "Outdoor shower", "Beach gear"],
                images: [image("Surf Cottage", "sf_stay_277", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Lanai", "sf_stay_278", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.20,green:0.59,blue:0.51,alpha:1)]), image("North Shore", "sf_stay_279", [UIColor(red:0.86,green:0.48,blue:0.30,alpha:1), UIColor(red:0.96,green:0.62,blue:0.40,alpha:1)])],
                host: hostRavi, description: "Laid-back surf cottage in Paia town with board storage, an outdoor shower, and the North Shore breaks a short paddle out.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Kai", 5.0, "Feb 2026", "Best surf-and-stay setup on Maui."), ("Luna", 4.9, "Jan 2026", "Paia town is pure magic.")])),
            Listing(id: "stay-maui-wailea", title: "Wailea ocean suite", location: "Maui, HI", price: 345, rating: 4.97, reviewCount: 89, beds: 2, baths: 2, guests: 4,
                categories: ["Beachfront", "Amazing views", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Pool", "Air conditioning", "Beach access", "Balcony"],
                images: [image("Ocean Suite", "sf_stay_280", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)]), image("Pool Deck", "sf_stay_281", [UIColor(red:0.16,green:0.47,blue:0.70,alpha:1), UIColor(red:0.39,green:0.74,blue:0.82,alpha:1)]), image("Sunset", "sf_stay_282", [UIColor(red:0.86,green:0.36,blue:0.30,alpha:1), UIColor(red:0.98,green:0.52,blue:0.42,alpha:1)])],
                host: hostSofia, description: "Luxury ocean suite in Wailea with an infinity pool, direct beach access, and whale-watching from the balcony in winter.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Elena", 5.0, "Jan 2026", "Watched whales breach from our balcony."), ("Grant", 4.9, "Dec 2025", "The most beautiful stay of our lives.")])),
            // Nashville, TN (2)
            Listing(id: "stay-nashville-gulch", title: "The Gulch modern loft", location: "Nashville, TN", price: 175, rating: 4.88, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Gym", "Elevator", "Workspace"],
                images: [image("Modern Loft", "sf_stay_283", [UIColor(red:0.74,green:0.43,blue:0.27,alpha:1), UIColor(red:0.90,green:0.67,blue:0.43,alpha:1)]), image("City View", "sf_stay_284", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Broadway Lights", "sf_stay_285", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)])],
                host: hostRavi, description: "Sleek loft in The Gulch with floor-to-ceiling windows, walkable distance to Broadway honky-tonks and the best hot chicken.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Dani", 4.9, "Jan 2026", "Could hear live music drifting up from Broadway."), ("Tess", 4.8, "Dec 2025", "Walkable to everything that matters in Nashville.")])),
            Listing(id: "stay-nashville-east", title: "East Nashville cottage", location: "Nashville, TN", price: 135, rating: 4.91, reviewCount: 167, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Parking", "Patio", "Washer"],
                images: [image("Cottage Front", "sf_stay_286", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Back Patio", "sf_stay_287", [UIColor(red:0.92,green:0.84,blue:0.72,alpha:1), UIColor(red:0.80,green:0.56,blue:0.43,alpha:1)]), image("Five Points", "sf_stay_288", [UIColor(red:0.66,green:0.59,blue:0.63,alpha:1), UIColor(red:0.78,green:0.72,blue:0.76,alpha:1)])],
                host: hostAmara, description: "Cheerful cottage near Five Points with a backyard patio, local dive bars, and the best brunch spots in East Nashville.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Cody", 4.9, "Dec 2025", "East Nashville is where the locals hang out."), ("Beth", 4.9, "Nov 2025", "The patio was perfect for morning coffee.")])),
            // Sedona, AZ (2)
            Listing(id: "stay-sedona-red-rock", title: "Red rock view casita", location: "Sedona, AZ", price: 225, rating: 4.96, reviewCount: 112, beds: 1, baths: 1, guests: 2,
                categories: ["Amazing views", "Countryside", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Parking", "Hot tub", "Patio"],
                images: [image("Red Rocks", "sf_stay_289", [UIColor(red:0.86,green:0.48,blue:0.30,alpha:1), UIColor(red:0.96,green:0.62,blue:0.40,alpha:1)]), image("Casita Interior", "sf_stay_290", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)]), image("Sunset Patio", "sf_stay_291", [UIColor(red:0.98,green:0.72,blue:0.52,alpha:1), UIColor(red:0.86,green:0.36,blue:0.30,alpha:1)])],
                host: hostAmara, description: "Desert casita with panoramic red rock views, a private hot tub for stargazing, and trailheads within a short drive.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Nina", 5.0, "Feb 2026", "The hot tub under the stars with red rocks glowing was unreal."), ("Dave", 4.9, "Jan 2026", "Best views of any stay ever.")])),
            Listing(id: "stay-sedona-creek", title: "Oak Creek canyon cabin", location: "Sedona, AZ", price: 175, rating: 4.92, reviewCount: 89, beds: 2, baths: 1, guests: 4,
                categories: ["Cabins", "Countryside", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Parking", "Fireplace", "Hiking access"],
                images: [image("Creek Cabin", "sf_stay_292", [UIColor(red:0.24,green:0.35,blue:0.24,alpha:1), UIColor(red:0.47,green:0.59,blue:0.39,alpha:1)]), image("Fireside", "sf_stay_293", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)]), image("Canyon Trail", "sf_stay_294", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.20,green:0.59,blue:0.51,alpha:1)])],
                host: hostSofia, description: "Creekside cabin tucked into Oak Creek Canyon with a stone fireplace, the sound of flowing water, and Slide Rock a short hike away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ava", 4.9, "Jan 2026", "Falling asleep to the creek was so peaceful."), ("Wyatt", 4.9, "Dec 2025", "The fireplace and canyon views were perfect.")])),
            // Cartagena, Colombia (2)
            Listing(id: "stay-cartagena-walled", title: "Walled City colonial apartment", location: "Cartagena, Colombia", price: 125, rating: 4.93, reviewCount: 198, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Balcony", "Rooftop access"],
                images: [image("Colonial Facade", "sf_stay_295", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)]), image("Colorful Interior", "sf_stay_296", [UIColor(red:0.92,green:0.54,blue:0.38,alpha:1), UIColor(red:0.98,green:0.72,blue:0.52,alpha:1)]), image("Rooftop Terrace", "sf_stay_297", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostDiego, description: "Colonial apartment inside the Walled City with a rooftop terrace, colorful bougainvillea, and the cathedral bells marking the hour.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lucia", 4.9, "Feb 2026", "The rooftop sunset over the old city was magical."), ("James", 4.9, "Jan 2026", "Walking the walls at sunset became our daily ritual.")])),
            Listing(id: "stay-cartagena-getsemani", title: "Getsemani street-art studio", location: "Cartagena, Colombia", price: 85, rating: 4.89, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in"],
                images: [image("Street Art", "sf_stay_298", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Studio Interior", "sf_stay_299", [UIColor(red:0.73,green:0.88,blue:0.66,alpha:1), UIColor(red:0.36,green:0.64,blue:0.45,alpha:1)]), image("Plaza Life", "sf_stay_300", [UIColor(red:0.86,green:0.48,blue:0.30,alpha:1), UIColor(red:0.96,green:0.62,blue:0.40,alpha:1)])],
                host: hostAmara, description: "Compact studio in Getsemani surrounded by street art, plaza life, and some of the best casual food in Cartagena.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Carmen", 4.9, "Jan 2026", "Getsemani is where the real Cartagena lives."), ("Rob", 4.9, "Dec 2025", "Incredible value and amazing energy.")])),
            // Hanoi, Vietnam (2)
            Listing(id: "stay-hanoi-old-quarter", title: "Old Quarter lantern house", location: "Hanoi, Vietnam", price: 58, rating: 4.92, reviewCount: 287, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in"],
                images: [image("Lantern House", "sf_stay_301", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)]), image("Room Interior", "sf_stay_302", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)]), image("Street Life", "sf_stay_303", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)])],
                host: hostJade, description: "Narrow house in the Old Quarter with lantern-lit hallways, pho on every corner, and Hoan Kiem Lake a short walk away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Linh", 5.0, "Feb 2026", "The Old Quarter chaos is part of the charm."), ("Will", 4.9, "Jan 2026", "Best pho of my life was 20 steps from the door.")])),
            Listing(id: "stay-hanoi-west-lake", title: "West Lake lakeside studio", location: "Hanoi, Vietnam", price: 72, rating: 4.88, reviewCount: 189, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Balcony", "Bikes"],
                images: [image("Lake View", "sf_stay_304", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)]), image("Balcony Studio", "sf_stay_305", [UIColor(red:0.92,green:0.90,blue:0.83,alpha:1), UIColor(red:0.78,green:0.64,blue:0.52,alpha:1)]), image("Sunset Ride", "sf_stay_306", [UIColor(red:0.86,green:0.48,blue:0.30,alpha:1), UIColor(red:0.96,green:0.62,blue:0.40,alpha:1)])],
                host: hostJade, description: "Calm lakeside studio on West Lake with a sunset balcony, loaner bikes for the lake loop, and floating cafes nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Trang", 4.9, "Jan 2026", "West Lake sunsets from the balcony were dreamy."), ("Alex", 4.8, "Dec 2025", "Much calmer than the Old Quarter. Perfect balance.")])),
            // ── ADDITIONAL STAYS: TOKYO ─────────────────────────────────
            Listing(id: "stay-tokyo-roppongi", title: "Roppongi Hills designer flat", location: "Tokyo, Japan", price: 245, rating: 4.89, reviewCount: 156, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Washer", "Elevator"],
                images: [image("Living Room", "sf_stay_307", [UIColor(red:0.20,green:0.20,blue:0.25,alpha:1), UIColor(red:0.40,green:0.40,blue:0.48,alpha:1)]), image("Night View", "sf_stay_308", [UIColor(red:0.12,green:0.12,blue:0.20,alpha:1), UIColor(red:0.30,green:0.28,blue:0.42,alpha:1)]), image("Kitchen", "sf_stay_309", [UIColor(red:0.90,green:0.88,blue:0.85,alpha:1), UIColor(red:0.72,green:0.70,blue:0.66,alpha:1)])],
                host: hostKenji, description: "Sleek flat in Roppongi Hills with floor-to-ceiling windows, a Mori Tower view, and Midtown restaurants downstairs.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lisa", 4.9, "Feb 2026", "The city view at night was unreal."), ("Tom", 4.8, "Jan 2026", "Walking distance to everything in Roppongi.")])),
            Listing(id: "stay-tokyo-nakameguro", title: "Nakameguro canal apartment", location: "Tokyo, Japan", price: 158, rating: 4.94, reviewCount: 203, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in", "Workspace"],
                images: [image("Canal View", "sf_stay_310", [UIColor(red:0.78,green:0.85,blue:0.80,alpha:1), UIColor(red:0.55,green:0.68,blue:0.58,alpha:1)]), image("Interior", "sf_stay_311", [UIColor(red:0.92,green:0.90,blue:0.86,alpha:1), UIColor(red:0.80,green:0.76,blue:0.70,alpha:1)]), image("Cafe Street", "sf_stay_312", [UIColor(red:0.74,green:0.66,blue:0.58,alpha:1), UIColor(red:0.88,green:0.82,blue:0.74,alpha:1)])],
                host: hostHiro, description: "Quiet canal-side apartment near Nakameguro's best coffee shops, boutiques, and the cherry blossom-lined Meguro River.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Yuki", 5.0, "Mar 2026", "Cherry blossom season from this apartment was magical."), ("Dan", 4.9, "Feb 2026", "Best neighborhood in Tokyo for a relaxed stay.")])),
            Listing(id: "stay-tokyo-shinjuku", title: "Shinjuku high-rise studio", location: "Tokyo, Japan", price: 112, rating: 4.82, reviewCount: 412, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Air conditioning", "Self check-in", "Elevator"],
                images: [image("City Lights", "sf_stay_313", [UIColor(red:0.15,green:0.18,blue:0.30,alpha:1), UIColor(red:0.35,green:0.40,blue:0.58,alpha:1)]), image("Compact Studio", "sf_stay_314", [UIColor(red:0.88,green:0.86,blue:0.82,alpha:1), UIColor(red:0.70,green:0.68,blue:0.64,alpha:1)]), image("Station Area", "sf_stay_315", [UIColor(red:0.24,green:0.24,blue:0.30,alpha:1), UIColor(red:0.48,green:0.48,blue:0.56,alpha:1)])],
                host: hostYuna, description: "Efficient studio steps from Shinjuku Station with neon views, late-night ramen options, and easy access to every train line.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Mike", 4.8, "Jan 2026", "Perfect location for getting around Tokyo."), ("Suki", 4.8, "Dec 2025", "Small but extremely functional. Great value.")])),
            Listing(id: "stay-tokyo-yanaka", title: "Yanaka traditional townhouse", location: "Tokyo, Japan", price: 189, rating: 4.96, reviewCount: 87, beds: 2, baths: 1, guests: 4,
                categories: ["Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Garden", "Self check-in", "Washer"],
                images: [image("Garden Entry", "sf_stay_316", [UIColor(red:0.35,green:0.50,blue:0.30,alpha:1), UIColor(red:0.55,green:0.70,blue:0.48,alpha:1)]), image("Tatami Room", "sf_stay_317", [UIColor(red:0.86,green:0.82,blue:0.74,alpha:1), UIColor(red:0.68,green:0.62,blue:0.54,alpha:1)]), image("Temple Street", "sf_stay_318", [UIColor(red:0.60,green:0.55,blue:0.50,alpha:1), UIColor(red:0.78,green:0.74,blue:0.68,alpha:1)])],
                host: hostHiro, description: "Renovated machiya in old-town Yanaka with tatami rooms, a pocket garden, and a neighborhood that still feels like 1960s Tokyo.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Emma", 5.0, "Feb 2026", "Yanaka is the hidden gem of Tokyo. This house is perfect."), ("Kai", 4.9, "Jan 2026", "The garden and tatami rooms were so peaceful.")])),
            Listing(id: "stay-tokyo-daikanyama", title: "Daikanyama loft with terrace", location: "Tokyo, Japan", price: 275, rating: 4.91, reviewCount: 64, beds: 2, baths: 1, guests: 3,
                categories: ["Design", "Trending", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Terrace", "Washer"],
                images: [image("Loft Space", "sf_stay_319", [UIColor(red:0.92,green:0.90,blue:0.85,alpha:1), UIColor(red:0.75,green:0.72,blue:0.66,alpha:1)]), image("Terrace", "sf_stay_320", [UIColor(red:0.45,green:0.60,blue:0.50,alpha:1), UIColor(red:0.65,green:0.78,blue:0.68,alpha:1)]), image("Bookshelf Wall", "sf_stay_321", [UIColor(red:0.68,green:0.58,blue:0.48,alpha:1), UIColor(red:0.85,green:0.78,blue:0.68,alpha:1)])],
                host: hostKenji, description: "Architect-designed loft in Daikanyama with a book wall, rooftop terrace, and T-Site Tsutaya just around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Anna", 4.9, "Mar 2026", "The terrace and design details were stunning."), ("James", 4.9, "Feb 2026", "Daikanyama is Tokyo's coolest neighborhood.")])),
            Listing(id: "stay-tokyo-koenji", title: "Koenji vintage district room", location: "Tokyo, Japan", price: 68, rating: 4.85, reviewCount: 298, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Air conditioning", "Self check-in"],
                images: [image("Room", "sf_stay_322", [UIColor(red:0.82,green:0.78,blue:0.72,alpha:1), UIColor(red:0.64,green:0.60,blue:0.54,alpha:1)]), image("Shopping Street", "sf_stay_323", [UIColor(red:0.70,green:0.55,blue:0.42,alpha:1), UIColor(red:0.88,green:0.75,blue:0.60,alpha:1)]), image("Live House", "sf_stay_324", [UIColor(red:0.25,green:0.22,blue:0.30,alpha:1), UIColor(red:0.48,green:0.44,blue:0.55,alpha:1)])],
                host: hostYuna, description: "Budget-friendly room in Koenji's vintage shopping district with thrift stores, live music venues, and izakayas on every block.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Rio", 4.9, "Jan 2026", "Koenji is the real Tokyo. Loved it."), ("Beth", 4.8, "Dec 2025", "Great value and amazing nightlife nearby.")])),
            // ── ADDITIONAL STAYS: PARIS ──────────────────────────────────
            Listing(id: "stay-paris-bastille", title: "Bastille artist loft", location: "Paris, France", price: 165, rating: 4.90, reviewCount: 178, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Elevator", "Workspace"],
                images: [image("Loft Space", "sf_stay_325", [UIColor(red:0.88,green:0.84,blue:0.78,alpha:1), UIColor(red:0.70,green:0.64,blue:0.58,alpha:1)]), image("Studio Wall", "sf_stay_326", [UIColor(red:0.92,green:0.88,blue:0.80,alpha:1), UIColor(red:0.76,green:0.70,blue:0.62,alpha:1)]), image("Market Below", "sf_stay_327", [UIColor(red:0.60,green:0.52,blue:0.44,alpha:1), UIColor(red:0.78,green:0.72,blue:0.64,alpha:1)])],
                host: hostSofia, description: "Double-height artist loft near Place de la Bastille with exposed brick, a mezzanine bedroom, and the Marche d'Aligre market steps away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Claire", 4.9, "Feb 2026", "The loft felt like living in a Parisian film."), ("Hugo", 4.9, "Jan 2026", "Market mornings and bistro evenings. Perfect.")])),
            Listing(id: "stay-paris-latin-quarter", title: "Latin Quarter book-lover's flat", location: "Paris, France", price: 142, rating: 4.93, reviewCount: 245, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in"],
                images: [image("Reading Nook", "sf_stay_328", [UIColor(red:0.72,green:0.62,blue:0.50,alpha:1), UIColor(red:0.90,green:0.82,blue:0.70,alpha:1)]), image("Street View", "sf_stay_329", [UIColor(red:0.55,green:0.50,blue:0.48,alpha:1), UIColor(red:0.75,green:0.70,blue:0.66,alpha:1)]), image("Pantheon Walk", "sf_stay_330", [UIColor(red:0.80,green:0.76,blue:0.70,alpha:1), UIColor(red:0.62,green:0.58,blue:0.52,alpha:1)])],
                host: hostNadia, description: "Cozy one-bedroom near Shakespeare and Company with a reading nook, Pantheon views, and the best falafel on Rue des Rosiers nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Sophie", 5.0, "Mar 2026", "A bibliophile's dream apartment."), ("Tom", 4.9, "Feb 2026", "Location is unbeatable for exploring Paris on foot.")])),
            Listing(id: "stay-paris-canal", title: "Canal Saint-Martin studio", location: "Paris, France", price: 118, rating: 4.87, reviewCount: 189, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Canal View", "sf_stay_331", [UIColor(red:0.45,green:0.58,blue:0.62,alpha:1), UIColor(red:0.65,green:0.78,blue:0.82,alpha:1)]), image("Studio", "sf_stay_332", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Cafe Corner", "sf_stay_333", [UIColor(red:0.68,green:0.60,blue:0.52,alpha:1), UIColor(red:0.85,green:0.78,blue:0.70,alpha:1)])],
                host: hostMateo, description: "Bright studio overlooking Canal Saint-Martin with iron footbridges, canal-side picnics, and the 10th arrondissement's best coffee.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jules", 4.9, "Jan 2026", "Watching the locks from the window was mesmerizing."), ("Amy", 4.8, "Dec 2025", "Hip neighborhood, great local restaurants.")])),
            Listing(id: "stay-paris-belleville", title: "Belleville panoramic penthouse", location: "Paris, France", price: 225, rating: 4.92, reviewCount: 98, beds: 2, baths: 1, guests: 4,
                categories: ["Amazing views", "Design", "City"],
                amenities: ["Wifi", "Kitchen", "Terrace", "Washer", "Elevator"],
                images: [image("Skyline View", "sf_stay_334", [UIColor(red:0.55,green:0.65,blue:0.80,alpha:1), UIColor(red:0.75,green:0.82,blue:0.92,alpha:1)]), image("Terrace", "sf_stay_335", [UIColor(red:0.40,green:0.52,blue:0.42,alpha:1), UIColor(red:0.62,green:0.74,blue:0.62,alpha:1)]), image("Interior", "sf_stay_336", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)])],
                host: hostSofia, description: "Top-floor penthouse in Belleville with a wraparound terrace, Eiffel Tower sunset views, and the multicultural food scene of the 20th below.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Marc", 5.0, "Feb 2026", "The terrace sunset with the Eiffel Tower was unforgettable."), ("Lea", 4.9, "Jan 2026", "Best view in all of Paris, and I've stayed in many.")])),
            Listing(id: "stay-paris-opera", title: "Opéra district classic apartment", location: "Paris, France", price: 198, rating: 4.86, reviewCount: 312, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Air conditioning", "Washer"],
                images: [image("Haussmann Interior", "sf_stay_337", [UIColor(red:0.90,green:0.86,blue:0.78,alpha:1), UIColor(red:0.74,green:0.68,blue:0.60,alpha:1)]), image("Balcony", "sf_stay_338", [UIColor(red:0.60,green:0.58,blue:0.55,alpha:1), UIColor(red:0.80,green:0.78,blue:0.74,alpha:1)]), image("Opera House", "sf_stay_339", [UIColor(red:0.35,green:0.30,blue:0.28,alpha:1), UIColor(red:0.55,green:0.50,blue:0.48,alpha:1)])],
                host: hostElsa, description: "Classic Haussmann apartment with herringbone floors, a Juliet balcony, and Palais Garnier just two blocks away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Pierre", 4.9, "Mar 2026", "The apartment is quintessentially Parisian."), ("Kate", 4.8, "Feb 2026", "Central, elegant, and exactly what we wanted.")])),
            Listing(id: "stay-paris-pigalle", title: "South Pigalle boutique room", location: "Paris, France", price: 95, rating: 4.84, reviewCount: 267, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Self check-in", "Air conditioning"],
                images: [image("Boutique Room", "sf_stay_340", [UIColor(red:0.78,green:0.68,blue:0.60,alpha:1), UIColor(red:0.92,green:0.84,blue:0.76,alpha:1)]), image("SoPi Street", "sf_stay_341", [UIColor(red:0.50,green:0.45,blue:0.40,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Cocktail Bar", "sf_stay_342", [UIColor(red:0.25,green:0.20,blue:0.28,alpha:1), UIColor(red:0.48,green:0.42,blue:0.52,alpha:1)])],
                host: hostNadia, description: "Stylish room in South Pigalle—Paris's cocktail bar capital—with natural wine spots, vintage shops, and Montmartre a short walk uphill.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Chloe", 4.9, "Jan 2026", "SoPi is the coolest neighborhood in Paris right now."), ("Ben", 4.8, "Dec 2025", "Great nightlife and character. Loved it.")])),
            // ── ADDITIONAL STAYS: NEW YORK ───────────────────────────────
            Listing(id: "stay-nyc-les", title: "Lower East Side walkup", location: "New York, NY", price: 165, rating: 4.88, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in"],
                images: [image("Apartment", "sf_stay_343", [UIColor(red:0.82,green:0.78,blue:0.72,alpha:1), UIColor(red:0.64,green:0.60,blue:0.54,alpha:1)]), image("Street Scene", "sf_stay_344", [UIColor(red:0.55,green:0.48,blue:0.42,alpha:1), UIColor(red:0.75,green:0.68,blue:0.62,alpha:1)]), image("Rooftop", "sf_stay_345", [UIColor(red:0.30,green:0.35,blue:0.50,alpha:1), UIColor(red:0.52,green:0.58,blue:0.72,alpha:1)])],
                host: hostAndre, description: "Fourth-floor walkup on Orchard Street with dim sum around the corner, rooftop access, and the best late-night pizza in Manhattan.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jake", 4.9, "Feb 2026", "Perfect location for nightlife and food."), ("Mia", 4.8, "Jan 2026", "Classic NYC apartment in the best neighborhood.")])),
            Listing(id: "stay-nyc-brooklyn-heights", title: "Brooklyn Heights brownstone floor", location: "New York, NY", price: 285, rating: 4.95, reviewCount: 87, beds: 3, baths: 2, guests: 6,
                categories: ["City", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Workspace", "Garden"],
                images: [image("Brownstone", "sf_stay_346", [UIColor(red:0.65,green:0.50,blue:0.38,alpha:1), UIColor(red:0.82,green:0.70,blue:0.55,alpha:1)]), image("Living Room", "sf_stay_347", [UIColor(red:0.90,green:0.86,blue:0.80,alpha:1), UIColor(red:0.74,green:0.68,blue:0.62,alpha:1)]), image("Promenade View", "sf_stay_348", [UIColor(red:0.40,green:0.50,blue:0.65,alpha:1), UIColor(red:0.60,green:0.72,blue:0.85,alpha:1)])],
                host: hostElsa, description: "Full parlor floor of a landmarked brownstone with original moldings, a garden, and the Brooklyn Heights Promenade two blocks away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Sarah", 5.0, "Mar 2026", "Most beautiful apartment I have ever stayed in."), ("Chris", 4.9, "Feb 2026", "The promenade walk to the Manhattan skyline was daily magic.")])),
            Listing(id: "stay-nyc-chelsea", title: "Chelsea gallery district loft", location: "New York, NY", price: 210, rating: 4.87, reviewCount: 156, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Air conditioning", "Workspace"],
                images: [image("Loft", "sf_stay_349", [UIColor(red:0.88,green:0.86,blue:0.82,alpha:1), UIColor(red:0.72,green:0.68,blue:0.64,alpha:1)]), image("Gallery Wall", "sf_stay_350", [UIColor(red:0.95,green:0.93,blue:0.90,alpha:1), UIColor(red:0.80,green:0.78,blue:0.74,alpha:1)]), image("High Line", "sf_stay_351", [UIColor(red:0.40,green:0.55,blue:0.38,alpha:1), UIColor(red:0.60,green:0.75,blue:0.58,alpha:1)])],
                host: hostLena, description: "Open-plan loft in the gallery district with concrete floors, High Line access, and Chelsea Market for morning pastries.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Diana", 4.9, "Jan 2026", "Walked to galleries every day. Dream location."), ("Paul", 4.8, "Dec 2025", "The High Line right outside was a huge bonus.")])),
            Listing(id: "stay-nyc-soho", title: "SoHo cast-iron loft", location: "New York, NY", price: 325, rating: 4.91, reviewCount: 112, beds: 2, baths: 1, guests: 4,
                categories: ["Design", "City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Washer", "Air conditioning"],
                images: [image("Cast Iron Detail", "sf_stay_352", [UIColor(red:0.75,green:0.72,blue:0.68,alpha:1), UIColor(red:0.90,green:0.88,blue:0.84,alpha:1)]), image("Open Floor", "sf_stay_353", [UIColor(red:0.92,green:0.90,blue:0.86,alpha:1), UIColor(red:0.78,green:0.74,blue:0.70,alpha:1)]), image("Cobblestone Street", "sf_stay_354", [UIColor(red:0.58,green:0.52,blue:0.46,alpha:1), UIColor(red:0.76,green:0.72,blue:0.66,alpha:1)])],
                host: hostRina, description: "Spacious loft in a landmark cast-iron building on Mercer Street with soaring ceilings, cobblestone views, and SoHo shopping at the door.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Olivia", 5.0, "Feb 2026", "Iconic SoHo loft living. Worth every penny."), ("Ryan", 4.8, "Jan 2026", "The ceilings and light in this place are incredible.")])),
            Listing(id: "stay-nyc-ues", title: "Upper East Side classic one-bed", location: "New York, NY", price: 178, rating: 4.83, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["City"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Air conditioning", "Doorman"],
                images: [image("Classic Interior", "sf_stay_355", [UIColor(red:0.86,green:0.82,blue:0.76,alpha:1), UIColor(red:0.70,green:0.66,blue:0.60,alpha:1)]), image("Park View", "sf_stay_356", [UIColor(red:0.35,green:0.50,blue:0.35,alpha:1), UIColor(red:0.55,green:0.70,blue:0.55,alpha:1)]), image("Museum Mile", "sf_stay_357", [UIColor(red:0.72,green:0.68,blue:0.62,alpha:1), UIColor(red:0.88,green:0.84,blue:0.78,alpha:1)])],
                host: hostLucia, description: "Doorman building one-bedroom near the Met and Central Park with a pre-war layout, Museum Mile access, and quiet tree-lined streets.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Helen", 4.8, "Feb 2026", "Morning runs in Central Park and afternoon Met visits."), ("Greg", 4.8, "Jan 2026", "Classic UES feel. Very comfortable and safe.")])),
            Listing(id: "stay-nyc-bushwick", title: "Bushwick creative studio", location: "New York, NY", price: 95, rating: 4.86, reviewCount: 345, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Mural Wall", "sf_stay_358", [UIColor(red:0.72,green:0.45,blue:0.35,alpha:1), UIColor(red:0.90,green:0.65,blue:0.50,alpha:1)]), image("Studio Space", "sf_stay_359", [UIColor(red:0.85,green:0.82,blue:0.78,alpha:1), UIColor(red:0.68,green:0.64,blue:0.60,alpha:1)]), image("Street Art", "sf_stay_360", [UIColor(red:0.45,green:0.38,blue:0.55,alpha:1), UIColor(red:0.65,green:0.58,blue:0.75,alpha:1)])],
                host: hostAndre, description: "Bright ground-floor studio in Bushwick surrounded by murals, warehouse galleries, and the best taco trucks in Brooklyn.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Zoe", 4.9, "Jan 2026", "Bushwick energy is incredible. Great base for exploring."), ("Marco", 4.8, "Dec 2025", "Affordable NYC with tons of character.")])),
            // ── ADDITIONAL STAYS: LONDON ─────────────────────────────────
            Listing(id: "stay-london-south-bank", title: "South Bank river view flat", location: "London, UK", price: 195, rating: 4.89, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Washer", "Elevator", "Air conditioning"],
                images: [image("Thames View", "sf_stay_361", [UIColor(red:0.40,green:0.50,blue:0.60,alpha:1), UIColor(red:0.60,green:0.72,blue:0.82,alpha:1)]), image("Modern Interior", "sf_stay_362", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Tate Walk", "sf_stay_363", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostIsla, description: "Modern flat with Thames river views, a short walk to the Tate Modern, Borough Market, and the Globe Theatre.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("James", 4.9, "Feb 2026", "Waking up to the Thames was special."), ("Fiona", 4.9, "Jan 2026", "Borough Market every morning. Heaven.")])),
            Listing(id: "stay-london-hackney", title: "Hackney warehouse conversion", location: "London, UK", price: 145, rating: 4.91, reviewCount: 203, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Workspace", "Self check-in"],
                images: [image("Warehouse Space", "sf_stay_364", [UIColor(red:0.70,green:0.65,blue:0.58,alpha:1), UIColor(red:0.88,green:0.84,blue:0.76,alpha:1)]), image("Brick Interior", "sf_stay_365", [UIColor(red:0.82,green:0.72,blue:0.62,alpha:1), UIColor(red:0.68,green:0.58,blue:0.48,alpha:1)]), image("Broadway Market", "sf_stay_366", [UIColor(red:0.50,green:0.55,blue:0.48,alpha:1), UIColor(red:0.70,green:0.75,blue:0.68,alpha:1)])],
                host: hostOmar, description: "Converted warehouse in Hackney with exposed brick, double-height ceilings, Broadway Market on Saturdays, and London Fields park nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Liam", 4.9, "Jan 2026", "The warehouse vibe is amazing. Hackney is so vibrant."), ("Nina", 4.9, "Dec 2025", "Broadway Market alone makes this neighborhood worth it.")])),
            Listing(id: "stay-london-fitzrovia", title: "Fitzrovia townhouse room", location: "London, UK", price: 168, rating: 4.85, reviewCount: 289, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Air conditioning"],
                images: [image("Georgian Room", "sf_stay_367", [UIColor(red:0.86,green:0.82,blue:0.76,alpha:1), UIColor(red:0.70,green:0.66,blue:0.60,alpha:1)]), image("Charlotte Street", "sf_stay_368", [UIColor(red:0.62,green:0.58,blue:0.52,alpha:1), UIColor(red:0.80,green:0.76,blue:0.70,alpha:1)]), image("Pub Corner", "sf_stay_369", [UIColor(red:0.45,green:0.38,blue:0.32,alpha:1), UIColor(red:0.65,green:0.58,blue:0.52,alpha:1)])],
                host: hostElsa, description: "Georgian townhouse room in Fitzrovia with Charlotte Street restaurants, Regent's Park nearby, and the West End a short walk south.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Oliver", 4.9, "Feb 2026", "Fitzrovia is perfectly central without the tourist crowds."), ("Grace", 4.8, "Jan 2026", "Charlotte Street dining was a highlight every night.")])),
            Listing(id: "stay-london-brixton", title: "Brixton village apartment", location: "London, UK", price: 115, rating: 4.88, reviewCount: 178, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in"],
                images: [image("Colorful Street", "sf_stay_370", [UIColor(red:0.78,green:0.55,blue:0.40,alpha:1), UIColor(red:0.92,green:0.72,blue:0.55,alpha:1)]), image("Apartment", "sf_stay_371", [UIColor(red:0.85,green:0.82,blue:0.78,alpha:1), UIColor(red:0.68,green:0.64,blue:0.60,alpha:1)]), image("Market Hall", "sf_stay_372", [UIColor(red:0.55,green:0.48,blue:0.42,alpha:1), UIColor(red:0.75,green:0.68,blue:0.62,alpha:1)])],
                host: hostOmar, description: "Bright apartment above Brixton Village market with Caribbean food stalls, live music venues, and Brockwell Park for morning walks.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Kwame", 4.9, "Jan 2026", "Brixton is electric. The market is unbelievable."), ("Amy", 4.8, "Dec 2025", "So much culture and energy in this neighborhood.")])),
            Listing(id: "stay-london-greenwich", title: "Greenwich riverside cottage", location: "London, UK", price: 155, rating: 4.93, reviewCount: 92, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Washer", "Parking"],
                images: [image("Cottage Front", "sf_stay_373", [UIColor(red:0.45,green:0.55,blue:0.42,alpha:1), UIColor(red:0.65,green:0.75,blue:0.62,alpha:1)]), image("Cozy Interior", "sf_stay_374", [UIColor(red:0.88,green:0.84,blue:0.78,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Observatory Hill", "sf_stay_375", [UIColor(red:0.35,green:0.45,blue:0.55,alpha:1), UIColor(red:0.55,green:0.65,blue:0.75,alpha:1)])],
                host: hostIsla, description: "Charming cottage near the Cutty Sark with Greenwich Park, the Royal Observatory, and Thames river walks from the front door.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("David", 5.0, "Feb 2026", "Greenwich felt like a village inside London."), ("Emma", 4.9, "Jan 2026", "The park and observatory made this stay unforgettable.")])),
            Listing(id: "stay-london-marylebone", title: "Marylebone mews house", location: "London, UK", price: 310, rating: 4.94, reviewCount: 54, beds: 3, baths: 2, guests: 5,
                categories: ["Design", "Guest favorite", "City"],
                amenities: ["Wifi", "Kitchen", "Washer", "Garden", "Parking"],
                images: [image("Mews Exterior", "sf_stay_376", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)]), image("Open Kitchen", "sf_stay_377", [UIColor(red:0.92,green:0.90,blue:0.86,alpha:1), UIColor(red:0.78,green:0.74,blue:0.70,alpha:1)]), image("Cobbled Lane", "sf_stay_378", [UIColor(red:0.60,green:0.55,blue:0.50,alpha:1), UIColor(red:0.78,green:0.74,blue:0.68,alpha:1)])],
                host: hostElsa, description: "Converted mews house on a cobbled lane in Marylebone with three bedrooms, a private patio, and Daunt Books around the corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Victoria", 5.0, "Mar 2026", "The most charming house on the most charming lane."), ("Andrew", 4.9, "Feb 2026", "Marylebone is the perfect London base. This house is exceptional.")])),
            // ── ADDITIONAL STAYS: SEOUL ──────────────────────────────────
            Listing(id: "stay-seoul-hongdae", title: "Hongdae arts district flat", location: "Seoul, South Korea", price: 78, rating: 4.87, reviewCount: 356, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in", "Washer"],
                images: [image("Flat Interior", "sf_stay_379", [UIColor(red:0.85,green:0.82,blue:0.78,alpha:1), UIColor(red:0.68,green:0.64,blue:0.60,alpha:1)]), image("Street Art", "sf_stay_380", [UIColor(red:0.70,green:0.50,blue:0.60,alpha:1), UIColor(red:0.88,green:0.70,blue:0.78,alpha:1)]), image("Night Scene", "sf_stay_381", [UIColor(red:0.20,green:0.18,blue:0.28,alpha:1), UIColor(red:0.42,green:0.38,blue:0.52,alpha:1)])],
                host: hostYuna, description: "Bright studio in Hongdae's indie arts district with busking, craft beer bars, vinyl shops, and the best late-night Korean fried chicken.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Min", 4.9, "Feb 2026", "Hongdae nightlife is unmatched. Great location."), ("Josh", 4.8, "Jan 2026", "Walking distance to everything fun in Seoul.")])),
            Listing(id: "stay-seoul-bukchon", title: "Bukchon hanok guesthouse", location: "Seoul, South Korea", price: 135, rating: 4.95, reviewCount: 145, beds: 2, baths: 1, guests: 3,
                categories: ["Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Garden", "Self check-in"],
                images: [image("Hanok Courtyard", "sf_stay_382", [UIColor(red:0.62,green:0.55,blue:0.45,alpha:1), UIColor(red:0.80,green:0.74,blue:0.64,alpha:1)]), image("Traditional Room", "sf_stay_383", [UIColor(red:0.88,green:0.84,blue:0.76,alpha:1), UIColor(red:0.72,green:0.66,blue:0.58,alpha:1)]), image("Village Path", "sf_stay_384", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostKenji, description: "Traditional hanok with a courtyard garden in Bukchon village, between Gyeongbokgung Palace and Changdeokgung, with tea houses on every corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Soo", 5.0, "Mar 2026", "Sleeping on ondol floors in a real hanok was special."), ("Laura", 4.9, "Feb 2026", "The courtyard morning tea ritual was beautiful.")])),
            Listing(id: "stay-seoul-yeonnam", title: "Yeonnam-dong cozy studio", location: "Seoul, South Korea", price: 62, rating: 4.89, reviewCount: 278, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Cafe Street", "sf_stay_385", [UIColor(red:0.75,green:0.72,blue:0.65,alpha:1), UIColor(red:0.90,green:0.88,blue:0.82,alpha:1)]), image("Studio", "sf_stay_386", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Gyeongui Line Park", "sf_stay_387", [UIColor(red:0.40,green:0.55,blue:0.40,alpha:1), UIColor(red:0.60,green:0.75,blue:0.60,alpha:1)])],
                host: hostYuna, description: "Charming studio on Yeonnam-dong's cafe-lined streets with Gyeongui Line Forest Park, brunch spots, and a village-in-the-city feel.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Hana", 4.9, "Jan 2026", "Yeonnam-dong is Seoul's coziest neighborhood."), ("Tim", 4.9, "Dec 2025", "The park walk and cafe hopping were daily joys.")])),
            Listing(id: "stay-seoul-jongno", title: "Jongno hanok with rooftop", location: "Seoul, South Korea", price: 155, rating: 4.92, reviewCount: 98, beds: 2, baths: 1, guests: 4,
                categories: ["Design", "Amazing views", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Rooftop", "Air conditioning", "Self check-in"],
                images: [image("Rooftop Sunset", "sf_stay_388", [UIColor(red:0.85,green:0.55,blue:0.35,alpha:1), UIColor(red:0.95,green:0.72,blue:0.50,alpha:1)]), image("Hanok Interior", "sf_stay_389", [UIColor(red:0.82,green:0.76,blue:0.68,alpha:1), UIColor(red:0.65,green:0.58,blue:0.50,alpha:1)]), image("Palace Wall", "sf_stay_390", [UIColor(red:0.55,green:0.50,blue:0.45,alpha:1), UIColor(red:0.74,green:0.70,blue:0.64,alpha:1)])],
                host: hostHiro, description: "Renovated hanok near Gyeongbokgung with a rooftop terrace overlooking palace walls, Insadong galleries, and Bukchon alleyways.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jin", 5.0, "Feb 2026", "Rooftop views of the palace at sunset were breathtaking."), ("Kelly", 4.9, "Jan 2026", "Perfect blend of traditional and modern.")])),
            // ── ADDITIONAL STAYS: BERLIN ─────────────────────────────────
            Listing(id: "stay-berlin-prenzlauer", title: "Prenzlauer Berg family flat", location: "Berlin, Germany", price: 125, rating: 4.90, reviewCount: 189, beds: 3, baths: 1, guests: 5,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Washer", "Workspace", "Balcony"],
                images: [image("Altbau Living", "sf_stay_391", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Balcony Garden", "sf_stay_392", [UIColor(red:0.45,green:0.58,blue:0.42,alpha:1), UIColor(red:0.65,green:0.78,blue:0.62,alpha:1)]), image("Mauerpark", "sf_stay_393", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostLina, description: "Spacious Altbau flat in Prenzlauer Berg with high ceilings, a balcony with plants, Mauerpark flea market on Sundays, and family-friendly cafes.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Anna", 4.9, "Feb 2026", "Best neighborhood for families in Berlin."), ("Stefan", 4.9, "Jan 2026", "The Altbau charm and Mauerpark Sundays were perfect.")])),
            Listing(id: "stay-berlin-charlottenburg", title: "Charlottenburg grand apartment", location: "Berlin, Germany", price: 185, rating: 4.88, reviewCount: 134, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Washer", "Air conditioning"],
                images: [image("Grand Room", "sf_stay_394", [UIColor(red:0.90,green:0.86,blue:0.78,alpha:1), UIColor(red:0.74,green:0.68,blue:0.60,alpha:1)]), image("Tiergarten View", "sf_stay_395", [UIColor(red:0.35,green:0.50,blue:0.35,alpha:1), UIColor(red:0.55,green:0.70,blue:0.55,alpha:1)]), image("KaDeWe Street", "sf_stay_396", [UIColor(red:0.62,green:0.58,blue:0.52,alpha:1), UIColor(red:0.80,green:0.76,blue:0.70,alpha:1)])],
                host: hostChen, description: "Elegant pre-war apartment near Schloss Charlottenburg with stucco ceilings, Tiergarten walks, and KaDeWe department store nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Petra", 4.9, "Jan 2026", "Old Berlin elegance at its finest."), ("Michael", 4.8, "Dec 2025", "The neighborhood feels sophisticated and calm.")])),
            Listing(id: "stay-berlin-friedrichshain", title: "Friedrichshain party district loft", location: "Berlin, Germany", price: 82, rating: 4.84, reviewCount: 312, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Washer"],
                images: [image("Industrial Loft", "sf_stay_397", [UIColor(red:0.72,green:0.68,blue:0.62,alpha:1), UIColor(red:0.55,green:0.50,blue:0.44,alpha:1)]), image("East Side Gallery", "sf_stay_398", [UIColor(red:0.65,green:0.50,blue:0.55,alpha:1), UIColor(red:0.82,green:0.68,blue:0.72,alpha:1)]), image("Spree River", "sf_stay_399", [UIColor(red:0.40,green:0.52,blue:0.60,alpha:1), UIColor(red:0.60,green:0.72,blue:0.80,alpha:1)])],
                host: hostLina, description: "Industrial loft near the East Side Gallery and RAW Gelande with Berlin's best club scene, Spree river bars, and late-night doner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Felix", 4.8, "Feb 2026", "This is the Berlin experience. Clubs, art, and doner."), ("Isla", 4.8, "Jan 2026", "Great value for an incredible neighborhood.")])),
            Listing(id: "stay-berlin-wedding", title: "Wedding artist collective room", location: "Berlin, Germany", price: 55, rating: 4.82, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Self check-in", "Workspace"],
                images: [image("Art Studio", "sf_stay_400", [UIColor(red:0.78,green:0.72,blue:0.65,alpha:1), UIColor(red:0.62,green:0.55,blue:0.48,alpha:1)]), image("Collective Space", "sf_stay_401", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Canal Walk", "sf_stay_402", [UIColor(red:0.45,green:0.55,blue:0.50,alpha:1), UIColor(red:0.65,green:0.75,blue:0.70,alpha:1)])],
                host: hostZara, description: "Simple room in a Wedding artist collective with shared studio space, Panke canal walks, and the most affordable eats in Berlin.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Klaus", 4.8, "Jan 2026", "Wedding is Berlin's next big neighborhood. Get here early."), ("Yuki", 4.8, "Dec 2025", "Loved the creative energy and cheap eats.")])),
            // ── ADDITIONAL STAYS: BARCELONA ──────────────────────────────
            Listing(id: "stay-barcelona-born", title: "El Born gothic quarter flat", location: "Barcelona, Spain", price: 138, rating: 4.91, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in", "Washer"],
                images: [image("Gothic Archway", "sf_stay_403", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)]), image("Flat Interior", "sf_stay_404", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Basilica View", "sf_stay_405", [UIColor(red:0.60,green:0.55,blue:0.50,alpha:1), UIColor(red:0.78,green:0.74,blue:0.68,alpha:1)])],
                host: hostDiego, description: "Stone-walled flat in El Born near Santa Maria del Mar, the Picasso Museum, and the best vermouth bars in Barcelona.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Maria", 4.9, "Feb 2026", "El Born is the heart of Barcelona. Perfect apartment."), ("Jack", 4.9, "Jan 2026", "Walking to tapas bars every night from here was ideal.")])),
            Listing(id: "stay-barcelona-eixample", title: "Eixample Modernista apartment", location: "Barcelona, Spain", price: 175, rating: 4.90, reviewCount: 178, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Air conditioning", "Balcony"],
                images: [image("Modernista Details", "sf_stay_406", [UIColor(red:0.82,green:0.72,blue:0.55,alpha:1), UIColor(red:0.94,green:0.86,blue:0.70,alpha:1)]), image("Living Room", "sf_stay_407", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Passeig de Gracia", "sf_stay_408", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostSofia, description: "Art Nouveau apartment on Eixample's grid with original tile floors, Gaudi's Casa Batllo nearby, and Passeig de Gracia shopping.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Carlos", 4.9, "Mar 2026", "The Modernista tiles alone are worth the stay."), ("Sophie", 4.9, "Feb 2026", "Beautiful apartment in the best part of Eixample.")])),
            Listing(id: "stay-barcelona-barceloneta", title: "Barceloneta beachfront studio", location: "Barcelona, Spain", price: 155, rating: 4.85, reviewCount: 312, beds: 1, baths: 1, guests: 2,
                categories: ["Beachfront", "City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in"],
                images: [image("Beach View", "sf_stay_409", [UIColor(red:0.45,green:0.68,blue:0.82,alpha:1), UIColor(red:0.65,green:0.85,blue:0.92,alpha:1)]), image("Studio", "sf_stay_410", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Seafood Market", "sf_stay_411", [UIColor(red:0.70,green:0.58,blue:0.45,alpha:1), UIColor(red:0.88,green:0.78,blue:0.65,alpha:1)])],
                host: hostMateo, description: "Bright studio in old Barceloneta, two minutes from the beach, with seafood restaurants, chiringuitos, and the W Hotel promenade.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lucia", 4.9, "Feb 2026", "Beach every morning, tapas every night."), ("Dan", 4.8, "Jan 2026", "Best location for a summer Barcelona trip.")])),
            Listing(id: "stay-barcelona-poble-sec", title: "Poble-sec vermouth district room", location: "Barcelona, Spain", price: 85, rating: 4.88, reviewCount: 267, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Air conditioning", "Self check-in"],
                images: [image("Neighborhood Bar", "sf_stay_412", [UIColor(red:0.72,green:0.60,blue:0.48,alpha:1), UIColor(red:0.90,green:0.80,blue:0.68,alpha:1)]), image("Room", "sf_stay_413", [UIColor(red:0.86,green:0.82,blue:0.78,alpha:1), UIColor(red:0.70,green:0.66,blue:0.60,alpha:1)]), image("Montjuic Path", "sf_stay_414", [UIColor(red:0.38,green:0.52,blue:0.38,alpha:1), UIColor(red:0.58,green:0.72,blue:0.58,alpha:1)])],
                host: hostDiego, description: "Affordable room in Poble-sec with the city's best pintxos bars on Carrer de Blai, Montjuic hikes, and a local neighborhood feel.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ana", 4.9, "Jan 2026", "Carrer de Blai pintxos every night. Amazing."), ("Leo", 4.8, "Dec 2025", "Best value in Barcelona. Real neighborhood vibes.")])),
            // ── ADDITIONAL STAYS: ROME ───────────────────────────────────
            Listing(id: "stay-rome-testaccio", title: "Testaccio food district apartment", location: "Rome, Italy", price: 128, rating: 4.92, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Washer", "Self check-in"],
                images: [image("Market View", "sf_stay_415", [UIColor(red:0.82,green:0.68,blue:0.50,alpha:1), UIColor(red:0.94,green:0.82,blue:0.65,alpha:1)]), image("Apartment", "sf_stay_416", [UIColor(red:0.90,green:0.86,blue:0.80,alpha:1), UIColor(red:0.74,green:0.68,blue:0.62,alpha:1)]), image("Evening Piazza", "sf_stay_417", [UIColor(red:0.55,green:0.45,blue:0.38,alpha:1), UIColor(red:0.75,green:0.65,blue:0.58,alpha:1)])],
                host: hostMateo, description: "Apartment in Rome's food capital Testaccio with the historic market, cacio e pepe at its birthplace, and Monte Testaccio nightlife.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Giulia", 5.0, "Feb 2026", "Testaccio is where Romans actually eat. This is the real Rome."), ("Peter", 4.9, "Jan 2026", "Best carbonara of my life was around the corner.")])),
            Listing(id: "stay-rome-prati", title: "Prati Vatican-area flat", location: "Rome, Italy", price: 148, rating: 4.86, reviewCount: 256, beds: 2, baths: 1, guests: 4,
                categories: ["City"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Elevator", "Washer"],
                images: [image("Vatican Proximity", "sf_stay_418", [UIColor(red:0.85,green:0.80,blue:0.72,alpha:1), UIColor(red:0.68,green:0.62,blue:0.54,alpha:1)]), image("Bright Kitchen", "sf_stay_419", [UIColor(red:0.92,green:0.90,blue:0.86,alpha:1), UIColor(red:0.78,green:0.74,blue:0.70,alpha:1)]), image("Bridge Walk", "sf_stay_420", [UIColor(red:0.62,green:0.58,blue:0.52,alpha:1), UIColor(red:0.80,green:0.76,blue:0.70,alpha:1)])],
                host: hostLucia, description: "Two-bedroom flat in quiet Prati with Vatican Museums around the corner, Castel Sant'Angelo walks, and excellent neighborhood trattorias.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Frank", 4.9, "Feb 2026", "Perfect base for the Vatican. Quiet and comfortable."), ("Lisa", 4.8, "Jan 2026", "Prati restaurants were a welcome escape from tourist traps.")])),
            Listing(id: "stay-rome-san-lorenzo", title: "San Lorenzo student quarter room", location: "Rome, Italy", price: 72, rating: 4.84, reviewCount: 345, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in"],
                images: [image("Street Art", "sf_stay_421", [UIColor(red:0.70,green:0.55,blue:0.45,alpha:1), UIColor(red:0.88,green:0.75,blue:0.62,alpha:1)]), image("Room", "sf_stay_422", [UIColor(red:0.85,green:0.82,blue:0.78,alpha:1), UIColor(red:0.68,green:0.64,blue:0.60,alpha:1)]), image("Piazza Night", "sf_stay_423", [UIColor(red:0.25,green:0.22,blue:0.30,alpha:1), UIColor(red:0.48,green:0.44,blue:0.55,alpha:1)])],
                host: hostDiego, description: "Budget-friendly room in the university quarter with the best pizza al taglio in Rome, street art, and a young lively energy.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Marco", 4.8, "Jan 2026", "Cheapest and most authentic neighborhood in Rome."), ("Julia", 4.8, "Dec 2025", "The pizza and nightlife here are incredible.")])),
            Listing(id: "stay-rome-aventine", title: "Aventine Hill garden apartment", location: "Rome, Italy", price: 195, rating: 4.94, reviewCount: 76, beds: 2, baths: 1, guests: 3,
                categories: ["Guest favorite", "Amazing views", "Design"],
                amenities: ["Wifi", "Kitchen", "Garden", "Air conditioning", "Washer"],
                images: [image("Orange Garden", "sf_stay_424", [UIColor(red:0.45,green:0.58,blue:0.38,alpha:1), UIColor(red:0.65,green:0.78,blue:0.58,alpha:1)]), image("Apartment", "sf_stay_425", [UIColor(red:0.90,green:0.86,blue:0.80,alpha:1), UIColor(red:0.74,green:0.68,blue:0.62,alpha:1)]), image("Dome View", "sf_stay_426", [UIColor(red:0.62,green:0.58,blue:0.55,alpha:1), UIColor(red:0.82,green:0.78,blue:0.74,alpha:1)])],
                host: hostSofia, description: "Elegant apartment on the Aventine Hill near the Orange Garden and the Knights of Malta keyhole, with a private garden and city panorama.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Isabella", 5.0, "Mar 2026", "The keyhole view and the Orange Garden made this magical."), ("Tom", 4.9, "Feb 2026", "Quietest, most beautiful corner of Rome.")])),
            // ── ADDITIONAL STAYS: AMSTERDAM ──────────────────────────────
            Listing(id: "stay-amsterdam-de-pijp", title: "De Pijp market district flat", location: "Amsterdam, Netherlands", price: 155, rating: 4.90, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in", "Bikes"],
                images: [image("Albert Cuyp", "sf_stay_427", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)]), image("Flat", "sf_stay_428", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Canal Bike Ride", "sf_stay_429", [UIColor(red:0.40,green:0.55,blue:0.52,alpha:1), UIColor(red:0.60,green:0.75,blue:0.72,alpha:1)])],
                host: hostElsa, description: "Bright flat in De Pijp with Albert Cuyp market on the doorstep, Heineken Experience nearby, and loaner bikes for canal rides.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Marten", 4.9, "Feb 2026", "Albert Cuyp market every morning was a dream."), ("Sophie", 4.9, "Jan 2026", "Best neighborhood to live like a local in Amsterdam.")])),
            Listing(id: "stay-amsterdam-west", title: "Amsterdam West canal house room", location: "Amsterdam, Netherlands", price: 125, rating: 4.87, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Bikes"],
                images: [image("Canal House", "sf_stay_430", [UIColor(red:0.65,green:0.55,blue:0.42,alpha:1), UIColor(red:0.82,green:0.74,blue:0.60,alpha:1)]), image("Room", "sf_stay_431", [UIColor(red:0.86,green:0.82,blue:0.78,alpha:1), UIColor(red:0.70,green:0.66,blue:0.60,alpha:1)]), image("Food Hallen", "sf_stay_432", [UIColor(red:0.55,green:0.50,blue:0.45,alpha:1), UIColor(red:0.75,green:0.70,blue:0.65,alpha:1)])],
                host: hostOmar, description: "Canal house room in Amsterdam West near the Foodhallen, Vondelpark, and the city's best Indonesian restaurants.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jan", 4.9, "Jan 2026", "Amsterdam West is the new center. Great spot."), ("Emily", 4.8, "Dec 2025", "Foodhallen and Vondelpark made this perfect.")])),
            Listing(id: "stay-amsterdam-noord", title: "Amsterdam Noord creative loft", location: "Amsterdam, Netherlands", price: 108, rating: 4.86, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Self check-in"],
                images: [image("NDSM Wharf", "sf_stay_433", [UIColor(red:0.58,green:0.55,blue:0.52,alpha:1), UIColor(red:0.78,green:0.74,blue:0.70,alpha:1)]), image("Loft Space", "sf_stay_434", [UIColor(red:0.85,green:0.82,blue:0.78,alpha:1), UIColor(red:0.68,green:0.64,blue:0.60,alpha:1)]), image("Ferry View", "sf_stay_435", [UIColor(red:0.42,green:0.55,blue:0.65,alpha:1), UIColor(red:0.62,green:0.75,blue:0.85,alpha:1)])],
                host: hostChen, description: "Creative loft near NDSM Wharf in Amsterdam Noord with free ferry to Central Station, street art, and industrial-chic restaurants.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Daan", 4.9, "Feb 2026", "Noord is Amsterdam's coolest area right now."), ("Rachel", 4.8, "Jan 2026", "The free ferry ride is part of the charm.")])),
            // ── ADDITIONAL STAYS: LISBON ──────────────────────────────────
            Listing(id: "stay-lisbon-principe", title: "Principe Real garden flat", location: "Lisbon, Portugal", price: 135, rating: 4.93, reviewCount: 167, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Balcony", "Self check-in"],
                images: [image("Garden Square", "sf_stay_436", [UIColor(red:0.45,green:0.58,blue:0.42,alpha:1), UIColor(red:0.65,green:0.78,blue:0.62,alpha:1)]), image("Tiled Interior", "sf_stay_437", [UIColor(red:0.55,green:0.62,blue:0.78,alpha:1), UIColor(red:0.75,green:0.82,blue:0.92,alpha:1)]), image("Sunset Balcony", "sf_stay_438", [UIColor(red:0.85,green:0.60,blue:0.38,alpha:1), UIColor(red:0.95,green:0.75,blue:0.52,alpha:1)])],
                host: hostMateo, description: "Azulejo-tiled flat near Principe Real gardens with concept stores, wine bars, and Tagus River sunset views from the balcony.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Rita", 5.0, "Feb 2026", "Principe Real is Lisbon's most beautiful neighborhood."), ("Mark", 4.9, "Jan 2026", "The tiles and balcony sunset were perfect.")])),
            Listing(id: "stay-lisbon-mouraria", title: "Mouraria fado quarter studio", location: "Lisbon, Portugal", price: 78, rating: 4.87, reviewCount: 289, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Air conditioning"],
                images: [image("Fado Street", "sf_stay_439", [UIColor(red:0.72,green:0.58,blue:0.45,alpha:1), UIColor(red:0.90,green:0.78,blue:0.65,alpha:1)]), image("Studio", "sf_stay_440", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Miradouro", "sf_stay_441", [UIColor(red:0.55,green:0.65,blue:0.78,alpha:1), UIColor(red:0.75,green:0.85,blue:0.92,alpha:1)])],
                host: hostNadia, description: "Budget studio in Mouraria, birthplace of fado, with multicultural food stalls, miradouro views, and live music drifting through the windows.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Joao", 4.9, "Jan 2026", "Mouraria is the real Lisbon. Fado from the street at night."), ("Sarah", 4.8, "Dec 2025", "Best value neighborhood with amazing character.")])),
            Listing(id: "stay-lisbon-santos", title: "Santos riverside loft", location: "Lisbon, Portugal", price: 112, rating: 4.88, reviewCount: 145, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Workspace", "Self check-in"],
                images: [image("River View", "sf_stay_442", [UIColor(red:0.42,green:0.58,blue:0.72,alpha:1), UIColor(red:0.62,green:0.78,blue:0.88,alpha:1)]), image("Loft", "sf_stay_443", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("LX Factory", "sf_stay_444", [UIColor(red:0.65,green:0.58,blue:0.50,alpha:1), UIColor(red:0.82,green:0.76,blue:0.68,alpha:1)])],
                host: hostSofia, description: "Industrial-chic loft near LX Factory with Tagus riverside walks, creative brunch spots, and Tram 28 rumbling past the door.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Miguel", 4.9, "Feb 2026", "LX Factory brunch was a daily ritual."), ("Kate", 4.8, "Jan 2026", "Great design and perfect riverside location.")])),
            // ── ADDITIONAL STAYS: BANGKOK ────────────────────────────────
            Listing(id: "stay-bangkok-silom", title: "Silom business district condo", location: "Bangkok, Thailand", price: 65, rating: 4.85, reviewCount: 312, beds: 1, baths: 1, guests: 2,
                categories: ["City"],
                amenities: ["Wifi", "Kitchen", "Pool", "Gym", "Air conditioning"],
                images: [image("Pool Deck", "sf_stay_445", [UIColor(red:0.35,green:0.62,blue:0.78,alpha:1), UIColor(red:0.55,green:0.82,blue:0.92,alpha:1)]), image("Condo Interior", "sf_stay_446", [UIColor(red:0.88,green:0.86,blue:0.82,alpha:1), UIColor(red:0.72,green:0.68,blue:0.64,alpha:1)]), image("Night Market", "sf_stay_447", [UIColor(red:0.75,green:0.55,blue:0.35,alpha:1), UIColor(red:0.90,green:0.72,blue:0.50,alpha:1)])],
                host: hostJade, description: "Modern condo in Silom with a rooftop pool, BTS access, Lumphini Park jogging, and Patpong night market street food.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Chai", 4.9, "Feb 2026", "The pool and BTS access make this unbeatable value."), ("Amy", 4.8, "Jan 2026", "So convenient for getting around Bangkok.")])),
            Listing(id: "stay-bangkok-ari", title: "Ari neighborhood townhouse", location: "Bangkok, Thailand", price: 88, rating: 4.92, reviewCount: 145, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Air conditioning", "Washer"],
                images: [image("Garden Patio", "sf_stay_448", [UIColor(red:0.42,green:0.58,blue:0.40,alpha:1), UIColor(red:0.62,green:0.78,blue:0.60,alpha:1)]), image("Living Room", "sf_stay_449", [UIColor(red:0.90,green:0.88,blue:0.82,alpha:1), UIColor(red:0.74,green:0.70,blue:0.64,alpha:1)]), image("Cafe Street", "sf_stay_450", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)])],
                host: hostRavi, description: "Charming townhouse in Ari, Bangkok's hipster neighborhood, with specialty coffee shops, vintage stores, and excellent local Thai food.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ploy", 5.0, "Jan 2026", "Ari is the best neighborhood in Bangkok. Period."), ("Sam", 4.9, "Dec 2025", "The townhouse garden was a peaceful escape from the city.")])),
            Listing(id: "stay-bangkok-chinatown", title: "Chinatown heritage shophouse", location: "Bangkok, Thailand", price: 52, rating: 4.86, reviewCount: 278, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Air conditioning", "Self check-in"],
                images: [image("Shophouse Front", "sf_stay_451", [UIColor(red:0.78,green:0.45,blue:0.32,alpha:1), UIColor(red:0.92,green:0.65,blue:0.48,alpha:1)]), image("Room", "sf_stay_452", [UIColor(red:0.86,green:0.82,blue:0.76,alpha:1), UIColor(red:0.70,green:0.65,blue:0.58,alpha:1)]), image("Street Food", "sf_stay_453", [UIColor(red:0.82,green:0.62,blue:0.35,alpha:1), UIColor(red:0.95,green:0.78,blue:0.50,alpha:1)])],
                host: hostJade, description: "Converted shophouse in Yaowarat with the best street food in Asia right outside, temple markets, and gold shop alleyways.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Nan", 4.9, "Feb 2026", "The street food at your doorstep is next level."), ("Will", 4.8, "Jan 2026", "Most authentic Bangkok experience possible.")])),
            // ── ADDITIONAL STAYS: SYDNEY ─────────────────────────────────
            Listing(id: "stay-sydney-manly", title: "Manly beachfront apartment", location: "Sydney, Australia", price: 195, rating: 4.91, reviewCount: 178, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Washer", "Balcony", "Parking"],
                images: [image("Beach View", "sf_stay_454", [UIColor(red:0.45,green:0.72,blue:0.85,alpha:1), UIColor(red:0.65,green:0.88,blue:0.95,alpha:1)]), image("Apartment", "sf_stay_455", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Coastal Walk", "sf_stay_456", [UIColor(red:0.35,green:0.55,blue:0.45,alpha:1), UIColor(red:0.55,green:0.75,blue:0.65,alpha:1)])],
                host: hostZara, description: "Sun-filled apartment steps from Manly Beach with the Spit to Manly coastal walk, ferry commute to the city, and fish and chips on the wharf.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jack", 4.9, "Feb 2026", "The ferry commute to work was the highlight of the trip."), ("Emma", 4.9, "Jan 2026", "Manly Beach life is addictive. Didn't want to leave.")])),
            Listing(id: "stay-sydney-newtown", title: "Newtown terrace house", location: "Sydney, Australia", price: 135, rating: 4.89, reviewCount: 198, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Garden", "Self check-in"],
                images: [image("Terrace Front", "sf_stay_457", [UIColor(red:0.65,green:0.55,blue:0.45,alpha:1), UIColor(red:0.82,green:0.74,blue:0.64,alpha:1)]), image("Living Room", "sf_stay_458", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("King Street", "sf_stay_459", [UIColor(red:0.55,green:0.50,blue:0.45,alpha:1), UIColor(red:0.75,green:0.70,blue:0.65,alpha:1)])],
                host: hostChen, description: "Victorian terrace in Newtown with King Street's Thai restaurants, vintage shops, live music pubs, and the best people-watching in Sydney.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Liam", 4.9, "Jan 2026", "Newtown is Sydney's coolest suburb. So much character."), ("Nina", 4.9, "Dec 2025", "King Street dining was endless and excellent.")])),
            Listing(id: "stay-sydney-glebe", title: "Glebe harbor-view studio", location: "Sydney, Australia", price: 108, rating: 4.86, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Harbor Glimpse", "sf_stay_460", [UIColor(red:0.42,green:0.58,blue:0.72,alpha:1), UIColor(red:0.62,green:0.78,blue:0.88,alpha:1)]), image("Studio", "sf_stay_461", [UIColor(red:0.86,green:0.82,blue:0.78,alpha:1), UIColor(red:0.70,green:0.66,blue:0.60,alpha:1)]), image("Market Day", "sf_stay_462", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)])],
                host: hostZara, description: "Affordable studio in leafy Glebe with Saturday markets, harbor foreshore walks, bookshops, and easy bus access to the CBD.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Oscar", 4.9, "Feb 2026", "Glebe markets on Saturday were a highlight."), ("Ava", 4.8, "Jan 2026", "Quiet, green, and still close to everything.")])),
            // ── ADDITIONAL STAYS: MEXICO CITY ────────────────────────────
            Listing(id: "stay-cdmx-juarez", title: "Juarez art deco apartment", location: "Mexico City, Mexico", price: 82, rating: 4.90, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in", "Washer"],
                images: [image("Art Deco Lobby", "sf_stay_463", [UIColor(red:0.78,green:0.68,blue:0.52,alpha:1), UIColor(red:0.92,green:0.84,blue:0.68,alpha:1)]), image("Apartment", "sf_stay_464", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Reforma Walk", "sf_stay_465", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostAmara, description: "Art deco apartment in Colonia Juarez near Reforma, craft mezcal bars, contemporary galleries, and the Zona Rosa energy.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Diego", 4.9, "Feb 2026", "The art deco details in this building are stunning."), ("Claire", 4.9, "Jan 2026", "Juarez is CDMX's most exciting neighborhood right now.")])),
            Listing(id: "stay-cdmx-coyoacan", title: "Coyoacan colonial house room", location: "Mexico City, Mexico", price: 58, rating: 4.93, reviewCount: 312, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Self check-in"],
                images: [image("Colonial Garden", "sf_stay_466", [UIColor(red:0.42,green:0.58,blue:0.38,alpha:1), UIColor(red:0.62,green:0.78,blue:0.58,alpha:1)]), image("Room", "sf_stay_467", [UIColor(red:0.88,green:0.82,blue:0.74,alpha:1), UIColor(red:0.72,green:0.66,blue:0.58,alpha:1)]), image("Frida Museum", "sf_stay_468", [UIColor(red:0.55,green:0.45,blue:0.65,alpha:1), UIColor(red:0.75,green:0.65,blue:0.82,alpha:1)])],
                host: hostDiego, description: "Room in a colonial house in Coyoacan near Frida Kahlo's Casa Azul, the central plaza, and churros con chocolate at El Moro.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ana", 5.0, "Mar 2026", "Coyoacan feels like a village inside the city. Magical."), ("Tom", 4.9, "Feb 2026", "Walking to Frida's house every morning was special.")])),
            Listing(id: "stay-cdmx-polanco", title: "Polanco luxury apartment", location: "Mexico City, Mexico", price: 165, rating: 4.88, reviewCount: 145, beds: 2, baths: 2, guests: 4,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Gym", "Doorman", "Air conditioning", "Washer"],
                images: [image("Modern Interior", "sf_stay_469", [UIColor(red:0.92,green:0.90,blue:0.86,alpha:1), UIColor(red:0.78,green:0.74,blue:0.70,alpha:1)]), image("Park View", "sf_stay_470", [UIColor(red:0.35,green:0.52,blue:0.38,alpha:1), UIColor(red:0.55,green:0.72,blue:0.58,alpha:1)]), image("Restaurant Row", "sf_stay_471", [UIColor(red:0.65,green:0.58,blue:0.50,alpha:1), UIColor(red:0.82,green:0.76,blue:0.68,alpha:1)])],
                host: hostAmara, description: "Upscale apartment in Polanco near Chapultepec Park, the Anthropology Museum, and some of Latin America's best fine dining.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Miguel", 4.9, "Jan 2026", "Polanco is Mexico City's most polished neighborhood."), ("Sophie", 4.8, "Dec 2025", "The Anthropology Museum alone made this location worth it.")])),
            // ── ADDITIONAL STAYS: MIAMI ──────────────────────────────────
            Listing(id: "stay-miami-design", title: "Design District modern condo", location: "Miami Beach, FL", price: 195, rating: 4.87, reviewCount: 167, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Pool", "Gym", "Air conditioning", "Parking"],
                images: [image("Pool Area", "sf_stay_472", [UIColor(red:0.35,green:0.68,blue:0.82,alpha:1), UIColor(red:0.55,green:0.85,blue:0.92,alpha:1)]), image("Modern Interior", "sf_stay_473", [UIColor(red:0.92,green:0.90,blue:0.86,alpha:1), UIColor(red:0.78,green:0.74,blue:0.70,alpha:1)]), image("Gallery Walk", "sf_stay_474", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)])],
                host: hostChen, description: "Sleek condo in the Design District with rooftop pool, contemporary galleries, luxury shopping, and some of Miami's best restaurants.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Alex", 4.9, "Feb 2026", "Design District is Miami's most interesting area."), ("Nina", 4.8, "Jan 2026", "The pool and nearby galleries were perfect.")])),
            Listing(id: "stay-miami-little-havana", title: "Little Havana casita", location: "Miami Beach, FL", price: 98, rating: 4.91, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in", "Patio"],
                images: [image("Colorful Casita", "sf_stay_475", [UIColor(red:0.82,green:0.55,blue:0.38,alpha:1), UIColor(red:0.95,green:0.72,blue:0.52,alpha:1)]), image("Patio", "sf_stay_476", [UIColor(red:0.42,green:0.58,blue:0.40,alpha:1), UIColor(red:0.62,green:0.78,blue:0.60,alpha:1)]), image("Calle Ocho", "sf_stay_477", [UIColor(red:0.72,green:0.58,blue:0.42,alpha:1), UIColor(red:0.90,green:0.78,blue:0.62,alpha:1)])],
                host: hostDiego, description: "Colorful casita on Calle Ocho with a private patio, Cuban coffee ventanitas, domino park, and the best Cuban sandwich in Miami.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Carmen", 5.0, "Feb 2026", "Felt like stepping into Havana. Incredible culture."), ("Josh", 4.9, "Jan 2026", "The Cuban coffee alone was worth the trip.")])),
            Listing(id: "stay-miami-coconut", title: "Coconut Grove waterfront villa", location: "Miami Beach, FL", price: 345, rating: 4.93, reviewCount: 67, beds: 4, baths: 3, guests: 8,
                categories: ["Beachfront", "Design", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Pool", "Parking", "Washer", "Garden"],
                images: [image("Waterfront", "sf_stay_478", [UIColor(red:0.30,green:0.62,blue:0.75,alpha:1), UIColor(red:0.50,green:0.82,blue:0.90,alpha:1)]), image("Villa Interior", "sf_stay_479", [UIColor(red:0.92,green:0.90,blue:0.86,alpha:1), UIColor(red:0.78,green:0.74,blue:0.70,alpha:1)]), image("Pool Deck", "sf_stay_480", [UIColor(red:0.42,green:0.68,blue:0.78,alpha:1), UIColor(red:0.62,green:0.85,blue:0.90,alpha:1)])],
                host: hostRina, description: "Bayfront villa in Coconut Grove with a pool, dock, lush tropical gardens, and the Grove's walkable village of cafes and boutiques.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("David", 5.0, "Mar 2026", "A private paradise in the middle of Miami."), ("Lisa", 4.9, "Feb 2026", "The pool and bay views were out of this world.")])),
            // ── ADDITIONAL STAYS: MID-TIER DESTINATIONS ──────────────────
            // Austin, TX
            Listing(id: "stay-austin-south", title: "South Congress bungalow", location: "Austin, TX", price: 165, rating: 4.91, reviewCount: 198, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite", "Trending"],
                amenities: ["Wifi", "Kitchen", "Patio", "Parking", "Self check-in"],
                images: [image("Bungalow Front", "sf_stay_481", [UIColor(red:0.62,green:0.55,blue:0.42,alpha:1), UIColor(red:0.80,green:0.74,blue:0.60,alpha:1)]), image("Patio", "sf_stay_482", [UIColor(red:0.45,green:0.58,blue:0.42,alpha:1), UIColor(red:0.65,green:0.78,blue:0.62,alpha:1)]), image("SoCo Strip", "sf_stay_483", [UIColor(red:0.72,green:0.62,blue:0.50,alpha:1), UIColor(red:0.90,green:0.82,blue:0.70,alpha:1)])],
                host: hostRavi, description: "Classic Austin bungalow on South Congress with a shaded patio, food truck access, live music venues, and the bat bridge at sunset.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jake", 4.9, "Feb 2026", "SoCo is the perfect Austin base. Walked everywhere."), ("Mia", 4.9, "Jan 2026", "The bungalow patio with morning coffee was heaven.")])),
            Listing(id: "stay-austin-rainey", title: "Rainey Street modern studio", location: "Austin, TX", price: 128, rating: 4.85, reviewCount: 267, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Pool", "Gym", "Air conditioning"],
                images: [image("Rooftop Pool", "sf_stay_484", [UIColor(red:0.38,green:0.65,blue:0.80,alpha:1), UIColor(red:0.58,green:0.82,blue:0.90,alpha:1)]), image("Studio", "sf_stay_485", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Bar District", "sf_stay_486", [UIColor(red:0.55,green:0.45,blue:0.38,alpha:1), UIColor(red:0.75,green:0.65,blue:0.58,alpha:1)])],
                host: hostLena, description: "Modern studio near Rainey Street's bar-house district with a rooftop pool, Lady Bird Lake trails, and downtown Austin steps away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Chris", 4.8, "Jan 2026", "Rainey Street nightlife plus morning lake runs. Perfect combo."), ("Zoe", 4.8, "Dec 2025", "Great pool and close to everything fun.")])),
            // Nashville, TN
            Listing(id: "stay-nashville-12south", title: "12 South cottage", location: "Nashville, TN", price: 155, rating: 4.92, reviewCount: 178, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Patio", "Parking", "Washer"],
                images: [image("Cottage", "sf_stay_487", [UIColor(red:0.72,green:0.68,blue:0.58,alpha:1), UIColor(red:0.90,green:0.86,blue:0.76,alpha:1)]), image("Porch", "sf_stay_488", [UIColor(red:0.52,green:0.60,blue:0.45,alpha:1), UIColor(red:0.72,green:0.80,blue:0.65,alpha:1)]), image("Mural Wall", "sf_stay_489", [UIColor(red:0.78,green:0.55,blue:0.62,alpha:1), UIColor(red:0.92,green:0.74,blue:0.80,alpha:1)])],
                host: hostIsla, description: "Cozy cottage in 12 South near the I Believe in Nashville mural, Draper James, boutique shopping, and excellent brunch spots.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Amy", 4.9, "Feb 2026", "12 South is Nashville's best neighborhood. Loved the cottage."), ("Ben", 4.9, "Jan 2026", "Front porch mornings were the highlight of our trip.")])),
            Listing(id: "stay-nashville-germantown", title: "Germantown loft", location: "Nashville, TN", price: 135, rating: 4.88, reviewCount: 212, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Kitchen", "Workspace", "Self check-in", "Washer"],
                images: [image("Industrial Loft", "sf_stay_490", [UIColor(red:0.82,green:0.76,blue:0.68,alpha:1), UIColor(red:0.65,green:0.58,blue:0.50,alpha:1)]), image("Farmers Market", "sf_stay_491", [UIColor(red:0.55,green:0.62,blue:0.48,alpha:1), UIColor(red:0.75,green:0.82,blue:0.68,alpha:1)]), image("Street View", "sf_stay_492", [UIColor(red:0.62,green:0.58,blue:0.52,alpha:1), UIColor(red:0.80,green:0.76,blue:0.70,alpha:1)])],
                host: hostRavi, description: "Converted warehouse loft in historic Germantown with the Nashville Farmers' Market, Bicentennial Park, and craft breweries nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Mark", 4.9, "Jan 2026", "Germantown has the best food scene in Nashville."), ("Sara", 4.8, "Dec 2025", "The loft was gorgeous and the farmers market was daily.")])),
            // New Orleans, LA
            Listing(id: "stay-nola-marigny", title: "Marigny shotgun house", location: "New Orleans, LA", price: 118, rating: 4.93, reviewCount: 234, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Patio", "Self check-in", "Washer"],
                images: [image("Shotgun House", "sf_stay_493", [UIColor(red:0.55,green:0.68,blue:0.52,alpha:1), UIColor(red:0.75,green:0.88,blue:0.72,alpha:1)]), image("Colorful Interior", "sf_stay_494", [UIColor(red:0.85,green:0.72,blue:0.55,alpha:1), UIColor(red:0.95,green:0.85,blue:0.70,alpha:1)]), image("Frenchmen Street", "sf_stay_495", [UIColor(red:0.30,green:0.25,blue:0.35,alpha:1), UIColor(red:0.52,green:0.45,blue:0.58,alpha:1)])],
                host: hostIsla, description: "Colorful shotgun house in the Marigny with Frenchmen Street jazz a block away, the best po'boys in town, and a quiet courtyard patio.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Louis", 5.0, "Feb 2026", "Frenchmen Street jazz every night from this perfect house."), ("Kate", 4.9, "Jan 2026", "The shotgun house architecture alone was worth it.")])),
            Listing(id: "stay-nola-warehouse", title: "Warehouse District loft", location: "New Orleans, LA", price: 175, rating: 4.87, reviewCount: 145, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Elevator", "Air conditioning", "Workspace"],
                images: [image("Warehouse Loft", "sf_stay_496", [UIColor(red:0.72,green:0.68,blue:0.60,alpha:1), UIColor(red:0.55,green:0.50,blue:0.42,alpha:1)]), image("Art District", "sf_stay_497", [UIColor(red:0.88,green:0.84,blue:0.78,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("River Walk", "sf_stay_498", [UIColor(red:0.42,green:0.55,blue:0.62,alpha:1), UIColor(red:0.62,green:0.75,blue:0.82,alpha:1)])],
                host: hostRavi, description: "Industrial loft in the Warehouse District near the WWII Museum, Julia Street galleries, and the Mississippi River walk.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Frank", 4.9, "Jan 2026", "The WWII Museum was steps away. Great loft space."), ("Diana", 4.8, "Dec 2025", "Warehouse District is the quieter, artier side of NOLA.")])),
            // Portland, OR
            Listing(id: "stay-portland-alberta", title: "Alberta Arts District house", location: "Portland, OR", price: 135, rating: 4.91, reviewCount: 198, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Parking", "Self check-in"],
                images: [image("Craftsman House", "sf_stay_499", [UIColor(red:0.55,green:0.60,blue:0.48,alpha:1), UIColor(red:0.75,green:0.80,blue:0.68,alpha:1)]), image("Garden", "sf_stay_500", [UIColor(red:0.42,green:0.58,blue:0.40,alpha:1), UIColor(red:0.62,green:0.78,blue:0.60,alpha:1)]), image("Art Walk", "sf_stay_501", [UIColor(red:0.70,green:0.58,blue:0.48,alpha:1), UIColor(red:0.88,green:0.78,blue:0.68,alpha:1)])],
                host: hostLena, description: "Craftsman house on Alberta Street with galleries, food carts, craft beer, and Last Thursday art walks in the summer.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Emma", 4.9, "Feb 2026", "Alberta is Portland at its best. Loved this house."), ("Jason", 4.9, "Jan 2026", "The garden and neighborhood walks were perfect.")])),
            Listing(id: "stay-portland-hawthorne", title: "Hawthorne vintage apartment", location: "Portland, OR", price: 98, rating: 4.88, reviewCount: 267, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Washer"],
                images: [image("Vintage Interior", "sf_stay_502", [UIColor(red:0.78,green:0.72,blue:0.62,alpha:1), UIColor(red:0.62,green:0.55,blue:0.45,alpha:1)]), image("Bookstore", "sf_stay_503", [UIColor(red:0.65,green:0.58,blue:0.50,alpha:1), UIColor(red:0.82,green:0.76,blue:0.68,alpha:1)]), image("Food Carts", "sf_stay_504", [UIColor(red:0.72,green:0.62,blue:0.48,alpha:1), UIColor(red:0.90,green:0.82,blue:0.68,alpha:1)])],
                host: hostChen, description: "Cozy apartment on Hawthorne Boulevard with Powell's Books, vintage shops, food cart pods, and Mt. Tabor park hikes.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Alex", 4.9, "Jan 2026", "Hawthorne is quintessential Portland. Perfect base."), ("Sam", 4.8, "Dec 2025", "Great vintage shops and food carts everywhere.")])),
            Listing(id: "stay-portland-pearl", title: "Pearl District modern loft", location: "Portland, OR", price: 165, rating: 4.86, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Gym", "Elevator", "Workspace"],
                images: [image("Loft Interior", "sf_stay_505", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Gallery Row", "sf_stay_506", [UIColor(red:0.62,green:0.58,blue:0.52,alpha:1), UIColor(red:0.80,green:0.76,blue:0.70,alpha:1)]), image("Waterfront Park", "sf_stay_507", [UIColor(red:0.40,green:0.55,blue:0.48,alpha:1), UIColor(red:0.60,green:0.75,blue:0.68,alpha:1)])],
                host: hostLena, description: "Modern loft in the Pearl District with art galleries, Powell's flagship bookstore, waterfront walks, and Portland's best restaurants.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Nina", 4.9, "Feb 2026", "Pearl District is walkable, clean, and full of great food."), ("Dan", 4.8, "Jan 2026", "Loved the loft design and gallery hopping.")])),
            // Kyoto, Japan
            Listing(id: "stay-kyoto-gion", title: "Gion traditional machiya", location: "Kyoto, Japan", price: 195, rating: 4.96, reviewCount: 112, beds: 2, baths: 1, guests: 4,
                categories: ["Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Self check-in"],
                images: [image("Machiya Entrance", "sf_stay_508", [UIColor(red:0.55,green:0.48,blue:0.40,alpha:1), UIColor(red:0.75,green:0.68,blue:0.60,alpha:1)]), image("Courtyard Garden", "sf_stay_509", [UIColor(red:0.38,green:0.52,blue:0.35,alpha:1), UIColor(red:0.58,green:0.72,blue:0.55,alpha:1)]), image("Geisha District", "sf_stay_510", [UIColor(red:0.62,green:0.55,blue:0.48,alpha:1), UIColor(red:0.80,green:0.74,blue:0.68,alpha:1)])],
                host: hostHiro, description: "Restored machiya in the Gion geisha district with a tsuboniwa courtyard, tatami bedrooms, and lantern-lit streets at dusk.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Yuki", 5.0, "Mar 2026", "Staying in a machiya in Gion was a dream come true."), ("Sarah", 4.9, "Feb 2026", "Spotted geiko walking past the house at twilight. Magical.")])),
            Listing(id: "stay-kyoto-higashiyama", title: "Higashiyama temple district room", location: "Kyoto, Japan", price: 115, rating: 4.90, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Air conditioning"],
                images: [image("Temple Path", "sf_stay_511", [UIColor(red:0.45,green:0.55,blue:0.40,alpha:1), UIColor(red:0.65,green:0.75,blue:0.60,alpha:1)]), image("Room", "sf_stay_512", [UIColor(red:0.86,green:0.82,blue:0.76,alpha:1), UIColor(red:0.70,green:0.66,blue:0.58,alpha:1)]), image("Kiyomizu View", "sf_stay_513", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostKenji, description: "Simple room near Kiyomizu-dera with the Philosopher's Path, morning temple visits before the crowds, and matcha shops on every corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Tom", 4.9, "Feb 2026", "Walking to temples at dawn was the best part."), ("Mei", 4.9, "Jan 2026", "Higashiyama is the most beautiful part of Kyoto.")])),
            // Tulum, Mexico
            Listing(id: "stay-tulum-pueblo", title: "Tulum pueblo town studio", location: "Tulum, Mexico", price: 55, rating: 4.87, reviewCount: 312, beds: 1, baths: 1, guests: 2,
                categories: ["Tropical", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in", "Bikes"],
                images: [image("Town Studio", "sf_stay_514", [UIColor(red:0.88,green:0.85,blue:0.78,alpha:1), UIColor(red:0.72,green:0.68,blue:0.60,alpha:1)]), image("Taco Stand", "sf_stay_515", [UIColor(red:0.78,green:0.58,blue:0.38,alpha:1), UIColor(red:0.92,green:0.75,blue:0.55,alpha:1)]), image("Bike Path", "sf_stay_516", [UIColor(red:0.42,green:0.58,blue:0.42,alpha:1), UIColor(red:0.62,green:0.78,blue:0.62,alpha:1)])],
                host: hostDiego, description: "Budget studio in Tulum town with authentic taco stands, loaner bikes to the beach, and none of the hotel-zone markup.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ana", 4.9, "Feb 2026", "Town is the real Tulum. Way better value than the strip."), ("Will", 4.8, "Jan 2026", "Biked to the beach every day. Perfect setup.")])),
            Listing(id: "stay-tulum-cenote", title: "Cenote-side eco cabin", location: "Tulum, Mexico", price: 145, rating: 4.94, reviewCount: 89, beds: 1, baths: 1, guests: 2,
                categories: ["Tropical", "Guest favorite", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Pool", "Garden"],
                images: [image("Jungle Cabin", "sf_stay_517", [UIColor(red:0.35,green:0.52,blue:0.35,alpha:1), UIColor(red:0.55,green:0.72,blue:0.55,alpha:1)]), image("Cenote Pool", "sf_stay_518", [UIColor(red:0.28,green:0.58,blue:0.65,alpha:1), UIColor(red:0.48,green:0.78,blue:0.82,alpha:1)]), image("Eco Interior", "sf_stay_519", [UIColor(red:0.82,green:0.78,blue:0.68,alpha:1), UIColor(red:0.65,green:0.60,blue:0.50,alpha:1)])],
                host: hostAmara, description: "Eco cabin near a private cenote with jungle surroundings, an outdoor shower, stargazing from the deck, and ruins a bike ride away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Luna", 5.0, "Mar 2026", "Swimming in the cenote at sunrise was spiritual."), ("Rob", 4.9, "Feb 2026", "Most unique place I have ever stayed.")])),
            // Cape Town, South Africa
            Listing(id: "stay-capetown-woodstock", title: "Woodstock creative quarter flat", location: "Cape Town, South Africa", price: 68, rating: 4.88, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Street Art", "sf_stay_520", [UIColor(red:0.72,green:0.55,blue:0.45,alpha:1), UIColor(red:0.90,green:0.75,blue:0.62,alpha:1)]), image("Flat", "sf_stay_521", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Biscuit Mill", "sf_stay_522", [UIColor(red:0.62,green:0.55,blue:0.48,alpha:1), UIColor(red:0.80,green:0.74,blue:0.66,alpha:1)])],
                host: hostZara, description: "Flat in Woodstock's creative quarter with Old Biscuit Mill markets, street art tours, craft breweries, and Table Mountain views.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Thabo", 4.9, "Feb 2026", "Woodstock is Cape Town's most exciting neighborhood."), ("Kate", 4.8, "Jan 2026", "Biscuit Mill Saturdays were incredible.")])),
            Listing(id: "stay-capetown-gardens", title: "Gardens district Victorian flat", location: "Cape Town, South Africa", price: 95, rating: 4.90, reviewCount: 167, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in", "Garden"],
                images: [image("Victorian Facade", "sf_stay_523", [UIColor(red:0.65,green:0.58,blue:0.48,alpha:1), UIColor(red:0.82,green:0.76,blue:0.66,alpha:1)]), image("Interior", "sf_stay_524", [UIColor(red:0.90,green:0.86,blue:0.80,alpha:1), UIColor(red:0.74,green:0.68,blue:0.62,alpha:1)]), image("Company Garden", "sf_stay_525", [UIColor(red:0.38,green:0.55,blue:0.38,alpha:1), UIColor(red:0.58,green:0.75,blue:0.58,alpha:1)])],
                host: hostZara, description: "Victorian flat in Gardens near the Company's Garden, Kloof Street restaurants, and the Table Mountain cable car base station.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("James", 4.9, "Jan 2026", "Kloof Street dining was phenomenal every night."), ("Nia", 4.9, "Dec 2025", "Perfect base for Table Mountain and the city bowl.")])),
            // ── ADDITIONAL STAYS: NICHE DESTINATIONS ─────────────────────
            // Joshua Tree, CA
            Listing(id: "stay-joshua-dome", title: "Joshua Tree desert dome", location: "Joshua Tree, CA", price: 175, rating: 4.94, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["Amazing views", "Trending", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Hot tub", "Stargazing deck", "Parking"],
                images: [image("Dome Exterior", "sf_stay_526", [UIColor(red:0.85,green:0.75,blue:0.58,alpha:1), UIColor(red:0.95,green:0.88,blue:0.72,alpha:1)]), image("Interior", "sf_stay_527", [UIColor(red:0.90,green:0.86,blue:0.80,alpha:1), UIColor(red:0.74,green:0.68,blue:0.62,alpha:1)]), image("Desert Stars", "sf_stay_528", [UIColor(red:0.15,green:0.12,blue:0.22,alpha:1), UIColor(red:0.35,green:0.30,blue:0.45,alpha:1)])],
                host: hostRina, description: "Geodesic dome with panoramic desert views, a hot tub under the stars, and Joshua Tree National Park minutes away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Zoe", 5.0, "Feb 2026", "Stargazing from the hot tub was life-changing."), ("Mark", 4.9, "Jan 2026", "Most unique place I have ever stayed. Incredible.")])),
            Listing(id: "stay-joshua-hacienda", title: "High desert hacienda", location: "Joshua Tree, CA", price: 225, rating: 4.92, reviewCount: 98, beds: 3, baths: 2, guests: 6,
                categories: ["Amazing views", "Design"],
                amenities: ["Wifi", "Kitchen", "Pool", "Hot tub", "Parking", "Fire pit"],
                images: [image("Hacienda", "sf_stay_529", [UIColor(red:0.82,green:0.72,blue:0.55,alpha:1), UIColor(red:0.94,green:0.86,blue:0.70,alpha:1)]), image("Pool Sunset", "sf_stay_530", [UIColor(red:0.85,green:0.55,blue:0.35,alpha:1), UIColor(red:0.95,green:0.72,blue:0.50,alpha:1)]), image("Fire Pit Night", "sf_stay_531", [UIColor(red:0.30,green:0.22,blue:0.18,alpha:1), UIColor(red:0.55,green:0.42,blue:0.35,alpha:1)])],
                host: hostChen, description: "Sprawling desert hacienda with a pool, fire pit, unobstructed sunset views, and the quiet emptiness of the Mojave all around.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Laura", 4.9, "Mar 2026", "The pool and desert sunset were out of a movie."), ("James", 4.9, "Feb 2026", "Fire pit under the Milky Way. No words.")])),
            // Santorini, Greece
            Listing(id: "stay-santorini-oia", title: "Oia caldera cave suite", location: "Santorini, Greece", price: 325, rating: 4.96, reviewCount: 87, beds: 1, baths: 1, guests: 2,
                categories: ["Amazing views", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Pool", "Air conditioning", "Terrace"],
                images: [image("Caldera View", "sf_stay_532", [UIColor(red:0.35,green:0.55,blue:0.82,alpha:1), UIColor(red:0.55,green:0.75,blue:0.92,alpha:1)]), image("Cave Interior", "sf_stay_533", [UIColor(red:0.92,green:0.90,blue:0.88,alpha:1), UIColor(red:0.78,green:0.76,blue:0.74,alpha:1)]), image("Sunset Terrace", "sf_stay_534", [UIColor(red:0.88,green:0.58,blue:0.35,alpha:1), UIColor(red:0.98,green:0.75,blue:0.50,alpha:1)])],
                host: hostSofia, description: "Whitewashed cave suite carved into the Oia caldera with a plunge pool, sunset terrace, and the most photographed view in Greece.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Elena", 5.0, "Mar 2026", "The sunset from the terrace was the best moment of my life."), ("Tom", 5.0, "Feb 2026", "Worth every penny. A once-in-a-lifetime stay.")])),
            Listing(id: "stay-santorini-fira", title: "Fira cliffside apartment", location: "Santorini, Greece", price: 165, rating: 4.89, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["Amazing views", "City"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Balcony"],
                images: [image("Cliffside View", "sf_stay_535", [UIColor(red:0.40,green:0.60,blue:0.80,alpha:1), UIColor(red:0.60,green:0.80,blue:0.92,alpha:1)]), image("White Interior", "sf_stay_536", [UIColor(red:0.94,green:0.92,blue:0.90,alpha:1), UIColor(red:0.80,green:0.78,blue:0.76,alpha:1)]), image("Donkey Path", "sf_stay_537", [UIColor(red:0.72,green:0.68,blue:0.62,alpha:1), UIColor(red:0.88,green:0.84,blue:0.78,alpha:1)])],
                host: hostMateo, description: "Cliffside apartment in Fira with caldera views, walkable tavernas, the cable car, and more affordable than Oia with the same sunset.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Maria", 4.9, "Feb 2026", "Same stunning views as Oia at a better price."), ("Jack", 4.9, "Jan 2026", "Fira is the better base for exploring the island.")])),
            // Marrakech, Morocco
            Listing(id: "stay-marrakech-riad", title: "Medina traditional riad", location: "Marrakech, Morocco", price: 95, rating: 4.95, reviewCount: 234, beds: 2, baths: 1, guests: 4,
                categories: ["Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Pool", "Terrace", "Air conditioning"],
                images: [image("Riad Courtyard", "sf_stay_538", [UIColor(red:0.82,green:0.62,blue:0.38,alpha:1), UIColor(red:0.95,green:0.78,blue:0.55,alpha:1)]), image("Tiled Room", "sf_stay_539", [UIColor(red:0.45,green:0.55,blue:0.72,alpha:1), UIColor(red:0.65,green:0.75,blue:0.88,alpha:1)]), image("Rooftop View", "sf_stay_540", [UIColor(red:0.85,green:0.68,blue:0.48,alpha:1), UIColor(red:0.95,green:0.82,blue:0.62,alpha:1)])],
                host: hostOmar, description: "Traditional riad with a courtyard plunge pool, zellige tiles, a rooftop terrace with Atlas Mountain views, and Jemaa el-Fnaa steps away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Fatima", 5.0, "Feb 2026", "The riad courtyard was an oasis in the medina chaos."), ("Ben", 4.9, "Jan 2026", "Most beautiful tile work I have ever seen.")])),
            Listing(id: "stay-marrakech-gueliz", title: "Gueliz modern apartment", location: "Marrakech, Morocco", price: 65, rating: 4.86, reviewCount: 178, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in", "Washer"],
                images: [image("Modern Interior", "sf_stay_541", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Cafe Culture", "sf_stay_542", [UIColor(red:0.72,green:0.62,blue:0.50,alpha:1), UIColor(red:0.90,green:0.82,blue:0.70,alpha:1)]), image("Jardin Majorelle", "sf_stay_543", [UIColor(red:0.30,green:0.50,blue:0.62,alpha:1), UIColor(red:0.50,green:0.70,blue:0.82,alpha:1)])],
                host: hostOmar, description: "Modern apartment in Gueliz's new city near Jardin Majorelle, French-Moroccan cafes, and a calmer pace than the medina.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Sara", 4.9, "Jan 2026", "Gueliz is the perfect base if the medina feels intense."), ("Chris", 4.8, "Dec 2025", "Loved the cafe culture and Majorelle Garden.")])),
            // Copenhagen, Denmark
            Listing(id: "stay-copenhagen-norrebro", title: "Norrebro neighborhood flat", location: "Copenhagen, Denmark", price: 145, rating: 4.90, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in", "Bikes"],
                images: [image("Canal Side", "sf_stay_544", [UIColor(red:0.45,green:0.58,blue:0.65,alpha:1), UIColor(red:0.65,green:0.78,blue:0.85,alpha:1)]), image("Scandi Interior", "sf_stay_545", [UIColor(red:0.92,green:0.90,blue:0.88,alpha:1), UIColor(red:0.78,green:0.76,blue:0.74,alpha:1)]), image("Superkilen Park", "sf_stay_546", [UIColor(red:0.55,green:0.48,blue:0.55,alpha:1), UIColor(red:0.75,green:0.68,blue:0.75,alpha:1)])],
                host: hostElsa, description: "Scandi-minimal flat in Norrebro with Superkilen park, craft coffee, natural wine bars, and the city's most diverse food scene.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lars", 4.9, "Feb 2026", "Norrebro is Copenhagen's most exciting neighborhood."), ("Amy", 4.9, "Jan 2026", "Loaner bikes were perfect for getting around.")])),
            Listing(id: "stay-copenhagen-vesterbro", title: "Vesterbro design studio", location: "Copenhagen, Denmark", price: 128, rating: 4.88, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Design Studio", "sf_stay_547", [UIColor(red:0.88,green:0.86,blue:0.82,alpha:1), UIColor(red:0.72,green:0.68,blue:0.64,alpha:1)]), image("Meatpacking", "sf_stay_548", [UIColor(red:0.55,green:0.50,blue:0.45,alpha:1), UIColor(red:0.75,green:0.70,blue:0.65,alpha:1)]), image("Street Scene", "sf_stay_549", [UIColor(red:0.62,green:0.58,blue:0.52,alpha:1), UIColor(red:0.80,green:0.76,blue:0.70,alpha:1)])],
                host: hostElsa, description: "Danish design studio in Vesterbro near the Meatpacking District, Tivoli Gardens, and Copenhagen's best cocktail bars.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Mads", 4.9, "Jan 2026", "Vesterbro has the best nightlife in Copenhagen."), ("Chloe", 4.8, "Dec 2025", "Perfectly designed space. Very hygge.")])),
            // Dubrovnik, Croatia
            Listing(id: "stay-dubrovnik-old", title: "Old Town stone apartment", location: "Dubrovnik, Croatia", price: 165, rating: 4.93, reviewCount: 145, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in"],
                images: [image("City Walls", "sf_stay_550", [UIColor(red:0.72,green:0.62,blue:0.50,alpha:1), UIColor(red:0.90,green:0.82,blue:0.70,alpha:1)]), image("Stone Interior", "sf_stay_551", [UIColor(red:0.86,green:0.82,blue:0.76,alpha:1), UIColor(red:0.70,green:0.66,blue:0.60,alpha:1)]), image("Adriatic View", "sf_stay_552", [UIColor(red:0.35,green:0.58,blue:0.78,alpha:1), UIColor(red:0.55,green:0.78,blue:0.92,alpha:1)])],
                host: hostMateo, description: "Stone apartment inside the old city walls with Adriatic views, the Stradun at your door, and cliff bar swimming nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Luka", 5.0, "Feb 2026", "Living inside the walls was a fairy tale."), ("Emma", 4.9, "Jan 2026", "The cliff bar and old town walks were unforgettable.")])),
            Listing(id: "stay-dubrovnik-lapad", title: "Lapad seaside villa", location: "Dubrovnik, Croatia", price: 225, rating: 4.90, reviewCount: 87, beds: 3, baths: 2, guests: 6,
                categories: ["Beachfront", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Pool", "Terrace", "Parking"],
                images: [image("Villa Terrace", "sf_stay_553", [UIColor(red:0.42,green:0.65,blue:0.80,alpha:1), UIColor(red:0.62,green:0.85,blue:0.92,alpha:1)]), image("Pool", "sf_stay_554", [UIColor(red:0.38,green:0.68,blue:0.78,alpha:1), UIColor(red:0.58,green:0.85,blue:0.90,alpha:1)]), image("Sunset Bay", "sf_stay_555", [UIColor(red:0.85,green:0.58,blue:0.38,alpha:1), UIColor(red:0.95,green:0.75,blue:0.52,alpha:1)])],
                host: hostSofia, description: "Seaside villa in Lapad with a pool, Adriatic terrace, pine-shaded beaches, and a water taxi to the old town.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Marco", 4.9, "Mar 2026", "The pool and Adriatic views were paradise."), ("Julia", 4.9, "Feb 2026", "Lapad is perfect if you want beach and old town access.")])),
            // Hong Kong
            Listing(id: "stay-hk-sheung-wan", title: "Sheung Wan art district flat", location: "Hong Kong", price: 135, rating: 4.88, reviewCount: 198, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Elevator", "Self check-in"],
                images: [image("Street Scene", "sf_stay_556", [UIColor(red:0.72,green:0.58,blue:0.45,alpha:1), UIColor(red:0.90,green:0.78,blue:0.65,alpha:1)]), image("Flat", "sf_stay_557", [UIColor(red:0.88,green:0.86,blue:0.82,alpha:1), UIColor(red:0.72,green:0.68,blue:0.64,alpha:1)]), image("Temple Walk", "sf_stay_558", [UIColor(red:0.55,green:0.48,blue:0.42,alpha:1), UIColor(red:0.75,green:0.68,blue:0.62,alpha:1)])],
                host: hostChen, description: "Flat in Sheung Wan's gallery district with dried seafood streets, Man Mo Temple, PMQ design market, and the Mid-Levels escalator.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Mei", 4.9, "Feb 2026", "Sheung Wan is the coolest part of Hong Kong."), ("David", 4.8, "Jan 2026", "Great art scene and incredible food nearby.")])),
            Listing(id: "stay-hk-sai-kung", title: "Sai Kung waterfront house", location: "Hong Kong", price: 195, rating: 4.92, reviewCount: 78, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Parking", "Washer"],
                images: [image("Waterfront", "sf_stay_559", [UIColor(red:0.38,green:0.62,blue:0.78,alpha:1), UIColor(red:0.58,green:0.82,blue:0.90,alpha:1)]), image("House", "sf_stay_560", [UIColor(red:0.86,green:0.82,blue:0.76,alpha:1), UIColor(red:0.70,green:0.66,blue:0.60,alpha:1)]), image("Fishing Village", "sf_stay_561", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostChen, description: "Waterfront house in Sai Kung fishing village with seafood restaurants, island-hopping boat trips, and hiking trails into the geopark.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jason", 4.9, "Jan 2026", "Sai Kung is Hong Kong's hidden gem. Incredible seafood."), ("Amy", 4.9, "Dec 2025", "Felt like a different world from the city.")])),
            // Singapore
            Listing(id: "stay-singapore-kampong", title: "Kampong Glam heritage room", location: "Singapore", price: 115, rating: 4.89, reviewCount: 189, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Trending"],
                amenities: ["Wifi", "Air conditioning", "Self check-in"],
                images: [image("Shophouse Front", "sf_stay_562", [UIColor(red:0.78,green:0.55,blue:0.40,alpha:1), UIColor(red:0.92,green:0.72,blue:0.55,alpha:1)]), image("Room", "sf_stay_563", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Haji Lane", "sf_stay_564", [UIColor(red:0.65,green:0.55,blue:0.68,alpha:1), UIColor(red:0.82,green:0.72,blue:0.85,alpha:1)])],
                host: hostRavi, description: "Heritage shophouse room in Kampong Glam near Haji Lane boutiques, Arab Street, Sultan Mosque, and the best nasi lemak in Singapore.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Wei", 4.9, "Feb 2026", "Kampong Glam has so much character. Loved it."), ("Tom", 4.9, "Jan 2026", "Haji Lane shopping and Arab Street food were highlights.")])),
            Listing(id: "stay-singapore-joo-chiat", title: "Joo Chiat Peranakan flat", location: "Singapore", price: 98, rating: 4.91, reviewCount: 156, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in", "Washer"],
                images: [image("Peranakan Tiles", "sf_stay_565", [UIColor(red:0.45,green:0.65,blue:0.55,alpha:1), UIColor(red:0.65,green:0.82,blue:0.72,alpha:1)]), image("Flat Interior", "sf_stay_566", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Katong Laksa", "sf_stay_567", [UIColor(red:0.78,green:0.58,blue:0.38,alpha:1), UIColor(red:0.92,green:0.75,blue:0.55,alpha:1)])],
                host: hostRavi, description: "Flat in a Peranakan shophouse on Joo Chiat Road with the best laksa in Singapore, colorful facades, and Katong heritage nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Lin", 5.0, "Jan 2026", "Joo Chiat is Singapore's most photogenic neighborhood."), ("Sarah", 4.9, "Dec 2025", "The Peranakan architecture was stunning.")])),
            // Reykjavik, Iceland
            Listing(id: "stay-reykjavik-old", title: "Old Reykjavik colorful apartment", location: "Reykjavik, Iceland", price: 175, rating: 4.90, reviewCount: 145, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in"],
                images: [image("Colorful Street", "sf_stay_568", [UIColor(red:0.55,green:0.65,blue:0.78,alpha:1), UIColor(red:0.75,green:0.82,blue:0.92,alpha:1)]), image("Cozy Interior", "sf_stay_569", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Hallgrimskirkja", "sf_stay_570", [UIColor(red:0.62,green:0.60,blue:0.58,alpha:1), UIColor(red:0.80,green:0.78,blue:0.76,alpha:1)])],
                host: hostElsa, description: "Colorful apartment on Laugavegur with Hallgrimskirkja views, craft beer bars, hot dog stands, and northern lights from the rooftop.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Bjorn", 4.9, "Feb 2026", "Walking distance to everything in Reykjavik."), ("Kate", 4.9, "Jan 2026", "Saw the northern lights from the rooftop. Incredible.")])),
            Listing(id: "stay-reykjavik-harbour", title: "Old Harbour waterfront studio", location: "Reykjavik, Iceland", price: 155, rating: 4.87, reviewCount: 178, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Harbour View", "sf_stay_571", [UIColor(red:0.40,green:0.52,blue:0.62,alpha:1), UIColor(red:0.60,green:0.72,blue:0.82,alpha:1)]), image("Studio", "sf_stay_572", [UIColor(red:0.86,green:0.84,blue:0.80,alpha:1), UIColor(red:0.70,green:0.68,blue:0.64,alpha:1)]), image("Whale Watching", "sf_stay_573", [UIColor(red:0.35,green:0.50,blue:0.60,alpha:1), UIColor(red:0.55,green:0.70,blue:0.80,alpha:1)])],
                host: hostElsa, description: "Waterfront studio in the Old Harbour with whale watching boats, Grandi food hall, and Harpa concert hall lit up at night.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Erik", 4.9, "Jan 2026", "Harbour views and the Grandi food hall were daily joys."), ("Lisa", 4.8, "Dec 2025", "Perfect base for Golden Circle day trips.")])),
            // Bali additions (Ubud + Canggu)
            Listing(id: "stay-ubud-terrace", title: "Ubud rice terrace villa", location: "Ubud, Bali", price: 85, rating: 4.95, reviewCount: 267, beds: 2, baths: 1, guests: 4,
                categories: ["Tropical", "Amazing views", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Pool", "Garden", "Self check-in"],
                images: [image("Rice Terraces", "sf_stay_574", [UIColor(red:0.35,green:0.58,blue:0.32,alpha:1), UIColor(red:0.55,green:0.78,blue:0.52,alpha:1)]), image("Villa Pool", "sf_stay_575", [UIColor(red:0.38,green:0.65,blue:0.72,alpha:1), UIColor(red:0.58,green:0.85,blue:0.88,alpha:1)]), image("Jungle View", "sf_stay_576", [UIColor(red:0.30,green:0.50,blue:0.30,alpha:1), UIColor(red:0.50,green:0.70,blue:0.50,alpha:1)])],
                host: hostJade, description: "Open-air villa overlooking Tegallalang rice terraces with a private pool, jungle sounds, morning yoga, and Ubud's art galleries nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Maya", 5.0, "Feb 2026", "Waking up to rice terrace views was paradise."), ("Dan", 4.9, "Jan 2026", "The pool overlooking the jungle was surreal.")])),
            Listing(id: "stay-canggu-surf", title: "Canggu surf villa", location: "Canggu, Bali", price: 72, rating: 4.88, reviewCount: 312, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "Trending", "Tropical"],
                amenities: ["Wifi", "Kitchen", "Pool", "Surfboard storage", "Self check-in"],
                images: [image("Surf Break", "sf_stay_577", [UIColor(red:0.42,green:0.68,blue:0.80,alpha:1), UIColor(red:0.62,green:0.85,blue:0.90,alpha:1)]), image("Villa", "sf_stay_578", [UIColor(red:0.82,green:0.78,blue:0.68,alpha:1), UIColor(red:0.65,green:0.60,blue:0.50,alpha:1)]), image("Beach Club", "sf_stay_579", [UIColor(red:0.85,green:0.70,blue:0.48,alpha:1), UIColor(red:0.95,green:0.82,blue:0.62,alpha:1)])],
                host: hostRavi, description: "Surf villa near Echo Beach with board storage, a pool, acai bowl cafes, co-working spaces, and Canggu's legendary sunset beach clubs.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Surfer Joe", 4.9, "Feb 2026", "Surfed Echo Beach every morning. Dream setup."), ("Nina", 4.8, "Jan 2026", "Canggu vibes are unmatched. Great villa.")])),
            // Napa Valley, CA
            Listing(id: "stay-napa-vineyard", title: "Vineyard cottage", location: "Napa Valley, CA", price: 275, rating: 4.94, reviewCount: 98, beds: 2, baths: 1, guests: 4,
                categories: ["Countryside", "Guest favorite", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Hot tub", "Parking", "Fire pit"],
                images: [image("Vineyard View", "sf_stay_580", [UIColor(red:0.45,green:0.55,blue:0.35,alpha:1), UIColor(red:0.65,green:0.75,blue:0.55,alpha:1)]), image("Cottage Interior", "sf_stay_581", [UIColor(red:0.90,green:0.86,blue:0.78,alpha:1), UIColor(red:0.74,green:0.68,blue:0.60,alpha:1)]), image("Wine Tasting", "sf_stay_582", [UIColor(red:0.65,green:0.50,blue:0.38,alpha:1), UIColor(red:0.82,green:0.70,blue:0.55,alpha:1)])],
                host: hostRina, description: "Stone cottage among the vines with a hot tub, fire pit, vineyard walking paths, and a complimentary bottle of estate cabernet.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Karen", 5.0, "Mar 2026", "Hot tub among the vines at sunset. Perfection."), ("Steve", 4.9, "Feb 2026", "Most romantic getaway we have ever had.")])),
            Listing(id: "stay-napa-downtown", title: "Downtown Napa walkable flat", location: "Napa Valley, CA", price: 165, rating: 4.87, reviewCount: 167, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Washer"],
                images: [image("Downtown", "sf_stay_583", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)]), image("Flat", "sf_stay_584", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Oxbow Market", "sf_stay_585", [UIColor(red:0.62,green:0.55,blue:0.48,alpha:1), UIColor(red:0.80,green:0.74,blue:0.66,alpha:1)])],
                host: hostLena, description: "Walkable flat in downtown Napa near Oxbow Public Market, tasting rooms, the Napa River trail, and Michelin-starred restaurants.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Rachel", 4.9, "Feb 2026", "Oxbow Market every morning was incredible."), ("Tom", 4.8, "Jan 2026", "Walking to tasting rooms was the way to do Napa.")])),
            // Santa Fe, NM
            Listing(id: "stay-santafe-canyon", title: "Canyon Road adobe casita", location: "Santa Fe, NM", price: 185, rating: 4.93, reviewCount: 134, beds: 1, baths: 1, guests: 2,
                categories: ["Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Fire pit", "Parking", "Self check-in"],
                images: [image("Adobe Exterior", "sf_stay_586", [UIColor(red:0.78,green:0.62,blue:0.45,alpha:1), UIColor(red:0.92,green:0.78,blue:0.60,alpha:1)]), image("Kiva Fireplace", "sf_stay_587", [UIColor(red:0.85,green:0.72,blue:0.55,alpha:1), UIColor(red:0.70,green:0.55,blue:0.40,alpha:1)]), image("Gallery Row", "sf_stay_588", [UIColor(red:0.62,green:0.55,blue:0.48,alpha:1), UIColor(red:0.80,green:0.74,blue:0.66,alpha:1)])],
                host: hostAmara, description: "Adobe casita on Canyon Road with a kiva fireplace, gallery-hopping from the front door, and desert sunsets from the private patio.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Maria", 5.0, "Feb 2026", "The kiva fireplace and Canyon Road galleries were magical."), ("James", 4.9, "Jan 2026", "Santa Fe sunsets from the patio were breathtaking.")])),
            Listing(id: "stay-santafe-railyard", title: "Railyard District modern studio", location: "Santa Fe, NM", price: 125, rating: 4.86, reviewCount: 178, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Railyard", "sf_stay_589", [UIColor(red:0.72,green:0.68,blue:0.60,alpha:1), UIColor(red:0.55,green:0.50,blue:0.42,alpha:1)]), image("Studio", "sf_stay_590", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Farmers Market", "sf_stay_591", [UIColor(red:0.55,green:0.58,blue:0.45,alpha:1), UIColor(red:0.75,green:0.78,blue:0.65,alpha:1)])],
                host: hostAmara, description: "Modern studio near the Railyard arts district with the farmers market, SITE Santa Fe, craft breweries, and the Plaza a short walk away.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Dan", 4.9, "Jan 2026", "Railyard farmers market was the highlight of our trip."), ("Kim", 4.8, "Dec 2025", "Great modern space in a historic city.")])),
            // Additional stays for Chiang Mai, Edinburgh, Hanoi, Charleston, Savannah, Maui
            // Chiang Mai
            Listing(id: "stay-chiangmai-riverside", title: "Ping River boutique room", location: "Chiang Mai, Thailand", price: 42, rating: 4.89, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Air conditioning", "Self check-in", "Workspace"],
                images: [image("River View", "sf_stay_592", [UIColor(red:0.42,green:0.55,blue:0.50,alpha:1), UIColor(red:0.62,green:0.75,blue:0.70,alpha:1)]), image("Room", "sf_stay_593", [UIColor(red:0.86,green:0.82,blue:0.76,alpha:1), UIColor(red:0.70,green:0.66,blue:0.58,alpha:1)]), image("Night Bazaar", "sf_stay_594", [UIColor(red:0.78,green:0.58,blue:0.38,alpha:1), UIColor(red:0.92,green:0.75,blue:0.55,alpha:1)])],
                host: hostJade, description: "Affordable room along the Ping River near the Night Bazaar, Warorot Market, and riverside cafes with mountain views.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Nok", 4.9, "Feb 2026", "Best value in Chiang Mai. River views for this price!"), ("Sam", 4.8, "Jan 2026", "Night Bazaar walking distance was perfect.")])),
            // Edinburgh
            Listing(id: "stay-edinburgh-leith", title: "Leith waterfront flat", location: "Edinburgh, Scotland", price: 105, rating: 4.88, reviewCount: 189, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in"],
                images: [image("Waterfront", "sf_stay_595", [UIColor(red:0.42,green:0.55,blue:0.65,alpha:1), UIColor(red:0.62,green:0.75,blue:0.85,alpha:1)]), image("Flat", "sf_stay_596", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Shore Pubs", "sf_stay_597", [UIColor(red:0.55,green:0.48,blue:0.42,alpha:1), UIColor(red:0.75,green:0.68,blue:0.62,alpha:1)])],
                host: hostIsla, description: "Waterfront flat in Leith near the Shore's Michelin restaurants, craft beer pubs, and the Royal Yacht Britannia.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Hamish", 4.9, "Jan 2026", "Leith has Edinburgh's best restaurants. Great base."), ("Claire", 4.8, "Dec 2025", "Loved the waterfront walks and pub scene.")])),
            // Hanoi
            Listing(id: "stay-hanoi-french", title: "French Quarter colonial flat", location: "Hanoi, Vietnam", price: 48, rating: 4.86, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City"],
                amenities: ["Wifi", "Kitchen", "Air conditioning", "Self check-in"],
                images: [image("Colonial Building", "sf_stay_598", [UIColor(red:0.82,green:0.78,blue:0.68,alpha:1), UIColor(red:0.65,green:0.60,blue:0.50,alpha:1)]), image("Flat", "sf_stay_599", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Opera House", "sf_stay_600", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostJade, description: "Colonial-era flat in the French Quarter near the Opera House, Hoan Kiem Lake, and wide tree-lined boulevards with Vietnamese coffee shops.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Linh", 4.9, "Feb 2026", "French Quarter is Hanoi's most elegant area."), ("Ben", 4.8, "Jan 2026", "Great coffee shops and very walkable.")])),
            // Charleston
            Listing(id: "stay-charleston-rainbow", title: "Rainbow Row carriage house", location: "Charleston, SC", price: 195, rating: 4.94, reviewCount: 98, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Self check-in", "Parking"],
                images: [image("Rainbow Row", "sf_stay_601", [UIColor(red:0.78,green:0.68,blue:0.55,alpha:1), UIColor(red:0.92,green:0.82,blue:0.68,alpha:1)]), image("Carriage House", "sf_stay_602", [UIColor(red:0.88,green:0.84,blue:0.78,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Waterfront", "sf_stay_603", [UIColor(red:0.42,green:0.58,blue:0.68,alpha:1), UIColor(red:0.62,green:0.78,blue:0.85,alpha:1)])],
                host: hostIsla, description: "Historic carriage house steps from Rainbow Row with a private courtyard, the Battery promenade, and Charleston's best shrimp and grits.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Amy", 5.0, "Feb 2026", "The most charming stay I have ever had."), ("Will", 4.9, "Jan 2026", "Rainbow Row and the Battery were a daily walk.")])),
            // Savannah
            Listing(id: "stay-savannah-jones", title: "Jones Street row house", location: "Savannah, GA", price: 175, rating: 4.92, reviewCount: 145, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Self check-in", "Washer"],
                images: [image("Live Oaks", "sf_stay_604", [UIColor(red:0.38,green:0.52,blue:0.35,alpha:1), UIColor(red:0.58,green:0.72,blue:0.55,alpha:1)]), image("Row House", "sf_stay_605", [UIColor(red:0.82,green:0.74,blue:0.62,alpha:1), UIColor(red:0.94,green:0.88,blue:0.76,alpha:1)]), image("Forsyth Fountain", "sf_stay_606", [UIColor(red:0.45,green:0.58,blue:0.48,alpha:1), UIColor(red:0.65,green:0.78,blue:0.68,alpha:1)])],
                host: hostRavi, description: "Row house on one of America's prettiest streets with live oak canopy, Forsyth Park walks, and Savannah's legendary food scene.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Beth", 5.0, "Feb 2026", "Jones Street is as beautiful as they say. Dream stay."), ("Mark", 4.9, "Jan 2026", "Forsyth Park morning runs and Mrs. Wilkes' lunch.")])),
            // Maui
            Listing(id: "stay-maui-kihei", title: "Kihei oceanview condo", location: "Maui, HI", price: 185, rating: 4.88, reviewCount: 198, beds: 2, baths: 2, guests: 4,
                categories: ["Beachfront", "Trending"],
                amenities: ["Wifi", "Kitchen", "Pool", "Air conditioning", "Parking"],
                images: [image("Ocean View", "sf_stay_607", [UIColor(red:0.35,green:0.62,blue:0.82,alpha:1), UIColor(red:0.55,green:0.82,blue:0.92,alpha:1)]), image("Condo", "sf_stay_608", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Sunset Beach", "sf_stay_609", [UIColor(red:0.85,green:0.55,blue:0.35,alpha:1), UIColor(red:0.95,green:0.72,blue:0.50,alpha:1)])],
                host: hostRina, description: "Oceanview condo in sunny Kihei with whale watching from the lanai, pool access, snorkeling beaches, and food truck lunches.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jake", 4.9, "Feb 2026", "Saw whales from the balcony every morning!"), ("Emma", 4.8, "Jan 2026", "Kihei is the sweet spot between value and beauty.")])),
            // ── ADDITIONAL STAYS: REMAINING GAPS ─────────────────────────
            // Lake Tahoe
            Listing(id: "stay-tahoe-emerald", title: "Emerald Bay view cabin", location: "Lake Tahoe, CA", price: 225, rating: 4.93, reviewCount: 112, beds: 3, baths: 2, guests: 6,
                categories: ["Cabins", "Amazing views", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Hot tub", "Parking", "Fire pit"],
                images: [image("Lake View", "sf_stay_610", [UIColor(red:0.30,green:0.55,blue:0.72,alpha:1), UIColor(red:0.50,green:0.75,blue:0.88,alpha:1)]), image("Cabin Interior", "sf_stay_611", [UIColor(red:0.82,green:0.74,blue:0.62,alpha:1), UIColor(red:0.65,green:0.55,blue:0.42,alpha:1)]), image("Snow Deck", "sf_stay_612", [UIColor(red:0.88,green:0.90,blue:0.92,alpha:1), UIColor(red:0.72,green:0.74,blue:0.78,alpha:1)])],
                host: hostLena, description: "A-frame cabin with Emerald Bay views, a hot tub, fire pit, ski resort shuttle, and summer kayaking from the dock.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Mike", 5.0, "Mar 2026", "Hot tub with lake views after skiing. Perfection."), ("Sara", 4.9, "Feb 2026", "The A-frame is even more beautiful in person.")])),
            // Amalfi Coast
            Listing(id: "stay-amalfi-positano", title: "Positano cliffside apartment", location: "Amalfi Coast, Italy", price: 285, rating: 4.95, reviewCount: 78, beds: 1, baths: 1, guests: 2,
                categories: ["Amazing views", "Guest favorite", "Beachfront"],
                amenities: ["Wifi", "Kitchen", "Terrace", "Air conditioning"],
                images: [image("Cliffside View", "sf_stay_613", [UIColor(red:0.40,green:0.62,blue:0.82,alpha:1), UIColor(red:0.60,green:0.82,blue:0.92,alpha:1)]), image("Terrace", "sf_stay_614", [UIColor(red:0.85,green:0.78,blue:0.65,alpha:1), UIColor(red:0.95,green:0.90,blue:0.78,alpha:1)]), image("Beach Path", "sf_stay_615", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)])],
                host: hostSofia, description: "Apartment carved into Positano's cliff with a terrace overlooking the Tyrrhenian Sea, steps descending to the beach, and limoncello sunsets.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Isabella", 5.0, "Mar 2026", "Most beautiful view I will ever wake up to."), ("Tom", 4.9, "Feb 2026", "Positano from this terrace is a postcard.")])),
            // Buenos Aires
            Listing(id: "stay-ba-palermo", title: "Palermo Soho loft", location: "Buenos Aires, Argentina", price: 72, rating: 4.90, reviewCount: 234, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Washer", "Self check-in", "Workspace"],
                images: [image("Street Art", "sf_stay_616", [UIColor(red:0.70,green:0.55,blue:0.62,alpha:1), UIColor(red:0.88,green:0.72,blue:0.80,alpha:1)]), image("Loft", "sf_stay_617", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Plaza Serrano", "sf_stay_618", [UIColor(red:0.62,green:0.55,blue:0.48,alpha:1), UIColor(red:0.80,green:0.74,blue:0.66,alpha:1)])],
                host: hostDiego, description: "Design loft in Palermo Soho with street art, Plaza Serrano bars, steak parrillas, and Buenos Aires's best boutique shopping.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Camila", 4.9, "Feb 2026", "Palermo Soho is the heart of BA nightlife and culture."), ("Jack", 4.9, "Jan 2026", "The steak restaurants nearby were unbelievable.")])),
            // Lima, Peru
            Listing(id: "stay-lima-miraflores", title: "Miraflores oceanview apartment", location: "Lima, Peru", price: 85, rating: 4.89, reviewCount: 198, beds: 2, baths: 1, guests: 3,
                categories: ["City", "Amazing views"],
                amenities: ["Wifi", "Kitchen", "Gym", "Elevator", "Air conditioning"],
                images: [image("Pacific View", "sf_stay_619", [UIColor(red:0.40,green:0.58,blue:0.72,alpha:1), UIColor(red:0.60,green:0.78,blue:0.88,alpha:1)]), image("Apartment", "sf_stay_620", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Malecon Walk", "sf_stay_621", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostAmara, description: "Modern apartment in Miraflores with Pacific Ocean views, Malecon clifftop walks, world-class ceviche, and Parque Kennedy nearby.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Carlos", 4.9, "Feb 2026", "Best ceviche of my life was two blocks away."), ("Sarah", 4.9, "Jan 2026", "Miraflores is perfect for a first visit to Lima.")])),
            Listing(id: "stay-lima-barranco", title: "Barranco bohemian studio", location: "Lima, Peru", price: 55, rating: 4.91, reviewCount: 267, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Trending", "Design"],
                amenities: ["Wifi", "Kitchen", "Self check-in", "Workspace"],
                images: [image("Bridge of Sighs", "sf_stay_622", [UIColor(red:0.72,green:0.58,blue:0.45,alpha:1), UIColor(red:0.90,green:0.78,blue:0.65,alpha:1)]), image("Studio", "sf_stay_623", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("Gallery Walk", "sf_stay_624", [UIColor(red:0.65,green:0.55,blue:0.50,alpha:1), UIColor(red:0.82,green:0.72,blue:0.68,alpha:1)])],
                host: hostDiego, description: "Bohemian studio in Barranco near the Bridge of Sighs, street art murals, craft pisco bars, and Lima's best gallery and nightlife scene.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Ana", 4.9, "Jan 2026", "Barranco is Lima's coolest neighborhood. Loved it."), ("Will", 4.9, "Dec 2025", "Bridge of Sighs at sunset was magical.")])),
            // Busan, South Korea
            Listing(id: "stay-busan-haeundae", title: "Haeundae beachfront condo", location: "Busan, South Korea", price: 115, rating: 4.88, reviewCount: 234, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "City", "Trending"],
                amenities: ["Wifi", "Kitchen", "Pool", "Air conditioning", "Elevator"],
                images: [image("Beach View", "sf_stay_625", [UIColor(red:0.42,green:0.68,blue:0.85,alpha:1), UIColor(red:0.62,green:0.85,blue:0.92,alpha:1)]), image("Condo", "sf_stay_626", [UIColor(red:0.90,green:0.88,blue:0.84,alpha:1), UIColor(red:0.74,green:0.70,blue:0.66,alpha:1)]), image("Fish Market", "sf_stay_627", [UIColor(red:0.72,green:0.58,blue:0.42,alpha:1), UIColor(red:0.90,green:0.78,blue:0.62,alpha:1)])],
                host: hostYuna, description: "Modern beachfront condo in Haeundae with Jagalchi fish market nearby, beach walks, rooftop pool, and KTX train access.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Soo", 4.9, "Feb 2026", "Haeundae Beach at sunrise was incredible."), ("Emma", 4.8, "Jan 2026", "Best seafood of our Korea trip was in Busan.")])),
            Listing(id: "stay-busan-gamcheon", title: "Gamcheon Culture Village room", location: "Busan, South Korea", price: 58, rating: 4.90, reviewCount: 178, beds: 1, baths: 1, guests: 2,
                categories: ["City", "Design", "Guest favorite"],
                amenities: ["Wifi", "Air conditioning", "Self check-in"],
                images: [image("Colorful Houses", "sf_stay_628", [UIColor(red:0.72,green:0.62,blue:0.50,alpha:1), UIColor(red:0.90,green:0.82,blue:0.70,alpha:1)]), image("Room", "sf_stay_629", [UIColor(red:0.86,green:0.82,blue:0.76,alpha:1), UIColor(red:0.70,green:0.66,blue:0.58,alpha:1)]), image("Village Art", "sf_stay_630", [UIColor(red:0.55,green:0.65,blue:0.78,alpha:1), UIColor(red:0.75,green:0.82,blue:0.92,alpha:1)])],
                host: hostKenji, description: "Room in Gamcheon Culture Village—Busan's pastel hillside art village—with murals, installations, and harbor views from every corner.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Min", 5.0, "Jan 2026", "Gamcheon is like living inside an art installation."), ("Jade", 4.9, "Dec 2025", "Most photogenic place I have ever stayed.")])),
            // Cape Cod, MA
            Listing(id: "stay-capecod-provincetown", title: "Provincetown harbor cottage", location: "Cape Cod, MA", price: 195, rating: 4.91, reviewCount: 112, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Garden", "Parking", "Bikes"],
                images: [image("Harbor", "sf_stay_631", [UIColor(red:0.42,green:0.58,blue:0.70,alpha:1), UIColor(red:0.62,green:0.78,blue:0.88,alpha:1)]), image("Cottage", "sf_stay_632", [UIColor(red:0.85,green:0.80,blue:0.72,alpha:1), UIColor(red:0.68,green:0.62,blue:0.54,alpha:1)]), image("Commercial Street", "sf_stay_633", [UIColor(red:0.72,green:0.65,blue:0.55,alpha:1), UIColor(red:0.90,green:0.84,blue:0.74,alpha:1)])],
                host: hostLena, description: "Shingled cottage near Provincetown harbor with Commercial Street galleries, whale watching, dune shack hikes, and fresh oysters daily.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Beth", 4.9, "Feb 2026", "P-town in summer is pure magic. Perfect cottage."), ("Dan", 4.9, "Jan 2026", "Whale watching and oyster happy hours every day.")])),
            Listing(id: "stay-capecod-wellfleet", title: "Wellfleet oyster farm cottage", location: "Cape Cod, MA", price: 155, rating: 4.89, reviewCount: 145, beds: 2, baths: 1, guests: 3,
                categories: ["Beachfront", "Countryside"],
                amenities: ["Wifi", "Kitchen", "Parking", "Garden", "Fire pit"],
                images: [image("Marsh View", "sf_stay_634", [UIColor(red:0.55,green:0.65,blue:0.55,alpha:1), UIColor(red:0.75,green:0.85,blue:0.75,alpha:1)]), image("Cottage", "sf_stay_635", [UIColor(red:0.82,green:0.78,blue:0.70,alpha:1), UIColor(red:0.65,green:0.60,blue:0.52,alpha:1)]), image("Oyster Shack", "sf_stay_636", [UIColor(red:0.68,green:0.60,blue:0.50,alpha:1), UIColor(red:0.85,green:0.78,blue:0.68,alpha:1)])],
                host: hostLena, description: "Cottage near Wellfleet's oyster farms with marsh views, Cape Cod National Seashore beaches, drive-in movie theater, and fire pit nights.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Karen", 4.9, "Feb 2026", "Wellfleet oysters straight from the farm. Incredible."), ("Rob", 4.8, "Jan 2026", "The drive-in and fire pit were nostalgic perfection.")])),
            // Hudson Valley, NY
            Listing(id: "stay-hudson-farmhouse", title: "Hudson Valley farmhouse retreat", location: "Hudson Valley, NY", price: 245, rating: 4.93, reviewCount: 89, beds: 3, baths: 2, guests: 6,
                categories: ["Countryside", "Guest favorite", "Design"],
                amenities: ["Wifi", "Kitchen", "Fire pit", "Parking", "Garden", "Hot tub"],
                images: [image("Farmhouse", "sf_stay_637", [UIColor(red:0.62,green:0.58,blue:0.48,alpha:1), UIColor(red:0.80,green:0.76,blue:0.66,alpha:1)]), image("Garden", "sf_stay_638", [UIColor(red:0.42,green:0.58,blue:0.40,alpha:1), UIColor(red:0.62,green:0.78,blue:0.60,alpha:1)]), image("Mountain View", "sf_stay_639", [UIColor(red:0.45,green:0.55,blue:0.62,alpha:1), UIColor(red:0.65,green:0.75,blue:0.82,alpha:1)])],
                host: hostRina, description: "Renovated farmhouse on rolling acres with Catskill views, a hot tub, fire pit, farm-to-table dining nearby, and antique shop hopping in Hudson.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Amy", 5.0, "Mar 2026", "The hot tub with mountain views was paradise."), ("Greg", 4.9, "Feb 2026", "Best weekend escape from NYC we have found.")])),
            Listing(id: "stay-hudson-cottage", title: "Beacon arts district cottage", location: "Hudson Valley, NY", price: 155, rating: 4.88, reviewCount: 167, beds: 2, baths: 1, guests: 4,
                categories: ["Countryside", "Design"],
                amenities: ["Wifi", "Kitchen", "Garden", "Parking", "Self check-in"],
                images: [image("Cottage", "sf_stay_640", [UIColor(red:0.72,green:0.68,blue:0.58,alpha:1), UIColor(red:0.55,green:0.50,blue:0.40,alpha:1)]), image("Garden Patio", "sf_stay_641", [UIColor(red:0.45,green:0.58,blue:0.42,alpha:1), UIColor(red:0.65,green:0.78,blue:0.62,alpha:1)]), image("Dia Beacon", "sf_stay_642", [UIColor(red:0.88,green:0.86,blue:0.82,alpha:1), UIColor(red:0.72,green:0.68,blue:0.64,alpha:1)])],
                host: hostLena, description: "Cottage near Dia Beacon museum with Main Street cafes, Hudson River walks, Storm King day trips, and Metro-North to NYC.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Nina", 4.9, "Feb 2026", "Dia Beacon was life-changing. This cottage was perfect."), ("Sam", 4.8, "Jan 2026", "Main Street Beacon has amazing food and shops.")])),
            // San Francisco additional
            Listing(id: "stay-sf-sunset", title: "Outer Sunset beach bungalow", location: "San Francisco, CA", price: 145, rating: 4.89, reviewCount: 167, beds: 2, baths: 1, guests: 4,
                categories: ["Beachfront", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Washer", "Parking", "Garden"],
                images: [image("Beach Walk", "sf_stay_643", [UIColor(red:0.55,green:0.68,blue:0.75,alpha:1), UIColor(red:0.75,green:0.85,blue:0.90,alpha:1)]), image("Bungalow", "sf_stay_644", [UIColor(red:0.82,green:0.78,blue:0.72,alpha:1), UIColor(red:0.65,green:0.60,blue:0.54,alpha:1)]), image("Judah Line", "sf_stay_645", [UIColor(red:0.55,green:0.52,blue:0.48,alpha:1), UIColor(red:0.75,green:0.72,blue:0.68,alpha:1)])],
                host: hostChen, description: "Beach bungalow in the Outer Sunset with Ocean Beach walks, Judah streetcar to downtown, taco trucks, and foggy morning surf sessions.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Jake", 4.9, "Feb 2026", "Outer Sunset is the real SF. Beach vibes and great tacos."), ("Lisa", 4.8, "Jan 2026", "Loved the foggy morning walks on Ocean Beach.")])),
            // Los Angeles additional
            Listing(id: "stay-la-highland-park", title: "Highland Park craftsman", location: "Los Angeles, CA", price: 135, rating: 4.90, reviewCount: 198, beds: 2, baths: 1, guests: 4,
                categories: ["City", "Guest favorite", "Trending"],
                amenities: ["Wifi", "Kitchen", "Patio", "Parking", "Washer"],
                images: [image("Craftsman Front", "sf_stay_646", [UIColor(red:0.62,green:0.55,blue:0.45,alpha:1), UIColor(red:0.80,green:0.74,blue:0.64,alpha:1)]), image("Interior", "sf_stay_647", [UIColor(red:0.88,green:0.85,blue:0.80,alpha:1), UIColor(red:0.72,green:0.68,blue:0.62,alpha:1)]), image("York Blvd", "sf_stay_648", [UIColor(red:0.55,green:0.50,blue:0.45,alpha:1), UIColor(red:0.75,green:0.70,blue:0.65,alpha:1)])],
                host: hostRavi, description: "Craftsman house in Highland Park with York Boulevard's craft beer and coffee scene, vintage shops, and the Gold Line to DTLA.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Mia", 4.9, "Feb 2026", "HiPa is LA's best neighborhood. This house is perfect."), ("Dan", 4.9, "Jan 2026", "York Blvd is a food and drink paradise.")])),
            Listing(id: "stay-la-malibu", title: "Malibu beach house", location: "Los Angeles, CA", price: 425, rating: 4.94, reviewCount: 56, beds: 3, baths: 2, guests: 6,
                categories: ["Beachfront", "Amazing views", "Guest favorite"],
                amenities: ["Wifi", "Kitchen", "Parking", "Washer", "Deck"],
                images: [image("Beach Front", "sf_stay_649", [UIColor(red:0.42,green:0.68,blue:0.85,alpha:1), UIColor(red:0.62,green:0.85,blue:0.92,alpha:1)]), image("Ocean Deck", "sf_stay_650", [UIColor(red:0.85,green:0.78,blue:0.65,alpha:1), UIColor(red:0.95,green:0.90,blue:0.78,alpha:1)]), image("Sunset PCH", "sf_stay_651", [UIColor(red:0.85,green:0.55,blue:0.35,alpha:1), UIColor(red:0.95,green:0.72,blue:0.50,alpha:1)])],
                host: hostRina, description: "Beachfront house on PCH with waves crashing below the deck, Malibu Farm for lunch, Point Dume hikes, and dolphins at breakfast.", kind: .stay, duration: "", highlights: [],
                reviews: reviews([("Chris", 5.0, "Mar 2026", "Dolphins from the deck at sunrise. Bucket list."), ("Sophie", 4.9, "Feb 2026", "Worth the splurge. Most beautiful place in LA.")])),
            // ── NEW EXPERIENCES ──────────────────────────────────────────
            Listing(id: "exp-berlin-food", title: "Berlin street food and beer tour", location: "Berlin, Germany", price: 58, rating: 4.91, reviewCount: 187, beds: 0, baths: 0, guests: 10,
                categories: ["Trending", "City"],
                amenities: ["Tastings", "Guide", "Small group"],
                images: [image("Street Food", "sf_exp_43", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)]), image("Beer Garden", "sf_exp_44", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Market Walk", "sf_exp_45", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)])],
                host: hostLina, description: "Taste your way through Kreuzberg and Neukolln with currywurst, doner, craft beer stops, and neighborhood stories between bites.", kind: .experience, duration: "3 hours",
                highlights: ["Meet in Kreuzberg", "Five food stops", "Two beer gardens", "Local history"],
                reviews: reviews([("Fritz", 4.9, "Jan 2026", "Best way to understand Berlin's food culture."), ("Kate", 4.9, "Dec 2025", "The hidden beer garden was a highlight.")])),
            Listing(id: "exp-nola-jazz", title: "New Orleans jazz and cocktail walk", location: "New Orleans, LA", price: 75, rating: 4.96, reviewCount: 156, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "City"],
                amenities: ["Cocktails", "Guide", "Small group"],
                images: [image("Jazz Club", "sf_exp_28", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)]), image("Cocktail Bar", "sf_exp_29", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)]), image("Street Music", "sf_exp_30", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)])],
                host: hostIsla, description: "Walk through the French Quarter and Frenchmen Street with stops at hidden jazz clubs and craft cocktail bars with a local musician guide.", kind: .experience, duration: "3 hours",
                highlights: ["Meet on Frenchmen St", "Three live jazz stops", "Craft cocktails", "Music history"],
                reviews: reviews([("Max", 5.0, "Feb 2026", "Hearing live jazz in tiny clubs was unforgettable."), ("Rose", 4.9, "Jan 2026", "Our guide knew every musician by name.")])),
            Listing(id: "exp-capetown-wine", title: "Cape Winelands tasting tour", location: "Cape Town, South Africa", price: 85, rating: 4.94, reviewCount: 134, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "Countryside"],
                amenities: ["Wine tastings", "Guide", "Transport", "Lunch"],
                images: [image("Vineyard", "sf_exp_46", [UIColor(red:0.31,green:0.39,blue:0.27,alpha:1), UIColor(red:0.55,green:0.63,blue:0.43,alpha:1)]), image("Wine Cellar", "sf_exp_47", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)]), image("Mountain Backdrop", "sf_exp_48", [UIColor(red:0.27,green:0.59,blue:0.82,alpha:1), UIColor(red:0.55,green:0.86,blue:0.90,alpha:1)])],
                host: hostZara, description: "Drive through Stellenbosch and Franschhoek wine valleys with tastings at three estates, a vineyard lunch, and mountain views.", kind: .experience, duration: "6 hours",
                highlights: ["Hotel pickup", "Three wine estates", "Vineyard lunch", "Mountain drive"],
                reviews: reviews([("Pierre", 5.0, "Jan 2026", "The Franschhoek valley was breathtaking."), ("Amira", 4.9, "Dec 2025", "Best wine tour we have done anywhere.")])),
            Listing(id: "exp-chiangmai-cook", title: "Chiang Mai farm-to-table cooking class", location: "Chiang Mai, Thailand", price: 42, rating: 4.97, reviewCount: 312, beds: 0, baths: 0, guests: 10,
                categories: ["Trending", "Countryside"],
                amenities: ["Ingredients", "Guide", "Market visit", "Recipe book"],
                images: [image("Cooking Station", "sf_exp_49", [UIColor(red:0.86,green:0.78,blue:0.70,alpha:1), UIColor(red:0.60,green:0.50,blue:0.44,alpha:1)]), image("Market Visit", "sf_exp_50", [UIColor(red:0.92,green:0.54,blue:0.38,alpha:1), UIColor(red:0.98,green:0.72,blue:0.52,alpha:1)]), image("Herb Garden", "sf_exp_51", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.20,green:0.59,blue:0.51,alpha:1)])],
                host: hostJade, description: "Start at a local market, pick ingredients from an organic garden, and cook five Thai dishes in an open-air kitchen with mountain views.", kind: .experience, duration: "4 hours",
                highlights: ["Market tour", "Herb garden", "Cook 5 dishes", "Take recipe book home"],
                reviews: reviews([("Mei", 5.0, "Jan 2026", "Best cooking class in all of Thailand."), ("Ryan", 5.0, "Dec 2025", "I still make the green curry at home.")])),
            Listing(id: "exp-hanoi-street-food", title: "Hanoi street food motorbike tour", location: "Hanoi, Vietnam", price: 38, rating: 4.95, reviewCount: 278, beds: 0, baths: 0, guests: 6,
                categories: ["Trending", "City"],
                amenities: ["Tastings", "Guide", "Motorbike transport"],
                images: [image("Motorbike Tour", "sf_exp_52", [UIColor(red:0.70,green:0.39,blue:0.24,alpha:1), UIColor(red:0.86,green:0.63,blue:0.39,alpha:1)]), image("Pho Stop", "sf_exp_53", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)]), image("Night Market", "sf_exp_54", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostJade, description: "Hop on the back of a motorbike and taste your way through Hanoi's best street food stalls, from pho to egg coffee to bun cha.", kind: .experience, duration: "3.5 hours",
                highlights: ["Motorbike pickup", "Six food stops", "Local neighborhoods", "Egg coffee finale"],
                reviews: reviews([("Thao", 5.0, "Feb 2026", "The most authentic way to experience Hanoi."), ("Ollie", 4.9, "Jan 2026", "Egg coffee changed my life.")])),
            Listing(id: "exp-edinburgh-whisky", title: "Edinburgh whisky and history walk", location: "Edinburgh, Scotland", price: 68, rating: 4.93, reviewCount: 145, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "City"],
                amenities: ["Whisky tastings", "Guide", "Small group"],
                images: [image("Whisky Bar", "sf_exp_55", [UIColor(red:0.68,green:0.62,blue:0.55,alpha:1), UIColor(red:0.38,green:0.32,blue:0.28,alpha:1)]), image("Old Town Walk", "sf_exp_56", [UIColor(red:0.24,green:0.24,blue:0.29,alpha:1), UIColor(red:0.47,green:0.49,blue:0.55,alpha:1)]), image("Castle View", "sf_exp_57", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)])],
                host: hostIsla, description: "Walk the Royal Mile and hidden closes with a historian guide, stopping at three whisky bars for tastings and stories.", kind: .experience, duration: "2.5 hours",
                highlights: ["Royal Mile walk", "Three whisky tastings", "Hidden closes", "Castle views"],
                reviews: reviews([("Hamish", 5.0, "Jan 2026", "The stories in the closes were fascinating."), ("Sarah", 4.9, "Dec 2025", "Best whisky education wrapped in great storytelling.")])),
            // ── NEW SERVICES ────────────────────────────────────────────
            Listing(id: "service-tulum-wellness", title: "Beach yoga and sound bath", location: "Tulum, Mexico", price: 95, rating: 4.95, reviewCount: 67, beds: 0, baths: 0, guests: 6,
                categories: ["Trending", "Tropical"],
                amenities: ["Yoga mats", "Instructor", "Sound bowls"],
                images: [image("Beach Yoga", "sf_svc_19", [UIColor(red:0.56,green:0.83,blue:0.87,alpha:1), UIColor(red:0.22,green:0.48,blue:0.74,alpha:1)]), image("Sound Bath", "sf_svc_20", [UIColor(red:0.35,green:0.66,blue:0.55,alpha:1), UIColor(red:0.20,green:0.59,blue:0.51,alpha:1)])],
                host: hostAmara, description: "Sunrise yoga on the beach followed by a crystal singing bowl sound bath with the Caribbean waves as your backdrop.", kind: .service, duration: "90 minutes",
                highlights: ["Sunrise start", "Beach yoga flow", "Sound bowl healing", "Guided meditation"],
                reviews: reviews([("Luna", 5.0, "Jan 2026", "Most transformative morning of the trip."), ("Aria", 4.9, "Dec 2025", "The sound bowls on the beach were incredible.")])),
            Listing(id: "service-nola-music", title: "Private jazz trio for your stay", location: "New Orleans, LA", price: 185, rating: 4.98, reviewCount: 34, beds: 0, baths: 0, guests: 8,
                categories: ["Trending", "City"],
                amenities: ["Musicians", "PA system", "Song requests"],
                images: [image("Jazz Trio", "sf_svc_21", [UIColor(red:0.16,green:0.12,blue:0.24,alpha:1), UIColor(red:0.39,green:0.27,blue:0.47,alpha:1)]), image("Performance", "sf_svc_22", [UIColor(red:0.84,green:0.64,blue:0.28,alpha:1), UIColor(red:0.96,green:0.74,blue:0.38,alpha:1)])],
                host: hostRavi, description: "Book a jazz trio to play in your courtyard or living room for an intimate private concert with classic New Orleans standards.", kind: .service, duration: "2 hours",
                highlights: ["Trio arrives at your stay", "Classic jazz standards", "Song requests welcome", "Setup and breakdown included"],
                reviews: reviews([("Frank", 5.0, "Jan 2026", "A private jazz concert in our courtyard. Unforgettable."), ("Diana", 5.0, "Dec 2025", "The most special night of our New Orleans trip.")]))
        ]

        func makeConversation(
            listingId: String,
            hostName: String,
            title: String,
            tripSummary: String,
            category: ConversationCategory,
            unreadCount: Int,
            baseDate: Date,
            messages: [(String, Bool)]
        ) -> Conversation? {
            guard let listing = listings.first(where: { $0.id == listingId }) else { return nil }
            let builtMessages = messages.enumerated().map { index, entry in
                Message(
                    id: UUID().uuidString,
                    text: entry.0,
                    isHost: entry.1,
                    timestamp: baseDate.addingTimeInterval(Double(index) * 240)
                )
            }
            return Conversation(
                id: UUID().uuidString,
                listingId: listingId,
                hostName: hostName.isEmpty ? listing.host.name : hostName,
                title: title,
                tripSummary: tripSummary,
                category: category,
                unreadCount: unreadCount,
                messages: builtMessages
            )
        }

        conversations = [
            makeConversation(
                listingId: "stay-soma",
                hostName: "Lena",
                title: "Lena and Ridge Cabin",
                tripSummary: "Oct 12 - 15, 2025 · Big Sur",
                category: .traveling,
                unreadCount: 1,
                baseDate: date(2025, 10, 11),
                messages: [
                    ("Your check-in code will arrive at 2 PM on the day of arrival.", true),
                    ("Perfect, thank you. We should land around noon.", false),
                    ("Sounds good. The luggage rack is right inside the entry.", true)
                ]
            ),
            makeConversation(
                listingId: "stay-beach",
                hostName: "Andre",
                title: "Andre at Catalina Retreat",
                tripSummary: tripSummaryString(start: catalinaStart, end: catalinaEnd, location: "Catalina Island"),
                category: .traveling,
                unreadCount: 0,
                baseDate: futureDate(daysFromNow: -42),
                messages: [
                    ("Parking is marked in your guidebook, and the side gate opens with the keypad code I sent over.", true),
                    ("Great, that answers everything for us.", false)
                ]
            ),
            makeConversation(
                listingId: "stay-midtown-hotel",
                hostName: "StayFinder Support",
                title: "StayFinder Support",
                tripSummary: "Refund request · Closed",
                category: .support,
                unreadCount: 0,
                baseDate: date(2025, 12, 20),
                messages: [
                    ("Your refund for the canceled bay-view reservation has been processed to your saved card.", true),
                    ("Thank you for the update.", false)
                ]
            ),
            makeConversation(
                listingId: "stay-asheville",
                hostName: "Andre",
                title: "Andre at Redwood Canyon Room",
                tripSummary: "Jun 5 - 8, 2025 · Sequoia",
                category: .traveling,
                unreadCount: 0,
                baseDate: date(2025, 6, 7),
                messages: [
                    ("The front door sometimes sticks. Pull once, then enter the code.", true),
                    ("Worked perfectly, thanks again.", false)
                ]
            ),
            makeConversation(
                listingId: "service-photo",
                hostName: "Mika",
                title: "Mika and Catalina Photo Session",
                tripSummary: tripSummaryString(start: photoSessionDate, end: photoSessionDate, location: "Catalina Island"),
                category: .traveling,
                unreadCount: 0,
                baseDate: futureDate(daysFromNow: -39),
                messages: [
                    ("Golden hour starts at 6:42 PM that week, so 6:15 PM is the best meeting time.", true),
                    ("Perfect. We would love a harbor overlook stop if the light works.", false),
                    ("Absolutely. I will map a two-stop route for you.", true)
                ]
            ),
            makeConversation(
                listingId: "exp-food",
                hostName: "Rina",
                title: "Rina and Coastal Taco Tasting",
                tripSummary: "Aug 2, 2025 · San Diego",
                category: .traveling,
                unreadCount: 0,
                baseDate: date(2025, 7, 30),
                messages: [
                    ("Bring cash for a few optional market add-ons and come hungry.", true),
                    ("Noted. We are very ready.", false)
                ]
            )
        ].compactMap { $0 }

        bookings = [
            Booking(
                id: UUID().uuidString,
                listingId: "stay-beach",
                startDate: catalinaStart,
                endDate: catalinaEnd,
                guests: 4,
                status: .upcoming,
                createdAt: futureDate(daysFromNow: -45)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "service-photo",
                startDate: photoSessionDate,
                endDate: photoSessionDate,
                guests: 2,
                status: .upcoming,
                createdAt: futureDate(daysFromNow: -41)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "exp-sail",
                startDate: sunsetSailDate,
                endDate: sunsetSailDate,
                guests: 2,
                status: .upcoming,
                createdAt: futureDate(daysFromNow: -54)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "stay-soma",
                startDate: date(2025, 10, 12),
                endDate: date(2025, 10, 15),
                guests: 2,
                status: .completed,
                createdAt: date(2025, 9, 28)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "exp-food",
                startDate: date(2025, 8, 2),
                endDate: date(2025, 8, 2),
                guests: 2,
                status: .completed,
                createdAt: date(2025, 7, 20)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "service-chef",
                startDate: date(2025, 11, 22),
                endDate: date(2025, 11, 22),
                guests: 4,
                status: .completed,
                createdAt: date(2025, 10, 30)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "stay-asheville",
                startDate: date(2025, 6, 5),
                endDate: date(2025, 6, 8),
                guests: 1,
                status: .completed,
                createdAt: date(2025, 5, 18)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "stay-lisbon-alfama",
                startDate: date(2025, 3, 14),
                endDate: date(2025, 3, 19),
                guests: 2,
                status: .completed,
                createdAt: date(2025, 2, 20)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "stay-chelsea-hotel",
                startDate: date(2024, 11, 8),
                endDate: date(2024, 11, 11),
                guests: 3,
                status: .completed,
                createdAt: date(2024, 10, 22)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "stay-london",
                startDate: date(2024, 7, 19),
                endDate: date(2024, 7, 22),
                guests: 1,
                status: .completed,
                createdAt: date(2024, 6, 30)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "stay-cabin",
                startDate: date(2024, 3, 22),
                endDate: date(2024, 3, 25),
                guests: 4,
                status: .completed,
                createdAt: date(2024, 3, 5)
            ),
            Booking(
                id: UUID().uuidString,
                listingId: "stay-midtown-hotel",
                startDate: date(2025, 12, 18),
                endDate: date(2025, 12, 20),
                guests: 2,
                status: .canceled,
                createdAt: date(2025, 11, 30)
            )
        ]

        wishlists = [
            Wishlist(id: "wl-saved", name: "Saved stays", listingIDs: ["stay-beach", "stay-soma", "stay-soho-suite", "stay-chelsea-hotel", "stay-cabin", "stay-seoul-hanok"]),
            Wishlist(id: "wl-europe", name: "Europe 2025", listingIDs: ["stay-paris", "stay-amalfi", "stay-santorini", "stay-barcelona", "stay-amsterdam", "stay-dubrovnik"]),
            Wishlist(id: "wl-weekend", name: "Weekend getaways", listingIDs: ["stay-cabin", "stay-tahoe", "stay-hudson", "stay-asheville", "stay-napa"])
        ]

        // Build favorites from all wishlist entries so hearts are consistent
        favorites = []
        for wishlist in wishlists {
            for listingID in wishlist.listingIDs {
                favorites.insert(listingID)
            }
        }
        favorites.insert("exp-seoul-market")

        loadPersistedFavoritesAndWishlists()
    }

    func toggleFavorite(listingId: String) {
        if favorites.contains(listingId) {
            favorites.remove(listingId)
            for i in wishlists.indices {
                wishlists[i].listingIDs.removeAll { $0 == listingId }
            }
        } else {
            favorites.insert(listingId)
            if wishlists.count > 1 {
                showWishlistPicker(for: listingId)
            } else if !wishlists.isEmpty {
                wishlists[0].listingIDs.append(listingId)
            }
        }
        persistFavoritesAndWishlists()
        NotificationCenter.default.post(name: .bnbFavoritesChanged, object: nil)
    }

    func showWishlistPicker(for listingId: String) {
        let alert = UIAlertController(title: "Save to wishlist", message: "Choose a wishlist for this listing", preferredStyle: .actionSheet)
        for wishlist in wishlists {
            let alreadyIn = wishlist.listingIDs.contains(listingId)
            let title = alreadyIn ? "\(wishlist.name) (saved)" : wishlist.name
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self else { return }
                if !alreadyIn {
                    self.addToWishlist(listingId: listingId, wishlistId: wishlist.id)
                }
            })
        }
        alert.addAction(UIAlertAction(title: "New wishlist", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let nameAlert = UIAlertController(title: "New wishlist", message: "Give your wishlist a name", preferredStyle: .alert)
            nameAlert.addTextField { $0.placeholder = "Name" }
            nameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.addToWishlist(listingId: listingId, wishlistId: self?.wishlists.first?.id ?? "")
            })
            nameAlert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
                guard let name = nameAlert.textFields?.first?.text, !name.isEmpty else { return }
                self.createWishlist(name: name)
                if let newWishlist = self.wishlists.last {
                    self.addToWishlist(listingId: listingId, wishlistId: newWishlist.id)
                }
            })
            if let topVC = SfUI.keyRootViewController() {
                var presenter = topVC
                while let presented = presenter.presentedViewController { presenter = presented }
                presenter.present(nameAlert, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            if !self.wishlists.isEmpty {
                self.addToWishlist(listingId: listingId, wishlistId: self.wishlists[0].id)
            }
        })

        if let topVC = SfUI.keyRootViewController() {
            var presenter = topVC
            while let presented = presenter.presentedViewController { presenter = presented }
            presenter.present(alert, animated: true)
        }
    }

    func isFavorite(_ listingId: String) -> Bool {
        favorites.contains(listingId)
    }

    func createWishlist(name: String) {
        let id = "wl-\(wishlists.count + 1)"
        wishlists.append(Wishlist(id: id, name: name, listingIDs: []))
        persistFavoritesAndWishlists()
        NotificationCenter.default.post(name: .bnbFavoritesChanged, object: nil)
    }

    func addToWishlist(listingId: String, wishlistId: String) {
        guard let idx = wishlists.firstIndex(where: { $0.id == wishlistId }) else { return }
        if !wishlists[idx].listingIDs.contains(listingId) {
            wishlists[idx].listingIDs.append(listingId)
        }
        favorites.insert(listingId)
        persistFavoritesAndWishlists()
        NotificationCenter.default.post(name: .bnbFavoritesChanged, object: nil)
    }

    func removeFromWishlist(listingId: String, wishlistId: String) {
        guard let idx = wishlists.firstIndex(where: { $0.id == wishlistId }) else { return }
        wishlists[idx].listingIDs.removeAll { $0 == listingId }
        let stillInAny = wishlists.contains { $0.listingIDs.contains(listingId) }
        if !stillInAny { favorites.remove(listingId) }
        persistFavoritesAndWishlists()
        NotificationCenter.default.post(name: .bnbFavoritesChanged, object: nil)
    }

    func filteredListings(criteria: SearchCriteria, kind: ListingKind) -> [Listing] {
        listings.filter { listing in
            if listing.kind != kind { return false }
            if let category = criteria.category, !listing.categories.contains(category) { return false }
            if !criteria.query.isEmpty {
                let tokens = normalizedSearchTokens(criteria.query)
                let searchableText = normalizedSearchText([
                    listing.title,
                    listing.location,
                    listing.host.name,
                    listing.description,
                    listing.categories.joined(separator: " "),
                    listing.amenities.joined(separator: " ")
                ].joined(separator: " "))
                if !tokens.allSatisfy({ searchableText.contains($0) }) { return false }
            }
            if let minPrice = criteria.minPrice, listing.price < minPrice { return false }
            if let maxPrice = criteria.maxPrice, listing.price > maxPrice { return false }
            if criteria.guests > listing.guests { return false }
            if !criteria.amenities.isEmpty {
                let amenities = Set(listing.amenities.map { $0.lowercased() })
                let needed = Set(criteria.amenities.map { $0.lowercased() })
                if !needed.isSubset(of: amenities) { return false }
            }
            return true
        }
    }

    func addBooking(listingId: String, startDate: Date, endDate: Date, guests: Int) -> Booking {
        let booking = Booking(
            id: UUID().uuidString,
            listingId: listingId,
            startDate: startDate,
            endDate: endDate,
            guests: guests,
            status: .upcoming,
            createdAt: Date()
        )
        bookings.insert(booking, at: 0)
        appendBookingConfirmation(for: booking)
        NotificationCenter.default.post(name: .bnbBookingsChanged, object: nil)
        return booking
    }

    func updateBooking(_ booking: Booking) {
        if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[index] = booking
            NotificationCenter.default.post(name: .bnbBookingsChanged, object: nil)
        }
    }

    func cancelBooking(_ bookingId: String) {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        var booking = bookings[index]
        booking.status = .canceled
        bookings[index] = booking
        NotificationCenter.default.post(name: .bnbBookingsChanged, object: nil)
    }

    func conversation(for listing: Listing) -> Conversation {
        if let index = conversations.firstIndex(where: { $0.listingId == listing.id }) {
            return conversations[index]
        }
        let convo = makeConversation(for: listing)
        conversations.insert(convo, at: 0)
        sortConversations()
        NotificationCenter.default.post(name: .bnbMessagesChanged, object: nil)
        return convo
    }

    func updateConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        sortConversations()
        NotificationCenter.default.post(name: .bnbMessagesChanged, object: nil)
    }

    func markConversationRead(_ conversationID: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = 0
        NotificationCenter.default.post(name: .bnbMessagesChanged, object: nil)
    }

    func generatedHostReply(for conversation: Conversation, guestMessage: String) -> String {
        guard let listing = listing(for: conversation.listingId) else {
            return "Thanks for the note. I’ll follow up here shortly."
        }

        let normalizedMessage = normalizedSearchText(guestMessage)
        let booking = currentBooking(for: conversation.listingId)

        func containsAny(_ phrases: [String]) -> Bool {
            phrases.contains { normalizedMessage.contains($0) }
        }

        func pick(_ options: [String]) -> String {
            var generator = SeededGenerator(seed: stableSeed("\(conversation.id)|\(normalizedMessage)|\(conversation.messages.count)"))
            return generator.pick(options)
        }

        if conversation.category == .support || containsAny(["refund", "cancel", "support"]) {
            return pick([
                "Thanks for checking in. I’ve attached your note to the support thread for \(listing.title), and I’ll message you here as soon as there’s an update.",
                "I’m still tracking this support request for \(listing.title). If the reservation status changes or we need anything else from you, I’ll follow up here right away."
            ])
        }

        if containsAny(["confirm", "confirmation", "booked", "booking", "reservation"]), let booking {
            return pick(bookingConfirmationOptions(for: listing, booking: booking))
        }

        if containsAny(["check in", "checkin", "arrival", "arrive", "late", "early", "luggage", "bag", "drop", "code"]) {
            return pick(arrivalReplyOptions(for: listing, booking: booking))
        }

        if containsAny(["parking", "park", "car", "garage"]) {
            return pick(parkingReplyOptions(for: listing))
        }

        if containsAny(["wifi", "internet", "workspace", "work"]) {
            return pick(connectivityReplyOptions(for: listing))
        }

        if containsAny(["guest", "guests", "party", "group", "bring", "dress", "allergy", "diet", "menu"]) {
            return pick(preparationReplyOptions(for: listing, booking: booking))
        }

        return pick(generalReplyOptions(for: listing, booking: booking))
    }

    func listing(for id: String) -> Listing? {
        listings.first { $0.id == id }
    }

    func listings(withIDs ids: [String]) -> [Listing] {
        return ids.compactMap { id in
            listing(for: id)
        }
    }

    func upcomingBookings() -> [Booking] {
        return bookings
            .filter { $0.status == .upcoming }
            .sorted { $0.startDate < $1.startDate }
    }

    func pastBookings() -> [Booking] {
        return bookings
            .filter { $0.status != .upcoming }
            .sorted { $0.startDate > $1.startDate }
    }

    private func makeConversation(for listing: Listing) -> Conversation {
        let intro = Message(
            id: UUID().uuidString,
            text: defaultIntroMessage(for: listing),
            isHost: true,
            timestamp: Date()
        )
        return Conversation(
            id: UUID().uuidString,
            listingId: listing.id,
            hostName: listing.host.name,
            title: "\(listing.host.name) and \(listing.title)",
            tripSummary: tripSummary(for: listing, booking: currentBooking(for: listing.id)),
            category: .traveling,
            unreadCount: 0,
            messages: [intro]
        )
    }

    private func appendBookingConfirmation(for booking: Booking) {
        guard let listing = listing(for: booking.listingId) else { return }

        var conversation = conversations.first(where: { $0.listingId == listing.id }) ?? makeConversation(for: listing)
        if !conversations.contains(where: { $0.id == conversation.id }) {
            conversations.insert(conversation, at: 0)
        }

        let confirmation = bookingConfirmationOptions(for: listing, booking: booking).first ?? "Your booking is confirmed."
        guard !conversation.messages.contains(where: { $0.isHost && $0.text == confirmation }) else { return }

        conversation.messages.append(
            Message(
                id: UUID().uuidString,
                text: confirmation,
                isHost: true,
                timestamp: Date()
            )
        )
        updateConversation(conversation)
    }

    private func currentBooking(for listingId: String) -> Booking? {
        if let upcoming = bookings
            .filter({ $0.listingId == listingId && $0.status == .upcoming })
            .sorted(by: { $0.startDate < $1.startDate })
            .first {
            return upcoming
        }

        return bookings
            .filter { $0.listingId == listingId }
            .sorted {
                if $0.createdAt == $1.createdAt {
                    return $0.startDate > $1.startDate
                }
                return $0.createdAt > $1.createdAt
            }
            .first
    }

    private func defaultIntroMessage(for listing: Listing) -> String {
        switch listing.kind {
        case .stay:
            return "Hi, thanks for reaching out about \(listing.title). I can help with check-in details, arrival timing, and local tips."
        case .experience:
            return "Hi, thanks for reaching out about \(listing.title). I’m happy to help with timing, meeting point details, or what to bring."
        case .service:
            return "Hi, thanks for reaching out about \(listing.title). I can help with timing, preferences, and prep details."
        }
    }

    private func tripSummary(for listing: Listing, booking: Booking?) -> String {
        guard let booking else { return listing.location }
        switch listing.kind {
        case .stay:
            return "\(bookingDateRangeString(start: booking.startDate, end: booking.endDate)) · \(listing.location)"
        case .experience, .service:
            return "\(shortMonthDayString(from: booking.startDate)) · \(listing.location)"
        }
    }

    private func bookingConfirmationOptions(for listing: Listing, booking: Booking) -> [String] {
        let guestText = guestCountString(booking.guests)

        switch booking.status {
        case .canceled:
            return [
                "I’m sorry that booking was canceled. If your plans shift again, send me a note here and I can help with next steps."
            ]
        case .completed:
            return [
                "Thanks again for booking \(listing.title). I hope everything went smoothly, and I’m happy to help with anything post-trip."
            ]
        case .upcoming:
            switch listing.kind {
            case .stay:
                let detailsLine = hasAmenity("check-in", in: listing)
                    ? "Self check-in is available, so I’ll send the code and entry steps closer to arrival."
                    : "I’ll message you with arrival details before check-in."
                return [
                    "You’re all set for \(bookingDateRangeString(start: booking.startDate, end: booking.endDate)) at \(listing.title) for \(guestText). \(detailsLine)",
                    "Confirmed for \(bookingDateRangeString(start: booking.startDate, end: booking.endDate)) at \(listing.title) for \(guestText). \(detailsLine)"
                ]
            case .experience:
                return [
                    "Your spot for \(listing.title) on \(shortMonthDayString(from: booking.startDate)) is confirmed for \(guestText). I’ll send the meeting point and timing before we start.",
                    "You’re booked for \(listing.title) on \(shortMonthDayString(from: booking.startDate)) for \(guestText). I’ll follow up with the exact meetup details before the experience."
                ]
            case .service:
                return [
                    "Your \(listing.title) booking is confirmed for \(shortMonthDayString(from: booking.startDate)) for \(guestText). I’ll follow up with timing and prep details here.",
                    "Confirmed for \(listing.title) on \(shortMonthDayString(from: booking.startDate)) for \(guestText). I’ll message you soon with the arrival window and any prep notes."
                ]
            }
        }
    }

    private func arrivalReplyOptions(for listing: Listing, booking: Booking?) -> [String] {
        switch listing.kind {
        case .stay:
            let bookingLine = booking.map {
                "for \(bookingDateRangeString(start: $0.startDate, end: $0.endDate))"
            } ?? "for your stay"
            let entryLine = hasAmenity("check-in", in: listing)
                ? "Self check-in is available, and I’ll send the code before arrival."
                : "I’ll message you with the arrival steps before check-in."
            let parkingLine = hasAmenity("parking", in: listing)
                ? "Parking is available at the property."
                : "Street parking nearby is usually the easiest option."
            return [
                "You should be in good shape \(bookingLine). \(entryLine) \(parkingLine)",
                "\(entryLine) If your timing changes \(bookingLine), send me a note here and I’ll keep the arrival details aligned. \(parkingLine)"
            ]
        case .experience:
            let dateLine = booking.map { "before \(shortMonthDayString(from: $0.startDate))" } ?? "before the experience starts"
            return [
                "I’ll send the exact meeting point and timing \(dateLine). Comfortable shoes and a water bottle are usually the best call.",
                "Arrival is straightforward for \(listing.title). I’ll message you with the meetup landmark and timing \(dateLine)."
            ]
        case .service:
            let dateLine = booking.map { "before \(shortMonthDayString(from: $0.startDate))" } ?? "before the service"
            return [
                "I’ll confirm the arrival window and any setup details \(dateLine). If your timing shifts, send it here and I’ll work around it.",
                "Thanks for the heads up. I’ll message you with the arrival timing and setup notes \(dateLine) so everything feels easy."
            ]
        }
    }

    private func parkingReplyOptions(for listing: Listing) -> [String] {
        switch listing.kind {
        case .stay:
            if hasAmenity("parking", in: listing) {
                return [
                    "Yes, parking is available for \(listing.title), and I’ll send the exact arrival note before you head over.",
                    "Parking is included at the stay. I’ll share the easiest arrival route and where to pull in before check-in."
                ]
            }
            return [
                "There isn’t dedicated on-site parking listed for \(listing.title), but nearby street parking is usually the simplest option.",
                "I don’t have a dedicated garage to promise here, but nearby street parking is normally the easiest arrival plan."
            ]
        case .experience, .service:
            return [
                "There isn’t host-managed parking for this booking, so rideshare or nearby public parking is usually the best plan. I can send the closest landmark before you arrive.",
                "I’d plan on nearby public parking or rideshare for this one, and I can message the easiest drop-off point before you head over."
            ]
        }
    }

    private func connectivityReplyOptions(for listing: Listing) -> [String] {
        let hasWifi = hasAmenity("wifi", in: listing)
        let hasWorkspace = hasAmenity("workspace", in: listing)

        switch listing.kind {
        case .experience:
            return [
                "This experience doesn’t really depend on wifi. The main thing is the meetup details, and I’ll send those ahead of time.",
                "Wifi won’t be important for this experience, but I’ll send the meeting point and timing so you have everything before it starts."
            ]
        case .stay, .service:
            if hasWifi && hasWorkspace {
                return [
                    "Yes, the space has wifi and a workspace setup, so you should be in good shape if you need to log on.",
                    "You’ll have wifi available, and there’s a workspace setup if you need to take a call or get a little work done."
                ]
            }
            if hasWifi {
                return [
                    "Yes, wifi is available throughout the space, so you should be covered.",
                    "You’ll have wifi access during the booking, and I can help with anything else you need before arrival."
                ]
            }
            return [
                "Wifi isn’t listed as a core amenity here, so I wouldn’t want to overpromise on that.",
                "I don’t want to promise a dedicated wifi setup for this one, but I can help with any other arrival details you need."
            ]
        }
    }

    private func preparationReplyOptions(for listing: Listing, booking: Booking?) -> [String] {
        switch listing.kind {
        case .stay:
            if let booking {
                let guestText = guestCountString(booking.guests)
                return [
                    "Your reservation is currently set for \(guestText). If you need to adjust the group size or arrival plan, send me the new details and I’ll confirm what works.",
                    "I have the booking down for \(guestText). If anything changes with the guest count or timing, message me here and I’ll help sort it out."
                ]
            }
            return [
                "If you want to share your guest count or arrival window, I can help with the best next steps for \(listing.title).",
                "Send over any guest-count or arrival questions and I’ll help you line things up for \(listing.title)."
            ]
        case .experience:
            return [
                "Comfortable shoes and a water bottle are usually the safest call. I’ll send a reminder with the meeting point and timing before we start.",
                "For \(listing.title), comfortable shoes and a light layer are usually enough. I’ll send the exact meetup details before the experience."
            ]
        case .service:
            let dateLine = booking.map { "before \(shortMonthDayString(from: $0.startDate))" } ?? "before the booking"
            return [
                "Happy to work around allergies, menu preferences, or timing requests. Send me those details here and I’ll confirm what’s possible \(dateLine).",
                "If you have dietary preferences or setup requests, message them here and I’ll follow up with the best plan \(dateLine)."
            ]
        }
    }

    private func generalReplyOptions(for listing: Listing, booking: Booking?) -> [String] {
        switch listing.kind {
        case .stay:
            let dateLine = booking.map { "before \(bookingDateRangeString(start: $0.startDate, end: $0.endDate))" } ?? "before your stay"
            return [
                "Thanks for the note about \(listing.title). I’m happy to help with arrival details, parking, or neighborhood tips \(dateLine).",
                "Happy to help with anything around \(listing.title). If you need arrival notes, check-in details, or local suggestions, I can keep everything in one thread here."
            ]
        case .experience:
            return [
                "Thanks for checking in about \(listing.title). I’ll make sure you have the timing, meeting point, and what-to-bring notes before it starts.",
                "Happy to help with \(listing.title). I’ll keep the key details here so the meetup and timing are easy to follow."
            ]
        case .service:
            return [
                "Thanks for the note about \(listing.title). I’ll confirm timing and prep details here so the service day feels straightforward.",
                "Happy to help with \(listing.title). I can keep timing, preferences, and setup details organized here before the booking."
            ]
        }
    }

    private func guestCountString(_ guests: Int) -> String {
        guests == 1 ? "1 guest" : "\(guests) guests"
    }

    private func hasAmenity(_ token: String, in listing: Listing) -> Bool {
        listing.amenities.contains { $0.localizedCaseInsensitiveContains(token) }
    }

    private func sortConversations() {
        conversations.sort { $0.lastActivityDate > $1.lastActivityDate }
    }
}

final class SfTabBarController: UITabBarController {
    private var readyActions: [() -> Void] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let explore = UINavigationController(rootViewController: ExploreViewController())
        explore.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "magnifyingglass"), tag: 0)

        let wishlist = UINavigationController(rootViewController: WishlistViewController())
        wishlist.tabBarItem = UITabBarItem(title: "Wishlists", image: UIImage(systemName: "heart"), tag: 1)

        let trips = UINavigationController(rootViewController: TripsViewController())
        trips.tabBarItem = UITabBarItem(title: "Trips", image: UIImage(systemName: "suitcase"), tag: 2)

        let inbox = UINavigationController(rootViewController: InboxViewController())
        inbox.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(systemName: "message"), tag: 3)
        inbox.tabBarItem.badgeValue = SfStore.shared.conversations.contains(where: { $0.unreadCount > 0 }) ? "" : nil

        let profile = UINavigationController(rootViewController: ProfileViewController())
        profile.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.crop.circle"), tag: 4)

        viewControllers = [explore, wishlist, trips, inbox, profile]
        tabBar.tintColor = SfStyle.accent
        tabBar.backgroundColor = .white
        tabBar.unselectedItemTintColor = SfStyle.textSecondary
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = SfStyle.divider.cgColor
        NotificationCenter.default.addObserver(self, selector: #selector(updateMessageBadge), name: .bnbMessagesChanged, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !readyActions.isEmpty else { return }
        let actions = readyActions
        readyActions.removeAll()
        actions.forEach { $0() }
    }

    func performWhenReady(_ action: @escaping () -> Void) {
        if isViewLoaded, view.window != nil {
            action()
            return
        }
        readyActions.append(action)
    }

    @objc private func updateMessageBadge() {
        let hasUnread = SfStore.shared.conversations.contains { $0.unreadCount > 0 }
        viewControllers?[3].tabBarItem.badgeValue = hasUnread ? "" : nil
    }
}

protocol SearchBarViewDelegate: AnyObject {
    func searchBarDidTap(_ searchBar: SearchBarView)
    func searchBarDidTapFilters(_ searchBar: SearchBarView)
}

class TapAccessibleControl: UIControl {
    private let tapProxyButton = UIButton(type: .custom)

    override var isAccessibilityElement: Bool {
        get { false }
        set { tapProxyButton.isAccessibilityElement = newValue }
    }

    override var accessibilityIdentifier: String? {
        get { tapProxyButton.accessibilityIdentifier }
        set {
            super.accessibilityIdentifier = newValue
            tapProxyButton.accessibilityIdentifier = newValue
        }
    }

    override var accessibilityLabel: String? {
        get { tapProxyButton.accessibilityLabel }
        set {
            super.accessibilityLabel = newValue
            tapProxyButton.accessibilityLabel = newValue
        }
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get { tapProxyButton.accessibilityTraits }
        set {
            super.accessibilityTraits = newValue
            tapProxyButton.accessibilityTraits = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureTapProxy()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTapProxy()
    }

    private func configureTapProxy() {
        tapProxyButton.backgroundColor = .clear
        tapProxyButton.translatesAutoresizingMaskIntoConstraints = false
        tapProxyButton.isAccessibilityElement = true
        tapProxyButton.addTarget(self, action: #selector(handleTapProxy), for: .touchUpInside)
        addSubview(tapProxyButton)
        sendSubview(toBack: tapProxyButton)

        NSLayoutConstraint.activate([
            tapProxyButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapProxyButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            tapProxyButton.topAnchor.constraint(equalTo: topAnchor),
            tapProxyButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func handleTapProxy() {
        sendActions(for: .touchUpInside)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        guard let view = hitView else { return nil }
        if let control = view as? UIControl, control !== self, control !== tapProxyButton {
            return control
        }
        return self
    }

    override func accessibilityActivate() -> Bool {
        sendActions(for: .touchUpInside)
        return true
    }
}

final class SearchBarView: TapAccessibleControl {
    weak var delegate: SearchBarViewDelegate?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let filterButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isAccessibilityElement = true
        accessibilityIdentifier = "bnb.explore.searchBar"
        accessibilityTraits = UIAccessibilityTraitButton
        backgroundColor = .white
        layer.cornerRadius = 28
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.03
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 3)

        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = SfStyle.textSecondary
        icon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Start your search"
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityIdentifier = "bnb.explore.searchBar"
        titleLabel.accessibilityTraits = UIAccessibilityTraitStaticText
        titleLabel.accessibilityLabel = titleLabel.text
        accessibilityLabel = titleLabel.text

        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = SfStyle.textSecondary
        subtitleLabel.isHidden = true

        filterButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        filterButton.tintColor = SfStyle.textPrimary
        filterButton.backgroundColor = SfStyle.background
        filterButton.layer.cornerRadius = 16
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        filterButton.isHidden = true

        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 0
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(icon)
        addSubview(labelStack)

        addTarget(self, action: #selector(searchTapped), for: .touchUpInside)

        icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        icon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        labelStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12).isActive = true
        labelStack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        labelStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
    }

    func updateSubtitle(_ text: String) {
        titleLabel.text = text.isEmpty ? "Start your search" : text
        titleLabel.accessibilityLabel = titleLabel.text
        accessibilityLabel = titleLabel.text
    }

    @objc private func searchTapped() {
        delegate?.searchBarDidTap(self)
    }

    @objc private func filterTapped() {
        delegate?.searchBarDidTapFilters(self)
    }
}

final class ChipButton: UIButton {
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? SfStyle.accentSoft : .white
            setTitleColor(isSelected ? SfStyle.accent : SfStyle.textPrimary, for: .normal)
            layer.borderColor = (isSelected ? SfStyle.accent : SfStyle.divider).cgColor
        }
    }

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        setTitleColor(SfStyle.textPrimary, for: .normal)
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = SfStyle.divider.cgColor
        layer.cornerRadius = 14
        contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

final class ListingImageView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        layer.insertSublayer(gradientLayer, at: 0)
        layer.cornerRadius = 18
        layer.masksToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.backgroundColor = UIColor(white: 0, alpha: 0.35)
        titleLabel.layer.cornerRadius = 10
        titleLabel.layer.masksToBounds = true
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(_ image: ListingImage, showsTitle: Bool = false) {
        imageView.image = UIImage(named: image.assetName)
        gradientLayer.colors = image.fallbackColors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        titleLabel.isHidden = !showsTitle
        titleLabel.text = showsTitle ? "  \(image.title)  " : nil
    }
}

final class ListingCardView: TapAccessibleControl {
    private let imageView = ListingImageView()
    private let titleLabel = UILabel()
    private let locationLabel = UILabel()
    private let priceLabel = UILabel()
    private let ratingLabel = UILabel()
    private let heartButton = UIButton(type: .system)

    var onFavoriteToggle: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton
        backgroundColor = .white
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowRadius = 7
        layer.shadowOffset = CGSize(width: 0, height: 4)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        heartButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary

        locationLabel.font = .systemFont(ofSize: 13, weight: .regular)
        locationLabel.textColor = SfStyle.textSecondary

        priceLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        priceLabel.textColor = SfStyle.textPrimary

        ratingLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        ratingLabel.textColor = SfStyle.textPrimary

        heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
        heartButton.tintColor = SfStyle.accent
        heartButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(locationLabel)
        addSubview(priceLabel)
        addSubview(ratingLabel)
        addSubview(heartButton)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            imageView.heightAnchor.constraint(equalToConstant: 180),

            heartButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            heartButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            heartButton.widthAnchor.constraint(equalToConstant: 28),
            heartButton.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),

            locationLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            priceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            ratingLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            ratingLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor)
        ])
    }

    func configure(_ listing: Listing, isFavorite: Bool) {
        if let firstImage = listing.images.first {
            imageView.configure(firstImage)
        }
        titleLabel.text = listing.title
        locationLabel.text = listing.location
        ratingLabel.text = String(format: "%.2f (%d)", listing.rating, listing.reviewCount)
        if listing.kind == .experience {
            priceLabel.text = "From \(listing.price) per person"
        } else if listing.kind == .service {
            priceLabel.text = "From \(listing.price)"
        } else {
            priceLabel.text = "\(listing.price) per night"
        }
        let heartName = isFavorite ? "heart.fill" : "heart"
        heartButton.setImage(UIImage(systemName: heartName), for: .normal)
        accessibilityLabel = listing.title
    }

    @objc private func favoriteTapped() {
        onFavoriteToggle?()
    }
}

final class ExperienceCardView: TapAccessibleControl {
    private let imageView = ListingImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 3)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = SfStyle.textSecondary

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            imageView.heightAnchor.constraint(equalToConstant: 110),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    func configure(_ listing: Listing) {
        if let firstImage = listing.images.first {
            imageView.configure(firstImage)
        }
        titleLabel.text = listing.title
        subtitleLabel.text = "\(listing.location) - \(listing.duration)"
    }
}

final class DarkPillButton: UIButton {
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        layer.cornerRadius = 24
        contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateAppearance()
    }

    private func updateAppearance() {
        backgroundColor = isSelected ? SfStyle.textPrimary : UIColor(white: 0.93, alpha: 1)
        setTitleColor(isSelected ? .white : SfStyle.textPrimary, for: .normal)
    }
}

final class KindTabButton: TapAccessibleControl {
    let kind: ListingKind
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let badgeLabel = UILabel()
    private let underlineView = UIView()

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    init(kind: ListingKind, iconName: String, title: String, showsBadge: Bool) {
        self.kind = kind
        super.init(frame: .zero)

        iconView.image = UIImage(systemName: iconName)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = SfStyle.textPrimary
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        titleLabel.textAlignment = .center

        badgeLabel.text = "NEW"
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor(red: 0.26, green: 0.37, blue: 0.55, alpha: 1)
        badgeLabel.layer.cornerRadius = 14
        badgeLabel.layer.masksToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.isHidden = !showsBadge

        underlineView.backgroundColor = SfStyle.textPrimary
        underlineView.layer.cornerRadius = 2

        let headerRow = UIStackView(arrangedSubviews: [iconView, badgeLabel])
        headerRow.axis = .horizontal
        headerRow.spacing = 8
        headerRow.alignment = .center
        headerRow.distribution = .equalCentering

        let stack = UIStackView(arrangedSubviews: [headerRow, titleLabel, underlineView])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        underlineView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            badgeLabel.widthAnchor.constraint(equalToConstant: 52),
            badgeLabel.heightAnchor.constraint(equalToConstant: 28),
            underlineView.widthAnchor.constraint(equalToConstant: 66),
            underlineView.heightAnchor.constraint(equalToConstant: 5)
        ])

        updateAppearance()
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = UIAccessibilityTraitButton
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAppearance() {
        titleLabel.textColor = isSelected ? SfStyle.textPrimary : SfStyle.textSecondary
        titleLabel.font = .systemFont(ofSize: 16, weight: isSelected ? .semibold : .regular)
        underlineView.isHidden = !isSelected
        iconView.alpha = isSelected ? 1 : 0.65
        iconView.tintColor = isSelected ? SfStyle.textPrimary : SfStyle.textSecondary
    }
}

final class KindSelectorView: UIView {
    private let stack = UIStackView()
    private var buttons: [KindTabButton] = []
    private(set) var selectedKind: ListingKind = .stay

    var onSelectionChanged: ((ListingKind) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        stack.axis = .horizontal
        stack.spacing = 18
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let items: [(ListingKind, String, String, Bool)] = [
            (.stay, "house", "Homes", false),
            (.experience, "sparkles", "Experiences", false),
            (.service, "bell", "Services", false)
        ]

        items.forEach { item in
            let button = KindTabButton(kind: item.0, iconName: item.1, title: item.2, showsBadge: item.3)
            button.addTarget(self, action: #selector(kindTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }

        setSelectedKind(.stay, sendAction: false)
    }

    func setSelectedKind(_ kind: ListingKind, sendAction: Bool = false) {
        selectedKind = kind
        buttons.forEach { $0.isSelected = $0.kind == kind }
        if sendAction {
            onSelectionChanged?(kind)
        }
    }

    @objc private func kindTapped(_ sender: KindTabButton) {
        setSelectedKind(sender.kind, sendAction: true)
    }
}

enum RailListingCardStyle {
    case recent
    case price
    case service
}

final class RailListingCardView: TapAccessibleControl {
    private let imageView = ListingImageView()
    private let heartButton = UIButton(type: .system)
    private let badgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    var onFavoriteToggle: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.numberOfLines = 2

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = SfStyle.textSecondary
        subtitleLabel.numberOfLines = 2

        badgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        badgeLabel.textColor = SfStyle.textPrimary
        badgeLabel.backgroundColor = UIColor(white: 1, alpha: 0.88)
        badgeLabel.layer.cornerRadius = 14
        badgeLabel.layer.masksToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.isHidden = true

        heartButton.tintColor = .white
        heartButton.backgroundColor = UIColor(white: 0, alpha: 0.18)
        heartButton.layer.cornerRadius = 18
        heartButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        heartButton.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        addSubview(heartButton)
        addSubview(badgeLabel)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 240),

            heartButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -14),
            heartButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 14),
            heartButton.widthAnchor.constraint(equalToConstant: 36),
            heartButton.heightAnchor.constraint(equalToConstant: 36),

            badgeLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 12),
            badgeLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 12),
            badgeLabel.heightAnchor.constraint(equalToConstant: 28),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(listing: Listing, style: RailListingCardStyle, isFavorite: Bool) {
        if let firstImage = listing.images.first {
            imageView.configure(firstImage, showsTitle: false)
        }

        titleLabel.text = listing.title
        let ratingText = String(format: "%.2f", listing.rating)
        switch style {
        case .recent:
            let bedLabel = listing.beds == 1 ? "1 bed" : "\(listing.beds) beds"
            subtitleLabel.text = "\(listing.location) · \(bedLabel) · ★\(ratingText)"
            configureBadge(for: listing)
        case .price:
            subtitleLabel.text = "\(listing.location) · $\(listing.price) per night · ★\(ratingText)"
            configureBadge(for: listing)
        case .service:
            let priceText: String
            if listing.kind == .service {
                priceText = "\(listing.location) · $\(listing.price) · \(listing.duration)"
            } else {
                priceText = "\(listing.location) · $\(listing.price) per person · \(listing.duration)"
            }
            subtitleLabel.text = priceText
            badgeLabel.isHidden = true
        }

        let heartName = isFavorite ? "heart.fill" : "heart"
        heartButton.setImage(UIImage(systemName: heartName), for: .normal)
        accessibilityLabel = listing.title
    }

    private func configureBadge(for listing: Listing) {
        if listing.rating >= 4.93 {
            badgeLabel.text = "  Guest favorite  "
            badgeLabel.isHidden = false
        } else if listing.price >= 300 && listing.rating >= 4.8 {
            badgeLabel.text = "  Rare find  "
            badgeLabel.isHidden = false
        } else if listing.host.isSuperhost {
            badgeLabel.text = "  Superhost  "
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }

    @objc private func favoriteTapped() {
        onFavoriteToggle?()
    }
}

final class VerticalFeedCardView: TapAccessibleControl {
    private let carousel = ImageCarouselView()
    private let heartButton = UIButton(type: .system)
    private let badgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let locationLabel = UILabel()
    private let priceLabel = UILabel()

    var onFavoriteToggle: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton

        carousel.layer.cornerRadius = 16
        carousel.clipsToBounds = true
        carousel.isUserInteractionEnabled = true
        carousel.translatesAutoresizingMaskIntoConstraints = false

        heartButton.tintColor = .white
        heartButton.backgroundColor = UIColor(white: 0, alpha: 0.18)
        heartButton.layer.cornerRadius = 18
        heartButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        heartButton.translatesAutoresizingMaskIntoConstraints = false

        badgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        badgeLabel.textColor = SfStyle.textPrimary
        badgeLabel.backgroundColor = UIColor(white: 1, alpha: 0.88)
        badgeLabel.layer.cornerRadius = 14
        badgeLabel.layer.masksToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.isHidden = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.numberOfLines = 1

        locationLabel.font = .systemFont(ofSize: 14, weight: .regular)
        locationLabel.textColor = SfStyle.textSecondary
        locationLabel.numberOfLines = 1

        priceLabel.font = .systemFont(ofSize: 14, weight: .regular)
        priceLabel.textColor = SfStyle.textPrimary

        let ratingRow = UIStackView(arrangedSubviews: [titleLabel])
        ratingRow.axis = .horizontal
        ratingRow.spacing = 4

        let infoStack = UIStackView(arrangedSubviews: [ratingRow, locationLabel, priceLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 3
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(carousel)
        addSubview(heartButton)
        addSubview(badgeLabel)
        addSubview(infoStack)

        NSLayoutConstraint.activate([
            carousel.leadingAnchor.constraint(equalTo: leadingAnchor),
            carousel.trailingAnchor.constraint(equalTo: trailingAnchor),
            carousel.topAnchor.constraint(equalTo: topAnchor),
            carousel.heightAnchor.constraint(equalToConstant: 280),

            heartButton.trailingAnchor.constraint(equalTo: carousel.trailingAnchor, constant: -14),
            heartButton.topAnchor.constraint(equalTo: carousel.topAnchor, constant: 14),
            heartButton.widthAnchor.constraint(equalToConstant: 36),
            heartButton.heightAnchor.constraint(equalToConstant: 36),

            badgeLabel.leadingAnchor.constraint(equalTo: carousel.leadingAnchor, constant: 12),
            badgeLabel.topAnchor.constraint(equalTo: carousel.topAnchor, constant: 12),
            badgeLabel.heightAnchor.constraint(equalToConstant: 28),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),

            infoStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            infoStack.topAnchor.constraint(equalTo: carousel.bottomAnchor, constant: 10),
            infoStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(listing: Listing, isFavorite: Bool) {
        carousel.configure(images: listing.images)

        titleLabel.text = listing.title
        let ratingText = String(format: "%.2f", listing.rating)
        locationLabel.text = "\(listing.location) · ★\(ratingText)"
        priceLabel.text = "$\(listing.price) per night"

        if listing.rating >= 4.93 {
            badgeLabel.text = "  Guest favorite  "
            badgeLabel.isHidden = false
        } else if listing.price >= 300 && listing.rating >= 4.8 {
            badgeLabel.text = "  Rare find  "
            badgeLabel.isHidden = false
        } else if listing.host.isSuperhost {
            badgeLabel.text = "  Superhost  "
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }

        let heartName = isFavorite ? "heart.fill" : "heart"
        heartButton.setImage(UIImage(systemName: heartName), for: .normal)
        accessibilityLabel = listing.title
    }

    @objc private func favoriteTapped() {
        onFavoriteToggle?()
    }
}

final class WishlistMosaicCardView: TapAccessibleControl {
    private let photoViews = (0..<4).map { _ in UIImageView() }
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton
        photoViews.forEach { imageView in
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
        }

        let topRow = UIStackView(arrangedSubviews: [photoViews[0], photoViews[1]])
        topRow.axis = .horizontal
        topRow.spacing = 2
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView(arrangedSubviews: [photoViews[2], photoViews[3]])
        bottomRow.axis = .horizontal
        bottomRow.spacing = 2
        bottomRow.distribution = .fillEqually

        let grid = UIStackView(arrangedSubviews: [topRow, bottomRow])
        grid.axis = .vertical
        grid.spacing = 2
        grid.layer.cornerRadius = 16
        grid.layer.masksToBounds = true
        grid.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary

        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = SfStyle.textSecondary

        addSubview(grid)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: trailingAnchor),
            grid.topAnchor.constraint(equalTo: topAnchor),
            grid.heightAnchor.constraint(equalTo: grid.widthAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 10),

            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(images: [ListingImage], title: String, subtitle: String) {
        let resolvedImages: [ListingImage]
        if images.isEmpty {
            resolvedImages = []
        } else {
            resolvedImages = (0..<4).map { images[$0 % images.count] }
        }

        for (index, imageView) in photoViews.enumerated() {
            if index < resolvedImages.count {
                imageView.image = UIImage(named: resolvedImages[index].assetName)
                imageView.backgroundColor = resolvedImages[index].fallbackColors.first ?? UIColor(white: 0.92, alpha: 1)
            } else {
                imageView.image = nil
                imageView.backgroundColor = UIColor(white: 0.88, alpha: 1)
            }
        }

        titleLabel.text = title
        subtitleLabel.text = subtitle
        accessibilityLabel = title
    }
}

final class TripsPlaceholderView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        let line = UIView()
        line.backgroundColor = UIColor(white: 0.88, alpha: 1)
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)

        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 34),
            line.topAnchor.constraint(equalTo: topAnchor, constant: 26),
            line.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -26),
            line.widthAnchor.constraint(equalToConstant: 2)
        ])

        let cards: [(String, String, String)] = [
            ("sf_stay_10", "City loft with easy check-in", "Home · 2 nights · Save to book later"),
            ("sf_exp_3", "Sunset sail on the bay", "Experience · 2.5 hours · Great for couples"),
            ("sf_exp_1", "Private chef dinner setup", "Service · 3 hours · Delivered at your stay")
        ]
        var previousCard: UIView?

        for (index, item) in cards.enumerated() {
            let dot = UIView()
            dot.backgroundColor = UIColor(white: index == 1 ? 0.65 : 0.9, alpha: 1)
            dot.layer.cornerRadius = 10
            dot.translatesAutoresizingMaskIntoConstraints = false
            addSubview(dot)

            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 24
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.03
            card.layer.shadowRadius = 7
            card.layer.shadowOffset = CGSize(width: 0, height: 4)
            card.translatesAutoresizingMaskIntoConstraints = false

            let imageView = UIImageView(image: UIImage(named: item.0))
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 18
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false

            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            titleLabel.textColor = SfStyle.textPrimary
            titleLabel.numberOfLines = 2
            titleLabel.text = item.1

            let subtitleLabel = UILabel()
            subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
            subtitleLabel.textColor = SfStyle.textSecondary
            subtitleLabel.numberOfLines = 0
            subtitleLabel.text = item.2

            let badge = UILabel()
            badge.font = .systemFont(ofSize: 11, weight: .bold)
            badge.textColor = SfStyle.textPrimary
            badge.backgroundColor = UIColor(white: 0.95, alpha: 1)
            badge.layer.cornerRadius = 12
            badge.layer.masksToBounds = true
            badge.text = index == 0 ? "  Stay  " : (index == 1 ? "  Experience  " : "  Service  ")

            let textStack = UIStackView(arrangedSubviews: [badge, titleLabel, subtitleLabel])
            textStack.axis = .vertical
            textStack.spacing = 8
            textStack.alignment = .leading
            textStack.translatesAutoresizingMaskIntoConstraints = false

            addSubview(card)
            card.addSubview(imageView)
            card.addSubview(textStack)

            NSLayoutConstraint.activate([
                dot.centerXAnchor.constraint(equalTo: line.centerXAnchor),
                dot.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                dot.widthAnchor.constraint(equalToConstant: 20),
                dot.heightAnchor.constraint(equalToConstant: 20),

                card.leadingAnchor.constraint(equalTo: line.trailingAnchor, constant: 24),
                card.trailingAnchor.constraint(equalTo: trailingAnchor),
                card.heightAnchor.constraint(equalToConstant: 140),

                imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                imageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                imageView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
                imageView.widthAnchor.constraint(equalToConstant: 128),

                textStack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 18),
                textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
            ])

            if let previousCard = previousCard {
                card.topAnchor.constraint(equalTo: previousCard.bottomAnchor, constant: 20).isActive = true
            } else {
                card.topAnchor.constraint(equalTo: topAnchor).isActive = true
            }

            previousCard = card
        }

        previousCard?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}

final class BookingSummaryCardView: TapAccessibleControl {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.03
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 18

        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.numberOfLines = 2

        dateLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        dateLabel.textColor = SfStyle.textPrimary

        locationLabel.font = .systemFont(ofSize: 15, weight: .regular)
        locationLabel.textColor = SfStyle.textSecondary

        statusLabel.font = .systemFont(ofSize: 12, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 14
        statusLabel.layer.masksToBounds = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel, locationLabel, statusLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        let row = UIStackView(arrangedSubviews: [imageView, textStack])
        row.axis = .horizontal
        row.spacing = 16
        row.alignment = .top
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            imageView.widthAnchor.constraint(equalToConstant: 98),
            imageView.heightAnchor.constraint(equalToConstant: 98),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 84),
            statusLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func configure(listing: Listing, booking: Booking) {
        imageView.image = UIImage(named: listing.images.first?.assetName ?? "")
        titleLabel.text = listing.title
        dateLabel.text = bookingDateRangeString(start: booking.startDate, end: booking.endDate)
        locationLabel.text = listing.location
        accessibilityLabel = listing.title

        switch booking.status {
        case .upcoming:
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: booking.startDate).day ?? 0
            if daysUntil >= 0 && daysUntil <= 7 {
                statusLabel.text = daysUntil == 0 ? "  Arriving today  " : "  Arriving in \(daysUntil) day\(daysUntil == 1 ? "" : "s")  "
                statusLabel.textColor = .white
                statusLabel.backgroundColor = UIColor(red: 0.0, green: 0.6, blue: 0.4, alpha: 1)
            } else {
                statusLabel.text = "  Upcoming  "
                statusLabel.textColor = .white
                statusLabel.backgroundColor = SfStyle.accent
            }
        case .completed:
            statusLabel.text = "  Past trip  "
            statusLabel.textColor = SfStyle.textPrimary
            statusLabel.backgroundColor = UIColor(white: 0.93, alpha: 1)
        case .canceled:
            statusLabel.text = "  Canceled  "
            statusLabel.textColor = SfStyle.textSecondary
            statusLabel.backgroundColor = UIColor(white: 0.9, alpha: 1)
        }
    }
}

final class ConversationThreadView: TapAccessibleControl {
    var conversationID: String?

    private let artworkView = UIImageView()
    private let overlayBubble = UIView()
    private let overlayLabel = UILabel()
    private let titleLabel = UILabel()
    private let previewLabel = UILabel()
    private let tripLabel = UILabel()
    private let dateLabel = UILabel()
    private let unreadDot = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton
        artworkView.contentMode = .scaleAspectFill
        artworkView.clipsToBounds = true
        artworkView.layer.cornerRadius = 20

        overlayBubble.layer.cornerRadius = 24
        overlayBubble.layer.borderColor = UIColor.white.cgColor
        overlayBubble.layer.borderWidth = 3

        overlayLabel.font = .systemFont(ofSize: 16, weight: .bold)
        overlayLabel.textColor = .white
        overlayLabel.textAlignment = .center

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary

        previewLabel.font = .systemFont(ofSize: 15, weight: .regular)
        previewLabel.textColor = SfStyle.textSecondary

        tripLabel.font = .systemFont(ofSize: 14, weight: .regular)
        tripLabel.textColor = SfStyle.textSecondary

        dateLabel.font = .systemFont(ofSize: 15, weight: .regular)
        dateLabel.textColor = SfStyle.textSecondary
        dateLabel.textAlignment = .right

        unreadDot.backgroundColor = SfStyle.accent
        unreadDot.layer.cornerRadius = 5
        unreadDot.isHidden = true

        let bodyStack = UIStackView(arrangedSubviews: [titleLabel, previewLabel, tripLabel])
        bodyStack.axis = .vertical
        bodyStack.spacing = 4

        addSubview(artworkView)
        addSubview(overlayBubble)
        overlayBubble.addSubview(overlayLabel)
        addSubview(bodyStack)
        addSubview(dateLabel)
        addSubview(unreadDot)

        artworkView.translatesAutoresizingMaskIntoConstraints = false
        overlayBubble.translatesAutoresizingMaskIntoConstraints = false
        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyStack.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadDot.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            artworkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            artworkView.topAnchor.constraint(equalTo: topAnchor),
            artworkView.widthAnchor.constraint(equalToConstant: 82),
            artworkView.heightAnchor.constraint(equalToConstant: 82),

            overlayBubble.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: -30),
            overlayBubble.bottomAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: 8),
            overlayBubble.widthAnchor.constraint(equalToConstant: 48),
            overlayBubble.heightAnchor.constraint(equalToConstant: 48),

            overlayLabel.centerXAnchor.constraint(equalTo: overlayBubble.centerXAnchor),
            overlayLabel.centerYAnchor.constraint(equalTo: overlayBubble.centerYAnchor),

            bodyStack.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: 18),
            bodyStack.trailingAnchor.constraint(lessThanOrEqualTo: dateLabel.leadingAnchor, constant: -12),
            bodyStack.topAnchor.constraint(equalTo: topAnchor, constant: 2),

            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            dateLabel.widthAnchor.constraint(equalToConstant: 72),

            unreadDot.trailingAnchor.constraint(equalTo: trailingAnchor),
            unreadDot.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            unreadDot.widthAnchor.constraint(equalToConstant: 10),
            unreadDot.heightAnchor.constraint(equalToConstant: 10),
            bottomAnchor.constraint(greaterThanOrEqualTo: artworkView.bottomAnchor)
        ])
    }

    func configure(conversation: Conversation, listing: Listing?) {
        artworkView.image = UIImage(named: listing?.images.first?.assetName ?? "")
        artworkView.backgroundColor = UIColor(white: 0.92, alpha: 1)

        titleLabel.text = conversation.title
        let lastMessage = conversation.messages.last
        let previewPrefix = (lastMessage?.isHost == false) ? "You: " : ""
        previewLabel.text = "\(previewPrefix)\(lastMessage?.text ?? "")"
        tripLabel.text = conversation.tripSummary
        dateLabel.text = shortSlashDateString(from: conversation.lastActivityDate)
        unreadDot.isHidden = conversation.unreadCount == 0

        if conversation.category == .support {
            overlayBubble.backgroundColor = SfStyle.textPrimary
            overlayLabel.text = "A"
        } else {
            overlayBubble.backgroundColor = listing?.host.avatarColor ?? SfStyle.accent
            overlayLabel.text = String(conversation.hostName.prefix(1))
        }

        accessibilityLabel = conversation.title
    }
}

final class CategoryStripView: UIView {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var selectedCategory: String?
    var onCategorySelected: ((String?) -> Void)?

    private let categoryItems: [(icon: String, title: String)] = [
        ("water.waves", "Beachfront"),
        ("leaf", "Cabins"),
        ("flame", "Trending"),
        ("paintbrush", "Design"),
        ("building.2", "City"),
        ("star", "Guest favorite"),
        ("mountain.2", "Countryside"),
        ("sparkles", "Amazing views"),
        ("drop", "Lakefront"),
        ("sun.max", "Tropical")
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stack.axis = .horizontal
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        for (index, item) in categoryItems.enumerated() {
            let button = makeCategoryButton(icon: item.icon, title: item.title, tag: index)
            stack.addArrangedSubview(button)
        }
    }

    private func makeCategoryButton(icon: String, title: String, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = SfStyle.textSecondary
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = SfStyle.textSecondary
        label.textAlignment = .center

        let underline = UIView()
        underline.backgroundColor = SfStyle.textPrimary
        underline.layer.cornerRadius = 1
        underline.isHidden = true
        underline.translatesAutoresizingMaskIntoConstraints = false
        underline.tag = 100

        let tap = UIButton(type: .custom)
        tap.tag = tag
        tap.translatesAutoresizingMaskIntoConstraints = false
        tap.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)

        let vStack = UIStackView(arrangedSubviews: [iconView, label, underline])
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.alignment = .center
        vStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(vStack)
        container.addSubview(tap)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            underline.widthAnchor.constraint(equalToConstant: 28),
            underline.heightAnchor.constraint(equalToConstant: 2),
            vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vStack.topAnchor.constraint(equalTo: container.topAnchor),
            vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 56),
            tap.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tap.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tap.topAnchor.constraint(equalTo: container.topAnchor),
            tap.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let tapped = categoryItems[sender.tag].title
        if selectedCategory == tapped {
            selectedCategory = nil
        } else {
            selectedCategory = tapped
        }
        updateSelection()
        onCategorySelected?(selectedCategory)
    }

    private func updateSelection() {
        for (index, view) in stack.arrangedSubviews.enumerated() {
            let isSelected = categoryItems[index].title == selectedCategory
            if let vStack = view.subviews.first as? UIStackView {
                if let iconView = vStack.arrangedSubviews.first as? UIImageView {
                    iconView.tintColor = isSelected ? SfStyle.textPrimary : SfStyle.textSecondary
                }
                if let label = vStack.arrangedSubviews.dropFirst().first as? UILabel {
                    label.textColor = isSelected ? SfStyle.textPrimary : SfStyle.textSecondary
                    label.font = .systemFont(ofSize: 11, weight: isSelected ? .bold : .medium)
                }
                if let underline = vStack.viewWithTag(100) {
                    underline.isHidden = !isSelected
                }
            }
        }
    }

    func clearSelection() {
        selectedCategory = nil
        updateSelection()
    }
}

final class ExploreViewController: UIViewController, SearchBarViewDelegate, SearchPanelDelegate {
    private let store = SfStore.shared
    private var criteria = SearchCriteria()
    private var selectedKind: ListingKind = .stay
    private var railSections: [(title: String, listings: [Listing])] = []

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let searchBar = SearchBarView()
    private let categoryStrip = CategoryStripView()
    private let kindSelector = KindSelectorView()
    private let sectionsStack = UIStackView()
    private let mapButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SfStyle.background
        configureLayout()
        refreshContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func configureLayout() {
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        categoryStrip.translatesAutoresizingMaskIntoConstraints = false
        categoryStrip.onCategorySelected = { [weak self] category in
            self?.criteria.category = category
            self?.refreshContent()
        }

        kindSelector.translatesAutoresizingMaskIntoConstraints = false
        kindSelector.onSelectionChanged = { [weak self] kind in
            self?.selectedKind = kind
            self?.categoryStrip.clearSelection()
            self?.criteria.category = nil
            self?.refreshContent()
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        sectionsStack.axis = .vertical
        sectionsStack.spacing = 32
        sectionsStack.translatesAutoresizingMaskIntoConstraints = false

        mapButton.setTitle("  Map  ", for: .normal)
        mapButton.setImage(UIImage(systemName: "map"), for: .normal)
        mapButton.tintColor = .white
        mapButton.backgroundColor = SfStyle.textPrimary
        mapButton.layer.cornerRadius = 22
        mapButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        mapButton.translatesAutoresizingMaskIntoConstraints = false
        mapButton.accessibilityIdentifier = "bnb.explore.map"
        mapButton.addTarget(self, action: #selector(showMap), for: .touchUpInside)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(mapButton)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),

            mapButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mapButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            mapButton.heightAnchor.constraint(equalToConstant: 44),
            mapButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])

        contentStack.addArrangedSubview(searchBar)
        searchBar.heightAnchor.constraint(equalToConstant: 62).isActive = true

        contentStack.addArrangedSubview(categoryStrip)
        categoryStrip.heightAnchor.constraint(equalToConstant: 58).isActive = true

        contentStack.addArrangedSubview(kindSelector)
        kindSelector.heightAnchor.constraint(equalToConstant: 118).isActive = true

        contentStack.addArrangedSubview(sectionsStack)
    }

    @objc private func showMap() {
        let filtered = store.filteredListings(criteria: criteria, kind: selectedKind)
        let mapVC = MapViewController(listings: filtered)
        navigationController?.pushViewController(mapVC, animated: true)
    }

    private func refreshContent() {
        sectionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        railSections = []

        let filtered = store.filteredListings(criteria: criteria, kind: selectedKind)
            .sorted {
                if $0.rating == $1.rating {
                    return $0.reviewCount > $1.reviewCount
                }
                return $0.rating > $1.rating
            }

        if hasActiveSearchFilters {
            populateSearchResults(using: filtered)
        } else {
            populateDefaultSections()
        }

        if sectionsStack.arrangedSubviews.isEmpty {
            let label = UILabel()
            label.font = .systemFont(ofSize: 20, weight: .semibold)
            label.textColor = SfStyle.textSecondary
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = hasActiveSearchFilters ? "No places match this search. Try a broader destination or fewer guests." : "Nothing featured yet."
            sectionsStack.addArrangedSubview(label)
        }

        updateSearchSummary()
    }

    private var hasActiveSearchFilters: Bool {
        return !criteria.query.isEmpty ||
            criteria.guests != 1 ||
            criteria.startDate != nil ||
            criteria.endDate != nil ||
            criteria.minPrice != nil ||
            criteria.maxPrice != nil ||
            !criteria.amenities.isEmpty ||
            criteria.category != nil
    }

    private func populateDefaultSections() {
        switch selectedKind {
        case .stay:
            addVerticalSection(title: "Recently viewed", listings: store.listings(withIDs: ["stay-tokyo-nakameguro", "stay-paris-belleville", "stay-nyc-soho"]))
            addRailSection(title: "Coastal escapes", listings: store.listings(withIDs: ["stay-la-malibu", "stay-santorini-oia", "stay-amalfi-positano", "stay-sydney-manly", "stay-canggu-surf", "stay-tulum-beach", "stay-capetown-camps", "stay-maui-wailea", "stay-capecod-provincetown", "stay-miami-coconut", "stay-barcelona-barceloneta", "stay-dubrovnik-lapad"]), style: .price)
            addRailSection(title: "City stays right now", listings: store.listings(withIDs: ["stay-paris-bastille", "stay-london-hackney", "stay-nyc-les", "stay-rome-testaccio", "stay-seoul-hongdae", "stay-tokyo-shinjuku", "stay-berlin-friedrichshain", "stay-sf-mission", "stay-nola-marigny", "stay-barcelona-born", "stay-amsterdam-de-pijp", "stay-cdmx-juarez"]), style: .price)
            addRailSection(title: "Mountain and countryside retreats", listings: store.listings(withIDs: ["stay-tahoe-emerald", "stay-napa-vineyard", "stay-hudson-farmhouse", "stay-bigsur-treehouse", "stay-kyoto-arashiyama", "stay-sedona-red-rock", "stay-joshua-hacienda", "stay-tulum-cenote", "stay-capecod-wellfleet", "stay-ubud-terrace"]), style: .price)
            addRailSection(title: "International getaways", listings: store.listings(withIDs: ["stay-santorini-oia", "stay-marrakech-riad", "stay-kyoto-gion", "stay-ba-palermo", "stay-dubrovnik-old", "stay-reykjavik-old", "stay-capetown-bo-kaap", "stay-chiangmai-old", "stay-hanoi-old-quarter", "stay-hk-sheung-wan", "stay-singapore-joo-chiat", "stay-lima-barranco"]), style: .price)
            addRailSection(title: "New on StayFinder", listings: store.listings(withIDs: ["stay-tokyo-yanaka", "stay-paris-canal", "stay-london-greenwich", "stay-nyc-brooklyn-heights", "stay-seoul-bukchon", "stay-berlin-prenzlauer", "stay-copenhagen-norrebro", "stay-portland-alberta", "stay-nashville-12south", "stay-savannah-jones"]), style: .price)
            addRailSection(title: "Trending this week", listings: store.listings(withIDs: ["stay-austin-south", "stay-nola-marigny", "stay-joshua-dome", "stay-bangkok-ari", "stay-marrakech-riad", "stay-tokyo-koenji", "stay-berlin-wedding", "stay-miami-little-havana", "stay-lisbon-mouraria", "stay-busan-gamcheon"]), style: .price)
            addRailSection(title: "Design picks", listings: store.listings(withIDs: ["stay-santafe-canyon", "stay-portland-pearl", "stay-tokyo-daikanyama", "stay-paris-belleville", "stay-london-marylebone", "stay-barcelona-eixample", "stay-rome-aventine", "stay-copenhagen-vesterbro", "stay-cdmx-coyoacan", "stay-charleston-rainbow"]), style: .price)
            addRailSection(title: "Best value stays", listings: store.listings(withIDs: ["stay-chiangmai-riverside", "stay-hanoi-french", "stay-bangkok-chinatown", "stay-lima-barranco", "stay-busan-gamcheon", "stay-berlin-wedding", "stay-lisbon-mouraria", "stay-nola-bywater", "stay-cdmx-coyoacan", "stay-tulum-pueblo"]), style: .price)
        case .experience:
            addRailSection(title: "Food and drink experiences", listings: store.listings(withIDs: ["exp-food", "exp-seoul-market", "exp-pastry", "exp-barcelona-tapas", "exp-berlin-food", "exp-hanoi-street-food", "exp-chiangmai-cook"]), style: .service)
            addRailSection(title: "Outdoor and cultural walks", listings: store.listings(withIDs: ["exp-tokyo-coffee", "exp-sail", "exp-bali-terrace", "exp-kyoto-temple", "exp-edinburgh-whisky", "exp-capetown-wine"]), style: .service)
            addRailSection(title: "Nightlife and music", listings: store.listings(withIDs: ["exp-nola-jazz", "exp-berlin-food"]), style: .service)
        case .service:
            addRailSection(title: "Chef and dining services", listings: store.listings(withIDs: ["service-chef", "service-lisbon-chef", "service-nola-music"]), style: .service)
            addRailSection(title: "Photo, wellness, and more", listings: store.listings(withIDs: ["service-seoul-photo", "service-photo", "service-massage", "service-yoga", "service-tulum-wellness"]), style: .service)
        }
    }

    private func populateSearchResults(using listings: [Listing]) {
        guard !listings.isEmpty else { return }

        let primaryTitle: String
        switch selectedKind {
        case .stay:
            primaryTitle = criteria.query.isEmpty ? "Homes that fit your trip" : "Homes in \(criteria.query)"
        case .experience:
            primaryTitle = criteria.query.isEmpty ? "Experiences that fit your trip" : "Experiences in \(criteria.query)"
        case .service:
            primaryTitle = criteria.query.isEmpty ? "Services that fit your trip" : "Services in \(criteria.query)"
        }

        let resultCountText = listings.count == 1 ? "1 place" : "\(listings.count) places"

        // Show top results as a vertical feed for a proper search experience
        let topResults = Array(listings.prefix(8))
        addVerticalSection(title: "\(primaryTitle) · \(resultCountText)", listings: topResults)

        // Show remaining results in a rail for quick browsing
        let seenIDs = Set(topResults.map { $0.id })
        let moreCandidates = listings.filter { !seenIDs.contains($0.id) }
        guard !moreCandidates.isEmpty else { return }

        let secondaryTitle: String
        switch selectedKind {
        case .stay:
            secondaryTitle = "More top-rated stays"
        case .experience:
            secondaryTitle = "More bookable experiences"
        case .service:
            secondaryTitle = "More services nearby"
        }

        addRailSection(
            title: secondaryTitle,
            listings: Array(moreCandidates.prefix(10)),
            style: selectedKind == .stay ? .price : .service
        )
    }

    private func updateSearchSummary() {
        if criteria.query.isEmpty && criteria.guests == 1 && criteria.startDate == nil && criteria.endDate == nil {
            searchBar.updateSubtitle("")
            return
        }

        let location = criteria.query.isEmpty ? "Anywhere" : criteria.query
        let dateText: String
        if let start = criteria.startDate, let end = criteria.endDate {
            dateText = "\(shortMonthDayString(from: start)) - \(shortMonthDayString(from: end))"
        } else {
            dateText = "Any week"
        }
        let guestLabel = criteria.guests == 1 ? "1 guest" : "\(criteria.guests) guests"
        searchBar.updateSubtitle("\(location) · \(dateText) · \(guestLabel)")
    }

    private func addRailSection(title: String, listings: [Listing], style: RailListingCardStyle) {
        guard !listings.isEmpty else { return }
        let sectionIndex = railSections.count
        railSections.append((title: title, listings: listings))

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 18

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = title

        let arrowButton = makeRoundHeaderButton(symbol: "arrow.right")
        arrowButton.tag = sectionIndex
        arrowButton.accessibilityLabel = "Open \(title)"
        arrowButton.addTarget(self, action: #selector(openRailSection(_:)), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [titleLabel, arrowButton])
        header.axis = .horizontal
        header.alignment = .center
        header.distribution = .equalSpacing
        container.addArrangedSubview(header)

        let railScroll = UIScrollView()
        railScroll.showsHorizontalScrollIndicator = false
        railScroll.translatesAutoresizingMaskIntoConstraints = false

        let railStack = UIStackView()
        railStack.axis = .horizontal
        railStack.spacing = 18
        railStack.translatesAutoresizingMaskIntoConstraints = false

        railScroll.addSubview(railStack)
        NSLayoutConstraint.activate([
            railStack.leadingAnchor.constraint(equalTo: railScroll.contentLayoutGuide.leadingAnchor),
            railStack.trailingAnchor.constraint(equalTo: railScroll.contentLayoutGuide.trailingAnchor),
            railStack.topAnchor.constraint(equalTo: railScroll.contentLayoutGuide.topAnchor),
            railStack.bottomAnchor.constraint(equalTo: railScroll.contentLayoutGuide.bottomAnchor),
            railStack.heightAnchor.constraint(equalTo: railScroll.frameLayoutGuide.heightAnchor)
        ])

        let cardHeight: CGFloat = style == .recent ? 316 : 328
        let cardWidth: CGFloat = style == .recent ? 250 : 300

        listings.forEach { listing in
            let card = RailListingCardView()
            card.configure(listing: listing, style: style, isFavorite: store.isFavorite(listing.id))
            card.accessibilityIdentifier = listing.id
            card.onFavoriteToggle = { [weak self, weak card] in
                self?.store.toggleFavorite(listingId: listing.id)
                card?.configure(listing: listing, style: style, isFavorite: self?.store.isFavorite(listing.id) ?? false)
            }
            card.addTarget(self, action: #selector(railListingTapped(_:)), for: .touchUpInside)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.widthAnchor.constraint(equalToConstant: cardWidth).isActive = true
            railStack.addArrangedSubview(card)
        }

        container.addArrangedSubview(railScroll)
        railScroll.heightAnchor.constraint(equalToConstant: cardHeight).isActive = true
        sectionsStack.addArrangedSubview(container)
    }

    private func addVerticalSection(title: String, listings: [Listing]) {
        guard !listings.isEmpty else { return }
        let sectionIndex = railSections.count
        railSections.append((title: title, listings: listings))

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 24

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = title

        let arrowButton = makeRoundHeaderButton(symbol: "arrow.right")
        arrowButton.tag = sectionIndex
        arrowButton.accessibilityLabel = "Open \(title)"
        arrowButton.addTarget(self, action: #selector(openRailSection(_:)), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [titleLabel, arrowButton])
        header.axis = .horizontal
        header.alignment = .center
        header.distribution = .equalSpacing
        container.addArrangedSubview(header)

        listings.forEach { listing in
            let card = VerticalFeedCardView()
            card.configure(listing: listing, isFavorite: store.isFavorite(listing.id))
            card.accessibilityIdentifier = listing.id
            card.onFavoriteToggle = { [weak self, weak card] in
                self?.store.toggleFavorite(listingId: listing.id)
                card?.configure(listing: listing, isFavorite: self?.store.isFavorite(listing.id) ?? false)
            }
            card.addTarget(self, action: #selector(railListingTapped(_:)), for: .touchUpInside)
            container.addArrangedSubview(card)
        }

        sectionsStack.addArrangedSubview(container)
    }

    private func makeRoundHeaderButton(symbol: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = SfStyle.textPrimary
        button.backgroundColor = UIColor(white: 0.93, alpha: 1)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }

    @objc private func openRailSection(_ sender: UIButton) {
        guard sender.tag >= 0, sender.tag < railSections.count else { return }
        let section = railSections[sender.tag]
        let controller = SectionListingsViewController(titleText: section.title, listings: section.listings)
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func railListingTapped(_ sender: UIControl) {
        guard let listingID = sender.accessibilityIdentifier,
              let listing = store.listing(for: listingID) else { return }
        let detail = ListingDetailViewController(listing: listing)
        navigationController?.pushViewController(detail, animated: true)
    }

    func searchBarDidTap(_ searchBar: SearchBarView) {
        let panel = SearchPanelViewController(criteria: criteria, selectedKind: selectedKind)
        panel.delegate = self
        panel.modalPresentationStyle = .pageSheet
        if #available(iOS 15, *) {
            if let sheet = panel.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(panel, animated: true, completion: nil)
    }

    func searchBarDidTapFilters(_ searchBar: SearchBarView) {
        searchBarDidTap(searchBar)
    }

    func searchPanel(_ panel: SearchPanelViewController, didApply criteria: SearchCriteria, kind: ListingKind) {
        self.criteria = criteria
        selectedKind = kind
        kindSelector.setSelectedKind(kind, sendAction: false)
        refreshContent()
    }

    func presentSearchPanelForTesting() {
        searchBarDidTap(searchBar)
    }

    func openListingForTesting(_ listingID: String) {
        guard let listing = store.listing(for: listingID) else { return }
        let detail = ListingDetailViewController(listing: listing)
        navigationController?.pushViewController(detail, animated: false)
    }

    func openBookingForTesting(_ listingID: String) {
        guard let listing = store.listing(for: listingID) else { return }
        let booking = BookingViewController(listing: listing)
        navigationController?.pushViewController(booking, animated: false)
    }

    func openCheckoutForTesting(_ listingID: String) {
        guard let listing = store.listing(for: listingID),
              let navigationController = navigationController else { return }
        let booking = BookingViewController(listing: listing)
        booking.openCheckoutForTesting()
        navigationController.pushViewController(booking, animated: false)
    }
}

// MARK: - Map View

final class ListingAnnotation: MKPointAnnotation {
    let listing: Listing
    init(listing: Listing) {
        self.listing = listing
        super.init()
    }
}

final class MapViewController: UIViewController, MKMapViewDelegate {
    private let listings: [Listing]
    private let mapView = MKMapView()
    private let store = SfStore.shared

    private static let locationCoordinates: [String: (lat: Double, lon: Double)] = [
        "San Francisco, CA": (37.7749, -122.4194),
        "Catalina Island, CA": (33.3870, -118.4160),
        "Big Sur, CA": (36.2704, -121.8081),
        "Sequoia, CA": (36.4864, -118.5658),
        "Carmel Valley, CA": (36.4174, -121.7327),
        "Avalon, CA": (33.3428, -118.3287),
        "Monterey Bay, CA": (36.6002, -121.8947),
        "Seoul, South Korea": (37.5665, 126.9780),
        "Tokyo, Japan": (35.6762, 139.6503),
        "Lisbon, Portugal": (38.7223, -9.1393),
        "Lake Tahoe, CA": (39.0968, -120.0324),
        "Joshua Tree, CA": (34.1347, -116.3131),
        "Savannah, GA": (32.0809, -81.0912),
        "Austin, TX": (30.2672, -97.7431),
        "Portland, OR": (45.5152, -122.6784),
        "Miami Beach, FL": (25.7907, -80.1300),
        "Napa Valley, CA": (38.5025, -122.2654),
        "Santa Fe, NM": (35.6870, -105.9378),
        "Hudson Valley, NY": (41.7004, -73.9310),
        "Cape Cod, MA": (41.6688, -70.2962),
        "Barcelona, Spain": (41.3874, 2.1686),
        "Barcelona, ES": (41.3874, 2.1686),
        "Amsterdam, Netherlands": (52.3676, 4.9041),
        "Ubud, Bali": (-8.5069, 115.2625),
        "Kyoto, Japan": (35.0116, 135.7681),
        "Marrakech, Morocco": (31.6295, -7.9811),
        "Copenhagen, Denmark": (55.6761, 12.5683),
        "Buenos Aires, Argentina": (-34.6037, -58.3816),
        "Dubrovnik, Croatia": (42.6507, 18.0944),
        "Amalfi Coast, Italy": (40.6340, 14.6027),
        "Reykjavik, Iceland": (64.1466, -21.9426),
        "Bangkok, Thailand": (13.7563, 100.5018),
        "Santorini, Greece": (36.3932, 25.4615),
        "Carmel-by-the-Sea, CA": (36.5554, -121.9233)
    ]

    init(listings: [Listing]) {
        self.listings = listings
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        view.backgroundColor = .white
        configureLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func configureLayout() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.showsScale = true
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add listing annotations
        var annotations: [ListingAnnotation] = []
        for listing in listings.prefix(30) {
            let coord = MapViewController.coordinateForListing(listing)
            let annotation = ListingAnnotation(listing: listing)
            annotation.coordinate = CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lon)
            annotation.title = listing.title
            annotation.subtitle = "$\(listing.price)/night"
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)

        // Fit map to show all pins
        if !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: false)
        }

        // Results count pill overlay
        let countPill = UILabel()
        countPill.text = "  \(listings.count) stays  "
        countPill.font = .systemFont(ofSize: 14, weight: .semibold)
        countPill.textColor = .white
        countPill.backgroundColor = UIColor(white: 0.15, alpha: 0.9)
        countPill.layer.cornerRadius = 18
        countPill.layer.masksToBounds = true
        countPill.textAlignment = .center
        countPill.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(countPill)

        NSLayoutConstraint.activate([
            countPill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countPill.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            countPill.heightAnchor.constraint(equalToConstant: 36)
        ])

        // Back button with white fill for readability on map
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = SfStyle.textPrimary
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        backButton.layer.cornerRadius = 20
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOpacity = 0.15
        backButton.layer.shadowRadius = 4
        backButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private static func coordinateForListing(_ listing: Listing) -> (lat: Double, lon: Double) {
        if let coord = locationCoordinates[listing.location] {
            // Add small jitter so pins don't stack
            var rng = SeededGenerator(seed: stableSeed(listing.id))
            let latJitter = Double(rng.next() % 1000) / 100000.0 - 0.005
            let lonJitter = Double(rng.next() % 1000) / 100000.0 - 0.005
            return (coord.lat + latJitter, coord.lon + lonJitter)
        }
        // Fallback: deterministic position near San Francisco
        var rng = SeededGenerator(seed: stableSeed(listing.id))
        let lat = 37.0 + Double(rng.next() % 3000) / 1000.0
        let lon = -123.0 + Double(rng.next() % 2000) / 1000.0
        return (lat, lon)
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let listing = (annotation as? ListingAnnotation)?.listing else { return nil }

        let reuseID = "PricePill"
        var av = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        if av == nil {
            av = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            av?.canShowCallout = true
        } else {
            av?.annotation = annotation
        }

        // Render price pill as annotation image
        let pill = UILabel()
        pill.text = " $\(listing.price) "
        pill.font = .systemFont(ofSize: 13, weight: .bold)
        pill.textColor = .white
        pill.backgroundColor = SfStyle.accent
        pill.layer.cornerRadius = 14
        pill.layer.masksToBounds = true
        pill.textAlignment = .center
        pill.sizeToFit()

        let size = CGSize(width: max(pill.bounds.width + 16, 50), height: 28)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        pill.frame = CGRect(origin: .zero, size: size)
        pill.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        av?.image = image
        av?.centerOffset = CGPoint(x: 0, y: -14)

        let detailButton = UIButton(type: .detailDisclosure)
        detailButton.tintColor = SfStyle.accent
        av?.rightCalloutAccessoryView = detailButton

        return av
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let listingAnnotation = view.annotation as? ListingAnnotation else { return }
        let detail = ListingDetailViewController(listing: listingAnnotation.listing)
        navigationController?.pushViewController(detail, animated: true)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Callout is shown automatically; the user taps the detail disclosure button
        // (calloutAccessoryControlTapped) to open the listing. No immediate push here.
    }
}

protocol SearchPanelDelegate: AnyObject {
    func searchPanel(_ panel: SearchPanelViewController, didApply criteria: SearchCriteria, kind: ListingKind)
}

final class SearchPanelViewController: UIViewController, UITextFieldDelegate {
    weak var delegate: SearchPanelDelegate?

    private var criteria: SearchCriteria
    private var selectedKind: ListingKind
    private var usesDates: Bool

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let footerContainer = UIView()
    private let kindSelector = KindSelectorView()
    private let destinationField = UITextField()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let dateSummaryLabel = UILabel()
    private let guestsStepper = UIStepper()
    private let guestsLabel = UILabel()
    private var footerBottomConstraint: NSLayoutConstraint?

    init(criteria: SearchCriteria, selectedKind: ListingKind) {
        self.criteria = criteria
        self.selectedKind = selectedKind
        self.usesDates = criteria.startDate != nil && criteria.endDate != nil
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        criteria = SearchCriteria()
        selectedKind = .stay
        usesDates = false
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SfStyle.background
        configureLayout()
        registerForKeyboardNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureLayout() {
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.spacing = 16
        topRow.alignment = .top
        topRow.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topRow)

        kindSelector.translatesAutoresizingMaskIntoConstraints = false
        kindSelector.setSelectedKind(selectedKind, sendAction: false)
        kindSelector.onSelectionChanged = { [weak self] kind in
            self?.selectedKind = kind
            self?.updateDatePickerConstraints()
            self?.updateDateSummary()
        }

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = SfStyle.textPrimary
        closeButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        closeButton.layer.cornerRadius = 32
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.accessibilityIdentifier = "bnb.search.close"

        topRow.addArrangedSubview(kindSelector)
        topRow.addArrangedSubview(closeButton)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.backgroundColor = SfStyle.background
        view.addSubview(footerContainer)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let footerButtons = makeFooterButtons()
        footerButtons.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.addSubview(footerButtons)

        footerBottomConstraint = footerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)

        NSLayoutConstraint.activate([
            topRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            topRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            topRow.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 20),
            scrollView.bottomAnchor.constraint(equalTo: footerContainer.topAnchor, constant: -12),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),

            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            footerButtons.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            footerButtons.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            footerButtons.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            footerButtons.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor)
        ])
        footerBottomConstraint?.isActive = true

        contentStack.addArrangedSubview(makeWhereCard())
        contentStack.addArrangedSubview(makeWhenCard())
        contentStack.addArrangedSubview(makeWhoCard())
    }

    private func makeWhereCard() -> UIView {
        let card = roundedCard()

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Where?"

        let searchContainer = UIView()
        searchContainer.layer.cornerRadius = 20
        searchContainer.layer.borderWidth = 1
        searchContainer.layer.borderColor = UIColor(white: 0.65, alpha: 1).cgColor
        searchContainer.translatesAutoresizingMaskIntoConstraints = false

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = SfStyle.textPrimary
        searchIcon.translatesAutoresizingMaskIntoConstraints = false

        destinationField.borderStyle = .none
        destinationField.font = .systemFont(ofSize: 18, weight: .regular)
        destinationField.textColor = SfStyle.textPrimary
        destinationField.placeholder = "Search destinations"
        destinationField.text = criteria.query
        destinationField.returnKeyType = .search
        destinationField.delegate = self
        destinationField.translatesAutoresizingMaskIntoConstraints = false
        destinationField.accessibilityIdentifier = "bnb.search.destinationField"

        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(destinationField)

        NSLayoutConstraint.activate([
            searchContainer.heightAnchor.constraint(equalToConstant: 102),
            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 24),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 30),
            searchIcon.heightAnchor.constraint(equalToConstant: 30),
            destinationField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 18),
            destinationField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -20),
            destinationField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor)
        ])

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        subtitleLabel.textColor = SfStyle.textPrimary
        subtitleLabel.text = "Suggested destinations"

        let suggestionsStack = UIStackView()
        suggestionsStack.axis = .vertical
        suggestionsStack.spacing = 12

        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Nearby", subtitle: "Find what's around you", symbol: "location.north.line", tint: UIColor(red: 0.40, green: 0.60, blue: 0.92, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Seoul", subtitle: "For design apartments, hanoks, and late-night food", symbol: "building.2", tint: UIColor(red: 0.39, green: 0.56, blue: 0.90, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Tokyo", subtitle: "For compact stays and city experiences", symbol: "tram", tint: UIColor(red: 0.94, green: 0.45, blue: 0.34, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Lisbon", subtitle: "For tiled apartments and in-home dinners", symbol: "sun.max", tint: UIColor(red: 0.84, green: 0.64, blue: 0.30, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Big Sur", subtitle: "For dramatic cliffs and cabins", symbol: "mountain.2", tint: UIColor(red: 0.42, green: 0.61, blue: 0.86, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Paris", subtitle: "For lofts, galleries, and long cafe mornings", symbol: "building.columns", tint: UIColor(red: 0.72, green: 0.42, blue: 0.56, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "New York", subtitle: "For brownstones, lofts, and skyline views", symbol: "building.2.crop.circle", tint: UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Rome", subtitle: "For terraces, trattorias, and ancient streets", symbol: "theatermasks", tint: UIColor(red: 0.84, green: 0.52, blue: 0.28, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Bali", subtitle: "For villas, rice terraces, and surf breaks", symbol: "leaf", tint: UIColor(red: 0.30, green: 0.68, blue: 0.48, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Berlin", subtitle: "For gallery lofts, canals, and street food", symbol: "paintbrush", tint: UIColor(red: 0.52, green: 0.62, blue: 0.38, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "London", subtitle: "For terrace flats, markets, and warehouse lofts", symbol: "crown", tint: UIColor(red: 0.44, green: 0.44, blue: 0.50, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Barcelona", subtitle: "For Gothic Quarter balconies and tapas crawls", symbol: "sun.haze", tint: UIColor(red: 0.90, green: 0.52, blue: 0.28, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Tulum", subtitle: "For beachfront palapas and jungle treehouses", symbol: "beach.umbrella", tint: UIColor(red: 0.22, green: 0.68, blue: 0.72, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Cape Town", subtitle: "For ocean villas and winelands tasting", symbol: "mountain.2.fill", tint: UIColor(red: 0.78, green: 0.48, blue: 0.32, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "New Orleans", subtitle: "For shotgun houses, jazz, and courtyard suites", symbol: "music.note", tint: UIColor(red: 0.58, green: 0.32, blue: 0.68, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Chiang Mai", subtitle: "For teak houses, temples, and cooking classes", symbol: "flame", tint: UIColor(red: 0.40, green: 0.72, blue: 0.58, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Nashville", subtitle: "For live music, hot chicken, and loft stays", symbol: "guitars", tint: UIColor(red: 0.84, green: 0.64, blue: 0.28, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Maui", subtitle: "For surf cottages and ocean suites", symbol: "water.waves", tint: UIColor(red: 0.30, green: 0.60, blue: 0.85, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Edinburgh", subtitle: "For castle views, whisky bars, and garden flats", symbol: "building", tint: UIColor(red: 0.44, green: 0.58, blue: 0.82, alpha: 1)))
        suggestionsStack.addArrangedSubview(makeSuggestionRow(title: "Sedona", subtitle: "For red rock views and desert hot tubs", symbol: "sparkles", tint: UIColor(red: 0.86, green: 0.48, blue: 0.30, alpha: 1)))

        let stack = UIStackView(arrangedSubviews: [titleLabel, searchContainer, subtitleLabel, suggestionsStack])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])

        return card
    }

    private func makeWhenCard() -> UIView {
        let card = roundedCard()

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 22, weight: .medium)
        titleLabel.textColor = SfStyle.textSecondary
        titleLabel.text = "When"

        dateSummaryLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        dateSummaryLabel.textColor = SfStyle.textPrimary

        startDatePicker.datePickerMode = .date
        endDatePicker.datePickerMode = .date
        startDatePicker.accessibilityIdentifier = "bnb.search.startDate"
        endDatePicker.accessibilityIdentifier = "bnb.search.endDate"
        startDatePicker.addTarget(self, action: #selector(datesChanged), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(datesChanged), for: .valueChanged)
        let today = Calendar.current.startOfDay(for: Date())
        startDatePicker.minimumDate = today
        startDatePicker.date = criteria.startDate ?? today
        endDatePicker.date = criteria.endDate ?? dateByAddingDays(selectedKind == .stay ? 1 : 0, to: startDatePicker.date)
        updateDatePickerConstraints()
        updateDateSummary()

        let labelRow = UIStackView(arrangedSubviews: [titleLabel, dateSummaryLabel])
        labelRow.axis = .horizontal
        labelRow.distribution = .equalSpacing

        let pickers = UIStackView(arrangedSubviews: [startDatePicker, endDatePicker])
        pickers.axis = .horizontal
        pickers.spacing = 12
        pickers.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [labelRow, pickers])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    private func makeWhoCard() -> UIView {
        let card = roundedCard()

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 22, weight: .medium)
        titleLabel.textColor = SfStyle.textSecondary
        titleLabel.text = "Who"

        guestsLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        guestsLabel.textColor = SfStyle.textPrimary
        guestsLabel.text = criteria.guests == 1 ? "Add guests" : "\(criteria.guests) guests"

        guestsStepper.minimumValue = 1
        guestsStepper.maximumValue = 10
        guestsStepper.value = Double(criteria.guests)
        guestsStepper.addTarget(self, action: #selector(guestsChanged), for: .valueChanged)
        guestsStepper.accessibilityIdentifier = "bnb.search.guestsStepper"

        let row = UIStackView(arrangedSubviews: [titleLabel, guestsLabel, guestsStepper])
        row.axis = .horizontal
        row.spacing = 16
        row.alignment = .center
        row.distribution = .equalSpacing
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28)
        ])

        return card
    }

    private func makeFooterButtons() -> UIView {
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear all", for: .normal)
        clearButton.setTitleColor(SfStyle.textPrimary, for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        clearButton.contentHorizontalAlignment = .left
        clearButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        let searchButton = UIButton(type: .system)
        searchButton.setTitle("Search", for: .normal)
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        searchButton.backgroundColor = SfStyle.accent
        searchButton.layer.cornerRadius = 24
        searchButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.accessibilityIdentifier = "bnb.search.apply"
        searchButton.widthAnchor.constraint(equalToConstant: 168).isActive = true
        searchButton.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let row = UIStackView(arrangedSubviews: [clearButton, UIView(), searchButton])
        row.axis = .horizontal
        row.alignment = .center
        return row
    }

    private func makeSuggestionRow(title: String, subtitle: String, symbol: String, tint: UIColor) -> UIControl {
        let control = TapAccessibleControl()
        control.isAccessibilityElement = true
        control.accessibilityIdentifier = "bnb.search.suggestion.\(suggestionSlug(for: title))"
        control.accessibilityLabel = title
        control.accessibilityTraits = UIAccessibilityTraitButton
        control.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

        let iconBackground = UIView()
        iconBackground.backgroundColor = tint.withAlphaComponent(0.12)
        iconBackground.layer.cornerRadius = 20

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = title

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = SfStyle.textSecondary
        subtitleLabel.text = subtitle

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [iconBackground, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 16
        row.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(row)
        iconBackground.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            row.topAnchor.constraint(equalTo: control.topAnchor),
            row.bottomAnchor.constraint(equalTo: control.bottomAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 74),
            iconBackground.heightAnchor.constraint(equalToConstant: 74),
            icon.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 30),
            icon.heightAnchor.constraint(equalToConstant: 30)
        ])

        return control
    }

    private func suggestionSlug(for title: String) -> String {
        return title.lowercased()
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "-")
    }

    private func roundedCard() -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.03
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        return view
    }

    @objc private func suggestionTapped(_ sender: UIControl) {
        let suggestion = sender.accessibilityLabel ?? ""
        destinationField.text = suggestion == "Nearby" ? "San Francisco" : suggestion
        performApply()
    }

    @objc private func guestsChanged() {
        let value = Int(guestsStepper.value)
        guestsLabel.text = value == 1 ? "1 guest" : "\(value) guests"
    }

    @objc private func datesChanged() {
        usesDates = true
        updateDatePickerConstraints()
        updateDateSummary()
    }

    @objc private func closeTapped() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }

    @objc private func resetTapped() {
        criteria = SearchCriteria()
        selectedKind = .stay
        usesDates = false
        destinationField.text = ""
        guestsStepper.value = 1
        guestsLabel.text = "Add guests"
        let today = Calendar.current.startOfDay(for: Date())
        startDatePicker.date = today
        endDatePicker.date = dateByAddingDays(1, to: today)
        updateDatePickerConstraints()
        updateDateSummary()
        kindSelector.setSelectedKind(.stay, sendAction: false)
    }

    @objc private func applyTapped() {
        performApply()
    }

    private func performApply() {
        view.endEditing(true)
        criteria.query = (destinationField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        destinationField.text = criteria.query
        criteria.guests = Int(guestsStepper.value)
        updateDatePickerConstraints()
        if usesDates {
            criteria.startDate = startDatePicker.date
            criteria.endDate = endDatePicker.date
        } else {
            criteria.startDate = nil
            criteria.endDate = nil
        }
        criteria.minPrice = nil
        criteria.maxPrice = nil
        criteria.amenities = []
        delegate?.searchPanel(self, didApply: criteria, kind: selectedKind)
        dismiss(animated: true, completion: nil)
    }

    private func updateDateSummary() {
        if usesDates {
            dateSummaryLabel.text = "\(shortMonthDayString(from: startDatePicker.date)) - \(shortMonthDayString(from: endDatePicker.date))"
        } else {
            dateSummaryLabel.text = "Add dates"
        }
    }

    private func updateDatePickerConstraints() {
        let minimumStayDays = selectedKind == .stay ? 1 : 0
        let minimumEndDate = dateByAddingDays(minimumStayDays, to: startDatePicker.date)
        endDatePicker.minimumDate = minimumEndDate
        if endDatePicker.date < minimumEndDate {
            endDatePicker.date = minimumEndDate
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        performApply()
        return true
    }

    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardFrameChange(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardFrameChange(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }

        let endFrame = view.convert(frameValue.cgRectValue, from: nil)
        let overlap = max(0, view.bounds.maxY - endFrame.minY - view.safeAreaInsets.bottom)
        footerBottomConstraint?.constant = -(16 + overlap)

        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let animationCurveRaw = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 7
        let animationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw << 16)

        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

final class ListingDetailViewController: UIViewController {
    private let listing: Listing
    private let store = SfStore.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let carousel = ImageCarouselView()
    private let reserveBar = ReserveBarView()

    init(listing: Listing) {
        self.listing = listing
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "bnb.detail.screen"
        view.backgroundColor = .white
        title = listing.location
        configureLayout()
        configureNavBarButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 20

        view.addSubview(reserveBar)
        reserveBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: reserveBar.topAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            reserveBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reserveBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            reserveBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            reserveBar.heightAnchor.constraint(equalToConstant: 128)
        ])

        // Photo grid for 5+ images, carousel otherwise
        if listing.images.count >= 5 {
            let grid = PhotoGridView(images: listing.images)
            grid.heightAnchor.constraint(equalToConstant: 260).isActive = true
            grid.onTap = { [weak self] _ in
                guard let self = self else { return }
                let fullCarousel = ImageCarouselView()
                fullCarousel.configure(images: self.listing.images)
                let container = UIViewController()
                container.view.backgroundColor = .black
                container.view.addSubview(fullCarousel)
                fullCarousel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    fullCarousel.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
                    fullCarousel.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
                    fullCarousel.centerYAnchor.constraint(equalTo: container.view.centerYAnchor),
                    fullCarousel.heightAnchor.constraint(equalToConstant: 300)
                ])
                self.navigationController?.pushViewController(container, animated: true)
            }
            grid.onShowAll = { [weak grid] in grid?.onTap?(0) }
            contentStack.addArrangedSubview(grid)
        } else {
            carousel.configure(images: listing.images)
            carousel.heightAnchor.constraint(equalToConstant: 260).isActive = true
            contentStack.addArrangedSubview(carousel)
        }

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = listing.title

        let ratingLabel = UILabel()
        ratingLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        ratingLabel.textColor = SfStyle.textSecondary
        ratingLabel.text = String(format: "%.2f (%d reviews)", listing.rating, listing.reviewCount)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, ratingLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4
        contentStack.addArrangedSubview(headerStack)

        // Urgency indicator for stays
        if listing.kind == .stay {
            var urgencyRng = SeededGenerator(seed: stableSeed(listing.id) &+ 77)
            let viewers = Int(urgencyRng.next() % 16) + 3
            let urgencyPill = UILabel()
            urgencyPill.text = "  \(viewers) people are looking at this right now  "
            urgencyPill.font = .systemFont(ofSize: 12, weight: .semibold)
            urgencyPill.textColor = .white
            urgencyPill.backgroundColor = SfStyle.accent
            urgencyPill.layer.cornerRadius = 14
            urgencyPill.layer.masksToBounds = true
            urgencyPill.textAlignment = .center
            urgencyPill.heightAnchor.constraint(equalToConstant: 28).isActive = true
            let urgencyWrapper = UIStackView(arrangedSubviews: [urgencyPill, UIView()])
            urgencyWrapper.axis = .horizontal
            contentStack.addArrangedSubview(urgencyWrapper)
        }

        let detailLabel = UILabel()
        detailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        detailLabel.textColor = SfStyle.textSecondary
        detailLabel.numberOfLines = 0
        detailLabel.text = listing.description
        contentStack.addArrangedSubview(detailLabel)

        let stats = InfoRowView(items: [
            InfoRowView.Item(title: "Guests", value: "\(listing.guests)"),
            InfoRowView.Item(title: "Beds", value: "\(listing.beds)"),
            InfoRowView.Item(title: "Baths", value: "\(listing.baths)")
        ])
        contentStack.addArrangedSubview(stats)

        let hostView = HostView(host: listing.host)
        contentStack.addArrangedSubview(hostView)

        let amenitiesView = AmenitiesView(amenities: listing.amenities)
        amenitiesView.onShowAll = { [weak self] in
            guard let self = self else { return }
            let vc = AllAmenitiesViewController(amenities: self.listing.amenities)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        contentStack.addArrangedSubview(amenitiesView)

        // Mini-map for stays
        if listing.kind == .stay {
            let mapCard = UIView()
            mapCard.backgroundColor = UIColor(red: 0.92, green: 0.94, blue: 0.90, alpha: 1)
            mapCard.layer.cornerRadius = 16
            mapCard.clipsToBounds = true

            let roadOverlay = UIView()
            roadOverlay.backgroundColor = .clear
            roadOverlay.translatesAutoresizingMaskIntoConstraints = false
            mapCard.addSubview(roadOverlay)

            let areaCircle = UIView()
            areaCircle.backgroundColor = SfStyle.accent.withAlphaComponent(0.12)
            areaCircle.layer.cornerRadius = 40
            areaCircle.translatesAutoresizingMaskIntoConstraints = false
            mapCard.addSubview(areaCircle)

            let pin = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
            pin.tintColor = SfStyle.accent
            pin.translatesAutoresizingMaskIntoConstraints = false
            mapCard.addSubview(pin)

            NSLayoutConstraint.activate([
                roadOverlay.leadingAnchor.constraint(equalTo: mapCard.leadingAnchor),
                roadOverlay.trailingAnchor.constraint(equalTo: mapCard.trailingAnchor),
                roadOverlay.topAnchor.constraint(equalTo: mapCard.topAnchor),
                roadOverlay.bottomAnchor.constraint(equalTo: mapCard.bottomAnchor),
                areaCircle.centerXAnchor.constraint(equalTo: mapCard.centerXAnchor),
                areaCircle.centerYAnchor.constraint(equalTo: mapCard.centerYAnchor),
                areaCircle.widthAnchor.constraint(equalToConstant: 80),
                areaCircle.heightAnchor.constraint(equalToConstant: 80),
                pin.centerXAnchor.constraint(equalTo: mapCard.centerXAnchor),
                pin.centerYAnchor.constraint(equalTo: mapCard.centerYAnchor),
                pin.widthAnchor.constraint(equalToConstant: 28),
                pin.heightAnchor.constraint(equalToConstant: 28)
            ])

            let mapTitle = UILabel()
            mapTitle.font = .systemFont(ofSize: 18, weight: .bold)
            mapTitle.textColor = SfStyle.textPrimary
            mapTitle.text = "Where you'll be"

            let mapLocation = UILabel()
            mapLocation.font = .systemFont(ofSize: 14, weight: .regular)
            mapLocation.textColor = SfStyle.textSecondary
            mapLocation.text = listing.location

            let mapSection = UIStackView(arrangedSubviews: [mapTitle, mapCard, mapLocation])
            mapSection.axis = .vertical
            mapSection.spacing = 8
            mapCard.heightAnchor.constraint(equalToConstant: 180).isActive = true

            let mapTap = UITapGestureRecognizer(target: self, action: #selector(miniMapTapped))
            mapCard.addGestureRecognizer(mapTap)
            mapCard.isUserInteractionEnabled = true

            contentStack.addArrangedSubview(mapSection)
        }

        if listing.kind != .stay {
            let sectionTitle = listing.kind == .service ? "What's included" : "What you will do"
            let experience = ExperienceOverviewView(highlights: listing.highlights, duration: listing.duration, titleText: sectionTitle)
            contentStack.addArrangedSubview(experience)
        }

        // Price breakdown for stays
        if listing.kind == .stay {
            let breakdown = PriceBreakdown.generate(for: listing, nights: 3)
            let priceTitle = UILabel()
            priceTitle.font = .systemFont(ofSize: 18, weight: .bold)
            priceTitle.textColor = SfStyle.textPrimary
            priceTitle.text = "Price breakdown"

            let breakdownStack = UIStackView()
            breakdownStack.axis = .vertical
            breakdownStack.spacing = 6

            let items: [(String, Int)] = [
                ("$\(listing.price) x 3 nights", breakdown.subtotal),
                ("Cleaning fee", breakdown.cleaningFee),
                ("Service fee", breakdown.serviceFee),
                ("Taxes", breakdown.taxes)
            ]
            for (label, amount) in items {
                let row = UIStackView()
                row.axis = .horizontal
                let left = UILabel()
                left.font = .systemFont(ofSize: 14, weight: .regular)
                left.textColor = SfStyle.textSecondary
                left.text = label
                let right = UILabel()
                right.font = .systemFont(ofSize: 14, weight: .regular)
                right.textColor = SfStyle.textPrimary
                right.text = "$\(amount)"
                right.textAlignment = .right
                row.addArrangedSubview(left)
                row.addArrangedSubview(right)
                breakdownStack.addArrangedSubview(row)
            }

            let divider = UIView()
            divider.backgroundColor = UIColor(white: 0.85, alpha: 1)
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            breakdownStack.addArrangedSubview(divider)

            let totalRow = UIStackView()
            totalRow.axis = .horizontal
            let totalLeft = UILabel()
            totalLeft.font = .systemFont(ofSize: 15, weight: .bold)
            totalLeft.textColor = SfStyle.textPrimary
            totalLeft.text = "Total"
            let totalRight = UILabel()
            totalRight.font = .systemFont(ofSize: 15, weight: .bold)
            totalRight.textColor = SfStyle.textPrimary
            totalRight.text = "$\(breakdown.total)"
            totalRight.textAlignment = .right
            totalRow.addArrangedSubview(totalLeft)
            totalRow.addArrangedSubview(totalRight)
            breakdownStack.addArrangedSubview(totalRow)

            let priceSection = UIStackView(arrangedSubviews: [priceTitle, breakdownStack])
            priceSection.axis = .vertical
            priceSection.spacing = 10
            contentStack.addArrangedSubview(priceSection)
        }

        let detailInfo = ListingDetailInfo.generate(for: listing)
        detailInfo.sections.forEach { section in
            let sectionView = DetailSectionView(section: section)
            contentStack.addArrangedSubview(sectionView)
        }

        // Cancellation policy card for stays
        if listing.kind == .stay {
            var cancelRng = SeededGenerator(seed: stableSeed(listing.id) &+ 42)
            let cancelText = cancelRng.pick([
                "Free cancellation for 48 hours after booking.",
                "Cancel up to 5 days before check-in for a full refund.",
                "Cancel up to 7 days before check-in. 50% refund after that.",
                "Free cancellation up to 24 hours before check-in."
            ])
            let cancelCard = UIView()
            cancelCard.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.95, alpha: 1)
            cancelCard.layer.cornerRadius = 16

            let cancelIcon = UIImageView(image: UIImage(systemName: "checkmark.shield"))
            cancelIcon.tintColor = UIColor(red: 0.0, green: 0.6, blue: 0.4, alpha: 1)
            cancelIcon.translatesAutoresizingMaskIntoConstraints = false
            cancelIcon.widthAnchor.constraint(equalToConstant: 24).isActive = true
            cancelIcon.heightAnchor.constraint(equalToConstant: 24).isActive = true

            let cancelTitle = UILabel()
            cancelTitle.font = .systemFont(ofSize: 15, weight: .bold)
            cancelTitle.textColor = SfStyle.textPrimary
            cancelTitle.text = "Cancellation policy"

            let cancelBody = UILabel()
            cancelBody.font = .systemFont(ofSize: 13, weight: .regular)
            cancelBody.textColor = SfStyle.textSecondary
            cancelBody.numberOfLines = 0
            cancelBody.text = cancelText

            let cancelTopRow = UIStackView(arrangedSubviews: [cancelIcon, cancelTitle])
            cancelTopRow.axis = .horizontal
            cancelTopRow.spacing = 8
            cancelTopRow.alignment = .center

            let cancelStack = UIStackView(arrangedSubviews: [cancelTopRow, cancelBody])
            cancelStack.axis = .vertical
            cancelStack.spacing = 6
            cancelStack.translatesAutoresizingMaskIntoConstraints = false
            cancelCard.addSubview(cancelStack)
            NSLayoutConstraint.activate([
                cancelStack.leadingAnchor.constraint(equalTo: cancelCard.leadingAnchor, constant: 16),
                cancelStack.trailingAnchor.constraint(equalTo: cancelCard.trailingAnchor, constant: -16),
                cancelStack.topAnchor.constraint(equalTo: cancelCard.topAnchor, constant: 14),
                cancelStack.bottomAnchor.constraint(equalTo: cancelCard.bottomAnchor, constant: -14)
            ])
            contentStack.addArrangedSubview(cancelCard)
        }

        let reviewHeader = UILabel()
        reviewHeader.font = .systemFont(ofSize: 18, weight: .bold)
        reviewHeader.textColor = SfStyle.textPrimary
        reviewHeader.text = "Reviews"
        contentStack.addArrangedSubview(reviewHeader)

        listing.reviews.prefix(2).forEach { review in
            let row = ReviewRowView(review: review)
            contentStack.addArrangedSubview(row)
        }

        if listing.reviewCount > 2 {
            let showAllReviewsBtn = UIButton(type: .system)
            showAllReviewsBtn.setTitle("Show all \(listing.reviewCount) reviews", for: .normal)
            showAllReviewsBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            showAllReviewsBtn.setTitleColor(SfStyle.textPrimary, for: .normal)
            showAllReviewsBtn.contentHorizontalAlignment = .leading
            showAllReviewsBtn.addTarget(self, action: #selector(showAllReviews), for: .touchUpInside)
            contentStack.addArrangedSubview(showAllReviewsBtn)
        }

        // Similar listings
        let similarListings = store.listings.filter { $0.kind == listing.kind && $0.id != listing.id }
        let similar = Array(similarListings.prefix(5))
        if !similar.isEmpty {
            let similarHeader = UILabel()
            similarHeader.font = .systemFont(ofSize: 18, weight: .bold)
            similarHeader.textColor = SfStyle.textPrimary
            similarHeader.text = "You might also like"
            contentStack.addArrangedSubview(similarHeader)

            let similarScroll = UIScrollView()
            similarScroll.showsHorizontalScrollIndicator = false
            similarScroll.heightAnchor.constraint(equalToConstant: 316).isActive = true

            let similarStack = UIStackView()
            similarStack.axis = .horizontal
            similarStack.spacing = 16
            similarStack.translatesAutoresizingMaskIntoConstraints = false
            similarScroll.addSubview(similarStack)

            NSLayoutConstraint.activate([
                similarStack.leadingAnchor.constraint(equalTo: similarScroll.contentLayoutGuide.leadingAnchor),
                similarStack.trailingAnchor.constraint(equalTo: similarScroll.contentLayoutGuide.trailingAnchor),
                similarStack.topAnchor.constraint(equalTo: similarScroll.contentLayoutGuide.topAnchor),
                similarStack.bottomAnchor.constraint(equalTo: similarScroll.contentLayoutGuide.bottomAnchor),
                similarStack.heightAnchor.constraint(equalTo: similarScroll.frameLayoutGuide.heightAnchor)
            ])

            for sim in similar {
                let card = RailListingCardView()
                card.configure(listing: sim, style: .price, isFavorite: store.isFavorite(sim.id))
                card.widthAnchor.constraint(equalToConstant: 260).isActive = true
                card.accessibilityIdentifier = sim.id
                card.addTarget(self, action: #selector(similarListingTapped(_:)), for: .touchUpInside)
                similarStack.addArrangedSubview(card)
            }
            contentStack.addArrangedSubview(similarScroll)
        }

        reserveBar.configure(listing: listing)
        reserveBar.onReserve = { [weak self] in
            self?.showBooking()
        }
        reserveBar.onMessage = { [weak self] in
            self?.messageHost()
        }

    }

    private func showBooking() {
        let booking = BookingViewController(listing: listing)
        navigationController?.pushViewController(booking, animated: true)
    }

    private func messageHost() {
        let conversation = store.conversation(for: listing)
        let chat = ChatViewController(conversation: conversation)
        navigationController?.pushViewController(chat, animated: true)
    }

    private func configureNavBarButtons() {
        let heartImage = UIImage(systemName: store.isFavorite(listing.id) ? "heart.fill" : "heart")
        let heartBtn = UIBarButtonItem(image: heartImage, style: .plain, target: self, action: #selector(toggleFavorite))
        heartBtn.tintColor = SfStyle.accent
        let shareBtn = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareListing))
        shareBtn.tintColor = SfStyle.textPrimary
        navigationItem.rightBarButtonItems = [heartBtn, shareBtn]
    }

    @objc private func toggleFavorite() {
        store.toggleFavorite(listingId: listing.id)
        navigationItem.rightBarButtonItems?.first?.image = UIImage(systemName: store.isFavorite(listing.id) ? "heart.fill" : "heart")
    }

    @objc private func shareListing() {
        let text = "Check out \(listing.title) in \(listing.location) on StayFinder! $\(listing.price)/night — \(String(format: "%.1f", listing.rating)) stars"
        let items: [Any] = if let url = URL(string: "https://stayfinder.example/rooms/\(listing.id)") { [text, url] } else { [text] }
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        ac.excludedActivityTypes = [.addToReadingList, .assignToContact, .print, .saveToCameraRoll]
        present(ac, animated: true, completion: nil)
    }

    @objc private func miniMapTapped() {
        let filtered = store.listings.filter { $0.kind == .stay && $0.location == listing.location }
        let mapVC = MapViewController(listings: filtered.isEmpty ? [listing] : filtered)
        navigationController?.pushViewController(mapVC, animated: true)
    }

    @objc private func showAllReviews() {
        let vc = AllReviewsViewController(listing: listing)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func similarListingTapped(_ sender: TapAccessibleControl) {
        guard let id = sender.accessibilityIdentifier, let sim = store.listing(for: id) else { return }
        let detail = ListingDetailViewController(listing: sim)
        navigationController?.pushViewController(detail, animated: true)
    }
}

final class ImageCarouselView: UIView, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let pageControl = UIPageControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        scrollView.addSubview(stack)
        addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.pageIndicatorTintColor = UIColor(white: 1, alpha: 0.4)
        pageControl.currentPageIndicatorTintColor = .white

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),

            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    func configure(images: [ListingImage]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        images.forEach { image in
            let imageView = ListingImageView()
            imageView.configure(image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(imageView)
            imageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
        pageControl.numberOfPages = images.count
        pageControl.currentPage = 0
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        pageControl.currentPage = page
    }
}

final class PhotoGridView: UIView {
    private let images: [ListingImage]
    private var imageViews: [ListingImageView] = []
    var onTap: ((Int) -> Void)?
    var onShowAll: (() -> Void)?

    init(images: [ListingImage]) {
        self.images = images
        super.init(frame: .zero)
        configureGrid()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureGrid() {
        clipsToBounds = true
        layer.cornerRadius = 12

        let count = min(images.count, 5)
        for i in 0..<count {
            let iv = ListingImageView()
            iv.configure(images[i], showsTitle: false)
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            iv.addGestureRecognizer(tap)
            iv.tag = i
            addSubview(iv)
            imageViews.append(iv)
        }

        guard count == 5 else { return }

        let gap: CGFloat = 2
        // Hero: left half full height. Right: 2x2 grid
        NSLayoutConstraint.activate([
            imageViews[0].leadingAnchor.constraint(equalTo: leadingAnchor),
            imageViews[0].topAnchor.constraint(equalTo: topAnchor),
            imageViews[0].bottomAnchor.constraint(equalTo: bottomAnchor),
            imageViews[0].widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -gap / 2),

            imageViews[1].leadingAnchor.constraint(equalTo: imageViews[0].trailingAnchor, constant: gap),
            imageViews[1].topAnchor.constraint(equalTo: topAnchor),
            imageViews[1].widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.25, constant: -gap),
            imageViews[1].heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5, constant: -gap / 2),

            imageViews[2].leadingAnchor.constraint(equalTo: imageViews[1].trailingAnchor, constant: gap),
            imageViews[2].topAnchor.constraint(equalTo: topAnchor),
            imageViews[2].trailingAnchor.constraint(equalTo: trailingAnchor),
            imageViews[2].heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5, constant: -gap / 2),

            imageViews[3].leadingAnchor.constraint(equalTo: imageViews[0].trailingAnchor, constant: gap),
            imageViews[3].topAnchor.constraint(equalTo: imageViews[1].bottomAnchor, constant: gap),
            imageViews[3].widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.25, constant: -gap),
            imageViews[3].bottomAnchor.constraint(equalTo: bottomAnchor),

            imageViews[4].leadingAnchor.constraint(equalTo: imageViews[3].trailingAnchor, constant: gap),
            imageViews[4].topAnchor.constraint(equalTo: imageViews[2].bottomAnchor, constant: gap),
            imageViews[4].trailingAnchor.constraint(equalTo: trailingAnchor),
            imageViews[4].bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        addShowAllButton()
    }

    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        if let index = gesture.view?.tag {
            onTap?(index)
        }
    }

    @objc private func showAllPhotosTapped() {
        onShowAll?()
    }

    private func addShowAllButton() {
        let btn = UIButton(type: .system)
        btn.setTitle("Show all photos", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        btn.setTitleColor(SfStyle.textPrimary, for: .normal)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        btn.layer.cornerRadius = 6
        btn.layer.borderWidth = 1
        btn.layer.borderColor = SfStyle.textPrimary.cgColor
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        btn.addTarget(self, action: #selector(showAllPhotosTapped), for: .touchUpInside)
        addSubview(btn)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            btn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
}

final class InfoRowView: UIView {
    struct Item {
        let title: String
        let value: String
    }

    init(items: [Item]) {
        super.init(frame: .zero)
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        items.forEach { item in
            let valueLabel = UILabel()
            valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            valueLabel.textColor = SfStyle.textPrimary
            valueLabel.textAlignment = .center
            valueLabel.text = item.value

            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 12, weight: .regular)
            titleLabel.textColor = SfStyle.textSecondary
            titleLabel.textAlignment = .center
            titleLabel.text = item.title

            let stackItem = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
            stackItem.axis = .vertical
            stackItem.spacing = 4
            stack.addArrangedSubview(stackItem)
        }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HostView: UIView {
    init(host: Host) {
        super.init(frame: .zero)

        let avatar = UIView()
        avatar.backgroundColor = host.avatarColor
        avatar.layer.cornerRadius = 22
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 44).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let initials = UILabel()
        initials.text = String(host.name.prefix(1))
        initials.textColor = .white
        initials.font = .systemFont(ofSize: 18, weight: .bold)
        initials.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(initials)
        NSLayoutConstraint.activate([
            initials.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            initials.centerYAnchor.constraint(equalTo: avatar.centerYAnchor)
        ])

        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = SfStyle.textPrimary
        nameLabel.text = "Hosted by \(host.name)"

        let nameRow = UIStackView(arrangedSubviews: [nameLabel])
        nameRow.axis = .horizontal
        nameRow.spacing = 4
        nameRow.alignment = .center

        if host.isVerified {
            let badge = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            badge.tintColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1)
            badge.translatesAutoresizingMaskIntoConstraints = false
            badge.widthAnchor.constraint(equalToConstant: 16).isActive = true
            badge.heightAnchor.constraint(equalToConstant: 16).isActive = true
            nameRow.addArrangedSubview(badge)
        }

        let statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = SfStyle.textSecondary
        let statusText = host.isSuperhost ? "Superhost - \(host.responseRate) response rate" : "Response rate \(host.responseRate)"
        statusLabel.text = statusText

        let stack = UIStackView(arrangedSubviews: [nameRow, statusLabel])
        stack.axis = .vertical
        stack.spacing = 4

        let row = UIStackView(arrangedSubviews: [avatar, stack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AmenitiesView: UIView {
    var onShowAll: (() -> Void)?

    init(amenities: [String]) {
        super.init(frame: .zero)
        let title = UILabel()
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textColor = SfStyle.textPrimary
        title.text = "Amenities"

        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 6

        amenities.prefix(4).forEach { amenity in
            let label = UILabel()
            label.font = .systemFont(ofSize: 14, weight: .regular)
            label.textColor = SfStyle.textSecondary
            label.text = "- \(amenity)"
            list.addArrangedSubview(label)
        }

        if amenities.count > 4 {
            let showAllBtn = UIButton(type: .system)
            showAllBtn.setTitle("Show all \(amenities.count) amenities", for: .normal)
            showAllBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            showAllBtn.setTitleColor(SfStyle.textPrimary, for: .normal)
            showAllBtn.contentHorizontalAlignment = .leading
            showAllBtn.addTarget(self, action: #selector(showAllTapped), for: .touchUpInside)
            list.addArrangedSubview(showAllBtn)
        }

        let stack = UIStackView(arrangedSubviews: [title, list])
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func showAllTapped() { onShowAll?() }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class DetailSectionView: UIView {
    init(section: DetailSection) {
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.03
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 3)

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = section.title

        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 6

        let useBullets = section.lines.count > 1
        section.lines.forEach { line in
            let label = UILabel()
            label.font = .systemFont(ofSize: 13, weight: .regular)
            label.textColor = SfStyle.textSecondary
            label.numberOfLines = 0
            label.text = useBullets ? "• \(line)" : line
            list.addArrangedSubview(label)
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, list])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ExperienceOverviewView: UIView {
    init(highlights: [String], duration: String, titleText: String = "What you will do") {
        super.init(frame: .zero)
        let title = UILabel()
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textColor = SfStyle.textPrimary
        title.text = titleText

        let durationLabel = UILabel()
        durationLabel.font = .systemFont(ofSize: 13, weight: .medium)
        durationLabel.textColor = SfStyle.textSecondary
        durationLabel.text = "Duration: \(duration)"

        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 6
        highlights.forEach { highlight in
            let label = UILabel()
            label.font = .systemFont(ofSize: 14, weight: .regular)
            label.textColor = SfStyle.textSecondary
            label.text = "- \(highlight)"
            list.addArrangedSubview(label)
        }

        let stack = UIStackView(arrangedSubviews: [title, durationLabel, list])
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ReviewRowView: UIView {
    init(review: Review) {
        super.init(frame: .zero)
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = SfStyle.textPrimary
        nameLabel.text = review.author

        let ratingLabel = UILabel()
        ratingLabel.font = .systemFont(ofSize: 12, weight: .medium)
        ratingLabel.textColor = SfStyle.textSecondary
        ratingLabel.text = String(format: "%.1f - \(review.date)", review.rating)

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 13, weight: .regular)
        bodyLabel.textColor = SfStyle.textSecondary
        bodyLabel.numberOfLines = 0
        bodyLabel.text = review.text

        let stack = UIStackView(arrangedSubviews: [nameLabel, ratingLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 4
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AllAmenitiesViewController: UIViewController {
    private let amenities: [String]

    private let amenityIcons: [String: String] = [
        "Wifi": "wifi", "Kitchen": "fork.knife", "Pool": "figure.pool.swim",
        "Parking": "car", "Washer": "washer", "Dryer": "wind",
        "Workspace": "desktopcomputer", "Self check-in": "key",
        "Outdoor dining": "leaf", "Hot tub": "drop", "Gym": "figure.walk",
        "Air conditioning": "snowflake", "Heating": "flame",
        "Iron": "tshirt", "TV": "tv", "Hair dryer": "wind"
    ]

    init(amenities: [String]) {
        self.amenities = amenities
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Amenities"
        view.backgroundColor = .white
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        for amenity in amenities {
            let iconName = amenityIcons[amenity] ?? "checkmark"
            let icon = UIImageView(image: UIImage(systemName: iconName))
            icon.tintColor = SfStyle.textSecondary
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 22).isActive = true

            let label = UILabel()
            label.font = .systemFont(ofSize: 15, weight: .regular)
            label.textColor = SfStyle.textPrimary
            label.text = amenity

            let row = UIStackView(arrangedSubviews: [icon, label])
            row.axis = .horizontal
            row.spacing = 14
            row.alignment = .center
            row.heightAnchor.constraint(equalToConstant: 48).isActive = true

            stack.addArrangedSubview(row)

            let divider = UIView()
            divider.backgroundColor = SfStyle.divider
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            stack.addArrangedSubview(divider)
        }
    }
}

final class AllReviewsViewController: UIViewController {
    private let listing: Listing

    init(listing: Listing) {
        self.listing = listing
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(listing.reviewCount) Reviews"
        view.backgroundColor = .white

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        // Start with existing reviews
        var allReviews = listing.reviews

        // Generate additional reviews to fill reviewCount
        let names = ["Emma", "James", "Mia", "Liam", "Olivia", "Noah", "Ava", "Lucas", "Isabella", "Ethan",
                     "Sophia", "Mason", "Charlotte", "Logan", "Amelia", "Ben", "Harper", "Aiden", "Luna", "Caleb"]
        let dates = ["Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025", "Jun 2025", "Jul 2025",
                     "Aug 2024", "Sep 2024", "Oct 2024", "Nov 2024", "Dec 2024"]
        let bodies = [
            "Great stay, exactly as described. Would come back again.",
            "Beautiful place with a wonderful host. Everything was clean and well-maintained.",
            "Perfect location and great amenities. Highly recommend.",
            "Very comfortable and cozy. The neighborhood is lovely.",
            "Outstanding experience from start to finish. Five stars!",
            "Good value for the price. The check-in process was smooth.",
            "Nice space with great natural light. Kitchen was well-equipped.",
            "Quiet neighborhood, close to restaurants and shops. Very convenient.",
            "Host was very responsive and helpful throughout our stay.",
            "Clean, modern, and exactly what we needed for our trip."
        ]

        var rng = SeededGenerator(seed: stableSeed(listing.id) &+ 999)
        let needed = max(0, listing.reviewCount - allReviews.count)
        for _ in 0..<min(needed, 30) {
            let review = Review(
                author: rng.pick(names),
                rating: Double(rng.pick([4, 4, 5, 5, 5])),
                date: rng.pick(dates),
                text: rng.pick(bodies)
            )
            allReviews.append(review)
        }

        for review in allReviews {
            let row = ReviewRowView(review: review)
            stack.addArrangedSubview(row)
        }
    }
}

final class ReserveBarView: UIView {
    private let priceLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let reserveButton = UIButton(type: .system)
    private let messageButton = UIButton(type: .system)
    private let separator = UIView()

    var onReserve: (() -> Void)?
    var onMessage: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .white
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: -1)

        separator.backgroundColor = SfStyle.divider
        separator.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.font = .systemFont(ofSize: 20, weight: .bold)
        priceLabel.textColor = SfStyle.textPrimary

        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = SfStyle.textSecondary
        subtitleLabel.numberOfLines = 2

        reserveButton.setTitle("Reserve", for: .normal)
        reserveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        reserveButton.backgroundColor = SfStyle.accent
        reserveButton.tintColor = .white
        reserveButton.layer.cornerRadius = 22
        reserveButton.addTarget(self, action: #selector(reserveTapped), for: .touchUpInside)
        reserveButton.accessibilityIdentifier = "bnb.detail.reserve"

        messageButton.setTitle("Message host", for: .normal)
        messageButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        messageButton.setTitleColor(SfStyle.accent, for: .normal)
        messageButton.contentHorizontalAlignment = .left
        messageButton.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        messageButton.accessibilityIdentifier = "bnb.detail.messageHost"

        let infoStack = UIStackView(arrangedSubviews: [priceLabel, subtitleLabel, messageButton])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        infoStack.alignment = .leading

        let row = UIStackView(arrangedSubviews: [infoStack, reserveButton])
        row.axis = .horizontal
        row.spacing = 16
        row.alignment = .center

        addSubview(separator)
        addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            row.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            row.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
            reserveButton.widthAnchor.constraint(equalToConstant: 156),
            reserveButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    func configure(listing: Listing) {
        if listing.kind == .experience {
            priceLabel.text = "$\(listing.price) per person"
            subtitleLabel.text = "Instant confirmation for \(listing.duration.lowercased())"
        } else if listing.kind == .service {
            priceLabel.text = "From $\(listing.price)"
            subtitleLabel.text = "Final price and availability confirmed at checkout"
        } else {
            priceLabel.text = "$\(listing.price) per night"
            subtitleLabel.text = "Includes taxes and fees at checkout"
        }
    }

    @objc private func reserveTapped() {
        onReserve?()
    }

    @objc private func messageTapped() {
        onMessage?()
    }
}

final class BookingViewController: UIViewController {
    private let listing: Listing
    private let store = SfStore.shared
    private let myBankAccountsService = StayFinderMyBankAccountsService()
    private var shouldAutoOpenCheckoutForTesting = false

    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let guestsStepper = UIStepper()
    private let guestsLabel = UILabel()
    private let totalLabel = UILabel()
    private let confirmButton = UIButton(type: .system)

    init(listing: Listing) {
        self.listing = listing
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "bnb.booking.screen"
        title = "Booking"
        view.backgroundColor = .white
        configureLayout()
        updateTotal()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentCheckoutForTestingIfNeeded()
    }

    private func configureLayout() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = listing.title
        stack.addArrangedSubview(titleLabel)

        startDatePicker.datePickerMode = .date
        endDatePicker.datePickerMode = .date
        let today = Calendar.current.startOfDay(for: Date())
        startDatePicker.minimumDate = today
        startDatePicker.date = today
        startDatePicker.accessibilityIdentifier = "bnb.booking.startDate"
        endDatePicker.accessibilityIdentifier = "bnb.booking.endDate"
        endDatePicker.date = dateByAddingDays(listing.kind == .stay ? 1 : 0, to: today)
        startDatePicker.addTarget(self, action: #selector(updateTotal), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(updateTotal), for: .valueChanged)
        updateDatePickerConstraints()

        let dateRow = UIStackView(arrangedSubviews: [startDatePicker, endDatePicker])
        dateRow.axis = .horizontal
        dateRow.spacing = 12
        dateRow.distribution = .fillEqually
        stack.addArrangedSubview(labeled(title: "Dates", view: dateRow))

        guestsStepper.minimumValue = 1
        guestsStepper.maximumValue = Double(listing.guests)
        guestsStepper.value = 1
        guestsStepper.addTarget(self, action: #selector(guestsChanged), for: .valueChanged)
        guestsStepper.accessibilityIdentifier = "bnb.booking.guestsStepper"

        guestsLabel.font = .systemFont(ofSize: 15, weight: .medium)
        guestsLabel.textColor = SfStyle.textPrimary
        guestsLabel.text = "1 guest"

        let guestsRow = UIStackView(arrangedSubviews: [guestsLabel, guestsStepper])
        guestsRow.axis = .horizontal
        guestsRow.spacing = 12
        stack.addArrangedSubview(labeled(title: "Guests", view: guestsRow))

        let paymentLabel = UILabel()
        paymentLabel.font = .systemFont(ofSize: 13, weight: .regular)
        paymentLabel.textColor = SfStyle.textSecondary
        paymentLabel.text = "Payment method: MyBank saved card (confirm at checkout)"
        stack.addArrangedSubview(paymentLabel)

        totalLabel.font = .systemFont(ofSize: 16, weight: .bold)
        totalLabel.textColor = SfStyle.textPrimary
        stack.addArrangedSubview(totalLabel)

        confirmButton.setTitle("Continue to checkout", for: .normal)
        confirmButton.backgroundColor = SfStyle.accent
        confirmButton.tintColor = .white
        confirmButton.layer.cornerRadius = 18
        confirmButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        confirmButton.accessibilityIdentifier = "bnb.booking.continue"
        stack.addArrangedSubview(confirmButton)
    }

    private func labeled(title: String, view: UIView) -> UIView {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = SfStyle.textSecondary
        label.text = title
        let stack = UIStackView(arrangedSubviews: [label, view])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    @objc private func guestsChanged() {
        let guests = Int(guestsStepper.value)
        guestsLabel.text = guests == 1 ? "1 guest" : "\(guests) guests"
        updateTotal()
    }

    @objc private func updateTotal() {
        updateDatePickerConstraints()
        let nights = bookingNights
        let total = bookingTotal
        if listing.kind == .experience {
            totalLabel.text = "Total: $\(total) for \(Int(guestsStepper.value)) guests"
        } else if listing.kind == .service {
            totalLabel.text = "Total: $\(total) service fee"
        } else {
            let breakdown = PriceBreakdown.generate(for: listing, nights: nights)
            totalLabel.numberOfLines = 0
            totalLabel.text = "$\(listing.price) x \(nights) nights: $\(breakdown.subtotal)\nCleaning: $\(breakdown.cleaningFee) · Service: $\(breakdown.serviceFee) · Tax: $\(breakdown.taxes)\nTotal: $\(breakdown.total)"
        }
    }

    @objc private func confirmTapped() {
        navigationController?.pushViewController(makeCheckoutViewController(), animated: true)
    }

    func openCheckoutForTesting() {
        shouldAutoOpenCheckoutForTesting = true
        presentCheckoutForTestingIfNeeded()
    }

    private func makeCheckoutViewController() -> BookingCheckoutViewController {
        let checkout = BookingCheckoutViewController(
            listing: listing,
            startDate: startDatePicker.date,
            endDate: endDatePicker.date,
            guests: Int(guestsStepper.value),
            total: bookingTotal,
            accountsService: myBankAccountsService
        )
        checkout.onConfirm = { [weak self] account in
            self?.completeBooking(using: account)
        }
        return checkout
    }

    private func presentCheckoutForTestingIfNeeded() {
        guard shouldAutoOpenCheckoutForTesting,
              isViewLoaded,
              view.window != nil else { return }
        shouldAutoOpenCheckoutForTesting = false
        navigationController?.pushViewController(makeCheckoutViewController(), animated: false)
    }

    private var bookingNights: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDatePicker.date, to: endDatePicker.date).day ?? 1)
    }

    private var bookingTotal: Int {
        if listing.kind == .experience {
            return listing.price * Int(guestsStepper.value)
        }
        if listing.kind == .service {
            return listing.price
        }
        return listing.price * bookingNights
    }

    private func completeBooking(using account: StayFinderPaymentAccount) {
        let booking = store.addBooking(listingId: listing.id, startDate: startDatePicker.date, endDate: endDatePicker.date, guests: Int(guestsStepper.value))
        let total = Double(bookingTotal)
        StayFinderMyBankLedgerWriter.recordBooking(
            booking: booking,
            listing: listing,
            total: total,
            paymentAccountId: account.id
        )
        StayFinderMailOutboxWriter.recordBookingEmail(
            booking: booking,
            listing: listing,
            total: total,
            nights: bookingNights,
            guests: Int(guestsStepper.value),
            guestFirstName: store.profile.firstName
        )
        let tabController = tabBarController
        navigationController?.popToRootViewController(animated: false)
        if let tab = tabController {
            if let tripsNavigationController = tab.viewControllers?[2] as? UINavigationController {
                tripsNavigationController.popToRootViewController(animated: false)
                if let trips = tripsNavigationController.viewControllers.first as? TripsViewController {
                    trips.refreshForTesting()
                }
            }
            DispatchQueue.main.async {
                tab.selectedIndex = 2
            }
        }
    }

    private func updateDatePickerConstraints() {
        let minimumStayDays = listing.kind == .stay ? 1 : 0
        let minimumEndDate = dateByAddingDays(minimumStayDays, to: startDatePicker.date)
        endDatePicker.minimumDate = minimumEndDate
        if endDatePicker.date < minimumEndDate {
            endDatePicker.date = minimumEndDate
        }
    }
}

final class BookingCheckoutViewController: UIViewController {
    private let listing: Listing
    private let startDate: Date
    private let endDate: Date
    private let guests: Int
    private let total: Int
    private let accountsService: StayFinderMyBankAccountsService

    private var paymentAccounts: [StayFinderPaymentAccount] = []

    private let accountSegment = UISegmentedControl()
    private let cardLabel = UILabel()
    private let confirmSwitch = UISwitch()
    private let confirmButton = UIButton(type: .system)

    var onConfirm: ((StayFinderPaymentAccount) -> Void)?

    init(
        listing: Listing,
        startDate: Date,
        endDate: Date,
        guests: Int,
        total: Int,
        accountsService: StayFinderMyBankAccountsService
    ) {
        self.listing = listing
        self.startDate = startDate
        self.endDate = endDate
        self.guests = guests
        self.total = total
        self.accountsService = accountsService
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Checkout"
        view.backgroundColor = .white
        paymentAccounts = accountsService.loadAccounts()
        configureLayout()
        configureAccountOptions()
        updateSelectedCard()
        updateConfirmState()
    }

    private func configureLayout() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])

        let badge = UILabel()
        badge.font = .systemFont(ofSize: 13, weight: .semibold)
        badge.textColor = SfStyle.accent
        badge.text = "Payment routed through MyBank"
        badge.accessibilityIdentifier = "bnb.checkout.mybank"
        stack.addArrangedSubview(badge)

        let summary = UILabel()
        summary.numberOfLines = 0
        summary.font = .systemFont(ofSize: 14, weight: .regular)
        summary.textColor = SfStyle.textPrimary
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let nights = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        let breakdownText: String
        if listing.kind == .stay {
            let bd = PriceBreakdown.generate(for: listing, nights: nights)
            breakdownText = """
            \(listing.title)
            \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))
            Guests: \(guests)

            $\(listing.price) x \(nights) nights: $\(bd.subtotal)
            Cleaning fee: $\(bd.cleaningFee)
            Service fee: $\(bd.serviceFee)
            Taxes: $\(bd.taxes)
            Total: $\(bd.total)
            """
        } else {
            breakdownText = """
            \(listing.title)
            \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))
            Guests: \(guests)
            Total: $\(total)
            """
        }
        summary.text = breakdownText
        summary.accessibilityIdentifier = "bnb.checkout.summary"
        stack.addArrangedSubview(summary)

        let cardTitle = UILabel()
        cardTitle.text = "Autosaved card"
        cardTitle.font = .systemFont(ofSize: 12, weight: .semibold)
        cardTitle.textColor = SfStyle.textSecondary
        stack.addArrangedSubview(cardTitle)

        accountSegment.addTarget(self, action: #selector(accountSelectionChanged), for: .valueChanged)
        accountSegment.accessibilityIdentifier = "bnb.checkout.cardPicker"
        stack.addArrangedSubview(accountSegment)

        cardLabel.numberOfLines = 0
        cardLabel.font = .systemFont(ofSize: 14, weight: .medium)
        cardLabel.textColor = SfStyle.textPrimary
        cardLabel.accessibilityIdentifier = "bnb.checkout.card"
        stack.addArrangedSubview(cardLabel)

        let confirmRow = UIStackView()
        confirmRow.axis = .horizontal
        confirmRow.spacing = 12
        confirmRow.alignment = .center

        let confirmLabel = UILabel()
        confirmLabel.numberOfLines = 0
        confirmLabel.font = .systemFont(ofSize: 14, weight: .regular)
        confirmLabel.text = "I confirm charging this saved MyBank card."
        confirmLabel.accessibilityIdentifier = "bnb.checkout.confirmLabel"
        confirmRow.addArrangedSubview(confirmLabel)

        confirmSwitch.addTarget(self, action: #selector(confirmSwitchChanged), for: .valueChanged)
        confirmSwitch.accessibilityIdentifier = "bnb.checkout.confirmSwitch"
        confirmRow.addArrangedSubview(confirmSwitch)
        stack.addArrangedSubview(confirmRow)

        confirmButton.setTitle("Confirm Booking", for: .normal)
        confirmButton.backgroundColor = SfStyle.accent
        confirmButton.tintColor = .white
        confirmButton.layer.cornerRadius = 18
        confirmButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        confirmButton.accessibilityIdentifier = "bnb.checkout.confirmButton"
        stack.addArrangedSubview(confirmButton)
    }

    private func configureAccountOptions() {
        accountSegment.removeAllSegments()
        for (index, account) in paymentAccounts.enumerated() {
            accountSegment.insertSegment(withTitle: account.shortName, at: index, animated: false)
        }

        let preferredIndex = paymentAccounts.firstIndex(where: { $0.type == .credit }) ?? 0
        if !paymentAccounts.isEmpty {
            accountSegment.selectedSegmentIndex = preferredIndex
        } else {
            accountSegment.isEnabled = false
        }
    }

    private func selectedAccount() -> StayFinderPaymentAccount? {
        let index = accountSegment.selectedSegmentIndex
        guard index >= 0, index < paymentAccounts.count else { return nil }
        return paymentAccounts[index]
    }

    private func updateSelectedCard() {
        guard let account = selectedAccount() else {
            cardLabel.text = "No autosaved MyBank card found."
            cardLabel.textColor = .systemRed
            return
        }

        cardLabel.textColor = SfStyle.textPrimary
        cardLabel.text = "\(account.network) • \(account.maskedNumber)\n\(account.name)"
    }

    private func updateConfirmState() {
        let enabled = confirmSwitch.isOn && selectedAccount() != nil
        confirmButton.isEnabled = enabled
        confirmButton.alpha = enabled ? 1 : 0.5
    }

    @objc private func accountSelectionChanged() {
        updateSelectedCard()
        updateConfirmState()
    }

    @objc private func confirmSwitchChanged() {
        updateConfirmState()
    }

    @objc private func confirmTapped() {
        guard let account = selectedAccount(), confirmButton.isEnabled else { return }
        onConfirm?(account)
    }
}

final class WishlistViewController: UIViewController {
    private let store = SfStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let bodyStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SfStyle.background
        configureLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .bnbFavoritesChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refresh()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 22

        bodyStack.translatesAutoresizingMaskIntoConstraints = false
        bodyStack.axis = .vertical
        bodyStack.spacing = 26

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Wishlists"

        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = SfStyle.textPrimary
        addButton.backgroundColor = UIColor(white: 0.94, alpha: 1)
        addButton.layer.cornerRadius = 20
        addButton.accessibilityLabel = "Create wishlist"
        addButton.accessibilityIdentifier = "bnb.wishlist.add"
        addButton.addTarget(self, action: #selector(createWishlist), for: .touchUpInside)
        addButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), addButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        contentStack.addArrangedSubview(headerRow)
        contentStack.addArrangedSubview(bodyStack)
    }

    @objc private func refresh() {
        bodyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard !store.wishlists.isEmpty else {
            let emptyLabel = UILabel()
            emptyLabel.font = .systemFont(ofSize: 18, weight: .medium)
            emptyLabel.textColor = SfStyle.textSecondary
            emptyLabel.numberOfLines = 0
            emptyLabel.text = "Create your first wishlist by tapping the heart on any listing."
            bodyStack.addArrangedSubview(emptyLabel)
            return
        }

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 28

        var row: UIStackView?
        for (index, wishlist) in store.wishlists.enumerated() {
            if index % 2 == 0 {
                row = UIStackView()
                row!.axis = .horizontal
                row!.spacing = 16
                row!.distribution = .fillEqually
                gridStack.addArrangedSubview(row!)
            }

            let images = store.listings(withIDs: wishlist.listingIDs).flatMap { Array($0.images.prefix(1)) }
            let mosaic = WishlistMosaicCardView()
            mosaic.configure(images: images, title: wishlist.name, subtitle: "\(wishlist.listingIDs.count) saved")
            mosaic.tag = index
            mosaic.accessibilityIdentifier = "bnb.wishlist.\(index)"
            mosaic.addTarget(self, action: #selector(wishlistCardTapped(_:)), for: .touchUpInside)
            row!.addArrangedSubview(mosaic)
        }

        if store.wishlists.count % 2 != 0 {
            let spacer = UIView()
            row?.addArrangedSubview(spacer)
        }

        bodyStack.addArrangedSubview(gridStack)
    }

    @objc private func createWishlist() {
        let alert = UIAlertController(title: "New wishlist", message: "Give your wishlist a name", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.store.createWishlist(name: name)
        })
        present(alert, animated: true)
    }

    @objc private func wishlistCardTapped(_ sender: UIControl) {
        let index = sender.tag
        guard index >= 0, index < store.wishlists.count else { return }
        let wishlist = store.wishlists[index]
        let vc = WishlistDetailViewController(wishlist: wishlist)
        navigationController?.pushViewController(vc, animated: true)
    }
}

final class WishlistDetailViewController: UIViewController {
    private let store = SfStore.shared
    private var wishlist: Wishlist
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    init(wishlist: Wishlist) {
        self.wishlist = wishlist
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = wishlist.name
        view.backgroundColor = SfStyle.background
        configureLayout()
        refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesChanged), name: .bnbFavoritesChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    @objc private func favoritesChanged() {
        if let updated = store.wishlists.first(where: { $0.id == wishlist.id }) {
            wishlist = updated
        }
        refresh()
    }

    private func refresh() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let listings = store.listings(withIDs: wishlist.listingIDs)

        guard !listings.isEmpty else {
            let emptyLabel = UILabel()
            emptyLabel.font = .systemFont(ofSize: 18, weight: .medium)
            emptyLabel.textColor = SfStyle.textSecondary
            emptyLabel.numberOfLines = 0
            emptyLabel.text = "No listings saved to this wishlist yet."
            stack.addArrangedSubview(emptyLabel)
            return
        }

        listings.forEach { listing in
            let card = ListingCardView()
            card.configure(listing, isFavorite: store.isFavorite(listing.id))
            card.accessibilityIdentifier = listing.id
            card.onFavoriteToggle = { [weak self] in
                guard let self = self else { return }
                self.store.removeFromWishlist(listingId: listing.id, wishlistId: self.wishlist.id)
            }
            card.addTarget(self, action: #selector(openListing(_:)), for: .touchUpInside)
            stack.addArrangedSubview(card)
        }
    }

    @objc private func openListing(_ sender: ListingCardView) {
        guard let listingID = sender.accessibilityIdentifier,
              let listing = store.listing(for: listingID) else { return }
        navigationController?.pushViewController(ListingDetailViewController(listing: listing), animated: true)
    }
}

final class SectionListingsViewController: UIViewController {
    private let store = SfStore.shared
    private let listings: [Listing]
    private let titleText: String
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    init(titleText: String, listings: [Listing]) {
        self.titleText = titleText
        self.listings = listings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = titleText
        view.backgroundColor = SfStyle.background
        configureLayout()
        refresh()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func refresh() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        listings.forEach { listing in
            let card = ListingCardView()
            card.configure(listing, isFavorite: store.isFavorite(listing.id))
            card.accessibilityIdentifier = listing.id
            card.onFavoriteToggle = { [weak self, weak card] in
                self?.store.toggleFavorite(listingId: listing.id)
                card?.configure(listing, isFavorite: self?.store.isFavorite(listing.id) ?? false)
            }
            card.addTarget(self, action: #selector(openListing(_:)), for: .touchUpInside)
            stack.addArrangedSubview(card)
        }
    }

    @objc private func openListing(_ sender: ListingCardView) {
        guard let listingID = sender.accessibilityIdentifier,
              let listing = store.listing(for: listingID) else { return }
        navigationController?.pushViewController(ListingDetailViewController(listing: listing), animated: true)
    }
}

final class InboxSearchViewController: UIViewController {
    private let store = SfStore.shared
    private let searchField = UITextField()
    private let scrollView = UIScrollView()
    private let resultsStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search messages"
        view.backgroundColor = SfStyle.background
        hidesBottomBarWhenPushed = true
        configureLayout()
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func configureLayout() {
        searchField.borderStyle = .roundedRect
        searchField.placeholder = "Search by host, place, or message"
        searchField.accessibilityIdentifier = "bnb.inbox.searchField"
        searchField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        resultsStack.axis = .vertical
        resultsStack.spacing = 20
        resultsStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchField)
        view.addSubview(scrollView)
        scrollView.addSubview(resultsStack)

        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchField.heightAnchor.constraint(equalToConstant: 44),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            resultsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            resultsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            resultsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            resultsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            resultsStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    @objc private func textChanged() {
        refresh()
    }

    private func refresh() {
        resultsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let query = (searchField.text ?? "").lowercased()
        let conversations = store.conversations.filter { conversation in
            guard !query.isEmpty else { return true }
            let lastMessage = conversation.messages.last?.text.lowercased() ?? ""
            let haystack = "\(conversation.title) \(conversation.tripSummary) \(lastMessage)".lowercased()
            return haystack.contains(query)
        }

        if conversations.isEmpty {
            let label = UILabel()
            label.font = .systemFont(ofSize: 17, weight: .medium)
            label.textColor = SfStyle.textSecondary
            label.text = "No messages match that search."
            resultsStack.addArrangedSubview(label)
            return
        }

        conversations.forEach { conversation in
            let row = ConversationThreadView()
            row.configure(conversation: conversation, listing: store.listing(for: conversation.listingId))
            row.conversationID = conversation.id
            row.addTarget(self, action: #selector(openConversation(_:)), for: .touchUpInside)
            resultsStack.addArrangedSubview(row)
        }
    }

    @objc private func openConversation(_ sender: ConversationThreadView) {
        guard let conversationID = sender.conversationID,
              let conversation = store.conversations.first(where: { $0.id == conversationID }) else { return }
        navigationController?.pushViewController(ChatViewController(conversation: conversation), animated: true)
    }
}

final class InboxPreferencesViewController: UIViewController {
    private let tripUpdatesSwitch = UISwitch()
    private let supportSwitch = UISwitch()
    private let soundsSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Message settings"
        view.backgroundColor = SfStyle.background
        hidesBottomBarWhenPushed = true
        configureLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func configureLayout() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])

        tripUpdatesSwitch.isOn = true
        supportSwitch.isOn = true
        soundsSwitch.isOn = false

        stack.addArrangedSubview(settingsRow(title: "Trip updates", subtitle: "Reservation changes, check-in notes, and reminders.", control: tripUpdatesSwitch))
        stack.addArrangedSubview(settingsRow(title: "Support replies", subtitle: "Updates from StayFinder Support in your inbox.", control: supportSwitch))
        stack.addArrangedSubview(settingsRow(title: "Sounds", subtitle: "Play a sound for incoming messages on this device.", control: soundsSwitch))
    }

    private func settingsRow(title: String, subtitle: String, control: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 22

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = title

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = SfStyle.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = subtitle

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        let row = UIStackView(arrangedSubviews: [textStack, control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }
}

final class NotificationsViewController: UIViewController {
    private let store = SfStore.shared
    private let notifications: [SfNotificationItem]
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    init(notifications: [SfNotificationItem]) {
        self.notifications = notifications
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = SfStyle.background
        configureLayout()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        notifications.enumerated().forEach { item in
            stack.addArrangedSubview(notificationCard(item.element, index: item.offset))
        }
    }

    private func notificationCard(_ item: SfNotificationItem, index: Int) -> UIView {
        let card = TapAccessibleControl()
        card.isAccessibilityElement = true
        card.accessibilityIdentifier = "bnb.notifications.\(index)"
        card.accessibilityLabel = "\(item.title). \(item.subtitle)"
        card.accessibilityTraits = UIAccessibilityTraitButton
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.tag = index
        card.addTarget(self, action: #selector(openNotification(_:)), for: .touchUpInside)

        let icon = UIImageView(image: UIImage(systemName: item.symbolName))
        icon.tintColor = SfStyle.accent
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = item.title

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = SfStyle.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = item.subtitle

        let dateLabel = UILabel()
        dateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        dateLabel.textColor = SfStyle.textSecondary
        dateLabel.text = item.relativeDate

        let unreadDot = UIView()
        unreadDot.backgroundColor = SfStyle.accent
        unreadDot.layer.cornerRadius = 5
        unreadDot.translatesAutoresizingMaskIntoConstraints = false
        unreadDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        unreadDot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        unreadDot.isHidden = !item.isUnread

        let topRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), dateLabel, unreadDot])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8

        let textStack = UIStackView(arrangedSubviews: [topRow, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 8

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = SfStyle.textTertiary
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 10).isActive = true

        let row = UIStackView(arrangedSubviews: [icon, textStack, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    @objc private func openNotification(_ sender: UIControl) {
        guard sender.tag >= 0, sender.tag < notifications.count else { return }
        openDestination(notifications[sender.tag].destination)
    }

    private func openDestination(_ destination: SfDestination) {
        switch destination {
        case .listing(let listingID):
            guard let listing = store.listing(for: listingID) else { return }
            navigationController?.pushViewController(ListingDetailViewController(listing: listing), animated: true)
        case .conversation(let listingID):
            guard let listing = store.listing(for: listingID) else { return }
            navigationController?.pushViewController(ChatViewController(conversation: store.conversation(for: listing)), animated: true)
        case .pastTrips:
            navigationController?.pushViewController(PastTripsViewController(), animated: true)
        }
    }
}

final class ConnectionsViewController: UIViewController {
    private let store = SfStore.shared
    private let connections: [SfConnection]
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    init(connections: [SfConnection]) {
        self.connections = connections
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connections"
        view.backgroundColor = SfStyle.background
        configureLayout()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        let intro = UILabel()
        intro.font = .systemFont(ofSize: 15, weight: .regular)
        intro.textColor = SfStyle.textSecondary
        intro.numberOfLines = 0
        intro.text = "People you have hosted with, stayed with, or crossed paths with during shared StayFinder trips."
        stack.addArrangedSubview(intro)

        connections.enumerated().forEach { item in
            stack.addArrangedSubview(connectionCard(item.element, index: item.offset))
        }
    }

    private func connectionCard(_ item: SfConnection, index: Int) -> UIView {
        let card = TapAccessibleControl()
        card.isAccessibilityElement = true
        card.accessibilityIdentifier = "bnb.connections.\(index)"
        card.accessibilityLabel = "\(item.name). \(item.subtitle). \(item.detail)"
        card.accessibilityTraits = UIAccessibilityTraitButton
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.tag = index
        card.addTarget(self, action: #selector(openConnection(_:)), for: .touchUpInside)

        let bubble = UIView()
        bubble.backgroundColor = item.color
        bubble.layer.cornerRadius = 28
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.widthAnchor.constraint(equalToConstant: 56).isActive = true
        bubble.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let initialsLabel = UILabel()
        initialsLabel.font = .systemFont(ofSize: 22, weight: .bold)
        initialsLabel.textColor = .white
        initialsLabel.text = item.initials
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(initialsLabel)

        NSLayoutConstraint.activate([
            initialsLabel.centerXAnchor.constraint(equalTo: bubble.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: bubble.centerYAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = item.name

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = SfStyle.textPrimary
        subtitleLabel.text = item.subtitle

        let detailLabel = UILabel()
        detailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = SfStyle.textSecondary
        detailLabel.numberOfLines = 0
        detailLabel.text = item.detail

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = SfStyle.textTertiary
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 10).isActive = true

        let row = UIStackView(arrangedSubviews: [bubble, textStack, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    @objc private func openConnection(_ sender: UIControl) {
        guard sender.tag >= 0, sender.tag < connections.count else { return }

        switch connections[sender.tag].destination {
        case .listing(let listingID):
            guard let listing = store.listing(for: listingID) else { return }
            navigationController?.pushViewController(ListingDetailViewController(listing: listing), animated: true)
        case .conversation(let listingID):
            guard let listing = store.listing(for: listingID) else { return }
            navigationController?.pushViewController(ChatViewController(conversation: store.conversation(for: listing)), animated: true)
        case .pastTrips:
            navigationController?.pushViewController(PastTripsViewController(), animated: true)
        }
    }
}

final class HostingIntroViewController: UIViewController {
    private let store = SfStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hosting"
        view.backgroundColor = SfStyle.background
        configureLayout()
    }

    private func configureLayout() {
        let scrollView = UIScrollView()
        let stack = UIStackView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.text = "Get your space ready for hosting"
        stack.addArrangedSubview(titleLabel)

        let introLabel = UILabel()
        introLabel.font = .systemFont(ofSize: 16, weight: .regular)
        introLabel.textColor = SfStyle.textSecondary
        introLabel.numberOfLines = 0
        introLabel.text = "A strong listing starts with clear photos, house rules, arrival instructions, and a reliable calendar."
        stack.addArrangedSubview(introLabel)

        [
            ("Set up your place", "Add photos, sleeping arrangements, amenities, and check-in details."),
            ("Choose a hosting style", "Host a full home, a private room, or limited dates around your own travel."),
            ("Build trust early", "Write a thoughtful listing description and respond quickly to first messages.")
        ].forEach { item in
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 22

            let heading = UILabel()
            heading.font = .systemFont(ofSize: 17, weight: .semibold)
            heading.textColor = SfStyle.textPrimary
            heading.text = item.0

            let body = UILabel()
            body.font = .systemFont(ofSize: 14, weight: .regular)
            body.textColor = SfStyle.textSecondary
            body.numberOfLines = 0
            body.text = item.1

            let innerStack = UIStackView(arrangedSubviews: [heading, body])
            innerStack.axis = .vertical
            innerStack.spacing = 8
            innerStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(innerStack)

            NSLayoutConstraint.activate([
                innerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                innerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                innerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                innerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
            ])

            stack.addArrangedSubview(card)
        }

        let sampleButton = UIButton(type: .system)
        sampleButton.setTitle("View a sample listing", for: .normal)
        sampleButton.setTitleColor(.white, for: .normal)
        sampleButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        sampleButton.backgroundColor = SfStyle.accent
        sampleButton.layer.cornerRadius = 20
        sampleButton.accessibilityIdentifier = "bnb.hosting.sampleListing"
        sampleButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        sampleButton.addTarget(self, action: #selector(openSampleListing), for: .touchUpInside)
        stack.addArrangedSubview(sampleButton)
    }

    @objc private func openSampleListing() {
        guard let listing = store.listing(for: "stay-beach") else { return }
        navigationController?.pushViewController(ListingDetailViewController(listing: listing), animated: true)
    }
}

final class TripsViewController: UIViewController {
    private let store = SfStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let bodyStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SfStyle.background
        configureLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .bnbBookingsChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refresh()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 28

        bodyStack.translatesAutoresizingMaskIntoConstraints = false
        bodyStack.axis = .vertical
        bodyStack.spacing = 22

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 42, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Trips"

        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(bodyStack)
    }

    @objc private func refresh() {
        bodyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let upcoming = store.upcomingBookings()
        if upcoming.isEmpty {
            let placeholder = TripsPlaceholderView()
            placeholder.heightAnchor.constraint(equalToConstant: 430).isActive = true
            bodyStack.addArrangedSubview(placeholder)

            let headline = UILabel()
            headline.font = .systemFont(ofSize: 28, weight: .bold)
            headline.textColor = SfStyle.textPrimary
            headline.textAlignment = .center
            headline.text = "Build the perfect trip"
            bodyStack.addArrangedSubview(headline)

            let subheadline = UILabel()
            subheadline.font = .systemFont(ofSize: 19, weight: .regular)
            subheadline.textColor = SfStyle.textSecondary
            subheadline.numberOfLines = 0
            subheadline.textAlignment = .center
            subheadline.text = "Explore homes, experiences, and services. When you book, your reservations will show up here."
            bodyStack.addArrangedSubview(subheadline)

            let getStartedButton = UIButton(type: .system)
            getStartedButton.setTitle("Get started", for: .normal)
            getStartedButton.setTitleColor(.white, for: .normal)
            getStartedButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
            getStartedButton.backgroundColor = SfStyle.accent
            getStartedButton.layer.cornerRadius = 20
            getStartedButton.heightAnchor.constraint(equalToConstant: 72).isActive = true
            getStartedButton.accessibilityIdentifier = "bnb.trips.getStarted"
            getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
            bodyStack.addArrangedSubview(getStartedButton)
        } else {
            let label = UILabel()
            label.font = .systemFont(ofSize: 26, weight: .bold)
            label.textColor = SfStyle.textPrimary
            label.text = "Upcoming reservations"
            label.accessibilityIdentifier = "bnb.trips.upcomingHeader"
            bodyStack.addArrangedSubview(label)

            upcoming.forEach { booking in
                guard let listing = store.listing(for: booking.listingId) else { return }
                let card = BookingSummaryCardView()
                card.configure(listing: listing, booking: booking)
                card.accessibilityIdentifier = booking.id
                card.addTarget(self, action: #selector(bookingTapped(_:)), for: .touchUpInside)
                bodyStack.addArrangedSubview(card)
            }
        }

        bodyStack.addArrangedSubview(makePastTripsPrompt())
    }

    private func makePastTripsPrompt() -> UIControl {
        let card = TapAccessibleControl()
        card.backgroundColor = UIColor(white: 0.95, alpha: 1)
        card.layer.cornerRadius = 28
        card.accessibilityIdentifier = "bnb.trips.pastTripsPrompt"
        card.addTarget(self, action: #selector(openProfileTapped), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Find past trips in your profile ›"

        let thumbnail = UIImageView(image: UIImage(named: "sf_stay_10"))
        thumbnail.contentMode = .scaleAspectFill
        thumbnail.clipsToBounds = true
        thumbnail.layer.cornerRadius = 18
        thumbnail.translatesAutoresizingMaskIntoConstraints = false
        thumbnail.widthAnchor.constraint(equalToConstant: 76).isActive = true
        thumbnail.heightAnchor.constraint(equalToConstant: 76).isActive = true

        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), thumbnail])
        row.axis = .horizontal
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            card.heightAnchor.constraint(equalToConstant: 120)
        ])

        return card
    }

    @objc private func getStartedTapped() {
        tabBarController?.selectedIndex = 0
    }

    @objc private func openProfileTapped() {
        tabBarController?.selectedIndex = 4
    }

    @objc private func bookingTapped(_ sender: BookingSummaryCardView) {
        guard let bookingID = sender.accessibilityIdentifier,
              let booking = store.bookings.first(where: { $0.id == bookingID }),
              let listing = store.listing(for: booking.listingId) else { return }
        let detail = ListingDetailViewController(listing: listing)
        navigationController?.pushViewController(detail, animated: true)
    }

    func refreshForTesting() {
        loadViewIfNeeded()
        refresh()
    }
}

final class InboxViewController: UIViewController {
    private enum Filter {
        case all
        case traveling
        case support
    }

    private let store = SfStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let threadsStack = UIStackView()
    private let allButton = DarkPillButton(title: "All")
    private let travelingButton = DarkPillButton(title: "Traveling")
    private let supportButton = DarkPillButton(title: "Support")
    private var selectedFilter: Filter = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SfStyle.background
        configureLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .bnbMessagesChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refresh()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 22
        threadsStack.translatesAutoresizingMaskIntoConstraints = false
        threadsStack.axis = .vertical
        threadsStack.spacing = 26

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 42, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Messages"

        let searchButton = makeHeaderButton(symbol: "magnifyingglass")
        let settingsButton = makeHeaderButton(symbol: "gearshape")
        searchButton.accessibilityLabel = "Search messages"
        searchButton.accessibilityIdentifier = "bnb.inbox.search"
        settingsButton.accessibilityLabel = "Message settings"
        settingsButton.accessibilityIdentifier = "bnb.inbox.settings"
        searchButton.addTarget(self, action: #selector(openSearch), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), searchButton, settingsButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 16

        let filterRow = UIStackView(arrangedSubviews: [allButton, travelingButton, supportButton])
        filterRow.axis = .horizontal
        filterRow.spacing = 12
        filterRow.distribution = .fillProportionally

        allButton.tag = 0
        travelingButton.tag = 1
        supportButton.tag = 2
        [allButton, travelingButton, supportButton].forEach { button in
            button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        }

        contentStack.addArrangedSubview(headerRow)
        contentStack.addArrangedSubview(filterRow)
        contentStack.addArrangedSubview(threadsStack)
    }

    private func makeHeaderButton(symbol: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = SfStyle.textPrimary
        button.backgroundColor = UIColor(white: 0.94, alpha: 1)
        button.layer.cornerRadius = 28
        button.widthAnchor.constraint(equalToConstant: 56).isActive = true
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return button
    }

    @objc private func refresh() {
        threadsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        allButton.isSelected = selectedFilter == .all
        travelingButton.isSelected = selectedFilter == .traveling
        supportButton.isSelected = selectedFilter == .support

        let conversations = filteredConversations()
        if conversations.isEmpty {
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.textColor = SfStyle.textSecondary
            label.text = "No conversations here yet."
            threadsStack.addArrangedSubview(label)
            return
        }

        conversations.forEach { conversation in
            let row = ConversationThreadView()
            row.configure(conversation: conversation, listing: store.listing(for: conversation.listingId))
            row.conversationID = conversation.id
            row.accessibilityIdentifier = "bnb.inbox.thread.\(conversation.listingId)"
            row.addTarget(self, action: #selector(conversationTapped(_:)), for: .touchUpInside)
            threadsStack.addArrangedSubview(row)
        }
    }

    private func filteredConversations() -> [Conversation] {
        switch selectedFilter {
        case .all:
            return store.conversations
        case .traveling:
            return store.conversations.filter { $0.category == .traveling }
        case .support:
            return store.conversations.filter { $0.category == .support }
        }
    }

    @objc private func filterTapped(_ sender: DarkPillButton) {
        switch sender.tag {
        case 1:
            selectedFilter = .traveling
        case 2:
            selectedFilter = .support
        default:
            selectedFilter = .all
        }
        refresh()
    }

    @objc private func conversationTapped(_ sender: ConversationThreadView) {
        guard let conversationID = sender.conversationID,
              let conversation = store.conversations.first(where: { $0.id == conversationID }) else { return }
        let chat = ChatViewController(conversation: conversation)
        navigationController?.pushViewController(chat, animated: true)
    }

    @objc private func openSearch() {
        navigationController?.pushViewController(InboxSearchViewController(), animated: true)
    }

    @objc private func openSettings() {
        navigationController?.pushViewController(InboxPreferencesViewController(), animated: true)
    }

    func openConversationForTesting(listingID: String) {
        let conversation = store.conversations.first(where: { $0.listingId == listingID })
            ?? store.listing(for: listingID).map { store.conversation(for: $0) }
        guard let resolvedConversation = conversation else { return }
        let chat = ChatViewController(conversation: resolvedConversation)
        navigationController?.pushViewController(chat, animated: false)
    }
}

final class ProfileViewController: UIViewController {
    private let store = SfStore.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let tripCountLabel = UILabel()
    private let reviewsCountLabel = UILabel()
    private let yearsCountLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SfStyle.background
        configureLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .bnbBookingsChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refresh()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 22

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 42, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Profile"

        let bellButton = UIButton(type: .system)
        bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
        bellButton.tintColor = SfStyle.textPrimary
        bellButton.backgroundColor = UIColor(white: 0.94, alpha: 1)
        bellButton.layer.cornerRadius = 32
        bellButton.accessibilityLabel = "Notifications"
        bellButton.accessibilityIdentifier = "bnb.profile.notifications"
        bellButton.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        bellButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        bellButton.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), bellButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        contentStack.addArrangedSubview(headerRow)
        contentStack.addArrangedSubview(makeProfileSummaryCard())
        contentStack.addArrangedSubview(makeTileRow())
        contentStack.addArrangedSubview(makeHostCard())
        contentStack.addArrangedSubview(makeSettingsSection())
    }

    private func makeProfileSummaryCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.03
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 5)

        let avatar = UIView()
        avatar.backgroundColor = UIColor(white: 0.15, alpha: 1)
        avatar.layer.cornerRadius = 58
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 116).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 116).isActive = true

        let initials = UILabel()
        initials.font = .systemFont(ofSize: 42, weight: .bold)
        initials.textColor = .white
        initials.text = store.profile.initials
        initials.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(initials)

        let badge = UIView()
        badge.backgroundColor = SfStyle.accent
        badge.layer.cornerRadius = 22
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: 44).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let badgeIcon = UIImageView(image: UIImage(systemName: "checkmark.shield.fill"))
        badgeIcon.tintColor = .white
        badgeIcon.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeIcon)

        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 32, weight: .bold)
        nameLabel.textColor = SfStyle.textPrimary
        nameLabel.text = store.profile.fullName

        let locationLabel = UILabel()
        locationLabel.font = .systemFont(ofSize: 18, weight: .regular)
        locationLabel.textColor = SfStyle.textSecondary
        locationLabel.text = store.profile.location

        let leftStack = UIStackView(arrangedSubviews: [avatar, nameLabel, locationLabel])
        leftStack.axis = .vertical
        leftStack.alignment = .center
        leftStack.spacing = 14

        let statsStack = UIStackView(arrangedSubviews: [
            makeStatView(valueLabel: tripCountLabel, title: "Trips"),
            makeDivider(),
            makeStatView(valueLabel: reviewsCountLabel, title: "Reviews"),
            makeDivider(),
            makeStatView(valueLabel: yearsCountLabel, title: "Years on StayFinder")
        ])
        statsStack.axis = .vertical
        statsStack.spacing = 14

        let row = UIStackView(arrangedSubviews: [leftStack, statsStack])
        row.axis = .horizontal
        row.spacing = 26
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        card.addSubview(badge)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),

            initials.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            initials.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),

            badge.centerXAnchor.constraint(equalTo: avatar.trailingAnchor, constant: -8),
            badge.centerYAnchor.constraint(equalTo: avatar.bottomAnchor, constant: -6),
            badgeIcon.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            badgeIcon.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])

        return card
    }

    private func makeStatView(valueLabel: UILabel, title: String) -> UIView {
        valueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = SfStyle.textPrimary

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.text = title

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = SfStyle.divider
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    private func makeTileRow() -> UIView {
        let pastTripsTile = makePastTripsTile()
        let connectionsTile = makeConnectionsTile()
        pastTripsTile.heightAnchor.constraint(equalToConstant: 238).isActive = true
        connectionsTile.heightAnchor.constraint(equalToConstant: 238).isActive = true
        let row = UIStackView(arrangedSubviews: [pastTripsTile, connectionsTile])
        row.axis = .horizontal
        row.spacing = 18
        row.distribution = .fillEqually
        return row
    }

    private func makePastTripsTile() -> UIControl {
        let card = TapAccessibleControl()
        card.accessibilityIdentifier = "bnb.profile.pastTrips"
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.03
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 5)
        card.addTarget(self, action: #selector(openPastTrips), for: .touchUpInside)

        let badge = makeNewBadge()

        let first = UIImageView(image: UIImage(named: "sf_stay_1"))
        let second = UIImageView(image: UIImage(named: "sf_stay_10"))
        [first, second].forEach { imageView in
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 18
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 4
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 78).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 78).isActive = true
        }
        first.transform = CGAffineTransform(rotationAngle: -0.12)
        second.transform = CGAffineTransform(rotationAngle: 0.08)

        let collage = UIView()
        collage.translatesAutoresizingMaskIntoConstraints = false
        collage.addSubview(second)
        collage.addSubview(first)

        NSLayoutConstraint.activate([
            collage.heightAnchor.constraint(equalToConstant: 120),
            first.leadingAnchor.constraint(equalTo: collage.leadingAnchor),
            first.bottomAnchor.constraint(equalTo: collage.bottomAnchor),
            second.leadingAnchor.constraint(equalTo: collage.leadingAnchor, constant: 46),
            second.topAnchor.constraint(equalTo: collage.topAnchor),
            second.trailingAnchor.constraint(equalTo: collage.trailingAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Past trips"

        let stack = UIStackView(arrangedSubviews: [badge, collage, titleLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    private func makeConnectionsTile() -> UIControl {
        let card = TapAccessibleControl()
        card.accessibilityLabel = "Connections"
        card.accessibilityIdentifier = "bnb.profile.connections"
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.03
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 5)
        card.addTarget(self, action: #selector(openConnections), for: .touchUpInside)

        let badge = makeNewBadge()

        let avatarRow = UIView()
        avatarRow.translatesAutoresizingMaskIntoConstraints = false
        avatarRow.heightAnchor.constraint(equalToConstant: 120).isActive = true

        let previewConnections = Array(store.connections.prefix(3))
        let letters = previewConnections.enumerated().map { item in
            (item.element.initials, item.element.color, item.offset * 24)
        }
        letters.forEach { item in
            let bubble = UIView()
            bubble.backgroundColor = item.1
            bubble.layer.cornerRadius = 38
            bubble.layer.borderColor = UIColor.white.cgColor
            bubble.layer.borderWidth = 4
            bubble.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.font = .systemFont(ofSize: 30, weight: .bold)
            label.textColor = .white
            label.text = item.0
            label.translatesAutoresizingMaskIntoConstraints = false
            bubble.addSubview(label)
            avatarRow.addSubview(bubble)

            NSLayoutConstraint.activate([
                bubble.widthAnchor.constraint(equalToConstant: 76),
                bubble.heightAnchor.constraint(equalToConstant: 76),
                bubble.leadingAnchor.constraint(equalTo: avatarRow.leadingAnchor, constant: CGFloat(item.2)),
                bubble.centerYAnchor.constraint(equalTo: avatarRow.centerYAnchor),
                label.centerXAnchor.constraint(equalTo: bubble.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: bubble.centerYAnchor)
            ])
        }

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Connections"

        let stack = UIStackView(arrangedSubviews: [badge, avatarRow, titleLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    private func makeNewBadge() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .white
        label.text = "  NEW  "
        label.backgroundColor = UIColor(red: 0.26, green: 0.37, blue: 0.55, alpha: 1)
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        return label
    }

    private func makeHostCard() -> UIControl {
        let card = TapAccessibleControl()
        card.accessibilityLabel = "Become a host"
        card.accessibilityIdentifier = "bnb.profile.hosting"
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.03
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 5)
        card.addTarget(self, action: #selector(openHosting), for: .touchUpInside)

        let previewImage = UIImageView(image: UIImage(named: "sf_stay_5"))
        previewImage.contentMode = .scaleAspectFill
        previewImage.clipsToBounds = true
        previewImage.layer.cornerRadius = 20
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewImage.widthAnchor.constraint(equalToConstant: 92).isActive = true
        previewImage.heightAnchor.constraint(equalToConstant: 92).isActive = true

        let badgeLabel = UILabel()
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = SfStyle.accent
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.layer.masksToBounds = true
        badgeLabel.text = "  START HERE  "

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = SfStyle.textPrimary
        titleLabel.text = "Become a host"

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 18, weight: .regular)
        subtitleLabel.textColor = SfStyle.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "It's easy to start hosting and earn extra income."

        let textStack = UIStackView(arrangedSubviews: [badgeLabel, titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 8
        textStack.alignment = .leading

        let row = UIStackView(arrangedSubviews: [previewImage, textStack])
        row.axis = .horizontal
        row.spacing = 18
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])

        return card
    }

    private func makeSettingsSection() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.03
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 5)

        let items: [(String, String, Bool)] = [
            ("person.circle", "Personal information", false),
            ("creditcard", "Payments", false),
            ("bell", "Notifications", false),
            ("lock.shield", "Privacy and security", false),
            ("accessibility", "Accessibility", false),
            ("questionmark.circle", "Help", false),
            ("rectangle.portrait.and.arrow.right", "Log out", true)
        ]

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (index, item) in items.enumerated() {
            if item.2 && index > 0 {
                let sep = UIView()
                sep.backgroundColor = SfStyle.divider
                sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
                let sepWrap = UIView()
                sepWrap.translatesAutoresizingMaskIntoConstraints = false
                sepWrap.heightAnchor.constraint(equalToConstant: 9).isActive = true
                stack.addArrangedSubview(sepWrap)
            }

            let row = TapAccessibleControl()
            row.accessibilityLabel = item.1
            row.accessibilityIdentifier = "bnb.profile.settings.\(index)"
            row.tag = index
            row.addTarget(self, action: #selector(settingsRowTapped(_:)), for: .touchUpInside)
            row.heightAnchor.constraint(equalToConstant: 48).isActive = true

            let icon = UIImageView(image: UIImage(systemName: item.0))
            icon.tintColor = item.2 ? SfStyle.accent : SfStyle.textPrimary
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.widthAnchor.constraint(equalToConstant: 24).isActive = true

            let label = UILabel()
            label.font = .systemFont(ofSize: 17, weight: .regular)
            label.textColor = item.2 ? SfStyle.accent : SfStyle.textPrimary
            label.text = item.1

            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = SfStyle.textSecondary
            chevron.contentMode = .scaleAspectFit
            chevron.translatesAutoresizingMaskIntoConstraints = false
            chevron.widthAnchor.constraint(equalToConstant: 14).isActive = true

            let rowStack = UIStackView(arrangedSubviews: [icon, label, UIView(), chevron])
            rowStack.axis = .horizontal
            rowStack.spacing = 14
            rowStack.alignment = .center
            rowStack.isUserInteractionEnabled = false
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(rowStack)

            NSLayoutConstraint.activate([
                rowStack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                rowStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                rowStack.topAnchor.constraint(equalTo: row.topAnchor),
                rowStack.bottomAnchor.constraint(equalTo: row.bottomAnchor)
            ])

            stack.addArrangedSubview(row)

            if !item.2 && index < items.count - 1 {
                let div = UIView()
                div.backgroundColor = UIColor(white: 0.93, alpha: 1)
                div.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(div)
            }
        }

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    @objc private func settingsRowTapped(_ sender: UIControl) {
        if sender.tag == 6 {
            let alert = UIAlertController(title: "Log out", message: "Are you sure you want to log out?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Log out", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                let loggedOutVC = UIViewController()
                loggedOutVC.view.backgroundColor = SfStyle.background
                let stack = UIStackView()
                stack.axis = .vertical
                stack.spacing = 16
                stack.alignment = .center
                stack.translatesAutoresizingMaskIntoConstraints = false
                loggedOutVC.view.addSubview(stack)
                NSLayoutConstraint.activate([
                    stack.centerXAnchor.constraint(equalTo: loggedOutVC.view.centerXAnchor),
                    stack.centerYAnchor.constraint(equalTo: loggedOutVC.view.centerYAnchor),
                    stack.leadingAnchor.constraint(equalTo: loggedOutVC.view.leadingAnchor, constant: 40),
                    stack.trailingAnchor.constraint(equalTo: loggedOutVC.view.trailingAnchor, constant: -40)
                ])
                let icon = UIImageView(image: UIImage(systemName: "person.crop.circle.badge.checkmark"))
                icon.tintColor = SfStyle.textSecondary
                icon.contentMode = .scaleAspectFit
                icon.translatesAutoresizingMaskIntoConstraints = false
                icon.heightAnchor.constraint(equalToConstant: 64).isActive = true
                icon.widthAnchor.constraint(equalToConstant: 64).isActive = true
                let titleLabel = UILabel()
                titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
                titleLabel.textColor = SfStyle.textPrimary
                titleLabel.text = "You've been logged out"
                titleLabel.textAlignment = .center
                let subtitleLabel = UILabel()
                subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
                subtitleLabel.textColor = SfStyle.textSecondary
                subtitleLabel.text = "Thanks for using StayFinder, \(self.store.profile.firstName)."
                subtitleLabel.textAlignment = .center
                subtitleLabel.numberOfLines = 0
                stack.addArrangedSubview(icon)
                stack.addArrangedSubview(titleLabel)
                stack.addArrangedSubview(subtitleLabel)

                if let tabBar = self.tabBarController {
                    for vc in tabBar.viewControllers ?? [] {
                        (vc as? UINavigationController)?.popToRootViewController(animated: false)
                    }
                    tabBar.selectedIndex = 4
                }
                self.navigationController?.pushViewController(loggedOutVC, animated: true)
            })
            present(alert, animated: true)
        } else {
            let vc: UIViewController
            switch sender.tag {
            case 0:
                vc = makePersonalInfoViewController()
            case 1:
                vc = makePaymentsViewController()
            case 2:
                vc = makeNotificationSettingsViewController()
            case 3:
                vc = makePrivacyViewController()
            case 4:
                vc = makeAccessibilityViewController()
            case 5:
                vc = makeHelpViewController()
            default:
                return
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func makePersonalInfoViewController() -> UIViewController {
        let vc = UIViewController()
        vc.title = "Personal information"
        vc.view.backgroundColor = SfStyle.background
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.addSubview(stack)
        vc.view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            card.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        let rows: [(String, String)] = [
            ("Full name", store.profile.fullName),
            ("Email", "jordan.avery@email.com"),
            ("Phone", "+1 (415) 555-0198"),
            ("Location", store.profile.location),
            ("Emergency contact", "Morgan Avery"),
            ("Government ID", "Verified")
        ]
        for (i, row) in rows.enumerated() {
            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
            titleLabel.textColor = SfStyle.textSecondary
            titleLabel.text = row.0
            let valueLabel = UILabel()
            valueLabel.font = .systemFont(ofSize: 17, weight: .regular)
            valueLabel.textColor = SfStyle.textPrimary
            valueLabel.text = row.1
            let rowStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
            rowStack.axis = .vertical
            rowStack.spacing = 4
            rowStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
            stack.addArrangedSubview(rowStack)
            if i < rows.count - 1 {
                let div = UIView()
                div.backgroundColor = SfStyle.divider
                div.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(div)
            }
        }
        return vc
    }

    private func makePaymentsViewController() -> UIViewController {
        let vc = UIViewController()
        vc.title = "Payments"
        vc.view.backgroundColor = SfStyle.background
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        let payments: [(String, String, String)] = [
            ("VISA", "**** 2095", "Freedom Unlimited"),
            ("VISA DEBIT", "**** 6645", "Total Checking"),
            ("MASTERCARD DEBIT", "**** 7814", "Savings")
        ]
        for pay in payments {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 16
            let networkLabel = UILabel()
            networkLabel.font = .systemFont(ofSize: 13, weight: .bold)
            networkLabel.textColor = SfStyle.accent
            networkLabel.text = pay.0
            let numberLabel = UILabel()
            numberLabel.font = .systemFont(ofSize: 17, weight: .medium)
            numberLabel.textColor = SfStyle.textPrimary
            numberLabel.text = pay.1
            let nameLabel = UILabel()
            nameLabel.font = .systemFont(ofSize: 14, weight: .regular)
            nameLabel.textColor = SfStyle.textSecondary
            nameLabel.text = pay.2
            let inner = UIStackView(arrangedSubviews: [networkLabel, numberLabel, nameLabel])
            inner.axis = .vertical
            inner.spacing = 4
            inner.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(inner)
            NSLayoutConstraint.activate([
                inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
            stack.addArrangedSubview(card)
        }
        return vc
    }

    private func makeNotificationSettingsViewController() -> UIViewController {
        let vc = UIViewController()
        vc.title = "Notifications"
        vc.view.backgroundColor = SfStyle.background
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        let items: [(String, Bool)] = [
            ("Booking confirmations", true),
            ("Trip reminders", true),
            ("Price alerts", false),
            ("Host messages", true),
            ("Promotions and tips", false),
            ("Account activity", true)
        ]
        for item in items {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 16
            let label = UILabel()
            label.font = .systemFont(ofSize: 17, weight: .regular)
            label.textColor = SfStyle.textPrimary
            label.text = item.0
            let toggle = UISwitch()
            toggle.isOn = item.1
            toggle.onTintColor = SfStyle.accent
            let row = UIStackView(arrangedSubviews: [label, toggle])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
            ])
            stack.addArrangedSubview(card)
        }
        return vc
    }

    private func makePrivacyViewController() -> UIViewController {
        let vc = UIViewController()
        vc.title = "Privacy and security"
        vc.view.backgroundColor = SfStyle.background
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        let items: [(String, String)] = [
            ("Two-factor authentication", "Enabled"),
            ("Login activity", "1 active session"),
            ("Data sharing", "Only with hosts"),
            ("Search history", "Saved"),
            ("Third-party connections", "None")
        ]
        for item in items {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 16
            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
            titleLabel.textColor = SfStyle.textPrimary
            titleLabel.text = item.0
            let valueLabel = UILabel()
            valueLabel.font = .systemFont(ofSize: 15, weight: .medium)
            valueLabel.textColor = SfStyle.textSecondary
            valueLabel.text = item.1
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = SfStyle.textTertiary
            chevron.translatesAutoresizingMaskIntoConstraints = false
            chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true
            let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel, chevron])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 8
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
            stack.addArrangedSubview(card)
        }
        return vc
    }

    private func makeAccessibilityViewController() -> UIViewController {
        let vc = UIViewController()
        vc.title = "Accessibility"
        vc.view.backgroundColor = SfStyle.background
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        let items: [(String, Bool)] = [
            ("Screen reader optimizations", true),
            ("Reduce motion", false),
            ("High contrast mode", false),
            ("Larger text", false)
        ]
        for item in items {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 16
            let label = UILabel()
            label.font = .systemFont(ofSize: 17, weight: .regular)
            label.textColor = SfStyle.textPrimary
            label.text = item.0
            let toggle = UISwitch()
            toggle.isOn = item.1
            toggle.onTintColor = SfStyle.accent
            let row = UIStackView(arrangedSubviews: [label, toggle])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
            ])
            stack.addArrangedSubview(card)
        }
        return vc
    }

    private func makeHelpViewController() -> UIViewController {
        let vc = UIViewController()
        vc.title = "Help"
        vc.view.backgroundColor = SfStyle.background
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        let items: [(String, String)] = [
            ("How booking works", "Learn about reservations, payments, and confirmations"),
            ("Cancellation policies", "Understand refund timelines and host policies"),
            ("Account and security", "Manage your login, password, and identity verification"),
            ("Contact support", "Reach our team for urgent issues or questions"),
            ("Safety tips", "Stay safe while traveling and hosting")
        ]
        for item in items {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 16
            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            titleLabel.textColor = SfStyle.textPrimary
            titleLabel.text = item.0
            let descLabel = UILabel()
            descLabel.font = .systemFont(ofSize: 14, weight: .regular)
            descLabel.textColor = SfStyle.textSecondary
            descLabel.numberOfLines = 0
            descLabel.text = item.1
            let inner = UIStackView(arrangedSubviews: [titleLabel, descLabel])
            inner.axis = .vertical
            inner.spacing = 4
            inner.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(inner)
            NSLayoutConstraint.activate([
                inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
            stack.addArrangedSubview(card)
        }
        return vc
    }

    @objc private func refresh() {
        let activeTrips = store.bookings.filter { $0.status != .canceled }.count
        tripCountLabel.text = "\(activeTrips)"
        reviewsCountLabel.text = "\(store.profile.reviewCount)"
        yearsCountLabel.text = "\(store.profile.yearsOnStayFinder)"
    }

    @objc private func openPastTrips() {
        let controller = PastTripsViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func openNotifications() {
        navigationController?.pushViewController(NotificationsViewController(notifications: store.notifications), animated: true)
    }

    @objc private func openConnections() {
        navigationController?.pushViewController(ConnectionsViewController(connections: store.connections), animated: true)
    }

    @objc private func openHosting() {
        navigationController?.pushViewController(HostingIntroViewController(), animated: true)
    }

    func openPastTripsForTesting() {
        openPastTrips()
    }

    func openNotificationsForTesting() {
        openNotifications()
    }

    func openHostingForTesting() {
        openHosting()
    }
}

final class PastTripsViewController: UIViewController {
    private let store = SfStore.shared
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Past trips"
        view.backgroundColor = SfStyle.background
        configureLayout()
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refresh()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func refresh() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let pastBookings = store.pastBookings()
        if pastBookings.isEmpty {
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.textColor = SfStyle.textSecondary
            label.text = "No past trips yet."
            stack.addArrangedSubview(label)
            return
        }

        pastBookings.forEach { booking in
            guard let listing = store.listing(for: booking.listingId) else { return }
            let card = BookingSummaryCardView()
            card.configure(listing: listing, booking: booking)
            card.accessibilityIdentifier = booking.id
            card.addTarget(self, action: #selector(openPastBooking(_:)), for: .touchUpInside)
            stack.addArrangedSubview(card)
        }
    }

    @objc private func openPastBooking(_ sender: BookingSummaryCardView) {
        guard let bookingID = sender.accessibilityIdentifier,
              let booking = store.bookings.first(where: { $0.id == bookingID }),
              let listing = store.listing(for: booking.listingId) else { return }

        if booking.status == .completed {
            let alert = UIAlertController(title: listing.title, message: "What would you like to do?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "View listing", style: .default) { [weak self] _ in
                self?.navigationController?.pushViewController(ListingDetailViewController(listing: listing), animated: true)
            })
            alert.addAction(UIAlertAction(title: "Leave a review", style: .default) { [weak self] _ in
                self?.showReviewSheet(for: listing, bookingID: bookingID)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            navigationController?.pushViewController(ListingDetailViewController(listing: listing), animated: true)
        }
    }

    private func showReviewSheet(for listing: Listing, bookingID: String) {
        let alert = UIAlertController(title: "Rate \(listing.title)", message: "How was your stay?", preferredStyle: .alert)
        let ratings = ["5 - Excellent", "4 - Great", "3 - Good", "2 - Fair", "1 - Poor"]
        for rating in ratings {
            alert.addAction(UIAlertAction(title: rating, style: .default) { [weak self] _ in
                self?.showReviewTextInput(for: listing, rating: rating)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showReviewTextInput(for listing: Listing, rating: String) {
        let alert = UIAlertController(title: "Write a review", message: "Share your experience at \(listing.title)", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "What did you enjoy about your stay?"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            let confirmation = UIAlertController(title: "Review submitted", message: "Thanks for your \(rating.prefix(1))-star review of \(listing.title)!", preferredStyle: .alert)
            confirmation.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(confirmation, animated: true)
        })
        present(alert, animated: true)
    }
}

final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private var conversation: Conversation
    private let store = SfStore.shared
    private let tableView = UITableView()
    private let inputField = UITextField()
    private let transcriptSummaryView = UIView()
    private var inputContainerBottomConstraint: NSLayoutConstraint?

    init(conversation: Conversation) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "bnb.chat.screen"
        title = conversation.title
        view.backgroundColor = .white
        configureLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardFrameChange(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardFrameChange(_:)), name: .UIKeyboardWillHide, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        store.markConversationRead(conversation.id)
        conversation.unreadCount = 0
    }

    private func configureNavBarItems() {
        if store.listing(for: conversation.listingId) != nil {
            let listingBtn = UIBarButtonItem(image: UIImage(systemName: "house"), style: .plain, target: self, action: #selector(openListing))
            listingBtn.tintColor = SfStyle.accent
            listingBtn.accessibilityLabel = "View listing"
            navigationItem.rightBarButtonItem = listingBtn
        }
    }

    @objc private func openListing() {
        guard let listing = store.listing(for: conversation.listingId) else { return }
        navigationController?.pushViewController(ListingDetailViewController(listing: listing), animated: true)
    }

    private func configureLayout() {
        configureNavBarItems()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.accessibilityIdentifier = "bnb.chat.messages"
        view.addSubview(tableView)

        transcriptSummaryView.translatesAutoresizingMaskIntoConstraints = false
        transcriptSummaryView.isAccessibilityElement = true
        transcriptSummaryView.accessibilityIdentifier = "bnb.chat.transcriptSummary"
        transcriptSummaryView.accessibilityTraits = UIAccessibilityTraitStaticText
        transcriptSummaryView.backgroundColor = .clear
        transcriptSummaryView.alpha = 0.01
        view.addSubview(transcriptSummaryView)

        let inputContainer = UIView()
        inputContainer.backgroundColor = .white
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.layer.borderColor = SfStyle.divider.cgColor
        inputContainer.layer.borderWidth = 1

        inputField.borderStyle = .roundedRect
        inputField.placeholder = "Type a message"
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.accessibilityIdentifier = "bnb.chat.input"
        inputField.returnKeyType = .send
        inputField.delegate = self

        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(SfStyle.accent, for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.accessibilityIdentifier = "bnb.chat.send"

        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)
        view.addSubview(inputContainer)

        inputContainerBottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint!,

            transcriptSummaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            transcriptSummaryView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            transcriptSummaryView.widthAnchor.constraint(equalToConstant: 1),
            transcriptSummaryView.heightAnchor.constraint(equalToConstant: 1),

            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputField.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 10),
            inputField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -10),

            sendButton.leadingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 50),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor)
        ])

        updateTranscriptAccessibility()
    }

    @objc private func sendTapped() {
        let text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let message = Message(id: UUID().uuidString, text: text, isHost: false, timestamp: Date())
        conversation.messages.append(message)
        store.updateConversation(conversation)
        inputField.text = ""
        tableView.reloadData()
        updateTranscriptAccessibility()
        scrollToBottom(animated: false)
        respondFromHost(to: text)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return false
    }

    private func respondFromHost(to guestMessage: String) {
        // Show typing indicator
        let typingID = "__typing__"
        let typingMsg = Message(id: typingID, text: "···", isHost: true, timestamp: Date())
        conversation.messages.append(typingMsg)
        tableView.reloadData()
        scrollToBottom(animated: true)

        let llm = LLMService.shared
        guard llm.isAvailable, let listing = store.listing(for: conversation.listingId) else {
            deliverReply(replaceTypingID: typingID, fallbackFor: guestMessage)
            return
        }

        let history = conversation.messages
            .filter { $0.id != typingID }
            .dropLast()
            .map { (role: $0.isHost ? "host" : "guest", text: $0.text) }

        llm.generateHostReply(
            hostName: conversation.hostName,
            listingTitle: listing.title,
            listingLocation: listing.location,
            listingKind: "\(listing.kind)",
            amenities: listing.amenities,
            conversationHistory: history,
            guestMessage: guestMessage
        ) { [weak self] reply in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let reply = reply {
                    self.replaceTypingIndicator(typingID: typingID, text: reply)
                } else {
                    self.deliverReply(replaceTypingID: typingID, fallbackFor: guestMessage)
                }
            }
        }
    }

    private func deliverReply(replaceTypingID typingID: String, fallbackFor guestMessage: String) {
        let reply = store.generatedHostReply(for: conversation, guestMessage: guestMessage)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.replaceTypingIndicator(typingID: typingID, text: reply)
        }
    }

    private func replaceTypingIndicator(typingID: String, text: String) {
        if let idx = conversation.messages.firstIndex(where: { $0.id == typingID }) {
            conversation.messages[idx] = Message(id: UUID().uuidString, text: text, isHost: true, timestamp: Date())
        } else {
            conversation.messages.append(Message(id: UUID().uuidString, text: text, isHost: true, timestamp: Date()))
        }
        store.updateConversation(conversation)
        tableView.reloadData()
        updateTranscriptAccessibility()
        scrollToBottom(animated: true)
    }

    private func updateTranscriptAccessibility() {
        let transcript = conversation.messages.map { $0.text }.joined(separator: "\n")
        tableView.accessibilityValue = transcript
        transcriptSummaryView.accessibilityLabel = transcript
        transcriptSummaryView.accessibilityValue = transcript
    }

    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
              let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
              let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else { return }

        let frameInView = view.convert(frameValue.cgRectValue, from: nil)
        let overlap = max(0, view.bounds.maxY - frameInView.minY)
        inputContainerBottomConstraint?.constant = -overlap

        UIView.animate(
            withDuration: duration.doubleValue,
            delay: 0,
            options: UIViewAnimationOptions(rawValue: UInt(curve.intValue << 16)),
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }

    private func scrollToBottom(animated: Bool) {
        guard !conversation.messages.isEmpty else { return }
        let lastRow = IndexPath(row: conversation.messages.count - 1, section: 0)
        tableView.scrollToRow(at: lastRow, at: .bottom, animated: animated)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversation.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        cell.configure(message: conversation.messages[indexPath.row])
        return cell
    }
}

final class MessageCell: UITableViewCell {
    private let bubble = UIView()
    private let messageLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        selectionStyle = .none
        isAccessibilityElement = false
        contentView.isAccessibilityElement = false
        bubble.layer.cornerRadius = 16
        bubble.isAccessibilityElement = false
        bubble.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 14, weight: .regular)
        messageLabel.isAccessibilityElement = true
        messageLabel.accessibilityTraits = UIAccessibilityTraitStaticText
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(bubble)
        bubble.addSubview(messageLabel)

        leadingConstraint = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            messageLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            messageLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8)
        ])
    }

    func configure(message: Message) {
        messageLabel.text = message.text
        messageLabel.accessibilityLabel = message.text
        messageLabel.accessibilityIdentifier = "bnb.chat.message.\(message.id)"
        if message.isHost {
            bubble.backgroundColor = SfStyle.background
            messageLabel.textColor = SfStyle.textPrimary
            leadingConstraint?.isActive = true
            trailingConstraint?.isActive = false
        } else {
            bubble.backgroundColor = SfStyle.accent
            messageLabel.textColor = .white
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        }
    }
}

enum StayFinderPaymentAccountType: String, Codable {
    case checking
    case savings
    case credit
}

struct StayFinderPaymentAccount: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: StayFinderPaymentAccountType
    let balance: Double
    let availableBalance: Double
    let currency: String
    let lastUpdated: Date
    let creditLimit: Double?

    var maskedNumber: String {
        switch type {
        case .checking: return "**** **** **** 6645"
        case .savings: return "**** **** **** 7814"
        case .credit: return "**** **** **** 2095"
        }
    }

    var network: String {
        switch type {
        case .credit: return "VISA"
        case .checking: return "VISA DEBIT"
        case .savings: return "MASTERCARD DEBIT"
        }
    }

    var shortName: String {
        switch type {
        case .credit: return "Credit"
        case .checking: return "Checking"
        case .savings: return "Savings"
        }
    }
}

final class StayFinderMyBankAccountsService {
    private let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private let fileName = "mybank_accounts.json"

    private var accountsURL: URL {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    func loadAccounts() -> [StayFinderPaymentAccount] {
        guard let data = try? Data(contentsOf: accountsURL) else {
            return defaultAccounts()
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([StayFinderPaymentAccount].self, from: data), !decoded.isEmpty {
            return decoded
        }
        return defaultAccounts()
    }

    private func defaultAccounts() -> [StayFinderPaymentAccount] {
        let now = Date()
        return [
            StayFinderPaymentAccount(
                id: UUID(),
                name: "Total Checking (...6645)",
                type: .checking,
                balance: 2150.32,
                availableBalance: 2150.32,
                currency: "USD",
                lastUpdated: now,
                creditLimit: nil
            ),
            StayFinderPaymentAccount(
                id: UUID(),
                name: "Savings (...1032)",
                type: .savings,
                balance: 9400.0,
                availableBalance: 9400.0,
                currency: "USD",
                lastUpdated: now,
                creditLimit: nil
            ),
            StayFinderPaymentAccount(
                id: UUID(),
                name: "Freedom Unlimited (...2095)",
                type: .credit,
                balance: -642.13,
                availableBalance: 5357.87,
                currency: "USD",
                lastUpdated: now,
                creditLimit: 6000.0
            )
        ]
    }
}

struct StayFinderMyBankLedgerWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let ledgerFileName = "mybank_ledger.json"
    private static let ioQueue = DispatchQueue(label: "stayfinder.ledger.io", qos: .utility)

    private struct LedgerTransaction: Codable {
        let id: UUID
        let externalId: String
        let accountId: UUID
        let vendor: String
        let amount: Double
        let currency: String
        let category: String
        let note: String?
        let timestamp: Date
        let status: String
        let sourceApp: String
        let rawSource: String

        enum CodingKeys: String, CodingKey {
            case id
            case externalId = "external_id"
            case accountId = "account_id"
            case vendor
            case amount
            case currency
            case category
            case note
            case timestamp
            case status
            case sourceApp = "source_app"
            case rawSource = "raw_source"
        }
    }

    static func recordBooking(booking: Booking, listing: Listing, total: Double, paymentAccountId: UUID) {
        guard let url = ledgerURL() else {
            print("[MyBank] App Group unavailable; StayFinder ledger write skipped.")
            return
        }

        let note = "\(listing.title) • guests: \(booking.guests)"
        let transaction = LedgerTransaction(
            id: UUID(),
            externalId: booking.id,
            accountId: paymentAccountId,
            vendor: listing.title,
            amount: -abs(total),
            currency: "USD",
            category: listing.kind == .experience ? "Experiences" : (listing.kind == .service ? "Services" : "Travel"),
            note: note,
            timestamp: Date(),
            status: "pending",
            sourceApp: "StayFinder",
            rawSource: "stayfinder_checkout"
        )

        ioQueue.async {
            var records = loadLedger(from: url)
            if records.contains(where: { $0.externalId == transaction.externalId }) {
                return
            }
            records.append(transaction)
            saveLedger(records, to: url)
        }
    }

    private static func ledgerURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(ledgerFileName)
        }
        return nil
    }

    private static func loadLedger(from url: URL) -> [LedgerTransaction] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([LedgerTransaction].self, from: data)) ?? []
    }

    private static func saveLedger(_ records: [LedgerTransaction], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[MyBank] Failed to write StayFinder ledger: \(error)")
        }
    }
}

struct StayFinderMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "stayfinder.outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordBookingEmail(booking: Booking, listing: Listing, total: Double, nights: Int, guests: Int, guestFirstName: String) {
        guard let url = inboxURL() else {
            print("[Mail] App Group unavailable; StayFinder email write skipped.")
            return
        }

        let totalText = String(format: "$%.2f", total)
        let subject = "Your StayFinder booking is confirmed"
        let staySummary: String
        if listing.kind != .stay {
            staySummary = "Guests: \(guests)"
        } else {
            staySummary = "Nights: \(nights), Guests: \(guests)"
        }
        let body = """
        Hi \(guestFirstName),

        Your StayFinder booking is confirmed.

        Listing: \(listing.title)
        \(staySummary)
        Total: \(totalText)
        Booking ID: \(booking.id)

        Thanks,
        StayFinder
        """

        let record = MailRecord(
            id: UUID(),
            from: "StayFinder",
            subject: subject,
            body: body,
            category: 1,
            date: Date()
        )

        let bookingId = booking.id
        ioQueue.async {
            var records = loadRecords(from: url)
            if records.contains(where: { $0.body.contains(bookingId) }) {
                return
            }
            records.append(record)
            saveRecords(records, to: url)
        }
    }

    private static func inboxURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        return nil
    }

    private static func loadRecords(from url: URL) -> [MailRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MailRecord].self, from: data)) ?? []
    }

    private static func saveRecords(_ records: [MailRecord], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[Mail] Failed to write StayFinder email: \(error)")
        }
    }
}
