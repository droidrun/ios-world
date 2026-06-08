#!/usr/bin/env python3
"""MCP agent runner for iOS Simulator benchmark tasks (Qwen-only).

MCP mode is the paper's Qwen3.5 + per-app tool-use configuration. The runner
loads FastMCP tool definitions from per-app servers in `mcps/` and dispatches
through vLLM's OpenAI-compatible Chat Completions API. With ``--with-cua`` the
cookbook `mobile_use` tool is added alongside the MCP function tools so the
Qwen3-VL / Qwen3.5 model can fall back to raw pixel click/type when no MCP
tool covers a step. Non-Qwen models are rejected at argument parsing.

Two MCP transports:
  --transport in_memory   FastMCP Client(server) in-process (default; same
                          wire-protocol semantics as stdio, zero IPC cost).
  --transport stdio       Spawns scripts/combined_mcp_server.py as a
                          subprocess and connects via JSON-RPC stdio. Use
                          for true subprocess isolation.

Tools all return real MCP `structuredContent` with the shape
  {"action": ..., "args": ..., "ok": true, "message"|"<custom>": ...}
via the wrapper in mcps/simulator_base.py.

Usage:
    # Single task, in-memory transport
    python scripts/mcp_agent_runner.py \\
        --apps teamchat --task "Send 'hi' in #general" \\
        --model qwen3.5-35B-a3

    # Stdio transport
    python scripts/mcp_agent_runner.py \\
        --apps teamchat --task "..." --transport stdio

    # From a benchmark tasks file
    python scripts/mcp_agent_runner.py \\
        --tasks tasks.json \\
        --task-id teamchat-001 --model qwen3.5-35B-a3

    # Hybrid MCP + Qwen `mobile_use` (paper's qwen35-mcp-cua configuration)
    python scripts/mcp_agent_runner.py --apps teamchat --task "..." \\
        --model qwen3.5-35B-a3 --with-cua

Optional flags:
    --with-screenshots       Include a base64 PNG screenshot in each tool result.
    --with-cua               Add Qwen's cookbook `mobile_use` tool alongside MCP.
    --with-sim-fallback      Include sim_tap_xy / sim_type / sim_swipe primitives.
                             Off by default — adds ~300 tokens per call and is
                             rarely needed when MCP tools cover the task.
    --transport stdio        Use the stdio MCP transport (default: in_memory).

Environment:
    LLM_PROVIDER=vllm        Set explicitly when the model name doesn't include
                             "qwen" so the runner picks the vLLM path.
    VLLM_BASE_URL / VLLM_API_KEY  vLLM endpoint overrides.
    SIMCTL_UDID              iOS Simulator device UDID.
    APPIUM_URL               Appium server (default http://127.0.0.1:4723).
    MCP_STRUCTURED_RETURNS=0 Disable structured-envelope wrapping (legacy
                             string-return mode, for A/B comparison).
"""
from __future__ import annotations

import argparse
import asyncio
import importlib
import importlib.util
import json
import os
import pathlib
import sys
import threading
import time
from contextlib import AsyncExitStack
from typing import Any, Dict, List, Optional, Tuple
import re

# Add paths
_SCRIPTS = pathlib.Path(__file__).resolve().parent
_ROOT = _SCRIPTS.parent
_MCPS = _ROOT / "mcps"
sys.path.insert(0, str(_SCRIPTS))
sys.path.insert(0, str(_MCPS))

NON_APP_MCP_MODULES = {
    "__init__",
    "_data_layer",
    "simulator_base",
    "tool_support",
}

_PROVIDER_TOOL_NAME_RE = re.compile(r"^[A-Za-z0-9_-]{1,64}$")


# ──────────────────────────────────────────────────────────────────────
# Real MCP client pool
#
# Uses FastMCP's in-memory transport (Client(server_instance)) so every
# tool call goes through real MCP protocol semantics: initialize handshake,
# list_tools / call_tool RPCs, Pydantic param validation, exception →
# isError CallToolResult wrapping. We use in-memory rather than stdio
# subprocesses because the iOS Simulator's Appium driver only allows one
# session per device — N independent processes can't drive the same sim
# concurrently. In-memory keeps the SimulatorBridge singleton in one
# process while still going through the real MCP wire format.
# ──────────────────────────────────────────────────────────────────────

class MCPClientPool:
    """Persistent MCP client pool. Two transport modes:

    - in_memory (default): one FastMCP Client per app, all in this process.
        Same wire protocol as stdio (initialize / list_tools / call_tool with
        validation and isError envelopes), but no IPC.
    - stdio: a single subprocess running scripts/combined_mcp_server.py with
        every app mounted under `mcp_<app>` namespace, connected over JSON-RPC
        stdio. This is the canonical MCP-spec transport.

    Both expose the same per-app interface to the runner: `list_tools(app)`,
    `call_tool(app, name, args)`. In stdio mode the per-app split is
    synthesized by parsing the `mcp_<app>_<tool>` prefix.
    """

    def __init__(self, transport: str = "in_memory") -> None:
        self.transport = transport
        self._loop = asyncio.new_event_loop()
        self._thread = threading.Thread(target=self._loop.run_forever, daemon=True)
        self._thread.start()
        self._stack: Optional[AsyncExitStack] = None
        # in_memory: app_name -> fastmcp.Client
        # stdio: special key "__combined__" -> mcp.ClientSession (single)
        self._clients: Dict[str, Any] = {}
        # stdio only: app_name -> [tool names available for this app]
        self._stdio_app_tools: Dict[str, List[Any]] = {}
        self._closed = False

    def _run(self, coro):
        return asyncio.run_coroutine_threadsafe(coro, self._loop).result()

    def start(self, app_names: List[str]) -> List[str]:
        if self.transport == "stdio":
            return self._run(self._aopen_stdio(app_names))
        return self._run(self._aopen_in_memory(app_names))

    async def _aopen_in_memory(self, app_names: List[str]) -> List[str]:
        from fastmcp import Client  # noqa: WPS433
        self._stack = AsyncExitStack()
        await self._stack.__aenter__()
        loaded: List[str] = []
        for app_name in app_names:
            module_path = _MCPS / f"{app_name}.py"
            if not module_path.exists():
                print(f"[mcp] no module for app '{app_name}'", flush=True)
                continue
            try:
                spec = importlib.util.spec_from_file_location(
                    f"mcp_{app_name}", str(module_path),
                )
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)
                server = getattr(mod, "mcp", None)
                if server is None:
                    print(f"[mcp] {app_name}: no `mcp` FastMCP instance", flush=True)
                    continue
                client = Client(server)
                await self._stack.enter_async_context(client)
                self._clients[app_name] = client
                loaded.append(app_name)
            except Exception as e:
                print(f"[mcp] failed to load {app_name}: {e}", flush=True)
        return loaded

    async def _aopen_stdio(self, app_names: List[str]) -> List[str]:
        """Spawn the combined MCP server as a subprocess and connect via stdio."""
        from mcp import ClientSession, StdioServerParameters  # noqa: WPS433
        from mcp.client.stdio import stdio_client  # noqa: WPS433
        self._stack = AsyncExitStack()
        await self._stack.__aenter__()

        server_path = _SCRIPTS / "combined_mcp_server.py"
        # Pass through the parent env so the subprocess sees SIMCTL_UDID,
        # APPIUM_URL, DEVICE_NAME, MCP_PLATFORM_VERSION, MCP_STRUCTURED_RETURNS,
        # and any provider API keys / vLLM overrides. env=None would give the
        # subprocess a sanitized minimal env and the SimulatorBridge inside
        # would fall back to default UDIDs, leading to subtle "wrong simulator"
        # bugs on multi-worker setups.
        params = StdioServerParameters(
            command=sys.executable,
            args=[str(server_path), "--apps", *app_names],
            env=dict(os.environ),
        )
        read, write = await self._stack.enter_async_context(stdio_client(params))
        session: ClientSession = await self._stack.enter_async_context(
            ClientSession(read, write),
        )
        await session.initialize()
        self._clients["__combined__"] = session

        # Discover tools, group by `mcp_<app>_<tool>` prefix and normalize
        # to naked names so load_mcp_tools sees the same shape as in-memory.
        from types import SimpleNamespace  # noqa: WPS433
        tools_resp = await session.list_tools()
        loaded_apps: List[str] = []
        for app_name in app_names:
            prefix = f"mcp_{app_name}_"
            normalized = []
            for t in tools_resp.tools:
                if t.name.startswith(prefix):
                    normalized.append(SimpleNamespace(
                        name=t.name[len(prefix):],
                        description=t.description,
                        inputSchema=t.inputSchema,
                    ))
            if normalized:
                self._stdio_app_tools[app_name] = normalized
                loaded_apps.append(app_name)
            else:
                print(f"[mcp] {app_name}: no tools found in combined server", flush=True)
        return loaded_apps

    def list_tools(self, app_name: str):
        if self.transport == "stdio":
            # Return tools as a list of objects exposing .name/.description/.inputSchema
            return self._stdio_app_tools.get(app_name, [])
        return self._run(self._clients[app_name].list_tools())

    def call_tool(self, app_name: str, tool_name: str, args: Dict[str, Any]):
        if self.transport == "stdio":
            session = self._clients["__combined__"]
            full_name = f"mcp_{app_name}_{tool_name}"
            return self._run(session.call_tool(full_name, args))
        client = self._clients[app_name]
        # call_tool_mcp returns the raw MCP CallToolResult (isError + content +
        # structuredContent), the true wire-protocol shape; call_tool raises on
        # tool errors which loses the protocol envelope.
        if hasattr(client, "call_tool_mcp"):
            return self._run(client.call_tool_mcp(tool_name, args))
        return self._run(client.call_tool(tool_name, args))

    def app_names(self) -> List[str]:
        if self.transport == "stdio":
            return list(self._stdio_app_tools.keys())
        return list(self._clients.keys())

    def close(self) -> None:
        if self._closed:
            return
        self._closed = True

        async def _aclose():
            if self._stack is not None:
                await self._stack.__aexit__(None, None, None)
        try:
            self._run(_aclose())
        except Exception:
            pass
        finally:
            self._loop.call_soon_threadsafe(self._loop.stop)
            self._thread.join(timeout=5)


