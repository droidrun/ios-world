import SwiftUI

struct ActivityDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    let activityId: String

    private var viewModel: ActivityDetailViewModel {
        ActivityDetailViewModel(appState: appState, activityId: activityId)
    }

    private var trimmedCommentText: String {
        commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Group {
            if let activity = viewModel.activity {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        hero(for: activity)

                        MapPlaceholderView(
                            points: viewModel.route?.points ?? [],
                            routes: viewModel.route.map { [$0] } ?? [],
                            highlightedRouteId: viewModel.route?.id,
                            height: 250
                        )

                        detailCard {
                            SectionHeaderView("Performance Snapshot", subtitle: metricSubtitle(for: activity))

                            MetricGridView(
                                items: [
                                    MetricItem(label: "Distance", value: AppFormatters.distance(activity.distanceKilometers)),
                                    MetricItem(label: "Duration", value: AppFormatters.duration(activity.durationSeconds)),
                                    MetricItem(label: activity.activityType == .ride || activity.activityType == .indoorRide ? "Speed" : "Pace", value: AppFormatters.primaryPerformanceMetric(for: activity)),
                                    MetricItem(label: "Elev Gain", value: AppFormatters.elevation(activity.elevationGainMeters)),
                                    MetricItem(label: "Calories", value: AppFormatters.integer(activity.calories)),
                                    MetricItem(label: "Kudos", value: AppFormatters.integer(activity.kudosCount))
                                ]
                            )
                        }

                        detailCard {
                            SectionHeaderView("Elevation Profile", subtitle: viewModel.route?.name ?? "Auto-generated from this activity")
                            ElevationProfileView(values: viewModel.route?.elevationProfile ?? [])
                        }

                        detailCard {
                            SectionHeaderView("Splits", subtitle: splitSubtitle(for: activity))

                            ForEach(activity.splits) { split in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Split \(split.index)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text(AppFormatters.distance(split.distanceKilometers))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }

                                    Spacer()

                                    Text(AppFormatters.duration(split.durationSeconds))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(AppTheme.backgroundMuted)
                                )
                            }
                        }

                        detailCard {
                            SectionHeaderView("Segment Results", subtitle: "Tap a segment to inspect the leaderboard")

                            if viewModel.segments.isEmpty {
                                EmptyStateView(
                                    title: "No segments on this activity",
                                    subtitle: "Choose a saved route with mapped segments or record a ride with a more competitive route.",
                                    systemImage: "flag.slash",
                                    identifier: "activity_segments_empty_state"
                                )
                            } else {
                                ForEach(viewModel.segments) { segment in
                                    let result = activity.segmentResults.first(where: { $0.segmentId == segment.id })

                                    NavigationLink(destination: SegmentDetailView(segmentId: segment.id)) {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(AppTheme.accentMuted)
                                                Image(systemName: "flag.checkered")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(AppTheme.accent)
                                            }
                                            .frame(width: 42, height: 42)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(segment.name)
                                                    .font(.system(size: 17, weight: .bold))
                                                    .foregroundStyle(.white)
                                                Text("\(AppFormatters.distance(segment.distanceKilometers)) • \(AppFormatters.decimal(segment.gradePercent))% grade")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(AppTheme.textSecondary)
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text(result.map { AppFormatters.duration($0.timeSeconds) } ?? "--")
                                                    .font(.system(size: 17, weight: .bold))
                                                    .foregroundStyle(.white)
                                                Text("Rank \(result?.rank ?? 0)")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(AppTheme.accent)
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(AppTheme.backgroundMuted)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier(AccessibilityID.segmentRow(segment.id))
                                }
                            }
                        }

                        detailCard {
                            SectionHeaderView("Kudos and Comments", subtitle: "React to the effort or add context for your future self")

                            Button {
                                appState.toggleKudos(for: activity.id)
                            } label: {
                                Label(
                                    activity.hasCurrentUserKudo ? "Remove Kudos" : "Give Kudos",
                                    systemImage: activity.hasCurrentUserKudo ? "hand.thumbsup.fill" : "hand.thumbsup"
                                )
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accent)
                            .accessibilityIdentifier(AccessibilityID.kudosButton(activity.id))

                            HStack(alignment: .top, spacing: 10) {
                                TrailBlazeInsetTextField(title: "Add a comment", text: $commentText)
                                    .accessibilityIdentifier(AccessibilityID.commentField(activity.id))

                                Button("Post") {
                                    appState.addComment(to: activity.id, message: trimmedCommentText)
                                    commentText = ""
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.accent)
                                .disabled(trimmedCommentText.isEmpty)
                                .accessibilityIdentifier(AccessibilityID.commentSendButton(activity.id))
                            }

                            if activity.comments.isEmpty {
                                EmptyStateView(
                                    title: "No comments yet",
                                    subtitle: "Start the conversation with a quick note or training takeaway.",
                                    systemImage: "bubble.left",
                                    identifier: "activity_comments_empty_state"
                                )
                            } else {
                                ForEach(activity.comments) { comment in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(appState.athlete(id: comment.athleteId)?.name ?? "Athlete")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Text(AppFormatters.shortDate(comment.createdAt))
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }

                                        Text(comment.message)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(AppTheme.backgroundMuted)
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .accessibilityIdentifier(AccessibilityID.activityDetailView)
                .background(AppTheme.background.ignoresSafeArea())
                .navigationTitle("Activity")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if viewModel.isOwnedByCurrentUser {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button("Edit") {
                                showingEditSheet = true
                            }

                            Button("Delete", role: .destructive) {
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    if let activity = viewModel.activity {
                        ActivityEditSheet(activity: activity) { title, type in
                            appState.updateActivity(activity.id, title: title, type: type)
                        }
                    }
                }
                .confirmationDialog("Delete Activity", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete Activity", role: .destructive) {
                        appState.deleteActivity(activity.id)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This removes the activity from the feed and profile history.")
                }
            } else {
                ScrollView {
                    EmptyStateView(
                        title: "Activity unavailable",
                        subtitle: "This activity may have been deleted or removed after a reset.",
                        systemImage: "exclamationmark.triangle",
                        identifier: AccessibilityID.activityDetailView
                    )
                    .padding(20)
                }
                .background(AppTheme.background.ignoresSafeArea())
            }
        }
    }

    private func hero(for activity: Activity) -> some View {
        detailCard {
            HStack(alignment: .top, spacing: 14) {
                AthleteBadgeView(athleteName: viewModel.athlete?.name ?? "Athlete")
                    .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text(viewModel.athlete?.name ?? "Unknown Athlete")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(AppFormatters.fullDate(activity.startTime))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 12)
            }

            HStack(spacing: 10) {
                metadataPill(
                    title: activity.activityType.title,
                    systemImage: activity.activityType.systemImage,
                    accent: true
                )

                metadataPill(
                    title: activity.sourceType.rawValue.capitalized,
                    systemImage: "circle.grid.2x1"
                )

                if let route = viewModel.route {
                    metadataPill(title: route.startLocation, systemImage: "location")
                }
            }
        }
    }

    private func metadataPill(title: String, systemImage: String, accent: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(accent ? .black : .white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(accent ? AppTheme.accent : AppTheme.backgroundMuted)
        )
        .overlay(
            Capsule()
                .stroke(accent ? AppTheme.accent : AppTheme.divider, lineWidth: 1)
        )
    }

    private func metricSubtitle(for activity: Activity) -> String {
        if let route = viewModel.route {
            return "\(route.name) • \(route.startLocation)"
        }
        return "\(activity.activityType.title) activity"
    }

    private func splitSubtitle(for activity: Activity) -> String {
        activity.activityType == .ride || activity.activityType == .indoorRide
            ? "Autogenerated 5-mile blocks"
            : "Autogenerated mile-by-mile breakdown"
    }

    private func detailCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }
}

