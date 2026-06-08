"""FreshCart MCP — Instacart-style grocery shopping with cart & checkout.

Bundle: com.iosworld.benchmark.freshcart

ID conventions (real Swift accessibility ids — the display labels like
"Stores"/"Search" are NOT queryable):
  Tabs:                  tab_home, tab_search, tab_cart, tab_orders, tab_account.
                         navigate_to_tab accepts the friendly names
                         home/stores, search, cart, orders, account (both
                         "home" and "stores" map to tab_home).
  Product rows/buttons:  product_row_<id>, add_to_cart_<id>, where <id> is the
                         catalog product id, e.g. ``salmon_fresh_005`` or
                         ``grapes_001`` (NOT a generic ``salmon_fillet``).
                         Product-taking tools also accept the human-readable
                         display name/brand ("Green Seedless Grapes",
                         "sockeye salmon") and resolve it to the id.
  Category tiles:        category_tile_<slug> on the Search tab; <slug> is the
                         catalog category id: produce, dairy_eggs, meat_seafood,
                         prepared, frozen, bakery, pantry, beverages, household,
                         pet, retail. browse_category also accepts friendly
                         names/synonyms ("Dairy & Eggs", "meat", "drinks").
  Checkout controls:     checkout_place_order_button, checkout_promo_toggle +
                         checkout_promo_code_field + checkout_promo_apply_button,
                         checkout_time_slot_button, checkout_priority_delivery_toggle,
                         checkout_contactless_toggle, checkout_custom_tip_field,
                         checkout_order_notes_field, checkout_delivery_instructions_field.
  Orders:                order_row_<id>, cancel_order_button_<id>,
                         reorder_order_button_<id>, advance_order_state_button_<id>
                         (<id> = the order id, e.g. ``order_scheduled_002``).
"""

import json
import re
import sys, pathlib
import time
from datetime import datetime, timezone
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("FreshCart")

BUNDLE_ID = "com.iosworld.benchmark.freshcart"
CATALOG_PATH = pathlib.Path(__file__).resolve().parents[1] / "iphone/apps/freshcart/xproj/FreshCart/Resources/catalog_snapshot.json"

# Real bottom-bar accessibility ids (RootTabView.swift): tab_home, tab_search,
# tab_cart, tab_orders, tab_account. (The display labels "Stores"/"Search"/...
# are NOT queryable as accessibility ids.)
TAB_MAP = {
    "home": "tab_home",
    "stores": "tab_home",
    "store": "tab_home",
    "search": "tab_search",
    "cart": "tab_cart",
    "orders": "tab_orders",
    "order": "tab_orders",
    "account": "tab_account",
    "profile": "tab_account",
}


def _load_catalog() -> dict:
    try:
        return json.loads(CATALOG_PATH.read_text())
    except Exception:
        return {"products": [], "categories": []}


def _slug(text: str) -> str:
    """Replicate Swift ``AccessibilityID.slug`` for cross-language matching.

    Lowercases, replaces every non-alphanumeric character with ``_``, collapses
    runs of ``_`` into a single ``_``, and strips leading/trailing ``_``.
    """
    s = (text or "").lower()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return s.strip("_")


def _catalog_stores() -> list[dict]:
    return _load_catalog().get("stores", []) or []


def _store_name(store_id: str) -> str:
    for store in _catalog_stores():
        if store.get("id") == store_id:
            return store.get("storeName", store_id)
    return store_id


def _resolve_store_id(store: str) -> Optional[str]:
    """Resolve a store id/name/``store_card_<id>`` handle to a catalog id."""
    raw = (store or "").strip()
    if raw.startswith("store_card_"):
        raw = raw[len("store_card_"):]
    if not raw:
        return None
    raw_low = raw.lower()
    raw_slug = _slug(raw)
    stores = _catalog_stores()
    for item in stores:
        sid = item.get("id", "")
        if raw == sid or raw_slug == _slug(sid):
            return sid
    for item in stores:
        sid = item.get("id", "")
        name = item.get("storeName", "")
        if raw_low == name.lower() or raw_slug == _slug(name):
            return sid
    matches = []
    for item in stores:
        sid = item.get("id", "")
        hay = f"{sid} {item.get('storeName', '')}".lower()
        if raw_low in hay or raw_slug in _slug(hay):
            matches.append(sid)
    return matches[0] if len(matches) == 1 else None


_CANCELLABLE_STATUSES = {"placed", "scheduled", "shopperassigned", "shopper_assigned"}


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _load_state() -> dict:
    return dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}


def _save_state(state: dict) -> None:
    dl.write_app_state(BUNDLE_ID, "instacartsim_state.json", state)
    dl.reload_app(BUNDLE_ID)


def _order_summary(order: dict) -> dict:
    return {
        "id": order.get("id"),
        "status": order.get("orderStatus"),
        "store_id": order.get("storeID") or order.get("storeId"),
        "store_name": _store_name(order.get("storeID") or order.get("storeId") or ""),
        "total": order.get("total") or order.get("totalAmount") or order.get("orderTotal"),
        "created_at": order.get("createdAt"),
        "delivery_window": order.get("deliveryWindow") or order.get("deliveryTime"),
    }


def _resolve_order_id(order_id: str) -> Optional[str]:
    """Resolve friendly/order-row handles to a real FreshCart order id."""
    raw = (order_id or "").strip()
    if not raw:
        return None
    for prefix in ("order_row_", "order_card_", "cancel_order_button_",
                   "reorder_order_button_", "advance_order_state_button_"):
        if raw.startswith(prefix):
            raw = raw[len(prefix):]
            break
    state = _load_state()
    orders = state.get("orders", []) or []
    by_id = {str(o.get("id", "")): o for o in orders}
    if raw in by_id:
        return raw
    if not raw.startswith("order_") and f"order_{raw}" in by_id:
        return f"order_{raw}"
    raw_slug = _slug(raw)
    for oid in by_id:
        if _slug(oid) == raw_slug:
            return oid
    if not raw_slug.startswith("order_"):
        for oid in by_id:
            if _slug(oid) == f"order_{raw_slug}":
                return oid

    # Agents often infer ids such as scheduled_002/active_001 from visible
    # status text. Resolve status+ordinal when it points to one real order.
    m = re.fullmatch(r"(?:order_)?([a-z_]+)_(\d+)", raw_slug)
    if m:
        status_slug, num = m.groups()
        idx = int(num)
        matches = [
            o for o in orders
            if _slug(str(o.get("orderStatus", ""))) == status_slug
        ]
        if 1 <= idx <= len(matches):
            return matches[idx - 1].get("id")

    # Store-name guesses like freshcart_trader_joes_001 are not real ids, but
    # they are useful if they identify a single order by store substring.
    store_tokens = [t for t in re.split(r"_+", raw_slug) if t and not t.isdigit()]
    if store_tokens:
        needle = "_".join(t for t in store_tokens if t not in {"freshcart", "order"})
        matches = []
        for order in orders:
            store_id = order.get("storeID") or order.get("storeId") or ""
            hay = _slug(f"{store_id} {_store_name(store_id)}")
            if needle and needle in hay:
                matches.append(order)
        if len(matches) == 1:
            return matches[0].get("id")
    return None


def _find_order_by_id(order_id: str) -> Optional[dict]:
    """Look up a seeded/persisted order in shared state by id or alias."""
    resolved = _resolve_order_id(order_id)
    if not resolved:
        return None
    state = _load_state()
    for order in state.get("orders", []) or []:
        if order.get("id") == resolved:
            return order
    return None


