"""SplitPay MCP — send/request payments, friends, feed, wallet.

Bundle: com.iosworld.benchmark.splitpay

IDs (see SplitPay/Views/):
  Tabs: splitpay_tab_home, splitpay_tab_cards, splitpay_tab_crypto,
        splitpay_tab_me  (custom buttons in RootTabView).
  Feed: splitpay_feed_row_<transaction_uuid>.
  Transaction detail: transaction_detail_title/amount/memo,
                      transaction_detail_<row>.
  Profile: profile_avatar_<user_id>, profile_name_<user_id>,
           profile_username_<user_id>, profile_friend_toggle_<user_id>,
           profile_recent_<transaction_uuid>.
  Pay/Request flow: pay_or_request_button, recipient_search_field,
           recipient_row_<name_slug>, amount_digit_<0-9>, amount_decimal,
           memo_field, send_button, pay_confirm_button (final commit),
           request_button.

Naming: <name_slug> is the recipient display name lowercased with
spaces replaced by underscores (e.g. 'Maya Patel' →
'recipient_row_maya_patel'). <transaction_uuid> and <user_id> are
read live from the UI tree.

Resolver convention: every tool that takes a person (recipient / from_person /
user_id) accepts ANY of these case-insensitively — internal id ('user_brian'),
exact display name ('Maya Patel'), @username ('Maya-Patel'), or a UNIQUE partial
/ first name ('maya'). You do NOT need to know the slug or internal id; the
human-readable name works. Get UUIDs from list_feed_transactions. If a partial
is AMBIGUOUS (e.g. 'Brooks' → Nina/Elena/Lila Brooks, 'Sofia' → Sofia Reyes/Kim)
the person tools return a controlled failure rather than guess — pass a fuller
name or the @username. Nav tools self-navigate (dismiss overlays / relaunch to
clean Home), so they work from any screen.
"""

import json
import sys, pathlib, re, uuid
from datetime import datetime, timezone
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("SplitPay")

BUNDLE_ID = "com.iosworld.benchmark.splitpay"

DEFAULT_FRIEND_IDS = ["user_brian", "user_trevor", "user_chenchen"]
YOU_ID = "user_you"

# Seed users (mirror of SplitPay/Models/SeedData.swift coreUsers()+suggestedUsers()).
# Used to resolve a blind recipient/user argument (id, display name, username, or a
# partial/first name) to the canonical (id, display_name) the UI keys off of. The
# recipient picker row id is recipient_row_<display_name lowercased, spaces->_>, and
# avatar/profile ids are profile_*_<id>; resolving here lets every tool accept any of
# those forms instead of only the exact display name.
_SEED_CORE = [
    ("user_you", "Jordan Avery", "Jordan-Avery"),
    ("user_venmo", "SplitPay", "splitpay"),
    ("user_brian", "Maya Patel", "Maya-Patel"),
    ("user_trevor", "Leo Chen", "Leo-Chen"),
    ("user_chenchen", "Camille Hart", "Camille-Hart"),
    ("user_abi", "Priya Raman", "Priya-Raman"),
    ("user_arnav", "Arnav Srikanth", "arnavs"),
    ("user_spencer", "Spencer Bowman", "spencerbowman"),
    ("user_theo", "Theo Nguyen", "Theo-Nguyen"),
    ("user_sharp", "Sharp Sports Consulting LLC", "sharp_sports"),
    ("user_jing", "Nina Brooks", "Nina-Brooks"),
    ("user_shuyan", "Kai Santos", "Kai-Santos"),
    ("user_doordash", "QuickBite", "doordash"),
    ("user_diego", "Diego Martinez", "Diego-Martinez"),
    ("user_sofia", "Sofia Reyes", "Sofia-Reyes"),
    ("user_elena", "Elena Brooks", "Elena-Brooks"),
    ("user_rohan", "Rohan Mehta", "Rohan-Mehta"),
]
_SEED_SUGGESTED_NAMES = [
    "Ava Torres", "Miles Chen", "Noah Patel", "Grace Lin", "Sam Rivera",
    "Ruby Flores", "Mason Ward", "Henry Cooper", "Sofia Kim", "Chloe Bennett",
    "Jack Sullivan", "Lila Brooks", "Jules Park", "Celeste Huang", "Ravi Krishnan",
    "Amara Osei", "Juno Adler", "Kira Nakamura", "Declan Walsh", "Callum Reed",
    "Felix Delgado", "Hazel Dunn", "Dante Morales", "Oscar Leung",
]


def _seed_users() -> list:
    """Return [(id, display_name, username), ...] for all seed users."""
    users = list(_SEED_CORE)
    for i, name in enumerate(_SEED_SUGGESTED_NAMES):
        users.append((f"user_suggested_{i}", name, name.lower().replace(" ", "_")))
    return users


def _slug(display_name: str) -> str:
    """recipient_row_<slug>: display name lowercased, spaces -> underscores."""
    return display_name.lower().replace(" ", "_")


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _page_bounds(page, page_size, default_size: int = 50, max_size: int = 200) -> tuple[int, int]:
    try:
        p = int(page)
    except Exception:
        p = 1
    try:
        size = int(page_size)
    except Exception:
        size = default_size
    return max(1, p), min(max(1, size), max_size)


def _paginate(items: list, page=1, page_size=50) -> tuple[list, dict]:
    p, size = _page_bounds(page, page_size)
    total = len(items)
    start = (p - 1) * size
    end = start + size
    return items[start:end], {
        "page": p,
        "page_size": size,
        "count": total,
        "returned_count": max(0, min(end, total) - min(start, total)),
        "has_more": end < total,
        "next_page": p + 1 if end < total else None,
    }


def _decode_defaults_json(defaults: dict, key: str, fallback):
    raw = defaults.get(key)
    if raw is None:
        return fallback
    try:
        if isinstance(raw, (bytes, bytearray)):
            raw = raw.decode("utf-8")
        return json.loads(raw)
    except Exception:
        return fallback


def _encode_defaults_json(value) -> bytes:
    return json.dumps(value, separators=(",", ":")).encode("utf-8")


def _read_splitpay_defaults() -> dict:
    return dl.read_user_defaults(BUNDLE_ID) or {}


def _write_splitpay_defaults(defaults: dict) -> None:
    dl.write_user_defaults(BUNDLE_ID, defaults)
    dl.reload_app(BUNDLE_ID)


def _user_display(user_id: str) -> str:
    for uid, display, _username in _seed_users():
        if uid == user_id:
            return display
    return user_id or ""


def _request_row(req: dict) -> dict:
    from_id = req.get("fromUserID")
    to_id = req.get("toUserID")
    direction = "incoming" if to_id == YOU_ID else "outgoing" if from_id == YOU_ID else "other"
    return {
        "id": req.get("id"),
        "from_user_id": from_id,
        "from_name": _user_display(from_id),
        "to_user_id": to_id,
        "to_name": _user_display(to_id),
        "direction": direction,
        "amount": req.get("amount"),
        "memo": req.get("memo"),
        "timestamp": req.get("timestamp"),
        "privacy": req.get("privacy"),
        "status": req.get("status"),
    }


def _request_totals(rows: list[dict]) -> dict:
    totals = {
        "incoming_pending_amount": 0.0,
        "outgoing_pending_amount": 0.0,
        "incoming_pending_count": 0,
        "outgoing_pending_count": 0,
    }
    for row in rows:
        if row.get("status") != "pending":
            continue
        try:
            amount = float(row.get("amount") or 0)
        except Exception:
            amount = 0.0
        if row.get("direction") == "incoming":
            totals["incoming_pending_count"] += 1
            totals["incoming_pending_amount"] += amount
        elif row.get("direction") == "outgoing":
            totals["outgoing_pending_count"] += 1
            totals["outgoing_pending_amount"] += amount
    totals["incoming_pending_amount"] = round(totals["incoming_pending_amount"], 2)
    totals["outgoing_pending_amount"] = round(totals["outgoing_pending_amount"], 2)
    return totals


def _read_balance(defaults: dict) -> float:
    value = _decode_defaults_json(defaults, "balance", 250)
    try:
        return round(float(value), 2)
    except Exception:
        return 250.0


