import SwiftUI

struct RoutesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedFilter: RouteFilter = .all
    @State private var selectedSport: MapsSport = .run
    @State private var selectedSort: MapsSort = .recommended
    @State private var searchText = ""
    @State private var highlightedRouteId: String?
    @State private var showLabels = false
    @State private var showThreeDimensionalMap = false
    @State private var showingCreateRouteSheet = false
    @State private var createRouteName = ""
    @State private var mapResetTrigger = 0
    @State private var sheetRestingOffset: CGFloat = 0
    @GestureState private var sheetDragOffset: CGFloat = 0

    private let maxSheetLift: CGFloat = 132

    private var viewModel: RoutesViewModel {
        RoutesViewModel(appState: appState)
    }

    private var routes: [Route] {
        let baseRoutes = viewModel.routes(filter: selectedFilter)
            .filter { route in
                guard let activityType = selectedSport.activityType else { return true }
                return route.recommendedActivityType == activityType
            }
            .filter { route in
                searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    route.name.localizedCaseInsensitiveContains(searchText) ||
                    route.startLocation.localizedCaseInsensitiveContains(searchText)
            }

        switch selectedSort {
        case .recommended:
            return baseRoutes.sorted { $0.popularityScore > $1.popularityScore }
        case .length:
            return baseRoutes.sorted { $0.distanceKilometers > $1.distanceKilometers }
        case .elevation:
            return baseRoutes.sorted { $0.elevationGainMeters > $1.elevationGainMeters }
        case .surface:
            return baseRoutes.sorted { surfaceRatio(for: $0) > surfaceRatio(for: $1) }
        case .difficulty:
            return baseRoutes.sorted { difficultyScore(for: $0) > difficultyScore(for: $1) }
        }
    }

    private var selectedRoute: Route? {
        routes.first(where: { $0.id == highlightedRouteId }) ?? routes.first
    }

    var body: some View {
        GeometryReader { proxy in
            let bottomSheetPadding = proxy.safeAreaInsets.bottom + 72
            let sheetOffset = max(-maxSheetLift, min(0, sheetRestingOffset + sheetDragOffset))

            ZStack {
                MapPlaceholderView(
                    points: selectedRoute?.points ?? [],
                    routes: routes,
                    highlightedRouteId: selectedRoute?.id,
                    height: proxy.size.height + proxy.safeAreaInsets.top + 120,
                    style: .fullScreen,
                    showCurrentLocation: true,
                    showLabels: showLabels,
                    isThreeDimensional: showThreeDimensionalMap,
                    allowsInteraction: true,
                    recenterTrigger: mapResetTrigger
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    topSearchRow
                    filterChips
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, proxy.safeAreaInsets.top + 8)

                trailingMapControls
                    .padding(.trailing, 18)
                    .padding(.bottom, bottomSheetPadding + 176)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                createRouteButton
                    .padding(.trailing, 18)
                    .padding(.bottom, bottomSheetPadding + 132)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                bottomSheet
                    .offset(y: sheetOffset)
                    .padding(.horizontal, 12)
                    .padding(.bottom, bottomSheetPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: sheetRestingOffset)
        .onAppear {
            if highlightedRouteId == nil {
                highlightedRouteId = routes.first?.id
            }
        }
        .onChange(of: selectedFilter) { _, _ in syncHighlightedRoute() }
        .onChange(of: selectedSport) { _, _ in syncHighlightedRoute() }
        .onChange(of: selectedSort) { _, _ in syncHighlightedRoute() }
        .onChange(of: searchText) { _, _ in syncHighlightedRoute() }
        .sheet(isPresented: $showingCreateRouteSheet) {
            NavigationStack {
                Form {
                    Section("Route Name") {
                        TextField("Evening Loop", text: $createRouteName)
                    }

                    if let selectedRoute {
                        Section("Template") {
                            Text(selectedRoute.name)
                            Text(selectedRoute.startLocation)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.background.ignoresSafeArea())
                .navigationTitle("Create Route")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingCreateRouteSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let fallbackName = createRouteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? "\(selectedSport.title) Route"
                                : createRouteName
                            if let route = appState.createRoute(
                                title: fallbackName,
                                basedOn: selectedRoute?.id,
                                activityType: selectedSport.activityType ?? selectedRoute?.recommendedActivityType ?? .run
                            ) {
                                selectedFilter = .saved
                                highlightedRouteId = route.id
                            }
                            showingCreateRouteSheet = false
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.medium])
        }
    }

    private var topSearchRow: some View {
        HStack(spacing: 8) {
            Button {
                selectedSport = selectedSport.next
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedSport.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Capsule().fill(.black.opacity(0.94)))
                .overlay(Capsule().stroke(AppTheme.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)

            TrailBlazeInsetTextField(title: "Search locations", text: $searchText)
                .frame(maxWidth: .infinity)

            Button {
                selectedFilter = selectedFilter == .saved ? .all : .saved
                syncHighlightedRoute()
            } label: {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Saved")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Image(systemName: "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Capsule().fill(.black.opacity(0.94)))
                .overlay(Capsule().stroke(AppTheme.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: selectedFilter == .saved ? "Saved Routes" : selectedFilter == .bookmarked ? "Bookmarked" : "Routes", isSelected: true) {
                    selectedFilter = nextFilter(after: selectedFilter)
                    syncHighlightedRoute()
                }
                chip(title: "Length", isSelected: selectedSort == .length) {
                    selectedSort = .length
                }
                chip(title: "Elevation", isSelected: selectedSort == .elevation) {
                    selectedSort = .elevation
                }
                chip(title: "Surface", isSelected: selectedSort == .surface) {
                    selectedSort = .surface
                }
                chip(title: "Difficulty", isSelected: selectedSort == .difficulty) {
                    selectedSort = .difficulty
                }
            }
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        TrailBlazeChip(title: title, isSelected: isSelected, action: action)
    }

    private var trailingMapControls: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Button {
                    showLabels.toggle()
                } label: {
                    TrailBlazeIconButton(
                        systemImage: "square.3.layers.3d",
                        filled: true,
                        background: showLabels ? AppTheme.accent.opacity(0.9) : .black.opacity(0.9),
                        foreground: showLabels ? .black : .white,
                        size: 44
                    )
                }
                .buttonStyle(.plain)

                Text("3")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.white))
                    .offset(x: 6, y: -6)
            }

            Button {
                showThreeDimensionalMap.toggle()
            } label: {
                Text("3D")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(showThreeDimensionalMap ? .black : .white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(showThreeDimensionalMap ? AppTheme.accent : .black.opacity(0.9)))
            }
            .buttonStyle(.plain)

            Button {
                searchText = ""
                selectedFilter = .all
                selectedSort = .recommended
                showLabels = false
                highlightedRouteId = routes.first?.id
                mapResetTrigger += 1
                appState.transientMessage = "Centered on San Francisco routes."
            } label: {
                TrailBlazeIconButton(systemImage: "location", filled: true, background: .black.opacity(0.9), size: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var createRouteButton: some View {
        Button {
            createRouteName = selectedRoute.map { "\($0.name) Remix" } ?? "\(selectedSport.title) Route"
            showingCreateRouteSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .bold))
                Text("Create Route")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(.black.opacity(0.92)))
        }
        .buttonStyle(.plain)
    }

    private var bottomSheet: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(.white.opacity(0.28))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            if let route = selectedRoute {
                NavigationLink(destination: RouteDetailView(routeId: route.id)) {
                    MapsRouteCardView(
                        route: route,
                        surfaceRatio: surfaceRatio(for: route),
                        difficulty: difficultyLabel(for: route)
                    )
                }
                .buttonStyle(.plain)
            } else {
                EmptyStateView(
                    title: "No routes available",
                    subtitle: "Adjust your filters or switch data modes to repopulate the map.",
                    systemImage: "map",
                    identifier: selectedFilter == .saved ? AccessibilityID.routesEmptySavedState : "routes_empty_state"
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.09).opacity(0.98))
        )
        .simultaneousGesture(sheetDragGesture)
    }

    private func syncHighlightedRoute() {
        highlightedRouteId = routes.first?.id
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .updating($sheetDragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let proposedOffset = max(-maxSheetLift, min(0, sheetRestingOffset + value.translation.height))
                sheetRestingOffset = proposedOffset < (-maxSheetLift * 0.45) ? -maxSheetLift : 0
            }
    }

    private func nextFilter(after filter: RouteFilter) -> RouteFilter {
        switch filter {
        case .all: return .saved
        case .saved: return .bookmarked
        case .bookmarked: return .all
        }
    }

    private func difficultyScore(for route: Route) -> Double {
        route.distanceKilometers * 0.7 + route.elevationGainMeters * 0.03
    }

    private func difficultyLabel(for route: Route) -> String {
        let score = difficultyScore(for: route)
        switch score {
        case ..<12: return "Easy"
        case ..<22: return "Moderate"
        default: return "Hard"
        }
    }

    private func surfaceRatio(for route: Route) -> Int {
        min(98, max(68, Int(Double(route.popularityScore) * 0.92)))
    }
}

