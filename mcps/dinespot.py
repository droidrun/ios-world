"""DineSpot MCP — OpenTable-style restaurant discovery & reservation booking.

Bundle: com.iosworld.benchmark.dinespot

ID conventions:
  Tabs (by label):    Home, Search, Rewards, Reservations, Updates
  Restaurant rows:    restaurant_row_<slug>   (slug = lowercased name w/ underscores)
  Booking review:     booking_review_restaurant, booking_review_date,
                      booking_review_time, booking_review_party
  Reservation slots:  reservation_slot_<slug>
  Confirm:            reservation_confirm_button
  Featured filters:   featured_collection_<outdoor|romantic|italian|brunch|bar>
  Party size:         party_size_option_<n>
  City picker:        city_picker_option_<city>
"""

import re
import sys, pathlib
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts

mcp = FastMCP("DineSpot")

BUNDLE_ID = "com.iosworld.benchmark.dinespot"

TAB_MAP = {
    "home":         ["tab_home", "Home"],
    "search":       ["tab_search", "Search"],
    "rewards":      ["tab_rewards", "Rewards"],
    "reservations": ["tab_reservations", "Reservations"],
    "updates":      ["tab_updates", "Updates"],
}

# Seeded cities. The city picker is a SwiftUI Menu (label id
# ``search_location_field``) on the Discover/Search tab; tapping it surfaces
# ``city_picker_option_<city.id>`` buttons where the id is ``city_<slug>``
# (e.g. ``city_san_francisco``), NOT the bare display name.
_CITY_IDS = (
    "city_new_york", "city_san_francisco", "city_los_angeles",
    "city_chicago", "city_boston", "city_seattle", "city_catalina",
)


# Seed restaurant id -> display name (mirrors Resources/SeedData.swift). Used to
# resolve a blind display NAME ("Golden Gate Izakaya") to its underlying id, and
# to know the searchable name for an id that is off the current screen. Keep in
# sync with SeedData.swift.
_RESTAURANT_NAMES = {
    "restaurant_001": "Le Jardin Moderne",
    "restaurant_002": "Hudson Grill House",
    "restaurant_003": "Cedar & Smoke",
    "restaurant_004": "Golden Gate Izakaya",
    "restaurant_005": "Harborline Seafood",
    "restaurant_006": "Fiore Trattoria",
    "restaurant_sf_mission_block": "Mission Block",
    "restaurant_sf_marina_oyster": "Marina Oyster Club",
    "restaurant_sf_hayes_bistro": "Hayes Valley Bistro",
    "restaurant_sf_soma_rooftop": "SoMa Rooftop",
    "restaurant_sf_embarcadero_grill": "Embarcadero Grill",
    "restaurant_007": "Pacifica Terrace",
    "restaurant_008": "Nori Counter LA",
    "restaurant_009": "Olvera Social Club",
    "restaurant_010": "Lakefront Room",
    "restaurant_011": "Fulton Tasting Table",
    "restaurant_012": "Wicker Park Bistro",
    "restaurant_013": "Commonwealth Steakhouse",
    "restaurant_014": "North End Osteria",
    "restaurant_015": "Seaport Raw Bar",
    "restaurant_016": "Rain City Izakaya",
    "restaurant_017": "Ballard Hearth",
    "restaurant_018": "Belltown Tapas Room",
    "restaurant_019": "Greenwich Omakase Loft",
    "restaurant_020": "Mercer Pasta Lab",
    "restaurant_021": "Ferry House Grill",
    "restaurant_022": "Presidio Hearth",
    "restaurant_023": "Echo Park Supper Club",
    "restaurant_024": "Melrose Raw Counter",
    "restaurant_025": "Canal Street Oyster Hall",
    "restaurant_026": "Fulton Ember Room",
    "restaurant_027": "Beacon Cellar Dining",
    "restaurant_028": "Seaport Kaisen House",
    "restaurant_029": "Harborline Chophouse",
    "restaurant_030": "Capitol Hill Noodle Atelier",
    "restaurant_031": "Avalon Catch House",
    "restaurant_032": "Catalina Cantina",
    "restaurant_033": "Harbor Reef Grill",
    "restaurant_tr_tartine": "Tartine Manufactory",
    "restaurant_tr_la_taqueria": "La Taqueria",
    "restaurant_tr_el_farolito": "El Farolito",
    "restaurant_tr_rich_table": "Rich Table",
    "restaurant_tr_souvla": "Souvla",
    "restaurant_tr_mama": "Mama",
    "restaurant_tr_sightglass": "Sightglass Coffee",
    "restaurant_tr_zy": "Z & Y Restaurant",
    "restaurant_tr_nopalito": "Nopalito",
    "restaurant_tr_mister_jius": "Mister Jiu's",
    "restaurant_tr_san_tung": "San Tung",
    "restaurant_tr_nari": "Nari",
    "restaurant_tr_burma_superstar": "Burma Superstar",
    "restaurant_tr_hog_island": "Hog Island Oyster Co.",
    "restaurant_tr_flour_water": "Flour + Water",
    "restaurant_tr_kin_khao": "Kin Khao",
    "restaurant_tr_delfina": "Delfina",
    "restaurant_tr_che_fico": "Che Fico",
    "restaurant_tr_lazy_bear": "Lazy Bear",
    "restaurant_tr_zuni_cafe": "Zuni Cafe",
    "restaurant_tr_state_bird": "State Bird Provisions",
    "restaurant_tr_swan_oyster": "Swan Oyster Depot",
    "restaurant_tr_dumpling_home": "Dumpling Home",
    "restaurant_tr_marufuku": "Marufuku Ramen",
    "restaurant_tr_tonys": "Tony's Pizza Napoletana",
    "restaurant_tr_carbone": "Carbone",
    "restaurant_tr_katzs": "Katz's Delicatessen",
    "restaurant_tr_lilia": "Lilia",
    "restaurant_tr_don_angie": "Don Angie",
    "restaurant_tr_via_carota": "Via Carota",
    "restaurant_tr_los_tacos": "Los Tacos No. 1",
    "restaurant_tr_holbox": "Holbox",
    "restaurant_tr_bestia": "Bestia",
    "restaurant_tr_avalon_seafood": "Avalon Seafood & Fish Market",
    "restaurant_tr_descanso": "Descanso Beach Club",
    "restaurant_tr_harbor_reef": "Harbor Reef Restaurant",
}


# Restaurant id -> seeded city id. The Discover/Search results are scoped to the
# currently-selected city, so to surface an off-screen restaurant by search we
# must first switch to its city. Mirrors SeedData.swift cityID fields.
_RESTAURANT_CITY = {
    "restaurant_001": "city_new_york", "restaurant_002": "city_new_york",
    "restaurant_003": "city_new_york", "restaurant_004": "city_san_francisco",
    "restaurant_005": "city_san_francisco", "restaurant_006": "city_san_francisco",
    "restaurant_sf_mission_block": "city_san_francisco",
    "restaurant_sf_marina_oyster": "city_san_francisco",
    "restaurant_sf_hayes_bistro": "city_san_francisco",
    "restaurant_sf_soma_rooftop": "city_san_francisco",
    "restaurant_sf_embarcadero_grill": "city_san_francisco",
    "restaurant_007": "city_los_angeles", "restaurant_008": "city_los_angeles",
    "restaurant_009": "city_los_angeles", "restaurant_010": "city_chicago",
    "restaurant_011": "city_chicago", "restaurant_012": "city_chicago",
    "restaurant_013": "city_boston", "restaurant_014": "city_boston",
    "restaurant_015": "city_boston", "restaurant_016": "city_seattle",
    "restaurant_017": "city_seattle", "restaurant_018": "city_seattle",
    "restaurant_019": "city_new_york", "restaurant_020": "city_new_york",
    "restaurant_021": "city_san_francisco", "restaurant_022": "city_san_francisco",
    "restaurant_023": "city_los_angeles", "restaurant_024": "city_los_angeles",
    "restaurant_025": "city_chicago", "restaurant_026": "city_chicago",
    "restaurant_027": "city_boston", "restaurant_028": "city_boston",
    "restaurant_029": "city_seattle", "restaurant_030": "city_seattle",
    "restaurant_031": "city_catalina", "restaurant_032": "city_catalina",
    "restaurant_033": "city_catalina",
    "restaurant_tr_tartine": "city_san_francisco",
    "restaurant_tr_la_taqueria": "city_san_francisco",
    "restaurant_tr_el_farolito": "city_san_francisco",
    "restaurant_tr_rich_table": "city_san_francisco",
    "restaurant_tr_souvla": "city_san_francisco",
    "restaurant_tr_mama": "city_san_francisco",
    "restaurant_tr_sightglass": "city_san_francisco",
    "restaurant_tr_zy": "city_san_francisco",
    "restaurant_tr_nopalito": "city_san_francisco",
    "restaurant_tr_mister_jius": "city_san_francisco",
    "restaurant_tr_san_tung": "city_san_francisco",
    "restaurant_tr_nari": "city_san_francisco",
    "restaurant_tr_burma_superstar": "city_san_francisco",
    "restaurant_tr_hog_island": "city_san_francisco",
    "restaurant_tr_flour_water": "city_san_francisco",
    "restaurant_tr_kin_khao": "city_san_francisco",
    "restaurant_tr_delfina": "city_san_francisco",
    "restaurant_tr_che_fico": "city_san_francisco",
    "restaurant_tr_lazy_bear": "city_san_francisco",
    "restaurant_tr_zuni_cafe": "city_san_francisco",
    "restaurant_tr_state_bird": "city_san_francisco",
    "restaurant_tr_swan_oyster": "city_san_francisco",
    "restaurant_tr_dumpling_home": "city_san_francisco",
    "restaurant_tr_marufuku": "city_san_francisco",
    "restaurant_tr_tonys": "city_san_francisco",
    "restaurant_tr_carbone": "city_new_york",
    "restaurant_tr_katzs": "city_new_york",
    "restaurant_tr_lilia": "city_new_york",
    "restaurant_tr_don_angie": "city_new_york",
    "restaurant_tr_via_carota": "city_new_york",
    "restaurant_tr_los_tacos": "city_new_york",
    "restaurant_tr_holbox": "city_los_angeles",
    "restaurant_tr_bestia": "city_los_angeles",
    "restaurant_tr_avalon_seafood": "city_catalina",
    "restaurant_tr_descanso": "city_catalina",
    "restaurant_tr_harbor_reef": "city_catalina",
}


