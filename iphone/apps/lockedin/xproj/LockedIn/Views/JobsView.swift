import SwiftUI

struct JobsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSearchResults: Bool = false
    @State private var selectedJob: Job?
    @State private var searchQuery: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var showMyProfile: Bool = false
    @State private var showSavedJobs: Bool = false
    // jobAlertEnabled is stored in appState for persistence
    @State private var activeFilters: Set<String> = []
    @State private var sortOption: String = "Most relevant"
    @State private var showSortPicker: Bool = false
    @State private var showPostJobAlert: Bool = false
    @State private var showDatePostedPicker: Bool = false
    @State private var selectedDatePosted: String = ""
    @State private var showExperienceLevelPicker: Bool = false
    @State private var selectedExperienceLevel: String = ""
    @State private var showCompanyPicker: Bool = false
    @State private var selectedCompany: String = ""
    @State private var showFilterSheet: Bool = false

    private var filteredJobs: [Job] {
        var jobs: [Job]
        if showSearchResults {
            let query = searchQuery.lowercased().trimmingCharacters(in: .whitespaces)
            if query.isEmpty {
                jobs = appState.jobs
            } else {
                jobs = appState.jobs.filter {
                    $0.title.lowercased().contains(query) ||
                    $0.company.lowercased().contains(query) ||
                    $0.location.lowercased().contains(query) ||
                    $0.locationType.rawValue.lowercased().contains(query)
                }
            }
        } else {
            jobs = appState.jobs
        }

        // Apply active filters
        if activeFilters.contains("Remote") {
            jobs = jobs.filter { $0.locationType == .remote }
        }
        if activeFilters.contains("Easy Apply") {
            jobs = jobs.filter { $0.isEasyApply }
        }
        if activeFilters.contains("Salary") {
            jobs = jobs.filter { $0.salaryRange != nil }
        }

        // Date posted filter
        if !selectedDatePosted.isEmpty {
            jobs = jobs.filter { matchesDateFilter($0.postedTimeAgo, period: selectedDatePosted) }
        }

        // Experience level filter
        if !selectedExperienceLevel.isEmpty {
            jobs = jobs.filter { matchesExperienceLevel($0.title, level: selectedExperienceLevel) }
        }

        // Company filter
        if !selectedCompany.isEmpty {
            jobs = jobs.filter { $0.company == selectedCompany }
        }

        // Apply sort
        switch sortOption {
        case "Most recent":
            jobs = jobs.sorted { timeAgoToHours($0.postedTimeAgo) < timeAgoToHours($1.postedTimeAgo) }
        case "Salary (highest first)":
            jobs = jobs.sorted { ($0.salaryRange ?? "") > ($1.salaryRange ?? "") }
        default:
            break
        }

        return jobs
    }

    private func timeAgoToHours(_ timeAgo: String) -> Int {
        let lower = timeAgo.lowercased()
        let number = Int(lower.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 1
        if lower.contains("min") || lower.contains("just now") { return 0 }
        if lower.contains("h ago") || lower.contains("hour") { return number }
        if lower.contains("d ago") || lower.contains("day") { return number * 24 }
        if lower.contains("w ago") || lower.contains("week") { return number * 24 * 7 }
        if lower.contains("mo ago") || lower.contains("month") { return number * 24 * 30 }
        return number * 24 * 365
    }

    private func matchesDateFilter(_ timeAgo: String, period: String) -> Bool {
        let lower = timeAgo.lowercased()
        switch period {
        case "Past 24 hours":
            return lower.contains("h ago") || lower.contains("min ago") || lower.contains("just now")
        case "Past week":
            return lower.contains("h ago") || lower.contains("min ago") || lower.contains("just now") ||
                   (lower.contains("d ago") && !lower.contains("w ago"))
        case "Past month":
            return !lower.contains("mo ago")
        default:
            return true
        }
    }

    private func matchesExperienceLevel(_ title: String, level: String) -> Bool {
        let lower = title.lowercased()
        switch level {
        case "Entry level":
            return lower.contains("junior") || lower.contains("associate") || lower.contains("intern") ||
                   lower.contains("entry") || lower.contains("assistant") || lower.contains("coordinator")
        case "Mid-Senior level":
            return lower.contains("senior") || lower.contains("staff") || lower.contains("lead") ||
                   lower.contains("principal") || lower.contains("sr.")
        case "Director":
            return lower.contains("director") || lower.contains("vp") || lower.contains("head of") ||
                   lower.contains("vice president")
        case "Executive":
            return lower.contains("chief") || lower.contains("ceo") || lower.contains("cto") ||
                   lower.contains("cfo") || lower.contains("president") || lower.contains("founder")
        default:
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if showSearchResults {
                jobSearchResultsView
            } else {
                jobsMainView
            }
        }
        .background(LockedInTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if showSearchResults {
                    Button {
                        withAnimation {
                            showSearchResults = false
                            searchQuery = ""
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(LockedInTheme.primaryText)
                    }
                } else {
                    Button {
                        showMyProfile = true
                    } label: {
                        AvatarView(
                            initials: appState.currentUser.avatarInitials,
                            topHex: appState.currentUser.avatarTopHex,
                            bottomHex: appState.currentUser.avatarBottomHex,
                            size: 30
                        )
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                if showSearchResults {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(LockedInTheme.secondaryText)
                            .font(.system(size: 14))
                        TextField("Search jobs", text: $searchQuery)
                            .font(.system(size: 15))
                            .focused($isSearchFocused)
                            .accessibilityIdentifier("jobs_search_field")
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
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
                } else {
                    Button {
                        withAnimation { showSearchResults = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isSearchFocused = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(LockedInTheme.secondaryText)
                                .font(.system(size: 14))
                            Text("Search jobs")
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
            ToolbarItem(placement: .navigationBarTrailing) {
                if showSearchResults {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                } else {
                    Button {
                        appState.showMessaging = true
                    } label: {
                        Image(systemName: "message.fill")
                            .font(.system(size: 18))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }
            }
        }
        .sheet(item: $selectedJob) { job in
            JobDetailView(job: job)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showMyProfile) {
            ProfileMenuView()
        }
        .sheet(isPresented: $showSavedJobs) {
            NavigationStack {
                Group {
                    let savedJobs = appState.jobs.filter { $0.isSaved }
                    if savedJobs.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "bookmark")
                                .font(.system(size: 48))
                                .foregroundColor(LockedInTheme.tertiaryText)
                            Text("No saved jobs yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText)
                            Text("Save jobs you're interested in by tapping the bookmark icon.")
                                .font(.system(size: 14))
                                .foregroundColor(LockedInTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        List(savedJobs) { job in
                            Button {
                                showSavedJobs = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    selectedJob = job
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(job.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(LockedInTheme.linkedInBlue)
                                    Text(job.company)
                                        .font(.system(size: 13))
                                        .foregroundColor(LockedInTheme.primaryText)
                                    Text(job.location)
                                        .font(.system(size: 12))
                                        .foregroundColor(LockedInTheme.secondaryText)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("My Jobs")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showSavedJobs = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                List {
                    Section("Location") {
                        filterToggleRow("Remote", icon: "wifi")
                    }
                    Section("Job type") {
                        filterToggleRow("Easy Apply", icon: "checkmark.seal")
                    }
                    Section("Salary") {
                        filterToggleRow("Salary", icon: "dollarsign.circle")
                    }
                    Section("Date posted") {
                        ForEach(["Past 24 hours", "Past week", "Past month"], id: \.self) { option in
                            Button {
                                selectedDatePosted = selectedDatePosted == option ? "" : option
                            } label: {
                                HStack {
                                    Text(option)
                                        .foregroundColor(LockedInTheme.primaryText)
                                    Spacer()
                                    if selectedDatePosted == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(LockedInTheme.linkedInBlue)
                                    }
                                }
                            }
                        }
                    }
                    Section("Experience level") {
                        ForEach(["Entry level", "Mid-Senior level", "Director", "Executive"], id: \.self) { option in
                            Button {
                                selectedExperienceLevel = selectedExperienceLevel == option ? "" : option
                            } label: {
                                HStack {
                                    Text(option)
                                        .foregroundColor(LockedInTheme.primaryText)
                                    Spacer()
                                    if selectedExperienceLevel == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(LockedInTheme.linkedInBlue)
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        Button("Reset all filters", role: .destructive) {
                            activeFilters.removeAll()
                            selectedDatePosted = ""
                            selectedExperienceLevel = ""
                            selectedCompany = ""
                        }
                    }
                }
                .navigationTitle("All filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showFilterSheet = false }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Post a Free Job", isPresented: $showPostJobAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Create a job listing to find qualified candidates. Free job posts get up to 50 applicants.")
        }
        .confirmationDialog("Sort by", isPresented: $showSortPicker, titleVisibility: .visible) {
            Button("Most relevant") { sortOption = "Most relevant" }
            Button("Most recent") { sortOption = "Most recent" }
            Button("Salary (highest first)") { sortOption = "Salary (highest first)" }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Jobs Main View

    private var jobsMainView: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Action pills
                actionPills

                // Suggested job searches
                suggestedSearches

                // Jobs based on activity
                jobRecommendations
            }
        }
    }

    // MARK: - Action Pills

    private var actionPills: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    actionPillButton(icon: "slider.horizontal.3", title: "Preferences") {
                        withAnimation { showSearchResults = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isSearchFocused = true }
                    }
                    actionPillButton(icon: "bookmark", title: "My jobs") {
                        showSavedJobs = true
                    }
                    actionPillButton(icon: "plus.square", title: "Post a free job") {
                        showPostJobAlert = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    private func actionPillButton(icon: String, title: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(LockedInTheme.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LockedInTheme.separator, lineWidth: 1)
            )
        }
    }

    // MARK: - Suggested Searches

    private var suggestedSearches: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Suggested job searches")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(LockedInTheme.primaryText)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            ForEach(suggestedSearchItems, id: \.title) { item in
                Button {
                    searchQuery = item.title
                    withAnimation { showSearchResults = true }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(LockedInTheme.linkedInBlue.opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                            Text(item.subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                if item.title != suggestedSearchItems.last?.title {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    private struct SearchItem: Hashable {
        let title: String
        let subtitle: String
    }

    private var suggestedSearchItems: [SearchItem] {
        [
            SearchItem(title: "Platform Engineer", subtitle: "Based on your profile"),
            SearchItem(title: "Staff Software Engineer", subtitle: "Based on your profile"),
            SearchItem(title: "DevOps Engineer", subtitle: "Based on your searches"),
            SearchItem(title: "SRE Manager", subtitle: "Based on your profile"),
            SearchItem(title: "Machine Learning Engineer", subtitle: "Trending in your area"),
            SearchItem(title: "Product Manager", subtitle: "Based on your network")
        ]
    }

    // MARK: - Job Recommendations

    private var jobRecommendations: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Top job picks for you")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)
                Text("Based on your profile and search history")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ForEach(Array(appState.jobs.prefix(8))) { job in
                jobRow(job)
            }

            // Show all button
            Button {
                withAnimation { showSearchResults = true }
            } label: {
                HStack {
                    Text("Show all")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13))
                }
                .foregroundColor(LockedInTheme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }

            Divider()
        }
        .background(LockedInTheme.cardBackground)
    }

    private func jobRow(_ job: Job) -> some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.leading, 72)

            HStack(alignment: .top, spacing: 12) {
                CompanyLogoView(
                    initials: job.companyLogoInitials,
                    topHex: job.companyLogoTopHex,
                    bottomHex: job.companyLogoBottomHex,
                    size: 48
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                        .lineLimit(2)

                    Text(job.company)
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.primaryText)

                    Text("\(job.location) (\(job.locationType.rawValue))")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)

                    if let salary = job.salaryRange {
                        HStack(spacing: 4) {
                            Text(salary)
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                            if !job.benefits.isEmpty {
                                Text("\u{2022}")
                                    .font(.system(size: 8))
                                    .foregroundColor(LockedInTheme.secondaryText)
                                Text(job.benefits.joined(separator: ", "))
                                    .font(.system(size: 12))
                                    .foregroundColor(LockedInTheme.secondaryText)
                            }
                        }
                    }

                    if job.isActivelyRecruiting {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.greenButton)
                            Text("Actively recruiting")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.greenButton)
                        }
                        .padding(.top, 2)
                    }

                    if job.connectionsAtCompany > 0 {
                        HStack(spacing: 4) {
                            HStack(spacing: -6) {
                                ForEach(0..<min(2, job.connectionsAtCompany), id: \.self) { _ in
                                    Circle()
                                        .fill(Color(hex: 0xDDDDDD))
                                        .frame(width: 14, height: 14)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                            Text("\(job.connectionsAtCompany) connections")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        .padding(.top, 1)
                    }

                    HStack(spacing: 4) {
                        Text(job.postedTimeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(LockedInTheme.secondaryText)
                        if job.isPromoted {
                            Text("\u{2022} Promoted")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        if job.isEasyApply {
                            Text("\u{2022}")
                                .font(.system(size: 8))
                                .foregroundColor(LockedInTheme.secondaryText)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                            Text("Easy Apply")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                    .padding(.top, 1)
                }

                Spacer()

                Button {
                    appState.toggleSaveJob(job.id)
                } label: {
                    Image(systemName: job.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(job.isSaved ? LockedInTheme.linkedInBlue : LockedInTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("job_row_\(job.id)")
        .onTapGesture {
            selectedJob = job
        }
    }

    // MARK: - Job Search Results View

    private var jobSearchResultsView: some View {
        VStack(spacing: 0) {
            // Filter pills
            searchFilterPills

            // Results
            ScrollView {
                VStack(spacing: 0) {
                    // Results header
                    HStack {
                        Text("\(filteredJobs.count) result\(filteredJobs.count == 1 ? "" : "s")")
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.secondaryText)
                        Spacer()
                        Button {
                            showSortPicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Sort by: \(sortOption)")
                                    .font(.system(size: 14))
                                    .foregroundColor(LockedInTheme.secondaryText)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(LockedInTheme.secondaryText)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(LockedInTheme.cardBackground)

                    Divider()

                    if filteredJobs.isEmpty {
                        noJobResults
                    } else {
                        // Job list
                        LazyVStack(spacing: 0) {
                            ForEach(filteredJobs) { job in
                                searchResultRow(job)
                            }
                        }
                        .background(LockedInTheme.cardBackground)
                    }

                    // Set job alert
                    setJobAlertCard
                }
            }
        }
    }

    // MARK: - No Results

    private var noJobResults: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "briefcase")
                .font(.system(size: 48))
                .foregroundColor(LockedInTheme.tertiaryText)
            Text("No jobs found for \"\(searchQuery)\"")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(LockedInTheme.primaryText)
            Text("Try different keywords or broaden your search.")
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - Search Filters

    private var searchFilterPills: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    pickerFilterPill(
                        title: selectedDatePosted.isEmpty ? "Date posted" : selectedDatePosted,
                        isActive: !selectedDatePosted.isEmpty
                    ) {
                        if !selectedDatePosted.isEmpty { selectedDatePosted = "" }
                        else { showDatePostedPicker = true }
                    }
                    pickerFilterPill(
                        title: selectedExperienceLevel.isEmpty ? "Experience level" : selectedExperienceLevel,
                        isActive: !selectedExperienceLevel.isEmpty
                    ) {
                        if !selectedExperienceLevel.isEmpty { selectedExperienceLevel = "" }
                        else { showExperienceLevelPicker = true }
                    }
                    pickerFilterPill(
                        title: selectedCompany.isEmpty ? "Company" : selectedCompany,
                        isActive: !selectedCompany.isEmpty
                    ) {
                        if !selectedCompany.isEmpty { selectedCompany = "" }
                        else { showCompanyPicker = true }
                    }
                    toggleFilterPill("Remote")
                    toggleFilterPill("Easy Apply")
                    toggleFilterPill("Salary")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(LockedInTheme.cardBackground)

            Divider()
        }
        .confirmationDialog("Date posted", isPresented: $showDatePostedPicker, titleVisibility: .visible) {
            Button("Past 24 hours") { selectedDatePosted = "Past 24 hours" }
            Button("Past week") { selectedDatePosted = "Past week" }
            Button("Past month") { selectedDatePosted = "Past month" }
            Button("Any time") { selectedDatePosted = "" }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Experience level", isPresented: $showExperienceLevelPicker, titleVisibility: .visible) {
            Button("Entry level") { selectedExperienceLevel = "Entry level" }
            Button("Mid-Senior level") { selectedExperienceLevel = "Mid-Senior level" }
            Button("Director") { selectedExperienceLevel = "Director" }
            Button("Executive") { selectedExperienceLevel = "Executive" }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Company", isPresented: $showCompanyPicker, titleVisibility: .visible) {
            ForEach(topCompanies, id: \.self) { company in
                Button(company) { selectedCompany = company }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var topCompanies: [String] {
        var counts: [String: Int] = [:]
        for job in appState.jobs {
            counts[job.company, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(8).map { $0.key }
    }

    private func toggleFilterPill(_ title: String) -> some View {
        Button {
            if activeFilters.contains(title) {
                activeFilters.remove(title)
            } else {
                activeFilters.insert(title)
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Image(systemName: activeFilters.contains(title) ? "xmark" : "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundColor(activeFilters.contains(title) ? .white : LockedInTheme.secondaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(activeFilters.contains(title) ? LockedInTheme.linkedInBlue : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(activeFilters.contains(title) ? Color.clear : LockedInTheme.separator, lineWidth: 1)
            )
        }
    }

    private func pickerFilterPill(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Image(systemName: isActive ? "xmark" : "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundColor(isActive ? .white : LockedInTheme.secondaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isActive ? LockedInTheme.linkedInBlue : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? Color.clear : LockedInTheme.separator, lineWidth: 1)
            )
        }
    }

    private func filterToggleRow(_ title: String, icon: String) -> some View {
        Button {
            if activeFilters.contains(title) {
                activeFilters.remove(title)
            } else {
                activeFilters.insert(title)
            }
        } label: {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                if activeFilters.contains(title) {
                    Image(systemName: "checkmark")
                        .foregroundColor(LockedInTheme.linkedInBlue)
                }
            }
        }
    }

    // MARK: - Search Result Row

    private func searchResultRow(_ job: Job) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                CompanyLogoView(
                    initials: job.companyLogoInitials,
                    topHex: job.companyLogoTopHex,
                    bottomHex: job.companyLogoBottomHex,
                    size: 48
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(job.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.linkedInBlue)
                        .lineLimit(2)

                    Text(job.company)
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.primaryText)

                    Text("\(job.location) (\(job.locationType.rawValue))")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)

                    if let salary = job.salaryRange {
                        Text(salary)
                            .font(.system(size: 12))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }

                    if job.isActivelyRecruiting {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.greenButton)
                            Text("Actively recruiting")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.greenButton)
                        }
                    }

                    if job.connectionsAtCompany > 0 {
                        HStack(spacing: 4) {
                            HStack(spacing: -6) {
                                ForEach(0..<min(2, job.connectionsAtCompany), id: \.self) { _ in
                                    Circle()
                                        .fill(Color(hex: 0xDDDDDD))
                                        .frame(width: 14, height: 14)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                            Text("\(job.connectionsAtCompany) connections")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }

                    HStack(spacing: 4) {
                        Text(job.postedTimeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(LockedInTheme.tertiaryText)
                        if job.isPromoted {
                            Text("\u{2022} Promoted")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.tertiaryText)
                        }
                        if job.isEasyApply {
                            Text("\u{2022}")
                                .font(.system(size: 8))
                                .foregroundColor(LockedInTheme.tertiaryText)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                            Text("Easy Apply")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                    }
                }

                Spacer()

                Button {
                    appState.toggleSaveJob(job.id)
                } label: {
                    Image(systemName: job.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(job.isSaved ? LockedInTheme.linkedInBlue : LockedInTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, 76)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("job_result_row_\(job.id)")
        .onTapGesture {
            selectedJob = job
        }
    }

    // MARK: - Set Job Alert

    private var setJobAlertCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 32))
                .foregroundColor(LockedInTheme.linkedInBlue)

            Text("Set alert for \(searchQuery.isEmpty ? "similar" : "\"\(searchQuery)\"") jobs")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(LockedInTheme.primaryText)
                .multilineTextAlignment(.center)

            Button {
                appState.jobAlertEnabled = true
            } label: {
                Text(appState.jobAlertEnabled ? "Alert set \u{2713}" : "Set alert")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(appState.jobAlertEnabled ? LockedInTheme.greenButton : LockedInTheme.linkedInBlue)
                    )
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(LockedInTheme.cardBackground)
    }
}
