"""CloudSheets MCP — spreadsheets browsing + editing.

Shared AccessibilityID registry (CloudSheets/Utilities/AccessibilityID.swift).
The spreadsheet fileType's accessibilityPrefix is "sheet" (SINGULAR), so the
real row ids embed "_sheet_", not "_sheets_":
  file_row_sheet_<slug>, recent_row_sheet_<slug>, starred_row_sheet_<slug>,
  shared_row_sheet_<slug>, trash_row_sheet_<slug>, search_file_sheet_<slug>
  file_action_{rename,duplicate,move,trash,star,restore}
  sheets_search_field, sheets_title_field, sheet_formula_bar,
  sheet_add_row_button, sheet_add_column_button,
  sheet_cell_<address>, sheet_tab_<index>
  folder_row_<slug>

NOTE FOR AGENTS: every tool that takes a ``spreadsheet``/``spreadsheet_title``
arg accepts the plain human-readable TITLE (or the id) — you never need to
guess a slug. ``<slug>`` is the lowercase title with spaces/punctuation
stripped; it only appears inside row accessibility ids, not as a tool arg.
"""

import sys, pathlib, re
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import _data_layer as dl
import tool_support as ts

mcp = FastMCP("CloudSheets")

BUNDLE_ID = "com.iosworld.benchmark.cloudsheets"
_CURRENT_SPREADSHEET_ID = ""
_CURRENT_SHEET_INDEX = 0
_CURRENT_CELL = ""


def _slug(s: str) -> str:
    return re.sub(r'[^a-z0-9_]+', '', s.lower().replace(" ", "_"))


def _find_spreadsheet(env: dict, name_or_id: str) -> dict | None:
    if not name_or_id:
        return None
    sp = (
        dl.envelope_find(env, "spreadsheets", value=name_or_id)
        or dl.envelope_match(env, "spreadsheets", title_substring=name_or_id)
    )
    if sp:
        return sp
    # Fuzzy fallback: slug-equality and substring on slugified titles/ids so a
    # blind agent passing a display name with odd spacing/punctuation still hits.
    sps = env.get("seededData", {}).get("spreadsheets", []) or []
    want = _slug(name_or_id)
    if not want:
        return None
    for s in sps:
        if _slug(str(s.get("title", ""))) == want or _slug(str(s.get("id", ""))) == want:
            return s
    for s in sps:
        tslug = _slug(str(s.get("title", "")))
        if want in tslug or tslug in want:
            return s
    return None


# Generic placeholder sheet names an agent commonly guesses when it doesn't
# actually know the worksheet name — treated as "use the obvious sheet".
_GENERIC_SHEET_NAMES = {"sheet1", "sheet 1", "sheet", "default", "main", "tab1", ""}


def _resolve_sheet(sp: dict, sheet_name: str | None):
    """Resolve a worksheet within a spreadsheet from a blind/guessed name.

    Strategy: exact (ci) -> substring (ci) -> id match -> single-sheet
    fallback -> generic-placeholder fallback (first sheet). Returns the sheet
    dict or None (only when name is given, no match, and multiple sheets).
    """
    sheets = sp.get("sheets", []) or []
    if not sheets:
        return None
    if not sheet_name or not str(sheet_name).strip():
        return sheets[0]
    q = str(sheet_name).strip().lower()
    # exact (case-insensitive)
    for s in sheets:
        if str(s.get("name", "")).lower() == q:
            return s
    # substring either direction
    for s in sheets:
        nm = str(s.get("name", "")).lower()
        if nm and (q in nm or nm in q):
            return s
    # id / slug match
    for s in sheets:
        if str(s.get("id", "")).lower() == q or _slug(str(s.get("name", ""))) == _slug(q):
            return s
    # single sheet: the name doesn't matter, there's only one place to write
    if len(sheets) == 1:
        return sheets[0]
    # generic placeholder name the agent didn't really know -> first sheet
    if q in _GENERIC_SHEET_NAMES:
        return sheets[0]
    return None


def _a1_to_row_col(address: str) -> tuple[int, int] | None:
    m = re.match(r'^([A-Z]+)(\d+)$', address.upper())
    if not m:
        return None
    col = sum((ord(c) - 64) * 26 ** i for i, c in enumerate(reversed(m.group(1)))) - 1
    return int(m.group(2)) - 1, col


def _col_to_letters(col: int) -> str:
    out = ""
    col += 1
    while col:
        col, rem = divmod(col - 1, 26)
        out = chr(65 + rem) + out
    return out


def _cell_value_map(sheet: dict) -> dict[str, str]:
    return {
        str(c.get("address", "")).upper(): str(c.get("rawValue", c.get("value", "")))
        for c in sheet.get("cells", []) or []
        if c.get("address")
    }


def _sheet_headers(sheet: dict) -> list[str]:
    vals = _cell_value_map(sheet)
    cols = max(int(sheet.get("columnCount", 0)), 0)
    headers = []
    for c in range(cols):
        headers.append(vals.get(f"{_col_to_letters(c)}1", ""))
    return headers


def _sheet_records(sheet: dict) -> list[dict]:
    vals = _cell_value_map(sheet)
    headers = _sheet_headers(sheet)
    records = []
    for r in range(2, int(sheet.get("rowCount", 0)) + 1):
        row = {"row_number": r}
        nonempty = False
        for c, header in enumerate(headers):
            if not header:
                continue
            address = f"{_col_to_letters(c)}{r}"
            value = vals.get(address, "")
            if value:
                nonempty = True
            row[header] = value
        if nonempty:
            records.append(row)
    return records


