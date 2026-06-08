import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    @State private var showCheckInSheet = false
    @State private var checkInTripID: String?
    @State private var showNotifications = false
    @State private var showNoCheckInAlert = false
    @State private var showBagTracking = false
    @State private var showTripDetail: Trip?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        whereToCard

                        if let checkInTrip = viewModel.checkInEligibleTrip {
                            checkInPrompt(trip: checkInTrip)
                        }

                        if let upcomingTrip = viewModel.upcomingTrip {
                            myDayCard(upcomingTrip)
                        } else {
                            emptyUpcomingTripsState
                        }

                        quickActionsGrid

                        if let statusTrip = viewModel.upcomingTrip {
                            flightStatusCard(trip: statusTrip)
                        }

                        recentSearchesSection
                        skyMilesSummaryCard
                        alertsSection
                    }
                    .padding(16)
                    .padding(.bottom, 28)
                }
                .background(SkyTripTheme.surface)
            }
            .background(SkyTripTheme.navy.ignoresSafeArea(edges: .top))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCheckInSheet) {
                CheckInFlowView(store: viewModel.store, preselectedTripID: checkInTripID)
            }
            .sheet(isPresented: $showNotifications) {
                AlertsCenterView(alerts: viewModel.store.alerts)
            }
            .alert("No Eligible Trips", isPresented: $showNoCheckInAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Check-in is not available at this time. Check-in opens 24 hours before departure.")
            }
            .sheet(item: $showTripDetail) { trip in
                TripDetailSheet(trip: trip, store: viewModel.store)
            }
            .sheet(isPresented: $showBagTracking) {
                if let trip = viewModel.upcomingTrip {
                    BaggageTrackingView(trip: trip)
                } else {
                    NavigationStack {
                        VStack(spacing: 16) {
                            Image(systemName: "suitcase")
                                .font(.system(size: 44))
                                .foregroundStyle(SkyTripTheme.textSecondary.opacity(0.5))
                            Text("No Upcoming Trips")
                                .font(.headline)
                                .foregroundStyle(SkyTripTheme.textPrimary)
                            Text("Bag tracking is available once you have an upcoming trip.")
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(SkyTripTheme.surface)
                        .navigationTitle("Baggage")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showBagTracking = false }
                                    .accessibilityIdentifier("bag_tracking_no_trip_done_button")
                            }
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.timeOfDayGreeting),")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Text(viewModel.profileFirstName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("home_greeting_label")
                }
                Spacer()
                HStack(spacing: 14) {
                    Button {
                        showNotifications = true
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_notifications_button")

                    Button {
                        viewModel.store.showWalletSection(.profile)
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_profile_icon")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 14)

            HStack(spacing: 12) {
                Text("#\(viewModel.skyMiles.memberNumber)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .accessibilityIdentifier("home_subtitle_label")
                Text("|")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.4))
                Text("\(viewModel.skyMiles.redeemableMiles) Miles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(SkyTripTheme.navy)
    }

    private var whereToCard: some View {
        Button {
            viewModel.runQuickAction(.bookFlights)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text("Where To?")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home_where_to_card")
    }

    private func flightProgress(for trip: Trip) -> Double {
        guard let segment = trip.outboundSegments.first else { return 0 }
        let now = Date()
        if now < segment.departureTime { return 0 }
        if now > segment.arrivalTime { return 1 }
        let total = segment.arrivalTime.timeIntervalSince(segment.departureTime)
        guard total > 0 else { return 0 }
        return now.timeIntervalSince(segment.departureTime) / total
    }

    private func myDayCard(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("MY DAY")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                    .accessibilityIdentifier("home_upcoming_trip_title")
                Spacer()
                Text(trip.operationalStatus.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(StatusBadgeStyle.color(for: trip.operationalStatus))
                    .foregroundStyle(StatusBadgeStyle.textColor(for: trip.operationalStatus))
                    .clipShape(Capsule())
                    .accessibilityIdentifier("home_upcoming_status_chip")
            }

            Button {
                showTripDetail = trip
            } label: {
                myDayRouteSection(trip)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_upcoming_trip_route")

            Divider()

            HStack(spacing: 0) {
                infoPill(
                    title: "FLIGHT",
                    value: trip.primaryFlightNumber,
                    id: "home_upcoming_trip_flight"
                )
                Spacer()
                infoPill(
                    title: "DEPARTS",
                    value: AppFormatters.time(trip.departureTime),
                    id: "home_upcoming_trip_departure"
                )
                Spacer()
                infoPill(
                    title: "SEAT",
                    value: trip.seatAssignment ?? "—",
                    id: "home_upcoming_seat_label"
                )
                Spacer()
                infoPill(
                    title: "GATE",
                    value: trip.outboundSegments.first?.gate ?? "—",
                    id: "home_upcoming_trip_gate"
                )
            }

            HStack(spacing: 10) {
                Button {
                    if trip.checkInEligible && !trip.checkedIn {
                        checkInTripID = trip.id
                        showCheckInSheet = true
                    } else {
                        viewModel.runQuickAction(.boardingPass)
                    }
                } label: {
                    Text(trip.checkInEligible && !trip.checkedIn ? "Check In" : "Boarding Pass")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(SkyTripTheme.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home_upcoming_primary_action")

                Button {
                    viewModel.runQuickAction(.flightStatus)
                } label: {
                    Text("Flight Status")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(SkyTripTheme.navy, lineWidth: 1.5)
                        )
                        .foregroundStyle(SkyTripTheme.navy)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home_upcoming_flight_status_button")
            }

            Text("Confirmation: \(trip.confirmationCode)")
                .font(.system(size: 12))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .accessibilityIdentifier("home_upcoming_trip_confirmation")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .accessibilityIdentifier("home_upcoming_trip_card")
    }

    private func myDayRouteSection(_ trip: Trip) -> some View {
        let progress = flightProgress(for: trip)
        return VStack(spacing: 4) {
            HStack(alignment: .center) {
                VStack(spacing: 2) {
                    Text(trip.outboundSegments.first?.origin.code ?? "---")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                    Text(trip.outboundSegments.first?.origin.city ?? "")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                Spacer()
                VStack(spacing: 4) {
                    Text(AppFormatters.duration(minutes: trip.outboundSegments.first?.durationMinutes ?? 0))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    flightProgressBar(progress: progress)
                        .frame(maxWidth: 120)
                    Text(trip.outboundSegments.count <= 1 ? "Nonstop" : "\(trip.outboundSegments.count - 1) Stop")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(trip.outboundSegments.last?.destination.code ?? "---")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                    Text(trip.outboundSegments.last?.destination.city ?? "")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
            }
            if progress > 0 && progress < 1 {
                Text("\(Int((1 - progress) * Double(trip.outboundSegments.first?.durationMinutes ?? 0)))min remaining")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("home_upcoming_trip_remaining")
            }
        }
    }

    private func flightProgressBar(progress: Double) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clampedProgress = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Circle()
                        .fill(progress > 0 ? SkyTripTheme.red : SkyTripTheme.red)
                        .frame(width: 6, height: 6)
                    Rectangle()
                        .fill(SkyTripTheme.red.opacity(0.2))
                        .frame(height: 1.5)
                    Circle()
                        .fill(progress >= 1 ? SkyTripTheme.red : SkyTripTheme.red.opacity(0.3))
                        .frame(width: 6, height: 6)
                }

                if progress > 0 {
                    Rectangle()
                        .fill(SkyTripTheme.red)
                        .frame(width: max(0, (width - 12) * clampedProgress + 6), height: 2)
                        .offset(x: 3)
                }

                Image(systemName: "airplane")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(SkyTripTheme.red)
                    .offset(x: max(0, (width - 12) * clampedProgress))
            }
        }
        .frame(height: 12)
    }

    private func checkInPrompt(trip: Trip) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(SkyTripTheme.red)
            VStack(alignment: .leading, spacing: 2) {
                Text("Check-In Available")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                    .accessibilityIdentifier("home_checkin_prompt_title")
                Text("\(trip.routeText) · \(trip.primaryFlightNumber)")
                    .font(.caption)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("home_checkin_prompt_trip")
            }
            Spacer()
            Button {
                checkInTripID = trip.id
                showCheckInSheet = true
            } label: {
                Text("Check In")
                    .font(.caption.weight(.bold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(SkyTripTheme.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_checkin_prompt_button")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .accessibilityIdentifier("home_checkin_prompt_card")
    }

    private func flightStatusCard(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FLIGHT STATUS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                    .accessibilityIdentifier("home_flight_status_title")
                Spacer()
            }

            HStack {
                Text("\(trip.primaryFlightNumber) · \(trip.routeText)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                    .accessibilityIdentifier("home_flight_status_route")
                Spacer()
                Text(trip.operationalStatus.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(StatusBadgeStyle.color(for: trip.operationalStatus))
                    .foregroundStyle(StatusBadgeStyle.textColor(for: trip.operationalStatus))
                    .clipShape(Capsule())
                    .accessibilityIdentifier("home_flight_status_value")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("home_flight_status_card")
    }

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK ACTIONS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("home_quick_actions_title")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                quickActionTile(
                    title: "Book a\nFlight",
                    icon: "magnifyingglass",
                    id: "home_quick_action_book_search"
                ) {
                    viewModel.runQuickAction(.bookFlights)
                }
                quickActionTile(
                    title: "Check\nIn",
                    icon: "checkmark.circle",
                    id: "home_quick_action_checkin"
                ) {
                    if let eligibleTrip = viewModel.checkInEligibleTrip {
                        checkInTripID = eligibleTrip.id
                        showCheckInSheet = true
                    } else {
                        showNoCheckInAlert = true
                    }
                }
                quickActionTile(
                    title: "Boarding\nPass",
                    icon: "wallet.pass",
                    id: "home_quick_action_boarding_pass"
                ) {
                    viewModel.runQuickAction(.boardingPass)
                }
                quickActionTile(
                    title: "Flight\nStatus",
                    icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    id: "home_quick_action_flight_status"
                ) {
                    viewModel.runQuickAction(.flightStatus)
                }
                quickActionTile(
                    title: "Seat\nSelection",
                    icon: "square.grid.3x3",
                    id: "home_quick_action_seat_selection"
                ) {
                    viewModel.runQuickAction(.seatSelection)
                }
                quickActionTile(
                    title: "Track\nBags",
                    icon: "suitcase",
                    id: "home_quick_action_track_bags"
                ) {
                    showBagTracking = true
                }
            }
        }
    }

    private func quickActionTile(
        title: String,
        icon: String,
        id: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(SkyTripTheme.navy)
                    .frame(width: 36, height: 36)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(id)_label")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECENT SEARCHES")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("home_recent_searches_title")

            if viewModel.recentSearches.isEmpty {
                Text("No recent searches")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityIdentifier("home_recent_searches_empty")
            } else {
                ForEach(viewModel.recentSearches) { search in
                    Button {
                        viewModel.repeatSearch(search)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(search.originCode) → \(search.destinationCode)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SkyTripTheme.textPrimary)
                                    .accessibilityIdentifier("home_recent_search_route_\(search.id)")
                                Text("\(search.tripType.displayName) · \(AppFormatters.date(search.departureDate))")
                                    .font(.caption)
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                                    .accessibilityIdentifier("home_recent_search_date_\(search.id)")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        .padding(12)
                        .background(SkyTripTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_recent_search_row_\(search.id)")
                }
            }
        }
    }

    private var skyMilesSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SKYMILES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(1)
                    .accessibilityIdentifier("home_skymiles_title")
                Spacer()
                Text(viewModel.skyMiles.medallionLevel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .accessibilityIdentifier("home_skymiles_status")
            }
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(viewModel.skyMiles.redeemableMiles)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("home_skymiles_miles")
                Text("Miles Available")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            HStack(spacing: 8) {
                metricColumn(
                    label: "MQDs",
                    value: "$\(viewModel.skyMiles.mqds.formatted())",
                    id: "home_skymiles_mqds"
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SkyTripTheme.navyLight, SkyTripTheme.navy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier("home_skymiles_card")
    }

    private func metricColumn(label: String, value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .accessibilityIdentifier(id)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.7))
        }
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRAVEL ALERTS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("home_travel_alerts_title")

            ForEach(viewModel.alerts) { alert in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(alert.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SkyTripTheme.textPrimary)
                            .accessibilityIdentifier("home_alert_title_\(alert.id)")
                        Spacer()
                        Text(alert.severity.rawValue.capitalized)
                            .font(.caption2.weight(.semibold))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(SkyTripTheme.alertChipColor(for: alert.severity))
                            .foregroundStyle(SkyTripTheme.alertTextColor(for: alert.severity))
                            .clipShape(Capsule())
                            .accessibilityIdentifier("home_alert_severity_chip_\(alert.id)")
                    }
                    Text(alert.message)
                        .font(.caption)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .accessibilityIdentifier("home_alert_message_\(alert.id)")
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier("home_alert_row_\(alert.id)")
            }
        }
    }

    private var emptyUpcomingTripsState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No Upcoming Trips")
                .font(.headline)
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("home_no_upcoming_trips_title")
            Text("Your next adventure awaits. Search for flights to get started.")
                .font(.subheadline)
                .foregroundStyle(SkyTripTheme.textSecondary)
                .accessibilityIdentifier("home_no_upcoming_trips_message")
            Button {
                viewModel.runQuickAction(.bookFlights)
            } label: {
                Text("Search Flights")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(SkyTripTheme.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_no_upcoming_trips_action")
        }
        .padding(16)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier("home_no_upcoming_trips_state")
    }

    private func infoPill(title: String, value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier(id)
        }
    }
}

