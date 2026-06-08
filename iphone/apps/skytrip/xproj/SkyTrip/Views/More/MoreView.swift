import SwiftUI

private struct MoreMenuItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
}

struct MoreView: View {
    @ObservedObject var viewModel: MoreViewModel

    @State private var notificationsEnabled = true
    @State private var biometricEnabled = false
    @State private var showResetConfirmation = false
    @State private var selectedItem: MoreMenuItem?

    private let exploreItems: [MoreMenuItem] = [
        MoreMenuItem(id: "more_menu_flight_status_row", title: "Flight Status", detail: "Check current departure, gate, and arrival updates for tracked trips.", icon: "clock.arrow.trianglehead.counterclockwise.rotate.90"),
        MoreMenuItem(id: "more_menu_track_bags_row", title: "Track My Bags", detail: "Track the real-time status of your checked bags from check-in through baggage claim.", icon: "suitcase"),
        MoreMenuItem(id: "more_menu_sky_club_row", title: "SkyTrip Sky Club", detail: "Sky Club access requires a SkyTrip Sky Club membership or eligible SkyTrip One ticket. Visit skytrip.com for a full list of locations and hours.", icon: "cup.and.saucer"),
        MoreMenuItem(id: "more_menu_airport_maps_row", title: "Airport Maps", detail: "Interactive terminal maps with gate locations, restaurants, shops, and SkyTrip Sky Club lounges.", icon: "map"),
        MoreMenuItem(id: "more_menu_aircraft_row", title: "Aircraft", detail: "Aircraft details and seat-map previews are available in trip and seat views.", icon: "airplane"),
        MoreMenuItem(id: "more_menu_flight_schedules_row", title: "Flight Schedules", detail: "Browse SkyTrip flight schedules for popular domestic and international routes.", icon: "calendar.badge.clock"),
        MoreMenuItem(id: "more_menu_fees_row", title: "Baggage & Travel Fees", detail: "First checked bag is complimentary for SkyTrip SkyMiles Card Members. Standard checked bag fees start at $35 for the first bag and $45 for the second.", icon: "dollarsign.circle")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        exploreSection
                        travelerPaymentSection
                        notificationsSection
                        settingsSection
                        helpSection

                        NavigationLink {
                            DebugImportView(viewModel: viewModel)
                        } label: {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver")
                                    .font(.system(size: 16))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                                    .frame(width: 28)
                                Text("Debug / Import")
                                    .font(.system(size: 16))
                                    .foregroundStyle(SkyTripTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                            }
                            .padding(14)
                            .background(SkyTripTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more_debug_import_row")

                        Button("Reset App State") {
                            showResetConfirmation = true
                        }
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SkyTripTheme.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityIdentifier("profile_reset_app_state")
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
                .background(SkyTripTheme.surface)
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Reset app state?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                    .accessibilityIdentifier("more_reset_cancel_button")
                Button("Reset", role: .destructive) {
                    viewModel.resetAppState()
                }
                .accessibilityIdentifier("more_reset_confirm_button")
            } message: {
                Text("This clears persisted trips, boarding passes, and fare mode selections.")
            }
            .sheet(item: $selectedItem) { item in
                PlaceholderDetailView(item: item)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("More")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            Button {
                selectedItem = MoreMenuItem(
                    id: "more_account_info",
                    title: "Account Info",
                    detail: "This app stays signed in to the default account. Use Reset App State to restore trips, boarding passes, and fare mode defaults.",
                    icon: ""
                )
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.8))
            }
                .buttonStyle(.plain)
                .accessibilityIdentifier("more_account_button")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SkyTripTheme.navy)
    }

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EXPLORE")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(exploreItems) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        menuRow(item.title, icon: item.icon, identifier: item.id)
                    }
                    .buttonStyle(.plain)
                    // Lift the row id onto the Button itself in addition to
                    // the inner HStack so Appium can locate the tap target
                    // by accessibility id when the tab is freshly
                    // foregrounded (some SwiftUI builds don't propagate the
                    // label's identifier up to the Button's wrapper element).
                    .accessibilityIdentifier(item.id)
                    if item.id != exploreItems.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var travelerPaymentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRAVELER & PAYMENT")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("more_traveler_payment_title")

            VStack(spacing: 0) {
                Button {
                    selectedItem = MoreMenuItem(id: "more_saved_travelers_placeholder", title: "Saved Travelers", detail: "Manage your saved traveler profiles to speed up future bookings. Add names, Known Traveler Numbers, and redress numbers for frequent companions.", icon: "person.2")
                } label: {
                    menuRow("Saved Travelers", icon: "person.2", identifier: "more_saved_travelers_placeholder")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button {
                    selectedItem = MoreMenuItem(id: "more_saved_payment_methods_placeholder", title: "Saved Payment Methods", detail: "Manage your saved credit and debit cards for faster checkout. SkyTrip SkyMiles Card Members enjoy priority boarding and free checked bags.", icon: "creditcard")
                } label: {
                    menuRow("Saved Payment Methods", icon: "creditcard", identifier: "more_saved_payment_methods_placeholder")
                }
                .buttonStyle(.plain)
            }
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTIFICATIONS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("more_notifications_title")

            if viewModel.store.alerts.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 14))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text("No notifications")
                        .font(.system(size: 14))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier("more_notifications_empty_state")
            } else {
                ForEach(viewModel.store.alerts) { alert in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(alert.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SkyTripTheme.textPrimary)
                                .accessibilityIdentifier("more_notification_title_\(alert.id)")
                            Spacer()
                            Text(alert.severity.rawValue.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(SkyTripTheme.alertChipColor(for: alert.severity))
                                .foregroundStyle(SkyTripTheme.alertTextColor(for: alert.severity))
                                .clipShape(Capsule())
                                .accessibilityIdentifier("more_notification_chip_\(alert.id)")
                        }
                        Text(alert.message)
                            .font(.system(size: 12))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .accessibilityIdentifier("more_notification_message_\(alert.id)")
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityIdentifier("more_notification_row_\(alert.id)")
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APP SETTINGS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("more_app_settings_title")

            VStack(spacing: 0) {
                Toggle(isOn: $notificationsEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 14))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .frame(width: 24)
                        Text("Push Notifications")
                            .font(.system(size: 15))
                    }
                }
                .tint(SkyTripTheme.red)
                .padding(14)
                .accessibilityIdentifier("more_settings_notifications_toggle")

                Divider().padding(.leading, 52)

                Toggle(isOn: $biometricEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.system(size: 14))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .frame(width: 24)
                        Text("Biometric App Lock")
                            .font(.system(size: 15))
                    }
                }
                .tint(SkyTripTheme.red)
                .padding(14)
                .accessibilityIdentifier("more_settings_biometrics_toggle")
            }
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HELP & FEEDBACK")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("more_support_title")

            VStack(spacing: 0) {
                Button {
                    selectedItem = MoreMenuItem(id: "more_help_center_row", title: "Help Center", detail: "Find answers to common questions about flights, SkyMiles, baggage, and more.", icon: "questionmark.circle")
                } label: {
                    menuRow("Help Center", icon: "questionmark.circle", identifier: "more_help_center_row")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button {
                    selectedItem = MoreMenuItem(id: "more_contact_support_row", title: "Message Us", detail: "Chat with a SkyTrip representative for help with reservations, SkyMiles, or travel disruptions.", icon: "message")
                } label: {
                    menuRow("Message Us", icon: "message", identifier: "more_contact_support_row")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button {
                    selectedItem = MoreMenuItem(id: "more_call_support_row", title: "Call Us", detail: "Speak with a SkyTrip agent at 1-800-555-0199. Medallion members can access priority support lines.", icon: "phone")
                } label: {
                    menuRow("Call Us", icon: "phone", identifier: "more_call_support_row")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button {
                    selectedItem = MoreMenuItem(id: "more_baggage_faq_row", title: "Baggage FAQs", detail: "Carry-on bags must fit in the overhead bin or under the seat. Checked bags may not exceed 50 lbs or 62 linear inches. Special items such as sporting equipment may incur additional fees.", icon: "suitcase")
                } label: {
                    menuRow("Baggage FAQs", icon: "suitcase", identifier: "more_baggage_faq_row")
                }
                .buttonStyle(.plain)
            }
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func menuRow(_ title: String, icon: String, identifier: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        .padding(.horizontal, 14)
        .accessibilityIdentifier(identifier)
    }
}

private struct PlaceholderDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let item: MoreMenuItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailContent
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .background(SkyTripTheme.surface)
            .navigationTitle(item.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("\(item.id)_detail_done_button")
                }
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch item.id {
        case "more_menu_flight_status_row":
            flightStatusContent
        case "more_menu_track_bags_row":
            trackBagsContent
        case "more_menu_sky_club_row":
            skyClubContent
        case "more_menu_airport_maps_row":
            airportMapsContent
        case "more_menu_aircraft_row":
            aircraftContent
        case "more_menu_flight_schedules_row":
            flightSchedulesContent
        case "more_menu_fees_row":
            baggageFeesContent
        case "more_saved_travelers_placeholder":
            savedTravelersContent
        case "more_saved_payment_methods_placeholder":
            savedPaymentMethodsContent
        case "more_help_center_row", "more_contact_support_row", "more_call_support_row", "more_baggage_faq_row":
            helpFAQContent
        default:
            Text(item.detail)
                .font(.body)
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("\(item.id)_detail_text")
        }
    }

    // MARK: - Flight Status

    private var flightStatusContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Look Up Flight Status")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                    .accessibilityIdentifier("flight_status_lookup_title")

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FROM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .tracking(0.5)
                        Text("Origin (e.g. ATL)")
                            .font(.system(size: 15))
                            .foregroundStyle(SkyTripTheme.textSecondary.opacity(0.6))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .tracking(0.5)
                        Text("Destination (e.g. JFK)")
                            .font(.system(size: 15))
                            .foregroundStyle(SkyTripTheme.textSecondary.opacity(0.6))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text("Today, Mar 10")
                        .font(.system(size: 15))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                .padding(12)
                .background(SkyTripTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(16)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityIdentifier("flight_status_lookup_form")

            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT STATUS CHECKS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                    .accessibilityIdentifier("flight_status_recent_title")

                recentStatusCard(flight: "DL 1492", route: "ATL → LAX", status: "On Time", statusColor: Color(red: 225/255, green: 244/255, blue: 234/255), statusTextColor: Color(red: 16/255, green: 118/255, blue: 62/255), time: "Departs 2:35 PM")
                recentStatusCard(flight: "DL 872", route: "JFK → LHR", status: "Delayed", statusColor: Color(red: 254/255, green: 242/255, blue: 224/255), statusTextColor: Color(red: 168/255, green: 95/255, blue: 0/255), time: "Departs 7:10 PM (was 6:45 PM)")
                recentStatusCard(flight: "DL 2241", route: "SEA → MSP", status: "On Time", statusColor: Color(red: 225/255, green: 244/255, blue: 234/255), statusTextColor: Color(red: 16/255, green: 118/255, blue: 62/255), time: "Departs 11:20 AM")
            }
        }
    }

    private func recentStatusCard(flight: String, route: String, status: String, statusColor: Color, statusTextColor: Color, time: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flight)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                Text(route)
                    .font(.system(size: 14))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Spacer()
                Text(status)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(statusColor)
                    .foregroundStyle(statusTextColor)
                    .clipShape(Capsule())
            }
            Text(time)
                .font(.system(size: 12))
                .foregroundStyle(SkyTripTheme.textSecondary)
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Track Bags

    private var trackBagsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "suitcase.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(SkyTripTheme.navy)
                    Text("Bag Claim Info")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                }
                .accessibilityIdentifier("track_bags_header")

                VStack(spacing: 0) {
                    bagInfoRow(label: "Bag Tag Number", value: "DL 0117 842 395")
                    Divider().padding(.leading, 14)
                    bagInfoRow(label: "Claim Reference", value: "ATLBG82947")
                    Divider().padding(.leading, 14)
                    bagInfoRow(label: "Last Scan Location", value: "ATL Domestic Terminal S")
                    Divider().padding(.leading, 14)
                    bagInfoRow(label: "Status", value: "Loaded on Aircraft")
                }
            }
            .padding(16)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityIdentifier("track_bags_claim_card")

            VStack(alignment: .leading, spacing: 12) {
                Text("HOW BAG TRACKING WORKS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                    .accessibilityIdentifier("track_bags_info_title")

                bagInfoBullet(icon: "barcode.viewfinder", text: "Each checked bag receives a unique RFID tag scanned at every checkpoint.")
                bagInfoBullet(icon: "antenna.radiowaves.left.and.right", text: "Scanners at ticket counters, TSA, and ramp areas record bag location in real time.")
                bagInfoBullet(icon: "bell.badge", text: "Push notifications alert you when your bag is loaded and when it reaches the carousel.")
                bagInfoBullet(icon: "exclamationmark.triangle", text: "If a bag is delayed or misrouted, SkyTrip will proactively notify you with recovery options.")
            }
            .padding(16)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityIdentifier("track_bags_info_card")
        }
    }

    private func bagInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textPrimary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    private func bagInfoBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.navy)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.textPrimary)
        }
    }

    // MARK: - Sky Club

    private var skyClubContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SKY CLUB LOCATIONS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("sky_club_directory_title")

            skyClubCard(airport: "SFO", terminal: "Terminal 2, near Gate D5", hours: "5:00 AM - 10:30 PM", amenities: ["WiFi", "Showers", "Premium Dining", "Runway Views"], capacity: 0.55)
            skyClubCard(airport: "ATL", terminal: "Concourse B", hours: "5:00 AM - 10:00 PM", amenities: ["WiFi", "Showers", "Premium Bar", "Sky Deck"], capacity: 0.72)
            skyClubCard(airport: "JFK", terminal: "Terminal 4, Concourse B", hours: "5:30 AM - 11:00 PM", amenities: ["WiFi", "Showers", "Premium Bar", "Dining"], capacity: 0.85)
            skyClubCard(airport: "LAX", terminal: "Terminal 2/3", hours: "4:30 AM - 11:30 PM", amenities: ["WiFi", "Premium Bar", "Relaxation Area"], capacity: 0.58)
            skyClubCard(airport: "MSP", terminal: "Terminal 1, Concourse G", hours: "5:00 AM - 9:30 PM", amenities: ["WiFi", "Showers", "Dining"], capacity: 0.45)
            skyClubCard(airport: "SEA", terminal: "South Satellite", hours: "5:00 AM - 10:30 PM", amenities: ["WiFi", "Premium Bar", "Panoramic Views"], capacity: 0.62)
        }
    }

    private func skyClubCard(airport: String, terminal: String, hours: String, amenities: [String], capacity: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(airport)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SkyTripTheme.navy)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(capacity < 0.5 ? Color.green : (capacity < 0.8 ? Color.orange : Color.red))
                        .frame(width: 8, height: 8)
                    Text(capacity < 0.5 ? "Low" : (capacity < 0.8 ? "Moderate" : "Busy"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
            }

            Text(terminal)
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.textPrimary)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text(hours)
                    .font(.system(size: 13))
                    .foregroundStyle(SkyTripTheme.textSecondary)
            }

            HStack(spacing: 6) {
                ForEach(amenities, id: \.self) { amenity in
                    Text(amenity)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(SkyTripTheme.surface)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .clipShape(Capsule())
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SkyTripTheme.surface)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(capacity < 0.5 ? Color.green : (capacity < 0.8 ? Color.orange : SkyTripTheme.red))
                        .frame(width: geo.size.width * capacity, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Airport Maps

    private var airportMapsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TERMINAL DIRECTORY")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("airport_maps_directory_title")

            airportMapCard(
                airport: "ATL", name: "Hartsfield-Jackson Atlanta",
                concourses: [
                    ("T", "Gates T1-T14", "Ticketing, Ground Transport"),
                    ("A", "Gates A1-A34", "Sky Club, Sky Priority"),
                    ("B", "Gates B1-B36", "Sky Club, Food Court"),
                    ("C", "Gates C1-C48", "International, Sky Club"),
                    ("D", "Gates D1-D42", "Sky Club, Concessions"),
                    ("E", "Gates E1-E36", "International, Customs")
                ]
            )

            airportMapCard(
                airport: "JFK", name: "John F. Kennedy International",
                concourses: [
                    ("T4-A", "Gates A2-A12", "Sky Club, Retail"),
                    ("T4-B", "Gates B20-B47", "Sky Club, Food Court, Sky Priority")
                ]
            )

            airportMapCard(
                airport: "LAX", name: "Los Angeles International",
                concourses: [
                    ("T2", "Gates 21-28A", "Sky Priority"),
                    ("T3", "Gates 31-39", "Sky Club, Food Court")
                ]
            )

            airportMapCard(
                airport: "SFO", name: "San Francisco International",
                concourses: [
                    ("T2", "Gates D1-D18", "Sky Club, SkyTrip Check-In"),
                    ("T2", "Gates D1-D10", "Food Court, Retail, Sky Priority"),
                    ("Int'l", "Gates G91-G102", "International Arrivals, Customs")
                ]
            )

            airportMapCard(
                airport: "SEA", name: "Seattle-Tacoma International",
                concourses: [
                    ("S", "Gates S1-S16", "Sky Club"),
                    ("Satellite", "Gates S1-S10", "Food Court, Retail")
                ]
            )
        }
    }

    private func airportMapCard(airport: String, name: String, concourses: [(letter: String, gates: String, amenities: String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(airport)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SkyTripTheme.navy)
                Text(name)
                    .font(.system(size: 13))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .lineLimit(1)
            }

            ForEach(Array(concourses.enumerated()), id: \.offset) { _, concourse in
                HStack(alignment: .top, spacing: 10) {
                    Text(concourse.letter)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(SkyTripTheme.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(concourse.gates)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SkyTripTheme.textPrimary)
                        Text(concourse.amenities)
                            .font(.system(size: 11))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Aircraft

    private var aircraftContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SKYTRIP FLEET")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("aircraft_fleet_title")

            aircraftCard(name: "Boeing 737-900ER", seats: "180", range: "3,200 nmi", wifi: true, cabins: ["First Class", "SkyTrip Comfort+", "Main Cabin"])
            aircraftCard(name: "Airbus A321neo", seats: "194", range: "4,000 nmi", wifi: true, cabins: ["First Class", "SkyTrip Comfort+", "Main Cabin"])
            aircraftCard(name: "Boeing 767-300ER", seats: "226", range: "5,990 nmi", wifi: true, cabins: ["SkyTrip One", "SkyTrip Premium Select", "SkyTrip Comfort+", "Main Cabin"])
            aircraftCard(name: "Airbus A330-900neo", seats: "281", range: "7,200 nmi", wifi: true, cabins: ["SkyTrip One Suite", "SkyTrip Premium Select", "SkyTrip Comfort+", "Main Cabin"])
        }
    }

    private func aircraftCard(name: String, seats: String, range: String, wifi: Bool, cabins: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                Spacer()
                Image(systemName: "airplane")
                    .font(.system(size: 14))
                    .foregroundStyle(SkyTripTheme.navy)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text("\(seats) seats")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text(range)
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                if wifi {
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.system(size: 11))
                            .foregroundStyle(SkyTripTheme.navy)
                        Text("WiFi")
                            .font(.system(size: 13))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                }
            }

            HStack(spacing: 6) {
                ForEach(cabins, id: \.self) { cabin in
                    Text(cabin)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(SkyTripTheme.surface)
                        .foregroundStyle(SkyTripTheme.navy)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Flight Schedules

    private var flightSchedulesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("POPULAR ROUTES")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("flight_schedules_popular_title")

            routeCard(origin: "ATL", destination: "JFK", frequency: "12 daily", aircraft: "A321neo / 737-900ER")
            routeCard(origin: "ATL", destination: "LAX", frequency: "10 daily", aircraft: "A321neo / 767-300ER")
            routeCard(origin: "JFK", destination: "LHR", frequency: "4 daily", aircraft: "A330-900neo")
            routeCard(origin: "MSP", destination: "ATL", frequency: "8 daily", aircraft: "737-900ER")
            routeCard(origin: "SEA", destination: "NRT", frequency: "1 daily", aircraft: "A330-900neo")
            routeCard(origin: "SFO", destination: "JFK", frequency: "6 daily", aircraft: "A321neo / 767-300ER")
            routeCard(origin: "SFO", destination: "SEA", frequency: "8 daily", aircraft: "737-900ER")
            routeCard(origin: "SFO", destination: "NRT", frequency: "1 daily", aircraft: "A330-900neo")
        }
    }

    private func routeCard(origin: String, destination: String, frequency: String, aircraft: String) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(origin)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SkyTripTheme.navy)
                Text("")
                    .font(.system(size: 10))
            }
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
            VStack(spacing: 2) {
                Text(destination)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SkyTripTheme.navy)
                Text("")
                    .font(.system(size: 10))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(frequency)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                Text(aircraft)
                    .font(.system(size: 11))
                    .foregroundStyle(SkyTripTheme.textSecondary)
            }
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Baggage & Travel Fees

    private var baggageFeesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("CHECKED BAG FEES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                    .accessibilityIdentifier("baggage_fees_checked_title")

                VStack(spacing: 0) {
                    feeRow(item: "1st Checked Bag", fee: "$35")
                    Divider().padding(.leading, 14)
                    feeRow(item: "2nd Checked Bag", fee: "$45")
                    Divider().padding(.leading, 14)
                    feeRow(item: "3rd+ Checked Bag", fee: "$150")
                }
            }
            .padding(16)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Text("OVERWEIGHT / OVERSIZE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)

                VStack(spacing: 0) {
                    feeRow(item: "Overweight (51-70 lbs)", fee: "$100")
                    Divider().padding(.leading, 14)
                    feeRow(item: "Overweight (71-100 lbs)", fee: "$200")
                    Divider().padding(.leading, 14)
                    feeRow(item: "Oversize (63-80 in)", fee: "$200")
                }
            }
            .padding(16)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Text("SPECIAL ITEMS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)

                VStack(spacing: 0) {
                    feeRow(item: "Sporting Equipment", fee: "$150")
                    Divider().padding(.leading, 14)
                    feeRow(item: "Musical Instruments", fee: "$150")
                    Divider().padding(.leading, 14)
                    feeRow(item: "Pet in Cabin", fee: "$125")
                }
            }
            .padding(16)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(SkyTripTheme.navy)
                    .padding(.top, 2)
                Text("SkyTrip SkyMiles Card Members receive their first checked bag free on SkyTrip-marketed flights.")
                    .font(.system(size: 14))
                    .foregroundStyle(SkyTripTheme.textPrimary)
            }
            .padding(14)
            .background(Color(red: 225/255, green: 236/255, blue: 252/255))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("baggage_fees_amex_note")
        }
    }

    private func feeRow(item: String, fee: String) -> some View {
        HStack {
            Text(item)
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.textPrimary)
            Spacer()
            Text(fee)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SkyTripTheme.navy)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    // MARK: - Saved Travelers

    private var savedTravelersContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SAVED TRAVELERS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("saved_travelers_title")

            travelerCard(name: "Jordan Mitchell", ktn: "TT1284790", seatPref: "Window", mealPref: "No preference")
            travelerCard(name: "Alex Mitchell", ktn: "TT0937215", seatPref: "Aisle", mealPref: "Vegetarian")
        }
    }

    private func travelerCard(name: String, ktn: String, seatPref: String, mealPref: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(SkyTripTheme.navy)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                    Text("KTN: \(ktn)")
                        .font(.system(size: 12))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
            }
            Divider()
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Seat Preference")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .tracking(0.3)
                    Text(seatPref)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meal Preference")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .tracking(0.3)
                    Text(mealPref)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                }
            }
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Saved Payment Methods

    private var savedPaymentMethodsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PAYMENT METHODS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("saved_payment_methods_title")

            paymentCard(type: "SkyTrip SkyMiles Card", lastFour: "4829", icon: "creditcard.fill", isDefault: true)
            paymentCard(type: "Visa", lastFour: "7156", icon: "creditcard", isDefault: false)
        }
    }

    private func paymentCard(type: String, lastFour: String, icon: String, isDefault: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(SkyTripTheme.navy)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(type)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                    if isDefault {
                        Text("Default")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(SkyTripTheme.navy)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                Text("ending in \(lastFour)")
                    .font(.system(size: 13))
                    .foregroundStyle(SkyTripTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Help / FAQ

    private var helpFAQContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.detail)
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier("\(item.id)_detail_text")

            Text("FREQUENTLY ASKED QUESTIONS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("\(item.id)_faq_title")

            faqRow(question: "How do I change or cancel my flight?", answer: "You can change or cancel most tickets through the Fly SkyTrip app or at skytrip.com. Basic Economy tickets are non-changeable and non-refundable.")
            faqRow(question: "What is the carry-on bag size limit?", answer: "Carry-on bags must fit in the overhead bin or under the seat ahead of you. Maximum dimensions: 22\" x 14\" x 9\" including handles and wheels.")
            faqRow(question: "How early should I arrive at the airport?", answer: "We recommend arriving 2 hours before domestic flights and 3 hours before international flights.")
            faqRow(question: "Can I select my seat in advance?", answer: "Yes, most tickets allow advance seat selection. SkyTrip Comfort+ and higher cabins include complimentary preferred seat selection.")
            faqRow(question: "How do I earn Medallion Status?", answer: "Earn Medallion Qualification Dollars (MQDs) through eligible SkyTrip flights and SkyTrip SkyMiles credit card spending to qualify for Silver, Gold, Platinum, or Diamond status.")
        }
    }

    private func faqRow(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(question)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
            }
            Text(answer)
                .font(.system(size: 13))
                .foregroundStyle(SkyTripTheme.textSecondary)
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DebugImportView: View {
    @ObservedObject var viewModel: MoreViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fare Debug / Import")
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("debug_import_title")

                Picker("Fare Source", selection: Binding(
                    get: { viewModel.fareSourceType },
                    set: { viewModel.fareSourceType = $0 }
                )) {
                    Text("Default").tag(FareSourceType.seeded)
                    Text("Snapshot").tag(FareSourceType.snapshot)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("debug_fare_source_picker")

                Text("Current fare source: \(viewModel.fareSourceType.displayName)")
                    .font(.subheadline)
                    .accessibilityIdentifier("debug_current_fare_source_label")

                if let metadata = viewModel.snapshotMetadata {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Provider: \(metadata.providerLabel)")
                            .accessibilityIdentifier("debug_snapshot_provider_label")
                        Text("Snapshot timestamp: \(metadata.snapshotTimestamp)")
                            .accessibilityIdentifier("debug_snapshot_timestamp_label")
                        Text("Last updated: \(metadata.lastUpdated)")
                            .accessibilityIdentifier("debug_snapshot_last_updated_label")
                    }
                    .font(.caption)
                } else {
                    Text("Snapshot Data Unavailable")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("debug_snapshot_unavailable_state")
                }

                Text("Active snapshot path: \(viewModel.snapshotSourcePath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("debug_snapshot_source_path")

                if let snapshotError = viewModel.snapshotError {
                    Text(snapshotError)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("debug_snapshot_error_label")
                }

                Button {
                    viewModel.reloadBundledSnapshot()
                } label: {
                    Text("Reload Bundled Snapshot Data")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(SkyTripTheme.navy)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("debug_reload_snapshot_button")

                Button {
                    viewModel.refreshSnapshotStatus()
                } label: {
                    Text("Refresh Snapshot Status")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .foregroundStyle(SkyTripTheme.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(SkyTripTheme.navy, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("debug_refresh_snapshot_button")

                Button {
                    viewModel.resetPersistence()
                } label: {
                    Text("Reset Persistence")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .foregroundStyle(SkyTripTheme.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(SkyTripTheme.red, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("debug_reset_persistence_button")

                if let debugMessage = viewModel.debugMessage {
                    Text(debugMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("debug_message_label")
                }
            }
            .padding()
        }
        .background(SkyTripTheme.surface)
        .navigationTitle("Debug / Import")
    }
}
