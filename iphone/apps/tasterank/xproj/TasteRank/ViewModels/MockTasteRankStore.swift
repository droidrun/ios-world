import Foundation

final class MockTasteRankStore: ObservableObject {
    @Published private(set) var restaurants: [Restaurant]
    @Published private(set) var cuisines: [CuisineTag]
    @Published private(set) var neighborhoods: [Neighborhood]
    @Published private(set) var friends: [FriendProfile]
    @Published private(set) var friendLogs: [FriendLog]
    @Published private(set) var feedPosts: [FeedPost]
    @Published private(set) var leaderboardEntries: [LeaderboardEntry]
    @Published var userProfile: UserProfileSummary {
        didSet {
            Persistence.save(userProfile, key: .userProfile)
        }
    }
    @Published var feedInteractionState: FeedInteractionState {
        didSet {
            Persistence.save(feedInteractionState, key: .feedInteractions)
        }
    }

    @Published var visitLogs: [VisitLog] {
        didSet {
            Persistence.save(visitLogs, key: .visitLogs)
        }
    }
    @Published var listCollections: [ListCollection] {
        didSet {
            Persistence.save(listCollections, key: .listCollections)
        }
    }
    @Published var followedFriendIDs: Set<String> {
        didSet {
            Persistence.save(Array(followedFriendIDs), key: .followedFriends)
        }
    }
    @Published var settings: SettingsState {
        didSet {
            Persistence.save(settings, key: .settings)
        }
    }

    init() {
        let seededRestaurants = SeedData.restaurants()
        let seededCuisines = SeedData.cuisines()
        let seededNeighborhoods = SeedData.neighborhoods()
        let seededFriends = SeedData.friends()
        let seededFriendLogs = SeedData.friendLogs(restaurants: seededRestaurants, friends: seededFriends)
        let seededFeedPosts = SeedData.feedPosts()
        let seededLeaderboard = SeedData.leaderboardEntries()
        let seededUserProfile = SeedData.userProfile()
        let seededFeedInteractionState = SeedData.defaultFeedInteractionState()

        restaurants = seededRestaurants
        cuisines = seededCuisines
        neighborhoods = seededNeighborhoods
        friends = seededFriends
        friendLogs = seededFriendLogs
        feedPosts = seededFeedPosts
        leaderboardEntries = seededLeaderboard
        userProfile = seededUserProfile
        feedInteractionState = seededFeedInteractionState

        let savedLogs = Persistence.load([VisitLog].self, key: .visitLogs, fallback: SeedData.defaultVisitLogs(restaurants: seededRestaurants))
        let savedLists = Persistence.load([ListCollection].self, key: .listCollections, fallback: SeedData.defaultLists(restaurants: seededRestaurants))
        let savedFollows = Persistence.load([String].self, key: .followedFriends, fallback: SeedData.defaultFollowedFriendIDs())
        let savedSettings = Persistence.load(SettingsState.self, key: .settings, fallback: .default)
        let savedUserProfile = Persistence.load(UserProfileSummary.self, key: .userProfile, fallback: seededUserProfile)
        let savedFeedInteractionState = Persistence.load(FeedInteractionState.self, key: .feedInteractions, fallback: seededFeedInteractionState)

        let restaurantIDs = Set(seededRestaurants.map { $0.id })
        visitLogs = savedLogs.filter { restaurantIDs.contains($0.restaurantID) }
        listCollections = savedLists.map { list in
            let filteredIDs = list.restaurantIDs.filter { restaurantIDs.contains($0) }
            return ListCollection(id: list.id, name: list.name, restaurantIDs: filteredIDs)
        }
        followedFriendIDs = Set(savedFollows.filter { id in seededFriends.contains(where: { $0.id == id }) })
        settings = savedSettings
        userProfile = Self.sanitizedUserProfile(savedUserProfile, seeded: seededUserProfile)
        let validPostIDs = Set(seededFeedPosts.map(\.id)).union(savedLogs.map(Self.userFeedPostID(for:)))
        feedInteractionState = Self.sanitizedFeedInteractionState(savedFeedInteractionState, validPostIDs: validPostIDs)
    }

    var visitedRestaurantIDs: Set<String> {
        Set(visitLogs.map { $0.restaurantID })
    }

