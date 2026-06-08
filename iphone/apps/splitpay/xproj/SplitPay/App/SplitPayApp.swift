import SwiftUI

@main
struct SplitPayApp: App {
    @StateObject private var store = SplitPayStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
