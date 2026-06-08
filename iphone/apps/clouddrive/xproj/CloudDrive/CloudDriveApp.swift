import SwiftUI

@main
struct CloudDriveApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = WorkspaceStore()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        store.reloadFromDisk()
                    }
                }
        }
    }
}
