# Notes

Lightweight notes app clone. Supports creating, editing, and searching notes,
pinning favorites, and folder organization. Notes persist locally.

- Project: `Notes.xcodeproj`
- Scheme / bundle ID: `Notes` / `com.iosworld.benchmark.notes`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+

Open `Notes.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/notes.py` — `open_folder`, `list_notes`, `open_note`, `create_note`,
`edit_note_body`, `edit_note_title`, `create_folder`, `search_notes`,
`read_note`, plus `observe` / `launch`.

## Attribution

Swift source in this folder was rewritten from scratch for the benchmark;
see `ATTRIBUTIONS.md §Notes` in the repo root for the full history.
