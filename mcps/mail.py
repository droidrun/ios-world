"""Mail MCP — inbox navigation, compose, reply, archive via accessibility IDs.

Bundle: com.iosworld.benchmark.mail

ID conventions (from Mail/ViewController.swift):
  Message rows:    mail_row_<subject_slug>
                   slug = subject lowercased, spaces->_ , non-alnum stripped,
                   truncated to 40 chars
  Mailboxes panel: mailboxes_button (open),
                   mailbox_<folder> for inbox|drafts|scheduled|sent|archive|trash
  Categories:      category_<name> for primary|transactions|updates|promotions
  Compose:         compose_button (open),
                   compose_to_field / compose_subject_field /
                   compose_body_field (filled by accessibility id, falling
                   back to XCUIElementTypeTextField indices 0,1 + TextView 0),
                   compose_send_button (commit; label "Send")
  Search:          mail_search_bar
  Bulk select:     select_button, bulk_archive_button, bulk_delete_button,
                   bulk_read_button
  Settings:        settings_button, dark_mode_toggle, notifications_apply_button
"""

import sys, pathlib, re
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts

mcp = FastMCP("Mail")

BUNDLE_ID = "com.iosworld.benchmark.mail"

# Mailbox row ids are mailbox_<folder.title.lowercased()> (see ViewController
# MailboxesViewController). The title is only lowercased — spaces are NOT
# replaced — so the "scheduled" folder (title "Send Later") renders as the id
# "mailbox_send later" (with a literal space), NOT "mailbox_scheduled". Aliases
# let agents pass either the internal name or the visible title.
_FOLDER_MAP = {
    "inbox": "mailbox_inbox",
    "drafts": "mailbox_drafts",
    "scheduled": "mailbox_send later",
    "send later": "mailbox_send later",
    "send_later": "mailbox_send later",
    "sent": "mailbox_sent",
    "archive": "mailbox_archive",
    "trash": "mailbox_trash",
}

_CATEGORY_MAP = {
    "primary": "category_primary",
    "transactions": "category_transactions",
    "updates": "category_updates",
    "promotions": "category_promotions",
}


def _slug(s: str) -> str:
    return "".join(c for c in s.lower().replace(" ", "_") if c.isalnum() or c == "_")[:40]


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


def _mail_rows_from_tree(tree: str) -> list[dict]:
    rows = {}
    for m in re.finditer(r'name="mail_row_([^"\s]+)"(?:\s+label="([^"]*)")?', tree or ""):
        slug = m.group(1)
        label = m.group(2) or ""
        rows.setdefault(slug, {"slug": slug, "row_id": f"mail_row_{slug}", "label": label})
    return list(rows.values())


def _collect_visible_mail_rows(sim, max_scrolls: int = 12) -> list[dict]:
    """Collect row ids across the current list/search by scrolling downward."""
    rows: dict[str, dict] = {}
    seen_signatures = set()
    for _ in range(max_scrolls):
        tree = sim.observe_text() or ""
        for row in _mail_rows_from_tree(tree):
            rows.setdefault(row["slug"], row)
        sig = "|".join(sorted(r["slug"] for r in _mail_rows_from_tree(tree)))
        if sig in seen_signatures:
            break
        seen_signatures.add(sig)
        if not sig:
            break
        try:
            sim.swipe("up")
            sim.wait(0.35)
        except Exception:
            break
    return sorted(rows.values(), key=lambda r: r["slug"])


def _is_mail_foreground(tree: str) -> bool:
    """True if Mail is the foreground app in the given UI tree."""
    return f'bundleId="{BUNDLE_ID}"' in (tree or "")


def _on_list_chrome(tree: str) -> bool:
    """True if ANY scrollable message-list view is showing (inbox OR a folder).

    The list chrome (``select_button`` / ``mail_search_bar`` / category chips)
    is present on the inbox AND on every folder list (Archive, Trash, Sent…).
    Use this only when the caller just needs *some* list chrome, not the
    inbox specifically — for the inbox use ``_on_inbox_list``.
    """
    return "select_button" in (tree or "")


def _on_inbox_list(tree: str) -> bool:
    """True if the INBOX list view specifically is showing.

    ``select_button`` alone is NOT enough — every folder list (Archive,
    Trash, Sent…) also exposes it, so a stale Trash view would falsely pass
    a select_button-only check and a row tap would resolve against the wrong
    folder. The inbox is uniquely titled "All Inboxes" (or "Inbox") in its
    navigation bar, so require that title together with the list chrome.
    """
    t = tree or ""
    if "select_button" not in t:
        return False
    return ('name="All Inboxes"' in t or 'name="Inbox"' in t
            or 'value="All Inboxes"' in t)


def _ensure_mail_foreground(sim) -> str:
    """Make sure Mail is the foreground app; relaunch from cold/other-app.

    Returns the current UI tree. Agents call tools blind (from the home
    screen or another app), so every navigating tool funnels through here
    first instead of assuming the caller pre-launched Mail.
    """
    tree = sim.observe_text() or ""
    if not _is_mail_foreground(tree):
        tree = sim.launch_and_observe(BUNDLE_ID)
    return tree