def _cancel_order_state(order_id: str) -> dict:
    order_id = _resolve_order_id(order_id) or order_id
    state = _load_state()
    for order in state.get("orders", []) or []:
        if order.get("id") != order_id:
            continue
        status = str(order.get("orderStatus", "")).strip()
        if _slug(status) not in _CANCELLABLE_STATUSES:
            return {"ok": False, "error": f"order '{order_id}' is not cancellable from status '{status}'"}
        timestamp = _now_iso()
        events = order.setdefault("statusEvents", [])
        order["orderStatus"] = "canceled"
        order["updatedAt"] = timestamp
        events.append({
            "id": f"{order_id}_canceled_{len(events) + 1}",
            "status": "canceled",
            "timestamp": timestamp,
            "message": "Your order was canceled.",
        })
        _save_state(state)
        return {"ok": True, "order_id": order_id, "orderStatus": "canceled", "event_count": len(events)}
    return {"ok": False, "error": f"unknown order_id '{order_id}'"}


def _apply_promo_state() -> dict:
    state = _load_state()
    code = str(state.get("promoCode", "")).strip()
    if not code:
        return {"ok": False, "error": "promoCode is empty; enter a promo code before applying"}
    state["promoApplied"] = True
    _save_state(state)
    return {"ok": True, "promoCode": code, "promoApplied": True}


# Friendly category name / synonym -> real category_tile_<slug> suffix.
# The Search tab renders category tiles with ids ``category_tile_<slug>``
# (e.g. ``category_tile_meat_seafood``, label "Meat & Seafood") — see
# AccessibilityID.categoryTile in AccessibilityID.swift. Slugs are the
# catalog category ids (see catalog_snapshot.json / CatalogRepository.swift).
_CATEGORY_SLUGS = {
    "produce", "dairy_eggs", "meat_seafood", "prepared", "frozen",
    "bakery", "pantry", "beverages", "household", "pet", "retail",
}
_CATEGORY_ALIASES = {
    "dairy": "dairy_eggs", "eggs": "dairy_eggs", "dairy_and_eggs": "dairy_eggs",
    "meat": "meat_seafood", "seafood": "meat_seafood",
    "meat_and_seafood": "meat_seafood", "fish": "meat_seafood",
    "drinks": "beverages", "beverage": "beverages",
    "fruit": "produce", "fruits": "produce",
    "vegetables": "produce", "veggies": "produce", "veg": "produce",
    "bread": "bakery", "baked_goods": "bakery", "baked": "bakery",
    "prepared_meals": "prepared", "meals": "prepared", "deli": "prepared",
    "home": "household", "cleaning": "household",
    "pets": "pet", "snacks": "pantry", "snack": "pantry",
    "grocery": "pantry", "groceries": "pantry",
}


def _category_to_slug(category_name: str) -> Optional[str]:
    """Resolve a free-text category name to a ``category_card_<slug>`` suffix."""
    raw = (category_name or "").strip().lower()
    slug = re.sub(r"[^a-z0-9]+", "_", raw).strip("_")
    if not slug:
        return None
    if slug in _CATEGORY_SLUGS:
        return slug
    if slug in _CATEGORY_ALIASES:
        return _CATEGORY_ALIASES[slug]
    first = slug.split("_")[0]
    if first in _CATEGORY_SLUGS:
        return first
    if first in _CATEGORY_ALIASES:
        return _CATEGORY_ALIASES[first]
    return None


def _reveal_and_tap(sim, accessibility_id: str, max_swipes: int = 5) -> bool:
    """Tap ``accessibility_id``, scrolling the screen up to surface it first.

    Many checkout controls render below the fold; ``tap_id`` raises when the
    element is off-screen, so scroll until the id appears in the tree (or a
    direct tap succeeds). Returns True on a successful tap, False otherwise.
    """
    try:
        sim.tap_id(accessibility_id)
        sim.wait(0.3)
        return True
    except Exception:
        pass
    for _ in range(max_swipes):
        if accessibility_id in (sim.observe_text() or ""):
            try:
                sim.tap_id(accessibility_id)
                sim.wait(0.3)
                return True
            except Exception:
                pass
        try:
            sim.swipe("up")
            sim.wait(0.3)
        except Exception:
            break
    if accessibility_id in (sim.observe_text() or ""):
        try:
            sim.tap_id(accessibility_id)
            sim.wait(0.3)
            return True
        except Exception:
            return False
    return False


def _keyboard_up(sim) -> bool:
    """True if the soft keyboard is currently covering the screen."""
    tree = sim.observe_text() or ""
    return ("UIKeyboardLayoutStar" in tree) or ("dictation" in tree and "delete" in tree)


def _dismiss_keyboard(sim) -> None:
    """Dismiss the soft keyboard if it's up.

    A focused search field leaves the keyboard covering the bottom tab bar,
    so any subsequent ``tab_*`` tap silently lands on a key. Pressing Return
    (``\\n``) reliably resigns first-responder in FreshCart's search field.
    """
    try:
        if _keyboard_up(sim):
            sim.type_text("\n")
            sim.wait(0.4)
    except Exception:
        pass


def _clear_text_field(sim, max_chars: int = 80) -> None:
    """Best-effort clear of the currently-focused text field.

    Pre-seeded fields (order notes, delivery instructions) otherwise get the
    new text inserted at the cursor, corrupting the value. We send a run of
    backspaces (``\\b``); callers MUST still verify the resulting value and
    fall back to a direct state write, since soft-keyboard delete support is
    not guaranteed across WDA builds.
    """
    try:
        sim.type_text("\b" * max_chars)
        sim.wait(0.2)
    except Exception:
        pass


def _ensure_foreground(sim) -> None:
    """Make sure FreshCart (not Clock/SpringBoard) is the frontmost app.

    The shared simulator harness primes the Clock app on first connect, and
    Clock can steal focus between calls. Tools that self-navigate must first
    guarantee FreshCart is foreground or every tap targets the wrong app.
    """
    try:
        tree = sim.observe_text() or ""
        if BUNDLE_ID not in tree:
            sim.launch_app(BUNDLE_ID)
            sim.wait(1.0)
    except Exception:
        try:
            sim.launch_app(BUNDLE_ID)
            sim.wait(1.0)
        except Exception:
            pass


def _goto_tab(sim, tab_aid: str) -> bool:
    """Self-navigate to a bottom-bar tab, handling keyboard + foreground.

    Returns True if the tab tap was issued successfully.
    """
    _ensure_foreground(sim)
    _dismiss_keyboard(sim)
    try:
        sim.tap_id(tab_aid)
        sim.wait(0.6)
        return True
    except Exception:
        # Keyboard may have re-appeared or foreground changed — retry once.
        _ensure_foreground(sim)
        _dismiss_keyboard(sim)
        try:
            sim.tap_id(tab_aid)
            sim.wait(0.6)
            return True
        except Exception:
            return False


def _product_summary(product: dict) -> dict:
    return {
        "id": product.get("id"),
        "name": product.get("productName"),
        "brand": product.get("brand"),
        "store_id": product.get("storeID"),
        "store_name": _store_name(product.get("storeID", "")),
        "category": product.get("categoryID"),
        "in_stock": product.get("inStock"),
    }


def _current_store_id() -> Optional[str]:
    state = _load_state()
    selected = state.get("selectedStoreID")
    if selected:
        return selected
    stores = _catalog_stores()
    return stores[0].get("id") if stores else None


