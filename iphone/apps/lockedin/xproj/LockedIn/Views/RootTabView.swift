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
                    .accessibilityIdentifier("tab_home")
            }
            .tag(AppTab.home)

            NavigationStack {
                NetworkView()
            }
            .tabItem {
                Label("My Network", systemImage: "person.2.fill")
                    .accessibilityIdentifier("tab_network")
            }
            .tag(AppTab.myNetwork)
            .badge(appState.invitations.count > 0 ? appState.invitations.count : 0)

            Text("")
                .tabItem {
                    Label("Post", systemImage: "plus.app.fill")
                        .accessibilityIdentifier("tab_post")
                }
                .tag(AppTab.post)

            NavigationStack {
                NotificationsView()
            }
            .tabItem {
                Label {
                    Text("Notifications")
                } icon: {
                    Image(systemName: "bell.fill")
                }
                .accessibilityIdentifier("tab_notifications")
            }
            .tag(AppTab.notifications)
            .badge(appState.unreadNotificationCount > 0 ? appState.unreadNotificationCount : 0)

            NavigationStack {
                JobsView()
            }
            .tabItem {
                Label("Jobs", systemImage: "briefcase.fill")
                    .accessibilityIdentifier("tab_jobs")
            }
            .tag(AppTab.jobs)
        }
        .tint(LockedInTheme.tabBarActive)
        .onChange(of: appState.selectedTab) { _, newValue in
            if newValue == .post {
                appState.selectedTab = .home
                appState.showCreatePost = true
            }
        }
        .sheet(isPresented: $appState.showCreatePost) {
            CreatePostView()
        }
        .sheet(isPresented: $appState.showMessaging) {
            MessagingListView()
        }
        .sheet(isPresented: $appState.showSearch) {
            SearchView()
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