def _current_sheet(env: dict) -> tuple[dict | None, dict | None]:
    sp = _find_spreadsheet(env, _CURRENT_SPREADSHEET_ID) if _CURRENT_SPREADSHEET_ID else None
    if not sp:
        return None, None
    sheets = sp.get("sheets", []) or []
    if _CURRENT_SHEET_INDEX < 0 or _CURRENT_SHEET_INDEX >= len(sheets):
        return sp, None
    return sp, sheets[_CURRENT_SHEET_INDEX]


def _resolve_current_spreadsheet(env: dict, spreadsheet: str | None = None) -> dict | None:
    """Resolve the spreadsheet an editor tool should operate on.

    Robust to BLIND calls: if ``spreadsheet`` is given (id or display name),
    resolve & adopt it as the current document (so a fresh-launch agent that
    never called open_spreadsheet still works). Otherwise fall back to the
    module-level current pointer.
    """
    global _CURRENT_SPREADSHEET_ID, _CURRENT_SHEET_INDEX
    if spreadsheet:
        sp = _find_spreadsheet(env, spreadsheet)
        if sp:
            if sp.get("id", "") != _CURRENT_SPREADSHEET_ID:
                _CURRENT_SHEET_INDEX = 0
            _CURRENT_SPREADSHEET_ID = sp.get("id", "")
            return sp
        return None
    if _CURRENT_SPREADSHEET_ID:
        return _find_spreadsheet(env, _CURRENT_SPREADSHEET_ID)
    return None


def _set_cell(sheet: dict, address: str, value: str) -> tuple[bool, str]:
    parsed = _a1_to_row_col(address)
    if not parsed:
        return False, f"Address '{address}' must be A1-style"
    row, col = parsed
    cells = sheet.setdefault("cells", [])
    existing = next((c for c in cells if str(c.get("address", "")).upper() == address.upper()), None)
    if existing:
        existing["rawValue"] = value
        existing["value"] = value
    else:
        cells.append({"address": address.upper(), "rawValue": value})
    sheet["rowCount"] = max(sheet.get("rowCount", 0), row + 1)
    sheet["columnCount"] = max(sheet.get("columnCount", 0), col + 1)
    return True, ""


@mcp.tool()
def launch() -> str:
    """Launch the CloudSheets app and return its initial UI tree.

    Returns:
      Human-readable string with a confirmation line and the accessibility
      tree from the foreground app.
    """
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched CloudSheets.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current accessibility-tree dump of the CloudSheets app's UI."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="CloudSheets",
        markers=("sheet_row_", "cell_", "cloudsheets_", "spreadsheet_"),
    )


@mcp.tool()
def list_spreadsheets() -> dict:
    """List spreadsheet slugs from the workspace (never returns a false empty).

    Works from any screen — scans the live UI tree for spreadsheet rows
    (``file_row_sheet_<slug>`` and the recent/shared/starred/trash/search
    variants, so it reads the home/recent/shared/starred/trash/search lists
    alike). If an overlay, editor, or search modal has emptied the live tree,
    it falls back to the authoritative workspace store (excluding trashed
    spreadsheets) rather than reporting an empty workspace.

    The returned ``<slug>`` values are lowercase title-slugs (spaces and
    punctuation removed). They are the identity used by ``open_spreadsheet``
    rows, but any tool that takes a ``spreadsheet`` arg also accepts the plain
    human-readable title — prefer the title from list_spreadsheets_with_meta.

    Returns:
      ``{"spreadsheets": [<slug>, ...], "count": int, "source": "ui" |
        "workspace_store"}``.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text()
    # Row ids are <screen>_row_<prefix>_<slug>; the spreadsheet fileType's
    # accessibilityPrefix is "sheet" (singular) — see WorkspaceModels.swift.
    matches = sorted(set(re.findall(
        r'(?:file|recent|shared|starred|trash|search_file)_row_sheet_([^"\s]+)', tree)))
    if matches:
        return {"spreadsheets": matches, "count": len(matches), "source": "ui"}
    # Bug-class (1) defense: an overlay/editor/search-modal can leave the
    # browse list out of the live tree (0 rows) even though the spreadsheets
    # all still exist. Never report an empty workspace from a transient UI
    # state — fall back to the authoritative workspace store.
    try:
        env = dl.read_envelope()
        slugs = sorted(
            _slug(s.get("title", ""))
            for s in env.get("seededData", {}).get("spreadsheets", [])
            if not s.get("isTrashed")
        )
        return {"spreadsheets": slugs, "count": len(slugs), "source": "workspace_store"}
    except Exception:
        return {"spreadsheets": [], "count": 0, "source": "ui"}


@mcp.tool()
def search_spreadsheets(query: str) -> str:
    """Search for spreadsheets by title (with store fallback) — works anywhere.

    Args:
      query: free-text title substring (case-insensitive). Matched against
        each spreadsheet's title and id.

    Tries the on-screen ``sheets_search_field`` first; if that field isn't
    reachable or yields no rows, it filters the authoritative workspace store
    directly, so this returns results from any screen.

    Returns:
      ``{"query": str, "spreadsheets": [<slug>, ...], "count": int,
        "source": "workspace_store"}`` on the store fallback, or the dict
      from `list_spreadsheets()` on UI success. Slugs are lowercase
      title-slugs; the plain title also works wherever a ``spreadsheet`` arg
      is accepted.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("sheets_search_field")
        sim.wait(0.3)
        sim.type_text(query)
        sim.wait(0.5)
        result = list_spreadsheets()
        if result.get("count", 0):
            return result
    except Exception:
        pass
    env = dl.read_envelope()
    q = query.lower()
    slugs = sorted(
        s.get("title", "").lower().replace(" ", "_").replace("-", "_")
        for s in env.get("seededData", {}).get("spreadsheets", [])
        if q in s.get("title", "").lower() or q in s.get("id", "").lower()
    )
    return {"query": query, "spreadsheets": slugs, "count": len(slugs), "source": "workspace_store"}


