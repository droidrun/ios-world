import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    @Published private(set) var requestDraft: RequestDraft = .empty
    @Published private(set) var savedPlaces: [SavedPlace] = []
    @Published private(set) var suggestedDestinations: [LocationPlace] = []
    @Published private(set) var recentDestinations: [LocationPlace] = []
    @Published private(set) var commuteShortcuts: [LocationPlace] = []
    @Published private(set) var travelAlerts: [TravelAlert] = []
    @Published private(set) var previewRideOptions: [RideOption] = []
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

    func setPickup(_ place: LocationPlace) {
        store.setPickup(place)
    }

    func setDestination(_ place: LocationPlace) {
        store.setDestination(place)
    }

    func setDestination(from savedPlace: SavedPlace) {
        store.setDestination(from: savedPlace)
    }

    func addFavoritePlace(_ place: LocationPlace) {
        store.addSavedPlace(from: place)
    }

    func swapPickupAndDestination() {
        store.swapPickupAndDestination()
    }

    func openSuggestionsHub() {}

    func openPromotionDetails() {
        store.postStatusMessage("Promotions are applied automatically at checkout.")
    }

    func openSafetyToolkit() {}

    func openHelpCenter() {}

    func recenterMap() {
        store.refreshRideOptions()
        store.postStatusMessage("Map recentered on active route.")
    }

    private func bind() {
        store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.requestDraft = state.requestDraft
                self?.savedPlaces = state.savedPlaces
                self?.suggestedDestinations = state.suggestedDestinations
                self?.recentDestinations = state.recentDestinations
                self?.commuteShortcuts = SeedData.commuteShortcuts
                self?.travelAlerts = state.travelAlerts
                self?.fareSourceLabel = self?.store.fareSourceLabel ?? ""
            }
            .store(in: &cancellables)

        store.$currentRideOptions
            .map { Array($0.prefix(3)) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$previewRideOptions)

        store.$inlineStatusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$message)
    }
}
