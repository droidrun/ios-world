"""Shared metadata, validation, and logging helpers for iOSWorld MCP tools.

The per-app MCP modules intentionally expose app-level primitives. This module
keeps the cross-cutting Vision+Tools policy in one place so every tool can be
audited and every call can be logged without hand-editing 26 app modules.
"""
from __future__ import annotations

import inspect
import json
import os
import pathlib
import threading
import time
import typing
import uuid
from typing import Any, Callable, Mapping, Optional


ROOT = pathlib.Path(__file__).resolve().parents[1]
LOG_PATH = ROOT / "artifacts" / "mcp_tool_calls.jsonl"


# ---------------------------------------------------------------------------
# Scalar argument coercion
#
# Agents and some MCP clients frequently double-encode scalar arguments, so the
# value for e.g. ``calories`` arrives as the 5-character string ``"100"`` (with
# literal double-quote characters), or numbers/bools arrive as plain strings
# ("100", "True"). Handlers that do ``int(value)`` or expect a real bool then
# fail. These helpers normalise such inputs against each tool's *declared*
# parameter types, conservatively: already-correct values pass through
# unchanged, and anything that can't be coerced cleanly is returned untouched
# so the handler can still raise its own domain error.
#
# The central dispatch point that applies this is
# simulator_base._wrap_tool_callable (the monkey-patched FastMCP.tool), so all
# 26 apps get robust scalar handling for free. Per-app code may also call
# coerce_value() directly for a single argument.
# ---------------------------------------------------------------------------

_TRUE_TOKENS = {"true", "1", "yes", "on", "y", "t"}
_FALSE_TOKENS = {"false", "0", "no", "off", "n", "f", "none", "null"}


def unwrap_json_string(value: str) -> str:
    """If *value* is a JSON-encoded *string* scalar, return the inner string.

    ``'"100"'`` -> ``'100'``, ``'"Banana"'`` -> ``'Banana'``. Only unwraps one
    layer and only when the decoded value is itself a string, so a real JSON
    object/array payload is left intact. Plain strings (``Banana``) are
    returned unchanged.
    """
    if not isinstance(value, str):
        return value
    s = value.strip()
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        try:
            decoded = json.loads(s)
        except Exception:
            return value
        if isinstance(decoded, str):
            return decoded
    return value


def _coerce_bool(value: Any) -> Any:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        token = unwrap_json_string(value).strip().lower()
        if token in _TRUE_TOKENS:
            return True
        if token in _FALSE_TOKENS:
            return False
    return value  # leave untouched; let the handler decide


def _strip_optional(annotation: Any) -> Any:
    """Reduce ``Optional[T]`` / ``Union[T, None]`` to ``T`` when possible."""
    origin = typing.get_origin(annotation)
    if origin is typing.Union:
        args = [a for a in typing.get_args(annotation) if a is not type(None)]
        if len(args) == 1:
            return args[0]
    return annotation