def _smart_truncate(text: str, limit: int) -> str:
    """Truncate at the last '>' before *limit* so we never leave an
    unclosed XML tag in the model's view. Falls back to a hard cut for
    non-XML content."""
    if text is None or len(text) <= limit:
        return text or ""
    cutoff = text.rfind(">", 0, limit)
    if cutoff <= 0:
        cutoff = limit
    else:
        cutoff += 1
    return text[:cutoff] + "\n... [truncated]"


# Sim fallback tools — low-level CUA-style primitives surfaced alongside the
# MCP tools. Listed AFTER the app tools in load_mcp_tools so the model
# attends to high-level tools first.
_SIM_TOOLS: List[Dict[str, Any]] = [
    {
        "name": "sim_observe",
        "description": "Get the current screen's UI accessibility tree XML. Use this to see what's on screen.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "sim_screenshot",
        "description": "Take a screenshot of the current screen. Returns base64 PNG.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "sim_tap_xy",
        "description": "Tap the screen at normalized (x, y) coordinates (0-1000 scale where 0,0 is top-left).",
        "input_schema": {
            "type": "object",
            "properties": {
                "x": {"type": "integer", "description": "X coordinate (0-1000)"},
                "y": {"type": "integer", "description": "Y coordinate (0-1000)"},
            },
            "required": ["x", "y"],
        },
    },
    {
        "name": "sim_type",
        "description": "Type text into the currently focused input field.",
        "input_schema": {
            "type": "object",
            "properties": {"text": {"type": "string", "description": "Text to type"}},
            "required": ["text"],
        },
    },
    {
        "name": "sim_swipe",
        "description": "Swipe in a direction: up, down, left, or right.",
        "input_schema": {
            "type": "object",
            "properties": {"direction": {"type": "string", "enum": ["up", "down", "left", "right"]}},
            "required": ["direction"],
        },
    },
    {
        "name": "sim_home",
        "description": "Press the home button to return to the home screen.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
]


def _normalize_input_schema(schema: Dict[str, Any]) -> Dict[str, Any]:
    """Return a conservative JSON Schema object for provider tool APIs.

    MCP tools expose `inputSchema` as JSON Schema. Provider APIs accept mostly
    the same shape, but they are less forgiving about absent object wrappers or
    dangling `required` entries. Keep the schema semantic, deterministic, and
    JSON-serializable without altering argument names.
    """
    if not isinstance(schema, dict):
        schema = {}
    normalized = json.loads(json.dumps(schema, default=str))
    if normalized.get("type") is None:
        normalized["type"] = "object"
    if normalized.get("type") == "object":
        props = normalized.get("properties")
        if not isinstance(props, dict):
            props = {}
            normalized["properties"] = props
        required = normalized.get("required") or []
        if not isinstance(required, list):
            required = []
        normalized["required"] = [
            name for name in required
            if isinstance(name, str) and name in props
        ]
    return normalized


def _normalize_description(description: Any) -> str:
    return " ".join(str(description or "").split()).strip()


_VISIBILITY_CONTRACT_NOTE = (
    " PRECONDITION: any ID arg must correspond to an element currently"
    " rendered on screen. IDs returned by `search_*`/`list_*` (without"
    " `_visible_` in the name) come from the data layer and may NOT be"
    " currently rendered. If this tool returns 'not visible', 'not found',"
    " 'scroll first', or similar, change the screen state first"
    " (call `list_visible_*`, navigate to the right tab, or use a listed"
    " low-level fallback tool if one is available)"
    " before retrying. Calling this tool again with the same non-visible"
    " ID will fail the same way."
)

_VISIBILITY_GATED_PREFIXES = (
    "open_", "view_", "tap_", "reserve_", "wishlist_", "favorite_",
    "star_", "rate_", "react_", "react_to_", "like_",
)


def _augment_visibility_contract(
    tool_name: str, schema: Dict[str, Any], description: str
) -> str:
    """Append a uniform visibility-contract note to tool descriptions
    for tools that act on an ID and require that ID to be visible.

    Triggered by name prefix (open_*/view_*/tap_*/etc.) AND the presence
    of at least one ID-like required argument in the input schema (e.g.
    movie_id, transaction_id, file_id, message_id, channel, slug).

    This is the runtime version of the same contract we put in the
    SYSTEM_PROMPT — having it on the tool itself catches it whether the
    model is reading the prompt or the tool description.

    Disable via ``MCP_DISABLE_VISIBILITY_AUGMENT=1`` (ablation): returns
    description unchanged. Defaults to current augmentation.
    """
    if os.environ.get("MCP_DISABLE_VISIBILITY_AUGMENT", "0") == "1":
        return description
    if not tool_name.startswith(_VISIBILITY_GATED_PREFIXES):
        return description
    props = schema.get("properties") if isinstance(schema, dict) else None
    required = schema.get("required") if isinstance(schema, dict) else None
    if not isinstance(props, dict) or not props:
        return description
    # Look for an ID-like required arg
    id_arg_hints = ("_id", "_slug", "_name", "channel", "slug", "tab", "id")
    candidate_args = list(required) if isinstance(required, list) and required else list(props.keys())
    if not any(any(h in str(a).lower() for h in id_arg_hints) for a in candidate_args):
        return description
    # Avoid double-appending if already documented
    if "PRECONDITION" in description and "visible" in description.lower():
        return description
    return (description + _VISIBILITY_CONTRACT_NOTE).strip()


def _is_confirmation_pair_tool(tool_name: str, schema: Dict[str, Any]) -> bool:
    """Return True for expanded prepare/confirm safety-pair tools.

    The OSS benchmark's default agent surface keeps the compact app-primitive
    tools to control context size. The prepare_*/confirm_*(draft_id) safety
    surface remains available behind --with-confirmation-tools.
    """
    if tool_name.startswith("prepare_"):
        return True
    if tool_name.startswith("confirm_"):
        props = schema.get("properties") if isinstance(schema, dict) else {}
        required = schema.get("required") if isinstance(schema, dict) else []
        return (
            isinstance(props, dict)
            and set(props.keys()) == {"draft_id"}
            and (not required or set(required) == {"draft_id"})
        )
    return False


def _mcp_app_names_from_disk() -> List[str]:
    return sorted(
        p.stem for p in _MCPS.glob("*.py")
        if p.stem not in NON_APP_MCP_MODULES
    )


def validate_tool_specs(tools: List[Dict[str, Any]]) -> List[str]:
    """Validate provider-facing tool specs before sending them to a model."""
    failures: List[str] = []
    seen = set()
    for idx, tool in enumerate(tools):
        name = tool.get("name")
        if not isinstance(name, str) or not _PROVIDER_TOOL_NAME_RE.match(name):
            failures.append(f"tool[{idx}] has invalid provider name: {name!r}")
            continue
        if name in seen:
            failures.append(f"duplicate provider tool name: {name}")
        seen.add(name)
        description = tool.get("description")
        if not isinstance(description, str) or "\n" in description:
            failures.append(f"{name} has invalid description formatting")
        schema = tool.get("input_schema")
        if not isinstance(schema, dict):
            failures.append(f"{name} input_schema is not an object")
            continue
        if schema.get("type") != "object":
            failures.append(f"{name} input_schema.type must be object")
        properties = schema.get("properties")
        if not isinstance(properties, dict):
            failures.append(f"{name} input_schema.properties must be an object")
            properties = {}
        required = schema.get("required", [])
        if not isinstance(required, list):
            failures.append(f"{name} input_schema.required must be a list")
            required = []
        dangling = [item for item in required if item not in properties]
        if dangling:
            failures.append(f"{name} required args missing properties: {dangling}")
        for prop_name, prop_schema in properties.items():
            if not isinstance(prop_name, str):
                failures.append(f"{name} has non-string property name: {prop_name!r}")
            if not isinstance(prop_schema, dict):
                failures.append(f"{name}.{prop_name} schema is not an object")
    return failures


def load_mcp_tools(
    pool: MCPClientPool,
    app_names: List[str],
    *,
    include_sim_fallback: bool = False,
    include_confirmation_tools: bool = False,
    include_observe_tools: bool = True,
) -> Tuple[List[Dict[str, Any]], Dict[str, Tuple[str, str]]]:
    """Discover tools from each app's MCP server via the real MCP client.

    Args:
        pool: a started MCPClientPool.
        app_names: app stems whose tools should be loaded (informational —
            the pool already knows which it loaded).
        include_sim_fallback: if True, append the sim_tap_xy / sim_type /
            sim_swipe / sim_observe / sim_screenshot / sim_home primitives
            after the MCP tools as low-level CUA-style fallbacks. Off by
            default — saves ~300 tokens per call and isn't needed when MCP
            tools cover the task.
        include_confirmation_tools: if True, include the expanded
            prepare_*/confirm_*(draft_id) safety-pair tools. Off by default
            to keep provider tool payloads bounded for multi-app tasks.
        include_observe_tools: if True, include observe-style tools that may
            return Appium UI XML. Disable for clean vision+MCP runs where XML
            must remain a local judge artifact rather than model input.

    Returns:
        tools: list of {name, description, input_schema} dicts in the order
            the model sees them — app tools first, sim_* fallbacks last
            (only when include_sim_fallback=True).
        tool_to_app: maps prefixed tool_name → (app_name, real_tool_name).
            For sim_* tools, app_name is "__simulator__".

    Tool naming follows Anthropic's MCP-connector convention:
        mcp__<server>__<tool>
    """
    tools: List[Dict[str, Any]] = []
    tool_to_app: Dict[str, Tuple[str, str]] = {}

    # 1) High-level MCP tools first (per app, via real list_tools RPC)
    for app_name in pool.app_names():
        try:
            raw_tools = pool.list_tools(app_name)
        except Exception as e:
            print(f"[mcp] {app_name}: list_tools failed: {e}", flush=True)
            continue
        for t in raw_tools:
            schema = _normalize_input_schema(
                dict(getattr(t, "inputSchema", None) or {})
            )
            if (
                not include_confirmation_tools
                and _is_confirmation_pair_tool(t.name, schema)
            ):
                continue
            if not include_observe_tools and t.name == "observe":
                continue
            prefixed = f"mcp__{app_name}__{t.name}"
            description = _normalize_description(getattr(t, "description", ""))
            description = _augment_visibility_contract(t.name, schema, description)
            spec = {
                "name": prefixed,
                "description": description,
                "input_schema": schema,
            }
            output_schema = getattr(t, "outputSchema", None)
            if output_schema:
                spec["output_schema"] = output_schema
            tools.append(spec)
            tool_to_app[prefixed] = (app_name, t.name)

    # 2) Sim fallback tools last (opt-in)
    if include_sim_fallback:
        for t in _SIM_TOOLS:
            if not include_observe_tools and t["name"] == "sim_observe":
                continue
            tools.append(dict(t))
            tool_to_app[t["name"]] = ("__simulator__", t["name"])

    failures = validate_tool_specs(tools)
    if failures:
        raise ValueError("Invalid provider tool specs:\n" + "\n".join(failures[:20]))

    return tools, tool_to_app


def write_tool_manifest(
    task_dir: pathlib.Path,
    *,
    app_names: List[str],
    tools: List[Dict[str, Any]],
    tool_to_app: Dict[str, Tuple[str, str]],
) -> pathlib.Path:
    """Persist the exact model-visible tool list for audit/debugging."""
    task_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "apps": app_names,
        "tool_count": len(tools),
        "tools": [
            {
                "name": tool["name"],
                "description": tool.get("description", ""),
                "input_schema": tool.get("input_schema", {}),
                "route": {
                    "app": tool_to_app.get(tool["name"], ("", ""))[0],
                    "tool": tool_to_app.get(tool["name"], ("", ""))[1],
                },
            }
            for tool in tools
        ],
    }
    path = task_dir / "tool_manifest.json"
    path.write_text(json.dumps(manifest, indent=2, sort_keys=True, default=str))
    return path


