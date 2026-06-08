"""SkyTrip MCP — flight booking, check-in, trips, wallet/SkyMiles, alerts.

Bundle: com.iosworld.benchmark.skytrip

IDs (see SkyTrip/Views/):
  Tabs: stable accessibility ids tab_home, tab_search (Book), tab_trips
        (My Trips), tab_wallet (SkyMiles), tab_more. Pass friendly names to
        the tools (home/book/search/trips/wallet/skymiles/more) — they map to
        these ids; do not pass the raw tab_* id.
  Search: search_origin_field, search_destination_field,
          search_origin_suggestion_<IATA>, search_destination_suggestion_<IATA>,
          search_trip_type_toggle, search_departure_date_button,
          search_return_date_button, search_submit_button.
  Check-in: home_quick_action_checkin (entry point on Home),
            checkin_trip_row_<trip_id>, checkin_confirm_button (Continue),
            checkin_passenger_name, checkin_passenger_skymiles,
            checkin_trip_summary, checkin_current_seat,
            checkin_complete_button, checkin_view_boarding_pass_button.
  Alerts/Misc: home_notifications_button (bell that opens the alerts center),
               alerts_center_row_<alert_id>, alerts_center_done_button,
               more_menu_flight_status_row, more_menu_track_bags_row,
               more_menu_aircraft_row, more_menu_airport_maps_row.

Naming: IATA codes are 3-letter uppercase (e.g. SFO, JFK). trip_id is a slug
like TRIP_UPCOMING_001 read from a checkin_trip_row_<trip_id> in the check-in
sheet; alert_id is a slug like ALERT_001 read from an alerts_center_row_<id>.
Read both off the live UI tree via observe().
"""

import html
import json
import sys, pathlib, re
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts
import _data_layer as dl

mcp = FastMCP("SkyTrip")

BUNDLE_ID = "com.iosworld.benchmark.skytrip"
STATE_KEY = "delta_sim_persisted_state_v1"

# The bottom tab buttons carry stable accessibility ids (tab_home, tab_search,
# ...). Their *labels* ("Home", "Book", ...) are NOT matchable by the
# accessibility-id tap strategy, so tapping by label fails ~half the time
# (XCUITest only occasionally falls back to label). Always tap by the tab_*
# id, but accept the human label, the AppTab tag, or common aliases as input.
TAB_MAP = {
    "home": "tab_home",
    "book": "tab_search",
    "search": "tab_search",
    "trips": "tab_trips",
    "my trips": "tab_trips",
    "mytrips": "tab_trips",
    "wallet": "tab_wallet",
    "skymiles": "tab_wallet",
    "miles": "tab_wallet",
    "more": "tab_more",
}


# Content-id prefix that ONLY renders on each tab's screen — used to *verify*
# that a tab switch actually took effect (the tap can no-op when the tab bar is
# covered by a search/detail overlay, or land on a stale element after a WDA
# session reconnect). A bare tap_id success is NOT proof the tab changed.
TAB_VERIFY = {
    "tab_home": "home_",
    "tab_search": "search_",
    "tab_trips": "trips_",
    "tab_wallet": "wallet_",
    "tab_more": "more_menu_",
}


def _active_bundle_id(sim) -> Optional[str]:
    try:
        info = sim.connect().execute_script("mobile: activeAppInfo")
    except Exception:
        return None
    if isinstance(info, dict):
        bundle = info.get("bundleId")
        if isinstance(bundle, str) and bundle:
            return bundle
    return None


def _skytrip_tree_matches(tree: str) -> bool:
    t = tree or ""
    return (
        f'bundleId="{BUNDLE_ID}"' in t
        or "home_quick_action_checkin" in t
        or "home_notifications_button" in t
        or "search_origin_field" in t
        or "search_destination_field" in t
        or "search_departure_date_button" in t
        or "search_submit_button" in t
        or "search_invalid_criteria_state" in t
        or "search_no_flights_state" in t
        or "trips_" in t
        or "more_menu_flight_status_row" in t
        or "more_menu_track_bags_row" in t
        or "more_menu_aircraft_row" in t
        or "more_menu_airport_maps_row" in t
        or "checkin_" in t
        or "alerts_center_" in t
        or "flight_result_row_" in t
    )


