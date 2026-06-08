import SwiftUI
import SwiftData

// Root entry point for the Notes UI. Wraps the folder sidebar in a
// NavigationStack so each subsequent screen (folder → notes list → editor)
// pushes with the standard iOS transition.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            FolderSidebar()
        }
    }
}

// MARK: - List scope

/// Describes what a NoteList is showing. Drives filtering logic and controls
/// which toolbar actions are available (trash view hides the new-note button,
/// disables pinning, etc.).
enum ListScope: Hashable {
    case everything
    case inFolder(NoteFolder)
    case trashed

    var displaysTrashedNotes: Bool {
        if case .trashed = self { return true }
        return false
    }

    var showsAllFolderNames: Bool {
        switch self {
        case .everything, .trashed: return true
        case .inFolder: return false
        }
    }
}

/// Ordering options exposed via the notes-list context menu.
enum NoteOrder: String, CaseIterable, Hashable {
    case dateEdited, dateCreated, title

    var menuLabel: String {
        switch self {
        case .dateEdited: return "Date Edited"
        case .dateCreated: return "Date Created"
        case .title: return "Title"
        }
    }
}

// MARK: - Date formatting

/// Centralized date formatting so that every screen renders the "last
/// modified" chip identically. Broken out so `NoteRowCell` and the editor
/// header share the same formatter instances (cheaper than rebuilding).
enum NoteDateFormatting {
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()
    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f
    }()
    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "M/d/yy"; return f
    }()
    private static let editorFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy 'at' h:mm a"; return f
    }()

    /// Compact relative label for the notes list: today = time, yesterday =
    /// "Yesterday", within a week = weekday name, otherwise short date.
    static func rowLabel(for date: Date, relativeTo reference: Date = .now) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return timeFormatter.string(from: date) }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if let weekAgo = cal.date(byAdding: .day, value: -7, to: reference), date > weekAgo {
            return weekdayFormatter.string(from: date)
        }
        return shortDateFormatter.string(from: date)
    }

    static func editorLabel(for date: Date) -> String {
        editorFormatter.string(from: date)
    }
}

// MARK: - Folder sidebar (root screen)

