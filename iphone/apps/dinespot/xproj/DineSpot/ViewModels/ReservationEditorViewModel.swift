import Foundation

@MainActor
final class ReservationEditorViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var selectedTime: Date
    @Published var partySize: Int
    @Published var diningPreference: String
    @Published var selectedSlotID: String?

    init(reservation: Reservation) {
        selectedDate = reservation.date
        selectedTime = reservation.date
        partySize = reservation.partySize
        diningPreference = reservation.diningPreference
        selectedSlotID = nil
    }

    func candidateSlots(store: DiningStore, restaurantID: String) -> [ReservationSlot] {
        store.availableSlots(for: restaurantID, date: selectedDate, partySize: partySize)
    }

    func selectedSlot(from slots: [ReservationSlot], calendar: Calendar = .current) -> ReservationSlot? {
        if let selectedSlotID {
            return slots.first(where: { $0.id == selectedSlotID })
        }

        let targetHour = calendar.component(.hour, from: selectedTime)
        return slots.min(by: {
            abs(calendar.component(.hour, from: $0.date) - targetHour) < abs(calendar.component(.hour, from: $1.date) - targetHour)
        })
    }
}
