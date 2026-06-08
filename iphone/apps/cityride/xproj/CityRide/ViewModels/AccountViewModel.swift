import Combine
import Foundation

final class AccountViewModel: ObservableObject {
    @Published private(set) var userProfile: UserProfile = SeedData.userProfile
    @Published private(set) var passengerProfile: PassengerProfile = SeedData.passengerProfile
    @Published private(set) var savedPlaces: [SavedPlace] = SeedData.savedPlaces
    @Published private(set) var travelAlerts: [TravelAlert] = SeedData.travelAlerts
    @Published private(set) var message: String?

    let store: CityRideStore
    private var cancellables = Set<AnyCancellable>()

    init(store: CityRideStore) {
        self.store = store
        bind()
    }

    func useSavedPlaceAsDestination(_ savedPlace: SavedPlace) {
        store.setDestination(from: savedPlace)
    }

    func renameSavedPlace(_ savedPlaceID: String, newName: String) {
        store.renameSavedPlace(savedPlaceID: savedPlaceID, newName: newName)
    }

    func openHelpSupport() {}

    func openWallet() {
        store.postStatusMessage("Open the Wallet tab to manage payment methods.")
    }

    func openSafetyToolkit() {}

    func openInbox() {}

    func openPrivacySettings() {}

    func openFavoriteDestinations() {}

    func openAppPreferences() {}

    func setNotificationsEnabled(_ enabled: Bool) {
        store.postStatusMessage(enabled ? "Notifications enabled." : "Notifications disabled.")
    }

    func setShareTripStatusEnabled(_ enabled: Bool) {
        store.postStatusMessage(enabled ? "Trip status sharing enabled." : "Trip status sharing disabled.")
    }

    private func bind() {
        store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.userProfile = state.userProfile
                self?.passengerProfile = state.passengerProfile
                self?.savedPlaces = state.savedPlaces
                self?.travelAlerts = state.travelAlerts
            }
            .store(in: &cancellables)

        store.$inlineStatusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$message)
    }
}
