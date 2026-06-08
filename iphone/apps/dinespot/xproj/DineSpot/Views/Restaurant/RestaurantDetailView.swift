import SwiftUI

/// Thin Identifiable wrapper so a plain String can drive a `.sheet(item:)`.
private struct SelectedMenuItem: Identifiable {
    let id: String  // the item name itself
}

struct RestaurantDetailView: View {
    enum DetailSection: String, CaseIterable, Identifiable {
        case reservations
        case experiences
        case reviews
        case concierge
        case menu

        var id: String { rawValue }

        var title: String {
            switch self {
            case .reservations: return "Reservations"
            case .experiences: return "Experiences"
            case .reviews: return "Reviews"
            case .concierge: return "Concierge"
            case .menu: return "Menu"
            }
        }
    }

    @EnvironmentObject private var store: DiningStore
    @Environment(\.dismiss) private var dismiss

    let restaurantID: String
    var initialDate: Date? = nil
    var initialTime: Date? = nil
    var initialPartySize: Int = 2

    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var partySize: Int = 2
    @State private var selectedSection: DetailSection = .reservations
    @State private var selectedSlot: ReservationSlot?
    @State private var pendingSlotFromFullAvailability: ReservationSlot?
    @State private var showFullAvailability = false
    @State private var showPhotosSheet = false
    @State private var showDateSheet = false
    @State private var showTimeSheet = false
    @State private var waitlistRequestType: WaitlistRequestType?
    @State private var selectedPhotoIndex = 0
    @State private var statusMessage: String?
    @State private var selectedMenuItem: SelectedMenuItem?

    private var restaurant: Restaurant? {
        store.restaurant(for: restaurantID)
    }

    private var neighborhoodName: String {
        guard let restaurant else { return "" }
        return store.neighborhood(for: restaurant.neighborhoodID)?.name ?? ""
    }

    private var photoSeeds: [RestaurantPhotoSeed] {
        guard let restaurant else { return [] }
        return SeedData.photoSeeds(for: restaurant)
    }

    private var selectedDateTime: Date {
        let calendar = Calendar.current
        let day = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let time = calendar.dateComponents([.hour, .minute], from: selectedTime)
        var merged = DateComponents()
        merged.year = day.year
        merged.month = day.month
        merged.day = day.day
        merged.hour = time.hour
        merged.minute = time.minute
        return calendar.date(from: merged) ?? selectedDate
    }

    private var selectedDateLabel: String {
        Calendar.current.isDateInToday(selectedDate)
            ? "Tonight"
            : DateFormatters.weekdayDate.string(from: selectedDate)
    }

    private var daySlots: [ReservationSlot] {
        let slots = store.availableSlots(for: restaurantID, date: selectedDate, partySize: partySize)
        let nearTarget = slots.filter { $0.date >= selectedDateTime.addingTimeInterval(-60 * 30) }
        if !nearTarget.isEmpty {
            return nearTarget
        }
        return slots
    }

    private var allFutureSlots: [ReservationSlot] {
        store.allFutureSlots(for: restaurantID, partySize: partySize)
    }

