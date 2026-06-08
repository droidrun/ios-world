import SwiftUI

private enum DocsDrawerSelection: String, CaseIterable, Identifiable {
    case recent
    case starred
    case sharedWithMe
    case offline
    case spam
    case trash
    case googleDrive
    case settings
    case help

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent: return "Recent"
        case .starred: return "Starred"
        case .sharedWithMe: return "Shared with me"
        case .offline: return "Offline"
        case .spam: return "Spam"
        case .trash: return "Trash"
        case .googleDrive: return "CloudDrive"
        case .settings: return "Settings"
        case .help: return "Help & feedback"
        }
    }

    var systemImage: String {
        switch self {
        case .recent: return "clock"
        case .starred: return "star.fill"
        case .sharedWithMe: return "person.2.fill"
        case .offline: return "checkmark.circle.fill"
        case .spam: return "exclamationmark.octagon"
        case .trash: return "trash.fill"
        case .googleDrive: return "externaldrive.fill"
        case .settings: return "gearshape.fill"
        case .help: return "questionmark.circle.fill"
        }
    }

    var isFilter: Bool {
        switch self {
        case .settings, .help:
            return false
        default:
            return true
        }
    }

    var sectionTitle: String {
        switch self {
        case .recent, .googleDrive:
            return "Last modified by me"
        case .starred:
            return "Starred"
        case .sharedWithMe:
            return "Shared with me"
        case .offline:
            return "Available offline"
        case .spam:
            return "Spam"
        case .trash:
            return "Trash"
        case .settings:
            return "Settings"
        case .help:
            return "Help & feedback"
        }
    }

    var emptyTitle: String {
        switch self {
        case .spam:
            return "Nothing in spam"
        case .trash:
            return "Trash is empty"
        case .offline:
            return "No offline documents"
        default:
            return "No documents"
        }
    }

    var emptyMessage: String {
        switch self {
        case .spam:
            return "Spam items will appear here when they are flagged."
        case .trash:
            return "Deleted documents will appear here."
        case .offline:
            return "No offline files are available in this view."
        default:
            return "This section does not have any matching documents right now."
        }
    }
}

private enum DocsHomeModal: String, Identifiable {
    case search
    case settings
    case help

    var id: String { rawValue }
}

