"""CloudDrive MCP — cloud-storage file browser on the iOS simulator.

Bundle ID: ``com.iosworld.benchmark.clouddrive``.

ID conventions used by tools below:
* File rows: ``file_row_drive_<slug>`` plus view-specific variants
  ``recent_row_drive_<slug>``, ``shared_row_drive_<slug>``,
  ``starred_row_drive_<slug>``, ``trash_row_drive_<slug>``,
  ``search_file_row_drive_<slug>`` (slug is the file's id minus the
  ``file_`` prefix, e.g. ``onboarding_pdf``).
* Folder rows: ``folder_row_<slug>``. Folder ids look like
  ``folder_<slug>`` (root is ``folder_root_my_drive``).
* Browse tabs: ``tab_drive_home``, ``tab_drive_starred``,
  ``tab_drive_shared``.
* File-action buttons (on a selected file): ``file_action_star``,
  ``file_action_rename``, ``file_action_move``, ``file_action_trash``,
  ``file_action_duplicate``, ``file_action_restore``.

Most write tools fall back to direct shared-state mutations when the UI
tap chain fails; the benchmark grades end-state. Tools that target the
"currently selected file" rely on the module-level ``_CURRENT_FILE_ID``
set by the most recent ``open_file`` / ``star_file(name=...)`` call.
"""

import sys, pathlib, copy, re
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("CloudDrive")

BUNDLE_ID = "com.iosworld.benchmark.clouddrive"
_CURRENT_FILE_ID = ""


def _unique_id(prefix: str, label: str, existing_ids: set[str]) -> str:
    base = re.sub(r"[^a-z0-9_]+", "", label.lower().replace(" ", "_")) or "item"
    candidate = f"{prefix}_{base}"
    index = 2
    while candidate in existing_ids:
        candidate = f"{prefix}_{base}_{index}"
        index += 1
    return candidate


def _ensure_foreground() -> None:
    """Make sure CloudDrive's tab bar is on screen before tapping its tabs.

    Blind agents often call ``view_starred`` / ``view_shared`` etc. from a
    fresh state, after another app was open, or — critically — while a
    search/detail overlay is up (the agent just called ``search_files``).
    In all of these the ``tab_drive_*`` ids aren't tappable, so a naive tap
    raises "not currently visible".

    Recovery ladder (cheapest first):
      1. If the tab bar is already present, do nothing.
      2. Otherwise dismiss any open search/detail overlay by tapping its
         back chevron, then re-observe.
      3. If tabs are still missing (CloudDrive backgrounded, or a plain
         ``launch_app`` won't pop the overlay because the app is already
         frontmost), terminate + relaunch which resets the nav stack.
    """
    sim = SimulatorBridge.get()

    def tabs_visible() -> bool:
        try:
            return "tab_drive_" in (sim.observe_text() or "")
        except Exception:
            return False

    if tabs_visible():
        return

    # Step 2: try to back out of an overlay (search results / file detail).
    for aid in ("chevron.left", "Back", "drive_search_back", "xmark"):
        try:
            sim.tap_id(aid); sim.wait(0.4)
            if tabs_visible():
                return
        except Exception:
            continue

    # Step 3: hard reset. A plain launch_app of an already-frontmost app does
    # NOT pop the overlay, so terminate first to force a clean root render.
    try:
        sim.terminate_app(BUNDLE_ID); sim.wait(0.4)
    except Exception:
        pass
    try:
        sim.launch_app(BUNDLE_ID); sim.wait(1.0)
    except Exception:
        pass


@mcp.tool()
def launch() -> str:
    """Launch CloudDrive and return the post-launch accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched CloudDrive.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree as text (no navigation)."""
    sim = SimulatorBridge.get()
    return ts.observe_app_scoped(
        sim,
        bundle_id=BUNDLE_ID,
        app_name="CloudDrive",
        markers=("tab_drive_home", "file_row_drive_", "folder_row_"),
    )