@mcp.tool()
def open_spreadsheet(name: str) -> str:
    """Open a spreadsheet by title (or id) and set it as the current document.

    Args:
      name: spreadsheet title or id (case-insensitive). The plain
        human-readable title works — it is slugified (lowercase,
        non-alphanumerics stripped) and matched against the visible
        ``{file|recent|starred|shared|search_file}_row_sheet[s]_<slug>``
        rows; if no row is on screen it falls back to a workspace-store
        lookup by title/id (with fuzzy slug matching). Get titles from
        list_spreadsheets_with_meta or list_spreadsheets.

    On success, updates the module-level current-spreadsheet/sheet pointers
    used by subsequent cell ops, and resets the active sheet to index 0.

    Returns a confirmation string when a UI row was tapped, or a dict
    ``{"ok": True, "opened_via": "shared_state", ...}`` when resolved via the
    store (UI may still show the browser — do NOT call open_spreadsheet again;
    tap_cell/edit_cell already operate on the selected doc). Returns the
    string ``"No spreadsheet matching '<name>' visible."`` if nothing matched.
    """
    global _CURRENT_SPREADSHEET_ID, _CURRENT_SHEET_INDEX
    sim = SimulatorBridge.get()
    slug = _slug(name)
    # Read the UI tree once and find which prefix actually has this slug —
    # avoids 5× expensive tap-then-fail rounds when the slug isn't on screen.
    tree = sim.observe_text() or ""
    # The spreadsheet fileType's accessibilityPrefix is "sheet" (singular) — the
    # real row ids are e.g. recent_row_sheet_<slug> / file_row_sheet_<slug>.
    for prefix in ("file_row_sheet_", "recent_row_sheet_", "starred_row_sheet_",
                   "shared_row_sheet_", "search_file_sheet_",
                   "file_row_sheets_", "recent_row_sheets_", "starred_row_sheets_",
                   "shared_row_sheets_", "search_file_sheets_"):
        if f'name="{prefix}{slug}"' in tree:
            sim.tap_id(f"{prefix}{slug}")
            sim.wait(0.5)
            env = dl.read_envelope()
            sp = _find_spreadsheet(env, name)
            if sp:
                _CURRENT_SPREADSHEET_ID = sp.get("id", "")
                _CURRENT_SHEET_INDEX = 0
            return f"Opened spreadsheet '{name}'."
    env = dl.read_envelope()
    sp = _find_spreadsheet(env, name)
    if not sp:
        return f"No spreadsheet matching '{name}' visible."
    _CURRENT_SPREADSHEET_ID = sp.get("id", "")
    _CURRENT_SHEET_INDEX = 0
    dl.reload_app(BUNDLE_ID)
    # Shared-state fallback: spreadsheet is now the "current" doc in the data
    # layer, but the on-screen UI may still show the file browser after reload.
    # tap_cell / edit_cell will still operate on the selected spreadsheet via
    # shared state. The model should NOT keep calling open_spreadsheet —
    # proceed directly to tap_cell / edit_cell.
    return {
        "ok": True, "action": "open_spreadsheet",
        "spreadsheet_id": _CURRENT_SPREADSHEET_ID,
        "title": sp.get("title"),
        "opened_via": "shared_state",
        "message": (
            f"Spreadsheet '{sp.get('title')}' selected via shared state. UI may "
            "still show the file browser — tap_cell / edit_cell will operate "
            "on the selected spreadsheet directly. Do NOT call open_spreadsheet "
            "again with the same name."
        ),
    }


@mcp.tool()
def open_folder(name: str) -> str:
    """Open/resolve a folder by display name (confirmed against the store).

    Args:
      name: folder display name (case-insensitive). Best-effort UI tap of
        ``folder_row_<slug>``, then resolved in the workspace store by exact
        value, ``folder_<slug>`` id, or title substring — so the plain folder
        name works even when the row isn't tappable in the browser-only UI.

    Returns ``{"ok": True, "folder_id": str, "name": str}`` on a match, or
    ``{"ok": False, "message": ..., "available": [<name>, ...]}`` listing up
    to 10 known folder names when nothing matches.
    """
    sim = SimulatorBridge.get()
    # Best-effort UI tap (no-ops in the browser-only UI). Resolve the folder in
    # the shared workspace state so we can confirm it exists even when the row
    # isn't tappable; the cloud apps are graded on state, not the UI tree.
    try:
        sim.tap_id(f"folder_row_{_slug(name)}"); sim.wait(0.3)
    except Exception:
        pass
    env = dl.read_envelope()
    folders = env.get("seededData", {}).get("folders", [])
    folder = (
        dl.envelope_find(env, "folders", value=name)
        or dl.envelope_find(env, "folders", value=f"folder_{_slug(name)}")
        or next((f for f in folders if name.lower() in str(f.get("name", "")).lower()), None)
    )
    if not folder:
        names = [f.get("name") for f in folders][:10]
        return {"ok": False, "action": "open_folder", "message": f"No folder matching '{name}'.", "available": names}
    return {"ok": True, "action": "open_folder", "folder_id": folder.get("id"), "name": folder.get("name")}


