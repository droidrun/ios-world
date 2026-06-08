import SwiftUI

struct JobDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let job: Job
    @State private var hasApplied: Bool = false
    // alertEnabled is synced from appState in .onAppear
    @State private var showFullDescription: Bool = false
    @State private var showJobActions: Bool = false
    @State private var showMatchDetails: Bool = false
    @State private var matchFeedback: Int = 0
    @State private var showPremiumAlert: Bool = false
    @State private var showReportConfirm: Bool = false

    private var liveJob: Job {
        appState.jobs.first(where: { $0.id == job.id }) ?? job
    }

    private var companyFollowerCount: Int {
        let hash = abs(job.company.hashValue)
        let base = (hash % 900_000) + 100_000
        return base + job.connectionsAtCompany * 1000
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: 0xCCCCCC))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            HStack {
                Spacer()
                Button { showJobActions = true } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Company + Title
                    jobHeader

                    // Apply / Save buttons
                    applyButtons

                    // Profile match card
                    profileMatchCard

                    // People you can reach out to
                    peopleToReachOut

                    sectionDivider

                    // About the job
                    aboutTheJob

                    sectionDivider

                    // Set alert for similar jobs
                    setAlertSection

                    sectionDivider

                    // Premium upsell
                    premiumUpsell

                    sectionDivider

                    // About the company
                    aboutTheCompany
                }
            }

            // Bottom bar
            bottomBar
        }
        .background(LockedInTheme.cardBackground)
        .confirmationDialog("", isPresented: $showJobActions) {
            Button("Share job") {
                UIPasteboard.general.string = "https://lockedin.example/jobs/view/\(job.id)"
            }
            Button("Report job", role: .destructive) {
                showReportConfirm = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Report Submitted", isPresented: $showReportConfirm) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for your report. We'll review this job listing and take action if it violates our policies.")
        }
        .alert("Profile Match", isPresented: $showMatchDetails) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your skills and experience closely match this role's requirements. You have relevant experience in the key areas this employer is looking for.")
        }
        .alert("LockedIn Premium", isPresented: $showPremiumAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Start your free 1-month Premium trial to see who's viewed your profile, get AI-powered insights, and stand out to recruiters.")
        }
        .onAppear { hasApplied = appState.appliedJobs.contains(job.id) }
    }

    // MARK: - Job Header

    private var jobHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                CompanyLogoView(
                    initials: job.companyLogoInitials,
                    topHex: job.companyLogoTopHex,
                    bottomHex: job.companyLogoBottomHex,
                    size: 36
                )
                Text(job.company)
                    .font(.system(size: 14))
                    .foregroundColor(LockedInTheme.primaryText)
            }

            Text(job.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(LockedInTheme.primaryText)

            if job.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(LockedInTheme.linkedInBlue)
            }

            HStack(spacing: 4) {
                Text(job.location)
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
                Text("\u{2022}")
                    .font(.system(size: 8))
                    .foregroundColor(LockedInTheme.secondaryText)
                Text("Posted \(job.postedTimeAgo)")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
            }

            if job.isActivelyRecruiting {
                Text("Over 100 people clicked apply")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
            }

            if job.isEasyApply {
                Text("Responses managed on LockedIn")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
            } else {
                Text("Responses managed off LockedIn")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
            }

            // Job type pill
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12))
                Text(job.employmentType.rawValue)
                    .font(.system(size: 13))
            }
            .foregroundColor(LockedInTheme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LockedInTheme.separator, lineWidth: 1)
            )
            .padding(.top, 4)
        }
        .padding(16)
    }

    // MARK: - Apply / Save Buttons

    private var applyButtons: some View {
        HStack(spacing: 8) {
            Button(action: { UINotificationFeedbackGenerator().notificationOccurred(.success); hasApplied = true; appState.applyToJob(job.id) }) {
                if hasApplied || appState.appliedJobs.contains(job.id) {
                    Text("Applied \u{2713}")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.green)
                        )
                } else {
                    HStack(spacing: 4) {
                        Text("Apply")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LockedInTheme.linkedInBlue)
                    )
                }
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                appState.toggleSaveJob(job.id)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: liveJob.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14))
                    Text(liveJob.isSaved ? "Saved" : "Save")
                        .font(.system(size: 15, weight: .semibold))
                }
                    .foregroundColor(liveJob.isSaved ? LockedInTheme.secondaryText : LockedInTheme.linkedInBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(liveJob.isSaved ? LockedInTheme.separator : LockedInTheme.linkedInBlue, lineWidth: 1)
                    )
            }
            .accessibilityIdentifier("job_save_button")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Profile Match Card

    private var profileMatchCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    (
                        Text("Your profile is ")
                            .foregroundColor(LockedInTheme.primaryText) +
                        Text("a strong match")
                            .foregroundColor(LockedInTheme.greenButton)
                    )
                    .font(.system(size: 16, weight: .semibold))

                    Button { showMatchDetails = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.premiumGold)
                            Text("Show match details")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(LockedInTheme.primaryText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LockedInTheme.separator, lineWidth: 1)
                        )
                    }
                }

                Spacer()

                ZStack {
                    CompanyLogoView(
                        initials: job.companyLogoInitials,
                        topHex: job.companyLogoTopHex,
                        bottomHex: job.companyLogoBottomHex,
                        size: 36
                    )
                    .offset(x: 10, y: -10)

                    AvatarView(
                        name: appState.currentUser.fullName,
                        initials: appState.currentUser.avatarInitials,
                        topHex: appState.currentUser.avatarTopHex,
                        bottomHex: appState.currentUser.avatarBottomHex,
                        size: 36,
                        showBorder: true
                    )
                    .offset(x: -10, y: 10)
                }
            }

            HStack(spacing: 4) {
                Text("BETA")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(LockedInTheme.secondaryText)
                Text("\u{2022}")
                    .font(.system(size: 6))
                    .foregroundColor(LockedInTheme.secondaryText)
                Text("Is this information helpful?")
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)

                Spacer()

                Button { matchFeedback = 1 } label: {
                    Image(systemName: "hand.thumbsup\(matchFeedback == 1 ? ".fill" : "")")
                        .font(.system(size: 14))
                        .foregroundColor(matchFeedback == 1 ? LockedInTheme.linkedInBlue : LockedInTheme.secondaryText)
                }
                Button { matchFeedback = -1 } label: {
                    Image(systemName: "hand.thumbsdown\(matchFeedback == -1 ? ".fill" : "")")
                        .font(.system(size: 14))
                        .foregroundColor(matchFeedback == -1 ? LockedInTheme.linkedInBlue : LockedInTheme.secondaryText)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(LockedInTheme.separator, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - People to Reach Out

    private var peopleToReachOut: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("People you can reach out to")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(LockedInTheme.primaryText)

            if let matchingConn = appState.connections.first(where: { $0.company == job.company }) {
                HStack(spacing: 12) {
                    AvatarView(
                        name: matchingConn.fullName,
                    initials: matchingConn.avatarInitials,
                        topHex: matchingConn.avatarTopHex,
                        bottomHex: matchingConn.avatarBottomHex,
                        size: 48
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(matchingConn.fullName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText)
                            Text("\u{2022} \(matchingConn.degree.rawValue)")
                                .font(.system(size: 13))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        Text(matchingConn.headline)
                            .font(.system(size: 12))
                            .foregroundColor(LockedInTheme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button(action: { appState.showMessaging = true }) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 18))
                            .foregroundColor(LockedInTheme.secondaryText)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(LockedInTheme.separator, lineWidth: 1)
                            )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LockedInTheme.separator, lineWidth: 1)
                )
            } else if let conn = appState.connections.first {
                // Show a generic connection
                HStack(spacing: 12) {
                    AvatarView(
                        name: conn.fullName,
                    initials: conn.avatarInitials,
                        topHex: conn.avatarTopHex,
                        bottomHex: conn.avatarBottomHex,
                        size: 48
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(conn.fullName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText)
                            Text("\u{2022} \(conn.degree.rawValue)")
                                .font(.system(size: 13))
                                .foregroundColor(LockedInTheme.secondaryText)
                        }
                        Text(conn.headline)
                            .font(.system(size: 12))
                            .foregroundColor(LockedInTheme.secondaryText)
                            .lineLimit(1)
                        Text("School alum from \(appState.currentUser.educations.first?.school ?? "your university")")
                            .font(.system(size: 12))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }

                    Spacer()

                    Button(action: { appState.showMessaging = true }) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 18))
                            .foregroundColor(LockedInTheme.secondaryText)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(LockedInTheme.separator, lineWidth: 1)
                            )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LockedInTheme.separator, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Rectangle()
            .fill(LockedInTheme.background)
            .frame(height: 8)
    }

    // MARK: - About the Job

    private var aboutTheJob: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About the job")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(LockedInTheme.primaryText)

            Text(jobDescription)
                .font(.system(size: 14))
                .foregroundColor(LockedInTheme.primaryText)
                .lineSpacing(3)
                .lineLimit(showFullDescription ? nil : 8)

            if !showFullDescription {
                Button(action: { showFullDescription = true }) {
                    Text("...more")
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private var jobDescription: String {
        let titleLower = job.title.lowercased()
        let responsibilities: String
        let requirements: String

        if titleLower.contains("engineer") || titleLower.contains("developer") {
            responsibilities = "design, build, and maintain scalable systems and applications. You'll collaborate with cross-functional teams to deliver reliable, high-performance solutions"
            requirements = "\u{2022} 3-7+ years of software engineering experience\n\u{2022} Proficiency in one or more programming languages\n\u{2022} Experience with distributed systems and cloud platforms\n\u{2022} Strong problem-solving and communication skills"
        } else if titleLower.contains("manager") || titleLower.contains("director") || titleLower.contains("lead") {
            responsibilities = "lead and mentor a team while driving strategic initiatives. You'll set goals, remove blockers, and ensure your team delivers impactful results"
            requirements = "\u{2022} 5-10+ years of relevant experience with 2+ years in leadership\n\u{2022} Proven track record of managing high-performing teams\n\u{2022} Strong strategic thinking and stakeholder management skills\n\u{2022} Experience with agile methodologies"
        } else if titleLower.contains("analyst") || titleLower.contains("data") || titleLower.contains("scientist") {
            responsibilities = "analyze complex datasets, build models, and generate actionable insights that drive business decisions"
            requirements = "\u{2022} 2-5+ years in data analysis or related field\n\u{2022} Proficiency in SQL, Python, or R\n\u{2022} Experience with data visualization tools\n\u{2022} Strong analytical and presentation skills"
        } else if titleLower.contains("design") || titleLower.contains("ux") || titleLower.contains("creative") {
            responsibilities = "create intuitive, user-centered designs and experiences. You'll conduct user research, build prototypes, and collaborate with engineering"
            requirements = "\u{2022} 3-5+ years of design experience with a strong portfolio\n\u{2022} Proficiency in Figma, Sketch, or Adobe Creative Suite\n\u{2022} Experience with user research and usability testing\n\u{2022} Strong visual design skills"
        } else if titleLower.contains("nurse") || titleLower.contains("therapist") || titleLower.contains("clinical") || titleLower.contains("veterinar") {
            responsibilities = "provide exceptional care while collaborating with interdisciplinary teams. You'll assess, plan, and implement treatment strategies"
            requirements = "\u{2022} Valid professional license in relevant field\n\u{2022} Clinical experience in a healthcare setting\n\u{2022} Strong interpersonal and communication skills\n\u{2022} Commitment to patient safety and evidence-based practice"
        } else if titleLower.contains("teacher") || titleLower.contains("professor") || titleLower.contains("instructor") || titleLower.contains("educator") {
            responsibilities = "develop and deliver engaging curriculum while fostering an inclusive learning environment"
            requirements = "\u{2022} Relevant teaching certification or advanced degree\n\u{2022} 2+ years of teaching experience\n\u{2022} Excellent classroom management skills\n\u{2022} Passion for student development"
        } else {
            responsibilities = "contribute to key initiatives and collaborate across teams to achieve organizational goals"
            requirements = "\u{2022} 3-5+ years of relevant professional experience\n\u{2022} Strong communication and organizational skills\n\u{2022} Ability to work independently and in a team\n\u{2022} Track record of delivering results"
        }

        return "We are looking for a \(job.title) to join our team at \(job.company). This role is based in \(job.location) (\(job.locationType.rawValue)).\n\nAs a \(job.title), you will \(responsibilities).\n\nRequirements:\n\(requirements)\n\nBenefits:\n\u{2022} Competitive salary\(job.salaryRange.map { " (\($0))" } ?? "")\n\u{2022} Comprehensive health, dental, and vision insurance\n\u{2022} 401(k) with company match\n\u{2022} Professional development opportunities"
    }

    // MARK: - Set Alert

    private var setAlertSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set alert for similar jobs")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(LockedInTheme.primaryText)
                Text("\(job.title), \(job.location)")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
            }

            Spacer()

            Toggle("", isOn: $appState.jobAlertEnabled)
                .labelsHidden()
        }
        .padding(16)
    }

    // MARK: - Premium Upsell

    private var premiumUpsell: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Job search faster with Premium")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(LockedInTheme.primaryText)

            Text("Access company insights like strategic priorities, headcount trends, and more")
                .font(.system(size: 13))
                .foregroundColor(LockedInTheme.secondaryText)

            HStack(spacing: 8) {
                HStack(spacing: -8) {
                    ForEach(0..<3, id: \.self) { i in
                        let colors = [
                            ("0x2B1F4E", "0x8B6FD4"),
                            ("0x1A3C2D", "0x4DB882"),
                            ("0x3A2811", "0xD4A34E")
                        ]
                        AvatarView(
                            initials: ["BM", "DH", "KS"][i],
                            topHex: colors[i].0,
                            bottomHex: colors[i].1,
                            size: 24,
                            showBorder: true
                        )
                    }
                }
                Text("Blair and millions of other members use Premium")
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)
            }

            Button(action: { showPremiumAlert = true }) {
                Text("Try Premium for $0")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LockedInTheme.premiumGold.opacity(0.2))
                    )
            }
            .padding(.top, 4)

            Text("1-month free trial. We'll send you a reminder 7 days before your trial ends.")
                .font(.system(size: 12))
                .foregroundColor(LockedInTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    // MARK: - About the Company

    private var aboutTheCompany: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About the company")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(LockedInTheme.primaryText)

            HStack(spacing: 12) {
                CompanyLogoView(
                    initials: job.companyLogoInitials,
                    topHex: job.companyLogoTopHex,
                    bottomHex: job.companyLogoBottomHex,
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.company)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                    Text("\(companyFollowerCount.abbreviatedString()) followers")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                }

                Spacer()

                Button(action: { appState.toggleFollowCompany(job.company) }) {
                    if appState.followedCompanies.contains(job.company) {
                        Text("Following")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                            )
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Follow")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(LockedInTheme.linkedInBlue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .padding(.bottom, 40)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                Button(action: { UINotificationFeedbackGenerator().notificationOccurred(.success); hasApplied = true; appState.applyToJob(job.id) }) {
                    if hasApplied || appState.appliedJobs.contains(job.id) {
                        Text("Applied \u{2713}")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.green)
                            )
                    } else {
                        HStack(spacing: 4) {
                            Text("Apply")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(LockedInTheme.linkedInBlue)
                        )
                    }
                }

                Button {
                    appState.toggleSaveJob(job.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: liveJob.isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14))
                        Text(liveJob.isSaved ? "Saved" : "Save")
                            .font(.system(size: 15, weight: .semibold))
                    }
                        .foregroundColor(liveJob.isSaved ? LockedInTheme.secondaryText : LockedInTheme.linkedInBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(liveJob.isSaved ? LockedInTheme.separator : LockedInTheme.linkedInBlue, lineWidth: 1)
                        )
                }
                .accessibilityIdentifier("job_save_button")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(LockedInTheme.cardBackground)
        }
    }
}
