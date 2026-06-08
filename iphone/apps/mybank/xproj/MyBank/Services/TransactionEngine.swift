import Foundation

final class TransactionEngine {
    private var scheduledIds = Set<UUID>()

    func defaultAccountId(for category: String, accounts: [Account]) -> UUID? {
        let lowered = category.lowercased()
        if lowered.contains("credit") || lowered.contains("card") {
            return accounts.first(where: { $0.type == .credit })?.id
        }
        return accounts.first(where: { $0.type == .checking })?.id ?? accounts.first?.id
    }

    func normalizedIngestAmount(_ amount: Double) -> Double {
        if amount > 0 {
            return -amount
        }
        return amount
    }

    func schedulePosting(for transactionId: UUID, in store: BankStore, delay: TimeInterval? = nil) {
        guard !scheduledIds.contains(transactionId) else { return }
        scheduledIds.insert(transactionId)
        let wait = delay ?? Double.random(in: 10...30)
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self, weak store] in
            guard let self, let store else { return }
            self.scheduledIds.remove(transactionId)
            self.postTransaction(transactionId: transactionId, in: store, reason: "auto")
        }
    }

    func postAllPending(in store: BankStore, reason: String) {
        let pendingIds = store.transactions.filter { $0.status == .pending }.map { $0.id }
        for id in pendingIds {
            postTransaction(transactionId: id, in: store, reason: reason)
        }
    }

    func postTransaction(transactionId: UUID, in store: BankStore, reason: String) {
        guard let index = store.transactions.firstIndex(where: { $0.id == transactionId }) else { return }
        var transaction = store.transactions[index]
        guard transaction.status == .pending else { return }
        transaction.status = .posted
        store.transactions[index] = transaction
        applyTransaction(transaction, accounts: &store.accounts)
        store.saveState()
        store.ledgerService.upsertRecord(transaction)
        #if DEBUG
        print("[Engine] Posted transaction \(transaction.externalId) (\(reason))")
        #endif
    }

    func applyTransaction(_ transaction: Transaction, accounts: inout [Account]) {
        guard let index = accounts.firstIndex(where: { $0.id == transaction.accountId }) else { return }
        var account = accounts[index]
        let amount = transaction.amount
        let delta: Double
        if account.type == .credit {
            delta = amount < 0 ? abs(amount) : -abs(amount)
        } else {
            delta = amount
        }
        account.balance += delta
        if account.type == .credit, let limit = account.creditLimit {
            account.availableBalance = limit - account.balance
        } else {
            account.availableBalance = account.balance
        }
        account.lastUpdated = Date()
        accounts[index] = account
    }
}