    var body: some View {
        Group {
            if let restaurant {
                ZStack {
                    DiningTheme.background.ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            hero(restaurant: restaurant)
                            infoPanel(restaurant: restaurant)
                            popularDishesSection(restaurant: restaurant)
                            sectionTabs
                            tabContent(restaurant: restaurant)
                        }
                        .padding(.bottom, 20)
                    }
                    // Booking-review sheet is attached to the ScrollView (its own
                    // view node) rather than stacked with the other 5 sheets on the
                    // ZStack below. SwiftUI only reliably presents ONE sheet per
                    // view; when `.sheet(item: $selectedSlot)` shared the stack it
                    // was shadowed by the later sheets and tapping a reservation
                    // slot silently no-op'd. Isolating it here makes the booking
                    // review present reliably.
                    .sheet(item: $selectedSlot) { slot in
                        BookingReviewView(
                            restaurant: restaurant,
                            slot: slot,
                            partySize: partySize
                        )
                        .environmentObject(store)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .accessibilityIdentifier("restaurant_detail_screen_\(restaurant.id)")
                .sheet(isPresented: $showFullAvailability) {
                    fullAvailabilitySheet(restaurant: restaurant)
                }
                .sheet(isPresented: $showPhotosSheet) {
                    photosSheet(restaurant: restaurant)
                }
                .sheet(isPresented: $showDateSheet) {
                    NavigationStack {
                        VStack(spacing: 16) {
                            DatePicker(
                                "Reservation Date",
                                selection: $selectedDate,
                                in: Date()...SeedData.makeDate(daysFromNow: 30, hour: 23),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .accessibilityIdentifier("restaurant_date_picker")

                            Button("Done") {
                                showDateSheet = false
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(DiningTheme.accentRed)
                        }
                        .padding()
                        .navigationTitle("Select Date")
                    }
                    .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showTimeSheet) {
                    NavigationStack {
                        VStack(spacing: 16) {
                            DatePicker(
                                "Reservation Time",
                                selection: $selectedTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .accessibilityIdentifier("restaurant_time_picker")

                            Button("Done") {
                                showTimeSheet = false
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(DiningTheme.accentRed)
                        }
                        .padding()
                        .navigationTitle("Select Time")
                    }
                    .presentationDetents([.medium])
                }
                .sheet(item: $waitlistRequestType) { requestType in
                    WaitlistRequestView(
                        restaurant: restaurant,
                        selectedDate: selectedDate,
                        partySize: partySize,
                        requestType: requestType
                    )
                    .environmentObject(store)
                }
                .onAppear {
                    selectedDate = initialDate ?? Date()
                    selectedTime = initialTime ?? SeedData.makeDate(daysFromNow: 0, hour: 19)
                    partySize = initialPartySize
                }
                .onChange(of: showFullAvailability) { _, isPresented in
                    guard !isPresented, let pending = pendingSlotFromFullAvailability else { return }
                    pendingSlotFromFullAvailability = nil
                    DispatchQueue.main.async {
                        selectedSlot = pending
                    }
                }
                .alert("Update", isPresented: Binding(
                    get: { statusMessage != nil },
                    set: { newValue in if !newValue { statusMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { statusMessage = nil }
                        .accessibilityIdentifier("restaurant_status_alert_ok")
                } message: {
                    Text(statusMessage ?? "")
                }
            } else {
                ContentUnavailableView(
                    "Restaurant unavailable",
                    systemImage: "fork.knife.circle",
                    description: Text("The selected restaurant could not be loaded.")
                )
                .accessibilityIdentifier("restaurant_detail_missing_state")
            }
        }
    }

    private func hero(restaurant: Restaurant) -> some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedPhotoIndex) {
                ForEach(Array(photoSeeds.enumerated()), id: \.offset) { index, photo in
                    GeometryReader { proxy in
                        ZStack {
                            LinearGradient(
                                colors: photo.paletteHex.map(AppFormat.colorFromHex),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(photo.assetName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .opacity(0.92)
                                .clipped()
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipShape(Rectangle())
                        .overlay(
                            LinearGradient(
                                colors: [Color.black.opacity(0.08), Color.black.opacity(0.58)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(photo.title)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Text(photo.subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.92))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: max(proxy.size.width - 16 - 140, 120), alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.leading, 16)
                            .padding(.bottom, 32)
                        }
                    }
                    .frame(height: 360)
                    .clipped()
                    .tag(index)
                }
            }
            .frame(height: 360)
            .clipped()
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(alignment: .top) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("restaurant_back_button")

                    Spacer()

                    Button {
                        store.toggleFavorite(restaurantID: restaurant.id)
                    } label: {
                        Image(systemName: store.isFavorite(restaurantID: restaurant.id) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("favorite_toggle_restaurant_\(restaurant.id)")

                    Button {
                        statusMessage = "Link copied to clipboard"
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("restaurant_share_button")
                }
                .padding(.horizontal, 16)
                .padding(.top, 58)
            }
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 6) {
                    ForEach(0..<min(photoSeeds.count, 5), id: \.self) { index in
                        Circle()
                            .fill(index == selectedPhotoIndex ? Color.white : Color.white.opacity(0.45))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 14)
            }

            Button {
                showPhotosSheet = true
            } label: {
                Text("See all \(photoSeeds.count) photos")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
            .accessibilityIdentifier("restaurant_photo_button")
        }
        .accessibilityIdentifier("restaurant_hero_image")
    }

    private func infoPanel(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(restaurant.name)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .accessibilityIdentifier("restaurant_detail_name")

            HStack(spacing: 8) {
                Text(AppFormat.starSymbols(for: restaurant.rating))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DiningTheme.accentRed)
                Text("\(AppFormat.reviewCount(for: restaurant.id)) reviews")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DiningTheme.textPrimary)
            }
            .accessibilityIdentifier("restaurant_detail_reviews")

            HStack(spacing: 8) {
                Label(AppFormat.priceRangeLabel(for: restaurant.priceTier), systemImage: "dollarsign.square")
                Text(restaurant.cuisine)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(DiningTheme.textSecondary)
            .accessibilityIdentifier("restaurant_detail_cuisine_neighborhood")

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "location")
                    .padding(.top, 3)
                Text(restaurant.address)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
            }
            .accessibilityIdentifier("restaurant_detail_address")

            HStack(spacing: 10) {
                datePartyPill

                Text("Booked \(22 + (Int(restaurant.id.suffix(2)) ?? 0) % 35) times today")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.blue.opacity(0.95))
                    .accessibilityIdentifier("restaurant_booked_today_label")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(DiningTheme.background)
    }

    private var datePartyPill: some View {
        HStack(spacing: 7) {
            Image(systemName: "person")
            Text("\(partySize) \u{2022} \(DateFormatters.shortTime.string(from: selectedTime)) \(selectedDateLabel)")
        }
        .font(.system(size: 17, weight: .bold))
        .foregroundStyle(DiningTheme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(
            Capsule().stroke(DiningTheme.chipBorder, lineWidth: 1.4)
        )
        .accessibilityIdentifier("restaurant_party_time_pill")
    }

    private var sectionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(DetailSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        VStack(spacing: 6) {
                            Text(section.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(selectedSection == section ? DiningTheme.accentRed : DiningTheme.textSecondary)
                                .lineLimit(1)
                                .fixedSize()

                            Rectangle()
                                .fill(selectedSection == section ? DiningTheme.accentRed : .clear)
                                .frame(height: 2.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("restaurant_tab_\(section.rawValue)")
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 6)
        .background(DiningTheme.background)
    }

    @ViewBuilder
    private func tabContent(restaurant: Restaurant) -> some View {
        switch selectedSection {
        case .reservations:
            reservationsTab(restaurant: restaurant)
        case .experiences:
            experiencesTab(restaurant: restaurant)
        case .reviews:
            reviewsTab(restaurant: restaurant)
        case .concierge:
            conciergeTab(restaurant: restaurant)
        case .menu:
            menuTab(restaurant: restaurant)
        }
    }

    private func reservationsTab(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Button {
                    showDateSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                        Text(DateFormatters.weekdayDate.string(from: selectedDate))
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .overlay(
                        Capsule().stroke(DiningTheme.chipBorder, lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("restaurant_date_control")

                Button {
                    showTimeSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                        Text(DateFormatters.shortTime.string(from: selectedTime))
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .overlay(
                        Capsule().stroke(DiningTheme.chipBorder, lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("restaurant_time_control")

                Menu {
                    ForEach(1...10, id: \.self) { size in
                        Button(AppFormat.partySizeLabel(size)) {
                            partySize = size
                        }
                        .accessibilityIdentifier("restaurant_party_size_option_\(size)")
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "person.2")
                        Text(AppFormat.partySizeLabel(partySize))
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .overlay(
                        Capsule().stroke(DiningTheme.chipBorder, lineWidth: 1.2)
                    )
                }
                .accessibilityIdentifier("restaurant_party_size_control")
            }

            if daySlots.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No availability for selected party size")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .accessibilityIdentifier("restaurant_no_availability_state")

                    if restaurant.supportsWaitlist {
                        Button("Join Waitlist") {
                            waitlistRequestType = .waitlist
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DiningTheme.accentRed)
                        .accessibilityIdentifier("waitlist_join_button")
                    }

                    if restaurant.supportsNotify {
                        Button("Notify Me") {
                            waitlistRequestType = .notify
                        }
                        .buttonStyle(.bordered)
                        .tint(DiningTheme.textPrimary)
                        .accessibilityIdentifier("notify_me_button")
                    }
                }
                .padding(16)
                .background(DiningTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DiningTheme.border, lineWidth: 1)
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(daySlots.prefix(8)) { slot in
                            Button {
                                selectedSlot = slot
                            } label: {
                                Text(DateFormatters.shortTime.string(from: slot.date))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(DiningTheme.slotRed)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("reservation_slot_\(DateFormatters.timestampID.string(from: slot.date))")
                        }
                    }
                }

                Button {
                    showFullAvailability = true
                } label: {
                    Text("View full availability")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(DiningTheme.border, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("restaurant_full_availability_button")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Walk-in")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DiningTheme.textPrimary)

                    Text("Search within the next 90 minutes to join the waitlist.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                }
                .accessibilityIdentifier("restaurant_walkin_section")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func experiencesTab(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            experienceCard(title: "Chef Counter Tasting", detail: "7-course tasting experience with wine pairing", price: "$145 per guest")
            experienceCard(title: "Anniversary Set Menu", detail: "Signature four-course dinner with dessert toast", price: "$98 per guest")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .accessibilityIdentifier("restaurant_experiences_section")
    }

    private func conciergeTab(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Concierge notes")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)

                Text(restaurant.policy.seatingNotes)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)

                Text(restaurant.policy.creditCardHold)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)

                Text(restaurant.policy.cancellationPolicy)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
            }
            .padding(14)
            .background(DiningTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DiningTheme.border, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .accessibilityIdentifier("restaurant_concierge_section")
    }

    private func menuTab(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Menu Highlights")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DiningTheme.textPrimary)
                    Text("Chef's selection · Tap an item to explore")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                }
                Spacer()
                // Course count badge
                Text("\(restaurant.menuHighlights.count) dishes")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DiningTheme.accentRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DiningTheme.accentRed.opacity(0.10))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)
            .accessibilityIdentifier("restaurant_menu_header")

            Divider()
                .padding(.horizontal, 16)

            // Menu item cards
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(restaurant.menuHighlights.enumerated()), id: \.offset) { index, item in
                    let appearance = MenuItemAppearance.lookup(name: item)
                    Button {
                        selectedMenuItem = SelectedMenuItem(id: item)
                    } label: {
                        menuItemRow(name: item, appearance: appearance, isLast: index == restaurant.menuHighlights.count - 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("restaurant_menu_item_\(AppFormat.accessibilitySlug(item))")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // "Full menu on request" footer note
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .medium))
                Text("Full seasonal menu available upon request")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(DiningTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 14)
            .accessibilityIdentifier("restaurant_menu_footer_note")
        }
        .background(DiningTheme.background)
        .accessibilityIdentifier("restaurant_menu_section")
        .sheet(item: $selectedMenuItem) { selection in
            menuItemDetailSheet(restaurant: restaurant, itemName: selection.id)
        }
    }

    /// A single row for a menu item with icon thumbnail, name, course badge, price, and chevron.
    private func menuItemRow(name: String, appearance: MenuItemAppearance, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // SF Symbol thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(appearance.tint.opacity(0.14))
                        .frame(width: 52, height: 52)
                    Image(systemName: appearance.symbol)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(appearance.tint)
                }

                // Name + course badge
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text(appearance.courseLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(appearance.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(appearance.tint.opacity(0.12))
                            .clipShape(Capsule())

                        Text(appearance.estimatedPrice)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DiningTheme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DiningTheme.muted)
            }
            .padding(.vertical, 13)

            if !isLast {
                Divider()
                    .padding(.leading, 66)
            }
        }
    }

    /// Detail sheet shown when a menu item is tapped.
    private func menuItemDetailSheet(restaurant: Restaurant, itemName: String) -> some View {
        MenuItemDetailSheet(restaurant: restaurant, itemName: itemName)
    }

    private func popularDishesSection(restaurant: Restaurant) -> some View {
        let dishes = store.popularDishes(for: restaurant.id)
        return Group {
            if !dishes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Popular Dishes")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .accessibilityIdentifier("restaurant_popular_dishes_title")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(dishes) { dish in
                                HStack(spacing: 6) {
                                    Text(dish.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(DiningTheme.textPrimary)
                                    Text("\(dish.mentionCount)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(DiningTheme.accentRed)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(DiningTheme.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(DiningTheme.border, lineWidth: 1)
                                )
                                .accessibilityIdentifier("popular_dish_\(AppFormat.accessibilitySlug(dish.name))")
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 12)
                .accessibilityIdentifier("restaurant_popular_dishes_section")
            }
        }
    }

    private func reviewsTab(restaurant: Restaurant) -> some View {
        let restaurantReviews = store.reviews(for: restaurant.id)
        return VStack(alignment: .leading, spacing: 16) {
            // Rating breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Ratings")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .accessibilityIdentifier("restaurant_ratings_title")

                ratingBar(label: "Food", value: restaurant.foodRating)
                ratingBar(label: "Service", value: restaurant.serviceRating)
                ratingBar(label: "Ambiance", value: restaurant.ambianceRating)
                ratingBar(label: "Value", value: restaurant.valueRating)
            }
            .padding(14)
            .background(DiningTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DiningTheme.border, lineWidth: 1)
            )
            .accessibilityIdentifier("restaurant_rating_breakdown")

            // Review cards
            if restaurantReviews.isEmpty {
                Text("No reviews yet")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
                    .accessibilityIdentifier("restaurant_no_reviews")
            } else {
                ForEach(restaurantReviews) { review in
                    reviewCard(review: review)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .accessibilityIdentifier("restaurant_reviews_section")
    }

    private func ratingBar(label: String, value: Double) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DiningTheme.textSecondary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(DiningTheme.border)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(DiningTheme.accentRed)
                        .frame(width: geometry.size.width * CGFloat(min(value, 5.0) / 5.0), height: 8)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.1f", value))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(DiningTheme.textPrimary)
                .frame(width: 32, alignment: .trailing)
        }
        .accessibilityIdentifier("rating_bar_\(label.lowercased())")
    }

    private func reviewCard(review: DinerReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.reviewerName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)

                Spacer()

                Text(DateFormatters.monthDayYear.string(from: review.date))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
            }

            HStack(spacing: 4) {
                Text(AppFormat.starSymbols(for: review.overallRating))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DiningTheme.accentRed)

                Text(String(format: "%.1f", review.overallRating))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DiningTheme.textSecondary)
            }

            Text(review.reviewText)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DiningTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(review.diningOccasion)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DiningTheme.accentRed)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(DiningTheme.accentRed.opacity(0.1))
                .clipShape(Capsule())
                .accessibilityIdentifier("review_occasion_\(AppFormat.accessibilitySlug(review.diningOccasion))")
        }
        .padding(14)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
        .accessibilityIdentifier("review_card_\(review.id)")
    }

