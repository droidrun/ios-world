import SwiftUI

private enum HomeRoute: Hashable {
    case search(SearchNavigationRequest)
}

private enum AccountRoute: Hashable {
    case auth(AuthEntryMode)
    case orders
    case savedItems
    case settings
}

struct RootTabView: View {
    @EnvironmentObject private var store: MegaMartStore
    @State private var homePath: [HomeRoute] = []
    @State private var accountPath: [AccountRoute] = []

    var body: some View {
        ZStack {
            tabStack(for: .home) {
                NavigationStack(path: $homePath) {
                    HomeView()
                        .navigationDestination(for: HomeRoute.self) { route in
                            switch route {
                            case .search(let request):
                                SearchView(initialRequest: request)
                            }
                        }
                }
            }

            tabStack(for: .account) {
                NavigationStack(path: $accountPath) {
                    AccountView()
                        .navigationDestination(for: AccountRoute.self) { route in
                            switch route {
                            case .auth(let mode):
                                AccountAuthView(mode: mode)
                            case .orders:
                                OrdersView()
                            case .savedItems:
                                SavedItemsListView()
                            case .settings:
                                MegaMartSettingsView()
                            }
                        }
                }
            }

            tabStack(for: .cart) {
                NavigationStack {
                    CartView()
                }
            }

            tabStack(for: .menu) {
                NavigationStack {
                    MoreView()
                }
            }
        }
        .background(MegaMartTheme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MegaMartBottomTabBar(selection: Binding(get: { store.selectedTab }, set: store.setSelectedTab(_:)))
                .environmentObject(store)
        }
        .overlay(alignment: .top) {
            if let message = store.inlineStatusMessage {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MegaMartTheme.linkBlue)
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button("Dismiss") {
                        store.dismissInlineMessage()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegaMartTheme.linkBlue)
                    .accessibilityIdentifier("inline_status_dismiss")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
                )
                .padding(.horizontal, 16)
                .padding(.top, store.selectedTab == .home ? 92 : 10)
                .accessibilityIdentifier("inline_status_banner")
            }
        }
        .onAppear {
            normalizeSelectionIfNeeded()
        }
        .onChange(of: store.searchNavigationRequest) { _, request in
            guard let request else { return }
            store.setSelectedTab(.home)
            homePath.append(.search(request))
        }
        .onChange(of: store.accountNavigationRequest) { _, request in
            guard let request else { return }
            store.setSelectedTab(.account)
            switch request.target {
            case .auth(let mode):
                accountPath.append(.auth(mode))
            case .orders:
                accountPath.append(.orders)
            case .savedItems:
                accountPath.append(.savedItems)
            case .settings:
                accountPath.append(.settings)
            }
        }
    }

    @ViewBuilder
    private func tabStack<Content: View>(for tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(store.selectedTab == tab ? 1 : 0)
            .allowsHitTesting(store.selectedTab == tab)
            .accessibilityHidden(store.selectedTab != tab)
    }

    private func normalizeSelectionIfNeeded() {
        if store.selectedTab == .search {
            store.setSelectedTab(.home)
        } else if store.selectedTab == .orders {
            store.setSelectedTab(.account)
        }
    }
}

enum MegaMartTheme {
    static let header = Color(red: 231 / 255, green: 187 / 255, blue: 128 / 255)
    static let headerAccent = Color(red: 226 / 255, green: 183 / 255, blue: 119 / 255)
    static let background = Color(red: 245 / 255, green: 246 / 255, blue: 248 / 255)
    static let searchBorder = Color(red: 154 / 255, green: 178 / 255, blue: 186 / 255)
    static let linkBlue = Color(red: 35 / 255, green: 104 / 255, blue: 178 / 255)
    static let amazonYellow = Color(red: 247 / 255, green: 210 / 255, blue: 0 / 255)
    static let cardBorder = Color(red: 214 / 255, green: 218 / 255, blue: 220 / 255)
    static let mutedText = Color(red: 95 / 255, green: 102 / 255, blue: 105 / 255)
}

struct MegaMartSearchBarVisual: View {
    let text: String
    var showBackButton = false
    var textColor: Color = .secondary

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 390

            HStack(spacing: compact ? 8 : 10) {
                if showBackButton {
                    Image(systemName: "arrow.left")
                        .font(.system(size: compact ? 18 : 20, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 28, height: 28)
                }

                HStack(spacing: compact ? 8 : 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: compact ? 16 : 18, weight: .medium))
                        .foregroundStyle(MegaMartTheme.mutedText)

                    Text(text)
                        .font(.system(size: compact ? 16 : 17, weight: .regular))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .layoutPriority(1)

                    Spacer(minLength: 4)

                    Image(systemName: "mic.fill")
                        .font(.system(size: compact ? 16 : 18, weight: .medium))
                        .foregroundStyle(MegaMartTheme.mutedText)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: compact ? 18 : 20, weight: .medium))
                        .foregroundStyle(MegaMartTheme.mutedText)
                }
                .padding(.horizontal, compact ? 12 : 14)
                .padding(.vertical, compact ? 10 : 12)
                .background(
                    RoundedRectangle(cornerRadius: compact ? 10 : 12)
                        .fill(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: compact ? 10 : 12)
                                .stroke(MegaMartTheme.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
                )
            }
            .padding(.horizontal, compact ? 12 : 16)
            .padding(.vertical, compact ? 8 : 10)
            .background(MegaMartTheme.header)
        }
        .frame(height: 84)
    }
}

struct MegaMartScreenHeader<Destination: View>: View {
    let destination: Destination
    let text: String
    var body: some View {
        NavigationLink {
            destination
        } label: {
            MegaMartSearchBarVisual(text: text)
        }
        .buttonStyle(.plain)
    }
}

private struct MegaMartBottomTabBar: View {
    @EnvironmentObject private var store: MegaMartStore
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(icon: "house", label: "Home", tab: .home, identifier: "tab_home")
            tabButton(icon: "person", label: "You", tab: .account, identifier: "tab_account")
            tabButton(icon: "cart", label: "Cart", tab: .cart, identifier: "tab_cart", badge: store.cartItemCount > 0 ? store.cartItemCount : nil)
            tabButton(icon: "line.3.horizontal", label: "Menu", tab: .menu, identifier: "tab_menu")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(.white)
                .overlay(alignment: .top) {
                    Divider()
                }
        )
    }

    private func tabButton(icon: String, label: String, tab: AppTab, identifier: String, badge: Int? = nil) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Capsule()
                    .fill(selection == tab ? Color.black : Color.clear)
                    .frame(width: 64, height: 7)

                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.black)

                    if let badge {
                        Text("\(badge)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .offset(x: 10, y: -8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 28)

                Text(label)
                    .font(.system(size: 10, weight: selection == tab ? .bold : .medium))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
