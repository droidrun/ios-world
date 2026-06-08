"""CloudSlides MCP — Keynote-style presentation editor with slide CRUD and metadata.

Bundle: com.iosworld.benchmark.cloudslides

ID conventions:
  Presentation store ids:  file_slides_<slug>  (e.g. file_slides_superintelligence).
                           The <slug> is the AUTHOR's slug, NOT the title — it may
                           differ from the title (id file_slides_superintelligence
                           has title "[Draft] Autonomous Agents").
  Presentation rows:  file_row_slides_<slug>  (also recent_/shared_/starred_/trash_/search_file_)
  Slide thumbnails:   slides_thumbnail_<index>  (0-based)
  Slide editor:       slides_slide_title_field, slides_slide_body_field
  Toolbar:            slides_add_slide_button, slides_duplicate_slide_button,
                      slides_delete_slide_button, slides_edit_button, slides_title_field
  Search:             slides_search_field

How to reference a presentation: every tool that takes a presentation handle
resolves it through one shared resolver that accepts, in order: the exact store
id (file_slides_<slug>), the exact display TITLE, the bare id-suffix slug
(superintelligence), the title slug (conference_practice_deck), or a
case-insensitive TITLE SUBSTRING. The human-readable title (or a substring of it)
is the most reliable handle — you do NOT need to guess a slug. If a slug substring
matches more than one deck the resolver returns no match rather than guess; a title
substring, however, returns the first title match, so prefer a unique substring.
"""

import sys, pathlib
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("CloudSlides")

BUNDLE_ID = "com.iosworld.benchmark.cloudslides"
_CURRENT_PRESENTATION_ID = ""
_CURRENT_SLIDE_INDEX = 0


def _slug(value: str) -> str:
    return (
        value.lower()
        .replace("[", "")
        .replace("]", "")
        .replace("-", "_")
        .replace(" ", "_")
    )


def _id_suffix(pres_id: str) -> str:
    """Slug after the ``file_slides_`` prefix (e.g. file_slides_athena_pitch
    -> athena_pitch). Falls back to the full id when the prefix is absent."""
    pid = pres_id or ""
    for prefix in ("file_slides_", "file_pres_", "file_row_slides_"):
        if pid.startswith(prefix):
            return pid[len(prefix):]
    return pid


def _find_presentation(env: dict, value: str) -> dict | None:
    """Resolve a presentation from a BLIND agent argument.

    Accepts, in priority order: exact id/title, the file_slides_<slug> id,
    the bare id-suffix slug (``athena_pitch``), the title slug
    (``conference_practice_deck`` / ``file_row_slides_...`` suffix), and
    finally a case-insensitive substring of the title. This is the single
    resolver every slide-editing tool relies on, so it must tolerate every
    handle an agent could plausibly read off the UI or from
    list_presentations_with_meta.
    """
    target = (value or "").strip()
    if not target:
        return None
    target_slug = _slug(target)
    presentations = env.get("seededData", {}).get("presentations", [])
    # 1. exact id / title / slugged-id / slugged-title / id-suffix slug
    for pres in presentations:
        pid = pres.get("id", "")
        title = pres.get("title", "")
        if target in {pid, title}:
            return pres
        if target_slug in {
            _slug(pid),
            _slug(title),
            _slug(_id_suffix(pid)),
        }:
            return pres
    # 2. envelope title-substring helper
    hit = dl.envelope_match(env, "presentations", title_substring=target)
    if hit:
        return hit
    # 3. fuzzy substring on slugs (handles partial id-suffix or title slugs).
    #    If more than one presentation matches the same stem the handle is
    #    ambiguous and a blind edit/delete could hit the wrong deck, so bail
    #    out with None rather than silently returning the first sibling.
    fuzzy_hits = []
    for pres in presentations:
        pid = pres.get("id", "")
        candidates = {
            _slug(pid),
            _slug(pres.get("title", "")),
            _slug(_id_suffix(pid)),
        }
        if any(target_slug and target_slug in c for c in candidates):
            fuzzy_hits.append(pres)
            continue
        if any(c and c in target_slug for c in candidates):
            fuzzy_hits.append(pres)
    if len(fuzzy_hits) == 1:
        return fuzzy_hits[0]
    return None


@mcp.tool()
def launch() -> str:
    """Launch CloudSlides and return the initial UI tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched CloudSlides.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (no taps)."""
    sim = SimulatorBridge.get()
    return ts.observe_app_scoped(
        sim,
        bundle_id=BUNDLE_ID,
        app_name="CloudSlides",
        markers=("slides_search_field", "file_row_slides_", "slides_thumbnail_"),
    )