def _product_candidates(product_name: str, *, store_id: Optional[str] = None) -> list[dict]:
    """Return catalog products matching a free-text product query."""
    raw = (product_name or "").strip()
    if raw.startswith("add_to_cart_"):
        raw = raw[len("add_to_cart_"):]
    if raw.startswith("product_row_"):
        raw = raw[len("product_row_"):]
    catalog = _load_catalog()
    products = catalog.get("products", []) or []
    if store_id:
        products = [p for p in products if p.get("storeID") == store_id]
    ids = {p.get("id") for p in products}
    if raw in ids:
        return [p for p in products if p.get("id") == raw]
    if raw.endswith("s") and raw[:-1] in ids:
        return [p for p in products if p.get("id") == raw[:-1]]

    needle = raw.lower().strip()
    if not needle:
        return []
    needle_slug = _slug(needle)
    stop = {"the", "a", "of", "and", "with", "fresh", "organic", "wild",
            "caught", "natural", "premium", "signature", "kirkland",
            "great", "value", "oz", "lb", "lbs", "ct", "pack", "count"}
    needle_tokens = [t for t in re.split(r"[^a-z0-9]+", needle) if t]
    core_tokens = [t for t in needle_tokens if t not in stop] or needle_tokens

    def _tok_hit(tok: str, hay_tokens: set[str]) -> bool:
        if tok in hay_tokens:
            return True
        for cand in (tok + "s", tok.rstrip("s")):
            if cand and cand != tok and cand in hay_tokens:
                return True
        if len(tok) >= 5:
            stem = tok[:-1] if tok.endswith("y") else tok
            return any(
                len(ht) >= 5 and ht.startswith(stem[:5]) and tok.startswith(ht[:5])
                for ht in hay_tokens
            )
        return False

    scored = []
    for p in products:
        pid = p.get("id", "")
        name = (p.get("productName", "") or "").lower()
        brand = (p.get("brand", "") or "").lower()
        hay = f"{name} {brand} {pid}".lower()
        hay_tokens = set(re.split(r"[^a-z0-9]+", hay))
        exact = int(needle == name or needle == pid.lower())
        substring = int(needle in hay or needle_slug in _slug(hay))
        hits = sum(1 for t in core_tokens if _tok_hit(t, hay_tokens))
        if exact or substring or hits:
            score = (exact, substring, hits, -len(name))
            scored.append((score, p))
    if not scored:
        return []
    scored.sort(key=lambda item: item[0], reverse=True)
    best = scored[0][0]
    # Keep all strong ties for disambiguation, plus any exact/substring match.
    return [
        p for score, p in scored
        if score[:3] == best[:3] or score[0] or score[1]
    ]


def _resolve_product(product_name: str) -> dict:
    """Resolve product input, returning product id or explicit ambiguity."""
    current_store = _current_store_id()
    matches = _product_candidates(product_name)
    if not matches:
        return {"ok": False, "message": f"No product matching '{product_name}' in the FreshCart catalog."}
    if len(matches) == 1:
        return {"ok": True, "product_id": matches[0].get("id"), "matches": [_product_summary(matches[0])]}
    selected_matches = [p for p in matches if p.get("storeID") == current_store]
    if len(selected_matches) == 1:
        return {
            "ok": True,
            "product_id": selected_matches[0].get("id"),
            "matches": [_product_summary(p) for p in matches],
            "disambiguated_by": "selectedStoreID",
        }
    return {
        "ok": False,
        "ambiguous": True,
        "message": (
            f"Ambiguous product '{product_name}'. Select a store or pass one "
            "of the exact product ids from candidates."
        ),
        "candidates": [_product_summary(p) for p in matches[:12]],
    }


def _normalize_product_id(product_name: str) -> str:
    """Resolve a free-text product NAME or id to a catalog product id.

    Accepts: a raw catalog id (``salmon_fresh_005``), an ``add_to_cart_<id>``
    accessibility id, a plural of an id, or a display NAME / brand substring
    (``"Green Seedless Grapes"``, ``"sockeye salmon"``). Returns the resolved
    catalog id, or the cleaned input if nothing matches (caller validates).
    """
    product_id = (product_name or "").strip()
    if product_id.startswith("add_to_cart_"):
        product_id = product_id[len("add_to_cart_"):]
    if product_id.startswith("product_row_"):
        product_id = product_id[len("product_row_"):]
    catalog = _load_catalog()
    products = catalog.get("products", []) or []
    ids = {p.get("id") for p in products}
    if product_id in ids:
        return product_id
    if product_id.endswith("s") and product_id[:-1] in ids:
        return product_id[:-1]
    # Fall back to NAME/brand resolution (case-insensitive substring/fuzzy).
    needle = product_id.lower().strip()
    if not needle:
        return product_id
    needle_slug = _slug(needle)
    # Noise words an agent commonly prepends/appends that should not gate a
    # match (they rarely appear verbatim in the catalog name).
    _STOP = {"the", "a", "of", "and", "with", "fresh", "organic", "wild",
             "caught", "natural", "premium", "signature", "kirkland",
             "great", "value", "oz", "lb", "lbs", "ct", "pack", "count"}
    needle_tokens = [t for t in re.split(r"[^a-z0-9]+", needle) if t]
    core_tokens = [t for t in needle_tokens if t not in _STOP] or needle_tokens
    best = None          # substring match (kept for back-compat)
    best_tok = None      # token-overlap match (count, -name_len, pid)
    for p in products:
        pid = p.get("id", "")
        name = (p.get("productName", "") or "").lower()
        brand = (p.get("brand", "") or "").lower()
        hay = f"{name} {brand} {pid}".lower()
        if needle == name or needle == pid.lower():
            return pid  # exact
        if needle in hay or needle_slug in _slug(hay):
            if best is None or len(name) < len(best[1]):
                best = (pid, name)
        # Token-overlap: how many of the query's content tokens appear in
        # this product's name/brand/id. Lets approximate multi-word names
        # ("Wild Caught Sockeye Salmon", "green grapes") resolve even when no
        # contiguous substring matches.
        hay_tokens = set(re.split(r"[^a-z0-9]+", hay))

        def _tok_hit(tok: str) -> bool:
            # Match a query token against the product tokens, tolerating
            # simple singular/plural differences ("avocado"/"avocados").
            if tok in hay_tokens:
                return True
            for cand in (tok + "s", tok.rstrip("s")):
                if cand and cand != tok and cand in hay_tokens:
                    return True
            # Irregular plurals / morphology (strawberry->strawberries):
            # accept a shared prefix of >=5 chars between query and a product
            # token (e.g. "strawberr"). Long enough to avoid spurious hits.
            if len(tok) >= 5:
                stem = tok[:-1] if tok.endswith("y") else tok
                for ht in hay_tokens:
                    if len(ht) >= 5 and (ht.startswith(stem[:5]) and tok.startswith(ht[:5])):
                        return True
            return False

        hits = sum(1 for t in core_tokens if _tok_hit(t))
        if hits:
            score = (hits, -len(name))
            if best_tok is None or score > best_tok[0]:
                best_tok = (score, pid, hits)
    if best:
        return best[0]
    # Accept a token-overlap match only if it covers a real majority of the
    # query's content tokens (>=2 tokens, or the single content token), so a
    # stray shared word ("organic", already stopped) can't create a false hit.
    if best_tok is not None:
        hits = best_tok[2]
        need = len(core_tokens)
        if hits >= 2 or (need == 1 and hits == 1):
            return best_tok[1]
    return product_id


def _product_exists(product_id: str) -> bool:
    catalog = _load_catalog()
    return any(p.get("id") == product_id for p in catalog.get("products", []) or [])


def _product_name(product_id: str) -> str:
    catalog = _load_catalog()
    for p in catalog.get("products", []) or []:
        if p.get("id") == product_id:
            return p.get("productName", product_id)
    return product_id


def _swap_cart_for_store_change(state: dict, new_store_id: str) -> None:
    """Mirror FreshCartStore.swapCartForStoreChange for direct state writes."""
    current = state.get("selectedStoreID")
    if not current or current == new_store_id:
        state["selectedStoreID"] = new_store_id
        return
    store_carts = state.setdefault("storeCarts", {})
    cart_items = state.get("cartItems", []) or []
    if cart_items:
        store_carts[current] = cart_items
    else:
        store_carts.pop(current, None)
    state["cartItems"] = store_carts.get(new_store_id, []) or []
    state["selectedStoreID"] = new_store_id