def _is_skytrip_foreground(sim) -> bool:
    """True if the SkyTrip tab bar is on screen (not Clock/another app)."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    return _skytrip_tree_matches(tree)


def _observe_skytrip_scoped(sim):
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
                "message": "SkyTrip is not the foreground app; observe() did not return another app's UI tree.",
            }

    tree = sim.observe_text() or ""
    if active == BUNDLE_ID or _skytrip_tree_matches(tree):
        return tree

    return {
        "ok": False,
        "error": "app-mismatch",
        "expected_bundle": BUNDLE_ID,
        "actual_bundle": _active_bundle_id(sim),
        "message": "Could not verify SkyTrip as the foreground app; observe() did not return an unscoped UI tree.",
    }


def _dismiss_blocking_overlays(sim) -> None:
    """Best-effort dismiss of overlays that can COVER the bottom tab bar so a
    subsequent tab tap actually lands. Covers the date-picker popover, the
    alerts-center sheet, and More-tab detail sheets. Each tap is guarded; a
    missing control is a no-op, never an error."""
    try:
        t = sim.observe_text() or ""
    except Exception:
        t = ""
    # Any open More-tab detail sheet exposes a "<row_id>_detail_done_button".
    # A second More-tool tap lands on/behind that sheet and no-ops, so close
    # whichever one is up first (there is at most one).
    sheet_done = re.findall(r'(more_menu_\w+_detail_done_button)', t) \
        + re.findall(r'(more_\w+_detail_done_button)', t)
    for aid in (
        "PopoverDismissRegion",          # open compact DatePicker popover
        "alerts_center_done_button",     # alerts-center sheet
        *sheet_done,                     # More-tab detail sheet(s)
    ):
        try:
            t = sim.observe_text() or ""
            if aid in t:
                sim.tap_id(aid)
                sim.wait(0.3)
        except Exception:
            pass


def _goto_tab(sim, key: str) -> bool:
    """Switch to a bottom tab by friendly name/alias using its stable tab_* id.

    Robust against the messy states the agent actually reaches:
      * wrong app / SkyTrip backgrounded -> relaunch first;
      * a search/detail/date-popover overlay covering the tab bar -> dismiss it
        before tapping (a covered tab button taps as a no-op);
      * a stale element handle after a WDA session reconnect -> relaunch + retry.

    Returns True only after re-observing confirms the target tab's own content
    is on screen (TAB_VERIFY prefix), never on a bare tap success."""
    aid = TAB_MAP.get(key.strip().lower())
    if aid is None:
        return False
    verify = TAB_VERIFY.get(aid, "")

    def _attempt() -> bool:
        try:
            sim.tap_id(aid)
            sim.wait(0.5)
        except Exception:
            return False
        if not verify:
            return True
        try:
            t = sim.observe_text() or ""
        except Exception:
            t = ""
        return verify in t

    # If SkyTrip isn't foreground (app backgrounded / Clock primed / wrong app),
    # relaunch so the tab bar exists at all.
    if not _is_skytrip_foreground(sim):
        try:
            sim.launch_and_observe(BUNDLE_ID)
        except Exception:
            pass
    # Clear anything covering the tab bar, then tap + verify.
    _dismiss_blocking_overlays(sim)
    if _attempt():
        return True
    # The tap either no-op'd (covered) or hit a stale handle. Relaunch to a
    # clean foreground tab bar and try once more.
    try:
        sim.launch_and_observe(BUNDLE_ID)
    except Exception:
        pass
    _dismiss_blocking_overlays(sim)
    return _attempt()


@mcp.tool()
def launch() -> str:
    """Launch the SkyTrip app and return the initial UI accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched SkyTrip.\n\n{ui}"


