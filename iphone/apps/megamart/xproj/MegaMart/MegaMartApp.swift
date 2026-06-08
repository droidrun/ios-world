import SwiftUI

@main
struct MegaMartApp: App {
    @StateObject private var store = MegaMartStore()
    @StateObject private var deviceLocationManager = DeviceLocationManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(deviceLocationManager)
        }
    }
}
