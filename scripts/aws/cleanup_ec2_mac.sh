#!/usr/bin/env bash
# Cost-control helper for EC2 Mac tests.
#
# Terminates a known instance, optionally removes temporary SSH/key resources,
# and attempts to release the Dedicated Host when AWS no longer marks it
# occupied. This script never allocates or launches resources.
set -euo pipefail

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-west-2}}"
HOST_ID="${HOST_ID:-}"
INSTANCE_ID="${INSTANCE_ID:-}"
SECURITY_GROUP_RULE_ID="${SECURITY_GROUP_RULE_ID:-}"
KEY_NAME="${KEY_NAME:-}"
DELETE_KEY_PAIR="${DELETE_KEY_PAIR:-0}"
WAIT_SECONDS="${WAIT_SECONDS:-600}"
POLL_SECONDS="${POLL_SECONDS:-15}"
DRY_RUN="${DRY_RUN:-0}"

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
  HOST_ID=h-... [INSTANCE_ID=i-...] scripts/aws/cleanup_ec2_mac.sh

Optional:
  AWS_REGION=us-east-1
  SECURITY_GROUP_RULE_ID=sgr-...   # Temporary SSH rule to revoke.
  KEY_NAME=iosworld-test-...       # EC2 key pair to delete only with DELETE_KEY_PAIR=1.
  DELETE_KEY_PAIR=1                # Required before deleting KEY_NAME.
  WAIT_SECONDS=600                 # Poll for release readiness.
  POLL_SECONDS=15
  DRY_RUN=1                        # Print intended actions only.

This script never allocates or launches EC2 resources.
EOF
}

aws_ec2() {
  aws --region "$REGION" ec2 "$@"
}

instance_state() {
  local id="$1"
  aws_ec2 describe-instances \
    --instance-ids "$id" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null || true
}

host_state_json() {
  aws_ec2 describe-hosts \
    --host-ids "$HOST_ID" \
    --query 'Hosts[0].{State:State,Instances:Instances}' \
    --output json
}

release_host() {
  aws_ec2 release-hosts --host-ids "$HOST_ID" --output json
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  command -v aws >/dev/null 2>&1 || die "Missing aws CLI."
  [[ -n "$HOST_ID" ]] || die "Set HOST_ID."

  log "Region: $REGION"
  log "Host: $HOST_ID"
  [[ -z "$INSTANCE_ID" ]] || log "Instance: $INSTANCE_ID"

  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY_RUN=1; no AWS mutations will be made."
    host_state_json || true
    return
  fi

  if [[ -n "$INSTANCE_ID" ]]; then
    local state
    state="$(instance_state "$INSTANCE_ID")"
    if [[ -n "$state" && "$state" != "None" && "$state" != "terminated" ]]; then
      log "Terminating instance $INSTANCE_ID (current state: $state)"
      aws_ec2 terminate-instances --instance-ids "$INSTANCE_ID" --output json >/dev/null
    else
      log "Instance $INSTANCE_ID is already terminated or not found."
    fi
  fi

  if [[ -n "$SECURITY_GROUP_RULE_ID" ]]; then
    log "Revoking temporary security group rule $SECURITY_GROUP_RULE_ID"
    aws_ec2 revoke-security-group-ingress \
      --security-group-rule-ids "$SECURITY_GROUP_RULE_ID" \
      --output json >/dev/null 2>&1 || true
  fi

  if [[ -n "$KEY_NAME" && "$DELETE_KEY_PAIR" == "1" ]]; then
    log "Deleting temporary EC2 key pair $KEY_NAME"
    aws_ec2 delete-key-pair --key-name "$KEY_NAME" --output json >/dev/null 2>&1 || true
  elif [[ -n "$KEY_NAME" ]]; then
    log "Leaving EC2 key pair $KEY_NAME intact. Set DELETE_KEY_PAIR=1 only for temporary keys."
  fi

  local deadline rc
  deadline=$((SECONDS + WAIT_SECONDS))
  while true; do
    log "Attempting to release host $HOST_ID"
    set +e
    release_host
    rc=$?
    set -e
    if [[ "$rc" -eq 0 ]]; then
      log "Release command returned successfully."
      return 0
    fi
    if (( SECONDS >= deadline )); then
      log "Host is not releasable yet. Current state:"
      host_state_json || true
      return 1
    fi
    sleep "$POLL_SECONDS"
  done
}

main "$@"
