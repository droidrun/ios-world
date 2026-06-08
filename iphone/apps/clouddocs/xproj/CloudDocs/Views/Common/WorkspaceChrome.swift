import SwiftUI
import UIKit

enum DocsPalette {
    static let background = Color(red: 0.11, green: 0.12, blue: 0.15)
    static let chrome = Color(red: 0.18, green: 0.19, blue: 0.23)
    static let searchSurface = Color(red: 0.20, green: 0.21, blue: 0.25)
    static let drawerSurface = Color(red: 0.22, green: 0.23, blue: 0.27)
    static let cardSurface = Color(red: 0.23, green: 0.25, blue: 0.29)
    static let selectedRow = Color(red: 0.13, green: 0.19, blue: 0.31)
    static let accent = Color(red: 0.56, green: 0.72, blue: 1.00)
    static let secondaryText = Color(red: 0.67, green: 0.70, blue: 0.76)
    static let page = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let pageInk = Color(red: 0.22, green: 0.23, blue: 0.25)
    static let pageMutedInk = Color(red: 0.44, green: 0.46, blue: 0.51)
    static let link = Color(red: 0.54, green: 0.69, blue: 1.00)
    static let avatar = Color(red: 0.47, green: 0.12, blue: 0.65)

    static let backgroundUIColor = UIColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1)
    static let chromeUIColor = UIColor(red: 0.18, green: 0.19, blue: 0.23, alpha: 1)
    static let textUIColor = UIColor(white: 0.97, alpha: 1)
    static let secondaryTextUIColor = UIColor(white: 0.76, alpha: 1)
    static let linkUIColor = UIColor(red: 0.54, green: 0.69, blue: 1.00, alpha: 1)
}

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
                Text("Snapshot \(AppFormatters.shortDateTime.string(from: metadata.snapshotTimestamp))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Offline mode")
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

struct DocsAvatarView: View {
    let letter: String
    var size: CGFloat = 46

    var body: some View {
        Circle()
            .fill(DocsPalette.avatar)
            .frame(width: size, height: size)
            .overlay {
                Text(letter.uppercased())
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(.white)
            }
    }
}

struct DocsSparkleIcon: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)

            Circle()
                .fill(DocsPalette.accent)
                .frame(width: 11, height: 11)
                .offset(x: 3, y: -3)
        }
    }
}

struct DocsDocumentGlyph: View {
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: "doc.text.fill")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(DocsPalette.accent)
    }
}

struct DocsMulticolorPlusIcon: View {
    var armLength: CGFloat = 14
    var thickness: CGFloat = 5

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.25, green: 0.45, blue: 0.91))
                .frame(width: thickness, height: armLength * 2)
                .offset(y: -armLength / 2)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.21, green: 0.67, blue: 0.32))
                .frame(width: thickness, height: armLength * 2)
                .offset(y: armLength / 2)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.98, green: 0.73, blue: 0.10))
                .frame(width: armLength * 2, height: thickness)
                .offset(x: -armLength / 2)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.84, green: 0.22, blue: 0.18))
                .frame(width: armLength * 2, height: thickness)
                .offset(x: armLength / 2)
        }
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
    let shareLink: String
    let onCancel: () -> Void
    let onSave: () -> Void

    @State private var copiedMessage: String?

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

                    VStack(alignment: .leading, spacing: 10) {
                        Text(shareLink)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy sharing link") {
                            UIPasteboard.general.string = shareLink
                            copiedMessage = "Copied to clipboard"
                        }

                        if let copiedMessage {
                            Text(copiedMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