def _norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def _resolve_restaurant(query: str) -> Optional[tuple]:
    """Resolve a blind id-or-name query to ``(restaurant_id, display_name)``.

    Accepts the full id (``restaurant_004``), the bare suffix (``004`` ->
    ``restaurant_004``, ``tr_lilia`` -> ``restaurant_tr_lilia``), or a display
    NAME (exact, case-insensitive, or substring/fuzzy). Returns None if nothing
    in the seed catalogue matches.
    """
    raw = (query or "").strip()
    if not raw:
        return None
    # 1) Direct id forms.
    if raw in _RESTAURANT_NAMES:
        return raw, _RESTAURANT_NAMES[raw]
    cand = raw if raw.startswith("restaurant_") else "restaurant_" + raw.lstrip("_")
    if cand in _RESTAURANT_NAMES:
        return cand, _RESTAURANT_NAMES[cand]
    # 2) Name match (exact normalised, then substring both directions).
    nq = _norm(raw)
    if not nq:
        return None
    for rid, nm in _RESTAURANT_NAMES.items():
        if _norm(nm) == nq:
            return rid, nm
    matches = [
        (rid, nm) for rid, nm in _RESTAURANT_NAMES.items()
        if nq in _norm(nm) or _norm(nm) in nq
    ]
    if len(matches) >= 1:
        # Prefer the shortest name (tightest match) for determinism.
        matches.sort(key=lambda kv: len(kv[1]))
        return matches[0]
    return None


def _type_in_discover_search(sim, text: str) -> bool:
    """Type ``text`` into the Discover/Search query field.

    The SwiftUI TextField's own ``search_query_field`` id is shadowed at runtime
    by the parent ``discover_screen`` id, so it is NOT reachable by accessibility
    id. We instead locate the concrete XCUIElementTypeTextField, clear it, and
    send keys directly. Returns True if a field was found and typed into.
    """
    try:
        fields = sim.driver.find_elements("class name", "XCUIElementTypeTextField")
    except Exception:
        fields = []
    if not fields:
        return False
    el = fields[0]
    try:
        el.click(); sim.wait(0.3)
        try:
            el.clear()
        except Exception:
            pass
        el.send_keys(text); sim.wait(0.7)
        return True
    except Exception:
        return False


def _select_city_id(sim, city_id: str) -> bool:
    """Switch the Discover/Search city to ``city_id`` via the location Menu.

    Precondition: the Discover/Search screen is showing. Opens the location
    Menu (``search_location_field`` / the "location" image button) and taps
    ``city_picker_option_<city_id>``. Returns True if the option was tapped.
    """
    tree = sim.observe_text() or ""
    if f"city_picker_option_{city_id}" not in tree:
        opened = False
        for aid in ("search_location_field", "location"):
            try:
                sim.tap_id(aid); sim.wait(0.5); opened = True; break
            except Exception:
                continue
        if not opened:
            return False
    try:
        sim.tap_id(f"city_picker_option_{city_id}"); sim.wait(0.6)
        return True
    except Exception:
        return False


def _city_to_id(city: str) -> Optional[str]:
    """Resolve a free-text city name to a seeded ``city_<slug>`` id.

    Accepts the display name (``San Francisco``), the slug (``san_francisco``),
    or the full id (``city_san_francisco``); case/punctuation insensitive.
    Returns None if no seeded city matches.
    """
    raw = (city or "").strip().lower()
    slug = re.sub(r"[^a-z0-9]+", "_", raw).strip("_")
    if not slug:
        return None
    for cid in _CITY_IDS:
        bare = cid[len("city_"):]
        if slug == cid or slug == bare or f"city_{slug}" == cid:
            return cid
    return None


def _open_discover(sim) -> bool:
    """Surface the Discover screen (search bar + party-size + city picker).

    The home screen is a single tab (``tab_home``); the Discover view that
    carries ``search_location_field`` / ``search_party_size_button`` is reached
    via the home context pills (``home_context_nearby_button``), NOT a bottom
    Search tab. Returns True if the Discover search controls are now visible.
    """
    # The Discover screen is identified at runtime by discover_screen /
    # search_party_size_button (search_location_field is NOT surfaced; the city
    # menu shows up as an Image/Button named "location").
    def _on_discover() -> bool:
        t = sim.observe_text() or ""
        return ("discover_screen" in t or "search_party_size_button" in t
                or "discover_bottom_sheet" in t)

    if _on_discover():
        return True
    # The Discover screen IS the Search tab at runtime (it renders
    # ``discover_screen`` / ``search_party_size_button``). The home context
    # pills the older code reached for (``home_context_nearby_button``) do not
    # exist in this build, so go straight to the Search tab — dismissing any
    # covering keyboard and backing out of a pushed detail first so the tap
    # lands. This is what makes set_city / set_party_size recover from the
    # after-search and after-detail messy states.
    for _ in range(3):
        _dismiss_overlays(sim)
        # If a restaurant detail is pushed on the Search tab, pop it so the
        # discover root (with the city/party controls) is showing.
        tree = sim.observe_text() or ""
        if "restaurant_detail_screen_" in tree:
            for aid in ("Back", "chevron.left"):
                try:
                    sim.tap_id(aid); sim.wait(0.5); break
                except Exception:
                    continue
        if _goto_tab(sim, "search"):
            if _on_discover():
                return True
        sim.wait(0.4)
    return _on_discover()


# Per-tab screen markers that ACTUALLY render at runtime (confirmed via live
# observe). Used to VERIFY a tab switch really happened — never trust the tap.
_TAB_SCREEN_MARKER = {
    "home":         ("home_action_book", "home_recent_row_", "home_quick_actions_label"),
    "search":       ("discover_screen", "search_party_size_button"),
    "rewards":      ("rewards_screen", "rewards_points_header", "rewards_progress_title"),
    "reservations": ("reservations_screen", "reservation_card_"),
    "updates":      ("updates_screen", "updates_alert_row_", "updates_help_center_row"),
}


def _keyboard_up(sim) -> bool:
    """True if the soft keyboard is currently shown (it covers the bottom tab
    bar, so a tab tap would land on a key instead of the tab)."""
    return "XCUIElementTypeKeyboard" in (sim.observe_text() or "")


def _dismiss_overlays(sim) -> None:
    """Best-effort dismiss of anything covering the bottom tab bar.

    The Discover/Search screen keeps its TextField focused after a search, so
    the soft keyboard stays up and intercepts taps aimed at the bottom tabs
    (this is the real "button present but covered" failure that made
    navigate_to_tab / view_reservations / view_rewards silently no-op). We
    dismiss the keyboard by submitting a newline (the search field's onSubmit),
    then fall back to a couple of known dismiss affordances.
    """
    if _keyboard_up(sim):
        for _ in range(2):
            try:
                sim.type_text("\n"); sim.wait(0.35)
            except Exception:
                break
            if not _keyboard_up(sim):
                break
    # Some detail/search overlays expose an explicit dismiss control.
    if _keyboard_up(sim):
        for aid in ("search_cancel_button", "Cancel", "Return", "Done"):
            try:
                sim.tap_id(aid); sim.wait(0.3)
            except Exception:
                continue
            if not _keyboard_up(sim):
                break


