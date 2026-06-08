import Foundation

@MainActor
final class CheckInViewModel: StoreBackedViewModel {
    enum Step {
        case selectTrip
        case reviewPassenger
        case seatSelection
        case upgradeConfirmation
        case complete
    }

    @Published var step: Step = .selectTrip
    @Published var selectedTripID: String?
    @Published private(set) var completionMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var upgradeAmount: Double = 0

    init(store: AppStore, preselectedTripID: String? = nil) {
        super.init(store: store)

        if let preselectedTripID,
           store.trip(with: preselectedTripID) != nil {
            self.selectedTripID = preselectedTripID
            self.step = .reviewPassenger
        }
    }

    var eligibleTrips: [Trip] {
        store.eligibleCheckInTrips
    }

    var selectedTrip: Trip? {
        guard let selectedTripID else {
            return nil
        }
        return store.trip(with: selectedTripID)
    }

    var hasNoEligibleTrips: Bool {
        eligibleTrips.isEmpty
    }

    func selectTrip(_ tripID: String) {
        selectedTripID = tripID
        errorMessage = nil
        step = .reviewPassenger
    }

    func proceedToSeatSelection() {
        errorMessage = nil
        step = .seatSelection
    }

    var canCompleteCheckIn: Bool {
        guard let trip = selectedTrip else { return false }
        return trip.selectedSeatCount >= trip.passengerCount
    }

    var currentUpcharge: Double {
        guard let trip = selectedTrip else { return 0 }
        return trip.seatMap.seats
            .filter { $0.availability == .selected }
            .reduce(0.0) { $0 + Trip.seatUpcharge(for: $1.tag) }
    }

    @Published private(set) var seatHint: String?

    func selectSeat(_ seatNumber: String) {
        guard let selectedTripID else { return }
        seatHint = nil

        // Prevent deselecting the only selected seat during check-in
        if let trip = selectedTrip,
           trip.selectedSeats.contains(seatNumber),
           trip.selectedSeatCount <= trip.passengerCount {
            seatHint = "Tap a different seat to change your selection."
            return
        }

        let result = store.selectSeat(tripID: selectedTripID, seatNumber: seatNumber)
        if case .failure(let error) = result {
            errorMessage = error.localizedDescription
        } else {
            errorMessage = nil
        }
    }

    func proceedToCompleteOrConfirm() {
        let upcharge = currentUpcharge
        if upcharge > 0 {
            upgradeAmount = upcharge
            step = .upgradeConfirmation
        } else {
            completeCheckIn()
        }
    }

    func confirmUpgradeAndComplete(paymentAccountID: UUID) {
        guard let selectedTripID else {
            errorMessage = "check-in unavailable"
            return
        }
        store.confirmSeatUpgrade(tripID: selectedTripID, paymentAccountID: paymentAccountID)
        completeCheckIn()
    }

    func completeCheckIn() {
        guard let selectedTripID else {
            errorMessage = "check-in unavailable"
            return
        }

        let result = store.completeCheckIn(tripID: selectedTripID, preferredSeat: nil)
        switch result {
        case .success(let boardingPass):
            completionMessage = "Check-in complete for \(boardingPass.flightNumber). Boarding pass available in Wallet."
            errorMessage = nil
            step = .complete
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
