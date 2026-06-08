import Combine
import Foundation

final class SavingsViewModel: ObservableObject {
    @Published private(set) var savingsAccount: Account?
    @Published private(set) var progress: Double = 0

    let goalAmount: Double = 15000

    private let store: BankStore
    private var cancellables = Set<AnyCancellable>()

    init(store: BankStore) {
        self.store = store

        store.$accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                guard let self else { return }
                let account = accounts.first(where: { $0.type == .savings })
                self.savingsAccount = account
                if let balance = account?.balance {
                    self.progress = min(1, max(0, balance / self.goalAmount))
                } else {
                    self.progress = 0
                }
            }
            .store(in: &cancellables)
    }

    func deposit(amount: Double, note: String?) {
        guard let accountId = savingsAccount?.id else { return }
        store.createDeposit(to: accountId, amount: amount, note: note)
    }
}
