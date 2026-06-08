import SwiftUI
import UniformTypeIdentifiers

struct MoreView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingImporter = false

    private var viewModel: MoreViewModel {
        MoreViewModel(appState: appState)
    }

    private var snapshotUnavailable: Bool {
        switch appState.selectedDataMode {
        case .seeded:
            return false
        case .bundledSnapshot:
            return !appState.bundledSnapshotAvailable
        case .sandboxSnapshot:
            return !appState.sandboxSnapshotAvailable
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                settingsSummary
                dataSourcesCard
                privacyCard
                debugCard
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appState.importSandboxSnapshot(from: url)
                }
            case .failure(let error):
                appState.lastErrorMessage = error.localizedDescription
            }
        }
    }

    private var settingsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Control your offline data setup")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("Switch data sources, import snapshots, and reset the app without leaving this screen.")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text("Default location: \(BenchmarkLocation.city)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
        }
    }

    private var dataSourcesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Sources")
                .font(.headline)
                .foregroundStyle(.white)

            Picker(
                "Activity Source",
                selection: Binding(
                    get: { appState.selectedDataMode },
                    set: { appState.switchDataMode($0) }
                )
            ) {
                ForEach(ActivityDataMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                        .accessibilityIdentifier(AccessibilityID.dataModeOption(mode))
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AccessibilityID.debugSwitchActivitySource)

            Text("Current mode: \(viewModel.selectedMode.title)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            if let importedSnapshotName = viewModel.importedSnapshotName {
                Text("Imported sandbox file: \(importedSnapshotName)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 12) {
                Button("Reload Snapshot File") {
                    appState.reloadSelectedSnapshot()
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .accessibilityIdentifier("reload_snapshot_button")

                Button("Import Snapshot JSON") {
                    showingImporter = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .accessibilityIdentifier("import_snapshot_button")
            }

            if snapshotUnavailable {
                EmptyStateView(
                    title: "Snapshot unavailable",
                    subtitle: "Import a sandbox JSON file or switch back to default mode.",
                    systemImage: "tray",
                    identifier: AccessibilityID.snapshotUnavailableState
                )
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.headline)
                .foregroundStyle(.white)
            Text("This app stays fully offline. No live GPS, HealthKit, or network requests are used; route defaults are centered on the default San Francisco location.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(18)
        .background(cardBackground)
    }

    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Debug Tools")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Use reset to restore default data and clear imported snapshots.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Button("Reset App State", role: .destructive) {
                appState.resetAppState()
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .accessibilityIdentifier(AccessibilityID.profileResetAppState)
        }
        .padding(18)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(AppTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.divider, lineWidth: 1)
            )
    }
}
