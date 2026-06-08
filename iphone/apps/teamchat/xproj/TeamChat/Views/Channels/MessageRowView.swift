import SwiftUI

struct MessageRowView: View {
    let message: Message
    let showThreadButton: Bool
    let mentionCurrentUser: Bool
    let onToggleReaction: (String) -> Void
    let onOpenThread: () -> Void

    @State private var showEmojiPicker = false

    private static let pickerEmojis = ["👍", "❤️", "😂", "🔥", "👀", "💯", "✅", "👏", "👋", "🎉", "🥳", "🤔", "🚀", "✨", "🙏"]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            avatar

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(message.senderDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("message_sender_\(message.id)")
                    Spacer()
                    Text(DateFormatters.messageTimestamp.string(from: message.timestamp))
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("message_timestamp_\(message.id)")
                }

                if message.messageText.isEmpty == false {
                    Text(message.messageText)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.95))
                        .accessibilityIdentifier("message_text_\(message.id)")
                }

                if let editedAt = message.editedAt {
                    Text("edited \(DateFormatters.messageTimestamp.string(from: editedAt))")
                        .font(.caption2)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("message_edited_label_\(message.id)")
                }

                if mentionCurrentUser {
                    Text("Mentions you")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(TeamChatPalette.avatarRing, in: Capsule())
                        .accessibilityIdentifier("mention_chip_\(message.id)")
                }

                if message.attachments.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(message.attachments) { attachment in
                            attachmentCard(attachment)
                        }
                    }
                }

                HStack(spacing: 8) {
                    if message.reactions.isEmpty == false {
                        ForEach(message.reactions) { reaction in
                            Button {
                                onToggleReaction(reaction.reactionEmoji)
                            } label: {
                                HStack(spacing: 4) {
                                    EmojiText(reaction.reactionEmoji, pointSize: 12)
                                    Text("\(reaction.reactionCount)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(TeamChatPalette.row, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("reaction_button_\(message.id)_\(reaction.reactionEmoji.accessibilitySlug)")
                        }
                    }

                    Button {
                        showEmojiPicker = true
                    } label: {
                        Label("React", systemImage: "face.smiling")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.88))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TeamChatPalette.row, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("add_reaction_button_\(message.id)")
                    .sheet(isPresented: $showEmojiPicker) {
                        emojiPickerGrid
                            .presentationDetents([.height(250)])
                            .presentationDragIndicator(.visible)
                            .presentationBackground(TeamChatPalette.card)
                    }

                    if showThreadButton {
                        Button {
                            onOpenThread()
                        } label: {
                            if message.replyCount > 0 {
                                Text("\(message.replyCount) repl\(message.replyCount == 1 ? "y" : "ies")")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            } else {
                                Text("Reply in thread")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(TeamChatPalette.row, in: Capsule())
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("open_thread_button_\(message.id)")
                    }

                    Spacer()
                }
            }
        }
        .padding(12)
        .background(TeamChatPalette.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(TeamChatPalette.divider, lineWidth: 1)
        )
        .padding(.vertical, 4)
        // Keep descendant accessibility elements (attachment_row_/_title_/
        // _subtitle_, message_text_, reaction/thread buttons) individually
        // addressable. Without this, SwiftUI fuses every child under this
        // container's identifier, so a sent attachment renders as anonymous
        // text under `message_row_<id>` and `attachment_title_<id>` /
        // `attachment_row_<id>` become unqueryable — making a sent attachment
        // impossible to verify by its own accessibility id.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("message_row_\(message.id)")
    }

    private var avatar: some View {
        TeamChatUserAvatar(displayName: message.senderDisplayName, fallbackInitials: initials, size: 38, cornerRadius: 12)
            .accessibilityIdentifier("message_avatar_\(message.id)")
    }

    private func attachmentCard(_ attachment: MessageAttachment) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(tint(for: attachment).opacity(0.9))
                .frame(width: 54, height: 54)
                .overlay {
                    Image(systemName: icon(for: attachment.attachmentType))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(attachment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("attachment_title_\(attachment.id)")
                Text(attachment.subtitle)
                    .font(.caption)
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .lineLimit(2)
                    .accessibilityIdentifier("attachment_subtitle_\(attachment.id)")
            }

            Spacer()
        }
        .padding(10)
        .background(TeamChatPalette.row, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(TeamChatPalette.divider, lineWidth: 1)
        )
        // Keep attachment_title_/attachment_subtitle_ individually queryable
        // instead of fusing them into attachment_row_<id>.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("attachment_row_\(attachment.id)")
    }

    private func icon(for attachmentType: AttachmentType) -> String {
        switch attachmentType {
        case .image:
            return "photo"
        case .pdf:
            return "doc.richtext"
        case .link:
            return "link"
        }
    }

    private func tint(for attachment: MessageAttachment) -> Color {
        switch attachment.attachmentType {
        case .image:
            return Color(red: 0.27, green: 0.49, blue: 0.76)
        case .pdf:
            return Color(red: 0.71, green: 0.27, blue: 0.32)
        case .link:
            return Color(red: 0.24, green: 0.52, blue: 0.46)
        }
    }

    private var initials: String {
        let parts = message.senderDisplayName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(message.senderDisplayName.prefix(2)).uppercased()
    }

    private var avatarGradient: LinearGradient {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.45, green: 0.25, blue: 0.71), Color(red: 0.25, green: 0.17, blue: 0.46)),
            (Color(red: 0.16, green: 0.53, blue: 0.61), Color(red: 0.10, green: 0.35, blue: 0.43)),
            (Color(red: 0.63, green: 0.38, blue: 0.23), Color(red: 0.39, green: 0.25, blue: 0.16)),
            (Color(red: 0.28, green: 0.45, blue: 0.28), Color(red: 0.18, green: 0.31, blue: 0.19))
        ]
        let index = stableColorIndex(for: message.senderId, count: palettes.count)
        let pair = palettes[index]
        return LinearGradient(colors: [pair.0, pair.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func stableColorIndex(for key: String, count: Int) -> Int {
        let scalarTotal = key.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        return scalarTotal % max(count, 1)
    }

    private var emojiPickerGrid: some View {
        let columns = Array(repeating: GridItem(.fixed(48), spacing: 8), count: 6)
        return VStack(spacing: 12) {
            Text("Add reaction")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("emoji_picker_title_\(message.id)")
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Self.pickerEmojis, id: \.self) { emoji in
                    Button {
                        showEmojiPicker = false
                        onToggleReaction(emoji)
                    } label: {
                        EmojiText(emoji, pointSize: 22)
                            .frame(width: 44, height: 44)
                            .background(TeamChatPalette.row, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("emoji_picker_\(emoji.accessibilitySlug)_\(message.id)")
                }
            }
        }
        .padding(16)
        .accessibilityIdentifier("emoji_picker_grid_\(message.id)")
    }
}
