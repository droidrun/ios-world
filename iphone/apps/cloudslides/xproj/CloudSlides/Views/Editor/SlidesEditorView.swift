import SwiftUI

private enum SlidesCanvasElement {
    case title
    case body
    case none   // no element selected — hides the selection outline
}

private enum SlidesCanvasAlignment: CaseIterable {
    case leading
    case center
    case trailing

    var textAlignment: TextAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    var iconName: String {
        switch self {
        case .leading:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .trailing:
            return "text.alignright"
        }
    }
}

private enum SlidesCanvasFill: CaseIterable {
    case white
    case cream
    case mist

    var color: Color {
        switch self {
        case .white:
            return .white
        case .cream:
            return Color(red: 0.98, green: 0.96, blue: 0.89)
        case .mist:
            return Color(red: 0.94, green: 0.96, blue: 1.0)
        }
    }
}

private enum SlidesAccentStyle: CaseIterable {
    case ink
    case blue
    case coral

    var color: Color {
        switch self {
        case .ink:
            return .black
        case .blue:
            return Color(red: 0.17, green: 0.37, blue: 0.86)
        case .coral:
            return Color(red: 0.80, green: 0.23, blue: 0.18)
        }
    }
}

private struct SlidesTextSnapshot: Equatable {
    let slideId: String
    let title: String
    let body: String
}

private struct SlidesDeckSummary {
    let title: String
    let slideCount: Int
    let sectionTitles: [String]
    let highlightBullets: [String]
}

