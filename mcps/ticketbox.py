"""TicketBox MCP — event ticket browsing, search, purchase, and tracking.

Bundle ID: com.iosworld.benchmark.ticketbox

ID-naming conventions:
  Tabs: tab.<browse|search|tickets|tracking|me>
  Events: event.row.title.<uuid> (rows in browse/search results)
  Listings: listing.price.<uuid> (ticket listings on an event detail screen)
  Filters: filter.<category|city|price|instant|reset|done>

RESOLVER FORMS (the app exposes NO UUIDs in the accessibility tree):
  - `event_id` (view_event): actually the event TITLE or a distinctive
    substring of it, case-insensitive. Get titles from `list_visible_events()`.
  - `listing_id` (view_listing): a price ("193"/"$193") or section ("109")
    appearing in a listing row label, case-insensitive substring.
  - `category`, `city`, `tab`, price tiers: human-readable strings,
    case-insensitive. Resolvers accept display names directly.
"""

import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts

mcp = FastMCP("TicketBox")

BUNDLE_ID = "com.iosworld.benchmark.ticketbox"
SEED_DATA_PATH = pathlib.Path(__file__).resolve().parents[1] / "iphone/apps/ticketbox/xproj/TicketBox/Models/SeedData.swift"

TAB_MAP = {
    "browse": "tab.browse",
    "search": "tab.search",
    "tickets": "tab.tickets",
    "tracking": "tab.tracking",
    "me": "tab.me",
}


def _ensure_search_tab(sim) -> None:
    """Make sure we're on the Search tab — the only screen that hosts the
    FilterSheetView toolbar button and the event-results list. The browse
    (Home) tab's hamburger opens a *different* sheet (BrowseSettings)."""
    try:
        sim.tap_id("tab.search")
        sim.wait(0.5)
    except Exception:
        pass


def _tap_predicate(sim, predicate: str):
    """Tap the first element matching an NSPredicate (name/label/type)."""
    return sim.perform_action(
        {"type": "tap", "using": "-ios predicate string", "value": predicate}
    )


def _focus_search_field(sim) -> bool:
    """Tap the search TextField (it has no a11y id, only a placeholder) so the
    keyboard appears before typing. Returns True on success."""
    for predicate in (
        'type == "XCUIElementTypeSearchField"',
        'type == "XCUIElementTypeTextField"',
        'placeholderValue CONTAINS[c] "Search"',
        'value CONTAINS[c] "Search"',
    ):
        try:
            _tap_predicate(sim, predicate)
            sim.wait(0.4)
            return True
        except Exception:
            continue
    return False


def _clear_search_field(sim) -> None:
    """Clear any existing text in the Search field so a fresh query replaces
    (not appends to) a prior one. The field renders a trailing
    ``xmark.circle.fill`` clear button whenever it holds text; tap it if
    present. Safe no-op when the field is already empty."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "xmark.circle.fill" in tree:
        try:
            sim.tap_id("xmark.circle.fill")
            sim.wait(0.3)
        except Exception:
            pass


def _open_filter_sheet(sim) -> None:
    # The filter toolbar button lives on the Search tab. Its name is the SF
    # symbol "line.3.horizontal.decrease.circle" (or the ".fill" variant once
    # filters are active); both share the visible label "Filter".
    # A detail/checkout overlay covers the toolbar — dismiss it first so the
    # filter button is reachable (otherwise the tap no-ops and the filter
    # action falsely reports it couldn't open the sheet).
    if not _on_list_screen(sim):
        _dismiss_overlays(sim)
    _ensure_search_tab(sim)
    try:
        sim.tap_id("line.3.horizontal.decrease.circle")
    except Exception:
        try:
            sim.tap_id("line.3.horizontal.decrease.circle.fill")
        except Exception:
            _tap_predicate(sim, 'label == "Filter"')
    sim.wait(0.4)


def _scroll_filter_sheet_to(sim, accessibility_id: str, max_swipes: int = 5) -> bool:
    """Swipe up on the filter sheet Form until ``accessibility_id`` appears.

    FilterSheetView.swift renders a SwiftUI Form whose lower sections
    (price-level buttons and the Reset section) sit below the visible
    viewport on a 6.1" simulator. XCUITest's auto-scroll on tap is not
    reliable for SwiftUI Forms, so this helper pages content into view
    before the tool issues the target tap.

    SwiftUI Form sections can also be lazy — when the Price Range
    section is well below the fold the inner ``filter_price_level_*``
    buttons may not even appear in the page_source tree until they're
    scrolled close to the viewport. Keep swiping until the id appears
    OR until ``max_swipes`` is exhausted; tolerate a short settle wait
    after each swipe so the lazy List instantiates the row.
    """
    for _ in range(max_swipes):
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if accessibility_id in tree:
            return True
        try:
            sim.swipe("up")
            sim.wait(0.35)
        except Exception:
            return False
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    return accessibility_id in tree


def _finish_filters(sim):
    ui = sim.tap_and_observe("filter.done")
    return ui


def _filter_applied(sim) -> bool:
    """True once at least one filter is active. The Search-tab toolbar swaps the
    filter glyph to the ``.fill`` variant when any filter is set, and the sheet
    must be dismissed (Done) — so we confirm the active glyph renders AND the
    filter sheet ("filter.done") is no longer on screen. This is the real
    on-screen marker, not a guessed screen id."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    sheet_gone = "filter.done" not in tree
    active = "line.3.horizontal.decrease.circle.fill" in tree
    return sheet_gone and active


import re as _re

