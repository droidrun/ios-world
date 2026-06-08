"""CloudDocs MCP — collaborative-document editor on the iOS simulator.

Bundle ID: ``com.iosworld.benchmark.clouddocs``.

ID conventions used by tools below:
* Document rows expose ``file_row_doc_<slug>`` where ``<slug>`` is the
  snake-case form of the **display title** (the app's ``stableSlug``:
  lowercase, runs of non-alphanumerics collapsed to a single ``_``).
  E.g. title "Mobile Launch Plan" -> row ``file_row_doc_mobile_launch_plan``.
  (``file_row_docs_<slug>`` / ``file_row_drive_<slug>`` are accepted only
  as legacy tap fallbacks; the current app emits ``file_row_doc_``.)
  Recents/shared/starred/trash variants reuse the suffix
  (``recent_row_doc_<slug>``, ``shared_row_doc_<slug>``, ...); search-
  result rows are ``search_file_doc_<slug>`` (NO ``_row_`` segment).
* Folder rows: ``folder_row_<slug>`` where ``<slug>`` is the folder
  name's ``stableSlug`` (e.g. "My Drive" -> ``folder_row_my_drive``).
* Document state is identified by the document's ``id`` (the seed ids are
  slug-based, e.g. ``file_doc_meeting_notes`` — NOT numbered like
  ``file_doc_001``; the id slug is the *original* seed name and need not
  match the current title slug) OR a case-insensitive substring of its
  display title (slugs with underscores also match, since matching strips
  non-alphanumerics). Both forms are accepted everywhere ``title_or_id``
  is taken. Prefer passing the human-readable title — do not invent an id.
* Edit-mode formatting toolbar (inside the open editor): bold/italic/
  underline are ``docs_format_bold_toggle`` / ``docs_format_italic_toggle``
  / ``docs_format_underline_toggle``; paragraph styles (heading, bullets)
  are ``docs_format_paragraph_<rawValue>`` (e.g.
  ``docs_format_paragraph_heading``). The ``toggle_*`` tools grade on
  shared state, so they do not depend on these ids being hit-testable.
* File actions (row context menu): ``file_action_rename``,
  ``file_action_duplicate``, ``file_action_move``, ``file_action_trash``,
  ``file_action_star``.

Discover titles/ids with ``list_documents_with_meta`` (state-sourced,
includes off-screen docs) or ``list_documents`` (on-screen rows only).
Many tools fall back to direct shared-state writes when the UI tap chain
fails; the benchmark grades end-state, so blind ``title_or_id`` calls
work without a prior ``open_document``.
"""

import sys, pathlib, copy
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("CloudDocs")

BUNDLE_ID = "com.iosworld.benchmark.clouddocs"
_CURRENT_DOCUMENT_ID = ""


def _slugify(value: str) -> str:
    """Snake-case a title the way the app builds ``file_row_doc_<slug>`` ids.

    Lowercases, replaces any run of non-alphanumeric chars with a single
    underscore, and strips leading/trailing underscores. ``"Mobile Launch
    Plan"`` -> ``"mobile_launch_plan"``; ``"Feature Spec — Draft"`` ->
    ``"feature_spec_draft"``.
    """
    import re as _re
    return _re.sub(r"[^a-z0-9]+", "_", str(value).lower()).strip("_")


def _create_document(env: dict, title: str) -> dict:
    """Create a brand-new document (and its browser file row) in shared state.

    Several real tasks ask the agent to *build* a NEW CloudDocs document
    (e.g. "Build a 'Life Dashboard'", "Create a master calendar") — there is
    no separate create tool, so the write tools must materialize the doc when
    the title resolves to nothing. Both the ``documents`` collection (editor
    body/blocks) and the ``files`` collection (home-browser row) get an entry
    sharing one ``file_doc_<slug>`` id, mirroring the seed shape exactly so
    the Swift Codable decoder (lenient ``try?`` + ``.iso8601`` dates) accepts
    it. Returns the new ``documents`` entry. The caller is responsible for
    writing/ reloading.
    """
    seeded = env.setdefault("seededData", {})
    documents = seeded.setdefault("documents", [])
    files = seeded.setdefault("files", [])

    title = (title or "Untitled document").strip() or "Untitled document"
    base_slug = _slugify(title) or "document"
    existing_ids = {str(d.get("id", "")) for d in documents} | {str(f.get("id", "")) for f in files}
    doc_id = f"file_doc_{base_slug}"
    n = 2
    while doc_id in existing_ids:
        doc_id = f"file_doc_{base_slug}_{n}"
        n += 1

    now = _now_iso()
    profile = seeded.get("profile") or {}
    owner = profile.get("displayName") or profile.get("name") or "You"
    root_folder = seeded.get("rootFolderId")

    document = {
        "id": doc_id,
        "title": title,
        "body": "",
        "formatting": {
            "paragraphStyle": "normal", "listStyle": "none", "alignment": "leading",
            "bold": False, "italic": False, "underline": False,
            "suggestionModeEnabled": False,
        },
        "blocks": [{"id": "block_1", "paragraphStyle": "title", "text": title}],
    }
    documents.append(document)

    files.append({
        "id": doc_id,
        "name": title,
        "fileType": "document",
        "parentFolderId": root_folder,
        "createdAt": now,
        "updatedAt": now,
        "starred": False,
        "trashed": False,
        "shared": False,
        "ownerName": owner,
        "accessRole": "editor",
        "sizeDescription": "1 KB",
        "permissions": [],
        "linkSettings": {"visibility": "restricted", "defaultRole": "editor", "copyCount": 0},
        "comments": [],
        "lastOpenedAt": now,
    })
    return document


