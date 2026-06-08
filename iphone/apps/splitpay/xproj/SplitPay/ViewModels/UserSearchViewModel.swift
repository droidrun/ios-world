import Foundation

final class UserSearchViewModel: ObservableObject {
    @Published var query: String = ""

    private static let excludedIDs: Set<String> = [SeedData.systemID, "user_doordash"]

    func results(store: SplitPayStore) -> [User] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return store.users.filter { !$0.isYou && !Self.excludedIDs.contains($0.id) }
        }
        let lower = trimmed.lowercased()
        return store.users.filter {
            !$0.isYou && !Self.excludedIDs.contains($0.id) && (
                $0.displayName.lowercased().contains(lower) ||
                $0.username.lowercased().contains(lower)
            )
        }
    }
}
