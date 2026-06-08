#!/usr/bin/env bash
# Run a guarded iOSWorld smoke on an existing EC2 Mac Dedicated Host.
#
# This script never allocates a Dedicated Host. It either reuses a running
# instance on HOST_ID or launches exactly one instance on that existing host
# when AWS marks the host available.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
HOST_ID="${HOST_ID:-}"
AVAILABILITY_ZONE="${AVAILABILITY_ZONE:-us-east-1d}"
INSTANCE_TYPE="${INSTANCE_TYPE:-mac2-m2pro.metal}"
MACOS_VERSION="${MACOS_VERSION:-tahoe}"
SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-}"
SUBNET_ID="${SUBNET_ID:-}"
INSTANCE_PROFILE_NAME="${INSTANCE_PROFILE_NAME:-}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}"
SSH_USER="${SSH_USER:-ec2-user}"
KEY_NAME="${KEY_NAME:-}"
XCODE_XIP_S3="${XCODE_XIP_S3:-}"
XCODE_XIP_PATH="${XCODE_XIP_PATH:-}"
RUN_BOOTSTRAP="${RUN_BOOTSTRAP:-0}"
RUN_XCODE_ONLY="${RUN_XCODE_ONLY:-0}"
RUN_AGENT_SMOKE="${RUN_AGENT_SMOKE:-0}"
SMOKE_TASK_ID="${SMOKE_TASK_ID:-teamchat-003}"
OPENAI_MODEL="${OPENAI_MODEL:-gpt-5.4-mini}"
REMOTE_ROOT="${REMOTE_ROOT:-/Users/ec2-user/iOSWorld}"
DRY_RUN="${DRY_RUN:-0}"

TEMP_KEY_CREATED=0
TEMP_KEY_NAME=""
TEMP_SG_RULE_ID=""
INSTANCE_ID=""
PUBLIC_DNS=""

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

shell_quote() {
  printf '%q' "$1"
}

usage() {
  cat <<'EOF'
Usage:
  HOST_ID=h-... SECURITY_GROUP_ID=sg-... SUBNET_ID=subnet-... scripts/aws/smoke_ec2_mac.sh

Required:
  HOST_ID                  Existing EC2 Mac Dedicated Host to reuse.
  SECURITY_GROUP_ID         Security group for SSH access.
  SUBNET_ID                 Subnet in the same AZ as the host.

Important options:
  AWS_REGION=us-east-1
  AVAILABILITY_ZONE=us-east-1d
  INSTANCE_TYPE=mac2-m2pro.metal
  INSTANCE_PROFILE_NAME=... IAM instance profile with S3 read access.
  SSH_KEY_PATH=~/.ssh/id_rsa
  XCODE_XIP_S3=s3://...     OSS path; remote EC2 Mac downloads and installs Xcode.
  XCODE_XIP_PATH=/path      Remote path to an Xcode .xip already on the EC2 Mac.
  RUN_XCODE_ONLY=1          Install/select Xcode, then stop before runtime/app setup.
  RUN_BOOTSTRAP=1           Build/install iOSWorld apps after preflight.
  RUN_AGENT_SMOKE=1         Run one OpenAI smoke task after Appium is ready.
  SMOKE_TASK_ID=teamchat-003
  DRY_RUN=1                 Validate host state and intended actions only.

This script never allocates a Dedicated Host.
EOF
}

aws_ec2() {
  aws --region "$REGION" ec2 "$@"
}

json_query() {
  local query="$1"
  shift
  aws --region "$REGION" "$@" --query "$query" --output text
}

host_state() {
  json_query 'Hosts[0].State' ec2 describe-hosts --host-ids "$HOST_ID"
}

running_instance_on_host() {
  aws_ec2 describe-instances \
    --filters Name=instance-state-name,Values=pending,running \
    --query "Reservations[].Instances[?Placement.HostId=='$HOST_ID'].InstanceId[]" \
    --output text | awk 'NF {print $1; exit}'
}

instance_dns() {
  local id="$1"
  json_query 'Reservations[0].Instances[0].PublicDnsName' ec2 describe-instances --instance-ids "$id"
}

ensure_temp_key() {
  if [[ -n "$KEY_NAME" ]]; then
    return
  fi
  [[ -f "$SSH_KEY_PATH.pub" ]] || die "SSH public key not found: $SSH_KEY_PATH.pub"
  TEMP_KEY_NAME="iosworld-smoke-$(date +%Y%m%d%H%M%S)"
  log "Importing temporary EC2 key pair: $TEMP_KEY_NAME"
  if [[ "$DRY_RUN" == "1" ]]; then
    KEY_NAME="$TEMP_KEY_NAME"
    return
  fi
  aws_ec2 import-key-pair \
    --key-name "$TEMP_KEY_NAME" \
    --public-key-material "fileb://$SSH_KEY_PATH.pub" \
    --output json >/dev/null
  TEMP_KEY_CREATED=1
  KEY_NAME="$TEMP_KEY_NAME"
}