def _now_iso() -> str:
    import datetime as _dt
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _dismiss_overlays(sim) -> None:
    """Back out of any search sheet / document detail so the home file
    browser re-renders its ``file_row_doc_*`` rows.

    The agent frequently leaves a DocsSearchSheet or a document-detail view
    on screen; a row tap then no-ops because the target row is covered or
    absent from the tree. Tap any visible dismiss affordance (search cancel,
    sheet xmark, nav back) a couple of times, then settle. Each tap is
    best-effort — missing controls are fine.
    """
    for _ in range(3):
        tree = ""
        try:
            tree = sim.observe_text()
        except Exception:
            pass
        # The DocsSearchSheet exposes a "Close" button; an open document
        # detail exposes docs_edit_button / a nav back chevron. The plain
        # home browser has none of these — nothing to dismiss.
        on_search = ("docs_search_field" in tree) or (
            'name="Close"' in tree and "Search in Docs" in tree)
        on_detail = ("docs_edit_button" in tree) or ("chevron.backward" in tree)
        if not on_search and not on_detail:
            return
        hit = False
        for did in ("Close", "docs_search_cancel", "Cancel", "docs_search_close",
                    "xmark", "docs_detail_back", "chevron.backward", "Back"):
            try:
                sim.tap_id(did); sim.wait(0.4); hit = True; break
            except Exception:
                continue
        if not hit:
            return


def _open_document_row(sim, doc: dict | None, name: str) -> bool:
    """Best-effort tap of the document's home-browser row.

    Tries the resolved doc's real title-slug first (the agent usually passes
    a display title, whose raw form never matches the snake-case row id),
    then the raw ``name`` and a couple of legacy prefixes. Verifies the tap
    actually navigated by confirming the detail-only ``docs_edit_button``
    renders afterwards — a bare WDA "success" that leaves the browser up is
    treated as a miss so callers don't over-claim a UI open.
    """
    candidates = []
    if doc and doc.get("title"):
        candidates.append(_slugify(doc["title"]))
    if doc and doc.get("id"):
        candidates.append(_slugify(str(doc["id"]).replace("file_doc_", "")))
    candidates.append(_slugify(name))
    candidates.append(name)
    seen = set()
    for slug in candidates:
        if not slug or slug in seen:
            continue
        seen.add(slug)
        for prefix in ("file_row_doc_", "file_row_docs_", "file_row_drive_"):
            try:
                sim.tap_id(f"{prefix}{slug}"); sim.wait(0.6)
            except Exception:
                continue
            try:
                if "docs_edit_button" in sim.observe_text():
                    return True
            except Exception:
                return True
    return False


def _find_document(env: dict, value: str) -> dict | None:
    return (
        dl.envelope_find(env, "documents", value=value)
        or dl.envelope_match(env, "documents", title_substring=value)
    )


def _find_file_for_document(env: dict, doc: dict | None) -> dict | None:
    if not doc:
        return None
    files = env.get("seededData", {}).get("files", [])
    doc_id = doc.get("id")
    title = str(doc.get("title", "")).lower()
    return (
        dl.envelope_find(env, "files", value=doc_id)
        or next((f for f in files if str(f.get("name", "")).lower() == title.lower()), None)
    )


def _current_document(env: dict) -> dict | None:
    return _find_document(env, _CURRENT_DOCUMENT_ID) if _CURRENT_DOCUMENT_ID else None


def _resolve_document(env: dict, title_or_id: Optional[str]) -> dict | None:
    """Resolve a document for a no-precondition (blind) tool call.

    If ``title_or_id`` is given, resolve it by id / case-insensitive title /
    slug substring AND latch it as the current document (so subsequent
    no-arg calls keep operating on it). Otherwise fall back to whatever
    document was previously opened via ``open_document``.

    This is what makes the document-action tools robust to the agent's
    real usage: a single blind ``star_file(title_or_id="Mobile Launch
    Plan")`` resolves and acts without a prior ``open_document`` step.
    """
    if title_or_id:
        # Explicit target: resolve it or fail. Do NOT silently fall back to a
        # previously-latched document — that would trash/edit the wrong file
        # and mask a genuinely-invalid target.
        return _set_current_document(env, title_or_id)
    return _current_document(env)


def _doc_not_found(env: dict, title_or_id: Optional[str], verb: str) -> dict:
    """Bounded controlled-failure envelope listing candidate titles."""
    titles = [d.get("title") for d in env.get("seededData", {}).get("documents", [])][:10]
    if title_or_id:
        msg = f"No document matching '{title_or_id}' to {verb}."
    else:
        msg = f"No selected document to {verb}. Pass title_or_id, or call open_document first."
    return {"ok": False, "action": verb, "message": msg, "available": titles}