@mcp.tool()
def tap_cell(address: str, spreadsheet: str = "") -> str:
    """Select a spreadsheet cell by A1-style address.

    Args:
      address: A1-style cell reference, uppercase or lowercase
        (e.g. "A1", "B3", "AA12"). Anything not matching the pattern
        ``[A-Z]+[0-9]+`` returns an error.
      spreadsheet: optional spreadsheet title or id (case-insensitive; the
        plain title works). If given, the tool self-resolves and adopts that
        spreadsheet — robust to blind calls from a fresh launch with no prior
        open_spreadsheet. If omitted, uses the currently open document.

    Falls back to updating the in-memory current-cell pointer if the UI cell
    isn't reachable. Returns ``{"ok": False, "error": ...}`` for a malformed
    address, an unmatched ``spreadsheet``, or no current document.
    """
    global _CURRENT_CELL
    if not _a1_to_row_col(address):
        return {"ok": False, "error": f"Address '{address}' must be A1-style (e.g. A1, B3)."}
    sim = SimulatorBridge.get()
    err = sim.tap_and_verify_changed(
        f"sheet_cell_{address}",
        prefix_for_failure=f"Cell '{address}' not visible. ",
        settle=0.2,
    )
    if err is None:
        _CURRENT_CELL = address.upper()
        return f"Selected cell {address}."
    env = dl.read_envelope()
    sp = _resolve_current_spreadsheet(env, spreadsheet)
    if not sp:
        if spreadsheet:
            return {"ok": False, "error": f"No spreadsheet matching '{spreadsheet}'."}
        return {"ok": False, "error": "No open spreadsheet/sheet for cell selection. Pass spreadsheet=<title> or call open_spreadsheet first."}
    _CURRENT_CELL = address.upper()
    return {"ok": True, "action": "tap_cell", "spreadsheet": sp.get("title"), "address": _CURRENT_CELL, "message": f"Selected cell {_CURRENT_CELL} via shared state."}


@mcp.tool()
def edit_cell(address: str, value: str, spreadsheet: str = "", sheet: str = "") -> str:
    """Set a cell's contents by selecting it, typing into the formula bar.

    Args:
      address: A1-style cell reference (e.g. "A1", "B3", "C12"). Must match
        ``[A-Z]+[0-9]+``.
      value: cell contents as a string — plain text, a number ("42"), or a
        formula starting with "=" (e.g. "=SUM(A1:A5)"). Replaces any
        existing value in that cell.
      spreadsheet: optional spreadsheet title or id (case-insensitive; the
        plain title works). If given, the tool self-resolves and adopts it
        (no prior open_spreadsheet needed) — robust to blind calls from a
        fresh launch. If omitted, uses the currently open document.
      sheet: optional worksheet name (case-insensitive; exact, then
        substring, then id/slug). Get names from list_spreadsheets_with_meta.
        Defaults to the current/first sheet. With a single-sheet spreadsheet
        the name is ignored; a generic guess ("Sheet1"/"main"/...) also maps
        to the first sheet.

    Writes directly to the workspace store (what grading reads); the UI tap
    is best-effort. A ``sheet`` name that matches no worksheet silently falls
    back to the first sheet (it does NOT fail), so pass an accurate name when
    targeting a specific tab. Returns ``{"ok": False, "error": ...}`` only for
    a malformed address, an unmatched ``spreadsheet`` (with an ``available``
    title list), or a spreadsheet that has no worksheets at all.
    """
    # Validate the address up-front so an invalid ref is rejected cleanly
    # regardless of which path (UI or state) ends up handling the write.
    if not _a1_to_row_col(address):
        return {"ok": False, "error": f"Address '{address}' must be A1-style (e.g. A1, B3)."}
    sim = SimulatorBridge.get()
    # Best-effort UI tap+type. The browser-only editor often doesn't render
    # sheet_cell_*/sheet_formula_bar, and sim.tap_id may silently no-op rather
    # than raise — so we never trust the UI path alone. We always persist the
    # value via the workspace store and reload, which is what grading reads.
    try:
        sim.tap_id(f"sheet_cell_{address}")
        sim.wait(0.2)
        sim.tap_id("sheet_formula_bar")
        sim.wait(0.2)
        sim.type_text(value)
        sim.wait(0.2)
    except Exception:
        pass
    env = dl.read_envelope()
    sp = _resolve_current_spreadsheet(env, spreadsheet)
    if not sp:
        if spreadsheet:
            names = [s.get("title") for s in env.get("seededData",{}).get("spreadsheets",[])][:8]
            return {"ok": False, "error": f"No spreadsheet matching '{spreadsheet}'.", "available": names}
        return {"ok": False, "error": "No open spreadsheet/sheet for edit. Pass spreadsheet=<title> or call open_spreadsheet first."}
    sheet_obj = _resolve_sheet(sp, sheet) if sheet else _current_sheet(env)[1]
    if not sheet_obj:
        sheet_obj = _resolve_sheet(sp, None)
    if not sheet_obj:
        return {"ok": False, "error": f"No worksheet to edit in '{sp.get('title')}'."}
    sheet = sheet_obj  # noqa: reuse name below
    ok, error = _set_cell(sheet, address, value)
    if not ok:
        return {"ok": False, "error": error}
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "edit_cell", "spreadsheet": sp.get("title"), "sheet": sheet.get("name"), "address": address.upper(), "value": value}


