import SwiftUI
import UIKit

private enum DocsEditorSheet: String, Identifiable {
    case formatting
    case comments
    case assist

    var id: String { rawValue }
}

struct DocumentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DocumentActionCoordinator
    let fileId: String

    @State private var isEditing = false
    @State private var isTextFocused = false
    @StateObject private var editorBridge = DocsTextEditorBridge()
    @State private var activeSheet: DocsEditorSheet?

    private var viewModel: DocumentEditorViewModel {
        DocumentEditorViewModel(store: store, fileId: fileId)
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { viewModel.document?.body ?? "" },
            set: { store.updateDocumentBody(fileId: fileId, body: $0) }
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DocsPalette.background
                    .ignoresSafeArea()

                if let file = viewModel.file, let document = viewModel.document {
                    VStack(spacing: 0) {
                        topBar(file: file, document: document, topInset: geometry.safeAreaInsets.top)

                        if isEditing {
                            DocsEditableTextView(
                                text: bodyBinding,
                                isFocused: $isTextFocused,
                                bridge: editorBridge,
                                formatting: document.formatting,
                                useLinkStyle: usesLinkStyle(document)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DocsPalette.background)
                        } else {
                            reader(document: document)
                                .overlay(alignment: .bottomTrailing) {
                                    floatingEditButton
                                        .padding(.trailing, 28)
                                        .padding(.bottom, 32)
                                }
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if isEditing {
                            keyboardToolbar(document: document)
                        } else {
                            readerTabStrip(document: document)
                        }
                    }
                    .onAppear {
                        if document.body == "Start typing here." {
                            beginEditing()
                        }
                    }
                } else {
                    EmptyStateCard(
                        title: "File unavailable",
                        message: "This document could not be loaded from the current workspace source.",
                        systemImage: "doc.badge.questionmark",
                        accessibilityIdentifier: AccessibilityID.emptyState("docs_file_unavailable")
                    )
                    .padding(24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            isTextFocused = false
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .formatting:
                DocsFormattingSheet(store: store, fileId: fileId)
            case .comments:
                DocsCommentsSheet(store: store, fileId: fileId)
            case .assist:
                DocsAssistSheet(store: store, fileId: fileId)
            }
        }
    }

    private func topBar(file: WorkspaceFile, document: DocumentFile, topInset: CGFloat) -> some View {
        HStack(spacing: 24) {
            if isEditing {
                Button {
                    isTextFocused = false
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isEditing = false
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(DocsPalette.accent)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                    editorTopAction(systemName: "arrow.uturn.backward") {
                        editorBridge.undo()
                    }
                    editorTopAction(systemName: "arrow.uturn.forward") {
                        editorBridge.redo()
                    }
                    editorTopAction(systemName: "plus") {
                        appendToBody("\n")
                    }
                    editorTopAction {
                        DocsATextIcon()
                    } action: {
                        activeSheet = .formatting
                    }
                    editorTopAction {
                        DocsSparkleIcon()
                    } action: {
                        activeSheet = .assist
                    }
                    moreMenu(file: file)
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                editorTopAction(systemName: "person.badge.plus") {
                    coordinator.beginShare(file: file)
                }
                editorTopAction(systemName: "message") {
                    activeSheet = .comments
                }
                editorTopAction {
                    DocsSparkleIcon()
                } action: {
                    activeSheet = .assist
                }
                moreMenu(file: file)
            }
        }
        .padding(.top, topInset + 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .background(DocsPalette.chrome)
    }

    private func reader(document: DocumentFile) -> some View {
        ScrollView(showsIndicators: false) {
            Text(document.body)
                .font(readerFont(for: document))
                .foregroundStyle(.white)
                .multilineTextAlignment(swiftUITextAlignment(for: document.formatting.alignment))
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: frameAlignment(for: document.formatting.alignment))
                .padding(.horizontal, 60)
                .padding(.top, 46)
                .padding(.bottom, 180)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DocsPalette.background)
    }

    private var floatingEditButton: some View {
        Button {
            beginEditing()
        } label: {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DocsPalette.chrome)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "pencil")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.34), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("docs_edit_button")
    }

    private func keyboardToolbar(document: DocumentFile) -> some View {
        HStack(spacing: 0) {
            keyboardAction {
                Text("@")
                    .font(.system(size: 23, weight: .medium))
            } action: {
                appendToBody("@")
            }

            keyboardDivider

            keyboardAction(isActive: document.formatting.bold) {
                Text("B")
                    .font(.system(size: 25, weight: .bold))
            } action: {
                store.updateDocumentFormatting(fileId: fileId, bold: !document.formatting.bold)
            }

            keyboardAction(isActive: document.formatting.italic) {
                Text("I")
                    .font(.system(size: 25, weight: .bold))
                    .italic()
            } action: {
                store.updateDocumentFormatting(fileId: fileId, italic: !document.formatting.italic)
            }

            keyboardAction(isActive: document.formatting.underline) {
                Text("U")
                    .font(.system(size: 25, weight: .medium))
                    .underline()
            } action: {
                store.updateDocumentFormatting(fileId: fileId, underline: !document.formatting.underline)
            }

            keyboardAction {
                DocsATextIcon()
                    .scaleEffect(0.86)
            } action: {
                activeSheet = .formatting
            }

            keyboardAction(isActive: document.formatting.suggestionModeEnabled) {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 22, weight: .medium))
            } action: {
                store.updateDocumentFormatting(fileId: fileId, suggestionMode: !document.formatting.suggestionModeEnabled)
            }

            keyboardDivider

            keyboardAction(isActive: document.formatting.listStyle != .none) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 24, weight: .medium))
            } action: {
                let next: DocumentListStyle = document.formatting.listStyle == .bullets ? .none : .bullets
                store.updateDocumentFormatting(fileId: fileId, listStyle: next)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 72)
        .background(DocsPalette.chrome)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var keyboardDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.18))
            .frame(width: 1, height: 46)
            .padding(.vertical, 13)
    }

    private func readerTabStrip(document: DocumentFile) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(DocsPalette.chrome)
                .frame(height: 142)

            HStack(spacing: 0) {
                readerTabButton(systemName: "person.badge.plus") {
                    coordinator.beginShare(file: viewModel.file!)
                }
                readerTabButton(systemName: "message") {
                    activeSheet = .comments
                }
                readerTabButton(systemName: "sparkles") {
                    activeSheet = .assist
                }
                readerTabButton(systemName: "textformat") {
                    activeSheet = .formatting
                }
            }
            .padding(.top, 22)
        }
    }

    private func readerTabButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.white.opacity(0.88))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .frame(height: 72)
    }

    private func moreMenu(file: WorkspaceFile) -> some View {
        Menu {
            Button("Share") {
                isTextFocused = false
                coordinator.beginShare(file: file)
            }
            Button(file.starred ? "Remove star" : "Star") {
                store.toggleStar(itemId: file.id)
            }
            Button("Rename") {
                // Dismiss the keyboard before presenting the rename sheet —
                // otherwise in edit mode the focused DocsEditableTextView keeps
                // the keyboard up and the sheet fails to surface above it.
                isTextFocused = false
                coordinator.beginRename(file: file)
            }
            Button("Move") {
                isTextFocused = false
                coordinator.beginMove(file: file)
            }
            Button("Duplicate") {
                _ = store.duplicateFile(id: file.id)
            }
            Button(file.trashed ? "Restore" : "Move to trash", role: file.trashed ? nil : .destructive) {
                file.trashed ? store.restoreItem(id: file.id) : store.trashItem(id: file.id)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 30)
        }
        .buttonStyle(.plain)
    }

    private func editorTopAction(systemName: String, action: @escaping () -> Void) -> some View {
        editorTopAction {
            Image(systemName: systemName)
                .font(.system(size: 27, weight: .regular))
                .foregroundStyle(.white)
        } action: {
            action()
        }
    }

    private func editorTopAction<Content: View>(
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            content()
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }

    private func keyboardAction<Content: View>(
        isActive: Bool = false,
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            content()
                .foregroundStyle(isActive ? DocsPalette.accent : .white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func beginEditing() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isEditing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isTextFocused = true
        }
    }

    private func appendToBody(_ suffix: String) {
        store.updateDocumentBody(fileId: fileId, body: bodyBinding.wrappedValue + suffix)
    }

    private func usesLinkStyle(_ document: DocumentFile) -> Bool {
        let trimmed = document.body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
    }

    private func readerFont(for document: DocumentFile) -> Font {
        switch document.formatting.paragraphStyle {
        case .normal:
            return .system(size: 28, weight: document.formatting.bold ? .semibold : .regular)
        case .heading:
            return .system(size: 32, weight: .semibold)
        case .subheading:
            return .system(size: 30, weight: .medium)
        case .title:
            return .system(size: 34, weight: .bold)
        }
    }

    private func swiftUITextAlignment(for alignment: DocumentAlignment) -> TextAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    private func frameAlignment(for alignment: DocumentAlignment) -> Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}

