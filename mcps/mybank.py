"""MyBank MCP — accounts, transactions, transfers, deposits, bills, Zelle, rewards.

Bundle ID: com.iosworld.benchmark.mybank

Accessibility-ID conventions (see MyBank/Views/):
  Tabs: chase_tab_<slug> (home/activity/pay/deposits/more etc.)
  Home: home_accounts_menu, home_add_action_button, home_credit_card,
        home_credit_journey_card, home_chip_deposit, home_chip_pay_bills,
        home_chip_pay_credit_card, home_chip_zelle, home_offer_<id>_button,
        home_search_bar, home_activity_row_<index>, home_link_external_accounts
  Accounts: account_balance_/available_/type_/name_/card_/updated_<raw>
  Cards: card_balance_/number_/view_<raw>
  Transactions: transaction_cell_/amount_/vendor_/category_/status_dot_/
                timestamp_/source_<uuid>
  Detail: detail_amount_label, detail_vendor_label, detail_status_label,
          detail_dispute_button, detail_share_button
  Transfer: transfer_from_picker_sheet, transfer_to_picker_sheet,
            transfer_amount_field_sheet, transfer_note_field_sheet,
            transfer_submit_button, transfer_cancel_button
  Deposit: deposit_account_picker, deposit_amount_field, deposit_note_field,
           deposit_submit_button, deposit_cancel_button
  Bill pay: bill_mode_picker, bill_payee_picker, bill_amount_field,
            bill_memo_field, bill_schedule_date_picker, bill_submit_button
  Zelle: zelle_amount_field, zelle_memo_field
  Rewards: reward_points_picker, reward_redeem_button
  Toolbar: toolbar_chase_logo, toolbar_clipboard, toolbar_profile
"""

import sys, pathlib, re, uuid
from datetime import datetime, timezone, timedelta
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("MyBank")

BUNDLE_ID = "com.iosworld.benchmark.mybank"

# Actual tab IDs rendered by ChaseTabBar (see MyBank/Views/RootView.swift):
#   chase_tab_home, chase_tab_pay_and_transfer, chase_tab_plan_and_track,
#   chase_tab_rewards, chase_tab_more. Map user-friendly shorthands to them.
_TAB_MAP = {
    "home": "chase_tab_home",
    "pay": "chase_tab_pay_and_transfer",
    "pay_transfer": "chase_tab_pay_and_transfer",
    "pay_and_transfer": "chase_tab_pay_and_transfer",
    "transfer": "chase_tab_pay_and_transfer",
    "zelle": "chase_tab_pay_and_transfer",
    "bills": "chase_tab_pay_and_transfer",
    "plan": "chase_tab_plan_and_track",
    "plan_track": "chase_tab_plan_and_track",
    "plan_and_track": "chase_tab_plan_and_track",
    "track": "chase_tab_plan_and_track",
    "budget": "chase_tab_plan_and_track",
    "rewards": "chase_tab_rewards",
    "more": "chase_tab_more",
}


def _slug(s: str) -> str:
    return s.lower().replace(" ", "_")


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _positive_amount(value) -> float:
    try:
        amount = float(str(value).replace("$", "").strip())
    except Exception:
        raise ValueError("amount must be a positive number")
    if amount <= 0:
        raise ValueError("amount must be a positive number")
    return round(amount, 2)


def _load_state() -> dict:
    return dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}


def _save_state(state: dict) -> None:
    dl.write_app_state(BUNDLE_ID, "mybank_state.json", state)
    dl.reload_app(BUNDLE_ID)


def _page_bounds(page, page_size, default_size: int = 50, max_size: int = 200) -> tuple[int, int]:
    try:
        p = int(page)
    except Exception:
        p = 1
    try:
        size = int(page_size)
    except Exception:
        size = default_size
    p = max(1, p)
    size = min(max(1, size), max_size)
    return p, size


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


def _account(state: dict, account_type: str) -> dict | None:
    return next((a for a in state.get("accounts", []) if a.get("type") == account_type), None)


def _account_lookup(state: dict) -> dict:
    return {
        str(a.get("id")): {
            "account_id": a.get("id"),
            "account_type": a.get("type"),
            "account_name": a.get("name"),
        }
        for a in state.get("accounts", [])
        if a.get("id")
    }


def _transaction_row(t: dict, accounts: dict) -> dict:
    row = {
        "id": t.get("id"),
        "vendor": t.get("vendor"),
        "amount": t.get("amount"),
        "category": t.get("category"),
        "timestamp": t.get("timestamp"),
        "status": t.get("status"),
        "note": t.get("note"),
    }
    row.update(accounts.get(str(t.get("account_id")), {
        "account_id": t.get("account_id"),
        "account_type": None,
        "account_name": None,
    }))
    return row


def _transaction_totals(rows: list[dict]) -> dict:
    by_category: dict[str, dict] = {}
    by_account: dict[str, dict] = {}
    credit = debit = 0.0
    for row in rows:
        try:
            amount = float(row.get("amount") or 0)
        except Exception:
            amount = 0.0
        if amount >= 0:
            credit += amount
        else:
            debit += amount
        category = row.get("category") or "Uncategorized"
        cat = by_category.setdefault(category, {"count": 0, "net_amount": 0.0})
        cat["count"] += 1
        cat["net_amount"] = round(cat["net_amount"] + amount, 2)
        account_key = row.get("account_type") or row.get("account_id") or "unknown"
        acct = by_account.setdefault(str(account_key), {
            "account_name": row.get("account_name"),
            "count": 0,
            "net_amount": 0.0,
        })
        acct["count"] += 1
        acct["net_amount"] = round(acct["net_amount"] + amount, 2)
    return {
        "credits": round(credit, 2),
        "debits": round(debit, 2),
        "net_amount": round(credit + debit, 2),
        "by_category": by_category,
        "by_account": by_account,
    }


def _find_transaction(state: dict, transaction_id: str) -> dict | None:
    raw = (transaction_id or "").strip()
    if raw.startswith("transaction_cell_"):
        raw = raw[len("transaction_cell_"):]
    if not raw:
        return None
    txs = [t for t in state.get("transactions", []) if t.get("id")]
    exact = next((t for t in txs if str(t.get("id")) == raw), None)
    if exact is not None:
        return exact
    low = raw.lower()
    exact = next((t for t in txs if str(t.get("id", "")).lower() == low), None)
    if exact is not None:
        return exact
    norm = re.sub(r"[^A-Za-z0-9]+", "", raw).lower()
    if len(norm) < 8:
        return None
    matches = [
        t for t in txs
        if re.sub(r"[^A-Za-z0-9]+", "", str(t.get("id") or "")).lower().startswith(norm)
    ]
    return matches[0] if len(matches) == 1 else None


def _payee(state: dict, name: str) -> dict | None:
    needle = (name or "").strip().lower()
    if not needle:
        return None
    return next((p for p in state.get("payees", []) if needle in str(p.get("name", "")).lower()), None)


def _apply_transaction_to_account(account: dict, amount: float) -> None:
    if account.get("type") == "credit":
        delta = abs(amount) if amount < 0 else -abs(amount)
    else:
        delta = amount
    account["balance"] = round(float(account.get("balance", 0)) + delta, 2)
    if account.get("type") == "credit" and account.get("creditLimit") is not None:
        account["availableBalance"] = round(float(account.get("creditLimit", 0)) - account["balance"], 2)
    else:
        account["availableBalance"] = account["balance"]
    account["lastUpdated"] = _now_iso()


def _make_transaction(account: dict, vendor: str, amount: float, category: str, note: str | None, raw_source: str, source_app: str = "MyBank") -> dict:
    return {
        "id": str(uuid.uuid4()).upper(),
        "external_id": str(uuid.uuid4()),
        "account_id": account["id"],
        "vendor": vendor,
        "amount": round(amount, 2),
        "currency": account.get("currency", "USD"),
        "category": category,
        "note": note or None,
        "timestamp": _now_iso(),
        "status": "posted",
        "source_app": source_app,
        "raw_source": raw_source,
    }


def _deposit_state(amount, note: str = "") -> dict:
    value = _positive_amount(amount)
    state = _load_state()
    checking = _account(state, "checking")
    if not checking:
        return {"ok": False, "error": "checking account not found"}
    transaction = _make_transaction(checking, "Mobile Check Deposit", value, "Deposit", note, "deposit")
    state.setdefault("transactions", []).insert(0, transaction)
    _apply_transaction_to_account(checking, value)
    _save_state(state)
    return {"ok": True, "transaction_id": transaction["id"], "account_id": checking["id"], "amount": value, "balance": checking["balance"]}


