import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var commentDrafts: [String: String] = [:]
    @State private var selectedWorkoutIndex = 0
    @State private var completedStepIDs: Set<String> = []

    private var viewModel: FeedViewModel {
        FeedViewModel(appState: appState)
    }

    private var workouts: [WorkoutPreset] {
        WorkoutCatalog.presets
    }

    private var momentumSteps: [MomentumStep] {
        [
            MomentumStep(id: "start_workout", title: "Start today's workout", subtitle: "Load an instant workout into Record and begin from the map.", icon: "bolt.fill", actionTitle: "Start"),
            MomentumStep(id: "join_club", title: "Join Bay Bridge Riders", subtitle: "Unlock the ride leaderboard and more club activity in Groups.", icon: "person.3.fill", actionTitle: "Join"),
            MomentumStep(id: "save_route", title: "Save a scenic route", subtitle: "Add one of the SF recommendations to your saved routes list.", icon: "map.fill", actionTitle: "Save"),
            MomentumStep(id: "review_progress", title: "Review March progress", subtitle: "Open your weekly totals, 12-week trend, and monthly summary.", icon: "chart.bar.fill", actionTitle: "Open")
        ]
    }

    private var recentActivities: [Activity] {
        Array(viewModel.activities(filter: .all).prefix(3))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                workoutsSection
                momentumSection
                recentSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        TrailBlazeTopHeaderBar(title: "Home") {
            HStack(spacing: 10) {
                Button {
                    appState.selectedTab = .profile
                } label: {
                    AthleteBadgeView(athleteName: appState.currentUser?.name ?? "L", size: 34)
                }
                .buttonStyle(.plain)

                Button {
                    appState.selectedTab = .routes
                } label: {
                    TrailBlazeIconButton(systemImage: "magnifyingglass", size: 34)
                }
                .buttonStyle(.plain)
            }
        } trailing: {
            HStack(spacing: 10) {
                NavigationLink(destination: InboxView()) {
                    TrailBlazeIconButton(systemImage: "bubble.left.and.bubble.right", size: 34)
                }
                NavigationLink(destination: NotificationsView()) {
                    TrailBlazeIconButton(systemImage: "bell", size: 34)
                }
            }
        }
    }

    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Instant Workouts", systemImage: "shield.lefthalf.filled")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                NavigationLink(destination: WorkoutLibraryView()) {
                    Text("See all")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            TabView(selection: $selectedWorkoutIndex) {
                ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                    Button {
                        appState.startWorkout(workout)
                    } label: {
                        InstantWorkoutHeroView(workout: workout)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)

            HStack(spacing: 6) {
                ForEach(workouts.indices, id: \.self) { index in
                    Circle()
                        .fill(index == selectedWorkoutIndex ? .white : .white.opacity(0.20))
                        .frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var momentumSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Keep that momentum going!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                ForEach(momentumSteps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index < completedStepIDs.count ? AppTheme.success : Color.white.opacity(0.12))
                        .frame(height: 5)
                }
                Text("\(completedStepIDs.count)/\(momentumSteps.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.leading, 2)
            }

            VStack(spacing: 10) {
                ForEach(momentumSteps) { step in
                    MomentumStepCardView(
                        step: step,
                        isComplete: completedStepIDs.contains(step.id),
                        onPrimaryAction: {
                            handleMomentumAction(step)
                        }
                    )
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView("From your network", subtitle: "Recent efforts from the people and clubs you follow")

            if recentActivities.isEmpty {
                EmptyStateView(
                    title: "No activities yet",
                    subtitle: "Switch data mode, record a workout, or reset the app to restore your feed.",
                    systemImage: "figure.run",
                    identifier: AccessibilityID.feedEmptyState
                )
            } else {
                ForEach(recentActivities) { activity in
                    ActivityCardView(
                        activity: activity,
                        athlete: appState.athlete(id: activity.athleteId),
                        route: activity.routeId.flatMap { appState.route(id: $0) },
                        activityDestination: AnyView(ActivityDetailView(activityId: activity.id)),
                        athleteDestination: AnyView(AthleteProfileView(athleteId: activity.athleteId)),
                        commentText: Binding(
                            get: { commentDrafts[activity.id, default: ""] },
                            set: { commentDrafts[activity.id] = $0 }
                        ),
                        onToggleKudos: {
                            appState.toggleKudos(for: activity.id)
                        },
                        onSubmitComment: {
                            appState.addComment(to: activity.id, message: commentDrafts[activity.id, default: ""])
                            commentDrafts[activity.id] = ""
                        },
                        onHideActivity: {
                            appState.deleteActivity(activity.id)
                        }
                    )
                }
            }
        }
    }

    private func handleMomentumAction(_ step: MomentumStep) {
        switch step.id {
        case "start_workout":
            completedStepIDs.insert(step.id)
            let workout = workouts[selectedWorkoutIndex]
            appState.startWorkout(workout)
        case "join_club":
            completedStepIDs.insert(step.id)
            if let club = appState.currentData.clubs.first(where: { $0.id == "club_002" && !$0.isJoined }) {
                appState.toggleClubMembership(club.id)
            } else {
                appState.selectedTab = .clubs
            }
        case "save_route":
            completedStepIDs.insert(step.id)
            if let route = appState.currentData.routes.first(where: { !$0.isSaved }) {
                appState.toggleRouteSaved(route.id)
            }
            appState.selectedTab = .routes
        default:
            completedStepIDs.insert(step.id)
            appState.selectedTab = .profile
        }
    }
}

private struct MomentumStep: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let actionTitle: String
}

private struct InstantWorkoutHeroView: View {
    let workout: WorkoutPreset

    var body: some View {
        WorkoutArtworkCard(preset: workout)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(16)
            }
            .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }
}

private struct MomentumStepCardView: View {
    let step: MomentumStep
    let isComplete: Bool
    let onPrimaryAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isComplete ? AppTheme.success : Color.white.opacity(0.24))

            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.backgroundMuted)
                    Image(systemName: step.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text(step.subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(isComplete ? "Done" : step.actionTitle) {
                    onPrimaryAction()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isComplete ? AppTheme.textSecondary : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isComplete ? Color.white.opacity(0.08) : AppTheme.accent)
                )
                .disabled(isComplete)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
}
