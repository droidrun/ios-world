import Foundation

enum PersistenceKey: String {
    case state = "dining_sim_state"
}

enum PersistenceManager {
    private static let defaults = UserDefaults.standard

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func save(_ state: PersistedState) {
        guard let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: PersistenceKey.state.rawValue)
    }

    static func loadState() -> PersistedState? {
        guard let data = defaults.data(forKey: PersistenceKey.state.rawValue) else { return nil }
        return try? decoder.decode(PersistedState.self, from: data)
    }

    static func clearAll() {
        defaults.removeObject(forKey: PersistenceKey.state.rawValue)
    }
}
