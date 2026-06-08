import SwiftUI

struct DocumentRowView: View {
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(.blue)

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
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Menu {
                Button("Open", action: onOpen)
                Button("Share", action: onShare)
                Button("Rename", action: onRename)
                    .accessibilityIdentifier(AccessibilityID.fileActionRename)
                Button("Move", action: onMove)
                    .accessibilityIdentifier(AccessibilityID.fileActionMove)
                Button("Duplicate", action: onDuplicate)
                    .accessibilityIdentifier(AccessibilityID.fileActionDuplicate)
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
}
