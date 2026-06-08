"""Clock MCP — tabs (World Clock, Alarm, Stopwatch, Timer) + CRUD.

Conventions:
  - Every action/read tool SELF-NAVIGATES to the tab it needs (and first
    dismisses any add-city / add-alarm overlay), so callers never need to
    navigate first. `navigate_to_tab` is only for explicitly switching view.
  - Resolvers accept human-readable names, not raw slugs: cities by display
    name ("New York"), alarms by label ("Wake up", case-insensitive, spaces
    auto-slugged). list_* tools return the underlying slugs for reference.
  - Mutating tools VERIFY the change landed and return a "Could not ..."
    string (ok:false) on failure rather than an optimistic success.

IDs (see Clock/ViewController.swift):
  clock_tab_world, clock_tab_alarm, clock_tab_stopwatch, clock_tab_timer
  clock_world_city_<name_slug>
  clock_alarm_row_<label_slug>, clock_alarm_toggle_<label_slug>
  clock_stopwatch_display, clock_stopwatch_start_stop, clock_stopwatch_lap_reset
  clock_timer_display, clock_timer_start_stop, clock_timer_reset,
  clock_timer_duration_picker (set via generic sim tools — no dedicated MCP
    tool sets the timer duration; start_stop_timer no-ops at 00:00:00)
  alarm_repeat_button (AddAlarmViewController — no dedicated MCP tool)
"""

import sys, pathlib, re
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge

mcp = FastMCP("Clock")

BUNDLE_ID = "com.iosworld.benchmark.clock"

_TAB_MAP = {
    "world": "clock_tab_world", "world clock": "clock_tab_world",
    "alarm": "clock_tab_alarm", "alarms": "clock_tab_alarm",
    "stopwatch": "clock_tab_stopwatch",
    "timer": "clock_tab_timer",
}


def _active_bundle_id(sim) -> str | None:
    try:
        info = sim.connect().execute_script("mobile: activeAppInfo")
    except Exception:
        return None
    if isinstance(info, dict):
        bundle = info.get("bundleId")
        if isinstance(bundle, str) and bundle:
            return bundle
    return None


def _clock_tree_matches(tree: str) -> bool:
    t = tree or ""
    return (
        f'bundleId="{BUNDLE_ID}"' in t
        or "clock_tab_" in t
        or "clock_world_city_" in t
        or "clock_alarm_" in t
        or "clock_stopwatch_" in t
        or "clock_timer_" in t
        or "worldclock.search" in t
        or "Add Alarm" in t
    )


def _observe_clock_scoped(sim):
    active = _active_bundle_id(sim)
    if active and active != BUNDLE_ID:
        try:
            sim.launch_app(BUNDLE_ID)
            sim.wait(0.8)
        except Exception:
            pass
        active = _active_bundle_id(sim)
        if active and active != BUNDLE_ID:
            return {
                "ok": False,
                "error": "app-mismatch",
                "expected_bundle": BUNDLE_ID,
                "actual_bundle": active,
                "message": "Clock is not the foreground app; observe() did not return another app's UI tree.",
            }

    tree = sim.observe_text() or ""
    if active == BUNDLE_ID or _clock_tree_matches(tree):
        return tree

    return {
        "ok": False,
        "error": "app-mismatch",
        "expected_bundle": BUNDLE_ID,
        "actual_bundle": _active_bundle_id(sim),
        "message": "Could not verify Clock as the foreground app; observe() did not return an unscoped UI tree.",
    }


def _slug(s: str) -> str:
    return s.lower().replace(" ", "_")


def _read(sim, aid: str) -> str:
    try:
        el = sim.driver.find_element("accessibility id", aid)
        return el.text or (el.get_attribute("value") or "")
    except Exception:
        return ""


def _label(sim, aid: str) -> str:
    """Read a control's label/title (e.g. a button's "Start"/"Pause" text).

    The start/stop buttons change their TITLE (not value) when toggled, so the
    label is the reliable running-state signal; `_read` returns value/text and
    is empty for these buttons. Falls back to a regex over the tree.
    """
    try:
        el = sim.driver.find_element("accessibility id", aid)
        lbl = el.get_attribute("label") or el.text or ""
        if lbl:
            return lbl
    except Exception:
        pass
    try:
        m = re.search(r'name="%s"[^>]*label="([^"]*)"' % re.escape(aid),
                      sim.observe_text())
        if m:
            return m.group(1)
    except Exception:
        pass
    return ""


