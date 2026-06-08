import SwiftUI

private enum TripsSection: String, CaseIterable, Identifiable {
    case myTrips = "My Trips"
    case findTrip = "Find a Trip"

    var id: String { rawValue }
}

struct TripsView: View {
    @ObservedObject var viewModel: TripsViewModel

    @State private var section: TripsSection = .myTrips
    @State private var path = NavigationPath()
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var confirmationCode = ""
    @State private var findTripError: String?
    @State private var foundTrip: Trip?
    @State private var showNotifications = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                content
            }
            .background(SkyTripTheme.surface)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { tripID in
                TripDetailView(viewModel: viewModel, tripID: tripID)
            }
            .sheet(isPresented: $showNotifications) {
                AlertsCenterView(alerts: viewModel.store.alerts)
            }
            .onChange(of: firstName) { _, _ in clearFindTripState() }
            .onChange(of: lastName) { _, _ in clearFindTripState() }
            .onChange(of: confirmationCode) { _, _ in clearFindTripState() }
            .onChange(of: section) { _, newValue in
                if newValue == .myTrips {
                    clearFindTripState()
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Trips")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("trips_header_title")
                Spacer()
                Button {
                    showNotifications = true
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("trips_notifications_button")
            }

            HStack(spacing: 0) {
                ForEach(TripsSection.allCases) { item in
                    Button {
                        section = item
                    } label: {
                        VStack(spacing: 8) {
                            Text(item.rawValue)
                                .font(.system(size: 14, weight: section == item ? .bold : .medium))
                                .foregroundStyle(section == item ? .white : Color.white.opacity(0.5))
                            Rectangle()
                                .fill(section == item ? Color.white : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .accessibilityIdentifier("trips_section_toggle")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
        .background(SkyTripTheme.navy)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if section == .myTrips {
                    myTripsSection
                } else {
                    findTripSection
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var myTripsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !viewModel.upcomingTrips.isEmpty {
                sectionTitle("UPCOMING", id: "trips_upcoming_title")

                ForEach(viewModel.upcomingTrips) { trip in
                    NavigationLink(value: trip.id) {
                        TripCardView(trip: trip)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("trip_row_\(trip.id)")
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "airplane")
                        .font(.system(size: 32))
                        .foregroundStyle(SkyTripTheme.textSecondary.opacity(0.5))
                    Text("No Upcoming Trips")
                        .font(.headline)
                        .foregroundStyle(SkyTripTheme.textPrimary)
                    Text("Book your next adventure to see it here.")
                        .font(.subheadline)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier("trips_no_upcoming_state")
            }

            if !viewModel.pastTrips.isEmpty {
                sectionTitle("PAST", id: "trips_past_title")

                ForEach(viewModel.pastTrips) { trip in
                    NavigationLink(value: trip.id) {
                        TripCardView(trip: trip, isPast: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("trip_row_\(trip.id)")
                }
            }
        }
    }

    private var findTripSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find a Trip")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("trips_find_title")
            Text("Enter your last name and confirmation number to find your trip.")
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.textSecondary)

            VStack(alignment: .leading, spacing: 12) {
                labeledField(
                    label: "First Name",
                    placeholder: "Optional",
                    text: $firstName,
                    id: "trips_find_first_name_field"
                )
                labeledField(
                    label: "Last Name",
                    placeholder: "Required",
                    text: $lastName,
                    id: "trips_find_last_name_field"
                )
                labeledField(
                    label: "Confirmation Number",
                    placeholder: "e.g., ABCDEF",
                    text: $confirmationCode,
                    id: "trips_find_confirmation_field"
                )
                .textInputAutocapitalization(.characters)

                Button {
                    findTrip()
                } label: {
                    Text("Find Trip")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFindButtonEnabled ? SkyTripTheme.red : Color.gray.opacity(0.35))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!isFindButtonEnabled)
                .accessibilityIdentifier("trips_find_submit_button")
            }
            .padding(16)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if let foundTrip {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text("Trip Found")
                            .font(.headline)
                            .foregroundStyle(SkyTripTheme.textPrimary)
                    }
                    Text("\(foundTrip.routeText) · \(foundTrip.primaryFlightNumber)")
                        .font(.subheadline)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text("Confirmation \(foundTrip.confirmationCode)")
                        .font(.caption)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Button {
                        path.append(foundTrip.id)
                    } label: {
                        Text("View Trip")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(SkyTripTheme.navy)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("trips_find_open_result_button")
                }
                .padding(14)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier("trips_find_result_card")
            }

            if let findTripError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(red: 157 / 255, green: 31 / 255, blue: 31 / 255))
                        .font(.system(size: 14))
                    Text(findTripError)
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 157 / 255, green: 31 / 255, blue: 31 / 255))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 255 / 255, green: 232 / 255, blue: 232 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityIdentifier("trips_find_error_state")
            }
        }
    }

    private var isFindButtonEnabled: Bool {
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !confirmationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func findTrip() {
        let matched = viewModel.findTrip(
            firstName: firstName,
            lastName: lastName,
            confirmationCode: confirmationCode
        )
        foundTrip = matched

        if matched == nil {
            findTripError = "Trip not found. Check the name and confirmation code."
        } else {
            findTripError = nil
        }
    }

    private func clearFindTripState() {
        foundTrip = nil
        findTripError = nil
    }

    private func labeledField(label: String, placeholder: String = "", text: Binding<String>, id: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(0.3)
            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .padding(12)
                .background(SkyTripTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityIdentifier(id)
        }
    }

    private func sectionTitle(_ title: String, id: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(SkyTripTheme.textSecondary)
            .tracking(1)
            .accessibilityIdentifier(id)
    }
}

