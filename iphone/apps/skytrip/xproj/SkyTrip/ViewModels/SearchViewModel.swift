import Foundation

@MainActor
final class SearchViewModel: StoreBackedViewModel {
    @Published var tripType: TripType = .oneWay
    @Published var originInput: String = "ATL"
    @Published var destinationInput: String = "LAX"
    @Published var departureDate: Date
    @Published var returnDate: Date
    @Published var passengers: Int = 1
    @Published var selectedCabin: CabinClass = .mainCabin
    @Published var nonstopOnly: Bool = false

    @Published var sortOption: SearchSortOption = .lowestPrice
    @Published var filters: SearchFilters = SearchFilters()

    @Published private(set) var rawResults: [FlightItinerary] = []
    @Published var selectedItinerary: FlightItinerary?
    @Published private(set) var validationMessage: String?
    @Published private(set) var hasSearched: Bool = false

    override init(store: AppStore) {
        let oneWayDate = SeedDataFactory.defaultDepartureDate(for: .oneWay)
        let roundTripReturn = Calendar(identifier: .gregorian).date(byAdding: .day, value: 3, to: oneWayDate) ?? oneWayDate
        self.departureDate = oneWayDate
        self.returnDate = roundTripReturn
        super.init(store: store)
    }

    var airports: [Airport] {
        store.airports
    }

    var displayedResults: [FlightItinerary] {
        let filtered = rawResults.filter { itinerary in
            if filters.nonstopOnly && itinerary.totalStops > 0 {
                return false
            }
            if let cabin = filters.cabin, itinerary.fare.cabin != cabin {
                return false
            }
            if itinerary.totalStops > filters.maxStops {
                return false
            }
            if !matchesTimeOfDayFilter(itinerary, filter: filters.timeOfDay) {
                return false
            }
            return true
        }

        return sorted(filtered)
    }

    var noFlightsFound: Bool {
        hasSearched && validationMessage == nil && rawResults.isEmpty
    }

    var noMatchingFilters: Bool {
        hasSearched && validationMessage == nil && !rawResults.isEmpty && displayedResults.isEmpty
    }

    var fareSourceLabel: String {
        store.fareSourceType.displayName
    }

    var snapshotErrorMessage: String? {
        store.fareSourceType == .snapshot ? store.snapshotError : nil
    }

    func setOrigin(_ airport: Airport) {
        originInput = airport.code
    }

    func setDestination(_ airport: Airport) {
        destinationInput = airport.code
    }

    /// Called by SearchView.onAppear to apply any pending preset from a recent-search tap.
    func applyPendingPresetIfNeeded() {
        guard let preset = store.pendingSearchPreset else { return }
        originInput = preset.originCode
        destinationInput = preset.destinationCode
        tripType = preset.tripType
        departureDate = preset.departureDate
        store.pendingSearchPreset = nil
    }

    func matchingAirports(for query: String) -> [Airport] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return airports
        }

        let lowercased = trimmed.lowercased()
        return airports.filter {
            $0.code.lowercased().contains(lowercased) ||
            $0.city.lowercased().contains(lowercased) ||
            $0.name.lowercased().contains(lowercased)
        }
    }

    func performSearch() {
        validationMessage = nil
        rawResults = []
        selectedItinerary = nil
        hasSearched = true

        let normalizedOrigin = normalizedAirportCode(from: originInput)
        let normalizedDestination = normalizedAirportCode(from: destinationInput)

        guard let origin = normalizedOrigin else {
            validationMessage = "Please enter a valid origin airport."
            return
        }

        guard let destination = normalizedDestination else {
            validationMessage = "Please enter a valid destination airport."
            return
        }

        guard origin != destination else {
            validationMessage = "Origin and destination must be different."
            return
        }

        if tripType == .roundTrip && returnDate < departureDate {
            validationMessage = "Return date must be after departure date."
            return
        }

        let criteria = FlightSearchCriteria(
            tripType: tripType,
            originCode: origin,
            destinationCode: destination,
            departureDate: departureDate,
            returnDate: tripType == .roundTrip ? returnDate : nil,
            passengers: passengers,
            cabin: selectedCabin,
            nonstopOnly: nonstopOnly
        )

        rawResults = store.search(criteria: criteria)
    }

    private func normalizedAirportCode(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let exact = airports.first(where: { $0.code.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return exact.code
        }

        if let city = airports.first(where: { $0.city.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return city.code
        }

        return nil
    }

    private func sorted(_ itineraries: [FlightItinerary]) -> [FlightItinerary] {
        switch sortOption {
        case .lowestPrice:
            return itineraries.sorted { $0.fare.price < $1.fare.price }
        case .highestPrice:
            return itineraries.sorted { $0.fare.price > $1.fare.price }
        case .shortestDuration:
            return itineraries.sorted { $0.totalDurationMinutes < $1.totalDurationMinutes }
        case .earliestDeparture:
            return itineraries.sorted { $0.departureTime < $1.departureTime }
        }
    }

    private func matchesTimeOfDayFilter(_ itinerary: FlightItinerary, filter: TimeOfDayFilter) -> Bool {
        guard filter != .any else {
            return true
        }

        let hour = Calendar(identifier: .gregorian).component(.hour, from: itinerary.departureTime)

        switch filter {
        case .any:
            return true
        case .morning:
            return (5...11).contains(hour)
        case .afternoon:
            return (12...17).contains(hour)
        case .evening:
            return hour >= 18 || hour < 5
        }
    }
}
