import SwiftUI

@main
struct SkyTripApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
        }
    }
}
