import SwiftUI

struct FileDetailView: View {
    @ObservedObject var store: WorkspaceStore
    let fileId: String
    let onOpen: () -> Void
    let onShare: () -> Void

    var body: some View {
        if let file = store.file(id: fileId) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(file.name, systemImage: file.fileType.systemImage)
                            .font(.title3.weight(.semibold))
                        Text(store.contentPreview(for: file))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier(AccessibilityID.fileDetail(file))
                }

                Section("Details") {
                    detailRow("Type", value: file.fileType.title)
                    detailRow("Parent folder", value: store.folder(id: file.parentFolderId)?.name ?? "My Drive")
                    detailRow("Path", value: store.pathString(for: file))
                    detailRow("Owner", value: file.ownerName)
                    detailRow("Created", value: AppFormatters.shortDateTime.string(from: file.createdAt))
                    detailRow("Last modified", value: AppFormatters.shortDateTime.string(from: file.updatedAt))
                    detailRow("Starred", value: file.starred ? "Yes" : "No")
                    detailRow("Shared", value: file.shared ? "Yes" : "No")
                    detailRow("Available offline", value: store.isOffline(fileId: file.id) ? "Yes" : "No")
                    detailRow("Comments", value: "\(file.commentCount)")
                    detailRow("File size", value: file.sizeDescription)
                }

                Section("Sharing") {
                    detailRow("Visibility", value: file.linkSettings.visibility.title)
                    detailRow("Default role", value: file.linkSettings.defaultRole.title)
                    detailRow("Link copies", value: "\(file.linkSettings.copyCount)")

                    if file.permissions.isEmpty {
                        Text("Only you have access right now.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(file.permissions) { permission in
                            HStack {
                                Text(permission.personName)
                                Spacer()
                                Text(permission.role.title)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Comments") {
                    if file.comments.isEmpty {
                        EmptyStateCard(
                            title: "No comments",
                            message: "No comments have been added to this file yet.",
                            systemImage: "bubble.left",
                            accessibilityIdentifier: AccessibilityID.emptyState("no_comments")
                        )
                    } else {
                        ForEach(file.comments) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(comment.authorName)
                                    .font(.subheadline.weight(.semibold))
                                Text(comment.body)
                                    .font(.footnote)
                                Text(AppFormatters.shortDateTime.string(from: comment.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Open", action: onOpen)
                        .buttonStyle(.borderedProminent)
                    Button("Share", action: onShare)
                        .buttonStyle(.bordered)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("File details")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            EmptyStateCard(
                title: "File unavailable",
                message: "The selected file could not be loaded.",
                systemImage: "exclamationmark.triangle",
                accessibilityIdentifier: AccessibilityID.emptyState("file_unavailable")
            )
            .padding()
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(AccessibilityID.metadataLabel(label))
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