    private func fullAvailabilitySheet(restaurant: Restaurant) -> some View {
        NavigationStack {
            List {
                if allFutureSlots.isEmpty {
                    Text("No upcoming online availability")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("restaurant_full_availability_empty")
                } else {
                    ForEach(allFutureSlots.prefix(50)) { slot in
                        Button {
                            pendingSlotFromFullAvailability = slot
                            showFullAvailability = false
                        } label: {
                            HStack {
                                Text(DateFormatters.weekdayDate.string(from: slot.date))
                                Spacer()
                                Text(DateFormatters.shortTime.string(from: slot.date))
                                    .fontWeight(.bold)
                                Text("\u{2022}")
                                Text(AppFormat.partySizeLabel(slot.partySize))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("full_availability_slot_\(slot.id)")
                    }
                }
            }
            .navigationTitle("Full Availability")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showFullAvailability = false
                    }
                    .accessibilityIdentifier("full_availability_close_button")
                }
            }
        }
    }

    private func experienceCard(title: String, detail: String, price: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)

            Text(detail)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(DiningTheme.textSecondary)

            Text(price)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DiningTheme.accentRed)

            Button("Book this experience") {
                showFullAvailability = true
            }
            .buttonStyle(.borderedProminent)
            .tint(DiningTheme.accentRed)
            .accessibilityIdentifier("restaurant_experience_book_button_\(AppFormat.accessibilitySlug(title))")
        }
        .padding(14)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
    }

    private func photosSheet(restaurant: Restaurant) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(photoSeeds) { photo in
                        ZStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: photo.paletteHex.map(AppFormat.colorFromHex),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Image(photo.assetName)
                                .resizable()
                                .scaledToFill()
                                .opacity(0.93)
                        }
                            .frame(height: 210)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(photo.title)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    Text(photo.subtitle)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .padding(12),
                                alignment: .bottomLeading
                            )
                            .accessibilityIdentifier("restaurant_photo_row_\(photo.id)")
                    }
                }
                .padding(16)
            }
            .background(DiningTheme.background)
            .navigationTitle("\(restaurant.name) Photos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showPhotosSheet = false
                    }
                    .accessibilityIdentifier("restaurant_photos_done_button")
                }
            }
        }
    }
}
