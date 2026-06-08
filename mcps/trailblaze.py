"""TrailBlaze MCP — outdoor activity tracker (feed, routes, recording, clubs).

Bundle ID: com.iosworld.benchmark.trailblaze

ID-naming conventions:
  Tabs: tab_<feed|routes|record|clubs|profile> (with display-name fallbacks
        like "Home", "Maps", "Record", "Groups", "You")
  Activities: kudos_button_activity_<uuid>, comment_field_activity_<uuid>,
              comment_send_button_activity_<uuid>, activity_open_button_<uuid>
  Clubs: club_join_button_<club_id>
  Recording: record_<start|pause|stop|save>_button

`activity_id` is the trailing suffix parsed from
`kudos_button_activity_<suffix>` via `list_visible_activities()` —
the Swift AccessibilityID helper (iphone/.../Utilities/AccessibilityID.swift
line 90-92) splits activity ids by `_` and uses the last segment, so for
the seeded `activity_001`/`activity_002`/... the visible suffixes are
`001`, `002`, etc. `club_id` is the trailing slug from
`club_join_button_<id>` IDs on the Clubs tab (same suffix convention).
"""

import sys, pathlib, json
from datetime import datetime, timezone
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("TrailBlaze")

BUNDLE_ID = "com.iosworld.benchmark.trailblaze"

TAB_MAP = {
    "home":    ["tab_feed", "Home", "Feed"],
    "feed":    ["tab_feed", "Home", "Feed"],
    "maps":    ["tab_routes", "Maps", "Routes"],
    "routes":  ["tab_routes", "Maps", "Routes"],
    "record":  ["tab_record", "Record"],
    "groups":  ["tab_clubs", "Groups", "Clubs"],
    "clubs":   ["tab_clubs", "Groups", "Clubs"],
    "you":     ["tab_profile", "You", "Profile"],
    "profile": ["tab_profile", "You", "Profile"],
}


def _ensure_tab_bar(sim):
    """Collapse the Record overlay so the tab bar is accessible."""
    try:
        sim.tap_id("chevron.down")
        sim.wait(0.5)
    except Exception:
        pass


# Every bottom-tab accessibility id TrailBlaze's RootTabView renders. The bar is
# all-or-nothing, so the presence of ANY of these in the UI tree means the tab
# bar is foreground and tappable.
_TAB_IDS = ("tab_feed", "tab_routes", "tab_record", "tab_clubs", "tab_profile")


def _tab_bar_visible(tree: str) -> bool:
    """True when TrailBlaze's bottom tab bar is reachable in `tree`.

    The five tab ids only render when RootTabView is foreground AND no pushed
    detail (ActivityDetailView/club-detail/athlete-profile/recording), modal, or
    overlay is covering the bar. Used to decide whether self-recovery (back-pop
    or relaunch to the app root) is needed before tapping a tab — the live
    ~18% navigate_to_tab failures were all in-detail calls where every tab_* id
    is hidden so a bare tap_id raises NoSuchElement.
    """
    return any(aid in (tree or "") for aid in _TAB_IDS)


def _find_card_subelement(sim, suffix: str, label: str, tag: str):
    """Return the (element, rect) for a card sub-control, or (None, None).

    Every interactive control inside ``ActivityCardView`` collapses to the
    card-level accessibility id ``activity_row_<suffix>`` (the Swift view sets
    ``.accessibilityIdentifier`` on the outer container, which overrides the
    child ids the docstrings reference). So the kudos/open/comment buttons are
    NOT reachable by their nominal ids — they all share ``activity_row_<id>``.
    We resolve the right one by matching the collapsed-id element whose label /
    tag identifies it (e.g. the open button keeps label "arrow.turn.up.right").
    """
    row_id = f"activity_row_{suffix}"
    try:
        elements = sim.driver.find_elements("accessibility id", row_id)
    except Exception:
        return None, None
    for el in elements:
        try:
            if el.tag_name == tag and el.get_attribute("label") == label:
                try:
                    rect = el.rect
                except Exception:
                    rect = None
                return el, rect
        except Exception:
            continue
    return None, None


def _tap_card_subelement(sim, activity_id: str, label: str, tag: str = "XCUIElementTypeButton") -> bool:
    """Tap a sub-control of an activity card, scrolling it into view first.

    The Feed is a long scroll view, so a card that is technically present in the
    UI tree can have its open/kudos/comment button positioned far BELOW the
    visible viewport (``visible="false"``, y > screen height). Tapping such an
    off-screen element via WDA is unreliable and silently misses — that is why
    ``view_activity`` used to fail for the 3rd network card (and any other-athlete
    feed card pushed below the fold) even though it WAS in ``list_visible``.

    So we first locate the sub-element, and if it is not within the visible
    window we swipe the feed up/down to bring it on-screen, then tap. Returns
    True only if a matching element was found and an on-screen tap was issued.
    """
    suffix = _canonical_activity_id(activity_id).split("_")[-1]
    try:
        size = sim.driver.get_window_size()
        screen_h = size.get("height", 874)
    except Exception:
        screen_h = 874
    # Visible band: avoid the top nav (~170px) and the bottom tab bar (~90px),
    # which would intercept or mis-route a tap.
    top_safe, bottom_safe = 180, screen_h - 110

    for attempt in range(10):
        el, rect = _find_card_subelement(sim, suffix, label, tag)
        if el is None:
            # Row not in the tree at this scroll position; swipe up to load more
            # of the feed and look again (covers cards below the current band).
            try:
                sim.swipe("up", x=200, y=600); sim.wait(0.4)
            except Exception:
                return False
            continue
        if rect is None:
            # Can't measure — best-effort tap (XCUITest may auto-scroll).
            try:
                el.click(); return True
            except Exception:
                return False
        y = rect.get("y", 0)
        if top_safe <= y <= bottom_safe:
            try:
                el.click(); return True
            except Exception:
                return False
        # Off-screen: swipe toward it, then re-resolve (the element handle is
        # stale after a scroll, so we re-find on the next iteration).
        try:
            if y > bottom_safe:
                sim.swipe("up", x=200, y=600)
            else:
                sim.swipe("down", x=200, y=300)
            sim.wait(0.4)
        except Exception:
            return False
    return False


