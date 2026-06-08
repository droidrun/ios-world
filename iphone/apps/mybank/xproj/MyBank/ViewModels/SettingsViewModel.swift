import Combine
import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var ledgerMode: String
    @Published var ledgerPath: String

    private let store: BankStore

    init(store: BankStore) {
        self.store = store
        self.ledgerMode = store.ledgerService.storageMode.rawValue
        self.ledgerPath = store.ledgerService.ledgerFileURL.path
    }

    func importLedger() {
        store.importFromSharedLedger()
    }

    func exportLedger() {
        store.exportLedger()
    }

    func simulateInbound() {
        store.simulateInboundTransaction()
    }

    func resetLocal() {
        store.resetLocalState()
    }

    func resetAll() {
        store.resetAllState()
    }

    func postPendingNow() {
        store.postAllPending(reason: "manual")
    }
}
