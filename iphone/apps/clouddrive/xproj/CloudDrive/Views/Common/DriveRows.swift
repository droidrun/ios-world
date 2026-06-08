import SwiftUI

struct DriveFolderRowView: View {
    let folder: WorkspaceFolder
    let onRename: () -> Void
    let onMove: () -> Void
    let onToggleStar: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: folder.shared ? "folder.badge.person.crop" : "folder")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    if folder.starred {
                        MetadataChip(text: "Starred")
                    }
                    if folder.shared {
                        MetadataChip(text: "Shared")
                    }
                    if folder.trashed {
                        MetadataChip(text: "Trash")
                    }
                }
            }

            Spacer()

            Menu {
                Button("Rename", action: onRename)
                Button("Move", action: onMove)
                Button(folder.starred ? "Remove star" : "Add star", action: onToggleStar)
                Button(folder.trashed ? "Restore" : "Move to trash", role: folder.trashed ? nil : .destructive, action: onTrashOrRestore)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier(AccessibilityID.folderRow(folder.name))
    }
}

struct DriveFileRowView: View {
    let file: WorkspaceFile
    let preview: String
    let isOffline: Bool
    let onOpen: () -> Void
    let onDetails: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onShare: () -> Void
    let onDuplicate: () -> Void
    let onToggleStar: () -> Void
    let onToggleOffline: (() -> Void)?
    let onTrashOrRestore: () -> Void

    init(
        file: WorkspaceFile,
        preview: String,
        isOffline: Bool = false,
        onOpen: @escaping () -> Void,
        onDetails: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onMove: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onToggleStar: @escaping () -> Void,
        onToggleOffline: (() -> Void)? = nil,
        onTrashOrRestore: @escaping () -> Void
    ) {
        self.file = file
        self.preview = preview
        self.isOffline = isOffline
        self.onOpen = onOpen
        self.onDetails = onDetails
        self.onRename = onRename
        self.onMove = onMove
        self.onShare = onShare
        self.onDuplicate = onDuplicate
        self.onToggleStar = onToggleStar
        self.onToggleOffline = onToggleOffline
        self.onTrashOrRestore = onTrashOrRestore
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onOpen) {
                Image(systemName: file.fileType.systemImage)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(file.fileType == .document ? AccessibilityID.fileActionOpenInDocs : file.fileType == .spreadsheet ? AccessibilityID.fileActionOpenInSheets : AccessibilityID.fileActionOpenInSlides)

            VStack(alignment: .leading, spacing: 4) {
                Button(action: onOpen) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            MetadataChip(text: file.fileType.title)
                            if file.starred {
                                MetadataChip(text: "Starred")
                            }
                            if isOffline {
                                MetadataChip(text: "Offline")
                            }
                            if file.shared {
                                MetadataChip(text: "Shared")
                            }
                            if file.trashed {
                                MetadataChip(text: "Trash")
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Menu {
                Button("Open", action: onOpen)
                Button("Details", action: onDetails)
                Button("Share", action: onShare)
                Button("Rename", action: onRename)
                    .accessibilityIdentifier(AccessibilityID.fileActionRename)
                Button("Move", action: onMove)
                    .accessibilityIdentifier(AccessibilityID.fileActionMove)
                Button("Duplicate", action: onDuplicate)
                    .accessibilityIdentifier(AccessibilityID.fileActionDuplicate)
                Button(file.starred ? "Remove star" : "Add star", action: onToggleStar)
                    .accessibilityIdentifier(AccessibilityID.fileActionStar)
                if let onToggleOffline {
                    Button(isOffline ? "Remove offline copy" : "Make available offline", action: onToggleOffline)
                }
                Button(file.trashed ? "Restore" : "Move to trash", role: file.trashed ? nil : .destructive, action: onTrashOrRestore)
                    .accessibilityIdentifier(file.trashed ? AccessibilityID.fileActionRestore : AccessibilityID.fileActionTrash)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier(AccessibilityID.fileRow(file))
    }

    private var iconColor: Color {
        switch file.fileType {
        case .document:
            return .blue
        case .spreadsheet:
            return .green
        case .presentation:
            return .orange
        }
    }
}

struct DriveMyDriveFolderRow: View {
    let folder: WorkspaceFolder
    let subtitle: String
    let onOpen: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onToggleStar: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: onOpen) {
                Image(systemName: folder.shared ? "folder.badge.person.fill" : "folder.fill")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.76))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Button(action: onOpen) {
                    Text(folder.name)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(DrivePalette.primaryText)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DrivePalette.secondaryText)
            }