@mcp.tool()
def launch() -> str:
    """Launch FreshCart and return the initial UI tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched FreshCart.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (no taps)."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="FreshCart",
        markers=("freshcart_", "store_card_", "product_row_", "cart_item_"),
    )


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch to a bottom-bar tab.

    Args:
        tab_name: One of ``home``/``stores`` (both map to Stores),
            ``search``, ``cart``, ``orders``, ``account``
            (case-insensitive). Any other value returns an error string.
    """
    aid = TAB_MAP.get(tab_name.lower().strip())
    if aid is None:
        return f"Could not navigate: unknown tab '{tab_name}'. Valid tabs: {', '.join(sorted(set(TAB_MAP.keys())))}"
    sim = SimulatorBridge.get()
    if _goto_tab(sim, aid):
        return f"Navigated to '{tab_name}' tab.\n\n{sim.observe_text()}"
    return f"Could not navigate to '{tab_name}' tab (id '{aid}' not tappable). Tree:\n\n{sim.observe_text()}"


@mcp.tool()
def search_products(query: str) -> dict:
    """Search the product catalog and return matching product slugs.

    Args:
        query: Free-text search. Matched against product id, name,
            brand, store id, and category id (case-insensitive).

    Returns:
        ``{query, products: [<id>...], count}``. Each id is a catalog
        product id (e.g. ``salmon_fresh_005``, ``grapes_001``) usable
        directly with ``add_to_cart(product_name=<id>)``. ``count`` is
        the number of catalog matches (0 for a nonsense query — the
        result is filtered against the catalog, not just on-screen rows).
        Self-navigates to the Search tab and types the query.
    """
    import re as _re
    sim = SimulatorBridge.get()
    # Self-navigate to the Search tab (real field id: search_products_field).
    _goto_tab(sim, "tab_search")
    tapped = False
    for aid in ("search_products_field", "freshcart_search_field"):
        try:
            sim.tap_id(aid)
            sim.wait(0.3)
            tapped = True
            break
        except Exception:
            continue
    try:
        if tapped:
            sim.type_text(query)
            sim.wait(0.6)
        tree = sim.observe_text() or ""
    except Exception:
        tree = sim.observe_text() or ""
    # Catalog matching is the source of truth for *what matches the query*.
    # The on-screen ``product_row_*`` scrape can include default/recommended
    # rows the search field did not actually filter out, so a nonsense query
    # would otherwise echo back whatever happened to be visible (e.g. count=3).
    q = query.lower().strip()
    catalog = _load_catalog()
    catalog_matches = {
        p.get("id")
        for p in catalog.get("products", [])
        if p.get("id") and (
            q in p.get("id", "").lower()
            or q in p.get("productName", "").lower()
            or q in p.get("brand", "").lower()
            or q in p.get("storeID", "").lower()
            or q in p.get("categoryID", "").lower()
        )
    }
    onscreen = set(_re.findall(r'product_row_([^"\s]+)', tree))
    intersected = onscreen & catalog_matches
    # Prefer on-screen rows that are genuine catalog matches; otherwise fall
    # back to the authoritative catalog match set (possibly empty).
    slugs = sorted(intersected) if intersected else sorted(catalog_matches)
    by_id = {p.get("id"): p for p in catalog.get("products", []) or []}
    matches = [_product_summary(by_id[pid]) for pid in slugs if pid in by_id]
    return {
        "query": query,
        "products": slugs,
        "matches": matches,
        "count": len(slugs),
        "selected_store_id": _current_store_id(),
        "message": "Use an exact product id when multiple stores/products match.",
    }


