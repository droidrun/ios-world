import Combine
import MapKit

enum GeocodeResult {
    case success(LocationPlace)
    case failure(String)

    var errorMessage: String? {
        switch self {
        case .success: return nil
        case .failure(let message): return message
        }
    }

    var place: LocationPlace? {
        if case .success(let place) = self { return place }
        return nil
    }
}

final class AddressSearchService: NSObject, ObservableObject {
    @Published var queryFragment: String = ""
    @Published private(set) var completions: [MKLocalSearchCompletion] = []
    @Published private(set) var isSearching: Bool = false

    private let completer: MKLocalSearchCompleter
    private var cancellables = Set<AnyCancellable>()

    override init() {
        completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
        super.init()
        completer.delegate = self

        $queryFragment
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] fragment in
                guard let self else { return }
                let trimmed = fragment.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    self.completions = []
                    self.isSearching = false
                } else {
                    self.isSearching = true
                    self.completer.queryFragment = trimmed
                }
            }
            .store(in: &cancellables)
    }

    /// Default SF center coordinates used to bias search results; overridden by device location
    private static let sfCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    /// Set this to the device's current coordinate to bias search results around the user
    var deviceCoordinate: CLLocationCoordinate2D? {
        didSet {
            if let coord = deviceCoordinate {
                completer.region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                )
            }
        }
    }

    private var searchCenter: CLLocationCoordinate2D {
        deviceCoordinate ?? Self.sfCenter
    }

    /// Geocode a free-text address string into a LocationPlace
    func geocode(address: String) async -> GeocodeResult {
        let trimmed = address.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .failure("Please enter an address.") }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = MKCoordinateRegion(
            center: searchCenter,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else {
                return .failure("No results found for \"\(trimmed)\".")
            }
            let coordinate = item.placemark.coordinate
            let displayName = item.name ?? trimmed
            let addressLine = [item.placemark.thoroughfare, item.placemark.locality, item.placemark.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", ")
            let finalAddress = addressLine.isEmpty ? displayName : addressLine
            let id = "mapkit_\(Int(coordinate.latitude * 10000))_\(Int(coordinate.longitude * 10000))_\(abs(displayName.hashValue) % 100000)"
            let place = LocationPlace(
                id: id,
                displayName: displayName,
                address: finalAddress,
                latitudePlaceholder: coordinate.latitude,
                longitudePlaceholder: coordinate.longitude
            )
            return .success(place)
        } catch {
            return .failure("Could not find that address. Please try again.")
        }
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> LocationPlace? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else { return nil }
            let coordinate = item.placemark.coordinate
            let displayName = completion.title
            let address = completion.subtitle.isEmpty
                ? (item.placemark.thoroughfare.map { street in
                    [street, item.placemark.locality, item.placemark.administrativeArea]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                } ?? completion.title)
                : completion.subtitle
            let id = "mapkit_\(Int(coordinate.latitude * 10000))_\(Int(coordinate.longitude * 10000))_\(abs(displayName.hashValue) % 100000)"
            return LocationPlace(
                id: id,
                displayName: displayName,
                address: address,
                latitudePlaceholder: coordinate.latitude,
                longitudePlaceholder: coordinate.longitude
            )
        } catch {
            return nil
        }
    }
}

extension AddressSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        isSearching = false
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        isSearching = false
        completions = []
    }
}
