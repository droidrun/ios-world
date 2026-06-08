"""Notes MCP — CRUD notes + folders via accessibility IDs.

IDs (see Notes/ContentView.swift):
  notes_folder_all, notes_folder_trash, notes_folder_<slug>
  notes_new_folder_button, notes_new_note_button,
  notes_new_folder_name_field, notes_new_folder_save
  note_row_<title_slug>
  notes_title_field, notes_body_editor
"""

import sys, pathlib, re
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("Notes")

BUNDLE_ID = "com.iosworld.benchmark.notes"


def _slug(s: str, max_len: int = 50) -> str:
    return s.lower().replace(" ", "_")[:max_len]


def _read(sim, aid: str) -> str:
    try:
        el = sim.driver.find_element("accessibility id", aid)
        return el.text or (el.get_attribute("value") or "")
    except Exception:
        return ""


def _row_slug(title: str) -> str:
    """Mirror Note.rowAccessibilityID in the Swift app.

    Untitled notes render as "New Note"; spaces -> underscores, lowercased,
    no special-char stripping, truncated to 50 chars. Used to build the
    ``note_row_<slug>`` accessibility id we tap.
    """
    base = title if (title or "").strip() else "New Note"
    return base.lower().replace(" ", "_")[:50]


def _resolve_note(title_or_id: str):
    """Resolve a blind note reference (numeric Z_PK or fuzzy title) against
    the SwiftData store. Returns a dict with the real title/folder/trash
    state so UI tools can self-navigate, or None if nothing matches.

    Match order: exact Z_PK -> exact (case-insensitive) title -> substring
    title (most-recently-modified wins) -> token-overlap fuzzy.
    """
    db = _notes_db()
    if not db:
        return None
    cur = db.cursor()
    rows = cur.execute(
        """SELECT n.Z_PK, n.ZTITLE, f.ZNAME, n.ZISINTRASH, n.ZISPINNED,
                  n.ZMODIFIEDDATE
           FROM ZNOTE n LEFT JOIN ZNOTEFOLDER f ON n.ZFOLDER = f.Z_PK"""
    ).fetchall()
    db.close()
    notes = [
        {"id": r[0], "title": r[1] or "", "folder": r[2] or "Notes",
         "trashed": bool(r[3]), "pinned": bool(r[4]), "mod": r[5] or 0}
        for r in rows
    ]
    if not notes:
        return None
    ref = (title_or_id or "").strip()
    # 1. numeric Z_PK
    try:
        pk = int(ref)
        for n in notes:
            if n["id"] == pk:
                return n
    except (TypeError, ValueError):
        pass
    low = ref.lower()
    slug_ref = low
    if slug_ref.startswith("note_row_"):
        slug_ref = slug_ref[len("note_row_"):]
    # 2. exact title (case-insensitive)
    exact = [n for n in notes if n["title"].lower() == low]
    if exact:
        return max(exact, key=lambda n: n["mod"])
    # 3. exact row slug, as returned by search_notes/list_notes.
    exact_slug = [n for n in notes if _row_slug(n["title"]) == slug_ref]
    if exact_slug:
        return max(exact_slug, key=lambda n: n["mod"])
    # 4. substring
    subs = [n for n in notes if low and low in n["title"].lower()]
    if subs:
        return max(subs, key=lambda n: n["mod"])
    # 5. token-overlap fuzzy
    qtokens = set(re.findall(r"\w+", low))
    if qtokens:
        scored = []
        for n in notes:
            ntokens = set(re.findall(r"\w+", n["title"].lower()))
            ov = len(qtokens & ntokens)
            if ov:
                scored.append((ov, n["mod"], n))
        if scored:
            scored.sort(key=lambda t: (t[0], t[1]), reverse=True)
            return scored[0][2]
    return None


def _nav_to_list_for(sim, note: dict) -> None:
    """From a fresh launch, open the list view that contains *note* so its
    row is reachable. Trashed -> Recently Deleted; otherwise -> All iCloud
    (which lists every active note across folders)."""
    sim.launch_and_observe(BUNDLE_ID)
    if note.get("trashed"):
        sim.tap_id("notes_folder_trash")
    else:
        sim.tap_id("notes_folder_all")
    sim.wait(0.6)


def _xml_escape(s: str) -> str:
    """Mirror how the accessibility tree text-escapes an id's special chars.

    The UI dump is XML, so ``&``->``&amp;``, ``<``->``&lt;``, ``>``->``&gt;``,
    ``"``->``&quot;``. A title like "Movies & Shows" therefore appears as
    ``note_row_movies_&amp;_shows`` in the tree even though the REAL
    accessibility id (used for the Appium tap) is the un-escaped form. Use
    this when probing the tree for a row id, but tap with the raw id.
    """
    return (s.replace("&", "&amp;").replace("<", "&lt;")
             .replace(">", "&gt;").replace('"', "&quot;"))