def _search_overlay_present(sim) -> bool:
    """True when the World-Clock add-city search sheet is on screen.

    The search sheet covers the bottom tab bar, so a tab tap from underneath
    no-ops. Detect it by its search field id (rendered only on that sheet).
    """
    try:
        return "worldclock.search" in sim.observe_text()
    except Exception:
        return False


def _overlay_present(sim) -> bool:
    """True when ANY modal overlay (search sheet or add-alarm sheet) is up.

    These overlays cover the tab bar / underlying lists. Navigating or
    enumerating while one is up silently fails (tab tap no-ops, the tree
    contains the wrong rows). Tools must dismiss the overlay before acting.
    """
    return _sheet_open(sim) or _search_overlay_present(sim)


def _dismiss_overlays(sim, max_rounds: int = 3) -> None:
    """Best-effort close any add-city / add-alarm modal so the tab bar is live.

    Strategy: tap the modal's Cancel bar button (dismisses both the search
    sheet and the add-alarm sheet). If an overlay is still detected after a
    few rounds, fall back to relaunching the app, which always returns to a
    clean World-Clock tab with no overlay. Idempotent / safe to call when no
    overlay is present.
    """
    for _ in range(max_rounds):
        if not _overlay_present(sim):
            return
        try:
            sim.tap_id("Cancel")
            sim.wait(0.4)
        except Exception:
            break
    if _overlay_present(sim):
        # Hard reset: relaunch clears every modal and returns to World Clock.
        try:
            sim.launch_and_observe(BUNDLE_ID)
            sim.wait(0.5)
        except Exception:
            pass


def _tab_active(sim, tab_aid: str) -> bool:
    """Confirm a tab's content is actually rendered (not just the tab tapped).

    Each tab renders a signature control; checking for it in the tree proves
    we navigated there rather than relying on the tap return value (which is
    a no-op success when the tab bar is covered by an overlay).
    """
    sig = {
        "clock_tab_world": "clock_world_city_",
        "clock_tab_alarm": "clock_alarm_row_",
        "clock_tab_stopwatch": "clock_stopwatch_display",
        "clock_tab_timer": "clock_timer_display",
    }.get(tab_aid)
    if not sig:
        return False
    try:
        tree = sim.observe_text()
    except Exception:
        return False
    if sig in tree:
        return True
    # Alarm tab with zero alarms renders no rows but does render the +/Edit
    # bar — accept the Alarm sheet trigger as a fallback signal.
    if tab_aid == "clock_tab_alarm" and "clock_tab_alarm" in tree and "clock_world_city_" not in tree:
        return True
    return False


def _ensure_tab(sim, tab_aid: str) -> bool:
    """Make sure a specific bottom tab is active before acting on its controls.

    The stopwatch/timer controls (and the alarm rows) are only rendered while
    their tab is selected; calling an action tool from a different tab would
    otherwise fail with "control not visible". A modal overlay (add-city
    search / add-alarm sheet) covers the tab bar, making a naive tap a no-op;
    we dismiss overlays first, tap, then VERIFY the tab content rendered,
    retrying (with a relaunch) if it didn't.

    Returns True if the tab's content is confirmed rendered.
    """
    for attempt in range(3):
        _dismiss_overlays(sim)
        try:
            sim.tap_id(tab_aid)
            sim.wait(0.4)
        except Exception:
            pass
        if _tab_active(sim, tab_aid):
            return True
        # Tap didn't take (covered / race). Relaunch to a clean state then retry.
        if attempt < 2:
            try:
                sim.launch_and_observe(BUNDLE_ID)
                sim.wait(0.5)
            except Exception:
                pass
    return _tab_active(sim, tab_aid)


def _ui_unavailable(action: str, control: str) -> dict:
    return {
        "ok": False,
        "action": action,
        "message": f"{control} is unavailable in the current UI state; open the Alarm tab/add-alarm sheet first.",
    }