@mcp.tool()
def search_presentations(query: str) -> dict:
    """Search presentations by name and return matching slugs.

    Self-navigates: taps ``slides_search_field`` and types the query, then
    parses the file rows. If the live UI has no matching rows it falls back to
    the shared workspace store, so it returns the real matches either way.

    Args:
        query: Free-text substring matched against presentation titles and
            ids. Case-insensitive. Empty string returns no matches.

    Returns:
        ``{query, presentations: [<slug>...], count}``. Each slug resolves with
        ``open_presentation`` / ``set_slide_text`` (UI rows give the row slug;
        the store fallback gives the title slug). You may also pass the
        human-readable TITLE straight to those tools instead of a slug.
    """
    import re as _re
    sim = SimulatorBridge.get()
    try:
        sim.tap_id('slides_search_field')
        sim.wait(0.3)
    except Exception:
        pass
    try:
        sim.type_text(query)
        sim.wait(0.5)
        tree = sim.observe_text() or ""
    except Exception:
        tree = ""
    slugs = sorted(set(_re.findall(r'(?:file|recent|shared|starred|trash|search_file)_row_slides_([^"\s]+)', tree)))
    if not slugs:
        env = dl.read_envelope()
        q = query.lower()
        slugs = sorted(
            p.get("title", "").lower().replace(" ", "_").replace("-", "_")
            for p in env.get("seededData", {}).get("presentations", [])
            if q in p.get("title", "").lower() or q in p.get("id", "").lower()
        )
    return {"query": query, "presentations": slugs, "count": len(slugs)}


@mcp.tool()
def open_presentation(name: str) -> str:
    """Open a presentation and mark it as the current deck.

    Works from any screen — self-navigates: resolves the deck from shared state
    first, taps its row if visible, otherwise selects it via shared state and
    reloads so slide-editing tools still operate on it.

    Args:
        name: Any presentation handle — the display TITLE (e.g.
            ``[Draft] Autonomous Agents``) or a unique substring of it, the
            store id ``file_slides_<slug>``, the bare id-suffix slug, or a
            title slug. Titles are accepted directly (not just as a fallback);
            you do NOT need to guess a slug. Slugs come from
            ``list_presentations`` / ``list_presentations_with_meta`` /
            ``search_presentations``.

    Returns ``{ok: False, opened: False, ...}`` if the handle matches no deck.
    Precondition: app launched.
    """
    global _CURRENT_PRESENTATION_ID, _CURRENT_SLIDE_INDEX
    sim = SimulatorBridge.get()
    # Resolve the canonical presentation up front so a BLIND title / id-suffix /
    # substring argument is handled the same whether or not the row is visible.
    env = dl.read_envelope()
    pres = _find_presentation(env, name)
    if not pres:
        return {"ok": False, "action": "open_presentation", "opened": False,
                "message": f"Presentation '{name}' is not available in the workspace."}
    canonical_id = pres.get("id", name)
    title = pres.get("title", "")
    # Candidate row ids to tap, derived from the resolved presentation rather
    # than the raw (possibly fuzzy) argument.
    row_slugs = []
    for cand in (_slug(title), _slug(_id_suffix(canonical_id)), _slug(name)):
        if cand and cand not in row_slugs:
            row_slugs.append(cand)
    for slug in row_slugs:
        for prefix in ("file_row_slides_", "recent_row_slides_", "shared_row_slides_",
                       "starred_row_slides_", "search_file_row_slides_"):
            try:
                ui = sim.tap_and_observe(f"{prefix}{slug}")
                _CURRENT_PRESENTATION_ID = canonical_id
                _CURRENT_SLIDE_INDEX = 0
                return f"Opened presentation '{title or name}'.\n\n{ui}"
            except Exception:
                continue
    # Row not on screen: select via shared state (slide-edit tools operate on it).
    _CURRENT_PRESENTATION_ID = canonical_id
    _CURRENT_SLIDE_INDEX = 0
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True, "action": "open_presentation",
        "presentation_id": _CURRENT_PRESENTATION_ID,
        "title": title,
        "opened_via": "shared_state",
        "message": (
            f"Presentation '{title}' selected via shared state. UI "
            "may still show the file browser — slide-editing tools will operate "
            "on the selected presentation directly. Do NOT call open_presentation again."
        ),
    }


