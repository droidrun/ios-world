import SwiftUI

private enum ListingSortOption {
    case lowestPrice
    case dealScore
    case recommended
}

struct EventDetailView: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var selectedListing: TicketListing?
    @State private var quantityFilter = 1
    @State private var showPerksOnly = false
    @State private var showFiltersSheet = false
    @State private var showInfoSheet = false
    @State private var listingSort: ListingSortOption = .dealScore
    @State private var focusedListingID: UUID?
    @State private var showPriceAlertConfirmation = false

    var body: some View {
        let data = prepareListingData()
        let listings = data.listings
        let scores = data.scores
        let focusedListing = listings.first(where: { $0.id == focusedListingID }) ?? listings.first

        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 14) {
                    headerCapsule
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                    HStack(spacing: 12) {
                        BuyerGuaranteeBanner()

                        Button {
                            showPriceAlertConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bell.badge")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Price alerts")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(MockSeatGeekTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(MockSeatGeekTheme.accent.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(MockSeatGeekTheme.accent.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)

                    filterChips

                    ArenaSeatMapView(
                        event: event,
                        listings: listings,
                        selectedListingID: focusedListingID,
                        showFeesUpfront: store.settings.showFeesUpfront
                    ) { listing in
                        focusedListingID = listing.id
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            proxy.scrollTo(listing.id, anchor: .center)
                        }
                    }
                    .padding(.horizontal, 12)

                    if let focusedListing {
                        Button {
                            selectedListing = focusedListing
                        } label: {
                            SeatMapSelectionCard(
                                event: event,
                                listing: focusedListing,
                                venueName: store.venue(for: event.venueID)?.name ?? event.city,
                                bestSeatScore: scores[focusedListing.id] ?? 0,
                                showFeesUpfront: store.settings.showFeesUpfront
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                    }

                    VStack(spacing: 0) {
                        HStack {
                            Text("\(listings.count) Listings")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(MockSeatGeekTheme.textPrimary)

                            Spacer()

                            Menu {
                                Button("Sort by price") { listingSort = .lowestPrice }
                                Button("Deal Score") { listingSort = .dealScore }
                                Button("Recommended") { listingSort = .recommended }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text(sortLabel)
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                        ListingStatsStrip(
                            minimumPrice: listings.map(\.price).min() ?? 0,
                            topSeatScore: scores.values.max() ?? 0,
                            instantCount: listings.filter(\.isInstant).count
                        )
                        .padding(.horizontal, 18)
                        .padding(.bottom, 14)

                        Divider()

                        LazyVStack(spacing: 0) {
                            ForEach(listings) { listing in
                                Button {
                                    focusedListingID = listing.id
                                    selectedListing = listing
                                } label: {
                                    TicketListingRow(
                                        event: event,
                                        listing: listing,
                                        showFeesUpfront: store.settings.showFeesUpfront,
                                        isSelected: focusedListingID == listing.id,
                                        bestSeatScore: scores[listing.id] ?? 0
                                    )
                                }
                                .buttonStyle(.plain)
                                .id(listing.id)

                                if listing.id != listings.last?.id {
                                    Divider()
                                        .padding(.leading, 154)
                                }
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(MockSeatGeekTheme.surface)
                            .shadow(color: MockSeatGeekTheme.shadow, radius: 10, x: 0, y: -2)
                    )
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 28)
            }
            .onChange(of: focusedListingID) { _, newValue in
                guard let newValue else { return }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .background(Color(red: 0.92, green: 0.93, blue: 0.95).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $selectedListing) { listing in
            TicketPurchaseSheet(event: event, listing: listing)
                .environment(store)
        }
        .sheet(isPresented: $showFiltersSheet) {
            EventFiltersSheet(quantityFilter: $quantityFilter, showPerksOnly: $showPerksOnly)
        }
        .sheet(isPresented: $showInfoSheet) {
            EventInfoSheet(event: event)
                .environment(store)
        }
        .alert("Price Alert Set", isPresented: $showPriceAlertConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We'll notify you when prices drop for \(event.title).")
        }
        .onAppear {
            store.recordViewedEvent(event.id)
        }
        .onChange(of: quantityFilter) { _, _ in
            syncFocusedListing()
        }
        .onChange(of: showPerksOnly) { _, _ in
            syncFocusedListing()
        }
        .onChange(of: listingSort) { _, _ in
            syncFocusedListing()
        }
    }

    private var eligibleListings: [TicketListing] {
        event.listings
            .filter { $0.quantityAvailable >= quantityFilter }
            .filter { !showPerksOnly || $0.dealScore >= 90 }
    }


    private var sortLabel: String {
        switch listingSort {
        case .dealScore:
            return "Deal Score"
        case .recommended:
            return "Recommended"
        case .lowestPrice:
            return "Sort by price"
        }
    }


    private var headerCapsule: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .lineLimit(2)

                Text(headerSubtitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }

            Spacer()

            Divider()
                .frame(height: 52)

            ShareLink(
                item: event.title,
                subject: Text(event.title),
                message: Text("Check out \(event.title) on TicketBox!")
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Button {
                showInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(CardBackground(cornerRadius: 28))
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button {
                    showFiltersSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(MockSeatGeekTheme.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(chipBackground(selected: false))
                }
                .buttonStyle(.plain)

                Menu {
                    Button("1 ticket") { quantityFilter = 1 }
                    Button("2 tickets") { quantityFilter = 2 }
                    Button("4+ tickets") { quantityFilter = 4 }
                } label: {
                    Text(quantityLabel)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(height: 48)
                        .padding(.horizontal, 18)
                        .background(chipBackground(selected: true))
                }
                .buttonStyle(.plain)

                Button {
                    store.settings.showFeesUpfront.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Text("Price")
                        Text(store.settings.showFeesUpfront ? "Includes Fees" : "+ Fees")
                            .foregroundStyle(store.settings.showFeesUpfront ? MockSeatGeekTheme.textSecondary : MockSeatGeekTheme.accent)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .frame(height: 48)
                    .padding(.horizontal, 18)
                    .background(chipBackground(selected: false))
                }
                .buttonStyle(.plain)

                Button {
                    showPerksOnly.toggle()
                } label: {
                    Text("Perks")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(showPerksOnly ? .white : MockSeatGeekTheme.textPrimary)
                        .frame(height: 48)
                        .padding(.horizontal, 18)
                        .background(chipBackground(selected: showPerksOnly))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
        }
    }

    private func chipBackground(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(selected ? MockSeatGeekTheme.accentDark : MockSeatGeekTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(selected ? Color.clear : MockSeatGeekTheme.border, lineWidth: 1)
            )
            .shadow(color: MockSeatGeekTheme.shadow, radius: 8, x: 0, y: 4)
    }

    private var quantityLabel: String {
        switch quantityFilter {
        case 1:
            return "1 ticket"
        case 2:
            return "2 tickets"
        default:
            return "4+ tickets"
        }
    }

    private var headerSubtitle: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE, MMM d"

        let timeFormatter = DateFormatter()
        if store.settings.use24HourTime {
            timeFormatter.dateFormat = "HH:mm"
        } else {
            timeFormatter.dateFormat = Calendar.current.component(.minute, from: event.date) == 0 ? "ha" : "h:mma"
        }

        let timeText = store.settings.use24HourTime
            ? timeFormatter.string(from: event.date)
            : timeFormatter.string(from: event.date).lowercased()
        return "\(dayFormatter.string(from: event.date)) at \(timeText)"
    }

    private func prepareListingData() -> (listings: [TicketListing], scores: [UUID: Int]) {
        let eligible = eligibleListings
        let prices = eligible.map(\.price)
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice

        var scores: [UUID: Int] = [:]
        scores.reserveCapacity(eligible.count)

        for listing in eligible {
            let priceScore: Double = priceRange > 0
                ? max(0, min(1, (maxPrice - listing.price) / priceRange))
                : 1
            let proxScore = proximityScore(for: listing)
            let ratingScore = seatRating(for: listing)
            let composite = (priceScore * 0.35) + (proxScore * 0.35) + (ratingScore * 0.30)
            scores[listing.id] = Int((composite * 100).rounded())
        }

        let sortOption = listingSort
        let sorted = eligible.sorted { lhs, rhs in
            switch sortOption {
            case .dealScore:
                let leftScore = scores[lhs.id] ?? 0
                let rightScore = scores[rhs.id] ?? 0
                if leftScore == rightScore { return lhs.price < rhs.price }
                return leftScore > rightScore
            case .recommended:
                if lhs.dealScore == rhs.dealScore { return lhs.price < rhs.price }
                return lhs.dealScore > rhs.dealScore
            case .lowestPrice:
                if lhs.price == rhs.price { return lhs.dealScore > rhs.dealScore }
                return lhs.price < rhs.price
            }
        }

        return (sorted, scores)
    }

    private func proximityScore(for listing: TicketListing) -> Double {
        let ringScore: Double
        switch sectionRing(for: listing.section) {
        case 1:
            ringScore = 1.0
        case 2:
            ringScore = 0.72
        default:
            ringScore = 0.46
        }

        let rowDigits = listing.row.filter(\.isNumber)
        let rowScore: Double
        if let rowValue = Int(rowDigits), !rowDigits.isEmpty {
            rowScore = max(0.4, 1.0 - (Double(max(0, rowValue - 1)) / 24.0))
        } else {
            rowScore = 0.74
        }

        return (ringScore * 0.7) + (rowScore * 0.3)
    }

    private func seatRating(for listing: TicketListing) -> Double {
        switch listing.imageStyle {
        case .centerCourt, .floor, .orchestra:
            return 1.0
        case .clubLevel, .dugout, .behindPlate:
            return 0.9
        case .cornerView, .behindGoal:
            return 0.78
        case .sideStage, .balcony:
            return 0.66
        case .lawn, .generalAdmission:
            return 0.58
        }
    }

    private func sectionRing(for section: String) -> Int {
        let token = section.lowercased()

        switch event.category {
        case .sports:
            if token.contains("lb") || token.contains("vr") || token.hasPrefix("10") || token.hasPrefix("11") || token.hasPrefix("12") {
                return 1
            }
            if token.contains("bleachers") || token.hasPrefix("22") || token.hasPrefix("23") {
                return 3
            }
            return 2
        case .concerts:
            if token.contains("floor") || token.contains("pit") || token.contains("ga") {
                return 1
            }
            if token.contains("balcony") || token.contains("lawn") || token.hasPrefix("20") {
                return 3
            }
            return 2
        case .theater, .comedy:
            if token.contains("orchestra") || token.contains("front") {
                return 1
            }
            if token.contains("balcony") || token.contains("rear") || token.contains("ga") {
                return 3
            }
            return 2
        }
    }

    private func syncFocusedListing() {
        let eligible = eligibleListings
        if let focusedListingID,
           eligible.contains(where: { $0.id == focusedListingID }) {
            return
        }
        focusedListingID = eligible.first?.id
    }
}

private struct ArenaSeatMapView: View {
    let event: Event
    let listings: [TicketListing]
    let selectedListingID: UUID?
    let showFeesUpfront: Bool
    let onSelectListing: (TicketListing) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                mapShell(size: size)

                seatTicks(size: size, ring: 1, count: 34, width: 10)
                seatTicks(size: size, ring: 2, count: 42, width: 9)
                seatTicks(size: size, ring: 3, count: 50, width: 8)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .frame(width: centerSize(for: size).width, height: centerSize(for: size).height)
                    .overlay(centerAnchor)

                ForEach(positionedZones(in: size)) { zone in
                    Button {
                        onSelectListing(zone.primaryListing)
                    } label: {
                        SeatMapZoneView(
                            section: zone.section,
                            listingCount: zone.listingCount,
                            priceText: Formatters.priceDisplay(price: zone.primaryListing.price, fees: zone.primaryListing.fees, showFeesUpfront: showFeesUpfront),
                            dealTint: dealTint(for: zone.primaryListing.dealScore),
                            deliveryType: zone.primaryListing.deliveryType,
                            isSelected: zone.section == selectedSection
                        )
                    }
                    .buttonStyle(.plain)
                    .position(zone.center)
                }
            }
        }
        .frame(height: mapHeight)
    }

    private var selectedSection: String? {
        listings.first(where: { $0.id == selectedListingID })?.section
    }

    private var mapHeight: CGFloat {
        switch event.category {
        case .sports:
            return 486
        case .concerts:
            return 458
        case .theater, .comedy:
            return 430
        }
    }

    private func positionedZones(in size: CGSize) -> [SeatMapZoneLayout] {
        let grouped = Dictionary(grouping: listings, by: \.section)
        let zones = grouped.map { section, listings -> SeatMapZoneLayoutSeed in
            let sortedListings = listings.sorted { lhs, rhs in
                if lhs.price == rhs.price {
                    return lhs.dealScore > rhs.dealScore
                }
                return lhs.price < rhs.price
            }

            return SeatMapZoneLayoutSeed(
                section: section,
                listingCount: listings.count,
                primaryListing: sortedListings[0],
                ring: sectionRing(for: section),
                orderKey: sectionOrderKey(for: section)
            )
        }

        let groupedByRing = Dictionary(grouping: zones, by: \.ring)
        var layouts: [SeatMapZoneLayout] = []

        for ring in groupedByRing.keys.sorted() {
            let zonesForRing = groupedByRing[ring, default: []].sorted { lhs, rhs in
                lhs.orderKey < rhs.orderKey
            }
            let angleRange = angleRange(for: ring)
            let radius = radii(for: ring, size: size)

            for (index, zone) in zonesForRing.enumerated() {
                let angle = interpolatedAngle(index: index, count: zonesForRing.count, range: angleRange)
                let radians = angle * .pi / 180
                let cosine = CGFloat(Darwin.cos(radians))
                let sine = CGFloat(Darwin.sin(radians))
                let center = CGPoint(
                    x: (size.width / 2) + (cosine * radius.x),
                    y: (size.height / 2) + (sine * radius.y)
                )

                layouts.append(
                    SeatMapZoneLayout(
                        section: zone.section,
                        listingCount: zone.listingCount,
                        primaryListing: zone.primaryListing,
                        center: center
                    )
                )
            }
        }

        return layouts
    }

    private func mapShell(size: CGSize) -> some View {
        ZStack {
            Ellipse()
                .fill(Color.white.opacity(0.64))
                .overlay(
                    Ellipse()
                        .stroke(Color.black.opacity(0.16), lineWidth: 5)
                )
                .padding(22)

            Ellipse()
                .fill(Color.black.opacity(0.02))
                .padding(44)

            Ellipse()
                .stroke(Color.black.opacity(0.12), lineWidth: 2)
                .padding(44)

            Ellipse()
                .stroke(Color.black.opacity(0.09), lineWidth: 1.5)
                .padding(74)

            Ellipse()
                .stroke(Color.black.opacity(0.06), lineWidth: 1.5)
                .padding(108)

            ForEach(0..<12, id: \.self) { index in
                seatAisle(size: size, index: index)
            }
        }
    }

    private func seatTicks(size: CGSize, ring: Int, count: Int, width: CGFloat) -> some View {
        ForEach(0..<count, id: \.self) { index in
            let angleRange = angleRange(for: ring)
            let angle = interpolatedAngle(index: index, count: count, range: angleRange)
            let radians = angle * .pi / 180
            let radius = radii(for: ring, size: size)
            let cosine = CGFloat(Darwin.cos(radians))
            let sine = CGFloat(Darwin.sin(radians))

            Capsule()
                .fill(Color.black.opacity(ring == 1 ? 0.12 : 0.08))
                .frame(width: width, height: 2)
                .rotationEffect(.degrees(angle + 90))
                .position(
                    x: (size.width / 2) + (cosine * radius.x),
                    y: (size.height / 2) + (sine * radius.y)
                )
        }
    }

    private func seatAisle(size: CGSize, index: Int) -> some View {
        let angleRange = angleRange(for: 3)
        let angle = interpolatedAngle(index: index, count: 12, range: angleRange)
        let radians = angle * .pi / 180
        let inner = centerSize(for: size)
        let outer = CGSize(width: size.width * 0.46, height: size.height * 0.35)
        let cosine = CGFloat(Darwin.cos(radians))
        let sine = CGFloat(Darwin.sin(radians))
        let startPoint = CGPoint(
            x: (size.width / 2) + (cosine * (inner.width * 0.58)),
            y: (size.height / 2) + (sine * (inner.height * 0.58))
        )
        let endPoint = CGPoint(
            x: (size.width / 2) + (cosine * outer.width),
            y: (size.height / 2) + (sine * outer.height)
        )

        return Path { path in
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        .stroke(Color.black.opacity(0.07), lineWidth: 1)
    }

    private func centerSize(for size: CGSize) -> CGSize {
        switch event.category {
        case .sports:
            return CGSize(width: size.width * 0.34, height: size.height * 0.31)
        case .concerts:
            return CGSize(width: size.width * 0.32, height: size.height * 0.26)
        case .theater, .comedy:
            return CGSize(width: size.width * 0.36, height: size.height * 0.38)
        }
    }

    private func sectionRing(for section: String) -> Int {
        let token = section.lowercased()

        switch event.category {
        case .sports:
            if token.contains("lb") || token.contains("vr") || token.hasPrefix("10") || token.hasPrefix("11") || token.hasPrefix("12") {
                return 1
            }
            if token.contains("bleachers") || token.hasPrefix("22") || token.hasPrefix("23") {
                return 3
            }
            return 2
        case .concerts:
            if token.contains("floor") || token.contains("pit") || token.contains("ga") {
                return 1
            }
            if token.contains("balcony") || token.contains("lawn") || token.hasPrefix("20") {
                return 3
            }
            return 2
        case .theater, .comedy:
            if token.contains("orchestra") || token.contains("front") {
                return 1
            }
            if token.contains("balcony") || token.contains("rear") || token.contains("ga") {
                return 3
            }
            return 2
        }
    }

    private func sectionOrderKey(for section: String) -> Int {
        let digits = section.filter(\.isNumber)
        if let value = Int(digits), !digits.isEmpty {
            return value
        }

        switch section.lowercased() {
        case let value where value.contains("floor"):
            return 10
        case let value where value.contains("pit"):
            return 20
        case let value where value.contains("orchestra"):
            return 30
        case let value where value.contains("front"):
            return 40
        case let value where value.contains("center"):
            return 50
        case let value where value.contains("side"):
            return 60
        case let value where value.contains("balcony"):
            return 80
        case let value where value.contains("ga"):
            return 90
        default:
            return 999
        }
    }

    private func angleRange(for ring: Int) -> ClosedRange<Double> {
        switch event.category {
        case .sports:
            return 200...520
        case .concerts:
            return ring == 1 ? 210...330 : 150...390
        case .theater, .comedy:
            return ring == 1 ? 210...330 : 160...380
        }
    }

    private func radii(for ring: Int, size: CGSize) -> CGPoint {
        switch event.category {
        case .sports:
            switch ring {
            case 1:
                return CGPoint(x: size.width * 0.24, y: size.height * 0.17)
            case 2:
                return CGPoint(x: size.width * 0.35, y: size.height * 0.26)
            default:
                return CGPoint(x: size.width * 0.46, y: size.height * 0.34)
            }
        case .concerts:
            switch ring {
            case 1:
                return CGPoint(x: size.width * 0.22, y: size.height * 0.15)
            case 2:
                return CGPoint(x: size.width * 0.34, y: size.height * 0.24)
            default:
                return CGPoint(x: size.width * 0.44, y: size.height * 0.31)
            }
        case .theater, .comedy:
            switch ring {
            case 1:
                return CGPoint(x: size.width * 0.2, y: size.height * 0.15)
            case 2:
                return CGPoint(x: size.width * 0.31, y: size.height * 0.24)
            default:
                return CGPoint(x: size.width * 0.42, y: size.height * 0.32)
            }
        }
    }

    private func interpolatedAngle(index: Int, count: Int, range: ClosedRange<Double>) -> Double {
        guard count > 1 else { return (range.lowerBound + range.upperBound) / 2 }
        let step = (range.upperBound - range.lowerBound) / Double(count - 1)
        return range.lowerBound + (Double(index) * step)
    }

    private func dealTint(for dealScore: Int) -> Color {
        if dealScore >= 95 { return MockSeatGeekTheme.green }
        if dealScore >= 88 { return MockSeatGeekTheme.blue }
        return MockSeatGeekTheme.accent
    }

    @ViewBuilder
    private var centerAnchor: some View {
        switch event.category {
        case .sports:
            if event.title.lowercased().contains("giants") || event.title.lowercased().contains("yankees") || event.title.lowercased().contains("pirates") {
                baseballField
            } else {
                iceRink
            }
        case .concerts:
            concertStage
        case .theater, .comedy:
            theaterStage
        }
    }

    private var iceRink: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(red: 0.68, green: 0.72, blue: 0.8), lineWidth: 3)
                .padding(18)

            Rectangle()
                .fill(Color.red.opacity(0.9))
                .frame(width: 2, height: 124)

            Rectangle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 2, height: 124)
                .offset(x: -40)

            Rectangle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 2, height: 124)
                .offset(x: 40)

            Circle()
                .stroke(Color.red.opacity(0.55), lineWidth: 2)
                .frame(width: 48, height: 48)

            VStack {
                Circle().stroke(Color.red.opacity(0.55), lineWidth: 2).frame(width: 28, height: 28)
                Spacer()
                Circle().stroke(Color.red.opacity(0.55), lineWidth: 2).frame(width: 28, height: 28)
            }
            .padding(.vertical, 26)
            .offset(x: -54)

            VStack {
                Circle().stroke(Color.red.opacity(0.55), lineWidth: 2).frame(width: 28, height: 28)
                Spacer()
                Circle().stroke(Color.red.opacity(0.55), lineWidth: 2).frame(width: 28, height: 28)
            }
            .padding(.vertical, 26)
            .offset(x: 54)
        }
    }

    private var baseballField: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.26, green: 0.51, blue: 0.27))
                .padding(18)

            DiamondShape()
                .fill(Color(red: 0.79, green: 0.66, blue: 0.46))
                .frame(width: 72, height: 72)

            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 22, height: 22)
        }
    }

    private var concertStage: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.68))
                .frame(width: 92, height: 30)
                .padding(.top, 24)

            ForEach(0..<4, id: \.self) { _ in
                Capsule()
                    .fill(Color(red: 0.8, green: 0.38, blue: 0.54).opacity(0.38))
                    .frame(width: 98, height: 8)
            }

            Spacer()
        }
    }

    private var theaterStage: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.88, green: 0.69, blue: 0.23))
                .frame(width: 96, height: 22)
                .padding(.top, 24)

            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(Color.white.opacity(0.24))
                    .frame(width: 94, height: 9)
            }

            Spacer()
        }
    }

}

