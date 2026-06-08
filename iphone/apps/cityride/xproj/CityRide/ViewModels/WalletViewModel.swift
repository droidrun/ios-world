import Combine
import Foundation

final class WalletViewModel: ObservableObject {
    @Published private(set) var walletState: WalletState = SeedData.walletState
    @Published private(set) var selectedPaymentMethodID: String = ""
    @Published private(set) var message: String?

    let store: CityRideStore
    private var cancellables = Set<AnyCancellable>()

    init(store: CityRideStore) {
        self.store = store
        bind()
    }

    var receipts: [RideReceipt] {
        store.state.receipts.sorted(by: { $0.generatedAt > $1.generatedAt })
    }

    func setPaymentMethod(id: String) {
        store.setPaymentMethod(id: id)
    }

    private func bind() {
        store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.walletState = state.walletState
                self?.selectedPaymentMethodID = state.selectedPaymentMethodId
            }
            .store(in: &cancellables)

        store.$inlineStatusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$message)
    }
}
