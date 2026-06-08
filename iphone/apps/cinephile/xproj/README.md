# Cinephile

Movie-discovery clone. Supports browsing trending/popular/upcoming titles,
search, detail pages with cast + similar titles, and a personal watchlist.
Data is seeded locally; no TMDB network calls at runtime.

- Project: `Cinephile/Cinephile.xcodeproj`
- Scheme / bundle ID: `Cinephile` / `com.iosworld.benchmark.cinephile`
- Tech: Swift + SwiftUI (Flux-style state container, pure SwiftUI views)
- Deployment target: iOS 17+

Open `Cinephile/Cinephile.xcodeproj` in Xcode and run on an iOS Simulator.

MCP: `mcps/cinephile.py` — generic `tap`, `swipe`, `type_text`, `observe`.

## Attribution

The UI and state-management patterns here are descended from
[MovieSwiftUI](https://github.com/Dimillian/MovieSwiftUI) (MIT). The
upstream MIT license is preserved at `LICENSE` in this directory.
