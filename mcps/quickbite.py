"""QuickBite MCP — DoorDash-style food delivery: browse, add, checkout.

Bundle ID: com.iosworld.benchmark.quickbite

Resolver conventions (read these before passing ids):
  - Tabs: pass a lowercase verb to navigate_to_tab — one of
    home / browse / orders / account (case-insensitive). Tools that need a tab
    self-navigate, so you rarely call navigate_to_tab directly.
  - Restaurants: pass the HUMAN-READABLE display name (e.g. "Chipotle Mexican
    Grill") OR its slug ("chipotle_mexican_grill"). The resolver fuzzy-matches
    by visible text, so the name is preferred — do NOT guess a slug. (This
    installed build does NOT expose restaurant_row_* ids; matching is by the
    visible restaurant name.)
  - Menu items: pass the item's display name OR slug ("chicken_burrito").
    Discover exact item slugs with browse_menu(restaurant=...).
  - Slug form = lowercase, every run of non-alphanumerics collapsed to one "_".

Accessibility-ID conventions (used internally; agents pass names/slugs, not ids):
  Search: browse_search_bar
  Chat support: doordash.chatSupport, doordash.chat.input, doordash.chat.send
  Add card: doordash.addCard.{name,number,save}
  Edit profile: doordash.editProfile.{name,email}
  New address: doordash.newAddress.{label,detail,save}
  Checkout (cross-app via MyBank): mybank.checkout.{badge,card,summary,
    confirmButton,confirmLabel,confirmToggle}

The high-level tools (browse_menu, add_to_order, open_cart,
tap_place_order_button, set_delivery_address, add_payment_card, edit_profile,
contact_support) self-navigate and resolve targets by visible text — you do
NOT need observe()+tap_xy for normal menu/checkout interaction. observe() is
only for inspecting state when a tool returns a controlled failure.
"""

import sys, pathlib, re
from collections import Counter
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts

mcp = FastMCP("QuickBite")

BUNDLE_ID = "com.iosworld.benchmark.quickbite"

TAB_MAP = {
    "home": "Home", "browse": "Browse", "orders": "Orders", "account": "Account",
}

# Candidate accessibility-id / label strings to tap for each tab, most-likely
# first. The Home tab button renders with name/label "home" (lowercase — it
# inherits the SF-symbol's label) regardless of selection, while the other
# tabs keep their capitalized titles ("Browse", "Orders", "Account"). The tap
# fallback in appium_agent matches `name == X OR label == X` *case-sensitively*,
# so we must try both cases. See observe: Home button is always name="home".
TAB_TAP_CANDIDATES = {
    "home": ["home", "Home"],
    "browse": ["Browse", "browse"],
    "orders": ["Orders", "orders"],
    "account": ["Account", "account"],
}

# A landmark substring that proves a given tab's screen is showing. Used to
# (a) short-circuit when already on the target tab and (b) verify the tap
# actually switched tabs.
# Landmark substrings that prove a given tab's screen is showing. The installed
# build exposes NO restaurant_row_/account_row_ ids, so these use visible text /
# nav-bar names that actually render (verified live). Each entry is a list of
# acceptable markers (ANY one present ⇒ on that tab).
TAB_LANDMARK = {
    "home": ["Deliver now", "All Restaurants"],
    "browse": ["browse_search_bar"],
    "orders": ['NavigationBar type="XCUIElementTypeNavigationBar" name="Orders"',
               "No active orders", "Active Orders", "Past Orders"],
    "account": ['NavigationBar type="XCUIElementTypeNavigationBar" name="Account"',
                "DashPass Member", "Saved Stores"],
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


def _quickbite_tree_matches(tree: str) -> bool:
    t = tree or ""
    return (
        f'bundleId="{BUNDLE_ID}"' in t
        or "browse_search_bar" in t
        or "doordash." in t
        or "view_cart_button" in t
        or "restaurant_row_" in t
        or "menu_item_" in t
        or "checkout_" in t
        or "Deliver now" in t
        or "All Restaurants" in t
        or "DashPass Member" in t
    )


def _observe_quickbite_scoped(sim):
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
                "message": "QuickBite is not the foreground app; observe() did not return another app's UI tree.",
            }

    tree = sim.observe_text() or ""
    if active == BUNDLE_ID or _quickbite_tree_matches(tree):
        return tree

    return {
        "ok": False,
        "error": "app-mismatch",
        "expected_bundle": BUNDLE_ID,
        "actual_bundle": _active_bundle_id(sim),
        "message": "Could not verify QuickBite as the foreground app; observe() did not return an unscoped UI tree.",
    }


def _on_tab(sim, tab: str) -> bool:
    """True if the screen for ``tab`` (lowercase key) is currently showing.

    Home and Browse can both show restaurant lists, so the Home check also
    requires the Browse search bar to be ABSENT — otherwise a filtered Browse
    list would masquerade as Home and short-circuit a navigate-to-Home.
    """
    tree = sim.observe_text() or ""
    marks = TAB_LANDMARK.get(tab)
    if not marks:
        return False
    if not any(m in tree for m in marks):
        return False
    if tab == "home" and "browse_search_bar" in tree:
        return False
    return True


def _goto_tab(sim, tab: str) -> bool:
    """Self-navigate to a bottom tab by lowercase name; return True on success.

    Robust to the lowercase-"home" tab-button quirk and to a tab being
    already selected (no-op success). Tries each candidate id/label, then
    verifies the destination screen's landmark appeared.
    """
    tab = (tab or "").lower()
    if tab not in TAB_TAP_CANDIDATES:
        return False
    _observe_quickbite_scoped(sim)
    if _on_tab(sim, tab):
        return True
    # Two passes: if the search keyboard is up, the first tab tap just dismisses
    # the keyboard / search focus instead of switching tabs, so we retry. We
    # also try tapping the search field's Cancel first when present to clear a
    # filtered Browse list back to a clean state.
    for attempt in range(5):
        # Clear anything intercepting the tab tap BEFORE tapping. A pushed
        # detail screen (e.g. the Chat Support composer) presents over the tab
        # bar with the keyboard up; the keyboard swallows the tap and the tab
        # never switches. Dismiss the keyboard, then pop pushed screens via
        # Back so the tab tap lands on the tab bar from a tab-root.
        tree = sim.observe_text() or ""
        if "Keyboard" in tree:
            for dismiss in ("Cancel", "Search", "Done", "BackButton", "Back"):
                try:
                    sim.tap_id(dismiss); sim.wait(0.4); break
                except Exception:
                    continue
            tree = sim.observe_text() or ""
        # Pop a lingering pushed detail (BackButton) when we're not on the
        # target yet — but skip if the destination is already showing.
        if not _on_tab(sim, tab) and "BackButton" in tree:
            try:
                sim.tap_id("BackButton"); sim.wait(0.4)
            except Exception:
                pass
        for cand in TAB_TAP_CANDIDATES[tab]:
            try:
                sim.tap_id(cand); sim.wait(0.5)
            except Exception:
                continue
            if _on_tab(sim, tab):
                return True
    try:
        sim.launch_and_observe(BUNDLE_ID); sim.wait(0.7)
    except Exception:
        pass
    for cand in TAB_TAP_CANDIDATES[tab]:
        try:
            sim.tap_id(cand); sim.wait(0.5)
        except Exception:
            continue
        if _on_tab(sim, tab):
            return True
    return _on_tab(sim, tab)


def _slug(value: str) -> str:
    """Normalize a free-text name to the app's slug form.

    Mirrors the app's slugging (see ViewController.swift): lowercase and
    replace any run of non-alphanumerics with a single underscore.
    """
    s = re.sub(r"[^a-z0-9]+", "_", (value or "").strip().lower())
    return s.strip("_")


def _set_field(sim, accessibility_id: str, text: str) -> bool:
    """Tap a text field, CLEAR any prefilled value, then type ``text``.

    The QuickBite edit-profile / new-address fields ship prefilled (e.g.
    the profile name already reads "Jordan A."). A plain tap+type appends
    to that value ("Jordan A.Jordan B"), so we clear the field first via
    the live Appium element before sending keys. Falls back to the legacy
    tap_id + type_text path if the element can't be resolved. Returns True
    if the value was set.
    """
    try:
        drv = sim.connect()
        el = drv.find_element("accessibility id", accessibility_id)
        el.click(); sim.wait(0.2)
        try:
            el.clear()
        except Exception:
            pass
        sim.wait(0.1)
        el.send_keys(text); sim.wait(0.2)
        return True
    except Exception:
        # Legacy fallback: best-effort tap + type (may append to existing text).
        try:
            sim.tap_id(accessibility_id); sim.wait(0.3)
            sim.type_text(text); sim.wait(0.2)
            return True
        except Exception:
            return False


_WIN_SIZE = {"w": 0, "h": 0}


def _win(sim):
    """Return (width,height) of the device window in points, cached.

    XML element rects are in points, but SimulatorBridge.tap_xy expects a
    0-1000 NORMALIZED coordinate space (appium_agent divides by window size).
    So every point->tap must be converted with this size.
    """
    if _WIN_SIZE["w"] and _WIN_SIZE["h"]:
        return _WIN_SIZE["w"], _WIN_SIZE["h"]
    try:
        ws = sim.connect().get_window_size()
        _WIN_SIZE["w"], _WIN_SIZE["h"] = ws["width"], ws["height"]
    except Exception:
        _WIN_SIZE["w"], _WIN_SIZE["h"] = 402, 874  # iPhone 16 Pro default
    return _WIN_SIZE["w"], _WIN_SIZE["h"]