struct SlidesEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: SlidesActionCoordinator
    let fileId: String

    @State private var selectedSlideId = ""
    @State private var isEditingCanvas = false
    @State private var selectedElement: SlidesCanvasElement = .title
    @State private var showSearchSheet = false
    @State private var showCommentsSheet = false
    @State private var showPresenter = false
    @State private var showSummaryBanner = true
    @State private var showSummarySheet = false
    @State private var showQuickAssistSheet = false
    @State private var showEditMoreSheet = false
    @State private var slideSearchQuery = ""
    @State private var clipboard = ""
    @State private var undoStack: [SlidesTextSnapshot] = []
    @State private var redoStack: [SlidesTextSnapshot] = []
    @State private var boldSlideIds: Set<String> = []
    @State private var accentBySlideId: [String: SlidesAccentStyle] = [:]
    @State private var titleAlignmentBySlideId: [String: SlidesCanvasAlignment] = [:]
    @State private var bodyAlignmentBySlideId: [String: SlidesCanvasAlignment] = [:]
    @State private var fillBySlideId: [String: SlidesCanvasFill] = [:]

    private var viewModel: SlidesEditorViewModel {
        SlidesEditorViewModel(store: store, fileId: fileId)
    }

    private var file: WorkspaceFile? {
        viewModel.file
    }

    private var presentation: PresentationFile? {
        viewModel.presentation
    }

    private var slideIDs: [String] {
        presentation?.slides.map(\.id) ?? []
    }

    private var selectedSlide: SlidePage? {
        presentation?.slides.first(where: { $0.id == selectedSlideId }) ?? presentation?.slides.first
    }

    private var selectedSlideIndex: Int {
        presentation?.slides.firstIndex(where: { $0.id == selectedSlide?.id }) ?? 0
    }

    private var deckSummary: SlidesDeckSummary {
        buildDeckSummary()
    }

    var body: some View {
        Group {
            if let presentation, let file {
                ZStack {
                    Color(red: 0.11, green: 0.12, blue: 0.15)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        toolbar(file: file)
                        Divider()
                            .overlay(Color.white.opacity(0.16))

                        if isEditingCanvas {
                            editorCanvas(presentation: presentation)
                        } else {
                            presentationCanvas(presentation: presentation)
                        }
                    }
                }
                .overlay(alignment: .topLeading) {
                    TextField(
                        "",
                        text: Binding(
                            get: { file.name },
                            set: { store.updatePresentationTitle(fileId: fileId, title: $0) }
                        )
                    )
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .accessibilityIdentifier(AccessibilityID.slidesTitleField)
                }
                .sheet(isPresented: $showSearchSheet) {
                    SlidesSearchSheet(
                        query: $slideSearchQuery,
                        slides: presentation.slides,
                        onSelect: { slideId in
                            selectedSlideId = slideId
                            showSearchSheet = false
                        }
                    )
                }
                .sheet(isPresented: $showCommentsSheet) {
                    SlidesCommentsSheet(store: store, fileId: file.id)
                }
                .sheet(isPresented: $showSummarySheet) {
                    SlidesSummarySheet(
                        summary: deckSummary,
                        onInsertAgenda: insertAgendaSlide,
                        onInsertRecap: insertRecapSlide
                    )
                }
                .sheet(isPresented: $showQuickAssistSheet) {
                    SlidesQuickAssistSheet(
                        selectedSlideTitle: selectedSlide?.title ?? "Selected slide",
                        onCondenseSelectedSlide: condenseSelectedSlide,
                        onInsertAgendaSlide: insertAgendaSlide,
                        onInsertClosingSlide: insertClosingSlide
                    )
                }
                .sheet(isPresented: $showEditMoreSheet) {
                    SlidesEditMoreSheet(
                        canMoveUp: selectedSlideIndex > 0,
                        canMoveDown: selectedSlideIndex < max(0, (presentation.slides.count - 1)),
                        onMoveUp: moveSelectedSlideUp,
                        onMoveDown: moveSelectedSlideDown,
                        onDuplicateSlide: duplicateSelectedSlide,
                        onDeleteSlide: deleteSelectedSlide,
                        onSelectTitle: { selectedElement = .title },
                        onSelectBody: { selectedElement = .body }
                    )
                }
                .fullScreenCover(isPresented: $showPresenter) {
                    SlidesPresentationPlayerView(
                        fileName: file.name,
                        slides: presentation.slides,
                        selectedSlideIndex: selectedSlideIndex
                    )
                }
                .onAppear {
                    syncSelection(with: presentation)
                }
                .onChange(of: slideIDs) { _, _ in
                    syncSelection(with: presentation)
                }
            } else {
                EmptyStateCard(
                    title: "File unavailable",
                    message: "This presentation could not be loaded from the current workspace source.",
                    systemImage: "menucard.badge.questionmark",
                    accessibilityIdentifier: AccessibilityID.emptyState("slides_file_unavailable")
                )
                .padding()
            }
        }
    }

    private func toolbar(file: WorkspaceFile) -> some View {
        HStack(spacing: isEditingCanvas ? 24 : 28) {
            Button {
                if isEditingCanvas {
                    // Dismiss keyboard + system edit menu before leaving edit mode.
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    isEditingCanvas = false
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: isEditingCanvas ? "checkmark" : "chevron.left")
            }

            if isEditingCanvas {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(undoStack.isEmpty)

                Button(action: redo) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(redoStack.isEmpty)
            }

            Button {
                showPresenter = true
            } label: {
                Image(systemName: "play")
            }

            if isEditingCanvas {
                Button(action: cycleAccentStyle) {
                    Text("A")
                        .font(.system(size: 26, weight: .medium))
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(currentAccentStyle.color)
                                .frame(width: 30, height: 3)
                                .offset(y: 6)
                        }
                }

                Button {
                    let newId = store.addSlideAndReturnId(fileId: fileId)
                    selectedSlideId = newId ?? selectedSlideId
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier(AccessibilityID.slidesAddSlideButton)

                Button {
                    showEditMoreSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityIdentifier("slides_edit_more_button")
            } else {
                Button {
                    showSearchSheet = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                    coordinator.beginShare(file: file)
                } label: {
                    Image(systemName: "person.badge.plus")
                }

                Button {
                    showCommentsSheet = true
                } label: {
                    Image(systemName: "rectangle.text.bubble")
                }
            }

            Button {
                showQuickAssistSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "sparkles")
                    Circle()
                        .fill(Color(red: 0.56, green: 0.66, blue: 0.99))
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -4)
                }
            }

            Menu {
                Button("Rename") {
                    coordinator.beginRename(file: file)
                }
                Button("Move") {
                    coordinator.beginMove(file: file)
                }
                Button("Share") {
                    coordinator.beginShare(file: file)
                }
                Button(file.starred ? "Remove star" : "Star") {
                    store.toggleStar(itemId: file.id)
                }
                .accessibilityIdentifier(AccessibilityID.fileActionStar)
                Button("Duplicate presentation") {
                    _ = store.duplicateFile(id: file.id)
                }
                if let selectedSlide {
                    Button("Duplicate slide") {
                        selectedSlideId = store.duplicateSlideAndReturnId(fileId: fileId, slideId: selectedSlide.id) ?? selectedSlide.id
                        isEditingCanvas = true
                    }
                    .accessibilityIdentifier(AccessibilityID.slidesDuplicateSlideButton)

                    Button("Delete slide", role: .destructive) {
                        deleteSelectedSlide()
                    }
                    .accessibilityIdentifier(AccessibilityID.slidesDeleteSlideButton)
                }
                Button(file.trashed ? "Restore presentation" : "Move presentation to trash", role: file.trashed ? nil : .destructive) {
                    file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id)
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.25))
    }

    private func presentationCanvas(presentation: PresentationFile) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(Array(presentation.slides.enumerated()), id: \.element.id) { index, slide in
                    SlidesPresentationCanvasView(
                        slide: slide,
                        isSelected: slide.id == selectedSlide?.id,
                        titleColor: accentStyle(for: slide).color,
                        titleAlignment: titleAlignment(for: slide).textAlignment,
                        bodyAlignment: bodyAlignment(for: slide).textAlignment,
                        fillColor: fill(for: slide).color,
                        isBold: isBold(slide),
                        slideIndex: index
                    )
                    .onTapGesture {
                        if selectedSlideId == slide.id {
                            selectedElement = .title
                            isEditingCanvas = true
                        } else {
                            selectedSlideId = slide.id
                        }
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                selectedElement = .title
                isEditingCanvas = true
            } label: {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.96, green: 0.71, blue: 0.0))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "pencil")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.34), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.slidesEditButton)
            .padding(.trailing, 24)
            .padding(.bottom, showSummaryBanner ? 88 : 24)
        }
        .overlay(alignment: .bottom) {
            if showSummaryBanner {
                HStack(spacing: 14) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Summarize this presentation")
                        .font(.system(size: 18, weight: .medium))
                    Spacer()
                    Button {
                        showSummaryBanner = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .medium))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(Color.black.opacity(0.86), in: Capsule())
                .padding(.bottom, 20)
                .padding(.horizontal, 24)
                .onTapGesture {
                    showSummarySheet = true
                }
            }
        }
    }

    private func editorCanvas(presentation: PresentationFile) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 18)

            if let selectedSlide {
                // The SlidesEditContextMenu overlay (Cut/Copy/Paste/Delete)
                // was removed because it permanently obscured slide content
                // in editor mode, even when no text was selected. The same
                // operations are accessible via the system edit menu (long-
                // press a text field) and the formatting toolbar below.
                SlidesEditableCanvasView(
                    slide: selectedSlide,
                    title: titleBinding(for: selectedSlide),
                    bodyText: bodyBinding(for: selectedSlide),
                    selectedElement: selectedElement,
                    titleColor: accentStyle(for: selectedSlide).color,
                    titleAlignment: titleAlignment(for: selectedSlide),
                    bodyAlignment: bodyAlignment(for: selectedSlide),
                    fillColor: fill(for: selectedSlide).color,
                    isBold: isBold(selectedSlide),
                    selectTitle: { selectedElement = .title },
                    selectBody: { selectedElement = .body },
                    deselect: { selectedElement = .none }
                )
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }

            Spacer(minLength: 16)

            filmstrip(presentation: presentation)
            formattingToolbar
        }
    }

    private func filmstrip(presentation: PresentationFile) -> some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.12))

            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(presentation.slides.enumerated()), id: \.element.id) { index, slide in
                            SlidesThumbnailView(
                                slide: slide,
                                index: index + 1,
                                isSelected: slide.id == selectedSlide?.id,
                                onTap: {
                                    selectedSlideId = slide.id
                                },
                                onDuplicate: {
                                    selectedSlideId = store.duplicateSlideAndReturnId(fileId: fileId, slideId: slide.id) ?? slide.id
                                    isEditingCanvas = true
                                },
                                onDelete: {
                                    selectedSlideId = slide.id
                                    deleteSelectedSlide()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }

                Divider()
                    .overlay(Color.white.opacity(0.12))

                Button {
                    let newId = store.addSlideAndReturnId(fileId: fileId)
                    selectedSlideId = newId ?? selectedSlideId
                } label: {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 74, height: 74)
                        .overlay {
                            Image(systemName: "plus.rectangle.on.rectangle")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(.white)
                        }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .accessibilityIdentifier(AccessibilityID.slidesAddSlideButton)
            }
            .frame(height: 112)
            .background(Color(red: 0.17, green: 0.18, blue: 0.21))
        }
    }

    private var formattingToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.12))

            HStack(spacing: 0) {
                SlidesFormattingButton(
                    title: "B",
                    isActive: selectedSlide.map(isBold) ?? false,
                    action: toggleBold
                )

                Divider()
                    .overlay(Color.white.opacity(0.12))

                SlidesFormattingIconButton(
                    systemImage: "a.underline",
                    isActive: currentAccentStyle != .ink,
                    action: cycleAccentStyle
                )

                Divider()
                    .overlay(Color.white.opacity(0.12))

                SlidesFormattingIconButton(
                    systemImage: "pencil",
                    isActive: selectedElement == .body,
                    action: {
                        selectedElement = selectedElement == .title ? .body : .title
                    }
                )

                Divider()
                    .overlay(Color.white.opacity(0.12))

                SlidesFormattingIconButton(
                    systemImage: currentAlignment.iconName,
                    isActive: currentAlignment == .center,
                    action: cycleAlignment
                )

                Divider()
                    .overlay(Color.white.opacity(0.12))

                SlidesFormattingIconButton(
                    systemImage: "list.bullet",
                    isActive: selectedTextIsBulleted,
                    action: toggleBullets
                )

                Divider()
                    .overlay(Color.white.opacity(0.12))

                SlidesFormattingIconButton(
                    systemImage: "paintbrush",
                    isActive: currentFill != .white,
                    action: cycleCanvasFill
                )
            }
            .frame(height: 96)
            .background(Color(red: 0.21, green: 0.22, blue: 0.25))
        }
    }

    private func titleBinding(for slide: SlidePage) -> Binding<String> {
        Binding(
            get: { selectedSlide?.title ?? slide.title },
            set: { newValue in
                updateSelectedSlide(slideId: slide.id, title: newValue, body: nil)
            }
        )
    }

    private func bodyBinding(for slide: SlidePage) -> Binding<String> {
        Binding(
            get: { selectedSlide?.body ?? slide.body },
            set: { newValue in
                updateSelectedSlide(slideId: slide.id, title: nil, body: newValue)
            }
        )
    }

    private func updateSelectedSlide(slideId: String, title: String?, body: String?) {
        guard let currentSlide = presentation?.slides.first(where: { $0.id == slideId }) else {
            return
        }

        let nextTitle = title ?? currentSlide.title
        let nextBody = body ?? currentSlide.body
        guard nextTitle != currentSlide.title || nextBody != currentSlide.body else {
            return
        }

        pushUndo(snapshot: SlidesTextSnapshot(slideId: slideId, title: currentSlide.title, body: currentSlide.body))
        redoStack.removeAll()
        store.updateSlide(fileId: fileId, slideId: slideId, title: title, body: body)
    }

    private func pushUndo(snapshot: SlidesTextSnapshot) {
        guard undoStack.last != snapshot else {
            return
        }
        undoStack.append(snapshot)
    }

    private func undo() {
        guard let previous = undoStack.popLast(),
              let current = selectedSlide else {
            return
        }

        redoStack.append(SlidesTextSnapshot(slideId: current.id, title: current.title, body: current.body))
        selectedSlideId = previous.slideId
        store.updateSlide(fileId: fileId, slideId: previous.slideId, title: previous.title, body: previous.body)
    }

    private func redo() {
        guard let next = redoStack.popLast(),
              let current = selectedSlide else {
            return
        }

        undoStack.append(SlidesTextSnapshot(slideId: current.id, title: current.title, body: current.body))
        selectedSlideId = next.slideId
        store.updateSlide(fileId: fileId, slideId: next.slideId, title: next.title, body: next.body)
    }

    private func selectedText() -> String {
        guard let selectedSlide else {
            return ""
        }

        switch selectedElement {
        case .title:
            return selectedSlide.title
        case .body:
            return selectedSlide.body
        case .none:
            return ""
        }
    }

    private func copySelectedText() {
        clipboard = selectedText()
    }

    private func cutSelectedText() {
        clipboard = selectedText()
        clearSelectedText()
    }

    private func pasteSelectedText() {
        guard let selectedSlide, !clipboard.isEmpty, selectedElement != .none else {
            return
        }

        switch selectedElement {
        case .title:
            updateSelectedSlide(slideId: selectedSlide.id, title: clipboard, body: nil)
        case .body:
            updateSelectedSlide(slideId: selectedSlide.id, title: nil, body: clipboard)
        case .none:
            break
        }
    }

    private func clearSelectedText() {
        guard let selectedSlide, selectedElement != .none else {
            return
        }

        switch selectedElement {
        case .title:
            updateSelectedSlide(slideId: selectedSlide.id, title: "", body: nil)
        case .body:
            updateSelectedSlide(slideId: selectedSlide.id, title: nil, body: "")
        case .none:
            break
        }
    }

    private func deleteSelectedSlide() {
        guard let selectedSlide else {
            return
        }

        store.deleteSlide(fileId: fileId, slideId: selectedSlide.id)
        if let updatedPresentation = presentation {
            syncSelection(with: updatedPresentation)
        }
    }

    private func toggleBold() {
        guard let selectedSlide else {
            return
        }

        if boldSlideIds.contains(selectedSlide.id) {
            boldSlideIds.remove(selectedSlide.id)
        } else {
            boldSlideIds.insert(selectedSlide.id)
        }
    }

    private func isBold(_ slide: SlidePage) -> Bool {
        boldSlideIds.contains(slide.id)
    }

    private func accentStyle(for slide: SlidePage) -> SlidesAccentStyle {
        accentBySlideId[slide.id] ?? .ink
    }

    private var currentAccentStyle: SlidesAccentStyle {
        selectedSlide.map(accentStyle(for:)) ?? .ink
    }

    private func cycleAccentStyle() {
        guard let selectedSlide else {
            return
        }

        let all = SlidesAccentStyle.allCases
        let current = accentStyle(for: selectedSlide)
        guard let index = all.firstIndex(of: current) else {
            accentBySlideId[selectedSlide.id] = .ink
            return
        }
        accentBySlideId[selectedSlide.id] = all[(index + 1) % all.count]
    }

    private func titleAlignment(for slide: SlidePage) -> SlidesCanvasAlignment {
        titleAlignmentBySlideId[slide.id] ?? .center
    }

    private func bodyAlignment(for slide: SlidePage) -> SlidesCanvasAlignment {
        bodyAlignmentBySlideId[slide.id] ?? .center
    }

    private var currentAlignment: SlidesCanvasAlignment {
        guard let slide = selectedSlide else { return .center }
        return selectedElement == .title ? titleAlignment(for: slide) : bodyAlignment(for: slide)
    }

    private func cycleAlignment() {
        guard let selectedSlide else {
            return
        }

        let all = SlidesCanvasAlignment.allCases
        let current = currentAlignment
        guard let index = all.firstIndex(of: current) else {
            if selectedElement == .title {
                titleAlignmentBySlideId[selectedSlide.id] = .center
            } else {
                bodyAlignmentBySlideId[selectedSlide.id] = .center
            }
            return
        }
        let next = all[(index + 1) % all.count]
        if selectedElement == .title {
            titleAlignmentBySlideId[selectedSlide.id] = next
        } else {
            bodyAlignmentBySlideId[selectedSlide.id] = next
        }
    }

    private func fill(for slide: SlidePage) -> SlidesCanvasFill {
        fillBySlideId[slide.id] ?? .white
    }

    private var currentFill: SlidesCanvasFill {
        selectedSlide.map(fill(for:)) ?? .white
    }

    private func cycleCanvasFill() {
        guard let selectedSlide else {
            return
        }

        let all = SlidesCanvasFill.allCases
        let current = fill(for: selectedSlide)
        guard let index = all.firstIndex(of: current) else {
            fillBySlideId[selectedSlide.id] = .white
            return
        }
        fillBySlideId[selectedSlide.id] = all[(index + 1) % all.count]
    }

    private var selectedTextIsBulleted: Bool {
        guard let selectedSlide else {
            return false
        }

        let text = selectedElement == .title ? selectedSlide.title : selectedSlide.body
        let nonEmptyLines = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !nonEmptyLines.isEmpty else {
            return false
        }

        return nonEmptyLines.allSatisfy { $0.hasPrefix("• ") }
    }

    private func toggleBullets() {
        guard let selectedSlide else {
            return
        }

        let text = selectedElement == .title ? selectedSlide.title : selectedSlide.body
        let lines = text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return }

        let newText: String
        if selectedTextIsBulleted {
            newText = lines.map { line in
                line.hasPrefix("• ") ? String(line.dropFirst(2)) : line
            }
            .joined(separator: "\n")
        } else {
            newText = lines.map { "• \($0)" }.joined(separator: "\n")
        }

        if selectedElement == .title {
            updateSelectedSlide(slideId: selectedSlide.id, title: newText, body: nil)
        } else {
            updateSelectedSlide(slideId: selectedSlide.id, title: nil, body: newText)
        }
    }

    private func buildDeckSummary() -> SlidesDeckSummary {
        guard let presentation else {
            return SlidesDeckSummary(title: "Presentation", slideCount: 0, sectionTitles: [], highlightBullets: [])
        }

        let sectionTitles = presentation.slides.map(\.title).filter { !$0.isEmpty }
        let highlightBullets = presentation.slides
            .flatMap { slide in
                slide.body
                    .components(separatedBy: "\n")
                    .map { $0.replacingOccurrences(of: "• ", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            .filter { !$0.isEmpty }
            .prefix(4)
            .map { $0 }

        return SlidesDeckSummary(
            title: presentation.title,
            slideCount: presentation.slides.count,
            sectionTitles: Array(sectionTitles.prefix(6)),
            highlightBullets: Array(highlightBullets)
        )
    }

    private func insertAgendaSlide() {
        guard let presentation else {
            return
        }

        let titles = presentation.slides
            .map(\.title)
            .filter { !$0.isEmpty }
            .dropFirst()

        let body = titles.isEmpty
            ? "• Overview\n• Discussion\n• Next steps"
            : titles.map { "• \($0)" }.joined(separator: "\n")

        insertSlide(title: "Agenda", body: body, layout: .titleBody)
    }

    private func insertRecapSlide() {
        let summary = deckSummary
        let body = summary.highlightBullets.isEmpty
            ? "• \(summary.slideCount) slides reviewed\n• Themes organized for presentation\n• Ready for follow-up edits"
            : summary.highlightBullets.map { "• \($0)" }.joined(separator: "\n")

        insertSlide(title: "Presentation recap", body: body, layout: .titleBody)
    }

    private func insertClosingSlide() {
        insertSlide(title: "Next steps", body: "• Align on owners\n• Finalize revisions\n• Prepare follow-up notes", layout: .titleBody)
    }

    private func insertSlide(title: String, body: String, layout: SlideLayout) {
        guard let newId = store.addSlideAndReturnId(fileId: fileId) else {
            return
        }

        store.updateSlide(fileId: fileId, slideId: newId, title: title, body: body, layout: layout)
        selectedSlideId = newId
        isEditingCanvas = true
    }

    private func condenseSelectedSlide() {
        guard let selectedSlide else {
            return
        }

        let condensedLines = selectedSlide.body
            .components(separatedBy: "\n")
            .map { $0.replacingOccurrences(of: "• ", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line in
                line
                    .split(separator: " ")
                    .prefix(9)
                    .joined(separator: " ")
            }

        guard !condensedLines.isEmpty else {
            return
        }

        let newBody = condensedLines.map { "• \($0)" }.joined(separator: "\n")
        updateSelectedSlide(slideId: selectedSlide.id, title: nil, body: newBody)
    }

    private func duplicateSelectedSlide() {
        guard let selectedSlide else {
            return
        }

        selectedSlideId = store.duplicateSlideAndReturnId(fileId: fileId, slideId: selectedSlide.id) ?? selectedSlide.id
        isEditingCanvas = true
    }

    private func moveSelectedSlideUp() {
        guard let presentation,
              let selectedSlide,
              let index = presentation.slides.firstIndex(where: { $0.id == selectedSlide.id }),
              index > 0 else {
            return
        }

        store.moveSlide(fileId: fileId, fromIndex: index, toIndex: index - 1)
    }

    private func moveSelectedSlideDown() {
        guard let presentation,
              let selectedSlide,
              let index = presentation.slides.firstIndex(where: { $0.id == selectedSlide.id }),
              index < presentation.slides.count - 1 else {
            return
        }

        store.moveSlide(fileId: fileId, fromIndex: index, toIndex: index + 1)
    }

    private func syncSelection(with presentation: PresentationFile) {
        if let selected = presentation.slides.first(where: { $0.id == selectedSlideId }) {
            selectedSlideId = selected.id
        } else {
            selectedSlideId = presentation.slides.first?.id ?? ""
        }
    }
}

private struct SlidesPresentationCanvasView: View {
    let slide: SlidePage
    let isSelected: Bool
    let titleColor: Color
    let titleAlignment: TextAlignment
    let bodyAlignment: TextAlignment
    let fillColor: Color
    let isBold: Bool
    let slideIndex: Int

    private var bulletLines: [String] {
        slide.body
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var shouldShowImageStrip: Bool {
        let lowercasedTitle = slide.title.lowercased()
        return lowercasedTitle.contains("web agents") || lowercasedTitle.contains("autonomous")
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(fillColor)

                VStack(alignment: alignmentGuide, spacing: 18) {
                    if slide.layout == .titleOnly || slideIndex == 0 {
                        Spacer(minLength: 0)
                        Text(slide.title)
                            .font(.system(size: 34, weight: isBold ? .semibold : .regular))
                            .foregroundStyle(titleColor)
                            .multilineTextAlignment(titleAlignment)
                        Text(slide.body)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(bodyAlignment)
                        Spacer(minLength: 0)
                    } else {
                        Text(slide.title)
                            .font(.system(size: 22, weight: isBold ? .semibold : .regular))
                            .foregroundStyle(titleColor)
                            .multilineTextAlignment(titleAlignment)
                            .frame(maxWidth: .infinity, alignment: horizontalAlignment)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(bulletLines.enumerated()), id: \.offset) { _, line in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                    Text(line.replacingOccurrences(of: "• ", with: ""))
                                }
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if shouldShowImageStrip {
                            HStack(spacing: 18) {
                                SlideIllustrationPanel(accent: .blue)
                                SlideIllustrationPanel(accent: .orange)
                            }
                            .frame(height: 132)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, slide.layout == .titleOnly || slideIndex == 0 ? 54 : 28)
            }
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .stroke(isSelected ? Color(red: 0.67, green: 0.77, blue: 0.98) : .clear, lineWidth: 3)
            )
        }
        .padding(.horizontal, 2)
    }

    private var alignmentGuide: HorizontalAlignment {
        switch titleAlignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    private var horizontalAlignment: Alignment {
        switch titleAlignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}

private struct SlidesEditableCanvasView: View {
    let slide: SlidePage
    @Binding var title: String
    @Binding var bodyText: String
    let selectedElement: SlidesCanvasElement
    let titleColor: Color
    let titleAlignment: SlidesCanvasAlignment
    let bodyAlignment: SlidesCanvasAlignment
    let fillColor: Color
    let isBold: Bool
    let selectTitle: () -> Void
    let selectBody: () -> Void
    var deselect: (() -> Void)? = nil

    // Focus management — prevents the system cut/copy/paste menu from getting
    // stuck when the user switches elements or taps the canvas background.
    private enum Field { case title, body }
    @FocusState private var focusedField: Field?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(fillColor)
                    // Tap the canvas background to dismiss keyboard + selection.
                    .onTapGesture {
                        focusedField = nil
                        deselect?()
                    }

                VStack(spacing: 0) {
                    Spacer(minLength: slide.layout == .titleOnly ? 86 : 38)

                    Button(action: selectTitle) {
                        TextField("Slide title", text: $title, axis: .vertical)
                            .focused($focusedField, equals: .title)
                            .font(.system(size: slide.layout == .titleOnly ? 30 : 24, weight: isBold ? .semibold : .regular))
                            .foregroundStyle(titleColor)
                            .multilineTextAlignment(titleAlignment.textAlignment)
                            .lineLimit(4)
                            .textFieldStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.slidesSlideTitleField)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 26)

                    Spacer(minLength: slide.layout == .titleOnly ? 10 : 20)

                    Button(action: selectBody) {
                        TextField("Slide body", text: $bodyText, axis: .vertical)
                            .focused($focusedField, equals: .body)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(bodyAlignment.textAlignment)
                            .lineLimit(8)
                            .textFieldStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.slidesSlideBodyField)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, slide.layout == .titleOnly ? 84 : 26)

                    Spacer()
                }

                selectionOutline(in: geometry.size)
            }
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        // When the selected element changes externally (e.g. user taps title
        // in the parent), drive focus to match.
        .onChange(of: selectedElement) { _, newElement in
            switch newElement {
            case .title: focusedField = .title
            case .body: focusedField = .body
            case .none: focusedField = nil
            }
        }
    }

    private func selectionOutline(in size: CGSize) -> some View {
        let titleRect = CGRect(
            x: size.width * 0.01,
            y: slide.layout == .titleOnly ? size.height * 0.34 : size.height * 0.22,
            width: size.width * 0.98,
            height: slide.layout == .titleOnly ? size.height * 0.22 : size.height * 0.17
        )

        let bodyRect = CGRect(
            x: slide.layout == .titleOnly ? size.width * 0.24 : size.width * 0.06,
            y: slide.layout == .titleOnly ? size.height * 0.62 : size.height * 0.49,
            width: slide.layout == .titleOnly ? size.width * 0.52 : size.width * 0.88,
            height: slide.layout == .titleOnly ? size.height * 0.1 : size.height * 0.24
        )

        if selectedElement == .none {
            return AnyView(EmptyView())
        }

        let rect = selectedElement == .title ? titleRect : bodyRect

        return AnyView(ZStack {
            Rectangle()
                .stroke(Color(red: 0.24, green: 0.48, blue: 0.92), lineWidth: 3)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

            Circle()
                .fill(Color(red: 0.24, green: 0.48, blue: 0.92))
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .position(x: rect.midX, y: rect.minY - 26)

            Rectangle()
                .fill(Color(red: 0.24, green: 0.48, blue: 0.92))
                .frame(width: 4, height: 28)
                .position(x: rect.midX, y: rect.minY - 10)

            ForEach(Array(selectionPoints(for: rect).enumerated()), id: \.offset) { _, point in
                Rectangle()
                    .fill(Color(red: 0.24, green: 0.48, blue: 0.92))
                    .frame(width: 16, height: 16)
                    .overlay(Rectangle().stroke(.white, lineWidth: 2))
                    .position(point)
            }
        })
    }

    private func selectionPoints(for rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.midY),
            CGPoint(x: rect.maxX, y: rect.midY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
    }
}

