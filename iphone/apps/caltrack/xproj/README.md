# CalTrack

Offline calorie and fitness tracking clone. Supports food logging (search +
custom entries), exercise logging, weight tracking, and daily/weekly progress
views. All data is seeded + persisted locally.

- Project: `CalTrack.xcodeproj`
- Scheme / bundle ID: `CalTrack` / `com.iosworld.benchmark.caltrack`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+

Project layout:

```
CalTrack/
├── Models/
├── ViewModels/
├── Views/
├── Persistence/
├── Resources/
├── Utilities/
└── CalTrackApp.swift
```

Open `CalTrack.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/caltrack.py` — `log_food`, `log_exercise`, `log_weight`,
`view_daily_summary`, `view_progress`, `view_goals`, `view_profile`.