struct HomeView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DocumentActionCoordinator

    @State private var drawerSelection: DocsDrawerSelection = .recent
    @State private var isDrawerPresented = false
    @State private var isProfileCardPresented = false
    @State private var showsListLayout = false
    @State private var activeModal: DocsHomeModal?
    @State private var isCreateFolderPresented = false
    @State private var createFolderName = ""

    private var profileLetter: String {
        String(store.profile.displayName.first ?? "L")
    }

    private var filteredDocuments: [WorkspaceFile] {
        let allDocuments = store.currentData.files
            .filter { $0.fileType == .document }
            .sorted { $0.updatedAt > $1.updatedAt }

        switch drawerSelection {
        case .recent, .googleDrive:
            return allDocuments.filter { !$0.trashed }
        case .starred:
            return allDocuments.filter { $0.starred && !$0.trashed }
        case .sharedWithMe:
            return allDocuments.filter { $0.shared && !$0.trashed }
        case .offline:
            return []
        case .spam:
            return []
        case .trash:
            return allDocuments.filter(\.trashed)
        case .settings, .help:
            return allDocuments.filter { !$0.trashed }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                DocsPalette.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        searchBar
                        contentHeader
                        documentsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geometry.safeAreaInsets.top + 14)
                    .padding(.bottom, max(170, geometry.safeAreaInsets.bottom + 150))
                }
                .blur(radius: isDrawerPresented ? 2 : 0)
                .disabled(isDrawerPresented)
                .overlay(alignment: .bottomTrailing) {
                    floatingCreateButton
                        .padding(.trailing, 22)
                        .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 18))
                }

                if isDrawerPresented {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                isDrawerPresented = false
                            }
                        }

                    DocsSidebarPanel(
                        selection: drawerSelection,
                        onSelect: selectDrawerItem
                    )
                    .frame(width: geometry.size.width * 0.82, alignment: .leading)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .transition(.move(edge: .leading))
                }

                if isProfileCardPresented {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                isProfileCardPresented = false
                            }
                        }

                    VStack {
                        Spacer()

                        DocsAccountCard(profile: store.profile)
                            .padding(.horizontal, 18)
                            .padding(.bottom, max(18, geometry.safeAreaInsets.bottom + 8))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: isDrawerPresented)
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: isProfileCardPresented)
        }
        .sheet(item: $activeModal) { modal in
            switch modal {
            case .search:
                DocsSearchSheet(store: store) { file in
                    activeModal = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        openDocument(file)
                    }
                }
            case .settings:
                DocsSettingsSheet(store: store)
            case .help:
                DocsHelpSheet(store: store) { file in
                    activeModal = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        openDocument(file)
                    }
                }
            }
        }
        .sheet(isPresented: $isCreateFolderPresented) {
            CreateFolderSheet(
                folderName: $createFolderName,
                onCancel: {
                    createFolderName = ""
                    isCreateFolderPresented = false
                },
                onCreate: {
                    store.createFolder(name: createFolderName, parentFolderId: store.currentData.rootFolderId)
                    createFolderName = ""
                    isCreateFolderPresented = false
                }
            )
        }
    }

    private var searchBar: some View {
        HStack(spacing: 14) {
            Button {
                isProfileCardPresented = false
                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                    isDrawerPresented = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button {
                activeModal = .search
            } label: {
                HStack {
                    Text("Search in Docs")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(DocsPalette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("docs_open_search_button")

            Menu {
                Button("Browse CloudDrive") {
                    drawerSelection = .googleDrive
                    isDrawerPresented = false
                    isProfileCardPresented = false
                }
                Button("Show recent docs") {
                    drawerSelection = .recent
                    isDrawerPresented = false
                    isProfileCardPresented = false
                }
                Button("Create folder") {
                    createFolderName = ""
                    isCreateFolderPresented = true
                }
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 21, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .buttonStyle(.plain)

            Button {
                isDrawerPresented = false
                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                    isProfileCardPresented.toggle()
                }
            } label: {
                DocsAvatarView(letter: profileLetter, size: 48)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .frame(height: 78)
        .background(DocsPalette.searchSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.42), radius: 18, x: 0, y: 10)
    }

    private var contentHeader: some View {
        HStack {
            HStack(spacing: 4) {
                Text(drawerSelection.sectionTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DocsPalette.secondaryText)

                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(DocsPalette.secondaryText)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsListLayout.toggle()
                }
            } label: {
                Image(systemName: showsListLayout ? "square.grid.2x2" : "list.bullet.rectangle.portrait")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundStyle(DocsPalette.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var documentsSection: some View {
        if filteredDocuments.isEmpty {
            DocsSectionEmptyState(selection: drawerSelection)
        } else if showsListLayout {
            VStack(spacing: 18) {
                ForEach(filteredDocuments) { file in
                    DocsDocumentListRow(
                        file: file,
                        previewLines: previewLines(for: file),
                        onOpen: { openDocument(file) },
                        onToggleStar: { store.toggleStar(itemId: file.id) },
                        onRename: { coordinator.beginRename(file: file) },
                        onMove: { coordinator.beginMove(file: file) },
                        onDuplicate: { _ = store.duplicateFile(id: file.id) },
                        onShare: { coordinator.beginShare(file: file) },
                        onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                    )
                }
            }
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 18),
                GridItem(.flexible(), spacing: 18)
            ], spacing: 24) {
                ForEach(filteredDocuments) { file in
                    DocsDocumentCard(
                        file: file,
                        previewLines: previewLines(for: file),
                        onOpen: { openDocument(file) },
                        onToggleStar: { store.toggleStar(itemId: file.id) },
                        onRename: { coordinator.beginRename(file: file) },
                        onMove: { coordinator.beginMove(file: file) },
                        onDuplicate: { _ = store.duplicateFile(id: file.id) },
                        onShare: { coordinator.beginShare(file: file) },
                        onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                    )
                }
            }
        }
    }

    private var floatingCreateButton: some View {
        Button {
            isDrawerPresented = false
            isProfileCardPresented = false
            _ = store.createDocument()
        } label: {
            Circle()
                .fill(DocsPalette.chrome)
                .frame(width: 56, height: 56)
                .overlay {
                    DocsMulticolorPlusIcon(armLength: 9, thickness: 4)
                }
                .shadow(color: .black.opacity(0.34), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func previewLines(for file: WorkspaceFile) -> [String] {
        let headerLine = AppFormatters.shortDate.string(from: file.updatedAt)
        let bodyLines = store.document(id: file.id)?
            .body
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []
        return [headerLine, ""] + bodyLines
    }

    private func selectDrawerItem(_ item: DocsDrawerSelection) {
        if item.isFilter {
            drawerSelection = item
        } else {
            switch item {
            case .settings:
                activeModal = .settings
            case .help:
                activeModal = .help
            default:
                break
            }
        }

        isProfileCardPresented = false
        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            isDrawerPresented = false
        }
    }

    private func openDocument(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudDocs", targetApp: "Docs")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}

private struct DocsSidebarPanel: View {
    let selection: DocsDrawerSelection
    let onSelect: (DocsDrawerSelection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("Cloud")
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(" Docs")
                    .font(.system(size: 27, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.94))
            }
            .padding(.leading, 24)
            .padding(.top, 30)
            .padding(.bottom, 24)

            Divider()
                .overlay(Color.white.opacity(0.22))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(DocsDrawerSelection.allCases) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        HStack(spacing: 22) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 22, weight: .medium))
                                .frame(width: 30)
                            Text(item.title)
                                .font(.system(size: 21, weight: .regular))
                        }
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 20)
                        .frame(height: 62)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            (item.isFilter && selection == item ? DocsPalette.selectedRow : Color.clear),
                            in: Capsule(style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DocsPalette.drawerSurface)
    }
}

private struct DocsDocumentCard: View {
    let file: WorkspaceFile
    let previewLines: [String]
    let onOpen: () -> Void
    let onToggleStar: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onDuplicate: () -> Void
    let onShare: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpen) {
                ZStack(alignment: .bottomTrailing) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(previewLines.prefix(8).enumerated()), id: \.offset) { index, line in
                            Text(line.isEmpty ? " " : line)
                                .font(.system(size: index == 0 ? 5.5 : 5.2, weight: index == 0 ? .semibold : .regular))
                                .foregroundStyle(line.contains("http") ? DocsPalette.link : (index <= 1 ? DocsPalette.pageMutedInk : DocsPalette.pageInk))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(DocsPalette.page)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(6)

                    if file.shared {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.56))
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 40, height: 40)
                        .padding(.trailing, 10)
                        .padding(.bottom, 12)
                    }
                }
                .frame(height: 214)
                .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(alignment: .center) {
                DocsDocumentGlyph(size: 22)
                Spacer()
                DocsCardMenu(
                    file: file,
                    onOpen: onOpen,
                    onToggleStar: onToggleStar,
                    onRename: onRename,
                    onMove: onMove,
                    onDuplicate: onDuplicate,
                    onShare: onShare,
                    onTrashOrRestore: onTrashOrRestore
                )
            }

            Text(file.name)
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(.white.opacity(0.96))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
        }
        .accessibilityIdentifier(AccessibilityID.fileRow(file))
    }
}

