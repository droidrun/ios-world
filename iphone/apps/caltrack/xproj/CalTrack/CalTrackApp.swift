import SwiftUI

@main
struct CalTrackApp: App {
    @StateObject private var store = FitnessStore()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
        }
    }
}
