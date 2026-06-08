#!/usr/bin/env bash
# Run a SINGLE benchmark task by its ID (e.g. clock-001, mybank-003, mem-021).
# Useful for smoke tests, debugging, and reviewing individual task behavior.
#
# Usage:
#   scripts/run_task_by_id.sh <task-id> [--provider <p>] [--model <m>] [--max-steps N]
#
# Examples:
#   scripts/run_task_by_id.sh clock-001                               # uses .env defaults
#   scripts/run_task_by_id.sh mybank-003 --provider vllm --model qwen3.5-35B-a3
#   scripts/run_task_by_id.sh mem-021 --max-steps 30
#
# Prereqs (one-time setup):
#   1. ./scripts/setup_env.sh
#   2. cp .env.example .env  (and fill in at least one API key)
#   3. ./iphone/bootstrap/bootstrap_ios_apps.sh     (builds + installs 26 apps)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/run_task_by_id.sh <task-id> [options]

Options:
  --provider <p>              openai|anthropic|gemini|vllm
  --model <m>                 Model name for the selected provider
  --max-steps <n>             Step budget (default: 50)
  --run-dir <dir>             Result directory
  --tasks-file <path>         Alternate tasks JSON file
  --xml-agent                 Add XCUITest accessibility XML to observations
  --mcp                       Qwen/vLLM MCP tool-use mode
  --tool-use                  Qwen/vLLM MCP + mobile_use mode
  --mcp-cua                   Add mobile_use fallback to MCP mode
  --mcp-screenshots           Include screenshots in MCP tool results
  --mcp-confirmation-tools    Include expanded prepare/confirm tools
  --mcp-model <m>             Qwen model for MCP/tool-use mode
  -h, --help                  Show this help

Prereqs:
  ./scripts/setup_env.sh
  ./iphone/bootstrap/bootstrap_ios_apps.sh
  appium --port 4723
  OPENAI_API_KEY if you want the default post-run rubric evaluation
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
esac

TASK_ID="$1"; shift

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_FILE="${TASKS_FILE:-$REPO_ROOT/tasks.json}"
MAX_STEPS="${MAX_STEPS:-50}"   # paper uses a 50-step budget for all runs
TASK_TIMEOUT="${TASK_TIMEOUT:-360}"
RUN_DIR="$REPO_ROOT/results/single-task-$(date +%Y%m%d-%H%M%S)-$TASK_ID"
EXTRA_ARGS=()

# Parse optional flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)   export LLM_PROVIDER="$2"; shift 2 ;;
    --model)      export LLM_MODEL="$2"; shift 2 ;;
    --max-steps)  MAX_STEPS="$2"; shift 2 ;;
    --run-dir)    RUN_DIR="$2"; shift 2 ;;
    --tasks-file) TASKS_FILE="$2"; shift 2 ;;
    --cua|--claude-cu|--gemini-cu|--qwen-cu|--xml-agent|--xml-no-screenshot|--xml-exclude-hidden|--mcp|--tool-use|--mcp-cua|--mcp-screenshots|--mcp-confirmation-tools)
                  EXTRA_ARGS+=("$1"); shift ;;
    --mcp-model)  EXTRA_ARGS+=("$1" "$2"); shift 2 ;;
    *)            EXTRA_ARGS+=("$1"); shift ;;
  esac
done

[[ -f "$TASKS_FILE" ]] || { echo "ERROR: tasks file not found: $TASKS_FILE" >&2; exit 1; }

# Extract the single task into a temp file, preserving the nested shape so
# load_tasks() in appium_agent.py runs its normalizer (task → goal, id → name).
TMP_TASKS=$(mktemp -t ios-task-XXXX.json)
trap 'rm -f "$TMP_TASKS"' EXIT

python3 - "$TASK_ID" "$TASKS_FILE" "$TMP_TASKS" <<'PY'
import json, sys
task_id, src, dst = sys.argv[1:4]
data = json.load(open(src))
if not isinstance(data, list):
    sys.stderr.write(f"ERROR: expected {src} to be a JSON array of tasks\n")
    sys.exit(2)
found = next((t for t in data if t.get("name") == task_id or t.get("id") == task_id), None)
if not found:
    sys.stderr.write(f"ERROR: task id {task_id!r} not found in {src}\n")
    sys.exit(2)