# An event-result/browse row's accessibility name is the row text, which always
# carries a ", <Mon> <day> ·" date marker (e.g. "Ali Wong, Jun 15 · ...").
# Performer rows ("AW, Ali Wong, 2 events"), venue rows, and bare StaticText
# labels (name="Ali Wong") do NOT have this marker, so it uniquely identifies a
# tappable EVENT row.
#
# The row name comes in two layouts depending on the tab:
#   Search results: "<Title>, <Mon> <day> · <Venue>[, <score>]"
#                   (title FIRST — e.g. "Ali Wong, Jun 16 · Great American…, 98")
#   Browse/Home:    "$<price>+, <Title>, <Mon> <day> · <Venue>"
#                   (price FIRST — e.g. "$101+, Ali Wong, Jun 16 · Great…")
#   Browse FEATURED:"FEATURED, TicketBox Pick, <score>, $<price>, <Title>"
# The shared, reliable marker in every layout is the ", <Mon> <day> ·" date
# token; we capture the whole name on that anchor, then strip any leading
# price/FEATURED prefix to recover the bare event TITLE used for matching.
_EVENT_ROW_RE = _re.compile(
    r'<XCUIElementTypeButton\b[^>]*\bname="('
    r'[^"]+?, '
    r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{1,2} ·[^"]*)"'
)

# Leading browse-tab prefixes to peel off the title segment.
_BROWSE_PREFIX_RE = _re.compile(
    r'^(?:'
    r'FEATURED, TicketBox Pick, \d+, \$[\d,.]+, '   # featured hero card
    r'|\$[\d,.]+\+?, '                               # "$101+, " price prefix
    r')'
)


def _seed_event_titles():
    """Return seeded event titles from TicketBox's Swift SeedData.

    The UI exposes rows by title, but agents often pass a performer/team
    fragment. Resolving against seed titles first lets `view_event("Padres")`
    search for a real event title instead of depending on whichever mixed
    performer/event suggestions SwiftUI currently renders.
    """
    try:
        text = SEED_DATA_PATH.read_text()
    except Exception:
        return []
    start = text.find("static func makeEvents")
    end = text.find("static func makePastTickets", start)
    if start != -1 and end != -1:
        text = text[start:end]
    seen = set()
    titles = []
    for match in _re.finditer(r'\btitle:\s*"([^"]+)"', text):
        title = match.group(1).replace("\\n", " ").strip()
        if title and title not in seen:
            seen.add(title)
            titles.append(title)
    return titles


def _best_seed_event_title(query: str) -> str | None:
    q = (query or "").strip().lower()
    if not q:
        return None
    titles = _seed_event_titles()
    exact = [t for t in titles if t.lower() == q]
    if exact:
        return exact[0]
    starts = [t for t in titles if t.lower().startswith(q)]
    if starts:
        return starts[0]
    contains = [t for t in titles if q in t.lower()]
    if contains:
        # Prefer shorter titles for fragment matches so "Padres" resolves to
        # a direct matchup title rather than an arbitrary long row.
        return sorted(contains, key=lambda t: (len(t), t))[0]
    rev = [t for t in titles if t.lower() in q]
    if rev:
        return sorted(rev, key=lambda t: (-len(t), t))[0]
    return None


def _row_title(full):
    """Extract the bare event title from a full event-row name, handling both
    the search-results layout (title first) and the browse layout (price/
    FEATURED prefix before the title). Returns the text up to the ", <Mon>
    <day> ·" date marker with any leading price/FEATURED prefix removed."""
    if not full:
        return full
    body = _BROWSE_PREFIX_RE.sub("", full, count=1)
    tm = _re.match(
        r'(.+?), (?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{1,2} ·',
        body,
    )
    return tm.group(1).strip() if tm else body.strip()


# Purchased/tracked-ticket rows on the Tickets and Tracking tabs ALSO embed a
# ", <Mon> <day> ·" date marker (e.g. "Tickets delivered, · Delivered,
# Hamilton, $267, Mon, Jul 27 · 5:17 AM · …"), so the bare event-row regex
# would falsely treat them as tappable browse/search EVENT rows. They are NOT —
# tapping one opens a ticket detail (or nothing), never an event detail, which
# made view_event short-circuit on a no-op tap and never reach its Search
# self-nav. These rows are distinguished by a leading order/delivery STATUS
# token; reject any row name carrying one.
_TICKET_ROW_MARKERS = (
    "Tickets delivered", "Processing", "· Delivered", "· ETA",
    "Mobile Tickets", "Transferred", "Refunded",
)


def _is_ticket_status_row(full: str) -> bool:
    if not full:
        return False
    return any(mark in full for mark in _TICKET_ROW_MARKERS)


def _scrape_event_rows(sim):
    """Return [(full_row_name, title)] for every visible browse/search EVENT
    row button.

    ``full_row_name`` is the exact element name (used to locate/tap the row);
    ``title`` is the bare event title (used for matching), with any leading
    browse-tab price/FEATURED prefix stripped. Purchased/tracked ticket rows
    (Tickets/Tracking tabs) are excluded — they carry a date marker too but are
    not tappable event rows."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    rows = []
    for m in _EVENT_ROW_RE.finditer(tree):
        full = m.group(1)
        if _is_ticket_status_row(full):
            continue
        rows.append((full, _row_title(full)))
    return rows


def _best_event_match(rows, query):
    """Pick the best (full_name, title) for ``query`` from scraped event rows.

    Priority: exact title (case-insensitive) > title startswith query >
    title contains query > query contains title. Returns None if nothing
    plausibly matches."""
    q = (query or "").strip().lower()
    if not q or not rows:
        return None
    exact = [r for r in rows if r[1].lower() == q]
    if exact:
        return exact[0]
    starts = [r for r in rows if r[1].lower().startswith(q)]
    if starts:
        return starts[0]
    contains = [r for r in rows if q in r[1].lower()]
    if contains:
        return contains[0]
    rev = [r for r in rows if r[1].lower() in q]
    if rev:
        return rev[0]
    return None


def _on_event_detail(sim) -> bool:
    """True when an event-detail screen is open.

    The detail screen shows a back chevron, a "Buyer Guarantee" banner, a
    "Price alerts" control, and ticket-listing rows whose button name is
    ``$<price>, <section>, <N> rows`` (the per-listing a11y ids like
    ``listing.price.<uuid>`` are NOT surfaced as the element ``name`` in the
    tree, so we match the visible listing-row shape instead)."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    if "Buyer Guarantee" in tree or "Price alerts" in tree:
        return True
    # A listing row: name like "$168, GA, 7 rows".
    return bool(_re.search(r'name="\$\d[\d,.]*,[^"]*\brows"', tree))


def _checkout_present(sim) -> bool:
    """True when a TicketPurchaseSheet / seat-detail sheet is presented over the
    detail screen (its hallmark text renders above the listing list)."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    if any(k in tree for k in (
        "Confirm purchase", "Tickets purchased", "Order summary",
        "Payment method",
    )):
        return True
    return ("View from Section" in tree and "listings nearby" in tree)


def _on_list_screen(sim) -> bool:
    """True when a browse/search EVENT-list screen is showing (event rows are
    tappable and no detail/checkout overlay is covering the list).

    Used to decide whether an overlay must be dismissed before a tab-nav or
    filter action can land. The tab bar pokes through the bottom of a SwiftUI
    `.sheet`, but the filter toolbar and the search field do NOT — so we treat
    any detail/checkout state as "not a list"."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    if _checkout_present(sim):
        return False
    # An event-detail screen (Buyer Guarantee / Price alerts) is not a list.
    if "Buyer Guarantee" in tree or "Price alerts" in tree:
        return False
    return True


def _dismiss_overlays(sim, max_backs: int = 4) -> bool:
    """Back out of any event-detail / checkout sheet so the browse/search list
    and the tab bar are reachable again.

    The agent frequently calls a list/nav/filter tool while a detail or
    checkout overlay is still up (e.g. right after view_listing). Those
    overlays COVER the filter toolbar and the search field, so a tap on them
    no-ops and the tool falsely reports it "couldn't" do the action. This
    helper taps the back chevron (the detail/checkout dismiss control) until a
    plain list screen is showing, falling back to a relaunch if the chevron
    path stalls. Returns True once a list screen is reached."""
    for _ in range(max_backs):
        if _on_list_screen(sim):
            return True
        try:
            sim.tap_id("chevron.left")
            sim.wait(0.6)
        except Exception:
            break
    if _on_list_screen(sim):
        return True
    # Last resort: relaunch lands on the Browse home, which always renders the
    # event list with no overlay.
    try:
        sim.launch_and_observe(BUNDLE_ID)
        sim.wait(0.8)
    except Exception:
        pass
    return _on_list_screen(sim)


def _tap_element_by_name_xy(sim, full_name) -> bool:
    """Tap the center of the element whose ``name`` exactly equals ``full_name``
    using normalized (0-1000) coordinates scraped from the tree. SwiftUI
    NavigationLink rows do not reliably fire on a predicate/element tap, so a
    coordinate tap on the row center is used. Returns True if the element was
    located and tapped."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    win = _re.search(
        r'<XCUIElementTypeApplication[^>]*width="(\d+)" height="(\d+)"', tree
    )
    sw, sh = (int(win.group(1)), int(win.group(2))) if win else (402, 874)
    esc = _re.escape(full_name)
    m = _re.search(
        r'<XCUIElementTypeButton[^>]*name="' + esc +
        r'"[^>]*x="(\d+)" y="(\d+)" width="(\d+)" height="(\d+)"',
        tree,
    )
    if not m:
        # Some rows are NavigationLinks rendered as a non-Button container; try
        # any element type carrying that exact name.
        m = _re.search(
            r'<XCUIElementType\w+[^>]*name="' + esc +
            r'"[^>]*x="(\d+)" y="(\d+)" width="(\d+)" height="(\d+)"',
            tree,
        )
    if not m:
        return False
    x, y, w, h = map(int, m.groups())
    cx, cy = x + w // 2, y + h // 2
    nx, ny = int(cx / sw * 1000), int(cy / sh * 1000)
    try:
        sim.tap_xy(nx, ny)
        sim.wait(0.8)
        return True
    except Exception:
        return False


@mcp.tool()
def launch() -> str:
    """Launch the TicketBox app from the home screen.

    Returns:
        Status string concatenated with the post-launch UI accessibility tree.
    """
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched TicketBox.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (raw text dump).

    Use to read the current screen state and the visible event/listing row
    text. NOTE: the app does NOT surface event or listing UUIDs anywhere in the
    tree — events are referenced by their TITLE and listings by their
    price/section label. Use `list_visible_events()` for clean event titles.
    """
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="TicketBox",
        markers=("ticketbox_", "event.row.", "listing.price.", "tab.search"),
    )