def coerce_value(value: Any, annotation: Any = None) -> Any:
    """Coerce *value* toward *annotation* (a type), conservatively.

    Repairs the two common upstream encoding glitches:
      * JSON-double-encoded scalars:  '"100"' -> 100, '"Banana"' -> 'Banana'
      * numbers / bools that arrived as plain strings: "100" -> 100, "True"

    With no annotation (or ``None``/empty), only the unambiguous
    double-encoded-string case is fixed. ``bool`` is handled before ``int``
    since ``bool`` is a subclass of ``int``. Values that cannot be coerced
    cleanly are returned unchanged.
    """
    if annotation is inspect.Parameter.empty or annotation is None:
        return unwrap_json_string(value) if isinstance(value, str) else value

    target = _strip_optional(annotation)

    if target is bool:
        return _coerce_bool(value)

    if target is int:
        if isinstance(value, bool) or isinstance(value, int):
            return value
        if isinstance(value, float):
            return int(value) if value.is_integer() else value
        if isinstance(value, str):
            s = unwrap_json_string(value).strip()
            # Don't let Python's int() reinterpret separator syntax like
            # "1_000" (-> 1000); only coerce plain numeric strings.
            if "_" in s:
                return value
            try:
                return int(s)
            except (TypeError, ValueError):
                try:
                    f = float(s)
                    return int(f) if f.is_integer() else value
                except (TypeError, ValueError):
                    return value
        return value

    if target is float:
        if isinstance(value, bool):
            return value
        if isinstance(value, (int, float)):
            return float(value)
        if isinstance(value, str):
            s = unwrap_json_string(value).strip()
            try:
                return float(s)
            except (TypeError, ValueError):
                return value
        return value

    if target is str:
        return unwrap_json_string(value) if isinstance(value, str) else value

    origin = typing.get_origin(target)
    if target in (dict, list) or origin in (dict, list):
        if isinstance(value, (dict, list)):
            return value
        if isinstance(value, str):
            try:
                decoded = json.loads(value.strip())
            except Exception:
                return value
            # Tolerate a double-encoded payload: '"{...}"' -> '{...}' -> obj.
            if isinstance(decoded, str):
                try:
                    decoded = json.loads(decoded)
                except Exception:
                    return value
            # Only accept an actual container. A string that decodes to a scalar
            # (e.g. '"42"' -> 42) is not a dict/list — leave the value untouched.
            return decoded if isinstance(decoded, (dict, list)) else value
        return value

    # Unknown annotation: only fix the double-encoded-string case.
    return unwrap_json_string(value) if isinstance(value, str) else value


def coerce_kwargs_for(fn: Callable, kwargs: Mapping[str, Any]) -> dict:
    """Return *kwargs* with each value coerced to ``fn``'s declared param type.

    Used by simulator_base._wrap_tool_callable so every registered tool gets
    robust scalar handling. Unknown / untyped kwargs only get
    double-encoded-string repair. Never raises — on any failure the original
    value is kept.
    """
    try:
        hints = typing.get_type_hints(fn)
    except Exception:
        hints = getattr(fn, "__annotations__", {}) or {}
    try:
        params = inspect.signature(fn).parameters
    except (TypeError, ValueError):
        params = {}
    out: dict = {}
    for key, val in dict(kwargs).items():
        if key in hints:
            ann = hints[key]
        elif key in params:
            ann = params[key].annotation
        else:
            ann = None
        try:
            out[key] = coerce_value(val, ann)
        except Exception:
            out[key] = val
    return out


def active_bundle_id(sim) -> Optional[str]:
    """Return the simulator foreground bundle id when Appium exposes it."""
    try:
        driver = sim.connect()
        info = driver.execute_script("mobile: activeAppInfo")
    except Exception:
        return None
    if isinstance(info, dict):
        bundle = info.get("bundleId")
        if isinstance(bundle, str) and bundle:
            return bundle
    return None


def observe_app_scoped(sim, *, bundle_id: str, app_name: str, markers: tuple[str, ...] = ()):
    """Observe only the requested app, never a stale foreground app tree.

    Many multi-app trajectories call app-specific ``observe`` tools after a
    different app was launched. Plain ``observe_text`` then returns the wrong
    app with ``ok:true``. This helper foregrounds ``bundle_id`` when needed and
    returns a controlled ``ok:false`` mismatch if the target cannot be verified.
    """
    active = active_bundle_id(sim)
    if active and active != bundle_id:
        try:
            sim.launch_app(bundle_id)
            sim.wait(0.8)
        except Exception:
            pass
        active = active_bundle_id(sim)
        if active and active != bundle_id:
            return {
                "ok": False,
                "error": "app-mismatch",
                "expected_bundle": bundle_id,
                "actual_bundle": active,
                "message": f"{app_name} is not the foreground app; observe() did not return another app's UI tree.",
            }

    tree = sim.observe_text() or ""
    if active == bundle_id or f'bundleId="{bundle_id}"' in tree or any(m in tree for m in markers):
        return tree
    return {
        "ok": False,
        "error": "app-mismatch",
        "expected_bundle": bundle_id,
        "actual_bundle": active_bundle_id(sim),
        "message": f"Could not verify {app_name} as the foreground app; observe() did not return an unscoped UI tree.",
    }


