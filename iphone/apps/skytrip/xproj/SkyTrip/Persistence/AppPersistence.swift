import Foundation

struct AppPersistence {
    private let stateKey = "delta_sim_persisted_state_v1"

    func load() -> PersistedAppState? {
        guard let data = UserDefaults.standard.data(forKey: stateKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(PersistedAppState.self, from: data)
    }

    func save(_ state: PersistedAppState) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(state) else {
            return
        }
        UserDefaults.standard.set(data, forKey: stateKey)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: stateKey)
    }
}