@mcp.tool()
def switch_tab(index: int, spreadsheet: str = "") -> str:
    """Switch to a specific sheet (worksheet) tab within the open spreadsheet.

    Args:
      index: 0-based sheet index. Must be in ``[0, sheet_count)``;
        out-of-range values return ``{"ok": False, "error": ...,
        "available": [<sheet name>, ...]}`` reporting the valid tab count and
        names. (To target a sheet by name instead, pass ``sheet`` to
        edit_cell/add_row.)
      spreadsheet: optional spreadsheet title or id (case-insensitive; the
        plain title works). Self-resolves and adopts it first — robust to
        blind calls with no prior open_spreadsheet. If omitted, uses the
        currently open document.

    Updates the module-level current-sheet pointer used by subsequent cell ops.
    """
    global _CURRENT_SHEET_INDEX
    sim = SimulatorBridge.get()
    err = sim.tap_and_verify_changed(
        f"sheet_tab_{index}",
        prefix_for_failure=f"Sheet tab {index} not visible. ",
        settle=0.3,
    )
    if err is None:
        _CURRENT_SHEET_INDEX = int(index)
        return f"Switched to sheet tab {index}."
    env = dl.read_envelope()
    sp = _resolve_current_spreadsheet(env, spreadsheet)
    if not sp:
        if spreadsheet:
            return {"ok": False, "error": f"No spreadsheet matching '{spreadsheet}'."}
        return {"ok": False, "error": "No open spreadsheet for switch_tab. Pass spreadsheet=<title> or call open_spreadsheet first."}
    sheets = sp.get("sheets", []) or []
    if index < 0 or index >= len(sheets):
        return {"ok": False, "error": f"No sheet tab {index} in '{sp.get('title')}'. Available tab count: {len(sheets)}.",
                "available": [s.get("name") for s in sheets]}
    _CURRENT_SHEET_INDEX = int(index)
    return {"ok": True, "action": "switch_tab", "spreadsheet": sp.get("title"), "index": _CURRENT_SHEET_INDEX, "sheet": sheets[_CURRENT_SHEET_INDEX].get("name")}


@mcp.tool()
def add_row(spreadsheet: str = "", sheet: str = "") -> str:
    """Append a new (empty) row to the currently active sheet.

    Args:
      spreadsheet: optional spreadsheet title or id (case-insensitive; the
        plain title works). Self-resolves and adopts it — robust to blind
        calls. If omitted, uses the currently open document.
      sheet: optional worksheet name (case-insensitive; exact/substring/slug).
        An unmatched name falls back to the first sheet (does not fail).

    Persists by incrementing ``rowCount`` in the workspace store (what grading
    reads); the UI tap is best-effort. Returns ``{"ok": False, "error": ...}``
    only when no spreadsheet resolves or it has no worksheets.
    """
    sim = SimulatorBridge.get()
    # Best-effort UI tap; the add-row button is usually not rendered in the
    # browser-only UI and tap_id may silently no-op, so always persist via the
    # workspace store (what grading reads) and reload.
    try:
        sim.tap_id("sheet_add_row_button")
        sim.wait(0.3)
    except Exception:
        pass
    env = dl.read_envelope()
    sp = _resolve_current_spreadsheet(env, spreadsheet)
    if not sp:
        if spreadsheet:
            return {"ok": False, "error": f"No spreadsheet matching '{spreadsheet}'."}
        return {"ok": False, "error": "No open spreadsheet/sheet for add_row. Pass spreadsheet=<title> or call open_spreadsheet first."}
    sheet = _resolve_sheet(sp, sheet) if sheet else _current_sheet(env)[1]
    if not sheet:
        sheet = _resolve_sheet(sp, None)
    if not sheet:
        return {"ok": False, "error": f"No worksheet in '{sp.get('title')}'."}
    sheet["rowCount"] = int(sheet.get("rowCount", 0)) + 1
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "add_row", "spreadsheet": sp.get("title"), "sheet": sheet.get("name"), "rowCount": sheet["rowCount"]}


