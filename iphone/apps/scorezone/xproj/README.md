# ScoreZone

Sports-scores + news clone. Supports multi-league scoreboards, game detail +
gamecast, headlines, favorites, and league/section navigation.

- Project: `ScoreZone.xcodeproj`
- Scheme / bundle ID: `ScoreZone` / `com.iosworld.benchmark.scorezone`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+

Project layout:

```
ScoreZone/
├── Models/
├── ViewModels/
├── Views/
├── Networking/
├── Persistence/
├── Resources/
├── Utilities/
└── ScoreZoneApp.swift
```

Open `ScoreZone.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/scorezone.py` — `navigate_to_section`, `view_scores`,
`view_favorites`, `search`, `read_headline`, `save_headline`, `toggle_alerts`.
