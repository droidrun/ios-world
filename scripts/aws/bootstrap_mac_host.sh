#!/usr/bin/env bash
# Headless EC2 Mac bootstrap for iOSWorld.
#
# This script prepares a macOS host that already has Xcode installed, or can
# install Xcode from a user-provided .xip. It intentionally does not download
# Xcode from Apple on the user's behalf.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

XCODE_APP_PATH="${XCODE_APP_PATH:-/Applications/Xcode.app}"
XCODE_XIP_PATH="${XCODE_XIP_PATH:-}"
XCODE_XIP_S3="${XCODE_XIP_S3:-}"
IOS_RUNTIME_VERSION="${IOS_RUNTIME_VERSION:-}"
IOS_RUNTIME_BUILD_VERSION="${IOS_RUNTIME_BUILD_VERSION:-}"
IOS_RUNTIME_ARCH="${IOS_RUNTIME_ARCH:-arm64}"
DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro}"
SIM_DEVICE_TYPE="${SIM_DEVICE_TYPE:-}"
APPIUM_PORT="${APPIUM_PORT:-4723}"
BOOTSTRAP_APPS="${BOOTSTRAP_APPS:-1}"
RUN_SMOKE="${RUN_SMOKE:-0}"
SMOKE_TASK_ID="${SMOKE_TASK_ID:-teamchat-003}"
START_APPIUM="${START_APPIUM:-1}"
KEEP_APPIUM="${KEEP_APPIUM:-1}"
SKIP_RUNTIME_DOWNLOAD="${SKIP_RUNTIME_DOWNLOAD:-0}"
CHECK_ONLY="${CHECK_ONLY:-0}"
ENSURE_AWS_CLI="${ENSURE_AWS_CLI:-auto}"
XCODE_ONLY="${XCODE_ONLY:-0}"

S3_BUCKET=""
S3_KEY=""
DOWNLOADED_XCODE_XIP=""
XCODE_EXPAND_TMP_DIR=""

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  scripts/setup_mac_host.sh
  scripts/aws/bootstrap_mac_host.sh

Common modes:
  CHECK_ONLY=1 scripts/setup_mac_host.sh
      Run non-mutating diagnostics. If Xcode is not installed yet, set
      XCODE_XIP_PATH or XCODE_XIP_S3 so the check can verify the source.

  scripts/setup_mac_host.sh
      Select/install Xcode, install an iOS runtime, create/boot the simulator,
      install Python/Node/Appium dependencies, build the 26 apps, and start
      Appium.

Xcode sources:
  XCODE_APP_PATH=/Applications/Xcode.app
  XCODE_XIP_PATH=/path/to/Xcode.xip
  XCODE_XIP_S3=s3://private-bucket/xcode/Xcode.xip

Useful options:
  DEVICE_NAME="iPhone 17 Pro"
  IOS_RUNTIME_VERSION=26.2
  IOS_RUNTIME_BUILD_VERSION=23C54
  SIM_DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro
  BOOTSTRAP_APPS=0
  START_APPIUM=0
  RUN_SMOKE=1
  SMOKE_TASK_ID=teamchat-003
  XCODE_ONLY=1

This script does not download Xcode from Apple. Provide an installed Xcode,
a licensed local .xip, or a private S3 .xip.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

xcode_is_installed() {
  [[ -d "$XCODE_APP_PATH/Contents/Developer" ]]
}

parse_s3_uri() {
  local uri="${1#s3://}"
  S3_BUCKET="${uri%%/*}"
  S3_KEY="${uri#*/}"
  [[ -n "$S3_BUCKET" && -n "$S3_KEY" && "$S3_BUCKET" != "$S3_KEY" ]] || die "Invalid S3 URI: $1"
}

verify_xcode_s3_access() {
  [[ -n "$XCODE_XIP_S3" ]] || return
  require_cmd aws
  parse_s3_uri "$XCODE_XIP_S3"
  log "Verifying Xcode .xip S3 access: $XCODE_XIP_S3"
  aws s3api head-object \
    --bucket "$S3_BUCKET" \
    --key "$S3_KEY" \
    --query '{Size:ContentLength,LastModified:LastModified,Encryption:ServerSideEncryption}' \
    --output table
}

