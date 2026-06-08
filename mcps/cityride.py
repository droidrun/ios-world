"""CityRide MCP — ride-hailing app on the iOS simulator.

Bundle ID: ``com.iosworld.benchmark.cityride``.

ID conventions used by tools below:
* Tabs: ``tab_home``, ``tab_activity``, ``tab_wallet``, ``tab_account``,
  ``tab_more`` (display names ``Home``, ``Activity``, ``Wallet``,
  ``Account``, ``Services`` also work).
* Ride request: ``request_pickup_chip_button``,
  ``request_destination_chip_button``, ``ride_type_row_<key>``
  (real backing keys ``standard``, ``xl``, ``green``, ``black``,
  ``comfort``; brand display names ``CityRideX``, ``CityRideXL``,
  ``CityRide Green``, ``CityRide Black``, ``CityRide Comfort`` and the
  legacy aliases ``uberx``/``uberxl``/``ubergreen`` all resolve onto those
  keys), ``request_confirm_button``.
* Activity rows: ``activity_past_trip_row_<trip_id>``,
  ``activity_upcoming_trip_row_<trip_id>`` with sibling buttons
  ``activity_rate_button_<id>``, ``activity_rebook_button_<id>``,
  ``activity_cancel_upcoming_<id>``, ``activity_detail_button_<id>``.
* Star ratings: ``rating_star_<n>`` for ``n`` in ``1..5``.
"""

import html
import sys, pathlib, re, json
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts
import _data_layer as dl

mcp = FastMCP("CityRide")

BUNDLE_ID = "com.iosworld.benchmark.cityride"
STATE_KEY = "ubersim.state.v1"

TAB_MAP = {
    # SwiftUI applies accessibilityIdentifier on the tab page; the bar
    # button often surfaces only the tabItem text label. Try both.
    "home":     ["tab_home", "Home"],
    "activity": ["tab_activity", "Activity"],
    "wallet":   ["tab_wallet", "Wallet"],
    "account":  ["tab_account", "Account"],
    "services": ["tab_more", "Services", "More"],
}

TAB_COORDS = {
    "home": (160, 940),
    "activity": (330, 940),
    "wallet": (500, 940),
    "account": (670, 940),
    "services": (840, 940),
}


def _slug(value: str) -> str:
    return value.lower().replace(" ", "_").replace("/", "_").replace("-", "_")


def _read_state() -> dict:
    raw = dl.read_user_defaults(BUNDLE_ID).get(STATE_KEY)
    if isinstance(raw, bytes):
        return json.loads(raw.decode("utf-8"))
    if isinstance(raw, str):
        return json.loads(raw)
    return {}


def _write_state(state: dict) -> None:
    defaults = dl.read_user_defaults(BUNDLE_ID)
    defaults[STATE_KEY] = json.dumps(state, separators=(",", ":"), sort_keys=True).encode("utf-8")
    dl.write_user_defaults(BUNDLE_ID, defaults)
    dl.reload_app(BUNDLE_ID)


def _cancel_trip_state(trip_id: str) -> dict:
    state = _read_state()
    trips = state.get("trips", [])
    trip = next((t for t in trips if t.get("id") == trip_id), None)
    if not trip:
        return {"ok": False, "error": f"trip '{trip_id}' not found"}
    if trip.get("tripStatus") not in {"reserved", "requesting", "driverAssigned", "driverArriving"}:
        return {"ok": False, "error": f"trip '{trip_id}' is not cancelable", "status": trip.get("tripStatus")}
    trip["tripStatus"] = "canceled"
    trip["reservedFor"] = None
    _write_state(state)
    return {"ok": True, "trip_id": trip_id, "status": "canceled"}


def _request_sheet_open(sim: SimulatorBridge) -> bool:
    tree = sim.observe_text() or ""
    return any(
        marker in tree
        for marker in (
            "request_destination_chip_button",
            "request_confirm_button",
            "request_ride_types_title",
            "request_modal_close_button",
        )
    )


_OVERLAY_MARKERS = (
    # Ride-request modal sheet.
    "request_confirm_button", "request_destination_chip_button",
    "request_modal_close_button", "request_ride_types_title",
    # Plan-a-ride sheet.
    "plan_ride_add_stop", "plan_ride_destination_field",
    "plan_ride_pickup_current_location",
    # Rating sheet.
    "rating_star_1", "rating_submit_button",
)


def _overlay_present(sim: SimulatorBridge, tree: Optional[str] = None) -> bool:
    """True if a modal sheet (request / plan-ride / rating) is covering the tabs.

    These sheets are presented over the tab bar: their controls appear in the
    tree, but the bottom tab-bar coordinates are physically covered, so a blind
    ``tap_xy`` on a tab no-ops and the underlying list never re-renders. Callers
    that need a tab/list must dismiss the overlay first (``_dismiss_overlays``).
    """
    t = tree if tree is not None else (sim.observe_text() or "")
    return any(m in t for m in _OVERLAY_MARKERS)


def _dismiss_overlays(sim: SimulatorBridge, tries: int = 3) -> bool:
    """Dismiss any modal sheet so the tab bar / underlying list is reachable.

    A live qwen run showed navigation/enumeration tools no-op when the agent
    leaves a ride-request or plan-ride sheet open: the tab tap lands on the
    covering sheet. We dismiss via the modal close button when present, then
    fall back to a swipe-down (sheet grabber) and finally a full relaunch
    (which always returns to a clean Home with the tab bar exposed).

    Returns True once no overlay marker remains.
    """
    for _ in range(max(1, tries)):
        tree = sim.observe_text() or ""
        if not _overlay_present(sim, tree):
            return True
        # Prefer an explicit close affordance if one is rendered.
        tapped = False
        for aid in ("request_modal_close_button",):
            if aid in tree:
                try:
                    sim.tap_id(aid); sim.wait(0.5); tapped = True; break
                except Exception:
                    pass
        if tapped:
            continue
        # No close button (plan-ride / rating sheets): swipe the sheet down.
        try:
            sim.swipe("down", x=400, y=850); sim.wait(0.5)
        except Exception:
            pass
        if not _overlay_present(sim):
            return True
        # Last resort: relaunch to a clean Home.
        try:
            sim.launch_and_observe(BUNDLE_ID); sim.wait(0.4)
        except Exception:
            pass
    return not _overlay_present(sim)


def _clear_field(sim: SimulatorBridge, aid: str) -> bool:
    """Clear a focused text field by accessibility id via the raw driver.

    The bridge exposes ``type_text`` (which appends) but no clear primitive.
    The ride-request destination/pickup chips arrive pre-populated with the
    top recent place, so any blind ``type_text`` would concatenate onto that
    seed value and never match a search result. We reach through to the
    Appium driver's ``element.clear()`` to wipe the field first.
    """
    try:
        from appium.webdriver.common.appiumby import AppiumBy
        el = sim.driver.find_element(AppiumBy.ACCESSIBILITY_ID, aid)
        el.clear()
        sim.wait(0.3)
        return True
    except Exception:
        return False


# Markers proving CityRide itself is foregrounded (any tab / the request
# sheet). If NONE of these are in the tree, the springboard or another app is
# on top (a stale `launch`, a cross-app multi-task, or the app never finished
# foregrounding) and blind tab/where-to taps would land on the wrong surface.
_CITYRIDE_FOREGROUND_MARKERS = (
    "home_where_to_button",
    "activity_filter_button", "wallet_payment_method_row_",
    "account_saved_place_row_", "recent_destination_row_",
    "saved_place_row_", "suggested_destination_row_",
    # request / plan-ride / rating sheets are also "CityRide is up".
    "request_destination_chip_button", "request_confirm_button",
    "plan_ride_add_stop", "rating_star_1",
)