            Spacer(minLength: 16)

            Menu {
                Button("Rename", action: onRename)
                Button("Move", action: onMove)
                Button(folder.starred ? "Remove star" : "Add star", action: onToggleStar)
                Button(folder.trashed ? "Restore" : "Move to trash", role: folder.trashed ? nil : .destructive, action: onTrashOrRestore)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DrivePalette.secondaryText)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityIdentifier(AccessibilityID.folderRow(folder.name))
    }
}

struct DriveStandardFileRow: View {
    let file: WorkspaceFile
    let subtitle: String
    let showStarMarker: Bool
    let showSharedMarker: Bool
    let showOfflineMarker: Bool
    let onOpen: () -> Void
    let onDetails: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onShare: () -> Void
    let onDuplicate: () -> Void
    let onToggleStar: () -> Void
    let onToggleOffline: (() -> Void)?
    let onTrashOrRestore: () -> Void

    init(
        file: WorkspaceFile,
        subtitle: String,
        showStarMarker: Bool,
        showSharedMarker: Bool,
        showOfflineMarker: Bool = false,
        onOpen: @escaping () -> Void,
        onDetails: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onMove: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onToggleStar: @escaping () -> Void,
        onToggleOffline: (() -> Void)? = nil,
        onTrashOrRestore: @escaping () -> Void
    ) {
        self.file = file
        self.subtitle = subtitle
        self.showStarMarker = showStarMarker
        self.showSharedMarker = showSharedMarker
        self.showOfflineMarker = showOfflineMarker
        self.onOpen = onOpen
        self.onDetails = onDetails
        self.onRename = onRename
        self.onMove = onMove
        self.onShare = onShare
        self.onDuplicate = onDuplicate
        self.onToggleStar = onToggleStar
        self.onToggleOffline = onToggleOffline
        self.onTrashOrRestore = onTrashOrRestore
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onOpen) {
                DriveFileGlyph(fileType: file.fileType, size: 44)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Button(action: onOpen) {
                    Text(file.name)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(DrivePalette.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    if showStarMarker {
                        Image(systemName: "star.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.70))
                    }

                    if showSharedMarker {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.62))
                    }

                    if showOfflineMarker {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(red: 0.52, green: 0.82, blue: 0.59))
                    }

                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(DrivePalette.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            DriveFileRowMenu(
                file: file,
                onOpen: onOpen,
                onDetails: onDetails,
                onRename: onRename,
                onMove: onMove,
                onShare: onShare,
                onDuplicate: onDuplicate,
                onToggleStar: onToggleStar,
                isOffline: showOfflineMarker,
                onToggleOffline: onToggleOffline,
                onTrashOrRestore: onTrashOrRestore
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityIdentifier(AccessibilityID.fileRow(file))
    }
}

struct DriveSharedFileRow: View {
    let file: WorkspaceFile
    let subtitle: String
    let showOfflineMarker: Bool
    let onOpen: () -> Void
    let onDetails: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onShare: () -> Void
    let onDuplicate: () -> Void
    let onToggleStar: () -> Void
    let onToggleOffline: (() -> Void)?
    let onTrashOrRestore: () -> Void

    init(
        file: WorkspaceFile,
        subtitle: String,
        showOfflineMarker: Bool = false,
        onOpen: @escaping () -> Void,
        onDetails: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onMove: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onToggleStar: @escaping () -> Void,
        onToggleOffline: (() -> Void)? = nil,
        onTrashOrRestore: @escaping () -> Void
    ) {
        self.file = file
        self.subtitle = subtitle
        self.showOfflineMarker = showOfflineMarker
        self.onOpen = onOpen
        self.onDetails = onDetails
        self.onRename = onRename
        self.onMove = onMove
        self.onShare = onShare
        self.onDuplicate = onDuplicate
        self.onToggleStar = onToggleStar
        self.onToggleOffline = onToggleOffline
        self.onTrashOrRestore = onTrashOrRestore
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onOpen) {
                ZStack(alignment: .bottomTrailing) {
                    DriveAvatarCircle(name: file.ownerName, size: 40)
                    DriveFileGlyph(fileType: file.fileType, size: 30)
                        .background(
                            Circle()
                                .fill(DrivePalette.listSurface)
                                .frame(width: 34, height: 34)
                        )
                        .offset(x: 8, y: 6)
                }
                .frame(width: 58, height: 48, alignment: .leading)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Button(action: onOpen) {
                    Text(file.name)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(DrivePalette.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.64))
                    if showOfflineMarker {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(red: 0.52, green: 0.82, blue: 0.59))
                    }
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(DrivePalette.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            DriveFileRowMenu(
                file: file,
                onOpen: onOpen,
                onDetails: onDetails,
                onRename: onRename,
                onMove: onMove,
                onShare: onShare,
                onDuplicate: onDuplicate,
                onToggleStar: onToggleStar,
                isOffline: showOfflineMarker,
                onToggleOffline: onToggleOffline,
                onTrashOrRestore: onTrashOrRestore
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityIdentifier(AccessibilityID.sharedRow(file))
    }
}

struct DriveFolderGridCard: View {
    let folder: WorkspaceFolder
    let subtitle: String
    let onOpen: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onToggleStar: () -> Void
    let onTrashOrRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Button(action: onOpen) {
                    Image(systemName: folder.shared ? "folder.badge.person.fill" : "folder.fill")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 10)

                Menu {
                    Button("Rename", action: onRename)
                    Button("Move", action: onMove)
                    Button(folder.starred ? "Remove star" : "Add star", action: onToggleStar)
                    Button(folder.trashed ? "Restore" : "Move to trash", role: folder.trashed ? nil : .destructive, action: onTrashOrRestore)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DrivePalette.secondaryText)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
            }

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(folder.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DrivePalette.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DrivePalette.secondaryText)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .accessibilityIdentifier(AccessibilityID.folderRow(folder.name))
    }
}

struct DriveFileGridCard: View {
    let file: WorkspaceFile
    let subtitle: String
    let showOwner: Bool
    let showOfflineMarker: Bool
    let onOpen: () -> Void
    let onDetails: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onShare: () -> Void
    let onDuplicate: () -> Void
    let onToggleStar: () -> Void
    let onToggleOffline: (() -> Void)?
    let onTrashOrRestore: () -> Void