    func restaurant(for id: String) -> Restaurant? {
        restaurants.first { $0.id == id }
    }

    func latestLog(for restaurantID: String) -> VisitLog? {
        visitLogs.filter { $0.restaurantID == restaurantID }
            .sorted(by: { $0.dateVisited > $1.dateVisited })
            .first
    }

    func averageRating(for restaurantID: String) -> Double? {
        let ratings = visitLogs.filter { $0.restaurantID == restaurantID }.map { Double($0.rating) }
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }

    func logVisit(restaurantID: String, date: Date, rating: Int, dishRatings: [DishRating], notes: String, tags: [String]) {
        let log = VisitLog(
            id: UUID(),
            restaurantID: restaurantID,
            dateVisited: date,
            rating: rating,
            dishRatings: dishRatings,
            notes: notes,
            tags: tags
        )
        visitLogs.insert(log, at: 0)
        removeRestaurant(restaurantID, from: "list_want_to_try")
        print("[Beli] Logged visit for \(restaurantID) with rating \(rating)")
    }

    func toggleVisited(restaurantID: String) {
        if visitLogs.contains(where: { $0.restaurantID == restaurantID }) {
            visitLogs.removeAll { $0.restaurantID == restaurantID }
            print("[Beli] Cleared visits for \(restaurantID)")
        } else {
            let log = VisitLog(
                id: UUID(),
                restaurantID: restaurantID,
                dateVisited: Date(),
                rating: 4,
                dishRatings: [],
                notes: "",
                tags: []
            )
            visitLogs.insert(log, at: 0)
            removeRestaurant(restaurantID, from: "list_want_to_try")
            print("[Beli] Marked \(restaurantID) as visited")
        }
    }

    func toggleFollow(friendID: String) {
        if followedFriendIDs.contains(friendID) {
            followedFriendIDs.remove(friendID)
        } else {
            followedFriendIDs.insert(friendID)
        }
        print("[Beli] Toggled follow for \(friendID): \(followedFriendIDs.contains(friendID))")
    }

    func createList(name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let list = ListCollection(id: "list_\(UUID().uuidString)", name: name, restaurantIDs: [])
        listCollections.insert(list, at: 0)
        print("[Beli] Created list \(name)")
    }

    func deleteList(listID: String) {
        listCollections.removeAll { $0.id == listID }
    }

    func toggleRestaurant(_ restaurantID: String, in listID: String) {
        guard let index = listCollections.firstIndex(where: { $0.id == listID }) else { return }
        if listCollections[index].restaurantIDs.contains(restaurantID) {
            listCollections[index].restaurantIDs.removeAll { $0 == restaurantID }
        } else {
            listCollections[index].restaurantIDs.append(restaurantID)
        }
        print("[Beli] Updated list \(listCollections[index].name) for \(restaurantID)")
    }

    func removeRestaurant(_ restaurantID: String, from listID: String) {
        guard let index = listCollections.firstIndex(where: { $0.id == listID }) else { return }
        listCollections[index].restaurantIDs.removeAll { $0 == restaurantID }
    }

    func isRestaurant(_ restaurantID: String, in listID: String) -> Bool {
        listCollections.first(where: { $0.id == listID })?.restaurantIDs.contains(restaurantID) ?? false
    }

    func recommendedRestaurantsFromFriends() -> [Restaurant] {
        let followedLogs = friendLogs.filter { followedFriendIDs.contains($0.friendID) }
        let grouped = Dictionary(grouping: followedLogs, by: { $0.restaurantID })
        let sortedIDs = grouped
            .sorted { $0.value.count > $1.value.count }
            .map { $0.key }
        return sortedIDs.compactMap { restaurant(for: $0) }
    }

    var wantToTryRestaurants: [Restaurant] {
        restaurants(forListID: "list_want_to_try")
    }

    var guideRestaurants: [Restaurant] {
        restaurants(forListID: "list_guides")
    }

    var guideLists: [ListCollection] {
        listCollections.filter { $0.id == "list_guides" || $0.id.hasPrefix("guide_") }
    }

