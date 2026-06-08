import SwiftUI

struct FilterSheetView: View {
    @EnvironmentObject var store: MockTasteRankStore
    @Binding var filterState: FilterState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    cuisineSection
                    priceSection
                    distanceSection
                    toggleSection
                    visitedSection
                }
                .padding(20)
            }
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("filters_done")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        filterState = .default
                    }
                    .accessibilityIdentifier("filters_reset")
                }
            }
        }
    }

    private var cuisineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cuisine")
                .font(MockTasteRankTheme.titleFont(size: 16))
                .accessibilityIdentifier("filters_cuisine_header")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                ForEach(store.cuisines) { cuisine in
                    FilterChip(
                        title: cuisine.name,
                        isSelected: filterState.selectedCuisineIDs.contains(cuisine.id),
                        accessibilityID: "filters_cuisine_\(cuisine.id)"
                    ) {
                        toggleCuisine(cuisine.id)
                    }
                    .accessibilityIdentifier("filters_cuisine_\(cuisine.id)")
                }
            }
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price")
                .font(MockTasteRankTheme.titleFont(size: 16))
                .accessibilityIdentifier("filters_price_header")
            HStack(spacing: 8) {
                ForEach(1..<5) { level in
                    FilterChip(
                        title: String(repeating: "$", count: level),
                        isSelected: filterState.selectedPriceLevels.contains(level),
                        accessibilityID: "filters_price_\(level)"
                    ) {
                        togglePrice(level)
                    }
                    .accessibilityIdentifier("filters_price_\(level)")
                }
            }
        }
    }

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distance")
                .font(MockTasteRankTheme.titleFont(size: 16))
                .accessibilityIdentifier("filters_distance_header")
            Picker("Distance", selection: Binding(
                get: { distanceSelection },
                set: { updateDistanceSelection($0) }
            )) {
                Text("Any").tag(0)
                Text("5 mi").tag(5)
                Text("10 mi").tag(10)
                Text("20 mi").tag(20)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("filters_distance_picker")
        }
    }

    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Open now", isOn: $filterState.openNowOnly)
                .accessibilityIdentifier("filters_open_now")
        }
    }

    private var visitedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visited")
                .font(MockTasteRankTheme.titleFont(size: 16))
                .accessibilityIdentifier("filters_visited_header")
            Picker("Visited", selection: $filterState.visitedFilter) {
                ForEach(VisitedFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("filters_visited_picker")
        }
    }

    private var distanceSelection: Int {
        Int(filterState.maxDistanceMiles ?? 0)
    }

    private func updateDistanceSelection(_ value: Int) {
        filterState.maxDistanceMiles = value == 0 ? nil : Double(value)
    }

    private func toggleCuisine(_ id: String) {
        if filterState.selectedCuisineIDs.contains(id) {
            filterState.selectedCuisineIDs.remove(id)
        } else {
            filterState.selectedCuisineIDs.insert(id)
        }
    }

    private func togglePrice(_ level: Int) {
        if filterState.selectedPriceLevels.contains(level) {
            filterState.selectedPriceLevels.remove(level)
        } else {
            filterState.selectedPriceLevels.insert(level)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var accessibilityID: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MockTasteRankTheme.bodyFont(size: 12))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundColor(isSelected ? .white : MockTasteRankTheme.textPrimary)
                .background(isSelected ? MockTasteRankTheme.accent : MockTasteRankTheme.accentSoft)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        // Collapse the chip into a single a11y element when an explicit
        // identifier is supplied, otherwise the inner Text's label (the cuisine
        // / price name, e.g. "Italian") wins as the WDA accessibility name and
        // the filters_cuisine_<id> / filters_price_<level> identifier set on the
        // wrapper never surfaces -- making the chip untappable by id. Mirrors the
        // TasteRankIconButton fix in Theme.swift.
        .accessibilityElement(children: accessibilityID == nil ? .contain : .ignore)
        .accessibilityIdentifier(accessibilityID ?? "")
        .accessibilityLabel(accessibilityID == nil ? "" : title)
    }
}
