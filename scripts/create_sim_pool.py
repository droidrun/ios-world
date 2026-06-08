#!/usr/bin/env python3
"""
Create a pool of simulator clones from a source simulator that already has
apps installed.  Uses ``xcrun simctl clone`` which copies all installed apps
and data, avoiding the need to rebuild/reinstall.

Usage:
  python3 scripts/create_sim_pool.py --source-udid <UDID> --workers 4

Outputs a JSON object to stdout:
  {
    "source_udid": "...",
    "clones": [
      {"worker": 0, "udid": "...", "name": "Bench-Worker-0"},
      ...
    ]
  }
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from typing import List


def run(cmd: List[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if check and proc.returncode != 0:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\nstdout: {proc.stdout}\nstderr: {proc.stderr}"
        )
    return proc


def verify_udid_exists(udid: str) -> None:
    """Verify the source UDID exists in available simulators."""
    proc = run(["xcrun", "simctl", "list", "devices", "available", "-j"])
    data = json.loads(proc.stdout)
    for _runtime, devs in data.get("devices", {}).items():
        for d in devs:
            if d.get("udid") == udid:
                return
    raise SystemExit(f"Source UDID not found in available simulators: {udid}")


def clone_simulator(source_udid: str, name: str) -> str:
    """Clone a simulator and return the new UDID."""
    proc = run(["xcrun", "simctl", "clone", source_udid, name])
    udid = proc.stdout.strip()
    if not udid:
        raise RuntimeError(f"simctl clone returned empty UDID for '{name}'")
    return udid


def boot_simulator(udid: str) -> None:
    """Boot a simulator and wait for it to be ready."""
    run(["xcrun", "simctl", "boot", udid], check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a pool of cloned simulators.")
    parser.add_argument("--source-udid", required=True, help="UDID of the source simulator (with apps installed).")
    parser.add_argument("--workers", type=int, required=True, help="Number of simulator clones to create.")
    parser.add_argument("--name-prefix", default="Bench-Worker", help="Name prefix for cloned simulators.")
    args = parser.parse_args()

    if args.workers < 1:
        print("--workers must be >= 1", file=sys.stderr)
        return 1

    verify_udid_exists(args.source_udid)

    # Shutdown source sim (required for cloning).
    print(f"Shutting down source simulator {args.source_udid} for cloning...", file=sys.stderr)
    run(["xcrun", "simctl", "shutdown", args.source_udid], check=False)

    clones = []
    for i in range(args.workers):
        name = f"{args.name_prefix}-{i}"
        print(f"Cloning worker {i}: {name}...", file=sys.stderr)
        udid = clone_simulator(args.source_udid, name)
        clones.append({"worker": i, "udid": udid, "name": name})

    # Boot all clones.
    for clone in clones:
        print(f"Booting {clone['name']} ({clone['udid']})...", file=sys.stderr)
        boot_simulator(clone["udid"])

    # Re-boot source sim so it's not left shutdown.
    print(f"Re-booting source simulator {args.source_udid}...", file=sys.stderr)
    boot_simulator(args.source_udid)

    result = {
        "source_udid": args.source_udid,
        "clones": clones,
    }
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
