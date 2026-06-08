import SwiftUI
import UIKit

private enum DriveShellTab: String, Hashable, CaseIterable {
    case home
    case starred
    case shared
    case files

    var title: String {
        switch self {
        case .home: return "Home"
        case .starred: return "Starred"
        case .shared: return "Shared"
        case .files: return "Files"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .starred: return "star"
        case .shared: return "person.2"
        case .files: return "folder"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home: return "tab_drive_home"
        case .starred: return "tab_drive_starred"
        case .shared: return "tab_drive_shared"
        case .files: return "tab_drive_files"
        }
    }
}

private enum DriveFilesSection: Int {
    case myDrive
    case sharedDrives
}

private enum DriveSearchPeopleFilter: String, CaseIterable, Identifiable {
    case everyone = "All people"
    case sharedWithMe = "Shared with me"
    case ownedByMe = "Owned by me"

    var id: String { rawValue }
}

private struct FolderRoute: Identifiable {
    let id: String
}

struct RootTabView: View {
    @ObservedObject var store: WorkspaceStore
    @StateObject private var coordinator = DriveActionCoordinator()

    @SceneStorage("drive_selected_tab") private var selectedTabRawValue = DriveShellTab.files.rawValue

    @State private var filesSection: DriveFilesSection = .myDrive
    @State private var showSearch = false
    @State private var showDrawer = false
    @State private var showTrash = false
    @State private var showSettings = false
    @State private var showUploads = false
    @State private var showOffline = false
    @State private var showSpam = false
    @State private var showHelp = false
    @State private var showScan = false
    @State private var showCreateFolder = false
    @State private var showCreateOptions = false
    @State private var newFolderName = ""
    @State private var activeFolderId: String?

    @State private var filesSort: WorkspaceSortOption = .recent
    @State private var filesAscending = false
    @State private var filesGridLayout = false
    @State private var starredSort: WorkspaceSortOption = .name
    @State private var starredAscending = true
    @State private var starredGridLayout = false
    @State private var sharedSort: WorkspaceSortOption = .recent
    @State private var sharedAscending = false
    @State private var sharedGridLayout = false

    @State private var searchQuery = ""
    @State private var searchTypeFilter: WorkspaceSearchFilter = .all
    @State private var searchPeopleFilter: DriveSearchPeopleFilter = .everyone
    @State private var searchSort: WorkspaceSortOption = .recent

    private let browserGridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var selectedTab: DriveShellTab {
        get { DriveShellTab(rawValue: selectedTabRawValue) ?? .files }
        set { selectedTabRawValue = newValue.rawValue }
    }

