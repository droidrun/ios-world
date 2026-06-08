import SwiftUI

private enum LeaderboardMetric: String, CaseIterable {
    case been = "Been"
    case influence = "Influence"
    case notes = "Notes"
    case photos = "Photos"

    var subtitle: String {
        switch self {
        case .been:
            return "Number of places on your been list"
        case .influence:
            return "How often your recs turn into someone else's meal"
        case .notes:
            return "Consistency and detail in your writeups"
        case .photos:
            return "The strength of your visual receipts"
        }
    }
}

private enum LeaderboardAudience: String, CaseIterable {
    case allMembers = "All Members"
    case following = "Following"
}

private enum LeaderboardLocation: String, CaseIterable {
    case seoul = "Seoul"
    case newYork = "New York"
    case global = "Global"
}

struct LeaderboardView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @State private var selectedMetric: LeaderboardMetric = .been
    @State private var selectedAudience: LeaderboardAudience = .allMembers
    @State private var selectedLocation: LeaderboardLocation = .global
    @State private var showingAudiencePicker = false
    @State private var showingLocationPicker = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Leaderboard")
                    .font(MockTasteRankTheme.displayFont(size: 36))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                    .padding(.top, 48)

                metricTabs

                Text(selectedMetric.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)

                HStack(spacing: 10) {
                    Button {
                        showingAudiencePicker = true
                    } label: {
                        TasteRankChip(title: selectedAudience.rawValue, filled: false, trailingChevron: true)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingLocationPicker = true
                    } label: {
                        TasteRankChip(title: selectedLocation.rawValue, filled: false, trailingChevron: true)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                LazyVStack(spacing: 14) {
                    ForEach(displayedEntries) { entry in
                        NavigationLink {
                            MemberProfileView(friend: member(for: entry))
                        } label: {
                            LeaderboardRow(entry: entry, score: score(for: entry))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Leaderboard audience", isPresented: $showingAudiencePicker) {
            ForEach(LeaderboardAudience.allCases, id: \.self) { audience in
                Button(audience.rawValue) {
                    selectedAudience = audience
                }
            }
        }
        .confirmationDialog("Leaderboard city", isPresented: $showingLocationPicker) {
            ForEach(LeaderboardLocation.allCases, id: \.self) { location in
                Button(location.rawValue) {
                    selectedLocation = location
                }
            }
        }
    }

    private var metricTabs: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardMetric.allCases, id: \.self) { metric in
                Button {
                    selectedMetric = metric
                } label: {
                    ZStack {
                        if selectedMetric == metric {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                                .padding(3)
                        }
                        Text(metric.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(MockTasteRankTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                if metric != LeaderboardMetric.allCases.last {
                    Rectangle()
                        .fill(MockTasteRankTheme.border)
                        .frame(width: 1, height: 28)
                        .padding(.vertical, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.90, green: 0.90, blue: 0.93))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(MockTasteRankTheme.border, lineWidth: 1)
                )
        )
    }

    private var displayedEntries: [LeaderboardEntry] {
        let filtered = store.leaderboardEntries.filter { entry in
            let audienceMatches = selectedAudience == .allMembers || store.followedFriendIDs.contains(entry.id)
            let locationMatches = entryMatchesSelectedLocation(entry)
            return audienceMatches && locationMatches
        }

        return filtered.isEmpty ? store.leaderboardEntries : filtered
    }

    private func entryMatchesSelectedLocation(_ entry: LeaderboardEntry) -> Bool {
        guard selectedLocation != .global else { return true }
        guard let friend = store.friend(for: entry.handle) else { return true }

        let cities = Set(
            store.friendLogs
                .filter { $0.friendID == friend.id }
                .compactMap { store.restaurant(for: $0.restaurantID)?.neighborhood.city }
        )

        switch selectedLocation {
        case .seoul:
            return cities.contains("Seoul") || cities.contains("Busan")
        case .newYork:
            return cities.contains("Manhattan") || cities.contains("Brooklyn")
        case .global:
            return true
        }
    }

    private func member(for entry: LeaderboardEntry) -> FriendProfile {
        if let friend = store.friend(for: entry.handle) {
            return friend
        }

        return FriendProfile(
            id: entry.id,
            name: entry.displayName.displayNameFromHandle,
            handle: entry.handle,
            avatarSeed: entry.avatarSeed
        )
    }

    private func score(for entry: LeaderboardEntry) -> Int {
        switch selectedMetric {
        case .been:
            return entry.score
        case .influence:
            return max(entry.score - 110, 210)
        case .notes:
            return max(entry.score - 160, 155)
        case .photos:
            return max(entry.score - 205, 120)
        }
    }
}

struct FriendsView: View {
    var body: some View {
        LeaderboardView()
    }
}

struct MemberProfileView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    let friend: FriendProfile

    @State private var showingShareSheet = false

    private var friendLogs: [FriendLog] {
        store.friendLogs
            .filter { $0.friendID == friend.id }
            .sorted { $0.date > $1.date }
    }

    private var recentRestaurants: [Restaurant] {
        friendLogs.compactMap { store.restaurant(for: $0.restaurantID) }
    }

    private var scoreSeed: Int {
        friend.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }

    private var followers: Int {
        40 + (scoreSeed % 120)
    }

    private var following: Int {
        22 + (scoreSeed % 55)
    }

    private var cityLabel: String {
        recentRestaurants.first?.neighborhood.city ?? "Manhattan"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                VStack(spacing: 10) {
                    TasteRankAvatarView(seed: friend.avatarSeed, initials: friend.initials, size: 88)

                    Text(friend.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)

                    Text(friend.handle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)

                    Text("Mostly ranking in \(cityLabel)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MockTasteRankTheme.accent)

                    Button(store.followedFriendIDs.contains(friend.id) ? "Following" : "Follow") {
                        store.toggleFollow(friendID: friend.id)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(store.followedFriendIDs.contains(friend.id) ? MockTasteRankTheme.textPrimary : Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(store.followedFriendIDs.contains(friend.id) ? MockTasteRankTheme.surface : MockTasteRankTheme.accent)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(MockTasteRankTheme.border, lineWidth: store.followedFriendIDs.contains(friend.id) ? 1 : 0)
                            )
                    )
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 10) {
                    MemberStatCard(title: "Been", value: "\(max(recentRestaurants.count, 1) * 19)")
                    MemberStatCard(title: "Followers", value: "\(followers)")
                    MemberStatCard(title: "Following", value: "\(following)")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent activity")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)

                    if friendLogs.isEmpty {
                        Text("No recent rankings yet.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(MockTasteRankTheme.textSecondary)
                            .padding(14)
                            .background(CardBackground(cornerRadius: 16))
                    } else {
                        ForEach(Array(friendLogs.prefix(5)), id: \.id) { log in
                            if let restaurant = store.restaurant(for: log.restaurantID) {
                                NavigationLink {
                                    RestaurantDetailView(restaurant: restaurant)
                                } label: {
                                    FriendActivityRow(log: log, restaurant: restaurant)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !recentRestaurants.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top recs from \(friend.name)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(MockTasteRankTheme.textPrimary)

                        ForEach(Array(recentRestaurants.prefix(3)), id: \.id) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(restaurant: restaurant)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(restaurant.photoAssetNames.first ?? "tr_photo_1")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(restaurant.name)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(MockTasteRankTheme.textPrimary)
                                        Text(restaurant.locationLine)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundStyle(MockTasteRankTheme.textSecondary)
                                        Text(restaurant.cuisineDetails)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(MockTasteRankTheme.accent)
                                    }

                                    Spacer()

                                    TasteRankScoreBadge(score: restaurant.beliScore, diameter: 42)
                                }
                                .padding(12)
                                .background(CardBackground(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            TasteRankShareSheet(
                title: "Share \(friend.name)",
                message: "Follow \(friend.handle) on TasteRank for restaurant recs in \(cityLabel)."
            )
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            TasteRankIconButton(systemName: "square.and.arrow.up", size: 18) {
                showingShareSheet = true
            }
        }
    }
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let score: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
                .frame(width: 20, alignment: .leading)

            TasteRankAvatarView(
                seed: entry.avatarSeed,
                initials: String(entry.displayName.prefix(2)).uppercased(),
                size: 44
            )

            Text(entry.handle)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MockTasteRankTheme.textSecondary)

            Spacer()

            Text("\(score)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
        }
    }
}

private struct MemberStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(CardBackground(cornerRadius: 16))
    }
}

private struct FriendActivityRow: View {
    let log: FriendLog
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                Text(restaurant.locationLine)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)

                Text(log.note)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                    .lineLimit(2)

                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.accent)
            }

            Spacer()

            TasteRankScoreBadge(score: Double(log.rating) * 2, diameter: 40)
        }
        .padding(14)
        .background(CardBackground(cornerRadius: 16))
    }
}

private extension String {
    var displayNameFromHandle: String {
        let trimmed = replacingOccurrences(of: "@", with: "")
        guard !trimmed.isEmpty else { return self }
        return trimmed
            .split(separator: "_")
            .flatMap { $0.split(separator: " ") }
            .map { chunk in
                guard let first = chunk.first else { return "" }
                return String(first).uppercased() + chunk.dropFirst()
            }
            .joined(separator: " ")
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
            .environmentObject(MockTasteRankStore())
    }
}
