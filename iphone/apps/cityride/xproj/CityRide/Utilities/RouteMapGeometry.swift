import CoreGraphics
import Foundation

struct RouteMapLayout {
    var pickup: CGPoint
    var destination: CGPoint
    var control1: CGPoint
    var control2: CGPoint

    static let fallback = RouteMapLayout(
        pickup: CGPoint(x: 0.20, y: 0.72),
        destination: CGPoint(x: 0.80, y: 0.28),
        control1: CGPoint(x: 0.38, y: 0.48),
        control2: CGPoint(x: 0.62, y: 0.52)
    )
}

enum RouteMapGeometry {
    static func location(named name: String, in places: [LocationPlace]) -> LocationPlace? {
        places.first { $0.displayName.caseInsensitiveCompare(name) == .orderedSame }
    }

    static func layout(pickup: LocationPlace?, destination: LocationPlace?, in places: [LocationPlace]) -> RouteMapLayout {
        guard let pickup, let destination else {
            return .fallback
        }

        let basePickup = normalizedPoint(for: pickup, in: places)
        let baseDestination = normalizedPoint(for: destination, in: places)
        let framed = framedRoutePoints(pickup: basePickup, destination: baseDestination)

        var pickupPoint = framed.pickup
        var destinationPoint = framed.destination
        ensureMinimumDistance(
            pickup: &pickupPoint,
            destination: &destinationPoint,
            minimumDistance: 0.24,
            inset: 0.10
        )

        let dx = destinationPoint.x - pickupPoint.x
        let dy = destinationPoint.y - pickupPoint.y
        let routeDistance = max(distance(pickupPoint, destinationPoint), 0.0001)

        let midpoint = CGPoint(
            x: (pickupPoint.x + destinationPoint.x) / 2,
            y: (pickupPoint.y + destinationPoint.y) / 2
        )
        let unitX = dx / max(routeDistance, 0.0001)
        let unitY = dy / max(routeDistance, 0.0001)
        let perpX = -unitY
        let perpY = unitX

        let bend = max(0.05, min(0.14, routeDistance * 0.30))
        let control1 = CGPoint(
            x: clamp(midpoint.x - dx * 0.18 + perpX * bend, min: 0.08, max: 0.92),
            y: clamp(midpoint.y - dy * 0.18 + perpY * bend, min: 0.08, max: 0.92)
        )
        let control2 = CGPoint(
            x: clamp(midpoint.x + dx * 0.18 + perpX * bend, min: 0.08, max: 0.92),
            y: clamp(midpoint.y + dy * 0.18 + perpY * bend, min: 0.08, max: 0.92)
        )

        return RouteMapLayout(
            pickup: pickupPoint,
            destination: destinationPoint,
            control1: control1,
            control2: control2
        )
    }

    static func point(in size: CGSize, normalized: CGPoint) -> CGPoint {
        CGPoint(
            x: normalized.x * size.width,
            y: normalized.y * size.height
        )
    }

    private static func normalizedPoint(for place: LocationPlace, in places: [LocationPlace]) -> CGPoint {
        guard !places.isEmpty else {
            return .init(x: 0.5, y: 0.5)
        }

        let lats = places.map(\.latitudePlaceholder)
        let lons = places.map(\.longitudePlaceholder)

        let minLat = lats.min() ?? place.latitudePlaceholder
        let maxLat = lats.max() ?? place.latitudePlaceholder
        let minLon = lons.min() ?? place.longitudePlaceholder
        let maxLon = lons.max() ?? place.longitudePlaceholder

        let latSpan = max(maxLat - minLat, 0.0001)
        let lonSpan = max(maxLon - minLon, 0.0001)

        let normalizedX = (place.longitudePlaceholder - minLon) / lonSpan
        let normalizedY = 1.0 - (place.latitudePlaceholder - minLat) / latSpan
        return CGPoint(
            x: clamp(CGFloat(normalizedX), min: 0.0, max: 1.0),
            y: clamp(CGFloat(normalizedY), min: 0.0, max: 1.0)
        )
    }

    private static func framedRoutePoints(pickup: CGPoint, destination: CGPoint) -> (pickup: CGPoint, destination: CGPoint) {
        let minSpan: CGFloat = 0.20
        let framePadding: CGFloat = 0.15

        let centerX = (pickup.x + destination.x) / 2
        let centerY = (pickup.y + destination.y) / 2
        let spanX = max(abs(destination.x - pickup.x), minSpan)
        let spanY = max(abs(destination.y - pickup.y), minSpan)
        let frameMinX = centerX - (spanX / 2)
        let frameMinY = centerY - (spanY / 2)

        func remap(_ point: CGPoint) -> CGPoint {
            let xRatio = clamp((point.x - frameMinX) / spanX, min: 0.0, max: 1.0)
            let yRatio = clamp((point.y - frameMinY) / spanY, min: 0.0, max: 1.0)
            return CGPoint(
                x: framePadding + xRatio * (1 - 2 * framePadding),
                y: framePadding + yRatio * (1 - 2 * framePadding)
            )
        }

        return (pickup: remap(pickup), destination: remap(destination))
    }

    private static func ensureMinimumDistance(
        pickup: inout CGPoint,
        destination: inout CGPoint,
        minimumDistance: CGFloat,
        inset: CGFloat
    ) {
        var dx = destination.x - pickup.x
        var dy = destination.y - pickup.y
        var routeDistance = distance(pickup, destination)
        guard routeDistance < minimumDistance else { return }

        if routeDistance < 0.0001 {
            dx = 0.7
            dy = -0.7
            routeDistance = 1.0
        }

        let unitX = dx / routeDistance
        let unitY = dy / routeDistance
        let midpoint = CGPoint(
            x: (pickup.x + destination.x) / 2,
            y: (pickup.y + destination.y) / 2
        )
        let halfDistance = minimumDistance / 2

        pickup = CGPoint(
            x: clamp(midpoint.x - unitX * halfDistance, min: inset, max: 1 - inset),
            y: clamp(midpoint.y - unitY * halfDistance, min: inset, max: 1 - inset)
        )
        destination = CGPoint(
            x: clamp(midpoint.x + unitX * halfDistance, min: inset, max: 1 - inset),
            y: clamp(midpoint.y + unitY * halfDistance, min: inset, max: 1 - inset)
        )
    }

    private static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt(dx * dx + dy * dy)
    }

    private static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(maxValue, Swift.max(minValue, value))
    }
}
