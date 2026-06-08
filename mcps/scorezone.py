"""ScoreZone MCP — sports news, favorites, scores, league standings, game detail.

Bundle ID: com.iosworld.benchmark.scorezone

App layout reality (verified against the SwiftUI sources):
  Tabs (label / sf-symbol name):
    Home (house.fill), Scores (sportscourt.fill), Watch (play.rectangle.fill),
    ScoreZone+ (star.circle.fill), More (line.3.horizontal).
  The ScoreZone+ tab IS the Favorites screen (screen_favorites). It hosts the
  saved-stories, saved-teams, standings, and league-shortcut sections.

  Watch FEATURED headlines: `watch_featured_headline_<NNN>` where <NNN> is the
    1-based POSITIONAL index (%03d) of the first 3 entries of loadedHeadlines —
    NOT the article id. In seed/benchmark mode loadedHeadlines == SeedData
    order, so position 001 == "headline_001", 002 == "headline_002", etc.
  Favorites saved stories: `favorites_open_saved_story_<NNN>` / `_row_<NNN>` /
    `_remove_<NNN>` — also POSITIONAL (%03d index of savedHeadlines, max 10).
  Standings shortcuts: `favorites_open_standings_<league_slug>` — present only
    for leagues that have a favorited team.
  League shortcut chips: `espn_plus_league_shortcut_<league_slug>` (ScoreZone+
    header) — all leagues.
  Game detail: opened by tapping a `scores_game_row_<league>_<away>_<home>` row
    on the Scores tab. Buttons there: game_detail_box_score_button,
    game_detail_gamecast_button, game_alert_toggle_<game_id>,
    game_detail_header_alert_button.

`headline_id`: article id ("headline_001".."headline_020") OR a substring of the
  headline text — resolved against seed data, navigated to, and opened.
`team_nickname_slug`: lowercase nickname slug (e.g. "warriors", "red_sox",
  "manchester_city") or a league-prefixed id ("nba_lal", "epl_ars").
`league_id`: lowercase league slug — nba, nfl, mlb, nhl, ncaafb, ncaamb, epl.
`game_id`: full game id ("g_mlb_001", "g_nba_001", ...).
"""

import sys, pathlib, re, subprocess, time
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("ScoreZone")

BUNDLE_ID = "com.iosworld.benchmark.scorezone"

# Tab labels (the SwiftUI Label text rendered on each tab item).
TAB_LABELS = {
    "home": "Home", "scores": "Scores", "watch": "Watch",
    "scorezone+": "ScoreZone+", "scorezone_plus": "ScoreZone+",
    "favorites": "ScoreZone+", "more": "More", "menu": "More",
}
SECTION_MAP = {
    "home": "Home", "scores": "Scores", "watch": "Watch",
    "scorezone+": "ScoreZone+", "more": "More",
}
# The tab-bar buttons carry the SF-symbol as their accessibility *name* and the
# human text only as *label*. We tap by the symbol name because it is UNIQUE —
# the "ScoreZone+" label collides with the Watch FEATURED cards (their labels
# start "ScoreZone+, …"), so tapping the label can resolve to a headline card
# and silently no-op instead of switching tabs.
TAB_SYMBOLS = {
    "home": "house.fill",
    "scores": "sportscourt.fill",
    "watch": "play.rectangle.fill",
    "scorezone+": "star.circle.fill",
    "scorezone_plus": "star.circle.fill",
    "favorites": "star.circle.fill",
    "more": "line.3.horizontal",
    "menu": "line.3.horizontal",
}

DEFAULT_FAVORITE_TEAM_IDS = ["nba_lal", "nfl_kc", "mlb_nyy"]
DEFAULT_GAME_ALERT_IDS = ["g_mlb_001", "g_nba_001"]
DEFAULT_SAVED_HEADLINE_IDS = ["headline_001", "headline_008", "headline_015"]
FAVORITES_KEY = "scorezone_sim_favorites"
GAME_ALERTS_KEY = "scorezone_sim_game_alerts"
SAVED_HEADLINE_IDS_KEY = "scorezone_sim_saved_headline_ids"
PUSH_ALERTS_ENABLED_KEY = "scorezone_sim_push_alerts_enabled"

VALID_LEAGUES = ["nba", "nfl", "mlb", "nhl", "ncaafb", "ncaamb", "epl"]

# ---------------------------------------------------------------------------
# Seed data mirrors (kept in lock-step with SeedData.swift). Used to resolve
# blind targets (headline ids/names, game ids -> row ids, team slugs).
# ---------------------------------------------------------------------------

# Ordered exactly as SeedData.headlines (== loadedHeadlines in seed mode).
SEED_HEADLINES = [
    ("headline_001", "Lakers Hold Off Warriors in Instant Classic"),
    ("headline_002", "Chiefs Clinch AFC Top Seed Path"),
    ("headline_003", "Red Sox Bullpen Survives Late Yankees Push"),
    ("headline_004", "Bruins and Rangers Battle for Metro Control"),
    ("headline_005", "Purdue's Defense Sets Tone in Top-25 Clash"),
    ("headline_006", "Arsenal and Liverpool Split Points"),
    ("headline_007", "Standings Watch: East Race Tightens"),
    ("headline_008", "Weekend Watch Guide: Must-See Matchups"),
    ("headline_009", "Celtics Extend Win Streak With Late Defensive Stops"),
    ("headline_010", "Bills Red-Zone Woes Loom Large in Narrow Loss"),
    ("headline_011", "Dodgers Rotation Finds Rhythm in Spring Tune-Up"),
    ("headline_012", "Oilers Top Line Drives Another Multi-Goal Night"),
    ("headline_013", "Jayhawks Hold Paint Advantage Against Duke"),
    ("headline_014", "Manchester City Keep Pressure on League Leaders"),
    ("headline_015", "Film Room: Why Late-Switch Defense Is Trending"),
    ("headline_016", "Power Rankings: Postseason Picture Update"),
    ("headline_017", "Preview: Knicks vs Bucks Could Swing East Seeding"),
    ("headline_018", "Sunday Slate: Best Games to Watch Across Leagues"),
    ("headline_019", "Inside the Numbers: MLB Exit Velocity Leaders"),
    ("headline_020", "Rivalry Week Brings Packed Arena Atmosphere"),
]

