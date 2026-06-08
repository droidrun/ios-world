#!/usr/bin/env python3
"""
Split a tasks JSON file into N worker chunks using round-robin distribution.

Each output file is a valid tasks JSON array that can be passed directly to
appium_agent.py.  An ``_original_index`` field is injected into every task so
that merge_results.py can reconstruct the original ordering.

Usage:
  python3 scripts/split_tasks.py --tasks tasks.json --workers 4 --output-dir /tmp/split

Exit code 0 on success.  Prints the actual worker count to stdout (may be less
than requested if there are fewer tasks than workers).
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys


def split_tasks(tasks: list, workers: int) -> list[list]:
    """Round-robin distribute *tasks* into *workers* buckets."""
    actual = min(workers, len(tasks))
    buckets: list[list] = [[] for _ in range(actual)]
    for i, task in enumerate(tasks):
        task.setdefault("_original_index", i)
        buckets[i % actual].append(task)
    return buckets


def sanitize_task_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", name)[:80]


def task_output_dir_name(task: dict, original_index: int) -> str:
    task_name = task.get("name") or task.get("id") or f"task-{original_index + 1}"
    return f"{original_index + 1:02d}-{sanitize_task_name(task_name)}"


def task_label(task: dict, original_index: int) -> str:
    return task.get("name") or task.get("id") or f"task-{original_index + 1}"


def _build_existing_results_index(run_dir: pathlib.Path) -> dict[str, pathlib.Path]:
    """Map sanitized task name -> existing result directory path.

    Scans *run_dir* for subdirectories matching ``NN-<task_name>`` and indexes
    them by the task-name portion (everything after the first ``-``).
    """
    index: dict[str, pathlib.Path] = {}
    if not run_dir.is_dir():
        return index
    for entry in run_dir.iterdir():
        if not entry.is_dir():
            continue
        name = entry.name
        # Strip numeric prefix: "85-mem-001" -> "mem-001"
        parts = name.split("-", 1)
        if len(parts) == 2 and parts[0].isdigit():
            task_key = parts[1]
        else:
            task_key = name
        if task_key not in index:
            index[task_key] = entry
    return index


def task_result_complete(task: dict, task_json_path: pathlib.Path, require_evaluation: bool,
                         *, retry_failed: bool = False) -> bool:
    if not task_json_path.exists():
        return False
    try:
        task_data = json.loads(task_json_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return False

    status = task_data.get("status")
    if not isinstance(status, str) or not status:
        return False

    if status != "ok":
        # Safety-blocked tasks should never be retried — the LLM will just
        # block them again.
        if status == "safety_blocked":
            return True
        # When --retry-failed is set, treat failed tasks as incomplete so they
        # get re-queued for execution.
        if retry_failed:
            return False
        return True

    if require_evaluation and task.get("goal") and "evaluation" not in task_data:
        return False

    return True


def filter_pending_tasks(
    tasks: list[dict],
    existing_run_dir: pathlib.Path | None,
    require_evaluation: bool,
    *,
    retry_failed: bool = False,
) -> tuple[list[dict], int, list[str], list[str]]:
    if existing_run_dir is None:
        pending_labels = [task_label(task, index) for index, task in enumerate(tasks)]
        return tasks, 0, [], pending_labels

    pending: list[dict] = []
    skipped = 0
    skipped_labels: list[str] = []
    pending_labels: list[str] = []
    cleaned = 0

    results_index = _build_existing_results_index(existing_run_dir)

    for index, task in enumerate(tasks):
        task["_original_index"] = index
        label = task_label(task, index)
        task_name_key = sanitize_task_name(
            task.get("name") or task.get("id") or f"task-{index + 1}"
        )
        task_dir = results_index.get(task_name_key)
        if task_dir is None:
            pending.append(task)
            pending_labels.append(label)
            continue
        task_json_path = task_dir / "task.json"
        if task_result_complete(task, task_json_path, require_evaluation, retry_failed=retry_failed):
            skipped += 1
            skipped_labels.append(label)
            continue
        # If retrying a failed task, remove the old result directory so the
        # agent starts with a clean slate.
        if retry_failed and task_dir.exists():
            import shutil
            shutil.rmtree(task_dir)
            cleaned += 1
        pending.append(task)
        pending_labels.append(label)

    if cleaned:
        print(f"Cleaned {cleaned} failed task directories for retry.", file=sys.stderr)

    return pending, skipped, skipped_labels, pending_labels


def main() -> int:
    parser = argparse.ArgumentParser(description="Split a tasks JSON into N worker chunks.")
    parser.add_argument("--tasks", required=True, help="Path to the tasks JSON array file.")
    parser.add_argument("--workers", type=int, required=True, help="Desired number of workers.")
    parser.add_argument("--output-dir", required=True, help="Directory to write worker-N-tasks.json files.")
    parser.add_argument("--existing-run-dir", help="Optional final run directory to scan for completed task results.")
    parser.add_argument("--require-evaluation", action="store_true", help="Treat goal tasks without an evaluation result as incomplete.")
    parser.add_argument("--retry-failed", action="store_true", help="Re-run tasks that previously failed instead of skipping them.")
    parser.add_argument("--emit-json", action="store_true", help="Print split metadata as JSON instead of only the worker count.")
    args = parser.parse_args()

    if args.workers < 1:
        print("--workers must be >= 1", file=sys.stderr)
        return 1

    tasks_path = pathlib.Path(args.tasks)
    if not tasks_path.exists():
        print(f"Tasks file not found: {tasks_path}", file=sys.stderr)
        return 1

    try:
        raw = json.loads(tasks_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        print(f"Invalid JSON in tasks file {tasks_path}: {exc}", file=sys.stderr)
        return 1

    # Support the nested benchmark_tasks.json format by importing the
    # flattening logic from appium_agent (avoids duplicating the code).
    if isinstance(raw, dict) and ("single_app_tasks" in raw or "multi_app_tasks" in raw):
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "appium_agent", pathlib.Path(__file__).parent / "appium_agent.py"
        )
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        tasks = mod._flatten_benchmark_tasks(raw)
    else:
        tasks = raw

    if not isinstance(tasks, list) or not tasks:
        print("Tasks file must be a non-empty JSON array", file=sys.stderr)
        return 1

    existing_run_dir = pathlib.Path(args.existing_run_dir) if args.existing_run_dir else None
    pending_tasks, skipped_tasks, skipped_labels, pending_labels = filter_pending_tasks(
        tasks,
        existing_run_dir,
        args.require_evaluation,
        retry_failed=args.retry_failed,
    )
    if pending_tasks:
        buckets = split_tasks(pending_tasks, args.workers)
    else:
        buckets = []

    out_dir = pathlib.Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    for worker_id, bucket in enumerate(buckets):
        out_path = out_dir / f"worker-{worker_id}-tasks.json"
        out_path.write_text(json.dumps(bucket, indent=2), encoding="utf-8")

    result = {
        "actual_workers": len(buckets),
        "total_tasks": len(tasks),
        "pending_tasks": len(pending_tasks),
        "skipped_tasks": skipped_tasks,
        "skipped_task_labels": skipped_labels,
        "pending_task_labels": pending_labels,
    }
    if args.emit_json:
        print(json.dumps(result))
    else:
        print(len(buckets))
    return 0


if __name__ == "__main__":
    sys.exit(main())
