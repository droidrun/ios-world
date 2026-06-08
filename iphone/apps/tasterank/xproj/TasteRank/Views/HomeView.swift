import SwiftUI
import UIKit

private enum HomeFeature: String, CaseIterable {
    case reserveNow = "Reserve now"
    case recsNearby = "Recs Nearby"
    case trending = "Trending"

    var icon: String {
        switch self {
        case .reserveNow:
            return "calendar"
        case .recsNearby:
            return "location.north.fill"
        case .trending:
            return "arrow.up.right"
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    let openSearch: () -> Void

    @State private var selectedFeature: HomeFeature = .recsNearby
    @State private var showingPlans = false
    @State private var showingNotifications = false
    @State private var showingFilters = false
    @State private var filterState: FilterState = .default
    @State private var showingComposer = false
    @State private var showingRequestResponses = false
    @State private var selectedRequestText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                searchBar
                actionChips
                featuredRestaurants
                composer
                requestCards
                posts
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingPlans) {
            HomePlansSheet(restaurants: featureRestaurants)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingNotifications) {
            HomeNotificationsSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView(filterState: $filterState)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingComposer) {
            RecommendationRequestSheet()
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            TasteRankWordmark(size: 34)
            Spacer()
            HStack(spacing: 6) {
                TasteRankIconButton(systemName: "calendar", size: 20) {
                    showingPlans = true
                }
                TasteRankIconButton(systemName: "bell", size: 20) {
                    showingNotifications = true
                }
                TasteRankIconButton(systemName: "line.3.horizontal", size: 20, accessibilityID: "Filters") {
                    showingFilters = true
                }
            }
        }
    }

