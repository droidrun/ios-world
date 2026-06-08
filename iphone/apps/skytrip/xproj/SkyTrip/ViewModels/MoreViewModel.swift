import Foundation

@MainActor
final class MoreViewModel: StoreBackedViewModel {
    @Published private(set) var debugMessage: String?

    var userProfile: UserProfile {
        store.userProfile
    }

    var skyMilesAccount: SkyMilesAccount {
        store.skyMilesAccount
    }

    var fareSourceType: FareSourceType {
        get { store.fareSourceType }
        set { store.setFareSource(newValue) }
    }

    var snapshotMetadata: FareSnapshotMetadata? {
        store.snapshotMetadata
    }

    var snapshotSourcePath: String {
        store.snapshotSourcePath ?? "Unavailable"
    }

    var snapshotError: String? {
        store.snapshotError
    }

    func reloadBundledSnapshot() {
        let result = store.reloadBundledSnapshotData()
        switch result {
        case .success:
            debugMessage = "Bundled snapshot copied and reloaded."
        case .failure(let error):
            debugMessage = error.localizedDescription
        }
    }

    func refreshSnapshotStatus() {
        store.refreshSnapshotStatus()
    }

    func resetPersistence() {
        store.resetPersistenceOnly()
        debugMessage = "Local data has been reset."
    }

    func resetAppState() {
        store.resetAppState()
        debugMessage = "App state has been reset."
    }
}
