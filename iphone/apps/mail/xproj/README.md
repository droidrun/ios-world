# Mail

Mail client clone. Reads a shared mailbox populated by other benchmark apps
(SplitPay payments, DineSpot reservations, MegaMart orders, etc.) via the
`group.com.iosworld.benchmark.personalsuite` App Group — see `Services/MailSharedInbox*`.

This is the canonical cross-app sink: any writer app that calls
`MailOutboxWriter.record*` appends a record that surfaces here as a mail row.

- Project: `Mail.xcodeproj`
- Scheme / bundle ID: `Mail` / `com.iosworld.benchmark.mail`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+
- Requires the `group.com.iosworld.benchmark.personalsuite` entitlement (see `Mail.entitlements`).

Open `Mail.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/mail.py` — generic UI primitives (tap, swipe, type_text, observe).
