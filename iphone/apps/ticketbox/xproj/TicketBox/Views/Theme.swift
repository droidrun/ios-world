import SwiftUI

enum MockSeatGeekTheme {
    static let background = Color(red: 0.965, green: 0.965, blue: 0.97)
    static let surface = Color.white
    static let surfaceMuted = Color(red: 0.942, green: 0.944, blue: 0.95)
    static let accent = Color(red: 0.922, green: 0.39, blue: 0.29)
    static let accentSoft = Color(red: 0.95, green: 0.9, blue: 0.88)
    static let accentDark = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.12)
    static let textSecondary = Color(red: 0.44, green: 0.44, blue: 0.46)
    static let textTertiary = Color(red: 0.72, green: 0.72, blue: 0.74)
    static let border = Color.black.opacity(0.08)
    static let shadow = Color.black.opacity(0.08)
    static let green = Color(red: 0.13, green: 0.73, blue: 0.33)
    static let blue = Color(red: 0.35, green: 0.58, blue: 0.9)
    static let pink = Color(red: 0.73, green: 0.47, blue: 0.92)
    static let dealScoreRed = Color(red: 0.85, green: 0.2, blue: 0.2)
    static let dealScoreOrange = Color(red: 0.96, green: 0.62, blue: 0.16)
    static let dealScoreAmber = Color(red: 0.96, green: 0.72, blue: 0.16)

    static func dealScoreColor(for score: Int) -> Color {
        switch score {
        case 85...100: return green
        case 70..<85: return dealScoreAmber
        case 60..<70: return dealScoreOrange
        default: return dealScoreRed
        }
    }

    static func titleFont(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func bodyFont(size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func mediumFont(size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
}

struct CardBackground: View {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 22) {
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(MockSeatGeekTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MockSeatGeekTheme.border, lineWidth: 1)
            )
            .shadow(color: MockSeatGeekTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

struct FloatingTabBarBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 10)
    }
}