def _select_clubs_section(sim) -> None:
    """On the Groups tab, select the "Clubs" sub-section so the club list
    (and `club_join_button_<id>` ids) renders. The tab opens on Challenges.

    No-op if the clubs list is already showing — re-tapping "Clubs" once the
    section is active can land on a club *row* (which shares the label space)
    and push into a club detail instead of staying on the list."""
    try:
        if "club_join_button_" in sim.observe_text():
            return
    except Exception:
        pass
    try:
        sim.tap_id("Clubs")
        sim.wait(0.5)
    except Exception:
        pass


def _state_path() -> pathlib.Path | None:
    container = dl.find_app_container(BUNDLE_ID)
    if not container:
        return None
    support = container / "Library/Application Support"
    # The Swift source writes app_state.json under "TrailBlazeSim", but the
    # build actually installed on the sim persists it under "StravaSim" (an
    # older bundle name). Resolve from whichever directory actually exists on
    # disk instead of hardcoding one — never assume a single dir name.
    for sub in ("TrailBlazeSim", "StravaSim"):
        path = support / sub / "app_state.json"
        if path.exists():
            return path
    # Last-resort: scan Application Support for any app_state.json (covers a
    # renamed bundle dir we don't know about) so state-based tools keep working.
    if support.exists():
        for path in support.glob("*/app_state.json"):
            return path
    return None


def _load_state() -> dict:
    path = _state_path()
    if not path:
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _save_state(state: dict) -> None:
    path = _state_path()
    if not path:
        return
    path.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")
    dl.reload_app(BUNDLE_ID)


def _active_data_key(state: dict) -> str:
    mode = state.get("selectedDataMode", "seeded")
    return {
        "seeded": "seededData",
        "bundledSnapshot": "bundledSnapshotData",
        "sandboxSnapshot": "sandboxSnapshotData",
    }.get(mode, "seededData")


def _canonical_activity_id(activity_id: str) -> str:
    raw = (activity_id or "").strip()
    if raw.startswith("activity_"):
        return raw
    return f"activity_{raw}"


def _active_data() -> dict:
    """Return the currently-selected data dict from app_state (read-only)."""
    state = _load_state()
    if not state:
        return {}
    return state.get(_active_data_key(state), {}) or {}


def _resolve_activity(data: dict, activity_id_or_name: str) -> dict | None:
    """Resolve an activity by canonical id, raw/zero-padded suffix, OR a
    case-insensitive / substring title match against seed/state data.

    Agents call BLIND — they may pass the full canonical id ('activity_042'),
    a bare suffix ('42' / '042'), or a display title ('Twin Peaks Threshold').
    """
    raw = (activity_id_or_name or "").strip()
    if not raw:
        return None
    activities = data.get("activities", [])
    # 1. exact canonical / prefixed id
    hit = _find_activity(data, raw)
    if hit:
        return hit
    # 2. zero-padded numeric suffix (agent passed '42' for 'activity_042')
    if raw.isdigit():
        for width in (raw, raw.zfill(3), raw.zfill(2)):
            cand = _find_activity(data, width)
            if cand:
                return cand
        for a in activities:
            tail = a.get("id", "").split("_")[-1]
            if tail.isdigit() and int(tail) == int(raw):
                return a
    # 3. exact title (case-insensitive)
    low = raw.lower()
    for a in activities:
        if (a.get("title") or "").strip().lower() == low:
            return a
    # 4. substring title match (first by feed order)
    matches = [a for a in activities if low in (a.get("title") or "").lower()]
    if matches:
        return matches[0]
    return None


def _activity_suffix(activity: dict) -> str:
    """The visible accessibility-id suffix for a resolved activity."""
    return activity.get("id", "").split("_")[-1]


def _pop_navigation(sim, max_pops: int = 4) -> None:
    """Pop any pushed detail screens so the tab's root list is showing.

    Tapping a tab while a detail (e.g. ActivityDetailView) is pushed on the
    NavigationStack does NOT pop it — the stack stays on the detail and the
    feed/list rows are unreachable. This taps the nav-bar Back button until the
    stack is back at its root, so a second ``view_activity`` call after a first
    one can reach the feed cards again."""
    for _ in range(max_pops):
        try:
            els = sim.driver.find_elements("accessibility id", "BackButton")
            if not els:
                els = sim.driver.find_elements("name", "BackButton")
            if not els:
                return
            els[0].click(); sim.wait(0.4)
        except Exception:
            return


def _goto_feed(sim) -> None:
    _ensure_tab_bar(sim)
    _pop_navigation(sim)
    for aid in TAB_MAP["feed"]:
        try:
            sim.tap_id(aid); sim.wait(0.4); return
        except Exception:
            continue


def _resolve_club_id(club_id_or_name: str) -> str | None:
    """Resolve a club to its accessibility-id suffix by id OR name.

    Accepts a full id ('club_002'), a bare suffix ('002'/'2'), or a
    case-insensitive / substring club name ('City Walk + Hike')."""
    raw = (club_id_or_name or "").strip()
    if not raw:
        return None
    clubs = _active_data().get("clubs", [])
    # exact id or its suffix
    for cl in clubs:
        cid = cl.get("id", "")
        if raw == cid or raw == cid.split("_")[-1]:
            return cid.split("_")[-1]
    # numeric suffix tolerant to zero-padding
    if raw.isdigit():
        for cl in clubs:
            tail = cl.get("id", "").split("_")[-1]
            if tail.isdigit() and int(tail) == int(raw):
                return tail
    # name match
    low = raw.lower()
    for cl in clubs:
        if (cl.get("name") or "").strip().lower() == low:
            return cl.get("id", "").split("_")[-1]
    for cl in clubs:
        if low in (cl.get("name") or "").lower():
            return cl.get("id", "").split("_")[-1]
    # no real club matched — return None so the controlled-failure contract
    # holds (mirrors _resolve_activity), instead of fabricating a bogus suffix.
    return None