final class DocsTextEditorBridge: ObservableObject {
    weak var textView: UITextView?

    func undo() {
        textView?.undoManager?.undo()
    }

    func redo() {
        textView?.undoManager?.redo()
    }
}

private struct DocsATextIcon: View {
    var body: some View {
        VStack(spacing: 2) {
            Text("A")
                .font(.system(size: 23, weight: .medium))
            Rectangle()
                .fill(Color.white)
                .frame(width: 21, height: 2)
        }
        .foregroundStyle(.white)
    }
}

private struct DocsEditableTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @ObservedObject var bridge: DocsTextEditorBridge
    let formatting: DocumentFormattingState
    let useLinkStyle: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.keyboardAppearance = .dark
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .yes
        textView.smartDashesType = .yes
        textView.smartQuotesType = .yes
        textView.tintColor = DocsPalette.linkUIColor
        textView.textColor = DocsPalette.textUIColor
        textView.textContainerInset = UIEdgeInsets(top: 40, left: 60, bottom: 36, right: 60)
        textView.textContainer.lineFragmentPadding = 0
        textView.alwaysBounceVertical = true
        textView.showsVerticalScrollIndicator = false
        bridge.textView = textView
        context.coordinator.render(text, in: textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        bridge.textView = uiView
        if context.coordinator.shouldSync(text: text, in: uiView) {
            let selectedRange = uiView.selectedRange
            context.coordinator.render(text, in: uiView)
            uiView.selectedRange = context.coordinator.clamped(range: selectedRange, text: text)
        } else {
            uiView.typingAttributes = context.coordinator.typingAttributes
        }

        if isFocused, uiView.isFirstResponder == false {
            uiView.becomeFirstResponder()
        } else if isFocused == false, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: DocsEditableTextView
        private var renderedText = ""
        private var renderedSignature = ""

        init(_ parent: DocsEditableTextView) {
            self.parent = parent
        }

        var typingAttributes: [NSAttributedString.Key: Any] {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8
            paragraphStyle.alignment = textAlignment

            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: parent.useLinkStyle ? DocsPalette.linkUIColor : DocsPalette.textUIColor,
                .paragraphStyle: paragraphStyle
            ]

            if parent.formatting.underline || parent.useLinkStyle {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }

            return attributes
        }

        func shouldSync(text: String, in textView: UITextView) -> Bool {
            textView.text != text || signature != renderedSignature
        }

        func render(_ text: String, in textView: UITextView) {
            textView.attributedText = NSAttributedString(string: text, attributes: typingAttributes)
            textView.typingAttributes = typingAttributes
            renderedText = text
            renderedSignature = signature
        }

        func clamped(range: NSRange, text: String) -> NSRange {
            let length = NSString(string: text).length
            let location = min(range.location, length)
            let maxLength = max(0, length - location)
            return NSRange(location: location, length: min(range.length, maxLength))
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            renderedText = textView.text
            renderedSignature = signature
            textView.typingAttributes = typingAttributes
        }

        private var signature: String {
            [
                parent.formatting.paragraphStyle.rawValue,
                parent.formatting.alignment.rawValue,
                parent.formatting.bold.description,
                parent.formatting.italic.description,
                parent.formatting.underline.description,
                parent.useLinkStyle.description
            ].joined(separator: "|")
        }

        private var font: UIFont {
            let baseSize: CGFloat
            switch parent.formatting.paragraphStyle {
            case .normal:
                baseSize = 28
            case .heading:
                baseSize = 32
            case .subheading:
                baseSize = 30
            case .title:
                baseSize = 34
            }

            var traits: UIFontDescriptor.SymbolicTraits = []
            if parent.formatting.bold {
                traits.insert(.traitBold)
            }
            if parent.formatting.italic {
                traits.insert(.traitItalic)
            }

            let baseDescriptor = UIFont.systemFont(ofSize: baseSize, weight: .regular).fontDescriptor
            let descriptor = baseDescriptor.withSymbolicTraits(traits) ?? baseDescriptor
            return UIFont(descriptor: descriptor, size: baseSize)
        }

        private var textAlignment: NSTextAlignment {
            switch parent.formatting.alignment {
            case .leading:
                return .left
            case .center:
                return .center
            case .trailing:
                return .right
            }
        }
    }
}

