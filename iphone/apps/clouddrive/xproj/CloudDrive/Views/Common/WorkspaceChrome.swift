import SwiftUI

struct SourceModeBannerView: View {
    let sourceType: WorkspaceSourceType
    let metadata: WorkspaceSnapshotMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(sourceType.title, systemImage: sourceType == .seeded ? "externaldrive" : "shippingbox")
                    .font(.headline)
                Spacer()
                Text(sourceType.shortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                    .accessibilityIdentifier(AccessibilityID.sourceBadge(sourceType))
            }

            if let metadata {
                Text(metadata.providerLabel)
                    .font(.subheadline.weight(.semibold))
                Text(metadata.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Updated \(AppFormatters.shortDateTime.string(from: metadata.snapshotTimestamp))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Using the built-in workspace.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String
    let systemImage: String
    let accessibilityIdentifier: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct MetadataChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill), in: Capsule())
    }
}

struct RenameItemSheet: View {
    let title: String
    @Binding var name: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier(AccessibilityID.fileActionRename)
                }
            }
        }
    }
}

struct CreateFolderSheet: View {
    @Binding var folderName: String
    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Folder name", text: $folderName)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: onCreate)
                        .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct MoveItemSheet: View {
    let destinations: [WorkspaceFolder]
    @Binding var selection: String
    let onCancel: () -> Void
    let onMove: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selection = ""
                } label: {
                    HStack {
                        Label("My Drive", systemImage: "house")
                        Spacer()
                        if selection.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("drive_move_destination_root")

                ForEach(destinations) { folder in
                    Button {
                        selection = folder.id
                    } label: {
                        HStack {
                            Label(folder.name, systemImage: "folder")
                            Spacer()
                            if selection == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.folderRow(folder.name))
                }
            }
            .navigationTitle("Move")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Move", action: onMove)
                        .accessibilityIdentifier(AccessibilityID.fileActionMove)
                }
            }
        }
    }
}

struct ShareSettingsSheet: View {
    @Binding var peopleText: String
    @Binding var role: AccessRole
    @Binding var visibility: SharedLinkVisibility
    let contacts: [WorkspaceContact]
    let linkDescription: String
    let onCancel: () -> Void
    let onCopyLink: (() -> Void)?
    let onSave: () -> Void

    init(
        peopleText: Binding<String>,
        role: Binding<AccessRole>,
        visibility: Binding<SharedLinkVisibility>,
        contacts: [WorkspaceContact] = [],
        linkDescription: String = "clouddrive.example",
        onCancel: @escaping () -> Void,
        onCopyLink: (() -> Void)? = nil,
        onSave: @escaping () -> Void
    ) {
        _peopleText = peopleText
        _role = role
        _visibility = visibility
        self.contacts = contacts
        self.linkDescription = linkDescription
        self.onCancel = onCancel
        self.onCopyLink = onCopyLink
        self.onSave = onSave
    }

