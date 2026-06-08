"""TasteRank MCP — restaurant discovery, reviews, ranked lists, and leaderboards.

Bundle ID: com.iosworld.benchmark.tasterank

ID-naming conventions (see TasteRank/Views/):
  Tabs: tasterank_tab_<feed|lists|leaderboard|profile>
  Rows: row_name_<restaurant_id>, row_meta_<id>, row_photo_<id>,
        row_stats_<id>, row_visited_<id>
  Cards: card_name_<id>, card_meta_<id>, card_photo_<id>, card_stats_<id>
  Filters: filters_cuisine_<id>, filters_price_<level>,
           filters_distance_picker, filters_visited_picker,
           filters_open_now, filters_done, filters_reset

`restaurant_id` is the trailing slug after `row_name_`/`card_name_` (e.g.
`r_001`, `osteria_luna`). `cuisine_id` is a lowercase cuisine slug
(e.g. `italian`, `japanese`). `level` is the integer price tier 1..4.
"""

import sys, pathlib, re, json, uuid, html
from datetime import datetime, timezone
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("TasteRank")

BUNDLE_ID = "com.iosworld.benchmark.tasterank"

_TAB_MAP = {
    "feed": "tasterank_tab_feed",
    "lists": "tasterank_tab_your_lists",
    "your_lists": "tasterank_tab_your_lists",
    "want_to_try": "tasterank_tab_your_lists",
    "want to try": "tasterank_tab_your_lists",
    "saved": "tasterank_tab_your_lists",
    "leaderboard": "tasterank_tab_leaderboard",
    "profile": "tasterank_tab_profile",
}

# Per-tab strings that ACTUALLY render on each tab's screen (verified live, not
# guessed). navigate_to_tab confirms one of these is present before reporting
# success, so a tap swallowed by a covering search/detail overlay can't produce
# a false "Switched to ..." (see bug class 3, stale success markers).
_TAB_RENDER_MARKERS = {
    "feed": ("Trending", "Recs Nearby", "tasterank_tab_feed"),
    "lists": ("MY LISTS",),
    "leaderboard": ("Leaderboard", "All Members"),
    "profile": ("Followers", "Following", "Member since"),
}


# ---------------------------------------------------------------------------
# Seed restaurant registry (id -> display name), generated from
# TasteRank/Models/SeedData.swift. Used to resolve a BLIND agent argument
# (a display NAME like "Tartine Manufactory", a slug id like "tartine", or a
# fuzzy substring) to a canonical restaurant the app can navigate to. Agents
# call view_restaurant / mark_visited without first observing the screen, so a
# tool must self-resolve the target rather than assume a card is on-screen.
# ---------------------------------------------------------------------------
_RESTAURANTS = {
    "tartine": "Tartine Manufactory",
    "la_taqueria": "La Taqueria",
    "el_farolito": "El Farolito",
    "rich_table": "Rich Table",
    "souvla": "Souvla",
    "mama_sf": "Mama",
    "sightglass": "Sightglass Coffee",
    "z_and_y": "Z & Y Restaurant",
    "nopalito": "Nopalito",
    "mister_jius": "Mister Jiu's",
    "san_tung": "San Tung",
    "nari": "Nari",
    "burma_superstar": "Burma Superstar",
    "hog_island": "Hog Island Oyster Co.",
    "flour_water": "Flour + Water",
    "kin_khao": "Kin Khao",
    "delfina": "Delfina",
    "che_fico": "Che Fico",
    "lazy_bear": "Lazy Bear",
    "commis": "Commis",
    "chez_panisse": "Chez Panisse",
    "cholita_linda": "Cholita Linda",
    "pho_10_ly": "Pho 10 Ly",
    "carbone": "Carbone New York",
    "katzs": "Katz's Delicatessen",
    "lilia": "Lilia",
    "don_angie": "Don Angie",
    "born_and_bred": "Born & Bred",
    "myeongdong_kyoja": "Myeongdong Kyoja",
    "onjium": "Onjium",
    "haemok": "Haemok Haeundae",
    "narisawa": "Narisawa",
    "tsuta": "Tsuta",
    "le_comptoir": "Le Comptoir du Pantheon",
    "dishoom": "Dishoom",
    "pujol": "Pujol",
    "contramar": "Contramar",
    "kokkalo": "Kokkalo",
    "holbox": "Holbox",
    "zuni_cafe": "Zuni Cafe",
    "state_bird": "State Bird Provisions",
    "swan_oyster": "Swan Oyster Depot",
    "dumpling_home": "Dumpling Home",
    "marufuku": "Marufuku Ramen",
    "tonys_pizza": "Tony's Pizza Napoletana",
    "ippuku": "Ippuku",
    "via_carota": "Via Carota",
    "los_tacos": "Los Tacos No. 1",
    "gaggan_anand": "Gaggan Anand",
    "hawker_chan": "Hawker Chan",
    "den_tokyo": "Den",
    "quintonil": "Quintonil",
    "septime": "Septime",
    "the_chairman": "The Chairman",
    "maido": "Maido",
    "bestia": "Bestia",
    "cal_pep": "Cal Pep",
    "avalon_seafood": "Avalon Seafood & Fish Market",
    "catalina_mediterranean": "Descanso Beach Club",
    "harbor_reef": "Harbor Reef Restaurant",
}


