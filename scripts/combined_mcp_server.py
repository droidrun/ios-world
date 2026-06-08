#!/usr/bin/env python3
"""Combined FastMCP server — stdio transport entrypoint.

Mounts every per-app MCP server in `mcps/*.py` under an `mcp_<app>` prefix
inside one FastMCP instance and runs it over stdio. This is the canonical
MCP-spec transport for a local agent.

Why one combined process and not one-subprocess-per-app: the iOS Simulator
allows only one Appium driver session per device. N independent processes
would fight over the simulator. A single combined server keeps the
SimulatorBridge singleton in one place while still going through the real
JSON-RPC stdio wire protocol (initialize, tools/list, tools/call).

Usage:
    python3 scripts/combined_mcp_server.py
    # then connect via mcp.ClientSession + stdio_client

Or via mcp_agent_runner.py:
    python3 scripts/mcp_agent_runner.py --transport stdio --task ... --apps ...
"""
from __future__ import annotations

import importlib.util
import pathlib
import sys
from typing import Optional

_HERE = pathlib.Path(__file__).resolve().parent
_ROOT = _HERE.parent
_MCPS = _ROOT / "mcps"
sys.path.insert(0, str(_HERE))
sys.path.insert(0, str(_MCPS))

from fastmcp import FastMCP

# Files in mcps/ that are NOT app servers
_SKIP = {
    "__init__", "_data_layer", "simulator_base", "tool_support",
}


def _load_app_server(app_path: pathlib.Path) -> Optional[FastMCP]:
    spec = importlib.util.spec_from_file_location(
        f"mcp_{app_path.stem}", str(app_path),
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return getattr(mod, "mcp", None)


def build_combined(app_filter: Optional[list] = None) -> FastMCP:
    """Build the combined FastMCP server.

    app_filter: optional list of app stems to include. None = all apps.
    """
    parent = FastMCP("iOSBenchmarkCombined")
    for app_path in sorted(_MCPS.glob("*.py")):
        stem = app_path.stem
        if stem in _SKIP:
            continue
        if app_filter is not None and stem not in app_filter:
            continue
        sub = _load_app_server(app_path)
        if sub is None:
            print(f"[combined-mcp] skip {stem}: no FastMCP instance", file=sys.stderr)
            continue
        # mount establishes a live link from parent → sub. Tools become
        # accessible as `<namespace>_<tool>`. We use `mcp_<app>` so the
        # outer name is e.g. `mcp_teamchat_send_message`.
        parent.mount(sub, namespace=f"mcp_{stem}")
    return parent


def main() -> None:
    # Optional CLI: --apps a b c to limit which apps are mounted
    args = sys.argv[1:]
    app_filter = None
    if "--apps" in args:
        i = args.index("--apps")
        app_filter = args[i + 1 :]
    parent = build_combined(app_filter)
    # Default transport for FastMCP.run() is stdio.
    parent.run()


if __name__ == "__main__":
    main()
