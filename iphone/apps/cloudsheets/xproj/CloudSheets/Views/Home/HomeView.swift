import SwiftUI

private enum HomeSortMode: String, CaseIterable, Identifiable {
    case recent
    case updated
    case name

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent:
            return "Last opened by me"
        case .updated:
            return "Last edited"
        case .name:
            return "Name"
        }
    }
}

private enum HomeLayoutMode {
    case list
    case grid
}

struct HomeView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SpreadsheetActionCoordinator

    @State private var sortMode: HomeSortMode = .recent
    @State private var layoutMode: HomeLayoutMode = .list
    @State private var showSearch = false
    @State private var showLibrary = false

    private var viewModel: SheetsHomeViewModel {
        SheetsHomeViewModel(store: store)
    }

    private var displayFiles: [WorkspaceFile] {
        let files = viewModel.recentFiles

        switch sortMode {
        case .recent:
            return files.sorted { ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt) }
        case .updated:
            return files.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SheetsTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    homeSearchBar
                    sectionHeader
                    contentSection
                        .padding(.horizontal, 22)
                        .padding(.bottom, 120)
                }
                .padding(.top, 18)
            }
            .scrollIndicators(.hidden)
            .sheet(isPresented: $showSearch) {
                SheetsSearchSheet(
                    store: store,
                    coordinator: coordinator,
                    openSheet: openSheet
                )
            }
            .sheet(isPresented: $showLibrary) {
                SheetsLibrarySheet(
                    store: store,
                    coordinator: coordinator,
                    openSheet: openSheet
                )
            }

            Button {
                let newId = store.createSpreadsheet()
                store.activeEditorRoute = EditorRoute(fileId: newId)
            } label: {
                ZStack {
                    Circle()
                        .fill(SheetsTheme.chrome)
                        .frame(width: 56, height: 56)
                        .shadow(color: SheetsTheme.shadow, radius: 18, y: 8)

                    SheetsAddGlyph()
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, 32)
        }
    }

    private var homeSearchBar: some View {
        HStack(spacing: 14) {
            Button {
                showLibrary = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button {
                showSearch = true
            } label: {
                HStack {
                    Text("Search in Sheets")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(SheetsTheme.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                showLibrary = true
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(SheetsTheme.mutedText)
            }
            .buttonStyle(.plain)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.14, green: 0.55, blue: 0.86), Color(red: 0.10, green: 0.39, blue: 0.73)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(String(store.profile.displayName.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 14)
        .frame(height: 68)
        .background(SheetsTheme.chrome, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: SheetsTheme.shadow, radius: 22, y: 10)
        .padding(.horizontal, 20)
    }

    private var sectionHeader: some View {
        HStack {
            Menu {
                ForEach(HomeSortMode.allCases) { mode in
                    Button {
                        sortMode = mode
                    } label: {
                        if sortMode == mode {
                            Label(mode.title, systemImage: "checkmark")
                        } else {
                            Text(mode.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(sortMode.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(SheetsTheme.mutedText)
                }
            }

            Spacer()

            Button {
                layoutMode = layoutMode == .list ? .grid : .list
            } label: {
                Image(systemName: layoutMode == .list ? "square.grid.2x2" : "list.bullet")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(SheetsTheme.mutedText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var contentSection: some View {
        if layoutMode == .list {
            LazyVStack(spacing: 6) {
                ForEach(displayFiles) { file in
                    SheetsRecentFileRow(
                        file: file,
                        preview: previewText(for: file),
                        subtitle: AppFormatters.shortDate.string(from: file.updatedAt),
                        onOpen: { openSheet(file) },
                        onRename: { coordinator.beginRename(file: file) },
                        onMove: { coordinator.beginMove(file: file) },
                        onDuplicate: { _ = store.duplicateFile(id: file.id) },
                        onShare: { coordinator.beginShare(file: file) },
                        onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                    )
                    .accessibilityIdentifier(AccessibilityID.recentRow(file))
                }
            }
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(displayFiles) { file in
                    SheetsRecentFileCard(
                        file: file,
                        preview: previewText(for: file),
                        sampleValues: previewSamples(for: file),
                        subtitle: AppFormatters.shortDate.string(from: file.updatedAt),
                        onOpen: { openSheet(file) }
                    )
                    .contextMenu {
                        Button("Open") { openSheet(file) }
                        Button("Share") { coordinator.beginShare(file: file) }
                        Button("Rename") { coordinator.beginRename(file: file) }
                        Button("Move") { coordinator.beginMove(file: file) }
                        Button("Duplicate") { _ = store.duplicateFile(id: file.id) }
                        Button(file.trashed ? "Restore" : "Move to trash", role: file.trashed ? nil : .destructive) {
                            file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id)
                        }
                    }
                }
            }
        }
    }

    private func previewText(for file: WorkspaceFile) -> String {
        store.contentPreview(for: file)
            .replacingOccurrences(of: " • ", with: "  ")
    }

    private func previewSamples(for file: WorkspaceFile) -> [String] {
        guard let sheet = store.spreadsheet(id: file.id)?.sheets.first else { return [] }
        return sheet.cells
            .map(\.rawValue)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(4)
            .map { $0 }
    }

    private func openSheet(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudSheets", targetApp: "Sheets")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}

private struct SheetsRecentFileRow: View {
    let file: WorkspaceFile
    let preview: String
    let subtitle: String
    let onOpen: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onDuplicate: () -> Void
    let onShare: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            SheetsDocumentGlyph(isImported: file.name.hasSuffix(".xlsx"))

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(file.name)
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(preview)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SheetsTheme.mutedText)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if file.shared || file.permissions.count > 1 {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12, weight: .medium))
                        }
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(SheetsTheme.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button("Open", action: onOpen)
                Button("Share", action: onShare)
                Button("Rename", action: onRename)
                Button("Move", action: onMove)
                Button("Duplicate", action: onDuplicate)
                Button(file.trashed ? "Restore" : "Move to trash", role: file.trashed ? nil : .destructive, action: onTrashOrRestore)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(SheetsTheme.mutedText)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 14)
    }
}

private struct SheetsRecentFileCard: View {
    let file: WorkspaceFile
    let preview: String
    let sampleValues: [String]
    let subtitle: String
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SheetsDocumentGlyph(isImported: file.name.hasSuffix(".xlsx"))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SheetsTheme.mutedText)
                }

                MiniSheetPreview(values: sampleValues)

                Text(file.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(preview)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SheetsTheme.mutedText)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    if file.shared || file.permissions.count > 1 {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11, weight: .medium))
                    }
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(SheetsTheme.mutedText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 218, alignment: .topLeading)
            .background(SheetsTheme.chrome, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: SheetsTheme.shadow.opacity(0.7), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct MiniSheetPreview: View {
    let values: [String]

    private var cells: [String] {
        let trimmed = values.filter { !$0.isEmpty }
        return Array(trimmed.prefix(4)) + Array(repeating: "", count: max(0, 4 - trimmed.count))
    }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { column in
                        let value = cells[(row * 2) + column]
                        Text(value.isEmpty ? " " : value)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                            .padding(.horizontal, 8)
                            .background(Color.black, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding(5)
        .background(SheetsTheme.headerCell, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SheetsSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SpreadsheetActionCoordinator
    let openSheet: (WorkspaceFile) -> Void

    @State private var query = ""

    private var allFiles: [WorkspaceFile] {
        store.currentData.files
            .filter { $0.fileType == .spreadsheet && !$0.trashed }
            .sorted { ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt) }
    }

    private var results: [WorkspaceFile] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.isEmpty == false else { return allFiles }

        return allFiles.filter { file in
            file.name.lowercased().contains(normalized) || store.contentPreview(for: file).lowercased().contains(normalized)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SheetsTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        TextField("Search spreadsheets", text: $query)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .font(.system(size: 18, weight: .medium))
                            .padding(.horizontal, 18)
                            .frame(height: 54)
                            .background(SheetsTheme.chrome, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .foregroundStyle(.white)

                        if results.isEmpty {
                            EmptyStateCard(
                                title: "No search results",
                                message: "Try a spreadsheet title, app name, or status value.",
                                systemImage: "magnifyingglass",
                                accessibilityIdentifier: AccessibilityID.emptyState("sheets_search_empty")
                            )
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(results) { file in
                                    SheetsRecentFileRow(
                                        file: file,
                                        preview: store.contentPreview(for: file),
                                        subtitle: AppFormatters.shortDate.string(from: file.updatedAt),
                                        onOpen: {
                                            dismiss()
                                            openSheet(file)
                                        },
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
                    .padding(22)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SheetsLibrarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SpreadsheetActionCoordinator
    let openSheet: (WorkspaceFile) -> Void

    @State private var sortMode: HomeSortMode = .updated

    private var files: [WorkspaceFile] {
        let allFiles = store.currentData.files.filter { $0.fileType == .spreadsheet && !$0.trashed }
        switch sortMode {
        case .recent:
            return allFiles.sorted { ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt) }
        case .updated:
            return allFiles.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return allFiles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SheetsTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Menu {
                            ForEach(HomeSortMode.allCases) { mode in
                                Button(mode.title) { sortMode = mode }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(sortMode.title)
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(SheetsTheme.accent)
                        }

                        LazyVStack(spacing: 6) {
                            ForEach(files) { file in
                                SheetsRecentFileRow(
                                    file: file,
                                    preview: store.contentPreview(for: file),
                                    subtitle: store.pathString(for: file),
                                    onOpen: {
                                        dismiss()
                                        openSheet(file)
                                    },
                                    onRename: { coordinator.beginRename(file: file) },
                                    onMove: { coordinator.beginMove(file: file) },
                                    onDuplicate: { _ = store.duplicateFile(id: file.id) },
                                    onShare: { coordinator.beginShare(file: file) },
                                    onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                                )
                            }
                        }
                    }
                    .padding(22)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SheetsDocumentGlyph: View {
    let isImported: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(red: 0.52, green: 0.83, blue: 0.60))
            .frame(width: 26, height: 38)
            .overlay {
                Group {
                    if isImported {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .black))
                    } else {
                        VStack(spacing: 4) {
                            Rectangle()
                                .frame(width: 18, height: 3)
                            Rectangle()
                                .frame(width: 18, height: 3)
                            Rectangle()
                                .frame(width: 18, height: 3)
                        }
                    }
                }
                .foregroundStyle(SheetsTheme.chrome)
            }
    }
}

private struct SheetsAddGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.25, green: 0.54, blue: 0.96))
                .frame(width: 26, height: 6)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.96, green: 0.24, blue: 0.20))
                .frame(width: 6, height: 26)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.98, green: 0.74, blue: 0.16))
                .frame(width: 26, height: 6)
                .offset(y: 11)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.42, green: 0.74, blue: 0.40))
                .frame(width: 6, height: 26)
                .offset(x: -11)
        }
    }
}
