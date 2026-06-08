"""Shared Appium bridge for all app MCP servers.

Provides SimulatorBridge — a singleton that wraps appium_agent.py to give
MCP tools a clean interface for launching apps, tapping elements, typing
text, swiping, and capturing observations (UI tree + screenshots).

Also installs (at import time) a global FastMCP.tool() wrapper that converts
every tool's raw return value into a structured MCP-style envelope:

    string  → {"action": <name>, "ok": True, "message": <stripped-of-trailing-XML>}
    XML     → {"action": <name>, "ok": True, "ui_xml": <xml>}   (for observe-style)
    dict    → passed through, ensuring "action" is set
    list    → {"action": <name>, "items": <list>}

This makes every per-app server return real MCP `structuredContent` instead
of UI-tree XML mixed with a status line. Disable with MCP_STRUCTURED_RETURNS=0.
"""
from __future__ import annotations

import base64
import re
import functools
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import time
from typing import Any, Dict, List, Optional

# ---------------------------------------------------------------------------
# Path setup — make scripts/ importable
# ---------------------------------------------------------------------------
_ROOT = pathlib.Path(__file__).resolve().parent.parent
_SCRIPTS = _ROOT / "scripts"
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
_MANIFEST_PATH = _ROOT / "iphone" / "bootstrap" / ".app_manifest.json"

def _autodetect_booted_udid() -> str:
    """Return the UDID of the first booted iPhone simulator, or '' if none."""
    import subprocess, json as _json
    try:
        out = subprocess.run(
            ["xcrun", "simctl", "list", "devices", "booted", "-j"],
            capture_output=True, text=True, timeout=5,
        ).stdout
        data = _json.loads(out or "{}")
        for _runtime, devs in (data.get("devices") or {}).items():
            for d in devs:
                if d.get("state") == "Booted" and "iPhone" in (d.get("name") or ""):
                    return d.get("udid", "")
    except Exception:
        pass
    return ""

# SIMCTL_UDID env var takes precedence; otherwise auto-detect the booted iPhone sim.
# Use `or` chain so an empty-string env var (common in .env templates) still
# falls through to auto-detect instead of being treated as a real value.
WORKER_UDID = (os.environ.get("SIMCTL_UDID") or _autodetect_booted_udid()).strip()
APPIUM_URL = (os.environ.get("APPIUM_URL") or "http://127.0.0.1:4723").strip()
# PLATFORM_VERSION: don't pass the .env value (often stale, e.g. "26.2"
# when the system has 26.3). Let Appium auto-detect unless explicitly
# overridden via MCP_PLATFORM_VERSION.
PLATFORM_VERSION = os.environ.get("MCP_PLATFORM_VERSION") or None
DEVICE_NAME = (os.environ.get("DEVICE_NAME") or "iPhone 17 Pro").strip().strip('"')
# Per-lane WDA port. When running multiple lanes (one process per cloned sim),
# each lane must use a distinct WDA local port so the XCUITest drivers don't
# collide on the default 8100. Unset → None → unchanged single-lane behavior
# (Appium picks/uses its default). Override via MCP_WDA_PORT or configure().
def _parse_wda_port(raw: Optional[str]) -> Optional[int]:
    raw = (raw or "").strip()
    if not raw:
        return None
    try:
        return int(raw)
    except (TypeError, ValueError):
        return None

WDA_PORT = _parse_wda_port(os.environ.get("MCP_WDA_PORT"))