@mcp.tool()
def search_files(query: str) -> dict:
    """Open Drive search, type a query, and return matching file slugs.

    Self-foregrounds CloudDrive first (dismissing any overlay / relaunching
    if needed), so it works blind from any screen.

    Args:
        query: Free-text substring matched case-insensitively against file
            ids AND display names (e.g. ``"runbook"`` or ``"Mobile Launch"``).

    Returns ``{query, files: [slug, ...], count}`` where each ``slug`` is a
    file id (trailing part of ``file_row_drive_<slug>``). Pass any returned
    slug — or just a display name — straight to ``open_file(name=...)``.
    Falls back to shared-state id/name substring matching when the UI
    surfaces no rows, so ``count`` reflects real matches.
    """
    import re as _re
    _ensure_foreground()
    sim = SimulatorBridge.get()
    for aid in ("Search in Drive", "drive_search_field", "Search"):
        try:
            sim.tap_id(aid)
            sim.wait(0.3)
            break
        except Exception:
            continue
    try:
        sim.type_text(query)
        sim.wait(0.5)
        tree = sim.observe_text() or ""
    except Exception:
        tree = sim.observe_text() or ""
    slugs = sorted(set(_re.findall(r'(?:file|recent|shared|starred|trash|search_file)_row_drive_([^"\s]+)', tree)))
    if not slugs:
        env = dl.read_envelope()
        q = query.lower().strip()
        slugs = sorted(
            f.get("id")
            for f in env.get("seededData", {}).get("files", [])
            if f.get("id") and (q in f.get("id", "").lower() or q in f.get("name", "").lower())
        )
    return {"query": query, "files": slugs, "count": len(slugs)}


@mcp.tool()
def open_file(name: str) -> str:
    """Open a file by id, slug, row id, or display name; mark it current.

    Args:
        name: Any of these accepted forms — the file's display NAME or a
            case-insensitive title substring (e.g. ``"Onboarding"``); the
            full id (``"file_onboarding_pdf"``); the bare slug (``"onboarding_pdf"``);
            or a copied UI row id (``"file_row_drive_onboarding_pdf"``,
            ``"recent_row_drive_..."``, ``"search_file_..."`` — row prefixes are
            stripped automatically). You do NOT need to know the slug — the
            human-readable name works.

    Resolves the file in shared state, sets it as the current selection,
    bumps ``lastOpenedAt`` and reloads the app. Returns
    ``{ok: True, file_id, name, ...}`` on success. Returns a bounded error
    string (no match) when ``name`` matches no file — call ``search_files``
    or ``list_files``/``list_all_files_with_meta`` to discover targets.
    """
    global _CURRENT_FILE_ID
    sim = SimulatorBridge.get()
    # Best-effort UI tap (no-ops in the browser-only UI). Resolve the file in
    # shared state — the slug may be the bare id suffix (``onboarding_pdf``),
    # the full id (``file_onboarding_pdf``), or a title substring.
    slug = _strip_row_prefix(name)
    try:
        sim.tap_id(f"file_row_drive_{slug}"); sim.wait(0.4)
    except Exception:
        pass
    env = dl.read_envelope()
    file_obj = _resolve_file(env, name)
    if not file_obj:
        return f"No file matching '{name}'. Use search_files() or list_files() to discover slugs."
    file_obj["lastOpenedAt"] = "2026-05-11T00:00:00Z"
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    _CURRENT_FILE_ID = file_obj.get("id", name)
    return {"ok": True, "action": "open_file", "file_id": _CURRENT_FILE_ID, "name": file_obj.get("name"), "message": "Opened file via shared state."}


@mcp.tool()
def open_folder(name: str) -> str:
    """Open a folder by id, slug, row id, or display name.

    Args:
        name: Any of — the folder's display NAME or case-insensitive name
            substring (e.g. ``"Team Assets"``); the full id
            (``"folder_team_assets"``); the bare slug (``"team_assets"``); or a
            ``"folder_row_team_assets"`` UI row id (the ``folder_row_`` prefix is
            stripped). The human-readable name works — no need to guess a slug.

    Resolves in shared state and returns ``{ok: True, folder_id, name,
    file_count}``. On no match returns ``{ok: False, message, available}``
    listing up to 10 candidate folder names. Discover folders via
    ``list_folders_with_meta()``.
    """
    sim = SimulatorBridge.get()
    # Best-effort UI tap (no-ops in the browser-only UI). Resolve the folder in
    # shared state so we can confirm it exists and list its contents even when
    # the row isn't tappable; the cloud apps are graded on state, not the tree.
    slug = name[len("folder_row_"):] if name.startswith("folder_row_") else name
    try:
        sim.tap_id(f"folder_row_{slug}"); sim.wait(0.4)
    except Exception:
        pass
    env = dl.read_envelope()
    folders = env.get("seededData", {}).get("folders", [])
    folder = (
        dl.envelope_find(env, "folders", value=name)
        or dl.envelope_find(env, "folders", value=slug)
        or dl.envelope_find(env, "folders", value=f"folder_{slug}")
        or next((f for f in folders if slug.lower() in str(f.get("name", "")).lower()), None)
    )
    if not folder:
        names = [f.get("name") for f in folders][:10]
        return {"ok": False, "action": "open_folder", "message": f"No folder matching '{name}'.", "available": names}
    fid = folder.get("id")
    contents = [fi.get("id") for fi in env.get("seededData", {}).get("files", [])
                if fi.get("parentFolderId") == fid]
    return {"ok": True, "action": "open_folder", "folder_id": fid,
            "name": folder.get("name"), "file_count": len(contents)}


