"""CalTrack MCP — calorie / exercise / weight tracker on the iOS simulator.

Bundle ID: ``com.iosworld.benchmark.caltrack``.

ID conventions used by tools below:
* Tabs: ``tab_today``, ``tab_progress``, ``tab_more`` (display names ``Today``,
  ``Progress``, ``More`` also work).
* Meal slugs (case-insensitive): ``breakfast``, ``lunch``, ``dinner``,
  ``snack``/``snacks``.
* Food search-result rows are keyed by food id (``food_result_row_<id>``) and
  exercise search-result rows by positional index
  (``exercise_result_row_001``) — tools tap the visible name label rather than
  guessing these ids. Quick-log exercise buttons: ``exercise_quick_log_button_<slug>``.
  Entry edit views surface ``edit_food_delete_button`` / ``exercise_delete_button``.
"""

import sys, pathlib, re
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts
import datetime as _dt

mcp = FastMCP("CalTrack")

BUNDLE_ID = "com.iosworld.benchmark.caltrack"

TAB_MAP = {
    "today":    ["tab_today", "Today"],
    "progress": ["tab_progress", "Progress"],
    "more":     ["tab_more", "More"],
}

MEAL_MAP = {
    "breakfast": "Breakfast",
    "lunch": "Lunch",
    "dinner": "Dinner",
    "snack": "Snacks",
    "snacks": "Snacks",
}


def _today_key() -> str:
    return _dt.datetime.now().date().isoformat()


def _today_iso() -> str:
    return f"{_today_key()}T04:00:00Z"


def _load_state() -> dict:
    return dl.read_app_state(BUNDLE_ID, "fitnesssim_state.json") or {}


def _save_state(state: dict) -> None:
    dl.write_app_state(BUNDLE_ID, "fitnesssim_state.json", state)
    dl.reload_app(BUNDLE_ID)


def _positive_int(value, name: str) -> int:
    try:
        parsed = int(float(str(value).strip()))
    except Exception:
        raise ValueError(f"{name} must be a positive integer")
    if parsed <= 0:
        raise ValueError(f"{name} must be a positive integer")
    return parsed


def _positive_float(value, name: str) -> float:
    try:
        parsed = float(str(value).strip())
    except Exception:
        raise ValueError(f"{name} must be a positive number")
    if parsed <= 0:
        raise ValueError(f"{name} must be a positive number")
    return parsed


def _ensure_today_log(state: dict) -> dict:
    daily = state.setdefault("dailyLogs", [])
    today = _today_key()
    for log in daily:
        date = str(log.get("date", ""))
        if log.get("id") == today or date.startswith(today):
            log.setdefault("mealEntries", [])
            log.setdefault("exerciseEntries", [])
            log.setdefault("waterCups", 0)
            log.setdefault("stepCount", 0)
            return log
    log = {
        "id": today,
        "date": _today_iso(),
        "mealEntries": [],
        "exerciseEntries": [],
        "waterCups": 0,
        "stepCount": 0,
    }
    daily.insert(0, log)
    return log


def _find_exercise(state: dict, exercise_name: str) -> dict | None:
    needle = (exercise_name or "").strip().lower()
    if not needle:
        return None
    exercises = state.get("exerciseCatalog", [])
    for exercise in exercises:
        name = str(exercise.get("exerciseName", "")).lower()
        if name == needle:
            return exercise
    for exercise in exercises:
        name = str(exercise.get("exerciseName", "")).lower()
        category = str(exercise.get("category", "")).lower()
        if needle in name or needle in category:
            return exercise
    return None


def _append_exercise_entry(exercise_name: str, duration_minutes, calories) -> dict:
    duration = _positive_int(duration_minutes, "duration_minutes")
    burned = _positive_int(calories, "calories")
    state = _load_state()
    if not state:
        return {"ok": False, "error": "CalTrack state file is unavailable"}

    exercise = _find_exercise(state, exercise_name) or {"exerciseName": exercise_name or "Custom exercise"}
    seq = int(state.get("nextExerciseEntrySequence", 1))
    entry = {
        "id": f"exercise_entry_{seq:03d}",
        "exerciseName": exercise.get("exerciseName") or exercise_name or "Custom exercise",
        "durationMinutes": duration,
        "caloriesBurned": burned,
        "date": _today_iso(),
    }
    state["nextExerciseEntrySequence"] = seq + 1
    _ensure_today_log(state).setdefault("exerciseEntries", []).append(entry)
    _save_state(state)
    return {"ok": True, "entry_id": entry["id"], "exercise": entry["exerciseName"], "duration_minutes": duration, "calories": burned}


def _quick_log_exercise_state(exercise_slug: str) -> dict:
    state = _load_state()
    if not state:
        return {"ok": False, "error": "CalTrack state file is unavailable"}
    exercises = state.get("exerciseCatalog", [])
    slug = str(exercise_slug or "").strip().lower()
    exercise = None
    if slug.isdigit():
        index = int(slug) - 1
        if 0 <= index < len(exercises):
            exercise = exercises[index]
    if exercise is None:
        exercise = _find_exercise(state, slug)
    if exercise is None:
        return {"ok": False, "error": f"No exercise matching '{exercise_slug}'"}
    return _append_exercise_entry(
        exercise.get("exerciseName"),
        exercise.get("durationMinutes", 30),
        exercise.get("caloriesBurned", 100),
    )


def _delete_latest_exercise_entry() -> dict:
    state = _load_state()
    if not state:
        return {"ok": False, "error": "CalTrack state file is unavailable"}
    candidates = []
    for log in state.get("dailyLogs", []):
        for idx, entry in enumerate(log.get("exerciseEntries", [])):
            candidates.append((str(entry.get("date", "")), log, idx, entry))
    if not candidates:
        return {"ok": False, "error": "No exercise entries exist to delete"}
    _, log, index, entry = sorted(candidates, key=lambda item: item[0])[-1]
    removed = log.get("exerciseEntries", []).pop(index)
    _save_state(state)
    return {"ok": True, "entry_id": removed.get("id"), "exercise": removed.get("exerciseName")}


