# DineSpot

Restaurant-discovery + reservation clone. 74 restaurants across 7 cities
(SF, NY, LA, Chicago, Boston, Seattle, Catalina Island) with 30+
neighborhoods. All TasteRank restaurants are mirrored here for cross-app
consistency. Supports city + cuisine search, multi-word queries with auto
city-switch, restaurant detail pages with reservation slots, party-size
selection, booking notes, rewards, and a reservations list.

A cross-app writer: on reservation confirm, DineSpot appends a confirmation
email to the shared `mail_inbox.json` in `group.com.iosworld.benchmark.personalsuite` — see
`DiningMailOutboxWriter` in `DineSpot/ViewModels/DiningStore.swift`.

- Project: `DineSpot.xcodeproj`
- Scheme / bundle ID: `DineSpot` / `com.iosworld.benchmark.dinespot`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+
- Requires the `group.com.iosworld.benchmark.personalsuite` entitlement (`DineSpot.entitlements`).

Project layout:

```
DineSpot/
├── Models/
├── ViewModels/
├── Views/
├── Persistence/
├── Resources/
├── Utilities/
└── DineSpotApp.swift
```

Open `DineSpot.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/dinespot.py` — `search_restaurants`, `set_city`, `set_party_size`,
`view_restaurant`, `make_reservation`, `view_reservations`, `view_rewards`.
