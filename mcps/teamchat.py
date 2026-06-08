"""TeamChat MCP — Slack-style workspaces: channels, DMs, threads, reactions.

Bundle: com.iosworld.benchmark.teamchat
State file: teamchatsim_state.json (fallback: slacksim_state.json)

IDs (see TeamChat/ source):
  Tabs: tab_home, tab_dms, tab_activity, tab_search, tab_more.
  Channel list: channel_row_<channel_slug>,
                channel_mute_action_<slug>, channel_star_action_<slug>,
                channel_read_action_<slug>.
  Channel detail: composer_text_field, send_message_button,
                  composer_add_image_attachment / pdf / link,
                  message_row_<message_id>,
                  add_reaction_button_<message_id>,
                  open_thread_button_<message_id>,
                  channel_info_button, channel_notifications_toggle,
                  empty_channel_state.
  DMs: dm_row_<contact_name>, send_dm_message_button.
  Threads: thread_reply_composer_field, thread_send_reply_button.
  Search: search_query_field, search_submit_button.
  Add workspace: add_workspace_name_field, add_workspace_description,
                 add_workspace_confirm_button.

Naming: <channel_slug> / <contact_name> are lowercased display names
(e.g. 'general', 'random'); <message_id> is the slug from a
`message_row_<id>` in the live UI tree.

Resolver conventions (what the tools accept):
  - Channel-addressed tools (open_channel, mute/star/mark_channel_read,
    post_message_direct, *_channel*) self-resolve via _find_channel, which
    accepts the DISPLAY NAME ('General'), the lowercase slug ('general'),
    the hyphen form ('eng-mobile'), or the channel id — case-insensitive.
    You do NOT need to pre-slugify; pass the human-readable channel name.
  - Person-addressed tools (open_dm) self-resolve via _resolve_contact:
    display name, @username, slug, substring, or first/last-name token.
  - Tab/nav tools self-navigate: every tab tool pops out of an open
    channel/DM detail view first (where the tab bar is hidden), so they
    work from ANY screen, including a fresh launch.
"""

import sys, pathlib, re
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("TeamChat")

BUNDLE_ID = "com.iosworld.benchmark.teamchat"
STATE_FILE = "teamchatsim_state.json"

TAB_MAP = {
    "home": "tab_home",
    "dms": "tab_dms",
    "activity": "tab_activity",
    "search": "tab_search",
    "more": "tab_more",
}


def _load_state() -> tuple[str, dict]:
    state = dl.read_app_state(BUNDLE_ID, STATE_FILE)
    if state:
        return STATE_FILE, state
    fallback = "slacksim_state.json"
    return fallback, dl.read_app_state(BUNDLE_ID, fallback) or {}


def _save_state(state_file: str, state: dict) -> None:
    dl.write_app_state(BUNDLE_ID, state_file, state)
    dl.reload_app(BUNDLE_ID)


def _element_center(tree: str, aid: str) -> Optional[tuple[int, int]]:
    """Parse the 0-1000-normalized (cx, cy) center of an accessibility-id
    element from a UI tree.

    Returns None when the id isn't present. `tap_xy` expects coordinates in
    a 0-1000 space (appium_agent scales them by window size), so we read the
    Application window bounds from the same tree and normalize. Used to fall
    back to a coordinate tap when WDA's accessibility-id tap fails to
    activate a SwiftUI NavigationLink row (observed on
    channel_row_general/hiring_panel: the row hit-tests by coordinate but the
    id tap silently no-ops).
    """
    m = re.search(
        r'name="' + re.escape(aid) + r'"[^>]*?x="(-?\d+)" y="(-?\d+)" width="(\d+)" height="(\d+)"',
        tree,
    )
    if not m:
        return None
    x, y, w, h = (int(g) for g in m.groups())
    cx, cy = x + w / 2.0, y + h / 2.0
    win = re.search(
        r'XCUIElementTypeApplication[^>]*?width="(\d+)" height="(\d+)"', tree
    )
    win_w = float(win.group(1)) if win else 402.0
    win_h = float(win.group(2)) if win else 874.0
    return (int(cx / win_w * 1000), int(cy / win_h * 1000))


def _pop_back_safe(sim, tree: str) -> None:
    """Pop the navigation stack without an unguarded keyboard-up find_element.

    After a send the keyboard stays raised; a bare ``tap_id("BackButton")``
    issues a WDA ``find_element`` that can HANG indefinitely with the
    keyboard up (the same accessibility-snapshot stall as the Send button).
    So we first try to resolve BackButton's coordinate from the
    already-fetched (timeout-guarded) ``tree`` and ``tap_xy`` it
    (snapshot-free); if it isn't locatable, fall back to a right edge-swipe
    back gesture. Both paths avoid ``find_element``.
    """
    center = _element_center(tree, "BackButton")
    if center is not None:
        try:
            sim.tap_xy(center[0], center[1]); sim.wait(0.5)
            return
        except Exception:
            pass
    try:
        sim.swipe("right"); sim.wait(0.5)  # edge-swipe back fallback
    except Exception:
        pass


def _tab_bar_visible(tree: str) -> bool:
    """True when TeamChat's bottom tab bar is reachable in `tree`.

    The five tab ids (tab_home/dms/activity/search/more) only render when
    TeamChat's RootTabView is foreground AND no channel/DM detail view or
    pushed sub-screen is covering it. The bar is all-or-nothing, so probing for
    ANY tab id is sufficient. Used to decide whether self-recovery (pop the
    detail view / relaunch to the workspace root) is needed before a tab tap.
    """
    return any(aid in (tree or "") for aid in TAB_MAP.values())


def _switch_state(tree: str, aid: str) -> Optional[str]:
    """Return a SwiftUI Switch's value ('1'/'0') by accessibility id, else None.

    The value attribute is emitted before `name` in the XCUITest XML, so the
    pattern intentionally looks left of the id.
    """
    m = re.search(r'value="(\d)" name="' + re.escape(aid) + r'"', tree)
    return m.group(1) if m else None


def _tap_switch_thumb(sim, tree: str, aid: str) -> bool:
    """Tap the right-edge thumb of a SwitchToggleStyle toggle by coordinate.

    A SwiftUI Toggle's accessibility-id tap (and even a center tap) lands on
    the label and does NOT flip the switch — only the thumb on the trailing
    edge does. Returns True if a tap was issued, False if the element/window
    bounds couldn't be resolved.
    """
    m = re.search(
        r'name="' + re.escape(aid) + r'"[^>]*?x="(-?\d+)" y="(-?\d+)" width="(\d+)" height="(\d+)"',
        tree,
    )
    if not m:
        return False
    x, y, w, h = (int(g) for g in m.groups())
    win = re.search(
        r'XCUIElementTypeApplication[^>]*?width="(\d+)" height="(\d+)"', tree
    )
    win_w = float(win.group(1)) if win else 402.0
    win_h = float(win.group(2)) if win else 874.0
    tx = (x + w - 22) / win_w * 1000
    ty = (y + h / 2.0) / win_h * 1000
    sim.tap_xy(int(tx), int(ty))
    return True


def _slugify(text: str) -> str:
    """Mirror the app's String.accessibilitySlug (String+Identifiers.swift).

    lowercased; strip '#'/'@'/'.'; '&'->'and'; ' ' and '-' -> '_'. Used to
    turn a human display name (e.g. 'Riley Shah') into the accessibility-id
    suffix the SwiftUI views actually emit (e.g. 'riley_shah'), which is what
    `dm_row_<slug>` / `channel_row_<slug>` are keyed on. The blind agent
    passes a display NAME, not the slug, so every name-addressed tool must
    slugify before building an id.
    """
    s = (text or "").lower()
    s = s.replace("#", "").replace("@", "").replace("&", "and")
    s = s.replace(" ", "_").replace("-", "_").replace(".", "")
    return s


def _list_members(state: dict) -> list[dict]:
    """All workspace members across seeded workspaces (current user included)."""
    out: list[dict] = []
    for ws in state.get("seededWorkspaces", []):
        out.extend(ws.get("members", []))
    return out


def _list_dm_conversations(state: dict) -> list[dict]:
    out: list[dict] = []
    for ws in state.get("seededWorkspaces", []):
        out.extend(ws.get("dmConversations", []))
    return out