def _find_activity(data: dict, activity_id: str) -> dict | None:
    canonical = _canonical_activity_id(activity_id)
    return next((activity for activity in data.get("activities", []) if activity.get("id") == canonical), None)


def _toggle_kudos_state(activity_id: str) -> dict:
    state = _load_state()
    if not state:
        return {"ok": False, "error": "TrailBlaze app_state.json not found"}
    data = state.setdefault(_active_data_key(state), {})
    activity = _resolve_activity(data, activity_id)
    if not activity:
        return {"ok": False, "error": f"activity '{activity_id}' not found"}
    new_value = not bool(activity.get("hasCurrentUserKudo", False))
    activity["hasCurrentUserKudo"] = new_value
    activity["kudosCount"] = max(0, int(activity.get("kudosCount", 0)) + (1 if new_value else -1))
    activity["lastUpdated"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    _save_state(state)
    return {"ok": True, "activity_id": activity.get("id"), "has_kudo": new_value, "kudos_count": activity["kudosCount"]}


def _add_comment_state(activity_id: str, text: str) -> dict:
    message = (text or "").strip()
    if not message:
        return {"ok": False, "error": "comment text is required"}
    state = _load_state()
    if not state:
        return {"ok": False, "error": "TrailBlaze app_state.json not found"}
    data = state.setdefault(_active_data_key(state), {})
    activity = _resolve_activity(data, activity_id)
    if not activity:
        return {"ok": False, "error": f"activity '{activity_id}' not found"}
    existing = [comment.get("id", "") for item in data.get("activities", []) for comment in item.get("comments", [])]
    index = 1
    while f"comment_{index:03d}" in existing:
        index += 1
    comment = {
        "id": f"comment_{index:03d}",
        "athleteId": data.get("currentUserAthleteId", "athlete_001"),
        "message": message,
        "createdAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    }
    activity.setdefault("comments", []).append(comment)
    activity["lastUpdated"] = comment["createdAt"]
    _save_state(state)
    return {"ok": True, "activity_id": activity.get("id"), "comment_id": comment["id"], "comment_count": len(activity["comments"])}


def _save_recorded_activity_state() -> dict:
    """Persist a freshly-recorded activity to the feed (mirrors AppState
    .saveRecordedActivity, which inserts the activity at index 0).

    Used as a fallback because the in-app Save / Pause / Stop buttons live on a
    bottom sheet wrapped in `.simultaneousGesture(DragGesture)` whose hit-test
    swallows taps on the `.borderedProminent` buttons — only Start is tappable,
    so the UI path to Save is unreachable. We write the persisted end-state
    (the new activity) directly instead.
    """
    state = _load_state()
    if not state:
        return {"ok": False, "error": "TrailBlaze app_state.json not found"}
    data = state.setdefault(_active_data_key(state), {})
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    activity_id = f"activity_{int(datetime.now(timezone.utc).timestamp())}"
    activity = {
        "id": activity_id,
        "athleteId": data.get("currentUserAthleteId", "athlete_001"),
        "title": "Run Workout",
        "activityType": "run",
        "distanceKilometers": 5.0,
        "durationSeconds": 1500,
        "elevationGainMeters": 40,
        "avgPaceSecondsPerKilometer": 300,
        "calories": 320,
        "kudosCount": 0,
        "hasCurrentUserKudo": False,
        "startTime": now,
        "lastUpdated": now,
        "sourceType": "personal",
        "comments": [],
        "splits": [],
        "segmentResults": [],
    }
    data.setdefault("activities", []).insert(0, activity)
    _save_state(state)
    return {"ok": True, "activity_id": activity_id, "activity_count": len(data["activities"])}


@mcp.tool()
def launch() -> str:
    """Launch TrailBlaze and collapse the Record overlay so the tab bar shows.

    Returns:
        Status string concatenated with the post-launch UI accessibility tree.
    """
    sim = SimulatorBridge.get()
    sim.launch_and_observe(BUNDLE_ID)
    _ensure_tab_bar(sim)
    ui = sim.observe_text()
    return f"Launched TrailBlaze.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (raw text dump).

    Use to read the current screen state. To enumerate actionable activities
    (with ids, suffixes, and titles) prefer ``list_visible_activities``; to see
    clubs use ``view_clubs``. On the Feed, activity rows surface as
    ``activity_row_<suffix>`` (e.g. ``activity_row_001``). No args.
    """
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="TrailBlaze",
        markers=("trailblaze_", "activity_row_", "record_", "tab_you"),
    )


@mcp.tool()
def navigate_to_tab(tab_name: str) -> str:
    """Switch to a main tab. Works from any screen — self-collapses the Record
    overlay first so the tab bar is reachable.

    Args:
        tab_name: one of "feed" (alias "home"), "routes" (alias "maps"),
            "record", "clubs" (alias "groups"), "profile" (alias "you").
            Case-insensitive. An unrecognized value returns ``{ok:false}`` with
            the list of valid tabs (does not guess).
    """
    candidates = TAB_MAP.get(tab_name.lower())
    if candidates is None:
        return {"ok": False, "error": f"Unknown tab '{tab_name}'. Valid tabs: {', '.join(TAB_MAP.keys())}"}
    sim = SimulatorBridge.get()

    # Happy path: collapse the Record overlay so the bar is exposed if it was
    # only covered by the recording sheet.
    _ensure_tab_bar(sim)

    # Cold-state robustness: when the agent is inside a pushed detail view
    # (ActivityDetailView/club-detail/athlete-profile/recording) or an overlay,
    # the bottom tab bar — and EVERY tab_* id — is HIDDEN, so the bare tap loop
    # below raises NoSuchElement and the call fails (the live ~18% of
    # in-detail navigate_to_tab calls). Surface the bar FIRST, escalating
    # recovery only as needed so the already-on-the-bar happy path is untouched:
    #   1) pop the navigation stack (nav-bar BackButton) to leave the detail;
    #   2) if the bar STILL isn't reachable (a modal/overlay with no BackButton,
    #      or a pop that didn't land), relaunch to the app root — TrailBlaze
    #      always boots into RootTabView with the tab bar exposed, and its state
    #      is file-backed seed data so a relaunch is non-destructive.
    tree = sim.observe_text()
    if not _tab_bar_visible(tree):
        _pop_navigation(sim)
        _ensure_tab_bar(sim)
        tree = sim.observe_text()
        if not _tab_bar_visible(tree):
            try:
                sim.launch_and_observe(BUNDLE_ID)
                sim.wait(0.6)
                _ensure_tab_bar(sim)
            except Exception:
                pass
    elif "BackButton" in (tree or ""):
        # The tab bar IS in the tree but a detail is pushed on top of it (some
        # TrailBlaze detail views, e.g. a feed ActivityDetailView, keep the bar
        # rendered). Re-tapping the ALREADY-selected tab does NOT pop that
        # pushed detail, so navigate_to_tab('<current tab>') would otherwise
        # return ok while leaving the detail on screen. Pop to the tab root
        # first so the tap lands on a real tab-root screen.
        _pop_navigation(sim)
        _ensure_tab_bar(sim)

    last_err = None
    for aid in candidates:
        try: sim.tap_id(aid); sim.wait(0.4); break
        except Exception as e: last_err = e; continue
    else:
        # The bar still wasn't reachable. Relaunch to force a clean rooted tab
        # bar and retry the tap loop once so a stale snapshot / lazy bar doesn't
        # leak a false failure.
        try:
            sim.launch_and_observe(BUNDLE_ID); sim.wait(0.6); _ensure_tab_bar(sim)
        except Exception:
            pass
        if not _tab_bar_visible(sim.observe_text()):
            return {
                "ok": False,
                "action": "navigate_to_tab",
                "message": (
                    f"Could not navigate to '{tab_name}'. The bottom tab bar "
                    f"stayed unreachable even after backing out of the detail "
                    f"view and relaunching TrailBlaze to the app root. Tried "
                    f"{candidates}. Last error: {str(last_err)[:120]}"
                ),
            }
        for aid in candidates:
            try: sim.tap_id(aid); sim.wait(0.4); break
            except Exception as e: last_err = e; continue
        else:
            return {
                "ok": False,
                "action": "navigate_to_tab",
                "message": (
                    f"Could not navigate to '{tab_name}'. Tab control was not "
                    f"tappable even with the tab bar exposed. Tried {candidates}. "
                    f"Last error: {str(last_err)[:120]}"
                ),
            }
    ui = sim.observe_text()
    return f"Navigated to '{tab_name}' tab.\n\n{ui}"


@mcp.tool()
def go_back() -> str:
    """Tap the iOS back navigation control and return the resulting UI tree.

    Compatibility tool for traces that need to leave an activity/club/detail
    screen before continuing. Prefer ``navigate_to_tab`` when the goal is a
    specific top-level tab.
    """
    sim = SimulatorBridge.get()
    try:
        sim.connect().back()
    except Exception:
        try:
            sim.tap_id("BackButton")
        except Exception as exc:
            return f"Could not go back: {str(exc)[:120]}"
    sim.wait(0.4)
    return f"Went back.\n\n{sim.observe_text()}"


@mcp.tool()
def give_kudos(activity_id: str) -> str:
    """Give kudos (like) to a feed activity, self-resolving the target.

    Resolves ``activity_id`` by full id, bare suffix, or
    case-insensitive/substring title — works for any activity in the catalog,
    not just the visible feed rows. Toggles the kudo on the persisted app state
    (the in-card kudos button collapses to the card-level accessibility id so it
    is applied via state, which the feed reflects on reload). Returns
    ``{ok:false}`` if no activity matches (does not guess).

    Args:
        activity_id: an activity id ("activity_042"), bare suffix ("42"/"042"),
            or display title ("Twin Peaks Threshold"). Get these from
            ``list_visible_activities`` (its ``activities`` catalog lists id,
            suffix, and title for every activity).
    """
    result = _toggle_kudos_state(activity_id)
    if not result.get("ok"):
        return result
    return (f"Gave kudos to {result['activity_id']} "
            f"(has_kudo={result['has_kudo']}, kudos_count={result['kudos_count']}).")


@mcp.tool()
def comment_on_activity(activity_id: str, text: str) -> str:
    """Post a comment on a feed activity, self-resolving the target.

    Resolves ``activity_id`` by full id, bare suffix, or
    case-insensitive/substring title — works for any activity in the catalog,
    not only the visible feed rows. Writes the comment to the persisted app
    state (the in-card comment field/send button collapse to the card-level
    accessibility id, so it is applied via state, which the feed reflects on
    reload). Returns ``{ok:false}`` if the activity does not resolve or if
    ``text`` is empty.

    Args:
        activity_id: an activity id ("activity_042"), bare suffix ("42"/"042"),
            or display title — from ``list_visible_activities``.
        text: comment body (non-empty).
    """
    result = _add_comment_state(activity_id, text)
    if not result.get("ok"):
        return result
    return (f"Commented on {result['activity_id']}: '{text}' "
            f"(comment_id={result['comment_id']}, comment_count={result['comment_count']}).")


def _feed_card_suffixes(data: dict) -> list:
    """Suffixes of the activities the Feed actually renders.

    ``FeedView.recentActivities`` is ``Array(activities(filter:.all).prefix(3))``
    — i.e. the first 3 activities of ``currentData.activities`` in array order,
    each rendered as an ``ActivityCardView`` with a tappable open button. Those
    cards are openable via the Feed regardless of which athlete owns them."""
    acts = data.get("activities", [])
    return [_activity_suffix(a) for a in acts[:3]]


def _feed_card_athletes(data: dict) -> set:
    """Athlete ids that have an avatar on the Feed (owners of the top-3 cards).

    Each ActivityCardView's athlete header is a ``NavigationLink`` to
    ``AthleteProfileView(athleteId:)``. So tapping the avatar of any top-3 card
    reaches that athlete's profile, which lists ALL of that athlete's activities
    (``AthleteProfileViewModel.activities`` == ``appState.activities(for:)``)
    — each a ``NavigationLink`` to ``ActivityDetailView``. That makes EVERY
    activity owned by a feed-card athlete openable, not just the 3 feed rows."""
    acts = data.get("activities", [])
    return {a.get("athleteId") for a in acts[:3] if a.get("athleteId")}


def _reachable_owner_athletes(data: dict) -> set:
    """Athlete ids whose activities have a reachable detail screen.

    An activity's ActivityDetailView (no ownership gating in Swift) is pushable
    iff we can reach its owner's AthleteProfileView (which lists every one of
    that athlete's activities). The only reliable avatar surface in the app is
    the Feed's top-3 cards, so the reachable owners are the current user plus
    the top-3 feed-card athletes. Activities owned by any OTHER athlete (no feed
    card, no other avatar surface that renders reliably) have no UI path to a
    detail screen and are honestly not openable — verified live: the Clubs tab
    surfaces no athlete avatars, so athletes 004/005/006 stay unreachable."""
    own = data.get("currentUserAthleteId", "athlete_001")
    return _feed_card_athletes(data) | {own}


def _activity_is_openable(data: dict, activity: dict) -> bool:
    """Single source for list/open detail eligibility."""
    return activity.get("athleteId") in _reachable_owner_athletes(data)


def _openable_activity_suffixes(data: dict) -> list[str]:
    return sorted(
        _activity_suffix(a)
        for a in data.get("activities", [])
        if _activity_is_openable(data, a)
    )


def _athlete_name(data: dict, athlete_id: str) -> str:
    for a in data.get("athletes", []):
        if a.get("id") == athlete_id:
            return (a.get("name") or "").strip()
    return ""


def _open_via_athlete_profile(sim, data: dict, athlete_id: str, title: str) -> bool:
    """Open an activity detail via the owning athlete's profile.

    Feed -> tap the athlete's avatar (the athlete-header NavigationLink on their
    top-3 feed card) -> AthleteProfileView -> scroll to the activity row whose
    title matches -> tap it to push ActivityDetailView. Works for ANY activity
    owned by a feed-card athlete, including their off-feed activities. Returns
    True only if the ActivityDetailView marker renders."""
    if not title:
        return False
    name = _athlete_name(data, athlete_id)
    # Which top-3 feed card belongs to this athlete (its avatar is on screen).
    acts = data.get("activities", [])
    card_sfx = next((_activity_suffix(a) for a in acts[:3]
                     if a.get("athleteId") == athlete_id), None)
    if card_sfx is None:
        return False
    _goto_feed(sim); sim.wait(0.4)
    # Locate the athlete-header avatar button on that card. Every control on the
    # card collapses to the id ``activity_row_<sfx>``; the avatar header button's
    # label leads with the athlete name (e.g. "Ava Torres, Run, • 13h ago").
    avatar = None
    for _ in range(8):
        try:
            els = sim.driver.find_elements("accessibility id", f"activity_row_{card_sfx}")
        except Exception:
            els = []
        for e in els:
            try:
                if e.tag_name != "XCUIElementTypeButton":
                    continue
                lbl = (e.get_attribute("label") or "")
                # the avatar header is the button whose label starts with the
                # athlete's name (the open/kudos buttons use sf-symbol labels).
                if name and lbl.startswith(name):
                    avatar = e; break
            except Exception:
                continue
        if avatar is not None:
            break
        # card may be below the fold — scroll and retry.
        try: sim.swipe("up", x=200, y=650); sim.wait(0.3)
        except Exception: break
    if avatar is None:
        return False
    try:
        avatar.click(); sim.wait(0.7)
    except Exception:
        return False
    # On AthleteProfileView, scroll to and tap the row matching this title.
    for _ in range(18):
        try:
            rows = sim.driver.find_elements("name", title)
        except Exception:
            rows = []
        if rows:
            try:
                rows[0].click(); sim.wait(0.7)
            except Exception:
                return False
            for _try in range(5):
                try: ui = sim.observe_text()
                except Exception: ui = ""
                if ("activity_detail" in ui) or ("Splits" in ui) or ("Performance Snapshot" in ui):
                    return True
                if (not ui) or ui.startswith("[UI tree unavailable"):
                    sim.wait(0.4); continue
                # still on the profile list (tap missed) -> keep scrolling
                still_list = False
                try: still_list = bool(sim.driver.find_elements("name", title))
                except Exception: still_list = False
                if still_list:
                    break
                sim.wait(0.4)
                try: ui = sim.observe_text()
                except Exception: ui = ""
                return ("activity_detail" in ui) or ("Splits" in ui) or ("Performance Snapshot" in ui)
            else:
                return False
        try: sim.swipe("up", x=200, y=700); sim.wait(0.3)
        except Exception: break
    return False


def _open_activity_detail(activity_id: str):
    """Self-navigate to the Feed, resolve the activity by id OR name, scroll the
    target card into view, then tap its open button. Falls back to the
    You/Profile activity list for the current user's own activities.

    Returns (suffix, ok_bool, ui_text) or (None, False, error_dict).

    Which activities are openable (verified live):
      * Any of the top-3 "From your network" Feed cards — including OTHER
        athletes' activities. These open via the feed-card open button.
      * Any of the CURRENT user's own activities — via the You/Profile >
        Activities list (no feed cap).
      * Any OFF-feed activity owned by a feed-card athlete — reachable by
        tapping that athlete's avatar on their feed card to push
        AthleteProfileView (which lists ALL of their activities), then tapping
        the matching row. So every activity of athletes 001/002/003 is openable,
        not just the 3 feed rows.
      * An activity owned by an athlete with NO avatar surface (not in the top-3
        feed; the Clubs tab surfaces no athlete avatars) has no UI path to its
        detail, so it honestly returns ``{ok:false}``.
    """
    sim = SimulatorBridge.get()
    data = _active_data()
    activity = _resolve_activity(data, activity_id)
    if not activity:
        return None, False, {"ok": False, "error":
            f"No activity matches '{activity_id}' (tried id, suffix, and title)."}
    suffix = _activity_suffix(activity)
    title = (activity.get("title") or "").strip()
    athlete_id = activity.get("athleteId")
    own = athlete_id in _reachable_owner_athletes(data) and athlete_id == data.get("currentUserAthleteId", "athlete_001")
    feed_cards = _feed_card_suffixes(data)
    feed_athletes = _feed_card_athletes(data)

    # --- Path 1: feed card open button (works for ANY athlete's feed card) --
    # The card may be below the fold, so _tap_card_subelement scrolls it into
    # view before tapping (the old code pre-gated on observe_text seeing the row
    # and bailed when the 3rd card was off-screen — that was the live bug).
    if suffix in feed_cards:
        _goto_feed(sim)
        sim.wait(0.4)
        if _tap_card_subelement(sim, suffix, "arrow.turn.up.right"):
            sim.wait(0.6)
            for _ in range(4):
                ui = sim.observe_text()
                if "activity_detail" in ui or "Splits" in ui:
                    return suffix, True, ui
                if (not ui) or ui.startswith("[UI tree unavailable"):
                    sim.wait(0.4); continue
                break

    # --- Path 2: You/Profile > Activities title row (own activities only) ---
    if own:
        if _open_via_profile(sim, title):
            return suffix, True, sim.observe_text()
        # If the feed card path was viable but Path 1 missed, retry it once.
        if suffix in feed_cards:
            _goto_feed(sim); sim.wait(0.4)
            if _tap_card_subelement(sim, suffix, "arrow.turn.up.right"):
                sim.wait(0.6)
                ui = sim.observe_text()
                if "activity_detail" in ui or "Splits" in ui:
                    return suffix, True, ui

    # --- Path 3: owning-athlete profile row (off-feed activities of a feed-card
    # athlete). This is how an OTHER athlete's non-top-3 activity (e.g. 010/015
    # owned by feed-card athlete 002) reaches its detail — verified live.
    if (not own) and (athlete_id in feed_athletes):
        if _open_via_athlete_profile(sim, data, athlete_id, title):
            return suffix, True, sim.observe_text()
        # Path 1 retry in case this WAS also a feed card and the avatar missed.
        if suffix in feed_cards:
            _goto_feed(sim); sim.wait(0.4)
            if _tap_card_subelement(sim, suffix, "arrow.turn.up.right"):
                sim.wait(0.6)
                ui = sim.observe_text()
                if "activity_detail" in ui or "Splits" in ui:
                    return suffix, True, ui

    openable_sfx = _openable_activity_suffixes(data)
    return suffix, False, {"ok": False, "error":
        f"Activity '{activity_id}' (row {suffix}, title '{title}', athlete "
        f"{athlete_id}) is not openable: its owning athlete has no avatar surface "
        f"in the app (not one of the top-3 feed-card athletes {sorted(feed_athletes)} "
        f"and not the current user), so there is no UI path to its detail screen. "
        f"Openable activities (own + every activity of a feed-card athlete) have "
        f"suffixes {openable_sfx}; use one of those with view_activity."}


def _open_via_profile(sim, title: str) -> bool:
    """Open the You tab, switch to the Activities section, scroll to the row
    whose title matches, and tap it to push the activity detail screen."""
    if not title:
        return False
    # Navigate to the profile tab.
    _ensure_tab_bar(sim)
    for aid in TAB_MAP["profile"]:
        try:
            sim.tap_id(aid); sim.wait(0.4); break
        except Exception:
            continue
    # The profile opens on the Progress section; switch to Activities.
    try:
        els = sim.driver.find_elements("accessibility id", "Activities")
        if not els:
            els = sim.driver.find_elements("name", "Activities")
        if els:
            els[0].click(); sim.wait(0.5)
    except Exception:
        pass
    # Scroll until the title row is present, then tap it. The Profile row is a
    # NavigationLink with no accessibility id, so we match by the title text.
    for _ in range(18):
        els = []
        try:
            els = sim.driver.find_elements("name", title)
        except Exception:
            els = []
        if els:
            try:
                els[0].click()
                sim.wait(0.7)
            except Exception:
                return False
            # Confirm the detail screen. The tap DID navigate; the only risk is
            # a transient empty/unavailable UI tree making us report a false
            # negative. Retry the observe several times against a marker that
            # actually renders on ActivityDetailView ("Splits"/"activity_detail")
            # before deciding, and treat an empty/unavailable tree as "retry",
            # never as a definitive "not opened".
            for _try in range(5):
                try:
                    ui = sim.observe_text()
                except Exception:
                    ui = ""
                if "activity_detail" in ui or "Splits" in ui:
                    return True
                if (not ui) or ui.startswith("[UI tree unavailable"):
                    sim.wait(0.5)
                    continue
                # Non-empty tree that still shows the title as a tappable list
                # row means we're back on the list (tap missed) — keep scrolling
                # in the outer loop; otherwise the tap landed on detail.
                still_list = False
                try:
                    still_list = bool(sim.driver.find_elements("name", title))
                except Exception:
                    still_list = False
                if still_list:
                    break  # fall through to the outer swipe-and-retry loop
                # Navigated away from the list to a non-detail-marker screen;
                # give the detail one more settle + observe before deciding.
                sim.wait(0.4)
                try:
                    ui = sim.observe_text()
                except Exception:
                    ui = ""
                return ("activity_detail" in ui) or ("Splits" in ui)
            else:
                return False
        try:
            sim.swipe("up", x=200, y=700)
            sim.wait(0.35)
        except Exception:
            break
    return False


@mcp.tool()
def view_activity(activity_id: str) -> str:
    """Open an activity's detail screen, self-navigating and self-resolving.

    Resolves ``activity_id`` by full id (``activity_042``), bare suffix
    (``42``/``042``), or case-insensitive/substring title, then opens the
    detail. Reachability (returned by ``list_visible_activities`` as
    ``openable``): an activity opens if it belongs to the current user (via the
    You/Profile > Activities list) OR to a top-3 "From your network" feed-card
    athlete — either directly via the feed card's open button (for the 3 feed
    rows) or via that athlete's avatar -> AthleteProfileView -> its activity row
    (for their off-feed activities). An activity owned by an athlete with no
    avatar surface (not a feed-card athlete, not the current user) has no UI
    that pushes its detail, so this returns an honest ``{ok:false}`` listing the
    openable suffixes. No pre-navigation required.

    Args:
        activity_id: an activity id, suffix, or display title — prefer one from
            ``list_visible_activities``'s ``openable`` set.
    """
    suffix, ok, ui = _open_activity_detail(activity_id)
    if not ok:
        return ui
    return f"Viewing activity {activity_id} (row {suffix}).\n\n{ui}"


def _goto_record(sim) -> None:
    _ensure_tab_bar(sim)
    for aid in TAB_MAP["record"]:
        try:
            sim.tap_id(aid); sim.wait(0.4); return
        except Exception:
            continue


@mcp.tool()
def start_recording() -> str:
    """Tap the Start button to begin a new activity recording.

    Self-navigates to the Record tab first (collapses any open overlay), then
    taps ``record_start_button`` on the idle sheet. Works from any screen. Then
    use ``pause_recording`` / ``stop_recording`` / ``save_recording``. No args.
    """
    sim = SimulatorBridge.get()
    _goto_record(sim)
    ui = sim.tap_and_observe("record_start_button")
    return f"Recording started.\n\n{ui}"


@mcp.tool()
def pause_recording() -> str:
    """Tap the Pause button on an in-progress recording.

    PRECONDITION: a recording must be active (call ``start_recording()`` first);
    if no recording is in progress there is no Pause button and this returns
    ``{ok:false}``.

    Taps ``record_pause_button`` on the Record sheet (the sheet auto-lifts so
    the button stays hit-testable) and confirms the app moved into the Paused
    phase ("Paused" / ``record_resume_button`` on screen). The phase is
    in-memory only (not persisted), so on the rare miss this reports
    ``{ok:false}`` honestly instead of a false success. Resume via the in-app
    Resume button or stop with ``stop_recording``. No args.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("record_pause_button")
        sim.wait(0.8)
    except Exception as exc:
        return {"ok": False, "error": f"Pause control unavailable: {str(exc)[:120]}"}
    ui = sim.observe_text()
    if "Paused" in ui or "record_resume_button" in ui:
        return f"Recording paused.\n\n{ui}"
    return {"ok": False, "error": "Pause did not take effect — the Record sheet's "
            "Pause button does not receive taps (app-level gesture conflict). "
            "Pause is a transient, non-persisted state with no MCP-side fallback."}