def _set_current_document(env: dict, value: str) -> dict | None:
    global _CURRENT_DOCUMENT_ID
    doc = _find_document(env, value)
    if doc:
        _CURRENT_DOCUMENT_ID = doc.get("id", value)
    return doc


def _toggle_document_format(field: str, exc: Exception, true_value=True, false_value=False,
                            title_or_id: Optional[str] = None) -> dict | str:
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    if not doc:
        return _doc_not_found(env, title_or_id, f"toggle_{field}")
    formatting = doc.setdefault("formatting", {})
    current = formatting.get(field, false_value)
    formatting[field] = false_value if current == true_value else true_value
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "action": f"toggle_{field}",
        "doc_id": doc.get("id"),
        "title": doc.get("title"),
        field: formatting[field],
    }


def _apply_document_format(field: str, tap_id: str, true_value=True, false_value=False,
                           title_or_id: Optional[str] = None) -> dict | str:
    """Best-effort UI tap, then ALWAYS flip ``formatting.<field>`` in shared state.

    Unlike ``toggle_bold`` (whose toolbar button persists state on its own),
    the italic/underline/list/heading toolbar taps succeed at the WDA level
    (no exception is raised) but do NOT mutate the graded ``formatting`` map.
    A pure ``try: tap / except: state-write`` path therefore silently
    no-ops for these fields. This helper mirrors ``star_file``: tap for UI
    fidelity, then unconditionally write the state the benchmark grades.
    Requires a document to be selected (call ``open_document`` first).
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id(tap_id); sim.wait(0.3)
    except Exception:
        pass
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    if not doc:
        return _doc_not_found(env, title_or_id, f"toggle_{field}")
    formatting = doc.setdefault("formatting", {})
    current = formatting.get(field, false_value)
    formatting[field] = false_value if current == true_value else true_value
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "action": f"toggle_{field}",
        "doc_id": doc.get("id"),
        "title": doc.get("title"),
        field: formatting[field],
    }


@mcp.tool()
def launch() -> str:
    """Launch CloudDocs and return the post-launch accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched CloudDocs.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree as text (no navigation)."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="CloudDocs",
        markers=("doc_row_", "docs_", "document_", "editor_"),
    )


@mcp.tool()
def search_documents(query: str) -> dict:
    """Open the search sheet, type a query, and return matching document slugs.

    Args:
        query: Free-text substring matched against document titles
            (case-insensitive). Empty strings still type into the field.

    Self-navigates: taps ``docs_open_search_button`` to open the search
    sheet (no-op if already there), focuses ``docs_search_field``, types,
    and reads the tree.

    Returns ``{ok: True, query, documents: [slug, ...], count}``. ``ok`` is
    True whenever the search ran, even for zero matches (an empty list is an
    honest no-result, not an error). Each ``slug`` can be passed directly to
    ``open_document(name=<slug>)`` (or to any ``title_or_id`` arg). When UI
    rows are present the slug is the trailing part of a ``*_row_doc_<slug>``
    id; when no rows render it falls back to a shared-state title/id
    substring match and returns a title-derived slug. Either way the slug
    resolves back to the document, so do not hand-build ids from it.
    """
    import re
    sim = SimulatorBridge.get()
    # Home screen has a "Search in Docs" button that opens DocsSearchSheet
    # (where the actual `docs_search_field` lives). Tap the button first;
    # if we're already on the sheet, this is a no-op.
    for opener_id in ("docs_open_search_button", "Search in Docs"):
        try:
            sim.tap_id(opener_id); sim.wait(0.8); break
        except Exception:
            continue
    # Field auto-focuses on sheet open in iOS, but tap to be sure
    try:
        sim.tap_id("docs_search_field")
        sim.wait(0.5)
    except Exception:
        pass
    try:
        sim.type_text(query)
        sim.wait(0.6)
        tree = sim.observe_text()
    except Exception:
        tree = ""
    # Tree IDs use file_row_doc_<slug> (singular). Older variants keep working.
    slugs = sorted(set(
        re.findall(r'(?:file|recent|shared|starred|trash|search_file)_row_docs?_([^"\s]+)', tree)
        + re.findall(r'search_file_doc_([^"\s]+)', tree)
    ))
    if not slugs:
        env = dl.read_envelope()
        q = query.lower()
        slugs = sorted(
            (d.get("title", "").lower().replace(" ", "_").replace("-", "_"), d.get("id"))
            for d in env.get("seededData", {}).get("documents", [])
            if q in d.get("title", "").lower() or q in d.get("id", "").lower()
        )
        docs = [slug for slug, _id in slugs]
    else:
        docs = slugs
    # Report an explicit ok so the agent gets a clear success signal instead
    # of an absent flag (which a prior run mis-read as a failure and looped
    # on). ok:true whenever the search ran, regardless of match count; a
    # zero-result search is an honest empty list, not an error.
    return {"ok": True, "query": query, "documents": docs, "count": len(docs)}


