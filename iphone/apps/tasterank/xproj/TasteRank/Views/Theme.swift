import SwiftUI
import UIKit

enum MockTasteRankTheme {
    static let accent = Color(red: 0.08, green: 0.36, blue: 0.41)
    static let accentSoft = Color(red: 0.90, green: 0.95, blue: 0.95)
    static let background = Color(red: 0.97, green: 0.97, blue: 0.95)
    static let surface = Color.white
    static let card = surface
    static let border = Color(red: 0.82, green: 0.82, blue: 0.82)
    static let textPrimary = Color(red: 0.14, green: 0.15, blue: 0.18)
    static let textSecondary = Color(red: 0.60, green: 0.61, blue: 0.65)
    static let muted = Color(red: 0.89, green: 0.89, blue: 0.89)
    static let scoreGreen = Color(red: 0.27, green: 0.68, blue: 0.47)
    static let divider = Color(red: 0.87, green: 0.87, blue: 0.87)

    static func titleFont(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func bodyFont(size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func displayFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
}

struct CardBackground: View {
    var cornerRadius: CGFloat = 18

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(MockTasteRankTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MockTasteRankTheme.border, lineWidth: 1)
            )
    }
}

struct TasteRankWordmark: View {
    var size: CGFloat = 32

    var body: some View {
        Text("TasteRank")
            .font(.custom("Georgia-Bold", size: size))
            .italic()
            .tracking(-0.8)
            .foregroundStyle(MockTasteRankTheme.accent)
    }
}

struct TasteRankIconButton: View {
    let systemName: String
    var size: CGFloat = 22
    var weight: Font.Weight = .regular
    var foreground: Color = MockTasteRankTheme.textPrimary
    var accessibilityID: String? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: weight))
                .foregroundStyle(foreground)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // For icon-only buttons the inner SF Symbol's name otherwise wins as the
        // accessibility name, swallowing the identifier (e.g. the Feed "Filters"
        // button surfaced as "line.3.horizontal" and was untappable by id). When
        // a custom id is supplied, collapse the button into a single a11y element
        // so the identifier actually surfaces to automation.
        .accessibilityElement(children: accessibilityID == nil ? .contain : .ignore)
        .accessibilityIdentifier(accessibilityID ?? "")
        .accessibilityLabel(accessibilityID ?? "")
    }
}

struct TasteRankAvatarView: View {
    let seed: String
    let initials: String
    var size: CGFloat
    var neutral: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundFill)
            Circle()
                .stroke(neutral ? MockTasteRankTheme.border : Color.white.opacity(0.85), lineWidth: 1.5)
            Text(initials)
                .font(.system(size: size * 0.36, weight: .medium))
                .foregroundStyle(neutral ? MockTasteRankTheme.textSecondary : Color.white.opacity(0.92))
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(neutral ? 0 : 0.10), radius: neutral ? 0 : 8, x: 0, y: 4)
    }

    private var backgroundFill: LinearGradient {
        if neutral {
            return LinearGradient(
                colors: [Color(red: 0.92, green: 0.92, blue: 0.93), Color(red: 0.87, green: 0.87, blue: 0.89)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        let palette = avatarColors(for: seed)
        return LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func avatarColors(for seed: String) -> [Color] {
        let palettes: [[Color]] = [
            [Color(red: 0.08, green: 0.36, blue: 0.41), Color(red: 0.02, green: 0.16, blue: 0.22)],
            [Color(red: 0.44, green: 0.19, blue: 0.28), Color(red: 0.12, green: 0.10, blue: 0.25)],
            [Color(red: 0.50, green: 0.35, blue: 0.14), Color(red: 0.18, green: 0.10, blue: 0.02)],
            [Color(red: 0.16, green: 0.36, blue: 0.20), Color(red: 0.05, green: 0.16, blue: 0.09)],
            [Color(red: 0.19, green: 0.24, blue: 0.43), Color(red: 0.04, green: 0.08, blue: 0.20)]
        ]
        let hash = abs(seed.hashValue)
        return palettes[hash % palettes.count]
    }
}

struct TasteRankScoreBadge: View {
    let score: Double
    var diameter: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
            Circle()
                .stroke(MockTasteRankTheme.border, lineWidth: 1.5)
            Text(String(format: "%.1f", score))
                .font(.system(size: diameter * 0.32, weight: .semibold))
                .foregroundStyle(MockTasteRankTheme.scoreGreen)
        }
        .frame(width: diameter, height: diameter)
    }
}

struct TasteRankChip: View {
    let title: String
    var systemName: String? = nil
    var filled: Bool = false
    var trailingChevron: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            if let systemName {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .semibold))
            }

            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }

            if trailingChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundStyle(filled ? Color.white : MockTasteRankTheme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(filled ? MockTasteRankTheme.accent : Color.clear)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(filled ? MockTasteRankTheme.accent : MockTasteRankTheme.textPrimary.opacity(0.65), lineWidth: 1.4)
                )
        )
    }
}

