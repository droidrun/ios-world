"""Weather MCP — navigate cities, add/remove, read forecast.

Accessibility IDs (see Weather/ViewController.swift):
  weather_add_city, weather_page_control, weather_updated_label
  weather_city_page_<location_id>, weather_city_name, weather_temp,
  weather_summary, weather_high_low, weather_detail
  weather_city_search_row_<location_id>
"""

import sys, pathlib, re
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts

mcp = FastMCP("Weather")

BUNDLE_ID = "com.iosworld.benchmark.weather"


def _read(sim, aid: str) -> str:
    try:
        el = sim.driver.find_element("accessibility id", aid)
        return el.text or (el.get_attribute("value") or "") or (el.get_attribute("label") or "")
    except Exception:
        return ""


def _static_texts(tree_xml: str) -> list[str]:
    """Extract visible static-text names/labels from an XCTest XML dump."""
    texts: list[str] = []
    for node in re.findall(r"<XCUIElementTypeStaticText\b[^>]*>", tree_xml or ""):
        value = ""
        for attr in ("name", "label", "value"):
            m = re.search(rf'\b{attr}="([^"]*)"', node)
            if m and m.group(1):
                value = m.group(1)
                break
        if value and value not in texts:
            texts.append(value)
    return texts


def _daily_rows_from_visible_text(tree_xml: str, max_rows: int = 10) -> list[dict]:
    """Parse 10-Day Forecast rows when row accessibility ids are absent.

    Some iOS/WDA builds expose the daily forecast buttons without their
    ``weather_daily_row_*`` identifiers, while still exposing each row's text.
    The row shape is stable: day label, low temp, high temp.
    """
    marker = (tree_xml or "").find("10-Day Forecast")
    if marker < 0:
        return []
    rows: list[dict] = []
    for node in re.findall(
        r"<XCUIElementTypeButton\b[^>]*>.*?</XCUIElementTypeButton>",
        tree_xml[marker:],
        flags=re.S,
    ):
        texts = []
        for child in re.findall(r"<XCUIElementTypeStaticText\b[^>]*>", node):
            value = ""
            for attr in ("value", "name", "label"):
                m = re.search(rf'\b{attr}="([^"]*)"', child)
                if m and m.group(1):
                    value = m.group(1)
                    break
            if value:
                texts.append(value)
        temps = [t for t in texts if re.fullmatch(r"-?\d+°", t)]
        day = next((t for t in texts if t not in temps), "")
        if not day or len(temps) < 2:
            continue
        low, high = temps[0], temps[-1]
        rows.append({
            "ok": True,
            "day_id": _day_slug(day),
            "day": day,
            "high_low": f"High {high} Low {low}",
            "summary": None,
            "detail": None,
            "hourly": [],
        })
        if len(rows) >= max_rows:
            break
    return rows


def _daily_row_ids(tree_xml: str) -> list[str]:
    """Ordered ``weather_daily_row_<slug>`` ids visible in the tree."""
    seen: list[str] = []
    for slug in re.findall(r"weather_daily_row_([a-z0-9_]+)", tree_xml or ""):
        if slug not in seen:
            seen.append(slug)
    return seen


def _rect_for_accessibility_id(tree_xml: str, aid: str) -> tuple[int, int, int, int] | None:
    """Return the XCTest rect for an element whose name/accessibility id matches."""
    for tag in re.findall(r"<XCUIElementType\w+\b[^>]*>", tree_xml or ""):
        if f'name="{re.escape(aid)}"' not in tag and f'label="{re.escape(aid)}"' not in tag:
            continue
        vals = {}
        for attr in ("x", "y", "width", "height"):
            m = re.search(rf'\b{attr}="(-?\d+)"', tag)
            if not m:
                vals = {}
                break
            vals[attr] = int(m.group(1))
        if vals:
            return vals["x"], vals["y"], vals["width"], vals["height"]
    return None


def _reveal_daily_rows(sim, max_swipes: int = 8) -> list[str]:
    """Scroll the city page until daily forecast rows are visible."""
    rows = _daily_row_ids(sim.observe_text() or "")
    if rows:
        return rows
    for _ in range(max_swipes):
        try:
            sim.swipe("up")
            sim.wait(0.35)
        except Exception:
            break
        rows = _daily_row_ids(sim.observe_text() or "")
        if rows:
            return rows
    return []


