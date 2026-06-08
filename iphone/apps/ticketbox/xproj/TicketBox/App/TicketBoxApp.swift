import CoreLocation
import SwiftUI

@main
struct TicketBoxApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = MockTicketBoxStore()
    @State private var locationResolver = TicketBoxDeviceLocationResolver()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .environment(locationResolver)
                .task {
                    syncDeviceLocationIfNeeded()
                    await store.loadLiveSportsEvents()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    syncDeviceLocationIfNeeded()
                }
                .onChange(of: locationResolver.resolvedCity) { _, city in
                    guard let city else { return }
                    store.applyDetectedLocation(city)
                }
                .onChange(of: store.settings.selectedCity) { _, city in
                    guard store.shouldAutoDetectLocation, city == SettingsState.default.selectedCity else { return }
                    syncDeviceLocationIfNeeded()
                }
        }
    }

    private func syncDeviceLocationIfNeeded() {
        guard store.shouldAutoDetectLocation else { return }

        if let resolvedCity = locationResolver.resolvedCity {
            store.applyDetectedLocation(resolvedCity)
        } else {
            locationResolver.requestCurrentLocation()
        }
    }
}

@Observable @MainActor
final class TicketBoxDeviceLocationResolver: NSObject {
    private(set) var resolvedCity: String?

    private var manager: CLLocationManager?
    private var isRequestInFlight = false

    func requestCurrentLocation(promptIfNeeded: Bool = false) {
        guard !isRequestInFlight else { return }

        guard CLLocationManager.locationServicesEnabled() else {
            applyFallback()
            return
        }

        if manager == nil {
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.manager = manager
        }

        guard let manager else { return }
        isRequestInFlight = true

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            if promptIfNeeded {
                manager.requestWhenInUseAuthorization()
            } else {
                applyFallback()
            }
        case .denied, .restricted:
            applyFallback()
        @unknown default:
            applyFallback()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            applyFallback()
        case .notDetermined:
            break
        @unknown default:
            applyFallback()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            applyFallback()
            return
        }

        resolvedCity = supportedCities.min(by: {
            $0.location.distance(from: location) < $1.location.distance(from: location)
        })?.name ?? SettingsState.default.selectedCity
        isRequestInFlight = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        applyFallback()
    }

    private func applyFallback() {
        resolvedCity = SettingsState.default.selectedCity
        isRequestInFlight = false
    }

    private var supportedCities: [SupportedCity] {
        [
            SupportedCity(name: "San Francisco, CA", latitude: 37.7749, longitude: -122.4194),
            SupportedCity(name: "Oakland, CA", latitude: 37.8044, longitude: -122.2712),
            SupportedCity(name: "San Jose, CA", latitude: 37.3382, longitude: -121.8863),
            SupportedCity(name: "Stanford, CA", latitude: 37.4275, longitude: -122.1697),
            SupportedCity(name: "Mountain View, CA", latitude: 37.3861, longitude: -122.0839)
        ]
    }

    private struct SupportedCity {
        let name: String
        let location: CLLocation

        init(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
            self.name = name
            self.location = CLLocation(latitude: latitude, longitude: longitude)
        }
    }
}

extension TicketBoxDeviceLocationResolver: @preconcurrency CLLocationManagerDelegate {}