def _resolve_user(query: str):
    """Resolve a blind user reference to (id, display_name, username) or None.

    Accepts, case-insensitively: the internal id ('user_trevor'), the exact
    display name ('Leo Chen'), the @username ('Leo-Chen' / 'leo-chen'), or a
    partial / first-name substring of either ('leo', 'maya', 'sharp'). Prefers
    exact id/name/username matches, then a UNIQUE substring/first-name match.

    If the substring / first-name match is ambiguous (>1 candidate with no
    unique exact winner) — e.g. 'Brooks' (Nina/Elena/Lila Brooks) or 'Sofia'
    (Sofia Reyes/Sofia Kim) — returns None (controlled failure) rather than
    silently guessing the first colliding seed user and paying the wrong person.
    """
    if not query:
        return None
    q = str(query).strip()
    ql = q.lower()
    users = _seed_users()
    # exact id
    for u in users:
        if u[0].lower() == ql:
            return u
    # exact display name or username (with/without leading @)
    qn = ql[1:] if ql.startswith("@") else ql
    for u in users:
        if u[1].lower() == qn or u[2].lower() == qn:
            return u
    # substring of display name / username / id
    subs = [u for u in users if qn in u[1].lower() or qn in u[2].lower() or qn in u[0].lower()]
    if len(subs) == 1:
        return subs[0]
    if subs:
        # Only auto-resolve when a display-name first-token match (e.g. 'leo'
        # -> 'Leo Chen') is itself UNIQUE; otherwise the substring/first-name
        # query is ambiguous and we must not guess — return None.
        first_token_hits = [
            u for u in subs
            if qn in u[1].lower().split()
            or (u[1].lower().split() and u[1].lower().split()[0] == qn)
        ]
        if len(first_token_hits) == 1:
            return first_token_hits[0]
        return None
    return None

_TAB_MAP = {
    "home": "splitpay_tab_home", "feed": "splitpay_tab_home",
    "cards": "splitpay_tab_cards", "wallet": "splitpay_tab_cards",
    "crypto": "splitpay_tab_crypto", "settings": "splitpay_tab_crypto",
    "me": "splitpay_tab_me", "profile": "splitpay_tab_me", "requests": "splitpay_tab_me",
}


@mcp.tool()
def launch() -> str:
    """Launch SplitPay and return the initial UI accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched SplitPay.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (XML) for SplitPay."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="SplitPay",
        markers=("splitpay_tab_home", "splitpay_feed_row_", "pay_or_request_button"),
    )


@mcp.tool()
def navigate_to_tab(tab: str) -> str:
    """Switch to a SplitPay bottom-tab. Works from any screen — self-navigates.

    Dismisses any covering overlay (Pay/Request fullScreenCover, a detail/profile
    sheet) before tapping, then VERIFIES the destination tab's content actually
    rendered (relaunches and retries once if not).

    Args:
      tab: one of 'home' / 'feed', 'cards' / 'wallet',
        'crypto' / 'settings', 'me' / 'profile' / 'requests'.
        Case-insensitive; aliases on each line map to the same tab.

    Returns "Switched to '<tab>'." on success. An unknown tab, or a tab whose
    content never rendered, returns a "Could not switch..." failure message.
    """
    aid = _TAB_MAP.get(tab.strip().lower())
    if aid is None:
        # "Could not" matches the failure-prefix heuristic so the wrapper marks
        # this ok:false instead of falsely reporting ok:true for a bad tab.
        return f"Could not switch tabs: unknown tab '{tab}'. Use: home, cards, crypto, me."
    sim = SimulatorBridge.get()
    # Bug-class (2): the Pay/Request fullScreenCover (and, more rarely, a stacked
    # sheet) sits ABOVE the tab bar — the tab button is in the tree but covered,
    # so a tap no-ops yet we'd falsely report "Switched". Dismiss any covering
    # overlay first so the tab bar is the top-most affordance, then tap.
    _dismiss_overlays(sim)
    last_exc = None
    try:
        sim.tap_id(aid); sim.wait(0.5)
    except Exception as exc:
        last_exc = exc
    # Bug-class (3)/(4): verify the destination tab actually rendered via a
    # content marker that THIS build emits — never report ok:true on a no-op.
    # Poll with a short settle so a slow render (esp. right after a relaunch
    # dismissed an overlay) isn't mistaken for a failed switch.
    if last_exc is not None or not _settle_on_tab(sim, aid):
        # One more attempt after a clean relaunch (covers a stuck fullScreenCover
        # that swallowed the first tap's animation).
        try:
            sim.launch_and_observe(BUNDLE_ID); sim.wait(0.3)
            sim.tap_id(aid); sim.wait(0.5)
            last_exc = None
        except Exception as exc:
            last_exc = exc
        if not _settle_on_tab(sim, aid):
            detail = f" Last error: {str(last_exc)[:120]}" if last_exc else ""
            return (
                f"Could not switch to '{tab}' tab: its content did not render "
                f"after tapping (an overlay may still be covering the tab bar). "
                f"Call observe() to inspect the current screen.{detail}"
            )
    return f"Switched to '{tab}'."


def _settle_on_tab(sim, aid: str, attempts: int = 6) -> bool:
    """Poll the live tree until _on_tab(tree, aid) holds (or attempts run out).
    A freshly-tapped tab — especially right after a relaunch that dismissed an
    overlay — can take a moment to render its content; a single observe can
    catch a transitional/empty tree and falsely read as 'not switched'."""
    for _ in range(attempts):
        if _on_tab(sim.observe_text() or "", aid):
            return True
        sim.wait(0.5)
    return _on_tab(sim.observe_text() or "", aid)


# Per-tab content markers that THIS build actually renders — used to VERIFY a
# tab switch landed (not just that the tab button exists). Home shows the feed
# filter chips; Crypto the holdings; Cards/Me a portfolio/balance card with an
# eye toggle (and Me additionally a 'plus'). pay_or_request_button is present on
# every tab so it can't disambiguate.
def _on_tab(tree: str, aid: str) -> bool:
    if _pay_flow_is_open(tree) or "transaction_detail_title" in tree:
        return False  # an overlay/fullScreenCover is still up — not on any tab
    has_crypto = "crypto_holding_" in tree
    has_filter = "feed_filter_all" in tree
    has_plus = 'name="plus"' in tree
    has_eye = 'name="eye"' in tree
    if aid == "splitpay_tab_home":
        return has_filter
    if aid == "splitpay_tab_crypto":
        # Crypto shows the holdings list and (unlike Me) no 'plus' add button.
        return has_crypto and not has_plus and not has_filter
    if aid == "splitpay_tab_me":
        # Me also renders a crypto-holdings summary, but uniquely carries 'plus'.
        return has_plus and not has_filter
    if aid == "splitpay_tab_cards":
        # Cards: wallet card with an 'eye' balance toggle + 'sparkles', and
        # NONE of the home-feed filter / crypto-holdings / me 'plus' markers.
        return has_eye and not has_filter and not has_crypto and not has_plus
    return True


@mcp.tool()
def list_feed_transactions() -> dict:
    """Scrape transaction UUIDs visible on the home/feed tab.

    Returns ``{"transactions": [uuid, ...], "count": n}``. Use the UUIDs
    with `open_transaction` / `transaction_id` arguments.
    """
    # Bug-class (1): feed rows only render on the Home tab, and a single live
    # page_source read can return a TRUNCATED tree (only a handful of rows) or
    # ZERO rows when called from a non-default tab / behind an overlay — making
    # a naive UI scrape report e.g. 4 transactions when 80+ exist. The
    # authoritative source is the persisted transactions in UserDefaults, which
    # is independent of whatever screen the agent left the app on. We read that
    # (excluding the system 'SplitPay' rows the public feed hides) and use the
    # live tree only as a fallback if state can't be read.
    state_ids = _feed_transaction_ids_from_state()
    if state_ids:
        uuids = sorted(state_ids)
        return {"transactions": uuids, "count": len(uuids)}
    # Fallback: scrape the live feed, self-navigating to a clean Home first.
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if (
        "splitpay_feed_row_" not in tree
        or _pay_flow_blocked_by_overlay(tree)
        or "feed_filter_all" not in tree
    ):
        try:
            tree = sim.launch_and_observe(BUNDLE_ID) or ""
            sim.wait(0.5)
        except Exception:
            tree = sim.observe_text() or ""
    best = set(re.findall(r'splitpay_feed_row_([0-9A-Fa-f\-]+)', tree))
    for _ in range(6):
        sim.wait(0.4)
        cur = set(re.findall(r'splitpay_feed_row_([0-9A-Fa-f\-]+)', sim.observe_text() or ""))
        if len(cur) > len(best):
            best = cur
    uuids = sorted(best)
    return {"transactions": uuids, "count": len(uuids)}


def _feed_transaction_ids_from_state() -> list:
    """Read the persisted SplitPay transaction UUIDs from UserDefaults — the
    authoritative feed contents, independent of the current screen. Excludes
    system ('SplitPay'/user_venmo) transactions, which the public feed hides,
    so the result matches what splitpay_feed_row_<uuid> renders on Home.
    Returns [] (caller falls back to a UI scrape) if state can't be read."""
    try:
        defaults = dl.read_user_defaults(BUNDLE_ID)
    except Exception:
        return []
    raw = defaults.get("transactions") if defaults else None
    if not raw:
        return []
    try:
        txs = json.loads(raw.decode("utf-8") if isinstance(raw, (bytes, bytearray)) else raw)
    except Exception:
        return []
    if not isinstance(txs, list):
        return []
    ids = []
    for t in txs:
        if not isinstance(t, dict):
            continue
        if t.get("fromUserID") == "user_venmo" or t.get("toUserID") == "user_venmo":
            continue  # system row — hidden from the public feed
        tid = t.get("id")
        if tid:
            ids.append(str(tid))
    return ids


