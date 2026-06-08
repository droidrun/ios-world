#!/usr/bin/env bash
# Convenience runner: starts Appium, runs the agent, and shuts Appium down.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Load .env (only for vars not already set by the caller) ──────────────
_ENV_FILE="${REPO_ROOT}/.env"
if [[ -f "$_ENV_FILE" ]]; then
  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    value="${value%\"}"
    value="${value#\"}"
    if [[ -z "${!key+x}" ]]; then
      export "$key=$value"
    fi
  done < "$_ENV_FILE"
fi

usage() {
  cat <<'EOF'
Usage: scripts/run_benchmark.sh --udid <SIM_UDID> --tasks <path> [options]

Required:
  --udid <UDID>           Simulator UDID to target.
  --tasks <file>          Tasks JSON (actions or goals).

Options:
  --agent-cmd <cmd>       Command that emits actions (e.g., "python3 scripts/llm_action_generator.py").
  --action-mode <mode>    batch|step (default: step for LLM use).
  --inprocess             Call llm_action_generator in-process (default; faster, no subprocess).
  --no-inprocess          Disable in-process mode (use --agent-cmd subprocess instead).
  --evaluate              After all tasks, ask the LLM to judge goal completion.
  --max-steps <n>         Max steps per task in step mode (default: 50).
  --platform-version <v>  iOS version (e.g., 26.2).
  --device-name <name>    Simulator device name (default: "iPhone 17 Pro" or \$DEVICE_NAME).
  --run-dir <dir>         Where to write results (default: results/run-<device>-<model>-<timestamp>).
  --task-root-dir <dir>   Where to write per-task artifacts (default: --run-dir).
  --port <port>           Appium port (default: 4723).
  --appium-cmd <cmd>      Override Appium executable (default: appium or npx appium).
  --post-reset-wait <s>   Seconds to wait after reset before first observation (default: 2.0).
  --post-action-wait <s>  Seconds to wait after each action before next observation (default: 2.0).
  --no-reset              Skip shutdown/boot between tasks.
  --skip-erase            Keep simulator data when resetting (default; data wipe handles isolation).
  --app-manifest <path>   Path to .app_manifest.json for between-task data reset (default: from .env).
  --wda-port <port>       WebDriverAgent port (unique per parallel worker; default: auto).
  --task-timeout <s>      Per-task timeout in seconds (default: 0 = no timeout).
  --xml-agent             XML agent mode: send the UI accessibility tree to the LLM.
  --xml-no-screenshot     Text-only XML mode (no screenshots).
  --xml-exclude-hidden    Exclude non-visible elements from the tree (default: include all).
  --cua                   Force native computer-use mode when supported.
  --claude-cu             Force Anthropic computer-use mode.
  --gemini-cu             Force Gemini computer-use mode.
  --qwen-cu               Force Qwen mobile_use mode.
  --mcp                   MCP tool_use mode (Qwen-only): Qwen calls high-level
                          per-app MCP tools. Paper's qwen35-mcp configuration.
  --mcp-model <name>      Qwen model for MCP mode (default: qwen3.5-35B-a3).
  --mcp-screenshots       Include a screenshot in each tool_result alongside the UI tree.
  --mcp-cua               Hybrid: add Qwen mobile_use tool alongside MCP tools.
  --help                  Show this help.

Environment:
  LLM_PROVIDER and provider key   Needed when using LLM agent (see README).
  SIMCTL_UDID                     UDID can also be provided via env.
EOF
}

