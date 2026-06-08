import SwiftUI
import UniformTypeIdentifiers

struct MoreView: View {
    @ObservedObject var store: WorkspaceStore
    @ObservedObject var coordinator: DriveActionCoordinator

    @AppStorage("drive_pref_notifications") private var notificationsEnabled = true
    @AppStorage("drive_pref_suggestions") private var suggestionsEnabled = true
    @AppStorage("drive_pref_cellular_downloads") private var cellularDownloadsEnabled = false
    @AppStorage("drive_pref_open_offline") private var openOfflineOnView = true
    @State private var showImporter = false
    @State private var showResetConfirmation = false

    private var viewModel: DriveMoreViewModel {
        DriveMoreViewModel(store: store)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.profile.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text(store.profile.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.storageText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Preferences") {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                    Toggle("Show suggested files", isOn: $suggestionsEnabled)
                    Toggle("Use cellular for downloads", isOn: $cellularDownloadsEnabled)
                    Toggle("Open files offline when available", isOn: $openOfflineOnView)
                }

                Section("Storage") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.storageText)
                            .font(.subheadline.weight(.semibold))
                        ProgressView(value: store.profile.storageUsedGB / store.profile.storageLimitGB)
                        Text("\(store.offlineFiles(limit: 99).count) files available offline")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("Workspace Data") {
                    ForEach(WorkspaceSourceType.allCases) { sourceType in
                        Button {
                            store.switchSourceType(sourceType)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sourceType.title)
                                    if sourceType == .importedSnapshot {
                                        Text(viewModel.importedSnapshotFilename)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if store.envelope.selectedSourceType == sourceType {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .accessibilityIdentifier(sourceType == .bundledSnapshot ? AccessibilityID.debugSwitchSnapshotMode : "debug_switch_\(sourceType.rawValue)")
                    }

                    if let metadata = store.currentMetadata {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(metadata.providerLabel)
                                .font(.subheadline.weight(.semibold))
                            Text(metadata.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Updated \(AppFormatters.shortDateTime.string(from: metadata.snapshotTimestamp))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Import local workspace JSON") {
                        showImporter = true
                    }

                    Button("Refresh workspace packages") {
                        store.reloadSnapshots()
                    }
                }

                Section("Activity") {
                    if let lastHandoff = store.lastHandoff {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Last handoff")
                                .font(.subheadline.weight(.semibold))
                            Text("\(lastHandoff.sourceApp) -> \(lastHandoff.targetApp)")
                                .font(.footnote)
                            Text(AppFormatters.shortDateTime.string(from: lastHandoff.createdAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Open a file in Docs, Sheets, or Slides to record a handoff.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Persistence: \(store.storageModeLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Source: \(viewModel.sourceLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Reset") {
                    Button("Reset app state") {
                        showResetConfirmation = true
                    }
                    .foregroundStyle(.red)
                    .accessibilityIdentifier(AccessibilityID.profileResetAppState)
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DrivePalette.listSurface)
            .confirmationDialog("Reset Drive workspace?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("Reset App State", role: .destructive) {
                    store.resetAppState()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This restores the built-in workspace and removes local edits and imported package changes.")
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    store.importSnapshot(from: url)
                case .failure(let error):
                    store.activeAlert = AppAlert(id: "import_failed", title: "Import failed", message: error.localizedDescription)
                }
            }
            .overlay(alignment: .bottom) {
                if let message = store.transientMessage {
                    DriveToast(message: message)
                        .padding(.bottom, 20)
                }
            }
        }
    }
}