def _active_bundle_id(sim: SimulatorBridge) -> Optional[str]:
    try:
        info = sim.connect().execute_script("mobile: activeAppInfo")
    except Exception:
        return None
    if isinstance(info, dict):
        bundle = info.get("bundleId")
        if isinstance(bundle, str) and bundle:
            return bundle
    return None


def _cityride_foreground(sim: SimulatorBridge, tree: Optional[str] = None) -> bool:
    t = tree if tree is not None else (sim.observe_text() or "")
    return f'bundleId="{BUNDLE_ID}"' in t or any(m in t for m in _CITYRIDE_FOREGROUND_MARKERS)


def _observe_cityride_scoped(sim: SimulatorBridge):
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
                "message": "CityRide is not the foreground app; observe() did not return another app's UI tree.",
            }

    tree = sim.observe_text() or ""
    if active == BUNDLE_ID or _cityride_foreground(sim, tree):
        return tree

    return {
        "ok": False,
        "error": "app-mismatch",
        "expected_bundle": BUNDLE_ID,
        "actual_bundle": _active_bundle_id(sim),
        "message": "Could not verify CityRide as the foreground app; observe() did not return an unscoped UI tree.",
    }


def _ensure_cityride_foreground(sim: SimulatorBridge) -> str:
    """Make sure CityRide is the foreground app; relaunch if it isn't.

    Returns the (possibly post-relaunch) UI tree text. Cheap when the app is
    already up (single observe, no relaunch) — only relaunches when no CityRide
    marker is visible, so it does not thrash a healthy session.
    """
    tree = sim.observe_text() or ""
    if _cityride_foreground(sim, tree):
        return tree
    try:
        tree = sim.launch_and_observe(BUNDLE_ID) or ""
        sim.wait(0.5)
    except Exception:
        tree = sim.observe_text() or ""
    return tree


def _try_open_where_to(sim: SimulatorBridge) -> bool:
    """One pass at opening the request modal, assuming CityRide is foregrounded.

    Dismiss covering sheets, ensure Home is active, tap the "Where to?" bar,
    then fall back to seed / live destination rows. No relaunch here — the
    caller (``_open_where_to_sheet``) owns the foreground-ensure + retry loop.
    """
    if _request_sheet_open(sim):
        return True
    # A non-request sheet (plan-ride / rating) may cover the Home search bar,
    # making home_where_to_button taps no-op. Dismiss it first.
    if _overlay_present(sim):
        _dismiss_overlays(sim)
        if _request_sheet_open(sim):
            return True
    # Ensure Home is active.
    try:
        sim.tap_xy(*TAB_COORDS["home"]); sim.wait(0.4)
    except Exception:
        pass
    # Primary: the "Where to?" search bar opens the full request modal.
    try:
        sim.tap_id("home_where_to_button"); sim.wait(0.9)
        if _request_sheet_open(sim):
            return True
    except Exception:
        pass
    seed_rows = (
        "recent_destination_row_pier_39",
        "recent_destination_row_ferry_building",
        "suggested_destination_row_airport",
        "saved_place_row_home",
        "saved_place_row_work",
    )
    for row in seed_rows:
        try:
            sim.tap_id(row); sim.wait(0.8)
            if _request_sheet_open(sim):
                return True
        except Exception:
            continue
    # Fall back: scan the live tree for any destination/place row.
    tree = sim.observe_text() or ""
    for row in re.findall(
        r'name="((?:recent_destination_row_|suggested_destination_row_|saved_place_row_)[^"]+)"',
        tree,
    ):
        try:
            sim.tap_id(row); sim.wait(0.8)
            if _request_sheet_open(sim):
                return True
        except Exception:
            continue
    return False


def _open_where_to_sheet(sim: SimulatorBridge) -> bool:
    """Open the ride-request modal from the Home screen.

    The primary entry point is ``home_where_to_button`` (the big "Where to?"
    search bar), which presents the full request modal directly (destination
    chip + ride-type rows + confirm button). If that id is missing we fall
    back to tapping any seed/visible destination row, which also opens the
    modal with that row pre-selected.

    Robust to CityRide not being foregrounded: the real benchmark showed
    `set_pickup` racing a not-yet-foregrounded app (a stale `launch`, or a
    cross-app multi-task left another app on top), so blind home-tab /
    where-to taps hit the springboard. We FIRST ensure CityRide is up
    (relaunch only if no CityRide marker is visible), then retry the open
    sequence once with a fresh relaunch before giving up.
    """
    if _request_sheet_open(sim):
        return True
    # Pass 1: ensure CityRide is foregrounded, then try to open the modal.
    _ensure_cityride_foreground(sim)
    if _try_open_where_to(sim):
        return True
    # Pass 2: a clean relaunch resets to a known Home with the tab bar exposed
    # (clears any half-open sheet or wrong-app state), then one more attempt.
    try:
        sim.launch_and_observe(BUNDLE_ID); sim.wait(0.6)
    except Exception:
        pass
    if _try_open_where_to(sim):
        return True
    return False


def _seed_destinations() -> list:
    """All known place dicts from seed state (places + saved + recent + suggested).

    Each dict has at least ``displayName``; deduped by displayName.
    """
    state = _read_state()
    out, seen = [], set()
    for key in ("places", "savedPlaces", "recentDestinations",
                "suggestedDestinations"):
        for p in state.get(key, []) or []:
            name = (p.get("displayName") or "").strip()
            if name and name.lower() not in seen:
                seen.add(name.lower())
                out.append(p)
    return out


def _resolve_destination_name(query: str) -> Optional[str]:
    """Resolve a blind destination query to a canonical seed display name.

    Matches case-insensitively by exact, then substring, then token overlap
    against seed place names. Returns the canonical displayName or ``None``.
    """
    q = (query or "").strip().lower()
    if not q:
        return None
    names = [p.get("displayName", "") for p in _seed_destinations()]
    # Exact (case-insensitive).
    for n in names:
        if n.lower() == q:
            return n
    # Substring either direction.
    for n in names:
        nl = n.lower()
        if q in nl or nl in q:
            return n
    # Token overlap.
    qtok = set(q.replace(",", " ").split())
    best, best_score = None, 0
    for n in names:
        ntok = set(n.lower().split())
        score = len(qtok & ntok)
        if score > best_score:
            best, best_score = n, score
    return best if best_score else None


def _select_destination_in_sheet(sim: SimulatorBridge, destination: str) -> bool:
    """With the request modal open, set ``destination`` and surface ride types.

    Strategy: tap the destination chip, CLEAR it (the chip is pre-filled with
    the top recent place), type the query, then tap the matching
    ``request_search_result_<slug>`` row (falling back to the first search
    result or the "Search for ..." map row). Returns True once the confirm
    button is visible.
    """
    try:
        sim.tap_id("request_destination_chip_button"); sim.wait(0.3)
    except Exception:
        return False
    _clear_field(sim, "request_destination_chip_button")
    try:
        sim.type_text(destination); sim.wait(0.9)
    except Exception:
        return False
    after = sim.observe_text() or ""
    slug = _slug(destination)
    results = re.findall(r'name="(request_search_result_[^"]+)"', after)
    # Build an ordered candidate list: slug-matching results first, then a
    # slug-matching recent/suggested/saved row, then any remaining results.
    rows = re.findall(
        r'name="((?:recent_destination_row_|suggested_destination_row_|'
        r'saved_place_row_)[^"]+)"',
        after,
    )
    ordered: list = []
    for r in results:
        if slug and slug in r:
            ordered.append(r)
    for r in rows:
        if slug and slug in r and r not in ordered:
            ordered.append(r)
    for r in results:
        if r not in ordered:
            ordered.append(r)
    # Tap candidates until ride-type rows (a real fare estimate) appear. This
    # skips geocoder-ambiguous matches that open an empty request sheet.
    for cand in ordered[:4]:
        try:
            sim.tap_id(cand); sim.wait(0.9)
        except Exception:
            continue
        tree = sim.observe_text() or ""
        if "ride_type_row_standard" in tree:
            return True
        if "request_confirm_button" in tree and "request_empty_state_message" not in tree:
            return True
        # Re-open the chip to retry another candidate.
        try:
            sim.tap_id("request_destination_chip_button"); sim.wait(0.3)
            _clear_field(sim, "request_destination_chip_button")
            sim.type_text(destination); sim.wait(0.7)
        except Exception:
            break
    final = sim.observe_text() or ""
    if "ride_type_row_standard" in final or "request_confirm_button" in final:
        return True
    # Last resort: the "Search for "<text>"" map row commits free text.
    try:
        from appium.webdriver.common.appiumby import AppiumBy
        el = sim.driver.find_element(
            AppiumBy.ACCESSIBILITY_ID, f'Search for "{destination}"')
        el.click(); sim.wait(0.9)
    except Exception:
        pass
    return "request_confirm_button" in (sim.observe_text() or "")


