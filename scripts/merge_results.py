#!/usr/bin/env python3
"""
Merge results from N parallel benchmark workers into a single summary.

Reads ``summary.json`` and ``conversations.json`` from worker run
directories, optionally combines them with an existing merged output
directory, and produces combined outputs that look identical to a
single-worker run (with extra ``worker`` and ``worker_stats`` fields).

Usage:
  python3 scripts/merge_results.py \\
    --run-dirs results/run-xxx/worker-0 results/run-xxx/worker-1 \\
    --output results/run-xxx
"""
from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Any, Dict, List


def load_json(path: pathlib.Path) -> Any:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in {path}: {exc}") from exc


def load_existing_task_entries(run_dir: pathlib.Path) -> List[Dict[str, Any]]:
    task_entries: List[Dict[str, Any]] = []
    for task_json_path in sorted(run_dir.glob("*/task.json")):
        data = load_json(task_json_path)
        if isinstance(data, dict):
            task_entries.append(data)
    return task_entries


def _merge_existing_run(existing_run_dir: pathlib.Path,
                        all_conversations: List[Dict[str, Any]]) -> Dict[str, Any] | None:
    run_metadata = load_json(existing_run_dir / "run_metadata.json")

    convos = load_json(existing_run_dir / "conversations.json")
    if isinstance(convos, list):
        all_conversations.extend(convos)

    return run_metadata if isinstance(run_metadata, dict) else None


def merge(run_dirs: List[pathlib.Path], output_dir: pathlib.Path,
          existing_run_dir: pathlib.Path | None = None) -> Dict[str, Any]:
    all_tasks: List[Dict[str, Any]] = []
    all_conversations: List[Dict[str, Any]] = []
    worker_stats: List[Dict[str, Any]] = []
    total_failed = 0
    merged_run_metadata: Dict[str, Any] | None = None
    worker_udids: List[str] = []

    if existing_run_dir is not None:
        existing_metadata = _merge_existing_run(existing_run_dir, all_conversations)
        if existing_metadata is not None:
            merged_run_metadata = dict(existing_metadata)

    for worker_id, rd in enumerate(run_dirs):
        summary = load_json(rd / "summary.json")
        run_metadata = load_json(rd / "run_metadata.json")
        if isinstance(run_metadata, dict):
            if merged_run_metadata is None:
                merged_run_metadata = dict(run_metadata)
            udid = run_metadata.get("udid")
            if isinstance(udid, str) and udid:
                worker_udids.append(udid)
        if summary is None:
            worker_stats.append({
                "worker": worker_id,
                "run_dir": str(rd),
                "tasks": 0,
                "failed": 0,
                "error": "summary.json not found",
            })
            continue

        tasks = summary.get("tasks", [])
        failed = summary.get("failed_tasks", 0)
        total_failed += failed

        for task_entry in tasks:
            task_entry["worker"] = worker_id

        all_tasks.extend(tasks)
        worker_stats.append({
            "worker": worker_id,
            "run_dir": str(rd),
            "tasks": len(tasks),
            "failed": failed,
        })

        convos = load_json(rd / "conversations.json")
        if isinstance(convos, list):
            for c in convos:
                c["worker"] = worker_id
            all_conversations.extend(convos)

    disk_tasks = load_existing_task_entries(output_dir)
    if disk_tasks:
        for task_entry in disk_tasks:
            task_entry.pop("worker", None)
        all_tasks = disk_tasks
        total_failed = sum(1 for task_entry in all_tasks if task_entry.get("status") != "ok")

    # Sort tasks by _original_index if present (injected by split_tasks.py),
    # so the merged output matches the original task order.
    all_tasks.sort(key=lambda t: _get_original_index(t))

    # Re-number iterations to be globally sequential.
    for i, task_entry in enumerate(all_tasks, start=1):
        task_entry["iteration"] = i

    merged_summary = {
        "run_dir": str(output_dir),
        "workers": len(run_dirs),
        "tasks": all_tasks,
        "failed_tasks": total_failed,
        "worker_stats": worker_stats,
    }

    # Write outputs.
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "summary.json").write_text(
        json.dumps(merged_summary, indent=2), encoding="utf-8"
    )
    if all_conversations:
        (output_dir / "conversations.json").write_text(
            json.dumps(all_conversations, indent=2), encoding="utf-8"
        )
    if merged_run_metadata is not None:
        merged_run_metadata["run_dir"] = str(output_dir)
        merged_run_metadata["workers"] = len(run_dirs)
        if worker_udids:
            merged_run_metadata["worker_udids"] = worker_udids
        (output_dir / "run_metadata.json").write_text(
            json.dumps(merged_run_metadata, indent=2), encoding="utf-8"
        )

    return merged_summary


def _get_original_index(task_entry: Dict[str, Any]) -> int:
    """Extract the original task index for sorting.

    Looks inside the per-task ``task.json`` for the ``_original_index`` field
    that split_tasks.py injected, or falls back to the task_dir path which
    contains the iteration number prefix (e.g. ``01-task-name``).
    """
    # Try reading _original_index from the nested task.json.
    task_dir = task_entry.get("task_dir")
    if task_dir:
        task_json_path = pathlib.Path(task_dir) / "task.json"
        if task_json_path.exists():
            try:
                data = json.loads(task_json_path.read_text(encoding="utf-8"))
                idx = data.get("_original_index")
                if idx is not None:
                    return int(idx)
            except (json.JSONDecodeError, ValueError):
                pass
        # Fallback: parse the directory name prefix (e.g. "01-task-name" → 1).
        try:
            return int(pathlib.Path(task_dir).name.split("-", 1)[0])
        except (ValueError, IndexError):
            pass

    return task_entry.get("iteration", 9999)


def main() -> int:
    parser = argparse.ArgumentParser(description="Merge parallel benchmark results.")
    parser.add_argument("--run-dirs", nargs="*", default=[], help="Worker run directories to merge.")
    parser.add_argument("--existing-run-dir", help="Existing merged output directory to preserve and extend.")
    parser.add_argument("--output", required=True, help="Output directory for merged summary.")
    args = parser.parse_args()

    run_dirs = [pathlib.Path(d) for d in args.run_dirs]
    output_dir = pathlib.Path(args.output)
    existing_run_dir = pathlib.Path(args.existing_run_dir) if args.existing_run_dir else None

    if not run_dirs and existing_run_dir is None:
        print("Provide at least one --run-dirs entry or --existing-run-dir", file=sys.stderr)
        return 1

    for rd in run_dirs:
        if not rd.is_dir():
            print(f"Warning: run directory not found: {rd}", file=sys.stderr)
    if existing_run_dir is not None and not existing_run_dir.is_dir():
        print(f"Warning: existing run directory not found: {existing_run_dir}", file=sys.stderr)

    try:
        summary = merge(run_dirs, output_dir, existing_run_dir=existing_run_dir)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    total = len(summary["tasks"])
    failed = summary["failed_tasks"]
    print(f"Merged {total} tasks from {len(run_dirs)} workers ({failed} failed)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
