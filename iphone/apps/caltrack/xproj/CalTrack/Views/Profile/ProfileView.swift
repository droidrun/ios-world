import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @ObservedObject var goalsViewModel: GoalsViewModel

    @State private var userName = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var goalWeightText = ""
    @State private var selectedActivityLevel = "Moderately Active"
    @State private var validationMessage: String?

    var body: some View {
        Form {
            Section {
                profileHero
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }

            Section("Account") {
                TextField("Name", text: $userName)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("profile_name_field")

                TextField("Height (\(heightUnitLabel))", text: $heightText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("profile_height_field")

                TextField("Current Weight (\(weightUnitLabel))", text: $weightText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("profile_weight_field")

                TextField("Goal Weight (\(weightUnitLabel))", text: $goalWeightText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("profile_goal_weight_field")

                Picker("Activity Level", selection: $selectedActivityLevel) {
                    ForEach(viewModel.activityLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .accessibilityIdentifier("profile_activity_level_picker")
            }

            Section("Current Targets") {
                HStack {
                    Text("Daily Calorie Goal")
                    Spacer()
                    Text("\(viewModel.currentGoalCalories)")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("profile_daily_calorie_goal_label")
                }

                HStack {
                    Text("Current Weight")
                    Spacer()
                    Text(AppFormatters.displayWeight(viewModel.profile.weight, unitSystem: viewModel.profile.unitSystem))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Goal Weight")
                    Spacer()
                    Text(AppFormatters.displayWeight(viewModel.profile.goalWeight, unitSystem: viewModel.profile.unitSystem))
                        .foregroundStyle(.secondary)
                }
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("profile_validation_error")
                }
            }

            Section {
                Button("Save Profile") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("profile_save_button")
            }

            Section {
                NavigationLink {
                    GoalsView(viewModel: goalsViewModel)
                } label: {
                    Label("Goals & Targets", systemImage: "target")
                }
                .accessibilityIdentifier("profile_goals_link")
            }
        }
        .navigationTitle("Profile")
        .accessibilityIdentifier("profile_screen")
        .scrollContentBackground(.hidden)
        .background(FitnessTheme.canvasGradient.ignoresSafeArea())
        .onAppear(perform: loadValues)
    }

    private var profileHero: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 66, height: 66)
                Text(initials)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.profile.userName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(viewModel.profile.activityLevel) • \(AppFormatters.displayHeight(viewModel.profile.height, unitSystem: viewModel.profile.unitSystem))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                Text("Goal: \(AppFormatters.displayWeight(viewModel.profile.goalWeight, unitSystem: viewModel.profile.unitSystem))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()
        }
        .padding(18)
        .background(FitnessTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var initials: String {
        let parts = viewModel.profile.userName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first?.uppercased() }
        let joined = parts.joined()
        return joined.isEmpty ? "U" : joined
    }

    private var weightUnitLabel: String {
        viewModel.profile.unitSystem == .pounds ? "lb" : "kg"
    }

    private var heightUnitLabel: String {
        viewModel.profile.unitSystem == .pounds ? "in" : "cm"
    }

    private func loadValues() {
        let profile = viewModel.profile
        userName = profile.userName
        heightText = AppFormatters.editableHeight(profile.height, unitSystem: profile.unitSystem)
        weightText = AppFormatters.editableWeight(profile.weight, unitSystem: profile.unitSystem)
        goalWeightText = AppFormatters.editableWeight(profile.goalWeight, unitSystem: profile.unitSystem)
        selectedActivityLevel = profile.activityLevel
        validationMessage = nil
    }

    private func saveProfile() {
        let unitSystem = viewModel.profile.unitSystem

        guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let heightValue = Double(heightText.replacingOccurrences(of: ",", with: ".")), heightValue > 0,
              let weightValue = Double(weightText.replacingOccurrences(of: ",", with: ".")), weightValue > 0,
              let goalWeightValue = Double(goalWeightText.replacingOccurrences(of: ",", with: ".")), goalWeightValue > 0 else {
            validationMessage = "Enter valid values for all profile fields."
            return
        }

        validationMessage = nil
        viewModel.saveProfile(
            userName: userName.trimmingCharacters(in: .whitespacesAndNewlines),
            height: AppFormatters.inches(fromEditableHeight: heightValue, unitSystem: unitSystem),
            weight: AppFormatters.pounds(fromEditableWeight: weightValue, unitSystem: unitSystem),
            goalWeight: AppFormatters.pounds(fromEditableWeight: goalWeightValue, unitSystem: unitSystem),
            activityLevel: selectedActivityLevel,
            unitSystem: unitSystem
        )
    }
}
