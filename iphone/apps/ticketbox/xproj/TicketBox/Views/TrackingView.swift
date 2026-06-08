import SwiftUI

struct TrackingView: View {
    @Environment(MockTicketBoxStore.self) private var store
    @State private var selectedMode: TrackingMode = .performers
    @State private var query = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Favorites")
                    .font(.system(size: 40, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)

                modePicker

                trackingSearchBar

                if selectedMode == .performers {
                    favoritePrompt
                }

                switch selectedMode {
                case .events:
                    eventSection
                case .performers:
                    performerSection
                case .venues:
                    venueSection
                }
            }
            .padding(.bottom, 34)
        }
        .background(MockSeatGeekTheme.background.ignoresSafeArea())
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(TrackingMode.allCases) { mode in
                Button {
                    selectedMode = mode
                    query = ""
                } label: {
                    VStack(spacing: 12) {
                        Text(mode.rawValue)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(selectedMode == mode ? MockSeatGeekTheme.textPrimary : MockSeatGeekTheme.textSecondary)
                        Rectangle()
                            .fill(selectedMode == mode ? MockSeatGeekTheme.textPrimary : Color.clear)
                            .frame(height: 4)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
    }

    private var trackingSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textTertiary)

            TextField(searchPlaceholder, text: $query)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MockSeatGeekTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MockSeatGeekTheme.border, lineWidth: 1)
                )
        )
        .padding(.horizontal, 18)
    }

    private var favoritePrompt: some View {
        VStack(spacing: 16) {
            Text(store.favoritePerformers.isEmpty ? "Track your favorite performers" : "You're following \(store.favoritePerformers.count) performers")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(MockSeatGeekTheme.textPrimary)

            Text(favoritePromptSubtitle)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 36) {
                ForEach(MusicServiceKind.allCases) { service in
                    Button {
                        store.toggleMusicService(service)
                    } label: {
                        VStack(spacing: 10) {
                            ZStack(alignment: .topTrailing) {
                                ServiceIconView(service: service, size: 84)

                                if store.settings.connectedMusicServices.contains(service) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(MockSeatGeekTheme.accent)
                                        .background(Circle().fill(Color.white))
                                        .offset(x: 8, y: -8)
                                }
                            }
                            Text(service.trackingName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(CardBackground())
        .padding(.horizontal, 18)
    }

    private var performerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if isSearching {
                performerListSection(title: "Results", performers: searchedPerformers)
            } else {
                if !store.favoritePerformers.isEmpty {
                    performerListSection(title: "Following", performers: store.favoritePerformers)
                }

                if !recommendedPerformers.isEmpty {
                    performerListSection(
                        title: store.favoritePerformers.isEmpty ? "Recommended" : "Recommended next",
                        performers: recommendedPerformers
                    )
                }
            }

            if displayedPerformerCount == 0 {
                TrackingEmptyState(
                    title: "No performers found",
                    subtitle: "Try another artist, team, or connect a music service to import favorites."
                )
                .padding(.horizontal, 18)
            }
        }
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if isSearching {
                eventListSection(title: "Results", events: searchedEvents)
            } else {
                if !store.favoriteEvents.isEmpty {
                    eventListSection(title: "Following", events: store.favoriteEvents)
                }

                if !recommendedEvents.isEmpty {
                    eventListSection(
                        title: store.favoriteEvents.isEmpty ? "Events" : "Recommended next",
                        events: recommendedEvents
                    )
                }
            }

            if displayedEventCount == 0 {
                TrackingEmptyState(
                    title: "No tracked events yet",
                    subtitle: "Favorite an event from Browse or Search to keep it here."
                )
                .padding(.horizontal, 18)
            }
        }
    }

    private var venueSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if isSearching {
                venueListSection(title: "Results", venues: searchedVenues)
            } else {
                if !store.favoriteVenues.isEmpty {
                    venueListSection(title: "Following", venues: store.favoriteVenues)
                }

                if !recommendedVenues.isEmpty {
                    venueListSection(
                        title: store.favoriteVenues.isEmpty ? "Venues" : "Recommended next",
                        venues: recommendedVenues
                    )
                }
            }

            if displayedVenueCount == 0 {
                TrackingEmptyState(
                    title: "No venues found",
                    subtitle: "Follow a venue from event details or search results to track it here."
                )
                .padding(.horizontal, 18)
            }
        }
    }

    private func performerListSection(title: String, performers: [Performer]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .padding(.horizontal, 18)

            VStack(spacing: 0) {
                ForEach(performers) { performer in
                    HStack(spacing: 0) {
                        NavigationLink {
                            let performerEvents = store.events(forPerformerID: performer.id)
                            EventCollectionView(
                                title: performer.name,
                                subtitle: performerEvents.isEmpty ? "No upcoming events" : "\(performerEvents.count) events",
                                events: performerEvents
                            )
                        } label: {
                            TrackingPerformerRow(performer: performer)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.toggleFavoritePerformer(performer.id)
                        } label: {
                            Image(systemName: store.favoritePerformerIDs.contains(performer.id) ? "heart.fill" : "heart")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(MockSeatGeekTheme.accent)
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 18)
                    }

                    if performer.id != performers.last?.id {
                        Divider()
                            .padding(.leading, 106)
                    }
                }
            }
            .background(CardBackground())
            .padding(.horizontal, 18)
        }
    }

    private func eventListSection(title: String, events: [Event]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .padding(.horizontal, 18)

            VStack(spacing: 0) {
                ForEach(events) { event in
                    HStack(spacing: 0) {
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            TrackingEventRow(event: event)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.toggleFavoriteEvent(event.id)
                        } label: {
                            Image(systemName: store.favoriteEventIDs.contains(event.id) ? "heart.fill" : "heart")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(MockSeatGeekTheme.accent)
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 18)
                    }

                    if event.id != events.last?.id {
                        Divider()
                            .padding(.leading, 106)
                    }
                }
            }
            .background(CardBackground())
            .padding(.horizontal, 18)
        }
    }

    private func venueListSection(title: String, venues: [Venue]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .padding(.horizontal, 18)

            VStack(spacing: 0) {
                ForEach(venues) { venue in
                    HStack(spacing: 0) {
                        NavigationLink {
                            EventCollectionView(
                                title: venue.name,
                                subtitle: venue.city,
                                events: store.events(forVenueID: venue.id)
                            )
                        } label: {
                            TrackingVenueRow(venue: venue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.toggleFavoriteVenue(venue.id)
                        } label: {
                            Image(systemName: store.favoriteVenueIDs.contains(venue.id) ? "heart.fill" : "heart")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(MockSeatGeekTheme.accent)
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 18)
                    }

                    if venue.id != venues.last?.id {
                        Divider()
                            .padding(.leading, 106)
                    }
                }
            }
            .background(CardBackground())
            .padding(.horizontal, 18)
        }
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var favoritePromptSubtitle: String {
        if store.settings.connectedMusicServices.isEmpty {
            return "Connect Apple Music or Spotify to pull in favorites and improve recommendations."
        }

        let serviceNames = store.settings.connectedMusicServices
            .map(\.trackingName)
            .sorted()
            .joined(separator: " and ")
        return "Imported favorites from \(serviceNames). Tap hearts to tune what you track."
    }

    private var searchedPerformers: [Performer] {
        store.filteredPerformers(query: query)
    }

    private var recommendedPerformers: [Performer] {
        store.recommendedPerformers.filter { !store.favoritePerformerIDs.contains($0.id) }
    }

    private var searchedEvents: [Event] {
        store.filteredEvents(query: query)
    }

    private var recommendedEvents: [Event] {
        deduplicatedEvents(store.trendingEvents + Array(store.events(for: nil).prefix(6)))
            .filter { !store.favoriteEventIDs.contains($0.id) }
    }

    private var searchedVenues: [Venue] {
        store.filteredVenues(query: query)
    }

    private var recommendedVenues: [Venue] {
        deduplicatedVenues(
            store.trendingEvents.compactMap { store.venue(for: $0.venueID) } +
            store.recommendedPerformers.flatMap { performer in
                store.events(forPerformerID: performer.id).compactMap { event in
                    store.venue(for: event.venueID)
                }
            }
        )
        .filter { !store.favoriteVenueIDs.contains($0.id) }
    }

    private var displayedPerformerCount: Int {
        isSearching ? searchedPerformers.count : store.favoritePerformers.count + recommendedPerformers.count
    }

    private var displayedEventCount: Int {
        isSearching ? searchedEvents.count : store.favoriteEvents.count + recommendedEvents.count
    }

    private var displayedVenueCount: Int {
        isSearching ? searchedVenues.count : store.favoriteVenues.count + recommendedVenues.count
    }

    private func deduplicatedEvents(_ events: [Event]) -> [Event] {
        var seen = Set<UUID>()
        return events.filter { event in
            seen.insert(event.id).inserted
        }
    }

    private func deduplicatedVenues(_ venues: [Venue]) -> [Venue] {
        var seen = Set<UUID>()
        return venues.filter { venue in
            seen.insert(venue.id).inserted
        }
    }

    private var searchPlaceholder: String {
        switch selectedMode {
        case .events:
            return "Search for events"
        case .performers:
            return "Search for performers"
        case .venues:
            return "Search for venues"
        }
    }
}

