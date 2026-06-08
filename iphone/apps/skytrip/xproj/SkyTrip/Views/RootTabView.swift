import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: AppStore

    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var tripsViewModel: TripsViewModel
    @StateObject private var walletViewModel: WalletViewModel
    @StateObject private var moreViewModel: MoreViewModel

    init(store: AppStore) {
        self.store = store
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(store: store))
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(store: store))
        _tripsViewModel = StateObject(wrappedValue: TripsViewModel(store: store))
        _walletViewModel = StateObject(wrappedValue: WalletViewModel(store: store))
        _moreViewModel = StateObject(wrappedValue: MoreViewModel(store: store))
    }

    var body: some View {
        TabView(selection: $store.selectedTab) {
            HomeView(viewModel: homeViewModel)
                .tag(AppTab.home)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                        .accessibilityIdentifier("tab_home")
                }

            SearchView(viewModel: searchViewModel)
                .tag(AppTab.search)
                .tabItem {
                    Label("Book", systemImage: "magnifyingglass")
                        .accessibilityIdentifier("tab_search")
                }

            TripsView(viewModel: tripsViewModel)
                .tag(AppTab.trips)
                .tabItem {
                    Label("My Trips", systemImage: "suitcase.fill")
                        .accessibilityIdentifier("tab_trips")
                }

            WalletView(viewModel: walletViewModel)
                .tag(AppTab.wallet)
                .tabItem {
                    Label("SkyMiles", systemImage: "star.circle.fill")
                        .accessibilityIdentifier("tab_wallet")
                }

            MoreView(viewModel: moreViewModel)
                .tag(AppTab.more)
                .tabItem {
                    Label("More", systemImage: "line.3.horizontal")
                        .accessibilityIdentifier("tab_more")
                }
        }
        .tint(SkyTripTheme.red)
        .toolbarBackground(SkyTripTheme.navy, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

struct AppInfoSheetItem: Identifiable {
    let id: String
    let title: String
    let message: String
}

struct AppInfoSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let item: AppInfoSheetItem

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(item.message)
                    .font(.body)
                    .foregroundStyle(SkyTripTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .accessibilityIdentifier("\(item.id)_message")
            }
            .background(SkyTripTheme.surface)
            .navigationTitle(item.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("\(item.id)_done_button")
                }
            }
        }
    }
}

struct AlertsCenterView: View {
    @Environment(\.dismiss) private var dismiss

    let alerts: [TravelAlert]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if alerts.isEmpty {
                        Text("No active alerts")
                            .font(.subheadline)
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(SkyTripTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityIdentifier("alerts_center_empty_state")
                    } else {
                        ForEach(alerts.sorted(by: { $0.publishedAt > $1.publishedAt })) { alert in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(alert.title)
                                        .font(.headline)
                                        .foregroundStyle(SkyTripTheme.textPrimary)
                                        .accessibilityIdentifier("alerts_center_title_\(alert.id)")
                                    Spacer()
                                    Text(alert.severity.rawValue.capitalized)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(SkyTripTheme.alertChipColor(for: alert.severity))
                                        .foregroundStyle(SkyTripTheme.alertTextColor(for: alert.severity))
                                        .clipShape(Capsule())
                                        .accessibilityIdentifier("alerts_center_chip_\(alert.id)")
                                }

                                Text(alert.message)
                                    .font(.subheadline)
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                                    .accessibilityIdentifier("alerts_center_message_\(alert.id)")

                                Text(AppFormatters.full(alert.publishedAt))
                                    .font(.caption)
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                                    .accessibilityIdentifier("alerts_center_published_\(alert.id)")
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(SkyTripTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityIdentifier("alerts_center_row_\(alert.id)")
                        }
                    }
                }
                .padding()
            }
            .background(SkyTripTheme.surface)
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("alerts_center_done_button")
                }
            }
        }
    }
}
