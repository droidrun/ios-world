"""QuickChat MCP — iMessage/WhatsApp clone chat operations.

Bundle ID: com.iosworld.benchmark.quickchat

Accessibility-ID conventions (see QuickChat/ViewController.swift, .accessibility(identifier:) API):
  Tabs: tab_updates, tab_calls, tab_communities, tab_chats, tab_you
  Chat list row: chat_row_<thread_uuid>
  In-chat: chat_back_button, chat_send_button, chat_search_trigger,
           chat_quick_camera_button, chat_voice_note_button
  Community: community_create_button, community_name_field
  Status/visual: status_post_button, visual_message_card_<slug>
"""

import html
import sys, pathlib, re
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts

mcp = FastMCP("QuickChat")

BUNDLE_ID = "com.iosworld.benchmark.quickchat"

_TAB_MAP = {
    "chats": "tab_chats", "messages": "tab_chats",
    "calls": "tab_calls",
    "updates": "tab_updates", "status": "tab_updates",
    "communities": "tab_communities", "groups": "tab_communities",
    "you": "tab_you", "me": "tab_you", "profile": "tab_you",
}


@mcp.tool()
def launch() -> str:
    """Launch QuickChat and return the initial UI tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched QuickChat.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree as text (no taps performed)."""
    sim = SimulatorBridge.get()
    return ts.observe_app_scoped(
        sim,
        bundle_id=BUNDLE_ID,
        app_name="QuickChat",
        markers=("tab_chats", "chat_row_", "chat_send_button"),
    )


@mcp.tool()
def navigate_to_tab(tab: str) -> str:
    """Switch the bottom tab by friendly name. Works from ANY screen.

    Self-navigates: backs out of an open chat thread (the TabBar is hidden
    while a thread is open) and clears a lingering Chats search hub by
    relaunching before tapping the tab, so a blind call always lands.

    Args:
        tab: One of `chats` (aliases: `messages`), `calls`, `updates`
            (aliases: `status`), `communities` (aliases: `groups`), or
            `you` (aliases: `me`, `profile`). Case-insensitive. An unknown
            value returns an error string listing the valid tabs.
    """
    aid = _TAB_MAP.get(tab.strip().lower())
    if aid is None:
        return f"Could not switch to unknown tab '{tab}'. Use: chats, calls, updates, communities, you."
    sim = SimulatorBridge.get()
    # The bottom TabBar is HIDDEN while a chat thread is open (NavigationStack
    # push), so tapping a tab id no-ops / errors from inside a thread or the
    # search hub. Dismiss those overlays first so the TabBar is on screen, then
    # tap. (Bug class: a self-nav tap on a present-but-covered control.)
    tree = sim.observe_text() or ""
    if "chat_back_button" in tree:
        try:
            sim.tap_id("chat_back_button"); sim.wait(0.4)
        except Exception:
            pass
        tree = sim.observe_text() or ""
    # A Chats search hub (from search_messages) leaves the search keyboard up and
    # a stray TextField covering the lower screen; tapping a tab id switches the
    # page content but the keyboard/overlay lingers and can swallow the next
    # tap. `aid` is in the shared TabView tree so the missing-tab guard below
    # would not fire — relaunch to land on a clean Chats tab first.
    if _search_overlay_up(sim, tree):
        try:
            tree = sim.launch_and_observe(BUNDLE_ID) or ""
        except Exception:
            tree = sim.observe_text() or ""
    if aid not in tree:
        # TabBar still not visible (e.g. wedged search hub) — relaunch lands on
        # the Chats list with the TabBar rendered; QuickChat seed state is fixed
        # in memory so this is non-destructive.
        try:
            tree = sim.launch_and_observe(BUNDLE_ID) or ""
        except Exception:
            tree = sim.observe_text() or ""
    last_exc = ""
    for _ in range(2):
        try:
            sim.tap_id(aid); sim.wait(0.4)
            return f"Switched to '{tab}'."
        except Exception as exc:
            last_exc = str(exc)[:120]
            sim.wait(0.3)
    return f"Could not switch to '{tab}' tab. {last_exc}"


@mcp.tool()
def list_chats() -> dict:
    """List chat thread UUIDs visible on the Chats tab.

    Returns: ``{chats: [thread_uuid, ...], threads: [{id, title}, ...], count}``.
    Each uuid is the suffix of a `chat_row_<uuid>` accessibility ID; pass either
    the uuid OR the title to `open_chat`. Self-navigates to the Chats tab.
    """
    sim = SimulatorBridge.get()
    # Use the shared recovery: backs out of an open thread, activates the Chats
    # tab, and — crucially — relaunches if the search hub is covering the list so
    # the `chat_row_` rows actually re-render. Reading the raw tree after a search
    # otherwise returns ZERO rows even though the chats exist (bug class:
    # enumeration off a stale/overlaid tree).
    tree = _goto_chats_list(sim)
    rows = _chat_rows(tree)
    return {
        "chats": [uid for uid, _ in rows],
        "threads": [{"id": uid, "title": title} for uid, title in rows],
        "count": len(rows),
    }


_UUID_RE = re.compile(r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-'
                      r'[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$')


def _chat_rows(tree: str):
    """Parse the chat-list tree into ``[(uuid, title), ...]``.

    Each chat row is rendered as ``<XCUIElementTypeButton ... name="chat_row_<uuid>"
    label="<thread title>" ...>``. The accessibility *label* carries the thread
    title (`thread.title`), which is stable across launches; the UUID is freshly
    generated each seed so it must NOT be hardcoded by callers.
    """
    rows = []
    for m in re.finditer(
        r'name="chat_row_([0-9A-Fa-f\-]+)"\s+label="([^"]*)"', tree or ""
    ):
        rows.append((m.group(1), m.group(2)))
    # De-dupe preserving order (the tree may repeat a row across containers).
    seen, out = set(), []
    for uid, title in rows:
        if uid in seen:
            continue
        seen.add(uid)
        out.append((uid, title))
    return out