// MARK: - Trip Detail Sheet

private struct TripDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let trip: Trip
    @ObservedObject var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    routeHeader
                    statusCard
                    segmentsSection("Outbound", segments: trip.outboundSegments)
                    if trip.tripType == .roundTrip && !trip.returnSegments.isEmpty {
                        segmentsSection("Return", segments: trip.returnSegments)
                    }
                    detailsCard
                }
                .padding(16)
            }
            .background(SkyTripTheme.surface)
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("trip_detail_done_button")
                }
            }
        }
    }

    private var routeHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(trip.outboundSegments.first?.origin.code ?? "---")
                    .font(.system(size: 32, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text(trip.outboundSegments.last?.destination.code ?? "---")
                    .font(.system(size: 32, weight: .bold))
            }
            .foregroundStyle(SkyTripTheme.textPrimary)
            Text("Confirmation: \(trip.confirmationCode)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SkyTripTheme.red)
                .accessibilityIdentifier("trip_detail_confirmation")
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusCard: some View {
        HStack(spacing: 16) {
            statusPill(label: "Status", value: trip.operationalStatus.displayName)
            statusPill(label: "Seat", value: trip.seatAssignment ?? "TBD")
            statusPill(label: "Group", value: trip.boardingGroup)
            statusPill(label: "Bags", value: trip.baggageStatus)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statusPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func segmentsSection(_ title: String, segments: [FlightSegment]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)

            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(segment.carrierCode)\(segment.flightNumber)")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(SkyTripTheme.navy)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        Spacer()
                        Text(segment.status.displayName)
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(StatusBadgeStyle.color(for: segment.status))
                            .foregroundStyle(StatusBadgeStyle.textColor(for: segment.status))
                            .clipShape(Capsule())
                    }

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppFormatters.time(segment.departureTime))
                                .font(.system(size: 18, weight: .bold))
                            Text(segment.origin.code)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Text("T\(segment.terminal) · Gate \(segment.gate)")
                                .font(.system(size: 11))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }

                        VStack(spacing: 2) {
                            Text(AppFormatters.duration(minutes: segment.durationMinutes))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Rectangle()
                                .fill(SkyTripTheme.red.opacity(0.3))
                                .frame(width: 40, height: 1)
                            Image(systemName: "airplane")
                                .font(.system(size: 9))
                                .foregroundStyle(SkyTripTheme.red)
                        }
                        .padding(.top, 6)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(AppFormatters.time(segment.arrivalTime))
                                .font(.system(size: 18, weight: .bold))
                            Text(segment.destination.code)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        Spacer()
                    }
                }
                .padding(12)
                .background(SkyTripTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailRow("Passenger", trip.passenger.fullName)
            detailRow("SkyMiles #", trip.passenger.skyMilesNumber)
            detailRow("Trip Type", trip.tripType.displayName)
            detailRow("Total Price", AppFormatters.currency(trip.totalPrice, code: trip.currency))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(SkyTripTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textPrimary)
        }
    }
}

