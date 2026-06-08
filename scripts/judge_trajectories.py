#!/usr/bin/env python3
"""Re-judge an existing benchmark run without re-running the agent.

Walks ``--run-dir`` (a ``results/run-*`` directory produced by
``appium_agent.py`` / ``run_benchmark.sh`` / ``bootstrap_release.sh``),
loads each per-task ``trajectory.json``, looks up the task's rubric in
``tasks.json``, calls the trajectory judge from
``llm_action_generator.evaluate_trajectory``, writes the result back into
the task's ``task.json``, and recomputes ``summary.json`` with pass-rate
    and rubric-score aggregates. Rubric criteria are weighted uniformly —
    there is no per-criterion weighting. Override the default judge with
    ``EVAL_PROVIDER`` / ``EVAL_MODEL`` or ``--judge-provider`` /
    ``--judge-model``.

Examples:

    # Re-judge an entire run (skips tasks that already have an evaluation)
    python scripts/judge_trajectories.py --run-dir results/run-iphone-17-pro-...

    # Force re-judge — useful after swapping judge model
    EVAL_MODEL=gpt-5.4 python scripts/judge_trajectories.py \\
        --run-dir results/run-iphone-17-pro-... --re-judge

    # Judge only specific tasks
    python scripts/judge_trajectories.py \\
        --run-dir results/run-iphone-17-pro-... \\
        --task clock-001 --task mybank-003

Environment:
    OPENAI_API_KEY            Required for the default GPT-5.4 Mini judge.
    EVAL_PROVIDER             Judge provider (default: openai).
    EVAL_MODEL                Judge model (default: gpt-5.4-mini).
    EVAL_MAX_SCREENSHOTS      Per-task screenshot cap sent to the judge
                              (default: 10; older steps go text-only).
    EVAL_TRAJ_CHAR_BUDGET     Total per-task trajectory char budget
                              (default: 520000).
    EVAL_MAX_WORKERS          Parallel judge calls (default: 4).
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import pathlib
import sys
from typing import Any, Dict, List, Optional

_SCRIPTS = pathlib.Path(__file__).resolve().parent
_ROOT = _SCRIPTS.parent
sys.path.insert(0, str(_SCRIPTS))


def _load_rubric_index(tasks_path: pathlib.Path) -> Dict[str, List[Dict[str, Any]]]:
    """Map task name → rubric, looked up from the canonical tasks file."""
    try:
        data = json.loads(tasks_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"ERROR: tasks file not found: {tasks_path}")
    except json.JSONDecodeError as e:
        raise SystemExit(f"ERROR: tasks file is not valid JSON ({tasks_path}): {e}")
    if not isinstance(data, list):
        raise SystemExit(
            f"ERROR: expected {tasks_path} to be a JSON array of task objects."
        )
    out: Dict[str, List[Dict[str, Any]]] = {}
    for t in data:
        name = t.get("name") or t.get("id")
        if name:
            out[name] = t.get("rubric") or []
    return out


def _discover_task_dirs(run_dir: pathlib.Path) -> List[pathlib.Path]:
    """Return the per-task subdirectories under *run_dir*.

    Each per-task dir has the shape ``<NN>-<task-name>/`` with a
    ``task.json`` and ``trajectory.json`` inside.
    """
    dirs: List[pathlib.Path] = []
    for child in sorted(run_dir.iterdir()):
        if child.is_dir() and (child / "task.json").exists():
            dirs.append(child)
    return dirs


def _task_name_from_dir(task_dir: pathlib.Path) -> str:
    """Best-effort task name from the dir.

    Per-task dirs use the convention ``NN-<task-name>`` (e.g.
    ``01-clock-001``); strip the leading index so we match the task file.
    The on-disk ``task.json`` wins when its ``task`` field is set.
    """
    try:
        meta = json.loads((task_dir / "task.json").read_text(encoding="utf-8"))
        name = meta.get("task")
        if name:
            return name
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    stem = task_dir.name
    head, _, tail = stem.partition("-")
    return tail if head.isdigit() and tail else stem


def _judge_one(
    task_dir: pathlib.Path,
    rubric_index: Dict[str, List[Dict[str, Any]]],
    judge_provider: Optional[str],
    judge_model: Optional[str],
    force: bool,
) -> Dict[str, Any]:
    """Re-judge a single task directory in place."""
    task_json_path = task_dir / "task.json"
    traj_path = task_dir / "trajectory.json"
    task_data = json.loads(task_json_path.read_text(encoding="utf-8"))
    task_name = task_data.get("task") or _task_name_from_dir(task_dir)

    if task_data.get("status") not in ("ok", None):
        return {
            "task": task_name, "task_dir": str(task_dir),
            "status": "skipped_failed_task",
            "reasoning": f"agent run status was {task_data.get('status')!r}",
        }
    if not force and task_data.get("evaluation"):
        return {
            "task": task_name, "task_dir": str(task_dir),
            "status": "skipped_already_judged",
            "evaluation": task_data["evaluation"],
        }

    try:
        trajectory = json.loads(traj_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {
            "task": task_name, "task_dir": str(task_dir),
            "status": "error",
            "reasoning": f"missing {traj_path.name}",
        }

    goal = task_data.get("goal") or ""
    if not goal:
        return {
            "task": task_name, "task_dir": str(task_dir),
            "status": "error",
            "reasoning": "task.json has no goal",
        }
    rubric = rubric_index.get(task_name) or []

    # Import lazily so a malformed run dir doesn't import the heavy LLM module.
    import llm_action_generator as lag
    eval_kwargs = {
        "agent_answer": task_data.get("agent_answer"),
        "rubric": rubric or None,
    }
    if judge_provider:
        eval_kwargs["provider"] = judge_provider
    if judge_model:
        eval_kwargs["model"] = judge_model
    try:
        result = lag.evaluate_trajectory(goal, trajectory, **eval_kwargs)
    except BaseException as exc:  # noqa: BLE001 — surface judge errors per-task
        return {
            "task": task_name, "task_dir": str(task_dir),
            "status": "error",
            "reasoning": f"Judge call failed: {type(exc).__name__}: {exc}",
        }

    task_data["evaluation"] = result
    task_json_path.write_text(json.dumps(task_data, indent=2), encoding="utf-8")
    return {
        "task": task_name, "task_dir": str(task_dir),
        "status": "ok",
        "evaluation": result,
    }


def _aggregate(per_task: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Compute pass rate + mean rubric score across judged tasks.

    Rubric criteria are weighted uniformly — every criterion counts equally.
    Pass rate counts only tasks with full rubric satisfaction (every
    criterion satisfied). Rubric score is the mean of
    ``n_satisfied / n_criteria`` across judged tasks. Skipped or errored
    tasks are excluded from both means but reported separately.
    """
    judged = [r for r in per_task if r.get("status") == "ok"]
    n = len(judged)
    if n == 0:
        return {"judged_tasks": 0, "pass_rate": None, "rubric_score": None,
                "passes": 0, "fails": 0}
    passes = 0
    score_sum = 0.0
    for r in judged:
        ev = r["evaluation"]
        score = float(ev.get("score") or 0.0)
        score_sum += score
        # Paper's pass-rate definition: every rubric criterion satisfied.
        # When no rubric is present, fall back to the judge's success bool.
        rubric_results = ev.get("rubric_results")
        if rubric_results is not None:
            full = bool(rubric_results) and all(
                rr.get("satisfied") for rr in rubric_results
            )
        else:
            full = bool(ev.get("success"))
        if full:
            passes += 1
    return {
        "judged_tasks": n,
        "passes": passes,
        "fails": n - passes,
        "pass_rate": round(passes / n, 4),
        "rubric_score": round(score_sum / n, 4),
    }


