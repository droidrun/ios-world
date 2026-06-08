import SwiftUI

private struct PriceLevelTier {
    let level: Int
    let label: String
    let min: Double
    let max: Double
}

private let priceLevels: [PriceLevelTier] = [
    PriceLevelTier(level: 1, label: "$",    min: 0,   max: 50),
    PriceLevelTier(level: 2, label: "$$",   min: 50,  max: 100),
    PriceLevelTier(level: 3, label: "$$$",  min: 100, max: 200),
    PriceLevelTier(level: 4, label: "$$$$", min: 200, max: 400),
]

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MockTicketBoxStore.self) var store
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        let categoryBinding = Binding<String>(
            get: { viewModel.filterState.category?.rawValue ?? "All" },
            set: { value in viewModel.filterState.category = value == "All" ? nil : EventCategory(rawValue: value) }
        )
        let cityBinding = Binding<String>(
            get: { viewModel.filterState.city ?? "All" },
            set: { value in viewModel.filterState.city = value == "All" ? nil : value }
        )

        Form {
            Section(header: Text("Date Range")) {
                Picker("Date", selection: $viewModel.filterState.dateRange) {
                    ForEach(DateRangeFilter.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("filter.date")
            }

            Section(header: Text("Category")) {
                Picker("Category", selection: categoryBinding) {
                    Text("All").tag("All")
                    ForEach(EventCategory.allCases) { category in
                        Text(category.rawValue).tag(category.rawValue)
                    }
                }
                .accessibilityIdentifier("filter.category")
            }

            Section(header: Text("City")) {
                Picker("City", selection: cityBinding) {
                    Text("All").tag("All")
                    ForEach(store.cities, id: \.self) { city in
                        Text(city).tag(city)
                    }
                }
                .accessibilityIdentifier("filter.city")
            }

            Section(header: Text("Price Range")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Min \(Formatters.price(viewModel.filterState.minPrice))")
                        .accessibilityIdentifier("filter.price.min")
                    Slider(
                        value: $viewModel.filterState.minPrice,
                        in: 0...viewModel.filterState.maxPrice,
                        step: 5
                    )
                    Text("Max \(Formatters.price(viewModel.filterState.maxPrice))")
                        .accessibilityIdentifier("filter.price.max")
                    Slider(
                        value: $viewModel.filterState.maxPrice,
                        in: viewModel.filterState.minPrice...400,
                        step: 5
                    )

                    // Discrete price-level tap targets. These are additive
                    // shortcuts that snap the min/max range to a common
                    // budget tier; the slider UI above remains the
                    // primary visual control.
                    HStack(spacing: 8) {
                        ForEach(priceLevels, id: \.level) { tier in
                            Button(action: {
                                viewModel.filterState.minPrice = tier.min
                                viewModel.filterState.maxPrice = tier.max
                            }) {
                                Text(tier.label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("filter_price_level_\(tier.level)")
                        }
                    }
                    .padding(.top, 4)
                }
                .accessibilityIdentifier("filter.price")
            }

            Section(header: Text("Delivery")) {
                Toggle("Only show instant delivery", isOn: $viewModel.filterState.instantOnly)
                    .accessibilityIdentifier("filter.instant")
            }

            Section {
                Button("Reset Filters") {
                    viewModel.filterState = .default
                }
                .accessibilityIdentifier("filter.reset")
            }
        }
        .navigationTitle("Filters")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .accessibilityIdentifier("filter.done")
            }
        }
    }
}