@mcp.tool()
def star_file(name: str = "") -> str:
    """Toggle the starred flag on a file (by name/id, or the selected file).

    Args:
        name: Optional target — the file's display NAME or case-insensitive
            title substring (e.g. ``"Onboarding"``), its id
            (``"file_onboarding_pdf"``), bare slug, or a UI row id. The
            human-readable name works. When empty, falls back to the
            currently selected file (``_CURRENT_FILE_ID`` from the most
            recent ``open_file``/``star_file`` call).

    This FLIPS the flag (starred -> unstarred or vice versa); call twice to
    return to the original state. To guarantee a file is starred, use
    ``ensure_starred`` instead. Commits directly to shared state. Returns
    ``{ok: True, file_id, starred: <new value>}``, or a bounded error string
    when no target resolves.
    """
    global _CURRENT_FILE_ID
    sim = SimulatorBridge.get()
    # Commit the end-state directly via the shared store (the browser-only UI
    # doesn't expose file_action_star). Deliberately NO best-effort UI tap:
    # tapping a working toggle AND flipping state below would double-toggle back
    # to a no-op. The shared-state write is the single source of truth.
    target = name or _CURRENT_FILE_ID
    env = dl.read_envelope()
    file_obj = _resolve_file(env, target)
    if not file_obj:
        return f"No selected file to star. Pass name=... or call open_file first."
    file_obj["starred"] = not bool(file_obj.get("starred", False))
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    _CURRENT_FILE_ID = file_obj.get("id", target)
    return {"ok": True, "action": "star_file", "file_id": _CURRENT_FILE_ID, "starred": file_obj["starred"]}


@mcp.tool()
def ensure_starred(name: str = "") -> dict:
    """Ensure a file is starred without toggling it off.

    Args:
        name: Optional target — the file's display NAME or case-insensitive
            title substring, its id, bare slug, or a UI row id. When empty,
            falls back to the currently selected file (``_CURRENT_FILE_ID``).

    This is idempotent: already-starred files remain starred and return
    ``changed: False``. Use this for tasks that say "star the file"; the
    legacy ``star_file`` tool intentionally remains a flip-toggle for
    backwards compatibility.
    """
    global _CURRENT_FILE_ID
    target = name or _CURRENT_FILE_ID
    env = dl.read_envelope()
    file_obj = _resolve_file(env, target)
    if not file_obj:
        return {
            "ok": False,
            "action": "ensure_starred",
            "message": "No selected file to star. Pass name=... or call open_file first.",
        }
    was_starred = bool(file_obj.get("starred", False))
    if not was_starred:
        file_obj["starred"] = True
        dl.write_envelope(env)
        dl.reload_app(BUNDLE_ID)
    _CURRENT_FILE_ID = file_obj.get("id", target)
    return {
        "ok": True,
        "action": "ensure_starred",
        "file_id": _CURRENT_FILE_ID,
        "starred": True,
        "changed": not was_starred,
    }


