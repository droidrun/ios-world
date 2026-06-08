import SwiftUI

struct SeatSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var store: AppStore
    let tripID: String

    @State private var message: String?
    @State private var showUpgradeConfirmation = false

    var trip: Trip? {
        store.trip(with: tripID)
    }

    private var currentUpcharge: Double {
        guard let trip else { return 0 }
        return trip.seatMap.seats
            .filter { $0.availability == .selected }
            .reduce(0.0) { $0 + Trip.seatUpcharge(for: $1.tag) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let trip {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Seat Selection")
                            .font(.title3.weight(.semibold))
                            .accessibilityIdentifier("seat_selection_title")

                        Text("\(trip.routeText) · \(trip.primaryFlightNumber)")
                            .font(.subheadline)
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .accessibilityIdentifier("seat_selection_trip_label")

                        Text("Current seat\(trip.passengerCount > 1 ? "s" : ""): \(trip.selectedSeats.isEmpty ? "Not assigned" : trip.selectedSeats.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .accessibilityIdentifier("seat_selection_current_seat")

                        AirplaneSeatMapCard(
                            trip: trip,
                            selectedSeats: Set(trip.selectedSeats),
                            selectionMessage: "Tap an available seat to update your assignment. Select \(trip.passengerCount) seat\(trip.passengerCount == 1 ? "" : "s").",
                            selectionMessageIdentifier: "seat_selection_instruction_label",
                            onSelect: { seat in
                                let result = store.selectSeat(tripID: tripID, seatNumber: seat)
                                switch result {
                                case .success:
                                    message = "Seat updated to \(seat)."
                                case .failure(let error):
                                    message = error.localizedDescription
                                }
                            }
                        )

                        if let message {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                                .accessibilityIdentifier("seat_selection_message")
                        }

                        Button {
                            if currentUpcharge > 0 {
                                showUpgradeConfirmation = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text(currentUpcharge > 0 ? "Review Upgrade" : "Done")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SkyTripTheme.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("seat_selection_done_button")
                    }
                    .padding()
                } else {
                    Text("Trip not found")
                        .accessibilityIdentifier("seat_selection_missing_trip_state")
                }
            }
            .background(SkyTripTheme.surface)
            .navigationTitle("Seat Map")
            .sheet(isPresented: $showUpgradeConfirmation) {
                if let trip {
                    SeatUpgradeConfirmationView(store: store, trip: trip, upchargeAmount: currentUpcharge, onComplete: {
                        dismiss()
                    })
                }
            }
        }
    }
}

