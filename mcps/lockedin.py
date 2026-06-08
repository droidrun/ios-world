"""LockedIn MCP — LinkedIn-style social: feed, post, messaging, network, jobs.

Bundle: com.iosworld.benchmark.lockedin

ID conventions (see LockedIn/Views/):
  Tabs (by label):    Home (feed), My Network, Post (compose), Notifications, Jobs
                      (the inner tab_home/tab_network/... IDs do NOT propagate to
                      the tab-bar buttons in SwiftUI)
  Home: home_search_bar, home_messaging_button, home_profile_avatar
  Compose: compose_text_editor, compose_post_button, compose_dismiss_button,
           compose_audience_button, compose_photo_button, compose_calendar_button,
           compose_schedule_clock_button, compose_more_button,
           compose_attachment_<id>, remove_attachment_<id>
  Schedule: schedule_date_picker, schedule_done_button, schedule_cancel_button,
            schedule_indicator, remove_schedule_button, remove_schedule_indicator
  Link attachment: link_title_field, link_subtitle_field
  Post detail/actions: detail_attachment_<id>, detail_scheduled_badge_<post_id>,
                      post_action_<label>, post_attachment_<id>, post_scheduled_badge_<post_id>
  Messaging: messaging_conversation_row_<contact_name_slug>, messaging_search_field,
             chat_message_field, chat_send_button
  Jobs:      jobs_search_field
  Slug rule: contact names lowercased + spaces->underscores
             (e.g. ``rachel_torres``, ``devon_hart``)
"""

import sys, pathlib, re
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import _data_layer as dl
import tool_support as ts

from fastmcp import FastMCP
from simulator_base import SimulatorBridge

mcp = FastMCP("LockedIn")

BUNDLE_ID = "com.iosworld.benchmark.lockedin"
SEED_DATA_PATH = pathlib.Path(__file__).resolve().parents[1] / "iphone/apps/lockedin/xproj/LockedIn/Utilities/SeedDataFactory.swift"

TAB_MAP = {
    # SwiftUI TabView tab-bar buttons are addressable by their visible Label
    # text (the tab_<name> accessibility IDs on the content don't propagate
    # up to the tab bar item — known SwiftUI limitation).
    "home": "Home", "feed": "Home",
    "network": "My Network", "mynetwork": "My Network",
    "post": "Post", "compose": "Post",
    "notifications": "Notifications", "alerts": "Notifications",
    "jobs": "Jobs",
}


def _job_catalog() -> list[dict]:
    """Parse seed job ids/titles/companies from SeedDataFactory.swift."""
    try:
        text = SEED_DATA_PATH.read_text()
    except Exception:
        return []
    jobs: list[dict] = []
    pat = re.compile(
        r'Job\(id:\s*"([^"]+)",\s*title:\s*"([^"]+)",\s*'
        r'company:\s*"([^"]+)".*?location:\s*"([^"]+)".*?'
        r'locationType:\s*\.([A-Za-z]+)',
        re.S,
    )
    for job_id, title, company, location, location_type in pat.findall(text):
        jobs.append({
            "id": job_id,
            "title": title,
            "company": company,
            "location": location,
            "location_type": location_type,
        })
    return jobs


def _notification_catalog() -> list[dict]:
    """Parse seed notifications from SeedDataFactory.swift."""
    try:
        text = SEED_DATA_PATH.read_text()
    except Exception:
        return []
    block = re.search(
        r"static let allNotifications: \[LockedInNotification\] = \[(.*?)\n    \]",
        text,
        re.S,
    )
    if not block:
        return []
    notifications: list[dict] = []
    pat = re.compile(
        r'LockedInNotification\(\s*'
        r'id:\s*"([^"]+)",\s*type:\s*\.([A-Za-z]+),.*?'
        r'actorName:\s*"([^"]+)".*?'
        r'message:\s*"((?:[^"\\]|\\.)*)",\s*'
        r'timeAgo:\s*"([^"]+)",\s*isRead:\s*(true|false).*?'
        r'actionLabel:\s*(?:"([^"]+)"|nil)'
        r'(?:,\s*relatedPostId:\s*"([^"]+)")?',
        re.S,
    )
    for match in pat.findall(block.group(1)):
        notif_id, notif_type, actor, message, time_ago, is_read, action, related = match
        notifications.append({
            "id": notif_id,
            "type": notif_type,
            "actor": actor,
            "message": message.replace(r"\"", '"'),
            "time_ago": time_ago,
            "is_read": is_read == "true",
            "action": action or None,
            "related_post_id": related or None,
        })
    return notifications


def _job_notification_catalog() -> list[dict]:
    """Parse seed job notifications from SeedDataFactory.swift."""
    try:
        text = SEED_DATA_PATH.read_text()
    except Exception:
        return []
    block = re.search(
        r"static let jobNotifications: \[JobNotification\] = \[(.*?)\n    \]",
        text,
        re.S,
    )
    if not block:
        return []
    jobs: list[dict] = []
    pat = re.compile(
        r'JobNotification\(id:\s*"([^"]+)",\s*title:\s*"([^"]+)",\s*'
        r'companies:\s*"([^"]+)",\s*location:\s*(?:"([^"]+)"|nil),\s*'
        r'timeAgo:\s*"([^"]+)"\)',
        re.S,
    )
    for job_id, title, companies, location, time_ago in pat.findall(block.group(1)):
        jobs.append({
            "id": job_id,
            "title": title,
            "companies": companies,
            "location": location or None,
            "time_ago": time_ago,
        })
    return jobs


def _notification_summary() -> str:
    notifications = _notification_catalog()
    job_notifications = _job_notification_catalog()
    if not notifications and not job_notifications:
        return "No seed notification data was available."
    lines = ["Notifications:"]
    for n in notifications:
        read = "read" if n["is_read"] else "unread"
        suffix = f" action={n['action']}" if n.get("action") else ""
        related = f" related_post={n['related_post_id']}" if n.get("related_post_id") else ""
        lines.append(
            f"- {n['id']} [{n['type']}, {read}, {n['time_ago']}] "
            f"{n['actor']}: {n['message']}{suffix}{related}"
        )
    if job_notifications:
        lines.append("Job notifications:")
        for j in job_notifications:
            loc = f" in {j['location']}" if j.get("location") else ""
            lines.append(
                f"- {j['id']} [{j['time_ago']}] {j['title']} {j['companies']}{loc}"
            )
    return "\n".join(lines)


def _resolve_job(query: str) -> dict:
    """Resolve a job id/title/company query to a seed job or ambiguity."""
    q = (query or "").strip()
    if not q:
        return {"ok": False, "message": "A non-empty job id, title, or company is required."}
    jobs = _job_catalog()
    q_low = q.lower()
    for job in jobs:
        if job["id"] == q:
            return {"ok": True, "job": job, "matches": [job]}
    exact = [
        job for job in jobs
        if q_low == job["title"].lower() or q_low == job["company"].lower()
    ]
    if len(exact) == 1:
        return {"ok": True, "job": exact[0], "matches": exact}
    if len(exact) > 1:
        return {"ok": False, "ambiguous": True,
                "message": f"'{query}' matches multiple jobs; pass a job id.",
                "candidates": exact[:12]}
    words = [w for w in re.split(r"[^a-z0-9]+", q_low) if len(w) >= 2]
    matches = []
    for job in jobs:
        hay = f"{job['id']} {job['title']} {job['company']} {job['location']}".lower()
        if q_low in hay or (words and all(w in hay for w in words)):
            matches.append(job)
    if len(matches) == 1:
        return {"ok": True, "job": matches[0], "matches": matches}
    if matches:
        return {"ok": False, "ambiguous": True,
                "message": f"'{query}' matches multiple jobs; pass a job id.",
                "candidates": matches[:12]}
    return {"ok": False, "message": f"No seed job matches '{query}'."}


def _job_detail_open(sim) -> bool:
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    if "0 results" in tree or "No jobs found" in tree:
        return False
    return "job_save_button" in tree or "About the company" in tree