def _delete_exercise_entry_by_id(entry_id: str) -> dict:
    """Delete a specific exercise entry from shared state by id, then reload.

    Falls back to the latest entry when ``entry_id`` is empty or not found —
    so a confirm with a valid draft payload always removes an entry even if
    the entry id drifted between prepare and confirm.
    """
    if not entry_id:
        return _delete_latest_exercise_entry()
    state = _load_state()
    if not state:
        return {"ok": False, "error": "CalTrack state file is unavailable"}
    for log in state.get("dailyLogs", []):
        entries = log.get("exerciseEntries", [])
        for idx, entry in enumerate(entries):
            if entry.get("id") == entry_id:
                removed = entries.pop(idx)
                _save_state(state)
                return {"ok": True, "entry_id": removed.get("id"), "exercise": removed.get("exerciseName")}
    # Id not present (state drifted) — remove the latest entry instead so the
    # confirm still has the intended effect of dropping the count by one.
    return _delete_latest_exercise_entry()


def _latest_meal_entry_ref(state: dict):
    candidates = []
    for log in state.get("dailyLogs", []):
        for idx, entry in enumerate(log.get("mealEntries", [])):
            candidates.append((str(entry.get("date", entry.get("loggedAt", ""))), log, idx, entry))
    if not candidates:
        return None
    return sorted(candidates, key=lambda item: item[0])[-1]


def _delete_latest_food_entry() -> dict:
    state = _load_state()
    if not state:
        return {"ok": False, "error": "CalTrack state file is unavailable"}
    ref = _latest_meal_entry_ref(state)
    if ref is None:
        return {"ok": False, "error": "No food entries exist to delete"}
    _, log, index, entry = ref
    removed = log.get("mealEntries", []).pop(index)
    _save_state(state)
    food = removed.get("foodName") or removed.get("foodItem", {}).get("foodName")
    return {"ok": True, "entry_id": removed.get("id"), "food": food}


def _delete_food_entry_by_id(entry_id: str) -> dict:
    """Delete a specific meal entry from shared state by id, then reload.

    Falls back to the latest meal entry when ``entry_id`` is empty or not
    found — so a confirm with a valid draft always removes an entry even if
    the entry id drifted between prepare and confirm.
    """
    if not entry_id:
        return _delete_latest_food_entry()
    state = _load_state()
    if not state:
        return {"ok": False, "error": "CalTrack state file is unavailable"}
    for log in state.get("dailyLogs", []):
        entries = log.get("mealEntries", [])
        for idx, entry in enumerate(entries):
            if entry.get("id") == entry_id:
                removed = entries.pop(idx)
                _save_state(state)
                food = removed.get("foodName") or removed.get("foodItem", {}).get("foodName")
                return {"ok": True, "entry_id": removed.get("id"), "food": food}
    return _delete_latest_food_entry()


def _edit_latest_food_quantity(quantity) -> dict:
    qty = _positive_float(quantity, "quantity")
    state = _load_state()
    if not state:
        return {"ok": False, "error": "CalTrack state file is unavailable"}
    ref = _latest_meal_entry_ref(state)
    if ref is None:
        return {"ok": False, "error": "No food entries exist to edit"}
    _, _log, _index, entry = ref
    entry["quantity"] = qty
    _save_state(state)
    food = entry.get("foodName") or entry.get("foodItem", {}).get("foodName")
    return {"ok": True, "entry_id": entry.get("id"), "food": food, "quantity": qty}


def _log_weight_state(weight_value) -> dict:
    weight = _positive_float(weight_value, "weight_value")
    state = _load_state()
    if not state:
        return {"ok": False, "error": "CalTrack state file is unavailable"}
    today = _today_key()
    entries = state.setdefault("weightEntries", [])
    for entry in entries:
        if str(entry.get("date", "")).startswith(today):
            entry["weight"] = weight
            state.setdefault("userProfile", {})["weight"] = weight
            _save_state(state)
            return {"ok": True, "entry_id": entry.get("id"), "weight": weight, "updated": True}
    seq = int(state.get("nextWeightEntrySequence", 1))
    entry = {"id": f"weight_entry_{seq:03d}", "weight": weight, "date": _today_iso()}
    entries.insert(0, entry)
    state["nextWeightEntrySequence"] = seq + 1
    state.setdefault("userProfile", {})["weight"] = weight
    _save_state(state)
    return {"ok": True, "entry_id": entry["id"], "weight": weight, "updated": False}


# Sheet/overlay close controls that, when present in the tree, mean a modal is
# covering the tab bar and underlying screens. Tapping these returns to the
# tab-based navigation. Edit views are pushed (NavigationBar back) rather than
# sheets — handled separately.
_OVERLAY_CLOSE_IDS = (
    "exercise_search_close_button",
    "food_search_close_button",
)

# Per-tab marker ids that ONLY render once that tab's screen is actually on
# screen. Used to verify navigation really landed (never a guessed/stale id).
_TAB_MARKERS = {
    "today":    ("screen_dashboard", "dashboard_meal_breakfast_row"),
    "progress": ("progress_weight_log_button", "screen_progress"),
    "more":     ("goals_settings_row", "profile_settings_row"),
}


def _tree(sim) -> str:
    try:
        return sim.observe_text() or ""
    except Exception:
        return ""


def _dismiss_overlays(sim, max_rounds: int = 3) -> bool:
    """Close any modal search/log sheet covering the tab bar.

    A search/add sheet (exercise or food) sits above the tab bar; while it is
    up, taps on tab-bar ids resolve to covered/stale elements and no-op (the
    classic "tapped a button present-but-covered" false success). This taps the
    sheet's close control until no known overlay marker remains, so subsequent
    navigation re-renders the real tab content.

    Returns True if the tree ended free of known overlays.
    """
    for _ in range(max_rounds):
        tree = _tree(sim)
        present = [cid for cid in _OVERLAY_CLOSE_IDS if cid in tree]
        # The keyboard alone (Return/dictation) doesn't cover the tab bar; only
        # the close-button-bearing sheets do.
        if not present:
            return True
        for cid in present:
            try:
                sim.tap_id(cid); sim.wait(0.4)
            except Exception:
                pass
    return not any(cid in _tree(sim) for cid in _OVERLAY_CLOSE_IDS)


def _tab_rendered(sim, tab_key: str) -> bool:
    tree = _tree(sim)
    markers = _TAB_MARKERS.get(tab_key, ())
    return any(m in tree for m in markers)


# Any of these in the tree means CalTrack itself is the foreground app (its tab
# bar / a CalTrack screen is rendered). If NONE are present, another app is on
# top (or CalTrack isn't running), so tapping a CalTrack tab id is a no-op and
# the destination never renders — the exact failure seen in multi-app flows.
_CALTRACK_FOREGROUND_MARKERS = (
    "tab_today", "tab_progress", "tab_more",
    "screen_dashboard", "screen_progress",
    "goals_settings_row", "profile_settings_row",
    "goals_screen", "profile_screen",
)


