# CloudDocs

Cloud-hosted rich-text document editor clone. Supports opening, editing,
renaming, searching documents, and basic formatting (bold/italic/underline).

- Project: `CloudDocs.xcodeproj`
- Scheme / bundle ID: `CloudDocs` / `com.iosworld.benchmark.clouddocs`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+

Open `CloudDocs.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/clouddocs.py` — `open_document`, `edit_document`, `rename_file`,
`search_documents`, `toggle_bold` / `_italic` / `_underline`, `view_recent`.