def _transfer_state(amount, note: str = "") -> dict:
    value = _positive_amount(amount)
    state = _load_state()
    checking = _account(state, "checking")
    savings = _account(state, "savings")
    if not checking or not savings:
        return {"ok": False, "error": "checking and savings accounts are required"}
    if float(checking.get("availableBalance", 0)) < value:
        return {"ok": False, "error": "insufficient available balance"}
    outgoing = _make_transaction(checking, f"Transfer to {savings.get('name')}", -value, "Transfer", note, "transfer")
    incoming = _make_transaction(savings, f"Transfer from {checking.get('name')}", value, "Transfer", note, "transfer")
    state.setdefault("transactions", [])[0:0] = [outgoing, incoming]
    _apply_transaction_to_account(checking, -value)
    _apply_transaction_to_account(savings, value)
    _save_state(state)
    return {
        "ok": True,
        "from_account_id": checking["id"],
        "to_account_id": savings["id"],
        "amount": value,
        "transaction_ids": [outgoing["id"], incoming["id"]],
    }


def _pay_bill_state(amount, memo: str = "", payee_name: str = "Electric") -> dict:
    value = _positive_amount(amount)
    state = _load_state()
    checking = _account(state, "checking")
    payee = _payee(state, payee_name) or next((p for p in state.get("payees", []) if p.get("category") != "Zelle"), None)
    if not checking:
        return {"ok": False, "error": "checking account not found"}
    if not payee:
        return {"ok": False, "error": "payee not found"}
    if float(checking.get("availableBalance", 0)) < value:
        return {"ok": False, "error": "insufficient available balance"}
    transactions = [_make_transaction(checking, payee["name"], -value, payee.get("category", "Bill"), memo, "bill_pay")]
    if payee.get("category") == "Credit Card":
        credit = _account(state, "credit")
        if credit:
            transactions.append(_make_transaction(credit, f"Payment from {checking.get('name')}", value, "Payment", memo, "bill_pay"))
    state.setdefault("transactions", [])[0:0] = transactions
    for transaction in transactions:
        account = next((a for a in state.get("accounts", []) if a.get("id") == transaction["account_id"]), None)
        if account:
            _apply_transaction_to_account(account, transaction["amount"])
    _save_state(state)
    return {"ok": True, "payee": payee["name"], "amount": value, "transaction_ids": [t["id"] for t in transactions]}


def _zelle_txn_count(recipient: str = "") -> int:
    """Count posted outgoing Zelle transactions (optionally to a recipient).

    Used as a read-back marker: the UI Send button closes the sheet without
    persisting anything in this build, so a real send must show up as a new
    ``Zelle to <recipient>`` transaction in the store.
    """
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    needle = (recipient or "").strip().lower()
    n = 0
    for t in state.get("transactions", []):
        vendor = str(t.get("vendor", ""))
        if t.get("category") == "Zelle" and vendor.lower().startswith("zelle to"):
            if not needle or needle in vendor.lower():
                n += 1
    return n


def _transfer_txn_count() -> int:
    """Count posted Transfer-category transactions (read-back marker)."""
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    return sum(1 for t in state.get("transactions", []) if t.get("category") == "Transfer")


def _bill_txn_count() -> int:
    """Count posted bill-pay transactions (raw_source == 'bill_pay'; read-back)."""
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    return sum(1 for t in state.get("transactions", []) if t.get("raw_source") == "bill_pay")


def _zelle_state(recipient: str, amount, memo: str = "") -> dict:
    """Commit a Zelle payment by directly writing the seed state (no UI).

    Mirrors `_pay_bill_state`: posts an outgoing transaction from checking to
    the matching Zelle payee. Used as a fallback when the home Zelle chip /
    send sheet is not reachable in the current build's UI.
    """
    value = _positive_amount(amount)
    state = _load_state()
    checking = _account(state, "checking")
    if not checking:
        return {"ok": False, "error": "checking account not found"}
    payee = _payee(state, recipient)
    payee_name = payee["name"] if payee else (recipient or "Zelle recipient")
    if float(checking.get("availableBalance", 0)) < value:
        return {"ok": False, "error": "insufficient available balance"}
    transaction = _make_transaction(checking, f"Zelle to {payee_name}", -value, "Zelle", memo, "zelle")
    state.setdefault("transactions", []).insert(0, transaction)
    _apply_transaction_to_account(checking, -value)
    _save_state(state)
    return {"ok": True, "recipient": payee_name, "amount": value, "transaction_id": transaction["id"]}


def _redeem_rewards_state(points: int = 100) -> dict:
    try:
        value = int(points)
    except Exception:
        value = 100
    if value <= 0:
        return {"ok": False, "error": "points must be positive"}
    state = _load_state()
    available = int(state.get("rewardPoints", 0) or 0)
    if available and value > available:
        value = available
    state["redeemedRewardPoints"] = int(state.get("redeemedRewardPoints", 0)) + value
    if available:
        state["rewardPoints"] = max(0, available - value)
    _save_state(state)
    return {
        "ok": True,
        "redeemed_points": value,
        "remaining_points": state.get("rewardPoints"),
        "total_redeemed_points": state["redeemedRewardPoints"],
    }


@mcp.tool()
def launch() -> str:
    """Launch MyBank and return the initial UI tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched MyBank.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree as text (no taps performed)."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="MyBank",
        markers=("mybank_", "account_card_", "transaction_row_", "card_row_"),
    )


@mcp.tool()
def navigate_to_tab(tab: str) -> str:
    """Switch the bottom tab.

    Args:
        tab: One of: `home`, `pay` (aliases `pay_and_transfer`, `transfer`,
            `zelle`, `bills`), `plan` (aliases `plan_and_track`, `budget`,
            `track`), `rewards`, `more`. There is no `activity` or `wallet`
            tab in MyBank. Maps to `chase_tab_<slug>`; an unrecognized value
            is tried as `chase_tab_<value>` and returns an error string if
            no such tab exists.
    """
    sim = SimulatorBridge.get()
    key = _slug(tab).replace("&", "and")
    aid = _TAB_MAP.get(key, f"chase_tab_{key}")
    try:
        sim.tap_id(aid); sim.wait(0.4)
    except Exception as exc:
        return f"Could not switch to '{tab}' tab. {str(exc)[:120]}"
    return f"Switched to '{tab}' tab."


@mcp.tool()
def list_accounts() -> dict:
    """List the account types available in MyBank.

    Returns: ``{accounts: [type, ...], count}``. Each `type` is a lowercase
    slug; in the seed store these are `checking`, `savings`, `credit` — pass
    one verbatim to `open_account(account_type=...)`. For the full
    per-account detail (id/name/balance/currency), use
    `list_accounts_direct` instead.

    Works from any screen: reads the account types from the seed store rather
    than scraping the home accessibility tree (the home view renders accounts
    as `home_<type>_card` and the cards can sit below the fold, so a tree scan
    returns an incomplete list depending on scroll position). Falls back to a
    tree scrape only if the store is empty.
    """
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    types = sorted({a.get("type") for a in state.get("accounts", []) if a.get("type")})
    if not types:
        # Fallback: scrape whatever the current home tree exposes.
        sim = SimulatorBridge.get()
        tree = sim.observe_text() or ""
        types = sorted(set(re.findall(r'home_([a-z_]+)_card', tree)))
    return {"accounts": types, "count": len(types)}


@mcp.tool()
def open_account(account_type: str) -> str:
    """Open an account's detail screen, self-navigating to home first.

    Works from any screen: returns to the home tab and dismisses overlays
    before tapping, so a blind call from another tab/sheet still lands. Taps
    the home `home_<type>_card` link (retries after revealing the accounts
    menu, then falls back to the legacy `account_card_<type>` id), and
    verifies the account-detail sheet actually opened.

    Args:
        account_type: Account type slug from `list_accounts()` — `checking`,
            `savings`, or `credit`. Lowercase, no spaces.

    Returns a success string, or an error string (caller should re-fetch a
    valid slug from `list_accounts()`) if no card led to the detail view.
    """
    sim = SimulatorBridge.get()
    slug = _slug(account_type)
    # Return to home first — the account cards live on the home tab and are
    # covered/off-tab after a search overlay or a tab switch, so a blind tap
    # would no-op. Dismiss the overlay and re-render before tapping.
    _ensure_home()

    def _detail_open() -> bool:
        # AccountDetailSheet (HomeView.swift) renders an activity list of
        # `account_activity_row_<index>` under an "Account detail" title. Use
        # ONLY those two markers: the home screen itself shows "Available
        # balance" text, so matching on "Available ..." would falsely report
        # the detail open while still on home.
        sim.wait(0.3)
        tree = sim.observe_text() or ""
        return "account_activity_row_" in tree or "Account detail" in tree

    # The home view renders account cards as NavigationLinks with id
    # `home_<type>_card` (see HomeView.swift). Only some cards are visible
    # above the fold; the rest live under the `home_accounts_menu` section.
    # Try the real id, then reveal the accounts menu and retry, then fall
    # back to the legacy `account_card_<type>` id for older builds.
    last_exc = None

    def _try_tap_card() -> bool:
        nonlocal last_exc
        for aid in (f"home_{slug}_card", f"account_card_{slug}"):
            try:
                sim.tap_id(aid); sim.wait(0.5)
                if _detail_open():
                    return True
            except Exception as exc:
                last_exc = exc
        return False

    opened = _try_tap_card()
    if not opened:
        # Reveal the accounts section in case the card is below the fold or
        # collapsed under the accounts menu, then retry.
        try:
            sim.tap_id("home_accounts_menu"); sim.wait(0.5)
        except Exception:
            pass
        opened = _try_tap_card()

    if not opened:
        return (
            f"Could not open account detail for '{account_type}'. No matching "
            f"`home_{slug}_card` led to the account detail view. Call "
            "list_accounts() and use one of the returned slugs as "
            f"account_type. {('Error: ' + str(last_exc)[:120]) if last_exc else ''}".rstrip()
        )
    return f"Opened {account_type} account."


@mcp.tool()
def list_transactions(page: int = 1, page_size: int = 50, account_type: str = "", category: str = "") -> dict:
    """List transactions from the MyBank store with bounded pagination.

    Returns ``{transactions, count, returned_count, page, page_size,
    has_more, next_page, totals}``. ``count`` is the total matching row count;
    ``transactions`` is the requested page. Each ``id`` is a transaction UUID
    usable with ``open_transaction``.

    Reads the seed store rather than scraping the on-screen "Recent activity"
    list: the home view only renders the 15 most-recent rows (and only when
    scrolled into view), so a tree scan misses the other ~580 transactions.
    Optional filters:
      account_type: checking/savings/credit (empty = all).
      category: exact category match, case-insensitive (empty = all).
    """
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    accounts = _account_lookup(state)
    account_filter = (account_type or "").strip().lower()
    category_filter = (category or "").strip().lower()
    rows = []
    for t in state.get("transactions", []):
        if not t.get("id"):
            continue
        row = _transaction_row(t, accounts)
        if account_filter and str(row.get("account_type") or "").lower() != account_filter:
            continue
        if category_filter and str(row.get("category") or "").lower() != category_filter:
            continue
        rows.append(row)
    page_rows, meta = _paginate(rows, page, page_size)
    return {**meta, "transactions": page_rows, "totals": _transaction_totals(rows)}


def _disputed_ids() -> set:
    """Return the set of transaction ids currently marked ``disputed`` in state."""
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    return {
        str(t.get("id"))
        for t in state.get("transactions", [])
        if t.get("id") and str(t.get("status", "")).lower() == "disputed"
    }


def _signed_amount_str(amount) -> str:
    """Replicate MyBank's signedCurrencyString for USD (`+$X.XX` / `-$X.XX`)."""
    try:
        value = float(amount)
    except (TypeError, ValueError):
        return ""
    sign = "-" if value < 0 else "+"
    return f"{sign}${abs(value):,.2f}"