    private var currentQuery: String {
        let last = peopleText.components(separatedBy: ",").last ?? ""
        return last.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var alreadyAdded: Set<String> {
        let parts = peopleText.components(separatedBy: ",").dropLast()
        return Set(parts.map { $0.trimmingCharacters(in: .whitespaces).lowercased() })
    }

    private var filteredContacts: [WorkspaceContact] {
        guard !currentQuery.isEmpty else { return [] }
        return contacts.filter { contact in
            let dominated = alreadyAdded.contains(contact.email.lowercased()) || alreadyAdded.contains(contact.name.lowercased())
            if dominated { return false }
            return contact.name.lowercased().contains(currentQuery) || contact.email.lowercased().contains(currentQuery)
        }
    }

    private func addContact(_ contact: WorkspaceContact) {
        var parts = peopleText.components(separatedBy: ",").dropLast().map { $0.trimmingCharacters(in: .whitespaces) }
        parts.append(contact.email)
        peopleText = parts.joined(separator: ", ") + ", "
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("People with access") {
                    TextField("Comma-separated names", text: $peopleText)
                        .textInputAutocapitalization(.words)

                    ForEach(filteredContacts) { contact in
                        Button {
                            addContact(contact)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.subheadline)
                                Text(contact.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Role") {
                    Picker("Role", selection: $role) {
                        ForEach(AccessRole.allCases) { role in
                            Text(role.title).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Link settings") {
                    Picker("Visibility", selection: $visibility) {
                        ForEach(SharedLinkVisibility.allCases) { visibility in
                            Text(visibility.title).tag(visibility)
                        }
                    }
                    .pickerStyle(.inline)

                    LabeledContent("Drive link") {
                        Text(linkDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }

                    if let onCopyLink {
                        Button("Copy link", action: onCopyLink)
                    }
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onSave)
                }
            }
        }
    }
}

struct DriveToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(DrivePalette.primaryText)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(DrivePalette.chrome.opacity(0.96))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
    }
}

enum DrivePalette {
    static let backgroundTop = Color(red: 0.09, green: 0.10, blue: 0.12)
    static let backgroundBottom = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let chrome = Color(red: 0.16, green: 0.17, blue: 0.20)
    static let listSurface = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let drawer = Color(red: 0.20, green: 0.21, blue: 0.24)
    static let divider = Color.white.opacity(0.16)
    static let primaryText = Color.white.opacity(0.95)
    static let secondaryText = Color.white.opacity(0.60)
    static let tertiaryText = Color.white.opacity(0.42)
    static let accent = Color(red: 0.04, green: 0.40, blue: 0.67)
    static let accentText = Color(red: 0.73, green: 0.83, blue: 1.00)
    static let chipBorder = Color.white.opacity(0.22)
    static let floatingButton = Color(red: 0.20, green: 0.21, blue: 0.25).opacity(0.94)
    static let avatar = Color(red: 0.52, green: 0.14, blue: 0.72)
    static let storageBar = Color(red: 0.93, green: 0.81, blue: 0.38)
}

struct DriveSearchPill: View {
    let title: String
    let profileInitial: String
    let onMenu: () -> Void
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onMenu) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(DrivePalette.primaryText)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)

            Button(action: onSearch) {
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(DrivePalette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ZStack {
                Circle()
                    .fill(DrivePalette.avatar)
                Circle()
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1.5)
                Text(profileInitial)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(DrivePalette.chrome)
        )
    }
}

struct DriveTopTabs: View {
    let titles: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                Button {
                    onSelect(index)
                } label: {
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(index == selectedIndex ? DrivePalette.accentText : DrivePalette.primaryText.opacity(0.78))
                            .frame(maxWidth: .infinity)

                        Capsule()
                            .fill(index == selectedIndex ? DrivePalette.accentText : .clear)
                            .frame(width: 118, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DriveSortHeader: View {
    let title: String
    let ascending: Bool
    let isGridLayout: Bool
    let sortOptions: [WorkspaceSortOption]
    let selectSort: (WorkspaceSortOption) -> Void
    let sortAction: () -> Void
    let layoutAction: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Menu {
                    ForEach(sortOptions) { option in
                        Button(option.title) {
                            selectSort(option)
                        }
                    }
                } label: {
                    Text(title)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(DrivePalette.primaryText)
                }
                .accessibilityIdentifier("drive_sort_filter_control")

                Button(action: sortAction) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.23, green: 0.29, blue: 0.40))
                        Image(systemName: ascending ? "arrow.up" : "arrow.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DrivePalette.accentText)
                    }
                    .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("drive_sort_direction_button")
            }

            Spacer()

            Button(action: layoutAction) {
                Image(systemName: isGridLayout ? "list.bullet" : "square.grid.3x3.fill")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(DrivePalette.secondaryText)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }
}

struct DriveFloatingActions: View {
    let onScan: () -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Button(action: onScan) {
                ZStack {
                    Circle()
                        .fill(DrivePalette.floatingButton)
                    Image(systemName: "viewfinder")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DrivePalette.accentText)
                }
                .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("drive_scan_button")