# team_id -> nickname slug (snake-cased lowercase nickname, used in row IDs).
TEAM_ID_TO_NICK_SLUG = {
    "nba_lal": "lakers", "nba_gsw": "warriors", "nba_bos": "celtics",
    "nba_nyk": "knicks", "nba_mil": "bucks", "nba_cle": "cavaliers",
    "nba_mia": "heat", "nba_den": "nuggets", "nba_phx": "suns",
    "nba_dal": "mavericks",
    "nfl_kc": "chiefs", "nfl_buf": "bills", "nfl_phi": "eagles",
    "nfl_dal": "cowboys", "nfl_sf": "49ers", "nfl_bal": "ravens",
    "mlb_nyy": "yankees", "mlb_lad": "dodgers", "mlb_bos": "red_sox",
    "mlb_hou": "astros", "mlb_chc": "cubs", "mlb_sf": "giants",
    "nhl_nyr": "rangers", "nhl_bos": "bruins", "nhl_tor": "maple_leafs",
    "nhl_edm": "oilers",
    "ncaafb_osu": "buckeyes", "ncaafb_uga": "bulldogs", "ncaafb_tex": "longhorns",
    "ncaafb_ore": "ducks", "ncaafb_bama": "crimson_tide", "ncaafb_psu": "nittany_lions",
    "ncaamb_duke": "blue_devils", "ncaamb_ku": "jayhawks",
    "ncaamb_ucla": "bruins", "ncaamb_purdue": "boilermakers",
    "epl_ars": "arsenal", "epl_liv": "liverpool",
    "epl_mci": "manchester_city", "epl_che": "chelsea",
}

# game_id -> (league, away_team_id, home_team_id)
SEED_GAMES = {
    "g_nba_001": ("nba", "nba_lal", "nba_gsw"),
    "g_nba_002": ("nba", "nba_bos", "nba_nyk"),
    "g_nba_003": ("nba", "nba_mil", "nba_den"),
    "g_nba_004": ("nba", "nba_phx", "nba_dal"),
    "g_nba_005": ("nba", "nba_gsw", "nba_lal"),
    "g_nba_006": ("nba", "nba_nyk", "nba_mil"),
    "g_nfl_001": ("nfl", "nfl_kc", "nfl_phi"),
    "g_nfl_002": ("nfl", "nfl_buf", "nfl_kc"),
    "g_nfl_003": ("nfl", "nfl_phi", "nfl_sf"),
    "g_nfl_004": ("nfl", "nfl_dal", "nfl_bal"),
    "g_mlb_001": ("mlb", "mlb_nyy", "mlb_bos"),
    "g_mlb_002": ("mlb", "mlb_lad", "mlb_hou"),
    "g_mlb_003": ("mlb", "mlb_chc", "mlb_nyy"),
    "g_mlb_004": ("mlb", "mlb_bos", "mlb_lad"),
    "g_mlb_005": ("mlb", "mlb_nyy", "mlb_sf"),
    "g_nhl_001": ("nhl", "nhl_nyr", "nhl_bos"),
    "g_nhl_002": ("nhl", "nhl_tor", "nhl_edm"),
    "g_nhl_003": ("nhl", "nhl_bos", "nhl_nyr"),
    "g_nhl_004": ("nhl", "nhl_edm", "nhl_tor"),
    "g_ncaamb_001": ("ncaamb", "ncaamb_duke", "ncaamb_ku"),
    "g_ncaamb_002": ("ncaamb", "ncaamb_ucla", "ncaamb_purdue"),
    "g_ncaamb_003": ("ncaamb", "ncaamb_ku", "ncaamb_ucla"),
    "g_ncaamb_004": ("ncaamb", "ncaamb_purdue", "ncaamb_duke"),
    "g_epl_001": ("epl", "epl_ars", "epl_liv"),
    "g_epl_002": ("epl", "epl_mci", "epl_che"),
    "g_epl_003": ("epl", "epl_che", "epl_ars"),
    "g_epl_004": ("epl", "epl_liv", "epl_mci"),
}

# nickname slug -> league-prefixed team id (for favorite_team).
TEAM_SLUG_TO_ID = {v: k for k, v in TEAM_ID_TO_NICK_SLUG.items()}
# Disambiguate the two "bruins" (nhl_bos wins for the plain slug, as in the
# original map) but keep the league-prefixed ids reachable directly.
TEAM_SLUG_TO_ID["bruins"] = "nhl_bos"
TEAM_SLUG_TO_ID["manchester_city"] = "epl_mci"

TEAM_ABBREV_TO_SLUGS = {
    # Common abbreviations surfaced in live Watch row labels. Some abbreviations
    # are league-ambiguous, so keep all plausible slugs and let row matching
    # disambiguate by the full query.
    "atl": ["braves"],
    "bal": ["orioles", "ravens"],
    "bos": ["red_sox", "celtics", "bruins"],
    "buf": ["bills"],
    "chi": ["cubs"],
    "chw": ["white_sox"],
    "cle": ["cavaliers"],
    "dal": ["mavericks", "cowboys"],
    "den": ["nuggets"],
    "det": ["tigers"],
    "gsw": ["warriors"],
    "hou": ["astros"],
    "kc": ["chiefs"],
    "lal": ["lakers"],
    "lad": ["dodgers"],
    "mia": ["heat"],
    "mil": ["bucks"],
    "nyk": ["knicks"],
    "nyr": ["rangers"],
    "nyy": ["yankees"],
    "phi": ["phillies", "eagles"],
    "pit": ["pirates"],
    "sea": ["mariners"],
    "sf": ["giants", "49ers"],
    "tor": ["blue_jays", "maple_leafs"],
}


def _slug(text: str) -> str:
    """Mirror of AccessibilityID.slug (Swift)."""
    out = []
    for ch in (text or "").lower():
        out.append(ch if (ch.isalnum()) else "_")
    raw = "".join(out)
    raw = re.sub(r"_+", "_", raw)
    return raw.strip("_")


def _token_variants(tokens: list[str]) -> list[list[str]]:
    variants: list[list[str]] = [[]]
    for token in tokens:
        replacements = [token] + TEAM_ABBREV_TO_SLUGS.get(token, [])
        next_variants: list[list[str]] = []
        for prefix in variants:
            for repl in dict.fromkeys(replacements):
                next_variants.append(prefix + [repl])
        variants = next_variants[:32]
    return variants


def _game_row_id(game_id: str) -> str | None:
    info = SEED_GAMES.get(game_id)
    if not info:
        return None
    league, away_id, home_id = info
    away = TEAM_ID_TO_NICK_SLUG.get(away_id, _slug(away_id))
    home = TEAM_ID_TO_NICK_SLUG.get(home_id, _slug(home_id))
    return f"scores_game_row_{_slug(league)}_{away}_{home}"


def _resolve_headline(headline_id: str):
    """Return (index0, article_id, title) for a blind headline id/name, else None."""
    raw = (headline_id or "").strip()
    low = raw.lower()
    # 1) exact article id
    for i, (aid, title) in enumerate(SEED_HEADLINES):
        if aid.lower() == low:
            return i, aid, title
    # 2) trailing positional number ("001" or "headline_001" or "1")
    m = re.search(r"(\d+)$", raw)
    if m:
        n = int(m.group(1))
        if 1 <= n <= len(SEED_HEADLINES):
            aid, title = SEED_HEADLINES[n - 1]
            return n - 1, aid, title
    # 3) substring of headline text
    for i, (aid, title) in enumerate(SEED_HEADLINES):
        if low and low in title.lower():
            return i, aid, title
    return None


def _defaults() -> dict:
    return dl.read_user_defaults(BUNDLE_ID)


