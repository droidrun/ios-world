import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: FreshCartStore

    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var browseViewModel: BrowseViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var cartViewModel: CartViewModel
    @StateObject private var ordersViewModel: OrdersViewModel
    @StateObject private var accountViewModel: AccountViewModel
    @StateObject private var moreViewModel: MoreViewModel

    init(store: FreshCartStore) {
        self.store = store
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(store: store))
        _browseViewModel = StateObject(wrappedValue: BrowseViewModel(store: store))
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(store: store))
        _cartViewModel = StateObject(wrappedValue: CartViewModel(store: store))
        _ordersViewModel = StateObject(wrappedValue: OrdersViewModel(store: store))
        _accountViewModel = StateObject(wrappedValue: AccountViewModel(store: store))
        _moreViewModel = StateObject(wrappedValue: MoreViewModel(store: store))
    }

    private var cartBadgeCount: Int {
        store.state.cartItems.reduce(0) { $0 + $1.quantity }
    }

    var body: some View {
        TabView(selection: Binding(
            get: { store.state.selectedTab },
            set: { store.switchTab($0) }
        )) {
            NavigationStack {
                HomeView(homeViewModel: homeViewModel, browseViewModel: browseViewModel, searchViewModel: searchViewModel)
            }
            .tag(AppTab.home)
            .tabItem {
                Label("Stores", systemImage: "storefront.fill")
                    .accessibilityIdentifier("tab_home")
            }

            NavigationStack {
                SearchView(viewModel: searchViewModel)
            }
            .tag(AppTab.search)
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
                    .accessibilityIdentifier("tab_search")
            }

            NavigationStack {
                CartView(viewModel: cartViewModel)
            }
            .tag(AppTab.cart)
            .tabItem {
                Label("Cart", systemImage: "cart.fill")
                    .accessibilityIdentifier("tab_cart")
            }
            .badge(cartBadgeCount > 0 ? cartBadgeCount : 0)

            NavigationStack {
                OrdersView(viewModel: ordersViewModel)
            }
            .tag(AppTab.orders)
            .tabItem {
                Label("Orders", systemImage: "bag.fill")
                    .accessibilityIdentifier("tab_orders")
            }

            NavigationStack {
                AccountView(viewModel: accountViewModel, moreViewModel: moreViewModel)
            }
            .tag(AppTab.account)
            .tabItem {
                Label("Account", systemImage: "person.crop.circle")
                    .accessibilityIdentifier("tab_account")
            }
        }
        .tint(Color.instacartGreenDark)
        .overlay(alignment: .top) {
            if let message = store.inlineStatusMessage {
                Text(message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.black.opacity(0.82)))
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.25), value: store.inlineStatusMessage)
        .onChange(of: store.inlineStatusMessage) { _, newValue in
            guard newValue != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if store.inlineStatusMessage == newValue {
                    store.clearInlineStatusMessage()
                }
            }
        }
    }
}