private struct DocsFormattingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    let fileId: String

    private var document: DocumentFile? {
        store.document(id: fileId)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    formattingCard(title: "Paragraph style") {
                        ForEach(DocumentParagraphStyle.allCases) { style in
                            formattingRow(
                                title: style.title,
                                isSelected: document?.formatting.paragraphStyle == style
                            ) {
                                store.updateDocumentFormatting(fileId: fileId, paragraphStyle: style)
                            }
                            .accessibilityIdentifier("docs_format_paragraph_\(style.rawValue)")
                        }
                    }

                    formattingCard(title: "Alignment") {
                        ForEach(DocumentAlignment.allCases) { alignment in
                            formattingRow(
                                title: alignment.title,
                                isSelected: document?.formatting.alignment == alignment
                            ) {
                                store.updateDocumentFormatting(fileId: fileId, alignment: alignment)
                            }
                            .accessibilityIdentifier("docs_format_alignment_\(alignment.rawValue)")
                        }
                    }

                    formattingCard(title: "Text emphasis") {
                        formattingToggle(title: "Bold", isOn: document?.formatting.bold == true) {
                            guard let document else { return }
                            store.updateDocumentFormatting(fileId: fileId, bold: !document.formatting.bold)
                        }
                        .accessibilityIdentifier("docs_format_bold_toggle")

                        formattingToggle(title: "Italic", isOn: document?.formatting.italic == true) {
                            guard let document else { return }
                            store.updateDocumentFormatting(fileId: fileId, italic: !document.formatting.italic)
                        }
                        .accessibilityIdentifier("docs_format_italic_toggle")

                        formattingToggle(title: "Underline", isOn: document?.formatting.underline == true) {
                            guard let document else { return }
                            store.updateDocumentFormatting(fileId: fileId, underline: !document.formatting.underline)
                        }
                        .accessibilityIdentifier("docs_format_underline_toggle")
                    }
                }
                .padding(24)
            }
            .background(DocsPalette.background.ignoresSafeArea())
            .navigationTitle("Text format")
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

    private func formattingCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func formattingRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DocsPalette.accent)
                }
            }
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func formattingToggle(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                Spacer()
                Text(isOn ? "On" : "Off")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isOn ? DocsPalette.accent : DocsPalette.secondaryText)
            }
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

