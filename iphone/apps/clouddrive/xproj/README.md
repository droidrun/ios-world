# CloudDrive

Cloud-file-storage clone. Supports folders, search, starred/recent/shared
views, file movement, rename, trash, and activity log.

- Project: `CloudDrive.xcodeproj`
- Scheme / bundle ID: `CloudDrive` / `com.iosworld.benchmark.clouddrive`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+

Open `CloudDrive.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/clouddrive.py` — `open_folder`, `open_file`, `create_folder`,
`move_file`, `rename_file`, `trash_file`, `star_file`, `search_files`,
`view_starred` / `_shared` / `_recent` / `_activity`.