private struct SlidesEditContextMenu: View {
    let onCut: () -> Void
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onDelete: () -> Void
    let onMore: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            button(title: "Cut", color: .white, action: onCut)
            divider
            button(title: "Copy", color: .white, action: onCopy)
            divider
            button(title: "Paste", color: .white, action: onPaste)
            divider
            button(title: "Delete", color: .red, action: onDelete)
            divider
            button(systemImage: "chevron.right", color: .white, action: onMore)
        }
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.82), in: Capsule())
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.14))
            .frame(width: 1, height: 52)
    }

    private func button(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(color)
            .frame(width: 92, height: 52)
    }

    private func button(systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 58, height: 52)
        }
    }
}

private struct SlidesThumbnailView: View {
    let slide: SlidePage
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                    VStack(spacing: 4) {
                        Text(slide.title)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(.black)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                        if !slide.body.isEmpty {
                            Text(slide.body)
                                .font(.system(size: 6, weight: .regular))
                                .foregroundStyle(.gray)
                                .lineLimit(2)
                        }
                    }
                    .padding(6)
                }
                .frame(width: 110, height: 74)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color(red: 0.24, green: 0.48, blue: 0.92) : Color.clear, lineWidth: 4)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.slidesThumbnail(index))
            .contextMenu {
                Button("Duplicate slide", action: onDuplicate)
                    .accessibilityIdentifier(AccessibilityID.slidesDuplicateSlideButton)
                Button("Delete slide", role: .destructive, action: onDelete)
                    .accessibilityIdentifier(AccessibilityID.slidesDeleteSlideButton)
            }

            Text("\(index)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
        }
    }
}