def _ensure_inbox_list(sim) -> str:
    """Self-navigate to the scrollable inbox/folder LIST and return the tree.

    Handles every blind entry state an agent can leave behind:
      * Mail not foreground / app cold  -> launch.
      * Sitting in a message detail, compose sheet, mailboxes panel, settings,
        or an active search session (select_button hidden) -> relaunch to root,
        which deterministically returns to the inbox list.
    Relaunch is cheap and is the only state-independent way to guarantee the
    list chrome (select_button / mail_search_bar) is hittable.
    """
    tree = sim.observe_text() or ""
    if _is_mail_foreground(tree) and _on_inbox_list(tree) and "mail_row_" in tree:
        return tree
    # Foreground-but-not-on-list, or not foreground at all: relaunch to root.
    tree = sim.launch_and_observe(BUNDLE_ID)
    # The list chrome (select_button) appears before the table cells finish
    # lazy-loading after a relaunch. A blind caller that taps a row right away
    # would miss it ("not currently visible") and fall through to wrong-folder
    # matches. Poll until the row cells actually render (or give up).
    for _ in range(6):
        if _on_inbox_list(tree) and "mail_row_" in tree:
            return tree
        sim.wait(0.4)
        tree = sim.observe_text() or tree
    return tree


def _scroll_find_row(sim, target_slug: str, max_scrolls: int = 8):
    """Scroll the current list looking for a ``mail_row_<slug>`` matching target.

    Returns the full slug (suffix of mail_row_) that matched, or None.
    Matching is exact-slug first, then prefix/substring. Stops early when the
    list stops changing (bottom reached) to avoid spinning on short lists.
    """
    seen_trees = set()
    fuzzy_match = None  # remember the best prefix/substring hit but keep
    # scrolling for an EXACT match, which always wins over a substring (so
    # "dinner_friday" prefers the inbox's exact row over a "re_dinner_friday").
    for _ in range(max_scrolls):
        tree = sim.observe_text() or ""
        slugs = re.findall(r'mail_row_([^"\s]+)', tree)
        for s in slugs:
            if s == target_slug:
                return s
        if fuzzy_match is None:
            for s in slugs:
                if s.startswith(target_slug) or target_slug in s:
                    fuzzy_match = s
                    break
        sig = tree[:200] + str(len(tree))
        if sig in seen_trees:
            break
        seen_trees.add(sig)
        sim.swipe("up")
        sim.wait(0.4)
    return fuzzy_match


def _ensure_selection_mode(sim) -> str:
    """Enter bulk-select mode on the inbox list and return the UI tree.

    Idempotent: navigates to the list, then taps ``select_button`` only if
    we're not already in selection mode (where the button reads "Done" and a
    second tap would EXIT). Leaves the toolbar (archive/delete/read) visible.
    """
    tree = _ensure_inbox_list(sim)
    if 'name="select_button" label="Done"' in tree:
        return tree
    sim.tap_id("select_button")
    sim.wait(0.4)
    return sim.observe_text() or ""


def _ensure_one_row_selected(sim, tree: str) -> tuple[bool, str]:
    """Ensure at least one mail row is tap-selected in selection mode.

    The Swift bulk handlers no-op on an empty selection, so a blind bulk_*
    call would silently do nothing. If no row is selected we tap the first
    visible row. Returns ``(selected_any, row_slug_or_empty)``.

    Selection state isn't reliably exposed per-cell in the XCUITest tree, so
    we conservatively tap the first row whenever we just entered selection
    mode / the caller hasn't pre-selected. Callers that have already selected
    rows themselves should pass ``assume_preselected``.
    """
    slugs = re.findall(r'mail_row_([^"\s]+)', tree or "")
    if not slugs:
        return False, ""
    first = slugs[0]
    try:
        sim.tap_id(f"mail_row_{first}")
        sim.wait(0.3)
        return True, first
    except Exception:
        return False, ""


def _fill_field(sim, aid: str, fallback_index: int, kind: str, text: str) -> None:
    """Type ``text`` into a compose field, preferring its accessibility id.

    ``aid`` is the real Swift accessibility id (e.g. ``compose_to_field``).
    If that id cannot be resolved we fall back to the Nth element of the
    given XCUITest ``kind`` class (``XCUIElementTypeTextField`` or
    ``XCUIElementTypeTextView``) for resilience across builds.
    """
    if not text:
        return
    el = None
    try:
        els = sim.driver.find_elements("accessibility id", aid)
        if els:
            el = els[0]
    except Exception:
        el = None
    if el is None:
        try:
            els = sim.driver.find_elements("class name", kind)
            if len(els) > fallback_index:
                el = els[fallback_index]
        except Exception:
            el = None
    if el is None:
        return
    el.click(); sim.wait(0.2)
    el.send_keys(text); sim.wait(0.2)


def _tap_send(sim) -> bool:
    """Tap the compose Send control. Returns True if a control was tapped."""
    for aid in ("compose_send_button", "Send"):
        try:
            sim.tap_id(aid)
            return True
        except Exception:
            continue
    return False


