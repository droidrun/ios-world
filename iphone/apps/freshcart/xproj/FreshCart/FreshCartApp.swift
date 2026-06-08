import SwiftUI

@main
struct FreshCartApp: App {
    @StateObject private var store = FreshCartStore()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
        }
    }
}
