# SkyTrip

Airline-app clone. Supports flight search, booking, check-in, boarding pass
display, trip management, bag tracking, wallet, alerts, and airport/aircraft
info subsections.

A cross-app writer: on booking confirmation + seat upgrades, SkyTrip appends
email records to the shared `mail_inbox.json` in `group.com.iosworld.benchmark.personalsuite`
— see `SkyTripMailOutboxWriter` in `SkyTrip/Persistence/AppStore.swift`.

- Project: `SkyTrip.xcodeproj`
- Scheme / bundle ID: `SkyTrip` / `com.iosworld.benchmark.skytrip`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+
- Requires the `group.com.iosworld.benchmark.personalsuite` entitlement (`SkyTrip.entitlements`).

Open `SkyTrip.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/skytrip.py` — `search_flights`, `check_flight_status`, `check_in`,
`view_boarding_pass`, `view_trips`, `view_wallet`, `track_bags`,
`view_notifications`.
