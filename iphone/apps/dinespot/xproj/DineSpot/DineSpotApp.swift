import SwiftUI

@main
struct DineSpotApp: App {
    @StateObject private var store = DiningStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
