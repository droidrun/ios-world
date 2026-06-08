import SwiftUI

@main
struct TasteRankApp: App {
    @StateObject private var store = MockTasteRankStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