private struct TrackingEmptyState: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textTertiary)
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(CardBackground())
    }
}

private struct TrackingPerformerRow: View {
    let performer: Performer

    var body: some View {
        HStack(spacing: 18) {
            if performer.category == .sports {
                TeamBadgeView(token: performer.imageName, size: 72)
            } else {
                PerformerAvatar(token: performer.imageName)
                    .frame(width: 72, height: 72)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(performer.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                Text("\(performer.eventCount) Events")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.leading, 18)
        .padding(.vertical, 16)
    }
}

private struct TrackingEventRow: View {
    @Environment(MockTicketBoxStore.self) private var store
    let event: Event

    var body: some View {
        HStack(spacing: 16) {
            EventArtworkView(event: event)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .lineLimit(2)

                Text("\(Formatters.compactMonthDay(event.date)) · \(store.venue(for: event.venueID)?.name ?? event.city)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.leading, 18)
        .padding(.vertical, 16)
    }
}

private struct TrackingVenueRow: View {
    let venue: Venue

    var body: some View {
        HStack(spacing: 16) {
            VenueArtworkView(imageName: venue.imageName)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(venue.name)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                Text(venue.city)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.leading, 18)
        .padding(.vertical, 16)
    }
}

private struct PerformerAvatar: View {
    let token: String

    var body: some View {
        ZStack {
            gradient
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 26, height: 26)
                Capsule()
                    .fill(Color.white.opacity(0.26))
                    .frame(width: 36, height: 24)
            }
            .offset(y: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var gradient: some View {
        let colors: [Color]
        switch token {
        case "harry_styles":
            colors = [Color(red: 0.14, green: 0.03, blue: 0.07), Color(red: 0.72, green: 0.1, blue: 0.18)]
        case "lady_gaga":
            colors = [Color(red: 0.09, green: 0.08, blue: 0.24), Color(red: 0.69, green: 0.34, blue: 0.74)]
        case "one_republic":
            colors = [Color(red: 0.08, green: 0.1, blue: 0.28), Color(red: 0.3, green: 0.56, blue: 0.96)]
        default:
            colors = [Color(red: 0.04, green: 0.08, blue: 0.14), Color(red: 0.09, green: 0.42, blue: 0.64)]
        }

        return LinearGradient(colors: colors, startPoint: .bottomLeading, endPoint: .topTrailing)
    }
}
