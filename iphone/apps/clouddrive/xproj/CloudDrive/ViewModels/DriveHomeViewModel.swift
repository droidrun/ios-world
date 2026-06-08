import Foundation

@MainActor
struct DriveHomeViewModel {
    let store: WorkspaceStore
    let folderId: String?
    let sort: WorkspaceSortOption

    var currentFolder: WorkspaceFolder? {
        store.folder(id: folderId)
    }

    var items: [BrowserItem] {
        store.browserItems(in: folderId, sort: sort)
    }

    var recentFiles: [WorkspaceFile] {
        store.recentFiles()
    }

    var quickAccessFiles: [WorkspaceFile] {
        store.quickAccessFiles()
    }

    var recentActivity: [RecentActivity] {
        store.recentActivity()
    }
}