private struct SeatMapZoneLayoutSeed {
    let section: String
    let listingCount: Int
    let primaryListing: TicketListing
    let ring: Int
    let orderKey: Int
}

private struct SeatMapZoneLayout: Identifiable {
    let section: String
    let listingCount: Int
    let primaryListing: TicketListing
    let center: CGPoint

    var id: String { section }
}

private struct SeatMapZoneView: View {
    let section: String
    let listingCount: Int
    let priceText: String
    let dealTint: Color
    let deliveryType: DeliveryType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            PriceBubbleView(
                price: priceText,
                tint: dealTint,
                deliveryType: deliveryType,
                isSelected: isSelected
            )

            VStack(spacing: 2) {
                Text(section)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .lineLimit(1)
                Text("\(listingCount) rows")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }
            .frame(width: 60, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? MockSeatGeekTheme.accentSoft : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? MockSeatGeekTheme.accent.opacity(0.45) : Color.black.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

private struct PriceBubbleView: View {
    let price: String
    let tint: Color
    let deliveryType: DeliveryType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isSelected ? Color.white.opacity(0.92) : tint)
                .frame(width: 8, height: 8)

            Text(price)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isSelected ? .white : MockSeatGeekTheme.textPrimary)

            if deliveryType == .instant {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.86) : MockSeatGeekTheme.green)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? MockSeatGeekTheme.accentDark : MockSeatGeekTheme.surface)
                .shadow(color: MockSeatGeekTheme.shadow, radius: 6, x: 0, y: 3)
        )
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct SeatMapSelectionCard: View {
    let event: Event
    let listing: TicketListing
    let venueName: String
    let bestSeatScore: Int
    let showFeesUpfront: Bool

    var body: some View {
        HStack(spacing: 14) {
            ListingSeatArtworkView(style: listing.imageStyle, category: event.category, sectionLabel: "Section \(listing.section)")
                .frame(width: 88, height: 70)

            VStack(alignment: .leading, spacing: 5) {
                Text("Section \(listing.section) · Row \(listing.row)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                Text("\(venueName) · \(listing.quantityAvailable) listings nearby")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                Text(listing.viewDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(Formatters.priceDisplay(price: listing.price, fees: listing.fees, showFeesUpfront: showFeesUpfront))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                Text(showFeesUpfront ? "incl. fees" : "+ fees")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                Text(listing.isInstant ? "Instant" : listing.deliveryType.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MockSeatGeekTheme.green)
                DealScoreView(score: bestSeatScore, size: 32)
            }
        }
        .padding(14)
        .background(CardBackground(cornerRadius: 20))
    }
}

private struct ListingStatsStrip: View {
    let minimumPrice: Double
    let topSeatScore: Int
    let instantCount: Int

    var body: some View {
        HStack(spacing: 10) {
            ListingStatPill(title: "From", value: Formatters.price(minimumPrice), tint: MockSeatGeekTheme.green)
            ListingStatPill(title: "Deal Score", value: "\(topSeatScore)/100", tint: MockSeatGeekTheme.blue)
            ListingStatPill(title: "Instant", value: "\(instantCount)", tint: MockSeatGeekTheme.accent)
        }
    }
}

private struct ListingStatPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textTertiary)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MockSeatGeekTheme.surfaceMuted)
        )
    }
}