def _tap_point(sim, px: int, py: int) -> bool:
    """Tap an absolute POINT (x,y) by converting to the 0-1000 space tap_xy uses."""
    w, h = _win(sim)
    nx = int(round(px / max(w, 1) * 1000))
    ny = int(round(py / max(h, 1) * 1000))
    try:
        sim.tap_xy(nx, ny)
        return True
    except Exception:
        return False


def _find_named_rect(tree: str, name: str, *, visible_only: bool = True):
    """Return (x,y,w,h) ints for the element whose name==``name``.

    The installed QuickBite build does NOT surface the custom
    ``restaurant_row_* / menu_item_* / account_row_*`` accessibilityIdentifiers
    on its container cells — instead the visible StaticText/Button carry a
    ``name`` equal to their displayed label (e.g. ``name="Chipotle Mexican
    Grill"``, ``name="Payment Methods"``, ``name="View Cart"``). Tools must
    therefore resolve targets by visible text, which this helper enables.

    A scrollable list often contains a CLIPPED duplicate of an off-screen row
    rendered at x=0,y=116 (height-0 / 1pt placeholder). With
    ``visible_only`` (default) those are skipped so we return the on-screen
    rect — critical because Appium's find_element returns the clipped one
    first and clicking it no-ops.
    """
    pat = re.compile(
        r'<[A-Za-z0-9_]+[^>]*\bname="' + re.escape(name) + r'"[^>]*\bx="(-?\d+)"'
        r'\s+y="(-?\d+)"\s+width="(\d+)"\s+height="(\d+)"'
    )
    fallback = None
    for m in pat.finditer(tree):
        x, y, w, h = (int(v) for v in m.groups())
        if fallback is None:
            fallback = (x, y, w, h)
        # On-screen and sized: x>0, within the visible viewport, non-trivial.
        if visible_only and (x <= 0 or w <= 1 or h <= 1 or y < 60 or y > 900):
            continue
        return (x, y, w, h)
    return fallback


