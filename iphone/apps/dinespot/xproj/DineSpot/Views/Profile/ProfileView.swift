import SwiftUI

struct RewardsView: View {
    @EnvironmentObject private var store: DiningStore

    private var completedBookings: Int {
        store.pastReservations().count
    }

    private var targetBookings: Int {
        6
    }

    private var progressValue: Double {
        min(1.0, Double(completedBookings) / Double(targetBookings))
    }

    var body: some View {
        ZStack {
            DiningTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroSection
                    benefitsSection
                    rewardsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("rewards_screen")
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [DiningTheme.accentRed, Color(red: 0.65, green: 0.15, blue: 0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("DineSpot Regulars")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(16)
                }

            Text("Your progress to Gold")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)
                .accessibilityIdentifier("rewards_progress_title")

            ProgressView(value: progressValue)
                .tint(DiningTheme.accentRed)
                .scaleEffect(y: 1.8)
                .accessibilityIdentifier("rewards_progress_bar")

            Text("\(completedBookings) of \(targetBookings) completed bookings")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(DiningTheme.textSecondary)
                .accessibilityIdentifier("rewards_progress_label")

            HStack(spacing: 14) {
                NavigationLink {
                    DiscoverView(viewModel: DiscoverViewModel())
                } label: {
                    Text("Book a table")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DiningTheme.border, lineWidth: 1.6)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("rewards_book_table_button")

                NavigationLink {
                    ProfileView()
                } label: {
                    Text("Learn more")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("rewards_learn_more_button")
            }
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Go for Gold status")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)
                .accessibilityIdentifier("rewards_benefits_title")

            benefitRow(icon: "bell.badge", title: "Priority notify", detail: "Be the first to know when tables open up.", id: "rewards_benefit_priority_notify")
            benefitRow(icon: "gift", title: "6 months of CityRide One for free", detail: "Enjoy member-only savings on CityRide, CityRide Eats, and more.", id: "rewards_benefit_partner_offer")
        }
    }

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Rewards from points")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                Spacer()
                Text("\(completedBookings * 120) points")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
            }
            .accessibilityIdentifier("rewards_points_header")

            rewardCard(
                title: "$8 Experiences credit",
                detail: "Save on prix fixe menus, cocktail classes, and more.",
                pointsCost: 1200,
                identifier: "reward_card_experiences_credit"
            )

            rewardCard(
                title: "$15 Dining credit",
                detail: "Apply toward your next eligible reservation.",
                pointsCost: 2000,
                identifier: "reward_card_dining_credit"
            )
        }
    }

    private func benefitRow(icon: String, title: String, detail: String, id: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.orange)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                Text(detail)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
            }
        }
        .accessibilityIdentifier(id)
    }

    private func rewardCard(title: String, detail: String, pointsCost: Int, identifier: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [DiningTheme.accentRed.opacity(0.15), DiningTheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 110, height: 110)
                .overlay {
                    Image(systemName: "lock")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(DiningTheme.muted)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                Text(detail)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
                Text("\(pointsCost) points")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DiningTheme.accentRed)
            }

            Spacer()
        }
        .padding(12)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
        .accessibilityIdentifier(identifier)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: DiningStore
    @State private var showResetConfirmation = false

    private var savedRestaurants: [Restaurant] {
        store.favoriteRestaurants()
    }

    var body: some View {
        Form {
            Section("Profile") {
                Text(store.userProfile.fullName)
                    .font(.headline)
                    .accessibilityIdentifier("profile_name_label")
                Text(store.userProfile.email)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("profile_email_label")
                Text("Loyalty: \(store.userProfile.loyaltyTier)")
                    .accessibilityIdentifier("profile_loyalty_label")
            }

            Section("Dining Preferences") {
                ForEach(store.userProfile.diningPreferences.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.userProfile.diningPreferences[index].title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField(
                            store.userProfile.diningPreferences[index].title,
                            text: diningPreferenceBinding(index: index)
                        )
                        .accessibilityIdentifier("profile_dining_pref_field_\(store.userProfile.diningPreferences[index].id)")
                    }
                }
            }

            Section("Notifications") {
                Toggle("Reservation updates", isOn: profileBinding(\.notificationEnabled))
                    .accessibilityIdentifier("profile_notification_toggle")
                Toggle("Promotions", isOn: profileBinding(\.promoNotificationsEnabled))
                    .accessibilityIdentifier("profile_promo_toggle")
            }

            Section("Saved Restaurants") {
                if savedRestaurants.isEmpty {
                    Text("No saved restaurants yet")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("profile_no_saved_restaurants_state")
                } else {
                    ForEach(savedRestaurants) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurantID: restaurant.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(restaurant.name)
                                    .font(.body.weight(.semibold))
                                Text("\(restaurant.cuisine) \u{2022} \(AppFormat.priceTierLabel(restaurant.priceTier))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("profile_saved_restaurant_row_\(restaurant.id)")
                    }
                }
            }

            Section("Snapshot Source") {
                Picker("Mode", selection: Binding(
                    get: { store.availabilityMode },
                    set: { store.setAvailabilityMode($0) }
                )) {
                    ForEach(AvailabilityMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("debug_switch_snapshot_mode")

                Text(store.availabilitySourceLabel)
                    .font(.footnote)
                    .accessibilityIdentifier("debug_current_source_label")

                Button("Reload Bundled Snapshot") {
                    store.reloadBundledSnapshot()
                }
                .accessibilityIdentifier("debug_reload_bundled_snapshot")

                Button("Reload Sandbox Snapshot") {
                    store.reloadSandboxSnapshot()
                }
                .accessibilityIdentifier("debug_reload_sandbox_snapshot")

                Text(store.sandboxSnapshotPath())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("debug_sandbox_snapshot_path_label")
            }

            Section("Account") {
                Button("Reset App State", role: .destructive) {
                    showResetConfirmation = true
                }
                .accessibilityIdentifier("profile_reset_app_state")
            }
        }
        .navigationTitle("Account")
        .accessibilityIdentifier("profile_screen")
        .confirmationDialog("Reset app state?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                store.resetAppState()
            }
            .accessibilityIdentifier("profile_reset_confirm_button")

            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("profile_reset_cancel_button")
        }
    }

    private func profileBinding<T>(_ keyPath: WritableKeyPath<UserProfile, T>) -> Binding<T> {
        Binding(
            get: { store.userProfile[keyPath: keyPath] },
            set: { newValue in
                var profile = store.userProfile
                profile[keyPath: keyPath] = newValue
                store.userProfile = profile
            }
        )
    }

    private func diningPreferenceBinding(index: Int) -> Binding<String> {
        Binding(
            get: {
                guard store.userProfile.diningPreferences.indices.contains(index) else { return "" }
                return store.userProfile.diningPreferences[index].value
            },
            set: { newValue in
                guard store.userProfile.diningPreferences.indices.contains(index) else { return }
                var profile = store.userProfile
                profile.diningPreferences[index].value = newValue
                store.userProfile = profile
            }
        )
    }
}