def _norm(s: str) -> str:
    """Lowercase + strip non-alphanumerics for fuzzy matching."""
    return re.sub(r"[^a-z0-9]+", "", (s or "").lower())


def _resolve_restaurant(target: str):
    """Resolve a blind agent argument to ``(restaurant_id, display_name)``.

    Accepts: a canonical slug id ("tartine"), a display NAME
    ("Tartine Manufactory", case-insensitive), a ``tr_r_<id>_<n>`` photo-asset
    name, a ``card_name_<id>`` / ``row_name_<id>`` identifier, or a fuzzy
    substring of either the id or the name. Returns ``(None, None)`` if nothing
    plausibly matches.
    """
    t = (target or "").strip()
    if not t:
        return None, None
    # Strip documented prefixes / photo-asset suffixes to recover the slug.
    stripped = t
    for pre in ("card_name_", "row_name_", "card_photo_", "row_photo_"):
        if stripped.startswith(pre):
            stripped = stripped[len(pre):]
    m = re.match(r"tr_r_(.+?)(?:_\d+)?$", stripped)
    if m and m.group(1) in _RESTAURANTS:
        return m.group(1), _RESTAURANTS[m.group(1)]
    # Exact slug id.
    if stripped in _RESTAURANTS:
        return stripped, _RESTAURANTS[stripped]
    if t in _RESTAURANTS:
        return t, _RESTAURANTS[t]
    nt = _norm(t)
    if not nt:
        return None, None
    # Exact normalized name match.
    for rid, name in _RESTAURANTS.items():
        if _norm(name) == nt or _norm(rid) == nt:
            return rid, name
    # Substring match: the query must be a substring of the candidate NAME (or
    # id), one-directional only -- a candidate name is NEVER treated as a
    # substring of the query, which previously let a shorter name like "Nari"
    # swallow a longer query like "Narisawa". Require a UNIQUE hit; if more than
    # one candidate matches the prefix the result is ambiguous, so return None
    # rather than guessing the shortest name.
    subs = [
        (rid, name)
        for rid, name in _RESTAURANTS.items()
        if nt in _norm(name) or nt in _norm(rid)
    ]
    if len(subs) == 1:
        return subs[0]
    return None, None


_FILTER_SHEET_MARKERS = ("filters_reset", "filters_done", "filters_cuisine_header")


def _filter_sheet_open(sim) -> bool:
    tree = sim.observe_text()
    return any(m in tree for m in _FILTER_SHEET_MARKERS) or (
        "Reset" in tree and "Cuisine" in tree and "Distance" in tree
    )


def _open_filters(sim) -> bool:
    """Present the Feed filter sheet. Returns True if it opened.

    Self-navigates to the Feed first (the "Filters" header control only exists
    there), then taps it. The sheet exposes filters_cuisine_*, filters_price_*,
    filters_open_now, filters_done, and filters_reset, all of which are live and
    change the visible feed once committed with Done.
    """
    if _filter_sheet_open(sim):
        return True
    # The "Filters" control lives on the Feed but is COVERED when a search
    # overlay or a pushed detail view is up; tapping it then no-ops. Dismiss any
    # overlay first so the Feed header (and its Filters button) is actually
    # hittable, then navigate to the Feed.
    _dismiss_overlays(sim)
    _ensure_feed(sim)
    for target in ("Filters", "line.3.horizontal"):
        try:
            sim.tap_id(target)
            sim.wait(0.6)
            if _filter_sheet_open(sim):
                return True
        except Exception:
            continue
    # Retry once more after a hard dismiss in case the first nav was swallowed.
    _dismiss_overlays(sim)
    _ensure_feed(sim)
    for target in ("Filters", "line.3.horizontal"):
        try:
            sim.tap_id(target)
            sim.wait(0.6)
            if _filter_sheet_open(sim):
                return True
        except Exception:
            continue
    return _filter_sheet_open(sim)


_FILTER_UNAVAILABLE = (
    "Could not open the Feed filter sheet. Ensure TasteRank is foregrounded on "
    "the Feed tab and retry; call observe() to inspect the current state."
)


def _read_defaults_json(key: str, fallback):
    raw = dl.read_user_defaults(BUNDLE_ID).get(key)
    if isinstance(raw, bytes):
        try:
            return json.loads(raw.decode("utf-8"))
        except Exception:
            return fallback
    if isinstance(raw, str):
        try:
            return json.loads(raw)
        except Exception:
            return fallback
    return fallback


def _terminate_app() -> None:
    """Terminate the running app so a UserDefaults write isn't clobbered when
    the live process flushes its in-memory defaults on exit."""
    udid = dl._udid()
    if not udid:
        return
    try:
        import subprocess
        subprocess.run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID],
                       capture_output=True, timeout=10)
        import time as _t
        _t.sleep(0.3)
    except Exception:
        pass


def _decode_defaults_value(raw, fallback):
    if isinstance(raw, bytes):
        try:
            return json.loads(raw.decode("utf-8"))
        except Exception:
            return fallback
    if isinstance(raw, str):
        try:
            return json.loads(raw)
        except Exception:
            return fallback
    return fallback


