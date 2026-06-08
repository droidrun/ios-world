import Foundation

enum PersistenceKey: String {
    case transactions
    case requests
    case balance
    case friends
    case settings
    case seedVersion
}

enum Persistence {
    static func load<T: Codable>(_ type: T.Type, key: PersistenceKey, fallback: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
            return fallback
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(type, from: data)) ?? fallback
    }

    static func save<T: Codable>(_ value: T, key: PersistenceKey) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }

    static func clearAll() {
        let keys: [PersistenceKey] = [.transactions, .requests, .balance, .friends, .settings, .seedVersion]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}
