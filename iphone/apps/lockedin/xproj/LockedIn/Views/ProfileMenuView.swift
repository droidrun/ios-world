import SwiftUI

struct ProfileMenuView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showFullProfile: Bool = false
    @State private var showSavedPosts: Bool = false
    @State private var showSettings: Bool = false
    @State private var hidePremiumUpsell: Bool = false
    @State private var showGamesAlert: Bool = false
    @State private var showGroups: Bool = false
    @State private var showEvents: Bool = false
    @State private var showClearedToast: Bool = false
    @State private var clearedToastMessage: String = ""
    @State private var personalizedAds: Bool = true
    @State private var emailMessages: Bool = true
    @State private var emailConnections: Bool = true
    @State private var emailJobRecs: Bool = false
    @State private var pushMessages: Bool = true
    @State private var pushReactions: Bool = true
    @State private var pushComments: Bool = true
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showCompanyPage: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile card
                    profileCard

                    Divider().padding(.horizontal, 16)

                    // Analytics
                    analyticsSection

                    Divider().padding(.horizontal, 16)

                    // Manage pages
                    managePagesSection

                    Divider().padding(.horizontal, 16)

                    // Menu items
                    menuItems

                    Divider().padding(.horizontal, 16)

                    // Premium upsell
                    if !hidePremiumUpsell {
                        premiumUpsell
                    }

                    Divider().padding(.horizontal, 16)

                    // Settings
                    settingsItem
                }
            }
            .background(LockedInTheme.cardBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
            }
            .sheet(isPresented: $showFullProfile) {
                ProfileView(connection: nil, isCurrentUser: true)
            }
            .alert("LockedIn Games", isPresented: $showGamesAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Keep your mind sharp with daily puzzles! Games are not available in this version.")
            }
            .sheet(isPresented: $showGroups) {
                NavigationStack {
                    List {
                        ForEach([
                            ("iOS Developers Community", 42518),
                            ("SwiftUI Enthusiasts", 18203),
                            ("Tech Leadership Circle", 95417),
                            ("Bay Area Professionals", 31842)
                        ], id: \.0) { group, members in
                            HStack(spacing: 12) {
                                CompanyLogoView(
                                    initials: String(group.prefix(2)),
                                    topHex: "0x004182",
                                    bottomHex: "0x0077B5",
                                    size: 40
                                )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(group)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("\(members) members")
                                        .font(.system(size: 12))
                                        .foregroundColor(LockedInTheme.secondaryText)
                                }
                            }
                        }
                    }
                    .navigationTitle("Groups")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showGroups = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showEvents) {
                NavigationStack {
                    List {
                        ForEach(["WWDC 2025 Watch Party", "Bay Area Tech Networking"], id: \.self) { event in
                            HStack(spacing: 12) {
                                Image(systemName: "calendar.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(LockedInTheme.linkedInBlue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Upcoming")
                                        .font(.system(size: 12))
                                        .foregroundColor(LockedInTheme.secondaryText)
                                }
                            }
                        }
                    }
                    .navigationTitle("Events")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showEvents = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showCompanyPage) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Company banner
                            LinearGradient(
                                colors: [Color(hex: 0x045A5C).opacity(0.8), Color(hex: 0x0A7F77).opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 100)
                            .overlay(alignment: .bottomLeading) {
                                CompanyLogoView(
                                    initials: "MT",
                                    topHex: "0x045A5C",
                                    bottomHex: "0x0A7F77",
                                    size: 72
                                )
                                .padding(.leading, 16)
                                .offset(y: 36)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Meridian Technologies")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(LockedInTheme.primaryText)
                                    .padding(.top, 44)

                                Text("Software · Technology · B2B")
                                    .font(.system(size: 14))
                                    .foregroundColor(LockedInTheme.secondaryText)

                                Text("San Francisco, CA · 12,408 followers · 1,200 employees")
                                    .font(.system(size: 13))
                                    .foregroundColor(LockedInTheme.secondaryText)

                                HStack(spacing: 10) {
                                    Button(action: {}) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 13, weight: .semibold))
                                            Text("Follow")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(LockedInTheme.linkedInBlue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                                        )
                                    }
                                    .accessibilityIdentifier("company_page_follow_button")

                                    Button(action: {}) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "square.and.pencil")
                                                .font(.system(size: 13, weight: .semibold))
                                            Text("Edit page")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(LockedInTheme.secondaryText)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(LockedInTheme.separator, lineWidth: 1)
                                        )
                                    }
                                    .accessibilityIdentifier("company_page_edit_button")
                                }
                                .padding(.top, 4)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                            .background(LockedInTheme.cardBackground)

                            Rectangle()
                                .fill(LockedInTheme.background)
                                .frame(height: 8)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(LockedInTheme.primaryText)
                                Text("Meridian Technologies builds cloud-native infrastructure tooling that helps engineering teams ship faster and operate more reliably. Our platform is trusted by 500+ companies worldwide.")
                                    .font(.system(size: 14))
                                    .foregroundColor(LockedInTheme.primaryText)
                                    .lineSpacing(3)
                            }
                            .padding(16)
                            .background(LockedInTheme.cardBackground)
                        }
                    }
                    .background(LockedInTheme.background)
                    .navigationTitle("Company Page")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showCompanyPage = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSavedPosts) {
                NavigationStack {
                    Group {
                        let savedPostsList = appState.posts.filter { appState.savedPosts.contains($0.id) }
                        if savedPostsList.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(LockedInTheme.tertiaryText)
                                Text("No saved posts yet")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(LockedInTheme.primaryText)
                                Text("Save posts to read later by tapping the bookmark icon on any post.")
                                    .font(.system(size: 14))
                                    .foregroundColor(LockedInTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                Spacer()
                            }
                        } else {
                            List(savedPostsList) { post in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        AvatarView(
                                            initials: post.authorInitials,
                                            topHex: post.authorAvatarTopHex,
                                            bottomHex: post.authorAvatarBottomHex,
                                            size: 32
                                        )
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(post.authorName)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(LockedInTheme.primaryText)
                                            Text(post.timestamp.linkedInTimeAgo())
                                                .font(.system(size: 11))
                                                .foregroundColor(LockedInTheme.tertiaryText)
                                        }
                                    }
                                    Text(post.content)
                                        .font(.system(size: 14))
                                        .foregroundColor(LockedInTheme.primaryText)
                                        .lineLimit(3)
                                    HStack(spacing: 8) {
                                        Text("\(post.reactionCount) reactions")
                                            .font(.system(size: 12))
                                            .foregroundColor(LockedInTheme.secondaryText)
                                        Text("\(post.commentCount) comments")
                                            .font(.system(size: 12))
                                            .foregroundColor(LockedInTheme.secondaryText)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        appState.toggleSavePost(post.id)
                                    } label: {
                                        Label("Unsave", systemImage: "bookmark.slash")
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Saved Posts")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showSavedPosts = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    List {
                        Section("Account") {
                            NavigationLink {
                                List {
                                    Section("Name & location") {
                                        HStack {
                                            Text("Name")
                                            Spacer()
                                            Text(appState.currentUser.fullName)
                                                .foregroundColor(LockedInTheme.secondaryText)
                                        }
                                        HStack {
                                            Text("Location")
                                            Spacer()
                                            Text(appState.currentUser.location)
                                                .foregroundColor(LockedInTheme.secondaryText)
                                        }
                                    }
                                    Section("Contact info") {
                                        HStack {
                                            Text("Email")
                                            Spacer()
                                            Text("\(appState.currentUser.firstName.lowercased()).\(appState.currentUser.lastName.lowercased())@meridiantech.com")
                                                .foregroundColor(LockedInTheme.secondaryText)
                                                .font(.system(size: 14))
                                        }
                                    }
                                }
                                .navigationTitle("Account preferences")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                Label("Account preferences", systemImage: "person.circle")
                            }
                            NavigationLink {
                                List {
                                    Section("Password & security") {
                                        NavigationLink {
                                            List {
                                                Section {
                                                    SecureField("Current password", text: $currentPassword)
                                                    SecureField("New password", text: $newPassword)
                                                    SecureField("Confirm new password", text: $confirmPassword)
                                                }
                                                Section {
                                                    Text("Password must be at least 8 characters and contain a number and special character.")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(LockedInTheme.secondaryText)
                                                }
                                            }
                                            .navigationTitle("Change password")
                                            .navigationBarTitleDisplayMode(.inline)
                                        } label: {
                                            Label("Change password", systemImage: "key")
                                        }
                                        NavigationLink {
                                            List {
                                                Section {
                                                    HStack {
                                                        Text("Status")
                                                        Spacer()
                                                        Text("Off")
                                                            .foregroundColor(LockedInTheme.secondaryText)
                                                    }
                                                }
                                                Section {
                                                    Text("Two-step verification adds an extra layer of security to your account. When enabled, you'll need to enter a code sent to your phone in addition to your password.")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(LockedInTheme.secondaryText)
                                                }
                                            }
                                            .navigationTitle("Two-step verification")
                                            .navigationBarTitleDisplayMode(.inline)
                                        } label: {
                                            Label("Two-step verification", systemImage: "lock.shield")
                                        }
                                        NavigationLink {
                                            List {
                                                Section("Current session") {
                                                    HStack {
                                                        Image(systemName: "iphone")
                                                            .font(.system(size: 24))
                                                            .foregroundColor(LockedInTheme.linkedInBlue)
                                                            .frame(width: 32)
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text("iPhone \u{2022} This device")
                                                                .font(.system(size: 14, weight: .semibold))
                                                            Text("San Francisco, CA \u{2022} Active now")
                                                                .font(.system(size: 12))
                                                                .foregroundColor(LockedInTheme.secondaryText)
                                                        }
                                                    }
                                                }
                                            }
                                            .navigationTitle("Active sessions")
                                            .navigationBarTitleDisplayMode(.inline)
                                        } label: {
                                            Label("Active sessions", systemImage: "desktopcomputer")
                                        }
                                    }
                                }
                                .navigationTitle("Sign in & security")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                Label("Sign in & security", systemImage: "lock.shield")
                            }
                            NavigationLink {
                                List {
                                    Section("Visibility of your profile") {
                                        HStack {
                                            Text("Profile viewing options")
                                            Spacer()
                                            Text("Your name and headline")
                                                .foregroundColor(LockedInTheme.secondaryText)
                                                .font(.system(size: 14))
                                        }
                                    }
                                }
                                .navigationTitle("Visibility")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                Label("Visibility", systemImage: "eye")
                            }
                            NavigationLink {
                                List {
                                    Section("How LockedIn uses your data") {
                                        NavigationLink {
                                            List {
                                                Section("Data management") {
                                                    HStack {
                                                        Text("Search history")
                                                        Spacer()
                                                        Button("Clear") {
                                                            clearedToastMessage = "Search history cleared"
                                                            showClearedToast = true
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showClearedToast = false }
                                                        }
                                                            .font(.system(size: 14))
                                                            .foregroundColor(LockedInTheme.linkedInBlue)
                                                    }
                                                    HStack {
                                                        Text("Browsing data")
                                                        Spacer()
                                                        Button("Clear") {
                                                            clearedToastMessage = "Browsing data cleared"
                                                            showClearedToast = true
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showClearedToast = false }
                                                        }
                                                            .font(.system(size: 14))
                                                            .foregroundColor(LockedInTheme.linkedInBlue)
                                                    }
                                                }
                                                Section("Ad preferences") {
                                                    Toggle("Personalized ads", isOn: $personalizedAds)
                                                }
                                            }
                                            .navigationTitle("Manage data")
                                            .navigationBarTitleDisplayMode(.inline)
                                        } label: {
                                            Label("Manage your data and activity", systemImage: "externaldrive")
                                        }
                                        NavigationLink {
                                            List {
                                                Section {
                                                    Text("Request a copy of the data LockedIn has about you. This includes your profile information, connections, messages, and activity.")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(LockedInTheme.secondaryText)
                                                }
                                                Section {
                                                    HStack {
                                                        Text("Last requested")
                                                        Spacer()
                                                        Text("Never")
                                                            .foregroundColor(LockedInTheme.secondaryText)
                                                    }
                                                }
                                            }
                                            .navigationTitle("Download your data")
                                            .navigationBarTitleDisplayMode(.inline)
                                        } label: {
                                            Label("Get a copy of your data", systemImage: "arrow.down.doc")
                                        }
                                    }
                                }
                                .navigationTitle("Data privacy")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                Label("Data privacy", systemImage: "hand.raised")
                            }
                        }
                        Section("Notifications") {
                            NavigationLink {
                                List {
                                    Section("Email") {
                                        Toggle("Messages", isOn: $emailMessages)
                                        Toggle("Connection requests", isOn: $emailConnections)
                                        Toggle("Job recommendations", isOn: $emailJobRecs)
                                    }
                                }
                                .navigationTitle("Communications")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                Label("Communications", systemImage: "envelope")
                            }
                            NavigationLink {
                                List {
                                    Section("Push notifications") {
                                        Toggle("Messages", isOn: $pushMessages)
                                        Toggle("Reactions", isOn: $pushReactions)
                                        Toggle("Comments", isOn: $pushComments)
                                    }
                                }
                                .navigationTitle("Notifications")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                Label("Notifications", systemImage: "bell")
                            }
                        }
                    }
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showSettings = false }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if showClearedToast {
                            Text(clearedToastMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.black.opacity(0.8)))
                                .transition(.opacity)
                                .padding(.bottom, 40)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: showClearedToast)
                }
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        Button {
            showFullProfile = true
        } label: {
            VStack(spacing: 12) {
                AvatarView(
                    name: appState.currentUser.fullName,
                    initials: appState.currentUser.avatarInitials,
                    topHex: appState.currentUser.avatarTopHex,
                    bottomHex: appState.currentUser.avatarBottomHex,
                    size: 72,
                    showBorder: true
                )

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(appState.currentUser.fullName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(LockedInTheme.primaryText)

                        if appState.currentUser.isPremium {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                        }
                    }

                    Text(appState.currentUser.headline)
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(appState.currentUser.location)
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)

                    if let edu = appState.currentUser.educations.first {
                        HStack(spacing: 6) {
                            CompanyLogoView(
                                initials: String(edu.school.prefix(3)),
                                topHex: "0x1A2744",
                                bottomHex: "0x4A6FA5",
                                size: 20
                            )
                            Text(edu.school)
                                .font(.system(size: 13))
                                .foregroundColor(LockedInTheme.primaryText)
                        }
                        .padding(.top, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Analytics

    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            analyticsRow(
                icon: "eye",
                value: "\(appState.currentUser.profileViewsThisWeek)",
                label: "profile viewers"
            )

            analyticsRow(
                icon: "chart.bar.fill",
                value: "\(appState.posts.filter { $0.authorId == appState.currentUser.id }.reduce(0) { $0 + $1.reactionCount + $1.commentCount })",
                label: "post impressions"
            )
        }
    }

    private func analyticsRow(icon: String, value: String, label: String) -> some View {
        Button {
            showFullProfile = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .frame(width: 24)

                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                    Text(label)
                        .font(.system(size: 15))
                        .foregroundColor(LockedInTheme.primaryText)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Manage Pages

    private var managePagesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Manage pages")
                .font(.system(size: 13))
                .foregroundColor(LockedInTheme.secondaryText)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 6)

            Button(action: { showCompanyPage = true }) {
                HStack(spacing: 12) {
                    CompanyLogoView(
                        initials: "MT",
                        topHex: "0x045A5C",
                        bottomHex: "0x0A7F77",
                        size: 28
                    )

                    Text("Meridian Technologies")
                        .font(.system(size: 15))
                        .foregroundColor(LockedInTheme.primaryText)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .accessibilityIdentifier("menu_manage_page_meridian")
        }
    }

    // MARK: - Menu Items

    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuRow(icon: "puzzlepiece.fill", title: "Puzzle games") { showGamesAlert = true }
            menuRow(icon: "bookmark.fill", title: "Saved posts") { showSavedPosts = true }
            menuRow(icon: "person.2.fill", title: "Groups") { showGroups = true }
            menuRow(icon: "calendar", title: "Events") { showEvents = true }
        }
    }

    private func menuRow(icon: String, title: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(LockedInTheme.primaryText)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Premium Upsell

    private var premiumUpsell: some View {
        Button(action: { showFullProfile = true }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("6.7x")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(LockedInTheme.premiumGold)
                    Spacer()
                    Button(action: { withAnimation { hidePremiumUpsell = true } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }

                Text("Premium helps you grow your Page followers 6.7x faster.")
                    .font(.system(size: 14))
                    .foregroundColor(LockedInTheme.primaryText)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.premiumGold)
                    Text("Try Premium Page for $0")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: 0xFFF8E1))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Settings

    private var settingsItem: some View {
        Button { showSettings = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .frame(width: 24)

                Text("Settings")
                    .font(.system(size: 15))
                    .foregroundColor(LockedInTheme.primaryText)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}