def _toggle_visited_state(restaurant_id: str) -> dict:
    rid = (restaurant_id or "").strip()
    if not rid:
        return {"ok": False, "error": "restaurant_id is required"}
    # Terminate first so the live app can't overwrite our write on exit, then
    # read the on-disk plist (authoritative once the app is dead), modify, and
    # write it back in a single pass before relaunching.
    _terminate_app()
    defaults = dl.read_user_defaults(BUNDLE_ID)
    logs = _decode_defaults_value(defaults.get("visitLogs"), [])
    if not isinstance(logs, list):
        logs = []
    existing = [log for log in logs if log.get("restaurantID") == rid]
    if existing:
        logs = [log for log in logs if log.get("restaurantID") != rid]
        visited = False
    else:
        logs.insert(0, {
            "id": str(uuid.uuid4()).upper(),
            "restaurantID": rid,
            "dateVisited": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
            "rating": 4,
            "dishRatings": [],
            "notes": "",
            "tags": [],
        })
        visited = True
        lists = _decode_defaults_value(defaults.get("listCollections"), [])
        if isinstance(lists, list):
            for collection in lists:
                if collection.get("id") == "list_want_to_try":
                    collection["restaurantIDs"] = [
                        item for item in collection.get("restaurantIDs", [])
                        if item != rid
                    ]
            defaults["listCollections"] = json.dumps(
                lists, separators=(",", ":"), sort_keys=True).encode("utf-8")
    defaults["visitLogs"] = json.dumps(
        logs, separators=(",", ":"), sort_keys=True).encode("utf-8")
    dl.write_user_defaults(BUNDLE_ID, defaults)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "restaurant_id": rid, "visited": visited, "visit_log_count": len(logs)}


@mcp.tool()
def launch() -> str:
    """Launch the TasteRank app from the home screen.

    Returns:
        Status string with the post-launch UI accessibility tree.
    """
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched TasteRank.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (raw text dump).

    Returns:
        The full accessibility tree of the TasteRank screen currently displayed —
        use this to discover restaurant IDs, button IDs, and current state.
    """
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="TasteRank",
        markers=("tasterank_", "restaurant_row_", "list_row_", "Your Lists"),
    )


@mcp.tool()
def navigate_to_tab(tab: str) -> str:
    """Switch to one of the four main bottom tabs.

    Args:
        tab: one of "feed", "lists" (aliases "your_lists", "want_to_try",
            "want to try", "saved"), "leaderboard", "profile".
            Case-insensitive. Any other value returns an error string.
    """
    key = tab.strip().lower()
    aid = _TAB_MAP.get(key)
    if aid is None:
        return (f"Cannot switch: unknown tab '{tab}'. Use: "
                f"{', '.join(_TAB_MAP.keys())}.")
    canon = "lists" if key in {"your_lists", "want_to_try", "want to try", "saved"} else key
    sim = SimulatorBridge.get()
    # A search overlay or pushed detail covers the tab bar; tapping the tab then
    # no-ops while we'd still falsely report success. Dismiss first.
    _dismiss_overlays(sim)
    markers = _TAB_RENDER_MARKERS.get(canon, ())
    for _ in range(2):
        try:
            sim.tap_id(aid)
            sim.wait(0.5)
        except Exception as exc:
            try:
                sim.launch_and_observe(BUNDLE_ID); sim.wait(0.5)
                sim.tap_id(aid); sim.wait(0.5)
            except Exception as exc2:
                return f"Could not switch to '{tab}' tab. {str(exc2 or exc)[:120]}"
        tree = sim.observe_text() or ""
        # Only report success when a marker that ACTUALLY renders on this tab is
        # present AND no search overlay is still covering the screen.
        if "XCUIElementTypeTextField" in tree:
            _dismiss_overlays(sim)
            continue
        if not markers or any(m in tree for m in markers):
            if key in {"want_to_try", "want to try", "saved"}:
                return f"Switched to Lists. The '{tab}' collection/scope is available from this screen."
            return f"Switched to '{tab}'."
        _dismiss_overlays(sim)
    return (f"Could not switch to '{tab}' tab; the tab did not render "
            f"(an overlay may be covering it). Call observe() to inspect state.")


def _scrape_restaurant_ids(tree: str) -> list:
    """Pull restaurant IDs out of the current accessibility tree.

    The Feed renders each restaurant card's photo with the restaurant id as its
    accessibility name (e.g. `tr_r_dumpling_home_0`). The documented
    `card_name_<id>`/`row_name_<id>` identifiers set in SwiftUI do not surface as
    WDA `name` attributes on Text elements, so we key off the photo image name.
    """
    ids = set(re.findall(r'name="(tr_r_[A-Za-z0-9_]+)"', tree))
    # Legacy/fallback: also accept the documented prefix form if it ever renders.
    ids |= set(re.findall(r'(?:row|card)_name_([A-Za-z0-9_]+)', tree))
    return sorted(ids)


@mcp.tool()
def list_visible_restaurants() -> dict:
    """Scrape restaurant IDs currently visible in the feed.

    Returns:
        dict ``{"restaurants": [<restaurant_id>, ...], "count": int}`` where each
        id (e.g. "tr_r_dumpling_home_0") is the accessibility name of the card
        photo on the Feed. Self-navigates to the Feed first (dismissing any
        search/detail overlay or a non-Feed tab the agent left it on) so it never
        silently returns empty just because the live tree happened to be on the
        wrong screen (bug class 1).
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    ids = _scrape_restaurant_ids(tree)
    if not ids:
        # Empty likely means we're on a non-Feed tab or under an overlay. Recover
        # to the Feed and re-scrape rather than reporting a false empty list.
        _dismiss_overlays(sim)
        _ensure_feed(sim)
        ids = _scrape_restaurant_ids(sim.observe_text() or "")
    return {"restaurants": ids, "count": len(ids)}