@mcp.tool()
def launch() -> str:
    """Launch Mail and return the initial UI tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched Mail.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (no taps)."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="Mail",
        markers=("mail_", "message_row_", "mailbox_", "compose_"),
    )


@mcp.tool()
def list_messages(page: int = 1, page_size: int = 50, aggregate_scroll: bool = True) -> dict:
    """List subject slugs for the current mail list/search with pagination.

    Foregrounds Mail if it isn't active (so a blind call reports real inbox
    rows), but does NOT relaunch when already in Mail — an active
    search/folder filter is preserved so the returned rows reflect the
    current filter. Honors the empty-state label, returning an empty list
    when the folder/search has no matches (stale recycled cells ignored).

    Returns:
        ``{messages, message_rows, count, returned_count, page, page_size,
        has_more, next_page}``. ``messages`` is kept as the list of slug
        suffixes usable with ``open_message(subject=<slug>)``.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    # Blind agents may call list_messages before Mail is foregrounded. If Mail
    # isn't the active app, foreground it so we report real inbox rows rather
    # than another app's empty tree. (We do NOT relaunch when already in Mail —
    # that would discard an active search/folder filter the agent set up.)
    if not _is_mail_foreground(tree):
        tree = sim.launch_and_observe(BUNDLE_ID)
    # When a folder/search yields zero matches UIKit shows an empty-state
    # label ("No results for ...", "No messages", "No <category> messages")
    # but still leaves recycled offscreen UITableViewCells in the XCUITest
    # tree with their old mail_row_<slug> ids. Trust the empty-state label
    # over those stale cells so we don't over-report rows that no longer
    # exist in the data source.
    if re.search(r'value="No (results|messages|[a-z]+ messages)', tree):
        page_rows, meta = _paginate([], page, page_size)
        return {**meta, "messages": [], "message_rows": page_rows}
    rows = _collect_visible_mail_rows(sim) if aggregate_scroll else _mail_rows_from_tree(tree)
    page_rows, meta = _paginate(rows, page, page_size)
    return {
        **meta,
        "messages": [r["slug"] for r in page_rows],
        "message_rows": page_rows,
        "aggregate_scroll": bool(aggregate_scroll),
    }


def _in_message_detail(tree: str) -> bool:
    """True if the single-message DETAIL view is showing.

    The detail toolbar exposes the per-message ``archive`` / ``trash`` /
    ``reply`` bar buttons (the SF-Symbol image names surface as the element
    ``name``). The list view never shows these, so their presence is a
    reliable "we are reading one message" marker — used to confirm an
    ``open_message`` tap actually pushed the detail screen and to drive the
    targeted ``archive_message`` / ``delete_message`` actions.
    """
    t = tree or ""
    return 'name="archive"' in t and 'name="trash"' in t


def _open_message_internal(sim, subject: str) -> tuple[bool, str]:
    """Open the message whose subject/slug matches ``subject``.

    Self-navigates from any blind entry state (cold app, stale detail,
    active search/filter) to the inbox list, taps the matching row, and
    sweeps the other folders if the row isn't in the inbox. Success is
    confirmed by the DETAIL view actually rendering (``_in_message_detail``)
    — not merely by the tree changing — so a tap that opened a different
    sheet does not count as opened.

    Returns ``(opened, where)`` where ``where`` is the folder label the
    message was found in (``"inbox"`` by default) or an error message string
    when ``opened`` is False.
    """
    target = _slug(subject)
    _ensure_inbox_list(sim)

    def _try_tap(slug: str) -> bool:
        err = sim.tap_and_verify_changed(f"mail_row_{slug}", prefix_for_failure="")
        if err is not None:
            return False
        # Confirm the DETAIL view rendered, not just any tree change.
        return _in_message_detail(sim.observe_text() or "")

    # Inbox: exact slug, then scroll to find prefix/substring matches.
    if _try_tap(target):
        return True, "inbox"
    matched = _scroll_find_row(sim, target)
    if matched is not None and _try_tap(matched):
        return True, "inbox"
    # Sweep the other folders (deduped label -> mailbox id).
    sweep = [("drafts", "mailbox_drafts"), ("send_later", "mailbox_send later"),
             ("sent", "mailbox_sent"), ("archive", "mailbox_archive"),
             ("trash", "mailbox_trash")]
    for folder, faid in sweep:
        _ensure_inbox_list(sim)
        try:
            sim.tap_id("mailboxes_button"); sim.wait(0.4)
            sim.tap_id(faid); sim.wait(0.5)
        except Exception:
            continue
        if _try_tap(target):
            return True, folder
        m2 = _scroll_find_row(sim, target)
        if m2 is not None and _try_tap(m2):
            return True, folder
    tree = sim.observe_text() or ""
    slugs = sorted(set(re.findall(r'mail_row_([^"\s]+)', tree)))
    return False, f"No message matching '{subject}' in any folder. Visible: {slugs[:10]}"


@mcp.tool()
def open_message(subject: str) -> str:
    """Open a message by its subject or slug.

    Args:
        subject: Subject line (case-insensitive, non-alnum stripped,
            spaces->_, truncated to 40 chars) OR a literal
            ``mail_row_<slug>`` suffix. Prefix/substring matches against
            visible rows are tried as a fallback.

    Works from any screen — self-navigates from a cold app / stale detail /
    active search to the inbox list first, then sweeps the other folders
    (drafts, send_later/scheduled, sent, archive, trash) if the subject isn't
    in the inbox. Success is confirmed by the message DETAIL view actually
    rendering. Returns a "Could not open" string (listing visible slugs) when
    no folder contains a match.
    """
    sim = SimulatorBridge.get()
    opened, where = _open_message_internal(sim, subject)
    if opened:
        if where == "inbox":
            return f"Opened message '{subject}'."
        return f"Opened message '{subject}' (in {where})."
    return f"Could not open message '{subject}'. {where}"