# Safe vertical band (in points) for tapping a chat row on the Chats list. The
# bottom TabBar floats around y~743-802 on the iPhone-16-Pro sim window (height
# ~874), so a row whose on-screen *center* lands under it receives the TabBar's
# tap instead of opening the thread (WDA does NOT auto-scroll a row it already
# considers "visible", and element.click() taps the row's mid-point under the
# bar). The top search header occupies the first ~336 points. We therefore aim
# to land each row's TOP at `_ROW_TARGET_Y` — comfortably between the header and
# the TabBar — and then tap that exact pixel rather than relying on tap_id.
_ROW_BAND_TOP = 200      # below the search header
_ROW_BAND_BOT = 640      # row top must stay this far above the floating TabBar
_ROW_TARGET_Y = 400      # one-shot drag aims the row's top here (center of band)


def _row_y(tree: str, uid: str):
    """Return the on-screen y (top) of ``chat_row_<uid>`` in *tree*, or None.

    The Appium page source reports the row's content-space y; for rows scrolled
    far down this can exceed the window height, but for on-screen rows it is the
    real pixel position we must keep clear of the floating TabBar.
    """
    m = re.search(
        r'name="chat_row_' + re.escape(uid) + r'"[^>]*?\by="(-?\d+)"', tree or ""
    )
    return int(m.group(1)) if m else None


def _drag(sim, dy: int, x: int = 200, start_y: int = 500) -> None:
    """Scroll the list content by ~``dy`` points using a CONTROLLED, inertia-free
    W3C drag.

    A positive ``dy`` scrolls content UP (rows move toward the top, revealing
    lower rows); negative scrolls DOWN. The motion is split into small steps and
    held briefly before the finger lifts so iOS treats it as a precise scroll,
    NOT a flick — a single fast drag carries momentum and overshoots a full
    extra page (e.g. a requested 398 px fling moved a row 840 px, oscillating
    798<->-42). The stepped+settle drag lands within a few px of the request,
    so a row can be parked in the tappable band deterministically. Falls back to
    a coarse swipe only if W3C actions are unavailable.
    """
    dy = max(-560, min(560, int(dy)))
    if abs(dy) < 4:
        return
    try:
        from selenium.webdriver.common.actions.action_builder import ActionBuilder
        from selenium.webdriver.common.actions.pointer_input import PointerInput
        steps = 8
        ptr = PointerInput("touch", "finger")
        ab = ActionBuilder(sim.driver, mouse=ptr)
        ab.pointer_action.move_to_location(x, start_y)
        ab.pointer_action.pointer_down()
        for s in range(1, steps + 1):
            ab.pointer_action.move_to_location(x, int(start_y - dy * s / steps))
            ab.pointer_action.pause(0.04)
        ab.pointer_action.pause(0.2)  # settle -> cancels fling inertia
        ab.pointer_action.pointer_up()
        ab.perform()
    except Exception:
        sim.swipe("up" if dy > 0 else "down")
    sim.wait(0.5)


def _scroll_row_into_band(sim, uid: str, max_iters: int = 6) -> bool:
    """Park ``chat_row_<uid>``'s top inside ``[_ROW_BAND_TOP, _ROW_BAND_BOT]``.

    Computes a precise per-iteration drag (current_y -> _ROW_TARGET_Y) so the
    row lands in the band — clear of the search header AND the floating TabBar —
    instead of flinging a full page and oscillating. Returns True once parked.
    """
    for _ in range(max_iters):
        tree = sim.observe_text() or ""
        y = _row_y(tree, uid)
        if y is None:
            # Row not in the current viewport — page up to surface earlier rows;
            # if it's below, a forward drag will bring it up next iteration.
            _drag(sim, -400)
            continue
        if _ROW_BAND_TOP <= y <= _ROW_BAND_BOT:
            return True
        # Drag exactly enough to move the row's top to the target band center.
        _drag(sim, y - _ROW_TARGET_Y)
    tree = sim.observe_text() or ""
    y = _row_y(tree, uid)
    return y is not None and _ROW_BAND_TOP <= y <= _ROW_BAND_BOT


def _thread_is_open(sim) -> bool:
    """True when a chat thread's composer is on screen (a thread is open)."""
    t = sim.observe_text() or ""
    return "chat_compose_field" in t or "chat_back_button" in t


def _tap_row(sim, uid: str) -> None:
    """Tap ``chat_row_<uid>`` once it has been parked in the tappable band.

    Uses Selenium ``element.click()``, which aims the row's geometric centre.
    That centre is reliable ONLY when the row is parked clear of the floating
    TabBar (the caller, `_scroll_row_into_band`, guarantees this) — for a row
    sitting low, the same click lands on the bar and no-ops. Empirically
    ``tap_xy`` at the row's pixel centre does NOT register a row tap on this
    build (its WDA tap path differs), whereas ``element.click()`` on a
    band-parked row opens the thread consistently. A short settle lets the
    scroll inertia fully stop before the click.
    """
    sim.wait(0.4)  # let any residual scroll settle so the click registers
    try:
        el = sim.driver.find_element("accessibility id", f"chat_row_{uid}")
        el.click()
        return
    except Exception:
        pass
    sim.tap_id(f"chat_row_{uid}")