UDID="${SIMCTL_UDID:-}"
TASKS=""
AGENT_CMD=""
ACTION_MODE="step"
INPROCESS=1
EVALUATE=0
MAX_STEPS=50
PLATFORM_VERSION=""
DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro}"
RUN_DIR=""
TASK_ROOT_DIR=""
PORT=4723
APPIUM_CMD=""
NO_RESET=0
SKIP_ERASE=0
WDA_PORT=""
POST_RESET_WAIT=2.0
POST_ACTION_WAIT=2.0
TASK_TIMEOUT=0
APP_MANIFEST="${APP_MANIFEST:-}"
XML_AGENT=0
XML_NO_SCREENSHOT=0
XML_EXCLUDE_HIDDEN=0
MCP=0
MCP_SCREENSHOTS=0
MCP_CUA=0
MCP_MODEL=""
GEMINI_CU=0
CLAUDE_CU=0
CUA=0
QWEN_CU=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --udid) UDID="$2"; shift 2 ;;
    --tasks) TASKS="$2"; shift 2 ;;
    --agent-cmd) AGENT_CMD="$2"; shift 2 ;;
    --action-mode) ACTION_MODE="$2"; shift 2 ;;
    --inprocess) INPROCESS=1; shift 1 ;;
    --no-inprocess) INPROCESS=0; shift 1 ;;
    --evaluate) EVALUATE=1; shift 1 ;;
    --max-steps) MAX_STEPS="$2"; shift 2 ;;
    --platform-version) PLATFORM_VERSION="$2"; shift 2 ;;
    --device-name) DEVICE_NAME="$2"; shift 2 ;;
    --mcp) MCP=1; shift 1 ;;
    --mcp-model) MCP_MODEL="$2"; shift 2 ;;
    --mcp-screenshots) MCP_SCREENSHOTS=1; shift 1 ;;
    --mcp-cua) MCP_CUA=1; shift 1 ;;
    --run-dir) RUN_DIR="$2"; shift 2 ;;
    --task-root-dir) TASK_ROOT_DIR="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --appium-cmd) APPIUM_CMD="$2"; shift 2 ;;
    --post-reset-wait) POST_RESET_WAIT="$2"; shift 2 ;;
    --post-action-wait) POST_ACTION_WAIT="$2"; shift 2 ;;
    --no-reset) NO_RESET=1; shift 1 ;;
    --skip-erase) SKIP_ERASE=1; shift 1 ;;
    --wda-port) WDA_PORT="$2"; shift 2 ;;
    --task-timeout) TASK_TIMEOUT="$2"; shift 2 ;;
    --app-manifest) APP_MANIFEST="$2"; shift 2 ;;
    --xml-agent) XML_AGENT=1; shift 1 ;;
    --xml-no-screenshot) XML_NO_SCREENSHOT=1; shift 1 ;;
    --xml-exclude-hidden) XML_EXCLUDE_HIDDEN=1; shift 1 ;;
    --gemini-cu) GEMINI_CU=1; shift 1 ;;
    --claude-cu) CLAUDE_CU=1; shift 1 ;;
    --cua) CUA=1; shift 1 ;;
    --qwen-cu) QWEN_CU=1; shift 1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$UDID" ]] || { echo "Missing --udid (or SIMCTL_UDID)"; usage; exit 1; }
[[ -n "$TASKS" ]] || { echo "Missing --tasks"; usage; exit 1; }
[[ -f "$TASKS" ]] || { echo "Tasks file not found: $TASKS"; exit 1; }

# MCP mode is Qwen-only (paper's only MCP configuration).
if [[ $MCP -eq 1 ]]; then
  _mcp_provider="$(echo "${LLM_PROVIDER:-}" | tr '[:upper:]' '[:lower:]')"
  _mcp_model_check="${MCP_MODEL:-${LLM_MODEL:-}}"
  _mcp_model_lower="$(echo "$_mcp_model_check" | tr '[:upper:]' '[:lower:]')"
  if [[ "$_mcp_provider" != "vllm" && "$_mcp_provider" != "qwen" && "$_mcp_model_lower" != *"qwen"* ]]; then
    echo "ERROR: --mcp is Qwen-only (paper's qwen35-mcp configuration). Set LLM_PROVIDER=vllm and pick a Qwen model (e.g. LLM_MODEL=qwen3.5-35B-a3), or pass --mcp-model qwen3.5-35B-a3." >&2
    exit 1
  fi
fi

ts="$(date +%Y%m%d-%H%M%S)"
slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }
device_slug="$(slug "$DEVICE_NAME")"
[[ -n "$device_slug" ]] || device_slug="device"
model_slug="$(slug "${LLM_MODEL:-unknown}")"
[[ -n "$model_slug" ]] || model_slug="unknown"
RUN_BASE="${ARTIFACT_DIR:-results}"
RUN_NAME="run-${device_slug}-${model_slug}-${ts}"
RUN_DIR="${RUN_DIR:-$RUN_BASE/$RUN_NAME}"
mkdir -p "$RUN_DIR"
APPIUM_LOG="$RUN_DIR/appium-server.log"

cmd_exists() { command -v "$1" >/dev/null 2>&1; }
cmd_exists curl || { echo "curl not found; required for Appium health checks." >&2; exit 1; }
cmd_exists lsof || { echo "lsof not found; required for Appium port checks." >&2; exit 1; }

list_listening_pids() {
  local port="$1"
  lsof -nP -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk '!seen[$0]++'
}