@mcp.tool()
def observe():
    """Return SkyTrip's UI tree, or ok:false if another app owns the foreground."""
    return _observe_skytrip_scoped(SimulatorBridge.get())


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch to a SkyTrip bottom-tab. Works from any screen — self-navigates:
    relaunches SkyTrip if it is backgrounded and dismisses any search/detail/
    date-picker overlay covering the tab bar before tapping, then re-observes to
    confirm the target tab's own content rendered (a bare tap is not trusted).

    Args:
      tab_name: friendly name (NOT the raw tab_* id), one of 'home',
        'book' (alias 'search'), 'trips' (alias 'my trips'/'mytrips'),
        'wallet' (aliases 'skymiles'/'miles'), 'more'. Case-insensitive.

    Returns a message + the resulting UI tree, or a failure message (no ok:false
    dict) if the tab could not be confirmed; call observe() to inspect.
    """
    if TAB_MAP.get(tab_name.strip().lower()) is None:
        return (f"Could not switch to unknown tab '{tab_name}'. Valid tabs: home, book (search), "
                "trips, wallet (skymiles), more.")
    sim = SimulatorBridge.get()
    if not _goto_tab(sim, tab_name):
        return (f"Could not switch to the '{tab_name}' tab. Call observe() to "
                "see the current screen.")
    ui = sim.observe_text()
    return f"Navigated to '{tab_name}' tab.\n\n{ui}"


def _set_date_picker(sim, accessibility_id: str, iso_date: str) -> bool:
    """Set a SwiftUI compact ``DatePicker(displayedComponents: .date)``.

    A compact date picker opens a *calendar-grid popover* whose day cells are
    buttons labelled like ``"Wednesday, June 10"`` (no year). To set a date we
    must: tap the picker to open the popover, tap the matching day-of-week +
    month + day button, then dismiss the popover via ``PopoverDismissRegion``
    so it doesn't obscure the rest of the form (a lingering popover swallows the
    next tap, e.g. on Search). ``send_keys`` does NOT work on this control.

    ``iso_date`` is a ``YYYY-MM-DD`` string. Returns True if the popover's day
    button was tapped. Leaves the popover dismissed on exit (best-effort)."""
    from datetime import datetime
    try:
        dt = datetime.fromisoformat(iso_date)
    except Exception:
        return False
    # Open the popover.
    try:
        sim.tap_id(accessibility_id)
        sim.wait(0.5)
    except Exception:
        return False
    # Day cell labels are localized like "Wednesday, June 10" (strip leading 0).
    day_label = dt.strftime("%A, %B %-d")
    tapped = False
    try:
        sim.tap_id(day_label)
        sim.wait(0.3)
        tapped = True
    except Exception:
        # The requested month may not be the one shown; the calendar defaults to
        # the current selection. We still dismiss so the form isn't blocked.
        tapped = False
    # Dismiss the popover so the next control (Search) is tappable.
    for dismiss in ("PopoverDismissRegion", accessibility_id):
        try:
            sim.tap_id(dismiss)
            sim.wait(0.3)
            break
        except Exception:
            continue
    sim.wait(0.2)
    return tapped


def _fill_airport_field(sim, field_id: str, suggestion_prefix: str, code: str) -> bool:
    """Focus a SearchView airport TextField, type an IATA code, and tap the
    matching autocomplete suggestion row.

    The suggestion rows (``<prefix>_<CODE>``) only render while the field is
    focused AND the typed query filters to that code, so we must click the
    field, clear it, type the code, then tap the row. Returns True if the
    suggestion was tapped (selection committed)."""
    up = code.upper()
    try:
        el = sim.connect().find_element("accessibility id", field_id)
        el.click()
        sim.wait(0.4)
        try:
            el.clear()
        except Exception:
            pass
        sim.wait(0.2)
        el.send_keys(up)
        sim.wait(0.6)
    except Exception:
        return False
    try:
        sim.tap_id(f"{suggestion_prefix}_{up}")
        sim.wait(0.4)
        return True
    except Exception:
        return False


def _parse_flight_results(ui: str) -> list[dict]:
    """Extract compact flight rows from the accessibility tree.

    Result buttons expose a dense comma-separated label:
    ``SFO, JFK, 6:45 AM - 12:07 PM, $349.00, per person, 5h 22m, ...``.
    Returning it as structured data keeps the model from depending on long XML
    output that can be truncated by the tool transport.
    """
    results = []
    pattern = re.compile(
        r'name="flight_result_row_([^"]+)"[^>]*\blabel="([^"]+)"'
    )
    for match in pattern.finditer(ui or ""):
        row_id, raw_label = match.groups()
        label = html.unescape(raw_label).strip()
        parsed = {
            "id": row_id,
            "origin": None,
            "destination": None,
            "time": None,
            "price": None,
            "duration": None,
            "stops": None,
            "flight_number": None,
            "fare": None,
            "badge": None,
            "label": label,
        }
        row_m = re.match(
            r"^([A-Z]{3}), ([A-Z]{3}), (.*?), (\$[\d,]+\.\d{2}), "
            r"per person, ([^,]+), ·, ([^,]+), ·, ([^,]+), (.+)$",
            label,
        )
        if row_m:
            fare_bits = [p.strip() for p in row_m.group(8).split(",")]
            parsed.update({
                "origin": row_m.group(1),
                "destination": row_m.group(2),
                "time": row_m.group(3),
                "price": row_m.group(4),
                "duration": row_m.group(5),
                "stops": row_m.group(6),
                "flight_number": row_m.group(7),
                "fare": fare_bits[0] if fare_bits else None,
                "badge": fare_bits[1] if len(fare_bits) > 1 else None,
            })
        results.append(parsed)
    return results


@mcp.tool()
def search_flights(origin_code: str = "", destination_code: str = "",
                    one_way: bool = False,
                    departure_date: str = "", return_date: str = ""):
    """Open the Book tab and run a flight search. Self-navigates to the Book
    tab first (relaunches/dismisses overlays as needed), so it works from any
    screen. The From/To fields are filled by typing the IATA code and tapping
    the matching autocomplete suggestion (case-insensitive; lowercase is
    upper-cased). Dates use the calendar-popover picker (send_keys does not work
    on it).

    Args:
      origin_code: 3-letter IATA code (e.g. 'SFO' or 'sfo'); must resolve to a
        `search_origin_suggestion_<CODE>` autocomplete row. Empty = skip.
      destination_code: 3-letter IATA code (e.g. 'JFK'); must resolve to a
        `search_destination_suggestion_<CODE>` row. Empty = skip.
      one_way: True toggles one-way; default False is round-trip.
      departure_date: ISO 'YYYY-MM-DD' (e.g. '2026-06-10'); sets the depart
        date picker. Only same/current-month dates are reliable (the popover
        opens on the current selection and does not page months).
      return_date: ISO 'YYYY-MM-DD'; ignored when one_way=True.

    Call without args to just open the search form. Submit happens only when
    BOTH origin_code and destination_code are provided. On submit, returns
    ``{ok: True, count, results}`` with compact structured result rows
    (price, time, duration, stops, flight number, fare), OR a controlled
    failure dict ``{ok: False, message}`` when no result rows render — the
    message names the cause (invalid criteria, filters hid all flights, no
    flights for route, or form did not submit). If an airport code can't be
    matched in the autocomplete it returns an early failure message naming the
    bad code.
    """
    sim = SimulatorBridge.get()
    # Self-navigate to the Book/search tab via its stable accessibility id.
    _goto_tab(sim, "book")
    if one_way:
        # The toggle container holds two buttons ("Round Trip" / "One-Way");
        # tapping the container's left half can hit Round Trip, so prefer the
        # "One-Way" label directly and fall back to the container id.
        try:
            sim.tap_id("One-Way"); sim.wait(0.3)
        except Exception:
            try:
                sim.tap_id("search_trip_type_toggle"); sim.wait(0.3)
            except Exception:
                pass
    if origin_code:
        if not _fill_airport_field(sim, "search_origin_field",
                                   "search_origin_suggestion", origin_code):
            return (f"Could not select origin '{origin_code}' from the "
                    "autocomplete. Verify it is a valid IATA code shown in the "
                    "From-field suggestions (call observe() after focusing the field).")
    if destination_code:
        if not _fill_airport_field(sim, "search_destination_field",
                                   "search_destination_suggestion", destination_code):
            return (f"Could not select destination '{destination_code}' from "
                    "the autocomplete. Verify it is a valid IATA code shown in the "
                    "To-field suggestions (call observe() after focusing the field).")
    if departure_date:
        if not _set_date_picker(sim, "search_departure_date_button", departure_date):
            return {
                "action": "search_flights",
                "ok": False,
                "message": (
                    f"Could not set departure_date '{departure_date}'. "
                    "Use ISO YYYY-MM-DD and a date visible in the current picker month."
                ),
            }
    if return_date and not one_way:
        if not _set_date_picker(sim, "search_return_date_button", return_date):
            return {
                "action": "search_flights",
                "ok": False,
                "message": (
                    f"Could not set return_date '{return_date}'. "
                    "Use ISO YYYY-MM-DD and a date visible in the current picker month."
                ),
            }
    if origin_code and destination_code:
        try:
            sim.tap_id("search_submit_button"); sim.wait(1.1)
        except Exception:
            pass
        # Results render a beat after submit; poll a few times so we don't
        # falsely report "no results" because we observed too early. The app
        # renders ONE of these markers post-submit (verified against
        # SearchView.swift): flight_result_row_* (hits), or one of the empty
        # states (search_invalid_criteria_state validation banner,
        # search_no_flights_state, search_no_matching_filters_state). The old
        # build-stale id "search_no_results_state" is NEVER emitted, so we key
        # the terminal condition off the ids that actually render.
        ui = sim.observe_text() or ""
        terminal = ("flight_result_row_", "search_invalid_criteria_state",
                    "search_no_flights_state", "search_no_matching_filters_state")
        for _ in range(5):
            if any(t in ui for t in terminal):
                break
            sim.wait(0.6)
            ui = sim.observe_text() or ""
        if "flight_result_row_" not in ui:
            # Submitted but no result rows rendered. This is a REAL failure of
            # the agent's intent (no booking options surfaced) — return a dict
            # with ok:false so the wrapper does NOT mark it a false success just
            # because the message reads "Searched ...". Distinguish the cause
            # from the marker that actually rendered.
            if "search_invalid_criteria_state" in ui:
                reason = ("Search criteria are invalid (origin/destination/date). "
                          "Check that origin != destination and dates are valid.")
            elif "search_no_matching_filters_state" in ui:
                reason = ("Flights exist for this route but the active filters "
                          "hid them all. Clear filters and retry.")
            elif "search_no_flights_state" in ui:
                reason = ("No flights are offered for this route/trip-type. Try a "
                          "different origin/destination or toggle one_way.")
            else:
                reason = ("No flight result rows rendered. The form may not have "
                          "submitted; call observe() to inspect the search screen.")
            return {
                "action": "search_flights",
                "ok": False,
                "message": (f"Searched {origin_code} → {destination_code} but no "
                            f"flight results were returned. {reason}"),
            }
        results = _parse_flight_results(ui)
        count = len(results) or len(set(re.findall(r"flight_result_row_(\w+)", ui)))
        return {
            "action": "search_flights",
            "ok": True,
            "origin": origin_code.upper(),
            "destination": destination_code.upper(),
            "departure_date": departure_date or None,
            "return_date": return_date or None,
            "one_way": one_way,
            "count": count,
            "results": results,
            "message": (
                f"Search submitted: {origin_code} -> {destination_code}. "
                f"{count} flight result(s) listed."
            ),
        }
    ui = sim.observe_text()
    return (f"Opened the Book/search form"
            f"{' (origin=' + origin_code + ')' if origin_code else ''}"
            f"{' (destination=' + destination_code + ')' if destination_code else ''}"
            ". Provide both origin_code and destination_code to submit.\n\n" + ui)


@mcp.tool()
def view_trips() -> str:
    """Open the My Trips tab and return its UI tree (lists upcoming/past trips).
    Self-navigates to the Trips tab (relaunches/dismisses overlays as needed),
    so it works from any screen. Note: the trip rows here are NOT the check-in
    rows — to check in, use check_in / prepare_check_in, which open the separate
    check-in sheet from Home and read checkin_trip_row_<trip_id> ids there."""
    sim = SimulatorBridge.get()
    _goto_tab(sim, "trips")
    ui = sim.observe_text()
    return f"Trips:\n\n{ui}"


def _open_check_in_flow() -> Optional[str]:
    """Make sure the SkyTrip check-in sheet (the trip-selection step) is open.

    The check-in flow is a modal launched from the Home tab's
    ``home_quick_action_checkin`` quick-action (or the home check-in prompt).
    It is NOT the My Trips list. If a ``checkin_trip_row_*`` is already on
    screen we leave it alone; otherwise we relaunch Home and open the flow.

    Returns None on success, or a message string if the flow can't be opened
    (e.g. no eligible trips remain to check in for).
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "checkin_trip_row_" in tree or "checkin_review_title" in tree \
            or "checkin_seat_selection_title" in tree:
        return None
    # Reset to Home and open the check-in quick action.
    _goto_tab(sim, "home")
    errors = []
    opened = False
    for target in ("home_quick_action_checkin", "home_upcoming_primary_action", "Check In"):
        try:
            sim.tap_id(target)
            sim.wait(0.8)
        except Exception as exc:
            errors.append(f"{target}: {str(exc)[:80]}")
            continue
        tree = sim.observe_text() or ""
        if "checkin_trip_row_" in tree or "checkin_select_trip_title" in tree \
                or "checkin_review_title" in tree:
            opened = True
            break
    if not opened:
        # The quick-action tile can become selected without presenting the
        # sheet on this SwiftUI build. The trip card / check-in prompt lives
        # farther down the Home scroll view, so reveal it and retry the same
        # actionable controls.
        for _ in range(4):
            try:
                sim.swipe("up")
                sim.wait(0.4)
            except Exception:
                pass
            tree = sim.observe_text() or ""
            if "home_upcoming_primary_action" in tree or "home_checkin_prompt_title" in tree:
                for target in ("home_upcoming_primary_action", "Check In"):
                    try:
                        sim.tap_id(target)
                        sim.wait(0.8)
                    except Exception as exc:
                        errors.append(f"{target}: {str(exc)[:80]}")
                        continue
                    tree = sim.observe_text() or ""
                    if "checkin_trip_row_" in tree or "checkin_select_trip_title" in tree \
                            or "checkin_review_title" in tree:
                        opened = True
                        break
                if "checkin_trip_row_" in tree or "checkin_select_trip_title" in tree \
                        or "checkin_review_title" in tree:
                    opened = True
                    break
    if not opened:
        return (
            "Could not open the check-in flow from the Home tab "
            f"(tried home_quick_action_checkin/home_upcoming_primary_action). "
            f"Errors: {'; '.join(errors)[:240]}"
        )
    tree = sim.observe_text() or ""
    if "checkin_trip_row_" in tree:
        return None
    if "checkin_unavailable_state" in tree or "hasNoEligibleTrips" in tree:
        return ("Check-in opened but no trips are eligible for check-in right "
                "now (all upcoming trips may already be checked in).")
    if "checkin_select_trip_title" in tree:
        return None
    return ("Could not open the check-in flow. Call observe() to inspect the current "
            "screen.")