    init(
        file: WorkspaceFile,
        subtitle: String,
        showOwner: Bool,
        showOfflineMarker: Bool = false,
        onOpen: @escaping () -> Void,
        onDetails: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onMove: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onToggleStar: @escaping () -> Void,
        onToggleOffline: (() -> Void)? = nil,
        onTrashOrRestore: @escaping () -> Void
    ) {
        self.file = file
        self.subtitle = subtitle
        self.showOwner = showOwner
        self.showOfflineMarker = showOfflineMarker
        self.onOpen = onOpen
        self.onDetails = onDetails
        self.onRename = onRename
        self.onMove = onMove
        self.onShare = onShare
        self.onDuplicate = onDuplicate
        self.onToggleStar = onToggleStar
        self.onToggleOffline = onToggleOffline
        self.onTrashOrRestore = onTrashOrRestore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                if showOwner {
                    ZStack(alignment: .bottomTrailing) {
                        DriveAvatarCircle(name: file.ownerName, size: 36)
                        DriveFileGlyph(fileType: file.fileType, size: 26)
                            .background(
                                Circle()
                                    .fill(DrivePalette.listSurface)
                                    .frame(width: 30, height: 30)
                            )
                            .offset(x: 7, y: 5)
                    }
                    .frame(width: 48, height: 40, alignment: .leading)
                } else {
                    DriveFileGlyph(fileType: file.fileType, size: 36)
                }

                Spacer(minLength: 10)

                DriveFileRowMenu(
                    file: file,
                    onOpen: onOpen,
                    onDetails: onDetails,
                    onRename: onRename,
                    onMove: onMove,
                    onShare: onShare,
                    onDuplicate: onDuplicate,
                    onToggleStar: onToggleStar,
                    isOffline: showOfflineMarker,
                    onToggleOffline: onToggleOffline,
                    onTrashOrRestore: onTrashOrRestore
                )
            }

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(file.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DrivePalette.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DrivePalette.secondaryText)
                        .lineLimit(3)

