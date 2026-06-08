#!/usr/bin/env python3
"""
Reset -> observe -> act loop using Appium (XCUITest driver) for richer actions
(tap/type/swipe/home) on the iOS Simulator. Designed for reproducible benchmarks.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import logging
import os
import pathlib
import re
import shlex
import signal
import subprocess
import sys
import time
from typing import Any, Dict, List, Optional, Tuple


class TaskTimeout(Exception):
    """Raised when a single task exceeds the configured timeout."""
    pass


class RecoverableActionError(Exception):
    """Raised for action failures that should trigger replanning, not task failure."""

    def __init__(self, message: str, *, action: Optional[Dict[str, Any]] = None):
        super().__init__(message)
        self.action = action or {}

webdriver = None
XCUITestOptions = None
Image = None
ImageDraw = None

# Lazy import of LLM action generator (avoids hard dep when using subprocess mode).
_llm_gen = None


def _ensure_llm_gen():
    global _llm_gen
    if _llm_gen is not None:
        return _llm_gen
    import importlib
    _llm_gen = importlib.import_module("llm_action_generator")
    return _llm_gen


def _load_mcp_judge_trajectory(task_dir: pathlib.Path, fallback: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Return the canonical MCP trajectory the default judge should score.

    `mcp_agent_runner` writes the real per-step tool trace directly to
    task_dir/trajectory.json. The outer Appium runner also has a local
    `trajectory` list, but in MCP mode that list only reflects the wrapper
    invocation unless we replace it. This helper keeps the judge input aligned
    with the artifact a human would inspect.
    """
    path = task_dir / "trajectory.json"
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return fallback
    if not isinstance(data, list):
        return fallback
    for entry in data:
        if not isinstance(entry, dict):
            return fallback
        actions = entry.get("actions")
        if actions is not None and not isinstance(actions, list):
            return fallback
    return data


# ---------------------------------------------------------------------------
# Stuck-loop detection
# ---------------------------------------------------------------------------

def _action_key(action: dict) -> str:
    """Deterministic string key for an action dict (ignoring transient fields)."""
    ignore = {"window_size", "normalized", "method", "installed"}
    filtered = {k: v for k, v in sorted(action.items()) if k not in ignore}
    return json.dumps(filtered, sort_keys=True)


def _action_type_key(action: dict) -> str:
    """Coarse key: action type only (for fuzzy similarity checks)."""
    return action.get("action") or action.get("type") or ""


def _actions_similar(a: dict, b: dict, *, xy_threshold: float = 40.0) -> bool:
    """Return True if two action-result dicts are semantically similar.

    For tap_xy, actions within *xy_threshold* pixels are considered the same
    (the agent is tapping roughly the same spot).
    """
    if _action_type_key(a) != _action_type_key(b):
        return False
    # Exact match (ignoring transient fields)
    if _action_key(a) == _action_key(b):
        return True
    # Fuzzy match for coordinate taps
    a_type = a.get("action") or a.get("type")
    if a_type == "tap_xy" and "x" in a and "x" in b:
        dx = abs(float(a["x"]) - float(b["x"]))
        dy = abs(float(a["y"]) - float(b["y"]))
        return dx <= xy_threshold and dy <= xy_threshold
    return False


def detect_stuck(history: list, *, window: int = 3) -> Optional[str]:
    """Return a nudge string if the last *window* actions are identical/similar or oscillating."""
    if len(history) < window:
        return None
    recent = history[-window:]

    # Case 1: exact same action repeated N times
    recent_keys = [_action_key(a) for a in recent]
    if len(set(recent_keys)) == 1:
        return (
            f"You have repeated the EXACT same action {window} times in a row: {history[-1]}. "
            "This is NOT making progress. You MUST try a DIFFERENT action. "
            "Consider: scrolling to reveal new elements, pressing Home, tapping a different UI element, "
            "or emitting 'stop' if the goal is complete or impossible."
        )

    # Case 2: similar actions (e.g., tapping nearly the same coordinates)
    if all(_actions_similar(recent[0], a) for a in recent[1:]):
        return (
            f"You have performed very similar actions {window} times in a row (e.g., tapping near the same spot). "
            "This is NOT making progress. The UI element you are targeting may not be responding. "
            "Try a COMPLETELY different approach: use 'tap' with an accessibility id, press Home, "
            "launch an app by bundle_id, scroll, or emit 'stop'."
        )

    # Case 3: oscillation (A-B-A-B)
    if len(history) >= 4:
        last4 = history[-4:]
        keys4 = [_action_key(a) for a in last4]
        if keys4[0] == keys4[2] and keys4[1] == keys4[3] and keys4[0] != keys4[1]:
            return (
                f"You are oscillating between two actions: {history[-2]} and {history[-1]}. "
                "This is NOT making progress. You MUST try a completely DIFFERENT approach. "
                "Consider: scrolling, pressing Home, launching a different app, or emitting 'stop'."
            )
        # Fuzzy oscillation
        if (_actions_similar(last4[0], last4[2]) and _actions_similar(last4[1], last4[3])
                and not _actions_similar(last4[0], last4[1])):
            return (
                f"You are oscillating between two similar actions. "
                "This is NOT making progress. You MUST try a completely DIFFERENT approach."
            )
    return None


def ensure_runtime_deps():
    global webdriver, XCUITestOptions, Image, ImageDraw
    if all((webdriver, XCUITestOptions, Image, ImageDraw)):
        return
    try:
        from appium import webdriver as _webdriver
        from appium.options.ios import XCUITestOptions as _XCUITestOptions
        from PIL import Image as _Image
        from PIL import ImageDraw as _ImageDraw
    except ImportError as exc:
        raise SystemExit(
            "Missing dependencies for appium_agent.py. Install with `pip install -r requirements.txt`."
        ) from exc
    webdriver = _webdriver
    XCUITestOptions = _XCUITestOptions
    Image = _Image
    ImageDraw = _ImageDraw


def run(cmd, check=True):
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if check and proc.returncode != 0:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\nstdout: {proc.stdout}\nstderr: {proc.stderr}"
        )
    return proc


def _looks_like_missing_focus_error(exc: Exception) -> bool:
    text = str(exc).lower()
    return (
        "unable to find an element using '(null)', value '(null)'" in text
        or ("nosuchelementerror" in text and "(null)" in text)
        or ("active element" in text and ("not found" in text or "none" in text))
    )


def _is_keyboard_shown(driver) -> bool:
    """Return True if the iOS keyboard is currently visible.

    Uses WDA's ``mobile: isKeyboardShown`` endpoint.  Returns False on
    any error (e.g. WDA timeout) so callers can fall back gracefully.
    """
    try:
        return bool(driver.execute_script("mobile: isKeyboardShown"))
    except Exception:
        return False


def _recoverable_action_result(action: Dict[str, Any], error: str) -> Dict[str, Any]:
    result = {
        "action": action.get("type", "unknown"),
        "status": "recoverable_error",
        "error": error,
    }
    for key, value in action.items():
        if key != "type":
            result[key] = value
    return result


def parse_json_from_text(raw: str) -> Any:
    text = (raw or "").strip()
    if not text:
        raise RuntimeError("LLM output is empty.")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Best-effort fallback: find the first JSON object/array in noisy stdout.
        decoder = json.JSONDecoder()
        for idx, ch in enumerate(text):
            if ch not in "{[":
                continue
            try:
                parsed, _ = decoder.raw_decode(text[idx:])
                return parsed
            except json.JSONDecodeError:
                continue
        raise RuntimeError(f"LLM output is not valid JSON:\n{text}")


def collect_run_metadata(udid: str, args) -> Dict[str, Any]:
    """Capture environment versions and config for reproducibility."""
    def _cmd_version(cmd: List[str]) -> str:
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            return r.stdout.strip().split("\n")[0]
        except Exception:
            return "unknown"

    meta: Dict[str, Any] = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "udid": udid,
        "platform_version": getattr(args, "platform_version", None),
        "device_name": getattr(args, "device_name", None),
        "xcode_version": _cmd_version(["xcodebuild", "-version"]),
        "python_version": _cmd_version(["python3", "--version"]),
        "node_version": _cmd_version(["node", "--version"]),
        "appium_version": _cmd_version(["appium", "--version"]),
        "macos_version": _cmd_version(["sw_vers", "-productVersion"]),
        "llm_provider": os.environ.get("LLM_PROVIDER", "openai"),
        "llm_model": os.environ.get("LLM_MODEL", ""),
        "llm_temperature": os.environ.get("LLM_TEMPERATURE", "0"),
        "action_mode": getattr(args, "action_mode", None),
        "max_steps": getattr(args, "max_steps", None),
        "vision_only": getattr(args, "vision_only", None),
        "skip_erase": getattr(args, "skip_erase", False),
        "app_manifest": getattr(args, "app_manifest", None),
        "tasks_file": getattr(args, "tasks", None),
        "cua": getattr(args, "cua", False),
        "claude_cu": getattr(args, "claude_cu", False),
        "gemini_cu": getattr(args, "gemini_cu", False),
        "tool_use": getattr(args, "tool_use", False),
        "mcp": getattr(args, "mcp", False),
        "mcp_cua": getattr(args, "mcp_cua", False),
        "mcp_model": getattr(args, "mcp_model", None),
        "xml_agent": getattr(args, "xml_agent", False),
        "xml_no_screenshot": getattr(args, "xml_no_screenshot", False),
        "xml_exclude_hidden": getattr(args, "xml_exclude_hidden", False),
    }
    return meta


# ---------------------------------------------------------------------------
# Per-step token usage extraction & cost computation
# ---------------------------------------------------------------------------

# Pricing tables (USD per token).  Must stay in sync with llm_action_generator.py.
_PRICING: Dict[str, Dict[str, float]] = {
    # Anthropic
    "claude-opus-4-6":   {"input":  5.00 / 1_000_000, "output": 25.00 / 1_000_000},
    "claude-sonnet-4-6": {"input":  3.00 / 1_000_000, "output": 15.00 / 1_000_000},
    # OpenAI
    "gpt-5.4":           {"input":  2.50 / 1_000_000, "output": 10.00 / 1_000_000},
    "gpt-5.4-mini":      {"input":  0.40 / 1_000_000, "output":  1.60 / 1_000_000},
    # Gemini
    "gemini-3-flash-preview":  {"input": 0.15 / 1_000_000, "output":  0.60 / 1_000_000},
}
_ANTHROPIC_CACHE_WRITE_MULT = 1.25
_ANTHROPIC_CACHE_READ_MULT = 0.10
_OPENAI_CACHE_READ_MULT = 0.50


def _extract_step_usage(raw_parsed: Any) -> Optional[Dict[str, Any]]:
    """Extract a normalised usage dict from a step's raw_parsed response.

    Works for Claude CU (response_log.usage), OpenAI CUA (usage key),
    and Gemini CU (usage key).  Returns None if no usage data is found.
    """
    if not isinstance(raw_parsed, dict):
        return None

    # 1) Anthropic Claude CU: usage lives inside response_log.usage
    response_log = raw_parsed.get("response_log") or {}
    usage = response_log.get("usage") if isinstance(response_log, dict) else None

    if isinstance(usage, dict) and "input_tokens" in usage:
        return {
            "input_tokens": usage.get("input_tokens", 0),
            "output_tokens": usage.get("output_tokens", 0),
            "cache_creation_input_tokens": usage.get("cache_creation_input_tokens", 0),
            "cache_read_input_tokens": usage.get("cache_read_input_tokens", 0),
        }

    # 2) OpenAI CUA / Gemini CU: usage dict set directly by generate_actions_*
    direct_usage = raw_parsed.get("usage")
    if isinstance(direct_usage, dict) and ("input_tokens" in direct_usage or "prompt_tokens" in direct_usage):
        cached = direct_usage.get("cached_input_tokens", 0)
        return {
            "input_tokens": direct_usage.get("input_tokens", 0) or direct_usage.get("prompt_tokens", 0),
            "output_tokens": direct_usage.get("output_tokens", 0) or direct_usage.get("completion_tokens", 0),
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": cached,
        }

    return None


def _aggregate_usage(
    step_usages: List[Dict[str, Any]],
    model: str,
    provider: str,
) -> Dict[str, Any]:
    """Aggregate per-step usage into totals with cost estimate."""
    totals = {
        "input_tokens": 0,
        "output_tokens": 0,
        "cache_creation_input_tokens": 0,
        "cache_read_input_tokens": 0,
    }
    for u in step_usages:
        for k in totals:
            totals[k] += u.get(k, 0)

    totals["total_input_tokens"] = (
        totals["input_tokens"]
        + totals["cache_creation_input_tokens"]
        + totals["cache_read_input_tokens"]
    )

    # Compute cost.
    pricing = _PRICING.get(model)
    if pricing:
        base_in = pricing["input"]
        out_price = pricing["output"]
        if provider == "anthropic":
            cost = (
                totals["input_tokens"] * base_in
                + totals["cache_creation_input_tokens"] * base_in * _ANTHROPIC_CACHE_WRITE_MULT
                + totals["cache_read_input_tokens"] * base_in * _ANTHROPIC_CACHE_READ_MULT
                + totals["output_tokens"] * out_price
            )
            cost_without_cache = (
                totals["total_input_tokens"] * base_in
                + totals["output_tokens"] * out_price
            )
        elif provider == "openai":
            # OpenAI cached input tokens are charged at 50% of base input price.
            cached = totals["cache_read_input_tokens"]
            uncached = totals["input_tokens"]
            cost = (
                uncached * base_in
                + cached * base_in * _OPENAI_CACHE_READ_MULT
                + totals["output_tokens"] * out_price
            )
            cost_without_cache = (
                totals["total_input_tokens"] * base_in
                + totals["output_tokens"] * out_price
            )
        else:
            # Gemini and others — no cache discount currently.
            cost = totals["total_input_tokens"] * base_in + totals["output_tokens"] * out_price
            cost_without_cache = cost
        totals["cost"] = round(cost, 6)
        totals["cost_without_cache"] = round(cost_without_cache, 6)
        if cost_without_cache > 0:
            totals["cache_savings_pct"] = round(
                (cost_without_cache - cost) / cost_without_cache * 100, 1
            )

    totals["steps_with_usage"] = len(step_usages)
    return totals