install_xcode_from_xip() {
  local source_xip="$1"
  local tmp_dir expanded_app

  [[ -f "$source_xip" ]] || die "Xcode .xip not found: $source_xip"
  tmp_dir="$(mktemp -d /tmp/iosworld-xcode.XXXXXX)"
  XCODE_EXPAND_TMP_DIR="$tmp_dir"
  trap '[[ -z "${XCODE_EXPAND_TMP_DIR:-}" ]] || sudo rm -rf "$XCODE_EXPAND_TMP_DIR"' RETURN

  log "Expanding Xcode .xip. This can take a while."
  (cd "$tmp_dir" && sudo xip --expand "$source_xip")
  expanded_app="$(find "$tmp_dir" -maxdepth 1 -type d -name 'Xcode*.app' | head -n 1 || true)"
  [[ -n "$expanded_app" ]] || die "No Xcode.app found after expanding $source_xip"

  log "Installing Xcode to $XCODE_APP_PATH"
  sudo rm -rf "$XCODE_APP_PATH"
  sudo mv "$expanded_app" "$XCODE_APP_PATH"
  sudo xattr -dr com.apple.quarantine "$XCODE_APP_PATH" 2>/dev/null || true
  sudo rm -rf "$tmp_dir"
  XCODE_EXPAND_TMP_DIR=""
  trap - RETURN
}

ensure_xcode() {
  if xcode_is_installed; then
    log "Using existing Xcode: $XCODE_APP_PATH"
  else
    if [[ -n "$XCODE_XIP_S3" ]]; then
      require_cmd aws
      local tmp_xip="/tmp/iosworld-xcode.xip"
      DOWNLOADED_XCODE_XIP="$tmp_xip"
      verify_xcode_s3_access
      log "Downloading Xcode .xip from $XCODE_XIP_S3"
      aws s3 cp "$XCODE_XIP_S3" "$tmp_xip"
      install_xcode_from_xip "$tmp_xip"
      rm -f "$tmp_xip"
      DOWNLOADED_XCODE_XIP=""
    elif [[ -n "$XCODE_XIP_PATH" ]]; then
      install_xcode_from_xip "$XCODE_XIP_PATH"
    else
      die "Full Xcode is not installed. Set XCODE_XIP_PATH or XCODE_XIP_S3, or install Xcode at $XCODE_APP_PATH first."
    fi
  fi

  log "Selecting Xcode and accepting first-launch requirements"
  sudo xcode-select -s "$XCODE_APP_PATH/Contents/Developer"
  sudo xcodebuild -license accept >/dev/null 2>&1 || true
  sudo xcodebuild -runFirstLaunch
  xcodebuild -version
}

ensure_aws_cli() {
  if [[ "$ENSURE_AWS_CLI" == "0" ]]; then
    return
  fi
  if [[ "$ENSURE_AWS_CLI" == "auto" && -z "$XCODE_XIP_S3" ]]; then
    return
  fi
  if command -v aws >/dev/null 2>&1; then
    log "AWS CLI available: $(aws --version 2>&1 | head -n 1)"
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    log "Installing AWS CLI via Homebrew"
    brew install awscli
    return
  fi
  die "AWS CLI is missing and Homebrew is not available. Install AWS CLI or set ENSURE_AWS_CLI=0."
}

runtime_selector() {
  python3 - "$IOS_RUNTIME_VERSION" <<'PY'
import json
import subprocess
import sys

requested = sys.argv[1].strip()
proc = subprocess.run(["xcrun", "simctl", "list", "runtimes", "-j"], capture_output=True, text=True)
if proc.returncode != 0:
    sys.exit(1)
data = json.loads(proc.stdout or "{}")
runtimes = []
for item in data.get("runtimes", []):
    if item.get("platform") != "iOS" or not item.get("isAvailable", False):
        continue
    version = str(item.get("version") or "")
    identifier = item.get("identifier") or ""
    if requested and not version.startswith(requested):
        continue
    runtimes.append((version, identifier))
if not runtimes:
    sys.exit(2)

def version_key(pair):
    version = pair[0]
    return tuple(int(part) for part in version.split(".") if part.isdigit())

runtimes.sort(key=version_key)
print(runtimes[-1][1])
PY
}

