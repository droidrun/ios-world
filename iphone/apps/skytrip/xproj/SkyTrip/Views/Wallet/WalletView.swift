import SwiftUI

struct WalletView: View {
    @ObservedObject var viewModel: WalletViewModel

    @State private var showNotifications = false
    @State private var selectedInfoItem: AppInfoSheetItem?

    private var headerTitle: String {
        switch viewModel.walletTabSection {
        case .skymiles: return "SkyMiles"
        case .wallet: return "My Wallet"
        case .profile: return "Profile"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch viewModel.walletTabSection {
                        case .skymiles:
                            skyMilesContent
                        case .wallet:
                            walletContent
                        case .profile:
                            profileContent
                        }
                    }
                    .padding(.bottom, 24)
                }
                .background(SkyTripTheme.surface)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showNotifications) {
                AlertsCenterView(alerts: viewModel.store.alerts)
            }
            .sheet(item: $selectedInfoItem) { item in
                AppInfoSheetView(item: item)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Text(headerTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showNotifications = true
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("wallet_notifications_button")
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)

            HStack(spacing: 0) {
                ForEach(WalletTabSection.allCases) { item in
                    Button {
                        viewModel.walletTabSection = item
                    } label: {
                        VStack(spacing: 8) {
                            Text(segmentTitle(for: item))
                                .font(.system(size: 13, weight: viewModel.walletTabSection == item ? .bold : .medium))
                                .foregroundStyle(viewModel.walletTabSection == item ? .white : Color.white.opacity(0.45))
                            Rectangle()
                                .fill(viewModel.walletTabSection == item ? Color.white : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(accountSegmentIdentifier(for: item))
                }
            }
            .padding(.horizontal, 16)
        }
        .background(SkyTripTheme.navy)
    }

    private var skyMilesContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            skyMilesHero

            VStack(alignment: .leading, spacing: 14) {
                statusProgressCard
                accountHighlightsCard
            }
            .padding(14)
        }
    }

    private var skyMilesHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.userProfile.fullName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("wallet_skymiles_name_label")

            HStack(spacing: 8) {
                Text(viewModel.skyMilesAccount.medallionLevel)
                    .font(.system(size: 14, weight: .semibold))
                Text("·")
                Text("#\(viewModel.skyMilesAccount.memberNumber)")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.85))
            .accessibilityIdentifier("wallet_skymiles_status_label")

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Miles")
                        .font(.system(size: 14, weight: .medium))
                    Text("Available")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.85))

                Text("\(viewModel.skyMilesAccount.redeemableMiles)")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .accessibilityIdentifier("wallet_skymiles_miles_available")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(red: 57 / 255, green: 74 / 255, blue: 147 / 255), SkyTripTheme.navyLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                GeometryReader { proxy in
                    let width = proxy.size.width
                    let pattern = Array(0..<8)
                    VStack(spacing: 0) {
                        ForEach(pattern, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(pattern, id: \.self) { column in
                                    TriangleTile(isFilled: (row + column).isMultiple(of: 2))
                                        .fill(Color.white.opacity((row + column).isMultiple(of: 3) ? 0.12 : 0.04))
                                }
                            }
                        }
                    }
                    .frame(width: width * 0.38, height: width * 0.38)
                    .position(x: width * 0.84, y: width * 0.24)
                }
                .allowsHitTesting(false)
            }
        )
        .accessibilityIdentifier("wallet_skymiles_hero_card")
    }

    private var statusProgressCard: some View {
        let currentMQDs = viewModel.skyMilesAccount.mqds
        let nextThreshold = 15_000
        let remaining = max(0, nextThreshold - currentMQDs)

        return VStack(alignment: .leading, spacing: 14) {
            Text("2026 STATUS PROGRESS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("wallet_status_progress_title")

            Text(viewModel.skyMilesAccount.medallionLevel)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(SkyTripTheme.navy)
                .accessibilityIdentifier("wallet_status_progress_level")

            SemiCircleProgressView(
                progress: min(Double(currentMQDs) / Double(nextThreshold), 1),
                currentValue: currentMQDs
            )
                .frame(height: 210)
                .accessibilityIdentifier("wallet_status_progress_gauge")

            HStack {
                Text("$0")
                Spacer()
                Text("$15K")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(SkyTripTheme.textSecondary)
            .padding(.horizontal, 18)

            Text("$\(remaining.formatted()) MQDs to Platinum Medallion")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SkyTripTheme.navy)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("wallet_status_progress_remaining")

            Divider()

            HStack(spacing: 18) {
                legendDot(color: SkyTripTheme.navy, label: "Earned")
                legendDot(color: Color(red: 147 / 255, green: 154 / 255, blue: 189 / 255), label: "Pending")
            }

            Text("Earn Status for the following year from Jan 1 to Dec 31.")
                .font(.system(size: 13))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .accessibilityIdentifier("wallet_status_progress_caption")

            Button("How Do I Reach Status?") {
                selectedInfoItem = AppInfoSheetItem(
                    id: "wallet_status_guide",
                    title: "How Status Works",
                    message: "Earn Medallion Status by accumulating Medallion Qualification Dollars (MQDs) through flights and eligible spending. Premium cabin bookings and higher annual MQDs move your progress toward the next tier. Silver requires $5,000 MQDs, Gold $10,000, Platinum $15,000, and Diamond $20,000."
                )
            }
                .font(.system(size: 15, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(Color.blue)
                .accessibilityIdentifier("wallet_status_progress_help_button")
        }
        .padding(16)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SkyTripTheme.textSecondary)
        }
    }

    private var accountHighlightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACCOUNT HIGHLIGHTS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("wallet_account_highlights_title")

            HStack {
                highlightMetric(title: "Home Airport", value: viewModel.userProfile.homeAirportCode, id: "wallet_account_home_airport")
                highlightMetric(title: "Upcoming Trips", value: "\(viewModel.savedTrips.count)", id: "wallet_account_upcoming_trips")
            }

            HStack {
                highlightMetric(title: "Boarding Passes", value: "\(viewModel.boardingPasses.count)", id: "wallet_account_boarding_passes")
                highlightMetric(title: "Email", value: viewModel.userProfile.email, id: "wallet_account_email")
            }
        }
        .padding(16)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func highlightMetric(title: String, value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SkyTripTheme.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier(id)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var walletContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            boardingPassesSection
            savedTripsSection
            placeholdersSection
        }
        .padding(16)
    }

    private var profileContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileSummaryView(profile: viewModel.userProfile, account: viewModel.skyMilesAccount)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 0) {
                profileRow("Email", value: viewModel.userProfile.email, id: "wallet_profile_email_row")
                Divider().padding(.leading, 14)
                profileRow("Home Airport", value: viewModel.userProfile.homeAirportCode, id: "wallet_profile_home_airport_row")
                Divider().padding(.leading, 14)
                profileRow("SkyMiles Number", value: viewModel.skyMilesAccount.memberNumber, id: "wallet_profile_skymiles_row")
            }
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 0) {
                profileActionButton(
                    "Saved Travelers",
                    id: "wallet_profile_saved_travelers_row",
                    message: "Manage your saved traveler profiles to speed up future bookings. Add names, Known Traveler Numbers, and redress numbers for frequent companions."
                )
                Divider().padding(.leading, 14)
                profileActionButton(
                    "Payment Methods",
                    id: "wallet_profile_payment_methods_row",
                    message: "Manage your saved credit and debit cards for faster checkout. SkyTrip SkyMiles Card Members enjoy priority boarding, free checked bags, and accelerated miles earning."
                )
                Divider().padding(.leading, 14)
                profileActionButton(
                    "Travel Preferences",
                    id: "wallet_profile_travel_preferences_row",
                    message: "Set your preferred seat type, meal preferences, and special assistance needs. These preferences will be applied automatically when booking future flights."
                )
            }
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private func profileRow(_ title: String, value: String, id: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(SkyTripTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .accessibilityIdentifier(id)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
    }

    private func profileActionButton(_ title: String, id: String, message: String) -> some View {
        Button {
            selectedInfoItem = AppInfoSheetItem(
                id: id,
                title: title,
                message: message
            )
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var boardingPassesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BOARDING PASSES")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("wallet_boarding_passes_title")

            if viewModel.boardingPasses.isEmpty {
                Text("No boarding passes")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityIdentifier("wallet_no_boarding_passes_state")
            } else {
                ForEach(viewModel.boardingPasses) { pass in
                    NavigationLink {
                        BoardingPassDetailView(boardingPass: pass)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Text(pass.route.components(separatedBy: " → ").first ?? "---")
                                        .font(.system(size: 16, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(SkyTripTheme.textSecondary)
                                    Text(pass.route.components(separatedBy: " → ").last ?? "---")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundStyle(SkyTripTheme.textPrimary)
                                .accessibilityIdentifier("wallet_boarding_pass_route_\(pass.id)")
                                Spacer()
                                Text(pass.flightNumber)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(SkyTripTheme.surface)
                                    .clipShape(Capsule())
                            }

                            HStack {
                                passMeta(label: "Seat", value: pass.seat)
                                passMeta(label: "Group", value: pass.boardingGroup)
                                passMeta(label: "Board", value: AppFormatters.time(pass.boardingTime))
                            }
                            .accessibilityIdentifier("wallet_boarding_pass_meta_\(pass.id)")

                            Text(AppFormatters.full(pass.date))
                                .font(.system(size: 12))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                                .accessibilityIdentifier("wallet_boarding_pass_date_\(pass.id)")
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SkyTripTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("wallet_boarding_pass_row_\(pass.flightNumber)")
                }
            }
        }
    }

    private func passMeta(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var savedTripsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SAVED TRIPS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .tracking(1)
                .accessibilityIdentifier("wallet_saved_trips_title")

            if viewModel.savedTrips.isEmpty {
                Text("No upcoming trips")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                ForEach(viewModel.savedTrips) { trip in
                    NavigationLink {
                        WalletTripDetailView(trip: trip, store: viewModel.store)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(trip.outboundSegments.first?.origin.code ?? "---")
                                        .font(.system(size: 14, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(SkyTripTheme.textSecondary)
                                    Text(trip.outboundSegments.last?.destination.code ?? "---")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundStyle(SkyTripTheme.textPrimary)
                                .accessibilityIdentifier("wallet_saved_trip_route_\(trip.id)")
                                Text(trip.primaryFlightNumber)
                                    .font(.system(size: 12))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                            }
                            Spacer()
                            Text(trip.confirmationCode)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                                .accessibilityIdentifier("wallet_saved_trip_confirmation_\(trip.id)")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        .padding(12)
                        .background(SkyTripTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("wallet_saved_trip_row_\(trip.id)")
                }
            }
        }
    }

    private var placeholdersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("TRAVEL CREDITS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                    .accessibilityIdentifier("wallet_travel_credits_title")

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("$247.50")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(SkyTripTheme.navy)
                                .accessibilityIdentifier("wallet_travel_credit_amount")
                            Text("eCredit")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Expires Dec 31, 2026")
                                .font(.system(size: 12))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                                .accessibilityIdentifier("wallet_travel_credit_expiry")
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text("From canceled flight DL 1847 ATL-SFO on Jan 15, 2026")
                            .font(.system(size: 12))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .accessibilityIdentifier("wallet_travel_credit_origin")
                    }

                    Button {
                        viewModel.store.selectedTab = .search
                    } label: {
                        Text("Use Credit")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(SkyTripTheme.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("wallet_travel_credit_use_button")
                }
                .padding(14)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("VOUCHERS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                    .accessibilityIdentifier("wallet_vouchers_title")

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("$15.00")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(SkyTripTheme.navy)
                                .accessibilityIdentifier("wallet_voucher_amount")
                            Text("Meal Voucher")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        Spacer()
                        Text("Expires Apr 30, 2026")
                            .font(.system(size: 12))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .accessibilityIdentifier("wallet_voucher_expiry")
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text("Issued for 3-hour delay on DL 2294 JFK-ATL, Feb 8, 2026")
                            .font(.system(size: 12))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .accessibilityIdentifier("wallet_voucher_origin")
                    }

                    Text("Valid at any airport restaurant or concession. Non-transferable. No cash value.")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyTripTheme.textSecondary.opacity(0.7))
                        .accessibilityIdentifier("wallet_voucher_terms")
                }
                .padding(14)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func accountSegmentIdentifier(for item: WalletTabSection) -> String {
        switch item {
        case .skymiles:
            return "wallet_segment_skymiles"
        case .wallet:
            return "wallet_segment_my_wallet"
        case .profile:
            return "wallet_segment_profile"
        }
    }

    private func segmentTitle(for item: WalletTabSection) -> String {
        switch item {
        case .skymiles:
            return "SKYMILES"
        case .wallet:
            return "MY WALLET"
        case .profile:
            return "PROFILE"
        }
    }
}

private struct SemiCircleProgressView: View {
    let progress: Double
    let currentValue: Int

    var body: some View {
        ZStack {
            ArcShape()
                .stroke(Color(red: 202 / 255, green: 207 / 255, blue: 225 / 255), style: StrokeStyle(lineWidth: 18, lineCap: .round))

            ArcShape()
                .trim(from: 0, to: progress)
                .stroke(Color(red: 118 / 255, green: 126 / 255, blue: 163 / 255), style: StrokeStyle(lineWidth: 18, lineCap: .round))

            VStack(spacing: 4) {
                Text("$\(currentValue.formatted())")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(SkyTripTheme.navy)
                Text("MQDs")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textSecondary)
            }
            .offset(y: 8)
        }
    }
}

private struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height)
        path.addArc(
            center: center,
            radius: radius - 16,
            startAngle: .degrees(200),
            endAngle: .degrees(-20),
            clockwise: false
        )
        return path
    }
}