def _unescape_slug(s: str) -> str:
    """Reverse :func:`_xml_escape` so slugs surfaced to callers are the REAL
    accessibility-id form (``movies_&_shows`` not ``movies_&amp;_shows``).
    ``&amp;`` must be last so it doesn't double-decode ``&lt;``/``&gt;``."""
    return (s.replace("&lt;", "<").replace("&gt;", ">")
             .replace("&quot;", '"').replace("&amp;", "&"))


def _row_in_tree(tree: str, aid: str) -> bool:
    """True if *aid* (a raw ``note_row_<slug>``) appears in the tree, testing
    both the raw and XML-escaped forms so ids containing &<>\" still match."""
    return aid in tree or _xml_escape(aid) in tree


def _find_and_tap_row(sim, slug: str, *, max_scrolls: int = 8) -> bool:
    """Scroll the current notes list looking for ``note_row_<slug>`` and tap
    it. Returns True if the tap landed (UI changed into the editor).

    The presence check tolerates XML-escaped ids (``&``->``&amp;`` etc.) but
    the tap always uses the raw accessibility id, which Appium resolves
    directly — so notes whose titles contain ``&``/``<``/``>`` still open.
    """
    aid = f"note_row_{slug}"
    for _ in range(max_scrolls + 1):
        tree = sim.observe_text() or ""
        if _row_in_tree(tree, aid):
            err = sim.tap_and_verify_changed(aid)
            if err is None:
                return True
            # tap didn't change UI; fall through to scroll & retry
        before = tree
        sim.swipe("up")
        sim.wait(0.4)
        if (sim.observe_text() or "") == before:
            break  # list didn't move -> reached the bottom
    # final attempt after last scroll
    if _row_in_tree(sim.observe_text() or "", aid):
        return sim.tap_and_verify_changed(aid) is None
    return False


def _open_note_robust(sim, title_or_id: str):
    """Self-navigate from any state and open the note. Returns
    (note_dict, True) on success or (note_dict_or_None, False) on failure."""
    note = _resolve_note(title_or_id)
    if not note:
        return None, False
    slug = _row_slug(note["title"])
    _nav_to_list_for(sim, note)
    if _find_and_tap_row(sim, slug):
        return note, True
    # Fallback: the note might live in its specific folder rather than All
    if not note.get("trashed"):
        sim.launch_and_observe(BUNDLE_ID)
        faid = f"notes_folder_{note['folder'].lower().replace(' ', '_')}"
        try:
            sim.tap_id(faid)
            sim.wait(0.6)
        except Exception:
            return note, False
        if _find_and_tap_row(sim, slug):
            return note, True
    return note, False


@mcp.tool()
def launch() -> str:
    """Launch the Notes app and return its initial UI tree.

    Returns:
      Human-readable string with a confirmation line and the accessibility
      tree from the foreground app.
    """
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched Notes.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current accessibility-tree dump of the Notes app's UI."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="Notes",
        markers=("note_row_", "notes_", "notes_title_field", "notes_body_editor"),
    )


@mcp.tool()
def open_folder(name: str) -> str:
    """Open a folder in the sidebar and return the resulting UI tree.

    Works from any screen — self-navigates: if a note/list is open it
    relaunches to the sidebar (where folder rows live) before tapping.

    Args:
      name: folder display name as shown in the sidebar (e.g. "Personal",
        "Work"). Get exact names from list_notes_with_meta()/search_notes()
        ``folder`` fields. Matched case-insensitively, then by substring
        against the real folder names in the store — so a partial name like
        "rec" finds "Recipes". You do NOT need to know the slug. Aliases:
        "all" / "all icloud" / "icloud" -> All iCloud; "trash" /
        "recently deleted" / "deleted" -> Recently Deleted.

    Returns the UI tree on success, or a "No Notes folder matching '<name>'"
    error string if no folder resolves.
    """
    sim = SimulatorBridge.get()
    key = name.strip().lower()
    if key in ("all", "all icloud", "icloud"):
        aid = "notes_folder_all"
    elif key in ("trash", "recently deleted", "deleted"):
        aid = "notes_folder_trash"
    else:
        aid = f"notes_folder_{_slug(key)}"
    # Self-navigate: the folder rows only exist on the sidebar (root of the
    # NavigationStack). If a note/list is currently open the tap would fail,
    # so ensure we're back on the sidebar first when the id isn't visible.
    if aid not in (sim.observe_text() or ""):
        sim.launch_and_observe(BUNDLE_ID)
    # If the user's folder name doesn't match a known accessibility id,
    # resolve it case-insensitively against the real folder names.
    if aid not in (sim.observe_text() or "") and key not in (
            "all", "all icloud", "icloud", "trash", "recently deleted", "deleted"):
        db = _notes_db()
        if db:
            rows = db.execute("SELECT ZNAME FROM ZNOTEFOLDER").fetchall()
            db.close()
            names = [r[0] for r in rows if r[0]]
            match = next((n for n in names if n.lower() == key), None) \
                or next((n for n in names if key and key in n.lower()), None)
            if match:
                aid = f"notes_folder_{match.lower().replace(' ', '_')}"
    try:
        ui = sim.tap_and_observe(aid)
    except Exception as exc:
        return f"No Notes folder matching '{name}'. Error: {str(exc)[:120]}"
    return f"Opened folder '{name}'.\n\n{ui}"