def _open_chat_row(sim, uid: str, prefix_for_failure: str = ""):
    """Open the chat thread ``chat_row_<uid>`` from the Chats list.

    Parks the row in the tappable band with a precise drag, taps its real
    on-screen center, then VERIFIES the thread actually opened (composer/back
    button rendered) rather than trusting a no-op tap. Retries with a fresh
    re-park up to 3 times. Returns None on a confirmed open or a recovery-hint
    string on genuine failure (never a false success).
    """
    for attempt in range(3):
        parked = _scroll_row_into_band(sim, uid)
        try:
            if parked:
                _tap_row(sim, uid)
            else:
                # Couldn't park (row off-list?) — last-ditch tap by id.
                sim.tap_id(f"chat_row_{uid}")
        except Exception as exc:
            if attempt < 2:
                sim.wait(0.3)
                continue
            return f"{prefix_for_failure}Could not tap the chat row. {str(exc)[:100]}"
        sim.wait(0.6)
        if _thread_is_open(sim):
            return None
    return (
        f"{prefix_for_failure}Could not open the chat thread after tapping its row "
        "(the row may have been under the tab bar). Call observe() to confirm "
        "the Chats list is showing, then retry."
    )


def _search_overlay_up(sim, tree: str = None) -> bool:
    """True when the Chats search hub overlay is on screen.

    The SearchHubView (revealed by `search_messages`) is pushed on the Chats
    NavigationStack and leaves a search TextField + an `xmark` clear button. It
    is NOT a chat thread (no `chat_compose_field`) and NOT the status/community
    composer. Detect it so callers that need a clean tab (post_status,
    create_community, navigate_to_tab) can relaunch to clear it before acting —
    its stray TextField otherwise hijacks `find_elements("...TextField")[0]`.
    """
    t = tree if tree is not None else (sim.observe_text() or "")
    if "chat_compose_field" in t:           # inside a chat thread, not search
        return False
    if "status_name_field" in t or "community_name_field" in t:
        return False                         # a real composer sheet is up
    # Search hub: the Chats list is covered (no chat_row_ rows render) yet a
    # search TextField + clear xmark are present.
    has_field = "XCUIElementTypeTextField" in t
    has_search = ("xmark" in t and "chat_row_" not in t)
    return bool(has_field and has_search)


def _goto_chats_list(sim) -> str:
    """Return to the plain Chats list (where `chat_row_<uuid>` rows render) and
    return its UI tree.

    This must work from ANY cold state the agent leaves behind:
      * inside an open thread  -> tap `chat_back_button`
      * on another tab         -> tap `tab_chats`
      * inside the search hub  -> the SearchHubView is pushed on the Chats
        NavigationStack and is NOT popped by tapping `xmark` or `tab_chats`
        on this build, so the Chats list rows never re-render. The only
        reliable way back is to relaunch the app (QuickChat opens on the
        Chats list, and its DM state is seed-fixed in memory so a relaunch
        is non-destructive).
    The function only relaunches as a LAST resort, when no `chat_row_` rows
    are visible after the cheap back/tab navigation.
    """
    tree = sim.observe_text() or ""
    if "chat_back_button" in tree:
        try:
            sim.tap_id("chat_back_button"); sim.wait(0.4)
        except Exception:
            pass
        tree = sim.observe_text() or ""
    try:
        sim.tap_id("tab_chats"); sim.wait(0.4)
    except Exception:
        pass
    tree = sim.observe_text() or ""
    if "chat_row_" in tree:
        return tree
    # Rows aren't rendering (search hub covering the list, or a wedged state).
    # Relaunch to land back on the seed Chats list.
    try:
        tree = sim.launch_and_observe(BUNDLE_ID) or ""
    except Exception:
        tree = sim.observe_text() or ""
    if "chat_row_" not in tree:
        # Make sure the Chats tab is selected post-relaunch.
        try:
            sim.tap_id("tab_chats"); sim.wait(0.4)
        except Exception:
            pass
        tree = sim.observe_text() or ""
    return tree


def _resolve_thread_uuid(sim, target: str):
    """Resolve a blind `target` (UUID, full/partial NAME, or chat-row id) to a
    thread UUID present in the current Chats list.

    Returns ``(uuid, title, rows)`` or ``(None, None, rows)``. Self-navigates to
    the Chats list first (relaunching if the search hub / an open thread is
    covering it) so the tool works from a fresh launch OR mid-search. Matching is
    UUID-exact first, then case-insensitive exact title, then case-insensitive
    substring (longest/earliest title wins for stability).
    """
    raw = (target or "").strip()
    # Strip an accidental chat_row_ prefix the agent may have copied verbatim.
    if raw.lower().startswith("chat_row_"):
        raw = raw[len("chat_row_"):]

    tree = _goto_chats_list(sim)
    rows = _chat_rows(tree)

    # 1) Exact UUID match.
    if _UUID_RE.match(raw):
        for uid, title in rows:
            if uid.lower() == raw.lower():
                return uid, title, rows
        # Caller gave a UUID we can't see; still return it so the tap can try
        # (it may be off-screen but addressable by accessibility id).
        return raw, None, rows

    if not raw:
        return None, None, rows

    low = raw.lower()
    # 2) Exact (case-insensitive) title.
    for uid, title in rows:
        if title.lower() == low:
            return uid, title, rows
    # 3) Substring match — prefer the shortest title containing the query so a
    #    query like "Brooks" maps deterministically; ties broken by list order.
    cands = [(uid, title) for uid, title in rows if low in title.lower()]
    if cands:
        cands.sort(key=lambda t: (len(t[1]), rows.index(t)))
        return cands[0][0], cands[0][1], rows
    # 4) Token/initial fallback: every whitespace token of the query appears in
    #    the title (handles "elena brooks" vs "Elena  Brooks" spacing quirks).
    toks = [t for t in low.split() if t]
    if toks:
        for uid, title in rows:
            tl = title.lower()
            if all(tok in tl for tok in toks):
                return uid, title, rows
    return None, None, rows