class SimulatorBridge:
    """Singleton bridge to the iOS Simulator via Appium."""

    _instance: Optional["SimulatorBridge"] = None

    @classmethod
    def get(cls) -> "SimulatorBridge":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self) -> None:
        import appium_agent
        appium_agent.ensure_runtime_deps()
        self._agent = appium_agent
        self.driver = None
        self._manifest: Optional[Dict[str, Dict[str, str]]] = None
        # Circuit breaker: after N consecutive page_source timeouts, stop
        # retrying and return screenshot-only mode until the driver is
        # replaced. Prevents infinite retry loops on permanently-stuck WDA.
        self._source_timeout_count = 0
        self._SOURCE_TIMEOUT_LIMIT = 2
        # Track whether we've ever successfully connected. Used to prime
        # the FIRST connect with Calculator (to avoid SpringBoard timeout)
        # but skip priming on reconnects — otherwise a mid-task session
        # death would silently launch Calculator and shadow whatever app
        # the agent was working with.
        self._has_primed = False
        # Per-instance config, defaulting to module-level env values.
        # Callers (e.g. parallel workers, appium_agent.py --mcp branch) can
        # override these via configure() before calling connect().
        self.udid = WORKER_UDID
        self.appium_url = APPIUM_URL
        self.platform_version = PLATFORM_VERSION
        self.device_name = DEVICE_NAME
        # Per-lane WDA local port (None = unchanged default behavior).
        self.wda_port = WDA_PORT

    def configure(self, *, udid: Optional[str] = None,
                  appium_url: Optional[str] = None,
                  device_name: Optional[str] = None,
                  platform_version: Optional[str] = None,
                  wda_port: Optional[int] = None) -> None:
        """Override per-instance connection config (for parallel workers or
        explicit CLI-passed overrides). Must be called before connect() —
        changing after an active connection is a no-op until reconnect."""
        if udid:
            self.udid = udid.strip()
        if appium_url:
            self.appium_url = appium_url.strip()
        if device_name:
            self.device_name = device_name.strip().strip('"')
        if platform_version:
            self.platform_version = platform_version
        if wda_port is not None:
            self.wda_port = _parse_wda_port(str(wda_port))

    # ------------------------------------------------------------------
    # Connection
    # ------------------------------------------------------------------

    @property
    def manifest(self) -> Dict[str, Dict[str, str]]:
        if self._manifest is None:
            self._manifest = self._agent.load_app_manifest(str(_MANIFEST_PATH))
        return self._manifest

    def connect(self):
        """Connect (or reconnect) to the Appium WebDriver.

        On the FIRST connect, launches Calculator as a lightweight warm-up
        so the subsequent page_source call doesn't timeout on SpringBoard's
        huge accessibility tree.

        On RECONNECT (mid-task session death), we deliberately skip the
        Calculator prime — otherwise we'd silently foreground Calculator
        and shadow whatever app the agent was actually working with.
        The caller (e.g. launch_and_observe) is responsible for relaunching
        the target app after a reconnect.
        """
        if self.driver is not None:
            try:
                self.driver.get_window_size()
                return self.driver
            except Exception:
                self.driver = None
        is_first_connect = not self._has_primed
        self.driver = self._agent.connect_driver(
            self.appium_url, self.udid, self.platform_version, self.device_name,
            wda_port=self.wda_port,
        )
        if is_first_connect:
            # First-connect prime: launch Calculator so the first page_source
            # call doesn't hit the enormous SpringBoard tree.
            try:
                self.driver.execute_script(
                    "mobile: launchApp",
                    {"bundleId": "com.iosworld.benchmark.clock"},
                )
                time.sleep(1)
            except Exception:
                pass
            self._has_primed = True
        return self.driver

    def disconnect(self):
        if self.driver:
            try:
                self.driver.quit()
            except Exception:
                pass
            self.driver = None

    # ------------------------------------------------------------------
    # Observation
    # ------------------------------------------------------------------

    def observe_text(self) -> str:
        """Return the UI accessibility tree XML as a string.

        If page_source times out, the orphaned HTTP request blocks WDA.
        Circuit breaker: after _SOURCE_TIMEOUT_LIMIT consecutive timeouts on
        a session, we give up and return screenshot-only mode until the
        driver is replaced (via _force_reconnect).
        """
        # Circuit breaker: don't retry indefinitely
        if self._source_timeout_count >= self._SOURCE_TIMEOUT_LIMIT:
            return "[UI tree unavailable — circuit breaker open after repeated timeouts]"

        driver = self.connect()
        result = self._observe_text_inner(driver)
        if result.startswith("[UI tree unavailable"):
            self._source_timeout_count += 1
            if self._source_timeout_count >= self._SOURCE_TIMEOUT_LIMIT:
                return result  # Give up, don't retry
            self._force_reconnect()
            driver = self.connect()
            time.sleep(1)
            result = self._observe_text_inner(driver)
            if result.startswith("[UI tree unavailable"):
                self._source_timeout_count += 1
        else:
            # Success — reset the counter
            self._source_timeout_count = 0
        return result

    def _force_reconnect(self):
        """Quit the driver with a timeout (WDA may be blocked) and reset.

        Resets the circuit breaker too, since a new WDA session gets a
        clean slate.
        """
        if getattr(self._agent, '_page_source_needs_reconnect', False):
            self._agent._page_source_needs_reconnect = False
        if self.driver:
            # Use a timeout-protected quit — driver.quit() can hang if WDA is
            # stuck processing the timed-out page_source request.
            from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeout
            pool = ThreadPoolExecutor(1)
            try:
                pool.submit(self.driver.quit).result(timeout=10)
            except (FuturesTimeout, Exception):
                pass
            finally:
                pool.shutdown(wait=False, cancel_futures=True)
        self.driver = None
        self._source_timeout_count = 0  # Fresh session = fresh circuit
        # Any in-flight prepare_*/confirm_* drafts are bound to the previous
        # UI session; drop them so a new session starts with no stale ids.
        try:
            from tool_support import clear_drafts  # type: ignore
            clear_drafts()
        except Exception:
            pass

    def _observe_text_inner(self, driver) -> str:
        with tempfile.TemporaryDirectory() as tmpdir:
            try:
                obs = self._agent.observe(driver, pathlib.Path(tmpdir))
            except Exception as exc:
                _msg = str(exc).lower()
                if "session" in _msg or "screenshot" in _msg or "wda" in _msg:
                    self._force_reconnect()
                    driver = self.connect()
                    obs = self._agent.observe(driver, pathlib.Path(tmpdir))
                else:
                    raise
            if obs.get("source"):
                with open(obs["source"]) as f:
                    return f.read()
            return "[UI tree unavailable — screenshot-only mode]"

    def screenshot_base64(self) -> str:
        """Return a base64-encoded PNG screenshot."""
        driver = self.connect()
        with tempfile.TemporaryDirectory() as tmpdir:
            try:
                obs = self._agent.observe(driver, pathlib.Path(tmpdir), skip_source=True)
            except Exception as exc:
                _msg = str(exc).lower()
                if "session" in _msg or "screenshot" in _msg or "wda" in _msg:
                    self._force_reconnect()
                    driver = self.connect()
                    obs = self._agent.observe(driver, pathlib.Path(tmpdir), skip_source=True)
                else:
                    raise
            if obs.get("screenshot"):
                with open(obs["screenshot"], "rb") as f:
                    return base64.b64encode(f.read()).decode()
        return ""

    # ------------------------------------------------------------------
    # Actions
    # ------------------------------------------------------------------

    def perform_action(self, action: dict) -> Dict[str, Any]:
        driver = self.connect()
        try:
            return self._agent.perform_action(driver, action, udid=self.udid)
        except Exception as exc:
            exc_text = str(exc).lower()
            if "session" in exc_text or "proxy" in exc_text or "socket" in exc_text:
                self._force_reconnect()
                driver = self.connect()
                return self._agent.perform_action(driver, action, udid=self.udid)
            raise

    def launch_app(self, bundle_id: str) -> Dict[str, Any]:
        return self.perform_action({"type": "launch_app", "bundle_id": bundle_id})

    def terminate_app(self, bundle_id: str) -> Dict[str, Any]:
        return self.perform_action({"type": "terminate_app", "bundle_id": bundle_id})

    def tap_id(self, accessibility_id: str) -> Dict[str, Any]:
        return self.perform_action({
            "type": "tap", "using": "accessibility id", "value": accessibility_id,
        })

    def tap_xy(self, x: int, y: int) -> Dict[str, Any]:
        return self.perform_action({"type": "tap_xy", "x": x, "y": y})

    def type_text(self, text: str) -> Dict[str, Any]:
        return self.perform_action({"type": "type", "text": text})

    def swipe(self, direction: str, x: Optional[int] = None, y: Optional[int] = None) -> Dict[str, Any]:
        action: Dict[str, Any] = {"type": "swipe", "direction": direction}
        if x is not None:
            action["x"] = x
        if y is not None:
            action["y"] = y
        return self.perform_action(action)

    def long_press(self, x: int, y: int, duration: float = 2.0) -> Dict[str, Any]:
        return self.perform_action({
            "type": "hover", "x": x, "y": y, "duration": duration,
        })

    def home(self) -> Dict[str, Any]:
        return self.perform_action({"type": "home"})

    def wait(self, duration: float = 1.0) -> Dict[str, Any]:
        return self.perform_action({"type": "wait", "duration": duration})

    def open_url(self, url: str) -> Dict[str, Any]:
        return self.perform_action({"type": "open_url", "url": url})

    # ------------------------------------------------------------------
    # Convenience helpers for MCP tools
    # ------------------------------------------------------------------

    def get_bundle_id(self, app_name: str) -> str:
        entry = self.manifest.get(app_name, {})
        return entry.get("bundle_id", "")

    def _inject_api_keys(self, bundle_id: str) -> None:
        """Write LLM API keys into the app's UserDefaults before launch.

        iOS simulator apps can't read the host's .env file (the bundle lives
        in DerivedData, far from the repo root). This injects keys that each
        app's LLM service already checks via UserDefaults.standard.
        """
        key_map = {
            "openai_api_key": os.environ.get("OPENAI_API_KEY", "").strip().strip('"').strip("'"),
        }
        for ud_key, value in key_map.items():
            if not value:
                continue
            try:
                subprocess.run(
                    ["xcrun", "simctl", "spawn", self.udid,
                     "defaults", "write", bundle_id, ud_key, "-string", value],
                    capture_output=True, timeout=5,
                )
            except Exception:
                pass

    def launch_and_observe(self, bundle_id: str, settle: float = 1.0) -> str:
        """Terminate, relaunch an app, wait for UI to settle, return the UI tree.

        If the first observe hits a page_source timeout, the session is
        force-reconnected and the target app is relaunched explicitly.
        Honors the circuit breaker — won't retry if we've hit the timeout
        limit for this session.
        """
        try:
            self.terminate_app(bundle_id)
            time.sleep(0.3)
        except Exception:
            pass
        self._inject_api_keys(bundle_id)
        self.launch_app(bundle_id)
        time.sleep(settle)
        tree = self._observe_text_inner(self.connect())
        if not tree.startswith("[UI tree unavailable"):
            self._source_timeout_count = 0
            return tree
        # First observe failed. Honor circuit breaker.
        self._source_timeout_count += 1
        if self._source_timeout_count >= self._SOURCE_TIMEOUT_LIMIT:
            return tree
        # Reconnect (connect() no longer primes Calculator on reconnect)
        # and relaunch the target app so it's foreground for the observe.
        self._force_reconnect()
        self.connect()
        self.launch_app(bundle_id)
        time.sleep(settle)
        tree = self._observe_text_inner(self.connect())
        if tree.startswith("[UI tree unavailable"):
            self._source_timeout_count += 1
        else:
            self._source_timeout_count = 0
        return tree

    def tap_and_observe(self, accessibility_id: str, settle: float = 0.5) -> str:
        """Tap an element by accessibility ID, wait, return UI tree."""
        self.tap_id(accessibility_id)
        time.sleep(settle)
        return self.observe_text()

    def type_and_observe(self, text: str, settle: float = 0.5) -> str:
        """Type text into the focused field, wait, return UI tree."""
        self.type_text(text)
        time.sleep(settle)
        return self.observe_text()

    def swipe_and_observe(self, direction: str, settle: float = 0.5) -> str:
        """Swipe in a direction, wait, return UI tree."""
        self.swipe(direction)
        time.sleep(settle)
        return self.observe_text()

    def tap_and_verify_changed(
        self,
        accessibility_id: str,
        *,
        settle: float = 0.4,
        prefix_for_failure: str = "",
    ) -> Optional[str]:
        """Tap *accessibility_id*; return None if the UI tree changed, else a
        recovery-hint string.

        Suited for tools whose taps SHOULD change state on every valid call
        (open_X, view_X, etc.). NOT suited for idempotent navigation taps
        (navigate_to_tab when the model might already be on that tab) — those
        should use plain ``tap_id`` because no-change is legitimate there.

        *prefix_for_failure* is prepended to the recovery hint, e.g.
        ``"Could not open transaction 'X'. "``.

        Disable via ``MCP_DISABLE_TAP_VERIFY=1`` (ablation): always returns
        None unless the tap itself raises. Defaults to current verification.
        """
        if os.environ.get("MCP_DISABLE_TAP_VERIFY", "0") == "1":
            try:
                self.tap_id(accessibility_id)
            except Exception as exc:
                return f"{prefix_for_failure}{_clean_tool_error(exc)}"
            time.sleep(settle)
            return None
        before = self.observe_text() or ""
        try:
            self.tap_id(accessibility_id)
        except Exception as exc:
            return f"{prefix_for_failure}{_clean_tool_error(exc)}"
        time.sleep(settle)
        after = self.observe_text() or ""
        if before != after:
            return None
        return (
            f"{prefix_for_failure}Tapped '{accessibility_id}' but the UI did "
            "not change. The element may be disabled, already-selected, or "
            "behind a modal that intercepted the tap. Call observe() to see "
            "current state and dismiss any open sheet before retrying."
        )

    def tap_and_verify(
        self,
        accessibility_id: str,
        post_state_markers: List[str],
        *,
        settle: float = 0.5,
    ) -> Optional[str]:
        """Tap *accessibility_id*, observe, return None on success or a
        recovery-hint string on verification failure.

        Verification passes when at least one of *post_state_markers* (substrings
        searched in the post-tap UI tree) appears, indicating the expected new
        view has actually rendered. If the markers don't appear, returns a
        clean failure message naming the missing markers so the model can
        diagnose.

        Use this instead of bare ``tap_id``+claim-success in tools where the
        tap is supposed to navigate or change the displayed view. It catches
        the "tap hits but doesn't navigate" silent-failure pattern that
        causes agents to loop on the same call expecting state to advance.

        Disable via ``MCP_DISABLE_TAP_VERIFY=1`` (ablation): skips the marker
        check, returns None unless the tap raises. Defaults to current
        verification.
        """
        try:
            self.tap_id(accessibility_id)
        except Exception as exc:
            return _clean_tool_error(exc)
        time.sleep(settle)
        if os.environ.get("MCP_DISABLE_TAP_VERIFY", "0") == "1":
            return None
        tree = self.observe_text() or ""
        if any(marker in tree for marker in post_state_markers):
            return None
        return (
            f"Tapped '{accessibility_id}' but the expected view did not "
            f"appear. None of these markers are visible: "
            f"{', '.join(repr(m) for m in post_state_markers[:5])}. The tab "
            "or button may be disabled, behind a modal, or its target view "
            "differs from expectations. Use observe() to see current state "
            "before retrying with a different approach."
        )