find_next_available_port() {
  local start_port="$1"
  local max_tries="${2:-200}"
  local candidate="$start_port"
  local tries=0

  while [[ "$tries" -lt "$max_tries" ]]; do
    if [[ -z "$(list_listening_pids "$candidate")" ]]; then
      echo "$candidate"
      return 0
    fi
    candidate=$((candidate + 1))
    tries=$((tries + 1))
  done

  return 1
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

ensure_port_available() {
  local port="$1"
  local label="$2"

  if print_port_conflict "$port" "$label"; then
    echo "Stop the conflicting listener or choose a different port before retrying." >&2
    exit 1
  fi
}

resolve_port_or_reassign() {
  local requested_port="$1"
  local label="$2"
  local fallback_port

  if print_port_conflict "$requested_port" "$label"; then
    fallback_port="$(find_next_available_port $((requested_port + 1)))" || {
      echo "Could not find an available fallback port for $label after $requested_port." >&2
      exit 1
    }
    echo "Reassigning $label port from $requested_port to $fallback_port." >&2
    echo "$fallback_port"
    return 0
  fi

  echo "$requested_port"
}

require_supported_node() {
  if ! cmd_exists node; then
    echo "node not found. Install Node ^20.19.0, ^22.12.0, or >=24.0.0 for Appium 3." >&2
    exit 1
  fi
  local raw ver major minor
  raw="$(node -v 2>/dev/null || true)"
  ver="${raw#v}"
  IFS='.' read -r major minor _ <<<"$ver"
  if { [[ "$major" -eq 20 && "$minor" -ge 19 ]] || [[ "$major" -eq 22 && "$minor" -ge 12 ]] || [[ "$major" -ge 24 ]]; }; then
    return 0
  fi
  echo "Node $raw is not supported by Appium 3 (needs ^20.19 || ^22.12 || >=24). Please install a compatible Node." >&2
  exit 1
}

if [[ -z "$APPIUM_CMD" ]]; then
  if cmd_exists appium; then
    APPIUM_CMD="appium"
  elif cmd_exists npx; then
    APPIUM_CMD="npx appium"
  else
    echo "Appium not found. Install with: npm install -g appium appium-xcuitest-driver" >&2
    exit 1
  fi
fi

APPIUM_PID=""
require_supported_node
start_appium() {
  local attempt startup_conflict fallback_port

  for attempt in 1 2 3; do
    echo "Starting Appium: $APPIUM_CMD -p $PORT (log: $APPIUM_LOG)"
    set +e
    nohup $APPIUM_CMD -p "$PORT" </dev/null >"$APPIUM_LOG" 2>&1 &
    APPIUM_PID=$!
    set -e
    startup_conflict=0

    for i in {1..60}; do
      if ! kill -0 "$APPIUM_PID" >/dev/null 2>&1; then
        if curl -s "http://127.0.0.1:$PORT/status" >/dev/null 2>&1; then
          print_port_conflict "$PORT" "Appium" || true
          startup_conflict=1
          break
        else
          echo "Appium process exited before becoming ready." >&2
          echo "See $APPIUM_LOG" >&2
          exit 1
        fi
      fi
      if curl -s "http://127.0.0.1:$PORT/status" >/dev/null 2>&1; then
        echo "Appium is up (pid $APPIUM_PID)"
        return
      fi
      sleep 0.5
    done

    if [[ "$startup_conflict" -eq 1 ]]; then
      fallback_port="$(find_next_available_port $((PORT + 1)))" || {
        echo "Could not find an available fallback Appium port after $PORT." >&2
        echo "See $APPIUM_LOG" >&2
        exit 1
      }
      echo "Retrying Appium on fallback port $fallback_port." >&2
      PORT="$fallback_port"
      APPIUM_PID=""
      continue
    fi

    echo "Appium did not start within timeout. See $APPIUM_LOG" >&2
    exit 1
  done

  echo "Appium could not start after multiple port retries. See $APPIUM_LOG" >&2
  exit 1
}

stop_appium() {
  if [[ -n "${APPIUM_PID:-}" ]]; then
    kill "$APPIUM_PID" >/dev/null 2>&1 || true
  fi
}

trap stop_appium EXIT
PORT="$(resolve_port_or_reassign "$PORT" "Appium")"
if [[ -n "$WDA_PORT" ]]; then
  WDA_PORT="$(resolve_port_or_reassign "$WDA_PORT" "WDA")"
  if [[ "$WDA_PORT" -eq "$PORT" ]]; then
    WDA_PORT="$(find_next_available_port $((WDA_PORT + 1)))" || {
      echo "Could not find a non-overlapping fallback WDA port after $PORT." >&2
      exit 1
    }
    echo "Reassigning WDA port to $WDA_PORT to avoid overlap with Appium port $PORT." >&2
  fi
fi
start_appium

export APPIUM_URL="http://127.0.0.1:$PORT"
# Export SIMCTL_UDID so the MCP SimulatorBridge picks up the right simulator
# (important for parallel runs — each worker has its own UDID).
export SIMCTL_UDID="$UDID"

# Prefer the project venv if available — installs include fastmcp, anthropic,
# openai, google-genai which the system python may lack. Override via
# PYTHON_BIN env if needed.
PYTHON_BIN="${PYTHON_BIN:-}"
if [[ -z "$PYTHON_BIN" ]]; then
  if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then
    PYTHON_BIN="$REPO_ROOT/.venv/bin/python"
  else
    PYTHON_BIN="python3"
  fi
fi

agent_args=(
  "$PYTHON_BIN" scripts/appium_agent.py
  --tasks "$TASKS"
  --udid "$UDID"
  --action-mode "$ACTION_MODE"
  --max-steps "$MAX_STEPS"
  --device-name "$DEVICE_NAME"
  --run-dir "$RUN_DIR"
  --post-reset-wait "$POST_RESET_WAIT"
  --post-action-wait "$POST_ACTION_WAIT"
)
if [[ -n "$AGENT_CMD" ]]; then
  agent_args+=(--agent-cmd "$AGENT_CMD")
fi
if [[ -n "$TASK_ROOT_DIR" ]]; then
  agent_args+=(--task-root-dir "$TASK_ROOT_DIR")
fi
if [[ $INPROCESS -eq 1 ]]; then
  agent_args+=(--inprocess)
fi
if [[ $EVALUATE -eq 1 ]]; then
  agent_args+=(--evaluate)
fi
if [[ -n "$PLATFORM_VERSION" ]]; then
  agent_args+=(--platform-version "$PLATFORM_VERSION")
fi
if [[ $NO_RESET -eq 1 ]]; then
  agent_args+=(--no-reset)
fi
if [[ -n "$APP_MANIFEST" ]]; then
  agent_args+=(--app-manifest "$APP_MANIFEST")
  # When the manifest is set, the data-wipe + reseed handles isolation —
  # full erase would uninstall all apps and break the reset flow.
  if [[ $SKIP_ERASE -eq 0 ]]; then
    SKIP_ERASE=1
  fi
fi
if [[ $SKIP_ERASE -eq 1 ]]; then
  agent_args+=(--skip-erase)
fi
if [[ -n "$WDA_PORT" ]]; then
  agent_args+=(--wda-port "$WDA_PORT")
fi
if [[ "$TASK_TIMEOUT" -gt 0 ]]; then
  agent_args+=(--task-timeout "$TASK_TIMEOUT")
fi
if [[ $XML_AGENT -eq 1 ]]; then
  agent_args+=(--xml-agent)
fi
if [[ $XML_NO_SCREENSHOT -eq 1 ]]; then
  agent_args+=(--xml-no-screenshot)
fi
if [[ $XML_EXCLUDE_HIDDEN -eq 1 ]]; then
  agent_args+=(--xml-exclude-hidden)
fi
if [[ $MCP -eq 1 ]]; then
  agent_args+=(--mcp)
fi
if [[ -n "$MCP_MODEL" ]]; then
  agent_args+=(--mcp-model "$MCP_MODEL")
fi
if [[ $MCP_SCREENSHOTS -eq 1 ]]; then
  agent_args+=(--mcp-screenshots)
fi
if [[ $MCP_CUA -eq 1 ]]; then
  agent_args+=(--mcp-cua)
fi
if [[ $GEMINI_CU -eq 1 ]]; then
  agent_args+=(--gemini-cu)
fi
if [[ $CLAUDE_CU -eq 1 ]]; then
  agent_args+=(--claude-cu)
fi
if [[ $CUA -eq 1 ]]; then
  agent_args+=(--cua)
fi
if [[ $QWEN_CU -eq 1 ]]; then
  agent_args+=(--qwen-cu)
fi
"${agent_args[@]}"

echo "Done. Results in $RUN_DIR"
echo "RUN_DIR=$RUN_DIR"
