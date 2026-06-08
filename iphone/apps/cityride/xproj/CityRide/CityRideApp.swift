import SwiftUI

@main
struct CityRideApp: App {
    @StateObject private var store = CityRideStore()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}