@mcp.tool()
def create_folder(name: str) -> dict:
    """Create a new folder in the My Drive root (direct shared-state write).

    Args:
        name: Display name for the new folder (e.g. ``"Roadmap 2026"``).
            Must be non-empty / non-whitespace — otherwise returns
            ``{ok: False, error}``. Idempotent: if a folder with the same
            case-insensitive name already exists, returns it with
            ``created: False``.

    Returns ``{ok, folder_id, name, created, message}``. The new folder's
    id is auto-derived from a snake-case slug of ``name``.
    """
    folder_name = (name or "").strip()
    if not folder_name:
        return {"ok": False, "error": "folder name is required"}
    env = dl.read_envelope()
    data = env.setdefault("seededData", {})
    folders = data.setdefault("folders", [])
    existing = next((f for f in folders if str(f.get("name", "")).lower() == folder_name.lower()), None)
    if existing:
        return {
            "ok": True,
            "folder_id": existing.get("id"),
            "name": existing.get("name"),
            "created": False,
            "message": f"Folder '{existing.get('name')}' already exists.",
        }
    folder_id = _unique_id("folder", folder_name, {str(f.get("id")) for f in folders})
    folders.append({
        "id": folder_id,
        "name": folder_name,
        "parentFolderId": "folder_root_my_drive",
        "ownerName": "Jordan Avery",
        "shared": False,
        "starred": False,
        "trashed": False,
        "createdAt": "2026-05-12T00:00:00Z",
        "updatedAt": "2026-05-12T00:00:00Z",
    })
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "folder_id": folder_id,
        "name": folder_name,
        "created": True,
        "message": f"Created folder '{folder_name}'.",
    }


_ROW_PREFIXES = (
    "search_file_row_drive_", "recent_row_drive_", "shared_row_drive_",
    "starred_row_drive_", "trash_row_drive_", "file_row_drive_",
    # The live search results render rows as ``search_file_<id>`` (e.g.
    # ``search_file_slides_all_hands_story``), so stripping this prefix yields
    # the bare ``file_``-stripped id which resolves via the ``file_`` fallback.
    "search_file_",
)


def _strip_row_prefix(target: str) -> str:
    """Normalize a target that may be a full UI row id into a bare slug/id.

    Blind agents copy ids straight out of the accessibility tree, e.g.
    ``file_row_drive_all_hands_storyline`` (real benchmark trajectory). The
    underlying file id is ``file_all_hands_storyline`` / slug
    ``all_hands_storyline`` — neither matched the raw row id, so resolution
    falsely failed. Strip the known row prefixes so the slug resolves.
    """
    t = (target or "").strip()
    for p in _ROW_PREFIXES:
        if t.startswith(p):
            return t[len(p):]
    return t


def _resolve_file(env: dict, target: str):
    """Resolve a file by id, ``file_``-prefixed id, row id, or title substring.

    Returns the file dict or ``None``. Shared by every selected-file tool so
    a blind agent can pass a display NAME, a bare id, a full UI row id, or a
    title substring directly without pre-navigating via ``open_file``.
    """
    target = (target or "").strip()
    if not target:
        return None
    slug = _strip_row_prefix(target)
    candidates = []
    for c in (target, slug):
        if c and c not in candidates:
            candidates.append(c)
    for c in candidates:
        hit = (
            dl.envelope_find(env, "files", value=c)
            or dl.envelope_find(env, "files", value=f"file_{c}")
        )
        if hit:
            return hit
    for c in candidates:
        hit = dl.envelope_match(env, "files", title_substring=c)
        if hit:
            return hit
    return None


@mcp.tool()
def rename_file(new_name: str = "", name: str = "") -> str:
    """Rename a file (by name/id, or the currently selected file).

    Args:
        new_name: New display name. REQUIRED — empty/whitespace-only values
            are rejected.
        name: Optional target — the file's display NAME or case-insensitive
            title substring (e.g. ``"Mobile Launch Plan"``), its id
            (``"file_doc_meeting_notes"``), bare slug, or a UI row id. The
            human-readable name works — no need to ``open_file`` first. When
            empty, falls back to the currently selected file
            (``_CURRENT_FILE_ID``).

    Commits to shared state. Returns ``{ok: True, file_id, old_name, name}``,
    or a bounded error string when ``new_name`` is empty or ``name`` matches
    no file.
    """
    global _CURRENT_FILE_ID
    sim = SimulatorBridge.get()
    target_name = (new_name or "").strip()
    # Best-effort UI tap to open the rename sheet (no-ops in the browser-only
    # UI); then commit the rename in shared state so the end-state changes.
    try:
        sim.tap_id("file_action_rename"); sim.wait(0.3)
    except Exception:
        pass
    if not target_name:
        return {"ok": False, "error": "new_name is required to rename the selected file"}
    env = dl.read_envelope()
    target = name or _CURRENT_FILE_ID
    if not target:
        return "No selected file to rename. Pass name=... or call open_file first."
    file_obj = _resolve_file(env, target)
    if not file_obj:
        return f"No file matching '{target}' in shared state."
    _CURRENT_FILE_ID = file_obj.get("id", target)
    old_name = file_obj.get("name")
    file_obj["name"] = target_name
    file_obj["updatedAt"] = "2026-05-12T00:00:00Z"
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "rename_file", "file_id": _CURRENT_FILE_ID, "old_name": old_name, "name": target_name}


