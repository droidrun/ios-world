import SwiftUI
import UniformTypeIdentifiers

private enum SlidesHomeLayoutMode: Hashable {
    case grid
    case list

    var systemImage: String {
        switch self {
        case .grid:
            return "square.grid.2x2.fill"
        case .list:
            return "list.bullet.rectangle"
        }
    }
}

struct HomeView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SlidesActionCoordinator

    @State private var query = ""
    @State private var selectedSection: SlidesHomeSection = .recent
    @State private var sort: SlidesHomeSortOption = .lastOpenedByMe
    @State private var layoutMode: SlidesHomeLayoutMode = .grid
    @State private var showDrawer = false
    @State private var showProfileSheet = false
    @State private var showSettingsSheet = false
    @State private var showHelpSheet = false
    @State private var showImporter = false
    @State private var feedbackDraft = ""

    private var viewModel: SlidesHomeViewModel {
        SlidesHomeViewModel(store: store)
    }

    private var visibleFiles: [WorkspaceFile] {
        viewModel.files(in: selectedSection, query: query, sort: sort)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color(red: 0.11, green: 0.12, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topSearchBar
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    libraryControls
                        .padding(.horizontal, 18)
                        .padding(.top, 20)

                    ScrollView(showsIndicators: false) {
                        if visibleFiles.isEmpty {
                            SlidesEmptyStateView(section: selectedSection, query: query)
                                .padding(.horizontal, 18)
                                .padding(.top, 56)
                        } else {
                            content(for: visibleFiles)
                                .padding(.horizontal, 18)
                                .padding(.top, 24)
                                .padding(.bottom, 120)
                        }
                    }
                }

                if showDrawer {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.24)) {
                                showDrawer = false
                            }
                        }

                    SlidesHomeDrawerView(
                        selection: $selectedSection,
                        profileName: store.profile.displayName,
                        closeDrawer: {
                            withAnimation(.easeInOut(duration: 0.24)) {
                                showDrawer = false
                            }
                        },
                        openSettings: {
                            withAnimation(.easeInOut(duration: 0.24)) {
                                showDrawer = false
                            }
                            showSettingsSheet = true
                        },
                        openHelp: {
                            withAnimation(.easeInOut(duration: 0.24)) {
                                showDrawer = false
                            }
                            showHelpSheet = true
                        }
                    )
                    .frame(width: min(geometry.size.width * 0.82, 390))
                    .transition(.move(edge: .leading))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                createButton
                    .padding(.trailing, 24)
                    .padding(.bottom, 34)
            }
            .sheet(isPresented: $showProfileSheet) {
                SlidesProfileSheet(profile: store.profile)
                    .presentationDetents([.height(240)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(18)
            }
            .sheet(isPresented: $showSettingsSheet) {
                SlidesSettingsSheet(
                    store: store,
                    layoutMode: $layoutMode,
                    onImportSnapshot: {
                        showSettingsSheet = false
                        showImporter = true
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showHelpSheet) {
                SlidesHelpSheet(
                    feedbackDraft: $feedbackDraft,
                    onSendFeedback: {
                        let trimmed = feedbackDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        feedbackDraft = ""
                        showHelpSheet = false
                        store.transientMessage = "Feedback draft saved locally."
                    }
                )
                .presentationDetents([.large])
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    store.importSnapshot(from: url)
                case .failure(let error):
                    store.activeAlert = AppAlert(id: "slides_import_failed", title: "Import failed", message: error.localizedDescription)
                }
            }
        }
    }

    @ViewBuilder
    private func content(for files: [WorkspaceFile]) -> some View {
        switch layoutMode {
        case .grid:
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 22
            ) {
                ForEach(files) { file in
                    SlidesDeckCardView(
                        file: file,
                        presentation: viewModel.presentation(for: file),
                        onOpen: { openDeck(file) },
                        onToggleStar: { store.toggleStar(itemId: file.id) },
                        onRename: { coordinator.beginRename(file: file) },
                        onMove: { coordinator.beginMove(file: file) },
                        onDuplicate: { _ = store.duplicateFile(id: file.id) },
                        onShare: { coordinator.beginShare(file: file) },
                        onTrashOrRestore: { file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id) }
                    )
                }
            }
        case .list:
            VStack(spacing: 14) {
                ForEach(files) { file in
                    SlidesDeckListRowView(
                        file: file,
                        presentation: viewModel.presentation(for: file),
                        onOpen: { openDeck(file) },
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

    private var topSearchBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.24)) {
                    showDrawer = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }

            TextField("", text: $query, prompt: Text("Search in Slides").foregroundStyle(.gray))
                .font(.system(size: 19, weight: .regular))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundStyle(.white)
                .accessibilityIdentifier("slides_search_field")

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            Button {
                selectedSection = .googleDrive
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Button {
                showProfileSheet = true
            } label: {
                SlidesAvatarView(initials: viewModel.profileInitials, diameter: 44)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.17, green: 0.18, blue: 0.21))
                .shadow(color: .black.opacity(0.3), radius: 18, y: 8)
        )
    }

    private var libraryControls: some View {
        HStack(alignment: .center) {
            Menu {
                ForEach(SlidesHomeSortOption.allCases) { option in
                    Button(option.title) {
                        sort = option
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(sort.title)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }

            Spacer()

            Button {
                layoutMode = layoutMode == .grid ? .list : .grid
            } label: {
                Image(systemName: layoutMode.systemImage)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    private var createButton: some View {
        Button {
            let newId = store.createPresentation()
            store.recordOpen(fileId: newId, sourceApp: "CloudSlides", targetApp: "Slides")
            store.activeEditorRoute = EditorRoute(fileId: newId)
        } label: {
            ZStack {
                Circle()
                    .fill(Color(red: 0.12, green: 0.13, blue: 0.15))
                    .frame(width: 78, height: 78)
                    .shadow(color: .black.opacity(0.38), radius: 20, y: 8)

                GooglePlusBadge()
            }
        }
        .buttonStyle(.plain)
    }

    private func openDeck(_ file: WorkspaceFile) {
        store.recordOpen(fileId: file.id, sourceApp: "CloudSlides", targetApp: "Slides")
        store.activeEditorRoute = EditorRoute(fileId: file.id)
    }
}

private struct SlidesDeckCardView: View {
    let file: WorkspaceFile
    let presentation: PresentationFile?
    let onOpen: () -> Void
    let onToggleStar: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onDuplicate: () -> Void
    let onShare: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                ZStack(alignment: .bottomTrailing) {
                    SlidesDeckThumbnailView(file: file, presentation: presentation)
                        .aspectRatio(0.78, contentMode: .fit)

                    if file.shared {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.7), in: Circle())
                            .padding(8)
                    }

                    if file.starred {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 0.98, green: 0.84, blue: 0.33))
                            .padding(8)
                            .background(Color.black.opacity(0.55), in: Circle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(8)
                    }
                }
            }
            .buttonStyle(.plain)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "menucard.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.97, green: 0.82, blue: 0.35))
                    .padding(.top, 3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(2)
                    Text(AppFormatters.shortDate.string(from: file.updatedAt))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.42))
                }

                Spacer(minLength: 0)

                SlidesDeckMenuButton(
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
        }
        .accessibilityIdentifier(AccessibilityID.fileRow(file))
    }
}