struct SeatUpgradeConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var store: AppStore
    let trip: Trip
    let upchargeAmount: Double
    var onComplete: (() -> Void)?

    @State private var confirmed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if !confirmed {
                    paymentStep
                } else {
                    confirmationStep
                }
            }
            .background(SkyTripTheme.surface)
            .navigationTitle(confirmed ? "Upgrade Confirmed" : "Confirm Upgrade")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                        if confirmed { onComplete?() }
                    }
                    .accessibilityIdentifier("seat_upgrade_close_button")
                }
            }
        }
    }

    private var paymentStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Upgrade summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Seat Upgrade")
                    .font(.headline)
                    .accessibilityIdentifier("seat_upgrade_title")

                HStack(spacing: 6) {
                    Text(trip.outboundSegments.first?.origin.code ?? "")
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text(trip.outboundSegments.last?.destination.code ?? "")
                        .font(.system(size: 16, weight: .bold))
                }
                .accessibilityIdentifier("seat_upgrade_route")

                Text("Flight \(trip.primaryFlightNumber) · \(AppFormatters.date(trip.departureTime))")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("seat_upgrade_flight_info")

                Text("Confirmation: \(trip.confirmationCode)")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("seat_upgrade_confirmation_code")

                Divider()

                ForEach(trip.selectedSeats, id: \.self) { seat in
                    if let seatObj = trip.seatMap.seats.first(where: { $0.seatNumber == seat }) {
                        HStack {
                            Text("Seat \(seat)")
                                .font(.system(size: 14, weight: .semibold))
                            Text("(\(seatObj.tag.rawValue.capitalized))")
                                .font(.system(size: 13))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Spacer()
                            if Trip.seatUpcharge(for: seatObj.tag) > 0 {
                                Text("+\(AppFormatters.currency(Trip.seatUpcharge(for: seatObj.tag), code: trip.currency))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(SkyTripTheme.red)
                            } else {
                                Text("Included")
                                    .font(.system(size: 13))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                            }
                        }
                        .accessibilityIdentifier("seat_upgrade_seat_row_\(seat)")
                    }
                }
            }
            .padding(14)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Payment method picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Payment Method")
                    .font(.headline)
                    .accessibilityIdentifier("seat_upgrade_payment_method_title")

                ForEach(store.paymentAccounts) { account in
                    Button {
                        store.selectedPaymentAccountID = account.id
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: store.selectedPaymentAccountID == account.id ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(store.selectedPaymentAccountID == account.id ? SkyTripTheme.navy : SkyTripTheme.textSecondary)
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
                        .background(store.selectedPaymentAccountID == account.id ? SkyTripTheme.surface : SkyTripTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(store.selectedPaymentAccountID == account.id ? SkyTripTheme.navy : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("seat_upgrade_payment_account_\(account.type.rawValue)")
                }
            }

            // Price breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Price Breakdown")
                    .font(.headline)
                    .accessibilityIdentifier("seat_upgrade_price_breakdown_title")

                HStack {
                    Text("Seat upgrade fee")
                        .font(.subheadline)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Spacer()
                    Text(AppFormatters.currency(upchargeAmount, code: trip.currency))
                        .font(.subheadline)
                }
                .accessibilityIdentifier("seat_upgrade_fee_row")

                Divider()

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(AppFormatters.currency(upchargeAmount, code: trip.currency))
                        .font(.headline)
                }
                .accessibilityIdentifier("seat_upgrade_total")

                if let selected = store.selectedPaymentAccount {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text("Charging \(selected.network) \(selected.maskedNumber)")
                            .font(.caption)
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                    .padding(.top, 4)
                    .accessibilityIdentifier("seat_upgrade_selected_card_display")
                }
            }
            .padding(14)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Bank & email info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(SkyTripTheme.navy)
                    Text("Transaction will be recorded in your linked bank account")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(SkyTripTheme.navy)
                    Text("Confirmation email will be sent to \(store.userProfile.email)")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
            }
            .padding(14)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("seat_upgrade_bank_email_info")

            // Confirm button
            Button {
                guard let accountID = store.selectedPaymentAccountID else { return }
                store.confirmSeatUpgrade(tripID: trip.id, paymentAccountID: accountID)
                withAnimation { confirmed = true }
            } label: {
                Text("Confirm & Pay \(AppFormatters.currency(upchargeAmount, code: trip.currency))")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SkyTripTheme.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("seat_upgrade_confirm_button")

            // Cancel
            Button {
                dismiss()
            } label: {
                Text("Go Back")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(SkyTripTheme.navy)
            .accessibilityIdentifier("seat_upgrade_go_back_button")
        }
        .padding()
    }

    private var confirmationStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.green)

            Text("Upgrade Confirmed!")
                .font(.title2.weight(.bold))
                .accessibilityIdentifier("seat_upgrade_confirmed_title")

            VStack(spacing: 8) {
                Text("Seat\(trip.selectedSeats.count > 1 ? "s" : ""): \(trip.selectedSeats.joined(separator: ", "))")
                    .font(.headline)
                    .accessibilityIdentifier("seat_upgrade_confirmed_seat")

                Text("Confirmation: \(trip.confirmationCode)")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("seat_upgrade_confirmed_code")
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Upgrade fee")
                        .font(.subheadline)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Spacer()
                    Text(AppFormatters.currency(upchargeAmount, code: trip.currency))
                        .font(.subheadline)
                }

                Divider()

                HStack {
                    Text("Total charged")
                        .font(.headline)
                    Spacer()
                    Text(AppFormatters.currency(upchargeAmount, code: trip.currency))
                        .font(.headline)
                }
                .accessibilityIdentifier("seat_upgrade_confirmed_total")

                if let account = store.selectedPaymentAccount {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text("\(account.network) \(account.maskedNumber)")
                            .font(.caption)
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                    .padding(.top, 2)
                    .accessibilityIdentifier("seat_upgrade_confirmed_payment_method")
                }
            }
            .padding(14)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.green)
                    Text("Payment recorded in your bank account")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.green)
                    Text("Confirmation email sent to \(store.userProfile.email)")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("seat_upgrade_confirmed_bank_email_status")

            Button {
                dismiss()
                onComplete?()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SkyTripTheme.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("seat_upgrade_confirmed_done_button")
        }
        .padding(24)
    }
}