struct RouteDetailView: View {
    @EnvironmentObject private var appState: AppState

    let routeId: String

    private var viewModel: RouteDetailViewModel {
        RouteDetailViewModel(appState: appState, routeId: routeId)
    }

    var body: some View {
        ScrollView {
            if let route = viewModel.route {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeaderView(route.name, subtitle: route.startLocation)

                    MapPlaceholderView(points: route.points, routes: [route], highlightedRouteId: route.id, height: 250)
                    ElevationProfileView(values: route.elevationProfile, height: 150)

                    MetricGridView(
                        items: [
                            MetricItem(label: "Distance", value: AppFormatters.distance(route.distanceKilometers)),
                            MetricItem(label: "Elev Gain", value: AppFormatters.elevation(route.elevationGainMeters)),
                            MetricItem(label: "Est. Time", value: AppFormatters.duration(route.estimatedTimeSeconds)),
                            MetricItem(label: "Popularity", value: AppFormatters.integer(route.popularityScore))
                        ]
                    )

                    HStack(spacing: 12) {
                        Button(route.isSaved ? "Unsave Route" : "Save Route") {
                            appState.toggleRouteSaved(route.id)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                        .accessibilityIdentifier(AccessibilityID.routeSaveButton(route.id))

                        Button(route.isBookmarked ? "Remove Bookmark" : "Bookmark") {
                            appState.toggleRouteBookmarked(route.id)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .accessibilityIdentifier(AccessibilityID.routeBookmarkButton(route.id))
                    }

                    Button("Start Activity Using Route") {
                        appState.startActivity(using: route.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                    .accessibilityIdentifier(AccessibilityID.routeStartButton(route.id))

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderView("Segments Along Route")
                        if viewModel.segments.isEmpty {
                            Text("No competitive segments mapped on this route.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        } else {
                            ForEach(viewModel.segments) { segment in
                                NavigationLink(destination: SegmentDetailView(segmentId: segment.id)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(segment.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white)
                                            Text("\(AppFormatters.distance(segment.distanceKilometers)) • \(AppFormatters.decimal(segment.gradePercent))% grade")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                        Spacer()
                                        Text("Leaderboard")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(AppTheme.backgroundMuted)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier(AccessibilityID.segmentRow(segment.id))
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Route")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum MapsSport: CaseIterable {
    case run
    case ride
    case swim
    case walk
    case hike

    var title: String {
        switch self {
        case .run: return "Run"
        case .ride: return "Ride"
        case .swim: return "Swim"
        case .walk: return "Walk"
        case .hike: return "Hike"
        }
    }

    var systemImage: String {
        switch self {
        case .run: return "figure.run"
        case .ride: return "bicycle"
        case .swim: return "figure.pool.swim"
        case .walk: return "figure.walk"
        case .hike: return "figure.hiking"
        }
    }

    var activityType: ActivityType? {
        switch self {
        case .run: return .run
        case .ride: return .ride
        case .swim: return nil
        case .walk: return .walk
        case .hike: return .hike
        }
    }

    var next: MapsSport {
        let allCases = Self.allCases
        guard let index = allCases.firstIndex(of: self) else { return .run }
        return allCases[(index + 1) % allCases.count]
    }
}

private enum MapsSort {
    case recommended
    case length
    case elevation
    case surface
    case difficulty
}

private struct MapsRouteCardView: View {
    let route: Route
    let surfaceRatio: Int
    let difficulty: String

    var body: some View {
        HStack(spacing: 12) {
            RouteArtworkThumbnailView(route: route)
                .frame(width: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text(route.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(difficulty)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(difficulty == "Easy" ? AppTheme.success : difficulty == "Moderate" ? Color.yellow : Color.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(difficulty == "Easy" ? AppTheme.success.opacity(0.15) : Color.white.opacity(0.08))
                        )
                    Text("\(AppFormatters.distance(route.distanceKilometers)) · \(AppFormatters.elevation(route.elevationGainMeters))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Label(route.startLocation, systemImage: "scope")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 11))
                    Text("Made for you")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(AppTheme.accent)

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(AppTheme.accent)
                        .frame(width: 28, height: 6)
                    Text("\(surfaceRatio)% Paved")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }
}

private struct RouteArtworkThumbnailView: View {
    let route: Route

    private var skyColors: [Color] {
        switch route.recommendedActivityType {
        case .ride, .indoorRide:
            return [Color(red: 0.39, green: 0.48, blue: 0.83), Color(red: 0.15, green: 0.18, blue: 0.35)]
        case .walk, .hike:
            return [Color(red: 0.48, green: 0.61, blue: 0.53), Color(red: 0.17, green: 0.23, blue: 0.19)]
        case .run:
            return [Color(red: 0.72, green: 0.76, blue: 0.88), Color(red: 0.28, green: 0.34, blue: 0.48)]
        }
    }

    private var routeLineColor: Color {
        switch route.recommendedActivityType {
        case .ride, .indoorRide:
            return AppTheme.accent
        case .walk, .hike:
            return Color(red: 0.84, green: 0.88, blue: 0.78)
        case .run:
            return .white
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: skyColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 80, height: 80)
                .offset(x: 20, y: -14)

            RouteArtworkHillShape(offset: 0)
                .fill(Color.black.opacity(0.24))
            RouteArtworkHillShape(offset: 20)
                .fill(Color.black.opacity(0.36))

            Path { path in
                path.move(to: CGPoint(x: 14, y: 95))
                path.addCurve(
                    to: CGPoint(x: 106, y: 18),
                    control1: CGPoint(x: 28, y: 78),
                    control2: CGPoint(x: 80, y: 30)
                )
            }
            .stroke(routeLineColor.opacity(0.28), style: StrokeStyle(lineWidth: 10, lineCap: .round))

            Path { path in
                path.move(to: CGPoint(x: 14, y: 95))
                path.addCurve(
                    to: CGPoint(x: 106, y: 18),
                    control1: CGPoint(x: 28, y: 78),
                    control2: CGPoint(x: 80, y: 30)
                )
            }
            .stroke(routeLineColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))

            VStack(alignment: .leading, spacing: 4) {
                Spacer()

                Label(route.recommendedActivityType.title, systemImage: route.recommendedActivityType.systemImage)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.55))
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct RouteArtworkHillShape: Shape {
    let offset: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.height * 0.72))
            path.addCurve(
                to: CGPoint(x: rect.width * 0.48, y: rect.height * 0.40 + offset * 0.08),
                control1: CGPoint(x: rect.width * 0.10, y: rect.height * 0.56 + offset * 0.04),
                control2: CGPoint(x: rect.width * 0.28, y: rect.height * 0.28 + offset * 0.08)
            )
            path.addCurve(
                to: CGPoint(x: rect.width, y: rect.height * 0.78),
                control1: CGPoint(x: rect.width * 0.66, y: rect.height * 0.56),
                control2: CGPoint(x: rect.width * 0.84, y: rect.height * 0.64)
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
