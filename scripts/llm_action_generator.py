#!/usr/bin/env python3
"""
LLM action generator for the Appium agent.
Reads a JSON payload on stdin (task, goal, observation, iteration, step, history),
calls an LLM, and prints a JSON object with actions/reasoning to stdout.
"""
from __future__ import annotations

import base64
import io
import json
import os
import random
import re
import sys
import textwrap
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, List, Optional, Tuple

from PIL import Image

# ---------------------------------------------------------------------------
# Image resizing – keeps screenshots under a reasonable token budget.
# ---------------------------------------------------------------------------
MAX_IMAGE_DIM = int(os.getenv("LLM_MAX_IMAGE_DIM", "1536"))

# Image format for screenshots sent to LLMs.
# JPEG is ~57% smaller than PNG at quality 85 with negligible visual loss.
_IMAGE_FORMAT = os.getenv("LLM_IMAGE_FORMAT", "JPEG").upper()  # "JPEG" or "PNG"
_JPEG_QUALITY = int(os.getenv("LLM_JPEG_QUALITY", "85"))
_IMAGE_MIME = "image/jpeg" if _IMAGE_FORMAT == "JPEG" else "image/png"

# How many recent user turns keep their screenshots in the conversation history.
# None = keep all (default).  Set to e.g. "10" to trim older screenshots.
_SCREENSHOT_KEEP_RECENT: Optional[int] = (
    int(os.environ["SCREENSHOT_KEEP_RECENT"])
    if os.environ.get("SCREENSHOT_KEEP_RECENT")
    else None
)


def resize_image_for_llm(image_path: str, max_dim: int = MAX_IMAGE_DIM) -> Optional[str]:
    """Load *image_path*, resize so the longest edge <= *max_dim*, return base64."""
    if not image_path:
        return None
    try:
        with Image.open(image_path) as img:
            if img.width > max_dim or img.height > max_dim:
                ratio = min(max_dim / img.width, max_dim / img.height)
                new_size = (int(img.width * ratio), int(img.height * ratio))
                img = img.resize(new_size, Image.LANCZOS)
            buf = io.BytesIO()
            if _IMAGE_FORMAT == "JPEG":
                img = img.convert("RGB")  # drop alpha channel for JPEG
                img.save(buf, format="JPEG", quality=_JPEG_QUALITY)
            else:
                img.save(buf, format="PNG", optimize=True)
            return base64.b64encode(buf.getvalue()).decode("utf-8")
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Custom exceptions for recoverable LLM / HTTP errors.
# ---------------------------------------------------------------------------

class LLMRecoverableError(Exception):
    """Raised when an LLM call fails in a way that should not kill the task.

    The agent loop can catch this, feed the error back to the LLM as context,
    and continue to the next step.
    """


class HTTPPayloadError(Exception):
    """Raised on HTTP 400 errors that are likely caused by oversized payloads."""

    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.status_code = status_code


# ---------------------------------------------------------------------------
# Retry helper – exponential back-off for transient LLM API errors.
# ---------------------------------------------------------------------------
_RETRYABLE_HTTP_CODES = {429, 500, 502, 503, 504}
_MAX_RETRIES = int(os.getenv("LLM_MAX_RETRIES", "7"))
_RETRY_BASE_DELAY = float(os.getenv("LLM_RETRY_BASE_DELAY", "8.0"))


def retry_with_backoff(fn, *, max_retries: int = _MAX_RETRIES, base_delay: float = _RETRY_BASE_DELAY):
    """Call *fn*; on transient errors retry up to *max_retries* times."""
    last_exc = None
    for attempt in range(max_retries + 1):
        try:
            return fn()
        except urllib.error.HTTPError as exc:
            last_exc = exc
            if exc.code not in _RETRYABLE_HTTP_CODES:
                raise
        except (urllib.error.URLError, TimeoutError, ConnectionError) as exc:
            last_exc = exc
        except Exception as exc:
            # For SDK-raised rate-limit / server errors (e.g. openai.RateLimitError)
            exc_name = type(exc).__name__.lower()
            if not any(k in exc_name for k in ("rate", "timeout", "connection", "server")):
                raise
            last_exc = exc
        if attempt < max_retries:
            delay = base_delay * (2 ** attempt) + random.uniform(0, base_delay)
            sys.stderr.write(
                f"[llm_action_generator] Attempt {attempt + 1}/{max_retries + 1} failed: {last_exc}; "
                f"retrying in {delay:.1f}s\n"
            )
            time.sleep(delay)
    raise last_exc  # type: ignore[misc]

ALLOWED_ACTIONS = textwrap.dedent(
    """\
    Action schema — emit a JSON object with keys "actions" (array) and "summary" (string).
    Each action is a JSON object with "type" and the parameters listed below.

    Available actions:
      tap_xy
        Tap at a screen position using coordinates in 0-1000 space (0=top/left edge, 1000=bottom/right edge).
        Parameters: x (integer, 0-1000), y (integer, 0-1000)
        Example: {"type":"tap_xy","x":500,"y":200}

      tap
        Tap an element by accessibility identifier (pixel-perfect, preferred when identifiers are available).
        Parameters: using (string, e.g. "accessibility id"), value (string, the identifier)
        Example: {"type":"tap","using":"accessibility id","value":"Add"}

      type
        Type text into the currently focused input field. You must tap a text field first to focus it.
        IMPORTANT: Ensure the text field is focused before typing. If typing produces no result or duplicate text, tap the field again and retry.
        Parameters: text (string, the text to enter)
        Example: {"type":"type","text":"hello world"}

      swipe
        Swipe in a direction, optionally from a specific origin point.
        Parameters: direction (string, one of "up"/"down"/"left"/"right"), x (integer, optional origin 0-1000), y (integer, optional origin 0-1000)
        Example: {"type":"swipe","direction":"up"}
        Example with origin: {"type":"swipe","direction":"left","x":800,"y":500}

      launch_app
        Launch an app by bundle identifier.
        Parameters: bundle_id (string)
        Example: {"type":"launch_app","bundle_id":"com.apple.Preferences"}

      terminate_app
        Terminate a running app by bundle identifier.
        Parameters: bundle_id (string)
        Example: {"type":"terminate_app","bundle_id":"com.apple.Preferences"}

      open_url
        Open a URL in the simulator.
        Parameters: url (string)
        Example: {"type":"open_url","url":"https://example.com"}

      home
        Press the home button to return to the home screen.
        Parameters: none
        Example: {"type":"home"}

      wait
        Pause for a specified duration (seconds). Use this when you need to wait for content to load,
        animations to complete, or a delay before the next action.
        Parameters: duration (number, seconds to wait; default 2.0)
        Example: {"type":"wait","duration":3.0}

      stop
        End the task and provide your final answer. ONLY use this when you have fully completed the goal.
        Do NOT stop early — keep trying alternative approaches if your current actions are not working.
        Parameters: answer (string, REQUIRED — if the task asks you to return, tell, or report any information, you MUST include all requested data here. This is how you communicate results back to the user.)
        Example: {"type":"stop","answer":"The movie's year is 1972 and its rating is 9.2/10. It has been added to the Wishlist."}
    """
)

ALLOWED_ACTIONS_VISION_ONLY = textwrap.dedent(
    """\
    Action schema — emit a JSON object with keys "actions" (array) and "summary" (string).
    Each action is a JSON object with "type" and the parameters listed below.

    Available actions:
      tap_xy
        Tap at a screen position using coordinates in 0-1000 space (0=top/left edge, 1000=bottom/right edge).
        Parameters: x (integer, 0-1000), y (integer, 0-1000)
        Example: {"type":"tap_xy","x":500,"y":200}

      type
        Type text into the currently focused input field. You must tap a text field first to focus it.
        IMPORTANT: Ensure the text field is focused before typing. If typing produces no result or duplicate text, tap the field again and retry.
        Parameters: text (string, the text to enter)
        Example: {"type":"type","text":"hello world"}

      swipe
        Swipe in a direction, optionally from a specific origin point.
        Parameters: direction (string, one of "up"/"down"/"left"/"right"), x (integer, optional origin 0-1000), y (integer, optional origin 0-1000)
        Example: {"type":"swipe","direction":"up"}
        Example with origin: {"type":"swipe","direction":"left","x":800,"y":500}

      home
        Press the home button to return to the home screen.
        Parameters: none
        Example: {"type":"home"}

      wait
        Pause for a specified duration (seconds). Use this when you need to wait for content to load,
        animations to complete, or a delay before the next action.
        Parameters: duration (number, seconds to wait; default 2.0)
        Example: {"type":"wait","duration":3.0}

      stop
        End the task and provide your final answer. ONLY use this when you have fully completed the goal.
        Do NOT stop early — keep trying alternative approaches if your current actions are not working.
        Parameters: answer (string, REQUIRED — if the task asks you to return, tell, or report any information, you MUST include all requested data here. This is how you communicate results back to the user.)
        Example: {"type":"stop","answer":"The movie's year is 1972 and its rating is 9.2/10. It has been added to the Wishlist."}
    """
)


def build_system_prompt(*, vision_only: bool = False, xml_agent: bool = False, xml_no_screenshot: bool = False) -> str:
    """Build the system prompt with action schema, coordinate space, and grounding guidance."""
    parts = [
        'You are an iOS Simulator control agent. Reply with exactly one JSON object and no other text.',
        '',
        'Schema: {"actions":[...],"summary":"..."}',
        '',
        'Rules:',
        'You are in an agentic loop. After your actions execute, you will receive a new observation.',
        'Use the normalized 0-1000 coordinate space for all coordinates, where (0,0) is the top-left and (1000,1000) is the bottom-right.',
        'Do not chain many actions unless the next state is highly predictable.',
        'Only use stop when the task is fully complete.',
        'If uncertain, make the best grounded attempt and use the next observation to recover.',
        '',
    ]
    if xml_agent:
        if xml_no_screenshot:
            parts.append(
                "You are in TEXT-ONLY XML agent mode. Your ONLY input is the UI accessibility tree "
                "showing elements with their type, name/label, value, and centre coordinates in "
                "0-1000 space. You do NOT receive screenshots.\n\n"
                "GROUNDING STRATEGY:\n"
                "1. PREFERRED: Use 'tap' with the element's accessibility ID (shown as id=\"...\") — "
                "this is pixel-perfect and the most reliable way to interact with elements.\n"
                "2. FALLBACK: Use 'tap_xy' with the centre coordinates from the tree when no "
                "suitable ID exists.\n"
                "3. To open apps, use 'launch_app' with the bundle ID (provided in the task context) — "
                "this is faster and more reliable than navigating to the home screen and tapping icons.\n"
                "4. For text fields, tap to focus first, then use 'type' to enter text.\n"
                "5. If you need to find elements not currently in the tree, try scrolling.\n"
                "6. Elements marked [hidden] (if present) are in the DOM but not rendered on screen."
            )
        else:
            parts.append(
                "You are in MULTIMODAL XML agent mode. You receive TWO complementary inputs:\n"
                "  - SCREENSHOT: the ground truth of what is displayed on screen.\n"
                "  - ACCESSIBILITY TREE: a structured list of UI elements with type, name/label, "
                "value, accessibility IDs, and centre coordinates in 0-1000 space.\n"
                "Use the screenshot to understand visual layout and confirm what is on screen. "
                "Use the tree for precise element targeting and coordinates.\n\n"
                "GROUNDING STRATEGY:\n"
                "1. PREFERRED: Use 'tap' with the element's accessibility ID (shown as id=\"...\") — "
                "this is pixel-perfect and the most reliable way to interact with elements.\n"
                "2. FALLBACK: Use 'tap_xy' with the centre coordinates from the tree when no "
                "suitable ID exists. Cross-check the coordinates against what you see in the screenshot.\n"
                "3. To open apps, use 'launch_app' with the bundle ID (provided in the task context) — "
                "this is faster and more reliable than navigating to the home screen and tapping icons.\n"
                "4. For text fields, tap to focus first, then use 'type' to enter text.\n"
                "5. If the screenshot and tree disagree (e.g. an element appears in the tree but not "
                "on screen), trust the screenshot — the element may be off-screen or obscured.\n"
                "6. If you need to find elements not currently visible, try scrolling.\n"
                "7. Elements marked [hidden] (if present) are in the DOM but not rendered on screen."
            )
    elif vision_only:
        parts.append(
            "You are in vision-only mode: you do not have access to accessibility identifiers, "
            "UI metadata, or hidden state. Carefully estimate the centre of the element you want "
            "to tap in 0-1000 coordinates."
        )
    else:
        parts.append(
            "GROUNDING: Prefer 'tap' with an accessibility id/name from the interactive elements list — "
            "this is pixel-perfect. Only use tap_xy (integer coordinates in 0-1000 space) when no suitable identifier exists. "
            "If you do use tap_xy, cross-check against the element centres listed."
        )
    parts.append("")
    parts.append(ALLOWED_ACTIONS_VISION_ONLY if vision_only and not xml_agent else ALLOWED_ACTIONS)
    parts.append("")
    parts.append("Output requirements:")
    parts.append("Return valid JSON only. Do not use markdown or code fences.")
    parts.append('Do NOT use <function_calls>, <invoke>, or any XML-style tool tags — respond with plain JSON.')
    parts.append('"summary" should be brief and describe the immediate intent for this turn.')
    return "\n".join(parts)


def build_first_turn(
    payload: Dict[str, Any],
    img_size: Optional[tuple[int, int]],
    window_size: Optional[Dict[str, Any]],
    *,
    vision_only: bool = False,
    xml_agent: bool = False,
    xml_include_hidden: bool = True,
    app_manifest: Optional[Dict[str, Dict[str, str]]] = None,
) -> str:
    """Build the first user message with task context."""
    task = payload.get("task") if isinstance(payload.get("task"), dict) else {}
    goal = payload.get("goal") or task.get("goal") or ""
    task_name = task.get("name") or task.get("id") or ""
    observation = payload.get("observation", {})

    parts = [
        f"Task: {task_name or 'unknown'}.",
        f"Goal: {goal}",
    ]

    # Inject app bundle IDs so the model can use launch_app directly.
    # Skip for vision-only mode where launch_app isn't in the action schema.
    if app_manifest and not vision_only:
        task_apps = task.get("apps") or []
        app_lines = []
        for app_name in task_apps:
            entry = app_manifest.get(app_name)
            if entry and entry.get("bundle_id"):
                app_lines.append(f"  {app_name}: {entry['bundle_id']}")
        if app_lines:
            parts.append("Installed apps (use launch_app with these bundle IDs):\n" + "\n".join(app_lines))

    ws_w = window_size.get("width") if window_size else None
    ws_h = window_size.get("height") if window_size else None

    if observation and not vision_only:
        source_path = observation.get("source")
        if source_path:
            if xml_agent:
                tree_text = build_cleaned_accessibility_tree(
                    source_path,
                    window_width=ws_w or 393,
                    window_height=ws_h or 852,
                    include_hidden=xml_include_hidden,
                )
                if tree_text:
                    parts.append(tree_text)
            else:
                interactive_summary = extract_interactive_elements(
                    source_path,
                    window_width=ws_w or 393,
                    window_height=ws_h or 852,
                )
                if interactive_summary:
                    parts.append(interactive_summary)

        active = observation.get("active_element")
        if active:
            parts.append(f"Active element: {json.dumps(active)}")
        else:
            parts.append("Active element: none detected (you must focus a field before typing).")

    return "\n".join(parts)


def build_step_turn(
    observation: Dict[str, Any],
    step: int,
    window_size: Optional[Dict[str, Any]],
    *,
    stuck_hint: Optional[str] = None,
    last_action_error: Optional[str] = None,
    vision_only: bool = False,
    xml_agent: bool = False,
    xml_include_hidden: bool = True,
) -> str:
    """Build subsequent user messages — current observation context."""
    parts = ["Current observation:"]

    if not vision_only:
        source_path = observation.get("source")
        if source_path:
            ws_w = window_size.get("width") if window_size else None
            ws_h = window_size.get("height") if window_size else None
            if xml_agent:
                tree_text = build_cleaned_accessibility_tree(
                    source_path,
                    window_width=ws_w or 393,
                    window_height=ws_h or 852,
                    include_hidden=xml_include_hidden,
                )
                if tree_text:
                    parts.append(tree_text)
                else:
                    parts.append("⚠ Accessibility tree unavailable this step (timed out). Use the screenshot to decide your next action.")
            else:
                interactive_summary = extract_interactive_elements(
                    source_path,
                    window_width=ws_w or 393,
                    window_height=ws_h or 852,
                )
                if interactive_summary:
                    parts.append(interactive_summary)
        elif xml_agent:
            parts.append("⚠ Accessibility tree unavailable this step (timed out). Use the screenshot to decide your next action.")

    if stuck_hint:
        parts.append(f"⚠ STUCK DETECTION: {stuck_hint}")
    if last_action_error:
        parts.append(f"⚠ BATCH ERROR:\n{last_action_error}")
        parts.append("Re-plan from the current screen state. Do not repeat the same failed action. If you need to type, first focus a text field.")

    return "\n".join(parts)


def load_payload() -> Dict[str, Any]:
    raw = sys.stdin.read()
    if not raw.strip():
        raise SystemExit("No input payload on stdin")
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON on stdin: {exc}")


def env_int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None or not raw.strip():
        return default
    try:
        return int(raw)
    except ValueError:
        return default



def extract_interactive_elements(source_path: str, window_width: int = 393, window_height: int = 852) -> Optional[str]:
    """Parse the UI XML and return a compact summary of tappable elements with centres in 0-1000 space."""
    if not source_path:
        return None
    try:
        import xml.etree.ElementTree as ET
        tree = ET.parse(source_path)
    except Exception:
        return None
    interactive_types = {
        "XCUIElementTypeButton",
        "XCUIElementTypeTextField",
        "XCUIElementTypeSecureTextField",
        "XCUIElementTypeSearchField",
        "XCUIElementTypeLink",
        "XCUIElementTypeSwitch",
        "XCUIElementTypeCell",
        "XCUIElementTypeStaticText",  # often tappable labels
    }
    elements: List[str] = []
    max_elements = max(5, env_int("LLM_MAX_INTERACTIVE_ELEMENTS", 30))
    for el in tree.iter():
        el_type = el.get("type", "")
        if el_type not in interactive_types:
            continue
        enabled = el.get("enabled", "true")
        visible = el.get("visible", "true")
        if enabled == "false" or visible == "false":
            continue
        name = el.get("name", "")
        label = el.get("label", "")
        value = el.get("value", "")
        x = el.get("x")
        y = el.get("y")
        w = el.get("width")
        h = el.get("height")
        if not (x and y and w and h):
            continue
        try:
            ix, iy, iw, ih = int(x), int(y), int(w), int(h)
        except ValueError:
            continue
        if iw < 5 or ih < 5:
            continue  # skip invisible / zero-size
        cx = round((ix + iw / 2) / window_width * 1000)
        cy = round((iy + ih / 2) / window_height * 1000)
        ident = name or label or value or ""
        short_type = el_type.replace("XCUIElementType", "")
        desc = f"  {short_type}: \"{ident}\" center=({cx},{cy})"
        if value and value != ident:
            desc += f" value=\"{value[:30]}\""
        elements.append(desc)
        if len(elements) >= max_elements:
            break
    if not elements:
        return None
    return "Interactive UI elements (type, identifier, centre x,y in 0-1000 space):\n" + "\n".join(elements)


def build_cleaned_accessibility_tree(
    source_path: str,
    window_width: int = 393,
    window_height: int = 852,
    *,
    output_width: int = 1000,
    output_height: int = 1000,
    max_elements: int = 0,
    max_depth: int = 0,
    include_hidden: bool = False,
) -> Optional[str]:
    """Parse UI XML and return a compact, indented accessibility tree.

    Filters out invisible elements (unless *include_hidden* is True),
    collapses empty ``XCUIElementTypeOther`` wrappers, normalises
    coordinates to the target output space, and limits depth / element
    count for token efficiency.

    *window_width* / *window_height* describe the native coordinate space
    of the raw XML element positions (iOS logical points).  These are
    auto-detected from the root ``XCUIElementTypeApplication`` element
    when available.

    *output_width* / *output_height* set the target coordinate space for
    the tree output.  Defaults to 1000×1000 (0-1000 normalised space).
    Pass the model's display pixel dimensions (e.g. 591×1280 for Claude
    CU) to output coordinates in the model's native action space.
    """
    if not source_path:
        return None
    try:
        import xml.etree.ElementTree as ET
        tree = ET.parse(source_path)
    except Exception:
        return None

    # Auto-detect native XML coordinate space from the root Application
    # element.  Falls back to the caller-supplied window_width/window_height.
    root = tree.getroot()
    app_el = root.find(".//{http://apple.com/automation/XCUITest}XCUIElementTypeApplication")
    if app_el is None:
        app_el = root.find(".//XCUIElementTypeApplication")
    if app_el is None:
        # Try the root itself or first child.
        for candidate in [root] + list(root):
            if candidate.get("type") == "XCUIElementTypeApplication":
                app_el = candidate
                break
    if app_el is not None:
        try:
            detected_w = int(app_el.get("width", "0"))
            detected_h = int(app_el.get("height", "0"))
            if detected_w > 0 and detected_h > 0:
                window_width = detected_w
                window_height = detected_h
        except (ValueError, TypeError):
            pass

    max_elements = max_elements or max(10, env_int("LLM_XML_MAX_ELEMENTS", 200))
    max_depth = max_depth or max(3, env_int("LLM_XML_MAX_DEPTH", 15))
    element_count = [0]  # mutable counter for closure
    lines: List[str] = []

    def _is_visible(el) -> bool:
        if include_hidden:
            return True
        return el.get("visible") != "false"

    def _is_meaningful(el) -> bool:
        """Return True if element carries semantic content worth showing."""
        el_type = el.get("type", "")
        # Non-Other types are always meaningful (Button, TextField, Cell, Icon, etc.)
        if "Other" not in el_type and "Window" not in el_type:
            return True
        name = el.get("name", "")
        label = el.get("label", "")
        if name and name != "label-view":
            return True
        if label:
            return True
        if el.get("accessible") == "true":
            return True
        return False

    def _format_element(el, depth: int) -> str:
        el_type = el.get("type", "").replace("XCUIElementType", "")
        name = el.get("name", "")
        label = el.get("label", "")
        value = el.get("value", "")

        parts = [f"[{el_type}]"]
        if include_hidden and el.get("visible") == "false":
            parts.append("[hidden]")
        if name:
            parts.append(f'"{name}"')
        if label and label != name:
            parts.append(f'label="{label}"')
        if value and value != name and value != label:
            parts.append(f'value="{value[:50]}"')

        x, y, w, h = el.get("x"), el.get("y"), el.get("width"), el.get("height")
        if x and y and w and h:
            try:
                ix, iy, iw, ih = int(x), int(y), int(w), int(h)
                if iw > 0 and ih > 0:
                    cx = round((ix + iw / 2) / window_width * output_width)
                    cy = round((iy + ih / 2) / window_height * output_height)
                    parts.append(f"({cx},{cy})")
            except ValueError:
                pass

        if el.get("enabled") == "false":
            parts.append("[disabled]")

        # Mark elements that can be tapped via accessibility ID.
        if name and el.get("accessible") == "true":
            parts.append(f'id="{name}"')

        indent = "  " * depth
        return f"{indent}{' '.join(parts)}"

    def _walk(el, depth: int):
        if element_count[0] >= max_elements or depth > max_depth:
            return
        if not _is_visible(el):
            return

        children = [c for c in el if _is_visible(c)]

        if _is_meaningful(el):
            lines.append(_format_element(el, depth))
            element_count[0] += 1
            for child in children:
                _walk(child, depth + 1)
        else:
            # Collapse: skip this node, promote children.
            for child in children:
                _walk(child, depth)

    for child in root:
        _walk(child, 0)

    if not lines:
        return None
    visibility_label = "all elements including hidden" if include_hidden else "visible elements"
    if output_width == 1000 and output_height == 1000:
        coord_label = "coordinates in 0-1000 normalized space"
    else:
        coord_label = (
            f"coordinates in pixel space matching your action coordinates "
            f"(width={output_width}, height={output_height})"
        )
    return (
        f"UI Accessibility Tree ({visibility_label}, {coord_label}):\n"
        + "\n".join(lines)
    )