def _select_pickup_in_sheet(sim: SimulatorBridge, pickup: str) -> bool:
    """Set pickup on an open request modal and return to ride options."""
    try:
        sim.tap_id("request_pickup_chip_button"); sim.wait(0.3)
    except Exception:
        return False
    _clear_field(sim, "request_pickup_chip_button")
    try:
        sim.type_text(pickup); sim.wait(0.9)
    except Exception:
        return False

    after = sim.observe_text() or ""
    slug = _slug(pickup)
    results = re.findall(r'name="(request_search_result_[^"]+)"', after)
    rows = re.findall(
        r'name="((?:recent_destination_row_|suggested_destination_row_|'
        r'saved_place_row_|request_current_location_row)[^"]*)"',
        after,
    )
    ordered: list[str] = []
    for r in results + rows:
        if slug and slug in r and r not in ordered:
            ordered.append(r)
    for r in results + rows:
        if r not in ordered:
            ordered.append(r)

    for cand in ordered[:5]:
        try:
            sim.tap_id(cand); sim.wait(0.9)
        except Exception:
            continue
        tree = sim.observe_text() or ""
        if "ride_type_row_standard" in tree or "request_confirm_button" in tree:
            return True
        try:
            sim.tap_id("request_pickup_chip_button"); sim.wait(0.3)
            _clear_field(sim, "request_pickup_chip_button")
            sim.type_text(pickup); sim.wait(0.7)
        except Exception:
            break

    final = sim.observe_text() or ""
    return "ride_type_row_standard" in final or "request_confirm_button" in final


def _accessibility_safe(value: str) -> str:
    return value.lower().replace(" ", "_").replace("/", "_").replace("-", "_")