@mcp.tool()
def list_notes() -> dict:
    """List the title-slugs of notes visible in the currently open folder.

    Self-navigating: if no notes list is currently open (e.g. you're on the
    folder sidebar or just launched), this opens the All iCloud view first
    so it returns every active note rather than an empty list.

    Returns:
      ``{"notes": [<title_slug>, ...], "count": int}`` — slugs come from
      ``note_row_<title_slug>`` IDs (lowercased, spaces->underscores).
    """
    sim = SimulatorBridge.get()

    def _collect(scrolls: int) -> set:
        """Gather every ``note_row_<slug>`` id by scrolling the current list,
        un-escaping the XML entities the tree dump introduces."""
        seen = set()
        for _ in range(scrolls):
            t = sim.observe_text() or ""
            seen.update(re.findall(r'note_row_([^"\s]+)', t))
            before = t
            sim.swipe("up")
            sim.wait(0.3)
            if (sim.observe_text() or "") == before:
                break
        return seen

    tree = sim.observe_text() or ""
    if "note_row_" in tree:
        # A list is open. Scroll to capture rows below the fold too (the
        # on-screen slice alone misses any note past the first viewport).
        found = _collect(10)
    else:
        # No list open — self-navigate to All iCloud and scroll the whole list.
        try:
            sim.launch_and_observe(BUNDLE_ID)
            sim.tap_id("notes_folder_all")
            sim.wait(0.6)
        except Exception:
            pass
        found = _collect(10)
    slugs = sorted(_unescape_slug(s) for s in found)
    return {"notes": slugs, "count": len(slugs)}


@mcp.tool()
def open_note(title: str) -> str:
    """Open a note by title or id — self-navigating and blind-call safe.

    Args:
      title: a note's numeric id (Z_PK as a string) OR its title. Titles
        match case-insensitively (exact -> substring -> token-overlap
        fuzzy), so partial names like "alpha" or "garlic pasta" work even
        when the note lives in another folder or is off-screen.

    Does NOT require any prior navigation: the tool resolves the note from
    the app's store, relaunches to the folder list, opens the list that
    holds the note (All iCloud, or Recently Deleted for trashed notes),
    scrolls to the row, and taps it. Ambiguous title matches resolve to the
    most-recently-modified note (no controlled failure).

    Returns a confirmation string with the opened note's id/folder. If no
    note matches it returns "No note matching ..." plus a sample of existing
    titles; if it resolves but the row can't be tapped it says so and
    suggests observe().
    """
    sim = SimulatorBridge.get()
    note, ok = _open_note_robust(sim, title)
    if ok:
        return (f"Opened note '{note['title'] or 'New Note'}' "
                f"(id={note['id']}, folder={note['folder']}).")
    if note is None:
        # surface a few real titles to help the caller
        meta = list_notes_with_meta()
        avail = [n.get("title", "") for n in meta.get("notes", [])][:10] \
            if isinstance(meta, dict) else []
        return f"No note matching '{title}'. Existing titles: {avail}"
    return (f"Could not tap row for resolved note '{note['title']}' "
            f"(id={note['id']}) after navigating. Call observe() to inspect.")


