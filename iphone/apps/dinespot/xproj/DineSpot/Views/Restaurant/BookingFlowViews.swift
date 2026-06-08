import SwiftUI

struct BookingRequest: Identifiable {
    let id = UUID()
    let restaurant: Restaurant
    let slot: ReservationSlot
}

struct BookingReviewView: View {
    @EnvironmentObject private var store: DiningStore
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant
    let slot: ReservationSlot
    let partySize: Int

    @State private var diningPreference = "No preference"
    @State private var notes = ""
    @State private var confirmedReservation: Reservation?

    private let preferences = [
        "No preference",
        "Window table",
        "Patio seating",
        "Quiet corner",
        "Bar seating"
    ]

    var body: some View {
        NavigationStack {
            if let reservation = confirmedReservation {
                BookingConfirmationView(reservation: reservation, restaurant: restaurant) {
                    dismiss()
                }
            } else {
                Form {
                    Section("Reservation Details") {
                        detailRow(label: "Restaurant", value: restaurant.name, id: "booking_review_restaurant")
                        detailRow(label: "Date", value: DateFormatters.weekdayDate.string(from: slot.date), id: "booking_review_date")
                        detailRow(label: "Time", value: DateFormatters.shortTime.string(from: slot.date), id: "booking_review_time")
                        detailRow(label: "Party", value: AppFormat.partySizeLabel(partySize), id: "booking_review_party")
                        detailRow(label: "Policy", value: restaurant.policy.cancellationPolicy, id: "booking_review_policy")
                    }

                    Section("Dining Preference") {
                        Picker("Preference", selection: $diningPreference) {
                            ForEach(preferences, id: \.self) { pref in
                                Text(pref).tag(pref)
                            }
                        }
                        .accessibilityIdentifier("booking_preference_picker")

                        TextField("Notes (optional)", text: $notes)
                            .accessibilityIdentifier("booking_notes_field")
                    }

                    Section {
                        Button("Confirm Reservation") {
                            let reservation = store.createReservation(
                                restaurant: restaurant,
                                slot: slot,
                                partySize: partySize,
                                diningPreference: diningPreference,
                                notes: notes
                            )
                            confirmedReservation = reservation
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DiningTheme.accentRed)
                        .accessibilityIdentifier("reservation_confirm_button")
                    }
                }
                .navigationTitle("Review Booking")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .accessibilityIdentifier("reservation_modal_close_button")
                    }
                }
                .accessibilityIdentifier("booking_review_screen")
            }
        }
    }

    private func detailRow(label: String, value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(DiningTheme.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DiningTheme.textPrimary)
        }
        .accessibilityIdentifier(id)
    }
}

struct BookingConfirmationView: View {
    let reservation: Reservation
    let restaurant: Restaurant
    let done: () -> Void

    var body: some View {
        ZStack {
            DiningTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(Color.green)

                Text("Reservation Confirmed")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .accessibilityIdentifier("reservation_confirmation_title")

                Text(restaurant.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .accessibilityIdentifier("reservation_confirmation_restaurant")

                Text("\(DateFormatters.weekdayDate.string(from: reservation.date)) • \(DateFormatters.shortTime.string(from: reservation.date))")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
                    .accessibilityIdentifier("reservation_confirmation_datetime")

                Text("Code: \(reservation.reservationCode)")
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(DiningTheme.accentRed)
                    .accessibilityIdentifier("reservation_confirmation_code")

                Button("Done") {
                    done()
                }
                .buttonStyle(.borderedProminent)
                .tint(DiningTheme.accentRed)
                .accessibilityIdentifier("reservation_confirmation_done_button")
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(DiningTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(DiningTheme.border, lineWidth: 1)
            )
            .padding(16)
        }
        .accessibilityIdentifier("reservation_confirmation_screen")
    }
}

struct WaitlistRequestView: View {
    @EnvironmentObject private var store: DiningStore
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant
    let selectedDate: Date
    let partySize: Int
    let requestType: WaitlistRequestType

    @State private var preferredWindow = "6:00 PM - 7:30 PM"
    @State private var requestCompleted = false

    private let windows = [
        "5:00 PM - 6:30 PM",
        "6:00 PM - 7:30 PM",
        "7:30 PM - 9:00 PM",
        "9:00 PM - 10:30 PM"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Request Details") {
                    Text(restaurant.name)
                        .foregroundStyle(DiningTheme.textPrimary)
                        .accessibilityIdentifier("waitlist_restaurant_label")
                    Text(DateFormatters.weekdayDate.string(from: selectedDate))
                        .foregroundStyle(DiningTheme.textSecondary)
                        .accessibilityIdentifier("waitlist_date_label")
                    Text(AppFormat.partySizeLabel(partySize))
                        .foregroundStyle(DiningTheme.textSecondary)
                        .accessibilityIdentifier("waitlist_party_label")
                }

                Section("Preferred Time Window") {
                    Picker("Window", selection: $preferredWindow) {
                        ForEach(windows, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .accessibilityIdentifier("waitlist_window_picker")
                }

                Section {
                    Button(requestType == .waitlist ? "Join Waitlist" : "Notify Me") {
                        _ = store.createWaitlistEntry(
                            restaurantID: restaurant.id,
                            requestType: requestType,
                            date: selectedDate,
                            partySize: partySize,
                            preferredWindow: preferredWindow
                        )
                        requestCompleted = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DiningTheme.accentRed)
                    .accessibilityIdentifier(requestType == .waitlist ? "waitlist_confirm_button" : "notify_confirm_button")
                }
            }
            .navigationTitle(requestType == .waitlist ? "Join Waitlist" : "Notify Me")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityIdentifier("waitlist_modal_close_button")
                }
            }
        }
        .alert(requestType == .waitlist ? "Waitlist Joined" : "Notify Request Created", isPresented: $requestCompleted) {
            Button("Done") {
                dismiss()
            }
            .accessibilityIdentifier("waitlist_done_button")
        } message: {
            Text("We'll monitor availability around \(preferredWindow).")
        }
        .accessibilityIdentifier(requestType == .waitlist ? "waitlist_request_screen" : "notify_request_screen")
    }
}