def _resolve_contact(state: dict, query: str) -> Optional[dict]:
    """Resolve a blind display-name (or username/slug) to a member record.

    Matching is tolerant of how an agent addresses a person from a fresh
    launch: exact display name (case-insensitive) -> exact username -> exact
    slug -> substring on display name -> first/last-name token match. Returns
    the member dict (with displayName/username/id) or None.
    """
    if not (query or "").strip():
        return None
    q = query.strip()
    ql = q.lower()
    qslug = _slugify(q)
    members = [m for m in _list_members(state)]
    # 1. exact display name
    for m in members:
        if (m.get("displayName") or "").lower() == ql:
            return m
    # 2. exact username
    for m in members:
        if (m.get("username") or "").lower() == ql:
            return m
    # 3. exact slug of display name
    for m in members:
        if _slugify(m.get("displayName") or "") == qslug:
            return m
    # 4. substring on display name (e.g. "riley" -> "Riley Shah")
    subs = [m for m in members if ql in (m.get("displayName") or "").lower()]
    if len(subs) == 1:
        return subs[0]
    # 5. token match on any name word (first OR last name)
    qtokens = [t for t in re.split(r"[\s_]+", ql) if t]
    if qtokens:
        toks = []
        for m in members:
            words = (m.get("displayName") or "").lower().split()
            if any(t in words for t in qtokens):
                toks.append(m)
        if len(toks) == 1:
            return toks[0]
    # Ambiguous substring: prefer one whose first token matches exactly.
    if subs:
        for m in subs:
            if (m.get("displayName") or "").lower().startswith(ql):
                return m
        return subs[0]
    return None


def _resolve_dm_target(state: dict, query: str) -> tuple[Optional[str], Optional[str], Optional[str]]:
    """Resolve a DM target to (display_name, row_slug, username).

    Handles both 1:1 contacts (via member resolution) and group DMs (matched
    on the dmConversation name). For a 1:1, username enables the
    participant-strip 'start DM' path when no row exists yet. row_slug is the
    accessibility slug used for `dm_row_<slug>`. Any field may be None.
    """
    member = _resolve_contact(state, query)
    if member:
        name = member.get("displayName") or query
        return name, _slugify(name), (member.get("username") or "")
    # Group DM (or DM addressed by conversation name).
    ql = (query or "").strip().lower()
    qslug = _slugify(query or "")
    for dm in _list_dm_conversations(state):
        nm = (dm.get("name") or "")
        if nm.lower() == ql or _slugify(nm) == qslug or (ql and ql in nm.lower()):
            return nm, _slugify(nm), None
    return None, None, None


def _dm_navigated(tree: str) -> bool:
    return (
        "send_dm_message_button" in tree
        or "composer_text_field" in tree
        or "dm_header_name" in tree
        or "empty_dm_history_state" in tree
        or "empty_dm_state" in tree
    )


def _coord_tap_from_tree(sim, tree: str, aid: str) -> bool:
    """Coordinate-tap an element by id using its bounds in `tree`.

    Returns True if a tap was issued (element bounds resolvable), else False.
    SwiftUI rows/buttons frequently no-op on an accessibility-id tap; a
    normalized coordinate tap on the element center is reliable.
    """
    center = _element_center(tree, aid)
    if center is None:
        return False
    sim.tap_xy(center[0], center[1])
    return True


def _open_dm_via_member_strip(sim, username: str) -> bool:
    """Scroll the horizontal participant strip on the DMs tab to find
    `dm_member_quick_open_<username>` and tap it to START/open the DM.

    The strip lists EVERY member (even those without an existing thread), and
    tapping a member calls store.createDM, so this is the robust path when no
    `dm_row_` exists yet. Off-screen strip elements appear in the tree but
    their id-tap no-ops, so we swipe the strip left until the element's center
    is within the window, then coordinate-tap it. Returns True if navigation
    into the DM detail view is confirmed.
    """
    if not username:
        return False
    aid = f"dm_member_quick_open_{username}"
    for _ in range(10):
        tree = sim.observe_text()
        m = re.search(
            r'name="' + re.escape(aid) + r'"[^>]*?x="(-?\d+)" y="(-?\d+)" width="(\d+)" height="(\d+)"',
            tree,
        )
        if not m:
            # Element not in tree at all yet; nudge the strip and retry.
            sim.swipe("left", x=500, y=183); sim.wait(0.4)
            continue
        x, y, w, h = (int(g) for g in m.groups())
        win = re.search(r'XCUIElementTypeApplication[^>]*?width="(\d+)" height="(\d+)"', tree)
        win_w = float(win.group(1)) if win else 402.0
        win_h = float(win.group(2)) if win else 874.0
        # On-screen if its center x is comfortably inside the window.
        if 8 <= x and (x + w) <= win_w - 4:
            cx = int((x + w / 2.0) / win_w * 1000)
            cy = int((y + h / 2.0) / win_h * 1000)
            sim.tap_xy(cx, cy); sim.wait(0.9)
            if _dm_navigated(sim.observe_text()):
                return True
            # Tapped but didn't navigate; loop once more.
            continue
        # Off to the right: scroll the strip left at its vertical band.
        strip_y = int((y + h / 2.0) / win_h * 1000)
        sim.swipe("left", x=500, y=strip_y); sim.wait(0.4)
    return False


def _find_channel(state: dict, channel_slug: str) -> tuple[dict | None, dict | None]:
    q = (channel_slug or "")
    ql = q.lower()
    qslug = _slugify(q)
    for ws in state.get("seededWorkspaces", []):
        for ch in ws.get("channels", []):
            name = ch.get("channelName", "")
            if (
                name.lower() == ql
                or ch.get("id") == q
                or _slugify(name) == qslug  # 'eng-mobile' <-> 'eng_mobile'
            ):
                return ws, ch
    return None, None


def _find_message(state: dict, message_id: str) -> tuple[dict | None, dict | None, dict | None]:
    for ws in state.get("seededWorkspaces", []):
        for ch in ws.get("channels", []):
            for msg in ch.get("messages", []):
                if msg.get("id") == message_id:
                    return ws, ch, msg
    return None, None, None


# Accessibility-id prefixes that wrap a bare <message_id>. A blind agent often
# pastes the WHOLE element name it saw (e.g. "message_row_msg_094") instead of
# the bare id, so we strip these to recover the id the resolver/UI expect.
_MSG_ID_PREFIXES = (
    "message_row_",
    "open_thread_button_",
    "add_reaction_button_",
    "message_text_",
    "message_avatar_",
    "message_sender_",
    "message_timestamp_",
)


def _normalize_message_id(message_id: str) -> str:
    """Strip a wrapping accessibility-id prefix off a pasted element name.

    'message_row_msg_094' -> 'msg_094'; a bare 'msg_094' passes through. Lets
    reply_to_thread / add_reaction accept either the bare id from the docstring
    OR the full element name the agent literally read out of observe().
    """
    mid = (message_id or "").strip()
    for pfx in _MSG_ID_PREFIXES:
        if mid.startswith(pfx):
            return mid[len(pfx):]
    return mid


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


def _message_row(msg: dict) -> dict:
    reactions = msg.get("reactions") or []
    return {
        "id": msg.get("id"),
        "sender_id": msg.get("senderId"),
        "sender": msg.get("senderDisplayName"),
        "text": msg.get("messageText"),
        "timestamp": msg.get("timestamp"),
        "is_unread": msg.get("isUnread"),
        "reply_count": msg.get("replyCount", len(msg.get("threadReplies") or [])),
        "reaction_count": len(reactions),
        "reactions": reactions,
        "attachment_count": len(msg.get("attachments") or []),
    }


def _resolve_message_id_in_tree(tree: str, message_text: str) -> Optional[str]:
    """Resolve a visible message body substring to its `msg_<id>` from a tree.

    Scans every `message_text_<id>` StaticText (the per-message body element)
    and returns the id whose `value` contains `message_text` (case-insensitive).
    Prefers the shortest matching body (most specific). Returns None if no
    on-screen message matches.
    """
    needle = (message_text or "").strip().lower()
    if not needle:
        return None
    best: Optional[tuple[int, str]] = None
    for m in re.finditer(r'value="([^"]*)" name="message_text_([^"]+)"', tree):
        body = m.group(1)
        mid = m.group(2)
        if needle in body.lower():
            cand = (len(body), mid)
            if best is None or cand < best:
                best = cand
    return best[1] if best else None