def _dismiss_preference_dialog(sim) -> None:
    """Close an open seating-preference confirmationDialog if one is showing.

    ``set_booking_preference`` opens a SwiftUI ``.confirmationDialog`` whose
    option buttons (``No preference`` / ``Patio seating`` / ``Bar seating``)
    float over the booking-review sheet and cover the
    ``reservation_confirm_button`` at the bottom. A blind confirm tap then lands
    on the dialog instead of committing the booking (bug class: covered/no-op
    tap). We close it by selecting a concrete option (defaulting to the
    benign ``No preference``), falling back to Cancel.
    """
    tree = sim.observe_text() or ""
    dialog_open = (
        "Dining Preference" in tree
        and any(o in tree for o in ("Patio seating", "Bar seating"))
    )
    if not dialog_open:
        return
    for aid in ("No preference", "Cancel"):
        try:
            sim.tap_id(aid); sim.wait(0.4)
        except Exception:
            continue
        if "Patio seating" not in (sim.observe_text() or ""):
            return


def _on_tab(sim, tab: str) -> bool:
    """True if one of *tab*'s real screen markers is in the current tree."""
    tree = sim.observe_text() or ""
    return any(m in tree for m in _TAB_SCREEN_MARKER.get(tab, ()))


def _goto_tab(sim, tab: str) -> bool:
    """Switch to bottom-bar *tab* and VERIFY the switch via a real screen
    marker, dismissing any covering overlay first. Returns True only when the
    target screen actually rendered — never a blind tap-succeeded.

    Defends bug classes (2) covered/no-op tap and (4) false ok: we dismiss the
    keyboard that covers the tab bar, then confirm against a marker that the
    build actually emits (``reservations_screen`` etc.), retrying.
    """
    candidates = TAB_MAP.get(tab, [tab])
    if _on_tab(sim, tab):
        return True
    for attempt in range(3):
        _dismiss_overlays(sim)
        for aid in candidates:
            try:
                sim.tap_id(aid); sim.wait(0.5)
            except Exception:
                continue
            if _on_tab(sim, tab):
                return True
        # Tab tap may have been swallowed; dismiss again and retry.
        sim.wait(0.3)
    # Some full-screen sheets/review flows keep intercepting the tab bar even
    # after keyboard dismissal. Relaunch is non-destructive for persisted
    # reservations and lands back on the rooted TabView.
    try:
        sim.launch_and_observe(BUNDLE_ID); sim.wait(0.6)
    except Exception:
        pass
    for aid in candidates:
        try:
            sim.tap_id(aid); sim.wait(0.5)
        except Exception:
            continue
        if _on_tab(sim, tab):
            return True
    return _on_tab(sim, tab)


def _dinespot_foreground(sim) -> bool:
    """True if DineSpot is actually the foreground app (not Clock/Calculator
    left over from the first-connect warm-up prime)."""
    t = sim.observe_text() or ""
    return (
        'bundleId="' + BUNDLE_ID + '"' in t
        or 'name="DineSpot"' in t
        or "home_screen" in t
        or "discover_screen" in t
    )


_PRIME_BUNDLE = "com.iosworld.benchmark.clock"


def _ensure_dinespot_foreground(sim, attempts: int = 12) -> bool:
    """Make sure DineSpot is foreground and HOLDS there, relaunching if a
    warm-up prime (Clock) or a backgrounding left another app on top.

    The SimulatorBridge primes the Clock app on its FIRST connect of a process;
    WDA processes that ``launchApp`` asynchronously and it can foreground Clock
    a beat after our DineSpot launch and stick. We converge by: observe →
    if DineSpot, require it to hold for TWO consecutive observes → else
    terminate the prime app and relaunch DineSpot. This reliably lands on
    DineSpot within a couple of iterations (bug class: covered/wrong screen)."""
    held = 0
    for _ in range(max(2, attempts)):
        if _dinespot_foreground(sim):
            held += 1
            if held >= 2:
                return True
            sim.wait(0.8)
            continue
        held = 0
        try:
            sim.terminate_app(_PRIME_BUNDLE)
        except Exception:
            pass
        try:
            sim.launch_app(BUNDLE_ID)
        except Exception:
            pass
        sim.wait(1.2)
    return _dinespot_foreground(sim)