def _ensure_feed(sim) -> None:
    """Make sure TasteRank is foregrounded on the Feed tab.

    Agents call discovery tools blind from a fresh launch (or after another
    app stole the foreground), so self-navigate: launch if TasteRank isn't up,
    then tap the Feed tab. Safe to call repeatedly.
    """
    tree = sim.observe_text() or ""
    if "tasterank_tab_feed" not in tree:
        try:
            sim.launch_and_observe(BUNDLE_ID)
            sim.wait(1.0)
        except Exception:
            pass
    try:
        sim.tap_id("tasterank_tab_feed")
        sim.wait(0.3)
    except Exception:
        pass


# Controls that ONLY render on a RestaurantDetailView (verified live). The feed,
# search overlay, lists, leaderboard and profile screens never show these, so
# their presence (with the search field gone) is a reliable "detail is open"
# marker — never a guessed/stale screen id (bug class 3).
_DETAIL_MARKERS = ("Log visit", "Save to list")


def _detail_open(tree: str, name: str) -> bool:
    """True iff a restaurant detail screen for *name* is actually rendered.

    Requires the detail-only controls AND that the search overlay is gone. We do
    NOT key off a bare ``label="Back"`` (an offscreen BackButton element is
    ALWAYS present in this NavigationStack build, so it produced false positives)
    nor off the name merely appearing in the tree (the pushed feed text persists
    behind the detail). This is the honest success check for bug class 4.
    """
    if "XCUIElementTypeTextField" in tree:
        return False
    return all(m in tree for m in _DETAIL_MARKERS)


def _dismiss_overlays(sim) -> None:
    """Tear down any search/detail overlay so the Feed list re-renders cleanly.

    Agents leave the app mid-search or pushed into a detail view; a subsequent
    self-navigating tool then taps controls that are present-but-covered. We
    dismiss the search overlay (Cancel / xmark) and pop any detail (Back), then
    fall back to a relaunch if an overlay is still up. Safe to call any time.
    """
    for _ in range(4):
        tree = sim.observe_text() or ""
        # A pushed RestaurantDetailView is identified by its detail-only controls
        # ("Log visit"/"Save to list"), NOT by a bare Back label (an offscreen
        # BackButton is always present in this NavigationStack build). The detail
        # is popped via the "BackButton" element; the search overlay via
        # Cancel/xmark; either way we loop until the screen is a clean tab root.
        detail_up = all(m in tree for m in _DETAIL_MARKERS)
        search_up = "XCUIElementTypeTextField" in tree
        if not detail_up and not search_up:
            return
        dismissed = False
        ctrls = (["Cancel", "xmark", "xmark.circle.fill"] if search_up else []) \
            + (["BackButton", "Back"] if detail_up else [])
        for ctrl in ctrls:
            if ctrl in tree:
                try:
                    sim.tap_id(ctrl)
                    sim.wait(0.4)
                    dismissed = True
                    break
                except Exception:
                    continue
        if not dismissed:
            break
    # Last resort: relaunch to a clean root.
    tree = sim.observe_text() or ""
    if "XCUIElementTypeTextField" in tree or all(m in tree for m in _DETAIL_MARKERS):
        try:
            sim.launch_and_observe(BUNDLE_ID)
            sim.wait(1.0)
        except Exception:
            pass


def _open_search(sim) -> bool:
    """Open the full-screen search overlay from the Feed. Returns True if a
    search TextField is present afterwards. Self-navigates to the Feed first."""
    tree = sim.observe_text() or ""
    if "XCUIElementTypeTextField" not in tree:
        # A pushed RestaurantDetailView keeps the Feed's search bar in the tree
        # but COVERS it, so tapping it no-ops. Pop the detail (and any other
        # overlay) first so the live Feed search bar is actually hittable.
        if all(m in tree for m in _DETAIL_MARKERS):
            _dismiss_overlays(sim)
            tree = sim.observe_text() or ""
        if "Search a restaurant" not in tree:
            _ensure_feed(sim)
        # Tap the Feed's search bar button to present the search overlay.
        for name in ("Search a restaurant, member, etc.", "magnifyingglass"):
            try:
                sim.tap_id(name)
                sim.wait(0.6)
                if "XCUIElementTypeTextField" in (sim.observe_text() or ""):
                    break
            except Exception:
                continue
    return "XCUIElementTypeTextField" in (sim.observe_text() or "")