@mcp.tool()
def create_note(title: str = "", body: str = "") -> str:
    """Create a new note and open it in the editor.

    Works from any screen. The note is created via a direct SwiftData write
    (NOT the + button — simulator-typed text does not commit to the binding),
    then opened so it is visible. The new note lands in whichever folder the
    nav bar currently shows; if that can't be determined it defaults to the
    "Notes" folder. To target a specific folder explicitly, use
    create_note_direct(folder=...) instead.

    Args:
      title: optional note title. Empty string leaves the note untitled
        (it renders as "New Note").
      body: optional body text. Empty string leaves the body empty.

    Returns a confirmation string including the new note's id, or an error
    string if the store could not be written.
    """
    sim = SimulatorBridge.get()
    # Determine the currently-open folder from the nav bar so the new note
    # lands where the agent is. Falls back to the default "Notes" folder
    # (matching the app's behavior when created from the sidebar/All view).
    tree = sim.observe_text() or ""
    m = re.search(r'XCUIElementTypeNavigationBar[^>]*\sname="([^"]+)"', tree)
    nav = (m.group(1) if m else "").strip()
    db = _notes_db()
    if not db:
        return "Notes store not found."
    folder_names = [r[0] for r in db.execute(
        "SELECT ZNAME FROM ZNOTEFOLDER").fetchall() if r[0]]
    db.close()
    folder = next((f for f in folder_names if f.lower() == nav.lower()), None)
    if folder is None:
        folder = "Notes" if "Notes" in folder_names else (
            folder_names[0] if folder_names else "Notes")
    res = create_note_direct(title=title, body=body, folder=folder)
    if not isinstance(res, dict) or not res.get("ok"):
        return f"Could not create note. {res}"
    # Open it so the new note is visible in the editor.
    _open_note_robust(sim, str(res["note_id"]))
    return (f"Created note (title='{title}', body_len={len(body)}) "
            f"in folder '{folder}' (id={res['note_id']}).")


def _open_note_in_editor(sim) -> dict | None:
    """If a note editor is currently on screen, resolve WHICH note it is by
    matching the live title/body fields back to the store. Returns the note
    dict (id/title/...) or None if no editor is open or no match is found."""
    tree = sim.observe_text() or ""
    if "notes_body_editor" not in tree and "notes_title_field" not in tree:
        return None
    live_title = (_read(sim, "notes_title_field") or "").strip()
    live_body = _read(sim, "notes_body_editor") or ""
    db = _notes_db()
    if not db:
        return None
    rows = db.execute(
        "SELECT Z_PK, ZTITLE, ZBODY, ZISINTRASH, ZMODIFIEDDATE FROM ZNOTE"
    ).fetchall()
    db.close()
    cands = []
    for pk, t, b, trashed, mod in rows:
        t = t or ""
        if live_title and t.strip().lower() == live_title.lower():
            cands.append((2, mod or 0, pk, t))
        elif not live_title and live_body and (b or "")[:40] == live_body[:40]:
            cands.append((1, mod or 0, pk, t))
    if not cands:
        return None
    cands.sort(reverse=True)
    _, _, pk, t = cands[0]
    return {"id": pk, "title": t}


@mcp.tool()
def edit_note_body(body: str, title: str = "") -> str:
    """Append text to a note's body, persisted to the store.

    Args:
      body: text to append to the end of the body. A leading newline is
        added automatically when the existing body is non-empty so the new
        text starts on its own line. Newlines within `body` are kept.
      title: OPTIONAL note title/id to target. When given the note is
        resolved from the store (exact -> substring -> fuzzy), so this works
        blind from any state. When omitted, the currently-open note (read
        back from the live editor) is edited.

    The write goes through the data layer (the SwiftUI TextEditor binding
    does not commit simulator-typed text to SwiftData), then the note is
    opened in the editor so the change is visible. Reports ok only after the
    store actually reflects the appended text.
    """
    sim = SimulatorBridge.get()
    target_id = None
    if title:
        note = _resolve_note(title)
        if note is None:
            return f"Could not open note '{title}' to edit. No match found."
        target_id = note["id"]
    else:
        cur = _open_note_in_editor(sim)
        if cur is None:
            return ("Could not edit body: no note is open and no title was "
                    "given. Pass title=... to self-navigate to a note.")
        target_id = cur["id"]
    db = _notes_db()
    if not db:
        return "Notes store not found."
    cur = db.cursor()
    row = cur.execute("SELECT ZTITLE, ZBODY FROM ZNOTE WHERE Z_PK=?",
                      (target_id,)).fetchone()
    if not row:
        db.close()
        return f"Could not open note '{title}' to edit. No match found."
    old_title, old_body = row
    old_body = old_body or ""
    new_body = (old_body + ("\n" if old_body and not old_body.endswith("\n")
                            else "") + body) if old_body else body
    cur.execute("UPDATE ZNOTE SET ZBODY=?, ZMODIFIEDDATE=? WHERE Z_PK=?",
                (new_body, _core_data_now(), target_id))
    db.commit()
    db.close()
    dl.reload_app(BUNDLE_ID)
    # Confirm: re-read the store.
    db = _notes_db()
    check = db.execute("SELECT ZBODY FROM ZNOTE WHERE Z_PK=?",
                       (target_id,)).fetchone()
    db.close()
    if not check or body.strip() not in (check[0] or ""):
        return (f"Edit not confirmed for note '{old_title}' (id={target_id}).")
    # Open the note so the change is visible in the editor.
    _open_note_robust(sim, str(target_id))
    return (f"Appended {len(body)} chars to '{old_title or 'New Note'}' "
            f"(id={target_id}); new body length {len(new_body)}.")


