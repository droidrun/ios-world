import MapKit
import SwiftUI

struct RouteMapView: View {
    let pickup: CLLocationCoordinate2D?
    let destination: CLLocationCoordinate2D?
    var showsAnnotations: Bool = true
    var driverProgress: Double? = nil
    var lineWidth: CGFloat = 5

    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            if showsAnnotations, let pickup {
                Annotation("Pickup", coordinate: pickup) {
                    Circle()
                        .fill(CityRideTheme.accent)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }

            if showsAnnotations, let destination {
                Annotation("Destination", coordinate: destination) {
                    Image(systemName: "mappin")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                }
            }

            if !routeCoordinates.isEmpty {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(.white, lineWidth: lineWidth)
            }

            if let progress = driverProgress, let coord = driverCoordinate(at: progress) {
                Annotation("Driver", coordinate: coord) {
                    Circle()
                        .fill(Color.black.opacity(0.80))
                        .frame(width: 24, height: 24)
                        .overlay(Image(systemName: "car.fill").font(.caption).foregroundStyle(.white))
                        .accessibilityIdentifier("map_driver_marker")
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
        .colorScheme(.dark)
        .onAppear { fetchRoute() }
        .onChange(of: pickup?.latitude) { _, _ in fetchRoute() }
        .onChange(of: destination?.latitude) { _, _ in fetchRoute() }
    }

    private func fetchRoute() {
        guard let pickup, let destination else {
            routeCoordinates = []
            return
        }

        let region = regionFitting(pickup, destination)
        cameraPosition = .region(region)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickup))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        Task {
            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                if let route = response.routes.first {
                    let points = route.polyline.points()
                    let count = route.polyline.pointCount
                    var coords: [CLLocationCoordinate2D] = []
                    for i in 0..<count {
                        coords.append(points[i].coordinate)
                    }
                    await MainActor.run {
                        routeCoordinates = coords
                        let routeRegion = regionFitting(pickup, destination, padding: 0.4)
                        cameraPosition = .region(routeRegion)
                    }
                }
            } catch {
                await MainActor.run {
                    routeCoordinates = [pickup, destination]
                }
            }
        }
    }

    private func driverCoordinate(at progress: Double) -> CLLocationCoordinate2D? {
        guard routeCoordinates.count >= 2 else { return nil }
        let t = max(0, min(1, progress))
        let totalDistance = totalRouteDistance()
        guard totalDistance > 0 else { return routeCoordinates.first }
        let targetDistance = t * totalDistance
        var accumulated = 0.0
        for i in 0..<(routeCoordinates.count - 1) {
            let segmentDist = distance(routeCoordinates[i], routeCoordinates[i + 1])
            if accumulated + segmentDist >= targetDistance {
                let remaining = targetDistance - accumulated
                let fraction = remaining / segmentDist
                let lat = routeCoordinates[i].latitude + (routeCoordinates[i + 1].latitude - routeCoordinates[i].latitude) * fraction
                let lon = routeCoordinates[i].longitude + (routeCoordinates[i + 1].longitude - routeCoordinates[i].longitude) * fraction
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            accumulated += segmentDist
        }
        return routeCoordinates.last
    }

    private func totalRouteDistance() -> Double {
        var total = 0.0
        for i in 0..<(routeCoordinates.count - 1) {
            total += distance(routeCoordinates[i], routeCoordinates[i + 1])
        }
        return total
    }

    private func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let R = 6_371_000.0
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let sinDLat = sin(dLat / 2)
        let sinDLon = sin(dLon / 2)
        let h = sinDLat * sinDLat + cos(lat1) * cos(lat2) * sinDLon * sinDLon
        return R * 2 * atan2(sqrt(h), sqrt(1 - h))
    }

    private func regionFitting(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, padding: Double = 0.35) -> MKCoordinateRegion {
        let centerLat = (a.latitude + b.latitude) / 2
        let centerLon = (a.longitude + b.longitude) / 2
        let spanLat = abs(a.latitude - b.latitude) * (1 + padding)
        let spanLon = abs(a.longitude - b.longitude) * (1 + padding)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(spanLat, 0.01),
                longitudeDelta: max(spanLon, 0.01)
            )
        )
    }
}

extension RouteMapView {
    init(pickup: LocationPlace?, destination: LocationPlace?, showsAnnotations: Bool = true, driverProgress: Double? = nil, lineWidth: CGFloat = 5) {
        self.init(
            pickup: pickup.map { CLLocationCoordinate2D(latitude: $0.latitudePlaceholder, longitude: $0.longitudePlaceholder) },
            destination: destination.map { CLLocationCoordinate2D(latitude: $0.latitudePlaceholder, longitude: $0.longitudePlaceholder) },
            showsAnnotations: showsAnnotations,
            driverProgress: driverProgress,
            lineWidth: lineWidth
        )
    }

    init(pickupName: String, destinationName: String, places: [LocationPlace], showsAnnotations: Bool = true, driverProgress: Double? = nil, lineWidth: CGFloat = 5) {
        let pickup = places.first(where: { $0.displayName.caseInsensitiveCompare(pickupName) == .orderedSame })
        let destination = places.first(where: { $0.displayName.caseInsensitiveCompare(destinationName) == .orderedSame })
        self.init(
            pickup: pickup,
            destination: destination,
            showsAnnotations: showsAnnotations,
            driverProgress: driverProgress,
            lineWidth: lineWidth
        )
    }
}