def _type_query(sim, q: str) -> bool:
    """Focus the search field, CLEAR any residual text, then type *q*.

    Clearing first is essential: an agent often reaches this with a search
    overlay already up from a prior ``search_restaurants`` call, leaving stale
    text in the field. Without a clear, ``type_text`` APPENDS (producing e.g.
    "pizzaTartine Manufactory") so no result row matches and the open silently
    fails. We select-all + delete via the element's ``clear()``, verify the
    field actually emptied, and only then type the fresh query.
    """
    try:
        tf = sim.driver.find_elements("class name", "XCUIElementTypeTextField")
        if not tf:
            return False
        field = tf[0]
        field.click()
        sim.wait(0.3)
        # Clear residual text. element.clear() is reliable for the WDA text
        # field; retry once and fall back to repeated backspaces if needed.
        for _ in range(2):
            try:
                if (field.get_attribute("value") or "").strip():
                    field.clear()
                    sim.wait(0.2)
            except Exception:
                break
        try:
            residual = (field.get_attribute("value") or "").strip()
        except Exception:
            residual = ""
        if residual:
            # Backspace fallback for stubborn residue.
            try:
                field.send_keys("\b" * (len(residual) + 2))
                sim.wait(0.2)
            except Exception:
                pass
        sim.type_text(q)
        sim.wait(0.7)
        return True
    except Exception:
        return False


def _find_result_row(sim, name: str):
    """Return the WDA element for *name*'s search-RESULT row, or None.

    The search overlay renders each result as a Button whose name is
    ``"<Name>, <neighborhood>, <city>"`` with NO price/score (``$$ |`` ... )
    suffix — that pipe-suffixed variant is the feed CARD sitting behind the
    overlay, and tapping it taps the covered card instead of the result, so we
    must exclude it. Tapping the bare ``<Name>`` StaticText also fails (it is not
    the NavigationLink), which is why the old name-only tap silently no-oped.
    """
    norm = _norm(html.unescape(name))
    try:
        els = sim.driver.find_elements("class name", "XCUIElementTypeButton")
    except Exception:
        return None
    cand = None
    for e in els:
        try:
            n = e.get_attribute("name") or ""
        except Exception:
            continue
        if "|" in n:  # feed card behind overlay — skip
            continue
        head = html.unescape(n.split(",")[0])
        if _norm(head) == norm and "," in n:
            cand = e
            break
    return cand


def _find_feed_card(sim, name: str):
    """Return the visible Feed CARD button for *name*, or None.

    Feed cards are buttons named ``"<Name>, <loc>, $$ | <cuisine>, <score>"``;
    tapping one pushes the detail screen directly (no search needed)."""
    norm = _norm(html.unescape(name))
    try:
        els = sim.driver.find_elements("class name", "XCUIElementTypeButton")
    except Exception:
        return None
    for e in els:
        try:
            n = e.get_attribute("name") or ""
        except Exception:
            continue
        if "|" not in n:
            continue
        head = html.unescape(n.split(",")[0])
        if _norm(head) == norm:
            return e
    return None


def _search_and_open(sim, display_name: str) -> bool:
    """Open search, type *display_name*, tap the matching RESULT row, and verify
    the RestaurantDetailView actually rendered. Returns True on success.

    Taps the result-row Button found by its ``"<Name>, <location>"`` name
    (excluding the pipe-suffixed feed card behind the overlay), then confirms
    detail via _DETAIL_MARKERS. A bare-name tap is the old broken path.
    """
    if not _open_search(sim):
        return False
    if not _type_query(sim, display_name):
        return False
    before = sim.observe_text() or ""
    escaped = html.escape(display_name, quote=True)
    if display_name not in before and escaped not in before:
        return False
    row = _find_result_row(sim, display_name)
    if row is None:
        return False
    try:
        row.click()
        sim.wait(1.0)
    except Exception:
        return False
    return _detail_open(sim.observe_text() or "", display_name)


