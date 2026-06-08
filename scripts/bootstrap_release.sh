#!/usr/bin/env bash
# Full benchmark pipeline: build/install iOS apps → run LLM agent → evaluate.
#
# Typical usage:
#   scripts/bootstrap_release.sh --target phone
#   scripts/bootstrap_release.sh --target phone --skip-setup
#   scripts/bootstrap_release.sh --target phone --tasks tasks.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LAST_BOOTSTRAP_STATE_FILE="$REPO_ROOT/iphone/bootstrap/.last_bootstrap_state.env"
cd "$REPO_ROOT"

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap_release.sh [options]

Full pipeline: build/install simulator apps, then run the LLM agent benchmark.

Setup options (app build & install):
  --skip-setup              Skip app build/install (apps already on simulator).
  --repos <file>            Repo list for bootstrap (default: iphone/bootstrap/repos.txt).

Benchmark options (agent loop & evaluation):
  --target <phone|ipad|both>  Simulator target (default: phone).
  --tasks <path>              Tasks JSON (default: tasks.json).
  --action-mode <mode>        batch|step (default: step).
  --agent-cmd <cmd>           External agent command (disables in-process mode).
  --no-inprocess              Use --agent-cmd subprocess instead of in-process mode.
  --no-evaluate               Skip LLM evaluation of task outcomes.
  --max-steps <n>             Max steps per task (default: 50).
  --workers <n>               Run N parallel benchmark workers (default: 1).
  --run-dir <dir>             Write benchmark results to this directory.
  --keep-sims                 Keep worker simulator clones after a parallel run.
  --reuse-sims                Reuse the last kept worker simulator pool
                              from a previous run (requires --skip-setup).
  --post-reset-wait <s>       Wait after simulator reset (default: 2.0).
  --post-action-wait <s>      Wait after each action (default: 2.0).
  --task-timeout <s>          Per-task timeout in seconds (default: 0 = no timeout).
  --retry-failed              Re-run tasks that previously failed instead of skipping them.
  --skip-erase                Keep simulator data between tasks (default).
  --no-skip-erase             Erase simulator between tasks (removes installed apps!).
  --tool-use                  Run Vision+Tools mode (Qwen-only): task-scoped
                              MCP tools + Qwen mobile_use fallback. The paper's
                              qwen35-mcp-cua configuration.
  --mcp                       Run MCP tool-use mode (Qwen-only). The paper's
                              qwen35-mcp configuration. Requires LLM_PROVIDER=vllm
                              and a Qwen model.
  --mcp-cua                   Add Qwen mobile_use alongside MCP tools.
  --mcp-model <model>         Override Qwen model for MCP/tool-use mode
                              (default: qwen3.5-35B-a3).
  --mcp-screenshots           Include screenshots in MCP tool results.
  --mcp-confirmation-tools    Include expanded prepare_*/confirm_*(draft_id)
                              safety-pair tools. Off by default for compactness.

  Per-app reinstall (clean slate):
    When an app manifest exists (created by bootstrap), each task's app is
    automatically uninstalled and reinstalled before that task runs. This gives
    a clean slate (no leftover data) without erasing the full simulator.
  -h, --help                  Show this help.

Environment (can be set in .env):
  LLM_PROVIDER                    openai|anthropic|gemini|vllm (default: openai)
  LLM_MODEL                       Model name (provider-specific default if unset).
  OPENAI_API_KEY                   For LLM_PROVIDER=openai (or use LLM_API_KEY).
  ANTHROPIC_API_KEY                For LLM_PROVIDER=anthropic.
  GEMINI_API_KEY / GOOGLE_API_KEY  For LLM_PROVIDER=gemini.
  VLLM_BASE_URL / VLLM_API_KEY     For LLM_PROVIDER=vllm (default URL: http://localhost:8000/v1).
  SIMCTL_UDID                     Generic pre-set UDID for the selected target.
  PHONE_SIMCTL_UDID / IPAD_SIMCTL_UDID  Target-specific pre-set UDIDs (skip auto-pick).
  PHONE_PLATFORM_VERSION / PHONE_DEVICE_NAME
  IPAD_PLATFORM_VERSION / IPAD_DEVICE_NAME
EOF
}

