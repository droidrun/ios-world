import SwiftUI
import MapKit

enum AppTheme {
    static let accent = Color(red: 0.98, green: 0.37, blue: 0.08)
    static let accentMuted = accent.opacity(0.16)
    static let background = Color.black
    static let backgroundRaised = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let backgroundMuted = Color(red: 0.16, green: 0.16, blue: 0.17)
    static let chrome = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let divider = Color.white.opacity(0.10)
    static let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let mapBase = Color(red: 0.12, green: 0.16, blue: 0.23)
    static let mapRoad = Color(red: 0.54, green: 0.64, blue: 0.97)
    static let mapRoadGlow = Color(red: 0.35, green: 0.46, blue: 0.98)
    static let textSecondary = Color.white.opacity(0.56)
    static let success = Color(red: 0.40, green: 0.78, blue: 0.20)
}

struct MetricItem: Identifiable {
    let id = UUID()
    var label: String
    var value: String
}

struct SectionHeaderView: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let identifier: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .accessibilityIdentifier(identifier)
    }
}

/// Deterministic, gender-aware face asset lookup (mirrored across the chat / social / fitness / payments clones,
/// — keep implementations in sync). See
/// `LockedIn/Utilities/LockedInTheme.swift` for documentation.
enum FaceAssetResolver {
    static let feminineSlots: [Int] = [
        1, 4, 5, 6, 7, 8, 9, 12, 14, 18, 24, 26, 28, 29, 32, 34, 37, 38, 41, 42,
        44, 48, 50, 51, 52, 56, 63, 65, 67, 69, 70, 72, 75, 78, 79, 80, 81, 84,
        85, 86, 88, 89, 91, 92, 93, 94
    ]
    static let masculineSlots: [Int] = [
        2, 3, 10, 11, 13, 15, 16, 17, 19, 20, 21, 22, 23, 25, 26, 27, 28, 30,
        31, 33, 35, 36, 39, 40, 43, 45, 46, 47, 49, 53, 54, 55, 56, 57, 58, 59,
        60, 61, 62, 64, 65, 66, 68, 71, 73, 74, 76, 77, 81, 82, 83, 87, 90, 95,
        96, 97
    ]
    static let feminineFirstNames: Set<String> = [
        "aisha","amara","amy","ana","anna","ava","aya","ayla",
        "beatrice","bianca","camila","camille","celeste","chloe","claire","claudia",
        "devi","diana","elena","eleanor","elise","elizabeth","ella","emma","erin","esme","eva","evelyn",
        "fatima","felicia","fiona","flora","freya",
        "grace","greta","hannah","hazel","helen","hillary",
        "imani","ingrid","iris","isabel","ivy",
        "jasmine","jenna","jessica","juno",
        "kira","laura","lena","lila","linda","lisa","lucia","luna",
        "maren","maria","marina","martha","mary","maya","mei","meera","melissa","mia","mira","monica",
        "nadia","naomi","natasha","nina","nora","olivia",
        "paige","petra","phoebe","priscilla","priya",
        "rachel","rebekah","renee","rosa","ruby","sarah","sienna","sofia","sophia","stephanie","susan",
        "tanya","tara","teresa","tessa","tiffany",
        "vanessa","vera","veronica","victoria","violet",
        "whitney","yuki","yuna","zara","zoe"
    ]
    static let masculineFirstNames: Set<String> = [
        "aaron","adam","aiden","alan","alex","alfredo","ali","amir","andrew","andy","antonio",
        "arjun","arnav","arthur","austin",
        "benjamin","bill","blake","brandon","brian","bruce","bryce",
        "callum","calvin","cameron","carl","carlos","charles","charlie","chase","chris","christopher",
        "clay","cole","colin","connor","craig",
        "damon","daniel","dante","darius","david","declan","derek","devon","diego","dominic","dylan",
        "eddie","edwin","eli","elio","elvis","emmanuel","eric","ernesto","ethan","evan","ezra",
        "felipe","felix","fernando","francisco","frank",
        "gabriel","gary","george","graham","gus",
        "hank","harry","hassan","hector","henrik","henry","hiroshi","hugo","hunter",
        "isaac","isaiah","ivan",
        "jack","jackson","jacob","jake","james","jamie","jared","jason","javier","jeremy","joel","john",
        "jonah","jonathan","joseph","josh","joshua","juan","justin",
        "kenji","kevin","kurt","kyle",
        "lance","leo","leon","lewis","liam","logan","lorenzo","lucas","luca","luis","luke",
        "malcolm","manuel","marcus","mario","mark","markus","martin","mason","mateo","matt","matthew",
        "miguel","miles","mohammed","mohamed",
        "nathan","nathaniel","neil","nicholas","nick","noah","noel",
        "omar","oscar","owen",
        "pablo","patrick","paul","peter","philip","phil","pierre","preston",
        "rafael","ramon","raphael","ravi","raymond","reese","richard","rob","robert","roberto","rohan",
        "ron","ronald","ryan",
        "samir","samuel","scott","sean","sergio","seth","shane","shawn","simon","spencer","stephen",
        "stuart",
        "tariq","ted","terrence","theo","thomas","tim","tobias","todd","tom","tony","tyler",
        "victor","vijay","vince",
        "walter","warren","wesley","william","willie","wyatt",
        "xavier","xander",
        "zachary"
    ]