struct TeamBadgeView: View {
    let token: String
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            badgeBackground
            badgeForeground
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }

    private var badgeBackground: some View {
        Group {
            switch token {
            case "pirates":
                Color.black
            case "cavaliers":
                Color(red: 0.39, green: 0.08, blue: 0.22)
            case "warriors":
                Color(red: 0.11, green: 0.29, blue: 0.68)
            case "bulls":
                Color(red: 0.62, green: 0.07, blue: 0.13)
            case "blues":
                Color(red: 0.08, green: 0.25, blue: 0.68)
            case "sharks":
                Color(red: 0.02, green: 0.4, blue: 0.46)
            case "yankees":
                Color(red: 0.1, green: 0.16, blue: 0.36)
            case "giants":
                Color(red: 0.94, green: 0.46, blue: 0.19)
            case "padres":
                Color(red: 0.89, green: 0.74, blue: 0.28)
            case "braves":
                Color(red: 0.07, green: 0.15, blue: 0.33)
            case "dodgers":
                Color(red: 0.1, green: 0.23, blue: 0.58)
            case "lakers":
                Color(red: 0.33, green: 0.15, blue: 0.53)
            case "celtics":
                Color(red: 0.0, green: 0.42, blue: 0.15)
            case "suns":
                Color(red: 0.91, green: 0.34, blue: 0.13)
            case "nuggets":
                Color(red: 0.06, green: 0.18, blue: 0.42)
            case "clippers":
                Color(red: 0.78, green: 0.12, blue: 0.22)
            case "rockies":
                Color(red: 0.2, green: 0.12, blue: 0.38)
            case "concert", "music":
                Color(red: 0.42, green: 0.18, blue: 0.58)
            case "comedy", "laughs":
                Color(red: 0.92, green: 0.72, blue: 0.18)
            case "theater", "stage":
                Color(red: 0.72, green: 0.14, blue: 0.22)
            default:
                LinearGradient(
                    colors: [MockSeatGeekTheme.surfaceMuted, MockSeatGeekTheme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    @ViewBuilder
    private var badgeForeground: some View {
        switch token {
        case "pirates":
            Text("P")
                .font(.system(size: size * 0.58, weight: .black, design: .serif))
                .foregroundStyle(Color(red: 0.95, green: 0.78, blue: 0.23))
        case "cavaliers":
            Text("C")
                .font(.system(size: size * 0.54, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.86, green: 0.66, blue: 0.28))
        case "warriors":
            Circle()
                .stroke(Color(red: 0.98, green: 0.81, blue: 0.2), lineWidth: 3)
                .padding(size * 0.18)
                .overlay(
                    Image(systemName: "bridge")
                        .font(.system(size: size * 0.26, weight: .bold))
                        .foregroundStyle(Color(red: 0.98, green: 0.81, blue: 0.2))
                )
        case "bulls":
            Text("B")
                .font(.system(size: size * 0.54, weight: .black))
                .foregroundStyle(.white)
        case "blues":
            Image(systemName: "music.note")
                .font(.system(size: size * 0.44, weight: .black))
                .foregroundStyle(.white)
        case "sharks":
            Image(systemName: "drop.fill")
                .font(.system(size: size * 0.46, weight: .black))
                .foregroundStyle(.white)
        case "yankees":
            Text("NY")
                .font(.system(size: size * 0.3, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
        case "giants":
            Text("SF")
                .font(.system(size: size * 0.28, weight: .heavy, design: .serif))
                .foregroundStyle(.black)
        case "padres":
            Text("SD")
                .font(.system(size: size * 0.28, weight: .black))
                .foregroundStyle(Color(red: 0.13, green: 0.1, blue: 0.08))
        case "braves":
            Text("A")
                .font(.system(size: size * 0.52, weight: .bold, design: .serif))
                .foregroundStyle(.white)
        case "dodgers":
            Text("LA")
                .font(.system(size: size * 0.26, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
        case "lakers":
            Text("LAL")
                .font(.system(size: size * 0.22, weight: .heavy))
                .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.22))
        case "celtics":
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        case "suns":
            Image(systemName: "sun.max.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.22))
        case "nuggets":
            Text("DEN")
                .font(.system(size: size * 0.22, weight: .heavy))
                .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.22))
        case "clippers":
            Text("LAC")
                .font(.system(size: size * 0.22, weight: .heavy))
                .foregroundStyle(.white)
        case "rockies":
            Text("COL")
                .font(.system(size: size * 0.22, weight: .heavy))
                .foregroundStyle(Color(red: 0.76, green: 0.76, blue: 0.82))
        case "concert", "music":
            Image(systemName: "music.mic")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        case "comedy", "laughs":
            Image(systemName: "face.smiling.inverse")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(Color(red: 0.14, green: 0.12, blue: 0.1))
        case "theater", "stage":
            Image(systemName: "theatermasks.fill")
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
        default:
            Image(systemName: "sportscourt")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
        }
    }
}

struct ServiceIconView: View {
    let service: MusicServiceKind
    var size: CGFloat = 74

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(background)

            if service == .spotify {
                Circle()
                    .fill(Color(red: 0.33, green: 0.84, blue: 0.36))
                    .frame(width: size * 0.56, height: size * 0.56)
                VStack(spacing: 4) {
                    Capsule().fill(Color.black).frame(width: size * 0.28, height: 4)
                    Capsule().fill(Color.black).frame(width: size * 0.22, height: 4)
                    Capsule().fill(Color.black).frame(width: size * 0.2, height: 4)
                }
                .offset(y: size * 0.02)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.52, green: 0.42, blue: 0.9),
                                Color(red: 0.32, green: 0.65, blue: 0.92),
                                Color(red: 0.9, green: 0.33, blue: 0.46)
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
            }
        }
        .frame(width: size, height: size)
    }

    private var background: some ShapeStyle {
        if service == .spotify {
            return AnyShapeStyle(Color(red: 0.07, green: 0.05, blue: 0.06))
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [Color.white, Color(red: 0.97, green: 0.97, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct MasterCardMarkView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                .frame(width: 34, height: 24)
            HStack(spacing: -4) {
                Circle().fill(Color(red: 0.92, green: 0.37, blue: 0.24)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 0.98, green: 0.75, blue: 0.2)).frame(width: 12, height: 12)
            }
        }
    }
}

struct MLBAccountBadgeView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.16, blue: 0.4), Color.white, Color(red: 0.76, green: 0.12, blue: 0.16)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 56, height: 34)
            .overlay(
                Image(systemName: "figure.baseball")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}

struct EventArtworkView: View {
    let event: Event

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if let uiImage = UIImage(named: event.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    backgroundGradient

                    switch event.category {
                    case .sports:
                        sportsArtwork(in: size)
                    case .concerts:
                        concertArtwork(in: size)
                    case .theater:
                        broadwayArtwork(in: size)
                    case .comedy:
                        comedyArtwork(in: size)
                    }
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var backgroundGradient: some View {
        let colors: [Color]
        switch event.imageName {
        case "featured_warriors":
            colors = [Color(red: 0.23, green: 0.18, blue: 0.08), Color(red: 0.08, green: 0.12, blue: 0.26)]
        case "oracle_baseball":
            colors = [Color(red: 0.08, green: 0.17, blue: 0.28), Color(red: 0.29, green: 0.49, blue: 0.73)]
        case "sharks_map":
            colors = [Color(red: 0.1, green: 0.19, blue: 0.28), Color(red: 0.35, green: 0.5, blue: 0.68)]
        case "harry_styles_stage":
            colors = [Color(red: 0.2, green: 0.05, blue: 0.1), Color(red: 0.75, green: 0.08, blue: 0.16)]
        case "lady_gaga_stage":
            colors = [Color(red: 0.09, green: 0.05, blue: 0.15), Color(red: 0.39, green: 0.15, blue: 0.54)]
        case "bts_stadium":
            colors = [Color(red: 0.07, green: 0.09, blue: 0.25), Color(red: 0.35, green: 0.2, blue: 0.64)]
        case "one_republic_stage":
            colors = [Color(red: 0.13, green: 0.11, blue: 0.21), Color(red: 0.39, green: 0.18, blue: 0.58)]
        case "chainsmokers_stage":
            colors = [Color(red: 0.05, green: 0.09, blue: 0.15), Color(red: 0.04, green: 0.42, blue: 0.74)]
        case "hamilton_marquee":
            colors = [Color(red: 0.17, green: 0.12, blue: 0.08), Color(red: 0.54, green: 0.35, blue: 0.18)]
        case "comedy_stage":
            colors = [Color(red: 0.11, green: 0.09, blue: 0.1), Color(red: 0.32, green: 0.16, blue: 0.18)]
        case "taylor_swift_stage":
            colors = [Color(red: 0.52, green: 0.28, blue: 0.48), Color(red: 0.82, green: 0.42, blue: 0.6)]
        case "bad_bunny_stage":
            colors = [Color(red: 0.04, green: 0.12, blue: 0.08), Color(red: 0.18, green: 0.56, blue: 0.28)]
        case "drake_stage":
            colors = [Color(red: 0.06, green: 0.06, blue: 0.14), Color(red: 0.16, green: 0.22, blue: 0.48)]
        case "theater_marquee":
            colors = [Color(red: 0.22, green: 0.14, blue: 0.06), Color(red: 0.62, green: 0.42, blue: 0.16)]
        default:
            colors = [Color(red: 0.15, green: 0.17, blue: 0.22), Color(red: 0.3, green: 0.36, blue: 0.48)]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @ViewBuilder
    private func sportsArtwork(in size: CGSize) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<8, id: \.self) { _ in
                    Capsule()
                        .fill(Color(red: 0.31, green: 0.16, blue: 0.12).opacity(0.75))
                        .frame(height: max(5, size.height * 0.035))
                }
            }
            .padding(.top, size.height * 0.1)
            .padding(.horizontal, size.width * 0.06)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.69, green: 0.57, blue: 0.28))
                            .padding(size.width * 0.12)
                        Image(systemName: event.imageName == "sharks_map" ? "snowflake" : "sportscourt")
                            .font(.system(size: size.width * 0.12, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.88))
                    }
                )
                .padding(.horizontal, size.width * 0.08)

            Spacer()
        }
    }

    @ViewBuilder
    private func concertArtwork(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.28 : 0.16))
                    .frame(width: size.width * 0.1, height: size.height * 0.8)
                    .rotationEffect(.degrees(Double(-24 + (index * 12))))
                    .offset(x: CGFloat(index - 2) * size.width * 0.12, y: -size.height * 0.08)
            }

            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: size.width * 0.38, height: size.width * 0.38)
                .offset(y: size.height * 0.12)

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: size.width * 0.28, height: size.height * 0.18)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: size.width * 0.1, height: size.height * 0.24)
            }
            .offset(y: size.height * 0.03)
        }
    }

    @ViewBuilder
    private func broadwayArtwork(in size: CGSize) -> some View {
        let marqueeText = event.title
            .replacingOccurrences(of: " - ", with: "\n")
            .components(separatedBy: "\n").first?
            .uppercased() ?? event.title.uppercased()

        VStack(spacing: size.height * 0.06) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.87, green: 0.66, blue: 0.23))
                .frame(width: size.width * 0.62, height: size.height * 0.2)
                .overlay(
                    Text(marqueeText)
                        .font(.system(size: size.width * 0.065, weight: .black))
                        .foregroundStyle(Color.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 6)
                )
                .padding(.top, size.height * 0.18)

            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: size.width * 0.6, height: 6)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func comedyArtwork(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "mic.fill")
                .font(.system(size: size.width * 0.2, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.85))
            Capsule()
                .fill(Color.white.opacity(0.24))
                .frame(width: size.width * 0.12, height: size.height * 0.18)
            Spacer()
                .frame(height: size.height * 0.12)
        }
    }
}