READ_PREFIXES = (
    "launch", "observe", "read_", "list_", "view_", "open_", "current_",
    "search_", "filter_", "navigate_", "browse_", "get_", "check_",
    "track_", "recenter_", "refresh_", "close_", "go_back",
)

RISKY_PREFIXES = (
    "confirm_", "checkout", "send_", "pay_", "transfer_", "buy_",
    "request_payment", "send_payment", "send_zelle", "make_reservation",
    "reserve_", "check_in", "cancel_order", "return_or_replace",
    "dispute_", "redeem_", "bulk_delete", "trash_", "delete_",
)

# A tool whose name starts with one of these prefixes is the non-committing half
# of a `prepare_<verb>` / `confirm_<verb>` pair. It navigates the UI, fills
# fields, captures a structured preview, and stores it in the draft store
# (see create_draft below). It MUST NOT commit. Classified as reversible_write
# so the safety tier reflects "the UI was touched but no commit happened".
PREPARE_PREFIXES = ("prepare_", "draft_")
CONFIRM_PREFIXES = ("confirm_",)

WRITE_PREFIXES = (
    "add_", "adjust_", "append_", "apply_", "attach_", "bulk_",
    "cancel_", "comment_", "compose", "create_", "duplicate_", "edit_",
    "favorite_", "file_action", "give_", "join_", "log_", "make_",
    "like_", "dismiss_", "mark_", "message_", "move_", "mute_", "post_", "publish_", "quick_log_",
    "prepare_", "draft_",
    "rate_", "react_", "rebook_", "remove_", "rename_", "reply_", "reset_",
    "restore_", "save_", "schedule_", "select_", "set_", "share_", "star_",
    "start_", "stop_", "pause_", "stopwatch_", "toggle_", "wishlist_",
)

LEAKY_NAME_PATTERNS = (
    "answer_task",
    "summarize_my_finances",
    "find_most_common_route",
    "infer_favorite_restaurant",
    "compare_receipt_and_charge",
)


def side_effect_type(tool_name: str) -> str:
    """Return the Vision+Tools side-effect tier for a tool name."""
    if tool_name.startswith(RISKY_PREFIXES) or tool_name in {"checkout", "mark_seen"}:
        return "risky_action"
    if tool_name.startswith(WRITE_PREFIXES):
        return "reversible_write"
    if tool_name.startswith(READ_PREFIXES):
        return "read"
    return "read"


def requires_confirmation(tool_name: str) -> bool:
    """Whether this tool is the confirmation step or should be guarded."""
    return side_effect_type(tool_name) == "risky_action"


def validator_hook(tool_name: str) -> str:
    """Name the validator hook expected for a tool."""
    effect = side_effect_type(tool_name)
    if effect == "read":
        return "validate_read_result"
    if effect == "risky_action":
        return f"validate_{tool_name}_confirmed"
    return f"validate_{tool_name}_state"


def expected_failure_modes(tool_name: str, required_args: list[str] | tuple[str, ...]) -> list[str]:
    modes = []
    if required_args:
        modes.append("missing required argument")
        modes.append("unknown or invalid target identifier")
    if side_effect_type(tool_name) != "read":
        modes.append("validator cannot find expected post-state")
    if requires_confirmation(tool_name):
        modes.append("confirmation state missing or expired")
    modes.append("simulator/app state unavailable")
    return modes


def has_leaky_name(tool_name: str) -> bool:
    lower = tool_name.lower()
    return any(pattern in lower for pattern in LEAKY_NAME_PATTERNS)


# ---------------------------------------------------------------------------
# prepare_*/confirm_* pair helpers
#
# A risky action splits into two registry tools:
#   prepare_<verb>(args) → returns {ok, draft_id, action, summary, ...}
#       navigates UI, fills fields, captures preview, but does NOT commit.
#   confirm_<verb>(draft_id) → returns {ok, action, evidence}
#       commits the draft.
#
# Scaffolding here is forward-looking: today the codebase still uses
# single-verb risky tools (send_zelle, checkout, …). Step 3 of the
# verification plan migrates them; this module gives them the draft store
# and pair-invariant validation they need without touching app modules.
# ---------------------------------------------------------------------------

