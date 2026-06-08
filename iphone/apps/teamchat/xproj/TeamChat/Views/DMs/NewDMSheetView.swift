import SwiftUI

struct NewDMSheetView: View {
    @ObservedObject var viewModel: DMsViewModel
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMemberIds: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                TeamChatPalette.screen.ignoresSafeArea()

                List(viewModel.members) { member in
                    Button {
                        if selectedMemberIds.contains(member.id) {
                            selectedMemberIds.remove(member.id)
                        } else {
                            selectedMemberIds.insert(member.id)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName)
                                    .foregroundStyle(.white)
                                    .accessibilityIdentifier("new_dm_member_name_\(member.username)")
                                Text("@\(member.username)")
                                    .font(.caption)
                                    .foregroundStyle(TeamChatPalette.subtleText)
                                    .accessibilityIdentifier("new_dm_member_username_\(member.username)")
                            }
                            Spacer()
                            if selectedMemberIds.contains(member.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(TeamChatPalette.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(TeamChatPalette.screen)
                    .listRowSeparatorTint(TeamChatPalette.divider)
                    .accessibilityIdentifier("member_row_\(member.username)")
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("new_dm_cancel_button")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") {
                        if let dmId = viewModel.createDM(memberIds: Array(selectedMemberIds)) {
                            onCreate(dmId)
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("new_dm_create_button")
                }
            }
        }
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
