import Foundation

struct SeedData {
    static let youID = "user_you"
    static let systemID = "user_venmo"

    static func users() -> [User] {
        coreUsers() + suggestedUsers()
    }

    static func requestContactBackedUsers(completion: @escaping ([User]) -> Void) {
        completion([])
    }

    static func coreUsers() -> [User] {
        [
            User(id: youID, username: "Jordan-Avery", displayName: "Jordan Avery", avatarSeed: "jordan", isYou: true),
            User(id: systemID, username: "splitpay", displayName: "SplitPay", avatarSeed: "business_venmo", isYou: false),
            User(id: "user_brian", username: "Maya-Patel", displayName: "Maya Patel", avatarSeed: "maya", isYou: false),
            User(id: "user_trevor", username: "Leo-Chen", displayName: "Leo Chen", avatarSeed: "leo", isYou: false),
            User(id: "user_chenchen", username: "Camille-Hart", displayName: "Camille Hart", avatarSeed: "camille", isYou: false),
            User(id: "user_abi", username: "Priya-Raman", displayName: "Priya Raman", avatarSeed: "priya", isYou: false),
            User(id: "user_arnav", username: "arnavs", displayName: "Arnav Srikanth", avatarSeed: "arnav", isYou: false),
            User(id: "user_spencer", username: "spencerbowman", displayName: "Spencer Bowman", avatarSeed: "spencer", isYou: false),
            User(id: "user_theo", username: "Theo-Nguyen", displayName: "Theo Nguyen", avatarSeed: "theo", isYou: false),
            User(id: "user_sharp", username: "sharp_sports", displayName: "Sharp Sports Consulting LLC", avatarSeed: "business_sharp", isYou: false),
            User(id: "user_jing", username: "Nina-Brooks", displayName: "Nina Brooks", avatarSeed: "nina", isYou: false),
            User(id: "user_shuyan", username: "Kai-Santos", displayName: "Kai Santos", avatarSeed: "kai", isYou: false),
            User(id: "user_doordash", username: "doordash", displayName: "QuickBite", avatarSeed: "business_doordash", isYou: false),
            User(id: "user_diego", username: "Diego-Martinez", displayName: "Diego Martinez", avatarSeed: "diego", isYou: false),
            User(id: "user_sofia", username: "Sofia-Reyes", displayName: "Sofia Reyes", avatarSeed: "sofia", isYou: false),
            User(id: "user_elena", username: "Elena-Brooks", displayName: "Elena Brooks", avatarSeed: "elena", isYou: false),
            User(id: "user_rohan", username: "Rohan-Mehta", displayName: "Rohan Mehta", avatarSeed: "rohan", isYou: false)
        ]
    }

    private static func suggestedUsers() -> [User] {
        let names = [
            "Ava Torres", "Miles Chen", "Noah Patel", "Grace Lin", "Sam Rivera",
            "Ruby Flores", "Mason Ward", "Henry Cooper", "Sofia Kim", "Chloe Bennett",
            "Jack Sullivan", "Lila Brooks", "Jules Park", "Celeste Huang", "Ravi Krishnan",
            "Amara Osei", "Juno Adler", "Kira Nakamura", "Declan Walsh", "Callum Reed",
            "Felix Delgado", "Hazel Dunn", "Dante Morales", "Oscar Leung"
        ]

        return names.enumerated().map { index, name in
            let handle = name.lowercased().replacingOccurrences(of: " ", with: "_")
            return User(
                id: "user_suggested_\(index)",
                username: handle,
                displayName: name,
                avatarSeed: "suggested_\(index)",
                isYou: false
            )
        }
    }

    static func fundingSources() -> [FundingSource] {
        [
            FundingSource(id: "balance", name: "SplitPay balance", subtitle: "Available instantly", isBalance: true),
            FundingSource(id: "debit", name: "Chase Visa Debit", subtitle: "Personal •••• 6645", isBalance: false),
            FundingSource(id: "credit", name: "Apple Pay", subtitle: "Visa •••• 2095", isBalance: false)
        ]
    }