def _detail_action(subject: str, button_id: str, verb: str, gerund: str) -> str:
    """Open ``subject`` and tap a per-message detail toolbar button.

    ``button_id`` is the resolvable element name of the detail bar button
    (``archive`` or ``trash`` — UIBarButtonItems surface their SF-Symbol
    image name, not their accessibilityIdentifier). This is the ONLY way to
    act on a SPECIFIC message; the bulk_* tools act on the current selection
    and cannot target a named message, so a blind ``bulk_archive`` after
    ``open_message`` silently archives the wrong row.

    Confirms the effect by reading back state: after the tap we re-base on
    the inbox list and verify the target's row is GONE from the inbox (the
    message moved to archive/trash). Returns a success string only when the
    move is confirmed, else an honest failure (no false positive).
    """
    sim = SimulatorBridge.get()
    target = _slug(subject)
    opened, where = _open_message_internal(sim, subject)
    if not opened:
        return f"Could not {verb} message '{subject}'. {where}"
    # The detail toolbar's archive/trash buttons are no-ops when the message
    # already lives in the destination folder (archiving a trashed/archived
    # message, or trashing an already-trashed one, leaves it put). Detect that
    # up front and fail honestly rather than tapping a dead control and then
    # "confirming" the unchanged state.
    dest_folder = "archive" if verb == "archive" else "trash"
    if where == dest_folder:
        return (
            f"Could not {verb} message '{subject}' — it is already in the "
            f"{dest_folder} folder, so {verb} has no effect."
        )
    tree = sim.observe_text() or ""
    if not _in_message_detail(tree):
        return (
            f"Could not {verb} message '{subject}' — the message detail "
            "toolbar did not render. Call observe() to inspect, then retry."
        )
    try:
        sim.tap_id(button_id); sim.wait(0.6)
    except Exception as exc:
        return (
            f"Could not {verb} message '{subject}' — the '{button_id}' control "
            f"was not hittable. {str(exc)[:120]}"
        )
    # Confirm: the message should no longer be in the inbox list. Re-base on
    # the inbox and read back the rows. (If it was opened from a non-inbox
    # folder we still confirm it left THAT folder by re-checking the source.)
    src_label, src_aid = ("inbox", None)
    if where != "inbox":
        src_label = where
        src_aid = _FOLDER_MAP.get(where) or _FOLDER_MAP.get(where.replace("_", " "))
    _ensure_inbox_list(sim)
    if src_aid is not None:
        try:
            sim.tap_id("mailboxes_button"); sim.wait(0.4)
            sim.tap_id(src_aid); sim.wait(0.5)
        except Exception:
            pass
    after = sim.observe_text() or ""
    still_slugs = set(re.findall(r'mail_row_([^"\s]+)', after))
    gone = not any(s == target or s.startswith(target) or target in s
                   for s in still_slugs)
    if gone:
        return f"{gerund} message '{subject}' (removed from {src_label})."
    return (
        f"Could not {verb} message '{subject}' — after tapping {verb} it still "
        f"appears in {src_label} (the action did not move it). Call observe() "
        "to inspect the current state."
    )


@mcp.tool()
def archive_message(subject: str) -> str:
    """Archive ONE specific message by subject/slug.

    Works from any screen — self-navigates to find the message (sweeping
    all folders), opens its detail view, taps the Archive bar button, then
    confirms the message left its source folder by reading back the list.
    Use this (not ``bulk_archive``) when the task names a particular
    message — ``bulk_archive`` acts on the current bulk selection and
    cannot target a named message.

    Returns a controlled "Could not archive" string (not a false success)
    when the message can't be found, is already in Archive (archive is then
    a no-op), or the row still appears after the tap.

    Args:
        subject: Subject line or ``mail_row_<slug>`` suffix (same matching
            as ``open_message``).
    """
    return _detail_action(subject, "archive", "archive", "Archived")


@mcp.tool()
def delete_message(subject: str) -> str:
    """Delete (move to Trash) ONE specific message by subject/slug.

    Works from any screen — self-navigates to find the message (sweeping
    all folders), opens its detail view, taps the Trash bar button, then
    confirms the message left its source folder by reading back the list.
    Use this (not ``bulk_delete``) when the task names a particular
    message.

    Returns a controlled "Could not delete" string (not a false success)
    when the message can't be found, is already in Trash (trash is then a
    no-op), or the row still appears after the tap.

    Args:
        subject: Subject line or ``mail_row_<slug>`` suffix (same matching
            as ``open_message``).
    """
    return _detail_action(subject, "trash", "delete", "Deleted")


@mcp.tool()
def open_folder(folder: str) -> str:
    """Open a top-level mail folder via the Mailboxes panel.

    Works from any screen — self-navigates to the inbox list first.

    Args:
        folder: One of ``inbox``, ``drafts``, ``scheduled`` (also accepts
            its visible title ``send later`` / ``send_later``), ``sent``,
            ``archive``, ``trash`` (case-insensitive). Any other value
            returns an error string listing valid folders.

    Taps ``mailboxes_button`` to surface the panel if needed, then the
    matching ``mailbox_<folder>`` row.
    """
    sim = SimulatorBridge.get()
    key = folder.strip().lower()
    aid = _FOLDER_MAP.get(key)
    if aid is None:
        return f"Could not open folder — unknown folder '{folder}'. Use: {', '.join(_FOLDER_MAP.keys())}."
    # Blind agents call this from a cold app / detail view where the
    # mailboxes_button is hidden. Self-navigate to the inbox list first.
    _ensure_inbox_list(sim)
    # First navigate to the mailboxes panel if needed
    try:
        sim.tap_id("mailboxes_button")
    except Exception:
        pass
    sim.wait(0.3)
    err = sim.tap_and_verify_changed(aid, prefix_for_failure=f"Could not open folder '{folder}'. ")

    if err:

        return err

    return f"Opened folder '{folder}'."


