import SwiftUI

struct ReservationDetailView: View {
    @EnvironmentObject private var store: DiningStore
    let reservationID: String

    @State private var showModifySheet = false
    @State private var showCancelConfirmation = false
    @State private var statusMessage: String?

    private var reservation: Reservation? {
        store.reservations.first(where: { $0.id == reservationID })
    }

    private var restaurant: Restaurant? {
        guard let reservation else { return nil }
        return store.restaurant(for: reservation.restaurantID)
    }

    var body: some View {
        Group {
            if let reservation,
               let restaurant {
                ZStack {
                    DiningTheme.background.ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            summaryCard(reservation: reservation, restaurant: restaurant)
                            policyCard(reservation: reservation, restaurant: restaurant)
                            actionCard(reservation: reservation, restaurant: restaurant)
                        }
                        .padding(16)
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle("Reservation")
                .navigationBarTitleDisplayMode(.inline)
                .accessibilityIdentifier("reservation_detail_screen")
                .sheet(isPresented: $showModifySheet) {
                    ModifyReservationSheet(reservationID: reservation.id)
                        .environmentObject(store)
                }
                .confirmationDialog("Cancel this reservation?", isPresented: $showCancelConfirmation) {
                    Button("Confirm Cancellation", role: .destructive) {
                        if store.cancelReservation(reservationID: reservation.id) {
                            statusMessage = "Reservation canceled"
                        } else {
                            statusMessage = "Unable to cancel reservation"
                        }
                    }
                    .accessibilityIdentifier("reservation_cancel_confirm_button")

                    Button("Keep Reservation", role: .cancel) {}
                        .accessibilityIdentifier("reservation_cancel_keep_button")
                }
                .alert("Update", isPresented: Binding(
                    get: { statusMessage != nil },
                    set: { newValue in if !newValue { statusMessage = nil } }
                )) {
                    Button("OK", role: .cancel) {
                        statusMessage = nil
                    }
                    .accessibilityIdentifier("reservation_status_alert_ok")
                } message: {
                    Text(statusMessage ?? "")
                }
            } else {
                ContentUnavailableView("Reservation unavailable", systemImage: "calendar.badge.exclamationmark")
                    .accessibilityIdentifier("reservation_detail_missing_state")
            }
        }
    }

    private func summaryCard(reservation: Reservation, restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(restaurant.name)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)
                .accessibilityIdentifier("reservation_detail_restaurant")

            Text(reservation.reservationCode)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(DiningTheme.accentRed)
                .accessibilityIdentifier("reservation_detail_code")

            detailRow(icon: "calendar", title: DateFormatters.weekdayDate.string(from: reservation.date), id: "reservation_detail_datetime")
            detailRow(icon: "clock", title: DateFormatters.shortTime.string(from: reservation.date), id: "reservation_detail_time")
            detailRow(icon: "person", title: AppFormat.partySizeLabel(reservation.partySize), id: "reservation_detail_party")
            detailRow(icon: "location", title: restaurant.address, id: "reservation_detail_address")