# ── Load .env (only for vars not already set by the caller) ──────────────
if [[ -f ".env" ]]; then
  while IFS='=' read -r key value; do
    # Skip comments and blank lines
    [[ -z "$key" || "$key" == \#* ]] && continue
    # Strip surrounding quotes from value
    value="${value%\"}"
    value="${value#\"}"
    # Only set if not already in environment (caller's inline vars win)
    if [[ -z "${!key+x}" ]]; then
      export "$key=$value"
    fi
  done < .env
fi

# ── Defaults ─────────────────────────────────────────────────────────────
TARGET="phone"
TASKS="tasks.json"
REPOS="iphone/bootstrap/repos.txt"
SKIP_SETUP=0
AGENT_CMD=""
ACTION_MODE="step"
INPROCESS=1
EVALUATE=1
MAX_STEPS=50
WORKERS=1
RUN_DIR=""
KEEP_SIMS=0
REUSE_SIMS=0
POST_RESET_WAIT=2.0
POST_ACTION_WAIT=2.0
TASK_TIMEOUT=0
SKIP_ERASE_SET=""  # empty = auto (on when setup runs, off otherwise)
CROSS_RUN_REUSE=0
XML_AGENT=0
XML_NO_SCREENSHOT=0
XML_EXCLUDE_HIDDEN=0
RETRY_FAILED=0
QWEN_CU=0
MCP=0
TOOL_USE=0
MCP_CUA=0
MCP_SCREENSHOTS=0
MCP_CONFIRMATION_TOOLS=0
MCP_MODEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)           TARGET="$2"; shift 2 ;;
    --tasks)            TASKS="$2"; shift 2 ;;
    --repos)            REPOS="$2"; shift 2 ;;
    --skip-setup)       SKIP_SETUP=1; shift 1 ;;
    --agent-cmd)        AGENT_CMD="$2"; INPROCESS=0; shift 2 ;;
    --action-mode)      ACTION_MODE="$2"; shift 2 ;;
    --no-inprocess)     INPROCESS=0; shift 1 ;;
    --no-evaluate)      EVALUATE=0; shift 1 ;;
    --max-steps)        MAX_STEPS="$2"; shift 2 ;;
    --workers)          WORKERS="$2"; shift 2 ;;
    --run-dir)          RUN_DIR="$2"; shift 2 ;;
    --keep-sims)        KEEP_SIMS=1; shift 1 ;;
    --reuse-sims)       REUSE_SIMS=1; shift 1 ;;
    --retry-failed)     RETRY_FAILED=1; shift 1 ;;
    --post-reset-wait)  POST_RESET_WAIT="$2"; shift 2 ;;
    --post-action-wait) POST_ACTION_WAIT="$2"; shift 2 ;;
    --task-timeout)     TASK_TIMEOUT="$2"; shift 2 ;;
    --skip-erase)       SKIP_ERASE_SET="1"; shift 1 ;;
    --no-skip-erase)    SKIP_ERASE_SET="0"; shift 1 ;;
    --xml-agent)            XML_AGENT=1; shift 1 ;;
    --xml-no-screenshot)    XML_NO_SCREENSHOT=1; shift 1 ;;
    --xml-exclude-hidden)   XML_EXCLUDE_HIDDEN=1; shift 1 ;;
    --qwen-cu)              QWEN_CU=1; shift 1 ;;
    --mcp)                  MCP=1; shift 1 ;;
    --tool-use)             TOOL_USE=1; shift 1 ;;
    --mcp-cua)              MCP_CUA=1; shift 1 ;;
    --mcp-screenshots)      MCP_SCREENSHOTS=1; shift 1 ;;
    --mcp-confirmation-tools) MCP_CONFIRMATION_TOOLS=1; shift 1 ;;
    --mcp-model)            MCP_MODEL="$2"; shift 2 ;;
    --help|-h)          usage; exit 0 ;;
    *)                  echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

# ── MCP mode is Qwen-only (the paper's only MCP configuration) ──────────
if [[ $MCP -eq 1 || $TOOL_USE -eq 1 ]]; then
  _mcp_provider="$(echo "${LLM_PROVIDER:-}" | tr '[:upper:]' '[:lower:]')"
  _mcp_model_check="${MCP_MODEL:-${LLM_MODEL:-}}"
  _mcp_model_lower="$(echo "$_mcp_model_check" | tr '[:upper:]' '[:lower:]')"
  if [[ "$_mcp_provider" != "vllm" && "$_mcp_provider" != "qwen" && "$_mcp_model_lower" != *"qwen"* ]]; then
    die "--mcp / --tool-use is Qwen-only (paper's qwen35-mcp configuration). Set LLM_PROVIDER=vllm and pick a Qwen model (e.g. LLM_MODEL=qwen3.5-35B-a3), or pass --mcp-model qwen3.5-35B-a3."
  fi