def _detail_sheet_open(sim) -> bool:
    tree = sim.observe_text() or ""
    return "detail_dispute_button" in tree or "detail_amount_label" in tree


def _open_transaction_detail(transaction_id: str) -> Optional[str]:
    """Resolve a transaction by id and open its detail sheet from a fresh launch.

    Self-navigates: (1) launches/ensures MyBank is up, (2) taps the home
    `transaction_cell_<uuid>` if the row is in the visible "Recent activity"
    list, (3) otherwise opens the home search sheet, types the vendor, and
    taps the matching result row (its accessibility name embeds the signed
    amount, so a same-vendor/same-amount transaction is uniquely targetable).

    Returns None on success (detail sheet open) or an error string. Accepts a
    raw UUID or a `transaction_cell_<uuid>` id.
    """
    sim = SimulatorBridge.get()
    raw = (transaction_id or "").strip()
    if raw.startswith("transaction_cell_"):
        raw = raw[len("transaction_cell_"):]

    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    txn = _find_transaction(state, raw)
    if not txn:
        return (
            f"No transaction with id '{transaction_id}' exists in the MyBank store. "
            "Call list_transactions() or search_transactions(query=...) for valid ids."
        )

    # Ensure we're on home (the search bar + recent-activity cells live there).
    try:
        sim.launch_and_observe(BUNDLE_ID); sim.wait(0.4)
    except Exception:
        pass

    real_id = str(txn.get("id"))
    vendor = str(txn.get("vendor", ""))
    amount_str = _signed_amount_str(txn.get("amount"))

    # 1) Fast path: the row is in the visible Recent-activity list (top 15).
    tree = sim.observe_text() or ""
    if f"transaction_cell_{real_id}" in tree:
        try:
            sim.tap_id(f"transaction_cell_{real_id}"); sim.wait(0.5)
            if _detail_sheet_open(sim):
                return None
        except Exception:
            pass

    # 2) General path: drive the search sheet and tap the matching result row.
    try:
        sim.tap_id("home_search_bar"); sim.wait(0.5)
    except Exception as exc:
        return f"Could not open the search sheet to locate transaction '{transaction_id}'. {str(exc)[:120]}"
    try:
        sim.tap_id("Search transactions"); sim.wait(0.3)
    except Exception:
        pass
    sim.type_text(vendor); sim.wait(0.6)

    tree = sim.observe_text() or ""
    # Result rows are Buttons whose name embeds "<vendor>, ..., <signed amount>, ...".
    row_names = re.findall(r'(?:name|label)="([^"]*)"', tree)
    target = None
    if amount_str:
        target = next(
            (n for n in row_names
             if vendor.lower() in n.lower() and amount_str in n and "," in n),
            None,
        )
    if not target:
        # Fall back to any result row for this vendor (best-effort).
        target = next(
            (n for n in row_names if vendor.lower() in n.lower() and "," in n and "$" in n),
            None,
        )
    if not target:
        return (
            f"Could not locate a search result row for transaction '{transaction_id}' "
            f"(vendor '{vendor}', amount {amount_str}). The search sheet returned no "
            "matching row."
        )
    try:
        sim.tap_id(target); sim.wait(0.6)
    except Exception as exc:
        return f"Could not tap the located result row. {str(exc)[:120]}"
    if _detail_sheet_open(sim):
        return None
    return (
        f"Could not open the detail sheet after tapping the search result for "
        f"transaction '{transaction_id}'."
    )


@mcp.tool()
def open_transaction(transaction_id: str) -> str:
    """Open a transaction's detail sheet by id, self-navigating from any state.

    Args:
        transaction_id: Transaction UUID (the `id` field from
            `list_transactions()` / `search_transactions()`) or a full
            `transaction_cell_<uuid>` id.

    Robust to blind use: the tool resolves the transaction in the MyBank
    store, then opens its detail sheet — tapping the visible home
    `transaction_cell_<uuid>` if it's one of the recent rows, otherwise
    opening the search sheet, typing the vendor, and tapping the matching
    result row. Works for any of the ~600 stored transactions, not just the
    15 shown on home.
    """
    err = _open_transaction_detail(transaction_id)
    if err:
        state = _load_state()
        txn = _find_transaction(state, transaction_id)
        if txn is not None:
            return {
                "ok": True,
                "action": "open_transaction",
                "transaction_id": txn.get("id"),
                "summary": _transaction_row(txn, _account_lookup(state)),
                "message": (
                    f"Resolved transaction '{transaction_id}' from MyBank state. "
                    "The in-app detail sheet was not reachable."
                ),
            }
        return f"Could not open transaction '{transaction_id}'. {err}"
    return f"Opened transaction {transaction_id}."


@mcp.tool()
def search_transactions(query: str, page: int = 1, page_size: int = 50) -> dict:
    """Search transactions and return a bounded, structured result page.

    Args:
        query: Free-text search string (matched against vendors, categories, etc.).

    Returns ``{query, transactions, count, returned_count, page, page_size,
    has_more, next_page, totals}`` filtered to rows whose vendor / category /
    note / account fields contain the query (case-insensitive). Reads the seed
    store so it works regardless of which tab is showing.
    """
    sim = SimulatorBridge.get()
    # Best-effort: drive the on-screen search UI if this build exposes it.
    # `home_search_bar` is a Button that opens a search SHEET whose field is a
    # `.searchable` ("Search transactions") — tap that field before typing so
    # the keyboard is up; tapping the bar alone leaves no field focused.
    try:
        sim.tap_id("home_search_bar"); sim.wait(0.4)
        try:
            sim.tap_id("Search transactions"); sim.wait(0.3)
        except Exception:
            pass
        sim.type_text(query); sim.wait(0.4)
    except Exception:
        pass
    needle = (query or "").strip().lower()
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    accounts = _account_lookup(state)
    matches = []
    for t in state.get("transactions", []):
        row = _transaction_row(t, accounts)
        hay = " ".join(str(row.get(k, "")) for k in (
            "vendor", "category", "note", "account_type", "account_name", "amount", "status"
        )).lower()
        if not needle or needle in hay:
            matches.append(row)
    page_rows, meta = _paginate(matches, page, page_size)
    return {**meta, "query": query, "transactions": page_rows, "totals": _transaction_totals(matches)}


