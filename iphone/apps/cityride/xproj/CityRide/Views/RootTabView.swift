import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: CityRideStore

    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var requestViewModel: RequestViewModel
    @StateObject private var activityViewModel: ActivityViewModel
    @StateObject private var walletViewModel: WalletViewModel
    @StateObject private var accountViewModel: AccountViewModel
    @StateObject private var moreViewModel: MoreViewModel

    init(store: CityRideStore) {
        self.store = store
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(store: store))
        _requestViewModel = StateObject(wrappedValue: RequestViewModel(store: store))
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(store: store))
        _walletViewModel = StateObject(wrappedValue: WalletViewModel(store: store))
        _accountViewModel = StateObject(wrappedValue: AccountViewModel(store: store))
        _moreViewModel = StateObject(wrappedValue: MoreViewModel(store: store))
    }

    private var activityBadge: Int {
        store.activeTrips.count + store.upcomingTrips.count
    }

    private var walletBadge: Int {
        store.state.walletState.promotions.filter(\.isActive).count
    }

    var body: some View {
        TabView {
            HomeView(homeViewModel: homeViewModel, requestViewModel: requestViewModel)
                .accessibilityIdentifier("tab_home")
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ActivityView(viewModel: activityViewModel)
                .accessibilityIdentifier("tab_activity")
                .tabItem {
                    Label("Activity", systemImage: "clock.arrow.circlepath")
                }
                .badge(activityBadge > 0 ? activityBadge : 0)

            WalletView(viewModel: walletViewModel)
                .accessibilityIdentifier("tab_wallet")
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }
                .badge(walletBadge > 0 ? walletBadge : 0)

            AccountView(viewModel: accountViewModel)
                .accessibilityIdentifier("tab_account")
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }

            MoreView(viewModel: moreViewModel)
                .accessibilityIdentifier("tab_more")
                .tabItem {
                    Label("Services", systemImage: "square.grid.2x2")
                }
        }
        .tint(.white)
        .toolbarBackground(CityRideTheme.panel, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .background(CityRideTheme.background.ignoresSafeArea())
    }
}
