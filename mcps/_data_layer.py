"""Shared helpers for direct seed-data manipulation across MCP servers.

When a UI flow can't be cleanly driven via accessibility IDs, MCP tools
can mutate the underlying state file (JSON / SQLite / UserDefaults) and
then trigger an app reload so the view re-renders the new state. This
abstraction layer hides the details of locating each app's container.

All paths are resolved per-UDID so this works on the source sim and any
clone.
"""
import json
import os
import pathlib
import plistlib
import sqlite3
import subprocess
import time
from typing import Any, Dict, Optional


def _autodetect_booted_udid() -> str:
    """Return the UDID of the first booted iPhone simulator, or '' if none.

    Mirrors simulator_base._autodetect_booted_udid so the data layer resolves
    the same device the Appium bridge is driving when SIMCTL_UDID is not
    exported. Result is cached for the process lifetime.
    """
    try:
        out = subprocess.run(
            ["xcrun", "simctl", "list", "devices", "booted", "-j"],
            capture_output=True, text=True, timeout=5,
        ).stdout
        data = json.loads(out or "{}")
        for _runtime, devs in (data.get("devices") or {}).items():
            for dev in devs:
                if dev.get("state") == "Booted" and "iPhone" in (dev.get("name") or ""):
                    return dev.get("udid", "")
    except Exception:
        pass
    return ""


_AUTODETECTED_UDID: Optional[str] = None


def _udid() -> str:
    """Resolve the simulator UDID for state-file access.

    Precedence: explicit ``SIMCTL_UDID`` env var, else the first booted iPhone
    simulator (auto-detected and cached). Previously this only read the env
    var, so any MCP server launched without SIMCTL_UDID exported — common,
    since the Appium bridge auto-detects the device itself — failed every
    data-layer call with "cant find sim container". Auto-detect closes that
    gap so direct/state read-write tools work in the same conditions the UI
    tools already do.
    """
    global _AUTODETECTED_UDID
    env = (os.environ.get("SIMCTL_UDID") or "").strip()
    if env:
        return env
    if _AUTODETECTED_UDID:
        return _AUTODETECTED_UDID
    _AUTODETECTED_UDID = _autodetect_booted_udid()
    return _AUTODETECTED_UDID


def _sim_data_root() -> pathlib.Path:
    udid = _udid()
    if not udid:
        raise RuntimeError(
            "Could not locate a simulator data container: no SIMCTL_UDID set "
            "and no booted iPhone simulator found. Boot the simulator (or "
            "export SIMCTL_UDID) and retry."
        )
    return pathlib.Path.home() / "Library" / "Developer" / "CoreSimulator" / "Devices" / udid / "data"


def find_app_container(bundle_id: str) -> Optional[pathlib.Path]:
    """Locate the per-app Documents container directory for `bundle_id`."""
    root = _sim_data_root() / "Containers/Data/Application"
    if not root.exists():
        return None
    for d in root.iterdir():
        md = d / ".com.apple.mobile_container_manager.metadata.plist"
        if not md.exists():
            continue
        try:
            with md.open("rb") as f:
                m = plistlib.load(f)
            if m.get("MCMMetadataIdentifier") == bundle_id:
                return d
        except Exception:
            continue
    return None


def find_workspace_suite_envelope() -> Optional[pathlib.Path]:
    """Path to the shared cloud-suite envelope (clouddocs/sheets/slides/drive
    all read+write the same envelope)."""
    root = _sim_data_root() / "Containers/Shared/AppGroup"
    if not root.exists():
        return None
    for d in root.iterdir():
        md = d / ".com.apple.mobile_container_manager.metadata.plist"
        if not md.exists():
            continue
        try:
            with md.open("rb") as f:
                m = plistlib.load(f)
            if m.get("MCMMetadataIdentifier") == "group.com.iosworld.benchmark.workspacesuite":
                p = d / "WorkspaceSuite/workspace_envelope.json"
                return p if p.exists() else None
        except Exception:
            continue
    return None


def read_envelope() -> Dict[str, Any]:
    p = find_workspace_suite_envelope()
    if not p:
        raise RuntimeError("workspace_envelope.json not found")
    return json.loads(p.read_text())


def write_envelope(data: Dict[str, Any]) -> None:
    p = find_workspace_suite_envelope()
    if not p:
        raise RuntimeError("workspace_envelope.json not found")
    p.write_text(json.dumps(data, indent=2, default=str))