# ---------------------------------------------------------------------------
# Structured-return wrapping for FastMCP tools
#
# Real MCP servers (GitHub, Notion, Slack, …) return structured JSON, not UI
# trees mixed with status lines. We give every per-app tool that shape via
# a single global wrapper installed at FastMCP import time. Each return is
# converted to a dict that FastMCP serializes as `structuredContent` in the
# MCP CallToolResult.
#
# Disable with MCP_STRUCTURED_RETURNS=0 to compare against the legacy
# string-return behavior.
# ---------------------------------------------------------------------------

_STRUCTURED_RETURNS = os.environ.get("MCP_STRUCTURED_RETURNS", "1") == "1"
_MAX_TOOL_STRING = int(os.environ.get("MCP_MAX_TOOL_STRING", "2000"))
_MAX_TOOL_LIST_ITEMS = int(os.environ.get("MCP_MAX_TOOL_LIST_ITEMS", "80"))
# Ablation alias: MCP_DISABLE_RESULT_COMPACT=1 raises the cap to effectively
# unlimited (200KB) without requiring users to compute a byte budget.
_DISABLE_RESULT_COMPACT = os.environ.get("MCP_DISABLE_RESULT_COMPACT", "0") == "1"
_MAX_TOOL_RESULT_BYTES = int(
    os.environ.get(
        "MCP_MAX_TOOL_RESULT_BYTES",
        "200000" if _DISABLE_RESULT_COMPACT else "12000",
    )
)


