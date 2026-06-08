import Foundation

enum PersistenceKey: String {
    case visitLogs
    case listCollections
    case followedFriends
    case settings
    case userProfile
    case feedInteractions
}

enum Persistence {
    static func load<T: Codable>(_ type: T.Type, key: PersistenceKey, fallback: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
            return fallback
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(type, from: data)
        } catch {
            #if DEBUG
            print("[Persistence] Failed to decode \(key.rawValue) (\(type)): \(error)")
            #endif
            return fallback
        }
    }

    static func save<T: Codable>(_ value: T, key: PersistenceKey) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(value)
            UserDefaults.standard.set(data, forKey: key.rawValue)
        } catch {
            #if DEBUG
            print("[Persistence] Failed to encode \(key.rawValue): \(error)")
            #endif
        }
    }

    static func clearAll() {
        let keys: [PersistenceKey] = [.visitLogs, .listCollections, .followedFriends, .settings, .userProfile, .feedInteractions]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}