def _tab_bar_visible(sim) -> bool:
    """True when TicketBox's bottom tab bar is reachable in the current tree.

    The five tab ids only render when TicketBox is the foreground app AND no
    full-screen modal is hiding the TabView. We probe for ANY tab id rather
    than a specific one because the bar is all-or-nothing — if one tab is
    present they all are. Used to decide whether self-recovery (dismiss
    overlays / relaunch to foreground TicketBox) is needed before a tab tap."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    return any(aid in tree for aid in TAB_MAP.values())


def _is_failure_result(value) -> bool:
    if isinstance(value, dict):
        return value.get("ok") is False
    if isinstance(value, str):
        return value.startswith("Could not")
    return False


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch to one of the five bottom tabs.

    Works from ANY screen — self-navigates: if the tab bar is not currently
    reachable (an event-detail / checkout overlay is covering it, or TicketBox
    is not the foreground app), it dismisses the overlay / re-foregrounds
    TicketBox, re-observes, and retries the tab tap. Returns a controlled
    ok:false only when the tab is genuinely unreachable after recovery.

    Args:
        tab_name: one of "browse", "search", "tickets", "tracking", "me".
            Case-insensitive. Any other value returns an error string.
    """
    aid = TAB_MAP.get(tab_name.lower())
    if aid is None:
        return f"Could not switch to unknown tab '{tab_name}'. Valid tabs: {', '.join(TAB_MAP.keys())}"
    sim = SimulatorBridge.get()

    # 1) If the tab bar isn't reachable, an event-detail / checkout overlay is
    #    covering it OR TicketBox is backgrounded (another app is foreground).
    #    Recover: first back out of any in-app overlay; if the bar is STILL
    #    absent, re-foreground TicketBox with a relaunch (lands on Browse home,
    #    which always roots a clean tab bar). Only recover when needed — don't
    #    thrash on a state where the bar is already up.
    if not _tab_bar_visible(sim):
        _dismiss_overlays(sim)
        if not _tab_bar_visible(sim):
            try:
                sim.launch_and_observe(BUNDLE_ID)
                sim.wait(0.8)
            except Exception:
                pass

    # 2) Tap the tab. If the control still wasn't present (tap raised), recover
    #    once more (relaunch to force-foreground TicketBox) and retry so a
    #    stale/lazy tree doesn't leak a false failure.
    try:
        ui = sim.tap_and_observe(aid)
    except Exception:
        try:
            sim.launch_and_observe(BUNDLE_ID)
            sim.wait(0.8)
        except Exception:
            pass
        if not _tab_bar_visible(sim):
            return (
                f"Could not switch to the '{tab_name}' tab — the TicketBox tab "
                "bar is unavailable in the current app state even after "
                "re-foregrounding TicketBox. Re-launch TicketBox, then retry."
            )
        try:
            ui = sim.tap_and_observe(aid)
        except Exception as exc:
            return (
                f"Could not switch to the '{tab_name}' tab. Error: "
                f"{str(exc)[:120]}"
            )
    return f"Navigated to '{tab_name}' tab.\n\n{ui}"


