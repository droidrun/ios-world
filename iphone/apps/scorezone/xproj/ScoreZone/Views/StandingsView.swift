import SwiftUI

struct StandingsView: View {
    @EnvironmentObject private var appState: AppState

    let league: League

    @State private var entries: [StandingEntry] = []
    @State private var loadState: LoadState = .idle
    @State private var dataOrigin: DataOrigin = .fallback
    @State private var warningMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    statusSection

                    if entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedEntries.keys.sorted(), id: \.self) { conference in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(conference.uppercased())
                                    .font(.caption.weight(.black))
                                    .tracking(1.2)
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 14)
                                    .padding(.bottom, 8)

                                ForEach(Array((groupedEntries[conference] ?? []).enumerated()), id: \.element.id) { index, entry in
                                    HStack {
                                        Text("\(entry.rank)")
                                            .frame(width: 24, alignment: .leading)
                                            .foregroundStyle(.white)
                                        Text(entry.team.displayName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text(entry.recordText)
                                            .foregroundStyle(.gray)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .accessibilityIdentifier("standings_row_\(AccessibilityID.slug(entry.leagueID))_\(AccessibilityID.slug(entry.conference))_\(entry.rank)")

                                    if index < (groupedEntries[conference] ?? []).count - 1 {
                                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 38)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(ScoreZoneColors.cardBackground)
                            )
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("\(league.shortName) Standings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("screen_standings_\(league.accessibilitySlug)")
        .task {
            if case .idle = loadState {
                await refresh()
            }
        }
        .onChange(of: appState.dataAccessMode) { _, _ in
            Task {
                await refresh()
            }
        }
        .refreshable {
            await refresh()
        }
    }

    private var groupedEntries: [String: [StandingEntry]] {
        Dictionary(grouping: entries, by: \.conference)
            .mapValues { rows in
                rows.sorted { lhs, rhs in
                    lhs.rank < rhs.rank
                }
            }
    }

    private var statusSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("League Table")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("standings_section_header")

                Text("Conference and division positioning")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .accessibilityIdentifier("standings_section_subtitle")
            }

            Spacer()

            Button {
                Task {
                    await refresh()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .tint(ScoreZoneColors.accentRed)
            .accessibilityIdentifier("standings_refresh_button")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var emptyState: some View {
        Text("No standings available")
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(ScoreZoneColors.cardBackground)
            )
            .accessibilityIdentifier("standings_empty_state")
    }

    private func refresh() async {
        loadState = .loading
        let result = await appState.repository.loadStandings(league: league, mode: appState.dataAccessMode)
        entries = result.value
        dataOrigin = result.origin
        warningMessage = result.warningMessage
        loadState = .loaded
        appState.refreshCacheMetadata()
    }

}