private struct DocsDocumentListRow: View {
    let file: WorkspaceFile
    let previewLines: [String]
    let onOpen: () -> Void
    let onToggleStar: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onDuplicate: () -> Void
    let onShare: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onOpen) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(DocsPalette.cardSurface)
                    .frame(width: 102, height: 122)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(DocsPalette.page)
                            .padding(12)
                            .overlay(alignment: .topLeading) {
                                VStack(alignment: .leading, spacing: 3) {
                                    ForEach(Array(previewLines.prefix(7).enumerated()), id: \.offset) { _, line in
                                        Text(line.isEmpty ? " " : line)
                                            .font(.system(size: 4.8))
                                            .foregroundStyle(line.contains("http") ? DocsPalette.link : DocsPalette.pageInk)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(8)
                            }
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 10) {
                Text(file.name)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(AppFormatters.shortDateTime.string(from: file.updatedAt))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DocsPalette.secondaryText)

                HStack(spacing: 10) {
                    DocsDocumentGlyph(size: 18)
                    if file.shared {
                        Label("Shared", systemImage: "person.2.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DocsPalette.secondaryText)
                    }
                }
            }

            Spacer()

            DocsCardMenu(
                file: file,
                onOpen: onOpen,
                onToggleStar: onToggleStar,
                onRename: onRename,
                onMove: onMove,
                onDuplicate: onDuplicate,
                onShare: onShare,
                onTrashOrRestore: onTrashOrRestore
            )
        }
        .padding(16)
        .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier(AccessibilityID.fileRow(file))
    }
}

