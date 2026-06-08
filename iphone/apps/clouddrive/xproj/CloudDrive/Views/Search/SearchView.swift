import SwiftUI
import UIKit

struct SearchView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DriveActionCoordinator

    @State private var query = ""
    @State private var filter: WorkspaceSearchFilter = .all
    @State private var sort: WorkspaceSortOption = .recent

    private var viewModel: DriveSearchViewModel {
        DriveSearchViewModel(store: store, query: query, filter: filter, sort: sort)
    }

    var body: some View {
        searchScreen
    }

    private var searchScreen: some View {
        NavigationStack {
            searchList
                .navigationTitle("Search")
        }
        .sheet(item: detailRouteBinding, content: detailSheet)
        .sheet(item: renameRouteBinding, content: renameSheet)
        .sheet(item: moveRouteBinding, content: moveSheet)
        .sheet(item: shareRouteBinding, content: shareSheet)
    }

    private var searchList: some View {
        List {
            Section {
                TextField("Search Drive", text: $query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier("drive_search_field")
            }

            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(WorkspaceSearchFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("Sort", selection: $sort) {
                    ForEach(WorkspaceSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Results") {
                DriveBrowserListView(
                    store: store,
                    coordinator: coordinator,
                    items: viewModel.results,
                    showPath: true,
                    emptyTitle: query.isEmpty ? "Search Drive" : "No results",
                    emptyMessage: query.isEmpty ? "Search by file name, folder, or content preview text." : "Try a different query or filter.",
                    emptyAccessibilityID: AccessibilityID.emptyState(query.isEmpty ? "search_idle" : "search_no_results"),
                    openFile: openFile
                )
            }
        }
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
        RenameItemSheet(title: "Rename", name: $coordinator.renameValue, onCancel: coordinator.resetRename) {
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

    private func shareLinkText(for fileId: String) -> String {
        "clouddrive.example/file/d/\(fileId)/view"
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
                store.activeAlert = AppAlert(id: "handoff_target_unavailable_\(file.id)", title: "Handoff target unavailable", message: "Launch the matching editor app to open this file.")
            }
        }
    }
}
