import Foundation

@MainActor
final class GameDetailViewModel: ObservableObject {
    @Published var game: Game
    @Published var dataOrigin: DataOrigin = .fallback
    @Published var loadState: LoadState = .idle
    @Published var warningMessage: String?

    init(game: Game) {
        self.game = game
    }

    func refresh(appState: AppState) async {
        loadState = .loading

        let result = await appState.repository.loadGameDetail(for: game, mode: appState.dataAccessMode)
        game = result.value
        dataOrigin = result.origin
        warningMessage = result.warningMessage
        loadState = .loaded

        appState.refreshCacheMetadata()
    }
}