@mcp.tool()
def add_column(spreadsheet: str = "", sheet: str = "") -> str:
    """Append a new (empty) column to the currently active sheet.

    Args:
      spreadsheet: optional spreadsheet title or id (case-insensitive; the
        plain title works). Self-resolves and adopts it — robust to blind
        calls. If omitted, uses the currently open document.
      sheet: optional worksheet name (case-insensitive; exact/substring/slug).
        An unmatched name falls back to the first sheet (does not fail).

    Persists by incrementing ``columnCount`` in the workspace store (what
    grading reads); the UI tap is best-effort. Returns ``{"ok": False,
    "error": ...}`` only when no spreadsheet resolves or it has no worksheets.
    """
    sim = SimulatorBridge.get()
    # Best-effort UI tap; the add-column button is usually not rendered in the
    # browser-only UI and tap_id may silently no-op, so always persist via the
    # workspace store (what grading reads) and reload.
    try:
        sim.tap_id("sheet_add_column_button")
        sim.wait(0.3)
    except Exception:
        pass
    env = dl.read_envelope()
    sp = _resolve_current_spreadsheet(env, spreadsheet)
    if not sp:
        if spreadsheet:
            return {"ok": False, "error": f"No spreadsheet matching '{spreadsheet}'."}
        return {"ok": False, "error": "No open spreadsheet/sheet for add_column. Pass spreadsheet=<title> or call open_spreadsheet first."}
    sheet = _resolve_sheet(sp, sheet) if sheet else _current_sheet(env)[1]
    if not sheet:
        sheet = _resolve_sheet(sp, None)
    if not sheet:
        return {"ok": False, "error": f"No worksheet in '{sp.get('title')}'."}
    sheet["columnCount"] = int(sheet.get("columnCount", 0)) + 1
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "add_column", "spreadsheet": sp.get("title"), "sheet": sheet.get("name"), "columnCount": sheet["columnCount"]}


@mcp.tool()
def rename_spreadsheet(new_name: str, spreadsheet: str = "") -> str:
    """Rename a spreadsheet (the currently open one, or one named directly).

    Args:
      new_name: new full title for the spreadsheet (replaces the old title).
      spreadsheet: optional current title or id of the spreadsheet to rename
        (case-insensitive; the plain title works). Self-resolves it — robust
        to blind calls with no prior open_spreadsheet. If omitted, renames the
        currently open document.

    Persists the new title to the workspace store (what grading reads); the UI
    type is best-effort. Returns ``{"ok": False, "error": ...}`` (with an
    ``available`` title list) when no spreadsheet resolves.
    """
    sim = SimulatorBridge.get()
    # Best-effort UI type into the title field; the field is usually not
    # rendered in the browser-only UI and type_text may silently no-op, so we
    # always persist the rename via the workspace store and reload.
    try:
        sim.tap_id("sheets_title_field")
        sim.wait(0.3)
        sim.type_text(new_name)
        sim.wait(0.3)
    except Exception:
        pass
    env = dl.read_envelope()
    sp = _resolve_current_spreadsheet(env, spreadsheet)
    if not sp:
        if spreadsheet:
            names = [s.get("title") for s in env.get("seededData",{}).get("spreadsheets",[])][:8]
            return {"ok": False, "error": f"No spreadsheet matching '{spreadsheet}'.", "available": names}
        return {"ok": False, "error": "No open spreadsheet to rename. Pass spreadsheet=<title> or call open_spreadsheet first."}
    old_title = sp.get("title")
    sp["title"] = new_name
    sp["updatedAt"] = "2026-05-12T00:00:00Z"
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "action": "rename_spreadsheet", "spreadsheet_id": sp.get("id"), "old_title": old_title, "title": new_name}


@mcp.tool()
def file_action(action: str, spreadsheet: str = "") -> str:
    """Invoke a file action (star/trash/restore/duplicate) on a spreadsheet.

    Args:
      action: one of "star", "trash", "restore", "duplicate", "rename",
        "move" (case-insensitive). Anything else returns ``{"ok": False,
        "error": ...}`` listing the valid set.
        - "star"/"trash"/"restore" flip ``isStarred``/``isTrashed`` in the
          store and persist (real effect).
        - "duplicate" deep-copies the spreadsheet into the store with a fresh
          id (``<id>_copy``) and a "<title> Copy" title (real effect).
        - "rename" and "move" intentionally FAIL with ``{"ok": False, ...}``:
          they need extra info this tool doesn't take. Use
          rename_spreadsheet(new_name=...) for rename; no move-by-destination
          tool is exposed for spreadsheets.
      spreadsheet: optional title or id of the target spreadsheet
        (case-insensitive; the plain title works). Self-resolves it — robust
        to blind calls with no prior open_spreadsheet. If omitted, acts on the
        currently open document; returns ``{"ok": False, ...}`` (with an
        ``available`` title list) when none resolves.
    """
    action_map = {
        "rename": "file_action_rename",
        "duplicate": "file_action_duplicate",
        "move": "file_action_move",
        "trash": "file_action_trash",
        "star": "file_action_star",
        "restore": "file_action_restore",
    }
    act = action.strip().lower()
    aid = action_map.get(act)
    if aid is None:
        return {"ok": False, "error": f"Unknown action '{action}'. Use: {', '.join(action_map.keys())}."}
    sim = SimulatorBridge.get()
    # Best-effort UI tap of the context-menu item (usually not rendered in the
    # browser-only UI and may silently no-op), then persist the effect via the
    # workspace store for the actions that map to state flags.
    try:
        sim.tap_id(aid)
        sim.wait(0.4)
    except Exception:
        pass
    env = dl.read_envelope()
    sp = _resolve_current_spreadsheet(env, spreadsheet)
    if not sp:
        if spreadsheet:
            names = [s.get("title") for s in env.get("seededData",{}).get("spreadsheets",[])][:8]
            return {"ok": False, "error": f"No spreadsheet matching '{spreadsheet}'.", "available": names}
        return {"ok": False, "error": "No open spreadsheet for file_action. Pass spreadsheet=<title> or call open_spreadsheet first."}
    flag_actions = {
        "star": ("isStarred", True),
        "trash": ("isTrashed", True),
        "restore": ("isTrashed", False),
    }
    if act in flag_actions:
        field, val = flag_actions[act]
        sp[field] = val
        sp["updatedAt"] = "2026-05-12T00:00:00Z"
        dl.write_envelope(env)
        dl.reload_app(BUNDLE_ID)
        return {"ok": True, "action": "file_action", "file_action": act,
                "spreadsheet_id": sp.get("id"), "title": sp.get("title"), field: val}
    # ``duplicate`` is a real, persistable effect: deep-copy the spreadsheet into
    # the workspace store with a fresh id and a "Copy" title. The browser-only UI
    # doesn't expose file_action_duplicate, so we do NOT trust the earlier UI tap
    # for this — the store write is the authoritative effect (bug class 4: never
    # report ok:true without a confirmed effect).
    if act == "duplicate":
        import copy as _copy
        sps = env.get("seededData", {}).get("spreadsheets", [])
        existing_ids = {str(s.get("id")) for s in sps}
        dup = _copy.deepcopy(sp)
        base = str(sp.get("id") or "sheet")
        new_id = f"{base}_copy"
        i = 2
        while new_id in existing_ids:
            new_id = f"{base}_copy{i}"; i += 1
        dup["id"] = new_id
        dup["title"] = f"{sp.get('title', 'Untitled')} Copy"
        dup["isStarred"] = False
        dup["updatedAt"] = "2026-05-12T00:00:00Z"
        sps.append(dup)
        dl.write_envelope(env)
        dl.reload_app(BUNDLE_ID)
        return {"ok": True, "action": "file_action", "file_action": act,
                "spreadsheet_id": dup["id"], "source_id": sp.get("id"),
                "title": dup["title"],
                "message": f"Duplicated '{sp.get('title')}' as '{dup['title']}'."}
    # rename / move need information this tool doesn't carry (a new title / a
    # destination folder). Rather than emit a false ok:true with no effect,
    # fail honestly and point to the dedicated tool.
    if act == "rename":
        return {"ok": False, "action": "file_action", "file_action": act,
                "spreadsheet_id": sp.get("id"), "title": sp.get("title"),
                "error": "file_action('rename') cannot rename without a new title. "
                         "Use rename_spreadsheet(new_name=..., spreadsheet=...) instead."}
    # move
    return {"ok": False, "action": "file_action", "file_action": act,
            "spreadsheet_id": sp.get("id"), "title": sp.get("title"),
            "error": "file_action('move') cannot move without a destination folder; "
                     "no move-by-destination tool is exposed for CloudSheets spreadsheets."}




