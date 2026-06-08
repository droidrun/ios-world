import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DriveActionCoordinator

    @State private var sort: WorkspaceSortOption = .recent
    @State private var showCreateFolder = false
    @State private var newFolderName = ""

    private var viewModel: DriveHomeViewModel {
        DriveHomeViewModel(store: store, folderId: store.currentData.rootFolderId, sort: sort)
    }

    private var offlineFiles: [WorkspaceFile] {
        store.offlineFiles(limit: 3)
    }

    var body: some View {
        homeScreen
    }

    private var homeScreen: some View {
        NavigationStack {
            homeList
        }
        .sheet(isPresented: $showCreateFolder, content: createFolderSheet)
        .sheet(item: detailRouteBinding, content: detailSheet)
        .sheet(item: renameRouteBinding, content: renameSheet)
        .sheet(item: moveRouteBinding, content: moveSheet)
        .sheet(item: shareRouteBinding, content: shareSheet)
    }

    private var homeList: some View {
        List {
            sourceSection
            quickAccessSection
            myDriveSection
            recentFilesSection
            offlineSection
            recentActivitySection
            storageSection
        }
        .navigationTitle("Home")
        .toolbar(content: homeToolbar)
    }

    @ViewBuilder
    private var sourceSection: some View {
        Section {
            SourceModeBannerView(sourceType: store.envelope.selectedSourceType, metadata: store.currentMetadata)
        }
    }

    @ViewBuilder
    private var quickAccessSection: some View {
        Section("Quick access") {
            if viewModel.quickAccessFiles.isEmpty {
                EmptyStateCard(
                    title: "No quick access items",
                    message: "Star or open a file to surface it here.",
                    systemImage: "sparkles",
                    accessibilityIdentifier: AccessibilityID.emptyState("quick_access")
                )
            } else {
                ForEach(viewModel.quickAccessFiles) { file in
                    quickAccessCard(for: file)
                        .accessibilityIdentifier(AccessibilityID.recentRow(file))
                }
            }
        }
    }

    @ViewBuilder
    private var myDriveSection: some View {
        Section("My Drive") {
            DriveBrowserListView(
                store: store,
                coordinator: coordinator,
                items: viewModel.items,
                showPath: false,
                emptyTitle: "Empty folder",
                emptyMessage: "Create a folder or add a file to get started.",
                emptyAccessibilityID: AccessibilityID.emptyState("home_folder"),
                openFile: openFile
            )
        }
    }

    @ViewBuilder
    private var recentFilesSection: some View {
        Section("Recent files") {
            if viewModel.recentFiles.isEmpty {
                EmptyStateCard(
                    title: "No recent files",
                    message: "Open a file to see it appear here.",
                    systemImage: "clock.arrow.circlepath",
                    accessibilityIdentifier: AccessibilityID.emptyState("recent_files_empty")
                )
            } else {
                ForEach(viewModel.recentFiles) { file in
                    standardFileRow(for: file)
                        .accessibilityIdentifier(AccessibilityID.recentRow(file))
                }
            }
        }
    }

    @ViewBuilder
    private var offlineSection: some View {
        Section("Offline") {
            if offlineFiles.isEmpty {
                EmptyStateCard(
                    title: "Nothing available offline",
                    message: "Files you save for offline access will appear here.",
                    systemImage: "wifi.slash",
                    accessibilityIdentifier: AccessibilityID.emptyState("offline_empty")
                )
            } else {
                ForEach(offlineFiles) { file in
                    offlineFileRow(for: file)
                }
            }
        }
    }

    @ViewBuilder
    private var recentActivitySection: some View {
        Section("Recent activity") {
            ForEach(viewModel.recentActivity) { activity in
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.summary)
                        .font(.subheadline.weight(.medium))
                    Text(AppFormatters.relativeDate.localizedString(for: activity.createdAt, relativeTo: Date()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier(AccessibilityID.activityRow(activity))
            }
        }
    }

    @ViewBuilder
    private var storageSection: some View {
        Section("Storage") {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppFormatters.storageText(usedGB: store.profile.storageUsedGB, limitGB: store.profile.storageLimitGB))
                    .font(.subheadline.weight(.semibold))
                ProgressView(value: store.profile.storageUsedGB / store.profile.storageLimitGB)
                Text("Shared storage mode: \(store.storageModeLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
    }

    @ToolbarContentBuilder
    private func homeToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(WorkspaceSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
            .accessibilityIdentifier("drive_sort_filter_control")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showCreateFolder = true
            } label: {
                Image(systemName: "folder.badge.plus")
            }
            .accessibilityIdentifier("drive_create_folder_button")
        }
    }

    private func createFolderSheet() -> some View {
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
    }

    private var detailRouteBinding: Binding<EditorRoute?> {
        Binding(
            get: { coordinator.detailFileId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.detailFileId = $0?.fileId }
        )
    }

    private var renameRouteBinding: Binding<EditorRoute?> {
        Binding(
            get: { coordinator.renameTargetId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.renameTargetId = $0?.fileId }
        )
    }

    private var moveRouteBinding: Binding<EditorRoute?> {
        Binding(
            get: { coordinator.moveTargetId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.moveTargetId = $0?.fileId }
        )
    }

    private var shareRouteBinding: Binding<EditorRoute?> {
        Binding(
            get: { coordinator.shareFileId.map(EditorRoute.init(fileId:)) },
            set: { coordinator.shareFileId = $0?.fileId }
        )
    }

    private func detailSheet(route: EditorRoute) -> some View {
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
        }
    }

    private func renameSheet(route: EditorRoute) -> some View {
        RenameItemSheet(
            title: "Rename",
            name: $coordinator.renameValue,
            onCancel: coordinator.resetRename
        ) {
            store.renameItem(id: route.fileId, newName: coordinator.renameValue)
            coordinator.resetRename()
        }
    }

    private func moveSheet(route: EditorRoute) -> some View {
        MoveItemSheet(
            destinations: store.availableMoveDestinations(excluding: route.fileId),
            selection: $coordinator.moveSelection,
            onCancel: coordinator.resetMove
        ) {
            let destination = coordinator.moveSelection.isEmpty ? nil : coordinator.moveSelection
            store.moveItem(id: route.fileId, toFolderId: destination)
            coordinator.resetMove()
        }
    }

    private func shareSheet(route: EditorRoute) -> some View {
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
    }

    private func quickAccessCard(for file: WorkspaceFile) -> some View {
        Button {
            openFile(file)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Label(file.name, systemImage: file.fileType.systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(store.contentPreview(for: file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func standardFileRow(for file: WorkspaceFile) -> some View {
        DriveFileRowView(
            file: file,
            preview: store.contentPreview(for: file),
            onOpen: { openFile(file) },
            onDetails: { coordinator.detailFileId = file.id },
            onRename: { coordinator.beginRename(itemId: file.id, currentName: file.name) },
            onMove: { coordinator.beginMove(itemId: file.id, currentParentId: file.parentFolderId) },
            onShare: { coordinator.beginShare(file: file) },
            onDuplicate: { _ = store.duplicateFile(id: file.id) },
            onToggleStar: { store.toggleStar(itemId: file.id) },
            onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
        )
    }

    private func offlineFileRow(for file: WorkspaceFile) -> some View {
        DriveFileRowView(
            file: file,
            preview: store.contentPreview(for: file),
            isOffline: true,
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

    private func shareLinkText(for fileId: String) -> String {
        "clouddrive.example/file/d/\(fileId)/view"
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