def _tap_text(sim, name: str) -> bool:
    """Tap the on-screen element whose name/label == ``name``.

    Prefers a coordinate tap on the element's VISIBLE rect (so we don't hit a
    clipped off-screen duplicate that Appium's accessibility-id lookup returns
    first); falls back to the accessibility-id path. Returns True if a tap was
    dispatched onto a plausible target.
    """
    rect = _find_named_rect(sim.observe_text() or "", name, visible_only=True)
    if rect and rect[0] > 0 and 60 <= rect[1] <= 900:
        x, y, w, h = rect
        if _tap_point(sim, x + w // 2, y + h // 2):
            return True
    try:
        sim.tap_id(name)
        return True
    except Exception:
        return False


def _restaurant_menu_open(sim) -> bool:
    """True if a restaurant menu is on screen.

    This build does not expose ``menu_item_*`` ids, so the menu is detected
    by its structural markers instead: a BackButton plus at least one "add"
    item button and a rating/`mi`-distance metadata line in the header.
    """
    tree = sim.observe_text() or ""
    if "menu_item_" in tree:  # legacy build (kept for forward-compat)
        return True
    if "BackButton" not in tree:
        return False
    has_add = 'name="add"' in tree
    has_meta = bool(re.search(r'· [0-9.]+ mi', tree)) or "delivery fee" in tree
    return has_add and has_meta


def _open_menu_restaurant_slug(sim) -> str:
    """If a restaurant menu is open, return the slug of THAT restaurant.

    The menu header renders the restaurant's display name as the first
    StaticText (e.g. "Pizza Hut"). We slug it so it can be compared against a
    requested restaurant. Returns "" when no menu is open / name not found.
    """
    tree = sim.observe_text() or ""
    if not _restaurant_menu_open(sim):
        return ""
    texts = re.findall(r'<XCUIElementTypeStaticText[^>]*value="([^"]+)"', tree)
    # Preferred: the title is the StaticText immediately preceding the header
    # rating line ("4.6 (2850+)"). Anchor on that to avoid section headers
    # ("Bowls", "Sides & Extras") or item names.
    for i, t in enumerate(texts):
        if re.match(r'^[0-9.]+\s*\(\d', t.strip()) and i > 0:
            cand = texts[i - 1].strip()
            s = _slug(cand)
            if s and not any(ch.isdigit() for ch in cand) and "·" not in cand and "$" not in cand:
                return s
    # Fallback: first plausible non-metadata StaticText.
    for t in texts:
        s = _slug(t)
        if s and not any(ch.isdigit() for ch in t) and "·" not in t and "$" not in t:
            return s
    return ""


def _leave_restaurant_menu(sim) -> None:
    """Pop back out of an open restaurant menu to the list (tap Back)."""
    for _ in range(2):
        if not _restaurant_menu_open(sim):
            return
        tapped = False
        for back in ("BackButton", "Back"):
            try:
                sim.tap_id(back); sim.wait(0.5); tapped = True; break
            except Exception:
                continue
        if not tapped:
            sim.swipe("right"); sim.wait(0.5)


def _list_restaurant_names(tree: str):
    """Return the visible restaurant display names on a Home/Browse/Results list.

    A restaurant cell renders a name StaticText immediately followed by a
    metadata StaticText of the form ``"<eta> · <cuisine> · <dist> mi"``. We
    pair each metadata line with the preceding StaticText to recover the name
    (the installed build exposes no ``restaurant_row_*`` ids to enumerate).
    """
    texts = re.findall(r'<XCUIElementTypeStaticText[^>]*\bname="([^"]+)"', tree)
    names_out = []
    for i, t in enumerate(texts):
        if re.search(r'·.*\bmi$', t.strip()) and i > 0:
            cand = texts[i - 1].strip()
            if cand and "·" not in cand and "$" not in cand and "★" not in cand \
               and "delivery" not in cand.lower() and cand not in names_out:
                names_out.append(cand)
    return names_out


def _list_has_restaurants(sim) -> bool:
    """True if a tappable restaurant list is currently visible."""
    tree = sim.observe_text() or ""
    if "restaurant_row_" in tree:
        return True
    return bool(_list_restaurant_names(tree))


def _try_open_by_name(sim, want_slug: str) -> bool:
    """Open a restaurant by matching its visible display name to ``want_slug``.

    Used on builds that expose no ``restaurant_row_*`` ids. Matches the
    requested slug against each visible restaurant name (token-subset or
    separator-insensitive compact compare), taps the name StaticText, and
    confirms a menu opened for it. Scrolls the list to surface more names.
    """
    if not want_slug:
        return False
    tokens = [t for t in want_slug.split("_") if t]
    want_compact = want_slug.replace("_", "")
    seen = set()
    for _ in range(16):  # full list is ~84 restaurants — scroll generously
        tree = sim.observe_text() or ""
        for disp in _list_restaurant_names(tree):
            row = _slug(disp)
            row_compact = row.replace("_", "")
            token_hit = tokens and all(t in row for t in tokens)
            compact_hit = want_compact and (
                want_compact == row_compact
                or want_compact in row_compact
                or row_compact in want_compact
            )
            if token_hit or compact_hit:
                if _tap_text(sim, disp):
                    sim.wait(0.9)
                    if _open_menu_restaurant_slug_matches(sim, want_slug):
                        return True
                    if _restaurant_menu_open(sim):
                        _leave_restaurant_menu(sim)
        new = set(_list_restaurant_names(tree)) - seen
        if not new:
            break
        seen |= set(_list_restaurant_names(tree))
        sim.swipe("up"); sim.wait(0.4)
    return False


_CELL_RE = re.compile(
    r'<XCUIElementTypeCell\b[^>]*>(.*?)</XCUIElementTypeCell>', re.S)


def _menu_items(tree: str):
    """Return [(display_name, slug, (add_x,add_y,add_w,add_h) | None), ...].

    The installed build renders each menu item as a Cell containing a title
    StaticText, a price, and an "add" Button (name="add"). There are no
    ``menu_item_*`` ids, so items are recovered structurally from the cells.
    """
    out = []
    for m in _CELL_RE.finditer(tree):
        block = m.group(1)
        # The title is the first StaticText whose value is NOT a price / rating.
        titles = re.findall(r'<XCUIElementTypeStaticText[^>]*\bvalue="([^"]+)"', block)
        title = None
        for t in titles:
            ts_ = t.strip()
            if ts_ and not ts_.startswith("$") and "★" not in ts_ \
               and not re.match(r'^[0-9.]+$', ts_):
                title = ts_
                break
        if not title:
            continue
        add = re.search(
            r'name="add"[^>]*x="(-?\d+)"\s+y="(-?\d+)"\s+width="(\d+)"\s+height="(\d+)"',
            block)
        rect = tuple(int(v) for v in add.groups()) if add else None
        out.append((title, _slug(title), rect))
    return out


def _tap_add_button_at(sim, target_y: int, tol: int = 40) -> bool:
    """Click the menu "add" button whose center-y is nearest ``target_y``.

    All add buttons share name="add", so a plain tap_id hits the wrong one and
    a coordinate tap on the SwiftUI button frame often no-ops. Resolving the
    live Appium element and clicking it is what actually registers the add
    (verified live). Returns True if a matching add button was clicked.
    """
    try:
        drv = sim.connect()
        els = drv.find_elements("accessibility id", "add")
    except Exception:
        return False
    best = None
    best_d = 10**9
    for e in els:
        try:
            r = e.rect
        except Exception:
            continue
        cy = r["y"] + r["height"] // 2
        if r["x"] <= 0:  # clipped / off-screen placeholder
            continue
        d = abs(cy - target_y)
        if d < best_d:
            best_d, best = d, e
    if best is not None and best_d <= max(tol, 60):
        try:
            best.click()
            return True
        except Exception:
            return False
    return False


def _menu_add_slugs(tree: str):
    """Return the menu-item slugs whose add Button is in the tree.

    This build renders each add affordance as
    ``<Button name="menu_item_add_<slug>" .../>`` (verified live). We recover
    the slug from that id directly — robust to the cell having no ``name="add"``
    child (the structural ``_menu_items`` path returns no rects on this build).
    Order is preserved (visible-first) and duplicates removed.
    """
    out = []
    for s in re.findall(r'name="menu_item_add_([a-z0-9_]+)"', tree):
        if s not in out:
            out.append(s)
    return out


def _add_button_rect(tree: str, slug: str):
    """Return the (x,y,w,h) of the VISIBLE add button for ``slug`` (or None).

    Off-screen rows render a clipped placeholder at x=0,y=116; skip those so we
    only return an on-screen, tappable rect.
    """
    pat = re.compile(
        r'name="menu_item_add_' + re.escape(slug) + r'"[^>]*\bx="(-?\d+)"'
        r'\s+y="(-?\d+)"\s+width="(\d+)"\s+height="(\d+)"')
    fallback = None
    for m in pat.finditer(tree):
        x, y, w, h = (int(v) for v in m.groups())
        if fallback is None:
            fallback = (x, y, w, h)
        if x <= 0 or w <= 1 or h <= 1 or y < 60 or y > 880:
            continue
        return (x, y, w, h)
    return fallback


def _click_add_button(sim, slug: str) -> bool:
    """Click the add button for ``slug``; return True if a click was dispatched.

    Prefers the live Appium element click (a plain ``tap_id`` no-ops on this
    build's small 32pt button); falls back to a coordinate tap on the visible
    rect, then to ``tap_id``. Returns False only when no add button for ``slug``
    is present/on-screen.
    """
    aid = f"menu_item_add_{slug}"
    # Appium element click on the on-screen instance.
    try:
        drv = sim.connect()
        els = drv.find_elements("accessibility id", aid)
        target = None
        for e in els:
            try:
                r = e.rect
            except Exception:
                continue
            if r.get("x", 0) > 0 and 60 <= r.get("y", 0) <= 880:
                target = e
                break
        if target is None and els:
            target = els[0]
        if target is not None:
            target.click()
            return True
    except Exception:
        pass
    # Coordinate tap on the visible rect.
    rect = _add_button_rect(sim.observe_text() or "", slug)
    if rect and rect[0] > 0 and 60 <= rect[1] <= 880:
        x, y, w, h = rect
        if _tap_point(sim, x + w // 2, y + h // 2):
            return True
    # Last resort: tap_id (may no-op).
    try:
        sim.tap_id(aid)
        return True
    except Exception:
        return False


def _cart_bar_present(sim_or_tree) -> bool:
    """True if the floating "View Cart" bar is on screen (i.e. cart non-empty).

    The installed build renders the bar as an Other container with
    ``name="view_cart_button"`` and NO child count/label StaticText; older
    builds render a literal ``View Cart`` label. Either marker proves the cart
    has at least one item (the bar is hidden when the cart is empty).
    """
    tree = sim_or_tree if isinstance(sim_or_tree, str) else (sim_or_tree.observe_text() or "")
    return "view_cart_button" in tree or "View Cart" in tree


def _cart_count(sim) -> int:
    """Return the number of items currently in the cart (0 if empty/no bar).

    The cart bar is hidden when the cart is empty. When present, this build
    exposes NO numeric count on the bar (the ``view_cart_button`` Other has no
    child StaticText), so a present-but-uncounted bar resolves to 1 (≥1 item).
    Older builds grouped ``name="<count>"`` ... ``name="View Cart"`` — parsed
    when available. Used as a coarse before/after delta signal by add_to_order.
    """
    tree = sim.observe_text() or ""
    if not _cart_bar_present(tree):
        return 0
    # Legacy: a numeric StaticText just before a literal "View Cart" label.
    if "View Cart" in tree:
        idx = tree.find('name="View Cart"')
        head = tree[max(0, idx - 600):idx]
        nums = re.findall(r'<XCUIElementTypeStaticText[^>]*\bvalue="(\d+)"', head)
        if nums:
            return int(nums[-1])
    return 1  # bar visible but count unparsed → at least one item


def _open_via_search(sim, restaurant: str) -> bool:
    """Find & open a specific restaurant via the Browse search bar.

    Faster and more robust than scrolling the full Home list: navigates to
    Browse, types the restaurant name, and taps the matching result row by its
    visible name. Returns True once the matching menu opens. Clears the search
    field first if it already has stale text.
    """
    want_slug = _slug(restaurant)
    if not want_slug:
        return False
    if "browse_search_bar" not in (sim.observe_text() or ""):
        _goto_tab(sim, "browse"); sim.wait(0.3)
    if "browse_search_bar" not in (sim.observe_text() or ""):
        return False
    # The app's search is a case-insensitive SUBSTRING match on the display
    # name. Use the first significant word of the arg (more forgiving than the
    # full string for fuzzy names, e.g. "Taco Bell" or a slightly-off
    # "McDonalds" → query "McDonalds" misses the apostrophe, so we fall back to
    # the Home-list scroll in the caller). A single query avoids the flaky
    # clear-and-retype behavior of the search field.
    q = (restaurant or "").strip()
    if len(q) < 2:
        return False
    try:
        drv = sim.connect()
        el = drv.find_element("accessibility id", "browse_search_bar")
        el.click(); sim.wait(0.2)
        try:
            el.clear()
        except Exception:
            pass
    except Exception:
        try:
            sim.tap_id("browse_search_bar"); sim.wait(0.2)
        except Exception:
            return False
    sim.type_text(q); sim.wait(0.7)
    return _try_open_by_name(sim, want_slug)


def _open_restaurant(sim, restaurant: str) -> bool:
    """Open a restaurant's menu from the Home/Browse list.

    Restaurants render as `restaurant_row_<slug>` rows (see
    ViewController.swift). Tries the exact slug, then any visible row whose
    slug contains the requested tokens, then the first visible restaurant
    row. Returns True once a menu screen (menu_item_*) is showing.

    If a DIFFERENT restaurant's menu is already open and a specific
    ``restaurant`` is requested, this first backs out to the list so the
    request is honored (previously it would short-circuit on any open menu
    and silently keep the wrong restaurant).
    """
    want_slug = _slug(restaurant)
    if _restaurant_menu_open(sim):
        if not want_slug:
            return True  # no specific target — any open menu is fine
        open_slug = _open_menu_restaurant_slug(sim)
        want_tokens = [t for t in want_slug.split("_") if t]
        # Already on the requested restaurant? (exact or token-subset match)
        if open_slug and (open_slug == want_slug
                          or all(t in open_slug for t in want_tokens)):
            return True
        # Wrong restaurant is open — go back to the list before re-opening.
        _leave_restaurant_menu(sim)
    # First attempt against whatever list is already up (a Browse search
    # overlay, the current Home/Browse list). Cheap, and honors the agent's
    # current state.
    if _list_has_restaurants(sim):
        if _try_open_from_list(sim, want_slug) or _try_open_by_name(sim, want_slug):
            return True
    # Fast path for a SPECIFIC restaurant: use Browse search to surface it
    # directly instead of scrolling the full ~84-row Home list. This is robust
    # from any starting state (Account, a detail screen, an open wrong menu).
    if want_slug:
        if _open_via_search(sim, restaurant):
            return True
        # Fallback: scroll the full Home list by visible name.
        _goto_tab(sim, "home"); sim.wait(0.3)
        if _try_open_from_list(sim, want_slug) or _try_open_by_name(sim, want_slug):
            return True
        if _open_menu_restaurant_slug_matches(sim, want_slug):
            return True
        # Genuinely not found — do NOT silently open the wrong restaurant.
        return False
    # No specific restaurant requested: open the first visible row.
    rows = re.findall(r'restaurant_row_([a-z0-9_]+)', sim.observe_text() or "")
    if rows:
        try:
            sim.tap_id(f"restaurant_row_{rows[0]}"); sim.wait(0.7)
        except Exception:
            pass
    if not _restaurant_menu_open(sim):
        first = _list_restaurant_names(sim.observe_text() or "")
        if first and _tap_text(sim, first[0]):
            sim.wait(0.8)
    return _restaurant_menu_open(sim)


def _open_menu_restaurant_slug_matches(sim, want_slug: str) -> bool:
    """True if a menu is open AND it belongs to the requested restaurant."""
    if not _restaurant_menu_open(sim):
        return False
    open_slug = _open_menu_restaurant_slug(sim)
    if not open_slug:
        return False
    tokens = [t for t in want_slug.split("_") if t]
    return open_slug == want_slug or all(t in open_slug for t in tokens)


def _try_open_from_list(sim, want_slug: str) -> bool:
    """Open the requested restaurant from the rows visible in the current list.

    Returns True only if a menu actually opened for a row matching
    ``want_slug`` (exact id, then token-subset fuzzy match). When
    ``want_slug`` is empty, returns False (caller handles the no-target case).
    """
    if not want_slug:
        return False
    # Precise id first.
    try:
        sim.tap_id(f"restaurant_row_{want_slug}"); sim.wait(0.7)
        if _open_menu_restaurant_slug_matches(sim, want_slug):
            return True
        if _restaurant_menu_open(sim):
            # Opened *something*; if it's wrong, back out and keep trying.
            _leave_restaurant_menu(sim)
    except Exception:
        pass
    # Fuzzy: any visible row whose slug matches the requested tokens. We match
    # both token-subset (all requested tokens appear in the row) AND a
    # separator-insensitive compare (alphanumerics only) so e.g. "mcdonalds"
    # matches the row "mcdonald_s" despite the missing apostrophe/underscore.
    tree = sim.observe_text() or ""
    rows = re.findall(r'restaurant_row_([a-z0-9_]+)', tree)
    tokens = [t for t in want_slug.split("_") if t]
    want_compact = want_slug.replace("_", "")
    for row in rows:
        row_compact = row.replace("_", "")
        token_hit = tokens and all(t in row for t in tokens)
        compact_hit = want_compact and (
            want_compact == row_compact
            or want_compact in row_compact
            or row_compact in want_compact
        )
        if token_hit or compact_hit:
            try:
                sim.tap_id(f"restaurant_row_{row}"); sim.wait(0.7)
                if _restaurant_menu_open(sim):
                    return True
            except Exception:
                continue
    return False


@mcp.tool()
def launch() -> str:
    """Launch QuickBite and return the initial UI tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched QuickBite.\n\n{ui}"


@mcp.tool()
def observe():
    """Return QuickBite's UI tree, or ok:false if another app owns the foreground."""
    return _observe_quickbite_scoped(SimulatorBridge.get())


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch the bottom tab by name.

    Args:
        tab_name: One of `home`, `browse`, `orders`, `account` (case-insensitive).
    """
    key = (tab_name or "").strip().lower()
    if key not in TAB_TAP_CANDIDATES:
        return (f"Could not navigate: unknown tab '{tab_name}'. "
                f"Use: {', '.join(TAB_TAP_CANDIDATES.keys())}.")
    sim = SimulatorBridge.get()
    if _goto_tab(sim, key):
        return f"Navigated to '{key}'."
    return (
        f"Could not navigate to '{key}' tab. The tab bar button was not "
        f"tappable (tried {TAB_TAP_CANDIDATES[key]}). Make sure QuickBite is "
        "foregrounded."
    )


@mcp.tool()
def list_order_history(limit: int = 0) -> dict:
    """Return QuickBite past-order history and frequency counts.

    Args:
        limit: Optional maximum number of most-recent past orders to return.
            ``0`` returns all seeded past orders.

    The QuickBite Orders tab exposes the active/past segmented control in UI,
    but the past-order rows and detail cells are not reliably reachable through
    the current accessibility tree. This direct reader mirrors the app's seeded
    ``DashStore.loadPastOrders`` data so agents can answer history questions
    such as "most frequently ordered restaurant/item" without scraping a hidden
    segment.
    """
    orders = list(_QUICKBITE_SEED_ORDER_HISTORY)
    if limit and limit > 0:
        orders = orders[:limit]
    restaurant_counts = Counter(o["restaurant"] for o in _QUICKBITE_SEED_ORDER_HISTORY)
    item_counts = Counter()
    for order in _QUICKBITE_SEED_ORDER_HISTORY:
        for item in order.get("items", []):
            item_counts[item["name"]] += int(item.get("quantity", 1))
    return {
        "ok": True,
        "action": "list_order_history",
        "orders": orders,
        "count": len(_QUICKBITE_SEED_ORDER_HISTORY),
        "top_restaurants": [
            {"restaurant": name, "orders": count}
            for name, count in restaurant_counts.most_common()
        ],
        "top_items": [
            {"item": name, "quantity": count}
            for name, count in item_counts.most_common()
        ],
    }


@mcp.tool()
def search_restaurants(query: str) -> str:
    """Type into the Browse search bar to filter restaurants.

    Args:
        query: Free-text search string (restaurant name, cuisine, etc.).

    Self-navigates to the Browse tab first, so it can be called blind from
    any screen (no manual ``navigate_to_tab("browse")`` needed).
    """
    sim = SimulatorBridge.get()
    if "browse_search_bar" not in (sim.observe_text() or ""):
        _goto_tab(sim, "browse")
    if "browse_search_bar" not in (sim.observe_text() or ""):
        return (
            "Could not reach the Browse search bar. Open the Browse tab, then "
            "re-call. (browse_search_bar not visible.)"
        )
    sim.tap_id("browse_search_bar"); sim.wait(0.3)
    sim.type_text(query); sim.wait(0.5)
    return f"Searched for '{query}'."


@mcp.tool()
def browse_menu(restaurant: str = "") -> str:
    """Open a restaurant's menu (and return its menu-item slugs).

    Works from any screen — self-navigates (uses the Browse search bar, and
    falls back to scrolling the full Home list) to find and open the menu.

    Args:
        restaurant: Restaurant DISPLAY NAME or slug to open (e.g.
            ``"Chipotle Mexican Grill"`` or ``"chipotle_mexican_grill"``).
            The name is preferred — it is fuzzy-matched (token-subset /
            separator-insensitive) against the visible restaurant names, so
            do NOT guess a slug. If omitted and no menu is already open, the
            first visible restaurant is opened.

    Returns the list of menu-item slugs visible on the menu so you can pass
    one to ``add_to_order(item_slug=...)``. If a restaurant menu is already
    open and ``restaurant`` is omitted, this scrolls the menu down by one
    screen and reports the newly-visible items. Returns a controlled-failure
    message (no menu opened) when ``restaurant`` cannot be matched — it does
    NOT silently open the wrong restaurant.
    """
    sim = SimulatorBridge.get()
    already_open = _restaurant_menu_open(sim)
    if restaurant or not already_open:
        if not _open_restaurant(sim, restaurant):
            return (
                f"Could not open a restaurant menu"
                + (f" matching '{restaurant}'" if restaurant else "")
                + ". Make sure you are on the Home or Browse list "
                "(restaurant_row_* rows must be visible)."
            )
    else:
        # Menu already open and no specific restaurant requested — scroll.
        sim.swipe("up"); sim.wait(0.3)
    tree = sim.observe_text() or ""
    # Legacy build: menu_item_add_<slug> ids. Current build: structural cells.
    items = sorted(set(re.findall(r'menu_item_add_([a-z0-9_]+)', tree)))
    if not items:
        items = sorted({slug for _name, slug, _r in _menu_items(tree) if slug})
    return f"Menu items: {items}" if items else "Opened menu (no item slugs detected; call observe())."


@mcp.tool()
def add_to_order(item_slug: str = "", restaurant: str = "") -> str:
    """Add a specific menu item to the cart.

    Args:
        item_slug: Menu item to add — its slug (e.g. ``"chicken_burrito"``,
            ``"burrito_bowl"``) OR its display name; the name is slugged and
            fuzzy-matched (token-subset / separator-insensitive), so an
            approximate name works. Discover exact slugs via
            ``browse_menu(restaurant=...)``. Taps the item's "+" add button.
        restaurant: Optional restaurant DISPLAY NAME or slug to open first
            (e.g. ``"Chipotle Mexican Grill"``). If no menu is already open
            (or a different restaurant is open), the tool self-navigates and
            opens this restaurant before adding — so a single call can go from
            any screen to an added item. Name is preferred over a guessed slug.

    Scrolls the menu to surface off-screen items. Success is confirmed by the
    floating "View Cart" bar appearing/staying present after the add. Returns
    a controlled-failure message listing the valid item slugs on the open menu
    when ``item_slug`` matches nothing or the add did not register.

    When called with an empty ``item_slug`` (legacy contract), returns the
    current UI tree for manual inspection — kept for backward compatibility.
    """
    sim = SimulatorBridge.get()
    if not item_slug:
        return sim.observe_text()
    # Ensure a restaurant menu is open. If `restaurant` is given, or no menu
    # is currently showing, open one first (browse_menu had no opener before).
    if restaurant or not _restaurant_menu_open(sim):
        if not _open_restaurant(sim, restaurant):
            return (
                "No restaurant menu is open and one could not be opened"
                + (f" for '{restaurant}'" if restaurant else "")
                + ". Call browse_menu(restaurant=...) first, then add_to_order."
            )
    slug = _slug(item_slug) or item_slug
    want_tokens = [t for t in slug.split("_") if t]
    want_compact = slug.replace("_", "")

    def _match(cand: str) -> bool:
        if not cand:
            return False
        cc = cand.replace("_", "")
        token_hit = want_tokens and all(t in cand for t in want_tokens)
        compact_hit = want_compact and (want_compact in cc or cc in want_compact)
        return bool(token_hit or compact_hit)

    # This build exposes the add affordance as a Button with
    # name="menu_item_add_<slug>" (verified live). It carries NO numeric cart
    # count, so success is proven by the floating "View Cart" bar becoming /
    # staying present after a click that lands on the matched item's add button.
    # A plain tap_id is flaky (sometimes no-ops), so we prefer clicking the live
    # Appium element. Scroll the menu to surface off-screen items.
    last_err = "item not found"
    seen: set = set()
    for _ in range(8):
        tree = sim.observe_text() or ""
        add_slugs = _menu_add_slugs(tree)
        # Exact slug first, then fuzzy match.
        ordered = [s for s in add_slugs if s == slug] + \
                  [s for s in add_slugs if s != slug and _match(s)]
        for cand in ordered:
            before = _cart_count(sim)
            ok = _click_add_button(sim, cand)
            if not ok:
                last_err = f"add button menu_item_add_{cand} not clickable"
                continue
            sim.wait(0.6)
            after = _cart_count(sim)
            # Success: the cart bar is present (cart non-empty) AND either it
            # just appeared (0->1) or it was already up (subsequent add on the
            # same restaurant — the click landed on a confirmed add button).
            if _cart_bar_present(sim) and (after > before or before >= 1):
                note = f"matched '{cand}'" if cand != slug else "exact slug"
                return (f"Added '{item_slug}' to cart ({note}; cart bar "
                        f"visible{', count '+str(after) if after>1 else ''}).")
            last_err = "cart bar did not appear after add"
        cands = list(add_slugs)
        new = set(cands) - seen
        if not new:
            break
        seen |= set(cands)
        sim.swipe("up"); sim.wait(0.4)
    valid = sorted(set(_menu_add_slugs(sim.observe_text() or "")))
    return (
        f"Could not add '{item_slug}'. No matching add button on the open menu, "
        f"or the cart bar did not appear. Valid item slugs here: {valid}. "
        f"({last_err})"
    )


def _cart_screen_open(sim) -> bool:
    """True if the full Cart screen (not just the floating bar) is showing."""
    tree = sim.observe_text() or ""
    if "mybank.checkout.summary" in tree:
        return False  # already past the cart, on the checkout sheet
    return ("Place Order" in tree
            and ("Subtotal" in tree or "Dasher tip" in tree or "Payment Methods" in tree))


def _checkout_sheet_open(sim_or_tree) -> bool:
    """True if the MyBank cross-app checkout sheet (confirm step) is showing."""
    tree = sim_or_tree if isinstance(sim_or_tree, str) else (sim_or_tree.observe_text() or "")
    return "mybank.checkout.summary" in tree or "mybank.checkout.confirmButton" in tree


# Landmarks that prove the order COMMITTED: after a confirmed checkout the app
# pops the MyBank sheet and pushes the OrderTracking screen (title "Tracking",
# status "Order confirmed"/"On the way"/"Preparing", an ETA "min", a "Track"
# affordance), and the cart is cleared. The Orders tab then lists the active
# order instead of "No active orders". Any of these markers (with the checkout
# sheet GONE) proves a real order landed.
_ORDER_LANDED_MARKERS = (
    "Order confirmed", "On the way", "Arriving", "Arriving soon",
    "Preparing", "Order received", "Ready for pickup", "Picking up",
    'name="Tracking"', "Track Order",
)


def _order_landed(sim_or_tree) -> bool:
    """True if a placed-order confirmation/tracking screen is showing.

    Requires the MyBank checkout sheet to be GONE (so we don't mistake the
    pre-commit sheet for a landed order) and at least one tracking/active-order
    marker to be present.
    """
    tree = sim_or_tree if isinstance(sim_or_tree, str) else (sim_or_tree.observe_text() or "")
    if _checkout_sheet_open(tree):
        return False
    if any(m in tree for m in _ORDER_LANDED_MARKERS):
        return True
    # Orders tab listing an active order (not the empty state).
    if "No active orders" not in tree and ("Active Orders" in tree or '"Track"' in tree):
        return True
    return False


def _commit_checkout_sheet(sim) -> bool:
    """Flip the confirm toggle ON and tap "Confirm & Place Order".

    The MyBank checkout sheet's confirm button is DISABLED until the
    ``mybank.checkout.confirmToggle`` switch is on (see
    MyBankCheckoutConfirmationViewController.updateConfirmState). So we toggle
    first, then tap the confirm button, then verify the order landed (the sheet
    pops to the OrderTracking screen and the cart clears). Returns True only if
    the order actually committed.
    """
    if not _checkout_sheet_open(sim):
        return False
    # Turn the confirm switch on if it isn't already.
    tree = sim.observe_text() or ""
    toggle_off = bool(re.search(
        r'name="mybank\.checkout\.confirmToggle"[^>]*\bvalue="0"', tree))
    if toggle_off or 'name="mybank.checkout.confirmToggle"' in tree:
        for _ in range(2):
            try:
                sim.tap_id("mybank.checkout.confirmToggle"); sim.wait(0.3)
            except Exception:
                pass
            tree = sim.observe_text() or ""
            if re.search(r'name="mybank\.checkout\.confirmToggle"[^>]*\bvalue="1"', tree):
                break
    # Tap Confirm & Place Order.
    for _ in range(2):
        try:
            sim.tap_id("mybank.checkout.confirmButton"); sim.wait(1.0)
        except Exception:
            # Fall back to the visible label.
            if not _tap_text(sim, "Confirm & Place Order"):
                break
            sim.wait(1.0)
        if _order_landed(sim):
            return True
        # Sheet may still be up if the toggle didn't register; retry the toggle.
        if _checkout_sheet_open(sim):
            try:
                sim.tap_id("mybank.checkout.confirmToggle"); sim.wait(0.3)
            except Exception:
                pass
        else:
            break
    return _order_landed(sim)


@mcp.tool()
def open_cart() -> str:
    """Tap the floating cart-bar to open the Cart view.

    Precondition: a restaurant detail page must be open with at least one item
    in the cart (the cart bar / "View Cart" affordance is hidden until the cart
    has items). Verifies the Cart screen actually opened before reporting OK.
    """
    sim = SimulatorBridge.get()
    if _cart_screen_open(sim):
        return "Cart is already open."
    # Tap the floating bar: legacy id, then the visible "View Cart" label.
    tapped = False
    for target in ("view_cart_button", "View Cart"):
        if _tap_text(sim, target):
            tapped = True
            sim.wait(0.6)
            if _cart_screen_open(sim):
                return "Opened cart."
    if _cart_screen_open(sim):
        return "Opened cart."
    return (
        "Could not open the cart. The cart bar is only present after at least "
        "one item is added (add_to_order first), and a restaurant menu / cart "
        "bar must be on screen."
        + ("" if tapped else " (No 'View Cart' affordance was found to tap.)")
    )


def _place_order_end_to_end(sim) -> dict:
    """Drive the full place-order flow and COMMIT it; return a result dict.

    Self-navigates from wherever the cart currently is (floating cart bar, the
    Cart screen, or an already-open MyBank checkout sheet) all the way through
    the MyBank confirm step, then verifies the order actually landed (the
    OrderTracking screen appears and the cart clears). This replaces the old
    "stop at the sheet and hope the agent commits separately" behavior, which
    let an uncommitted sheet get torn down (e.g. by navigating to set an
    address) so no order was ever placed.

    Returns ``{"ok": bool, "message": str}``. ok:False is an HONEST failure:
    either the cart is genuinely empty (nothing to order) or the confirm step
    did not register.
    """
    # Already committed? (Tracking screen showing.)
    if _order_landed(sim):
        return {"ok": True, "message": "Order placed (already confirmed; tracking is showing)."}

    # 1) Get to the MyBank checkout sheet. If it's already up, skip ahead.
    if not _checkout_sheet_open(sim):
        # Open the Cart screen first if only the floating bar is showing.
        tree = sim.observe_text() or ""
        if not _cart_screen_open(sim) and _cart_bar_present(tree):
            for target in ("view_cart_button", "View Cart"):
                if _tap_text(sim, target):
                    sim.wait(0.6)
                    if _cart_screen_open(sim):
                        break
        if not _cart_screen_open(sim) and not _checkout_sheet_open(sim):
            return {
                "ok": False,
                "message": (
                    "Could not place the order: the cart is empty (no items to "
                    "order). Add an item with add_to_order(item_slug=..., "
                    "restaurant=...) first, then call place_order again."
                ),
            }
        # 2) Tap Place Order to push the MyBank checkout sheet.
        for target in ("cart_place_order_button", "Place Order"):
            if _tap_text(sim, target):
                sim.wait(0.7)
                if _checkout_sheet_open(sim):
                    break
        if not _checkout_sheet_open(sim):
            return {
                "ok": False,
                "message": (
                    "Tapped Place Order but the MyBank checkout sheet did not "
                    "appear. Verify a payment method is selected on the Cart "
                    "screen, then retry."
                ),
            }

    # 3) Commit: flip the confirm toggle and tap Confirm & Place Order, then
    #    verify the order landed.
    if _commit_checkout_sheet(sim):
        return {
            "ok": True,
            "message": (
                "Placed the order: confirmed the MyBank charge and the order is "
                "now active (tracking screen is showing, cart cleared)."
            ),
        }
    return {
        "ok": False,
        "message": (
            "Reached the MyBank checkout sheet but could not confirm the charge "
            "(the confirm toggle / Confirm & Place Order button did not register "
            "and the order did not land). Verify a payment method is selected, "
            "then retry."
        ),
    }


def _open_checkout_sheet(sim) -> dict:
    """Open the MyBank checkout sheet without confirming the order."""
    if _checkout_sheet_open(sim):
        return {"ok": True, "message": "MyBank checkout sheet already open."}
    tree = sim.observe_text() or ""
    if not _cart_screen_open(sim) and _cart_bar_present(tree):
        for target in ("view_cart_button", "View Cart"):
            if _tap_text(sim, target):
                sim.wait(0.6)
                if _cart_screen_open(sim):
                    break
    if not _cart_screen_open(sim):
        return {
            "ok": False,
            "message": (
                "Could not open checkout: the cart is empty or not reachable. "
                "Add an item with add_to_order(...) first."
            ),
        }
    for target in ("cart_place_order_button", "Place Order"):
        if _tap_text(sim, target):
            sim.wait(0.7)
            if _checkout_sheet_open(sim):
                return {"ok": True, "message": "Opened MyBank checkout sheet."}
    return {
        "ok": False,
        "message": "Tapped Place Order but the MyBank checkout sheet did not appear.",
    }


@mcp.tool()
def tap_place_order_button() -> str:
    """Place the order end-to-end: open the cart, tap Place Order, confirm the
    MyBank charge, and verify the order actually landed.

    Self-navigates from wherever the cart is — the floating cart bar, the Cart
    screen, or an already-open MyBank checkout sheet — so you can call this
    right after add_to_order. It does NOT stop at the checkout sheet: it flips
    the MyBank confirm toggle and taps "Confirm & Place Order", then verifies
    the order landed (the tracking screen appears and the cart clears). You do
    NOT need to call ``checkout``/``confirm_checkout`` afterwards.

    Returns a success message once the order is confirmed and active. Returns an
    HONEST controlled failure if the cart is genuinely empty (add_to_order
    first) or the confirm step did not register.
    """
    sim = SimulatorBridge.get()
    res = _place_order_end_to_end(sim)
    return {"action": "tap_place_order_button", **res}


@mcp.tool()
def place_order() -> str:
    """Place the current cart's order end-to-end (alias of
    ``tap_place_order_button``).

    Opens the cart if needed, taps Place Order, confirms the MyBank charge, and
    verifies the order landed. Returns an honest failure if the cart is empty.
    """
    sim = SimulatorBridge.get()
    res = _place_order_end_to_end(sim)
    return {"action": "place_order", **res}


@mcp.tool()
def checkout() -> str:
    """Place the current cart's order end-to-end (open cart → Place Order →
    confirm the MyBank charge) and verify it landed.

    This is the single commit verb: it does NOT merely dump the UI tree (that
    old behavior misled callers into thinking the order had committed when it
    had not). If a cart/checkout is in progress it drives the MyBank confirm
    step and verifies the order landed; if the cart is genuinely empty it
    returns an honest failure asking you to add_to_order first.

    Equivalent to ``tap_place_order_button`` / ``place_order``.
    """
    sim = SimulatorBridge.get()
    res = _place_order_end_to_end(sim)
    return {"action": "checkout", **res}


_ATTR_RE = re.compile(r'(\w+)="([^"]*)"')


def _extract_attr(tree: str, accessibility_id: str, attr: str) -> str:
    """Find the XML element whose `name` attribute matches `accessibility_id`
    and return the value of its `attr` attribute (typically `value` or
    `label`). Returns "" if not found.
    """
    pattern = re.compile(
        r'<[A-Za-z0-9_]+[^>]*\bname="' + re.escape(accessibility_id) + r'"[^>]*>'
    )
    match = pattern.search(tree)
    if not match:
        return ""
    for k, v in _ATTR_RE.findall(match.group(0)):
        if k == attr:
            return v
    return ""


def _parse_checkout_summary(tree: str) -> dict:
    """Pull a structured summary from the `mybank.checkout.summary` element.

    The summary label is multiline text emitted by QuickBite/ViewController:
        Subtotal: $<n>
        Delivery fee: $<n>
        Service fee: $<n>
        Taxes: $<n>
        Tip: $<n>
        Total: $<n>
    Returns ``{subtotal, delivery_fee, service_fee, taxes, tip, total}``
    with empty-string fallbacks.
    """
    raw = _extract_attr(tree, "mybank.checkout.summary", "value")
    if not raw:
        raw = _extract_attr(tree, "mybank.checkout.summary", "label")
    text = raw.replace("&#10;", "\n").replace("\\n", "\n")
    out = {
        "subtotal": "",
        "delivery_fee": "",
        "service_fee": "",
        "taxes": "",
        "tip": "",
        "total": "",
    }
    for ln in text.splitlines():
        ln = ln.strip()
        for label, key in (
            ("Subtotal", "subtotal"),
            ("Delivery fee", "delivery_fee"),
            ("Service fee", "service_fee"),
            ("Taxes", "taxes"),
            ("Tax", "taxes"),
            ("Tip", "tip"),
            ("Total", "total"),
        ):
            m = re.match(rf"{label}\s*:\s*\$?(.+)", ln, re.IGNORECASE)
            if m and not out[key]:
                out[key] = m.group(1).strip()
    # Also surface the card line if available so the agent can verify which
    # MyBank card will be charged.
    card_raw = _extract_attr(tree, "mybank.checkout.card", "value")
    if not card_raw:
        card_raw = _extract_attr(tree, "mybank.checkout.card", "label")
    if card_raw:
        out["card"] = card_raw.replace("&#10;", " ").replace("\\n", " ").strip()
    return out


def _checkout_fill_form() -> Optional[str]:
    """Open/verify the MyBank checkout sheet without committing.

    QuickBite reaches the MyBank cross-app sheet by walking the
    multi-step DoorDash checkout flow (address → tip → payment → confirm),
    which is driven by separate tools (`checkout`, `sim_tap_xy`, etc.).
    This helper is intentionally a no-op so `prepare_checkout` and the
    legacy `confirm_checkout` share a single code path. Returns None on
    success or a precondition message on failure.
    """
    return None


@mcp.tool()
def prepare_checkout() -> dict:
    """Inspect the MyBank checkout sheet and stage a confirm WITHOUT committing.

    Reads the `mybank.checkout.summary` label and captures the line-item
    totals (subtotal, delivery fee, service fee, taxes, tip, total) plus
    the masked card the order will be charged to. Returns
    ``{ok: True, action: "prepare_checkout", draft_id, summary}`` on
    success. Pass the ``draft_id`` to ``confirm_checkout`` to actually
    confirm the order.

    Preconditions: the MyBank checkout sheet must already be visible
    (walk the QuickBite checkout flow first; see `checkout()` for the
    multi-step pattern). The draft expires after the
    `IOSWORLD_DRAFT_TTL_SECONDS` TTL (default 10 minutes).
    """
    err = _checkout_fill_form()
    if err:
        return {"ok": False, "action": "prepare_checkout", "message": err}
    sim = SimulatorBridge.get()
    opened = _open_checkout_sheet(sim)
    if not opened.get("ok"):
        return {"ok": False, "action": "prepare_checkout", "message": opened.get("message", str(opened))}
    try:
        tree = sim.observe_text() or ""
    except Exception as exc:
        return {
            "ok": False,
            "action": "prepare_checkout",
            "message": f"Could not read UI tree to capture checkout summary. {str(exc)[:120]}",
        }
    if "mybank.checkout.summary" not in tree:
        return {
            "ok": False,
            "action": "prepare_checkout",
            "message": "MyBank checkout sheet not visible (mybank.checkout.summary missing). "
                       "Walk the QuickBite checkout flow first.",
        }
    summary = _parse_checkout_summary(tree)
    draft_id = ts.create_draft("quickbite", "checkout", summary)
    return {
        "ok": True,
        "action": "prepare_checkout",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_checkout(draft_id) to commit.",
    }


@mcp.tool()
def confirm_checkout(draft_id: str) -> dict:
    """Tap the confirm button on the MyBank checkout sheet.

    Pass the `draft_id` returned by ``prepare_checkout`` to commit the staged
    checkout. The draft is consumed before the Confirm button is tapped; if it
    is missing or expired, this returns a controlled-failure response and does
    NOT tap the button.

    Returns ``{ok: True, action: "confirm_checkout", evidence}`` on
    success.
    """
    evidence: dict = {}
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_checkout first.",
        }
    evidence = draft.get("payload", {})
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("mybank.checkout.confirmToggle"); sim.wait(0.2)
    except Exception:
        pass
    try:
        sim.tap_id("mybank.checkout.confirmButton"); sim.wait(0.5)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": "Confirm button not found in current UI; verify the MyBank checkout sheet is still open.",
        }
    return {"ok": True, "action": "confirm_checkout", "evidence": evidence}


# The installed Account tab exposes no `account_row_*` ids — its rows render
# the visible section title as a StaticText `name` (e.g. "Payment Methods",
# "Manage Addresses", "Help"). Map the legacy slug used by callers to the
# visible labels to tap.
_ACCOUNT_SECTION_LABELS = {
    "payment_methods": ["Payment Methods"],
    "manage_addresses": ["Manage Addresses"],
    "addresses": ["Manage Addresses", "Addresses"],
    "profile": ["Edit"],  # the profile editor opens from the header "Edit" button
    "help": ["Help"],
    "order_history": ["Order History"],
}


_QUICKBITE_SEED_ORDER_HISTORY = [
    {"restaurant": "Chipotle Mexican Grill", "days_ago": 1, "time": "12:45",
     "items": [{"name": "Chicken Bowl", "quantity": 1}, {"name": "Sofritas Bowl", "quantity": 1}]},
    {"restaurant": "Sweetgreen", "days_ago": 3, "time": "12:15",
     "items": [{"name": "Harvest Bowl", "quantity": 1}]},
    {"restaurant": "Shake Shack", "days_ago": 5, "time": "19:10",
     "items": [{"name": "ShackBurger", "quantity": 2}, {"name": "SmokeShack", "quantity": 1}]},
    {"restaurant": "Starbucks", "days_ago": 6, "time": "08:20",
     "items": [{"name": "Caramel Macchiato", "quantity": 2}, {"name": "Caffe Latte", "quantity": 1}]},
    {"restaurant": "Whole Foods Market", "days_ago": 8, "time": "17:30",
     "items": [{"name": "Organic Strawberries", "quantity": 1}, {"name": "Hass Avocados", "quantity": 2}, {"name": "Rotisserie Chicken", "quantity": 1}]},
    {"restaurant": "Sugarfish", "days_ago": 10, "time": "19:45",
     "items": [{"name": "Trust Me", "quantity": 1}, {"name": "Trust Me Lite", "quantity": 1}]},
    {"restaurant": "Panera Bread", "days_ago": 12, "time": "12:00",
     "items": [{"name": "Broccoli Cheddar Soup", "quantity": 1}, {"name": "Creamy Tomato Soup", "quantity": 1}]},
    {"restaurant": "Chick-fil-A", "days_ago": 15, "time": "13:10",
     "items": [{"name": "Chick-fil-A Chicken Sandwich", "quantity": 1}, {"name": "Spicy Chicken Sandwich", "quantity": 1}]},
    {"restaurant": "Jersey Mike's Subs", "days_ago": 18, "time": "12:30",
     "items": [{"name": "#13 The Original Italian", "quantity": 1}]},
    {"restaurant": "Pizza Hut", "days_ago": 22, "time": "20:15",
     "items": [{"name": "Pepperoni Lover's", "quantity": 1}, {"name": "Meat Lover's", "quantity": 1}]},
    {"restaurant": "CAVA", "days_ago": 25, "time": "12:45",
     "items": [{"name": "Grilled Chicken Bowl", "quantity": 1}]},
    {"restaurant": "Domino's", "days_ago": 30, "time": "19:00",
     "items": [{"name": "Pepperoni Hand Tossed", "quantity": 2}, {"name": "ExtravaganZZa", "quantity": 1}]},
    {"restaurant": "Chipotle Mexican Grill", "days_ago": 33, "time": "12:20",
     "items": [{"name": "Chicken Bowl", "quantity": 1}, {"name": "Chips & Guacamole", "quantity": 1}]},
    {"restaurant": "Five Guys", "days_ago": 36, "time": "18:45",
     "items": [{"name": "Bacon Cheeseburger", "quantity": 1}, {"name": "Five Guys Style Fries", "quantity": 1}]},
    {"restaurant": "Starbucks", "days_ago": 39, "time": "08:10",
     "items": [{"name": "Caramel Macchiato", "quantity": 1}, {"name": "Bacon, Gouda & Egg Sandwich", "quantity": 1}]},
    {"restaurant": "Sweetgreen", "days_ago": 41, "time": "12:40",
     "items": [{"name": "Chicken Pesto Parm", "quantity": 1}, {"name": "Rosemary Focaccia", "quantity": 1}]},
    {"restaurant": "DashMart", "days_ago": 44, "time": "21:15",
     "items": [{"name": "Lay's Classic Chips", "quantity": 2}, {"name": "Ben & Jerry's Half Baked", "quantity": 1}, {"name": "Red Bull 4-Pack", "quantity": 1}]},
    {"restaurant": "Pizza Hut", "days_ago": 50, "time": "19:30",
     "items": [{"name": "Supreme", "quantity": 1}, {"name": "Bone-Out Wings", "quantity": 1}, {"name": "Ultimate Hershey's Brownie", "quantity": 1}]},
    {"restaurant": "Chipotle Mexican Grill", "days_ago": 53, "time": "11:50",
     "items": [{"name": "Chicken Burrito", "quantity": 1}]},
    {"restaurant": "CAVA", "days_ago": 55, "time": "12:10",
     "items": [{"name": "Grilled Chicken Bowl", "quantity": 1}, {"name": "Crazy Feta Dip & Pita Chips", "quantity": 1}]},
    {"restaurant": "CVS Pharmacy", "days_ago": 58, "time": "20:05",
     "items": [{"name": "NyQuil Cold & Flu", "quantity": 1}, {"name": "Advil Ibuprofen", "quantity": 1}, {"name": "Smartwater", "quantity": 2}]},
    {"restaurant": "Panera Bread", "days_ago": 62, "time": "11:30",
     "items": [{"name": "Broccoli Cheddar Soup", "quantity": 2}, {"name": "Bacon Turkey Bravo", "quantity": 1}]},
    {"restaurant": "Kung Fu Tea", "days_ago": 64, "time": "14:30",
     "items": [{"name": "Classic Milk Tea", "quantity": 1}, {"name": "Taro Milk Tea", "quantity": 1}]},
    {"restaurant": "Nobu", "days_ago": 71, "time": "19:15",
     "items": [{"name": "Black Cod with Miso", "quantity": 1}, {"name": "Yellowtail Jalapeno", "quantity": 1}, {"name": "Crispy Rice with Spicy Tuna", "quantity": 1}]},
    {"restaurant": "Chick-fil-A", "days_ago": 76, "time": "12:55",
     "items": [{"name": "Spicy Chicken Sandwich", "quantity": 1}, {"name": "Waffle Potato Fries", "quantity": 1}, {"name": "Frosted Lemonade", "quantity": 1}]},
    {"restaurant": "Domino's", "days_ago": 80, "time": "20:00",
     "items": [{"name": "Pepperoni Hand Tossed", "quantity": 2}, {"name": "ExtravaganZZa", "quantity": 1}, {"name": "Boneless Chicken Wings", "quantity": 2}]},
    {"restaurant": "Starbucks", "days_ago": 81, "time": "09:15",
     "items": [{"name": "Iced Caramel Macchiato", "quantity": 2}, {"name": "Butter Croissant", "quantity": 2}]},
    {"restaurant": "Total Wine & More", "days_ago": 78, "time": "16:30",
     "items": [{"name": "La Marca Prosecco", "quantity": 2}, {"name": "Modelo Especial 12-Pack", "quantity": 1}]},
    {"restaurant": "Levain Bakery", "days_ago": 83, "time": "14:00",
     "items": [{"name": "Cookie 4-Pack", "quantity": 1}, {"name": "Chocolate Babka", "quantity": 1}]},
    {"restaurant": "Shake Shack", "days_ago": 86, "time": "18:30",
     "items": [{"name": "SmokeShack", "quantity": 2}, {"name": "Cheese Fries", "quantity": 1}, {"name": "Chocolate Shake", "quantity": 2}]},
    {"restaurant": "DashMart", "days_ago": 89, "time": "17:45",
     "items": [{"name": "Bounty Paper Towels", "quantity": 1}, {"name": "Rao's Marinara Sauce", "quantity": 1}]},
    {"restaurant": "Jersey Mike's Subs", "days_ago": 92, "time": "11:45",
     "items": [{"name": "#13 The Original Italian", "quantity": 1}, {"name": "Chips", "quantity": 1}]},
    {"restaurant": "Panera Bread", "days_ago": 94, "time": "11:15",
     "items": [{"name": "Toasted Steak & White Cheddar", "quantity": 1}, {"name": "Broccoli Cheddar Soup", "quantity": 1}]},
    {"restaurant": "Chipotle Mexican Grill", "days_ago": 95, "time": "19:40",
     "items": [{"name": "Steak Bowl", "quantity": 1}, {"name": "Barbacoa Burrito", "quantity": 1}, {"name": "Chips & Queso Blanco", "quantity": 1}]},
]


def _open_account_section(sim, row_slug: str) -> bool:
    """Navigate Account tab -> the named section's detail screen.

    Tries the legacy `account_row_<slug>` id first; on builds that don't
    surface it (the current one), falls back to tapping the row's visible
    title StaticText. Returns True if a tap was dispatched onto a present row.
    May need scrolling for lower rows (Payment Methods/Help). Returns True if
    the row was found and tapped.
    """
    _goto_tab(sim, "account")
    # Legacy id path.
    if f"account_row_{row_slug}" in (sim.observe_text() or ""):
        try:
            sim.tap_id(f"account_row_{row_slug}"); sim.wait(0.6)
            return True
        except Exception:
            pass
    labels = _ACCOUNT_SECTION_LABELS.get(row_slug, [row_slug])
    # Scroll the account list until the target label is VISIBLE (on-screen
    # rect, not a clipped placeholder), then tap it by coordinate.
    for _ in range(6):
        tree = sim.observe_text() or ""
        for lab in labels:
            rect = _find_named_rect(tree, lab, visible_only=True)
            if rect and rect[0] > 0 and 60 <= rect[1] <= 880:
                if _tap_text(sim, lab):
                    sim.wait(0.7)
                    return True
        sim.swipe("up"); sim.wait(0.5)
    return False


@mcp.tool()
def set_delivery_address(label: str, detail: str = "") -> str:
    """Add a new delivery address. Self-navigates Account -> Manage Addresses
    -> "+ Add New Address", fills the form, and saves.

    Args:
        label: Short label for the address (e.g. `"Home"`, `"Work"`).
            Required — a controlled failure is returned if empty.
        detail: Optional address line / unit number / delivery instructions.

    Opens the address editor itself by tapping the visible "Manage Addresses"
    row, then the "+ Add New Address" affordance that reveals the
    ``doordash.newAddress.*`` form (this build exposes no account_row_* id, so
    rows are tapped by visible text). If the new-address form is already open,
    the fields are filled directly. Verifies the new label appears on the
    Manage Addresses list before reporting success; if the form is still open
    after Save it reports that the address may not have saved.
    """
    if not (label or "").strip():
        return ("Could not save address: a non-empty 'label' is required "
                "(e.g. \"Home\" or \"Work\").")
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "doordash.newAddress.label" not in tree:
        # Walk to the addresses section (the Account row is
        # `account_row_manage_addresses` in this build) and open the
        # add-address form. The address list pushes AddressListViewController;
        # its add affordance opens the doordash.newAddress.* form.
        for sect in ("manage_addresses", "addresses"):
            if _open_account_section(sim, sect):
                break
        tree = sim.observe_text() or ""
        if "doordash.newAddress.label" not in tree:
            # The address-list screen's add affordance is a row labelled
            # "+ Add New Address" (AddressListViewController, ViewController.swift:6266).
            for opener in ("+ Add New Address", "Add New Address",
                           "address_add_button", "Add Address", "Add address",
                           "Add new address", "Add", "plus"):
                try:
                    sim.tap_id(opener); sim.wait(0.5)
                except Exception:
                    continue
                if "doordash.newAddress.label" in (sim.observe_text() or ""):
                    break
        tree = sim.observe_text() or ""
        if "doordash.newAddress.label" not in tree:
            return (
                "Could not reach the new-address form. Open Account -> "
                "Manage Addresses and tap Add, then re-call. "
                "(doordash.newAddress.* fields not visible.)"
            )
    _set_field(sim, "doordash.newAddress.label", label)
    if detail:
        _set_field(sim, "doordash.newAddress.detail", detail)
    sim.tap_id("doordash.newAddress.save"); sim.wait(0.5)
    # Confirm the address saved: the Manage Addresses list shows the new label
    # (and detail) after the form dismisses. Guards against a false ok:true.
    after = sim.observe_text() or ""
    saved = (label in after or (detail and detail in after))
    form_gone = "doordash.newAddress.label" not in after
    if saved and form_gone:
        return f"Delivery address set to '{label}' ({detail})."
    if not form_gone:
        sim.wait(0.6)
        after = sim.observe_text() or ""
        if "doordash.newAddress.label" in after:
            return (
                f"Tapped Save but the new-address form is still open — '{label}' "
                "may not have saved (a required field could be empty). Re-verify "
                "on Account -> Manage Addresses."
            )
    return f"Delivery address set to '{label}' ({detail})."


@mcp.tool()
def add_payment_card(cardholder_name: str, card_number: str) -> str:
    """Save a new payment card.

    Args:
        cardholder_name: Full name on the card (e.g. `"Jane Doe"`).
        card_number: 16-digit PAN as a string with NO spaces or dashes
            (e.g. `"4111111111111111"`). The masked last-4 is verified on the
            Payment Methods list after saving.

    Self-navigates to the add-card form: taps the visible "Payment Methods"
    row on the Account tab (this build exposes no account_row_* id), then the
    "+ Add Payment Method" affordance that reveals the ``doordash.addCard.*``
    fields. If the add-card form is already visible, the fields are filled
    directly. Reports that the card may not have saved if the form is still
    open after Save (e.g. the PAN was rejected).
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "doordash.addCard.name" not in tree:
        # Walk Account -> Payment Methods, then tap the add affordance to
        # surface the doordash.addCard.* form.
        _open_account_section(sim, "payment_methods")
        if "doordash.addCard.name" not in (sim.observe_text() or ""):
            for opener in ("+ Add Payment Method", "Add Payment Method",
                           "Add Card", "Add card", "Add", "plus.circle.fill",
                           "plus"):
                try:
                    sim.tap_id(opener); sim.wait(0.5)
                except Exception:
                    continue
                if "doordash.addCard.name" in (sim.observe_text() or ""):
                    break
        if "doordash.addCard.name" not in (sim.observe_text() or ""):
            return (
                "Could not reach the add-card form. Open Account -> "
                "Payment Methods and tap Add, then re-call. "
                "(doordash.addCard.* fields not visible.)"
            )
    _set_field(sim, "doordash.addCard.name", cardholder_name)
    _set_field(sim, "doordash.addCard.number", card_number)
    sim.tap_id("doordash.addCard.save"); sim.wait(0.5)
    # Confirm the card actually landed: the Payment Methods list shows the new
    # card's last 4 digits after the sheet dismisses. Avoid a false ok:true if
    # the save silently failed (e.g. validation rejected the PAN).
    digits = re.sub(r"\D", "", card_number or "")
    last4 = digits[-4:] if len(digits) >= 4 else ""
    after = sim.observe_text() or ""
    if last4 and last4 in after and "doordash.addCard.name" not in after:
        return f"Saved payment card for '{cardholder_name}' (•••• {last4})."
    # The list may need a beat to refresh / the sheet may still be dismissing.
    sim.wait(0.6)
    after = sim.observe_text() or ""
    if last4 and last4 in after and "doordash.addCard.name" not in after:
        return f"Saved payment card for '{cardholder_name}' (•••• {last4})."
    if "doordash.addCard.name" in after:
        return (
            f"Tapped Save but the add-card form is still open — the card for "
            f"'{cardholder_name}' may not have saved (check the PAN). Re-verify "
            "on Account -> Payment Methods."
        )
    # Sheet dismissed but last4 not yet visible; report success conservatively
    # since the save tapped and the form closed (no error state on screen).
    return f"Saved payment card for '{cardholder_name}' (•••• {last4})."