@mcp.tool()
def edit_note_title(title: str, target: str = "") -> str:
    """Append text to a note's title, persisted to the store.

    Args:
      title: text appended to the note's existing title (no auto-clear, to
        match the field-typing semantics). For an untitled note this sets
        the title outright.
      target: OPTIONAL note title/id to target. Resolved from the store
        (exact -> substring -> fuzzy) so this works blind from any state.
        When omitted, the currently-open note (read back from the live
        editor) is edited.

    The write goes through the data layer (the SwiftUI title field binding
    does not commit simulator-typed text to SwiftData), then the note is
    opened so the change is visible. Reports ok only after the store
    reflects the new title.
    """
    sim = SimulatorBridge.get()
    if target:
        note = _resolve_note(target)
        if note is None:
            return f"Could not open note '{target}' to edit. No match found."
        target_id = note["id"]
    else:
        cur = _open_note_in_editor(sim)
        if cur is None:
            return ("Could not edit title: no note is open and no target was "
                    "given. Pass target=... to self-navigate to a note.")
        target_id = cur["id"]
    db = _notes_db()
    if not db:
        return "Notes store not found."
    cur = db.cursor()
    row = cur.execute("SELECT ZTITLE FROM ZNOTE WHERE Z_PK=?",
                      (target_id,)).fetchone()
    if not row:
        db.close()
        return f"Could not open note '{target}' to edit. No match found."
    old_title = row[0] or ""
    new_title = old_title + title
    cur.execute("UPDATE ZNOTE SET ZTITLE=?, ZMODIFIEDDATE=? WHERE Z_PK=?",
                (new_title, _core_data_now(), target_id))
    db.commit()
    db.close()
    dl.reload_app(BUNDLE_ID)
    db = _notes_db()
    check = db.execute("SELECT ZTITLE FROM ZNOTE WHERE Z_PK=?",
                       (target_id,)).fetchone()
    db.close()
    if not check or check[0] != new_title:
        return f"Title edit not confirmed for note id={target_id}."
    _open_note_robust(sim, str(target_id))
    return (f"Set title of note id={target_id} to '{new_title}' "
            f"(appended '{title}').")


@mcp.tool()
def create_folder(name: str) -> dict:
    """Create a new Notes folder (or return an existing one) via direct SwiftData write.

    Args:
      name: folder display name (e.g. "Recipes"). Matched case-insensitively
        against existing folder names — duplicates are NOT created; the
        existing folder is returned with ``created: False``. Whitespace-only
        names return ``{"ok": False, "error": ...}``.

    Bypasses the UI; writes to the app's SwiftData store and relaunches.

    Returns:
      ``{"ok": bool, "folder_id": int, "name": str, "created": bool,
        "message": str}`` on success.
    """
    folder_name = (name or "").strip()
    if not folder_name:
        return {"ok": False, "error": "folder name is required"}
    db = _notes_db()
    if not db:
        return {"ok": False, "error": "notes store not found"}
    cur = db.cursor()
    cur.execute(
        "SELECT Z_PK, ZNAME FROM ZNOTEFOLDER WHERE LOWER(ZNAME) = LOWER(?) LIMIT 1",
        (folder_name,),
    )
    row = cur.fetchone()
    if row:
        db.close()
        return {
            "ok": True,
            "folder_id": row[0],
            "name": row[1],
            "created": False,
            "message": f"Folder '{row[1]}' already exists.",
        }
    cur.execute("UPDATE Z_PRIMARYKEY SET Z_MAX = Z_MAX + 1 WHERE Z_NAME = 'NoteFolder'")
    cur.execute("SELECT Z_MAX FROM Z_PRIMARYKEY WHERE Z_NAME = 'NoteFolder'")
    new_pk_row = cur.fetchone()
    if not new_pk_row:
        db.close()
        return {"ok": False, "error": "NoteFolder primary key metadata not found"}
    cur.execute("SELECT COALESCE(MAX(ZSORTORDER), -1) + 1 FROM ZNOTEFOLDER")
    sort_order = cur.fetchone()[0]
    new_pk = new_pk_row[0]
    cur.execute(
        "INSERT INTO ZNOTEFOLDER (Z_PK, Z_ENT, Z_OPT, ZSORTORDER, ZNAME) VALUES (?, 2, 1, ?, ?)",
        (new_pk, sort_order, folder_name),
    )
    db.commit()
    db.close()
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "folder_id": new_pk,
        "name": folder_name,
        "created": True,
        "message": f"Created folder '{folder_name}'.",
    }


