import SwiftUI
import UIKit

struct FolderBrowserView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DriveActionCoordinator
    let folderId: String

    @State private var sort: WorkspaceSortOption = .recent
    @State private var ascending = false
    @State private var gridLayout = false
    @State private var showScan = false
    @State private var showCreateFolder = false
    @State private var showCreateOptions = false
    @State private var newFolderName = ""

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var currentFolder: WorkspaceFolder? {
        store.folder(id: folderId)
    }

    private var folders: [WorkspaceFolder] {
        let base = store.folders(in: folderId)
        let sorted: [WorkspaceFolder]

        switch sort {
        case .recent:
            sorted = base.sorted { $0.updatedAt < $1.updatedAt }
        case .name, .type:
            sorted = base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return ascending ? sorted : Array(sorted.reversed())
    }

    private var files: [WorkspaceFile] {
        let base = store.files(in: folderId, sort: sort)
        let sorted: [WorkspaceFile]

        switch sort {
        case .recent:
            sorted = base.sorted { $0.updatedAt < $1.updatedAt }
        case .name:
            sorted = base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .type:
            sorted = base.sorted {
                if $0.fileType == $1.fileType {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.fileType.rawValue < $1.fileType.rawValue
            }
        }

        return ascending ? sorted : Array(sorted.reversed())
    }

    private var isEmpty: Bool {
        folders.isEmpty && files.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DrivePalette.listSurface
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    DriveSortHeader(
                        title: titleForSort(sort),
                        ascending: ascending,
                        isGridLayout: gridLayout,
                        sortOptions: [.recent, .name, .type],
                        selectSort: { sort = $0 },
                        sortAction: { ascending.toggle() },
                        layoutAction: { gridLayout.toggle() }
                    )

                    if isEmpty {
                        EmptyStateCard(
                            title: "Empty folder",
                            message: "This folder does not contain any items yet.",
                            systemImage: "folder",
                            accessibilityIdentifier: AccessibilityID.emptyState("empty_folder")
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    } else if gridLayout {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(folders) { folder in
                                DriveFolderGridCard(
                                    folder: folder,
                                    subtitle: modifiedText(for: folder.updatedAt),
                                    onOpen: { },
                                    onRename: { coordinator.beginRename(itemId: folder.id, currentName: folder.name) },
                                    onMove: { coordinator.beginMove(itemId: folder.id, currentParentId: folder.parentFolderId) },
                                    onToggleStar: { store.toggleStar(itemId: folder.id) },
                                    onTrashOrRestore: { folder.trashed ? store.restoreItem(id: folder.id) : store.trashItem(id: folder.id) }
                                )
                                .overlay {
                                    NavigationLink(value: folder.id) {
                                        EmptyView()
                                    }
                                    .opacity(0.001)
                                }
                            }

                            ForEach(files) { file in
                                DriveFileGridCard(
                                    file: file,
                                    subtitle: modifiedText(for: file.updatedAt),
                                    showOwner: file.shared,
                                    showOfflineMarker: store.isOffline(fileId: file.id),
                                    onOpen: { openFile(file) },
                                    onDetails: { coordinator.detailFileId = file.id },
                                    onRename: { coordinator.beginRename(itemId: file.id, currentName: file.name) },
                                    onMove: { coordinator.beginMove(itemId: file.id, currentParentId: file.parentFolderId) },
                                    onShare: { coordinator.beginShare(file: file) },
                                    onDuplicate: { _ = store.duplicateFile(id: file.id) },
                                    onToggleStar: { store.toggleStar(itemId: file.id) },
                                    onToggleOffline: { store.toggleOffline(fileId: file.id) },
                                    onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 132)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(folders) { folder in
                                NavigationLink(value: folder.id) {
                                    DriveMyDriveFolderRow(
                                        folder: folder,
                                        subtitle: modifiedText(for: folder.updatedAt),
                                        onOpen: { },
                                        onRename: { coordinator.beginRename(itemId: folder.id, currentName: folder.name) },
                                        onMove: { coordinator.beginMove(itemId: folder.id, currentParentId: folder.parentFolderId) },
                                        onToggleStar: { store.toggleStar(itemId: folder.id) },
                                        onTrashOrRestore: { folder.trashed ? store.restoreItem(id: folder.id) : store.trashItem(id: folder.id) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(files) { file in
                                DriveStandardFileRow(
                                    file: file,
                                    subtitle: modifiedText(for: file.updatedAt),
                                    showStarMarker: file.starred,
                                    showSharedMarker: file.shared,
                                    showOfflineMarker: store.isOffline(fileId: file.id),
                                    onOpen: { openFile(file) },
                                    onDetails: { coordinator.detailFileId = file.id },
                                    onRename: { coordinator.beginRename(itemId: file.id, currentName: file.name) },
                                    onMove: { coordinator.beginMove(itemId: file.id, currentParentId: file.parentFolderId) },
                                    onShare: { coordinator.beginShare(file: file) },
                                    onDuplicate: { _ = store.duplicateFile(id: file.id) },
                                    onToggleStar: { store.toggleStar(itemId: file.id) },
                                    onToggleOffline: { store.toggleOffline(fileId: file.id) },
                                    onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                                )
                            }
                        }
                        .padding(.bottom, 132)
                    }
                }
            }

            DriveFloatingActions(
                onScan: {
                    showScan = true
                },
                onCreate: {
                    showCreateOptions = true
                }
            )
            .padding(.trailing, 24)
            .padding(.bottom, 28)
        }
        .navigationTitle(currentFolder?.name ?? "Folder")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: String.self) { nextFolderId in
            FolderBrowserView(store: store, coordinator: coordinator, folderId: nextFolderId)
        }
        .overlay(alignment: .bottom) {
            if let message = store.transientMessage {
                DriveToast(message: message)
                    .padding(.bottom, 20)
            }
        }
        .confirmationDialog("Create new", isPresented: $showCreateOptions, titleVisibility: .visible) {
            Button("Folder") {
                showCreateFolder = true
            }
            Button("CloudDocs") {
                createDocument()
            }
            Button("CloudSheets") {
                createSpreadsheet()
            }
            Button("CloudSlides") {
                createPresentation()
            }
        }
        .sheet(isPresented: $showCreateFolder) {
            CreateFolderSheet(
                folderName: $newFolderName,
                onCancel: {
                    newFolderName = ""
                    showCreateFolder = false
                },
                onCreate: {
                    store.createFolder(name: newFolderName, parentFolderId: folderId)
                    newFolderName = ""
                    showCreateFolder = false
                }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showScan) {
            DriveScanSheet(
                onCancel: { showScan = false },
                onCreate: { preset, name in
                    let resolvedName = name.isEmpty ? preset.suggestedName : name
                    _ = store.createScannedDocument(
                        parentFolderId: folderId,
                        name: resolvedName,
                        body: preset.sampleBody,
                        sizeDescription: preset.suggestedSize
                    )
                    showScan = false
                }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(item: Binding(
            get: { coordinator.detailFileId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.detailFileId = $0?.fileId }
        )) { route in
            NavigationStack {
                FileDetailView(
                    store: store,
                    fileId: route.fileId,
                    onOpen: {
                        if let file = store.file(id: route.fileId) {
                            openFile(file)
                        }
                    },
                    onShare: {
                        if let file = store.file(id: route.fileId) {
                            coordinator.beginShare(file: file)
                            coordinator.detailFileId = nil
                        }
                    }
                )
                .preferredColorScheme(.dark)
            }
        }
        .sheet(item: Binding(
            get: { coordinator.renameTargetId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.renameTargetId = $0?.fileId }
        )) { route in
            RenameItemSheet(
                title: "Rename",
                name: $coordinator.renameValue,
                onCancel: coordinator.resetRename,
                onSave: {
                    store.renameItem(id: route.fileId, newName: coordinator.renameValue)
                    coordinator.resetRename()
                }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(item: Binding(
            get: { coordinator.moveTargetId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.moveTargetId = $0?.fileId }
        )) { route in
            MoveItemSheet(
                destinations: store.availableMoveDestinations(excluding: route.fileId),
                selection: $coordinator.moveSelection,
                onCancel: coordinator.resetMove,
                onMove: {
                    let destination = coordinator.moveSelection.isEmpty ? nil : coordinator.moveSelection
                    store.moveItem(id: route.fileId, toFolderId: destination)
                    coordinator.resetMove()
                }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(item: Binding(
            get: { coordinator.shareFileId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.shareFileId = $0?.fileId }
        )) { route in
            ShareSettingsSheet(
                peopleText: $coordinator.sharePeopleText,
                role: $coordinator.shareRole,
                visibility: $coordinator.shareVisibility,
                contacts: store.contacts,
                linkDescription: shareLinkText(for: route.fileId),
                onCancel: coordinator.resetShare,
                onCopyLink: { copyShareLink(fileId: route.fileId) }
            ) {
                store.updateShareSettings(
                    fileId: route.fileId,
                    peopleNames: coordinator.sharePeopleText,
                    role: coordinator.shareRole,
                    visibility: coordinator.shareVisibility
                )
                coordinator.resetShare()
            }
            .preferredColorScheme(.dark)
        }
    }

    private func titleForSort(_ sort: WorkspaceSortOption) -> String {
        switch sort {
        case .recent:
            return "Date modified"
        case .name:
            return "Name"
        case .type:
            return "Type"
        }
    }

    private func modifiedText(for date: Date) -> String {
        "Modified \(DriveFolderDateFormats.modifiedDate.string(from: date))"
    }

    private func createDocument() {
        let fileId = store.createDocument(parentFolderId: folderId)
        if let file = store.file(id: fileId) {
            openFile(file)
        }
    }

    private func createSpreadsheet() {
        let fileId = store.createSpreadsheet(parentFolderId: folderId)
        if let file = store.file(id: fileId) {
            openFile(file)
        }
    }

    private func createPresentation() {
        let fileId = store.createPresentation(parentFolderId: folderId)
        if let file = store.file(id: fileId) {
            openFile(file)
        }
    }

    private func shareLinkText(for fileId: String) -> String {
        guard let file = store.file(id: fileId) else { return "clouddrive.example" }
        return "clouddrive.example/file/d/\(file.id)/view"
    }

    private func copyShareLink(fileId: String) {
        UIPasteboard.general.string = "https://\(shareLinkText(for: fileId))"
        store.registerShareLinkCopy(fileId: fileId)
    }

    private func openFile(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudDrive", targetApp: file.fileType.title)
        guard let url = URL(string: "\(file.fileType.editorScheme)://open?file=\(file.id)") else {
            return
        }

        UIApplication.shared.open(url) { success in
            if success == false {
                store.activeAlert = AppAlert(
                    id: "handoff_target_unavailable_\(file.id)",
                    title: "Handoff target unavailable",
                    message: "Install and launch the matching editor app to open this file."
                )
            }
        }
    }
}

private enum DriveFolderDateFormats {
    static let modifiedDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter
    }()
}