            Text("Status: \(AppFormat.reservationStatusTitle(reservation.status))")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DiningTheme.textSecondary)
                .accessibilityIdentifier("reservation_detail_status")

            if !reservation.notes.isEmpty {
                Text(reservation.notes)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
                    .accessibilityIdentifier("reservation_detail_notes")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
    }

    private func policyCard(reservation: Reservation, restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dining policy")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)

            Text(reservation.policySummary)
                .foregroundStyle(DiningTheme.textSecondary)
                .accessibilityIdentifier("reservation_policy_summary")
            Text(restaurant.policy.lateArrivalPolicy)
                .foregroundStyle(DiningTheme.textSecondary)
                .accessibilityIdentifier("reservation_late_arrival_policy")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
    }

    private func actionCard(reservation: Reservation, restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)

            if store.canModifyReservation(reservation) {
                actionButton(title: "Modify Reservation", role: nil, identifier: "reservation_modify_button") {
                    showModifySheet = true
                }
            } else {
                Text("Reservation modification unavailable")
                    .foregroundStyle(DiningTheme.textSecondary)
                    .accessibilityIdentifier("reservation_modification_unavailable")
            }

            if reservation.status == .upcoming {
                if store.cancellationWindowClosed(reservation) {
                    Text("Cancellation window closed")
                        .foregroundStyle(DiningTheme.textSecondary)
                        .accessibilityIdentifier("cancellation_window_closed_label")
                } else {
                    actionButton(title: "Cancel Reservation", role: .destructive, identifier: "reservation_cancel_button") {
                        showCancelConfirmation = true
                    }
                }
            }

            actionButton(title: "Rebook", role: nil, identifier: "reservation_rebook_button") {
                if store.rebookReservation(reservation) != nil {
                    statusMessage = "Rebooked to next available slot"
                } else {
                    statusMessage = "No rebook slots available"
                }
            }

            NavigationLink {
                RestaurantDetailView(restaurantID: restaurant.id)
            } label: {
                buttonLabel(title: "View Restaurant")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reservation_view_restaurant_button")

            actionButton(title: "Add to Wallet / Calendar", role: nil, identifier: "reservation_wallet_button") {
                statusMessage = "Reservation added to calendar"
            }

            actionButton(title: "Directions", role: nil, identifier: "reservation_directions_button") {
                statusMessage = "Open Maps for directions to \(restaurant.address)"
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
    }

    private func actionButton(title: String, role: ButtonRole?, identifier: String, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            buttonLabel(title: title)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private func buttonLabel(title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(DiningTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(DiningTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func detailRow(icon: String, title: String, id: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(DiningTheme.textSecondary)
                .padding(.top, 3)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DiningTheme.textSecondary)
        }
        .accessibilityIdentifier(id)
    }
}

private struct ModifyReservationSheet: View {
    @EnvironmentObject private var store: DiningStore
    @Environment(\.dismiss) private var dismiss

    let reservationID: String

    @State private var editor: ReservationEditorViewModel?
    @State private var statusMessage: String?

    private var reservation: Reservation? {
        store.reservations.first(where: { $0.id == reservationID })
    }

    private var restaurant: Restaurant? {
        guard let reservation else { return nil }
        return store.restaurant(for: reservation.restaurantID)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let reservation,
                   let restaurant,
                   let editor {
                    Form {
                        Section("Update Details") {
                            DatePicker("Date", selection: binding(editor: editor, keyPath: \.selectedDate), in: Date()...SeedData.makeDate(daysFromNow: 30, hour: 23), displayedComponents: .date)
                                .accessibilityIdentifier("modify_reservation_date_picker")

                            DatePicker("Time", selection: binding(editor: editor, keyPath: \.selectedTime), displayedComponents: .hourAndMinute)
                                .accessibilityIdentifier("modify_reservation_time_picker")

                            Stepper(
                                "\(AppFormat.partySizeLabel(editor.partySize))",
                                value: binding(editor: editor, keyPath: \.partySize),
                                in: 1...10
                            )
                            .accessibilityIdentifier("modify_reservation_party_stepper")

                            TextField("Dining preference", text: binding(editor: editor, keyPath: \.diningPreference))
                                .accessibilityIdentifier("modify_reservation_preference_field")
                        }

                        let slots = editor.candidateSlots(store: store, restaurantID: restaurant.id)

                        Section("Available Slots") {
                            if slots.isEmpty {
                                Text("No availability for selected party size")
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("modify_no_slots_state")
                            } else {
                                ForEach(slots) { slot in
                                    Button {
                                        self.editor?.selectedSlotID = slot.id
                                    } label: {
                                        HStack {
                                            Text(DateFormatters.shortTime.string(from: slot.date))
                                            Spacer()
                                            if self.editor?.selectedSlotID == slot.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("modify_slot_\(slot.id)")
                                }
                            }
                        }

                        Section {
                            Button("Save Changes") {
                                guard let selectedSlot = editor.selectedSlot(from: slots) else {
                                    statusMessage = "Select an available slot"
                                    return
                                }

                                let didModify = store.modifyReservation(
                                    reservationID: reservation.id,
                                    newSlot: selectedSlot,
                                    newPartySize: editor.partySize,
                                    newDiningPreference: editor.diningPreference
                                )

                                if didModify {
                                    dismiss()
                                } else {
                                    statusMessage = "Unable to modify reservation"
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(DiningTheme.accentRed)
                            .accessibilityIdentifier("modify_reservation_save_button")
                        }
                    }
                } else {
                    ContentUnavailableView("Reservation unavailable", systemImage: "calendar.badge.exclamationmark")
                        .accessibilityIdentifier("modify_reservation_missing_state")
                }
            }
            .navigationTitle("Modify Reservation")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityIdentifier("modify_reservation_close_button")
                }
            }
            .onAppear {
                if editor == nil, let reservation {
                    editor = ReservationEditorViewModel(reservation: reservation)
                }
            }
            .alert("Update", isPresented: Binding(
                get: { statusMessage != nil },
                set: { newValue in if !newValue { statusMessage = nil } }
            )) {
                Button("OK", role: .cancel) { statusMessage = nil }
                    .accessibilityIdentifier("modify_reservation_alert_ok")
            } message: {
                Text(statusMessage ?? "")
            }
        }
    }

    private func binding<T>(editor: ReservationEditorViewModel, keyPath: ReferenceWritableKeyPath<ReservationEditorViewModel, T>) -> Binding<T> {
        Binding(
            get: { editor[keyPath: keyPath] },
            set: { newValue in
                editor[keyPath: keyPath] = newValue
            }
        )
    }
}