            Button(action: onCreate) {
                ZStack {
                    Circle()
                        .fill(DrivePalette.floatingButton)
                    DrivePlusGlyph()
                }
                .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("drive_new_button")
        }
        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 12)
    }
}

private struct DrivePlusGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.96, green: 0.77, blue: 0.15))
                .frame(width: 8, height: 28)
                .offset(y: 7)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.09, green: 0.63, blue: 0.29))
                .frame(width: 8, height: 28)
                .offset(y: -7)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.89, green: 0.26, blue: 0.22))
                .frame(width: 28, height: 8)
                .offset(x: -7)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.20, green: 0.48, blue: 0.96))
                .frame(width: 28, height: 8)
                .offset(x: 7)
        }
        .rotationEffect(.degrees(90))
    }
}

struct DriveDrawerItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let action: () -> Void
}

struct DriveDrawerPanel: View {
    let storageUsedGB: Double
    let storageLimitGB: Double
    let items: [DriveDrawerItem]

    private var usageFraction: Double {
        guard storageLimitGB > 0 else { return 0 }
        return min(max(storageUsedGB / storageLimitGB, 0), 1)
    }

    private var usagePercentText: String {
        "\(Int((usageFraction * 100).rounded()))%"
    }

    private var usageDetailText: String {
        String(format: "%.2f GB of %.0f GB used", storageUsedGB, storageLimitGB)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CloudDrive")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(DrivePalette.primaryText)
                .padding(.top, 40)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

            Rectangle()
                .fill(DrivePalette.divider)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index == 6 {
                        Rectangle()
                            .fill(DrivePalette.divider)
                            .frame(height: 1)
                            .padding(.vertical, 10)
                    }

                    Button(action: item.action) {
                        HStack(spacing: 22) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 21, weight: .regular))
                                .foregroundStyle(DrivePalette.primaryText)
                                .frame(width: 24)
                            Text(item.title)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(DrivePalette.primaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 22) {
                    Image(systemName: "icloud")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(DrivePalette.primaryText)
                        .frame(width: 24)
                    Text("Storage (\(usagePercentText))")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(DrivePalette.primaryText)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                        Capsule()
                            .fill(DrivePalette.storageBar)
                            .frame(width: geometry.size.width * usageFraction)
                    }
                }
                .frame(height: 10)

                Text(usageDetailText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DrivePalette.secondaryText)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DrivePalette.drawer)
    }
}

struct DriveSharedDrivesEmptyState: View {
    var body: some View {
        VStack(spacing: 26) {
            DriveSharedDrivesIllustration()
                .frame(width: 430, height: 430)

            VStack(spacing: 14) {
                Text("No shared drives")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(DrivePalette.primaryText)

                Text("When someone adds you to a shared drive, you'll\nsee it listed here.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(DrivePalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 640)
        .padding(.top, 76)
        .padding(.horizontal, 24)
    }
}

private struct DriveSharedDrivesIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.47, green: 0.74, blue: 0.92))
                .frame(width: 272, height: 206)
                .offset(x: 26, y: -38)

            HStack(spacing: 24) {
                Image(systemName: "doc")
                Image(systemName: "doc")
                Image(systemName: "folder")
            }
            .font(.system(size: 44, weight: .regular))
            .foregroundStyle(Color.black.opacity(0.75))
            .offset(x: 24, y: -60)

            DriveIllustratedPerson(
                shirt: Color.white.opacity(0.92),
                pants: Color(red: 0.93, green: 0.82, blue: 0.53),
                accent: Color(red: 0.79, green: 0.52, blue: 0.23),
                mirrored: false
            )
            .offset(x: -54, y: 68)

            DriveIllustratedPerson(
                shirt: Color.white.opacity(0.92),
                pants: Color(red: 0.89, green: 0.70, blue: 0.70),
                accent: Color(red: 0.44, green: 0.82, blue: 0.54),
                mirrored: true
            )
            .offset(x: 76, y: 92)