def _sheet_open(sim) -> bool:
    """True when the Add-Alarm modal is on screen."""
    try:
        return "Add Alarm" in sim.observe_text()
    except Exception:
        return False


def _open_alarm_sheet(sim) -> bool:
    """Tap the Alarm-tab + button and wait for the sheet to actually appear.

    The Add tap needs ~1s to present the modal; a short settle was the root
    cause of intermittent 'Save unavailable' failures. Retries the tap once.
    """
    if _sheet_open(sim):
        return True
    for _ in range(2):
        # A search overlay (or stale alarm sheet) covers the tab bar / +
        # button; dismiss it and confirm the Alarm tab is actually rendered
        # before tapping Add, otherwise the Add tap no-ops under the overlay.
        _ensure_tab(sim, "clock_tab_alarm")
        try:
            sim.tap_id("Add")
        except Exception:
            continue
        for _ in range(6):
            sim.wait(0.3)
            if _sheet_open(sim):
                return True
    return _sheet_open(sim)


def _dismiss_keyboard(sim) -> None:
    """Best-effort hide the soft keyboard so the Save bar button is hittable."""
    try:
        sim.driver.hide_keyboard()
        sim.wait(0.2)
    except Exception:
        pass


def _tap_save(sim) -> bool:
    """Dismiss the keyboard, then tap Save, retrying on the page_source race.

    Returns True once the sheet is dismissed (commit succeeded)."""
    _dismiss_keyboard(sim)
    for _ in range(3):
        try:
            sim.tap_id("Save"); sim.wait(0.5)
        except Exception:
            sim.wait(0.3)
            continue
        if not _sheet_open(sim):
            return True
    return not _sheet_open(sim)


@mcp.tool()
def launch() -> str:
    """Launch the Clock app and return its initial UI tree.

    Returns:
      Human-readable string with a confirmation line and the accessibility
      tree from the foreground app.
    """
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched Clock.\n\n{ui}"


@mcp.tool()
def observe():
    """Return Clock's UI tree, or ok:false if another app owns the foreground."""
    return _observe_clock_scoped(SimulatorBridge.get())


@mcp.tool()
def navigate_to_tab(tab: str) -> str:
    """Switch the bottom tab bar to a specific Clock section.

    Dismisses any add-city / add-alarm overlay first and verifies the tab's
    content actually rendered. Most action/read tools self-navigate, so call
    this only when you need to explicitly land on a tab.

    Args:
      tab: one of "world" / "world clock", "alarm" / "alarms", "stopwatch",
        "timer" (case-insensitive). Any other value returns "Could not switch
        tab: unknown tab ..." (ok:false).
    """
    aid = _TAB_MAP.get(tab.strip().lower())
    if aid is None:
        # "Unknown tab" is not caught by the failure-prefix detector, which
        # would mark this ok:true. Prefix with "Could not" so the envelope
        # records ok:false for an unrecognized tab.
        return f"Could not switch tab: unknown tab '{tab}'. Use: world, alarm, stopwatch, timer."
    sim = SimulatorBridge.get()
    # Dismiss any add-city/add-alarm overlay first; verify the tab rendered.
    if _ensure_tab(sim, aid):
        return f"Switched to '{tab}'."
    return f"Could not switch to '{tab}' tab — an overlay may be blocking the tab bar."


