# CloudSlides

Cloud-hosted presentation editor clone. Supports opening presentations, slide
navigation, add/delete/duplicate slides, and editing titles + body text.

- Project: `CloudSlides.xcodeproj`
- Scheme / bundle ID: `CloudSlides` / `com.iosworld.benchmark.cloudslides`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+

Open `CloudSlides.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/cloudslides.py` — `open_presentation`, `navigate_to_slide`,
`add_slide`, `delete_slide`, `duplicate_slide`, `edit_slide`,
`set_slide_title`, `set_slide_body`, `search_presentations`, `view_recent`.
