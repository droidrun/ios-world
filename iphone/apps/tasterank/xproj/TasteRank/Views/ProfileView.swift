import SwiftUI

private enum ProfileCollectionDestination: String, Identifiable {
    case been = "Been"
    case wantToTry = "Want to Try"
    case recs = "Recs for You"

    var id: String { rawValue }
}

enum FollowListTab: String, CaseIterable {
    case followers = "Followers"
    case following = "Following"
}

struct ProfileView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @State private var showingShareSheet = false
    @State private var showingActionsSheet = false
    @State private var showingEditProfile = false
    @State private var showingSchoolEditor = false
    @State private var showingGoalCustomize = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                profileSummary
                statButtons
                listRows
                highlightTiles
                goalCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingShareSheet) {
            TasteRankShareSheet(
                title: "Share Profile",
                message: "Follow \(profile.handle) on TasteRank. \(profile.beenCount) spots ranked so far."
            )
        }
        .sheet(isPresented: $showingActionsSheet) {
            ProfileActionsSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingEditProfile) {
            ProfileEditSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingSchoolEditor) {
            SchoolEditorSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingGoalCustomize) {
            GoalCustomizeSheet()
                .environmentObject(store)
        }
    }

    private var profile: UserProfileSummary {
        store.currentUserProfile
    }

    private var header: some View {
        HStack {
            Text(profile.displayName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer()
            HStack(spacing: 8) {
                TasteRankIconButton(systemName: "square.and.arrow.up", size: 18) {
                    showingShareSheet = true
                }
                TasteRankIconButton(systemName: "line.3.horizontal", size: 18) {
                    showingActionsSheet = true
                }
            }
        }
    }

    private var profileSummary: some View {
        VStack(spacing: 8) {
            TasteRankAvatarView(
                seed: profile.handle,
                initials: profile.initials,
                size: 80,
                neutral: true
            )
            Text(profile.handle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
            Text(profile.memberSince)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(MockTasteRankTheme.textSecondary)

            Button(profile.schoolName ?? "+ Add School") {
                showingSchoolEditor = true
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(MockTasteRankTheme.accent)

            HStack {
                NavigationLink {
                    FollowListView(initialTab: .followers)
                } label: {
                    ProfileCountView(value: "\(profile.followers)", title: "Followers")
                }
                .buttonStyle(.plain)

                Spacer()

                NavigationLink {
                    FollowListView(initialTab: .following)
                } label: {
                    ProfileCountView(value: "\(profile.following)", title: "Following")
                }
                .buttonStyle(.plain)

                Spacer()
                ProfileCountView(value: profile.formattedRank, title: "Rank on TasteRank")
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    private var statButtons: some View {
        HStack(spacing: 8) {
            BorderedActionButton(title: "Edit profile") {
                showingEditProfile = true
            }
            BorderedActionButton(title: "Share profile") {
                showingShareSheet = true
            }

            Button {
                showingActionsSheet = true
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(CardBackground(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var listRows: some View {
        VStack(spacing: 0) {
            NavigationLink {
                ProfileRestaurantCollectionView(
                    title: ProfileCollectionDestination.been.rawValue,
                    restaurants: store.visitedRestaurants
                )
            } label: {
                ProfileCollectionRow(icon: "checkmark.circle", title: "Been", value: "\(profile.beenCount)")
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfileRestaurantCollectionView(
                    title: ProfileCollectionDestination.wantToTry.rawValue,
                    restaurants: store.wantToTryRestaurants
                )
            } label: {
                ProfileCollectionRow(icon: "bookmark.fill", title: "Want to Try", value: "\(profile.wantToTryCount)")
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfileRestaurantCollectionView(
                    title: ProfileCollectionDestination.recs.rawValue,
                    restaurants: store.recommendedRestaurantsFromFriends()
                )
            } label: {
                ProfileCollectionRow(icon: "heart.circle", title: "Recs for You", value: "\(store.recommendedRestaurantsFromFriends().count)")
            }
            .buttonStyle(.plain)
        }
    }

    private var highlightTiles: some View {
        HStack(spacing: 10) {
            HighlightTile(
                icon: "trophy",
                title: "Rank on TasteRank",
                value: profile.formattedRank,
                accent: MockTasteRankTheme.accent
            )
            HighlightTile(
                icon: "drop.fill",
                title: "Current Streak",
                value: profile.streakLabel,
                accent: MockTasteRankTheme.accent
            )
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Set your \(String(profile.goalYear)) goal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                    Text("You tried \(profile.lastYearCount) spots in 2025!\nHow many do you want to try in \(String(profile.goalYear))?")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                        .lineSpacing(2)
                }
                Spacer()
                Text("🏆")
                    .font(.system(size: 40))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(profile.goalOptions) { option in
                        Button {
                            if option.id == "customize" {
                                showingGoalCustomize = true
                            } else {
                                store.selectGoalOption(option.id)
                            }
                        } label: {
                            Text(option.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(option.id == profile.selectedGoalID ? MockTasteRankTheme.textPrimary : MockTasteRankTheme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(option.id == profile.selectedGoalID ? MockTasteRankTheme.surface : Color.clear)
                                        .overlay(
                                            Capsule(style: .continuous)
                                                .stroke(Color(red: 0.71, green: 0.74, blue: 0.86), lineWidth: 1.6)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(CardBackground(cornerRadius: 18))
    }
}

private struct ProfileCountView: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BorderedActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(CardBackground(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileCollectionRow: View {
    let icon: String
    let title: String
    let value: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)

            Spacer()

            if let value {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MockTasteRankTheme.border)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MockTasteRankTheme.divider)
                .frame(height: 1)
        }
    }
}

private struct HighlightTile: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(accent)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(14)
        .background(CardBackground(cornerRadius: 16))
    }
}

private struct ProfileEditSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var handle = ""
    @State private var schoolName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display Name", text: $displayName)
                    TextField("Handle", text: $handle)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    TextField("School", text: $schoolName)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.updateProfile(displayName: displayName, handle: handle, schoolName: schoolName)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            let profile = store.currentUserProfile
            displayName = profile.displayName
            handle = profile.handle
            schoolName = profile.schoolName ?? ""
        }
    }
}

private struct SchoolEditorSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    @State private var schoolName = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Add school")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                TextField("School name", text: $schoolName)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(CardBackground(cornerRadius: 14))

                Spacer()
            }
            .padding(16)
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("School")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let profile = store.currentUserProfile
                        store.updateProfile(
                            displayName: profile.displayName,
                            handle: profile.handle,
                            schoolName: schoolName
                        )
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            schoolName = store.currentUserProfile.schoolName ?? ""
        }
    }
}

private struct ProfileActionsSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingInviteShare = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    SettingsView()
                        .environmentObject(store)
                } label: {
                    TasteRankModalRow(systemName: "gearshape", title: "Settings", subtitle: "Privacy, display, and app reset")
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("profile_menu_settings")

                NavigationLink {
                    ListsView()
                        .environmentObject(store)
                } label: {
                    TasteRankModalRow(systemName: "list.bullet", title: "Open Your Lists", subtitle: "Manage been, guides, and want to try")
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("profile_menu_lists")

                Button {
                    showingInviteShare = true
                } label: {
                    TasteRankModalRow(systemName: "person.2", title: "Invite Friends", subtitle: "Share your handle and find mutuals", accessory: nil)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("profile_menu_invite")
            }
            .listStyle(.plain)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingInviteShare) {
            TasteRankShareSheet(
                title: "Invite Friends",
                message: "Join me on TasteRank and follow \(store.currentUserProfile.handle) for restaurant recs."
            )
        }
    }
}

private struct ProfileRestaurantCollectionView: View {
    let title: String
    let restaurants: [Restaurant]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(restaurants) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        HStack(spacing: 10) {
                            Image(restaurant.photoAssetNames.first ?? "tr_photo_1")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 68, height: 68)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(restaurant.name)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                                Text(restaurant.cuisineDetails)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(MockTasteRankTheme.accent)
                                Text(restaurant.locationLine)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                            }

                            Spacer()

                            TasteRankScoreBadge(score: restaurant.beliScore, diameter: 44)
                        }
                        .padding(14)
                        .background(CardBackground(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: MockTasteRankStore

    var body: some View {
        Form {
            Section(header: Text("Preferences")) {
                Picker("Price display", selection: $store.settings.priceDisplayMode) {
                    Text("$ / $$ / $$$").tag(PriceDisplayMode.dollarSigns)
                    Text("1-4").tag(PriceDisplayMode.numeric)
                }

                Toggle("Private profile", isOn: $store.settings.privateProfile)
            }

            Section {
                Button("Reset App State", role: .destructive) {
                    store.resetState()
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct FollowListView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @State var selectedTab: FollowListTab
    @State private var searchText = ""
    @State private var showingInviteSheet = false

    init(initialTab: FollowListTab) {
        _selectedTab = State(initialValue: initialTab)
    }

    private var followerFriends: [FriendProfile] {
        store.friends
    }

    private var followingFriends: [FriendProfile] {
        store.friends.filter { store.followedFriendIDs.contains($0.id) }
    }

    private var displayedFriends: [FriendProfile] {
        let base = selectedTab == .followers ? followerFriends : followingFriends
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter {
            $0.name.lowercased().contains(query) || $0.handle.lowercased().contains(query)
        }
    }

    private var totalCount: Int {
        selectedTab == .followers
            ? store.currentUserProfile.followers
            : store.currentUserProfile.following
    }

    private var contactCount: Int {
        selectedTab == .followers ? followerFriends.count : followingFriends.count
    }

    var body: some View {
        VStack(spacing: 0) {
            tabPicker
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Text("\(totalCount) total · \(contactCount) from contacts")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
                .padding(.top, 8)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)
                TextField("Search by name", text: $searchText)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(MockTasteRankTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(CardBackground(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text(selectedTab == .followers ? "FROM YOUR CONTACTS" : "PEOPLE YOU FOLLOW")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                        .tracking(0.6)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    if displayedFriends.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(MockTasteRankTheme.textSecondary)
                            Text(searchText.isEmpty ? "No one yet" : "No results")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(MockTasteRankTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(displayedFriends) { friend in
                            NavigationLink {
                                MemberProfileView(friend: friend)
                            } label: {
                                FollowListRow(friend: friend, tab: selectedTab)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if searchText.isEmpty {
                        inviteFooter
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .navigationTitle(selectedTab.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInviteSheet) {
            TasteRankShareSheet(
                title: "Invite Friends",
                message: "Join me on TasteRank to rank restaurants and share recommendations! Download at bfrn.ch/app"
            )
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(FollowListTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    ZStack {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white)
                                .padding(3)
                        }
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(MockTasteRankTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                if tab != FollowListTab.allCases.last {
                    Rectangle()
                        .fill(MockTasteRankTheme.border)
                        .frame(width: 1, height: 20)
                        .padding(.vertical, 6)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.90, green: 0.90, blue: 0.93))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MockTasteRankTheme.border, lineWidth: 1)
                )
        )
    }

    private var inviteFooter: some View {
        VStack(spacing: 10) {
            Divider()
                .padding(.vertical, 8)

            Image(systemName: "person.badge.plus")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(MockTasteRankTheme.accent)

            Text("Invite friends to TasteRank")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)

            Text("Find more people to share recommendations with")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showingInviteSheet = true
            } label: {
                Label("Share invite link", systemImage: "link")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(MockTasteRankTheme.accent)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct FollowListRow: View {
    @EnvironmentObject private var store: MockTasteRankStore
    let friend: FriendProfile
    let tab: FollowListTab

    private var isFollowing: Bool {
        store.followedFriendIDs.contains(friend.id)
    }

    private var beenCount: Int {
        max(1, store.friendLogs.filter { $0.friendID == friend.id }.count) * 19
    }

    private var showFollowsYou: Bool {
        tab == .following
    }

    var body: some View {
        HStack(spacing: 12) {
            TasteRankAvatarView(seed: friend.avatarSeed, initials: friend.initials, size: 46)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(friend.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)
                    if tab == .followers && isFollowing {
                        Text("Mutual")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MockTasteRankTheme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(MockTasteRankTheme.accentSoft)
                            )
                    }
                }
                HStack(spacing: 4) {
                    Text(friend.handle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                    if showFollowsYou {
                        Text("· Follows you")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(MockTasteRankTheme.textSecondary)
                    }
                }
                Text("\(beenCount) places ranked")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MockTasteRankTheme.accent)
            }

            Spacer()

            Button {
                store.toggleFollow(friendID: friend.id)
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isFollowing ? MockTasteRankTheme.textPrimary : Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isFollowing ? MockTasteRankTheme.surface : MockTasteRankTheme.accent)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(MockTasteRankTheme.border, lineWidth: isFollowing ? 1 : 0)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MockTasteRankTheme.divider)
                .frame(height: 1)
        }
    }
}

private struct GoalCustomizeSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    @State private var customGoal = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Set a custom goal")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                Text("How many spots do you want to try in \(String(store.currentUserProfile.goalYear))?")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textSecondary)

                TextField("Enter a number", text: $customGoal)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(CardBackground(cornerRadius: 14))

                Spacer()
            }
            .padding(16)
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("Custom Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmed = customGoal.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            store.setCustomGoal(trimmed)
                        }
                        dismiss()
                    }
                    .disabled(customGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(MockTasteRankStore())
    }
}
