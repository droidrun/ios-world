# CityRide

Rideshare clone. Supports destination search, ride-type selection (economy /
comfort / premium), saved places, in-ride cancellation + rating, trip history,
and wallet/payment management.

A cross-app writer: on a completed ride, CityRide appends a receipt email to
the shared `mail_inbox.json` in `group.com.iosworld.benchmark.personalsuite` — see
`CityRideMailOutboxWriter` in `CityRide/ViewModels/CityRideSimStore.swift`.

- Project: `CityRide.xcodeproj`
- Scheme / bundle ID: `CityRide` / `com.iosworld.benchmark.cityride`
- Tech: Swift + SwiftUI, no storyboard, no runtime network calls
- Deployment target: iOS 17+
- Requires the `group.com.iosworld.benchmark.personalsuite` entitlement (`CityRide.entitlements`).

Deterministic local seed data, with optional snapshot fares at
`CityRide/Resources/fare_snapshot.json`.

Open `CityRide.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/cityride.py` — `request_ride`, `select_ride_type`, `confirm_ride`,
`cancel_ride`, `rate_trip`, `view_trip_history`, `view_wallet`.