@mcp.tool()
def add_slide() -> str:
    """Append a new blank slide ("Untitled Slide") to the open presentation.

    Commits directly to shared state (no UI tap) and reloads. New slide has
    title ``Untitled Slide``, empty body, layout ``titleBody``, appended last;
    returns ``{ok: True, slide_id, slide_count, new_slide_index}`` where
    ``new_slide_index`` is the 0-based index of the slide just added (pass it to
    ``navigate_to_slide`` then ``set_slide_title``/``set_slide_body`` to fill it
    in).

    Precondition: a presentation must be open (call ``open_presentation``
    first), else returns a plain "No open presentation" message. To create a
    slide WITH content in one call, or to target a deck by name without opening
    it, use ``add_slide_direct`` instead.
    """
    sim = SimulatorBridge.get()
    # Deliberately NO best-effort UI tap: slides_add_slide_button isn't exposed
    # by the browser-only UI, and tapping a working button AND appending below
    # would add two slides. The shared-state write is authoritative.
    if not _CURRENT_PRESENTATION_ID:
        return "No open presentation to add a slide. Call open_presentation first."
    env = dl.read_envelope()
    pres = _find_presentation(env, _CURRENT_PRESENTATION_ID)
    if not pres:
        return f"No presentation matching '{_CURRENT_PRESENTATION_ID}' in shared state."
    slides = pres.setdefault("slides", [])
    slide_id = f"slide_added_{len(slides) + 1}"
    slides.append({"id": slide_id, "title": "Untitled Slide", "body": "", "layout": "titleBody"})
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "add_slide", "presentation_id": pres.get("id"), "slide_id": slide_id, "slide_count": len(slides), "new_slide_index": len(slides) - 1}


@mcp.tool()
def duplicate_slide() -> str:
    """Duplicate the currently selected slide and insert the copy after it.

    Commits directly to shared state (no UI tap) and reloads; the copy keeps
    the original title/body/layout with a new id. Returns ``{ok: True,
    slide_id, slide_count}``.

    The current slide defaults to index 0; call ``navigate_to_slide`` first to
    duplicate a different one. Precondition: a presentation must be open (call
    ``open_presentation`` first), else returns a plain "No open presentation"
    message.
    """
    sim = SimulatorBridge.get()
    # Deliberately NO best-effort UI tap: slides_duplicate_slide_button isn't
    # exposed by the browser-only UI, and tapping a working button AND inserting
    # below would create two copies. The shared-state write is authoritative.
    if not _CURRENT_PRESENTATION_ID:
        return "No open presentation to duplicate a slide. Call open_presentation first."
    env = dl.read_envelope()
    pres = _find_presentation(env, _CURRENT_PRESENTATION_ID)
    slides = pres.get("slides", []) if pres else []
    if not pres:
        return f"No presentation matching '{_CURRENT_PRESENTATION_ID}' in shared state."
    if not (0 <= _CURRENT_SLIDE_INDEX < len(slides)):
        return f"No current slide {_CURRENT_SLIDE_INDEX} to duplicate."
    original = dict(slides[_CURRENT_SLIDE_INDEX])
    original["id"] = f"{original.get('id', 'slide')}_copy_{len(slides) + 1}"
    slides.insert(_CURRENT_SLIDE_INDEX + 1, original)
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "duplicate_slide", "presentation_id": pres.get("id"), "slide_id": original["id"], "slide_count": len(slides)}


def _delete_slide_fill_form() -> Optional[str]:
    """Verify a presentation is open and the current slide can be deleted.

    Returns None on success or a precondition message on failure. Used by
    both ``delete_slide`` (one-shot commit) and ``prepare_delete_slide``
    (capture-only). Stops short of tapping
    ``slides_delete_slide_button`` so the caller decides whether to
    commit.
    """
    if not _CURRENT_PRESENTATION_ID:
        return "No open presentation to delete a slide. Call open_presentation first."
    env = dl.read_envelope()
    pres = _find_presentation(env, _CURRENT_PRESENTATION_ID)
    slides = pres.get("slides", []) if pres else []
    if not pres:
        return f"No presentation matching '{_CURRENT_PRESENTATION_ID}' in shared state."
    if len(slides) <= 1:
        return "Cannot delete the only slide in a presentation."
    if not (0 <= _CURRENT_SLIDE_INDEX < len(slides)):
        return f"No current slide {_CURRENT_SLIDE_INDEX} to delete."
    return None


def _capture_delete_slide_context() -> dict:
    """Snapshot the slide that would be removed by delete_slide."""
    env = dl.read_envelope()
    pres = _find_presentation(env, _CURRENT_PRESENTATION_ID) or {}
    slides = pres.get("slides", []) or []
    slide = slides[_CURRENT_SLIDE_INDEX] if 0 <= _CURRENT_SLIDE_INDEX < len(slides) else {}
    return {
        "presentation_id": pres.get("id"),
        "presentation_title": pres.get("title"),
        "slide_index": _CURRENT_SLIDE_INDEX,
        "slide_id": slide.get("id"),
        "title": slide.get("title"),
        "slide_count": len(slides),
    }