def _scroll_find_message_by_text(sim, message_text: str, max_scrolls: int = 14) -> tuple[Optional[str], str]:
    """Find the `msg_<id>` for a visible-text substring, scrolling the channel.

    Channels are long; the target message may be above the current viewport.
    Scrolls UP (toward older messages) and DOWN, observing each time, until a
    `message_text_<id>` body contains `message_text`. Returns
    (msg_id_or_None, last_tree). Leaves the matching row on screen when found.
    """
    tree = sim.observe_text()
    mid = _resolve_message_id_in_tree(tree, message_text)
    if mid:
        return mid, tree
    # Scroll up toward older messages first (most channels open near the bottom).
    for _ in range(max_scrolls):
        sim.swipe("down"); sim.wait(0.35)  # swipe down reveals older/upper msgs
        tree = sim.observe_text()
        mid = _resolve_message_id_in_tree(tree, message_text)
        if mid:
            return mid, tree
    # Then scroll back down past the start in case it was below.
    for _ in range(max_scrolls * 2):
        sim.swipe("up"); sim.wait(0.35)
        tree = sim.observe_text()
        mid = _resolve_message_id_in_tree(tree, message_text)
        if mid:
            return mid, tree
    return None, tree


def _id_onscreen(tree: str, aid: str) -> bool:
    """True if `aid`'s element center lies inside the visible window.

    The XCUITest tree lists scrolled-OFF rows too, but with x/y outside the
    Application bounds (often NEGATIVE y above the viewport). A coordinate tap
    on those misses, so callers must scroll the row into the viewport first.
    """
    m = re.search(
        r'name="' + re.escape(aid) + r'"[^>]*?x="(-?\d+)" y="(-?\d+)" width="(\d+)" height="(\d+)"',
        tree,
    )
    if not m:
        return False
    x, y, w, h = (int(g) for g in m.groups())
    win = re.search(r'XCUIElementTypeApplication[^>]*?width="(\d+)" height="(\d+)"', tree)
    win_w = float(win.group(1)) if win else 402.0
    win_h = float(win.group(2)) if win else 874.0
    cy = y + h / 2.0
    cx = x + w / 2.0
    # Keep a margin off the very top/bottom (nav bar / composer) so the tap
    # lands on the row, not on chrome.
    return 0 <= cx <= win_w and 80 <= cy <= win_h - 90


def _scroll_id_onscreen(sim, aid: str, max_scrolls: int = 20) -> tuple[bool, str]:
    """Scroll the channel until `aid`'s center is inside the viewport.

    Returns (onscreen, last_tree). Decides scroll direction from the element's
    current y: if it sits ABOVE the viewport (negative/small y) swipe down to
    bring older content into view; if BELOW, swipe up. Falls back to a sweep
    if the element isn't in the tree at all yet.
    """
    tree = sim.observe_text()
    win = re.search(r'XCUIElementTypeApplication[^>]*?width="(\d+)" height="(\d+)"', tree)
    win_h = float(win.group(2)) if win else 874.0
    for _ in range(max_scrolls):
        if _id_onscreen(tree, aid):
            return True, tree
        m = re.search(
            r'name="' + re.escape(aid) + r'"[^>]*?y="(-?\d+)" width="\d+" height="(\d+)"',
            tree,
        )
        if m:
            cy = int(m.group(1)) + int(m.group(2)) / 2.0
            if cy < 80:
                sim.swipe("down")  # element above viewport -> reveal upward
            else:
                sim.swipe("up")    # element below viewport -> reveal downward
        else:
            sim.swipe("down")      # not in tree: sweep toward older messages
        sim.wait(0.35)
        tree = sim.observe_text()
    return _id_onscreen(tree, aid), tree


def _resolve_message_in_state_by_text(state: dict, message_text: str) -> tuple[dict | None, dict | None, dict | None]:
    """Resolve a body substring to (ws, ch, msg) using full seed text.

    The visible tree only shows on-screen bodies; seed state has every
    message's full `messageText`, so this is the authoritative fallback when a
    substring can't be found on screen. Prefers the shortest matching body.
    """
    needle = (message_text or "").strip().lower()
    if not needle:
        return None, None, None
    best = None
    best_len = None
    for ws in state.get("seededWorkspaces", []):
        for ch in ws.get("channels", []):
            for msg in ch.get("messages", []):
                body = (msg.get("messageText") or "")
                if needle in body.lower():
                    if best_len is None or len(body) < best_len:
                        best = (ws, ch, msg)
                        best_len = len(body)
    return best if best else (None, None, None)


@mcp.tool()
def launch() -> str:
    """Launch the TeamChat app and return the initial UI accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched TeamChat.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (XML) for the foreground app."""
    sim = SimulatorBridge.get()
    return ts.observe_app_scoped(
        sim,
        bundle_id=BUNDLE_ID,
        app_name="TeamChat",
        markers=("tab_home", "channel_row_", "composer_text_field", "dm_row_"),
    )


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch to a TeamChat bottom-tab. Works from any screen.

    Args:
      tab_name: one of 'home', 'dms', 'activity', 'search', 'more'.
        Case-insensitive.

    Self-navigates: if you are inside a channel/DM detail view, a thread, or a
    pushed sub-screen (where the bottom tab bar is hidden) it backs out first —
    popping the detail view (keyboard-up-safe) and, if that doesn't surface the
    bar, relaunching to the workspace root — so the target tab becomes tappable.
    Returns ``{ok: False, ...}`` for an unknown tab_name, and an honest
    ``ok: False`` failure string only if the tab is genuinely unreachable after
    recovery.
    """
    aid = TAB_MAP.get(tab_name.lower())
    if aid is None:
        # Return an explicit ok:False envelope (not a bare string): the message
        # "Unknown tab ..." does NOT match the wrapper's failure-prefix regex,
        # so a string return would be marked ok:true — a false positive for an
        # invalid input that performed no navigation.
        return {
            "ok": False,
            "action": "navigate_to_tab",
            "message": f"Unknown tab '{tab_name}'. Valid tabs: {', '.join(TAB_MAP.keys())}",
        }
    sim = SimulatorBridge.get()

    # Cold-state robustness: when the agent is inside a channel/DM detail view,
    # a thread, a search/info overlay, or a pushed sub-screen, the bottom tab
    # bar (and EVERY tab_* id) is HIDDEN, so a bare tap_and_observe(tab_*) raises
    # NoSuchElement and the tab tap fails (~40% of in-detail calls in live runs).
    # Surface the bar FIRST, escalating recovery only as needed so the happy
    # path (bar already up) is untouched:
    #   1) keyboard-up-safe back-pop (BackButton coord-tap / edge-swipe), x2 for
    #      nested pushes;
    #   2) if the bar STILL isn't reachable (a modal/overlay with no BackButton,
    #      or a pop that didn't land), relaunch to the workspace root — TeamChat
    #      always boots into RootTabView with the tab bar exposed, and its state
    #      is file-backed seed data so a relaunch is non-destructive.
    tree = sim.observe_text()
    if not _tab_bar_visible(tree):
        _pop_back_safe(sim, tree)
        sim.wait(0.4)
        tree = sim.observe_text()
        if not _tab_bar_visible(tree):
            # Some detail views nest two levels; pop once more before relaunch.
            _pop_back_safe(sim, tree)
            sim.wait(0.4)
            tree = sim.observe_text()
        if not _tab_bar_visible(tree):
            try:
                sim.launch_and_observe(BUNDLE_ID)
                sim.wait(0.6)
            except Exception:
                pass

    # Tap the tab. If the control still wasn't present (tap raised, e.g. a stale
    # tree), relaunch to force a clean rooted tab bar and retry once so a lazy
    # snapshot doesn't leak a false failure.
    try:
        ui = sim.tap_and_observe(aid)
    except Exception:
        try:
            sim.launch_and_observe(BUNDLE_ID)
            sim.wait(0.6)
        except Exception:
            pass
        if not _tab_bar_visible(sim.observe_text()):
            return {
                "ok": False,
                "action": "navigate_to_tab",
                "message": (
                    f"Could not switch to '{tab_name}' tab. The bottom tab bar "
                    "stayed unreachable even after backing out and relaunching "
                    "TeamChat to the workspace root."
                ),
            }
        try:
            ui = sim.tap_and_observe(aid)
        except Exception as exc:
            return {
                "ok": False,
                "action": "navigate_to_tab",
                "message": (
                    f"Could not switch to '{tab_name}' tab. Error: "
                    f"{str(exc)[:120]}"
                ),
            }
    return f"Navigated to '{tab_name}' tab.\n\n{ui}"


@mcp.tool()
def open_channel(channel_name: str) -> str:
    """Open a channel by name from the Home tab and return its UI tree.
    Works from any screen — self-navigates to Home first.

    Args:
      channel_name: the channel's DISPLAY NAME ('General'), slug ('general'),
        hyphen form ('eng-mobile'), or id. Resolved via _find_channel against
        seed state (case/hyphen-insensitive), so the human-readable name works
        — you do not need to slugify. From `list_channels()` you get the slug;
        either form is fine.

    Pops out of any open detail view, switches to Home, then taps the channel
    row (coordinate tap, since SwiftUI rows can no-op on id taps); retries with
    a scroll if the row was off-screen. Returns a failure string (no false
    success) if the channel detail view never appears (bad/absent name).
    """
    sim = SimulatorBridge.get()
    # If we're inside a channel/DM detail view, the bottom tab bar (and
    # tab_home) is hidden — pop back first so a repeated open_channel call
    # doesn't fail on a missing tab_home.
    tree = sim.observe_text()
    if "tab_home" not in tree:
        # Keyboard-up-safe back-pop: tap BackButton by coordinate (or edge
        # swipe), never an unguarded find_element that can hang with the
        # keyboard raised (e.g. right after a send_message).
        _pop_back_safe(sim, tree)
    try:
        sim.tap_id("tab_home")
    except Exception:
        pass
    sim.wait(0.5)
    # Slugify: the agent may pass a display name with caps/hyphens
    # ('Hiring Panel', 'eng-mobile') but the row id is the accessibility slug
    # ('hiring_panel', 'eng_mobile'). Resolve against seed state so a partial
    # or id-style input ('channel_eng_mobile') also lands on the right slug.
    slug = _slugify(channel_name)
    _sf, _state = _load_state()
    _ws, _ch = _find_channel(_state, channel_name)
    if not _ch:
        _ws, _ch = _find_channel(_state, slug)
    if _ch and _ch.get("channelName"):
        slug = _slugify(_ch.get("channelName"))
    target = f"channel_row_{slug}"
    channel_name = slug  # downstream label/target builders use the slug

    def _check_navigated(tree: str) -> bool:
        """Channel detail view exposes one of these IDs."""
        return (
            "send_message_button" in tree
            or "composer_text_field" in tree
            or "empty_channel_state" in tree
            or "message_row_" in tree
        )

    # Tap the channel row. WDA's accessibility-id tap silently no-ops on some
    # small SwiftUI NavigationLink rows (reproducible on general/hiring_panel)
    # even when fully on-screen, so prefer a coordinate tap whose center we
    # parse from the freshly-observed tree; fall back to the id tap.
    label_target = f"channel_name_{channel_name}"

    def _tap_row() -> str:
        tree = sim.observe_text()
        # Prefer the left-aligned label element's center: a full-width row's
        # geometric center can land in the trailing Spacer where SwiftUI does
        # not forward the tap (observed on #leadership, width-365 row), while
        # the label element is always over hittable content.
        center = _element_center(tree, label_target) or _element_center(tree, target)
        if center is not None:
            sim.tap_xy(center[0], center[1])
        else:
            try:
                sim.tap_id(target)
            except Exception:
                pass
        sim.wait(0.9)
        return sim.observe_text()

    ui = _tap_row()
    if not _check_navigated(ui):
        # One more try (positions settle after the tab switch / animations).
        ui = _tap_row()
    if not _check_navigated(ui):
        # Channel row may have been partially visible; scroll and retry.
        sim.swipe("up")
        sim.wait(0.4)
        ui = _tap_row()
    # After retry, re-check navigation. Return failure cleanly so the agent
    # doesn't keep calling open_channel with the same slug expecting state to
    # advance — it won't, the channel slug is wrong or not present.
    if not _check_navigated(ui):
        return (
            f"Could not open channel '{channel_name}'. The channel detail "
            "view did not appear after tap. Verify the channel via "
            "list_channels() or observe() and pick from visible "
            "channel_row_<slug> elements; the display name or the slug are "
            "both accepted."
        )
    return f"Opened channel '{channel_name}'.\n\n{ui}"


def _send_message_fill_form(text: str) -> Optional[str]:
    """Tap the composer in the open channel/DM and type `text` (no commit).

    Returns None on success or a precondition message on failure. Used by
    both `send_message` (one-shot commit) and `prepare_send_message`
    (capture-only). Stops short of tapping `send_message_button` /
    `send_dm_message_button` so the caller decides whether to commit.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("composer_text_field")
        sim.wait(0.3)
        sim.type_text(text)
        sim.wait(0.3)
        return None
    except Exception as exc:
        return (
            f"Composer field unavailable. Open a channel or DM first, then re-call. "
            f"{str(exc)[:120]}"
        )


