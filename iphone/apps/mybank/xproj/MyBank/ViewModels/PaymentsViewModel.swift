import Combine
import Foundation

final class PaymentsViewModel: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var payees: [Payee] = []
    @Published private(set) var scheduledPayments: [ScheduledPayment] = []

    @Published var transferAmountText = ""
    @Published var transferNote = ""
    @Published var fromAccountId: UUID? = nil
    @Published var toAccountId: UUID? = nil

    @Published var scheduledAmountText = ""
    @Published var selectedPayeeId: UUID? = nil
    @Published var scheduleDate = Date()

    private let store: BankStore
    private var cancellables = Set<AnyCancellable>()

    init(store: BankStore) {
        self.store = store

        store.$accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                self?.accounts = accounts
                if self?.fromAccountId == nil {
                    self?.fromAccountId = accounts.first(where: { $0.type == .checking })?.id
                }
                if self?.toAccountId == nil {
                    self?.toAccountId = accounts.first(where: { $0.type == .savings })?.id
                }
            }
            .store(in: &cancellables)

        store.$payees
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payees in
                self?.payees = payees
                if self?.selectedPayeeId == nil {
                    self?.selectedPayeeId = payees.first?.id
                }
            }
            .store(in: &cancellables)

        store.$scheduledPayments
            .receive(on: DispatchQueue.main)
            .assign(to: &$scheduledPayments)
    }

    func submitTransfer() {
        guard let fromAccountId, let toAccountId else { return }
        let amount = Double(transferAmountText) ?? 0
        store.createTransfer(from: fromAccountId, to: toAccountId, amount: amount, note: transferNote)
        transferAmountText = ""
        transferNote = ""
    }

    func schedulePayment() {
        guard let selectedPayeeId else { return }
        let amount = Double(scheduledAmountText) ?? 0
        store.schedulePayment(payeeId: selectedPayeeId, amount: amount, scheduleDate: scheduleDate)
        scheduledAmountText = ""
    }

    func runScheduledNow() {
        store.runDueScheduledPayments(reason: "manual")
    }

    func payeeName(for id: UUID) -> String {
        payees.first(where: { $0.id == id })?.name ?? "Payee"
    }
}
