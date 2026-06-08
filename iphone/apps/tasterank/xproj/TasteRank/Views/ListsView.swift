import SwiftUI

private enum TasteRankListScope: String, CaseIterable {
    case been = "Been"
    case wantToTry = "Want to Try"
    case recs = "Recs"
    case guides = "Guides"
    case more = "More"
}

private enum TasteRankListSort: String, CaseIterable {
    case score = "Score"
    case distance = "Distance"
    case alphabetical = "A-Z"
}

struct ListsView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @State private var selectedScope: TasteRankListScope = .been
    @State private var selectedCity = "All Cities"
    @State private var selectedCuisine = "All Cuisines"
    @State private var reserveOnly = false
    @State private var openNowOnly = false
    @State private var sortMode: TasteRankListSort = .score
    @State private var searchText = ""

    @State private var showingShareSheet = false
    @State private var showingOptionsSheet = false
    @State private var showingMapSheet = false
    @State private var showingFilterSheet = false
    @State private var showingSearchSheet = false
    @State private var showingCityPicker = false
    @State private var showingCuisinePicker = false
    @State private var showingSortPicker = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    titleSection
                    scopeTabs
                    filterRow
                    sortRow
                    rankedRestaurants
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)

            Button {
                showingMapSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.system(size: 16, weight: .regular))
                    Text("View Map")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(MockTasteRankTheme.accent)
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $showingShareSheet) {
            TasteRankShareSheet(
                title: "Share \(selectedScope.rawValue)",
                message: "Check out my \(selectedScope.rawValue.lowercased()) list on TasteRank. \(displayedRestaurants.count) spots saved right now."
            )
        }
        .sheet(isPresented: $showingOptionsSheet) {
            ListOptionsSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingMapSheet) {
            NavigationStack {
                ListMapSheet(restaurants: displayedRestaurants)
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingFilterSheet) {
            ListFilterSheet(
                selectedCity: $selectedCity,
                availableCities: availableCities,
                selectedCuisine: $selectedCuisine,
                availableCuisines: availableCuisines,
                reserveOnly: $reserveOnly,
                openNowOnly: $openNowOnly,
                sortMode: $sortMode,
                searchText: $searchText
            )
        }
        .sheet(isPresented: $showingSearchSheet) {
            NavigationStack {
                ListSearchSheet(query: $searchText, restaurants: displayedRestaurants)
            }
            .environmentObject(store)
        }
        .confirmationDialog("City", isPresented: $showingCityPicker) {
            ForEach(availableCities, id: \.self) { city in
                Button(city) {
                    selectedCity = city
                }
            }
        }
        .confirmationDialog("Cuisine", isPresented: $showingCuisinePicker) {
            ForEach(availableCuisines, id: \.self) { cuisine in
                Button(cuisine) {
                    selectedCuisine = cuisine
                }
            }
        }
        .confirmationDialog("Sort", isPresented: $showingSortPicker) {
            ForEach(TasteRankListSort.allCases, id: \.self) { mode in
                Button(mode.rawValue) {
                    sortMode = mode
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Text("MY LISTS")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                HStack(spacing: 10) {
                    TasteRankIconButton(systemName: "square.and.arrow.up", size: 20) {
                        showingShareSheet = true
                    }
                    TasteRankIconButton(systemName: "ellipsis", size: 20) {
                        showingOptionsSheet = true
                    }
                }
            }
        }
    }

    private var titleSection: some View {
        HStack(spacing: 8) {
            Text("Restaurants")
                .font(MockTasteRankTheme.displayFont(size: 26))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
            Spacer()
        }
    }

    private var scopeTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(TasteRankListScope.allCases, id: \.self) { scope in
                    Button {
                        selectedScope = scope
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 3) {
                                Text(scope.rawValue)
                                    .font(.system(size: 16, weight: selectedScope == scope ? .bold : .semibold))
                                    .foregroundStyle(selectedScope == scope ? MockTasteRankTheme.textPrimary : MockTasteRankTheme.textSecondary)
                                if scope == .more {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                                }
                            }
                            Rectangle()
                                .fill(selectedScope == scope ? MockTasteRankTheme.textPrimary : Color.clear)
                                .frame(height: 3)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MockTasteRankTheme.divider)
                .frame(height: 1)
                .offset(y: 2)
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    showingFilterSheet = true
                } label: {
                    TasteRankChip(title: "", systemName: "line.3.horizontal.decrease", filled: hasActiveFilters)
                }
                .buttonStyle(.plain)

                Button {
                    showingCityPicker = true
                } label: {
                    TasteRankChip(
                        title: selectedCity == "All Cities" ? "City" : selectedCity,
                        filled: selectedCity != "All Cities",
                        trailingChevron: true
                    )
                }
                .buttonStyle(.plain)

                Button {
                    reserveOnly.toggle()
                } label: {
                    TasteRankChip(title: "Reserve", filled: reserveOnly)
                }
                .buttonStyle(.plain)

                Button {
                    openNowOnly.toggle()
                } label: {
                    TasteRankChip(title: "Open now", filled: openNowOnly)
                }
                .buttonStyle(.plain)

                Button {
                    showingCuisinePicker = true
                } label: {
                    TasteRankChip(
                        title: selectedCuisine == "All Cuisines" ? "Cuisine" : selectedCuisine,
                        filled: selectedCuisine != "All Cuisines",
                        trailingChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
    }

    private var sortRow: some View {
        HStack {
            Button {
                showingSortPicker = true
            } label: {
                Label(sortMode.rawValue, systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.accent)
            }
            .buttonStyle(.plain)

            Spacer()

            TasteRankIconButton(systemName: "magnifyingglass", size: 20, foreground: MockTasteRankTheme.accent) {
                showingSearchSheet = true
            }
        }
    }

    @ViewBuilder
    private var rankedRestaurants: some View {
        if selectedScope == .guides {
            guideSections
        } else if selectedScope == .more {
            customListsSection
        } else if displayedRestaurants.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No spots match those filters.")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                Text("Try clearing a city, cuisine, or search term.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
            }
            .padding(.top, 20)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(displayedRestaurants.enumerated()), id: \.element.id) { index, restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        RestaurantRankingRow(rank: index + 1, restaurant: restaurant)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var guideSections: some View {
        if store.guideLists.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No guides available.")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
            }
            .padding(.top, 20)
        } else {
            LazyVStack(spacing: 14) {
                ForEach(store.guideLists) { guide in
                    NavigationLink {
                        CustomListDetailView(list: guide)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(guide.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                                Spacer()
                                Text("\(guide.restaurantIDs.count) spots")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(MockTasteRankTheme.border)
                            }

                            let guideRestaurants = store.restaurants
                                .filter { guide.restaurantIDs.contains($0.id) }
                                .sorted { $0.beliScore > $1.beliScore }
                                .prefix(3)
                            ForEach(Array(guideRestaurants.enumerated()), id: \.element.id) { index, restaurant in
                                HStack(spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(MockTasteRankTheme.accent)
                                        .frame(width: 22)
                                    Text(restaurant.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                                    Spacer()
                                    Text(String(format: "%.1f", restaurant.beliScore))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(MockTasteRankTheme.accent)
                                }
                            }
                        }
                        .padding(14)
                        .background(CardBackground(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var userCreatedLists: [ListCollection] {
        store.listCollections.filter { $0.id != "list_want_to_try" && $0.id != "list_guides" }
    }

    @ViewBuilder
    private var customListsSection: some View {
        if userCreatedLists.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No custom lists yet.")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                Text("Tap the \u{2026} button above to create a new list.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
            }
            .padding(.top, 20)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(userCreatedLists) { list in
                    NavigationLink {
                        CustomListDetailView(list: list)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(list.name)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                                Text("\(list.restaurantIDs.count) spot\(list.restaurantIDs.count == 1 ? "" : "s")")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(MockTasteRankTheme.border)
                        }
                        .padding(14)
                        .background(CardBackground(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var activeRestaurants: [Restaurant] {
        switch selectedScope {
        case .been:
            return store.visitedRestaurants
        case .wantToTry:
            return store.wantToTryRestaurants.sorted { $0.beliScore > $1.beliScore }
        case .recs:
            return store.recommendedRestaurantsFromFriends().sorted { $0.beliScore > $1.beliScore }
        case .guides:
            return store.guideRestaurants.sorted { $0.beliScore > $1.beliScore }
        case .more:
            let extraIDs = Set(store.listCollections
                .filter { $0.id != "list_want_to_try" && $0.id != "list_guides" }
                .flatMap(\.restaurantIDs))
            return store.restaurants
                .filter { extraIDs.contains($0.id) }
                .sorted { $0.beliScore > $1.beliScore }
        }
    }

    private var displayedRestaurants: [Restaurant] {
        var results = activeRestaurants

        if selectedCity != "All Cities" {
            results = results.filter { $0.neighborhood.city == selectedCity }
        }

        if selectedCuisine != "All Cuisines" {
            results = results.filter { $0.cuisine.name == selectedCuisine }
        }

        if reserveOnly {
            results = results.filter { $0.priceLevel >= 3 }
        }

        if openNowOnly {
            results = results.filter { $0.hours.isOpen(at: Date()) }
        }

        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedQuery.isEmpty {
            results = results.filter { restaurant in
                restaurant.name.lowercased().contains(trimmedQuery)
                    || restaurant.locationLine.lowercased().contains(trimmedQuery)
                    || restaurant.cuisineDetails.lowercased().contains(trimmedQuery)
                    || restaurant.searchHints.contains(where: { $0.lowercased().contains(trimmedQuery) })
            }
        }

        switch sortMode {
        case .score:
            results.sort { $0.beliScore > $1.beliScore }
        case .distance:
            results.sort { $0.distanceMiles < $1.distanceMiles }
        case .alphabetical:
            results.sort { $0.name < $1.name }
        }

        return results
    }

    private var availableCities: [String] {
        ["All Cities"] + Array(Set(activeRestaurants.map(\.neighborhood.city))).sorted()
    }

    private var availableCuisines: [String] {
        ["All Cuisines"] + Array(Set(activeRestaurants.map(\.cuisine.name))).sorted()
    }

    private var hasActiveFilters: Bool {
        selectedCity != "All Cities"
            || selectedCuisine != "All Cuisines"
            || reserveOnly
            || openNowOnly
            || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct RestaurantRankingRow: View {
    @EnvironmentObject private var store: MockTasteRankStore
    let rank: Int
    let restaurant: Restaurant

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(rank).")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(restaurant.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("row_name_\(restaurant.id)")

                    Button {
                        store.toggleVisited(restaurantID: restaurant.id)
                    } label: {
                        let isVisited = store.visitedRestaurantIDs.contains(restaurant.id)
                        Image(systemName: isVisited ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isVisited ? MockTasteRankTheme.accent : MockTasteRankTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("row_visited_\(restaurant.id)")
                }

                Text(restaurant.cuisineDetails)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.accent)

                Text(restaurant.locationLine)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                    .lineLimit(2)

                Text(restaurant.statusLine)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                    .padding(.top, 6)
            }

            Spacer(minLength: 8)

            TasteRankScoreBadge(score: restaurant.beliScore)
                .padding(.top, 2)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MockTasteRankTheme.divider)
                .frame(height: 1)
        }
    }
}

private struct ListOptionsSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Manage Lists")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                HStack(spacing: 10) {
                    TextField("New list name", text: $newListName)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(CardBackground(cornerRadius: 14))

                    Button("Create") {
                        store.createList(name: newListName)
                        newListName = ""
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MockTasteRankTheme.accent)
                    )
                }

                Text("Saved lists")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(store.listCollections) { list in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(list.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                                    Text("\(list.restaurantIDs.count) spots")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(CardBackground(cornerRadius: 16))
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("Lists")
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

private struct ListMapSheet: View {
    let restaurants: [Restaurant]

    private var groupedByCity: [(key: String, value: [Restaurant])] {
        Dictionary(grouping: restaurants, by: \.neighborhood.city)
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            ForEach(groupedByCity, id: \.key) { group in
                Section(group.key) {
                    ForEach(group.value) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurant: restaurant)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(restaurant.name)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(restaurant.locationLine)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                                }
                                Spacer()
                                Text(String(format: "%.1f", restaurant.beliScore))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(MockTasteRankTheme.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Map Preview")
    }
}

private struct ListFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCity: String
    let availableCities: [String]
    @Binding var selectedCuisine: String
    let availableCuisines: [String]
    @Binding var reserveOnly: Bool
    @Binding var openNowOnly: Bool
    @Binding var sortMode: TasteRankListSort
    @Binding var searchText: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Search") {
                    TextField("Restaurant, cuisine, neighborhood", text: $searchText)
                }

                Section("Quick Filters") {
                    Toggle("Reserve only", isOn: $reserveOnly)
                    Toggle("Open now", isOn: $openNowOnly)
                }

                Section("City") {
                    Picker("City", selection: $selectedCity) {
                        ForEach(availableCities, id: \.self) { city in
                            Text(city).tag(city)
                        }
                    }
                }

                Section("Cuisine") {
                    Picker("Cuisine", selection: $selectedCuisine) {
                        ForEach(availableCuisines, id: \.self) { cuisine in
                            Text(cuisine).tag(cuisine)
                        }
                    }
                }

                Section("Sort") {
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(TasteRankListSort.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }

                Section {
                    Button("Reset Filters", role: .destructive) {
                        selectedCity = "All Cities"
                        selectedCuisine = "All Cuisines"
                        reserveOnly = false
                        openNowOnly = false
                        sortMode = .score
                        searchText = ""
                    }
                }
            }
            .navigationTitle("Filters")
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

private struct ListSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var query: String
    let restaurants: [Restaurant]

    private var previewResults: [Restaurant] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return Array(restaurants.prefix(8)) }
        return restaurants.filter { restaurant in
            restaurant.name.lowercased().contains(trimmed)
                || restaurant.locationLine.lowercased().contains(trimmed)
                || restaurant.cuisineDetails.lowercased().contains(trimmed)
        }
    }

    var body: some View {
        List {
            Section {
                TextField("Search your current list", text: $query)
                    .textInputAutocapitalization(.words)
            }

            Section("Results") {
                ForEach(previewResults) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(restaurant.name)
                                .font(.system(size: 16, weight: .semibold))
                            Text(restaurant.locationLine)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(MockTasteRankTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search List")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

private struct CustomListDetailView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    let list: ListCollection

    private var restaurants: [Restaurant] {
        list.restaurantIDs.compactMap { store.restaurant(for: $0) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if restaurants.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                    Text("No restaurants yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                    Text("Add spots from any restaurant page.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(restaurants.enumerated()), id: \.element.id) { index, restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurant: restaurant)
                        } label: {
                            RestaurantRankingRow(rank: index + 1, restaurant: restaurant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ListsView()
            .environmentObject(MockTasteRankStore())
    }
}
