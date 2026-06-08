import SwiftUI

struct NetworkView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedConnection: Connection?
    @State private var showMyProfile: Bool = false
    @State private var acceptedInvitations: Set<String> = []
    @State private var catchUpProfileConnection: Connection?
    @State private var hideGamesCard: Bool = false
    @State private var hidePremiumCard: Bool = false
    @State private var dismissedSuggestions: Set<String> = []
    @State private var showGameAlert: Bool = false
    @State private var selectedGameName: String = ""
    @State private var showConnectionsList: Bool = false
    @State private var connectionsListTitle: String = "Connections"
    @State private var showInvitationsList: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Grow / Catch up tabs
            networkTabs

            ScrollView {
                if appState.selectedNetworkTab == .grow {
                    growContent
                } else {
                    catchUpContent
                }
            }
        }
        .background(LockedInTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showMyProfile = true
                } label: {
                    AvatarView(
                        name: appState.currentUser.fullName,
                        initials: appState.currentUser.avatarInitials,
                        topHex: appState.currentUser.avatarTopHex,
                        bottomHex: appState.currentUser.avatarBottomHex,
                        size: 30
                    )
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    appState.showMessaging = true
                }) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }
        }
        .sheet(item: $selectedConnection) { conn in
            ProfileView(connection: conn, isCurrentUser: false)
        }
        .sheet(isPresented: $showMyProfile) {
            ProfileMenuView()
        }
        .sheet(item: $catchUpProfileConnection) { conn in
            ProfileView(connection: conn, isCurrentUser: false)
        }
        .sheet(isPresented: $showInvitationsList) {
            NavigationStack {
                Group {
                    if appState.invitations.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 48))
                                .foregroundColor(LockedInTheme.tertiaryText)
                            Text("No pending invitations")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText)
                            Text("When people invite you to connect, their invitations will appear here.")
                                .font(.system(size: 14))
                                .foregroundColor(LockedInTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(appState.invitations) { invitation in
                                HStack(spacing: 12) {
                                    AvatarView(
                                        name: invitation.fullName,
                                        initials: invitation.avatarInitials,
                                        topHex: invitation.avatarTopHex,
                                        bottomHex: invitation.avatarBottomHex,
                                        size: 48
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(invitation.fullName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(LockedInTheme.primaryText)
                                        Text(invitation.headline)
                                            .font(.system(size: 12))
                                            .foregroundColor(LockedInTheme.secondaryText)
                                            .lineLimit(1)
                                        Text("\(invitation.mutualConnections) mutual connections")
                                            .font(.system(size: 12))
                                            .foregroundColor(LockedInTheme.secondaryText)
                                    }
                                    Spacer()
                                    HStack(spacing: 10) {
                                        Button {
                                            appState.declineInvitation(invitation.id)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 18))
                                                .foregroundColor(LockedInTheme.secondaryText)
                                                .frame(width: 32, height: 32)
                                                .overlay(Circle().stroke(LockedInTheme.separator, lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                        Button {
                                            appState.acceptInvitation(invitation.id)
                                        } label: {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 18))
                                                .foregroundColor(LockedInTheme.linkedInBlue)
                                                .frame(width: 32, height: 32)
                                                .overlay(Circle().stroke(LockedInTheme.linkedInBlue, lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Invitations (\(appState.invitations.count))")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showInvitationsList = false }
                    }
                }
            }
        }
        .alert("LockedIn Games", isPresented: $showGameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(selectedGameName) — Keep your mind sharp with daily puzzles! Games are not available in this version.")
        }
        .sheet(isPresented: $showConnectionsList) {
            NavigationStack {
                Group {
                    if connectionsListTitle == "Connections" || connectionsListTitle == "Contacts" || connectionsListTitle == "People I Follow" {
                        List(connectionsListTitle == "People I Follow" ? Array(appState.connections.filter { appState.followedAuthors.contains($0.id) || $0.isFollowing }) : Array(appState.connections)) { conn in
                            Button {
                                showConnectionsList = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    selectedConnection = conn
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
                    } else if connectionsListTitle == "Groups" {
                        let groupData: [(String, Int)] = [
                            ("iOS Developers Community", 42518),
                            ("SwiftUI Enthusiasts", 18203),
                            ("Tech Leadership Circle", 95417),
                            ("Bay Area Professionals", 31842)
                        ]
                        List {
                            ForEach(groupData, id: \.0) { group, members in
                                HStack(spacing: 12) {
                                    CompanyLogoView(initials: String(group.prefix(2)), topHex: "0x004182", bottomHex: "0x0077B5", size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(group).font(.system(size: 14, weight: .semibold))
                                        Text("\(members) members").font(.system(size: 12)).foregroundColor(LockedInTheme.secondaryText)
                                    }
                                }
                            }
                        }
                    } else if connectionsListTitle == "Events" {
                        List {
                            ForEach(["WWDC Watch Party", "Bay Area Tech Networking"], id: \.self) { event in
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar.circle.fill").font(.system(size: 32)).foregroundColor(LockedInTheme.linkedInBlue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event).font(.system(size: 14, weight: .semibold))
                                        Text("Upcoming").font(.system(size: 12)).foregroundColor(LockedInTheme.secondaryText)
                                    }
                                }
                            }
                        }
                    } else if connectionsListTitle == "Pages" {
                        let pageData: [(String, Int)] = [
                            ("Meridian Technologies", 12408),
                            ("Google Cloud", 5284119),
                            ("HashiCorp", 284762),
                            ("Docker Inc.", 418590)
                        ]
                        List {
                            ForEach(pageData, id: \.0) { page, followers in
                                HStack(spacing: 12) {
                                    CompanyLogoView(initials: String(page.prefix(2)), topHex: "0x045A5C", bottomHex: "0x0A7F77", size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(page).font(.system(size: 14, weight: .semibold))
                                        Text("\(followers) followers").font(.system(size: 12)).foregroundColor(LockedInTheme.secondaryText)
                                    }
                                }
                            }
                        }
                    } else if connectionsListTitle == "Newsletters" {
                        List {
                            ForEach(["The Platform Weekly", "Cloud Native Digest", "DevOps Insider", "Tech Hiring Trends", "AI & ML Spotlight", "Startup Pulse", "Engineering Leadership"], id: \.self) { newsletter in
                                HStack(spacing: 12) {
                                    Image(systemName: "newspaper.fill").font(.system(size: 24)).foregroundColor(LockedInTheme.linkedInBlue).frame(width: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(newsletter).font(.system(size: 14, weight: .semibold))
                                        Text("Weekly").font(.system(size: 12)).foregroundColor(LockedInTheme.secondaryText)
                                    }
                                }
                            }
                        }
                    } else {
                        List(appState.connections) { conn in
                            HStack(spacing: 12) {
                                AvatarView(name: conn.fullName,
                    initials: conn.avatarInitials, topHex: conn.avatarTopHex, bottomHex: conn.avatarBottomHex, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(conn.fullName).font(.system(size: 14, weight: .semibold))
                                    Text(conn.headline).font(.system(size: 12)).foregroundColor(LockedInTheme.secondaryText).lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(connectionsListTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showConnectionsList = false }
                    }
                }
            }
        }
    }

    // MARK: - Network Tabs

    private var networkTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(NetworkTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.selectedNetworkTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: appState.selectedNetworkTab == tab ? .bold : .regular))
                                .foregroundColor(appState.selectedNetworkTab == tab ? LockedInTheme.greenButton : LockedInTheme.secondaryText)

                            Rectangle()
                                .fill(appState.selectedNetworkTab == tab ? LockedInTheme.greenButton : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 8)
            .background(LockedInTheme.cardBackground)

            Divider()
        }
    }

    // MARK: - Grow Content

    private var growContent: some View {
        VStack(spacing: 8) {
            // Invitations section
            invitationsSection

            // Manage my network
            manageNetworkCard

            // LockedIn Games card
            if !hideGamesCard {
                linkedInGamesCard
            }

            // Premium upsell card
            if !hidePremiumCard {
                premiumUpsellCard
            }

            // People you may know
            peopleYouMayKnowSection

            // More suggestions as a list
            moreSuggestionsSection
        }
    }

    // MARK: - Invitations

    private var invitationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                showInvitationsList = true
            } label: {
                HStack {
                    Text("Invitations (\(appState.invitations.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .accessibilityIdentifier("network_invitations_header")

            ForEach(appState.invitations) { invitation in
                invitationRow(invitation)
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    private func connectionFromInvitation(_ invitation: ConnectionInvitation) -> Connection {
        Connection(
            id: invitation.id,
            firstName: invitation.firstName,
            lastName: invitation.lastName,
            headline: invitation.headline,
            avatarInitials: invitation.avatarInitials,
            avatarTopHex: invitation.avatarTopHex,
            avatarBottomHex: invitation.avatarBottomHex,
            degree: .first,
            mutualConnections: invitation.mutualConnections,
            isFollowing: invitation.isFollower,
            company: "",
            location: ""
        )
    }

    private func invitationRow(_ invitation: ConnectionInvitation) -> some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.leading, 76)

            HStack(alignment: .top, spacing: 12) {
                Button {
                    selectedConnection = connectionFromInvitation(invitation)
                } label: {
                    AvatarView(
                        name: invitation.fullName,
                    initials: invitation.avatarInitials,
                        topHex: invitation.avatarTopHex,
                        bottomHex: invitation.avatarBottomHex,
                        size: 48
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Button {
                            selectedConnection = connectionFromInvitation(invitation)
                        } label: {
                            Text(invitation.fullName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(LockedInTheme.primaryText)
                        }
                        .buttonStyle(.plain)

                        if invitation.isFollower {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                        }
                    }

                    if invitation.isFollower {
                        Text("follows you and is inviting you to connect")
                            .font(.system(size: 12))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }

                    Text(invitation.headline)
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .lineLimit(1)

                    Text("\(invitation.mutualConnections) mutual connections")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)

                    Text(invitation.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.tertiaryText)

                    if let note = invitation.note {
                        Text("\"\(note)\"")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(LockedInTheme.primaryText)
                            .italic()
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                if acceptedInvitations.contains(invitation.id) {
                    Text("Connected!")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(LockedInTheme.greenButton)
                        .transition(.opacity)
                } else {
                    HStack(spacing: 12) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            appState.declineInvitation(invitation.id)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(LockedInTheme.secondaryText)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(LockedInTheme.separator, lineWidth: 1)
                                )
                        }

                        Button {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            _ = withAnimation {
                                acceptedInvitations.insert(invitation.id)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                appState.acceptInvitation(invitation.id)
                                acceptedInvitations.remove(invitation.id)
                            }
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Manage Network

    private var manageNetworkCard: some View {
        VStack(spacing: 0) {
            Button {
                connectionsListTitle = "Connections"
                showConnectionsList = true
            } label: {
                HStack {
                    Text("Manage my network")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            Divider()

            // Network stats
            VStack(spacing: 0) {
                manageRow(icon: "person.2", label: "Connections", count: appState.currentUser.connectionCount) {
                    connectionsListTitle = "Connections"
                    showConnectionsList = true
                }
                manageRow(icon: "person.badge.plus", label: "Contacts", count: 184) {
                    connectionsListTitle = "Contacts"
                    showConnectionsList = true
                }
                manageRow(icon: "person.crop.rectangle", label: "People I Follow", count: 53) {
                    connectionsListTitle = "People I Follow"
                    showConnectionsList = true
                }
                manageRow(icon: "building.2", label: "Groups", count: 4) {
                    connectionsListTitle = "Groups"
                    showConnectionsList = true
                }
                manageRow(icon: "calendar", label: "Events", count: 2) {
                    connectionsListTitle = "Events"
                    showConnectionsList = true
                }
                manageRow(icon: "newspaper", label: "Pages", count: 31) {
                    connectionsListTitle = "Pages"
                    showConnectionsList = true
                }
                manageRow(icon: "bell", label: "Newsletters", count: 7) {
                    connectionsListTitle = "Newsletters"
                    showConnectionsList = true
                }
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    private func manageRow(icon: String, label: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(LockedInTheme.primaryText)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 14))
                    .foregroundColor(LockedInTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - LockedIn Games Card

    private var linkedInGamesCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "puzzlepiece.fill")
                            .font(.system(size: 16))
                            .foregroundColor(LockedInTheme.linkedInBlue)
                        Text("LockedIn Games")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(LockedInTheme.primaryText)
                    }

                    Text("Keep your mind sharp with daily puzzles")
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                }

                Spacer()

                Button(action: { withAnimation { hideGamesCard = true } }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Game tiles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    gameCard(name: "Tango", icon: "sun.max.fill", color: Color(hex: 0xFF6B35), description: "Harmony in every pair") {
                        selectedGameName = "Tango"; showGameAlert = true
                    }
                    gameCard(name: "Queens", icon: "crown.fill", color: Color(hex: 0x9B59B6), description: "Crown each region") {
                        selectedGameName = "Queens"; showGameAlert = true
                    }
                    gameCard(name: "Pinpoint", icon: "mappin.circle.fill", color: Color(hex: 0x3498DB), description: "Find the category") {
                        selectedGameName = "Pinpoint"; showGameAlert = true
                    }
                    gameCard(name: "Crossclimb", icon: "arrow.up.right", color: Color(hex: 0x2ECC71), description: "Climb the ladder") {
                        selectedGameName = "Crossclimb"; showGameAlert = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    private func gameCard(name: String, icon: String, color: Color, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 100, height: 80)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundColor(color)
                    }

                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 110)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Premium Upsell

    private var premiumUpsellCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 28))
                    .foregroundColor(LockedInTheme.premiumGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Grow your career faster with Premium")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)

                    Text("See who's viewed your profile, get AI-powered insights, and stand out to recruiters.")
                        .font(.system(size: 13))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .lineLimit(3)

                    Button(action: { withAnimation { hidePremiumCard = true } }) {
                        Text("Try for free")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(LockedInTheme.premiumGold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(LockedInTheme.premiumGold, lineWidth: 1)
                            )
                    }
                    .padding(.top, 4)
                }

                Spacer()

                Button(action: { withAnimation { hidePremiumCard = true } }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
            }
            .padding(16)
        }
        .background(LockedInTheme.cardBackground)
    }

    // MARK: - People You May Know

    private var peopleYouMayKnowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("People you may know")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(LockedInTheme.primaryText)
                .padding(.horizontal, 16)
                .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestedConnections.filter { !dismissedSuggestions.contains($0.id) }) { person in
                        suggestedPersonCard(person)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 14)
        }
        .background(LockedInTheme.cardBackground)
    }

    private var suggestedConnections: [Connection] {
        Array(appState.connections.filter { $0.degree == .second || $0.degree == .first }.prefix(8))
    }

    private func suggestedPersonCard(_ person: Connection) -> some View {
        VStack(spacing: 0) {
            // Banner background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hexString: person.avatarTopHex).opacity(0.3), Color(hexString: person.avatarBottomHex).opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 55)
                .overlay(alignment: .topTrailing) {
                    Button(action: { withAnimation { _ = dismissedSuggestions.insert(person.id) } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(LockedInTheme.secondaryText)
                            .padding(6)
                    }
                }
                .overlay(alignment: .bottom) {
                    AvatarView(
                        name: person.fullName,
                    initials: person.avatarInitials,
                        topHex: person.avatarTopHex,
                        bottomHex: person.avatarBottomHex,
                        size: 56,
                        showBorder: true
                    )
                    .offset(y: 28)
                }

            VStack(spacing: 4) {
                Text(person.fullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                    .lineLimit(1)

                Text(person.headline)
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if person.mutualConnections > 0 {
                    HStack(spacing: 4) {
                        HStack(spacing: -6) {
                            ForEach(0..<min(2, person.mutualConnections), id: \.self) { _ in
                                Circle()
                                    .fill(Color(hex: 0xDDDDDD))
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: 1)
                                    )
                            }
                        }
                        Text("\(person.mutualConnections) mutual")
                            .font(.system(size: 11))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }

                Spacer()

                if appState.sentConnectionRequests.contains(person.id) {
                    Text("Pending")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LockedInTheme.separator, lineWidth: 1)
                        )
                } else {
                    Button {
                        appState.sendConnectionRequest(person.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 12))
                            Text("Connect")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(LockedInTheme.linkedInBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 24)
            .padding(.bottom, 12)
        }
        .frame(width: 160, height: 260)
        .background(LockedInTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(LockedInTheme.separator, lineWidth: 1)
        )
        .onTapGesture {
            selectedConnection = person
        }
    }

    // MARK: - More Suggestions List

    private var moreSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("More suggestions for you")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(LockedInTheme.primaryText)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 4)

            Text("Based on your profile and search history")
                .font(.system(size: 13))
                .foregroundColor(LockedInTheme.secondaryText)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            ForEach(Array(appState.connections.suffix(4))) { person in
                moreSuggestionRow(person)
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    private func moreSuggestionRow(_ person: Connection) -> some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.leading, 76)

            HStack(alignment: .top, spacing: 12) {
                AvatarView(
                    name: person.fullName,
                    initials: person.avatarInitials,
                    topHex: person.avatarTopHex,
                    bottomHex: person.avatarBottomHex,
                    size: 48
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.fullName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.primaryText)
                    Text(person.headline)
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .lineLimit(1)
                    if person.mutualConnections > 0 {
                        Text("\(person.mutualConnections) mutual connections")
                            .font(.system(size: 12))
                            .foregroundColor(LockedInTheme.secondaryText)
                    }
                }

                Spacer()

                if appState.sentConnectionRequests.contains(person.id) {
                    Text("Pending")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LockedInTheme.separator, lineWidth: 1)
                        )
                } else {
                    Button {
                        appState.sendConnectionRequest(person.id)
                    } label: {
                        Text("Connect")
                            .font(.system(size: 14, weight: .semibold))
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedConnection = person
        }
    }

    // MARK: - Catch Up Content

    private var catchUpContent: some View {
        VStack(spacing: 8) {
            catchUpItemsSection
        }
    }

    private struct CatchUpItem: Identifiable {
        let id: String
        let type: CatchUpType
        let personName: String
        let personInitials: String
        let topHex: String
        let bottomHex: String
        let headline: String
        let detail: String
        let timeAgo: String
    }

    private enum CatchUpType {
        case birthday
        case workAnniversary
        case newPosition
        case promotion
    }

    private var catchUpItems: [CatchUpItem] {
        [
            CatchUpItem(id: "catchup_devon",
                type: .newPosition,
                personName: "Devon Hart",
                personInitials: "DH",
                topHex: "0x1A3C2D",
                bottomHex: "0x4DB882",
                headline: "Senior Product Manager at Meridian Technologies",
                detail: "Started a new position as Senior Product Manager at Meridian Technologies",
                timeAgo: "2d"
            ),
            CatchUpItem(id: "catchup_petra",
                type: .workAnniversary,
                personName: "Petra Johansson",
                personInitials: "PJ",
                topHex: "0x28143D",
                bottomHex: "0x9B5CC8",
                headline: "VP of Engineering at Luminos AI",
                detail: "Celebrating 4 years at Luminos AI",
                timeAgo: "3d"
            ),
            CatchUpItem(id: "catchup_kai",
                type: .birthday,
                personName: "Kai Santos",
                personInitials: "KS",
                topHex: "0x3A2811",
                bottomHex: "0xD4A34E",
                headline: "Design Lead at Meridian Technologies",
                detail: "Birthday today!",
                timeAgo: "Today"
            ),
            CatchUpItem(id: "catchup_lena",
                type: .promotion,
                personName: "Lena Park",
                personInitials: "LP",
                topHex: "0x1E3252",
                bottomHex: "0x5B9ECF",
                headline: "Staff Engineer at Meta",
                detail: "Got promoted to Staff Engineer",
                timeAgo: "5d"
            )
        ]
    }

    private func connectionFromCatchUpItem(_ item: CatchUpItem) -> Connection {
        let nameParts = item.personName.split(separator: " ")
        let firstName = nameParts.first.map(String.init) ?? item.personName
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        return Connection(
            id: item.id,
            firstName: firstName,
            lastName: lastName,
            headline: item.headline,
            avatarInitials: item.personInitials,
            avatarTopHex: item.topHex,
            avatarBottomHex: item.bottomHex,
            degree: .first,
            mutualConnections: 0,
            isFollowing: false,
            company: "",
            location: ""
        )
    }

    private var catchUpItemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(catchUpItems) { item in
                catchUpRow(item)
            }
        }
        .background(LockedInTheme.cardBackground)
    }

    private func catchUpRow(_ item: CatchUpItem) -> some View {
        VStack(spacing: 0) {
            if item.id != catchUpItems.first?.id {
                Divider()
                    .padding(.leading, 76)
            }

            HStack(alignment: .top, spacing: 12) {
                Button {
                    catchUpProfileConnection = connectionFromCatchUpItem(item)
                } label: {
                    AvatarView(
                        initials: item.personInitials,
                        topHex: item.topHex,
                        bottomHex: item.bottomHex,
                        size: 48
                    )
                    .overlay(alignment: .bottomTrailing) {
                        catchUpIcon(item.type)
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    (
                        Text(item.personName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(LockedInTheme.primaryText)
                        +
                        Text(" \(item.detail)")
                            .font(.system(size: 14))
                            .foregroundColor(LockedInTheme.primaryText)
                    )
                    .onTapGesture {
                        catchUpProfileConnection = connectionFromCatchUpItem(item)
                    }

                    Text(item.headline)
                        .font(.system(size: 12))
                        .foregroundColor(LockedInTheme.secondaryText)
                        .lineLimit(1)

                    if appState.congratsSent.contains(item.id) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(LockedInTheme.greenButton)
                            Text("Sent!")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(LockedInTheme.greenButton)
                        }
                        .padding(.top, 2)
                    } else {
                        Button {
                            appState.sendCongrats(item.id)
                        } label: {
                            Text("Say congrats")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(LockedInTheme.linkedInBlue)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(LockedInTheme.linkedInBlue, lineWidth: 1)
                                )
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()

                Text(item.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func catchUpIcon(_ type: CatchUpType) -> some View {
        let (icon, bgColor): (String, Color) = {
            switch type {
            case .birthday: return ("gift.fill", Color(hex: 0xFF6B35))
            case .workAnniversary: return ("star.fill", Color(hex: 0x9B59B6))
            case .newPosition: return ("briefcase.fill", LockedInTheme.linkedInBlue)
            case .promotion: return ("arrow.up.circle.fill", LockedInTheme.greenButton)
            }
        }()

        Image(systemName: icon)
            .font(.system(size: 8))
            .foregroundColor(.white)
            .padding(3)
            .background(Circle().fill(bgColor))
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .offset(x: 2, y: 2)
    }
}