def _tap_job_result_row(sim, job: dict) -> bool:
    """Tap a visible Jobs search result row by coordinates.

    SwiftUI renders the row as a content-shaped container with nested title and
    company text. Direct `tap_id(title)` can hit only the StaticText and miss
    the row gesture, so use the element bounds from the accessibility tree.
    """
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    def _attrs(node: str) -> dict:
        return {k: v for k, v in re.findall(r'([A-Za-z]+)="([^"]*)"', node)}

    win = re.search(
        r'<XCUIElementTypeApplication[^>]*width="(\d+)" height="(\d+)"', tree
    )
    sw, sh = (int(win.group(1)), int(win.group(2))) if win else (402, 874)
    title = job.get("title", "")
    company = job.get("company", "")
    nodes = re.findall(r"<XCUIElementType\w+\b[^>]*>", tree)
    title_nodes = []
    company_nodes = []
    row_nodes = []
    row_ids = {f"job_result_row_{job.get('id', '')}", f"job_row_{job.get('id', '')}"}
    for node in nodes:
        attrs = _attrs(node)
        label = attrs.get("label") or attrs.get("name") or attrs.get("value") or ""
        try:
            rect = tuple(int(attrs[k]) for k in ("x", "y", "width", "height"))
        except Exception:
            continue
        x, y, w, h = rect
        if attrs.get("name") in row_ids:
            row_nodes.insert(0, rect)
        if y > 160 and w > 250 and h > 70:
            row_nodes.append(rect)
        if title and title.lower() in label.lower():
            title_nodes.append(rect)
        if company and company.lower() in label.lower():
            company_nodes.append(rect)

    candidates = title_nodes[:]
    if company_nodes:
        # Prefer a title whose nearby company label belongs to the same row.
        paired = []
        for tx, ty, tw, th in title_nodes:
            if any(abs(cy - ty) <= 40 and cx >= tx - 80 for cx, cy, cw, ch in company_nodes):
                paired.append((tx, ty, tw, th))
        if paired:
            candidates = paired

    tap_points = []
    # Prefer the explicit row accessibility element when SwiftUI exposes it.
    # Direct Appium element taps can hit the accessibility container without
    # firing the row's onTapGesture; a coordinate tap inside the content region
    # triggers the same gesture a human tap would.
    for rx, ry, rw, rh in row_nodes:
        if rw > 250 and rh > 40:
            tap_points.append((rx + min(rw - 48, max(80, rw // 3)), ry + rh // 2))

    for x, y, w, h in candidates:
        # Tap lower and centered in the row so SwiftUI's contentShape receives
        # the gesture, not just the nested StaticText.
        tap_points.append((sw // 2, min(sh - 24, y + max(48, h + 36))))
        for rx, ry, rw, rh in row_nodes:
            if ry - 4 <= y <= ry + rh and rx <= x <= rx + rw:
                tap_points.append((rx + rw // 2, ry + min(rh - 10, max(28, h + 34))))
                break

    seen = set()
    for cx, cy in tap_points:
        point = (int(cx), int(cy))
        if point in seen:
            continue
        seen.add(point)
        try:
            sim.tap_xy(int(point[0] / sw * 1000), int(point[1] / sh * 1000))
            sim.wait(0.8)
            if _job_detail_open(sim):
                return True
        except Exception:
            continue
    return False


def _clear_field(sim, aid: str) -> bool:
    """Best-effort clear for focused SwiftUI text fields."""
    try:
        el = sim.driver.find_element("accessibility id", aid)
        try:
            el.clear()
            sim.wait(0.2)
            return True
        except Exception:
            pass
        try:
            el.click()
            sim.type_text("\b" * 80)
            sim.wait(0.2)
            return True
        except Exception:
            return False
    except Exception:
        return False


def _rewrite_jobs_search_field(sim, query: str) -> bool:
    """Directly replace the active Jobs search query when the field is visible."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    if "jobs_search_field" not in tree:
        return False
    try:
        sim.tap_id("xmark.circle.fill")
        sim.wait(0.2)
    except Exception:
        _clear_field(sim, "jobs_search_field")
    try:
        sim.tap_id("jobs_search_field")
        sim.wait(0.2)
        sim.type_text(query)
        sim.wait(0.7)
        return True
    except Exception:
        return False


@mcp.tool()
def launch() -> str:
    """Launch LockedIn and return the initial UI tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched LockedIn.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (no taps)."""
    sim = SimulatorBridge.get()
    return ts.observe_app_scoped(
        sim,
        bundle_id=BUNDLE_ID,
        app_name="LockedIn",
        markers=("home_search_bar", "jobs_search_field", "messaging_search_field"),
    )


def _dismiss_search_overlay(sim) -> bool:
    """If a SearchView is pushed on the Home stack, dismiss it.

    After ``search(...)`` the SearchView is presented on top of the Home
    feed. Its toolbar buttons (``home_messaging_button`` etc.) still appear
    in the tree (cached in the navigation stack), but they're covered by the
    search results / keyboard, so tapping them no-ops and the messaging panel
    never opens — the root cause of the open_dm_with/message_contact failures
    when called right after a search. The SearchView exposes an ``xmark``
    close button; tap it to pop back to the clean Home feed. Returns True if
    an ``xmark`` was tapped.
    """
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    # "See all N results"/search-result chrome (or a focused search field with
    # the keyboard up) indicates the SearchView is on top. xmark pops it.
    if ("See all" in tree or "xmark.circle.fill" in tree) and "xmark" in tree:
        try:
            sim.tap_id("xmark"); sim.wait(0.5)
            return True
        except Exception:
            return False
    return False


def _dismiss_system_overlay(sim) -> bool:
    """Dismiss iOS system disclosure overlays that can cover app rows."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return False
    if "Siri, Dictation" not in tree:
        return False
    for close_id in ("close", "Close", "xmark"):
        try:
            sim.tap_id(close_id)
            sim.wait(0.5)
            return True
        except Exception:
            continue
    return False


def _dismiss_blocking_sheet(sim) -> bool:
    """Dismiss ANY modal sheet covering the TabView so a subsequent tab
    switch / search actually lands on the underlying content.

    SwiftUI presents the compose, messaging, search, and schedule screens as
    ``.sheet``s on top of the whole TabView. While one is up, tapping a
    tab-bar button (or another sheet's affordance) no-ops because the sheet
    intercepts the touch. This pops whichever sheet is up:
      * compose  -> ``compose_dismiss_button``
      * search   -> ``xmark`` (handled by _dismiss_search_overlay)
      * messaging/new-message/schedule -> ``xmark``
    Returns True if something was dismissed. Safe to call when nothing is up.
    """
    dismissed = False
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if _dismiss_system_overlay(sim):
        dismissed = True
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
    # Compose sheet — has an explicit dismiss button.
    if "compose_text_editor" in tree or "compose_dismiss_button" in tree:
        try:
            sim.tap_id("compose_dismiss_button"); sim.wait(0.5)
            dismissed = True
        except Exception:
            pass
    # Search overlay.
    if _dismiss_search_overlay(sim):
        dismissed = True
    # Messaging / new-message / schedule sheets close via xmark. Only tap when
    # the home toolbar is NOT already reachable (toolbar reachable => nothing
    # covering it) to avoid spuriously tapping an xmark on the clean feed.
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if (
        ("messaging_conversation_row_" in tree or "chat_message_field" in tree
         or "new_message_search_field" in tree or "schedule_done_button" in tree)
        and "xmark" in tree
    ):
        try:
            sim.tap_id("xmark"); sim.wait(0.5)
            dismissed = True
        except Exception:
            pass
    # Post-detail sheet: react_to_post('Comment') sets showDetail=true on a
    # PostCard, presenting PostDetailView as a .sheet over the TabView. It has
    # NO compose/search/messaging marker, and the underlying Home toolbar still
    # LEAKS into the page source — so a toolbar-reachable check wrongly thinks
    # nothing is on top. The reliable marker is PostDetailView's comment field
    # placeholder ("Leave your thoughts here...") plus its detail_* ids. While
    # it's up, a Post-tab tap (to open the composer) silently no-ops (root
    # cause of create_post failing right after react_to_post('Comment')). It
    # closes via the xmark/Close in its header.
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    detail_up = (
        "Leave your thoughts here" in tree
        or "detail_attachment_" in tree
        or "detail_scheduled_badge_" in tree
    )
    if detail_up and "compose_text_editor" not in tree:
        for close_id in ("xmark", "Close"):
            try:
                sim.tap_id(close_id); sim.wait(0.5)
                dismissed = True
                break
            except Exception:
                continue
    return dismissed


def _ensure_home(sim) -> None:
    """Make sure the Home tab is the selected tab AND its feed (not a pushed
    SearchView) is on top, so the toolbar buttons
    (``home_search_bar``/``home_messaging_button``/``home_profile_avatar``)
    are actually tappable. These IDs render only on the Home tab; from another
    tab or a fresh launch onto a different tab they're absent, and after a
    search they're present-but-covered. Tapping ``tab_home`` is idempotent.
    """
    # First clear any modal sheet (search/compose/messaging) covering the
    # Home toolbar — Home-targeting callers always want a clean feed.
    _dismiss_blocking_sheet(sim)
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "home_messaging_button" in tree or "home_search_bar" in tree:
        return
    for tab_id in ("tab_home", "Home"):
        try:
            sim.tap_id(tab_id); sim.wait(0.4); break
        except Exception:
            continue


def _dismiss_open_sheet(sim) -> None:
    """Best-effort dismiss of any messaging/search/compose sheet covering the
    Home toolbar, so a subsequent ``_ensure_home`` can reach the toolbar
    buttons. Taps a close affordance if present; harmless otherwise."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        return
    # The messaging list / search sheets expose an "xmark"/Close button.
    if "home_messaging_button" in tree or "home_search_bar" in tree:
        return  # toolbar already reachable, nothing covering it


def _messaging_panel_open(tree: str) -> bool:
    """True when the messaging panel is actually presented. The panel renders
    seed conversation rows (``messaging_conversation_row_<slug>``), the
    "Search messages" affordance, and the New-Message compose button
    (``square.and.pencil``) — any of these is a reliable open-marker."""
    return (
        "messaging_conversation_row_" in tree
        or "Search messages" in tree
        or "square.and.pencil" in tree
    )


def _open_messaging_panel(sim) -> bool:
    """Self-navigate to Home and open the messaging sheet. Returns True when
    the messaging panel is actually presented (conversation rows / search /
    compose button in the tree).

    Robust against the cold states the agent leaves behind:
      * on another tab  -> ``_ensure_home`` taps tab_home
      * after a search  -> ``_ensure_home`` pops the covering SearchView so the
        ``home_messaging_button`` tap actually lands (previously it no-op'd
        and this function falsely returned False)
      * wedged state    -> relaunch (LockedIn's DM/conversation state is
        in-memory seed data, so a relaunch is non-destructive) and retry.
    """
    def _try_open() -> bool:
        _ensure_home(sim)
        for _ in range(3):
            try:
                sim.tap_id("home_messaging_button"); sim.wait(0.6)
            except Exception:
                pass
            try:
                tree = sim.observe_text() or ""
            except Exception:
                tree = ""
            if _messaging_panel_open(tree):
                return True
            # A leftover search overlay can still be intercepting; clear it
            # and loop so the next messaging tap lands on the clean Home.
            if not _dismiss_search_overlay(sim):
                sim.wait(0.4)
        return False

    if _try_open():
        return True
    # Last resort: relaunch to a clean Home, then open the panel.
    try:
        sim.launch_and_observe(BUNDLE_ID)
    except Exception:
        pass
    return _try_open()


@mcp.tool()
def navigate_to_tab(tab: str) -> str:
    """Switch to a bottom-bar tab.

    Args:
        tab: One of ``home``/``feed``, ``network``/``mynetwork``,
            ``post``/``compose``, ``notifications``/``alerts``, ``jobs``
            (case-insensitive). Any other value returns an error string.
    """
    aid = TAB_MAP.get(tab.strip().lower())
    if aid is None:
        # Prefix with "Could not" so the envelope marks this ok:False — an
        # unknown tab is an honest failure, not a no-op success.
        return (
            f"Could not switch to tab '{tab}': unknown tab. "
            f"Use one of: home, network, post, notifications, jobs."
        )
    sim = SimulatorBridge.get()
    # Any modal sheet (search, compose, messaging, schedule) covers the whole
    # TabView; tapping a tab-bar button while one is up leaves the sheet
    # intercepting and the target tab's content unreachable. Pop it first so
    # the switch actually lands.
    _dismiss_blocking_sheet(sim)
    # A chat detail opened from the messaging panel is an EXTRA level on top of
    # the messaging sheet. Its close affordance is an unlabeled `xmark` button
    # (ChatDetailView.swift line 38-44) that _dismiss_blocking_sheet's xmark tap
    # does NOT reliably hit (multiple xmarks in the tree; the tap lands on the
    # wrong one and `chat_message_field` stays up). The old navigate_to_tab then
    # tapped the tab-bar button while the chat sheet was still presented: the tap
    # no-op'd on the underlying TabView, but the Home toolbar LEAKS through the
    # sheet so it returned ok:true with chat_message_field STILL in the tree —
    # the silent no-op flagged in the live run. An OPEN chat detail is reliably
    # closed by a relaunch (LockedIn's conversation state is in-memory seed data,
    # so a relaunch is non-destructive and lands on a clean Home feed). Detect
    # the stuck chat via its compose field (which does NOT leak onto a clean
    # feed, unlike the cached messaging_conversation_row_ ids) and relaunch.
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "chat_message_field" in tree:
        try:
            sim.launch_and_observe(BUNDLE_ID); sim.wait(0.4)
        except Exception:
            pass
    try:
        sim.tap_id(aid); sim.wait(0.4)
    except Exception as exc:
        return f"Could not switch to '{tab}' tab. {str(exc)[:120]}"
    # Verify the switch actually landed and didn't silently no-op behind a
    # still-open chat sheet. chat_message_field is the reliable "chat still up"
    # marker (the messaging_conversation_row_ ids leak into a clean feed and
    # would false-positive here). If it's still present the tab didn't change.
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "chat_message_field" in tree:
        # Relaunch to force the chat closed, then re-tap the tab.
        try:
            sim.launch_and_observe(BUNDLE_ID); sim.wait(0.4)
            sim.tap_id(aid); sim.wait(0.4)
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "chat_message_field" in tree:
            return (
                f"Could not switch to '{tab}' tab: a chat detail stayed open and "
                f"intercepted the tab tap. Call observe() and close the chat "
                f"(tap its xmark), then retry navigate_to_tab."
            )
    return f"Switched to '{tab}'."


@mcp.tool()
def search(query: str) -> str:
    """Search people/posts/jobs via the Home tab's global search bar.

    Args:
        query: Free-text query. Typed into ``home_search_bar``.

    Self-navigates to the Home tab first, so a blind call from a fresh
    launch (or while another tab is selected) works without a manual
    ``navigate_to_tab('home')``.
    """
    sim = SimulatorBridge.get()
    _ensure_home(sim)
    try:
        sim.tap_id("home_search_bar"); sim.wait(0.4)
    except Exception as exc:
        return (
            f"Could not open search. Ensure the Home tab is visible. "
            f"Error: {str(exc)[:120]}"
        )
    # SearchView presents its own text field; type into whatever field is
    # now focused (the search bar tap focuses it on this build).
    try:
        sim.type_text(query); sim.wait(0.5)
    except Exception:
        # If the tap surfaced a separate SearchView TextField that needs an
        # explicit focus, try common search field ids before giving up.
        for fid in ("search_field", "home_search_field"):
            try:
                sim.tap_id(fid); sim.wait(0.3); sim.type_text(query); sim.wait(0.4)
                break
            except Exception:
                continue
    return f"Searched for '{query}'."


def _ensure_compose(sim) -> bool:
    """Make sure the compose sheet is open (``compose_text_editor`` in tree).
    Opens it via the Post tab if needed. Returns True when the composer is
    reachable. Lets blind compose-helper calls (set_audience/attach_photo/
    attach_event/open_link_panel) work without a manual navigate."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "compose_text_editor" in tree:
        return True
    # The compose sheet is presented via `.sheet(isPresented: $showCreatePost)`
    # on RootTabView, and SwiftUI allows only ONE sheet at a time. If ANY other
    # sheet is still up (a Search overlay after search(), a PostDetail sheet
    # after react_to_post('Comment'), a messaging/schedule sheet), the compose
    # sheet silently fails to present — the Post-tab tap flips showCreatePost
    # but the existing sheet wins, so compose_text_editor never enters the tree
    # (root cause of create_post/schedule_post failing right after a
    # search/comment). Pop whatever sheet is up first, then take the slot.
    # Retry the whole open a couple times: dismissing a nested sheet can leave
    # another underneath, and the first Post-tap can race the dismiss.
    for _attempt in range(3):
        _dismiss_blocking_sheet(sim)
        for tab_id in ("tab_post", "Post"):
            try:
                sim.tap_id(tab_id); sim.wait(0.6); break
            except Exception:
                continue
        for _ in range(4):
            try:
                tree = sim.observe_text() or ""
            except Exception:
                tree = ""
            if "compose_text_editor" in tree:
                return True
            sim.wait(0.3)
    # Last resort: a stacked sheet (e.g. a PostDetail sheet presented over a
    # leftover search overlay) can leave several ambiguous `xmark` close
    # buttons in the tree that targeted dismissal can't disentangle — the
    # composer then never gets the single-sheet slot. Relaunch to a clean Home
    # (LockedIn's feed/conversation state is in-memory seed data, and no draft
    # has been typed yet, so this is non-destructive) and open the composer
    # from there.
    try:
        sim.launch_and_observe(BUNDLE_ID); sim.wait(0.5)
    except Exception:
        pass
    for tab_id in ("tab_post", "Post"):
        try:
            sim.tap_id(tab_id); sim.wait(0.6); break
        except Exception:
            continue
    for _ in range(4):
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "compose_text_editor" in tree:
            return True
        sim.wait(0.3)
    return False


@mcp.tool()
def create_post(text: str) -> str:
    """Compose and publish a new feed post in one shot.

    Args:
        text: Body of the post. Typed into ``compose_text_editor``.

    Opens the Post tab automatically (skipped if the compose sheet is
    already visible) and taps ``compose_post_button`` to publish.
    """
    sim = SimulatorBridge.get()
    # Use the robust opener (dismisses a covering search overlay, then opens
    # the composer via the Post tab) so a blind call right after a search /
    # from another tab still reaches the editor instead of blindly tapping
    # compose_text_editor and erroring when it isn't presented.
    if not _ensure_compose(sim):
        return (
            "Could not open the compose sheet to post. Call "
            "navigate_to_tab('post') then retry create_post."
        )
    sim.tap_id("compose_text_editor"); sim.wait(0.3)
    sim.type_text(text); sim.wait(0.3)
    sim.tap_id("compose_post_button"); sim.wait(0.6)
    # Verify the post actually published: tapping compose_post_button dismisses
    # the sheet and prepends the new post to the Home feed. Confirm the body
    # rendered on the feed so we don't report a false success when the editor
    # silently failed to commit. Match on a distinctive slice of the body
    # (the feed truncates long posts, so compare a short head fragment that
    # survives truncation). On match return success; otherwise surface the
    # honest failure.
    _ensure_home(sim)
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    head = text.strip()[:24]
    if head and head in tree:
        return f"Posted: '{text[:80]}'."
    # Fragment may carry characters the tree escapes (emoji/newlines); fall
    # back to a short alphanumeric token that's robust to XML escaping.
    token = ""
    for word in text.split():
        w = "".join(ch for ch in word if ch.isalnum())
        if len(w) >= 4:
            token = w; break
    if token and token in tree:
        return f"Posted: '{text[:80]}'."
    return (
        "Could not confirm the new post in the Home feed after tapping Post. "
        "Call observe() to verify; the compose sheet may have failed to "
        "commit. Retry create_post if the post is absent."
    )


@mcp.tool()
def schedule_post(text: str) -> str:
    """Compose a post and schedule it via the schedule picker.

    Args:
        text: Body of the post.

    Opens the Post tab if needed, types the body, taps
    ``compose_schedule_clock_button``, then confirms with
    ``schedule_done_button`` — the date defaults to whatever the picker
    is currently showing (no explicit date argument).

    Idempotent: if the compose sheet is already open
    (``compose_text_editor`` is reachable), skips re-opening the Post tab
    so callers that pre-seed the composer don't trip the tab-bar tap
    against the already-presented sheet.
    """
    sim = SimulatorBridge.get()
    # Robust opener: dismisses a covering search overlay (SwiftUI only allows
    # one sheet at a time — a live search sheet would otherwise block the
    # compose sheet) then opens the composer via the Post tab. Surfaces a
    # clear precondition failure instead of cascading a tap_id error on
    # compose_schedule_clock_button later.
    if not _ensure_compose(sim):
        return (
            "Could not schedule post: the compose sheet is not open. "
            "Call navigate_to_tab('post') first, or open the composer via "
            "the Post tab."
        )
    sim.tap_id("compose_text_editor"); sim.wait(0.4)
    sim.type_text(text); sim.wait(0.4)
    sim.tap_id("compose_schedule_clock_button"); sim.wait(0.6)
    # The schedule picker is a .sheet with `presentationDetents(.medium)` —
    # on cold launches the presentation animation can take >500ms before
    # the Done toolbar button is in the tree. Poll briefly before tapping.
    for _ in range(4):
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "schedule_done_button" in tree:
            break
        sim.wait(0.3)
    sim.tap_id("schedule_done_button"); sim.wait(0.4)
    return f"Scheduled post: '{text[:60]}'."


@mcp.tool()
def cancel_compose() -> str:
    """Dismiss the compose sheet without posting (taps the dismiss button).

    Precondition: the compose sheet is open.
    """
    sim = SimulatorBridge.get()
    sim.tap_id("compose_dismiss_button"); sim.wait(0.3)
    return "Cancelled compose."


@mcp.tool()
def open_link_panel() -> str:
    """Open the "Add a link" alert on the compose sheet.

    Precondition: the compose sheet is open (call
    ``navigate_to_tab('post')`` first if needed). Taps
    ``compose_more_button`` to surface the "Add to your post"
    confirmation dialog, then taps
    ``compose_more_add_link_button`` (the "Add a link" choice). The
    resulting alert exposes ``link_title_field`` /
    ``link_subtitle_field`` for ``add_link_to_post``.
    """
    sim = SimulatorBridge.get()
    # Self-navigate: the compose sheet must be open. compose_more_button only
    # renders inside CreatePostView (CreatePostView.swift line 132-137). Open
    # the composer via the Post tab if it isn't already up.
    if not _ensure_compose(sim):
        return (
            "Could not open the compose sheet. Call navigate_to_tab('post') "
            "first to surface compose_more_button."
        )
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    # The "Add to your post" confirmationDialog presents intermittently when
    # invoked from inside the compose sheet (a SwiftUI stacked-presentation
    # race — several .confirmationDialog/.sheet/.alert modifiers share the
    # same view, so this one sometimes loses the race and silently no-ops).
    # Retry the trigger tap a few times until the dialog's "Add a link"
    # option is actually in the tree.
    dialog_up = False
    for _attempt in range(4):
        sim.tap_id("compose_more_button"); sim.wait(0.6)
        for _ in range(4):
            try:
                tree = sim.observe_text() or ""
            except Exception:
                tree = ""
            if "compose_more_add_link_button" in tree or "Add a link" in tree:
                dialog_up = True
                break
            sim.wait(0.3)
        if dialog_up:
            break
    if not dialog_up:
        return (
            "Could not open the 'Add to your post' menu after retries. "
            "This is an intermittent SwiftUI presentation issue with the "
            "compose '+' menu; call observe() and retry open_link_panel(), "
            "or proceed without a link attachment."
        )
    try:
        sim.tap_id("compose_more_add_link_button"); sim.wait(0.6)
    except Exception:
        # Older builds without the explicit dialog button IDs still expose
        # the buttons by their visible label.
        try:
            sim.tap_id("Add a link"); sim.wait(0.6)
        except Exception:
            return (
                "Could not tap 'Add a link': the option did not stay on "
                "screen long enough. Retry open_link_panel()."
            )
    # Wait for the link-input alert to actually present so link_title_field
    # is in the tree for the follow-up add_link_to_post call. The
    # `.alert(isPresented: $showLinkInput)` is the innermost of a stacked
    # sheet→confirmationDialog→alert chain and frequently fails to present
    # on this build (SwiftUI presentation-race). Surface that honestly
    # instead of falsely reporting the panel is ready.
    for _ in range(5):
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "link_title_field" in tree:
            return "Opened link panel."
        sim.wait(0.3)
    return (
        "Could not present the link-input alert after tapping 'Add a link' "
        "(known SwiftUI nested-presentation issue on this build). "
        "link_title_field is not available; retry open_link_panel() or "
        "skip the link attachment."
    )


@mcp.tool()
def add_link_to_post(title: str, subtitle: str = "") -> str:
    """Fill the link-attachment fields on the current compose draft.

    Args:
        title: Link title text, typed into ``link_title_field``.
        subtitle: Optional secondary text typed into
            ``link_subtitle_field``. Empty string skips the field.

    Precondition: the compose sheet is open with the link-attachment
    alert showing ``link_title_field`` / ``link_subtitle_field``.
    Call ``open_link_panel()`` first to surface those inputs (taps
    the compose "+" menu then "Add a link").
    """
    sim = SimulatorBridge.get()
    # Precondition gate: the "Add a link" alert must be presented so the
    # text fields are in the tree. The alert is only shown when
    # `showLinkInput == true` (CreatePostView.swift line 170-192).
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "link_title_field" not in tree:
        return (
            "Could not add link: the link-input alert is not open. "
            "Call open_link_panel() first to surface link_title_field / "
            "link_subtitle_field."
        )
    sim.tap_id("link_title_field"); sim.wait(0.4); sim.type_text(title); sim.wait(0.3)
    if subtitle:
        sim.tap_id("link_subtitle_field"); sim.wait(0.4); sim.type_text(subtitle); sim.wait(0.3)
    return f"Added link '{title}'."


@mcp.tool()
def set_audience() -> str:
    """Open the post audience picker (Anyone / Connections only / etc).

    Opens the picker only; the agent must observe the resulting UI to
    choose an option. Self-navigates: opens the compose sheet via the Post
    tab first if it isn't already showing.
    """
    sim = SimulatorBridge.get()
    if not _ensure_compose(sim):
        return (
            "Could not open the compose sheet. Call navigate_to_tab('post') "
            "then retry set_audience."
        )
    sim.tap_id("compose_audience_button"); sim.wait(0.4)
    return "Opened audience picker."


@mcp.tool()
def attach_photo() -> str:
    """Tap the photo attachment button on the composer.

    Self-navigates: opens the compose sheet via the Post tab first if it
    isn't already showing. Opens the photo picker UI; the agent must
    continue from the resulting tree to select an image.
    """
    sim = SimulatorBridge.get()
    if not _ensure_compose(sim):
        return (
            "Could not open the compose sheet. Call navigate_to_tab('post') "
            "then retry attach_photo."
        )
    sim.tap_id("compose_photo_button"); sim.wait(0.4)
    return "Tapped photo attachment."


@mcp.tool()
def attach_event() -> str:
    """Tap the calendar/event attachment button on the composer.

    Self-navigates: opens the compose sheet via the Post tab first if it
    isn't already showing. Opens an event picker; the agent must continue
    from the resulting tree.
    """
    sim = SimulatorBridge.get()
    if not _ensure_compose(sim):
        return (
            "Could not open the compose sheet. Call navigate_to_tab('post') "
            "then retry attach_event."
        )
    sim.tap_id("compose_calendar_button"); sim.wait(0.4)
    return "Tapped event attachment."


@mcp.tool()
def open_messaging() -> str:
    """Open the messaging screen via the Home tab's messaging button.

    Self-navigates to the Home tab first so a blind call works regardless
    of the currently-selected tab.
    """
    sim = SimulatorBridge.get()
    if _open_messaging_panel(sim):
        return "Opened messaging."
    return (
        "Could not open the messaging panel. Call navigate_to_tab('home') "
        "then retry open_messaging()."
    )


@mcp.tool()
def open_profile() -> str:
    """Open the user's own profile via the Home tab avatar.

    Self-navigates to the Home tab first so a blind call works regardless
    of the currently-selected tab.
    """
    sim = SimulatorBridge.get()
    _ensure_home(sim)
    err = sim.tap_and_verify_changed(
        "home_profile_avatar",
        prefix_for_failure="Could not open profile. ",
        settle=0.5,
    )
    if err:
        return err
    return "Opened profile."


@mcp.tool()
def view_notifications() -> str:
    """Navigate to Notifications and return the current notification signals."""
    nav = navigate_to_tab("notifications")
    return f"{nav}\n\n{_notification_summary()}"


@mcp.tool()
def view_network() -> str:
    """Navigate to the My Network tab (alias for navigate_to_tab('network'))."""
    return navigate_to_tab("network")


@mcp.tool()
def view_jobs() -> str:
    """Navigate to the Jobs tab (alias for navigate_to_tab('jobs'))."""
    return navigate_to_tab("jobs")


# Reaction labels that live behind the long-press palette on the Like
# control (PostCardView.swift: actionButton("Like") has a LongPressGesture
# that opens an overlay of `reaction_<rawValue>` buttons). Like itself is a
# direct tap on post_action_like; the others require opening the palette.
# Maps a caller's free-text label -> the PostReactionType.rawValue used in
# the `reaction_<rawValue>` accessibility id (AppEnums.swift).
_REACTION_RAWVALUES = {
    "celebrate": "celebrate",
    "support": "support",
    "love": "love",
    "insightful": "insightful",
    "funny": "funny",
    "like": "like",
}


def _element_norm_center(tree: str, accessibility_id: str):
    """Return (norm_x, norm_y) on the 0-1000 scale for the element carrying
    *accessibility_id* in the page-source *tree*, or None if not found.

    The ``hover`` (touchAndHold) action expects coordinates normalised to the
    application window's width/height on a 0-1000 scale (appium_agent.py
    divides by 1000 then multiplies by window size). The page source reports
    absolute pixel x/y/width/height, so we read the app window size and the
    element rect and convert.
    """
    appm = re.search(
        r"XCUIElementTypeApplication[^>]*width=\"(\d+)\"\s+height=\"(\d+)\"",
        tree,
    )
    if not appm:
        return None
    aw, ah = int(appm.group(1)), int(appm.group(2))
    if aw <= 0 or ah <= 0:
        return None
    # Match the element node bearing the id and capture its rect attributes.
    pat = (
        r"<[^>]*(?:name|identifier)=\"" + re.escape(accessibility_id) +
        r"\"[^>]*x=\"(-?\d+)\"\s+y=\"(-?\d+)\"\s+width=\"(\d+)\"\s+height=\"(\d+)\""
    )
    m = re.search(pat, tree)
    if not m:
        # Attribute order can vary; try x/y/w/h appearing before the id too.
        pat2 = (
            r"<[^>]*x=\"(-?\d+)\"\s+y=\"(-?\d+)\"\s+width=\"(\d+)\"\s+height=\"(\d+)\""
            r"[^>]*(?:name|identifier)=\"" + re.escape(accessibility_id) + r"\""
        )
        m = re.search(pat2, tree)
    if not m:
        return None
    x, y, w, h = (int(g) for g in m.groups())
    cx, cy = x + w / 2.0, y + h / 2.0
    nx = max(0, min(1000, int(round(cx / aw * 1000))))
    ny = max(0, min(1000, int(round(cy / ah * 1000))))
    return nx, ny


def _open_reaction_palette(sim) -> bool:
    """Long-press the Like control (post_action_like) to open the reaction
    palette, returning True once the `reaction_*` buttons are in the tree."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "reaction_insightful" in tree or "reaction_celebrate" in tree:
        return True  # already open
    center = _element_norm_center(tree, "post_action_like")
    if center is None:
        return False
    nx, ny = center
    for _ in range(2):
        try:
            sim.long_press(nx, ny, duration=0.8); sim.wait(0.8)
        except Exception:
            pass
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "reaction_insightful" in tree or "reaction_celebrate" in tree:
            return True
    return False


@mcp.tool()
def react_to_post(label: str) -> str:
    """React to / act on a feed post.

    Args:
        label: Action or reaction name. Direct post actions: ``Like``,
            ``Comment``, ``Repost``, ``Send`` (tapped via
            ``post_action_<label>``). Rich reactions — ``Celebrate``,
            ``Support``, ``Love``, ``Insightful``, ``Funny`` — live behind
            the reaction palette: this tool long-presses the post's Like
            control to open the palette, then taps the matching
            ``reaction_<type>`` button.

    Self-navigates to the Home feed first (dismissing any covering sheet /
    popping back from another tab) so a blind call from a messy state reaches
    the post action row instead of erroring on an off-screen control.
    """
    sim = SimulatorBridge.get()
    key = label.strip().lower()
    is_rich = key in _REACTION_RAWVALUES and key != "like"
    # Make sure the Home feed (where post action rows live) is on top.
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    # A covering sheet (search results / PostDetail) leaves the underlying
    # Home feed's `post_action_like` LEAKING into the page source, so a bare
    # "post_action_like in tree" check wrongly thinks the feed is interactive.
    # A rich reaction long-presses by COORDINATE, and that touch lands on the
    # covering sheet (not the leaked post), so the palette never opens (root
    # cause of react_to_post('Insightful') failing right after a search). Pop
    # any covering sheet and land on a clean Home before reacting. (Direct
    # taps by id route through to the leaked control fine, but a clean feed is
    # harmless for them too.)
    sheet_up = (
        "Leave your thoughts here" in tree  # PostDetail sheet
        or "See all" in tree or "xmark.circle.fill" in tree  # search overlay
        or "messaging_conversation_row_" in tree or "chat_message_field" in tree
    )
    if is_rich or sheet_up or "post_action_like" not in tree:
        _ensure_home(sim)
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""

    # ── Rich reaction (Celebrate/Support/Love/Insightful/Funny): open the
    # long-press palette on the Like control, then tap the specific reaction.
    if is_rich:
        rid = f"reaction_{_REACTION_RAWVALUES[key]}"
        if not _open_reaction_palette(sim):
            return (
                f"Could not open the reaction palette to react with '{label}'. "
                f"Open the Home feed with a post in view, then retry."
            )
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if rid not in tree:
            return (
                f"Could not react with '{label}': '{rid}' is not in the "
                f"reaction palette. Available reactions: Like, Celebrate, "
                f"Support, Love, Insightful, Funny."
            )
        try:
            sim.tap_id(rid); sim.wait(0.5)
        except Exception as exc:
            return (
                f"Could not tap reaction '{label}' ({rid}). {str(exc)[:80]}"
            )
        # Verify the reaction registered: tapping it dismisses the palette and
        # the chosen reaction's icon appears on the post's reaction summary
        # row. Confirm the palette closed (reaction buttons gone) — a no-op tap
        # would leave them up.
        try:
            tree2 = sim.observe_text() or ""
        except Exception:
            tree2 = ""
        if "reaction_insightful" in tree2 or "reaction_celebrate" in tree2:
            return (
                f"Tapped '{label}' but the reaction palette is still open; the "
                f"reaction may not have registered. Retry react_to_post."
            )
        return f"Reacted with '{label}'."

    # ── Direct post action (Like/Comment/Repost/Send).
    aid = f"post_action_{key}"
    try:
        sim.tap_id(aid); sim.wait(0.3)
    except Exception as exc:
        return (
            f"Could not react with '{label}': the post action "
            f"'{aid}' is not visible. Open the Home feed and scroll a post "
            f"into view first. {str(exc)[:80]}"
        )
    return f"Reacted with '{label}'."


# ── New UI-driven messaging + jobs tools (rely on accessibility IDs added
# to LinkedIn's MessagingListView, ChatDetailView, JobsView in iOS source).

def _conversation_slugs(sim) -> list:
    """Return the list of conversation-row slugs currently in the tree."""
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    slugs = []
    for m in re.finditer(r"messaging_conversation_row_([a-z0-9_]+)", tree):
        s = m.group(1)
        if s not in slugs:
            slugs.append(s)
    return slugs


def _resolve_contact_slug(sim, contact_name: str) -> Optional[str]:
    """Match *contact_name* against the seed connections (by full name,
    case-insensitive, exact then substring then first-name) and return the
    canonical slug ``firstname_lastname``. Falls back to slugging the raw
    input if the data layer is unavailable so callers still get a best
    effort. Returns None only if nothing plausibly matches."""
    raw_slug = contact_name.strip().lower().replace(" ", "_")
    names = []
    try:
        # Seed connections live in SeedDataFactory; read the persisted state
        # if available, else derive from the on-screen new-message picker.
        # We don't have a structured connections export, so rely on the
        # picker search to canonicalise. Here we just normalise the input.
        pass
    except Exception:
        pass
    return raw_slug or None


def _open_dm_via_picker(sim, contact_name: str) -> Optional[str]:
    """From the messaging panel, open the New Message picker, filter by
    *contact_name*, and tap the matching connection row to start/open a DM.
    Returns None on success or an error string. Requires the messaging panel
    to already be open."""
    slug = contact_name.strip().lower().replace(" ", "_")
    # Open the compose ("square.and.pencil") picker.
    opened = False
    for _ in range(3):
        try:
            sim.tap_id("square.and.pencil"); sim.wait(0.7)
        except Exception:
            pass
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "new_message_connection_row_" in tree or "new_message_search_field" in tree or "New Message" in tree:
            opened = True
            break
        sim.wait(0.3)
    if not opened:
        return (
            f"Could not open the New Message picker to start a DM with "
            f"'{contact_name}'."
        )
    # Filter the connection list to make the target row reachable (lists can
    # be long / off-screen). Typing into new_message_search_field narrows it.
    try:
        sim.tap_id("new_message_search_field"); sim.wait(0.3)
        # Use the first token (first name) to keep the filter forgiving of
        # display-name variations while still narrowing the list.
        token = contact_name.strip().split()[0] if contact_name.strip() else contact_name
        sim.type_text(token); sim.wait(0.6)
    except Exception:
        pass
    # Tap the connection row by its canonical id.
    row_id = f"new_message_connection_row_{slug}"
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if row_id not in tree:
        # The exact slug isn't present after filtering; fall back to the
        # first available connection row only if it actually matches the
        # requested name (avoid silently messaging the wrong person).
        candidates = re.findall(r"new_message_connection_row_([a-z0-9_]+)", tree)
        want = slug.split("_")
        match = None
        for c in candidates:
            if c == slug or all(p in c.split("_") for p in want):
                match = c; break
        if match is None:
            return (
                f"No connection matching '{contact_name}' found in the New "
                f"Message picker."
            )
        row_id = f"new_message_connection_row_{match}"
    err = sim.tap_and_verify_changed(
        row_id,
        prefix_for_failure=f"Could not open the DM with '{contact_name}' from the picker. ",
        settle=0.8,
    )
    if err:
        return err
    return None


def _open_dm_with_impl(contact_name: str) -> str:
    """Plain implementation shared by ``open_dm_with`` and ``message_contact``
    (the @mcp.tool wrapper returns an envelope dict, so internal callers must
    use this string-returning helper)."""
    sim = SimulatorBridge.get()
    # If a DIFFERENT chat is already open (chat detail pushed over the
    # messaging list), the conversation rows underneath are present in the
    # tree but COVERED — tapping the requested row no-ops and verify-changed
    # honestly fails. Back out of the open chat first so the target row is
    # reachable. The chat-detail header exposes its own close affordance
    # (xmark). LockedIn's conversation state is in-memory seed data, so if a
    # clean panel can't be reached we relaunch (non-destructive).
    try:
        tree0 = sim.observe_text() or ""
    except Exception:
        tree0 = ""
    if "chat_message_field" in tree0:
        # Relaunch to a clean Home so the messaging panel re-renders its full
        # conversation list with every row tappable (the rows under an open
        # chat detail are present-but-covered). Re-opening the same contact is
        # idempotent — it just re-resolves and taps the row again.
        try:
            sim.launch_and_observe(BUNDLE_ID); sim.wait(0.4)
        except Exception:
            pass
    if not _open_messaging_panel(sim):
        return (
            f"Could not open the messaging panel to reach '{contact_name}'. "
            "Call navigate_to_tab('home') then retry."
        )
    slug = contact_name.strip().lower().replace(" ", "_")
    # 1) Existing conversation row?
    existing = _conversation_slugs(sim)
    target = None
    if slug in existing:
        target = slug
    else:
        # forgiving match: substring on the slug tokens
        want = slug.split("_")
        for s in existing:
            if all(p in s.split("_") for p in want):
                target = s; break
    if target is not None:
        err = sim.tap_and_verify_changed(
            f"messaging_conversation_row_{target}",
            prefix_for_failure=f"Could not open the existing conversation with '{contact_name}'. ",
            settle=0.6,
        )
        if err:
            return err
        return f"Opened DM with {contact_name}."
    # 2) No existing thread — start one via the New Message picker.
    err = _open_dm_via_picker(sim, contact_name)
    if err:
        return err
    return f"Opened DM with {contact_name}."


@mcp.tool()
def open_dm_with(contact_name: str) -> str:
    """Open a DM conversation with a named contact, starting a new one if
    no conversation exists yet.

    Args:
        contact_name: Contact display name (e.g. ``Rachel Torres``,
            ``Aiden Cross``, ``Devon Hart``). Resolved case-insensitively.
            Existing seed conversations: Rachel Torres, Devon Hart, Blair
            Morgan, Imani Brooks, Petra Johansson, Rohan Mehta, Tessa
            Monroe, Wyatt Lin. Any other *connection* (e.g. Aiden Cross)
            has no existing thread — this tool then opens the New Message
            picker and starts the DM automatically.

    Self-navigates: opens the messaging panel from Home (switching to the
    Home tab first if needed). If a conversation row already exists it is
    tapped directly; otherwise the New Message composer is used to find the
    connection and start the chat.
    """
    return _open_dm_with_impl(contact_name)


def _flatten_dm_text(text: str) -> str:
    """Collapse newlines to spaces for the single-line DM TextField.

    ``chat_message_field`` is a single-line SwiftUI ``TextField`` with an
    ``.onSubmit`` handler: typing a literal newline fires onSubmit, which
    SENDS the text typed so far and CLEARS the field (ChatDetailView.swift
    line 397-408). So a multi-line message (the live failing flow used
    ``\\n\\n``-separated question lists) gets PARTIALLY sent — only the text
    up to the first newline — and the remainder is lost, leaving the field
    empty so ``chat_send_button`` (which only renders when messageText is
    non-empty) disappears and the send tap errors "not visible". Collapse
    newlines to a single space so the whole body stays in the field as one
    message and the send button stays present.
    """
    # Normalise CRLF/CR then collapse any run of newlines (and surrounding
    # spaces) into a single space; squeeze remaining whitespace runs.
    flat = re.sub(r"[ \t]*[\r\n]+[ \t]*", " ", text)
    flat = re.sub(r"[ \t]{2,}", " ", flat)
    return flat.strip()


def _send_dm_fill_form(text: str) -> Optional[str]:
    """Tap `chat_message_field` and type `text` without tapping send.

    Returns None on success or a precondition message on failure. Used by
    both `send_dm` (one-shot commit) and `prepare_send_dm` (capture-only).
    Stops short of tapping `chat_send_button` so the caller decides
    whether to commit.

    Multi-line input is flattened (see ``_flatten_dm_text``) because the
    single-line TextField's onSubmit fires on a newline and would otherwise
    send a truncated message and clear the field.
    """
    sim = SimulatorBridge.get()
    body = _flatten_dm_text(text)
    # Precondition: a chat must actually be open (chat_message_field in tree).
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    if "chat_message_field" not in tree:
        return (
            "Could not focus DM message field: no chat is open. Open a chat "
            "first via open_dm_with(contact_name=...)."
        )
    # Type the (flattened) body, then CONFIRM chat_send_button is now in the
    # tree (it only renders when messageText is non-empty — ChatDetailView
    # line 418/424). If it's absent the text didn't land (focus race / a
    # stray newline submitted+cleared it); re-focus and retype before giving
    # up, so the caller's send tap doesn't hit a hidden button.
    for _attempt in range(3):
        try:
            sim.tap_id("chat_message_field"); sim.wait(0.3)
            sim.type_text(body); sim.wait(0.4)
        except Exception as exc:
            return (
                f"Could not focus DM message field. Open a chat first via "
                f"open_dm_with(contact_name=...). Error: {str(exc)[:120]}"
            )
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "chat_send_button" in tree:
            return None
        sim.wait(0.3)
    return (
        "Could not confirm the DM composer was ready: chat_send_button did not appear "
        "(the message field "
        "may not have captured the text). Call observe() to verify a chat is "
        "open, then retry send_dm."
    )


@mcp.tool()
def send_dm(text: str) -> str:
    """Send a DM in the currently open chat.

    Args:
        text: Message body. Typed into ``chat_message_field`` and
            committed by tapping ``chat_send_button``.

    Precondition: a chat must be open (call
    ``open_dm_with(contact_name=...)`` first).

    Legacy single-verb commit; prefer ``prepare_send_dm`` +
    ``confirm_send_dm`` for new code.
    """
    sim = SimulatorBridge.get()
    err = _send_dm_fill_form(text)
    if err:
        return err
    try:
        sim.tap_id("chat_send_button"); sim.wait(0.6)
    except Exception as exc:
        return (
            f"Could not tap Send: chat_send_button not visible. The message "
            f"field may have lost focus. Retry send_dm. Error: {str(exc)[:100]}"
        )
    # Verify the message bubble rendered: sendMessage appends the text to the
    # conversation and clears the field, so the body should now be on screen
    # as a sent bubble (and chat_send_button should be gone — field empty).
    body = _flatten_dm_text(text)
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    head = body[:24]
    token = ""
    for word in body.split():
        w = "".join(ch for ch in word if ch.isalnum())
        if len(w) >= 4:
            token = w; break
    if (head and head in tree) or (token and token in tree):
        return f"Sent DM: '{text[:60]}'"
    return (
        "Could not confirm the message bubble rendered in the "
        "chat. Call observe() to verify; retry send_dm if the message is "
        "absent."
    )


@mcp.tool()
def prepare_send_dm(text: str) -> dict:
    """Type `text` into the DM compose field WITHOUT tapping send.

    `text` is the message body to stage. PRECONDITION: a DM chat must be
    open (use `open_dm_with(contact_name=...)` first).

    On success, returns ``{ok: True, action: "prepare_send_dm",
    draft_id, summary: {text}}``. The agent should inspect the summary,
    then pass the ``draft_id`` to ``confirm_send_dm`` to actually send.
    The draft expires after the `IOSWORLD_DRAFT_TTL_SECONDS` TTL
    (default 10 minutes) or when the simulator session resets.

    On precondition failure, returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _send_dm_fill_form(text)
    if err:
        return {"ok": False, "action": "prepare_send_dm", "message": err}
    summary = {"text": text}
    draft_id = ts.create_draft("lockedin", "send_dm", summary)
    return {
        "ok": True,
        "action": "prepare_send_dm",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_send_dm(draft_id) to commit.",
    }


@mcp.tool()
def confirm_send_dm(draft_id: str) -> dict:
    """Commit a DM previously staged by ``prepare_send_dm``.

    `draft_id` is the id returned by ``prepare_send_dm``. The draft must
    still be present (not consumed, not expired). Returns
    ``{ok: True, action: "confirm_send_dm", evidence: <summary>}`` on
    success.

    If the draft is missing or expired, returns a controlled-failure
    response and does not tap the Send button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_send_dm",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_send_dm first.",
        }
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("chat_send_button"); sim.wait(0.5)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_send_dm",
            "message": "Send button not found in current UI; verify the DM chat is still open.",
        }
    payload = draft.get("payload", {}) or {}
    body = _flatten_dm_text(payload.get("text", ""))
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    head = body[:24]
    token = ""
    for word in body.split():
        w = "".join(ch for ch in word if ch.isalnum())
        if len(w) >= 4:
            token = w
            break
    if not ((head and head in tree) or (token and token in tree)):
        return {
            "ok": False,
            "action": "confirm_send_dm",
            "message": "Tapped Send but could not verify the DM bubble rendered.",
            "evidence": payload,
        }
    return {
        "ok": True,
        "action": "confirm_send_dm",
        "evidence": payload,
    }


@mcp.tool()
def message_contact(contact_name: str, text: str) -> str:
    """Open the DM with a contact and send a message in one call.

    Args:
        contact_name: Contact display name; see ``open_dm_with`` for
            slug rules and seed contacts.
        text: Message body typed into ``chat_message_field``.

    Self-navigating wrapper: opens (or starts) the DM with the contact —
    reusing ``open_dm_with``'s existing-row-or-New-Message-picker logic —
    then types and sends the message. Works for contacts with no existing
    thread (e.g. Aiden Cross), not just seed conversations.
    """
    sim = SimulatorBridge.get()
    open_result = _open_dm_with_impl(contact_name)
    if not open_result.startswith("Opened DM"):
        # Propagate the precise navigation/resolution failure.
        return open_result
    # The chat sheet should now be open; fill and send. Reuse send_dm's
    # verified-commit logic: _send_dm_fill_form types the (flattened) body and
    # only returns None once chat_send_button has actually rendered (the button
    # only appears when messageText is non-empty), then we tap Send and CONFIRM
    # the message bubble rendered. Without the bubble check a no-op send (sheet
    # collapsed / field lost focus) previously returned "Opened DM ... but could
    # not tap Send" — a non-failure-prefixed string that the envelope wrongly
    # marked ok:true even though nothing was sent.
    err = _send_dm_fill_form(text)
    if err:
        # _send_dm_fill_form already returns a "Could not ..." failure-prefixed
        # string on precondition failure; surface it so the envelope is ok:false.
        return err
    try:
        sim.tap_id("chat_send_button"); sim.wait(0.6)
    except Exception as exc:
        return (
            f"Could not send message to {contact_name}: the Send button "
            f"(chat_send_button) was not tappable, so the message was not "
            f"sent. Retry message_contact. Error: {str(exc)[:100]}"
        )
    # Verify the sent bubble rendered: sendMessage appends the body to the
    # conversation, so the text should now be on screen as a sent bubble.
    body = _flatten_dm_text(text)
    try:
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    head = body[:24]
    token = ""
    for word in body.split():
        w = "".join(ch for ch in word if ch.isalnum())
        if len(w) >= 4:
            token = w; break
    if (head and head in tree) or (token and token in tree):
        return f"Sent DM to {contact_name}: '{text[:60]}'"
    return (
        f"Could not confirm the message to {contact_name} was sent: tapped Send "
        f"but the message bubble did not render in the chat. Call observe() to "
        f"verify, then retry message_contact."
    )


@mcp.tool()
def search_messages_field(query: str) -> str:
    """Search messages via the messaging-list search bar.

    Args:
        query: Free-text query typed into ``messaging_search_field``.

    Self-navigates: opens the messaging panel from Home (switching tabs if
    needed), taps the "Search messages" affordance to reveal the field,
    then types the query.
    """
    sim = SimulatorBridge.get()
    if not _open_messaging_panel(sim):
        return (
            f"Could not open the messaging panel to search for '{query}'. "
            "Call navigate_to_tab('home') then retry."
        )
    # The search TextField (messaging_search_field) only renders once
    # isSearching=true, which is toggled by tapping the "Search messages"
    # button. Tap that affordance, then confirm the field is in the tree.
    for _ in range(2):
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "messaging_search_field" in tree:
            break
        try:
            sim.tap_id("Search messages"); sim.wait(0.5)
        except Exception:
            pass
    # Focus the field and type.
    try:
        sim.tap_id("messaging_search_field"); sim.wait(0.3)
    except Exception:
        pass
    try:
        sim.type_text(query); sim.wait(0.5)
    except Exception as exc:
        return (
            f"Could not focus message search for '{query}'. The messaging "
            f"panel is open; retry search_messages_field. Error: {str(exc)[:120]}"
        )
    return f"Searched messages for '{query}'."


@mcp.tool()
def search_jobs(query: str) -> str:
    """Search jobs via the Jobs tab's search field.

    Args:
        query: Free-text query typed into ``jobs_search_field``.

    Navigates to the Jobs tab automatically.
    """
    sim = SimulatorBridge.get()
    query = query or ""

    def _observe() -> str:
        try:
            return sim.observe_text() or ""
        except Exception:
            return ""

    def _query_token() -> str:
        for word in query.split():
            w = "".join(ch for ch in word if ch.isalnum())
            if len(w) >= 4:
                return w
        return ""

    def _already_showing_results() -> bool:
        tree = _observe()
        token = _query_token()
        if "0 results" in tree or "No jobs found" in tree:
            return False
        return (
            "jobs_search_field" in tree
            and "result" in tree.lower()
            and (not token or token.lower() in tree.lower())
        )

    if _already_showing_results():
        return f"Searched jobs for '{query}'."

    def _goto_jobs() -> None:
        # Any modal sheet (search, compose, messaging) sits on top of the whole
        # TabView, so tapping the Jobs tab leaves the sheet intercepting and the
        # JobsView "Search jobs" affordance is never reachable. Pop it first.
        _dismiss_blocking_sheet(sim)
        tree = _observe()
        if not any(marker in tree for marker in (
            "tab_jobs", "tab_home", "tab_network", "tab_notifications",
            "jobs_search_field", "Search jobs", "jobs_search_bar",
        )):
            try:
                sim.launch_and_observe(BUNDLE_ID)
                sim.wait(0.8)
            except Exception:
                pass
        # SwiftUI TabView's tab-bar buttons are addressable by the tab_jobs
        # accessibility identifier (it propagates here) or the visible label.
        for tab_id in ("tab_jobs", "Jobs"):
            try:
                sim.tap_id(tab_id); sim.wait(0.5); break
            except Exception:
                continue

    def _reveal_field() -> bool:
        # JobsView renders `jobs_search_field` only after `showSearchResults`
        # is toggled on (JobsView.swift line 164/169). At rest the screen shows
        # a "Search jobs" button (no id) that toggles showSearchResults=true and
        # focuses the field via a 0.3s asyncAfter (line 188-192). Tap the
        # affordance, then poll until `jobs_search_field` is actually in the
        # tree before typing — a fixed wait races the toggle/focus on a cold
        # first open (the root cause of the "Could not focus" failures).
        if "jobs_search_field" in _observe():
            return True
        for affordance in ("Search jobs", "jobs_search_bar"):
            try:
                sim.tap_id(affordance); sim.wait(0.5); break
            except Exception:
                continue
        for _ in range(4):
            tree = _observe()
            if "jobs_search_field" in tree:
                return True
            # A transient WDA getPageSource hiccup can return "" even though the
            # field is up; probe directly by trying to tap it. If the tap
            # succeeds the field exists — treat reveal as done.
            if not tree:
                try:
                    sim.tap_id("jobs_search_field"); sim.wait(0.2)
                    return True
                except Exception:
                    pass
            sim.wait(0.4)
        return False

    def _focus_type_verify() -> Optional[bool]:
        # Returns True if results rendered, False if typed-but-unverified,
        # None if the field could not be focused at all.
        try:
            sim.tap_id("jobs_search_field"); sim.wait(0.3)
            _clear_field(sim, "jobs_search_field")
            sim.type_text(query); sim.wait(0.6)
        except Exception:
            return None
        tree = _observe()
        # JobsView shows "N result(s)" (line 667) once showSearchResults is on,
        # and the typed query echoes back in jobs_search_field's value. Either
        # confirms the search actually ran.
        token = _query_token()
        if "result" in tree.lower() or (token and token in tree):
            return True
        return False

    last = None
    for _attempt in range(2):
        _goto_jobs()
        if not _reveal_field():
            last = "reveal"
            continue
        res = _focus_type_verify()
        if res is True:
            return f"Searched jobs for '{query}'."
        if res is False:
            # Typed but couldn't confirm results — still a soft success on the
            # first try; retry once for a clean verification, else accept.
            last = "unverified"
            continue
        last = "focus"  # None -> couldn't focus the field; retry from Jobs tab

    if last == "unverified":
        # The field accepted the query but the results list wasn't confirmed in
        # the tree (slow render). Report success — the query did land.
        return f"Searched jobs for '{query}'."
    return (
        f"Could not focus jobs search for '{query}'. Navigate to the Jobs tab, "
        f"tap the 'Search jobs' bar, then retry search_jobs."
    )


@mcp.tool()
def list_jobs(query: str = "") -> dict:
    """List seed jobs with stable ids, optionally filtered by title/company.

    Args:
        query: Optional free-text filter over job id, title, company, and
            location. Empty returns the full seed job catalog.

    Returns ``{ok, jobs, count}``; pass a returned ``id`` to
    ``open_job_detail`` or ``save_job_direct``.
    """
    q = (query or "").strip().lower()
    jobs = []
    for job in _job_catalog():
        hay = f"{job['id']} {job['title']} {job['company']} {job['location']}".lower()
        if q and q not in hay and not all(w in hay for w in re.split(r"[^a-z0-9]+", q) if w):
            continue
        jobs.append(job)
    return {"ok": True, "jobs": jobs, "count": len(jobs)}


@mcp.tool()
def open_job_detail(job: str) -> dict:
    """Open a LockedIn job detail sheet by seed job id/title/company.

    The app does not expose per-row job accessibility ids in JobsView, so this
    resolves against the seed catalog, opens Jobs search, types the title, and
    taps the visible title/company text. Ambiguous company/title queries return
    candidates instead of opening the wrong job.
    """
    resolved = _resolve_job(job)
    if not resolved.get("ok"):
        out = {"ok": False, "action": "open_job_detail",
               "message": resolved.get("message")}
        if resolved.get("candidates"):
            out["candidates"] = resolved["candidates"]
        return out
    target = resolved["job"]
    sim = SimulatorBridge.get()
    def _target_row_visible() -> bool:
        try:
            tree = sim.observe_text() or ""
        except Exception:
            return False
        if "0 results" in tree or "No jobs found" in tree:
            return False
        return (
            f"job_result_row_{target['id']}" in tree
            or f"job_row_{target['id']}" in tree
            or (target["title"] in tree and target["company"] in tree and "result" in tree.lower())
        )

    if not _target_row_visible():
        search_jobs(target["title"])
    if not _target_row_visible():
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if "0 results" in tree or "No jobs found" in tree:
            try:
                sim.tap_id("chevron.left")
                sim.wait(0.5)
            except Exception:
                pass
            search_jobs(target["title"])
    if not _target_row_visible():
        _rewrite_jobs_search_field(sim, target["title"])
    _dismiss_system_overlay(sim)
    for row_id in (f"job_result_row_{target['id']}", f"job_row_{target['id']}"):
        try:
            sim.tap_id(row_id)
            sim.wait(0.7)
        except Exception:
            pass
        if _job_detail_open(sim):
            return {
                "ok": True,
                "action": "open_job_detail",
                "job": target,
                "message": f"Opened detail for {target['title']} at {target['company']}.",
            }
    for label in (target["title"], target["company"]):
        for _ in range(3):
            try:
                sim.tap_id(label)
                sim.wait(0.7)
            except Exception:
                pass
            if _job_detail_open(sim):
                return {
                    "ok": True,
                    "action": "open_job_detail",
                    "job": target,
                    "message": f"Opened detail for {target['title']} at {target['company']}.",
                }
            if _tap_job_result_row(sim, target) and _job_detail_open(sim):
                return {
                    "ok": True,
                    "action": "open_job_detail",
                    "job": target,
                    "message": f"Opened detail for {target['title']} at {target['company']}.",
                }
            try:
                sim.swipe("up")
                sim.wait(0.25)
            except Exception:
                break
    return {
        "ok": False,
        "action": "open_job_detail",
        "job": target,
        "message": (
            "Resolved the job but could not open its detail sheet from the "
            "search results. Tap the visible row with an available low-level "
            "tool if this run exposes one, or retry after surfacing the row."
        ),
    }


@mcp.tool()
def follow_company(company: str = "", follow: bool = True) -> dict:
    """Follow/unfollow a company from an open job detail sheet.

    Args:
        company: Optional company name. If provided and no matching job detail
            is open, opens the first seed job for that company. This is UI
            scoped because LockedIn does not persist followed companies.
        follow: True to follow; False to unfollow.

    Returns a controlled failure if no job detail/about-company section can be
    reached.
    """
    sim = SimulatorBridge.get()
    target_company = (company or "").strip()
    if target_company:
        try:
            tree = sim.observe_text() or ""
        except Exception:
            tree = ""
        if target_company not in tree or not _job_detail_open(sim):
            matches = [
                j for j in _job_catalog()
                if target_company.lower() in j["company"].lower()
            ]
            if not matches:
                return {"ok": False, "action": "follow_company",
                        "message": f"No seed jobs found for company '{company}'."}
            opened = open_job_detail(matches[0]["id"])
            if not opened.get("ok"):
                return {"ok": False, "action": "follow_company",
                        "message": f"Could not open a job detail for '{company}': {opened.get('message')}"}
    elif not _job_detail_open(sim):
        return {"ok": False, "action": "follow_company",
                "message": "Open a job detail first, or pass company=<name>."}

    for _ in range(8):
        tree = sim.observe_text() or ""
        if "About the company" in tree and ("Follow" in tree or "Following" in tree):
            if follow and "Following" in tree:
                return {"ok": True, "action": "follow_company",
                        "company": target_company or None, "following": True,
                        "message": "Company is already followed."}
            if not follow and "Following" not in tree and "Follow" in tree:
                return {"ok": True, "action": "follow_company",
                        "company": target_company or None, "following": False,
                        "message": "Company is already not followed."}
            label = "Follow" if follow else "Following"
            try:
                sim.tap_id(label)
                sim.wait(0.5)
            except Exception as exc:
                return {"ok": False, "action": "follow_company",
                        "message": f"Could not tap '{label}' in the company section: {str(exc)[:100]}"}
            tree_after = sim.observe_text() or ""
            following = "Following" in tree_after
            return {"ok": following == bool(follow), "action": "follow_company",
                    "company": target_company or None, "following": following}
        try:
            sim.swipe("up")
            sim.wait(0.3)
        except Exception:
            break
    return {"ok": False, "action": "follow_company",
            "message": "Could not reach the About the company follow button on the job detail sheet."}


# ── Direct-state-write tools
#
# LockedIn's `AppPersistence.swift` only writes 3 keys to UserDefaults:
#   lockedin_sim_saved_job_ids
#   lockedin_sim_liked_post_ids
#   lockedin_sim_dismissed_invitation_ids
# Everything else (DMs, posts, conversations, search results) is held in
# in-memory @StateObjects and reset on every launch — there's literally
# no database to write to for those. Tasks that require sending DMs or
# composing posts must use UI-driven tools (existing) or CUA pixel
# fallback. Tasks that involve saving/liking/dismissing CAN be unblocked
# via direct UserDefaults writes below.

def _ld_prefs() -> dict:
    return dl.read_user_defaults(BUNDLE_ID) or {}


def _ld_write_prefs(prefs: dict) -> None:
    dl.write_user_defaults(BUNDLE_ID, prefs)
    dl.reload_app(BUNDLE_ID)


_KNOWN_POST_IDS = {
    *(f"post_{i}" for i in range(1, 21)),
    "post_elena_new_job",
    "post_with_photo",
    "post_with_document",
    "post_with_link",
    "post_user_monitoring",
}


def _valid_numbered_id(value: str, prefix: str, low: int, high: int) -> bool:
    m = re.fullmatch(rf"{re.escape(prefix)}_(\d+)", value or "")
    return bool(m and low <= int(m.group(1)) <= high)


@mcp.tool()
def save_job_direct(job_id: str) -> dict:
    """Mark a job as saved via direct UserDefaults write.

    Args:
        job_id: Stable seed job id. The real ids are ``job_1`` ..
            ``job_N`` (e.g. ``job_1`` = "Staff Platform Engineer",
            ``job_2`` = "Senior DevOps Engineer"). Get the exact id from
            ``list_persistable_state`` (for already-saved jobs) or the
            JobsView accessibility tree; do NOT invent a descriptive id
            like ``job_<role>_<company>`` — those don't match any seed
            job and grading against the real ``job_N`` id will miss. Any
            string is stored as-is, but only a real ``job_N`` corresponds
            to an actual listing. Already-saved ids are idempotent.

    Writes to ``lockedin_sim_saved_job_ids`` and reloads the app —
    bypasses the in-app save button. Use for grading "this job is in
    saved jobs". Returns ``{ok: True, saved_jobs: [...]}``.
    """
    if not _valid_numbered_id(job_id, "job", 1, 116):
        return {
            "ok": False,
            "action": "save_job_direct",
            "message": (
                f"Unknown job_id '{job_id}'. Use a real seed id like job_1 "
                "through job_116 from the Jobs accessibility tree."
            ),
        }
    prefs = _ld_prefs()
    saved = set(prefs.get("lockedin_sim_saved_job_ids", []) or [])
    saved.add(job_id)
    prefs["lockedin_sim_saved_job_ids"] = sorted(saved)
    _ld_write_prefs(prefs)
    return {"ok": True, "saved_jobs": sorted(saved),
            "message": f"Saved job '{job_id}' ({len(saved)} total)."}


@mcp.tool()
def like_post_direct(post_id: str) -> dict:
    """Like a feed post via direct UserDefaults write.

    Args:
        post_id: Stable seed post id. The real ids are ``post_1`` ..
            ``post_N`` plus a few named ones (e.g. ``post_elena_new_job``);
            do NOT invent a descriptive id like ``post_announcement_q4``
            — no such post exists and grading against the real id will
            miss. For SCHEDULED posts the id is embedded in the tree as
            ``post_scheduled_badge_<post_id>`` (also
            ``detail_scheduled_badge_<post_id>`` on the detail screen), so
            you can read it there. Note ``post_attachment_<id>`` carries
            the ATTACHMENT id, not the post id. Any string is stored as-is
            but only a real ``post_N`` maps to an actual feed post.
            Already-liked ids are idempotent.

    Writes to ``lockedin_sim_liked_post_ids`` and reloads the app.
    Returns ``{ok: True, liked_posts: [...]}``.
    """
    if post_id not in _KNOWN_POST_IDS:
        return {
            "ok": False,
            "action": "like_post_direct",
            "message": (
                f"Unknown post_id '{post_id}'. Use a real seed id such as "
                "post_1..post_20, post_elena_new_job, post_with_photo, "
                "post_with_document, post_with_link, or post_user_monitoring."
            ),
        }
    prefs = _ld_prefs()
    liked = set(prefs.get("lockedin_sim_liked_post_ids", []) or [])
    liked.add(post_id)
    prefs["lockedin_sim_liked_post_ids"] = sorted(liked)
    _ld_write_prefs(prefs)
    return {"ok": True, "liked_posts": sorted(liked),
            "message": f"Liked post '{post_id}'."}


@mcp.tool()
def dismiss_invitation_direct(invitation_id: str) -> dict:
    """Dismiss a connection invitation via direct UserDefaults write.

    Args:
        invitation_id: Stable seed invitation id from the My Network
            tab. The real ids are ``inv_1`` .. ``inv_N`` (e.g. ``inv_1``
            = Priya Raman, ``inv_2`` = Arnav Srikanth). Use a real
            ``inv_N`` id, not the inviter's name. Already-dismissed ids
            are idempotent.

    Writes to ``lockedin_sim_dismissed_invitation_ids`` and reloads
    the app. Returns ``{ok: True, dismissed_invitations: [...]}``.
    """
    if not _valid_numbered_id(invitation_id, "inv", 1, 6):
        return {
            "ok": False,
            "action": "dismiss_invitation_direct",
            "message": (
                f"Unknown invitation_id '{invitation_id}'. Use a real seed id "
                "inv_1 through inv_6 from the My Network tab."
            ),
        }
    prefs = _ld_prefs()
    dismissed = set(prefs.get("lockedin_sim_dismissed_invitation_ids", []) or [])
    dismissed.add(invitation_id)
    prefs["lockedin_sim_dismissed_invitation_ids"] = sorted(dismissed)
    _ld_write_prefs(prefs)
    return {"ok": True, "dismissed_invitations": sorted(dismissed),
            "message": f"Dismissed invitation '{invitation_id}'."}


@mcp.tool()
def list_persistable_state() -> dict:
    """Inspect what LockedIn currently has persisted in UserDefaults.

    Returns:
        ``{saved_jobs: [<id>...], liked_posts: [<id>...],
        dismissed_invitations: [<id>...]}`` — useful before deciding
        whether a direct-write tool is needed.
    """
    prefs = _ld_prefs()
    return {
        "saved_jobs": prefs.get("lockedin_sim_saved_job_ids", []) or [],
        "liked_posts": prefs.get("lockedin_sim_liked_post_ids", []) or [],
        "dismissed_invitations": prefs.get("lockedin_sim_dismissed_invitation_ids", []) or [],
    }


if __name__ == "__main__":
    mcp.run()