@mcp.tool()
def search_notes(query: str) -> dict:
    """Search notes by title or body, case-insensitively.

    Args:
      query: free-text search string. Matches notes whose title or full
        body contains `query` (case-insensitive). Empty string returns all
        active (non-trashed) notes.

    Resolved directly from the app's store (the SwiftUI ``.searchable`` bar
    has no stable accessibility id, and driving it blind would risk typing
    the query into a focused note editor). This is overlay-proof: it returns
    the correct matches no matter what UI state you call it from — a folder
    list, an open note editor, the search overlay, or a fresh launch.

    Returns:
      ``{"query": str, "notes": [<title_slug>, ...], "count": int,
        "matches": [{"id": int, "title": str, "folder": str}, ...]}`` —
      slugs are the REAL ``note_row_<slug>`` ids, openable via open_note.
    """
    q = (query or "").lower()
    db = _notes_db()
    if not db:
        return {"query": query, "notes": [], "count": 0, "matches": [],
                "error": "notes store not found"}
    rows = db.execute(
        """SELECT n.Z_PK, n.ZTITLE, n.ZBODY, f.ZNAME, n.ZISINTRASH,
                  n.ZMODIFIEDDATE
           FROM ZNOTE n LEFT JOIN ZNOTEFOLDER f ON n.ZFOLDER = f.Z_PK"""
    ).fetchall()
    db.close()
    matches = []
    for pk, title, body, folder, trashed, mod in rows:
        if trashed:
            continue
        hay = f"{title or ''}\n{body or ''}".lower()
        if not q or q in hay:
            matches.append({"id": pk, "title": title or "",
                            "folder": folder or "Notes", "mod": mod or 0})
    matches.sort(key=lambda m: m["mod"], reverse=True)
    slugs = [_row_slug(m["title"]) for m in matches]
    clean = [{"id": m["id"], "title": m["title"], "folder": m["folder"]}
             for m in matches]
    return {"query": query, "notes": slugs, "count": len(slugs),
            "matches": clean}


@mcp.tool()
def read_note(title: str = "") -> dict:
    """Read the title and body of a note.

    Args:
      title: OPTIONAL note title/id. When given, self-navigates and opens
        that note first (blind-call safe). When omitted, reads whatever note
        is currently open in the editor.

    Returns:
      ``{"title": str | None, "body": str | None}`` — read live from the
      editor fields. If the editor isn't visible, falls back to the note's
      stored content from the data layer so a read still succeeds.
    """
    sim = SimulatorBridge.get()
    if title:
        note, ok = _open_note_robust(sim, title)
        if not ok and note is not None:
            # Couldn't open the UI, but we know the note — return stored data.
            db = _notes_db()
            if db:
                row = db.execute(
                    "SELECT ZTITLE, ZBODY FROM ZNOTE WHERE Z_PK = ?",
                    (note["id"],)).fetchone()
                db.close()
                if row:
                    return {"title": row[0] or None, "body": row[1] or None}
        if not ok and note is None:
            return {"ok": False, "title": None, "body": None,
                    "error": f"No note matching '{title}'"}
    title_value = _read(sim, "notes_title_field") or None
    body_value = _read(sim, "notes_body_editor") or None
    if title_value is None and body_value is None:
        return {
            "ok": False,
            "title": None,
            "body": None,
            "error": "No note editor is open. Pass title=<note title/id> or open a note first.",
        }
    return {"title": title_value, "body": body_value}


# ── Direct-state-write tools (Notes uses SwiftData; we mutate the
# default.store SQLite database directly, then relaunch so the app
# re-reads). Schema: ZNOTE(Z_PK, ZTITLE, ZBODY, ZFOLDER FK→ZNOTEFOLDER,
# ZCREATEDDATE, ZMODIFIEDDATE, ZTRASHEDDATE, ZISINTRASH, ZISPINNED) +
# ZNOTEFOLDER(Z_PK, ZNAME, ZSORTORDER).