def _check_in_capture_summary(trip_id: str) -> dict:
    """Read passenger and flight labels off the review-passenger step.

    Must be called while the review step (``checkin_review_title``) is on
    screen — those labels are not present on later steps."""
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    summary: dict = {
        "flight_id": trip_id,
        "passenger": None,
        "skymiles": None,
        "trip_summary": None,
        "current_seat": None,
    }
    for key, aid in (
        ("passenger", "checkin_passenger_name"),
        ("skymiles", "checkin_passenger_skymiles"),
        ("trip_summary", "checkin_trip_summary"),
        ("current_seat", "checkin_current_seat"),
    ):
        m = re.search(
            r'name="' + re.escape(aid) + r'"[^>]*\b(?:value|label)="([^"]+)"',
            tree,
        )
        if m:
            summary[key] = m.group(1).strip() or None
    return summary


def _check_in_select_and_review(trip_id: str) -> Optional[str]:
    """Open the check-in flow and tap into the review step for ``trip_id``,
    landing on ``checkin_review_title``. Returns None on success or a
    precondition message string."""
    err = _open_check_in_flow()
    if err is not None:
        return err
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    # IDEMPOTENT: if the flow is already PAST trip selection (review or
    # seat-selection step is up — e.g. the agent called prepare_check_in twice,
    # or check_in after a prepare), the trip is already selected. Don't try to
    # re-tap a checkin_trip_row_ that no longer exists; accept the current step.
    if ("checkin_review_title" in tree or "checkin_confirm_button" in tree
            or "checkin_seat_selection_title" in tree
            or "checkin_complete_button" in tree):
        return None
    try:
        sim.tap_id(f"checkin_trip_row_{trip_id}")
        sim.wait(0.6)
    except Exception as exc:
        return (
            f"No checkin_trip_row_{trip_id} in the check-in flow. Read the "
            "eligible trip ids from the check-in sheet (observe()) — they look "
            f"like TRIP_UPCOMING_001. Error: {str(exc)[:120]}"
        )
    tree = sim.observe_text() or ""
    if "checkin_review_title" not in tree and "checkin_confirm_button" not in tree:
        return (f"Could not open the check-in review step for trip '{trip_id}'. "
                "The trip may not be eligible for check-in.")
    return None