@mcp.tool()
def search_events(query: str) -> str:
    """Switch to the Search tab and type the query into the search field.

    Works from ANY screen — self-navigates: dismisses any open event-detail /
    checkout overlay, switches to the Search tab, and clears any stale prior
    query so this one replaces (not appends to) it before typing.

    Returns a controlled failure string ("Could not search events…") if the
    search field cannot be focused. After it returns, call
    `list_visible_events()` to read the matching event titles.

    Args:
        query: free-text search term (event title, performer, venue, or city,
            e.g. "Taylor Swift", "Madison Square Garden"). Case-insensitive.
    """
    sim = SimulatorBridge.get()
    try:
        # A detail/checkout overlay covers the search field — dismiss it first
        # so the field is reachable and focusable.
        if not _on_list_screen(sim):
            _dismiss_overlays(sim)
        nav = navigate_to_tab("search")
        if _is_failure_result(nav):
            try:
                sim.launch_and_observe(BUNDLE_ID)
                sim.wait(0.8)
                nav = navigate_to_tab("search")
            except Exception:
                pass
        if _is_failure_result(nav):
            return f"Could not search events for '{query}'. Search tab was not reachable: {nav}"
        # Clear any stale query left from a prior search so this one replaces
        # rather than appends to it.
        _clear_search_field(sim)
        # The search TextField carries no accessibility id, so tap it via a
        # type predicate to give it keyboard focus before typing — otherwise
        # `type` fails fast with "no keyboard visible".
        if not _focus_search_field(sim):
            try:
                sim.launch_and_observe(BUNDLE_ID)
                sim.wait(0.8)
                navigate_to_tab("search")
                _clear_search_field(sim)
            except Exception:
                pass
        if not _focus_search_field(sim):
            return (
                f"Could not search events for '{query}'. The search field "
                "could not be focused (no TextField on the current screen)."
            )
        sim.type_text(query)
        sim.wait(0.6)
    except Exception as exc:
        return f"Could not search events for '{query}'. Open the search field first. Error: {str(exc)[:120]}"
    ui = sim.observe_text()
    return f"Searched for '{query}'.\n\n{ui}"


@mcp.tool()
def filter_by_category(category: str) -> str:
    """Open the filter sheet and apply a category filter, then commit (Done).

    Works from ANY screen — self-navigates: dismisses any open detail/checkout
    overlay and forces the Search tab (the only tab whose toolbar hosts the
    filter sheet) before opening it. No precondition needed.

    Live category options are: All, Sports, Concerts, Broadway, Comedy. The
    data model's "theater" maps to the "Broadway" option. Accepted arg values
    (case-insensitive): "concerts"/"concert", "sports"/"sport",
    "theater"/"theatre"/"broadway", "comedy", and "all" (clears the category).
    Any other value is passed through verbatim and, if it is not a real option,
    the tool returns a controlled failure (dict with ok:false) naming the valid
    choices rather than guessing.

    Args:
        category: see the accepted values above. Case-insensitive.
    """
    sim = SimulatorBridge.get()
    _open_filter_sheet(sim)
    # Tapping `filter.category` opens a Menu-style popover; the options are
    # buttons whose visible label is the category name.
    sim.tap_id("filter.category")
    sim.wait(0.4)
    # Live category options are: All, Sports, Concerts, Broadway, Comedy.
    # (The data model's "theater" category is titled "Broadway".)
    option = {
        "concert": "Concerts",
        "concerts": "Concerts",
        "sports": "Sports",
        "sport": "Sports",
        "theater": "Broadway",
        "theatre": "Broadway",
        "theatre/broadway": "Broadway",
        "broadway": "Broadway",
        "comedy": "Comedy",
        "all": "All",
    }.get(category.strip().lower(), category)
    try:
        sim.tap_id(option)
    except Exception as exc:
        return {
            "ok": False,
            "action": "filter_by_category",
            "category": category,
            "message": (
                f"Category '{category}' is not a valid option. Choose one of: "
                f"Sports, Concerts, Broadway (theater), Comedy, or All. ({str(exc)[:80]})"
            ),
        }
    sim.wait(0.3)
    ui = _finish_filters(sim)
    if not _filter_applied(sim):
        return {
            "ok": False,
            "action": "filter_by_category",
            "category": category,
            "message": (
                f"Tapped category '{category}' but no active-filter marker "
                "rendered; the filter may not have applied."
            ),
        }
    return f"Filtered by category '{category}'.\n\n{ui}"