    enum PersonaGender { case feminine, masculine, neutral }

    static func genderOfKey(_ key: String) -> PersonaGender {
        let lower = key.lowercased()
        let tokens = lower.split(whereSeparator: { !$0.isLetter })
        for token in tokens {
            let candidate = String(token)
            if feminineFirstNames.contains(candidate) { return .feminine }
            if masculineFirstNames.contains(candidate) { return .masculine }
        }
        return .neutral
    }

    static func index(for key: String, poolSize: Int = 97) -> Int {
        var hash: UInt64 = 14695981039346656037
        for byte in key.lowercased().utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        if poolSize == 97 {
            switch genderOfKey(key) {
            case .feminine:
                return feminineSlots[Int(hash % UInt64(feminineSlots.count))]
            case .masculine:
                return masculineSlots[Int(hash % UInt64(masculineSlots.count))]
            case .neutral:
                break
            }
        }
        return Int(hash % UInt64(poolSize)) + 1
    }

    static func assetName(prefix: String, key: String, poolSize: Int = 97) -> String {
        let idx = index(for: key, poolSize: poolSize)
        return String(format: "\(prefix)%02d", idx)
    }
}

private enum TrailBlazeFaceResolver {
    static func assetName(for key: String) -> String {
        FaceAssetResolver.assetName(prefix: "tb_face_", key: key)
    }
}

struct AthleteBadgeView: View {
    let athleteName: String
    var size: CGFloat = 36

    private var initials: String {
        athleteName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
    }

    private var faceAssetName: String {
        TrailBlazeFaceResolver.assetName(for: athleteName)
    }