@mcp.tool()
def open_document(name: str) -> str:
    """Open a document and mark it as the current document.

    Args:
        name: Identifies the document. Any of the following resolve:
            - the display **TITLE** (a case-insensitive substring is enough,
              e.g. ``"Mobile Launch Plan"``) — recommended, since this is the
              value you usually already have and it resolves robustly;
            - the document **id** (slug-based, e.g.
              ``"file_doc_meeting_notes"`` — NOT numbered like
              ``file_doc_001``);
            - the trailing **row slug** from ``file_row_doc_<slug>`` (e.g.
              ``"mobile_launch_plan"``); the bare slug also resolves because
              matching strips non-alphanumerics.
            Resolution is against the seeded documents by id or title
            substring, then the current document is latched in shared state.
            The function also taps the matching row (canonical
            ``file_row_doc_`` prefix plus legacy ``file_row_docs_`` /
            ``file_row_drive_`` fallbacks); if no row taps it still selects
            the document via shared state and returns ``opened_via:
            "shared_state"`` (edit/format tools then operate correctly — do
            NOT call open_document again).

    Returns ``ok: False`` with up to 10 candidate titles in ``available``
    when ``name`` matches no document. Use ``list_documents_with_meta`` (all
    docs) or ``list_documents`` (on-screen rows) to discover titles.
    """
    global _CURRENT_DOCUMENT_ID
    sim = SimulatorBridge.get()
    env = dl.read_envelope()
    doc = _set_current_document(env, name)
    if not doc:
        titles = [d.get("title") for d in env.get("seededData", {}).get("documents", [])][:10]
        return {
            "ok": False, "action": "open_document",
            "message": f"No document matching '{name}'. Call list_documents to see available titles/slugs.",
            "available": titles,
        }
    _CURRENT_DOCUMENT_ID = doc.get("id", name)
    # Dismiss any search sheet / lingering detail so the home browser rows
    # re-render and are tappable, THEN tap the resolved row by its real slug.
    _dismiss_overlays(sim)
    opened = _open_document_row(sim, doc, name)
    if opened:
        ui = sim.observe_text()
        return f"Opened document '{doc.get('title')}'.\n\n{ui}"
    # Row tap didn't navigate (e.g. doc is in a folder/recents not on the
    # current browser screen). The document is still latched in shared state,
    # so the state-graded edit/format tools operate on it correctly.
    return {
        "ok": True, "action": "open_document",
        "doc_id": doc.get("id"), "title": doc.get("title"),
        "opened_via": "shared_state",
        "message": (
            f"Document '{doc.get('title')}' selected via shared state. UI may "
            "still show the file browser — edit/format tools will operate on "
            "the selected document directly. Do NOT call open_document again."
        ),
    }


@mcp.tool()
def edit_document(title_or_id: Optional[str] = None) -> str:
    """Enter edit mode on a document (taps ``docs_edit_button``).

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, edits the document last opened via
            ``open_document``. Passing it self-resolves and selects the
            document so a single blind call works.

    Falls back to confirming the selected document via shared state when the
    edit button is not present.
    """
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    sim = SimulatorBridge.get()
    if not title_or_id:
        try:
            ui = sim.tap_and_observe("docs_edit_button")
            return f"Entered edit mode.\n\n{ui}"
        except Exception:
            pass
    if not doc:
        return _doc_not_found(env, title_or_id, "edit_document")
    return {"ok": True, "action": "edit_document", "doc_id": doc.get("id"), "title": doc.get("title"), "message": "Document is selected; use append_to_document or set_document_body for text edits."}


@mcp.tool()
def toggle_bold(title_or_id: Optional[str] = None) -> str:
    """Toggle bold formatting on a document.

    Args:
        title_or_id: Optional document to target — the ``file_doc_*`` id,
            a case-insensitive title substring, or a row slug (e.g.
            ``"Mobile Launch Plan"`` / ``"mobile_launch_plan"`` /
            ``"file_doc_meeting_notes"``). When omitted, operates on the
            document last opened via ``open_document``. Passing it lets a
            single blind call resolve the target itself.

    Flips ``formatting.bold`` in shared state (the graded field).
    """
    # When a target is named explicitly, the doc is not guaranteed to be the
    # one rendered in the UI, so skip the toolbar tap and write graded state
    # for the resolved document directly.
    if title_or_id:
        return _toggle_document_format("bold", Exception("explicit target"), title_or_id=title_or_id)
    sim = SimulatorBridge.get()
    try:
        ui = sim.tap_and_observe("docs_format_bold_toggle")
        return f"Toggled bold.\n\n{ui}"
    except Exception as exc:
        return _toggle_document_format("bold", exc)


@mcp.tool()
def toggle_italic(title_or_id: Optional[str] = None) -> str:
    """Toggle italic formatting on a document.

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, operates on the document last opened via
            ``open_document``. Passing it lets a single blind call resolve
            the target itself.

    Taps the toolbar button for UI fidelity, then flips
    ``formatting.italic`` in shared state (the graded field).
    """
    return _apply_document_format("italic", "docs_format_italic_toggle", title_or_id=title_or_id)


@mcp.tool()
def toggle_underline(title_or_id: Optional[str] = None) -> str:
    """Toggle underline formatting on a document.

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, operates on the document last opened via
            ``open_document``. Passing it lets a single blind call resolve
            the target itself.

    Taps the toolbar button for UI fidelity, then flips
    ``formatting.underline`` in shared state (the graded field).
    """
    return _apply_document_format("underline", "docs_format_underline_toggle", title_or_id=title_or_id)


