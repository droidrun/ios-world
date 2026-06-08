import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel

    @FocusState private var focusedField: FocusField?

    @State private var showFilters = false
    @State private var bookedTrip: Trip?
    @State private var bookedPaymentAccount: CheckoutPaymentAccount?
    @State private var showNotifications = false
    @State private var shopWithMiles = false

    enum FocusField {
        case origin
        case destination
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        searchFormCard
                        sortAndFilterSection
                        resultsSection
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
                .background(SkyTripTheme.surface)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.applyPendingPresetIfNeeded()
            }
            .sheet(item: $viewModel.selectedItinerary) { itinerary in
                ItineraryReviewView(viewModel: viewModel, itinerary: itinerary, bookedTrip: $bookedTrip, bookedPaymentAccount: $bookedPaymentAccount)
            }
            .sheet(isPresented: $showFilters) {
                SearchFiltersSheet(viewModel: viewModel)
            }
            .sheet(item: $bookedTrip) { trip in
                BookingConfirmationView(trip: trip, store: viewModel.store, paymentAccount: bookedPaymentAccount)
            }
            .sheet(isPresented: $showNotifications) {
                AlertsCenterView(alerts: viewModel.store.alerts)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Book")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("search_header_title")
            Spacer()
            Button {
                showNotifications = true
            } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("search_notifications_button")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SkyTripTheme.navy)
    }

    private var searchFormCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 0) {
                tripTypeButton("Round Trip", type: .roundTrip)
                tripTypeButton("One-Way", type: .oneWay)
            }
            .accessibilityIdentifier("search_trip_type_toggle")

            VStack(spacing: 0) {
                airportRow(
                    title: "From",
                    text: $viewModel.originInput,
                    focus: .origin,
                    identifier: "search_origin_field",
                    icon: "airplane.departure"
                )
                Divider().padding(.leading, 44)
                airportRow(
                    title: "To",
                    text: $viewModel.destinationInput,
                    focus: .destination,
                    identifier: "search_destination_field",
                    icon: "airplane.arrival"
                )
            }
            .background(SkyTripTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .trailing) {
                swapAirportsButton
                    .offset(y: 0)
            }

            if focusedField == .origin {
                airportSuggestions(query: viewModel.originInput, selectionAction: { airport in
                    viewModel.setOrigin(airport)
                    focusedField = nil
                }, prefix: "search_origin_suggestion")
            }

            if focusedField == .destination {
                airportSuggestions(query: viewModel.destinationInput, selectionAction: { airport in
                    viewModel.setDestination(airport)
                    focusedField = nil
                }, prefix: "search_destination_suggestion")
            }

            HStack(spacing: 10) {
                dateField(title: "Depart", selection: $viewModel.departureDate, id: "search_departure_date_button", icon: "calendar")
                if viewModel.tripType == .roundTrip {
                    dateField(title: "Return", selection: $viewModel.returnDate, id: "search_return_date_button", icon: "calendar")
                }
            }

            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .font(.system(size: 14))
                    Stepper("\(viewModel.passengers) Passenger\(viewModel.passengers == 1 ? "" : "s")", value: $viewModel.passengers, in: 1...9)
                        .font(.system(size: 14, weight: .medium))
                        .accessibilityIdentifier("search_passenger_count_stepper")
                }
                .padding(12)
                .background(SkyTripTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Cabin")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(0.5)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CabinClass.allCases) { cabin in
                            Button {
                                viewModel.selectedCabin = cabin
                            } label: {
                                Text(cabin.displayName)
                                    .font(.system(size: 13, weight: viewModel.selectedCabin == cabin ? .bold : .medium))
                                    .foregroundStyle(viewModel.selectedCabin == cabin ? .white : SkyTripTheme.textPrimary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(viewModel.selectedCabin == cabin ? SkyTripTheme.navy : SkyTripTheme.surface)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .accessibilityIdentifier("search_cabin_selector")
            }

            HStack(spacing: 16) {
                Toggle(isOn: $viewModel.nonstopOnly) {
                    Text("Nonstop Only")
                        .font(.system(size: 14, weight: .medium))
                }
                .tint(SkyTripTheme.red)
                .accessibilityIdentifier("search_nonstop_toggle")
            }

            HStack(spacing: 16) {
                Toggle(isOn: $shopWithMiles) {
                    Text("Shop with Miles")
                        .font(.system(size: 14, weight: .medium))
                }
                .tint(SkyTripTheme.red)
                .accessibilityIdentifier("search_shop_with_miles_toggle")
            }

            Button {
                focusedField = nil
                viewModel.performSearch()
            } label: {
                Text("Search")
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SkyTripTheme.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("search_submit_button")

            if let validationMessage = viewModel.validationMessage {
                errorBanner(text: validationMessage, id: "search_invalid_criteria_state")
            }

            if let snapshotError = viewModel.snapshotErrorMessage {
                errorBanner(text: snapshotError, id: "search_snapshot_unavailable_state")
            }
        }
        .padding(16)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func tripTypeButton(_ title: String, type: TripType) -> some View {
        Button {
            viewModel.tripType = type
        } label: {
            Text(title)
                .font(.system(size: 14, weight: viewModel.tripType == type ? .bold : .medium))
                .foregroundStyle(viewModel.tripType == type ? SkyTripTheme.navy : SkyTripTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    if viewModel.tripType == type {
                        Rectangle()
                            .fill(SkyTripTheme.navy)
                            .frame(height: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func airportRow(
        title: String,
        text: Binding<String>,
        focus: FocusField,
        identifier: String,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(SkyTripTheme.textSecondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                TextField("Airport", text: text)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                    .focused($focusedField, equals: focus)
                    .accessibilityIdentifier(identifier)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var swapAirportsButton: some View {
        Button {
            let previousOrigin = viewModel.originInput
            viewModel.originInput = viewModel.destinationInput
            viewModel.destinationInput = previousOrigin
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(SkyTripTheme.navy)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 12)
        .accessibilityIdentifier("search_swap_airports_button")
    }

    private func dateField(title: String, selection: Binding<Date>, id: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(SkyTripTheme.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                DatePicker("", selection: selection, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .accessibilityIdentifier(id)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func errorBanner(text: String, id: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(red: 157 / 255, green: 31 / 255, blue: 31 / 255))
                .font(.system(size: 14))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color(red: 157 / 255, green: 31 / 255, blue: 31 / 255))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 255 / 255, green: 232 / 255, blue: 232 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityIdentifier(id)
    }

    private var sortAndFilterSection: some View {
        HStack(spacing: 10) {
            Picker("Sort", selection: $viewModel.sortOption) {
                ForEach(SearchSortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .font(.system(size: 14, weight: .medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityIdentifier("search_sort_control")

            Button("Filters") {
                showFilters = true
            }
            .font(.system(size: 14, weight: .semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityIdentifier("search_filter_button")

            Spacer()
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RESULTS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .tracking(1)
                    .accessibilityIdentifier("search_results_title")
                Spacer()
                Text("\(viewModel.displayedResults.count) flights")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("search_results_count_label")
            }
            .padding(.top, 4)

            if !viewModel.hasSearched {
                emptyState(
                    text: "Enter your travel details above and tap Search to find available flights.",
                    id: "search_initial_prompt_state"
                )
            } else if viewModel.noFlightsFound {
                emptyState(
                    text: "No flights found for this search.",
                    id: "search_no_flights_state"
                )
            } else if viewModel.noMatchingFilters {
                emptyState(
                    text: "No matching filters. Adjust your filters and try again.",
                    id: "search_no_matching_filters_state"
                )
            } else {
                ForEach(viewModel.displayedResults) { itinerary in
                    Button {
                        viewModel.selectedItinerary = itinerary
                    } label: {
                        FlightResultRow(itinerary: itinerary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("flight_result_row_\(itinerary.id)")
                }
            }
        }
    }

    private func emptyState(text: String, id: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(SkyTripTheme.textSecondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SkyTripTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier(id)
    }

    private func airportSuggestions(
        query: String,
        selectionAction: @escaping (Airport) -> Void,
        prefix: String
    ) -> some View {
        let suggestions = viewModel.matchingAirports(for: query)

        return VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(suggestions.prefix(5))) { airport in
                Button {
                    selectionAction(airport)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "airplane")
                            .font(.system(size: 12))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(airport.code) · \(airport.city)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SkyTripTheme.textPrimary)
                            Text(airport.name)
                                .font(.system(size: 12))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(SkyTripTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(prefix)_\(airport.code)")
            }
        }
    }
}

private struct FlightResultRow: View {
    let itinerary: FlightItinerary

    private var outboundDeparture: Date {
        itinerary.outboundSegments.first?.departureTime ?? itinerary.departureTime
    }

    private var outboundArrival: Date {
        itinerary.outboundSegments.last?.arrivalTime ?? itinerary.departureTime
    }

    private var returnDeparture: Date? {
        itinerary.returnSegments.first?.departureTime
    }

    private var returnArrival: Date? {
        itinerary.returnSegments.last?.arrivalTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(itinerary.origin.code)
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text(itinerary.destination.code)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(SkyTripTheme.textPrimary)
                    .accessibilityIdentifier("flight_result_departure_arrival_\(itinerary.id)")
                    Text("\(AppFormatters.time(outboundDeparture)) – \(AppFormatters.time(outboundArrival))")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(AppFormatters.currency(itinerary.fare.price, code: itinerary.fare.currency))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                        .accessibilityIdentifier("flight_result_price_\(itinerary.id)")
                    Text("per person")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                }
            }

            if itinerary.tripType == .roundTrip,
               let returnDeparture,
               let returnArrival {
                Text("Return \(AppFormatters.time(returnDeparture)) – \(AppFormatters.time(returnArrival))")
                    .font(.system(size: 12))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("flight_result_return_departure_arrival_\(itinerary.id)")
            }

            HStack {
                Text("\(AppFormatters.duration(minutes: itinerary.totalDurationMinutes))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SkyTripTheme.textPrimary)
                Text("·")
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text(itinerary.totalStops == 0 ? "Nonstop" : "\(itinerary.totalStops) stop")
                    .font(.system(size: 12))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text("·")
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text(itinerary.outboundFlightNumber)
                    .font(.system(size: 12))
                    .foregroundStyle(SkyTripTheme.textSecondary)
            }
            .accessibilityIdentifier("flight_result_duration_stops_\(itinerary.id)")

            HStack {
                Text("\(itinerary.fare.fareBrand) · \(itinerary.fare.cabin.displayName)")
                    .font(.system(size: 12))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("flight_result_fare_brand_\(itinerary.id)")
                Spacer()
                ForEach(itinerary.badges, id: \.self) { badge in
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(Color(red: 233 / 255, green: 240 / 255, blue: 255 / 255))
                        .foregroundStyle(SkyTripTheme.navy)
                        .clipShape(Capsule())
                        .accessibilityIdentifier("flight_result_badge_\(itinerary.id)_\(badge.replacingOccurrences(of: " ", with: "_"))")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ItineraryReviewView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SearchViewModel
    let itinerary: FlightItinerary
    @Binding var bookedTrip: Trip?
    @Binding var bookedPaymentAccount: CheckoutPaymentAccount?

    @State private var showPayment = false

    private var baseFare: Double {
        itinerary.fare.price * Double(viewModel.passengers)
    }

    private var taxesAndFees: Double {
        baseFare * 0.12
    }

    private var totalPrice: Double {
        baseFare + taxesAndFees
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if !showPayment {
                    reviewStep
                } else {
                    paymentStep
                }
            }
            .navigationTitle(showPayment ? "Payment" : "Itinerary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityIdentifier("itinerary_review_close_button")
                }
            }
        }
    }

    @State private var showFareComparison = false

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Review Itinerary")
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("itinerary_review_title")

            VStack(alignment: .leading, spacing: 8) {
                Text("\(itinerary.origin.code) \u{2192} \(itinerary.destination.code)")
                    .font(.headline)
                    .accessibilityIdentifier("itinerary_review_route")

                itinerarySegmentSummary(
                    title: "Outbound",
                    segments: itinerary.outboundSegments,
                    prefix: "itinerary_review_outbound",
                    headlineIdentifier: "itinerary_review_departure"
                )

                if itinerary.tripType == .roundTrip,
                   !itinerary.returnSegments.isEmpty {
                    itinerarySegmentSummary(
                        title: "Return",
                        segments: itinerary.returnSegments,
                        prefix: "itinerary_review_return",
                        headlineIdentifier: "itinerary_review_return"
                    )
                }

                Text("Fare: \(itinerary.fare.fareBrand) \u{00B7} \(itinerary.fare.cabin.displayName)")
                    .font(.subheadline)
                    .accessibilityIdentifier("itinerary_review_fare")

                Text("Total: \(AppFormatters.currency(itinerary.fare.price, code: itinerary.fare.currency))")
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("itinerary_review_total")
            }
            .padding(12)
            .background(SkyTripTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                showFareComparison = true
            } label: {
                Text("Compare Fare Classes")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SkyTripTheme.navy, lineWidth: 1.5)
                    )
                    .foregroundStyle(SkyTripTheme.navy)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("itinerary_compare_fares_button")
            .sheet(isPresented: $showFareComparison) {
                FareComparisonView(selectedCabin: itinerary.fare.cabin)
            }

            Button {
                withAnimation { showPayment = true }
            } label: {
                Text("Continue to Payment")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SkyTripTheme.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("booking_continue_to_payment_button")
        }
        .padding()
    }

    private var paymentStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Flight summary
            VStack(alignment: .leading, spacing: 6) {
                Text("Flight Summary")
                    .font(.headline)
                    .accessibilityIdentifier("payment_flight_summary_title")

                HStack(spacing: 6) {
                    Text(itinerary.origin.code)
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Text(itinerary.destination.code)
                        .font(.system(size: 16, weight: .bold))
                }
                .accessibilityIdentifier("payment_route")

                if let first = itinerary.outboundSegments.first {
                    Text("Depart \(AppFormatters.date(first.departureTime))")
                        .font(.subheadline)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .accessibilityIdentifier("payment_departure_date")
                }

                if itinerary.tripType == .roundTrip,
                   let returnFirst = itinerary.returnSegments.first {
                    Text("Return \(AppFormatters.date(returnFirst.departureTime))")
                        .font(.subheadline)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                        .accessibilityIdentifier("payment_return_date")
                }

                Text("\(itinerary.fare.cabin.displayName) \u{00B7} \(viewModel.passengers) passenger\(viewModel.passengers == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("payment_cabin_passengers")
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SkyTripTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Payment method picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Payment Method")
                    .font(.headline)
                    .accessibilityIdentifier("payment_method_title")

                ForEach(viewModel.store.paymentAccounts) { account in
                    Button {
                        viewModel.store.selectedPaymentAccountID = account.id
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.store.selectedPaymentAccountID == account.id ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(viewModel.store.selectedPaymentAccountID == account.id ? SkyTripTheme.navy : SkyTripTheme.textSecondary)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(SkyTripTheme.textPrimary)
                                Text(account.displayName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                            }

                            Spacer()

                            Text(AppFormatters.currency(account.availableBalance, code: account.currency))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                        }
                        .padding(12)
                        .background(viewModel.store.selectedPaymentAccountID == account.id ? SkyTripTheme.surface : SkyTripTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(viewModel.store.selectedPaymentAccountID == account.id ? SkyTripTheme.navy : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("payment_account_\(account.type.rawValue)")
                }
            }

            // Price breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Price Breakdown")
                    .font(.headline)
                    .accessibilityIdentifier("payment_price_breakdown_title")

                HStack {
                    Text("Base fare (\(viewModel.passengers) pax)")
                        .font(.subheadline)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Spacer()
                    Text(AppFormatters.currency(baseFare, code: itinerary.fare.currency))
                        .font(.subheadline)
                }
                .accessibilityIdentifier("payment_base_fare")

                HStack {
                    Text("Taxes & fees")
                        .font(.subheadline)
                        .foregroundStyle(SkyTripTheme.textSecondary)
                    Spacer()
                    Text(AppFormatters.currency(taxesAndFees, code: itinerary.fare.currency))
                        .font(.subheadline)
                }
                .accessibilityIdentifier("payment_taxes_fees")

                Divider()

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(AppFormatters.currency(totalPrice, code: itinerary.fare.currency))
                        .font(.headline)
                }
                .accessibilityIdentifier("payment_total")

                if let selected = viewModel.store.selectedPaymentAccount {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(SkyTripTheme.textSecondary)
                        Text("Charging \(selected.network) \(selected.maskedNumber)")
                            .font(.caption)
                            .foregroundStyle(SkyTripTheme.textSecondary)
                    }
                    .padding(.top, 4)
                    .accessibilityIdentifier("payment_selected_card_display")
                }
            }
            .padding(12)
            .background(SkyTripTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Purchase button
            Button {
                guard let accountID = viewModel.store.selectedPaymentAccountID else { return }
                let trip = viewModel.store.createBooking(from: itinerary, passengers: viewModel.passengers, paymentAccountID: accountID)
                bookedPaymentAccount = viewModel.store.selectedPaymentAccount
                bookedTrip = trip
                dismiss()
            } label: {
                Text("Purchase Flight")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SkyTripTheme.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("booking_confirm_button")

            // Go back button
            Button {
                withAnimation { showPayment = false }
            } label: {
                Text("Go Back")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(SkyTripTheme.navy)
            .accessibilityIdentifier("payment_go_back_button")
        }
        .padding()
    }

    @ViewBuilder
    private func itinerarySegmentSummary(
        title: String,
        segments: [FlightSegment],
        prefix: String,
        headlineIdentifier: String
    ) -> some View {
        if let first = segments.first,
           let last = segments.last {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SkyTripTheme.textSecondary)
                Text("\(first.origin.code) \u{2192} \(last.destination.code)")
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("\(prefix)_route")
                Text(title == "Return" ? "Return \(AppFormatters.full(first.departureTime))" : "Depart \(AppFormatters.full(first.departureTime))")
                    .font(.subheadline)
                    .accessibilityIdentifier(headlineIdentifier)
                Text("Arrive \(AppFormatters.full(last.arrivalTime))")
                    .font(.subheadline)
                    .foregroundStyle(SkyTripTheme.textSecondary)
                    .accessibilityIdentifier("\(prefix)_times")
            }
        }
    }
}

private struct BookingConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    @ObservedObject var store: AppStore
    let paymentAccount: CheckoutPaymentAccount?

    private var baseFare: Double {
        trip.totalPrice / 1.12
    }

    private var taxesAndFees: Double {
        trip.totalPrice - baseFare
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.green)

                    Text("Booking Confirmed!")
                        .font(.title2.weight(.bold))
                        .accessibilityIdentifier("booking_confirmation_title")

                    VStack(spacing: 8) {
                        Text("Confirmation: \(trip.confirmationCode)")
                            .font(.headline)
                            .accessibilityIdentifier("booking_confirmation_code")
                    }

                    // Flight details card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Flight Details")
                            .font(.headline)
                            .accessibilityIdentifier("booking_confirmation_details_title")

                        HStack(spacing: 6) {
                            Text(trip.outboundSegments.first?.origin.code ?? "")
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Text(trip.outboundSegments.last?.destination.code ?? "")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .accessibilityIdentifier("booking_confirmation_route")

                        if let first = trip.outboundSegments.first {
                            Text("Depart \(AppFormatters.full(first.departureTime))")
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                                .accessibilityIdentifier("booking_confirmation_departure")
                        }

                        if trip.tripType == .roundTrip,
                           let returnFirst = trip.returnSegments.first {
                            Text("Return \(AppFormatters.full(returnFirst.departureTime))")
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                                .accessibilityIdentifier("booking_confirmation_return")
                        }

                        Divider()

                        HStack {
                            Text("Passenger")
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Spacer()
                            Text(trip.passenger.fullName)
                                .font(.subheadline.weight(.medium))
                        }
                        .accessibilityIdentifier("booking_confirmation_passenger")

                        HStack {
                            Text("Seat")
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Spacer()
                            Text(trip.seatAssignment ?? "TBD")
                                .font(.subheadline.weight(.medium))
                        }
                        .accessibilityIdentifier("booking_confirmation_seat")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Price breakdown card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price Breakdown")
                            .font(.headline)
                            .accessibilityIdentifier("booking_confirmation_price_title")

                        HStack {
                            Text("Base fare")
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Spacer()
                            Text(AppFormatters.currency(baseFare, code: trip.currency))
                                .font(.subheadline)
                        }
                        .accessibilityIdentifier("booking_confirmation_base_fare")

                        HStack {
                            Text("Taxes & fees")
                                .font(.subheadline)
                                .foregroundStyle(SkyTripTheme.textSecondary)
                            Spacer()
                            Text(AppFormatters.currency(taxesAndFees, code: trip.currency))
                                .font(.subheadline)
                        }
                        .accessibilityIdentifier("booking_confirmation_taxes")

                        Divider()

                        HStack {
                            Text("Total charged")
                                .font(.headline)
                            Spacer()
                            Text(AppFormatters.currency(trip.totalPrice, code: trip.currency))
                                .font(.headline)
                        }
                        .accessibilityIdentifier("booking_confirmation_total")

                        if let account = paymentAccount {
                            HStack(spacing: 4) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                                Text("\(account.network) \(account.maskedNumber)")
                                    .font(.caption)
                                    .foregroundStyle(SkyTripTheme.textSecondary)
                            }
                            .padding(.top, 2)
                            .accessibilityIdentifier("booking_confirmation_payment_method")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SkyTripTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button {
                        store.selectedTab = .trips
                        dismiss()
                    } label: {
                        Text("View in My Trips")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(SkyTripTheme.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("booking_confirmation_view_trips_button")

                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SkyTripTheme.navy)
                    .accessibilityIdentifier("booking_confirmation_done_button")
                }
                .padding(24)
            }
        }
    }
}

private struct SearchFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SearchViewModel

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Nonstop only", isOn: $viewModel.filters.nonstopOnly)
                    .accessibilityIdentifier("search_filter_nonstop_toggle")

                Picker("Cabin", selection: Binding<CabinClass?>(
                    get: { viewModel.filters.cabin },
                    set: { viewModel.filters.cabin = $0 }
                )) {
                    Text("Any Cabin").tag(CabinClass?.none)
                    ForEach(CabinClass.allCases) { cabin in
                        Text(cabin.displayName).tag(Optional(cabin))
                    }
                }
                .accessibilityIdentifier("search_filter_cabin_picker")

                Picker("Time of day", selection: $viewModel.filters.timeOfDay) {
                    ForEach(TimeOfDayFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .accessibilityIdentifier("search_filter_time_of_day_picker")

                Stepper("Max stops: \(viewModel.filters.maxStops)", value: $viewModel.filters.maxStops, in: 0...2)
                    .accessibilityIdentifier("search_filter_max_stops_stepper")
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .accessibilityIdentifier("search_filter_apply_button")
                }
            }
        }
    }
}

// MARK: - Fare Comparison View

private struct FareComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedCabin: CabinClass

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(FareClassBenefit.allClasses) { fareClass in
                        fareColumn(fareClass)
                    }
                }
                .padding(16)
            }
            .background(SkyTripTheme.surface)
            .navigationTitle("Compare Fares")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("fare_comparison_done_button")
                }
            }
        }
    }

    private func fareColumn(_ fareClass: FareClassBenefit) -> some View {
        let isSelected = fareClass.cabin == selectedCabin
        return VStack(alignment: .leading, spacing: 10) {
            Text(fareClass.cabin.displayName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isSelected ? .white : SkyTripTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(isSelected ? SkyTripTheme.navy : SkyTripTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if isSelected {
                Text("Selected")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SkyTripTheme.red)
                    .accessibilityIdentifier("fare_comparison_selected_badge")
            }

            ForEach(fareClass.benefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SkyTripTheme.red)
                        .padding(.top, 2)
                    Text(benefit)
                        .font(.system(size: 12))
                        .foregroundStyle(SkyTripTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
        .frame(width: 160)
        .padding(12)
        .background(SkyTripTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? SkyTripTheme.navy : Color.clear, lineWidth: 2)
        )
        .accessibilityIdentifier("fare_comparison_\(fareClass.cabin.rawValue)")
    }
}