@mcp.tool()
def delete_slide() -> str:
    """Delete the currently selected slide (one-shot commit).

    Commits directly to shared state (no UI tap) and reloads. Current slide
    defaults to index 0; call ``navigate_to_slide`` first to delete a
    different one. Returns ``{ok: True, removed_slide_id, slide_count}`` on
    success, or ``{ok: False, error}`` when the deck has only one slide (the
    last slide cannot be deleted).

    Precondition: a presentation is open and the deck has more than one slide.
    Prefer ``prepare_delete_slide`` + ``confirm_delete_slide`` so you can
    preview the slide that will be removed before committing.
    """
    sim = SimulatorBridge.get()
    # Deliberately NO best-effort UI tap: slides_delete_slide_button isn't
    # exposed by the browser-only UI, and tapping a working button AND popping
    # below would remove two slides. The shared-state write is authoritative.
    if not _CURRENT_PRESENTATION_ID:
        return "No open presentation to delete a slide. Call open_presentation first."
    env = dl.read_envelope()
    pres = _find_presentation(env, _CURRENT_PRESENTATION_ID)
    slides = pres.get("slides", []) if pres else []
    if not pres:
        return f"No presentation matching '{_CURRENT_PRESENTATION_ID}' in shared state."
    if len(slides) <= 1:
        return {"ok": False, "error": "cannot delete the only slide in a presentation"}
    if not (0 <= _CURRENT_SLIDE_INDEX < len(slides)):
        return f"No current slide {_CURRENT_SLIDE_INDEX} to delete."
    removed = slides.pop(_CURRENT_SLIDE_INDEX)
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "delete_slide", "presentation_id": pres.get("id"), "removed_slide_id": removed.get("id"), "slide_count": len(slides)}


@mcp.tool()
def prepare_delete_slide() -> dict:
    """Stage a delete on the current slide WITHOUT committing.

    Verifies a presentation is open, the current slide index is valid,
    and that the deck has more than one slide. Captures a summary
    (``presentation_id``, ``presentation_title``, ``slide_index``,
    ``slide_id``, ``title``, ``slide_count``) describing the slide that
    would be removed.

    On success returns ``{ok: True, action: "prepare_delete_slide",
    draft_id, summary}``. Pass the ``draft_id`` to
    ``confirm_delete_slide`` to commit. Drafts expire after the
    ``IOSWORLD_DRAFT_TTL_SECONDS`` TTL (default 10 minutes).

    On precondition failure returns ``{ok: False, ...}`` with a bounded
    message and does not store a draft.
    """
    err = _delete_slide_fill_form()
    if err:
        return {"ok": False, "action": "prepare_delete_slide", "message": err}
    summary = _capture_delete_slide_context()
    draft_id = ts.create_draft("cloudslides", "delete_slide", summary)
    return {
        "ok": True,
        "action": "prepare_delete_slide",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_delete_slide(draft_id) to commit.",
    }


@mcp.tool()
def confirm_delete_slide(draft_id: str) -> dict:
    """Commit a slide delete previously staged by ``prepare_delete_slide``.

    ``draft_id`` is the id returned by ``prepare_delete_slide``. Removes the
    slide via a direct shared-state pop (no UI tap — the browser-only UI
    exposes no delete button) using the presentation + slide_index captured in
    the draft, NOT the live current selection, then reloads. Returns
    ``{ok: True, action: "confirm_delete_slide", evidence: {..., removed_slide_id,
    slide_count}}`` on success.

    Returns ``{ok: False, message}`` without removing anything if the draft is
    missing/expired, the deck now has only one slide, or the captured index is
    out of range.
    """
    if not draft_id or not isinstance(draft_id, str):
        return {
            "ok": False,
            "action": "confirm_delete_slide",
            "message": "Missing draft_id. Call prepare_delete_slide first and pass its draft_id.",
        }
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_delete_slide",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_delete_slide first.",
        }
    payload = draft.get("payload", {})
    # Commit the deletion resolved from the draft payload (presentation_id +
    # slide_index) — NOT the module globals, which may have been reset between
    # prepare and confirm. Deliberately NO best-effort UI tap: tapping a working
    # delete button AND popping below would remove two slides.
    env = dl.read_envelope()
    pres_key = payload.get("presentation_id") or _CURRENT_PRESENTATION_ID
    pres = _find_presentation(env, pres_key)
    slides = pres.get("slides", []) if pres else []
    slide_index = payload.get("slide_index")
    if slide_index is None:
        slide_index = _CURRENT_SLIDE_INDEX
    if not pres:
        return {
            "ok": False, "action": "confirm_delete_slide",
            "message": f"Presentation '{pres_key}' not found in shared state.",
        }
    if len(slides) <= 1:
        return {
            "ok": False, "action": "confirm_delete_slide",
            "message": "Cannot delete the only slide in a presentation.",
        }
    if not (0 <= slide_index < len(slides)):
        return {
            "ok": False, "action": "confirm_delete_slide",
            "message": f"Slide index {slide_index} out of range (have {len(slides)} slides).",
        }
    removed = slides.pop(slide_index)
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "action": "confirm_delete_slide",
        "evidence": {**payload, "removed_slide_id": removed.get("id"), "slide_count": len(slides)},
    }


