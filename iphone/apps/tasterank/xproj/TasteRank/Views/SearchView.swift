import SwiftUI

private enum SearchScope: String, CaseIterable {
    case restaurants = "Restaurants"
    case members = "Members"
}

private enum SearchQuickFilter: String, CaseIterable {
    case reserveNow = "Reserve now"
    case recs = "Recs"
    case trending = "Trending"
    case friends = "Friends"

    var icon: String {
        switch self {
        case .reserveNow:
            return "calendar"
        case .recs:
            return "heart.fill"
        case .trending:
            return "arrow.up.right"
        case .friends:
            return "person.2.fill"
        }
    }
}

private enum SearchLocation: String, CaseIterable {
    case current = "Current Location"
    case manhattan = "Manhattan"
    case seoul = "Seoul"
    case anywhere = "Anywhere"
}

struct SearchView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedScope: SearchScope = .restaurants
    @State private var selectedQuickFilter: SearchQuickFilter?
    @State private var selectedLocation: SearchLocation = .current
    @State private var showingLocationPicker = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                scopeTabs
                searchField
                locationField
                chipRow
                resultsSection
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                searchFocused = true
            }
        }
        .confirmationDialog("Search location", isPresented: $showingLocationPicker) {
            ForEach(SearchLocation.allCases, id: \.self) { location in
                Button(location.rawValue) {
                    selectedLocation = location
                }
            }
        }
    }

    private var header: some View {
        HStack {
            TasteRankWordmark(size: 32)
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(MockTasteRankTheme.muted.opacity(0.55)))
            }
            .buttonStyle(.plain)
        }
    }

    private var scopeTabs: some View {
        HStack(spacing: 0) {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Button {
                    selectedScope = scope
                } label: {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: scope == .restaurants ? "storefront" : "person.2")
                                .font(.system(size: 17, weight: .regular))
                            Text(scope.rawValue)
                                .font(.system(size: 20, weight: .bold))
                        }
                        Rectangle()
                            .fill(selectedScope == scope ? MockTasteRankTheme.accent : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedScope == scope ? MockTasteRankTheme.accent : MockTasteRankTheme.textPrimary)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
            TextField(searchPlaceholder, text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.system(size: 15, weight: .medium))
                .focused($searchFocused)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(CardBackground(cornerRadius: 14))
    }

    private var locationField: some View {
        Button {
            showingLocationPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                Text(selectedLocation.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MockTasteRankTheme.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(CardBackground(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SearchQuickFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedQuickFilter = selectedQuickFilter == filter ? nil : filter
                    } label: {
                        TasteRankChip(
                            title: filter.rawValue,
                            systemName: filter.icon,
                            filled: selectedQuickFilter == filter
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if selectedScope == .restaurants {
            restaurantResults
        } else {
            memberResults
        }
    }

    private var restaurantResults: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.query.isEmpty ? "Recents" : "Restaurants")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
                .padding(.bottom, 8)

            if restaurantMatches.isEmpty {
                Text("No restaurants matched your search.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(restaurantMatches) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.query.isEmpty ? "clock" : "fork.knife")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(MockTasteRankTheme.textSecondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(restaurant.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                                Text(restaurant.locationLine)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MockTasteRankTheme.muted)
                        }
                        .padding(.vertical, 12)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(MockTasteRankTheme.divider)
                                .frame(height: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var memberResults: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.query.isEmpty ? "Suggested Members" : "Members")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
                .padding(.bottom, 8)

            if memberMatches.isEmpty {
                Text("No members matched your search.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(memberMatches) { friend in
                    HStack(spacing: 10) {
                        NavigationLink {
                            MemberProfileView(friend: friend)
                        } label: {
                            HStack(spacing: 10) {
                                TasteRankAvatarView(seed: friend.avatarSeed, initials: friend.initials, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                                    Text(friend.handle)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(store.followedFriendIDs.contains(friend.id) ? "Following" : "Follow") {
                            store.toggleFollow(friendID: friend.id)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(store.followedFriendIDs.contains(friend.id) ? MockTasteRankTheme.textSecondary : MockTasteRankTheme.accent)
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(MockTasteRankTheme.divider)
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private var searchPlaceholder: String {
        selectedScope == .restaurants ? "Search restaurant, cuisine, occasion" : "Search member or handle"
    }

    private var restaurantMatches: [Restaurant] {
        let trimmedQuery = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseResults: [Restaurant]

        if trimmedQuery.isEmpty {
            let recents = ["flour_water", "kin_khao", "carbone"]
            baseResults = recents.compactMap(store.restaurant(for:))
        } else {
            baseResults = store.filteredRestaurants(query: trimmedQuery, filters: .default, sort: .recommended)
        }

        let filteredByQuickAction: [Restaurant]
        switch selectedQuickFilter {
        case .reserveNow:
            filteredByQuickAction = baseResults.filter { $0.priceLevel >= 3 }
        case .recs:
            filteredByQuickAction = store.recommendedRestaurantsFromFriends()
        case .trending:
            filteredByQuickAction = baseResults.filter(\.isTrending)
        case .friends:
            filteredByQuickAction = store.recommendedRestaurantsFromFriends()
        case .none:
            filteredByQuickAction = baseResults
        }

        let locationFiltered = filteredByQuickAction.filter(matchesLocation(_:))
        return locationFiltered.isEmpty ? filteredByQuickAction : locationFiltered
    }

    private var memberMatches: [FriendProfile] {
        let query = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var results: [FriendProfile]
        if query.isEmpty {
            results = Array(store.friends.prefix(8))
        } else {
            results = store.friends.filter {
                $0.name.lowercased().contains(query) || $0.handle.lowercased().contains(query)
            }
        }

        if selectedQuickFilter == .friends {
            results = results.filter { store.followedFriendIDs.contains($0.id) }
        }

        return results
    }

    private func matchesLocation(_ restaurant: Restaurant) -> Bool {
        switch selectedLocation {
        case .current:
            return restaurant.distanceMiles <= 250
        case .manhattan:
            return restaurant.neighborhood.city == "Manhattan" || restaurant.neighborhood.city == "Brooklyn"
        case .seoul:
            return restaurant.neighborhood.city == "Seoul"
        case .anywhere:
            return true
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(isPresented: .constant(true))
            .environmentObject(MockTasteRankStore())
    }
}