def _find_transaction(transaction_id: str) -> Optional[dict]:
    raw = (transaction_id or "").strip()
    if not raw:
        return None
    defaults = _read_splitpay_defaults()
    txs = _decode_defaults_json(defaults, "transactions", [])
    if not isinstance(txs, list):
        return None
    exact = next((t for t in txs if isinstance(t, dict) and str(t.get("id")) == raw), None)
    if exact is not None:
        return exact
    norm = re.sub(r"[^A-Za-z0-9]+", "", raw).lower()
    if len(norm) < 8:
        return None
    matches = [
        t for t in txs
        if isinstance(t, dict)
        and re.sub(r"[^A-Za-z0-9]+", "", str(t.get("id") or "")).lower().startswith(norm)
    ]
    if len(matches) == 1:
        return matches[0]
    return None


def _transaction_summary(tx: dict) -> dict:
    from_id = tx.get("fromUserID")
    to_id = tx.get("toUserID")
    return {
        "id": tx.get("id"),
        "from_user_id": from_id,
        "from_name": _user_display(from_id),
        "to_user_id": to_id,
        "to_name": _user_display(to_id),
        "amount": tx.get("amount"),
        "memo": tx.get("memo"),
        "timestamp": tx.get("timestamp"),
        "privacy": tx.get("privacy"),
        "emoji": tx.get("emoji"),
    }


@mcp.tool()
def list_pending_requests(direction: str = "incoming", page: int = 1, page_size: int = 50) -> dict:
    """List SplitPay payment requests from persisted state.

    Args:
      direction: ``incoming`` (friends requesting money from you), ``outgoing``
        (requests you sent), or ``all``.
      page/page_size: bounded pagination to avoid huge tool payloads.

    Returns ``{requests, count, returned_count, page, page_size, has_more,
    next_page, balance, totals}``. Request ids can be passed to
    ``pay_request(request_id=...)``.
    """
    defaults = _read_splitpay_defaults()
    requests = _decode_defaults_json(defaults, "requests", None)
    if requests is None:
        try:
            SimulatorBridge.get().launch_and_observe(BUNDLE_ID)
        except Exception:
            pass
        defaults = _read_splitpay_defaults()
        requests = _decode_defaults_json(defaults, "requests", [])
    wanted = (direction or "incoming").strip().lower()
    rows = [_request_row(r) for r in requests if isinstance(r, dict)]
    if wanted in ("incoming", "inbound"):
        rows = [r for r in rows if r.get("direction") == "incoming" and r.get("status") == "pending"]
    elif wanted in ("outgoing", "sent"):
        rows = [r for r in rows if r.get("direction") == "outgoing" and r.get("status") == "pending"]
    elif wanted in ("all", "any", ""):
        rows = [r for r in rows if r.get("status") == "pending"]
    else:
        return {"ok": False, "message": "direction must be incoming, outgoing, or all"}
    rows.sort(key=lambda r: str(r.get("timestamp") or ""), reverse=True)
    page_rows, meta = _paginate(rows, page, page_size)
    return {
        **meta,
        "requests": page_rows,
        "balance": _read_balance(defaults),
        "totals": _request_totals([_request_row(r) for r in requests if isinstance(r, dict)]),
    }


@mcp.tool()
def list_requests(direction: str = "incoming", page: int = 1, page_size: int = 50) -> dict:
    """Backward-compatible alias for ``list_pending_requests``."""
    return list_pending_requests.fn(direction, page, page_size) if hasattr(list_pending_requests, "fn") else list_pending_requests(direction, page, page_size)


@mcp.tool()
def pay_request(request_id: str = "", requester: str = "", funding_source_id: str = "balance") -> dict:
    """Pay a pending incoming SplitPay request by id or requester.

    Args:
      request_id: UUID from ``list_pending_requests``. Preferred.
      requester: optional requester name/id/username when id is unknown. Must
        resolve to exactly one pending incoming request.
      funding_source_id: ``balance`` (default), ``debit``, or ``credit``.

    Writes the same persisted request/transaction/balance fields the app uses,
    then reloads SplitPay. Returns a structured failure instead of guessing on
    ambiguous requesters or insufficient balance.
    """
    defaults = _read_splitpay_defaults()
    requests = _decode_defaults_json(defaults, "requests", None)
    transactions = _decode_defaults_json(defaults, "transactions", None)
    if requests is None or transactions is None:
        try:
            SimulatorBridge.get().launch_and_observe(BUNDLE_ID)
        except Exception:
            pass
        defaults = _read_splitpay_defaults()
        requests = _decode_defaults_json(defaults, "requests", None)
        transactions = _decode_defaults_json(defaults, "transactions", None)
    if not isinstance(requests, list) or not isinstance(transactions, list):
        return {"ok": False, "action": "pay_request", "message": "SplitPay persisted requests/transactions are unavailable"}

    target_index = None
    rid = (request_id or "").strip().lower()
    if rid:
        for i, req in enumerate(requests):
            if str(req.get("id", "")).lower() == rid:
                target_index = i
                break
    else:
        resolved = _resolve_user(requester)
        if not resolved:
            return {
                "ok": False,
                "action": "pay_request",
                "message": "Pass request_id from list_pending_requests, or an unambiguous requester name.",
            }
        requester_id = resolved[0]
        hits = [
            i for i, req in enumerate(requests)
            if req.get("fromUserID") == requester_id
            and req.get("toUserID") == YOU_ID
            and req.get("status") == "pending"
        ]
        if len(hits) != 1:
            return {
                "ok": False,
                "action": "pay_request",
                "message": f"Requester '{requester}' matched {len(hits)} pending incoming requests; pass request_id.",
            }
        target_index = hits[0]

    if target_index is None:
        return {"ok": False, "action": "pay_request", "message": f"No request '{request_id or requester}' found."}
    req = requests[target_index]
    row = _request_row(req)
    if row.get("status") != "pending":
        return {"ok": False, "action": "pay_request", "message": f"Request {row.get('id')} is {row.get('status')}, not pending."}
    if row.get("direction") != "incoming":
        return {"ok": False, "action": "pay_request", "message": f"Request {row.get('id')} is not an incoming request to pay."}

    try:
        amount = round(float(req.get("amount") or 0), 2)
    except Exception:
        amount = 0.0
    if amount <= 0:
        return {"ok": False, "action": "pay_request", "message": f"Request {row.get('id')} has invalid amount."}

    funding = (funding_source_id or "balance").strip().lower()
    if funding not in {"balance", "debit", "credit"}:
        return {"ok": False, "action": "pay_request", "message": "funding_source_id must be balance, debit, or credit."}
    balance_before = _read_balance(defaults)
    if funding == "balance" and balance_before < amount:
        return {
            "ok": False,
            "action": "pay_request",
            "message": f"Insufficient SplitPay balance (${balance_before:.2f}) for ${amount:.2f}.",
            "request": row,
        }

    transaction = {
        "id": str(uuid.uuid4()).upper(),
        "fromUserID": YOU_ID,
        "toUserID": req.get("fromUserID"),
        "amount": amount,
        "memo": req.get("memo") or "",
        "timestamp": _now_iso(),
        "privacy": req.get("privacy") or "Friends",
        "fundingSourceID": funding,
    }
    transactions.insert(0, transaction)
    requests[target_index]["status"] = "paid"
    if funding == "balance":
        defaults["balance"] = _encode_defaults_json(round(balance_before - amount, 2))
    defaults["requests"] = _encode_defaults_json(requests)
    defaults["transactions"] = _encode_defaults_json(transactions)
    _write_splitpay_defaults(defaults)
    return {
        "ok": True,
        "action": "pay_request",
        "request_id": row.get("id"),
        "transaction_id": transaction["id"],
        "paid_to": row.get("from_name"),
        "amount": amount,
        "memo": req.get("memo") or "",
        "funding_source_id": funding,
        "balance_before": balance_before,
        "balance_after": round(balance_before - amount, 2) if funding == "balance" else balance_before,
    }