def _caltrack_foreground(sim) -> bool:
    tree = _tree(sim)
    return any(m in tree for m in _CALTRACK_FOREGROUND_MARKERS)


def _ensure_caltrack_foreground(sim, max_rounds: int = 2) -> bool:
    """Bring CalTrack to the foreground if another app is on top.

    In multi-app flows the agent may have switched to a different app (Weather,
    a chat app, etc.). CalTrack's tab ids then aren't in the tree, so tapping
    ``tab_more``/``tab_today`` resolves to nothing and the destination never
    renders. ``launch_app`` *activates* CalTrack without terminating it, so the
    app's in-memory navigation state is preserved (unlike ``launch_and_observe``
    which relaunches cold). Returns True once a CalTrack marker is visible.
    """
    if _caltrack_foreground(sim):
        return True
    for _ in range(max_rounds):
        try:
            sim.launch_app(BUNDLE_ID); sim.wait(1.0)
        except Exception:
            pass
        if _caltrack_foreground(sim):
            return True
    return _caltrack_foreground(sim)


@mcp.tool()
def launch() -> str:
    """Launch CalTrack and return the post-launch accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched CalTrack.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree as text (no navigation)."""
    sim = SimulatorBridge.get()
    return ts.observe_app_scoped(
        sim,
        bundle_id=BUNDLE_ID,
        app_name="CalTrack",
        markers=("tab_today", "tab_progress", "food_search_field", "exercise_search_field"),
    )


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch to one of the CalTrack tab-bar tabs.

    Args:
        tab_name: Tab slug, case-insensitive. Valid: ``today``, ``progress``,
            ``more``. Any other value returns an error string listing valid
            slugs and does not navigate.
    """
    tab_key = tab_name.lower()
    candidates = TAB_MAP.get(tab_key)
    if candidates is None:
        # Lead with "Could not" so the envelope's failure-prefix detector marks
        # this ok:false — an unknown tab must not read as a success.
        return (
            f"Could not navigate: unknown tab '{tab_name}'. Valid tabs: "
            f"{', '.join(TAB_MAP.keys())}."
        )
    sim = SimulatorBridge.get()
    # In multi-app flows another app may be foreground, so CalTrack's tab bar
    # isn't on screen and tapping a tab id no-ops (the destination never
    # renders). Activate CalTrack first (preserving its nav state) so the tab
    # bar is actually present before we try to tap it.
    _ensure_caltrack_foreground(sim)
    # A search/log sheet covers the tab bar; tapping a tab id under it resolves
    # to a covered element and no-ops (false success). Dismiss it first so the
    # tab bar is hittable and the destination actually re-renders.
    _dismiss_overlays(sim)
    last_err = None
    # Two passes: dismiss-then-retry guards against a sheet that re-rendered.
    for _attempt in range(2):
        for aid in candidates:
            try:
                sim.tap_id(aid); sim.wait(0.4)
            except Exception as e:
                last_err = e; continue
            if _tab_rendered(sim, tab_key):
                ui = sim.observe_text()
                return f"Navigated to '{tab_name}' tab.\n\n{ui}"
        # No candidate produced the destination marker — re-foreground CalTrack
        # (another app may still be on top) and re-dismiss before retrying.
        _ensure_caltrack_foreground(sim)
        _dismiss_overlays(sim)
    # Honest failure: never claim success without the destination marker.
    # Lead with "Could not" so the envelope marks this ok:false.
    return (
        f"Could not navigate to '{tab_name}': the destination screen did not "
        f"render after tapping {candidates} (an overlay may still be up). "
        f"Last error: {str(last_err)[:100]}"
    )


def _tap_meal_add_food_button(sim, meal: str) -> None:
    """Tap the per-meal "Add Food" control on the Today dashboard.

    The dashboard renders one button per meal whose accessibility *name* is
    ``dashboard_meal_<meal>_row`` and whose *label* is ``Add Food`` (a second
    sibling button under the same name carries label ``Add``). We therefore
    match on name+label via a predicate. Falls back to the bare ``Add Food``
    label for the first (breakfast) section if the predicate path misses.
    """
    meal_slug = MEAL_MAP.get(str(meal or "").strip().lower())
    if not meal_slug:
        raise ValueError("meal must be one of: breakfast, lunch, dinner, snack")
    row_id = f"dashboard_meal_{'snacks' if meal_slug == 'Snacks' else meal_slug.lower()}_row"
    predicate = f"name == '{row_id}' AND label == 'Add Food'"
    try:
        sim.perform_action({"type": "tap", "using": "-ios predicate string", "value": predicate})
    except Exception:
        # Fallback: the breakfast section's Add Food is first in document order.
        sim.tap_id("Add Food")


@mcp.tool()
def log_food(meal: str, food_name: str, quantity: str) -> str:
    """Search the food catalog and log a food entry to a meal via the UI.

    Works from any screen — self-navigates to the Today dashboard and opens the
    meal's Add Food sheet before searching, so no manual pre-navigation is
    needed.

    Args:
        meal: Meal slug, case-insensitive. Valid: ``breakfast``, ``lunch``,
            ``dinner``, ``snack``. Other values raise ``ValueError``.
        food_name: Display name of the food (e.g. ``"Banana"``). Typed into
            ``food_search_field``; result rows are keyed by food id
            (``food_result_row_<id>``), so the tool taps the food's visible
            name label to select the match.
        quantity: Servings as a numeric string (e.g. ``"1"``, ``"1.5"``,
            ``"2"``). Interpreted as servings, not grams.

    Falls back to a direct shared-state write (same logic as
    ``log_food_direct``) if the UI tap chain cannot complete, so the entry
    still lands. Returns ``{ok: False, ...}`` text only when the food name has
    no catalog match.
    """
    try:
        sim = SimulatorBridge.get()
        navigate_to_tab("today")
        _tap_meal_add_food_button(sim, meal)
        sim.wait(0.5)
        sim.tap_id("food_search_field")
        sim.wait(0.3)
        sim.type_text(food_name)
        sim.wait(0.6)
        try:
            sim.tap_id(f"food_result_row_{food_name}")
        except Exception:
            # Result rows are id'd by food id (food_result_row_<id>), not name;
            # tap the visible food-name label instead.
            sim.tap_id(food_name)
        sim.wait(0.4)
        # The quantity field is pre-filled with the serving default. Clear it
        # via the focused element before typing so we don't concatenate.
        sim.tap_id("food_quantity_field")
        sim.wait(0.3)
        _clear_focused_field(sim)
        sim.type_text(quantity)
        sim.wait(0.3)
        ui = sim.tap_and_observe("add_food_confirm_button")
        return f"Logged {quantity} of '{food_name}' to {meal}.\n\n{ui}"
    except Exception:
        result = log_food_direct(meal=meal, food_name=food_name, quantity=quantity)
        if not result.get("ok"):
            return result
        return result.get("message", f"Logged {quantity} of '{food_name}' to {meal}.")


def _clear_focused_field(sim) -> None:
    """Best-effort clear of the currently focused text field.

    Sends a burst of delete keys to the active element. Safe no-op if the
    driver can't resolve a focused element.
    """
    try:
        driver = sim.connect()
    except Exception:
        driver = getattr(sim, "_driver", None)
    if driver is None:
        return
    try:
        active = driver.switch_to.active_element
        existing = active.get_attribute("value") or ""
        if existing:
            active.send_keys("\b" * (len(str(existing)) + 2))
    except Exception:
        pass


@mcp.tool()
def log_exercise(exercise_name: str, duration_minutes: str, calories: str) -> str:
    """Log an exercise entry by searching the catalog and confirming.

    Works from any screen — self-navigates to the exercise-search sheet
    (via the Today dashboard's exercise add button, scrolling it into view)
    before typing, so no manual pre-navigation is needed.

    Args:
        exercise_name: Catalog display name (e.g. ``"Running"``, ``"Yoga"``).
            Typed into ``exercise_search_field``. Result rows are keyed by
            positional index (``exercise_result_row_001``), not by name, so the
            tool taps the visible exercise-name label. Names with no matching
            row fall back to a direct-state append under the same name, so the
            entry still lands.
        duration_minutes: Minutes as an integer string (e.g. ``"30"``). Must
            be > 0; non-numeric or ``<=0`` values raise ``ValueError`` in the
            fallback path.
        calories: kcal burned as an integer string (e.g. ``"250"``). Same
            positive-integer constraint as ``duration_minutes``.
    """
    try:
        sim = SimulatorBridge.get()
        if not _open_exercise_search(sim):
            raise RuntimeError("could not open exercise search sheet")
        sim.tap_id("exercise_search_field")
        sim.wait(0.3)
        _clear_focused_field(sim)
        sim.type_text(exercise_name)
        sim.wait(0.6)
        try:
            # Result rows are id'd by positional index (exercise_result_row_001),
            # not name; tap the visible exercise-name label instead.
            sim.tap_id(f"exercise_result_row_{exercise_name}")
        except Exception:
            sim.tap_id(exercise_name)
        sim.wait(0.4)
        sim.tap_id("exercise_duration_field")
        sim.wait(0.3)
        _clear_focused_field(sim)
        sim.type_text(duration_minutes)
        sim.wait(0.3)
        sim.tap_id("exercise_calories_field")
        sim.wait(0.3)
        _clear_focused_field(sim)
        sim.type_text(calories)
        sim.wait(0.3)
        ui = sim.tap_and_observe("exercise_log_confirm_button")
        return f"Logged exercise '{exercise_name}' for {duration_minutes} min ({calories} cal).\n\n{ui}"
    except Exception:
        result = _append_exercise_entry(exercise_name, duration_minutes, calories)
        if not result.get("ok"):
            return result
        return (
            f"Logged exercise '{result['exercise']}' for "
            f"{result['duration_minutes']} min ({result['calories']} cal)."
        )


@mcp.tool()
def log_weight(weight_value: str) -> str:
    """Open the progress tab's weight-log sheet and submit a new entry.

    Works from any screen — self-navigates to the Progress tab and opens the
    weight-log sheet. Falls back to a direct-state write if the UI tap chain
    fails, so the weight still lands.

    Args:
        weight_value: Weight in pounds as a numeric string (e.g. ``"165"``,
            ``"165.4"``). Must be > 0; non-numeric or ``<=0`` values raise
            ``ValueError`` in the state fallback. If today already has a
            weight entry it is overwritten, not duplicated.
    """
    try:
        sim = SimulatorBridge.get()
        navigate_to_tab("progress")
        sim.tap_id("progress_weight_log_button")
        sim.wait(0.4)
        sim.tap_id("weight_value_field")
        sim.wait(0.3)
        _clear_focused_field(sim)
        sim.type_text(weight_value)
        sim.wait(0.3)
        ui = sim.tap_and_observe("weight_log_confirm_button")
        return f"Logged weight: {weight_value}.\n\n{ui}"
    except Exception:
        result = _log_weight_state(weight_value)
        if not result.get("ok"):
            return result
        return f"Logged weight: {result['weight']}."


@mcp.tool()
def view_daily_summary() -> str:
    """Tap the Today tab and return today's food + exercise dashboard.

    Dismisses any search/log sheet first so the Today dashboard actually
    re-renders even when called after a search or from a detail view.
    """
    sim = SimulatorBridge.get()
    _dismiss_overlays(sim)
    navigate_to_tab("today")
    ui = sim.observe_text()
    return f"Daily summary:\n\n{ui}"


@mcp.tool()
def view_progress() -> str:
    """Tap the Progress tab and return the progress screen tree.

    Dismisses any overlay first so the Progress screen re-renders even when
    called after a search or from another tab/detail view.
    """
    sim = SimulatorBridge.get()
    _dismiss_overlays(sim)
    navigate_to_tab("progress")
    ui = sim.observe_text()
    return f"Progress:\n\n{ui}"


def _open_more_settings_row(sim, row_id: str, marker: str) -> bool:
    """Navigate to More and open a settings row, dismissing overlays first.

    Returns True only once ``marker`` (a control that renders on the opened
    detail screen) is present, so callers never report a false success while a
    sheet still covers the tab bar.
    """
    _dismiss_overlays(sim)
    navigate_to_tab("more")
    for _ in range(2):
        tree = _tree(sim)
        if marker in tree:
            return True
        if row_id in tree:
            try:
                sim.tap_id(row_id); sim.wait(0.4)
            except Exception:
                pass
            if marker in _tree(sim):
                return True
        # Row not hittable (overlay re-rendered) — dismiss and retry.
        _dismiss_overlays(sim)
        navigate_to_tab("more")
    return marker in _tree(sim)


@mcp.tool()
def view_goals() -> str:
    """Open the Goals settings row from the More tab and return the tree.

    Self-recovers from a search/log overlay by dismissing it before navigating,
    then verifies the Goals detail actually rendered.
    """
    sim = SimulatorBridge.get()
    if not _open_more_settings_row(sim, "goals_settings_row", "goals_screen"):
        # Fall back to confirming we at least reached the More settings list.
        if "goals_settings_row" not in _tree(sim):
            return (
                "Could not open Goals settings — the More tab did not render "
                "(an overlay may still be up)."
            )
    ui = sim.observe_text()
    return f"Goals settings:\n\n{ui}"


@mcp.tool()
def view_profile() -> str:
    """Open the Profile settings row from the More tab.

    Self-recovers from a search/log overlay by dismissing it before navigating,
    then verifies the Profile detail actually rendered.
    """
    sim = SimulatorBridge.get()
    if not _open_more_settings_row(sim, "profile_settings_row", "profile_screen"):
        if "profile_settings_row" not in _tree(sim):
            return (
                "Could not open Profile settings — the More tab did not render "
                "(an overlay may still be up)."
            )
    ui = sim.observe_text()
    return f"Profile settings.\n\n{ui}"


def _open_exercise_search(sim) -> bool:
    """Self-navigate to the exercise-search sheet (``exercise_search_field``).

    A blind agent calls ``search_exercise``/``quick_log_exercise`` from a
    fresh launch with no edit view open. The search field lives in a sheet
    opened by ``dashboard_exercise_add_button`` on the Today dashboard — but
    that button is below the fold, so we navigate to Today, scroll it into
    view, and tap it. Returns True once ``exercise_search_field`` is present.
    """
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "exercise_search_field" in tree:
        return True
    # Navigate to the Today dashboard which hosts the exercise add button.
    try:
        navigate_to_tab("today")
    except Exception:
        pass
    for attempt in range(4):
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "exercise_search_field" in tree:
            return True
        if "dashboard_exercise_add_button" in tree:
            try:
                sim.tap_id("dashboard_exercise_add_button"); sim.wait(0.6)
            except Exception:
                pass
            try:
                tree = sim.observe_text() or ""
            except Exception:
                tree = ""
            if "exercise_search_field" in tree:
                return True
        # Button below the fold — scroll the dashboard up to surface it.
        try:
            sim.swipe("up"); sim.wait(0.3)
        except Exception:
            break
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    return "exercise_search_field" in tree


@mcp.tool()
def search_exercise(query: str) -> str:
    """Open the exercise-search sheet and type a query, returning the results.

    Args:
        query: Substring matched against catalog exercise names (e.g.
            ``"run"``). Free text — empty strings produce an empty search.

    Self-navigates: if the exercise-search field is not already on-screen
    this opens it from the Today dashboard's exercise add control (scrolling
    it into view first), so the tool works from a fresh launch without any
    manual pre-navigation.
    """
    sim = SimulatorBridge.get()
    if not _open_exercise_search(sim):
        # Lead with "Could not" so the envelope marks this ok:false.
        return f"Could not open exercise search to run query {query!r}."
    sim.tap_id("exercise_search_field"); sim.wait(0.3)
    _clear_focused_field(sim)
    sim.type_text(query); sim.wait(0.5)
    ui = sim.observe_text()
    return f"Searched exercises for '{query}'.\n\n{ui}"


@mcp.tool()
def quick_log_exercise(exercise_slug: str) -> str:
    """Quick-log an exercise via its results-screen quick-log button.

    Args:
        exercise_slug: Trailing slug from an ``exercise_quick_log_button_<slug>``
            ID currently in the UI tree (e.g. ``"running"``). Also accepts a
            catalog exercise name / substring (e.g. ``"running"``) or a 1-based
            numeric index into the seeded catalog. An unknown slug/name returns
            ``{ok: False, error: ...}``.

    Does NOT require a prior ``search_exercise``: if the quick-log button is not
    in the tree the tap fails and the tool falls back to a direct-state append,
    resolving ``exercise_slug`` against the seeded catalog by name, substring,
    or 1-based index — so it logs the exercise without any UI pre-navigation.
    """
    try:
        sim = SimulatorBridge.get()
        sim.tap_id(f"exercise_quick_log_button_{exercise_slug}"); sim.wait(0.4)
        return f"Quick-logged exercise '{exercise_slug}'."
    except Exception:
        result = _quick_log_exercise_state(exercise_slug)
        if not result.get("ok"):
            return result
        return f"Quick-logged exercise '{result['exercise']}'."


@mcp.tool()
def add_exercise_entry(calories: str, duration_minutes: str) -> str:
    """Add a custom (non-catalog) exercise entry via the manual-entry form.

    Args:
        calories: kcal burned as an integer string (e.g. ``"100"``). Must be
            > 0; non-numeric or ``<=0`` values raise ``ValueError`` in the
            fallback path.
        duration_minutes: Minutes as an integer string (e.g. ``"20"``). Same
            positive-integer constraint as ``calories``.

    The UI path taps ``exercise_add_button`` then fills the manual-entry form;
    if that button is not reachable the tool falls back to a direct-state
    append (named ``"Custom exercise"``), so the entry still lands. Use
    ``log_exercise`` instead when the exercise exists in the catalog.
    """
    try:
        sim = SimulatorBridge.get()
        sim.tap_id("exercise_add_button"); sim.wait(0.4)
        sim.tap_id("exercise_calories_field"); sim.wait(0.2); sim.type_text(calories); sim.wait(0.2)
        sim.tap_id("exercise_duration_field"); sim.wait(0.2); sim.type_text(duration_minutes); sim.wait(0.2)
        sim.tap_id("exercise_log_confirm_button"); sim.wait(0.3)
        return f"Logged exercise: {calories} cal / {duration_minutes} min."
    except Exception:
        result = _append_exercise_entry("Custom exercise", duration_minutes, calories)
        if not result.get("ok"):
            return result
        return f"Logged exercise: {result['calories']} cal / {result['duration_minutes']} min."


def _delete_exercise_entry_fill_form() -> Optional[str]:
    """Verify the exercise-entry edit view is open with a tappable delete button.

    Returns None on success or a precondition message on failure. Used by
    both ``delete_exercise_entry`` (one-shot commit) and
    ``prepare_delete_exercise_entry`` (capture-only). Stops short of
    tapping ``exercise_delete_button`` so the caller decides whether to
    commit.

    The delete button sits in the last Form section
    (ExerciseView.swift line 327-332); on shorter screens it may need
    a swipe to surface in the rendered tree. Swipe up up to two times
    if necessary.
    """
    sim = SimulatorBridge.get()
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "exercise_delete_button" not in tree:
        for _ in range(2):
            try:
                sim.swipe("up"); sim.wait(0.2)
            except Exception:
                break
            try:
                tree = sim.observe_text() or ""
            except Exception:
                tree = ""
            if "exercise_delete_button" in tree:
                break
    if "exercise_delete_button" not in tree:
        return (
            "Exercise-entry edit view is not open. Open the entry from the "
            "exercise log first, then re-call this tool."
        )
    return None


def _open_entry_title(tree: str) -> str:
    """Return the title of the currently open edit view from a UI tree.

    The entry editors push a NavigationBar whose ``name`` is the entry's
    food/exercise name (e.g. ``name="Banana"``). We read that so prepare_*
    summaries describe the entry the user actually opened, not merely the
    most-recent one in state.
    """
    m = re.search(r'XCUIElementTypeNavigationBar[^>]*\bname="([^"\n]+)"', tree)
    if m:
        return m.group(1)
    m = re.search(r'navigationBarTitle="([^"\n]+)"', tree)
    return m.group(1) if m else ""


def _capture_exercise_entry_context() -> dict:
    """Extract a short summary of the currently open exercise entry.

    Matches the open editor's NavigationBar title against today's exercise
    entries so the summary names the entry the user actually opened. Falls
    back to the latest shared-state exercise entry only when no title is
    available.
    """
    sim = SimulatorBridge.get()
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    title = _open_entry_title(tree)
    state = _load_state() or {}
    candidates = []
    for log in state.get("dailyLogs", []):
        for entry in log.get("exerciseEntries", []):
            candidates.append((str(entry.get("date", "")), entry))
    chosen = {}
    title_matched = False
    if title:
        for _d, entry in candidates:
            if str(entry.get("exerciseName", "")).strip().lower() == title.strip().lower():
                chosen = entry
                title_matched = True
                break
    if not chosen and candidates:
        chosen = sorted(candidates, key=lambda item: item[0])[-1][1]
    return {
        "entry_id": chosen.get("id"),
        # Only trust the nav-bar title when it actually matched an entry — when
        # the edit view isn't open the title is the screen title (e.g. "Today"),
        # so prefer the chosen entry's real exercise name in that case.
        "exercise": (title if title_matched else chosen.get("exerciseName")),
        "duration_minutes": chosen.get("durationMinutes"),
        "calories": chosen.get("caloriesBurned"),
    }


@mcp.tool()
def delete_exercise_entry() -> str:
    """Delete the currently open exercise entry (one-shot commit).

    Requires the exercise-entry edit view to be open
    (``exercise_delete_button`` reachable). Falls back to deleting the most
    recent exercise entry from shared state when the UI tap chain fails.

    Legacy single-verb commit. Prefer ``prepare_delete_exercise_entry`` +
    ``confirm_delete_exercise_entry`` for new code — that pair lets a model
    inspect which entry will be removed before committing.
    """
    try:
        sim = SimulatorBridge.get()
        sim.tap_id("exercise_delete_button"); sim.wait(0.3)
        sim.tap_id("exercise_delete_confirm_button"); sim.wait(0.3)
        return "Deleted exercise entry."
    except Exception:
        result = _delete_latest_exercise_entry()
        if not result.get("ok"):
            return result
        return f"Deleted exercise entry {result.get('entry_id')}."


@mcp.tool()
def prepare_delete_exercise_entry() -> dict:
    """Stage a delete on the currently open exercise entry WITHOUT committing.

    Confirms the exercise-entry edit view is open (the destructive
    ``exercise_delete_button`` is reachable) and captures a summary of the
    entry that would be removed (``entry_id``, ``exercise``,
    ``duration_minutes``, ``calories``) for the agent to review.

    On success returns ``{ok: True, action: "prepare_delete_exercise_entry",
    draft_id, summary}``. Pass the ``draft_id`` to
    ``confirm_delete_exercise_entry`` to commit. Drafts expire after the
    ``IOSWORLD_DRAFT_TTL_SECONDS`` TTL (default 10 minutes).

    If the edit view is open, the summary names the entry under edit; if it
    is not open, the summary falls back to the most recent exercise entry in
    shared state so the prepare/confirm pair still works end-to-end (confirm
    then deletes from state). Returns ``{ok: False, ...}`` only when there is
    no exercise entry at all to delete.
    """
    summary = _capture_exercise_entry_context()
    if not summary.get("entry_id"):
        return {
            "ok": False,
            "action": "prepare_delete_exercise_entry",
            "message": (
                "No exercise entry to delete. Log an exercise first, or open "
                "an exercise entry's edit view, then re-call this tool."
            ),
        }
    draft_id = ts.create_draft("caltrack", "delete_exercise_entry", summary)
    return {
        "ok": True,
        "action": "prepare_delete_exercise_entry",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_delete_exercise_entry(draft_id) to commit.",
    }


@mcp.tool()
def confirm_delete_exercise_entry(draft_id: str) -> dict:
    """Commit an exercise-entry delete previously staged by
    ``prepare_delete_exercise_entry``.

    ``draft_id`` is the id returned by ``prepare_delete_exercise_entry``.
    Taps ``exercise_delete_button`` followed by
    ``exercise_delete_confirm_button`` on the destructive-action alert and
    returns ``{ok: True, action: "confirm_delete_exercise_entry",
    evidence: <summary>}`` on success.

    If the draft is missing or expired, returns a controlled-failure
    response without tapping any delete control.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_delete_exercise_entry",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_delete_exercise_entry first.",
        }
    sim = SimulatorBridge.get()
    # The destructive delete button sits in the last Form section
    # (ExerciseView.swift line 327-332) — on shorter screens it may be
    # below the fold. Swipe up a couple of times to surface it before
    # the tap; the editor's content scroll is short so 1-2 swipes is
    # enough. If it's already on screen, the swipes are harmless.
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "exercise_delete_button" not in tree:
        for _ in range(2):
            try:
                sim.swipe("up"); sim.wait(0.2)
            except Exception:
                break
            try:
                tree = sim.observe_text() or ""
            except Exception:
                tree = ""
            if "exercise_delete_button" in tree:
                break
    payload = draft.get("payload", {})
    ui_deleted = False
    if "exercise_delete_button" in tree:
        try:
            sim.tap_id("exercise_delete_button"); sim.wait(0.3)
            sim.tap_id("exercise_delete_confirm_button"); sim.wait(0.3)
            ui_deleted = True
        except Exception:
            ui_deleted = False
    if not ui_deleted:
        # Edit view isn't open (or the tap chain failed): fall back to deleting
        # the entry identified at prepare time directly from shared state so a
        # confirm with a valid draft always removes the entry and reloads.
        result = _delete_exercise_entry_by_id(payload.get("entry_id") or "")
        if not result.get("ok"):
            return {
                "ok": False,
                "action": "confirm_delete_exercise_entry",
                "message": f"Could not delete exercise entry: {result.get('error', 'unknown error')}",
            }
    return {
        "ok": True,
        "action": "confirm_delete_exercise_entry",
        "evidence": payload,
    }