    private var profileInitial: String {
        store.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() } ?? "D"
    }

    private var myDriveFolders: [WorkspaceFolder] {
        sortFolders(
            store.folders(in: store.currentData.rootFolderId),
            by: filesSort,
            ascending: filesAscending
        )
    }

    private var sharedDriveFolders: [WorkspaceFolder] {
        sortFolders(
            store.sharedDriveFolders(),
            by: filesSort,
            ascending: filesAscending
        )
    }

    private var starredFiles: [WorkspaceFile] {
        sortFiles(
            store.currentData.files.filter { $0.starred && !$0.trashed },
            by: starredSort,
            ascending: starredAscending
        )
    }

    private var sharedFiles: [WorkspaceFile] {
        sortFiles(
            store.currentData.files.filter { $0.shared && !$0.trashed },
            by: sharedSort,
            ascending: sharedAscending
        )
    }

    private var recentFiles: [WorkspaceFile] {
        store.recentFiles(limit: 6)
    }

    private var quickAccessFiles: [WorkspaceFile] {
        store.quickAccessFiles(limit: 4)
    }

    private var suggestedFiles: [WorkspaceFile] {
        store.suggestedFiles(limit: 4)
    }

    private var filteredSearchResults: [BrowserItem] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return [] }

        return store.search(query: trimmed, filter: searchTypeFilter, sort: searchSort)
            .filter { item in
                switch searchPeopleFilter {
                case .everyone:
                    return true
                case .sharedWithMe:
                    switch item {
                    case .folder(let folder):
                        return folder.shared
                    case .file(let file):
                        return file.shared || file.permissions.count > 1
                    }
                case .ownedByMe:
                    switch item {
                    case .folder(let folder):
                        return folder.ownerName == store.profile.displayName
                    case .file(let file):
                        return file.ownerName == store.profile.displayName
                    }
                }
            }
    }

    var body: some View {
        GeometryReader { geometry in
            let drawerWidth = min(geometry.size.width * 0.82, 360)

            ZStack(alignment: .bottom) {
                backgroundView

                contentShell()
                    .offset(x: showDrawer ? drawerWidth * 0.52 : 0)
                    .scaleEffect(showDrawer ? 0.98 : 1.0, anchor: .center)
                    .disabled(showSearch || showDrawer)
                    .animation(.spring(response: 0.30, dampingFraction: 0.88), value: showDrawer)

                if showDrawer {
                    drawerOverlay(drawerWidth: drawerWidth)
                        .transition(.opacity)
                }

                if showSearch {
                    DriveSearchOverlay(
                        query: $searchQuery,
                        typeFilter: $searchTypeFilter,
                        peopleFilter: $searchPeopleFilter,
                        sort: $searchSort,
                        results: filteredSearchResults,
                        closeAction: { withAnimation(.easeInOut(duration: 0.2)) { showSearch = false } },
                        onOpenFolder: { folder in
                            showSearch = false
                            activeFolderId = folder.id
                        },
                        onOpenFile: openFile,
                        onDetails: { file in coordinator.detailFileId = file.id },
                        onRename: { file in coordinator.beginRename(itemId: file.id, currentName: file.name) },
                        onMove: { file in coordinator.beginMove(itemId: file.id, currentParentId: file.parentFolderId) },
                        onShare: { file in coordinator.beginShare(file: file) },
                        onDuplicate: { file in _ = store.duplicateFile(id: file.id) },
                        onToggleStar: { file in store.toggleStar(itemId: file.id) },
                        onTrashOrRestore: { file in
                            file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id)
                        },
                        onFolderRename: { folder in coordinator.beginRename(itemId: folder.id, currentName: folder.name) },
                        onFolderMove: { folder in coordinator.beginMove(itemId: folder.id, currentParentId: folder.parentFolderId) },
                        onFolderToggleStar: { folder in store.toggleStar(itemId: folder.id) },
                        onFolderTrashOrRestore: { folder in
                            folder.trashed ? store.restoreItem(id: folder.id) : store.trashItem(id: folder.id)
                        },
                        pathText: pathText(for:)
                    )
                    .transition(.move(edge: .trailing))
                }
            }
            .preferredColorScheme(.dark)
            .alert(item: $store.activeAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK")) { store.dismissAlert() }
                )
            }
            .overlay(alignment: .bottom) {
                if let message = store.transientMessage, showSearch == false {
                    DriveToast(message: message)
                        .padding(.bottom, 108)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .confirmationDialog("Create new", isPresented: $showCreateOptions, titleVisibility: .visible) {
                Button("Folder") {
                    showCreateFolder = true
                }
                Button("CloudDocs") {
                    createDocument(in: store.currentData.rootFolderId)
                }
                Button("CloudSheets") {
                    createSpreadsheet(in: store.currentData.rootFolderId)
                }
                Button("CloudSlides") {
                    createPresentation(in: store.currentData.rootFolderId)
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
                        store.createFolder(name: newFolderName, parentFolderId: store.currentData.rootFolderId)
                        newFolderName = ""
                        showCreateFolder = false
                    }
                )
                .preferredColorScheme(.dark)
            }
            .sheet(item: Binding(
                get: { activeFolderId.map(FolderRoute.init(id:)) },
                set: { activeFolderId = $0?.id }
            )) { route in
                NavigationStack {
                    FolderBrowserView(store: store, coordinator: coordinator, folderId: route.id)
                        .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showTrash) {
                NavigationStack {
                    TrashView(store: store, coordinator: coordinator)
                        .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    MoreView(store: store, coordinator: coordinator)
                        .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showUploads) {
                NavigationStack {
                    DriveUploadsView(
                        store: store,
                        parentFolderId: store.currentData.rootFolderId,
                        openFile: openFile
                    )
                    .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showOffline) {
                NavigationStack {
                    DriveOfflineView(store: store, openFile: openFile)
                        .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showSpam) {
                NavigationStack {
                    DriveSpamView()
                        .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showHelp) {
                NavigationStack {
                    DriveHelpFeedbackView(store: store)
                        .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showScan) {
                DriveScanSheet(
                    onCancel: { showScan = false },
                    onCreate: { preset, name in
                        createScan(in: store.currentData.rootFolderId, preset: preset, name: name)
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
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [DrivePalette.backgroundTop, DrivePalette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.035))
                .frame(width: 360, height: 360)
                .blur(radius: 40)
                .offset(x: 150, y: -280)

            Circle()
                .fill(DrivePalette.accent.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 54)
                .offset(x: -170, y: 420)
        }
    }

    private func contentShell() -> some View {
        VStack(spacing: 0) {
            activeScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom) {
            if showSearch == false {
                DriveShellTabBar(selection: selectedTab) { tab in
                    selectedTabRawValue = tab.rawValue
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private var activeScreen: some View {
        switch selectedTab {
        case .home:
            shellScreen {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        DriveSectionHeading(title: "Quick Access")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(quickAccessFiles) { file in
                                    DriveQuickAccessCard(
                                        title: file.name,
                                        subtitle: store.contentPreview(for: file),
                                        systemImage: file.fileType.systemImage,
                                        tint: tint(for: file.fileType),
                                        action: { openFile(file) }
                                    )
                                    .accessibilityIdentifier(AccessibilityID.recentRow(file))
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        homeSectionCard(title: "Recent") {
                            ForEach(Array(recentFiles.prefix(4))) { file in
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

                        homeSectionCard(title: "Suggested") {
                            ForEach(suggestedFiles) { file in
                                DriveStandardFileRow(
                                    file: file,
                                    subtitle: pathText(for: file),
                                    showStarMarker: false,
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

                        VStack(alignment: .leading, spacing: 12) {
                            DriveSectionHeading(title: "Storage")
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(format: "%.2f GB of %.0f GB used", store.profile.storageUsedGB, store.profile.storageLimitGB))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(DrivePalette.primaryText)

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.10))
                                        Capsule()
                                            .fill(DrivePalette.storageBar)
                                            .frame(width: geometry.size.width * min(store.profile.storageUsedGB / store.profile.storageLimitGB, 1))
                                    }
                                }
                                .frame(height: 10)

                                Text("\(store.offlineFiles(limit: 99).count) files available offline")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(DrivePalette.secondaryText)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 132)
                }
            }

        case .starred:
            shellScreen {
                listScreen(showFloatingActions: true) {
                    DriveSortHeader(
                        title: titleForStarredSort(starredSort),
                        ascending: starredAscending,
                        isGridLayout: starredGridLayout,
                        sortOptions: [.name, .recent, .type],
                        selectSort: { starredSort = $0 },
                        sortAction: { starredAscending.toggle() },
                        layoutAction: { starredGridLayout.toggle() }
                    )

                    if starredFiles.isEmpty {
                        EmptyStateCard(
                            title: "No starred files",
                            message: "Starred items will appear here.",
                            systemImage: "star",
                            accessibilityIdentifier: AccessibilityID.emptyState("no_starred_files")
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    } else if starredGridLayout {
                        LazyVGrid(columns: browserGridColumns, spacing: 16) {
                            ForEach(starredFiles) { file in
                                DriveFileGridCard(
                                    file: file,
                                    subtitle: modifiedText(for: file.updatedAt),
                                    showOwner: false,
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
                                .accessibilityIdentifier(AccessibilityID.starredRow(file))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 132)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(starredFiles) { file in
                                DriveStandardFileRow(
                                    file: file,
                                    subtitle: modifiedText(for: file.updatedAt),
                                    showStarMarker: true,
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
                                .accessibilityIdentifier(AccessibilityID.starredRow(file))
                            }
                        }
                        .padding(.bottom, 132)
                    }
                }
            }

        case .shared:
            shellScreen {
                listScreen(showFloatingActions: true) {
                    DriveSortHeader(
                        title: titleForSharedSort(sharedSort),
                        ascending: sharedAscending,
                        isGridLayout: sharedGridLayout,
                        sortOptions: [.recent, .name, .type],
                        selectSort: { sharedSort = $0 },
                        sortAction: { sharedAscending.toggle() },
                        layoutAction: { sharedGridLayout.toggle() }
                    )

                    if sharedFiles.isEmpty {
                        EmptyStateCard(
                            title: "No shared files",
                            message: "Shared items will appear here when access is granted locally.",
                            systemImage: "person.2",
                            accessibilityIdentifier: AccessibilityID.emptyState("no_shared_files")
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    } else if sharedGridLayout {
                        LazyVGrid(columns: browserGridColumns, spacing: 16) {
                            ForEach(sharedFiles) { file in
                                DriveFileGridCard(
                                    file: file,
                                    subtitle: "\(file.ownerName) • \(sharedDateText(for: file.updatedAt))",
                                    showOwner: true,
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
                            ForEach(sharedFiles) { file in
                                DriveSharedFileRow(
                                    file: file,
                                    subtitle: "\(file.ownerName) • \(sharedDateText(for: file.updatedAt))",
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

        case .files:
            shellScreen {
                VStack(spacing: 0) {
                    DriveTopTabs(
                        titles: ["My Drive", "Shared drives"],
                        selectedIndex: filesSection == .myDrive ? 0 : 1,
                        onSelect: { index in
                            filesSection = index == 0 ? .myDrive : .sharedDrives
                        }
                    )
                    .padding(.horizontal, 28)
                    .padding(.bottom, 6)

                    Rectangle()
                        .fill(DrivePalette.divider)
                        .frame(height: 1)

                    if filesSection == .myDrive {
                        listScreen(showFloatingActions: true, addTopDivider: false) {
                            DriveSortHeader(
                                title: titleForFilesSort(filesSort),
                                ascending: filesAscending,
                                isGridLayout: filesGridLayout,
                                sortOptions: [.recent, .name],
                                selectSort: { filesSort = $0 },
                                sortAction: { filesAscending.toggle() },
                                layoutAction: { filesGridLayout.toggle() }
                            )

                            if filesGridLayout {
                                LazyVGrid(columns: browserGridColumns, spacing: 16) {
                                    ForEach(myDriveFolders) { folder in
                                        DriveFolderGridCard(
                                            folder: folder,
                                            subtitle: modifiedText(for: folder.updatedAt),
                                            onOpen: { activeFolderId = folder.id },
                                            onRename: { coordinator.beginRename(itemId: folder.id, currentName: folder.name) },
                                            onMove: { coordinator.beginMove(itemId: folder.id, currentParentId: folder.parentFolderId) },
                                            onToggleStar: { store.toggleStar(itemId: folder.id) },
                                            onTrashOrRestore: { folder.trashed ? store.restoreItem(id: folder.id) : store.trashItem(id: folder.id) }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                .padding(.bottom, 132)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(myDriveFolders) { folder in
                                        DriveMyDriveFolderRow(
                                            folder: folder,
                                            subtitle: modifiedText(for: folder.updatedAt),
                                            onOpen: { activeFolderId = folder.id },
                                            onRename: { coordinator.beginRename(itemId: folder.id, currentName: folder.name) },
                                            onMove: { coordinator.beginMove(itemId: folder.id, currentParentId: folder.parentFolderId) },
                                            onToggleStar: { store.toggleStar(itemId: folder.id) },
                                            onTrashOrRestore: { folder.trashed ? store.restoreItem(id: folder.id) : store.trashItem(id: folder.id) }
                                        )
                                    }
                                }
                                .padding(.bottom, 132)
                            }
                        }
                    } else {
                        listScreen(showFloatingActions: false, addTopDivider: false) {
                            DriveSortHeader(
                                title: titleForFilesSort(filesSort),
                                ascending: filesAscending,
                                isGridLayout: filesGridLayout,
                                sortOptions: [.recent, .name],
                                selectSort: { filesSort = $0 },
                                sortAction: { filesAscending.toggle() },
                                layoutAction: { filesGridLayout.toggle() }
                            )

                            if sharedDriveFolders.isEmpty {
                                DriveSharedDrivesEmptyState()
                                    .padding(.bottom, 132)
                            } else if filesGridLayout {
                                LazyVGrid(columns: browserGridColumns, spacing: 16) {
                                    ForEach(sharedDriveFolders) { folder in
                                        DriveFolderGridCard(
                                            folder: folder,
                                            subtitle: pathText(for: folder),
                                            onOpen: { activeFolderId = folder.id },
                                            onRename: { coordinator.beginRename(itemId: folder.id, currentName: folder.name) },
                                            onMove: { coordinator.beginMove(itemId: folder.id, currentParentId: folder.parentFolderId) },
                                            onToggleStar: { store.toggleStar(itemId: folder.id) },
                                            onTrashOrRestore: { folder.trashed ? store.restoreItem(id: folder.id) : store.trashItem(id: folder.id) }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                .padding(.bottom, 132)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(sharedDriveFolders) { folder in
                                        DriveMyDriveFolderRow(
                                            folder: folder,
                                            subtitle: folder.ownerName,
                                            onOpen: { activeFolderId = folder.id },
                                            onRename: { coordinator.beginRename(itemId: folder.id, currentName: folder.name) },
                                            onMove: { coordinator.beginMove(itemId: folder.id, currentParentId: folder.parentFolderId) },
                                            onToggleStar: { store.toggleStar(itemId: folder.id) },
                                            onTrashOrRestore: { folder.trashed ? store.restoreItem(id: folder.id) : store.trashItem(id: folder.id) }
                                        )
                                    }
                                }
                                .padding(.bottom, 132)
                            }
                        }
                    }
                }
            }
        }
    }

    private func shellScreen<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            DriveSearchPill(
                title: "Search in Drive",
                profileInitial: profileInitial,
                onMenu: { withAnimation(.easeInOut(duration: 0.2)) { showDrawer = true } },
                onSearch: {
                    showDrawer = false
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearch = true
                    }
                }
            )
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 16)

            content()
        }
    }

    private func listScreen<Content: View>(showFloatingActions: Bool, addTopDivider: Bool = true, @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if addTopDivider {
                        Rectangle()
                            .fill(DrivePalette.divider)
                            .frame(height: 1)
                    }

                    content()
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(DrivePalette.listSurface)

            if showFloatingActions {
                DriveFloatingActions(
                    onScan: {
                        showScan = true
                    },
                    onCreate: {
                        showCreateOptions = true
                    }
                )
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func homeSectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            DriveSectionHeading(title: title)

            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    private func drawerOverlay(drawerWidth: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDrawer = false
                    }
                }

            DriveDrawerPanel(
                storageUsedGB: store.profile.storageUsedGB,
                storageLimitGB: store.profile.storageLimitGB,
                items: drawerItems
            )
            .frame(width: drawerWidth)
            .ignoresSafeArea(edges: .vertical)
            .transition(.move(edge: .leading))
        }
    }

    private var drawerItems: [DriveDrawerItem] {
        [
            DriveDrawerItem(id: "recent", title: "Recent", systemImage: "clock") {
                selectedTabRawValue = DriveShellTab.home.rawValue
                showDrawer = false
            },
            DriveDrawerItem(id: "workspaces", title: "Workspaces", systemImage: "circle.grid.2x2") {
                selectedTabRawValue = DriveShellTab.files.rawValue
                filesSection = .sharedDrives
                showDrawer = false
            },
            DriveDrawerItem(id: "uploads", title: "Uploads", systemImage: "arrow.up.to.line") {
                showDrawer = false
                showUploads = true
            },
            DriveDrawerItem(id: "offline", title: "Offline", systemImage: "checkmark.circle") {
                showDrawer = false
                showOffline = true
            },
            DriveDrawerItem(id: "spam", title: "Spam", systemImage: "exclamationmark.octagon") {
                showDrawer = false
                showSpam = true
            },
            DriveDrawerItem(id: "trash", title: "Trash", systemImage: "trash") {
                showDrawer = false
                showTrash = true
            },
            DriveDrawerItem(id: "settings", title: "Settings", systemImage: "gearshape") {
                showDrawer = false
                showSettings = true
            },
            DriveDrawerItem(id: "help", title: "Help & Feedback", systemImage: "questionmark.circle") {
                showDrawer = false
                showHelp = true
            }
        ]
    }

    private func pathText(for file: WorkspaceFile) -> String {
        store.pathString(for: file)
    }

    private func pathText(for folder: WorkspaceFolder) -> String {
        let parents = store.pathFolders(for: folder.parentFolderId).map(\.name)
        if parents.isEmpty {
            return folder.parentFolderId == nil && folder.id != store.currentData.rootFolderId ? "Shared drive" : "My Drive"
        }
        return parents.joined(separator: " / ")
    }

    private func modifiedText(for date: Date) -> String {
        "Modified \(DriveDateFormats.modifiedDate.string(from: date))"
    }

    private func titleForFilesSort(_ sort: WorkspaceSortOption) -> String {
        switch sort {
        case .recent:
            return "Date modified"
        case .name:
            return "Name"
        case .type:
            return "Type"
        }
    }

    private func titleForStarredSort(_ sort: WorkspaceSortOption) -> String {
        switch sort {
        case .recent:
            return "Date modified"
        case .name:
            return "Name"
        case .type:
            return "Type"
        }
    }

    private func titleForSharedSort(_ sort: WorkspaceSortOption) -> String {
        switch sort {
        case .recent:
            return "Date shared"
        case .name:
            return "Name"
        case .type:
            return "Type"
        }
    }

    private func sharedDateText(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return DriveDateFormats.weekdayTime.string(from: date)
        }
        return DriveDateFormats.monthDay.string(from: date)
    }

    private func tint(for fileType: WorkspaceFileType) -> Color {
        switch fileType {
        case .document:
            return Color(red: 0.55, green: 0.69, blue: 0.98)
        case .spreadsheet:
            return Color(red: 0.52, green: 0.82, blue: 0.59)
        case .presentation:
            return Color(red: 0.92, green: 0.53, blue: 0.50)
        }
    }

    private func sortFiles(_ files: [WorkspaceFile], by sort: WorkspaceSortOption, ascending: Bool) -> [WorkspaceFile] {
        let sorted: [WorkspaceFile]

        switch sort {
        case .recent:
            sorted = files.sorted { $0.updatedAt < $1.updatedAt }
        case .name:
            sorted = files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .type:
            sorted = files.sorted {
                if $0.fileType == $1.fileType {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.fileType.rawValue < $1.fileType.rawValue
            }
        }

        return ascending ? sorted : Array(sorted.reversed())
    }

    private func sortFolders(_ folders: [WorkspaceFolder], by sort: WorkspaceSortOption, ascending: Bool) -> [WorkspaceFolder] {
        let sorted: [WorkspaceFolder]

        switch sort {
        case .recent:
            sorted = folders.sorted { $0.updatedAt < $1.updatedAt }
        case .name, .type:
            sorted = folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return ascending ? sorted : Array(sorted.reversed())
    }

    private func createDocument(in parentFolderId: String?) {
        let fileId = store.createDocument(parentFolderId: parentFolderId, name: "Untitled document")
        if let file = store.file(id: fileId) {
            openFile(file)
        }
    }

    private func createSpreadsheet(in parentFolderId: String?) {
        let fileId = store.createSpreadsheet(parentFolderId: parentFolderId, name: "Untitled spreadsheet")
        if let file = store.file(id: fileId) {
            openFile(file)
        }
    }

    private func createPresentation(in parentFolderId: String?) {
        let fileId = store.createPresentation(parentFolderId: parentFolderId, name: "Untitled presentation")
        if let file = store.file(id: fileId) {
            openFile(file)
        }
    }

    private func createScan(in parentFolderId: String?, preset: DriveScanPreset, name: String) {
        let resolvedName = name.isEmpty ? preset.suggestedName : name
        _ = store.createScannedDocument(
            parentFolderId: parentFolderId,
            name: resolvedName,
            body: preset.sampleBody,
            sizeDescription: preset.suggestedSize
        )
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
        guard let url = URL(string: "\(file.fileType.editorScheme)://open?file=\(file.id)") else { return }

        UIApplication.shared.open(url) { success in
            if success == false {
                store.activeAlert = AppAlert(
                    id: "handoff_target_unavailable_\(file.id)",
                    title: "Handoff target unavailable",
                    message: "Launch the matching editor app to open this file."
                )
            }
        }
    }
}

private struct DriveDateFormats {
    static let modifiedDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter
    }()

    static let weekdayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mm a"
        return formatter
    }()

    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

private struct DriveShellTabBar: View {
    let selection: DriveShellTab
    let onSelect: (DriveShellTab) -> Void

    var body: some View {
        HStack {
            ForEach(DriveShellTab.allCases, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(selection == tab ? DrivePalette.accent : .clear)
                                .frame(width: 78, height: 48)

                            Image(systemName: tab.systemImage)
                                .font(.system(size: 22, weight: selection == tab ? .semibold : .regular))
                                .foregroundStyle(selection == tab ? DrivePalette.accentText : DrivePalette.primaryText.opacity(0.88))
                        }

                        Text(tab.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selection == tab ? DrivePalette.primaryText : DrivePalette.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(tab.accessibilityIdentifier)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(DrivePalette.chrome.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

private struct DriveSearchOverlay: View {
    @Binding var query: String
    @Binding var typeFilter: WorkspaceSearchFilter
    @Binding var peopleFilter: DriveSearchPeopleFilter
    @Binding var sort: WorkspaceSortOption

    let results: [BrowserItem]
    let closeAction: () -> Void
    let onOpenFolder: (WorkspaceFolder) -> Void
    let onOpenFile: (WorkspaceFile) -> Void
    let onDetails: (WorkspaceFile) -> Void
    let onRename: (WorkspaceFile) -> Void
    let onMove: (WorkspaceFile) -> Void
    let onShare: (WorkspaceFile) -> Void
    let onDuplicate: (WorkspaceFile) -> Void
    let onToggleStar: (WorkspaceFile) -> Void
    let onTrashOrRestore: (WorkspaceFile) -> Void
    let onFolderRename: (WorkspaceFolder) -> Void
    let onFolderMove: (WorkspaceFolder) -> Void
    let onFolderToggleStar: (WorkspaceFolder) -> Void
    let onFolderTrashOrRestore: (WorkspaceFolder) -> Void
    let pathText: (WorkspaceFile) -> String

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DrivePalette.backgroundTop, DrivePalette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    Button(action: closeAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(DrivePalette.primaryText)
                    }
                    .buttonStyle(.plain)

                    TextField("", text: $query, prompt: Text("Search in Drive").foregroundStyle(DrivePalette.secondaryText))
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(DrivePalette.primaryText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                        .focused($isFieldFocused)
                        .accessibilityIdentifier("drive_search_field")
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Menu {
                            Button("All") { typeFilter = .all }
                            Button("Folders") { typeFilter = .folders }
                            Button("Docs") { typeFilter = .documents }
                            Button("Sheets") { typeFilter = .spreadsheets }
                            Button("Slides") { typeFilter = .presentations }
                        } label: {
                            DriveFilterChip(label: "Type", value: typeFilterLabel)
                        }

                        Menu {
                            ForEach(DriveSearchPeopleFilter.allCases) { option in
                                Button(option.rawValue) { peopleFilter = option }
                            }
                        } label: {
                            DriveFilterChip(label: "People", value: peopleFilter.rawValue)
                        }

                        Menu {
                            Button("Modified") { sort = .recent }
                            Button("Name") { sort = .name }
                            Button("Type") { sort = .type }
                        } label: {
                            DriveFilterChip(label: "Modified", value: sortLabel)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 22)
                }

                if results.isEmpty {
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(results, id: \.id) { item in
                                switch item {
                                case .folder(let folder):
                                    DriveMyDriveFolderRow(
                                        folder: folder,
                                        subtitle: folder.shared ? "Shared folder" : "Folder",
                                        onOpen: { onOpenFolder(folder) },
                                        onRename: { onFolderRename(folder) },
                                        onMove: { onFolderMove(folder) },
                                        onToggleStar: { onFolderToggleStar(folder) },
                                        onTrashOrRestore: { onFolderTrashOrRestore(folder) }
                                    )
                                    .accessibilityIdentifier(AccessibilityID.searchResultRow(item))

                                case .file(let file):
                                    DriveStandardFileRow(
                                        file: file,
                                        subtitle: pathText(file),
                                        showStarMarker: false,
                                        showSharedMarker: file.shared,
                                        onOpen: { onOpenFile(file) },
                                        onDetails: { onDetails(file) },
                                        onRename: { onRename(file) },
                                        onMove: { onMove(file) },
                                        onShare: { onShare(file) },
                                        onDuplicate: { onDuplicate(file) },
                                        onToggleStar: { onToggleStar(file) },
                                        onTrashOrRestore: { onTrashOrRestore(file) }
                                    )
                                    .accessibilityIdentifier(AccessibilityID.searchResultRow(item))
                                }
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 96)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isFieldFocused = true
            }
        }
    }

    private var typeFilterLabel: String {
        switch typeFilter {
        case .all: return "All"
        case .folders: return "Folders"
        case .documents: return "Docs"
        case .spreadsheets: return "Sheets"
        case .presentations: return "Slides"
        default: return "All"
        }
    }

    private var sortLabel: String {
        switch sort {
        case .recent: return "Recent"
        case .name: return "Name"
        case .type: return "Type"
        }
    }
}

private struct DriveFilterChip: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DrivePalette.primaryText.opacity(0.88))

            if value != "All" && value != "All people" && value != "Recent" {
                Text(value)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DrivePalette.secondaryText)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DrivePalette.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(DrivePalette.chipBorder, lineWidth: 1.5)
        )
    }
}