// MARK: - Baggage Tracking View

private struct BaggageTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    let trip: Trip

    private var events: [BaggageEvent] {
        let cal = Calendar.current
        let dep = trip.departureTime
        if trip.baggageStatus == "Carry-on only" {
            return [
                BaggageEvent(id: "bag_1", status: "Carry-On Only", location: "No checked bags", timestamp: dep, isCompleted: true)
            ]
        }
        let checkedBags = trip.baggageStatus.contains("1 checked") ? "1 bag" : "2 bags"
        return [
            BaggageEvent(id: "bag_1", status: "Checked In", location: "\(trip.outboundSegments.first?.origin.code ?? "") ticket counter — \(checkedBags)", timestamp: cal.date(byAdding: .minute, value: -120, to: dep) ?? dep, isCompleted: true),
            BaggageEvent(id: "bag_2", status: "Screened", location: "TSA screening complete", timestamp: cal.date(byAdding: .minute, value: -100, to: dep) ?? dep, isCompleted: true),
            BaggageEvent(id: "bag_3", status: "Loaded on Aircraft", location: "\(trip.primaryFlightNumber) · Gate \(trip.outboundSegments.first?.gate ?? "—")", timestamp: cal.date(byAdding: .minute, value: -30, to: dep) ?? dep, isCompleted: true),
            BaggageEvent(id: "bag_4", status: "In Transit", location: "En route to \(trip.outboundSegments.last?.destination.code ?? "destination")", timestamp: dep, isCompleted: trip.operationalStatus == .departed),
            BaggageEvent(id: "bag_5", status: "Arrived", location: "Carousel B3 · \(trip.outboundSegments.last?.destination.code ?? "")", timestamp: trip.outboundSegments.last?.arrivalTime ?? dep, isCompleted: false)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "suitcase.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(SkyTripTheme.navy)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Track My Bags")
                                .font(.headline)
                                .foregroundStyle(SkyTripTheme.textPrimary)
                            Text("\(trip.routeText) · \(trip.primaryFlightNumber)")
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityIdentifier("bag_tracking_header")

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                            HStack(alignment: .top, spacing: 14) {
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(event.isCompleted ? SkyTripTheme.red : SkyTripTheme.textSecondary.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                        .overlay {
                                            if event.isCompleted {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 7, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    if index < events.count - 1 {
                                        Rectangle()
                                            .fill(event.isCompleted ? SkyTripTheme.red.opacity(0.4) : SkyTripTheme.textSecondary.opacity(0.15))
                                            .frame(width: 2)
                                            .frame(minHeight: 36)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(event.status)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(event.isCompleted ? SkyTripTheme.textPrimary : SkyTripTheme.textSecondary)
                                    Text(event.location)
                                        .font(.system(size: 12))
                                        .foregroundStyle(SkyTripTheme.textSecondary)
                                    Text(AppFormatters.time(event.timestamp))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(SkyTripTheme.textSecondary.opacity(0.7))
                                }
                                .padding(.bottom, index < events.count - 1 ? 8 : 0)
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .background(SkyTripTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityIdentifier("bag_tracking_timeline")
                }
                .padding(16)
            }
            .background(SkyTripTheme.surface)
            .navigationTitle("Baggage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("bag_tracking_done_button")
                }
            }
        }
    }
}