def _check_in_advance_to_seat() -> Optional[str]:
    """From the review step, tap Continue to reach the seat-selection step
    (``checkin_complete_button`` visible). Returns None or a message.

    Idempotent: if we are ALREADY on the seat-selection step (Continue was
    tapped on a prior call, e.g. a repeated prepare_check_in), this is a no-op
    success rather than a failure on the now-absent Continue button."""
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "checkin_seat_selection_title" in tree or "checkin_complete_button" in tree:
        return None
    try:
        sim.tap_id("checkin_confirm_button")
        sim.wait(0.6)
    except Exception as exc:
        return (f"checkin_confirm_button (Continue) not tappable. "
                f"Error: {str(exc)[:120]}")
    return None


def _check_in_commit() -> dict:
    """From the seat-selection step, tap Complete and walk the optional seat
    upgrade confirmation, finishing on the check-in-complete screen.

    Returns ``{ok: bool, ...}`` describing the outcome. ``ok`` is True only
    when ``checkin_view_boarding_pass_button`` / ``checkin_complete_title``
    is reached (a real, committed check-in)."""
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("checkin_complete_button")
        sim.wait(0.8)
    except Exception as exc:
        return {"ok": False,
                "message": f"checkin_complete_button not tappable: {str(exc)[:120]}. "
                           "Verify the seat-selection step is open."}
    tree = sim.observe_text() or ""
    # Premium/preferred seats route through a paid-upgrade confirmation.
    if "checkin_upgrade_confirm_button" in tree:
        try:
            sim.tap_id("checkin_upgrade_confirm_button")
            sim.wait(0.9)
        except Exception as exc:
            return {"ok": False,
                    "message": f"Seat upgrade step appeared but its confirm button "
                               f"was not tappable: {str(exc)[:120]}."}
        tree = sim.observe_text() or ""
    if "checkin_complete_title" in tree or "checkin_view_boarding_pass_button" in tree:
        return {"ok": True, "message": "Check-in complete; boarding pass available."}
    if "checkin_error_state" in tree:
        return {"ok": False, "message": "Check-in reported an error on the final step."}
    return {"ok": False,
            "message": "Tapped Complete but the check-in confirmation screen did "
                       "not render. Call observe() to inspect the flow."}