def encode_image(image_path: str) -> Optional[str]:
    """Encode image to base64, resizing for LLM token efficiency."""
    return resize_image_for_llm(image_path)


# ---------------------------------------------------------------------------
# CUA (Computer Use Agent) helpers
# ---------------------------------------------------------------------------
_CUA_MAX_IMAGE_DIM = int(os.getenv("CUA_MAX_IMAGE_DIM", "1536"))  # cap retina screenshots


def is_cua_model(model: str) -> bool:
    """Return True if *model* should use the CUA (Responses API) path."""
    m = (model or "").lower()
    return any(k in m for k in ("gpt-5.4", "gpt-5.4-mini"))


def is_claude_cu_model(model: str) -> bool:
    """Return True if *model* should use the Claude Computer Use path.

    Only Sonnet 4.6 and Opus 4.6 support computer use.
    """
    m = (model or "").lower()
    return any(k in m for k in ("claude-sonnet-4-6", "claude-opus-4-6"))


def encode_image_for_cua(image_path: str) -> Optional[str]:
    """Resize screenshot for CUA and return base64 PNG.

    Caps the longest edge to ``CUA_MAX_IMAGE_DIM`` (default 1280) to avoid
    grounding issues on retina-resolution screenshots.  Set to 0 to disable.
    """
    if _CUA_MAX_IMAGE_DIM > 0:
        return resize_image_for_llm(image_path, max_dim=_CUA_MAX_IMAGE_DIM)
    if not image_path:
        return None
    try:
        with open(image_path, "rb") as f:
            return base64.b64encode(f.read()).decode("utf-8")
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Claude Computer Use helpers
# ---------------------------------------------------------------------------
_CLAUDE_CU_MAX_IMAGE_DIM = int(os.getenv("CLAUDE_CU_MAX_IMAGE_DIM", "1536"))


def get_claude_cu_display_dims(image_path: str) -> Tuple[int, int]:
    """Compute display dimensions for the Claude CU tool declaration.

    Returns the (width, height) that will be declared in the computer tool
    and used to resize the screenshot before sending.  Caps the longest edge
    to ``_CLAUDE_CU_MAX_IMAGE_DIM`` (default 1536) to stay within Anthropic's
    recommended range for best accuracy.
    """
    img_size = get_image_size(image_path)
    if not img_size:
        return 393, 852  # fallback: iPhone 15 Pro logical points
    w, h = img_size
    max_dim = _CLAUDE_CU_MAX_IMAGE_DIM
    if max_dim > 0 and (w > max_dim or h > max_dim):
        ratio = min(max_dim / w, max_dim / h)
        return int(w * ratio), int(h * ratio)
    return w, h


def encode_image_for_claude_cu(
    image_path: str,
    display_width: int,
    display_height: int,
) -> Optional[str]:
    """Resize screenshot to exactly *display_width* x *display_height* and return base64.

    Claude CU returns coordinates in the pixel space of the declared display
    dimensions, so the image MUST match those dimensions to avoid coordinate
    mismatch.
    """
    if not image_path:
        return None
    try:
        with Image.open(image_path) as img:
            if img.width != display_width or img.height != display_height:
                img = img.resize((display_width, display_height), Image.LANCZOS)
            buf = io.BytesIO()
            if _IMAGE_FORMAT == "JPEG":
                img = img.convert("RGB")
                img.save(buf, format="JPEG", quality=_JPEG_QUALITY)
            else:
                img.save(buf, format="PNG", optimize=True)
            return base64.b64encode(buf.getvalue()).decode("utf-8")
    except Exception:
        return None


def is_gemini_cu_model(model: str) -> bool:
    """Return True if *model* should use the Gemini Computer Use path.

    Matches models with 'computer-use' in the name, or gemini-3-flash-preview
    which has built-in Computer Use support.

    NOTE: gemini-3.1-pro-preview and gemini-3.1-flash-* do NOT support CU
    (API returns "Computer Use is not enabled").  Use ``--gemini-cu`` to
    force CU mode if Google enables it for those models later.
    """
    m = (model or "").lower()
    if "computer-use" in m:
        return True
    # gemini-3-flash-preview has built-in CU support.
    if "gemini-3-flash" in m:
        return True
    return False


def is_qwen_cu_model(model: str) -> bool:
    """Return True if *model* should use the Qwen Computer Use path.

    Vision-capable Qwen families served via a vLLM endpoint that speak the
    cookbook's ``mobile_use`` tool contract:

    * Models with an explicit ``-VL-`` suffix (Qwen-VL, Qwen2-VL, Qwen2.5-VL,
      Qwen3-VL, future Qwen3.5-VL).
    * The entire Qwen3.5 family — both the dense variants (``Qwen3.5-4B``,
      ``Qwen3.5-9B``) and the A-series MoE (``Qwen3.5-35B-A3B``, …) — which
      ships multimodal by default; the ``-VL`` suffix was dropped starting
      with this release.

    The vLLM server must be launched with
    ``--enable-auto-tool-choice --tool-call-parser hermes`` so it returns
    OpenAI-spec ``message.tool_calls``.
    """
    m = (model or "").lower()
    if "qwen3.5" in m:
        return True
    return any(k in m for k in ("qwen-vl", "qwen2-vl", "qwen2.5-vl", "qwen3-vl"))


# ---------------------------------------------------------------------------
# Gemini Computer Use helpers
# ---------------------------------------------------------------------------
_GEMINI_CU_MAX_IMAGE_DIM = int(os.getenv("GEMINI_CU_MAX_IMAGE_DIM", "1536"))


def encode_image_for_gemini_cu(image_path: str, max_dim: int = _GEMINI_CU_MAX_IMAGE_DIM) -> Optional[str]:
    """Resize screenshot for Gemini CU and return base64.

    Gemini Computer Use recommends 1440x900 screen size.  We cap the longest
    edge to *max_dim* (default 1536) for consistency across all providers.
    """
    if not image_path:
        return None
    try:
        with Image.open(image_path) as img:
            if max_dim > 0 and (img.width > max_dim or img.height > max_dim):
                ratio = min(max_dim / img.width, max_dim / img.height)
                new_size = (int(img.width * ratio), int(img.height * ratio))
                img = img.resize(new_size, Image.LANCZOS)
            buf = io.BytesIO()
            if _IMAGE_FORMAT == "JPEG":
                img = img.convert("RGB")
                img.save(buf, format="JPEG", quality=_JPEG_QUALITY)
            else:
                img.save(buf, format="PNG", optimize=True)
            return base64.b64encode(buf.getvalue()).decode("utf-8")
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Qwen Computer Use helpers (mobile_use cookbook contract on a vLLM endpoint)
# ---------------------------------------------------------------------------
#
# Qwen3-VL's "mobile_use" tool is documented in:
#   https://github.com/QwenLM/Qwen3-VL/blob/main/cookbooks/mobile_agent.ipynb
# The model is trained on a fixed 0-999 coordinate grid regardless of the
# actual image resolution. The cookbook ALWAYS declares "The screen's
# resolution is 999x999." in the tool description, then post-processes
# model output via `coord / 999 * actual_width` to map back to pixels.
# We follow that contract verbatim: hardcode 999, divide by 999 → 0-1000
# normalised → framework rescales to the simulator window dims. We still
# resize images client-side for token control; the resize doesn't affect
# coord interpretation since the model always uses the 999×999 grid.
_QWEN_CU_GRID = 999  # cookbook constant — do NOT vary by image dim
_QWEN_CU_MAX_IMAGE_DIM = int(os.getenv("QWEN_CU_MAX_IMAGE_DIM", "1280"))

# Screenshot-history cap for Qwen CU. Tuned to fit a 32K-context vLLM
# deployment of Qwen3.5-35B-A3B (each ~1024×1024 patch ≈ 1.2-1.5k tokens
# at the cookbook 999×999 grid).
#
# Two reference patterns for Qwen3-VL/3.5 CU agents:
#   xlang-ai/OSWorld/mm_agents/qwen3vl_agent.py → history_n=4 (sliding window)
#   QwenLM/Qwen3-VL/cookbooks/mobile_agent.ipynb → 1 image (stateless)
#
# Per the Qwen3.5 model card (https://huggingface.co/Qwen/Qwen3.5-35B-A3B):
# multi-turn conversations should *strip <think>...</think>* from historical
# assistant messages and use a context-folding strategy on Tool Responses
# when token usage approaches the model's max_model_len.
#
# Defaults:
#   N=1 — matches the Qwen cookbook's stateless image policy. Empirically
#         beat N=4 on our 3-task multi-app A/B (0.620 vs 0.540 avg score),
#         at ~60% lower per-turn token cost (~9.5K vs ~24K). The XML+CUA
#         path is stateless by construction, so this constant only changes
#         behavior on the multi-turn MCP+CUA path; for that path, N=1
#         avoids reinforcing stuck loops via repeated visuals of the same
#         failed state.
#
# Override with QWEN_CU_SCREENSHOT_HISTORY (set higher value if a task
# benefits from cross-app visual continuity; set 0 to keep all screenshots).
# The global SCREENSHOT_KEEP_RECENT env var overrides this when set.
_QWEN_CU_SCREENSHOT_HISTORY = int(os.getenv("QWEN_CU_SCREENSHOT_HISTORY", "1"))


def get_qwen_cu_display_dims(image_path: str) -> Tuple[int, int]:
    """Compute the post-resize image dimensions Qwen will receive.

    Aspect-ratio resize so the longest edge is at most _QWEN_CU_MAX_IMAGE_DIM.
    These dims are NOT sent to the model (cookbook hardcodes 999×999); they
    are only used so the framework knows what bytes to actually transmit.
    """
    img_size = get_image_size(image_path)
    if not img_size:
        return 393, 852  # iPhone 15 Pro logical points
    w, h = img_size
    max_dim = _QWEN_CU_MAX_IMAGE_DIM
    if max_dim > 0 and (w > max_dim or h > max_dim):
        ratio = min(max_dim / w, max_dim / h)
        return int(w * ratio), int(h * ratio)
    return w, h


def encode_image_for_qwen_cu(
    image_path: str,
    display_width: int,
    display_height: int,
) -> Optional[str]:
    """Resize screenshot to (display_width, display_height) and return base64."""
    if not image_path:
        return None
    try:
        with Image.open(image_path) as img:
            if img.width != display_width or img.height != display_height:
                img = img.resize((display_width, display_height), Image.LANCZOS)
            buf = io.BytesIO()
            if _IMAGE_FORMAT == "JPEG":
                img = img.convert("RGB")
                img.save(buf, format="JPEG", quality=_JPEG_QUALITY)
            else:
                img.save(buf, format="PNG", optimize=True)
            return base64.b64encode(buf.getvalue()).decode("utf-8")
    except Exception:
        return None


def translate_qwen_cu_actions(
    tool_input: Dict[str, Any],
    display_width: int = 0,        # unused — cookbook contract is fixed 0-999 grid
    display_height: int = 0,       # unused — kept for signature parity
) -> List[Dict[str, Any]]:
    """Translate one ``mobile_use`` tool_input to our 0-1000 normalised actions.

    Per the Qwen3-VL mobile_agent cookbook, the model emits coordinates on a
    fixed 0-999 grid regardless of actual image size. We map 0-999 → 0-1000
    (negligible scaling drift); the framework's existing tap-execution layer
    then rescales 0-1000 → actual simulator window pixels.
    """
    translated: List[Dict[str, Any]] = []
    action = tool_input.get("action", "").lower()

    def _norm(coord) -> Tuple[int, int]:
        if not coord or len(coord) < 2:
            return 0, 0
        # Cookbook contract: model output is in [0, _QWEN_CU_GRID]. Map to
        # framework's [0, 1000] normalised space.
        x_grid = float(coord[0])
        y_grid = float(coord[1])
        x_norm = int(round(x_grid / _QWEN_CU_GRID * 1000))
        y_norm = int(round(y_grid / _QWEN_CU_GRID * 1000))
        return max(0, min(1000, x_norm)), max(0, min(1000, y_norm))

    if action == "click":
        x_n, y_n = _norm(tool_input.get("coordinate"))
        translated.append({"type": "tap_xy", "x": x_n, "y": y_n})

    elif action == "long_press":
        x_n, y_n = _norm(tool_input.get("coordinate"))
        duration = float(tool_input.get("time", 1.5) or 1.5)
        translated.append({"type": "hover", "x": x_n, "y": y_n, "duration": duration})

    elif action == "swipe":
        sx, sy = _norm(tool_input.get("coordinate"))
        ex, ey = _norm(tool_input.get("coordinate2") or tool_input.get("coordinate"))
        dx = ex - sx
        dy = ey - sy
        if abs(dy) >= abs(dx):
            direction = "up" if dy < 0 else "down"
            distance_fraction = min(abs(dy) / 1000.0, 0.9)
        else:
            direction = "left" if dx < 0 else "right"
            distance_fraction = min(abs(dx) / 1000.0, 0.9)
        swipe_action: Dict[str, Any] = {
            "type": "swipe", "direction": direction, "x": sx, "y": sy,
        }
        if distance_fraction > 0:
            swipe_action["distance_fraction"] = distance_fraction
        translated.append(swipe_action)

    elif action == "type":
        text = tool_input.get("text", "")
        if text:
            translated.append({"type": "type", "text": text})

    elif action == "system_button":
        button = (tool_input.get("button") or "").lower()
        if button == "home":
            translated.append({"type": "home"})
        elif button == "back":
            # iOS swipe-from-left-edge gesture is the standard back action.
            translated.append({"type": "swipe", "direction": "right", "x": 20, "y": 500})
        elif button == "enter":
            translated.append({"type": "type", "text": "\n"})
        elif button == "menu":
            # iOS has no Menu key; fall back to the App Switcher gesture.
            translated.append({"type": "swipe", "direction": "up", "x": 500, "y": 990,
                               "distance_fraction": 0.5})
        else:
            sys.stderr.write(f"[Qwen CU] Unknown system button: {button!r}; skipping.\n")

    elif action == "wait":
        duration = float(tool_input.get("time", 2.0) or 2.0)
        translated.append({"type": "wait", "duration": duration})

    elif action == "launch_app":
        bundle_id = str(tool_input.get("bundle_id") or "").strip()
        if bundle_id:
            translated.append({"type": "launch_app", "bundle_id": bundle_id})
        else:
            sys.stderr.write("[Qwen CU] launch_app missing bundle_id; skipping.\n")

    elif action == "answer":
        text = tool_input.get("text", "")
        translated.append({"type": "stop", "answer": text or "Task completed."})

    elif action == "terminate":
        status = (tool_input.get("status") or "success").lower()
        translated.append({"type": "stop", "answer": f"Task terminated with status={status}."})

    elif action in ("launch", "open", "open_app", "start_app", "launchapp"):
        # Common Qwen3.5 confusion: emits 'launch'/'open' instead of the
        # canonical 'launch_app'. Accept as alias when a bundle_id is present;
        # otherwise leave the warning so the model can self-correct next turn.
        bundle_id = str(tool_input.get("bundle_id") or "").strip()
        if bundle_id:
            translated.append({"type": "launch_app", "bundle_id": bundle_id})
        else:
            sys.stderr.write(f"[Qwen CU] action {action!r} missing bundle_id; skipping.\n")

    else:
        sys.stderr.write(f"[Qwen CU] Unknown action: {action!r}; skipping.\n")

    return translated


