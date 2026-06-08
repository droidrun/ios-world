import SwiftUI

struct MoreSettingsView: View {
    @ObservedObject var viewModel: MoreViewModel

    var body: some View {
        List {
            Section("App settings") {
                Text(viewModel.currentSourceLabel)
                    .accessibilityIdentifier("current_data_source_label")

                NavigationLink {
                    DebugImportView(viewModel: viewModel)
                } label: {
                    Text("Offline / Import")
                }
                .accessibilityIdentifier("more_debug_import_link")
            }

            Section("Order lifecycle") {
                if let activeOrder = viewModel.activeOrder {
                    Text("Active order: \(activeOrder.orderNumber)")
                    Button("Advance active order state") {
                        viewModel.advanceActiveOrder()
                    }
                    .accessibilityIdentifier("advance_active_order_state_button")
                } else {
                    Text("No active orders")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("no_active_orders_state")
                }
            }

            Section("Storage") {
                Button("Reset app state") {
                    viewModel.resetAppState()
                }
                .foregroundStyle(.red)
                .accessibilityIdentifier("account_reset_app_state")
            }

            Section("About") {
                Text("Fully offline grocery ordering experience.")
                Text("Catalog data can be updated by importing a snapshot file.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DebugImportView: View {
    @ObservedObject var viewModel: MoreViewModel

    var body: some View {
        List {
            Section("Catalog source") {
                HStack(spacing: 10) {
                    Button("Default") {
                        viewModel.switchSource(.seeded)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.sourceType == .seeded ? .green : .gray.opacity(0.2))
                    .foregroundStyle(viewModel.sourceType == .seeded ? .white : .primary)
                    .accessibilityIdentifier("catalog_source_seeded")

                    Button("Snapshot") {
                        viewModel.switchSource(.snapshot)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.sourceType == .snapshot ? .green : .gray.opacity(0.2))
                    .foregroundStyle(viewModel.sourceType == .snapshot ? .white : .primary)
                    .accessibilityIdentifier("catalog_source_snapshot")
                }

                Text("Current: \(viewModel.currentSourceLabel)")
                    .font(.subheadline)
                    .accessibilityIdentifier("current_catalog_source_label")

                Button("Reload bundled snapshot data") {
                    viewModel.reloadSnapshot()
                }
                .accessibilityIdentifier("reload_snapshot_button")
            }

            Section("Snapshot metadata") {
                if let metadata = viewModel.metadata {
                    Text("Provider: \(metadata.providerLabel)")
                        .accessibilityIdentifier("snapshot_provider_label")
                    Text("Snapshot: \(AppFormatters.dateTime.string(from: metadata.snapshotTimestamp))")
                        .accessibilityIdentifier("snapshot_timestamp_label")
                    Text("Last updated: \(AppFormatters.dateTime.string(from: metadata.lastUpdated))")
                        .accessibilityIdentifier("snapshot_last_updated_label")
                } else {
                    Text("Snapshot data unavailable")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("snapshot_data_unavailable_state")
                }
            }

            Section("Lifecycle controls") {
                if let activeOrder = viewModel.activeOrder {
                    Text("Target order: \(activeOrder.orderNumber)")
                    Button("Advance active order state locally") {
                        viewModel.advanceActiveOrder()
                    }
                    .accessibilityIdentifier("advance_active_order_state_button")
                } else {
                    Text("No active orders")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("no_active_orders_state")
                }
            }

            Section("Storage") {
                Text("Sandbox snapshot path: \(viewModel.persistencePathLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("sandbox_snapshot_path_label")

                Button("Reset app state") {
                    viewModel.resetAppState()
                }
                .foregroundStyle(.red)
                .accessibilityIdentifier("account_reset_app_state")
            }
        }
        .navigationTitle("Offline / Import")
        .navigationBarTitleDisplayMode(.inline)
    }
}