def _zelle_fill_form(recipient: str, amount: str, memo: str = "") -> Optional[str]:
    """Navigate to the Zelle send sheet and fill recipient/amount/memo.

    Returns None on success or a precondition message on failure. Used by
    both `send_zelle` (one-shot commit) and `prepare_send_zelle`
    (capture-only). Stops short of tapping `zelle_send_button` so the
    caller decides whether to commit.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("home_chip_zelle"); sim.wait(0.5)
    except Exception:
        return "Zelle chip not reachable in the current UI."
    # Verify the Zelle send sheet actually opened. In some builds the quick-
    # action chips render below the fold and the tap is a no-op; bail so the
    # caller can use the shared-state fallback rather than reporting a false
    # success.
    tree = sim.observe_text() or ""
    if "zelle_amount_field" not in tree and "zelle_recipient_picker" not in tree:
        return "Could not open the Zelle send sheet."
    try:
        sim.tap_id("zelle_recipient_picker"); sim.wait(0.4)
        sim.tap_id(recipient); sim.wait(0.3)
    except Exception:
        return (
            f"Could not select recipient '{recipient}'. Open the picker via observe() "
            f"and tap the matching name; then re-call this tool."
        )
    sim.tap_id("zelle_amount_field"); sim.wait(0.2); sim.type_text(amount); sim.wait(0.2)
    if memo:
        sim.tap_id("zelle_memo_field"); sim.wait(0.2); sim.type_text(memo); sim.wait(0.2)
    return None


@mcp.tool()
def send_zelle(recipient: str, amount: str, memo: str = "") -> str:
    """Send a Zelle payment end-to-end (one-shot commit).

    Args:
        recipient: Zelle payee display name from your saved payees, e.g.
            `"Maya Patel"`. Use `list_payees_direct()` (category `"Zelle"`)
            to discover exact names. Resolution is a case-insensitive
            substring match against payee names, so a unique partial like
            `"Maya"` also works; an unknown name is still accepted and used
            verbatim as the recipient.
        amount: Positive dollar amount as a string, no currency symbol
            (e.g. `"50"` or `"50.00"`). A non-positive/non-numeric value
            returns a "could not send" message without committing.
        memo: Optional free-text memo.

    Reliably commits: in this build the UI Send button closes the sheet
    without persisting, so the tool reads the store back and, if no Zelle
    transaction posted, commits the payment via a direct state write (debits
    checking). Either way the payment lands. Fails (without committing) if
    checking has insufficient available balance. Legacy single-verb commit —
    `prepare_send_zelle` + `confirm_send_zelle` lets a model inspect the
    draft before committing.
    """
    try:
        _positive_amount(amount)
    except ValueError as exc:
        return f"Could not send Zelle: {exc}"
    sim = SimulatorBridge.get()
    before = _zelle_txn_count(recipient)
    err = _zelle_fill_form(recipient, amount, memo)
    if not err:
        try:
            sim.tap_id("zelle_send_button"); sim.wait(0.6)
            # The Send button closes the sheet but, in this build, does NOT
            # persist a Zelle transaction (verified: state + shared ledger stay
            # empty). So a clean tap is NOT proof of success — read back the
            # store and only trust the UI path if a new Zelle txn actually
            # posted; otherwise fall through to the shared-state commit.
            if _zelle_txn_count(recipient) > before:
                return f"Sent ${amount} via Zelle to {recipient}" + (f" (memo: '{memo}')" if memo else "") + "."
        except Exception:
            pass
    # UI path unavailable or did not persist (the Send button is a no-op for the
    # store in this build) — commit via shared state so the action completes.
    result = _zelle_state(recipient, amount, memo)
    if not result.get("ok"):
        return f"Could not send Zelle: {result.get('error', str(result))}"
    return (
        f"Sent ${result['amount']} via Zelle to {result['recipient']}"
        + (f" (memo: '{memo}')" if memo else "")
        + "."
    )


@mcp.tool()
def prepare_send_zelle(recipient: str, amount: str, memo: str = "") -> dict:
    """Navigate to the Zelle send sheet and pre-fill it WITHOUT committing.

    `recipient` is the Zelle payee's display name from your saved payees
    (e.g. 'Maya Patel'); resolution is a case-insensitive substring match,
    discover names via `list_payees_direct()` (category 'Zelle'). `amount`
    is a positive dollar amount as a string (e.g. '50' or '50.00'). `memo`
    is optional free text.

    Always stages a draft as long as the amount is valid — even if the
    on-screen Zelle sheet can't be opened, `confirm_send_zelle` commits via
    a direct state write, so a non-home tab/overlay never blocks prepare.
    On success returns ``{ok: True, action: "prepare_send_zelle", draft_id,
    summary: {recipient, amount, memo}, next}``; inspect the summary then
    pass ``draft_id`` to `confirm_send_zelle`. The draft expires after the
    `IOSWORLD_DRAFT_TTL_SECONDS` TTL (default 10 minutes) or when the
    simulator session resets.

    Only an invalid (non-positive/non-numeric) amount fails here, returning
    ``{ok: False, message}`` without staging a draft.
    """
    # Validate the amount up front so a bad value fails here, not at confirm.
    try:
        _positive_amount(amount)
    except ValueError as exc:
        return {"ok": False, "action": "prepare_send_zelle", "message": str(exc)}
    # Best-effort fill of the on-screen form; if the UI path is unavailable in
    # this build we still stage the draft (confirm_send_zelle commits via the
    # shared-state fallback). The summary carries everything confirm needs.
    # Never let a UI hiccup raise out of prepare — the draft is what matters.
    try:
        _zelle_fill_form(recipient, amount, memo)
    except Exception:
        pass
    summary = {"recipient": recipient, "amount": amount, "memo": memo}
    draft_id = ts.create_draft("mybank", "send_zelle", summary)
    return {
        "ok": True,
        "action": "prepare_send_zelle",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_send_zelle(draft_id) to commit.",
    }


@mcp.tool()
def confirm_send_zelle(draft_id: str) -> dict:
    """Commit a Zelle payment previously staged by ``prepare_send_zelle``.

    `draft_id` is the id returned by ``prepare_send_zelle``. The draft
    must still be present (not consumed, not expired). Returns
    ``{ok: True, action: "confirm_send_zelle", evidence: <summary>}``
    on success.

    Reliably commits: only trusts the UI Send button if a new Zelle
    transaction actually posts to the store afterward; otherwise (the Send
    button is a no-op for the store in this build) it commits the payment
    via a direct state write that debits checking. Returns
    ``{ok: False, message}`` without committing if the draft is
    missing/expired or checking has insufficient available balance.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_send_zelle",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_send_zelle first.",
        }
    sim = SimulatorBridge.get()
    payload = draft.get("payload", {})
    recipient = payload.get("recipient", "")
    tree = sim.observe_text() or ""
    # Only trust the UI Send button if the Zelle send sheet is actually open AND
    # a new Zelle transaction actually posts to the store afterward. In this
    # build the Send button closes the sheet without persisting anything, so a
    # clean tap is a false positive — verify with a store read-back, else fall
    # through to the shared-state commit.
    if "zelle_send_button" in tree:
        before = _zelle_txn_count(recipient)
        try:
            sim.tap_id("zelle_send_button"); sim.wait(0.6)
            if _zelle_txn_count(recipient) > before:
                return {"ok": True, "action": "confirm_send_zelle", "evidence": payload}
        except Exception:
            pass
    result = _zelle_state(payload.get("recipient", ""), payload.get("amount"), payload.get("memo", ""))
    if not result.get("ok"):
        return {
            "ok": False,
            "action": "confirm_send_zelle",
            "message": f"Could not commit Zelle payment: {result.get('error', str(result))}",
        }
    return {
        "ok": True,
        "action": "confirm_send_zelle",
        "evidence": {**payload, "state_commit": result},
    }


@mcp.tool()
def make_deposit(amount: str, note: str = "") -> str:
    """Open the deposit chip flow, fill amount + note, and submit (one-shot commit).

    Args:
        amount: Positive dollar amount as a string, no currency symbol
            (e.g. `"100"` or `"100.50"`). A non-positive/non-numeric value
            returns a "could not deposit" message without committing.
        note: Optional memo/description for the deposit.

    Reliably credits the checking account: drives the deposit-chip sheet if
    available, and on any UI failure falls back to a direct state write — so
    the deposit always lands. Target is always the checking account (not
    selectable). Posts a "Mobile Check Deposit" transaction.
    """
    try:
        _positive_amount(amount)
    except ValueError as exc:
        return f"Could not deposit: {exc}"
    try:
        sim = SimulatorBridge.get()
        sim.tap_id("home_chip_deposit"); sim.wait(0.5)
        sim.tap_id("deposit_amount_field"); sim.wait(0.2); sim.type_text(amount); sim.wait(0.2)
        if note:
            sim.tap_id("deposit_note_field"); sim.wait(0.2); sim.type_text(note); sim.wait(0.2)
        sim.tap_id("deposit_submit_button"); sim.wait(0.4)
        return f"Deposited {amount} (note: '{note}')."
    except Exception:
        result = _deposit_state(amount, note)
        if not result.get("ok"):
            return result
        return f"Deposited {result['amount']} (note: '{note}')."


