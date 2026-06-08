import Foundation

protocol CatalogRepository {
    func loadCatalog() -> CatalogData?
}

enum SnapshotCatalogLocation: String {
    case bundled
    case documents

    var label: String {
        switch self {
        case .bundled:
            return "Bundled Resource"
        case .documents:
            return "Documents Override"
        }
    }
}

final class SeededCatalogRepository: CatalogRepository {
    func loadCatalog() -> CatalogData? {
        SeedData.seededCatalog()
    }
}

final class SnapshotCatalogRepository: CatalogRepository {
    private let persistence: AppPersistence
    private(set) var currentLocation: SnapshotCatalogLocation?
    private(set) var lastCatalog: CatalogData?

    init(persistence: AppPersistence) {
        self.persistence = persistence
    }

    func loadCatalog() -> CatalogData? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = persistence.readSandboxSnapshotData(),
           let catalog = try? decoder.decode(CatalogData.self, from: data) {
            currentLocation = .documents
            lastCatalog = catalog
            return catalog
        }

        guard let data = bundledSnapshotData(),
              let catalog = try? decoder.decode(CatalogData.self, from: data) else {
            currentLocation = nil
            lastCatalog = nil
            return nil
        }

        currentLocation = .bundled
        lastCatalog = catalog
        return catalog
    }

    func reloadBundledSnapshotData() -> CatalogData? {
        guard let data = bundledSnapshotData() else {
            return nil
        }

        do {
            try persistence.writeSandboxSnapshotData(data)
            return loadCatalog()
        } catch {
            return nil
        }
    }

    private func bundledSnapshotData() -> Data? {
        let directURL = Bundle.main.url(forResource: "catalog_snapshot", withExtension: "json")
        let nestedURL = Bundle.main.url(forResource: "catalog_snapshot", withExtension: "json", subdirectory: "Resources")
        guard let url = directURL ?? nestedURL else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
}
