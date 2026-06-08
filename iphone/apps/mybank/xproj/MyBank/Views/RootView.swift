import SwiftUI
import UIKit

enum MyBankTab: CaseIterable, Identifiable {
    case home
    case payTransfer
    case planTrack
    case rewards
    case more

    var id: Self { self }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .payTransfer:
            return "Pay &\ntransfer"
        case .planTrack:
            return "Plan & track"
        case .rewards:
            return "Rewards"
        case .more:
            return "More"
        }
    }

    var icon: String {
        switch self {
        case .home:
            return "house"
        case .payTransfer:
            return "arrow.left.arrow.right"
        case .planTrack:
            return "chart.bar.fill"
        case .rewards:
            return "star"
        case .more:
            return "line.3.horizontal"
        }
    }
}

enum BankPalette {
    static let accentRed = Color(red: 0.80, green: 0.11, blue: 0.24)
    static let chaseBlue = Color(red: 0.067, green: 0.478, blue: 0.792)
    static let chaseGreen = Color(red: 0.24, green: 0.53, blue: 0.00)
    static let chaseTeal = Color(red: 0.05, green: 0.35, blue: 0.32)
    static let chaseNavy = Color(red: 0.02, green: 0.15, blue: 0.40)
    static let ink = Color(red: 0.08, green: 0.10, blue: 0.16)
    static let pageBackground = Color(red: 0.95, green: 0.95, blue: 0.96)
    static let cardBackground = Color.white
    static let outline = Color.black.opacity(0.08)
    static let positiveGreen = Color(red: 0.13, green: 0.59, blue: 0.15)
    static let zelleViolet = Color(red: 0.44, green: 0.16, blue: 0.86)
}

struct RootView: View {
    @ObservedObject var store: BankStore
    @State private var selectedTab: MyBankTab = .home

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                currentContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                MyBankTabBar(selection: $selectedTab)
            }
            .background(BankPalette.pageBackground.ignoresSafeArea())

            if let toast = store.toast {
                ToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
            }
        }
        .animation(.spring(), value: store.toast)
    }

    @ViewBuilder
    private var currentContent: some View {
        switch selectedTab {
        case .home:
            MyBankHomeView(store: store)
        case .payTransfer:
            MyBankPayTransferView(store: store)
        case .planTrack:
            MyBankPlanTrackView(store: store)
        case .rewards:
            MyBankRewardsView(store: store)
        case .more:
            MyBankMoreView(store: store)
        }
    }
}

struct MyBankTabBar: View {
    @Binding var selection: MyBankTab
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var usesCompactLayout: Bool {
        dynamicTypeSize >= .xLarge
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MyBankTab.allCases) { tab in
                Button {
                    if selection != tab {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    selection = tab
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: usesCompactLayout ? 22 : 23, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                    }
                    .foregroundColor(selection == tab ? BankPalette.chaseBlue : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                }
                .accessibilityIdentifier("chase_tab_\(tab.title.replacingOccurrences(of: "\n", with: "_").replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "&", with: "and").lowercased())")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }
}

struct SurfaceCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(BankPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(BankPalette.outline, lineWidth: 1)
            )
    }
}

struct FilledPillButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(tint.opacity(configuration.isPressed ? 0.82 : 1))
            )
    }
}

struct OutlinePillButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(tint)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.92 : 1))
            )
            .overlay(
                Capsule()
                    .stroke(tint, lineWidth: 2)
            )
    }
}
