# Weather

Weather clone showing current conditions, hourly + 10-day forecasts, and
multi-city swipe-navigation. Data is deterministic local seed, not a live API.

- Project: `Weather.xcodeproj`
- Scheme / bundle ID: `Weather` / `com.iosworld.benchmark.weather`
- Tech: Swift + SwiftUI, no storyboard
- Deployment target: iOS 17+

Open `Weather.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/weather.py` — `read_temp`, `read_summary`, `read_detail`,
`read_high_low`, `view_city`, plus generic UI primitives.