@mcp.tool()
def filter_category(category: str) -> str:
    """Filter the inbox by a category chip.

    Args:
        category: One of ``primary``, ``transactions``, ``updates``,
            ``promotions`` (case-insensitive). Any other value returns
            an error string listing valid categories.

    Returns the post-filter ``list_messages()`` dict so the agent can
    see remaining rows.
    """
    key = category.strip().lower()
    aid = _CATEGORY_MAP.get(key)
    if aid is None:
        return f"Could not filter — unknown category '{category}'. Use: {', '.join(_CATEGORY_MAP.keys())}."
    sim = SimulatorBridge.get()
    # The category chips live in the inbox header. Blind agents call this from
    # a cold app, a detail view, or a non-inbox folder, so self-navigate to
    # the inbox list (relaunch returns to the inbox) and let it settle.
    tree = _ensure_inbox_list(sim)
    if aid not in tree:
        sim.launch_and_observe(BUNDLE_ID)
        sim.wait(0.8)
    # Primary: tap the chip by accessibility id (with the built-in settle/retry
    # inside tap_id). Fall back to the visible chip label if the id is briefly
    # unhittable inside its horizontal scroll strip.
    try:
        sim.tap_id(aid)
    except Exception:
        try:
            sim.tap_label(key.capitalize())
        except Exception as exc:
            return (
                f"Could not select category '{category}'. The inbox category "
                f"chips were not hittable. Call launch() then retry. {str(exc)[:120]}"
            )
    sim.wait(0.4)
    return list_messages()


@mcp.tool()
def compose(to: str, subject: str, body: str) -> str:
    """Open the compose sheet and fill To / Subject / Body without sending.

    Works from any screen — self-navigates to the inbox list, then taps
    ``compose_button``. Fields are filled by accessibility id
    (``compose_to_field`` / ``compose_subject_field`` / ``compose_body_field``).

    Args:
        to: Recipient email/address. Empty string skips this field.
        subject: Subject line. Empty string skips.
        body: Message body. Empty string skips.

    Does NOT send — use ``send_compose`` (or the
    ``prepare_send_compose`` + ``confirm_send_compose`` pair) to tap Send.
    """
    sim = SimulatorBridge.get()
    # Blind agents call compose from a cold app / other screen; the compose
    # button lives on the inbox list, so self-navigate there first.
    _ensure_inbox_list(sim)
    sim.tap_id("compose_button")
    sim.wait(0.6)
    _fill_field(sim, "compose_to_field", 0, "XCUIElementTypeTextField", to)
    _fill_field(sim, "compose_subject_field", 1, "XCUIElementTypeTextField", subject)
    _fill_field(sim, "compose_body_field", 0, "XCUIElementTypeTextView", body)
    return f"Drafted compose (to={to!r}, subject={subject!r}). Call send_compose() to send."


def _send_compose_fill_form(to: str = "", subject: str = "", body: str = "") -> Optional[str]:
    """Open and fill the compose sheet, but DO NOT tap Send.

    If any of ``to``/``subject``/``body`` is empty, that field is left as
    whatever the existing compose draft already contains (so this helper
    can be used both for fresh composes and to commit an in-progress
    draft). Returns None on success or a precondition message string on
    failure. Used by both ``send_compose`` (one-shot commit) and
    ``prepare_send_compose`` (capture-only).
    """
    sim = SimulatorBridge.get()
    try:
        # Only open the compose sheet if we have content to fill. If the
        # caller passes all-empty values they want to commit an existing
        # in-progress draft — in that case we leave the sheet untouched.
        if to or subject or body:
            _ensure_inbox_list(sim)
            sim.tap_id("compose_button")
            sim.wait(0.6)
            _fill_field(sim, "compose_to_field", 0, "XCUIElementTypeTextField", to)
            _fill_field(sim, "compose_subject_field", 1, "XCUIElementTypeTextField", subject)
            _fill_field(sim, "compose_body_field", 0, "XCUIElementTypeTextView", body)
        return None
    except Exception as exc:
        return (
            "Could not open or fill the compose sheet. Call launch() first, "
            f"then re-call. {str(exc)[:120]}"
        )


@mcp.tool()
def send_compose(to: str = "", subject: str = "", body: str = "") -> str:
    """Tap the Send button on the compose sheet (optionally filling fields first).

    Args:
        to: Optional recipient. If any of to/subject/body is non-empty,
            opens compose and fills those fields before sending;
            otherwise sends whatever is already drafted.
        subject: Optional subject line. Empty leaves existing subject.
        body: Optional body. Empty leaves existing body.

    Legacy single-verb commit; prefer ``prepare_send_compose`` +
    ``confirm_send_compose`` for new code.
    """
    sim = SimulatorBridge.get()
    err = _send_compose_fill_form(to, subject, body)
    if err:
        return err
    if not _tap_send(sim):
        return "Send button not found — ensure the compose sheet is open."
    sim.wait(0.5)
    return "Sent compose."