@mcp.tool()
def launch() -> str:
    """Launch CityRide and return the post-launch accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched CityRide.\n\n{ui}"


@mcp.tool()
def observe():
    """Return CityRide's UI tree, or ok:false if another app owns the foreground."""
    return _observe_cityride_scoped(SimulatorBridge.get())


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch to one of the CityRide bottom-bar tabs. Works from any screen.

    Self-recovers: dismisses any open modal sheet (ride-request / plan-ride /
    rating) first — otherwise the tab tap would land on the covering sheet —
    then taps the tab and verifies a per-tab marker actually rendered before
    reporting success.

    Args:
        tab_name: Tab slug, case-insensitive. Valid: ``home``, ``activity``,
            ``wallet``, ``account``, ``services`` (``services`` is the "More"
            tab). Any other value returns ``{ok: False, ...}`` listing valid
            slugs and does not navigate.

    Returns the tab's UI tree on success, or ``{ok: False, ...}`` if the
    tab's marker did not render after tapping.
    """
    candidates = TAB_MAP.get(tab_name.lower())
    if candidates is None:
        # Explicit ok:False — a bare "Unknown tab ..." string would otherwise be
        # marked ok:true by the envelope wrapper (no failure-prefix match).
        return {
            "ok": False,
            "action": "navigate_to_tab",
            "message": f"Unknown tab '{tab_name}'. Valid tabs: {', '.join(TAB_MAP.keys())}",
        }
    sim = SimulatorBridge.get()
    # Dismiss any modal sheet first — otherwise the tab tap lands on the
    # covering ride-request / plan-ride sheet and silently no-ops.
    _dismiss_overlays(sim)
    # Per-tab markers that prove we actually landed on the destination tab.
    landed_marker = {
        "home": "home_where_to_button",
        "activity": "activity_filter_button",
        "wallet": "wallet_payment_method_row_",
        "account": "account_saved_place_row_",
        "services": None,
    }.get(tab_name.lower())
    coords = TAB_COORDS.get(tab_name.lower())
    for _ in range(2):
        if coords:
            sim.tap_xy(*coords); sim.wait(0.5)
        else:
            for aid in candidates:
                try:
                    sim.tap_id(aid); sim.wait(0.4); break
                except Exception:
                    continue
        tree = sim.observe_text() or ""
        if landed_marker is None or landed_marker in tree:
            return f"Navigated to '{tab_name}' tab.\n\n{tree}"
        # Retry via accessibility id if the coordinate tap missed.
        for aid in candidates:
            try:
                sim.tap_id(aid); sim.wait(0.4); break
            except Exception:
                continue
        tree = sim.observe_text() or ""
        if landed_marker is None or landed_marker in tree:
            return f"Navigated to '{tab_name}' tab.\n\n{tree}"
    return {
        "ok": False,
        "action": "navigate_to_tab",
        "message": (
            f"Could not navigate to '{tab_name}' tab — its marker "
            f"'{landed_marker}' did not render after tapping {candidates}."
        ),
    }


@mcp.tool()
def request_ride(destination: str):
    """Open Where to?, type a destination, and select the matching suggestion.

    Works from any screen: self-navigates to Home and opens the request modal
    (via the "Where to?" search bar, falling back to a seed destination row),
    dismissing any covering sheet first.

    Args:
        destination: Free-text, human-readable destination name. A fuzzy
            resolver first maps it onto a canonical seed place (so partial /
            loose inputs like ``"airport"``, ``"ferry"``, ``"pier 39"`` work,
            matched by exact -> substring -> token overlap against seeded
            places). The resolved name is typed into the destination chip and
            the matching ``request_search_result_<slug>`` row is tapped; if no
            seed matches, the raw text is typed and committed via the map's
            "Search for ..." row. Examples: ``"Oracle Park"``, ``"SFO Airport"``.

    On success the request sheet is open with ride-type rows + fare/ETA
    estimates, returned as ``{ok: True, ride_options: [...]}`` so callers do
    not need to parse raw XML. Follow with ``select_ride_type(...)`` then
    ``prepare_ride()`` + ``confirm_ride(draft_id=...)``.
    """
    sim = SimulatorBridge.get()
    # Ensure Home is active.
    try:
        sim.tap_xy(*TAB_COORDS["home"]); sim.wait(0.4)
    except Exception:
        pass
    # Resolve the blind query to a canonical seed place name when possible so
    # fuzzy inputs ("airport", "ferry") still hit the right search result.
    canonical = _resolve_destination_name(destination) or destination
    # Open the request modal, then type the destination and select the result
    # that yields a real fare estimate (ride-type rows).
    if not _open_where_to_sheet(sim):
        return "Could not open the ride request sheet from the home screen."
    ok = _select_destination_in_sheet(sim, canonical)
    if not ok and canonical != destination:
        # Retry with the raw query in case the canonical alias missed.
        ok = _select_destination_in_sheet(sim, destination)
    ui = sim.observe_text() or ""
    if "request_confirm_button" not in ui:
        return (
            f"Could not load ride options after entering destination '{destination}'. They did not "
            "appear. Call observe() to inspect the request modal."
        )
    types_loaded = "ride_type_row_standard" in ui
    ride_options = _parse_ride_options(ui)
    tail = ("Select a ride type next." if types_loaded else
            "Request sheet is open; ride options for this destination did not "
            "load a fare — try a nearby landmark.")
    return {
        "ok": True,
        "action": "request_ride",
        "destination": canonical,
        "ride_options": ride_options,
        "message": f"Requested ride to '{canonical}'. {tail}",
        "ui_excerpt": ui[:1500],
    }


@mcp.tool()
def select_ride_type(ride_type: str) -> str:
    """Tap a ride-tier row on the request sheet.

    Args:
        ride_type: Display name or backing key, case-insensitive. The real
            ``ride_type_row_*`` keys in this build are ``standard``, ``xl``,
            ``green``, ``black``, ``comfort``. Accepted spellings resolve onto
            them: ``CityRideX`` / ``uberx`` / ``x`` -> standard,
            ``CityRideXL`` / ``uberxl`` / ``xl`` -> xl,
            ``CityRide Green`` / ``ubergreen`` / ``green`` -> green,
            ``CityRide Black`` / ``black`` -> black,
            ``CityRide Comfort`` / ``comfort`` -> comfort. Other strings are
            passed through as ``ride_type_row_<value>`` and return an error
            listing the candidates tried if no row matches.

    Requires the request sheet to be open and showing tier rows (call
    ``request_ride(destination=...)`` first). Does not self-navigate.
    """
    sim = SimulatorBridge.get()
    for _ in range(3):
        tree = sim.observe_text() or ""
        if any(f"ride_type_row_{k}" in tree for k in ("standard", "xl", "green", "black", "comfort")):
            break
        if "request_confirm_button" not in tree and "request_destination_chip_button" not in tree:
            break
        sim.wait(0.5)
    # Real ride_type_row keys in this build: standard, xl, green, black, comfort.
    aliases = {
        "cityridex": "standard", "cityride x": "standard", "uberx": "standard",
        "standard": "standard", "x": "standard",
        "cityridexl": "xl", "cityride xl": "xl", "uberxl": "xl", "xl": "xl",
        "cityride green": "green", "ubergreen": "green", "green": "green",
        "cityride black": "black", "black": "black",
        "cityride comfort": "comfort", "comfort": "comfort",
    }
    normalized = ride_type.strip().lower().replace("_", " ")
    compact = normalized.replace(" ", "")
    key = aliases.get(normalized, aliases.get(compact, compact))
    candidates = [
        f"ride_type_row_{key}",
        f"ride_type_row_{compact}",
        f"ride_type_row_{ride_type}",
    ]
    last_exc = None
    for candidate in dict.fromkeys(candidates):
        try:
            ui = sim.tap_and_observe(candidate)
            return f"Selected ride type '{ride_type}'.\n\n{ui}"
        except Exception as exc:
            last_exc = exc
    return (
        f"No ride option matching '{ride_type}' is visible. "
        f"Tried {list(dict.fromkeys(candidates))}. Error: {str(last_exc)[:120]}"
    )


def _ride_capture_summary() -> tuple[Optional[dict], Optional[str]]:
    """Inspect the current UI tree for the staged ride request sheet.

    Returns ``(summary, None)`` where ``summary`` is
    ``{"pickup": <str or None>, "destination": <str or None>,
       "fare": <str or None>, "eta_minutes": <str or None>,
       "ride_type": <str or None>}`` or ``(None, message)`` if the request
    sheet is not in a confirmable state.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "request_confirm_button" not in tree:
        return None, (
            "Ride request sheet is not in a confirmable state. Call "
            "request_ride(destination=...) and select_ride_type(...) first."
        )
    # The confirm button label embeds verb + ride type + price, e.g.
    # "Request CityRideX · $12.34". Parse this from the visible label.
    pickup = None
    destination = None
    fare = None
    eta = None
    ride_type = None
    # `request_pickup_chip_button` and `request_destination_chip_button`
    # surface as TextField elements whose `value` attribute mirrors the
    # entered text. Capture both `value="..."` and adjacent `name="..."`
    # patterns conservatively.
    pickup_m = re.search(
        r'name="request_pickup_chip_button"[^>]*\bvalue="([^"]+)"',
        tree,
    )
    if pickup_m:
        pickup = pickup_m.group(1).strip() or None
    dest_m = re.search(
        r'name="request_destination_chip_button"[^>]*\bvalue="([^"]+)"',
        tree,
    )
    if dest_m:
        destination = dest_m.group(1).strip() or None
    # Selected ride row carries the price label estimate_price_label_<id>.
    price_m = re.search(
        r'name="estimate_price_label_[^"]+"[^>]*\bvalue="([^"]+)"',
        tree,
    )
    if not price_m:
        price_m = re.search(
            r'name="estimate_price_label_[^"]+"[^>]*\blabel="([^"]+)"',
            tree,
        )
    if not price_m:
        price_m = re.search(
            r'name="upfront_price_badge"[^>]*\b(?:value|label)="([^"]+)"',
            tree,
        )
    if price_m:
        fare = price_m.group(1).strip() or None
    eta_m = re.search(
        r'name="estimate_eta_label_[^"]+"[^>]*\b(?:value|label)="([^"]+)"',
        tree,
    )
    if not eta_m:
        eta_m = re.search(
            r'name="map_eta_chip"[^>]*\b(?:value|label)="([^"]+)"',
            tree,
        )
    if eta_m:
        eta = eta_m.group(1).strip() or None
    type_m = re.search(r'ride_type_row_([A-Za-z0-9_]+)', tree)
    if type_m:
        ride_type = type_m.group(1)
    return {
        "pickup": pickup,
        "destination": destination,
        "fare": fare,
        "eta_minutes": eta,
        "ride_type": ride_type,
    }, None


def _parse_ride_options(tree: str) -> list[dict]:
    """Extract visible ride rows as structured estimates."""
    options = []
    pattern = re.compile(
        r'name="ride_type_row_([^"]+)"[^>]*\blabel="([^"]+)"'
    )
    for key, raw_label in pattern.findall(tree or ""):
        label = html.unescape(raw_label).strip()
        parts = [p.strip() for p in label.split(",")]
        option = {
            "key": key,
            "name": parts[0] if parts else None,
            "fare": None,
            "eta": None,
            "capacity": None,
            "badges": [],
            "label": label,
        }
        if len(parts) > 1 and parts[1].startswith("$"):
            option["fare"] = parts[1]
        for part in parts:
            if re.search(r"\bmin away\b", part):
                option["eta"] = part
            elif part.isdigit():
                option["capacity"] = int(part)
        option["badges"] = [
            p for p in parts[2:]
            if p and p != "·" and not re.search(r"\bmin away\b", p)
            and not p.isdigit()
        ]
        options.append(option)
    return options


def _trip_summary(t: dict) -> dict:
    return {
        "id": t.get("id"),
        "status": t.get("tripStatus"),
        "pickup": t.get("pickupName"),
        "destination": t.get("destinationName"),
        "ride_type": t.get("rideType") or t.get("rideTypeId"),
        "fare": t.get("estimatedPrice"),
        "currency": t.get("currency", "USD"),
        "eta_minutes": t.get("etaMinutes"),
        "route": t.get("routeLabel"),
        "requested_at": t.get("requestedAt"),
        "pickup_time": t.get("pickupTime"),
        "dropoff_time": t.get("dropoffTime"),
    }