def _notes_db():
    return dl.open_sqlite(BUNDLE_ID, "Library/Application Support/default.store")


def _core_data_now():
    """Core-Data's reference timestamp is seconds since 2001-01-01."""
    import datetime as _dt
    epoch = _dt.datetime(2001, 1, 1, tzinfo=_dt.timezone.utc)
    return (_dt.datetime.now(_dt.timezone.utc) - epoch).total_seconds()


@mcp.tool()
def list_notes_with_meta() -> dict:
    """List ALL notes (across every folder) directly from the SwiftData store.

    Bypasses the UI; sees notes that aren't on screen, including pinned and
    trashed ones, ordered by most-recently-modified first.

    Returns:
      ``{"notes": [{"id": int, "title": str, "body_preview": str (<=80 chars),
        "body_len": int, "folder": str, "pinned": bool, "trashed": bool}, ...],
        "count": int}``.
    """
    db = _notes_db()
    if not db: return {"ok": False, "error": "notes store not found"}
    cur = db.execute("""
        SELECT n.Z_PK, n.ZTITLE, n.ZBODY, f.ZNAME, n.ZMODIFIEDDATE,
               n.ZISPINNED, n.ZISINTRASH
        FROM ZNOTE n LEFT JOIN ZNOTEFOLDER f ON n.ZFOLDER = f.Z_PK
        ORDER BY n.ZMODIFIEDDATE DESC""")
    out = []
    for pk, title, body, folder, mod, pinned, trashed in cur.fetchall():
        out.append({"id": pk, "title": title or "",
                    "body_preview": (body or "")[:80],
                    "body_len": len(body or ""),
                    "folder": folder or "Notes",
                    "pinned": bool(pinned), "trashed": bool(trashed)})
    db.close()
    return {"notes": out, "count": len(out)}


@mcp.tool()
def create_note_direct(title: str, body: str = "", folder: str = "Notes") -> dict:
    """Create a new note via direct SwiftData write (no UI taps).

    Args:
      title: title for the new note. Empty string is allowed (untitled).
      body: optional body text.
      folder: folder display name. Matched exact first, then
        case-insensitively against ZNAME (e.g. "Notes", "Personal", "Work").
        Get available names from list_notes_with_meta()/search_notes()
        ``folder`` fields or create_folder(). Unknown folders return
        ``ok:false`` instead of silently writing elsewhere.

    Returns:
      ``{"ok": True, "note_id": int, "title": str, "folder": str,
        "message": str}``.
    """
    db = _notes_db()
    if not db: return {"ok": False, "error": "notes store not found"}
    cur = db.cursor()
    # Find folder. Never silently fall back to another folder while reporting
    # the requested one; that creates false success in cross-app workflows.
    requested_folder = (folder or "Notes").strip()
    if requested_folder.lower() in ("all", "all icloud", "icloud"):
        requested_folder = "Notes"
    cur.execute(
        "SELECT Z_PK, ZNAME FROM ZNOTEFOLDER WHERE ZNAME = ? LIMIT 1",
        (requested_folder,),
    )
    row = cur.fetchone()
    if not row:
        cur.execute(
            "SELECT Z_PK, ZNAME FROM ZNOTEFOLDER WHERE lower(ZNAME) = lower(?) LIMIT 1",
            (requested_folder,),
        )
        row = cur.fetchone()
    if not row:
        cur.execute("SELECT ZNAME FROM ZNOTEFOLDER ORDER BY ZNAME")
        available = [r[0] for r in cur.fetchall()]
        db.close()
        return {
            "ok": False,
            "error": f"No folder matching '{folder}'.",
            "available_folders": available,
        }
    folder_pk, actual_folder = row[0], row[1]
    now = _core_data_now()
    # Bump Z_PRIMARYKEY.Z_MAX for ZNOTE (entity 1)
    cur.execute("UPDATE Z_PRIMARYKEY SET Z_MAX = Z_MAX + 1 WHERE Z_NAME = 'Note'")
    cur.execute("SELECT Z_MAX FROM Z_PRIMARYKEY WHERE Z_NAME = 'Note'")
    new_pk = cur.fetchone()[0]
    cur.execute("""
        INSERT INTO ZNOTE (Z_PK, Z_ENT, Z_OPT, ZISINTRASH, ZISPINNED, ZFOLDER,
                           ZCREATEDDATE, ZMODIFIEDDATE, ZTITLE, ZBODY)
        VALUES (?, 1, 1, 0, 0, ?, ?, ?, ?, ?)
    """, (new_pk, folder_pk, now, now, title, body))
    db.commit()
    db.close()
    try:
        dl.reload_app(BUNDLE_ID)
    except Exception as exc:
        return {"ok": True, "note_id": new_pk, "title": title, "folder": actual_folder,
                "warning": f"Created note, but app reload failed: {exc}",
                "message": f"Created note '{title}' in {actual_folder}."}
    return {"ok": True, "note_id": new_pk, "title": title, "folder": actual_folder,
            "message": f"Created note '{title}' in {actual_folder}."}


