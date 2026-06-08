import SwiftUI

struct FoodLogView: View {
    @ObservedObject var viewModel: FoodLogViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Today")
                        .font(.headline)
                        .foregroundStyle(FitnessTheme.secondaryText)

                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(viewModel.todayLog.consumedCalories)")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(FitnessTheme.deepText)
                                .accessibilityIdentifier("food_daily_total_calories_label")
                            Text("calories logged")
                                .font(.subheadline)
                                .foregroundStyle(FitnessTheme.secondaryText)
                            Text("\(viewModel.remainingCalories) remaining")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(FitnessTheme.accent)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            macroSnapshot(title: "Protein", value: viewModel.todayLog.nutritionTotals.protein, tint: FitnessTheme.accent)
                            macroSnapshot(title: "Carbs", value: viewModel.todayLog.nutritionTotals.carbs, tint: FitnessTheme.accentWarm)
                            macroSnapshot(title: "Fat", value: viewModel.todayLog.nutritionTotals.fat, tint: FitnessTheme.accentRose)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FitnessTheme.heroGradient.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }

            Section("Meals") {
                ForEach(viewModel.mealSummaries) { summary in
                    NavigationLink {
                        MealDetailView(viewModel: viewModel, mealType: summary.mealType)
                    } label: {
                        HStack {
                            Image(systemName: summary.mealType.systemImage)
                                .font(.headline)
                                .foregroundStyle(FitnessTheme.color(forMeal: summary.mealType))
                                .frame(width: 38, height: 38)
                                .background(FitnessTheme.color(forMeal: summary.mealType).opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.mealType.rawValue)
                                    .font(.headline)
                                Text(summary.itemCount == 0 ? "Empty meal" : "\(summary.itemCount) food items")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(summary.totalCalories) cal")
                                .font(.subheadline.weight(.semibold))
                                .accessibilityIdentifier("food_meal_\(AccessibilityID.meal(summary.mealType))_calories_label")
                        }
                    }
                    .accessibilityIdentifier("meal_\(AccessibilityID.meal(summary.mealType))_row")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FitnessTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle("Food")
        .accessibilityIdentifier("screen_food")
    }

    private func macroSnapshot(title: String, value: Double, tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
            Text("\(AppFormatters.displayNumber(value)) g")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

struct MealDetailView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    let mealType: MealType

    @State private var showSearch = false

    private var entries: [MealEntry] {
        viewModel.mealEntries(for: mealType)
    }

    private var totalCalories: Int {
        entries.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(mealType.rawValue) Total")
                        .font(.headline)
                    Text("\(totalCalories) cal")
                        .font(.title2.weight(.semibold))
                        .accessibilityIdentifier("meal_\(AccessibilityID.meal(mealType))_total_calories_label")
                }
                .padding(.vertical, 6)
            }

            Section {
                if entries.isEmpty {
                    Text("No foods logged for \(mealType.rawValue.lowercased()) yet.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("meal_empty_state_\(AccessibilityID.meal(mealType))")
                } else {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            LoggedFoodEditorView(viewModel: viewModel, entry: entry)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.foodName)
                                        .font(.headline)
                                    Text("\(AppFormatters.displayNumber(entry.quantity)) x \(entry.servingSize)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(entry.calories) cal")
                                    .font(.subheadline.weight(.semibold))
                                    .accessibilityIdentifier("meal_\(AccessibilityID.meal(mealType))_entry_calories_\(String(format: "%03d", index + 1))")
                            }
                        }
                        .accessibilityIdentifier("meal_\(AccessibilityID.meal(mealType))_entry_row_\(String(format: "%03d", index + 1))")
                    }
                }
            }

            Section("Suggested for \(mealType.rawValue)") {
                ForEach(Array(viewModel.suggestedFoods(for: mealType).enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.systemImageName)
                            .font(.headline)
                            .foregroundStyle(FitnessTheme.color(for: entry))
                            .frame(width: 38, height: 38)
                            .background(FitnessTheme.color(for: entry).opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.foodName)
                                .font(.subheadline.weight(.semibold))
                            Text("\(entry.servingSize) • \(entry.calories) cal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            _ = viewModel.addFood(entry, quantity: 1, to: mealType)
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(FitnessTheme.color(for: entry))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("meal_suggested_add_button_\(String(format: "%03d", index + 1))")
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Button("Add Food") {
                    showSearch = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("meal_\(AccessibilityID.meal(mealType))_add_food_button")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FitnessTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle(mealType.rawValue)
        .sheet(isPresented: $showSearch) {
            NavigationStack {
                FoodSearchView(viewModel: viewModel, mealType: mealType)
            }
        }
    }
}

struct FoodSearchView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    let mealType: MealType

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [FoodDatabaseEntry] {
        Array(viewModel.searchFoods(query).prefix(20))
    }

    var body: some View {
        List {
            Section {
                TextField("Search foods", text: $query)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier("food_search_field")
            }

            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !viewModel.recentFoods.isEmpty {
                    Section("Recent Foods") {
                        ForEach(Array(viewModel.recentFoods.enumerated()), id: \.element.id) { index, entry in
                            NavigationLink {
                                FoodDatabaseDetailView(viewModel: viewModel, food: entry, mealType: mealType)
                            } label: {
                                FoodResultRow(entry: entry, index: index)
                            }
                            .accessibilityIdentifier("food_recent_row_\(String(format: "%03d", index + 1))")
                        }
                    }
                }

                Section("Common Foods") {
                    ForEach(Array(viewModel.commonFoods.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            FoodDatabaseDetailView(viewModel: viewModel, food: entry, mealType: mealType)
                        } label: {
                            FoodResultRow(entry: entry, index: index)
                        }
                        .accessibilityIdentifier("food_common_row_\(String(format: "%03d", index + 1))")
                    }
                }
            } else if results.isEmpty {
                Section {
                    Text("No foods found. Try a broader search.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("food_search_empty_state")
                }
            } else {
                Section("Food Database Results") {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            FoodDatabaseDetailView(viewModel: viewModel, food: entry, mealType: mealType)
                        } label: {
                            FoodResultRow(entry: entry, index: index)
                        }
                        .accessibilityIdentifier("food_result_row_\(String(format: "%03d", index + 1))")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FitnessTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle("Search Food")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .accessibilityIdentifier("food_search_close_button")
            }
        }
    }
}

struct FoodDatabaseDetailView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    let food: FoodDatabaseEntry
    let mealType: MealType

    @Environment(\.dismiss) private var dismiss
    @State private var quantityText = "1.0"
    @State private var validationMessage: String?

    private var parsedQuantity: Double? {
        Double(quantityText.replacingOccurrences(of: ",", with: "."))
    }

    private var nutritionPreview: NutritionInfo {
        food.nutritionInfo.scaled(by: max(parsedQuantity ?? 1, 0))
    }

    var body: some View {
        Form {
            Section("Serving Size") {
                LabeledContent("Food", value: food.foodName)
                LabeledContent("Serving", value: food.servingSize)
                TextField("Quantity", text: $quantityText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("food_quantity_field")
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("food_serving_size_error")
                }
            }

            Section("Nutrition") {
                nutritionRow(title: "Calories", value: "\(nutritionPreview.calories)", id: "food_detail_calories_label")
                nutritionRow(title: "Protein", value: "\(AppFormatters.displayNumber(nutritionPreview.protein)) g", id: "food_detail_protein_label")
                nutritionRow(title: "Carbs", value: "\(AppFormatters.displayNumber(nutritionPreview.carbs)) g", id: "food_detail_carbs_label")
                nutritionRow(title: "Fat", value: "\(AppFormatters.displayNumber(nutritionPreview.fat)) g", id: "food_detail_fat_label")
                nutritionRow(title: "Fiber", value: "\(AppFormatters.displayNumber(nutritionPreview.fiber)) g", id: "food_detail_fiber_label")
                nutritionRow(title: "Sodium", value: "\(AppFormatters.displayNumber(nutritionPreview.sodium)) mg", id: "food_detail_sodium_label")
            }

            Section {
                Button("Add Food") {
                    guard let quantity = parsedQuantity, quantity > 0 else {
                        validationMessage = "Enter a valid serving size greater than 0."
                        return
                    }
                    validationMessage = nil
                    if viewModel.addFood(food, quantity: quantity, to: mealType) {
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("add_food_confirm_button")
            }
        }
        .navigationTitle(food.foodName)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .accessibilityIdentifier("add_food_cancel_button")
            }
        }
    }

    private func nutritionRow(title: String, value: String, id: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(id)
        }
    }
}

