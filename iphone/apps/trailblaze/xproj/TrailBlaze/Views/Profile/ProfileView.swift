import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSection: YouSection = .progress
    @State private var selectedSport: ActivityType = .run

    private var viewModel: ProfileViewModel {
        ProfileViewModel(appState: appState)
    }

    private let calendar = Calendar.current

    private var thisWeekActivities: [Activity] {
        activitiesForCurrentWeek(of: selectedSport)
    }

    private var thisWeekDistance: Double {
        thisWeekActivities.reduce(0) { $0 + $1.distanceKilometers }
    }

    private var thisWeekDuration: Int {
        thisWeekActivities.reduce(0) { $0 + $1.durationSeconds }
    }

    private var thisWeekElevation: Double {
        thisWeekActivities.reduce(0) { $0 + $1.elevationGainMeters }
    }

    private var weeklyDistanceValues: [Double] {
        (0..<12).reversed().map { offset in
            let weekActivities = activities(inWeekOffset: offset, type: selectedSport)
            return weekActivities.reduce(0) { $0 + AppFormatters.milesValue($1.distanceKilometers) }
        }
    }

    private var monthlyActivities: [Activity] {
        viewModel.activities.filter {
            calendar.isDate($0.startTime, equalTo: Date(), toGranularity: .month)
        }
    }

    private var monthlyStreakWeeks: Int {
        Set(monthlyActivities.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.startTime)?.start }).count
    }

    private var monthlyDistance: Double {
        monthlyActivities.reduce(0) { $0 + $1.distanceKilometers }
    }

    private var monthlyLabels: [String] {
        let dates = [10, 5, 0].compactMap { weeksBack -> Date? in
            calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: Date())
        }
        return dates.map(AppFormatters.monthAbbreviation)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                sectionTabs
                if selectedSection == .progress {
                    progressSection
                } else {
                    activitiesSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        TrailBlazeTopHeaderBar(title: "You") {
            AthleteBadgeView(athleteName: viewModel.athlete?.name ?? "L", size: 34)
        } trailing: {
            HStack(spacing: 10) {
                Button {
                    appState.selectedTab = .record
                } label: {
                    TrailBlazeIconButton(systemImage: "plus", size: 34)
                }
                .buttonStyle(.plain)

                NavigationLink(destination: MoreView()) {
                    TrailBlazeIconButton(systemImage: "gearshape", size: 34)
                }
            }
        }
    }

    private var sectionTabs: some View {
        HStack(spacing: 0) {
            ForEach(YouSection.allCases, id: \.self) { section in
                Button {
                    selectedSection = section
                } label: {
                    VStack(spacing: 8) {
                        Text(section.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(selectedSection == section ? .white : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(selectedSection == section ? AppTheme.accent : .clear)
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            workoutsPreview

            TrailBlazeChip(
                title: selectedSport.title,
                systemImage: selectedSport.systemImage,
                isSelected: true
            ) {
                selectedSport = nextSport(after: selectedSport)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("This week")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    progressMetric(title: "Distance", value: AppFormatters.distance(thisWeekDistance))
                    progressMetric(title: "Time", value: AppFormatters.duration(thisWeekDuration))
                    progressMetric(title: "Elev Gain", value: AppFormatters.elevation(thisWeekElevation))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Past 12 weeks")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    WeekTrendChartView(values: weeklyDistanceValues, labels: monthlyLabels)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )

            if let athlete = viewModel.athlete, !athlete.personalRecords.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Personal Records")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    ForEach(athlete.personalRecords, id: \.self) { record in
                        HStack {
                            let parts = record.split(separator: " ", maxSplits: 1)
                            Text(String(parts.first ?? ""))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text(String(parts.last ?? ""))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.cardBackground)
                )
                .accessibilityIdentifier("personal_records_section")
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(AppFormatters.monthYear(Date()))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    ShareLink(
                        item: "\(AppFormatters.monthYear(Date())) summary: \(AppFormatters.distance(monthlyDistance)) across \(monthlyActivities.count) activities on TrailBlaze."
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .disabled(monthlyActivities.isEmpty)
                }

                HStack(spacing: 16) {
                    progressMetric(title: "Your Streak", value: "\(monthlyStreakWeeks) Weeks")
                    progressMetric(title: "Streak Activities", value: "\(monthlyActivities.count)")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    private var workoutsPreview: some View {
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

            NavigationLink(destination: WorkoutLibraryView()) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.53, green: 0.05, blue: 0.05), Color(red: 0.86, green: 0.27, blue: 0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            VStack(spacing: 6) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 24, weight: .bold))
                                Text("30m")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(.white)
                        }
                        .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Foundation Strength")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Build a strong foundation with bodyweight exercises.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.cardBackground)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView("Activities", subtitle: "Your recent workouts, routes, and uploads")

            if viewModel.activities.isEmpty {
                EmptyStateView(
                    title: "No activities yet",
                    subtitle: "Record an activity to build your history.",
                    systemImage: "clock.arrow.circlepath",
                    identifier: "profile_activity_empty_state"
                )
            } else {
                ForEach(viewModel.activities) { activity in
                    NavigationLink(destination: ActivityDetailView(activityId: activity.id)) {
                        HStack(spacing: 10) {
                            AthleteBadgeView(athleteName: viewModel.athlete?.name ?? "L", size: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("\(AppFormatters.shortDate(activity.startTime)) • \(activity.activityType.title)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(AppFormatters.distance(activity.distanceKilometers))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(AppFormatters.duration(activity.durationSeconds))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Reset App State", role: .destructive) {
                appState.resetAppState()
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .accessibilityIdentifier(AccessibilityID.profileResetAppState)
        }
    }

    private func progressMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nextSport(after type: ActivityType) -> ActivityType {
        let supported: [ActivityType] = [.run, .ride, .walk, .hike]
        guard let index = supported.firstIndex(of: type) else { return .run }
        return supported[(index + 1) % supported.count]
    }

    private func activitiesForCurrentWeek(of type: ActivityType) -> [Activity] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return viewModel.activities.filter { activity in
            activity.activityType == type && interval.contains(activity.startTime)
        }
    }

    private func activities(inWeekOffset offset: Int, type: ActivityType) -> [Activity] {
        guard
            let referenceDate = calendar.date(byAdding: .weekOfYear, value: -offset, to: Date()),
            let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        else {
            return []
        }

        return viewModel.activities.filter { activity in
            activity.activityType == type && interval.contains(activity.startTime)
        }
    }
}

struct AthleteProfileView: View {
    @EnvironmentObject private var appState: AppState

    let athleteId: String

    private var viewModel: AthleteProfileViewModel {
        AthleteProfileViewModel(appState: appState, athleteId: athleteId)
    }

    var body: some View {
        ScrollView {
            if let athlete = viewModel.athlete {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        AthleteBadgeView(athleteName: athlete.name)
                            .frame(width: 62, height: 62)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(athlete.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            Text(athlete.handle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(athlete.bio)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    MetricGridView(
                        items: [
                            MetricItem(label: "Total Distance", value: AppFormatters.distance(viewModel.totalDistanceKilometers)),
                            MetricItem(label: "Activities", value: AppFormatters.integer(viewModel.activities.count)),
                            MetricItem(label: "Followers", value: AppFormatters.integer(athlete.followerCount)),
                            MetricItem(label: "Following", value: AppFormatters.integer(athlete.followingCount))
                        ]
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderView("Recent Activities")
                        ForEach(viewModel.activities) { activity in
                            NavigationLink(destination: ActivityDetailView(activityId: activity.id)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activity.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text("\(AppFormatters.shortDate(activity.startTime)) • \(activity.activityType.title)")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Text(AppFormatters.distance(activity.distanceKilometers))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppTheme.backgroundMuted)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Athlete")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum YouSection: CaseIterable {
    case progress
    case activities

    var title: String {
        switch self {
        case .progress: return "Progress"
        case .activities: return "Activities"
        }
    }
}
