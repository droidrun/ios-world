import SwiftUI

@main
struct ScoreZoneApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .task {
                    await appState.preWarmCache()
                }
        }
    }
}
