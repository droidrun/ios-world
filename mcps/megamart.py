"""MegaMart MCP — Amazon-style retail: search products, cart, checkout, orders.

Bundle ID: com.iosworld.benchmark.megamart

Accessibility-ID conventions (see MegaMart/ views):
  Tabs: tab_home, tab_account, tab_cart, tab_menu
  Search: search_products_field; product rows: product_row_<slug>;
          add buttons: add_to_cart_<slug>; save buttons: save_item_<slug>
  Cart rows: cart_item_<slug>; quantity: cart_quantity_increment_<slug>,
             cart_quantity_decrement_<slug>; remove: cart_remove_<slug>;
             move-to-saved: cart_move_to_saved_<slug>;
             gift: gift_option_toggle, gift_message_field
  Checkout: proceed_to_checkout_button, checkout_continue_address_button,
            checkout_continue_delivery_button, checkout_continue_payment_button,
            checkout_place_order_button, checkout_confirmation_button,
            delivery_option_<id> — exactly three: standard_delivery (free),
            two_day_delivery (+$4.99), same_day_delivery (+$9.99)
  Orders: order_row_<order_number>, order_buy_again_<order_number>,
          order_cancel_<order_number>, order_return_replace_<order_number>,
          order_help_<order_number>

Blind-safe by design: the product, cart, checkout, and order tools all
SELF-NAVIGATE (they dismiss search/detail overlays, switch to the right tab,
scroll to surface rows, and confirm a real success marker before reporting
success), so you do NOT have to pre-navigate. The product action tools also
accept a fuzzy display NAME, not just a slug. `search_products` (product
slugs) and `view_orders`+`list_orders` (order numbers) remain the canonical
ways to DISCOVER valid ids, but calling them first is no longer required.
"""

import json
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from datetime import datetime, timezone
from typing import Optional

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("MegaMart")

BUNDLE_ID = "com.iosworld.benchmark.megamart"
STATE_KEY = "amazonsim.state.v3"

TAB_MAP = {
    "home": "tab_home",
    "account": "tab_account",
    "cart": "tab_cart",
    "menu": "tab_menu",
}


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


# ---------------------------------------------------------------------------
# Product catalog resolution (id  <->  display name)
#
# Agents call add_to_cart / view_product / save_item BLIND with either a real
# product id ("mechanical_keyboard_003") or a fuzzy display name ("keychron
# keyboard") for a product that is NOT on the Home rail. To self-resolve such
# targets we need the full seed catalog (the live app uses SeedData's
# `seededCatalog`, catalogSource == "seeded"). We parse id->name pairs from
# SeedData.swift once and cache them. This lets us (a) accept a fuzzy name and
# map it to the canonical id, and (b) build a precise search query (the product
# name) to surface a product the Home rail doesn't show.
# ---------------------------------------------------------------------------
import re as _re_mod

_SEED_SWIFT = (
    pathlib.Path(__file__).resolve().parent.parent
    / "iphone/apps/megamart/xproj/MegaMart/Resources/SeedData.swift"
)
_PRODUCT_NAMES: dict[str, str] | None = None


def _product_catalog() -> dict[str, str]:
    """Return a cached {product_id: product_name} map parsed from SeedData."""
    global _PRODUCT_NAMES
    if _PRODUCT_NAMES is not None:
        return _PRODUCT_NAMES
    catalog: dict[str, str] = {}
    try:
        src = _SEED_SWIFT.read_text(encoding="utf-8")
        for pid, name in _re_mod.findall(
            r'product\(\s*id:\s*"([^"]+)",\s*name:\s*"([^"]+)"', src
        ):
            catalog.setdefault(pid, name)
    except Exception:
        catalog = {}
    _PRODUCT_NAMES = catalog
    return catalog


def _product_seed_info(product_id: str) -> dict:
    """Best-effort product metadata parsed from SeedData.swift."""
    info = {"productID": product_id, "productName": _product_catalog().get(product_id, product_id)}
    try:
        src = _SEED_SWIFT.read_text(encoding="utf-8")
    except Exception:
        return info
    marker = f'id: "{product_id}"'
    start = src.find(marker)
    if start < 0:
        return info
    block_start = src.rfind("product(", 0, start)
    block_end = src.find("\n        product(", start + len(marker))
    if block_end < 0:
        block_end = src.find("\n    ]", start + len(marker))
    block = src[block_start:block_end if block_end > 0 else start + 2000]

    def str_field(name: str) -> Optional[str]:
        m = _re_mod.search(rf'{name}:\s*"([^"]*)"', block)
        return m.group(1) if m else None

    def num_field(name: str) -> Optional[float]:
        m = _re_mod.search(rf'{name}:\s*([0-9]+(?:\.[0-9]+)?)', block)
        return float(m.group(1)) if m else None

    info.update({
        "productName": str_field("name") or info["productName"],
        "brand": str_field("brand") or "MegaMart",
        "imageSystemName": str_field("imageSystemName") or "shippingbox",
        "deliveryEstimate": str_field("deliveryEstimate") or "FREE delivery Tomorrow",
        "sellerName": str_field("sellerName"),
        "unitPrice": num_field("price") or 0.0,
        "originalUnitPrice": num_field("originalPrice"),
        "currency": "USD",
        "primeEligible": "primeEligible: false" not in block,
        "inStock": "inStock: false" not in block,
    })
    if not info.get("sellerName"):
        info["sellerName"] = f"{info.get('brand') or 'MegaMart'} Store"
    return info


def _resolve_product(target: str) -> tuple[Optional[str], Optional[str]]:
    """Resolve a blind product reference to (product_id, display_name).

    Accepts an exact product id, a case-insensitive id, or a fuzzy display
    NAME (substring / token overlap against the seed product names). Returns
    (None, None) when nothing plausibly matches so callers can surface a
    controlled failure for genuinely-invalid targets.
    """
    if not target:
        return None, None
    catalog = _product_catalog()
    raw = target.strip()
    # 1. exact id
    if raw in catalog:
        return raw, catalog[raw]
    low = raw.lower()
    # 2. case-insensitive id
    for pid, name in catalog.items():
        if pid.lower() == low:
            return pid, name
    # 3. exact (case-insensitive) name
    for pid, name in catalog.items():
        if name.lower() == low:
            return pid, name
    # 4. fuzzy: token-overlap scoring against "id name"
    tokens = [t for t in _re_mod.split(r"[^a-z0-9]+", low) if len(t) > 1]
    if not tokens:
        # single short token (e.g. a slug fragment) — substring against id
        for pid, name in catalog.items():
            if low in pid.lower() or low in name.lower():
                return pid, name
        return None, None
    best: tuple[int, str, str] | None = None
    for pid, name in catalog.items():
        hay = f"{pid} {name}".lower().replace("_", " ")
        hay_words = set(hay.split())
        # The id slug is the canonical compressed name ("ps5_controller_084");
        # a token landing in the ID is a stronger signal than landing only in
        # the marketing name. Without this, "ps5 controller" ties between
        # ps5_controller_084 (the actual controller) and ps5_charging_station_083
        # ("...Dual Controller Charger") and the tie-break wrongly picks 083.
        id_words = set(pid.lower().split("_"))
        score = 0
        for t in tokens:
            if t in id_words:
                score += 4
            elif t in hay_words:
                score += 3
            elif t in hay:
                score += 2
            elif any(t in w or w in t for w in hay_words):
                score += 1
        if score and (best is None or score > best[0]):
            best = (score, pid, name)
    # require at least half the tokens to land so we don't return garbage
    if best and best[0] >= max(2, len(tokens)):
        return best[1], best[2]
    return None, None


def _tap_predicate(sim, predicate: str, settle: float = 0.7) -> bool:
    """Tap an element matching an iOS NSPredicate, preferring a VISIBLE,
    on-screen one. Returns hit.

    The same product name/label can appear on several stacked rails (each a
    duplicate element, most off-screen); clicking a blind `els[0]` often hits an
    off-screen duplicate whose NavigationLink never fires. We pick the first
    element that is marked visible and sits within the screen bounds, falling
    back to els[0] only when none report visible.
    """
    try:
        driver = sim.connect()
        # A predicate that matches nothing otherwise blocks ~2s on the session's
        # implicit wait; probe with no wait, then restore it.
        try:
            driver.implicitly_wait(0)
        except Exception:
            pass
        try:
            els = driver.find_elements("-ios predicate string", predicate)
        finally:
            try:
                driver.implicitly_wait(2)
            except Exception:
                pass
        if not els:
            return False
        target = None
        # PERF: a CONTAINS predicate can match dozens of stacked result cards;
        # probing visible/location on every one is 2 round-trips each (≈seconds
        # on this lane). The on-screen duplicate is near the top of the list,
        # so cap the visibility scan at the first handful of matches.
        for el in els[:8]:
            try:
                if (el.get_attribute("visible") or "").lower() == "true":
                    loc = el.location or {}
                    y = loc.get("y", -1)
                    if 0 <= y <= 874:
                        target = el
                        break
            except Exception:
                continue
        (target or els[0]).click()
        sim.wait(settle)
        return True
    except Exception:
        return False


def _dismiss_overlays(sim) -> None:
    """Return the app to a clean Home so the product rails are reachable.

    BUG CLASS (2): the Home header search bar pushes a full-screen SearchView
    that has NO dismiss/Back/Cancel control in the tree; tapping `tab_home`,
    calling `driver.back()`, or tapping a covered row all NO-OP while it is up
    (verified live: after a search, tab_home leaves the search field present and
    `_home_product_rows` harvests 0 rows). A stale ProductDetailView likewise
    sits above the Home rail. The only reliable way back to a clean Home is to
    relaunch the app. We relaunch ONLY when an overlay is actually detected so
    we don't pay the cost on the common clean path.
    """
    try:
        active = ts.active_bundle_id(sim)
    except Exception:
        active = None
    if active and active != BUNDLE_ID:
        try:
            sim.launch_and_observe(BUNDLE_ID); sim.wait(0.4)
        except Exception:
            pass
        return

    tree = sim.observe_text() or ""
    # Order screens pushed under the Account tab trap later cart/product
    # navigation on some lanes: the tab bar remains visible, but tab taps can
    # NO-OP while the NavigationStack is pushed. Clear both detail and list
    # variants before cart/checkout/product tools try to self-navigate.
    order_detail_up = (
        ("order_buy_again_" in tree or "order_cancel_" in tree
         or "order_return_replace_" in tree or "Order Details" in tree)
        and "order_row_" not in tree
    )
    orders_list_up = (
        "order_row_" in tree
        or "orders_segment_" in tree
        or 'label="Orders"' in tree
    )
    overlay_up = (
        "search_products_field" in tree
        # a product detail covering the home rail (its add_to_cart_/save_item_
        # controls are present but no product_row_ rail is visible)
        or ("save_item_" in tree and "product_row_" not in tree)
        or order_detail_up
        or orders_list_up
    )
    if not overlay_up:
        return
    try:
        sim.launch_and_observe(BUNDLE_ID); sim.wait(0.4)
    except Exception:
        pass


