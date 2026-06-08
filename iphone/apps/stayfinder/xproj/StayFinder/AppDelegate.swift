import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let rootController = SfTabBarController()
        window.rootViewController = rootController
        window.makeKeyAndVisible()
        self.window = window
        handleUITestRouteIfNeeded(rootController)
        return true
    }

    private func handleUITestRouteIfNeeded(_ rootController: SfTabBarController) {
        let arguments = ProcessInfo.processInfo.arguments
        rootController.performWhenReady {
            if arguments.contains("-bnb-ui-test-open-search"),
               let navigationController = rootController.viewControllers?.first as? UINavigationController,
               let explore = navigationController.viewControllers.first as? ExploreViewController {
                rootController.selectedIndex = 0
                explore.presentSearchPanelForTesting()
                return
            }

            if let index = arguments.firstIndex(of: "-bnb-ui-test-open-listing"),
               index + 1 < arguments.count,
               let navigationController = rootController.viewControllers?.first as? UINavigationController,
               let explore = navigationController.viewControllers.first as? ExploreViewController {
                rootController.selectedIndex = 0
                explore.openListingForTesting(arguments[index + 1])
                return
            }

            if let index = arguments.firstIndex(of: "-bnb-ui-test-open-booking"),
               index + 1 < arguments.count,
               let navigationController = rootController.viewControllers?.first as? UINavigationController,
               let explore = navigationController.viewControllers.first as? ExploreViewController {
                rootController.selectedIndex = 0
                explore.openBookingForTesting(arguments[index + 1])
                return
            }

            if let index = arguments.firstIndex(of: "-bnb-ui-test-open-checkout"),
               index + 1 < arguments.count,
               let navigationController = rootController.viewControllers?.first as? UINavigationController,
               let explore = navigationController.viewControllers.first as? ExploreViewController {
                rootController.selectedIndex = 0
                explore.openCheckoutForTesting(arguments[index + 1])
                return
            }

            if let index = arguments.firstIndex(of: "-bnb-ui-test-open-conversation"),
               index + 1 < arguments.count,
               let navigationController = rootController.viewControllers?[3] as? UINavigationController,
               let inbox = navigationController.viewControllers.first as? InboxViewController {
                rootController.selectedIndex = 3
                inbox.openConversationForTesting(listingID: arguments[index + 1])
                return
            }

            if arguments.contains("-bnb-ui-test-open-past-trips"),
               let navigationController = rootController.viewControllers?[4] as? UINavigationController,
               let profile = navigationController.viewControllers.first as? ProfileViewController {
                rootController.selectedIndex = 4
                profile.openPastTripsForTesting()
                return
            }

            if arguments.contains("-bnb-ui-test-open-notifications"),
               let navigationController = rootController.viewControllers?[4] as? UINavigationController,
               let profile = navigationController.viewControllers.first as? ProfileViewController {
                rootController.selectedIndex = 4
                profile.openNotificationsForTesting()
                return
            }

            if arguments.contains("-bnb-ui-test-open-hosting"),
               let navigationController = rootController.viewControllers?[4] as? UINavigationController,
               let profile = navigationController.viewControllers.first as? ProfileViewController {
                rootController.selectedIndex = 4
                profile.openHostingForTesting()
            }
        }
    }
}