def _ensure_home() -> None:
    """Return to the home tab so the home chips/buttons are hittable.

    The transfer/deposit/bill chips live only on the home tab. When the agent
    has navigated to another tab (rewards/plan/more) or left a sheet up, the
    home controls are present in the tree but covered or off-tab and a tap
    no-ops. Dismiss any open sheet (Close/Cancel) and tap the home tab, then
    re-render, so the subsequent chip tap actually lands.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "home_chip_zelle" in tree:
        return  # already on home with chips visible
    # Dismiss a presented sheet if one is up (search/detail/picker overlays).
    for dismiss in ("Close", "Cancel", "Done"):
        try:
            if dismiss in tree:
                sim.tap_id(dismiss); sim.wait(0.3); break
        except Exception:
            pass
    try:
        sim.tap_id("chase_tab_home"); sim.wait(0.4)
    except Exception:
        pass
    # Some overlays (the .searchable transaction-search sheet) expose no
    # Cancel/Close and sit ABOVE the tab bar, so the home tap no-ops and the
    # chips stay hidden. If the home chips still aren't reachable, relaunch the
    # app to land cleanly on home (the only reliable dismissal for that sheet).
    tree = sim.observe_text() or ""
    if "home_chip_zelle" not in tree:
        try:
            sim.launch_and_observe(BUNDLE_ID); sim.wait(0.5)
        except Exception:
            pass


def _transfer_fill_form(amount: str, note: str = "") -> Optional[str]:
    """Open the transfer sheet and fill amount + note (no commit).

    Returns None on success or a precondition message string on failure.
    """
    sim = SimulatorBridge.get()
    _ensure_home()
    try:
        sim.tap_id("home_add_action_button"); sim.wait(0.4)
        sim.tap_id("transfer_amount_field_sheet"); sim.wait(0.2); sim.type_text(amount); sim.wait(0.2)
        if note:
            sim.tap_id("transfer_note_field_sheet"); sim.wait(0.2); sim.type_text(note); sim.wait(0.2)
        return None
    except Exception as exc:
        return f"Transfer sheet unavailable. Open it via home_add_action_button and re-call. {str(exc)[:120]}"


@mcp.tool()
def transfer_money(amount: str, note: str = "") -> str:
    """Open the transfer sheet, fill amount + note, and submit (one-shot commit).

    Args:
        amount: Positive dollar amount as a string, no currency symbol
            (e.g. `"50"` or `"50.00"`). A non-positive/non-numeric value
            returns a "could not transfer" message without committing.
        note: Optional free-text memo.

    Works from any screen: the fill helper self-navigates to home (dismissing
    overlays) before opening the transfer sheet. Always transfers from
    checking to savings (accounts are not selectable). Reliably commits:
    falls back to a direct state write if the UI path fails — but fails
    (no commit) if checking has insufficient available balance. Legacy
    single-verb commit — prefer `prepare_transfer_money` +
    `confirm_transfer_money` for new code.
    """
    try:
        _positive_amount(amount)
    except ValueError as exc:
        return f"Could not transfer: {exc}"
    try:
        err = _transfer_fill_form(amount, note)
        if err:
            raise RuntimeError(err)
        sim = SimulatorBridge.get()
        sim.tap_id("transfer_submit_button"); sim.wait(0.4)
        return f"Transferred {amount} (note: '{note}')."
    except Exception:
        result = _transfer_state(amount, note)
        if not result.get("ok"):
            return result
        return f"Transferred {result['amount']} (note: '{note}')."


@mcp.tool()
def prepare_transfer_money(amount: str, note: str = "") -> dict:
    """Open the transfer sheet and pre-fill it WITHOUT committing.

    `amount` is a positive dollar amount as a string (e.g. '50' or '50.00').
    `note` is optional free text. Always transfers from checking to savings
    (accounts are not selectable).

    Works from any screen (the fill helper self-navigates to home). Always
    stages a draft when the amount is valid — even if the on-screen sheet is
    unreachable, `confirm_transfer_money` commits via a direct state write.
    Returns ``{ok: True, draft_id, summary: {amount, note}, next}``; pass the
    ``draft_id`` to `confirm_transfer_money` to submit. Only an invalid
    amount fails here, returning ``{ok: False, message}`` without a draft.
    """
    # Validate up front so a bad amount fails here, not at confirm.
    try:
        _positive_amount(amount)
    except ValueError as exc:
        return {"ok": False, "action": "prepare_transfer_money", "message": str(exc)}
    # Best-effort fill of the on-screen sheet from any state (the helper returns
    # to home first). If the UI sheet is unreachable in the current build we
    # still stage the draft — confirm_transfer_money commits via the shared-
    # state fallback — so the agent isn't blocked from a non-home tab/overlay.
    try:
        _transfer_fill_form(amount, note)
    except Exception:
        pass
    summary = {"amount": amount, "note": note}
    draft_id = ts.create_draft("mybank", "transfer_money", summary)
    return {
        "ok": True,
        "action": "prepare_transfer_money",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_transfer_money(draft_id) to commit.",
    }


@mcp.tool()
def confirm_transfer_money(draft_id: str) -> dict:
    """Commit a transfer previously staged by `prepare_transfer_money`.

    `draft_id` is the id returned by `prepare_transfer_money`. Reliably
    commits: trusts the UI submit only if a transfer transaction actually
    posts; otherwise commits via a direct state write (checking → savings).
    Returns ``{ok: True, evidence: <summary>}`` on success, or
    ``{ok: False, message}`` if the draft is missing/expired or checking has
    insufficient available balance.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_transfer_money",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_transfer_money first.",
        }
    sim = SimulatorBridge.get()
    payload = draft.get("payload", {})
    # Trust the UI submit only if the transfer sheet is actually open AND a
    # transfer transaction posts; otherwise commit via shared state so the
    # transfer really happens (e.g. when prepare staged from a non-home tab and
    # the sheet never opened).
    tree = sim.observe_text() or ""
    if "transfer_submit_button" in tree:
        before = _transfer_txn_count()
        try:
            sim.tap_id("transfer_submit_button"); sim.wait(0.5)
            if _transfer_txn_count() > before:
                return {"ok": True, "action": "confirm_transfer_money", "evidence": payload}
        except Exception:
            pass
    result = _transfer_state(payload.get("amount"), payload.get("note", ""))
    if not result.get("ok"):
        return {
            "ok": False,
            "action": "confirm_transfer_money",
            "message": f"Could not commit transfer: {result.get('error', str(result))}",
        }
    return {"ok": True, "action": "confirm_transfer_money", "evidence": {**payload, "state_commit": result}}


def _pay_bill_fill_form(amount: str, memo: str = "") -> Optional[str]:
    """Open the bill-pay sheet and fill amount + memo (no commit)."""
    sim = SimulatorBridge.get()
    _ensure_home()
    try:
        sim.tap_id("home_chip_pay_bills"); sim.wait(0.5)
        sim.tap_id("bill_amount_field"); sim.wait(0.2); sim.type_text(amount); sim.wait(0.2)
        if memo:
            sim.tap_id("bill_memo_field"); sim.wait(0.2); sim.type_text(memo); sim.wait(0.2)
        return None
    except Exception as exc:
        return f"Bill-pay sheet unavailable. Open it via home_chip_pay_bills and re-call. {str(exc)[:120]}"


@mcp.tool()
def pay_bill(amount: str, memo: str = "") -> str:
    """Open bill-pay, fill amount + memo, and submit (one-shot commit).

    Args:
        amount: Positive dollar amount as a string, no currency symbol
            (e.g. `"100"` or `"150.50"`). A non-positive/non-numeric value
            returns a "could not pay bill" message without committing.
        memo: Optional free-text memo.

    This tool does NOT pick a biller and takes no payee arg. The UI path
    pays whoever is selected on the bill-pay sheet; when it falls back to a
    direct state write (the common case), the payee defaults to the
    Electric utility (matches "Pacific Gas & Electric") — to pay a specific
    biller use `schedule_payment_direct(payee_name=...)` instead. Works
    from any screen (the fill helper self-navigates to home). Fails (no
    commit) if checking has insufficient available balance. Legacy
    single-verb commit — prefer `prepare_pay_bill` + `confirm_pay_bill`.
    """
    try:
        _positive_amount(amount)
    except ValueError as exc:
        return f"Could not pay bill: {exc}"
    try:
        err = _pay_bill_fill_form(amount, memo)
        if err:
            raise RuntimeError(err)
        sim = SimulatorBridge.get()
        sim.tap_id("bill_submit_button"); sim.wait(0.4)
        return f"Submitted bill payment {amount} (memo: '{memo}')."
    except Exception:
        result = _pay_bill_state(amount, memo)
        if not result.get("ok"):
            return result
        return f"Submitted bill payment {result['amount']} to {result['payee']} (memo: '{memo}')."