private struct SlidesDeckListRowView: View {
    let file: WorkspaceFile
    let presentation: PresentationFile?
    let onOpen: () -> Void
    let onToggleStar: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onDuplicate: () -> Void
    let onShare: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                SlidesDeckThumbnailView(file: file, presentation: presentation)
                    .frame(width: 98, height: 74)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(file.name)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(2)
                Text(AppFormatters.shortDateTime.string(from: file.updatedAt))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.42))
                Text(presentation?.slides.first?.title ?? "Presentation")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer()

            SlidesDeckMenuButton(
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .accessibilityIdentifier(AccessibilityID.fileRow(file))
    }
}

private struct SlidesDeckMenuButton: View {
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
                .accessibilityIdentifier(AccessibilityID.fileActionStar)
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
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 26, height: 26)
        }
    }
}

private struct SlidesDeckThumbnailView: View {
    let file: WorkspaceFile
    let presentation: PresentationFile?

    private var title: String {
        presentation?.slides.first?.title ?? file.name
    }

    private var subtitle: String {
        presentation?.slides.first?.body ?? file.ownerName
    }

    private var normalizedName: String {
        file.name.lowercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)

            content
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        if normalizedName.contains("conference practice") {
            VStack(spacing: 0) {
                Spacer()
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                Spacer(minLength: 12)
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.gray)
                Spacer(minLength: 4)
            }
        } else if normalizedName.contains("autonomous agents") {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                Spacer(minLength: 4)
                Text("19 Feb")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.gray)
                Spacer()
                Rectangle()
                    .fill(Color(red: 0.84, green: 0.25, blue: 0.14))
                    .frame(height: 42)
            }
        } else if normalizedName.contains("frontend codegen") {
            ZStack {
                Color(red: 0.12, green: 0.13, blue: 0.16)
                Image(systemName: "menucard.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color(red: 0.97, green: 0.82, blue: 0.35))
            }
        } else if normalizedName.contains("s26 city guide") {
            VStack(spacing: 6) {
                Text("City Guide")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(.black)
                Spacer(minLength: 0)
                ZStack {
                    Rectangle()
                        .fill(Color(red: 0.91, green: 0.94, blue: 0.98))
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.95, green: 0.75, blue: 0.22))
                            .frame(width: 26, height: 26)
                        Text("CITY")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 56, height: 56)
                Spacer(minLength: 0)
            }
        } else if normalizedName.contains("s25 city guide") {
            VStack(spacing: 8) {
                Text("City Guide")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(.black)
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? Color.white : Color(red: 0.96, green: 0.97, blue: 0.93))
                            .overlay(
                                Circle()
                                    .fill(index == 2 ? Color.orange : Color(red: 0.92, green: 0.39, blue: 0.12))
                                    .frame(width: 10, height: 10)
                                    .offset(x: index == 2 ? 2 : -2, y: 8)
                            )
                    }
                }
                .frame(height: 52)
            }
        } else if normalizedName.contains("healthcare startup") {
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                Text("Healthcare Startup\nCriteria")
                    .font(.system(size: 16, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                    .lineLimit(3)
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.gray)
                Spacer(minLength: 0)
            }
        } else if normalizedName.contains("signal check") {
            VStack(spacing: 0) {
                Spacer()
                Text(title)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.black)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        } else if normalizedName.contains("agent systems") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Agent Systems\nTalk")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.black)
                    .lineLimit(3)
                Spacer()
                Text(subtitle)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(.gray)
                    .lineLimit(3)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.black)
                    .lineLimit(3)
                Spacer(minLength: 0)
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.gray)
                    .lineLimit(3)
            }
        }
    }
}