@mcp.tool()
def list_world_cities() -> dict:
    """List the cities currently shown in the World Clock tab.

    Works from any screen — self-navigates to the World Clock tab and
    dismisses any open overlay first; no need to pre-navigate.

    Returns:
      ``{"cities": [<slug>, ...], "count": int}`` — each slug is the city's
      display name lowercased with spaces->underscores (e.g. "new_york").
      To add a city pass its display name to `add_world_city`.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_world")
    tree = sim.observe_text()
    slugs = sorted(set(re.findall(r'clock_world_city_([^"\s]+)', tree)))
    return {"cities": slugs, "count": len(slugs)}


@mcp.tool()
def add_world_city(city_name: str) -> str:
    """Add a city to the World Clock by searching for it and tapping the match.

    Works from any screen — self-navigates to the World Clock tab, opens the
    add-city search sheet, types the name, and selects the matching result.

    Args:
      city_name: the city's DISPLAY name (e.g. "Tokyo", "New York", "paris").
        Matched case-insensitively against the live search results: an exact
        name wins, else a substring match, so partial/lowercased names work.

    Returns a success string listing the cities after the add, or a
    "Could not confirm ..." / "No city matching ..." string (ok:false) when
    the city list did not grow (no optimistic success).
    """
    sim = SimulatorBridge.get()
    # Self-navigate to the World Clock tab (dismisses any overlay) so the +
    # (Add) button is uncovered.
    _ensure_tab(sim, "clock_tab_world")

    def _city_slugs() -> set:
        try:
            tree = sim.observe_text()
        except Exception:
            return set()
        return set(re.findall(r'clock_world_city_([^"\s]+)', tree))

    before_slugs = _city_slugs()

    def _verify_added(label_hint: str) -> str:
        """Dismiss the search sheet and confirm a new city row appeared.

        Returns a success string only when the world-city list actually grew
        (or the typed city now appears) — never a bare optimistic claim.
        """
        _dismiss_overlays(sim)
        _ensure_tab(sim, "clock_tab_world")
        after_slugs = _city_slugs()
        new = after_slugs - before_slugs
        if new:
            return f"Added city '{label_hint}' (now showing: {sorted(after_slugs)})."
        hint_slug = _slug(label_hint.split(",")[0].strip())
        if hint_slug in after_slugs:
            return f"Added city '{label_hint}'."
        return f"Could not confirm city '{city_name}' was added (list unchanged)."

    # Tap the + button — system add barButton has label "Add"
    try:
        sim.tap_id("Add")
    except Exception:
        return "Could not find Add button — ensure you're on the World Clock tab."
    sim.wait(0.5)
    # Type into search
    try:
        sim.tap_id("worldclock.search")
    except Exception:
        pass
    sim.wait(0.2)
    sim.type_text(city_name)
    sim.wait(0.6)
    # Tap the matching result. Try exact id first, then resolve by a
    # case-insensitive / substring match against the result cells so partial
    # or differently-cased names ("paris", "new york") still resolve.
    try:
        sim.tap_id(city_name)
        sim.wait(0.4)
        return _verify_added(city_name)
    except Exception:
        pass
    matched = None
    needle = city_name.strip().lower()
    # Resolve against the search-result rows. The result city name is a
    # StaticText whose name/label is the city ("San Francisco"); tapping it
    # selects the row. Case-insensitive exact match wins over a substring.
    for cls in ("XCUIElementTypeStaticText", "XCUIElementTypeCell"):
        try:
            els = sim.driver.find_elements("class name", cls)
        except Exception:
            els = []
        exact, sub = None, None
        for el in els:
            label = (el.get_attribute("label") or el.get_attribute("name") or "")
            base = label.split(",")[0].strip().lower()
            if not base:
                continue
            # skip the timezone-abbreviation static texts (all-caps, short)
            if cls.endswith("StaticText") and label.isupper() and len(label) <= 4:
                continue
            if base == needle and exact is None:
                exact = (el, label)
            elif needle and needle in base and sub is None:
                sub = (el, label)
        chosen = exact or sub
        if chosen is not None:
            try:
                chosen[0].click()
                matched = chosen[1].split(",")[0].strip()
                sim.wait(0.4)
                break
            except Exception:
                continue
    if matched is not None:
        return _verify_added(matched)
    return f"No city matching '{city_name}' in search results."


@mcp.tool()
def list_alarms() -> dict:
    """List the alarms visible in the Alarm tab.

    Works from any screen — self-navigates to the Alarm tab and dismisses any
    overlay first; no need to pre-navigate.

    Returns:
      ``{"alarms": [<slug>, ...], "count": int}`` — each slug is the alarm's
      label lowercased with spaces->underscores ("Wake up"->"wake_up"), or
      ``idxN`` for an unlabeled alarm (N = row index). Pass either the label
      or the slug to `toggle_alarm`.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_alarm")
    tree = sim.observe_text()
    slugs = sorted(set(re.findall(r'clock_alarm_row_([^"\s]+)', tree)))
    return {"alarms": slugs, "count": len(slugs)}