private struct DocsCardMenu: View {
    let file: WorkspaceFile
    let onOpen: () -> Void
    let onToggleStar: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onDuplicate: () -> Void
    let onShare: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        Menu {
            Button("Open", action: onOpen)
            Button("Share", action: onShare)
            Button(file.starred ? "Remove star" : "Star", action: onToggleStar)
            Button("Rename", action: onRename)
                .accessibilityIdentifier(AccessibilityID.fileActionRename)
            Button("Move", action: onMove)
                .accessibilityIdentifier(AccessibilityID.fileActionMove)
            Button("Duplicate", action: onDuplicate)
                .accessibilityIdentifier(AccessibilityID.fileActionDuplicate)
            Button(file.trashed ? "Restore" : "Move to trash", role: file.trashed ? nil : .destructive, action: onTrashOrRestore)
                .accessibilityIdentifier(file.trashed ? AccessibilityID.fileActionRestore : AccessibilityID.fileActionTrash)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(DocsPalette.secondaryText)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }
}

private struct DocsSectionEmptyState: View {
    let selection: DocsDrawerSelection

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: selection.systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(DocsPalette.secondaryText)
            Text(selection.emptyTitle)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
            Text(selection.emptyMessage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(DocsPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct DocsAccountCard: View {
    let profile: UserWorkspaceProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(profile.displayName)
            Text(profile.email)
        }
        .font(.system(size: 22, weight: .regular))
        .foregroundStyle(.black.opacity(0.78))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 16, x: 0, y: 8)
    }
}