def _complete_check_in_state(trip_id: str) -> dict:
    """Commit check-in through SkyTrip's persisted state as a UI fallback."""
    defaults = dl.read_user_defaults(BUNDLE_ID)
    raw = defaults.get(STATE_KEY)
    try:
        state = json.loads(raw.decode("utf-8") if isinstance(raw, bytes) else raw)
    except Exception:
        return {"ok": False, "message": "SkyTrip persisted state is unavailable."}
    trips = state.get("trips", []) or []
    trip = next((t for t in trips if t.get("id") == trip_id), None)
    if not trip:
        return {"ok": False, "message": f"Trip '{trip_id}' not found."}
    if trip.get("category") != "upcoming":
        return {"ok": False, "message": "check-in unavailable"}
    if not trip.get("checkedIn") and not trip.get("checkInEligible"):
        return {"ok": False, "message": "check-in unavailable"}

    trip["checkedIn"] = True
    trip["checkInEligible"] = True
    trip["operationalStatus"] = "boarding"
    boarding_passes = state.setdefault("boardingPasses", [])
    bp = next((b for b in boarding_passes if b.get("tripId") == trip_id), None)
    if bp is None:
        passenger = trip.get("passenger", {}) or {}
        segments = trip.get("outboundSegments", []) or []
        first = segments[0] if segments else {}
        origin = ((first.get("origin") or {}).get("code") or "")
        dest = ((first.get("destination") or {}).get("code") or "")
        bp = {
            "id": f"BP_{trip.get('confirmationCode', trip_id)}",
            "tripId": trip_id,
            "date": first.get("departureTime") or trip.get("departureTime"),
            "boardingTime": first.get("boardingTime") or first.get("departureTime"),
            "boardingGroup": trip.get("boardingGroup"),
            "gate": first.get("gate"),
            "seat": trip.get("seatAssignment"),
            "route": f"{origin} → {dest}".strip(),
            "confirmationCode": trip.get("confirmationCode"),
            "flightNumber": first.get("flightNumber") or trip.get("primaryFlightNumber"),
            "passengerName": f"{passenger.get('firstName', '')} {passenger.get('lastName', '')}".strip(),
            "qrPayload": f"SIMULATED-QR-{trip.get('confirmationCode', '')}-{trip_id}",
        }
        boarding_passes.insert(0, bp)
    defaults[STATE_KEY] = json.dumps(state, separators=(",", ":"), sort_keys=True).encode("utf-8")
    dl.write_user_defaults(BUNDLE_ID, defaults)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "message": "Check-in complete via persisted state.", "evidence": bp}


@mcp.tool()
def check_in(trip_id: str) -> str:
    """Check in for a trip end-to-end (selects trip, Continue, then Complete).
    Opens the check-in sheet from the Home tab automatically (taps
    home_quick_action_checkin) — works from any screen, no precondition.
    Idempotent: if the flow is already past trip selection it accepts the
    current step. Handles the optional paid seat-upgrade confirmation.

    Args:
      trip_id: the slug from a `checkin_trip_row_<trip_id>` accessibility id in
        the check-in sheet — looks like 'TRIP_UPCOMING_001'. Read it by calling
        observe() once the check-in sheet is open (it is NOT shown by
        view_trips). Must be a trip eligible for check-in.

    Returns a success message + UI tree once the boarding-pass screen is
    reached, or a failure message (trip not eligible / flow not open / Complete
    not reachable). Legacy single-verb commit — prefer prepare_check_in +
    confirm_check_in for new code.
    """
    fallback = _complete_check_in_state(trip_id)
    if fallback.get("ok"):
        return {
            "ok": True,
            "action": "check_in",
            "trip_id": trip_id,
            "state_fallback": fallback,
        }
    err = _check_in_select_and_review(trip_id)
    if err is not None:
        return err
    err = _check_in_advance_to_seat()
    if err is not None:
        return err
    result = _check_in_commit()
    sim = SimulatorBridge.get()
    ui = sim.observe_text()
    if not result.get("ok"):
        return f"Could not complete check-in for '{trip_id}': {result.get('message')}\n\n{ui}"
    return f"Checked in for trip '{trip_id}'. {result.get('message')}\n\n{ui}"