@mcp.tool()
def launch() -> str:
    """Launch DineSpot and return the initial UI tree."""
    sim = SimulatorBridge.get()
    # SUPPRESS the bridge's first-connect warm-up prime. The prime foregrounds
    # the Clock app via an asynchronously-queued ``mobile: launchApp`` that WDA
    # can execute SECONDS later — after launch_and_observe (and any verify loop)
    # already left DineSpot foreground — leaving Clock stuck on top so the
    # agent's very first tool call lands on the wrong app. We mark the session
    # as already-primed BEFORE the first connect so the Clock launch never
    # fires; launch_and_observe still handles any first-observe SpringBoard
    # timeout via its own reconnect path, so the warm-up isn't actually needed.
    if not getattr(sim, "_has_primed", True):
        try:
            sim._has_primed = True
        except Exception:
            pass
    ui = sim.launch_and_observe(BUNDLE_ID)
    # Converge to DineSpot foreground: the async warm-up prime can still leave
    # Clock on top after launch_and_observe returns, so terminate the prime app
    # and relaunch DineSpot until it holds (see _ensure_dinespot_foreground).
    if not _ensure_dinespot_foreground(sim):
        ui = sim.observe_text() or ui
    else:
        ui = sim.observe_text() or ui
    return f"Launched DineSpot.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (no taps)."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="DineSpot",
        markers=("restaurant_row_", "dinespot_", "reservation_", "tab_reservations"),
    )


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch to a bottom-bar tab. Works from any screen — self-recovers by
    dismissing a covering keyboard/overlay first, then VERIFIES the target
    screen actually rendered (never a blind tap-succeeded).

    Args:
        tab_name: One of ``home``, ``search``, ``rewards``,
            ``reservations``, ``updates`` (case-insensitive). Note ``search``
            lands on the Discover screen (search field + city/party pickers).
            Any other value returns an error string listing valid tabs.

    Returns an error string (not an exception) if the tab screen could not be
    rendered after retries, so the agent can dismiss sheets and retry.
    """
    tab = tab_name.lower()
    candidates = TAB_MAP.get(tab)
    if candidates is None:
        return f"Cannot navigate: unknown tab '{tab_name}'. Valid tabs: {', '.join(TAB_MAP.keys())}"
    sim = SimulatorBridge.get()
    # Dismiss any covering keyboard/overlay, tap the tab, and VERIFY the target
    # screen actually rendered (a search keyboard covers the tab bar, so a blind
    # tap silently no-ops and falsely reports success).
    if not _goto_tab(sim, tab):
        ui = sim.observe_text() or ""
        return (
            f"Could not navigate to '{tab_name}'. Tapped {candidates} but the "
            f"'{tab}' screen did not render (an overlay/keyboard may be "
            f"covering the tab bar). Dismiss open sheets and retry.\n\n{ui}"
        )
    ui = sim.observe_text()
    return f"Navigated to '{tab_name}' tab.\n\n{ui}"


@mcp.tool()
def search_restaurants(query: str) -> str:
    """Search restaurants by name/cuisine via the Discover/Search query field.

    Args:
        query: Free-text query. Matched against restaurant names and
            cuisines (e.g. ``sushi``, ``Golden Gate``).

    Works from any screen — self-navigates to the Discover/Search tab, popping
    any pushed restaurant detail and dismissing a covering keyboard first so the
    field focuses. The response lists the underlying restaurant ids that matched
    (e.g. ``restaurant_004``); pass any of those ids — OR the restaurant's
    display name directly — to ``view_restaurant(name=...)``. If the search
    field could not be focused, returns a controlled failure (no stale rows) so
    the agent can call ``observe()`` or ``list_visible_restaurants()`` instead.
    """
    sim = SimulatorBridge.get()
    # A pushed restaurant detail (after view_restaurant) or a covering keyboard
    # (after a prior search) leaves the discover query field UNREACHABLE: a bare
    # tab_search tap does NOT pop the detail, so the field never focuses and we
    # would otherwise return stale on-screen rows that have nothing to do with
    # `query` (bug class 2: button present but covered + bug class 1: stale tree).
    # Pop any pushed detail and dismiss overlays, then use _open_discover to land
    # on the discover root before typing.
    for _ in range(2):
        tree = sim.observe_text() or ""
        if "restaurant_detail_screen_" not in tree:
            break
        popped = False
        for aid in ("Back", "chevron.left"):
            try:
                sim.tap_id(aid); sim.wait(0.5); popped = True; break
            except Exception:
                continue
        if not popped:
            break
    _dismiss_overlays(sim)
    if not _open_discover(sim):
        # Self-navigate to the Search/Discover tab as a fallback.
        for aid in ("tab_search", "Search"):
            try:
                sim.tap_id(aid); sim.wait(0.6)
                break
            except Exception:
                continue
    typed = _type_in_discover_search(sim, query)
    ui = sim.observe_text() or ""
    restaurants = _restaurant_ids_from_text(ui)
    if not typed:
        # Honest failure — never echo stale, unrelated rows as if they were
        # matches for `query` (that is a false positive the agent acts on).
        return (
            f"Could not run the search for '{query}': the Discover search field "
            f"could not be focused (an overlay/detail may still be covering it). "
            f"Call observe() and retry, or use list_visible_restaurants()."
        )
    return f"Searched for '{query}'. Matches: {restaurants}\n\n{ui}"


@mcp.tool()
def set_party_size(size: int) -> str:
    """Set the party size for restaurant discovery via the party-size picker.

    Args:
        size: Integer number of guests, 1-8 (each maps to a
            ``party_size_option_<n>`` button). A size with no matching option
            returns a controlled failure naming the 1-8 range.

    Works from any screen — self-navigates to the Discover/Search screen (where
    the picker lives) first, dismissing a covering keyboard and popping any
    pushed detail. Taps ``search_party_size_button`` to open the
    ``party_size_option_<n>`` dialog, then selects ``size``. NOTE: this sets the
    discovery party size, not the booking-review party; it is a search filter.
    """
    sim = SimulatorBridge.get()
    if not _open_discover(sim):
        return ("Could not open the Discover screen to reach the party-size "
                "picker (home_context_nearby_button not reachable).")
    try:
        sim.tap_id("search_party_size_button"); sim.wait(0.4)
    except Exception as exc:
        return (f"Could not open the party-size picker "
                f"(search_party_size_button not reachable): {str(exc)[:120]}")
    try:
        ui = sim.tap_and_observe(f"party_size_option_{size}")
    except Exception as exc:
        return (f"Could not select party size {size}: {str(exc)[:120]}. "
                "Valid sizes are 1-8.")
    return f"Set party size to {size}.\n\n{ui}"


@mcp.tool()
def set_city(city: str) -> str:
    """Set the active city for restaurant discovery via the city picker.

    Args:
        city: City name, slug, or id (case/punctuation insensitive). The
            display name works directly — e.g. ``San Francisco``, ``New York``,
            ``los_angeles``, or ``city_san_francisco`` all resolve. Seeded
            cities: New York, San Francisco, Los Angeles, Chicago, Boston,
            Seattle, Catalina. An unrecognised city returns an error string
            listing the seeded cities.

    Works from any screen — self-navigates to the Discover/Search screen,
    opens the city Menu, and taps ``city_picker_option_<city_id>``. VERIFIES
    the switch took effect (the map recenters / city restaurants render) and
    returns a controlled failure if it cannot confirm the city changed, rather
    than reporting a blind tap as success.
    """
    sim = SimulatorBridge.get()
    city_id = _city_to_id(city)
    if city_id is None:
        return (f"Cannot set city: unknown city '{city}'. Seeded cities: "
                f"{', '.join(c[len('city_'):].replace('_', ' ') for c in _CITY_IDS)}.")
    # Surface the Discover screen (reached via the home Nearby pill) where the
    # city Menu lives.
    if not _open_discover(sim):
        return ("Could not open the Discover/Search screen to reach the city "
                "picker. Dismiss any open sheet and retry.")
    # The expected display label for the target city (used to verify the switch
    # actually took effect, not just that a tap didn't raise).
    want_label = city_id[len("city_"):].replace("_", " ").title()
    # The city Menu is the location button (its SwiftUI .accessibilityIdentifier
    # "search_location_field" is not surfaced at runtime; the live tree exposes
    # it as a Button named "location" whose label is the current city). Tapping
    # it opens the menu so the city_picker_option_* buttons render.
    last_exc: Optional[Exception] = None
    for _attempt in range(2):
        opened = False
        for aid in ("search_location_field", "location"):
            try:
                sim.tap_id(aid); sim.wait(0.5)
                opened = True
                break
            except Exception:
                continue
        if not opened:
            last_exc = RuntimeError("location menu not tappable")
            sim.wait(0.4)
            continue
        try:
            sim.tap_id(f"city_picker_option_{city_id}"); sim.wait(0.5)
            break
        except Exception as exc:
            last_exc = exc
            sim.wait(0.4)
    else:
        return (f"Could not select '{city}' ({city_id}) in the city picker: "
                f"{str(last_exc)[:120] if last_exc else 'menu not reachable'}")
    # VERIFY the city really switched — never report success on a bare tap (bug
    # class: false ok). The Discover map recenters on the selected city and
    # drops a city-center annotation (``VKPointFeature`` whose label is the
    # city name); that marker is city-specific and present regardless of any
    # active search filter, unlike the picker-menu list which always lists
    # every city. As a secondary signal, accept any of the city's seeded
    # restaurants rendering.
    sim.wait(0.4)
    ui = sim.observe_text() or ""
    center_marker = f'name="VKPointFeature" label="{want_label}"'
    city_restaurants = [
        _RESTAURANT_NAMES[rid]
        for rid, cid in _RESTAURANT_CITY.items()
        if cid == city_id and rid in _RESTAURANT_NAMES
    ]
    switched = (
        center_marker in ui
        or any(nm in ui for nm in city_restaurants)
    )
    if switched:
        return f"Set city to '{want_label}' ({city_id}).\n\n{ui}"
    return (
        f"Could not confirm the city switched to '{want_label}'; the Discover "
        f"map did not recenter on it. Call observe() and retry.\n\n{ui}"
    )


@mcp.tool()
def view_restaurant(name: str) -> str:
    """Open a restaurant's detail page (the bookable view with time slots).

    Args:
        name: A restaurant id OR its display name. The human-readable name
            works directly — e.g. ``Golden Gate Izakaya`` (exact, case-
            insensitive, or substring/fuzzy). Ids also accepted: full
            ``restaurant_004``, bare ``004``, or ``tr_*`` suffixes such as
            ``restaurant_tr_lazy_bear`` / ``tr_lazy_bear``. Get valid
            ids/names from ``list_visible_restaurants`` / ``search_restaurants``.

    Works from any screen — if the card is not visible it self-navigates to the
    Discover/Search tab (popping any pushed detail), switches to the
    restaurant's seeded city, types its name to surface the row, then opens it
    and confirms ``restaurant_detail_screen_<id>`` rendered. The trending
    ``restaurant_tr_*`` entries are map-only highlights with no openable detail;
    requesting one returns a controlled failure steering you to a bookable
    ``restaurant_001``..``restaurant_033`` instead.
    """
    sim = SimulatorBridge.get()
    # Resolve a blind id-or-NAME to the underlying ``restaurant_<...>`` id (and
    # the seed display name we can search for). Falls back to literal handling
    # for ids not in the seed catalogue.
    resolved = _resolve_restaurant(name)
    if resolved is not None:
        rid, disp_name = resolved
    else:
        rid = name.strip()
        if not rid.startswith("restaurant_"):
            rid = "restaurant_" + rid.lstrip("_")
        disp_name = None

    def _try_open() -> Optional[str]:
        tree = sim.observe_text() or ""
        candidates = [
            f"restaurant_row_{rid}",            # Search/Discover row wrapper
            f"home_dinner_row_{rid}",
            f"home_recent_row_{rid}",
            f"restaurant_row_{name.strip()}",   # legacy slug form
            rid,
        ]
        present = [c for c in candidates if f'name="{c}"' in tree]
        order = present + [c for c in candidates if c not in present]
        for cid in order:
            try:
                sim.tap_and_observe(cid); sim.wait(0.4)
                now = sim.observe_text() or ""
                if ("restaurant_detail_screen_" in now
                        or "restaurant_detail_name" in now):
                    return now
            except Exception:
                continue
        return None

    # 1) Already on screen (home carousel / current list).
    _settle_restaurant_ids(sim)
    now = _try_open()
    if now is not None:
        return f"Viewing restaurant '{name}'.\n\n{now}"

    # 2) Not visible: self-navigate to the Search/Discover tab and type the
    # restaurant's name to surface its row, then open it. The Discover results
    # are scoped to the selected city, so first switch to the restaurant's
    # seeded city (if known) before searching.
    search_term = disp_name or name.strip()
    # If a DIFFERENT restaurant's detail is currently pushed on the Search tab,
    # re-tapping the Search tab will NOT pop it (the detail stays and the search
    # field is unreachable). Pop the detail and dismiss any keyboard so the
    # discover search field is focusable. This is the after-detail recovery.
    for _ in range(2):
        tree = sim.observe_text() or ""
        if "restaurant_detail_screen_" not in tree:
            break
        popped = False
        for aid in ("Back", "chevron.left"):
            try:
                sim.tap_id(aid); sim.wait(0.5); popped = True; break
            except Exception:
                continue
        if not popped:
            break
    _dismiss_overlays(sim)
    if not _open_discover(sim):
        for aid in ("tab_search", "Search"):
            try:
                sim.tap_id(aid); sim.wait(0.6)
                break
            except Exception:
                continue
    target_city = _RESTAURANT_CITY.get(rid)
    if target_city:
        _select_city_id(sim, target_city)
    # Try the full name first, then progressively shorter tokens (handles
    # punctuation/qualifier mismatches like "Cedar & Smoke" -> "Cedar").
    terms = [search_term]
    toks = [t for t in re.split(r"[^A-Za-z0-9]+", search_term) if len(t) >= 3]
    if toks:
        terms.append(toks[0])
    for term in terms:
        if _type_in_discover_search(sim, term):
            now = _try_open()
            if now is not None:
                return f"Viewing restaurant '{name}'.\n\n{now}"
        # Clear before next attempt is handled inside _type_in_discover_search.

    # The trending/seed ``restaurant_tr_*`` entries are rendered only as
    # non-interactive map annotations in the seed data — they have no bookable
    # detail row in the discover list, so no detail page can be opened. Report
    # that honestly instead of an opaque error so the agent picks a bookable
    # restaurant (the numbered ``restaurant_001``..``restaurant_033`` rows).
    if rid.startswith("restaurant_tr_"):
        return (
            f"Cannot open '{disp_name or name}': it is only a map highlight in "
            f"this build and has no openable detail/booking page. Use "
            f"list_visible_restaurants() to pick a bookable restaurant "
            f"(e.g. restaurant_001..restaurant_033)."
        )
    return (
        f"No restaurant matching '{name}' could be opened. Use "
        f"list_visible_restaurants() or search_restaurants() to find a valid id/name."
    )


def _parse_time_to_hhmm(text: str) -> Optional[str]:
    """Normalize a human time string (e.g. ``"7:30 PM"``, ``"19:30"``,
    ``"7 PM"``) into a 24-hour ``"HHmm"`` token that matches the suffix of a
    ``reservation_slot_yyyyMMdd_HHmm`` accessibility id. Returns None when the
    input cannot be parsed as a time.
    """
    if not text:
        return None
    s = text.strip().upper()
    m = re.match(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$', s)
    if not m:
        return None
    hour = int(m.group(1))
    minute = int(m.group(2)) if m.group(2) is not None else 0
    ampm = m.group(3)
    if minute > 59:
        return None
    if ampm:
        if hour < 1 or hour > 12:
            return None
        if ampm == "AM":
            hour = 0 if hour == 12 else hour
        else:  # PM
            hour = 12 if hour == 12 else hour + 12
    else:
        if hour > 23:
            return None
    return f"{hour:02d}{minute:02d}"


def _slot_label_from_id(slot_id: str) -> str:
    """Render a human ``"H:MM AM/PM"`` label from a slot id's ``HHmm`` suffix
    (the part after the final underscore of ``yyyyMMdd_HHmm``). Falls back to
    the raw id when it does not carry a parseable time component."""
    m = re.search(r'_(\d{2})(\d{2})$', slot_id)
    if not m:
        return slot_id
    h24 = int(m.group(1))
    minute = int(m.group(2))
    suffix = "AM" if h24 < 12 else "PM"
    h12 = h24 % 12
    if h12 == 0:
        h12 = 12
    return f"{h12}:{minute:02d} {suffix}"


def _make_reservation_fill_form(time: Optional[str] = None) -> Optional[str]:
    """Open the booking review screen by tapping the Book-Table button or an
    available reservation slot.

    Shared helper used by both `make_reservation` (legacy one-shot) and
    `prepare_make_reservation` (pair-based prepare). Returns None on success
    (booking review screen is now open). Returns a precondition message on
    failure (controls not visible, e.g. user is not on a restaurant detail
    view yet).

    When ``time`` is given (e.g. ``"7:30 PM"``), only the reservation slot
    whose time matches the request is booked; if no available slot matches,
    a controlled-failure message listing the available times is returned
    instead of silently booking a different slot. When ``time`` is None the
    previous first-available behaviour is preserved.
    """
    sim = SimulatorBridge.get()
    want_hhmm = _parse_time_to_hhmm(time) if time else None
    if time and want_hhmm is None:
        return (
            f"Could not parse requested time '{time}'. Use a clock time such "
            f"as '7:30 PM' or '19:30'."
        )
    candidates = (
        "rewards_book_table_button",
        "restaurant_book_table_button",
        "Book Table",
        "Book a table",
    )
    last_exc: Optional[Exception] = None
    markers = ("booking_review_screen", "Review Booking", "booking_review_")
    on_detail = False
    seen_slot_ids: list = []
    for _ in range(5):
        tree = sim.observe_text() or ""
        if "restaurant_detail_screen_" in tree or "restaurant_detail_name" in tree:
            on_detail = True
        slot_ids = re.findall(r'reservation_slot_([^"\s]+)', tree)
        for sid in slot_ids:
            if sid not in seen_slot_ids:
                seen_slot_ids.append(sid)
        # When a specific time is requested, only tap the matching slot. A
        # requested time that is not currently visible is not necessarily
        # absent — keep scrolling to surface more slots before deciding.
        if want_hhmm is not None:
            matched = next(
                (sid for sid in slot_ids if sid.endswith("_" + want_hhmm)),
                None,
            )
            if matched is not None:
                try:
                    ui = sim.tap_and_observe(f"reservation_slot_{matched}")
                    if any(marker in ui for marker in markers):
                        return None
                    last_exc = RuntimeError(
                        f"slot '{matched}' did not open booking review"
                    )
                except Exception as exc:
                    last_exc = exc
            # No matching slot on screen yet: skip the first-available chips
            # and Book-Table button so we never book the wrong time; scroll
            # to look for more slots instead.
            if not slot_ids and "restaurant_no_availability_state" in tree:
                return (
                    "This restaurant has no bookable time slots for the "
                    "currently selected date/party size "
                    "(restaurant_no_availability_state is shown). Pick a "
                    "different restaurant, date, or party size."
                )
            try:
                sim.swipe("up")
                sim.wait(0.3)
            except Exception:
                break
            continue
        # Prefer an available reservation-slot chip first: on a restaurant
        # detail view there is no Book-Table button, and tapping a slot opens
        # the booking review screen directly.
        for slot_id in slot_ids[:4]:
            try:
                ui = sim.tap_and_observe(f"reservation_slot_{slot_id}")
                if any(marker in ui for marker in markers):
                    return None
            except Exception as exc:
                last_exc = exc
        for candidate in candidates:
            try:
                ui = sim.tap_and_observe(candidate)
                if any(marker in ui for marker in markers):
                    return None
                last_exc = RuntimeError(f"'{candidate}' did not open booking review")
            except Exception as exc:
                last_exc = exc
        # If the restaurant detail view is showing but no slots and an explicit
        # no-availability state, the date/party combination simply has no
        # bookable times — report that honestly instead of an opaque error.
        if not slot_ids and "restaurant_no_availability_state" in tree:
            return (
                "This restaurant has no bookable time slots for the currently "
                "selected date/party size (restaurant_no_availability_state is "
                "shown). Pick a different restaurant, date, or party size — or "
                "use the waitlist (waitlist_join_button)."
            )
        try:
            sim.swipe("up")
            sim.wait(0.3)
        except Exception:
            break
    if not on_detail:
        return (
            "Not on a restaurant detail page. Call view_restaurant(name=...) "
            "first to open a restaurant, then make/prepare the reservation."
        )
    # A specific time was requested but no matching slot was ever surfaced —
    # fail in a controlled way and list the times that ARE available, rather
    # than booking a different (wrong) slot.
    if want_hhmm is not None:
        avail = sorted({_slot_label_from_id(s) for s in seen_slot_ids})
        if avail:
            return (
                f"Requested time '{time}' is not available for this "
                f"restaurant/date/party size. Available times: "
                f"{', '.join(avail)}."
            )
        return (
            f"Requested time '{time}' is not available and no bookable time "
            f"slots are currently visible for this restaurant/date/party "
            f"size. Pick a different restaurant, date, or party size."
        )
    return (
        "Reservation controls are not currently visible; open a restaurant "
        "detail page and scroll to an available time slot. "
        f"Last error: {str(last_exc)[:120] if last_exc else 'no booking entry point found'}"
    )


def _make_reservation_capture_summary() -> dict:
    """Read the booking-review (Confirm reservation) screen summary.

    Each detail row on ``booking_review_screen`` renders TWO StaticText
    elements that share the same accessibility id: the first is the field
    *header* (``Restaurant`` / ``Date`` / ``Time`` / ``Party``) and the second
    is the actual *value* (e.g. ``Golden Gate Izakaya`` / ``Sun, May 31`` /
    ``9:00 PM`` / ``2 guests``). The previous implementation matched the first
    occurrence and so returned the header words instead of the values; here we
    take the first value that is not the header.
    """
    sim = SimulatorBridge.get()
    sim.wait(0.3)  # let the sheet finish animating in
    tree = sim.observe_text() or ""
    summary: dict = {
        "restaurant": None,
        "date": None,
        "time": None,
        "party_size": None,
    }
    for key, aid, header in (
        ("restaurant", "booking_review_restaurant", "Restaurant"),
        ("date", "booking_review_date", "Date"),
        ("time", "booking_review_time", "Time"),
        ("party_size", "booking_review_party", "Party"),
    ):
        vals = re.findall(
            r'name="' + re.escape(aid) + r'"[^>]*\b(?:value|label)="([^"]+)"',
            tree,
        )
        value = next((v.strip() for v in vals if v.strip() and v.strip() != header), None)
        summary[key] = value
    return summary


def _commit_open_review(sim) -> Optional[dict]:
    """Tap ``reservation_confirm_button`` on an already-open booking review
    screen and VERIFY a real confirmation screen rendered.

    Shared commit step used by the one-shot ``make_reservation`` and by
    ``confirm_make_reservation``. Precondition: the booking review screen is
    already open. Dismisses anything covering the confirm button (the notes
    keyboard left up by ``add_booking_notes`` and any open seating-preference
    dialog), taps confirm, then reads the tree back to confirm the
    ``reservation_confirmation_screen`` marker actually appeared.

    Returns ``None`` on a verified commit. Returns a ``{ok: False, message}``
    dict describing the controlled failure otherwise (never a false ok:true).
    """
    # add_booking_notes leaves the keyboard up and set_booking_preference can
    # leave a picker confirmationDialog open — either covers the confirm button
    # at the bottom so a blind tap silently no-ops. Dismiss them before tapping.
    _dismiss_overlays(sim)
    _dismiss_preference_dialog(sim)
    if "reservation_confirm_button" not in (sim.observe_text() or ""):
        _dismiss_overlays(sim)
        _dismiss_preference_dialog(sim)
    try:
        sim.tap_id("reservation_confirm_button"); sim.wait(0.6)
    except Exception as exc:
        return {
            "ok": False,
            "message": (
                f"reservation_confirm_button not found: {str(exc)[:120]}. "
                "The booking review screen may not be open."
            ),
        }
    # VERIFY a real confirmation actually rendered — never report success just
    # because the tap didn't raise (bug class: false ok). The build renders a
    # reservation_confirmation_screen / "Reservation Confirmed" marker.
    after = sim.observe_text() or ""
    confirmed = (
        "reservation_confirmation_screen" in after
        or "Reservation Confirmed" in after
        or "reservation_confirmed" in after
    )
    if not confirmed:
        # The keyboard or preference dialog may have re-raised between dismiss
        # and tap; clear it once more and retry a single time before failing.
        _dismiss_overlays(sim)
        _dismiss_preference_dialog(sim)
        if "reservation_confirm_button" in (sim.observe_text() or ""):
            try:
                sim.tap_id("reservation_confirm_button"); sim.wait(0.6)
            except Exception:
                pass
            after = sim.observe_text() or ""
            confirmed = (
                "reservation_confirmation_screen" in after
                or "Reservation Confirmed" in after
                or "reservation_confirmed" in after
            )
    if not confirmed:
        return {
            "ok": False,
            "message": (
                "Tapped reservation_confirm_button but no confirmation screen "
                "rendered; the booking may not have committed."
            ),
        }
    return None


@mcp.tool()
def make_reservation(time: Optional[str] = None) -> dict:
    """Book a reservation end-to-end for the current restaurant in ONE call.

    Args:
        time: Optional requested reservation time, e.g. ``"7:30 PM"`` or
            ``"19:30"``. When given, the matching reservation slot is booked;
            if that time is not available a controlled failure listing the
            available times is returned. When omitted, the next available
            slot is used.

    Opens the booking review screen (taps the matching reservation slot or a
    Book-Table button, scrolling to surface slots), then COMMITS the booking by
    tapping ``reservation_confirm_button`` and VERIFYING the
    ``reservation_confirmation_screen`` actually rendered. This is a complete
    one-shot verb — it does NOT depend on a follow-up confirm step.

    Precondition: must be on a restaurant detail view (call
    ``view_restaurant(...)`` first); otherwise returns ``{ok: false}``. If the
    restaurant has no slots for the current date/party size, returns a
    controlled failure naming ``restaurant_no_availability_state``. To stage the
    booking and add notes / a seating preference before committing, use
    ``prepare_make_reservation`` + ``confirm_make_reservation`` instead.

    Returns ``{ok: True, evidence: {restaurant, date, time, party_size}}`` only
    on a verified, committed reservation; a controlled ``{ok: false}`` otherwise.
    """
    err = _make_reservation_fill_form(time)
    if err is not None:
        return {"ok": False, "action": "make_reservation", "opened": False, "message": err}
    sim = SimulatorBridge.get()
    # Capture the staged summary while the review screen is open (used as
    # evidence; the confirmation screen replaces these rows).
    summary = _make_reservation_capture_summary()
    commit_err = _commit_open_review(sim)
    if commit_err is not None:
        commit_err.setdefault("action", "make_reservation")
        commit_err["opened"] = True
        commit_err["evidence"] = summary
        return commit_err
    return {
        "ok": True,
        "action": "make_reservation",
        "committed": True,
        "evidence": summary,
    }


@mcp.tool()
def prepare_make_reservation(time: Optional[str] = None) -> dict:
    """Open the booking review screen and capture the staged reservation
    summary WITHOUT committing the booking.

    Args:
        time: Optional requested reservation time, e.g. ``"7:30 PM"`` or
            ``"19:30"``. When given, the matching reservation slot is staged;
            if that time is not available a controlled failure listing the
            available times is returned. When omitted, the next available
            slot is used (legacy behaviour).

    Taps a reservation slot (or the Book-Table button) to surface the
    booking review screen, then reads the ``booking_review_restaurant`` /
    ``booking_review_date`` / ``booking_review_time`` /
    ``booking_review_party`` labels so the agent can sanity-check the
    reservation before confirming. Does NOT tap the
    ``reservation_confirm_button``. Requires that `view_restaurant(...)`
    has already been called to surface a restaurant detail view.

    Returns ``{ok: True, draft_id, summary: {restaurant, party_size, date,
    time}, next}`` on success, or a controlled-failure response if the
    booking review screen could not be opened.
    """
    err = _make_reservation_fill_form(time)
    if err is not None:
        return {"ok": False, "action": "prepare_make_reservation", "message": err}
    summary = _make_reservation_capture_summary()
    draft_id = ts.create_draft("dinespot", "make_reservation", summary)
    return {
        "ok": True,
        "action": "prepare_make_reservation",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_make_reservation(draft_id) to commit.",
    }


@mcp.tool()
def confirm_make_reservation(draft_id: str) -> dict:
    """Commit a reservation previously staged by ``prepare_make_reservation``.

    Args:
        draft_id: The id returned by ``prepare_make_reservation``. A
            missing/expired draft returns ``{ok: false}``.

    Auto-dismisses anything covering the confirm button first (the notes
    keyboard left up by ``add_booking_notes``, and any open seating-preference
    dialog from ``set_booking_preference``), then taps
    ``reservation_confirm_button`` and VERIFIES a confirmation screen actually
    rendered. Returns ``{ok: True, evidence: <summary>}`` only on a real
    confirmation; returns a controlled failure if the draft is missing/expired,
    the confirm button is no longer visible, or no confirmation screen appeared.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_make_reservation",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_make_reservation first.",
        }
    sim = SimulatorBridge.get()
    commit_err = _commit_open_review(sim)
    if commit_err is not None:
        msg = commit_err.get("message", "")
        return {
            "ok": False,
            "action": "confirm_make_reservation",
            "message": (
                f"{msg} Re-open the booking review (prepare_make_reservation) "
                "and confirm again."
            ),
            "evidence": draft.get("payload", {}),
        }
    return {
        "ok": True,
        "action": "confirm_make_reservation",
        "evidence": draft.get("payload", {}),
    }


