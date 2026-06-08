import SwiftUI

struct RootTabView: View {
    @Environment(MockTicketBoxStore.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            NavigationStack {
                HomeView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tag(TicketBoxTab.browse)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack {
                SearchView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tag(TicketBoxTab.search)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack {
                TicketsView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tag(TicketBoxTab.tickets)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack {
                TrackingView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tag(TicketBoxTab.tracking)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack {
                MeView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tag(TicketBoxTab.me)
            .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom) {
            TicketBoxTabBar(selectedTab: $store.selectedTab)
        }
        .background(MockSeatGeekTheme.background.ignoresSafeArea())
    }
}

private struct TicketBoxTabBar: View {
    @Binding var selectedTab: TicketBoxTab

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                ForEach(TicketBoxTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == tab ? tab.selectedIconName : tab.iconName)
                                .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                                .frame(height: 24)
                            Text(tab.title)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(selectedTab == tab ? MockSeatGeekTheme.accent : MockSeatGeekTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("tab.\(tab.rawValue)")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 2)
        }
        .background(MockSeatGeekTheme.surface)
    }
}

#Preview {
    RootTabView()
        .environment(MockTicketBoxStore())
}