private struct SlidesEmptyStateView: View {
    let section: SlidesHomeSection
    let query: String

    private var title: String {
        if query.isEmpty == false {
            return "No matching presentations"
        }

        switch section {
        case .spam:
            return "Nothing in spam"
        case .trash:
            return "Trash is empty"
        default:
            return "No presentations here"
        }
    }

    private var message: String {
        if query.isEmpty == false {
            return "Try another search term."
        }

        switch section {
        case .spam:
            return "No spam items to show."
        case .trash:
            return "Deleted presentations will appear here."
        default:
            return "Create a new deck or switch to another Slides section."
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "menucard")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.56))
            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.58))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct SlidesHomeDrawerView: View {
    @Binding var selection: SlidesHomeSection
    let profileName: String
    let closeDrawer: () -> Void
    let openSettings: () -> Void
    let openHelp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("CloudSlides")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.white.opacity(0.94))
                .padding(.top, 72)
                .padding(.horizontal, 22)

            Divider()
                .overlay(Color.white.opacity(0.14))

            VStack(alignment: .leading, spacing: 14) {
                ForEach([
                    SlidesHomeSection.recent,
                    .starred,
                    .sharedWithMe,
                    .offline,
                    .spam,
                    .trash,
                    .googleDrive
                ]) { section in
                    Button {
                        selection = section
                        closeDrawer()
                    } label: {
                        SlidesDrawerRow(
                            title: section.title,
                            systemImage: section.systemImage,
                            isSelected: selection == section
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: openSettings) {
                    SlidesDrawerRow(
                        title: "Settings",
                        systemImage: "gearshape.fill",
                        isSelected: false
                    )
                }
                .buttonStyle(.plain)

                Button(action: openHelp) {
                    SlidesDrawerRow(
                        title: "Help & feedback",
                        systemImage: "questionmark.circle.fill",
                        isSelected: false
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            Spacer()

            Text(profileName)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.38))
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.18, green: 0.19, blue: 0.22))
    }
}