@mcp.tool()
def view_reservations() -> str:
    """Navigate to the Reservations tab and return its UI tree (existing
    bookings as ``reservation_card_*`` rows). Works from any screen —
    self-recovers by dismissing a covering keyboard/overlay and VERIFIES the
    ``reservations_screen`` rendered; returns a controlled failure string (not a
    blind success) if it could not."""
    sim = SimulatorBridge.get()
    if not _goto_tab(sim, "reservations"):
        ui = sim.observe_text() or ""
        return (
            "Could not open the Reservations tab; the reservations_screen did "
            "not render (an overlay/keyboard may be covering the tab bar). "
            f"Dismiss open sheets and retry.\n\n{ui}"
        )
    ui = sim.observe_text()
    return f"Reservations:\n\n{ui}"


@mcp.tool()
def view_rewards() -> str:
    """Navigate to the Rewards tab and return its UI tree (points header +
    progress). Works from any screen — self-recovers by dismissing a covering
    keyboard/overlay and VERIFIES the ``rewards_screen`` rendered; returns a
    controlled failure string (not a blind success) if it could not."""
    sim = SimulatorBridge.get()
    if not _goto_tab(sim, "rewards"):
        ui = sim.observe_text() or ""
        return (
            "Could not open the Rewards tab; the rewards_screen did not render "
            "(an overlay/keyboard may be covering the tab bar). Dismiss open "
            f"sheets and retry.\n\n{ui}"
        )
    ui = sim.observe_text()
    return f"Rewards:\n\n{ui}"