def _commit_send() -> Optional[str]:
    """Tap Send for the open channel/DM after `_send_message_fill_form`.

    Keyboard-up-safe. The bug this fixes: with the keyboard raised, an
    accessibility-id ``tap_id("send_message_button")`` issues a WDA
    ``find_element`` that can HANG indefinitely in the accessibility
    snapshot (observed: 1000s+ stall). ``observe_text`` is the only WDA
    snapshot path that is timeout-guarded (60s) and self-healing
    (reconnect), and ``tap_xy`` is snapshot-free. So we:

      1. ``observe_text()`` once (bounded) to read the live tree,
      2. parse the Send button's *current* (keyboard-up) center, and
      3. ``tap_xy`` it — no ``find_element`` with the keyboard up.

    The button moves up when the keyboard rises, so the coordinate must be
    read from the post-typing tree (not pre-typing). Falls back to an
    accessibility-id tap only if the tree couldn't be read or the button
    isn't in it.

    Returns None on success, or a short error string when no Send control
    could be actuated.
    """
    sim = SimulatorBridge.get()
    tree = ""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if tree and not tree.startswith("[UI tree unavailable"):
        for aid in ("send_message_button", "send_dm_message_button"):
            if aid in tree:
                center = _element_center(tree, aid)
                if center is not None:
                    try:
                        sim.tap_xy(center[0], center[1]); sim.wait(0.4)
                        return None
                    except Exception:
                        break  # fall through to id taps
    # Tree unreadable or button not located: fall back to id taps (may
    # snapshot with the keyboard up, but only reached when coordinate tap
    # wasn't possible).
    try:
        sim.tap_id("send_message_button"); sim.wait(0.3)
        return None
    except Exception:
        pass
    try:
        sim.tap_id("send_dm_message_button"); sim.wait(0.3)
        return None
    except Exception as exc:
        return (
            "Send button not found in current UI; verify a channel or DM "
            f"composer is still open. {str(exc)[:100]}"
        )


@mcp.tool()
def send_message(text: str) -> str:
    """Type a message into the open channel/DM composer and tap Send.

    Args:
      text: message body (free text).

    Tries `send_message_button` first, falls back to
    `send_dm_message_button` (keyboard-up-safe coordinate tap). Precondition:
    a channel or DM must be open (use `open_channel` or `open_dm` first); if
    none is, returns ``{ok: False, ...}`` — no false success. To address a
    channel without pre-navigating, use `post_message_direct(channel, text)`.
    Legacy single-verb commit — prefer `prepare_send_message` +
    `confirm_send_message` for new code.
    """
    sim = SimulatorBridge.get()
    err = _send_message_fill_form(text)
    if err:
        # Return a proper ok:False envelope so a blind call (no channel/DM
        # open) is reported as a controlled failure, not a false success.
        # To address a message by channel without pre-navigating, use
        # post_message_direct(channel_name, text).
        return {"ok": False, "action": "send_message", "message": err}
    # Commit via the keyboard-up-safe path (coordinate tap captured before
    # typing), falling back to id taps. Avoids the WDA snapshot stall.
    send_err = _commit_send()
    if send_err:
        return {"ok": False, "action": "send_message", "message": send_err}
    ui = sim.observe_text()
    return f"Sent message: '{text}'.\n\n{ui}"


@mcp.tool()
def prepare_send_message(text: str) -> dict:
    """Tap the open channel/DM composer and pre-fill `text` WITHOUT sending.

    Args:
      text: message body (free text).

    Pass the returned ``draft_id`` to `confirm_send_message` to actually
    tap Send.

    Returns ``{ok: True, action, draft_id, summary, next}`` on success,
    or ``{ok: False, action, message}`` on precondition failure (no
    draft stored).

    Precondition: a channel or DM must be open (`composer_text_field`
    visible) — use `open_channel` or `open_dm` first. Drafts expire
    after `IOSWORLD_DRAFT_TTL_SECONDS` (default 10 minutes).
    """
    err = _send_message_fill_form(text)
    if err:
        return {"ok": False, "action": "prepare_send_message", "message": err}
    summary = {"text": text}
    draft_id = ts.create_draft("teamchat", "send_message", summary)
    return {
        "ok": True,
        "action": "prepare_send_message",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_send_message(draft_id) to commit.",
    }