@mcp.tool()
def open_chat(thread_id: str) -> str:
    """Open a chat thread by UUID or by display NAME.

    Args:
        thread_id: Either a thread UUID (suffix of `chat_row_<uuid>` from
            `list_chats()`) OR the chat's display name / title (e.g.
            ``"Elena Brooks"``, ``"Studio Launch"``). Name matching is
            case-insensitive and accepts substrings, so a fresh-launch blind
            call like ``open_chat("brooks")`` resolves to the matching thread.

    Self-navigates to the Chats tab, resolves the target against the live chat
    list, then taps the row.
    """
    sim = SimulatorBridge.get()
    uid, title, rows = _resolve_thread_uuid(sim, thread_id)
    if uid is None:
        names = ", ".join(sorted({t for _, t in rows})[:12])
        return (
            f"Could not find a chat matching '{thread_id}'. Available chats "
            f"include: {names}. Pass a display name or a UUID from list_chats()."
        )
    err = _open_chat_row(sim, uid, prefix_for_failure=f"Could not open chat '{thread_id}'. ")
    if err:
        return err
    shown = title or uid
    return f"Opened chat {shown}."


def _ensure_chat_open(sim, thread_id: Optional[str]) -> Optional[str]:
    """Make sure a chat thread is open so the composer is reachable.

    If `thread_id` is given, resolve it (UUID/name) and open that chat. If it's
    None, only act when no thread is currently open — leaving an already-open
    thread untouched. Returns None on success or a precondition message.
    """
    tree = sim.observe_text() or ""
    if thread_id:
        uid, _, rows = _resolve_thread_uuid(sim, thread_id)
        if uid is None:
            names = ", ".join(sorted({t for _, t in rows})[:12])
            return (f"Could not find a chat matching '{thread_id}'. "
                    f"Available chats include: {names}.")
        err = _open_chat_row(sim, uid, prefix_for_failure=f"Could not open chat '{thread_id}'. ")
        if err:
            return err
        return None
    # No explicit target: fine if a thread is already open.
    if "chat_compose_field" in tree or "chat_send_button" in tree:
        return None
    return (
        "No chat thread is open. Pass thread_id=<name or uuid> to this tool, "
        "or call open_chat(thread_id=...) first."
    )


def _send_message_fill_form(text: str) -> Optional[str]:
    """Tap the chat compose field and type `text` without tapping send.

    Returns None on success or a precondition message on failure. Used by
    both `send_message` (one-shot commit) and `prepare_send_message`
    (capture-only). Stops short of tapping `chat_send_button` so the
    caller decides whether to commit.
    """
    sim = SimulatorBridge.get()
    try:
        field = sim.driver.find_element("accessibility id", "chat_compose_field")
        field.click()
        sim.wait(0.2)
        field.send_keys(text)
    except Exception:
        try:
            sim.tap_id("chat_compose_field")
            sim.wait(0.3)
        except Exception:
            pass
        try:
            sim.type_text(text)
        except Exception as exc:
            return (
                f"Could not focus the chat compose field. Open a chat thread first "
                f"via open_chat(thread_id=...). Error: {str(exc)[:120]}"
            )
    sim.wait(0.3)
    tree = sim.observe_text() or ""
    if "chat_compose_field" not in tree:
        return (
            "Could not verify the chat compose field after typing. "
            "Open a chat thread first via open_chat(thread_id=...)."
        )
    if "chat_send_button" not in tree and "paperplane.fill" not in tree:
        return "Could not verify the chat send button after typing."
    return None


def _message_visible_after_send(sim, text: str) -> bool:
    """Poll for the sent message text in the current chat transcript."""
    token = " ".join((text or "").split())[:48]
    if not token:
        return True
    escaped = html.escape(token, quote=True)
    for _ in range(5):
        tree = sim.observe_text() or ""
        compact = " ".join(tree.split())
        if token in compact or escaped in compact:
            return True
        sim.wait(0.25)
    return False


@mcp.tool()
def send_message(text: str, thread_id: str = "") -> str:
    """Send a message to a chat thread (one-shot commit).

    Args:
        text: Plain-text message body.
        thread_id: Optional target chat — a UUID or display NAME (e.g.
            ``"Elena Brooks"``). When provided, the tool self-navigates to the
            Chats tab and opens that thread first, so a blind fresh-launch call
            works without a separate `open_chat`. When omitted, sends in the
            currently open thread.

    Taps the compose field, types `text`, then taps Send.
    """
    sim = SimulatorBridge.get()
    nav_err = _ensure_chat_open(sim, thread_id.strip() or None)
    if nav_err:
        return nav_err
    err = _send_message_fill_form(text)
    if err:
        return err
    try:
        sim.tap_id("chat_send_button")
    except Exception:
        sim.tap_id("paperplane.fill")
    sim.wait(0.4)
    if not _message_visible_after_send(sim, text):
        return (
            f"Could not verify that the message was sent. "
            f"Expected to see '{text[:48]}' in the open chat transcript."
        )
    return f"Sent message: '{text[:60]}'."


