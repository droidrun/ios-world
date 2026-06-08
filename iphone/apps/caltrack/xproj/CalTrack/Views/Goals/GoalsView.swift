import SwiftUI

struct GoalsView: View {
    @ObservedObject var viewModel: GoalsViewModel

    @State private var goalCalories = ""
    @State private var goalProtein = ""
    @State private var goalCarbs = ""
    @State private var goalFat = ""
    @State private var targetWeight = ""
    @State private var weeklyWeightChange = ""
    @State private var validationMessage: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Targets shape every summary, chart, and meal recommendation in the app.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.84))
                    Text("Weights are shown in \(viewModel.unitSystem.shortLabel.uppercased()).")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FitnessTheme.heroGradient)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }

            Section("Nutrition Targets") {
                TextField("Daily Calories", text: $goalCalories)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("goals_daily_calories_field")
                TextField("Protein (g)", text: $goalProtein)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("goals_protein_field")
                TextField("Carbs (g)", text: $goalCarbs)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("goals_carbs_field")
                TextField("Fat (g)", text: $goalFat)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("goals_fat_field")
            }

            Section("Weight Goals") {
                TextField("Target Weight (\(viewModel.unitSystem.shortLabel))", text: $targetWeight)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("goals_target_weight_field")
                TextField("Weekly Weight Change (\(viewModel.unitSystem.shortLabel))", text: $weeklyWeightChange)
                    .keyboardType(.numbersAndPunctuation)
                    .accessibilityIdentifier("goals_weekly_change_field")
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("goals_validation_error")
                }
            }

            Section {
                Button("Save Goals") {
                    saveGoals()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("goals_save_button")
            }
        }
        .navigationTitle("Goals")
        .accessibilityIdentifier("goals_screen")
        .scrollContentBackground(.hidden)
        .background(FitnessTheme.canvasGradient.ignoresSafeArea())
        .onAppear(perform: loadValues)
    }

    private func loadValues() {
        let goals = viewModel.goals
        goalCalories = "\(goals.goalCalories)"
        goalProtein = AppFormatters.displayNumber(goals.goalProtein)
        goalCarbs = AppFormatters.displayNumber(goals.goalCarbs)
        goalFat = AppFormatters.displayNumber(goals.goalFat)
        targetWeight = AppFormatters.editableWeight(goals.targetWeight, unitSystem: viewModel.unitSystem)
        weeklyWeightChange = AppFormatters.displayNumber(viewModel.unitSystem == .pounds ? goals.weeklyWeightChange : goals.weeklyWeightChange * 0.453592)
        validationMessage = nil
    }

    private func saveGoals() {
        guard let calories = Int(goalCalories), calories > 0,
              let protein = Double(goalProtein.replacingOccurrences(of: ",", with: ".")), protein > 0,
              let carbs = Double(goalCarbs.replacingOccurrences(of: ",", with: ".")), carbs > 0,
              let fat = Double(goalFat.replacingOccurrences(of: ",", with: ".")), fat > 0,
              let targetWeightValue = Double(targetWeight.replacingOccurrences(of: ",", with: ".")), targetWeightValue > 0,
              let weeklyChange = Double(weeklyWeightChange.replacingOccurrences(of: ",", with: ".")) else {
            validationMessage = "Enter valid values for all goal fields."
            return
        }

        validationMessage = nil
        viewModel.saveGoals(
            goalCalories: calories,
            goalProtein: protein,
            goalCarbs: carbs,
            goalFat: fat,
            targetWeight: AppFormatters.pounds(fromEditableWeight: targetWeightValue, unitSystem: viewModel.unitSystem),
            weeklyWeightChange: viewModel.unitSystem == .pounds ? weeklyChange : weeklyChange / 0.453592
        )
    }
}