    private var searchBar: some View {
        Button(action: openSearch) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                Text("Search a restaurant, member, etc.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MockTasteRankTheme.muted.opacity(0.55))
            )
        }
        .buttonStyle(.plain)
    }

    private var actionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeFeature.allCases, id: \.self) { feature in
                    Button {
                        selectedFeature = feature
                    } label: {
                        TasteRankChip(
                            title: feature.rawValue,
                            systemName: feature.icon,
                            filled: selectedFeature == feature
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var featuredRestaurants: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedFeature.rawValue)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(featureRestaurants) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurant: restaurant)
                        } label: {
                            HomeRestaurantCard(restaurant: restaurant)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var composer: some View {
        Button {
            showingComposer = true
        } label: {
            HStack(spacing: 10) {
                TasteRankAvatarView(
                    seed: store.currentUserProfile.handle,
                    initials: store.currentUserProfile.initials,
                    size: 40,
                    neutral: true
                )
                HStack {
                    Text("Ask your friends for recs")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.88)
                        .allowsTightening(true)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(MockTasteRankTheme.muted.opacity(0.45))
                )
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var requestCards: some View {
        if !store.feedInteractionState.recommendationRequests.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your requests")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                ForEach(store.feedInteractionState.recommendationRequests.prefix(2), id: \.self) { request in
                    Button {
                        selectedRequestText = request
                        showingRequestResponses = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Looking for")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(MockTasteRankTheme.accent)
                                Text(request)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                                Text("Tap to see responses")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MockTasteRankTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(14)
                    .background(CardBackground(cornerRadius: 16))
                }
            }
            .sheet(isPresented: $showingRequestResponses) {
                RequestResponsesSheet(request: selectedRequestText, friends: store.friends, restaurants: store.restaurants)
                    .environmentObject(store)
            }
        }
    }

    private var posts: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            ForEach(filteredPosts) { post in
                FeedPostCard(post: post)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func matchesFilterState(_ restaurant: Restaurant) -> Bool {
        let cuisineMatch = filterState.selectedCuisineIDs.isEmpty
            || filterState.selectedCuisineIDs.contains(restaurant.cuisine.id)
        let priceMatch = filterState.selectedPriceLevels.isEmpty
            || filterState.selectedPriceLevels.contains(restaurant.priceLevel)
        let distanceMatch = filterState.maxDistanceMiles == nil
            || restaurant.distanceMiles <= (filterState.maxDistanceMiles ?? 0)
        let openMatch = !filterState.openNowOnly || restaurant.hours.isOpen(at: Date())

        let visited = store.visitedRestaurantIDs.contains(restaurant.id)
        let visitedMatch: Bool
        switch filterState.visitedFilter {
        case .all:
            visitedMatch = true
        case .visited:
            visitedMatch = visited
        case .notVisited:
            visitedMatch = !visited
        }

        return cuisineMatch && priceMatch && distanceMatch && openMatch && visitedMatch
    }

    private var filteredPosts: [FeedPost] {
        let base: [FeedPost]
        switch selectedFeature {
        case .reserveNow:
            base = store.homeFeedPosts.filter { post in
                guard let restaurant = store.feedRestaurant(for: post) else { return false }
                return restaurant.priceLevel >= 3
            }
        case .recsNearby:
            base = store.homeFeedPosts.sorted { lhs, rhs in
                let leftDistance = store.feedRestaurant(for: lhs)?.distanceMiles ?? .greatestFiniteMagnitude
                let rightDistance = store.feedRestaurant(for: rhs)?.distanceMiles ?? .greatestFiniteMagnitude
                return leftDistance < rightDistance
            }
        case .trending:
            base = store.homeFeedPosts.filter { post in
                store.feedRestaurant(for: post)?.isTrending == true
            }
        }
        return base.filter { post in
            guard let restaurant = store.feedRestaurant(for: post) else { return false }
            return matchesFilterState(restaurant)
        }
    }

    private var featureRestaurants: [Restaurant] {
        let base: [Restaurant]
        switch selectedFeature {
        case .reserveNow:
            base = store.restaurants
                .filter { $0.priceLevel >= 3 }
                .sorted { $0.beliScore > $1.beliScore }
        case .recsNearby:
            base = store.restaurants
                .sorted { $0.distanceMiles < $1.distanceMiles }
        case .trending:
            base = store.restaurants
                .filter(\.isTrending)
                .sorted { $0.beliScore > $1.beliScore }
        }
        return base
            .filter { matchesFilterState($0) }
            .prefix(6)
            .map { $0 }
    }
}

private struct HomeRestaurantCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(restaurant.photoAssetNames.first ?? "tr_photo_1")
                .resizable()
                .scaledToFill()
                .frame(width: 196, height: 114)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(restaurant.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
                .lineLimit(1)
                .accessibilityIdentifier("card_name_\(restaurant.id)")

            Text(restaurant.locationLine)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
                .lineLimit(1)

            HStack {
                Text(restaurant.cuisineDetails)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.accent)
                    .lineLimit(1)
                Spacer()
                TasteRankScoreBadge(score: restaurant.beliScore, diameter: 38)
            }
        }
        .padding(10)
        .frame(width: 220, alignment: .leading)
        .background(CardBackground(cornerRadius: 16))
    }
}

private enum FeedPostSheet: Identifiable {
    case comments
    case share
    case addToList
    case memberProfile

    var id: String { String(describing: self) }
}

private struct FeedPostCard: View {
    @EnvironmentObject private var store: MockTasteRankStore
    let post: FeedPost

    @State private var activeSheet: FeedPostSheet?