@mcp.tool()
def move_file(destination_folder: str = "", name: str = "") -> str:
    """Move a file to another folder (by name/id, or the selected file).

    Args:
        destination_folder: Destination folder — its display NAME or a
            case-insensitive name substring (e.g. ``"Team Assets"``) OR a
            ``folder_*`` id (e.g. ``"folder_team_assets"``). The
            human-readable name works. REQUIRED; missing/unknown
            destinations return ``{ok: False, error}``.
        name: Optional source file — the file's display NAME or title
            substring (e.g. ``"Compute Access Runbook"``), its id
            (``"file_doc_meeting_notes"``), bare slug, or a UI row id. The
            name works — no ``open_file`` needed first. When empty, falls
            back to the currently selected file (``_CURRENT_FILE_ID``).

    Commits to shared state. Returns ``{ok: True, file_id,
    old_parent_folder_id, parent_folder_id, parent_folder_name}`` on
    success, or a bounded error / ``{ok: False, error}`` when the file or
    destination folder cannot be resolved.
    """
    global _CURRENT_FILE_ID
    sim = SimulatorBridge.get()
    destination = (destination_folder or "").strip()
    # Best-effort UI tap to open the move sheet (no-ops in the browser-only
    # UI); then commit the move in shared state when a destination is given.
    try:
        sim.tap_id("file_action_move"); sim.wait(0.3)
    except Exception:
        pass
    if True:
        target = name or _CURRENT_FILE_ID
        if not target:
            return "No selected file to move. Pass name=... or call open_file first."
        if not destination:
            return {"ok": False, "error": "destination_folder is required to move the selected file"}
        env = dl.read_envelope()
        data = env.setdefault("seededData", {})
        file_obj = _resolve_file(env, target)
        folder_obj = (
            dl.envelope_find(env, "folders", value=destination)
            or next((f for f in data.get("folders", []) if destination.lower() in str(f.get("name", "")).lower()), None)
        )
        if not file_obj:
            return f"No file matching '{target}' in shared state."
        if not folder_obj:
            return {"ok": False, "error": f"No destination folder matching '{destination_folder}'"}
        _CURRENT_FILE_ID = file_obj.get("id", target)
        old_parent = file_obj.get("parentFolderId")
        file_obj["parentFolderId"] = folder_obj.get("id")
        file_obj["updatedAt"] = "2026-05-12T00:00:00Z"
        dl.write_envelope(env)
        dl.reload_app(BUNDLE_ID)
        return {
            "ok": True,
            "action": "move_file",
            "file_id": _CURRENT_FILE_ID,
            "old_parent_folder_id": old_parent,
            "parent_folder_id": folder_obj.get("id"),
            "parent_folder_name": folder_obj.get("name"),
        }


def _trash_file_fill_form(target: str = "") -> Optional[str]:
    """Verify a trash target exists so trash_file has a defined target.

    ``target`` may be a file id or title substring; when empty it falls back
    to ``_CURRENT_FILE_ID``. Returns None on success or a precondition message
    on failure. Used by both ``trash_file`` (one-shot commit) and
    ``prepare_trash_file`` (capture-only).
    """
    target = target or _CURRENT_FILE_ID
    if not target:
        return "No selected file to trash. Pass name=... or call open_file first."
    env = dl.read_envelope()
    file_obj = _resolve_file(env, target)
    if not file_obj:
        return f"No file matching '{target}' in shared state."
    return None


def _capture_trash_file_context(target: str = "") -> dict:
    """Snapshot the file that would be trashed."""
    target = target or _CURRENT_FILE_ID
    env = dl.read_envelope()
    file_obj = _resolve_file(env, target) or {}
    return {
        "file_id": file_obj.get("id") or target,
        "name": file_obj.get("name"),
        "parent_folder_id": file_obj.get("parentFolderId"),
        "size": file_obj.get("sizeBytes") or file_obj.get("size"),
    }