struct VenueArtworkView: View {
    let imageName: String
    var cornerRadius: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    venueGradient

                    switch imageName {
                    case "oracle_park", "stanford_stadium", "levis_stadium":
                        stadiumScene(size: size)
                    case "orpheum", "fox_theater":
                        theaterScene(size: size)
                    case "punch_line", "the_warfield", "gamh":
                        comedyScene(size: size)
                    default:
                        arenaScene(size: size)
                    }
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    private var venueGradient: some View {
        let colors: [Color]
        switch imageName {
        case "city_arena":
            colors = [Color(red: 0.09, green: 0.14, blue: 0.25), Color(red: 0.3, green: 0.49, blue: 0.82)]
        case "sap_center":
            colors = [Color(red: 0.02, green: 0.22, blue: 0.28), Color(red: 0.14, green: 0.49, blue: 0.54)]
        case "oracle_park":
            colors = [Color(red: 0.07, green: 0.14, blue: 0.22), Color(red: 0.2, green: 0.41, blue: 0.64)]
        case "stanford_stadium":
            colors = [Color(red: 0.35, green: 0.05, blue: 0.07), Color(red: 0.64, green: 0.16, blue: 0.12)]
        case "bill_graham":
            colors = [Color(red: 0.13, green: 0.05, blue: 0.12), Color(red: 0.48, green: 0.14, blue: 0.42)]
        case "shoreline":
            colors = [Color(red: 0.03, green: 0.12, blue: 0.17), Color(red: 0.09, green: 0.41, blue: 0.47)]
        case "orpheum":
            colors = [Color(red: 0.17, green: 0.11, blue: 0.08), Color(red: 0.56, green: 0.34, blue: 0.19)]
        case "punch_line":
            colors = [Color(red: 0.11, green: 0.08, blue: 0.11), Color(red: 0.42, green: 0.18, blue: 0.18)]
        case "levis_stadium":
            colors = [Color(red: 0.42, green: 0.12, blue: 0.12), Color(red: 0.68, green: 0.22, blue: 0.14)]
        case "fox_theater":
            colors = [Color(red: 0.14, green: 0.08, blue: 0.06), Color(red: 0.52, green: 0.32, blue: 0.16)]
        case "the_warfield":
            colors = [Color(red: 0.12, green: 0.06, blue: 0.08), Color(red: 0.44, green: 0.16, blue: 0.22)]
        case "gamh":
            colors = [Color(red: 0.14, green: 0.1, blue: 0.06), Color(red: 0.48, green: 0.28, blue: 0.12)]
        default:
            colors = [Color(red: 0.09, green: 0.12, blue: 0.16), Color(red: 0.23, green: 0.29, blue: 0.4)]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @ViewBuilder
    private func arenaScene(size: CGSize) -> some View {
        VStack(spacing: size.height * 0.05) {
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: max(4, size.height * 0.07))
                }
            }
            .padding(.horizontal, size.width * 0.08)
            .padding(.top, size.height * 0.12)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .frame(width: size.width * 0.72, height: size.height * 0.36)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                        .padding(size.width * 0.11)
                )