@mcp.tool()
def confirm_send_message(draft_id: str) -> dict:
    """Commit a message previously staged by `prepare_send_message`.

    Args:
      draft_id: the id returned by `prepare_send_message` (must still
        be active — not consumed, not expired).

    Taps `send_message_button` (or falls back to `send_dm_message_button`).
    Returns ``{ok: True, action, evidence}`` on success, or a
    controlled-failure response (without tapping) if the draft is
    missing/expired or both Send buttons are gone.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_send_message",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_send_message first.",
        }
    # Commit via the keyboard-up-safe path (timeout-guarded observe +
    # coordinate tap), falling back to id taps.
    send_err = _commit_send()
    if send_err:
        return {
            "ok": False,
            "action": "confirm_send_message",
            "message": send_err,
        }
    return {
        "ok": True,
        "action": "confirm_send_message",
        "evidence": draft.get("payload", {}),
    }


@mcp.tool()
def open_dm(contact_name: str) -> str:
    """Open (or START) a DM on the DMs tab. Works from any screen.

    Args:
      contact_name: the person's DISPLAY NAME ('Riley Shah'), @username,
        slug ('riley_shah'), or a first/last-name substring ('riley') — also
        a group-DM conversation name. Resolved via _resolve_contact /
        _resolve_dm_target; the human-readable name works, no need to slugify.

    Self-navigates to the DMs tab (popping any open detail view). Opens the
    existing `dm_row_<slug>` if present; if NO thread exists yet, it STARTS one
    via the participant strip (`dm_member_quick_open_<username>`, which calls
    createDM). Returns a failure string (no false success) only when the
    contact can't be resolved at all.
    """
    sim = SimulatorBridge.get()
    # Pop back to the tab bar if we're inside a detail view (tab_dms hidden).
    tree = sim.observe_text()
    if "tab_dms" not in tree:
        # Keyboard-up-safe back-pop (avoids an unguarded find_element hang).
        _pop_back_safe(sim, tree)
    try:
        sim.tap_id("tab_dms"); sim.wait(0.5)
    except Exception:
        pass

    # Resolve the blind display NAME to the row slug + username. The agent
    # passes e.g. "Riley Shah" (not the slug "riley_shah"), and may target a
    # contact with no existing DM thread at all (e.g. "Aiden Cross"), so we
    # self-resolve against seed state.
    _sf, state = _load_state()
    disp, slug, username = _resolve_dm_target(state, contact_name)
    # Fall back to a raw slugify so a literal slug/name still works even if the
    # contact isn't in seed (keeps a path for unusual inputs).
    if slug is None:
        slug = _slugify(contact_name)
        disp = contact_name

    # 1. Existing 1:1 / group DM row. Prefer a coordinate tap (SwiftUI rows
    #    no-op on id taps); scroll the DM list if the row is off-screen.
    for attempt in range(3):
        tree = sim.observe_text()
        row_aid = f"dm_row_{slug}"
        if row_aid in tree:
            if not _coord_tap_from_tree(sim, tree, row_aid):
                try:
                    sim.tap_id(row_aid)
                except Exception:
                    pass
            sim.wait(0.9)
            ui = sim.observe_text()
            if _dm_navigated(ui):
                return f"Opened DM with '{disp}'.\n\n{ui}"
            # Tapped but no nav; break to the start-DM path.
            break
        if attempt < 2:
            sim.swipe("up"); sim.wait(0.4)

    # 2. No existing thread (or row tap didn't navigate): START the DM via the
    #    participant strip, which lists every member and calls createDM. This
    #    is the key fix — open_dm must be able to begin a conversation, not
    #    only re-open an existing one.
    if username:
        # Make sure we're back on the DM list (the row attempt scrolled it).
        try:
            sim.tap_id("tab_dms"); sim.wait(0.4)
        except Exception:
            pass
        if _open_dm_via_member_strip(sim, username):
            ui = sim.observe_text()
            return f"Opened DM with '{disp}'.\n\n{ui}"

    return (
        f"Could not open or start a DM with '{contact_name}'. No matching "
        "contact was found in the workspace. Use list_dms()/observe() to see "
        "the participant strip (dm_member_quick_open_<username>) and existing "
        "dm_row_<slug> rows."
    )


@mcp.tool()
def search_messages(query: str) -> str:
    """Run a workspace message search via the Search tab. Works from any
    screen — self-navigates to Search first.

    Args:
      query: free-text search query.

    Pops out of any open channel/DM detail view (where the tab bar is hidden),
    opens the Search tab, types into `search_query_field`, taps
    `search_submit_button`, and returns the resulting UI tree. Returns a
    failure string if the Search tab stayed unreachable.
    """
    sim = SimulatorBridge.get()
    # Cold-state robustness: inside a channel/DM detail view the tab bar (and
    # tab_search) is HIDDEN, so tap_id("tab_search") raises NoSuchElement and
    # search dies. Pop the detail first (keyboard-up-safe) so the tab bar
    # re-renders. (Other overlays keep the tab bar visible.)
    tree = sim.observe_text()
    if "tab_search" not in tree:
        _pop_back_safe(sim, tree)
        sim.wait(0.4)
    try:
        sim.tap_id("tab_search")
        sim.wait(0.5)
    except Exception:
        # One more pop in case a detail view was nested, then retry the tab.
        tree = sim.observe_text()
        if "tab_search" not in tree:
            _pop_back_safe(sim, tree)
            sim.wait(0.4)
        try:
            sim.tap_id("tab_search"); sim.wait(0.5)
        except Exception as exc:
            return (
                f"Could not search team messages for '{query}'. The Search tab "
                f"was not reachable. Error: {str(exc)[:100]}"
            )
    try:
        sim.tap_id("search_query_field")
        sim.wait(0.3)
        sim.type_text(query)
        sim.wait(0.3)
        ui = sim.tap_and_observe("search_submit_button")
    except Exception as exc:
        return f"Could not search team messages for '{query}'. Open the workspace first. Error: {str(exc)[:120]}"
    return f"Searched for '{query}'.\n\n{ui}"


def _thread_state_writeback(message_id: str, text: str) -> dict:
    """Append a thread reply directly into seed state (authoritative fallback).

    Used when the live thread UI can't be driven. Returns an ``{ok: ...}``
    envelope. Resolves the parent message by exact id only.
    """
    state_file, state = _load_state()
    ws, ch, msg = _find_message(state, message_id)
    if not msg:
        return {
            "ok": False,
            "action": "reply_to_thread",
            "message": f"No message '{message_id}' for thread reply.",
        }
    replies = msg.setdefault("threadReplies", [])
    seq = ws.get("nextMessageSequence", len(replies) + 1)
    reply_id = f"{message_id}_r{len(replies) + 1}"
    replies.append({
        "id": reply_id,
        "parentMessageId": message_id,
        "messageText": text,
        "senderId": "member_jordan_avery",
        "senderDisplayName": "Jordan Avery",
        "attachments": [],
        "reactions": [],
        "timestamp": "2026-05-12T00:00:00Z",
    })
    msg["replyCount"] = len(replies)
    ws["nextMessageSequence"] = seq + 1
    _save_state(state_file, state)
    return {
        "ok": True,
        "action": "reply_to_thread",
        "channel": ch.get("channelName"),
        "message_id": message_id,
        "reply_id": reply_id,
        "threadReplies": len(replies),
    }


@mcp.tool()
def reply_to_thread(message_id: str = "", text: str = "", message_text: str = "") -> dict:
    """Post a reply in the thread of a specific channel message.

    Identify the parent message EITHER way (precondition: open the parent
    channel via `open_channel` first so its messages are on screen):

      • message_text: a substring of the message body you want to reply to
        (e.g. "Dark mode color tokens"). RECOMMENDED — you do not need to know
        any id. The tool scrolls the open channel, matches it to the right
        `message_row_<id>`, and opens that thread for you.
      • message_id: the bare `<id>` from a `message_row_<id>` /
        `open_thread_button_<id>` element in observe() (e.g. 'msg_088'). You
        may also paste the FULL element name ('message_row_msg_088') — the
        wrapping prefix is stripped automatically. Do NOT invent an id; ids
        come ONLY from `message_row_<id>` in the live observe() tree.

    Args:
      message_id: parent message id (or full message_row_<id> element name).
      text: reply body (free text). Required.
      message_text: substring of the parent message body (alternative to
        message_id; resolved against the live channel + seed state).

    Auto-opens the thread (`open_thread_button_<id>`), types into
    `thread_reply_composer_field`, and taps `thread_send_reply_button`
    (keyboard-up-safe). Verified against state: returns
    ``{ok: True, threadReplies: N}`` only after the parent message's reply
    count actually grows; falls back to a seed-state write if the live thread
    UI can't be driven. Returns ``{ok: False, message}`` if neither a
    message_id nor a message_text resolves to a real message — no false
    success on a hallucinated id.
    """
    if not (text or "").strip():
        return {"ok": False, "action": "reply_to_thread", "message": "reply text is required"}

    sim = SimulatorBridge.get()
    resolved_id: Optional[str] = None

    # 1. Content-based resolution (preferred): scroll the open channel to find
    #    the message whose visible body contains `message_text`, mapping it to
    #    the real message_row_<id>. This is the provenance fix — the agent need
    #    not know any id.
    if (message_text or "").strip():
        resolved_id, _tree = _scroll_find_message_by_text(sim, message_text)
        if not resolved_id:
            # Not on screen anywhere; fall back to full seed text to get the id.
            _sf, _state = _load_state()
            _ws, _ch, _msg = _resolve_message_in_state_by_text(_state, message_text)
            if _msg:
                resolved_id = _msg.get("id")

    # 2. Id path: normalize a pasted element name to the bare id, and accept it
    #    only if it actually exists (live tree OR seed) — never a hallucinated id.
    if not resolved_id and (message_id or "").strip():
        cand = _normalize_message_id(message_id)
        tree = sim.observe_text()
        if f"message_row_{cand}" in tree or f"open_thread_button_{cand}" in tree:
            resolved_id = cand
        else:
            _sf, _state = _load_state()
            _ws, _ch, _msg = _find_message(_state, cand)
            if _msg:
                resolved_id = cand

    if not resolved_id:
        hint = "message_text" if (message_text or "").strip() else "message_id"
        return {
            "ok": False,
            "action": "reply_to_thread",
            "message": (
                f"Could not resolve a parent message from {hint}="
                f"'{message_text or message_id}'. Open the channel via "
                "open_channel(), then pass message_text=<a substring of a "
                "visible message> OR message_id=<the bare id from a "
                "message_row_<id> element in observe()>. Do not invent ids."
            ),
        }

    # Snapshot the current thread-reply count for an honest verification.
    def _reply_count(mid: str) -> Optional[int]:
        _sf, st = _load_state()
        _w, _c, m = _find_message(st, mid)
        if not m:
            return None
        return len(m.get("threadReplies", []) or [])

    before = _reply_count(resolved_id)

    # 3. Drive the real thread UI. Scroll the thread button into view first so
    #    a row above/below the viewport still works.
    try:
        found, tree = _scroll_id_onscreen(sim, f"open_thread_button_{resolved_id}")
        opened = False
        thread_aid = f"open_thread_button_{resolved_id}"

        def _thread_open() -> bool:
            tu = sim.observe_text() or ""
            return "thread_reply_composer_field" in tu or "thread_send_reply_button" in tu

        if found:
            # Coordinate tap first (SwiftUI buttons can no-op on id taps); if the
            # thread doesn't open (e.g. the row sat at the very top edge so the
            # center tap landed under the header), retry with the id tap.
            _coord_tap_from_tree(sim, tree, thread_aid)
            sim.wait(0.6)
            opened = _thread_open()
            if not opened:
                try:
                    sim.tap_id(thread_aid); sim.wait(0.6)
                    opened = _thread_open()
                except Exception:
                    pass
        if opened:
            sim.tap_id("thread_reply_composer_field"); sim.wait(0.3)
            sim.type_text(text); sim.wait(0.3)
            # Keyboard-up-safe commit: coordinate-tap the reply Send button.
            ui = sim.observe_text() or ""
            committed = False
            if ui and not ui.startswith("[UI tree unavailable") and "thread_send_reply_button" in ui:
                center = _element_center(ui, "thread_send_reply_button")
                if center is not None:
                    sim.tap_xy(center[0], center[1]); sim.wait(0.5)
                    committed = True
            if not committed:
                sim.tap_id("thread_send_reply_button"); sim.wait(0.4)
            sim.wait(0.5)
            after = _reply_count(resolved_id)
            if before is not None and after is not None and after > before:
                _pop_back_safe(sim, sim.observe_text())
                return {
                    "ok": True,
                    "action": "reply_to_thread",
                    "message_id": resolved_id,
                    "threadReplies": after,
                    "text": text,
                }
            # UI tapped but state didn't grow — fall through to write-back.
    except Exception:
        pass

    # 4. Authoritative fallback: write the reply into seed state.
    return _thread_state_writeback(resolved_id, text)


@mcp.tool()
def list_channels() -> dict:
    """Scrape channel slugs visible on the Home tab. Works from any screen.

    Self-navigates to Home (popping any open channel/DM detail view, where the
    tab bar and channel rows are hidden), then returns ``{"channels": [slug,
    ...], "count": n}``. Slugs feed `open_channel`, `mute_channel`,
    `star_channel`, and `mark_channel_read` (those also accept the display
    name). Only channels currently rendered in the list are returned; scroll
    via observe() if you expect more than fit on screen.
    """
    import re
    sim = SimulatorBridge.get()
    # Cold-state robustness: if we're inside a channel/DM detail view the tab
    # bar (and tab_home) is HIDDEN, so tap_id("tab_home") raises NoSuchElement
    # and we'd scrape an empty tree -> false "0 channels". Pop the detail first
    # (keyboard-up-safe) so the Home channel list re-renders. Search/other-tab
    # overlays keep the tab bar visible, so tab_home is tappable there.
    tree = sim.observe_text()
    if "tab_home" not in tree:
        _pop_back_safe(sim, tree)
        sim.wait(0.4)
    try:
        sim.tap_id("tab_home"); sim.wait(0.4)
    except Exception:
        pass
    tree = sim.observe_text()
    # If still no channel rows (e.g. an overlay remained), pop once more and
    # re-read so enumeration reflects the real Home list, not a stale overlay.
    if "channel_row_" not in tree:
        _pop_back_safe(sim, tree)
        sim.wait(0.4)
        try:
            sim.tap_id("tab_home"); sim.wait(0.4)
        except Exception:
            pass
        tree = sim.observe_text()
    slugs = sorted(set(re.findall(r'channel_row_([^"\s]+)', tree)))
    return {"channels": slugs, "count": len(slugs)}


@mcp.tool()
def list_channel_messages(channel_name: str, page: int = 1, page_size: int = 50, query: str = "") -> dict:
    """List messages for a channel from the full TeamChat state.

    Args:
      channel_name: display name, slug, hyphen form, or channel id accepted by
        ``open_channel`` / ``_find_channel``.
      page/page_size: bounded pagination to avoid truncated tool output.
      query: optional case-insensitive substring filter over message text,
        sender, id, and timestamp.

    Returns ``{channel, channel_id, messages, count, returned_count, page,
    page_size, has_more, next_page}``. Message ids can be passed to
    ``reply_to_thread`` / ``add_reaction``.
    """
    _state_file, state = _load_state()
    _ws, ch = _find_channel(state, channel_name)
    if not ch:
        return {
            "ok": False,
            "message": (
                f"Channel '{channel_name}' was not found. Call list_channels() "
                "or pass a display name/slug such as 'general'."
            ),
        }
    rows = [_message_row(m) for m in ch.get("messages", []) if isinstance(m, dict)]
    needle = (query or "").strip().lower()
    if needle:
        rows = [
            r for r in rows
            if needle in " ".join(str(r.get(k, "")) for k in (
                "id", "sender", "sender_id", "text", "timestamp"
            )).lower()
        ]
    rows.sort(key=lambda r: str(r.get("timestamp") or ""))
    page_rows, meta = _paginate(rows, page, page_size)
    return {
        **meta,
        "channel": ch.get("channelName"),
        "channel_id": ch.get("id"),
        "query": query,
        "messages": page_rows,
    }


@mcp.tool()
def list_dms() -> str:
    """Open the DMs tab, then call `observe()` to read the DM list and the
    participant strip (`dm_member_quick_open_<username>`).

    Unlike the other tab tools this does NOT pop out of an open channel/DM
    detail view first, so call it from a tab/list screen (or use
    `navigate_to_tab('dms')`, which self-recovers). To open a specific DM use
    `open_dm(name)`, which self-navigates and can also start a new thread.
    """
    sim = SimulatorBridge.get()
    sim.tap_id("tab_dms"); sim.wait(0.4)
    return "Opened DMs tab."


@mcp.tool()
def mute_channel(channel_slug: str) -> str:
    """Mute a channel by tapping its `channel_mute_action_<slug>` action.

    Args:
      channel_slug: the channel slug from `list_channels()` (e.g. 'general',
        'random'). The seed-state fallback resolves via _find_channel, so a
        display name / hyphen form / id also work there. NOTE: the primary UI
        tap builds the id from this string verbatim (no slugify), so for the
        UI path pass the exact slug; the fallback covers other forms.

    Falls back to writing `isMuted=True` directly into seed state if the UI
    action isn't reachable, returning ``{ok: True, channel, isMuted}``; returns
    a failure string if the channel can't be found at all.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id(f"channel_mute_action_{channel_slug}"); sim.wait(0.3)
        return f"Muted channel '{channel_slug}'."
    except Exception as exc:
        state_file, state = _load_state()
        _ws, ch = _find_channel(state, channel_slug)
        if not ch:
            return f"No channel '{channel_slug}' to mute. Error: {str(exc)[:120]}"
        ch["isMuted"] = True
        _save_state(state_file, state)
        return {"ok": True, "action": "mute_channel", "channel": ch.get("channelName"), "isMuted": True}