struct LoggedFoodEditorView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    let entry: MealEntry

    @Environment(\.dismiss) private var dismiss
    @State private var quantityText: String
    @State private var selectedMealType: MealType
    @State private var validationMessage: String?
    @State private var showDeleteConfirmation = false

    init(viewModel: FoodLogViewModel, entry: MealEntry) {
        self.viewModel = viewModel
        self.entry = entry
        _quantityText = State(initialValue: AppFormatters.displayNumber(entry.quantity))
        _selectedMealType = State(initialValue: entry.mealType)
    }

    private var parsedQuantity: Double? {
        Double(quantityText.replacingOccurrences(of: ",", with: "."))
    }

    private var nutritionPreview: NutritionInfo {
        entry.foodItem.nutritionInfo.scaled(by: max(parsedQuantity ?? entry.quantity, 0))
    }

    var body: some View {
        Form {
            Section("Food") {
                LabeledContent("Name", value: entry.foodName)
                LabeledContent("Serving", value: entry.servingSize)
            }

            Section("Entry") {
                Picker("Meal", selection: $selectedMealType) {
                    ForEach(MealType.allCases) { mealType in
                        Text(mealType.rawValue).tag(mealType)
                    }
                }
                .accessibilityIdentifier("edit_food_meal_picker")

                TextField("Quantity", text: $quantityText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("edit_food_quantity_field")
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("food_serving_size_error")
                }
            }

            Section("Nutrition") {
                nutritionRow(title: "Calories", value: "\(nutritionPreview.calories)")
                nutritionRow(title: "Protein", value: "\(AppFormatters.displayNumber(nutritionPreview.protein)) g")
                nutritionRow(title: "Carbs", value: "\(AppFormatters.displayNumber(nutritionPreview.carbs)) g")
                nutritionRow(title: "Fat", value: "\(AppFormatters.displayNumber(nutritionPreview.fat)) g")
                nutritionRow(title: "Fiber", value: "\(AppFormatters.displayNumber(nutritionPreview.fiber)) g")
                nutritionRow(title: "Sodium", value: "\(AppFormatters.displayNumber(nutritionPreview.sodium)) mg")
            }

            Section {
                Button("Save Changes") {
                    guard let quantity = parsedQuantity, quantity > 0 else {
                        validationMessage = "Enter a valid serving size greater than 0."
                        return
                    }
                    validationMessage = nil
                    if viewModel.updateMealEntry(entryID: entry.id, quantity: quantity, mealType: selectedMealType) {
                        dismiss()
                    }
                }
                .accessibilityIdentifier("edit_food_save_button")
            }

            Section {
                Button("Remove Food", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .accessibilityIdentifier("edit_food_delete_button")
            }
        }
        .navigationTitle(entry.foodName)
        .alert("Remove Food?", isPresented: $showDeleteConfirmation) {
            Button("Remove", role: .destructive) {
                viewModel.removeMealEntry(entryID: entry.id)
                dismiss()
            }
            .accessibilityIdentifier("remove_food_confirm_button")

            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("remove_food_cancel_button")
        } message: {
            Text("This will delete the logged food entry from the meal.")
        }
    }

    private func nutritionRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}

struct FoodResultRow: View {
    let entry: FoodDatabaseEntry
    let index: Int

    var body: some View {
        HStack {
            Image(systemName: entry.systemImageName)
                .font(.headline)
                .foregroundStyle(FitnessTheme.color(for: entry))
                .frame(width: 40, height: 40)
                .background(FitnessTheme.color(for: entry).opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.headline)
                Text(entry.servingSize)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("P \(AppFormatters.displayNumber(entry.protein))g  C \(AppFormatters.displayNumber(entry.carbs))g  F \(AppFormatters.displayNumber(entry.fat))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.calories) cal")
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("food_result_calories_\(String(format: "%03d", index + 1))")
        }
    }
}