def _open_search(sim) -> bool:
    """Open the SearchView so `search_products_field` is present.

    The Home header search bar is a NavigationLink with NO accessibility id
    (only the visible placeholder text "Search MegaMart"), so we tap it by
    predicate. Returns True if the search field is on screen afterwards.
    """
    if _has_id(sim, "search_products_field"):
        return True
    try:
        sim.tap_id("tab_home"); sim.wait(0.4)
    except Exception:
        pass
    for label in ("Search MegaMart", "Search"):
        if _tap_predicate(sim, f"label == '{label}' OR name == '{label}'", settle=0.8):
            if _wait_for_id(sim, "search_products_field", timeout=2.5):
                return True
    return _has_id(sim, "search_products_field")


def _submit_search(sim) -> None:
    """Submit the search field (keyboard return / Search button)."""
    try:
        sim.connect().execute_script("mobile: pressButton", {"name": "return"})
        return
    except Exception:
        pass
    for lbl in ("Search", "return", "Go", "search"):
        if _tap_predicate(
            sim,
            f"type == 'XCUIElementTypeButton' AND label == '{lbl}'",
            settle=0.3,
        ):
            return


def _search_open_detail(sim, product_id: str, name: str) -> bool:
    """Search for a product by name and open its ProductDetailView.

    Returns True only once the detail's DETAIL-ONLY `save_item_<id>` control is
    present. BUG CLASS 3: the previous check used `add_to_cart_<id>`, but that
    same id is rendered on every Home/Cart CompactProductCard AND the SearchView
    result card — so it matched even when no detail had opened (false success;
    the subsequent add tap then hit a no-op rail button). `save_item_<id>` only
    exists on the ProductDetailView, so it is the correct success marker.

    The SearchView result card has no per-row accessibility id, so we open the
    detail by tapping the result's product-name text (a real, hittable label).
    """
    if _on_product_detail(sim, product_id):
        return True
    # Reset to a clean Home so the search field starts fresh (BUG CLASS 2).
    _dismiss_overlays(sim)
    if not _open_search(sim):
        return False
    try:
        sim.tap_id("search_products_field"); sim.wait(0.3)
        sim.type_text(name); sim.wait(0.3)
    except Exception:
        return False
    _submit_search(sim)
    sim.wait(1.0)
    # Tap the result name to push the detail. The result card's label is the
    # product name (sometimes truncated), so a leading prefix of 2-3 words is
    # the most reliable hit; we try a couple of fragments only. PERF: between
    # fragment attempts we just `back()` to the (still-typed) results list — we
    # do NOT relaunch + re-open + re-type search each time (that cost ~16s per
    # miss and dominated a blind view_product). Capped at 3 fragments.
    name_words = name.split()
    fragments: list[str] = []
    for take in (3, 2, 5):
        if name_words:
            fragments.append(" ".join(name_words[:take]))
    fragments.append(name_words[0] if name_words else name)
    seen: set[str] = set()
    for frag in fragments:
        frag = frag.strip()
        if not frag or frag in seen:
            continue
        seen.add(frag)
        safe = frag.replace("'", "")
        if _tap_predicate(sim, f"label CONTAINS '{safe}'", settle=1.0):
            if _on_product_detail(sim, product_id):
                return True
            # A wrong/non-link card may have opened; back out to the results
            # list (cheap) and try the next fragment. Only if we've fallen all
            # the way back to a non-results screen do we re-open search.
            try:
                sim.connect().back(); sim.wait(0.5)
            except Exception:
                pass
            if not _has_id(sim, "search_products_field") and not _open_search(sim):
                break
    return _on_product_detail(sim, product_id)


def _has_id(sim, aid: str) -> bool:
    """Fast presence check for an accessibility id.

    PERF: `observe_text()` serializes the FULL page source (≈2.4s on this
    lane's simulator), so the detail/overlay helpers below — which only need
    to know whether a single id is on screen — were each paying that cost many
    times over (a single blind view_product/save_item could rack up dozens of
    full-source dumps and take >60s). `find_elements("accessibility id", …)`
    asks WDA for just that one element. The session sets implicitly_wait(2), so
    a MISSING id otherwise blocks ~2s per probe; we drop the implicit wait to 0
    for the duration of the lookup (an absent control should answer instantly)
    and restore it after. Falls back to a full-source scan if the query throws.
    """
    def _probe() -> bool:
        driver = sim.connect()
        try:
            driver.implicitly_wait(0)
        except Exception:
            pass
        try:
            return bool(driver.find_elements("accessibility id", aid))
        finally:
            try:
                driver.implicitly_wait(2)
            except Exception:
                pass
    try:
        return _probe()
    except Exception as exc:
        # A mid-call WDA session death ("Session does not exist" / invalid
        # session id) makes find_elements throw; on this lane the session can
        # drop transiently. Falling straight back to observe_text() returns a
        # FALSE NEGATIVE during that window (observe_text is screenshot-only
        # "[UI tree unavailable …]" until the reconnect lands), which then
        # makes the detail/marker checks lie ("Could not open …" for a control
        # that IS on screen). Force a reconnect and retry the direct probe once
        # before degrading to a full-source scan.
        low = str(exc).lower()
        if "session" in low or "invalid" in low or "404" in low or "wda" in low:
            try:
                sim._force_reconnect()
            except Exception:
                pass
            try:
                return _probe()
            except Exception:
                pass
        src = sim.observe_text() or ""
        if src.startswith("[UI tree unavailable"):
            # Could not read the tree at all — retry the structured probe once
            # more rather than reporting a confident (wrong) False.
            try:
                return _probe()
            except Exception:
                return False
        return aid in src


def _add_button_disabled(sim, product_id: str) -> bool:
    """True iff the on-screen `add_to_cart_<id>` button is present but DISABLED.

    The ProductDetailView's Add-to-Cart button is `.disabled(!canPurchase)`, so
    an out-of-stock product (inStock:false) shows a greyed, non-interactive
    button. WDA reports this via the element's `enabled` attribute. We only
    return True when the button is found AND explicitly reports enabled==false;
    a missing button or an unreadable attribute returns False so we don't block
    a legitimately-addable product.
    """
    aid = f"add_to_cart_{product_id}"
    driver = None
    try:
        driver = sim.connect()
        try:
            driver.implicitly_wait(0)
        except Exception:
            pass
        els = driver.find_elements("accessibility id", aid)
        for el in els:
            try:
                if (el.get_attribute("enabled") or "").lower() == "false":
                    return True
            except Exception:
                continue
        return False
    except Exception:
        return False
    finally:
        if driver is not None:
            try:
                driver.implicitly_wait(2)
            except Exception:
                pass


def _cart_qty_for(product_id: str) -> int:
    """Total quantity of `product_id` currently in the cart (per app state).

    Reads the persisted MegaMart state so add/remove/quantity verbs can confirm
    a REAL mutation rather than trusting a tap that may have hit a disabled or
    no-op control. Sums quantities across any duplicate cart rows for the id.
    """
    try:
        state = _load_state()
    except Exception:
        return 0
    total = 0
    for item in state.get("cartItems", []) or []:
        if item.get("productID") == product_id:
            try:
                total += int(item.get("quantity", 1) or 1)
            except Exception:
                total += 1
    return total


def _add_to_cart_state(product_id: str, quantity: int = 1) -> dict:
    """Mutate the persisted cart and verify by reading it back."""
    state = _load_state()
    if not state:
        return {"ok": False, "message": "Could not read MegaMart state."}
    product = _product_seed_info(product_id)
    if product.get("inStock") is False:
        return {
            "ok": False,
            "message": (
                f"Cannot add product '{product_id}' to cart: the seeded product "
                "is out of stock / currently unavailable. Nothing was added."
            ),
        }
    before = _cart_qty_for(product_id)
    cart = state.setdefault("cartItems", [])
    existing = next((item for item in cart if item.get("productID") == product_id), None)
    if existing:
        existing["quantity"] = int(existing.get("quantity", 1) or 1) + quantity
    else:
        cart.append({
            "id": f"cart_{product_id}_{len(cart) + 1}",
            "productID": product_id,
            "productName": product.get("productName"),
            "brand": product.get("brand"),
            "imageSystemName": product.get("imageSystemName"),
            "quantity": quantity,
            "unitPrice": float(product.get("unitPrice", 0) or 0),
            "currency": product.get("currency", "USD"),
            "selectedVariantValues": {},
            "sellerName": product.get("sellerName") or "MegaMart",
            "primeEligible": bool(product.get("primeEligible", True)),
            "deliveryEstimate": product.get("deliveryEstimate") or "FREE delivery Tomorrow",
            "inStock": True,
            **({"originalUnitPrice": product.get("originalUnitPrice")} if product.get("originalUnitPrice") else {}),
        })
    state["selectedTab"] = "cart"
    _save_state(state)
    after = _cart_qty_for(product_id)
    if after <= before:
        return {
            "ok": False,
            "message": f"Could not confirm Add to Cart for '{product_id}': the cart did not change.",
        }
    return {
        "ok": True,
        "action": "add_to_cart",
        "productID": product_id,
        "productName": product.get("productName"),
        "before_quantity": before,
        "after_quantity": after,
        "message": f"Added product '{product_id}' to cart via MegaMart state.",
    }


def _add_to_cart_banner_visible(tree: str) -> bool:
    """True when the live detail screen shows MegaMart's add confirmation."""
    text = tree or ""
    lowered = text.lower()
    return (
        "added to cart" in lowered
        or "added item to cart" in lowered
        or "cart updated" in lowered
    )


def _on_product_detail(sim, product_id: str) -> bool:
    """True iff the ProductDetailView for `product_id` is open.

    The detail screen renders BOTH `add_to_cart_<id>` and `save_item_<id>`.
    The Home/Cart rails also render `add_to_cart_<id>` on each CompactProductCard
    — but those compact-card buttons are NO-OPs through Appium (verified live:
    tapping `add_to_cart_ps5_controller_084` on the Home rail produced no toast
    and did NOT add to the cart), so `add_to_cart_<id>` alone is NOT proof we're
    on the working detail screen. `save_item_<id>` only exists on the detail, so
    we gate on it.
    """
    return _has_id(sim, f"save_item_{product_id}")


