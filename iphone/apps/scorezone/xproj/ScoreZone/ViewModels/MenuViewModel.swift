import Foundation

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var cacheMetadata: [CachedResponseMetadata] = []

    func refresh(appState: AppState) {
        appState.refreshCacheMetadata()
        cacheMetadata = appState.cacheMetadata
    }

    func reset(appState: AppState) {
        appState.resetAppState()
        refresh(appState: appState)
    }
}