@mcp.tool()
def prepare_send_compose(to: str = "", subject: str = "", body: str = "") -> dict:
    """Open and fill the compose sheet WITHOUT tapping Send.

    If ``to``/``subject``/``body`` are provided, opens compose and fills
    them; otherwise leaves the existing compose draft in place. Returns
    ``{ok: True, action: "prepare_send_compose", draft_id, summary: {to,
    subject, body}}`` on success. The agent should inspect the summary,
    then pass the ``draft_id`` to ``confirm_send_compose`` to actually
    tap Send. The draft expires after the ``IOSWORLD_DRAFT_TTL_SECONDS``
    TTL (default 10 minutes) or when the simulator session resets.

    On precondition failure, returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _send_compose_fill_form(to, subject, body)
    if err:
        return {"ok": False, "action": "prepare_send_compose", "message": err}
    summary = {"to": to, "subject": subject, "body": body}
    draft_id = ts.create_draft("mail", "send_compose", summary)
    return {
        "ok": True,
        "action": "prepare_send_compose",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_send_compose(draft_id) to commit.",
    }


@mcp.tool()
def confirm_send_compose(draft_id: str) -> dict:
    """Commit a compose previously staged by ``prepare_send_compose``.

    `draft_id` is the id returned by ``prepare_send_compose``. The draft
    must still be present (not consumed, not expired). Returns
    ``{ok: True, action: "confirm_send_compose", evidence: <summary>}``
    on success.

    If the draft is missing or expired, returns a controlled-failure
    response and does not tap the Send button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_send_compose",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_send_compose first.",
        }
    sim = SimulatorBridge.get()
    if not _tap_send(sim):
        return {
            "ok": False,
            "action": "confirm_send_compose",
            "message": "Send button not found in current UI; verify the compose sheet is still open.",
        }
    sim.wait(0.5)
    return {
        "ok": True,
        "action": "confirm_send_compose",
        "evidence": draft.get("payload", {}),
    }


def _visible_row_count(sim) -> int:
    """Number of distinct ``mail_row_<slug>`` ids currently in the tree."""
    return len(set(re.findall(r'mail_row_([^"\s]+)', sim.observe_text() or "")))


def _inbox_unread_count(sim) -> Optional[int]:
    """Read the inbox unread badge from the Mailboxes panel, or None.

    Opens the panel (``mailboxes_button``), parses the numeric badge on the
    ``mailbox_inbox`` row, and dismisses the panel back to the inbox. Used to
    confirm ``bulk_mark_read`` actually reduced the unread count rather than
    no-opping on an empty selection (a false positive otherwise).
    """
    try:
        sim.tap_id("mailboxes_button"); sim.wait(0.4)
    except Exception:
        return None
    tree = sim.observe_text() or ""
    count = None
    idx = tree.find('mailbox_inbox')
    if idx != -1:
        # The unread badge is a StaticText child of the inbox cell holding a
        # bare integer; the cell spans ~900 chars (icon + title + separators).
        window = tree[idx:idx + 1000]
        digits = re.findall(r'(?:value|label)="(\d{1,4})"', window)
        if digits:
            count = int(digits[0])
    # Dismiss the panel back to the inbox list.
    _ensure_inbox_list(sim)
    return count


def _commit_bulk(sim, button_id: str, verb: str, gerund: str) -> str:
    """Tap a bulk-action toolbar button and CONFIRM a real removal effect.

    Captures the visible row count before the tap and after; a genuine
    archive/delete removes the selected rows from the current list, so the
    count must drop. If the count is unchanged we report an HONEST failure
    instead of a false ``ok:true`` (e.g. the agent entered selection mode but
    never tapped any row, so the toolbar button no-ops).
    """
    before = _visible_row_count(sim)
    try:
        sim.tap_id(button_id)
    except Exception as exc:
        return (
            f"Could not tap {verb}. Call enter_bulk_select() and tap the rows "
            f"to {verb.lower()} first. {str(exc)[:120]}"
        )
    sim.wait(0.5)
    after = _visible_row_count(sim)
    if after < before:
        return f"{gerund} {before - after} bulk-selected message(s)."
    return (
        f"No messages were {gerund.lower()} — the current list is unchanged. "
        "Enter bulk-select mode and tap the row(s) you want first, then retry "
        f"(or use {verb.lower()}_message(subject) to act on one named message)."
    )


@mcp.tool()
def enter_bulk_select() -> str:
    """Enter bulk-select mode by tapping ``select_button``.

    Works from any screen — self-navigates to the inbox list first.
    Idempotent: if already in selection mode (the button reads "Done") it
    stays in rather than tapping again and exiting. After entering, tap
    individual mail rows to select them, then call ``bulk_archive`` /
    ``bulk_delete`` / ``bulk_mark_read`` (or the prepare/confirm pair) to act
    on the selection. (Those bulk tools also self-enter this mode when called
    blind, so this is only needed to control WHICH rows are selected.)
    """
    sim = SimulatorBridge.get()
    # Self-navigate to the inbox list — select_button only exists there, and
    # agents call this blind from a cold app / detail / search-active state.
    tree = _ensure_inbox_list(sim)
    # If we're already in selection mode (select_button now reads "Done"),
    # tapping again would EXIT it. Detect that and stay in.
    if 'name="select_button" label="Done"' in tree:
        return "Already in bulk-select mode. Tap rows then call bulk_* tools."
    sim.tap_id("select_button")
    sim.wait(0.4)
    return "Entered bulk-select mode. Use bulk_* tools next."