@mcp.tool()
def toggle_alarm(label_or_index: str) -> str:
    """Toggle an alarm's on/off switch.

    Works from any screen — self-navigates to the Alarm tab and dismisses any
    overlay first.

    Args:
      label_or_index: the alarm's LABEL (case-insensitive; spaces auto-slugged,
        e.g. "Wake up"), or its slug / synthetic ``"idxN"`` form for an
        unlabeled alarm. Substring matches against alarm rows are accepted.
        Get valid values from `list_alarms()`.

    Confirms the switch value actually flipped before returning success;
    returns "No alarm toggle matching ..." (ok:false) if nothing matched.
    """
    sim = SimulatorBridge.get()
    # Ensure the Alarm tab is active AND any overlay (search / add-alarm
    # sheet) is dismissed, so the rows/toggles are uncovered in the tree.
    # Without this, a toggle id found behind a sheet gets "tapped" with no
    # effect yet falsely reported as success.
    _ensure_tab(sim, "clock_tab_alarm")
    raw = label_or_index.strip()
    slug = _slug(raw)

    def _tap_and_verify(tid: str) -> bool:
        """Tap a toggle id and confirm its value flipped (no false positive)."""
        before = _read(sim, tid)
        try:
            sim.tap_id(tid); sim.wait(0.4)
        except Exception:
            return False
        after = _read(sim, tid)
        # A real flip changes the switch value ("0"<->"1"). If we can't read
        # a value (e.g. covered), treat as failure rather than guess success.
        return bool(after) and bool(before) and after != before

    # Primary: the toggle id is clock_alarm_toggle_<labelSlug> (labeled
    # alarms) or clock_alarm_toggle_idx<row> (unlabeled).
    aid = f"clock_alarm_toggle_{slug}"
    if _tap_and_verify(aid):
        return f"Toggled alarm '{label_or_index}'."
    # Fallback: resolve label -> row index by scanning cells, then tap the
    # row-indexed toggle. Handles labels that don't slug-match the id and
    # the synthetic "idxN" form.
    try:
        cells = sim.driver.find_elements("class name", "XCUIElementTypeCell")
        for idx, cell in enumerate(cells):
            cid = (cell.get_attribute("name") or "")
            clabel = (cell.get_attribute("label") or "")
            if not cid.startswith("clock_alarm_row_"):
                continue
            row_slug = cid[len("clock_alarm_row_"):]
            if (raw.lower() in clabel.lower()
                    or slug == row_slug
                    or slug in row_slug
                    or raw.lower() == f"idx{idx}"):
                for tid in (f"clock_alarm_toggle_{row_slug}",
                            f"clock_alarm_toggle_idx{idx}"):
                    if _tap_and_verify(tid):
                        return f"Toggled alarm '{label_or_index}' (row {idx})."
    except Exception:
        pass
    return f"No alarm toggle matching '{label_or_index}'. Try {list_alarms()}."


@mcp.tool()
def open_add_alarm() -> str:
    """Open the add-alarm sheet (the Alarm tab's + button).

    Works from any screen — self-navigates to the Alarm tab and dismisses any
    overlay first, then waits for the modal to actually appear. After it
    returns the sheet's time picker and label field are reachable; commit
    with `save_alarm()` or discard with `cancel_add_alarm()`. For a one-shot
    create, prefer `add_alarm(time, label)` instead.
    """
    sim = SimulatorBridge.get()
    if _open_alarm_sheet(sim):
        return "Opened add-alarm sheet."
    return "Could not open the add-alarm sheet — ensure you're on the Alarm tab."