@mcp.tool()
def prepare_send_message(text: str) -> dict:
    """Tap the chat compose field and pre-fill `text` WITHOUT committing.

    `text` is the message body to stage. PRECONDITION: a chat thread must
    already be open — this tool does NOT take a thread_id and does NOT
    self-navigate, so call `open_chat(thread_id=...)` first. (Use one-shot
    `send_message(text, thread_id=...)` instead if you do not need the
    two-step prepare/confirm flow.)

    On success, returns ``{ok: True, action: "prepare_send_message",
    draft_id, summary: {text}}``. The agent should inspect the summary,
    then pass the ``draft_id`` to ``confirm_send_message`` to actually
    send. The draft expires after the `IOSWORLD_DRAFT_TTL_SECONDS` TTL
    (default 10 minutes) or when the simulator session resets.

    On precondition failure, returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _send_message_fill_form(text)
    if err:
        return {"ok": False, "action": "prepare_send_message", "message": err}
    summary = {"text": text}
    draft_id = ts.create_draft("quickchat", "send_message", summary)
    return {
        "ok": True,
        "action": "prepare_send_message",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_send_message(draft_id) to commit.",
    }


@mcp.tool()
def confirm_send_message(draft_id: str) -> dict:
    """Commit a chat message previously staged by ``prepare_send_message``.

    `draft_id` is the id returned by ``prepare_send_message``. The draft
    must still be present (not consumed, not expired). Returns
    ``{ok: True, action: "confirm_send_message", evidence: <summary>}``
    on success.

    If the draft is missing or expired, returns a controlled-failure
    response and does not tap the Send button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_send_message",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_send_message first.",
        }
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("chat_send_button")
    except Exception:
        try:
            sim.tap_id("paperplane.fill")
        except Exception:
            return {
                "ok": False,
                "action": "confirm_send_message",
                "message": "Send button not found in current UI; verify the chat thread is still open.",
            }
    sim.wait(0.4)
    payload = draft.get("payload", {}) or {}
    if not _message_visible_after_send(sim, payload.get("text", "")):
        return {
            "ok": False,
            "action": "confirm_send_message",
            "message": "Tapped Send but could not verify the message in the chat transcript.",
            "evidence": payload,
        }
    return {
        "ok": True,
        "action": "confirm_send_message",
        "evidence": payload,
    }


@mcp.tool()
def search_messages(query: str) -> str:
    """Search chats from the Chats tab's search bar.

    Args:
        query: Free-text search string (matched against chat names and
            message contents).

    The search bar lives on the Chats list screen, NOT inside an open
    thread. Self-navigates: backs out of an open thread, then activates the
    Chats tab before tapping `chat_search_trigger` to reveal and focus the
    search field. After this call the search hub overlay stays up and covers
    the Chats list (no `chat_row_` rows render); any follow-up tool that needs
    the list (list_chats, open_chat, post_status, create_community,
    navigate_to_tab) self-recovers by relaunching, so just call it normally.
    """
    sim = SimulatorBridge.get()

    def _open_search_field() -> Optional[str]:
        """Land on a clean Chats list, then tap `chat_search_trigger` to reveal
        and focus the search field. Returns None on success or an error string.

        Self-recovers from EVERY cold state the agent leaves behind:
          * inside an open chat thread -> tap `chat_back_button`
          * on another tab             -> tap `tab_chats`
          * a LINGERING search hub from a prior `search_messages` -> the
            SearchHubView is pushed on the Chats NavigationStack and is NOT
            popped by tapping `tab_chats`/`xmark` on this build, so
            `chat_search_trigger` never re-renders and the tap fails. Relaunch
            to land back on the seed Chats list (DM state is fixed in memory, so
            non-destructive), then the trigger is present again.
        """
        tree = sim.observe_text() or ""
        if "chat_back_button" in tree:
            try:
                sim.tap_id("chat_back_button"); sim.wait(0.4)
            except Exception:
                pass
            tree = sim.observe_text() or ""
        # Clear a lingering Chats search hub: its stray TextField/xmark replaces
        # the Chats list (no `chat_row_` rows, no `chat_search_trigger`), so a
        # second search would otherwise fail. tab_chats does NOT pop it on this
        # build — relaunch to get a clean Chats list with the trigger rendered.
        if _search_overlay_up(sim, tree):
            try:
                tree = sim.launch_and_observe(BUNDLE_ID) or ""
            except Exception:
                tree = sim.observe_text() or ""
        # Always activate the Chats tab. `chat_search_trigger` appears in the
        # tree from other tabs (shared TabView), but it only opens the search
        # field when Chats is the active screen.
        try:
            sim.tap_id("tab_chats"); sim.wait(0.4)
        except Exception:
            pass
        tree = sim.observe_text() or ""
        # If the trigger still isn't on screen (e.g. the search hub was not
        # caught above, or a wedged state), relaunch to recover the Chats list.
        if "chat_search_trigger" not in tree:
            try:
                tree = sim.launch_and_observe(BUNDLE_ID) or ""
                sim.tap_id("tab_chats"); sim.wait(0.4)
            except Exception:
                pass
        try:
            sim.tap_id("chat_search_trigger")
            sim.wait(0.6)
        except Exception as exc:
            return (f"Could not open chat search for '{query}'. Be on the Chats "
                    f"tab (navigate_to_tab('chats')). Error: {str(exc)[:120]}")
        return None

    err = _open_search_field()
    if err:
        # Retry once from a guaranteed-clean state: relaunch resets the Chats
        # NavigationStack so `chat_search_trigger` is present, then re-open.
        try:
            sim.launch_and_observe(BUNDLE_ID)
        except Exception:
            pass
        err = _open_search_field()
        if err:
            return err

    # The revealed SearchHubView TextField has no accessibility id, so focus
    # it by class name to bring up the keyboard, then type via send_keys.
    typed = False
    try:
        fields = sim.driver.find_elements("class name", "XCUIElementTypeTextField")
        if fields:
            fields[0].click()
            sim.wait(0.3)
            fields[0].send_keys(query)
            sim.wait(0.5)
            typed = True
    except Exception:
        typed = False
    if not typed:
        # Fallback: try the (legacy) named field then the global typer.
        try:
            sim.tap_id("chat_search_field"); sim.wait(0.3)
        except Exception:
            pass
        try:
            sim.type_text(query)
            sim.wait(0.5)
        except Exception as exc:
            return f"Could not type the search query '{query}': {str(exc)[:120]}"
    return f"Searched chats for '{query}'."