struct SegmentDetailView: View {
    @EnvironmentObject private var appState: AppState

    let segmentId: String

    private var segment: Segment? {
        appState.segment(id: segmentId)
    }

    private var route: Route? {
        segment.flatMap { appState.route(id: $0.routeId) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if let segment {
                VStack(alignment: .leading, spacing: 20) {
                    segmentHero(segment)

                    MapPlaceholderView(
                        points: route?.points ?? [],
                        routes: route.map { [$0] } ?? [],
                        highlightedRouteId: route?.id,
                        height: 230
                    )

                    segmentCard {
                        SectionHeaderView("Segment Snapshot", subtitle: route?.startLocation ?? "Matched route")

                        MetricGridView(
                            items: [
                                MetricItem(label: "Distance", value: AppFormatters.distance(segment.distanceKilometers)),
                                MetricItem(label: "Grade", value: "\(AppFormatters.decimal(segment.gradePercent))%"),
                                MetricItem(label: "Leaderboard", value: AppFormatters.integer(segment.leaderboard.count)),
                                MetricItem(label: "Route", value: route?.name ?? "Route")
                            ]
                        )
                    }

                    segmentCard {
                        SectionHeaderView("Leaderboard", subtitle: "Top rides and runs on this segment")

                        ForEach(segment.leaderboard) { entry in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(rankColor(for: entry.rank).opacity(0.18))
                                    Text("#\(entry.rank)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(rankColor(for: entry.rank))
                                }
                                .frame(width: 42, height: 42)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.athleteName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text(rankSubtitle(for: entry.rank))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                Spacer()

                                Text(AppFormatters.duration(entry.timeSeconds))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(AppTheme.backgroundMuted)
                            )
                            .accessibilityIdentifier(AccessibilityID.segmentLeaderboardRow(entry.id))
                        }
                    }
                }
                .padding(20)
            } else {
                EmptyStateView(
                    title: "Segment unavailable",
                    subtitle: "This segment may have been removed after changing the current data source.",
                    systemImage: "road.lanes",
                    identifier: "segment_unavailable_state"
                )
                .padding(20)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Segment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func segmentHero(_ segment: Segment) -> some View {
        segmentCard {
            SectionHeaderView(
                segment.name,
                subtitle: "\(AppFormatters.distance(segment.distanceKilometers)) • \(AppFormatters.decimal(segment.gradePercent))% average grade"
            )

            if let route {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(route.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(route.startLocation)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func segmentCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color.yellow
        case 2: return Color(red: 0.76, green: 0.80, blue: 0.84)
        case 3: return Color(red: 0.86, green: 0.55, blue: 0.29)
        default: return AppTheme.accent
        }
    }

    private func rankSubtitle(for rank: Int) -> String {
        switch rank {
        case 1: return "Segment leader"
        case 2...3: return "Podium ride"
        default: return "Top 10 effort"
        }
    }
}

private struct ActivityEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var selectedType: ActivityType

    let onSave: (String, ActivityType) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(activity: Activity, onSave: @escaping (String, ActivityType) -> Void) {
        _title = State(initialValue: activity.title)
        _selectedType = State(initialValue: activity.activityType)
        self.onSave = onSave
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeaderView("Edit Activity", subtitle: "Update the title or recategorize the saved workout")

                    TrailBlazeInsetTextField(title: "Activity Title", text: $title)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Type")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ActivityType.allCases) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: type.systemImage)
                                            .font(.system(size: 17, weight: .bold))
                                        Text(type.title)
                                            .font(.system(size: 15, weight: .bold))
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(selectedType == type ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(selectedType == type ? AppTheme.accent : AppTheme.backgroundMuted)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(selectedType == type ? AppTheme.accent : AppTheme.divider, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(trimmedTitle, selectedType)
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