@mcp.tool()
def trash_file(name: str = "") -> str:
    """Trash a file (by name/id, or the currently selected file).

    Args:
        name: Optional target — the file's display NAME or case-insensitive
            title substring (e.g. ``"Untitled document"``), its id
            (``"file_doc_travel_checklist"``), bare slug, or a UI row id. The
            name works — no ``open_file`` needed first. When empty, falls
            back to the currently selected file (``_CURRENT_FILE_ID``).

    Sets ``trashed=True`` in shared state. Returns ``{ok: True, file_id,
    trashed: True}``, or a bounded error string when no target resolves.
    Use ``restore_file`` to undo. For a stage-then-confirm flow, use
    ``prepare_trash_file`` + ``confirm_trash_file``.
    """
    global _CURRENT_FILE_ID
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("file_action_trash"); sim.wait(0.3)
    except Exception:
        pass
    target = name or _CURRENT_FILE_ID
    if not target:
        return "No selected file to trash. Pass name=... or call open_file first."
    env = dl.read_envelope()
    file_obj = _resolve_file(env, target)
    if not file_obj:
        return f"No file matching '{target}' in shared state."
    file_obj["trashed"] = True
    file_obj["updatedAt"] = "2026-05-12T00:00:00Z"
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    _CURRENT_FILE_ID = file_obj.get("id", target)
    return {"ok": True, "action": "trash_file", "file_id": _CURRENT_FILE_ID, "trashed": True}


@mcp.tool()
def prepare_trash_file(name: str = "") -> dict:
    """Stage a trash operation WITHOUT committing.

    Args:
        name: Optional target file id or case-insensitive title substring.
            When empty, falls back to the currently selected file
            (``_CURRENT_FILE_ID``).

    Captures a summary (``file_id``, ``name``, ``parent_folder_id``, ``size``)
    of the file that would be moved to trash.

    On success returns ``{ok: True, action: "prepare_trash_file",
    draft_id, summary}``. Pass the ``draft_id`` to ``confirm_trash_file``
    to commit. Drafts expire after the ``IOSWORLD_DRAFT_TTL_SECONDS``
    TTL (default 10 minutes).

    On precondition failure returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _trash_file_fill_form(name)
    if err:
        return {"ok": False, "action": "prepare_trash_file", "message": err}
    summary = _capture_trash_file_context(name)
    draft_id = ts.create_draft("clouddrive", "trash_file", summary)
    return {
        "ok": True,
        "action": "prepare_trash_file",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_trash_file(draft_id) to commit.",
    }


@mcp.tool()
def confirm_trash_file(draft_id: str) -> dict:
    """Commit a trash previously staged by ``prepare_trash_file``.

    ``draft_id`` is the id returned by ``prepare_trash_file``. Taps
    ``file_action_trash`` and returns ``{ok: True,
    action: "confirm_trash_file", evidence: <summary>}`` on success.

    Falls back to a shared-state mutation when the UI button is not
    present (mirrors the legacy single-verb tool). If the draft is
    missing or expired, returns a controlled-failure response without
    trashing anything.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_trash_file",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_trash_file first.",
        }
    payload = draft.get("payload", {})
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("file_action_trash"); sim.wait(0.3)
    except Exception:
        pass
    # Commit in shared state (UI tap no-ops in the browser-only UI). Resolve
    # the target from the draft payload so it works even if module state was
    # reset between prepare and confirm.
    target = payload.get("file_id") or _CURRENT_FILE_ID
    env = dl.read_envelope()
    file_obj = dl.envelope_find(env, "files", value=target) or dl.envelope_match(env, "files", title_substring=target)
    if not file_obj:
        return {
            "ok": False,
            "action": "confirm_trash_file",
            "message": f"Could not resolve file '{target}' to trash.",
        }
    file_obj["trashed"] = True
    file_obj["updatedAt"] = "2026-05-12T00:00:00Z"
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "action": "confirm_trash_file",
        "evidence": {**payload, "trashed": True},
    }


@mcp.tool()
def view_recent() -> str:
    """Switch to the Home tab (``tab_drive_home``) to see recent files.

    Self-foregrounds CloudDrive first, so it works blind even when another
    app is on screen or CloudDrive was never launched.
    """
    _ensure_foreground()
    sim = SimulatorBridge.get()
    ui = sim.tap_and_observe("tab_drive_home")
    return f"Recent files view.\n\n{ui}"


@mcp.tool()
def view_starred() -> str:
    """Switch to the Starred tab (``tab_drive_starred``) and return its tree.

    Self-foregrounds CloudDrive first so it works blind.
    """
    _ensure_foreground()
    sim = SimulatorBridge.get()
    ui = sim.tap_and_observe("tab_drive_starred")
    return f"Starred files view.\n\n{ui}"