def _looks_like_xml(s: str) -> bool:
    return isinstance(s, str) and s.lstrip().startswith("<")


def _truncate_string(value: str, limit: int = _MAX_TOOL_STRING) -> Any:
    if len(value) <= limit:
        return value
    return {
        "excerpt": value[:limit],
        "truncated": True,
        "length": len(value),
    }


def _compact_tool_value(value: Any) -> Any:
    """Keep MCP tool results bounded enough for model context.

    App tools should return app-level facts and stable IDs, not full UI trees
    or entire document bodies. This compactor is a final safety net for older
    UI-driven tools that still return XML or long text payloads.
    """
    if isinstance(value, str):
        return _truncate_string(value)
    if isinstance(value, list):
        items = [_compact_tool_value(item) for item in value[:_MAX_TOOL_LIST_ITEMS]]
        if len(value) > _MAX_TOOL_LIST_ITEMS:
            return {
                "items": items,
                "truncated": True,
                "count": len(value),
                "returned": len(items),
            }
        return items
    if isinstance(value, dict):
        compacted: Dict[str, Any] = {}
        for key, item in value.items():
            if key in {"ui_xml", "source"} and isinstance(item, str):
                compacted[f"{key}_excerpt"] = item[:_MAX_TOOL_STRING]
                compacted[f"{key}_truncated"] = len(item) > _MAX_TOOL_STRING
                compacted[f"{key}_length"] = len(item)
            elif key in {"body", "text", "message", "content", "transcript"} and isinstance(item, str):
                compacted[key] = _truncate_string(item)
            else:
                compacted[key] = _compact_tool_value(item)
        return compacted
    return value


