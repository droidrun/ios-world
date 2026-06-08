# StayFinder

Short-term-rental marketplace clone. Supports destination search, date range
selection, listing detail pages, wishlists, booking, and host messaging.

A cross-app writer: on a completed booking, StayFinder appends a confirmation
email record to the shared `mail_inbox.json` in the `group.com.iosworld.benchmark.personalsuite`
App Group — see `StayFinderMailOutboxWriter` in `StayFinder/ViewController.swift`.

- Project: `StayFinder.xcodeproj`
- Scheme / bundle ID: `StayFinder` / `com.iosworld.benchmark.stayfinder`
- Tech: Swift + SwiftUI (+ UIKit bridging), no storyboard
- Deployment target: iOS 17+
- Requires the `group.com.iosworld.benchmark.personalsuite` entitlement (`StayFinder.entitlements`).

Open `StayFinder.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/stayfinder.py` — `open_search`, `search_destination`,
`reserve_listing`, `continue_booking`, `confirm_checkout`, plus messaging tools.