    var visitedRestaurants: [Restaurant] {
        return restaurants
            .filter { visitedRestaurantIDs.contains($0.id) }
            .sorted { lhs, rhs in
                let leftDate = latestLog(for: lhs.id)?.dateVisited ?? .distantPast
                let rightDate = latestLog(for: rhs.id)?.dateVisited ?? .distantPast
                if leftDate == rightDate {
                    return lhs.beliScore > rhs.beliScore
                }
                return leftDate > rightDate
            }
    }

    var currentUserProfile: UserProfileSummary {
        let baseProfile = userProfile
        let baselineVisitedCount = Set(SeedData.defaultVisitLogs(restaurants: restaurants).map(\.restaurantID)).count
        let baselineWantToTry = SeedData.defaultLists(restaurants: restaurants)
            .first(where: { $0.id == "list_want_to_try" })?
            .restaurantIDs.count ?? 0
        let baselineFollowing = SeedData.defaultFollowedFriendIDs().count

        return UserProfileSummary(
            displayName: baseProfile.displayName,
            initials: baseProfile.initials,
            handle: baseProfile.handle,
            memberSince: baseProfile.memberSince,
            schoolName: baseProfile.schoolName,
            followers: baseProfile.followers,
            following: max(0, baseProfile.following + (followedFriendIDs.count - baselineFollowing)),
            beliRank: baseProfile.beliRank,
            beenCount: max(0, baseProfile.beenCount + (visitedRestaurantIDs.count - baselineVisitedCount)),
            wantToTryCount: max(0, baseProfile.wantToTryCount + (wantToTryRestaurants.count - baselineWantToTry)),
            streakLabel: baseProfile.streakLabel,
            lastYearCount: baseProfile.lastYearCount,
            goalYear: baseProfile.goalYear,
            goalOptions: baseProfile.goalOptions,
            selectedGoalID: baseProfile.selectedGoalID
        )
    }

    var homeFeedPosts: [FeedPost] {
        userFeedPosts + feedPosts
    }

    func feedRestaurant(for post: FeedPost) -> Restaurant? {
        restaurant(for: post.restaurantID)
    }

    func friend(for handle: String) -> FriendProfile? {
        friends.first { $0.handle.caseInsensitiveCompare(handle) == .orderedSame }
    }

    func filteredRestaurants(query: String, filters: FilterState, sort: SortOption) -> [Restaurant] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerQuery = trimmed.lowercased()

        var results = restaurants.filter { restaurant in
            let matchesQuery: Bool
            if lowerQuery.isEmpty {
                matchesQuery = true
            } else {
                let dishMatch = restaurant.dishes.contains { $0.name.lowercased().contains(lowerQuery) }
                let combined = [
                    restaurant.name,
                    restaurant.cuisine.name,
                    restaurant.neighborhood.name,
                    restaurant.neighborhood.city,
                    restaurant.locationLine,
                    restaurant.cuisineDetails
                ] + restaurant.searchHints
                matchesQuery = combined.contains { $0.lowercased().contains(lowerQuery) } || dishMatch
            }

            let cuisineMatch = filters.selectedCuisineIDs.isEmpty || filters.selectedCuisineIDs.contains(restaurant.cuisine.id)
            let priceMatch = filters.selectedPriceLevels.isEmpty || filters.selectedPriceLevels.contains(restaurant.priceLevel)
            let distanceMatch = filters.maxDistanceMiles == nil || restaurant.distanceMiles <= (filters.maxDistanceMiles ?? 0)
            let openMatch = !filters.openNowOnly || restaurant.hours.isOpen(at: Date())

            let visited = visitedRestaurantIDs.contains(restaurant.id)
            let visitedMatch: Bool
            switch filters.visitedFilter {
            case .all:
                visitedMatch = true
            case .visited:
                visitedMatch = visited
            case .notVisited:
                visitedMatch = !visited
            }

            return matchesQuery && cuisineMatch && priceMatch && distanceMatch && openMatch && visitedMatch
        }

        switch sort {
        case .recommended:
            results.sort {
                if $0.isTrending != $1.isTrending {
                    return $0.isTrending && !$1.isTrending
                }
                return $0.seedRating > $1.seedRating
            }
        case .highestRated:
            results.sort {
                let left = averageRating(for: $0.id) ?? $0.seedRating
                let right = averageRating(for: $1.id) ?? $1.seedRating
                return left > right
            }
        case .mostPopular:
            results.sort { $0.popularity > $1.popularity }
        case .closest:
            results.sort { $0.distanceMiles < $1.distanceMiles }
        }