def _semantic_item_summary(item: Any) -> Any:
    """Compact one list item while preserving identifiers and useful labels."""
    if not isinstance(item, dict):
        return _compact_tool_value(item)
    preferred_keys = (
        "id", "uuid", "slug", "name", "title", "subject", "displayName",
        "fileName", "folderName", "channelName", "restaurantName",
        "productID", "product_id", "price", "amount", "date", "type",
        "kind", "mimeType", "parentId", "folderId", "starred", "trashed",
        "modifiedAt", "createdAt", "updatedAt",
    )
    summary: Dict[str, Any] = {}
    for key in preferred_keys:
        if key in item and item[key] not in (None, ""):
            summary[key] = _compact_tool_value(item[key])
    if not summary:
        for key, val in list(item.items())[:6]:
            if key not in {"body", "text", "content", "ui_xml", "source"}:
                summary[key] = _compact_tool_value(val)
    omitted_fields = [str(key) for key in item.keys() if key not in summary]
    for key in ("body", "text", "content"):
        value = item.get(key)
        if isinstance(value, str) and value:
            summary[f"{key}_excerpt"] = value[:240]
            summary[f"{key}_length"] = len(value)
            if len(value) > 240:
                summary[f"{key}_truncated"] = True
        elif isinstance(value, dict) and "excerpt" in value:
            excerpt = str(value.get("excerpt") or "")
            summary[f"{key}_excerpt"] = excerpt[:240]
            if "length" in value:
                summary[f"{key}_length"] = value.get("length")
            if value.get("truncated") or len(excerpt) > 240:
                summary[f"{key}_truncated"] = True
    omitted_fields = [key for key in omitted_fields if f"{key}_excerpt" not in summary]
    if omitted_fields:
        summary["omitted_field_count"] = len(omitted_fields)
        summary["omitted_fields"] = omitted_fields[:20]
    return summary


def _semantic_result_summary(result: Any, raw_bytes: int) -> dict[str, Any]:
    """Summarize oversized results without dropping all useful information."""
    if isinstance(result, dict):
        summary: Dict[str, Any] = {
            "action": result.get("action"),
            "ok": result.get("ok", True),
            "truncated": True,
            "result_bytes": raw_bytes,
        }
        for key in ("count", "total_count", "returned", "query", "message"):
            if key in result:
                summary[key] = _compact_tool_value(result[key])
        for key, value in result.items():
            if isinstance(value, list):
                sample = [_semantic_item_summary(item) for item in value[:20]]
                summary[key] = {
                    "items": sample,
                    "total_count": len(value),
                    "returned": len(sample),
                    "omitted_count": max(0, len(value) - len(sample)),
                }
            elif (
                isinstance(value, dict)
                and isinstance(value.get("items"), list)
                and value.get("truncated") is True
            ):
                sample = [_semantic_item_summary(item) for item in value["items"][:20]]
                total = int(value.get("count") or value.get("total_count") or len(value["items"]))
                summary[key] = {
                    "items": sample,
                    "total_count": total,
                    "returned": len(sample),
                    "omitted_count": max(0, total - len(sample)),
                }
        if len(summary) <= 4:
            summary["available_keys"] = sorted(str(k) for k in result.keys())
        return summary
    if isinstance(result, list):
        sample = [_semantic_item_summary(item) for item in result[:20]]
        return {
            "ok": True,
            "truncated": True,
            "result_bytes": raw_bytes,
            "items": sample,
            "total_count": len(result),
            "returned": len(sample),
            "omitted_count": max(0, len(result) - len(sample)),
        }
    return {
        "ok": True,
        "truncated": True,
        "result_bytes": raw_bytes,
        "message": _compact_tool_value(str(result)),
    }