fi

if [[ $REUSE_SIMS -eq 1 ]]; then
  if [[ $WORKERS -le 1 ]]; then
    echo "NOTE: --reuse-sims has no effect unless --workers > 1." >&2
  elif [[ $SKIP_SETUP -eq 1 ]]; then
    CROSS_RUN_REUSE=1
  else
    echo "NOTE: --reuse-sims only applies with --skip-setup; using a fresh worker pool for this run." >&2
  fi
fi

# Auto-set skip-erase: default ON unless explicitly overridden.
# Erasing between tasks removes installed apps, which is almost never desired
# whether setup ran or not.
if [[ -z "$SKIP_ERASE_SET" ]]; then
  SKIP_ERASE_SET="1"
fi

# ── Validate LLM key ────────────────────────────────────────────────────
require_env_key() {
  local provider="${LLM_PROVIDER:-openai}"
  provider="$(echo "$provider" | tr '[:upper:]' '[:lower:]')"
  case "$provider" in
    huggingface|hf)
      die "LLM_PROVIDER=huggingface is not supported. The paper's six runners are openai|anthropic|gemini|vllm."
      ;;
    anthropic|claude)
      [[ -n "${ANTHROPIC_API_KEY:-${LLM_API_KEY:-}}" ]] || die "Set ANTHROPIC_API_KEY (or LLM_API_KEY) in .env or environment."
      ;;
    gemini|google)
      [[ -n "${GEMINI_API_KEY:-${GOOGLE_API_KEY:-${LLM_API_KEY:-}}}" ]] || die "Set GEMINI_API_KEY (or GOOGLE_API_KEY / LLM_API_KEY) in .env or environment."
      ;;
    vllm|qwen)
      # vLLM is self-hosted; VLLM_API_KEY defaults to "EMPTY". Only the
      # base URL needs to resolve. Fall back to localhost:8000/v1 if unset.
      : "${VLLM_BASE_URL:=http://localhost:8000/v1}"
      ;;
    openai|*)
      [[ -n "${OPENAI_API_KEY:-${LLM_API_KEY:-}}" ]] || die "Set OPENAI_API_KEY (or LLM_API_KEY) in .env or environment."
      ;;
  esac
}

# ── Simulator helpers ────────────────────────────────────────────────────
pick_udid() {
  local filter="$1"
  local out udid
  out="$(python3 scripts/find_latest_udid.py --device-filter "$filter")"
  udid="$(printf '%s\n' "$out" | sed -nE 's/^export SIMCTL_UDID=([A-F0-9-]{36}).*/\1/p' | head -n1)"
  [[ -n "$udid" ]] || die "Failed to auto-pick simulator UDID for filter '$filter'. Raw output: $out"
  echo "$udid"
}

resolve_sim_meta() {
  local udid="$1"
  python3 - "$udid" <<'PY'
import json, subprocess, sys
udid = sys.argv[1]
proc = subprocess.run(
    ["xcrun", "simctl", "list", "devices", "available", "-j"],
    capture_output=True,
    text=True,
)
if proc.returncode != 0:
    sys.exit(1)
data = json.loads(proc.stdout)
for runtime, devs in data.get("devices", {}).items():
    for d in devs:
        if d.get("udid") == udid:
            name = d.get("name", "")
            version = runtime.split("iOS-")[-1].replace("-", ".") if "iOS-" in runtime else runtime.split(".")[-1].replace("-", " ")
            print(f"{name}|{version}")
            sys.exit(0)
sys.exit(1)
PY
}

load_last_bootstrap_udid() {
  local expected_filter="$1"
  local saved_udid meta meta_name meta_name_lc expected_filter_lc

  [[ -f "$LAST_BOOTSTRAP_STATE_FILE" ]] || return 1

  # shellcheck disable=SC1090
  source "$LAST_BOOTSTRAP_STATE_FILE"
  saved_udid="${BOOTSTRAP_SIMCTL_UDID:-}"
  [[ -n "$saved_udid" ]] || return 1

  if meta="$(resolve_sim_meta "$saved_udid" 2>/dev/null)"; then
    IFS="|" read -r meta_name _ <<<"$meta"
    meta_name_lc="$(printf '%s' "$meta_name" | tr '[:upper:]' '[:lower:]')"
    expected_filter_lc="$(printf '%s' "$expected_filter" | tr '[:upper:]' '[:lower:]')"
    if [[ -n "$expected_filter_lc" ]] && [[ "$meta_name_lc" != *"$expected_filter_lc"* ]]; then
      return 1
    fi
  fi

  echo "Using last bootstrapped simulator: $saved_udid" >&2
  echo "$saved_udid"
}