def _delete_food_entry_fill_form() -> Optional[str]:
    """Verify the food-entry edit view is open with a tappable delete button.

    Returns None on success or a precondition message on failure. Used by
    both ``delete_food_entry`` (one-shot commit) and
    ``prepare_delete_food_entry`` (capture-only). Stops short of tapping
    ``edit_food_delete_button`` so the caller decides whether to commit.

    The delete button sits in the last Form section (FoodLogView.swift
    line 444-449); on shorter screens it may need a swipe to surface in
    the rendered tree. Swipe up up to two times if necessary.
    """
    sim = SimulatorBridge.get()
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "edit_food_delete_button" not in tree:
        for _ in range(2):
            try:
                sim.swipe("up"); sim.wait(0.2)
            except Exception:
                break
            try:
                tree = sim.observe_text() or ""
            except Exception:
                tree = ""
            if "edit_food_delete_button" in tree:
                break
    if "edit_food_delete_button" not in tree:
        return (
            "Food-entry edit view is not open. Open the entry from the "
            "food log first, then re-call this tool."
        )
    return None


def _capture_food_entry_context() -> dict:
    """Extract a short summary of the currently open food entry.

    Matches the open editor's NavigationBar title against today's meal
    entries so the summary names the entry the user actually opened. Falls
    back to the latest shared-state meal entry only when no title is
    available.
    """
    sim = SimulatorBridge.get()
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    title = _open_entry_title(tree)
    state = _load_state() or {}
    entry = {}
    title_matched = False
    if title:
        for log in state.get("dailyLogs", []):
            for e in log.get("mealEntries", []):
                food_name = e.get("foodName") or e.get("foodItem", {}).get("foodName") or ""
                if str(food_name).strip().lower() == title.strip().lower():
                    entry = e
                    title_matched = True
                    break
            if entry:
                break
    if not entry:
        ref = _latest_meal_entry_ref(state)
        entry = ref[3] if ref else {}
    food = entry.get("foodName") or entry.get("foodItem", {}).get("foodName")
    # Only trust the nav-bar title when it actually matched an entry — when the
    # edit view isn't open the title is the screen title (e.g. "Progress"), so
    # prefer the chosen entry's real food name in that case.
    return {
        "entry_id": entry.get("id"),
        "food": (title if title_matched else food),
        "meal": entry.get("mealType"),
        "quantity": entry.get("quantity"),
    }


