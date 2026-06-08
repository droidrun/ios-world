import Combine
import Foundation

@MainActor
class StoreBackedViewModel: ObservableObject {
    let store: WorkspaceStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: WorkspaceStore) {
        self.store = store
        store.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