        return results
    }

    func displayPrice(level: Int) -> String {
        switch settings.priceDisplayMode {
        case .dollarSigns:
            return String(repeating: "$", count: max(1, min(level, 4)))
        case .numeric:
            return "\(level)/4"
        }
    }

    func updateProfile(displayName: String, handle: String, schoolName: String?) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let rawHandle = handle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
        let normalizedHandle = rawHandle.hasPrefix("@") ? rawHandle : "@\(rawHandle)"

        userProfile = UserProfileSummary(
            displayName: trimmedName,
            initials: String(trimmedName.split(separator: " ").prefix(2).compactMap(\.first)).uppercased(),
            handle: normalizedHandle == "@" ? userProfile.handle : normalizedHandle,
            memberSince: userProfile.memberSince,
            schoolName: schoolName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            followers: userProfile.followers,
            following: userProfile.following,
            beliRank: userProfile.beliRank,
            beenCount: userProfile.beenCount,
            wantToTryCount: userProfile.wantToTryCount,
            streakLabel: userProfile.streakLabel,
            lastYearCount: userProfile.lastYearCount,
            goalYear: userProfile.goalYear,
            goalOptions: userProfile.goalOptions,
            selectedGoalID: userProfile.selectedGoalID
        )
    }

    func selectGoalOption(_ goalID: String) {
        guard userProfile.goalOptions.contains(where: { $0.id == goalID }) else { return }
        userProfile = UserProfileSummary(
            displayName: userProfile.displayName,
            initials: userProfile.initials,
            handle: userProfile.handle,
            memberSince: userProfile.memberSince,
            schoolName: userProfile.schoolName,
            followers: userProfile.followers,
            following: userProfile.following,
            beliRank: userProfile.beliRank,
            beenCount: userProfile.beenCount,
            wantToTryCount: userProfile.wantToTryCount,
            streakLabel: userProfile.streakLabel,
            lastYearCount: userProfile.lastYearCount,
            goalYear: userProfile.goalYear,
            goalOptions: userProfile.goalOptions,
            selectedGoalID: goalID
        )
    }

    func setCustomGoal(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let customOption = GoalOption(id: "custom_\(trimmed)", title: trimmed)
        var updatedOptions = userProfile.goalOptions.filter { $0.id != "customize" && !$0.id.hasPrefix("custom_") }
        updatedOptions.append(customOption)
        userProfile = UserProfileSummary(
            displayName: userProfile.displayName,
            initials: userProfile.initials,
            handle: userProfile.handle,
            memberSince: userProfile.memberSince,
            schoolName: userProfile.schoolName,
            followers: userProfile.followers,
            following: userProfile.following,
            beliRank: userProfile.beliRank,
            beenCount: userProfile.beenCount,
            wantToTryCount: userProfile.wantToTryCount,
            streakLabel: userProfile.streakLabel,
            lastYearCount: userProfile.lastYearCount,
            goalYear: userProfile.goalYear,
            goalOptions: updatedOptions,
            selectedGoalID: customOption.id
        )
    }

    func toggleLike(postID: String) {
        if feedInteractionState.likedPostIDs.contains(postID) {
            feedInteractionState.likedPostIDs.remove(postID)
        } else {
            feedInteractionState.likedPostIDs.insert(postID)
        }
    }

    func isLiked(postID: String) -> Bool {
        feedInteractionState.likedPostIDs.contains(postID)
    }

    func likeCount(for post: FeedPost) -> Int {
        post.likeCount + (isLiked(postID: post.id) ? 1 : 0)
    }

    func toggleSavedPost(postID: String) {
        if feedInteractionState.savedPostIDs.contains(postID) {
            feedInteractionState.savedPostIDs.remove(postID)
        } else {
            feedInteractionState.savedPostIDs.insert(postID)
        }
    }

    func isSaved(postID: String) -> Bool {
        feedInteractionState.savedPostIDs.contains(postID)
    }

    func comments(for postID: String) -> [String] {
        feedInteractionState.commentsByPostID[postID] ?? []
    }

    func addComment(_ comment: String, to postID: String) {
        let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var comments = feedInteractionState.commentsByPostID[postID] ?? []
        comments.append(trimmed)
        feedInteractionState.commentsByPostID[postID] = comments
    }

    func addRecommendationRequest(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        feedInteractionState.recommendationRequests.insert(trimmed, at: 0)
    }

    private func refreshFriendsFromContacts() {
        SeedData.requestContactFriends { [weak self] contactFriends in
            guard let self else { return }
            guard !contactFriends.isEmpty else { return }

            DispatchQueue.main.async {
                self.friends = contactFriends
                self.friendLogs = SeedData.friendLogs(restaurants: self.restaurants, friends: contactFriends)

                let validIDs = Set(contactFriends.map(\.id))
                self.followedFriendIDs = self.followedFriendIDs.filter { validIDs.contains($0) }
            }
        }
    }

    func resetState() {
        visitLogs = SeedData.defaultVisitLogs(restaurants: restaurants)
        listCollections = SeedData.defaultLists(restaurants: restaurants)
        followedFriendIDs = Set(SeedData.defaultFollowedFriendIDs())
        settings = .default
        userProfile = SeedData.userProfile()
        feedInteractionState = SeedData.defaultFeedInteractionState()
        Persistence.clearAll()
        print("[Beli] Reset app state")
    }

    private func restaurants(forListID listID: String) -> [Restaurant] {
        guard let ids = listCollections.first(where: { $0.id == listID })?.restaurantIDs else { return [] }
        return ids.compactMap(restaurant(for:))
    }

    private var userFeedPosts: [FeedPost] {
        visitLogs
            .sorted { $0.dateVisited > $1.dateVisited }
            .prefix(6)
            .compactMap { log in
                guard let restaurant = restaurant(for: log.restaurantID) else { return nil }
                let notes = log.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                let visitCount = visitLogs.filter { $0.restaurantID == log.restaurantID }.count
                return FeedPost(
                    id: Self.userFeedPostID(for: log),
                    authorName: currentUserProfile.displayName,
                    authorHandle: currentUserProfile.handle,
                    authorAvatarSeed: currentUserProfile.handle,
                    restaurantID: restaurant.id,
                    companionNames: [],
                    notePreview: notes.nilIfEmpty ?? "Logged a \(log.rating <= 5 ? log.rating * 2 : log.rating)/10 visit at \(restaurant.name).",
                    likeCount: 0,
                    timeLabel: Self.relativeTimeLabel(since: log.dateVisited),
                    visitLabel: visitCount == 1 ? "1 visit" : "\(visitCount) visits"
                )
            }
    }

    private static func userFeedPostID(for log: VisitLog) -> String {
        "feed_user_\(log.id.uuidString)"
    }

    private static func relativeTimeLabel(since date: Date, now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 {
            return "Just now"
        }
        if seconds < 3600 {
            let minutes = max(1, seconds / 60)
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        }
        if seconds < 86_400 {
            let hours = max(1, seconds / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        if seconds < 172_800 {
            return "Yesterday"
        }
        let days = max(2, seconds / 86_400)
        return "\(days) days ago"
    }

    private static func sanitizedUserProfile(_ profile: UserProfileSummary, seeded: UserProfileSummary) -> UserProfileSummary {
        let legacyGoalIDs = profile.goalOptions.map(\.id)
        let looksLikeLegacySeed = profile.beliRank == 88_202
            && profile.beenCount == 233
            && profile.wantToTryCount == 30
            && legacyGoalIDs == ["80", "100", "150", "customize"]

        guard !looksLikeLegacySeed else {
            return seeded
        }

        guard profile.goalOptions.contains(where: { $0.id == profile.selectedGoalID }) else {
            return seeded
        }

        return profile
    }

    private static func sanitizedFeedInteractionState(_ state: FeedInteractionState, validPostIDs: Set<String>) -> FeedInteractionState {
        FeedInteractionState(
            likedPostIDs: Set(state.likedPostIDs.filter { validPostIDs.contains($0) }),
            savedPostIDs: Set(state.savedPostIDs.filter { validPostIDs.contains($0) }),
            commentsByPostID: state.commentsByPostID.filter { validPostIDs.contains($0.key) },
            recommendationRequests: state.recommendationRequests
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
