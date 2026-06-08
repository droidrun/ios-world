import SwiftUI

private enum SearchRoute: Hashable {
    case event(UUID)
    case performer(UUID)
    case venue(UUID)
    case suggestion(SearchSuggestionKind)
}

struct SearchView: View {
    @Environment(MockTicketBoxStore.self) private var store
    @State private var searchViewModel = SearchViewModel()
    @State private var query = ""
    @State private var showingFilters = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                searchField
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                Divider()

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    recentSearchesSection
                    suggestionsSection
                } else {
                    searchResultsSection
                }
            }
            .padding(.bottom, 32)
        }
        .background(MockSeatGeekTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showingFilters) {
            NavigationStack {
                FilterSheetView(viewModel: searchViewModel)
                    .environment(store)
            }
        }
        .onChange(of: query) { _, newValue in
            searchViewModel.query = newValue
        }
        .navigationDestination(for: SearchRoute.self) { route in
            switch route {
            case .event(let eventID):
                if let event = store.event(for: eventID) {
                    EventDetailView(event: event)
                }
            case .performer(let performerID):
                if let performer = store.performer(for: performerID) {
                    let performerEvents = store.events(forPerformerID: performerID)
                        EventCollectionView(
                            title: performer.name,
                            subtitle: performerEvents.isEmpty ? "No upcoming events" : "\(performerEvents.count) events",
                            events: performerEvents
                        )
                }
            case .venue(let venueID):
                if let venue = store.venue(for: venueID) {
                        EventCollectionView(
                            title: venue.name,
                            subtitle: venue.city,
                            events: store.events(forVenueID: venueID)
                        )
                }
            case .suggestion(let suggestion):
                EventCollectionView(
                    title: suggestion.title,
                    events: store.eventsForSuggestion(suggestion)
                )
            }
        }
    }

    private var filteredEvents: [Event] {
        if hasActiveFilters {
            return searchViewModel.filteredEvents(store: store)
        }
        return store.filteredEvents(query: query)
    }
    private var filteredPerformers: [Performer] { store.filteredPerformers(query: query) }
    private var filteredVenues: [Venue] { store.filteredVenues(query: query) }

    private var searchField: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)

            TextField("Search on TicketBox", text: $query)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(MockSeatGeekTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Button {
                showingFilters = true
            } label: {
                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(hasActiveFilters ? MockSeatGeekTheme.accent : MockSeatGeekTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(MockSeatGeekTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(MockSeatGeekTheme.border, lineWidth: 1)
                )
                .shadow(color: MockSeatGeekTheme.shadow, radius: 8, x: 0, y: 4)
        )
    }

    private var hasActiveFilters: Bool {
        searchViewModel.filterState != .default
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent searches")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)

                Spacer()

                if !store.recentSearches.isEmpty {
                    Button("Clear") {
                        store.clearRecentSearches()
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)

            if store.recentSearches.isEmpty {
                Text("No recent searches yet.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    .padding(.horizontal, 18)
            } else {
                VStack(spacing: 0) {
                    ForEach(store.recentSearches) { record in
                        if let route = route(for: record) {
                            NavigationLink(value: route) {
                                SearchRecordRow(record: record)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    handleRecentSelection(record)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggestions")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                .padding(.horizontal, 18)

            VStack(spacing: 0) {
                ForEach(store.searchSuggestions) { suggestion in
                    NavigationLink(value: SearchRoute.suggestion(suggestion.kind)) {
                        SuggestionRow(suggestion: suggestion)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            store.recordSearch(for: suggestion.kind)
                        }
                    )
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if filteredEvents.isEmpty && filteredPerformers.isEmpty && filteredVenues.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textTertiary)
                    Text("No results")
                        .font(.system(size: 24, weight: .bold))
                    Text("Try a team, artist, venue, or event.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
            } else {
                SearchResultSection(title: "Events") {
                    ForEach(filteredEvents) { event in
                        NavigationLink(value: SearchRoute.event(event.id)) {
                            SearchResultRow(
                                title: event.title,
                                subtitle: "\(Formatters.compactMonthDay(event.date)) · \(store.venue(for: event.venueID)?.name ?? event.city)",
                                leading: .event(event)
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                store.recordViewedEvent(event.id)
                            }
                        )
                    }
                }

                SearchResultSection(title: "Performers") {
                    ForEach(filteredPerformers) { performer in
                        NavigationLink(value: SearchRoute.performer(performer.id)) {
                            SearchResultRow(
                                title: performer.name,
                                subtitle: {
                                    let count = store.events(forPerformerID: performer.id).count
                                    return count > 0 ? "\(count) events" : "No upcoming events"
                                }(),
                                leading: .performer(performer)
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                store.recordSearch(for: performer)
                            }
                        )
                    }
                }

                SearchResultSection(title: "Venues") {
                    ForEach(filteredVenues) { venue in
                        NavigationLink(value: SearchRoute.venue(venue.id)) {
                            SearchResultRow(
                                title: venue.name,
                                subtitle: venue.city,
                                leading: .venue(venue)
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                store.recordSearch(for: venue)
                            }
                        )
                    }
                }
            }
        }
    }

    private func route(for record: SearchRecord) -> SearchRoute? {
        switch record.kind {
        case .event:
            guard let referenceID = record.referenceID else { return nil }
            return .event(referenceID)
        case .performer:
            guard let referenceID = record.referenceID else { return nil }
            return .performer(referenceID)
        case .venue:
            guard let referenceID = record.referenceID else { return nil }
            return .venue(referenceID)
        case .suggestion:
            let suggestion = SearchSuggestionKind(rawValue: record.imageName) ?? .popularEvents
            return .suggestion(suggestion)
        }
    }

    private func handleRecentSelection(_ record: SearchRecord) {
        switch record.kind {
        case .event:
            if let referenceID = record.referenceID {
                store.recordViewedEvent(referenceID)
            }
        case .performer:
            if let referenceID = record.referenceID, let performer = store.performer(for: referenceID) {
                store.recordSearch(for: performer)
            }
        case .venue:
            if let referenceID = record.referenceID, let venue = store.venue(for: referenceID) {
                store.recordSearch(for: venue)
            }
        case .suggestion:
            let suggestion = SearchSuggestionKind(rawValue: record.imageName) ?? .popularEvents
            store.recordSearch(for: suggestion)
        }
    }
}

private struct SearchRecordRow: View {
    let record: SearchRecord

    var body: some View {
        HStack(spacing: 18) {
            SearchLeadingView(
                kind: record.kind,
                imageName: record.imageName,
                title: record.title
            )

            Text(record.title)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MockSeatGeekTheme.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

private struct SuggestionRow: View {
    let suggestion: SearchSuggestion

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 56, height: 56)
                Image(systemName: suggestion.systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(suggestion.title)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MockSeatGeekTheme.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var backgroundColor: Color {
        switch suggestion.kind {
        case .popularEvents:
            return MockSeatGeekTheme.blue.opacity(0.12)
        case .favoritePerformers:
            return MockSeatGeekTheme.accent.opacity(0.12)
        case .justAnnounced:
            return MockSeatGeekTheme.pink.opacity(0.12)
        }
    }

    private var iconColor: Color {
        switch suggestion.kind {
        case .popularEvents:
            return MockSeatGeekTheme.blue
        case .favoritePerformers:
            return MockSeatGeekTheme.accent
        case .justAnnounced:
            return MockSeatGeekTheme.pink
        }
    }
}

private struct SearchResultSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                .padding(.horizontal, 18)

            VStack(spacing: 0) {
                content
            }
            .background(CardBackground())
            .padding(.horizontal, 18)
        }
    }
}

private enum SearchResultLeading {
    case event(Event)
    case performer(Performer)
    case venue(Venue)
}

private struct SearchResultRow: View {
    let title: String
    let subtitle: String
    let leading: SearchResultLeading

    var body: some View {
        HStack(spacing: 16) {
            switch leading {
            case .event(let event):
                EventArtworkView(event: event)
                    .frame(width: 62, height: 62)
            case .performer(let performer):
                SearchLeadingView(kind: .performer, imageName: performer.imageName, title: performer.name)
            case .venue(let venue):
                SearchLeadingView(kind: .venue, imageName: venue.imageName, title: venue.name)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if case .event(let event) = leading,
               let topScore = event.listings.map(\.dealScore).max() {
                DealScoreView(score: topScore, size: 28)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

struct SearchLeadingView: View {
    let kind: SearchRecordKind
    let imageName: String
    let title: String

    var body: some View {
        Group {
            switch kind {
            case .performer:
                if isSportsToken(imageName) {
                    TeamBadgeView(token: imageName, size: 56)
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MockSeatGeekTheme.accent.opacity(0.9), MockSeatGeekTheme.pink.opacity(0.75)],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                        Text(initials)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                }
            case .venue:
                VenueArtworkView(imageName: imageName)
                    .frame(width: 56, height: 56)
            case .event:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: eventTileColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .frame(width: 56, height: 56)
            case .suggestion:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MockSeatGeekTheme.surfaceMuted)
                    .frame(width: 56, height: 56)
            }
        }
    }

    private var initials: String {
        title
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
    }

    private func isSportsToken(_ token: String) -> Bool {
        ["pirates", "cavaliers", "warriors", "bulls", "blues", "sharks", "yankees", "giants", "padres", "braves", "dodgers", "lakers", "celtics"].contains(token)
    }

    private var eventTileColors: [Color] {
        switch imageName {
        case "oracle_baseball":
            return [Color(red: 0.08, green: 0.17, blue: 0.28), Color(red: 0.25, green: 0.49, blue: 0.73)]
        case "sharks_map":
            return [Color(red: 0.1, green: 0.19, blue: 0.28), Color(red: 0.35, green: 0.5, blue: 0.68)]
        case "bts_stadium", "harry_styles_stage", "lady_gaga_stage":
            return [Color(red: 0.22, green: 0.06, blue: 0.16), Color(red: 0.63, green: 0.22, blue: 0.58)]
        default:
            return [Color(red: 0.14, green: 0.16, blue: 0.22), Color(red: 0.32, green: 0.37, blue: 0.48)]
        }
    }
}