@mcp.tool()
def open_folder(name: str) -> str:
    """Open / resolve a folder by name, id, or row slug.

    Args:
        name: The folder's display **name** (case-insensitive substring,
            e.g. ``"Research"``), its **id** (e.g. ``"folder_research"``),
            or the trailing slug from ``folder_row_<slug>`` (e.g.
            ``"research"``; the tool also tries ``folder_<name>``). The
            human-readable name is the easiest form. Use ``observe()`` to
            see ``folder_row_*`` ids.

    Best-effort taps ``folder_row_<name>`` (no-op in the browser-only UI),
    then resolves the folder in shared workspace state. Returns
    ``{ok: True, folder_id, name}`` on a match, or ``{ok: False, ...,
    available: [...]}`` listing up to 10 folder names when nothing matches.
    """
    sim = SimulatorBridge.get()
    # Best-effort UI tap (no-ops in the browser-only UI). Resolve the folder in
    # the shared workspace state so we can confirm it exists even when the row
    # isn't tappable; the cloud apps are graded on state, not the UI tree.
    try:
        sim.tap_id(f"folder_row_{name}"); sim.wait(0.4)
    except Exception:
        pass
    env = dl.read_envelope()
    folders = env.get("seededData", {}).get("folders", [])
    folder = (
        dl.envelope_find(env, "folders", value=name)
        or dl.envelope_find(env, "folders", value=f"folder_{name}")
        or next((f for f in folders if name.lower() in str(f.get("name", "")).lower()), None)
    )
    if not folder:
        names = [f.get("name") for f in folders][:10]
        return {"ok": False, "action": "open_folder", "message": f"No folder matching '{name}'.", "available": names}
    return {"ok": True, "action": "open_folder", "folder_id": folder.get("id"), "name": folder.get("name")}


@mcp.tool()
def rename_file(new_title: Optional[str] = None, title_or_id: Optional[str] = None) -> str:
    """Rename a file/document.

    Args:
        new_title: New display title to apply. When provided, the document
            (and its ``files`` metadata row) is renamed in shared state and
            the change is graded. When omitted, only the rename sheet is
            triggered (legacy behaviour, awaits user input).
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, renames the document last opened via
            ``open_document``. Passing it self-resolves the target so a
            single blind call works.
    """
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("file_action_rename"); sim.wait(0.3)
    except Exception:
        pass
    if not doc:
        return _doc_not_found(env, title_or_id, "rename_file")
    if not new_title:
        return {"ok": True, "action": "rename_file", "doc_id": doc.get("id"),
                "title": doc.get("title"),
                "message": "Rename action triggered for the selected document; pass new_title to apply a rename."}
    old_title = doc.get("title")
    doc["title"] = new_title
    file_obj = _find_file_for_document(env, doc)
    if file_obj is None:
        # match by the OLD title too, since _find_file_for_document looks at the (now-changed) title
        files = env.get("seededData", {}).get("files", [])
        file_obj = next((f for f in files if str(f.get("name", "")).lower() == str(old_title).lower()), None)
    if file_obj:
        file_obj["name"] = new_title
        file_obj["updatedAt"] = "2026-05-12T00:00:00Z"
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "rename_file", "doc_id": doc.get("id"),
            "old_title": old_title, "title": new_title}


@mcp.tool()
def view_recent() -> str:
    """Return the current UI tree (used as a passthrough to view recents)."""
    sim = SimulatorBridge.get()
    ui = sim.observe_text()
    return f"Recent documents view.\n\n{ui}"


@mcp.tool()
def list_documents() -> dict:
    """Scan the current UI tree and return visible document row slugs.

    Returns ``{documents: [slug, ...], count: int}`` extracted from the
    ``*_row_doc_<slug>`` rows in the tree (``file_row_doc_`` /
    ``recent_row_doc_`` / ``shared_row_doc_`` / ``starred_row_doc_`` /
    ``trash_row_doc_``). Reflects only what is on-screen, so it can be empty
    or partial depending on the current view (search-result rows use a
    different ``search_file_doc_`` shape and are not captured here). For a
    complete, view-independent list use ``list_documents_with_meta``.
    """
    import re
    sim = SimulatorBridge.get()
    tree = sim.observe_text()
    slugs = sorted(set(
        re.findall(r'(?:file|recent|shared|starred|trash|search_file)_row_docs?_([^"\s]+)', tree)
        + re.findall(r'search_file_doc_([^"\s]+)', tree)
    ))
    return {"documents": slugs, "count": len(slugs)}