@mcp.tool()
def append_to_note(title_or_id: str, text: str) -> dict:
    """Append text to an existing note's body via direct SwiftData write.

    Args:
      title_or_id: numeric Z_PK as a string (e.g. "42", from the ``id``
        field of list_notes_with_meta/search_notes/create_note_direct) —
        tried first — or a case-insensitive substring of the note's REAL
        title (with spaces, NOT the underscore slug). Ambiguous substring
        matches fall back to the first hit (no controlled failure).
      text: text to append. Always prepended with a single newline so it
        starts on a new line.

    Returns:
      ``{"ok": True, "note_id": int, "title": str, "new_body_len": int,
        "message": str}`` on success.
    """
    db = _notes_db()
    if not db: return {"ok": False, "error": "notes store not found"}
    cur = db.cursor()
    # Try by Z_PK first
    target = None
    try:
        pk = int(title_or_id)
        cur.execute("SELECT Z_PK, ZTITLE, ZBODY FROM ZNOTE WHERE Z_PK = ?", (pk,))
        target = cur.fetchone()
    except (TypeError, ValueError):
        pass
    if not target:
        cur.execute("SELECT Z_PK, ZTITLE, ZBODY FROM ZNOTE WHERE LOWER(ZTITLE) LIKE ? LIMIT 1",
                    (f"%{title_or_id.lower()}%",))
        target = cur.fetchone()
    if not target:
        cur.execute("SELECT ZTITLE FROM ZNOTE LIMIT 10")
        titles = [r[0] for r in cur.fetchall()]
        db.close()
        return {"ok": False, "error": f"No note matching '{title_or_id}'", "available": titles}
    pk, title, body = target
    new_body = (body or "") + "\n" + text
    cur.execute("UPDATE ZNOTE SET ZBODY = ?, ZMODIFIEDDATE = ? WHERE Z_PK = ?",
                (new_body, _core_data_now(), pk))
    db.commit()
    db.close()
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "note_id": pk, "title": title,
            "new_body_len": len(new_body),
            "message": f"Appended {len(text)} chars to '{title}'."}


@mcp.tool()
def edit_note_direct(title_or_id: str, new_title: str = "", new_body: str = "") -> dict:
    """Replace the title and/or body of an existing note via direct SwiftData write.

    Args:
      title_or_id: numeric Z_PK as a string (from the ``id`` field of
        list_notes_with_meta/search_notes) — tried first — or a
        case-insensitive substring of the note's REAL title (with spaces,
        NOT the underscore slug). First substring hit wins.
      new_title: replacement title. Empty string leaves the title unchanged
        (so passing "" can NOT be used to clear a title).
      new_body: replacement body. Empty string leaves the body unchanged.

    Returns:
      ``{"ok": True, "note_id": int, "title": str, "message": str}``.
    """
    db = _notes_db()
    if not db: return {"ok": False, "error": "notes store not found"}
    cur = db.cursor()
    target = None
    try:
        pk = int(title_or_id)
        cur.execute("SELECT Z_PK, ZTITLE, ZBODY FROM ZNOTE WHERE Z_PK = ?", (pk,))
        target = cur.fetchone()
    except (TypeError, ValueError):
        pass
    if not target:
        cur.execute("SELECT Z_PK, ZTITLE, ZBODY FROM ZNOTE WHERE LOWER(ZTITLE) LIKE ? LIMIT 1",
                    (f"%{title_or_id.lower()}%",))
        target = cur.fetchone()
    if not target:
        return {"ok": False, "error": f"No note matching '{title_or_id}'"}
    pk, old_title, old_body = target
    title_to_use = new_title if new_title else old_title
    body_to_use = new_body if new_body else old_body
    cur.execute("UPDATE ZNOTE SET ZTITLE=?, ZBODY=?, ZMODIFIEDDATE=? WHERE Z_PK=?",
                (title_to_use, body_to_use, _core_data_now(), pk))
    db.commit(); db.close(); dl.reload_app(BUNDLE_ID)
    return {"ok": True, "note_id": pk, "title": title_to_use,
            "message": f"Updated note {pk}."}


if __name__ == "__main__":
    mcp.run()
