import Foundation

@MainActor
final class WalletViewModel: StoreBackedViewModel {
    var boardingPasses: [BoardingPass] {
        store.boardingPasses
    }

    var savedTrips: [Trip] {
        store.upcomingTrips
    }

    var userProfile: UserProfile {
        store.userProfile
    }

    var skyMilesAccount: SkyMilesAccount {
        store.skyMilesAccount
    }

    var walletTabSection: WalletTabSection {
        get { store.walletTabSection }
        set { store.walletTabSection = newValue }
    }

    func trip(for id: String) -> Trip? {
        store.trip(with: id)
    }
}
