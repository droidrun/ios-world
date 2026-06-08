#!/usr/bin/env python3
"""
Select the latest available iOS simulator UDID (defaults to iPhone; override with --device-filter).
By default prints a shell-exportable line: export SIMCTL_UDID=<udid> # <name> (<runtime>)
Pass --bare to print just the bare UDID (useful for command substitution).

Usage:
  python3 scripts/find_latest_udid.py
  python3 scripts/find_latest_udid.py --device-filter iPad
  SOURCE_UDID=$(python3 scripts/find_latest_udid.py --bare)
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Tuple


def run(cmd):
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit(f"Command failed: {' '.join(cmd)}\nstdout:\n{proc.stdout}\nstderr:\n{proc.stderr}")
    return proc.stdout


def pick_latest(device_filter: str) -> Tuple[str, str, str]:
    data = json.loads(run(["xcrun", "simctl", "list", "devices", "available", "-j"]))
    devices = data.get("devices", {})
    # Sort runtimes descending by version number
    def runtime_key(rt: str):
        # rt looks like "com.apple.CoreSimulator.SimRuntime.iOS-17-4"
        if "iOS" not in rt:
            return (-1, rt)
        tail = rt.split("iOS-")[-1].replace("-", ".")
        try:
            parts = [int(p) for p in tail.split(".")]
        except ValueError:
            parts = [0]
        return (parts[0], parts[1] if len(parts) > 1 else 0, parts[2] if len(parts) > 2 else 0)

    # Prefer (in order):
    #   1. Booted + has-benchmark-apps + device_filter match
    #   2. Booted + has-benchmark-apps (any device)
    #   3. Booted + device_filter match
    #   4. Booted anything
    #   5. Available + device_filter match
    #   6. Anything available
    # The has-benchmark-apps check disambiguates the common case of multiple
    # booted sims — pick the one with our apps installed. Checked via
    # `simctl get_app_container <udid> com.iosworld.benchmark.clock`.
    def _has_benchmark_apps(udid: str) -> bool:
        r = subprocess.run(
            ["xcrun", "simctl", "get_app_container", udid,
             "com.iosworld.benchmark.clock"],
            capture_output=True, text=True,
        )
        return r.returncode == 0

    runtimes_sorted = [r for r in sorted(devices.keys(), key=runtime_key, reverse=True) if "iOS" in r]

    def _candidates(want_booted, name_filter):
        out = []
        for runtime in runtimes_sorted:
            for d in devices.get(runtime, []):
                if not d.get("isAvailable"):
                    continue
                if want_booted and d.get("state") != "Booted":
                    continue
                if name_filter and name_filter.lower() not in d.get("name", "").lower():
                    continue
                out.append((d, runtime))
        return out

    for want_booted in (True, False):
        if want_booted:
            # Stage 1+2: among booted, prefer ones with benchmark apps.
            for name_filter in (device_filter, None):
                cands = _candidates(True, name_filter)
                with_apps = [(d, rt) for d, rt in cands if _has_benchmark_apps(d["udid"])]
                if with_apps:
                    d, rt = with_apps[0]
                    return (d["udid"], d["name"], rt.split(".")[-1].replace("-", " "))
        # Stage 3+4 (booted without apps) or 5+6 (any available).
        for name_filter in (device_filter, None):
            cands = _candidates(want_booted, name_filter)
            if cands:
                d, rt = cands[0]
                return (d["udid"], d["name"], rt.split(".")[-1].replace("-", " "))
    raise SystemExit("No available iOS simulators found.")


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Pick latest available iOS simulator UDID.")
    parser.add_argument("--device-filter", default=os.environ.get("SIMCTL_DEVICE_FILTER", "iPhone"),
                        help="Substring to match device name (default: iPhone)")
    parser.add_argument("--bare", action="store_true",
                        help="Print just the UDID (suitable for $(...) substitution).")
    args = parser.parse_args()
    udid, name, runtime = pick_latest(args.device_filter)
    if args.bare:
        print(udid)
    else:
        print(f'export SIMCTL_UDID={udid}  # {name} ({runtime})')


if __name__ == "__main__":
    sys.exit(main())