def _bounded_tool_result(result: Any) -> Any:
    compacted = _compact_tool_value(result)
    try:
        raw = json.dumps(compacted, default=str, sort_keys=True)
    except Exception:
        return compacted
    if len(raw.encode("utf-8")) <= _MAX_TOOL_RESULT_BYTES:
        return compacted
    return _semantic_result_summary(compacted, len(raw.encode("utf-8")))


def _clean_tool_error(exc: Exception) -> str:
    raw = f"{type(exc).__name__}: {exc}"
    lower = raw.lower()
    # Try to extract the accessibility ID that failed — Appium's WebDriverException
    # text contains it in patterns like:
    #   "...('accessibility id' == 'tab_home')..."
    #   "...accessibility id = tab_home..."
    #   "...with accessibility id 'tab_home'..."
    #   "...element 'tab_home' not found..."
    aid = None
    for pat in (
        r"accessibility[\s_]*id['\"]?\s*[=:]+\s*['\"]?([A-Za-z][A-Za-z0-9_\-]*)",
        r"accessibility[\s_]*id\s+['\"]?([A-Za-z][A-Za-z0-9_\-]*)",
        r"element\s+['\"]([A-Za-z][A-Za-z0-9_\-]*)['\"]",
    ):
        m = re.search(pat, raw)
        if m:
            aid = m.group(1)
            break
    if "no keyboard is visible" in lower:
        return "Input field is unavailable in the current UI state; open the relevant compose/edit screen first."
    if "not found or stale" in lower or "could not be located" in lower:
        if aid:
            return (
                f"UI control '{aid}' is not currently visible. Call observe() "
                "to see what's on screen, then navigate to a screen that "
                f"exposes '{aid}' before retrying (or use the matching "
                "direct shared-state tool if one exists)."
            )
        return "Required UI control is unavailable in the current app state; navigate to the relevant screen or use a direct shared-state tool when available."
    if len(raw) > 240:
        return raw[:237] + "..."
    return raw


# Phrases that expose WebDriver / Appium / Selenium internals to the agent.
# When a tool's own catch-and-return path embeds a raw Appium exception in its
# precondition message, these markers trip the eval-readiness leak audit. We
# strip them at the envelope layer so per-tool error formatting stays simple.
_LEAKY_INTERNAL_PHRASES = (
    "not found or stale",
    "could not be located on the page",
    "could not be located",
    "could not run because no keyboard is visible",
    "WebDriverException",
    "InvalidSelector",
    "Message: An element",
    "selenium.dev",
)


_DISABLE_LEAK_SANITIZE = os.environ.get("MCP_DISABLE_LEAK_SANITIZE", "0") == "1"


def _sanitize_message_string(s: str) -> str:
    """Remove WebDriver-internal phrases from a tool's status message.

    Tools that catch exceptions internally often format precondition responses
    like ``"Call open_document first. Error: <raw exc>"``. The raw exception
    text contains WebDriver internals that are not useful to the agent. The
    precondition statement before the ``Error:`` already conveys what the agent
    needs.

    Disable via ``MCP_DISABLE_LEAK_SANITIZE=1`` (ablation): passes the raw
    string through unmodified. Defaults to current sanitization.
    """
    if _DISABLE_LEAK_SANITIZE:
        return s if isinstance(s, str) else s
    if not isinstance(s, str) or not s:
        return s
    if " Error: " in s and any(p in s for p in _LEAKY_INTERNAL_PHRASES):
        head, _, _ = s.partition(" Error: ")
        return head.rstrip()
    for phrase in _LEAKY_INTERNAL_PHRASES:
        if phrase in s:
            s = s.replace(phrase, "UI control unavailable")
    return s