def _find_trip(trip_id: str) -> Optional[dict]:
    raw = (trip_id or "").strip()
    if not raw:
        return None
    return next((t for t in _read_state().get("trips", []) or [] if t.get("id") == raw), None)


@mcp.tool()
def prepare_ride() -> dict:
    """Capture the staged ride-request summary WITHOUT confirming.

    Reads the request sheet (pickup, destination, fare, ETA, selected ride
    type) so the agent can sanity-check the booking target before
    committing. Does NOT tap the Request/Confirm button. Requires that
    `request_ride(destination=...)` and `select_ride_type(...)` have already
    been called to surface a confirmable request sheet.

    Returns ``{ok: True, draft_id, summary, next}`` on success, or a
    controlled-failure response if the request sheet is not in a
    confirmable state.
    """
    summary, err = _ride_capture_summary()
    if err is not None:
        return {"ok": False, "action": "prepare_ride", "message": err}
    draft_id = ts.create_draft("cityride", "ride", summary)
    return {
        "ok": True,
        "action": "prepare_ride",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_ride(draft_id=...) to commit.",
    }


@mcp.tool()
def confirm_ride(draft_id: str) -> dict:
    """Confirm the current ride request.

    The draft from a prior ``prepare_ride()`` call is consumed first; if it is
    missing or expired, returns a controlled-failure response without tapping
    the confirm button.

    Requires the request sheet open with a ride type selected; returns
    ``{ok: False, ...}`` if the confirm button cannot be tapped.
    """
    sim = SimulatorBridge.get()
    evidence: dict = {}
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_ride",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_ride() first.",
        }
    evidence = draft.get("payload", {}) or {}
    try:
        ui = sim.tap_and_observe("request_confirm_button")
    except Exception as exc:
        return {
            "ok": False,
            "action": "confirm_ride",
            "message": (
                f"Could not tap request_confirm_button: {str(exc)[:120]}. "
                "Verify the ride request sheet is open and a ride type is selected."
            ),
            "evidence": evidence,
        }
    return {
        "ok": True,
        "action": "confirm_ride",
        "evidence": evidence,
        "ui": ui,
    }


@mcp.tool()
def cancel_ride() -> str:
    """Tap ``trip_cancel_button`` to cancel the active in-progress ride.

    Requires an active trip view to be open. Verifies the cancellation took
    effect by confirming the trip status chip flips to ``canceled`` before
    reporting success (the cancel control itself stays on the active-trip
    view, so its presence alone is not proof).
    """
    sim = SimulatorBridge.get()
    if "trip_cancel_button" not in (sim.observe_text() or ""):
        return (
            "No active trip to cancel — the active-trip view (trip_cancel_button) "
            "is not open. Confirm a ride first."
        )
    try:
        sim.tap_id("trip_cancel_button"); sim.wait(0.6)
    except Exception as exc:
        return f"Could not tap trip_cancel_button: {str(exc)[:120]}."
    tree = sim.observe_text() or ""
    if "trip_status_chip_canceled" in tree or "trip_stage_chip_canceled" in tree:
        return f"Cancelled ride.\n\n{tree}"
    return (
        "Tapped trip_cancel_button but the trip status did not flip to canceled. "
        "Call observe() to inspect the active-trip view."
    )


@mcp.tool()
def view_trip_history() -> str:
    """Switch to the Activity tab and return its UI tree (trip history)."""
    sim = SimulatorBridge.get()
    _dismiss_overlays(sim)
    for _ in range(2):
        sim.tap_xy(*TAB_COORDS["activity"]); sim.wait(0.5)
        if "activity_" in (sim.observe_text() or ""):
            break
        for aid in ("tab_activity", "Activity"):
            try: sim.tap_id(aid); sim.wait(0.4); break
            except Exception: continue
        if "activity_" in (sim.observe_text() or ""):
            break
    ui = sim.observe_text()
    return f"Trip history:\n\n{ui}"


@mcp.tool()
def view_wallet() -> str:
    """Switch to the Wallet tab and return its UI tree (cards/balance)."""
    sim = SimulatorBridge.get()
    _dismiss_overlays(sim)
    sim.tap_xy(*TAB_COORDS["wallet"]); sim.wait(0.4)
    if "wallet_payment_method_row_" not in (sim.observe_text() or ""):
        for aid in ("tab_wallet", "Wallet"):
            try: sim.tap_id(aid); sim.wait(0.4); break
            except Exception: continue
    ui = sim.observe_text()
    return f"Wallet:\n\n{ui}"


@mcp.tool()
def rate_trip(trip_id: str, stars: int) -> str:
    """Rate a completed past trip: open its rating sheet, pick a star, submit.

    Works from any screen: self-dismisses overlays and navigates to the
    Activity tab, expands the trip row (the Rate button renders inside the
    expanded card), opens the rating sheet, taps the star, and taps Submit so
    the rating is committed. Verifies the sheet closed before reporting success.

    Args:
        trip_id: Slug from ``list_past_trips()`` (e.g. ``"trip_001"``). Must
            correspond to an ``activity_rate_button_<id>`` button, which is
            only rendered for trips whose status is ``.tripCompleted``. An
            id that is not a completed trip yields a "rating sheet did not
            open" failure message.
        stars: Integer rating from ``1`` to ``5`` inclusive. Maps to a
            ``rating_star_<stars>`` button; out-of-range or non-integer values
            return a bounded error without tapping.
    """
    sim = SimulatorBridge.get()
    try:
        stars = int(stars)
    except Exception:
        return f"Could not rate trip: invalid star count '{stars}'. Use an integer 1..5."
    if not (1 <= stars <= 5):
        return f"Could not rate trip: star count {stars} out of range. Use an integer 1..5."
    # Dismiss any covering sheet, then self-navigate to Activity (where the
    # past-trip rows + rate buttons live).
    _dismiss_overlays(sim)
    try:
        sim.tap_xy(*TAB_COORDS["activity"]); sim.wait(0.5)
    except Exception:
        pass
    if "activity_past_trip_row_" not in (sim.observe_text() or ""):
        for aid in ("tab_activity", "Activity"):
            try:
                sim.tap_id(aid); sim.wait(0.5); break
            except Exception:
                continue
    # Expand the trip row first — the rate button is only rendered inside the
    # expanded card. Tapping the row toggles the inline Rate/Rebook actions.
    rate_id = f"activity_rate_button_{trip_id}"
    try:
        sim.tap_id(f"activity_past_trip_row_{trip_id}"); sim.wait(0.6)
    except Exception:
        pass
    # Open the rating sheet.
    try:
        sim.tap_id(rate_id); sim.wait(0.6)
    except Exception as exc:
        return (
            f"Could not open the rating sheet for '{trip_id}': {str(exc)[:120]}. "
            "Use a completed trip slug from list_past_trips()."
        )
    if "rating_star_1" not in (sim.observe_text() or ""):
        return (
            f"Could not open the rating sheet for '{trip_id}'. It may not be a "
            "completed trip. Use a slug from list_past_trips()."
        )
    # Pick the star and submit so the rating is committed.
    try:
        sim.tap_id(f"rating_star_{stars}"); sim.wait(0.3)
    except Exception as exc:
        return f"Could not select {stars} stars: {str(exc)[:120]}"
    for submit in ("rating_submit_button", "Submit"):
        try:
            sim.tap_id(submit); sim.wait(0.6); break
        except Exception:
            continue
    closed = "rating_star_1" not in (sim.observe_text() or "")
    if not closed:
        return (
            f"Could not submit rating — rating sheet still open for '{trip_id}' "
            f"({stars} stars not committed). The submit did not dismiss the sheet."
        )
    return f"Rated trip '{trip_id}' with {stars} stars."