@mcp.tool()
def open_transaction(transaction_id: str) -> str:
    """Open a feed transaction's detail sheet (transaction_detail_title/amount/memo).

    Args:
      transaction_id: the transaction UUID returned by `list_feed_transactions`
        (the trailing slug of `splitpay_feed_row_<uuid>`).

    Works from any screen — self-navigates: relaunches to a clean Home feed if an
    overlay is up or the row isn't visible, scrolls the row into view (it may sit
    far below the fold), taps it, and VERIFIES the detail rendered. Returns
    "Opened transaction <id>." on success, or a "Could not open..." failure
    message if the detail never appeared (check the id is in the feed).
    """
    sim = SimulatorBridge.get()
    row_id = f"splitpay_feed_row_{transaction_id}"
    # Self-navigate: feed rows only exist on Home. The row string can appear in
    # the tree *behind* a covering sheet (a transaction detail or profile sheet),
    # so a naive tap would no-op. If an overlay is up — or the row isn't present,
    # or we're not on Home — relaunch to a clean Home feed first.
    tree = sim.observe_text() or ""
    needs_reset = (
        _pay_flow_blocked_by_overlay(tree)
        or "transaction_detail_title" in tree   # a detail sheet is already up
        or row_id not in tree
        or "splitpay_tab_home" not in tree
    )
    if needs_reset:
        if "splitpay_tab_home" in tree and not _pay_flow_blocked_by_overlay(tree) \
                and "transaction_detail_title" not in tree and row_id in tree:
            # On Home with the row already present and no overlay — just retap Home.
            try:
                sim.tap_id("splitpay_tab_home"); sim.wait(0.4)
            except Exception:
                pass
        else:
            try:
                sim.launch_and_observe(BUNDLE_ID); sim.wait(0.3)
            except Exception:
                pass
    # Feed rows can sit far below the fold (y >> screen height); a direct
    # tap-by-id on a deep row no-ops (Appium resolves a duplicate/off-screen
    # frame). For a row that's already in the viewport, an id tap works; for a
    # deep row we scroll it into view then tap its HEADER coordinate (re-reading
    # the live rect right before each tap so a scroll-settle shift can't stale
    # it). Either way we verify the detail actually rendered.
    tree = sim.observe_text() or ""
    if _row_is_tappable(tree, row_id):
        sim.tap_and_verify_changed(row_id, prefix_for_failure="")
    if "transaction_detail_title" not in (sim.observe_text() or ""):
        if not _open_row_by_scroll_tap(sim, row_id):
            tx = _find_transaction(transaction_id)
            if tx is not None:
                return {
                    "ok": True,
                    "action": "open_transaction",
                    "transaction_id": transaction_id,
                    "summary": _transaction_summary(tx),
                    "message": (
                        f"Resolved transaction '{transaction_id}' from SplitPay "
                        "state. The in-app feed row detail sheet was not reachable."
                    ),
                }
            return (
                f"Could not open transaction '{transaction_id}': the detail "
                f"screen (transaction_detail_title) did not appear after "
                f"scrolling the row into view and tapping it. Confirm the "
                f"transaction id is in the feed, then retry."
            )
    return f"Opened transaction {transaction_id}."


