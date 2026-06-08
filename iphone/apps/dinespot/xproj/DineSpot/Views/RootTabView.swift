import SwiftUI

struct RootTabView: View {
    @StateObject private var discoverViewModel = DiscoverViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "circle.inset.filled")
            }
            .accessibilityIdentifier("tab_home")

            NavigationStack {
                DiscoverView(viewModel: discoverViewModel)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .accessibilityIdentifier("tab_search")

            NavigationStack {
                RewardsView()
            }
            .tabItem {
                Label("Rewards", systemImage: "diamond")
            }
            .accessibilityIdentifier("tab_rewards")

            NavigationStack {
                ReservationsView()
            }
            .tabItem {
                Label("Reservations", systemImage: "calendar")
            }
            .accessibilityIdentifier("tab_reservations")

            NavigationStack {
                UpdatesView()
            }
            .tabItem {
                Label("Updates", systemImage: "bell")
            }
            .accessibilityIdentifier("tab_updates")
        }
        .tint(DiningTheme.accentRed)
        .toolbarBackground(.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environmentObject(DiningStore())
    }
}