json.dump([found], open(dst, "w"), indent=2)
print(f"[extract] {task_id}  category={found.get('category','?')}  apps={found.get('apps')}", file=sys.stderr)
print(f"[extract] goal: {(found.get('goal') or found.get('task') or '')[:100]}", file=sys.stderr)
PY

# Find booted sim UDID (first one that looks like a phone)
SIM_UDID="${SIMCTL_UDID:-$(xcrun simctl list devices booted -j 2>/dev/null | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(next((x['udid'] for rt,devs in d['devices'].items() for x in devs if x.get('state')=='Booted' and 'iPhone' in x.get('name','')), ''))")}"

if [[ -z "$SIM_UDID" ]]; then
  echo "ERROR: no booted iPhone simulator found. Boot one via Xcode or:" >&2
  echo "  xcrun simctl boot <udid>" >&2
  exit 1
fi

# Auto-detect app manifest
APP_MANIFEST="${APP_MANIFEST:-$REPO_ROOT/iphone/bootstrap/.app_manifest.json}"
if [[ ! -f "$APP_MANIFEST" ]]; then
  echo "WARNING: app manifest missing at $APP_MANIFEST." >&2
  echo "  Run: ./iphone/bootstrap/bootstrap_ios_apps.sh  (builds + installs 26 apps)" >&2
fi

# Resolve device name + platform version for Appium capabilities
SIM_META=$(xcrun simctl list devices booted -j | python3 -c "
import json, sys
d = json.load(sys.stdin)
for rt, devs in d['devices'].items():
    for x in devs:
        if x.get('udid') == '$SIM_UDID':
            ver = rt.split('iOS-')[-1].replace('-', '.') if 'iOS-' in rt else ''
            print(f\"{x.get('name','iPhone')}|{ver}\")
            sys.exit(0)
" 2>/dev/null || echo "iPhone|")
DEVICE_NAME="${DEVICE_NAME:-$(echo "$SIM_META" | cut -d'|' -f1)}"
PLATFORM_VERSION="${PLATFORM_VERSION:-$(echo "$SIM_META" | cut -d'|' -f2)}"

echo "────────────────────────────────────────────────────────"
echo "  Task:      $TASK_ID"
echo "  Sim:       $DEVICE_NAME ($SIM_UDID) iOS $PLATFORM_VERSION"
echo "  Provider:  ${LLM_PROVIDER:-<from .env>}"
echo "  Model:     ${LLM_MODEL:-<from .env>}"
echo "  Max steps: $MAX_STEPS"
echo "  Results:   $RUN_DIR"
echo "────────────────────────────────────────────────────────"

# Load .env for keys, but don't let it override --provider/--model the user passed.
USER_PROVIDER="${LLM_PROVIDER:-}"
USER_MODEL="${LLM_MODEL:-}"
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a; . "$REPO_ROOT/.env"; set +a
fi
[[ -n "$USER_PROVIDER" ]] && export LLM_PROVIDER="$USER_PROVIDER"
[[ -n "$USER_MODEL"    ]] && export LLM_MODEL="$USER_MODEL"

# Make sure Appium is up
if ! curl -sS -m 3 "${APPIUM_URL:-http://127.0.0.1:4723}/status" >/dev/null 2>&1; then
  echo "ERROR: Appium not reachable at ${APPIUM_URL:-http://127.0.0.1:4723}." >&2
  echo "  Start it in another terminal: appium --port 4723" >&2
  exit 1
fi

# --skip-erase is essential: otherwise the per-task reset factory-wipes the sim
# and removes the 26 installed apps. The per-app data-wipe + reseed handles
# between-task isolation.
exec python3 "$REPO_ROOT/scripts/appium_agent.py" \
  --tasks "$TMP_TASKS" \
  --udid "$SIM_UDID" \
  --device-name "$DEVICE_NAME" \
  --platform-version "$PLATFORM_VERSION" \
  --app-manifest "$APP_MANIFEST" \
  --inprocess --skip-erase \
  --action-mode step \
  --max-steps "$MAX_STEPS" \
  --task-timeout "$TASK_TIMEOUT" \
  --run-dir "$RUN_DIR" \
  --evaluate \
  ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