def pin_simulator_state(udid: str):
    """Set deterministic locale, timezone, and status bar for reproducibility."""
    # Fix the status bar to a canonical time/signal so screenshots are consistent.
    run(["xcrun", "simctl", "status_bar", udid, "override",
         "--time", "9:41",
         "--batteryState", "charged",
         "--batteryLevel", "100",
         "--wifiBars", "3",
         "--cellularBars", "4"], check=False)


def reset_device(udid: str, *, erase: bool = True):
    run(["xcrun", "simctl", "shutdown", udid], check=False)
    if erase:
        run(["xcrun", "simctl", "erase", udid])
    run(["xcrun", "simctl", "boot", udid], check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])
    pin_simulator_state(udid)


# ---------------------------------------------------------------------------
# Per-app reinstall (clean slate without full erase)
# ---------------------------------------------------------------------------

# Task-level app names → bootstrap repo names (for apps that were renamed).
_APP_ALIASES: Dict[str, str] = {
    "letterboxd": "cinephile",
    "whatsapp": "quickchat",
    "linkedin": "lockedin",
}


def load_app_manifest(path: str) -> Dict[str, Dict[str, str]]:
    """Load the bootstrap app manifest JSON → {app_name: {bundle_id, app_path}}."""
    p = pathlib.Path(path)
    if not p.exists():
        return {}
    with open(p) as f:
        return json.load(f)


def _app_is_installed(udid: str, bundle_id: str) -> bool:
    """Check whether a bundle ID is currently installed on the simulator."""
    proc = run(["xcrun", "simctl", "get_app_container", udid, bundle_id], check=False)
    return proc.returncode == 0


def _get_app_data_container(udid: str, bundle_id: str) -> Optional[str]:
    """Return the data-container path for a bundle, or None."""
    proc = run(["xcrun", "simctl", "get_app_container", udid, bundle_id, "data"], check=False)
    if proc.returncode != 0:
        return None
    container = proc.stdout.strip()
    return container if container else None


# Directories inside the data container that hold user/app-generated data.
# Wiping these resets UserDefaults, SwiftData/CoreData DBs, Documents, caches,
# and any other runtime state — the app re-seeds on next launch.
_DATA_DIRS_TO_WIPE = [
    "Library/Preferences",          # UserDefaults plist files
    "Library/Application Support",  # SwiftData / CoreData stores, snapshots
    "Library/Caches",               # URL caches, image caches
    "Library/Cookies",              # Cookie storage
    "Library/SplashBoard",          # Cached launch screenshots
    "Library/Saved Application State",  # UI restoration state
    "Library/WebKit",               # WebView storage
    "Documents",                    # App document storage
    "tmp",                          # Temporary files
]

# App-group IDs used by the workspace-suite apps (Slides, Sheets, Drive, Docs).
# These are stored in a shared device-level container, not per-app.
_SHARED_APP_GROUP_IDS = [
    "group.com.iosworld.benchmark.workspacesuite",
]


def _get_sim_data_dir(udid: str) -> Optional[str]:
    """Return the simulator's root data directory (contains app groups, etc.)."""
    home = os.path.expanduser("~/Library/Developer/CoreSimulator/Devices")
    device_dir = os.path.join(home, udid, "data")
    return device_dir if os.path.isdir(device_dir) else None


def _wipe_app_data(udid: str, bundle_id: str) -> bool:
    """Delete all user data inside an app's data container.

    Returns True if something was actually cleaned, False if the container
    was already empty or could not be found.
    """
    import shutil

    container = _get_app_data_container(udid, bundle_id)
    if not container or not os.path.isdir(container):
        return False

    cleaned = False

    # Wipe known data directories.
    for rel in _DATA_DIRS_TO_WIPE:
        target = os.path.join(container, rel)
        if os.path.isdir(target):
            for entry in os.listdir(target):
                full = os.path.join(target, entry)
                try:
                    if os.path.isdir(full):
                        shutil.rmtree(full)
                    else:
                        os.remove(full)
                    cleaned = True
                except OSError as exc:
                    print(f"[reset-data] Warning: could not remove {full}: {exc}", flush=True)

    return cleaned


def _wipe_shared_group_containers(udid: str):
    """Wipe shared app-group containers at the device level.

    Apps like Slides-Sim, Sheets-Sim, Drive-Sim share a group container
    (group.com.iosworld.benchmark.workspacesuite) that lives outside any
    individual app's data container.  This must be wiped separately.
    """
    import shutil

    sim_data = _get_sim_data_dir(udid)
    if not sim_data:
        return
    group_containers = os.path.join(sim_data, "Containers", "Shared", "AppGroup")
    if not os.path.isdir(group_containers):
        return
    # Each subdirectory is a UUID; we need to find which ones match our
    # known group IDs by checking the .com.apple.mobile_container_manager.metadata.plist.
    import plistlib
    for uuid_dir in os.listdir(group_containers):
        full_path = os.path.join(group_containers, uuid_dir)
        if not os.path.isdir(full_path):
            continue
        plist_path = os.path.join(full_path, ".com.apple.mobile_container_manager.metadata.plist")
        if not os.path.isfile(plist_path):
            continue
        try:
            with open(plist_path, "rb") as f:
                meta = plistlib.load(f)
            group_id = meta.get("MCMMetadataIdentifier", "")
        except Exception:
            continue
        if group_id in _SHARED_APP_GROUP_IDS:
            # Wipe contents but keep the container directory itself.
            for entry in os.listdir(full_path):
                if entry.startswith("."):
                    continue  # Keep metadata plist.
                entry_path = os.path.join(full_path, entry)
                try:
                    if os.path.isdir(entry_path):
                        shutil.rmtree(entry_path)
                    else:
                        os.remove(entry_path)
                except OSError as exc:
                    print(f"[reset-data] Warning: could not remove group container file {entry_path}: {exc}", flush=True)
            print(f"[reset-data] Wiped shared app-group container '{group_id}'.", flush=True)


def _verify_app_data_clean(udid: str, bundle_id: str) -> bool:
    """Return True if the app's data container has no user-generated data."""
    container = _get_app_data_container(udid, bundle_id)
    if not container or not os.path.isdir(container):
        return True  # No container at all → clean.

    for rel in _DATA_DIRS_TO_WIPE:
        target = os.path.join(container, rel)
        if os.path.isdir(target) and os.listdir(target):
            return False

    return True


def reset_app_data(udid: str, app_names: List[str], manifest: Dict[str, Dict[str, str]]):
    """Terminate apps and wipe their data containers so they re-seed on next launch.

    Much faster than uninstall+reinstall — the app binary stays in place,
    only the runtime data (UserDefaults, databases, documents, caches) is
    removed.  Every app's seed-check (seedIfNeeded, fallback to SeedData,
    etc.) will fire on next launch because the persisted state is gone.

    Also wipes shared app-group containers used by the workspace-suite apps.

    Raises RuntimeError if any app's data cannot be fully cleaned after retries.
    """
    max_retries = 2

    # First: terminate all apps so none hold file locks during wipe.
    for app_name in app_names:
        repo_name = _APP_ALIASES.get(app_name, app_name)
        entry = manifest.get(repo_name) or manifest.get(app_name)
        if entry and entry.get("bundle_id"):
            run(["xcrun", "simctl", "terminate", udid, entry["bundle_id"]], check=False)

    # Second: wipe shared app-group containers (Slides, Sheets, Drive, Docs).
    _wipe_shared_group_containers(udid)

    # Third: wipe each app's individual data container and verify.
    for app_name in app_names:
        repo_name = _APP_ALIASES.get(app_name, app_name)
        entry = manifest.get(repo_name) or manifest.get(app_name)
        if not entry:
            print(f"[reset-data] No manifest entry for '{app_name}' (repo: '{repo_name}'); skipping.", flush=True)
            continue
        bundle_id = entry.get("bundle_id", "")
        if not bundle_id:
            print(f"[reset-data] No bundle_id for '{repo_name}'; skipping.", flush=True)
            continue

        for attempt in range(1, max_retries + 2):
            _wipe_app_data(udid, bundle_id)

            if _verify_app_data_clean(udid, bundle_id):
                print(f"[reset-data] Verified '{app_name}' ({bundle_id}) — data wiped, will re-seed on launch.", flush=True)
                break
            elif attempt <= max_retries:
                print(f"[reset-data] WARNING: '{app_name}' still has data after wipe (attempt {attempt}); retrying...", flush=True)
                time.sleep(0.5)
            else:
                raise RuntimeError(
                    f"[reset-data] FAILED: Could not wipe data for '{app_name}' ({bundle_id}) after {max_retries + 1} attempts"
                )


def _inject_api_keys_to_apps(udid: str, bundle_ids: List[str]) -> None:
    """Write LLM API keys into each app's UserDefaults.

    iOS simulator apps can't read the host's .env file (the bundle lives in
    DerivedData, far from the repo root).  This injects keys that each app's
    LLM service already checks via ``UserDefaults.standard``.
    """
    key = os.environ.get("OPENAI_API_KEY", "").strip().strip('"').strip("'")
    if not key:
        return
    for bid in bundle_ids:
        try:
            run(["xcrun", "simctl", "spawn", udid,
                 "defaults", "write", bid, "openai_api_key", "-string", key],
                check=False)
        except Exception:
            pass


def reseed_apps(udid: str, app_names: List[str], manifest: Dict[str, Dict[str, str]],
                seed_wait: float = 3.0, verify_wait: float = 1.0, max_retries: int = 2):
    """Launch all apps so they re-seed from hardcoded data, then terminate them.

    After reset_app_data() wipes containers, apps won't have seed data until
    they are actually launched.  This function ensures every app has been
    launched, has written its seed state to disk, and has been terminated
    *before* the task begins — guaranteeing a fully populated clean slate.

    Raises RuntimeError if any app fails to produce data after retries.
    """
    # Resolve bundle IDs.
    bid_map: Dict[str, str] = {}  # app_name → bundle_id
    for app_name in app_names:
        repo_name = _APP_ALIASES.get(app_name, app_name)
        entry = manifest.get(repo_name) or manifest.get(app_name)
        if not entry or not entry.get("bundle_id"):
            continue
        bid_map[app_name] = entry["bundle_id"]

    if not bid_map:
        return

    # Inject LLM API keys into each app's UserDefaults so in-app LLM
    # services can generate context-aware replies (the apps can't read the
    # host's .env because their bundles live in DerivedData).
    _inject_api_keys_to_apps(udid, list(bid_map.values()))

    parallel_reseed = os.environ.get("PARALLEL_RESEED_APPS", "").lower() in {"1", "true", "yes", "on"}

    for attempt in range(1, max_retries + 2):
        if parallel_reseed:
            # Fast path: launch all apps at once. This is memory-heavy because
            # simctl launch returns immediately and iOS may initialize many
            # app processes concurrently.
            for app_name, bundle_id in bid_map.items():
                run(["xcrun", "simctl", "launch", udid, bundle_id], check=False)

            time.sleep(seed_wait)

            for bundle_id in bid_map.values():
                run(["xcrun", "simctl", "terminate", udid, bundle_id], check=False)
        else:
            # Stable path: launch/seed/terminate one app at a time. This avoids
            # a large simulator process burst when multiple benchmark workers
            # reset concurrently.
            per_app_wait = float(os.environ.get("RESEED_APP_WAIT", "1.0") or "1.0")
            for app_name, bundle_id in bid_map.items():
                run(["xcrun", "simctl", "launch", udid, bundle_id], check=False)
                time.sleep(per_app_wait)
                run(["xcrun", "simctl", "terminate", udid, bundle_id], check=False)

        # Brief pause for filesystem sync after termination.
        time.sleep(verify_wait)

        # Verify all apps now have data (seed was written).
        missing = []
        for app_name, bundle_id in bid_map.items():
            if _verify_app_data_clean(udid, bundle_id):
                missing.append(app_name)

        if not missing:
            print(f"[reseed] All {len(bid_map)} apps verified — seed data populated.", flush=True)
            return

        if attempt <= max_retries:
            print(f"[reseed] WARNING: {len(missing)} apps still empty after seeding "
                  f"(attempt {attempt}): {missing[:5]}{'...' if len(missing) > 5 else ''}; "
                  f"retrying with longer wait...", flush=True)
            seed_wait += 2  # Give more time on retry.
        else:
            raise RuntimeError(
                f"[reseed] FAILED: {len(missing)} apps have no seed data after "
                f"{max_retries + 1} attempts: {missing}"
            )


def reinstall_apps(udid: str, app_names: List[str], manifest: Dict[str, Dict[str, str]]):
    """Uninstall + reinstall specific apps to clear their data (slower fallback).

    Prefer reset_app_data() for speed. This fully removes and re-installs the
    app binary, which guarantees a clean slate but is significantly slower.
    """
    for app_name in app_names:
        repo_name = _APP_ALIASES.get(app_name, app_name)
        entry = manifest.get(repo_name) or manifest.get(app_name)
        if not entry:
            print(f"[reinstall] No manifest entry for '{app_name}' (repo: '{repo_name}'); skipping.", flush=True)
            continue
        bundle_id = entry.get("bundle_id", "")
        app_path = entry.get("app_path", "")
        if not bundle_id or not app_path:
            print(f"[reinstall] Incomplete manifest for '{repo_name}'; skipping.", flush=True)
            continue
        if not pathlib.Path(app_path).exists():
            print(f"[reinstall] .app not found at '{app_path}'; skipping.", flush=True)
            continue
        # Terminate → uninstall → reinstall.
        run(["xcrun", "simctl", "terminate", udid, bundle_id], check=False)
        run(["xcrun", "simctl", "uninstall", udid, bundle_id], check=False)
        run(["xcrun", "simctl", "install", udid, app_path])
        print(f"[reinstall] Reinstalled '{app_name}' ({bundle_id})", flush=True)