def _open_row_by_scroll_tap(sim, row_id: str, attempts: int = 5) -> bool:
    """Scroll *row_id* into the viewport and tap it until the detail opens.
    Returns True once transaction_detail_title is showing.

    The feed row is a `.buttonStyle(.plain)` Button with `.contentShape(Rectangle())`
    — once it's actually inside the on-screen viewport an accessibility-id tap
    resolves to its real (in-bounds) frame and reliably opens the detail sheet.
    A raw coordinate tap on the row's header/center, by contrast, NO-OPS here
    (SwiftUI routes the plain Button's hit-test through its own frame, and the
    duplicate off-screen row frame can steal a coordinate hit). And an id tap on a
    row whose origin is still far off-screen raises NoSuchElement (XCUITest can't
    resolve a deep off-viewport element). So: scroll the row into a comfortable
    MIDDLE band (away from the floating tab-bar edge), then prefer the id tap, and
    only fall back to a coordinate tap on its header band."""
    for _ in range(attempts):
        rect = _scroll_feed_row_into_view(sim, row_id)
        # An id tap is the most reliable way to open the row once it's actually
        # inside the viewport — try it first (swallow NoSuchElement for a row
        # that's still off-screen; the next scroll/attempt will reposition it).
        try:
            sim.tap_id(row_id); sim.wait(0.8)
        except Exception:
            pass
        if "transaction_detail_title" in (sim.observe_text() or ""):
            return True
        if rect is None:
            continue
        # Fallback: re-read the live rect (scroll momentum can shift it) and tap
        # its header band by coordinate.
        live = _row_rect_live(sim, row_id) or rect
        x, y, w, h = live
        try:
            sim.tap_xy(x + w // 2, y + 22); sim.wait(0.8)
        except Exception:
            pass
        if "transaction_detail_title" in (sim.observe_text() or ""):
            return True
    return "transaction_detail_title" in (sim.observe_text() or "")


def _row_rect(tree: str, row_id: str):
    """Parse (x, y, w, h) of *row_id* from the UI tree, or None."""
    m = re.search(
        rf'name="{re.escape(row_id)}"[^>]*\bx="(-?\d+)"\s+y="(-?\d+)"\s+width="(\d+)"\s+height="(\d+)"',
        tree,
    )
    if not m:
        return None
    return tuple(int(g) for g in m.groups())


def _row_rect_live(sim, row_id: str, tries: int = 4):
    """Read *row_id*'s rect from a FRESH observe, retrying a few times. A single
    live page_source read can come back truncated (only the visible page of rows),
    so one observe that misses the row doesn't mean it's absent — retry."""
    for _ in range(tries):
        rect = _row_rect(sim.observe_text() or "", row_id)
        if rect is not None:
            return rect
        sim.wait(0.3)
    return None


def _row_is_tappable(tree: str, row_id: str) -> bool:
    """True if *row_id*'s CENTER sits in the safe on-screen band where a direct
    id tap reliably opens it — comfortably below the search bar and well ABOVE the
    floating tab bar (~y 779). A row whose center is near/under the tab bar (or far
    off-screen) must go through the scroll path instead; an id/coordinate tap on it
    no-ops because the hit point is occluded."""
    rect = _row_rect(tree, row_id)
    if rect is None:
        return False
    _x, y, _w, h = rect
    center = y + h // 2
    return 120 <= center <= 640


# Target band for the scrolled row's HEADER (top text line, ~y+22). We want the
# whole row to sit between the search bar and the floating tab bar (~y 779). A row
# whose header lands much past ~600 has its center under the tab bar and won't tap,
# so we accept a generous [130, 600] band (wider than one gentle-scroll step, to
# avoid ping-ponging) and treat anything outside it as needing another scroll.
_TARGET_TOP = 150
_TARGET_BOTTOM = 600


def _gentle_scroll(sim, direction: str, fraction: float = 0.22) -> None:
    """Small, controlled drag from screen-center (0-1000 normalized space) used
    to FINE-position a row when it's close to the target band, without the
    full-screen overshoot of `mobile: swipe` (one default swipe moves ~680px)."""
    try:
        sim.perform_action({
            "type": "swipe", "direction": direction,
            "x": 500, "y": 500, "distance_fraction": fraction,
        })
        sim.wait(0.4)
    except Exception:
        try:
            sim.swipe(direction); sim.wait(0.4)
        except Exception:
            pass


def _scroll_feed_row_into_view(sim, row_id: str, max_swipes: int = 22):
    """Scroll the Home feed until *row_id*'s header sits in [_TARGET_TOP,
    _TARGET_BOTTOM] (clear of the floating tab bar, where an id tap opens it).
    Returns the row's live (x, y, w, h) once positioned, or None.

    Rows can sit ~10000px below the fold, so close the distance with coarse
    full-screen swipes when far, and fine-position with a small coordinate drag
    when close — bounded, so a borderline row converges instead of oscillating.
    A transient truncated observe (row momentarily absent) is retried."""
    last_rect = None
    for _ in range(max_swipes):
        rect = _row_rect_live(sim, row_id)
        if rect is None:
            if last_rect is None:
                return None
            rect = last_rect
        last_rect = rect
        x, y, w, h = rect
        header = y + 22
        # Already inside the accepted band — done.
        if _TARGET_TOP <= header <= _TARGET_BOTTOM:
            return rect
        # Close to the band (within ~one gentle step): nudge gently so we settle
        # inside it rather than overshoot past it with a full swipe.
        if -120 <= header <= _TARGET_BOTTOM + 260:
            _gentle_scroll(sim, "up" if header > _TARGET_BOTTOM else "down")
            continue
        # Far away: cover ground fast with a full-screen swipe.
        try:
            sim.swipe("up" if header > _TARGET_BOTTOM else "down"); sim.wait(0.45)
        except Exception:
            return rect
    return _row_rect_live(sim, row_id)


@mcp.tool()
def open_pay_request() -> str:
    """Tap the central Pay/Request (V) button to open the payment-flow sheet.

    Opens the recipient picker (recipient_search_field). Does a single tap from
    the CURRENT screen and does not verify or self-recover, so call it from Home
    (or use navigate_to_tab('home') first) — if an overlay is covering the button
    the tap may no-op. The send_payment / request_payment / prepare_* tools open
    this flow themselves with overlay-dismissal + verification, so you usually
    don't need to call this directly.
    """
    sim = SimulatorBridge.get()
    sim.tap_id("pay_or_request_button")
    sim.wait(0.5)
    return "Opened Pay/Request flow."


def _enter_amount(sim, amount: str) -> None:
    """Enter an amount on the number pad via amount_digit_<n> / amount_decimal taps."""
    for ch in str(amount):
        if ch.isdigit():
            sim.tap_id(f"amount_digit_{ch}")
        elif ch == ".":
            sim.tap_id("amount_decimal")
        else:
            continue
        sim.wait(0.1)


_OVERLAY_MARKERS = (
    "transaction_detail_title", "transaction_detail_amount",
    "profile_name_", "profile_friend_toggle_", "profile_recent_header",
)

# The Pay/Request flow is a fullScreenCover that sits ABOVE the tab bar and the
# Home feed: its recipient picker / amount-entry / confirm markers appear while
# the feed rows + tab buttons remain in the tree behind it, so a tap on a tab,
# a feed row, or the central pay button no-ops. Any of these means the pay flow
# is up and must be dismissed before navigating elsewhere.
#
# Match the accessibility IDS EXACTLY (name="<id>") — a bare substring test for
# 'request_button' / 'send_button' also matches the always-present central
# 'pay_or_request_button' on Home, which would make _pay_flow_is_open falsely
# report the flow open on a clean feed and wedge every nav verify.
_PAY_FLOW_IDS = (
    "recipient_search_field", "send_button", "request_button",
    "pay_confirm_button", "amount_digit_0", "amount_decimal",
)


def _pay_flow_is_open(tree: str) -> bool:
    """True if the Pay/Request fullScreenCover is currently covering the app."""
    return any(f'name="{m}"' in tree for m in _PAY_FLOW_IDS)


def _pay_flow_blocked_by_overlay(tree: str) -> bool:
    """True if a sheet/detail overlay (transaction detail, profile, info sheet)
    OR the Pay/Request fullScreenCover is covering Home. The central
    pay_or_request_button (and the feed rows / tab buttons) can still appear in
    the tree *behind* such an overlay, so a tap would no-op — we must dismiss
    first."""
    return any(m in tree for m in _OVERLAY_MARKERS) or _pay_flow_is_open(tree)


def _dismiss_overlays(sim) -> str:
    """Dismiss any covering overlay (Pay/Request fullScreenCover, transaction
    detail / profile sheet) and return to a clean Home feed. Relaunch is the
    most reliable way to tear down a fullScreenCover AND any stacked sheet, and
    it re-renders the feed rows + tab bar so subsequent taps land. Returns the
    fresh tree."""
    tree = sim.observe_text() or ""
    if not _pay_flow_blocked_by_overlay(tree):
        return tree
    try:
        tree = sim.launch_and_observe(BUNDLE_ID) or ""
        sim.wait(0.3)
    except Exception:
        tree = sim.observe_text() or ""
    return tree


def _ensure_pay_flow_open(sim) -> None:
    """Open the Pay/Request fullScreenCover, dismissing any covering overlay
    first, and VERIFY it actually opened (raise otherwise).

    Bug-class fixes:
      (2) the central pay_or_request_button is present in the tree even when a
          transaction-detail / profile sheet is covering Home, so a naive tap
          no-ops. We detect such overlays (and any state where the flow fails
          to open) and RELAUNCH to a clean Home before tapping, then re-observe.
      (4) we confirm `recipient_search_field` actually rendered before
          returning — never assume the flow opened.
    """
    tree = sim.observe_text() or ""
    if "recipient_search_field" in tree:
        return
    # If an overlay is covering Home, or the central button isn't even present,
    # relaunch to a clean Home where the pay button is the top-most affordance.
    if _pay_flow_blocked_by_overlay(tree) or "pay_or_request_button" not in tree:
        try:
            tree = sim.launch_and_observe(BUNDLE_ID) or ""
            sim.wait(0.3)
        except Exception:
            tree = sim.observe_text() or ""
        if "recipient_search_field" in tree:
            return
    # Tap the central button and confirm the flow opened.
    try:
        sim.tap_id("pay_or_request_button"); sim.wait(1.5)  # fullScreenCover animation
    except Exception:
        pass
    if "recipient_search_field" in (sim.observe_text() or ""):
        return
    # Last resort: relaunch to a guaranteed-clean Home and tap once more.
    try:
        sim.launch_and_observe(BUNDLE_ID); sim.wait(0.3)
        sim.tap_id("pay_or_request_button"); sim.wait(1.5)
    except Exception:
        pass
    if "recipient_search_field" not in (sim.observe_text() or ""):
        raise RuntimeError(
            "Could not open the Pay/Request flow (recipient_search_field never "
            "appeared) even after dismissing overlays and relaunching to Home."
        )


def _search_field_value(tree: str) -> str:
    """Current text in the recipient search field, or '' if empty/absent.

    An empty XCUITextField reports its placeholder as `value`, so we treat
    value == placeholderValue (the 'Phone, name or @username' hint) as empty."""
    m = re.search(
        r'<XCUIElementTypeTextField[^>]*name="recipient_search_field"[^>]*/?>',
        tree,
    )
    if not m:
        m2 = re.search(r'name="recipient_search_field"[^>]*\bvalue="([^"]*)"', tree) \
            or re.search(r'\bvalue="([^"]*)"[^>]*name="recipient_search_field"', tree)
        return m2.group(1) if m2 else ""
    node = m.group(0)
    vm = re.search(r'\bvalue="([^"]*)"', node)
    pm = re.search(r'\bplaceholderValue="([^"]*)"', node)
    val = vm.group(1) if vm else ""
    placeholder = pm.group(1) if pm else ""
    if val and placeholder and val == placeholder:
        return ""
    return val


def _clear_search_field(sim) -> None:
    """Clear stale text from the focused recipient search field by sending one
    backspace per existing character. Re-reads the value after to confirm; no-op
    if the field is already empty. (The field has no native clear button, and a
    plain type_text would APPEND to a stale query like 'Maya'.)"""
    tree = sim.observe_text() or ""
    cur = _search_field_value(tree)
    if not cur:
        return
    # Send backspaces (a couple extra to cover any cursor/placeholder quirk).
    try:
        sim.type_text("\b" * (len(cur) + 2))
        sim.wait(0.3)
    except Exception:
        pass
    # If backspaces didn't take, fall back to tapping a clear/'xmark' affordance
    # if present, else leave it (the row resolution below will still try).
    if _search_field_value(sim.observe_text() or ""):
        for clear_id in ("xmark.circle.fill", "Clear text"):
            try:
                sim.tap_id(clear_id); sim.wait(0.2)
                if not _search_field_value(sim.observe_text() or ""):
                    return
            except Exception:
                continue


def _select_recipient(sim, recipient: str) -> Optional[str]:
    """Resolve *recipient* (id / name / username / partial) and tap their row in
    the open Pay/Request recipient picker, scrolling/searching as needed.

    Returns None once the amount-entry view for that user is showing, or an
    error string. Assumes the recipient picker is already open.
    """
    resolved = _resolve_user(recipient)
    if resolved is None or resolved[0] == "user_you":
        return (
            f"No SplitPay user matches '{recipient}'. Try a full name "
            f"(e.g. 'Maya Patel'), @username, or user id (e.g. 'user_trevor')."
        )
    _id, display, username = resolved
    slug = _slug(display)
    row_id = f"recipient_row_{slug}"

    # Type the resolved display name so the (case-sensitive-slug) row is rendered.
    # Bug-class (1)/(2): the Pay flow may already be open with STALE query text
    # in the field (e.g. a prior search typed 'Maya'); _ensure_pay_flow_open
    # returns early in that case without clearing it, so a plain type_text would
    # append -> 'MayaLeo Chen' and no row matches. Clear the field first.
    try:
        sim.tap_id("recipient_search_field"); sim.wait(0.3)
        _clear_search_field(sim)
        sim.type_text(display); sim.wait(0.7)
    except Exception:
        pass

    # The row id keys off the canonical display-name slug, so it now matches
    # regardless of how the caller spelled the recipient.
    try:
        sim.tap_id(row_id); sim.wait(0.8)
    except Exception:
        # Fallback: tap by visible name label (NSPredicate name/label match).
        try:
            sim.tap_id(display); sim.wait(0.8)
        except Exception as exc:
            return (
                f"Could not tap the recipient row for '{recipient}' "
                f"(resolved to {display}, {row_id}). {str(exc)[:100]}"
            )
    # Confirm we advanced to amount entry (send/request buttons present).
    after = sim.observe_text() or ""
    if "send_button" not in after and "request_button" not in after:
        return (
            f"Could not advance to amount entry for '{display}' "
            f"(send/request buttons not visible). Re-open the Pay/Request flow and retry."
        )
    return None


def _send_payment_fill_form(recipient: str, amount: str, memo: str = "") -> Optional[str]:
    """Open the Pay/Request flow, select recipient, enter amount/memo, and
    tap `send_button` to surface the confirmation sheet (no final commit).

    Self-navigates (opens the flow from any screen) and resolves the recipient
    by id / display name / @username / partial name. Returns None on success or
    a precondition message on failure. The final irreversible commit is
    `pay_confirm_button` on the surfaced confirmation sheet, which
    `send_payment` and `confirm_send_payment` are responsible for tapping.
    """
    sim = SimulatorBridge.get()
    try:
        _ensure_pay_flow_open(sim)
        err = _select_recipient(sim, recipient)
        if err:
            return err
        _enter_amount(sim, amount); sim.wait(0.3)
        if memo:
            sim.tap_id("memo_field"); sim.wait(0.3)
            sim.type_text(memo); sim.wait(0.3)
        sim.tap_id("send_button"); sim.wait(1.5)
        return None
    except Exception as exc:
        return (
            f"Could not stage send_payment for '{recipient}' ${amount}. "
            f"Open the Pay/Request flow via observe() and verify the recipient row exists. "
            f"{str(exc)[:120]}"
        )


@mcp.tool()
def send_payment(recipient: str, amount: str, memo: str = "") -> str:
    """Send a SplitPay payment end-to-end (opens flow, fills, taps Confirm). COMMITS.

    Works from any screen — self-navigates (opens the Pay/Request flow,
    dismissing any covering overlay first).

    Args:
      recipient: the payee — internal id ('user_brian'), display name
        ('Maya Patel'), @username, or a UNIQUE partial/first name ('maya'), all
        case-insensitive. The human-readable name works; you don't need the slug.
        An AMBIGUOUS partial (e.g. 'Brooks', 'Sofia') returns a failure message
        instead of guessing — pass a fuller name.
      amount: positive dollar amount as a string ('50', '50.25'); entered via the
        on-screen number pad.
      memo: optional free-text note, left blank by default.

    Returns "Sent $<amount> to <recipient>..." on success, or a precondition
    failure message (unresolved/ambiguous recipient, flow wouldn't open) before
    any money moves. Legacy single-verb commit — prefer `prepare_send_payment` +
    `confirm_send_payment` to inspect the filled form before committing.
    """
    sim = SimulatorBridge.get()
    err = _send_payment_fill_form(recipient, amount, memo)
    if err:
        return err
    # Confirmation sheet appears with pay_confirm_button
    try:
        sim.tap_id("pay_confirm_button"); sim.wait(1.5)
    except Exception:
        pass
    return f"Sent ${amount} to {recipient} (memo: '{memo}')."


@mcp.tool()
def prepare_send_payment(recipient: str, amount: str, memo: str = "") -> dict:
    """Open the SplitPay send flow and pre-fill it WITHOUT committing.

    Works from any screen — self-navigates (opens the Pay/Request flow,
    dismissing any covering overlay first).

    Args:
      recipient: the payee — internal id ('user_brian'), display name
        ('Maya Patel'), @username, or a UNIQUE partial/first name, case-insensitive.
        The human-readable name works. An AMBIGUOUS partial returns ok:False
        instead of guessing.
      amount: positive dollar amount as a string ('50', '50.25').
      memo: optional free-text note.

    Taps Pay/Request, selects the recipient, enters the amount via the
    number pad, fills the memo, and taps `send_button` to surface the
    final confirmation sheet — but does NOT tap `pay_confirm_button`.
    Pass the returned ``draft_id`` to `confirm_send_payment` to commit.

    Returns ``{ok: True, action, draft_id, summary, next}`` on success,
    or ``{ok: False, action, message}`` on precondition failure (no
    draft stored). Drafts expire after `IOSWORLD_DRAFT_TTL_SECONDS`
    (default 10 minutes) or on simulator session reset.
    """
    err = _send_payment_fill_form(recipient, amount, memo)
    if err:
        return {"ok": False, "action": "prepare_send_payment", "message": err}
    summary = {"recipient": recipient, "amount": amount, "memo": memo}
    draft_id = ts.create_draft("splitpay", "send_payment", summary)
    return {
        "ok": True,
        "action": "prepare_send_payment",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_send_payment(draft_id) to commit.",
    }


@mcp.tool()
def confirm_send_payment(draft_id: str) -> dict:
    """Commit a SplitPay send previously staged by `prepare_send_payment`.

    Args:
      draft_id: the id returned by `prepare_send_payment`.

    Taps `pay_confirm_button` on the confirmation sheet. Returns
    ``{ok: True, action: "confirm_send_payment", evidence: <summary>}``
    on success. If the draft is missing or expired, returns a
    controlled-failure response and does not tap the confirm button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_send_payment",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_send_payment first.",
        }
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("pay_confirm_button"); sim.wait(1.5)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_send_payment",
            "message": "Confirm button not found in current UI; verify the pay confirmation sheet is still open.",
        }
    return {
        "ok": True,
        "action": "confirm_send_payment",
        "evidence": draft.get("payload", {}),
    }


def _request_confirm_label(amount: str) -> str:
    """The Request-confirm button has no accessibilityIdentifier; its label
    is ``Request $%.2f`` (e.g. '9' -> 'Request $9.00'). tap_id falls back to
    NSPredicate name/label matching, so tapping this label commits."""
    try:
        return f"Request ${float(str(amount)):.2f}"
    except Exception:
        return f"Request ${amount}"


def _tap_request_confirm(sim, amount: str) -> bool:
    """Tap the surfaced Request confirmation button. Returns True if tapped.

    The confirm sheet's primary button (label 'Request $X.XX') carries no
    accessibility id, so we match it by label/name. Falls back to a couple
    of label variants in case of trailing-zero formatting differences.
    """
    candidates = [_request_confirm_label(amount)]
    try:
        amt = float(str(amount))
        if amt == int(amt):
            candidates.append(f"Request ${int(amt)}.00")
    except Exception:
        pass
    for label in candidates:
        try:
            sim.tap_id(label); sim.wait(1.0)
            return True
        except Exception:
            continue
    return False


def _request_payment_fill_form(from_person: str, amount: str, memo: str = "") -> Optional[str]:
    """Open the Pay/Request flow, select the source friend, enter amount/memo,
    and tap ``request_button`` to surface the Confirm Request sheet (no final
    commit). Returns None on success or a precondition message on failure.

    The irreversible commit is the sheet's 'Request $X.XX' button, tapped by
    ``request_payment`` / ``confirm_request_payment`` via ``_tap_request_confirm``.
    """
    sim = SimulatorBridge.get()
    try:
        _ensure_pay_flow_open(sim)
        err = _select_recipient(sim, from_person)
        if err:
            return err
        # Amount entry uses a custom number pad (no `amount_field`).
        _enter_amount(sim, amount); sim.wait(0.3)
        if memo:
            sim.tap_id("memo_field"); sim.wait(0.3)
            sim.type_text(memo); sim.wait(0.3)
        # Surface the Confirm Request sheet (requireConfirmation defaults true).
        sim.tap_id("request_button"); sim.wait(1.2)
        return None
    except Exception as exc:
        return (
            f"Could not stage request_payment from '{from_person}' for ${amount}. "
            f"Open the Pay/Request flow via observe() and verify the recipient row exists. "
            f"{str(exc)[:120]}"
        )


@mcp.tool()
def request_payment(from_person: str, amount: str, memo: str = "") -> str:
    """Request a payment from a friend end-to-end (opens flow, fills, taps Request). COMMITS.

    Works from any screen — self-navigates (opens the Pay/Request flow,
    dismissing any covering overlay first).

    Args:
      from_person: who to charge — internal id ('user_brian'), display name
        ('Maya Patel'), @username, or a UNIQUE partial/first name, case-insensitive.
        The human-readable name works. An AMBIGUOUS partial returns a failure
        message instead of guessing.
      amount: positive dollar amount as a string ('50', '50.25'); entered via the
        on-screen number pad.
      memo: optional free-text note.

    Commits by tapping the 'Request $X.XX' button on the surfaced sheet (it has no
    accessibility id; matched by label). Returns "Requested $<amount> from..." on
    success, or a failure message (unresolved/ambiguous person, confirm button not
    found) you can react to. Legacy single-verb commit — prefer
    `prepare_request_payment` + `confirm_request_payment` for new code.
    """
    sim = SimulatorBridge.get()
    err = _request_payment_fill_form(from_person, amount, memo)
    if err:
        return err
    # Commit on the surfaced Confirm Request sheet (the 'Request $X.XX' button,
    # which has no accessibility id — matched by label).
    if not _tap_request_confirm(sim, amount):
        return (
            f"Could not tap the Confirm Request button after filling the request "
            f"form for ${amount} from {from_person}. Call observe() and tap the "
            f"'{_request_confirm_label(amount)}' button to finalize."
        )
    return f"Requested ${amount} from {from_person}" + (f" (memo: '{memo}')" if memo else "") + "."


@mcp.tool()
def prepare_request_payment(from_person: str, amount: str, memo: str = "") -> dict:
    """Open the SplitPay request flow and pre-fill it WITHOUT committing.

    Works from any screen — self-navigates (opens the Pay/Request flow,
    dismissing any covering overlay first).

    Args:
      from_person: who to charge — internal id ('user_brian'), display name
        ('Maya Patel'), @username, or a UNIQUE partial/first name, case-insensitive.
        The human-readable name works. An AMBIGUOUS partial returns ok:False
        instead of guessing.
      amount: positive dollar amount as a string ('50', '50.25').
      memo: optional free-text note.

    Taps Pay/Request, selects the friend, enters the amount via the
    number pad, fills the memo, and taps `request_button` to surface the
    Confirm Request sheet — but does NOT tap the final 'Request $X.XX'
    commit button. Pass the returned ``draft_id`` to
    `confirm_request_payment` to commit.

    Returns ``{ok: True, action, draft_id, summary, next}`` on success,
    or ``{ok: False, action, message}`` on precondition failure (no
    draft stored). Drafts expire after `IOSWORLD_DRAFT_TTL_SECONDS`
    (default 10 minutes) or on simulator session reset.
    """
    err = _request_payment_fill_form(from_person, amount, memo)
    if err:
        return {"ok": False, "action": "prepare_request_payment", "message": err}
    summary = {"from_person": from_person, "amount": amount, "memo": memo}
    draft_id = ts.create_draft("splitpay", "request_payment", summary)
    return {
        "ok": True,
        "action": "prepare_request_payment",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_request_payment(draft_id) to commit.",
    }


@mcp.tool()
def confirm_request_payment(draft_id: str) -> dict:
    """Commit a SplitPay request previously staged by `prepare_request_payment`.

    Args:
      draft_id: the id returned by `prepare_request_payment`.

    Taps the surfaced 'Request $X.XX' commit button (no accessibility id; matched
    by label, amount taken from the draft) to finalize the request. Returns
    ``{ok: True, action: "confirm_request_payment", evidence: <summary>}``
    on success. If the draft is missing or expired, returns a
    controlled-failure response and does not tap the request button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_request_payment",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_request_payment first.",
        }
    sim = SimulatorBridge.get()
    payload = draft.get("payload", {})
    amount = str(payload.get("amount", ""))
    if not _tap_request_confirm(sim, amount):
        return {
            "ok": False,
            "action": "confirm_request_payment",
            "message": (
                "Confirm Request button not found in current UI; verify the "
                "Confirm Request sheet is still open (prepare_request_payment "
                "surfaces it)."
            ),
        }
    return {
        "ok": True,
        "action": "confirm_request_payment",
        "evidence": payload,
    }