ensure_ssh_ingress() {
  local current_ip existing rule_json
  [[ -n "$SECURITY_GROUP_ID" ]] || die "Set SECURITY_GROUP_ID."
  current_ip="$(curl -fsS https://checkip.amazonaws.com | tr -d '\n')"
  existing="$(
    aws_ec2 describe-security-groups \
      --group-ids "$SECURITY_GROUP_ID" \
      --query 'SecurityGroups[0].IpPermissions[?IpProtocol==`tcp` && FromPort==`22`].IpRanges[].CidrIp' \
      --output text | tr '\t' '\n'
  )"
  if printf '%s\n' "$existing" | grep -qx "$current_ip/32"; then
    log "SSH ingress already allows $current_ip/32."
    return
  fi
  log "Adding temporary SSH ingress for $current_ip/32."
  if [[ "$DRY_RUN" == "1" ]]; then
    return
  fi
  rule_json="$(
    aws_ec2 authorize-security-group-ingress \
      --group-id "$SECURITY_GROUP_ID" \
      --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$current_ip/32,Description=iosworld-smoke-ssh}]" \
      --output json
  )"
  TEMP_SG_RULE_ID="$(python3 - <<'PY' "$rule_json"
import json, sys
data=json.loads(sys.argv[1])
rules=data.get("SecurityGroupRules") or []
print(rules[0].get("SecurityGroupRuleId","") if rules else "")
PY
)"
}

launch_or_reuse_instance() {
  local state existing
  state="$(host_state)"
  log "Host $HOST_ID state: $state"
  existing="$(running_instance_on_host || true)"
  if [[ -n "$existing" ]]; then
    INSTANCE_ID="$existing"
    PUBLIC_DNS="$(instance_dns "$INSTANCE_ID")"
    log "Reusing existing instance: $INSTANCE_ID"
    return
  fi
  [[ "$state" == "available" ]] || die "Host $HOST_ID is not available yet; current state is $state."
  ensure_temp_key
  ensure_ssh_ingress
  log "Launching one instance on existing host $HOST_ID."
  if [[ "$DRY_RUN" == "1" ]]; then
    return
  fi
  INSTANCE_ID="$(
    REUSE_HOST_ONLY=1 \
    HOST_ID="$HOST_ID" \
    AWS_REGION="$REGION" \
    AVAILABILITY_ZONE="$AVAILABILITY_ZONE" \
    INSTANCE_TYPE="$INSTANCE_TYPE" \
    MACOS_VERSION="$MACOS_VERSION" \
    KEY_NAME="$KEY_NAME" \
    SECURITY_GROUP_ID="$SECURITY_GROUP_ID" \
    SUBNET_ID="$SUBNET_ID" \
    INSTANCE_PROFILE_NAME="$INSTANCE_PROFILE_NAME" \
    SSH_KEY_PATH="$SSH_KEY_PATH" \
      "$SCRIPT_DIR/provision_ec2_mac.sh" 2>"$REPO_ROOT/results/aws-smoke-provision.log" \
      | sed -nE 's/^  (i-[a-f0-9]+)$/\1/p' | head -n 1
  )"
  if [[ -z "$INSTANCE_ID" ]]; then
    INSTANCE_ID="$(aws_ec2 describe-instances \
      --filters Name=instance-state-name,Values=pending,running \
      --query "Reservations[].Instances[?Placement.HostId=='$HOST_ID'].InstanceId[]" --output text | awk 'NF {print $1; exit}')"
  fi
  [[ -n "$INSTANCE_ID" ]] || die "Could not determine launched instance ID. See results/aws-smoke-provision.log."
  PUBLIC_DNS="$(instance_dns "$INSTANCE_ID")"
}

ssh_remote() {
  ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes "$SSH_USER@$PUBLIC_DNS" "$@"
}

rsync_remote() {
  local quoted_key
  quoted_key="$(shell_quote "$SSH_KEY_PATH")"
  rsync -az --delete -e "ssh -i $quoted_key -o StrictHostKeyChecking=accept-new -o BatchMode=yes" "$@"
}

wait_for_ssh() {
  local deadline=$((SECONDS + 900))
  log "Waiting for SSH: $SSH_USER@$PUBLIC_DNS"
  while true; do
    if ssh_remote 'sw_vers && uname -m' >/tmp/iosworld-aws-smoke-ssh.txt 2>/dev/null; then
      cat /tmp/iosworld-aws-smoke-ssh.txt
      return
    fi
    (( SECONDS >= deadline )) && die "SSH did not become ready."
    sleep 15
  done
}

sync_repo() {
  log "Syncing repository to remote $REMOTE_ROOT."
  if [[ "$DRY_RUN" == "1" ]]; then
    return
  fi
  ssh_remote "mkdir -p '$REMOTE_ROOT'"
  rsync_remote \
    --exclude .git \
    --exclude .env \
    --exclude results \
    --exclude .venv \
    --exclude 'iphone/bootstrap/.derived_data' \
    "$REPO_ROOT/" "$SSH_USER@$PUBLIC_DNS:$REMOTE_ROOT/"
}