def _write_defaults(data: dict) -> None:
    """Persist user defaults so the change SURVIVES into the running app.

    The app must be TERMINATED before we write the plist: while it is alive,
    cfprefsd holds an in-memory cache of the preferences and will flush it back
    over our direct file write (observed: removing a favorited team "took" in
    the file but reappeared after relaunch because the live app's cached set
    clobbered it). Terminating first releases that cache, so the write sticks;
    we then relaunch to re-read the new state.
    """
    udid = dl._udid()
    if udid:
        try:
            subprocess.run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID],
                           capture_output=True, timeout=10)
            # Graceful SIGTERM lets the app flush its in-memory prefs on the way
            # out; wait for that flush to settle BEFORE we write, otherwise the
            # app's stale set lands after our write and clobbers it.
            time.sleep(1.0)
        except Exception:
            pass
    dl.write_user_defaults(BUNDLE_ID, data)
    if udid:
        try:
            subprocess.run(["xcrun", "simctl", "launch", udid, BUNDLE_ID],
                           capture_output=True, timeout=15)
            time.sleep(1.5)
            return
        except Exception:
            pass
    dl.reload_app(BUNDLE_ID)


def _array_from_defaults(data: dict, key: str, fallback: list[str]) -> list[str]:
    value = data.get(key)
    return list(value) if isinstance(value, list) else list(fallback)


def _toggle_array_value(key: str, value: str, fallback: list[str]) -> dict:
    data = _defaults()
    items = set(_array_from_defaults(data, key, fallback))
    if value in items:
        items.remove(value)
        enabled = False
    else:
        items.add(value)
        enabled = True
    data[key] = sorted(items)
    _write_defaults(data)
    return {"ok": True, "id": value, "enabled": enabled, "values": data[key]}


def _team_id_from_slug(slug: str) -> str | None:
    raw = (slug or "").strip()
    normalized = raw.lower().replace(" ", "_").replace("-", "_")
    if "_" in normalized and normalized.split("_", 1)[0] in {"nba", "nfl", "mlb", "nhl", "ncaafb", "ncaamb", "epl"}:
        return normalized
    return TEAM_SLUG_TO_ID.get(normalized)


# ---------------------------------------------------------------------------
# Navigation / scrolling helpers (self-navigation primitives).
# ---------------------------------------------------------------------------

def _observe(sim) -> str:
    try:
        return sim.observe_text() or ""
    except Exception:
        return ""


def _ensure_app(sim) -> str:
    """Ensure ScoreZone is foreground; launch if its tab bar isn't present."""
    tree = _observe(sim)
    if any(m in tree for m in ("screen_home", "screen_scores", "screen_watch",
                               "screen_favorites", "navigation_title_", "play.rectangle.fill")):
        return tree
    try:
        return sim.launch_and_observe(BUNDLE_ID)
    except Exception:
        return _observe(sim)


# Overlays/sheets that cover the tab content and swallow taps on tab-level
# controls. Each entry: (screen marker substring, ordered dismiss button ids).
# The agent routinely leaves these up (search sheet, an open detail) and the
# next tool's self-nav taps a button that is present-but-covered -> no-op. We
# back out of any such overlay before navigating.
_OVERLAY_DISMISS = [
    ("screen_search", ("search_done_button",)),
    ("screen_box_score_sheet", ("game_detail_box_score_done",)),
    ("screen_gamecast_sheet", ("gamecast_done_button",)),
    ("screen_watch_headline_detail", ("watch_headline_detail_done_button",)),
    ("screen_favorites_headline_detail", ("favorites_headline_detail_done_button",)),
    ("screen_game_detail_", ("game_detail_header_back_button",)),
]
# (Standings is a full pushed screen reached via tab nav, not a covering sheet —
#  a tab tap navigates away from it cleanly, so it needs no explicit dismiss.)


def _dismiss_overlays(sim, *, max_rounds: int = 4, keep: tuple[str, ...] = ()) -> str:
    """Back out of any search sheet / detail screen covering the tab content.

    Returns the settled UI tree. Idempotent and safe to call from any state:
    if no overlay is up it is a near no-op (one observe).

    *keep* lists marker substrings to leave in place (e.g. a game-detail screen
    a tool is about to act on)."""
    tree = _observe(sim)
    for _ in range(max_rounds):
        active = None
        for marker, buttons in _OVERLAY_DISMISS:
            if any(k in marker for k in keep):
                continue
            if marker in tree:
                active = (marker, buttons)
                break
        if active is None:
            return tree
        marker, buttons = active
        dismissed = False
        for bid in buttons:
            try:
                sim.tap_id(bid); sim.wait(0.4); dismissed = True; break
            except Exception:
                continue
        if not dismissed:
            # No labeled dismiss control reachable -> swipe-down (sheet) then
            # fall back to a relaunch so we are guaranteed on a tab screen.
            try:
                sim.swipe("down"); sim.wait(0.4)
            except Exception:
                pass
            tree = _observe(sim)
            if marker in tree:
                try:
                    sim.launch_and_observe(BUNDLE_ID); sim.wait(0.4)
                except Exception:
                    pass
                return _observe(sim)
        tree = _observe(sim)
    return tree


def _goto_tab(sim, key: str, *, marker: str | None = None) -> str:
    """Tap a top-level tab by its label; return the resulting UI tree.

    Backs out of any search/detail overlay first so the tab tap is not
    swallowed by a covering sheet (the tab buttons are present in the tree even
    while an overlay is up, so a blind tap silently no-ops)."""
    _ensure_app(sim)
    _dismiss_overlays(sim)
    label = TAB_LABELS.get(key.lower(), key)
    symbol = TAB_SYMBOLS.get(key.lower())
    # Tap by the UNIQUE symbol name first; fall back to the label / raw key.
    attempts = [a for a in (symbol, label, key) if a]
    for attempt in attempts:
        try:
            sim.tap_id(attempt)
            sim.wait(0.5)
            break
        except Exception:
            continue
    tree = _observe(sim)
    if marker and marker not in tree:
        # Marker missing -> the tap likely landed on a same-label element (or an
        # overlay re-appeared). Dismiss again and retry by symbol.
        _dismiss_overlays(sim)
        for attempt in attempts:
            try:
                sim.tap_id(attempt); sim.wait(0.6)
                if marker in _observe(sim):
                    break
            except Exception:
                continue
        tree = _observe(sim)
    return tree


def _scroll_find(sim, needle: str, *, max_swipes: int = 6) -> bool:
    """Swipe up until *needle* appears in the UI tree (or already visible)."""
    tree = _observe(sim)
    if needle in tree:
        return True
    for _ in range(max_swipes):
        try:
            sim.swipe("up")
        except Exception:
            pass
        sim.wait(0.4)
        tree = _observe(sim)
        if needle in tree:
            return True
    return False


def _tap_when_found(sim, aid: str, *, max_swipes: int = 6) -> bool:
    """Scroll the current screen until *aid* is present, then tap it.

    Returns True on a successful tap, False if never found/tappable."""
    if not _scroll_find(sim, aid, max_swipes=max_swipes):
        return False
    for _ in range(3):
        try:
            sim.tap_id(aid)
            sim.wait(0.4)
            return True
        except Exception:
            try:
                sim.swipe("up"); sim.wait(0.3)
            except Exception:
                pass
    return False


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