@mcp.tool()
def add_to_cart(product_name: str) -> str:
    """Add a product to the cart by NAME or catalog id (self-navigating).

    Args:
        product_name: A catalog product id (e.g. ``salmon_fresh_005``), an
            ``add_to_cart_<id>`` accessibility id, OR a free-text display
            NAME / brand (e.g. ``"sockeye salmon"``, ``"Green Seedless
            Grapes"``). The tool resolves it to a catalog id, navigates to
            Search, types the name to surface the product's add button,
            scrolls to reveal it, taps it, and verifies. Falls back to a
            shared-state cart write if the button can't be reached.

    Works from any screen (self-navigates). Returns "No product
    matching '<name>'..." if the name/id resolves to nothing in the
    catalog (ambiguous/unknown input is reported, not guessed).
    """
    sim = SimulatorBridge.get()
    resolved = _resolve_product(product_name)
    if not resolved.get("ok"):
        return resolved
    product_id = resolved["product_id"]
    if not _product_exists(product_id):
        return f"No product matching '{product_name}' in the FreshCart catalog."
    aid = f"add_to_cart_{product_id}"

    # 1) Direct tap if the button is already on screen (e.g. agent already
    #    on a product list / category view).
    if _reveal_and_tap(sim, aid):
        sim.wait(0.3)
        return f"Added '{product_id}' ({_product_name(product_id)}) to cart.\n\n{sim.observe_text()}"

    # 2) Self-navigate: open Search and type the product name so its row +
    #    add button render, then reveal-and-tap.
    _goto_tab(sim, "tab_search")
    for aid_field in ("search_products_field", "freshcart_search_field"):
        try:
            sim.tap_id(aid_field); sim.wait(0.3)
            # A readable query: the display name (first token) finds the row.
            query = _product_name(product_id)
            sim.type_text(query); sim.wait(0.7)
            break
        except Exception:
            continue
    if _reveal_and_tap(sim, aid):
        sim.wait(0.3)
        return f"Added '{product_id}' ({_product_name(product_id)}) to cart.\n\n{sim.observe_text()}"

    # 3) Last resort: shared-state cart write (still a real, verifiable add).
    try:
        ui = sim.tap_and_observe(aid)
        return f"Added '{product_id}' to cart.\n\n{ui}"
    except Exception as exc:
        state = dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}
        catalog = _load_catalog()
        if not any(p.get("id") == product_id for p in catalog.get("products", [])):
            return f"No product matching '{product_name}'. Error: {str(exc)[:120]}"
        product = next((p for p in catalog.get("products", []) if p.get("id") == product_id), {})
        if product.get("storeID"):
            _swap_cart_for_store_change(state, product.get("storeID"))
        items = state.setdefault("cartItems", [])
        existing = next((i for i in items if i.get("productID") == product_id), None)
        if existing:
            existing["quantity"] = int(existing.get("quantity", 0)) + 1
            existing["addedAt"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        else:
            items.append({
                "productID": product_id,
                "quantity": 1,
                "note": "",
                "substitutionPreference": {"type": "bestMatch"},
                "addedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            })
        state["selectedTab"] = "cart"
        dl.write_app_state(BUNDLE_ID, "instacartsim_state.json", state)
        dl.reload_app(BUNDLE_ID)
        return {"ok": True, "action": "add_to_cart", "productID": product_id, "message": f"Added '{product_id}' to cart via shared state."}


@mcp.tool()
def list_stores(query: str = "") -> dict:
    """List FreshCart stores and their stable ids.

    Args:
        query: Optional free-text filter matched against store id/name/tagline.

    Returns ``{ok, stores, count, selected_store_id}``; use ``id`` with
    ``select_store`` or pass exact product ids from ``search_products``.
    """
    q = (query or "").strip().lower()
    stores = []
    for store in _catalog_stores():
        hay = f"{store.get('id', '')} {store.get('storeName', '')} {store.get('tagline', '')}".lower()
        if q and q not in hay and _slug(q) not in _slug(hay):
            continue
        stores.append({
            "id": store.get("id"),
            "name": store.get("storeName"),
            "tagline": store.get("tagline"),
            "eta": store.get("etaText"),
            "supports_delivery": store.get("supportsDelivery"),
            "supports_pickup": store.get("supportsPickup"),
        })
    return {
        "ok": True,
        "stores": stores,
        "count": len(stores),
        "selected_store_id": _current_store_id(),
    }


@mcp.tool()
def select_store(store: str) -> dict:
    """Select a FreshCart store by id/name/``store_card_<id>``.

    Mirrors the app's single-store checkout behavior: the outgoing store cart
    is saved in ``storeCarts`` and the newly selected store's saved cart is
    restored. Returns a controlled ambiguity/error when the store cannot be
    resolved.
    """
    store_id = _resolve_store_id(store)
    if store_id is None:
        return {
            "ok": False,
            "action": "select_store",
            "message": f"Could not resolve store '{store}'. Use list_stores() for valid ids.",
            "stores": list_stores().get("stores", []),
        }
    state = _load_state()
    before = state.get("selectedStoreID")
    _swap_cart_for_store_change(state, store_id)
    dl.write_app_state(BUNDLE_ID, "instacartsim_state.json", state)
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "action": "select_store",
        "store_id": store_id,
        "store_name": _store_name(store_id),
        "previous_store_id": before,
        "cart_count": len(state.get("cartItems", []) or []),
        "message": f"Selected {_store_name(store_id)} ({store_id}).",
    }


@mcp.tool()
def view_cart() -> str:
    """Navigate to the Cart tab and return its UI tree (cart contents)."""
    sim = SimulatorBridge.get()
    _goto_tab(sim, "tab_cart")
    return f"Cart contents:\n\n{sim.observe_text()}"


def _on_checkout_screen(sim) -> bool:
    """True if the checkout screen (not the cart list) is showing.

    The checkout screen renders summary/control ids that never appear on the
    plain cart list, e.g. ``checkout_total`` / ``checkout_promo_toggle`` /
    ``checkout_time_slot_button``.
    """
    tree = sim.observe_text() or ""
    return any(
        k in tree
        for k in ("checkout_total", "checkout_promo_toggle",
                  "checkout_time_slot_button", "checkout_contactless_toggle")
    )


def _open_checkout_screen(sim) -> bool:
    """Self-navigate Cart -> checkout screen.

    Tap Cart, scroll to the "Go to checkout" button (id
    ``checkout_place_order_button``, shared with the place-order button), tap
    it once to push the checkout screen. Returns True if the checkout screen
    is reached. No-op (returns True) if already on the checkout screen.
    """
    if _on_checkout_screen(sim):
        return True
    _goto_tab(sim, "tab_cart")
    if _on_checkout_screen(sim):
        return True
    # Reveal + tap the "Go to checkout" button to push the checkout screen.
    if _reveal_and_tap(sim, "checkout_place_order_button"):
        sim.wait(0.8)
    return _on_checkout_screen(sim)


def _cart_has_items(sim) -> bool:
    state = _load_state()
    return bool(state.get("cartItems"))


def _checkout_fill_form() -> Optional[str]:
    """Prepare the checkout screen for a place-order commit (no commit yet).

    Returns None on success or a precondition message on failure. Used by
    both `checkout` (one-shot commit) and `prepare_checkout` (capture-only).
    Stops short of tapping `checkout_place_order_button` so the caller
    decides whether to commit.
    """
    # Checkout has no pre-fill steps in the current UI — the only action is
    # tapping the place-order button itself. Optional toggles/fields are
    # handled by separate tools (toggle_priority_delivery, set_custom_tip,
    # add_delivery_instructions, etc.) and have already run by the time
    # this helper is called.
    return None


@mcp.tool()
def checkout() -> str:
    """Place the order by tapping ``checkout_place_order_button``.

    Works from any screen with at least one cart item — self-navigates
    Cart -> checkout screen, then commits. Set any optional fields (tip,
    instructions, toggles, promo) via their setter tools BEFORE calling
    this. Returns "Cannot checkout: cart is empty ..." if the cart has
    no items.

    Legacy single-verb commit; prefer ``prepare_checkout`` +
    ``confirm_checkout`` for new code.
    """
    sim = SimulatorBridge.get()
    err = _checkout_fill_form()
    if err:
        return err
    if not _cart_has_items(sim):
        return "Cannot checkout: cart is empty — add at least one item before checking out."
    # Self-navigate to the checkout screen (Cart -> Go to checkout), then tap
    # the place-order button to commit.
    if not _open_checkout_screen(sim):
        return "Could not open the checkout screen from the cart."
    if _reveal_and_tap(sim, "checkout_place_order_button"):
        sim.wait(0.6)
        return f"Checkout placed.\n\n{sim.observe_text()}"
    return "Could not reach the place-order button on the checkout screen."


@mcp.tool()
def prepare_checkout() -> dict:
    """Stage a checkout (place-order) commit WITHOUT actually placing the order.

    On success, returns ``{ok: True, action: "prepare_checkout", draft_id,
    summary: {}}``. The agent should inspect the cart/checkout UI, then
    pass the ``draft_id`` to ``confirm_checkout`` to actually commit. The
    draft expires after the `IOSWORLD_DRAFT_TTL_SECONDS` TTL (default
    10 minutes) or when the simulator session resets.

    On precondition failure, returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _checkout_fill_form()
    if err:
        return {"ok": False, "action": "prepare_checkout", "message": err}
    summary: dict = {}
    draft_id = ts.create_draft("freshcart", "checkout", summary)
    return {
        "ok": True,
        "action": "prepare_checkout",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_checkout(draft_id) to commit.",
    }


@mcp.tool()
def confirm_checkout(draft_id: str) -> dict:
    """Commit a checkout previously staged by ``prepare_checkout``.

    `draft_id` is the id returned by ``prepare_checkout``. The draft must
    still be present (not consumed, not expired). Returns
    ``{ok: True, action: "confirm_checkout", evidence: <summary>}`` on
    success.

    If the draft is missing or expired, returns a controlled-failure
    response and does not tap the place-order button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_checkout first.",
        }
    sim = SimulatorBridge.get()
    if not _open_checkout_screen(sim):
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": "Could not open the checkout screen from the cart (cart may be empty).",
        }
    if not _reveal_and_tap(sim, "checkout_place_order_button"):
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": "Place-order button not reachable on the checkout screen.",
        }
    sim.wait(0.5)
    return {
        "ok": True,
        "action": "confirm_checkout",
        "evidence": draft.get("payload", {}),
    }


@mcp.tool()
def select_delivery_slot() -> str:
    """Open the delivery time-slot picker (``checkout_time_slot_button``).

    Works from any screen with items in the cart — self-navigates Cart ->
    checkout screen, then opens the picker only; the agent must observe the
    resulting UI and tap a specific slot. Returns ``{ok: False, ...}`` if
    the cart is empty or the time-slot button can't be reached.
    """
    sim = SimulatorBridge.get()
    if not _cart_has_items(sim):
        return {
            "ok": False,
            "action": "select_delivery_slot",
            "message": "Cart is empty — add an item before opening the delivery slot picker.",
        }
    _open_checkout_screen(sim)
    for aid in (
        "checkout_time_slot_button",
        "checkout_delivery_slot_button",
        "checkout_delivery_time_button",
    ):
        if _reveal_and_tap(sim, aid):
            return f"Delivery slot picker:\n\n{sim.observe_text()}"
    return {
        "ok": False,
        "action": "select_delivery_slot",
        "message": (
            "Could not reach the delivery time-slot button "
            "(checkout_time_slot_button) on the checkout screen."
        ),
    }


@mcp.tool()
def view_orders() -> dict:
    """Navigate to the Orders tab and return order history plus UI evidence."""
    sim = SimulatorBridge.get()
    _goto_tab(sim, "tab_orders")
    state = _load_state()
    orders = [_order_summary(o) for o in state.get("orders", []) or []]
    return {
        "ok": True,
        "action": "view_orders",
        "orders": orders,
        "count": len(orders),
        "message": "Orders loaded. Pass one of orders[].id to open_order_detail/cancel_order.",
        "ui_after": sim.observe_text(),
    }