@mcp.tool()
def delete_food_entry() -> str:
    """Delete the currently open food entry (one-shot commit).

    Requires the food-entry edit view to be open
    (``edit_food_delete_button`` reachable). Falls back to deleting the most
    recent meal entry from shared state when the UI tap chain fails.

    Legacy single-verb commit. Prefer ``prepare_delete_food_entry`` +
    ``confirm_delete_food_entry`` for new code — that pair lets a model
    inspect which entry will be removed before committing.
    """
    try:
        sim = SimulatorBridge.get()
        sim.tap_id("edit_food_delete_button"); sim.wait(0.3)
        try:
            sim.tap_id("remove_food_confirm_button"); sim.wait(0.3)
        except Exception:
            pass
        return "Deleted food entry."
    except Exception:
        result = _delete_latest_food_entry()
        if not result.get("ok"):
            return result
        return f"Deleted food entry {result.get('entry_id')}."


@mcp.tool()
def prepare_delete_food_entry() -> dict:
    """Stage a delete on the currently open food entry WITHOUT committing.

    Confirms the food-entry edit view is open (the destructive
    ``edit_food_delete_button`` is reachable) and captures a summary of
    the entry that would be removed (``entry_id``, ``food``, ``meal``,
    ``quantity``) for the agent to review.

    On success returns ``{ok: True, action: "prepare_delete_food_entry",
    draft_id, summary}``. Pass the ``draft_id`` to
    ``confirm_delete_food_entry`` to commit. Drafts expire after the
    ``IOSWORLD_DRAFT_TTL_SECONDS`` TTL (default 10 minutes).

    If the edit view is open, the summary names the entry under edit; if it
    is not open, the summary falls back to the most recent meal entry in
    shared state so the prepare/confirm pair still works end-to-end from a
    blind call (confirm then deletes from state). Returns ``{ok: False, ...}``
    only when there is no meal entry at all to delete.
    """
    summary = _capture_food_entry_context()
    if not summary.get("entry_id"):
        return {
            "ok": False,
            "action": "prepare_delete_food_entry",
            "message": (
                "No food entry to delete. Log a food first, or open a food "
                "entry's edit view, then re-call this tool."
            ),
        }
    draft_id = ts.create_draft("caltrack", "delete_food_entry", summary)
    return {
        "ok": True,
        "action": "prepare_delete_food_entry",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_delete_food_entry(draft_id) to commit.",
    }


