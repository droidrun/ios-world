import Combine
import Foundation

final class RequestViewModel: ObservableObject {
    @Published private(set) var draft: RequestDraft = .empty
    @Published private(set) var rideOptions: [RideOption] = []
    @Published private(set) var paymentMethods: [PaymentMethod] = []
    @Published private(set) var selectedPaymentMethodID: String = ""
    @Published private(set) var fareSourceLabel: String = ""
    @Published private(set) var message: String?

    let store: CityRideStore
    private var cancellables = Set<AnyCancellable>()

    init(store: CityRideStore) {
        self.store = store
        bind()
    }

    var availablePlaces: [LocationPlace] {
        store.availablePlaces
    }

    var canConfirmRequest: Bool {
        guard let pickup = draft.pickup,
              let destination = draft.destination,
              pickup.id != destination.id else {
            return false
        }

        guard !rideOptions.isEmpty else {
            return false
        }

        guard let selectedRideID = draft.selectedRideTypeId ?? rideOptions.first?.id,
              rideOptions.contains(where: { $0.id == selectedRideID }) else {
            return false
        }

        return paymentMethods.contains(where: { $0.id == selectedPaymentMethodID && $0.isAvailable })
    }

    func setPickup(_ place: LocationPlace) {
        store.setPickup(place)
    }

    func setDestination(_ place: LocationPlace) {
        store.setDestination(place)
    }

    func setRideTiming(_ timing: RideTimingOption) {
        store.setRideTiming(timing)
    }

    func setReservedDate(_ date: Date) {
        store.setReservedDate(date)
    }

    func setSortOption(_ option: RideSortOption) {
        store.setSortOption(option)
    }

    func setFilterCategory(_ category: RideFilterCategory) {
        store.setFilterCategory(category)
    }

    func setMaxETA(_ minutes: Int) {
        store.setMaxETA(minutes: minutes)
    }

    func setLowerPriceOnly(_ enabled: Bool) {
        store.setLowerPriceOnly(enabled)
    }

    func setPromoCode(_ code: String) {
        store.setPromoCode(code)
    }

    func selectRideType(_ id: String) {
        store.selectRideType(id: id)
    }

    func setPaymentMethod(_ id: String) {
        store.setPaymentMethod(id: id)
    }

    func requestRide() -> Trip? {
        store.requestRide()
    }

    func refreshRideOptions() {
        store.refreshRideOptions()
    }

    private func bind() {
        store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.draft = state.requestDraft
                self?.paymentMethods = state.walletState.paymentMethods
                self?.selectedPaymentMethodID = state.selectedPaymentMethodId
                self?.fareSourceLabel = self?.store.fareSourceLabel ?? ""
            }
            .store(in: &cancellables)

        store.$currentRideOptions
            .receive(on: DispatchQueue.main)
            .assign(to: &$rideOptions)

        store.$inlineStatusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$message)
    }
}