def translate_claude_cu_actions(
    tool_input: Dict[str, Any],
    display_width: int,
    display_height: int,
) -> List[Dict[str, Any]]:
    """Translate a single Claude CU tool_input to our 0-1000 normalised action space.

    Claude CU returns ONE action per tool_use block.  The *tool_input* dict
    contains ``action`` (str) and action-specific parameters.

    *display_width*/*display_height* are the dimensions passed in the tool
    definition (and used to resize screenshots via CLAUDE_CU_MAX_IMAGE_DIM).
    Claude returns coordinates in that pixel space.
    """
    translated: List[Dict[str, Any]] = []
    action = tool_input.get("action", "").lower()

    def _norm_coord(coord):
        """Normalise a [x, y] coordinate list to 0-1000 space."""
        if not coord or len(coord) < 2:
            return 0, 0
        x_px, y_px = float(coord[0]), float(coord[1])
        x_norm = int(round(x_px / display_width * 1000)) if display_width else 0
        y_norm = int(round(y_px / display_height * 1000)) if display_height else 0
        return max(0, min(1000, x_norm)), max(0, min(1000, y_norm))

    if action == "left_click":
        coord = tool_input.get("coordinate", [0, 0])
        x_n, y_n = _norm_coord(coord)
        translated.append({"type": "tap_xy", "x": x_n, "y": y_n})

    elif action == "double_click":
        coord = tool_input.get("coordinate", [0, 0])
        x_n, y_n = _norm_coord(coord)
        translated.append({"type": "tap_xy", "x": x_n, "y": y_n})
        translated.append({"type": "tap_xy", "x": x_n, "y": y_n})

    elif action == "triple_click":
        coord = tool_input.get("coordinate", [0, 0])
        x_n, y_n = _norm_coord(coord)
        for _ in range(3):
            translated.append({"type": "tap_xy", "x": x_n, "y": y_n})

    elif action == "type":
        text = tool_input.get("text", "")
        translated.append({"type": "type", "text": text})

    elif action == "key":
        key_combo = tool_input.get("text", "") or tool_input.get("key", "")
        keys_lower = key_combo.lower()
        # Split on spaces for multi-key sequences like "BackSpace BackSpace"
        # and on + for combos like "ctrl+a"
        parts = [p.strip() for p in keys_lower.replace("+", " ").split() if p.strip()]
        _claude_modifiers = {"ctrl", "control", "cmd", "command", "shift", "alt",
                             "meta", "super", "option"}
        base_parts = [p for p in parts if p not in _claude_modifiers]
        has_modifier = len(base_parts) < len(parts)
        if "return" in keys_lower or "enter" in keys_lower:
            translated.append({"type": "type", "text": "\n"})
        elif "backspace" in keys_lower or "delete" in keys_lower:
            translated.append({"type": "type", "text": "\b"})
        elif "tab" in keys_lower:
            translated.append({"type": "type", "text": "\t"})
        elif "space" in keys_lower:
            translated.append({"type": "type", "text": " "})
        elif "home" in keys_lower or "escape" in keys_lower or "esc" in keys_lower:
            translated.append({"type": "home"})
        elif has_modifier and base_parts == ["h"]:
            # ctrl+h / cmd+h = Home button
            translated.append({"type": "home"})
        elif has_modifier:
            # Modifier combos (ctrl+a, cmd+c, etc.) — not actionable on iOS, skip
            pass
        else:
            # Single character keys only (not multi-char key names like "ArrowUp")
            if len(key_combo) == 1 and key_combo.isprintable():
                translated.append({"type": "type", "text": key_combo})

    elif action == "scroll":
        coord = tool_input.get("coordinate", [display_width // 2, display_height // 2])
        x_n, y_n = _norm_coord(coord)
        # Claude CU may return scroll_direction/scroll_amount (string-based)
        # or delta_x/delta_y (numeric).  Handle both formats.
        scroll_dir = tool_input.get("scroll_direction", "")
        distance_fraction = None
        if scroll_dir:
            # scroll_direction is the SCROLL direction (where the view goes),
            # which is OPPOSITE to the swipe GESTURE direction on iOS.
            # "scroll down" = see content below = swipe UP gesture.
            _scroll_to_swipe = {"down": "up", "up": "down",
                                "left": "right", "right": "left"}
            direction = _scroll_to_swipe.get(scroll_dir.lower(), "up")
            # scroll_amount is number of "clicks" (default ~3).
            # Map each click to ~10% of screen, capped at 90%.
            scroll_amount = tool_input.get("scroll_amount", 3)
            if scroll_amount:
                distance_fraction = min(int(scroll_amount) * 0.10, 0.9)
        else:
            delta_x = tool_input.get("delta_x", 0)
            delta_y = tool_input.get("delta_y", 0)
            # Claude CU: delta_y > 0 = scroll down (see content below).
            # On iOS a swipe UP gesture scrolls the page down, so we invert.
            if abs(delta_y) >= abs(delta_x):
                direction = "up" if delta_y > 0 else "down"
                dim = display_height
                distance_px = abs(delta_y)
            else:
                direction = "left" if delta_x > 0 else "right"
                dim = display_width
                distance_px = abs(delta_x)
            if distance_px and dim:
                distance_fraction = min(distance_px / dim, 0.9)
        swipe_action: Dict[str, Any] = {"type": "swipe", "direction": direction, "x": x_n, "y": y_n}
        if distance_fraction is not None:
            swipe_action["distance_fraction"] = distance_fraction
        translated.append(swipe_action)

    elif action == "left_click_drag":
        start = tool_input.get("start_coordinate", [0, 0])
        end = tool_input.get("coordinate") or tool_input.get("end_coordinate", [0, 0])
        sx_n, sy_n = _norm_coord(start)
        dx = end[0] - start[0]
        dy = end[1] - start[1]
        # Long-press: start ≈ end
        if abs(dx) < 3 and abs(dy) < 3:
            translated.append({"type": "hover", "x": sx_n, "y": sy_n, "duration": 1.0})
        else:
            if abs(dy) >= abs(dx):
                direction = "up" if dy < 0 else "down"
            else:
                direction = "left" if dx < 0 else "right"
            swipe_action: Dict[str, Any] = {"type": "swipe", "direction": direction, "x": sx_n, "y": sy_n}
            distance_px = ((dx)**2 + (dy)**2)**0.5
            dim = display_height if direction in ("up", "down") else display_width
            if dim:
                swipe_action["distance_fraction"] = min(distance_px / dim, 0.9)
            translated.append(swipe_action)

    elif action == "wait":
        duration = tool_input.get("duration", 2)
        translated.append({"type": "wait", "duration": float(duration)})

    elif action in ("screenshot", "mouse_move", "zoom"):
        pass  # no-op on iOS

    else:
        sys.stderr.write(f"[Claude CU] Unknown action: {action!r}; skipping.\n")

    return translated


def translate_cua_actions(
    cua_actions: List[Dict[str, Any]],
    display_width: int,
    display_height: int,
) -> List[Dict[str, Any]]:
    """Translate CUA pixel-coordinate actions to our 0-1000 normalised action space.

    *display_width*/*display_height* are the dimensions of the image that CUA
    actually received (post-resize if CUA_MAX_IMAGE_DIM is set).  CUA returns
    coordinates in that pixel space, so normalisation must use these values.
    """
    translated: List[Dict[str, Any]] = []

    def _norm(x_px, y_px):
        x_n = int(round(float(x_px) / display_width * 1000)) if display_width else 0
        y_n = int(round(float(y_px) / display_height * 1000)) if display_height else 0
        return max(0, min(1000, x_n)), max(0, min(1000, y_n))

    for action in cua_actions:
        a_type = (action.get("type") or "").lower()

        if a_type == "click":
            x_norm, y_norm = _norm(action.get("x", 0), action.get("y", 0))
            translated.append({"type": "tap_xy", "x": x_norm, "y": y_norm})

        elif a_type == "double_click":
            x_norm, y_norm = _norm(action.get("x", 0), action.get("y", 0))
            translated.append({"type": "tap_xy", "x": x_norm, "y": y_norm})
            translated.append({"type": "tap_xy", "x": x_norm, "y": y_norm})

        elif a_type == "type":
            translated.append({"type": "type", "text": action.get("text", "")})

        elif a_type == "scroll":
            x_norm, y_norm = _norm(action.get("x", display_width // 2), action.get("y", display_height // 2))
            scroll_x = action.get("scroll_x", 0)
            scroll_y = action.get("scroll_y", 0)
            # CUA scroll_y follows Playwright mouse.wheel() convention:
            # scroll_y > 0 = scroll DOWN the page (see content below).
            # On iOS, a swipe UP gesture scrolls the page down, so we invert.
            if abs(scroll_y) >= abs(scroll_x):
                direction = "up" if scroll_y > 0 else "down"
                distance_px = abs(scroll_y)
            else:
                direction = "left" if scroll_x > 0 else "right"
                distance_px = abs(scroll_x)
            swipe_action: Dict[str, Any] = {"type": "swipe", "direction": direction, "x": x_norm, "y": y_norm}
            if distance_px:
                # Pass pixel distance so appium_agent can use it instead of a fixed 30%.
                dim = display_height if direction in ("up", "down") else display_width
                swipe_action["distance_fraction"] = min(distance_px / dim, 0.9) if dim else 0.3
            translated.append(swipe_action)

        elif a_type == "keypress":
            keys = action.get("keys", [])
            keys_lower = [k.lower() for k in keys]
            # Strip modifier keys (not actionable on iOS) to find the base key
            _modifiers = {"cmd", "ctrl", "shift", "alt", "meta", "super",
                          "command", "control", "option"}
            base_keys = [k for k in keys_lower if k not in _modifiers]
            if "enter" in keys_lower or "return" in keys_lower:
                translated.append({"type": "type", "text": "\n"})
            elif "backspace" in keys_lower or "delete" in keys_lower:
                translated.append({"type": "type", "text": "\b"})
            elif "tab" in keys_lower:
                translated.append({"type": "type", "text": "\t"})
            elif "space" in keys_lower:
                translated.append({"type": "type", "text": " "})
            elif "home" in keys_lower or "escape" in keys_lower or "esc" in keys_lower:
                translated.append({"type": "home"})
            elif any(m in keys_lower for m in _modifiers) and base_keys == ["h"]:
                # CMD+H / META+SHIFT+H = Home button
                translated.append({"type": "home"})
            elif "app_switch" in keys_lower:
                # App switcher: double-tap home or swipe up and hold
                translated.append({"type": "home"})
            elif "back" in keys_lower:
                # Back gesture: swipe right from left edge
                translated.append({"type": "swipe", "direction": "right", "x": 0, "y": 500})
            elif any(k in ("arrowup", "arrowdown", "arrowleft", "arrowright",
                           "up", "down", "left", "right") for k in base_keys):
                # Arrow keys: map to small swipes in the corresponding direction
                for k in base_keys:
                    arrow_map = {"arrowup": "up", "arrowdown": "down",
                                 "arrowleft": "left", "arrowright": "right",
                                 "up": "up", "down": "down",
                                 "left": "left", "right": "right"}
                    if k in arrow_map:
                        translated.append({"type": "swipe", "direction": arrow_map[k],
                                           "x": 500, "y": 500, "distance_fraction": 0.1})
            else:
                # Single character keys (skip multi-char modifier names)
                for k in keys:
                    if len(k) == 1:
                        translated.append({"type": "type", "text": k})

        elif a_type == "drag":
            # SDK returns {path: [{x, y}, ...]} with at least 2 waypoints.
            path = action.get("path")
            if not path or len(path) < 2:
                sys.stderr.write(f"[CUA] drag with insufficient path points; skipping.\n")
                continue
            sx, sy = path[0].get("x", 0), path[0].get("y", 0)
            ex, ey = path[-1].get("x", 0), path[-1].get("y", 0)
            sx_norm, sy_norm = _norm(sx, sy)
            dx = ex - sx
            dy = ey - sy
            drag_keys = action.get("keys", [])
            # Long-press: start == end or keys contain LONG_PRESS
            if (abs(dx) < 3 and abs(dy) < 3) or "LONG_PRESS" in drag_keys:
                translated.append({"type": "hover", "x": sx_norm, "y": sy_norm, "duration": 1.0})
            else:
                if abs(dy) >= abs(dx):
                    direction = "up" if dy < 0 else "down"
                else:
                    direction = "left" if dx < 0 else "right"
                swipe_action: Dict[str, Any] = {"type": "swipe", "direction": direction, "x": sx_norm, "y": sy_norm}
                distance_px = ((dx)**2 + (dy)**2)**0.5
                dim = display_height if direction in ("up", "down") else display_width
                if dim:
                    swipe_action["distance_fraction"] = min(distance_px / dim, 0.9)
                translated.append(swipe_action)

        elif a_type == "wait":
            # CUA's wait action has no duration field; use a sensible default.
            translated.append({"type": "wait", "duration": 2.0})

        elif a_type in ("screenshot", "move"):
            pass  # no-op on iOS

        else:
            sys.stderr.write(f"[CUA] Unknown action type: {a_type!r}; skipping.\n")

    return translated


def translate_gemini_cu_actions(
    function_call: Dict[str, Any],
) -> List[Dict[str, Any]]:
    """Translate a single Gemini CU function_call to our 0-1000 normalised action space.

    Gemini Computer Use returns actions as ``functionCall`` objects with
    ``name`` (str) and ``args`` (dict).  Coordinates are already in a
    normalised 0-999 grid (1000x1000), which maps directly to our 0-1000
    space with negligible error.
    """
    translated: List[Dict[str, Any]] = []
    name = function_call.get("name", "").lower()
    args = function_call.get("args", {})

    if name == "click_at":
        x = int(args.get("x", 0))
        y = int(args.get("y", 0))
        translated.append({"type": "tap_xy", "x": x, "y": y})

    elif name == "type_text_at":
        x = int(args.get("x", 0))
        y = int(args.get("y", 0))
        text = args.get("text", "")
        # Tap to focus first, then type.
        translated.append({"type": "tap_xy", "x": x, "y": y})
        if text:
            if args.get("clear_before_typing"):
                # Triple-tap to select all text, then the new text replaces it.
                translated.append({"type": "tap_xy", "x": x, "y": y})
                translated.append({"type": "tap_xy", "x": x, "y": y})
            translated.append({"type": "type", "text": text})
        if args.get("press_enter"):
            translated.append({"type": "type", "text": "\n"})

    elif name == "hover_at":
        # Excluded by default (_GEMINI_CU_EXCLUDED_FUNCTIONS) but keep
        # a fallback in case the user overrides exclusions via env var.
        x = int(args.get("x", 0))
        y = int(args.get("y", 0))
        translated.append({"type": "tap_xy", "x": x, "y": y})

    elif name == "scroll_document":
        direction = args.get("direction", "down")
        # Gemini scroll direction is the CONTENT direction:
        # "scroll down" = see content below = swipe UP on iOS.
        _scroll_to_swipe = {"down": "up", "up": "down",
                            "left": "right", "right": "left"}
        swipe_dir = _scroll_to_swipe.get(direction.lower(), "up")
        swipe_action: Dict[str, Any] = {"type": "swipe", "direction": swipe_dir, "x": 500, "y": 500}
        magnitude = args.get("magnitude")
        if magnitude is not None:
            swipe_action["distance_fraction"] = min(int(magnitude) / 1000.0, 0.9)
        translated.append(swipe_action)

    elif name == "scroll_at":
        x = int(args.get("x", 500))
        y = int(args.get("y", 500))
        direction = args.get("direction", "down")
        _scroll_to_swipe = {"down": "up", "up": "down",
                            "left": "right", "right": "left"}
        swipe_dir = _scroll_to_swipe.get(direction.lower(), "up")
        swipe_action: Dict[str, Any] = {"type": "swipe", "direction": swipe_dir, "x": x, "y": y}
        # Gemini magnitude: 0-999 on a 1000x1000 grid (default 800).
        magnitude = args.get("magnitude")
        if magnitude is not None:
            swipe_action["distance_fraction"] = min(int(magnitude) / 1000.0, 0.9)
        translated.append(swipe_action)

    elif name == "key_combination":
        keys = args.get("keys", "")
        keys_lower = keys.lower()
        # Split on + for combos like "control+a"
        parts = [p.strip() for p in keys_lower.split("+")]
        _gem_modifiers = {"ctrl", "control", "cmd", "command", "shift", "alt",
                          "meta", "super", "option"}
        base_parts = [p for p in parts if p not in _gem_modifiers]
        has_modifier = len(base_parts) < len(parts)
        if "enter" in keys_lower or "return" in keys_lower:
            translated.append({"type": "type", "text": "\n"})
        elif "backspace" in keys_lower or "delete" in keys_lower:
            translated.append({"type": "type", "text": "\b"})
        elif "tab" in keys_lower:
            translated.append({"type": "type", "text": "\t"})
        elif "space" in keys_lower:
            translated.append({"type": "type", "text": " "})
        elif "home" in keys_lower or "escape" in keys_lower:
            translated.append({"type": "home"})
        elif has_modifier and base_parts == ["h"]:
            translated.append({"type": "home"})
        elif has_modifier:
            # Modifier combos (ctrl+a, cmd+c, etc.) — not actionable on iOS, skip silently
            pass
        else:
            for ch in keys:
                if len(ch) == 1 and ch.isprintable():
                    translated.append({"type": "type", "text": ch})

    elif name == "drag_and_drop":
        sx = int(args.get("x", 0))
        sy = int(args.get("y", 0))
        ex = int(args.get("destination_x", 0))
        ey = int(args.get("destination_y", 0))
        dx = ex - sx
        dy = ey - sy
        if abs(dy) >= abs(dx):
            direction = "up" if dy < 0 else "down"
            distance_fraction = min(abs(dy) / 1000.0, 0.9)
        else:
            direction = "left" if dx < 0 else "right"
            distance_fraction = min(abs(dx) / 1000.0, 0.9)
        translated.append({"type": "swipe", "direction": direction, "x": sx, "y": sy,
                            "distance_fraction": distance_fraction})

    elif name == "navigate":
        url = args.get("url", "")
        if url:
            translated.append({"type": "open_url", "url": url})

    elif name == "open_web_browser":
        # Excluded by default but keep fallback.
        translated.append({"type": "launch_app", "bundle_id": "com.apple.mobilesafari"})

    elif name == "go_back":
        # Swipe from left edge to go back on iOS.
        translated.append({"type": "swipe", "direction": "right", "x": 20, "y": 500})

    elif name == "go_forward":
        # Excluded by default (no iOS equivalent) but keep fallback.
        translated.append({"type": "swipe", "direction": "left", "x": 980, "y": 500})

    elif name == "wait_5_seconds":
        translated.append({"type": "wait", "duration": 5.0})

    elif name == "search":
        # Open Spotlight search on iOS: swipe down from middle of home screen.
        translated.append({"type": "swipe", "direction": "down", "x": 500, "y": 400})

    # -- Custom iOS functions (user-defined via _GEMINI_CU_CUSTOM_FUNCTIONS) --

    elif name == "open_app":
        bundle_id = args.get("bundle_id", "")
        if bundle_id:
            translated.append({"type": "launch_app", "bundle_id": bundle_id})

    elif name == "long_press_at":
        x = int(args.get("x", 0))
        y = int(args.get("y", 0))
        duration = float(args.get("duration", 1.5))
        translated.append({"type": "hover", "x": x, "y": y, "duration": duration})

    elif name == "go_home":
        translated.append({"type": "home"})

    # -- Info-gathering actions (no-op) --

    elif name in ("get_latest_observation", "get_user_and_device_info", "screenshot"):
        # Model-specific info-gathering actions — no-op on iOS.
        # The agent loop already sends a fresh screenshot on every turn.
        pass

    else:
        sys.stderr.write(f"[Gemini CU] Unknown action: {name!r}; skipping.\n")

    return translated


def get_image_size(image_path: str) -> Optional[tuple[int, int]]:
    if not image_path:
        return None
    try:
        with Image.open(image_path) as im:
            return im.width, im.height
    except Exception:
        return None


def normalize_provider(provider: str) -> str:
    p = (provider or "").strip().lower()
    aliases = {
        "openai": "openai",
        "oai": "openai",
        "anthropic": "anthropic",
        "claude": "anthropic",
        "gemini": "gemini",
        "google": "gemini",
        "vllm": "vllm",
        "qwen": "vllm",
    }
    return aliases.get(p, p or "openai")


def model_supports_image(provider: str, model: str) -> bool:
    """Best-effort heuristic for whether we can attach an image."""
    if not model:
        return False
    m = model.lower()
    provider = normalize_provider(provider)
    if provider == "openai":
        return any(
            key in m
            for key in [
                "gpt-4o",
                "gpt-4.1",
                "gpt-5",
                "o3",
                "o1",
            ]
        )
    if provider == "gemini":
        return "gemini" in m
    if provider == "anthropic":
        # Claude models generally support image inputs via the Messages API.
        # Match broadly so names like "claude-opus-4-5-..." still get images.
        return "claude" in m
    if provider == "vllm":
        # vLLM serves any OpenAI-compatible model. Vision support is decided
        # by the model itself; match the Qwen-VL keyword set plus the Qwen3.5
        # A-series MoE which ships multimodal by default.
        if "qwen3.5" in m:
            return True
        return any(
            key in m
            for key in [
                "vision",
                "qwen3-vl",
                "qwen2.5-vl",
                "qwen2-vl",
                "qwen-vl",
                "-vl",
                "vl-",
                "llava",
                "internvl",
                "pixtral",
            ]
        )
    return False


_DEFAULT_MODELS: Dict[str, str] = {
    "openai": "gpt-5.4",
    "gemini": "gemini-3-flash-preview",
    "anthropic": "claude-sonnet-4-6",
    "vllm": "Qwen/Qwen3.5-35B-A3B",
}


def strip_code_fences(text: str) -> str:
    t = (text or "").strip()
    if not t.startswith("```"):
        return t
    # Remove first/last fence lines.
    lines = t.splitlines()
    if lines and lines[0].startswith("```"):
        lines = lines[1:]
    if lines and lines[-1].startswith("```"):
        lines = lines[:-1]
    if lines and lines[0].strip().lower() in {"json", "javascript"}:
        lines = lines[1:]
    return "\n".join(lines).strip()


def extract_json(text: str) -> Any:
    cleaned = strip_code_fences(text)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        # Try parsing just the first JSON object (handles duplicate/trailing JSON).
        start = cleaned.find("{")
        if start != -1:
            try:
                decoder = json.JSONDecoder()
                obj, _ = decoder.raw_decode(cleaned, start)
                return obj
            except json.JSONDecodeError:
                pass
        # Last resort: first { to last }.
        end = cleaned.rfind("}")
        if start != -1 and end != -1 and end > start:
            snippet = cleaned[start : end + 1]
            return json.loads(snippet)
        raise


def _sanitize_payload_for_log(obj: Any, *, _depth: int = 0) -> Any:
    """Deep-copy a payload dict, replacing base64 image data with placeholders."""
    if _depth > 20:
        return "<max depth>"
    if isinstance(obj, dict):
        out: Dict[str, Any] = {}
        for k, v in obj.items():
            if k in ("data", "image_url") and isinstance(v, str) and len(v) > 200:
                out[k] = f"<{len(v)} chars base64>"
            elif k == "screenshot" and isinstance(v, str) and len(v) > 200:
                out[k] = f"<{len(v)} chars base64>"
            else:
                out[k] = _sanitize_payload_for_log(v, _depth=_depth + 1)
        return out
    if isinstance(obj, (list, tuple)):
        return [_sanitize_payload_for_log(item, _depth=_depth + 1) for item in obj]
    return obj


def http_post_json(url: str, headers: Dict[str, str], payload: Dict[str, Any], *, timeout_s: int = 90) -> Dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    for k, v in headers.items():
        if v is not None:
            req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=timeout_s) as resp:
            body = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        # Let retryable codes bubble up as HTTPError so retry_with_backoff can catch them.
        if exc.code in _RETRYABLE_HTTP_CODES:
            raise
        err_body = exc.read().decode("utf-8", errors="replace") if hasattr(exc, "read") else ""
        if exc.code == 400:
            raise HTTPPayloadError(f"HTTP {exc.code} calling {url}\n{err_body}", status_code=400) from exc
        raise SystemExit(f"HTTP {exc.code} calling {url}\n{err_body}") from exc
    except urllib.error.URLError as exc:
        raise
    try:
        return json.loads(body)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Non-JSON response from {url}: {exc}\nRaw: {body[:2000]}") from exc


def openai_api_key() -> Optional[str]:
    return os.getenv("LLM_API_KEY") or os.getenv("OPENAI_API_KEY")


def gemini_api_key() -> Optional[str]:
    return os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY") or os.getenv("LLM_API_KEY")


def anthropic_api_key() -> Optional[str]:
    return os.getenv("ANTHROPIC_API_KEY") or os.getenv("LLM_API_KEY")


def vllm_api_key() -> str:
    """vLLM auth token. Defaults to the vLLM convention of "EMPTY" for
    unauthenticated local servers; production deployments override via env."""
    return os.getenv("VLLM_API_KEY") or os.getenv("LLM_API_KEY") or "EMPTY"


def vllm_base_url() -> str:
    """OpenAI-compatible base URL for the vLLM server (e.g. forwarded port).
    Defaults to ``http://localhost:8000/v1``; trailing slash stripped.
    """
    raw = os.getenv("VLLM_BASE_URL") or "http://localhost:8000/v1"
    return raw.rstrip("/")


def _llm_temperature() -> float:
    """Return configured LLM temperature (default 0 for reproducibility)."""
    raw = os.getenv("LLM_TEMPERATURE")
    if raw is not None:
        try:
            return float(raw)
        except ValueError:
            pass
    return 0.0


def _llm_seed() -> Optional[int]:
    """Return configured LLM seed for reproducibility (default 42)."""
    raw = os.getenv("LLM_SEED")
    if raw is not None:
        try:
            return int(raw)
        except ValueError:
            return None
    return 42


def _strip_thinking_blocks(text: Any) -> Any:
    """Remove <think>...</think> blocks from a string.

    Per the Qwen3.5 model card, multi-turn conversations should not
    include thinking content in historical assistant messages — only
    the final answer. Qwen emits ``<think>...</think>\\n\\n<answer>``;
    this regex is anchored to that exact spec but tolerates whitespace.
    No-op for non-string content.
    """
    if not isinstance(text, str) or "<think>" not in text:
        return text
    import re as _re
    return _re.sub(r"<think>.*?</think>\s*", "", text, flags=_re.DOTALL).lstrip()


def _strip_thinking_from_history(messages: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Strip <think>...</think> from historical assistant messages.

    Mutates in spirit but returns a fresh list. The current/final assistant
    turn (the last one) keeps its thinking block intact since it's not
    yet "history". Only assistant messages with thinking content are
    rewritten; user/tool/system messages pass through unchanged.

    Reference: Qwen3.5-35B-A3B model card §"Multi-Turn Conversation".
    """
    out: List[Dict[str, Any]] = []
    last_asst_idx = None
    for i, m in enumerate(messages):
        if m.get("role") == "assistant":
            last_asst_idx = i
    for i, m in enumerate(messages):
        if m.get("role") != "assistant" or i == last_asst_idx:
            out.append(m); continue
        content = m.get("content")
        if isinstance(content, str):
            stripped = _strip_thinking_blocks(content)
            if stripped != content:
                m = {**m, "content": stripped}
        elif isinstance(content, list):
            new_blocks = []
            for b in content:
                if isinstance(b, dict) and b.get("type") == "text":
                    t = _strip_thinking_blocks(b.get("text", ""))
                    if t != b.get("text"):
                        b = {**b, "text": t}
                new_blocks.append(b)
            if new_blocks != content:
                m = {**m, "content": new_blocks}
        out.append(m)
    return out


def _trim_old_screenshots_raw(messages: List[Dict[str, Any]], keep_recent: Optional[int] = None) -> List[Dict[str, Any]]:
    """Strip base64 image data from older turns in raw API message format.

    Works with Anthropic (``content`` list with ``image`` / ``tool_result`` blocks)
    and Gemini (``parts`` list with ``inline_data`` blocks).

    When *keep_recent* is ``None`` (default), all images are preserved.
    When set to an integer, keeps images in the first user message and the
    last *keep_recent* user messages.
    """
    if keep_recent is None:
        return messages
    user_indices = [i for i, m in enumerate(messages) if m.get("role") == "user"]
    if len(user_indices) <= keep_recent + 1:
        return messages

    keep_set = {user_indices[0]} | set(user_indices[-keep_recent:])
    result: List[Dict[str, Any]] = []

    for i, msg in enumerate(messages):
        if i in keep_set or msg.get("role") != "user":
            result.append(msg)
            continue
        # Anthropic / OpenAI: content list with image / image_url / tool_result blocks
        content = msg.get("content")
        if isinstance(content, list):
            new_content = []
            for block in content:
                if not isinstance(block, dict):
                    new_content.append(block)
                elif block.get("type") == "image":
                    # Anthropic image block — replace with text placeholder.
                    new_content.append({"type": "text", "text": "[screenshot omitted]"})
                elif block.get("type") == "image_url":
                    # OpenAI / vLLM image_url block — replace with text placeholder.
                    new_content.append({"type": "text", "text": "[screenshot omitted]"})
                elif block.get("type") == "tool_result":
                    # Strip images from Anthropic tool_result content.
                    inner = block.get("content", [])
                    if isinstance(inner, list) and any(
                        isinstance(b, dict) and b.get("type") == "image" for b in inner
                    ):
                        new_inner = [b for b in inner if not (isinstance(b, dict) and b.get("type") == "image")]
                        if not new_inner:
                            new_inner = [{"type": "text", "text": "[screenshot omitted]"}]
                        block = {**block, "content": new_inner}
                    new_content.append(block)
                else:
                    new_content.append(block)
            result.append({**msg, "content": new_content})
            continue
        # Gemini: parts list with inline_data and functionResponse blocks
        parts = msg.get("parts")
        if isinstance(parts, list):
            new_parts = []
            for part in parts:
                if isinstance(part, dict) and "inline_data" in part:
                    new_parts.append({"text": "[screenshot omitted]"})
                elif isinstance(part, dict) and "functionResponse" in part:
                    # Slim down old functionResponse parts — keep the
                    # structure (name + minimal response) so multi-turn
                    # conversation remains valid, but drop the verbose
                    # output text and url fields that bloat the payload.
                    fr = part["functionResponse"]
                    new_parts.append({"functionResponse": {
                        "name": fr.get("name", "unknown"),
                        "response": {"output": "executed"},
                    }})
                else:
                    new_parts.append(part)
            result.append({**msg, "parts": new_parts})
            continue
        result.append(msg)

    return result


_ACCESSIBILITY_TREE_MARKER = "UI Accessibility Tree"


def _strip_accessibility_tree_text(text: str) -> Optional[str]:
    """Remove an XML/accessibility tree payload while preserving other text."""
    marker_idx = text.find(_ACCESSIBILITY_TREE_MARKER)
    if marker_idx < 0:
        return text
    kept = text[:marker_idx].rstrip()
    if not kept:
        return None
    return kept


def _trim_old_qwen_observations_raw(messages: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Keep Qwen action history, but include accessibility XML only on the latest turn.

    The Qwen mobile-agent cookbook carries concise task progress/action history
    plus the current screenshot. Our runner preserves the tool/assistant history
    for continuity, but strips older XML tree payloads because they are large
    per-observation state snapshots rather than action history.
    """
    user_indices = [i for i, msg in enumerate(messages) if msg.get("role") == "user"]
    if len(user_indices) <= 1:
        return messages
    keep_xml_idx = user_indices[-1]
    result: List[Dict[str, Any]] = []

    for idx, msg in enumerate(messages):
        if msg.get("role") != "user" or idx == keep_xml_idx:
            result.append(msg)
            continue

        content = msg.get("content")
        if not isinstance(content, list):
            result.append(msg)
            continue

        new_content = []
        for block in content:
            if not isinstance(block, dict) or block.get("type") != "text":
                new_content.append(block)
                continue
            stripped = _strip_accessibility_tree_text(str(block.get("text", "")))
            if stripped:
                new_content.append({**block, "text": stripped})
        result.append({**msg, "content": new_content})

    return result


def _summarize_qwen_action_for_progress(action: Dict[str, Any]) -> str:
    """Return a concise cookbook-style description of one executed action."""
    action_type = str(action.get("type") or action.get("action") or "").strip()
    status = str(action.get("status") or "").strip()
    if status == "recoverable_error":
        error = str(action.get("error") or "action failed").replace("\n", " ")
        base = str(action.get("action") or action_type or "action")
        return f"{base} failed: {error}"
    if action_type in {"tap_xy", "click"}:
        x = action.get("x")
        y = action.get("y")
        return f"clicked at ({int(round(float(x)))}, {int(round(float(y)))})" if x is not None and y is not None else "clicked"
    if action_type in {"swipe", "scroll"}:
        direction = action.get("direction")
        if direction:
            return f"swiped {direction}"
        x = action.get("x")
        y = action.get("y")
        coordinate2 = action.get("coordinate2")
        x2 = action.get("x2")
        y2 = action.get("y2")
        if isinstance(coordinate2, list) and len(coordinate2) >= 2:
            x2 = x2 if x2 is not None else coordinate2[0]
            y2 = y2 if y2 is not None else coordinate2[1]
        if None not in (x, y, x2, y2):
            return f"swiped from ({int(round(float(x)))}, {int(round(float(y)))}) to ({int(round(float(x2)))}, {int(round(float(y2)))})"
        return "swiped"
    if action_type in {"type", "type_text"}:
        text = str(action.get("text") or "")
        return f"typed {json.dumps(text)}"
    if action_type in {"hover", "long_press"}:
        x = action.get("x")
        y = action.get("y")
        return f"long-pressed at ({int(round(float(x)))}, {int(round(float(y)))})" if x is not None and y is not None else "long-pressed"
    if action_type in {"stop", "done"}:
        answer = str(action.get("answer") or "")
        return f"finished with answer {json.dumps(answer)}" if answer else "finished"
    if action_type:
        return action_type.replace("_", " ")
    return "performed an action"


def _build_qwen_task_progress(history: Optional[List[Dict[str, Any]]], max_items: int = 100) -> str:
    """Build the mobile_agent.ipynb style `Step x: ...;` progress string."""
    if not history:
        return ""
    entries: List[str] = []
    for action in history[-max_items:]:
        if not isinstance(action, dict):
            continue
        entries.append(_summarize_qwen_action_for_progress(action).replace("\n", " ").replace('"', "'"))
    return " ".join(f"Step {idx + 1}: {entry};" for idx, entry in enumerate(entries))


def _build_qwen_user_query(
    task_description: str,
    *,
    task_progress: str = "",
    xml_tree: Optional[str] = None,
    xml_agent: bool = False,
    last_action_error: Optional[str] = None,
) -> str:
    """Build the user turn in the Qwen mobile_agent.ipynb style."""
    parts = [
        f"The user query: {task_description}.",
        "Task progress (You have done the following operation on the current device): "
        f"{task_progress or 'None yet.'}.",
    ]
    if last_action_error:
        parts.append(
            "Previous action error: "
            f"{last_action_error.replace(chr(10), ' ')} "
            "Re-plan from the current screen state. Do not repeat the same failed action."
        )
    if xml_tree:
        parts.append(xml_tree)
    elif xml_agent:
        parts.append(
            "Accessibility tree unavailable this step (timed out). "
            "Use the screenshot to decide your next action."
        )
    return "\n".join(parts)


def _trim_old_screenshots(conversation: List[Dict[str, Any]], keep_recent: Optional[int] = None) -> List[Dict[str, Any]]:
    """Return a shallow copy of *conversation* with images stripped from older turns.

    When *keep_recent* is ``None`` (default), all images are preserved.
    When set to an integer, keeps screenshots only on the first user turn
    (task context) and the most recent *keep_recent* user turns.  Older user
    turns have their ``images`` replaced with an empty list.
    """
    if keep_recent is None:
        return conversation
    # Identify user-turn indices.
    user_indices = [i for i, m in enumerate(conversation) if m.get("role") == "user"]
    if len(user_indices) <= keep_recent + 1:
        return conversation  # nothing to trim

    # Always keep: first user turn (index 0 in user_indices) + last N.
    keep_set = {user_indices[0]} | set(user_indices[-keep_recent:])

    trimmed: List[Dict[str, Any]] = []
    for i, msg in enumerate(conversation):
        if i in keep_set or msg.get("role") != "user" or not msg.get("images"):
            trimmed.append(msg)
        else:
            trimmed.append({**msg, "images": []})
    return trimmed


def _to_openai_messages(conversation: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Convert internal conversation format to OpenAI messages format."""
    msgs = []
    for msg in _trim_old_screenshots(conversation, keep_recent=_SCREENSHOT_KEEP_RECENT):
        role = msg["role"]
        if role == "system":
            msgs.append({"role": "system", "content": msg["text"]})
        elif role == "user":
            content: Any = [{"type": "text", "text": msg["text"]}]
            for img in msg.get("images") or []:
                content.append({"type": "image_url", "image_url": {"url": f"data:{_IMAGE_MIME};base64,{img}", "detail": "high"}})
            msgs.append({"role": "user", "content": content})
        elif role == "assistant":
            msgs.append({"role": "assistant", "content": msg["text"]})
    return msgs


def _to_gemini_contents(conversation: List[Dict[str, Any]]) -> Tuple[str, List[Dict[str, Any]]]:
    """Convert internal conversation format to Gemini contents format.

    Returns ``(system_text, contents_list)``.
    """
    system_text = ""
    contents: List[Dict[str, Any]] = []
    for msg in _trim_old_screenshots(conversation, keep_recent=_SCREENSHOT_KEEP_RECENT):
        role = msg["role"]
        if role == "system":
            system_text = msg["text"]
        elif role == "user":
            parts: List[Dict[str, Any]] = [{"text": msg["text"]}]
            for img in msg.get("images") or []:
                parts.append({"inline_data": {"mime_type": _IMAGE_MIME, "data": img}})
            contents.append({"role": "user", "parts": parts})
        elif role == "assistant":
            contents.append({"role": "model", "parts": [{"text": msg["text"]}]})
    return system_text, contents


def _to_anthropic_messages(conversation: List[Dict[str, Any]]) -> Tuple[str, List[Dict[str, Any]]]:
    """Convert internal conversation format to Anthropic messages format.

    Returns ``(system_text, messages_list)``.
    """
    system_text = ""
    messages: List[Dict[str, Any]] = []
    for msg in _trim_old_screenshots(conversation, keep_recent=_SCREENSHOT_KEEP_RECENT):
        role = msg["role"]
        if role == "system":
            system_text = msg["text"]
        elif role == "user":
            content: List[Dict[str, Any]] = [{"type": "text", "text": msg["text"]}]
            for img in msg.get("images") or []:
                content.append({
                    "type": "image",
                    "source": {"type": "base64", "media_type": _IMAGE_MIME, "data": img},
                })
            messages.append({"role": "user", "content": content})
        elif role == "assistant":
            messages.append({"role": "assistant", "content": msg["text"]})
    return system_text, messages


def _add_anthropic_cache_breakpoints(
    system: Any,
    messages: List[Dict[str, Any]],
) -> Tuple[Any, List[Dict[str, Any]]]:
    """Add ``cache_control`` markers for Anthropic prompt caching.

    Strategy:
    - Mark the system prompt with ``cache_control`` so it is cached across all turns.
    - Mark the last content block of the second-to-last *user* message so all
      prior conversation history is cached (only the newest user turn is uncached).

    Anthropic allows a maximum of 4 ``cache_control`` blocks per request.
    We first strip all existing markers (from prior turns) then add up to 4:
    system prompt, first user message (static task instruction + screenshot),
    second-to-last user message (history boundary), and last user message
    (most recent turn, useful for retries and tool-use continuations).
    """
    # --- Step 1: Strip all existing cache_control markers from messages ---
    for msg in messages:
        content = msg.get("content")
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict):
                    block.pop("cache_control", None)

    # --- Step 2: Mark system prompt (1 marker) ---
    if isinstance(system, str) and system:
        system = [{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}]
    elif isinstance(system, list) and system:
        # Strip any prior marker on system blocks too.
        for block in system:
            if isinstance(block, dict):
                block.pop("cache_control", None)
        system[-1] = {**system[-1], "cache_control": {"type": "ephemeral"}}

    # --- Step 3: Mark up to 3 user messages (using remaining 3 of 4 breakpoints) ---
    # 1. First user message  — static task instruction + screenshot (always cached)
    # 2. Second-to-last user — conversation history boundary
    # 3. Last user message   — most recent turn (cached for retries / tool-use loops)
    user_indices = [i for i, m in enumerate(messages) if m.get("role") == "user"]

    def _mark_message(idx: int) -> None:
        msg = messages[idx]
        content = msg.get("content")
        if isinstance(content, list) and content:
            content[-1] = {**content[-1], "cache_control": {"type": "ephemeral"}}
        elif isinstance(content, str):
            messages[idx] = {
                "role": "user",
                "content": [{"type": "text", "text": content, "cache_control": {"type": "ephemeral"}}],
            }

    # Build set of unique indices to mark — avoid double-marking when
    # first/second-to-last/last point to the same message.
    mark_set: set = set()
    if user_indices:
        mark_set.add(user_indices[0])               # first (task instruction)
    if len(user_indices) >= 2:
        mark_set.add(user_indices[-2])              # second-to-last (history boundary)
        mark_set.add(user_indices[-1])              # last (most recent turn)

    for idx in sorted(mark_set):
        _mark_message(idx)

    return system, messages


# ---------------------------------------------------------------------------
# OpenAI pricing (USD per token) – verified 2026-04-18 against
# developers.openai.com/api/docs/pricing.  Cached-input rate reflects the
# current 90%-off cache-hit discount on the 5.4 family (not the legacy 50%).
# ---------------------------------------------------------------------------
_OPENAI_PRICING: Dict[str, Dict[str, float]] = {
    "gpt-5.4":      {"input": 2.50 / 1_000_000, "cached_input": 0.25  / 1_000_000, "output": 15.00 / 1_000_000},
    "gpt-5.4-mini": {"input": 0.75 / 1_000_000, "cached_input": 0.075 / 1_000_000, "output":  4.50 / 1_000_000},
}


def _log_openai_usage(usage: Any, model: str, label: str = "OpenAI") -> None:
    """Log OpenAI token usage (including cache hits) and estimated cost to stderr."""
    if not usage:
        return
    # Chat Completions uses prompt_tokens/completion_tokens;
    # Responses API uses input_tokens/output_tokens.
    input_tokens = getattr(usage, "input_tokens", None) or getattr(usage, "prompt_tokens", 0)
    output_tokens = getattr(usage, "output_tokens", None) or getattr(usage, "completion_tokens", 0)
    total_tokens = getattr(usage, "total_tokens", None) or (input_tokens + output_tokens)

    # Extract cached token count from details sub-object.
    # Responses API: usage.input_tokens_details.cached_tokens
    # Chat Completions: usage.prompt_tokens_details.cached_tokens
    cached_tokens = 0
    for details_attr in ("input_tokens_details", "prompt_tokens_details"):
        details = getattr(usage, details_attr, None)
        if details:
            cached_tokens = getattr(details, "cached_tokens", 0) or 0
            break

    parts = [
        f"input={input_tokens}",
        f"output={output_tokens}",
        f"total={total_tokens}",
    ]
    if cached_tokens:
        uncached = input_tokens - cached_tokens
        parts.append(f"cached={cached_tokens}")
        parts.append(f"uncached={uncached}")

    # Estimate cost — cached input tokens are charged at 50% discount.
    pricing = _OPENAI_PRICING.get(model)
    if pricing:
        uncached_input = input_tokens - cached_tokens
        cost = (
            uncached_input * pricing["input"]
            + cached_tokens * pricing["cached_input"]
            + output_tokens * pricing["output"]
        )
        parts.append(f"cost=${cost:.4f}")
    sys.stderr.write(f"[{label}] tokens: {', '.join(parts)}\n")


# ---------------------------------------------------------------------------
# Anthropic pricing (USD per token) – verified 2026-04-18 against
# platform.claude.com/docs/en/about-claude/pricing.
# Cache write (5-min TTL) costs 1.25x base input; cache read costs 0.1x.
# (1-hour TTL writes are billed at 2x — not used by this agent.)
# ---------------------------------------------------------------------------
_ANTHROPIC_PRICING: Dict[str, Dict[str, float]] = {
    "claude-opus-4-6":   {"input": 5.00 / 1_000_000, "output": 25.00 / 1_000_000},
    "claude-sonnet-4-6": {"input": 3.00 / 1_000_000, "output": 15.00 / 1_000_000},
}
_ANTHROPIC_CACHE_WRITE_MULTIPLIER = 1.25
_ANTHROPIC_CACHE_READ_MULTIPLIER = 0.10


def _log_anthropic_usage(usage: Dict[str, Any], model: str = "", label: str = "Anthropic") -> None:
    """Log Anthropic token usage including cache metrics and cost to stderr.

    Anthropic's ``input_tokens`` field represents *only* the non-cached input
    tokens.  The total input is ``input_tokens + cache_creation + cache_read``.
    """
    if not usage:
        return
    input_tokens = usage.get("input_tokens", 0)
    output_tokens = usage.get("output_tokens", 0)
    cache_creation = usage.get("cache_creation_input_tokens", 0)
    cache_read = usage.get("cache_read_input_tokens", 0)
    total_input = input_tokens + cache_creation + cache_read
    parts = [
        f"input={total_input}",
        f"output={output_tokens}",
    ]
    if cache_creation or cache_read:
        parts.append(f"cache_creation={cache_creation}")
        parts.append(f"cache_read={cache_read}")
        parts.append(f"uncached={input_tokens}")

    # Estimate cost if we have pricing for this model.
    # input_tokens = uncached (full price), cache_creation = 1.25x, cache_read = 0.1x
    pricing = _ANTHROPIC_PRICING.get(model)
    if pricing:
        base_input = pricing["input"]
        cost = (
            input_tokens * base_input
            + cache_creation * base_input * _ANTHROPIC_CACHE_WRITE_MULTIPLIER
            + cache_read * base_input * _ANTHROPIC_CACHE_READ_MULTIPLIER
            + output_tokens * pricing["output"]
        )
        parts.append(f"cost=${cost:.4f}")

    sys.stderr.write(f"[{label}] tokens: {', '.join(parts)}\n")


# Gemini pricing (USD per token) – verified 2026-04-18 against
# ai.google.dev/gemini-api/docs/pricing.  Only the SKU we ship against
# (gemini-3.1-flash / *-lite-preview) is listed; the prefix match in
# _log_gemini_usage() covers the "-preview" / "-lite-preview" suffix variants.
# Gemini 3.1 Flash has no ≤/> prompt-length tier split.
_GEMINI_PRICING: Dict[str, Dict[str, float]] = {
    "gemini-3.1-flash": {"input": 0.25 / 1_000_000, "cached_input": 0.025 / 1_000_000, "output": 1.50 / 1_000_000},
    "gemini-3-flash": {"input": 0.15 / 1_000_000, "cached_input": 0.015 / 1_000_000, "output": 0.60 / 1_000_000},
}


def _log_gemini_usage(data: Dict[str, Any], model: str = "", label: str = "Gemini") -> None:
    """Log Gemini token usage including cache hits and estimated cost to stderr.

    Gemini returns ``usageMetadata`` in the response with fields like
    ``promptTokenCount``, ``candidatesTokenCount``, ``totalTokenCount``,
    and ``cachedContentTokenCount`` (when implicit caching kicks in).
    """
    usage = data.get("usageMetadata")
    if not usage:
        return
    input_tokens = usage.get("promptTokenCount", 0)
    output_tokens = usage.get("candidatesTokenCount", 0)
    total_tokens = usage.get("totalTokenCount", 0) or (input_tokens + output_tokens)
    cached_tokens = usage.get("cachedContentTokenCount", 0)

    parts = [
        f"input={input_tokens}",
        f"output={output_tokens}",
        f"total={total_tokens}",
    ]
    if cached_tokens:
        uncached = input_tokens - cached_tokens
        parts.append(f"cached={cached_tokens}")
        parts.append(f"uncached={uncached}")

    # Estimate cost — match model prefix to pricing table.
    pricing = None
    for key in _GEMINI_PRICING:
        if key in model:
            pricing = _GEMINI_PRICING[key]
            break
    if pricing:
        uncached_input = input_tokens - cached_tokens
        cost = (
            uncached_input * pricing["input"]
            + cached_tokens * pricing["cached_input"]
            + output_tokens * pricing["output"]
        )
        parts.append(f"cost=${cost:.4f}")

    sys.stderr.write(f"[{label}] tokens: {', '.join(parts)}\n")


# ---------------------------------------------------------------------------
# vLLM / Qwen pricing — self-hosted defaults to $0; users running on a paid
# cluster can amortize GPU cost via VLLM_INPUT_PRICE_PER_M / _OUTPUT_PRICE_PER_M.
# ---------------------------------------------------------------------------
def _vllm_pricing() -> Optional[Dict[str, float]]:
    in_per_m = os.getenv("VLLM_INPUT_PRICE_PER_M")
    out_per_m = os.getenv("VLLM_OUTPUT_PRICE_PER_M")
    if not in_per_m and not out_per_m:
        return None
    try:
        return {
            "input": float(in_per_m or 0) / 1_000_000,
            "output": float(out_per_m or 0) / 1_000_000,
        }
    except ValueError:
        return None


def _log_qwen_cu_usage(usage: Any, model: str = "", label: str = "Qwen CU") -> None:
    """Log Qwen CU token usage. vLLM returns OpenAI-shaped ``usage`` objects."""
    if not usage:
        return
    input_tokens = getattr(usage, "prompt_tokens", 0) or 0
    output_tokens = getattr(usage, "completion_tokens", 0) or 0
    total_tokens = getattr(usage, "total_tokens", 0) or (input_tokens + output_tokens)
    parts = [
        f"input={input_tokens}",
        f"output={output_tokens}",
        f"total={total_tokens}",
    ]
    pricing = _vllm_pricing()
    if pricing:
        cost = input_tokens * pricing["input"] + output_tokens * pricing["output"]
        parts.append(f"cost=${cost:.4f}")
    else:
        parts.append("cost=$0.0000")
    sys.stderr.write(f"[{label}] tokens: {', '.join(parts)}\n")


def _extract_chat_message_text(message: Any) -> str:
    """Extract plain text from an OpenAI-style chat completion message."""
    if isinstance(message, str):
        return message
    if isinstance(message, list):
        parts: List[str] = []
        for block in message:
            if isinstance(block, str):
                parts.append(block)
            elif isinstance(block, dict):
                if block.get("type") == "text" and isinstance(block.get("text"), str):
                    parts.append(block["text"])
                elif isinstance(block.get("content"), str):
                    parts.append(block["content"])
        return "".join(parts).strip()
    if isinstance(message, dict):
        if isinstance(message.get("content"), str):
            return message["content"]
        if isinstance(message.get("text"), str):
            return message["text"]
    return ""


def call_openai(prompt: str, model: str, images_b64: Optional[List[str]],
                *, conversation: Optional[List[Dict[str, Any]]] = None) -> Tuple[Any, str]:
    api_key = openai_api_key()
    if not api_key:
        raise SystemExit("Set OPENAI_API_KEY (or LLM_API_KEY) for OpenAI models.")
    base_url = os.getenv("LLM_BASE_URL") or os.getenv("OPENAI_BASE_URL")
    try:
        from openai import BadRequestError, OpenAI  # type: ignore
    except ImportError as exc:
        raise SystemExit("Missing openai client. Install with `pip install -r requirements.txt`.") from exc
    client = OpenAI(api_key=api_key, base_url=base_url) if base_url else OpenAI(api_key=api_key)

    if conversation:
        messages = _to_openai_messages(conversation)
    else:
        # Legacy single-shot fallback (used by evaluate_trajectory, subprocess mode, etc.)
        user_content: Any = [{"type": "text", "text": prompt}]
        if images_b64:
            for img in images_b64:
                user_content.append({"type": "image_url", "image_url": {"url": f"data:{_IMAGE_MIME};base64,{img}"}})
        messages = [
            {"role": "system", "content": build_system_prompt()},
            {"role": "user", "content": user_content},
        ]

    temp = _llm_temperature()
    seed = _llm_seed()
    extra_kwargs: Dict[str, Any] = {}
    if seed is not None:
        extra_kwargs["seed"] = seed

    def _call():
        nonlocal messages
        try:
            return client.chat.completions.create(model=model, messages=messages, temperature=temp, **extra_kwargs)
        except BadRequestError as exc:
            msg = str(exc).lower()
            if images_b64 and "image" in msg and ("not support" in msg or "unsupported" in msg):
                sys.stderr.write(
                    f"[llm_action_generator] Model '{model}' rejected image input; retrying without screenshot.\n"
                )
                # Strip images from the last user message.
                last_user = [m for m in messages if m["role"] == "user"][-1]
                last_user["content"] = [c for c in last_user["content"] if c.get("type") == "text"]
                return client.chat.completions.create(model=model, messages=messages, temperature=temp, **extra_kwargs)
            raise

    resp = retry_with_backoff(_call)
    _log_openai_usage(getattr(resp, "usage", None), model, label="OpenAI")
    content = (resp.choices[0].message.content or "").strip()
    try:
        return extract_json(content), content
    except Exception as exc:
        raise ValueError(f"OpenAI response is not valid JSON: {exc}\nRaw: {content}") from exc


# ---------------------------------------------------------------------------
# OpenAI CUA (Computer Use Agent) via the Responses API
# ---------------------------------------------------------------------------

def call_openai_cua(
    task_description: str,
    screenshot_b64: Optional[str],
    *,
    model: str = "gpt-5.4",
    previous_response_id: Optional[str] = None,
    last_call_id: Optional[str] = None,
    pending_safety_checks: Optional[list] = None,
    display_width: int = 393,
    display_height: int = 852,
    xml_tree: Optional[str] = None,
    xml_agent: bool = False,
    last_action_error: Optional[str] = None,
) -> Dict[str, Any]:
    """Call OpenAI CUA via the Responses API.

    Returns a dict with:
      response_id, actions (translated), cua_actions (raw), call_id,
      done (bool), text_output, pending_safety_checks.
    """
    api_key = openai_api_key()
    if not api_key:
        raise SystemExit("Set OPENAI_API_KEY (or LLM_API_KEY) for CUA models.")
    base_url = os.getenv("LLM_BASE_URL") or os.getenv("OPENAI_BASE_URL")
    try:
        from openai import OpenAI  # type: ignore
    except ImportError as exc:
        raise SystemExit("Missing openai client. Install with `pip install -r requirements.txt`.") from exc

    client = OpenAI(api_key=api_key, base_url=base_url) if base_url else OpenAI(api_key=api_key)

    # The computer tool type is "computer" (no display params needed;
    # the model infers dimensions from the screenshots it receives).
    tools: List[Dict[str, Any]] = [{"type": "computer"}]

    # Build input payload.
    if previous_response_id and last_call_id and screenshot_b64:
        # Subsequent turn: send screenshot as computer_call_output.
        input_content: Any = [{
            "type": "computer_call_output",
            "call_id": last_call_id,
            "output": {
                "type": "computer_screenshot",
                "image_url": f"data:{_IMAGE_MIME};base64,{screenshot_b64}",
                "detail": "original",
            },
        }]
        # Acknowledge any pending safety checks from the previous turn.
        if pending_safety_checks:
            input_content[0]["acknowledged_safety_checks"] = pending_safety_checks
        # Inject error feedback from the previous action batch.
        if last_action_error:
            input_content.append({
                "role": "user",
                "content": [{"type": "input_text", "text": (
                    f"⚠ ACTION ERROR:\n{last_action_error}\n"
                    "Re-plan from the current screen state. Do not repeat the same failed action. "
                    "If you need to type, first tap a text field to bring up the keyboard."
                )}],
            })
        # Inject XML accessibility tree alongside the screenshot.
        if xml_tree:
            input_content.append({
                "role": "user",
                "content": [{"type": "input_text", "text": xml_tree}],
            })
        elif xml_agent:
            input_content.append({
                "role": "user",
                "content": [{"type": "input_text", "text": "⚠ Accessibility tree unavailable this step (timed out). Use the screenshot to decide your next action."}],
            })
    else:
        # First turn: send task description (+ optional initial screenshot).
        first_turn_text = task_description
        if xml_tree:
            first_turn_text = f"{task_description}\n\n{xml_tree}"
        if screenshot_b64:
            input_content = [
                {
                    "role": "user",
                    "content": [
                        {"type": "input_text", "text": first_turn_text},
                        {
                            "type": "input_image",
                            "image_url": f"data:{_IMAGE_MIME};base64,{screenshot_b64}",
                            "detail": "original",
                        },
                    ],
                }
            ]
        else:
            input_content = first_turn_text

    kwargs: Dict[str, Any] = {
        "model": model,
        "tools": tools,
        "input": input_content,
        "truncation": "auto",
    }
    if previous_response_id:
        kwargs["previous_response_id"] = previous_response_id
    # Provide iOS context on the first turn.
    if not previous_response_id:
        kwargs["instructions"] = _build_cu_ios_instructions(
            tap_action="Use 'click' for all touch/tap interactions (there is no mouse cursor).",
            type_action="To type text, click a text field first, then type the text.",
            scroll_action=(
                "To scroll content, use the 'scroll' action (scroll_y positive = scroll content "
                "down, scroll_y negative = scroll content up)."
            ),
            home_action=(
                "To return to the home screen, use keypress with the 'Home' key, or "
                "swipe up from the very bottom of the screen (drag from the bottom edge upward)."
            ),
            back_action=(
                "To go back within an app, look for a back button (usually top-left) or swipe "
                "from the left edge of the screen to the right."
            ),
            app_switcher_action="To open the App Switcher, swipe up from the bottom and pause mid-screen.",
            stop_instruction=(
                "When the task is complete, stop calling the computer tool and respond with "
                "a text summary of what you accomplished."
            ),
        )
        if xml_tree:
            kwargs["instructions"] += _CU_ACCESSIBILITY_TREE_INSTRUCTIONS
    # Enable reasoning with summaries on every turn.
    # GPT-5.2+ defaults to effort="none", so we must set it explicitly.
    cua_effort = os.getenv("CUA_REASONING_EFFORT", "high")
    cua_summary = os.getenv("CUA_REASONING_SUMMARY", "auto")
    kwargs["reasoning"] = {"effort": cua_effort, "summary": cua_summary}

    def _call():
        return client.responses.create(**kwargs)

    response = retry_with_backoff(_call)
    _log_openai_usage(getattr(response, "usage", None), model, label="OpenAI CUA")

    # Parse response output items.
    text_parts: List[str] = []
    reasoning_parts: List[str] = []
    call_id: Optional[str] = None
    cua_actions: List[Dict[str, Any]] = []
    done = True
    new_safety_checks: Optional[list] = None

    for item in response.output:
        if getattr(item, "type", None) == "message":
            for block in getattr(item, "content", []) or []:
                txt = getattr(block, "text", None)
                if txt:
                    text_parts.append(txt)
        elif getattr(item, "type", None) == "reasoning":
            for summary_item in getattr(item, "summary", []) or []:
                txt = getattr(summary_item, "text", None)
                if txt and txt.strip():
                    reasoning_parts.append(txt)
        elif getattr(item, "type", None) == "computer_call":
            done = False
            call_id = getattr(item, "call_id", None)
            # The SDK exposes .actions as a batched array of action dicts.
            raw_actions = getattr(item, "actions", None)
            if raw_actions is not None:
                for a in raw_actions:
                    cua_actions.append(a if isinstance(a, dict) else _cua_action_to_dict(a))
            # Check for pending safety checks.
            psc = getattr(item, "pending_safety_checks", None)
            if psc:
                new_safety_checks = [{"id": c.id, "code": c.code, "message": c.message} for c in psc]
                sys.stderr.write(f"[CUA] Safety checks pending: {[c['code'] for c in new_safety_checks]}\n")

    # Translate CUA actions to our action space.
    translated = translate_cua_actions(cua_actions, display_width, display_height) if cua_actions else []

    # If done (no computer_call), emit stop action.
    if done:
        text_output = " ".join(text_parts).strip()
        translated = [{"type": "stop", "answer": text_output or "Task completed."}]

    reasoning_text = " ".join(reasoning_parts).strip() or None
    text_output = " ".join(text_parts).strip() or None

    # Build a sanitised copy of the request for logging (strip base64 images).
    request_log = _sanitize_payload_for_log(kwargs)

    # Extract usage from the OpenAI response for cost tracking.
    raw_usage = getattr(response, "usage", None)
    usage_dict: Optional[Dict[str, Any]] = None
    if raw_usage is not None:
        # Responses API style: input_tokens / output_tokens
        inp = getattr(raw_usage, "input_tokens", 0) or 0
        out = getattr(raw_usage, "output_tokens", 0) or 0
        # Cached tokens live under input_tokens_details.cached_tokens
        cached = 0
        details = getattr(raw_usage, "input_tokens_details", None)
        if details is not None:
            cached = getattr(details, "cached_tokens", 0) or 0
        usage_dict = {
            "input_tokens": inp,
            "output_tokens": out,
            "cached_input_tokens": cached,
        }

    return {
        "response_id": response.id,
        "actions": translated,
        "cua_actions": cua_actions,
        "call_id": call_id,
        "done": done,
        "text_output": text_output,
        "reasoning": reasoning_text,
        "pending_safety_checks": new_safety_checks,
        "request_log": request_log,
        "usage": usage_dict,
    }


def _cua_action_to_dict(action_obj: Any) -> Dict[str, Any]:
    """Convert an SDK CUA action object to a plain dict."""
    if isinstance(action_obj, dict):
        return action_obj
    # The OpenAI SDK returns typed Pydantic objects.  The actual field names
    # from the SDK are: type, x, y, button, text, keys, scroll_x, scroll_y,
    # path (list of {x, y}).  "wait" and "screenshot" have only "type".
    d: Dict[str, Any] = {}
    for attr in ("type", "x", "y", "button", "text", "keys",
                 "scroll_x", "scroll_y", "path"):
        val = getattr(action_obj, attr, None)
        if val is not None:
            # Convert path elements (Pydantic objects) to plain dicts.
            if attr == "path" and isinstance(val, list):
                val = [{"x": p.x, "y": p.y} if not isinstance(p, dict) else p for p in val]
            d[attr] = val
    return d


def call_gemini(prompt: str, model: str, images_b64: Optional[List[str]],
                *, conversation: Optional[List[Dict[str, Any]]] = None) -> Tuple[Any, str]:
    api_key = gemini_api_key()
    if not api_key:
        raise SystemExit("Set GEMINI_API_KEY (or LLM_API_KEY) for Gemini models.")
    base = os.getenv("GEMINI_BASE_URL", "https://generativelanguage.googleapis.com")
    version = os.getenv("GEMINI_API_VERSION", "v1beta").strip() or "v1beta"
    url = f"{base.rstrip('/')}/{version}/models/{urllib.parse.quote(model)}:generateContent"

    if conversation:
        system_text, contents = _to_gemini_contents(conversation)
    else:
        # Legacy single-shot fallback.
        parts: List[Dict[str, Any]] = [{"text": prompt}]
        if images_b64:
            for img in images_b64:
                parts.append({"inline_data": {"mime_type": _IMAGE_MIME, "data": img}})
        system_text = build_system_prompt()
        contents = [{"role": "user", "parts": parts}]

    gen_config: Dict[str, Any] = {
        "temperature": _llm_temperature(),
        "maxOutputTokens": max(128, env_int("LLM_MAX_TOKENS", 2048)),
    }
    seed = _llm_seed()
    if seed is not None:
        gen_config["seed"] = seed
    req_payload: Dict[str, Any] = {
        "contents": contents,
        "systemInstruction": {"parts": [{"text": system_text}]},
        "generationConfig": gen_config,
        "safetySettings": [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "OFF"},
            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "OFF"},
            {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "OFF"},
            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "OFF"},
            {"category": "HARM_CATEGORY_CIVIC_INTEGRITY", "threshold": "OFF"},
        ],
    }
    headers = {"x-goog-api-key": api_key}

    def _call():
        return http_post_json(url, headers=headers, payload=req_payload)

    data = retry_with_backoff(_call)
    _log_gemini_usage(data, model=model, label="Gemini")
    try:
        candidates = data.get("candidates") or []
        if not candidates:
            feedback = data.get("promptFeedback", {})
            block_reason = feedback.get("blockReason", "unknown")
            raise LLMRecoverableError(
                f"Gemini returned no candidates (blockReason={block_reason}).\n"
                f"Raw: {json.dumps(data)[:2000]}"
            )
        content = candidates[0]["content"]["parts"]
        text = "".join(p.get("text", "") for p in content if isinstance(p, dict))
    except LLMRecoverableError:
        raise
    except Exception as exc:
        raise SystemExit(f"Unexpected Gemini response shape.\nRaw: {json.dumps(data)[:2000]}") from exc
    try:
        return extract_json(text), text
    except Exception as exc:
        raise SystemExit(f"Gemini response is not valid JSON: {exc}\nRaw: {text}") from exc


# ---------------------------------------------------------------------------
# Shared iOS Computer Use system prompt
# ---------------------------------------------------------------------------
# Each provider's CU tool exposes different action names (click_at vs
# left_click vs click, etc.).  The shared base keeps the iOS context,
# navigation strategy, and task-completion instructions identical across
# providers so benchmark scores are comparable.  Only the action-name
# references differ (filled in via ``_build_cu_ios_instructions``).

_CU_ACCESSIBILITY_TREE_INSTRUCTIONS = (
    "\n\nACCESSIBILITY TREE:\n"
    "On each turn you will also receive a text accessibility tree of the current UI. "
    "The tree lists every element with its type, name/label, value, accessibility IDs "
    "(shown as id=\"...\"), and centre coordinates.\n\n"
    "IMPORTANT: The coordinates in the tree are in the SAME coordinate space as your "
    "action coordinates. You can use tree coordinates DIRECTLY as click/tap targets "
    "without any conversion or mapping.\n\n"
    "How to use the two inputs together:\n"
    "- The SCREENSHOT is ground truth for what is displayed on screen.\n"
    "- The TREE provides precise element names and coordinates for targeting.\n"
    "- Use tree coordinates DIRECTLY to click more precisely than visual estimation.\n"
    "- If the screenshot and tree disagree (e.g. an element appears in the tree but not "
    "on screen), trust the screenshot — the element may be off-screen or obscured.\n"
    "- Elements marked [hidden] are in the DOM but not rendered on screen.\n"
    "- If you need to find elements not currently visible, try scrolling."
)


def _build_cu_ios_instructions(
    *,
    tap_action: str,
    type_action: str,
    scroll_action: str,
    home_action: str,
    back_action: str,
    app_switcher_action: str,
    stop_instruction: str,
) -> str:
    """Build the iOS CU system prompt with provider-specific action names."""
    return (
        "You are controlling an iOS Simulator (iPhone). This is a touch-screen mobile "
        "phone with NO mouse cursor, NO physical keyboard shortcuts, and NO right-click.\n\n"
        "CURRENT STATE: You start on the iOS home screen. You must find and open apps yourself.\n\n"
        "HOW TO OPEN APPS:\n"
        "- Tap an app icon on the home screen if it is visible.\n"
        "- To search for an app: swipe DOWN from the MIDDLE of the home screen to open "
        "Spotlight search, then type the app name and tap the result.\n"
        "- Swipe left/right on the home screen to browse additional pages of apps.\n\n"
        "TOUCH INTERACTIONS:\n"
        f"- {tap_action}\n"
        f"- {type_action}\n"
        f"- {scroll_action}\n\n"
        "iOS-SPECIFIC BEHAVIOURS:\n"
        f"- HOME: {home_action}\n"
        f"- APP SWITCHER: {app_switcher_action}\n"
        f"- BACK NAVIGATION: {back_action}\n"
        "- KEYBOARD DISMISS: To dismiss the on-screen keyboard, tap any area outside "
        "the text field.\n\n"
        "COMPLETING THE TASK:\n"
        f"- {stop_instruction}\n"
        "- IMPORTANT: If the task asks you to find, check, look up, or report ANY "
        "information (e.g. a price, a name, a status, a setting value), you MUST "
        "include that exact information in your final text response. This is how "
        "results are communicated back to the user."
    )


_GEMINI_CU_IOS_INSTRUCTIONS = _build_cu_ios_instructions(
    tap_action="Use 'click_at' for all touch/tap interactions (there is no mouse cursor).",
    type_action="To type text, use 'type_text_at' which taps the field and enters text.",
    scroll_action="To scroll content, use 'scroll_at' or 'scroll_document'.",
    home_action=(
        "To return to the home screen, call the 'go_home' function."
    ),
    back_action=(
        "To go back within an app, look for a back button (usually "
        "top-left) and tap it, or use 'go_back' to swipe from the left edge."
    ),
    app_switcher_action=(
        "To open the App Switcher, use 'drag_and_drop' from the bottom "
        "edge upward but stop mid-screen (e.g. from x=500,y=990 to x=500,y=600) and pause."
    ),
    stop_instruction=(
        "When the task is complete, stop calling actions and respond with "
        "a text summary of what you accomplished."
    ),
) + (
    "\n\nCUSTOM iOS FUNCTIONS:\n"
    "You have access to the following custom functions in addition to standard actions:\n"
    "- long_press_at(x, y, duration): Long-press (touch and hold) at a coordinate. "
    "Use for context menus, rearranging items, or any interaction requiring a "
    "sustained press. Duration defaults to 1.5 seconds.\n"
    "- go_home(): Navigate to the iOS home screen instantly."
)

# Extra system prompt fragment appended only in XML agent mode.
_GEMINI_CU_XML_OPEN_APP_INSTRUCTIONS = (
    "\n- open_app(bundle_id): Launch an app directly by its bundle ID. This is the "
    "PREFERRED way to open apps — faster and more reliable than tapping icons or "
    "using Spotlight search. Bundle IDs for installed apps are listed in the task."
)


# ---------------------------------------------------------------------------
# Gemini Computer Use via the generateContent API
# ---------------------------------------------------------------------------

# Actions we exclude from Gemini CU on iOS.
# NOTE: ENVIRONMENT_BROWSER is the only valid environment value in the
# Gemini CU API (ENVIRONMENT_UNSPECIFIED defaults to browser too).  To
# improve behaviour on an iOS simulator we exclude predefined functions
# that have no meaningful mobile equivalent.
#
# - open_web_browser: excluded; our system prompt directs the model to
#   use click_at on app icons or Spotlight search to open apps.
# - hover_at: no hover concept on a touchscreen; the model should use
#   click_at instead.  Mapping hover→tap is misleading (triggers taps
#   when the model only intended a hover preview).
# - go_forward: browser forward-button; no iOS equivalent.  go_back is
#   kept because the left-edge swipe translation works reliably.
_GEMINI_CU_EXCLUDED_FUNCTIONS = ["open_web_browser", "hover_at", "go_forward"]

# ---------------------------------------------------------------------------
# Custom iOS function declarations for Gemini CU
# ---------------------------------------------------------------------------
# These are user-defined functions passed alongside the built-in computer_use
# tool.  The model can call them instead of (or in addition to) standard UI
# actions, giving it reliable iOS-specific capabilities that don't exist in
# the browser-oriented predefined function set.

# Functions available in all modes (vision-only and XML agent).
_GEMINI_CU_CUSTOM_FUNCTIONS: List[Dict[str, Any]] = [
    {
        "name": "long_press_at",
        "description": (
            "Long-press (touch and hold) at a specific screen coordinate.  "
            "Use this for actions that require a sustained press, such as "
            "opening context menus, rearranging items, or activating drag mode.  "
            "Coordinates are in the 0-999 normalised grid."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "x": {"type": "integer", "description": "X coordinate (0-999 normalised)."},
                "y": {"type": "integer", "description": "Y coordinate (0-999 normalised)."},
                "duration": {
                    "type": "number",
                    "description": "Hold duration in seconds (default 1.5).",
                },
            },
            "required": ["x", "y"],
        },
    },
    {
        "name": "go_home",
        "description": (
            "Navigate to the iOS home screen.  Use this instead of "
            "swiping from the bottom edge."
        ),
        "parameters": {
            "type": "object",
            "properties": {},
        },
    },
]

# open_app is only available in XML agent mode — in vision-only mode the
# model should find and tap app icons or use Spotlight like a real user.
_GEMINI_CU_XML_ONLY_FUNCTIONS: List[Dict[str, Any]] = [
    {
        "name": "open_app",
        "description": (
            "Opens an iOS app by its bundle ID.  Use this instead of "
            "searching for apps on the home screen — it is faster and "
            "more reliable.  The bundle IDs of installed apps are listed "
            "in the task description."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "bundle_id": {
                    "type": "string",
                    "description": "The iOS bundle identifier of the app to launch (e.g. 'com.apple.mobilesafari').",
                },
            },
            "required": ["bundle_id"],
        },
    },
]


def call_gemini_cu(
    task_description: str,
    screenshot_b64: Optional[str],
    *,
    model: str = "gemini-3-flash-preview",
    conversation: Optional[List[Dict[str, Any]]] = None,
    last_function_calls: Optional[List[Dict[str, Any]]] = None,
    xml_tree: Optional[str] = None,
    xml_agent: bool = False,
    last_action_error: Optional[str] = None,
) -> Dict[str, Any]:
    """Call Gemini Computer Use via the generateContent API.

    Returns a dict with:
      actions (translated), cu_actions (raw function_calls), done (bool),
      text_output, conversation (updated).

    *conversation* carries the full ``contents`` array across turns.
    *last_function_calls* is the list of ``functionCall`` dicts from the
    previous model response (used to build ``functionResponse`` on the next turn).
    """
    api_key = gemini_api_key()
    if not api_key:
        raise SystemExit("Set GEMINI_API_KEY (or LLM_API_KEY) for Gemini Computer Use.")
    base = os.getenv("GEMINI_BASE_URL", "https://generativelanguage.googleapis.com")
    version = os.getenv("GEMINI_CU_API_VERSION") or os.getenv("GEMINI_API_VERSION", "v1alpha")
    url = f"{base.rstrip('/')}/{version}/models/{urllib.parse.quote(model)}:generateContent"

    # Tool definition for Computer Use.
    excluded = json.loads(os.getenv("GEMINI_CU_EXCLUDED_FUNCTIONS", "null")) or _GEMINI_CU_EXCLUDED_FUNCTIONS
    tools: List[Dict[str, Any]] = [{
        "computer_use": {
            "environment": os.getenv("GEMINI_CU_ENVIRONMENT", "ENVIRONMENT_BROWSER"),
        },
    }]
    if excluded:
        tools[0]["computer_use"]["excluded_predefined_functions"] = excluded

    # Custom iOS function declarations — passed as a separate Tool so the
    # model can call them alongside standard CU actions.
    # open_app is only included in XML agent mode (vision-only agents should
    # navigate to apps visually).
    custom_fns = list(_GEMINI_CU_CUSTOM_FUNCTIONS)
    if xml_tree is not None:
        custom_fns.extend(_GEMINI_CU_XML_ONLY_FUNCTIONS)
    if custom_fns:
        tools.append({"function_declarations": custom_fns})

    # Build or extend conversation.
    if conversation is None:
        # First turn: user message with task description + screenshot.
        first_turn_text = task_description
        if xml_tree:
            first_turn_text = f"{task_description}\n\n{xml_tree}"
        user_parts: List[Dict[str, Any]] = [{"text": first_turn_text}]
        if screenshot_b64:
            user_parts.append({
                "inline_data": {"mime_type": _IMAGE_MIME, "data": screenshot_b64},
            })
        conversation = [{"role": "user", "parts": user_parts}]
    else:
        # Subsequent turn: send function_response for each function_call
        # from the previous model response, with the new screenshot.
        # The Gemini CU API requires a "url" field in each function response
        # (even for non-browser environments).  We use a descriptive
        # placeholder since iOS has no browser URL.
        if last_function_calls:
            fn_response_parts: List[Dict[str, Any]] = []
            for fc in last_function_calls:
                fn_name = fc.get("name", "unknown")
                response_obj: Dict[str, Any] = {
                    "output": f"{fn_name} executed",
                    "url": "ios-simulator://current-screen",
                }
                # If the model flagged a safety_decision requiring confirmation,
                # acknowledge it automatically (we trust all iOS simulator actions).
                fc_args = fc.get("args") or {}
                if fc_args.get("safety_decision"):
                    response_obj["safety_acknowledgement"] = "true"
                fn_response_parts.append({
                    "functionResponse": {
                        "name": fn_name,
                        "response": response_obj,
                    },
                })
            # Attach the screenshot as an inline_data part alongside
            # the function responses.  The Gemini CU model uses this
            # to observe the new screen state.
            if screenshot_b64:
                fn_response_parts.append({
                    "inline_data": {"mime_type": _IMAGE_MIME, "data": screenshot_b64},
                })
            conversation.append({"role": "user", "parts": fn_response_parts})
            # Inject error feedback as a separate user turn (Gemini API
            # does not allow mixing text with functionResponse parts).
            if last_action_error:
                conversation.append({"role": "user", "parts": [{"text": (
                    f"⚠ ACTION ERROR:\n{last_action_error}\n"
                    "Re-plan from the current screen state. Do not repeat the same failed action. "
                    "If you need to type, first tap a text field to bring up the keyboard."
                )}]})
            # Inject XML accessibility tree as a separate user turn.
            # Gemini API does not allow mixing text parts with
            # functionResponse parts in the same turn.
            if xml_tree:
                conversation.append({"role": "user", "parts": [{"text": xml_tree}]})
            elif xml_agent:
                conversation.append({"role": "user", "parts": [{"text": "⚠ Accessibility tree unavailable this step (timed out). Use the screenshot to decide your next action."}]})

    # System instruction.
    system_prompt = _GEMINI_CU_IOS_INSTRUCTIONS
    if xml_tree:
        system_prompt += _GEMINI_CU_XML_OPEN_APP_INSTRUCTIONS
        system_prompt += _CU_ACCESSIBILITY_TREE_INSTRUCTIONS

    gen_config: Dict[str, Any] = {
        "temperature": _llm_temperature(),
        "maxOutputTokens": max(4096, env_int("GEMINI_CU_MAX_TOKENS", 8192)),
    }
    seed = _llm_seed()
    if seed is not None:
        gen_config["seed"] = seed

    # Drop screenshots from older turns to prevent request size issues.
    trimmed_conversation = _trim_old_screenshots_raw(conversation, keep_recent=_SCREENSHOT_KEEP_RECENT)

    req_payload: Dict[str, Any] = {
        "contents": trimmed_conversation,
        "systemInstruction": {"parts": [{"text": system_prompt}]},
        "tools": tools,
        "generationConfig": gen_config,
        "safetySettings": [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "OFF"},
            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "OFF"},
            {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "OFF"},
            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "OFF"},
            {"category": "HARM_CATEGORY_CIVIC_INTEGRITY", "threshold": "OFF"},
        ],
    }

    headers = {"x-goog-api-key": api_key}

    def _call():
        return http_post_json(url, headers=headers, payload=req_payload, timeout_s=180)

    try:
        data = retry_with_backoff(_call)
    except HTTPPayloadError as exc:
        # Likely oversized payload — aggressively trim and retry once.
        sys.stderr.write(f"[llm_action_generator] Gemini CU HTTP 400 — trimming payload and retrying once\n")
        req_payload["contents"] = _trim_old_screenshots_raw(
            req_payload["contents"], keep_recent=1,
        )
        try:
            data = retry_with_backoff(_call)
        except HTTPPayloadError:
            raise LLMRecoverableError(
                f"Gemini CU HTTP 400 after payload trimming: {exc}"
            ) from exc
    _log_gemini_usage(data, model=model, label="Gemini CU")

    # Parse response.
    candidates = data.get("candidates") or []
    if not candidates:
        feedback = data.get("promptFeedback", {})
        block_reason = feedback.get("blockReason", "unknown")
        raise LLMRecoverableError(
            f"Gemini CU returned no candidates (blockReason={block_reason}).\n"
            f"Raw: {json.dumps(data)[:2000]}"
        )
    content = candidates[0].get("content", {})
    parts = content.get("parts") or []

    text_parts: List[str] = []
    thought_parts: List[str] = []
    function_calls: List[Dict[str, Any]] = []
    translated: List[Dict[str, Any]] = []
    safety_requires_confirm = False

    for part in parts:
        if not isinstance(part, dict):
            continue

        if "text" in part:
            txt = part["text"]
            if txt and txt.strip():
                # Gemini 3 models return thinking content as parts with
                # ``thought: true``.  These must NOT be treated as the
                # model's final text answer — only non-thought text counts.
                if part.get("thought"):
                    thought_parts.append(txt.strip())
                else:
                    text_parts.append(txt.strip())

        if "functionCall" in part:
            fc = part["functionCall"]
            function_calls.append(fc)
            translated.extend(translate_gemini_cu_actions(fc))

            # Check for safety decision requiring confirmation.
            args = fc.get("args", {})
            if args.get("safety_decision") == "require_confirmation":
                safety_requires_confirm = True

    # If model returned function calls, the task continues.
    # If it returned only text (no function calls), the task is done.
    done = len(function_calls) == 0

    if done and conversation is not None and len(conversation) > 1:
        # Non-first turn with no function calls — the model may have
        # degenerated into a thinking loop (common with Gemini 3 Flash).
        # Log a warning but still treat as done (benchmark failure).
        sys.stderr.write(
            f"[Gemini CU] WARNING: No function calls on turn "
            f"{len(conversation) // 2 + 1}. "
            f"Model may have degenerated (thought_parts={len(thought_parts)}, "
            f"text_parts={len(text_parts)}).\n"
        )

    # Append model response to conversation history.
    # This preserves thoughtSignature fields on parts, which Gemini 3
    # models require for multi-turn reasoning continuity.
    conversation.append({"role": "model", "parts": parts})

    # If safety confirmation is needed, auto-acknowledge and re-call immediately
    # so the action is actually executed before returning to the caller.
    if safety_requires_confirm:
        sys.stderr.write("[Gemini CU] Safety confirmation required; auto-acknowledging.\n")
        ack_parts: List[Dict[str, Any]] = []
        for fc in function_calls:
            ack_parts.append({
                "functionResponse": {
                    "name": fc.get("name", "unknown"),
                    "response": {"safety_acknowledgement": "true"},
                },
            })
        conversation.append({"role": "user", "parts": ack_parts})
        req_payload["contents"] = conversation
        ack_data = retry_with_backoff(_call)
        ack_candidates = ack_data.get("candidates") or []
        if ack_candidates:
            ack_content = ack_candidates[0].get("content", {})
            ack_parts_resp = ack_content.get("parts") or []
            conversation.append({"role": "model", "parts": ack_parts_resp})
            # Re-parse function calls from the post-ack response.
            function_calls = []
            translated = []
            for part in ack_parts_resp:
                if not isinstance(part, dict):
                    continue
                if "functionCall" in part:
                    fc = part["functionCall"]
                    function_calls.append(fc)
                    translated.extend(translate_gemini_cu_actions(fc))
            done = len(function_calls) == 0

    # If done, emit stop action.  Use only non-thought text for the answer
    # (thought_parts contain internal reasoning, not user-facing output).
    if done:
        text_output = " ".join(text_parts).strip()
        # Cap degenerate thought-loop answers (Gemini 3 Flash can emit
        # 50KB+ of repeated sentences).  2000 chars is more than enough
        # for any real task answer.
        if len(text_output) > 2000:
            sys.stderr.write(
                f"[Gemini CU] Truncating oversized stop answer "
                f"({len(text_output)} chars → 2000).\n"
            )
            text_output = text_output[:2000]
        translated = [{"type": "stop", "answer": text_output or "Task completed."}]

    text_output = " ".join(text_parts).strip() or None

    # Build a sanitised copy of the request for logging (strip base64 images).
    request_log = _sanitize_payload_for_log(req_payload)

    # Extract usage from the Gemini response for cost tracking.
    usage_meta = data.get("usageMetadata") or {}
    gemini_usage: Optional[Dict[str, Any]] = None
    if usage_meta:
        gemini_usage = {
            "input_tokens": usage_meta.get("promptTokenCount", 0),
            "output_tokens": usage_meta.get("candidatesTokenCount", 0),
            "cached_input_tokens": usage_meta.get("cachedContentTokenCount", 0),
        }

    return {
        "actions": translated,
        "cu_actions": function_calls,
        "done": done,
        "text_output": text_output,
        "conversation": conversation,
        "last_function_calls": function_calls,
        "request_log": request_log,
        "usage": gemini_usage,
    }


def call_anthropic(prompt: str, model: str, images_b64: Optional[List[str]],
                   *, conversation: Optional[List[Dict[str, Any]]] = None) -> Tuple[Any, str]:
    api_key = anthropic_api_key()
    if not api_key:
        raise SystemExit("Set ANTHROPIC_API_KEY (or LLM_API_KEY) for Claude models.")
    base = os.getenv("ANTHROPIC_BASE_URL", "https://api.anthropic.com")
    url = f"{base.rstrip('/')}/v1/messages"

    if conversation:
        system_text, messages = _to_anthropic_messages(conversation)
    else:
        # Legacy single-shot fallback.
        user_parts: List[Dict[str, Any]] = [{"type": "text", "text": prompt}]
        if images_b64:
            for img in images_b64:
                user_parts.append(
                    {
                        "type": "image",
                        "source": {"type": "base64", "media_type": _IMAGE_MIME, "data": img},
                    }
                )
        system_text = build_system_prompt()
        messages = [{"role": "user", "content": user_parts}]

    # Apply prompt caching breakpoints.
    cached_system, messages = _add_anthropic_cache_breakpoints(system_text, messages)

    req_payload: Dict[str, Any] = {
        "model": model,
        "max_tokens": max(128, env_int("LLM_MAX_TOKENS", 2048)),
        "temperature": _llm_temperature(),
        "system": cached_system,
        "messages": messages,
    }
    headers = {
        "x-api-key": api_key,
        "anthropic-version": os.getenv("ANTHROPIC_VERSION", "2023-06-01"),
        "anthropic-beta": "prompt-caching-2024-07-31",
    }

    def _call():
        return http_post_json(url, headers=headers, payload=req_payload)

    data = retry_with_backoff(_call)
    _log_anthropic_usage(data.get("usage", {}), model=model, label="Anthropic")
    try:
        blocks = data.get("content") or []
        text = "".join(b.get("text", "") for b in blocks if isinstance(b, dict) and b.get("type") == "text")
    except Exception as exc:
        raise SystemExit(f"Unexpected Anthropic response shape.\nRaw: {json.dumps(data)[:2000]}") from exc
    try:
        return extract_json(text), text
    except Exception as exc:
        raise SystemExit(f"Anthropic response is not valid JSON: {exc}\nRaw: {text}") from exc


# ---------------------------------------------------------------------------
# Claude Computer Use via the Messages API
# ---------------------------------------------------------------------------

_CLAUDE_CU_IOS_INSTRUCTIONS = _build_cu_ios_instructions(
    tap_action="Use 'left_click' for all touch/tap interactions (there is no mouse cursor).",
    type_action="To type text, click a text field first, then use the 'type' action to enter text.",
    scroll_action="To scroll content, use the 'scroll' action with delta_x/delta_y.",
    home_action=(
        "To return to the home screen, use key 'Home', or "
        "swipe up from the very bottom of the screen (left_click_drag from bottom edge upward)."
    ),
    back_action=(
        "To go back within an app, look for a back button (usually top-left) or swipe "
        "from the left edge of the screen to the right."
    ),
    app_switcher_action="To open the App Switcher, swipe up from the bottom and pause mid-screen.",
    stop_instruction=(
        "When the task is complete, stop calling the computer tool and respond with "
        "a text summary of what you accomplished."
    ),
)


def call_anthropic_cu(
    task_description: str,
    screenshot_b64: Optional[str],
    *,
    model: str = "claude-sonnet-4-6",
    conversation: Optional[List[Dict[str, Any]]] = None,
    display_width: int = 1280,
    display_height: int = 800,
    tool_use_ids: Optional[List[str]] = None,
    xml_tree: Optional[str] = None,
    xml_agent: bool = False,
    last_action_error: Optional[str] = None,
) -> Dict[str, Any]:
    """Call Claude Computer Use via the Messages API.

    Returns a dict with:
      actions (translated), cu_actions (raw), tool_use_ids (list), done (bool),
      text_output, reasoning, conversation (updated).
    """
    api_key = anthropic_api_key()
    if not api_key:
        raise SystemExit("Set ANTHROPIC_API_KEY (or LLM_API_KEY) for Claude Computer Use.")
    base = os.getenv("ANTHROPIC_BASE_URL", "https://api.anthropic.com")
    url = f"{base.rstrip('/')}/v1/messages"

    # Build tool definition.
    tools: List[Dict[str, Any]] = [{
        "type": "computer_20251124",
        "name": "computer",
        "display_width_px": display_width,
        "display_height_px": display_height,
    }]

    # Build or extend conversation.
    if conversation is None:
        # First turn: user message with task description + screenshot.
        first_turn_text = task_description
        if xml_tree:
            first_turn_text = f"{task_description}\n\n{xml_tree}"
        user_content: List[Dict[str, Any]] = [
            {"type": "text", "text": first_turn_text},
        ]
        if screenshot_b64:
            user_content.append({
                "type": "image",
                "source": {"type": "base64", "media_type": _IMAGE_MIME, "data": screenshot_b64},
            })
        conversation = [{"role": "user", "content": user_content}]
    else:
        # Subsequent turn: send a tool_result for EACH tool_use_id from the
        # previous assistant response.  The Anthropic API requires exactly one
        # tool_result per tool_use block.  We attach the screenshot only to the
        # last tool_result (the final state after executing all actions).
        if tool_use_ids:
            user_msg_content: List[Dict[str, Any]] = []
            for idx, tui in enumerate(tool_use_ids):
                result_content: List[Dict[str, Any]] = []
                is_last = idx == len(tool_use_ids) - 1
                if is_last and screenshot_b64:
                    result_content.append({
                        "type": "image",
                        "source": {"type": "base64", "media_type": _IMAGE_MIME, "data": screenshot_b64},
                    })
                user_msg_content.append({
                    "type": "tool_result",
                    "tool_use_id": tui,
                    "content": result_content,
                })
            # Inject error feedback from the previous action batch.
            if last_action_error:
                user_msg_content.append({"type": "text", "text": (
                    f"⚠ ACTION ERROR:\n{last_action_error}\n"
                    "Re-plan from the current screen state. Do not repeat the same failed action. "
                    "If you need to type, first tap a text field to bring up the keyboard."
                )})
            # Inject XML accessibility tree alongside the tool results.
            if xml_tree:
                user_msg_content.append({"type": "text", "text": xml_tree})
            elif xml_agent:
                user_msg_content.append({"type": "text", "text": "⚠ Accessibility tree unavailable this step (timed out). Use the screenshot to decide your next action."})
            conversation.append({
                "role": "user",
                "content": user_msg_content,
            })

    # Thinking configuration.
    # If CLAUDE_CU_EFFORT is set, use adaptive thinking with that effort level.
    # Otherwise, auto-select based on model: "max" for Opus, "high" for Sonnet.
    cu_effort = os.getenv("CLAUDE_CU_EFFORT", "")
    if not cu_effort:
        # Auto-select effort based on model capability.
        if "opus" in model.lower():
            cu_effort = "max"
        else:
            cu_effort = "high"
    thinking_config: Dict[str, Any] = {"type": "adaptive"}
    output_config: Optional[Dict[str, Any]] = {"effort": cu_effort}

    system_prompt: Any = _CLAUDE_CU_IOS_INSTRUCTIONS
    if xml_tree:
        system_prompt += _CU_ACCESSIBILITY_TREE_INSTRUCTIONS

    # Drop screenshots from older turns to prevent HTTP 413 (request too large).
    conversation = _trim_old_screenshots_raw(conversation, keep_recent=_SCREENSHOT_KEEP_RECENT)

    # Apply prompt caching breakpoints.
    cached_system, conversation = _add_anthropic_cache_breakpoints(system_prompt, conversation)

    req_payload: Dict[str, Any] = {
        "model": model,
        "max_tokens": max(4096, env_int("CLAUDE_CU_MAX_TOKENS", 16384)),
        "system": cached_system,
        "tools": tools,
        "messages": conversation,
        "thinking": thinking_config,
    }
    if output_config:
        req_payload["output_config"] = output_config

    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "anthropic-beta": "prompt-caching-2024-07-31,computer-use-2025-11-24",
    }

    def _call():
        return http_post_json(url, headers=headers, payload=req_payload, timeout_s=180)

    data = retry_with_backoff(_call)
    _log_anthropic_usage(data.get("usage", {}), model=model, label="Claude CU")

    # Parse response.
    stop_reason = data.get("stop_reason", "")
    content_blocks = data.get("content") or []

    text_parts: List[str] = []
    thinking_parts: List[str] = []
    cu_actions: List[Dict[str, Any]] = []
    translated: List[Dict[str, Any]] = []
    new_tool_use_ids: List[str] = []

    for block in content_blocks:
        if not isinstance(block, dict):
            continue
        btype = block.get("type")

        if btype == "thinking":
            thinking_text = block.get("thinking", "")
            if thinking_text and thinking_text.strip():
                thinking_parts.append(thinking_text.strip())

        elif btype == "text":
            txt = block.get("text", "")
            if txt and txt.strip():
                text_parts.append(txt.strip())

        elif btype == "tool_use" and block.get("name") == "computer":
            tui = block.get("id")
            if tui:
                new_tool_use_ids.append(tui)
            tool_input = block.get("input", {})
            cu_actions.append(tool_input)
            translated.extend(
                translate_claude_cu_actions(tool_input, display_width, display_height)
            )

    if len(new_tool_use_ids) > 1:
        sys.stderr.write(
            f"[Claude CU] Multiple computer tool_use blocks in one response "
            f"({len(new_tool_use_ids)}); sending tool_result for each.\n"
        )

    done = stop_reason != "tool_use"

    # If done, emit stop action with text output as answer.
    if done:
        text_output = " ".join(text_parts).strip()
        translated = [{"type": "stop", "answer": text_output or "Task completed."}]

    # Append assistant response to conversation (preserve ALL blocks including thinking).
    conversation.append({"role": "assistant", "content": content_blocks})

    reasoning_text = " ".join(thinking_parts).strip() or None
    text_output = " ".join(text_parts).strip() or None

    # Build a sanitised copy of the request for logging (strip base64 images).
    request_log = _sanitize_payload_for_log(req_payload)

    return {
        "actions": translated,
        "cu_actions": cu_actions,
        "tool_use_ids": new_tool_use_ids,
        "done": done,
        "text_output": text_output,
        "reasoning": reasoning_text,
        "conversation": conversation,
        "request_log": request_log,
        "response_log": {k: v for k, v in data.items() if k != "content"} if data else None,
    }


# ---------------------------------------------------------------------------
# Qwen Computer Use (mobile_use cookbook) via vLLM Chat Completions
# ---------------------------------------------------------------------------

_QWEN_CU_BASE_INSTRUCTIONS = (
    "You are a mobile-device agent using the `mobile_use` tool.\n\n"
    "The screen's resolution is 999x999. Use coordinates in this 999x999 coordinate space.\n"
    "You are controlling an iOS Simulator with a touchscreen. There is no mouse cursor, "
    "no right click, and no physical keyboard shortcuts.\n\n"
    "Action rules:\n"
    "- Click the center of buttons, links, icons, fields, or rows; do not click edges.\n"
    "- To type, first click the input field and wait for it to become active, then use `type`.\n"
    "- To scroll, use `swipe` from a start coordinate to an end coordinate. On iOS, swiping up "
    "moves content down the page.\n"
    "- To return to the Home screen, use `system_button` with button `Home`.\n"
    "- To go back, click the visible back control when present; otherwise use `system_button` "
    "with button `Back`.\n"
    "- If the UI needs time to update, use `wait`.\n"
    "- For compound tasks, complete every requested UI side effect before answering. For example, "
    "if the user asks you to add/save/book/order/request/send something and also report information, "
    "perform the add/save/book/order/request/send action first, then call `answer` only after the "
    "screen confirms it is complete.\n"
    "- If any requested action is still pending, do not call `answer` or `terminate`; perform the "
    "next pending UI action instead.\n"
    "- If the task asks for information, finish by calling `answer` with the exact requested information "
    "only after all requested UI actions are complete.\n"
    "- If the task only requires completing an action and no answer text, finish by calling `terminate` "
    "with status `success`.\n"
    "- If the task is impossible, call `terminate` "
    "with status `failure`.\n\n"
    "Response format for every step:\n"
    "1) Thought: one concise sentence explaining the next move.\n"
    "2) Action: one short imperative describing the UI operation.\n"
    "3) Exactly one `mobile_use` tool call.\n\n"
    "Keep each step local and concrete. Do not plan multiple future steps in one response."
)


_QWEN_CU_VISION_ONLY_INSTRUCTIONS = (
    "\n\nCURRENT OBSERVATION:\n"
    "Each turn includes the current screenshot. Use the screenshot as the ground truth for "
    "visible UI state and choose coordinates in the 999x999 action grid."
)


_QWEN_CU_XML_INSTRUCTIONS = (
    "\n\nCURRENT OBSERVATION:\n"
    "Each turn includes the current screenshot and a text accessibility tree of the current UI. "
    "The tree lists elements with type, name/label, value, accessibility IDs (shown as id=\"...\"), "
    "and center coordinates in the same 999x999 action grid.\n\n"
    "How to use screenshot and tree together:\n"
    "- The screenshot is ground truth for what is visibly displayed.\n"
    "- Use tree coordinates directly for precise click targets when the element is visible.\n"
    "- If screenshot and tree disagree, trust the screenshot; the tree element may be hidden, "
    "off-screen, or obscured.\n"
    "- Elements marked [hidden] are not visible; do not click them unless the task explicitly "
    "requires hidden/system state.\n"
    "- If the needed element is not visible, scroll or navigate rather than clicking a hidden element."
)


def _qwen_cu_system_prompt(*, xml_agent: bool) -> str:
    return _QWEN_CU_BASE_INSTRUCTIONS + _qwen_cu_tools_prompt_block() + (
        _QWEN_CU_XML_INSTRUCTIONS if xml_agent else _QWEN_CU_VISION_ONLY_INSTRUCTIONS
    )


def _qwen_mobile_use_tool() -> Dict[str, Any]:
    """OpenAI-compatible JSON schema for Qwen3-VL's ``mobile_use`` tool.

    Description text and action enum copied verbatim from the cookbook
    (https://github.com/QwenLM/Qwen3-VL/blob/main/cookbooks/mobile_agent.ipynb)
    so the model sees the exact format it was trained on.

    The hardcoded "999x999" resolution is the cookbook contract — model
    output coordinates always live on a 0-999 grid regardless of the actual
    image bytes; ``translate_qwen_cu_actions`` rescales accordingly.
    """
    return {
        "type": "function",
        "function": {
            "name": "mobile_use",
            "description": (
                "Use a touchscreen to interact with a mobile device, and take screenshots.\n"
                "* This is an interface to a mobile device with touchscreen. You can perform "
                "actions like clicking, typing, swiping, etc.\n"
                "* Some applications may take time to start or process actions, so you may "
                "need to wait and take successive screenshots to see the results of your actions.\n"
                "* The screen's resolution is 999x999.\n"
                "* Make sure to click any buttons, links, icons, etc with the cursor tip in "
                "the center of the element. Don't click boxes on their edges unless asked."
            ),
            "parameters": {
                "type": "object",
                "required": ["action"],
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": [
                            "click", "long_press", "swipe", "type", "answer",
                            "system_button", "wait", "terminate",
                        ],
                        "description": (
                            "The action to perform. The available actions are:\n"
                            "* `click`: Click the point on the screen with coordinate (x, y).\n"
                            "* `long_press`: Press the point on the screen with coordinate (x, y) "
                            "for specified seconds.\n"
                            "* `swipe`: Swipe from the starting point with coordinate (x, y) to "
                            "the end point with coordinates2 (x2, y2).\n"
                            "* `type`: Input the specified text into the activated input box.\n"
                            "* `answer`: Output the answer.\n"
                            "* `system_button`: Press the system button.\n"
                            "* `wait`: Wait specified seconds for the change to happen.\n"
                            "* `terminate`: Terminate the current task and report its completion status."
                        ),
                    },
                    "coordinate": {
                        "type": "array",
                        "description": (
                            "(x, y): The x (pixels from the left edge) and y (pixels from the "
                            "top edge) coordinates to move the mouse to. Required only by "
                            "`action=click`, `action=long_press`, and `action=swipe`."
                        ),
                    },
                    "coordinate2": {
                        "type": "array",
                        "description": (
                            "(x, y): The x (pixels from the left edge) and y (pixels from the "
                            "top edge) coordinates to move the mouse to. Required only by `action=swipe`."
                        ),
                    },
                    "text": {
                        "type": "string",
                        "description": "Required only by `action=type` and `action=answer`.",
                    },
                    "time": {
                        "type": "number",
                        "description": "The seconds to wait. Required only by `action=long_press` and `action=wait`.",
                    },
                    "button": {
                        "type": "string",
                        "enum": ["Back", "Home", "Menu", "Enter"],
                        "description": (
                            "Back means returning to the previous interface, Home means returning "
                            "to the desktop, Menu means opening the application background menu, "
                            "and Enter means pressing the enter. Required only by `action=system_button`"
                        ),
                    },
                    "status": {
                        "type": "string",
                        "enum": ["success", "failure"],
                        "description": "The status of the task. Required only by `action=terminate`.",
                    },
                },
            },
        },
    }


def _qwen_cu_tools_prompt_block() -> str:
    """Qwen3.5-style embedded ``mobile_use`` tool contract.

    Qwen3.5's tokenizer_config tool template differs from the Qwen3-VL
    mobile_agent.ipynb example: the model is instructed to emit
    <tool_call><function=name><parameter=...>...</parameter></function></tool_call>
    rather than a JSON object inside <tool_call>.  Keep the tool schema JSON
    identical to the OpenAI-compatible tool object, but ask for the native
    Qwen3.5 XML function-call envelope.
    """
    tool_schema = json.dumps(_qwen_mobile_use_tool(), ensure_ascii=False)
    return (
        "\n\n# Tools\n\n"
        "You may call one or more functions to assist with the user query.\n\n"
        "You are provided with function signatures within <tools></tools> XML tags:\n"
        "<tools>\n"
        f"{tool_schema}\n"
        "</tools>\n\n"
        "If you choose to call a function ONLY reply in the following format with NO suffix:\n\n"
        "<tool_call>\n"
        "<function=example_function_name>\n"
        "<parameter=example_parameter_1>\n"
        "value_1\n"
        "</parameter>\n"
        "<parameter=example_parameter_2>\n"
        "This is the value for the second parameter\n"
        "that can span\n"
        "multiple lines\n"
        "</parameter>\n"
        "</function>\n"
        "</tool_call>\n\n"
        "<IMPORTANT>\n"
        "Reminder:\n"
        "- Function calls MUST follow the specified format: an inner <function=...></function> "
        "block must be nested within <tool_call></tool_call> XML tags.\n"
        "- Required parameters MUST be specified.\n"
        "- You may provide optional reasoning for your function call in natural language BEFORE "
        "the function call, but NOT after.\n"
        "- If there is no function call available, answer the question normally.\n"
        "</IMPORTANT>\n\n"
        "# Response format\n\n"
        "Response format for every step:\n"
        "1) Thought: one concise sentence explaining the next move (no multi-step reasoning).\n"
        "2) Action: a short imperative describing what to do in the UI.\n"
        "3) A single <tool_call>...</tool_call> block containing exactly one "
        "<function=mobile_use>...</function> call.\n\n"
        "Rules:\n"
        "- Output exactly in the order: Thought, Action, <tool_call>.\n"
        "- Be brief: one sentence for Thought, one for Action.\n"
        "- Do not output anything after </tool_call>.\n"
        "- If finishing, use action=terminate in the tool call."
    )


_QWEN_TOOL_CALL_FENCE_RE = re.compile(
    r"<tool_call>\s*(.*?)\s*</tool_call>", re.DOTALL | re.IGNORECASE,
)
_QWEN_XML_FUNCTION_RE = re.compile(
    r"<function=([^>\s]+)>\s*(.*?)\s*</function>", re.DOTALL | re.IGNORECASE,
)
_QWEN_XML_PARAMETER_RE = re.compile(
    r"<parameter=([^>\s]+)>\s*(.*?)\s*</parameter>", re.DOTALL | re.IGNORECASE,
)


def _parse_qwen_tool_call_from_content(content: str) -> List[Tuple[str, Dict[str, Any]]]:
    """Fallback: extract ``mobile_use`` calls from the raw ``message.content``.

    Needed because vLLM's tool-call parsers (``hermes``, ``qwen3_coder``) can
    miss the fence depending on whitespace / reasoning-parser interactions.
    The cookbook itself does the same thing:
        action = json.loads(output_text.split('<tool_call>\\n')[1].split('\\n</tool_call>')[0])

    Handles BOTH fence payloads:
      * Hermes JSON:    {"name": "mobile_use", "arguments": {...}}
      * Qwen3-Coder XML: <function=mobile_use><parameter=action>click</parameter>...
    """
    calls: List[Tuple[str, Dict[str, Any]]] = []
    if not content:
        return calls
    for fence in _QWEN_TOOL_CALL_FENCE_RE.findall(content):
        fence = fence.strip()
        # 1. Try Hermes JSON.
        if fence.startswith("{"):
            try:
                obj = json.loads(fence)
                name = obj.get("name") or ""
                args = obj.get("arguments") or obj.get("args") or {}
                if isinstance(args, str):
                    try:
                        args = json.loads(args)
                    except json.JSONDecodeError:
                        args = {}
                if name and isinstance(args, dict):
                    calls.append((name, args))
                    continue
            except json.JSONDecodeError:
                pass
        # 2. Try Qwen3-Coder XML.
        fn_match = _QWEN_XML_FUNCTION_RE.search(fence)
        if fn_match:
            fn_name = fn_match.group(1).strip()
            body = fn_match.group(2)
            args: Dict[str, Any] = {}
            for pk, pv in _QWEN_XML_PARAMETER_RE.findall(body):
                pv = pv.strip()
                # Coerce JSON-looking values (arrays, numbers, booleans)
                if pv.startswith(("[", "{")):
                    try:
                        args[pk] = json.loads(pv)
                        continue
                    except json.JSONDecodeError:
                        pass
                if re.fullmatch(r"-?\d+", pv):
                    args[pk] = int(pv)
                elif re.fullmatch(r"-?\d+\.\d+", pv):
                    args[pk] = float(pv)
                elif pv.lower() in ("true", "false"):
                    args[pk] = pv.lower() == "true"
                else:
                    args[pk] = pv
            if fn_name:
                calls.append((fn_name, args))
    return calls


def _extract_qwen_installed_apps(task_description: str) -> Dict[str, str]:
    """Return app-name/bundle aliases from the task's installed-app manifest text."""
    aliases: Dict[str, str] = {}
    for line in (task_description or "").splitlines():
        match = re.match(r"\s*([^:]+):\s*([A-Za-z0-9_.-]+\.[A-Za-z0-9_.-]+)\.?\s*$", line)
        if not match:
            continue
        app_name = match.group(1).strip()
        bundle_id = match.group(2).rstrip(".")
        if not app_name or not bundle_id:
            continue
        aliases[app_name.lower()] = bundle_id
        aliases[app_name.lower().replace(" ", "")] = bundle_id
        aliases[bundle_id.lower()] = bundle_id
        aliases[bundle_id.rsplit(".", 1)[-1].lower()] = bundle_id
    return aliases


def _repair_qwen_cu_action(
    args: Dict[str, Any],
    *,
    app_aliases: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """Recover common malformed Qwen mobile_use actions without changing the prompt contract."""
    repaired = dict(args)
    action = str(repaired.get("action") or "").strip().lower()

    # Qwen occasionally emits action=open/open_app despite the cookbook schema.
    # Treat it as a direct app launch only when the target matches the manifest.
    if action in {"open", "open_app", "launch_app"}:
        target = str(
            repaired.get("bundle_id")
            or repaired.get("app")
            or repaired.get("app_name")
            or repaired.get("text")
            or ""
        ).strip()
        bundle_id = ""
        if target:
            aliases = app_aliases or {}
            bundle_id = aliases.get(target.lower()) or aliases.get(target.lower().replace(" ", ""))
            if not bundle_id and "." in target:
                bundle_id = target
        if bundle_id:
            repaired["action"] = "launch_app"
            repaired["bundle_id"] = bundle_id
    return repaired


def call_qwen_cu(
    task_description: str,
    screenshot_b64: Optional[str],
    *,
    model: str,
    conversation: Optional[List[Dict[str, Any]]] = None,
    task_progress: str = "",
    display_width: int = 1280,
    display_height: int = 800,
    last_tool_call_ids: Optional[List[str]] = None,
    xml_tree: Optional[str] = None,
    xml_agent: bool = False,
    xml_no_screenshot: bool = False,
    last_action_error: Optional[str] = None,
) -> Dict[str, Any]:
    """Call Qwen3-VL Computer Use against an OpenAI-compatible vLLM endpoint.

    Returns a dict with: actions (translated), cu_actions (raw mobile_use
    inputs), tool_call_ids (list), done (bool), text_output, conversation.

    Requires vLLM launched with
    ``--enable-auto-tool-choice --tool-call-parser hermes`` so it converts
    ``<tool_call>...</tool_call>`` content into OpenAI-spec ``message.tool_calls``.
    """
    api_key = vllm_api_key()
    base_url = vllm_base_url()
    try:
        from openai import OpenAI  # type: ignore
    except ImportError as exc:
        raise SystemExit("Missing openai client. Install with `pip install -r requirements.txt`.") from exc
    client = OpenAI(api_key=api_key, base_url=base_url)

    use_openai_tools = os.getenv("QWEN_CU_USE_OPENAI_TOOLS", "").lower() in {"1", "true", "yes", "on"}
    tools: List[Dict[str, Any]] = [_qwen_mobile_use_tool()]

    # Two conversation modes for Qwen-CU:
    #   1. Cookbook stateless (default) — Qwen3-VL `mobile_agent.ipynb`:
    #      system + user(text_with_task_progress + 1 current screenshot).
    #      Past actions encoded as text in `task_progress`. Each turn rebuilds.
    #   2. OSWorld multi-turn (QWEN_CU_MULTI_TURN=1) — qwen3vl_agent.py canon:
    #      Persistent conversation with sliding N=4 screenshot window. Past
    #      actions visible as actual assistant turns + synthetic tool results.
    #      Better for multi-app cross-state-tracking; OOD vs cookbook training.
    multi_turn = os.getenv("QWEN_CU_MULTI_TURN", "").strip().lower() in {"1", "true", "yes", "on"}

    system_prompt = _qwen_cu_system_prompt(xml_agent=bool(xml_tree or xml_agent))
    user_text = _build_qwen_user_query(
        task_description,
        task_progress=task_progress,
        xml_tree=xml_tree,
        xml_agent=xml_agent,
        last_action_error=last_action_error,
    )
    user_content: List[Dict[str, Any]] = [{"type": "text", "text": user_text}]
    if screenshot_b64 and not xml_no_screenshot:
        user_content.append({
            "type": "image_url",
            "image_url": {"url": f"data:{_IMAGE_MIME};base64,{screenshot_b64}"},
        })

    if multi_turn and conversation:
        # Continue the prior conversation. If the last turn was an assistant
        # that emitted tool_calls (the typical case — every Qwen-CU turn ends
        # with a `mobile_use` call), append synthetic tool-result messages so
        # the API sees a closed tool_call→tool_result→user chain. The actual
        # "result" of the action is captured by the new screenshot in the
        # user content we're about to append.
        conversation = list(conversation)  # shallow copy; don't mutate caller's
        if conversation and conversation[-1].get("role") == "assistant":
            last = conversation[-1]
            tool_calls = last.get("tool_calls") or []
            for tc in tool_calls:
                tcid = tc.get("id") if isinstance(tc, dict) else getattr(tc, "id", None)
                if not tcid:
                    continue
                conversation.append({
                    "role": "tool",
                    "tool_call_id": tcid,
                    "content": "Action executed. Updated screen state in the next user message.",
                })
        conversation.append({"role": "user", "content": user_content})
    else:
        # Cookbook stateless rebuild
        conversation = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content},
        ]

    # Sliding-window pruning. In stateless mode this is a no-op (only 1
    # user message ever); in multi-turn mode it caps screenshot history at
    # N (default 4, matching OSWorld qwen3vl_agent's history_n).
    if _SCREENSHOT_KEEP_RECENT is not None:
        _qwen_keep: Optional[int] = _SCREENSHOT_KEEP_RECENT
    elif _QWEN_CU_SCREENSHOT_HISTORY > 0:
        _qwen_keep = _QWEN_CU_SCREENSHOT_HISTORY
    else:
        _qwen_keep = None  # keep all
    trimmed_conversation = _trim_old_screenshots_raw(
        conversation, keep_recent=_qwen_keep,
    )
    trimmed_conversation = _trim_old_qwen_observations_raw(trimmed_conversation)
    if multi_turn:
        trimmed_conversation = _strip_thinking_from_history(trimmed_conversation)

    temp = _llm_temperature()
    seed = _llm_seed()
    extra_kwargs: Dict[str, Any] = {}
    if seed is not None:
        extra_kwargs["seed"] = seed

    def _call():
        kwargs: Dict[str, Any] = {
            "model": model,
            "messages": trimmed_conversation,
            "temperature": temp,
            "max_tokens": max(4096, env_int("QWEN_CU_MAX_TOKENS", 4096)),
            **extra_kwargs,
        }
        if use_openai_tools:
            kwargs["tools"] = tools
            kwargs["tool_choice"] = "auto"
        return client.chat.completions.create(**kwargs)

    resp = retry_with_backoff(_call)
    _log_qwen_cu_usage(getattr(resp, "usage", None), model=model, label="Qwen CU")

    msg = resp.choices[0].message
    text_output = (msg.content or "").strip()
    # vLLM with --reasoning-parser <name> separates the model's chain-of-thought
    # into a sibling `reasoning` field (mirrors OpenAI o-series / Anthropic
    # thinking blocks). Capture it so the trajectory log preserves the why.
    reasoning_text = (getattr(msg, "reasoning", None) or "").strip()
    raw_tool_calls = list(msg.tool_calls or [])
    app_aliases = _extract_qwen_installed_apps(task_description)

    cu_actions: List[Dict[str, Any]] = []
    translated: List[Dict[str, Any]] = []
    new_tool_call_ids: List[str] = []
    for tc in raw_tool_calls:
        fn_name = getattr(tc.function, "name", "")
        if fn_name != "mobile_use":
            sys.stderr.write(f"[Qwen CU] Ignoring unknown tool call: {fn_name!r}\n")
            continue
        try:
            args = json.loads(getattr(tc.function, "arguments", "") or "{}")
        except json.JSONDecodeError:
            args = {}
        args = _repair_qwen_cu_action(args, app_aliases=app_aliases)
        cu_actions.append(args)
        translated.extend(translate_qwen_cu_actions(args))
        if tc.id:
            new_tool_call_ids.append(tc.id)

    # Cookbook-style fallback: if vLLM's tool-call parser missed the fence
    # (whitespace / reasoning-parser interaction), scrape <tool_call>...</tool_call>
    # blocks out of message.content manually. Handles Hermes JSON and
    # Qwen3-Coder XML payloads. Synthesize tool_call_ids so follow-up turns
    # still emit a matching `role: tool` reply.
    if not raw_tool_calls:
        fallback_source = text_output or ""
        fallback = _parse_qwen_tool_call_from_content(fallback_source)
        if not fallback and reasoning_text:
            fallback_source = reasoning_text
            fallback = _parse_qwen_tool_call_from_content(reasoning_text)
        if fallback:
            sys.stderr.write(
                f"[Qwen CU] vLLM tool_calls empty; parsed {len(fallback)} call(s) "
                f"from {'message.reasoning' if fallback_source == reasoning_text else 'message.content'} fence.\n"
            )
            synthetic_tool_calls: List[Dict[str, Any]] = []
            for idx, (fn_name, args) in enumerate(fallback):
                if fn_name != "mobile_use":
                    sys.stderr.write(f"[Qwen CU] Ignoring unknown tool call: {fn_name!r}\n")
                    continue
                tcid = f"fallback-{idx}-{int(time.time() * 1000)}"
                args = _repair_qwen_cu_action(args, app_aliases=app_aliases)
                cu_actions.append(args)
                translated.extend(translate_qwen_cu_actions(args))
                new_tool_call_ids.append(tcid)
                synthetic_tool_calls.append({
                    "id": tcid,
                    "type": "function",
                    "function": {"name": fn_name, "arguments": json.dumps(args)},
                })
            # Strip the fence out of text_output so we don't feed the same
            # XML back to the model as plain content on the next turn.
            if fallback_source == text_output:
                text_output = _QWEN_TOOL_CALL_FENCE_RE.sub("", text_output).strip()
            raw_tool_calls = synthetic_tool_calls  # flag below that we have calls

    # Build a single bool for the "no actions this turn => done" check.
    has_any_call = bool(raw_tool_calls) or bool(cu_actions)
    done = not has_any_call
    if done:
        translated = [{"type": "stop", "answer": text_output or "Task completed."}]

    # Append the assistant turn so the next call has the function-call context.
    # raw_tool_calls may hold either OpenAI SDK ToolCall objects (normal path)
    # or dicts synthesized by the content-fallback parser. Normalise.
    def _tc_to_dict(tc: Any) -> Dict[str, Any]:
        if isinstance(tc, dict):
            return tc
        return {
            "id": getattr(tc, "id", None),
            "type": "function",
            "function": {
                "name": tc.function.name,
                "arguments": tc.function.arguments or "{}",
            },
        }
    assistant_msg: Dict[str, Any] = {"role": "assistant", "content": text_output or ""}
    if raw_tool_calls:
        assistant_msg["tool_calls"] = [_tc_to_dict(tc) for tc in raw_tool_calls]
    # In multi-turn mode, the assistant turn is threaded back to the next call
    # (which will append a synthetic tool result + new user turn). In stateless
    # mode the conversation is rebuilt next call so this is just for logging.
    conversation.append(assistant_msg)

    request_log = _sanitize_payload_for_log({
        "model": model,
        "base_url": base_url,
        "messages": trimmed_conversation,
        "tools": tools,
        "temperature": temp,
        **({"seed": seed} if seed is not None else {}),
    })
    response_log = {
        "id": getattr(resp, "id", None),
        "model": getattr(resp, "model", None),
        "finish_reason": resp.choices[0].finish_reason if resp.choices else None,
        "usage": (getattr(resp, "usage", None).__dict__
                  if getattr(resp, "usage", None) and hasattr(resp.usage, "__dict__") else None),
    }

    return {
        "actions": translated,
        "cu_actions": cu_actions,
        "tool_call_ids": new_tool_call_ids,
        "done": done,
        "text_output": text_output or None,
        "reasoning": reasoning_text or text_output or None,
        "conversation": conversation,
        "request_log": request_log,
        "response_log": response_log,
    }


def call_vllm(prompt: str, model: str, images_b64: Optional[List[str]],
              *, conversation: Optional[List[Dict[str, Any]]] = None) -> Tuple[Any, str]:
    """Chat-Completions call against a vLLM OpenAI-compatible endpoint.

    Used by non-CU paths (XML text-only mode, evaluator) when LLM_PROVIDER=vllm.
    The Qwen-CU mode goes through ``call_qwen_cu`` directly with the cookbook
    ``mobile_use`` tool; this function is for plain JSON-action prompts.
    """
    api_key = vllm_api_key()
    base_url = vllm_base_url()
    try:
        from openai import BadRequestError, OpenAI  # type: ignore
    except ImportError as exc:
        raise SystemExit("Missing openai client. Install with `pip install -r requirements.txt`.") from exc
    client = OpenAI(api_key=api_key, base_url=base_url)

    if conversation:
        messages = _to_openai_messages(conversation)
    else:
        user_content: Any = [{"type": "text", "text": prompt}]
        if images_b64:
            for img in images_b64:
                user_content.append({"type": "image_url", "image_url": {"url": f"data:{_IMAGE_MIME};base64,{img}"}})
        messages = [
            {"role": "system", "content": build_system_prompt()},
            {"role": "user", "content": user_content},
        ]

    temp = _llm_temperature()
    seed = _llm_seed()
    extra_kwargs: Dict[str, Any] = {}
    if seed is not None:
        extra_kwargs["seed"] = seed

    def _call():
        nonlocal messages
        try:
            return client.chat.completions.create(model=model, messages=messages, temperature=temp, **extra_kwargs)
        except BadRequestError as exc:
            msg = str(exc).lower()
            if images_b64 and "image" in msg and ("not support" in msg or "unsupported" in msg):
                sys.stderr.write(
                    f"[llm_action_generator] vLLM model '{model}' rejected image input; retrying without screenshot.\n"
                )
                last_user = [m for m in messages if m["role"] == "user"][-1]
                last_user["content"] = [c for c in last_user["content"] if c.get("type") == "text"]
                return client.chat.completions.create(model=model, messages=messages, temperature=temp, **extra_kwargs)
            raise

    resp = retry_with_backoff(_call)
    _log_qwen_cu_usage(getattr(resp, "usage", None), model, label="vLLM")
    content = (resp.choices[0].message.content or "").strip()
    try:
        return extract_json(content), content
    except Exception as exc:
        raise ValueError(f"vLLM response is not valid JSON: {exc}\nRaw: {content}") from exc


def call_llm(prompt: str, provider: str, model: str, images_b64: Optional[List[str]],
             *, conversation: Optional[List[Dict[str, Any]]] = None) -> Tuple[Any, str]:
    """Call the LLM and return ``(parsed_json, raw_response_text)``.

    Works with any model via the Chat Completions API, including CUA-capable
    models like gpt-5.4 / gpt-5.4-mini (which also support Chat Completions
    for non-computer-use tasks such as evaluation).
    """
    provider = normalize_provider(provider)
    if provider == "openai":
        return call_openai(prompt, model, images_b64, conversation=conversation)
    if provider == "gemini":
        return call_gemini(prompt, model, images_b64, conversation=conversation)
    if provider == "anthropic":
        return call_anthropic(prompt, model, images_b64, conversation=conversation)
    if provider == "vllm":
        return call_vllm(prompt, model, images_b64, conversation=conversation)
    raise SystemExit(f"Unsupported LLM_PROVIDER: {provider} (supported: openai|gemini|anthropic|vllm)")


# ---------------------------------------------------------------------------
# In-process entry points (avoids subprocess overhead per LLM call).
# ---------------------------------------------------------------------------

def generate_actions_inprocess(
    payload: Dict[str, Any],
    *,
    stuck_hint: Optional[str] = None,
    observation_history: Optional[List[Dict[str, Any]]] = None,
    vision_only: bool = False,
    xml_agent: bool = False,
    xml_no_screenshot: bool = False,
    xml_include_hidden: bool = True,
    app_manifest: Optional[Dict[str, Dict[str, str]]] = None,
    conversation: Optional[List[Dict[str, Any]]] = None,
) -> Tuple[List[Dict[str, Any]], Optional[str], Any, str, List[Dict[str, Any]]]:
    """Generate actions using multi-turn conversation state.

    On the first call (conversation=None), builds the system prompt and first
    user turn with task context.  On subsequent calls, appends a step turn
    with only the current screenshot.

    When *xml_agent* is True, every turn includes the cleaned UI accessibility
    tree from the current observation's ``ui.xml``.

    When *xml_no_screenshot* is True (only meaningful with *xml_agent*),
    screenshots are suppressed even for vision-capable models (text-only mode).

    When *xml_include_hidden* is True, non-visible elements are included in the
    accessibility tree.

    Returns ``(actions_list, reasoning_or_none, raw_parsed, raw_response_text, conversation)``.
    """
    window_size = None
    history = payload.get("history") or []
    if history:
        last = history[-1]
        if isinstance(last, dict) and "window_size" in last:
            window_size = last.get("window_size")
    screenshot_path = (payload.get("observation") or {}).get("screenshot")
    img_size = get_image_size(screenshot_path) if screenshot_path else None
    provider = normalize_provider(os.getenv("LLM_PROVIDER", "openai"))
    default_model = _DEFAULT_MODELS.get(provider, "gpt-5.4")
    model = os.getenv("LLM_MODEL", default_model)
    image_b64 = None
    if screenshot_path and model_supports_image(provider, model):
        if xml_agent and xml_no_screenshot:
            pass  # text-only XML mode: suppress screenshot even if model supports it
        else:
            image_b64 = encode_image(screenshot_path)

    # Build or extend the multi-turn conversation.
    if conversation is None:
        # First turn: system prompt + task context.
        sys_prompt = build_system_prompt(vision_only=vision_only, xml_agent=xml_agent,
                                         xml_no_screenshot=xml_no_screenshot)
        first_text = build_first_turn(payload, img_size, window_size,
                                      vision_only=vision_only, xml_agent=xml_agent,
                                      xml_include_hidden=xml_include_hidden,
                                      app_manifest=app_manifest)
        conversation = [
            {"role": "system", "text": sys_prompt},
            {"role": "user", "text": first_text, "images": [image_b64] if image_b64 else []},
        ]
    else:
        # Subsequent turns: step context + screenshot.
        observation = payload.get("observation", {})
        step = payload.get("step", 1)
        step_text = build_step_turn(
            observation, step, window_size,
            stuck_hint=stuck_hint,
            last_action_error=payload.get("last_action_error"),
            vision_only=vision_only,
            xml_agent=xml_agent,
            xml_include_hidden=xml_include_hidden,
        )
        conversation.append(
            {"role": "user", "text": step_text, "images": [image_b64] if image_b64 else []}
        )

    parsed, raw_text = call_llm("", provider, model, None, conversation=conversation)

    # Append assistant response to conversation history.
    conversation.append({"role": "assistant", "text": raw_text})

    # Normalise to (actions, reasoning, raw, raw_text, conversation).
    if isinstance(parsed, list):
        return parsed, None, parsed, raw_text, conversation
    if isinstance(parsed, dict):
        actions = parsed.get("actions", [])
        if not isinstance(actions, list):
            raise RuntimeError("LLM returned non-list actions")
        return actions, parsed.get("summary") or parsed.get("reasoning"), parsed, raw_text, conversation
    raise RuntimeError("LLM returned unsupported JSON type; expected object with 'actions'.")


def generate_actions_cua(
    payload: Dict[str, Any],
    *,
    cua_state: Optional[Dict[str, Any]] = None,
    xml_agent: bool = False,
    xml_include_hidden: bool = True,
    app_manifest: Optional[Dict[str, Dict[str, str]]] = None,
) -> Tuple[List[Dict[str, Any]], Optional[str], Any, str, Dict[str, Any]]:
    """Generate actions using OpenAI CUA (Responses API).

    Returns ``(actions, reasoning, raw_parsed, raw_text, cua_state)``.

    *cua_state* is a dict carrying ``response_id``, ``call_id``,
    ``display_width``, ``display_height``, and ``pending_safety_checks``
    across turns.  Pass ``None`` on the first call.
    """
    model = os.getenv("LLM_MODEL", "gpt-5.4")
    screenshot_path = (payload.get("observation") or {}).get("screenshot")

    # Determine display dimensions from the screenshot (pixel space).
    # CUA returns coordinates in the pixel space of the image it actually
    # receives.  If CUA_MAX_IMAGE_DIM is set, the image is resized before
    # sending, so we must use the *post-resize* dimensions for normalisation.
    # NOTE: This may differ from Claude CU dimensions (which use
    # CLAUDE_CU_MAX_IMAGE_DIM).  Each provider's coordinates are relative
    # to the image it receives, so different resize caps are correct.
    img_size = get_image_size(screenshot_path) if screenshot_path else None
    if img_size:
        w, h = img_size
        if _CUA_MAX_IMAGE_DIM > 0 and (w > _CUA_MAX_IMAGE_DIM or h > _CUA_MAX_IMAGE_DIM):
            ratio = min(_CUA_MAX_IMAGE_DIM / w, _CUA_MAX_IMAGE_DIM / h)
            display_width = int(w * ratio)
            display_height = int(h * ratio)
        else:
            display_width, display_height = img_size
    elif cua_state:
        display_width = cua_state.get("display_width", 393)
        display_height = cua_state.get("display_height", 852)
    else:
        display_width, display_height = 393, 852

    screenshot_b64 = encode_image_for_cua(screenshot_path) if screenshot_path else None

    # Build task description for the first turn.
    task = payload.get("task") if isinstance(payload.get("task"), dict) else {}
    goal = payload.get("goal") or task.get("goal") or ""
    task_name = task.get("name") or task.get("id") or ""
    task_description = f"Task: {task_name}. Goal: {goal}" if task_name else goal

    # Append bundle IDs so CUA models know how to open apps directly.
    if app_manifest:
        task_apps = task.get("apps") or []
        app_lines = []
        for app_name in task_apps:
            entry = app_manifest.get(app_name)
            if entry and entry.get("bundle_id"):
                app_lines.append(f"  {app_name}: {entry['bundle_id']}")
        if app_lines:
            task_description += "\nInstalled apps (bundle IDs):\n" + "\n".join(app_lines)

    # Build XML accessibility tree if xml_agent mode is active.
    # Output coordinates in CUA's pixel space so the model can use
    # tree coordinates directly as click targets.
    xml_tree: Optional[str] = None
    if xml_agent:
        source_path = (payload.get("observation") or {}).get("source")
        if source_path:
            xml_tree = build_cleaned_accessibility_tree(
                source_path,
                output_width=display_width,
                output_height=display_height,
                include_hidden=xml_include_hidden,
            )

    result = call_openai_cua(
        task_description=task_description,
        screenshot_b64=screenshot_b64,
        model=model,
        previous_response_id=cua_state.get("response_id") if cua_state else None,
        last_call_id=cua_state.get("call_id") if cua_state else None,
        pending_safety_checks=cua_state.get("pending_safety_checks") if cua_state else None,
        display_width=display_width,
        display_height=display_height,
        xml_tree=xml_tree,
        xml_agent=xml_agent,
        last_action_error=payload.get("last_action_error"),
    )

    new_state: Dict[str, Any] = {
        "response_id": result["response_id"],
        "call_id": result["call_id"],
        "display_width": display_width,
        "display_height": display_height,
        "pending_safety_checks": result.get("pending_safety_checks"),
        "done": result["done"],
    }

    actions = result["actions"]
    # Prefer reasoning summary; fall back to text_output (message content).
    reasoning = result.get("reasoning") or result.get("text_output")
    raw_parsed = {
        "cua_actions": result["cua_actions"], "translated_actions": actions,
        "done": result["done"], "reasoning": reasoning,
        "request_log": result.get("request_log"),
        "usage": result.get("usage"),
    }
    raw_text = json.dumps(raw_parsed)

    return actions, reasoning, raw_parsed, raw_text, new_state


def generate_actions_claude_cu(
    payload: Dict[str, Any],
    *,
    cu_state: Optional[Dict[str, Any]] = None,
    xml_agent: bool = False,
    xml_include_hidden: bool = True,
    app_manifest: Optional[Dict[str, Dict[str, str]]] = None,
) -> Tuple[List[Dict[str, Any]], Optional[str], Any, str, Dict[str, Any]]:
    """Generate actions using Claude Computer Use (Messages API).

    Returns ``(actions, reasoning, raw_parsed, raw_text, cu_state)``.

    *cu_state* carries ``conversation``, ``tool_use_ids`` (list),
    ``display_width``, ``display_height``, and ``done`` across turns.
    Pass ``None`` on the first call.
    """
    model = os.getenv("LLM_MODEL", "claude-sonnet-4-6")
    screenshot_path = (payload.get("observation") or {}).get("screenshot")

    # Determine display dimensions from the screenshot (first call)
    # or reuse from state (subsequent calls).
    if screenshot_path and (cu_state is None or "display_width" not in cu_state):
        display_width, display_height = get_claude_cu_display_dims(screenshot_path)
    elif cu_state:
        display_width = cu_state.get("display_width", 1280)
        display_height = cu_state.get("display_height", 800)
    else:
        display_width, display_height = 1280, 800

    screenshot_b64 = encode_image_for_claude_cu(
        screenshot_path, display_width, display_height,
    ) if screenshot_path else None

    # Build task description for the first turn.
    task = payload.get("task") if isinstance(payload.get("task"), dict) else {}
    goal = payload.get("goal") or task.get("goal") or ""
    task_name = task.get("name") or task.get("id") or ""
    task_description = f"Task: {task_name}. Goal: {goal}" if task_name else goal

    # Append bundle IDs so Claude CU models know how to open apps directly.
    if app_manifest:
        task_apps = task.get("apps") or []
        app_lines = []
        for app_name in task_apps:
            entry = app_manifest.get(app_name)
            if entry and entry.get("bundle_id"):
                app_lines.append(f"  {app_name}: {entry['bundle_id']}")
        if app_lines:
            task_description += "\nInstalled apps (bundle IDs):\n" + "\n".join(app_lines)

    # Build XML accessibility tree if xml_agent mode is active.
    # Output coordinates in Claude CU's pixel space so the model can
    # use tree coordinates directly as left_click targets.
    xml_tree: Optional[str] = None
    if xml_agent:
        source_path = (payload.get("observation") or {}).get("source")
        if source_path:
            xml_tree = build_cleaned_accessibility_tree(
                source_path,
                output_width=display_width,
                output_height=display_height,
                include_hidden=xml_include_hidden,
            )

    result = call_anthropic_cu(
        task_description=task_description,
        screenshot_b64=screenshot_b64,
        model=model,
        conversation=cu_state.get("conversation") if cu_state else None,
        display_width=display_width,
        display_height=display_height,
        tool_use_ids=cu_state.get("tool_use_ids") if cu_state else None,
        xml_tree=xml_tree,
        xml_agent=xml_agent,
        last_action_error=payload.get("last_action_error"),
    )

    new_state: Dict[str, Any] = {
        "conversation": result["conversation"],
        "tool_use_ids": result["tool_use_ids"],
        "display_width": display_width,
        "display_height": display_height,
        "done": result["done"],
    }

    actions = result["actions"]
    # Prefer thinking summary; fall back to text_output.
    reasoning = result.get("reasoning") or result.get("text_output")
    raw_parsed = {
        "cu_actions": result["cu_actions"],
        "translated_actions": actions,
        "done": result["done"],
        "reasoning": reasoning,
        "request_log": result.get("request_log"),
        "response_log": result.get("response_log"),
    }
    raw_text = json.dumps(raw_parsed)

    return actions, reasoning, raw_parsed, raw_text, new_state


def generate_actions_gemini_cu(
    payload: Dict[str, Any],
    *,
    cu_state: Optional[Dict[str, Any]] = None,
    xml_agent: bool = False,
    xml_include_hidden: bool = True,
    app_manifest: Optional[Dict[str, Dict[str, str]]] = None,
) -> Tuple[List[Dict[str, Any]], Optional[str], Any, str, Dict[str, Any]]:
    """Generate actions using Gemini Computer Use (generateContent API).

    Returns ``(actions, reasoning, raw_parsed, raw_text, cu_state)``.

    *cu_state* carries ``conversation``, ``last_function_calls``,
    and ``done`` across turns.  Pass ``None`` on the first call.
    """
    model = os.getenv("LLM_MODEL", "gemini-3-flash-preview")
    screenshot_path = (payload.get("observation") or {}).get("screenshot")

    screenshot_b64 = encode_image_for_gemini_cu(screenshot_path) if screenshot_path else None

    # Build task description for the first turn.
    task = payload.get("task") if isinstance(payload.get("task"), dict) else {}
    goal = payload.get("goal") or task.get("goal") or ""
    task_name = task.get("name") or task.get("id") or ""
    task_description = f"Task: {task_name}. Goal: {goal}" if task_name else goal

    # Append bundle IDs so Gemini CU models know how to open apps.
    if app_manifest:
        task_apps = task.get("apps") or []
        app_lines = []
        for app_name in task_apps:
            entry = app_manifest.get(app_name)
            if entry and entry.get("bundle_id"):
                app_lines.append(f"  {app_name}: {entry['bundle_id']}")
        if app_lines:
            task_description += "\nInstalled apps (bundle IDs):\n" + "\n".join(app_lines)

    # Build XML accessibility tree if xml_agent mode is active.
    # Gemini CU uses normalised 0-999 coords; output in 0-1000 space
    # (auto-detected native dims handle the input side).
    xml_tree: Optional[str] = None
    if xml_agent:
        source_path = (payload.get("observation") or {}).get("source")
        if source_path:
            xml_tree = build_cleaned_accessibility_tree(
                source_path,
                include_hidden=xml_include_hidden,
            )

    result = call_gemini_cu(
        task_description=task_description,
        screenshot_b64=screenshot_b64,
        model=model,
        conversation=cu_state.get("conversation") if cu_state else None,
        last_function_calls=cu_state.get("last_function_calls") if cu_state else None,
        xml_tree=xml_tree,
        xml_agent=xml_agent,
        last_action_error=payload.get("last_action_error"),
    )

    new_state: Dict[str, Any] = {
        "conversation": result["conversation"],
        "last_function_calls": result["last_function_calls"],
        "done": result["done"],
    }

    actions = result["actions"]
    reasoning = result.get("text_output")
    raw_parsed = {
        "cu_actions": result["cu_actions"],
        "translated_actions": actions,
        "done": result["done"],
        "reasoning": reasoning,
        "request_log": result.get("request_log"),
        "usage": result.get("usage"),
    }
    raw_text = json.dumps(raw_parsed)

    return actions, reasoning, raw_parsed, raw_text, new_state


def generate_actions_qwen_cu(
    payload: Dict[str, Any],
    *,
    cu_state: Optional[Dict[str, Any]] = None,
    xml_agent: bool = False,
    xml_no_screenshot: bool = False,
    xml_include_hidden: bool = True,
    app_manifest: Optional[Dict[str, Dict[str, str]]] = None,
) -> Tuple[List[Dict[str, Any]], Optional[str], Any, str, Dict[str, Any]]:
    """Generate actions using Qwen3-VL Computer Use (vLLM Chat Completions).

    Returns ``(actions, reasoning, raw_parsed, raw_text, cu_state)``.

    *cu_state* carries ``conversation``, ``tool_call_ids``, ``display_width``,
    ``display_height``, and ``done`` across turns. Pass ``None`` on the first
    call.
    """
    model = os.getenv("LLM_MODEL", _DEFAULT_MODELS["vllm"])
    screenshot_path = (payload.get("observation") or {}).get("screenshot")

    if screenshot_path and (cu_state is None or "display_width" not in cu_state):
        display_width, display_height = get_qwen_cu_display_dims(screenshot_path)
    elif cu_state:
        display_width = cu_state.get("display_width", 1280)
        display_height = cu_state.get("display_height", 800)
    else:
        display_width, display_height = 1280, 800

    screenshot_b64 = encode_image_for_qwen_cu(
        screenshot_path, display_width, display_height,
    ) if screenshot_path else None

    # Build task description for the first turn.
    task = payload.get("task") if isinstance(payload.get("task"), dict) else {}
    goal = payload.get("goal") or task.get("goal") or ""
    task_name = task.get("name") or task.get("id") or ""
    task_description = f"Task: {task_name}. Goal: {goal}" if task_name else goal

    if app_manifest:
        task_apps = task.get("apps") or []
        app_lines = []
        for app_name in task_apps:
            entry = app_manifest.get(app_name)
            if entry and entry.get("bundle_id"):
                app_lines.append(f"  {app_name}: {entry['bundle_id']}")
        if app_lines:
            task_description += "\nInstalled apps (bundle IDs):\n" + "\n".join(app_lines)

    # Build XML accessibility tree if xml_agent mode is active. Output the
    # tree's coordinates in Qwen's cookbook 999x999 action grid so the model
    # can use them directly as click targets.
    xml_tree: Optional[str] = None
    if xml_agent:
        source_path = (payload.get("observation") or {}).get("source")
        if source_path:
            xml_tree = build_cleaned_accessibility_tree(
                source_path,
                output_width=_QWEN_CU_GRID,
                output_height=_QWEN_CU_GRID,
                include_hidden=xml_include_hidden,
            )

    result = call_qwen_cu(
        task_description=task_description,
        screenshot_b64=screenshot_b64,
        model=model,
        conversation=cu_state.get("conversation") if cu_state else None,
        task_progress=_build_qwen_task_progress(payload.get("history")),
        display_width=display_width,
        display_height=display_height,
        last_tool_call_ids=cu_state.get("tool_call_ids") if cu_state else None,
        xml_tree=xml_tree,
        xml_agent=xml_agent,
        xml_no_screenshot=xml_no_screenshot,
        last_action_error=payload.get("last_action_error"),
    )

    new_state: Dict[str, Any] = {
        "conversation": result["conversation"],
        "tool_call_ids": result["tool_call_ids"],
        "display_width": display_width,
        "display_height": display_height,
        "done": result["done"],
    }

    actions = result["actions"]
    reasoning = result.get("reasoning") or result.get("text_output")
    raw_parsed = {
        "cu_actions": result["cu_actions"],
        "translated_actions": actions,
        "done": result["done"],
        "reasoning": reasoning,
        "request_log": result.get("request_log"),
        "response_log": result.get("response_log"),
    }
    raw_text = json.dumps(raw_parsed)

    return actions, reasoning, raw_parsed, raw_text, new_state


def evaluate_trajectory(
    goal: str,
    trajectory: List[Dict[str, Any]],
    *,
    agent_answer: Optional[str] = None,
    rubric: Optional[List[Dict[str, Any]]] = None,
    provider: Optional[str] = None,
    model: Optional[str] = None,
) -> Dict[str, Any]:
    """Evaluate whether *goal* was achieved given the full agent trajectory.

    *trajectory* is a list of step dicts, each containing at least:
      - ``screenshot`` (path to the pre-action screenshot for that step, optional)
      - ``action`` (dict or str describing the action taken, optional)
      - ``post_action_screenshot`` (path to the post-action screenshot, optional)

    *agent_answer* is the text the agent provided in its ``stop`` action's
    ``answer`` field, if any.  For question-answering tasks this is the
    agent's final response and should be considered when judging success.

    *rubric* is an optional list of rubric criteria dicts, each with:
      - ``criterion`` (str): description of the criterion

    When a rubric is provided, the judge evaluates each criterion individually
    and the score is the uniform fraction (n_satisfied / n_criteria). Returns::

        {
            "success": bool,
            "score": float,          # n_satisfied / n_criteria, in [0.0, 1.0]
            "reasoning": str,
            "rubric_results": [      # only present when rubric is provided
                {"criterion": str, "satisfied": bool, "reasoning": str},
                ...
            ],
        }
    """
    provider = normalize_provider(os.getenv("EVAL_PROVIDER") or provider or "openai")
    default_model = _DEFAULT_MODELS.get(provider, "gpt-5.4-mini")
    model = model or os.getenv("EVAL_MODEL", "gpt-5.4-mini")
    supports_image = model_supports_image(provider, model)

    # Build per-step trajectory text with one screenshot per step.
    # Each step gets its pre-action screenshot; the final post-action screenshot
    # is appended as an extra image so the judge can see the end state.
    step_lines: List[str] = []
    images_b64: List[str] = []
    img_index = 0

    # Paper-faithful default: attach EVERY per-step screenshot to the judge
    # (the paper's trajectory-judge prompt sends N screenshots, one per step).
    # Setting EVAL_MAX_SCREENSHOTS to a positive integer caps to the LAST N
    # pre-action screenshots when the judge model's context can't hold them
    # all — long vision+XML trajectories (50 steps) can otherwise push a
    # 272K-context judge over the limit. 0 (the default) = no cap, send all.
    # The final post-action screenshot is always attached below regardless.
    _max_ss = int(os.getenv("EVAL_MAX_SCREENSHOTS", "0"))
    _ntraj = len(trajectory)
    if _max_ss <= 0 or _max_ss >= _ntraj:
        _ss_threshold = 0  # attach every screenshot
    else:
        _ss_threshold = _ntraj - _max_ss
    _dropped_ss = 0
    # Paper-faithful default: no per-step text truncation. Setting
    # EVAL_TRAJ_CHAR_BUDGET to a positive integer distributes that total
    # char budget across the trajectory's steps and head/tail-truncates any
    # step whose action text exceeds its share — useful only when a long
    # vision+XML run blows the judge model's context. 0 (the default) = no
    # truncation, every step's full action text is sent.
    _traj_char_budget = int(os.getenv("EVAL_TRAJ_CHAR_BUDGET", "0"))
    _per_step_chars = (_traj_char_budget // max(1, _ntraj)) if _traj_char_budget > 0 else 0

    for _pos, entry in enumerate(trajectory):
        step = entry.get("step", "?")
        # Support both new "actions" (list) and legacy "action" (single dict).
        actions = entry.get("actions") or []
        if not actions:
            act = entry.get("action")
            if act:
                actions = [act]
        act_str = json.dumps(actions) if actions else "(no actions)"
        # Optional per-step truncation: only triggers when the caller has
        # opted into EVAL_TRAJ_CHAR_BUDGET to fit a context-pressured judge.
        # Head+tail kept so action + outcome both survive.
        if _per_step_chars > 0 and len(act_str) > _per_step_chars:
            _h = _per_step_chars // 2
            act_str = (act_str[:_h] + f" …[{len(act_str) - _per_step_chars} chars truncated]… "
                       + act_str[-_h:])

        # Attach pre-action screenshot only for the last _max_ss steps.
        ss = entry.get("screenshot")
        if supports_image and ss and _pos >= _ss_threshold:
            b64 = encode_image(ss)
            if b64:
                img_index += 1
                images_b64.append(b64)
                step_lines.append(f"  Step {step}: [Screenshot {img_index} - before actions] Actions: {act_str}")
            else:
                step_lines.append(f"  Step {step}: Actions: {act_str}")
        else:
            if ss and supports_image:
                _dropped_ss += 1
            step_lines.append(f"  Step {step}: Actions: {act_str}")

    if _dropped_ss:
        step_lines.insert(0, f"  [note: {_dropped_ss} earlier-step screenshots omitted to fit judge context; "
                             f"action text retained for all steps; last {_max_ss} steps + final state shown visually]")

    # Attach the final post-action screenshot (end state after last action).
    if trajectory:
        final_post_ss = trajectory[-1].get("post_action_screenshot")
        if supports_image and final_post_ss:
            b64 = encode_image(final_post_ss)
            if b64:
                img_index += 1
                images_b64.append(b64)
                step_lines.append(f"  [Screenshot {img_index} - final state after all actions]")

    # ── Build prompt ──────────────────────────────────────────────────
    parts = [
        f"Goal: {goal}",
        "",
        "You are evaluating whether an iOS agent successfully completed the above goal.",
        f"The agent executed {len(step_lines)} steps. Full trajectory with per-step screenshots:",
        *(step_lines if step_lines else ["  (no steps recorded)"]),
        "",
    ]
    if agent_answer:
        parts.append(f'The agent\'s final answer was: "{agent_answer}"')

    if images_b64:
        parts.append(
            f"{len(images_b64)} screenshots are attached, one per step showing the screen "
            "state before each action, plus one final screenshot showing the end state. "
            "Each screenshot is labeled in the trajectory above."
        )
    else:
        parts.append("No screenshots are available.")

    if rubric:
        parts.append("")
        parts.append("Evaluate each of the following rubric criteria individually:")
        for i, r in enumerate(rubric, 1):
            parts.append(f"  {i}. {r['criterion']}")
        parts.append("")
        parts.append(
            "Respond with ONLY a JSON object (no code fences) in this format:\n"
            "{\n"
            '  "success": true/false,\n'
            '  "reasoning": "overall assessment of whether the task was completed",\n'
            '  "rubric_results": [\n'
            '    {"criterion": "<criterion text>", "satisfied": true/false, "reasoning": "<why>"},\n'
            "    ...\n"
            "  ]\n"
            "}\n"
            "success=true means the goal is fully and completely achieved. "
            "For each rubric criterion, set satisfied=true only if there is clear evidence "
            "in the trajectory and screenshots that the criterion was met. "
            "For tasks that ask a question, evaluate whether the agent's final answer is correct."
        )
    else:
        parts.append(
            'Respond with ONLY a JSON object: {"success": true/false, "reasoning": "..."}. '
            "success=true means the goal is fully and completely achieved, false means it is not "
            "(even if partial progress was made). "
            "For tasks that ask a question, evaluate whether the agent's final answer is correct. No code fences."
        )

    prompt = "\n".join(parts)
    # Use a higher token limit for evaluation to avoid truncated JSON responses.
    # Rubric evaluations with many criteria can exceed the default 2048 limit.
    _orig_max_tokens = os.environ.get("LLM_MAX_TOKENS")
    os.environ["LLM_MAX_TOKENS"] = str(max(4096, env_int("EVAL_MAX_TOKENS", 4096)))
    try:
        parsed, _raw_text = call_llm(prompt, provider, model, images_b64 or None)
    finally:
        if _orig_max_tokens is None:
            os.environ.pop("LLM_MAX_TOKENS", None)
        else:
            os.environ["LLM_MAX_TOKENS"] = _orig_max_tokens

    if isinstance(parsed, dict):
        success = bool(parsed.get("success", False))

        if rubric:
            # Uniform rubric scoring: score = (criteria satisfied) / (total criteria).
            rubric_results = parsed.get("rubric_results", [])
            n_criteria = len(rubric)
            n_satisfied = 0
            enriched_results = []
            for rr in rubric_results:
                satisfied = bool(rr.get("satisfied", False))
                if satisfied:
                    n_satisfied += 1
                enriched_results.append({
                    "criterion": rr.get("criterion", ""),
                    "satisfied": satisfied,
                    "reasoning": rr.get("reasoning", ""),
                })
            score = n_satisfied / n_criteria if n_criteria else 0.0
            return {
                "success": success,
                "score": round(score, 4),
                "reasoning": parsed.get("reasoning", ""),
                "rubric_results": enriched_results,
            }
        else:
            return {
                "success": success,
                "score": 1 if success else 0,
                "reasoning": parsed.get("reasoning", ""),
            }
    return {"success": False, "score": 0, "reasoning": f"Unexpected evaluation response: {parsed}"}


# ---------------------------------------------------------------------------
# CLI entry point (stdin/stdout mode, kept for backwards compatibility).
# ---------------------------------------------------------------------------

def main():
    payload = load_payload()
    vision_only = bool(payload.get("vision_only"))
    stuck_hint = payload.get("stuck_hint")
    observation_history = payload.get("observation_history")
    actions, reasoning, _raw_parsed, _raw_text, _conv = generate_actions_inprocess(
        payload,
        stuck_hint=stuck_hint,
        observation_history=observation_history,
        vision_only=vision_only,
    )
    out = {"actions": actions, "summary": reasoning}
    sys.stdout.write(json.dumps(out))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