@mcp.tool()
def toggle_bullets(title_or_id: Optional[str] = None) -> str:
    """Toggle bullet-list paragraph style on a document.

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug (see module docstring). When omitted, operates on the
            document last opened via ``open_document``. Passing it lets a
            single blind call resolve the target itself.

    Flips ``formatting.listStyle`` between ``"bullets"`` and ``"none"`` in
    shared state — the graded field — and relaunches the app so it renders.
    A best-effort toolbar tap is attempted first but is not required for
    correctness (the real editor exposes this as
    ``docs_format_paragraph_bullets``, only when a document is open in the
    editor; the state write is authoritative either way).

    Uses the app's exact ``DocumentListStyle`` raw value ``"bullets"``
    (the Swift enum is ``String``-backed with cases ``none`` / ``bullets``
    / ``numbered``). Any other spelling (``"bullet"`` / ``"bulleted"``)
    fails the app's Codable decode on launch and silently resets to
    ``.none``, which is why an earlier value never persisted.
    """
    return _apply_document_format("listStyle", "docs_toolbar_bullets",
                                  true_value="bullets", false_value="none",
                                  title_or_id=title_or_id)


@mcp.tool()
def toggle_heading(title_or_id: Optional[str] = None) -> str:
    """Toggle heading paragraph style on a document.

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug (see module docstring). When omitted, operates on the
            document last opened via ``open_document``. Passing it lets a
            single blind call resolve the target itself.

    Flips ``formatting.paragraphStyle`` between ``"heading"`` and
    ``"normal"`` in shared state (the graded field) and relaunches the app.
    A best-effort toolbar tap is attempted first but is not required (the
    real editor exposes this as ``docs_format_paragraph_heading``, only when
    a document is open in the editor; the state write is authoritative).
    """
    return _apply_document_format("paragraphStyle", "docs_toolbar_heading",
                                  true_value="heading", false_value="normal",
                                  title_or_id=title_or_id)


@mcp.tool()
def duplicate_file(title_or_id: Optional[str] = None) -> str:
    """Duplicate a file/document.

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, duplicates the document last opened via
            ``open_document``. Passing it self-resolves the target so a
            single blind call works.

    Best-effort UI tap, then ALWAYS writes a shared-state copy titled
    ``"<original> Copy"`` (plus a matching ``files`` row) — the toolbar tap
    does not durably create the copy, so the state write is what the
    benchmark grades. The new document becomes the current selection.
    """
    global _CURRENT_DOCUMENT_ID
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("file_action_duplicate"); sim.wait(0.3)
    except Exception:
        pass
    if not doc:
        return _doc_not_found(env, title_or_id, "duplicate_file")
    documents = env.setdefault("seededData", {}).setdefault("documents", [])
    files = env.setdefault("seededData", {}).setdefault("files", [])
    new_doc = copy.deepcopy(doc)
    new_doc["id"] = f"{doc.get('id')}_copy_{len(documents) + 1}"
    new_doc["title"] = f"{doc.get('title', 'Untitled')} Copy"
    documents.append(new_doc)
    file_obj = _find_file_for_document(env, doc)
    if file_obj:
        new_file = copy.deepcopy(file_obj)
        new_file["id"] = new_doc["id"]
        new_file["name"] = new_doc["title"]
        new_file["createdAt"] = "2026-05-12T00:00:00Z"
        new_file["updatedAt"] = "2026-05-12T00:00:00Z"
        files.append(new_file)
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    _CURRENT_DOCUMENT_ID = new_doc["id"]
    return {"ok": True, "action": "duplicate_file", "source_doc_id": doc.get("id"), "doc_id": new_doc["id"], "title": new_doc["title"]}


@mcp.tool()
def move_file(destination: Optional[str] = None, title_or_id: Optional[str] = None) -> str:
    """Move a file/document into a destination folder.

    Args:
        destination: Folder to move the file into — a ``folder_*`` id, a
            case-insensitive folder-name substring, or a row slug (e.g.
            ``"Research"`` / ``"folder_research"``). When provided, the
            file's ``parentFolderId`` is updated in shared state and graded.
            When omitted, only the move sheet is opened (awaits user input).
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, moves the document last opened via
            ``open_document``. Passing it self-resolves the target.
    """
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("file_action_move"); sim.wait(0.4)
    except Exception:
        pass
    if not doc:
        return _doc_not_found(env, title_or_id, "move_file")
    if not destination:
        return {"ok": True, "action": "move_file", "doc_id": doc.get("id"), "title": doc.get("title"),
                "message": "Move sheet opened; pass destination (folder name/id) to apply the move."}
    folders = env.get("seededData", {}).get("folders", [])
    folder = (
        dl.envelope_find(env, "folders", value=destination)
        or dl.envelope_find(env, "folders", value=f"folder_{destination}")
        or next((f for f in folders if destination.lower() in str(f.get("name", "")).lower()), None)
    )
    if not folder:
        names = [f.get("name") for f in folders][:10]
        return {"ok": False, "action": "move_file", "message": f"No destination folder matching '{destination}'.", "available": names}
    file_obj = _find_file_for_document(env, doc)
    if not file_obj:
        return {"ok": False, "action": "move_file", "message": f"No file record for document '{doc.get('title')}'."}
    file_obj["parentFolderId"] = folder.get("id")
    file_obj["updatedAt"] = "2026-05-12T00:00:00Z"
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "move_file", "doc_id": doc.get("id"), "title": doc.get("title"),
            "destination_folder_id": folder.get("id"), "destination": folder.get("name")}