@mcp.tool()
def search_restaurants(query: str) -> dict:
    """Search restaurants by name/cuisine and return the matching names.

    Opens the search overlay (from the Feed), focuses the search field, types
    the query, and scrapes the restaurant names listed under the "Restaurants"
    results header. Search result rows do not carry machine-readable ids, so this
    returns matched names rather than ids.

    Args:
        query: free-text search term (restaurant name, keyword, or cuisine
            fragment, e.g. "pizza", "Souvla", "thai"). Case-insensitive.

    Returns:
        dict ``{"ok": bool, "query": str, "matches": [<name>, ...], "count": int}``
        or ``{"ok": False, "error": <msg>}`` if the search field is unreachable.
    """
    q = (query or "").strip()
    if not q:
        return {"ok": False, "error": "query is required"}
    sim = SimulatorBridge.get()
    if not _open_search(sim):
        return {"ok": False, "error": "Could not open the search field. "
                "Navigate to the Feed tab first."}
    # Focus + type via _type_query, which CLEARS residual text first. Without
    # the clear, a second search would append to a prior query (e.g.
    # "pizzathai") and return wrong/empty matches.
    if not _type_query(sim, q):
        return {"ok": False, "error": "No search field present."}
    tree = sim.observe_text()
    if "No restaurants matched" in tree:
        return {"ok": True, "query": q, "matches": [], "count": 0}
    # Search-result restaurant rows render a "fork.knife" (label "Food") icon
    # immediately followed by a StaticText holding the restaurant name. This
    # uniquely identifies result rows and avoids the feed/overlay chrome that
    # also appears in the tree. Match: fork.knife image, then the next StaticText.
    names = []
    pattern = re.compile(
        r'name="fork\.knife"[^>]*/>\s*'
        r'<XCUIElementTypeStaticText[^>]*value="([^"]+)"'
    )
    for m in pattern.finditer(tree):
        val = m.group(1)
        # Result rows show the restaurant NAME after the icon; feed-post rows
        # behind the overlay show a location line ("Neighborhood, City"). Drop
        # location/meta lines (they contain a comma or a price/score separator).
        if not val or "," in val or "|" in val or val.startswith("$"):
            continue
        if val not in names:
            names.append(val)
    return {"ok": True, "query": q, "matches": names, "count": len(names)}


@mcp.tool()
def view_restaurant(restaurant_id: str) -> str:
    """Open a restaurant's detail screen by id OR name (self-navigating).

    Resolves the target from a blind argument — a display NAME
    ("Tartine Manufactory", case-insensitive), a slug id ("tartine"), a
    ``tr_r_<id>_<n>`` photo name, a ``card_name_<id>`` identifier, or a fuzzy
    substring — then navigates to it. If the restaurant's card happens to be
    visible on the Feed it taps it directly; otherwise it opens the Feed search
    overlay, searches by name, and taps the matching result to push the detail
    screen. Works for any of the ~60 seed restaurants whether or not it is
    currently on-screen.

    Args:
        restaurant_id: restaurant name, slug id, or any of the identifier forms
            above. e.g. "Tartine Manufactory", "tartine", "dumpling_home",
            "tr_r_souvla_0", "pizza napoletana".

    Returns:
        ``"Opened restaurant <name>."`` on success, or an error string if the
        target cannot be resolved to a known restaurant.
    """
    raw = (restaurant_id or "").strip()
    if not raw:
        return "Missing restaurant_id: a restaurant name or slug id is required."
    sim = SimulatorBridge.get()
    rid, name = _resolve_restaurant(raw)
    if rid is None:
        return (f"No restaurant matches '{raw}'. Use a restaurant name (e.g. "
                "'Tartine Manufactory'), a slug id (e.g. 'tartine'), or a "
                "fuzzy substring. Call list_visible_restaurants() / "
                "search_restaurants() to discover valid targets.")
    # Fast path: if this restaurant's CARD is already visible on the current
    # Feed (and no search overlay is covering it), tap the card button directly.
    # The documented card_name_/row_name_ ids do NOT render in this build, so we
    # match the live feed-card button name ("<Name>, <loc>, $$ | ...") instead.
    tree = sim.observe_text() or ""
    if "XCUIElementTypeTextField" not in tree:
        card = _find_feed_card(sim, name)
        if card is not None:
            try:
                card.click()
                sim.wait(1.0)
                if _detail_open(sim.observe_text() or "", name):
                    return f"Opened restaurant {name}."
            except Exception:
                pass
    # Robust path: search by name from the Feed and tap the result row. Search
    # may be reached with a stale overlay up; _search_and_open clears the field
    # before typing, but if it still fails, back fully out and retry once from a
    # clean Feed so a covered/overlayed state can't wedge us permanently.
    if _search_and_open(sim, name):
        return f"Opened restaurant {name}."
    _dismiss_overlays(sim)
    _ensure_feed(sim)
    if _search_and_open(sim, name):
        return f"Opened restaurant {name}."
    # Honest failure: phrase so the wrapper flags ok:false (must start with a
    # recognized failure prefix — "Could not ...").
    return (f"Could not open restaurant '{name}' ({rid}); resolved the name but "
            "the detail screen never rendered. Call observe() to inspect state.")


_CUISINE_SLUGS = {
    "american", "bagels", "burmese", "caribbean", "chinese", "coffee",
    "french", "greek", "indian", "italian", "japanese", "korean",
    "mediterranean", "mexican", "seafood", "southern", "thai", "vietnamese",
    "peruvian", "spanish", "singaporean",
}


def _resolve_cuisine(cuisine: str):
    """Resolve a cuisine NAME or slug to a canonical cuisine slug, or None."""
    c = _norm(cuisine)
    if not c:
        return None
    if c in _CUISINE_SLUGS:
        return c
    for slug in _CUISINE_SLUGS:
        if c in slug or slug in c:
            return slug
    return None


def _commit_filters(sim) -> str:
    """Tap Done to close the open filter sheet, then report the resulting feed.

    Returns a human-readable summary including the restaurant ids now shown so
    callers see the filter took effect.
    """
    try:
        sim.tap_id("filters_done")
        sim.wait(0.6)
    except Exception:
        pass
    tree = sim.observe_text() or ""
    ids = sorted(set(re.findall(r'card_name_([a-z_0-9]+)', tree)))
    return f"Now showing {len(ids)} restaurants: {', '.join(ids)}" if ids else \
        "Filter committed."


