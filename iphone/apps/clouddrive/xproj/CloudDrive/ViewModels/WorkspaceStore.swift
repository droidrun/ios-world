import Foundation
import SwiftUI

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var envelope: PersistedWorkspaceEnvelope
    @Published var activeAlert: AppAlert?
    @Published var activeEditorRoute: EditorRoute?
    @Published var transientMessage: String?

    private let persistence: SharedWorkspacePersistence
    private let seededRepository: WorkspaceRepository
    private let snapshotRepository: SnapshotWorkspaceRepository
    private let defaults = UserDefaults.standard
    private let offlineFileIDsKey = "drive_sim_offline_file_ids"

    init(
        persistence: SharedWorkspacePersistence = SharedWorkspacePersistence(),
        seededRepository: WorkspaceRepository = SeededWorkspaceRepository(),
        snapshotRepository: SnapshotWorkspaceRepository = SnapshotWorkspaceRepository()
    ) {
        self.persistence = persistence
        self.seededRepository = seededRepository
        self.snapshotRepository = snapshotRepository

        let seededData = (try? seededRepository.loadWorkspaceData()) ?? SeedDataFactory.makeSeededData()
        let bundledSnapshot = try? snapshotRepository.loadBundledSnapshot()
        let importedSnapshot = try? snapshotRepository.loadImportedSnapshot()

        if var saved = persistence.loadEnvelope() {
            saved.seededData = seededData
            if saved.bundledSnapshotData == nil {
                saved.bundledSnapshotData = bundledSnapshot?.data
                saved.bundledSnapshotMetadata = bundledSnapshot?.metadata
            }
            saved.importedSnapshotData = importedSnapshot?.data ?? saved.importedSnapshotData
            saved.importedSnapshotMetadata = importedSnapshot?.metadata ?? saved.importedSnapshotMetadata
            saved.importedSnapshotFilename = persistence.importedSnapshotFilename() ?? saved.importedSnapshotFilename
            self.envelope = saved
        } else {
            self.envelope = PersistedWorkspaceEnvelope(
                selectedSourceType: .seeded,
                seededData: seededData,
                bundledSnapshotData: bundledSnapshot?.data,
                bundledSnapshotMetadata: bundledSnapshot?.metadata,
                importedSnapshotData: importedSnapshot?.data,
                importedSnapshotMetadata: importedSnapshot?.metadata,
                importedSnapshotFilename: persistence.importedSnapshotFilename(),
                lastHandoff: nil
            )
            saveEnvelope()
        }
    }

    var currentData: WorkspaceData {
        switch envelope.selectedSourceType {
        case .seeded:
            return envelope.seededData
        case .bundledSnapshot:
            return envelope.bundledSnapshotData ?? envelope.seededData
        case .importedSnapshot:
            return envelope.importedSnapshotData ?? envelope.seededData
        }
    }

    var currentMetadata: WorkspaceSnapshotMetadata? {
        switch envelope.selectedSourceType {
        case .seeded:
            return nil
        case .bundledSnapshot:
            return envelope.bundledSnapshotMetadata
        case .importedSnapshot:
            return envelope.importedSnapshotMetadata
        }
    }

    var currentSourceLabel: String {
        envelope.selectedSourceType.title
    }

    var storageModeLabel: String {
        persistence.storageMode.rawValue
    }

    var bundledSnapshotAvailable: Bool {
        envelope.bundledSnapshotData != nil
    }

    var importedSnapshotAvailable: Bool {
        envelope.importedSnapshotData != nil
    }

    var importedSnapshotFilename: String? {
        envelope.importedSnapshotFilename
    }

    var profile: UserWorkspaceProfile {
        currentData.profile
    }

    var contacts: [WorkspaceContact] {
        currentData.contacts
    }

    var lastHandoff: PendingHandoff? {
        envelope.lastHandoff
    }

    func dismissAlert() {
        activeAlert = nil
    }

    func showMessage(_ message: String) {
        transientMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard self?.transientMessage == message else { return }
            self?.transientMessage = nil
        }
    }

    func reloadFromDisk() {
        guard let stored = persistence.loadEnvelope() else {
            return
        }
        envelope = stored
        envelope.importedSnapshotFilename = persistence.importedSnapshotFilename() ?? envelope.importedSnapshotFilename
    }

    func reloadSnapshots() {
        let bundledSnapshot = try? snapshotRepository.loadBundledSnapshot()
        let importedSnapshot = try? snapshotRepository.loadImportedSnapshot()

        envelope.bundledSnapshotData = bundledSnapshot?.data
        envelope.bundledSnapshotMetadata = bundledSnapshot?.metadata
        envelope.importedSnapshotData = importedSnapshot?.data
        envelope.importedSnapshotMetadata = importedSnapshot?.metadata
        envelope.importedSnapshotFilename = persistence.importedSnapshotFilename()

        if envelope.selectedSourceType == .bundledSnapshot, bundledSnapshot == nil {
            envelope.selectedSourceType = .seeded
        }
        if envelope.selectedSourceType == .importedSnapshot, importedSnapshot == nil {
            envelope.selectedSourceType = .seeded
        }

        saveEnvelope()
    }

    func switchSourceType(_ sourceType: WorkspaceSourceType) {
        switch sourceType {
        case .seeded:
            envelope.selectedSourceType = .seeded
        case .bundledSnapshot:
            guard bundledSnapshotAvailable else {
                showAlert(id: "bundled_snapshot_missing", title: "Workspace package unavailable", message: "The bundled workspace package is unavailable.")
                return
            }
            envelope.selectedSourceType = .bundledSnapshot
        case .importedSnapshot:
            guard importedSnapshotAvailable else {
                showAlert(id: "imported_snapshot_missing", title: "Workspace package unavailable", message: "Import a workspace package first.")
                return
            }
            envelope.selectedSourceType = .importedSnapshot
        }
        saveEnvelope()
    }

    func importSnapshot(from url: URL) {
        do {
            let payload = try persistence.importSnapshot(from: url)
            envelope.importedSnapshotData = payload.data
            envelope.importedSnapshotMetadata = payload.metadata
            envelope.importedSnapshotFilename = persistence.importedSnapshotFilename()
            envelope.selectedSourceType = .importedSnapshot
            saveEnvelope()
            showMessage("Workspace package imported.")
        } catch {
            showAlert(id: "snapshot_import_failed", title: "Import failed", message: error.localizedDescription)
        }
    }

    func resetAppState() {
        do {
            try persistence.resetPersistence()
            defaults.removeObject(forKey: offlineFileIDsKey)
            let seeded = (try? seededRepository.loadWorkspaceData()) ?? SeedDataFactory.makeSeededData()
            let bundled = try? snapshotRepository.loadBundledSnapshot()
            let imported = try? snapshotRepository.loadImportedSnapshot()
            envelope = PersistedWorkspaceEnvelope(
                selectedSourceType: .seeded,
                seededData: seeded,
                bundledSnapshotData: bundled?.data,
                bundledSnapshotMetadata: bundled?.metadata,
                importedSnapshotData: imported?.data,
                importedSnapshotMetadata: imported?.metadata,
                importedSnapshotFilename: persistence.importedSnapshotFilename(),
                lastHandoff: nil
            )
            activeEditorRoute = nil
            showMessage("Workspace reset.")
            saveEnvelope()
        } catch {
            showAlert(id: "reset_failed", title: "Reset failed", message: error.localizedDescription)
        }
    }

    func folder(id: String?) -> WorkspaceFolder? {
        guard let id else { return nil }
        return currentData.folders.first(where: { $0.id == id })
    }

    func file(id: String) -> WorkspaceFile? {
        currentData.files.first(where: { $0.id == id })
    }

    func document(id: String) -> DocumentFile? {
        currentData.documents.first(where: { $0.id == id })
    }

    func spreadsheet(id: String) -> SpreadsheetFile? {
        currentData.spreadsheets.first(where: { $0.id == id })
    }

    func presentation(id: String) -> PresentationFile? {
        currentData.presentations.first(where: { $0.id == id })
    }

    func folders(in parentFolderId: String?, includeTrashed: Bool = false) -> [WorkspaceFolder] {
        currentData.folders
            .filter { $0.parentFolderId == parentFolderId && (includeTrashed || !$0.trashed) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func files(
        in parentFolderId: String?,
        includeTrashed: Bool = false,
        sort: WorkspaceSortOption = .recent
    ) -> [WorkspaceFile] {
        sortFiles(
            currentData.files.filter { $0.parentFolderId == parentFolderId && (includeTrashed || !$0.trashed) },
            by: sort
        )
    }

    func browserItems(
        in parentFolderId: String?,
        includeTrashed: Bool = false,
        sort: WorkspaceSortOption = .recent
    ) -> [BrowserItem] {
        let folderItems = folders(in: parentFolderId, includeTrashed: includeTrashed).map(BrowserItem.folder)
        let fileItems = files(in: parentFolderId, includeTrashed: includeTrashed, sort: sort).map(BrowserItem.file)
        return folderItems + fileItems
    }

    func recentFiles(limit: Int = 6) -> [WorkspaceFile] {
        currentData.files
            .filter { !$0.trashed }
            .sorted {
                ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt)
            }
            .prefix(limit)
            .map { $0 }
    }

    func quickAccessFiles(limit: Int = 4) -> [WorkspaceFile] {
        currentData.files
            .filter { !$0.trashed }
            .sorted {
                let lhsScore = ($0.starred ? 2 : 0) + ($0.shared ? 1 : 0)
                let rhsScore = ($1.starred ? 2 : 0) + ($1.shared ? 1 : 0)
                if lhsScore == rhsScore {
                    return $0.updatedAt > $1.updatedAt
                }
                return lhsScore > rhsScore
            }
            .prefix(limit)
            .map { $0 }
    }

    func sharedPreviewFiles(limit: Int = 4) -> [WorkspaceFile] {
        currentData.files
            .filter { $0.shared && !$0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit)
            .map { $0 }
    }

    func suggestedFiles(limit: Int = 4) -> [WorkspaceFile] {
        currentData.files
            .filter { !$0.trashed }
            .sorted {
                let lhs = ($0.shared ? 1 : 0) + ($0.starred ? 1 : 0)
                let rhs = ($1.shared ? 1 : 0) + ($1.starred ? 1 : 0)
                if lhs == rhs {
                    return $0.updatedAt > $1.updatedAt
                }
                return lhs > rhs
            }
            .prefix(limit)
            .map { $0 }
    }

    func starredItems() -> [BrowserItem] {
        let folders = currentData.folders.filter { $0.starred && !$0.trashed }.map(BrowserItem.folder)
        let files = currentData.files.filter { $0.starred && !$0.trashed }.map(BrowserItem.file)
        return folders + files
    }

    func sharedItems() -> [BrowserItem] {
        let folders = currentData.folders.filter { $0.shared && !$0.trashed }.map(BrowserItem.folder)
        let files = currentData.files.filter { $0.shared && !$0.trashed }.map(BrowserItem.file)
        return folders + files
    }

    func sharedDriveFolders() -> [WorkspaceFolder] {
        currentData.folders
            .filter { $0.parentFolderId == nil && $0.id != currentData.rootFolderId && $0.shared && !$0.trashed }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func trashedItems() -> [BrowserItem] {
        let folders = currentData.folders.filter(\.trashed).map(BrowserItem.folder)
        let files = currentData.files.filter(\.trashed).map(BrowserItem.file)
        return folders + files
    }

    func recentActivity(limit: Int = 8) -> [RecentActivity] {
        currentData.recentActivity
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }

    func recentlyCreatedFiles(limit: Int = 12) -> [WorkspaceFile] {
        currentData.files
            .filter { !$0.trashed }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }

    func offlineFiles(limit: Int = 20) -> [WorkspaceFile] {
        currentData.files
            .filter { offlineFileIDs.contains($0.id) && !$0.trashed }
            .sorted { ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt) }
            .prefix(limit)
            .map { $0 }
    }

    func isOffline(fileId: String) -> Bool {
        offlineFileIDs.contains(fileId)
    }

    func availableMoveDestinations(excluding itemId: String?) -> [WorkspaceFolder] {
        let excludedFolderIds = descendantFolderIDs(for: itemId)
        return currentData.folders
            .filter { !$0.trashed && !excludedFolderIds.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func pathFolders(for folderId: String?) -> [WorkspaceFolder] {
        var result: [WorkspaceFolder] = []
        var current = folder(id: folderId)

        while let folder = current {
            result.append(folder)
            current = self.folder(id: folder.parentFolderId)
        }

        return result.reversed()
    }

    func pathString(for file: WorkspaceFile) -> String {
        let names = pathFolders(for: file.parentFolderId).map(\.name)
        return names.isEmpty ? "My Drive" : names.joined(separator: " / ")
    }

    func contentPreview(for file: WorkspaceFile) -> String {
        switch file.fileType {
        case .document:
            return document(id: file.id)?.body.replacingOccurrences(of: "\n", with: " ").prefix(120).description ?? file.name
        case .spreadsheet:
            guard let sheet = spreadsheet(id: file.id)?.sheets.first else {
                return file.name
            }
            let values = sheet.cells.prefix(3).map(\.rawValue).joined(separator: " • ")
            return values.isEmpty ? file.name : values
        case .presentation:
            guard let slide = presentation(id: file.id)?.slides.first else {
                return file.name
            }
            return "\(slide.title) • \(slide.body)"
        }
    }

    func search(
        query: String,
        filter: WorkspaceSearchFilter,
        sort: WorkspaceSortOption
    ) -> [BrowserItem] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var results: [BrowserItem] = []

        let folderMatches = currentData.folders.filter { folder in
            guard folder.trashed == false || filter == .trashed else { return false }
            guard matchesFilter(filter, folder: folder) else { return false }
            if normalized.isEmpty { return true }
            return folder.name.lowercased().contains(normalized)
        }
        results.append(contentsOf: folderMatches.sorted { $0.name < $1.name }.map(BrowserItem.folder))

        let fileMatches = currentData.files.filter { file in
            guard matchesFilter(filter, file: file) else { return false }
            if normalized.isEmpty { return true }

            if file.name.lowercased().contains(normalized) {
                return true
            }

            if contentPreview(for: file).lowercased().contains(normalized) {
                return true
            }

            if let folder = folder(id: file.parentFolderId),
               folder.name.lowercased().contains(normalized) {
                return true
            }

            return false
        }
        results.append(contentsOf: sortFiles(fileMatches, by: sort).map(BrowserItem.file))

        return results
    }

    func createFolder(name: String, parentFolderId: String?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            showAlert(id: "create_folder_empty_name", title: "Unable to create folder", message: "Folder name cannot be empty.")
            return
        }

        mutateCurrentData { data in
            let folderId = nextIdentifier(prefix: "folder", existingIds: data.folders.map(\.id))
            let now = Date()
            data.folders.append(
                WorkspaceFolder(
                    id: folderId,
                    name: trimmed,
                    parentFolderId: parentFolderId,
                    createdAt: now,
                    updatedAt: now,
                    starred: false,
                    shared: false,
                    trashed: false,
                    ownerName: data.profile.displayName
                )
            )
            data.recentActivity.insert(
                RecentActivity(
                    id: nextIdentifier(prefix: "activity", existingIds: data.recentActivity.map(\.id)),
                    summary: "Created folder \(trimmed)",
                    targetFileId: nil,
                    createdAt: now
                ),
                at: 0
            )
        }

        showMessage("Folder created.")
    }

    func renameItem(id: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            showAlert(id: "rename_empty_name", title: "Unable to rename", message: "Name cannot be empty.")
            return
        }

        mutateCurrentData { data in
            if let folderIndex = data.folders.firstIndex(where: { $0.id == id }) {
                data.folders[folderIndex].name = trimmed
                data.folders[folderIndex].updatedAt = Date()
                return
            }

            guard let fileIndex = data.files.firstIndex(where: { $0.id == id }) else { return }
            data.files[fileIndex].name = trimmed
            data.files[fileIndex].updatedAt = Date()
            syncAttachmentTitle(in: &data, fileId: id, title: trimmed)
        }
    }

    func moveItem(id: String, toFolderId destinationFolderId: String?) {
        // nil destination means "My Drive" (the root folder). Resolve it to the
        // actual rootFolderId so the moved item continues to appear under the root
        // when the home view queries folders(in: rootFolderId).
        let resolvedDestination = destinationFolderId ?? currentData.rootFolderId

        if let folder = folder(id: id), isDescendant(folderId: resolvedDestination, of: folder.id) {
            showAlert(id: "invalid_move_destination", title: "Invalid move", message: "You cannot move a folder into itself or one of its subfolders.")
            return
        }

        mutateCurrentData { data in
            let destination = destinationFolderId ?? data.rootFolderId

            if let folderIndex = data.folders.firstIndex(where: { $0.id == id }) {
                data.folders[folderIndex].parentFolderId = destination
                data.folders[folderIndex].updatedAt = Date()
                return
            }

            if let fileIndex = data.files.firstIndex(where: { $0.id == id }) {
                data.files[fileIndex].parentFolderId = destination
                data.files[fileIndex].updatedAt = Date()
            }
        }
    }

    @discardableResult
    func duplicateFile(id: String) -> String? {
        var newId: String?

        mutateCurrentData { data in
            guard let file = data.files.first(where: { $0.id == id }) else { return }
            let duplicateId = nextIdentifier(prefix: file.fileType.accessibilityPrefix, existingIds: data.files.map(\.id))
            var copy = file
            let now = Date()

            copy.id = duplicateId
            copy.name = "Copy of \(file.name)"
            copy.createdAt = now
            copy.updatedAt = now
            copy.lastOpenedAt = nil

            data.files.append(copy)

            switch file.fileType {
            case .document:
                if let source = data.documents.first(where: { $0.id == id }) {
                    var documentCopy = source
                    documentCopy.id = duplicateId
                    documentCopy.title = copy.name
                    data.documents.append(documentCopy)
                }
            case .spreadsheet:
                if let source = data.spreadsheets.first(where: { $0.id == id }) {
                    var spreadsheetCopy = source
                    spreadsheetCopy.id = duplicateId
                    spreadsheetCopy.title = copy.name
                    data.spreadsheets.append(spreadsheetCopy)
                }
            case .presentation:
                if let source = data.presentations.first(where: { $0.id == id }) {
                    var presentationCopy = source
                    presentationCopy.id = duplicateId
                    presentationCopy.title = copy.name
                    data.presentations.append(presentationCopy)
                }
            }

            data.recentActivity.insert(
                RecentActivity(
                    id: nextIdentifier(prefix: "activity", existingIds: data.recentActivity.map(\.id)),
                    summary: "Duplicated \(file.name)",
                    targetFileId: duplicateId,
                    createdAt: now
                ),
                at: 0
            )

            newId = duplicateId
        }

        return newId
    }

    func toggleStar(itemId: String) {
        mutateCurrentData { data in
            if let folderIndex = data.folders.firstIndex(where: { $0.id == itemId }) {
                data.folders[folderIndex].starred.toggle()
                data.folders[folderIndex].updatedAt = Date()
                return
            }

            if let fileIndex = data.files.firstIndex(where: { $0.id == itemId }) {
                data.files[fileIndex].starred.toggle()
                data.files[fileIndex].updatedAt = Date()
            }
        }
    }

    func trashItem(id: String) {
        var offlineIDs = offlineFileIDs

        mutateCurrentData { data in
            if let folderIndex = data.folders.firstIndex(where: { $0.id == id }) {
                data.folders[folderIndex].trashed = true
                data.folders[folderIndex].updatedAt = Date()
                return
            }

            if let fileIndex = data.files.firstIndex(where: { $0.id == id }) {
                data.files[fileIndex].trashed = true
                data.files[fileIndex].updatedAt = Date()
                offlineIDs.remove(id)
            }
        }

        offlineFileIDs = offlineIDs
    }

    func restoreItem(id: String) {
        mutateCurrentData { data in
            if let folderIndex = data.folders.firstIndex(where: { $0.id == id }) {
                data.folders[folderIndex].trashed = false
                data.folders[folderIndex].updatedAt = Date()
                return
            }

            if let fileIndex = data.files.firstIndex(where: { $0.id == id }) {
                data.files[fileIndex].trashed = false
                data.files[fileIndex].updatedAt = Date()
            }
        }
    }

    func updateShareSettings(fileId: String, peopleNames: String, role: AccessRole, visibility: SharedLinkVisibility) {
        let parsedNames = peopleNames
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        mutateCurrentData { data in
            guard let fileIndex = data.files.firstIndex(where: { $0.id == fileId }) else { return }
            let permissions = parsedNames.map { name in
                FilePermission(id: "permission_\(name.stableSlug)", personName: name, role: role)
            }
            data.files[fileIndex].permissions = permissions
            data.files[fileIndex].linkSettings.visibility = visibility
            data.files[fileIndex].linkSettings.defaultRole = role
            data.files[fileIndex].shared = visibility == .anyoneWithLink || !permissions.isEmpty
            data.files[fileIndex].updatedAt = Date()
        }

        showMessage("Sharing updated.")
    }

    func registerShareLinkCopy(fileId: String) {
        mutateCurrentData { data in
            guard let fileIndex = data.files.firstIndex(where: { $0.id == fileId }) else { return }
            data.files[fileIndex].linkSettings.copyCount += 1
            data.files[fileIndex].updatedAt = Date()
        }

        showMessage("Link copied.")
    }

    func toggleOffline(fileId: String) {
        guard file(id: fileId)?.trashed == false else { return }

        var ids = offlineFileIDs
        let isAdding = ids.contains(fileId) == false

        if isAdding {
            ids.insert(fileId)
        } else {
            ids.remove(fileId)
        }

        offlineFileIDs = ids
        showMessage(isAdding ? "Available offline." : "Removed from offline.")
    }

    func recordOpen(fileId: String, sourceApp: String, targetApp: String) {
        var handoff: PendingHandoff?
        mutateCurrentData { data in
            guard let fileIndex = data.files.firstIndex(where: { $0.id == fileId }) else { return }
            let now = Date()
            data.files[fileIndex].lastOpenedAt = now
            data.recentActivity.insert(
                RecentActivity(
                    id: nextIdentifier(prefix: "activity", existingIds: data.recentActivity.map(\.id)),
                    summary: "Opened \(data.files[fileIndex].name) in \(targetApp)",
                    targetFileId: fileId,
                    createdAt: now
                ),
                at: 0
            )
            handoff = PendingHandoff(
                fileId: fileId,
                fileType: data.files[fileIndex].fileType,
                sourceApp: sourceApp,
                targetApp: targetApp,
                createdAt: now
            )
        }
        envelope.lastHandoff = handoff
        saveEnvelope()
    }

    @discardableResult
    func createDocument(parentFolderId: String? = nil, name: String = "Untitled document", body: String = "Start typing here.") -> String {
        let fileId = createFileShell(type: .document, name: name, parentFolderId: resolvedParentFolderId(parentFolderId))
        mutateCurrentData { data in
            data.documents.append(
                DocumentFile(
                    id: fileId,
                    title: name,
                    body: body,
                    formatting: DocumentFormattingState(
                        paragraphStyle: .normal,
                        listStyle: .none,
                        alignment: .leading,
                        bold: false,
                        italic: false,
                        underline: false,
                        suggestionModeEnabled: false
                    ),
                    blocks: body
                        .components(separatedBy: "\n")
                        .enumerated()
                        .map { offset, line in
                            DocumentBlock(id: "block_\(offset + 1)", text: line, paragraphStyle: offset == 0 ? .title : .normal)
                        }
                )
            )
        }
        activeEditorRoute = EditorRoute(fileId: fileId)
        return fileId
    }

    @discardableResult
    func createScannedDocument(parentFolderId: String? = nil, name: String, body: String, sizeDescription: String = "1.8 MB") -> String {
        let resolvedParentId = resolvedParentFolderId(parentFolderId)
        let fileId = createDocument(parentFolderId: resolvedParentId, name: name, body: body)

        mutateCurrentData { data in
            guard let fileIndex = data.files.firstIndex(where: { $0.id == fileId }) else { return }
            data.files[fileIndex].sizeDescription = sizeDescription
            data.files[fileIndex].updatedAt = Date()
            data.recentActivity.insert(
                RecentActivity(
                    id: nextIdentifier(prefix: "activity", existingIds: data.recentActivity.map(\.id)),
                    summary: "Scanned \(name)",
                    targetFileId: fileId,
                    createdAt: Date()
                ),
                at: 0
            )
        }

        showMessage("Scan added to Drive.")
        return fileId
    }

    func updateDocumentTitle(fileId: String, title: String) {
        renameItem(id: fileId, newName: title)
    }

    func updateDocumentBody(fileId: String, body: String) {
        mutateCurrentData { data in
            guard let documentIndex = data.documents.firstIndex(where: { $0.id == fileId }) else { return }
            data.documents[documentIndex].body = body
            data.documents[documentIndex].blocks = body
                .components(separatedBy: "\n")
                .enumerated()
                .map { offset, line in
                    DocumentBlock(id: "block_\(offset + 1)", text: line, paragraphStyle: offset == 0 ? .title : data.documents[documentIndex].formatting.paragraphStyle)
                }
            touchFile(in: &data, fileId: fileId)
        }
    }

    func updateDocumentFormatting(
        fileId: String,
        paragraphStyle: DocumentParagraphStyle? = nil,
        listStyle: DocumentListStyle? = nil,
        alignment: DocumentAlignment? = nil,
        bold: Bool? = nil,
        italic: Bool? = nil,
        underline: Bool? = nil,
        suggestionMode: Bool? = nil
    ) {
        mutateCurrentData { data in
            guard let documentIndex = data.documents.firstIndex(where: { $0.id == fileId }) else { return }
            if let paragraphStyle {
                data.documents[documentIndex].formatting.paragraphStyle = paragraphStyle
            }
            if let listStyle {
                data.documents[documentIndex].formatting.listStyle = listStyle
            }
            if let alignment {
                data.documents[documentIndex].formatting.alignment = alignment
            }
            if let bold {
                data.documents[documentIndex].formatting.bold = bold
            }
            if let italic {
                data.documents[documentIndex].formatting.italic = italic
            }
            if let underline {
                data.documents[documentIndex].formatting.underline = underline
            }
            if let suggestionMode {
                data.documents[documentIndex].formatting.suggestionModeEnabled = suggestionMode
            }
            touchFile(in: &data, fileId: fileId)
        }
    }

    @discardableResult
    func createSpreadsheet(parentFolderId: String? = nil, name: String = "Untitled spreadsheet") -> String {
        let fileId = createFileShell(type: .spreadsheet, name: name, parentFolderId: resolvedParentFolderId(parentFolderId))
        mutateCurrentData { data in
            data.spreadsheets.append(
                SpreadsheetFile(
                    id: fileId,
                    title: name,
                    sheets: [
                        SpreadsheetSheet(
                            id: "sheet_1",
                            name: "Sheet 1",
                            rowCount: 8,
                            columnCount: 5,
                            cells: [
                                SpreadsheetCell(address: "A1", rawValue: "Item"),
                                SpreadsheetCell(address: "B1", rawValue: "Value")
                            ]
                        )
                    ]
                )
            )
        }
        activeEditorRoute = EditorRoute(fileId: fileId)
        return fileId
    }

    func updateSpreadsheetTitle(fileId: String, title: String) {
        renameItem(id: fileId, newName: title)
    }

    func cellRawValue(fileId: String, sheetId: String, address: String) -> String {
        guard let sheet = spreadsheet(id: fileId)?.sheets.first(where: { $0.id == sheetId }) else {
            return ""
        }
        return sheet.cells.first(where: { $0.address == address })?.rawValue ?? ""
    }

    func displayValue(fileId: String, sheetId: String, address: String) -> String {
        let rawValue = cellRawValue(fileId: fileId, sheetId: sheetId, address: address)
        guard rawValue.hasPrefix("=") else {
            return rawValue
        }

        guard let sheet = spreadsheet(id: fileId)?.sheets.first(where: { $0.id == sheetId }) else {
            return rawValue
        }

        return evaluateFormula(rawValue, in: sheet) ?? rawValue
    }

    func updateSpreadsheetCell(fileId: String, sheetId: String, address: String, rawValue: String) {
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }),
                  let sheetIndex = data.spreadsheets[spreadsheetIndex].sheets.firstIndex(where: { $0.id == sheetId }) else {
                return
            }

            if let cellIndex = data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].cells.firstIndex(where: { $0.address == address }) {
                data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].cells[cellIndex].rawValue = rawValue
            } else {
                data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].cells.append(
                    SpreadsheetCell(address: address, rawValue: rawValue)
                )
            }
            touchFile(in: &data, fileId: fileId)
        }
    }

    func addSpreadsheetRow(fileId: String, sheetId: String) {
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }),
                  let sheetIndex = data.spreadsheets[spreadsheetIndex].sheets.firstIndex(where: { $0.id == sheetId }) else {
                return
            }
            data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].rowCount += 1
            touchFile(in: &data, fileId: fileId)
        }
    }

    func removeSpreadsheetRow(fileId: String, sheetId: String) {
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }),
                  let sheetIndex = data.spreadsheets[spreadsheetIndex].sheets.firstIndex(where: { $0.id == sheetId }) else {
                return
            }
            data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].rowCount = max(1, data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].rowCount - 1)
            touchFile(in: &data, fileId: fileId)
        }
    }

    func addSpreadsheetColumn(fileId: String, sheetId: String) {
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }),
                  let sheetIndex = data.spreadsheets[spreadsheetIndex].sheets.firstIndex(where: { $0.id == sheetId }) else {
                return
            }
            data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].columnCount += 1
            touchFile(in: &data, fileId: fileId)
        }
    }

    func removeSpreadsheetColumn(fileId: String, sheetId: String) {
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }),
                  let sheetIndex = data.spreadsheets[spreadsheetIndex].sheets.firstIndex(where: { $0.id == sheetId }) else {
                return
            }
            data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].columnCount = max(1, data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].columnCount - 1)
            touchFile(in: &data, fileId: fileId)
        }
    }

    func addSpreadsheetTab(fileId: String) {
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }) else { return }
            let existingIds = data.spreadsheets[spreadsheetIndex].sheets.map(\.id)
            let newId = nextIdentifier(prefix: "sheet", existingIds: existingIds)
            let index = data.spreadsheets[spreadsheetIndex].sheets.count + 1
            data.spreadsheets[spreadsheetIndex].sheets.append(
                SpreadsheetSheet(id: newId, name: "Sheet \(index)", rowCount: 8, columnCount: 5, cells: [])
            )
            touchFile(in: &data, fileId: fileId)
        }
    }

    func renameSpreadsheetTab(fileId: String, sheetId: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }),
                  let sheetIndex = data.spreadsheets[spreadsheetIndex].sheets.firstIndex(where: { $0.id == sheetId }) else {
                return
            }
            data.spreadsheets[spreadsheetIndex].sheets[sheetIndex].name = trimmed
            touchFile(in: &data, fileId: fileId)
        }
    }

    func duplicateSpreadsheetTab(fileId: String, sheetId: String) {
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }),
                  let sourceSheet = data.spreadsheets[spreadsheetIndex].sheets.first(where: { $0.id == sheetId }) else {
                return
            }
            var copy = sourceSheet
            copy.id = nextIdentifier(prefix: "sheet", existingIds: data.spreadsheets[spreadsheetIndex].sheets.map(\.id))
            copy.name = "Copy of \(sourceSheet.name)"
            data.spreadsheets[spreadsheetIndex].sheets.append(copy)
            touchFile(in: &data, fileId: fileId)
        }
    }

    func deleteSpreadsheetTab(fileId: String, sheetId: String) {
        mutateCurrentData { data in
            guard let spreadsheetIndex = data.spreadsheets.firstIndex(where: { $0.id == fileId }) else { return }
            data.spreadsheets[spreadsheetIndex].sheets.removeAll(where: { $0.id == sheetId })
            touchFile(in: &data, fileId: fileId)
        }
    }

    @discardableResult
    func createPresentation(parentFolderId: String? = nil, name: String = "Untitled presentation") -> String {
        let fileId = createFileShell(type: .presentation, name: name, parentFolderId: resolvedParentFolderId(parentFolderId))
        mutateCurrentData { data in
            data.presentations.append(
                PresentationFile(
                    id: fileId,
                    title: name,
                    themeName: "Neutral",
                    slides: [
                        SlidePage(id: "slide_1", title: "Title slide", body: "Add your speaker notes here.", layout: .titleBody)
                    ]
                )
            )
        }
        activeEditorRoute = EditorRoute(fileId: fileId)
        return fileId
    }

    func updatePresentationTitle(fileId: String, title: String) {
        renameItem(id: fileId, newName: title)
    }

    func updateSlide(fileId: String, slideId: String, title: String? = nil, body: String? = nil, layout: SlideLayout? = nil) {
        mutateCurrentData { data in
            guard let presentationIndex = data.presentations.firstIndex(where: { $0.id == fileId }),
                  let slideIndex = data.presentations[presentationIndex].slides.firstIndex(where: { $0.id == slideId }) else {
                return
            }
            if let title {
                data.presentations[presentationIndex].slides[slideIndex].title = title
            }
            if let body {
                data.presentations[presentationIndex].slides[slideIndex].body = body
            }
            if let layout {
                data.presentations[presentationIndex].slides[slideIndex].layout = layout
            }
            touchFile(in: &data, fileId: fileId)
        }
    }

    func addSlide(fileId: String) {
        mutateCurrentData { data in
            guard let presentationIndex = data.presentations.firstIndex(where: { $0.id == fileId }) else { return }
            let slideId = nextIdentifier(prefix: "slide", existingIds: data.presentations[presentationIndex].slides.map(\.id))
            let count = data.presentations[presentationIndex].slides.count + 1
            data.presentations[presentationIndex].slides.append(
                SlidePage(id: slideId, title: "Slide \(count)", body: "Add slide content.", layout: .titleBody)
            )
            touchFile(in: &data, fileId: fileId)
        }
    }

    func duplicateSlide(fileId: String, slideId: String) {
        mutateCurrentData { data in
            guard let presentationIndex = data.presentations.firstIndex(where: { $0.id == fileId }),
                  let source = data.presentations[presentationIndex].slides.first(where: { $0.id == slideId }) else {
                return
            }
            var copy = source
            copy.id = nextIdentifier(prefix: "slide", existingIds: data.presentations[presentationIndex].slides.map(\.id))
            copy.title = "Copy of \(source.title)"
            data.presentations[presentationIndex].slides.append(copy)
            touchFile(in: &data, fileId: fileId)
        }
    }

    func deleteSlide(fileId: String, slideId: String) {
        mutateCurrentData { data in
            guard let presentationIndex = data.presentations.firstIndex(where: { $0.id == fileId }) else { return }
            data.presentations[presentationIndex].slides.removeAll(where: { $0.id == slideId })
            touchFile(in: &data, fileId: fileId)
        }
    }

    func moveSlide(fileId: String, fromIndex: Int, toIndex: Int) {
        mutateCurrentData { data in
            guard let presentationIndex = data.presentations.firstIndex(where: { $0.id == fileId }),
                  data.presentations[presentationIndex].slides.indices.contains(fromIndex),
                  data.presentations[presentationIndex].slides.indices.contains(toIndex) else {
                return
            }
            let slide = data.presentations[presentationIndex].slides.remove(at: fromIndex)
            data.presentations[presentationIndex].slides.insert(slide, at: toIndex)
            touchFile(in: &data, fileId: fileId)
        }
    }

    func handleIncomingHandoff(url: URL, expectedType: WorkspaceFileType) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let fileId = components.queryItems?.first(where: { $0.name == "file" })?.value,
              let file = file(id: fileId),
              file.fileType == expectedType else {
            showAlert(id: "handoff_invalid", title: "File unavailable", message: "The requested file could not be opened.")
            return
        }
        activeEditorRoute = EditorRoute(fileId: fileId)
        recordOpen(fileId: fileId, sourceApp: "CloudDrive", targetApp: expectedType.title)
    }

    private func matchesFilter(_ filter: WorkspaceSearchFilter, folder: WorkspaceFolder) -> Bool {
        switch filter {
        case .all, .folders:
            return !folder.trashed
        case .starred:
            return folder.starred && !folder.trashed
        case .shared:
            return folder.shared && !folder.trashed
        case .trashed:
            return folder.trashed
        case .documents, .spreadsheets, .presentations:
            return false
        }
    }

    private func matchesFilter(_ filter: WorkspaceSearchFilter, file: WorkspaceFile) -> Bool {
        switch filter {
        case .all:
            return !file.trashed
        case .folders:
            return false
        case .documents:
            return file.fileType == .document && !file.trashed
        case .spreadsheets:
            return file.fileType == .spreadsheet && !file.trashed
        case .presentations:
            return file.fileType == .presentation && !file.trashed
        case .starred:
            return file.starred && !file.trashed
        case .shared:
            return file.shared && !file.trashed
        case .trashed:
            return file.trashed
        }
    }

    private func sortFiles(_ files: [WorkspaceFile], by sort: WorkspaceSortOption) -> [WorkspaceFile] {
        switch sort {
        case .recent:
            return files.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .type:
            return files.sorted {
                if $0.fileType == $1.fileType {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.fileType.rawValue < $1.fileType.rawValue
            }
        }
    }

    private func descendantFolderIDs(for itemId: String?) -> Set<String> {
        guard let itemId,
              let folder = currentData.folders.first(where: { $0.id == itemId }) else {
            return []
        }

        var result: Set<String> = [folder.id]
        var queue = [folder.id]

        while let next = queue.first {
            queue.removeFirst()
            let children = currentData.folders.filter { $0.parentFolderId == next }.map(\.id)
            for child in children where !result.contains(child) {
                result.insert(child)
                queue.append(child)
            }
        }

        return result
    }

    private func isDescendant(folderId: String, of ancestorId: String) -> Bool {
        var cursor = self.folder(id: folderId)
        while let folder = cursor {
            if folder.id == ancestorId {
                return true
            }
            cursor = self.folder(id: folder.parentFolderId)
        }
        return false
    }

    private func createFileShell(type: WorkspaceFileType, name: String, parentFolderId: String?) -> String {
        var newId = ""
        mutateCurrentData { data in
            let prefix = type.accessibilityPrefix
            let now = Date()
            newId = nextIdentifier(prefix: prefix, existingIds: data.files.map(\.id))
            data.files.append(
                WorkspaceFile(
                    id: newId,
                    name: name,
                    fileType: type,
                    parentFolderId: parentFolderId,
                    createdAt: now,
                    updatedAt: now,
                    starred: false,
                    trashed: false,
                    shared: false,
                    ownerName: data.profile.displayName,
                    accessRole: .editor,
                    sizeDescription: type == .presentation ? "1.2 MB" : "12 KB",
                    permissions: [FilePermission(id: "permission_\(data.profile.displayName.stableSlug)", personName: data.profile.displayName, role: .editor)],
                    linkSettings: SharedLinkSettings(visibility: .restricted, defaultRole: .editor, copyCount: 0),
                    comments: [],
                    lastOpenedAt: now
                )
            )
        }
        return newId
    }

    private func resolvedParentFolderId(_ parentFolderId: String?) -> String? {
        parentFolderId ?? currentData.rootFolderId
    }

    private func syncAttachmentTitle(in data: inout WorkspaceData, fileId: String, title: String) {
        if let index = data.documents.firstIndex(where: { $0.id == fileId }) {
            data.documents[index].title = title
        }
        if let index = data.spreadsheets.firstIndex(where: { $0.id == fileId }) {
            data.spreadsheets[index].title = title
        }
        if let index = data.presentations.firstIndex(where: { $0.id == fileId }) {
            data.presentations[index].title = title
        }
    }

    private func touchFile(in data: inout WorkspaceData, fileId: String) {
        if let fileIndex = data.files.firstIndex(where: { $0.id == fileId }) {
            data.files[fileIndex].updatedAt = Date()
            if data.files[fileIndex].lastOpenedAt == nil {
                data.files[fileIndex].lastOpenedAt = Date()
            }
        }
    }

    private func mutateCurrentData(_ mutation: (inout WorkspaceData) -> Void) {
        switch envelope.selectedSourceType {
        case .seeded:
            mutation(&envelope.seededData)
        case .bundledSnapshot:
            if envelope.bundledSnapshotData == nil {
                envelope.bundledSnapshotData = envelope.seededData
            }
            if var bundled = envelope.bundledSnapshotData {
                mutation(&bundled)
                envelope.bundledSnapshotData = bundled
            }
        case .importedSnapshot:
            if envelope.importedSnapshotData == nil {
                envelope.importedSnapshotData = envelope.seededData
            }
            if var imported = envelope.importedSnapshotData {
                mutation(&imported)
                envelope.importedSnapshotData = imported
            }
        }
        saveEnvelope()
    }

    private func saveEnvelope() {
        do {
            try persistence.saveEnvelope(envelope)
        } catch {
            activeAlert = AppAlert(id: "save_failed", title: "Save failed", message: error.localizedDescription)
        }
    }

    private func showAlert(id: String, title: String, message: String) {
        activeAlert = AppAlert(id: id, title: title, message: message)
    }

    private var offlineFileIDs: Set<String> {
        get {
            let values = defaults.stringArray(forKey: offlineFileIDsKey) ?? []
            return Set(values)
        }
        set {
            defaults.set(Array(newValue).sorted(), forKey: offlineFileIDsKey)
        }
    }

    private func nextIdentifier(prefix: String, existingIds: [String]) -> String {
        let normalizedPrefix = prefix.stableSlug
        let suffixes = existingIds.compactMap { id -> Int? in
            guard id.hasPrefix("\(normalizedPrefix)_") else { return nil }
            return Int(id.replacingOccurrences(of: "\(normalizedPrefix)_", with: ""))
        }
        let next = (suffixes.max() ?? 0) + 1
        return "\(normalizedPrefix)_\(next)"
    }

    private func evaluateFormula(_ rawValue: String, in sheet: SpreadsheetSheet) -> String? {
        let normalized = rawValue.uppercased()
        guard normalized.hasPrefix("=") else { return nil }

        if normalized.hasPrefix("=SUM("), let range = extractRange(normalized) {
            let values = numericValues(in: range, for: sheet)
            return formatFormulaResult(values.reduce(0, +))
        }

        if normalized.hasPrefix("=AVG("), let range = extractRange(normalized) {
            let values = numericValues(in: range, for: sheet)
            guard values.isEmpty == false else { return "0" }
            return formatFormulaResult(values.reduce(0, +) / Double(values.count))
        }

        return nil
    }

    private func extractRange(_ formula: String) -> ClosedRange<String>? {
        guard let start = formula.firstIndex(of: "("),
              let end = formula.firstIndex(of: ")") else {
            return nil
        }
        let content = String(formula[formula.index(after: start)..<end])
        let parts = content.split(separator: ":").map(String.init)
        guard parts.count == 2 else { return nil }
        return parts[0]...parts[1]
    }

    private func numericValues(in range: ClosedRange<String>, for sheet: SpreadsheetSheet) -> [Double] {
        let addresses = addressesInRange(start: range.lowerBound, end: range.upperBound)
        let dictionary = Dictionary(uniqueKeysWithValues: sheet.cells.map { ($0.address.uppercased(), $0.rawValue) })
        return addresses.compactMap { address in
            guard let raw = dictionary[address], let value = Double(raw) else { return nil }
            return value
        }
    }

    private func addressesInRange(start: String, end: String) -> [String] {
        guard let startPoint = splitAddress(start), let endPoint = splitAddress(end) else {
            return []
        }

        let columnStart = min(startPoint.column, endPoint.column)
        let columnEnd = max(startPoint.column, endPoint.column)
        let rowStart = min(startPoint.row, endPoint.row)
        let rowEnd = max(startPoint.row, endPoint.row)

        var result: [String] = []
        for column in columnStart...columnEnd {
            for row in rowStart...rowEnd {
                result.append("\(columnName(for: column))\(row)")
            }
        }
        return result
    }

    private func splitAddress(_ address: String) -> (column: Int, row: Int)? {
        let letters = address.prefix { $0.isLetter }
        let digits = String(address.reversed().prefix { $0.isNumber }.reversed())
        guard letters.isEmpty == false, let row = Int(digits) else {
            return nil
        }
        var column = 0
        for scalar in letters.uppercased().unicodeScalars {
            column = (column * 26) + Int(scalar.value) - 64
        }
        return (column, row)
    }

    private func columnName(for index: Int) -> String {
        var value = index
        var name = ""
        while value > 0 {
            let remainder = (value - 1) % 26
            if let scalar = UnicodeScalar(65 + remainder) {
                name = String(Character(scalar)) + name
            }
            value = (value - 1) / 26
        }
        return name
    }

    private func formatFormulaResult(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}