class TrajectoryRecorder:
    """Capture per-step screenshot + UI XML before each action, in the
    canonical benchmark format. Even text-only runs produce visual evidence
    so downstream graders/judges can review behavior the same way they
    review CUA runs.

    Layout under task_dir/:
        steps/01/screenshot.png
        steps/01/ui.xml
        steps/02/screenshot.png
        steps/02/ui.xml
        ...
        final_state/screenshot.png
        final_state/ui.xml
        trajectory.json    ← canonical benchmark format

    trajectory.json shape (matches existing runs/<run>/<task>/trajectory.json):
        [
          {
            "step": 1,
            "screenshot": "<rel path to BEFORE screenshot>",
            "source":     "<rel path to BEFORE ui.xml>",
            "actions": [
              {"action": "mcp_tool_call",
               "tool": "mcp__clock__launch",
               "args": {},
               "result": {<full structured envelope>}}
            ],
            "post_action_screenshot": "<rel path to NEXT step's screenshot>"
          },
          ...
        ]
    """

    def __init__(self, task_dir: pathlib.Path, *, verbose: bool = True) -> None:
        self.task_dir = task_dir
        self.steps_dir = task_dir / "steps"
        self.final_dir = task_dir / "final_state"
        self.task_dir.mkdir(parents=True, exist_ok=True)
        self.steps_dir.mkdir(exist_ok=True)
        self._entries: List[Dict[str, Any]] = []
        self._step_paths: Dict[int, Dict[str, str]] = {}
        self._verbose = verbose
        self._sim = None
        self._sim_failed = False

    def _ensure_sim(self):
        """Lazy SimulatorBridge connect — degrade gracefully if no Appium."""
        if self._sim_failed:
            return None
        if self._sim is None:
            try:
                from simulator_base import SimulatorBridge  # noqa: WPS433
                self._sim = SimulatorBridge.get()
                self._sim.connect()
            except Exception as e:
                if self._verbose:
                    print(f"[trajectory] sim unavailable, screenshots disabled: {e}",
                          flush=True)
                self._sim_failed = True
                return None
        return self._sim

    def _path_for_trajectory(self, p: pathlib.Path) -> str:
        """Render a path the way existing benchmark trajectories do: relative
        to CWD when possible (so it works from project root), else absolute."""
        try:
            return str(p.resolve().relative_to(pathlib.Path.cwd().resolve()))
        except ValueError:
            return str(p.resolve())

    def capture(self, step_num: int) -> Dict[str, Optional[str]]:
        """Snapshot the sim BEFORE step `step_num` executes. Idempotent if
        called twice for the same step. Returns relative paths for trajectory."""
        if step_num in self._step_paths:
            return self._step_paths[step_num]

        step_dir = self.steps_dir / f"{step_num:02d}"
        step_dir.mkdir(exist_ok=True)
        shot_file = step_dir / "screenshot.png"
        xml_file = step_dir / "ui.xml"

        sim = self._ensure_sim()
        screenshot_path: Optional[str] = None
        xml_path: Optional[str] = None
        if sim is not None:
            try:
                import base64 as _b64
                shot = sim.screenshot_base64()
                shot_file.write_bytes(_b64.b64decode(shot))
                screenshot_path = self._path_for_trajectory(shot_file)
            except Exception as e:
                if self._verbose:
                    print(f"[trajectory] screenshot capture failed at step {step_num}: {e}",
                          flush=True)
            try:
                xml = sim.observe_text()
                xml_file.write_text(xml or "")
                xml_path = self._path_for_trajectory(xml_file)
            except Exception as e:
                if self._verbose:
                    print(f"[trajectory] ui.xml capture failed at step {step_num}: {e}",
                          flush=True)

        paths = {"screenshot": screenshot_path, "source": xml_path,
                 "step_dir": str(step_dir)}
        self._step_paths[step_num] = paths
        return paths

    def record_action(self, step_num: int, action: Dict[str, Any]) -> None:
        """Append an action object to the trajectory entry for `step_num`.
        Multiple actions per step are supported (parallel tool calls)."""
        before = self._step_paths.get(step_num)
        if before is None:
            # In case capture was skipped (sim unavailable), still record action
            before = {"screenshot": None, "source": None}
        # Find or create the entry
        for entry in self._entries:
            if entry["step"] == step_num:
                entry["actions"].append(action)
                return
        self._entries.append({
            "step": step_num,
            "screenshot": before["screenshot"],
            "source": before["source"],
            "actions": [action],
        })

    def finalize(self) -> pathlib.Path:
        """Capture final state screenshot, link it as post_action_screenshot
        for the last step, and write trajectory.json."""
        # Capture final state
        sim = self._ensure_sim()
        final_path: Optional[str] = None
        if sim is not None:
            self.final_dir.mkdir(exist_ok=True)
            try:
                import base64 as _b64
                shot = sim.screenshot_base64()
                final_file = self.final_dir / "screenshot.png"
                final_file.write_bytes(_b64.b64decode(shot))
                final_path = self._path_for_trajectory(final_file)
            except Exception:
                pass
            try:
                xml = sim.observe_text()
                (self.final_dir / "ui.xml").write_text(xml or "")
            except Exception:
                pass

        # Wire post_action_screenshot for each step → next step's BEFORE shot,
        # except the final step which gets the final_state shot.
        for i, entry in enumerate(self._entries):
            if i + 1 < len(self._entries):
                entry["post_action_screenshot"] = self._entries[i + 1]["screenshot"]
            else:
                entry["post_action_screenshot"] = final_path

        traj_path = self.task_dir / "trajectory.json"
        traj_path.write_text(json.dumps(self._entries, indent=2, default=str))
        return traj_path


def _format_call_tool_result(result: Any) -> str:
    """Render a FastMCP CallToolResult into the string the model sees.

    Prefers structured_content (real MCP structured output) when present,
    falls back to concatenated text blocks. Errors come back as a labeled
    string so the model can see them but isn't handed a Python traceback.
    """
    # CallToolResult uses MCP wire-format names (isError, structuredContent);
    # FastMCP's high-level result uses snake_case (is_error, structured_content).
    # Check both so we work whether the pool returned via call_tool_mcp or
    # call_tool fallback.
    is_error = bool(
        getattr(result, "isError", None)
        or getattr(result, "is_error", False)
    )
    structured = (
        getattr(result, "structuredContent", None)
        or getattr(result, "structured_content", None)
        or getattr(result, "data", None)
    )
    content_blocks = getattr(result, "content", None) or []

    text_parts: List[str] = []
    for b in content_blocks:
        t = getattr(b, "text", None)
        if t:
            text_parts.append(t)
    text_body = "\n".join(text_parts) if text_parts else ""

    if is_error:
        return f"[MCP error] {text_body or structured or 'unknown error'}"
    if structured is not None and not isinstance(structured, str):
        try:
            return json.dumps(structured, default=str)
        except Exception:
            return str(structured)
    return text_body or (str(structured) if structured else "OK")