_DRAFT_TTL_SECONDS = int(os.environ.get("IOSWORLD_DRAFT_TTL_SECONDS", "600"))
_DRAFT_LOCK = threading.Lock()
_DRAFT_STORE: dict[str, dict[str, Any]] = {}

# File-backed mirror of the draft store so a draft minted by ``prepare_<verb>``
# survives to a ``confirm_<verb>`` call made from a *different process* (e.g. a
# fresh MCP client per call, or a reviewer copy-pasting the draft_id into a
# separate confirm invocation). In a single persistent server the in-memory
# dict already suffices; the files make the prepare→confirm contract hold for
# every invocation pattern. Draft ids are uuids so cross-task collision is nil;
# expired files are purged on access.
_DRAFT_DIR_ENV = os.environ.get("IOSWORLD_DRAFT_DIR", "").strip()
# NOTE: pathlib.Path("") == Path(".") which is *truthy*, so `Path(env) or default`
# would never fall through — guard on the raw env string instead.
_DRAFT_DIR = pathlib.Path(_DRAFT_DIR_ENV) if _DRAFT_DIR_ENV else (ROOT / "artifacts" / "drafts")


def _draft_file(draft_id: str) -> pathlib.Path:
    # draft_id is "{app}.{verb}.{uuid}"; keep it filesystem-safe.
    safe = draft_id.replace("/", "_")
    return _DRAFT_DIR / f"{safe}.json"


def _write_draft_file(draft_id: str, entry: dict) -> None:
    try:
        _DRAFT_DIR.mkdir(parents=True, exist_ok=True)
        final = _draft_file(draft_id)
        # Write to a temp file then atomically rename, so a concurrent reader
        # in another process never sees a truncated/partial JSON document.
        tmp = final.with_suffix(f".{os.getpid()}.{uuid.uuid4().hex}.tmp")
        tmp.write_text(json.dumps(entry, default=str))
        os.replace(tmp, final)
    except Exception:
        pass  # in-memory store still works; file is best-effort robustness


def _read_draft_file(draft_id: str) -> Optional[dict]:
    try:
        p = _draft_file(draft_id)
        if not p.exists():
            return None
        entry = json.loads(p.read_text())
        if (time.time() - float(entry.get("created_at", 0))) > _DRAFT_TTL_SECONDS:
            p.unlink(missing_ok=True)
            return None
        return entry
    except Exception:
        return None


def _delete_draft_file(draft_id: str) -> None:
    try:
        _draft_file(draft_id).unlink(missing_ok=True)
    except Exception:
        pass


def _claim_draft_file(draft_id: str) -> Optional[dict]:
    """Atomically take ownership of a draft file and return its entry.

    Renames the file to a unique name first: ``os.replace`` is atomic, so if two
    processes race to consume the same draft only one rename succeeds — the other
    gets FileNotFoundError and returns None. Prevents a confirm-once draft from
    being consumed twice (e.g. double-executing a risky action) across processes.
    """
    src = _draft_file(draft_id)
    claimed = src.with_suffix(f".claimed.{os.getpid()}.{uuid.uuid4().hex}")
    try:
        os.replace(src, claimed)  # atomic claim; raises if already taken/absent
    except Exception:
        return None
    try:
        entry = json.loads(claimed.read_text())
        if (time.time() - float(entry.get("created_at", 0))) > _DRAFT_TTL_SECONDS:
            return None
        return entry
    except Exception:
        return None
    finally:
        try:
            claimed.unlink(missing_ok=True)
        except Exception:
            pass


def _purge_expired_draft_files() -> None:
    try:
        now = time.time()
        for p in _DRAFT_DIR.glob("*.json"):
            try:
                if (now - float(json.loads(p.read_text()).get("created_at", 0))) > _DRAFT_TTL_SECONDS:
                    p.unlink(missing_ok=True)
            except Exception:
                p.unlink(missing_ok=True)
    except Exception:
        pass


def _draft_verb(tool_name: str) -> str:
    """Extract the action verb from `prepare_<verb>` / `confirm_<verb>` / `draft_<verb>`."""
    for prefix in PREPARE_PREFIXES + CONFIRM_PREFIXES:
        if tool_name.startswith(prefix) and len(tool_name) > len(prefix):
            return tool_name[len(prefix):]
    return ""