def _trash_file_fill_form(title_or_id: Optional[str] = None) -> Optional[str]:
    """Verify a document is resolvable so trash_file has a defined target.

    Returns None on success or a precondition message on failure. Used by
    both ``trash_file`` (one-shot commit) and ``prepare_trash_file``
    (capture-only). Stops short of tapping ``file_action_trash`` so the
    caller decides whether to commit. Resolves (and latches) ``title_or_id``
    when given so a blind prepare/confirm pair works without open_document.
    """
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    if not doc:
        return ("No selected document to trash. Pass title_or_id, or call "
                "open_document first.")
    return None


def _capture_trash_file_context() -> dict:
    """Snapshot the document that would be trashed."""
    env = dl.read_envelope()
    doc = _current_document(env) or {}
    file_obj = _find_file_for_document(env, doc) or {}
    return {
        "doc_id": doc.get("id"),
        "title": doc.get("title"),
        "file_id": file_obj.get("id"),
        "name": file_obj.get("name"),
    }


@mcp.tool()
def trash_file(title_or_id: Optional[str] = None) -> str:
    """Trash a document (one-shot commit).

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, trashes the document last opened via
            ``open_document``. Passing it self-resolves the target so a
            single blind call works.

    Taps ``file_action_trash``; falls back to marking ``trashed=True`` in
    shared state. Prefer ``prepare_trash_file`` + ``confirm_trash_file``
    for new code — that pair lets a model see which document will be
    trashed before committing.
    """
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    sim = SimulatorBridge.get()
    # Best-effort UI tap (the file_action_trash button only exists inside a
    # row's context menu, so it usually isn't hit-testable from the current
    # screen). Like star_file / the format toggles, a "successful" WDA tap
    # does NOT durably flip the graded ``trashed`` flag, so we must ALWAYS
    # write shared state afterwards rather than returning on a bare tap.
    try:
        sim.tap_id("file_action_trash"); sim.wait(0.3)
    except Exception:
        pass
    if not doc:
        return _doc_not_found(env, title_or_id, "trash_file")
    doc["trashed"] = True
    file_obj = _find_file_for_document(env, doc)
    if file_obj:
        file_obj["trashed"] = True
        file_obj["updatedAt"] = "2026-05-12T00:00:00Z"
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "trash_file", "doc_id": doc.get("id"), "trashed": True}