    var body: some View {
        if let restaurant = store.feedRestaurant(for: post) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    if memberProfileFriend != nil {
                        activeSheet = .memberProfile
                    }
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        TasteRankAvatarView(
                            seed: post.authorAvatarSeed,
                            initials: post.authorName.feedInitials,
                            size: 52
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            title(restaurant: restaurant)
                            Text(post.companionNames.isEmpty ? "solo" : "with \(post.companionNames.joined(separator: ", "))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MockTasteRankTheme.textPrimary)
                                .lineLimit(1)
                            Label(restaurant.locationLine, systemImage: "fork.knife")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(MockTasteRankTheme.textSecondary)
                                .lineLimit(1)
                            Label(post.visitLabel, systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(MockTasteRankTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                        TasteRankScoreBadge(score: restaurant.beliScore, diameter: 52)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    RestaurantDetailView(restaurant: restaurant)
                } label: {
                    TasteRankPhotoGrid(photoNames: postPhotoNames(for: restaurant), height: 140)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    RestaurantDetailView(restaurant: restaurant)
                } label: {
                    (
                        Text("Notes: ")
                            .font(.system(size: 14, weight: .bold))
                        + Text(post.notePreview)
                            .font(.system(size: 14, weight: .regular))
                        + Text(" See more")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(MockTasteRankTheme.textSecondary)
                    )
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.plain)

                Text("\(store.likeCount(for: post)) like\(store.likeCount(for: post) == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                HStack {
                    HStack(spacing: 18) {
                        Button {
                            store.toggleLike(postID: post.id)
                        } label: {
                            Image(systemName: store.isLiked(postID: post.id) ? "heart.fill" : "heart")
                                .foregroundStyle(store.isLiked(postID: post.id) ? Color.red : MockTasteRankTheme.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            activeSheet = .comments
                        } label: {
                            Image(systemName: "bubble.left")
                                .foregroundStyle(MockTasteRankTheme.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            activeSheet = .share
                        } label: {
                            Image(systemName: "paperplane")
                                .foregroundStyle(MockTasteRankTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: 22, weight: .regular))

                    Spacer()

                    HStack(spacing: 18) {
                        Button {
                            activeSheet = .addToList
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(MockTasteRankTheme.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.toggleSavedPost(postID: post.id)
                        } label: {
                            Image(systemName: store.isSaved(postID: post.id) ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(store.isSaved(postID: post.id) ? MockTasteRankTheme.accent : MockTasteRankTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: 24, weight: .regular))
                }

                Text(post.timeLabel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 14)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(MockTasteRankTheme.divider)
                    .frame(height: 1)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .comments:
                    PostCommentsSheet(post: post)
                        .environmentObject(store)
                case .share:
                    TasteRankShareSheet(
                        title: "Share Post",
                        message: "\(post.authorHandle) ranked \(restaurant.name) on TasteRank. \(restaurant.locationLine)."
                    )
                case .addToList:
                    AddToListSheet(restaurant: restaurant)
                        .environmentObject(store)
                case .memberProfile:
                    NavigationStack {
                        if let friend = memberProfileFriend {
                            MemberProfileView(friend: friend)
                                .environmentObject(store)
                        }
                    }
                }
            }
        }
    }

    private func title(restaurant: Restaurant) -> some View {
        (
            Text("\(post.authorName) ")
                .font(.system(size: 15, weight: .semibold))
            + Text("ranked \(restaurant.name)")
                .font(.system(size: 15, weight: .bold))
        )
        .foregroundStyle(MockTasteRankTheme.textPrimary)
        .lineLimit(2)
        .truncationMode(.tail)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func handleMatching(_ handle: String) -> String {
        handle.lowercased()
    }

    private var memberProfileFriend: FriendProfile? {
        store.friend(for: handleMatching(post.authorHandle))
    }

    private func postPhotoNames(for restaurant: Restaurant) -> [String] {
        let seeded = ["tr_p_\(post.id)_0", "tr_p_\(post.id)_1"]
        let resolved = seeded.map { name -> String in
            if UIImage(named: name) != nil { return name }
            return ""
        }
        if resolved.allSatisfy({ !$0.isEmpty }) {
            return resolved
        }
        let fallback = restaurant.photoAssetNames
        guard !fallback.isEmpty else { return seeded }
        return (0..<2).map { fallback[$0 % fallback.count] }
    }
}

private struct PostCommentsSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    let post: FeedPost

    @State private var draft = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if store.comments(for: post.id).isEmpty {
                            Text("No comments yet. Start the thread.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(MockTasteRankTheme.textSecondary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(CardBackground(cornerRadius: 14))
                        } else {
                            ForEach(store.comments(for: post.id), id: \.self) { comment in
                                Text(comment)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(CardBackground(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                HStack(spacing: 10) {
                    TextField("Add a comment", text: $draft)
                        .textInputAutocapitalization(.sentences)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(CardBackground(cornerRadius: 14))

                    Button("Post") {
                        store.addComment(draft, to: post.id)
                        draft = ""
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MockTasteRankTheme.accent)
                    )
                }
                .padding(16)
            }
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct RecommendationRequestSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Ask for recommendations")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                Text("Post what you are looking for and keep it specific enough that friends can actually help.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)

                TextEditor(text: $prompt)
                    .font(.system(size: 15))
                    .frame(height: 160)
                    .padding(10)
                    .background(CardBackground(cornerRadius: 16))

                Spacer()
            }
            .padding(16)
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Post") {
                        store.addRecommendationRequest(prompt)
                        dismiss()
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct HomePlansSheet: View {
    @Environment(\.dismiss) private var dismiss
    let restaurants: [Restaurant]

    var body: some View {
        NavigationStack {
            List(restaurants.prefix(4)) { restaurant in
                NavigationLink {
                    RestaurantDetailView(restaurant: restaurant)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dinner at \(restaurant.name)")
                            .font(.system(size: 16, weight: .semibold))
                        Text(restaurant.statusLine)
                            .font(.system(size: 13))
                            .foregroundStyle(MockTasteRankTheme.textSecondary)
                    }
                }
            }
            .navigationTitle("Upcoming Plans")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HomeNotificationsSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let topRestaurant = store.recommendedRestaurantsFromFriends().first {
                    NavigationLink {
                        RestaurantDetailView(restaurant: topRestaurant)
                    } label: {
                        TasteRankModalRow(
                            systemName: "sparkles",
                            title: "\(topRestaurant.name) is trending with people you follow",
                            subtitle: topRestaurant.locationLine
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }

                if let friend = store.friends.first {
                    NavigationLink {
                        MemberProfileView(friend: friend)
                            .environmentObject(store)
                    } label: {
                        TasteRankModalRow(
                            systemName: "person.badge.plus",
                            title: "\(friend.name) joined TasteRank in your city",
                            subtitle: "See what they have been ranking lately"
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HomeMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MockTasteRankStore
    @State private var showingInviteShare = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    SettingsView()
                        .environmentObject(store)
                } label: {
                    TasteRankModalRow(systemName: "gearshape", title: "Settings", subtitle: "Profile privacy, display, and reset")
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)

                NavigationLink {
                    ListsView()
                        .environmentObject(store)
                } label: {
                    TasteRankModalRow(systemName: "list.bullet", title: "Open Your Lists", subtitle: "Manage been, guides, and want to try")
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)

                Button {
                    showingInviteShare = true
                } label: {
                    TasteRankModalRow(systemName: "person.2", title: "Invite Friends", subtitle: "Share your handle and find mutuals", accessory: nil)
                }
                .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingInviteShare) {
            TasteRankShareSheet(
                title: "Invite Friends",
                message: "Join me on TasteRank and follow \(store.currentUserProfile.handle) for restaurant recs."
            )
        }
    }
}

private extension String {
    var feedInitials: String {
        let pieces = split(separator: " ")
        let letters = pieces.prefix(2).compactMap(\.first)
        if letters.isEmpty {
            return String(prefix(2)).uppercased()
        }
        return String(letters).uppercased()
    }
}

private struct RequestResponsesSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    let request: String
    let friends: [FriendProfile]
    let restaurants: [Restaurant]

    private var responses: [(friend: FriendProfile, restaurant: Restaurant)] {
        guard !friends.isEmpty, !restaurants.isEmpty else { return [] }
        let seed = abs(request.hashValue)
        let startIndex = seed % friends.count
        let selectedFriends = (0..<min(3, friends.count)).map { i in friends[(startIndex + i) % friends.count] }
        let topRestaurants = restaurants.sorted { $0.beliScore > $1.beliScore }
        let dropCount = seed % max(topRestaurants.count - 3, 1)
        return Array(zip(selectedFriends, topRestaurants.dropFirst(dropCount).prefix(3)))
            .map { (friend: $0, restaurant: $1) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Looking for")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MockTasteRankTheme.accent)
                        Text(request)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(MockTasteRankTheme.textPrimary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CardBackground(cornerRadius: 16))

                    Text("\(responses.count) response\(responses.count == 1 ? "" : "s")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                        .padding(.top, 4)

                    ForEach(responses, id: \.restaurant.id) { response in
                        NavigationLink {
                            RestaurantDetailView(restaurant: response.restaurant)
                        } label: {
                            HStack(spacing: 10) {
                                TasteRankAvatarView(seed: response.friend.avatarSeed, initials: response.friend.initials, size: 36)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(response.friend.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                                    Text("Try \(response.restaurant.name)")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                                    Text(response.restaurant.locationLine)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                                }

                                Spacer()

                                TasteRankScoreBadge(score: response.restaurant.beliScore, diameter: 38)
                            }
                            .padding(12)
                            .background(CardBackground(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("Responses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(openSearch: {})
            .environmentObject(MockTasteRankStore())
    }
}