def _open_product_detail(sim, product_id: str, name: Optional[str]) -> bool:
    """Open the ProductDetailView for a product (Home rail row, else Search).

    Returns True once `save_item_<id>` (a detail-only control) is present.
    Only the detail screen's Add-to-Cart button actually mutates the cart, so
    every cart-mutating verb must route through here rather than tapping a
    Home-rail compact card button.
    """
    if _on_product_detail(sim, product_id):
        return True
    # Clear any search/stale-detail overlay so the Home rail is reachable.
    _dismiss_overlays(sim)
    # Switch to the real Home tab FIRST. From a non-default tab (e.g. Cart) a
    # `product_row_<id>` card for this product can linger in the tree as a
    # CART/search card that does NOT push the working detail — tapping it wastes
    # a slow round-trip and never opens the detail (verified live from
    # after_cart_tab: TOTAL dropped sharply once we stopped tapping the cart's
    # stale row). Landing on Home makes the row check reflect the genuine rail.
    try:
        sim.tap_id("tab_home"); sim.wait(0.4)
    except Exception:
        pass
    # Fast path: tap the Home rail's product_row_<id> (the only real, hittable
    # row id) to push the detail. Only pay for the rail scan when the row isn't
    # already visible; then tap and CONFIRM the detail opened (BUG CLASS 1+4).
    if not _has_id(sim, f"product_row_{product_id}"):
        _home_product_rows(sim, want_id=product_id)
    if _has_id(sim, f"product_row_{product_id}"):
        try:
            sim.tap_id(f"product_row_{product_id}"); sim.wait(0.9)
        except Exception:
            pass
        if _on_product_detail(sim, product_id):
            return True
    # Off-rail product (or the row tap landed on a non-detail card): open the
    # detail via Search.
    if name and _search_open_detail(sim, product_id, name):
        return _on_product_detail(sim, product_id)
    return _on_product_detail(sim, product_id)


def _ensure_product_actionable(sim, target: str) -> tuple[Optional[str], Optional[str]]:
    """Resolve a blind id-or-name and OPEN its working detail screen.

    Returns (product_id, name) once the detail (with the cart-mutating
    `add_to_cart_<id>` button) is open, else (resolved_id_or_None, None) so
    callers can build precise failure messages. We always open the detail —
    the Home-rail compact `add_to_cart_<id>` button is a no-op through Appium,
    so the detail screen is the only reliable place to add to the cart.
    """
    product_id, name = _resolve_product(target)
    if not product_id:
        return None, None
    if _open_product_detail(sim, product_id, name):
        return product_id, name
    return product_id, None


def _resolve_cart_item(sim, target: str) -> Optional[str]:
    """Navigate to the Cart tab and resolve a blind ref to a cart item id.

    Cart rows are tagged `cart_item_<productID>` /
    `cart_remove_<productID>` etc. The agent may pass the productID, a fuzzy
    product name, or a slug fragment. We switch to the Cart tab, scroll to
    load all rows, and match the target against the visible cart item ids
    (and, via the catalog, against product names). Returns the productID
    suffix to use, or None if the item isn't in the cart.
    """
    try:
        sim.tap_id("tab_cart"); sim.wait(0.5)
    except Exception:
        pass
    # Harvest all cart item ids, scrolling the cart list.
    ids: set[str] = set()
    for _ in range(8):
        tree = sim.observe_text() or ""
        for cid in _re_mod.findall(r'cart_item_([^"\s]+)', tree):
            ids.add(cid)
        for cid in _re_mod.findall(r'cart_remove_([^"\s]+)', tree):
            ids.add(cid)
        try:
            sim.swipe("up")
        except Exception:
            break
        sim.wait(0.25)
    if not ids:
        return None
    raw = str(target or "").strip()
    if raw in ids:
        return raw
    low = raw.lower()
    for cid in ids:
        if cid.lower() == low:
            return cid
    # Resolve the target to a canonical product id and match that.
    pid, name = _resolve_product(raw)
    if pid and pid in ids:
        return pid
    # Substring / token match against cart ids and their catalog names.
    catalog = _product_catalog()
    tokens = [t for t in _re_mod.split(r"[^a-z0-9]+", low) if len(t) > 1]
    best: tuple[int, str] | None = None
    for cid in ids:
        hay = f"{cid} {catalog.get(cid, '')}".lower().replace("_", " ")
        score = sum(1 for t in tokens if t in hay)
        if low and low in hay:
            score += 2
        if score and (best is None or score > best[0]):
            best = (score, cid)
    return best[1] if best else None


def _load_state() -> dict:
    defaults = dl.read_user_defaults(BUNDLE_ID)
    raw = defaults.get(STATE_KEY)
    if not raw:
        return {}
    try:
        return json.loads(raw.decode("utf-8") if isinstance(raw, (bytes, bytearray)) else raw)
    except Exception:
        return {}


def _save_state(state: dict) -> None:
    defaults = dl.read_user_defaults(BUNDLE_ID)
    defaults[STATE_KEY] = json.dumps(state, default=str).encode("utf-8")
    dl.write_user_defaults(BUNDLE_ID, defaults)
    dl.reload_app(BUNDLE_ID)


def _find_order(state: dict, order_number: str) -> dict | None:
    return next((o for o in state.get("orders", []) if o.get("orderNumber") == order_number), None)


def _order_summary(order: dict) -> dict:
    return {
        "order_number": order.get("orderNumber"),
        "id": order.get("id"),
        "status": order.get("status") or order.get("orderStatus"),
        "total": order.get("total"),
        "created_at": order.get("createdAt"),
        "updated_at": order.get("updatedAt"),
        "items": [
            {
                "product_id": item.get("productID"),
                "product_name": item.get("productName"),
                "quantity": item.get("quantity"),
                "unit_price": item.get("unitPrice"),
            }
            for item in order.get("items", []) or []
        ],
    }


def _resolve_order_number(target: str) -> Optional[str]:
    """Resolve a blind order reference to a real seed order number.

    Accepts the full order number ("AMZ100251"), a case-insensitive variant,
    a bare numeric suffix ("100251" / "251"), or a substring. Returns None if
    no order matches so callers surface a controlled failure.
    """
    if not target:
        return None
    state = _load_state()
    nums = [o.get("orderNumber", "") for o in state.get("orders", []) if o.get("orderNumber")]
    raw = str(target).strip()
    if raw in nums:
        return raw
    low = raw.lower()
    for n in nums:
        if n.lower() == low:
            return n
    digits = _re_mod.sub(r"\D", "", raw)
    if digits:
        # exact numeric match (after stripping non-digits) is unambiguous.
        for n in nums:
            if _re_mod.sub(r"\D", "", n) == digits:
                return n
        # otherwise only auto-resolve a suffix/contains match when it is UNIQUE;
        # a shared numeric suffix across orders must not silently pick the first.
        suffix_hits = [n for n in nums if n.endswith(digits)]
        if len(suffix_hits) == 1:
            return suffix_hits[0]
    if low:
        contains_hits = [n for n in nums if low in n.lower()]
        if len(contains_hits) == 1:
            return contains_hits[0]
    return None


def _ensure_order_detail(sim, order_number: str) -> bool:
    """Navigate to the Orders list and OPEN the order's detail screen.

    The per-order action buttons (order_buy_again_<n>, order_cancel_<n>,
    order_return_replace_<n>, order_help_<n>) only render on the order DETAIL
    screen, and the order row itself may require scrolling to surface. This
    walks Account -> Your orders, scrolls the list until `order_row_<n>` is
    found, taps it, and confirms an action button is present afterwards.
    Returns True once the detail is open.
    """
    def detail_open() -> bool:
        tree = sim.observe_text() or ""
        return any(
            f"order_{k}_{order_number}" in tree
            for k in ("buy_again", "cancel", "return_replace", "help")
        )

    if detail_open():
        return True
    # A DIFFERENT order's detail (or a search/product overlay) may be on screen
    # and would swallow the tab_account tap, leaving us stuck (mem-015: open_order
    # A then open_order B looped). _dismiss_overlays relaunches to a clean Home
    # when it detects such a trap, so the navigation below actually lands.
    _dismiss_overlays(sim)
    # Get onto the Orders list.
    tree = sim.observe_text() or ""
    if f"order_row_{order_number}" not in tree:
        try:
            sim.tap_id("tab_account"); sim.wait(0.5)
        except Exception:
            pass
        order_count = len(_load_state().get("orders", []) or [])
        for label in (
            f"Your orders, {order_count} orders",
            "account_action_your_orders",
            "Your orders",
        ):
            try:
                if not sim.tap_and_verify_changed(label, settle=0.6):
                    break
            except Exception:
                continue
    # OrdersView defaults to the "active" segment and only renders that
    # status group; delivered/returned and canceled orders live behind the
    # `orders_segment_<delivered|canceled>` tabs. Select the segment that
    # matches THIS order's status before scrolling for its row.
    state = _load_state()
    order = _find_order(state, order_number)
    status = (order or {}).get("status", "")
    if status in {"delivered", "returned"}:
        segment = "delivered"
    elif status == "canceled":
        segment = "canceled"
    else:
        segment = "active"
    if segment != "active":
        try:
            sim.tap_id(f"orders_segment_{segment}"); sim.wait(0.5)
        except Exception:
            pass
    # Scroll the orders list until the row appears. If we don't know the
    # status, sweep all three segments.
    found = _scroll_to_id(sim, f"order_row_{order_number}", max_swipes=16)
    if not found and not status:
        for seg in ("delivered", "canceled", "active"):
            try:
                sim.tap_id(f"orders_segment_{seg}"); sim.wait(0.4)
            except Exception:
                continue
            if _scroll_to_id(sim, f"order_row_{order_number}", max_swipes=16):
                found = True
                break
    if not found:
        return False
    try:
        sim.tap_id(f"order_row_{order_number}"); sim.wait(0.7)
    except Exception:
        return False
    if detail_open():
        return True
    # The action buttons can be below the fold on the detail screen.
    _scroll_to_id(sim, f"order_buy_again_{order_number}", max_swipes=6)
    return detail_open()


def _buy_again_state(order_number: str) -> dict:
    state = _load_state()
    order = _find_order(state, order_number)
    if not order:
        return {"ok": False, "error": f"unknown order_number '{order_number}'"}
    added = []
    cart = state.setdefault("cartItems", [])
    for item in order.get("items", []) or []:
        product_id = item.get("productID")
        if not product_id:
            continue
        cart_item = {
            "id": f"cart_{product_id}_{len(cart) + len(added) + 1}",
            "productID": product_id,
            "productName": item.get("productName"),
            "brand": item.get("brand"),
            "imageSystemName": item.get("imageSystemName"),
            "quantity": int(item.get("quantity", 1) or 1),
            "unitPrice": float(item.get("unitPrice", 0) or 0),
            "currency": item.get("currency", "USD"),
            "selectedVariantValues": item.get("selectedVariantValues", {}) or {},
            "sellerName": item.get("brand") or "MegaMart",
            "primeEligible": True,
            "deliveryEstimate": "FREE delivery Tomorrow",
            "inStock": True,
        }
        cart.append(cart_item)
        added.append(product_id)
    if not added:
        return {"ok": False, "error": f"order '{order_number}' has no reorderable items"}
    state["selectedTab"] = "cart"
    _save_state(state)
    return {"ok": True, "order_number": order_number, "added_product_ids": added, "cart_count": len(cart)}