@mcp.tool()
def star_channel(channel_slug: str) -> str:
    """Toggle a channel's starred (favorite) flag.

    Args:
      channel_slug: the channel slug from `list_channels()` (e.g. 'general').
        The seed-state fallback resolves via _find_channel, so a display
        name / hyphen form / id also work there; the UI tap uses the string
        verbatim, so pass the exact slug for the UI path.

    Taps `channel_star_action_<slug>`; falls back to TOGGLING `isStarred`
    directly in seed state if the UI action isn't reachable, returning
    ``{ok: True, channel, isStarred}``. Returns a failure string if the
    channel can't be found.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id(f"channel_star_action_{channel_slug}"); sim.wait(0.3)
        return f"Starred channel '{channel_slug}'."
    except Exception as exc:
        state_file, state = _load_state()
        _ws, ch = _find_channel(state, channel_slug)
        if not ch:
            return f"No channel '{channel_slug}' to star. Error: {str(exc)[:120]}"
        ch["isStarred"] = not bool(ch.get("isStarred", False))
        _save_state(state_file, state)
        return {"ok": True, "action": "star_channel", "channel": ch.get("channelName"), "isStarred": ch["isStarred"]}


@mcp.tool()
def mark_channel_read(channel_slug: str) -> str:
    """Mark a channel as read (clears mentions and unread message flags).

    Args:
      channel_slug: the channel slug from `list_channels()` (e.g. 'general').
        The seed-state fallback resolves via _find_channel, so a display
        name / hyphen form / id also work there; the UI tap uses the string
        verbatim, so pass the exact slug for the UI path.

    Taps `channel_read_action_<slug>`; falls back to clearing `mentionCount`
    and every message's `isUnread` in seed state if the UI action isn't
    reachable, returning ``{ok: True, channel, mentionCount: 0}``. Returns a
    failure string if the channel can't be found.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id(f"channel_read_action_{channel_slug}"); sim.wait(0.3)
        return f"Marked '{channel_slug}' as read."
    except Exception as exc:
        state_file, state = _load_state()
        _ws, ch = _find_channel(state, channel_slug)
        if not ch:
            return f"No channel '{channel_slug}' to mark read. Error: {str(exc)[:120]}"
        ch["mentionCount"] = 0
        for msg in ch.get("messages", []):
            msg["isUnread"] = False
        _save_state(state_file, state)
        return {"ok": True, "action": "mark_channel_read", "channel": ch.get("channelName"), "mentionCount": 0}