def _collect_daily_row_ids(sim, max_swipes: int = 8) -> list[str]:
    """Collect daily forecast row ids by scrolling through the forecast card."""
    rows: list[str] = []
    stable = 0
    _reveal_daily_rows(sim, max_swipes=max_swipes)
    for _ in range(max_swipes):
        current = _daily_row_ids(sim.observe_text() or "")
        before = len(rows)
        for row in current:
            if row not in rows:
                rows.append(row)
        if len(rows) == before:
            stable += 1
            if stable >= 2:
                break
        else:
            stable = 0
        try:
            sim.swipe("up")
            sim.wait(0.25)
        except Exception:
            break
    return rows


def _collect_daily_text_rows(sim, max_rows: int = 10, max_swipes: int = 8) -> list[dict]:
    """Collect forecast rows from visible text when WDA omits row ids."""
    limit = max(1, min(int(max_rows or 10), 10))
    for _ in range(max_swipes + 1):
        rows = _daily_rows_from_visible_text(sim.observe_text() or "", max_rows=limit)
        if rows:
            return rows
        try:
            sim.swipe("up")
            sim.wait(0.35)
        except Exception:
            break
    return []


def _scroll_city_page_to_top(sim, swipes: int = 4) -> None:
    """Reset the weather city page near the top before scanning downward."""
    for _ in range(max(1, swipes)):
        try:
            sim.swipe("down")
            sim.wait(0.2)
        except Exception:
            break


