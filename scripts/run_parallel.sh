#!/usr/bin/env bash
# Parallel benchmark runner: clones simulators, splits tasks, launches N
# independent run_benchmark.sh workers, then merges results.
#
# Typically invoked by bootstrap_release.sh when --workers > 1, but can also
# be called directly:
#
#   scripts/run_parallel.sh \
#     --workers 4 \
#     --source-udid <UDID> \
#     --tasks tasks.json \
#     --device-name "iPhone 17 Pro" \
#     --platform-version 26.2 \
#     [any other run_benchmark.sh flags]
set -euo pipefail

WALL_START=$SECONDS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
POOL_STATE_FILE="${PARALLEL_SIM_POOL_STATE_FILE:-$REPO_ROOT/iphone/bootstrap/.last_parallel_pool.json}"

usage() {
  cat <<'EOF'
Usage: scripts/run_parallel.sh --workers N --source-udid <UDID> --tasks <file> [options]

Required:
  --workers <N>             Number of parallel workers.
  --source-udid <UDID>      UDID of the source simulator (apps already installed).
  --tasks <file>            Tasks JSON file.

Options:
  --device-name <name>      Simulator device name (default: "iPhone 17 Pro").
  --platform-version <v>    iOS version (e.g., 26.2).
  --run-dir <dir>           Base results directory for this run.
  --keep-sims               Do not delete cloned simulators on exit.
  --reuse-sims              Reuse the last kept simulator pool instead of cloning.
  --base-port <port>        Starting Appium port (default: 4723).

All other flags are passed through to run_benchmark.sh (e.g., --action-mode,
--max-steps, --evaluate, --skip-erase, --inprocess, etc.).
EOF
}

# ── Defaults ──────────────────────────────────────────────────────────────
WORKERS=""
SOURCE_UDID=""
TASKS=""
DEVICE_NAME="iPhone 17 Pro"
PLATFORM_VERSION=""
RUN_DIR=""
KEEP_SIMS=0
REUSE_SIMS=0
BASE_PORT=4723
WDA_BASE_PORT=8100
ACTIVE_BASE_PORT="$BASE_PORT"
ACTIVE_WDA_BASE_PORT="$WDA_BASE_PORT"
PASSTHROUGH_ARGS=()
TASKS_REQUIRE_EVALUATION=0
RETRY_FAILED=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workers)          WORKERS="$2"; shift 2 ;;
    --source-udid)      SOURCE_UDID="$2"; shift 2 ;;
    --tasks)            TASKS="$2"; shift 2 ;;
    --device-name)      DEVICE_NAME="$2"; shift 2 ;;
    --platform-version) PLATFORM_VERSION="$2"; shift 2 ;;
    --run-dir)          RUN_DIR="$2"; shift 2 ;;
    --keep-sims)        KEEP_SIMS=1; shift 1 ;;
    --reuse-sims)       REUSE_SIMS=1; shift 1 ;;
    --retry-failed)     RETRY_FAILED=1; shift 1 ;;
    --base-port)        BASE_PORT="$2"; shift 2 ;;
    --help|-h)          usage; exit 0 ;;
    # Everything else is passed through to run_benchmark.sh.
    *)                  PASSTHROUGH_ARGS+=("$1"); shift 1 ;;
  esac
done

append_error_log() {
  local level="$1"
  shift
  [[ -n "${ERROR_LOG_FILE:-}" ]] || return 0
  printf '[%s] %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$ERROR_LOG_FILE"
}

append_file_tail_to_error_log() {
  local label="$1"
  local path="$2"
  local lines="${3:-40}"

  [[ -n "${ERROR_LOG_FILE:-}" ]] || return 0
  [[ -f "$path" ]] || return 0

  {
    printf '[%s] INFO %s (%s, last %s lines)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$label" "$path" "$lines"
    tail -n "$lines" "$path"
    printf '\n'
  } >> "$ERROR_LOG_FILE"
}

die() {
  append_error_log "ERROR" "$*"
  echo "ERROR: $*" >&2
  echo "" >&2
  usage >&2
  exit 1
}
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

[[ -n "$WORKERS" ]]     || die "Missing --workers"
[[ -n "$SOURCE_UDID" ]] || die "Missing --source-udid"
[[ -n "$TASKS" ]]       || die "Missing --tasks"
[[ -f "$TASKS" ]]       || die "Tasks file not found: $TASKS"
[[ "$WORKERS" -ge 1 ]]  || die "--workers must be >= 1"
cmd_exists lsof || die "lsof not found; required for worker port preflight checks."