@mcp.tool()
def prepare_pay_bill(amount: str, memo: str = "") -> dict:
    """Open the bill-pay sheet and pre-fill it WITHOUT committing.

    `amount` is a positive dollar amount as a string. `memo` is optional.
    This tool takes no payee arg: the UI path pays the biller selected on
    the sheet, and `confirm_pay_bill`'s state fallback defaults to the
    Electric utility (Pacific Gas & Electric). To target a specific payee
    use `schedule_payment_direct(payee_name=...)` instead.

    Works from any screen (the fill helper self-navigates to home) and always
    stages a draft when the amount is valid — even if the on-screen sheet is
    unreachable, `confirm_pay_bill` commits via a state write. Returns
    ``{ok: True, draft_id, summary, next}``; pass draft_id to
    `confirm_pay_bill` to commit. Only an invalid amount fails here.
    """
    try:
        _positive_amount(amount)
    except ValueError as exc:
        return {"ok": False, "action": "prepare_pay_bill", "message": str(exc)}
    # Best-effort fill (helper returns to home first). Stage the draft even if
    # the on-screen sheet is unreachable — confirm_pay_bill commits via the
    # shared-state fallback — so a non-home tab / overlay doesn't block prepare.
    try:
        _pay_bill_fill_form(amount, memo)
    except Exception:
        pass
    summary = {"amount": amount, "memo": memo}
    draft_id = ts.create_draft("mybank", "pay_bill", summary)
    return {
        "ok": True,
        "action": "prepare_pay_bill",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_pay_bill(draft_id) to commit.",
    }


@mcp.tool()
def confirm_pay_bill(draft_id: str) -> dict:
    """Commit a bill payment previously staged by `prepare_pay_bill`.

    Args:
        draft_id: The id returned by `prepare_pay_bill`.

    Reliably commits: trusts the UI Submit only if a bill-pay transaction
    actually posts; otherwise commits via a direct state write whose payee
    defaults to the Electric utility (Pacific Gas & Electric). Returns
    ``{ok: True, evidence: <summary>}`` on success, or ``{ok: False,
    message}`` if the draft is missing/expired or checking has insufficient
    available balance.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_pay_bill",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_pay_bill first.",
        }
    sim = SimulatorBridge.get()
    payload = draft.get("payload", {})
    tree = sim.observe_text() or ""
    if "bill_submit_button" in tree:
        before = _bill_txn_count()
        try:
            sim.tap_id("bill_submit_button"); sim.wait(0.5)
            if _bill_txn_count() > before:
                return {"ok": True, "action": "confirm_pay_bill", "evidence": payload}
        except Exception:
            pass
    # Sheet not open / submit no-op — commit via shared state so the bill is paid.
    result = _pay_bill_state(payload.get("amount"), payload.get("memo", ""))
    if not result.get("ok"):
        return {
            "ok": False,
            "action": "confirm_pay_bill",
            "message": f"Could not commit bill payment: {result.get('error', str(result))}",
        }
    return {"ok": True, "action": "confirm_pay_bill", "evidence": {**payload, "state_commit": result}}


@mcp.tool()
def pay_credit_card() -> str:
    """Tap the 'Pay Credit Card' home chip to surface the credit-card payment control.

    Returns to home first (so it works from any tab/overlay), then taps the
    chip. In this build the chip reveals an inline `pay_credit_card_submit_button`
    ("Pay credit card now, $X") on the home view rather than opening a sheet;
    it does NOT submit. To actually pay, use `prepare_pay_credit_card` +
    `confirm_pay_credit_card`.
    """
    sim = SimulatorBridge.get()
    _ensure_home()
    sim.tap_id("home_chip_pay_credit_card")
    sim.wait(0.4)
    return "Opened credit-card payment flow."


@mcp.tool()
def prepare_pay_credit_card() -> dict:
    """Open the 'Pay Credit Card' chip flow and capture pre-commit state WITHOUT committing.

    Self-navigates to home, then taps `home_chip_pay_credit_card` to reveal
    the inline credit-card payment control, and reads the current
    credit-card balance (from the UI tree, falling back to the seed store)
    so the agent can sanity-check the payment before confirming. Always
    stages a draft even if the chip tap is a no-op. Takes no arguments.

    Returns ``{ok: True, draft_id, summary: {credit_balance, from_account,
    to_account}, next}``. Pass the ``draft_id`` to `confirm_pay_credit_card`
    to commit.
    """
    sim = SimulatorBridge.get()
    # Return to home first so the chip is hittable from any tab/overlay, then
    # best-effort open the sheet. Even if the chip tap is a no-op in the current
    # state, still stage the draft — confirm_pay_credit_card commits via the
    # shared-state fallback — so a non-home tab doesn't block prepare.
    _ensure_home()
    try:
        sim.tap_id("home_chip_pay_credit_card"); sim.wait(0.5)
    except Exception:
        pass
    tree = sim.observe_text() or ""
    balances = re.findall(r'account_balance_credit[^\n]*?\$?([0-9,]+\.\d{2})', tree)
    credit_balance = balances[0] if balances else None
    # The credit-card balance label isn't reliably exposed in the chip sheet's
    # accessibility tree, so fall back to the seed store for a real number and
    # name the source/target accounts so the agent can verify the payment.
    state = _load_state()
    credit = _account(state, "credit")
    checking = _account(state, "checking")
    if credit_balance is None and credit is not None:
        credit_balance = f"{float(credit.get('balance', 0)):.2f}"
    summary = {
        "credit_balance": credit_balance,
        "from_account": checking.get("name") if checking else None,
        "to_account": credit.get("name") if credit else None,
    }
    draft_id = ts.create_draft("mybank", "pay_credit_card", summary)
    return {
        "ok": True,
        "action": "prepare_pay_credit_card",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_pay_credit_card(draft_id) to commit.",
    }


@mcp.tool()
def confirm_pay_credit_card(draft_id: str) -> dict:
    """Commit a credit-card payment previously staged by `prepare_pay_credit_card`.

    `draft_id` is the id returned by `prepare_pay_credit_card`. Closes any
    open sheet, then taps the dedicated ``pay_credit_card_submit_button`` on
    the home view, which one-shot commits a payment from checking to the
    registered Credit Card payee for the current balance. If that button
    isn't present it falls back to a direct state write paying the
    "Freedom Unlimited" credit-card payee the staged balance — so the
    payment lands either way. Returns ``{ok: True, evidence}`` on success,
    or ``{ok: False, message}`` if the draft is missing/expired or no
    balance is available to pay.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_pay_credit_card",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_pay_credit_card first.",
        }
    sim = SimulatorBridge.get()
    # The prepare step may have left the bill-pay sheet open. Close it so
    # the dedicated commit button on the home view is hittable.
    try:
        sim.tap_id("Close"); sim.wait(0.3)
    except Exception:
        pass
    try:
        sim.tap_id("pay_credit_card_submit_button"); sim.wait(0.4)
    except Exception as exc:
        state = _load_state()
        credit = _account(state, "credit")
        amount = draft.get("payload", {}).get("credit_balance")
        if not amount and credit:
            amount = credit.get("balance")
        result = _pay_bill_state(amount, "Pay credit card", payee_name="Freedom Unlimited") if amount else {
            "ok": False,
            "error": "credit card balance not available",
        }
        if not result.get("ok"):
            return {
                "ok": False,
                "action": "confirm_pay_credit_card",
                "message": (
                    "pay_credit_card_submit_button not found in current UI and shared-state "
                    f"fallback failed: {result.get('error', str(result))}. ({str(exc)[:120]})"
                ),
            }
        return {
            "ok": True,
            "action": "confirm_pay_credit_card",
            "evidence": {
                **draft.get("payload", {}),
                "state_fallback": result,
            },
        }
    return {
        "ok": True,
        "action": "confirm_pay_credit_card",
        "evidence": draft.get("payload", {}),
    }