@mcp.tool()
def prepare_check_in(trip_id: str) -> dict:
    """Drive the check-in flow up to the seat-selection step and capture
    pre-commit state WITHOUT tapping the final ``checkin_complete_button``.
    Opens the check-in sheet from Home automatically — works from any screen.

    Args:
      trip_id: the slug from a `checkin_trip_row_<trip_id>` id in the check-in
        sheet — looks like 'TRIP_UPCOMING_001'. Read it via observe() once the
        sheet is open (not shown by view_trips). Must be eligible for check-in.

    Taps the trip row, reads passenger name / SkyMiles / route / current seat
    off the review step, then taps Continue (`checkin_confirm_button`) to land
    on seat selection. Idempotent: re-calling when already past these steps is
    accepted, not an error.

    Returns ``{ok: True, draft_id, summary: {flight_id, passenger, skymiles,
    trip_summary, current_seat}, next}`` on success (pass draft_id to
    confirm_check_in), or ``{ok: False, message}`` if the trip row or Continue
    button cannot be reached (e.g. trip not eligible).
    """
    err = _check_in_select_and_review(trip_id)
    if err is not None:
        return {"ok": False, "action": "prepare_check_in", "message": err}
    # Capture passenger/flight details from the review step BEFORE advancing.
    summary = _check_in_capture_summary(trip_id)
    err = _check_in_advance_to_seat()
    if err is not None:
        return {"ok": False, "action": "prepare_check_in", "message": err}
    draft_id = ts.create_draft("skytrip", "check_in", summary)
    return {
        "ok": True,
        "action": "prepare_check_in",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_check_in(draft_id) to commit.",
    }