@mcp.tool()
def filter_by_city(city: str) -> str:
    """Open the filter sheet and pick a city from the list, then commit (Done).

    Works from ANY screen — self-navigates: dismisses any open detail/checkout
    overlay and forces the Search tab before opening the filter sheet. No
    precondition needed.

    Available cities (the only selectable ones, all in CA): San Francisco,
    San Jose, Oakland, Stanford, Mountain View. Pass the display name as shown.
    If the name has no comma and the exact match isn't found, the tool retries
    with ", CA" appended. An unselectable city returns a controlled failure
    (dict with ok:false) listing the available cities — the tool also cleans up
    the half-open picker so it does not corrupt the next tool's state.

    Args:
        city: a city display name from the list above (e.g. "San Jose").
    """
    sim = SimulatorBridge.get()
    _open_filter_sheet(sim)
    sim.tap_id("filter.city")
    sim.wait(0.3)
    city_name = city.strip()
    # Try the exact name, then a ", CA" variant. The seed picker only carries a
    # handful of Bay-Area cities; an unknown city (e.g. "Los Angeles") matches
    # none, so BOTH taps raise. We must NOT let that propagate — an unhandled
    # raise leaves the city-picker popover + filter sheet stuck OPEN, which
    # corrupts the state for every subsequent tool. Catch it, dismiss the open
    # sheet, and return a clean honest ok:false instead.
    candidates = [city_name]
    if "," not in city_name:
        candidates.append(f"{city_name}, CA")
    tapped = False
    for cand in candidates:
        try:
            sim.tap_id(cand)
            tapped = True
            break
        except Exception:
            continue
    if not tapped:
        # Close the still-open filter sheet so we leave a clean list screen
        # behind for the next tool, then report an honest failure. The city
        # picker is a SwiftUI Menu: the FIRST Done tap only dismisses the
        # still-open Menu popover, so tap Done until the sheet ("filter.done")
        # is actually gone (or fall back to a relaunch).
        for _ in range(3):
            try:
                if "filter.done" not in (sim.observe_text() or ""):
                    break
                sim.tap_id("filter.done"); sim.wait(0.3)
            except Exception:
                break
        if "filter.done" in (sim.observe_text() or ""):
            # Sheet still up — relaunch to a clean list screen as a last resort.
            try:
                sim.launch_and_observe(BUNDLE_ID); sim.wait(0.6)
            except Exception:
                pass
        return {
            "ok": False,
            "action": "filter_by_city",
            "city": city,
            "message": (
                f"City '{city}' is not selectable in the filter picker. The "
                "available cities are San Francisco, San Jose, Oakland, "
                "Stanford, and Mountain View (all CA)."
            ),
        }
    sim.wait(0.3)
    ui = _finish_filters(sim)
    if not _filter_applied(sim):
        # Make sure no half-open sheet is left behind on a non-apply.
        try:
            if "filter.done" in (sim.observe_text() or ""):
                sim.tap_id("filter.done"); sim.wait(0.3)
        except Exception:
            pass
        return {
            "ok": False,
            "action": "filter_by_city",
            "city": city,
            "message": (
                f"Tapped city '{city}' but no active-filter marker rendered; "
                "the filter may not have applied."
            ),
        }
    return f"Filtered by city '{city}'.\n\n{ui}"


