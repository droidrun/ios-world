import SwiftUI

struct ExerciseTabView: View {
    @ObservedObject var viewModel: ExerciseViewModel

    @State private var showSearch = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("This Week")
                        .font(.headline)
                        .foregroundStyle(FitnessTheme.secondaryText)

                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(viewModel.todayBurnedCalories)")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(FitnessTheme.deepText)
                                .accessibilityIdentifier("exercise_total_burned_label")
                            Text("calories burned today")
                                .font(.subheadline)
                                .foregroundStyle(FitnessTheme.secondaryText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            exerciseStat(title: "7-day burn", value: "\(viewModel.weeklyBurnedCalories) cal", tint: FitnessTheme.accentBlue)
                            exerciseStat(title: "Sessions", value: "\(viewModel.weeklySessionCount)", tint: FitnessTheme.accent)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FitnessTheme.heroGradient.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }

            Section {
                Button("Add Exercise") {
                    showSearch = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("exercise_add_button")
            }

            Section("Featured Routines") {
                ForEach(Array(viewModel.featuredExercises.enumerated()), id: \.element.id) { index, exercise in
                    HStack(spacing: 12) {
                        Image(systemName: exercise.systemImageName)
                            .font(.headline)
                            .foregroundStyle(FitnessTheme.color(forExercise: exercise))
                            .frame(width: 40, height: 40)
                            .background(FitnessTheme.color(forExercise: exercise).opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.exerciseName)
                                .font(.subheadline.weight(.semibold))
                            Text("\(exercise.durationMinutes) min • \(exercise.caloriesBurned) cal • \(exercise.category)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Quick Log") {
                            _ = viewModel.quickLog(exercise)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(FitnessTheme.color(forExercise: exercise))
                        .accessibilityIdentifier("exercise_quick_log_button_\(String(format: "%03d", index + 1))")
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Today") {
                if viewModel.todayEntries.isEmpty {
                    Text("No exercise logged today.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("exercise_empty_state")
                } else {
                    ForEach(Array(viewModel.todayEntries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            LoggedExerciseEditorView(viewModel: viewModel, entry: entry)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.exerciseName)
                                        .font(.headline)
                                    Text("\(entry.durationMinutes) min")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(entry.caloriesBurned) cal")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .accessibilityIdentifier("exercise_entry_row_\(String(format: "%03d", index + 1))")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FitnessTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle("Exercise")
        .accessibilityIdentifier("screen_exercise")
        .sheet(isPresented: $showSearch) {
            NavigationStack {
                ExerciseSearchView(viewModel: viewModel)
            }
        }
    }

    private func exerciseStat(title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

struct ExerciseSearchView: View {
    @ObservedObject var viewModel: ExerciseViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [Exercise] {
        Array(viewModel.searchExercises(query).prefix(20))
    }

    var body: some View {
        List {
            Section {
                TextField("Search exercise", text: $query)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier("exercise_search_field")
            }

            if results.isEmpty {
                Section {
                    Text("No exercises found.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("exercise_search_empty_state")
                }
            } else {
                Section("Exercises") {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, exercise in
                        NavigationLink {
                            ExerciseLogDetailView(viewModel: viewModel, exercise: exercise)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.exerciseName)
                                        .font(.headline)
                                    Text(exercise.category)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(exercise.caloriesBurned) cal / \(exercise.durationMinutes) min")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("exercise_result_row_\(String(format: "%03d", index + 1))")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FitnessTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle("Log Exercise")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .accessibilityIdentifier("exercise_search_close_button")
            }
        }
    }
}

struct ExerciseLogDetailView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss
    @State private var durationText: String
    @State private var caloriesText: String
    @State private var validationMessage: String?

    init(viewModel: ExerciseViewModel, exercise: Exercise) {
        self.viewModel = viewModel
        self.exercise = exercise
        _durationText = State(initialValue: "\(exercise.durationMinutes)")
        _caloriesText = State(initialValue: "\(exercise.caloriesBurned)")
    }

    var body: some View {
        Form {
            Section("Exercise") {
                LabeledContent("Name", value: exercise.exerciseName)
                LabeledContent("Category", value: exercise.category)
            }

            Section("Details") {
                TextField("Duration", text: $durationText)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("exercise_duration_field")
                    .onChange(of: durationText) { _, newValue in
                        if let duration = Int(newValue), duration > 0 {
                            caloriesText = "\(exercise.calories(for: duration))"
                        }
                    }

                TextField("Calories Burned", text: $caloriesText)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("exercise_calories_field")
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("exercise_duration_error")
                }
            }

            Section {
                Button("Log Exercise") {
                    guard let duration = Int(durationText), duration > 0,
                          let calories = Int(caloriesText), calories > 0 else {
                        validationMessage = "Enter a valid duration and calories burned."
                        return
                    }
                    validationMessage = nil
                    if viewModel.logExercise(exercise, durationMinutes: duration, caloriesBurned: calories) {
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("exercise_log_confirm_button")
            }
        }
        .navigationTitle(exercise.exerciseName)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .accessibilityIdentifier("exercise_log_cancel_button")
            }
        }
    }
}

struct LoggedExerciseEditorView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    let entry: ExerciseEntry

    @Environment(\.dismiss) private var dismiss
    @State private var durationText: String
    @State private var caloriesText: String
    @State private var validationMessage: String?
    @State private var showDeleteConfirmation = false

    init(viewModel: ExerciseViewModel, entry: ExerciseEntry) {
        self.viewModel = viewModel
        self.entry = entry
        _durationText = State(initialValue: "\(entry.durationMinutes)")
        _caloriesText = State(initialValue: "\(entry.caloriesBurned)")
    }

    var body: some View {
        Form {
            Section("Exercise") {
                LabeledContent("Name", value: entry.exerciseName)
                TextField("Duration", text: $durationText)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("exercise_edit_duration_field")
                TextField("Calories Burned", text: $caloriesText)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("exercise_edit_calories_field")
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("exercise_duration_error")
                }
            }

            Section {
                Button("Save Changes") {
                    guard let duration = Int(durationText), duration > 0,
                          let calories = Int(caloriesText), calories > 0 else {
                        validationMessage = "Enter a valid duration and calories burned."
                        return
                    }
                    validationMessage = nil
                    if viewModel.updateExerciseEntry(entryID: entry.id, durationMinutes: duration, caloriesBurned: calories) {
                        dismiss()
                    }
                }
                .accessibilityIdentifier("exercise_edit_save_button")
            }

            Section {
                Button("Delete Exercise", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .accessibilityIdentifier("exercise_delete_button")
            }
        }
        .navigationTitle(entry.exerciseName)
        .alert("Delete Exercise?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.removeExerciseEntry(entryID: entry.id)
                dismiss()
            }
            .accessibilityIdentifier("exercise_delete_confirm_button")

            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("exercise_delete_cancel_button")
        } message: {
            Text("This removes the logged exercise entry from the day.")
        }
    }
}
