import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let connection: Connection?
    let isCurrentUser: Bool
    @State private var selectedViewerConnection: Connection?
    @State private var showEditAbout: Bool = false
    @State private var showEditExperience: Bool = false
    @State private var showEditEducation: Bool = false
    @State private var showEditSkills: Bool = false
    @State private var editAboutText: String = ""
    @State private var selectedPost: Post?
    @State private var selectedConversation: Conversation?
    @State private var showChat: Bool = false
    @State private var showConnectionsList: Bool = false
    @State private var showOpenTo: Bool = false
    @State private var showAddSection: Bool = false
    @State private var aboutExpanded: Bool = false
    @State private var showAllPosts: Bool = false
    @State private var activityFilter: String = "Posts"
    @State private var showAllExperiences: Bool = false
    @State private var showAllSkills: Bool = false
    @State private var selectedInterestTab: String = "Companies"
    @State private var unfollowedInterests: Set<String> = []
    @State private var showAnalytics: Bool = false

    /// Live connection data from appState (reactive to degree/follow changes)
    private var liveConnection: Connection? {
        guard let conn = connection else { return nil }
        return appState.connections.first(where: { $0.id == conn.id }) ?? conn
    }

    private var profile: LockedInProfile {
        if isCurrentUser {
            return appState.currentUser
        }
        // Build a profile from connection data
        guard let conn = connection else { return appState.currentUser }
        return LockedInProfile(
            id: conn.id,
            firstName: conn.firstName,
            lastName: conn.lastName,
            headline: conn.headline,
            location: conn.location.isEmpty ? "San Francisco Bay Area" : conn.location,
            about: "",
            avatarInitials: conn.avatarInitials,
            avatarTopHex: conn.avatarTopHex,
            avatarBottomHex: conn.avatarBottomHex,
            connectionCount: 500 + (conn.mutualConnections * 12),
            followerCount: 500 + (conn.mutualConnections * 15),
            isOpenToWork: false,
            isPremium: conn.degree == .first && conn.mutualConnections > 20,
            experiences: connectionExperiences(conn),
            educations: connectionEducations(conn),
            skills: connectionSkills(conn),
            profileViewsThisWeek: 0
        )
    }

    /// Derive a role string from the headline for the "Open to work" card
    private var openToWorkRole: String {
        let headline = profile.headline
        // Extract role portion before " at " if present
        if let range = headline.range(of: " at ", options: .caseInsensitive) {
            return String(headline[headline.startIndex..<range.lowerBound]) + " roles"
        }
        return headline
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Banner + Avatar
                    bannerSection

                    // Name, headline, location
                    profileHeader

                    // Connection info
                    connectionInfo

                    // Message / Connect button
                    actionButtons

                    if isCurrentUser {
                        // Enhance Profile button
                        enhanceProfileButton

                        // Open to work card
                        openToWorkCard

                        sectionDivider

                        // Suggested for you / Analytics
                        suggestedForYouSection
                    }

                    sectionDivider

                    // Highlights (for other users)
                    if !isCurrentUser {
                        highlightsSection
                        sectionDivider
                    }

                    // About
                    if !profile.about.isEmpty {
                        aboutSection
                        sectionDivider
                    }

                    // Activity
                    activitySection
                    sectionDivider

                    // Experience
                    experienceSection
                    sectionDivider

                    // Education
                    educationSection
                    sectionDivider

                    // Skills
                    skillsSection
                    sectionDivider

                    // Interests
                    interestsSection

                    if isCurrentUser {
                        sectionDivider

                        // Who your viewers also viewed
                        viewersAlsoViewedSection
                    }

                    Spacer().frame(height: 40)
                }
            }
            .background(LockedInTheme.background)
            .sheet(isPresented: $showEditAbout) {
                NavigationStack {
                    VStack {
                        TextEditor(text: $editAboutText)
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.primaryText)
                            .padding()
                    }
                    .navigationTitle("Edit About")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                appState.currentUser.about = editAboutText
                                showEditAbout = false
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showEditAbout = false
                            }
                            .font(.system(size: 15))
                            .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditExperience) {
                NavigationStack {
                    Form {
                        ForEach(appState.currentUser.experiences.indices, id: \.self) { index in
                            Section(index == 0 ? "Current Position" : "Position \(index + 1)") {
                                TextField("Title", text: Binding(
                                    get: { appState.currentUser.experiences[index].title },
                                    set: { appState.currentUser.experiences[index].title = $0 }
                                ))
                                .font(.system(size: 14))
                                TextField("Company", text: Binding(
                                    get: { appState.currentUser.experiences[index].company },
                                    set: { appState.currentUser.experiences[index].company = $0 }
                                ))
                                .font(.system(size: 14))
                                TextField("Location", text: Binding(
                                    get: { appState.currentUser.experiences[index].location },
                                    set: { appState.currentUser.experiences[index].location = $0 }
                                ))
                                .font(.system(size: 14))
                                TextField("Location type (e.g. Hybrid)", text: Binding(
                                    get: { appState.currentUser.experiences[index].locationType },
                                    set: { appState.currentUser.experiences[index].locationType = $0 }
                                ))
                                .font(.system(size: 14))
                                HStack {
                                    Text("Start date")
                                        .foregroundColor(LockedInTheme.secondaryText)
                                    Spacer()
                                    TextField("Start", text: Binding(
                                        get: { appState.currentUser.experiences[index].startDate },
                                        set: { appState.currentUser.experiences[index].startDate = $0 }
                                    ))
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.trailing)
                                }
                                HStack {
                                    Text("End date")
                                        .foregroundColor(LockedInTheme.secondaryText)
                                    Spacer()
                                    TextField("Present", text: Binding(
                                        get: { appState.currentUser.experiences[index].endDate ?? "Present" },
                                        set: { appState.currentUser.experiences[index].endDate = $0 == "Present" ? nil : $0 }
                                    ))
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.trailing)
                                }
                                if appState.currentUser.experiences.count > 1 {
                                    Button("Remove position", role: .destructive) {
                                        appState.currentUser.experiences.remove(at: index)
                                    }
                                    .font(.system(size: 14))
                                }
                            }
                        }

                        Section {
                            Button {
                                let newExp = Experience(
                                    id: "exp_new_\(Int(Date().timeIntervalSince1970))",
                                    title: "",
                                    company: "",
                                    companyLogoInitials: "",
                                    locationType: "On-site",
                                    location: "",
                                    startDate: "Jan 2024",
                                    endDate: nil,
                                    description: "",
                                    isCurrent: false
                                )
                                appState.currentUser.experiences.append(newExp)
                            } label: {
                                Label("Add position", systemImage: "plus.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(LockedInTheme.linkedInBlue)
                            }
                        }
                    }
                    .navigationTitle("Edit Experience")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                // Update companyLogoInitials for any new/edited entries
                                for i in appState.currentUser.experiences.indices {
                                    if appState.currentUser.experiences[i].companyLogoInitials.isEmpty {
                                        appState.currentUser.experiences[i].companyLogoInitials = String(appState.currentUser.experiences[i].company.prefix(2).uppercased())
                                    }
                                }
                                showEditExperience = false
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showEditExperience = false
                            }
                            .font(.system(size: 15))
                            .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditEducation) {
                NavigationStack {
                    Form {
                        ForEach(appState.currentUser.educations.indices, id: \.self) { index in
                            Section(appState.currentUser.educations[index].school.isEmpty ? "Education \(index + 1)" : appState.currentUser.educations[index].school) {
                                TextField("School", text: Binding(
                                    get: { appState.currentUser.educations[index].school },
                                    set: { appState.currentUser.educations[index].school = $0 }
                                ))
                                .font(.system(size: 14))
                                TextField("Degree", text: Binding(
                                    get: { appState.currentUser.educations[index].degree },
                                    set: { appState.currentUser.educations[index].degree = $0 }
                                ))
                                .font(.system(size: 14))
                                TextField("Field of Study", text: Binding(
                                    get: { appState.currentUser.educations[index].field },
                                    set: { appState.currentUser.educations[index].field = $0 }
                                ))
                                .font(.system(size: 14))
                                HStack {
                                    Text("Start year")
                                        .foregroundColor(LockedInTheme.secondaryText)
                                    Spacer()
                                    TextField("Year", text: Binding(
                                        get: { String(appState.currentUser.educations[index].startYear) },
                                        set: { appState.currentUser.educations[index].startYear = Int($0) ?? appState.currentUser.educations[index].startYear }
                                    ))
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.numberPad)
                                }
                                HStack {
                                    Text("End year")
                                        .foregroundColor(LockedInTheme.secondaryText)
                                    Spacer()
                                    TextField("Year", text: Binding(
                                        get: { String(appState.currentUser.educations[index].endYear) },
                                        set: { appState.currentUser.educations[index].endYear = Int($0) ?? appState.currentUser.educations[index].endYear }
                                    ))
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.numberPad)
                                }
                                TextField("Activities and societies", text: Binding(
                                    get: { appState.currentUser.educations[index].activities },
                                    set: { appState.currentUser.educations[index].activities = $0 }
                                ))
                                .font(.system(size: 14))
                                if appState.currentUser.educations.count > 1 {
                                    Button("Remove education", role: .destructive) {
                                        appState.currentUser.educations.remove(at: index)
                                    }
                                    .font(.system(size: 14))
                                }
                            }
                        }

                        Section {
                            Button {
                                let newEdu = Education(
                                    id: "edu_new_\(Int(Date().timeIntervalSince1970))",
                                    school: "",
                                    degree: "",
                                    field: "",
                                    startYear: 2020,
                                    endYear: 2024,
                                    activities: ""
                                )
                                appState.currentUser.educations.append(newEdu)
                            } label: {
                                Label("Add education", systemImage: "plus.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(LockedInTheme.linkedInBlue)
                            }
                        }
                    }
                    .navigationTitle("Edit Education")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                showEditEducation = false
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showEditEducation = false
                            }
                            .font(.system(size: 15))
                            .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditSkills) {
                NavigationStack {
                    List {
                        Section("Your Skills") {
                            ForEach(appState.currentUser.skills, id: \.self) { skill in
                                HStack {
                                    Text(skill)
                                        .font(.system(size: 15))
                                    Spacer()
                                    Button {
                                        appState.currentUser.skills.removeAll { $0 == skill }
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(LockedInTheme.greenButton)
                                    }
                                }
                            }
                        }
                        Section("Suggested Skills") {
                            ForEach(["Project Management", "Agile Methodologies", "Cloud Architecture", "Team Leadership", "System Design", "Technical Writing"].filter { !appState.currentUser.skills.contains($0) }, id: \.self) { skill in
                                Button {
                                    appState.currentUser.skills.append(skill)
                                } label: {
                                    HStack {
                                        Text(skill)
                                            .font(.system(size: 15))
                                            .foregroundColor(LockedInTheme.primaryText)
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(LockedInTheme.linkedInBlue)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Edit Skills")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showEditSkills = false }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") { showEditSkills = false }
                                .font(.system(size: 15))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAnalytics) {
                NavigationStack {
                    List {
                        Section("Profile performance") {
                            HStack {
                                Image(systemName: "eye")
                                    .foregroundColor(LockedInTheme.linkedInBlue)
                                    .frame(width: 28)
                                VStack(alignment: .leading) {
                                    Text("\(profile.profileViewsThisWeek) profile views")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Discover who's viewed your profile")
                                        .font(.system(size: 13))
                                        .foregroundColor(LockedInTheme.secondaryText)
                                }
                            }
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(LockedInTheme.greenButton)
                                    .frame(width: 28)
                                VStack(alignment: .leading) {
                                    Text("\(appState.posts.filter { $0.authorId == profile.id }.reduce(0) { $0 + $1.reactionCount + $1.commentCount }) post impressions")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Check out who's engaging with your posts")
                                        .font(.system(size: 13))
                                        .foregroundColor(LockedInTheme.secondaryText)
                                }
                            }
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(LockedInTheme.premiumGold)
                                    .frame(width: 28)
                                VStack(alignment: .leading) {
                                    Text("\(profile.connectionCount / 8) search appearances")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("See how often you appear in search results")
                                        .font(.system(size: 13))
                                        .foregroundColor(LockedInTheme.secondaryText)
                                }
                            }
                        }
                        Section("Top search keywords") {
                            Label("Platform Engineer", systemImage: "number")
                            Label("Automation", systemImage: "number")
                            Label("Kubernetes", systemImage: "number")
                            Label("DevOps", systemImage: "number")
                        }
                    }
                    .navigationTitle("Analytics")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showAnalytics = false }
                        }
                    }
                }
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
                    .environmentObject(appState)
            }
            .sheet(item: $selectedConversation) { convo in
                ChatDetailView(conversation: convo)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showConnectionsList) {
                NavigationStack {
                    List(appState.connections) { conn in
                        Button {
                            showConnectionsList = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                selectedViewerConnection = conn
                            }
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(name: conn.fullName,
                    initials: conn.avatarInitials, topHex: conn.avatarTopHex, bottomHex: conn.avatarBottomHex, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(conn.fullName)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(LockedInTheme.primaryText)
                                    Text(conn.headline)
                                        .font(.system(size: 12))
                                        .foregroundColor(LockedInTheme.secondaryText)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .navigationTitle("\(appState.connections.count) Connections")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showConnectionsList = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAllPosts) {
                NavigationStack {
                    let authored = appState.posts.filter { $0.authorId == profile.id }
                    let reposted = profile.id == appState.currentUser.id
                        ? appState.posts.filter { appState.repostedPosts.contains($0.id) && $0.authorId != profile.id }
                        : []
                    let allPosts = authored + reposted
                    List(allPosts) { post in
                        VStack(alignment: .leading, spacing: 6) {
                            if post.authorId != profile.id {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.2.squarepath")
                                        .font(.system(size: 10))
                                    Text("Reposted")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(LockedInTheme.secondaryText)
                            }
                            Text(post.content)
                                .font(.system(size: 14))
                                .foregroundColor(LockedInTheme.primaryText)
                                .lineLimit(4)
                            HStack(spacing: 8) {
                                Text("\(post.reactionCount) reactions")
                                    .font(.system(size: 12))
                                    .foregroundColor(LockedInTheme.secondaryText)
                                Text("\(post.commentCount) comments")
                                    .font(.system(size: 12))
                                    .foregroundColor(LockedInTheme.secondaryText)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showAllPosts = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                selectedPost = post
                            }
                        }
                    }
                    .navigationTitle("Posts")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showAllPosts = false }
                        }
                    }
                }
            }
            .confirmationDialog("Open to", isPresented: $showOpenTo, titleVisibility: .visible) {
                Button("Finding a new job") { appState.currentUser.isOpenToWork = true }
                Button("Hiring") { appState.currentUser.isOpenToWork = true }
                Button("Providing services") { appState.currentUser.isOpenToWork = true }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Add to profile", isPresented: $showAddSection, titleVisibility: .visible) {
                Button("Add summary") { editAboutText = appState.currentUser.about; showEditAbout = true }
                Button("Add position") { showEditExperience = true }
                Button("Add education") { showEditEducation = true }
                Button("Add skills") { showEditSkills = true }
                Button("Cancel", role: .cancel) {}
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        appState.showSearch = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(LockedInTheme.secondaryText)
                                .font(.system(size: 14))
                            Text("I'm looking for...")
                                .font(.system(size: 15))
                                .foregroundColor(LockedInTheme.secondaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0xEDF3F8))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .sheet(item: $selectedViewerConnection) { conn in
                ProfileView(connection: conn, isCurrentUser: false)
            }
        }
    }

    // MARK: - Banner

    private var bannerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Banner gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hexString: profile.avatarTopHex).opacity(0.6),
                            Color(hexString: profile.avatarBottomHex).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay {
                    // Decorative pattern
                    HStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "cube.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.15))
                                .rotationEffect(.degrees(-15))
                        }
                    }
                }

            // Avatar
            AvatarView(
                name: profile.fullName,
                    initials: profile.avatarInitials,
                topHex: profile.avatarTopHex,
                bottomHex: profile.avatarBottomHex,
                size: 100,
                showBorder: true,
                showOpenToWork: profile.isOpenToWork
            )
            .padding(.leading, 16)
            .offset(y: 50)
        }
        .padding(.bottom, 50)
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(profile.fullName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)
                    .lineLimit(1)
                    .layoutPriority(1)

                if profile.isPremium {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                        .fixedSize()
                }

                if !isCurrentUser, let conn = liveConnection {
                    Text("\u{2022} \(conn.degree.rawValue)")
                        .font(.system(size: 15))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .fixedSize()
                }
            }

            Text(profile.headline)
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.secondaryText)
                .lineLimit(2)

            if !profile.experiences.isEmpty, let currentExp = profile.experiences.first(where: { $0.isCurrent }) ?? profile.experiences.first {
                HStack(spacing: 4) {
                    Text(currentExp.company)
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.primaryText)

                    if let firstEdu = profile.educations.first {
                        Text("\u{2022}")
                            .font(.system(size: 10))
                            .foregroundColor(LockedInTheme.secondaryText)
                        Text(firstEdu.school)
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.primaryText)
                    }
                }
            }

            Text(profile.location)
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Connection Info

    private var connectionInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { showConnectionsList = true } label: {
                Text("\(profile.connectionCount)+ connections")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LockedInTheme.linkedInBlue)
            }

            if !isCurrentUser, let conn = connection, conn.mutualConnections > 0 {
                HStack(spacing: 6) {
                    // Overlapping avatars for mutual connections
                    HStack(spacing: -8) {
                        ForEach(0..<min(3, conn.mutualConnections), id: \.self) { i in
                            let mutualColors = [
                                ("0x2B1F4E", "0x8B6FD4"),
                                ("0x1A3C2D", "0x4DB882"),
                                ("0x3A2811", "0xD4A34E")
                            ]
                            AvatarView(
                                initials: ["BM", "DH", "KS"][i],
                                topHex: mutualColors[i].0,
                                bottomHex: mutualColors[i].1,
                                size: 20,
                                showBorder: true
                            )
                        }
                    }

                    let mutualNames = mutualConnectionNames(for: conn)
                    Text(mutualNames)
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            if isCurrentUser {
                Button { showOpenTo = true } label: {
                    Text("Open to")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(LockedInTheme.linkedInBlue)
                        )
                }

                Button { showAddSection = true } label: {
                    Text("Add section")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                        )
                }
            } else if let conn = liveConnection {
                if conn.degree == .first {
                    // 1st degree: Message (primary) + three-dot menu
                    profileMessageButton(filled: true)
                    profileMoreMenu(conn: conn)
                } else if conn.degree == .second {
                    // 2nd degree: Connect/Pending (primary) + Message (secondary) + three-dot menu
                    if appState.sentConnectionRequests.contains(conn.id) {
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                Text("Pending")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(LockedInTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(LockedInTheme.separator, lineWidth: 1)
                            )
                        }
                        .disabled(true)
                    } else {
                        Button {
                            appState.sendConnectionRequest(conn.id)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 14))
                                Text("Connect")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(LockedInTheme.linkedInBlue)
                            )
                        }
                    }
                    profileMessageButton(filled: false)
                    profileMoreMenu(conn: conn)
                } else {
                    // 3rd degree: Follow (primary) + Message (secondary) + three-dot menu
                    Button {
                        appState.toggleFollow(conn.id)
                    } label: {
                        HStack(spacing: 4) {
                            if conn.isFollowing {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14))
                                Text("Following")
                                    .font(.system(size: 15, weight: .semibold))
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                                Text("Follow")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                        .foregroundColor(conn.isFollowing ? LockedInTheme.secondaryText : LockedInTheme.linkedInBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(conn.isFollowing ? LockedInTheme.separator : LockedInTheme.linkedInBlue, lineWidth: 1)
                        )
                    }
                    profileMessageButton(filled: false)
                    profileMoreMenu(conn: conn)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(LockedInTheme.cardBackground)
    }

    @ViewBuilder
    private func profileMessageButton(filled: Bool) -> some View {
        Button {
            if let conn = connection {
                let convoId = appState.startNewConversation(with: conn)
                if let convo = appState.conversations.first(where: { $0.id == convoId }) {
                    selectedConversation = convo
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14))
                Text("Message")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(filled ? .white : LockedInTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(filled ? LockedInTheme.linkedInBlue : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(filled ? Color.clear : LockedInTheme.separator, lineWidth: 1)
            )
        }
    }

    private func profileMoreMenu(conn: Connection) -> some View {
        Menu {
            if conn.degree == .third && !appState.sentConnectionRequests.contains(conn.id) {
                Button {
                    appState.sendConnectionRequest(conn.id)
                } label: {
                    Label("Connect", systemImage: "person.badge.plus")
                }
            }
            if conn.degree != .first {
                if conn.isFollowing {
                    Button {
                        appState.toggleFollow(conn.id)
                    } label: {
                        Label("Unfollow", systemImage: "person.fill.xmark")
                    }
                } else if conn.degree == .second {
                    Button {
                        appState.toggleFollow(conn.id)
                    } label: {
                        Label("Follow", systemImage: "plus")
                    }
                }
            }
            Button {
                UIPasteboard.general.string = "https://lockedin.example/in/\(conn.firstName.lowercased())-\(conn.lastName.lowercased())"
            } label: {
                Label("Share profile via...", systemImage: "square.and.arrow.up")
            }
            Divider()
            Button(role: .destructive) {
                dismiss()
            } label: {
                Label("Report / Block", systemImage: "exclamationmark.triangle")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(LockedInTheme.secondaryText)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(LockedInTheme.separator, lineWidth: 1)
                )
        }
    }

    // MARK: - Enhance Profile Button

    private var enhanceProfileButton: some View {
        Button(action: { showAddSection = true }) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14))
                Text("Enhance profile")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(LockedInTheme.linkedInBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Open to Work Card

    private var openToWorkCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 14))
                    .foregroundColor(LockedInTheme.greenButton)
                Text("Open to work")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)
            }

            Text(openToWorkRole)
                .font(.system(size: 13))
                .foregroundColor(LockedInTheme.primaryText)
                .lineLimit(2)

            Button { showOpenTo = true } label: {
                Text("Show details")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(LockedInTheme.linkedInBlue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: 0xF0FFF0))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: 0xC8E6C9), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Rectangle()
            .fill(LockedInTheme.background)
            .frame(height: 8)
    }

    // MARK: - Suggested for You / Analytics

    private var suggestedForYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("Suggested for you")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)

                HStack(spacing: 4) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                    Text("Private to you")
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }

            // Profile analytics card
            analyticsRow(
                icon: "person.fill",
                iconColor: LockedInTheme.linkedInBlue,
                title: "\(profile.profileViewsThisWeek) profile viewers",
                subtitle: "Discover who's viewed your profile.",
                trailingText: nil
            )

            Divider()

            // Post impressions card
            analyticsRow(
                icon: "chart.bar.fill",
                iconColor: LockedInTheme.linkedInBlue,
                title: "\(appState.posts.filter { $0.authorId == profile.id }.reduce(0) { $0 + $1.reactionCount + $1.commentCount }) post impressions",
                subtitle: "Check out who's engaging with your posts.",
                trailingText: "Past 7 days"
            )

            Divider()

            // Search appearances card
            analyticsRow(
                icon: "magnifyingglass",
                iconColor: LockedInTheme.linkedInBlue,
                title: "\(profile.connectionCount / 8) search appearances",
                subtitle: "See how often you appear in search results.",
                trailingText: nil
            )

            // Show all analytics link
            Button(action: { showAnalytics = true }) {
                Text("Show all analytics \u{2192}")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    private func analyticsRow(icon: String, iconColor: Color, title: String, subtitle: String, trailingText: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            if let trailing = trailingText {
                Text(trailing)
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)
            }
        }
    }

    // MARK: - Highlights

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(LockedInTheme.primaryText)

            if let conn = connection {
                HStack(spacing: 12) {
                    CompanyLogoView(
                        initials: conn.company.isEmpty ? String(conn.firstName.prefix(1)) : String(conn.company.prefix(2)),
                        topHex: conn.avatarTopHex,
                        bottomHex: conn.avatarBottomHex,
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("You both work in tech")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(LockedInTheme.primaryText)
                        if !conn.company.isEmpty {
                            Text("\(conn.firstName) works at \(conn.company)")
                                .font(.system(size: 13))
                                .foregroundColor(LockedInTheme.secondaryText)
                        } else {
                            Text("\(conn.firstName) is in your network")
                                .font(.system(size: 13))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                }

                Button {
                    if let conn = connection {
                        let convoId = appState.startNewConversation(with: conn)
                        if let convo = appState.conversations.first(where: { $0.id == convoId }) {
                            selectedConversation = convo
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 12))
                        Text("Message")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(LockedInTheme.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LockedInTheme.separator, lineWidth: 1)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("About")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                if isCurrentUser {
                    Button {
                        editAboutText = appState.currentUser.about
                        showEditAbout = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
            }

            Text(profile.about)
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.primaryText)
                .lineSpacing(3)
                .lineLimit(aboutExpanded ? nil : 4)

            if profile.about.count > 200 && !aboutExpanded {
                Button { aboutExpanded = true } label: {
                    Text("...see more")
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(LockedInTheme.primaryText)
                    Text("\(profile.followerCount.abbreviatedString()) followers")
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
                Spacer()
            }

            // Posts / Comments filter
            HStack(spacing: 8) {
                activityFilterPill("Posts", isSelected: activityFilter == "Posts")
                activityFilterPill("Comments", isSelected: activityFilter == "Comments")
            }

            // Show content based on selected filter
            if activityFilter == "Posts" {
                let authoredPosts = appState.posts.filter { $0.authorId == profile.id }
                let repostedPosts = profile.id == appState.currentUser.id
                    ? appState.posts.filter { appState.repostedPosts.contains($0.id) && $0.authorId != profile.id }
                    : []
                let allActivity: [(post: Post, isRepost: Bool)] =
                    authoredPosts.map { ($0, false) } + repostedPosts.map { ($0, true) }

                if let first = allActivity.first {
                    activityPostCard(first.post, isRepost: first.isRepost)
                } else {
                    activityPlaceholder
                }

                Button { showAllPosts = true } label: {
                    Text("Show all posts \u{2192}")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            } else {
                // Comments by this user
                let userComments = appState.postComments.values.flatMap { $0 }.filter { $0.authorName == profile.fullName }
                if userComments.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 24))
                            .foregroundColor(LockedInTheme.tertiaryText)
                        Text("No recent comments")
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(userComments.prefix(3)) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.content)
                                .font(.system(size: 14))
                                .foregroundColor(LockedInTheme.primaryText)
                                .lineLimit(3)
                            Text(comment.timestamp.linkedInTimeAgo())
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0xF2F2F2))
                        )
                    }
                }
            }

            Divider()
        }
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    private func activityFilterPill(_ title: String, isSelected: Bool) -> some View {
        Button { activityFilter = title } label: {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : LockedInTheme.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? LockedInTheme.greenButton : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : LockedInTheme.separator, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func activityPostCard(_ post: Post, isRepost: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AvatarView(
                    name: isRepost ? profile.fullName : post.authorName,
                    initials: isRepost ? profile.avatarInitials : post.authorInitials,
                    topHex: isRepost ? profile.avatarTopHex : post.authorAvatarTopHex,
                    bottomHex: isRepost ? profile.avatarBottomHex : post.authorAvatarBottomHex,
                    size: 28
                )
                Text(isRepost ? "\(profile.fullName) reposted this" : "\(post.authorName) posted this")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
                Spacer()
                Button(action: { showAllPosts = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }

            Divider()

            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.primaryText)
                .lineLimit(3)

            if post.content.count > 150 {
                Text("...more")
                    .font(.system(size: 14))
                    .foregroundColor(LockedInTheme.secondaryText)
            }

            // Reaction summary
            HStack(spacing: 4) {
                HStack(spacing: -2) {
                    ForEach(post.topReactions.prefix(3), id: \.self) { reaction in
                        ZStack {
                            Circle()
                                .fill(Color(hexString: reaction.iconColor))
                                .frame(width: 16, height: 16)
                            Image(systemName: reaction.sfSymbol)
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    }
                }
                Text(post.reactionCount.abbreviatedString())
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)
                Spacer()
                Text("\(post.commentCount) comments")
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)
                Text("\u{2022}")
                    .font(.system(size: 6))
                    .foregroundColor(LockedInTheme.tertiaryText)
                Text("\(post.repostCount) reposts")
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(LockedInTheme.separator, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPost = post
        }
    }

    private var activityPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 24))
                .foregroundColor(LockedInTheme.tertiaryText)
            Text("No recent activity")
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Experience

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Experience")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                if isCurrentUser {
                    Button {
                        showEditExperience = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
            }

            let sortedExperiences = profile.experiences.sorted { a, b in
                if a.isCurrent != b.isCurrent { return a.isCurrent }
                return a.startDate > b.startDate
            }
            let displayedExperiences = showAllExperiences ? sortedExperiences : Array(sortedExperiences.prefix(2))
            ForEach(displayedExperiences) { exp in
                experienceRow(exp)
                if exp.id != displayedExperiences.last?.id {
                    Divider()
                }
            }

            if profile.experiences.count > 2 && !showAllExperiences {
                Button { showAllExperiences = true } label: {
                    Text("Show all \(profile.experiences.count) experiences \u{2192}")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    private func experienceRow(_ exp: Experience) -> some View {
        HStack(alignment: .top, spacing: 12) {
            CompanyLogoView(
                initials: exp.companyLogoInitials,
                topHex: profile.avatarTopHex,
                bottomHex: profile.avatarBottomHex,
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(exp.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)

                HStack(spacing: 4) {
                    Text(exp.company)
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.primaryText)
                    Text("\u{2022} \(exp.locationType)")
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                }

                Text("\(exp.startDate) - \(exp.endDate ?? "Present")")
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)

                if !exp.location.isEmpty {
                    Text(exp.location)
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                }

                if !exp.description.isEmpty {
                    Text(exp.description)
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.primaryText)
                        .lineLimit(3)
                        .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Education

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Education")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                if isCurrentUser {
                    Button {
                        showEditEducation = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
            }

            ForEach(profile.educations.sorted { $0.endYear > $1.endYear }) { edu in
                educationRow(edu)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    private func educationRow(_ edu: Education) -> some View {
        HStack(alignment: .top, spacing: 12) {
            CompanyLogoView(
                initials: String(edu.school.prefix(3)),
                topHex: "0x1A2744",
                bottomHex: "0x4A6FA5",
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(edu.school)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)

                Text("\(edu.degree), \(edu.field)")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)

                Text("\(edu.startYear) - \(edu.endYear)")
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)

                if !edu.activities.isEmpty {
                    Text("Activities and societies: \(edu.activities)")
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
    }

    // MARK: - Skills

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Skills")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                if isCurrentUser {
                    Button {
                        showEditSkills = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
            }

            ForEach(Array(profile.skills.prefix(showAllSkills ? profile.skills.count : 3).enumerated()), id: \.offset) { index, skill in
                VStack(alignment: .leading, spacing: 4) {
                    Text(skill)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)

                    if index == 0 {
                        HStack(spacing: 6) {
                            AvatarView(
                                initials: "BM",
                                topHex: "0x2B1F4E",
                                bottomHex: "0x8B6FD4",
                                size: 20
                            )
                            Text("Endorsed by ")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText) +
                            Text("Blair Morgan")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText) +
                            Text(" and 1 other who is highly skilled at this")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }

                    if index < 2 {
                        Divider()
                            .padding(.top, 4)
                    }
                }
            }

            if profile.skills.count > 3 && !showAllSkills {
                Button { showAllSkills = true } label: {
                    Text("Show all \(profile.skills.count) skills \u{2192}")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Interests Section

    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(LockedInTheme.primaryText)

            // Tab pills
            HStack(spacing: 8) {
                interestTabPill("Companies", isSelected: selectedInterestTab == "Companies")
                interestTabPill("Groups", isSelected: selectedInterestTab == "Groups")
                interestTabPill("Schools", isSelected: selectedInterestTab == "Schools")
            }

            // Tab content
            if selectedInterestTab == "Companies" {
                interestCompanyRow(
                    initials: "MT",
                    topHex: "0x045A5C",
                    bottomHex: "0x0A7F77",
                    name: "Meridian Technologies",
                    followers: "12,408 followers"
                )

                Divider()

                interestCompanyRow(
                    initials: "GC",
                    topHex: "0x1A2744",
                    bottomHex: "0x4A6FA5",
                    name: "Prism Cloud",
                    followers: "5,284,119 followers"
                )

                Divider()

                interestCompanyRow(
                    initials: "HN",
                    topHex: "0x3A2811",
                    bottomHex: "0xD4A34E",
                    name: "HashiCorp",
                    followers: "284,762 followers"
                )

                Divider()

                interestCompanyRow(
                    initials: "DI",
                    topHex: "0x003E6B",
                    bottomHex: "0x0066B2",
                    name: "Docker Inc.",
                    followers: "418,590 followers"
                )
            } else if selectedInterestTab == "Groups" {
                interestCompanyRow(
                    initials: "ID",
                    topHex: "0x004182",
                    bottomHex: "0x0077B5",
                    name: "iOS Developers Community",
                    followers: "42,518 members"
                )

                Divider()

                interestCompanyRow(
                    initials: "SE",
                    topHex: "0x1A3D1A",
                    bottomHex: "0x4DCC4D",
                    name: "SwiftUI Enthusiasts",
                    followers: "18,203 members"
                )

                Divider()

                interestCompanyRow(
                    initials: "TL",
                    topHex: "0x3D1A3D",
                    bottomHex: "0xB84DB8",
                    name: "Tech Leadership Circle",
                    followers: "95,417 members"
                )
            } else {
                interestCompanyRow(
                    initials: "SU",
                    topHex: "0x8C1515",
                    bottomHex: "0xB83A3A",
                    name: "Stanford University",
                    followers: "3,841,029 followers"
                )

                Divider()

                interestCompanyRow(
                    initials: "MI",
                    topHex: "0x00274C",
                    bottomHex: "0x00509E",
                    name: "University of Michigan",
                    followers: "2,150,832 followers"
                )

                Divider()

                interestCompanyRow(
                    initials: "GT",
                    topHex: "0x54585A",
                    bottomHex: "0xB3A369",
                    name: "Georgia Institute of Technology",
                    followers: "1,287,410 followers"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    private func interestTabPill(_ title: String, isSelected: Bool) -> some View {
        Button { selectedInterestTab = title } label: {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : LockedInTheme.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? LockedInTheme.greenButton : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : LockedInTheme.separator, lineWidth: 1)
                )
        }
    }

    private func interestCompanyRow(initials: String, topHex: String, bottomHex: String, name: String, followers: String) -> some View {
        HStack(spacing: 12) {
            CompanyLogoView(
                initials: initials,
                topHex: topHex,
                bottomHex: bottomHex,
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                Text(followers)
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
            }

            Spacer()

            Button {
                if unfollowedInterests.contains(name) {
                    unfollowedInterests.remove(name)
                } else {
                    unfollowedInterests.insert(name)
                }
            } label: {
                Text(unfollowedInterests.contains(name) ? "Follow" : "Following")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(unfollowedInterests.contains(name) ? LockedInTheme.linkedInBlue : LockedInTheme.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(unfollowedInterests.contains(name) ? LockedInTheme.linkedInBlue : LockedInTheme.separator, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Viewers Also Viewed

    private var viewersAlsoViewedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("Who your viewers also viewed")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)

                HStack(spacing: 4) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                    Text("Private to you")
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }

            // Show up to 3 connections as viewer suggestions
            let viewerSuggestions = Array(appState.connections.prefix(3))
            ForEach(viewerSuggestions) { conn in
                viewerAlsoViewedRow(conn)
                if conn.id != viewerSuggestions.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LockedInTheme.cardBackground)
    }

    private func viewerAlsoViewedRow(_ conn: Connection) -> some View {
        HStack(spacing: 12) {
            AvatarView(
                name: conn.fullName,
                    initials: conn.avatarInitials,
                topHex: conn.avatarTopHex,
                bottomHex: conn.avatarBottomHex,
                size: 48
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(conn.fullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                Text(conn.headline)
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                selectedViewerConnection = conn
            } label: {
                Text("View")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(LockedInTheme.linkedInBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                    )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedViewerConnection = conn
        }
    }

    // MARK: - Helpers

    private func mutualConnectionNames(for conn: Connection) -> String {
        let names = appState.connections.filter { $0.id != conn.id }.prefix(2).map { $0.fullName }
        let remaining = max(0, conn.mutualConnections - 2)
        if names.count >= 2 && remaining > 0 {
            return "\(names[0]), \(names[1]), and \(remaining) other mutual connections"
        } else if names.count >= 2 {
            return "\(names[0]) and \(names[1])"
        } else if let first = names.first {
            return first
        }
        return "\(conn.mutualConnections) mutual connections"
    }

    private func connectionExperiences(_ conn: Connection) -> [Experience] {
        [
            Experience(
                id: "exp_\(conn.id)_current",
                title: conn.headline.components(separatedBy: " at ").first ?? conn.headline,
                company: conn.company,
                companyLogoInitials: String(conn.company.prefix(2)),
                locationType: "Hybrid",
                location: conn.location,
                startDate: "Jan 2021",
                endDate: nil,
                description: "",
                isCurrent: true
            )
        ]
    }

    private func connectionEducations(_ conn: Connection) -> [Education] {
        let schools = [
            "Stanford University", "UC Berkeley", "MIT",
            "Cornell University", "University of Washington",
            "Georgia Tech", "University of Michigan"
        ]
        let school = schools[abs(conn.id.hashValue) % schools.count]
        return [
            Education(
                id: "edu_\(conn.id)",
                school: school,
                degree: "Bachelor of Science",
                field: "Computer Science",
                startYear: 2010,
                endYear: 2014,
                activities: ""
            )
        ]
    }

    private func connectionSkills(_ conn: Connection) -> [String] {
        let headline = conn.headline.lowercased()
        if headline.contains("ios") || headline.contains("mobile") || headline.contains("android") {
            return ["Swift", "iOS Development", "UIKit", "SwiftUI", "Mobile Architecture", "Objective-C"]
        } else if headline.contains("data") || headline.contains("ml") || headline.contains("analytics") {
            return ["Python", "Machine Learning", "Data Analysis", "SQL", "TensorFlow", "Statistics"]
        } else if headline.contains("devops") || headline.contains("sre") || headline.contains("platform") || headline.contains("infrastructure") {
            return ["Kubernetes", "Docker", "AWS", "Terraform", "CI/CD", "Linux"]
        } else if headline.contains("product") || headline.contains("program") {
            return ["Product Strategy", "Agile", "Roadmapping", "Cross-functional Leadership", "Analytics", "User Research"]
        } else if headline.contains("design") || headline.contains("ux") {
            return ["Figma", "User Research", "Prototyping", "Design Systems", "Accessibility", "Interaction Design"]
        } else if headline.contains("security") {
            return ["Application Security", "Penetration Testing", "Cloud Security", "OWASP", "Threat Modeling", "Cryptography"]
        } else {
            return ["Software Engineering", "System Design", "Distributed Systems", "Python", "Go", "Cloud Computing"]
        }
    }
}