private struct TripCardView: View {
    let trip: Trip
    var isPast: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Text(trip.outboundSegments.first?.origin.code ?? "---")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text(trip.outboundSegments.last?.destination.code ?? "---")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("trip_card_route_\(trip.id)")
                Spacer()
                Text(trip.operationalStatus.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 9)
                    .background(StatusBadgeStyle.color(for: trip.operationalStatus))
                    .foregroundStyle(StatusBadgeStyle.textColor(for: trip.operationalStatus))
                    .clipShape(Capsule())
                    .accessibilityIdentifier("trip_status_chip_\(trip.id)")
            }

            HStack(spacing: 16) {
                tripMeta(label: "Flight", value: trip.primaryFlightNumber)
                tripMeta(label: "Date", value: AppFormatters.date(trip.departureTime))
                tripMeta(label: "Seat", value: trip.seatAssignment ?? "—")
                tripMeta(label: "Cost", value: AppFormatters.currency(trip.totalPrice, code: trip.currency))
            }
            .accessibilityIdentifier("trip_card_flight_\(trip.id)")

            HStack {
                Text(trip.confirmationCode)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("trip_card_confirmation_\(trip.id)")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(isPast ? 0.7 : 1)
    }

    private func tripMeta(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textPrimary)
        }
    }
}

private struct TripDetailView: View {
    @ObservedObject var viewModel: TripsViewModel

    let tripID: String

    @State private var showCheckInFlow = false
    @State private var showStatus = false
    @State private var showSeatSelection = false
    @State private var showCancelConfirmation = false

    var trip: Trip? {
        viewModel.trip(for: tripID)
    }

    var body: some View {
        ScrollView {
            if let trip {
                VStack(alignment: .leading, spacing: 14) {
                    routeHeader(trip)
                    statusSummary(trip)
                    segmentSection(trip)
                    actionSection(trip)
                }
                .padding()
            } else {
                Text("Trip not found")
                    .accessibilityIdentifier("trip_detail_missing_state")
            }
        }
        .navigationTitle("Trip Detail")
        .background(SkyTripTheme.surface)
        .sheet(isPresented: $showCheckInFlow) {
            CheckInFlowView(store: viewModel.store, preselectedTripID: tripID)
        }
        .sheet(isPresented: $showStatus) {
            if let trip {
                FlightStatusDetailView(trip: trip)
            }
        }
        .sheet(isPresented: $showSeatSelection) {
            SeatSelectionView(store: viewModel.store, tripID: tripID)
        }
        .alert("Cancel this trip?", isPresented: $showCancelConfirmation) {
            Button("Keep", role: .cancel) {}
                .accessibilityIdentifier("trip_cancel_keep_button")
            Button("Cancel Trip", role: .destructive) {
                viewModel.cancelTrip(tripID: tripID)
            }
            .accessibilityIdentifier("trip_cancel_confirm_button")
        } message: {
            Text("This action updates local simulated trip state only.")
        }
    }

