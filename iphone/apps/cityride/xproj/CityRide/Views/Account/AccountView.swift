import SwiftUI

struct AccountView: View {
    @ObservedObject var viewModel: AccountViewModel

    @AppStorage("uber.account.notifications_enabled") private var notificationsEnabled = true
    @AppStorage("uber.account.share_trip_status_enabled") private var shareTripStatus = true
    @State private var editingPlace: SavedPlace?
    @State private var editedSavedPlaceName = ""
    @State private var showPrivacy = false
    @State private var showPreferences = false
    @State private var showHelp = false
    @State private var showWallet = false
    @State private var showSafety = false
    @State private var showInbox = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    profileHeader
                    quickActionTiles
                    uberOneCard
                    savedPlacesSection
                    settingsSection
                }
                .padding(16)
            }
            .background(CityRideTheme.background)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottom) {
                if let message = viewModel.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .uberCard(radius: 999)
                        .padding(.bottom, 10)
                        .accessibilityIdentifier("account_status_message")
                }
            }
            .onChange(of: notificationsEnabled) { _, enabled in
                viewModel.setNotificationsEnabled(enabled)
            }
            .onChange(of: shareTripStatus) { _, enabled in
                viewModel.setShareTripStatusEnabled(enabled)
            }
        }
        .sheet(item: $editingPlace) { place in
            NavigationStack {
                Form {
                    TextField("Saved place name", text: $editedSavedPlaceName)
                        .accessibilityIdentifier("account_saved_place_name_field")
                    Text(place.address)
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                }
                .navigationTitle("Edit Saved Place")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            editingPlace = nil
                        }
                        .accessibilityIdentifier("account_saved_place_edit_cancel")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            viewModel.renameSavedPlace(place.id, newName: editedSavedPlaceName)
                            editingPlace = nil
                        }
                        .accessibilityIdentifier("account_saved_place_edit_save")
                    }
                }
            }
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showPreferences) {
            AppPreferencesView()
        }
        .sheet(isPresented: $showHelp) {
            HelpSupportSheet()
        }
        .sheet(isPresented: $showWallet) {
            WalletSummarySheet(store: viewModel.store)
        }
        .sheet(isPresented: $showSafety) {
            SafetyToolkitSheet()
        }
        .sheet(isPresented: $showInbox) {
            InboxSheet()
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.userProfile.fullName)
                        .font(.system(size: 32, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .accessibilityIdentifier("account_profile_name")
                    HStack(spacing: 8) {
                        labelPill(text: String(format: "%.2f", viewModel.passengerProfile.riderRating), icon: "star.fill")
                        labelPill(text: "Verified", icon: "checkmark.seal.fill")
                    }
                }
                Spacer()
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.white.opacity(0.9), Color.white.opacity(0.2))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.userProfile.email)
                    .font(.subheadline)
                    .foregroundStyle(CityRideTheme.muted)
                    .accessibilityIdentifier("account_profile_email")
                Text(viewModel.userProfile.phoneNumberMasked)
                    .font(.subheadline)
                    .foregroundStyle(CityRideTheme.muted)
                    .accessibilityIdentifier("account_profile_phone")
            }
        }
    }

    private var quickActionTiles: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                quickTile(title: "Help", icon: "lifepreserver", id: "account_help_support_button") {
                    showHelp = true
                }
                quickTile(title: "Wallet", icon: "wallet.pass", id: "account_wallet_button") {
                    showWallet = true
                }
            }
            HStack(spacing: 10) {
                quickTile(title: "Safety", icon: "shield", id: "account_safety_toolkit_button") {
                    showSafety = true
                }
                quickTile(title: "Inbox", icon: "envelope", id: "account_inbox_button") {
                    showInbox = true
                }
            }
        }
    }

    private var uberOneCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Save with CityRide One")
                    .font(.headline)
                Text("You could've saved $15.05 in the last 30 days")
                    .font(.subheadline)
                    .foregroundStyle(CityRideTheme.muted)
            }
            Spacer()
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
        }
        .padding(14)
        .uberCard(radius: 18)
        .accessibilityIdentifier("account_uber_one_card")
    }

    private var savedPlacesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved places")
                .font(.title3.weight(.bold))

            ForEach(viewModel.savedPlaces) { place in
                Button {
                    editingPlace = place
                    editedSavedPlaceName = place.displayName
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: iconForPlace(place.type))
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(place.displayName)
                                .font(.headline)
                            Text(place.address)
                                .font(.caption)
                                .foregroundStyle(CityRideTheme.muted)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(CityRideTheme.muted)
                    }
                    .padding(12)
                    .uberCard(radius: 14)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("account_saved_place_row_\(place.displayName.accessibilitySafe)")
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.title3.weight(.bold))

            VStack(spacing: 0) {
                settingsRow(icon: "bell", title: "Notifications") {
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .accessibilityIdentifier("account_notifications_toggle")
                }

                Divider().overlay(CityRideTheme.cardBorder)

                settingsRow(icon: "location", title: "Share trip status") {
                    Toggle("", isOn: $shareTripStatus)
                        .labelsHidden()
                        .accessibilityIdentifier("account_share_trip_toggle")
                }

                Divider().overlay(CityRideTheme.cardBorder)

                settingsNavRow(icon: "lock.shield", title: "Privacy", id: "account_privacy_settings_button") {
                    showPrivacy = true
                }

                Divider().overlay(CityRideTheme.cardBorder)

                settingsNavRow(icon: "gearshape", title: "App preferences", id: "account_app_preferences_button") {
                    showPreferences = true
                }
            }
            .uberCard(radius: 14)
        }
    }

    private func settingsRow<Trailing: View>(icon: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(CityRideTheme.muted)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func settingsNavRow(icon: String, title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(CityRideTheme.muted)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(CityRideTheme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private func labelPill(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.headline)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08), in: Capsule())
    }

    private func quickTile(title: String, icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
            }
            .padding(14)
            .uberCard(radius: 18)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private func iconForPlace(_ type: SavedPlaceType) -> String {
        switch type {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .favorite: return "star.fill"
        }
    }
}

private struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("uber.privacy.location_sharing") private var locationSharing = true
    @AppStorage("uber.privacy.personalized_ads") private var personalizedAds = true
    @AppStorage("uber.privacy.data_sharing_partners") private var dataSharingPartners = false
    @AppStorage("uber.privacy.analytics") private var analytics = true
    @State private var showDownloadConfirm = false
    @State private var showDeleteConfirm = false
    @State private var downloadRequested = false

    var body: some View {
        NavigationStack {
            List {
                Section("Location") {
                    Toggle("Share location with driver", isOn: $locationSharing)
                        .accessibilityIdentifier("privacy_location_sharing_toggle")
                }

                Section("Data") {
                    Toggle("Personalized ads", isOn: $personalizedAds)
                        .accessibilityIdentifier("privacy_personalized_ads_toggle")
                    Toggle("Share data with partners", isOn: $dataSharingPartners)
                        .accessibilityIdentifier("privacy_data_sharing_toggle")
                    Toggle("Usage analytics", isOn: $analytics)
                        .accessibilityIdentifier("privacy_analytics_toggle")
                }

                Section {
                    Button(downloadRequested ? "Download requested" : "Download my data") {
                        showDownloadConfirm = true
                    }
                    .disabled(downloadRequested)
                    .accessibilityIdentifier("privacy_download_data_button")
                    Button("Delete account", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .accessibilityIdentifier("privacy_delete_account_button")
                }
            }
            .scrollContentBackground(.hidden)
            .background(CityRideTheme.background)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("privacy_done_button")
                }
            }
            .alert("Download your data?", isPresented: $showDownloadConfirm) {
                Button("Request Download") { downloadRequested = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("We'll prepare a copy of your account data. You'll receive an email when it's ready.")
            }
            .alert("Delete your account?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
    }
}

private struct AppPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("uber.prefs.dark_mode") private var darkMode = true
    @AppStorage("uber.prefs.sounds") private var sounds = true
    @AppStorage("uber.prefs.haptics") private var haptics = true
    @AppStorage("uber.prefs.language") private var language = "English"

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Toggle("Dark mode", isOn: $darkMode)
                        .accessibilityIdentifier("prefs_dark_mode_toggle")
                }

                Section("Notifications") {
                    Toggle("Sounds", isOn: $sounds)
                        .accessibilityIdentifier("prefs_sounds_toggle")
                    Toggle("Haptics", isOn: $haptics)
                        .accessibilityIdentifier("prefs_haptics_toggle")
                }

                Section("Language") {
                    Picker("Language", selection: $language) {
                        Text("English").tag("English")
                        Text("Spanish").tag("Spanish")
                        Text("French").tag("French")
                        Text("Chinese").tag("Chinese")
                    }
                    .accessibilityIdentifier("prefs_language_picker")
                }

                Section("Accessibility") {
                    NavigationLink("Accessibility settings") {
                        AccessibilitySettingsView()
                    }
                    .accessibilityIdentifier("prefs_accessibility_link")
                }
            }
            .scrollContentBackground(.hidden)
            .background(CityRideTheme.background)
            .navigationTitle("App preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("prefs_done_button")
                }
            }
        }
    }
}

private struct AccessibilitySettingsView: View {
    @AppStorage("uber.a11y.larger_text") private var largerText = false
    @AppStorage("uber.a11y.high_contrast") private var highContrast = false
    @AppStorage("uber.a11y.reduce_motion") private var reduceMotion = false
    @AppStorage("uber.a11y.voiceover_announcements") private var voiceoverAnnouncements = true

