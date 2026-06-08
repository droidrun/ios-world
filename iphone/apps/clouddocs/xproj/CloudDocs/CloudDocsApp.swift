import SwiftUI

@main
struct CloudDocsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = WorkspaceStore()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
                .onOpenURL { url in
                    store.handleIncomingHandoff(url: url, expectedType: .document)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        store.reloadFromDisk()
                    }
                }
        }
    }
}