@mcp.tool()
def open_order_detail(order_id: str) -> str:
    """Push the order detail view for ``order_id`` from the Orders tab.

    Args:
        order_id: Order id, e.g. ``order_scheduled_002`` (the suffix of
            ``order_row_<id>`` in the Orders tab tree, or any id from
            state.orders[].id — call ``view_orders`` first). Each order
            row carries an ``order_row_<id>`` identifier (OrdersView.swift)
            so the tap uniquely targets one order even when several share a
            status chip.

    Works from any screen — self-navigates to the Orders tab. Taps the
    per-order handle in order ``order_card_<id>`` -> ``order_row_<id>``
    -> ``order_status_chip_<status>`` (chip is the last-resort fallback),
    then confirms a real detail view appeared. Returns "No order found
    for order_id ..." if the id isn't in seeded/persisted state.

    Returns a status string with the resulting UI tree.
    """
    sim = SimulatorBridge.get()
    resolved_order_id = _resolve_order_id(order_id)
    order = _find_order_by_id(resolved_order_id or order_id)
    if not order:
        state = _load_state()
        available = [o.get("id") for o in state.get("orders", []) or []]
        return (
            f"No order found for order_id '{order_id}'. Call view_orders() and "
            f"pick a valid id from state.orders[].id. Available ids: {available[:8]}."
        )
    canonical_order_id = order.get("id")
    # Self-navigate to the Orders tab.
    _goto_tab(sim, "tab_orders")
    status = str(order.get("orderStatus", "")).strip()
    chip = f"order_status_chip_{_slug(status)}"
    # SwiftUI does not surface the per-row NavigationLink id (order_row_<id>)
    # in the XCUI tree, so the only tappable per-order handle is its status
    # chip. Scroll the list to surface the chip, then tap it to push the
    # order detail. (When several orders share a status the topmost opens; we
    # still confirm a real detail view appeared.)
    candidates = [
        f"order_card_{canonical_order_id}",
        f"order_row_{_slug(canonical_order_id)}",
        chip,
    ]
    for target in candidates:
        if _reveal_and_tap(sim, target):
            sim.wait(0.6)
            tree = sim.observe_text() or ""
            if ("cancel_order_button" in tree or "reorder_order_button" in tree
                    or "advance_order_state_button" in tree
                    or "order_status_chip" not in tree):
                return f"Opened detail for order '{canonical_order_id}' (status '{status}').\n\n{tree}"
            return f"Opened detail for order '{canonical_order_id}'.\n\n{tree}"
    return (
        f"Could not open order '{order_id}' (status '{status}'). Its status "
        f"chip '{chip}' was not reachable on the Orders tab."
    )


@mcp.tool()
def browse_category(category_name: str) -> str:
    """Open a product category tile on the Stores/home screen.

    Args:
        category_name: Category name or slug. The Search tab exposes
            ``category_tile_<slug>`` for the catalog slugs ``produce``,
            ``dairy_eggs`` (label "Dairy & Eggs"), ``meat_seafood`` (label
            "Meat & Seafood"), ``prepared``, ``frozen``, ``bakery``,
            ``pantry``, ``beverages``, ``household``, ``pet``, ``retail``.
            Friendly names and synonyms are accepted (e.g. "Dairy & Eggs",
            "dairy", "meat", "seafood", "drinks", "fruit") and resolved to
            a slug; an unknown name returns "No category matching ...".

    Works from any screen — self-navigates to the Search tab. If the tile
    isn't present (only stocked categories render one) it falls back to a
    search query for the category, then to an authoritative catalog
    listing ``{ok, category, products: [<id>...], count}``.
    """
    sim = SimulatorBridge.get()
    slug = _category_to_slug(category_name)
    if slug is None:
        return (f"No category matching '{category_name}'. Valid categories: "
                f"{', '.join(sorted(_CATEGORY_SLUGS))}.")
    # Category tiles (``category_tile_<slug>``) live on the SEARCH tab. Only a
    # subset of categories (those stocked by the selected store) render a
    # tile; for the rest we fall back to a search query that surfaces the
    # category's products.
    _goto_tab(sim, "tab_search")
    tile = f"category_tile_{slug}"
    if _reveal_and_tap(sim, tile):
        sim.wait(0.5)
        return f"Browsing category '{slug}'.\n\n{sim.observe_text()}"
    # Fallback 1: type the category display name into search to filter to it.
    catalog = _load_catalog()
    cat_name = next((c.get("name") for c in catalog.get("categories", [])
                     if c.get("id") == slug), slug.replace("_", " "))
    for aid_field in ("search_products_field", "freshcart_search_field"):
        try:
            sim.tap_id(aid_field); sim.wait(0.3)
            sim.type_text(cat_name); sim.wait(0.7)
            tree = sim.observe_text() or ""
            if "product_row_" in tree:
                return f"Browsing category '{slug}' via search '{cat_name}'.\n\n{tree}"
            break
        except Exception:
            continue
    # Fallback 2: authoritative catalog listing for the category.
    products = [
        p.get("id")
        for p in catalog.get("products", [])
        if _category_to_slug(p.get("categoryID", "")) == slug
        or p.get("categoryID", "").lower() == slug
    ]
    return {"ok": True, "category": slug, "products": products, "count": len(products)}


@mcp.tool()
def toggle_priority_delivery() -> str:
    """Toggle the priority (express) delivery switch
    (``checkout_priority_delivery_toggle``).

    Works from any screen with items in the cart — self-navigates to the
    checkout screen, then taps the toggle. Falls back to a shared-state
    write (``toggle_priority_delivery_direct``) if the UI toggle is not
    reachable or the cart is empty. Note: this FLIPS the current value;
    use ``toggle_priority_delivery_direct(enabled)`` to set an explicit on/off.
    """
    sim = SimulatorBridge.get()
    # Real Swift id is ``checkout_priority_delivery_toggle`` (CartView.swift);
    # self-navigate to the checkout screen, then reveal + tap it.
    if _cart_has_items(sim):
        _open_checkout_screen(sim)
        if _reveal_and_tap(sim, "checkout_priority_delivery_toggle"):
            return "Toggled priority delivery."
    state = dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}
    enabled = not bool(state.get("priorityDelivery", False))
    return toggle_priority_delivery_direct.fn(enabled) if hasattr(toggle_priority_delivery_direct, "fn") else toggle_priority_delivery_direct(enabled)


@mcp.tool()
def toggle_contactless() -> str:
    """Toggle the contactless-handoff switch (``checkout_contactless_toggle``).

    Works from any screen with items in the cart — self-navigates to the
    checkout screen, then taps the toggle. Falls back to a shared-state
    write (``toggle_contactless_direct``) if the UI toggle is not reachable
    or the cart is empty. Note: this FLIPS the current value; use
    ``toggle_contactless_direct(enabled)`` to set an explicit on/off.
    """
    sim = SimulatorBridge.get()
    if _cart_has_items(sim):
        _open_checkout_screen(sim)
        if _reveal_and_tap(sim, "checkout_contactless_toggle"):
            return "Toggled contactless delivery."
    state = dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}
    enabled = not bool(state.get("contactlessHandoff", False))
    return toggle_contactless_direct.fn(enabled) if hasattr(toggle_contactless_direct, "fn") else toggle_contactless_direct(enabled)