            Spacer()
        }
    }

    @ViewBuilder
    private func stadiumScene(size: CGSize) -> some View {
        VStack(spacing: size.height * 0.04) {
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.16))
                        .frame(height: max(4, size.height * 0.06))
                }
            }
            .padding(.top, size.height * 0.12)
            .padding(.horizontal, size.width * 0.06)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .frame(width: size.width * 0.78, height: size.height * 0.38)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.21, green: 0.47, blue: 0.26))
                        .padding(size.width * 0.12)
                )

            Spacer()
        }
    }

    @ViewBuilder
    private func theaterScene(size: CGSize) -> some View {
        VStack(spacing: size.height * 0.06) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.86, green: 0.68, blue: 0.22))
                .frame(width: size.width * 0.56, height: size.height * 0.18)
                .padding(.top, size.height * 0.18)

            HStack(spacing: 5) {
                ForEach(0..<6, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: size.width * 0.08, height: size.height * 0.22)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func comedyScene(size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "mic.fill")
                .font(.system(size: size.width * 0.24, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.84))
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: size.width * 0.14, height: size.height * 0.24)
            Spacer()
                .frame(height: size.height * 0.12)
        }
    }
}

struct ListingSeatArtworkView: View {
    let style: ListingImageStyle
    let category: EventCategory
    var sectionLabel: String? = nil

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                seatGradient