@mcp.tool()
def list_past_trips(limit: int = 20) -> dict:
    """Scan the current UI tree for past-trip rows and return their slugs.

    Returns compact state-backed summaries for completed trips. ``limit``
    defaults to 20 to stay below tool-output truncation; pass ``0`` to return
    all completed trips.
    """
    import re
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "activity_completed_trip_row_" not in tree and "activity_past_trip_row_" not in tree:
        # Dismiss any covering sheet (else the tab tap no-ops) then navigate.
        _dismiss_overlays(sim)
        try:
            sim.tap_xy(*TAB_COORDS["activity"]); sim.wait(0.5)
        except Exception:
            pass
        tree = sim.observe_text() or ""
    # This build renders completed trips as ``activity_completed_trip_row_<id>``
    # (older builds used ``activity_past_trip_row_<id>``). Accept both.
    ids = sorted(set(
        re.findall(r'activity_(?:completed|past)_trip_row_([^"\s]+)', tree)
    ))
    # Fallback to app state so a covered/empty tree never yields a false-empty
    # enumeration (live qwen hit count:0 with an overlay up).
    state = _read_state()
    summaries = {
        t.get("id"): _trip_summary(t)
        for t in state.get("trips", []) or []
        if t.get("id") and t.get("tripStatus") == "tripCompleted"
    }
    ids = sorted(set(summaries) | {i for i in ids if i in summaries})
    total = len(ids)
    if limit and limit > 0:
        ids = ids[:limit]
    return {
        "past_trips": ids,
        "trips": [summaries[i] for i in ids if i in summaries],
        "count": total,
        "returned": len(ids),
        "truncated": total > len(ids),
    }


@mcp.tool()
def list_upcoming_trips(limit: int = 20) -> dict:
    """Scan the current UI tree for upcoming-trip rows and return their slugs.

    Returns ``{upcoming_trips: [slug, ...], count: int}`` extracted from
    every ``activity_upcoming_trip_row_<slug>`` in the tree. Self-navigates
    to the Activity tab first, so it works from a fresh launch.

    Note: this build does not render dedicated ``activity_upcoming_trip_row_``
    ids; reserved/scheduled trips surface through their cancel buttons
    (``activity_cancel_upcoming_<id>``). We derive the slugs from those (and
    from app state) so the list is populated regardless.
    """
    import re
    sim = SimulatorBridge.get()
    if "activity_filter_button" not in (sim.observe_text() or ""):
        _dismiss_overlays(sim)
        try:
            sim.tap_xy(*TAB_COORDS["activity"]); sim.wait(0.5)
        except Exception:
            pass
    tree = sim.observe_text() or ""
    ids = set(re.findall(r'activity_upcoming_trip_row_([^"\s]+)', tree))
    ids |= set(re.findall(r'activity_cancel_upcoming_([^"\s]+)', tree))
    # Augment from state (reserved/scheduled trips) so blind callers get the
    # full set even if the rows are scrolled off-screen.
    state = _read_state()
    summaries = {}
    for t in state.get("trips", []) or []:
        if t.get("tripStatus") in {"reserved", "requesting", "driverAssigned",
                                    "driverArriving", "scheduled"}:
            tid = t.get("id")
            if tid:
                ids.add(tid)
                summaries[tid] = _trip_summary(t)
    ids = sorted(ids)
    total = len(ids)
    if limit and limit > 0:
        ids = ids[:limit]
    return {
        "upcoming_trips": ids,
        "trips": [summaries[i] for i in ids if i in summaries],
        "count": total,
        "returned": len(ids),
        "truncated": total > len(ids),
    }


@mcp.tool()
def cancel_upcoming_trip(trip_id: str) -> str:
    """Cancel a scheduled/reserved future trip and persist the cancellation.

    Authoritatively flips the trip's state to ``canceled`` via the data layer
    (existence + cancelable check + persist + app reload), then best-effort
    taps the row's ``activity_cancel_upcoming_<id>`` button to mirror the UI.

    Args:
        trip_id: Slug from ``list_upcoming_trips()`` (e.g. ``"sched_002"``).
            Must be a trip whose status is one of ``reserved``, ``requesting``,
            ``driverAssigned``, ``driverArriving``. Unknown or non-cancelable
            ids return a bounded error message (no state change).
    """
    # Validate+persist via the data layer FIRST. ``tap_id`` raises for a
    # missing element, but routing all outcomes through ``_cancel_trip_state``
    # gives a single authoritative source of truth (existence + cancelable
    # check + persisted state + app reload) and a clean string envelope.
    result = _cancel_trip_state(trip_id)
    if not result.get("ok"):
        return (
            f"Could not cancel '{trip_id}': {result.get('error', 'not cancelable')}."
            " Use a slug from list_upcoming_trips() that is still scheduled/reserved."
        )
    try:
        sim = SimulatorBridge.get()
        sim.tap_id(f"activity_cancel_upcoming_{trip_id}")
        sim.wait(0.2)
    except Exception:
        pass
    return f"Cancelled trip {trip_id}."


@mcp.tool()
def rebook_trip(trip_id: str) -> str:
    """Start a new ride request reusing a past trip's route.

    Args:
        trip_id: Slug from ``list_past_trips()`` (e.g. ``"trip_past_1"``).
            Must correspond to an ``activity_rebook_button_<id>``.

    The in-app ``activity_rebook_button_<id>`` is tappable but a no-op in this
    build (it neither navigates nor creates a trip), so this tool resolves the
    trip's destination from app state and opens the ride-request sheet
    pre-targeted at that destination — the documented "same route" intent.
    """
    sim = SimulatorBridge.get()
    # Validate the trip exists and grab its destination for the rebooking.
    state = _read_state()
    trip = next((t for t in state.get("trips", []) if t.get("id") == trip_id), None)
    if trip is None:
        return (
            f"Could not rebook '{trip_id}': no such trip. Use a slug from "
            "list_past_trips()."
        )
    dest = (trip.get("destinationName") or trip.get("destination")
            or trip.get("dropoffName") or "")
    # Tap the real Rebook button first (best-effort; it is a UI no-op here but
    # keeps the action faithful when the build wires it up).
    try:
        _dismiss_overlays(sim)
        sim.tap_xy(*TAB_COORDS["activity"]); sim.wait(0.4)
        sim.tap_id(f"activity_rebook_button_{trip_id}"); sim.wait(0.5)
    except Exception:
        pass
    # If the tap opened a request sheet, we're done.
    if _request_sheet_open(sim):
        return f"Rebooking trip {trip_id} (request sheet open)."
    # Otherwise drive the request flow ourselves to the same destination.
    if not dest:
        return (
            f"Rebooked trip {trip_id}, but its destination is unknown; open the "
            "request sheet manually with request_ride(destination=...)."
        )
    result = request_ride(dest)
    msg = result if isinstance(result, str) else ""
    if _request_sheet_open(sim):
        return f"Rebooking trip {trip_id}: opened request to '{dest}'."
    return (
        f"Could not rebook trip {trip_id}: targeted '{dest}' but the request "
        f"sheet did not open. {msg[:120]}"
    )