    private func routeHeader(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(trip.outboundSegments.first?.origin.code ?? "---")
                    .font(.system(size: 24, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text(trip.outboundSegments.last?.destination.code ?? "---")
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundStyle(SkyTripTheme.textPrimary)
            .accessibilityIdentifier("trip_detail_route")

            Text("Confirmation: \(trip.confirmationCode)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .accessibilityIdentifier("trip_detail_confirmation_code")
        }
    }

    private func statusSummary(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("STATUS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                Spacer()
                Text(trip.operationalStatus.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 9)
                    .background(StatusBadgeStyle.color(for: trip.operationalStatus))
                    .foregroundStyle(StatusBadgeStyle.textColor(for: trip.operationalStatus))
                    .clipShape(Capsule())
            }

            HStack(spacing: 16) {
                detailRow("Seat", trip.seatAssignment ?? "Not selected", id: "trip_detail_seat_assignment")
                detailRow("Group", trip.boardingGroup, id: "trip_detail_boarding_group")
                detailRow("Bags", trip.baggageStatus, id: "trip_detail_baggage_status")
                detailRow("Cost", AppFormatters.currency(trip.totalPrice, code: trip.currency), id: "trip_detail_total_price")
            }
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func detailRow(_ label: String, _ value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier(id)
        }
    }

    private func segmentSection(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FLIGHT SEGMENTS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("trip_detail_segments_title")

            ForEach(trip.outboundSegments) { segment in
                segmentRow(segment: segment, prefix: "trip_detail_outbound_segment")
            }

            ForEach(trip.returnSegments) { segment in
                segmentRow(segment: segment, prefix: "trip_detail_return_segment")
            }
        }
        .padding(14)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func actionSection(_ trip: Trip) -> some View {
        VStack(spacing: 10) {
            if trip.checkedIn {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.green)
                    Text("Checked In")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 232 / 255, green: 246 / 255, blue: 236 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityIdentifier("trip_checked_in_badge")

                Button {
                    viewModel.store.showWalletSection(.wallet)
                } label: {
                    Text("View Boarding Pass")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SkyTripTheme.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("trip_view_boarding_pass_button")
            } else if trip.checkInEligible {
                Button {
                    showCheckInFlow = true
                } label: {
                    Text("Check In")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SkyTripTheme.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("trip_checkin_entry_button")
            }

            Button {
                showSeatSelection = true
            } label: {
                Text("Change Seat")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SkyTripTheme.navy, lineWidth: 1.5)
                    )
                    .foregroundStyle(SkyTripTheme.navy)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("trip_seat_selection_button")

            Button {
                showStatus = true
            } label: {
                Text("Flight Status")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SkyTripTheme.navy, lineWidth: 1.5)
                    )
                    .foregroundStyle(SkyTripTheme.navy)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("trip_flight_status_entry_button")

            Button {
                showCancelConfirmation = true
            } label: {
                Text("Cancel Trip")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .accessibilityIdentifier("trip_cancel_button")
        }
    }

    private func segmentRow(segment: FlightSegment, prefix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(segment.descriptor)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                Text("·")
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text("\(segment.origin.code) → \(segment.destination.code)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textPrimary)
            }
            .accessibilityIdentifier("\(prefix)_flight_\(segment.id)")

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("DEPART")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .tracking(0.5)
                    Text(AppFormatters.full(segment.departureTime))
                        .font(.system(size: 12))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("ARRIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .tracking(0.5)
                    Text(AppFormatters.full(segment.arrivalTime))
                        .font(.system(size: 12))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                }
            }
            .accessibilityIdentifier("\(prefix)_times_\(segment.id)")

            Text("Terminal \(segment.terminal), Gate \(segment.gate)")
                .font(.system(size: 12))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .accessibilityIdentifier("\(prefix)_gate_\(segment.id)")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityIdentifier("\(prefix)_row_\(segment.id)")
    }
}

private struct FlightStatusDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let trip: Trip

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(trip.outboundSegments.first?.origin.code ?? "---")
                        .font(.system(size: 24, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text(trip.outboundSegments.last?.destination.code ?? "---")
                        .font(.system(size: 24, weight: .bold))
                }
                .accessibilityIdentifier("flight_status_route_label")

                Text(trip.operationalStatus.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .background(StatusBadgeStyle.color(for: trip.operationalStatus))
                    .foregroundStyle(StatusBadgeStyle.textColor(for: trip.operationalStatus))
                    .clipShape(Capsule())
                    .accessibilityIdentifier("flight_status_value")

                ForEach(trip.outboundSegments) { segment in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(segment.origin.code) → \(segment.destination.code)")
                            .font(.system(size: 16, weight: .semibold))
                            .accessibilityIdentifier("flight_status_segment_route_\(segment.id)")
                        Text("Gate \(segment.gate) · Terminal \(segment.terminal)")
                            .font(.system(size: 13))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .accessibilityIdentifier("flight_status_segment_gate_\(segment.id)")
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityIdentifier("flight_status_segment_row_\(segment.id)")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Flight Status")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("flight_status_done_button")
                }
            }
        }
    }
}