private struct TicketListingRow: View {
    let event: Event
    let listing: TicketListing
    let showFeesUpfront: Bool
    let isSelected: Bool
    let bestSeatScore: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ListingSeatArtworkView(style: listing.imageStyle, category: event.category, sectionLabel: "Section \(listing.section)")
                .frame(width: 92, height: 76)

            VStack(alignment: .leading, spacing: 6) {
                Text("Section \(listing.section) · Row \(listing.row)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)

                HStack(spacing: 8) {
                    Text("\(listing.seatRange) · up to \(listing.quantityAvailable) tickets")
                    Text(listing.deliveryType.rawValue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(MockSeatGeekTheme.surfaceMuted)
                        )
                }
                .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)

                Text(listing.viewDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    DealScoreView(score: bestSeatScore, size: 28)
                    Text("Deal Score")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(Formatters.priceDisplay(price: listing.price, fees: listing.fees, showFeesUpfront: showFeesUpfront))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)

                Text(showFeesUpfront ? "incl. fees" : "+ fees")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? MockSeatGeekTheme.accent.opacity(0.08) : Color.clear)
        )
    }
}

private struct TicketPurchaseSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let event: Event
    let listing: TicketListing

    @State private var quantity = 1
    @State private var order: Order?
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    @State private var showCardPicker = false
    @State private var promoCodeInput = ""
    @State private var promoMessage: String?

    private var preview: CheckoutPreview {
        let item = CartItem(
            id: UUID(),
            listingID: listing.id,
            eventID: event.id,
            eventTitle: event.title,
            venueName: store.venue(for: event.venueID)?.name ?? "TicketBox",
            city: event.city,
            eventDate: event.date,
            section: listing.section,
            row: listing.row,
            seatRange: listing.seatRange,
            quantityAvailable: listing.quantityAvailable,
            pricePerTicket: listing.price,
            feesPerTicket: listing.fees,
            deliveryType: listing.deliveryType,
            quantity: quantity
        )

        return store.checkoutPreview(for: [item])
    }

    var body: some View {
        NavigationStack {
            if let order {
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(MockSeatGeekTheme.accent)
                    Text("Tickets purchased")
                        .font(.system(size: 28, weight: .bold))
                    Text(order.orderNumber)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)

                    Button("Go to Tickets") {
                        store.selectedTab = .tickets
                        dismiss()
                    }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(MockSeatGeekTheme.accentDark)
                    )
                }
                .padding(24)
            } else if !showConfirmation {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        EventArtworkView(event: event)
                            .frame(height: 180)

                        Text(event.title)
                            .font(.system(size: 26, weight: .bold))

                        HStack(spacing: 14) {
                            ListingSeatArtworkView(style: listing.imageStyle, category: event.category, sectionLabel: "Section \(listing.section)")
                                .frame(width: 108, height: 86)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Section \(listing.section) · Row \(listing.row) · Seats \(listing.seatRange)")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                                Text(listing.viewDescription)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                                    .lineLimit(2)
                            }
                        }

                        Stepper("Quantity: \(quantity)", value: $quantity, in: 1...listing.quantityAvailable)
                            .font(.system(size: 19, weight: .medium))

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Price")
                                Spacer()
                                Text(Formatters.price(preview.subtotal))
                            }
                            HStack {
                                Text("Fees")
                                Spacer()
                                Text(Formatters.price(preview.fees))
                            }
                            if preview.discount > 0 {
                                HStack {
                                    Text(preview.appliedPromo?.code ?? "Promo code")
                                    Spacer()
                                    Text("-\(Formatters.price(preview.discount))")
                                        .foregroundStyle(MockSeatGeekTheme.green)
                                }
                            }
                            HStack {
                                Text("Total")
                                    .font(.system(size: 20, weight: .bold))
                                Spacer()
                                Text(Formatters.price(preview.total))
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .font(.system(size: 18, weight: .medium))
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(MockSeatGeekTheme.surfaceMuted)
                        )

                        // Promo code entry
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Promo code")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(MockSeatGeekTheme.textPrimary)

                            HStack(spacing: 10) {
                                TextField("Enter code", text: $promoCodeInput)
                                    .font(.system(size: 16, weight: .medium))
                                    .textInputAutocapitalization(.characters)
                                    .disableAutocorrection(true)
                                    .padding(.horizontal, 14)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(MockSeatGeekTheme.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(MockSeatGeekTheme.border, lineWidth: 1)
                                            )
                                    )

                                Button("Apply") {
                                    switch store.redeemPromoCode(promoCodeInput) {
                                    case .success(let promo):
                                        promoCodeInput = ""
                                        promoMessage = "\(promo.code) applied!"
                                    case .failure(let error):
                                        promoMessage = error.localizedDescription
                                    }
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(MockSeatGeekTheme.accent)
                                )
                                .disabled(promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            if let promoMessage {
                                Text(promoMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(promoMessage.contains("applied") ? MockSeatGeekTheme.green : MockSeatGeekTheme.accent)
                            }
                        }

                        // Payment method selector
                        Button {
                            showCardPicker = true
                        } label: {
                            HStack(spacing: 14) {
                                MasterCardMarkView()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.selectedPaymentAccount?.displayName ?? "No card selected")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(MockSeatGeekTheme.textPrimary)
                                    Text("Tap to change payment method")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(MockSeatGeekTheme.textTertiary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(MockSeatGeekTheme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(MockSeatGeekTheme.border, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)

                        BuyerGuaranteeBanner()

                        Button("Review order") {
                            showConfirmation = true
                        }
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(MockSeatGeekTheme.accent)
                        )
                    }
                    .padding(20)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Confirm your purchase")
                            .font(.system(size: 26, weight: .bold))

                        Text(event.title)
                            .font(.system(size: 20, weight: .semibold))

                        Text("Section \(listing.section) · Row \(listing.row) · Seats \(listing.seatRange)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MockSeatGeekTheme.textSecondary)

                        Text("\(quantity) ticket\(quantity > 1 ? "s" : "")")
                            .font(.system(size: 16))
                            .foregroundStyle(MockSeatGeekTheme.textSecondary)

                        Divider()

                        // Payment method with change option
                        Button {
                            showCardPicker = true
                        } label: {
                            HStack(spacing: 14) {
                                MasterCardMarkView()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.selectedPaymentAccount?.displayName ?? "No card selected")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(MockSeatGeekTheme.textPrimary)
                                    Text("Payment method")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                                }
                                Spacer()
                                Text("Change")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(MockSeatGeekTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)

                        Divider()

                        // Price breakdown
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(Formatters.price(preview.subtotal))
                            }
                            HStack {
                                Text("Fees")
                                Spacer()
                                Text(Formatters.price(preview.fees))
                            }
                            if preview.discount > 0 {
                                HStack {
                                    Text(preview.appliedPromo?.code ?? "Promo")
                                    Spacer()
                                    Text("-\(Formatters.price(preview.discount))")
                                        .foregroundStyle(MockSeatGeekTheme.green)
                                }
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)

                        HStack {
                            Text("Total")
                                .font(.system(size: 22, weight: .bold))
                            Spacer()
                            Text(Formatters.price(preview.total))
                                .font(.system(size: 22, weight: .bold))
                        }

                        Text("By confirming, you agree to TicketBox's terms and conditions. All sales are final.")
                            .font(.system(size: 14))
                            .foregroundStyle(MockSeatGeekTheme.textSecondary)

                        Button("Confirm purchase") {
                            switch store.purchase(listing: listing, event: event, quantity: quantity) {
                            case .success(let placedOrder):
                                order = placedOrder
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(MockSeatGeekTheme.accent)
                        )

                        Button("Go back") {
                            showConfirmation = false
                        }
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.accent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                }
                .alert("Unable to purchase", isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { newValue in
                        if !newValue { errorMessage = nil }
                    }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showCardPicker) {
            CheckoutCardPickerSheet()
                .environment(store)
        }
    }
}