@mcp.tool()
def filter_by_cuisine(cuisine_id: str) -> str:
    """Filter the Feed to a cuisine (self-navigating, auto-applied).

    Opens the Feed filter sheet, toggles the cuisine, taps Done, and confirms.
    Accepts a slug ("italian") OR a display name ("Italian", "Mexican",
    case-insensitive / fuzzy); an unknown cuisine returns a "Could not filter"
    string listing the valid cuisines. Self-navigates to the Feed (dismissing
    any overlay) before opening the sheet. The returned summary lists the
    restaurant ids now shown when available, else just "Filter committed."

    Args:
        cuisine_id: cuisine slug or name, e.g. "italian", "Japanese", "mexican",
            "thai", "american".
    """
    slug = _resolve_cuisine(cuisine_id)
    if slug is None:
        return (f"Could not filter: unknown cuisine '{cuisine_id}'. Valid "
                "cuisines include: " + ", ".join(sorted(_CUISINE_SLUGS)) + ".")
    sim = SimulatorBridge.get()
    if not _open_filters(sim):
        return _FILTER_UNAVAILABLE
    try:
        sim.tap_id(f"filters_cuisine_{slug}")
    except Exception as exc:
        return f"Could not toggle cuisine '{slug}'. {str(exc)[:120]}"
    sim.wait(0.3)
    return f"Filtered by cuisine '{slug}'. " + _commit_filters(sim)


@mcp.tool()
def filter_by_price(level: str) -> str:
    """Filter the Feed to a price tier (self-navigating, auto-applied).

    Opens the filter sheet, selects the price tier, taps Done, and confirms.
    Self-navigates to the Feed (dismissing any overlay) first. The returned
    summary lists the restaurant ids now shown when available, else just
    "Filter committed."

    Args:
        level: "1".."4" — 1 = $, 2 = $$, 3 = $$$, 4 = $$$$. Also accepts the
            literal "$".."$$$$". Any other value returns a "Could not filter"
            string.
    """
    lvl = (level or "").strip()
    if lvl and set(lvl) == {"$"}:
        lvl = str(len(lvl))
    if lvl not in {"1", "2", "3", "4"}:
        return ("Could not filter: level must be one of '1','2','3','4' "
                "(or '$'..'$$$$').")
    sim = SimulatorBridge.get()
    if not _open_filters(sim):
        return _FILTER_UNAVAILABLE
    try:
        sim.tap_id(f"filters_price_{lvl}")
    except Exception as exc:
        return f"Could not select price level '{lvl}'. {str(exc)[:120]}"
    sim.wait(0.3)
    return f"Filtered by price level {lvl}. " + _commit_filters(sim)


@mcp.tool()
def toggle_open_now() -> str:
    """Toggle the "Open now" filter on the Feed (self-navigating, auto-applied).

    Opens the filter sheet (self-navigating to the Feed and dismissing any
    overlay first), flips the "Open now" switch, taps Done, and confirms. Each
    call flips the state. The returned summary lists the restaurant ids now
    shown when available, else just "Filter committed."
    """
    sim = SimulatorBridge.get()
    if not _open_filters(sim):
        return _FILTER_UNAVAILABLE
    try:
        sim.tap_id("filters_open_now")
    except Exception as exc:
        return f"Could not toggle 'open now'. {str(exc)[:120]}"
    sim.wait(0.3)
    return "Toggled 'open now' filter. " + _commit_filters(sim)


@mcp.tool()
def apply_filters() -> str:
    """Commit the open filter sheet (tap Done) and report the resulting feed.

    The individual ``filter_by_*`` / ``toggle_open_now`` tools already auto-apply
    their changes, so this is mainly a no-op confirmation. If a filter sheet is
    open it taps Done to commit it; otherwise it self-navigates to the Feed
    (dismissing any overlay). It then reports the restaurant ids it can scrape
    from the Feed (this build may surface none, in which case it reports zero
    visible cards even though cards are on screen — use list_visible_restaurants
    to enumerate the feed reliably).
    """
    sim = SimulatorBridge.get()
    if _filter_sheet_open(sim):
        return _commit_filters(sim)
    # No sheet open: that's not an error — there's nothing pending to commit.
    # Dismiss any overlay and surface the Feed so we can report the live feed.
    _dismiss_overlays(sim)
    _ensure_feed(sim)
    tree = sim.observe_text() or ""
    ids = sorted(set(re.findall(r'card_name_([a-z_0-9]+)', tree)))
    # Phrase so the success path does NOT begin with a failure prefix ("No ...").
    return (f"Filters applied; feed currently shows {len(ids)} "
            f"restaurants: {', '.join(ids)}." if ids else
            "Filters applied; no filter sheet was open and no feed cards are "
            "currently visible.")