@mcp.tool()
def filter_by_price(min: str, max: str) -> str:
    """Apply a price filter by tapping a discrete price-level shortcut, then commit.

    TicketBox preserves its slider-only visual control, but the filter sheet
    also exposes four discrete tap-target buttons (``filter_price_level_1``
    through ``filter_price_level_4``) corresponding to common budget tiers:

    - level 1 (``$``):    $0 – $50
    - level 2 (``$$``):   $50 – $100
    - level 3 (``$$$``):  $100 – $200
    - level 4 (``$$$$``): $200 – $400

    The numeric ``min`` and ``max`` args are mapped to whichever single tier
    best covers the requested range: the lowest tier whose upper bound is >=
    the requested max (so min=50,max=200 selects tier 3 = $100-$200). A
    requested max above $400 uses the top tier (4). ``min`` is honored only as
    a fallback when no tier covers the max. Only ONE discrete tier can be
    applied per call.

    Works from ANY screen — self-navigates: dismisses any open detail/checkout
    overlay and forces the Search tab before opening the filter sheet. No
    precondition needed. Returns a controlled failure (dict with ok:false) if
    the price tier button can't be located/applied.

    Args:
        min: lower-bound dollar amount as a numeric string (e.g. "50").
            Non-numeric defaults to 0.
        max: upper-bound dollar amount as a numeric string (e.g. "200").
            Non-numeric defaults to 400.
    """
    sim = SimulatorBridge.get()
    _open_filter_sheet(sim)
    # Tapping the `filter.price` Section header is a no-op (Sections in
    # SwiftUI Forms don't expand); skip it and rely on the explicit
    # scroll loop below to bring the price-level buttons into view.
    sim.wait(0.3)

    tiers = [
        (1, 0.0, 50.0),
        (2, 50.0, 100.0),
        (3, 100.0, 200.0),
        (4, 200.0, 400.0),
    ]
    try:
        req_min = float(min)
    except (TypeError, ValueError):
        req_min = 0.0
    try:
        req_max = float(max)
    except (TypeError, ValueError):
        req_max = 400.0

    # Pick the lowest tier whose upper bound still covers the requested max, so
    # the chosen tier actually spans the budget the agent asked for (e.g.
    # min=50,max=200 -> tier 3 ($100-$200), not tier 2 which would clip at
    # $100). Only one discrete tap-target can be applied, so we honor the max.
    chosen = None
    for level, lo, hi in tiers:
        if hi >= req_max:
            chosen = (level, lo, hi)
            break
    if chosen is None:
        # Requested max exceeds the top tier — use the widest (top) tier.
        chosen = tiers[-1]

    level, lo, hi = chosen
    # SwiftUI collapses the four price-tier Buttons' individual
    # `filter_price_level_N` identifiers under the enclosing VStack's
    # `filter.price` id, so the only thing that distinguishes them in the
    # accessibility tree is their visible label: "$", "$$", "$$$", "$$$$".
    tier_label = "$" * level
    # The Price Range section sits below the fold on a fresh sheet open.
    # Scroll the "filter.price" container into view, then tap the tier by
    # its label.
    _scroll_filter_sheet_to(sim, "filter.price", max_swipes=8)
    predicate = f'name == "filter.price" AND label == "{tier_label}"'
    try:
        _tap_predicate(sim, predicate)
        sim.wait(0.3)
    except Exception:
        # Make sure the section is fully rendered, then retry.
        try:
            for _ in range(2):
                sim.swipe("up"); sim.wait(0.3)
            _tap_predicate(sim, predicate); sim.wait(0.3)
        except Exception as exc2:
            return {
                "ok": False,
                "action": "filter_by_price",
                "min": min,
                "max": max,
                "message": (
                    f"Price tier '{tier_label}' (level {level}) not found in "
                    f"the filter sheet. ({str(exc2)[:100]})"
                ),
            }
    ui = _finish_filters(sim)
    if not _filter_applied(sim):
        return {
            "ok": False,
            "action": "filter_by_price",
            "min": min,
            "max": max,
            "message": (
                f"Tapped price tier '{tier_label}' (level {level}) but no "
                "active-filter marker rendered; the filter may not have applied."
            ),
        }
    return (
        f"Filtered by price tier level {level} ({tier_label}, ${int(lo)}-${int(hi)}) "
        f"covering requested range ${min}-${max}.\n\n{ui}"
    )


@mcp.tool()
def view_event(event_id: str) -> str:
    """Open an event's detail screen by tapping its row/card.

    Event rows in TicketBox are SwiftUI NavigationLinks identified by their
    visible *title text* (the event name), not by a stable UUID — so this tool
    matches on the title. Pass the event title exactly as shown in the list,
    e.g. "New York Yankees at San Francisco Giants" or just a distinctive
    fragment like "Lion King".

    Works from ANY screen — self-navigates: dismisses any open detail/checkout
    overlay, tries the current screen, then falls back to the Search tab,
    clears any stale query, types the title to populate the Events section,
    and scrolls to find the row. A BLIND call (fresh launch, target not yet on
    screen) works. No precondition needed, though `list_visible_events()` after
    a search shows the exact titles available.

    Matching is CASE-INSENSITIVE with this priority: exact title > title
    starts-with query > title contains query > query contains title. Returns a
    controlled failure (dict with ok:false) if nothing matches — it does not
    guess. Pass the title or a distinctive fragment, e.g. "Lion King".

    Args:
        event_id: the event TITLE or a distinctive substring of it (NOT a UUID
            — the app exposes no event UUIDs) as shown in the results/browse
            cards. Case-insensitive match.
    """
    sim = SimulatorBridge.get()
    title = (event_id or "").strip()
    if not title:
        return {
            "ok": False,
            "action": "view_event",
            "message": "view_event requires an event title (or fragment).",
        }
    resolved_title = _best_seed_event_title(title) or title

    def _try_tap_event(query):
        """Find an event row matching ``query`` in the CURRENT screen and tap it.
        Returns the matched title on success, else None (no screen change /
        no detail)."""
        rows = _scrape_event_rows(sim)
        match = _best_event_match(rows, query)
        if match is None:
            return None
        full, matched_title = match
        if not _tap_element_by_name_xy(sim, full):
            return None
        return matched_title if _on_event_detail(sim) else None

    # 0) If a detail/checkout overlay is up (e.g. the agent just called
    #    view_listing), it covers the tab bar / search field — dismiss it so
    #    the self-nav below can actually land. Without this, a repeat
    #    view_event from a checkout state no-ops and falsely reports failure.
    if not _on_list_screen(sim):
        _dismiss_overlays(sim)

    # 1) Try the current screen first (agent may already be on browse/search).
    matched = _try_tap_event(resolved_title)

    # 2) Self-navigate: go to the Search tab, type the query so the Events
    #    section populates, then tap the matching event row. This is the path
    #    that makes a BLIND call (fresh launch, target not on screen) work.
    if matched is None:
        try:
            sim.tap_id(TAB_MAP["search"])
            sim.wait(0.5)
            # A prior search may have left a stale query in the field; clear it
            # so typing `title` replaces rather than appends (e.g. avoids
            # "Ali WongDrake" when switching events after a checkout).
            _clear_search_field(sim)
            typed = False
            if _focus_search_field(sim):
                sim.type_text(resolved_title)
                sim.wait(0.8)
                typed = True
            # If focusing failed (transient: tab transition not settled), give
            # the screen a beat and retry once so the Events section populates.
            if not typed:
                sim.wait(0.4)
                if _focus_search_field(sim):
                    sim.type_text(resolved_title)
                    sim.wait(0.8)
        except Exception:
            pass
        matched = _try_tap_event(resolved_title)
        # Scroll the results once and retry in case the row was below the fold.
        if matched is None:
            for _ in range(3):
                try:
                    sim.swipe("up"); sim.wait(0.4)
                except Exception:
                    break
                matched = _try_tap_event(resolved_title)
                if matched is not None:
                    break

    if matched is None:
        return {
            "ok": False,
            "action": "view_event",
            "event": title,
            "message": (
                f"No event matching '{title}' could be found via search"
                f"{f' (resolved to {resolved_title!r})' if resolved_title != title else ''}. Check "
                "the title with list_visible_events() after search_events(...)."
            ),
        }
    after = sim.observe_text() or ""
    return f"Viewing event '{matched}'.\n\n{after}"