ensure_ios_runtime() {
  local runtime_id download_args

  if runtime_id="$(runtime_selector 2>/dev/null)"; then
    log "Using iOS runtime: $runtime_id"
    return
  fi

  [[ "$SKIP_RUNTIME_DOWNLOAD" == "1" ]] && die "No matching iOS runtime installed and SKIP_RUNTIME_DOWNLOAD=1."

  log "Downloading iOS Simulator runtime through xcodebuild"
  download_args=(-downloadPlatform iOS -architectureVariant "$IOS_RUNTIME_ARCH")
  if [[ -n "$IOS_RUNTIME_BUILD_VERSION" ]]; then
    download_args+=(-buildVersion "$IOS_RUNTIME_BUILD_VERSION")
  fi
  xcodebuild "${download_args[@]}"

  runtime_id="$(runtime_selector)" || die "iOS runtime download finished, but no matching runtime is available."
  log "Installed iOS runtime: $runtime_id"
}

device_type_selector() {
  python3 - "$DEVICE_NAME" "$SIM_DEVICE_TYPE" <<'PY'
import json
import subprocess
import sys

device_name, requested = sys.argv[1:3]
proc = subprocess.run(["xcrun", "simctl", "list", "devicetypes", "-j"], capture_output=True, text=True)
if proc.returncode != 0:
    sys.exit(1)
types = json.loads(proc.stdout or "{}").get("devicetypes", [])
if requested:
    for item in types:
        if item.get("identifier") == requested or item.get("name") == requested:
            print(item["identifier"])
            sys.exit(0)
    sys.exit(2)
for item in types:
    if item.get("name") == device_name:
        print(item["identifier"])
        sys.exit(0)
for item in types:
    name = item.get("name") or ""
    if "iPhone" in name and ("Pro" in name or "Max" in name):
        print(item["identifier"])
        sys.exit(0)
for item in types:
    name = item.get("name") or ""
    if "iPhone" in name:
        print(item["identifier"])
        sys.exit(0)
sys.exit(3)
PY
}

existing_device_udid() {
  python3 - "$DEVICE_NAME" <<'PY'
import json
import subprocess
import sys

name = sys.argv[1]
proc = subprocess.run(["xcrun", "simctl", "list", "devices", "available", "-j"], capture_output=True, text=True)
if proc.returncode != 0:
    sys.exit(1)
for devices in (json.loads(proc.stdout or "{}").get("devices") or {}).values():
    for device in devices:
        if device.get("name") == name and device.get("isAvailable", True):
            print(device.get("udid", ""))
            sys.exit(0)
sys.exit(2)
PY
}

ensure_simulator() {
  local runtime_id device_type udid

  runtime_id="$(runtime_selector)" || die "No iOS runtime available."
  if udid="$(existing_device_udid 2>/dev/null)"; then
    log "Using existing simulator: $DEVICE_NAME ($udid)"
  else
    device_type="$(device_type_selector)" || die "Could not find an iPhone simulator device type."
    log "Creating simulator: $DEVICE_NAME ($device_type, $runtime_id)"
    udid="$(xcrun simctl create "$DEVICE_NAME" "$device_type" "$runtime_id")"
  fi

  log "Booting simulator: $DEVICE_NAME ($udid)"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b

  export SIMCTL_UDID="$udid"
  export PHONE_SIMCTL_UDID="$udid"
  export DEVICE_NAME
  export PHONE_DEVICE_NAME="$DEVICE_NAME"
  export APPIUM_URL="http://127.0.0.1:$APPIUM_PORT"
}

