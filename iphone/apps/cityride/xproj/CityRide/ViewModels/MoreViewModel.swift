import Combine
import Foundation

final class MoreViewModel: ObservableObject {
    @Published private(set) var fareMode: FareSourceType = .seeded
    @Published private(set) var snapshotLocation: SnapshotLocation = .bundled
    @Published private(set) var fareSourceLabel: String = ""
    @Published private(set) var activeTrip: Trip?
    @Published private(set) var message: String?
    @Published var autoAdvanceEnabled: Bool = true

    let store: CityRideStore
    private var cancellables = Set<AnyCancellable>()

    init(store: CityRideStore) {
        self.store = store
        bind()
        autoAdvanceEnabled = store.lifecycleAutoAdvanceEnabled
    }

    func setFareMode(_ mode: FareSourceType) {
        store.setFareMode(mode)
    }

    func setSnapshotLocation(_ location: SnapshotLocation) {
        store.setSnapshotLocation(location)
    }

    func reloadBundledSnapshot() {
        store.reloadBundledSnapshotData()
    }

    func copyBundledSnapshotToSandbox() {
        store.copyBundledSnapshotToSandbox()
    }

    func loadSandboxSnapshot() {
        store.loadSandboxSnapshotData()
    }

    func advanceTrip() {
        store.advanceActiveTrip()
    }

    func cancelActiveTrip() {
        guard let activeTrip else {
            return
        }
        store.cancelTrip(tripID: activeTrip.id)
    }

    func completeActiveTrip() {
        guard let activeTrip else {
            return
        }
        store.completeTrip(tripID: activeTrip.id)
    }

    func resetAppState() {
        store.resetAppState()
    }

    func setAutoAdvance(_ enabled: Bool) {
        autoAdvanceEnabled = enabled
        store.setAutoLifecycleProgression(enabled)
    }

    private func bind() {
        store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.fareMode = state.fareMode
                self?.snapshotLocation = state.snapshotLocation
                self?.fareSourceLabel = self?.store.fareSourceLabel ?? ""
                self?.activeTrip = self?.store.activeTrip
            }
            .store(in: &cancellables)

        store.$inlineStatusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$message)
    }
}