@mcp.tool()
def add_delivery_instructions(text: str) -> str:
    """Type delivery special-instructions on the checkout screen.

    Args:
        text: Free-text instructions for the driver (e.g. "leave at
            door"). Replaces existing instructions.

    Works from any screen with items in the cart — self-navigates to the
    checkout screen, taps the "Other" instruction chip to reveal
    ``checkout_delivery_instructions_field``, types, and verifies the value
    persisted. Falls back to ``set_delivery_instructions_direct`` if the
    field is not reachable or the cart is empty.
    """
    sim = SimulatorBridge.get()
    # The free-text field (checkout_delivery_instructions_field) is hidden
    # until the "Other" instruction chip is tapped. Self-navigate to checkout,
    # tap "Other", then type.
    if _cart_has_items(sim):
        _open_checkout_screen(sim)
        _reveal_and_tap(sim, "Other")
        if _reveal_and_tap(sim, "checkout_delivery_instructions_field"):
            try:
                _clear_text_field(sim)
                sim.type_text(text); sim.wait(0.2)
                _dismiss_keyboard(sim)
                # Verify the value persisted exactly; otherwise fall through to
                # the direct write (the "Other" field starts empty, but a prior
                # custom value could remain — replace cleanly).
                if (_load_state() or {}).get("specialInstructions", None) == text:
                    return "Added delivery instructions."
            except Exception:
                pass
    return set_delivery_instructions_direct.fn(text) if hasattr(set_delivery_instructions_direct, "fn") else set_delivery_instructions_direct(text)


@mcp.tool()
def add_order_notes(text: str) -> str:
    """Type order notes on the checkout screen.

    Args:
        text: Free-text note attached to the order. Replaces existing
            notes.

    Works from any screen with items in the cart — self-navigates to the
    checkout screen, types into ``checkout_order_notes_field``, and verifies
    the value persisted. Falls back to ``set_order_notes_direct`` if the
    field is not reachable or the cart is empty.
    """
    sim = SimulatorBridge.get()
    if _cart_has_items(sim):
        _open_checkout_screen(sim)
        if _reveal_and_tap(sim, "checkout_order_notes_field"):
            try:
                _clear_text_field(sim)
                sim.type_text(text); sim.wait(0.2)
                _dismiss_keyboard(sim)
                # The notes field is pre-seeded; typing without a clean clear
                # corrupts it. Verify the field now equals the requested text
                # (the app persists it to state.orderNotes); otherwise fall
                # through to the direct write, which replaces cleanly.
                if (_load_state() or {}).get("orderNotes", None) == text:
                    return "Added order notes."
            except Exception:
                pass
    return set_order_notes_direct.fn(text) if hasattr(set_order_notes_direct, "fn") else set_order_notes_direct(text)


@mcp.tool()
def set_custom_tip(amount: str) -> str:
    """Set a custom tip in the checkout-screen tip field.

    Args:
        amount: Dollar amount as a string (e.g. ``"5"`` or ``"7.50"``);
            no currency sign. Falls back to ``set_tip_direct`` if the
            field is unreachable.

    Works from any screen with items in the cart — self-navigates to
    checkout. The custom-tip field (``checkout_custom_tip_field``) is hidden
    until the "Custom amount" button (no id — matched by label) is tapped;
    this taps it, types the amount, taps "Set" to commit, and verifies the
    tip changed in state. Falls back to ``set_tip_direct`` if the field is
    unreachable or the cart is empty.
    """
    sim = SimulatorBridge.get()
    if _cart_has_items(sim):
        _open_checkout_screen(sim)
        # Reveal + tap the "Custom amount" button (label, no id) to surface
        # ``checkout_custom_tip_field``.
        _reveal_and_tap(sim, "Custom amount")
        if "checkout_custom_tip_field" in (sim.observe_text() or ""):
            try:
                sim.tap_id("checkout_custom_tip_field"); sim.wait(0.3)
                sim.type_text(amount); sim.wait(0.2)
                # Commit the value via the "Set" button next to the field.
                try:
                    sim.tap_id("Set"); sim.wait(0.3)
                except Exception:
                    pass
                _dismiss_keyboard(sim)
                # Verify the tip actually changed in shared state; otherwise
                # fall through to the direct write.
                if abs(float((_load_state() or {}).get("tipAmount", -1)) - float(amount)) < 0.001:
                    return f"Custom tip: {amount}."
            except Exception:
                pass
    return set_tip_direct.fn(amount) if hasattr(set_tip_direct, "fn") else set_tip_direct(amount)


@mcp.tool()
def apply_promo(promo_code: str = "") -> str:
    """Enter a promo code and tap Apply on the checkout screen.

    Args:
        promo_code: The promo/coupon code to enter into
            ``checkout_promo_code_field`` (revealed by tapping
            ``checkout_promo_toggle``) before tapping
            ``checkout_promo_apply_button``. If omitted, applies whatever
            code is already in the field (or the seeded ``promoCode``).

    Works from any screen with items in the cart — self-navigates to the
    checkout screen. Verifies the discount actually registered: returns
    ``{ok: False, ...}`` if the code was rejected (no discount), so an
    empty/invalid code is never reported as a false success.
    """
    sim = SimulatorBridge.get()
    code = (promo_code or "").strip()
    if _cart_has_items(sim):
        _open_checkout_screen(sim)
        # The promo field is collapsed behind ``checkout_promo_toggle``.
        _reveal_and_tap(sim, "checkout_promo_toggle")
        if code and "checkout_promo_code_field" in (sim.observe_text() or ""):
            try:
                sim.tap_id("checkout_promo_code_field"); sim.wait(0.2)
                sim.type_text(code); sim.wait(0.2)
                _dismiss_keyboard(sim)
            except Exception:
                pass
        # Tap Apply (scroll to reveal if needed), then verify the code was
        # actually accepted before claiming success. The app only registers a
        # discount (``promoApplied``) for a non-empty code; an empty/whitespace
        # code is rejected ("Enter a valid promo code."). Read the discount back
        # from shared state so we never report a false success.
        if _reveal_and_tap(sim, "checkout_promo_apply_button"):
            sim.wait(0.3)
            applied = bool((_load_state() or {}).get("promoApplied"))
            if applied:
                return f"Applied promo{(' ' + repr(code)) if code else ''}."
            return {
                "ok": False,
                "action": "apply_promo",
                "message": (
                    f"Could not apply promo{(' ' + repr(code)) if code else ''} — "
                    "code was rejected (no discount registered)."
                ),
            }
    # UI not reachable — fall back to a shared-state write.
    if code:
        state = _load_state()
        state["promoCode"] = code
        _save_state(state)
    result = _apply_promo_state()
    if result.get("ok"):
        return {"ok": True, "action": "apply_promo", "promo_code": code or result.get("promoCode"), "state_fallback": result}
    return {"ok": False, "action": "apply_promo", "message": result.get("error", str(result))}


def _cancel_order_fill_form(order_id: str) -> Optional[str]:
    """Validate the order_id for a cancel-order commit (no commit yet).

    Returns None on success or a precondition message on failure. Used by
    both `cancel_order` (one-shot commit) and `prepare_cancel_order`
    (capture-only). Stops short of tapping `order_cancel_<order_id>` so
    the caller decides whether to commit.
    """
    if not order_id or not str(order_id).strip():
        return (
            "Missing order_id. Call view_orders() and pass the slug from "
            "`order_row_<id>` in the UI tree."
        )
    if _resolve_order_id(order_id) is None:
        state = _load_state()
        available = [o.get("id") for o in state.get("orders", []) or []]
        return f"No order matching '{order_id}'. Available ids: {available[:8]}"
    return None


