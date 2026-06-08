import Combine
import Foundation

final class ActivityViewModel: ObservableObject {
    @Published private(set) var activeTrips: [Trip] = []
    @Published private(set) var upcomingTrips: [Trip] = []
    @Published private(set) var pastTrips: [Trip] = []
    @Published private(set) var message: String?

    let store: CityRideStore
    private var cancellables = Set<AnyCancellable>()

    init(store: CityRideStore) {
        self.store = store
        bind()
    }

    func receipt(for tripID: String) -> RideReceipt? {
        store.receipt(for: tripID)
    }

    func cancelTrip(_ tripID: String) {
        store.cancelTrip(tripID: tripID)
    }

    func completeTrip(_ tripID: String) {
        store.completeTrip(tripID: tripID)
    }

    func startReservedTrip(_ tripID: String) {
        store.startReservedTrip(tripID)
    }

    func advanceTrip(_ tripID: String) {
        store.advanceTrip(tripID: tripID)
    }

    func rebookTrip(_ trip: Trip) {
        let fallbackLocation = store.state.requestDraft.pickup ?? store.state.places.first ?? SeedData.places[0]
        let pickup = store.state.places.first(where: { $0.displayName.caseInsensitiveCompare(trip.pickupName) == .orderedSame })
            ?? LocationPlace(
                id: "rebook_pickup_\(trip.id)",
                displayName: trip.pickupName,
                address: trip.pickupName,
                latitudePlaceholder: fallbackLocation.latitudePlaceholder,
                longitudePlaceholder: fallbackLocation.longitudePlaceholder
            )
        let destination = store.state.places.first(where: { $0.displayName.caseInsensitiveCompare(trip.destinationName) == .orderedSame })
            ?? LocationPlace(
                id: "rebook_destination_\(trip.id)",
                displayName: trip.destinationName,
                address: trip.destinationName,
                latitudePlaceholder: fallbackLocation.latitudePlaceholder + 0.012,
                longitudePlaceholder: fallbackLocation.longitudePlaceholder + 0.009
            )

        store.setPickup(pickup)
        store.setDestination(destination)
        store.setRideTiming(.now)
        store.selectRideType(id: trip.rideTypeId)
        store.refreshRideOptions()
        store.postStatusMessage("Rebook draft prepared. Open Home to confirm.")
    }

    func applyPastFilter(label: String) {
        store.postStatusMessage("Past rides filtered by \(label.lowercased()).")
    }

    func rateTrip(_ tripID: String, tip: Double = 0) {
        if tip > 0 {
            store.addTipToReceipt(tripID: tripID, tip: tip)
            store.postStatusMessage("Thanks for rating your trip and adding a $\(Int(tip)) tip!")
        } else {
            store.postStatusMessage("Thanks for rating your trip.")
        }
    }

    func openSafetyToolkit() {}

    func openHelpCenter() {}

    private func bind() {
        store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.activeTrips = self?.store.activeTrips ?? []
                self?.upcomingTrips = self?.store.upcomingTrips ?? []
                self?.pastTrips = self?.store.pastTrips ?? []
            }
            .store(in: &cancellables)

        store.$inlineStatusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$message)
    }
}
