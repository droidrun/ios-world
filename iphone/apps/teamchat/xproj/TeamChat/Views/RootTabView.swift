import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: WorkspaceStore
    @State private var hidesBottomControls = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TeamChatPalette.screen
                .ignoresSafeArea()

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: hidesBottomControls ? 0 : TeamChatMetrics.bottomChromeInset)
                }

            if hidesBottomControls == false {
                bottomControls
                    .padding(.bottom, TeamChatMetrics.bottomChromeBottomPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: hidesBottomControls)
        .onPreferenceChange(RootChromeHiddenPreferenceKey.self) { hidesBottomControls in
            self.hidesBottomControls = hidesBottomControls
        }
        .alert(item: $store.appAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(alert.confirmButtonTitle))
            )
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch store.selectedTab {
        case .home:
            HomeView(store: store)
        case .channels:
            ChannelsView(store: store)
        case .dms:
            DMsView(store: store)
        case .activity:
            ActivityCenterView(store: store, initialFilter: .all)
        case .search:
            SearchView(store: store)
        case .more:
            MoreView(store: store)
        }
    }

    private var bottomControls: some View {
        HStack(alignment: .bottom, spacing: 10) {
            bottomTabBar
            searchFloatingButton
        }
        .padding(.horizontal, TeamChatMetrics.bottomChromeHorizontalPadding)
    }

    private var bottomTabBar: some View {
        HStack(spacing: 2) {
            tabButton(tab: .home, title: "Home", icon: "house.fill", inactiveIcon: "house")
            tabButton(tab: .dms, title: "DMs", icon: "bubble.left.and.bubble.right.fill", inactiveIcon: "bubble.left.and.bubble.right")
            tabButton(tab: .activity, title: "Activity", icon: "bell.fill", inactiveIcon: "bell")
            tabButton(tab: .more, title: "More", icon: "ellipsis", inactiveIcon: "ellipsis")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(TeamChatPalette.tabBar)
                .overlay(Capsule().strokeBorder(TeamChatPalette.divider, lineWidth: 1))
        )
    }

    private var searchFloatingButton: some View {
        Button {
            store.switchTab(.search)
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: TeamChatMetrics.bottomSearchButtonSize, height: TeamChatMetrics.bottomSearchButtonSize)
                .background(
                    Circle()
                        .fill(TeamChatPalette.avatarRing)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab_search")
    }

    private func tabButton(tab: AppTab, title: String, icon: String, inactiveIcon: String) -> some View {
        let isSelected = tabIsSelected(tab)
        return Button {
            store.switchTab(tab)
        } label: {
            VStack(spacing: 1) {
                ZStack {
                    Image(systemName: isSelected ? icon : inactiveIcon)
                        .font(.callout.weight(.semibold))

                    if badgeCount(for: tab) > 0 {
                        Text("\(badgeCount(for: tab))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.red, in: Capsule())
                            .offset(x: 12, y: -8)
                    }
                }
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.14) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId(for: tab))
    }

    private func badgeCount(for tab: AppTab) -> Int {
        switch tab {
        case .dms:
            return store.unreadDMCount
        case .home:
            return store.mentionCount
        case .activity:
            return store.activityItems(for: .unreads).count
        case .channels, .search, .more:
            return 0
        }
    }

    private func accessibilityId(for tab: AppTab) -> String {
        switch tab {
        case .home:
            return "tab_home"
        case .dms:
            return "tab_dms"
        case .activity:
            return "tab_activity"
        case .channels:
            return "tab_channels"
        case .search:
            return "tab_search"
        case .more:
            return "tab_more"
        }
    }

    private func tabIsSelected(_ tab: AppTab) -> Bool {
        switch tab {
        case .home:
            return store.selectedTab == .home || store.selectedTab == .channels
        default:
            return store.selectedTab == tab
        }
    }
}

private struct RootChromeHiddenPreferenceKey: PreferenceKey {
    static var defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    func hidesRootChrome(_ hidden: Bool = true) -> some View {
        preference(key: RootChromeHiddenPreferenceKey.self, value: hidden)
    }
}