    static func transactions(users: [User]) -> [Transaction] {
        let lookup = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        guard lookup[youID] != nil else { return [] }

        let activity: [Transaction] = [
            transaction(from: "user_arnav", to: "user_spencer", amount: 46, memo: "february utilities", minutesAgo: 5, privacy: .friends, funding: "debit"),
            transaction(from: "user_theo", to: "user_sharp", amount: 175, memo: "For services", hoursAgo: 15, privacy: .friends, funding: "debit"),
            transaction(from: "user_brian", to: youID, amount: 18, memo: "coffee before standup", daysAgo: 1, privacy: .friends, funding: "balance"),
            transaction(from: youID, to: "user_trevor", amount: 62, memo: "Pirates tickets", daysAgo: 2, privacy: .friends, funding: "debit"),
            transaction(from: "user_chenchen", to: "user_abi", amount: 24, memo: "dumplings", daysAgo: 2, privacy: .public, funding: "debit"),
            transaction(from: "user_spencer", to: "user_brian", amount: 85, memo: "golf weekend deposit", daysAgo: 3, privacy: .public, funding: "credit"),
            transaction(from: youID, to: "user_arnav", amount: 101, memo: "apartment wifi", daysAgo: 4, privacy: .private, funding: "balance"),
            transaction(from: "user_jing", to: "user_shuyan", amount: 14, memo: "boba", daysAgo: 5, privacy: .public, funding: "debit"),
            transaction(from: "user_abi", to: youID, amount: 12, memo: "garage parking", daysAgo: 6, privacy: .friends, funding: "balance"),
            transaction(from: systemID, to: youID, amount: 120, memo: "Added funds", daysAgo: 7, privacy: .private, funding: "balance"),
            transaction(from: "user_shuyan", to: "user_jing", amount: 32, memo: "grocery run", daysAgo: 1, privacy: .friends, funding: "debit"),
            transaction(from: youID, to: "user_brian", amount: 38, memo: "concert merch", daysAgo: 3, privacy: .public, funding: "debit"),
            transaction(from: "user_trevor", to: "user_spencer", amount: 22, memo: "lunch at the taco spot", daysAgo: 4, privacy: .public, funding: "debit"),
            transaction(from: "user_chenchen", to: youID, amount: 45, memo: "escape room split", daysAgo: 5, privacy: .friends, funding: "balance"),
            transaction(from: "user_brian", to: "user_trevor", amount: 110, memo: "StayFinder deposit", daysAgo: 6, privacy: .friends, funding: "debit"),
            transaction(from: youID, to: "user_doordash", amount: 28, memo: "friday night order", daysAgo: 7, privacy: .private, funding: "debit"),
            transaction(from: "user_spencer", to: youID, amount: 55, memo: "fantasy league payout", daysAgo: 8, privacy: .public, funding: "balance"),
            transaction(from: "user_arnav", to: "user_chenchen", amount: 19, memo: "matcha", hoursAgo: 3, privacy: .public, funding: "debit"),
            transaction(from: "user_abi", to: "user_arnav", amount: 35, memo: "uber to airport", daysAgo: 3, privacy: .friends, funding: "debit"),
            transaction(from: youID, to: "user_shuyan", amount: 75, memo: "Warriors game tickets", daysAgo: 9, privacy: .friends, funding: "debit"),

            // ── 10–15 days ago (late Feb) ──
            transaction(from: "user_brian", to: youID, amount: 34, memo: "sushi night 🍣", daysAgo: 10, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_diego", amount: 23, memo: "uber last night", daysAgo: 11, privacy: .friends, funding: "balance"),
            transaction(from: "user_sofia", to: "user_elena", amount: 16, memo: "iced oat latte ☕", daysAgo: 11, privacy: .public, funding: "debit"),
            transaction(from: "user_rohan", to: youID, amount: 42, memo: "thai food split 🍜", daysAgo: 12, privacy: .friends, funding: "debit"),
            transaction(from: youID, to: "user_theo", amount: 55, memo: "warriors tix 🏀", daysAgo: 13, privacy: .friends, funding: "debit"),
            transaction(from: "user_elena", to: youID, amount: 9, memo: "bagel run", daysAgo: 14, privacy: .public, funding: "balance"),
            transaction(from: "user_trevor", to: "user_diego", amount: 27, memo: "bowling 🎳", daysAgo: 14, privacy: .friends, funding: "debit"),
            transaction(from: "user_arnav", to: youID, amount: 650, memo: "rent march 🏠", daysAgo: 15, privacy: .private, funding: "debit"),

            // ── 16–25 days ago (mid Feb) ──
            transaction(from: youID, to: "user_brian", amount: 19, memo: "coffee + pastry", daysAgo: 16, privacy: .friends, funding: "balance"),
            transaction(from: "user_spencer", to: "user_trevor", amount: 40, memo: "valentines dinner split", daysAgo: 17, privacy: .friends, funding: "debit"),
            transaction(from: youID, to: "user_sofia", amount: 50, memo: "galentines brunch 🥂", daysAgo: 17, privacy: .public, funding: "debit"),
            transaction(from: "user_diego", to: youID, amount: 15, memo: "lyft home", daysAgo: 18, privacy: .friends, funding: "balance"),
            transaction(from: "user_chenchen", to: "user_brian", amount: 32, memo: "hot pot ingredients 🍲", daysAgo: 19, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_rohan", amount: 120, memo: "super bowl squares payout 🏈", daysAgo: 20, privacy: .public, funding: "balance"),
            transaction(from: "user_abi", to: "user_sofia", amount: 28, memo: "target run", daysAgo: 21, privacy: .friends, funding: "debit"),
            transaction(from: "user_shuyan", to: youID, amount: 7.50, memo: "boba 🧋", daysAgo: 22, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_elena", amount: 35, memo: "escape room 🔐", daysAgo: 23, privacy: .friends, funding: "debit"),
            transaction(from: "user_brian", to: "user_trevor", amount: 65, memo: "concert tickets 🎶", daysAgo: 24, privacy: .friends, funding: "debit"),

            // ── 26–40 days ago (late Jan – early Feb) ──
            transaction(from: "user_rohan", to: "user_arnav", amount: 22, memo: "pho 🍜", daysAgo: 26, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_spencer", amount: 85, memo: "ski lift tickets ⛷️", daysAgo: 28, privacy: .friends, funding: "debit"),
            transaction(from: "user_trevor", to: youID, amount: 44, memo: "pizza night 🍕", daysAgo: 29, privacy: .public, funding: "balance"),
            transaction(from: "user_diego", to: "user_sofia", amount: 13, memo: "parking meter", daysAgo: 30, privacy: .private, funding: "debit"),
            transaction(from: youID, to: "user_brian", amount: 30, memo: "happy hour 🍻", daysAgo: 32, privacy: .public, funding: "debit"),
            transaction(from: "user_arnav", to: youID, amount: 650, memo: "rent february 🏠", daysAgo: 33, privacy: .private, funding: "debit"),
            transaction(from: "user_elena", to: "user_chenchen", amount: 18, memo: "smoothie bowls 🥣", daysAgo: 34, privacy: .friends, funding: "debit"),
            transaction(from: "user_sofia", to: youID, amount: 75, memo: "bday dinner!! 🎂🥳", daysAgo: 36, privacy: .public, funding: "balance"),
            transaction(from: youID, to: "user_theo", amount: 25, memo: "late bday gift 🎁", daysAgo: 37, privacy: .friends, funding: "debit"),
            transaction(from: "user_spencer", to: "user_diego", amount: 52, memo: "climbing gym day pass", daysAgo: 38, privacy: .friends, funding: "credit"),
            transaction(from: youID, to: "user_shuyan", amount: 17, memo: "ramen 🍜", daysAgo: 40, privacy: .public, funding: "debit"),

            // ── 41–55 days ago (mid–late Jan) ──
            transaction(from: "user_abi", to: youID, amount: 20, memo: "movie ticket 🎬", daysAgo: 42, privacy: .friends, funding: "balance"),
            transaction(from: youID, to: "user_diego", amount: 95, memo: "group trip gas money ⛽", daysAgo: 44, privacy: .friends, funding: "debit"),
            transaction(from: "user_brian", to: youID, amount: 47, memo: "dinner at that italian place 🍝", daysAgo: 45, privacy: .public, funding: "debit"),
            transaction(from: "user_trevor", to: "user_sofia", amount: 60, memo: "karaoke room 🎤", daysAgo: 46, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_rohan", amount: 11, memo: "coffee ☕", daysAgo: 48, privacy: .friends, funding: "balance"),
            transaction(from: "user_chenchen", to: youID, amount: 38, memo: "grocery split 🛒", daysAgo: 50, privacy: .friends, funding: "debit"),
            transaction(from: "user_shuyan", to: "user_jing", amount: 26, memo: "dim sum", daysAgo: 52, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_arnav", amount: 102, memo: "apartment wifi + electric", daysAgo: 54, privacy: .private, funding: "balance"),

            // ── 56–70 days ago (early Jan) ──
            transaction(from: "user_elena", to: youID, amount: 33, memo: "new years brunch 🥂🎆", daysAgo: 56, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_brian", amount: 40, memo: "nye uber split 🚗", daysAgo: 57, privacy: .friends, funding: "debit"),
            transaction(from: "user_spencer", to: youID, amount: 200, memo: "ski trip cabin split 🏔️", daysAgo: 58, privacy: .friends, funding: "debit"),
            transaction(from: "user_rohan", to: "user_trevor", amount: 29, memo: "wings and beer 🍗🍺", daysAgo: 59, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_sofia", amount: 25, memo: "secret santa gift 🎅", daysAgo: 61, privacy: .friends, funding: "debit"),
            transaction(from: "user_arnav", to: youID, amount: 650, memo: "rent january 🏠", daysAgo: 63, privacy: .private, funding: "debit"),
            transaction(from: "user_diego", to: youID, amount: 18, memo: "taco truck 🌮", daysAgo: 64, privacy: .public, funding: "balance"),
            transaction(from: youID, to: "user_elena", amount: 45, memo: "board game night snacks 🎲", daysAgo: 66, privacy: .friends, funding: "debit"),
            transaction(from: "user_theo", to: "user_abi", amount: 14, memo: "bubble tea", daysAgo: 68, privacy: .public, funding: "debit"),

            // ── 71–90+ days ago (December 2025) ──
            transaction(from: "user_brian", to: youID, amount: 55, memo: "christmas dinner split 🎄", daysAgo: 72, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_trevor", amount: 35, memo: "xmas gift exchange 🎁", daysAgo: 73, privacy: .friends, funding: "debit"),
            transaction(from: "user_sofia", to: "user_diego", amount: 43, memo: "holiday party supplies 🎉", daysAgo: 74, privacy: .friends, funding: "debit"),
            transaction(from: youID, to: "user_abi", amount: 20, memo: "holiday cookie ingredients 🍪", daysAgo: 76, privacy: .public, funding: "balance"),
            transaction(from: "user_chenchen", to: youID, amount: 30, memo: "white elephant gift", daysAgo: 78, privacy: .friends, funding: "debit"),
            transaction(from: youID, to: "user_rohan", amount: 62, memo: "group dinner 🍽️", daysAgo: 80, privacy: .friends, funding: "debit"),
            transaction(from: "user_elena", to: "user_spencer", amount: 48, memo: "ugly sweater party 🧶", daysAgo: 82, privacy: .public, funding: "credit"),
            transaction(from: "user_trevor", to: youID, amount: 22, memo: "late night diner run 🥞", daysAgo: 84, privacy: .public, funding: "balance"),
            transaction(from: youID, to: "user_diego", amount: 150, memo: "nye party house deposit 🎆", daysAgo: 85, privacy: .friends, funding: "debit"),
            transaction(from: "user_arnav", to: youID, amount: 650, memo: "rent december 🏠", daysAgo: 88, privacy: .private, funding: "debit"),
            transaction(from: "user_shuyan", to: youID, amount: 12, memo: "matcha latte 🍵", daysAgo: 90, privacy: .public, funding: "debit"),
            transaction(from: youID, to: "user_brian", amount: 80, memo: "friendsgiving leftovers potluck 🦃", daysAgo: 92, privacy: .friends, funding: "debit"),
            transaction(from: "user_rohan", to: "user_elena", amount: 37, memo: "ice skating ⛸️", daysAgo: 94, privacy: .friends, funding: "debit"),
            transaction(from: youID, to: "user_spencer", amount: 110, memo: "nfl tickets 🏈", daysAgo: 96, privacy: .friends, funding: "debit")
        ]

        return activity.sorted { $0.timestamp > $1.timestamp }
    }

    static func requests(users: [User]) -> [Request] {
        let pending: [Request] = [
            request(from: "user_brian", to: youID, amount: 42, memo: "dinner split", hoursAgo: 2, privacy: .friends),
            request(from: youID, to: "user_chenchen", amount: 60, memo: "ski house", daysAgo: 1, privacy: .friends),
            request(from: "user_trevor", to: youID, amount: 17, memo: "parking", daysAgo: 1, privacy: .private),
            request(from: youID, to: "user_abi", amount: 25, memo: "movie tickets", daysAgo: 3, privacy: .friends),
            request(from: "user_shuyan", to: youID, amount: 33, memo: "brunch", hoursAgo: 8, privacy: .friends),
            request(from: youID, to: "user_spencer", amount: 90, memo: "concert tickets", daysAgo: 2, privacy: .friends)
        ]

        return pending.sorted { $0.timestamp > $1.timestamp }
    }

    private static func transaction(
        from fromUserID: String,
        to toUserID: String,
        amount: Double,
        memo: String,
        minutesAgo: Int = 0,
        hoursAgo: Int = 0,
        daysAgo: Int = 0,
        privacy: TransactionPrivacy,
        funding: String
    ) -> Transaction {
        Transaction(
            id: UUID(),
            fromUserID: fromUserID,
            toUserID: toUserID,
            amount: amount,
            memo: memo,
            timestamp: relativeDate(minutesAgo: minutesAgo, hoursAgo: hoursAgo, daysAgo: daysAgo),
            privacy: privacy,
            fundingSourceID: funding
        )
    }

    private static func request(
        from fromUserID: String,
        to toUserID: String,
        amount: Double,
        memo: String,
        minutesAgo: Int = 0,
        hoursAgo: Int = 0,
        daysAgo: Int = 0,
        privacy: TransactionPrivacy
    ) -> Request {
        Request(
            id: UUID(),
            fromUserID: fromUserID,
            toUserID: toUserID,
            amount: amount,
            memo: memo,
            timestamp: relativeDate(minutesAgo: minutesAgo, hoursAgo: hoursAgo, daysAgo: daysAgo),
            privacy: privacy,
            status: .pending
        )
    }

    private static func relativeDate(minutesAgo: Int = 0, hoursAgo: Int = 0, daysAgo: Int = 0) -> Date {
        let seconds = TimeInterval(minutesAgo * 60 + hoursAgo * 3600 + daysAgo * 86400)
        return Date().addingTimeInterval(-seconds)
    }
}