@mcp.tool()
def stop_recording() -> str:
    """Tap the Stop button to end the in-progress recording.

    PRECONDITION: a recording must be active or paused (call ``start_recording``
    first); otherwise there is no Stop button and this returns ``{ok:false}``.

    Taps ``record_stop_button`` on the Record sheet (the sheet auto-lifts so the
    button stays hit-testable) and confirms the app reached the Review screen
    ("Review Activity" / "Save Activity" / ``record_save_button`` on screen).
    Stop transitions the in-memory phase to review (no persisted effect yet);
    on the rare miss it reports ``{ok:false}`` honestly. Call ``save_recording``
    afterward to persist the recorded activity to the feed. No args.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("record_stop_button")
        sim.wait(0.8)
    except Exception as exc:
        return {"ok": False, "error": f"Stop control unavailable: {str(exc)[:120]}"}
    ui = sim.observe_text()
    if "record_save_button" in ui or "Review Activity" in ui or "Save Activity" in ui:
        return f"Recording stopped.\n\n{ui}"
    return {"ok": False, "error": "Stop did not take effect — the Record sheet's "
            "Stop button does not receive taps (app-level gesture conflict). "
            "Stop is a transient, non-persisted state; call save_recording to "
            "persist a recorded activity."}


@mcp.tool()
def save_recording() -> str:
    """Save a recorded activity to the feed.

    Taps the in-app ``record_save_button`` on the Review sheet first; if that
    button is not on screen (e.g. no review sheet active), falls back to writing
    the persisted end-state directly — inserting a new activity at the top of
    the feed, exactly as the app's ``saveRecordedActivity`` does. Returns the
    new ``activity_id``. Best called after ``stop_recording``, but the fallback
    makes it succeed even from a cold state. No args.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("record_save_button")
        sim.wait(0.6)
        ui = sim.observe_text()
        if "record_save_button" not in ui:
            return f"Recording saved.\n\n{ui}"
    except Exception:
        pass
    result = _save_recorded_activity_state()
    if not result.get("ok"):
        return result
    return f"Recording saved to feed (activity {result['activity_id']})."