preflight_check() {
  local runtime_id device_type node_version appium_version xcode_ready=0

  log "Running non-mutating Mac host preflight"
  is_macos || die "This script must run on macOS, such as an AWS EC2 Mac instance."
  require_cmd python3
  require_cmd curl

  if xcode_is_installed; then
    log "Xcode app found: $XCODE_APP_PATH"
    xcode_ready=1
  elif [[ -n "$XCODE_XIP_PATH" && -f "$XCODE_XIP_PATH" ]]; then
    log "Xcode app missing, but XCODE_XIP_PATH exists: $XCODE_XIP_PATH"
  elif [[ -n "$XCODE_XIP_S3" ]]; then
    require_cmd aws
    verify_xcode_s3_access
    log "Xcode app missing, but XCODE_XIP_S3 is configured: $XCODE_XIP_S3"
  else
    die "Full Xcode is not installed. Set XCODE_XIP_PATH or XCODE_XIP_S3, or install Xcode at $XCODE_APP_PATH first."
  fi

  if [[ "$xcode_ready" != "1" ]]; then
    log "Skipping Xcode-dependent checks until full setup installs Xcode from the configured source."
  else
    require_cmd xcodebuild
    require_cmd xcrun
    xcodebuild -version

    if [[ "$XCODE_ONLY" == "1" ]]; then
      log "XCODE_ONLY=1; skipping iOS runtime and simulator device checks."
    else
      runtime_id="$(runtime_selector)" || die "No matching iOS runtime is currently installed. Bootstrap can download it unless SKIP_RUNTIME_DOWNLOAD=1."
      log "Matching iOS runtime available: $runtime_id"

      device_type="$(device_type_selector)" || die "Could not find an iPhone simulator device type for DEVICE_NAME=$DEVICE_NAME."
      log "Matching simulator device type available: $device_type"
    fi
  fi

  if command -v node >/dev/null 2>&1; then
    node_version="$(node --version 2>/dev/null || true)"
    log "Node available: ${node_version:-unknown}"
  else
    log "Node is not installed yet; scripts/setup_env.sh can install node@20 via Homebrew."
  fi

  if command -v appium >/dev/null 2>&1; then
    appium_version="$(appium --version 2>/dev/null || true)"
    log "Appium available: ${appium_version:-unknown}"
  else
    log "Appium is not installed yet; scripts/setup_env.sh will install it."
  fi

  if command -v aws >/dev/null 2>&1; then
    log "AWS CLI available: $(aws --version 2>&1 | head -n 1)"
  elif [[ "$ENSURE_AWS_CLI" == "1" || ( "$ENSURE_AWS_CLI" == "auto" && -n "$XCODE_XIP_S3" ) ]]; then
    log "AWS CLI is not installed yet; full setup will install it with Homebrew if available."
  else
    log "AWS CLI check skipped."
  fi

  log "Preflight passed. No host state was changed."
}

start_appium() {
  if [[ "$START_APPIUM" != "1" ]]; then
    return 0
  fi
  if curl -fsS "http://127.0.0.1:$APPIUM_PORT/status" >/dev/null 2>&1; then
    log "Appium already running on port $APPIUM_PORT"
    return
  fi

  log "Starting Appium on port $APPIUM_PORT"
  mkdir -p "$REPO_ROOT/results"
  nohup appium --port "$APPIUM_PORT" --log-level warn >"$REPO_ROOT/results/aws-appium.log" 2>&1 &
  APPIUM_PID=$!

  for _ in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:$APPIUM_PORT/status" >/dev/null 2>&1; then
      log "Appium is ready (pid $APPIUM_PID)"
      if [[ "$KEEP_APPIUM" != "1" ]]; then
        trap 'kill "$APPIUM_PID" >/dev/null 2>&1 || true' EXIT
      fi
      return
    fi
    sleep 1
  done

  die "Appium did not become ready. See results/aws-appium.log"
}

run_setup() {
  log "Installing Python, Node, Appium, and project dependencies"
  "$REPO_ROOT/scripts/setup_env.sh"
}

bootstrap_apps() {
  [[ "$BOOTSTRAP_APPS" == "1" ]] || return 0
  log "Building and installing iOSWorld apps"
  OPEN_SIMULATOR=false SIM_DEVICE_NAME="$DEVICE_NAME" "$REPO_ROOT/iphone/bootstrap/bootstrap_ios_apps.sh"
}

run_smoke() {
  [[ "$RUN_SMOKE" == "1" ]] || return 0
  log "Running smoke task: $SMOKE_TASK_ID"
  "$REPO_ROOT/scripts/run_task_by_id.sh" "$SMOKE_TASK_ID" --provider "${LLM_PROVIDER:-vllm}" --model "${LLM_MODEL:-qwen3.5-35B-a3}"
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  if [[ "$CHECK_ONLY" == "1" ]]; then
    preflight_check
    return
  fi

  is_macos || die "This script must run on macOS, such as an AWS EC2 Mac instance."
  require_cmd sudo
  require_cmd python3
  require_cmd curl
  trap '[[ -z "${DOWNLOADED_XCODE_XIP:-}" ]] || rm -f "$DOWNLOADED_XCODE_XIP"' EXIT

  cd "$REPO_ROOT"
  ensure_aws_cli
  ensure_xcode
  if [[ "$XCODE_ONLY" == "1" ]]; then
    log "XCODE_ONLY=1; Xcode install/selection verified. Skipping runtime, simulator, app bootstrap, and Appium."
    return
  fi
  ensure_ios_runtime
  ensure_simulator
  run_setup
  bootstrap_apps
  start_appium
  run_smoke

  log "AWS Mac host is ready."
  log "Simulator UDID: ${SIMCTL_UDID:-}"
  log "Appium URL: http://127.0.0.1:$APPIUM_PORT"
}

main "$@"