# ── Setup phase: build & install apps ────────────────────────────────────
run_setup() {
  local device_name="$1"

  echo ""
  echo "============================================"
  echo "  Setup: building and installing apps"
  echo "  Repos: $REPOS"
  echo "============================================"
  echo ""

  local -a bootstrap_args=(
    iphone/bootstrap/bootstrap_ios_apps.sh
    --repos "$REPOS"
  )
  if [[ -n "$device_name" ]]; then
    bootstrap_args+=(--device "$device_name")
  fi

  "${bootstrap_args[@]}"

  echo ""
  echo "============================================"
  echo "  Setup complete — apps installed"
  echo "============================================"
  echo ""
}

# ── Benchmark phase: Appium + agent loop ─────────────────────────────────
run_target() {
  local udid="$1"
  local device_name="$2"
  local platform_version="$3"
  local meta_name meta_version

  # Resolve actual device metadata from UDID.
  if meta="$(resolve_sim_meta "$udid")"; then
    IFS="|" read -r meta_name meta_version <<<"$meta"
    if [[ -n "$meta_name" ]]; then
      device_name="$meta_name"
    fi
    if [[ -n "$meta_version" ]]; then
      platform_version="$meta_version"
    fi
  fi

  echo "Running benchmark: $device_name (UDID: $udid, iOS $platform_version)"

  # Build passthrough flags for run_benchmark.sh (or run_parallel.sh).
  local -a common_args=(
    --action-mode "$ACTION_MODE"
    --max-steps "$MAX_STEPS"
    --post-reset-wait "$POST_RESET_WAIT"
    --post-action-wait "$POST_ACTION_WAIT"
  )
  if [[ -n "$AGENT_CMD" ]]; then
    common_args+=(--agent-cmd "$AGENT_CMD")
  fi
  if [[ $INPROCESS -eq 1 ]]; then
    common_args+=(--inprocess)
  else
    common_args+=(--no-inprocess)
  fi
  if [[ $EVALUATE -eq 1 ]]; then
    common_args+=(--evaluate)
  fi
  if [[ "$SKIP_ERASE_SET" == "1" ]]; then
    common_args+=(--skip-erase)
  fi
  if [[ "$TASK_TIMEOUT" -gt 0 ]]; then
    common_args+=(--task-timeout "$TASK_TIMEOUT")
  fi
  if [[ $XML_AGENT -eq 1 ]]; then
    common_args+=(--xml-agent)
  fi
  if [[ $XML_NO_SCREENSHOT -eq 1 ]]; then
    common_args+=(--xml-no-screenshot)
  fi
  if [[ $XML_EXCLUDE_HIDDEN -eq 1 ]]; then
    common_args+=(--xml-exclude-hidden)
  fi
  if [[ $QWEN_CU -eq 1 ]]; then
    common_args+=(--qwen-cu)
  fi
  if [[ $MCP -eq 1 ]]; then
    common_args+=(--mcp)
  fi
  if [[ $TOOL_USE -eq 1 ]]; then
    common_args+=(--tool-use)
  fi
  if [[ $MCP_CUA -eq 1 ]]; then
    common_args+=(--mcp-cua)
  fi
  if [[ $MCP_SCREENSHOTS -eq 1 ]]; then
    common_args+=(--mcp-screenshots)
  fi
  if [[ $MCP_CONFIRMATION_TOOLS -eq 1 ]]; then
    common_args+=(--mcp-confirmation-tools)
  fi
  if [[ -n "$MCP_MODEL" ]]; then
    common_args+=(--mcp-model "$MCP_MODEL")
  fi
  # Auto-detect app manifest for per-app reinstall (clean slate without erase).
  local manifest="$REPO_ROOT/iphone/bootstrap/.app_manifest.json"
  if [[ -f "$manifest" ]]; then
    common_args+=(--app-manifest "$manifest")
  fi

  if [[ $WORKERS -gt 1 ]]; then
    local -a parallel_args=(
      --workers "$WORKERS"
      --source-udid "$udid"
      --tasks "$TASKS"
      --device-name "$device_name"
      --platform-version "$platform_version"
    )
    if [[ -n "$RUN_DIR" ]]; then
      parallel_args+=(--run-dir "$RUN_DIR")
    fi
    if [[ $KEEP_SIMS -eq 1 ]]; then
      parallel_args+=(--keep-sims)
    fi
    if [[ $CROSS_RUN_REUSE -eq 1 ]]; then
      parallel_args+=(--reuse-sims)
    fi
    if [[ $RETRY_FAILED -eq 1 ]]; then
      parallel_args+=(--retry-failed)
    fi
    scripts/run_parallel.sh \
      "${parallel_args[@]}" \
      "${common_args[@]}"
  else
    local -a benchmark_args=(
      --udid "$udid"
      --tasks "$TASKS"
      --platform-version "$platform_version"
      --device-name "$device_name"
    )
    if [[ -n "$RUN_DIR" ]]; then
      benchmark_args+=(--run-dir "$RUN_DIR")
    fi
    scripts/run_benchmark.sh \
      "${benchmark_args[@]}" \
      "${common_args[@]}"
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────
main() {
  require_env_key

  [[ -f "$TASKS" ]] || die "Tasks file not found: $TASKS"
  if [[ $SKIP_SETUP -eq 0 && ! -f "$REPOS" ]]; then
    die "Repos file not found: $REPOS"
  fi

  case "$TARGET" in
    phone)
      local device_name="${PHONE_DEVICE_NAME:-${DEVICE_NAME:-iPhone 17 Pro}}"

      if [[ $SKIP_SETUP -eq 0 ]]; then
        run_setup "$device_name"
      fi

      local phone_udid="${PHONE_SIMCTL_UDID:-${SIMCTL_UDID:-}}"
      phone_udid="${phone_udid:-$(load_last_bootstrap_udid iPhone || true)}"
      phone_udid="${phone_udid:-$(pick_udid iPhone)}"
      run_target "$phone_udid" "$device_name" "${PHONE_PLATFORM_VERSION:-${PLATFORM_VERSION:-26.2}}"
      ;;

    ipad)
      local device_name="${IPAD_DEVICE_NAME:-iPad Pro 11-inch (M5)}"

      if [[ $SKIP_SETUP -eq 0 ]]; then
        run_setup "$device_name"
      fi

      local ipad_udid="${IPAD_SIMCTL_UDID:-${SIMCTL_UDID:-}}"
      ipad_udid="${ipad_udid:-$(load_last_bootstrap_udid iPad || true)}"
      ipad_udid="${ipad_udid:-$(pick_udid iPad)}"
      run_target "$ipad_udid" "$device_name" "${IPAD_PLATFORM_VERSION:-26.2}"
      ;;

    both)
      local requested_run_dir="$RUN_DIR"

      local phone_name="${PHONE_DEVICE_NAME:-${DEVICE_NAME:-iPhone 17 Pro}}"
      if [[ $SKIP_SETUP -eq 0 ]]; then
        run_setup "$phone_name"
      fi
      local phone_udid="${PHONE_SIMCTL_UDID:-${SIMCTL_UDID:-}}"
      phone_udid="${phone_udid:-$(load_last_bootstrap_udid iPhone || true)}"
      phone_udid="${phone_udid:-$(pick_udid iPhone)}"
      if [[ -n "$requested_run_dir" ]]; then
        RUN_DIR="$requested_run_dir/phone"
      fi
      run_target "$phone_udid" "$phone_name" "${PHONE_PLATFORM_VERSION:-${PLATFORM_VERSION:-26.2}}"

      local ipad_name="${IPAD_DEVICE_NAME:-iPad Pro 11-inch (M5)}"
      if [[ $SKIP_SETUP -eq 0 ]]; then
        run_setup "$ipad_name"
      fi
      local ipad_udid="${IPAD_SIMCTL_UDID:-${SIMCTL_UDID:-}}"
      ipad_udid="${ipad_udid:-$(load_last_bootstrap_udid iPad || true)}"
      ipad_udid="${ipad_udid:-$(pick_udid iPad)}"
      if [[ -n "$requested_run_dir" ]]; then
        RUN_DIR="$requested_run_dir/ipad"
      fi
      run_target "$ipad_udid" "$ipad_name" "${IPAD_PLATFORM_VERSION:-26.2}"
      RUN_DIR="$requested_run_dir"
      ;;

    *)
      die "Unsupported target: $TARGET (use phone|ipad|both)"
      ;;
  esac
}

main "$@"
