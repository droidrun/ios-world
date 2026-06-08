import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var recentTransactions: [Transaction] = []

    private let store: BankStore
    private var cancellables = Set<AnyCancellable>()

    init(store: BankStore) {
        self.store = store

        store.$accounts
            .receive(on: DispatchQueue.main)
            .assign(to: &$accounts)

        store.$transactions
            .map { transactions in
                transactions.sorted(by: { $0.timestamp > $1.timestamp }).prefix(6)
            }
            .map { Array($0) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$recentTransactions)
    }

    func account(for id: UUID) -> Account? {
        accounts.first(where: { $0.id == id })
    }

    func deposit(to accountId: UUID, amount: Double, note: String?) {
        store.createDeposit(to: accountId, amount: amount, note: note)
    }

    func transfer(from fromId: UUID, to toId: UUID, amount: Double, note: String?) {
        store.createTransfer(from: fromId, to: toId, amount: amount, note: note)
    }

    var checkingAccount: Account? {
        accounts.first(where: { $0.type == .checking })
    }

    var creditAccount: Account? {
        accounts.first(where: { $0.type == .credit })
    }
}