private struct SlidesFormattingButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(isActive ? .white : .white.opacity(0.84))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isActive ? Color(red: 0.13, green: 0.29, blue: 0.74) : .clear)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                )
        }
    }
}

private struct SlidesFormattingIconButton: View {
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.84))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isActive ? Color(red: 0.13, green: 0.29, blue: 0.74) : .clear)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                )
        }
    }
}

private struct SlidesSearchSheet: View {
    @Binding var query: String
    let slides: [SlidePage]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private var results: [SlidePage] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return slides
        }

        return slides.filter { slide in
            slide.title.lowercased().contains(normalized) ||
            slide.body.lowercased().contains(normalized)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search in presentation", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }

                Section("Slides") {
                    ForEach(results) { slide in
                        Button {
                            onSelect(slide.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(slide.title)
                                    .font(.headline)
                                Text(slide.body)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SlidesCommentsSheet: View {
    @ObservedObject var store: WorkspaceStore
    let fileId: String
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    private var file: WorkspaceFile? {
        store.file(id: fileId)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Add comment") {
                    TextEditor(text: $draft)
                        .frame(minHeight: 120)
                    Button("Post comment") {
                        store.addComment(fileId: fileId, body: draft)
                        draft = ""
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Thread") {
                    if let file, file.comments.isEmpty {
                        EmptyStateCard(
                            title: "No comments",
                            message: "Start the thread with a comment on this presentation.",
                            systemImage: "text.bubble",
                            accessibilityIdentifier: AccessibilityID.emptyState("slides_comments")
                        )
                        .listRowBackground(Color.clear)
                    } else if let file {
                        ForEach(file.comments) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(comment.authorName)
                                    .font(.headline)
                                Text(comment.body)
                                    .font(.body)
                                Text(AppFormatters.shortDateTime.string(from: comment.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        EmptyStateCard(
                            title: "Presentation unavailable",
                            message: "This presentation could not be loaded.",
                            systemImage: "text.bubble",
                            accessibilityIdentifier: AccessibilityID.emptyState("slides_comments_unavailable")
                        )
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SlidesSummarySheet: View {
    let summary: SlidesDeckSummary
    let onInsertAgenda: () -> Void
    let onInsertRecap: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(summary.title)
                            .font(.headline)
                        Text("\(summary.slideCount) slides in this presentation")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !summary.sectionTitles.isEmpty {
                    Section("Section titles") {
                        ForEach(Array(summary.sectionTitles.enumerated()), id: \.offset) { _, title in
                            Text(title)
                        }
                    }
                }

                if !summary.highlightBullets.isEmpty {
                    Section("Highlights") {
                        ForEach(Array(summary.highlightBullets.enumerated()), id: \.offset) { _, bullet in
                            Text(bullet)
                        }
                    }
                }

                Section("Actions") {
                    Button("Insert agenda slide") {
                        onInsertAgenda()
                        dismiss()
                    }
                    Button("Insert recap slide") {
                        onInsertRecap()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Presentation summary")
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
}

private struct SlidesQuickAssistSheet: View {
    let selectedSlideTitle: String
    let onCondenseSelectedSlide: () -> Void
    let onInsertAgendaSlide: () -> Void
    let onInsertClosingSlide: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Quick assist") {
                    Button("Condense “\(selectedSlideTitle)”") {
                        onCondenseSelectedSlide()
                        dismiss()
                    }
                    Button("Insert agenda slide") {
                        onInsertAgendaSlide()
                        dismiss()
                    }
                    Button("Insert closing slide") {
                        onInsertClosingSlide()
                        dismiss()
                    }
                }

                Section("What it does") {
                    Text("These actions apply preset content templates to the current deck.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Quick assist")
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
}

private struct SlidesEditMoreSheet: View {
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDuplicateSlide: () -> Void
    let onDeleteSlide: () -> Void
    let onSelectTitle: () -> Void
    let onSelectBody: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Slide actions") {
                    Button("Move slide up") {
                        onMoveUp()
                        dismiss()
                    }
                        .disabled(!canMoveUp)
                    Button("Move slide down") {
                        onMoveDown()
                        dismiss()
                    }
                        .disabled(!canMoveDown)
                    Button("Duplicate slide") {
                        onDuplicateSlide()
                        dismiss()
                    }
                    Button("Delete slide", role: .destructive) {
                        onDeleteSlide()
                        dismiss()
                    }
                }

                Section("Selection") {
                    Button("Select title box") {
                        onSelectTitle()
                        dismiss()
                    }
                    Button("Select body box") {
                        onSelectBody()
                        dismiss()
                    }
                }
            }
            .navigationTitle("More actions")
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
}

private struct SlidesPresentationPlayerView: View {
    let fileName: String
    let slides: [SlidePage]
    let selectedSlideIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var activeIndex = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $activeIndex) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    SlidesPresentationCanvasView(
                        slide: slide,
                        isSelected: false,
                        titleColor: .black,
                        titleAlignment: .center,
                        bodyAlignment: .center,
                        fillColor: .white,
                        isBold: false,
                        slideIndex: index
                    )
                    .padding(.horizontal, 12)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack {
                HStack {
                    Text(fileName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)

                Spacer()
            }
        }
        .onAppear {
            activeIndex = selectedSlideIndex
        }
    }
}

private struct SlideIllustrationPanel: View {
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.13))
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(accent.opacity(0.32), lineWidth: 1)
            Circle()
                .fill(accent.opacity(0.55))
                .frame(width: 56, height: 56)
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 1)
                .frame(width: 86, height: 86)
        }
    }
}