# String-return failure detection. Many MCP tools catch exceptions internally
# and return a friendly error string like "No visible movie row with ID 238"
# or "Could not navigate to settings". Without this check the envelope sets
# ok:true on those returns and the model can't tell the action failed. Matches
# message PREFIXES only to avoid false positives on valid messages that happen
# to mention "no" or "could not" mid-sentence.
_FAILURE_PREFIX_RE = re.compile(
    r"^\s*("
    r"No\s+\w+"                              # "No X ..."
    r"|Could\s+not\s+"                       # "Could not ..."
    r"|Cannot\s+"                            # "Cannot ..."
    r"|Unable\s+to\s+"                       # "Unable to ..."
    r"|Failed\s+to\s+"                       # "Failed to ..."
    r"|Failed:\s+"                           # "Failed: ..."
    r"|There\s+is\s+no\s+"                   # "There is no ..."
    r"|Missing\s+"                           # "Missing X"
    r"|(?:Simulator\s+)?UI\s+tree\s+unavailable"
    r"|Required\s+UI\s+control\s+is\s+unavailable"
    r"|\w[\w\s']*\s+unavailable\b"            # "Search bar unavailable"
    r"|\w[\w\s']*\s+not\s+reachable\b"        # "Zelle chip not reachable"
    r"|\w[\w\s']*\s+button\s+not\s+found\b"  # "Seen button not found"
    r"|\w[\w\s']*\s+failed\b"                # "Cancel failed"
    r"|\w[\w\s']*\s+not\s+found\b"           # "Trip detail button not found"
    r"|Tapped\s+['\"]?\S+['\"]?\s+but\b"     # "Tapped 'X' but ..." (state-verification failure)
    r")",
    re.IGNORECASE,
)


_DISABLE_FAILURE_PREFIX = os.environ.get("MCP_DISABLE_FAILURE_PREFIX", "0") == "1"


def _string_looks_like_failure(msg: str) -> bool:
    """Return True if a tool's status-string return reads like a failure.

    Heuristic on the leading phrase only — we don't scan the middle of the
    message because legitimate success messages can mention "no" or "could
    not" without being failures. Matched patterns are derived from a sweep
    of mcps/*.py exception-handler returns.

    Disable via ``MCP_DISABLE_FAILURE_PREFIX=1`` (ablation): forces every
    string return to flag as ok:true. Defaults to current behavior.
    """
    if _DISABLE_FAILURE_PREFIX:
        return False
    if not msg:
        return False
    return bool(_FAILURE_PREFIX_RE.match(msg))


_UI_BAR_TITLE_RE = re.compile(
    r'<XCUIElementTypeNavigationBar\b[^>]*\bname="([^"]+)"',
)
_UI_VISIBLE_ELEM_RE = re.compile(
    r'<XCUIElementType(Button|StaticText|TextField|SearchField|Cell|Other)\b'
    r'[^>]*\b(?:name|label|value)="([^"]+)"[^>]*\bvisible="true"',
)


def _ui_summary_from_xml(xml: str, *, max_items: int = 8, max_chars: int = 400) -> Optional[str]:
    """Extract a compact 'current UI state' summary from an Appium XML page source.

    Returns a one-line summary like:
        "page='Inbox' | visible: 'Inbox', 'Search', 'Compose', 'Filter'"

    or None if the XML is empty / unparseable. Used by `_structured_envelope`
    so tools returning "<status>\\n\\n<XML>" don't drop the post-action state
    that the model needs to verify the action actually changed something.
    """
    if not xml or len(xml) < 64:
        return None
    title = None
    m = _UI_BAR_TITLE_RE.search(xml)
    if m:
        title = m.group(1)
    elements: List[str] = []
    seen: set[str] = set()
    for elem_m in _UI_VISIBLE_ELEM_RE.finditer(xml):
        label = elem_m.group(2).strip()
        if not label or label in seen:
            continue
        seen.add(label)
        elements.append(label)
        if len(elements) >= max_items:
            break
    parts: List[str] = []
    if title:
        parts.append(f"page='{title}'")
    if elements:
        joined = ", ".join(f"'{e}'" for e in elements)
        parts.append(f"visible: {joined}")
    if not parts:
        return None
    summary = " | ".join(parts)
    if len(summary) > max_chars:
        summary = summary[: max_chars - 3] + "..."
    return summary


def _structured_envelope(tool_name: str, ret: Any, args: Optional[Dict[str, Any]] = None) -> Any:
    """Convert a tool's raw return value into a structured MCP envelope.

    Every envelope includes:
      - "action": the tool name
      - "args": the bound input arguments (empty dict if no args), so the
        model / evaluator can verify exactly what was called

    Plus, depending on return shape:
      - dict → merged with envelope (tool's keys win over auto fields)
      - list → {"items": ...}
      - whole-XML string → {"ok", "ui_xml"}    (observe-style)
      - "<message>\\n\\n<XML>...</XML>" → keep status line + compact ui_after
        summary parsed from the XML, so the model can verify the action's
        post-state without flooding context with full XML.
      - any other string → {"ok", "message"}
      - other → {"result"}
    """
    base: Dict[str, Any] = {"action": tool_name}
    if args:
        base["args"] = dict(args)

    if ret is None:
        base["ok"] = True
        return _bounded_tool_result(base)
    if isinstance(ret, dict):
        # Tool already returned structure; merge — tool's keys win.
        merged = dict(base)
        if "action" in ret:
            # Tool deliberately set its own action; respect it.
            merged.update(ret)
        else:
            merged.update(ret)
        if isinstance(merged.get("message"), str):
            merged["message"] = _sanitize_message_string(merged["message"])
        return _bounded_tool_result(merged)
    if isinstance(ret, list):
        base["items"] = ret
        return _bounded_tool_result(base)
    if isinstance(ret, str):
        if _looks_like_xml(ret):
            base["ok"] = True
            base["ui_xml"] = ret
            return _bounded_tool_result(base)
        if "\n\n<" in ret:
            head, _, xml_tail = ret.partition("\n\n<")
            sanitized = _sanitize_message_string(head.rstrip())
            base["ok"] = not _string_looks_like_failure(sanitized)
            base["message"] = sanitized
            ui_after = _ui_summary_from_xml("<" + xml_tail)
            if ui_after:
                base["ui_after"] = ui_after
            return _bounded_tool_result(base)
        sanitized = _sanitize_message_string(ret)
        base["ok"] = not _string_looks_like_failure(sanitized)
        base["message"] = sanitized
        return _bounded_tool_result(base)
    base["result"] = ret
    return _bounded_tool_result(base)