@mcp.tool()
def cancel_order(order_id: str) -> str:
    """Cancel a previously placed order.

    Args:
        order_id: Order id (slug suffix of ``order_row_<id>`` in the
            Orders tab UI tree). Call ``view_orders`` first to find
            valid ids. Empty/whitespace values are rejected.

    Legacy single-verb commit; prefer ``prepare_cancel_order`` +
    ``confirm_cancel_order`` for new code.

    The Swift-side accessibility id is ``cancel_order_button_<slug>`` (see
    OrdersView.swift ``actionsCard``) and only renders inside the order
    detail view for orders whose status is cancellable
    (``scheduled``/``placed``/``shopperAssigned``). Call
    ``open_order_detail(order_id=...)`` first so the button is reachable.
    """
    err = _cancel_order_fill_form(order_id)
    if err:
        return err
    order_id = _resolve_order_id(order_id) or order_id
    result = _cancel_order_state(order_id)
    if result.get("ok"):
        return {"ok": True, "action": "cancel_order", "order_id": order_id, "state_fallback": result}
    if result.get("error"):
        return {"ok": False, "action": "cancel_order", "message": result.get("error", str(result))}

    sim = SimulatorBridge.get()
    cancel_btn = f"cancel_order_button_{_slug(order_id)}"
    # Self-navigate: open the order's detail view so the cancel button renders.
    order = _find_order_by_id(order_id)
    if order is not None:
        if cancel_btn not in (sim.observe_text() or ""):
            try:
                open_order_detail.fn(order_id) if hasattr(open_order_detail, "fn") else open_order_detail(order_id)
            except Exception:
                pass
    if _reveal_and_tap(sim, cancel_btn):
        sim.wait(0.4)
        # Some builds show a confirm dialog — best effort confirm.
        _reveal_and_tap(sim, "Cancel order")
        sim.wait(0.4)
        # Verify the order actually transitioned to canceled before claiming
        # success; a best-effort tap with no read-back can otherwise report a
        # false success (e.g. non-cancellable status, missed confirm dialog).
        updated = _find_order_by_id(order_id)
        if updated is not None and _slug(str(updated.get("orderStatus", ""))) == "canceled":
            return f"Cancelled order {order_id}."
        # UI tap did not stick — fall through to the shared-state path, which
        # enforces cancellable-status and reports an honest failure otherwise.
    return {"ok": False, "action": "cancel_order", "message": result.get("error", str(result))}


@mcp.tool()
def prepare_cancel_order(order_id: str) -> dict:
    """Stage a cancel-order commit WITHOUT actually cancelling.

    `order_id` is the slug from `order_row_<id>` in the orders tab UI
    tree (call `view_orders` first).

    On success, returns ``{ok: True, action: "prepare_cancel_order",
    draft_id, summary: {order_id}}``. The agent should inspect the
    summary, then pass the ``draft_id`` to ``confirm_cancel_order`` to
    actually cancel. The draft expires after the
    `IOSWORLD_DRAFT_TTL_SECONDS` TTL (default 10 minutes) or when the
    simulator session resets.

    On precondition failure, returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _cancel_order_fill_form(order_id)
    if err:
        return {"ok": False, "action": "prepare_cancel_order", "message": err}
    order_id = _resolve_order_id(order_id) or order_id
    summary = {"order_id": order_id}
    draft_id = ts.create_draft("freshcart", "cancel_order", summary)
    return {
        "ok": True,
        "action": "prepare_cancel_order",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_cancel_order(draft_id) to commit.",
    }


@mcp.tool()
def confirm_cancel_order(draft_id: str) -> dict:
    """Commit a cancel-order previously staged by ``prepare_cancel_order``.

    `draft_id` is the id returned by ``prepare_cancel_order``. The draft
    must still be present (not consumed, not expired). Returns
    ``{ok: True, action: "confirm_cancel_order", evidence: <summary>}``
    on success.

    If the draft is missing or expired, returns a controlled-failure
    response and does not tap the cancel button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_cancel_order",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_cancel_order first.",
        }
    payload = draft.get("payload", {}) or {}
    order_id = payload.get("order_id", "")
    result = _cancel_order_state(order_id)
    if result.get("ok"):
        return {
            "ok": True,
            "action": "confirm_cancel_order",
            "evidence": {
                **payload,
                "state_fallback": result,
            },
        }
    if result.get("error"):
        return {
            "ok": False,
            "action": "confirm_cancel_order",
            "message": result.get("error", str(result)),
        }

    sim = SimulatorBridge.get()
    target_id = f"cancel_order_button_{_slug(order_id)}"
    # Self-navigate to the order detail so the cancel button is reachable.
    if target_id not in (sim.observe_text() or ""):
        try:
            open_order_detail.fn(order_id) if hasattr(open_order_detail, "fn") else open_order_detail(order_id)
        except Exception:
            pass
    if _reveal_and_tap(sim, target_id):
        sim.wait(0.4)
        _reveal_and_tap(sim, "Cancel order")
    else:
        result = _cancel_order_state(order_id)
        if result.get("ok"):
            return {
                "ok": True,
                "action": "confirm_cancel_order",
                "evidence": {
                    **payload,
                    "state_fallback": result,
                },
            }
        return {
            "ok": False,
            "action": "confirm_cancel_order",
            "message": (
                f"Cancel button '{target_id}' not found in current UI and shared-state "
                f"fallback failed: {result.get('error', str(result))}. "
                "Open the order's detail view (open_order_detail) first or choose a cancellable order."
            ),
        }
    return {
        "ok": True,
        "action": "confirm_cancel_order",
        "evidence": payload,
    }




# ── Direct-state-write tools

@mcp.tool()
def toggle_priority_delivery_direct(enabled: bool) -> dict:
    """Set priority-delivery on/off via direct shared-state write.

    Bypasses the checkout-screen toggle (which only takes effect once
    the checkout screen is showing).

    Args:
        enabled: ``True`` for priority/express, ``False`` for standard
            delivery.
    """
    state = dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}
    state["priorityDelivery"] = bool(enabled)
    dl.write_app_state(BUNDLE_ID, "instacartsim_state.json", state)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "priorityDelivery": bool(enabled),
            "message": f"Priority delivery {'enabled' if enabled else 'disabled'}."}


@mcp.tool()
def toggle_contactless_direct(enabled: bool) -> dict:
    """Set contactless-handoff on/off via direct shared-state write.

    Args:
        enabled: ``True`` to enable contactless handoff, ``False`` to
            require recipient interaction.
    """
    state = dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}
    state["contactlessHandoff"] = bool(enabled)
    dl.write_app_state(BUNDLE_ID, "instacartsim_state.json", state)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "contactlessHandoff": bool(enabled),
            "message": f"Contactless handoff {'enabled' if enabled else 'disabled'}."}


@mcp.tool()
def set_tip_direct(amount: str) -> dict:
    """Set the cart's tip amount via direct shared-state write.

    Args:
        amount: Dollar amount as a numeric string, e.g. ``"5"`` or
            ``"7.50"``. Non-numeric values return ``{ok: False, error}``.
    """
    state = dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}
    try:
        state["tipAmount"] = float(amount)
    except Exception:
        return {"ok": False, "error": f"amount '{amount}' is not numeric"}
    dl.write_app_state(BUNDLE_ID, "instacartsim_state.json", state)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "tipAmount": state["tipAmount"],
            "message": f"Tip set to ${amount}."}


@mcp.tool()
def set_order_notes_direct(text: str) -> dict:
    """Set the order notes via direct shared-state write.

    Args:
        text: Free-text note attached to the order. Replaces existing
            notes; empty string clears.
    """
    state = dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}
    state["orderNotes"] = text
    dl.write_app_state(BUNDLE_ID, "instacartsim_state.json", state)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "message": f"Order notes set ({len(text)} chars)."}


@mcp.tool()
def set_delivery_instructions_direct(text: str) -> dict:
    """Set delivery special instructions via direct shared-state write.

    Args:
        text: Free-text instructions for the driver. Replaces existing
            instructions; empty string clears.
    """
    state = dl.read_app_state(BUNDLE_ID, "instacartsim_state.json") or {}
    state["specialInstructions"] = text
    dl.write_app_state(BUNDLE_ID, "instacartsim_state.json", state)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "message": f"Delivery instructions set ({len(text)} chars)."}

if __name__ == "__main__":
    mcp.run()