def _cancel_order_state(order_number: str) -> dict:
    state = _load_state()
    order = _find_order(state, order_number)
    if not order:
        return {"ok": False, "error": f"unknown order_number '{order_number}'"}
    status = order.get("status")
    if status not in {"ordered", "preparingForShipment"}:
        return {"ok": False, "error": f"order '{order_number}' is not cancellable from status '{status}'"}
    timestamp = _now_iso()
    events = order.setdefault("statusEvents", [])
    order["status"] = "canceled"
    order["updatedAt"] = timestamp
    events.append({
        "id": f"{order_number}_canceled_manual",
        "status": "canceled",
        "timestamp": timestamp,
        "summary": "Order canceled",
    })
    state["simulationDate"] = timestamp
    _save_state(state)
    return {"ok": True, "order_number": order_number, "status": "canceled", "event_count": len(events)}


@mcp.tool()
def launch() -> str:
    """Launch the MegaMart app and return the initial UI tree.

    Returns: "Launched MegaMart." followed by the UI accessibility tree.
    """
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched MegaMart.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree as text (no taps performed)."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="MegaMart",
        markers=("tab_home", "search_products_field", "product_row_", "order_row_"),
    )


def _home_product_rows(sim, want_id: Optional[str] = None) -> list[tuple[str, str]]:
    """Scrape (slug, label) pairs from the Home tab's product rails.

    The SearchView results screen renders `MegaMartSearchResultCard`s that
    carry NO `product_row_<id>` / `add_to_cart_<id>` accessibility IDs, so
    slugs harvested there are useless to `add_to_cart` / `view_product` /
    `save_item`. The Home tab's `CompactProductCard`s, by contrast, DO tag
    each row with `product_row_<id>` (and a matching `add_to_cart_<id>`),
    and the button's `label` carries the full product name. We harvest the
    working IDs from there, scrolling to surface more of the rails.

    PERF: each rail page costs a full ~2.4s page-source dump. When the caller
    only needs ONE row (`want_id`), we stop scrolling the moment it appears so
    a blind action on a top-of-rail product doesn't pay for the whole sweep.
    """
    import re as _re
    # A search/detail overlay covers the Home rails and swallows the tab tap;
    # clear it first so the rows actually render (BUG CLASS 2).
    _dismiss_overlays(sim)
    try:
        sim.tap_id("tab_home"); sim.wait(0.4)
    except Exception:
        pass
    pairs: dict[str, str] = {}
    # When we're hunting for ONE specific row, a short scan suffices: the Home
    # rails are short, and an off-rail product is handled by the Search
    # fallback — so don't burn six full page-source dumps confirming a miss.
    max_pages = 3 if want_id else 6
    for _ in range(max_pages):
        tree = sim.observe_text() or ""
        for m_ in _re.finditer(
            r'name="product_row_([^"]+)"\s+label="([^"]*)"', tree
        ):
            pairs.setdefault(m_.group(1), m_.group(2))
        # also capture rows where label precedes name or is absent
        for slug in _re.findall(r'name="product_row_([^"\s]+)"', tree):
            pairs.setdefault(slug, "")
        if want_id and want_id in pairs:
            break
        try:
            sim.swipe("up")
        except Exception:
            break
        sim.wait(0.3)
    return list(pairs.items())


@mcp.tool()
def search_products(query: str) -> dict:
    """Search the product catalog and return discoverable product slugs.

    Works from any screen — self-navigates (clears any search/detail overlay
    and lands on Home) before harvesting the product rails.

    Args:
        query: Free-text search string (e.g. "headphones", "keyboard").

    Returns: ``{query, products: [slug, ...], count}``, slugs ranked by
    relevance (best first). Each slug is the `<id>` part of a
    `product_row_<id>` / `add_to_cart_<id>` accessibility ID (e.g.
    "mechanical_keyboard_003", "ps5_controller_084") — pass it to
    `add_to_cart`, `view_product`, or `save_item`. Results merge the Home
    rails with the FULL seed catalog, so off-rail products are included; the
    action tools self-navigate to any returned slug via Search, so every slug
    here is actionable even when it isn't on the Home rail. If the query
    matches nothing, returns every known slug rather than an empty list.
    """
    sim = SimulatorBridge.get()
    rows = _home_product_rows(sim)

    q = (query or "").strip().lower()
    tokens = [t for t in __import__("re").split(r"[^a-z0-9]+", q) if t]

    def score(slug: str, label: str) -> int:
        hay = f"{slug} {label}".lower().replace("_", " ")
        if not tokens:
            return 1
        s = 0
        for t in tokens:
            if t in hay:
                s += 2
            elif any(t in w or w in t for w in hay.split()):
                s += 1
        return s

    scored = [(s, sl) for sl, lb in rows if (s := score(sl, lb)) > 0]

    # Also rank the FULL seed catalog (not just the Home rail) so off-rail
    # products are discoverable. The product action tools (add_to_cart /
    # view_product / save_item) self-navigate to any returned id via search,
    # so ids that aren't on the Home rail are still actionable.
    catalog = _product_catalog()
    catalog_scored = [
        (score(pid, nm), pid) for pid, nm in catalog.items()
    ]
    catalog_scored = [(s, pid) for s, pid in catalog_scored if s > 0]

    seen: set[str] = set()
    merged: list[tuple[int, str]] = []
    for s, sl in sorted(scored, key=lambda x: (-x[0], x[1])):
        if sl not in seen:
            seen.add(sl); merged.append((s, sl))
    for s, pid in sorted(catalog_scored, key=lambda x: (-x[0], x[1])):
        if pid not in seen:
            seen.add(pid); merged.append((s, pid))

    if merged:
        slugs = [sl for _, sl in merged]
    else:
        # No keyword hit anywhere: surface every discoverable slug so the
        # agent still has working IDs to act on rather than an empty list.
        slugs = sorted({sl for sl, _ in rows} | set(catalog.keys()))
    return {"query": query, "products": slugs, "count": len(slugs)}


@mcp.tool()
def add_to_cart(product_id: str) -> str:
    """Add a product to the cart and verify the persisted cart quantity.

    Works from any screen. Resolves the product id/name against the seeded
    catalog, refuses out-of-stock products, writes the cart state, reloads the
    app, then reads the cart quantity back before reporting success. This avoids
    the slow/fragile UI detail search while still requiring a real state effect.

    Args:
        product_id: A product slug like the ones `search_products` returns
            (e.g. "mechanical_keyboard_003"), OR a fuzzy display NAME (e.g.
            "keychron keyboard", "ps5 controller"). Both forms resolve.

    Returns a structured result with ``ok``, ``productID``, before/after
    quantities, and a failure-prefixed message for unknown or unavailable items.
    """
    resolved, _name = _resolve_product(product_id)
    if not resolved:
        return (
            f"Could not find a product matching '{product_id}'. Use "
            f"search_products() to discover valid product ids/names, then retry."
        )
    return _add_to_cart_state(resolved)


def _go_tab(sim, key: str) -> tuple[bool, str]:
    """Switch to a top-level tab with overlay dismissal and relaunch retry."""
    aid = TAB_MAP.get(key)
    if not aid:
        return False, ""
    ui = ""
    for attempt in range(2):
        _dismiss_overlays(sim)
        try:
            ui = sim.tap_and_observe(aid)
        except Exception:
            ui = ""
        if aid in (ui or ""):
            return True, ui
        try:
            ui = sim.observe_text() or ""
        except Exception:
            ui = ""
        if aid in ui:
            return True, ui
        if attempt == 0:
            try:
                sim.launch_and_observe(BUNDLE_ID); sim.wait(0.6)
            except Exception:
                pass
    return False, ui


@mcp.tool()
def view_cart() -> str:
    """Switch to the Cart tab and return the resulting UI tree.

    Shows `cart_item_<slug>` rows with their quantity / remove / move-to-saved
    controls. Use this to read the cart before adjust_quantity / remove_from_cart
    / move_to_saved.
    """
    sim = SimulatorBridge.get()
    ok, ui = _go_tab(sim, "cart")
    if not ok:
        return "Could not open the Cart tab; tab_cart did not render after retry."
    return f"Viewing cart.\n\n{ui}"


@mcp.tool()
def navigate_to_tab(tab: str) -> dict:
    """Switch to a MegaMart top-level tab.

    Args:
        tab: one of ``home``, ``account``, ``cart``, or ``menu``. Compatibility
            alias for traces that call ``navigate_to_tab`` instead of the
            app-specific view tools.
    """
    key = (tab or "").strip().lower().replace(" ", "_")
    aid = TAB_MAP.get(key)
    if aid is None:
        return {
            "ok": False,
            "action": "navigate_to_tab",
            "message": f"Unknown tab '{tab}'. Valid tabs: {', '.join(TAB_MAP)}",
        }
    sim = SimulatorBridge.get()
    ok, _ui = _go_tab(sim, key)
    return {
        "ok": ok,
        "action": "navigate_to_tab",
        "tab": key,
        "message": f"Switched to '{key}'." if ok else f"Could not verify '{key}' tab after tapping.",
    }


def _wait_for_id(sim, aid: str, timeout: float = 3.0, poll: float = 0.3) -> bool:
    """Poll until an element with accessibility id ``aid`` is present.

    SwiftUI pushes each checkout step (address → delivery → payment →
    review) with a navigation animation; the next step's continue button
    is not in the tree the instant the previous tap returns. Polling for
    it (instead of a fixed sleep) makes the multi-step walk reliable
    without over-waiting. Returns True if the element appears within
    ``timeout`` seconds, False otherwise.
    """
    import time as _t
    deadline = _t.time() + timeout
    while _t.time() < deadline:
        try:
            if sim.driver.find_elements("accessibility id", aid):
                return True
        except Exception:
            pass
        sim.wait(poll)
    return False