def _wrap_tool_callable(fn):
    """Return a wrapper around `fn` whose result is converted to a structured
    dict, while preserving the input signature so FastMCP's input schema is
    unchanged. The return annotation is dropped so FastMCP doesn't validate
    the structured dict against the tool's original `-> str` declaration.

    The wrapper also binds and echoes the caller's input arguments into
    the envelope under "args", so every tool gets structured input echoing
    for free without per-tool edits."""
    import inspect  # local: avoid module-level cost when STRUCTURED off

    fn_sig = inspect.signature(fn)

    def wrapper(*args, **kwargs):
        # Normalise loosely-typed / JSON-double-encoded arguments against the
        # tool's declared parameter types before the handler runs. Agents
        # frequently send scalars as double-encoded strings ('"100"') or
        # numbers/bools as plain strings ("100", "True"); coercion repairs
        # those while leaving already-correct values untouched. FastMCP invokes
        # tools with keyword arguments, so we only coerce kwargs (no positional
        # reordering risk). See tool_support.coerce_kwargs_for / coerce_value.
        if kwargs:
            try:
                from tool_support import coerce_kwargs_for  # type: ignore
                kwargs = coerce_kwargs_for(fn, kwargs)
            except Exception:
                pass
        # Bind caller args to parameter names so the envelope echoes them.
        try:
            bound = fn_sig.bind(*args, **kwargs)
            bound.apply_defaults()
            bound_args: Dict[str, Any] = dict(bound.arguments)
        except (TypeError, ValueError):
            bound_args = {}
        app_name = (getattr(fn, "__module__", "") or "").rsplit(".", 1)[-1]
        try:
            raw = fn(*args, **kwargs)
            result = _structured_envelope(fn.__name__, raw, bound_args)
        except Exception as exc:
            result = _bounded_tool_result({
                "action": fn.__name__,
                "args": bound_args,
                "ok": False,
                "error_type": type(exc).__name__,
                "message": _clean_tool_error(exc),
            })
            try:
                from tool_support import log_tool_call  # type: ignore
                log_tool_call(
                    app=app_name,
                    tool_name=fn.__name__,
                    arguments=bound_args,
                    result=result,
                    error=result.get("message") if isinstance(result, dict) else _clean_tool_error(exc),
                )
            except Exception:
                pass
            return result
        try:
            from tool_support import log_tool_call  # type: ignore
            log_tool_call(
                app=app_name,
                tool_name=fn.__name__,
                arguments=bound_args,
                result=result,
            )
        except Exception:
            pass
        return result

    # Copy identity / docs (manual copy, NOT functools.wraps — wraps sets
    # __wrapped__ and inspect.signature would then traverse to fn and pick
    # up its `-> str` return annotation again).
    wrapper.__name__ = fn.__name__
    wrapper.__qualname__ = fn.__qualname__
    wrapper.__module__ = fn.__module__
    wrapper.__doc__ = fn.__doc__
    # Annotations: keep params, drop return.
    new_annotations = dict(getattr(fn, "__annotations__", {}))
    new_annotations.pop("return", None)
    wrapper.__annotations__ = new_annotations
    # Explicit signature so FastMCP sees naked-of-return-type version.
    try:
        sig = inspect.signature(fn)
        wrapper.__signature__ = sig.replace(return_annotation=inspect.Signature.empty)
    except (TypeError, ValueError):
        pass
    return wrapper


def _install_structured_tool_wrapping() -> None:
    """Monkey-patch FastMCP.tool() so every @mcp.tool() registers a wrapped
    callable whose return is converted to a structured envelope."""
    if not _STRUCTURED_RETURNS:
        return
    try:
        from fastmcp import FastMCP  # noqa: WPS433
    except Exception:
        return
    if getattr(FastMCP.tool, "_structured_wrapped", False):
        return
    original_tool = FastMCP.tool

    def patched_tool(self, *t_args, **t_kwargs):
        # `mcp.tool(...)` may be called with or without args. The result of
        # original_tool is itself a decorator that takes the tool function.
        decorator = original_tool(self, *t_args, **t_kwargs)

        def wrapping_decorator(fn):
            return decorator(_wrap_tool_callable(fn))

        return wrapping_decorator

    patched_tool._structured_wrapped = True  # type: ignore[attr-defined]
    FastMCP.tool = patched_tool


_install_structured_tool_wrapping()