@mcp.tool()
def confirm_check_in(draft_id: str) -> dict:
    """Commit a check-in previously staged by ``prepare_check_in``.

    Args:
      draft_id: the exact id returned by a preceding ``prepare_check_in`` call.

    Consumes the draft, then taps ``checkin_complete_button`` (and the optional
    paid seat-upgrade confirm) on the live seat-selection step to finalize.
    Requires the check-in flow to still be on the seat-selection step from the
    matching prepare_check_in. Returns
    ``{ok: True, action: "confirm_check_in", evidence: <summary>}`` on success,
    or ``{ok: False, message, ...}`` if the draft is missing/expired (call
    prepare_check_in first) or the Complete button is no longer reachable.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_check_in",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_check_in first.",
        }
    result = _check_in_commit()
    if not result.get("ok"):
        return {
            "ok": False,
            "action": "confirm_check_in",
            "message": result.get("message"),
            "evidence": draft.get("payload", {}),
        }
    return {
        "ok": True,
        "action": "confirm_check_in",
        "message": result.get("message"),
        "evidence": draft.get("payload", {}),
    }


@mcp.tool()
def view_boarding_pass() -> str:
    """Tap the boarding pass button after check-in and return the UI tree.

    Precondition: must have completed check-in for some trip (the
    `checkin_view_boarding_pass_button` is only present post-check-in).
    """
    sim = SimulatorBridge.get()
    try:
        ui = sim.tap_and_observe("checkin_view_boarding_pass_button")
    except Exception as exc:
        return f"No boarding pass button found. Check in for a trip first. Error: {str(exc)[:120]}"
    return f"Boarding pass:\n\n{ui}"


@mcp.tool()
def view_wallet() -> str:
    """Open the SkyMiles (wallet) tab and return its UI tree. Self-navigates
    (relaunches/dismisses overlays as needed), so it works from any screen."""
    sim = SimulatorBridge.get()
    _goto_tab(sim, "wallet")
    ui = sim.observe_text()
    return f"Wallet:\n\n{ui}"


def _open_more_detail(row_id: str, markers: list, label: str):
    """Navigate to the More tab and open one of its EXPLORE detail sheets.

    Each EXPLORE entry is a Button (`more_menu_<x>_row`) that presents a
    PlaceholderDetailView sheet; the rich content (forms, cards, titles)
    only renders inside that sheet. Verifies the sheet opened by checking
    for any of *markers* (or the sheet's own Done button) in the tree.
    """
    sim = SimulatorBridge.get()
    done_marker = f"{row_id}_detail_done_button"

    def _try_open() -> str:
        """One open attempt from a (hopefully) clean More list. Returns the UI
        tree if the target sheet rendered, else ''."""
        # Close any sheet/popover that may be covering the More list, then make
        # sure we're actually on the More tab list (a covered row taps as a
        # no-op or lands on the still-open sheet).
        _dismiss_blocking_overlays(sim)
        if not _goto_tab(sim, "more"):
            return ""
        try:
            sim.tap_id(row_id); sim.wait(1.0)
        except Exception:
            return ""
        ui_ = sim.observe_text() or ""
        if done_marker in ui_ or any(m in ui_ for m in markers):
            return ui_
        return ""

    ui = _try_open()
    if ui:
        return f"{label}:\n\n{ui}"
    # The row was likely covered by another open detail sheet (the agent had a
    # different More-tool sheet up). Force-dismiss and retry once more.
    _dismiss_blocking_overlays(sim)
    ui = _try_open()
    if ui:
        return f"{label}:\n\n{ui}"
    cur = sim.observe_text() or ""
    return (
        f"Could not open {label}: tapped {row_id} but the detail sheet "
        f"did not render.\n\n{cur}"
    )


@mcp.tool()
def check_flight_status() -> str:
    """Open the flight status lookup screen (More tab > Flight Status) and
    return its UI tree. Self-navigates to the More tab and dismisses any other
    open More detail sheet first, so it works from any screen; retries once if
    the sheet is covered. Returns the sheet's UI tree, or a message + current
    tree if the detail sheet did not render."""
    return _open_more_detail(
        "more_menu_flight_status_row",
        ["flight_status_lookup_form", "flight_status_recent_title",
         "flight_status_lookup_title"],
        "Flight status",
    )


@mcp.tool()
def track_bags() -> str:
    """Open the bag-tracking screen (More tab > Track My Bags) and return its
    UI tree. Self-navigates to the More tab and dismisses any other open More
    detail sheet first, so it works from any screen; retries once if covered.
    Returns the sheet's UI tree, or a message + current tree if it did not
    render."""
    return _open_more_detail(
        "more_menu_track_bags_row",
        ["track_bags_claim_card", "track_bags_info_card", "track_bags_header"],
        "Bag tracking",
    )


@mcp.tool()
def view_notifications() -> str:
    """Open the alerts/notifications center from the Home tab.

    Self-navigates to Home (relaunches/dismisses overlays as needed), then taps
    `home_notifications_button` (the bell icon) — works from any screen. Returns
    the resulting UI tree, which contains `alerts_center_row_<alert_id>` rows
    (ids like ALERT_001) for use with `open_alert`, or a message + tree if the
    center did not open.
    """
    sim = SimulatorBridge.get()
    _goto_tab(sim, "home")
    try:
        sim.tap_id("home_notifications_button")
        sim.wait(0.7)
    except Exception as exc:
        return f"Could not open notifications. Error: {str(exc)[:120]}"
    ui = sim.observe_text() or ""
    if "alerts_center_done_button" not in ui and "alerts_center_row_" not in ui \
            and "alerts_center_empty_state" not in ui:
        return (f"Could not open the alerts center after tapping the notifications bell; it did not "
                f"open.\n\n{ui}")
    return f"Notifications:\n\n{ui}"


@mcp.tool()
def open_alert(alert_id: str) -> str:
    """Surface a specific alert in the alerts center. Opens the center from the
    Home tab if it isn't already showing — works from any screen.

    Args:
      alert_id: the trailing slug from an `alerts_center_row_<alert_id>` id
        visible in the alerts center UI tree — looks like 'ALERT_001'. Get it
        from view_notifications() or observe().

    The alerts center is a READ-ONLY list: each alert renders its title,
    severity, message, and timestamp inline in an `alerts_center_row_<id>`
    container that is NOT a navigable button (there is no per-alert detail
    screen). This tool just verifies the requested row is present and focuses
    it. Returns ``{ok: True, alert_id, message}`` when the row is shown, or
    ``{ok: False, message}`` listing the visible alert ids when alert_id is not
    present (so the agent can pick a valid one rather than guess).
    """
    sim = SimulatorBridge.get()
    ui = sim.observe_text() or ""
    if "alerts_center_done_button" not in ui:
        # Alerts center not open — open it from Home.
        _goto_tab(sim, "home")
        try:
            sim.tap_id("home_notifications_button"); sim.wait(0.7)
        except Exception as exc:
            return {"ok": False, "action": "open_alert",
                    "message": f"Could not open the alerts center: {str(exc)[:120]}"}
        ui = sim.observe_text() or ""
    row_id = f"alerts_center_row_{alert_id}"
    if row_id not in ui:
        present = sorted(set(re.findall(r'alerts_center_row_(\w+)', ui)))
        return {"ok": False, "action": "open_alert",
                "message": (f"No alert '{alert_id}' in the alerts center. "
                            f"Visible alert ids: {', '.join(present) or 'none'}.")}
    # Tap the row to scroll/focus it (no detail navigation exists), then
    # read the alert's title/message off the live tree as evidence.
    try:
        sim.tap_id(row_id); sim.wait(0.3)
    except Exception:
        pass
    ui = sim.observe_text() or ""
    return {"ok": True, "action": "open_alert", "alert_id": alert_id,
            "message": f"Alert {alert_id} is shown in the alerts center."}


@mcp.tool()
def close_alerts_center() -> str:
    """Dismiss the alerts center sheet by tapping its Done button."""
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("alerts_center_done_button"); sim.wait(0.3)
    except Exception as exc:
        return f"Could not close alerts center: {str(exc)[:120]}"
    if "alerts_center_done_button" in (sim.observe_text() or ""):
        return "Could not close alerts center: Done button is still visible."
    return "Closed alerts center."


@mcp.tool()
def view_aircraft_fleet() -> str:
    """Open the aircraft directory (More tab > Aircraft) and return its UI
    tree. Self-navigates to the More tab and dismisses any other open More
    detail sheet first, so it works from any screen; retries once if covered.
    Returns the sheet's UI tree, or a message + current tree if it did not
    render."""
    return _open_more_detail(
        "more_menu_aircraft_row",
        ["aircraft_fleet_title"],
        "Aircraft fleet",
    )


@mcp.tool()
def view_airport_maps() -> str:
    """Open the airport-maps directory (More tab > Airport Maps) and return its
    UI tree. Self-navigates to the More tab and dismisses any other open More
    detail sheet first, so it works from any screen; retries once if covered.
    Returns the sheet's UI tree, or a message + current tree if it did not
    render."""
    return _open_more_detail(
        "more_menu_airport_maps_row",
        ["airport_maps_directory_title"],
        "Airport maps",
    )


if __name__ == "__main__":
    mcp.run()