@mcp.tool()
def edit_slide() -> str:
    """Enter edit mode on the currently selected slide.

    Precondition: a presentation is open. If the edit button is hidden,
    returns a controlled-failure dict — use ``set_slide_text`` for a
    direct shared-state edit instead.
    """
    sim = SimulatorBridge.get()
    for accessibility_id in ("slides_edit_button", "Edit"):
        try:
            ui = sim.tap_and_observe(accessibility_id)
            return f"Entered slide edit mode.\n\n{ui}"
        except Exception:
            continue
    return {
        "ok": True,
        "action": "edit_slide",
        "entered": False,
        "message": "Edit controls are unavailable in the current UI state; use set_slide_text for direct shared-state edits.",
    }


def _current_slide(env: dict):
    """Return (presentation, slides, slide) for the current selection, or
    (None, [], None) if no presentation/slide is selected."""
    pres = _find_presentation(env, _CURRENT_PRESENTATION_ID) if _CURRENT_PRESENTATION_ID else None
    slides = pres.get("slides", []) if pres else []
    slide = slides[_CURRENT_SLIDE_INDEX] if (0 <= _CURRENT_SLIDE_INDEX < len(slides)) else None
    return pres, slides, slide


def _clean_appended_body_text(text: str) -> str:
    """Normalize one appended bullet/body line to the store convention."""
    return (text or "").strip().lstrip("•-*").strip()


@mcp.tool()
def set_slide_title(text: str) -> str:
    """Set the title text of the current slide (replaces, does not append).

    Args:
        text: New title text.

    Precondition: a presentation is open and a slide is selected (call
    ``open_presentation`` then optionally ``navigate_to_slide``). Best-effort
    types into ``slides_slide_title_field`` for visual parity, then commits
    the title to the current slide in the shared workspace envelope and
    reloads the app — so the change persists even though the browser-only UI
    exposes no stable editor field. The benchmark grades end-state.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("slides_slide_title_field"); sim.wait(0.3)
        sim.type_text(text); sim.wait(0.2)
    except Exception:
        pass
    if not _CURRENT_PRESENTATION_ID:
        return {"ok": False, "action": "set_slide_title",
                "message": "No open presentation. Call open_presentation first."}
    env = dl.read_envelope()
    pres, slides, slide = _current_slide(env)
    if not pres:
        return {"ok": False, "action": "set_slide_title",
                "message": f"No presentation matching '{_CURRENT_PRESENTATION_ID}' in shared state."}
    if slide is None:
        return {"ok": False, "action": "set_slide_title",
                "message": f"No current slide {_CURRENT_SLIDE_INDEX} (have {len(slides)} slides)."}
    slide["title"] = text
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "set_slide_title", "presentation_id": pres.get("id"),
            "slide_index": _CURRENT_SLIDE_INDEX, "slide_id": slide.get("id"), "title": text}


@mcp.tool()
def set_slide_body(text: str) -> str:
    """APPEND text into the body of the current slide.

    Args:
        text: Text to append to the existing body. To fully REPLACE the
            body instead, use ``set_slide_text`` (accepts a complete
            ``body`` value).

    The appended text starts a NEW LINE: when the slide already has a
    non-empty body the text is joined with a ``\n`` so bullets never merge
    (e.g. ``Why benchmarks matter`` + ``Safety`` becomes two lines, not
    ``Why benchmarks matterSafety``). Any leading bullet/dash glyph
    (``•``, ``-``, ``*``) and surrounding whitespace are stripped from the
    appended text so the stored body stays a clean newline-separated list.

    Precondition: a presentation is open and a slide is selected. Best-effort
    types into ``slides_slide_body_field`` for visual parity, then appends
    the text to the current slide's body in the shared workspace envelope and
    reloads the app so the change persists.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("slides_slide_body_field"); sim.wait(0.3)
        sim.type_text(text); sim.wait(0.2)
    except Exception:
        pass
    if not _CURRENT_PRESENTATION_ID:
        return {"ok": False, "action": "set_slide_body",
                "message": "No open presentation. Call open_presentation first."}
    env = dl.read_envelope()
    pres, slides, slide = _current_slide(env)
    if not pres:
        return {"ok": False, "action": "set_slide_body",
                "message": f"No presentation matching '{_CURRENT_PRESENTATION_ID}' in shared state."}
    if slide is None:
        return {"ok": False, "action": "set_slide_body",
                "message": f"No current slide {_CURRENT_SLIDE_INDEX} (have {len(slides)} slides)."}
    existing = slide.get("body", "") or ""
    # Append text starts a NEW LINE. Strip any leading bullet/dash glyph and
    # surrounding whitespace from the incoming text, then join to a non-empty
    # body with "\n" so bullets never concatenate ("...matterSafety").
    appended = _clean_appended_body_text(text)
    if existing and appended:
        slide["body"] = existing.rstrip("\n") + "\n" + appended
    elif appended:
        slide["body"] = appended
    else:
        slide["body"] = existing
    dl.write_envelope(env)
    check_env = dl.read_envelope()
    check_pres = _find_presentation(check_env, pres.get("id", ""))
    check_slides = check_pres.get("slides", []) if check_pres else []
    persisted_body = ""
    if 0 <= _CURRENT_SLIDE_INDEX < len(check_slides):
        persisted_body = check_slides[_CURRENT_SLIDE_INDEX].get("body", "") or ""
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "set_slide_body", "presentation_id": pres.get("id"),
            "slide_index": _CURRENT_SLIDE_INDEX, "slide_id": slide.get("id"),
            "appended": appended, "body": persisted_body,
            "verified": persisted_body == slide["body"],
            "line_count": len([ln for ln in persisted_body.splitlines() if ln.strip()])}