private struct TriangleTile: Shape {
    let isFilled: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isFilled {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

private struct BoardingPassDetailView: View {
    let boardingPass: BoardingPass

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("BOARDING PASS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .tracking(1)
                            .accessibilityIdentifier("boarding_pass_title")
                        Spacer()
                        Text(boardingPass.flightNumber)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Text(boardingPass.passengerName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("boarding_pass_passenger_name")

                    HStack {
                        routeColumn(title: "From", value: boardingPass.route.components(separatedBy: " → ").first ?? "---")
                        Spacer()
                        Image(systemName: "airplane")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        routeColumn(title: "To", value: boardingPass.route.components(separatedBy: " → ").last ?? "---")
                    }
                    .accessibilityIdentifier("boarding_pass_route")
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [SkyTripTheme.navyLight, SkyTripTheme.navy],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    statRow(label: "Date", value: AppFormatters.date(boardingPass.date), id: "boarding_pass_date")
                    statRow(label: "Boarding", value: AppFormatters.time(boardingPass.boardingTime), id: "boarding_pass_boarding_time")
                    statRow(label: "Gate", value: boardingPass.gate, id: "boarding_pass_gate")
                    statRow(label: "Seat", value: boardingPass.seat, id: "boarding_pass_seat")
                    statRow(label: "Group", value: boardingPass.boardingGroup, id: "boarding_pass_group")

                    VStack(spacing: 8) {
                        let seed = boardingPass.passengerName.hashValue ^ boardingPass.flightNumber.hashValue
                        QRPatternView(seed: seed)
                            .frame(width: 120, height: 120)
                            .accessibilityIdentifier("boarding_pass_qr_code")
                        Text("Scan at gate")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("boarding_pass_qr_block")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(16)
        }
        .background(SkyTripTheme.surface)
        .navigationTitle(boardingPass.flightNumber)
    }

    private func routeColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func statRow(label: String, value: String, id: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .accessibilityIdentifier(id)
        }
    }
}

private struct WalletTripDetailView: View {
    let trip: Trip
    @ObservedObject var store: AppStore

    @State private var showCheckIn = false
    @State private var showSeatSelection = false

    var boardingPass: BoardingPass? {
        store.boardingPass(for: trip.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Route header
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text(trip.outboundSegments.first?.origin.code ?? "---")
                            .font(.system(size: 30, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text(trip.outboundSegments.last?.destination.code ?? "---")
                            .font(.system(size: 30, weight: .bold))
                    }
                    .foregroundStyle(SkyTripTheme.textPrimary)
                    .accessibilityIdentifier("wallet_trip_detail_route")
                    Text("Confirmation: \(trip.confirmationCode)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SkyTripTheme.red)
                        .accessibilityIdentifier("wallet_trip_detail_confirmation")
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Status card
                HStack(spacing: 16) {
                    statusPill(label: "Status", value: trip.operationalStatus.displayName, id: "wallet_trip_detail_status")
                    statusPill(label: "Seat", value: trip.seatAssignment ?? "TBD", id: "wallet_trip_detail_seat")
                    statusPill(label: "Group", value: trip.boardingGroup, id: "wallet_trip_detail_group")
                    statusPill(label: "Cost", value: AppFormatters.currency(trip.totalPrice, code: trip.currency), id: "wallet_trip_detail_cost")
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Segments
                VStack(alignment: .leading, spacing: 10) {
                    Text("OUTBOUND")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .tracking(1)
                    ForEach(trip.outboundSegments) { segment in
                        segmentRow(segment)
                    }
                    if trip.tripType == .roundTrip && !trip.returnSegments.isEmpty {
                        Text("RETURN")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                            .tracking(1)
                            .padding(.top, 4)
                        ForEach(trip.returnSegments) { segment in
                            segmentRow(segment)
                        }
                    }
                }
                .padding(14)
                .background(SkyTripTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityIdentifier("wallet_trip_detail_segments")

                // Actions
                VStack(spacing: 10) {
                    if trip.checkedIn {
                        NavigationLink {
                            if let pass = boardingPass {
                                BoardingPassDetailView(boardingPass: pass)
                            }
                        } label: {
                            Text("View Boarding Pass")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SkyTripTheme.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("wallet_trip_detail_boarding_pass_button")
                    } else if trip.checkInEligible {
                        Button {
                            showCheckIn = true
                        } label: {
                            Text("Check In")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SkyTripTheme.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("wallet_trip_detail_checkin_button")
                    }

                    Button {
                        showSeatSelection = true
                    } label: {
                        Text("Change Seat")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(SkyTripTheme.navy, lineWidth: 1.5)
                            )
                            .foregroundStyle(SkyTripTheme.navy)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("wallet_trip_detail_seat_button")
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(SkyTripTheme.surface)
        .navigationTitle("Trip Detail")
        .sheet(isPresented: $showCheckIn) {
            CheckInFlowView(store: store, preselectedTripID: trip.id)
        }
        .sheet(isPresented: $showSeatSelection) {
            SeatSelectionView(store: store, tripID: trip.id)
        }
    }

    private func statusPill(label: String, value: String, id: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SkyTripTheme.textSecondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SkyTripTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier(id)
        }
        .frame(maxWidth: .infinity)
    }

    private func segmentRow(_ segment: FlightSegment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(segment.carrierCode)\(segment.flightNumber)")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(SkyTripTheme.navy)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                Spacer()
                Text(segment.status.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(StatusBadgeStyle.color(for: segment.status))
                    .foregroundStyle(StatusBadgeStyle.textColor(for: segment.status))
                    .clipShape(Capsule())
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppFormatters.time(segment.departureTime))
                        .font(.system(size: 16, weight: .bold))
                    Text(segment.origin.code)
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text("Gate \(segment.gate)")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(AppFormatters.time(segment.arrivalTime))
                        .font(.system(size: 16, weight: .bold))
                    Text(segment.destination.code)
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
            }
        }
        .padding(12)
        .background(SkyTripTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - QR Pattern View

private struct QRPatternView: View {
    let seed: Int
    private let gridSize = 21

    var body: some View {
        Canvas { context, size in
            let cellSize = size.width / CGFloat(gridSize)
            let grid = generatePattern()

            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    if grid[row][col] {
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )
                        context.fill(Path(rect), with: .color(.black))
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func generatePattern() -> [[Bool]] {
        var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        // Draw finder patterns (7x7 squares in three corners)
        drawFinderPattern(&grid, row: 0, col: 0)
        drawFinderPattern(&grid, row: 0, col: gridSize - 7)
        drawFinderPattern(&grid, row: gridSize - 7, col: 0)

        // Timing patterns (alternating row/col between finders)
        for i in 8..<(gridSize - 8) {
            grid[6][i] = i.isMultiple(of: 2)
            grid[i][6] = i.isMultiple(of: 2)
        }

        // Separator (quiet zone around finders is already false)

        // Fill data area with seeded pseudo-random pattern
        var rng = seed
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if isFinderOrTimingZone(row: row, col: col) { continue }
                rng = nextRandom(rng)
                grid[row][col] = (rng & 0x1) == 1
            }
        }

        return grid
    }

    private func drawFinderPattern(_ grid: inout [[Bool]], row: Int, col: Int) {
        // Outer 7x7 border
        for i in 0..<7 {
            for j in 0..<7 {
                let isEdge = i == 0 || i == 6 || j == 0 || j == 6
                let isInner = (i >= 2 && i <= 4) && (j >= 2 && j <= 4)
                grid[row + i][col + j] = isEdge || isInner
            }
        }
    }

    private func isFinderOrTimingZone(row: Int, col: Int) -> Bool {
        // Top-left finder + separator
        if row <= 7 && col <= 7 { return true }
        // Top-right finder + separator
        if row <= 7 && col >= gridSize - 8 { return true }
        // Bottom-left finder + separator
        if row >= gridSize - 8 && col <= 7 { return true }
        // Timing patterns
        if row == 6 || col == 6 { return true }
        return false
    }

    private func nextRandom(_ current: Int) -> Int {
        var x = current
        x = x &+ (x &<< 13)
        x = x ^ (x >> 7)
        x = x &+ (x &<< 17)
        return x
    }
}