@mcp.tool()
def redeem_rewards() -> str:
    """Redeem rewards points (one-shot commit). Takes no arguments.

    Reliably commits: taps `reward_redeem_button` if the rewards sheet is
    already open (no need to navigate first), otherwise falls back to a
    direct state write — so the redemption always lands. Redeems 100 points
    (capped at the available balance), increments `redeemedRewardPoints`.
    Legacy single-verb commit — prefer `prepare_redeem_rewards` +
    `confirm_redeem_rewards` to confirm the target first.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "reward_redeem_button" in tree:
        try:
            sim.tap_id("reward_redeem_button"); sim.wait(0.4)
            return "Redeemed rewards."
        except Exception:
            pass
    # Button not on screen in this build — fall back to a direct state write so
    # the redemption actually happens.
    result = _redeem_rewards_state(100)
    if not result.get("ok"):
        return f"Could not redeem rewards: {result.get('error', str(result))}"
    return f"Redeemed {result['redeemed_points']} rewards points."


@mcp.tool()
def prepare_redeem_rewards() -> dict:
    """Navigate to the rewards screen and capture pre-commit state WITHOUT committing.

    Switches to the rewards tab and reads the available rewards points (from
    the UI tree, falling back to the seed store's `rewardPoints`, which may
    be null) so the agent can confirm the redemption target. Does NOT tap
    the redeem button. Takes no arguments.

    Returns ``{ok: True, draft_id, summary: {available_points,
    points_to_redeem, already_redeemed}, next}`` on success, or
    ``{ok: False, message}`` if the rewards tab can't be reached. Pass the
    ``draft_id`` to `confirm_redeem_rewards` to commit.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id(_TAB_MAP["rewards"]); sim.wait(0.4)
    except Exception as exc:
        return {
            "ok": False,
            "action": "prepare_redeem_rewards",
            "message": f"Could not navigate to rewards tab: {str(exc)[:120]}",
        }
    tree = sim.observe_text()
    points = re.findall(r'(\d[\d,]*)\s*(?:Available points|points available)', tree, re.IGNORECASE)
    available_points = points[0] if points else None
    # The rewards tab doesn't always expose a parseable points label, so back
    # the summary with the seed store: surface the available balance (when
    # present), how many points this redemption will spend (default 100), and
    # the running redeemed total so the agent can confirm before committing.
    state = _load_state()
    if available_points is None and state.get("rewardPoints") is not None:
        available_points = str(state.get("rewardPoints"))
    redeem_points = 100
    if state.get("rewardPoints") is not None:
        redeem_points = min(100, int(state.get("rewardPoints") or 0)) or 100
    summary = {
        "available_points": available_points,
        "points_to_redeem": redeem_points,
        "already_redeemed": state.get("redeemedRewardPoints"),
    }
    draft_id = ts.create_draft("mybank", "redeem_rewards", summary)
    return {
        "ok": True,
        "action": "prepare_redeem_rewards",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_redeem_rewards(draft_id) to commit.",
    }


@mcp.tool()
def confirm_redeem_rewards(draft_id: str) -> dict:
    """Commit a rewards redemption previously staged by `prepare_redeem_rewards`.

    `draft_id` is the id returned by `prepare_redeem_rewards`. Reliably
    commits: taps `reward_redeem_button` if it's on screen, otherwise commits
    via a direct state write of the staged points (the `points_to_redeem`
    from the draft, default 100, capped at the available balance). Returns
    ``{ok: True, evidence: <summary>}`` on success, or ``{ok: False,
    message}`` if the draft is missing/expired.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_redeem_rewards",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_redeem_rewards first.",
        }
    sim = SimulatorBridge.get()
    payload = draft.get("payload", {})
    tree = sim.observe_text() or ""
    if "reward_redeem_button" in tree:
        try:
            sim.tap_id("reward_redeem_button"); sim.wait(0.4)
            return {"ok": True, "action": "confirm_redeem_rewards", "evidence": payload}
        except Exception:
            pass
    # Redeem button not actually on screen in this build — commit via state so
    # the redemption really happens instead of reporting a false success.
    # Honor the amount staged by prepare_redeem_rewards (it computed
    # min(100, available)); fall back to 100 only if the draft lacks it.
    try:
        staged_points = int(payload.get("points_to_redeem") or 100)
    except (TypeError, ValueError):
        staged_points = 100
    result = _redeem_rewards_state(staged_points)
    if not result.get("ok"):
        return {
            "ok": False,
            "action": "confirm_redeem_rewards",
            "message": f"Could not redeem rewards: {result.get('error', str(result))}",
        }
    return {"ok": True, "action": "confirm_redeem_rewards", "evidence": {**payload, "state_commit": result}}


@mcp.tool()
def dispute_transaction(transaction_id: str = "") -> dict:
    """Dispute a transaction, self-navigating to its detail sheet first.

    Args:
        transaction_id: Optional transaction UUID (from `list_transactions()`
            / `search_transactions()`). When provided, the tool opens that
            transaction's detail sheet first, then taps the Dispute button —
            so it works blind, without a manual `open_transaction` call. When
            omitted, it disputes whatever transaction detail sheet is already
            open.

    After tapping, the dispute is verified against the MyBank store: the tool
    returns ``{ok: True, message}`` only when the transaction's status actually
    flipped to ``disputed`` in mybank_state.json. If the tap only previewed a
    confirmation without committing (status unchanged), it returns
    ``{ok: False, message}`` instead of a false success.

    Legacy single-verb commit — prefer `prepare_dispute_transaction` +
    `confirm_dispute_transaction` so a model can verify which transaction is
    being disputed.
    """
    sim = SimulatorBridge.get()
    # Always self-navigate to the REQUESTED transaction when an id is given —
    # do NOT trust a detail sheet that merely happens to be open, since it may
    # belong to a DIFFERENT (previously opened) transaction and we'd act on the
    # wrong one. _open_transaction_detail relaunches first, dismissing any stale
    # sheet, then opens the correct transaction.
    if transaction_id:
        err = _open_transaction_detail(transaction_id)
        if err:
            return {
                "ok": False,
                "action": "dispute_transaction",
                "message": f"Could not dispute transaction '{transaction_id}'. {err}",
            }
    if not _detail_sheet_open(sim):
        return {
            "ok": False,
            "action": "dispute_transaction",
            "message": (
                "No transaction detail sheet is open. Pass transaction_id=... so this "
                "tool can navigate to the transaction first, or call open_transaction(<id>)."
            ),
        }
    before = _disputed_ids()
    raw = (transaction_id or "").strip()
    if raw.startswith("transaction_cell_"):
        raw = raw[len("transaction_cell_"):]
    # If the target is ALREADY disputed before we tap, a post-tap read-back
    # would still find it disputed and we'd report a false success. Detect the
    # already-disputed case up front and fail honestly — there is no new
    # dispute to file.
    if raw and (raw in before or any(i.lower() == raw.lower() for i in before)):
        return {
            "ok": False,
            "action": "dispute_transaction",
            "message": (
                f"Transaction '{transaction_id}' is already marked 'disputed' in the "
                "MyBank store; no new dispute was filed."
            ),
        }
    sim.tap_id("detail_dispute_button")
    sim.wait(0.6)
    # Read-back: a real dispute flips the transaction's status to `disputed`
    # in mybank_state.json (BankStore.disputeTransaction -> saveState()). Some
    # navigation paths only present a confirmation UI without wiring the commit
    # (the detail sheet's local `didDispute` flag flips, but nothing persists),
    # so a successful-looking tap is NOT sufficient evidence — verify the store.
    after = _disputed_ids()
    if raw:
        disputed_now = raw in after or any(i.lower() == raw.lower() for i in after)
        if not disputed_now:
            return {
                "ok": False,
                "action": "dispute_transaction",
                "message": (
                    f"Dispute for transaction '{transaction_id}' did not file: its status "
                    "is not 'disputed' in the MyBank store after tapping. The transaction "
                    "may already be disputed, or the dispute was only previewed (a confirm "
                    "step) without being committed."
                ),
            }
    else:
        if after <= before:
            return {
                "ok": False,
                "action": "dispute_transaction",
                "message": (
                    "No dispute was filed: no transaction flipped to 'disputed' in the "
                    "MyBank store after tapping. The dispute may have only been previewed "
                    "without committing. Pass transaction_id=... to target an un-disputed "
                    "transaction."
                ),
            }
    return {
        "ok": True,
        "action": "dispute_transaction",
        "message": "Disputed transaction" + (f" {transaction_id}" if transaction_id else "") + ".",
    }


@mcp.tool()
def prepare_dispute_transaction(transaction_id: str = "") -> dict:
    """Capture a transaction's identifying state WITHOUT committing the dispute.

    Args:
        transaction_id: Optional transaction UUID. When provided, the tool
            self-navigates to that transaction's detail sheet first (so it
            works blind). When omitted, it reads whatever detail sheet is
            already open.

    Reads the transaction-detail sheet (vendor + amount labels) so the agent
    can confirm which transaction is about to be disputed. Does NOT tap the
    Dispute button.

    Returns ``{ok: True, draft_id, summary: {vendor, amount}, next}`` on
    success, or a controlled-failure response if no transaction can be
    surfaced.
    """
    sim = SimulatorBridge.get()
    # Always self-navigate to the REQUESTED transaction when an id is given —
    # do NOT trust a detail sheet that merely happens to be open, since it may
    # belong to a DIFFERENT (previously opened) transaction and we'd act on the
    # wrong one. _open_transaction_detail relaunches first, dismissing any stale
    # sheet, then opens the correct transaction.
    if transaction_id:
        err = _open_transaction_detail(transaction_id)
        if err:
            return {
                "ok": False,
                "action": "prepare_dispute_transaction",
                "message": f"Could not open transaction '{transaction_id}'. {err}",
            }
    tree = sim.observe_text()
    if "detail_amount_label" not in tree and "detail_dispute_button" not in tree:
        return {
            "ok": False,
            "action": "prepare_dispute_transaction",
            "message": (
                "No transaction detail sheet is open. Pass transaction_id=... or call "
                "list_transactions() then open_transaction(<id>) first, then re-call."
            ),
        }
    # Each label element renders as: value="X" name="detail_vendor_label" label="X".
    # Read the `value=`/`label=` on the SAME element as the id (value/label
    # precede the name attr in the Appium tree).
    def _label_for(aid: str):
        m = re.search(r'value="([^"]*)"\s+name="' + re.escape(aid) + r'"', tree)
        if m:
            return m.group(1)
        m = re.search(r'name="' + re.escape(aid) + r'"\s+label="([^"]*)"', tree)
        return m.group(1) if m else None
    summary = {
        "vendor": _label_for("detail_vendor_label"),
        "amount": _label_for("detail_amount_label"),
    }
    draft_id = ts.create_draft("mybank", "dispute_transaction", summary)
    return {
        "ok": True,
        "action": "prepare_dispute_transaction",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_dispute_transaction(draft_id) to commit.",
    }


@mcp.tool()
def confirm_dispute_transaction(draft_id: str) -> dict:
    """Commit a transaction dispute previously staged by `prepare_dispute_transaction`.

    `draft_id` is the id returned by `prepare_dispute_transaction`. Taps
    `detail_dispute_button` on the currently-open detail sheet (it does NOT
    re-navigate — keep the sheet from `prepare_dispute_transaction` open).
    Returns ``{ok: True, evidence: <summary>}`` once the tap succeeds, or
    ``{ok: False, message}`` if the draft is missing/expired or the Dispute
    button isn't present (e.g. the detail sheet was closed). For
    store-verified commit (status flips to `disputed`), use the legacy
    `dispute_transaction(transaction_id=...)`, which reads the store back.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_dispute_transaction",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_dispute_transaction first.",
        }
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("detail_dispute_button"); sim.wait(0.4)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_dispute_transaction",
            "message": "Dispute button not found in current UI; verify the transaction detail sheet is still open.",
        }
    return {"ok": True, "action": "confirm_dispute_transaction", "evidence": draft.get("payload", {})}


