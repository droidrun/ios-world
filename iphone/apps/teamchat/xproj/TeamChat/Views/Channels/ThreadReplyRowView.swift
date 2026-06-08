import SwiftUI

struct ThreadReplyRowView: View {
    let reply: ThreadReply
    let senderName: String
    let onToggleReaction: (String) -> Void

    @State private var showEmojiPicker = false

    private static let pickerEmojis = ["👍", "❤️", "😂", "🔥", "👀", "💯", "✅", "👏", "👋", "🎉", "🥳", "🤔", "🚀", "✨", "🙏"]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TeamChatUserAvatar(displayName: senderName, fallbackInitials: initials, size: 32, cornerRadius: 10)
                .accessibilityIdentifier("thread_reply_avatar_\(reply.id)")

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(senderName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("thread_reply_sender_\(reply.id)")
                    Spacer()
                    Text(DateFormatters.messageTimestamp.string(from: reply.timestamp))
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("thread_reply_timestamp_\(reply.id)")
                }

                Text(reply.messageText)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.95))
                    .accessibilityIdentifier("thread_reply_text_\(reply.id)")

                HStack(spacing: 8) {
                    ForEach(reply.reactions) { reaction in
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
                        .accessibilityIdentifier("thread_reaction_button_\(reply.id)_\(reaction.reactionEmoji.accessibilitySlug)")
                    }

                    Button {
                        showEmojiPicker = true
                    } label: {
                        Label("React", systemImage: "face.smiling")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TeamChatPalette.row, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("add_reaction_button_\(reply.id)")
                    .sheet(isPresented: $showEmojiPicker) {
                        emojiPickerGrid
                            .presentationDetents([.height(250)])
                            .presentationDragIndicator(.visible)
                            .presentationBackground(TeamChatPalette.card)
                    }
                }
            }
        }
        .padding(10)
        .background(TeamChatPalette.card, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(TeamChatPalette.divider, lineWidth: 1)
        )
        .accessibilityIdentifier("thread_reply_row_\(reply.id)")
    }

    private var initials: String {
        let parts = senderName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(senderName.prefix(2)).uppercased()
    }

    private var avatarGradient: LinearGradient {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.45, green: 0.25, blue: 0.71), Color(red: 0.25, green: 0.17, blue: 0.46)),
            (Color(red: 0.16, green: 0.53, blue: 0.61), Color(red: 0.10, green: 0.35, blue: 0.43)),
            (Color(red: 0.63, green: 0.38, blue: 0.23), Color(red: 0.39, green: 0.25, blue: 0.16)),
            (Color(red: 0.28, green: 0.45, blue: 0.28), Color(red: 0.18, green: 0.31, blue: 0.19))
        ]
        let index = stableColorIndex(for: reply.senderId, count: palettes.count)
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
                .accessibilityIdentifier("emoji_picker_title_\(reply.id)")
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
                    .accessibilityIdentifier("emoji_picker_\(emoji.accessibilitySlug)_\(reply.id)")
                }
            }
        }
        .padding(16)
        .accessibilityIdentifier("emoji_picker_grid_\(reply.id)")
    }
}