def _find_feed_row_for_name(tree: str, display: str):
    """Return (feed_row_uuid, side) for a feed row whose label mentions *display*,
    where side is 'from' if the name is the payer (left of 'paid'/'charged') else
    'to'. Returns (None, None) if no row mentions the user.

    Feed-row buttons carry label like 'Jordan Avery paid Maya Patel, 23d, memo'
    (or 'X charged Y, ...'). The payer is before the verb, the recipient after.
    """
    dlow = display.lower()
    for m in re.finditer(
        r'name="(splitpay_feed_row_[0-9A-Fa-f\-]+)"\s+label="([^"]*)"', tree
    ):
        row_id, label = m.group(1), m.group(2)
        llow = label.lower()
        if dlow not in llow:
            continue
        uuid = row_id[len("splitpay_feed_row_"):]
        # Split on the action verb to decide which side the name is on.
        verb_idx = -1
        for verb in (" paid ", " charged ", " requested ", " sent "):
            i = llow.find(verb)
            if i != -1:
                verb_idx = i + len(verb)
                break
        if verb_idx == -1:
            # Can't tell; default to 'to' (recipient) — both rows open the same
            # profile only when the user is on that side, so try the matching half.
            side = "to" if llow.find(dlow) > len(llow) // 2 else "from"
        else:
            side = "to" if llow.find(dlow) >= verb_idx else "from"
        return uuid, side
    return None, None