            Rectangle()
                .fill(Color(red: 0.49, green: 0.79, blue: 1.0))
                .frame(width: 420, height: 3)
                .offset(y: 154)
        }
    }
}

private struct DriveIllustratedPerson: View {
    let shirt: Color
    let pants: Color
    let accent: Color
    let mirrored: Bool

    var body: some View {
        VStack(spacing: -8) {
            Circle()
                .fill(Color(red: 0.19, green: 0.20, blue: 0.24))
                .frame(width: 46, height: 46)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color(red: 0.79, green: 0.52, blue: 0.23))
                        .frame(width: 16, height: 16)
                }

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(shirt)
                .frame(width: 108, height: 126)
                .rotationEffect(.degrees(mirrored ? 18 : -18))

            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(pants)
                    .frame(width: 38, height: 116)
                    .rotationEffect(.degrees(mirrored ? -8 : 8))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(pants)
                    .frame(width: 38, height: 116)
                    .rotationEffect(.degrees(mirrored ? 10 : -10))
            }

            HStack(spacing: 22) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 42, height: 20)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 42, height: 20)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accent)
                .frame(width: 54, height: 48)
                .offset(x: mirrored ? -8 : 18, y: 56)
        }
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
    }
}

struct DriveSectionHeading: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(DrivePalette.secondaryText)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

struct DriveQuickAccessCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.18))
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DrivePalette.primaryText)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DrivePalette.secondaryText)
                        .lineLimit(3)
                }
            }
            .padding(16)
            .frame(width: 194, height: 170, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

enum DriveScanPreset: String, CaseIterable, Identifiable {
    case meetingNotes
    case receipt
    case signedAgreement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meetingNotes:
            return "Meeting Notes"
        case .receipt:
            return "Expense Receipt"
        case .signedAgreement:
            return "Signed Agreement"
        }
    }

    var subtitle: String {
        switch self {
        case .meetingNotes:
            return "Clean scan with a short summary and action items."
        case .receipt:
            return "Single-page receipt formatted for quick filing."
        case .signedAgreement:
            return "Multi-page contract with signature pages."
        }
    }

    var suggestedName: String {
        switch self {
        case .meetingNotes:
            return "Scanned Meeting Notes"
        case .receipt:
            return "Expense Receipt"
        case .signedAgreement:
            return "Signed Agreement"
        }
    }

    var suggestedSize: String {
        switch self {
        case .meetingNotes:
            return "620 KB"
        case .receipt:
            return "1.1 MB"
        case .signedAgreement:
            return "2.4 MB"
        }
    }

    var sampleBody: String {
        switch self {
        case .meetingNotes:
            return """
            Scanned notes

            Team sync
            - confirm launch timeline
            - assign review owners
            - publish support checklist
            """
        case .receipt:
            return """
            Expense receipt

            Merchant: North Market Cafe
            Total: $48.90
            Category: Team lunch
            """
        case .signedAgreement:
            return """
            Signed agreement

            Vendor services addendum
            Effective date: March 4, 2026
            Signature pages attached
            """
        }
    }
}

struct DriveScanSheet: View {
    @State private var preset: DriveScanPreset = .meetingNotes
    @State private var name = DriveScanPreset.meetingNotes.suggestedName