                    if showOfflineMarker {
                        Label("Available offline", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(red: 0.52, green: 0.82, blue: 0.59))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 144, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .accessibilityIdentifier(showOwner ? AccessibilityID.sharedRow(file) : AccessibilityID.fileRow(file))
    }
}

private struct DriveFileRowMenu: View {
    let file: WorkspaceFile
    let onOpen: () -> Void
    let onDetails: () -> Void
    let onRename: () -> Void
    let onMove: () -> Void
    let onShare: () -> Void
    let onDuplicate: () -> Void
    let onToggleStar: () -> Void
    let isOffline: Bool
    let onToggleOffline: (() -> Void)?
    let onTrashOrRestore: () -> Void

    init(
        file: WorkspaceFile,
        onOpen: @escaping () -> Void,
        onDetails: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onMove: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onToggleStar: @escaping () -> Void,
        isOffline: Bool = false,
        onToggleOffline: (() -> Void)? = nil,
        onTrashOrRestore: @escaping () -> Void
    ) {
        self.file = file
        self.onOpen = onOpen
        self.onDetails = onDetails
        self.onRename = onRename
        self.onMove = onMove
        self.onShare = onShare
        self.onDuplicate = onDuplicate
        self.onToggleStar = onToggleStar
        self.isOffline = isOffline
        self.onToggleOffline = onToggleOffline
        self.onTrashOrRestore = onTrashOrRestore
    }

    var body: some View {
        Menu {
            Button("Open", action: onOpen)
            Button("Details", action: onDetails)
            Button("Share", action: onShare)
            Button("Rename", action: onRename)
                .accessibilityIdentifier(AccessibilityID.fileActionRename)
            Button("Move", action: onMove)
                .accessibilityIdentifier(AccessibilityID.fileActionMove)
            Button("Duplicate", action: onDuplicate)
                .accessibilityIdentifier(AccessibilityID.fileActionDuplicate)
            Button(file.starred ? "Remove star" : "Add star", action: onToggleStar)
                .accessibilityIdentifier(AccessibilityID.fileActionStar)
            if let onToggleOffline {
                Button(isOffline ? "Remove offline copy" : "Make available offline", action: onToggleOffline)
            }
            Button(file.trashed ? "Restore" : "Move to trash", role: file.trashed ? nil : .destructive, action: onTrashOrRestore)
                .accessibilityIdentifier(file.trashed ? AccessibilityID.fileActionRestore : AccessibilityID.fileActionTrash)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(DrivePalette.secondaryText)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }
}

private struct DriveFileGlyph: View {
    let fileType: WorkspaceFileType
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(tint.opacity(0.18))
            Image(systemName: symbol)
                .font(.system(size: size * 0.52, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
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

private struct DriveAvatarCircle: View {
    let name: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
            Text(initials)
                .font(.system(size: size * 0.48, weight: .regular))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var initials: String {
        let parts = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        if parts.isEmpty {
            return "?"
        }

        return String(parts).uppercased()
    }

    private var backgroundColor: Color {
        let palette: [Color] = [
            Color(red: 0.48, green: 0.35, blue: 0.84),
            Color(red: 0.95, green: 0.49, blue: 0.02),
            Color(red: 0.13, green: 0.53, blue: 0.89),
            Color(red: 0.84, green: 0.11, blue: 0.41),
            Color(red: 0.26, green: 0.27, blue: 0.31)
        ]
        let scalarSum = name.unicodeScalars.map(\.value).reduce(0, +)
        return palette[Int(scalarSum) % palette.count]
    }
}