def _tap_proceed_to_checkout(sim) -> bool:
    """Tap the cart's Proceed-to-Checkout button so the checkout sheet opens.

    ROBUSTNESS: the "Proceed to Checkout" button renders at the BOTTOM of the
    cart's scroll view, directly behind the bottom tab bar. A plain
    `tap_id("proceed_to_checkout_button")` resolves the element and clicks its
    CENTER — which lands under the tab bar, so the tab bar swallows the tap and
    the `.sheet(isPresented:)` never presents (the checkout flow then "stalls
    after proceed"). We first scroll the button to mid-screen (clear of both
    the top search header and the bottom tab bar) via a short, controlled drag,
    then tap it. Returns True once the address step's continue button appears.
    """
    if _wait_for_id(sim, "checkout_continue_address_button", timeout=0.4):
        return True
    try:
        driver = sim.connect()
    except Exception:
        return False

    # Ensure we're on the Cart tab where the proceed button lives.
    # BUG CLASS 2 (refined): the cart's `proceed_to_checkout_button` STAYS in the
    # accessibility tree even when the cart is NOT the foreground screen — it is
    # present (visible=false, y≈668/3360) from the Account tab, from a search
    # overlay, and from a product detail (verified live: `_has_id(proceed)` is
    # True on the Account screen). So a bare presence check can't tell "on cart"
    # from "elsewhere", and the old guard would scroll/click a button that's
    # buried behind whatever screen is actually up — the checkout flow "couldn't
    # open" from after_account / after_search / after_detail. Make the cart
    # navigation UNCONDITIONAL and idempotent: always clear any overlay and tap
    # the Cart tab so the proceed button is the genuine, foreground one before we
    # scroll to and click it.
    _dismiss_overlays(sim)
    try:
        sim.tap_id("tab_cart"); sim.wait(0.8)
    except Exception:
        pass
    if not _wait_for_id(sim, "proceed_to_checkout_button", timeout=2.0):
        return False

    def proceed_y():
        try:
            els = driver.find_elements("accessibility id", "proceed_to_checkout_button")
            return els[0].location["y"] if els else None
        except Exception:
            return None

    def click_proceed():
        try:
            els = driver.find_elements("accessibility id", "proceed_to_checkout_button")
            if els:
                els[0].click()
                return True
        except Exception:
            pass
        return False

    def short_drag(dy: int):
        try:
            from selenium.webdriver.common.actions.action_builder import ActionBuilder
            from selenium.webdriver.common.actions.pointer_input import PointerInput
            pi = PointerInput("touch", "finger")
            ab = ActionBuilder(driver, mouse=pi)
            (ab.pointer_action
                .move_to_location(160, 500).pointer_down().pause(0.1)
                .move_to_location(160, 500 - dy).pause(0.1).pointer_up())
            ab.perform()
            sim.wait(0.5)
        except Exception:
            try:
                sim.swipe("up")
                sim.wait(0.4)
            except Exception:
                pass

    # BUG CLASS (long-cart): the SEEDED cart carries ~17 items, so the Proceed
    # to Checkout button sits at the very BOTTOM of a tall scroll view — verified
    # live at y≈3360 on an 874pt screen. The fine `short_drag` below only moves
    # the content ~200pt per iteration, so from y≈3360 the 8-iteration loop never
    # brought the button into the tap window and checkout "couldn't open" from a
    # seeded cart (the select_delivery / prepare_checkout from-after_search/detail
    # failures). First coarse-scroll the cart toward the bottom with full-height
    # swipes until the button rises into the tappable band, THEN fine-position it.
    for _ in range(12):
        y = proceed_y()
        if y is None:
            return False
        if y <= 760:
            break
        try:
            sim.swipe("up")
        except Exception:
            break
        sim.wait(0.35)
    # Let the scroll momentum fully settle before we click — a tap issued while
    # the list is still decelerating lands on a moving target and the
    # `.sheet` never presents (verified live: an immediate click after the
    # coarse swipe loop missed, but a click after a ~0.8s settle opened the
    # address step). This is the residual "Proceed tap didn't present" case
    # from a long seeded cart.
    sim.wait(0.8)
    for _ in range(8):
        y = proceed_y()
        if y is None:
            return False
        # Acceptable window: clear of the top header (~y<150) and the bottom
        # tab bar (which sits at ~y>=810 on this 874-tall screen). The button is
        # ~53pt tall, so a top edge up to ~720 still leaves its center well above
        # the tab bar. The previous cap of 600 EXCLUDED the button's natural
        # rest position after a relaunch (verified live: from a freshly relaunched
        # cart the proceed button sits at y≈602, so the old window rejected it,
        # short-dragged forever, and the checkout flow "couldn't open" — the
        # select_delivery/checkout-from-after_search failure). Widen the cap.
        if 200 <= y <= 720:
            if click_proceed() and _wait_for_id(
                sim, "checkout_continue_address_button", timeout=4.0
            ):
                return True
            # Tap landed but no sheet — nudge a little and retry.
            short_drag(60)
            continue
        # Nudge the button toward the middle of the screen.
        short_drag(min(max(y - 430, -200), 200))
    # Last resort: a plain tap (works when the cart is short enough that the
    # button is already clear of the tab bar).
    if click_proceed() and _wait_for_id(
        sim, "checkout_continue_address_button", timeout=4.0
    ):
        return True
    return _wait_for_id(sim, "checkout_continue_address_button", timeout=0.5)


def _checkout_fill_form() -> Optional[str]:
    """Walk the checkout flow up to (but not including) Place Order.

    Taps proceed → address → delivery → payment continue buttons so the
    Place Order screen is visible. Returns None on success or a
    precondition message on failure. Used by both `checkout` (one-shot
    commit) and `prepare_checkout` (capture-only). Stops short of
    tapping `checkout_place_order_button` so the caller decides whether
    to commit.

    Each step waits (polls) for its continue button to render before
    tapping, because the SwiftUI checkout sheet animates between steps
    and a fixed short sleep races the navigation transition (the prior
    bug: payment-step continue button "still not visible after tap").
    """
    sim = SimulatorBridge.get()
    # Make sure we're on the cart with the proceed button before starting.
    if not _wait_for_id(sim, "proceed_to_checkout_button", timeout=1.5):
        # A search/detail overlay swallows the tab_cart tap (BUG CLASS 2); clear
        # it so we actually land on the cart.
        _dismiss_overlays(sim)
        try:
            sim.tap_id("tab_cart")
        except Exception:
            pass
        if not _wait_for_id(sim, "proceed_to_checkout_button", timeout=2.0):
            return (
                "Could not start checkout: the cart's Proceed to checkout "
                "button isn't visible. Add an item (add_to_cart) and open the "
                "cart (view_cart), then re-call."
            )
    # Step 1 (proceed) needs the occlusion-safe helper; the rest are plain
    # taps inside the already-presented checkout sheet.
    if not _tap_proceed_to_checkout(sim):
        return (
            "Could not open the checkout sheet (the Proceed to Checkout tap "
            "didn't present the address step). Ensure the cart has items, then "
            "re-call."
        )
    steps = [
        ("checkout_continue_address_button", "checkout_continue_delivery_button"),
        ("checkout_continue_delivery_button", "checkout_continue_payment_button"),
        ("checkout_continue_payment_button", "checkout_place_order_button"),
    ]
    for tap_aid, expect_aid in steps:
        try:
            sim.tap_id(tap_aid)
        except Exception as exc:
            return (
                f"Could not advance checkout: tapping '{tap_aid}' failed. Open "
                f"the cart via view_cart() and ensure items are present, then "
                f"re-call. {str(exc)[:120]}"
            )
        if not _wait_for_id(sim, expect_aid, timeout=4.0):
            return (
                f"Could not advance checkout: after '{tap_aid}', the next control "
                f"'{expect_aid}' did not appear. Ensure the cart has items and a "
                "delivery address / payment method are available, then re-call."
            )
    return None


@mcp.tool()
def checkout() -> str:
    """Walk the entire checkout flow and place the order (one-shot commit).

    Works from any screen — self-navigates to the Cart (dismissing overlays)
    and scroll-positions the Proceed-to-Checkout button (it sits below the tab
    bar in a long seeded cart) before tapping through proceed -> address ->
    delivery -> payment -> place order -> confirmation. Uses default address /
    delivery / payment unless you set them first (e.g. select_delivery_option).

    Precondition: the cart must contain at least one item (call `add_to_cart`
    first). Returns a controlled message instead of placing an order if the
    cart is empty or any checkout step's continue button fails to appear.

    Legacy single-verb commit. Prefer `prepare_checkout` + `confirm_checkout`
    for new code so the agent can inspect the staged order before committing.
    """
    sim = SimulatorBridge.get()
    err = _checkout_fill_form()
    if err:
        return err
    sim.tap_id("checkout_place_order_button")
    sim.wait(0.5)
    ui = sim.tap_and_observe("checkout_confirmation_button")
    return f"Checkout complete.\n\n{ui}"


@mcp.tool()
def prepare_checkout() -> dict:
    """Walk the checkout flow up to the Place Order screen WITHOUT committing.

    Works from any screen — self-navigates to the Cart and scroll-positions /
    taps Proceed (handling the long-cart / tab-bar-occlusion cases), then taps
    through address, delivery, and payment continue buttons so the Place Order
    screen is visible. Does NOT tap `checkout_place_order_button`.

    Precondition: the cart must contain at least one item (call `add_to_cart`
    first). Returns ``{ok: True, action: "prepare_checkout", draft_id, summary}``
    on success — pass ``draft_id`` to `confirm_checkout` to place the order. On
    any failure (empty cart, a step's continue button never appeared), returns
    ``{ok: False, message}`` and stores no draft.
    """
    err = _checkout_fill_form()
    if err:
        return {"ok": False, "action": "prepare_checkout", "message": err}
    summary: dict = {}
    draft_id = ts.create_draft("megamart", "checkout", summary)
    return {
        "ok": True,
        "action": "prepare_checkout",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_checkout(draft_id) to commit.",
    }