def pair_for(tool_name: str) -> Optional[str]:
    """If `tool_name` is one half of a pair, return the canonical name of its other half.

    `prepare_send_zelle` → `confirm_send_zelle`; `confirm_send_zelle` → `prepare_send_zelle`.
    `draft_*` is treated as an alias of `prepare_*`. Returns None for non-pair tools.
    """
    verb = _draft_verb(tool_name)
    if not verb:
        return None
    if tool_name.startswith(PREPARE_PREFIXES):
        return f"confirm_{verb}"
    if tool_name.startswith(CONFIRM_PREFIXES):
        return f"prepare_{verb}"
    return None


def _purge_expired_drafts_locked() -> None:
    now = time.time()
    stale = [k for k, v in _DRAFT_STORE.items() if (now - v.get("created_at", now)) > _DRAFT_TTL_SECONDS]
    for k in stale:
        _DRAFT_STORE.pop(k, None)
    _purge_expired_draft_files()


def create_draft(app: str, verb: str, payload: Mapping[str, Any]) -> str:
    """Store a draft for a prepare_*/confirm_* pair.

    Returns a draft_id of the form ``{app}.{verb}.{uuid}``. The caller (a
    `prepare_<verb>` tool) should return this id in its structured envelope so
    the agent can pass it to the matching `confirm_<verb>` tool.
    """
    draft_id = f"{app}.{verb}.{uuid.uuid4()}"
    entry = {
        "app": app,
        "verb": verb,
        "payload": dict(payload),
        "created_at": time.time(),
    }
    with _DRAFT_LOCK:
        _purge_expired_drafts_locked()
        _DRAFT_STORE[draft_id] = entry
        _write_draft_file(draft_id, entry)
    return draft_id


def peek_draft(draft_id: str) -> Optional[dict[str, Any]]:
    """Return a shallow copy of the draft (or None if absent/expired). Does not remove it."""
    with _DRAFT_LOCK:
        _purge_expired_drafts_locked()
        entry = _DRAFT_STORE.get(draft_id) or _read_draft_file(draft_id)
        if entry and draft_id not in _DRAFT_STORE:
            _DRAFT_STORE[draft_id] = entry  # rehydrate in-memory cache
        return dict(entry) if entry else None


def consume_draft(draft_id: str) -> Optional[dict[str, Any]]:
    """Pop and return a draft after the matching `confirm_<verb>` commits it.

    Returns None if the draft id is absent, already consumed, or expired
    beyond IOSWORLD_DRAFT_TTL_SECONDS. The `confirm_<verb>` tool should
    surface a CONTROLLED_FAILURE precondition response in that case.
    """
    with _DRAFT_LOCK:
        _purge_expired_drafts_locked()
        entry = _DRAFT_STORE.pop(draft_id, None)
        if entry is not None:
            _delete_draft_file(draft_id)
            return entry
        # Not in this process's memory — claim the file atomically so a
        # concurrent confirm in another process can't also consume it.
        return _claim_draft_file(draft_id)


def clear_drafts() -> None:
    """Drop every in-flight draft. Used when the simulator session is reset."""
    with _DRAFT_LOCK:
        _DRAFT_STORE.clear()
        try:
            for p in _DRAFT_DIR.glob("*.json"):
                p.unlink(missing_ok=True)
        except Exception:
            pass


def validate_pair_invariants(
    tools_by_app: Mapping[str, set[str]],
    *,
    strict: bool = False,
) -> list[str]:
    """Check that every `confirm_<verb>` has a matching `prepare_<verb>` per app.

    Returns a list of human-readable messages, one per missing partner. When
    `strict=False` (current default until Step 3f flips it), callers should
    treat the list as warnings; when `strict=True` they should fail the audit.

    Tools that are not part of a pair (no `prepare_*`/`draft_*`/`confirm_*`
    prefix) are ignored. This is the half-migration policy: legacy single-verb
    risky tools (`send_zelle`, `checkout`, …) are not flagged here — they are
    flagged via `RISKY_PREFIXES` and the rudimentary audit.
    """
    messages: list[str] = []
    for app, names in tools_by_app.items():
        local = set(names)
        for name in local:
            partner = pair_for(name)
            if partner and partner not in local:
                messages.append(
                    f"{app}: {name} has no matching {partner}"
                    + ("" if strict else " (warn-only until prepare/confirm migration completes)")
                )
    return messages