def _result_from_task_json(task_dir: pathlib.Path) -> Optional[Dict[str, Any]]:
    task_json_path = task_dir / "task.json"
    if not task_json_path.exists():
        return None
    try:
        task_data = json.loads(task_json_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    evaluation = task_data.get("evaluation")
    if not evaluation:
        return None
    return {
        "task": _task_name_from_dir(task_dir),
        "task_dir": str(task_dir),
        "status": "ok",
        "evaluation": evaluation,
    }


def _summary_task_key(entry: Dict[str, Any], run_dir: pathlib.Path) -> tuple[str, str]:
    task = str(entry.get("task") or "")
    task_dir = entry.get("task_dir") or ""
    if task_dir:
        try:
            normalized = str(pathlib.Path(task_dir).resolve())
        except OSError:
            normalized = str(run_dir / task_dir)
    else:
        normalized = ""
    return task, normalized


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--run-dir", required=True, help="results/run-* directory with per-task subdirs.")
    p.add_argument("--tasks", default=str(_ROOT / "tasks.json"),
                   help="Tasks file for rubric lookup. Default: repo-root tasks.json.")
    p.add_argument("--task", action="append", default=[],
                   help="Only judge this task name (repeatable). Default: every task in the run.")
    p.add_argument("--re-judge", action="store_true",
                   help="Re-judge tasks that already have an evaluation (overwrites).")
    p.add_argument("--workers", type=int, default=int(os.getenv("EVAL_MAX_WORKERS", "4")),
                   help="Parallel judge calls. Default: 4 (env: EVAL_MAX_WORKERS).")
    p.add_argument("--judge-provider", default=None,
                   help="Judge provider override (default: $EVAL_PROVIDER or 'openai').")
    p.add_argument("--judge-model", default=None,
                   help="Judge model override (default: $EVAL_MODEL or 'gpt-5.4-mini').")
    args = p.parse_args()

    run_dir = pathlib.Path(args.run_dir).resolve()
    if not run_dir.is_dir():
        print(f"ERROR: --run-dir not found: {run_dir}", file=sys.stderr)
        return 2

    tasks_path = pathlib.Path(args.tasks).resolve()
    rubric_index = _load_rubric_index(tasks_path)

    task_dirs = _discover_task_dirs(run_dir)
    if args.task:
        wanted = set(args.task)
        task_dirs = [d for d in task_dirs if _task_name_from_dir(d) in wanted]
    if not task_dirs:
        print(f"ERROR: no per-task subdirs found under {run_dir}", file=sys.stderr)
        return 2

    judge_model = args.judge_model or os.getenv("EVAL_MODEL", "gpt-5.4-mini")
    judge_provider = args.judge_provider or os.getenv("EVAL_PROVIDER", "openai")
    print(f"[judge] run-dir: {run_dir}")
    print(f"[judge] tasks: {len(task_dirs)} | provider: {judge_provider} | model: {judge_model}")
    print(f"[judge] re-judge: {args.re_judge} | workers: {args.workers}")
    print()

    results: List[Dict[str, Any]] = []
    workers = max(1, min(args.workers, len(task_dirs)))
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {
            pool.submit(
                _judge_one, d, rubric_index,
                args.judge_provider, args.judge_model, args.re_judge,
            ): d for d in task_dirs
        }
        for fut in concurrent.futures.as_completed(futures):
            r = fut.result()
            results.append(r)
            ev = r.get("evaluation") or {}
            score = ev.get("score")
            success = ev.get("success")
            tag = {
                "ok": "PASS" if ev.get("rubric_results")
                    and all(rr.get("satisfied") for rr in ev["rubric_results"])
                    else ("PASS" if success and not ev.get("rubric_results") else "PART"),
                "skipped_already_judged": "skip",
                "skipped_failed_task": "skip",
                "error": "ERR ",
            }.get(r["status"], "?   ")
            if r["status"] == "ok":
                score_s = f"{score:.2f}" if score is not None else "  - "
                print(f"  [{tag}] {r['task']:30s} score={score_s}")
            else:
                reason = r.get("reasoning") or r["status"]
                print(f"  [{tag}] {r['task']:30s} ({reason})")

    print()
    all_results = [
        r for r in (_result_from_task_json(d) for d in _discover_task_dirs(run_dir))
        if r is not None
    ]
    agg = _aggregate(all_results)
    if agg["judged_tasks"]:
        print("───── Run summary ─────────────────────────────────────")
        print(f"  Judged tasks:      {agg['judged_tasks']}")
        print(f"  Pass rate:         {agg['pass_rate'] * 100:.1f}%  "
              f"({agg['passes']}/{agg['judged_tasks']})")
        print(f"  Rubric score:      {agg['rubric_score']:.3f}")
    else:
        print("───── No tasks were judged (all skipped or errored). ─────")

    # Refresh summary.json with per-task evaluations and aggregates.
    summary_path = run_dir / "summary.json"
    summary: Dict[str, Any] = {}
    if summary_path.exists():
        try:
            summary = json.loads(summary_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            summary = {}
    summary.setdefault("run_dir", str(run_dir))
    # Patch evaluations into the existing task list (matched by task name +
    # task_dir). If the run had no summary.json yet, build a flat list.
    existing = summary.get("tasks") or []
    by_name: Dict[tuple[str, str], Dict[str, Any]] = {}
    out_tasks: List[Dict[str, Any]] = []
    for entry in existing:
        key = _summary_task_key(entry, run_dir)
        if key in by_name:
            continue
        by_name[key] = entry
        out_tasks.append(entry)
    for r in all_results:
        if r["status"] != "ok":
            continue
        key = (r["task"], r["task_dir"])
        entry = by_name.get(key)
        if entry is None:
            entry = {"task": r["task"], "task_dir": r["task_dir"]}
            out_tasks.append(entry)
        entry["evaluation"] = r["evaluation"]
    summary["tasks"] = out_tasks
    summary["judge"] = {
        "provider": judge_provider, "model": judge_model,
        **agg,
    }
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"\n  → wrote {summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
