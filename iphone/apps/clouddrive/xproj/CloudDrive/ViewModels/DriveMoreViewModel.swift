import Foundation

@MainActor
struct DriveMoreViewModel {
    let store: WorkspaceStore

    var storageText: String {
        AppFormatters.storageText(usedGB: store.profile.storageUsedGB, limitGB: store.profile.storageLimitGB)
    }

    var sourceLabel: String {
        store.currentSourceLabel
    }

    var importedSnapshotFilename: String {
        store.importedSnapshotFilename ?? "No imported package"
    }
}
