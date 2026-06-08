# MegaMart

E-commerce marketplace clone. Supports product browse/search, product detail
with variants, cart + save-for-later, delivery option selection, gift wrapping,
checkout, order history, and returns.

A cross-app writer: on a completed checkout, MegaMart appends an order-
confirmation email to the shared `mail_inbox.json` in
`group.com.iosworld.benchmark.personalsuite` — see `MegaMartMailOutboxWriter` in
`MegaMart/ViewModels/MegaMartStore.swift`.

- Project: `MegaMart.xcodeproj`
- Scheme / bundle ID: `MegaMart` / `com.iosworld.benchmark.megamart`
- Tech: Swift + SwiftUI only
- Deployment target: iOS 17+
- Requires the `group.com.iosworld.benchmark.personalsuite` entitlement (`MegaMart.entitlements`).
- Data: seeded local catalog + bundled `MegaMart/Resources/catalog_snapshot.json`
- Persistence: local `UserDefaults` state with an in-app reset flow.

Open `MegaMart.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/megamart.py` — `search_products`, `view_product`, `add_to_cart`,
`adjust_quantity`, `view_cart`, `checkout`, `view_orders`, `save_item`.