@mcp.tool()
def view_tickets() -> str:
    """Navigate to the Tickets tab (user's purchased/saved tickets)."""
    ui = navigate_to_tab("tickets")
    if _is_failure_result(ui):
        return ui
    return f"Viewing tickets.\n\n{ui}"


@mcp.tool()
def view_tracking() -> str:
    """Navigate to the Tracking tab (events the user is tracking for updates)."""
    ui = navigate_to_tab("tracking")
    if _is_failure_result(ui):
        return ui
    return f"Viewing tracking.\n\n{ui}"


@mcp.tool()
def reset_filters() -> str:
    """Open the filter sheet, tap Reset, then commit (Done) to clear all filters.

    Works from ANY screen — self-navigates: dismisses any open detail/checkout
    overlay and forces the Search tab before opening the filter sheet, then
    scrolls down to the Reset section (it sits below every other section).
    """
    sim = SimulatorBridge.get()
    _open_filter_sheet(sim)
    # `filter.reset` is the last Section in FilterSheetView (line 117)
    # — below every other section, so it requires scrolling.
    _scroll_filter_sheet_to(sim, "filter.reset", max_swipes=6)
    ui = sim.tap_and_observe("filter.reset")
    try:
        ui = _finish_filters(sim)
    except Exception:
        pass
    return f"Filters reset.\n\n{ui}"


@mcp.tool()
def list_visible_events() -> dict:
    """Scrape the event TITLES currently visible in the search results list.

    Event rows are SwiftUI NavigationLinks whose accessibility name is the
    full row text ("<Title>, <Mon> <day> · <Venue>[, <score>]"). The app does
    not surface event UUIDs anywhere in the accessibility tree, so this returns
    titles instead — pass any of them straight to `view_event(...)`.

    PRECONDITION: be on the Search tab with a query entered (call
    `search_events(...)` first); browse-card titles are also matched when on
    the Browse tab.

    Returns:
        dict ``{"events": [<title>, ...], "count": int}``. Empty when no event
        rows are visible.
    """
    sim = SimulatorBridge.get()
    titles = []
    seen = set()
    # Reuse the shared event-row scraper so both layouts (search "Title, …"
    # and browse "$<price>+, Title, …" / FEATURED hero) yield the BARE title.
    for _full, title in _scrape_event_rows(sim):
        if title and title not in seen:
            seen.add(title)
            titles.append(title)
    return {"events": titles, "count": len(titles)}