private struct SlidesDrawerRow: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .medium))
                .frame(width: 28)
            Text(title)
                .font(.system(size: 19, weight: .regular))
        }
        .foregroundStyle(.white.opacity(isSelected ? 0.9 : 0.78))
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? Color(red: 0.13, green: 0.20, blue: 0.34) : .clear)
        )
    }
}

private struct SlidesAvatarView: View {
    let initials: String
    let diameter: CGFloat

    var body: some View {
        Text(initials)
            .font(.system(size: diameter * 0.42, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(Color(red: 0.46, green: 0.12, blue: 0.69)))
    }
}

private struct GooglePlusBadge: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.25, green: 0.52, blue: 0.96))
                .frame(width: 8, height: 30)
                .offset(x: -9)

            Rectangle()
                .fill(Color(red: 0.93, green: 0.32, blue: 0.24))
                .frame(width: 8, height: 30)
                .offset(x: 9)

            Rectangle()
                .fill(Color(red: 0.98, green: 0.81, blue: 0.22))
                .frame(width: 30, height: 8)
                .offset(y: 9)

            Rectangle()
                .fill(Color(red: 0.19, green: 0.74, blue: 0.34))
                .frame(width: 30, height: 8)
                .offset(y: -9)
        }
    }
}

private struct SlidesProfileSheet: View {
    let profile: UserWorkspaceProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.white
            VStack(alignment: .leading, spacing: 8) {
                Text(profile.displayName)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.black.opacity(0.82))
                Text(profile.email)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.black.opacity(0.74))
                Text("Storage used \(profile.storageUsedGB.formatted(.number.precision(.fractionLength(1)))) GB of \(profile.storageLimitGB.formatted(.number.precision(.fractionLength(0)))) GB")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.black.opacity(0.54))
                    .padding(.top, 4)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)
        }
    }
}

private struct SlidesSettingsSheet: View {
    @ObservedObject var store: WorkspaceStore
    @Binding var layoutMode: SlidesHomeLayoutMode
    let onImportSnapshot: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Library layout") {
                    Picker("Default layout", selection: $layoutMode) {
                        Text("Grid").tag(SlidesHomeLayoutMode.grid)
                        Text("List").tag(SlidesHomeLayoutMode.list)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Workspace source") {
                    sourceRow(
                        title: "Default workspace data",
                        subtitle: "Recommended for offline use",
                        isSelected: store.envelope.selectedSourceType == .seeded
                    ) {
                        store.switchSourceType(.seeded)
                    }

                    if store.importedSnapshotAvailable {
                        sourceRow(
                            title: "Imported snapshot",
                            subtitle: store.importedSnapshotFilename ?? "workspace_snapshot.imported.json",
                            isSelected: store.envelope.selectedSourceType == .importedSnapshot
                        ) {
                            store.switchSourceType(.importedSnapshot)
                        }
                    }
                }

                Section("Data management") {
                    Button("Import snapshot JSON", action: onImportSnapshot)
                    Button("Reload snapshot state") {
                        store.reloadSnapshots()
                    }
                    Text("Storage backend: \(store.storageModeLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Application state") {
                    Button("Reset app state", role: .destructive) {
                        store.resetAppState()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sourceRow(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SlidesHelpSheet: View {
    @Binding var feedbackDraft: String
    let onSendFeedback: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Common actions") {
                    helpRow(title: "Open and edit a deck", detail: "Tap a presentation card, then tap the selected slide again to enter edit mode.")
                    helpRow(title: "Manage a presentation", detail: "Use the deck menu or editor menu to share, rename, move, duplicate, star, or trash a deck.")
                    helpRow(title: "Switch workspace data", detail: "Open Settings to jump back to the default data or import a custom workspace snapshot.")
                }

                Section("Feedback") {
                    TextEditor(text: $feedbackDraft)
                        .frame(minHeight: 120)
                    Button("Save feedback draft", action: onSendFeedback)
                        .disabled(feedbackDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Help & feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func helpRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
