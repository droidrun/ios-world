import SwiftUI

struct ClubsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSection: GroupsSection = .challenges
    @State private var selectedSport: GroupsSport = .run
    @State private var joinedChallengeIDs: Set<String> = []
    @State private var commentDrafts: [String: String] = [:]

    private var viewModel: ClubsViewModel {
        ClubsViewModel(appState: appState)
    }

    private var clubs: [Club] {
        viewModel.clubs(filter: .all)
    }

    private var joinedClubs: [Club] {
        clubs.filter(\.isJoined)
    }

    private var featuredChallenge: Challenge? {
        appState.currentData.challenges.first
    }

    private var recommendedChallenges: [Challenge] {
        Array(appState.currentData.challenges.dropFirst())
    }

    private var featuredChallengeDateRange: String {
        AppFormatters.monthDateRange(for: Date())
    }

    private var activeClubActivities: [Activity] {
        let joinedIDs = Set(joinedClubs.map(\.id))
        return appState.currentData.activities.filter { activity in
            guard let clubId = activity.clubId, joinedIDs.contains(clubId) else { return false }
            guard let filterType = selectedSport.activityType else { return true }
            return activity.activityType == filterType
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                sectionTabs
                sportChips
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        TrailBlazeTopHeaderBar(title: "Groups") {
            Button {
                selectedSection = .clubs
            } label: {
                TrailBlazeIconButton(systemImage: "magnifyingglass", size: 46)
            }
            .buttonStyle(.plain)
        } trailing: {
            HStack(spacing: 16) {
                NavigationLink(destination: InboxView()) {
                    TrailBlazeIconButton(systemImage: "bubble.left.and.bubble.right", size: 46)
                }
                NavigationLink(destination: MoreView()) {
                    TrailBlazeIconButton(systemImage: "gearshape", size: 46)
                }
            }
        }
    }

    private var sectionTabs: some View {
        HStack(spacing: 0) {
            ForEach(GroupsSection.allCases, id: \.self) { section in
                Button {
                    selectedSection = section
                } label: {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text(section.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(selectedSection == section ? .white : AppTheme.textSecondary)
                            if section == .clubs && clubs.contains(where: { !$0.isJoined }) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 12, height: 12)
                            }
                        }

                        Rectangle()
                            .fill(selectedSection == section ? AppTheme.accent : .clear)
                            .frame(height: 4)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sportChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GroupsSport.allCases, id: \.self) { sport in
                    TrailBlazeChip(
                        title: sport.title,
                        systemImage: sport.systemImage,
                        isSelected: selectedSport == sport
                    ) {
                        selectedSport = sport
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedSection {
        case .challenges:
            challengesContent
        case .active:
            activeContent
        case .clubs:
            clubsContent
        }
    }

    private var challengesContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            if let featuredChallenge {
                VStack(spacing: 0) {
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.10, green: 0.18, blue: 0.32), Color(red: 0.17, green: 0.20, blue: 0.28)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Ellipse()
                            .stroke(.white.opacity(0.85), lineWidth: 6)
                            .frame(width: 280, height: 110)
                            .rotationEffect(.degrees(-8))
                        Text("TRAILBLAZE")
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .frame(height: 260)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color(red: 0.10, green: 0.18, blue: 0.24))
                                Text("10x")
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundStyle(Color.cyan)
                            }
                            .frame(width: 86, height: 86)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(featuredChallenge.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(featuredChallenge.subtitle)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(2)
                                Text(featuredChallengeDateRange)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }

                        Button(joinedChallengeIDs.contains(featuredChallenge.id) ? "Joined" : "Join") {
                            joinedChallengeIDs.insert(featuredChallenge.id)
                            appState.transientMessage = "Joined \(featuredChallenge.title)."
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                        .controlSize(.large)
                        .disabled(joinedChallengeIDs.contains(featuredChallenge.id))
                        .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.black)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    AthleteBadgeView(athleteName: appState.currentUser?.name ?? "L")
                        .frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recommended For You")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Based on your activities")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(recommendedChallenges) { challenge in
                            RecommendedChallengeCardView(
                                challenge: challenge,
                                isJoined: joinedChallengeIDs.contains(challenge.id)
                            ) {
                                joinedChallengeIDs.insert(challenge.id)
                                appState.transientMessage = "Joined \(challenge.title)."
                            }
                        }
                    }
                }
            }
        }
    }

    private var activeContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            SectionHeaderView("Active clubs", subtitle: "Communities you're currently following and the latest activity inside them")

            if joinedClubs.isEmpty {
                EmptyStateView(
                    title: "No club membership",
                    subtitle: "Join a club to unlock weekly rankings and club activity feed views.",
                    systemImage: "person.3",
                    identifier: AccessibilityID.clubsEmptyMembershipState
                )
            } else {
                ForEach(joinedClubs) { club in
                    NavigationLink(destination: ClubDetailView(clubId: club.id)) {
                        ClubCardView(club: club)
                    }
                    .buttonStyle(.plain)
                }

                if activeClubActivities.isEmpty {
                    EmptyStateView(
                        title: "No activity for this sport yet",
                        subtitle: "Switch the sport filter or record something new to bring this view to life.",
                        systemImage: "bolt.heart",
                        identifier: "club_activity_empty_state"
                    )
                } else {
                    ForEach(activeClubActivities.prefix(2)) { activity in
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
    }

    private var clubsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView("Clubs", subtitle: "Browse nearby groups, compare weekly volume, and join from the directory")

            ForEach(clubs) { club in
                VStack(alignment: .leading, spacing: 14) {
                    NavigationLink(destination: ClubDetailView(clubId: club.id)) {
                        ClubCardView(club: club)
                    }
                    .buttonStyle(.plain)

                    Button(club.isJoined ? "Leave Club" : "Join Club") {
                        appState.toggleClubMembership(club.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(club.isJoined ? .gray : AppTheme.accent)
                    .accessibilityIdentifier(AccessibilityID.clubJoinButton(club.id))
                }
            }
        }
    }
}

struct ClubDetailView: View {
    @EnvironmentObject private var appState: AppState
    @State private var commentDrafts: [String: String] = [:]

    let clubId: String

    private var viewModel: ClubDetailViewModel {
        ClubDetailViewModel(appState: appState, clubId: clubId)
    }

    var body: some View {
        ScrollView {
            if let club = viewModel.club {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeaderView(club.name, subtitle: club.description)

                    Button(club.isJoined ? "Leave Club" : "Join Club") {
                        appState.toggleClubMembership(club.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(club.isJoined ? .gray : AppTheme.accent)
                    .accessibilityIdentifier(AccessibilityID.clubJoinButton(club.id))

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderView("Weekly Leaderboard", subtitle: "Compare current mileage with club members")
                        ForEach(club.weeklyLeaderboard) { entry in
                            HStack {
                                Text("#\(entry.rank)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.athleteName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(AppFormatters.distance(Double(entry.timeSeconds) / 180))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.backgroundMuted)
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderView("Club Activity Feed")
                        if viewModel.activities.isEmpty {
                            EmptyStateView(
                                title: "No club activity yet",
                                subtitle: "Switch sources or reset the app to repopulate the club feed.",
                                systemImage: "bolt.heart",
                                identifier: "club_activity_empty_state"
                            )
                        } else {
                            ForEach(viewModel.activities) { activity in
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
                .padding(20)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Club")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum GroupsSection: CaseIterable {
    case active
    case challenges
    case clubs

    var title: String {
        switch self {
        case .active: return "Active"
        case .challenges: return "Challenges"
        case .clubs: return "Clubs"
        }
    }
}

private enum GroupsSport: CaseIterable {
    case run
    case ride
    case swim
    case walk
    case hike

    var title: String {
        switch self {
        case .run: return "Run"
        case .ride: return "Ride"
        case .swim: return "Swim"
        case .walk: return "Walk"
        case .hike: return "Hike"
        }
    }

    var systemImage: String {
        switch self {
        case .run: return "figure.run"
        case .ride: return "bicycle"
        case .swim: return "figure.pool.swim"
        case .walk: return "figure.walk"
        case .hike: return "figure.hiking"
        }
    }

    var activityType: ActivityType? {
        switch self {
        case .run: return .run
        case .ride: return .ride
        case .swim: return nil
        case .walk: return .walk
        case .hike: return .hike
        }
    }
}

private struct RecommendedChallengeCardView: View {
    let challenge: Challenge
    let isJoined: Bool
    let action: () -> Void

    private var accentColor: Color {
        challenge.title.contains("Ultra") ? .cyan : AppTheme.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.24))
                    .frame(width: 110, height: 110)
                Text(challenge.title.contains("Ultra") ? "33.3" : "400'")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(accentColor)
            }

            Text(challenge.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(challenge.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(3)

            Button(isJoined ? "Joined" : "Join") {
                action()
            }
            .buttonStyle(.borderedProminent)
            .tint(isJoined ? .gray : AppTheme.accent)
            .disabled(isJoined)
        }
        .padding(18)
        .frame(width: 280, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }
}

private struct ClubCardView: View {
    let club: Club

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(club.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(club.description)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Text("\(club.memberCount)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
            }

            HStack {
                Text("\(club.memberCount) members")
                Spacer()
                Text(club.isJoined ? "Joined" : "Tap to view")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
        .accessibilityIdentifier(AccessibilityID.clubRow(club.id))
    }
}