@mcp.tool()
def add_booking_notes(notes: str) -> str:
    """Type notes into the booking review screen's notes field.

    Args:
        notes: Free-text note for the reservation (e.g. allergies,
            occasions). Replaces existing notes.

    Precondition: booking review screen open (call ``make_reservation``
    or ``prepare_make_reservation`` first); otherwise returns a controlled
    failure. VERIFIES the typed text actually landed in the field. Leaves the
    keyboard up, but ``confirm_make_reservation`` dismisses it before committing.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "booking_review_screen" not in tree and "booking_notes_field" not in tree:
        return (
            "Cannot add notes: the booking review screen (with its notes field) "
            "is not open. Call prepare_make_reservation(...) or "
            "make_reservation(...) first."
        )
    # The notes field lives in a Form section that can sit below the fold; if it
    # is not currently in the tree, scroll it into view so the tap lands on the
    # real TextField (a tap aimed at an off-screen id silently no-ops, leaving no
    # field focused -> the type action then has no keyboard target and raises
    # the "type action UI control unavailable" failure we are fixing).
    for _ in range(4):
        if "booking_notes_field" in (sim.observe_text() or ""):
            break
        try:
            sim.swipe("up"); sim.wait(0.3)
        except Exception:
            break
    tree = sim.observe_text() or ""
    if "booking_notes_field" not in tree:
        return (
            "Cannot add notes: the booking_notes_field is not visible on the "
            "booking review screen. Re-open the booking review and retry."
        )
    # Focus the field BEFORE typing and verify focus actually took (the soft
    # keyboard came up) — otherwise the type action has no control to write to.
    focused = False
    for _ in range(3):
        try:
            sim.tap_id("booking_notes_field"); sim.wait(0.4)
        except Exception:
            # A covering overlay can swallow the tap; clear it and retry.
            _dismiss_preference_dialog(sim)
            continue
        if _keyboard_up(sim):
            focused = True
            break
        # Keyboard did not raise — a picker dialog may be floating over the
        # field. Dismiss it and try focusing again.
        _dismiss_preference_dialog(sim)
    if not focused:
        return (
            "Could not focus the booking notes field (the keyboard did not come "
            "up after tapping it). Re-open the booking review and retry."
        )
    try:
        sim.type_text(notes); sim.wait(0.3)
    except Exception as exc:
        return f"Could not type the booking notes: {str(exc)[:120]}"
    # Confirm the note text actually landed in the field.
    after = sim.observe_text() or ""
    probe = notes.strip()[:24]
    if probe and probe not in after:
        return (
            f"Could not confirm booking notes were entered: '{notes[:40]}' did not appear; the "
            "field may not have been focused. Re-open the booking review and "
            "retry."
        )
    return f"Added booking notes: '{notes[:80]}'."


@mcp.tool()
def set_booking_preference() -> str:
    """Open the seating-preference picker on the booking review screen.

    Precondition: booking review screen open (call ``prepare_make_reservation``
    or ``make_reservation`` first); otherwise returns a controlled failure.
    Only OPENS the dialog and verifies its options surfaced — the agent must
    then observe and tap one of ``No preference`` / ``Patio seating`` /
    ``Bar seating``. (The open dialog floats over the confirm button, but
    ``confirm_make_reservation`` closes it before committing.)
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "booking_preference_picker" not in tree:
        return (
            "Cannot open the seating-preference picker: the booking review "
            "screen is not open. Call prepare_make_reservation(...) or "
            "make_reservation(...) first."
        )
    try:
        sim.tap_id("booking_preference_picker"); sim.wait(0.5)
    except Exception as exc:
        return f"Could not open the preference picker: {str(exc)[:120]}"
    # Confirm the picker options actually surfaced (so the agent can select one).
    after = sim.observe_text() or ""
    if not any(opt in after for opt in (
            "No preference", "Patio seating", "Bar seating", "Dining Preference")):
        return (
            "Could not open the preference picker after tapping it; "
            "re-open the booking review and retry."
        )
    return (
        "Opened booking preference picker. Select an option (e.g. 'Patio "
        "seating', 'Bar seating', 'No preference') before confirming."
    )