private struct DocsCommentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    let fileId: String

    @State private var draftComment = ""

    private var file: WorkspaceFile? {
        store.file(id: fileId)
    }

    private var comments: [FileComment] {
        (file?.comments ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Add a comment", text: $draftComment, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .padding(16)
                            .background(DocsPalette.searchSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .foregroundStyle(.white)

                        Button("Post comment") {
                            store.addComment(fileId: fileId, authorName: store.profile.displayName, body: draftComment)
                            draftComment = ""
                        }
                        .disabled(draftComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if comments.isEmpty {
                        Text("No comments yet.")
                            .font(.system(size: 18))
                            .foregroundStyle(DocsPalette.secondaryText)
                    } else {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(comment.authorName)
                                        .font(.system(size: 18, weight: .semibold))
                                    Spacer()
                                    Text(AppFormatters.shortDateTime.string(from: comment.createdAt))
                                        .font(.system(size: 14))
                                        .foregroundStyle(DocsPalette.secondaryText)
                                }
                                Text(comment.body)
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white.opacity(0.96))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                    }
                }
                .padding(24)
            }
            .background(DocsPalette.background.ignoresSafeArea())
            .navigationTitle(file?.name ?? "Comments")
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
}

private struct DocsAssistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkspaceStore
    let fileId: String

    private var document: DocumentFile? {
        store.document(id: fileId)
    }

    private var fileTitle: String {
        store.file(id: fileId)?.name ?? "Document"
    }

    private var suggestions: [(title: String, body: String)] {
        guard let document else { return [] }
        let lines = document.body
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let summarySource = lines.prefix(3).joined(separator: " ")
        let summary = """
        Summary
        This document captures the current status of \(fileTitle.lowercased()). \(summarySource)
        """

        let nextSteps = """
        Next steps
        - Review open items in \(fileTitle)
        - Confirm ownership and due dates
        - Publish the next revision after validation
        """

        let checklist = """
        Working checklist
        - Verify the latest edits
        - Flag anything that still needs feedback
        - Share the updated draft with collaborators
        """

        return [
            ("Insert summary", summary),
            ("Append next steps", nextSteps),
            ("Add checklist", checklist)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(suggestions, id: \.title) { suggestion in
                        VStack(alignment: .leading, spacing: 14) {
                            Text(suggestion.title)
                                .font(.system(size: 20, weight: .semibold))
                            Text(suggestion.body)
                                .font(.system(size: 16))
                                .foregroundStyle(DocsPalette.secondaryText)
                            Button("Append to document") {
                                if let document {
                                    store.updateDocumentBody(fileId: fileId, body: document.body + "\n\n" + suggestion.body)
                                }
                                dismiss()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(DocsPalette.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
                .padding(24)
            }
            .background(DocsPalette.background.ignoresSafeArea())
            .navigationTitle("Help me write")
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
}
