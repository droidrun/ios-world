import SwiftUI

struct CreatePostView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var postText: String = ""
    @State private var selectedAudience: String = "Anyone"
    @State private var showAudiencePicker: Bool = false
    @State private var showPhotoPicker: Bool = false
    // Single enum-driven presentation. SwiftUI does not reliably present a
    // sheet/alert/confirmationDialog from *inside* another sheet when several
    // such modifiers are stacked on the same view (presentation race). Drive
    // every secondary surface (schedule picker, "add to your post" menu, link
    // input, event picker) from ONE `.sheet(item:)` so each presents reliably.
    @State private var activeSheet: ComposeSheet? = nil
    @State private var selectedAttachments: [PostAttachment] = []
    @State private var scheduledDate: Date? = nil
    @State private var linkTitle: String = ""
    @State private var linkSubtitle: String = ""
    @State private var eventTitle: String = ""
    @State private var eventLocation: String = ""
    @State private var eventDate: Date = Date().addingTimeInterval(86_400)
    @FocusState private var isTextFieldFocused: Bool

    private enum ComposeSheet: String, Identifiable {
        case more
        case schedule
        case link
        case event
        var id: String { rawValue }
    }

    private var isPostEmpty: Bool {
        postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Author info
                HStack(spacing: 10) {
                    AvatarView(
                        name: appState.currentUser.fullName,
                        initials: appState.currentUser.avatarInitials,
                        topHex: appState.currentUser.avatarTopHex,
                        bottomHex: appState.currentUser.avatarBottomHex,
                        size: 40
                    )

                    Button {
                        showAudiencePicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedAudience)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText)
                        }
                    }
                    .accessibilityIdentifier("compose_audience_button")

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Text editor
                TextEditor(text: $postText)
                    .font(.system(size: 16))
                    .foregroundColor(LockedInTheme.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .focused($isTextFieldFocused)
                    .accessibilityIdentifier("compose_text_editor")
                    .overlay(alignment: .topLeading) {
                        if postText.isEmpty {
                            Text("What do you want to talk about?")
                                .font(.system(size: 16))
                                .foregroundColor(LockedInTheme.tertiaryText)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .allowsHitTesting(false)
                        }
                    }

                Spacer()

                // Schedule indicator
                if let date = scheduledDate {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(LockedInTheme.linkedInBlue)
                        Text("Scheduled for \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 13))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                        Spacer()
                        Button {
                            scheduledDate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(LockedInTheme.tertiaryText)
                        }
                        .accessibilityIdentifier("remove_schedule_indicator")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xE8F4FD))
                    .accessibilityIdentifier("schedule_indicator")
                }

                // Attachment previews
                if !selectedAttachments.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(selectedAttachments) { attachment in
                                composeAttachmentRow(attachment)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 160)
                }

                // Bottom toolbar
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 24) {
                        Button(action: { showPhotoPicker = true }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        .accessibilityIdentifier("compose_photo_button")

                        Button(action: { activeSheet = .event }) {
                            Image(systemName: "calendar")
                                .font(.system(size: 20))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        .accessibilityIdentifier("compose_calendar_button")

                        Button(action: { activeSheet = .more }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        .accessibilityIdentifier("compose_more_button")

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .confirmationDialog("Who can see your post?", isPresented: $showAudiencePicker, titleVisibility: .visible) {
                Button("Anyone") { selectedAudience = "Anyone" }
                Button("Connections only") { selectedAudience = "Connections only" }
                Button("Group members") { selectedAudience = "Group members" }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Choose a photo", isPresented: $showPhotoPicker, titleVisibility: .visible) {
                Button("Team meeting photo") { addPhotoAttachment("Team meeting photo") }
                Button("Office workspace") { addPhotoAttachment("Office workspace") }
                Button("Conference presentation") { addPhotoAttachment("Conference presentation") }
                Button("Product launch event") { addPhotoAttachment("Product launch event") }
                Button("Team celebration") { addPhotoAttachment("Team celebration") }
                Button("Whiteboard brainstorm") { addPhotoAttachment("Whiteboard brainstorm") }
                Button("Cancel", role: .cancel) {}
            }
            // fullScreenCover (rather than .sheet) is used for these secondary
            // surfaces because presenting a *sheet from within a sheet*
            // (CreatePostView is itself presented as a sheet from RootTabView)
            // is unreliable in SwiftUI — it frequently dismisses the parent
            // compose sheet instead of presenting the child. fullScreenCover
            // presents reliably from inside a sheet.
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .more:
                    moreAttachmentsSheet
                case .schedule:
                    schedulePickerSheet
                case .link:
                    linkInputSheet
                case .event:
                    eventPickerSheet
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(LockedInTheme.primaryText)
                    }
                    .accessibilityIdentifier("compose_dismiss_button")
                }

                // Two SEPARATE ToolbarItems (not one HStack) so the clock and
                // Post buttons each get their own hit-testable accessibility
                // frame — when both lived inside a single ToolbarItem HStack the
                // accessibility-id tap on the clock resolved to the combined
                // frame and triggered the adjacent Post button instead
                // (publishing + dismissing the composer).
                // The ONLY "Schedule" affordance: the clock opens the schedule
                // picker (configure when the post should go out). Give it an
                // explicit accessibility label so it reads as "Schedule post"
                // and is never confused with the commit button below.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { activeSheet = .schedule }) {
                        Image(systemName: "clock")
                            .font(.system(size: 18))
                            .foregroundColor(scheduledDate != nil ? LockedInTheme.linkedInBlue : LockedInTheme.secondaryText)
                    }
                    .accessibilityIdentifier("compose_schedule_clock_button")
                    .accessibilityLabel("Schedule post")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if !isPostEmpty {
                            appState.createPost(
                                content: postText,
                                attachments: selectedAttachments,
                                scheduledDate: scheduledDate
                            )
                            postText = ""
                            selectedAttachments = []
                            scheduledDate = nil
                            dismiss()
                        }
                    } label: {
                        // The commit button is always labeled "Post" — a single,
                        // unambiguous primary action. It used to flip to
                        // "Schedule" when a date was set, which produced TWO
                        // controls reading "Schedule" (this button + the clock)
                        // and made it easy to publish/schedule by accident. The
                        // schedule_indicator chip already communicates the
                        // scheduled state, so the commit verb stays stable.
                        Text("Post")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isPostEmpty ? LockedInTheme.tertiaryText : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isPostEmpty ? Color(hex: 0xE8E8E8) : LockedInTheme.linkedInBlue)
                            )
                    }
                    .disabled(isPostEmpty)
                    .accessibilityIdentifier("compose_post_button")
                    .accessibilityLabel("Post")
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    // MARK: - Schedule Picker Sheet

    private var schedulePickerSheet: some View {
        NavigationStack {
            Form {
                Section("Schedule for later") {
                    DatePicker(
                        "Date & Time",
                        selection: Binding(
                            get: { scheduledDate ?? Date().addingTimeInterval(3600) },
                            set: { scheduledDate = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("schedule_date_picker")
                }

                if scheduledDate != nil {
                    Section {
                        Button("Remove schedule") {
                            scheduledDate = nil
                            activeSheet = nil
                        }
                        .foregroundColor(.red)
                        .accessibilityIdentifier("remove_schedule_button")
                    }
                }
            }
            .navigationTitle("Schedule Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Tapping Done with no prior interaction should still
                        // mark the post as scheduled (the picker's binding only
                        // writes scheduledDate when the wheel is touched).
                        if scheduledDate == nil {
                            scheduledDate = Date().addingTimeInterval(3600)
                        }
                        activeSheet = nil
                    }
                    .accessibilityIdentifier("schedule_done_button")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        activeSheet = nil
                    }
                    .accessibilityIdentifier("schedule_cancel_button")
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - "Add to your post" Menu Sheet

    private var moreAttachmentsSheet: some View {
        NavigationStack {
            List {
                Button {
                    activeSheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showPhotoPicker = true
                    }
                } label: {
                    Label("Add a photo", systemImage: "photo.on.rectangle")
                }
                .accessibilityIdentifier("compose_more_add_photo_button")

                Button {
                    addDocumentAttachment()
                    activeSheet = nil
                } label: {
                    Label("Add a document", systemImage: "doc.richtext")
                }
                .accessibilityIdentifier("compose_more_add_document_button")

                NavigationLink {
                    linkFormContent
                } label: {
                    Label("Add a link", systemImage: "link")
                }
                .accessibilityIdentifier("compose_more_add_link_button")
            }
            .navigationTitle("Add to your post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { activeSheet = nil }
                        .accessibilityIdentifier("compose_more_cancel_button")
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Link Input

    /// Shared link form, used both as the destination pushed from the
    /// "Add to your post" menu (so `compose_more_add_link_button` →
    /// `link_title_field` stays inside ONE presented sheet) and as the
    /// standalone link sheet.
    private var linkFormContent: some View {
        Form {
            Section("Add a link") {
                TextField("Link title", text: $linkTitle)
                    .accessibilityIdentifier("link_title_field")
                TextField("URL or description", text: $linkSubtitle)
                    .accessibilityIdentifier("link_subtitle_field")
            }
        }
        .navigationTitle("Add a link")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    if !linkTitle.isEmpty {
                        let attachment = PostAttachment(
                            id: "attach_\(Int(Date().timeIntervalSince1970))_\(Int.random(in: 1000...9999))",
                            attachmentType: .link,
                            title: linkTitle,
                            subtitle: linkSubtitle.isEmpty ? "External link" : linkSubtitle
                        )
                        selectedAttachments.append(attachment)
                    }
                    linkTitle = ""
                    linkSubtitle = ""
                    activeSheet = nil
                }
                .accessibilityIdentifier("link_add_button")
            }
        }
    }

    private var linkInputSheet: some View {
        NavigationStack {
            linkFormContent
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            linkTitle = ""
                            linkSubtitle = ""
                            activeSheet = nil
                        }
                        .accessibilityIdentifier("link_cancel_button")
                    }
                }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Event Picker Sheet

    private var eventPickerSheet: some View {
        NavigationStack {
            Form {
                Section("Event details") {
                    TextField("Event name", text: $eventTitle)
                        .accessibilityIdentifier("event_title_field")
                    TextField("Location", text: $eventLocation)
                        .accessibilityIdentifier("event_location_field")
                    DatePicker(
                        "Date & Time",
                        selection: $eventDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("event_date_picker")
                }
            }
            .navigationTitle("Add an event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let title = eventTitle.isEmpty ? "Event" : eventTitle
                        let subtitle = eventLocation.isEmpty
                            ? eventDate.formatted(date: .abbreviated, time: .shortened)
                            : "\(eventLocation) · \(eventDate.formatted(date: .abbreviated, time: .shortened))"
                        let attachment = PostAttachment(
                            id: "attach_\(Int(Date().timeIntervalSince1970))_\(Int.random(in: 1000...9999))",
                            attachmentType: .event,
                            title: title,
                            subtitle: subtitle
                        )
                        selectedAttachments.append(attachment)
                        eventTitle = ""
                        eventLocation = ""
                        activeSheet = nil
                    }
                    .accessibilityIdentifier("event_add_button")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { activeSheet = nil }
                        .accessibilityIdentifier("event_cancel_button")
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Compose Attachment Row

    private func composeAttachmentRow(_ attachment: PostAttachment) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(attachmentTint(attachment.attachmentType))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: attachmentIcon(attachment.attachmentType))
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                Text(attachment.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(LockedInTheme.secondaryText)
            }

            Spacer()

            Button {
                selectedAttachments.removeAll { $0.id == attachment.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(LockedInTheme.tertiaryText)
            }
            .accessibilityIdentifier("remove_attachment_\(attachment.id)")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: 0xF3F2EF))
        )
        .accessibilityIdentifier("compose_attachment_\(attachment.id)")
    }

    // MARK: - Helpers

    private func addPhotoAttachment(_ description: String) {
        let attachment = PostAttachment(
            id: "attach_\(Int(Date().timeIntervalSince1970))_\(Int.random(in: 1000...9999))",
            attachmentType: .photo,
            title: description,
            subtitle: "Stock photo"
        )
        selectedAttachments.append(attachment)
    }

    private func addDocumentAttachment() {
        let docs = [
            ("Q1 Performance Report.pdf", "PDF Document - 2.4 MB"),
            ("Project Roadmap 2026.pdf", "PDF Document - 1.8 MB"),
            ("Technical Architecture.pdf", "PDF Document - 3.1 MB"),
        ]
        let doc = docs[Int.random(in: 0..<docs.count)]
        let attachment = PostAttachment(
            id: "attach_\(Int(Date().timeIntervalSince1970))_\(Int.random(in: 1000...9999))",
            attachmentType: .document,
            title: doc.0,
            subtitle: doc.1
        )
        selectedAttachments.append(attachment)
    }

    private func attachmentIcon(_ type: PostAttachmentType) -> String {
        switch type {
        case .photo: return "photo.fill"
        case .document: return "doc.richtext.fill"
        case .link: return "link"
        case .event: return "calendar"
        }
    }

    private func attachmentTint(_ type: PostAttachmentType) -> Color {
        switch type {
        case .photo: return Color(hex: 0x0A66C2)
        case .document: return Color(hex: 0xCC1016)
        case .link: return Color(hex: 0x057642)
        case .event: return Color(hex: 0xB24020)
        }
    }
}