@mcp.tool()
def go_back() -> str:
    """Return from an open chat thread to the chat list.

    Taps `chat_back_button` when a thread is open. If no chat is open (the
    back button isn't on screen), this is a no-op success — the agent is
    already at the chat list — rather than an error, so a blind call from a
    fresh launch does not fail.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    if "chat_back_button" not in tree:
        # Already at the list (or on another tab with no in-chat back button).
        # Make sure we're on the Chats list for a predictable end state.
        if "chat_row_" not in tree:
            try:
                sim.tap_id("tab_chats"); sim.wait(0.3)
            except Exception:
                pass
        return "Already at the chat list (no open thread to go back from)."
    sim.tap_id("chat_back_button")
    sim.wait(0.3)
    return "Returned to chat list."


def _send_voice_note_fill_form() -> Optional[str]:
    """Pre-flight check for the voice-note button (no commit).

    Voice notes have no UI fields to fill — this helper just verifies the
    chat composer is reachable so `prepare_send_voice_note` can capture a
    draft without tapping `chat_voice_note_button`. Returns None on
    success or a precondition message on failure.
    """
    sim = SimulatorBridge.get()
    try:
        tree = sim.observe_text()
    except Exception as exc:
        return f"Simulator UI tree unavailable: {str(exc)[:120]}"
    if "chat_voice_note_button" not in tree:
        return (
            "Could not start a voice note: voice-note button not visible. Open a chat thread first via "
            "open_chat(thread_id=...) and re-call."
        )
    return None


@mcp.tool()
def send_voice_note(thread_id: str = "") -> str:
    """Tap `chat_voice_note_button` in a chat's composer (one-shot commit).

    Args:
        thread_id: Optional target chat — UUID or display NAME. When provided,
            self-navigates and opens that thread first so a blind fresh-launch
            call works. When omitted, acts on the currently open thread.
    """
    sim = SimulatorBridge.get()
    nav_err = _ensure_chat_open(sim, thread_id.strip() or None)
    if nav_err:
        return nav_err
    if "chat_voice_note_button" not in (sim.observe_text() or ""):
        # "Could not" prefix so the wrapper scores this honest failure ok:false
        # (a bare "...not visible" string is NOT matched by the failure-prefix
        # regex and was mis-scored ok:true — bug class: false-positive success).
        return ("Could not tap voice-note: the voice-note button is not visible. "
                "Open a chat thread first via open_chat(thread_id=...) or pass "
                "thread_id=<name>.")
    sim.tap_id("chat_voice_note_button")
    sim.wait(0.3)
    return "Tapped voice-note button."


@mcp.tool()
def prepare_send_voice_note() -> dict:
    """Stage a voice-note send WITHOUT tapping the record button.

    PRECONDITION: a chat thread must already be open so the voice-note
    button is on screen. This tool does NOT take a thread_id and does NOT
    self-navigate — call `open_chat(thread_id=...)` first. (Use one-shot
    `send_voice_note(thread_id=...)` if you do not need prepare/confirm.)

    On success, returns ``{ok: True, action: "prepare_send_voice_note",
    draft_id, summary: {}}``. The agent should pass the ``draft_id`` to
    ``confirm_send_voice_note`` to actually tap the voice-note button.
    The draft expires after the `IOSWORLD_DRAFT_TTL_SECONDS` TTL
    (default 10 minutes) or when the simulator session resets.

    On precondition failure, returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _send_voice_note_fill_form()
    if err:
        return {"ok": False, "action": "prepare_send_voice_note", "message": err}
    summary: dict = {}
    draft_id = ts.create_draft("quickchat", "send_voice_note", summary)
    return {
        "ok": True,
        "action": "prepare_send_voice_note",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_send_voice_note(draft_id) to commit.",
    }


