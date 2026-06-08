import SwiftUI

struct CheckInFlowView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: CheckInViewModel

    init(store: AppStore, preselectedTripID: String? = nil) {
        _viewModel = StateObject(wrappedValue: CheckInViewModel(store: store, preselectedTripID: preselectedTripID))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch viewModel.step {
                    case .selectTrip:
                        selectTripStep
                    case .reviewPassenger:
                        reviewPassengerStep
                    case .seatSelection:
                        seatSelectionStep
                    case .upgradeConfirmation:
                        upgradeConfirmationStep
                    case .complete:
                        completeStep
                    }
                }
                .padding()
            }
            .background(SkyTripTheme.surface)
            .navigationTitle("Check In")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityIdentifier("checkin_close_button")
                }
            }
        }
    }

    private var selectTripStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Trip")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("checkin_select_trip_title")

            if viewModel.hasNoEligibleTrips {
                Text("Check-in is not available at this time.")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("checkin_unavailable_state")
            } else {
                ForEach(viewModel.eligibleTrips) { trip in
                    Button {
                        viewModel.selectTrip(trip.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(trip.outboundSegments.first?.origin.code ?? "---")
                                        .font(.system(size: 16, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(SkyTripTheme.textSecondary)
                                    Text(trip.outboundSegments.last?.destination.code ?? "---")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundStyle(SkyTripTheme.textPrimary)
                                .accessibilityIdentifier("checkin_trip_route_\(trip.id)")
                                Text("\(trip.primaryFlightNumber) · \(AppFormatters.date(trip.departureTime))")
                                    .font(.system(size: 13))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                                    .accessibilityIdentifier("checkin_trip_date_\(trip.id)")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SkyTripTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("checkin_trip_row_\(trip.id)")
                }
            }
        }
    }

    private var reviewPassengerStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Review Passenger")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("checkin_review_title")

            if let trip = viewModel.selectedTrip {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SkyTripTheme.navy)
                        Text(trip.passenger.fullName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SkyTripTheme.textPrimary)
                    }
                    .accessibilityIdentifier("checkin_passenger_name")

                    Text("SkyMiles #\(trip.passenger.skyMilesNumber)")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .accessibilityIdentifier("checkin_passenger_skymiles")

                    Divider()

                    HStack(spacing: 6) {
                        Text(trip.outboundSegments.first?.origin.code ?? "---")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text(trip.outboundSegments.last?.destination.code ?? "---")
                            .font(.system(size: 16, weight: .bold))
                        Text("·")
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text(trip.primaryFlightNumber)
                            .font(.system(size: 14))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                    .accessibilityIdentifier("checkin_trip_summary")

                    if trip.passengerCount > 1 {
                        Text("\(trip.passengerCount) passengers")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(SkyTripTheme.navy)
                            .accessibilityIdentifier("checkin_passenger_count")
                    }

                    Text("Current seat\(trip.passengerCount > 1 ? "s" : ""): \(trip.selectedSeats.isEmpty ? "Not assigned" : trip.selectedSeats.joined(separator: ", "))")
                        .font(.system(size: 14))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .accessibilityIdentifier("checkin_current_seat")
                }
                .padding(14)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    viewModel.proceedToSeatSelection()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SkyTripTheme.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("checkin_confirm_button")
            }

            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 255 / 255, green: 232 / 255, blue: 232 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityIdentifier("checkin_error_state")
            }
        }
    }

    private var seatSelectionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Your Seat\(viewModel.selectedTrip?.passengerCount ?? 1 > 1 ? "s" : "")")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("checkin_seat_selection_title")

            if let trip = viewModel.selectedTrip {
                if trip.passengerCount > 1 {
                    Text("Select \(trip.passengerCount) seats for your party.")
                        .font(.system(size: 14))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .accessibilityIdentifier("checkin_multi_seat_hint")
                }

                AirplaneSeatMapCard(
                    trip: trip,
                    selectedSeats: Set(trip.selectedSeats),
                    selectionMessage: "Preferred and premium seats are marked directly on the cabin map.",
                    selectionMessageIdentifier: "checkin_seat_selection_message",
                    onSelect: { seat in
                        viewModel.selectSeat(seat)
                    }
                )

                if !trip.selectedSeats.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(trip.selectedSeats, id: \.self) { seat in
                            if let seatObj = trip.seatMap.seats.first(where: { $0.seatNumber == seat }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.green)
                                    Text("Seat \(seat)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(SkyTripTheme.textPrimary)
                                    if Trip.seatUpcharge(for: seatObj.tag) > 0 {
                                        Text("+$\(Int(Trip.seatUpcharge(for: seatObj.tag)))")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(SkyTripTheme.red)
                                    }
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("checkin_selected_seat_label")
                }

                if let seatHint = viewModel.seatHint {
                    Text(seatHint)
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .accessibilityIdentifier("checkin_seat_hint")
                }

                Button {
                    viewModel.proceedToCompleteOrConfirm()
                } label: {
                    Text(viewModel.currentUpcharge > 0 ? "Review Upgrade & Check In" : "Complete Check-In")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.canCompleteCheckIn ? SkyTripTheme.red : SkyTripTheme.red.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canCompleteCheckIn)
                .accessibilityIdentifier("checkin_complete_button")
            } else {
                Text("Check-in is not available at this time.")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("checkin_unavailable_state")
            }

            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 255 / 255, green: 232 / 255, blue: 232 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityIdentifier("checkin_error_state")
            }
        }
    }

    private var upgradeConfirmationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Confirm Seat Upgrade")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("checkin_upgrade_title")

            if let trip = viewModel.selectedTrip {
                // Upgrade details
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(trip.outboundSegments.first?.origin.code ?? "---")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text(trip.outboundSegments.last?.destination.code ?? "---")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .accessibilityIdentifier("checkin_upgrade_route")

                    Text("Flight \(trip.primaryFlightNumber) · \(AppFormatters.date(trip.departureTime))")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)

                    Divider()

                    ForEach(trip.selectedSeats, id: \.self) { seat in
                        if let seatObj = trip.seatMap.seats.first(where: { $0.seatNumber == seat }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.green)
                                    .font(.system(size: 14))
                                Text("Seat \(seat)")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("(\(seatObj.tag.rawValue.capitalized))")
                                    .font(.system(size: 13))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                                Spacer()
                                if Trip.seatUpcharge(for: seatObj.tag) > 0 {
                                    Text("+$\(Int(Trip.seatUpcharge(for: seatObj.tag)))")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(SkyTripTheme.red)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Payment method picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Payment Method")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                        .accessibilityIdentifier("checkin_upgrade_payment_title")

                    ForEach(viewModel.store.paymentAccounts) { account in
                        Button {
                            viewModel.store.selectedPaymentAccountID = account.id
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: viewModel.store.selectedPaymentAccountID == account.id ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(viewModel.store.selectedPaymentAccountID == account.id ? SkyTripTheme.navy : SkyTripTheme.textSecondary)
                                    .font(.system(size: 20))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(SkyTripTheme.textPrimary)
                                    Text(account.displayName)
                                        .font(.system(size: 12))
                                        .foregroundStyle(SkyTripTheme.textSecondary)
                                }

                                Spacer()

                                Text(AppFormatters.currency(account.availableBalance, code: account.currency))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                            }
                            .padding(12)
                            .background(viewModel.store.selectedPaymentAccountID == account.id ? SkyTripTheme.surface : SkyTripTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(viewModel.store.selectedPaymentAccountID == account.id ? SkyTripTheme.navy : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("checkin_upgrade_payment_account_\(account.type.rawValue)")
                    }
                }

                // Price and bank/email info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Upgrade fee")
                            .font(.subheadline)
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Spacer()
                        Text(AppFormatters.currency(viewModel.upgradeAmount, code: trip.currency))
                            .font(.subheadline)
                    }

                    Divider()

                    HStack {
                        Text("Total")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Text(AppFormatters.currency(viewModel.upgradeAmount, code: trip.currency))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .accessibilityIdentifier("checkin_upgrade_total")

                    if let selected = viewModel.store.selectedPaymentAccount {
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Text("Charging \(selected.network) \(selected.maskedNumber)")
                                .font(.caption)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        .padding(.top, 4)
                        .accessibilityIdentifier("checkin_upgrade_selected_card")
                    }
                }
                .padding(14)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SkyTripTheme.navy)
                        Text("Transaction recorded in your linked bank account")
                            .font(.system(size: 13))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SkyTripTheme.navy)
                        Text("Confirmation email sent to \(viewModel.store.userProfile.email)")
                            .font(.system(size: 13))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                }
                .padding(14)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier("checkin_upgrade_bank_email_info")

                // Confirm upgrade + check-in
                Button {
                    guard let accountID = viewModel.store.selectedPaymentAccountID else { return }
                    viewModel.confirmUpgradeAndComplete(paymentAccountID: accountID)
                } label: {
                    Text("Pay & Complete Check-In")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SkyTripTheme.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("checkin_upgrade_confirm_button")

                Button {
                    viewModel.step = .seatSelection
                } label: {
                    Text("Go Back")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundStyle(SkyTripTheme.navy)
                .accessibilityIdentifier("checkin_upgrade_go_back_button")
            }

            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 255 / 255, green: 232 / 255, blue: 232 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityIdentifier("checkin_error_state")
            }
        }
    }

    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.green)

            Text("Check-In Complete!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier("checkin_complete_title")

            Text(viewModel.completionMessage ?? "Your boarding pass is now available in My Wallet.")
                .font(.system(size: 15))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("checkin_complete_message")

            Button {
                viewModel.store.showWalletSection(.wallet)
                dismiss()
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
            .accessibilityIdentifier("checkin_view_boarding_pass_button")

            Button("Done") {
                dismiss()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(SkyTripTheme.navy)
            .accessibilityIdentifier("checkin_done_button")
        }
        .frame(maxWidth: .infinity)
    }
}