def _ensure_channel_open(sim, channel_name: str = "") -> bool:
    """Make sure a channel detail view is on screen.

    If the composer/info button is already visible, do nothing. Otherwise, if
    a `channel_name` was supplied, self-navigate by opening it (slug-tolerant).
    Returns True if a channel detail view is (now) open.
    """
    tree = sim.observe_text()
    if "channel_info_button" in tree or "composer_text_field" in tree:
        return True
    if (channel_name or "").strip():
        res = open_channel.fn(channel_name) if hasattr(open_channel, "fn") else open_channel(channel_name)
        if "Opened channel" in str(res):
            return True
    tree = sim.observe_text()
    return "channel_info_button" in tree or "composer_text_field" in tree


@mcp.tool()
def open_channel_info(channel_name: str = "") -> str:
    """Open the channel-info panel (name, description, members).

    Args:
      channel_name: optional channel display name or slug (case/hyphen-
        insensitive, resolved via _find_channel). If a channel detail view is
        already open, leave it blank; otherwise the tool self-navigates and
        opens this channel first (works from a fresh launch).

    Taps `channel_info_button`. Returns a failure string if nothing is open
    and no channel_name was given.
    """
    sim = SimulatorBridge.get()
    if not _ensure_channel_open(sim, channel_name):
        return (
            "No channel is open and no channel_name was given to self-open. "
            "Pass channel_name (e.g. 'general') or call open_channel first."
        )
    try:
        sim.tap_id("channel_info_button"); sim.wait(0.4)
    except Exception as exc:
        return f"No channel info button found. Open a channel first. Error: {str(exc)[:120]}"
    return "Opened channel info."


@mcp.tool()
def toggle_channel_notifications(channel_name: str = "") -> str:
    """Flip a channel's per-channel notifications (notifyOnAllMessages).

    Args:
      channel_name: the channel slug or display name to edit (e.g. 'general',
        'random'). Resolved via _find_channel (name/slug/hyphen/id). REQUIRED
        in practice: if omitted it defaults to 'general', so always pass the
        channel you mean. Returns ``{ok: False, error}`` if it can't resolve.

    This is an authoritative deterministic flip: it reads the current flag
    from state, does one best-effort cosmetic tap on
    `channel_notifications_toggle` IF the info panel happens to be open, then
    writes the absolute target value `not before` to state (idempotent w.r.t.
    the UI tap). No precondition — you do NOT need to open the info panel
    first; this works from any screen. Returns
    ``{ok: True, channel, notifyOnAllMessages}``.
    """
    # Authoritative deterministic flip. Capture the channel's current notify flag
    # from state BEFORE any UI tap, do one best-effort cosmetic tap, then write
    # the absolute target `not before`. Writing an absolute value (rather than
    # re-toggling the post-tap value) is idempotent w.r.t. the UI tap, so there's
    # no double-toggle even if the switch also flips. Pass channel_name so we
    # edit the channel you opened (defaults to #general otherwise).
    state_file, state = _load_state()
    target = (channel_name or "").strip() or "general"
    ws, ch = _find_channel(state, target)
    if not ch:
        return {"ok": False, "error": f"Channel '{target}' is unavailable"}
    before = bool(ch.get("notifyOnAllMessages", True))
    sim = SimulatorBridge.get()
    tree = sim.observe_text()
    if "channel_notifications_toggle" in tree:
        try:
            _tap_switch_thumb(sim, tree, "channel_notifications_toggle"); sim.wait(0.3)
        except Exception:
            pass
    ch["notifyOnAllMessages"] = not before
    ch["notificationsEnabled"] = ch["notifyOnAllMessages"]
    _save_state(state_file, state)
    return {"ok": True, "action": "toggle_channel_notifications", "channel": ch.get("channelName"), "notifyOnAllMessages": ch["notifyOnAllMessages"]}


@mcp.tool()
def add_workspace(name: str, description: str = "") -> str:
    """Create a new workspace via the add-workspace form.

    Args:
      name: user-facing display name (required, non-empty).
      description: accepted for compatibility but ignored — this app's
        add-workspace form has only a name field (the "description" element
        is a static info note, and store.addWorkspace takes only a name).

    Drives the real UI: opens the workspace switcher
    (`workspace_switcher_button`) and the add sheet (`workspace_add_button`)
    if the form isn't already visible, fills `add_workspace_name_field`
    (and `add_workspace_description` if provided), then taps
    `add_workspace_confirm_button`. Verifies the workspace actually appears
    in app state afterward.

    Note: this app re-seeds its workspace LIST on launch, so a direct
    state-file write of a new workspace does NOT survive a reload — only the
    UI flow creates a persistent workspace, which is why there is no
    state-write fallback here.
    """
    workspace_name = (name or "").strip()
    if not workspace_name:
        return {"ok": False, "action": "add_workspace", "message": "workspace name is required"}

    sim = SimulatorBridge.get()
    # Navigate to the add-workspace form if it isn't already open.
    tree = sim.observe_text()
    if "add_workspace_name_field" not in tree:
        try:
            sim.tap_id("tab_home"); sim.wait(0.4)
        except Exception:
            pass
        try:
            sim.tap_id("workspace_switcher_button"); sim.wait(0.7)
            sim.tap_id("workspace_add_button"); sim.wait(0.7)
        except Exception as exc:
            return {
                "ok": False,
                "action": "add_workspace",
                "message": (
                    "Could not open the add-workspace form. From Home, tap "
                    "workspace_switcher_button then workspace_add_button. "
                    f"{str(exc)[:100]}"
                ),
            }

    try:
        # The form has only a name field; `description` has no editable input
        # in this app (the description element is a static info note), so we
        # intentionally do not type it anywhere — typing it would corrupt the
        # workspace name.
        sim.tap_id("add_workspace_name_field"); sim.wait(0.3); sim.type_text(workspace_name); sim.wait(0.2)
        sim.tap_id("add_workspace_confirm_button"); sim.wait(1.0)
    except Exception as exc:
        return {
            "ok": False,
            "action": "add_workspace",
            "message": f"Add-workspace form was not fully usable: {str(exc)[:120]}",
        }

    # Verify the workspace persisted into app state.
    _sf, state = _load_state()
    created = next(
        (ws for ws in state.get("seededWorkspaces", [])
         if ws.get("workspaceName", "").strip().lower() == workspace_name.lower()),
        None,
    )
    if created is None:
        return {
            "ok": False,
            "action": "add_workspace",
            "message": f"Tapped confirm but workspace '{workspace_name}' did not appear in app state.",
        }
    return {
        "ok": True,
        "action": "add_workspace",
        "workspace_id": created.get("id"),
        "name": created.get("workspaceName"),
        "created": True,
    }