@mcp.tool()
def append_bullet(text: str) -> dict:
    """Append one bullet/body line to the current slide and verify it persisted.

    Args:
        text: Bullet text to append. Leading bullet markers (``-``, ``*``,
            or ``•``) are accepted but stripped before storage.

    Precondition: a presentation is open and a slide is selected. This is a
    clearer alias for the append semantics of ``set_slide_body``.
    """
    result = set_slide_body(text)
    if isinstance(result, dict):
        result["action"] = "append_bullet"
    return result


@mcp.tool()
def navigate_to_slide(index: int) -> str:
    """Jump to a slide by zero-based index and make it current.

    Taps ``slides_thumbnail_<index>`` if present; if the thumbnail is not in
    the live tree it falls back to updating the current-slide index in shared
    state (validated against the open deck's slide count), so it still works
    from the file browser. Subsequent set_slide_title/body/delete/duplicate
    operate on this index.

    Args:
        index: Slide index. 0-based is canonical (``[0, slide_count)``), but a
            1-based "slide N" is tolerated: if ``index`` is out of range yet
            ``index-1`` is valid, it is treated as 1-based and resolved to
            ``index-1`` (reported via ``interpreted_as``). A truly out-of-range
            index or no-open-deck returns ``{ok: False, opened: False, ...}``
            with the valid range in the message.

    Precondition: a presentation is open.
    """
    global _CURRENT_SLIDE_INDEX
    sim = SimulatorBridge.get()
    try:
        ui = sim.tap_and_observe(f"slides_thumbnail_{index}")
        _CURRENT_SLIDE_INDEX = index
    except Exception as exc:
        if _CURRENT_PRESENTATION_ID:
            env = dl.read_envelope()
            pres = _find_presentation(env, _CURRENT_PRESENTATION_ID)
            slides = pres.get("slides", []) if pres else []
            n = len(slides)
            if 0 <= index < n:
                _CURRENT_SLIDE_INDEX = index
                return {"ok": True, "action": "navigate_to_slide", "presentation_id": _CURRENT_PRESENTATION_ID, "slide_index": index, "slide_id": slides[index].get("id")}
            # Tolerate a 1-based "slide N": map to 0-based index N-1 when valid.
            if isinstance(index, int) and index >= 1 and (index - 1) < n:
                resolved = index - 1
                _CURRENT_SLIDE_INDEX = resolved
                return {"ok": True, "action": "navigate_to_slide", "presentation_id": _CURRENT_PRESENTATION_ID,
                        "slide_index": resolved, "slide_id": slides[resolved].get("id"),
                        "interpreted_as": f"1-based 'slide {index}' -> 0-based index {resolved}"}
            return {"ok": False, "action": "navigate_to_slide", "opened": False, "slide_index": index,
                    "slide_count": n,
                    "message": (f"Slide index {index} is out of range. Valid 0-based indices are "
                                f"0..{n - 1} ({n} slides). Pass a 0-based index in that range.")}
        return {"ok": False, "action": "navigate_to_slide", "opened": False, "slide_index": index, "message": "No presentation is open; call open_presentation first, then navigate_to_slide with a 0-based index."}
    return f"Navigated to slide {index}.\n\n{ui}"