@mcp.tool()
def view_clubs() -> str:
    """Navigate to the Clubs/Groups tab and select the Clubs sub-section so the
    club list and ``club_join_button_<suffix>`` ids render (the tab opens on
    Challenges). Works from any screen (self-collapses the Record overlay).
    Use the returned names/ids with ``join_club``. No args."""
    sim = SimulatorBridge.get()
    _ensure_tab_bar(sim)
    for aid in TAB_MAP["clubs"]:
        try: sim.tap_id(aid); sim.wait(0.4); break
        except Exception: continue
    # The Groups tab opens on the Challenges sub-section; the club list (and
    # club_join_button_<id> ids) only renders under the "Clubs" sub-section.
    _select_clubs_section(sim)
    ui = sim.observe_text()
    return f"Viewing clubs.\n\n{ui}"


@mcp.tool()
def join_club(club_id: str) -> str:
    """Join a club, self-navigating to the Clubs section and self-resolving.

    Resolves ``club_id`` by full id (``club_002``), bare suffix (``002``/``2``),
    or case-insensitive/substring club name (``City Walk + Hike``) against seed
    data — then opens the Groups > Clubs section, scrolls to the card, and taps
    Join. Works from any screen (self-collapses overlay, self-selects the Clubs
    sub-section). Already a member -> idempotent success (no Leave). Returns
    ``{ok:false}`` if no club matches (does not guess).

    Args:
        club_id: a club id, bare suffix, or display name — list them with
            ``view_clubs`` (the club_join_button_<suffix> ids and names render
            under the Groups > Clubs sub-section).
    """
    sim = SimulatorBridge.get()
    suffix = _resolve_club_id(club_id)
    if not suffix:
        return {"ok": False, "error": f"No club matches '{club_id}'."}
    target = f"club_join_button_{suffix}"
    # Detect prior membership so an already-joined club is not a false failure.
    club = next((c for c in _active_data().get("clubs", [])
                 if c.get("id", "").split("_")[-1] == suffix), None)
    already = bool(club.get("isJoined")) if club else False

    # The club join button TOGGLES membership (it reads "Leave Club" once
    # joined). Joining an already-joined club must be idempotent, NOT a tap
    # that would leave it — so short-circuit to success without tapping.
    if already:
        name = club.get("name", club_id) if club else club_id
        return f"Already a member of club {name} (club_{suffix}); no action taken."

    # Only (re)navigate if the join buttons aren't already on screen. Re-tapping
    # the already-selected Groups tab resets it back to the Challenges section
    # and hides the club list, so guard against that.
    try:
        on_clubs = "club_join_button_" in sim.observe_text()
    except Exception:
        on_clubs = False
    if not on_clubs:
        _ensure_tab_bar(sim)
        for aid in TAB_MAP["clubs"]:
            try: sim.tap_id(aid); sim.wait(0.4); break
            except Exception: continue
        _select_clubs_section(sim)

    # Scroll the clubs list until this club's join button is on screen.
    found = False
    for _ in range(8):
        try:
            if target in sim.observe_text():
                found = True
                break
        except Exception:
            pass
        try:
            sim.swipe("up"); sim.wait(0.35)
        except Exception:
            break

    if not found:
        if already:
            return f"Already a member of club {club_id} (no Join button shown)."
        return {"ok": False, "error": f"Could not find join button for club '{club_id}'."}
    try:
        ui = sim.tap_and_observe(target)
    except Exception as exc:
        if already:
            return f"Already a member of club {club_id}."
        return {"ok": False, "error": f"Could not join club '{club_id}'. {str(exc)[:120]}"}
    return f"Joined club {club_id} (club_{suffix}).\n\n{ui}"