def _set_alarm_time_picker(sim, hour: int, minute: int, am_pm: str) -> tuple[bool, str]:
    """Set the UIDatePicker wheels on the AddAlarm sheet to (hour, minute, am_pm).

    The picker is a UIDatePicker(.wheels) with three wheels: Hour, Minute,
    AM/PM. Uses the XCUITest `value` setter via predicate-found wheel
    elements. Returns (ok, message).
    """
    try:
        # Find the three picker wheels via predicate
        wheels = sim.driver.find_elements("class name", "XCUIElementTypePickerWheel")
        if len(wheels) < 3:
            return False, f"Expected 3 picker wheels, found {len(wheels)}."
        h_str = str(int(hour) if hour <= 12 else hour - 12)
        m_str = f"{int(minute):02d}"
        wheels[0].send_keys(h_str)
        wheels[1].send_keys(m_str)
        wheels[2].send_keys(am_pm.upper())
        sim.wait(0.3)
        return True, f"Set picker to {h_str}:{m_str} {am_pm.upper()}"
    except Exception:
        return False, "Picker wheels are unavailable through the current automation session."


@mcp.tool()
def add_alarm(time: str, label: str = "") -> str:
    """Create a new alarm end-to-end: open sheet, set time/label, save.

    Works from any screen — self-navigates to the Alarm tab, opens the sheet,
    drives the three UIDatePicker wheels (Hour, Minute, AM/PM), fills the
    optional label field, and taps Save.

    Args:
      time: clock string. 12-hour form with colon and AM/PM marker
        ("6:45 AM", "11:30 PM"), OR 24-hour form ("18:15"). Other forms
        return "Could not add alarm: bad time ..." (ok:false).
      label: optional alarm label (e.g. "Wake up"); becomes the alarm's slug.
        Empty string leaves it unlabeled.

    Verifies a new alarm row appeared and returns "Could not confirm ..."
    (ok:false) if the alarm list did not change.
    """
    import re
    sim = SimulatorBridge.get()
    # Parse time
    s = time.strip().upper().replace(" ", "")
    m = re.match(r"^(\d{1,2}):(\d{2})(AM|PM)?$", s)
    if not m:
        # "Bad time ..." is not caught by the failure-prefix detector and
        # would be marked ok:true; prefix with "Could not" for a true ok:false.
        return f"Could not add alarm: bad time '{time}'. Use '6:45 AM' or '18:15'."
    h, mi, ap = int(m.group(1)), int(m.group(2)), m.group(3)
    if ap is None:
        ap = "PM" if h >= 12 else "AM"
        h = h % 12 or 12
    def _alarm_slugs() -> set:
        try:
            tree = sim.observe_text()
        except Exception:
            return set()
        return set(re.findall(r'clock_alarm_row_([^"\s]+)', tree))

    # Capture the existing alarm rows so we can confirm a NEW one appears.
    _ensure_tab(sim, "clock_tab_alarm")
    before_alarms = _alarm_slugs()
    # Navigate + open the sheet (waits for the modal to actually appear).
    if not _open_alarm_sheet(sim):
        return _ui_unavailable("add_alarm", "Add alarm button")
    ok, msg = _set_alarm_time_picker(sim, h, mi, ap)
    if not ok:
        # Best-effort: still let user save; they can fix time via observe + sim_tap_xy
        pass
    if label:
        # The label UITextField doesn't have an explicit ID; tap by class
        try:
            tfs = sim.driver.find_elements("class name", "XCUIElementTypeTextField")
            if tfs:
                tfs[0].click(); sim.wait(0.3)
                tfs[0].send_keys(label); sim.wait(0.3)
        except Exception:
            pass
    # Save (dismisses keyboard + retries past the page_source race).
    if not _tap_save(sim):
        return _ui_unavailable("add_alarm", "Save button")
    # Verify a new alarm row actually appeared (no optimistic success).
    _ensure_tab(sim, "clock_tab_alarm")
    after_alarms = _alarm_slugs()
    new = after_alarms - before_alarms
    label_slug = _slug(label) if label else ""
    confirmed = bool(new) or (label_slug and label_slug in after_alarms)
    if not confirmed:
        return (f"Could not confirm alarm '{label or '(no label)'}' at "
                f"{h}:{mi:02d} {ap} was saved (alarm list unchanged).")
    return (f"Added alarm '{label or '(no label)'}' at {h}:{mi:02d} {ap}. "
            f"Picker: {msg}. New rows: {sorted(new) or sorted(after_alarms)}")