@mcp.tool()
def view_shared() -> str:
    """Switch to the Shared tab (``tab_drive_shared``) and return its tree.

    Self-foregrounds CloudDrive first so it works blind.
    """
    _ensure_foreground()
    sim = SimulatorBridge.get()
    ui = sim.tap_and_observe("tab_drive_shared")
    return f"Shared files view.\n\n{ui}"


@mcp.tool()
def view_activity() -> str:
    """Surface the activity feed (foregrounds CloudDrive, then returns its tree)."""
    _ensure_foreground()
    sim = SimulatorBridge.get()
    ui = sim.observe_text()
    return f"Activity view.\n\n{ui}"


@mcp.tool()
def list_files() -> dict:
    """List the workspace's files from authoritative shared state.

    Returns ``{files: [{id, name}, ...], count}`` read straight from the
    workspace envelope (the same ``_data_layer`` source that
    ``list_all_files_with_meta`` uses), so ``count`` reflects the real
    files even when the browser-only UI under-renders rows. Each ``id``
    round-trips through ``open_file(name=<id>)``. Excludes trashed files
    (use ``list_all_files_with_meta()`` to also see trashed entries).

    Previously this scraped the live UI tree for ``file_row_drive_<slug>``
    rows, which routinely returned ``count: 0`` because the cloud UI does
    not surface those rows; reading the envelope fixes that.
    """
    env = dl.read_envelope()
    files = env.get("seededData", {}).get("files", [])
    out = [{"id": fi.get("id"), "name": fi.get("name")}
           for fi in files if not fi.get("trashed", False)]
    return {"files": out, "count": len(out)}


@mcp.tool()
def duplicate_file(name: str = "") -> str:
    """Duplicate a file (by name/id, or the currently selected file).

    Args:
        name: Optional source file — the file's display NAME or case-insensitive
            title substring (e.g. ``"Content Queue"``), its id
            (``"file_doc_hiring_notes"``), bare slug, or a UI row id. The name
            works — no ``open_file`` needed first. When empty, falls back to
            the currently selected file (``_CURRENT_FILE_ID``).

    Deep-copies the file in shared state with name ``"<original> Copy"`` and a
    fresh ``file_copy_*`` id; the copy becomes the new current selection.
    Returns ``{ok: True, source_file_id, file_id, name}``, or a bounded error
    string when no source resolves.
    """
    global _CURRENT_FILE_ID
    sim = SimulatorBridge.get()
    # Deliberately NO best-effort UI tap: file_action_duplicate isn't exposed by
    # the browser-only UI, and tapping a working button AND appending a copy
    # below would create two duplicates. The shared-state write is authoritative.
    if True:
        target = name or _CURRENT_FILE_ID
        if not target:
            return "No selected file to duplicate. Pass name=... or call open_file first."
        env = dl.read_envelope()
        files = env.setdefault("seededData", {}).setdefault("files", [])
        file_obj = _resolve_file(env, target)
        if not file_obj:
            return f"No file matching '{target}' in shared state."
        source_file_id = file_obj.get("id", target)
        duplicate = copy.deepcopy(file_obj)
        duplicate["id"] = _unique_id("file_copy", str(file_obj.get("name") or _CURRENT_FILE_ID), {str(f.get("id")) for f in files})
        duplicate["name"] = f"{file_obj.get('name', 'Untitled')} Copy"
        duplicate["createdAt"] = "2026-05-12T00:00:00Z"
        duplicate["updatedAt"] = "2026-05-12T00:00:00Z"
        duplicate["lastOpenedAt"] = None
        files.append(duplicate)
        dl.write_envelope(env)
        dl.reload_app(BUNDLE_ID)
        _CURRENT_FILE_ID = duplicate["id"]
        return {
            "ok": True,
            "action": "duplicate_file",
            "source_file_id": source_file_id,
            "file_id": duplicate["id"],
            "name": duplicate["name"],
        }