struct TasteRankPillField: View {
    let icon: String
    let title: String
    var actionIcon: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
            Spacer()
            if let actionIcon {
                Image(systemName: actionIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.muted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(CardBackground(cornerRadius: 14))
    }
}

struct TasteRankPhotoGrid: View {
    let photoNames: [String]
    var height: CGFloat = 140

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(photoNames.prefix(2).enumerated()), id: \.offset) { _, name in
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .overlay {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

enum TasteRankTab: String {
    case feed
    case lists
    case leaderboard
    case profile

    var title: String {
        switch self {
        case .feed:
            return "Feed"
        case .lists:
            return "Your Lists"
        case .leaderboard:
            return "Leaderboard"
        case .profile:
            return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .feed:
            return "newspaper"
        case .lists:
            return "list.bullet"
        case .leaderboard:
            return "trophy"
        case .profile:
            return "person.crop.circle"
        }
    }
}

struct TasteRankBottomBar: View {
    @Binding var selectedTab: TasteRankTab
    let profileInitials: String
    let openSearch: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            tabItem(.feed)
            tabItem(.lists)

            Button(action: openSearch) {
                ZStack {
                    Circle()
                        .fill(MockTasteRankTheme.accent)
                        .frame(width: 52, height: 52)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Color.white)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 56)

            tabItem(.leaderboard)

            Button {
                selectedTab = .profile
            } label: {
                VStack(spacing: 4) {
                    TasteRankAvatarView(seed: "profile_tab", initials: profileInitials, size: 28, neutral: true)
                    Text(TasteRankTab.profile.title)
                        .font(.system(size: 10, weight: selectedTab == .profile ? .semibold : .regular))
                        .foregroundStyle(selectedTab == .profile ? MockTasteRankTheme.textPrimary : MockTasteRankTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .allowsTightening(true)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("tasterank_tab_profile")
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(MockTasteRankTheme.background)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MockTasteRankTheme.divider)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabItem(_ tab: TasteRankTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(selectedTab == tab ? MockTasteRankTheme.textPrimary : MockTasteRankTheme.textSecondary)
                Text(tab.title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab ? MockTasteRankTheme.textPrimary : MockTasteRankTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .allowsTightening(true)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tasterank_tab_\(tab.title.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
}

extension FriendProfile {
    var initials: String {
        let pieces = name.split(separator: " ")
        let letters = pieces.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "B" : String(letters)
    }
}

extension UserProfileSummary {
    var formattedRank: String {
        "#\(beliRank)"
    }
}

struct TasteRankModalRow: View {
    let systemName: String
    let title: String
    var subtitle: String? = nil
    var accessory: String? = "chevron.right"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(MockTasteRankTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                }
            }

            Spacer()

            if let accessory {
                Image(systemName: accessory)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(CardBackground(cornerRadius: 14))
    }
}

struct TasteRankShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String

    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                    .padding(14)
                    .background(CardBackground(cornerRadius: 16))

                ShareLink(item: message) {
                    Label("Open Share Sheet", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(MockTasteRankTheme.accent)
                        )
                }

                Button {
                    UIPasteboard.general.string = message
                    copied = true
                } label: {
                    Label(copied ? "Copied" : "Copy Link", systemImage: copied ? "checkmark.circle.fill" : "link")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CardBackground(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(16)
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("Share")
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
