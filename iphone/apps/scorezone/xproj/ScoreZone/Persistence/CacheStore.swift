import Foundation

private struct CacheEnvelope<T: Codable>: Codable {
    let payload: T
    let metadata: CachedResponseMetadata
}

final class CacheStore {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let cachePrefix = "scorezone_sim_cache_"
    private let metadataListKey = "scorezone_sim_cache_metadata_list"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    @discardableResult
    func save<T: Codable>(_ payload: T, key: String, origin: DataOrigin, note: String) -> CachedResponseMetadata {
        let metadata = CachedResponseMetadata(
            id: UUID().uuidString,
            cacheKey: key,
            fetchedAt: Date(),
            expiresAt: nil,
            origin: origin,
            note: note
        )
        let envelope = CacheEnvelope(payload: payload, metadata: metadata)

        if let encoded = try? encoder.encode(envelope) {
            userDefaults.set(encoded, forKey: namespacedKey(key))
            updateMetadataList(with: metadata)
        }

        return metadata
    }

    func load<T: Codable>(_ type: T.Type, key: String) -> (value: T, metadata: CachedResponseMetadata)? {
        guard let data = userDefaults.data(forKey: namespacedKey(key)) else {
            return nil
        }

        do {
            let envelope = try decoder.decode(CacheEnvelope<T>.self, from: data)
            return (envelope.payload, envelope.metadata)
        } catch {
            return nil
        }
    }

    func latestMetadata() -> [CachedResponseMetadata] {
        guard let data = userDefaults.data(forKey: metadataListKey) else {
            return []
        }
        guard let items = try? decoder.decode([CachedResponseMetadata].self, from: data) else {
            return []
        }
        return items.sorted { $0.fetchedAt > $1.fetchedAt }
    }

    func clearAll() {
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(cachePrefix) {
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.removeObject(forKey: metadataListKey)
    }

    private func namespacedKey(_ key: String) -> String {
        "\(cachePrefix)\(key)"
    }

    private func updateMetadataList(with metadata: CachedResponseMetadata) {
        var existing = latestMetadata().filter { $0.cacheKey != metadata.cacheKey }
        existing.append(metadata)
        if let encoded = try? encoder.encode(Array(existing.prefix(50))) {
            userDefaults.set(encoded, forKey: metadataListKey)
        }
    }
}