@mcp.tool()
def view_listing(listing_id: str) -> str:
    """Tap a specific ticket listing on the open event-detail screen.

    Listings render as Buttons labelled "$<price>, <section>, <rows> rows"
    (e.g. "$193, 109, 21 rows"); they carry no UUID in the accessibility tree.
    Pass either the price (e.g. "193" or "$193") or the section number
    (e.g. "109"); the first listing whose label contains that token is tapped,
    opening its checkout sheet.

    The match is a case-insensitive substring of the row label, so a partial
    token works; the listing list is scrolled (a few pages) to find a row
    below the fold. On success the listing's checkout/purchase sheet opens.

    PRECONDITION: an event detail screen must be open (call `view_event()`
    first) — this tool does NOT self-navigate there, since listings only exist
    on a detail screen. Returns a controlled failure (dict with ok:false) if no
    matching listing is visible or the checkout sheet does not open.

    Args:
        listing_id: a price ("193"/"$193") or section ("109") that appears in
            the target listing's row label. NOT a UUID — listings expose none.
    """
    sim = SimulatorBridge.get()
    token = (listing_id or "").strip().lstrip("$").strip()
    if not token:
        return {
            "ok": False,
            "action": "view_listing",
            "message": "view_listing requires a price or section to identify the listing.",
        }

    def _checkout_open() -> bool:
        """True when the TicketPurchaseSheet is presented. Its hallmark content
        (seat-view header, "listings nearby", a "Confirm purchase" CTA below
        the fold) distinguishes it from the underlying detail screen."""
        try:
            tree = sim.observe_text() or ""
        except Exception:
            return False
        if any(k in tree for k in (
            "Confirm purchase", "Tickets purchased", "Order summary",
            "Payment method",
        )):
            return True
        # Seat-detail header rendered at the top of the purchase sheet.
        return ("View from Section" in tree and "listings nearby" in tree)

    def _find_listing_rows():
        """Return [(full_name, x, y, w, h, sw, sh)] for visible listing-row
        buttons (name like "$168, GA, 7 rows")."""
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        win = _re.search(
            r'<XCUIElementTypeApplication[^>]*width="(\d+)" height="(\d+)"', tree
        )
        sw, sh = (int(win.group(1)), int(win.group(2))) if win else (402, 874)
        rows = []
        for m in _re.finditer(
            r'<XCUIElementTypeButton[^>]*name="(\$\d[^"]*\brows)"'
            r'[^>]*x="(\d+)" y="(\d+)" width="(\d+)" height="(\d+)"',
            tree,
        ):
            full = m.group(1)
            x, y, w, h = map(int, m.groups()[1:])
            rows.append((full, x, y, w, h, sw, sh))
        return rows

    def _match(rows):
        tl = token.lower()
        # Prefer a section/price token match; CONTAINS the token (case-insens).
        for full, *rest in rows:
            if tl in full.lower():
                return (full, *rest)
        return None

    # The target listing may be below the fold on the detail screen; scroll the
    # listing list until a matching row appears (up to a few pages).
    target = _match(_find_listing_rows())
    if target is None:
        for _ in range(5):
            try:
                sim.swipe("up"); sim.wait(0.35)
            except Exception:
                break
            target = _match(_find_listing_rows())
            if target is not None:
                break

    if target is None:
        return {
            "ok": False,
            "action": "view_listing",
            "listing": listing_id,
            "message": (
                f"No ticket listing matching '{listing_id}' is visible. Open an "
                "event detail (view_event) first, then pass a price (e.g. '193') "
                "or section (e.g. '109') shown on a listing row."
            ),
        }

    full = target[0]
    # The listing row is a SwiftUI Button; an element .click() (predicate tap)
    # reliably fires its action and presents the purchase sheet, whereas a
    # coordinate tap on the tight a11y frame does not.
    esc = full.replace('"', '\\"')
    try:
        _tap_predicate(sim, f'name == "{esc}"')
        sim.wait(0.9)
    except Exception as exc:
        return {
            "ok": False,
            "action": "view_listing",
            "listing": listing_id,
            "message": f"Could not tap listing '{full}'. ({str(exc)[:90]})",
        }
    if not _checkout_open():
        return {
            "ok": False,
            "action": "view_listing",
            "listing": listing_id,
            "message": (
                f"Tapped listing '{full}' but the checkout sheet did not open. "
                "Make sure an event detail screen is open."
            ),
        }
    return f"Opened checkout for listing '{full}'."


@mcp.tool()
def toggle_instant_deliver() -> str:
    """Open the filter sheet, toggle "Instant delivery", and commit (Done).

    Each call FLIPS the current state (no on/off arg) — call twice to revert.
    The success string reports the resulting state ("now on"/"now off").

    Works from ANY screen — self-navigates: dismisses any open detail/checkout
    overlay and forces the Search tab before opening the filter sheet, then
    scrolls down to bring the Delivery toggle into view. Returns a controlled
    failure (dict with ok:false) if the toggle can't be found or its value did
    not actually change after the tap.
    """
    import re
    sim = SimulatorBridge.get()
    _open_filter_sheet(sim)

    def _switch_box():
        """Return (value, x, y, w, h) for the filter.instant Switch, plus the
        app window (sw, sh), or None if not present."""
        try:
            tree = sim.observe_text() or ""
        except Exception:
            return None
        win = re.search(
            r'<XCUIElementTypeApplication[^>]*width="(\d+)"\s+height="(\d+)"',
            tree,
        )
        sw, sh = (int(win.group(1)), int(win.group(2))) if win else (402, 874)
        m = re.search(
            r'<XCUIElementTypeSwitch[^>]*value="([01])"[^>]*name="filter\.instant"'
            r'[^>]*x="(\d+)"\s+y="(\d+)"\s+width="(\d+)"\s+height="(\d+)"',
            tree,
        )
        if not m:
            return None
        v, x, y, w, h = m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4)), int(m.group(5))
        return (v, x, y, w, h, sw, sh)

    # The Delivery toggle sits below the fold; page it into view first.
    _scroll_filter_sheet_to(sim, "filter.instant", max_swipes=6)
    box = _switch_box()
    before = box[0] if box else None
    if box is None:
        return {
            "ok": False,
            "action": "toggle_instant_deliver",
            "message": "The instant-delivery toggle could not be located in the filter sheet.",
        }
    # Tapping the row by accessibility id lands on the label (left side) and
    # does NOT flip a SwiftUI Form Toggle. Tap the switch control itself —
    # the thumb on the right edge — using normalized (0-1000) coordinates.
    _, x, y, w, h, sw, sh = box
    px = x + w - 22
    py = y + h // 2
    nx = int(px / sw * 1000)
    ny = int(py / sh * 1000)
    try:
        sim.tap_xy(nx, ny)
        sim.wait(0.4)
    except Exception as exc:
        return {
            "ok": False,
            "action": "toggle_instant_deliver",
            "message": f"Could not tap the instant-delivery toggle. ({str(exc)[:100]})",
        }
    box2 = _switch_box()
    after = box2[0] if box2 else None
    try:
        _finish_filters(sim)
    except Exception:
        pass
    if before is not None and after is not None and before == after:
        return {
            "ok": False,
            "action": "toggle_instant_deliver",
            "message": (
                f"Tapped the instant-delivery toggle but its value did not "
                f"change (still {after}). It may have been off-screen."
            ),
        }
    state = {"0": "off", "1": "on"}.get(after, "toggled")
    return f"Toggled instant-delivery filter (now {state})."


if __name__ == "__main__":
    mcp.run()
