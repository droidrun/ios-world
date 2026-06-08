import SwiftUI
import UIKit

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
                Button {
                    selection = ""
                } label: {
                    HStack {
                        Label("My Drive", systemImage: "externaldrive")
                        Spacer()
                        if selection.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)

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
    let linkLabel: String
    let onCopyLink: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void

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

                    Button("Copy local link", action: onCopyLink)

                    Text(linkLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
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