                VStack(spacing: size.height * 0.04) {
                    topAnchor(size: size)

                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<8, id: \.self) { column in
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(column > row ? 0.28 : 0.18))
                                    .frame(height: max(6, size.height * 0.07))
                            }
                        }
                    }
                }
                .padding(size.width * 0.08)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if let sectionLabel {
                    VStack {
                        Spacer()
                        Text("View from \(sectionLabel)")
                            .font(.system(size: max(9, size.width * 0.09), weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            .padding(.bottom, size.height * 0.08)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var seatGradient: some View {
        let colors: [Color]

        switch style {
        case .centerCourt:
            colors = [Color(red: 0.11, green: 0.14, blue: 0.22), Color(red: 0.38, green: 0.46, blue: 0.65)]
        case .cornerView:
            colors = [Color(red: 0.09, green: 0.11, blue: 0.16), Color(red: 0.28, green: 0.34, blue: 0.47)]
        case .clubLevel:
            colors = [Color(red: 0.22, green: 0.19, blue: 0.14), Color(red: 0.48, green: 0.39, blue: 0.24)]
        case .behindGoal:
            colors = [Color(red: 0.08, green: 0.14, blue: 0.22), Color(red: 0.31, green: 0.43, blue: 0.59)]
        case .behindPlate:
            colors = [Color(red: 0.07, green: 0.17, blue: 0.2), Color(red: 0.25, green: 0.5, blue: 0.31)]
        case .dugout:
            colors = [Color(red: 0.13, green: 0.15, blue: 0.18), Color(red: 0.35, green: 0.42, blue: 0.48)]
        case .floor:
            colors = [Color(red: 0.13, green: 0.05, blue: 0.08), Color(red: 0.59, green: 0.14, blue: 0.18)]
        case .sideStage:
            colors = [Color(red: 0.08, green: 0.08, blue: 0.15), Color(red: 0.32, green: 0.18, blue: 0.57)]
        case .orchestra:
            colors = [Color(red: 0.19, green: 0.12, blue: 0.08), Color(red: 0.56, green: 0.33, blue: 0.17)]
        case .balcony:
            colors = [Color(red: 0.12, green: 0.12, blue: 0.18), Color(red: 0.33, green: 0.34, blue: 0.42)]
        case .lawn:
            colors = [Color(red: 0.05, green: 0.16, blue: 0.15), Color(red: 0.15, green: 0.44, blue: 0.3)]
        case .generalAdmission:
            colors = [Color(red: 0.12, green: 0.08, blue: 0.11), Color(red: 0.29, green: 0.12, blue: 0.18)]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @ViewBuilder
    private func topAnchor(size: CGSize) -> some View {
        switch category {
        case .sports:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.2))
                .frame(height: size.height * 0.22)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 2)
                        .padding(size.width * 0.12)
                )
        case .concerts:
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: size.width * 0.44, height: size.height * 0.18)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.32))
                    .frame(width: size.width * 0.16, height: size.height * 0.12)
            }
        case .theater, .comedy:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(height: size.height * 0.18)
                .overlay(
                    Capsule()
                        .fill(Color(red: 0.86, green: 0.68, blue: 0.22))
                        .frame(width: size.width * 0.38, height: size.height * 0.08)
                )
        }
    }
}

struct DealScoreView: View {
    let score: Int
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(MockSeatGeekTheme.dealScoreColor(for: score))
            Text("\(score)")
                .font(.system(size: size * 0.38, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct TicketBoxPickBadge: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 11, weight: .bold))
            Text("TicketBox Pick")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(MockSeatGeekTheme.green)
        )
    }
}

struct BuyerGuaranteeBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MockSeatGeekTheme.green)
            Text("Every order backed by our Buyer Guarantee")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MockSeatGeekTheme.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MockSeatGeekTheme.green.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