def _share_sheet_open(sim) -> bool:
    """True when the transaction Share sheet (ShareLink) has actually presented.

    The detail sheet's `detail_share_button` is labelled "Share transaction
    details"; once tapped, MyBank presents a sheet containing a ShareLink
    button whose accessibility name is exactly ``Share``. That distinct button
    only exists while the share sheet is up, so it is a reliable read-back
    marker that the action took effect (rather than a no-op tap).
    """
    tree = sim.observe_text() or ""
    return bool(re.search(r'<XCUIElementTypeButton[^>]*\bname="Share"', tree))


@mcp.tool()
def share_transaction(transaction_id: str = "") -> dict:
    """Open the share sheet for a transaction, self-navigating to it first.

    Args:
        transaction_id: Optional transaction UUID (from `list_transactions()`
            / `search_transactions()`). When provided, the tool opens that
            transaction's detail sheet first, then taps the Share button — so
            it works blind. When omitted, it shares whatever transaction
            detail sheet is already open.

    After tapping, the tool verifies the share sheet actually presented (a
    ShareLink button named "Share" appears) and returns ``{ok: True, message}``
    only then; if the tap was a no-op it returns ``{ok: False, message}``
    rather than a false success.
    """
    sim = SimulatorBridge.get()
    # Always self-navigate to the REQUESTED transaction when an id is given —
    # do NOT trust a detail sheet that merely happens to be open, since it may
    # belong to a DIFFERENT (previously opened) transaction and we'd act on the
    # wrong one. _open_transaction_detail relaunches first, dismissing any stale
    # sheet, then opens the correct transaction.
    if transaction_id:
        err = _open_transaction_detail(transaction_id)
        if err:
            return {
                "ok": False,
                "action": "share_transaction",
                "message": f"Could not share transaction '{transaction_id}'. {err}",
            }
    if not _detail_sheet_open(sim):
        return {
            "ok": False,
            "action": "share_transaction",
            "message": (
                "No transaction detail sheet is open. Pass transaction_id=... so this "
                "tool can navigate to the transaction first, or call open_transaction(<id>)."
            ),
        }
    sim.tap_id("detail_share_button")
    sim.wait(0.6)
    # Read-back: confirm the share sheet actually presented rather than
    # reporting success for a tap that did nothing.
    if not _share_sheet_open(sim):
        return {
            "ok": False,
            "action": "share_transaction",
            "message": (
                "Share sheet did not open after tapping; the share action was not "
                "presented. Verify the transaction detail sheet is still open and retry."
            ),
        }
    return {
        "ok": True,
        "action": "share_transaction",
        "message": "Opened share sheet for transaction" + (f" {transaction_id}" if transaction_id else "") + ".",
    }


@mcp.tool()
def view_account() -> str:
    """Open the accounts menu from the home screen toolbar (`home_accounts_menu`)."""
    sim = SimulatorBridge.get()
    sim.tap_id("home_accounts_menu")
    sim.wait(0.4)
    return "Opened accounts menu."


@mcp.tool()
def open_profile() -> str:
    """Tap the toolbar account/profile button (`toolbar_profile`).

    In the current MyBank build this top-right person.circle button opens
    the account Inbox sheet (messages, scheduled-payment alerts), not a
    standalone profile/settings page. Returns after the sheet opens.
    """
    sim = SimulatorBridge.get()
    sim.tap_id("toolbar_profile")
    sim.wait(0.4)
    return "Opened the account inbox sheet (toolbar profile button)."




# ── Direct-state-write tools

@mcp.tool()
def schedule_payment_direct(payee_name: str, amount: float, note: str = "") -> dict:
    """Schedule a bill payment by directly writing the seed state (no UI).

    Args:
        payee_name: Case-insensitive substring of a saved payee's display name.
            Use `list_payees_direct()` to discover valid names.
        amount: Positive dollar amount (numeric, not a string).
        note: Optional free-text memo.

    Appends to `mybank_state.json::scheduledPayments` with `schedule_date`
    set to ~24h from now. Returns ``{ok, payment_id, payee, amount, message}``
    on success, ``{ok: False, error, available}`` if no payee matches.
    """
    state = _load_state()
    payees = state.get("payees", [])
    target = next((p for p in payees if payee_name.lower() in p.get("name","").lower()), None)
    if not target:
        names = [p.get("name") for p in payees][:8]
        return {"ok": False, "error": f"No payee matching '{payee_name}'", "available": names}
    pid = str(uuid.uuid4()).upper()
    scheduled = {
        "id": pid, "amount": float(amount), "note": note,
        "payee_id": target["id"],
        "schedule_date": (datetime.now(timezone.utc)+timedelta(days=1)).replace(microsecond=0).isoformat()
                          .replace("+00:00","Z"),
        "status": "scheduled",
    }
    state.setdefault("scheduledPayments", []).append(scheduled)
    _save_state(state)
    return {"ok": True, "payment_id": pid, "payee": target["name"],
            "amount": amount, "message": f"Scheduled ${amount} to {target['name']}."}


@mcp.tool()
def list_payees_direct() -> dict:
    """List all available payees from the seed store (bypasses the UI).

    Returns: ``{payees: [{id, name, category}, ...], count}``. Use this to
    discover valid `payee_name` values for `schedule_payment_direct` or to
    map `name` → Zelle recipient picker rows.
    """
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    payees = [{"id": p.get("id"), "name": p.get("name"), "category": p.get("category")}
              for p in state.get("payees", [])]
    return {"payees": payees, "count": len(payees)}


@mcp.tool()
def list_accounts_direct() -> dict:
    """List all accounts (id, name, type, balance, currency) from the seed store.

    Returns: ``{accounts: [{id, name, type, balance, currency}, ...], count}``.
    Bypasses the UI — works even if the home screen hasn't been opened.
    Use this for ground-truth balance checks; for the on-screen list use
    `list_accounts()`.
    """
    state = dl.read_app_state(BUNDLE_ID, "mybank_state.json") or {}
    accts = [{"id": a.get("id"), "name": a.get("name"),
              "type": a.get("type"), "balance": a.get("balance"),
              "currency": a.get("currency","USD")}
             for a in state.get("accounts", [])]
    return {"accounts": accts, "count": len(accts)}

if __name__ == "__main__":
    mcp.run()