def _open_profile_via_transaction(sim, user_id: str, display: str) -> Optional[str]:
    """Open UserProfileView for (user_id, display) by drilling into a feed
    transaction that involves them and tapping the From/To navigation row.

    Returns None once profile_name_<user_id> is showing, or an error string.
    """
    # Relaunch to a clean Home feed (dismisses any sheet/overlay that would
    # cover the rows) and scan the feed for a transaction involving the user.
    try:
        tree = sim.launch_and_observe(BUNDLE_ID) or ""
        sim.wait(0.3)
    except Exception:
        tree = sim.observe_text() or ""
    uuid, side = _find_feed_row_for_name(tree, display)
    if not uuid:
        return (
            f"Could not find any feed transaction involving '{display}' "
            f"({user_id}) to open their profile from."
        )
    # Open the transaction detail.
    try:
        sim.tap_id(f"splitpay_feed_row_{uuid}"); sim.wait(0.8)
    except Exception as exc:
        return f"Could not open transaction {uuid} for '{display}'. {str(exc)[:100]}"
    detail = sim.observe_text() or ""
    if "transaction_detail_title" not in detail:
        return f"Could not open the transaction detail for '{display}' ({uuid})."
    # Tap the From/To navigation row that shows this user's name, pushing
    # UserProfileView. Prefer the computed side; fall back to the other.
    order = [side, "to" if side == "from" else "from"]
    for s in order:
        row_id = f"transaction_detail_{s}"
        # Only tap the side that actually shows this user's display name.
        if display.lower() not in detail.lower():
            break
        try:
            sim.tap_id(row_id); sim.wait(0.8)
        except Exception:
            continue
        after = sim.observe_text() or ""
        if f"profile_name_{user_id}" in after:
            return None
    after = sim.observe_text() or ""
    if f"profile_name_{user_id}" in after:
        return None
    return (
        f"Could not open profile for '{display}' after tapping the From/To row "
        f"(profile_name_{user_id} did not render)."
    )