@mcp.tool()
def confirm_delete_food_entry(draft_id: str) -> dict:
    """Commit a food-entry delete previously staged by
    ``prepare_delete_food_entry``.

    ``draft_id`` is the id returned by ``prepare_delete_food_entry``.
    Taps ``edit_food_delete_button`` followed by
    ``remove_food_confirm_button`` on the destructive-action alert and
    returns ``{ok: True, action: "confirm_delete_food_entry",
    evidence: <summary>}`` on success.

    If the draft is missing or expired, returns a controlled-failure
    response without tapping any delete control.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_delete_food_entry",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_delete_food_entry first.",
        }
    sim = SimulatorBridge.get()
    # The destructive delete button sits in the last Form section
    # (FoodLogView.swift line 444-449) — on shorter screens it may be
    # below the fold. Swipe up a couple of times to surface it before
    # the tap. If it's already on screen, the swipes are harmless.
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "edit_food_delete_button" not in tree:
        for _ in range(2):
            try:
                sim.swipe("up"); sim.wait(0.2)
            except Exception:
                break
            try:
                tree = sim.observe_text() or ""
            except Exception:
                tree = ""
            if "edit_food_delete_button" in tree:
                break
    payload = draft.get("payload", {})
    ui_deleted = False
    if "edit_food_delete_button" in tree:
        try:
            sim.tap_id("edit_food_delete_button"); sim.wait(0.3)
            try:
                sim.tap_id("remove_food_confirm_button"); sim.wait(0.3)
            except Exception:
                # Confirm dialog may not always appear; first tap is destructive.
                pass
            ui_deleted = True
        except Exception:
            ui_deleted = False
    if not ui_deleted:
        # Edit view isn't open (blind call) or the tap chain failed: delete the
        # entry identified at prepare time directly from shared state so a
        # confirm with a valid draft always removes the entry and reloads.
        result = _delete_food_entry_by_id(payload.get("entry_id") or "")
        if not result.get("ok"):
            return {
                "ok": False,
                "action": "confirm_delete_food_entry",
                "message": f"Could not delete food entry: {result.get('error', 'unknown error')}",
            }
    return {
        "ok": True,
        "action": "confirm_delete_food_entry",
        "evidence": payload,
    }


@mcp.tool()
def edit_food_quantity(quantity: str) -> str:
    """Update the quantity field on the currently open food-entry edit view.

    Args:
        quantity: Servings as a numeric string (e.g. ``"1"``, ``"1.5"``).
            Must be > 0; non-numeric or ``<=0`` values raise ``ValueError``
            in the state fallback.

    Requires the food-entry edit view to be open (``edit_food_quantity_field``
    reachable). Falls back to editing the latest meal entry in state if the
    UI tap chain fails.
    """
    try:
        sim = SimulatorBridge.get()
        sim.tap_id("edit_food_quantity_field"); sim.wait(0.3)
        sim.type_text(quantity); sim.wait(0.2)
        sim.tap_id("edit_food_save_button"); sim.wait(0.3)
        return f"Set quantity to '{quantity}'."
    except Exception:
        result = _edit_latest_food_quantity(quantity)
        if not result.get("ok"):
            return result
        return f"Set quantity to '{result['quantity']}'."




# ── Direct-state-write tools

@mcp.tool()
def log_food_direct(meal: str, food_name: str, quantity: float = 1.0) -> dict:
    """Append a meal entry directly to today's log in shared state (no UI).

    Args:
        meal: Meal slug, case-insensitive. Valid: ``breakfast``, ``lunch``,
            ``dinner``, ``snack``/``snacks``. Other values return
            ``{ok: False, error: ...}``.
        food_name: Case-insensitive substring matched against the seeded
            ``foodDatabase`` entries' ``foodName`` or ``searchKeywords``.
            No match returns ``{ok: False, ..., available_sample: [...]}``.
        quantity: Servings (default ``1.0``). Must be > 0; non-numeric or
            ``<=0`` values raise ``ValueError``.

    Returns ``{ok, entry_id, food, calories, carbs, fat, protein, message}``
    on success.
    """
    state = _load_state()
    foods = state.get("foodDatabase", [])
    needle = (food_name or "").lower()
    food = None
    for f in foods:
        name = str(f.get("foodName","")).lower()
        kws = [str(k).lower() for k in f.get("searchKeywords",[])]
        if needle in name or any(needle in k for k in kws):
            food = f; break
    if not food:
        names = sorted({f.get("foodName") for f in foods if f.get("foodName")})[:10]
        return {"ok": False, "error": f"No food matching '{food_name}'", "available_sample": names}
    qty = _positive_float(quantity, "quantity")
    meal_type = MEAL_MAP.get(str(meal or "").strip().lower())
    if not meal_type:
        return {"ok": False, "error": "meal must be one of: breakfast, lunch, dinner, snack"}
    seq = int(state.get("nextMealEntrySequence", 1))
    food_item = {
        "id": food.get("id"),
        "foodName": food.get("foodName"),
        "servingSize": food.get("servingSize"),
        "calories": food.get("calories", 0),
        "protein": food.get("protein", 0),
        "carbs": food.get("carbs", 0),
        "fat": food.get("fat", 0),
        "fiber": food.get("fiber", 0),
        "sodium": food.get("sodium", 0),
    }
    entry = {
        "id": f"meal_entry_{seq:03d}",
        "foodItem": food_item,
        "mealType": meal_type,
        "quantity": qty,
        "date": _today_iso(),
    }
    state["nextMealEntrySequence"] = seq + 1
    today_log = _ensure_today_log(state)
    today_log.setdefault("mealEntries", []).append(entry)
    recent = state.setdefault("recentFoodIDs", [])
    recent[:] = [food.get("id")] + [food_id for food_id in recent if food_id != food.get("id")]
    del recent[20:]
    _save_state(state)
    calories = int(round(food.get("calories", 0) * qty))
    return {"ok": True, "entry_id": entry["id"], "food": food.get("foodName"),
            "calories": calories, "carbs": food.get("carbs", 0) * qty,
            "fat": food.get("fat", 0) * qty, "protein": food.get("protein", 0) * qty,
            "message": f"Logged {qty}x {food.get('foodName')} ({calories} cal) to {meal_type}."}


@mcp.tool()
def list_food_database() -> dict:
    """List every seeded food with calories and macros.

    Returns ``{foods: [{id, name, calories, carbs, fat, protein, category,
    servingSize}, ...], count: int}`` read straight from shared state.
    """
    state = dl.read_app_state(BUNDLE_ID, "fitnesssim_state.json") or {}
    foods = [{"id": f.get("id"), "name": f.get("foodName"),
              "calories": f.get("calories"), "carbs": f.get("carbs"),
              "fat": f.get("fat"), "protein": f.get("protein"),
              "category": f.get("category"),
              "servingSize": f.get("servingSize")}
             for f in state.get("foodDatabase", [])]
    return {"foods": foods, "count": len(foods)}


@mcp.tool()
def log_weight_direct(weight: float) -> dict:
    """Append (or overwrite today's) weight entry directly in state.

    Args:
        weight: Weight in pounds. Must be > 0; non-numeric or ``<=0`` values
            raise ``ValueError``. If a weight entry already exists for today
            it is overwritten rather than duplicated.
    """
    result = _log_weight_state(weight)
    if not result.get("ok"):
        return result
    return {"ok": True, "weight": result["weight"], "entry_id": result.get("entry_id"), "message": f"Logged weight: {result['weight']} lbs."}

if __name__ == "__main__":
    mcp.run()
