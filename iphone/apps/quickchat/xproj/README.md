# QuickChat

1:1 and group messaging clone. Supports threads, read receipts, and in-chat
media attachments. Used for conversational tasks and notification-style flows.

- Project: `QuickChat.xcodeproj`
- Scheme / bundle ID: `QuickChat` / `com.iosworld.benchmark.quickchat`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+

Open `QuickChat.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/quickchat.py` — `navigate_to_tab`, `search_messages`, plus generic
tap / swipe / type_text / observe primitives for open chat threads.