@mcp.tool()
def contact_support(message: str) -> str:
    """Send a message to support via the contact-support composer.

    Args:
        message: Body text to send to support.

    The composer is reached from the Updates screen (opened via the home
    ``home_action_updates`` quick action) through the
    ``updates_contact_support_row`` entry; this tool navigates there
    automatically. The composer TextField's Swift id
    (``contact_support_composer_field``) is shadowed at runtime by a sibling
    ``contact_support_screen`` identifier, so the field and send action are
    addressed via ``contact_support_screen`` (the TextField uses
    ``.submitLabel(.send)`` + ``onSubmit`` so a trailing newline sends it),
    with the labelled ids tried as fallbacks.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    on_composer = ("contact_support_composer_field" in tree
                   or "contact_support_screen" in tree)
    if not on_composer:
        # A prior search leaves the keyboard up, covering the bottom tab bar so
        # the Updates navigation taps silently no-op. Dismiss it first.
        _dismiss_overlays(sim)
        # If a restaurant detail (or any pushed view) is on top of the Updates
        # tab, a bare tab/quick-action tap won't pop it and the support row stays
        # unreachable (the after-detail / after-rewards recovery gap). Pop the
        # pushed detail first so the bottom tab bar is interactable.
        for _ in range(2):
            t = sim.observe_text() or ""
            if "restaurant_detail_screen_" not in t and "booking_review_screen" not in t:
                break
            popped = False
            for aid in ("Back", "chevron.left"):
                try:
                    sim.tap_id(aid); sim.wait(0.5); popped = True; break
                except Exception:
                    continue
            if not popped:
                break
        tree = sim.observe_text() or ""
        if "updates_contact_support_row" not in tree:
            # Reach the Updates screen. Prefer the verified tab switch (which
            # dismisses overlays + confirms the updates_screen marker rendered),
            # then fall back to the home quick action / raw tab taps.
            _goto_tab(sim, "updates")
            if "updates_contact_support_row" not in (sim.observe_text() or ""):
                for aid in ("home_action_updates", "tab_updates", "Updates"):
                    try:
                        sim.tap_id(aid); sim.wait(0.5)
                    except Exception:
                        continue
                    if "updates_contact_support_row" in (sim.observe_text() or ""):
                        break
        try:
            sim.tap_id("updates_contact_support_row"); sim.wait(1.0)
        except Exception as exc:
            return (f"Could not open the contact-support composer "
                    f"(updates_contact_support_row not reachable): {str(exc)[:120]}")
    # Focus the composer field. The TextField carries name=contact_support_screen
    # at runtime; click the concrete TextField element (brings up the keyboard)
    # and send keys to it directly so the global type action's keyboard
    # requirement is satisfied.
    field_el = None
    try:
        fields = sim.driver.find_elements("class name", "XCUIElementTypeTextField")
        for el in fields:
            try:
                nm = el.get_attribute("name") or ""
                ph = el.get_attribute("placeholderValue") or ""
            except Exception:
                nm, ph = "", ""
            if nm.startswith("contact_support") or "message" in ph.lower():
                field_el = el
                break
        if field_el is None and fields:
            field_el = fields[0]
    except Exception:
        field_el = None
    if field_el is not None:
        try:
            field_el.click(); sim.wait(0.3)
            field_el.send_keys(message); sim.wait(0.3)
        except Exception as exc:
            return f"Could not type the support message: {str(exc)[:120]}"
    else:
        # Fallback to accessibility-id tap + global type.
        tapped = False
        for aid in ("contact_support_composer_field", "contact_support_screen"):
            try:
                sim.tap_id(aid); sim.wait(0.3); tapped = True; break
            except Exception:
                continue
        if not tapped:
            return "Could not focus the contact-support composer field."
        try:
            sim.type_text(message); sim.wait(0.3)
        except Exception as exc:
            return f"Could not type the support message: {str(exc)[:120]}"
    # Commit: prefer the send button, else submit via newline (onSubmit).
    for aid in ("contact_support_send_button",):
        try:
            sim.tap_id(aid); sim.wait(0.5)
            break
        except Exception:
            continue
    else:
        try:
            sim.type_text("\n"); sim.wait(0.5)
        except Exception:
            pass
    # VERIFY the message actually posted — never report "Sent" on a blind tap
    # (bug class: false ok). A committed message renders as a user bubble
    # (``contact_support_user_msg_*``) carrying the message text, and the
    # composer field resets to its "Type a message..." placeholder. Require the
    # message text to appear in a user-msg element before claiming success.
    after = sim.observe_text() or ""
    probe = message.strip()[:24]
    user_bubble = re.search(
        r'name="contact_support_user_msg_[^"]*"[^>]*\b(?:value|label)="([^"]*)"',
        after,
    )
    posted = bool(
        (probe and probe in after and "contact_support_user_msg_" in after)
        or (user_bubble and probe and probe in (user_bubble.group(1) or ""))
    )
    if not posted:
        return (
            f"Could not confirm the support message was sent; no user message "
            f"bubble carrying '{message[:40]}' rendered. The composer may not "
            f"have been focused or the send action did not commit. Call "
            f"observe() and retry."
        )
    return f"Sent support message: '{message[:80]}'."


@mcp.tool()
def list_visible_restaurants() -> dict:
    """List bookable restaurant ids visible in the current UI tree.

    Returns:
        ``{restaurants: [<id>...], count}`` — each id (e.g. ``restaurant_004``)
        is usable with ``view_restaurant(name=<id>)``. Map-only markers are
        excluded, and if the home carousels are still empty this falls back to
        the Search tab so it returns the synchronous ``restaurant_row_*`` rows.
    """
    sim = SimulatorBridge.get()
    ids = _settle_restaurant_ids(sim)
    return {"restaurants": ids, "count": len(ids)}


def _settle_restaurant_ids(sim) -> list[str]:
    """Return visible restaurant ids, waiting for the (lazy) home carousel.

    An ``observe`` immediately after launch can catch an empty home shell
    because the carousels render asynchronously. Re-read a few times, and if
    the current screen still exposes no restaurant cards, fall back to the
    Search tab (which renders ``restaurant_row_restaurant_*`` rows synchronously).
    """
    for _ in range(4):
        ids = _restaurant_ids_from_text(sim.observe_text())
        if ids:
            return ids
        sim.wait(0.6)
    for aid in ("tab_search", "Search"):
        try:
            sim.tap_id(aid); sim.wait(0.6)
            break
        except Exception:
            continue
    for _ in range(3):
        ids = _restaurant_ids_from_text(sim.observe_text())
        if ids:
            return ids
        sim.wait(0.5)
    return _restaurant_ids_from_text(sim.observe_text())


def _restaurant_ids_from_text(tree: str) -> list[str]:
    """Extract underlying ``restaurant_<...>`` ids from the live tree.

    Restaurant cards are wrapped at runtime as ``home_dinner_row_<id>`` /
    ``home_recent_row_<id>`` on the home screen and
    ``restaurant_row_restaurant_<id>`` on the Search tab (the ``<id>`` itself is
    ``restaurant_004`` or ``restaurant_tr_lazy_bear``). Map markers
    (``map_marker_restaurant_*``) are intentionally excluded.
    """
    tree = tree or ""
    ids: set[str] = set()
    for pat in (
        r'(?:home_dinner_row_|home_recent_row_|restaurant_search_result_)(restaurant_[^"\s]+)',
        r'restaurant_row_(restaurant_[^"\s]+)',
        r'restaurant_detail_screen_(restaurant_[^"\s]+)',
    ):
        ids.update(re.findall(pat, tree))
    # Legacy fallback: bare restaurant_row_<slug> (older builds).
    if not ids:
        ids.update(re.findall(r'restaurant_row_([^"\s]+)', tree))
    return sorted(ids)


_FEATURE_MAP = {
    "outdoor": "featured_collection_outdoor", "outdoor seating": "featured_collection_outdoor",
    "patio": "featured_collection_outdoor",
    "romantic": "featured_collection_romantic", "date night": "featured_collection_romantic",
    "italian": "featured_collection_italian",
    "brunch": "featured_collection_brunch",
    "bar": "featured_collection_bar", "bar seating": "featured_collection_bar",
}


@mcp.tool()
def apply_feature_filter(feature: str) -> str:
    """Apply a featured-collection filter chip on the Discover/Search screen.

    Args:
        feature: One of ``outdoor`` (Outdoor seating), ``romantic``,
            ``italian``, ``brunch``, ``bar`` (case-insensitive). Synonyms
            also accepted: ``outdoor seating``/``patio`` -> outdoor,
            ``date night`` -> romantic, ``bar seating`` -> bar. Any other
            value returns an error listing valid features.

    Works from any screen — self-navigates to the Discover/Search screen
    (dismissing a covering keyboard and popping any pushed detail) before
    tapping the ``featured_collection_<feature>`` chip, so no manual
    navigation is needed. Returns ``{ok: false}`` if the chip is unreachable or
    the filter screen did not show, rather than reporting a blind tap success.
    """
    sim = SimulatorBridge.get()
    aid = _FEATURE_MAP.get(feature.strip().lower())
    if aid is None:
        return (f"Cannot apply filter: unknown feature '{feature}'. Use one of: "
                f"{sorted(set(_FEATURE_MAP.values()))}")
    # The filter chips live on the Discover/Search screen. Surface it first
    # (dismissing any covering keyboard / popping a pushed detail) so the chip
    # is reachable from cold home, after a search, or after opening a detail.
    if aid not in (sim.observe_text() or ""):
        _open_discover(sim)
    tapped = False
    for _attempt in range(2):
        if aid not in (sim.observe_text() or ""):
            _dismiss_overlays(sim)
            _open_discover(sim)
        try:
            sim.tap_id(aid); sim.wait(0.5)
            tapped = True
            break
        except Exception:
            sim.wait(0.3)
    if not tapped:
        restaurants = _restaurant_ids_from_text(sim.observe_text())
        return {
            "ok": False, "action": "apply_feature_filter", "feature": feature,
            "applied": False, "restaurants": restaurants, "count": len(restaurants),
            "message": f"Feature chip '{feature}' ({aid}) is not reachable on the Discover screen.",
        }
    # Confirm we are on the Discover screen (where the filter actually scopes
    # the result list) rather than reporting a blind tap success.
    ui = sim.observe_text() or ""
    restaurants = _restaurant_ids_from_text(ui)
    if "discover_screen" not in ui and aid not in ui:
        return {
            "ok": False, "action": "apply_feature_filter", "feature": feature,
            "applied": False, "message": (
                f"Tapped '{aid}' but the Discover filter screen is not showing; "
                "the filter may not have applied."),
        }
    return f"Applied '{feature}' filter (chip {aid}). {len(restaurants)} restaurants match."


if __name__ == "__main__":
    mcp.run()