@mcp.tool()
def bulk_archive() -> str:
    """Archive bulk-selected messages.

    If you have already entered bulk-select mode and tapped rows, archives
    exactly that selection. If called blind (not in selection mode), it
    self-navigates to the inbox list, enters selection mode, and selects the
    first visible row so the archive moves a real message — so
    ``enter_bulk_select`` first is optional, but call it (and tap rows) when
    you need to control WHICH messages are archived. To archive one named
    message use ``archive_message(subject)`` instead.

    Confirms a real effect (the visible row count drops) and returns an
    honest "No messages were Archived" string when nothing changed (e.g. an
    empty selection). Returns "No messages available to archive" when the
    current list has no rows.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    already_selecting = 'name="select_button" label="Done"' in tree
    if not already_selecting:
        # Blind call: self-enter selection mode and select the first row so the
        # archive actually moves a message instead of silently no-opping.
        tree = _ensure_selection_mode(sim)
        ok, row = _ensure_one_row_selected(sim, tree)
        if not ok:
            return (
                "No messages available to archive in the current list. Open a "
                "folder with messages, then retry."
            )
    return _commit_bulk(sim, "bulk_archive_button", "Archive", "Archived")


def _bulk_delete_collect_targets() -> tuple[list[str], int]:
    """Inspect the current UI tree for candidate mail rows in selection mode.

    Returns ``(ids, count)`` where ``ids`` is the list of visible
    ``mail_row_<slug>`` accessibility IDs from the current tree (sorted,
    deduped) and ``count`` is its length. In bulk-select mode these are
    the rows the user could have tapped; the iOS XCUITest tree does not
    surface per-row selected state by accessibility ID, so we report the
    visible candidates so the agent can sanity-check scope.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text()
    ids = sorted(set(re.findall(r'mail_row_([^"\s]+)', tree)))
    return ids, len(ids)


def _bulk_delete_fill_form() -> Optional[str]:
    """Pre-commit step for ``bulk_delete``: verify the bulk-delete control
    is reachable but DO NOT tap it.

    Returns None on success or a precondition message string on failure.
    Used by both ``bulk_delete`` (one-shot commit) and
    ``prepare_bulk_delete`` (capture-only).
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    # Blind call: if the delete control isn't visible we're not in selection
    # mode. Self-navigate to the inbox list, enter selection mode, and select
    # the first row so the delete acts on a real message.
    if "bulk_delete_button" not in tree:
        tree = _ensure_selection_mode(sim)
        ok, _row = _ensure_one_row_selected(sim, tree)
        tree = sim.observe_text() or tree
        if "bulk_delete_button" not in tree:
            return (
                "bulk_delete_button not reachable. Call enter_bulk_select() "
                "first and tap the message rows you want to delete."
            )
        if not ok and "mail_row_" not in tree:
            return (
                "No mail rows available to delete in the current list. Open a "
                "folder with messages, then retry."
            )
    if "mail_row_" not in tree:
        return (
            "No mail rows visible in the current list. Open a folder with "
            "messages and call enter_bulk_select() before bulk_delete."
        )
    return None


@mcp.tool()
def bulk_delete() -> str:
    """Delete (move to Trash) bulk-selected messages.

    If you have already entered bulk-select mode and tapped rows, deletes
    exactly that selection. If called blind (not in selection mode), it
    self-navigates to the inbox list, enters selection mode, and selects the
    first visible row — so ``enter_bulk_select`` first is optional, but call
    it (and tap rows) when you need to control WHICH messages are deleted. To
    delete one named message use ``delete_message(subject)`` instead.

    Confirms a real effect (the visible row count drops) and returns an
    honest failure string when nothing changed or no rows are present.

    Legacy single-verb commit; prefer ``prepare_bulk_delete`` +
    ``confirm_bulk_delete`` for new code so the agent can preview the
    visible candidates.
    """
    err = _bulk_delete_fill_form()
    if err:
        return err
    sim = SimulatorBridge.get()
    return _commit_bulk(sim, "bulk_delete_button", "Delete", "Deleted")


@mcp.tool()
def prepare_bulk_delete() -> dict:
    """Stage a bulk-delete WITHOUT tapping the Delete control.

    Verifies that the bulk-delete UI is reachable (selection mode is
    active and at least one mail row is visible), captures the visible
    candidate rows, and stores a draft. Returns ``{ok: True, action:
    "prepare_bulk_delete", draft_id, summary: {count, sample_ids}}`` on
    success, where ``count`` is the number of visible mail rows in the
    current list and ``sample_ids`` is the first 5 ``mail_row_<slug>``
    suffixes (so the agent can confirm scope before commit). Pass the
    ``draft_id`` to ``confirm_bulk_delete`` to actually delete.

    On precondition failure, returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _bulk_delete_fill_form()
    if err:
        return {"ok": False, "action": "prepare_bulk_delete", "message": err}
    ids, count = _bulk_delete_collect_targets()
    summary = {"count": count, "sample_ids": ids[:5]}
    draft_id = ts.create_draft("mail", "bulk_delete", summary)
    return {
        "ok": True,
        "action": "prepare_bulk_delete",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_bulk_delete(draft_id) to commit.",
    }


