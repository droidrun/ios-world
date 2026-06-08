import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )) {
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label(AppTab.feed.title, systemImage: AppTab.feed.systemImage)
            }
            .tag(AppTab.feed)
            .accessibilityIdentifier(AccessibilityID.tabFeed)

            NavigationStack {
                RoutesView()
            }
            .tabItem {
                Label(AppTab.routes.title, systemImage: AppTab.routes.systemImage)
            }
            .tag(AppTab.routes)
            .accessibilityIdentifier(AccessibilityID.tabRoutes)

            NavigationStack {
                RecordView()
            }
            .tabItem {
                Label(AppTab.record.title, systemImage: AppTab.record.systemImage)
            }
            .tag(AppTab.record)
            .accessibilityIdentifier(AccessibilityID.tabRecord)

            NavigationStack {
                ClubsView()
            }
            .tabItem {
                Label(AppTab.clubs.title, systemImage: AppTab.clubs.systemImage)
            }
            .tag(AppTab.clubs)
            .accessibilityIdentifier(AccessibilityID.tabClubs)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage)
            }
            .tag(AppTab.profile)
            .accessibilityIdentifier(AccessibilityID.tabProfile)
        }
        .tint(AppTheme.accent)
        .toolbarBackground(AppTheme.chrome, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .background(AppTheme.background.ignoresSafeArea())
        .overlay(alignment: .top) {
            if let transientMessage = appState.transientMessage {
                Text(transientMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.backgroundRaised.opacity(0.96), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
                    .padding(.top, 8)
                    .onTapGesture {
                        appState.transientMessage = nil
                    }
            }
        }
        .alert(
            "Issue",
            isPresented: Binding(
                get: { appState.lastErrorMessage != nil },
                set: { if !$0 { appState.lastErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.lastErrorMessage ?? "")
        }
    }
}
