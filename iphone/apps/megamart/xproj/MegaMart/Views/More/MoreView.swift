import SwiftUI

struct MoreView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private let categoryCards: [MegaMartCategoryCard] = [
        .init(title: "Prime", query: "prime", symbol: "shippingbox.fill", accent: Color(red: 214 / 255, green: 183 / 255, blue: 126 / 255)),
        .init(title: "Office &\nWorkspace", query: "office", symbol: "pencil.and.ruler.fill", accent: Color(red: 194 / 255, green: 115 / 255, blue: 92 / 255)),
        .init(title: "Fitness &\nOutdoor", query: "fitness", symbol: "figure.run", accent: Color(red: 38 / 255, green: 121 / 255, blue: 108 / 255)),
        .init(title: "Deals &\nSavings", query: "deals", symbol: "tag.fill", accent: Color(red: 48 / 255, green: 48 / 255, blue: 48 / 255)),
        .init(title: "Groceries &\nStores", query: "groceries", symbol: "cart.fill", accent: Color(red: 128 / 255, green: 179 / 255, blue: 87 / 255)),
        .init(title: "Pets", query: "pet supplies", symbol: "pawprint.fill", accent: Color(red: 162 / 255, green: 143 / 255, blue: 127 / 255)),
        .init(title: "Fashion &\nBeauty", query: "beauty", symbol: "sparkles", accent: Color(red: 229 / 255, green: 109 / 255, blue: 167 / 255)),
        .init(title: "Home,\nGarden &\nTools", query: "home", symbol: "chair.fill", accent: Color(red: 210 / 255, green: 171 / 255, blue: 52 / 255)),
        .init(title: "Devices &\nElectronics", query: "electronics", symbol: "desktopcomputer", accent: Color(red: 111 / 255, green: 178 / 255, blue: 202 / 255)),
        .init(title: "Music, Video\n& Gaming", query: "ps5", symbol: "gamecontroller.fill", accent: Color(red: 91 / 255, green: 137 / 255, blue: 226 / 255)),
        .init(title: "Books &\nReading", query: "books", symbol: "books.vertical.fill", accent: Color(red: 192 / 255, green: 124 / 255, blue: 100 / 255)),
        .init(title: "Toys, Kids &\nBaby", query: "toys", symbol: "balloon.2.fill", accent: Color(red: 233 / 255, green: 174 / 255, blue: 66 / 255))
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Shop by category")
                    .font(.system(size: 30, weight: .bold))
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(categoryCards) { card in
                        NavigationLink {
                            SearchView(initialRequest: SearchNavigationRequest(query: card.query, departmentID: nil, categoryID: nil))
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(card.title)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                ZStack(alignment: .bottom) {
                                    Circle()
                                        .fill(Color(red: 230 / 255, green: 241 / 255, blue: 246 / 255))
                                        .frame(width: 86, height: 86)
                                        .offset(y: 18)

                                    MegaMartCategoryArtwork(query: card.query, fallbackSystemImage: card.symbol)
                                        .frame(width: 82, height: 82)
                                        .padding(.bottom, 4)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(MegaMartTheme.searchBorder, lineWidth: 1.5)
                                    )
                                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 80)
            }
        }
        .background(MegaMartTheme.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            MegaMartScreenHeader(
                destination: SearchView(initialRequest: SearchNavigationRequest(query: "", departmentID: nil, categoryID: nil)),
                text: "Search MegaMart"
            )
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct MegaMartSettingsView: View {
    @EnvironmentObject private var store: MegaMartStore
    @StateObject private var viewModel = MoreViewModel()

    var body: some View {
        List {
            Section("Catalog source") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.catalogSourceLabel)
                        .font(.headline)
                        .accessibilityIdentifier("current_catalog_source")
                    Text("Catalog source file: \(store.snapshotLocationLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let metadata = store.state.snapshotMetadata {
                        Text("Catalog updated \(Formatters.detailDate(metadata.lastUpdated))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Use Standard Catalog") {
                    store.setCatalogSource(.seeded)
                }
                .accessibilityIdentifier("catalog_source_seeded")

                Button("Use Imported Catalog") {
                    store.setCatalogSource(.snapshot)
                }
                .accessibilityIdentifier("catalog_source_snapshot")

                Button("Reload Bundled Snapshot Data") {
                    store.reloadBundledSnapshotData()
                }
                .accessibilityIdentifier("reload_bundled_snapshot_data")
            }

            Section("Order lifecycle controls") {
                Button("Advance First Active Order") {
                    store.advanceFirstActiveOrder()
                }
                .accessibilityIdentifier("advance_first_active_order")

                Button("Advance All Active Orders") {
                    store.advanceAllActiveOrders()
                }
                .accessibilityIdentifier("advance_all_active_orders")
            }

            Section("Reset and persistence") {
                Button("Reset App State") {
                    viewModel.showResetConfirmation = true
                }
                .foregroundStyle(.red)
                .accessibilityIdentifier("account_reset_app_state")
            }

            Section("About") {
                Text("This app keeps catalog and order data on device for repeatable shopping flows.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Products in current catalog: \(store.catalog.products.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Orders stored locally: \(store.state.orders.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("App Settings")
        .alert("Reset app state?", isPresented: $viewModel.showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetAppState()
            }
        } message: {
            Text("This clears saved app data and restores the default state.")
        }
    }
}

private struct MegaMartCategoryCard: Identifiable {
    let id = UUID()
    let title: String
    let query: String
    let symbol: String
    let accent: Color
}