def _record_mcp_tool_action(
    recorder: Optional["TrajectoryRecorder"],
    step_num: int,
    *,
    tool_name: str,
    args: Dict[str, Any],
    output_text: Optional[str],
    tool_call_id: Optional[str] = None,
) -> None:
    """Record the exact MCP tool call/result in the judge-visible trajectory."""
    if recorder is None:
        return
    text = output_text or ""
    envelope = None
    try:
        if text and text.lstrip().startswith("{"):
            envelope = json.loads(text)
    except Exception:
        envelope = None
    action = {
        "action": "mcp_tool_call",
        "tool": tool_name,
        "args": dict(args) if args else {},
        # `output` is what the model received from the tool. Keep it on the
        # step so the judge can grade reads/writes from the MCP return itself.
        "output": text,
        "result": envelope or {"text": text},
    }
    if tool_call_id:
        action["tool_call_id"] = tool_call_id
    recorder.record_action(step_num, action)


_NAVIGATE_TAB_NAME_APPS = {
    "caltrack", "cityride", "dinespot", "freshcart", "quickbite", "skytrip",
    "teamchat", "ticketbox", "trailblaze",
}


def _normalize_mcp_tool_input(app_name: str, real_name: str, tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """Accept a few common model aliases before MCP schema validation.

    The provider still sees the canonical tool schema. This only repairs
    harmless near-misses that Qwen repeatedly makes in traces, such as using
    `tab` where the app tool requires `tab_name`.
    """
    if not isinstance(tool_input, dict):
        return tool_input
    out = dict(tool_input)
    if (
        real_name == "navigate_to_tab"
        and app_name in _NAVIGATE_TAB_NAME_APPS
        and "tab_name" not in out
        and "tab" in out
    ):
        out["tab_name"] = out.pop("tab")
    if (
        real_name == "navigate_to_tab"
        and app_name not in _NAVIGATE_TAB_NAME_APPS
        and "tab" not in out
        and "tab_name" in out
    ):
        out["tab"] = out.pop("tab_name")
    if real_name == "open_channel" and "channel_name" not in out:
        if "channel" in out:
            out["channel_name"] = out.pop("channel")
        elif "name" in out:
            out["channel_name"] = out.pop("name")
    return out


def _is_task_timeout_exception(exc: BaseException) -> bool:
    """Recognize appium_agent.TaskTimeout without importing appium_agent.

    In MCP mode the SIGALRM can fire while FastMCP is executing a tool. If the
    broad transport-error handler below turns that exception into normal tool
    text, appium_agent never sees the timeout and the task keeps running.
    """
    if exc.__class__.__name__ == "TaskTimeout":
        return True
    msg = str(exc).lower()
    return "exceeded" in msg and "timeout" in msg


def execute_tool(
    pool: MCPClientPool,
    tool_name: str,
    tool_input: Dict[str, Any],
    tool_to_app: Dict[str, Tuple[str, str]],
    *,
    capture_screenshot: bool = False,
) -> Any:
    """Dispatch a tool call.

    MCP tools (mcp__<app>__<tool>) go through the real FastMCP Client —
    `initialize` already happened at pool start; this is a real `tools/call`
    RPC with Pydantic validation and isError wrapping. Sim fallback tools
    bypass MCP and drive the simulator directly.

    If capture_screenshot=False (default), returns a string.
    If capture_screenshot=True, returns {"text": str, "screenshot_b64": str|None}.
    """
    from simulator_base import SimulatorBridge
    app_name, real_name = tool_to_app.get(tool_name, ("__unknown__", tool_name))

    # Sim fallback tools — direct dispatch, not MCP. These are the only path
    # that needs the bridge eagerly connected; MCP tool functions call
    # SimulatorBridge.get() themselves and connect lazily on first use.
    # All sim ops are wrapped so a RecoverableActionError (keyboard missing,
    # element stale, etc.) is surfaced to the model as a clean string instead
    # of crashing the agent loop.
    if app_name == "__simulator__":
        sim = SimulatorBridge.get()
        sim.connect()
        text = None
        try:
            if real_name == "sim_observe":
                text = sim.observe_text()
            elif real_name == "sim_screenshot":
                b64 = sim.screenshot_base64()
                text = f"[Screenshot captured, {len(b64)} bytes base64]"
                if capture_screenshot:
                    return {"text": text, "screenshot_b64": b64}
            elif real_name == "sim_tap_xy":
                sim.tap_xy(tool_input["x"], tool_input["y"])
                time.sleep(0.5)
                text = sim.observe_text()
            elif real_name == "sim_type":
                sim.type_text(tool_input["text"])
                time.sleep(0.3)
                text = sim.observe_text()
            elif real_name == "sim_swipe":
                sim.swipe(tool_input["direction"])
                time.sleep(0.5)
                text = sim.observe_text()
            elif real_name == "sim_home":
                sim.home()
                time.sleep(0.5)
                text = sim.observe_text()
            else:
                text = f"Unknown sim tool: {real_name}"
        except Exception as e:
            if _is_task_timeout_exception(e):
                raise
            # Surface as a recoverable error to the model, not a Python crash.
            text = f"[sim error] {type(e).__name__}: {e}"
        if capture_screenshot:
            shot = None
            try:
                shot = sim.screenshot_base64()
            except Exception:
                pass
            return {"text": text, "screenshot_b64": shot}
        return text

    # Real MCP tool call
    if app_name == "__unknown__":
        msg = f"[MCP error] Unknown tool: {tool_name}"
        if capture_screenshot:
            return {"text": msg, "screenshot_b64": None}
        return msg

    tool_input = _normalize_mcp_tool_input(app_name, real_name, tool_input)

    try:
        result = pool.call_tool(app_name, real_name, tool_input)
    except Exception as e:
        if _is_task_timeout_exception(e):
            raise
        msg = f"[MCP transport error] {e}"
        if capture_screenshot:
            return {"text": msg, "screenshot_b64": None}
        return msg

    text = _format_call_tool_result(result)
    # When a tool returns ok:false and we have a documented precondition for
    # this exact tool (per `_PRECONDITION_CONTEXTS`), inline the recovery hint
    # into the message field so the model sees "what to do next" at failure
    # time — not just in the preamble the user-message glossed over earlier.
    text = _inject_precondition_hint_on_failure(text, app_name, real_name)
    if capture_screenshot:
        # Only touch the bridge when actually capturing.
        sim = SimulatorBridge.get()
        sim.connect()
        return {"text": text, "screenshot_b64": sim.screenshot_base64()}
    return text


def _inject_precondition_hint_on_failure(text: str, app_name: str, real_name: str) -> str:
    """If *text* is a JSON envelope with ok:false and we have a documented
    precondition context for this tool, append the recovery hint into the
    `message` field. Returns the (possibly rewritten) JSON string. Best-effort:
    silently returns the original text on any parse/format mismatch.

    Disable via ``MCP_DISABLE_PRECONDITION_CONTEXTS=1`` (ablation): returns
    text unchanged. Defaults to current hint-injection behavior.
    """
    if os.environ.get("MCP_DISABLE_PRECONDITION_CONTEXTS", "0") == "1":
        return text
    key = f"{app_name}.{real_name}"
    hint = _PRECONDITION_CONTEXTS.get(key)
    if not hint:
        return text
    try:
        obj = json.loads(text)
    except Exception:
        return text
    if not isinstance(obj, dict) or obj.get("ok") is not False:
        return text
    existing = obj.get("message", "")
    if hint in existing:  # already present
        return text
    obj["message"] = (f"{existing} Recovery: {hint}").strip() if existing else f"Recovery: {hint}"
    try:
        return json.dumps(obj, default=str)
    except Exception:
        return text


# Current (487-word) SYSTEM_PROMPT — adds explicit guidance about ok:true≠success,
# ID-visibility before open_*, ui_after comparison, and final-response synthesis.
_SYSTEM_PROMPT_CURRENT = """You control an iOS Simulator. It is a touch phone: no cursor, keyboard shortcuts, or right-click. You start on the home screen.

For each task: (1) launch the required app via its `mcp__<app>__launch`; (2) ground yourself visually — read the next screenshot or call CUA `screenshot` / the app's `observe` tool if needed; (3) plan the minimum tool sequence to satisfy the goal; (4) execute, watching `ui_after` and `message` between steps to verify state actually changes.

Use the provider tool API. Do not invent tool names, arguments, IDs, or return fields. Tool names have the form `mcp__<app>__<tool>`. Launch an app before using its app-specific tools.

MCP tools are app primitives: search, list, open/get, create, edit, draft/send, prepare/confirm, and app actions. They are not task-answer functions. Inspect/change app state, then reason from returned data and visible UI.

Use tool result JSON directly. Check `action`, echoed `args`, `ok`, arrays/counts, read fields, `message`, and `ui_after`. `ok:true` ONLY means the function executed without throwing — it does NOT mean your goal succeeded. If `message` describes a problem ("No visible X with ID Y", "scroll first", "not found", "draft missing", etc.) or `ui_after` shows the same screen as before, the action did NOT achieve its semantic intent. Do not repeat the exact same call: read the message, change the precondition (scroll, navigate, surface the row, open the right screen), or pick a different tool. For `[MCP error]`, same rule applies.

IDs returned by `search`/`list_*` come from the data layer. They are not guaranteed to be currently visible on screen. Before calling `open_<x>(id)`, either confirm the ID appears in `list_visible_*` results OR scroll/navigate to surface it. If `open_<x>` returns "not visible", the right next step is `list_visible_*` or a CUA scroll, NOT calling the same `open_<x>` or `search` again.

Prefer list/search/read before writes. Use returned stable IDs, not guessed slugs. For multi-app tasks, launch each app when switching. If no app tool fits, use CUA touch actions. To dismiss the keyboard, tap outside the field.

Use CUA when app tools do not cover the interaction or after 2 consecutive MCP calls fail to advance the UI state (compare `ui_after` between turns — if it's the same, switch tactics). If XML is provided, use it as an aid; the screenshot is authoritative. Verify visible writes and risky actions before finishing.

For computer-use/CUA, use only its documented low-level action schema, such as click/type/scroll/wait/screenshot when available. Do not put MCP tool names, app actions like launch/observe/navigate_to_tab, or invented system buttons into CUA. To launch, observe, navigate tabs, search, or do app work, use the matching MCP tool if it exists.

When the task's required action(s) are complete and any required information has been read, STOP and produce your final response. Do not keep calling tools to re-verify what you already confirmed.

Final response: if the task asks to find, check, look up, or report information, include the exact requested values. Otherwise answer only with required confirmations."""


# Legacy (260-word) SYSTEM_PROMPT — the v15/v16 lean prompt that the canonical
# 0.45 baseline run used. Selected when MCP_LEGACY_SYSTEM_PROMPT=1 (ablation).
# Kept here verbatim so we can reproduce canonical behavior without git.
_SYSTEM_PROMPT_LEGACY = """You control an iOS Simulator. It is a touch phone: no cursor, keyboard shortcuts, or right-click. You start on the home screen.

Use the provider tool API. Do not invent tool names, arguments, IDs, or return fields. Tool names have the form `mcp__<app>__<tool>`. Launch an app before using its app-specific tools.

MCP tools are app primitives: search, list, open/get, create, edit, draft/send, prepare/confirm, and app actions. They are not task-answer functions. Inspect/change app state, then reason from returned data and visible UI.

Use tool result JSON directly. Check `action`, echoed `args`, `ok`, arrays/counts, read fields, and `message`. For `[MCP error]`, change argument, screen precondition, or tool choice; do not repeat the same failing call.

Prefer list/search/read before writes. Use returned stable IDs, not guessed slugs. For multi-app tasks, launch each app when switching. If no app tool fits, use CUA touch actions. To dismiss the keyboard, tap outside the field.

Use CUA only when app tools do not cover the interaction or for visual verification. If XML is provided, use it as an aid; the screenshot is authoritative. Verify visible writes and risky actions before finishing.

For computer-use/CUA, use only its documented low-level action schema, such as click/type/scroll/wait/screenshot when available. Do not put MCP tool names, app actions like launch/observe/navigate_to_tab, or invented system buttons into CUA. To launch, observe, navigate tabs, search, or do app work, use the matching MCP tool if it exists.

Final response: if the task asks to find, check, look up, or report information, include the exact requested values. Otherwise answer only with required confirmations."""


SYSTEM_PROMPT = (
    _SYSTEM_PROMPT_LEGACY
    if os.environ.get("MCP_LEGACY_SYSTEM_PROMPT", "0") == "1"
    else _SYSTEM_PROMPT_CURRENT
)


def _system_prompt_for_run(*, with_cua: bool) -> str:
    """Return the run prompt without advertising unavailable CUA aliases."""
    prompt = SYSTEM_PROMPT
    if with_cua:
        return prompt
    replacements = {
        "read the next screenshot or call CUA `screenshot` / the app's `observe` tool if needed":
            "read the next screenshot or call the app's `observe` tool if needed",
        "If no app tool fits, use CUA touch actions. ":
            "If no app tool fits, use only the provider tools that are actually listed for this run. ",
        "Use CUA when app tools do not cover the interaction or after 2 consecutive MCP calls fail to advance the UI state (compare `ui_after` between turns — if it's the same, switch tactics). ":
            "CUA/mobile_use is not available in this run. Do not call or describe low-level CUA aliases such as click, scroll, screenshot, or mobile_use unless they appear in the tool list. If MCP calls fail to advance the UI state, change MCP preconditions or choose another listed tool. ",
        "Use CUA only when app tools do not cover the interaction or for visual verification. ":
            "CUA/mobile_use is not available in this run; use only listed provider tools. ",
        "For computer-use/CUA, use only its documented low-level action schema, such as click/type/scroll/wait/screenshot when available. Do not put MCP tool names, app actions like launch/observe/navigate_to_tab, or invented system buttons into CUA. To launch, observe, navigate tabs, search, or do app work, use the matching MCP tool if it exists.\n\n":
            "",
    }
    for old, new in replacements.items():
        prompt = prompt.replace(old, new)
    return prompt

_RESULT_TRUNCATE = 15000  # Truncate tool results past this length to save tokens


_PRECONDITION_CONTEXTS: Dict[str, str] = {
    "caltrack.prepare_delete_food_entry": "Open a food entry from the daily food log so the food-entry edit view is visible.",
    "caltrack.confirm_delete_food_entry": "Call prepare_delete_food_entry from the food-entry edit view and keep that edit view open.",
    "cityride.recenter_map": "Be on the CityRide home map or request-flow map where map_recenter_button is rendered.",
    "dinespot.prepare_make_reservation": "Open a restaurant detail page and scroll to a visible reservation slot or Book Table entry point.",
    "dinespot.confirm_make_reservation": "Call prepare_make_reservation and keep the booking-review screen open.",
    "dinespot.set_party_size": "Open a restaurant detail/reservation flow where the party-size control is visible before changing party size.",
    "dinespot.add_booking_notes": "Booking-review screen must be open after starting a reservation flow.",
    "dinespot.set_booking_preference": "Booking-review screen must be open with the seating-preference picker available.",
    "dinespot.contact_support": "Contact-support composer must be visible from the account/help flow.",
    "lockedin.open_link_panel": "Open the post composer/editor screen with the link panel button visible.",
    "lockedin.schedule_post": "Open the post composer with schedule controls visible.",
    "megamart.return_or_replace": "Open order detail for a delivered order exposing order_return_replace_<order_number>.",
    "megamart.confirm_return_or_replace": "Call prepare_return_or_replace and keep that delivered order detail/action button visible.",
    "mybank.prepare_dispute_transaction": "Open a transaction detail sheet using list_transactions and open_transaction(transaction_id).",
    "mybank.confirm_dispute_transaction": "Call prepare_dispute_transaction from an open transaction detail sheet and keep the sheet open.",
    "mybank.dispute_transaction": "Transaction detail sheet must be open with detail_dispute_button visible.",
    "mybank.share_transaction": "Transaction detail sheet must be open with detail_share_button visible.",
    "quickbite.open_cart": "Open a restaurant detail page with at least one cart item so view_cart_button is visible.",
    "quickbite.search_restaurants": "Launch QuickBite and navigate_to_tab(tab_name='browse') before searching restaurants.",
    "quickbite.add_to_order": "Open a restaurant detail/menu where the item is visible before adding it to the order.",
    "quickbite.tap_place_order_button": "Cart view must be open with at least one item and a selected payment method.",
    "quickbite.prepare_checkout": "MyBank checkout sheet must be visible after restaurant detail -> add item -> open cart -> place order.",
    "quickbite.confirm_checkout": "Keep the prepared MyBank checkout sheet visible before confirming.",
    "quickchat.go_back": "Only use from inside an open chat thread; if already on the chats list, choose/open a thread instead.",
    "mail.search": "Launch Mail and open the relevant mailbox/folder before using search.",
    "mail.open_folder": "Launch Mail first; if folder controls are unavailable, use observe() and then choose the visible mailbox/folder.",
    "megamart.view_cart": "Launch MegaMart and navigate to Cart/checkout context before reading the cart.",
    "megamart.view_orders": "Launch MegaMart and navigate to account/orders before reading orders.",
    "scorezone.close_headline_detail": "Saved headline detail sheet must be visible from Favorites/Saved Stories.",
    "scorezone.read_headline": "Launch ScoreZone, navigate_to_section(section='watch'), then open a featured headline id from observe().",
    "scorezone.view_favorites": "Launch ScoreZone and navigate_to_section(section='scorezone+') before viewing favorites.",
    "skytrip.check_flight_status": "More tab must show the Flight Status detail sheet/header.",
    "skytrip.track_bags": "More tab must show the Track Bags detail sheet/header.",
    "skytrip.view_trips": "Launch SkyTrip and navigate_to_tab(tab_name='trips') before reading trips.",
    "stayfinder.reserve_listing": "Listing detail page must be open with bnb.detail.reserve visible.",
    "stayfinder.view_trips": "Launch StayFinder and navigate to the Trips tab before reading upcoming/past trips.",
    "teamchat.open_channel": "Launch TeamChat and navigate_to_tab(tab_name='home') first; then use the exact channel slug such as 'general', 'eng-mobile', or 'launch-war-room'.",
    "tasterank.filter_by_cuisine": "Requires the filters sheet with filters_cuisine_<id>; current app build does not present this sheet.",
    "tasterank.filter_by_price": "Requires the filters sheet with filters_price_<level>; current app build does not present this sheet.",
    "tasterank.toggle_open_now": "Requires the filters sheet with filters_open_now; current app build does not present this sheet.",
    "tasterank.apply_filters": "Requires the filters sheet with filters_done; current app build does not present this sheet.",
    "tasterank.reset_filters": "Requires the filters sheet with filters_reset; current app build does not present this sheet.",
    "ticketbox.filter_by_price": "Open the TicketBox filter sheet; price is exposed as visual sliders, so use CUA dragging if direct level ids are unavailable.",
    "trailblaze.save_recording": "Record tab must be in review phase after start_recording -> pause_recording -> stop_recording with record_save_button visible.",
}


def _format_precondition_contexts(app_names: List[str], *, include_confirmation_tools: bool = False) -> str:
    """Return compact, task-scoped context for precondition-only tools.

    The contexts are kept inline with the runner so the public release does not
    depend on a generated audit artifact. The model gets only the apps enabled
    for this task to avoid wasting context on unrelated tools.

    Disable via ``MCP_DISABLE_PRECONDITION_CONTEXTS=1`` (ablation): returns
    "" so the user message contains no per-tool preamble. Defaults to current.
    """
    if os.environ.get("MCP_DISABLE_PRECONDITION_CONTEXTS", "0") == "1":
        return ""
    allowed = set(app_names)
    rows = [
        f"- mcp__{app}__{tool}: {context}"
        for key, context in sorted(_PRECONDITION_CONTEXTS.items())
        for app, tool in [key.split(".", 1)]
        if app in allowed
        if include_confirmation_tools or not (tool.startswith("prepare_") or tool.startswith("confirm_"))
    ]
    if not rows:
        return ""
    return (
        "\n\nPrecondition-only tool contexts for these apps:\n"
        + "\n".join(rows)
        + "\nIf one returns ok=false, navigate to the stated screen/context before retrying; do not repeat the same call unchanged."
    )


def _format_user_message(
    goal: str,
    app_names: List[str],
    max_steps: Optional[int] = None,
    *,
    include_confirmation_tools: bool = False,
) -> str:
    """First user turn: the task plus the app inventory the agent has access to.

    The app list is part of session state (which servers are connected),
    not the assistant's persona — so it lives in the user message, not the
    system prompt. Tools self-describe their app via the `mcp__<app>__<tool>`
    name; we don't restate the convention.
    """
    if app_names:
        return (
            f"Task: {goal}\n\nApps available: {', '.join(app_names)}"
            f"{_format_precondition_contexts(app_names, include_confirmation_tools=include_confirmation_tools)}"
        )
    return f"Task: {goal}"


def _resolve_task_and_apps(
    *,
    task_text: Optional[str],
    explicit_apps: Optional[List[str]],
    tasks_path: Optional[str],
    task_id: Optional[str],
) -> Tuple[Optional[str], List[str]]:
    """Resolve the natural-language task and app scope.

    This is used by both execution and dry-run/list-tools paths so context
    budgeting is identical: when a benchmark task is selected, only the apps
    declared on that task are loaded unless `--apps` explicitly overrides it.
    """
    goal = task_text
    app_names = list(explicit_apps or [])

    if tasks_path and task_id:
        path = pathlib.Path(tasks_path)
        data = json.loads(path.read_text())
        import appium_agent
        if isinstance(data, dict) and "single_app_tasks" in data:
            all_tasks = appium_agent._flatten_benchmark_tasks(data)
        else:
            all_tasks = data
        task = next(
            (t for t in all_tasks if t.get("id") == task_id or t.get("name") == task_id),
            None,
        )
        if task is None:
            raise SystemExit(f"Task '{task_id}' not found in {tasks_path}")
        goal = task.get("goal") or task.get("task") or goal
        if not app_names:
            app_names = task.get("apps_involved") or task.get("apps") or []
            if isinstance(app_names, str):
                app_names = [app_names]
            if task.get("app"):
                app_names = [task["app"]]

    return goal, app_names


_QWEN_VLLM_MODEL_KEYS = (
    # Qwen3-VL family
    "qwen-vl", "qwen2-vl", "qwen2.5-vl", "qwen3-vl",
    # Qwen3.5 family ships multimodal without -VL suffix
    "qwen3.5",
)


def detect_provider(model: str) -> str:
    """Resolve the MCP provider.

    The MCP agent is Qwen-only (the paper's only MCP configuration). Any
    non-Qwen model — Claude, GPT, Gemini — is rejected here so the caller
    fails on argument validation rather than mid-run.
    """
    m = (model or "").lower()
    env_provider = os.environ.get("LLM_PROVIDER", "").lower()
    if "qwen" in m or env_provider in ("vllm", "qwen"):
        return "vllm"
    raise ValueError(
        f"MCP mode is Qwen-only. Got model={model!r} "
        f"(LLM_PROVIDER={env_provider or 'unset'}). Set LLM_PROVIDER=vllm and "
        f"pick a Qwen model (e.g. qwen3.5-35B-a3)."
    )


def is_cua_capable(model: str, provider: Optional[str] = None) -> bool:
    """Whether *model* supports the Qwen `mobile_use` tool used in --with-cua.

    Only the Qwen3-VL / Qwen3.5 families ship the cookbook `mobile_use`
    contract used by this runner.
    """
    m = (model or "").lower()
    return any(k in m for k in _QWEN_VLLM_MODEL_KEYS)


def _assert_cua_capable(model: str, provider: str = "vllm"):
    """Raise if the model doesn't support Qwen `mobile_use`."""
    if is_cua_capable(model):
        return
    raise ValueError(
        f"--with-cua requires a Qwen mobile_use-capable model. Got '{model}'. "
        f"Supported: {', '.join(_QWEN_VLLM_MODEL_KEYS)}"
    )


def run_mcp_agent(
    goal: str,
    app_names: List[str],
    *,
    max_steps: int = 15,
    model: str = "qwen3.5-35B-a3",
    verbose: bool = True,
    provider: Optional[str] = None,
    with_screenshots: bool = False,
    with_cua: bool = False,
    with_sim_fallback: bool = False,
    with_confirmation_tools: bool = False,
    transport: str = "in_memory",
    artifact_dir: Optional[pathlib.Path] = None,
    task_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Run the MCP agent loop for a single task against vLLM-served Qwen.

    MCP mode is Qwen-only — that's the only configuration evaluated in the
    iOSWorld paper. The runner speaks OpenAI-compatible Chat Completions
    against the vLLM endpoint declared by ``VLLM_BASE_URL`` / ``VLLM_API_KEY``.

    Options:
        with_screenshots: include a base64 PNG screenshot in each tool_result
            alongside the UI tree XML. Gives the Qwen-VL model visual grounding.
        with_cua: register Qwen's cookbook `mobile_use` tool alongside the
            MCP tools so the model can fall back to raw pixel click/type when
            no MCP tool covers a step.

    Returns a dict with: success, answer, steps, trajectory.
    """
    # Resolve provider — detect_provider() raises on non-Qwen models.
    provider = provider or detect_provider(model)
    if provider != "vllm":
        raise ValueError(
            f"MCP mode is Qwen-only. Got provider={provider!r}, model={model!r}."
        )

    # Keep provider-native CUA as the only low-level control surface unless the
    # caller explicitly asks for simulator fallback functions. Exposing both
    # `mobile_use` and sim_* tools makes tool choice noisier and is not the
    # standard Vision+Tools condition.
    sim_fallback = with_sim_fallback

    # Always-on trajectory recorder: even text-only runs capture per-step
    # screenshots + UI XML so the judge has visual evidence to grade against.
    if artifact_dir is None:
        artifact_dir = pathlib.Path("results") / time.strftime("mcp_%Y%m%d_%H%M%S")
    if task_id is None:
        task_id = "task"
    task_dir = pathlib.Path(artifact_dir) / task_id
    recorder = TrajectoryRecorder(task_dir, verbose=verbose)
    if verbose:
        print(f"[mcp-agent] Trajectory dir: {task_dir}", flush=True)

    pool = MCPClientPool(transport=transport)
    try:
        loaded_apps = pool.start(app_names)
        tools, tool_to_app = load_mcp_tools(
            pool, loaded_apps,
            include_sim_fallback=sim_fallback,
            include_confirmation_tools=with_confirmation_tools,
        )
        manifest_path = write_tool_manifest(
            task_dir,
            app_names=loaded_apps,
            tools=tools,
            tool_to_app=tool_to_app,
        )
        if verbose:
            sim_note = " +sim_fallback" if sim_fallback else ""
            confirm_note = " +confirmation_tools" if with_confirmation_tools else ""
            print(f"[mcp-agent] Loaded {len(tools)} tools "
                  f"(transport={transport}{sim_note}{confirm_note}) for apps: {loaded_apps}",
                  flush=True)
            print(f"[mcp-agent] Tool manifest: {manifest_path}", flush=True)

        if verbose:
            feats = []
            if with_screenshots:
                feats.append("screenshots")
            if with_cua:
                feats.append("+cua")
            print(f"[mcp-agent] Provider: vllm/qwen"
                  f"{' (' + ', '.join(feats) + ')' if feats else ''}", flush=True)

        if with_cua:
            _assert_cua_capable(model, "vllm")
        try:
            from llm_action_generator import vllm_base_url, vllm_api_key
            _base = vllm_base_url()
            _key = vllm_api_key()
        except Exception:
            _base = os.environ.get("VLLM_BASE_URL", "http://localhost:8000/v1").rstrip("/")
            _key = os.environ.get("VLLM_API_KEY") or os.environ.get("LLM_API_KEY") or "EMPTY"
        return _run_qwen_vllm(
            goal=goal, tools=tools, tool_to_app=tool_to_app,
            max_steps=max_steps, model=model, verbose=verbose,
            with_screenshots=with_screenshots, with_cua=with_cua,
            base_url=_base, api_key=_key,
            pool=pool, app_names=loaded_apps, recorder=recorder,
            include_confirmation_tools=with_confirmation_tools,
        )
    finally:
        try:
            traj_path = recorder.finalize()
            if verbose:
                print(f"[mcp-agent] Wrote trajectory: {traj_path}", flush=True)
        except Exception as e:
            if verbose:
                print(f"[mcp-agent] Trajectory finalize failed: {e}", flush=True)
        pool.close()


# ──────────────────────────────────────────────────────────────────────
# CUA dispatch — generic guarded wrapper used by the Qwen mobile_use path
# ──────────────────────────────────────────────────────────────────────

def _safe_cua_dispatch(fn, *args, **kwargs) -> Tuple[str, Optional[str]]:
    """Run a CUA dispatcher (returning a (text, screenshot_b64) tuple) under
    a guard. Any sim exception (RecoverableActionError, NoSuchElementError,
    etc.) is converted into a clean error string that the agent can read on
    the next turn — instead of crashing the whole run."""
    try:
        return fn(*args, **kwargs)
    except Exception as e:
        text = f"[sim error] {type(e).__name__}: {e}"
        shot = None
        try:
            from simulator_base import SimulatorBridge  # noqa: WPS433
            shot = SimulatorBridge.get().screenshot_base64()
        except Exception:
            pass
        return text, shot


# ──────────────────────────────────────────────────────────────────────
# Qwen via vLLM — OpenAI-compatible Chat Completions + mobile_use CUA
# ──────────────────────────────────────────────────────────────────────

def _qwen_dispatch_mobile_use(tool_input: Dict[str, Any], sim) -> Tuple[str, Optional[str]]:
    """Execute one Qwen `mobile_use` tool call against the iOS simulator.

    Reuses the cookbook-spec translator from llm_action_generator.py to map
    the model's emitted action (on a fixed 0-999 grid) into our framework's
    0-1000 normalized actions, then drives the SimulatorBridge accordingly.

    Returns (human_readable_summary, base64_png_screenshot). The screenshot
    is the post-action screen state, used as the model's vision input on
    the next turn.
    """
    from llm_action_generator import translate_qwen_cu_actions  # noqa: WPS433
    actions = translate_qwen_cu_actions(tool_input)
    summary_parts: List[str] = []
    for action in actions:
        atype = action.get("type")
        try:
            if atype == "tap_xy":
                sim.tap_xy(action["x"], action["y"])
                time.sleep(0.4)
                summary_parts.append(f"tap_xy({action['x']}, {action['y']})")
            elif atype == "type":
                sim.type_text(action.get("text", ""))
                time.sleep(0.3)
                summary_parts.append(f"type({action.get('text','')[:30]!r})")
            elif atype == "swipe":
                direction = action.get("direction", "up")
                sim.swipe(direction)
                time.sleep(0.4)
                summary_parts.append(f"swipe({direction})")
            elif atype == "home":
                sim.home()
                time.sleep(0.4)
                summary_parts.append("home")
            elif atype == "wait":
                time.sleep(float(action.get("duration", 1.0)))
                summary_parts.append(f"wait({action.get('duration',1.0)}s)")
            elif atype == "stop":
                summary_parts.append(f"stop(answer={action.get('answer','')[:60]!r})")
            elif atype == "hover":
                # iOS doesn't have a true hover; treat as tap.
                sim.tap_xy(action["x"], action["y"])
                summary_parts.append(f"long_press({action['x']}, {action['y']})")
            else:
                summary_parts.append(f"unsupported({atype})")
        except Exception as e:
            summary_parts.append(f"{atype} ERROR: {e}")
    text = ", ".join(summary_parts) or f"mobile_use({tool_input.get('action','?')}) — no actions"
    try:
        shot = sim.screenshot_base64()
    except Exception:
        shot = None
    return text, shot


def _run_qwen_vllm(goal, tools, tool_to_app, max_steps, model, verbose,
                   with_screenshots=False, with_cua=False,
                   *, base_url: str,
                   api_key: str,
                   pool: Optional[MCPClientPool] = None,
                   app_names: Optional[List[str]] = None,
                   recorder: Optional["TrajectoryRecorder"] = None,
                   include_confirmation_tools: bool = False):
    """Run the Qwen MCP agent loop against a vLLM endpoint.

    vLLM speaks OpenAI-compatible Chat Completions, so we use the `openai`
    SDK with `base_url` + `api_key` overrides. With ``with_cua=True``, the
    cookbook `mobile_use` tool is prepended to the function-tool list and
    its calls are routed through the Qwen action translator.
    """
    if with_cua:
        _assert_cua_capable(model, "vllm")
    import openai
    client = openai.OpenAI(api_key=api_key or "EMPTY", base_url=base_url)

    # Convert MCP tool schemas to OpenAI function schemas (vLLM accepts the
    # same wire format as OpenAI Chat Completions).
    openai_tools = [
        {"type": "function", "function": {
            "name": t["name"],
            "description": t["description"],
            "parameters": t["input_schema"],
        }} for t in tools
    ]

    # Qwen CUA: prepend the cookbook `mobile_use` tool. The Qwen-VL /
    # Qwen3.5 family was trained on this exact spec — it sees `mobile_use` as
    # the pixel-level fallback alongside our high-level MCP function tools.
    qwen_cu_active = with_cua
    if qwen_cu_active:
        try:
            from llm_action_generator import _qwen_mobile_use_tool  # noqa: WPS433
            openai_tools = [_qwen_mobile_use_tool()] + openai_tools
        except Exception as e:
            if verbose:
                print(f"[mcp-agent] Failed to load mobile_use tool spec: {e}", flush=True)
            qwen_cu_active = False
    # Qwen is a vision model — when CUA is on, force per-turn screenshots so
    # the model has visual grounding even for high-level MCP actions.
    if qwen_cu_active:
        with_screenshots = True

    messages = [
        {"role": "system", "content": _system_prompt_for_run(with_cua=qwen_cu_active)},
        {"role": "user", "content": _format_user_message(
            goal, app_names or [], include_confirmation_tools=include_confirmation_tools,
        )},
    ]
    trajectory = []
    answer = None
    cache_stats = {"cache_read_tokens": 0}
    max_tokens_kw = {"max_tokens": 4096}

    # Context management for Qwen MCP+CUA. The vLLM Qwen3.5 deployment is
    # 32K context, so two cookbook-recommended pruning steps are required:
    #
    #  1. Sliding-window screenshot history (OSWorld qwen3vl_agent canon —
    #     `history_n=4`). Keeps the first user message + last N screenshots,
    #     replaces older images with `[screenshot omitted]` text placeholders.
    #
    #  2. Strip `<think>...</think>` from historical assistant messages
    #     (Qwen3.5 model card guidance — only the latest turn keeps thinking).
    #
    # Both apply to Qwen and any vLLM run with screenshots; off otherwise.
    try:
        # _trim_old_screenshots_raw is the right helper for vLLM/OpenAI Chat
        # Completions message shape (image_url blocks inside content lists).
        # The non-_raw _trim_old_screenshots variant operates on the internal
        # {"images": [...]} format and is a no-op on raw API messages.
        from llm_action_generator import (
            _trim_old_screenshots_raw as _trim_screenshots,
            _strip_thinking_from_history,
            _QWEN_CU_SCREENSHOT_HISTORY,
            _SCREENSHOT_KEEP_RECENT,
        )
    except Exception:
        _trim_screenshots = None
        _strip_thinking_from_history = None
        _QWEN_CU_SCREENSHOT_HISTORY = 1
        _SCREENSHOT_KEEP_RECENT = None

    def _trim_old_tool_results(msgs, keep_recent: int, max_chars: int = 400):
        """Truncate tool result text in older turns to keep context lean.
        observe() and any tool that emits a UI tree can return ~3-4k tokens;
        in older turns we don't need the full snapshot, just the action proof.
        """
        if not keep_recent:
            return msgs
        tool_indices = [i for i, m in enumerate(msgs) if m.get("role") == "tool"]
        if len(tool_indices) <= keep_recent:
            return msgs
        keep_set = set(tool_indices[-keep_recent:])
        out = []
        for i, m in enumerate(msgs):
            if m.get("role") != "tool" or i in keep_set:
                out.append(m); continue
            c = m.get("content", "")
            if isinstance(c, str) and len(c) > max_chars:
                m = {**m, "content": c[:max_chars] + " …[result truncated for older turn]"}
            out.append(m)
        return out
    keep_recent = (
        _SCREENSHOT_KEEP_RECENT
        if _SCREENSHOT_KEEP_RECENT is not None
        else (_QWEN_CU_SCREENSHOT_HISTORY if (qwen_cu_active or with_screenshots) else None)
    )

    for step in range(max_steps):
        if verbose:
            print(f"\n[step {step + 1}/{max_steps}]", flush=True)

        if recorder is not None:
            recorder.capture(step + 1)

        # Apply pruning before each LLM call:
        #   • Screenshot sliding window (when keep_recent is set)
        #   • Tool-result truncation for older turns (handles observe() XML)
        #   • Strip <think> from old assistant messages (Qwen vLLM)
        msgs_for_call = messages
        if _trim_screenshots is not None and keep_recent is not None:
            msgs_for_call = _trim_screenshots(msgs_for_call, keep_recent=keep_recent)
        if keep_recent is not None:
            msgs_for_call = _trim_old_tool_results(msgs_for_call, keep_recent=keep_recent)
        if _strip_thinking_from_history is not None:
            msgs_for_call = _strip_thinking_from_history(msgs_for_call)

        from llm_action_generator import retry_with_backoff as _retry_bo
        response = _retry_bo(
            lambda: client.chat.completions.create(
                model=model, messages=msgs_for_call, tools=openai_tools, tool_choice="auto",
                **max_tokens_kw,
            ),
            max_retries=5,
        )

        usage = getattr(response, "usage", None)
        if usage and hasattr(usage, "prompt_tokens_details"):
            details = usage.prompt_tokens_details
            cache_stats["cache_read_tokens"] += getattr(details, "cached_tokens", 0) or 0
        if usage:
            try:
                from llm_action_generator import _log_openai_usage
                _log_openai_usage(usage, model, label="vLLM MCP")
            except Exception:
                pass

        msg = response.choices[0].message
        messages.append({
            "role": "assistant",
            "content": msg.content or "",
            "tool_calls": [{"id": tc.id, "type": "function",
                            "function": {"name": tc.function.name,
                                         "arguments": tc.function.arguments}}
                           for tc in (msg.tool_calls or [])] or None,
        })

        if msg.content and verbose:
            print(f"  Agent: {msg.content[:200]}", flush=True)

        tool_calls = msg.tool_calls or []
        if not tool_calls:
            answer = msg.content or ""
            trajectory.append({"step": step + 1, "type": "final_answer", "answer": answer})
            break

        for tc in tool_calls:
            name = tc.function.name
            try:
                args = json.loads(tc.function.arguments or "{}")
            except json.JSONDecodeError:
                args = {}
            if verbose:
                print(f"  Tool: {name}({json.dumps(args)[:100]})", flush=True)

            # Qwen mobile_use → pixel dispatcher; everything else → MCP path
            if qwen_cu_active and name == "mobile_use":
                from simulator_base import SimulatorBridge  # noqa: WPS433
                _sim = SimulatorBridge.get(); _sim.connect()
                text_q, shot_q = _safe_cua_dispatch(_qwen_dispatch_mobile_use, args, _sim)
                messages.append({
                    "role": "tool", "tool_call_id": tc.id,
                    "content": _smart_truncate(text_q, _RESULT_TRUNCATE),
                })
                if shot_q:
                    messages.append({
                        "role": "user",
                        "content": [
                            {"type": "text", "text": "[screenshot after mobile_use]"},
                            {"type": "image_url",
                             "image_url": {"url": f"data:image/png;base64,{shot_q}"}},
                        ],
                    })
                trajectory.append({
                    "step": step + 1, "tool": "mobile_use", "input": args, "result_len": len(text_q),
                })
                if recorder is not None:
                    recorder.record_action(step + 1, {
                        "action": "computer_use",
                        "computer_action": args.get("action"),
                        "input": args,
                        "result_text": text_q[:200],
                    })
                continue

            result = execute_tool(pool, name, args, tool_to_app,
                                  capture_screenshot=with_screenshots)
            if isinstance(result, dict):
                text = _smart_truncate(result["text"], _RESULT_TRUNCATE)
                shot = result.get("screenshot_b64")
                messages.append({
                    "role": "tool", "tool_call_id": tc.id, "content": text,
                })
                # Post the screenshot as a follow-up user message (Chat
                # Completions tool messages don't accept images directly)
                if shot:
                    messages.append({
                        "role": "user",
                        "content": [
                            {"type": "text", "text": f"[screenshot of state after {name}]"},
                            {"type": "image_url",
                             "image_url": {"url": f"data:image/png;base64,{shot}"}},
                        ],
                    })
                trajectory.append({
                    "step": step + 1, "tool": name, "input": args, "result_len": len(text),
                })
            else:
                result = _smart_truncate(result, _RESULT_TRUNCATE)
                messages.append({
                    "role": "tool", "tool_call_id": tc.id, "content": result,
                })
                trajectory.append({
                    "step": step + 1, "tool": name, "input": args, "result_len": len(result),
                })
            if recorder is not None:
                text_for_envelope = result["text"] if isinstance(result, dict) else result
                _record_mcp_tool_action(
                    recorder, step + 1,
                    tool_name=name,
                    args=args,
                    output_text=text_for_envelope,
                    tool_call_id=tc.id,
                )

    if verbose:
        print(f"\n[cache] read={cache_stats['cache_read_tokens']} tokens (automatic)", flush=True)

    return {
        "success": answer is not None, "answer": answer,
        "steps": len(trajectory), "trajectory": trajectory,
        "provider": "vllm", "cache_stats": cache_stats,
    }


def main():
    parser = argparse.ArgumentParser(description="MCP-based agent runner for iOS Simulator tasks.")
    parser.add_argument("--task", help="Task goal (natural language description)")
    parser.add_argument("--apps", nargs="+", help="App names to load MCP tools for (e.g., teamchat mybank)")
    parser.add_argument("--tasks", help="Path to benchmark tasks JSON file")
    parser.add_argument("--task-id", help="Specific task ID to run from tasks file")
    parser.add_argument("--max-steps", type=int, default=50,
                        help="Maximum agent steps (paper uses 50 for all runs)")
    parser.add_argument("--model", default=os.environ.get("LLM_MODEL", "qwen3.5-35B-a3"),
                        help="Qwen model served by vLLM (e.g. qwen3.5-35B-a3). MCP mode is Qwen-only.")
    parser.add_argument("--list-tools", action="store_true", help="List available MCP tools and exit")
    parser.add_argument("--dry-run-tools", action="store_true",
                        help="Resolve task/app scope, validate provider-facing tool specs, write "
                             "tool_manifest.json, and exit without calling a model API.")
    parser.add_argument("--artifact-dir", default="results/mcp",
                        help="Base dir for output artifacts. Per-task layout: "
                             "<artifact-dir>/<task-id>/{trajectory.json, steps/NN/screenshot.png, "
                             "steps/NN/ui.xml, final_state/screenshot.png, mcp_run.json}.")
    parser.add_argument("--with-screenshots", action="store_true",
                        help="Include a screenshot in each tool_result alongside the UI tree XML. "
                             "Gives Qwen-VL visual grounding.")
    parser.add_argument("--with-cua", action="store_true",
                        help="Hybrid MCP + Qwen `mobile_use`: prepend the cookbook mobile_use tool "
                             "alongside the MCP tools so the agent can fall back to raw pixel "
                             "click/type when no MCP tool covers a step. Requires a Qwen-VL / "
                             "Qwen3.5 model.")
    parser.add_argument("--transport", choices=["in_memory", "stdio"], default="in_memory",
                        help="MCP transport. 'in_memory' uses FastMCP Client(server) — same wire "
                             "protocol, no IPC. 'stdio' spawns scripts/combined_mcp_server.py as a "
                             "subprocess and connects via JSON-RPC over stdio (canonical MCP spec "
                             "transport).")
    parser.add_argument("--with-sim-fallback", action="store_true",
                        help="Append sim_tap_xy / sim_type / sim_swipe / sim_observe / "
                             "sim_screenshot / sim_home as low-level CUA-style fallbacks after "
                             "the MCP tools. Off by default; provider-native CUA remains separate.")
    parser.add_argument("--with-confirmation-tools", action="store_true",
                        help="Include expanded prepare_*/confirm_*(draft_id) safety-pair tools. "
                             "Off by default to keep multi-app tool payloads compact; enable for "
                             "confirmation-focused safety experiments.")
    args = parser.parse_args()

    if args.list_tools:
        _goal, app_names = _resolve_task_and_apps(
            task_text=args.task,
            explicit_apps=args.apps,
            tasks_path=args.tasks,
            task_id=args.task_id,
        )
        if not app_names:
            # List all available apps
            app_names = _mcp_app_names_from_disk()
        pool = MCPClientPool()
        try:
            loaded = pool.start(app_names)
            tools, _ = load_mcp_tools(
                pool, loaded,
                include_sim_fallback=args.with_sim_fallback,
                include_confirmation_tools=args.with_confirmation_tools,
            )
        finally:
            pool.close()
        print(f"\n{'='*60}")
        print(f"Available MCP tools ({len(tools)} total) — apps: {loaded}")
        print(f"{'='*60}")
        for t in tools:
            params = list(t["input_schema"].get("properties", {}).keys())
            params_str = f"({', '.join(params)})" if params else "()"
            print(f"  {t['name']}{params_str}")
            if t.get("description"):
                print(f"    {t['description'][:100]}")
        return

    # Resolve task
    goal, app_names = _resolve_task_and_apps(
        task_text=args.task,
        explicit_apps=args.apps,
        tasks_path=args.tasks,
        task_id=args.task_id,
    )

    if not goal:
        raise SystemExit("Provide a task via --task or --tasks + --task-id")
    if not app_names:
        raise SystemExit("Provide app names via --apps or use --tasks with app info")

    print(f"[mcp-agent] Goal: {goal}", flush=True)
    print(f"[mcp-agent] Apps: {app_names}", flush=True)
    print(f"[mcp-agent] Model: {args.model}", flush=True)
    print(f"[mcp-agent] Max steps: {args.max_steps}", flush=True)

    # Resolve trajectory artifact path: <artifact-dir>/<task-id>/...
    artifact_dir = pathlib.Path(args.artifact_dir)
    resolved_task_id = args.task_id or f"task_{time.strftime('%Y%m%d_%H%M%S')}"

    if args.dry_run_tools:
        pool = MCPClientPool(transport=args.transport)
        try:
            loaded_apps = pool.start(app_names)
            tools, tool_to_app = load_mcp_tools(
                pool,
                loaded_apps,
                include_sim_fallback=args.with_sim_fallback,
                include_confirmation_tools=args.with_confirmation_tools,
            )
            task_dir = artifact_dir / resolved_task_id
            manifest_path = write_tool_manifest(
                task_dir,
                app_names=loaded_apps,
                tools=tools,
                tool_to_app=tool_to_app,
            )
        finally:
            pool.close()
        print(f"[mcp-agent] Dry-run tool manifest: {manifest_path}")
        print(f"[mcp-agent] Apps: {loaded_apps}")
        print(f"[mcp-agent] Tools: {len(tools)}")
        return

    result = run_mcp_agent(
        goal=goal,
        app_names=app_names,
        max_steps=args.max_steps,
        model=args.model,
        with_screenshots=args.with_screenshots,
        with_cua=args.with_cua,
        with_sim_fallback=args.with_sim_fallback,
        with_confirmation_tools=args.with_confirmation_tools,
        transport=args.transport,
        artifact_dir=artifact_dir,
        task_id=resolved_task_id,
    )

    print(f"\n{'='*60}")
    print(f"Result: {'SUCCESS' if result['success'] else 'INCOMPLETE'}")
    print(f"Steps: {result['steps']}")
    if result['answer']:
        print(f"Answer: {result['answer'][:500]}")
    print(f"{'='*60}")

    # Save the runner's full result alongside the trajectory written by
    # TrajectoryRecorder during the run.
    task_dir = artifact_dir / resolved_task_id
    task_dir.mkdir(parents=True, exist_ok=True)
    out_path = task_dir / "mcp_run.json"
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2, default=str)
    print(f"\nArtifacts saved to {task_dir}/")
    print(f"  • trajectory.json (canonical benchmark format with per-step screenshots)")
    print(f"  • mcp_run.json    (provider/cache stats + raw trajectory)")
    print(f"  • tool_manifest.json (exact provider-visible tool names + input schemas)")
    print(f"  • steps/NN/screenshot.png + ui.xml")
    print(f"  • final_state/screenshot.png + ui.xml")


if __name__ == "__main__":
    main()
