import Combine
import Foundation

enum TransactionSort: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case largestAmount
    case smallestAmount

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .largestAmount: return "Largest Amount"
        case .smallestAmount: return "Smallest Amount"
        }
    }
}

final class TransactionsViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var accounts: [Account] = []

    @Published var searchText = ""
    @Published var selectedAccountId: UUID? = nil
    @Published var selectedCategory: String? = nil
    @Published var selectedStatus: TransactionStatus? = nil
    @Published var sort: TransactionSort = .newest
    @Published var minAmountText = ""
    @Published var maxAmountText = ""
    @Published var startDate: Date? = nil
    @Published var endDate: Date? = nil

    private let store: BankStore
    private var cancellables = Set<AnyCancellable>()

    init(store: BankStore) {
        self.store = store

        store.$transactions
            .receive(on: DispatchQueue.main)
            .assign(to: &$transactions)

        store.$accounts
            .receive(on: DispatchQueue.main)
            .assign(to: &$accounts)
    }

    var categories: [String] {
        let set = Set(transactions.map { $0.category })
        return Array(set).sorted()
    }

    var filteredTransactions: [Transaction] {
        var results = transactions

        if let accountId = selectedAccountId {
            results = results.filter { $0.accountId == accountId }
        }
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        if let status = selectedStatus {
            results = results.filter { $0.status == status }
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            let lower = trimmedSearch.lowercased()
            results = results.filter {
                $0.vendor.lowercased().contains(lower)
                || $0.category.lowercased().contains(lower)
                || ($0.note?.lowercased().contains(lower) ?? false)
                || $0.sourceApp.lowercased().contains(lower)
            }
        }

        if let minAmount = Double(minAmountText) {
            results = results.filter { abs($0.amount) >= minAmount }
        }
        if let maxAmount = Double(maxAmountText) {
            results = results.filter { abs($0.amount) <= maxAmount }
        }

        if let startDate = startDate {
            results = results.filter { $0.timestamp >= startDate }
        }
        if let endDate = endDate {
            results = results.filter { $0.timestamp <= endDate }
        }

        switch sort {
        case .newest:
            results = results.sorted(by: { $0.timestamp > $1.timestamp })
        case .oldest:
            results = results.sorted(by: { $0.timestamp < $1.timestamp })
        case .largestAmount:
            results = results.sorted(by: { abs($0.amount) > abs($1.amount) })
        case .smallestAmount:
            results = results.sorted(by: { abs($0.amount) < abs($1.amount) })
        }

        return results
    }

    func accountName(for id: UUID) -> String {
        accounts.first(where: { $0.id == id })?.name ?? "Account"
    }
}
