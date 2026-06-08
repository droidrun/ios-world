import Foundation

@MainActor
final class TripsViewModel: StoreBackedViewModel {
    var upcomingTrips: [Trip] {
        store.upcomingTrips
    }

    var pastTrips: [Trip] {
        store.pastTrips
    }

    var allTrips: [Trip] {
        store.trips
    }

    func cancelTrip(tripID: String) {
        store.cancelTrip(tripID: tripID)
    }

    func selectSeat(tripID: String, seatNumber: String) -> Result<Void, AppStore.StoreError> {
        store.selectSeat(tripID: tripID, seatNumber: seatNumber)
    }

    func completeCheckIn(tripID: String, preferredSeat: String?) -> Result<BoardingPass, AppStore.StoreError> {
        store.completeCheckIn(tripID: tripID, preferredSeat: preferredSeat)
    }

    func trip(for id: String) -> Trip? {
        store.trip(with: id)
    }

    func boardingPass(for tripID: String) -> BoardingPass? {
        store.boardingPass(for: tripID)
    }

    func findTrip(firstName: String, lastName: String, confirmationCode: String) -> Trip? {
        let normalizedCode = confirmationCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalizedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedCode.isEmpty, !normalizedLast.isEmpty else {
            return nil
        }

        return allTrips.first { trip in
            let codeMatches = trip.confirmationCode.uppercased() == normalizedCode
            let lastMatches = trip.passenger.lastName.lowercased() == normalizedLast
            let firstMatches = normalizedFirst.isEmpty || trip.passenger.firstName.lowercased() == normalizedFirst
            return codeMatches && lastMatches && firstMatches
        }
    }
}