    let onCancel: () -> Void
    let onCreate: (DriveScanPreset, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Scan type") {
                    Picker("Preset", selection: $preset) {
                        ForEach(DriveScanPreset.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .onChange(of: preset) { _, value in
                        name = value.suggestedName
                    }
                }

                Section("File name") {
                    TextField("Document name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(preset.subtitle)
                            .font(.subheadline)
                        Text(preset.sampleBody)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onCreate(preset, name.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }
        }
    }
}

struct DriveUploadsView: View {
    @ObservedObject var store: WorkspaceStore
    let parentFolderId: String?
    let openFile: (WorkspaceFile) -> Void

    @State private var showCreateFolder = false
    @State private var showScan = false
    @State private var folderName = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            DrivePalette.listSurface
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    utilitySection(title: "Create") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                DriveActionTile(title: "Folder", systemImage: "folder.badge.plus") {
                                    showCreateFolder = true
                                }
                                DriveActionTile(title: "Docs", systemImage: "doc.text") {
                                    let fileId = store.createDocument(parentFolderId: parentFolderId)
                                    if let file = store.file(id: fileId) {
                                        openFile(file)
                                    }
                                }
                                DriveActionTile(title: "Sheets", systemImage: "tablecells") {
                                    let fileId = store.createSpreadsheet(parentFolderId: parentFolderId)
                                    if let file = store.file(id: fileId) {
                                        openFile(file)
                                    }
                                }
                                DriveActionTile(title: "Slides", systemImage: "menucard") {
                                    let fileId = store.createPresentation(parentFolderId: parentFolderId)
                                    if let file = store.file(id: fileId) {
                                        openFile(file)
                                    }
                                }
                                DriveActionTile(title: "Scan", systemImage: "viewfinder") {
                                    showScan = true
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    utilitySection(title: "Recent uploads") {
                        let files = store.recentlyCreatedFiles(limit: 10)

                        if files.isEmpty {
                            EmptyStateCard(
                                title: "Nothing uploaded yet",
                                message: "Create a folder or add a file to see it here.",
                                systemImage: "tray",
                                accessibilityIdentifier: AccessibilityID.emptyState("uploads_empty")
                            )
                        } else {
                            ForEach(files) { file in
                                DriveUtilityFileRow(
                                    file: file,
                                    subtitle: "Added \(AppFormatters.relativeDate.localizedString(for: file.createdAt, relativeTo: Date()))",
                                    onOpen: { openFile(file) },
                                    onToggleOffline: { store.toggleOffline(fileId: file.id) },
                                    isOffline: store.isOffline(fileId: file.id),
                                    onTrashOrRestore: { store.trashItem(id: file.id) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }

            if let message = store.transientMessage {
                DriveToast(message: message)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Uploads")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCreateFolder) {
            CreateFolderSheet(
                folderName: $folderName,
                onCancel: {
                    folderName = ""
                    showCreateFolder = false
                },
                onCreate: {
                    store.createFolder(name: folderName, parentFolderId: parentFolderId)
                    folderName = ""
                    showCreateFolder = false
                }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showScan) {
            DriveScanSheet(
                onCancel: { showScan = false },
                onCreate: { preset, name in
                    let resolvedName = name.isEmpty ? preset.suggestedName : name
                    _ = store.createScannedDocument(
                        parentFolderId: parentFolderId,
                        name: resolvedName,
                        body: preset.sampleBody,
                        sizeDescription: preset.suggestedSize
                    )
                    showScan = false
                }
            )
            .preferredColorScheme(.dark)
        }
    }

    private func utilitySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(DrivePalette.primaryText)

            VStack(spacing: 0) {
                content()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}

struct DriveOfflineView: View {
    @ObservedObject var store: WorkspaceStore
    let openFile: (WorkspaceFile) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            DrivePalette.listSurface
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if store.offlineFiles().isEmpty {
                        EmptyStateCard(
                            title: "No offline files",
                            message: "Use a file menu to make important files available offline.",
                            systemImage: "checkmark.circle",
                            accessibilityIdentifier: AccessibilityID.emptyState("offline_empty")
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    } else {
                        ForEach(store.offlineFiles()) { file in
                            DriveUtilityFileRow(
                                file: file,
                                subtitle: store.pathString(for: file),
                                onOpen: { openFile(file) },
                                onToggleOffline: { store.toggleOffline(fileId: file.id) },
                                isOffline: true,
                                onTrashOrRestore: { store.trashItem(id: file.id) }
                            )
                        }
                    }
                }
                .padding(.bottom, 28)
            }

            if let message = store.transientMessage {
                DriveToast(message: message)
                    .padding(.bottom, 20)
            }
        }
        .navigationTitle("Offline")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

struct DriveHelpFeedbackView: View {
    @ObservedObject var store: WorkspaceStore

    @State private var category = "Suggestion"
    @State private var feedback = ""

    private let topics = [
        ("Find files faster", "Use search filters or sort by recent activity to narrow the workspace."),
        ("Share with your team", "Open a file menu, choose Share, then update access and copy the link."),
        ("Keep files offline", "Mark important files available offline from the row action menu."),
    ]

    var body: some View {
        List {
            Section("Help topics") {
                ForEach(topics, id: \.0) { topic in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(topic.0)
                            .font(.subheadline.weight(.semibold))
                        Text(topic.1)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Send feedback") {
                Picker("Category", selection: $category) {
                    Text("Suggestion").tag("Suggestion")
                    Text("Bug").tag("Bug")
                    Text("Missing feature").tag("Missing feature")
                }

                TextEditor(text: $feedback)
                    .frame(minHeight: 140)

                Button("Send feedback") {
                    feedback = ""
                    store.showMessage("Feedback sent.")
                }
                .disabled(feedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Help & Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let message = store.transientMessage {
                DriveToast(message: message)
                    .padding(.bottom, 20)
            }
        }
    }
}

private struct DriveSpamItem: Identifiable {
    let id: String
    let sender: String
    let title: String
    let subtitle: String

    static let seeded: [DriveSpamItem] = [
        DriveSpamItem(id: "spam_1", sender: "Unknown Sender", title: "Invoice update required", subtitle: "Moved here automatically because the sender was flagged."),
        DriveSpamItem(id: "spam_2", sender: "Storage Monitor", title: "Shared file access request", subtitle: "Suspicious sharing request captured before it reached My Drive."),
    ]
}

struct DriveSpamView: View {
    @State private var items = DriveSpamItem.seeded

    var body: some View {
        List {
            if items.isEmpty {
                EmptyStateCard(
                    title: "Spam is empty",
                    message: "Potentially unsafe files and requests will appear here.",
                    systemImage: "exclamationmark.octagon",
                    accessibilityIdentifier: AccessibilityID.emptyState("spam_empty")
                )
            } else {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                        Text(item.sender)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(item.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            items.removeAll { $0.id == item.id }
                        }
                        Button("Not spam") {
                            items.removeAll { $0.id == item.id }
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("Spam")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DriveActionTile: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DrivePalette.accentText)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DrivePalette.primaryText)
            }
            .padding(16)
            .frame(width: 136, height: 100, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DriveUtilityFileRow: View {
    let file: WorkspaceFile
    let subtitle: String
    let onOpen: () -> Void
    let onToggleOffline: () -> Void
    let isOffline: Bool
    let onTrashOrRestore: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            DriveUtilityGlyph(fileType: file.fileType)

            VStack(alignment: .leading, spacing: 6) {
                Text(file.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(DrivePalette.primaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DrivePalette.secondaryText)
                    .lineLimit(2)

                if isOffline {
                    Label("Available offline", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(red: 0.52, green: 0.82, blue: 0.59))
                }
            }

            Spacer(minLength: 12)

            Menu {
                Button("Open", action: onOpen)
                Button(isOffline ? "Remove offline copy" : "Make available offline", action: onToggleOffline)
                Button(file.trashed ? "Restore" : "Move to trash", role: file.trashed ? nil : .destructive, action: onTrashOrRestore)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DrivePalette.secondaryText)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
    }
}

private struct DriveUtilityGlyph: View {
    let fileType: WorkspaceFileType

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.18))
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 40, height: 40)
    }

    private var symbol: String {
        switch fileType {
        case .document:
            return "doc.text.fill"
        case .spreadsheet:
            return "tablecells.fill"
        case .presentation:
            return "menucard.fill"
        }
    }

    private var tint: Color {
        switch fileType {
        case .document:
            return Color(red: 0.55, green: 0.69, blue: 0.98)
        case .spreadsheet:
            return Color(red: 0.52, green: 0.82, blue: 0.59)
        case .presentation:
            return Color(red: 0.92, green: 0.53, blue: 0.50)
        }
    }
}