@mcp.tool()
def save_alarm() -> str:
    """Commit the in-flight alarm by tapping the Save bar button.

    Requires the add-alarm sheet to already be open (call `open_add_alarm()`
    first) — this tool does NOT open it; it returns an ok:false envelope if no
    sheet is up. Use this when you filled the picker/label manually rather
    than via `add_alarm()`. Dismisses the keyboard before tapping Save.
    """
    sim = SimulatorBridge.get()
    if not _sheet_open(sim):
        return _ui_unavailable("save_alarm", "Save button")
    if not _tap_save(sim):
        return _ui_unavailable("save_alarm", "Save button")
    return "Alarm saved."


@mcp.tool()
def cancel_add_alarm() -> str:
    """Discard the in-flight alarm by tapping the Cancel bar button.

    Requires the add-alarm sheet to already be open — this tool does NOT open
    it and returns an ok:false envelope if no sheet is up. No changes are
    persisted.
    """
    sim = SimulatorBridge.get()
    if not _sheet_open(sim):
        return _ui_unavailable("cancel_add_alarm", "Cancel button")
    try: sim.tap_id("Cancel"); sim.wait(0.3)
    except Exception as e: return f"Could not cancel add-alarm sheet: {e}"
    return "Cancelled."


@mcp.tool()
def start_stop_stopwatch() -> str:
    """Toggle the stopwatch's start/stop button.

    Works from any screen — self-navigates to the Stopwatch tab first. The
    button is a single toggle: starts a stopped stopwatch ("Start"->"Stop"),
    stops a running one ("Stop"->"Start").

    Returns a string with the running state and post-tap display (e.g.
    "Stopwatch running. Display: 00:01.23"), or "Could not confirm ..."
    (ok:false) if the button title did not flip.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_stopwatch")
    before_lbl = _label(sim, "clock_stopwatch_start_stop")
    try:
        sim.tap_id("clock_stopwatch_start_stop")
    except Exception:
        return "Could not toggle the stopwatch — start/stop button not reachable."
    sim.wait(0.3)
    after_lbl = _label(sim, "clock_stopwatch_start_stop")
    disp = _read(sim, "clock_stopwatch_display")
    # Button title flips Start<->Stop on a real toggle; verify it changed.
    if before_lbl and after_lbl and after_lbl == before_lbl:
        return (f"Could not confirm the stopwatch toggled (button still "
                f"'{after_lbl}', display {disp}).")
    state = "running" if (after_lbl or "").strip().lower() == "stop" else "stopped"
    return f"Stopwatch {state}. Display: {disp}"


@mcp.tool()
def stopwatch_lap_reset() -> str:
    """Tap the polymorphic Lap/Reset button on the stopwatch.

    Works from any screen — self-navigates to the Stopwatch tab first. The
    button acts as Lap when the stopwatch is RUNNING and Reset when STOPPED.
    Prefer `stopwatch_lap()` / `stopwatch_reset()` for explicit semantics.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_stopwatch")
    sim.tap_id("clock_stopwatch_lap_reset")
    sim.wait(0.3)
    return f"Stopwatch display: {_read(sim, 'clock_stopwatch_display')}"


@mcp.tool()
def stopwatch_lap() -> str:
    """Record a lap split (explicit-semantics wrapper around the Lap/Reset button).

    Works from any screen — self-navigates to the Stopwatch tab first. The
    stopwatch must be RUNNING for this to lap; call `start_stop_stopwatch()`
    first if it isn't, otherwise the button resets the stopwatch instead.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_stopwatch")
    if (_label(sim, "clock_stopwatch_start_stop") or "").lower() != "stop":
        return (
            "Could not lap stopwatch: it is not running. "
            "Call start_stop_stopwatch() first, then retry stopwatch_lap()."
        )
    sim.tap_id("clock_stopwatch_lap_reset")
    sim.wait(0.3)
    return f"Lapped. Stopwatch display: {_read(sim, 'clock_stopwatch_display')}"


@mcp.tool()
def stopwatch_reset() -> str:
    """Reset the stopwatch to 00:00 (explicit-semantics wrapper around Lap/Reset).

    Works from any screen — self-navigates to the Stopwatch tab first. The
    stopwatch must be STOPPED for this to reset; call `start_stop_stopwatch()`
    to stop it first if it is running, otherwise the button records a lap.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_stopwatch")
    if (_label(sim, "clock_stopwatch_start_stop") or "").lower() != "start":
        return (
            "Could not reset stopwatch: it is still running. "
            "Call start_stop_stopwatch() to stop it first, then retry stopwatch_reset()."
        )
    sim.tap_id("clock_stopwatch_lap_reset")
    sim.wait(0.3)
    return f"Reset. Stopwatch display: {_read(sim, 'clock_stopwatch_display')}"