def summarize_value(value: Any, *, max_len: int = 240) -> str:
    """Redact long payloads and UI XML from log records."""
    if isinstance(value, Mapping):
        safe = {}
        for key, item in value.items():
            if key in {"ui_xml", "source", "screenshot", "body", "text", "message"}:
                safe[key] = f"<{key}:len={len(str(item))}>"
            else:
                safe[key] = item
        raw = json.dumps(safe, default=str, sort_keys=True)
    else:
        raw = str(value)
    raw = raw.replace("\n", "\\n")
    return raw if len(raw) <= max_len else raw[: max_len - 3] + "..."


def validate_result(tool_name: str, result: Any, error: str | None = None) -> dict[str, Any]:
    """Generic validator for call logging.

    App-specific validators still live in task/rubric checks. This hook records
    whether the tool returned a usable envelope or a clean failure.
    """
    if error:
        return {"ok": False, "hook": validator_hook(tool_name), "message": error[:200]}
    if result is None:
        return {"ok": True, "hook": validator_hook(tool_name), "message": "returned None"}
    if isinstance(result, Mapping):
        if result.get("ok") is False:
            return {
                "ok": False,
                "hook": validator_hook(tool_name),
                "message": summarize_value(result),
            }
        return {"ok": True, "hook": validator_hook(tool_name), "message": "structured result"}
    return {"ok": True, "hook": validator_hook(tool_name), "message": "result returned"}


def log_tool_call(
    *,
    app: str,
    tool_name: str,
    arguments: Mapping[str, Any],
    result: Any = None,
    error: str | None = None,
) -> dict[str, Any]:
    """Append a redacted JSONL tool-call record and return it."""
    effect = side_effect_type(tool_name)
    validator = validate_result(tool_name, result, error)
    confirmation_status = (
        "required" if requires_confirmation(tool_name) and not tool_name.startswith("confirm_")
        else "confirmed" if tool_name.startswith("confirm_") or tool_name == "checkout"
        else "not_required"
    )
    record = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "task_id": os.environ.get("IOSWORLD_TASK_ID"),
        "run_id": os.environ.get("IOSWORLD_RUN_ID"),
        "model_id": os.environ.get("IOSWORLD_MODEL_ID"),
        "condition": os.environ.get("IOSWORLD_CONDITION", "vision_tools"),
        "app": app,
        "tool_name": tool_name,
        "arguments": {key: summarize_value(value, max_len=80) for key, value in dict(arguments).items()},
        "return_value_summary": summarize_value(result),
        "side_effect_type": effect,
        "confirmation_status": confirmation_status,
        "validator_hook": validator["hook"],
        "validator_result": validator,
        "error": error,
    }
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LOG_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, sort_keys=True, default=str) + "\n")
    return record


def tool_schema(app: str, tool_name: str, description: str, inputs: Mapping[str, str]) -> dict[str, Any]:
    """Build the standard documentation schema for one tool."""
    schema: dict[str, Any] = {
        "name": tool_name,
        "app": app,
        "description": description.strip() or f"{tool_name} tool for {app}.",
        "inputs": dict(inputs),
        "outputs": "structured MCP result envelope or app-specific structured data",
        "side_effect_type": side_effect_type(tool_name),
        "requires_confirmation": requires_confirmation(tool_name),
        "validator_hook": validator_hook(tool_name),
        "example_call": {"tool": f"{app}.{tool_name}", "arguments": {key: f"<{key}>" for key in inputs}},
        "expected_failure_modes": expected_failure_modes(tool_name, tuple(inputs)),
    }
    partner = pair_for(tool_name)
    if partner:
        if tool_name.startswith(PREPARE_PREFIXES):
            schema["draft_for"] = partner
        elif tool_name.startswith(CONFIRM_PREFIXES):
            schema["confirm_pair"] = partner
    return schema