@mcp.tool()
def confirm_bulk_delete(draft_id: str) -> dict:
    """Commit a bulk delete previously staged by ``prepare_bulk_delete``.

    `draft_id` is the id returned by ``prepare_bulk_delete``. The draft
    must still be present (not consumed, not expired). Returns
    ``{ok: True, action: "confirm_bulk_delete", evidence: <summary>}``
    on success.

    If the draft is missing or expired, returns a controlled-failure
    response and does not tap the Delete button.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_bulk_delete",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_bulk_delete first.",
        }
    sim = SimulatorBridge.get()
    before = _visible_row_count(sim)
    try:
        sim.tap_id("bulk_delete_button"); sim.wait(0.5)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_bulk_delete",
            "message": "bulk_delete_button not found in current UI; verify selection mode is still active.",
        }
    after = _visible_row_count(sim)
    if after >= before:
        return {
            "ok": False,
            "action": "confirm_bulk_delete",
            "message": (
                "Tapped Delete but the list is unchanged — no rows were "
                "selected. Enter bulk-select and tap the row(s) first."
            ),
        }
    return {
        "ok": True,
        "action": "confirm_bulk_delete",
        "removed_count": before - after,
        "evidence": draft.get("payload", {}),
    }


@mcp.tool()
def bulk_mark_read() -> str:
    """Mark the bulk-selected messages as read.

    Marks each selected message read (an already-read message is left
    unchanged — this is a one-way mark-read, not a read/unread toggle).
    The inbox unread count drops by the number of selected messages that
    were unread.

    If you have already entered bulk-select mode and tapped rows, marks
    exactly that selection. If called blind (not in selection mode), it
    self-navigates to the inbox list, enters selection mode, and selects the
    first visible row — so ``enter_bulk_select`` first is optional, but call
    it (and tap rows) to control WHICH messages are marked. On the blind path
    it confirms the inbox unread badge actually dropped and returns an honest
    "No unread messages were marked" string if it did not (the row was
    already read).
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    already_selecting = 'name="select_button" label="Done"' in tree
    # Capture the inbox unread badge BEFORE marking so we can confirm a real
    # effect. (Reading it opens/closes the mailboxes panel, which would exit
    # selection mode — so only do this on the blind path, before we enter
    # selection mode ourselves. On the already-selecting path the caller's
    # selection must be preserved, so we skip the badge read there.)
    before_unread = None
    if not already_selecting:
        before_unread = _inbox_unread_count(sim)
        tree = _ensure_selection_mode(sim)
        ok, row = _ensure_one_row_selected(sim, tree)
        if not ok:
            return (
                "No messages available to mark in the current list. Open a "
                "folder with messages, then retry."
            )
    try:
        sim.tap_id("bulk_read_button")
    except Exception as exc:
        return (
            "Could not tap Read. Call enter_bulk_select() and tap the rows "
            f"first. {str(exc)[:120]}"
        )
    sim.wait(0.4)
    # Confirm the unread badge dropped (blind path only). If it didn't move,
    # nothing was actually marked — report honestly instead of a false ok.
    if before_unread is not None:
        after_unread = _inbox_unread_count(sim)
        if after_unread is not None and after_unread < before_unread:
            return (
                f"Marked {before_unread - after_unread} message(s) as read "
                f"(inbox unread {before_unread} -> {after_unread})."
            )
        if after_unread is not None and after_unread >= before_unread:
            return (
                "No unread messages were marked — the inbox unread count is "
                f"unchanged ({after_unread}). The selected row(s) may already "
                "be read; tap an unread row first, then retry."
            )
    return "Marked bulk-selected messages as read."


@mcp.tool()
def search(query: str, page: int = 1, page_size: int = 50) -> dict:
    """Search the current mail list via the search bar.

    Args:
        query: Free-text query. Matched against subject/sender/body of
            messages in the current folder.

    Returns the post-filter ``list_messages(page, page_size)`` dict so the
    agent can see remaining rows without overlarge/truncated tool output.
    """
    sim = SimulatorBridge.get()
    # Blind agents call search from a cold app / detail view where the search
    # bar isn't present. Self-navigate to the inbox list so the bar exists.
    _ensure_inbox_list(sim)
    tapped = False
    for aid in ("mail_search_bar", "Search Mail"):
        try:
            sim.tap_id(aid)
            tapped = True
            break
        except Exception:
            continue
    if not tapped:
        # The bar can sit just off-screen behind the large title; nudge the
        # list down to reveal it, then retry once.
        sim.swipe("down"); sim.wait(0.3)
        for aid in ("mail_search_bar", "Search Mail"):
            try:
                sim.tap_id(aid)
                tapped = True
                break
            except Exception:
                continue
    if not tapped:
        return (
            "Could not focus the Mail search bar. Call launch() then retry; "
            "the search field lives at the top of the inbox list."
        )
    sim.wait(0.3)
    sim.type_text(query)
    sim.wait(0.6)
    return list_messages(page=page, page_size=page_size)


@mcp.tool()
def open_settings() -> str:
    """Open the Mail settings sheet via ``settings_button``.

    Verifies the settings screen actually rendered (its ``dark_mode_toggle``
    / "Auto Notifications" controls) before reporting success, so a tap that
    no-ops behind a stale overlay fails honestly instead of falsely claiming
    the sheet opened.
    """
    sim = SimulatorBridge.get()
    # settings_button lives on the inbox nav bar; self-navigate there so blind
    # calls from a cold app / detail view succeed.
    _ensure_inbox_list(sim)
    try:
        sim.tap_id("settings_button")
    except Exception as exc:
        return (
            "Could not open Mail settings — settings_button was not hittable. "
            f"Call launch() then retry. {str(exc)[:120]}"
        )
    sim.wait(0.5)
    tree = sim.observe_text() or ""
    # Settings screen renders the dark-mode switch and the notifications
    # controls; either is a reliable marker that the sheet is actually up.
    if ("dark_mode_toggle" in tree or "notifications_apply_button" in tree
            or "Auto Notifications" in tree):
        return "Opened Mail settings."
    # Tap landed but the settings screen did not render — try once more after
    # re-basing on the inbox list (a covering overlay may have eaten the tap).
    _ensure_inbox_list(sim)
    try:
        sim.tap_id("settings_button")
    except Exception:
        pass
    sim.wait(0.5)
    tree = sim.observe_text() or ""
    if ("dark_mode_toggle" in tree or "notifications_apply_button" in tree
            or "Auto Notifications" in tree):
        return "Opened Mail settings."
    return (
        "Could not confirm Mail settings opened — the settings controls "
        "(dark mode / notifications) did not render. Call observe() to "
        "inspect the current screen and dismiss any open sheet, then retry."
    )


if __name__ == "__main__":
    mcp.run()
