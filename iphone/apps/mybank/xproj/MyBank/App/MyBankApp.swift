import SwiftUI

@main
struct MyBankApp: App {
    @StateObject private var store = BankStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .onOpenURL { url in
                    store.handleDeepLink(url)
                }
        }
    }
}
