import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @State private var showProfileSheet = false

    init(store: WorkspaceStore) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TeamChatPalette.screen.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(alignment: .leading, spacing: TeamChatMetrics.sectionSpacing) {
                            searchComposer
                            typeFilters
                            optionsFilters

                            if viewModel.recentSearches.isEmpty == false {
                                recentSearches
                            }

                            resultsSection
                        }
                        .padding(.horizontal, TeamChatMetrics.pagePadding)
                        .padding(.top, TeamChatMetrics.pagePadding)
                        .padding(.bottom, TeamChatMetrics.pageBottomPadding)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(store: viewModel.store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text("Search")
                .font(.system(size: TeamChatMetrics.headerTitleSize, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("search_header_title")

            Spacer()

            Button {
                showProfileSheet = true
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: TeamChatMetrics.headerProfileIconSize))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("search_profile_button")
        }
        .padding(.horizontal, TeamChatMetrics.headerHorizontalPadding)
        .padding(.top, TeamChatMetrics.headerTopPadding)
        .padding(.bottom, TeamChatMetrics.headerBottomPadding)
        .background(TeamChatPalette.header)
    }

    private var searchComposer: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TeamChatPalette.subtleText)

            TextField("Search in Messages", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(.white)
                .onSubmit {
                    viewModel.commitSearch()
                }
                .accessibilityIdentifier("search_query_field")

            Button {
                viewModel.commitSearch()
            } label: {
                Text("Go")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(TeamChatPalette.avatarRing, in: Capsule())
            }
            .accessibilityIdentifier("search_submit_button")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius).fill(TeamChatPalette.row))
        .overlay(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius).strokeBorder(TeamChatPalette.divider, lineWidth: 1))
    }

    private var typeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                typeFilterButton(.all, label: "Recents")
                typeFilterButton(.messages, label: "Messages")
                typeFilterButton(.channels, label: "Channels")
                typeFilterButton(.people, label: "People")
            }
        }
        .accessibilityIdentifier("search_type_filter")
    }

    private func typeFilterButton(_ filter: SearchFilter, label: String) -> some View {
        Button {
            viewModel.filter = filter
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(viewModel.filter == filter ? .white : TeamChatPalette.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: TeamChatMetrics.chipCornerRadius)
                        .fill(viewModel.filter == filter ? TeamChatPalette.avatarRing : TeamChatPalette.row)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TeamChatMetrics.chipCornerRadius)
                        .strokeBorder(TeamChatPalette.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("search_type_\(filter.rawValue)")
    }

    private var optionsFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toggleChip(
                    title: "Mentions me",
                    isOn: viewModel.mentionsMeOnly,
                    id: "search_filter_mentions_me"
                ) {
                    viewModel.mentionsMeOnly.toggle()
                }
                toggleChip(
                    title: "Has link",
                    isOn: viewModel.hasLinkOnly,
                    id: "search_filter_has_link"
                ) {
                    viewModel.hasLinkOnly.toggle()
                }
                toggleChip(
                    title: "Has file",
                    isOn: viewModel.hasFileOnly,
                    id: "search_filter_has_file"
                ) {
                    viewModel.hasFileOnly.toggle()
                }
            }
        }
    }

    private func toggleChip(title: String, isOn: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isOn ? .white : TeamChatPalette.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(isOn ? TeamChatPalette.unreadBadge : TeamChatPalette.row))
                .overlay(Capsule().strokeBorder(TeamChatPalette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var recentSearches: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Searches")
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("recent_searches_title")

            ForEach(viewModel.recentSearches, id: \.self) { search in
                Button {
                    viewModel.useRecentSearch(search)
                    viewModel.commitSearch()
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(TeamChatPalette.subtleText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(search)
                                .foregroundStyle(.white)
                            Text("Search in Messages")
                                .font(.caption)
                                .foregroundStyle(TeamChatPalette.subtleText)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("recent_search_\(search.accessibilitySlug)")
            }
        }
        .padding(12)
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
    }

    @ViewBuilder
    private var resultsSection: some View {
        let results = viewModel.results

        if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sectionCard(title: "Results") {
                Text("Enter a query to search messages, channels, and people")
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .accessibilityIdentifier("search_empty_query_state")
            }
        } else if results.isEmpty {
            sectionCard(title: "Results") {
                Text("No search results")
                    .foregroundStyle(TeamChatPalette.subtleText)
                    .accessibilityIdentifier("search_no_results_state")
            }
        } else {
            let messageResults = results.filter { $0.type == .messages }
            let channelResults = results.filter { $0.type == .channels }
            let peopleResults = results.filter { $0.type == .people }

            if messageResults.isEmpty == false {
                sectionCard(title: "Messages") {
                    ForEach(messageResults) { result in
                        searchResultRow(result: result)
                        if result.id != messageResults.last?.id {
                            Divider().overlay(TeamChatPalette.divider)
                        }
                    }
                }
            }

            if channelResults.isEmpty == false {
                sectionCard(title: "Channels") {
                    ForEach(channelResults) { result in
                        searchResultRow(result: result)
                        if result.id != channelResults.last?.id {
                            Divider().overlay(TeamChatPalette.divider)
                        }
                    }
                }
            }

            if peopleResults.isEmpty == false {
                sectionCard(title: "People") {
                    ForEach(peopleResults) { result in
                        searchResultRow(result: result)
                        if result.id != peopleResults.last?.id {
                            Divider().overlay(TeamChatPalette.divider)
                        }
                    }
                }
            }
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            content()
        }
        .padding(12)
        .background(TeamChatPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: TeamChatMetrics.cardCornerRadius))
    }

    @ViewBuilder
    private func destinationView(for target: NavigationTarget) -> some View {
        switch target {
        case .channel(let channelId, let focusMessageId):
            ChannelDetailView(store: viewModel.store, channelId: channelId, focusMessageId: focusMessageId)
        case .dm(let dmId, let focusMessageId):
            DMDetailView(store: viewModel.store, dmId: dmId, focusMessageId: focusMessageId)
        case .member(let memberId):
            MemberDetailView(store: viewModel.store, memberId: memberId)
        }
    }

    @ViewBuilder
    private func searchResultRow(result: SearchResult) -> some View {
        if let target = viewModel.navigationTarget(for: result) {
            NavigationLink {
                destinationView(for: target)
            } label: {
                SearchResultCell(result: result)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("search_result_\(result.id.accessibilitySlug)")
        } else {
            SearchResultCell(result: result)
                .accessibilityIdentifier("search_result_\(result.id.accessibilitySlug)")
        }
    }
}

