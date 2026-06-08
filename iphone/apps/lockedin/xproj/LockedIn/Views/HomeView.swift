import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showMyProfile: Bool = false
    @State private var dismissedSuggestions: Set<String> = []
    @State private var selectedConnection: Connection?
    @State private var connectingIds: Set<String> = []

    private var suggestedForYouConnections: [Connection] {
        Array(appState.connections.filter {
            ($0.degree == .second || $0.degree == .third) &&
            !dismissedSuggestions.contains($0.id) &&
            !appState.sentConnectionRequests.contains($0.id)
        }.prefix(6))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(appState.posts.enumerated()), id: \.element.id) { index, post in
                    PostCardView(post: post)
                    if index == 4 && !suggestedForYouConnections.isEmpty {
                        suggestedForYouSection
                    }
                }
            }
        }
        .refreshable {
            try? await Task.sleep(nanoseconds: 800_000_000)
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
                .accessibilityIdentifier("home_profile_avatar")
            }
            ToolbarItem(placement: .principal) {
                Button {
                    appState.showSearch = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(LockedInTheme.secondaryText)
                            .font(.system(size: 14))
                        Text("Search")
                            .font(.system(size: 15))
                            .foregroundColor(LockedInTheme.secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xEDF3F8))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .accessibilityIdentifier("home_search_bar")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    appState.showMessaging = true
                } label: {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                        .foregroundColor(LockedInTheme.secondaryText)
                }
                .accessibilityIdentifier("home_messaging_button")
            }
        }
        .sheet(isPresented: $showMyProfile) {
            ProfileMenuView()
        }
        .sheet(item: $selectedConnection) { conn in
            ProfileView(connection: conn, isCurrentUser: false)
        }
    }

    // MARK: - Suggested For You Section

    private var suggestedForYouSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Suggested for you")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(LockedInTheme.primaryText)
                Text("Based on your profile")
                    .font(.system(size: 13))
                    .foregroundColor(LockedInTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestedForYouConnections) { person in
                        suggestedPersonCard(person)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 14)
        }
        .background(LockedInTheme.cardBackground)
    }

    private func suggestedPersonCard(_ person: Connection) -> some View {
        VStack(spacing: 0) {
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
                    .padding(.top, 4)

                Text(person.headline)
                    .font(.system(size: 12))
                    .foregroundColor(LockedInTheme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

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

                connectButton(for: person)
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
        .contentShape(Rectangle())
        .onTapGesture {
            selectedConnection = person
        }
    }

    @ViewBuilder
    private func connectButton(for person: Connection) -> some View {
        if connectingIds.contains(person.id) {
            // Sending animation state
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(LockedInTheme.linkedInBlue)
                Text("Sending...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(LockedInTheme.linkedInBlue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LockedInTheme.linkedInBlue.opacity(0.5), lineWidth: 1)
            )
            .transition(.opacity)
        } else if appState.sentConnectionRequests.contains(person.id) {
            // Pending state
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                Text("Pending")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(LockedInTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LockedInTheme.separator, lineWidth: 1)
            )
            .transition(.opacity)
        } else {
            // Connect button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = connectingIds.insert(person.id)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    appState.sendConnectionRequest(person.id)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = connectingIds.remove(person.id)
                    }
                }
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
            .transition(.opacity)
        }
    }
}