def connect_driver(appium_url: str, udid: str, platform_version: str | None, device_name: str, wda_port: int | None = None):
    ensure_runtime_deps()
    opts = XCUITestOptions()
    opts.set_capability("platformName", "iOS")
    opts.set_capability("automationName", "XCUITest")
    opts.set_capability("udid", udid)
    opts.set_capability("deviceName", device_name)
    if platform_version:
        opts.set_capability("platformVersion", platform_version)
    if wda_port:
        opts.set_capability("wdaLocalPort", wda_port)
    # Increase idle timeout to prevent session death during long LLM API
    # calls (default is 60s which is too short for extended thinking).
    opts.set_capability("newCommandTimeout", 600)
    # Increase WDA proxy timeout (default 240s) to avoid mid-task proxy
    # timeouts on complex multi-app tasks.
    opts.set_capability("wdaConnectionTimeout", 480000)
    # Cap accessibility tree depth — heavy apps (e.g. MegaMart product grids,
    # TeamChat channel lists) can recurse deep enough to make getPageSource
    # exceed 60s. Default is 50. 30 is sufficient for tab-bar apps.
    opts.set_capability("snapshotMaxDepth", 30)
    # Auto-accept system alerts (location, notifications) so they don't block
    # the agent. Bootstrap also pre-grants permissions via simctl privacy, but
    # this is belt-and-suspenders for any popup that slips through (e.g. on a
    # sim that wasn't bootstrap-managed, or after a TCC daemon restart).
    opts.set_capability("autoAcceptAlerts", True)
    if os.environ.get("APPIUM_HEADLESS", "").lower() in {"1", "true", "yes"}:
        opts.set_capability("isHeadless", True)
        opts.set_capability("appium:isHeadless", True)
    driver = webdriver.Remote(appium_url, options=opts)
    driver.implicitly_wait(2)
    return driver


def _quit_driver_with_timeout(driver, timeout: int = 15) -> None:
    """Call driver.quit() with a timeout to avoid blocking forever on stuck WDA."""
    from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeout
    pool = ThreadPoolExecutor(1)
    try:
        pool.submit(driver.quit).result(timeout=timeout)
    except FuturesTimeout:
        logging.warning("driver.quit() timed out after %ds — abandoning session", timeout)
    except Exception:
        pass
    finally:
        pool.shutdown(wait=False, cancel_futures=True)


def get_driver_udid(driver) -> Optional[str]:
    caps = getattr(driver, "capabilities", {}) or {}
    for key in ("appium:udid", "udid"):
        value = caps.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


_page_source_needs_reconnect: bool = False  # module-level: signal driver reconnect needed


def observe(driver, step_dir: pathlib.Path, *, overlay: Optional[Tuple[float, float]] = None, window_size: Optional[Dict[str, Any]] = None, skip_source: bool = False, xml_agent: bool = False) -> Dict[str, Any]:
    """Capture screenshot + UI XML into *step_dir* and return observation dict."""
    global _page_source_needs_reconnect
    step_dir.mkdir(parents=True, exist_ok=True)
    ts = time.strftime("%Y%m%d-%H%M%S")
    shot_path = step_dir / "screenshot.png"
    source_path = step_dir / "ui.xml"
    active_el = None
    try:
        el = driver.switch_to.active_element
        attrs = {}
        for attr in ["type", "name", "label", "value", "placeholder"]:
            try:
                attrs[attr] = el.get_attribute(attr)
            except Exception:
                continue
        if any(attrs.values()):
            active_el = attrs
    except Exception:
        active_el = None
    try:
        driver.save_screenshot(str(shot_path))
    except Exception as e:
        logging.warning("save_screenshot failed — WDA session may be corrupted: %s", e)
        raise RuntimeError(f"Cannot capture screenshot (WDA session corrupted): {e}") from e
    if skip_source:
        source = None
    else:
        # Ensure the Appium session is bound to the foreground app, not
        # SpringBoard.  When Claude CU mode drives taps via raw coordinates
        # the Appium session context never updates, so getPageSource would
        # return the SpringBoard tree instead of the active app's tree.
        try:
            app_info = driver.execute_script("mobile: activeAppInfo")
            fg_bundle = app_info.get("bundleId", "") if isinstance(app_info, dict) else ""
            if fg_bundle and fg_bundle != "com.apple.springboard":
                driver.activate_app(fg_bundle)
        except Exception as e:
            logging.debug("activeAppInfo probe failed (non-fatal): %s", e)

        try:
            from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeout
            _src_pool = ThreadPoolExecutor(1)

            def _get_source_lean():
                # Use mobile:source with excludedAttributes to skip heavy XML
                # attributes that inflate tree size without affecting element
                # targeting.  When xml_agent is active we must keep visible,
                # accessible, enabled, and index — the tree builder relies on
                # them to filter hidden nodes and identify interactive elements.
                try:
                    excluded = "traits" if xml_agent else "visible,accessible,enabled,rect,traits,index"
                    return driver.execute_script("mobile: source", {
                        "format": "xml",
                        "excludedAttributes": excluded,
                    })
                except Exception:
                    # Fall back to standard page_source if mobile:source fails
                    return driver.page_source

            fut = _src_pool.submit(_get_source_lean)
            try:
                source = fut.result(timeout=60)
            except FuturesTimeout:
                logging.warning("getPageSource timed out after 60s — falling back to screenshot-only")
                source = None
                # Don't block on shutdown — the hung thread will die with the pool.
                _src_pool.shutdown(wait=False, cancel_futures=True)
                # Signal that the driver needs reconnection — the orphaned
                # thread's HTTP request blocks WDA for all subsequent commands.
                _page_source_needs_reconnect = True
            else:
                source_path.write_text(source, encoding="utf-8")
                _src_pool.shutdown(wait=False)
        except Exception as e:
            logging.warning("getPageSource failed — falling back to screenshot-only: %s", e)
            source = None
            if "session does not exist" in str(e).lower() or "session not found" in str(e).lower():
                _page_source_needs_reconnect = True
    annotated_path = None
    if overlay:
        ensure_runtime_deps()
        try:
            img = Image.open(shot_path)
            draw = ImageDraw.Draw(img)
            ox, oy = overlay
            if window_size and window_size.get("width") and window_size.get("height"):
                sx = img.width / window_size["width"]
                sy = img.height / window_size["height"]
                ox *= sx
                oy *= sy
            r = 8
            draw.ellipse((ox - r, oy - r, ox + r, oy + r), fill="red")
            annotated_path = step_dir / "screenshot_annotated.png"
            img.save(annotated_path)
        except Exception:
            annotated_path = None
    obs = {"timestamp": ts, "screenshot": str(shot_path)}
    if source is not None:
        obs["source"] = str(source_path)
    if annotated_path:
        obs["annotated_screenshot"] = str(annotated_path)
    if active_el:
        obs["active_element"] = active_el
    # Persist observation metadata.
    (step_dir / "observation.json").write_text(json.dumps(obs, indent=2), encoding="utf-8")
    return obs


def _get_window_size(driver, cached: Optional[Dict[str, Any]], action: Dict[str, Any]) -> Dict[str, Any]:
    """Return cached window size or fetch from driver; raise RecoverableActionError on failure."""
    if cached:
        return cached
    try:
        return driver.get_window_size()
    except Exception as exc:
        raise RecoverableActionError(
            f"{action.get('type')} failed — could not get window size (WDA session issue): {exc}",
            action=action,
        ) from exc


def _perform_action_with_timeout(
    driver, action: Dict[str, Any], *,
    udid: Optional[str] = None,
    cached_window_size: Optional[Dict[str, Any]] = None,
    timeout: int = 30,
):
    """Run perform_action with a wall-clock timeout.

    If the action takes longer than *timeout* seconds, it's a sign that WDA
    has become sluggish/stale.  Raises ``RecoverableActionError`` so the
    caller can reconnect and let the LLM re-plan.
    """
    from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeout
    pool = ThreadPoolExecutor(1)
    try:
        fut = pool.submit(perform_action, driver, action, udid=udid, cached_window_size=cached_window_size)
        return fut.result(timeout=timeout)
    except FuturesTimeout:
        logging.warning("perform_action timed out after %ds — WDA likely stale (action=%s)", timeout, action.get("type"))
        raise RecoverableActionError(
            f"Action '{action.get('type')}' timed out after {timeout}s — WDA session is stale",
            action=action,
        )
    except RecoverableActionError:
        raise  # pass through
    except Exception:
        raise  # pass through other errors (proxy timeout, etc.)
    finally:
        pool.shutdown(wait=False, cancel_futures=True)


def perform_action(driver, action: Dict[str, Any], *, udid: Optional[str] = None, cached_window_size: Optional[Dict[str, Any]] = None):
    a_type = action.get("type")
    if not a_type:
        raise ValueError("Action missing 'type'")

    if a_type == "tap":
        using = action.get("using", "accessibility id")
        value = action.get("value")
        if not value:
            raise ValueError("tap action requires 'value'")
        # Primary lookup: requested strategy (default "accessibility id").
        # Fallback when accessibility-id misses: NSPredicate matching either
        # `name` or `label`. SwiftUI's TabView/.tabItem renders tab buttons
        # whose `name` is the SF Symbol (e.g. "house.fill") and whose `label`
        # is the visible text (e.g. "Home"); the .accessibilityIdentifier on
        # the tab content view is NOT surfaced to the tab button. Matching by
        # label catches that case while preserving id-based behavior for apps
        # with explicit `.accessibilityIdentifier(...)` on tappable elements.
        last_exc = None
        try:
            el = driver.find_element(using, value)
            el.click()
        except Exception as exc:
            last_exc = exc
            if using == "accessibility id":
                # escape any embedded double-quotes in the value
                escaped = value.replace('"', '\\"')
                predicate = f'name == "{escaped}" OR label == "{escaped}"'
                try:
                    el = driver.find_element("-ios predicate string", predicate)
                    el.click()
                    return {"action": "tap", "using": "label_or_name", "value": value}
                except Exception as exc2:
                    last_exc = exc2
            raise RecoverableActionError(
                f"tap failed — element '{value}' not found or stale: {last_exc}",
                action=action,
            ) from last_exc
        return {"action": "tap", "using": using, "value": value}

    if a_type == "tap_xy":
        x = action.get("x")
        y = action.get("y")
        if x is None or y is None:
            raise ValueError("tap_xy action requires x and y")
        window_size = _get_window_size(driver, cached_window_size, action)
        # Convert from 0-1000 coordinate space to point coordinates.
        x = float(x) / 1000.0 * window_size["width"]
        y = float(y) / 1000.0 * window_size["height"]
        try:
            driver.execute_script("mobile: tap", {"x": x, "y": y})
        except Exception as exc:
            err = str(exc).lower()
            if "stale" in err or "not present" in err or "proxy" in err:
                raise RecoverableActionError(
                    f"tap_xy failed (transient): {exc}", action=action,
                ) from exc
            raise
        return {"action": "tap_xy", "x": x, "y": y, "normalized": True, "window_size": window_size}

    if a_type == "type":
        text = action.get("text", "")
        # Pre-check: is the keyboard visible?  If not, fail fast with a
        # recoverable error so the model learns to tap a text field first.
        if not _is_keyboard_shown(driver):
            raise RecoverableActionError(
                "type action could not run because no keyboard is visible. "
                "Tap a text field to bring up the keyboard before typing.",
                action={"type": "type", "text": text},
            )
        try:
            driver.execute_script("mobile: type", {"text": text})
            return {"action": "type", "text": text, "method": "mobile:type"}
        except Exception as exc1:
            # Fallback: send keys to the currently focused element
            try:
                active = driver.switch_to.active_element
                active.send_keys(text)
                return {"action": "type", "text": text, "method": "send_keys_active"}
            except Exception as exc2:
                if _looks_like_missing_focus_error(exc1) or _looks_like_missing_focus_error(exc2):
                    raise RecoverableActionError(
                        "type action could not run because no focused text field was available. "
                        "Tap a text field before typing.",
                        action={"type": "type", "text": text},
                    ) from exc2
                raise RuntimeError(f"type action failed; mobile:type and send_keys_active both failed: {exc2}")

    if a_type == "swipe":
        direction = action.get("direction", "up")
        x = action.get("x")
        y = action.get("y")
        try:
            if x is not None and y is not None:
                # Coordinate-based swipe from a specific origin (0-1000 space).
                window_size = _get_window_size(driver, cached_window_size, action)
                w, h = window_size["width"], window_size["height"]
                x = float(x) / 1000.0 * w
                y = float(y) / 1000.0 * h
                # Use model-provided distance if available, otherwise default 30%.
                frac = float(action.get("distance_fraction", 0.3))
                offsets = {"up": (0, -h * frac), "down": (0, h * frac),
                           "left": (-w * frac, 0), "right": (w * frac, 0)}
                dx, dy = offsets.get(direction, (0, -h * frac))
                end_x = max(0, min(w, x + dx))
                end_y = max(0, min(h, y + dy))
                driver.execute_script("mobile: dragFromToForDuration", {
                    "fromX": x, "fromY": y, "toX": end_x, "toY": end_y, "duration": 0.3,
                })
                return {"action": "swipe", "direction": direction, "x": x, "y": y,
                        "normalized": True, "window_size": window_size}
            driver.execute_script("mobile: swipe", {"direction": direction})
            return {"action": "swipe", "direction": direction}
        except RecoverableActionError:
            raise
        except Exception as exc:
            raise RecoverableActionError(
                f"swipe {direction} failed: {exc}", action=action,
            ) from exc

    if a_type == "hover":
        x = action.get("x")
        y = action.get("y")
        duration = action.get("duration", 2.0)
        if x is None or y is None:
            raise ValueError("hover action requires x and y")
        window_size = _get_window_size(driver, cached_window_size, action)
        x = float(x) / 1000.0 * window_size["width"]
        y = float(y) / 1000.0 * window_size["height"]
        try:
            driver.execute_script("mobile: touchAndHold", {
                "x": x, "y": y, "duration": float(duration),
            })
        except Exception as exc:
            raise RecoverableActionError(
                f"hover (long press) failed at ({x:.0f}, {y:.0f}): {exc}", action=action,
            ) from exc
        return {"action": "hover", "x": x, "y": y, "duration": duration,
                "normalized": True, "window_size": window_size}

    if a_type == "wait":
        duration = action.get("duration", 2.0)
        time.sleep(float(duration))
        return {"action": "wait", "duration": duration}

    if a_type == "home":
        try:
            driver.execute_script("mobile: pressButton", {"name": "home"})
        except Exception as exc:
            raise RecoverableActionError(
                f"home button press failed: {exc}", action=action,
            ) from exc
        return {"action": "home"}

    if a_type == "launch_app":
        bundle_id = action.get("bundle_id")
        if not bundle_id:
            raise ValueError("launch_app requires bundle_id")
        installed = None
        try:
            installed = driver.execute_script("mobile: isAppInstalled", {"bundleId": bundle_id})
        except Exception:
            pass
        if installed is False:
            raise RecoverableActionError(
                f"launch_app failed: app '{bundle_id}' is not installed on this device.",
                action=action,
            )
        try:
            driver.execute_script("mobile: launchApp", {"bundleId": bundle_id})
        except Exception as exc:
            raise RecoverableActionError(
                f"launch_app failed for '{bundle_id}': {exc}", action=action,
            ) from exc
        return {"action": "launch_app", "bundle_id": bundle_id, "installed": installed if installed is not None else "unknown"}

    if a_type == "terminate_app":
        bundle_id = action.get("bundle_id")
        if not bundle_id:
            raise ValueError("terminate_app requires bundle_id")
        try:
            driver.execute_script("mobile: terminateApp", {"bundleId": bundle_id})
        except Exception as exc:
            raise RecoverableActionError(
                f"terminate_app failed for '{bundle_id}': {exc}", action=action,
            ) from exc
        return {"action": "terminate_app", "bundle_id": bundle_id}

    if a_type == "open_url":
        url = action.get("url")
        if not url:
            raise ValueError("open_url requires url")
        try:
            target_udid = udid or get_driver_udid(driver)
            if target_udid:
                run(["xcrun", "simctl", "openurl", target_udid, url])
                return {"action": "open_url", "url": url, "method": "simctl_openurl", "udid": target_udid}

            driver.execute_script("mobile: launchApp", {"bundleId": "com.apple.mobilesafari"})
            driver.activate_app("com.apple.mobilesafari")
            target = None
            for locator in [
                ("accessibility id", "URL"),
                ("accessibility id", "Address"),
                ("accessibility id", "Search or enter website name"),
                (
                    "ios predicate string",
                    'type == "XCUIElementTypeTextField" AND '
                    '(name CONTAINS[c] "Address" OR label CONTAINS[c] "Address" OR '
                    'name CONTAINS[c] "Search" OR label CONTAINS[c] "Search" OR '
                    'name CONTAINS[c] "website")',
                ),
            ]:
                try:
                    target = driver.find_element(*locator)
                    break
                except Exception:
                    continue
            if target is None:
                raise RecoverableActionError(
                    "open_url failed: could not locate Safari address bar.",
                    action=action,
                )
            target.click()
            target.clear()
            target.send_keys(url + "\n")
            return {"action": "open_url", "url": url, "locator": target.get_attribute("name") or target.get_attribute("label")}
        except RecoverableActionError:
            raise
        except Exception as exc:
            raise RecoverableActionError(
                f"open_url failed for '{url}': {exc}", action=action,
            ) from exc

    raise ValueError(f"Unsupported action type: {a_type}")