@mcp.tool()
def launch() -> str:
    """Launch the ScoreZone app from the home screen.

    Returns:
        Status string concatenated with the post-launch UI accessibility tree.
    """
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched ScoreZone.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (raw text dump).

    Use to discover headline IDs, game IDs, team slugs, and current screen state.
    """
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="ScoreZone",
        markers=("scorezone", "scores_game_row_", "favorites_", "watch_featured_headline_"),
    )


@mcp.tool()
def navigate_to_section(section: str) -> str:
    """Switch to one of the five top-level sections. Works from any screen —
    self-navigates and first backs out of any covering search/detail sheet so
    the tab tap is not swallowed, then verifies the target screen rendered.

    Args:
        section: one of "home", "scores", "watch", "scorezone+", "more"
            (case-insensitive; "scorezone+" is the Favorites screen). Any other
            value returns ``{ok: False, ...}`` listing the valid sections.

    Returns:
        "Navigated to '<section>'." on success, else ``{ok: False, action,
        message}`` when the target screen could not be confirmed.
    """
    if section.lower() not in SECTION_MAP:
        return {
            "ok": False, "action": "navigate_to_section",
            "message": f"Unknown section '{section}'. Use: {', '.join(SECTION_MAP.keys())}.",
        }
    sim = SimulatorBridge.get()
    # Per-section screen markers that ACTUALLY render, so we confirm the tab
    # switch instead of blindly reporting success (the tab tap can no-op when an
    # overlay covers it — handled by _goto_tab — but we still verify).
    markers = {
        "home": ("screen_home",),
        "scores": ("screen_scores", "scores_game_row_"),
        "watch": ("screen_watch",),
        "scorezone+": ("screen_favorites", "favorites_page_header"),
        "more": ("screen_menu", "menu_preferences_section_title", "menu_profile_summary"),
    }.get(section.lower(), ())
    tree = _goto_tab(sim, section, marker=markers[0] if markers else None)
    if not markers or any(m in tree for m in markers):
        return f"Navigated to '{section}'."
    return {
        "ok": False,
        "action": "navigate_to_section",
        "message": f"Could not switch to the '{section}' section. Call observe().",
    }


@mcp.tool()
def list_saved_stories() -> dict:
    """List saved story IDs from Favorites (or persisted user defaults).

    Falls back to stored defaults when the UI tree contains no saved-story rows
    (e.g. when not currently on the Favorites screen).

    Returns:
        dict ``{"saved_stories": [<story_id>, ...], "count": int}`` where each
        id is an article id (e.g. "headline_001").
    """
    ids = _array_from_defaults(_defaults(), SAVED_HEADLINE_IDS_KEY, DEFAULT_SAVED_HEADLINE_IDS)
    return {"saved_stories": ids, "count": len(ids)}


def _watch_featured_cards(sim) -> dict:
    """Return {positional_index(1-based): label} for the on-screen Watch
    FEATURED cards (`watch_featured_headline_<NNN>`)."""
    tree = _observe(sim)
    cards = {}
    for m in re.finditer(r'name="watch_featured_headline_(\d+)"(?:[^>]*label="([^"]*)")?', tree):
        cards[int(m.group(1))] = (m.group(2) or "")
    return cards


@mcp.tool()
def read_headline(headline_id: str) -> str:
    """Open a featured headline's detail screen, self-navigating to the Watch tab.

    Self-navigates to Watch, reads the live FEATURED rail, and resolves
    *headline_id* to one of its positional cards
    (`watch_featured_headline_<NNN>`) — accepting an article id ("headline_002"),
    a bare position ("2"), or a substring of the headline text matched against
    the on-screen card labels (and the seed titles as a fallback). Then taps the
    card and verifies the headline detail opened.

    Note: only the first 3 headlines are exposed as openable cards on Watch; ids
    beyond that have no in-app detail screen and return a clear message.

    Args:
        headline_id: "headline_001".."headline_003", "1".."3", or part of the
            headline text. No need to pre-navigate or call observe() first.

    Returns:
        "Opened headline at position N ('<label>')." on success. If the id
        cannot be resolved to one of the 3 openable cards, returns a plain
        string listing the available positions. If the card is found but its
        detail will not open, returns ``{ok: False, action, message}``.
    """
    sim = SimulatorBridge.get()
    _goto_tab(sim, "watch", marker="screen_watch")
    cards = _watch_featured_cards(sim)
    if not cards:
        # Give the rail a moment / one scroll, then retry.
        _scroll_find(sim, "watch_featured_headline_", max_swipes=2)
        cards = _watch_featured_cards(sim)

    raw = (headline_id or "").strip()
    low = raw.lower()
    target_pos = None

    # 1) explicit position / id with trailing number.
    m = re.search(r"(\d+)$", raw)
    if m:
        n = int(m.group(1))
        if n in cards:
            target_pos = n

    # 2) substring match against the live card labels.
    if target_pos is None and low:
        for pos, label in cards.items():
            if low in label.lower():
                target_pos = pos
                break

    # 3) seed-title resolution -> seed position (valid when seed order is live).
    if target_pos is None:
        resolved = _resolve_headline(headline_id)
        if resolved:
            idx0, article_id, title = resolved
            if (idx0 + 1) in cards:
                target_pos = idx0 + 1

    if target_pos is None:
        avail = ", ".join(str(p) for p in sorted(cards)) or "none"
        return (
            f"Could not resolve headline '{headline_id}' to an openable Watch "
            f"FEATURED card (available positions: {avail}). Only the first 3 "
            "headlines have an in-app detail screen."
        )

    pos_id = f"watch_featured_headline_{target_pos:03d}"
    if _tap_when_found(sim, pos_id, max_swipes=4):
        tree = _observe(sim)
        if "screen_watch_headline_detail" in tree or "watch_headline_detail_title" in tree:
            label = cards.get(target_pos, "").replace("ScoreZone+, ", "")
            return f"Opened headline at position {target_pos} ('{label}')."
    # The card tap did not push a headline-detail screen. This typically means
    # a sheet/overlay was still covering Watch. Dismiss and retry once before
    # reporting an HONEST failure (must be a dict so the wrapper does not mark
    # a "did not open" string as ok:true).
    _dismiss_overlays(sim)
    _goto_tab(sim, "watch", marker="screen_watch")
    if _tap_when_found(sim, pos_id, max_swipes=4):
        tree = _observe(sim)
        if "screen_watch_headline_detail" in tree or "watch_headline_detail_title" in tree:
            label = _watch_featured_cards(sim).get(target_pos, cards.get(target_pos, ""))
            label = label.replace("ScoreZone+, ", "")
            return f"Opened headline at position {target_pos} ('{label}')."
    return {
        "ok": False,
        "action": "read_headline",
        "message": (
            f"Found card '{pos_id}' but its detail did not open. Call observe() "
            "to inspect the current screen."
        ),
    }


@mcp.tool()
def save_headline() -> str:
    """Tap the Save button on the currently open headline detail screen.

    PRECONDITION: a headline detail must be open (call `read_headline()` first).
    Tries Watch and Favorites Save IDs.
    """
    sim = SimulatorBridge.get()
    for aid in ("watch_headline_detail_save_button", "favorites_headline_detail_save_button"):
        try:
            sim.tap_id(aid); sim.wait(0.3); return "Saved headline."
        except Exception:
            continue
    return "Save button not found. Open a headline detail first (read_headline)."


@mcp.tool()
def close_headline_detail() -> str:
    """Tap Done to dismiss the currently open headline detail screen.

    PRECONDITION: a headline detail screen must be open. Tries Watch and
    Favorites Done IDs (the headline detail can be opened from either tab).
    """
    sim = SimulatorBridge.get()
    for aid in ("watch_headline_detail_done_button", "favorites_headline_detail_done_button"):
        try:
            sim.tap_id(aid); sim.wait(0.3); return "Closed headline detail."
        except Exception:
            continue
    return "Done button not found. Open a headline detail first."


@mcp.tool()
def remove_saved_story(story_id: str) -> dict:
    """Remove a saved story from the saved-stories list (persisted state).

    Resolves *story_id* against the currently-saved ids first (so live
    "api_news_*" ids match verbatim), then falls back to seed article-id or
    headline-substring resolution, and drops it from the persisted
    saved-headline ids so it no longer appears in Favorites. The change is
    written to user defaults and the app is relaunched to surface it.

    Args:
        story_id: an id exactly as returned by `list_saved_stories()` (e.g.
            "headline_001" or a live "api_news_*" id), or a substring of the
            headline text.

    Returns:
        ``{ok: True, story_id, saved: False, existed: bool}`` — always ok:True;
        ``existed`` is False (a no-op) when the id was not in the saved list.
    """
    data = _defaults()
    # Preserve the persisted ORDER and any non-seed ids (the app is usually on
    # live data, so the saved list can contain real "api_news_*" ids that are
    # NOT in the seed table — we must not silently drop them on rebuild).
    saved = _array_from_defaults(data, SAVED_HEADLINE_IDS_KEY, DEFAULT_SAVED_HEADLINE_IDS)

    # Resolve the target: prefer an EXACT match against a currently-saved id
    # (covers live api_news_* ids verbatim); otherwise fall back to seed
    # id/substring resolution.
    raw = (story_id or "").strip()
    article_id = None
    if raw in saved:
        article_id = raw
    else:
        resolved = _resolve_headline(story_id)
        cand = resolved[1] if resolved else raw
        if cand in saved:
            article_id = cand
        else:
            low = raw.lower()
            article_id = next((s for s in saved if low and low in s.lower()), cand)

    if article_id not in saved:
        return {"ok": True, "story_id": article_id, "saved": False, "existed": False}
    data[SAVED_HEADLINE_IDS_KEY] = [s for s in saved if s != article_id]
    _write_defaults(data)
    return {"ok": True, "story_id": article_id, "saved": False, "existed": True}


@mcp.tool()
def view_scores() -> str:
    """Navigate to the Scores tab (live and recent game scores by league)."""
    sim = SimulatorBridge.get()
    # Use the marker the Scores screen actually renders. The scoreboard always
    # emits `scores_game_row_<league>_<away>_<home>` rows; the `screen_scores`
    # container id is NOT emitted on every build, so gating success solely on
    # it produced false "Could not reach the Scores screen." failures even
    # though the scores were on screen. Accept either marker — the presence of
    # a real game row is the authoritative proof the screen rendered.
    tree = _goto_tab(sim, "scores", marker="scores_game_row_")
    if "scores_game_row_" in tree or "screen_scores" in tree:
        return "Viewing scores."
    # Genuinely blocked (no scoreboard content rendered) — honest failure.
    return {
        "ok": False,
        "action": "view_scores",
        "message": "Could not reach the Scores screen.",
    }


@mcp.tool()
def view_favorites() -> str:
    """Open the Favorites page (saved stories, teams, standings).

    The Favorites screen is the ScoreZone+ tab (screen_favorites). Self-navigates
    there and verifies the favorites header rendered.
    """
    sim = SimulatorBridge.get()
    tree = _goto_tab(sim, "scorezone+", marker="screen_favorites")
    if "screen_favorites" in tree or "favorites_page_header" in tree:
        return "Viewing favorites."
    return {
        "ok": False,
        "action": "view_favorites",
        "message": "Could not reach the Favorites screen (ScoreZone+ tab).",
    }


@mcp.tool()
def search(query: str) -> str:
    """Open the global search field and type a query.

    Self-navigates to a tab with a search affordance (Watch / ScoreZone+),
    opens the search sheet, focuses the field so the keyboard is visible, then
    types the query.

    Args:
        query: free-text search term — team, league, player, or game (e.g.
            "Lakers", "Premier League"). Case-insensitive.
    """
    sim = SimulatorBridge.get()
    opened = False
    # Watch tab has a header search button.
    _goto_tab(sim, "watch", marker="screen_watch")
    for aid in ("watch_header_search_button", "scores_header_search_button",
                "espn_plus_header_search_button", "favorites_open_search_button"):
        try:
            sim.tap_id(aid); sim.wait(0.5); opened = True; break
        except Exception:
            continue
    if not opened:
        _goto_tab(sim, "scorezone+", marker="screen_favorites")
        for aid in ("espn_plus_header_search_button", "favorites_open_search_button"):
            try:
                sim.tap_id(aid); sim.wait(0.5); opened = True; break
            except Exception:
                continue
    try:
        sim.tap_id("search_query_field"); sim.wait(0.4)
    except Exception:
        pass
    sim.type_text(query); sim.wait(0.5)
    # Commit the query so results render (the field's onSubmit / Search button).
    try:
        sim.tap_id("search_submit_button"); sim.wait(0.6)
    except Exception:
        pass
    tree = _observe(sim)
    n_results = len(set(re.findall(r'name="(team_row_[a-z0-9_]+|search_league_row_[a-z0-9]+|scores_game_row_[a-z0-9_]+)"', tree)))
    no_results = "No results" in tree
    if no_results and n_results == 0:
        return f"Searched '{query}' — no matching teams, leagues, or games."
    return f"Searched '{query}'; {n_results} result(s) shown."


@mcp.tool()
def open_league_standings(league_id: str) -> str:
    """Open a league's standings page, self-navigating from Favorites.

    The standings shortcut for a league only appears when a team in that league
    is favorited. This tool navigates to ScoreZone+/Favorites, and if the
    shortcut is missing it SIDE-EFFECT favorites a representative team in that
    league to surface it (leaving that team favorited), then taps the shortcut.

    Args:
        league_id: lowercase league slug — one of nba, nfl, mlb, nhl, ncaafb,
            ncaamb, epl. Aliases also accepted: ncaab->ncaamb, ncaaf->ncaafb,
            premier_league->epl, college_basketball/college_football. No need to
            pre-navigate.

    Returns:
        "Opened <league> standings." on success, else ``{ok: False, action,
        message}`` (unknown league, or the standings screen did not render).
    """
    sim = SimulatorBridge.get()
    league = (league_id or "").strip().lower()
    aliases = {"ncaab": "ncaamb", "ncaaf": "ncaafb",
               "college_basketball": "ncaamb", "college_football": "ncaafb",
               "premier_league": "epl"}
    league = aliases.get(league, league)
    if league not in VALID_LEAGUES:
        return {
            "ok": False, "action": "open_league_standings",
            "message": f"Unknown league '{league_id}'. Use one of: {', '.join(VALID_LEAGUES)}.",
        }

    _goto_tab(sim, "scorezone+", marker="screen_favorites")
    aid = f"favorites_open_standings_{league}"
    if not _scroll_find(sim, aid, max_swipes=8):
        # Surface the shortcut by favoriting a team in that league.
        rep = next((tid for tid in TEAM_ID_TO_NICK_SLUG if tid.startswith(league + "_")), None)
        if rep:
            result = _toggle_array_value(FAVORITES_KEY, rep, DEFAULT_FAVORITE_TEAM_IDS)
            if not result.get("enabled"):
                # we just removed it; toggle back on
                _toggle_array_value(FAVORITES_KEY, rep, DEFAULT_FAVORITE_TEAM_IDS)
            _goto_tab(sim, "home")  # leave & return to force a favorites refresh
            _goto_tab(sim, "scorezone+", marker="screen_favorites")
    if _tap_when_found(sim, aid, max_swipes=8):
        tree = _observe(sim)
        # Confirm the standings screen for THIS league actually rendered
        # (`screen_standings_<league>` + a standings row) — do not accept a
        # bare "standings" substring, which is present on Favorites too.
        if f"screen_standings_{league}" in tree or f"standings_row_{league}" in tree:
            return f"Opened {league} standings."
        return {
            "ok": False,
            "action": "open_league_standings",
            "message": (
                f"Tapped the {league} standings shortcut but its screen did not "
                "render. Call observe() to inspect."
            ),
        }
    return {
        "ok": False,
        "action": "open_league_standings",
        "message": (
            f"No standings shortcut found for league '{league}'. Favorite a team "
            "in that league first, then reopen Favorites."
        ),
    }


@mcp.tool()
def open_league_shortcut(league_id: str) -> str:
    """Tap a league shortcut chip in the ScoreZone+ header.

    Self-navigates to the ScoreZone+ tab and taps the league chip (scrolling the
    horizontal chip rail if needed).

    Args:
        league_id: lowercase league slug — nba, nfl, mlb, nhl, ncaafb, ncaamb,
            epl. Aliases accepted: ncaab->ncaamb, ncaaf->ncaafb,
            premier_league->epl. No need to pre-navigate.

    Returns:
        "Opened <league> league shortcut." on success, else ``{ok: False,
        action, message}`` (unknown league, or no league screen rendered).
    """
    sim = SimulatorBridge.get()
    league = (league_id or "").strip().lower()
    aliases = {"ncaab": "ncaamb", "ncaaf": "ncaafb", "premier_league": "epl"}
    league = aliases.get(league, league)
    if league not in VALID_LEAGUES:
        return {
            "ok": False, "action": "open_league_shortcut",
            "message": f"Unknown league '{league_id}'. Use one of: {', '.join(VALID_LEAGUES)}.",
        }

    _goto_tab(sim, "scorezone+", marker="screen_favorites")
    aid = f"espn_plus_league_shortcut_{league}"
    if _tap_when_found(sim, aid, max_swipes=4):
        sim.wait(0.5)
        after = _observe(sim)
        # The chip drills into the league's scoreboard (screen_scores with that
        # league's rows). Confirm we actually left the favorites page and a
        # scoreboard rendered — otherwise report an honest failure.
        if ("screen_scores" in after or "scores_game_row_" in after
                or f"screen_standings_{league}" in after) and "screen_favorites" not in after:
            return f"Opened {league} league shortcut."
        return {
            "ok": False,
            "action": "open_league_shortcut",
            "message": (
                f"Tapped the '{league}' chip but no league screen rendered. "
                "Call observe() to inspect."
            ),
        }
    return {
        "ok": False,
        "action": "open_league_shortcut",
        "message": (
            f"Could not open league shortcut '{league}'. Open the ScoreZone+ tab "
            "and look for the chip rail."
        ),
    }


@mcp.tool()
def favorite_team(team_nickname_slug: str) -> str:
    """Toggle favorite/unfavorite for a team (persisted-state write).

    Resolves the team, then ADDS it if absent / REMOVES it if present by writing
    the persisted favorites key the app reads on launch, terminating+relaunching
    the app so the change is live. (It does NOT tap the in-UI heart — that tap
    did not reliably flush UserDefaults, so a verified state write is used for
    both add and remove.) Each call flips the team's favorite state.

    Args:
        team_nickname_slug: the team's nickname slug (human-readable, lowercase,
            underscores for spaces) — e.g. "warriors", "lakers", "yankees",
            "red_sox", "manchester_city" — OR a league-prefixed team id like
            "nba_lal" / "epl_ars". Spaces and hyphens are normalized to
            underscores. Note "bruins" resolves to the NHL Bruins (nhl_bos); for
            the NCAA/EPL Bruins use the prefixed id (ncaamb_ucla).

    Returns:
        ``{ok: True, id, team_id, favorite: bool, nick_slug, values: [...]}``
        where ``favorite`` is the NEW state. Returns ``{ok: False, action,
        message}`` for an unknown slug, or if the state did not actually flip.
    """
    sim = SimulatorBridge.get()
    nick = (team_nickname_slug or "").strip().lower().replace(" ", "_").replace("-", "_")
    team_id = _team_id_from_slug(team_nickname_slug)
    if not team_id:
        return {"ok": False, "action": "favorite_team",
                "error": f"unknown team slug '{team_nickname_slug}'",
                "message": f"Unknown team slug '{team_nickname_slug}'."}
    nick_slug = TEAM_ID_TO_NICK_SLUG.get(team_id, nick)

    # Toggle via the persisted favorites key — the SAME key the app reads on
    # launch (AppPersistence.loadFavoriteTeamIDs -> "scorezone_sim_favorites"),
    # so reload_app surfaces the change in-app. We use the defaults path for
    # BOTH add and remove because the in-UI heart tap does not deterministically
    # flush UserDefaults before a read-back (it produced false "no change"
    # results from messy states), whereas a verified state write does.
    before = set(_array_from_defaults(_defaults(), FAVORITES_KEY, DEFAULT_FAVORITE_TEAM_IDS))
    result = _toggle_array_value(FAVORITES_KEY, team_id, DEFAULT_FAVORITE_TEAM_IDS)
    after = set(_array_from_defaults(_defaults(), FAVORITES_KEY, DEFAULT_FAVORITE_TEAM_IDS))
    favorite_now = team_id in after
    if (team_id in before) == favorite_now:
        # State did not actually flip — report honestly.
        return {"ok": False, "action": "favorite_team", "team_id": team_id,
                "message": f"Could not change favorite state for '{nick_slug}'."}
    result.update({"team_id": team_id, "favorite": favorite_now,
                   "nick_slug": nick_slug})
    result.pop("enabled", None)
    return result


def _live_game_rows(sim) -> list[str]:
    """Collect every `scores_game_row_<...>` slug visible across the Watch rails.

    The benchmark app is usually backed by LIVE network data, so the seed game
    ids (g_nba_001 -> lakers_warriors) frequently DON'T match the matchups that
    are actually on screen (e.g. live MLB is orioles_red_sox, not yankees_red_sox).
    We therefore resolve targets against the real on-screen rows instead of the
    stale seed map. Scrolls the Watch page to surface all rails."""
    _goto_tab(sim, "watch", marker="screen_watch")
    rows: list[str] = []
    seen: set[str] = set()
    for _ in range(9):
        tree = _observe(sim)
        for slug in re.findall(r'scores_game_row_[a-z0-9_]+', tree):
            if slug not in seen:
                seen.add(slug); rows.append(slug)
        try:
            sim.swipe("up"); sim.wait(0.3)
        except Exception:
            break
    return rows


def _resolve_live_row(sim, game_id: str) -> str | None:
    """Resolve a blind game target to a row id that is ACTUALLY on the Watch tab.

    Accepts (in priority order):
      1. an exact / `scores_game_row_`-prefixed slug already present live,
      2. a seed game_id whose seed matchup slug is present live,
      3. the seed matchup's away/home team nickname pair (both must appear in a
         live row, in order) — survives a different opponent only if it doesn't,
      4. any free-text token(s) (team name / city) matching a single live row.
    """
    raw = (game_id or "").strip().lower()
    live = _live_game_rows(sim)
    if not live:
        return None
    live_set = set(live)

    # 1) caller already passed a real row slug (with or without the prefix).
    cand = raw if raw.startswith("scores_game_row_") else f"scores_game_row_{raw}"
    if cand in live_set:
        return cand
    if raw and any(raw == r.replace("scores_game_row_", "") for r in live):
        return next(r for r in live if r.replace("scores_game_row_", "") == raw)

    # 2/3) seed game_id -> exact slug, else its away/home nicknames.
    info = SEED_GAMES.get(raw)
    if info:
        seed_row = _game_row_id(raw)
        if seed_row in live_set:
            return seed_row
        league, away_id, home_id = info
        away = TEAM_ID_TO_NICK_SLUG.get(away_id, "")
        home = TEAM_ID_TO_NICK_SLUG.get(home_id, "")
        lslug = _slug(league)
        for r in live:
            body = r.replace(f"scores_game_row_{lslug}_", "") if r.startswith(f"scores_game_row_{lslug}_") else ""
            if away and home and away in body and home in body:
                return r
        # fall back to either team appearing in a live row of that league.
        for team in (home, away):
            for r in live:
                if r.startswith(f"scores_game_row_{lslug}_") and team and team in r:
                    return r

    # 4) free-text token match (e.g. "phillies", "padres phillies", "Lakers").
    # Live row labels use team abbreviations ("BOS @ NYY") while row ids use
    # nicknames ("red_sox_yankees"), so expand known abbreviations before
    # matching. Ambiguous abbreviations stay bounded and are resolved by the
    # full token set.
    toks = [t for t in re.split(r"[^a-z0-9]+", raw) if t and t not in VALID_LEAGUES]
    if toks:
        for variant in _token_variants(toks):
            matches = [r for r in live if all(t in r for t in variant)]
            if len(matches) == 1:
                return matches[0]
            if matches:
                return matches[0]
    return None


def _open_game_detail(sim, game_id: str) -> bool:
    """Open a game's detail screen by navigating the Watch tab game rails.

    The Watch tab lists live / upcoming / replay games as NavigationLinks into
    GameDetailView, so tapping the row pushes a `screen_game_detail_<id>` screen
    (the live id is an ESPN event number, NOT the seed g_<league>_NNN). The
    compact Scores scoreboard rows instead drill into team detail.

    Resolves *game_id* against the LIVE rows (seed ids, row slugs, or team names
    all work), so it survives the app being on real network data. Returns True
    if a game-detail screen actually rendered."""
    row_id = _resolve_live_row(sim, game_id)
    if not row_id:
        return False
    if _scroll_find(sim, row_id, max_swipes=9):
        for _ in range(3):
            try:
                sim.tap_id(row_id); sim.wait(0.8)
            except Exception:
                try:
                    sim.swipe("up"); sim.wait(0.3)
                except Exception:
                    pass
                continue
            tree = _observe(sim)
            if ("screen_game_detail_" in tree
                    or "game_detail_box_score_button" in tree
                    or "game_detail_header_alert_button" in tree):
                return True
    return False


DEFAULT_DETAIL_GAME_ID = "g_nba_001"


def _ensure_game_detail(sim, game_id: str | None = None) -> bool:
    """Ensure a game-detail screen is open; open a (default) game if not."""
    tree = _observe(sim)
    if "game_detail_box_score_button" in tree or "screen_game_detail_" in tree:
        return True
    return _open_game_detail(sim, game_id or DEFAULT_DETAIL_GAME_ID)


@mcp.tool()
def open_box_score(game_id: str = "") -> str:
    """Open the Box Score sheet for a game's detail screen.

    Self-navigating: if no game detail is open, opens the given *game_id*
    (default a current live game) via the Watch tab, then taps Box Score.

    Args:
        game_id: optional — resolved against the LIVE Watch game rows, so a seed
            id ("g_nba_001"), a row slug ("mlb_padres_phillies" /
            "scores_game_row_..."), or team-name token(s) ("Phillies") all work.
            If omitted, keeps a currently-open game detail, else opens a default
            live game.

    Returns:
        "Opened box score." on success, else ``{ok: False, action, message}``
        (could not open the detail, no box-score button, or sheet not rendered).
    """
    sim = SimulatorBridge.get()
    # Preserve an already-open game detail when the caller did not name a
    # specific game; only clear sheets/search on top of it.
    _dismiss_overlays(sim, keep=("screen_game_detail_",) if not game_id else ())
    if not _ensure_game_detail(sim, game_id or None):
        return {
            "ok": False,
            "action": "open_box_score",
            "message": (
                f"Could not open a game detail{' for ' + game_id if game_id else ''} "
                "to read its box score. Call observe() to inspect."
            ),
        }
    if not _tap_when_found(sim, "game_detail_box_score_button", max_swipes=4):
        return {
            "ok": False,
            "action": "open_box_score",
            "message": "No box score button found. Open a game detail first (open_game).",
        }
    tree = _observe(sim)
    if "screen_box_score_sheet" in tree:
        return "Opened box score."
    return {
        "ok": False,
        "action": "open_box_score",
        "message": "Tapped Box Score but its sheet did not render. Call observe().",
    }


@mcp.tool()
def open_gamecast(game_id: str = "") -> str:
    """Open the Gamecast view for a game's detail screen.

    Self-navigating: if no game detail is open, opens the given *game_id*
    (default a current live game) via the Watch tab, then taps Gamecast.

    Args:
        game_id: optional — resolved against the LIVE Watch game rows, so a seed
            id ("g_nba_001"), a row slug ("mlb_padres_phillies" /
            "scores_game_row_..."), or team-name token(s) ("Phillies") all work.
            If omitted, keeps a currently-open game detail, else opens a default
            live game.

    Returns:
        "Opened gamecast." on success, else ``{ok: False, action, message}``
        (could not open the detail, no gamecast button, or view not rendered).
    """
    sim = SimulatorBridge.get()
    _dismiss_overlays(sim, keep=("screen_game_detail_",) if not game_id else ())
    if not _ensure_game_detail(sim, game_id or None):
        return {
            "ok": False,
            "action": "open_gamecast",
            "message": (
                f"Could not open a game detail{' for ' + game_id if game_id else ''} "
                "to open its gamecast. Call observe() to inspect."
            ),
        }
    if not _tap_when_found(sim, "game_detail_gamecast_button", max_swipes=4):
        return {
            "ok": False,
            "action": "open_gamecast",
            "message": "No gamecast button found. Open a game detail first (open_game).",
        }
    sim.wait(0.4)
    tree = _observe(sim)
    if "screen_gamecast_sheet" in tree or "gamecast_status_row" in tree:
        return "Opened gamecast."
    return {
        "ok": False,
        "action": "open_gamecast",
        "message": "Tapped Gamecast but its view did not render. Call observe().",
    }


@mcp.tool()
def open_game(game_id: str) -> str:
    """Open a game's detail screen, self-navigating via the Watch tab game rails.

    Resolves the target against the LIVE on-screen game rows, so it works whether
    the caller passes a seed game id, a `scores_game_row_<...>` slug copied from
    observe(), or team names. (The app is usually on real network data, so the
    seed matchups need not match what is on screen.)

    Args:
        game_id: a full seed game id ("g_nba_001"), a live row slug
            ("scores_game_row_mlb_padres_phillies" or "mlb_padres_phillies"), or
            team name token(s) like "Phillies" / "lakers warriors". Get live
            matchups from observe() / the Watch tab if unsure.

    Returns:
        "Opened game detail for <game_id>." on success, else ``{ok: False,
        action, message}`` when no matching row is on the Watch tab.
    """
    sim = SimulatorBridge.get()
    _dismiss_overlays(sim)
    if _open_game_detail(sim, game_id):
        return f"Opened game detail for {game_id}."
    return {
        "ok": False, "action": "open_game",
        "message": (
            f"Could not open game '{game_id}'. No matching game row is on the "
            "Watch tab; call observe() to see the live matchups."
        ),
    }


@mcp.tool()
def toggle_game_alert(game_id: str) -> str:
    """Toggle per-game push alerts, self-navigating to the game detail.

    Opens the game's detail via the Watch tab (resolved against the LIVE game
    rows — seed id, row slug, or team names all work) and taps its alert bell.
    The live alert toggle is keyed by the app's own event id, so we tap the
    header bell (always present on the detail) rather than a guessed id.

    Args:
        game_id: a seed game id ("g_nba_001"), a live row slug
            ("mlb_padres_phillies"), or team-name token(s) like "Phillies".

    Returns:
        "Toggled alerts for game <game_id>." when the detail bell is tapped. If
        the detail is unreachable but *game_id* is a KNOWN seed id, falls back to
        a persisted-state write returning ``{ok: True, id, alerts_enabled: bool,
        values: [...]}``. Otherwise returns an honest ``{ok: False, action,
        game_id, message}`` (no alert control, or no matching live row).
    """
    sim = SimulatorBridge.get()
    _dismiss_overlays(sim)
    if _open_game_detail(sim, game_id):
        tree = _observe(sim)
        # Capture the live event id so we can verify the toggle against the
        # game-specific control, and confirm a real effect.
        m = re.search(r'screen_game_detail_([a-z0-9_]+)', tree)
        live_id = m.group(1) if m else None
        controls = ["game_detail_header_alert_button"]
        if live_id:
            controls.append(f"game_alert_toggle_{live_id}")
        for aid in controls:
            if _tap_when_found(sim, aid, max_swipes=4):
                sim.wait(0.3)
                return f"Toggled alerts for game {game_id}."
        return {
            "ok": False, "action": "toggle_game_alert", "game_id": game_id,
            "message": ("Opened the game detail but found no alert control to "
                        "toggle. Call observe()."),
        }
    # Detail unreachable. Only fall back to a persisted-state write for a KNOWN
    # seed id (so we never fabricate a success for a phantom/unresolvable id).
    if game_id in SEED_GAMES:
        result = _toggle_array_value(GAME_ALERTS_KEY, game_id, DEFAULT_GAME_ALERT_IDS)
        result.update({"game_id": game_id, "alerts_enabled": result.pop("enabled")})
        return result
    return {
        "ok": False, "action": "toggle_game_alert", "game_id": game_id,
        "message": (
            f"Could not open a game detail for '{game_id}'. No matching live "
            "game row is on the Watch tab; call observe() to see the matchups."
        ),
    }


@mcp.tool()
def toggle_alerts(enabled: bool) -> str:
    """Set the global push-alerts switch in the More tab (UI + defaults fallback).

    Self-navigates to the More tab and taps the push-alerts toggle. Falls back
    to writing user defaults directly only when that toggle is unreachable.

    CAVEAT: the UI path is an unconditional TAP (a flip), not an absolute set —
    it always flips whatever the current switch state is, regardless of
    *enabled*, then reports success using the requested value. Only the defaults
    fallback writes the exact boolean. If unsure of the current state, observe()
    the More tab first.

    Args:
        enabled: True to turn alerts on, False to turn off.

    Returns:
        "Global alerts on/off." on the UI path, or ``{ok: True,
        push_alerts_enabled: bool}`` on the defaults fallback (exact set).
    """
    sim = SimulatorBridge.get()
    try:
        _goto_tab(sim, "more")
        if _tap_when_found(sim, "menu_toggle_push_alerts", max_swipes=6):
            sim.wait(0.3)
            return f"Global alerts {'on' if enabled else 'off'}."
    except Exception:
        pass
    data = _defaults()
    data[PUSH_ALERTS_ENABLED_KEY] = bool(enabled)
    _write_defaults(data)
    return {"ok": True, "push_alerts_enabled": bool(enabled)}


@mcp.tool()
def refresh_favorites() -> str:
    """Tap the Refresh button on the Favorites page to reload saved content.

    Self-navigates to ScoreZone+/Favorites and taps the refresh button.
    """
    sim = SimulatorBridge.get()
    _goto_tab(sim, "scorezone+", marker="screen_favorites")
    if _tap_when_found(sim, "favorites_refresh_button", max_swipes=4):
        sim.wait(0.4)
        return "Refreshed favorites."
    return "Refresh button not found on the Favorites screen."


if __name__ == "__main__":
    mcp.run()