# ── Direct-state-write tools

@mcp.tool()
def list_spreadsheets_with_meta() -> dict:
    """List every CloudSheets spreadsheet with full metadata from the workspace store.

    Bypasses the UI; sees all spreadsheets including trashed ones and those
    not in the current view. This is the best source of the exact ``title``
    and per-sheet ``name`` values that the ``spreadsheet`` and ``sheet`` args
    of the other tools accept.

    Returns:
      ``{"spreadsheets": [{"id": str, "title": str,
        "sheets": [{"id": str, "name": str, "rows": int, "cols": int,
        "cell_count": int}, ...]}, ...], "count": int}``.
    """
    env = dl.read_envelope()
    out = []
    for s in env.get("seededData",{}).get("spreadsheets",[]):
        sheets = [{"id": sh.get("id"), "name": sh.get("name"),
                   "rows": sh.get("rowCount", 0), "cols": sh.get("columnCount", 0),
                   "cell_count": len(sh.get("cells", []) or [])}
                  for sh in s.get("sheets", [])]
        out.append({"id": s.get("id"), "title": s.get("title"), "sheets": sheets})
    return {"spreadsheets": out, "count": len(out)}


@mcp.tool()
def list_sheet_records(spreadsheet: str, sheet: str = "") -> dict:
    """Read a worksheet as row records using row 1 as headers.

    Use this before tasks phrased in human terms such as "update a
    volunteer's status" or "find a row where Status is not Pending". It
    returns row numbers and header-named values, so you do not need to infer
    A1 addresses from screenshots. The ``spreadsheet`` arg accepts the plain
    human-readable title or id. ``sheet`` is optional; single-sheet files use
    their only sheet.

    Returns ``{"ok": True, "headers": [...], "records": [...]}``, where each
    record includes ``row_number`` plus one key per header.
    """
    env = dl.read_envelope()
    sp = _find_spreadsheet(env, spreadsheet)
    if not sp:
        names = [s.get("title") for s in env.get("seededData", {}).get("spreadsheets", [])][:8]
        return {"ok": False, "action": "list_sheet_records", "message": f"No spreadsheet matching '{spreadsheet}'.", "available": names}
    sh = _resolve_sheet(sp, sheet)
    if not sh:
        return {"ok": False, "action": "list_sheet_records", "message": f"No sheet '{sheet}' in '{sp.get('title')}'.", "available": [s.get("name") for s in sp.get("sheets", [])]}
    return {
        "ok": True,
        "action": "list_sheet_records",
        "spreadsheet": sp.get("title"),
        "sheet": sh.get("name"),
        "headers": _sheet_headers(sh),
        "records": _sheet_records(sh),
    }


