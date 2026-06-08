import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)
            .accessibilityIdentifier("tab_home")

            NavigationStack {
                ScoresView()
            }
            .tabItem {
                Label("Scores", systemImage: "sportscourt.fill")
            }
            .tag(AppTab.scores)
            .accessibilityIdentifier("tab_scores")

            NavigationStack {
                WatchView()
            }
            .tabItem {
                Label("Watch", systemImage: "play.rectangle.fill")
            }
            .tag(AppTab.watch)
            .accessibilityIdentifier("tab_watch")

            NavigationStack {
                ScoreZonePlusView()
            }
            .tabItem {
                Label("ScoreZone+", systemImage: "star.circle.fill")
            }
            .tag(AppTab.scoreZonePlus)
            .accessibilityIdentifier("tab_scorezone_plus")

            NavigationStack {
                MenuView()
            }
            .tabItem {
                Label("More", systemImage: "line.3.horizontal")
            }
            .tag(AppTab.menu)
            .accessibilityIdentifier("tab_menu")
        }
        .preferredColorScheme(.dark)
        .tint(ScoreZoneColors.accentRed)
        .onAppear {
            UITabBar.appearance().barStyle = .black
            UITabBar.appearance().isTranslucent = false
            UITabBar.appearance().backgroundColor = UIColor.black
            UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
        }
    }
}