/// Top-level folder picker — mirrors the Folders pane in Apple Notes with
/// "All iCloud" at the top, user folders in the middle, and Recently Deleted
/// at the bottom. Also handles creating new folders via an alert and creating
/// a new note (which lands in the default "Notes" folder and jumps straight
/// to the editor).
struct FolderSidebar: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoteFolder.sortOrder) private var folders: [NoteFolder]
    @Query private var allNotes: [Note]

    @State private var searchText: String = ""
    @State private var isCreatingFolder: Bool = false
    @State private var folderNameDraft: String = ""
    @State private var pendingNewNote: Note?

    private var activeCount: Int { allNotes.lazy.filter { !$0.isInTrash }.count }
    private var trashCount: Int { allNotes.lazy.filter { $0.isInTrash }.count }

    private var searchMatches: [Note] {
        guard !searchText.isEmpty else { return [] }
        let needle = searchText.lowercased()
        return allNotes
            .filter { !$0.isInTrash }
            .filter { $0.title.lowercased().contains(needle) || $0.body.lowercased().contains(needle) }
            .sorted { $0.modifiedDate > $1.modifiedDate }
    }

    var body: some View {
        List {
            if searchText.isEmpty {
                folderListSection
            } else {
                searchSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Folders")
        .searchable(text: $searchText, prompt: "Search")
        .toolbar { sidebarToolbar }
        .alert("New Folder", isPresented: $isCreatingFolder) {
            TextField("Name", text: $folderNameDraft)
                .accessibilityIdentifier("notes_new_folder_name_field")
            Button("Save") { commitNewFolder() }
                .accessibilityIdentifier("notes_new_folder_save")
            Button("Cancel", role: .cancel) { folderNameDraft = "" }
        }
        .navigationDestination(item: $pendingNewNote) { note in
            NoteEditor(note: note)
        }
    }

    // MARK: Subviews

    private var folderListSection: some View {
        Section("iCloud") {
            NavigationLink {
                NoteList(scope: .everything, navigationTitle: "All iCloud")
            } label: {
                folderRowLabel(
                    systemImage: "tray.fill",
                    tint: .yellow,
                    title: "All iCloud",
                    trailingCount: activeCount
                )
            }
            .accessibilityIdentifier("notes_folder_all")

            ForEach(folders) { folder in
                NavigationLink {
                    NoteList(scope: .inFolder(folder), navigationTitle: folder.name)
                } label: {
                    folderRowLabel(
                        systemImage: "folder.fill",
                        tint: .yellow,
                        title: folder.name,
                        trailingCount: folder.activeNotes.count
                    )
                }
                .accessibilityIdentifier(folder.accessibilityID)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { softDelete(folder: folder) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            NavigationLink {
                NoteList(scope: .trashed, navigationTitle: "Recently Deleted")
            } label: {
                folderRowLabel(
                    systemImage: "trash.fill",
                    tint: .secondary,
                    title: "Recently Deleted",
                    trailingCount: trashCount
                )
            }
            .accessibilityIdentifier("notes_folder_trash")
        }
    }

    private var searchSection: some View {
        ForEach(searchMatches) { note in
            NavigationLink {
                NoteEditor(note: note)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(note.displayTitle).fontWeight(.semibold).lineLimit(1)
                    HStack(spacing: 4) {
                        Text(note.folder?.name ?? "Notes")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text("·").font(.subheadline).foregroundColor(.secondary)
                        Text(note.preview.isEmpty ? "No additional text" : note.preview)
                            .font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                    }
                }
            }
            .accessibilityIdentifier(note.rowAccessibilityID)
        }
    }

    @ToolbarContentBuilder
    private var sidebarToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                folderNameDraft = ""
                isCreatingFolder = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "folder.badge.plus")
                    Text("New Folder")
                }
                .font(.callout)
            }
            .accessibilityIdentifier("notes_new_folder_button")

            Spacer()

            Button { openFreshNote() } label: {
                Image(systemName: "square.and.pencil")
            }
            .accessibilityIdentifier("notes_new_note_button")
        }
    }

    private func folderRowLabel(
        systemImage: String,
        tint: Color,
        title: String,
        trailingCount: Int
    ) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(tint)
                .font(.title3)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text("\(trailingCount)").foregroundColor(.secondary)
        }
    }

    // MARK: Actions

    private func commitNewFolder() {
        let trimmed = folderNameDraft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { folderNameDraft = ""; return }
        let folder = NoteFolder(name: trimmed, sortOrder: folders.count)
        modelContext.insert(folder)
        folderNameDraft = ""
    }

    private func openFreshNote() {
        let defaultFolder = folders.first(where: { $0.name == "Notes" }) ?? folders.first
        let note = Note()
        note.folder = defaultFolder
        modelContext.insert(note)
        pendingNewNote = note
    }

    /// Soft-deletes a folder by trashing its notes and removing the folder
    /// itself. Matches Apple Notes: the notes survive in "Recently Deleted".
    private func softDelete(folder: NoteFolder) {
        let now = Date()
        for note in folder.notes where !note.isInTrash {
            note.isInTrash = true
            note.trashedDate = now
        }
        modelContext.delete(folder)
    }
}

// MARK: - Note list (middle screen)