@mcp.tool()
def view_recent() -> str:
    """Return the current UI tree (the Recent tab when launched).

    Does not navigate; assumes the Recent tab is already showing.
    """
    sim = SimulatorBridge.get()
    ui = sim.observe_text()
    return f"Recent presentations view.\n\n{ui}"


@mcp.tool()
def list_presentations() -> dict:
    """List visible presentation slugs in the current file list.

    Returns:
        ``{presentations: [<slug>...], count}`` — each slug is the
        suffix of ``file_row_slides_<slug>`` (or
        recent_/shared_/starred_/trash_/search_file_) usable with
        ``open_presentation(name=<slug>)``.
    """
    import re
    sim = SimulatorBridge.get()
    tree = sim.observe_text()
    slugs = sorted(set(re.findall(r'(?:file|recent|shared|starred|trash|search_file)_row_slides_([^"\s]+)', tree)))
    resolved_from = "ui"
    # Bug class (1): after a search overlay / detail screen, the file-browser
    # rows are not in the live tree, so the regex returns []. Never report an
    # empty list as the truth — fall back to the shared-state workspace so the
    # agent always sees the decks that actually exist.
    if not slugs:
        env = dl.read_envelope()
        slugs = sorted(
            _slug(p.get("title", ""))
            for p in env.get("seededData", {}).get("presentations", [])
            if p.get("title")
        )
        resolved_from = "shared_state"
    return {"presentations": slugs, "count": len(slugs), "resolved_from": resolved_from}


@mcp.tool()
def enter_edit_mode() -> str:
    """Enter edit mode on the currently open presentation.

    Precondition: a presentation is open. Returns a controlled-failure
    dict if the Edit button is not visible — use ``set_slide_text`` for
    direct shared-state edits in that case.
    """
    sim = SimulatorBridge.get()
    for accessibility_id in ("slides_edit_button", "Edit"):
        try:
            sim.tap_id(accessibility_id)
            sim.wait(0.4)
            return "Entered slide edit mode."
        except Exception:
            continue
    return {
        "ok": True,
        "action": "enter_edit_mode",
        "entered": False,
        "message": "Edit controls are unavailable in the current UI state; use set_slide_text for direct shared-state edits.",
    }


@mcp.tool()
def rename_presentation(new_title: str) -> str:
    """Rename the currently open presentation.

    Args:
        new_title: New display title. Replaces the existing title.

    Precondition: a presentation is open. Taps ``slides_title_field``
    then types; falls back to a shared-state write if the field is
    unavailable.
    """
    sim = SimulatorBridge.get()
    # Best-effort UI tap, then always overwrite the title in shared state.
    try:
        sim.tap_id("slides_title_field"); sim.wait(0.3)
        sim.type_text(new_title); sim.wait(0.2)
    except Exception:
        pass
    if not _CURRENT_PRESENTATION_ID:
        return "No open presentation to rename. Call open_presentation first."
    env = dl.read_envelope()
    pres = _find_presentation(env, _CURRENT_PRESENTATION_ID)
    if not pres:
        return f"No presentation matching '{_CURRENT_PRESENTATION_ID}' in shared state."
    old_title = pres.get("title")
    pres["title"] = new_title
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "rename_presentation", "presentation_id": pres.get("id"), "old_title": old_title, "title": new_title}


# ── Direct-state-write tools (mutate the shared workspace_envelope and
# relaunch — bypasses the slide editor when its UI doesn't expose stable
# input IDs).

@mcp.tool()
def list_presentations_with_meta() -> dict:
    """List ALL presentations in the workspace store (not just visible ones).

    Returns:
        ``{presentations: [{id, title, slide_count, theme}...], count}``.
        Sourced from the shared workspace envelope rather than the UI
        tree, so includes presentations not currently rendered.
    """
    env = dl.read_envelope()
    out = [{"id": p.get("id"), "title": p.get("title"),
            "slide_count": len(p.get("slides", []) or []),
            "theme": p.get("themeName")}
           for p in env.get("seededData",{}).get("presentations",[])]
    return {"presentations": out, "count": len(out)}


