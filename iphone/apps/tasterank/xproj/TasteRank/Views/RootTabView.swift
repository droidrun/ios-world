import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @State private var selectedTab: TasteRankTab = .feed
    @State private var showingSearch = false

    var body: some View {
        ZStack {
            MockTasteRankTheme.background.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .feed:
                    NavigationStack {
                        HomeView(openSearch: { showingSearch = true })
                    }
                case .lists:
                    NavigationStack {
                        ListsView()
                    }
                case .leaderboard:
                    NavigationStack {
                        LeaderboardView()
                    }
                case .profile:
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TasteRankBottomBar(
                selectedTab: $selectedTab,
                profileInitials: store.currentUserProfile.initials,
                openSearch: { showingSearch = true }
            )
        }
        .fullScreenCover(isPresented: $showingSearch) {
            NavigationStack {
                SearchView(isPresented: $showingSearch)
            }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(MockTasteRankStore())
}