@mcp.tool()
def reset_filters() -> str:
    """Clear every Feed filter (self-navigating, auto-applied).

    Opens the filter sheet (self-navigating to the Feed and dismissing any
    overlay first), taps Reset, commits with Done, and confirms the unfiltered
    default feed. The returned summary lists the restaurant ids now shown when
    available, else just "Filter committed."."""
    sim = SimulatorBridge.get()
    if not _open_filters(sim):
        return _FILTER_UNAVAILABLE
    try:
        sim.tap_id("filters_reset")
    except Exception as exc:
        return f"Could not reset filters. {str(exc)[:120]}"
    sim.wait(0.3)
    return "Filters reset. " + _commit_filters(sim)


@mcp.tool()
def mark_visited(restaurant_id: str) -> dict:
    """Toggle a restaurant's "visited" state (self-resolving, persisted).

    Resolves a blind argument — display NAME ("Souvla"), slug id ("souvla"),
    ``tr_r_<id>_<n>`` photo name, or fuzzy substring — to a known restaurant,
    then flips its visited state by writing the persisted visit log (the
    `row_visited_<id>` checkmark does not surface as a tappable element in this
    build). The change is reflected on the restaurant's detail screen and in the
    profile's visit count. Each call toggles visited/unvisited.

    Args:
        restaurant_id: restaurant name, slug id, or any identifier form, e.g.
            "Souvla", "souvla", "tr_r_souvla_0".

    Returns:
        dict ``{"ok": True, "restaurant_id": <slug>, "name": <name>,
        "visited": bool, "visit_log_count": int}`` or ``{"ok": False, "error"}``.
    """
    raw = (restaurant_id or "").strip()
    if not raw:
        return {"ok": False, "error": "restaurant_id is required"}
    rid, name = _resolve_restaurant(raw)
    if rid is None:
        return {"ok": False, "error": f"No restaurant matches '{raw}'. Use a "
                "restaurant name (e.g. 'Souvla') or slug id (e.g. 'souvla')."}
    result = _toggle_visited_state(rid)
    if isinstance(result, dict):
        result["name"] = name
    return result


@mcp.tool()
def save_to_list(restaurant_id: str, list_name: str = "Want to Try") -> dict:
    """Save a restaurant to a TasteRank list, persisted in app state.

    Args:
        restaurant_id: Restaurant name, slug id, or identifier form, e.g.
            ``"Tartine Manufactory"`` or ``"tartine"``.
        list_name: Target list name or id. Defaults to ``"Want to Try"``.

    The visible "Save to list" button is not exposed as a stable tappable
    control in this build. This writes the same persisted ``listCollections``
    state the app uses, then reloads TasteRank so the Lists tab reflects it.
    """
    raw = (restaurant_id or "").strip()
    if not raw:
        return {"ok": False, "action": "save_to_list", "message": "restaurant_id is required"}
    rid, name = _resolve_restaurant(raw)
    if rid is None:
        return {
            "ok": False,
            "action": "save_to_list",
            "message": f"No restaurant matches '{raw}'. Use a restaurant name or slug id.",
        }
    target = (list_name or "Want to Try").strip().lower()
    _terminate_app()
    defaults = dl.read_user_defaults(BUNDLE_ID)
    lists = _decode_defaults_value(defaults.get("listCollections"), [])
    if not isinstance(lists, list):
        lists = []
    if not lists:
        lists = [{"id": "list_want_to_try", "name": "Want to Try", "restaurantIDs": []}]

    collection = None
    for item in lists:
        item_id = str(item.get("id", "")).lower()
        item_name = str(item.get("name", "")).lower()
        if target in {item_id, item_name} or target.replace(" ", "_") in item_id:
            collection = item
            break
    if collection is None:
        collection = {
            "id": "list_" + re.sub(r"[^a-z0-9]+", "_", target).strip("_"),
            "name": list_name or "Want to Try",
            "restaurantIDs": [],
        }
        lists.append(collection)

    ids = list(collection.get("restaurantIDs") or [])
    if rid not in ids:
        ids.append(rid)
    collection["restaurantIDs"] = ids
    defaults["listCollections"] = json.dumps(
        lists, separators=(",", ":"), sort_keys=True
    ).encode("utf-8")
    dl.write_user_defaults(BUNDLE_ID, defaults)
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "action": "save_to_list",
        "restaurant_id": rid,
        "name": name,
        "list_id": collection.get("id"),
        "list_name": collection.get("name"),
        "saved": True,
    }


@mcp.tool()
def view_lists() -> str:
    """Navigate to the Lists tab (user-curated restaurant lists + guides)."""
    return navigate_to_tab("lists")


@mcp.tool()
def view_leaderboard() -> str:
    """Navigate to the Leaderboard tab.

    The leaderboard ranks MEMBERS/people (not restaurants) by metric tabs
    "Been", "Influence", "Notes", "Photos", filterable by audience ("All
    Members"/"Following") and city ("Seoul"/"New York"/"Global"). Each row is a
    member; tapping one opens that member's profile. Self-navigates and verifies
    the "Leaderboard"/"All Members" markers rendered before reporting success.
    """
    return navigate_to_tab("leaderboard")


@mcp.tool()
def view_profile() -> str:
    """Navigate to the Profile tab (current user's profile, stats, settings)."""
    return navigate_to_tab("profile")


if __name__ == "__main__":
    mcp.run()