    var body: some View {
        List {
            Section("Display") {
                Toggle("Larger text", isOn: $largerText)
                    .accessibilityIdentifier("a11y_larger_text_toggle")
                Toggle("High contrast", isOn: $highContrast)
                    .accessibilityIdentifier("a11y_high_contrast_toggle")
            }

            Section("Motion") {
                Toggle("Reduce motion", isOn: $reduceMotion)
                    .accessibilityIdentifier("a11y_reduce_motion_toggle")
            }

            Section("VoiceOver") {
                Toggle("Trip announcements", isOn: $voiceoverAnnouncements)
                    .accessibilityIdentifier("a11y_voiceover_toggle")
            }
        }
        .scrollContentBackground(.hidden)
        .background(CityRideTheme.background)
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HelpSupportSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let faqItems: [(question: String, answer: String)] = [
        ("How do I change my payment method?", "Go to the Wallet tab and select a different payment method, or add a new one."),
        ("How do I cancel a ride?", "Open the trip from the Activity tab and tap 'Cancel ride'. Cancellation fees may apply after a driver is assigned."),
        ("I was charged incorrectly", "Open the trip receipt from Activity, then tap 'Report an issue' to submit a fare review."),
        ("My driver didn't show up", "You can report a no-show from the trip detail screen. You won't be charged if the driver was at fault."),
        ("How do I add a stop?", "Tap the '+' button on the route input card when planning your ride to add an intermediate stop."),
        ("How do I schedule a ride?", "Tap 'Later' on the Home screen, then choose your pickup time and destination.")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Frequently Asked Questions") {
                    ForEach(faqItems.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(faqItems[index].question)
                                .font(.subheadline.weight(.semibold))
                            Text(faqItems[index].answer)
                                .font(.caption)
                                .foregroundStyle(CityRideTheme.muted)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Contact") {
                    HStack(spacing: 12) {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(CityRideTheme.muted)
                        Text("1-800-UBER-HELP")
                            .font(.subheadline)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(CityRideTheme.muted)
                        Text("support@uber.com")
                            .font(.subheadline)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CityRideTheme.background)
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct WalletSummarySheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: CityRideStore

    var body: some View {
        NavigationStack {
            List {
                Section("Payment Methods") {
                    ForEach(store.walletPaymentMethods) { method in
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(CityRideTheme.muted)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(method.cardLabel)
                                    .font(.subheadline.weight(.medium))
                                if let account = store.myBankAccountForPaymentMethod(method) {
                                    Text("\(account.network) \u{00B7} \(account.name)")
                                        .font(.caption)
                                        .foregroundStyle(CityRideTheme.muted)
                                }
                            }
                            Spacer()
                            if method.id == store.state.selectedPaymentMethodId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section("CityRide Cash") {
                    HStack {
                        Text("Balance")
                            .font(.subheadline)
                        Spacer()
                        Text(AppFormatters.price(store.state.walletState.giftCardBalance, currencyCode: "USD"))
                            .font(.subheadline.weight(.semibold))
                    }
                }

                Section {
                    Text("Open the Wallet tab for full management options.")
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(CityRideTheme.background)
            .navigationTitle("Wallet Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SafetyToolkitSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("During a Trip") {
                    safetyRow(icon: "shield.fill", title: "Share trip status", detail: "Let friends and family follow your trip in real time.")
                    safetyRow(icon: "phone.arrow.up.right.fill", title: "Emergency assistance", detail: "Quickly connect with 911 if you feel unsafe.")
                    safetyRow(icon: "pin.fill", title: "Trusted contacts", detail: "Add contacts who will be notified when you share your trip.")
                }

                Section("Before a Trip") {
                    safetyRow(icon: "car.fill", title: "Verify your ride", detail: "Always confirm the license plate, driver name, and car model.")
                    safetyRow(icon: "lock.shield.fill", title: "PIN verification", detail: "Share a 4-digit PIN with your driver before boarding.")
                }

                Section("After a Trip") {
                    safetyRow(icon: "flag.fill", title: "Report a safety issue", detail: "Report any concerns directly from your trip history.")
                    safetyRow(icon: "star.fill", title: "Rate your driver", detail: "Your rating helps maintain ride quality for everyone.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(CityRideTheme.background)
            .navigationTitle("Safety Toolkit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func safetyRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(CityRideTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(CityRideTheme.muted)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct InboxSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let notifications: [(icon: String, title: String, body: String, time: String)] = [
        ("gift.fill", "Weekend promo", "Get 20% off your next 3 rides this weekend. Code auto-applies.", "2h ago"),
        ("car.fill", "Trip completed", "Your trip to Financial District has been completed. Rate your driver.", "Yesterday"),
        ("crown.fill", "Try CityRide One", "Save an average of $15/month with free delivery and ride discounts.", "2 days ago"),
        ("shield.fill", "Safety update", "We've added new safety features. Tap to learn more about PIN verification.", "3 days ago"),
        ("star.fill", "Rate your ride", "How was your recent trip with Marcus? Your feedback helps improve rides.", "4 days ago")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(notifications.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: notifications[index].icon)
                            .font(.headline)
                            .foregroundStyle(CityRideTheme.accent)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(notifications[index].title)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(notifications[index].time)
                                    .font(.caption2)
                                    .foregroundStyle(CityRideTheme.muted)
                            }
                            Text(notifications[index].body)
                                .font(.caption)
                                .foregroundStyle(CityRideTheme.muted)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(CityRideTheme.background)
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