private struct CheckoutCardPickerSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(store.paymentAccounts) { account in
                Button {
                    store.selectedPaymentAccountID = account.id
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        MasterCardMarkView()
                        VStack(alignment: .leading, spacing: 3) {
                            Text(account.displayName)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                            Text(account.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        }
                        Spacer()
                        if store.selectedPaymentAccountID == account.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(MockSeatGeekTheme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Payment method")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct EventFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var quantityFilter: Int
    @Binding var showPerksOnly: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Tickets") {
                    Stepper("Minimum tickets: \(quantityFilter)", value: $quantityFilter, in: 1...4)
                }

                Section("Perks") {
                    Toggle("Only show top deals", isOn: $showPerksOnly)
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
        .presentationDetents([.medium])
    }
}

private struct EventInfoSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    let event: Event

    var body: some View {
        NavigationStack {
            List {
                Section("Event") {
                    Text(event.title)
                    Text(Formatters.seatGeekListDate(event.date))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    Text(event.performers.map(\.name).joined(separator: ", "))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                }

                if let venue = store.venue(for: event.venueID) {
                    Section("Venue") {
                        Text(venue.name)
                        Text(venue.address)
                            .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        Text("\(venue.city) · Capacity \(venue.capacity)")
                            .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    }
                }

                Section("Inventory") {
                    LabeledContent("Listings", value: "\(event.listings.count)")
                    LabeledContent("Lowest price", value: Formatters.price(store.minPrice(for: event)))
                    LabeledContent("Instant transfer", value: "\(event.listings.filter(\.isInstant).count)")
                }

                Section("About") {
                    Text(event.description)
                }
            }
            .navigationTitle("Event Info")
        }
        .presentationDetents([.medium, .large])
    }
}