@mcp.tool()
def open_trip_detail(trip_id: str) -> str:
    """Open a trip's detail view via its detail button.

    Args:
        trip_id: Slug from ``list_past_trips()`` or ``list_upcoming_trips()``.
            Must correspond to an ``activity_detail_button_<id>``; unknown
            slugs return a bounded error string.
    """
    sim = SimulatorBridge.get()
    # Ensure the Activity tab (which renders the trip rows + detail buttons) is
    # visible before trying to tap a detail control.
    if "activity_detail_button_" not in (sim.observe_text() or ""):
        _dismiss_overlays(sim)
        try:
            sim.tap_xy(*TAB_COORDS["activity"]); sim.wait(0.5)
        except Exception:
            pass
    # Real id in this build is ``activity_detail_button_<id>`` (added to past +
    # upcoming rows); older builds used ``activity_trip_detail_button_<id>``.
    last = None
    for btn in (f"activity_trip_detail_button_{trip_id}", f"activity_detail_button_{trip_id}"):
        err = sim.tap_and_verify_changed(
            btn,
            prefix_for_failure=f"No trip detail button found for '{trip_id}'. Use list_past_trips() or list_upcoming_trips() first. ",
        )
        if not err:
            return f"Opened trip {trip_id} detail."
        last = err
    trip = _find_trip(trip_id)
    if trip is not None:
        return {
            "ok": True,
            "action": "open_trip_detail",
            "trip_id": trip_id,
            "summary": _trip_summary(trip),
            "message": (
                f"Resolved trip '{trip_id}' from CityRide state. The in-app "
                "detail button was not reachable in the current Activity UI."
            ),
        }
    return last or f"No trip detail button found for '{trip_id}'."


@mcp.tool()
def filter_activity(filter_type: str) -> str:
    """Open the activity filter menu and tap a filter option.

    Args:
        filter_type: Filter slug. The Activity filter menu exposes exactly
            ``all``, ``completed`` (past), and ``canceled``. Common spellings
            map onto these: ``past``/``history`` -> ``completed``,
            ``cancelled`` -> ``canceled``. ``upcoming``/``scheduled`` have no
            dedicated option in this build and return a bounded message.
    """
    sim = SimulatorBridge.get()
    raw = (filter_type or "").strip().lower()
    # Map blind spellings onto the THREE real option keys.
    key_map = {
        "all": "all", "any": "all",
        "completed": "completed", "past": "completed", "history": "completed",
        "complete": "completed", "done": "completed",
        "canceled": "canceled", "cancelled": "canceled", "cancel": "canceled",
    }
    target = key_map.get(raw)
    if target is None:
        if raw in {"upcoming", "scheduled", "future", "reserved"}:
            return (
                f"Cannot apply activity filter '{filter_type}': this build has no "
                f"'{filter_type}' option "
                "(only all / completed / canceled). Use list_upcoming_trips() "
                "to see reserved/scheduled trips instead."
            )
        return (
            f"Unknown activity filter '{filter_type}'. Valid: all, completed "
            "(a.k.a. past), canceled."
        )
    # Ensure the Activity tab is visible.
    if "activity_filter_button" not in (sim.observe_text() or ""):
        _dismiss_overlays(sim)
        try:
            sim.tap_xy(*TAB_COORDS["activity"]); sim.wait(0.5)
        except Exception:
            pass
    # Open the filter control (a SwiftUI Menu), then tap the resolved option.
    try:
        sim.tap_id("activity_filter_button"); sim.wait(1.0)
    except Exception as exc:
        return (
            f"Could not open the activity filter. Make sure the Activity tab is "
            f"visible (call view_trip_history first). Error: {str(exc)[:120]}"
        )
    opt = f"activity_filter_option_{target}"
    try:
        sim.tap_id(opt); sim.wait(0.5)
        return f"Filtered activity by '{filter_type}' (option '{target}')."
    except Exception as exc:
        return (
            f"Could not apply activity filter '{filter_type}'. Tried {opt}. "
            f"Error: {str(exc)[:120]}"
        )


@mcp.tool()
def open_where_to():
    """Open the Where-to? sheet from the home screen (no fields filled)."""
    sim = SimulatorBridge.get()
    if not _open_where_to_sheet(sim):
        return {
            "ok": False,
            "action": "open_where_to",
            "message": "Could not open the ride request sheet from the home screen.",
        }
    tree = sim.observe_text() or ""
    if "request_destination_chip_button" not in tree:
        return {
            "ok": False,
            "action": "open_where_to",
            "message": "Tapped Where to? but the request sheet did not render.",
        }
    return {"ok": True, "action": "open_where_to", "message": "Opened 'where to?' sheet."}


@mcp.tool()
def set_destination(address: str) -> str:
    """Open the Where-to? sheet and type a destination into the destination chip.

    Args:
        address: Free-text destination (street address, landmark name, or
            saved-place display name like ``"Home"`` / ``"Work"``). Must be
            non-empty. Does not auto-select a suggestion — call ``observe()``
            and tap a row, or use ``request_ride`` instead.
    """
    sim = SimulatorBridge.get()
    address = (address or "").strip()
    if not address:
        return "Could not set destination: address must be non-empty."
    if not _open_where_to_sheet(sim):
        return "Could not open the ride request modal from the Home screen."
    # The request modal's destination chip is `request_destination_chip_button`.
    # Clear it first — it arrives pre-filled with the top recent place, so a
    # bare type_text would append onto the seed value.
    try:
        sim.tap_id("request_destination_chip_button"); sim.wait(0.3)
        _clear_field(sim, "request_destination_chip_button")
        sim.type_text(address); sim.wait(0.6)
    except Exception as exc:
        return f"Could not set destination '{address}': {str(exc)[:120]}"
    landed = (address in (sim.observe_text() or "")) if address else True
    if not landed:
        return (
            f"Could not set destination '{address}': the destination chip did not register it. "
            "Call observe() to inspect the request modal."
        )
    return f"Set destination '{address}'."


@mcp.tool()
def set_pickup(address: str) -> str:
    """Set the pickup chip on the request sheet and return to ride options.

    Args:
        address: Free-text pickup address. Valid: street addresses (e.g.
            ``"410 Brannan St"``), saved-place display names (``"Home"``,
            ``"Work"``), or landmarks. Must be non-empty.

    Auto-opens the Where-to? sheet first. Taps the matching pickup search
    result/current-location row, then verifies the confirmable ride-options
    sheet is visible so ``select_ride_type(...)`` can be called next.
    """
    sim = SimulatorBridge.get()
    address = (address or "").strip()
    if not address:
        return {
            "ok": False,
            "action": "set_pickup",
            "message": "Could not set pickup: address must be non-empty.",
        }
    if not _open_where_to_sheet(sim):
        return "Could not open the ride request modal from the Home screen."
    canonical = _resolve_destination_name(address) or address
    ok = _select_pickup_in_sheet(sim, canonical)
    if not ok and canonical != address:
        ok = _select_pickup_in_sheet(sim, address)
    if not ok:
        return {
            "ok": False,
            "action": "set_pickup",
            "message": (
                f"Could not set pickup to '{address}': no matching pickup result "
                "returned to the ride-options sheet. Call observe() to inspect."
            ),
        }
    ride_options = _parse_ride_options(sim.observe_text() or "")
    return {
        "ok": True,
        "action": "set_pickup",
        "pickup": canonical,
        "ride_options": ride_options,
        "message": f"Set pickup to '{canonical}'. Select a ride type next.",
    }


def _open_plan_ride_sheet(sim: SimulatorBridge) -> bool:
    """Open the Plan-a-ride (PlanRideView) sheet from the Home screen.

    The add-stop control (``plan_ride_add_stop``) lives only in PlanRideView,
    which is presented via ``showPlanRide`` — triggered either by the
    ``quick_action_schedule_ride`` ("Later") button in the home search bar or
    by the ``suggested_destination_row_reserve`` ("Reserve") suggestion tile.
    Returns True once a PlanRideView marker is visible.
    """
    def plan_open() -> bool:
        t = sim.observe_text() or ""
        return any(m in t for m in ("plan_ride_add_stop", "plan_ride_destination_field",
                                    "plan_ride_pickup_current_location"))
    if plan_open():
        return True
    # A *different* sheet (ride-request / rating) may be covering the Home
    # search bar, so the plan-ride entry buttons would tap onto it and no-op.
    # Dismiss any non-plan overlay first. (_dismiss_overlays leaves nothing
    # open; plan-ride itself was handled by the early return above.)
    _dismiss_overlays(sim)
    # Ensure Home is active.
    try:
        sim.tap_xy(*TAB_COORDS["home"]); sim.wait(0.4)
    except Exception:
        pass
    for entry in ("quick_action_schedule_ride", "suggested_destination_row_reserve"):
        try:
            sim.tap_id(entry); sim.wait(0.8)
            if plan_open():
                return True
        except Exception:
            continue
    return plan_open()


