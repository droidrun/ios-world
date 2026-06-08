#!/usr/bin/env bash
# Setup helper for the iOS benchmark scaffold.
# Installs Python deps, Appium + xcuitest driver, and prints the env vars to set.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/.." && pwd)"

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

APPIUM_VERSION="${APPIUM_VERSION:-3}"
XCUITEST_VERSION="${XCUITEST_VERSION:-}" # leave empty to take latest driver

select_python() {
  local candidates candidate
  candidates=(
    "${PYTHON:-}"
    python3.13
    python3.12
    python3.11
    python3.10
    /opt/homebrew/bin/python3.13
    /opt/homebrew/bin/python3.12
    /opt/homebrew/bin/python3.11
    /opt/homebrew/bin/python3.10
    /usr/local/bin/python3.13
    /usr/local/bin/python3.12
    /usr/local/bin/python3.11
    /usr/local/bin/python3.10
    python3
  )
  for candidate in "${candidates[@]}"; do
    [[ -n "$candidate" ]] || continue
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
      then
        command -v "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

require_supported_node() {
  local raw ver major minor
  if ! command -v node >/dev/null 2>&1; then
    return 1
  fi
  raw="$(node -v 2>/dev/null || true)"
  ver="${raw#v}"
  IFS='.' read -r major minor _ <<<"$ver"
  if { [[ "$major" -eq 20 && "$minor" -ge 19 ]] || [[ "$major" -eq 22 && "$minor" -ge 12 ]] || [[ "$major" -ge 24 ]]; }; then
    return 0
  fi
  echo "Node $raw is not supported by Appium 3 (needs ^20.19 || ^22.12 || >=24)." >&2
  return 1
}

echo "==> Ensuring Python dependencies"
if python_bin="$(select_python)"; then
  venv_dir="$repo_root/.venv"
  if [[ -d "$venv_dir" ]] && ! "$venv_dir/bin/python" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
  then
    echo "Existing .venv uses Python <3.10; recreating it ..."
    rm -rf "$venv_dir"
  fi
  if [[ ! -d "$venv_dir" ]]; then
    echo "Creating virtual environment at .venv with $("$python_bin" --version) ..."
    "$python_bin" -m venv "$venv_dir"
  fi
  # shellcheck disable=SC1091
  source "$venv_dir/bin/activate"
  python3 -m pip install --upgrade pip >/dev/null
  python3 -m pip install -r "$repo_root/requirements.txt"
else
  echo "python3 not found; please install Python 3.10+ and rerun." >&2
  exit 1
fi

echo "==> Ensuring Node/npm are available"
if ! command -v npm >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "npm not found; installing Node.js (node@20) via Homebrew..."
    brew install node@20
    # Add Homebrew Node to PATH for this session and warn user to persist if needed.
    export PATH="/opt/homebrew/opt/node@20/bin:/usr/local/opt/node@20/bin:$PATH"
  else
    echo "npm not found and Homebrew is unavailable; install Node.js (^20.19 || ^22.12 || >=24) and rerun." >&2
    exit 1
  fi
fi
if ! require_supported_node; then
  exit 1
fi

echo "==> Installing Appium ${APPIUM_VERSION}"
npm install -g "appium@${APPIUM_VERSION}"

echo "==> Ensuring xcuitest driver"
if [ -n "$XCUITEST_VERSION" ]; then
  appium driver install "xcuitest@${XCUITEST_VERSION}" 2>/dev/null \
    || appium driver update "xcuitest@${XCUITEST_VERSION}" \
    || true
else
  appium driver install xcuitest 2>/dev/null \
    || appium driver update xcuitest \
    || true
fi

if [[ ! -f "$repo_root/.env" && -f "$repo_root/.env.example" ]]; then
  cp "$repo_root/.env.example" "$repo_root/.env"
  echo "==> Created .env from .env.example (edit API keys before running LLM eval)."
fi

echo
echo "Setup complete."
cat <<'EOF'

Next steps:
0) Activate the venv in each new shell:
   source .venv/bin/activate
1) Edit .env: pick one paper runner and set its key/base URL.
   The open-source model path is:
   LLM_PROVIDER=vllm, LLM_MODEL=qwen3.5-35B-a3,
   VLLM_BASE_URL=<your vLLM url>, VLLM_API_KEY=<token or "EMPTY">.
2) Boot a simulator and bootstrap the benchmark apps onto it:
   open -a Simulator
   ./iphone/bootstrap/bootstrap_ios_apps.sh
3) Run a single task:
   appium --port 4723   # in a separate terminal
   ./scripts/run_task_by_id.sh clock-001 --provider vllm --model qwen3.5-35B-a3
4) Run the full suite:
   LLM_PROVIDER=vllm LLM_MODEL=qwen3.5-35B-a3 \
     scripts/bootstrap_release.sh --target phone --tasks tasks.json

EOF