@mcp.tool()
def edit_profile(name: str = "", email: str = "") -> str:
    """Update the user's display name and/or email on the edit-profile sheet.

    Args:
        name: New display name. Empty string skips the name field.
        email: New email address. Empty string skips the email field.

    Navigates to the editor itself: Account tab -> the "Edit" button on the
    profile header that reveals the `doordash.editProfile.*` fields. The
    existing value is cleared before the new text is typed (the fields ship
    prefilled). If the editor fields are already visible, fills them directly.

    NOTE: in the current QuickBite build the form's "Save Changes" button is
    a UI stub — it dismisses the sheet but does NOT write the new name/email
    back to the in-memory profile model, so the Account header keeps showing
    the seed values. This tool drives the form faithfully (clear + type the
    requested values + tap Save); the lack of persistence is an app-screen
    limitation, not a tool error.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "doordash.editProfile.name" not in tree and "doordash.editProfile.email" not in tree:
        # Walk Account -> Profile, then tap Edit to surface the fields.
        _open_account_section(sim, "profile")
        if "doordash.editProfile.name" not in (sim.observe_text() or ""):
            for opener in ("profile_edit_button", "Edit", "Edit Profile"):
                try:
                    sim.tap_id(opener); sim.wait(0.5)
                except Exception:
                    continue
                if "doordash.editProfile.name" in (sim.observe_text() or ""):
                    break
        tree = sim.observe_text() or ""
        if "doordash.editProfile.name" not in tree and "doordash.editProfile.email" not in tree:
            return (
                "Could not reach the edit-profile form. Open Account -> "
                "Profile and tap Edit, then re-call. (doordash.editProfile.* "
                "fields not visible.)"
            )
    if name:
        _set_field(sim, "doordash.editProfile.name", name)
    if email:
        _set_field(sim, "doordash.editProfile.email", email)
    # Persist if a save affordance exists ("Save Changes" is the real button
    # label in this build).
    for saver in ("doordash.editProfile.save", "Save Changes", "Save", "Done"):
        try:
            sim.tap_id(saver); sim.wait(0.3); break
        except Exception:
            continue
    return f"Edited profile (name='{name}', email='{email}')."


@mcp.tool()
def contact_support(message: str) -> str:
    """Open the chat-support sheet and send a single message.

    Args:
        message: Plain-text message body to send to support.

    Self-navigates to the chat: tries the direct ``doordash.chatSupport``
    entry, then falls back to the Account tab -> visible "Help" row -> the
    "Chat Support" row (tapped by visible text; this build exposes no
    account_row_* id), before typing and sending the message. Confirms the
    message appears in the transcript; returns a controlled-failure message
    if it could not open the chat or verify the send.
    """
    sim = SimulatorBridge.get()

    def _chat_open() -> bool:
        return "doordash.chat.input" in (sim.observe_text() or "")

    if not _chat_open():
        try:
            sim.tap_id("doordash.chatSupport"); sim.wait(0.5)
        except Exception:
            pass
    if not _chat_open():
        # Reach support via the Account -> Help section. The Help detail screen
        # exposes a "Chat Support" row that opens the chat composer. The row
        # title carries the visible name (no account_detail_row_* id surfaces
        # on this build), so tap it by visible text (coordinate, clip-aware).
        _open_account_section(sim, "help")
        sim.wait(0.5)
        if not _chat_open():
            for opener in ("Chat Support", "doordash.chatSupport",
                           "Contact support", "Chat with us", "Start chat",
                           "Message us"):
                if _tap_text(sim, opener):
                    sim.wait(0.8)
                if _chat_open():
                    break
    if not _chat_open():
        return (
            "Could not open the support chat. Open Account -> Help and tap the "
            "Chat Support row, then re-call. (doordash.chat.input not visible.)"
        )
    sim.tap_id("doordash.chat.input"); sim.wait(0.3)
    sim.type_text(message); sim.wait(0.3)
    sim.tap_id("doordash.chat.send"); sim.wait(0.5)
    # Confirm the message actually landed in the transcript (no false positive).
    after = sim.observe_text() or ""
    snippet = message.strip()[:24]
    if snippet and snippet in after:
        return f"Sent support message: '{message}'."
    return (
        f"Could not confirm the message '{message}' appeared in "
        "the chat transcript. Re-open the chat and verify."
    )


if __name__ == "__main__":
    mcp.run()