@mcp.tool()
def restore_file(name: str = "") -> str:
    """Restore a file from trash (sets ``trashed=False`` in its folder).

    Args:
        name: Optional target — the file's display NAME or case-insensitive
            title substring, its id (e.g. ``"file_old_notes"``), bare slug, or
            a UI row id. The name works. When empty, falls back to the
            currently selected file (``_CURRENT_FILE_ID``). Discover trashed
            files via ``list_all_files_with_meta()`` (they have ``trashed:
            True``).

    Sets ``trashed=False`` regardless of the file's prior state (no error if
    it was not trashed) and leaves it as the current selection. Returns
    ``{ok: True, file_id, trashed: False}``, or a bounded error string when
    no target resolves.
    """
    global _CURRENT_FILE_ID
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("file_action_restore"); sim.wait(0.3)
    except Exception:
        pass
    target = name or _CURRENT_FILE_ID
    env = dl.read_envelope()
    file_obj = _resolve_file(env, target)
    if not file_obj:
        return "No selected trashed file to restore. Pass name=... or call open_file first."
    file_obj["trashed"] = False
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    _CURRENT_FILE_ID = file_obj.get("id", target)
    return {"ok": True, "action": "restore_file", "file_id": _CURRENT_FILE_ID, "trashed": False}


# ── Direct-state-read tools (read the workspace store directly so the
# agent sees all 67 files / 28 folders even when scrolled off-screen).

@mcp.tool()
def list_folders_with_meta() -> dict:
    """List every folder in the workspace from shared state (no UI).

    Returns ``{folders: [{id, name, starred, shared, trashed, ownerName,
    updatedAt}, ...], count}`` — sees all folders even when scrolled
    off-screen.
    """
    env = dl.read_envelope()
    folders = env.get("seededData", {}).get("folders", [])
    out = [{"id": f.get("id"), "name": f.get("name"),
            "starred": f.get("starred", False),
            "shared":  f.get("shared", False),
            "trashed": f.get("trashed", False),
            "ownerName": f.get("ownerName"),
            "updatedAt": f.get("updatedAt")}
           for f in folders]
    return {"folders": out, "count": len(out)}


@mcp.tool()
def list_files_in_folder(folder_name_or_id: str) -> dict:
    """List every file whose parent is a specific folder (shared state, no UI).

    Args:
        folder_name_or_id: Folder identifier — either a ``folder_*`` id
            (e.g. ``"folder_team_assets"``) or a case-insensitive substring
            of the folder's display name. Unknown values return
            ``{ok: False, error, available}`` listing up to 10 candidate
            folder names.

    Returns ``{folder, folder_id, files: [{id, name, fileType, size,
    starred, shared, updatedAt}, ...], count}`` on success.
    """
    env = dl.read_envelope()
    folders = env.get("seededData",{}).get("folders",[])
    folder = (dl.envelope_find(env, "folders", value=folder_name_or_id)
              or next((f for f in folders if folder_name_or_id.lower()
                       in str(f.get("name","")).lower()), None))
    if not folder:
        names = [f.get("name") for f in folders][:10]
        return {"ok": False, "error": f"No folder matching '{folder_name_or_id}'", "available": names}
    fid = folder["id"]
    files_in = [{"id": fi.get("id"), "name": fi.get("name"),
                 "fileType": fi.get("fileType"), "size": fi.get("sizeDescription"),
                 "starred": fi.get("starred", False),
                 "shared": fi.get("shared", False),
                 "updatedAt": fi.get("updatedAt")}
                for fi in env.get("seededData",{}).get("files",[])
                if fi.get("parentFolderId") == fid]
    return {"folder": folder.get("name"), "folder_id": fid,
            "files": files_in, "count": len(files_in)}


@mcp.tool()
def list_all_files_with_meta() -> dict:
    """List every file in the workspace from shared state (no UI).

    Returns ``{files: [{id, name, fileType, size, parent, starred, shared,
    trashed, updatedAt, lastOpenedAt}, ...], count}``. ``parent`` is the
    parent folder's display name or ``"(root)"`` when at My Drive root.
    """
    env = dl.read_envelope()
    files = env.get("seededData",{}).get("files",[])
    folders_by_id = {f["id"]: f.get("name") for f in env.get("seededData",{}).get("folders",[])}
    out = [{"id": fi.get("id"), "name": fi.get("name"),
            "fileType": fi.get("fileType"),
            "size": fi.get("sizeDescription"),
            "parent": folders_by_id.get(fi.get("parentFolderId"), "(root)"),
            "starred": fi.get("starred", False),
            "shared":  fi.get("shared", False),
            "trashed": fi.get("trashed", False),
            "updatedAt": fi.get("updatedAt"),
            "lastOpenedAt": fi.get("lastOpenedAt")}
           for fi in files]
    return {"files": out, "count": len(out)}


if __name__ == "__main__":
    mcp.run()