@mcp.tool()
def confirm_send_voice_note(draft_id: str) -> dict:
    """Commit a voice-note tap previously staged by ``prepare_send_voice_note``.

    `draft_id` is the id returned by ``prepare_send_voice_note``. The
    draft must still be present (not consumed, not expired). Returns
    ``{ok: True, action: "confirm_send_voice_note", evidence: <summary>}``
    on success.

    If the draft is missing or expired, returns a controlled-failure
    response and does not tap the voice-note button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_send_voice_note",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_send_voice_note first.",
        }
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("chat_voice_note_button")
        sim.wait(0.3)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_send_voice_note",
            "message": "Voice-note button not found in current UI; verify the chat thread is still open.",
        }
    return {
        "ok": True,
        "action": "confirm_send_voice_note",
        "evidence": draft.get("payload", {}),
    }


@mcp.tool()
def open_camera(thread_id: str = "") -> str:
    """Tap `chat_quick_camera_button` in a chat's composer.

    Args:
        thread_id: Optional target chat — UUID or display NAME. When provided,
            self-navigates and opens that thread first so a blind fresh-launch
            call works. When omitted, acts on the currently open thread.
    """
    sim = SimulatorBridge.get()
    nav_err = _ensure_chat_open(sim, thread_id.strip() or None)
    if nav_err:
        return nav_err
    if "chat_quick_camera_button" not in (sim.observe_text() or ""):
        # "Could not" prefix so the wrapper scores this honest failure ok:false
        # (a bare "...not visible" string was mis-scored ok:true).
        return ("Could not open camera: the camera button is not visible. Open a "
                "chat thread first via open_chat(thread_id=...) or pass "
                "thread_id=<name>.")
    sim.tap_id("chat_quick_camera_button")
    sim.wait(0.3)
    return "Tapped quick-camera button."


@mcp.tool()
def post_status(caption: str = "") -> str:
    """Post a text status on the Updates/Status tab. Works from ANY screen.

    Self-navigates: backs out of an open chat thread, clears a lingering Chats
    search hub (relaunching if needed), activates the Updates tab, taps
    `status_add_text_button`, fills the composer text field, taps
    `status_post_button`, then VERIFIES the caption appears on the Updates feed
    before reporting success (retries the Post tap once if needed).

    Args:
        caption: Status text. Required and non-empty — the in-app Post button
            stays disabled for an empty status.

    Returns a success string only when the caption is confirmed on the feed;
    otherwise returns a "Cannot"/"Could not" failure string the agent can
    react to.
    """
    if not (caption or "").strip():
        # "Cannot" prefix so the wrapper flags this honest refusal as ok:false
        # (a bare "A non-empty caption..." string was mis-scored ok:true).
        return ("Cannot post: a non-empty caption is required — the Post button "
                "stays disabled for an empty status.")
    sim = SimulatorBridge.get()
    # The bottom TabBar is hidden while a chat thread is open, so tapping
    # `tab_updates` from inside a thread no-ops and the composer never opens.
    # Back out of any open thread first so the TabBar is on screen.
    tree = sim.observe_text() or ""
    if "chat_back_button" in tree:
        try:
            sim.tap_id("chat_back_button"); sim.wait(0.4)
        except Exception:
            pass
        tree = sim.observe_text() or ""
    # If the Chats search hub is up (from a prior search_messages), it leaves a
    # stray search TextField on screen. `status_add_text_button` is still in the
    # shared TabView tree so the relaunch-on-missing-tab guard below would NOT
    # fire — yet the composer's caption field is the SECOND TextField and
    # find_elements(...)[0] would grab the SEARCH field instead, so the caption
    # never lands and the post silently fails. Relaunch to clear the search hub
    # whenever it is present (QuickChat seed state is fixed in memory, so a
    # relaunch is non-destructive). Marker: a TextField with no open composer.
    if _search_overlay_up(sim, tree):
        try:
            tree = sim.launch_and_observe(BUNDLE_ID) or ""
        except Exception:
            tree = sim.observe_text() or ""
    # Always activate the Updates tab. All tab views share one TabView so
    # `status_add_text_button` appears in the tree from other tabs too, but
    # tapping it only works when Updates is the active screen. If the TabBar is
    # still not rendered (wedged search hub), relaunch to recover it.
    if "tab_updates" not in tree:
        try:
            sim.launch_and_observe(BUNDLE_ID)
        except Exception:
            pass
    try:
        sim.tap_id("tab_updates"); sim.wait(0.5)
    except Exception:
        pass
    try:
        sim.tap_id("status_add_text_button")
        sim.wait(0.4)
    except Exception:
        return ("Could not open the status composer. Be on the Updates tab "
                "(navigate_to_tab('updates')).")
    try:
        fields = sim.driver.find_elements("class name", "XCUIElementTypeTextField")
        if fields:
            fields[0].click()
            sim.wait(0.2)
            fields[0].send_keys(caption)
        else:
            sim.type_text(caption)
        sim.wait(0.3)
    except Exception:
        # "Could not" prefix so the wrapper scores this ok:false (a bare
        # "...is unavailable" string was mis-scored ok:true).
        return ("Could not fill the status caption: the caption field is "
                "unavailable in the current UI state; open Updates and tap text "
                "status first.")
    sim.tap_id("status_post_button")
    sim.wait(0.6)
    # Verify the post actually landed: a published status renders on the Updates
    # feed as a row whose label embeds the caption text (e.g. "Jordan Avery,
    # <caption>"), and the composer's Post button is dismissed. Only report
    # success when the caption is observable — never a blind ok:true.
    after = sim.observe_text() or ""
    if caption[:40] in after and "status_post_button" not in after:
        return f"Posted status (caption: '{caption[:60]}')."
    # Composer may still be up (post tap missed) — retry the post once.
    if "status_post_button" in after:
        try:
            sim.tap_id("status_post_button"); sim.wait(0.6)
        except Exception:
            pass
        after = sim.observe_text() or ""
        if caption[:40] in after and "status_post_button" not in after:
            return f"Posted status (caption: '{caption[:60]}')."
    return ("Could not confirm the status was posted: the caption did not appear "
            "on the Updates feed after tapping Post. Call observe() to check the "
            "Updates tab.")


@mcp.tool()
def create_community(name: str) -> str:
    """Create a new community/group. Works from ANY screen — self-navigates.

    Backs out of any open chat thread, clears a lingering Chats search hub
    (relaunching if needed), activates the Communities tab, opens the New
    community sheet via `community_new_button`, fills `community_name_field`,
    auto-selects the first available member (the Create button stays disabled
    until both a name and >=1 member are present), then taps
    `community_create_button` to commit. No prior navigation is required.

    Args:
        name: User-facing display name for the new community. Required and
            non-empty.

    Returns a success string on commit, or an ``{ok: False, message}`` dict
    on a controlled failure (empty name, sheet would not open, name field
    unreachable, or no selectable member).
    """
    if not (name or "").strip():
        return {
            "ok": False,
            "action": "create_community",
            "message": "A non-empty community name is required.",
        }
    sim = SimulatorBridge.get()
    # The bottom TabBar is hidden while a chat thread is open, so tapping
    # `tab_communities` from inside a thread no-ops and the New community sheet
    # never opens. Back out of any open thread first so the TabBar is on screen.
    tree = sim.observe_text() or ""
    if "chat_back_button" in tree:
        try:
            sim.tap_id("chat_back_button"); sim.wait(0.4)
        except Exception:
            pass
        tree = sim.observe_text() or ""
    # Clear a lingering Chats search hub first: its stray search TextField would
    # otherwise be picked up while filling the community name field, and
    # `community_new_button` is present in the shared TabView tree so the
    # tab-missing guard below would not fire. Relaunch to land on a clean Chats
    # tab (seed state is fixed in memory, so non-destructive).
    if _search_overlay_up(sim, tree):
        try:
            tree = sim.launch_and_observe(BUNDLE_ID) or ""
        except Exception:
            tree = sim.observe_text() or ""
    if "tab_communities" not in tree:
        # TabBar still not rendered (wedged search hub) — relaunch to recover it.
        try:
            sim.launch_and_observe(BUNDLE_ID)
        except Exception:
            pass
    # Always activate the Communities tab. NOTE: all tab views live in one
    # TabView, so `community_new_button` appears in the tree even from other
    # tabs — tapping it only works when Communities is the *active* screen, so
    # we must switch tabs unconditionally rather than gate on id-presence.
    try:
        sim.tap_id("tab_communities"); sim.wait(0.5)
    except Exception:
        pass
    # Open the New community sheet.
    try:
        sim.tap_id("community_new_button")
    except Exception:
        # Fallback: the older create_button id might be the opener in some builds.
        try:
            sim.tap_id("community_create_button")
        except Exception as exc:
            return {
                "ok": False,
                "action": "create_community",
                "message": (
                    "Could not open the New community sheet. Be on the "
                    "Communities tab (navigate_to_tab('communities')). "
                    f"Error: {str(exc)[:100]}"
                ),
            }
    sim.wait(0.6)
    # Confirm the New-community sheet is actually open (its name field is unique).
    if "community_name_field" not in (sim.observe_text() or ""):
        return {
            "ok": False,
            "action": "create_community",
            "message": "Community name field is unavailable in the current UI state; open Communities and start New community first.",
        }
    # Fill the community name field (target by its accessibility id, not order).
    try:
        nf = sim.driver.find_element("accessibility id", "community_name_field")
        nf.click()
        sim.wait(0.2)
        nf.send_keys(name)
    except Exception:
        try:
            sim.tap_id("community_name_field")
            sim.wait(0.2)
            sim.type_text(name)
        except Exception:
            return {
                "ok": False,
                "action": "create_community",
                "message": "Could not focus the community name field on the New community sheet.",
            }
    sim.wait(0.3)
    # Dismiss the keyboard so the member list is hittable.
    try:
        sim.driver.find_element("accessibility id", "Return").click()
        sim.wait(0.4)
    except Exception:
        pass
    # The Create button is disabled until >=1 member is selected. Member rows
    # are Buttons whose accessibility label is the contact name followed by a
    # message preview (e.g. "Maya Patel, ..."). Tapping the row toggles the
    # selection. Match a real contact row rather than guessing circle x-coords.
    _CONTROL_LABELS = {"close", "create community", "more", "camera", "compose",
                       "back", "new community"}
    selected = False
    try:
        buttons = sim.driver.find_elements("class name", "XCUIElementTypeButton")
        for b in buttons:
            try:
                lab = (b.get_attribute("label") or "").strip()
            except Exception:
                lab = ""
            low = lab.lower()
            if not lab or low in _CONTROL_LABELS:
                continue
            if low.startswith("chat_row_") or low.startswith("tab_"):
                continue
            # A member row label looks like "Name, preview" or just "Name".
            # Require it to NOT be the create button and to sit in the member
            # list region (below the name field). Tap the first plausible one.
            try:
                y = b.location.get("y", 0)
            except Exception:
                y = 0
            if y < 240:  # skip the top compose/name area
                continue
            b.click()
            sim.wait(0.4)
            selected = True
            break
    except Exception:
        selected = False
    if not selected:
        # Fallback: tap a right-edge circle toggle directly.
        try:
            circles = sim.driver.find_elements("accessibility id", "circle")
            target = None
            for c in circles:
                try:
                    if c.location.get("x", 0) > 300 and c.location.get("y", 0) > 240:
                        target = c
                        break
                except Exception:
                    continue
            if target is None and circles:
                target = circles[0]
            if target is not None:
                target.click()
                sim.wait(0.4)
                selected = True
        except Exception:
            selected = False
    if not selected:
        return {
            "ok": False,
            "action": "create_community",
            "message": (
                "Could not select a community member; the Create button stays "
                "disabled without one. Verify the New community sheet is open."
            ),
        }
    # Commit — the Create button sits at the bottom of a scroll view, so it may
    # be off-screen. tap_id resolves it by accessibility id (WDA scrolls to it).
    committed = False
    try:
        btn = sim.driver.find_element("accessibility id", "community_create_button")
        btn.click()
        committed = True
    except Exception:
        for _ in range(3):
            try:
                sim.tap_id("community_create_button")
                committed = True
                break
            except Exception:
                try:
                    sim.swipe("up"); sim.wait(0.3)
                except Exception:
                    break
    if not committed:
        return {
            "ok": False,
            "action": "create_community",
            "message": "Create community button could not be tapped after selecting a member.",
        }
    sim.wait(0.8)
    return f"Created community '{name}'."


if __name__ == "__main__":
    mcp.run()
