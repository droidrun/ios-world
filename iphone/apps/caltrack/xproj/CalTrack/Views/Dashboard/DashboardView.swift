import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var foodLogViewModel: FoodLogViewModel
    @ObservedObject var exerciseViewModel: ExerciseViewModel

    @State private var showWeightSheet = false
    @State private var showWaterSheet = false
    @State private var showStepsSheet = false
    @State private var showExerciseSearch = false
    @State private var showQuickAdd = false
    @State private var foodSearchMealType: MealType?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    calorieHeader
                    macroRow
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        ForEach(MealType.allCases) { mealType in
                            mealSection(for: mealType)
                        }

                        exerciseSection
                        habitsSection
                    }

                    if let statusMessage = viewModel.store.inlineStatusMessage {
                        statusBanner(message: statusMessage)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(FitnessTheme.dashboardBackground.ignoresSafeArea())

            floatingAddButton
                .padding(.trailing, 20)
                .padding(.bottom, 16)
        }
        .navigationTitle("Today")
        .accessibilityIdentifier("screen_dashboard")
        .sheet(isPresented: $showWeightSheet) {
            NavigationStack {
                LogWeightSheetView(
                    title: "Log Weight",
                    initialWeightText: AppFormatters.editableWeight(
                        viewModel.store.state.userProfile.weight,
                        unitSystem: viewModel.store.state.userProfile.unitSystem
                    ),
                    unitSystem: viewModel.store.state.userProfile.unitSystem
                ) { pounds in
                    _ = viewModel.logWeight(pounds)
                }
            }
        }
        .sheet(isPresented: $showWaterSheet) {
            NavigationStack {
                MetricEditorSheetView(
                    title: "Hydration",
                    prompt: "Water cups",
                    initialValue: "\(viewModel.todayLog.waterCups)",
                    keyboardType: .numberPad,
                    unitLabel: "cups"
                ) { value in
                    _ = viewModel.updateWaterCups(value)
                }
            }
        }
        .sheet(isPresented: $showStepsSheet) {
            NavigationStack {
                MetricEditorSheetView(
                    title: "Steps",
                    prompt: "Step count",
                    initialValue: "\(viewModel.todayLog.stepCount)",
                    keyboardType: .numberPad,
                    unitLabel: "steps"
                ) { value in
                    _ = viewModel.updateStepCount(value)
                }
            }
        }
        .sheet(isPresented: $showExerciseSearch) {
            NavigationStack {
                ExerciseSearchView(viewModel: exerciseViewModel)
            }
        }
        .sheet(item: $foodSearchMealType) { mealType in
            NavigationStack {
                FoodSearchView(viewModel: foodLogViewModel, mealType: mealType)
            }
        }
        .confirmationDialog("Quick Add", isPresented: $showQuickAdd, titleVisibility: .visible) {
            Button("Food") { foodSearchMealType = .breakfast }
            Button("Exercise") { showExerciseSearch = true }
            Button("Water") { showWaterSheet = true }
            Button("Weight") { showWeightSheet = true }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Calorie Header

    private var calorieHeader: some View {
        VStack(spacing: 16) {
            CalorieRing(
                consumed: viewModel.consumedCalories,
                remaining: viewModel.remainingCalories,
                progress: viewModel.calorieProgress
            )

            calorieFormulaRow
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(FitnessTheme.heroGradient)
    }

    private var calorieFormulaRow: some View {
        HStack(spacing: 0) {
            CalorieFormulaItem(
                value: "\(viewModel.goal.goalCalories)",
                label: "Goal",
                systemImage: "flag.fill"
            )
            Spacer()
            Text("\u{2212}")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            CalorieFormulaItem(
                value: "\(viewModel.consumedCalories)",
                label: "Food",
                systemImage: "fork.knife"
            )
            Spacer()
            Text("+")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            CalorieFormulaItem(
                value: "\(viewModel.burnedCalories)",
                label: "Exercise",
                systemImage: "flame.fill"
            )
            Spacer()
            Text("=")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            CalorieFormulaItem(
                value: "\(viewModel.remainingCalories)",
                label: "Remaining",
                systemImage: "checkmark.circle.fill"
            )
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Macros

    private var macroRow: some View {
        HStack(spacing: 16) {
            MacroBar(
                label: "Protein",
                consumed: viewModel.todayLog.nutritionTotals.protein,
                goal: viewModel.goal.goalProtein,
                tint: FitnessTheme.accent
            )
            MacroBar(
                label: "Carbs",
                consumed: viewModel.todayLog.nutritionTotals.carbs,
                goal: viewModel.goal.goalCarbs,
                tint: FitnessTheme.accentWarm
            )
            MacroBar(
                label: "Fat",
                consumed: viewModel.todayLog.nutritionTotals.fat,
                goal: viewModel.goal.goalFat,
                tint: FitnessTheme.accentRose
            )
        }
    }

    // MARK: - Meal Sections

    private func mealSection(for mealType: MealType) -> some View {
        let entries = viewModel.mealEntries(for: mealType)
        let totalCalories = entries.reduce(0) { $0 + $1.calories }

        return VStack(spacing: 0) {
            HStack {
                Image(systemName: mealType.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FitnessTheme.color(forMeal: mealType))
                Text(mealType.rawValue)
                    .font(.headline)
                    .foregroundStyle(FitnessTheme.deepText)
                Spacer()
                Text("\(totalCalories)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FitnessTheme.secondaryText)
                Button {
                    foodSearchMealType = mealType
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FitnessTheme.accent)
                        .frame(width: 32, height: 32)
                }
                .accessibilityIdentifier("meal_\(AccessibilityID.meal(mealType))_add_button")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)

            Divider().padding(.leading, 16)

            if entries.isEmpty {
                Button {
                    foodSearchMealType = mealType
                } label: {
                    HStack {
                        Text("Add Food")
                            .font(.subheadline)
                            .foregroundStyle(FitnessTheme.accent)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("meal_\(AccessibilityID.meal(mealType))_add_food_button")
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    NavigationLink {
                        LoggedFoodEditorView(viewModel: foodLogViewModel, entry: entry)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.foodName)
                                    .font(.subheadline)
                                    .foregroundStyle(FitnessTheme.deepText)
                                Text("\(AppFormatters.displayNumber(entry.quantity)) \(entry.servingSize)")
                                    .font(.caption)
                                    .foregroundStyle(FitnessTheme.secondaryText)
                            }
                            Spacer()
                            Text("\(entry.calories)")
                                .font(.subheadline)
                                .foregroundStyle(FitnessTheme.secondaryText)
                                .accessibilityIdentifier("meal_\(AccessibilityID.meal(mealType))_entry_calories_\(String(format: "%03d", index + 1))")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("meal_\(AccessibilityID.meal(mealType))_entry_row_\(String(format: "%03d", index + 1))")

                    if index < entries.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }

                Divider().padding(.leading, 16)

                Button {
                    foodSearchMealType = mealType
                } label: {
                    HStack {
                        Text("Add Food")
                            .font(.subheadline)
                            .foregroundStyle(FitnessTheme.accent)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(FitnessTheme.subtleFill)
                .frame(height: 8)
        }
        .accessibilityIdentifier("dashboard_meal_\(AccessibilityID.meal(mealType))_row")
    }

    // MARK: - Exercise Section

    private var exerciseSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FitnessTheme.accent)
                Text("Exercise")
                    .font(.headline)
                    .foregroundStyle(FitnessTheme.deepText)
                Spacer()
                Text("\(viewModel.todayLog.burnedCalories)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FitnessTheme.secondaryText)
                    .accessibilityIdentifier("dashboard_exercise_burned_label")
                Button {
                    showExerciseSearch = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FitnessTheme.accent)
                        .frame(width: 32, height: 32)
                }
                .accessibilityIdentifier("dashboard_exercise_add_button")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)

            Divider().padding(.leading, 16)

            if viewModel.todayLog.exerciseEntries.isEmpty {
                Button {
                    showExerciseSearch = true
                } label: {
                    HStack {
                        Text("Add Exercise")
                            .font(.subheadline)
                            .foregroundStyle(FitnessTheme.accent)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("dashboard_exercise_empty_state")
            } else {
                ForEach(Array(viewModel.todayLog.exerciseEntries.enumerated()), id: \.element.id) { index, entry in
                    NavigationLink {
                        LoggedExerciseEditorView(viewModel: exerciseViewModel, entry: entry)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.exerciseName)
                                    .font(.subheadline)
                                    .foregroundStyle(FitnessTheme.deepText)
                                Text("\(entry.durationMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(FitnessTheme.secondaryText)
                            }
                            Spacer()
                            Text("\(entry.caloriesBurned)")
                                .font(.subheadline)
                                .foregroundStyle(FitnessTheme.secondaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("dashboard_exercise_entry_row_\(String(format: "%03d", index + 1))")

                    if index < viewModel.todayLog.exerciseEntries.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }

                Divider().padding(.leading, 16)

                Button {
                    showExerciseSearch = true
                } label: {
                    HStack {
                        Text("Add Exercise")
                            .font(.subheadline)
                            .foregroundStyle(FitnessTheme.accent)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(FitnessTheme.subtleFill)
                .frame(height: 8)
        }
    }

    // MARK: - Healthy Habits

    private var habitsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FitnessTheme.accentRose)
                Text("Healthy Habits")
                    .font(.headline)
                    .foregroundStyle(FitnessTheme.deepText)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)

            Divider().padding(.leading, 16)

            habitRow(
                icon: "drop.fill",
                tint: FitnessTheme.accent,
                title: "Water",
                value: "\(viewModel.todayLog.waterCups) of \(viewModel.waterGoal) cups",
                progress: viewModel.waterProgress,
                onTap: { showWaterSheet = true },
                onIncrement: { _ = viewModel.adjustWaterCups(by: 1) },
                accessibilityID: "dashboard_water_card"
            )

            Divider().padding(.leading, 16)

            habitRow(
                icon: "figure.walk",
                tint: FitnessTheme.accentWarm,
                title: "Steps",
                value: "\(viewModel.todayLog.stepCount) steps",
                progress: viewModel.stepProgress,
                onTap: { showStepsSheet = true },
                onIncrement: { _ = viewModel.adjustStepCount(by: 500) },
                accessibilityID: "dashboard_steps_card"
            )
        }
    }

    private func habitRow(
        icon: String,
        tint: Color,
        title: String,
        value: String,
        progress: Double,
        onTap: @escaping () -> Void,
        onIncrement: @escaping () -> Void,
        accessibilityID: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FitnessTheme.deepText)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(FitnessTheme.secondaryText)
                ProgressView(value: progress)
                    .tint(tint)
            }

            Spacer()

            Button(action: onIncrement) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(tint)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityIdentifier(accessibilityID)
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        Button {
            showQuickAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(FitnessTheme.accent)
                .clipShape(Circle())
                .shadow(color: FitnessTheme.accent.opacity(0.4), radius: 8, y: 4)
        }
        .accessibilityIdentifier("floating_add_button")
    }

    // MARK: - Status Banner

    private func statusBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(FitnessTheme.accent)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(FitnessTheme.deepText)
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
    }
}

// MARK: - Calorie Ring

private struct CalorieRing: View {
    let consumed: Int
    let remaining: Int
    let progress: Double

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("Remaining")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(remaining)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Calories")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 150, height: 150)
        }
    }
}

// MARK: - Calorie Formula Item

private struct CalorieFormulaItem: View {
    let value: String
    let label: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Macro Bar

private struct MacroBar: View {
    let label: String
    let consumed: Double
    let goal: Double
    let tint: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(consumed / goal, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FitnessTheme.secondaryText)
            ProgressView(value: progress)
                .tint(tint)
            Text("\(AppFormatters.displayNumber(consumed)) / \(AppFormatters.displayNumber(goal)) g")
                .font(.caption2)
                .foregroundStyle(FitnessTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Metric Editor Sheet

struct MetricEditorSheetView: View {
    let title: String
    let prompt: String
    let initialValue: String
    let keyboardType: UIKeyboardType
    let unitLabel: String
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var valueText = ""
    @State private var validationMessage: String?

    var body: some View {
        Form {
            Section(title) {
                TextField(prompt, text: $valueText)
                    .keyboardType(keyboardType)
                Text(unitLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Save") {
                    guard let value = Int(valueText), value >= 0 else {
                        validationMessage = "Enter a valid value."
                        return
                    }
                    onSave(value)
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            valueText = initialValue
        }
    }
}