private struct SearchResultCell: View {
    let result: SearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconTint)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("search_result_icon_\(result.id.accessibilitySlug)")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("search_result_title_\(result.id.accessibilitySlug)")

                    Spacer()

                    if let timestamp = result.timestamp {
                        Text(DateFormatters.relative.localizedString(for: timestamp, relativeTo: Date()))
                            .font(.caption)
                            .foregroundStyle(TeamChatPalette.subtleText)
                            .accessibilityIdentifier("search_result_timestamp_\(result.id.accessibilitySlug)")
                    }
                }

                Text(result.searchSnippet)
                    .font(.subheadline)
                    .foregroundStyle(TeamChatPalette.secondaryText)
                    .lineLimit(2)
                    .accessibilityIdentifier("search_result_snippet_\(result.id.accessibilitySlug)")

                HStack {
                    Text(result.contextName)
                        .font(.caption)
                        .foregroundStyle(TeamChatPalette.subtleText)
                        .accessibilityIdentifier("search_result_context_\(result.id.accessibilitySlug)")

                    if result.isUnread {
                        Text("Unread")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(TeamChatPalette.unreadBadge, in: Capsule())
                            .accessibilityIdentifier("search_result_unread_badge_\(result.id.accessibilitySlug)")
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var iconName: String {
        switch result.type {
        case .messages:
            return "text.bubble"
        case .channels:
            return "number"
        case .people:
            return "person.fill"
        }
    }

    private var iconTint: Color {
        switch result.type {
        case .messages:
            return TeamChatPalette.avatarRing
        case .channels:
            return Color(red: 0.19, green: 0.46, blue: 0.54)
        case .people:
            return Color(red: 0.45, green: 0.33, blue: 0.21)
        }
    }
}