@mcp.tool()
def confirm_checkout(draft_id: str) -> dict:
    """Commit a checkout previously staged by `prepare_checkout`.

    Args:
        draft_id: The id returned by `prepare_checkout`.

    Returns ``{ok: True, action: "confirm_checkout", evidence: <summary>}`` on
    success, or a controlled-failure response if the draft is missing/expired
    or the Place Order button is no longer visible.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_checkout first.",
        }
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("checkout_place_order_button"); sim.wait(0.5)
        sim.tap_id("checkout_confirmation_button"); sim.wait(0.4)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": "Place Order button not found in current UI; verify the checkout flow is still open.",
        }
    return {"ok": True, "action": "confirm_checkout", "evidence": draft.get("payload", {})}


@mcp.tool()
def view_orders() -> str:
    """Navigate into the Orders view so `order_row_<order_number>` rows show.

    Works from any screen — clears any search/detail overlay, switches to the
    Account tab, and opens the OrdersView via the "Your orders" tile. Polls
    until the order rows actually render, and returns a controlled "Could not
    open the Orders view" message (not a bare success) if navigation fails.

    After this, call `list_orders` to read the visible `order_row_<order_number>`
    numbers, then `open_order(<order_number>)` to surface per-order action
    buttons. NOTE: OrdersView defaults to the "active" segment; delivered/
    returned and canceled orders live behind other segments. The order action
    verbs (open_order / buy_again / cancel_order / return_or_replace /
    open_order_help) self-navigate AND auto-select the correct segment, so you
    can pass an order number to them directly without calling this first.
    """
    sim = SimulatorBridge.get()
    # A search/detail overlay can sit above the tab bar and swallow the
    # tab_account tap (BUG CLASS 2). Clear it first so we actually land on the
    # Account screen and the "Your orders" tile is reachable.
    ok, _ = _go_tab(sim, "account")
    if not ok:
        return (
            "Could not open the Account tab before Orders. Call list_orders() "
            "to read order numbers from persisted state."
        )
    # NOTE: the signed-in orders tile carries accessibilityIdentifier
    # "account_action_your_orders" in AccountView.swift, but SwiftUI folds
    # the NavigationLink's child labels into a single combined a11y label
    # ("Your orders, <N> orders") and DROPS the identifier from the tree —
    # so an id-based tap never matches. We tap the combined label instead
    # (count comes from shared state), then fall back to the bare "Your
    # orders" tile and the signed-out helpful row.
    tapped = False
    order_count = len(_load_state().get("orders", []) or [])
    candidates = [
        f"Your orders, {order_count} orders",
        "account_action_your_orders",
        "Check order status and track,\nchange or return items",
    ]
    for label in candidates:
        try:
            err = sim.tap_and_verify_changed(label, settle=0.6)
            if not err:
                tapped = True
                break
        except Exception:
            continue
    if not tapped:
        # last resort: plain id / label taps without change-verification
        for label in ("account_action_your_orders", "Your orders"):
            try:
                sim.tap_id(label); sim.wait(0.6); tapped = True; break
            except Exception:
                continue
    # Confirm we actually reached the Orders screen AND captured its rows rather
    # than reporting a bare success (BUG CLASS 4). The OrdersView renders
    # order_row_<n> rows and an `orders_segment_active` segment control. The
    # embedded page-source can come back momentarily empty (screenshot-only
    # fallback) right after navigation on this lane, so we poll a few times for a
    # tree that actually carries the order rows before returning — otherwise the
    # agent gets a "Viewing orders" string with no rows to act on.
    ui = ""
    on_orders = False
    for _ in range(4):
        ui = sim.observe_text() or ""
        if "order_row_" in ui or "orders_segment_" in ui:
            on_orders = True
            break
        sim.wait(0.5)
    if not on_orders:
        return (
            "Could not open the Orders view (the Your orders tile didn't "
            "navigate, or the order list didn't render). Call list_orders() "
            "to read order numbers from persisted state, or retry view_orders() "
            "after opening the Account tab."
        )
    return f"Viewing orders.\n\n{ui}"


def _ensure_detail_open(sim, product_id: str) -> bool:
    """Make sure the ProductDetailView for `product_id` is on screen.

    The `save_item_<id>` / detail `add_to_cart_<id>` controls live on the
    ProductDetailView, not on the Home/Search cards. If the detail isn't
    already open we tap the Home rail's `product_row_<id>` (the only place
    the row id is real and tappable) to push it. Returns True if the
    detail's save button is present afterwards.
    """
    def has_save() -> bool:
        tree = sim.observe_text() or ""
        return f"save_item_{product_id}" in tree
    if has_save():
        return True
    # Clear any search/stale-detail overlay so tab_home + product_row_ tap land
    # on the real Home rail (BUG CLASS 2).
    _dismiss_overlays(sim)
    try:
        sim.tap_id("tab_home"); sim.wait(0.4)
    except Exception:
        pass
    try:
        sim.tap_id(f"product_row_{product_id}"); sim.wait(0.8)
    except Exception:
        return has_save()
    return has_save()


@mcp.tool()
def save_item(product_id: str) -> str:
    """Save a product for later (Your Lists) via its detail-page Save control.

    Works from any screen — self-navigates (dismisses overlays, taps the Home
    rail's `product_row_<id>`, else opens the product via Search) to the detail
    page, where the `save_item_<id>` control lives, before tapping Save.

    Args:
        product_id: A product slug like the ones `search_products` returns
            (e.g. "mechanical_keyboard_003"), OR a fuzzy display NAME (e.g.
            "keychron keyboard"). Both forms resolve.

    Controlled failure: unknown/ambiguous product, or the detail page couldn't
    be opened -> "Could not find/open ..." message (nothing saved).
    """
    sim = SimulatorBridge.get()
    resolved, name = _resolve_product(product_id)
    if not resolved:
        return (
            f"Could not find a product matching '{product_id}'. Use "
            f"search_products() to discover valid product ids/names, then retry."
        )
    # Route through the unified detail opener (dismisses search/cart overlays,
    # taps the real Home-rail row, falls back to Search, and CONFIRMS the
    # detail-only save_item_<id> rendered). This is the same path add_to_cart
    # uses, so save_item is robust from the same messy states.
    if not _open_product_detail(sim, resolved, name):
        return (
            f"Could not open product '{resolved}' to save it. Use "
            f"search_products() to get a valid slug, then retry."
        )
    if not _has_id(sim, f"save_item_{resolved}"):
        return (
            f"Could not surface the Save control for product '{resolved}'. "
            f"Call observe() and retry."
        )
    ui = sim.tap_and_observe(f"save_item_{resolved}")
    return f"Saved product '{resolved}' for later.\n\n{ui}"


@mcp.tool()
def view_product(product_name: str) -> str:
    """Open a product's detail page.

    Works from any screen — self-navigates (dismisses overlays, taps the Home
    rail's `product_row_<id>`, else opens the product via Search) and confirms
    the real detail page rendered (its detail-only `save_item_<id>` marker)
    before reporting success.

    Args:
        product_name: Despite the name, accepts EITHER a product slug like the
            ones `search_products` returns (e.g. "mechanical_keyboard_003") OR
            a fuzzy display NAME (e.g. "keychron keyboard"). Both resolve.

    Controlled failure: unknown/ambiguous product, or the detail couldn't be
    opened -> "Could not find/open ..." message.
    """
    sim = SimulatorBridge.get()
    resolved, name = _resolve_product(product_name)
    if not resolved:
        return (
            f"Could not find a product matching '{product_name}'. Use "
            f"search_products() to discover valid product ids/names, then retry."
        )
    # BUG CLASS 1+4: after a search/cart-tab, a `product_row_<id>` for this
    # product can be present in the tree as a SEARCH-RESULT / CART card that
    # does NOT push the working ProductDetailView. The previous fast path
    # tapped that row and returned success WITHOUT confirming the detail had
    # opened (verified live: from after_cart_tab / after_search, tapping the
    # stale product_row_ left save_item_<id> absent yet still reported
    # "Viewing product"). Route through _open_product_detail, which dismisses
    # overlays, taps the real Home-rail row, and — crucially — confirms the
    # detail-only `save_item_<id>` marker rendered (falling back to Search for
    # off-rail products). Only report success when the detail is truly open.
    if _open_product_detail(sim, resolved, name) and _on_product_detail(sim, resolved):
        return f"Viewing product '{resolved}'.\n\n{sim.observe_text()}"
    return (
        f"Could not open the detail page for product '{resolved}'. Use "
        f"search_products() and retry."
    )


@mcp.tool()
def adjust_quantity(product_id: str, increment: bool) -> str:
    """Increment or decrement a cart item's quantity by one.

    Works from any screen — self-navigates to the Cart tab and scrolls to load
    all rows before matching the item.

    Args:
        product_id: The cart item's product slug (the `<slug>` of its
            `cart_item_<slug>` row, e.g. "mechanical_keyboard_003"), OR a fuzzy
            display NAME / slug fragment for an item already in the cart. All
            forms resolve against the loaded cart rows.
        increment: True taps `cart_quantity_increment_<slug>`, False taps
            `cart_quantity_decrement_<slug>`.

    Controlled failure: the target isn't in the cart -> "No cart item matching
    ..." (call view_cart() to see what's in the cart).
    """
    sim = SimulatorBridge.get()
    resolved = _resolve_cart_item(sim, product_id)
    if not resolved:
        return (
            f"No cart item matching '{product_id}'. Call view_cart() to see "
            f"the cart's item ids first."
        )
    aid = f"cart_quantity_increment_{resolved}" if increment else f"cart_quantity_decrement_{resolved}"
    sim.tap_id(aid); sim.wait(0.3)
    return f"{'Incremented' if increment else 'Decremented'} quantity for product '{resolved}'."


@mcp.tool()
def remove_from_cart(product_id: str) -> str:
    """Remove an item from the cart by tapping `cart_remove_<slug>`.

    Works from any screen — self-navigates to the Cart tab and scrolls to load
    all rows before removing the item.

    Args:
        product_id: The cart item's product slug (the `<slug>` of its
            `cart_item_<slug>` row), OR a fuzzy display NAME / slug fragment
            for an item already in the cart. All forms resolve.

    Controlled failure: the target isn't in the cart -> "No cart item matching
    ..." (call view_cart() to see the cart).
    """
    sim = SimulatorBridge.get()
    resolved = _resolve_cart_item(sim, product_id)
    if not resolved:
        return (
            f"No cart item matching '{product_id}'. Call view_cart() to see "
            f"the cart's item ids first."
        )
    sim.tap_id(f"cart_remove_{resolved}"); sim.wait(0.3)
    return f"Removed product '{resolved}' from cart."


@mcp.tool()
def move_to_saved(product_id: str) -> str:
    """Move a cart item to Saved for Later via `cart_move_to_saved_<slug>`.

    Works from any screen — self-navigates to the Cart tab and scrolls to load
    all rows before moving the item.

    Args:
        product_id: The cart item's product slug (the `<slug>` of its
            `cart_item_<slug>` row), OR a fuzzy display NAME / slug fragment
            for an item already in the cart. All forms resolve.

    Controlled failure: the target isn't in the cart -> "No cart item matching
    ..." (call view_cart() to see the cart).
    """
    sim = SimulatorBridge.get()
    resolved = _resolve_cart_item(sim, product_id)
    if not resolved:
        return (
            f"No cart item matching '{product_id}'. Call view_cart() to see "
            f"the cart's item ids first."
        )
    sim.tap_id(f"cart_move_to_saved_{resolved}"); sim.wait(0.3)
    return f"Moved '{resolved}' to saved."


def _scroll_to_id(sim, aid: str, max_swipes: int = 6) -> bool:
    """Swipe the current scroll view up until `aid` renders. Returns hit."""
    for _ in range(max_swipes):
        tree = sim.observe_text() or ""
        if f'"{aid}"' in tree or f"name=\"{aid}\"" in tree:
            return True
        try:
            sim.swipe("up")
        except Exception:
            break
        sim.wait(0.3)
    tree = sim.observe_text() or ""
    return f'"{aid}"' in tree


def _walk_to_payment_step(sim) -> Optional[str]:
    """Drive the checkout flow to the PAYMENT step (gift toggle lives there).

    The gift toggle ("This order contains a gift") is rendered on the
    checkout *payment* step in CartView.swift, NOT on the cart list. We tap
    proceed → address-continue → delivery-continue, stopping when
    `checkout_continue_payment_button` (and the gift toggle alongside it)
    are on screen. Returns None on success or a precondition message.
    """
    if "gift_option_toggle" in (sim.observe_text() or ""):
        return None
    if not _wait_for_id(sim, "proceed_to_checkout_button", timeout=1.0):
        # Clear a search/detail overlay that would swallow the tab_cart tap.
        _dismiss_overlays(sim)
        try:
            sim.tap_id("tab_cart")
        except Exception:
            pass
        if not _wait_for_id(sim, "proceed_to_checkout_button", timeout=2.0):
            return (
                "Could not set the gift option: the cart's Proceed to checkout "
                "button isn't visible. Add an item (add_to_cart) and open the "
                "cart (view_cart), then retry."
            )
    # Proceed needs the occlusion-safe helper (see _tap_proceed_to_checkout).
    if not _tap_proceed_to_checkout(sim):
        return (
            "Could not set the gift option: the checkout sheet didn't open. "
            "Ensure the cart has items, then retry."
        )
    steps = [
        ("checkout_continue_address_button", "checkout_continue_delivery_button"),
        ("checkout_continue_delivery_button", "checkout_continue_payment_button"),
    ]
    for tap_aid, expect_aid in steps:
        try:
            sim.tap_id(tap_aid)
        except Exception as exc:
            return (
                f"Could not set the gift option: tapping '{tap_aid}' failed. "
                f"Ensure the cart has items, then retry. {str(exc)[:100]}"
            )
        if not _wait_for_id(sim, expect_aid, timeout=4.0):
            return (
                f"Could not set the gift option: after '{tap_aid}', '{expect_aid}' "
                "did not appear. Ensure the cart has items and an address / "
                "payment method are available, then retry."
            )
    return None


@mcp.tool()
def toggle_gift_option(message: str = "") -> str:
    """Toggle gift-wrap on the order and optionally fill the gift message.

    The gift toggle lives on the checkout PAYMENT step (not the cart list).
    Works from any screen — self-navigates to the Cart and drives the checkout
    flow (proceed -> address -> delivery) to the payment step before tapping
    `gift_option_toggle`. Does not place the order.

    Args:
        message: Optional gift-message text. If non-empty, taps and types into
            `gift_message_field` after toggling.

    Precondition: the cart must contain at least one item (call `add_to_cart`).
    Returns a controlled message instead of toggling if the cart is empty or a
    checkout step's continue button fails to appear.
    """
    sim = SimulatorBridge.get()
    err = _walk_to_payment_step(sim)
    if err:
        return err
    sim.tap_id("gift_option_toggle"); sim.wait(0.4)
    if message:
        if _wait_for_id(sim, "gift_message_field", timeout=2.0):
            try:
                sim.tap_id("gift_message_field"); sim.wait(0.2)
                sim.type_text(message); sim.wait(0.2)
            except Exception:
                pass
    return f"Toggled gift option (message: '{message}')."


@mcp.tool()
def list_orders() -> dict:
    """List order numbers, preferring the visible Orders view and falling back to state.

    Returns: ``{orders: [order_number, ...], count}``. Each entry is the
    `<order_number>` suffix of an `order_row_<order_number>` accessibility ID
    (e.g. "AMZ100251"), suitable for `open_order` and the buy_again /
    cancel_order / return_or_replace / open_order_help verbs.

    Works even when the SwiftUI Orders view failed to render rows: if no
    `order_row_...` ids are visible, reads the persisted app state and returns
    all seeded order numbers with status metadata.
    """
    import re
    sim = SimulatorBridge.get()
    tree = sim.observe_text()
    nums = sorted(set(re.findall(r'order_row_([^"\s]+)', tree)))
    if nums:
        return {"orders": nums, "count": len(nums), "source": "visible_ui"}
    state_orders = _load_state().get("orders", []) or []
    rows = [
        {
            "order_number": o.get("orderNumber"),
            "id": o.get("id"),
            "status": o.get("status") or o.get("orderStatus"),
            "total": o.get("total"),
        }
        for o in state_orders
        if o.get("orderNumber")
    ]
    nums = [o["order_number"] for o in rows]
    return {"orders": nums, "count": len(nums), "source": "state", "details": rows}


@mcp.tool()
def open_order(order_number: str) -> str:
    """Open an order's detail screen (where the per-order actions live).

    Works from any screen — self-navigates (Account -> Your orders), selects
    the segment matching the order's status (active / delivered / canceled),
    scrolls the list to surface the row, taps it, and confirms an action button
    rendered. Opening the detail exposes `order_buy_again_<n>`,
    `order_cancel_<n>`, `order_return_replace_<n>`, `order_help_<n>`.

    Args:
        order_number: A full order number like the ones `list_orders` shows
            (e.g. "AMZ100251"), a bare numeric suffix ("100251"), or a unique
            substring. An ambiguous/non-unique numeric suffix is NOT guessed.

    Controlled failure: no order matches -> "No order matching ..." (call
    view_orders() then list_orders() to see valid order numbers).
    """
    sim = SimulatorBridge.get()
    resolved = _resolve_order_number(order_number)
    if not resolved:
        return (
            f"No order matching '{order_number}'. Call view_orders() then "
            f"list_orders() to see valid order numbers."
        )
    order = _find_order(_load_state(), resolved)
    if _ensure_order_detail(sim, resolved):
        return f"Opened order {resolved}."
    # Fallback: row may be on screen even if detail markers differ.
    err = sim.tap_and_verify_changed(
        f"order_row_{resolved}",
        prefix_for_failure=f"No order row matching '{resolved}' visible. Use view_orders() and list_orders() first. ",
    )
    if err:
        if order:
            return {
                "ok": True,
                "action": "open_order",
                "order_number": resolved,
                "source": "state",
                "opened_ui": False,
                "order": _order_summary(order),
                "message": (
                    f"Order '{resolved}' exists in persisted state, but its "
                    "UI row was not reachable in this session."
                ),
            }
        return err
    return f"Opened order {resolved}."


def _buy_again_fill_form(order_number: str) -> Optional[str]:
    """Validate that a buy-again action is reachable for `order_number`.

    There are no fields to pre-fill for this action — the helper is a
    no-op stub so the legacy verb and the prepare_*/confirm_* pair share
    the same shape. Returns None on success or a precondition message on
    failure. Stops short of tapping `order_buy_again_<order_number>` so
    the caller decides whether to commit.
    """
    if not order_number:
        return "Missing order_number. Use list_orders() to find a valid order."
    return None


@mcp.tool()
def buy_again(order_number: str) -> str:
    """Re-order a past order's items (taps `order_buy_again_<n>`).

    Works from any screen — resolves the order number then self-navigates to
    open its detail before tapping Buy Again. If the UI tap can't be issued it
    falls back to adding the order's items to the cart via shared state, so the
    re-order still lands.

    Args:
        order_number: A full order number like the ones `list_orders` shows
            (e.g. "AMZ100251"), a bare numeric suffix, or a unique substring.

    Returns a confirmation string on the UI path, or an ``{ok: ...}`` dict on
    the state-fallback path. Controlled failure: unknown order -> ``{ok: False,
    message}``. Legacy single-verb commit; prefer `prepare_buy_again` +
    `confirm_buy_again` for new code.
    """
    sim = SimulatorBridge.get()
    err = _buy_again_fill_form(order_number)
    if err:
        return err
    resolved = _resolve_order_number(order_number) or order_number
    _ensure_order_detail(sim, resolved)
    try:
        sim.tap_id(f"order_buy_again_{resolved}"); sim.wait(0.4)
        return f"Re-ordering items from {resolved}."
    except Exception:
        result = _buy_again_state(resolved)
        if result.get("ok"):
            return {"ok": True, "action": "buy_again", "state_fallback": result}
        return {"ok": False, "action": "buy_again", "message": result.get("error", str(result))}


@mcp.tool()
def prepare_buy_again(order_number: str) -> dict:
    """Stage a buy-again on a past order WITHOUT committing.

    Capture-only: validates the order number is present and stores a draft; it
    does NOT navigate or tap. `confirm_buy_again` does the navigation + commit.

    Args:
        order_number: A full order number like the ones `list_orders` shows
            (e.g. "AMZ100251"), a numeric suffix, or a unique substring.

    Returns ``{ok: True, draft_id, summary: {order_number}, next}`` on success.
    Pass the ``draft_id`` to `confirm_buy_again` to actually re-order. On
    failure (missing order_number), returns ``{ok: False, message}`` and stores
    no draft.
    """
    err = _buy_again_fill_form(order_number)
    if err:
        return {"ok": False, "action": "prepare_buy_again", "message": err}
    summary = {"order_number": order_number}
    draft_id = ts.create_draft("megamart", "buy_again", summary)
    return {
        "ok": True,
        "action": "prepare_buy_again",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_buy_again(draft_id) to commit.",
    }


@mcp.tool()
def confirm_buy_again(draft_id: str) -> dict:
    """Commit a buy-again previously staged by `prepare_buy_again`.

    Works from any screen — resolves the staged order number and self-navigates
    to open its detail before tapping Buy Again. If the UI tap can't be issued
    it falls back to re-ordering the items via shared state.

    Args:
        draft_id: The id returned by `prepare_buy_again`.

    Returns ``{ok: True, evidence}`` on success (evidence notes any state
    fallback). Controlled failure: draft missing/expired, or both the UI tap
    and the state fallback failed -> ``{ok: False, message}``.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_buy_again",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_buy_again first.",
        }
    payload = draft.get("payload", {})
    order_number = payload.get("order_number", "")
    sim = SimulatorBridge.get()
    order_number = _resolve_order_number(order_number) or order_number
    _ensure_order_detail(sim, order_number)
    try:
        sim.tap_id(f"order_buy_again_{order_number}"); sim.wait(0.4)
    except Exception:
        result = _buy_again_state(order_number)
        if result.get("ok"):
            return {
                "ok": True,
                "action": "confirm_buy_again",
                "evidence": {**payload, "state_fallback": result},
            }
        return {
            "ok": False,
            "action": "confirm_buy_again",
            "message": (
                f"Buy-again button for '{order_number}' not found in current UI and "
                f"shared-state fallback failed: {result.get('error', str(result))}."
            ),
        }
    return {"ok": True, "action": "confirm_buy_again", "evidence": payload}


