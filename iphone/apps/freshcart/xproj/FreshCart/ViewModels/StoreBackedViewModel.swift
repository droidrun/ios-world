import Combine
import Foundation

@MainActor
class StoreBackedViewModel: ObservableObject {
    let store: FreshCartStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: FreshCartStore) {
        self.store = store
        store.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