private struct DocsSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    let onOpen: (WorkspaceFile) -> Void

    @State private var query = ""

    private var results: [WorkspaceFile] {
        store.search(query: query, filter: .documents, sort: .recent).compactMap { item in
            guard case .file(let file) = item, file.fileType == .document else { return nil }
            return file
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    searchField

                    if results.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(DocsPalette.secondaryText)
                            Text(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Start typing to search" : "No matching documents")
                                .font(.system(size: 20, weight: .semibold))
                            Text(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Search looks through the document titles and previews in this workspace." : "Try a different title, keyword, or shared document name.")
                                .font(.system(size: 14))
                                .foregroundStyle(DocsPalette.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 24)
                        .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    } else {
                        VStack(spacing: 16) {
                            ForEach(results) { file in
                                Button {
                                    dismiss()
                                    onOpen(file)
                                } label: {
                                    HStack(spacing: 16) {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(DocsPalette.cardSurface)
                                            .frame(width: 72, height: 88)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(DocsPalette.page)
                                                    .padding(10)
                                            }

                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(file.name)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                                .multilineTextAlignment(.leading)

                                            Text(store.contentPreview(for: file))
                                                .font(.system(size: 14))
                                                .foregroundStyle(DocsPalette.secondaryText)
                                                .lineLimit(2)
                                        }

                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(24)
                .padding(.top, 8)
            }
            .background(DocsPalette.background.ignoresSafeArea())
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(DocsPalette.background)
        .preferredColorScheme(.dark)
    }

    private var searchField: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DocsPalette.secondaryText)

            TextField("Search documents", text: $query)
                .font(.system(size: 19, weight: .regular))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)

            if query.isEmpty == false {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DocsPalette.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 60)
        .background(DocsPalette.searchSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct DocsSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore

    private var sourceSelection: Binding<WorkspaceSourceType> {
        Binding(
            get: { store.envelope.selectedSourceType },
            set: { store.switchSourceType($0) }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    docsCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(store.profile.displayName)
                                .font(.system(size: 24, weight: .semibold))
                            Text(store.profile.email)
                                .font(.system(size: 16))
                                .foregroundStyle(DocsPalette.secondaryText)
                            Text(AppFormatters.storageText(usedGB: store.profile.storageUsedGB, limitGB: store.profile.storageLimitGB))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(DocsPalette.secondaryText)
                        }
                    }

                    docsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Workspace source")
                                .font(.system(size: 18, weight: .semibold))

                            ForEach(WorkspaceSourceType.allCases) { sourceType in
                                Button {
                                    store.switchSourceType(sourceType)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(sourceType.title)
                                                .font(.system(size: 16, weight: .medium))
                                            Text(sourceSubtitle(for: sourceType))
                                                .font(.system(size: 13))
                                                .foregroundStyle(DocsPalette.secondaryText)
                                        }
                                        Spacer()
                                        if store.envelope.selectedSourceType == sourceType {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(DocsPalette.accent)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(sourceAvailable(sourceType) == false)
                                .opacity(sourceAvailable(sourceType) ? 1 : 0.45)
                            }
                        }
                    }

                    docsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Maintenance")
                                .font(.system(size: 18, weight: .semibold))
                            Button("Reset app state") {
                                store.resetAppState()
                                dismiss()
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
                .padding(24)
            }
            .background(DocsPalette.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(DocsPalette.background)
        .preferredColorScheme(.dark)
    }

    private func sourceAvailable(_ sourceType: WorkspaceSourceType) -> Bool {
        switch sourceType {
        case .seeded:
            return true
        case .bundledSnapshot:
            return store.bundledSnapshotAvailable
        case .importedSnapshot:
            return store.importedSnapshotAvailable
        }
    }

    private func sourceSubtitle(for sourceType: WorkspaceSourceType) -> String {
        switch sourceType {
        case .seeded:
            return "Anonymized sample workspace"
        case .bundledSnapshot:
            return store.bundledSnapshotAvailable ? "Bundled offline snapshot available" : "No bundled snapshot loaded"
        case .importedSnapshot:
            return store.importedSnapshotAvailable ? (store.importedSnapshotFilename ?? "Imported snapshot ready") : "Import a snapshot to enable this mode"
        }
    }

    @ViewBuilder
    private func docsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct DocsHelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    let onOpen: (WorkspaceFile) -> Void

    private var starterDoc: WorkspaceFile? {
        store.currentData.files
            .filter { $0.fileType == .document && !$0.trashed }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    helpCard(title: "Supported workflows", lines: [
                        "Browse recent, starred, shared, offline, spam, and trash sections",
                        "Search documents from the header",
                        "Create, rename, move, duplicate, share, and trash docs",
                        "Read, edit, format, comment, and append writing suggestions"
                    ])

                    helpCard(title: "About this app", lines: [
                        "All visible account and document data is fictional sample content",
                        "Edits persist locally in the workspace store",
                        "The UI stays in dark Docs-style chrome for consistency with the reference flow"
                    ])

                    if let starterDoc {
                        Button {
                            dismiss()
                            onOpen(starterDoc)
                        } label: {
                            Text("Open starter document")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(DocsPalette.accent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .foregroundStyle(.black.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
            }
            .background(DocsPalette.background.ignoresSafeArea())
            .navigationTitle("Help & feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(DocsPalette.background)
        .preferredColorScheme(.dark)
    }

    private func helpCard(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(DocsPalette.accent)
                        .frame(width: 7, height: 7)
                        .padding(.top, 7)
                    Text(line)
                        .font(.system(size: 15))
                        .foregroundStyle(DocsPalette.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