def read_app_state(bundle_id: str, filename: str) -> Optional[Dict[str, Any]]:
    """Read a JSON state file from an app's Documents/ directory."""
    container = find_app_container(bundle_id)
    if not container:
        return None
    p = container / "Documents" / filename
    if not p.exists():
        return None
    try:
        return json.loads(p.read_text())
    except Exception:
        return None


def write_app_state(bundle_id: str, filename: str, data: Dict[str, Any]) -> bool:
    container = find_app_container(bundle_id)
    if not container:
        return False
    p = container / "Documents" / filename
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data, indent=2, default=str))
    return True


def reload_app(bundle_id: str, *, settle_seconds: float = 1.5) -> None:
    """Terminate + relaunch the app so it re-reads its state file."""
    udid = _udid()
    if not udid:
        return
    subprocess.run(["xcrun", "simctl", "terminate", udid, bundle_id],
                   capture_output=True, timeout=10)
    time.sleep(0.3)
    subprocess.run(["xcrun", "simctl", "launch", udid, bundle_id],
                   capture_output=True, timeout=15)
    time.sleep(settle_seconds)


def read_user_defaults(bundle_id: str) -> Dict[str, Any]:
    """Read NSUserDefaults plist for an app."""
    container = find_app_container(bundle_id)
    if not container:
        return {}
    p = container / "Library/Preferences" / f"{bundle_id}.plist"
    if not p.exists():
        return {}
    try:
        with p.open("rb") as f:
            return plistlib.load(f)
    except Exception:
        return {}


def write_user_defaults(bundle_id: str, data: Dict[str, Any]) -> bool:
    container = find_app_container(bundle_id)
    if not container:
        return False
    p = container / "Library/Preferences" / f"{bundle_id}.plist"
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open("wb") as f:
        plistlib.dump(data, f)
    return True


def delete_user_defaults_key(bundle_id: str, key: str) -> bool:
    """Remove a single key from the app's NSUserDefaults plist.

    Used to clear persisted state so the app falls back to seed data on
    next launch (e.g. MegaMart stores its full sim state under
    `amazonsim.state.v3`; deleting that key triggers SeedData re-seeding).
    Terminates the app first so the running process doesn't immediately
    re-save its in-memory state. Returns True if the key was removed or
    already absent; False if the plist couldn't be located.
    """
    udid = _udid()
    if udid:
        # Make sure the running app isn't holding stale state in memory.
        subprocess.run(["xcrun", "simctl", "terminate", udid, bundle_id],
                       capture_output=True, timeout=10)
        time.sleep(0.2)
    container = find_app_container(bundle_id)
    if not container:
        return False
    p = container / "Library/Preferences" / f"{bundle_id}.plist"
    if not p.exists():
        # Nothing to delete — fresh-install state will reseed on launch.
        return True
    try:
        with p.open("rb") as f:
            data = plistlib.load(f)
    except Exception:
        return False
    if key in data:
        del data[key]
        try:
            with p.open("wb") as f:
                plistlib.dump(data, f)
        except Exception:
            return False
    return True


def open_sqlite(bundle_id: str, relpath: str) -> Optional[sqlite3.Connection]:
    """Open a sqlite database in the app's container. `relpath` is relative
    to the container root — e.g. 'Documents/foo.sqlite' or
    'Library/Application Support/default.store'."""
    container = find_app_container(bundle_id)
    if not container:
        return None
    # Allow either bare filename (old behavior) or container-relative path
    if "/" in relpath:
        p = container / relpath
    else:
        p = container / "Documents" / relpath
    if not p.exists():
        return None
    return sqlite3.connect(str(p))


# ── Helpers for the workspace_envelope structure ───────────────────
def envelope_find(envelope: Dict[str, Any], collection: str,
                   *, by: str = "id", value: str) -> Optional[Dict[str, Any]]:
    """Find an item in seededData[collection] where item[by] == value."""
    seeded = envelope.get("seededData", {})
    for item in seeded.get(collection, []):
        if item.get(by) == value:
            return item
    return None


def envelope_match(envelope: Dict[str, Any], collection: str,
                    *, title_substring: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Find an item by title/name substring (case-insensitive)."""
    seeded = envelope.get("seededData", {})
    def _norm(value: Any) -> str:
        return "".join(ch for ch in str(value).lower().strip() if ch.isalnum())

    target = (title_substring or "").lower().strip()
    target_norm = _norm(target)
    if not target: return None
    for item in seeded.get(collection, []):
        for k in ("title", "name", "displayName", "subject"):
            v = item.get(k)
            if v and (target in str(v).lower() or (target_norm and target_norm in _norm(v))):
                return item
    return None