def log_event(event_type: str, payload: dict, task_log: Optional[List[Dict[str, Any]]] = None):
    entry = {"event": event_type, **payload}
    print(json.dumps(entry), flush=True)
    if task_log is not None:
        task_log.append(entry)


def _sanitize_conversation_for_log(conversation: list) -> list:
    """Strip base64 image data from conversation messages for logging."""
    sanitized = []
    for msg in conversation:
        entry: Dict[str, Any] = {"role": msg["role"], "text": msg["text"]}
        images = msg.get("images") or []
        if images:
            entry["image_count"] = len(images)
        sanitized.append(entry)
    return sanitized


def generate_actions_subprocess(cmd: str, payload: Dict[str, Any]) -> Tuple[List[Dict[str, Any]], Optional[str], Any, str]:
    """Call an external LLM command to generate actions. Reads JSON on stdin, writes JSON on stdout."""
    proc = subprocess.run(
        shlex.split(cmd),
        input=json.dumps(payload),
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"Agent command failed: {cmd}\nstdout: {proc.stdout}\nstderr: {proc.stderr}")
    parsed = parse_json_from_text(proc.stdout)
    reasoning = None
    actions = parsed
    if isinstance(parsed, dict):
        if "actions" not in parsed:
            raise RuntimeError("LLM output dict must include 'actions'")
        actions = parsed.get("actions", [])
        reasoning = parsed.get("summary") or parsed.get("reasoning")
    if not isinstance(actions, list):
        raise RuntimeError("LLM output 'actions' must be a JSON array")
    return actions, reasoning, parsed, proc.stdout


