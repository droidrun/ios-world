import SwiftUI

struct DebugImportView: View {
    @ObservedObject var viewModel: MoreViewModel

    var body: some View {
        ZStack {
            TeamChatPalette.screen.ignoresSafeArea()

            List {
                Section("Data source") {
                    Picker("Mode", selection: Binding(
                        get: { viewModel.sourceType },
                        set: { viewModel.switchSource($0) }
                    )) {
                        Text("Default").tag(WorkspaceSourceType.seeded)
                        Text("Snapshot").tag(WorkspaceSourceType.snapshot)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("data_source_picker")

                    Text("Current: \(viewModel.sourceType.label)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("current_data_source_label")

                    Button("Reload default data") {
                        viewModel.reloadSnapshot()
                    }
                    .accessibilityIdentifier("reload_snapshot_button")
                }

                Section("Workspace metadata") {
                    if let metadata = viewModel.metadata {
                        Text("Source: \(metadata.sourceLabel)")
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("snapshot_source_label")
                        Text("Snapshot: \(DateFormatters.messageTimestamp.string(from: metadata.snapshotTimestamp))")
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("snapshot_timestamp_label")
                        Text("Last updated: \(DateFormatters.messageTimestamp.string(from: metadata.lastUpdated))")
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("snapshot_last_updated_label")
                    } else {
                        Text("Snapshot data unavailable")
                            .foregroundStyle(TeamChatPalette.subtleText)
                            .accessibilityIdentifier("snapshot_data_unavailable_state")
                    }
                }

                Section("Storage") {
                    Button("Reset app state") {
                        viewModel.resetAppState()
                    }
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("profile_reset_app_state")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TeamChatPalette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .hidesRootChrome()
    }
}
