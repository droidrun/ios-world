import SwiftUI

struct MoreTabView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var goalsViewModel: GoalsViewModel
    @ObservedObject var moreViewModel: MoreViewModel

    @State private var showResetConfirmation = false
    @State private var showPremiumSheet = false

    var body: some View {
        Form {
            Section {
                profileHero
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }

            Section {
                NavigationLink {
                    ProfileView(
                        viewModel: profileViewModel,
                        goalsViewModel: goalsViewModel
                    )
                } label: {
                    Label("My Profile", systemImage: "person.fill")
                }
                .accessibilityIdentifier("profile_settings_row")

                NavigationLink {
                    GoalsView(viewModel: goalsViewModel)
                } label: {
                    Label("Goals & Nutrition", systemImage: "target")
                }
                .accessibilityIdentifier("goals_settings_row")
            }

            Section("Notifications") {
                Toggle(
                    "Push Notifications",
                    isOn: Binding(
                        get: { moreViewModel.pushNotificationsEnabled },
                        set: { moreViewModel.setPushNotifications($0) }
                    )
                )
                .accessibilityIdentifier("settings_push_notifications_toggle")

                Toggle(
                    "Meal Reminders",
                    isOn: Binding(
                        get: { moreViewModel.reminderNotificationsEnabled },
                        set: { moreViewModel.setReminderNotifications($0) }
                    )
                )
                .accessibilityIdentifier("settings_meal_reminders_toggle")
            }

            Section("Diary Settings") {
                Picker(
                    "Weight Units",
                    selection: Binding(
                        get: { moreViewModel.unitSystem },
                        set: { moreViewModel.setUnitSystem($0) }
                    )
                ) {
                    ForEach(UnitSystem.allCases) { system in
                        Text(system.displayName).tag(system)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings_unit_picker")
            }

            Section("Premium") {
                Button {
                    showPremiumSheet = true
                } label: {
                    HStack {
                        Label("Upgrade to Premium", systemImage: "star.fill")
                            .foregroundStyle(FitnessTheme.accentWarm)
                        Spacer()
                        Text("Learn More")
                            .font(.caption)
                            .foregroundStyle(FitnessTheme.accent)
                    }
                }
                .accessibilityIdentifier("more_premium_link")
            }

            Section("Data & Storage") {
                HStack {
                    Text("Food Database")
                    Spacer()
                    Text("\(moreViewModel.foodDatabaseCount) foods")
                        .foregroundStyle(.secondary)
                }

                Button("Refresh Food Library") {
                    moreViewModel.reloadSeededFoodDatabase()
                }
                .accessibilityIdentifier("reload_seeded_food_database_button")

                Button("Clear Saved State") {
                    moreViewModel.resetPersistence()
                }
                .accessibilityIdentifier("settings_reset_persistence_button")
            }

            Section("About") {
                Text("This app uses local data only. All information is stored securely on your device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("data_import_placeholder")
            }

            if let statusMessage = moreViewModel.statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("more_status_message")
                }
            }

            Section {
                Button("Reset App State", role: .destructive) {
                    showResetConfirmation = true
                }
                .accessibilityIdentifier("more_reset_app_state_button")
            }
        }
        .navigationTitle("More")
        .accessibilityIdentifier("settings_screen")
        .scrollContentBackground(.hidden)
        .background(FitnessTheme.canvasGradient.ignoresSafeArea())
        .sheet(isPresented: $showPremiumSheet) {
            PremiumUpsellView()
        }
        .alert("Reset App State?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                moreViewModel.resetAppState()
            }
            .accessibilityIdentifier("more_reset_confirm_button")

            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("more_reset_cancel_button")
        } message: {
            Text("This clears your data and restores the app to its default state.")
        }
    }

    private var profileHero: some View {
        NavigationLink {
            ProfileView(
                viewModel: profileViewModel,
                goalsViewModel: goalsViewModel
            )
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 56, height: 56)
                    Text(initials)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profileViewModel.profile.userName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(AppFormatters.displayWeight(profileViewModel.profile.weight, unitSystem: profileViewModel.profile.unitSystem)) \u{2022} Goal: \(AppFormatters.displayWeight(profileViewModel.profile.goalWeight, unitSystem: profileViewModel.profile.unitSystem))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .background(FitnessTheme.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let parts = profileViewModel.profile.userName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first?.uppercased() }
        let joined = parts.joined()
        return joined.isEmpty ? "U" : joined
    }
}

private struct PremiumUpsellView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, title: String, detail: String)] = [
        ("chart.bar.doc.horizontal.fill", "Advanced Insights", "Deeper macro breakdowns, nutrient timing, and weekly trend reports."),
        ("fork.knife", "Meal Plans", "Curated daily meal plans tailored to your calorie and macro targets."),
        ("barcode.viewfinder", "Barcode Scanner", "Instantly log packaged foods by scanning the barcode."),
        ("bell.badge.fill", "Smart Reminders", "Personalized meal and hydration reminders throughout the day."),
        ("rectangle.on.rectangle.angled", "Ad-Free Experience", "Remove all banners and enjoy a clean interface.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(FitnessTheme.accentWarm)
                        Text("Go Premium")
                            .font(.title.weight(.bold))
                            .foregroundStyle(FitnessTheme.deepText)
                        Text("Unlock the full suite of tracking and planning tools.")
                            .font(.subheadline)
                            .foregroundStyle(FitnessTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 0) {
                        ForEach(features.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: features[index].icon)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(FitnessTheme.accent)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(features[index].title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(FitnessTheme.deepText)
                                    Text(features[index].detail)
                                        .font(.caption)
                                        .foregroundStyle(FitnessTheme.secondaryText)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)

                            if index < features.count - 1 {
                                Divider().padding(.leading, 62)
                            }
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)

                    Text("Premium is not available at this time.")
                        .font(.caption)
                        .foregroundStyle(FitnessTheme.secondaryText)
                }
                .padding(.bottom, 32)
            }
            .background(FitnessTheme.canvasGradient.ignoresSafeArea())
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