    var body: some View {
        ZStack {
            if let uiImage = UIImage(named: faceAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, Color(red: 0.82, green: 0.27, blue: 0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

struct MetricGridView: View {
    let items: [MetricItem]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(item.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.backgroundMuted)
                )
            }
        }
    }
}

struct ChallengeCardView: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(challenge.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            Text(challenge.subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
            ProgressView(value: challenge.progress, total: challenge.goal)
                .tint(AppTheme.accent)
            HStack {
                Text("\(AppFormatters.integer(challenge.progress)) / \(AppFormatters.integer(challenge.goal))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(challenge.reward)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(14)
        .frame(width: 220, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }
}

struct TrailBlazeTopHeaderBar<Leading: View, Trailing: View>: View {
    let title: String
    let leading: Leading
    let trailing: Trailing

    init(
        title: String,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                leading
                Spacer(minLength: 16)
                trailing
            }
        }
    }
}

struct TrailBlazeIconButton: View {
    let systemImage: String
    var filled: Bool = false
    var background: Color = AppTheme.chrome
    var foreground: Color = .white
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(filled ? background : AppTheme.chrome)
            Image(systemName: systemImage)
                .font(.system(size: size * 0.40, weight: .medium))
                .foregroundStyle(foreground)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
    }
}

struct TrailBlazeChip: View {
    let title: String
    var systemImage: String? = nil
    var isSelected: Bool = false
    var filledWhenSelected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isSelected ? (filledWhenSelected ? .black : AppTheme.accent) : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected && filledWhenSelected ? AppTheme.accent : .black.opacity(0.92))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppTheme.accent : Color.white.opacity(0.14), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct TrailBlazeInsetTextField: View {
    let title: String
    @Binding var text: String
    var leadingSystemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let leadingSystemImage {
                Image(systemName: leadingSystemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            TextField(title, text: $text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.backgroundMuted)
        )
    }
}

struct WeekTrendChartView: View {
    let values: [Double]
    let labels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GeometryReader { proxy in
                let chartHeight = proxy.size.height
                let chartWidth = proxy.size.width
                let maxValue = max(values.max() ?? 0, 1)
                let points = values.enumerated().map { index, value in
                    CGPoint(
                        x: CGFloat(index) / CGFloat(max(values.count - 1, 1)) * (chartWidth - 20) + 10,
                        y: chartHeight - ((CGFloat(value) / CGFloat(maxValue)) * (chartHeight - 20)) - 10
                    )
                }

                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        let y = CGFloat(index) / 2 * (chartHeight - 20) + 10
                        Path { path in
                            path.move(to: CGPoint(x: 10, y: y))
                            path.addLine(to: CGPoint(x: chartWidth - 10, y: y))
                        }
                        .stroke(AppTheme.divider, lineWidth: 1)
                    }

                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                    ForEach(points.indices, id: \.self) { index in
                        ZStack {
                            Circle()
                                .fill(AppTheme.background)
                                .frame(width: index == points.indices.last ? 30 : 16, height: index == points.indices.last ? 30 : 16)
                                .opacity(index == points.indices.last ? 0.85 : 1)
                            Circle()
                                .stroke(AppTheme.accent, lineWidth: index == points.indices.last ? 6 : 4)
                                .frame(width: index == points.indices.last ? 16 : 10, height: index == points.indices.last ? 16 : 10)
                        }
                        .position(points[index])
                    }
                }
            }
            .frame(height: 170)

            HStack {
                ForEach(labels.indices, id: \.self) { index in
                    Text(labels[index])
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

enum MapPlaceholderStyle {
    case card
    case fullScreen
}

struct MapPlaceholderView: View {
    let points: [RoutePoint]
    var routes: [Route] = []
    var highlightedRouteId: String? = nil
    var height: CGFloat = 148
    var style: MapPlaceholderStyle = .card
    var showCurrentLocation: Bool = false
    var showLabels: Bool = false
    var showHeatmap: Bool = false
    var isThreeDimensional: Bool = false
    var allowsInteraction: Bool = false
    var recenterTrigger: Int = 0

    @State private var cameraPosition: MapCameraPosition = .automatic

    private var fallbackPoints: [RoutePoint] {
        BenchmarkLocation.fallbackRoutePoints(routeId: "fallback")
    }

    private var fallbackRoute: Route {
        Route(
            id: "fallback_route",
            name: "Suggested Route",
            distanceKilometers: 8.2,
            elevationGainMeters: 120,
            estimatedTimeSeconds: 2400,
            popularityScore: 80,
            startLocation: BenchmarkLocation.currentLocationLabel,
            points: fallbackPoints,
            elevationProfile: [],
            segmentIds: [],
            isSaved: false,
            isBookmarked: false,
            recommendedActivityType: .run
        )
    }

    private var visibleRoutes: [Route] {
        routes.isEmpty ? [fallbackRoute] : routes
    }

    private var highlightedRoute: Route? {
        visibleRoutes.first(where: { $0.id == highlightedRouteId }) ?? visibleRoutes.first
    }

    private var nonHighlightedRoutes: [Route] {
        visibleRoutes.filter { $0.id != highlightedRoute?.id }
    }

    var body: some View {
        Map(position: $cameraPosition, interactionModes: allowsInteraction ? .all : []) {
            // Non-highlighted routes (dimmed)
            ForEach(nonHighlightedRoutes) { route in
                MapPolyline(coordinates: route.points.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                })
                .stroke(Color.white.opacity(0.25), lineWidth: 3)
            }

            // Highlighted route layers
            if let highlighted = highlightedRoute {
                let coords = highlighted.points.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                }

                // Glow layer
                MapPolyline(coordinates: coords)
                    .stroke(AppTheme.accent.opacity(0.25), lineWidth: style == .fullScreen ? 12 : 8)

                // White outline
                MapPolyline(coordinates: coords)
                    .stroke(Color.white.opacity(style == .fullScreen ? 0.55 : 0.30), lineWidth: style == .fullScreen ? 6 : 4.5)

                // Accent line
                MapPolyline(coordinates: coords)
                    .stroke(AppTheme.accent, lineWidth: style == .fullScreen ? 3.5 : 3)

                // Start marker
                if let first = highlighted.points.first {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude), anchor: .center) {
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: style == .fullScreen ? 12 : 10, height: style == .fullScreen ? 12 : 10)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }

                // End marker
                if let last = highlighted.points.last, highlighted.points.count > 1 {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude), anchor: .center) {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: style == .fullScreen ? 12 : 10, height: style == .fullScreen ? 12 : 10)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
            }

            // Heatmap overlay (popular corridors)
            if showHeatmap {
                ForEach(0..<Self.heatPaths.count, id: \.self) { index in
                    MapPolyline(coordinates: Self.heatPaths[index].map {
                        CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1)
                    })
                    .stroke(
                        Self.heatColors[index % Self.heatColors.count].opacity(0.55),
                        lineWidth: 7
                    )
                }
            }

            // Current location blue dot
            if showCurrentLocation {
                Annotation("", coordinate: currentLocationCoordinate, anchor: .center) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.35, green: 0.62, blue: 0.98))
                            .frame(width: 18, height: 18)
                        Circle()
                            .stroke(.white, lineWidth: 3.5)
                            .frame(width: 18, height: 18)
                    }
                }
            }

            // Route labels
            if showLabels {
                ForEach(Array(visibleRoutes.prefix(4))) { route in
                    if let centroid = routeCentroid(route) {
                        Annotation("", coordinate: centroid, anchor: .center) {
                            Text(route.startLocation)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(red: 0.94, green: 0.67, blue: 0.48))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.chrome.opacity(0.82)))
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: isThreeDimensional ? .realistic : .flat, pointsOfInterest: .excludingAll))
        .mapControls { }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: style == .fullScreen ? 0 : 20, style: .continuous))
        .onAppear { fitCamera() }
        .onChange(of: recenterTrigger) { _, _ in fitCamera() }
        .onChange(of: isThreeDimensional) { _, _ in fitCamera() }
    }

    // MARK: - Heatmap Data

    private static let heatPaths: [[(Double, Double)]] = [
        // Embarcadero waterfront
        [(37.808, -122.410), (37.802, -122.398), (37.795, -122.392), (37.788, -122.389), (37.782, -122.388)],
        // Crissy Field to GG Bridge
        [(37.804, -122.460), (37.806, -122.468), (37.808, -122.474), (37.815, -122.478)],
        // GG Park pan handle
        [(37.773, -122.440), (37.772, -122.455), (37.770, -122.470), (37.769, -122.485), (37.768, -122.500)],
        // Marina Green
        [(37.807, -122.430), (37.807, -122.440), (37.807, -122.448), (37.806, -122.455)],
    ]

    private static let heatColors: [Color] = [.red, .orange, .yellow, .green]

    // MARK: - Helpers

    private var currentLocationCoordinate: CLLocationCoordinate2D {
        if let highlighted = highlightedRoute, !highlighted.points.isEmpty {
            let midIndex = min(highlighted.points.count / 2, highlighted.points.count - 1)
            let mid = highlighted.points[midIndex]
            return CLLocationCoordinate2D(latitude: mid.latitude + 0.001, longitude: mid.longitude + 0.001)
        }
        return CLLocationCoordinate2D(latitude: BenchmarkLocation.referenceLatitude, longitude: BenchmarkLocation.referenceLongitude)
    }

    private func routeCentroid(_ route: Route) -> CLLocationCoordinate2D? {
        guard !route.points.isEmpty else { return nil }
        let avgLat = route.points.map(\.latitude).reduce(0, +) / Double(route.points.count)
        let avgLon = route.points.map(\.longitude).reduce(0, +) / Double(route.points.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }

    private func fitCamera() {
        let allPoints = visibleRoutes.flatMap(\.points)
        guard !allPoints.isEmpty else { return }

        let lats = allPoints.map(\.latitude)
        let lons = allPoints.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latSpan = maxLat - minLat
        let lonSpan = maxLon - minLon
        let padding: Double = style == .fullScreen ? 1.6 : 1.4

        if isThreeDimensional {
            let distance = max(latSpan, lonSpan) * 111_000 * 2.5
            cameraPosition = .camera(MapCamera(
                centerCoordinate: center,
                distance: max(distance, 500),
                heading: 0,
                pitch: 45
            ))
        } else {
            cameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: max(latSpan * padding, 0.005),
                    longitudeDelta: max(lonSpan * padding, 0.005)
                )
            ))
        }
    }
}

