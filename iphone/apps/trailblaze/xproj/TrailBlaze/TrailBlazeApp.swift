import SwiftUI
import UIKit

@main
struct TrailBlazeApp: App {
    @StateObject private var appState = AppState()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 0.98)

        let selectedColor = UIColor(red: 0.98, green: 0.37, blue: 0.08, alpha: 1)
        let normalColor = UIColor(white: 1, alpha: 0.72)

        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance].forEach { tabAppearance in
            tabAppearance.normal.iconColor = normalColor
            tabAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
            tabAppearance.selected.iconColor = selectedColor
            tabAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
