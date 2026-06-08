import SwiftUI

struct HuddlePlaceholderView: View {
    let title: String
    let contextName: String
    let participantNames: [String]
    let accessibilityPrefix: String

    @Environment(\.dismiss) private var dismiss

    private var subtitle: String {
        if participantNames.isEmpty {
            return "No active participants"
        }
        if participantNames.count == 1 {
            return participantNames[0]
        }
        return participantNames.prefix(3).joined(separator: ", ")
    }

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("\(accessibilityPrefix)_title")

                    Text(contextName)
                        .font(.headline)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("\(accessibilityPrefix)_context")
                }

                VStack(alignment: .leading, spacing: 12) {
                    infoRow(title: "Participants", value: subtitle, id: "\(accessibilityPrefix)_participants")
                    infoRow(title: "Status", value: "Offline mode - audio unavailable", id: "\(accessibilityPrefix)_status")
                    infoRow(title: "What works", value: "You can open chat context, send messages, and continue the workflow locally.", id: "\(accessibilityPrefix)_capability")
                }

                Text("Live audio and video sessions are not available while offline.")
                    .font(.subheadline)
                    .foregroundStyle(TeamChatPalette.secondaryText)
                    .accessibilityIdentifier("\(accessibilityPrefix)_note")

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(TeamChatPalette.avatarRing, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityIdentifier("\(accessibilityPrefix)_done_button")
            }
            .padding(18)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(.white)
                .accessibilityIdentifier("\(accessibilityPrefix)_close_button")
            }
        }
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .hidesRootChrome()
    }

    private func infoRow(title: String, value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TeamChatPalette.subtleText)
            Text(value)
                .font(.body)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityIdentifier(id)
    }
}