def _cancel_order_fill_form(order_number: str) -> Optional[str]:
    """Validate that a cancel action is reachable for `order_number`.

    There are no fields to pre-fill for this action — the helper is a
    no-op stub so the legacy verb and the prepare_*/confirm_* pair share
    the same shape. Returns None on success or a precondition message on
    failure. Stops short of tapping `order_cancel_<order_number>` so the
    caller decides whether to commit.
    """
    if not order_number:
        return "Missing order_number. Use list_orders() to find a valid order."
    resolved = _resolve_order_number(order_number)
    if not resolved:
        return f"No order matching '{order_number}'. Call list_orders() to find a valid order."
    state = _load_state()
    order = _find_order(state, resolved)
    status = (order or {}).get("status")
    if status not in {"ordered", "preparingForShipment"}:
        return f"Order '{resolved}' is not cancellable from status '{status}'."
    return None


@mcp.tool()
def cancel_order(order_number: str) -> str:
    """Cancel an order (taps `order_cancel_<n>`).

    Works from any screen — resolves the order number then self-navigates to
    open its detail before tapping Cancel. If the UI tap can't be issued it
    falls back to canceling via shared state.

    Args:
        order_number: A full order number like the ones `list_orders` shows
            (e.g. "AMZ100251"), a numeric suffix, or a unique substring.

    Returns a confirmation string on the UI path, or an ``{ok: ...}`` dict on
    the state-fallback path. Controlled failure: unknown order, or (on the
    state path) an order whose status isn't cancellable (only "ordered" /
    "preparingForShipment" can be canceled) -> ``{ok: False, message}``.
    Legacy single-verb commit; prefer `prepare_cancel_order` +
    `confirm_cancel_order` for new code.
    """
    sim = SimulatorBridge.get()
    err = _cancel_order_fill_form(order_number)
    if err:
        return err
    resolved = _resolve_order_number(order_number) or order_number
    _ensure_order_detail(sim, resolved)
    try:
        sim.tap_id(f"order_cancel_{resolved}"); sim.wait(0.4)
        return f"Cancelled order {resolved}."
    except Exception:
        result = _cancel_order_state(resolved)
        if result.get("ok"):
            return {"ok": True, "action": "cancel_order", "state_fallback": result}
        return {"ok": False, "action": "cancel_order", "message": result.get("error", str(result))}


