import SwiftUI

struct HomeView: View {
    @Environment(MockTicketBoxStore.self) private var store
    @State private var selectedCategory: EventCategory?
    @State private var showBrowseSettings = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                browseHeader
                    .padding(.bottom, 12)

                categoryRail
                    .padding(.bottom, 16)

                let categoryEvts = categoryEvents
                let featured = featuredEvent(from: categoryEvts)
                let trending = trendingEvents(from: categoryEvts)

                // Featured event card
                if let featured {
                    NavigationLink(value: featured.id) {
                        FeaturedEventCard(event: featured)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }

                // Trending events for you (ranked text rows)
                if !trending.isEmpty {
                    trendingSection(events: trending)
                        .padding(.bottom, 8)
                }

                // Recently viewed events (horizontal image cards)
                let recent = displayedRecentEvents(from: categoryEvts)
                if !recent.isEmpty {
                    horizontalCardSection(
                        title: "Recently viewed events",
                        events: recent
                    )
                    .padding(.bottom, 8)
                }

                // Popular tonight (horizontal image cards)
                let tonight = popularTonight(from: categoryEvts, featured: featured)
                if !tonight.isEmpty {
                    horizontalCardSection(
                        title: "Popular tonight",
                        events: tonight
                    )
                    .padding(.bottom, 8)
                }

                // Popular this weekend
                let weekend = popularThisWeekend(from: categoryEvts, featured: featured)
                if !weekend.isEmpty {
                    horizontalCardSection(
                        title: "Popular this weekend",
                        events: weekend
                    )
                    .padding(.bottom, 8)
                }

                // Just announced
                let justAnnounced = justAnnouncedEvents(from: categoryEvts)
                if !justAnnounced.isEmpty {
                    horizontalCardSection(
                        title: "Just announced",
                        events: justAnnounced
                    )
                    .padding(.bottom, 8)
                }
            }
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(MockSeatGeekTheme.background.ignoresSafeArea())
        .navigationDestination(for: UUID.self) { eventID in
            if let event = store.event(for: eventID) {
                EventDetailView(event: event)
            }
        }
        .sheet(isPresented: $showBrowseSettings) {
            BrowseSettingsSheet(selectedCategory: $selectedCategory)
                .environment(store)
        }
    }

    // MARK: - Data

    private var categoryEvents: [Event] {
        store.browseEvents(for: selectedCategory)
    }

    private func featuredEvent(from categoryEvts: [Event]) -> Event? {
        if selectedCategory != nil {
            return categoryEvts.first
        }
        return store.featuredEvent ?? categoryEvts.first
    }

    private func trendingEvents(from categoryEvts: [Event]) -> [Event] {
        let filteredTrending = store.trendingEvents.filter { selectedCategory == nil || $0.category == selectedCategory }
        if !filteredTrending.isEmpty {
            return Array(filteredTrending.prefix(5))
        }
        return Array(categoryEvts.prefix(5))
    }

    private func displayedRecentEvents(from categoryEvts: [Event]) -> [Event] {
        let recentMatches = store.recentlyViewedEvents.filter {
            selectedCategory == nil || $0.category == selectedCategory
        }
        let base = recentMatches.isEmpty ? Array(categoryEvts.dropFirst(2)) : recentMatches
        return Array(base.prefix(8))
    }

    private func popularTonight(from categoryEvts: [Event], featured: Event?) -> [Event] {
        Array(
            categoryEvts
                .filter { $0.id != featured?.id }
                .sorted { $0.date < $1.date }
                .prefix(8)
        )
    }

    private func popularThisWeekend(from categoryEvts: [Event], featured: Event?) -> [Event] {
        Array(
            categoryEvts
                .filter { $0.id != featured?.id }
                .sorted { store.minPrice(for: $0) < store.minPrice(for: $1) }
                .prefix(8)
        )
    }

    private func justAnnouncedEvents(from categoryEvts: [Event]) -> [Event] {
        let titles: Set<String> = [
            "Taylor Swift | The Eras Tour",
            "Dave Chappelle",
            "Ali Wong",
            "Bad Bunny",
            "Drake",
            "Billie Eilish",
            "Kendrick Lamar",
            "SZA",
            "Doja Cat",
            "Post Malone"
        ]
        return Array(categoryEvts.filter { titles.contains($0.title) }.prefix(8))
    }

    // MARK: - Subviews

    private var browseHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.settings.selectedCity)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                Text("All dates")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }

            Spacer()

            Button {
                showBrowseSettings = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(MockSeatGeekTheme.surface)
                            .shadow(color: MockSeatGeekTheme.shadow, radius: 6, x: 0, y: 2)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
    }

    private var categoryRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(EventCategory.allCases) { category in
                    CategoryChip(label: category.rawValue, isSelected: selectedCategory == category) {
                        if selectedCategory == category {
                            selectedCategory = nil
                        } else {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    @ViewBuilder
    private func trendingSection(events: [Event]) -> some View {
        VStack(spacing: 0) {
            SectionHeaderView(
                title: "Trending events for you",
                actionTitle: "View all",
                destination: EventCollectionView(
                    title: "Trending events for you",
                    events: events
                )
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 4)

            Divider()
                .padding(.horizontal, 18)

            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                NavigationLink(value: event.id) {
                    TrendingEventRow(rank: index + 1, event: event)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index != events.count - 1 {
                    Divider()
                        .padding(.leading, 80)
                }
            }
        }
    }

    @ViewBuilder
    private func horizontalCardSection(title: String, events: [Event]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal, 18)

            SectionHeaderView(
                title: title,
                actionTitle: "View all",
                destination: EventCollectionView(
                    title: title,
                    events: events
                )
            )
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(events) { event in
                        NavigationLink(value: event.id) {
                            BrowseEventCard(event: event)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

// MARK: - Featured Event Card

struct FeaturedEventCard: View {
    @Environment(MockTicketBoxStore.self) private var store
    let event: Event

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            EventArtworkView(event: event)
                .frame(height: 240)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("FEATURED")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(MockSeatGeekTheme.accent)
                        )

                    if let topScore = event.listings.map(\.dealScore).max(), topScore >= 88 {
                        TicketBoxPickBadge()
                    }

                    Spacer()

                    if let topScore = event.listings.map(\.dealScore).max() {
                        DealScoreView(score: topScore, size: 40)
                    }
                }

                Spacer()

                if let listing = store.minListing(for: event) {
                    Text(Formatters.price(listing.price))
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(MockSeatGeekTheme.green)
                        )
                }

                Text(event.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text("\(Formatters.compactMonthDay(event.date)) · \(store.venue(for: event.venueID)?.name ?? event.city)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 18)
    }
}

// MARK: - Browse Event Card (horizontal carousel)

struct BrowseEventCard: View {
    @Environment(MockTicketBoxStore.self) private var store
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                EventArtworkView(event: event)
                    .frame(width: 170, height: 130)

                // Favorite heart button
                Button {
                    store.toggleFavoriteEvent(event.id)
                } label: {
                    Image(systemName: store.favoriteEventIDs.contains(event.id) ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.25))
                        )
                }
                .buttonStyle(.plain)
                .padding(8)

                // Price badge
                VStack {
                    Spacer()
                    HStack {
                        Text("\(Formatters.price(store.minPrice(for: event)))+")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(MockSeatGeekTheme.green.opacity(0.92))
                            )
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(width: 170, height: 130)

            Text(event.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            let venueName = store.venue(for: event.venueID)?.name ?? event.city
            Text("\(Formatters.compactMonthDay(event.date)) · \(venueName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 170, alignment: .leading)
    }
}

// MARK: - Trending Event Row

struct TrendingEventRow: View {
    @Environment(MockTicketBoxStore.self) private var store
    let rank: Int
    let event: Event

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MockSeatGeekTheme.accent.opacity(0.08))
                    .frame(width: 48, height: 48)
                Text("\(rank)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.accent)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .lineLimit(2)

                let venueName = store.venue(for: event.venueID)?.name ?? event.city
                (
                    Text("\(Formatters.price(store.minPrice(for: event)))+")
                        .foregroundStyle(MockSeatGeekTheme.green)
                    + Text(" · \(Formatters.seatGeekEventSubtitle(event.date, venue: venueName))")
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                )
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Event Collection

struct EventCollectionView: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let title: String
    let subtitle: String?
    let events: [Event]

    init(title: String, subtitle: String? = nil, events: [Event]) {
        self.title = title
        self.subtitle = subtitle
        self.events = events
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(MockSeatGeekTheme.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        .padding(.horizontal, 18)
                }

                if events.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        Text("Stay tuned for upcoming events")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    VStack(spacing: 0) {
                        ForEach(events) { event in
                            NavigationLink(value: event.id) {
                                CompactEventRow(event: event)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

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
            .padding(.bottom, 28)
        }
        .background(MockSeatGeekTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { eventID in
            if let event = store.event(for: eventID) {
                EventDetailView(event: event)
            }
        }
    }
}

// MARK: - Compact Event Row

struct CompactEventRow: View {
    @Environment(MockTicketBoxStore.self) private var store
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            EventArtworkView(event: event)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .lineLimit(2)

                let venueName = store.venue(for: event.venueID)?.name ?? event.city
                Text("\(Formatters.browseHeaderDate(event.date)) · \(venueName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(Formatters.price(store.minPrice(for: event)))+")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MockSeatGeekTheme.green)

                    if let topScore = event.listings.map(\.dealScore).max() {
                        DealScoreView(score: topScore, size: 24)

                        if topScore >= 90 {
                            TicketBoxPickBadge()
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MockSeatGeekTheme.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Section Header

struct SectionHeaderView<Destination: View>: View {
    let title: String
    let actionTitle: String
    let destination: Destination

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)

            Spacer()

            NavigationLink {
                destination
            } label: {
                HStack(spacing: 8) {
                    Text(actionTitle)
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : MockSeatGeekTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? MockSeatGeekTheme.accentDark : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? Color.clear : MockSeatGeekTheme.border, lineWidth: 1.4)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Browse Settings Sheet

struct BrowseSettingsSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: EventCategory?

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("City", selection: Binding(
                        get: { store.settings.selectedCity },
                        set: { store.updateLocation($0) }
                    )) {
                        ForEach(store.cities, id: \.self) { city in
                            Text(city).tag(city)
                        }
                    }
                }

                Section("Sort deals by") {
                    Picker("Sort", selection: Binding(
                        get: { store.settings.preferredSort },
                        set: { store.updatePreferredSort($0) }
                    )) {
                        ForEach(SortOption.allCases) { sortOption in
                            Text(sortOption.shortLabel).tag(sortOption)
                        }
                    }
                }

                Section("Featured category") {
                    Picker("Category", selection: Binding(
                        get: { selectedCategory },
                        set: { selectedCategory = $0 }
                    )) {
                        Text("All").tag(Optional<EventCategory>.none)
                        ForEach(EventCategory.allCases) { category in
                            Text(category.rawValue).tag(Optional(category))
                        }
                    }
                }
            }
            .navigationTitle("Browse")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