@mcp.tool()
def set_slide_text(title_or_id: str, slide_index: int,
                   slide_title: str = "", body: str = "") -> dict:
    """Edit a slide's title and/or body via direct shared-state write.

    Bypasses the in-app slide editor — works WITHOUT calling
    ``open_presentation`` first (you name the deck and slide explicitly).

    Args:
        title_or_id: Any presentation handle — the display TITLE or a unique
            substring of it (case-insensitive), the store id
            ``file_slides_<slug>``, the bare id-suffix slug, or a title slug.
            The human-readable title is the safest handle; no need to guess a
            slug. On no/ambiguous match returns ``{ok: False, error, available}``
            listing decks with their ids and slugs.
        slide_index: Slide index. 0-based is canonical (``[0, slide_count)``),
            but a 1-based "slide N" is tolerated: if ``slide_index`` is out of
            range yet ``slide_index-1`` is valid, it is treated as 1-based and
            resolved to ``slide_index-1`` (reported via ``interpreted_as``). A
            truly out-of-range index returns ``{ok: False, error}`` naming the
            valid range.
        slide_title: New title text — REPLACES the title. Empty string leaves
            the title untouched.
        body: New body text — REPLACES the body (does not append; use
            ``set_slide_body`` to append). Empty string leaves body untouched.
    """
    env = dl.read_envelope()
    pres = _find_presentation(env, title_or_id)
    if not pres:
        presentations = [
            {"id": p.get("id"), "title": p.get("title"), "slug": _slug(p.get("title", ""))}
            for p in env.get("seededData", {}).get("presentations", [])
        ][:8]
        return {"ok": False, "error": f"No presentation matching '{title_or_id}'", "available": presentations}
    slides = pres.get("slides", []) or []
    n = len(slides)
    interpreted_as = None
    if not (0 <= slide_index < n):
        # Tolerate a 1-based "slide N": map to 0-based index N-1 when valid.
        if isinstance(slide_index, int) and slide_index >= 1 and (slide_index - 1) < n:
            interpreted_as = f"1-based 'slide {slide_index}' -> 0-based index {slide_index - 1}"
            slide_index = slide_index - 1
        else:
            return {"ok": False, "error": (f"slide_index {slide_index} out of range. Valid 0-based "
                                           f"indices are 0..{n - 1} ({n} slides).")}
    s = slides[slide_index]
    if slide_title:
        s["title"] = slide_title
    if body:
        s["body"] = body
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    result = {"ok": True, "presentation": pres.get("title"),
              "slide_index": slide_index, "slide_id": s.get("id"),
              "message": f"Updated slide {slide_index} of '{pres.get('title')}'."}
    if interpreted_as:
        result["interpreted_as"] = interpreted_as
    return result


@mcp.tool()
def add_slide_direct(title_or_id: str, slide_title: str, body: str = "",
                     layout: str = "titleBody") -> dict:
    """Append a new slide to a presentation via direct shared-state write.

    Bypasses the slide editor and does NOT require ``open_presentation`` —
    you name the target deck explicitly. Reloads after writing.

    Args:
        title_or_id: Any presentation handle — the display TITLE or a unique
            substring of it (case-insensitive), the store id
            ``file_slides_<slug>``, the bare id-suffix slug, or a title slug.
            The human-readable title is the safest handle. On no/ambiguous
            match returns ``{ok: False, error, available}`` listing decks with
            ids and slugs.
        slide_title: Title text for the new slide. Required.
        body: Body content. Empty string for title-only slides.
        layout: One of ``titleOnly``, ``titleBody`` (default), ``bullets``,
            ``image``. Any other value is stored as-is but may not render
            correctly.

    Returns ``{ok: True, new_slide_index, ...}`` (new slide appended last).
    """
    env = dl.read_envelope()
    pres = _find_presentation(env, title_or_id)
    if not pres:
        presentations = [
            {"id": p.get("id"), "title": p.get("title"), "slug": _slug(p.get("title", ""))}
            for p in env.get("seededData", {}).get("presentations", [])
        ][:8]
        return {"ok": False, "error": f"No presentation matching '{title_or_id}'", "available": presentations}
    slides = pres.setdefault("slides", [])
    new_slide = {
        "id": f"slide_added_{len(slides)+1}",
        "title": slide_title,
        "body": body,
        "layout": layout,
    }
    slides.append(new_slide)
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "presentation": pres.get("title"),
            "new_slide_index": len(slides)-1,
            "message": f"Added slide {len(slides)-1} to '{pres.get('title')}'."}


if __name__ == "__main__":
    mcp.run()