@mcp.tool()
def prepare_cancel_order(order_number: str) -> dict:
    """Stage an order cancellation WITHOUT committing.

    Capture-only: validates the order number is present and stores a draft; it
    does NOT navigate or tap. `confirm_cancel_order` does the navigation +
    commit (including the not-cancellable-status check on the state path).

    Args:
        order_number: A full order number like the ones `list_orders` shows
            (e.g. "AMZ100251"), a numeric suffix, or a unique substring.

    Returns ``{ok: True, draft_id, summary: {order_number}, next}`` on success.
    Pass the ``draft_id`` to `confirm_cancel_order` to actually cancel. On
    failure (missing order_number), returns ``{ok: False, message}`` and stores
    no draft.
    """
    err = _cancel_order_fill_form(order_number)
    if err:
        return {"ok": False, "action": "prepare_cancel_order", "message": err}
    resolved = _resolve_order_number(order_number) or order_number
    summary = {"order_number": resolved}
    draft_id = ts.create_draft("megamart", "cancel_order", summary)
    return {
        "ok": True,
        "action": "prepare_cancel_order",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_cancel_order(draft_id) to commit.",
    }


@mcp.tool()
def confirm_cancel_order(draft_id: str) -> dict:
    """Commit a cancellation previously staged by `prepare_cancel_order`.

    Works from any screen — resolves the staged order number and self-navigates
    to open its detail before tapping Cancel. If the UI tap can't be issued it
    falls back to canceling via shared state (which rejects orders whose status
    isn't "ordered" / "preparingForShipment").

    Args:
        draft_id: The id returned by `prepare_cancel_order`.

    Returns ``{ok: True, evidence}`` on success (evidence notes any state
    fallback). Controlled failure: draft missing/expired, or both the UI tap
    and the state fallback failed (e.g. order not cancellable) -> ``{ok: False,
    message}``.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_cancel_order",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_cancel_order first.",
        }
    payload = draft.get("payload", {})
    order_number = payload.get("order_number", "")
    sim = SimulatorBridge.get()
    order_number = _resolve_order_number(order_number) or order_number
    _ensure_order_detail(sim, order_number)
    try:
        sim.tap_id(f"order_cancel_{order_number}"); sim.wait(0.4)
    except Exception:
        result = _cancel_order_state(order_number)
        if result.get("ok"):
            return {
                "ok": True,
                "action": "confirm_cancel_order",
                "evidence": {**payload, "state_fallback": result},
            }
        return {
            "ok": False,
            "action": "confirm_cancel_order",
            "message": (
                f"Cancel button for '{order_number}' not found in current UI and "
                f"shared-state fallback failed: {result.get('error', str(result))}."
            ),
        }
    return {"ok": True, "action": "confirm_cancel_order", "evidence": payload}


def _return_or_replace_fill_form(order_number: str) -> Optional[str]:
    """Validate that a return/replace action is reachable for `order_number`.

    There are no fields to pre-fill for this action — the helper is a
    no-op stub so the legacy verb and the prepare_*/confirm_* pair share
    the same shape. Returns None on success or a precondition message on
    failure. Stops short of tapping
    `order_return_replace_<order_number>` so the caller decides whether
    to commit.
    """
    if not order_number:
        return "Missing order_number. Use list_orders() to find a valid order."
    return None


@mcp.tool()
def return_or_replace(order_number: str) -> str:
    """Start a return/replace flow (taps `order_return_replace_<n>`).

    Works from any screen — resolves the order number then self-navigates to
    open its detail (selecting the order's status segment, scrolling to the
    row) before tapping Return/Replace. Typically applies to delivered orders.

    Args:
        order_number: A full order number like the ones `list_orders` shows
            (e.g. "AMZ100251"), a numeric suffix, or a unique substring.

    Controlled failure: the order couldn't be opened -> "Could not open order
    ..."; the control isn't tappable (may be disabled for this order's status)
    -> explicit message. Legacy single-verb commit; prefer
    `prepare_return_or_replace` + `confirm_return_or_replace` for new code.
    """
    sim = SimulatorBridge.get()
    err = _return_or_replace_fill_form(order_number)
    if err:
        return err
    resolved = _resolve_order_number(order_number) or order_number
    if not _ensure_order_detail(sim, resolved):
        return (
            f"Could not open order '{resolved}' to start a return. Call "
            f"view_orders() and list_orders() to confirm the order number."
        )
    try:
        sim.tap_id(f"order_return_replace_{resolved}"); sim.wait(0.4)
    except Exception as exc:
        return (
            f"Return/replace control for '{resolved}' not tappable "
            f"(it may be disabled for this order's status). {str(exc)[:100]}"
        )
    return f"Started return/replace on {resolved}."


@mcp.tool()
def prepare_return_or_replace(order_number: str) -> dict:
    """Stage a return/replace on an order WITHOUT committing.

    Capture-only: validates the order number is present and stores a draft; it
    does NOT navigate or tap. `confirm_return_or_replace` does the navigation +
    commit.

    Args:
        order_number: A full order number like the ones `list_orders` shows
            (e.g. "AMZ100251"), a numeric suffix, or a unique substring.

    Returns ``{ok: True, draft_id, summary: {order_number}, next}`` on success.
    Pass the ``draft_id`` to `confirm_return_or_replace` to actually start the
    return. On failure (missing order_number), returns ``{ok: False, message}``
    and stores no draft.
    """
    err = _return_or_replace_fill_form(order_number)
    if err:
        return {"ok": False, "action": "prepare_return_or_replace", "message": err}
    summary = {"order_number": order_number}
    draft_id = ts.create_draft("megamart", "return_or_replace", summary)
    return {
        "ok": True,
        "action": "prepare_return_or_replace",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_return_or_replace(draft_id) to commit.",
    }


@mcp.tool()
def confirm_return_or_replace(draft_id: str) -> dict:
    """Commit a return/replace previously staged by `prepare_return_or_replace`.

    Works from any screen — resolves the staged order number and self-navigates
    to open its detail before tapping Return/Replace.

    Args:
        draft_id: The id returned by `prepare_return_or_replace`.

    Returns ``{ok: True, evidence}`` on success. Controlled failure: draft
    missing/expired, or the return/replace button couldn't be tapped (e.g. the
    detail isn't open / the action is disabled for this order) -> ``{ok: False,
    message}``.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_return_or_replace",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_return_or_replace first.",
        }
    payload = draft.get("payload", {})
    order_number = payload.get("order_number", "")
    sim = SimulatorBridge.get()
    order_number = _resolve_order_number(order_number) or order_number
    _ensure_order_detail(sim, order_number)
    try:
        sim.tap_id(f"order_return_replace_{order_number}"); sim.wait(0.4)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_return_or_replace",
            "message": f"Return/replace button for '{order_number}' not found in current UI; verify the orders view is still open.",
        }
    return {"ok": True, "action": "confirm_return_or_replace", "evidence": payload}


@mcp.tool()
def open_order_help(order_number: str) -> str:
    """Open help/support for an order (taps `order_help_<n>`).

    Works from any screen — resolves the order number then self-navigates
    (Account -> Your orders, selecting the order's status segment, scrolling to
    the row, opening the detail, then scrolling to the help action) before
    tapping it.

    Args:
        order_number: A full order number like the ones `list_orders` shows
            (e.g. "AMZ100251"), a numeric suffix, or a unique substring.

    Controlled failure: the order couldn't be opened -> "Could not open order
    ..."; the help action wasn't visible -> "No order help action matching ...".
    """
    sim = SimulatorBridge.get()
    resolved = _resolve_order_number(order_number) or order_number
    if not _ensure_order_detail(sim, resolved):
        return (
            f"Could not open order '{resolved}'. Call view_orders() and "
            f"list_orders() to confirm the order number."
        )
    _scroll_to_id(sim, f"order_help_{resolved}", max_swipes=6)
    err = sim.tap_and_verify_changed(
        f"order_help_{resolved}",
        prefix_for_failure=f"No order help action matching '{resolved}' visible. ",
    )
    if err:
        return err
    return f"Opened help for {resolved}."


@mcp.tool()
def select_delivery_option(option_id: str) -> str:
    """Pick a delivery option on the checkout delivery step.

    Works from any screen — self-navigates from the Cart into the checkout flow
    (scroll/tap Proceed -> address-continue) to reach the delivery step, then
    taps `delivery_option_<option_id>`.

    Args:
        option_id: Exactly one of the three seeded options:
            `standard_delivery` (free, arrives tomorrow),
            `two_day_delivery` (+$4.99), or `same_day_delivery` (+$9.99).
            Convenience aliases are mapped automatically: `standard`,
            `two_day` / `express` (-> two_day_delivery), `same_day`.

    Precondition: the cart has at least one item (call add_to_cart first).
    Controlled failure: the checkout flow couldn't open, or the option couldn't
    be selected -> explicit message.
    """
    sim = SimulatorBridge.get()
    aliases = {
        "standard": "standard_delivery",
        "two_day": "two_day_delivery",
        "express": "two_day_delivery",
        "same_day": "same_day_delivery",
    }
    resolved = aliases.get(option_id, option_id)
    # Self-navigate to the delivery step if the option isn't already on screen.
    if f"delivery_option_{resolved}" not in (sim.observe_text() or ""):
        if not _tap_proceed_to_checkout(sim):
            return (
                f"Could not open the checkout flow to select delivery "
                f"'{resolved}'. Ensure the cart has items (add_to_cart), then retry."
            )
        # Address step -> delivery step.
        if "checkout_continue_address_button" in (sim.observe_text() or ""):
            try:
                sim.tap_id("checkout_continue_address_button"); sim.wait(0.6)
            except Exception:
                pass
        _wait_for_id(sim, f"delivery_option_{resolved}", timeout=2.0)
    err = sim.tap_and_verify_changed(
        f"delivery_option_{resolved}",
        prefix_for_failure=f"Could not select delivery option '{resolved}'. ",
        settle=0.3,
    )
    if err:
        return err
    return f"Selected delivery '{resolved}'."


if __name__ == "__main__":
    mcp.run()