@mcp.tool()
def read_stopwatch() -> dict:
    """Read the stopwatch display string.

    Works from any screen — self-navigates to the Stopwatch tab first so the
    display element is present in the tree.

    Returns:
      ``{"display": "MM:SS.cc" | None}`` — None if the display could not be
      read.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_stopwatch")
    val = ""
    for _ in range(3):
        val = _read(sim, "clock_stopwatch_display")
        if val:
            break
        sim.wait(0.3)
    return {"display": val or None}


@mcp.tool()
def start_stop_timer() -> str:
    """Toggle the timer's start/pause button.

    Works from any screen — self-navigates to the Timer tab first. Starts a
    paused/stopped timer ("Start"->"Pause") or pauses a running one.

    NOTE: there is no MCP tool to SET the timer duration. Start is a guarded
    no-op while the display reads 00:00:00 (no duration configured); this
    tool then returns "Could not start the timer: no duration is set ..."
    (ok:false). Set the duration by tapping the clock_timer_duration_picker
    wheels with generic sim tools first.

    Returns the running/paused state and post-tap display, or a
    "Could not ..." string (ok:false) when the toggle could not be confirmed.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_timer")
    before_lbl = _label(sim, "clock_timer_start_stop")
    before_disp = _read(sim, "clock_timer_display")
    try:
        sim.tap_id("clock_timer_start_stop")
    except Exception:
        return "Could not toggle the timer — start/stop button not reachable."
    sim.wait(0.4)
    after_lbl = _label(sim, "clock_timer_start_stop")
    after_disp = _read(sim, "clock_timer_display")
    # A real toggle flips the button title Start<->Pause. If the title is
    # unchanged AND it's still "Start" with a 00:00:00 display, the timer has
    # no configured duration and Start is a guarded no-op — report honestly
    # rather than claim a false success.
    if after_lbl == before_lbl:
        if (after_lbl or "").strip().lower() == "start" and \
                after_disp.replace(":", "").strip("0") == "":
            return ("Could not start the timer: no duration is set "
                    "(display 00:00:00). Set the duration picker first.")
        # Couldn't confirm a state change; surface honestly.
        return (f"Could not confirm the timer toggled (button still "
                f"'{after_lbl}', display {after_disp}).")
    state = "running" if (after_lbl or "").strip().lower() == "pause" else "paused"
    return f"Timer {state}. Display: {after_disp}"


@mcp.tool()
def reset_timer() -> str:
    """Cancel/reset the active timer back to its configured duration.

    Works from any screen — self-navigates to the Timer tab first. Pauses a
    running timer and restores the display to the duration picked on
    clock_timer_duration_picker.

    Returns a string with the post-reset display value.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_timer")
    sim.tap_id("clock_timer_reset")
    sim.wait(0.3)
    return f"Timer display: {_read(sim, 'clock_timer_display')}"


@mcp.tool()
def read_timer() -> dict:
    """Read the timer's current display string.

    Works from any screen — self-navigates to the Timer tab first so the
    display element is present in the tree.

    Returns:
      ``{"display": "HH:MM:SS" | None}`` — None if the display could not be
      read.
    """
    sim = SimulatorBridge.get()
    _ensure_tab(sim, "clock_tab_timer")
    val = ""
    for _ in range(3):
        val = _read(sim, "clock_timer_display")
        if val:
            break
        sim.wait(0.3)
    return {"display": val or None}


if __name__ == "__main__":
    mcp.run()