/// Lists notes within a given scope. Splits pinned vs. unpinned into separate
/// sections (except in trash view), supports swipe-to-trash / swipe-to-pin,
/// and exposes sort + selection options from a menu in the top-right corner.
struct NoteList: View {
    let scope: ListScope
    let navigationTitle: String

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.modifiedDate, order: .reverse) private var allNotes: [Note]
    @Query(sort: \NoteFolder.sortOrder) private var allFolders: [NoteFolder]

    @State private var searchText: String = ""
    @State private var order: NoteOrder = .dateEdited
    @State private var selectionMode: Bool = false
    @State private var editMode: EditMode = .inactive
    @State private var moveTarget: Note?
    @State private var pendingNewNote: Note?

    // MARK: Derived

    private var visibleNotes: [Note] {
        let base: [Note]
        switch scope {
        case .everything:
            base = allNotes.filter { !$0.isInTrash }
        case .inFolder(let folder):
            let folderID = folder.persistentModelID
            base = allNotes.filter { $0.folder?.persistentModelID == folderID && !$0.isInTrash }
        case .trashed:
            base = allNotes.filter { $0.isInTrash }
        }
        let filtered = searchText.isEmpty ? base : base.filter { matchesSearch($0) }
        return sorted(filtered)
    }

    private func matchesSearch(_ note: Note) -> Bool {
        let needle = searchText.lowercased()
        return note.title.lowercased().contains(needle) || note.body.lowercased().contains(needle)
    }

    private func sorted(_ input: [Note]) -> [Note] {
        switch order {
        case .dateEdited: return input.sorted { $0.modifiedDate > $1.modifiedDate }
        case .dateCreated: return input.sorted { $0.createdDate > $1.createdDate }
        case .title: return input.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    private var pinned: [Note] { visibleNotes.filter { $0.isPinned } }
    private var unpinned: [Note] { visibleNotes.filter { !$0.isPinned } }

    private var countLabel: String {
        let n = visibleNotes.count
        return n == 1 ? "1 Note" : "\(n) Notes"
    }

    // MARK: Body

    var body: some View {
        List {
            if scope.displaysTrashedNotes {
                trashRows
            } else {
                if !pinned.isEmpty {
                    Section {
                        ForEach(pinned) { note in pinnedRow(note) }
                    } header: {
                        Label("Pinned", systemImage: "pin.fill")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.secondary).textCase(nil)
                    }
                }
                Section {
                    ForEach(unpinned) { note in regularRow(note) }
                } header: {
                    if !pinned.isEmpty {
                        Text("Notes")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.secondary).textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(navigationTitle)
        .searchable(text: $searchText, prompt: "Search")
        .environment(\.editMode, $editMode)
        .overlay { emptyOverlay }
        .toolbar { listToolbar }
        .sheet(item: $moveTarget) { note in
            MoveDestinationSheet(note: note, folders: allFolders)
        }
        .navigationDestination(item: $pendingNewNote) { note in
            NoteEditor(note: note)
        }
    }

    // MARK: Row builders

    private func pinnedRow(_ note: Note) -> some View {
        NavigationLink {
            NoteEditor(note: note)
        } label: {
            NoteRowCell(note: note, showsFolderName: scope.showsAllFolderNames)
        }
        .accessibilityIdentifier(note.rowAccessibilityID)
        .swipeActions(edge: .leading) {
            Button { withAnimation { note.isPinned.toggle() } } label: {
                Label("Unpin", systemImage: "pin.slash.fill")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { trash(note) } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            Button { moveTarget = note } label: {
                Label("Move", systemImage: "folder.fill")
            }
            .tint(.purple)
        }
    }

    private func regularRow(_ note: Note) -> some View {
        NavigationLink {
            NoteEditor(note: note)
        } label: {
            NoteRowCell(note: note, showsFolderName: scope.showsAllFolderNames)
        }
        .accessibilityIdentifier(note.rowAccessibilityID)
        .swipeActions(edge: .leading) {
            Button { withAnimation { note.isPinned = true } } label: {
                Label("Pin", systemImage: "pin.fill")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { trash(note) } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            Button { moveTarget = note } label: {
                Label("Move", systemImage: "folder.fill")
            }
            .tint(.purple)
        }
    }

    private var trashRows: some View {
        ForEach(visibleNotes) { note in
            NavigationLink {
                NoteEditor(note: note)
            } label: {
                NoteRowCell(note: note, showsFolderName: true)
            }
            .accessibilityIdentifier(note.rowAccessibilityID)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) { modelContext.delete(note) } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    note.isInTrash = false
                    note.trashedDate = nil
                } label: {
                    Label("Recover", systemImage: "arrow.uturn.backward")
                }
                .tint(.blue)
            }
        }
    }

    @ViewBuilder private var emptyOverlay: some View {
        if visibleNotes.isEmpty && searchText.isEmpty {
            Text(scope.displaysTrashedNotes ? "No Recently Deleted Notes" : "No Notes")
                .foregroundColor(.secondary)
                .font(.title3)
        }
    }

    @ToolbarContentBuilder
    private var listToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if !scope.displaysTrashedNotes { sortMenu }
        }
        ToolbarItemGroup(placement: .bottomBar) {
            if !scope.displaysTrashedNotes {
                Image(systemName: "square.and.pencil")
                    .opacity(0)
                    .accessibilityHidden(true)
            }
            Spacer()
            Text(countLabel).font(.caption).foregroundColor(.secondary)
            Spacer()
            if !scope.displaysTrashedNotes {
                Button { openFreshNote() } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityIdentifier("notes_new_note_button")
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Button {
                selectionMode.toggle()
                editMode = selectionMode ? .active : .inactive
            } label: {
                Label(selectionMode ? "Done" : "Select Notes", systemImage: "checkmark.circle")
            }
            Divider()
            Menu {
                ForEach(NoteOrder.allCases, id: \.self) { option in
                    Button { order = option } label: {
                        Label(option.menuLabel, systemImage: order == option ? "checkmark" : "")
                    }
                }
            } label: {
                Label("Sort By", systemImage: "arrow.up.arrow.down")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    // MARK: Mutations

    private func openFreshNote() {
        let note = Note()
        switch scope {
        case .inFolder(let folder):
            note.folder = folder
        case .everything, .trashed:
            note.folder = allFolders.first(where: { $0.name == "Notes" }) ?? allFolders.first
        }
        modelContext.insert(note)
        pendingNewNote = note
    }

    private func trash(_ note: Note) {
        withAnimation {
            note.isPinned = false
            note.isInTrash = true
            note.trashedDate = Date()
        }
    }
}

// MARK: - Row cell

struct NoteRowCell: View {
    let note: Note
    var showsFolderName: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(note.displayTitle)
                .font(.body)
                .fontWeight(.semibold)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text(NoteDateFormatting.rowLabel(for: note.modifiedDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if showsFolderName, let folderName = note.folder?.name {
                    Text("·").font(.subheadline).foregroundColor(.secondary)
                    Text(folderName).font(.subheadline).foregroundColor(.secondary)
                }
                Text("·").font(.subheadline).foregroundColor(.secondary)
                Text(note.preview.isEmpty ? "No additional text" : note.preview)
                    .font(.subheadline)
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Note editor (leaf screen)

/// Title + body editor for a single note. Mirrors Apple Notes formatting
/// conventions: bold title on the first line, centered "last modified"
/// timestamp, then a full-height body TextEditor. Bottom-bar buttons append
/// text (bold marker, checklist, placeholders) to the body.
///
/// Empty-note cleanup: on disappear, a note whose title AND body are both
/// whitespace-only is deleted from the store. This matches Apple Notes and
/// keeps the benchmark's "new note" flow tidy when an agent abandons it.
struct NoteEditor: View {
    @Bindable var note: Note

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \NoteFolder.sortOrder) private var allFolders: [NoteFolder]

    @FocusState private var titleFocused: Bool
    @FocusState private var bodyFocused: Bool

    @State private var shownDate: Date = .now
    @State private var showingMoveSheet: Bool = false
    @State private var pendingNewNote: Note?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleField
                timestampLabel
                bodyField
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { shownDate = note.modifiedDate }
        .onDisappear { deleteIfEmpty() }
        .toolbar { editorToolbar }
        .onChange(of: note.title) { _, _ in note.modifiedDate = .now }
        .onChange(of: note.body) { _, _ in note.modifiedDate = .now }
        .sheet(isPresented: $showingMoveSheet) {
            MoveDestinationSheet(note: note, folders: allFolders)
        }
        .navigationDestination(item: $pendingNewNote) { fresh in
            NoteEditor(note: fresh)
        }
    }

    // MARK: Fields

    private var titleField: some View {
        TextField("Title", text: $note.title, axis: .vertical)
            .font(.title.bold())
            .focused($titleFocused)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .accessibilityIdentifier("notes_title_field")
    }

    private var timestampLabel: some View {
        Text(NoteDateFormatting.editorLabel(for: shownDate))
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
            .padding(.bottom, 12)
    }

    private var bodyField: some View {
        ZStack(alignment: .topLeading) {
            // Invisible sizing text so the TextEditor grows with content
            // while living inside a ScrollView.
            Text(note.body.isEmpty ? " " : note.body)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .opacity(0)
                .frame(maxWidth: .infinity, alignment: .leading)

            if note.body.isEmpty && !bodyFocused {
                Text("Start typing...")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 17)
                    .padding(.top, 8)
            }
            TextEditor(text: $note.body)
                .focused($bodyFocused)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .accessibilityIdentifier("notes_body_editor")
        }
        .frame(minHeight: 300)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                ShareLink(item: "\(note.title)\n\n\(note.body)") {
                    Image(systemName: "square.and.arrow.up")
                }
                Menu {
                    Button {
                        withAnimation { note.isPinned.toggle() }
                    } label: {
                        Label(note.isPinned ? "Unpin Note" : "Pin Note",
                              systemImage: note.isPinned ? "pin.slash" : "pin")
                    }
                    Button { showingMoveSheet = true } label: {
                        Label("Move Note", systemImage: "folder")
                    }
                    Divider()
                    Button(role: .destructive) { trashAndDismiss() } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        ToolbarItemGroup(placement: .bottomBar) {
            Button { appendMarker("\n**bold**") } label: {
                Image(systemName: "textformat.alt")
            }
            Spacer()
            Button { appendMarker("\n- [ ] ") } label: {
                Image(systemName: "checklist")
            }
            Spacer()
            Button { appendMarker("\n[Photo placeholder]") } label: {
                Image(systemName: "camera.fill")
            }
            Spacer()
            Button { appendMarker("\n[Sketch placeholder]") } label: {
                Image(systemName: "pencil.tip.crop.circle")
            }
            Spacer()
            Button { spawnSiblingNote() } label: {
                Image(systemName: "square.and.pencil")
            }
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") { titleFocused = false; bodyFocused = false }
        }
    }

    // MARK: Mutations

    private func appendMarker(_ text: String) { note.body += text }

    private func spawnSiblingNote() {
        let fresh = Note()
        fresh.folder = note.folder
        modelContext.insert(fresh)
        pendingNewNote = fresh
    }

    private func trashAndDismiss() {
        note.isInTrash = true
        note.trashedDate = Date()
        dismiss()
    }

    private func deleteIfEmpty() {
        let titleBlank = note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let bodyBlank = note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if titleBlank && bodyBlank && !note.isInTrash {
            modelContext.delete(note)
        }
    }
}

// MARK: - Move destination sheet

/// Simple list-of-folders picker. Tapping a row reassigns the note and
/// dismisses. A checkmark marks the note's current folder.
struct MoveDestinationSheet: View {
    let note: Note
    let folders: [NoteFolder]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(folders) { folder in
                    Button { assign(folder) } label: { row(for: folder) }
                }
            }
            .navigationTitle("Move Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func row(for folder: NoteFolder) -> some View {
        HStack {
            Image(systemName: "folder.fill").foregroundColor(.yellow)
            Text(folder.name).foregroundColor(.primary)
            Spacer()
            if note.folder?.persistentModelID == folder.persistentModelID {
                Image(systemName: "checkmark").foregroundColor(.accentColor)
            }
        }
    }

    private func assign(_ folder: NoteFolder) {
        note.folder = folder
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [NoteFolder.self, Note.self], inMemory: true)
}