@mcp.tool()
def prepare_trash_file(title_or_id: Optional[str] = None) -> dict:
    """Stage a trash operation on a document WITHOUT committing.

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, stages the document last opened via
            ``open_document``. Passing it self-resolves the target so a
            blind prepare/confirm pair works.

    Captures a summary (``doc_id``, ``title``, ``file_id``, ``name``)
    of the document that would be moved to trash.

    On success returns ``{ok: True, action: "prepare_trash_file",
    draft_id, summary}``. Pass the ``draft_id`` to ``confirm_trash_file``
    to commit. Drafts expire after the ``IOSWORLD_DRAFT_TTL_SECONDS``
    TTL (default 10 minutes).

    On precondition failure returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _trash_file_fill_form(title_or_id)
    if err:
        return {"ok": False, "action": "prepare_trash_file", "message": err}
    summary = _capture_trash_file_context()
    draft_id = ts.create_draft("clouddocs", "trash_file", summary)
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
    # Best-effort UI tap (usually a no-op that does NOT durably flip the
    # graded ``trashed`` flag), then ALWAYS write shared state. Resolve the
    # document from the draft payload so this works even in a fresh process
    # where the in-memory current-document is lost.
    try:
        sim.tap_id("file_action_trash"); sim.wait(0.3)
    except Exception:
        pass
    env = dl.read_envelope()
    target = payload.get("doc_id") or payload.get("title")
    doc = _find_document(env, target) if target else _current_document(env)
    if not doc:
        return {
            "ok": False,
            "action": "confirm_trash_file",
            "message": f"Selected document for draft '{draft_id}' missing in shared state.",
        }
    doc["trashed"] = True
    file_obj = _find_file_for_document(env, doc)
    if file_obj:
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
def star_file(title_or_id: Optional[str] = None) -> str:
    """Toggle the starred (favorite) flag on a file/document.

    Args:
        title_or_id: Optional document to target — id, title substring, or
            row slug. When omitted, stars the document last opened via
            ``open_document``. Passing it self-resolves the target so a
            single blind call works.

    Taps ``file_action_star``, then flips the ``starred`` field in shared
    state (the graded field) on the file-metadata record (or the document
    itself when no file row exists).
    """
    env = dl.read_envelope()
    doc = _resolve_document(env, title_or_id)
    sim = SimulatorBridge.get()
    # Best-effort UI tap (no-ops in the browser-only UI), then toggle the
    # ``starred`` flag in shared state so the end-state changes.
    try:
        sim.tap_id("file_action_star"); sim.wait(0.3)
    except Exception:
        pass
    if not doc:
        return _doc_not_found(env, title_or_id, "star_file")
    # Prefer the file-metadata record when one exists (keeps Drive/Docs in
    # sync); otherwise store the flag on the document itself — CloudDocs
    # documents are a distinct collection from Drive ``files``.
    file_obj = _find_file_for_document(env, doc)
    target = file_obj if file_obj else doc
    target["starred"] = not bool(target.get("starred", False))
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "star_file", "doc_id": doc.get("id"), "starred": target["starred"]}


# ── Direct-state-write tools (bypass UI for cases where the editor's
# UI doesn't have stable accessibility IDs for typing into the document
# body). These mutate the shared workspace_envelope.json directly and
# trigger an app reload so the view re-renders. The benchmark grades
# end-state, so these are equivalent to manually typing.

@mcp.tool()
def append_to_document(title_or_id: str = "", text: str = "", body: str = "",
                       title: str = "") -> dict:
    """Append a paragraph block to a document directly in shared state (no UI).

    Args:
        title_or_id: Document identifier — either the ``file_doc_*`` id
            (slug-based, e.g. ``"file_doc_meeting_notes"``) or a
            case-insensitive substring of its display title (e.g.
            ``"Mobile Launch Plan"`` — the easiest form). Resolution is the
            same title/slug/id-accepting match ``open_document`` uses, so any
            visible title resolves. If the title matches NO existing document
            (e.g. you are *building* a new doc like ``"Life Dashboard"``), a
            new document with that exact title is created and the text is
            appended into it (response has ``created: true``).
        text: Free-text paragraph to append. Empty strings still create
            an empty block. Also concatenated onto the legacy ``body``
            string if present.
        body: Compatibility alias for ``text``. Some model calls use
            ``body`` for document writes; accept it instead of failing
            schema validation before the tool can recover.
        title: Compatibility alias for ``title_or_id``. Some model calls use
            ``title`` when creating/appending a document.

    The app is relaunched after the write so the new content is visible.
    Intended for cases where the editor lacks a stable text-input id.
    """
    if not text and body:
        text = body
    if not title_or_id and title:
        title_or_id = title
    env = dl.read_envelope()
    doc = _find_document(env, title_or_id) if title_or_id else _current_document(env)
    created = False
    if not doc:
        if not title_or_id:
            return _doc_not_found(env, title_or_id, "append_to_document")
        # No existing document matches. The agent is building a NEW document
        # (e.g. "Build a 'Life Dashboard'") — there is no separate create tool,
        # so materialize it and append into it. Real state effect, no false ok.
        doc = _create_document(env, title_or_id)
        created = True
    blocks = doc.setdefault("blocks", [])
    blocks.append({"id": f"block_{len(blocks)+1}",
                   "paragraphStyle": "normal", "text": text})
    if "body" in doc and isinstance(doc["body"], str):
        doc["body"] = (doc["body"] + "\n" + text).strip()
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    verb = "Created and appended" if created else "Appended"
    return {"ok": True, "doc_id": doc["id"], "title": doc.get("title"),
            "block_count": len(blocks), "created": created,
            "message": f"{verb} {len(text)} chars to '{doc.get('title')}'."}


@mcp.tool()
def set_document_body(title_or_id: str = "", body: str = "", title: str = "",
                      text: str = "", content: str = "") -> dict:
    """Replace a document's entire body directly in shared state (no UI).

    Args:
        title_or_id: Document identifier — either the ``file_doc_*`` id
            (slug-based, e.g. ``"file_doc_meeting_notes"``) or a
            case-insensitive substring of its display title (the easiest
            form), resolved the same way ``open_document`` resolves. If the
            title matches NO existing document, a new document with that exact
            title is created and given this body (response has
            ``created: true``).
        body: New body text. Replaces all existing blocks with a title
            block plus one normal-paragraph block containing ``body``.
            Also written to the legacy ``body`` string.
        title: Compatibility alias for ``title_or_id``.
        text: Compatibility alias for ``body``.
        content: Compatibility alias for ``body``.

    The app is relaunched after the write so the new content is visible.
    """
    if not title_or_id and title:
        title_or_id = title
    if not body:
        body = text or content
    env = dl.read_envelope()
    doc = _find_document(env, title_or_id) if title_or_id else _current_document(env)
    created = False
    if not doc:
        if not title_or_id:
            return _doc_not_found(env, title_or_id, "set_document_body")
        # Build a NEW document when nothing matches (no separate create tool).
        doc = _create_document(env, title_or_id)
        created = True
    title = doc.get("title", "")
    doc["blocks"] = [
        {"id": "block_1", "paragraphStyle": "title", "text": title},
        {"id": "block_2", "paragraphStyle": "normal", "text": body},
    ]
    doc["body"] = body
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    verb = "Created with body" if created else "Replaced body of"
    return {"ok": True, "doc_id": doc["id"], "title": title, "created": created,
            "message": f"{verb} '{title}' ({len(body)} chars)."}


@mcp.tool()
def list_documents_with_meta() -> dict:
    """List every CloudDocs document with id, title, body length, and block count.

    Sourced from the workspace envelope rather than the UI tree, so it
    includes documents not currently rendered on-screen.

    Returns ``{documents: [{id, title, body_len, block_count}, ...], count}``.
    """
    env = dl.read_envelope()
    out = [{"id": d.get("id"), "title": d.get("title"),
            "body_len": len(d.get("body","") or ""),
            "block_count": len(d.get("blocks",[]) or [])}
           for d in env.get("seededData",{}).get("documents",[])]
    return {"documents": out, "count": len(out)}


if __name__ == "__main__":
    mcp.run()