def _flatten_benchmark_tasks(data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Flatten the nested benchmark_tasks.json format into a flat task list.

    The nested format has:
      - single_app_tasks: {app_name: [{id, task, ...}, ...]}
      - multi_app_tasks: [{id, task, apps_involved, ...}, ...]
      - memory_personalization_tasks: [{id, task, apps_involved, ...}, ...]

    Each task uses "task" (not "goal") and "id" (not "name").  We normalise
    them so the rest of the pipeline can use "goal" and "name" uniformly.
    """
    tasks: List[Dict[str, Any]] = []

    # single_app_tasks — dict of app_name → list of tasks
    for app_tasks in (data.get("single_app_tasks") or {}).values():
        if isinstance(app_tasks, list):
            tasks.extend(app_tasks)

    # multi_app_tasks — flat list
    for t in data.get("multi_app_tasks") or []:
        if isinstance(t, dict):
            tasks.append(t)

    # memory_personalization_tasks — flat list
    for t in data.get("memory_personalization_tasks") or []:
        if isinstance(t, dict):
            tasks.append(t)

    # Normalise field names: "id" → "name", "task" → "goal".
    for t in tasks:
        if "name" not in t and "id" in t:
            t["name"] = t["id"]
        if "goal" not in t and "task" in t:
            t["goal"] = t["task"]

    return tasks


def load_tasks(path: pathlib.Path) -> List[Dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))

    # Support the nested benchmark_tasks.json format.
    if isinstance(data, dict) and ("single_app_tasks" in data or "multi_app_tasks" in data):
        tasks = _flatten_benchmark_tasks(data)
        if not tasks:
            raise SystemExit("Benchmark tasks file contains no tasks")
        return tasks

    if not isinstance(data, list):
        raise SystemExit("Tasks file must be a JSON array")
    if not data:
        raise SystemExit("Tasks file is empty")
    for idx, task in enumerate(data, start=1):
        if not isinstance(task, dict):
            raise SystemExit(f"Task {idx} must be a JSON object")
        if "actions" in task and task["actions"] is not None and not isinstance(task["actions"], list):
            raise SystemExit(f"Task {idx} has 'actions' but it is not a list")
        if "actions" not in task and "goal" not in task:
            raise SystemExit(f"Task {idx} must include 'actions' or 'goal'")
    return data


def sanitize_task_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", name)[:80]


def task_output_dir_name(task: Dict[str, Any], fallback_iteration: int) -> str:
    task_name = task.get("name") or task.get("id") or f"task-{fallback_iteration}"
    task_index = int(task.get("_original_index", fallback_iteration - 1)) + 1
    return f"{task_index:02d}-{sanitize_task_name(task_name)}"


def main():
    parser = argparse.ArgumentParser(description="Appium-powered reset -> observe -> act loop for iOS Simulator.")
    parser.add_argument("--tasks", required=True, help="Path to JSON tasks file (array). Each task must include an 'actions' list or a 'goal'.")
    parser.add_argument("--artifact-dir", default=os.environ.get("ARTIFACT_DIR", "results"), help="Directory for screenshots/logs")
    parser.add_argument("--run-dir", help="Optional directory for this run. Defaults to ARTIFACT_DIR/run-<timestamp>.")
    parser.add_argument("--task-root-dir", help="Optional directory for final per-task artifacts. Defaults to --run-dir.")
    parser.add_argument("--udid", default=os.environ.get("SIMCTL_UDID"), help="Simulator UDID")
    parser.add_argument("--appium-url", default=os.environ.get("APPIUM_URL", "http://127.0.0.1:4723"), help="Appium server URL")
    parser.add_argument("--platform-version", default=os.environ.get("PLATFORM_VERSION"), help="iOS platform version (optional)")
    parser.add_argument("--device-name", default=os.environ.get("DEVICE_NAME", "iPhone"), help="Simulator device name for capabilities")
    parser.add_argument("--agent-cmd", help="External command for the agent LLM. Receives JSON on stdin, emits JSON (actions + reasoning) on stdout.")
    parser.add_argument("--action-mode", choices=["batch", "step"], default="batch", help="batch = LLM returns full action list; step = one action at a time with observe between.")
    parser.add_argument("--max-steps", type=int, default=50, help="Maximum LLM calls per task in step mode.")
    parser.add_argument("--no-reset", action="store_true", help="Skip shutdown/boot between tasks.")
    parser.add_argument("--skip-erase", action="store_true", help="Do not erase simulator between tasks (faster but less reproducible).")
    parser.add_argument("--app-manifest", default=os.environ.get("APP_MANIFEST"), help="Path to .app_manifest.json (enables between-task data wipe + reseed for clean slate; default: from APP_MANIFEST env).")
    parser.add_argument("--no-reinstall", action="store_true", help="Disable between-task data reset (faster but tasks may see state from prior tasks).")
    parser.add_argument("--post-reset-wait", type=float, default=2.0, help="Seconds to wait after connecting driver before first observation (avoid black screens).")
    parser.add_argument("--post-action-wait", type=float, default=2.0, help="Seconds to wait after each action before capturing the next observation (avoid transition frames).")
    parser.add_argument("--evaluate", action="store_true", help="After all tasks, ask the LLM to judge whether each goal was achieved (adds evaluation to results).")
    parser.add_argument("--stuck-window", type=int, default=3, help="Number of identical consecutive actions before stuck detection fires (default 3).")
    parser.add_argument("--inprocess", action="store_true", help="Call llm_action_generator in-process instead of spawning a subprocess (faster, requires deps).")
    parser.add_argument("--vision-only", action="store_true", default=True, help="(Default) Vision-only mode: the LLM receives only the screenshot, no UI XML or accessibility identifiers.")
    parser.add_argument("--no-vision-only", dest="vision_only", action="store_false", help="Disable vision-only mode: include UI XML and accessibility identifiers in the LLM prompt.")
    parser.add_argument("--wda-port", type=int, default=None, help="WebDriverAgent local port (default: auto). Set unique values when running multiple simulators in parallel.")
    parser.add_argument("--task-timeout", type=int, default=0, help="Per-task timeout in seconds (default: 0 = no timeout). Tasks exceeding this are marked as failed.")
    parser.add_argument("--cua", action="store_true", help="Force CUA (Computer Use Agent) mode using OpenAI Responses API. Auto-detected for GPT/OpenAI CUA-capable models.")
    parser.add_argument("--claude-cu", action="store_true", help="Force Claude Computer Use mode. Auto-detected for Claude Sonnet/Opus CUA-capable models.")
    parser.add_argument("--gemini-cu", action="store_true", help="Force Gemini Computer Use mode. Auto-detected for gemini-*-computer-use and gemini-3.1-* models.")
    parser.add_argument("--qwen-cu", action="store_true", help="Force Qwen Computer Use mode (mobile_use cookbook contract on a vLLM endpoint). Auto-detected for any Qwen-VL family (qwen-vl, qwen2-vl, qwen2.5-vl, qwen3-vl) and for the entire Qwen3.5 family — dense (Qwen3.5-4B, Qwen3.5-9B) and MoE (Qwen3.5-35B-A3B) — which ships multimodal without the -VL suffix. Requires VLLM_BASE_URL pointing at vLLM launched with --enable-auto-tool-choice --tool-call-parser hermes.")
    parser.add_argument("--xml-agent", action="store_true", help="XML agent mode: send the full UI accessibility tree to the LLM as the primary input. Screenshots included if model supports vision (multimodal). Works with any Chat Completions provider.")
    parser.add_argument("--xml-no-screenshot", action="store_true", help="When using --xml-agent, disable screenshot attachment even for vision-capable models (text-only XML mode).")
    parser.add_argument("--xml-exclude-hidden", action="store_true", help="When using --xml-agent, exclude non-visible elements from the accessibility tree (default: include all elements).")
    parser.add_argument("--mcp", action="store_true", help="MCP tool_use agent mode (Qwen-only): instead of raw tap/swipe actions, Qwen3.5/Qwen3-VL calls high-level per-app MCP tools (e.g. teamchat.send_message, megamart.search_products). This is the paper's qwen35-mcp configuration. Requires a Qwen model.")
    parser.add_argument("--tool-use", action="store_true", help="Unified Vision+Tools mode (Qwen-only): MCP tool calling with mobile_use CUA enabled by default. The paper's qwen35-mcp-cua configuration.")
    parser.add_argument("--mcp-model", default=None, help="Qwen model for --mcp/--tool-use mode (default: LLM_MODEL env, else qwen3.5-35B-a3). MCP mode is Qwen-only.")
    parser.add_argument("--mcp-screenshots", action="store_true", help="When using --mcp, include a screenshot in each tool_result alongside the UI tree XML. Gives Qwen-VL visual grounding.")
    parser.add_argument("--mcp-cua", action="store_true", help="When using --mcp, add Qwen's cookbook `mobile_use` tool alongside MCP tools so the agent can fall back to raw pixel click/type when no MCP tool covers a step.")
    parser.add_argument("--mcp-confirmation-tools", action="store_true", help="When using --mcp/--tool-use, include expanded prepare_*/confirm_*(draft_id) safety-pair tools. Off by default to keep tool payloads compact.")
    args = parser.parse_args()

    if not args.udid:
        raise SystemExit("Provide a simulator UDID via --udid or SIMCTL_UDID")
    if args.max_steps < 1:
        raise SystemExit("--max-steps must be >= 1")
    if args.post_reset_wait < 0 or args.post_action_wait < 0:
        raise SystemExit("--post-reset-wait and --post-action-wait must be >= 0")
    if args.stuck_window < 2:
        raise SystemExit("--stuck-window must be >= 2")

    # Auto-detect CUA mode from model name.
    use_cua = args.cua
    if not use_cua and args.inprocess:
        llm_gen = _ensure_llm_gen()
        if hasattr(llm_gen, "is_cua_model"):
            model = os.environ.get("LLM_MODEL", "gpt-5.4")
            if llm_gen.is_cua_model(model):
                use_cua = True
                print(f"[cua] Auto-detected CUA mode for model '{model}'", flush=True)
    # CUA requires step mode + inprocess.
    if use_cua:
        if args.action_mode != "step":
            args.action_mode = "step"
            print("[cua] Forcing --action-mode=step for CUA", flush=True)
        args.inprocess = True

    # Auto-detect Claude Computer Use mode from model name.
    use_claude_cu = args.claude_cu
    if not use_claude_cu and not use_cua and args.inprocess:
        llm_gen = _ensure_llm_gen()
        if hasattr(llm_gen, "is_claude_cu_model"):
            model = os.environ.get("LLM_MODEL", "")
            if llm_gen.is_claude_cu_model(model):
                use_claude_cu = True
                print(f"[claude-cu] Auto-detected Claude CU mode for model '{model}'", flush=True)
    if use_claude_cu:
        if args.action_mode != "step":
            args.action_mode = "step"
            print("[claude-cu] Forcing --action-mode=step for Claude CU", flush=True)
        args.inprocess = True

    # Auto-detect Gemini Computer Use mode from model name.
    use_gemini_cu = args.gemini_cu
    if not use_gemini_cu and not use_cua and not use_claude_cu and args.inprocess:
        llm_gen = _ensure_llm_gen()
        if hasattr(llm_gen, "is_gemini_cu_model"):
            model = os.environ.get("LLM_MODEL", "")
            if llm_gen.is_gemini_cu_model(model):
                use_gemini_cu = True
                print(f"[gemini-cu] Auto-detected Gemini CU mode for model '{model}'", flush=True)
    if use_gemini_cu:
        if args.action_mode != "step":
            args.action_mode = "step"
            print("[gemini-cu] Forcing --action-mode=step for Gemini CU", flush=True)
        args.inprocess = True

    # Auto-detect Qwen Computer Use mode from model name (vLLM-served Qwen3-VL).
    use_qwen_cu = args.qwen_cu
    if (not use_qwen_cu and not use_cua and not use_claude_cu and not use_gemini_cu
            and args.inprocess):
        llm_gen = _ensure_llm_gen()
        if hasattr(llm_gen, "is_qwen_cu_model"):
            model = os.environ.get("LLM_MODEL", "")
            if llm_gen.is_qwen_cu_model(model):
                use_qwen_cu = True
                print(f"[qwen-cu] Auto-detected Qwen CU mode for model '{model}'", flush=True)
    if use_qwen_cu:
        if args.action_mode != "step":
            args.action_mode = "step"
            print("[qwen-cu] Forcing --action-mode=step for Qwen CU", flush=True)
        args.inprocess = True

    # XML agent mode implies non-vision-only + inprocess.
    # --xml-agent is compatible with CUA/CU: the accessibility tree is
    # injected alongside the screenshot on every turn.
    if args.xml_agent:
        if args.vision_only:
            args.vision_only = False
        if not args.inprocess:
            args.inprocess = True
        xml_mode = "text-only" if args.xml_no_screenshot else "multimodal (XML + screenshot)"
        hidden_label = ", excluding hidden elements" if args.xml_exclude_hidden else ""
        cu_label = ""
        if use_cua:
            cu_label = " + CUA"
        elif use_claude_cu:
            cu_label = " + Claude CU"
        elif use_gemini_cu:
            cu_label = " + Gemini CU"
        elif use_qwen_cu:
            cu_label = " + Qwen CU"
        print(f"[xml-agent] Mode: {xml_mode}{cu_label}{hidden_label}", flush=True)
    if args.xml_no_screenshot and not args.xml_agent:
        print("[xml-agent] Warning: --xml-no-screenshot has no effect without --xml-agent", flush=True)
    if args.xml_no_screenshot and (use_cua or use_claude_cu or use_gemini_cu):
        print("[xml-agent] Warning: --xml-no-screenshot ignored for CUA/CU (screenshots required by protocol)", flush=True)
    if args.xml_exclude_hidden and not args.xml_agent:
        print("[xml-agent] Warning: --xml-exclude-hidden has no effect without --xml-agent", flush=True)

    # MCP agent mode (Qwen-only): the paper's qwen35-mcp configuration. The
    # MCP runner uses vLLM-served Qwen3.5/Qwen3-VL via OpenAI-compatible Chat
    # Completions. Explicit --mcp takes precedence over auto-detected
    # CUA/Claude-CU/Gemini-CU modes (the per-Qwen mobile_use hybrid is
    # enabled via --mcp-cua).
    use_mcp = args.mcp or args.tool_use
    if args.tool_use and not args.mcp_cua:
        args.mcp_cua = True
    if args.tool_use and args.mcp_model is None:
        args.mcp_model = os.environ.get("LLM_MODEL") or os.environ.get("MODEL") or "qwen3.5-35B-a3"
    mcp_runner = None
    if use_mcp:
        # Fail-fast Qwen-only check (paper's only MCP configuration).
        # detect_provider() would catch this too, but only after the sim
        # has been reset and the first observation taken — pre-flight here
        # so direct callers (run_task_by_id.sh, scripts/appium_agent.py)
        # get a clean rejection before any work starts.
        _mcp_model_check = args.mcp_model or os.environ.get("LLM_MODEL") or ""
        _mcp_provider_check = (os.environ.get("LLM_PROVIDER") or "").lower()
        if "qwen" not in _mcp_model_check.lower() and _mcp_provider_check not in ("vllm", "qwen"):
            raise SystemExit(
                "ERROR: --mcp / --tool-use is Qwen-only (paper's qwen35-mcp configuration). "
                f"Got --mcp-model={_mcp_model_check!r}, LLM_PROVIDER={_mcp_provider_check or 'unset'!r}. "
                "Pass --mcp-model qwen3.5-35B-a3 (or set LLM_PROVIDER=vllm + a Qwen LLM_MODEL)."
            )
        if args.action_mode != "step":
            args.action_mode = "step"
            print("[mcp] Forcing --action-mode=step for MCP mode", flush=True)
        args.inprocess = True
        # Disable any auto-detected CU modes — --mcp is explicit and takes
        # priority. (--mcp-cua enables the hybrid within MCP itself.)
        if use_cua or use_claude_cu or use_gemini_cu or use_qwen_cu:
            print(f"[mcp] Overriding auto-detected CU mode (--mcp explicit)", flush=True)
            use_cua = False
            use_claude_cu = False
            use_gemini_cu = False
            use_qwen_cu = False
        # Import the MCP runner
        import importlib.util
        _mcp_path = pathlib.Path(__file__).resolve().parent / "mcp_agent_runner.py"
        _mcp_spec = importlib.util.spec_from_file_location("mcp_agent_runner", str(_mcp_path))
        _mcp_mod = importlib.util.module_from_spec(_mcp_spec)
        _mcp_spec.loader.exec_module(_mcp_mod)
        mcp_runner = _mcp_mod
        print(f"[mcp] MCP agent mode enabled", flush=True)

    if args.action_mode == "step" and not args.agent_cmd and not args.inprocess:
        raise SystemExit("--action-mode=step requires --agent-cmd or --inprocess")
    if args.inprocess and not use_mcp:
        _ensure_llm_gen()  # fail fast if deps are missing
    ensure_runtime_deps()

    # Load app manifest — used for per-app reinstall AND for providing
    # bundle IDs to the LLM (enables launch_app action).
    app_manifest: Dict[str, Dict[str, str]] = {}
    if args.app_manifest:
        app_manifest = load_app_manifest(args.app_manifest)
        if app_manifest:
            print(f"[manifest] Loaded {len(app_manifest)} apps from {args.app_manifest}", flush=True)
        else:
            print(f"[manifest] Warning: manifest at {args.app_manifest} is empty or missing", flush=True)

    tasks_path = pathlib.Path(args.tasks)
    tasks = load_tasks(tasks_path)
    for index, task in enumerate(tasks):
        task.setdefault("_original_index", index)
    run_ts = time.strftime("%Y%m%d-%H%M%S")
    run_dir = pathlib.Path(args.run_dir) if args.run_dir else pathlib.Path(args.artifact_dir) / f"run-{run_ts}"
    run_dir.mkdir(parents=True, exist_ok=True)
    artifact_dir = run_dir
    task_root_dir = pathlib.Path(args.task_root_dir) if args.task_root_dir else artifact_dir
    task_root_dir.mkdir(parents=True, exist_ok=True)

    # ── Write run metadata for reproducibility ────────────────────
    run_meta = collect_run_metadata(args.udid, args)
    (artifact_dir / "run_metadata.json").write_text(
        json.dumps(run_meta, indent=2), encoding="utf-8"
    )

    run_manifest: List[Dict[str, Any]] = []
    llm_conversations: List[Dict[str, Any]] = []
    # Per-task trajectory data collected during the loop, evaluated afterwards.
    pending_evaluations: List[Dict[str, Any]] = []
    failed_tasks = 0

    for iteration, task in enumerate(tasks, start=1):
        task_wall_start = time.time()
        task_name = task.get("name") or task.get("id") or f"task-{iteration}"
        goal = task.get("goal")
        task_dir = task_root_dir / task_output_dir_name(task, iteration)
        steps_dir = task_dir / "steps"
        task_dir.mkdir(parents=True, exist_ok=True)
        task_log: List[Dict[str, Any]] = []
        trajectory: List[Dict[str, Any]] = []
        task_failed = False
        task_error: Optional[str] = None
        agent_answer: Optional[str] = None
        driver = None
        final_state_dir = task_dir / "final_state"
        step_usages: List[Dict[str, Any]] = []

        def _step_dir(n: int) -> pathlib.Path:
            return steps_dir / f"{n:02d}"

        def _write_step_action(step_n: int, action_data: dict, reasoning_text: Optional[str] = None):
            sd = _step_dir(step_n)
            sd.mkdir(parents=True, exist_ok=True)
            (sd / "action.json").write_text(json.dumps(action_data, indent=2), encoding="utf-8")
            if reasoning_text:
                (sd / "summary.txt").write_text(reasoning_text, encoding="utf-8")

        def _write_step_actions(step_n: int, actions_data: list, reasoning_text: Optional[str] = None):
            sd = _step_dir(step_n)
            sd.mkdir(parents=True, exist_ok=True)
            (sd / "actions.json").write_text(json.dumps(actions_data, indent=2), encoding="utf-8")
            if reasoning_text:
                (sd / "summary.txt").write_text(reasoning_text, encoding="utf-8")

        def _trajectory_step(step_n: int) -> Dict[str, Any]:
            for entry in trajectory:
                if entry.get("step") == step_n:
                    return entry
            entry: Dict[str, Any] = {"step": step_n}
            trajectory.append(entry)
            return entry

        def _record_step_observation(step_n: int, observation_data: Dict[str, Any]) -> Dict[str, Any]:
            log_event("observation", {"iteration": iteration, "task": task_name, "step": step_n, **observation_data}, task_log)
            entry = _trajectory_step(step_n)
            entry["screenshot"] = observation_data.get("screenshot")
            if observation_data.get("source"):
                entry["source"] = observation_data["source"]
            if observation_data.get("annotated_screenshot"):
                entry["annotated_screenshot"] = observation_data["annotated_screenshot"]
            return entry

        def _capture_step_observation(
            step_n: int,
            *,
            overlay: Optional[Tuple[float, float]] = None,
            window_size: Optional[Dict[str, Any]] = None,
        ) -> Dict[str, Any]:
            nonlocal driver, _cached_window_size
            global _page_source_needs_reconnect
            skip_src = (use_cua or use_claude_cu or use_gemini_cu or use_qwen_cu) and not args.xml_agent
            try:
                observation_data = observe(driver, _step_dir(step_n), overlay=overlay, window_size=window_size, skip_source=skip_src, xml_agent=args.xml_agent)
            except RuntimeError as _obs_exc:
                # save_screenshot raised — typically WDA session corrupted mid-task.
                # Try one forced reconnect + retry before giving up.
                _msg = str(_obs_exc).lower()
                if "session" in _msg or "screenshot" in _msg or "wda" in _msg:
                    logging.warning("observe() failed (likely session corrupted), attempting one-shot reconnect: %s", _obs_exc)
                    _quit_driver_with_timeout(driver)
                    driver = connect_driver(args.appium_url, args.udid, args.platform_version, args.device_name, args.wda_port)
                    try:
                        _cached_window_size = driver.get_window_size()
                    except Exception:
                        pass
                    observation_data = observe(driver, _step_dir(step_n), overlay=overlay, window_size=window_size, skip_source=skip_src, xml_agent=args.xml_agent)
                else:
                    raise
            # If getPageSource timed out, the orphaned HTTP request blocks WDA
            # for all subsequent commands.  Reconnect the driver to get a fresh session.
            if _page_source_needs_reconnect:
                _page_source_needs_reconnect = False
                logging.warning("Reconnecting Appium driver after getPageSource timeout")
                _quit_driver_with_timeout(driver)
                driver = connect_driver(args.appium_url, args.udid, args.platform_version, args.device_name, args.wda_port)
                try:
                    _cached_window_size = driver.get_window_size()
                except Exception:
                    pass
            _record_step_observation(step_n, observation_data)
            return observation_data

        def _capture_final_observation(
            *,
            overlay: Optional[Tuple[float, float]] = None,
            window_size: Optional[Dict[str, Any]] = None,
        ) -> Dict[str, Any]:
            # Skip XML source on final observation — no subsequent LLM call needs it,
            # and heavy pages (e.g. MyBank credit card) can wedge WDA for minutes.
            observation_data = observe(driver, final_state_dir, overlay=overlay, window_size=window_size, skip_source=True)
            log_event("final_observation", {"iteration": iteration, "task": task_name, **observation_data}, task_log)
            return observation_data

        # ── Per-task timeout handler (armed AFTER reset completes) ──
        def _task_timeout_handler(_signum, _frame):
            raise TaskTimeout(f"Task '{task_name}' exceeded {args.task_timeout}s timeout")

        # ── Reset + reinstall (outside the task-timeout window) ─────
        try:
            if args.no_reset:
                log_event("reset_skipped", {"iteration": iteration, "task": task_name}, task_log)
            else:
                log_event(
                    "reset_start",
                    {"iteration": iteration, "task": task_name, "erase": not args.skip_erase},
                    task_log,
                )
                reset_device(args.udid, erase=not args.skip_erase)
                log_event("reset_done", {"iteration": iteration, "task": task_name}, task_log)

            # ── Reset app data for clean slate ──────────────────────
            # Default: wipe data containers for ALL manifest apps so every
            # task starts from fresh seed data.  Much faster than reinstall
            # since the app binaries stay in place.
            if app_manifest and not args.no_reinstall:
                reset_list = list(app_manifest.keys())
                if reset_list:
                    log_event("reset_data_start", {"task": task_name, "apps": reset_list}, task_log)
                    reset_app_data(args.udid, reset_list, app_manifest)
                    log_event("reset_data_done", {"task": task_name, "apps": reset_list}, task_log)

                    # Launch all apps so they write seed data, then terminate.
                    # This guarantees seed data is fully on disk before the
                    # task begins — no race between first-launch seeding and
                    # the agent's actions.
                    log_event("reseed_start", {"task": task_name, "apps": reset_list}, task_log)
                    reseed_apps(args.udid, reset_list, app_manifest)
                    log_event("reseed_done", {"task": task_name, "apps": reset_list}, task_log)

            # Inject LLM API keys even when --no-reinstall is used (reseed
            # already handles this for the normal path, but skipping reinstall
            # means UserDefaults may lack the key from a prior wipe).
            if app_manifest:
                all_bids = [v.get("bundle_id", "") for v in app_manifest.values() if v.get("bundle_id")]
                _inject_api_keys_to_apps(args.udid, all_bids)

            _connect_attempts = int(os.getenv("APPIUM_CONNECT_RETRIES", "10"))
            # Exponential backoff cap=60s. Total worst-case wait at 10 retries:
            # 5+10+20+40+60+60+60+60+60 = ~6.3 min, much better than losing a
            # 30-min task to a transient Appium HTTP keep-alive disconnect or
            # OOM-killed Appium server.
            _backoff = 5
            for _attempt in range(_connect_attempts):
                try:
                    driver = connect_driver(args.appium_url, args.udid, args.platform_version, args.device_name, args.wda_port)
                    break
                except Exception as _conn_exc:
                    if _attempt < _connect_attempts - 1:
                        sys.stderr.write(f"[appium_agent] connect_driver attempt {_attempt + 1}/{_connect_attempts} failed: {_conn_exc}; retrying in {_backoff}s\n")
                        time.sleep(_backoff)
                        _backoff = min(_backoff * 2, 60)
                    else:
                        raise
            if args.post_reset_wait > 0:
                time.sleep(args.post_reset_wait)

            # Cache window size once so actions don't call get_window_size()
            # per-step (avoids WDA stale-session hangs on getWindowRect).
            try:
                _cached_window_size = driver.get_window_size()
            except Exception:
                _cached_window_size = None

            # Press home to ensure we start from the first home screen page
            # (app installs can leave the sim on a later page).
            try:
                driver.execute_script("mobile: pressButton", {"name": "home"})
                time.sleep(0.5)
            except Exception:
                pass

            log_event("reset_verified", {"iteration": iteration, "task": task_name}, task_log)

            # ── Arm task timeout AFTER reset is fully complete ───────
            # This ensures the reset/reinstall time doesn't eat into
            # the task's time budget.
            if args.task_timeout > 0:
                signal.signal(signal.SIGALRM, _task_timeout_handler)
                signal.alarm(args.task_timeout)

            # ── Step 1: initial pre-action observation ───────────────
            observation = _capture_step_observation(1)

            actions = task.get("actions", [])

            if args.action_mode == "batch":
                # ── Batch mode ────────────────────────────────────────
                if not actions:
                    if not args.agent_cmd and not args.inprocess:
                        raise RuntimeError(f"Task '{task_name}' has no actions and no agent-cmd/inprocess provided")
                    llm_payload = {
                        "task": task,
                        "goal": goal,
                        "observation": observation,
                        "iteration": iteration,
                    }
                    batch_conv = None
                    if args.inprocess:
                        llm = _ensure_llm_gen()
                        actions, reasoning, raw_parsed, raw_text, batch_conv = llm.generate_actions_inprocess(
                            llm_payload, vision_only=args.vision_only, xml_agent=args.xml_agent,
                            xml_no_screenshot=args.xml_no_screenshot, xml_include_hidden=not args.xml_exclude_hidden,
                            app_manifest=app_manifest,
                        )
                    else:
                        actions, reasoning, raw_parsed, raw_text = generate_actions_subprocess(args.agent_cmd, llm_payload)
                    conv_log = _sanitize_conversation_for_log(batch_conv) if batch_conv else None
                    llm_conversations.append(
                        {"iteration": iteration, "task": task_name, "step": None,
                         "messages": conv_log, "raw_parsed": raw_parsed, "raw_text": raw_text}
                    )
                    if reasoning:
                        log_event("summary", {"iteration": iteration, "task": task_name, "summary": reasoning}, task_log)
                    log_event("planned_actions", {"iteration": iteration, "task": task_name, "count": len(actions)}, task_log)

                last_tap_overlay_b: Optional[Tuple[float, float]] = None
                last_tap_ws_b: Optional[Dict[str, Any]] = None
                for step_index, action in enumerate(actions, start=1):
                    step_entry = _trajectory_step(step_index)
                    if action.get("type") in {"stop", "done"}:
                        _write_step_action(step_index, action)
                        log_event("action", {"iteration": iteration, "task": task_name, "step": step_index, "action": action.get("type")}, task_log)
                        if action.get("answer"):
                            agent_answer = action["answer"]
                        step_entry["action"] = action
                        break
                    try:
                        result = _perform_action_with_timeout(driver, action, udid=args.udid, cached_window_size=_cached_window_size, timeout=30)
                        _write_step_action(step_index, result)
                        log_event("action", {"iteration": iteration, "task": task_name, "step": step_index, **result}, task_log)
                        step_entry["action"] = result
                        if args.post_action_wait > 0:
                            time.sleep(args.post_action_wait)
                        overlay = None
                        ws = result.get("window_size") if isinstance(result, dict) else None
                        if isinstance(result, dict) and "x" in result and "y" in result:
                            overlay = (result["x"], result["y"])
                            last_tap_overlay_b = overlay
                            last_tap_ws_b = ws
                        if step_index < len(actions):
                            obs = _capture_step_observation(step_index + 1, overlay=overlay, window_size=ws)
                        else:
                            obs = _capture_final_observation(overlay=overlay, window_size=ws)
                        step_entry["post_action_screenshot"] = obs.get("screenshot")
                    except RecoverableActionError as exc:
                        error_text = str(exc)
                        recoverable_result = _recoverable_action_result(action, error_text)
                        _write_step_action(step_index, recoverable_result)
                        step_entry["action"] = recoverable_result
                        log_event(
                            "action_error",
                            {
                                "iteration": iteration,
                                "task": task_name,
                                "step": step_index,
                                "error": error_text,
                                "recoverable": True,
                            },
                            task_log,
                        )
                        if step_index < len(actions):
                            obs = _capture_step_observation(
                                step_index + 1, overlay=last_tap_overlay_b, window_size=last_tap_ws_b)
                        else:
                            obs = _capture_final_observation(
                                overlay=last_tap_overlay_b, window_size=last_tap_ws_b)
                        step_entry["post_action_screenshot"] = obs.get("screenshot")
                        last_tap_overlay_b = None
                        last_tap_ws_b = None
                        continue
                    except (Exception, SystemExit) as exc:
                        task_failed = True
                        task_error = str(exc)
                        log_event("action_error", {"iteration": iteration, "task": task_name, "step": step_index, "error": str(exc)}, task_log)
                        break

            else:
                # ── Step mode (observe -> plan -> act loop) ───────────
                # Each "step" corresponds to one LLM call.  The step
                # directory contains the pre-action observation (screenshot
                # + UI XML shown to the LLM), all planned actions, the LLM
                # conversation, and reasoning.  The post-execution screenshot
                # is captured once after the entire action batch runs (or
                # breaks early) and becomes the pre-action observation of
                # the next step.
                history: List[Dict[str, Any]] = []
                observation_history: List[Dict[str, Any]] = []
                conversation: Optional[List[Dict[str, Any]]] = None
                cua_state: Optional[Dict[str, Any]] = None
                cu_state: Optional[Dict[str, Any]] = None
                gemini_cu_state: Optional[Dict[str, Any]] = None
                qwen_cu_state: Optional[Dict[str, Any]] = None
                last_action_error: Optional[str] = None
                _llm_recoverable_consecutive = 0
                last_tap_overlay: Optional[Tuple[float, float]] = None
                last_tap_ws: Optional[Dict[str, Any]] = None
                current_observation = observation
                observation_history.append({
                    "step": 1,
                    "source_summary": current_observation.get("source", ""),
                    "active_element": current_observation.get("active_element"),
                })

                for step_num in range(1, args.max_steps + 1):
                    # Pre-action observation was already written to the
                    # step dir by either _capture_step_observation(1) for
                    # the first step or _capture_step_observation(N) at
                    # the end of the previous step.
                    step_dir = _step_dir(step_num)
                    step_dir.mkdir(parents=True, exist_ok=True)

                    # ── Call LLM ──────────────────────────────────────
                    stuck_hint = detect_stuck(history, window=args.stuck_window)
                    if stuck_hint:
                        log_event("stuck_detected", {"iteration": iteration, "task": task_name, "step": step_num, "hint": stuck_hint}, task_log)

                    llm_payload = {
                        "task": task, "goal": goal, "observation": current_observation,
                        "iteration": iteration, "step": step_num, "history": history,
                    }
                    if last_action_error:
                        llm_payload["last_action_error"] = last_action_error

                    try:
                        if use_cua:
                            # ── CUA path (Responses API) ─────────────────
                            llm = _ensure_llm_gen()
                            planned, reasoning, raw_parsed, raw_text, cua_state = llm.generate_actions_cua(
                                llm_payload, cua_state=cua_state,
                                xml_agent=args.xml_agent, xml_include_hidden=not args.xml_exclude_hidden,
                                app_manifest=app_manifest,
                            )
                        elif use_claude_cu:
                            # ── Claude Computer Use path (Messages API) ──
                            llm = _ensure_llm_gen()
                            planned, reasoning, raw_parsed, raw_text, cu_state = llm.generate_actions_claude_cu(
                                llm_payload, cu_state=cu_state,
                                xml_agent=args.xml_agent, xml_include_hidden=not args.xml_exclude_hidden,
                                app_manifest=app_manifest,
                            )
                        elif use_gemini_cu:
                            # ── Gemini Computer Use path (generateContent) ──
                            llm = _ensure_llm_gen()
                            planned, reasoning, raw_parsed, raw_text, gemini_cu_state = llm.generate_actions_gemini_cu(
                                llm_payload, cu_state=gemini_cu_state,
                                xml_agent=args.xml_agent, xml_include_hidden=not args.xml_exclude_hidden,
                                app_manifest=app_manifest,
                            )
                        elif use_qwen_cu:
                            # ── Qwen Computer Use path (vLLM mobile_use) ──
                            llm = _ensure_llm_gen()
                            planned, reasoning, raw_parsed, raw_text, qwen_cu_state = llm.generate_actions_qwen_cu(
                                llm_payload, cu_state=qwen_cu_state,
                                xml_agent=args.xml_agent,
                                xml_no_screenshot=args.xml_no_screenshot,
                                xml_include_hidden=not args.xml_exclude_hidden,
                                app_manifest=app_manifest,
                            )
                        elif use_mcp:
                            # ── MCP tool_use path — delegates to mcp_agent_runner ──
                            # Runs the full tool_use loop for this task against
                            # vLLM-served Qwen3.5 / Qwen3-VL (MCP mode is the
                            # paper's Qwen-only configuration; the runner
                            # rejects any non-Qwen model).
                            _task_apps = task.get("apps") or task.get("apps_involved") or []
                            if not _task_apps and task.get("app"):
                                _task_apps = [task["app"]]
                            if not _task_apps:
                                _task_apps = list(app_manifest.keys()) if app_manifest else []
                            # Determine model — MCP is Qwen-only, default to the
                            # paper's qwen3.5-35B-a3 if nothing was set.
                            _env_model = os.environ.get("LLM_MODEL", "")
                            _mcp_model = args.mcp_model or _env_model or "qwen3.5-35B-a3"
                            _provider = mcp_runner.detect_provider(_mcp_model)

                            # Configure the SimulatorBridge with per-worker CLI
                            # values (crucial for parallel runs where each worker
                            # has its own UDID / Appium port). Overrides any
                            # values previously read from env vars at import time.
                            try:
                                # mcp_agent_runner already added mcps/ to sys.path
                                from simulator_base import SimulatorBridge as _SB
                                _sb_inst = _SB.get()
                                _sb_inst.configure(
                                    udid=args.udid,
                                    appium_url=args.appium_url,
                                    device_name=args.device_name,
                                    platform_version=args.platform_version,
                                )
                                # Share the agent's already-warm driver with the
                                # bridge.  Without this, the bridge calls
                                # connect_driver() → creates a SECOND Appium
                                # session on the same WDA → WDA only allows
                                # one session at a time → existing session
                                # gets killed → 'Session does not exist' 404s
                                # on getPageSource and 'Cannot capture
                                # screenshot' on save_screenshot.
                                # Sharing one driver = one session.
                                _sb_inst.driver = driver
                                _sb_inst._has_primed = True
                            except Exception as _cfg_exc:
                                print(f"[mcp] Warning: SimulatorBridge.configure() failed: {_cfg_exc}", flush=True)

                            # Run the full agent loop for this task. Pass
                            # artifact_dir + task_id so the runner's
                            # TrajectoryRecorder writes per-step screenshots
                            # and the rich trajectory.json directly into
                            # this task's benchmark dir — instead of an
                            # orphan results/mcp_<ts>/task/ dir.  Without
                            # this, the evaluator only saw the single stop
                            # action, not the agent's per-tool calls.
                            _result = mcp_runner.run_mcp_agent(
                                goal=goal,
                                app_names=_task_apps,
                                max_steps=args.max_steps,
                                model=_mcp_model,
                                provider=_provider,
                                verbose=False,
                                with_screenshots=args.mcp_screenshots,
                                with_cua=args.mcp_cua,
                                with_confirmation_tools=args.mcp_confirmation_tools,
                                artifact_dir=task_dir.parent,
                                task_id=task_dir.name,
                            )
                            # Refresh agent's driver from the bridge — if the
                            # bridge reconnected internally (e.g. via
                            # screenshot_base64's reconnect-on-session-error
                            # path), our local 'driver' would otherwise
                            # point at a closed session.
                            try:
                                _new_drv = _SB.get().driver
                                if _new_drv is not None and _new_drv is not driver:
                                    driver = _new_drv
                            except Exception:
                                pass

                            _answer = _result.get("answer") or ""
                            planned = [{"type": "stop", "answer": _answer}]
                            reasoning = _answer
                            raw_parsed = {
                                "actions": planned,
                                "summary": f"MCP agent ({_provider}) ran {_result.get('steps', 0)} tool calls",
                                "cache_stats": _result.get("cache_stats", {}),
                            }
                            # Persist the detailed MCP trajectory (per-tool-call
                            # trace) alongside the standard trajectory.json so
                            # analysis tools can audit which tools the agent
                            # used and what they returned.
                            try:
                                _mcp_traj_path = task_dir / "mcp_trajectory.json"
                                _mcp_traj_path.write_text(json.dumps({
                                    "provider": _provider,
                                    "model": _mcp_model,
                                    "apps": _task_apps,
                                    "with_screenshots": args.mcp_screenshots,
                                    "with_cua": args.mcp_cua,
                                    "with_confirmation_tools": args.mcp_confirmation_tools,
                                    "tool_use": args.tool_use,
                                    "success": _result.get("success"),
                                    "steps": _result.get("steps"),
                                    "answer": _answer,
                                    "cache_stats": _result.get("cache_stats", {}),
                                    "trajectory": _result.get("trajectory", []),
                                }, indent=2, default=str), encoding="utf-8")
                            except Exception as _mcp_save_exc:
                                print(f"[mcp] Warning: failed to save mcp_trajectory.json: {_mcp_save_exc}", flush=True)
                            rich_trajectory = _load_mcp_judge_trajectory(task_dir, trajectory)
                            if rich_trajectory is not trajectory:
                                trajectory[:] = rich_trajectory
                            raw_text = _answer
                            conversation = None  # MCP manages its own conversation
                            if _answer:
                                agent_answer = _answer
                            planned = []

                        elif args.inprocess:
                            llm = _ensure_llm_gen()
                            planned, reasoning, raw_parsed, raw_text, conversation = llm.generate_actions_inprocess(
                                llm_payload, stuck_hint=stuck_hint,
                                observation_history=observation_history, vision_only=args.vision_only,
                                xml_agent=args.xml_agent, xml_no_screenshot=args.xml_no_screenshot,
                                xml_include_hidden=not args.xml_exclude_hidden, app_manifest=app_manifest,
                                conversation=conversation,
                            )
                        else:
                            if stuck_hint:
                                llm_payload["stuck_hint"] = stuck_hint
                            if observation_history:
                                llm_payload["observation_history"] = observation_history
                            if args.vision_only:
                                llm_payload["vision_only"] = True
                            planned, reasoning, raw_parsed, raw_text = generate_actions_subprocess(args.agent_cmd, llm_payload)
                    except Exception as _llm_exc:
                        # Check for LLMRecoverableError (imported lazily).
                        _llm_mod = _ensure_llm_gen()
                        _LLMRecoverable = getattr(_llm_mod, "LLMRecoverableError", None)
                        if _LLMRecoverable and isinstance(_llm_exc, _LLMRecoverable):
                            _llm_recoverable_consecutive += 1
                            error_text = str(_llm_exc)
                            log_event("llm_recoverable_error", {
                                "iteration": iteration, "task": task_name,
                                "step": step_num, "error": error_text,
                                "consecutive": _llm_recoverable_consecutive,
                            }, task_log)
                            if _llm_recoverable_consecutive >= 3:
                                task_failed = True
                                task_error = f"LLM recoverable error repeated {_llm_recoverable_consecutive}x: {error_text}"
                                step_entry = _trajectory_step(step_num)
                                step_entry["llm_error"] = task_error
                                (step_dir / "llm_error.txt").write_text(task_error, encoding="utf-8")
                                break
                            last_action_error = f"LLM error (will retry): {error_text}"
                            sys.stderr.write(f"[appium_agent] LLM recoverable error on step {step_num}: {error_text[:200]}\n")
                            # Reset CU state so next call starts a fresh turn.
                            if use_gemini_cu:
                                gemini_cu_state = None
                            if use_qwen_cu:
                                qwen_cu_state = None
                            continue
                        step_entry = _trajectory_step(step_num)
                        step_entry["llm_error"] = str(_llm_exc)
                        (step_dir / "llm_error.txt").write_text(str(_llm_exc), encoding="utf-8")
                        raise

                    # LLM call succeeded — reset consecutive error counter.
                    _llm_recoverable_consecutive = 0

                    # Extract per-step token usage for cost aggregation.
                    _step_usage = _extract_step_usage(raw_parsed)
                    if _step_usage:
                        step_usages.append(_step_usage)

                    # Log conversation messages and raw response.
                    if use_cua:
                        conv_entry = {
                            "iteration": iteration, "task": task_name, "step": step_num,
                            "cua_state": {
                                "response_id": cua_state.get("response_id") if cua_state else None,
                                "call_id": cua_state.get("call_id") if cua_state else None,
                            },
                            "raw_parsed": raw_parsed, "raw_text": raw_text,
                        }
                        llm_conversations.append(conv_entry)
                        # Save per-step LLM messages (request payload + response).
                        request_log = raw_parsed.get("request_log") if isinstance(raw_parsed, dict) else None
                        if request_log:
                            (step_dir / "llm_messages.json").write_text(
                                json.dumps({"request": request_log, "response": {k: v for k, v in (raw_parsed or {}).items() if k != "request_log"}}, indent=2), encoding="utf-8")
                    elif use_claude_cu:
                        conv_entry = {
                            "iteration": iteration, "task": task_name, "step": step_num,
                            "claude_cu_state": {
                                "tool_use_ids": cu_state.get("tool_use_ids") if cu_state else None,
                                "display_width": cu_state.get("display_width") if cu_state else None,
                                "display_height": cu_state.get("display_height") if cu_state else None,
                            },
                            "raw_parsed": raw_parsed, "raw_text": raw_text,
                        }
                        llm_conversations.append(conv_entry)
                        request_log = raw_parsed.get("request_log") if isinstance(raw_parsed, dict) else None
                        if request_log:
                            (step_dir / "llm_messages.json").write_text(
                                json.dumps({"request": request_log, "response": {k: v for k, v in (raw_parsed or {}).items() if k not in ("request_log", "response_log")}, "api_response_meta": raw_parsed.get("response_log")}, indent=2), encoding="utf-8")
                    elif use_gemini_cu:
                        conv_entry = {
                            "iteration": iteration, "task": task_name, "step": step_num,
                            "gemini_cu_state": {
                                "last_function_calls": gemini_cu_state.get("last_function_calls") if gemini_cu_state else None,
                                "done": gemini_cu_state.get("done") if gemini_cu_state else None,
                            },
                            "raw_parsed": raw_parsed, "raw_text": raw_text,
                        }
                        llm_conversations.append(conv_entry)
                        request_log = raw_parsed.get("request_log") if isinstance(raw_parsed, dict) else None
                        if request_log:
                            (step_dir / "llm_messages.json").write_text(
                                json.dumps({"request": request_log, "response": {k: v for k, v in (raw_parsed or {}).items() if k != "request_log"}}, indent=2), encoding="utf-8")
                    elif use_qwen_cu:
                        conv_entry = {
                            "iteration": iteration, "task": task_name, "step": step_num,
                            "qwen_cu_state": {
                                "tool_call_ids": qwen_cu_state.get("tool_call_ids") if qwen_cu_state else None,
                                "display_width": qwen_cu_state.get("display_width") if qwen_cu_state else None,
                                "display_height": qwen_cu_state.get("display_height") if qwen_cu_state else None,
                                "done": qwen_cu_state.get("done") if qwen_cu_state else None,
                            },
                            "raw_parsed": raw_parsed, "raw_text": raw_text,
                        }
                        llm_conversations.append(conv_entry)
                        request_log = raw_parsed.get("request_log") if isinstance(raw_parsed, dict) else None
                        if request_log:
                            (step_dir / "llm_messages.json").write_text(
                                json.dumps({"request": request_log, "response": {k: v for k, v in (raw_parsed or {}).items() if k not in ("request_log", "response_log")}, "api_response_meta": raw_parsed.get("response_log")}, indent=2), encoding="utf-8")
                    else:
                        conv_log = _sanitize_conversation_for_log(conversation) if conversation else None
                        llm_conversations.append(
                            {"iteration": iteration, "task": task_name, "step": step_num,
                             "messages": conv_log, "raw_parsed": raw_parsed, "raw_text": raw_text}
                        )
                        if conv_log:
                            (step_dir / "llm_messages.json").write_text(
                                json.dumps(conv_log, indent=2), encoding="utf-8")
                    (step_dir / "llm_response.txt").write_text(raw_text or "", encoding="utf-8")
                    if reasoning:
                        (step_dir / "reasoning.txt").write_text(reasoning, encoding="utf-8")

                    if reasoning:
                        log_event("summary", {"iteration": iteration, "task": task_name, "step": step_num, "summary": reasoning}, task_log)
                    log_event("planned_actions", {"iteration": iteration, "task": task_name, "step": step_num, "count": len(planned)}, task_log)
                    if not planned:
                        # CUA may return only a screenshot request (no executable
                        # actions) — if it's not done, capture a fresh screenshot
                        # and send it as computer_call_output on the next step.
                        if use_cua and cua_state and not cua_state.get("done", True):
                            sys.stderr.write(f"[CUA] Step {step_num}: screenshot requested, capturing fresh observation.\n")
                            current_observation = _capture_step_observation(
                                step_num + 1, overlay=None, window_size=None)
                            observation_history.append({
                                "step": step_num + 1,
                                "source_summary": current_observation.get("source", ""),
                                "active_element": current_observation.get("active_element"),
                            })
                            continue
                        if use_claude_cu and cu_state and not cu_state.get("done", True):
                            sys.stderr.write(f"[Claude CU] Step {step_num}: screenshot requested, capturing fresh observation.\n")
                            current_observation = _capture_step_observation(
                                step_num + 1, overlay=None, window_size=None)
                            observation_history.append({
                                "step": step_num + 1,
                                "source_summary": current_observation.get("source", ""),
                                "active_element": current_observation.get("active_element"),
                            })
                            continue
                        if use_gemini_cu and gemini_cu_state and not gemini_cu_state.get("done", True):
                            sys.stderr.write(f"[Gemini CU] Step {step_num}: screenshot requested, capturing fresh observation.\n")
                            current_observation = _capture_step_observation(
                                step_num + 1, overlay=None, window_size=None)
                            observation_history.append({
                                "step": step_num + 1,
                                "source_summary": current_observation.get("source", ""),
                                "active_element": current_observation.get("active_element"),
                            })
                            continue
                        if use_qwen_cu and qwen_cu_state and not qwen_cu_state.get("done", True):
                            sys.stderr.write(f"[Qwen CU] Step {step_num}: no actions emitted, capturing fresh observation.\n")
                            current_observation = _capture_step_observation(
                                step_num + 1, overlay=None, window_size=None)
                            observation_history.append({
                                "step": step_num + 1,
                                "source_summary": current_observation.get("source", ""),
                                "active_element": current_observation.get("active_element"),
                            })
                            continue
                        break

                    last_action_error = None

                    # ── Write all planned actions to step dir ─────────
                    _write_step_actions(step_num, planned, reasoning)

                    # ── Execute actions in batch ──────────────────────
                    step_entry = _trajectory_step(step_num)
                    executed_actions: List[Dict[str, Any]] = []
                    task_stopped = False

                    for action_idx_0, action in enumerate(planned):
                        # ── Per-action screenshot (obs_N.png) ──────
                        # Capture the screen state before each action
                        # so we have a visual record for every action
                        # in the batch, not just the LLM observation.
                        # For tap/swipe actions with coordinates, also
                        # save an annotated version showing where the
                        # action will land.
                        obs_path = step_dir / f"obs_{action_idx_0 + 1}.png"
                        try:
                            driver.save_screenshot(str(obs_path))
                            # Annotate with red dot if action targets coordinates.
                            act_x = action.get("x")
                            act_y = action.get("y")
                            if act_x is not None and act_y is not None:
                                ensure_runtime_deps()
                                try:
                                    img = Image.open(obs_path)
                                    draw = ImageDraw.Draw(img)
                                    # Convert 0-1000 normalised coords to pixels.
                                    px = float(act_x) / 1000.0 * img.width
                                    py = float(act_y) / 1000.0 * img.height
                                    r = 8
                                    draw.ellipse((px - r, py - r, px + r, py + r), fill="red")
                                    img.save(step_dir / f"obs_{action_idx_0 + 1}_annotated.png")
                                except Exception:
                                    pass
                        except Exception:
                            pass  # non-fatal; don't block execution

                        if action.get("type") in {"stop", "done"}:
                            executed_actions.append(action)
                            log_event("action", {"iteration": iteration, "task": task_name, "step": step_num, "action": action.get("type")}, task_log)
                            if action.get("answer"):
                                agent_answer = action["answer"]
                            task_stopped = True
                            break

                        try:
                            result = _perform_action_with_timeout(driver, action, udid=args.udid, cached_window_size=_cached_window_size, timeout=30)
                            history.append(result)
                            executed_actions.append(result)
                            log_event("action", {"iteration": iteration, "task": task_name, "step": step_num, **result}, task_log)
                            if args.post_action_wait > 0:
                                time.sleep(args.post_action_wait)

                            # ── Post-action screenshot (obs_N_after.png) ──
                            # Capture the screen state after each action so
                            # we have a visual record of the effect of every
                            # action in the batch, not just the final state.
                            try:
                                after_path = step_dir / f"obs_{action_idx_0 + 1}_after.png"
                                driver.save_screenshot(str(after_path))
                            except Exception:
                                pass  # non-fatal

                            # Track last tap for overlay on post-batch screenshot.
                            ws = result.get("window_size") if isinstance(result, dict) else None
                            if isinstance(result, dict) and "x" in result and "y" in result:
                                last_tap_overlay = (result["x"], result["y"])
                                last_tap_ws = ws

                        except RecoverableActionError as exc:
                            error_text = str(exc)
                            recoverable_result = _recoverable_action_result(action, error_text)
                            history.append(recoverable_result)
                            executed_actions.append(recoverable_result)
                            log_event(
                                "action_error",
                                {"iteration": iteration, "task": task_name, "step": step_num,
                                 "error": error_text, "recoverable": True},
                                task_log,
                            )

                            # ── WDA stale-session recovery ───────────
                            # If the action timed out, WDA is likely
                            # stale — reconnect before the next step so
                            # subsequent actions don't also hang.
                            if "timed out" in error_text and "WDA session is stale" in error_text:
                                sys.stderr.write(f"[appium_agent] WDA stale detected on step {step_num} — reconnecting\n")
                                log_event("wda_stale_recovery", {
                                    "iteration": iteration, "task": task_name,
                                    "step": step_num, "error": error_text[:200],
                                }, task_log)
                                _quit_driver_with_timeout(driver)
                                try:
                                    driver = connect_driver(
                                        args.appium_url, args.udid,
                                        args.platform_version, args.device_name,
                                        args.wda_port,
                                    )
                                    try:
                                        _cached_window_size = driver.get_window_size()
                                    except Exception:
                                        _cached_window_size = None
                                except Exception as recovery_exc:
                                    task_failed = True
                                    task_error = f"WDA stale recovery failed: {recovery_exc}"
                                    log_event("action_error", {"iteration": iteration, "task": task_name, "step": step_num, "error": task_error}, task_log)
                                    break

                            # Build detailed error feedback for the LLM
                            # showing which actions succeeded, which failed,
                            # and which were skipped.
                            action_idx = len(executed_actions)  # 1-based (failed action)
                            total = len(planned)
                            parts = []
                            if action_idx > 1:
                                succeeded = executed_actions[:-1]  # exclude the failed one
                                parts.append(f"Actions 1-{action_idx - 1} of {total} executed successfully:")
                                for i, a in enumerate(succeeded, 1):
                                    parts.append(f"  {i}. {json.dumps({k: v for k, v in a.items() if k not in ('window_size', 'normalized', 'method', 'installed')})}")
                            parts.append(f"Action {action_idx} of {total} FAILED: {json.dumps(action)}")
                            parts.append(f"Error: {error_text}")
                            skipped_count = total - action_idx
                            if skipped_count > 0:
                                skipped = planned[action_idx:]
                                parts.append(f"Actions {action_idx + 1}-{total} were skipped:")
                                for i, a in enumerate(skipped, action_idx + 1):
                                    parts.append(f"  {i}. {json.dumps(a)}")
                            last_action_error = "\n".join(parts)
                            break  # stop batch, LLM will re-plan
                        except (Exception, SystemExit) as exc:
                            error_msg = str(exc)
                            # Recover from Appium proxy timeouts by
                            # creating a fresh session and letting the
                            # LLM re-plan from the new screenshot.
                            if "proxy command" in error_msg.lower() or "timeout of" in error_msg.lower() or "is not present in" in error_msg.lower():
                                sys.stderr.write(f"[appium_agent] Proxy timeout on step {step_num} — recovering session\n")
                                log_event("proxy_timeout_recovery", {
                                    "iteration": iteration, "task": task_name,
                                    "step": step_num, "error": error_msg[:200],
                                }, task_log)
                                _quit_driver_with_timeout(driver)
                                try:
                                    driver = connect_driver(
                                        args.appium_url, args.udid,
                                        args.platform_version, args.device_name,
                                        args.wda_port,
                                    )
                                    try:
                                        _cached_window_size = driver.get_window_size()
                                    except Exception:
                                        _cached_window_size = None
                                    last_action_error = f"Appium session timed out and was recovered. Re-plan from current screen state."
                                    break  # break action batch, LLM re-plans
                                except Exception as recovery_exc:
                                    task_failed = True
                                    task_error = f"Proxy timeout and session recovery failed: {recovery_exc}"
                                    log_event("action_error", {"iteration": iteration, "task": task_name, "step": step_num, "error": task_error}, task_log)
                                    break
                            else:
                                task_failed = True
                                task_error = error_msg
                                log_event("action_error", {"iteration": iteration, "task": task_name, "step": step_num, "error": error_msg}, task_log)
                                break

                    step_entry["actions"] = executed_actions

                    if task_failed:
                        break

                    # ── Post-batch observation ────────────────────────
                    # Use last tap overlay so annotated screenshot shows
                    # where the final tap in the batch landed.
                    overlay = last_tap_overlay
                    ws = last_tap_ws

                    if task_stopped or step_num == args.max_steps:
                        # Final observation — write to final_state_dir,
                        # not steps/{N+1}/ (avoids orphan directories).
                        final_obs = _capture_final_observation(overlay=overlay, window_size=ws)
                        step_entry["post_action_screenshot"] = final_obs.get("screenshot")
                        break

                    current_observation = _capture_step_observation(
                        step_num + 1, overlay=overlay, window_size=ws)
                    observation_history.append({
                        "step": step_num + 1,
                        "source_summary": current_observation.get("source", ""),
                        "active_element": current_observation.get("active_element"),
                    })
                    step_entry["post_action_screenshot"] = current_observation.get("screenshot")
                    last_tap_overlay = None
                    last_tap_ws = None
        except TaskTimeout as exc:
            task_failed = True
            task_error = str(exc)
            log_event("task_timeout", {"iteration": iteration, "task": task_name, "error": task_error}, task_log)
        except (Exception, SystemExit) as exc:
            task_failed = True
            task_error = str(exc)
            log_event("task_error", {"iteration": iteration, "task": task_name, "error": task_error}, task_log)
        finally:
            # Cancel any pending alarm.
            if args.task_timeout > 0:
                signal.alarm(0)
            if driver is not None:
                _quit_driver_with_timeout(driver)

        if task_failed and task_error and "blockReason=SAFETY" in task_error:
            status = "safety_blocked"
        elif task_failed:
            status = "failed"
        else:
            status = "ok"
        if task_failed:
            failed_tasks += 1
        log_event(
            "task_complete",
            {"iteration": iteration, "task": task_name, "status": status, "error": task_error},
            task_log,
        )
        (task_dir / "events.jsonl").write_text(
            "".join(json.dumps(entry) + "\n" for entry in task_log),
            encoding="utf-8",
        )

        # ── Write per-task output files ──────────────────────────────
        # In MCP mode, the runner's TrajectoryRecorder has already written a
        # rich per-step trajectory.json into task_dir. Don't overwrite it with
        # the thin appium_agent trajectory (which only contains the single
        # final stop action) — the evaluator needs the full per-tool trace.
        if not (use_mcp and (task_dir / "trajectory.json").exists()
                and (task_dir / "steps" / "01" / "screenshot.png").exists()):
            (task_dir / "trajectory.json").write_text(json.dumps(trajectory, indent=2), encoding="utf-8")
        task_wall_seconds = round(time.time() - task_wall_start, 1)
        task_summary = {
            "task": task_name,
            "goal": goal,
            "status": status,
            "error": task_error,
            "steps": len(trajectory),
            "wall_time_seconds": task_wall_seconds,
            "agent_answer": agent_answer,
            "task_dir": str(task_dir),
        }
        # Preserve _original_index if set by split_tasks.py (needed by merge_results.py).
        if "_original_index" in task:
            task_summary["_original_index"] = task["_original_index"]
        # Aggregate token usage & cost across all steps.
        if step_usages:
            llm_model = os.environ.get("LLM_MODEL", "")
            llm_provider = os.environ.get("LLM_PROVIDER", "openai")
            task_summary["usage"] = _aggregate_usage(step_usages, llm_model, llm_provider)
        (task_dir / "task.json").write_text(json.dumps(task_summary, indent=2), encoding="utf-8")

        # Queue for post-loop evaluation.
        if args.evaluate and goal and not task_failed:
            pending_evaluations.append({
                "task_name": task_name,
                "iteration": iteration,
                "goal": goal,
                "trajectory": trajectory,
                "agent_answer": agent_answer,
                "task_dir": str(task_dir),
                "rubric": task.get("rubric"),
            })
        run_manifest.append({
            "task": task_name,
            "iteration": iteration,
            "task_dir": str(task_dir),
            "status": status,
            "error": task_error,
            "agent_answer": agent_answer,
        })

    # ── Post-loop evaluation (parallel) ─────────────────────────────
    if pending_evaluations:
        llm = _ensure_llm_gen()
        log_event("evaluation_start", {"count": len(pending_evaluations)})

        def _run_eval(entry: Dict[str, Any]) -> Dict[str, Any]:
            try:
                result = llm.evaluate_trajectory(entry["goal"], entry["trajectory"], agent_answer=entry.get("agent_answer"), rubric=entry.get("rubric"))
                return {"task_name": entry["task_name"], "iteration": entry["iteration"], **result}
            except BaseException as exc:
                return {"task_name": entry["task_name"], "iteration": entry["iteration"],
                        "success": False, "score": 0, "reasoning": f"Evaluation error: {exc}"}

        max_workers = min(len(pending_evaluations), int(os.getenv("EVAL_MAX_WORKERS", "4")))
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as pool:
            futures = {pool.submit(_run_eval, entry): entry for entry in pending_evaluations}
            for future in concurrent.futures.as_completed(futures):
                entry = futures[future]
                eval_result = future.result()
                log_event("evaluation", {"iteration": entry["iteration"], "task": entry["task_name"],
                                         "success": eval_result["success"], "score": eval_result["score"],
                                         "reasoning": eval_result["reasoning"]})
                # Patch evaluation into task.json.
                td = pathlib.Path(entry["task_dir"])
                task_json_path = td / "task.json"
                task_data = json.loads(task_json_path.read_text(encoding="utf-8"))
                task_data["evaluation"] = eval_result
                task_json_path.write_text(json.dumps(task_data, indent=2), encoding="utf-8")
                # Update manifest entry.
                for m in run_manifest:
                    if m["iteration"] == entry["iteration"]:
                        m["evaluation"] = eval_result
                        break

    # ── Write run-level summary ──────────────────────────────────────
    (artifact_dir / "summary.json").write_text(
        json.dumps({"run_dir": str(artifact_dir), "tasks": run_manifest, "failed_tasks": failed_tasks}, indent=2),
        encoding="utf-8",
    )
    (artifact_dir / "conversations.json").write_text(json.dumps(llm_conversations, indent=2), encoding="utf-8")
    log_event("complete", {"tasks": len(tasks), "failed_tasks": failed_tasks, "artifact_dir": str(artifact_dir)})
    if failed_tasks:
        raise SystemExit(1)


if __name__ == "__main__":
    sys.exit(main())
