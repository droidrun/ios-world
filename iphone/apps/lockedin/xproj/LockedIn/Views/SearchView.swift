import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    @State private var selectedConnection: Connection?
    @State private var selectedJob: Job?
    @State private var recentSearches: [String] = ["Platform Engineer", "Kubernetes", "Jordan Avery"]
    @State private var selectedPost: Post?
    @State private var showAllPeople: Bool = false
    @State private var showAllJobs: Bool = false
    @State private var showAllPostResults: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if searchText.isEmpty {
                    recentSearchesView
                } else {
                    searchResults
                }
            }
            .background(LockedInTheme.background)
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
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(LockedInTheme.secondaryText)
                            .font(.system(size: 14))
                        TextField("Search", text: $searchText)
                            .font(.system(size: 15))
                            .focused($isFocused)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(LockedInTheme.tertiaryText)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xEDF3F8))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .onAppear {
                isFocused = true
            }
            .onChange(of: searchText) { _, _ in
                showAllPeople = false
                showAllJobs = false
                showAllPostResults = false
            }
            .sheet(item: $selectedConnection) { conn in
                ProfileView(connection: conn, isCurrentUser: false)
            }
            .sheet(item: $selectedJob) { job in
                JobDetailView(job: job)
                    .presentationDetents([.large])
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
        }
    }

    // MARK: - Empty State (Recent + Suggested Searches)

    private var recentSearchesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !recentSearches.isEmpty {
                    HStack {
                        Text("Recent")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(LockedInTheme.primaryText)
                        Spacer()
                        Button("Clear") {
                            recentSearches.removeAll()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    ForEach(recentSearches, id: \.self) { search in
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(LockedInTheme.secondaryText)
                            Button {
                                searchText = search
                            } label: {
                                Text(search)
                                    .font(.system(size: 14))
                                    .foregroundColor(LockedInTheme.primaryText)
                            }
                            Spacer()
                            Button {
                                recentSearches.removeAll { $0 == search }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(LockedInTheme.secondaryText)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Divider()
                        .padding(.top, 4)
                }

                Text("Try searching for")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ForEach(suggestedSearches, id: \.self) { suggestion in
                    Button {
                        searchText = suggestion
                        addToRecentSearches(suggestion)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(LockedInTheme.secondaryText)
                            Text(suggestion)
                                .font(.system(size: 14))
                                .foregroundColor(LockedInTheme.primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    Divider().padding(.leading, 48)
                }
            }
            .background(LockedInTheme.cardBackground)
        }
    }

    private func addToRecentSearches(_ term: String) {
        if !recentSearches.contains(term) {
            recentSearches.insert(term, at: 0)
        }
    }

    private var suggestedSearches: [String] {
        [
            "Platform Engineer",
            "Kubernetes",
            "Meridian Technologies",
            "Staff Software Engineer",
            "Remote jobs",
            "San Francisco",
            "Marketing",
            "Goldman Sachs",
            "Healthcare",
            "Nike",
            "McKinsey",
            "New York",
            "Teacher",
            "Nurse",
            "Film Editor"
        ]
    }

    // MARK: - Search Results

    private var searchResults: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // People results
                if !matchingPeople.isEmpty {
                    peopleSectionView
                }

                // Job results
                if !matchingJobs.isEmpty {
                    jobsSectionView
                }

                // Post results
                if !matchingPosts.isEmpty {
                    postsSectionView
                }

                if matchingPeople.isEmpty && matchingJobs.isEmpty && matchingPosts.isEmpty {
                    noResults
                }
            }
        }
    }

    // MARK: - Matching Logic

    private var matchingPeople: [Connection] {
        let query = searchText.lowercased()
        let matchingConnections = appState.connections.filter {
            $0.fullName.lowercased().contains(query) ||
            $0.headline.lowercased().contains(query) ||
            $0.company.lowercased().contains(query) ||
            $0.location.lowercased().contains(query)
        }
        // Also search pending invitations so people visible in
        // the Network tab are discoverable via search.
        let matchingInvitations = appState.invitations.filter {
            $0.fullName.lowercased().contains(query) ||
            $0.headline.lowercased().contains(query)
        }.map { inv in
            Connection(
                id: inv.id,
                firstName: inv.firstName,
                lastName: inv.lastName,
                headline: inv.headline,
                avatarInitials: inv.avatarInitials,
                avatarTopHex: inv.avatarTopHex,
                avatarBottomHex: inv.avatarBottomHex,
                degree: .second,
                mutualConnections: inv.mutualConnections,
                isFollowing: inv.isFollower,
                company: "",
                location: ""
            )
        }
        // Connections first, then invitations
        let connIds = Set(matchingConnections.map { $0.id })
        let uniqueInvitations = matchingInvitations.filter { !connIds.contains($0.id) }
        return matchingConnections + uniqueInvitations
    }

    private var matchingJobs: [Job] {
        let query = searchText.lowercased()
        return appState.jobs.filter {
            $0.title.lowercased().contains(query) ||
            $0.company.lowercased().contains(query) ||
            $0.location.lowercased().contains(query)
        }
    }

    private var matchingPosts: [Post] {
        let query = searchText.lowercased()
        return appState.posts.filter {
            $0.content.lowercased().contains(query) ||
            $0.authorName.lowercased().contains(query) ||
            $0.authorHeadline.lowercased().contains(query)
        }
    }

    // MARK: - People Section

    private var peopleSectionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("People")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                if matchingPeople.count > 5 {
                    Button(showAllPeople ? "Show less" : "See all \(matchingPeople.count) results") {
                        showAllPeople.toggle()
                    }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(showAllPeople ? matchingPeople : Array(matchingPeople.prefix(5))) { person in
                Button {
                    selectedConnection = person
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(
                            name: person.fullName,
                    initials: person.avatarInitials,
                            topHex: person.avatarTopHex,
                            bottomHex: person.avatarBottomHex,
                            size: 44
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(person.fullName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(LockedInTheme.primaryText)
                                Text("\u{2022} \(person.degree.rawValue)")
                                    .font(.system(size: 12))
                                    .foregroundColor(LockedInTheme.secondaryText)
                            }
                            Text(person.headline)
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                Divider().padding(.leading, 72)
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Jobs Section

    private var jobsSectionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Jobs")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                if matchingJobs.count > 3 {
                    Button(showAllJobs ? "Show less" : "See all \(matchingJobs.count) results") {
                        showAllJobs.toggle()
                    }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(showAllJobs ? matchingJobs : Array(matchingJobs.prefix(3))) { job in
                Button {
                    selectedJob = job
                } label: {
                    HStack(spacing: 12) {
                        CompanyLogoView(
                            initials: job.companyLogoInitials,
                            topHex: job.companyLogoTopHex,
                            bottomHex: job.companyLogoBottomHex,
                            size: 44
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(job.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                                .lineLimit(1)
                            Text(job.company)
                                .font(.system(size: 13))
                                .foregroundColor(LockedInTheme.primaryText)
                            Text("\(job.location) (\(job.locationType.rawValue))")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                Divider().padding(.leading, 72)
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Posts Section

    private var postsSectionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Posts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                if matchingPosts.count > 3 {
                    Button(showAllPostResults ? "Show less" : "See all \(matchingPosts.count) results") {
                        showAllPostResults.toggle()
                    }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(showAllPostResults ? matchingPosts : Array(matchingPosts.prefix(3))) { post in
                Button {
                    selectedPost = post
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            AvatarView(
                                name: post.authorName,
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
                            .font(.system(size: 13))
                            .foregroundColor(LockedInTheme.primaryText)
                            .lineLimit(3)

                        HStack(spacing: 4) {
                            HStack(spacing: -2) {
                                ForEach(post.topReactions.prefix(3), id: \.self) { reaction in
                                    ZStack {
                                        Circle()
                                            .fill(Color(hexString: reaction.iconColor))
                                            .frame(width: 18, height: 18)
                                        Image(systemName: reaction.sfSymbol)
                                            .font(.system(size: 9))
                                            .foregroundColor(.white)
                                    }
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                }
                            }
                            Text("\(post.reactionCount.abbreviatedString()) reactions")
                                .font(.system(size: 11))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                Divider().padding(.leading, 16)
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - No Results

    private var noResults: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(LockedInTheme.tertiaryText)
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(LockedInTheme.primaryText)
            Text("Try different keywords or check the spelling.")
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(LockedInTheme.cardBackground)
    }
}