run_remote_smoke() {
  local setup_env_prefix=""
  if [[ -n "$XCODE_XIP_S3" ]]; then
    setup_env_prefix+="XCODE_XIP_S3=$(shell_quote "$XCODE_XIP_S3") "
  fi
  if [[ -n "$XCODE_XIP_PATH" ]]; then
    setup_env_prefix+="XCODE_XIP_PATH=$(shell_quote "$XCODE_XIP_PATH") "
  fi

  log "Running remote host preflight."
  if [[ "$RUN_XCODE_ONLY" == "1" ]]; then
    ssh_remote "cd '$REMOTE_ROOT' && ${setup_env_prefix}CHECK_ONLY=1 XCODE_ONLY=1 scripts/setup_mac_host.sh"
  else
    ssh_remote "cd '$REMOTE_ROOT' && ${setup_env_prefix}CHECK_ONLY=1 scripts/setup_mac_host.sh"
  fi
  if [[ "$RUN_XCODE_ONLY" == "1" ]]; then
    log "Running remote Xcode-only setup."
    ssh_remote "cd '$REMOTE_ROOT' && ${setup_env_prefix}XCODE_ONLY=1 scripts/setup_mac_host.sh"
    log "Xcode-only smoke passed. Skipping runtime, app bootstrap, Appium, and agent smoke."
    return
  fi
  if [[ "$RUN_BOOTSTRAP" == "1" ]]; then
    log "Running remote full host bootstrap."
    ssh_remote "cd '$REMOTE_ROOT' && ${setup_env_prefix}scripts/setup_mac_host.sh"
  else
    if [[ "$RUN_AGENT_SMOKE" == "1" ]]; then
      die "RUN_AGENT_SMOKE=1 requires RUN_BOOTSTRAP=1 unless the VM is already bootstrapped. For an existing bootstrapped VM, run the task manually over SSH."
    fi
    log "Running remote dependency setup."
    ssh_remote "cd '$REMOTE_ROOT' && scripts/setup_env.sh"
  fi
  ssh_remote "cd '$REMOTE_ROOT' && export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:\$PATH && mkdir -p results && (appium --port 4723 --log-level warn > results/aws-smoke-appium.log 2>&1 </dev/null &)"
  ssh_remote "for i in {1..60}; do curl -fsS http://127.0.0.1:4723/status >/dev/null && exit 0; sleep 1; done; exit 1"
  if [[ "$RUN_AGENT_SMOKE" == "1" ]]; then
    if ! ssh_remote 'test -n "${OPENAI_API_KEY:-}"'; then
      log "Infra smoke passed; agent smoke blocked by missing OPENAI_API_KEY on the remote host."
      return
    fi
    log "Running remote agent smoke task $SMOKE_TASK_ID."
    ssh_remote "cd '$REMOTE_ROOT' && APPIUM_HEADLESS=1 ./scripts/run_task_by_id.sh '$SMOKE_TASK_ID' --provider openai --model '$OPENAI_MODEL'"
  fi
}

cleanup_temp_access() {
  if [[ -n "${TEMP_SG_RULE_ID:-}" ]]; then
    log "Revoking temporary SSH rule $TEMP_SG_RULE_ID."
    aws_ec2 revoke-security-group-ingress --group-id "$SECURITY_GROUP_ID" --security-group-rule-ids "$TEMP_SG_RULE_ID" >/dev/null 2>&1 || true
  fi
  if [[ "$TEMP_KEY_CREATED" == "1" && -n "${TEMP_KEY_NAME:-}" ]]; then
    log "Deleting temporary key pair $TEMP_KEY_NAME."
    aws_ec2 delete-key-pair --key-name "$TEMP_KEY_NAME" >/dev/null 2>&1 || true
  fi
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  command -v aws >/dev/null 2>&1 || die "Missing aws CLI."
  command -v rsync >/dev/null 2>&1 || die "Missing rsync."
  [[ -n "$HOST_ID" ]] || die "Set HOST_ID."
  [[ -n "$SUBNET_ID" ]] || die "Set SUBNET_ID."
  [[ -n "$SECURITY_GROUP_ID" ]] || die "Set SECURITY_GROUP_ID."
  [[ -f "$SSH_KEY_PATH" ]] || die "SSH key not found: $SSH_KEY_PATH"
  mkdir -p "$REPO_ROOT/results"
  trap cleanup_temp_access EXIT
  launch_or_reuse_instance
  [[ "$DRY_RUN" == "1" ]] && return
  wait_for_ssh
  sync_repo
  run_remote_smoke
  log "AWS smoke completed on instance $INSTANCE_ID ($PUBLIC_DNS)."
}

main "$@"