@mcp.tool()
def add_stop() -> dict:
    """Add an intermediate stop to the ride being planned.

    Navigates to the Plan-a-ride sheet (PlanRideView) — which is where the
    ``plan_ride_add_stop`` control lives — then taps it to reveal the
    intermediate-stop input row (``plan_ride_stop_field``).

    Returns ``{ok: True, action, message}`` once the stop input row is
    visible, or a controlled-failure ``{ok: False, ...}`` if the plan-ride
    sheet cannot be reached or the stop row does not appear.
    """
    sim = SimulatorBridge.get()
    if not _open_plan_ride_sheet(sim):
        return {
            "ok": False,
            "action": "add_stop",
            "message": (
                "Could not open the Plan-a-ride sheet from the Home screen "
                "(tried quick_action_schedule_ride and suggested_destination_row_reserve)."
            ),
        }
    # The add-stop control becomes .disabled once a stop row already exists
    # (showStopField == true). If the stop field is already showing, the stop
    # has effectively been added.
    before = sim.observe_text() or ""
    if "plan_ride_stop_field" in before:
        return {
            "ok": True,
            "action": "add_stop",
            "message": "Added stop (intermediate-stop field is already present).",
        }
    try:
        sim.tap_id("plan_ride_add_stop"); sim.wait(0.5)
    except Exception as exc:
        return {
            "ok": False,
            "action": "add_stop",
            "message": f"Could not tap plan_ride_add_stop: {str(exc)[:120]}",
        }
    after = sim.observe_text() or ""
    if "plan_ride_stop_field" not in after:
        return {
            "ok": False,
            "action": "add_stop",
            "message": (
                "Tapped plan_ride_add_stop but the intermediate-stop field did "
                "not appear. Call observe() to inspect the Plan-a-ride sheet."
            ),
        }
    return {
        "ok": True,
        "action": "add_stop",
        "message": "Added stop. An intermediate-stop input row (plan_ride_stop_field) is now visible.",
    }


@mcp.tool()
def open_saved_places() -> str:
    """Open the saved-places management list.

    The Home screen only shows a non-interactive ``home_saved_places_title``
    label with a few inline rows; the real saved-places list (Home, Work,
    Airport, Gym, ... each opening an "Edit Saved Place" sheet) lives in the
    Account tab's "Saved places" section. Navigate there and confirm the
    section rendered.
    """
    sim = SimulatorBridge.get()
    # The saved-places management section is on the Account tab.
    _dismiss_overlays(sim)
    try:
        sim.tap_xy(*TAB_COORDS["account"]); sim.wait(0.6)
    except Exception:
        pass
    tree = sim.observe_text() or ""
    if "account_saved_place_row_" not in tree:
        # Fallback: try tab id, then a second settle.
        for aid in ("tab_account", "Account"):
            try:
                sim.tap_id(aid); sim.wait(0.6); break
            except Exception:
                continue
        tree = sim.observe_text() or ""
    if "account_saved_place_row_" not in tree:
        return (
            "Could not open the saved-places list. Expected the Account tab's "
            "'Saved places' section (account_saved_place_row_*) to be visible."
        )
    rows = sorted(set(re.findall(r'account_saved_place_row_([^"\s]+)', tree)))
    return f"Opened saved places ({len(rows)} places: {', '.join(rows[:8])})."


@mcp.tool()
def recenter_map() -> dict:
    """Recenter the home-screen map on the current location.

    Ensures the Home tab is active (the recenter control lives in the Home
    map overlay), then taps ``map_recenter_button``. Recentering is a
    view-only action with no persistent state change, so success is defined
    as the button being found and tapped.

    Returns ``{ok: True, action, message}`` after a verified tap, or a
    controlled-failure ``{ok: False, ...}`` if the button is not present.
    """
    sim = SimulatorBridge.get()
    # The recenter button lives on the Home map overlay. Dismiss any covering
    # sheet, then make Home active.
    _dismiss_overlays(sim)
    try:
        sim.tap_xy(*TAB_COORDS["home"]); sim.wait(0.4)
    except Exception:
        pass
    tree = sim.observe_text() or ""
    if "map_recenter_button" not in tree:
        return {
            "ok": False,
            "action": "recenter_map",
            "message": (
                "map_recenter_button is not visible on the Home screen. "
                "Make sure the Home tab is active (call navigate_to_tab('home'))."
            ),
        }
    try:
        sim.tap_id("map_recenter_button"); sim.wait(0.3)
    except Exception as exc:
        return {
            "ok": False,
            "action": "recenter_map",
            "message": f"Could not tap map_recenter_button: {str(exc)[:120]}",
        }
    return {
        "ok": True,
        "action": "recenter_map",
        "message": "Recentered the map on the current location.",
    }


@mcp.tool()
def open_payment_selector() -> str:
    """Open the payment-method selector / payment-methods list.

    Self-navigates so it works from a fresh launch: if a ride-request sheet is
    already open it taps that sheet's ``payment_method_selector``; otherwise it
    switches to the Wallet tab, which is the dedicated payment-methods screen
    (``wallet_payment_method_row_*``). Returns a bounded error only if neither
    surface can be reached.
    """
    sim = SimulatorBridge.get()
    # If a request sheet (or any screen) already exposes the inline selector,
    # tap it — that opens the payment chooser in-context.
    tree = sim.observe_text() or ""
    if "payment_method_selector" in tree:
        try:
            sim.tap_id("payment_method_selector"); sim.wait(0.7)
            after = sim.observe_text() or ""
            # The in-context chooser surfaces selectable payment options
            # (Apple Pay logo / card "banknote" glyphs / a "checkmark" on the
            # active method, or explicit payment-option rows). Only claim
            # success when one of those actually rendered.
            if any(m in after for m in (
                "apple.logo", "banknote", "checkmark",
                "payment_option_", "payment_method_option_",
            )):
                return "Opened payment selector (ride-request sheet)."
            # No distinct chooser appeared — fall through to the Wallet list.
        except Exception:
            pass
    # Otherwise go to the Wallet tab, the dedicated payment-methods list.
    # Dismiss any non-request sheet (plan-ride/rating) that would cover the tab.
    _dismiss_overlays(sim)
    try:
        sim.tap_xy(*TAB_COORDS["wallet"]); sim.wait(0.6)
    except Exception:
        pass
    tree = sim.observe_text() or ""
    if "wallet_payment_method_row_" not in tree:
        for aid in ("tab_wallet", "Wallet"):
            try:
                sim.tap_id(aid); sim.wait(0.6); break
            except Exception:
                continue
        tree = sim.observe_text() or ""
    if "wallet_payment_method_row_" in tree:
        rows = sorted(set(re.findall(r'wallet_payment_method_row_([^"\s]+)', tree)))
        return (f"Opened payment methods on the Wallet tab "
                f"({len(rows)} methods: {', '.join(rows[:6])}).")
    return (
        "Could not open the payment selector. Expected the ride-request sheet's "
        "payment_method_selector or the Wallet tab's payment methods."
    )


if __name__ == "__main__":
    mcp.run()