@mcp.tool()
def view_profile(user_id: str) -> str:
    """Open a user's profile sheet (UserProfileView).

    Args:
      user_id: internal user ID (e.g. `user_brian`), display name
        ('Maya Patel'), @username, or a unique partial — all resolved to the
        canonical user.

    Path: each Home-feed transaction row exposes a tappable
    `profile_avatar_<id>` button that presents UserProfileView (exposing
    `profile_name_<id>`, `profile_username_<id>`, `profile_friend_toggle_<id>`).
    This tool relaunches to a clean Home feed first so any covering
    sheet/overlay is dismissed before tapping, and VERIFIES the profile sheet
    actually rendered. If the user isn't a payer in the feed (no avatar), it
    falls back to drilling into a transaction that mentions them and tapping its
    From/To navigation row.
    """
    sim = SimulatorBridge.get()
    # Resolve a blind reference (display name / @username / partial) to the
    # canonical internal id the profile_* identifiers key off of.
    resolved = _resolve_user(user_id)
    if resolved is None:
        return (
            f"No SplitPay user matches '{user_id}'. Try a full name "
            f"(e.g. 'Maya Patel'), @username, or user id (e.g. 'user_brian')."
        )
    uid, display, _username = resolved
    # If this user's profile sheet is already up, we're done.
    try:
        if f"profile_name_{uid}" in (sim.observe_text() or ""):
            return f"Opened profile for {uid}."
    except Exception:
        pass
    # Relaunch to a clean Home feed: dismisses any transaction-detail / profile
    # / info sheet that would otherwise cover (and no-op a tap on) the feed
    # avatars, and re-renders the row buttons that carry profile_avatar_<id>.
    try:
        tree = sim.launch_and_observe(BUNDLE_ID) or ""
        sim.wait(0.3)
    except Exception:
        tree = sim.observe_text() or ""
    # Primary path: tap the feed avatar button for this user.
    if f"profile_avatar_{uid}" in tree:
        try:
            sim.tap_id(f"profile_avatar_{uid}"); sim.wait(0.9)
        except Exception:
            pass
        if f"profile_name_{uid}" in (sim.observe_text() or ""):
            return f"Opened profile for {uid}."
    # Fallback: drill into a transaction mentioning the user and tap From/To.
    err = _open_profile_via_transaction(sim, uid, display)
    if err:
        return err
    return f"Opened profile for {uid}."


@mcp.tool()
def toggle_friend(user_id: str) -> str:
    """Toggle a user's friend status (taps `profile_friend_toggle_<user_id>`).

    Args:
      user_id: the user — internal id ('user_brian'), display name ('Maya Patel'),
        @username, or a UNIQUE partial/first name, case-insensitive (resolved like
        `view_profile`). The human-readable name works.

    Works from any screen — self-navigates: if the friend-toggle button isn't on
    screen it opens that user's profile sheet first (via view_profile, which
    relaunches to Home). If the UI tap still can't be made, it falls back to
    flipping friend status directly in app state and returns a dict
    {ok, action, user_id, is_friend, friend_count, state_fallback:true}. The
    normal UI path returns "Toggled friend status for user <id>.".
    """
    sim = SimulatorBridge.get()
    # Resolve a blind reference (name / @username / partial) to the canonical id.
    resolved = _resolve_user(user_id)
    if resolved is not None:
        user_id = resolved[0]
    # Self-navigate: if the friend-toggle button isn't on screen, open this
    # user's profile sheet first (view_profile handles Home navigation).
    try:
        if f"profile_friend_toggle_{user_id}" not in (sim.observe_text() or ""):
            view_profile(user_id)
            sim.wait(0.3)
    except Exception:
        pass
    try:
        sim.tap_id(f"profile_friend_toggle_{user_id}")
        sim.wait(0.3)
        return f"Toggled friend status for user {user_id}."
    except Exception:
        user_id = (user_id or "").strip()
        if not user_id:
            return {"ok": False, "action": "toggle_friend", "message": "user_id is required"}
        defaults = dl.read_user_defaults(BUNDLE_ID)
        raw = defaults.get("friends")
        try:
            friends = json.loads(raw.decode("utf-8") if isinstance(raw, (bytes, bytearray)) else raw) if raw else list(DEFAULT_FRIEND_IDS)
        except Exception:
            friends = list(DEFAULT_FRIEND_IDS)
        if user_id in friends:
            friends = [f for f in friends if f != user_id]
            is_friend = False
        else:
            friends.append(user_id)
            is_friend = True
        defaults["friends"] = json.dumps(friends).encode("utf-8")
        dl.write_user_defaults(BUNDLE_ID, defaults)
        dl.reload_app(BUNDLE_ID)
        return {
            "ok": True,
            "action": "toggle_friend",
            "user_id": user_id,
            "is_friend": is_friend,
            "friend_count": len(friends),
            "state_fallback": True,
        }


@mcp.tool()
def view_wallet() -> str:
    """Switch to the Cards/Wallet tab (alias for `navigate_to_tab('cards')`)."""
    return navigate_to_tab("cards")


@mcp.tool()
def view_requests() -> str:
    """Switch to the Me tab — requests and profile (alias for `navigate_to_tab('me')`)."""
    return navigate_to_tab("me")


@mcp.tool()
def view_settings() -> str:
    """Switch to the Crypto/Settings tab (alias for `navigate_to_tab('crypto')`)."""
    return navigate_to_tab("crypto")


if __name__ == "__main__":
    mcp.run()