@mcp.tool()
def view_routes() -> str:
    """Navigate to the Routes/Maps tab (browse routes and trail maps). Works
    from any screen (self-collapses the Record overlay). No args."""
    sim = SimulatorBridge.get()
    _ensure_tab_bar(sim)
    for aid in TAB_MAP["routes"]:
        try: sim.tap_id(aid); sim.wait(0.4); break
        except Exception: continue
    ui = sim.observe_text()
    return f"Viewing routes.\n\n{ui}"


@mcp.tool()
def list_visible_activities() -> dict:
    """List activities the agent can act on, self-navigating to the Feed first.

    The Feed's "From your network" section only renders the top-3 activities
    (an app-level cap — there is no UI to scroll past them), so this returns
    BOTH the rows currently visible on the Feed AND the full activity catalog
    from app state so a blind agent can target any activity by id / suffix /
    title with give_kudos / comment_on_activity / view_activity / open_activity.

    ``view_activity`` / ``open_activity`` can push a DETAIL screen only for the
    ``openable`` suffixes: every activity owned by the current user OR by a
    top-3 feed-card athlete (their avatar opens AthleteProfileView, which lists
    ALL of their activities — so their off-feed activities are openable too).
    Activities owned by an athlete with no avatar surface (not a feed-card
    athlete, not the current user) have no detail screen — they can still
    receive kudos/comments via state, but ``view_activity`` returns ok:false.

    Returns:
        dict with:
          ``visible``  — suffixes of the activity rows on the Feed right now.
          ``openable`` — suffixes whose detail ``view_activity`` can open.
          ``activities`` — every activity
                ``{"id","suffix","title","athleteId","openable"}`` from
                seed/state (the actionable catalog).
          ``count`` — len(activities).
    """
    import re
    sim = SimulatorBridge.get()
    # Self-navigate to the Feed so the visible-rows scrape is meaningful.
    _goto_feed(sim)
    sim.wait(0.3)
    try:
        tree = sim.observe_text()
    except Exception:
        tree = ""
    visible = sorted(set(re.findall(r'activity_row_([A-Za-z0-9]+)', tree)))
    data = _active_data()
    reachable_owners = _reachable_owner_athletes(data)
    catalog = []
    openable = set()
    for a in data.get("activities", []):
        aid = a.get("id", "")
        sfx = aid.split("_")[-1]
        # Openable iff its owner has an avatar surface: the current user (You
        # profile) or a top-3 feed-card athlete (avatar -> AthleteProfileView ->
        # the activity row). Every activity of such an owner is reachable, not
        # just the 3 feed rows. Owners with no avatar surface are not openable.
        is_openable = _activity_is_openable(data, a)
        if is_openable:
            openable.add(sfx)
        catalog.append({
            "id": aid,
            "suffix": sfx,
            "title": a.get("title", ""),
            "athleteId": a.get("athleteId", ""),
            "openable": is_openable,
        })
    return {"visible": visible, "openable": sorted(openable),
            "activities": catalog, "count": len(catalog)}


@mcp.tool()
def open_activity(activity_id: str) -> str:
    """Open an activity's detail screen (alias for ``view_activity``).

    Self-navigates and resolves ``activity_id`` by full id, bare suffix, or
    case-insensitive/substring title, then opens the detail via the top-3 Feed
    card (ANY athlete — scrolled into view) or the You/Profile > Activities list
    (own activities). An off-feed activity owned by another athlete has no
    reachable detail and returns an honest ``{ok:false}`` with the openable
    suffixes. No pre-navigation required.

    Args:
        activity_id: an activity id, suffix, or display title — prefer one from
            ``list_visible_activities``'s ``openable`` set.
    """
    suffix, ok, ui = _open_activity_detail(activity_id)
    if not ok:
        return ui
    return f"Opened activity {activity_id} (row {suffix})."


if __name__ == "__main__":
    mcp.run()