struct AirplaneSeatMapCard: View {
    let trip: Trip
    let selectedSeats: Set<String>
    let selectionMessage: String?
    let selectionMessageIdentifier: String?
    let onSelect: (String) -> Void

    private func leftColumns(for row: Int) -> [String] {
        let rowSeats = Set(trip.seatMap.seats.filter { $0.row == row }.map(\.column))
        if rowSeats.contains("B") { return ["A", "B", "C"] }
        return ["A", "C"]
    }

    private func rightColumns(for row: Int) -> [String] {
        let rowSeats = Set(trip.seatMap.seats.filter { $0.row == row }.map(\.column))
        if rowSeats.contains("E") { return ["D", "E", "F"] }
        return ["D", "F"]
    }

    private var layoutDescription: String {
        let hasFront = !frontCabinRows.isEmpty
        let hasMain = !mainCabinRows.isEmpty
        if hasFront && hasMain {
            return "Front cabin 2-2, main cabin 3-3"
        } else if hasFront {
            return "2-2 layout"
        } else {
            return "3-3 layout"
        }
    }

    private var frontCabinRows: [Int] {
        trip.seatMap.rows.filter { row in
            !trip.seatMap.seats.filter({ $0.row == row }).contains { $0.column == "B" }
        }
    }

    private var mainCabinRows: [Int] {
        trip.seatMap.rows.filter { row in
            trip.seatMap.seats.filter({ $0.row == row }).contains { $0.column == "B" }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.seatMap.aircraftType)
                        .font(.headline)
                        .foregroundStyle(SkyTripTheme.textPrimary)
                        .accessibilityIdentifier("seat_map_aircraft_label")
                    Text(layoutDescription)
                        .font(.caption)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .accessibilityIdentifier("seat_map_layout_label")
                }
                Spacer()
                if !selectedSeats.isEmpty {
                    Text("\(selectedSeats.count)/\(trip.passengerCount) seats")
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(red: 255 / 255, green: 233 / 255, blue: 237 / 255))
                        .foregroundStyle(SkyTripTheme.red)
                        .clipShape(Capsule())
                        .accessibilityIdentifier("seat_map_selected_chip")
                }
            }

            if let selectionMessage,
               let selectionMessageIdentifier {
                Text(selectionMessage)
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier(selectionMessageIdentifier)
            }

            if !trip.seatMap.seats.contains(where: { $0.availability == .available || $0.availability == .selected }) {
                Text("No Seats Available")
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("seat_map_no_seat_available_state")
            } else {
                VStack(spacing: 10) {
                    AirplaneNoseView()
                        .frame(height: 34)
                        .accessibilityIdentifier("seat_map_front_indicator")

                    if !frontCabinRows.isEmpty {
                        cabinSectionLabel("Front Cabin", layout: "2-2", identifier: "seat_map_front_cabin_label")
                        seatColumnHeader(left: ["A", "C"], right: ["D", "F"])

                        ForEach(frontCabinRows, id: \.self) { row in
                            seatRow(row)
                        }
                    }

                    if !mainCabinRows.isEmpty {
                        cabinSectionLabel("Main Cabin", layout: "3-3", identifier: "seat_map_main_cabin_label")
                            .padding(.top, frontCabinRows.isEmpty ? 0 : 8)
                        seatColumnHeader(left: ["A", "B", "C"], right: ["D", "E", "F"])

                        ForEach(mainCabinRows, id: \.self) { row in
                            seatRow(row)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(red: 223 / 255, green: 229 / 255, blue: 238 / 255), lineWidth: 1)
                )

                seatLegend
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func cabinSectionLabel(_ title: String, layout: String, identifier: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
            Text(layout)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .accessibilityIdentifier(identifier)
    }

    private func seatColumnHeader(left: [String], right: [String]) -> some View {
        HStack(spacing: 6) {
            Text("Row")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .frame(width: 24, alignment: .leading)
            HStack(spacing: 4) {
                ForEach(left, id: \.self) { column in
                    Text(column)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .frame(width: 32)
                }
            }
            Text("Aisle")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .frame(width: 28)
            HStack(spacing: 4) {
                ForEach(right, id: \.self) { column in
                    Text(column)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .frame(width: 32)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func seatRow(_ row: Int) -> some View {
        let left = leftColumns(for: row)
        let right = rightColumns(for: row)
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                rowLabel(row)

                HStack(spacing: 4) {
                    ForEach(left, id: \.self) { column in
                        seatButton(row: row, column: column)
                    }
                }

                aisleLabel(for: row)

                HStack(spacing: 4) {
                    ForEach(right, id: \.self) { column in
                        seatButton(row: row, column: column)
                    }
                }
            }

            if rowHasExitRowMarker(row) {
                Text("Exit row")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(red: 45 / 255, green: 119 / 255, blue: 78 / 255))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("seat_map_exit_row_label_\(row)")
            }
        }
    }

    private var seatLegend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Legend")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .accessibilityIdentifier("seat_map_legend_title")

            HStack(spacing: 12) {
                legendItem(fill: Color.white, stroke: SkyTripTheme.navy, label: "Available")
                legendItem(fill: SkyTripTheme.red, stroke: SkyTripTheme.red, label: "Selected")
                legendItem(fill: Color(red: 233 / 255, green: 240 / 255, blue: 255 / 255), stroke: SkyTripTheme.navyLight, label: "Preferred")
            }

            HStack(spacing: 12) {
                legendItem(fill: Color(red: 14 / 255, green: 33 / 255, blue: 76 / 255), stroke: Color(red: 14 / 255, green: 33 / 255, blue: 76 / 255), label: "Premium")
                legendItem(fill: Color(red: 231 / 255, green: 233 / 255, blue: 238 / 255), stroke: Color.clear, label: "Occupied")
                legendItem(fill: Color(red: 244 / 255, green: 245 / 255, blue: 247 / 255), stroke: Color(red: 187 / 255, green: 191 / 255, blue: 201 / 255), label: "Blocked")
            }
        }
        .accessibilityIdentifier("seat_map_legend")
    }

    private func legendItem(fill: Color, stroke: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(fill)
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(stroke, lineWidth: strokeLineWidth(for: label))
                )
            Text(label)
                .font(.caption2)
                .foregroundStyle(SkyTripTheme.textSecondary)
        }
    }

    private func strokeLineWidth(for label: String) -> CGFloat {
        label == "Occupied" ? 0 : 1
    }

    private func rowLabel(_ row: Int) -> some View {
        Text("\(row)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(SkyTripTheme.textSecondary)
            .frame(width: 24, alignment: .leading)
            .accessibilityIdentifier("seat_map_row_label_\(row)")
    }

    private func aisleLabel(for row: Int) -> some View {
        VStack(spacing: 3) {
            Rectangle()
                .fill(Color(red: 226 / 255, green: 230 / 255, blue: 237 / 255))
                .frame(width: 2, height: 14)
            if rowHasExitRowMarker(row) {
                Text("EXIT")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color(red: 45 / 255, green: 119 / 255, blue: 78 / 255))
            } else {
                Text("")
                    .font(.system(size: 7, weight: .bold))
            }
            Rectangle()
                .fill(Color(red: 226 / 255, green: 230 / 255, blue: 237 / 255))
                .frame(width: 2, height: 14)
        }
        .frame(width: 28)
    }

    @ViewBuilder
    private func seatButton(row: Int, column: String) -> some View {
        if let seat = seat(for: row, column: column) {
            Button {
                if isSeatSelectable(seat) {
                    onSelect(seat.seatNumber)
                }
            } label: {
                SeatGlyphView(
                    seat: seat,
                    isSelected: selectedSeats.contains(seat.seatNumber),
                    upcharge: Trip.seatUpcharge(for: seat.tag)
                )
            }
            .buttonStyle(.plain)
            .disabled(!isSeatSelectable(seat))
            .accessibilityIdentifier("seat_map_seat_\(seat.seatNumber)")
        } else {
            Color.clear
                .frame(width: 32, height: 40)
        }
    }

    private func seat(for row: Int, column: String) -> Seat? {
        trip.seatMap.seats.first { $0.row == row && $0.column == column }
    }

    private func rowHasExitRowMarker(_ row: Int) -> Bool {
        trip.seatMap.seats.contains { $0.row == row && $0.tag == .exitRow }
    }

    private func isSeatSelectable(_ seat: Seat) -> Bool {
        seat.availability == .available || seat.availability == .selected
    }
}