# ── Memory preflight ──────────────────────────────────────────────────────
# Each booted iOS sim + WebDriverAgent + Appium worker consumes ~4 GB RSS in
# practice (measured on M-series with iOS 26 sims). Reject launches that would
# obviously OOM the machine. Override with MEM_PER_WORKER_GB or skip entirely
# with SKIP_MEM_PREFLIGHT=1.
if [[ "${SKIP_MEM_PREFLIGHT:-0}" != "1" ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    total_ram_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
    page_size="$(sysctl -n hw.pagesize 2>/dev/null || echo 16384)"
    vm_free_pages="$(vm_stat 2>/dev/null | awk '/Pages free/ {gsub(/\./,"",$3); print $3+0; exit}')"
    vm_inactive_pages="$(vm_stat 2>/dev/null | awk '/Pages inactive/ {gsub(/\./,"",$3); print $3+0; exit}')"
    vm_speculative_pages="$(vm_stat 2>/dev/null | awk '/Pages speculative/ {gsub(/\./,"",$3); print $3+0; exit}')"
    : "${vm_free_pages:=0}"; : "${vm_inactive_pages:=0}"; : "${vm_speculative_pages:=0}"
    # "Available" ≈ free + inactive + speculative (kernel can reclaim these).
    avail_bytes=$(( (vm_free_pages + vm_inactive_pages + vm_speculative_pages) * page_size ))
    avail_gb=$(( avail_bytes / 1024 / 1024 / 1024 ))
    total_gb=$(( total_ram_bytes / 1024 / 1024 / 1024 ))
    mem_per_worker_gb="${MEM_PER_WORKER_GB:-4}"
    required_gb=$(( WORKERS * mem_per_worker_gb ))
    printf '[mem-preflight] total=%dGB available=%dGB required=%dGB (%d workers × %d GB)\n' \
      "$total_gb" "$avail_gb" "$required_gb" "$WORKERS" "$mem_per_worker_gb"
    if (( avail_gb < required_gb )); then
      die "Insufficient memory: need ${required_gb}GB for $WORKERS workers but only ${avail_gb}GB available (of ${total_gb}GB total). Close other apps, reduce --workers, or set SKIP_MEM_PREFLIGHT=1 to override."
    fi
  fi
fi

if [[ ${#PASSTHROUGH_ARGS[@]} -gt 0 ]]; then
  for arg in "${PASSTHROUGH_ARGS[@]}"; do
    if [[ "$arg" == "--evaluate" ]]; then
      TASKS_REQUIRE_EVALUATION=1
      break
    fi
  done
fi

list_listening_pids() {
  local port="$1"
  lsof -nP -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk '!seen[$0]++'
}

port_is_available() {
  local port="$1"
  [[ -z "$(list_listening_pids "$port")" ]]
}

port_block_available() {
  local start_port="$1"
  local count="$2"
  local i

  for i in $(seq 0 $((count - 1))); do
    if ! port_is_available $((start_port + i)); then
      return 1
    fi
  done

  return 0
}

port_blocks_overlap() {
  local start_a="$1"
  local count_a="$2"
  local start_b="$3"
  local count_b="$4"
  local end_a=$((start_a + count_a - 1))
  local end_b=$((start_b + count_b - 1))

  (( start_a <= end_b && start_b <= end_a ))
}

find_available_port_block() {
  local start_port="$1"
  local count="$2"
  local label="$3"
  local max_tries="${4:-200}"
  local candidate="$start_port"
  local tries=0

  while [[ "$tries" -lt "$max_tries" ]]; do
    if port_block_available "$candidate" "$count"; then
      echo "$candidate"
      return 0
    fi
    candidate=$((candidate + 1))
    tries=$((tries + 1))
  done

  die "Could not find $count consecutive free $label ports starting at $start_port."
}

print_port_conflict() {
  local port="$1"
  local label="$2"
  local pids pid details

  pids="$(list_listening_pids "$port")"
  [[ -n "$pids" ]] || return 1

  echo "$label port $port is already in use:" >&2
  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    details="$(ps -o pid=,user=,command= -p "$pid" 2>/dev/null | sed 's/^[[:space:]]*//')"
    if [[ -n "$details" ]]; then
      echo "  $details" >&2
    else
      echo "  pid $pid" >&2
    fi
  done <<EOF
$pids
EOF
  return 0
}

resolve_worker_port_bases() {
  local worker_count="$1"
  [[ "$worker_count" -ge 1 ]] || return 0
  ACTIVE_BASE_PORT="$BASE_PORT"
  ACTIVE_WDA_BASE_PORT="$WDA_BASE_PORT"

  if ! port_block_available "$ACTIVE_BASE_PORT" "$worker_count"; then
    ACTIVE_BASE_PORT="$(find_available_port_block "$BASE_PORT" "$worker_count" "Appium")"
    echo "Preflight: Appium ports ${BASE_PORT}-$((BASE_PORT + worker_count - 1)) are busy; using ${ACTIVE_BASE_PORT}-$((ACTIVE_BASE_PORT + worker_count - 1)) instead."
  fi

  if ! port_block_available "$ACTIVE_WDA_BASE_PORT" "$worker_count"; then
    ACTIVE_WDA_BASE_PORT="$(find_available_port_block "$WDA_BASE_PORT" "$worker_count" "WDA")"
    echo "Preflight: WDA ports ${WDA_BASE_PORT}-$((WDA_BASE_PORT + worker_count - 1)) are busy; using ${ACTIVE_WDA_BASE_PORT}-$((ACTIVE_WDA_BASE_PORT + worker_count - 1)) instead."
  fi

  if port_blocks_overlap "$ACTIVE_BASE_PORT" "$worker_count" "$ACTIVE_WDA_BASE_PORT" "$worker_count"; then
    ACTIVE_WDA_BASE_PORT="$(find_available_port_block $((ACTIVE_BASE_PORT + worker_count)) "$worker_count" "WDA")"
    echo "Preflight: Adjusted WDA ports to ${ACTIVE_WDA_BASE_PORT}-$((ACTIVE_WDA_BASE_PORT + worker_count - 1)) to avoid overlap with Appium ports."
  fi
}

save_pool_state() {
  python3 - "$POOL_STATE_FILE" "$SOURCE_UDID" "$DEVICE_NAME" "$PLATFORM_VERSION" "$BASE_PORT" "${CLONE_UDIDS[@]}" <<'PY'
import json
import os
import sys

path, source_udid, device_name, platform_version, base_port = sys.argv[1:6]
clone_udids = sys.argv[6:]
directory = os.path.dirname(path)
if directory:
    os.makedirs(directory, exist_ok=True)

data = {
    "source_udid": source_udid,
    "workers": len(clone_udids),
    "device_name": device_name,
    "platform_version": platform_version,
    "base_port": int(base_port),
    "clone_udids": clone_udids,
}

with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
}

parse_clone_udids_from_pool_json() {
  python3 -c '
import json
import sys

data = json.loads(sys.argv[1])
for clone in data.get("clones", []):
    udid = clone.get("udid")
    if udid:
        print(udid)
' "$1"
}

ensure_benchmark_identity() {
  python3 - "$TASKS" "$BENCHMARK_ID_FILE" <<'PY'
import hashlib
import json
import pathlib
import sys

tasks_path = pathlib.Path(sys.argv[1]).resolve()
identity_path = pathlib.Path(sys.argv[2])
identity_path.parent.mkdir(parents=True, exist_ok=True)
payload = {
    "tasks_file": str(tasks_path),
    "tasks_sha256": hashlib.sha256(tasks_path.read_bytes()).hexdigest(),
}

if identity_path.exists():
    existing = json.loads(identity_path.read_text(encoding="utf-8"))
    if existing.get("tasks_sha256") != payload["tasks_sha256"]:
        raise SystemExit(
            f"Existing results at {identity_path.parent} were created for a different benchmark input. "
            f"Current task file: {tasks_path}"
        )

identity_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
}

parse_split_plan_field() {
  local split_json="$1"
  local field="$2"
  python3 -c 'import json,sys; print(json.loads(sys.argv[1])[sys.argv[2]])' "$split_json" "$field"
}

parse_split_plan_lines() {
  local split_json="$1"
  local field="$2"
  python3 -c '
import json
import sys

value = json.loads(sys.argv[1]).get(sys.argv[2], [])
if isinstance(value, list):
    for item in value:
        print(item)
elif value is not None:
    print(value)
' "$split_json" "$field"
}

preview_task_labels() {
  local limit="$1"
  shift
  local count="$#"
  local shown=0
  local preview=""
  local label

  for label in "$@"; do
    if [[ "$shown" -ge "$limit" ]]; then
      break
    fi
    if [[ -n "$preview" ]]; then
      preview+=", "
    fi
    preview+="$label"
    shown=$((shown + 1))
  done

  if [[ "$count" -gt "$limit" ]]; then
    preview+=" (+$((count - limit)) more)"
  fi

  echo "$preview"
}

copy_worker_appium_log() {
  local worker_index="$1"
  local worker_run_dir="$2"
  local src="$worker_run_dir/appium-server.log"
  local dest="$LOGS_DIR/appium-worker-$worker_index.log"
  if [[ -f "$src" ]]; then
    cp "$src" "$dest"
  fi
}

load_pool_state() {
  local pool_output

  if ! pool_output="$(python3 - "$POOL_STATE_FILE" "$SOURCE_UDID" "$WORKERS" <<'PY'
import json
import os
import sys

path, expected_source_udid, expected_workers = sys.argv[1], sys.argv[2], int(sys.argv[3])
if not os.path.exists(path):
    raise SystemExit(f"No saved simulator pool found at {path}. Run once with --keep-sims first.")

with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

source_udid = data.get("source_udid")
clone_udids = data.get("clone_udids") or []
workers = int(data.get("workers", len(clone_udids)))

if source_udid != expected_source_udid:
    raise SystemExit(
        f"Saved simulator pool source UDID {source_udid} does not match requested source UDID {expected_source_udid}."
    )
if workers != expected_workers or len(clone_udids) != expected_workers:
    raise SystemExit(
        f"Saved simulator pool has {len(clone_udids)} clones but this run requested {expected_workers} workers."
    )

for udid in clone_udids:
    print(udid)
PY
)"; then
    die "$pool_output"
  fi

  CLONE_UDIDS=()
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    CLONE_UDIDS+=("$line")
  done <<EOF
$pool_output
EOF
}

boot_existing_pool() {
  for i in "${!CLONE_UDIDS[@]}"; do
    local udid="${CLONE_UDIDS[$i]}"
    echo "Booting Bench-Worker-$i ($udid)..."
    xcrun simctl boot "$udid" 2>/dev/null || true
    if [[ "${PARALLEL_SKIP_BOOTSTATUS:-0}" -eq 1 ]]; then
      echo "Skipping bootstatus for Bench-Worker-$i ($udid) because PARALLEL_SKIP_BOOTSTATUS=1."
      continue
    fi
    if ! xcrun simctl bootstatus "$udid" -b; then
      echo "Warning: simctl bootstatus failed for Bench-Worker-$i ($udid); continuing because the worker/Appium preflight will verify device readiness." >&2
    fi
  done
}

worker_progress_summary() {
  local worker_index="$1"
  local log_path="$2"
  local total_tasks="$3"
  python3 - "$worker_index" "$log_path" "$total_tasks" <<'PY'
import json
import os
import sys

worker_index = int(sys.argv[1])
log_path = sys.argv[2]
total_tasks = int(sys.argv[3])
bar_width = 20

completed = 0
status = "running"

if not os.path.exists(log_path):
    bar = "-" * bar_width
    print(f"  Worker {worker_index}: [{bar}] 0/{total_tasks} tasks | waiting")
    raise SystemExit(0)

with open(log_path, "r", encoding="utf-8", errors="replace") as fh:
    for raw_line in fh:
        line = raw_line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except Exception:
            continue

        event = entry.get("event")
        if not event:
            continue

        if event == "task_complete":
            completed += 1
        elif event == "complete":
            status = "complete"
        elif event in {"task_error", "task_timeout"}:
            status = "running"

completed = max(0, min(completed, total_tasks))
filled = bar_width if total_tasks <= 0 else int((completed / total_tasks) * bar_width)
filled = max(0, min(filled, bar_width))
bar = "#" * filled + "-" * (bar_width - filled)

parts = [f"  Worker {worker_index}: [{bar}] {completed}/{total_tasks} tasks"]
if status == "complete":
    parts.append("done")
elif completed >= total_tasks and total_tasks > 0:
    parts.append("finalizing")

print(" | ".join(parts))
PY
}

overall_task_progress_summary() {
  python3 - "$TOTAL_TASKS" "$SKIPPED_TASKS" ${WORKER_LOGS[@]+"${WORKER_LOGS[@]}"} <<'PY'
import json
import os
import sys

total_tasks = int(sys.argv[1])
completed = int(sys.argv[2])
for path in sys.argv[3:]:
    if not os.path.exists(path):
        continue
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for raw_line in fh:
            line = raw_line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except Exception:
                continue
            if entry.get("event") == "task_complete":
                completed += 1

completed = max(0, min(completed, total_tasks))
left = max(0, total_tasks - completed)
print(f"  Task progress: {completed}/{total_tasks} complete | {left} left")
PY
}

record_worker_error_events() {
  local worker_index="$1"
  local log_path="$2"
  local exit_code="$3"

  [[ -n "${ERROR_LOG_FILE:-}" ]] || return 0

  python3 - "$worker_index" "$log_path" "$exit_code" "$ERROR_LOG_FILE" <<'PY'
import json
import os
import sys
from datetime import datetime

worker_index = sys.argv[1]
log_path = sys.argv[2]
exit_code = int(sys.argv[3])
error_log_path = sys.argv[4]

entries = []
if os.path.exists(log_path):
    with open(log_path, "r", encoding="utf-8", errors="replace") as fh:
        for raw_line in fh:
            line = raw_line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except Exception:
                if "ERROR" in line or "Traceback" in line:
                    entries.append(f"Worker {worker_index} raw log: {line}")
                continue

            event = entry.get("event", "")
            if event.endswith("_error") or event.endswith("_timeout"):
                details = []
                task = entry.get("task")
                step = entry.get("step")
                error = entry.get("error")
                if task:
                    details.append(f"task={task}")
                if step is not None:
                    details.append(f"step={step}")
                if error:
                    details.append(f"error={error}")
                suffix = f" ({', '.join(details)})" if details else ""
                entries.append(f"Worker {worker_index} {event}{suffix}")
            elif event == "task_complete" and entry.get("status") not in {None, 'ok'}:
                details = [f"task={entry.get('task', '?')}", f"status={entry.get('status')}"]
                if entry.get("error"):
                    details.append(f"error={entry['error']}")
                entries.append(f"Worker {worker_index} task_complete ({', '.join(details)})")
            elif event == "evaluation" and not entry.get("success", False):
                details = [f"task={entry.get('task', '?')}"]
                if entry.get("reasoning"):
                    details.append(f"reasoning={entry['reasoning']}")
                entries.append(f"Worker {worker_index} evaluation_failed ({', '.join(details)})")

if exit_code != 0:
    entries.insert(0, f"Worker {worker_index} exited with status {exit_code}")

if not entries:
    raise SystemExit(1)

timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
with open(error_log_path, "a", encoding="utf-8") as fh:
    for line in entries:
        fh.write(f"[{timestamp}] ERROR {line}\n")
PY
}

collect_worker_progress_snapshot() {
  for i in "${!WORKER_PIDS[@]}"; do
    worker_progress_summary "$i" "${WORKER_LOGS[$i]}" "${WORKER_TASK_COUNTS[$i]}"
  done
}

worker_process_exited() {
  local pid="$1"
  local proc_state

  proc_state="$(ps -p "$pid" -o stat= 2>/dev/null | tr -d '[:space:]')"
  [[ -z "$proc_state" || "$proc_state" == Z* ]]
}

# ── Run directory ─────────────────────────────────────────────────────────
ts="$(date +%Y%m%d-%H%M%S)"
slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }
device_slug="$(slug "$DEVICE_NAME")"
RUN_BASE="${ARTIFACT_DIR:-results}"
RUN_DIR="${RUN_DIR:-$RUN_BASE/run-${device_slug}-${ts}}"
mkdir -p "$RUN_DIR"
LOGS_DIR="$RUN_DIR/logs"
mkdir -p "$LOGS_DIR"

# ── Guard against concurrent runs on the same RUN_DIR ─────────────────────
LOCK_FILE="$LOGS_DIR/.run_parallel.lock"
if [[ -f "$LOCK_FILE" ]]; then
  existing_pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
  if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    die "Another run_parallel.sh (pid $existing_pid) is already running in $RUN_DIR. Aborting to avoid conflicts."
  else
    echo "NOTE: Stale lock file found (pid $existing_pid no longer running). Removing." >&2
    rm -f "$LOCK_FILE"
  fi
fi
echo $$ > "$LOCK_FILE"

ERROR_LOG_FILE="$LOGS_DIR/errors-$(date +%Y%m%d-%H%M%S).log"
touch "$ERROR_LOG_FILE"
append_error_log "INFO" "run_parallel.sh started"
BENCHMARK_ID_FILE="$RUN_DIR/benchmark_identity.json"
ensure_benchmark_identity

echo ""
echo "============================================"
echo "  Parallel benchmark: $WORKERS workers"
echo "  Source simulator: $SOURCE_UDID"
echo "  Tasks: $TASKS"
echo "  Results: $RUN_DIR"
echo "  Error log: $ERROR_LOG_FILE"
echo "============================================"
echo ""

# ── Temp directory for task splits ────────────────────────────────────────
SPLIT_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/bench-split-XXXXXX")"
WORKER_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/bench-workers-XXXXXX")"
CLONE_UDIDS=()
WORKER_PIDS=()
WORKER_DIRS=()
WORKER_LOGS=()
WORKER_TASK_COUNTS=()
WORKER_FINISHED=()
POOL_STATE_ACTIVE=0
SKIPPED_TASK_LABELS=()
PENDING_TASK_LABELS=()

cleanup() {
  local status=$?

  if [[ "$status" -ne 0 ]]; then
    append_error_log "ERROR" "run_parallel.sh exiting with status $status"
  else
    append_error_log "INFO" "run_parallel.sh completed successfully"
  fi

  echo ""
  echo "Cleaning up..."

  # Kill any still-running workers.
  if [[ ${#WORKER_PIDS[@]} -gt 0 ]]; then
    for pid in "${WORKER_PIDS[@]}"; do
      kill "$pid" 2>/dev/null || true
    done
  fi

  # Delete cloned simulators.
  if [[ "$KEEP_SIMS" -ne 1 ]] && [[ ${#CLONE_UDIDS[@]} -gt 0 ]]; then
    echo "Deleting ${#CLONE_UDIDS[@]} cloned simulators..."
    for udid in "${CLONE_UDIDS[@]}"; do
      xcrun simctl shutdown "$udid" 2>/dev/null || true
      xcrun simctl delete "$udid" 2>/dev/null || true
    done
    if [[ "$POOL_STATE_ACTIVE" -eq 1 ]]; then
      rm -f "$POOL_STATE_FILE"
    fi
  elif [[ "$KEEP_SIMS" -eq 1 ]] && [[ ${#CLONE_UDIDS[@]} -gt 0 ]]; then
    echo "Keeping ${#CLONE_UDIDS[@]} cloned simulators for reuse."
    echo "Saved simulator pool: $POOL_STATE_FILE"
  fi

  # Remove temp task splits.
  rm -rf "$SPLIT_TMPDIR"
  rm -rf "$WORKER_TMPDIR"

  # Release run lock.
  rm -f "${LOCK_FILE:-}"

  echo "Cleanup complete."
}
trap cleanup EXIT

# ── Phase 1: Create or reuse simulator pool ───────────────────────────────
if [[ "$REUSE_SIMS" -eq 1 ]]; then
  echo "Phase 1: Reusing $WORKERS simulators from saved pool..."
  load_pool_state
  POOL_STATE_ACTIVE=1
  boot_existing_pool
  if [[ "$KEEP_SIMS" -eq 1 ]]; then
    save_pool_state
  fi
  echo "Reused ${#CLONE_UDIDS[@]} simulator clones."
else
  echo "Phase 1: Cloning $WORKERS simulators from source..."
  if [[ "$KEEP_SIMS" -eq 1 ]] && [[ -f "$POOL_STATE_FILE" ]]; then
    echo "WARNING: Overwriting saved simulator pool state at $POOL_STATE_FILE." >&2
    echo "WARNING: Previously kept simulators will not be auto-deleted." >&2
  fi
  POOL_JSON="$(python3 "$SCRIPT_DIR/create_sim_pool.py" \
    --source-udid "$SOURCE_UDID" \
    --workers "$WORKERS")"

  # Parse clone UDIDs from the JSON output.
  while IFS= read -r line; do
    CLONE_UDIDS+=("$line")
  done < <(parse_clone_udids_from_pool_json "$POOL_JSON")

  [[ ${#CLONE_UDIDS[@]} -eq "$WORKERS" ]] || die "Expected $WORKERS cloned simulators, got ${#CLONE_UDIDS[@]}."

  if [[ "$KEEP_SIMS" -eq 1 ]]; then
    save_pool_state
    POOL_STATE_ACTIVE=1
  fi

  echo "Created ${#CLONE_UDIDS[@]} simulator clones."
fi

# ── Phase 2: Split tasks ─────────────────────────────────────────────────
echo "Phase 2: Splitting tasks across $WORKERS workers..."
split_cmd=(
  python3 "$SCRIPT_DIR/split_tasks.py"
  --tasks "$TASKS" \
  --workers "$WORKERS" \
  --output-dir "$SPLIT_TMPDIR" \
  --existing-run-dir "$RUN_DIR" \
  --emit-json
)
if [[ "$TASKS_REQUIRE_EVALUATION" -eq 1 ]]; then
  split_cmd+=(--require-evaluation)
fi
if [[ "$RETRY_FAILED" -eq 1 ]]; then
  split_cmd+=(--retry-failed)
fi
SPLIT_PLAN_JSON="$("${split_cmd[@]}")"
ACTUAL_WORKERS="$(parse_split_plan_field "$SPLIT_PLAN_JSON" actual_workers)"
PENDING_TASKS="$(parse_split_plan_field "$SPLIT_PLAN_JSON" pending_tasks)"
SKIPPED_TASKS="$(parse_split_plan_field "$SPLIT_PLAN_JSON" skipped_tasks)"
TOTAL_TASKS="$(parse_split_plan_field "$SPLIT_PLAN_JSON" total_tasks)"
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  SKIPPED_TASK_LABELS+=("$line")
done < <(parse_split_plan_lines "$SPLIT_PLAN_JSON" skipped_task_labels)
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  PENDING_TASK_LABELS+=("$line")
done < <(parse_split_plan_lines "$SPLIT_PLAN_JSON" pending_task_labels)

echo "Actual workers (based on pending task count): $ACTUAL_WORKERS"
echo "Task plan: $SKIPPED_TASKS/$TOTAL_TASKS already complete | $PENDING_TASKS scheduled now"
if [[ "$SKIPPED_TASKS" -gt 0 ]]; then
  echo "Skipping $SKIPPED_TASKS/$TOTAL_TASKS tasks with existing results."
  echo "  Already complete: $(preview_task_labels 12 "${SKIPPED_TASK_LABELS[@]}")"
fi
if [[ "$PENDING_TASKS" -gt 0 ]]; then
  echo "  Scheduled now: $(preview_task_labels 12 "${PENDING_TASK_LABELS[@]}")"
fi
if [[ "$PENDING_TASKS" -eq 0 ]]; then
  echo "All tasks already have results. No workers need to run."
fi
if [[ "$ACTUAL_WORKERS" -gt 0 ]]; then
  echo "Preflight: Resolving worker Appium/WDA ports..."
  resolve_worker_port_bases "$ACTUAL_WORKERS"
fi

# ── Phase 3: Launch workers ──────────────────────────────────────────────
echo "Phase 3: Launching $ACTUAL_WORKERS workers..."
WORKER_PIDS=()
WORKER_DIRS=()
WORKER_LOGS=()
WORKER_TASK_COUNTS=()
WORKER_FINISHED=()

for (( i=0; i<ACTUAL_WORKERS; i++ )); do
  port=$((ACTIVE_BASE_PORT + i))
  wda_port=$((ACTIVE_WDA_BASE_PORT + i))
  udid="${CLONE_UDIDS[$i]}"
  worker_dir="$WORKER_TMPDIR/worker-$i"
  worker_tasks="$SPLIT_TMPDIR/worker-${i}-tasks.json"
  worker_log="$LOGS_DIR/worker-$i.log"
  worker_task_count="$(python3 -c "import json; print(len(json.load(open('$worker_tasks'))))")"

  mkdir -p "$worker_dir"
  WORKER_DIRS+=("$worker_dir")
  WORKER_LOGS+=("$worker_log")
  WORKER_TASK_COUNTS+=("$worker_task_count")
  WORKER_FINISHED+=(0)

  echo "  Worker $i: port=$port wda=$wda_port udid=$udid tasks=$worker_task_count"

  worker_cmd=(
    "$SCRIPT_DIR/run_benchmark.sh"
    --udid "$udid"
    --port "$port"
    --wda-port "$wda_port"
    --run-dir "$worker_dir"
    --task-root-dir "$RUN_DIR"
    --tasks "$worker_tasks"
    --device-name "$DEVICE_NAME"
  )
  if [[ -n "${PLATFORM_VERSION:-}" ]]; then
    worker_cmd+=(--platform-version "$PLATFORM_VERSION")
  fi
  if [[ ${#PASSTHROUGH_ARGS[@]} -gt 0 ]]; then
    worker_cmd+=("${PASSTHROUGH_ARGS[@]}")
  fi

  "${worker_cmd[@]}" \
    > "$worker_log" 2>&1 &

  WORKER_PIDS+=($!)

  if [[ "${PARALLEL_WORKER_LAUNCH_DELAY:-0}" -gt 0 && "$i" -lt $((ACTUAL_WORKERS - 1)) ]]; then
    sleep "$PARALLEL_WORKER_LAUNCH_DELAY"
  fi
done

# ── Phase 4: Wait for all workers ────────────────────────────────────────
echo ""
echo "Phase 4: Waiting for ${#WORKER_PIDS[@]} workers to complete..."
ANY_FAILED=0
PENDING_WORKERS="${#WORKER_PIDS[@]}"
LAST_PROGRESS_TS=0
LAST_WORKER_PROGRESS_SNAPSHOT=""
LAST_TASK_PROGRESS_SNAPSHOT=""

while [[ "$PENDING_WORKERS" -gt 0 ]]; do
  state_changed=0

  for i in "${!WORKER_PIDS[@]}"; do
    if [[ "${WORKER_FINISHED[$i]:-0}" -eq 1 ]]; then
      continue
    fi

    pid="${WORKER_PIDS[$i]}"
    if ! worker_process_exited "$pid"; then
      continue
    fi

    had_worker_errors=0
    if wait "$pid"; then
      echo "  Worker $i (pid $pid): completed successfully"
      if record_worker_error_events "$i" "${WORKER_LOGS[$i]}" 0; then
        had_worker_errors=1
      fi
    else
      exit_code=$?
      echo "  Worker $i (pid $pid): FAILED (exit code $exit_code)"
      ANY_FAILED=1
      append_error_log "ERROR" "Worker $i failed with exit code $exit_code"
      if record_worker_error_events "$i" "${WORKER_LOGS[$i]}" "$exit_code"; then
        had_worker_errors=1
      fi
    fi
    copy_worker_appium_log "$i" "${WORKER_DIRS[$i]}"
    if [[ "$had_worker_errors" -eq 1 ]] && [[ -f "$LOGS_DIR/appium-worker-$i.log" ]]; then
      append_file_tail_to_error_log "Worker $i Appium log" "$LOGS_DIR/appium-worker-$i.log" 60
    fi
    if [[ "$had_worker_errors" -eq 1 ]] && [[ -f "${WORKER_LOGS[$i]}" ]]; then
      append_file_tail_to_error_log "Worker $i benchmark log" "${WORKER_LOGS[$i]}" 60
    fi

    WORKER_FINISHED[$i]=1
    PENDING_WORKERS=$((PENDING_WORKERS - 1))
    state_changed=1
  done

  if [[ "$PENDING_WORKERS" -gt 0 ]]; then
    now="$(date +%s)"
    if [[ "$state_changed" -eq 1 ]] || (( now - LAST_PROGRESS_TS >= 5 )); then
      task_snapshot="$(overall_task_progress_summary)"
      if [[ -n "$task_snapshot" ]] && [[ "$task_snapshot" != "$LAST_TASK_PROGRESS_SNAPSHOT" ]]; then
        echo "$task_snapshot"
        LAST_TASK_PROGRESS_SNAPSHOT="$task_snapshot"
      fi
      current_snapshot="$(collect_worker_progress_snapshot)"
      if [[ -n "$current_snapshot" ]] && [[ "$current_snapshot" != "$LAST_WORKER_PROGRESS_SNAPSHOT" ]]; then
        echo "  Worker progress:"
        printf '%s\n' "$current_snapshot"
        LAST_WORKER_PROGRESS_SNAPSHOT="$current_snapshot"
      fi
      LAST_PROGRESS_TS="$now"
    fi
    sleep 2 || true
  fi
done

if [[ "$TOTAL_TASKS" -gt 0 ]]; then
  echo "$(overall_task_progress_summary)"
fi

# ── Phase 5: Merge results ───────────────────────────────────────────────
echo ""
echo "Phase 5: Merging results from ${#WORKER_DIRS[@]} workers..."
MERGE_STATUS=0
merge_cmd=(
  python3 "$SCRIPT_DIR/merge_results.py"
  --existing-run-dir "$RUN_DIR"
  --output "$RUN_DIR"
)
if [[ ${#WORKER_DIRS[@]} -gt 0 ]]; then
  merge_cmd+=(--run-dirs "${WORKER_DIRS[@]}")
fi
if "${merge_cmd[@]}"; then
  MERGE_STATUS=0
else
  MERGE_STATUS=$?
  append_error_log "ERROR" "merge_results.py exited with status $MERGE_STATUS"
fi

if [[ ! -f "$RUN_DIR/summary.json" ]]; then
  append_error_log "ERROR" "summary.json was not produced in $RUN_DIR"
  exit "${MERGE_STATUS:-1}"
fi
if [[ "$MERGE_STATUS" -ne 0 ]]; then
  ANY_FAILED=1
fi

WALL_ELAPSED=$(( SECONDS - WALL_START ))
WALL_MIN=$(( WALL_ELAPSED / 60 ))
WALL_SEC=$(( WALL_ELAPSED % 60 ))

echo ""
echo "============================================"
echo "  Parallel benchmark complete"
echo "  Results: $RUN_DIR/summary.json"
echo "  Error log: $ERROR_LOG_FILE"
echo "  Workers: $ACTUAL_WORKERS"
echo "  Wall time: ${WALL_MIN}m ${WALL_SEC}s"
if [[ $ANY_FAILED -eq 1 ]]; then
  echo "  Status: SOME WORKERS FAILED"
else
  echo "  Status: ALL WORKERS SUCCEEDED"
fi
echo "============================================"
echo "RUN_DIR=$RUN_DIR"

# Exit non-zero if any worker failed.
[[ $ANY_FAILED -eq 0 ]] || exit 1