def _day_slug(day: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", (day or "").strip().lower()).strip("_")
    aliases = {
        "sunday": "sun",
        "monday": "mon",
        "tuesday": "tue",
        "wednesday": "wed",
        "thursday": "thu",
        "friday": "fri",
        "saturday": "sat",
    }
    return aliases.get(slug, slug)


def _tap_daily_row(sim, slug: str, max_swipes: int = 8) -> bool:
    aid = f"weather_daily_row_{slug}"
    def opened_detail() -> bool:
        tree = sim.observe_text() or ""
        return any(marker in tree for marker in ("weather_daily_detail", "Hourly", "Sunrise", "Sunset"))

    def tap_visible(tree: str) -> bool:
        try:
            sim.tap_id(aid)
            sim.wait(0.5)
            if opened_detail():
                return True
        except Exception:
            pass
        rect = _rect_for_accessibility_id(tree, aid)
        if rect:
            x, y, w, h = rect
            try:
                sim.tap_xy(x + max(24, min(w - 24, w // 2)), y + max(18, h // 2))
                sim.wait(0.5)
                if opened_detail():
                    return True
            except Exception:
                pass
        return False

    for direction in ("up", "down"):
        for _ in range(max_swipes + 1):
            tree = sim.observe_text() or ""
            if aid in tree:
                if tap_visible(tree):
                    return True
            try:
                sim.swipe(direction)
                sim.wait(0.25)
            except Exception:
                break
    # Final direct check after the last scroll.
    tree = sim.observe_text() or ""
    if aid in tree and tap_visible(tree):
        return True
    return False


def _dismiss_daily_detail(sim) -> None:
    for aid in ("Done", "Close"):
        try:
            sim.tap_id(aid)
            sim.wait(0.3)
            return
        except Exception:
            continue


def _location_ids_in_tree(tree_xml: str) -> list[str]:
    """Extract all weather_city_page_<id> identifiers from the UI tree."""
    return re.findall(r'weather_city_page_([^"\s]+)', tree_xml)


def _saved_city_ids(sim) -> list[str]:
    """Ordered list of saved location IDs (page-control value, tree fallback)."""
    try:
        el = sim.driver.find_element("accessibility id", "weather_page_control")
        val = el.get_attribute("value") or ""
        ids = [x.strip() for x in val.split(",") if x.strip()]
        if ids:
            return ids
    except Exception:
        pass
    # Fallback: scrape the tree (order not guaranteed, but better than nothing).
    seen: list[str] = []
    tree = sim.observe_text()
    for cid in _location_ids_in_tree(tree):
        if cid not in seen:
            seen.append(cid)
    return seen


def _slug(text: str) -> str:
    """Normalise a free-text city query to the slug style used by location IDs."""
    s = (text or "").strip().lower()
    s = s.replace(",", " ")
    s = re.sub(r"\s+", "-", s.strip())
    return s


def _match_saved(query: str, saved: list[str]) -> str | None:
    """Resolve a blind name/id query to a saved location ID.

    Handles: exact id, slugified-name substring (``"new york"`` ->
    ``new-york-ny``), and bare-word substring (``"york"`` -> ``new-york-ny``).
    Returns None when nothing in the saved list matches.
    """
    q = (query or "").strip().lower()
    if not q:
        return None
    if q in saved:
        return q
    slug = _slug(query)
    # Drop a trailing 2-letter state code from the slug when present so
    # "seattle" matches "seattle-wa" and "seattle wa" still matches too.
    candidates = [slug]
    parts = slug.split("-")
    if len(parts) > 1 and len(parts[-1]) == 2:
        candidates.append("-".join(parts[:-1]))
    for cand in candidates:
        for cid in saved:
            # The city portion of the id is everything before the trailing
            # "-<state>" segment; compare against that for robust matching.
            city_part = "-".join(cid.split("-")[:-1]) if "-" in cid else cid
            if cand and (cand == city_part or cand in cid or city_part.startswith(cand)):
                return cid
    # Last resort: any bare word from the query appears in the id.
    for word in [w for w in re.split(r"[\s,-]+", q) if len(w) >= 3]:
        for cid in saved:
            if word in cid:
                return cid
    return None


def _navigate_to_index(sim, target_idx: int, total: int) -> None:
    """Deterministically page to ``target_idx`` in the paged city list.

    Resets to page 0 (swipe fully right) then swipes left ``target_idx``
    times. Robust regardless of the current page.
    """
    # Reset to the first page.
    for _ in range(max(total, 1) + 1):
        sim.swipe("right")
        sim.wait(0.18)
    for _ in range(max(0, target_idx)):
        sim.swipe("left")
        sim.wait(0.22)
    sim.wait(0.2)


def _navigate_to_city(sim, target_id: str, saved: list[str]) -> bool:
    """Page to the city ``target_id`` using name feedback.

    Resets to page 0, then swipes left while the visible ``weather_city_name``
    keeps changing, stopping as soon as the resolved city matches ``target_id``.
    Feedback-driven so it tolerates collection-view settling after an add and
    off-by-one index drift. Returns True when the target is on screen.
    """
    total = max(len(saved), 1)
    # Reset to the first page.
    for _ in range(total + 1):
        sim.swipe("right")
        sim.wait(0.18)
    sim.wait(0.2)
    last = None
    stable = 0
    # Allow a few extra steps beyond the list length for settling.
    for _ in range(total + 3):
        shown = _read(sim, "weather_city_name")
        if shown and _match_saved(shown, [target_id]) == target_id:
            return True
        if shown == last:
            stable += 1
            if stable >= 2:  # name stopped changing -> reached the end
                break
        else:
            stable = 0
        last = shown
        sim.swipe("left")
        sim.wait(0.25)
    # Final check after the loop's last swipe.
    shown = _read(sim, "weather_city_name")
    return bool(shown) and _match_saved(shown, [target_id]) == target_id


@mcp.tool()
def launch() -> str:
    """Launch the Weather app and return its initial UI tree.

    Returns:
      Human-readable string with a confirmation line and the accessibility
      tree from the foreground app.
    """
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched Weather.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current accessibility-tree dump of the Weather app's UI."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="Weather",
        markers=("weather_", "location_", "forecast_", "weather_city_"),
    )


@mcp.tool()
def current_city(city: str = "") -> dict:
    """Read the city/temp/summary/high-low shown on the visible page.

    Args:
      city: optional city name/id. When given, self-navigates to that city
        first (adding it if not saved); when blank, reads whatever page is
        currently visible.

    Returns:
      ``{"city": str | None, "temp": str | None, "summary": str | None,
        "high_low": str | None}`` — each field is None when the corresponding
      label isn't visible (e.g. when the search sheet is on top).
    """
    sim = SimulatorBridge.get()
    if city and str(city).strip():
        err = _ensure_city(sim, city)
        if err is not None:
            return {"city": None, "temp": None, "summary": None,
                    "high_low": None, "message": err.get("message")}
    else:
        # No target city: make sure no search sheet is covering the screen so
        # we read the *visible* city rather than stale labels behind an overlay.
        _ensure_main_screen(sim)
    return {
        "city": _read(sim, "weather_city_name") or None,
        "temp": _read(sim, "weather_temp") or None,
        "summary": _read(sim, "weather_summary") or None,
        "high_low": _read(sim, "weather_high_low") or None,
    }


@mcp.tool()
def list_cities() -> dict:
    """List all location IDs in the user's weather city list.

    Source of truth is the page control's accessibilityValue (comma-separated
    location IDs, updated on every data-source reload). Falls back to
    scraping ``weather_city_page_<id>`` from the UI tree.

    Returns:
      ``{"cities": [<location_id>, ...], "count": int,
        "source": "page_control" | "tree"}``.
    """
    sim = SimulatorBridge.get()
    try:
        el = sim.driver.find_element("accessibility id", "weather_page_control")
        val = el.get_attribute("value") or ""
        if val:
            ids = [x.strip() for x in val.split(",") if x.strip()]
            return {"cities": ids, "count": len(ids), "source": "page_control"}
    except Exception:
        pass
    tree = sim.observe_text()
    ids = sorted(set(_location_ids_in_tree(tree)))
    return {"cities": ids, "count": len(ids), "source": "tree"}


def _city_snapshot_changed(before: dict, after: dict) -> bool:
    keys = ("city", "temp", "summary", "high_low")
    return any(before.get(k) != after.get(k) for k in keys)


@mcp.tool()
def swipe_next_city() -> dict:
    """Swipe left to the next city page in the paged city list.

    Works from any screen: self-dismisses the add-city search sheet first so
    the swipe reaches the real pager. No-op at the last page is reported with
    ``changed:false``. Returns ``{ok, action, changed, before, after}``.
    """
    sim = SimulatorBridge.get()
    _ensure_main_screen(sim)
    before = current_city()
    sim.swipe("left")
    sim.wait(0.4)
    after = current_city()
    changed = _city_snapshot_changed(before, after)
    return {
        "ok": True,
        "action": "swipe_next_city",
        "changed": changed,
        "before": before,
        "after": after,
        "message": "Moved to the next city page." if changed else "Swipe completed but the visible city did not change.",
    }


@mcp.tool()
def swipe_previous_city() -> dict:
    """Swipe right to the previous city page in the paged city list.

    Works from any screen: self-dismisses the add-city search sheet first so
    the swipe reaches the real pager. No-op at the first page is reported with
    ``changed:false``. Returns ``{ok, action, changed, before, after}``.
    """
    sim = SimulatorBridge.get()
    _ensure_main_screen(sim)
    before = current_city()
    sim.swipe("right")
    sim.wait(0.4)
    after = current_city()
    changed = _city_snapshot_changed(before, after)
    return {
        "ok": True,
        "action": "swipe_previous_city",
        "changed": changed,
        "before": before,
        "after": after,
        "message": "Moved to the previous city page." if changed else "Swipe completed but the visible city did not change.",
    }


@mcp.tool()
def open_add_city() -> str:
    """Open the add-city search sheet (the "+" button on the main weather screen).

    After this returns, type into the search field and tap a result row.
    Prefer `add_city(name)` for the full open-search-tap flow in one call.

    Idempotent: if a search sheet is already up, it's reported as open rather
    than tapping the (now-covered) "+" button again — which would toggle the
    sheet shut. Verifies the sheet is actually presented before reporting
    success, so it never falsely claims to have opened search.
    """
    sim = SimulatorBridge.get()
    if _search_sheet_up(sim):
        return f"City search already open.\n\n{sim.observe_text()}"
    _ensure_add_button_visible(sim)
    sim.tap_id("weather_add_city")
    sim.wait(0.6)
    if not _search_sheet_up(sim):
        # One retry in case the first tap was swallowed by a settling animation.
        sim.tap_id("weather_add_city")
        sim.wait(0.6)
    if not _search_sheet_up(sim):
        return ("Could not open city search: the add-city sheet did not "
                "appear. Call observe() to check the current screen.")
    return f"Opened city search.\n\n{sim.observe_text()}"


def _search_sheet_up(sim) -> bool:
    """True while the Add-City sheet is still presented."""
    t = sim.observe_text()
    # The sheet has a nav bar titled "Add City" and search rows; the main
    # weather screen exposes the paged city name label instead.
    if 'name="Add City"' in t or "weather_city_search_row_" in t:
        return True
    return False


def _tap_label_if_present(sim, name: str) -> bool:
    """Tap a button by name only if it's actually in the current tree."""
    if f'name="{name}"' not in sim.observe_text():
        return False
    try:
        sim.tap_id(name)
        sim.wait(0.3)
        return True
    except Exception:
        return False


def _drag_sheet_down(sim) -> None:
    """Drag the add-city pageSheet down from its nav bar to dismiss it.

    This is the only dependable dismissal: after tapping a result row the
    search keyboard stays up and covers the nav bar, so "Done"/"Cancel" aren't
    in the accessibility tree. A drag from the nav-bar region to the bottom
    dismisses the sheet regardless of keyboard/search state.
    """
    try:
        sim.driver.execute_script(
            "mobile: dragFromToForDuration",
            {"duration": 0.6, "fromX": 201, "fromY": 100, "toX": 201, "toY": 840},
        )
        sim.wait(0.6)
    except Exception:
        # Fallback to a plain swipe-down if the gesture script is unavailable.
        try:
            sim.swipe("down")
            sim.wait(0.4)
        except Exception:
            pass


def _dismiss_search_sheet(sim) -> None:
    """Reliably dismiss the add-city search sheet.

    First try the nav-bar "Done" (works when the keyboard is already down);
    otherwise drag the sheet down from its nav bar, which always closes it.
    Confirms the sheet is gone and retries a few times.
    """
    for _ in range(4):
        if not _search_sheet_up(sim):
            return
        # Fast path: if "Done" is directly tappable (keyboard down), use it.
        if _tap_label_if_present(sim, "Done"):
            if not _search_sheet_up(sim):
                return
        # Reliable path: drag the pageSheet down to dismiss.
        _drag_sheet_down(sim)
    # Last-ditch extra drag.
    if _search_sheet_up(sim):
        _drag_sheet_down(sim)


def _ensure_main_screen(sim) -> None:
    """Return the app to the main paged weather screen.

    The add-city search sheet (an overlay pageSheet) sits ON TOP of the city
    pager: its labels (city name/temp/etc.) are still in the accessibility tree
    *behind* the sheet, so a naive read would return stale values and a swipe
    would no-op against the sheet. Every read/navigation tool calls this first
    so it operates on the real, uncovered weather screen rather than whatever
    overlay the agent (or a prior tool) left up. No-op when no sheet is present.
    """
    if _search_sheet_up(sim):
        _dismiss_search_sheet(sim)


def _ensure_add_button_visible(sim) -> None:
    """Return to the top-level city page where the add-city button is tappable."""
    if _search_sheet_up(sim):
        _dismiss_search_sheet(sim)
    tree = sim.observe_text() or ""
    if "weather_add_city" in tree:
        return
    sim.launch_and_observe(BUNDLE_ID)
    sim.wait(0.4)


def _find_search_field(sim):
    """Return the search-field element, or None."""
    for finder in (
        lambda: sim.driver.find_element("accessibility id", "Search cities"),
        lambda: sim.driver.find_element("class name", "XCUIElementTypeSearchField"),
    ):
        try:
            return finder()
        except Exception:
            continue
    return None


def _focus_search_field(sim) -> None:
    """Focus the search field and clear any stale text.

    The Add-City search controller retains its previous query across sheet
    presentations, so a second add would otherwise append to the old text
    (e.g. "Charleston" + "Austin" -> no match). We focus then clear it.
    """
    el = _find_search_field(sim)
    if el is None:
        return
    try:
        el.click()
        sim.wait(0.3)
    except Exception:
        pass
    # Clear any pre-existing text via the element API; fall back to tapping a
    # "Clear text" button if present.
    try:
        if (el.get_attribute("value") or "").strip() not in ("", "Search cities"):
            el.clear()
            sim.wait(0.3)
    except Exception:
        try:
            sim.tap_id("Clear text")
            sim.wait(0.2)
        except Exception:
            pass


@mcp.tool()
def add_city(name: str) -> dict:
    """Open the add-city sheet, search for a city, and add the matching result.

    Args:
      name: city to add, in ANY form — display name ("Tokyo", "Seattle",
        "New York"), "City, ST" ("Tucson, AZ"), or a location_id/slug
        ("miami-fl", "san-francisco-ca"). Case-insensitive; the query is
        normalised to a plain city name before searching and the result row is
        then matched by location_id OR visible label (a lone result is taken as
        unambiguous). A blank query or one that matches no result row fails
        gracefully (``ok: false``) — it never silently adds an unrelated city.

    Self-contained flow: closes any sheet left open by a prior call, opens the
    "+" sheet, focuses+clears the search field, types the city name, and taps
    the matching result row. Dismisses the search sheet (nav-bar "Done", or a
    drag-down when the keyboard covers it) on every path — success or failure —
    so the app is always left on the main weather screen.

    Returns:
      ``{"ok": bool, "added_city_id": <location_id> | None, "cities": [...],
        "count": int, "message": str}`` — ``cities`` is the refreshed saved
      list (location IDs). ``ok`` is True only when the city is actually in the
      saved list afterward; an unmatched/blank query returns ``ok: false`` with
      candidate IDs in ``message`` rather than adding an unrelated city.
    """
    query = (name or "").strip()
    if not query:
        return {
            "ok": False,
            "added_city_id": None,
            "cities": [],
            "count": 0,
            "message": "add_city requires a non-empty city name.",
        }

    # The search field filters on the human-readable city name. Normalise the
    # caller's query to a plain city name the filter will match, regardless of
    # form: "miami-fl"/"san-francisco-ca" (slug/id), "Tucson, AZ" (comma+state)
    # or "Tucson". We still match result rows by id OR label below, so any form
    # resolves to the right city.
    def _search_term(q: str) -> str:
        # "City, ST" -> "City"
        if "," in q:
            q = q.split(",", 1)[0].strip()
        # Slug/id form "city-name-st" -> "city name"
        if "-" in q and " " not in q:
            parts = q.split("-")
            if len(parts) > 1 and len(parts[-1]) == 2:
                parts = parts[:-1]
            return " ".join(parts)
        return q

    search_text = _search_term(query)

    sim = SimulatorBridge.get()
    # Start from a clean main screen: close any sheet left open by a prior call.
    _ensure_add_button_visible(sim)
    sim.tap_id("weather_add_city")
    sim.wait(0.6)
    _focus_search_field(sim)
    try:
        sim.type_text(search_text)
    except Exception:
        pass
    sim.wait(0.6)

    tree = sim.observe_text()
    # Collect each result row's location_id together with its visible label so
    # we can match on either the slug or the human-readable city name.
    rows = re.findall(
        r'weather_city_search_row_([^"\s]+)"[^>]*?(?:label|value|name)="([^"]*)"',
        tree,
    )
    ids = re.findall(r'weather_city_search_row_([^"\s]+)', tree)
    if not ids:
        _dismiss_search_sheet(sim)
        return {
            "ok": False,
            "added_city_id": None,
            "cities": list_cities().get("cities", []),
            "count": list_cities().get("count", 0),
            "message": f"No cities matching '{query}' in search results.",
        }

    q_low = query.lower()
    st_low = search_text.lower()
    # Slug candidates derived from both the raw query and the cleaned search
    # term, so "Tucson, AZ", "tucson-az" and "Tucson" all resolve.
    q_slugs = {q_low.replace(" ", "-"), st_low.replace(" ", "-"),
               q_low.replace(", ", "-").replace(" ", "-")}
    target_id = None
    # 1) location_id contains a slugified form of the query.
    for loc_id in ids:
        low = loc_id.lower()
        if any(s and s in low for s in q_slugs):
            target_id = loc_id
            break
    # 2) visible row label contains the query (or its cleaned city name).
    if target_id is None:
        for loc_id, label in rows:
            lab = (label or "").lower()
            if (q_low in lab) or (st_low and st_low in lab):
                target_id = loc_id
                break
    # 3) single result row -> unambiguous, take it.
    if target_id is None and len(set(ids)) == 1:
        target_id = ids[0]
    if target_id is None:
        _dismiss_search_sheet(sim)
        c = list_cities()
        return {
            "ok": False,
            "added_city_id": None,
            "cities": c.get("cities", []),
            "count": c.get("count", 0),
            "message": (
                f"No result row matches '{query}'. "
                f"Candidates: {ids[:8]}"
            ),
        }

    sim.tap_id(f"weather_city_search_row_{target_id}")
    sim.wait(0.5)
    _dismiss_search_sheet(sim)
    sim.wait(0.3)
    cities = list_cities()
    added = target_id in cities.get("cities", [])
    return {
        "ok": bool(added),
        "added_city_id": target_id,
        "cities": cities.get("cities", []),
        "count": cities.get("count", 0),
        "message": (
            f"Added city (id={target_id})."
            if added
            else f"Tapped '{target_id}' but it is not in the city list "
            "(it may already exist or the add was rejected)."
        ),
    }


@mcp.tool()
def view_city(name: str, add_if_missing: bool = True) -> dict:
    """Navigate the paged city list to the city matching ``name``.

    Self-navigates and self-resolves: resolves ``name`` to a saved location
    (by id, slugified display name, or bare-word substring), then pages to it
    deterministically (works whether the target is before or after the current
    page, unlike a naive forward-only swipe). If the city is not yet in the
    saved list, it is added first (``add_if_missing``, default True) so a blind
    call from a fresh launch still lands on the requested city.

    Args:
      name: city display name or location_id (case-insensitive; substrings and
        slug forms like "new york" / "new-york-ny" both work).
      add_if_missing: when True, add the city via the search sheet if it is not
        already saved, then navigate to it. When False, returns ``ok: false``
        if the city is not saved.

    Returns:
      ``{"ok": bool, "city": str|None, "city_id": str|None, "temp": ...,
        "summary": ..., "high_low": ..., "message": str}`` — the ``ok`` flag is
      True only when the requested city is actually on screen.
    """
    sim = SimulatorBridge.get()
    query = (name or "").strip()
    if not query:
        return {"ok": False, "city": None, "city_id": None,
                "message": "view_city requires a non-empty city name."}

    # If a city is already saved we can navigate to it directly; only dismiss a
    # covering search sheet (so swipes reach the pager). add_city handles its
    # own sheet lifecycle when the city must be added first.
    saved = _saved_city_ids(sim)
    visible_ids = _location_ids_in_tree(sim.observe_text() or "")
    for cid in visible_ids:
        if cid not in saved:
            saved.append(cid)
    target = _match_saved(query, saved)
    visible_city = _read(sim, "weather_city_name")
    if target is None and visible_city and _match_saved(query, [visible_city]):
        target = visible_ids[0] if visible_ids else _slug(visible_city)
        if target not in saved:
            saved.append(target)
    if target is not None:
        _ensure_main_screen(sim)
        saved = _saved_city_ids(sim)

    if target is None and add_if_missing:
        res = add_city(query)
        if not res.get("ok"):
            return {"ok": False, "city": None, "city_id": None,
                    "message": f"'{query}' is not saved and could not be added: "
                               f"{res.get('message')}"}
        target = res.get("added_city_id")
        # Give the collection view time to reload after the add before paging.
        sim.wait(0.6)
        saved = _saved_city_ids(sim)

    if target is None or target not in saved:
        return {"ok": False, "city": None, "city_id": None,
                "message": f"'{query}' is not in the saved city list "
                           f"({saved}). Pass a city name that exists in the "
                           f"catalog, or use add_city first."}

    ok = _navigate_to_city(sim, target, saved)
    cur = current_city()
    return {
        "ok": ok,
        "city": cur.get("city"),
        "city_id": target,
        "temp": cur.get("temp"),
        "summary": cur.get("summary"),
        "high_low": cur.get("high_low"),
        "message": (f"Showing {cur.get('city')} (id={target})." if ok
                    else f"Navigated toward '{query}' but landed on "
                         f"'{cur.get('city')}'."),
    }


def _ensure_city(sim, city: str | None) -> dict | None:
    """If ``city`` is given, self-navigate to it. Returns an error dict on
    failure (caller should pass it straight through), else None."""
    if not city or not str(city).strip():
        return None
    res = view_city(str(city))
    if not res.get("ok"):
        return res
    return None


@mcp.tool()
def read_temp(city: str = "") -> dict:
    """Read the temperature for a city (self-navigating).

    Args:
      city: optional city name/id. When given, the tool first pages to that
        city (adding it if not saved) so a blind call reads the right city
        without manual navigation. When blank, reads the currently visible city.

    Returns:
      ``{"ok": bool, "city": str|None, "temp": str|None, "message"?: str}``.
    """
    sim = SimulatorBridge.get()
    err = _ensure_city(sim, city)
    if err is not None:
        return {"ok": False, "city": None, "temp": None, "message": err.get("message")}
    return {"ok": True, "city": _read(sim, "weather_city_name") or None,
            "temp": _read(sim, "weather_temp") or None}


@mcp.tool()
def read_summary(city: str = "") -> dict:
    """Read the conditions summary for a city (self-navigating).

    Args:
      city: optional city name/id to page to first (see ``read_temp``).

    Returns:
      ``{"ok": bool, "city": str|None, "summary": str|None, "message"?: str}``.
    """
    sim = SimulatorBridge.get()
    err = _ensure_city(sim, city)
    if err is not None:
        return {"ok": False, "city": None, "summary": None, "message": err.get("message")}
    return {"ok": True, "city": _read(sim, "weather_city_name") or None,
            "summary": _read(sim, "weather_summary") or None}


@mcp.tool()
def read_detail(city: str = "") -> dict:
    """Read the detail line for a city (self-navigating).

    Args:
      city: optional city name/id to page to first (see ``read_temp``).

    Returns:
      ``{"ok": bool, "city": str|None, "detail": str|None, "message"?: str}``.
    """
    sim = SimulatorBridge.get()
    err = _ensure_city(sim, city)
    if err is not None:
        return {"ok": False, "city": None, "detail": None, "message": err.get("message")}
    return {"ok": True, "city": _read(sim, "weather_city_name") or None,
            "detail": _read(sim, "weather_detail") or None}


@mcp.tool()
def read_high_low(city: str = "") -> dict:
    """Read today's high/low for a city (self-navigating).

    Args:
      city: optional city name/id to page to first (see ``read_temp``).

    Returns:
      ``{"ok": bool, "city": str|None, "high_low": str|None, "message"?: str}``.
    """
    sim = SimulatorBridge.get()
    err = _ensure_city(sim, city)
    if err is not None:
        return {"ok": False, "city": None, "high_low": None, "message": err.get("message")}
    return {"ok": True, "city": _read(sim, "weather_city_name") or None,
            "high_low": _read(sim, "weather_high_low") or None}


@mcp.tool()
def read_forecast(city: str = "", day: str = "", max_days: int = 10) -> dict:
    """Read the multi-day forecast for a city from the 10-Day Forecast rows.

    Args:
      city: optional city name/id to navigate to first.
      day: optional row name such as ``today``, ``tomorrow``, ``monday``.
        When blank, reads up to ``max_days`` visible/scrollable daily rows.
      max_days: maximum rows to open when ``day`` is blank (capped at 10).

    Returns:
      ``{ok, city, forecasts: [{day, high_low, summary, detail, hourly}],
      count}``. Each row is opened via ``weather_daily_row_<day>`` and parsed
      from the detail sheet, so this reads more than the current-day summary.
      If a requested row cannot be opened, returns top-level ``ok:false``
      instead of hiding the row failure inside a successful envelope.
    """
    sim = SimulatorBridge.get()
    err = _ensure_city(sim, city)
    if err is not None:
        return {"ok": False, "city": None, "forecasts": [], "count": 0,
                "message": err.get("message")}
    _ensure_main_screen(sim)
    _scroll_city_page_to_top(sim)
    city_name = _read(sim, "weather_city_name") or None
    wanted = _day_slug(day)
    wants_tomorrow = (day or "").strip().lower() == "tomorrow"
    rows = _collect_daily_row_ids(sim)
    fallback_rows = []
    if not rows:
        # The visible forecast rows may be unnamed buttons on some live WDA
        # builds. Parse the row text directly before declaring the forecast
        # unavailable; this is enough for comparison tasks that need highs/lows.
        _ensure_main_screen(sim)
        fallback_rows = _collect_daily_text_rows(
            sim,
            max_rows=max(1, min(int(max_days or 10), 10)),
        )
        if fallback_rows:
            if wanted:
                if wants_tomorrow and len(fallback_rows) > 1:
                    fallback_rows = [fallback_rows[1]]
                else:
                    fallback_rows = [
                        row for row in fallback_rows
                        if row["day_id"] == wanted or row["day_id"].startswith(wanted)
                    ]
                if not fallback_rows:
                    return {"ok": False, "city": city_name, "forecasts": [], "count": 0,
                            "message": f"No visible forecast row matched '{day}'."}
            return {"ok": True, "city": city_name, "forecasts": fallback_rows,
                    "count": len(fallback_rows),
                    "source": "visible_text"}
    if wanted:
        if wants_tomorrow and len(rows) > 1:
            matches = [rows[1]]
        else:
            matches = [r for r in rows if r == wanted or r.startswith(wanted)]
        if not matches:
            # If the requested row was below the collected range, try direct
            # reveal/tap anyway before failing.
            matches = [wanted]
        rows = matches[:1]
    else:
        rows = rows[: max(1, min(int(max_days or 10), 10))]
    if not rows:
        return {"ok": False, "city": city_name, "forecasts": [], "count": 0,
                "message": "No weather_daily_row_<day> forecast rows were visible after scrolling."}

    forecasts = []
    failures = []
    for slug in rows:
        _ensure_main_screen(sim)
        if not _tap_daily_row(sim, slug):
            failures.append({"day_id": slug, "message": f"Could not open weather_daily_row_{slug}."})
            continue
        tree = sim.observe_text() or ""
        texts = _static_texts(tree)
        high_low = next((t for t in texts if t.startswith("High ") and " Low " in t), None)
        section_labels = {"Sun", "Hourly", "Sunrise", "Sunset", "Forecast"}
        candidates = [
            t for t in texts
            if t not in section_labels
            and not re.fullmatch(r"\d{1,2}(:\d{2})?\s?(AM|PM)", t, flags=re.I)
        ]
        day_name = candidates[0] if candidates else slug.replace("_", " ").title()
        summary = None
        detail = None
        if high_low and high_low in candidates:
            idx = candidates.index(high_low)
            if idx + 1 < len(candidates):
                summary = candidates[idx + 1]
            if idx + 2 < len(candidates):
                detail = candidates[idx + 2]
        hourly = [
            {"time": texts[i], "forecast": texts[i + 1]}
            for i in range(len(texts) - 1)
            if re.fullmatch(r"\d{1,2}\s?(AM|PM)", texts[i], flags=re.I)
        ]
        forecasts.append({
            "ok": True,
            "day_id": slug,
            "day": day_name,
            "high_low": high_low,
            "summary": summary,
            "detail": detail,
            "hourly": hourly[:12],
        })
        _dismiss_daily_detail(sim)
    if failures:
        return {
            "ok": False,
            "city": city_name,
            "forecasts": forecasts,
            "count": len(forecasts),
            "failures": failures,
            "message": (
                "Could not open forecast row(s): "
                + ", ".join(f"weather_daily_row_{f['day_id']}" for f in failures)
            ),
        }
    return {"ok": True, "city": city_name, "forecasts": forecasts,
            "count": len(forecasts)}


if __name__ == "__main__":
    mcp.run()