private struct SeatGlyphView: View {
    let seat: Seat
    let isSelected: Bool
    var upcharge: Double = 0

    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(fillColor)
                .frame(width: 32, height: 28)
                .overlay(alignment: .top) {
                    if seat.tag == .preferred || seat.tag == .premium {
                        Capsule()
                            .fill(tagColor)
                            .frame(width: 18, height: 3)
                            .padding(.top, 3)
                    }
                }
                .overlay {
                    content
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
            if upcharge > 0 && seat.availability == .available {
                Text("+$\(Int(upcharge))")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(priceColor)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch seat.availability {
        case .blocked:
            Image(systemName: "minus")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 140 / 255, green: 145 / 255, blue: 154 / 255))
        case .occupied:
            Image(systemName: "person.fill")
                .font(.caption)
                .foregroundStyle(Color(red: 110 / 255, green: 116 / 255, blue: 126 / 255))
        default:
            Text(seat.column)
                .font(.caption.weight(.bold))
                .foregroundStyle(textColor)
        }
    }

    private var priceColor: Color {
        switch seat.tag {
        case .premium: return Color(red: 14 / 255, green: 33 / 255, blue: 76 / 255)
        case .preferred: return SkyTripTheme.navyLight
        case .exitRow: return Color(red: 45 / 255, green: 119 / 255, blue: 78 / 255)
        case .standard: return SkyTripTheme.textSecondary
        }
    }

    private var fillColor: Color {
        if isSelected {
            return SkyTripTheme.red
        }

        switch seat.availability {
        case .available:
            switch seat.tag {
            case .premium:
                return Color(red: 14 / 255, green: 33 / 255, blue: 76 / 255)
            case .preferred:
                return Color(red: 233 / 255, green: 240 / 255, blue: 255 / 255)
            case .exitRow:
                return Color(red: 232 / 255, green: 246 / 255, blue: 236 / 255)
            case .standard:
                return .white
            }
        case .occupied:
            return Color(red: 231 / 255, green: 233 / 255, blue: 238 / 255)
        case .blocked:
            return Color(red: 244 / 255, green: 245 / 255, blue: 247 / 255)
        case .selected:
            return SkyTripTheme.red
        }
    }

    private var borderColor: Color {
        if isSelected {
            return SkyTripTheme.red
        }

        switch seat.availability {
        case .available:
            switch seat.tag {
            case .premium:
                return Color(red: 14 / 255, green: 33 / 255, blue: 76 / 255)
            case .preferred:
                return SkyTripTheme.navyLight
            case .exitRow:
                return Color(red: 45 / 255, green: 119 / 255, blue: 78 / 255)
            case .standard:
                return SkyTripTheme.navy
            }
        case .occupied:
            return .clear
        case .blocked:
            return Color(red: 187 / 255, green: 191 / 255, blue: 201 / 255)
        case .selected:
            return SkyTripTheme.red
        }
    }

    private var borderWidth: CGFloat {
        switch seat.availability {
        case .occupied:
            return 0
        default:
            return 1
        }
    }

    private var textColor: Color {
        if isSelected || seat.tag == .premium || seat.availability == .selected {
            return .white
        }
        return SkyTripTheme.textPrimary
    }

    private var tagColor: Color {
        switch seat.tag {
        case .premium:
            return Color.white.opacity(0.85)
        case .preferred:
            return SkyTripTheme.navyLight
        case .exitRow:
            return Color(red: 45 / 255, green: 119 / 255, blue: 78 / 255)
        case .standard:
            return Color.clear
        }
    }
}

private struct AirplaneNoseView: View {
    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 232 / 255, green: 236 / 255, blue: 244 / 255), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(red: 213 / 255, green: 219 / 255, blue: 231 / 255), lineWidth: 1)
                )

            Text("FRONT")
                .font(.caption2.weight(.bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
        }
    }
}