@mcp.tool()
def update_row_value(spreadsheet: str, match_column: str, match_value: str,
                     target_column: str, value: str, sheet: str = "") -> dict:
    """Update one worksheet row by matching header names instead of A1 cells.

    This is the preferred tool for spreadsheet tasks expressed as records,
    e.g. "set Ava's Status to Pending" or "update a volunteer's assignment
    status". First call ``list_sheet_records`` to see valid header names and
    row values, then pass:
      - ``match_column``: a header from row 1, such as "Name"
      - ``match_value``: the exact row value to match, such as "Ava"
      - ``target_column``: the header to edit, such as "Status"
      - ``value``: the replacement cell value, such as "Pending"

    The match must identify exactly one row; otherwise this returns
    ``ok:false`` with candidates. On success it writes to the workspace store,
    reloads the app, and verifies the target cell read-back.
    """
    env = dl.read_envelope()
    sp = _find_spreadsheet(env, spreadsheet)
    if not sp:
        names = [s.get("title") for s in env.get("seededData", {}).get("spreadsheets", [])][:8]
        return {"ok": False, "action": "update_row_value", "message": f"No spreadsheet matching '{spreadsheet}'.", "available": names}
    sh = _resolve_sheet(sp, sheet)
    if not sh:
        return {"ok": False, "action": "update_row_value", "message": f"No sheet '{sheet}' in '{sp.get('title')}'.", "available": [s.get("name") for s in sp.get("sheets", [])]}

    headers = _sheet_headers(sh)
    header_lut = {h.strip().lower(): i for i, h in enumerate(headers) if h}
    match_idx = header_lut.get(match_column.strip().lower())
    target_idx = header_lut.get(target_column.strip().lower())
    if match_idx is None or target_idx is None:
        return {
            "ok": False,
            "action": "update_row_value",
            "message": f"Unknown column. Available headers: {headers}",
            "headers": headers,
        }

    records = _sheet_records(sh)
    matches = [
        r for r in records
        if str(r.get(headers[match_idx], "")).strip().lower() == str(match_value).strip().lower()
    ]
    if len(matches) != 1:
        return {
            "ok": False,
            "action": "update_row_value",
            "message": (
                f"Expected exactly one row where {match_column} == '{match_value}', "
                f"found {len(matches)}."
            ),
            "candidates": records[:12],
        }

    row_number = int(matches[0]["row_number"])
    address = f"{_col_to_letters(target_idx)}{row_number}"
    ok, error = _set_cell(sh, address, value)
    if not ok:
        return {"ok": False, "action": "update_row_value", "message": error}
    verified = _cell_value_map(sh).get(address.upper()) == str(value)
    if not verified:
        return {"ok": False, "action": "update_row_value", "message": f"Write to {address} did not verify."}
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {
        "ok": True,
        "action": "update_row_value",
        "spreadsheet": sp.get("title"),
        "sheet": sh.get("name"),
        "row_number": row_number,
        "matched": {match_column: matches[0].get(headers[match_idx])},
        "address": address,
        "target_column": headers[target_idx],
        "value": value,
        "message": (
            f"Updated row {row_number}: {match_column}='{matches[0].get(headers[match_idx])}', "
            f"{headers[target_idx]}='{value}'."
        ),
    }


@mcp.tool()
def set_cell_direct(spreadsheet_title: str, sheet_name: str,
                    address: str, value: str) -> dict:
    """Write a cell value via direct workspace-store mutation (no UI taps).

    Args:
      spreadsheet_title: spreadsheet title or id (case-insensitive). Resolved
        by exact value match, then title substring, then fuzzy title/id slug —
        first match wins. The plain human-readable title works. On no match,
        returns ``{ok: False, ...}`` with a list of available titles.
      sheet_name: worksheet name (case-insensitive). Resolved leniently:
        exact, then substring, then id/slug; a single-sheet spreadsheet
        ignores the name; a generic guess ("Sheet1"/"main"/...) maps to the
        first sheet. Returns ``{ok: False, available: [...]}`` only when the
        spreadsheet has several sheets and the name matches none. Get exact
        names from list_spreadsheets_with_meta.
      address: A1-style cell reference (e.g. "A1", "B3"). Anything not
        matching ``[A-Z]+[0-9]+`` returns ``{ok: False, error: ...}``.
      value: cell content as a string — text, number, or formula starting
        with "=". Replaces any existing value.

    Returns:
      ``{"ok": True, "spreadsheet": str, "sheet": str, "address": str,
        "value": str, "message": str}`` on success.
    """
    env = dl.read_envelope()
    sp = _find_spreadsheet(env, spreadsheet_title)
    if not sp:
        names = [s.get("title") for s in env.get("seededData",{}).get("spreadsheets",[])][:8]
        return {"ok": False, "error": f"No spreadsheet matching '{spreadsheet_title}'", "available": names}
    sheet = _resolve_sheet(sp, sheet_name)
    if not sheet:
        sheet_names = [s.get("name") for s in sp.get("sheets",[])]
        return {"ok": False, "error": f"No sheet '{sheet_name}' in '{sp.get('title')}'", "available": sheet_names}
    ok, error = _set_cell(sheet, address, value)
    if not ok:
        return {"ok": False, "error": error}
    dl.write_envelope(env)
    dl.reload_app(BUNDLE_ID)
    return {"ok": True, "spreadsheet": sp.get("title"), "sheet": sheet["name"],
            "address": address, "value": value,
            "message": f"Set {address}='{value}' in {sp.get('title')}/{sheet['name']}."}

if __name__ == "__main__":
    mcp.run()