struct ElevationProfileView: View {
    let values: [Double]
    var height: CGFloat = 120

    var body: some View {
        GeometryReader { proxy in
            let points = makePoints(in: proxy.size)

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.backgroundMuted)

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: CGPoint(x: first.x, y: proxy.size.height))
                    path.addLine(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    if let last = points.last {
                        path.addLine(to: CGPoint(x: last.x, y: proxy.size.height))
                    }
                    path.closeSubpath()
                }
                .fill(AppTheme.accent.opacity(0.18))

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func makePoints(in size: CGSize) -> [CGPoint] {
        let profile = values.isEmpty ? [0.2, 0.35, 0.68, 0.5, 0.72, 0.38, 0.16] : values
        let maxValue = profile.max() ?? 1
        let minValue = profile.min() ?? 0
        let range = max(maxValue - minValue, 0.0001)

        return profile.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(max(profile.count - 1, 1)) * (size.width - 20) + 10
            let yRatio = (value - minValue) / range
            let y = (1 - yRatio) * (size.height - 20) + 10
            return CGPoint(x: x, y: y)
        }
    }
}

struct ActivityCardView: View {
    let activity: Activity
    let athlete: Athlete?
    let route: Route?
    let activityDestination: AnyView
    let athleteDestination: AnyView
    @Binding var commentText: String
    let onToggleKudos: () -> Void
    let onSubmitComment: () -> Void
    var onHideActivity: (() -> Void)? = nil

    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Athlete header
            HStack(alignment: .center, spacing: 10) {
                NavigationLink(destination: athleteDestination) {
                    HStack(spacing: 10) {
                        AthleteBadgeView(athleteName: athlete?.name ?? "Athlete", size: 40)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(athlete?.name ?? "Unknown Athlete")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            HStack(spacing: 4) {
                                Text(activity.activityType.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("•")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(AppFormatters.relativeDate(activity.startTime))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.athleteProfileButton(activity.athleteId))

                Spacer()

                Menu {
                    if let onHideActivity {
                        Button(role: .destructive) {
                            onHideActivity()
                        } label: {
                            Label("Hide Activity", systemImage: "eye.slash")
                        }
                    }

                    Button {
                        let firstName = athlete?.name.components(separatedBy: " ").first ?? "Athlete"
                        appState.transientMessage = "\(firstName) muted."
                    } label: {
                        Label("Mute \(athlete?.name.components(separatedBy: " ").first ?? "Athlete")", systemImage: "speaker.slash")
                    }

                    ShareLink(item: "\(activity.title) — \(AppFormatters.distance(activity.distanceKilometers)) in \(AppFormatters.duration(activity.durationSeconds))") {
                        Label("Share Activity", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        appState.transientMessage = "Report submitted."
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Activity title
            Text(activity.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            // Map (full-bleed within card)
            MapPlaceholderView(points: route?.points ?? [], height: 180)
                .clipShape(Rectangle())

            // Metrics row
            HStack(spacing: 0) {
                activityMetric(label: "Distance", value: AppFormatters.distance(activity.distanceKilometers))
                activityMetric(label: activity.activityType == .ride || activity.activityType == .indoorRide ? "Speed" : "Pace", value: AppFormatters.primaryPerformanceMetric(for: activity))
                activityMetric(label: "Time", value: AppFormatters.duration(activity.durationSeconds))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(AppTheme.divider)
                .padding(.horizontal, 16)

            // Kudos + comments row
            HStack(spacing: 16) {
                Button(action: onToggleKudos) {
                    HStack(spacing: 6) {
                        Image(systemName: activity.hasCurrentUserKudo ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 18, weight: .medium))
                        Text("\(activity.kudosCount)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(activity.hasCurrentUserKudo ? AppTheme.accent : .white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.kudosButton(activity.id))

                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 18, weight: .medium))
                    Text("\(activity.commentCount)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)

                Spacer()

                NavigationLink(destination: activityDestination) {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier(AccessibilityID.activityOpenButton(activity.id))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if !activity.comments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(activity.comments.prefix(2)) { comment in
                        Text(comment.message)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Comment input
            HStack(spacing: 8) {
                AthleteBadgeView(athleteName: "Y", size: 28)
                TextField("Add a comment...", text: $commentText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier(AccessibilityID.commentField(activity.id))

                if !commentText.isEmpty {
                    Button("Post", action: onSubmitComment)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityIdentifier(AccessibilityID.commentSendButton(activity.id))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 0.5)
        )
        .accessibilityIdentifier(AccessibilityID.activityRow(activity.id))
    }

    private func activityMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkoutLibraryView: View {
    @EnvironmentObject private var appState: AppState

    let title: String

    init(title: String = "Instant Workouts") {
        self.title = title
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeaderView(title, subtitle: "Structured presets you can load directly into the Record tab")

                ForEach(WorkoutCatalog.presets) { preset in
                    NavigationLink(destination: WorkoutPresetDetailView(preset: preset)) {
                        WorkoutPresetRowView(preset: preset)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WorkoutPresetDetailView: View {
    @EnvironmentObject private var appState: AppState

    let preset: WorkoutPreset

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                WorkoutArtworkCard(preset: preset, large: true)

                MetricGridView(
                    items: [
                        MetricItem(label: "Duration", value: AppFormatters.durationMinutes(preset.durationSeconds)),
                        MetricItem(label: "Workout Type", value: preset.activityType.title),
                        MetricItem(label: "Focus", value: focusLabel),
                        MetricItem(label: "Load Into", value: "Record")
                    ]
                )

                SectionHeaderView("Overview", subtitle: preset.subtitle)

                Button("Start Workout") {
                    appState.startWorkout(preset)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(preset.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var focusLabel: String {
        switch preset.id {
        case "foundation_strength": return "Strength"
        case "recovery_mobility": return "Mobility"
        case "speed_starter": return "Speed"
        default: return "Core"
        }
    }
}

struct WorkoutArtworkCard: View {
    let preset: WorkoutPreset
    var large: Bool = false

    private var colors: [Color] {
        switch preset.id {
        case "foundation_strength":
            return [Color(red: 0.53, green: 0.05, blue: 0.05), Color(red: 0.86, green: 0.27, blue: 0.08)]
        case "recovery_mobility":
            return [Color(red: 0.17, green: 0.16, blue: 0.30), Color(red: 0.25, green: 0.44, blue: 0.78)]
        case "speed_starter":
            return [Color(red: 0.24, green: 0.12, blue: 0.04), Color(red: 0.98, green: 0.56, blue: 0.14)]
        default:
            return [Color(red: 0.11, green: 0.19, blue: 0.15), Color(red: 0.18, green: 0.58, blue: 0.38)]
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: large ? 20 : 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: large ? 16 : 12, style: .continuous)
                    .fill(.black.opacity(0.16))
                    .frame(width: large ? 100 : 80, height: large ? 120 : 100)
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: preset.systemImage)
                                .font(.system(size: large ? 32 : 26, weight: .bold))
                            Text(AppFormatters.durationMinutes(preset.durationSeconds))
                                .font(.system(size: large ? 16 : 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                    }
                    .padding(large ? 16 : 12)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .font(.system(size: large ? 22 : 18, weight: .bold))
                    Text(preset.subtitle)
                        .font(.system(size: large ? 14 : 13, weight: .medium))
                        .lineLimit(large ? 3 : 2)
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(16)
            }
            .frame(height: large ? 260 : 190)
    }
}

private struct WorkoutPresetRowView: View {
    let preset: WorkoutPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WorkoutArtworkCard(preset: preset)

            HStack {
                Label(preset.activityType.title, systemImage: preset.activityType.systemImage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Text("Open")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }
}