def _open_composer_attachment_menu() -> None:
    """Expand the paperclip Menu in the channel detail composer so the
    image/pdf/link options become tappable.

    The attachment options (composer_add_image_attachment,
    composer_add_pdf_attachment, composer_add_link_attachment) live inside
    a SwiftUI Menu whose label is `composer_add_attachment_button`
    (ChannelDetailView.swift line 275). Until the menu is expanded those
    options are not in the XCUITest tree, so any `tap_id` against them
    surfaces as a precondition failure. Tap the paperclip first and give
    the menu a beat to present.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("composer_add_attachment_button"); sim.wait(0.4)
    except Exception:
        # Menu may already be open, or the channel composer isn't on
        # screen — let the downstream tap surface the precondition error.
        pass


def _attach_to_message(option_aid: str, label: str, channel_name: str) -> str:
    """Shared body for the three attach tools: self-open a channel if needed,
    expand the paperclip menu, then tap the requested attachment option."""
    sim = SimulatorBridge.get()
    if not _ensure_channel_open(sim, channel_name):
        return (
            f"No channel composer is open and no channel_name was given to "
            f"self-open. Pass channel_name (e.g. 'general') or open_channel first."
        )
    _open_composer_attachment_menu()
    try:
        sim.tap_id(option_aid); sim.wait(0.3)
    except Exception as exc:
        return f"Could not open {label} attachment. {str(exc)[:120]}"
    return f"Opened {label} attachment."


@mcp.tool()
def attach_image_to_message(channel_name: str = "") -> str:
    """Tap the image-attachment button (`composer_add_image_attachment`).

    Args:
      channel_name: optional channel slug/display name; if no channel
        composer is open, the tool self-navigates and opens it first.

    Expands the paperclip menu (`composer_add_attachment_button`) so the
    image option is reachable, then taps it.
    """
    return _attach_to_message("composer_add_image_attachment", "image", channel_name)


@mcp.tool()
def attach_pdf_to_message(channel_name: str = "") -> str:
    """Tap the PDF-attachment button (`composer_add_pdf_attachment`).

    Args:
      channel_name: optional channel slug/display name; if no channel
        composer is open, the tool self-navigates and opens it first.

    Expands the paperclip menu (`composer_add_attachment_button`) so the
    PDF option is reachable, then taps it.
    """
    return _attach_to_message("composer_add_pdf_attachment", "PDF", channel_name)


@mcp.tool()
def attach_link_to_message(channel_name: str = "") -> str:
    """Tap the link-attachment button (`composer_add_link_attachment`).

    Args:
      channel_name: optional channel slug/display name; if no channel
        composer is open, the tool self-navigates and opens it first.

    Expands the paperclip menu (`composer_add_attachment_button`) so the
    link option is reachable, then taps it.
    """
    return _attach_to_message("composer_add_link_attachment", "link", channel_name)


@mcp.tool()
def add_reaction(message_id: str) -> str:
    """Open the reaction picker on a specific message (or add 👍 in seed state).

    Args:
      message_id: EXACT message id — the `<id>` from an
        `add_reaction_button_<id>` / `message_row_<id>` element in the open
        channel's UI tree (via observe()). The seed-state fallback matches
        this id exactly; it is not a display name.

    Taps `add_reaction_button_<message_id>` (opens the picker); falls back to
    appending a 👍 reaction directly in seed state if the UI action isn't
    reachable, returning ``{ok: True, ...}``. Returns a failure string if the
    id matches no message. Precondition: open the channel containing the
    message first (via `open_channel`) so its id is visible.
    """
    sim = SimulatorBridge.get()
    err = sim.tap_and_verify_changed(
        f"add_reaction_button_{message_id}",
        prefix_for_failure=f"Could not open reactions for message '{message_id}'. ",
        settle=0.3,
    )
    if err is None:
        return f"Opened reactions for message {message_id}."
    # Shared-state fallback: append 👍 directly in seed state.
    exc_str = str(err)[:120]
    state_file, state = _load_state()
    _ws, ch, msg = _find_message(state, message_id)
    if not msg:
        return f"No message '{message_id}' to react to. Error: {exc_str}"
    reactions = msg.setdefault("reactions", [])
    existing = next((r for r in reactions if r.get("reactionEmoji") == "👍"), None)
    if existing:
        users = existing.setdefault("userIds", [])
        if "member_jordan_avery" not in users:
            users.append("member_jordan_avery")
        existing["reactionCount"] = len(users)
    else:
        reactions.append({"reactionEmoji": "👍", "reactionCount": 1, "userIds": ["member_jordan_avery"]})
    _save_state(state_file, state)
    return {"ok": True, "action": "add_reaction", "channel": ch.get("channelName"), "message_id": message_id, "reaction": "👍"}




# ── Post a message to a channel addressed by name (navigates the UI for you).
#
# NOTE: a direct JSON write of a NEW message does NOT survive — this app
# re-seeds each channel's message array on launch and reload_app() reverts the
# injected message. So this tool drives the real send UI (open the channel,
# type into the composer, tap Send), which the app persists, and verifies the
# text landed in app state.

@mcp.tool()
def post_message_direct(channel_name: str, text: str) -> dict:
    """Post a message to a channel by name, navigating the UI for you.

    Args:
      channel_name: the channel's display name or slug (e.g. 'General' or
        'general'); resolved via open_channel/_find_channel, so either form
        works.
      text: message body (free text).

    Opens the named channel (Home tab, self-navigating from any screen) and
    sends `text` through the real composer, then confirms the message appears
    in app state. Returns
    ``{ok, channel, message}`` on success or ``{ok: False, message}`` if
    the channel can't be opened or the send didn't persist. (Direct
    state-file injection is not used: the app re-seeds channel messages on
    launch and would discard it.)
    """
    if not (text or "").strip():
        return {"ok": False, "action": "post_message_direct", "message": "message text is required"}

    sim = SimulatorBridge.get()
    opened = open_channel.fn(channel_name) if hasattr(open_channel, "fn") else open_channel(channel_name)
    opened_str = str(opened)
    if "Opened channel" not in opened_str:
        return {
            "ok": False,
            "action": "post_message_direct",
            "message": f"Could not open channel '{channel_name}'. {opened_str[:160]}",
        }

    err = _send_message_fill_form(text)
    if err:
        return {"ok": False, "action": "post_message_direct", "message": err}
    # Keyboard-up-safe commit (coordinate tap captured before typing).
    send_err = _commit_send()
    if send_err:
        return {
            "ok": False,
            "action": "post_message_direct",
            "message": f"After opening '{channel_name}': {send_err}",
        }
    sim.wait(0.6)

    # Verify the message persisted in app state.
    _sf, state = _load_state()
    _ws, ch = _find_channel(state, channel_name)
    landed = bool(ch) and any(
        (m.get("messageText") or "") == text for m in ch.get("messages", [])
    )
    if not landed:
        # The UI showed the send; state read can lag a beat. Re-check once.
        _sf, state = _load_state()
        _ws, ch = _find_channel(state, channel_name)
        landed = bool(ch) and any(
            (m.get("messageText") or "") == text for m in ch.get("messages", [])
        )
    return {
        "ok": bool(landed),
        "action": "post_message_direct",
        "channel": ch.get("channelName") if ch else channel_name,
        "message": (
            f"Posted to #{ch.get('channelName')}: '{text[:60]}'" if landed
            else f"Tapped Send in '{channel_name}' but could not confirm the message in state."
        ),
    }

if __name__ == "__main__":
    mcp.run()
