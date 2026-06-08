#!/usr/bin/env bash
# Provision an EC2 Mac Dedicated Host + instance for iOSWorld using AWS CLI.
#
# This script intentionally stops after provisioning and connection details.
# Run scripts/setup_mac_host.sh over SSH after the instance is ready.
set -euo pipefail

INSTANCE_TYPE="${INSTANCE_TYPE:-mac2-m2pro.metal}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-west-2}}"
AVAILABILITY_ZONE="${AVAILABILITY_ZONE:-}"
HOST_ID="${HOST_ID:-}"
AMI_ID="${AMI_ID:-}"
MACOS_VERSION="${MACOS_VERSION:-}"
KEY_NAME="${KEY_NAME:-}"
SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-}"
SUBNET_ID="${SUBNET_ID:-}"
INSTANCE_PROFILE_NAME="${INSTANCE_PROFILE_NAME:-}"
VOLUME_SIZE_GB="${VOLUME_SIZE_GB:-250}"
NAME_PREFIX="${NAME_PREFIX:-iosworld}"
SSH_USER="${SSH_USER:-ec2-user}"
SSH_KEY_PATH="${SSH_KEY_PATH:-}"
DRY_RUN="${DRY_RUN:-0}"
CONFIRM_24H_MAC_HOST="${CONFIRM_24H_MAC_HOST:-}"
WAIT_FOR_STATUS_OK="${WAIT_FOR_STATUS_OK:-0}"
SSH_READY_TIMEOUT_SECONDS="${SSH_READY_TIMEOUT_SECONDS:-900}"
REUSE_HOST_ONLY="${REUSE_HOST_ONLY:-0}"
ALLOW_NEW_HOST="${ALLOW_NEW_HOST:-0}"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  scripts/aws/provision_ec2_mac.sh

Required environment:
  KEY_NAME=<ec2-key-pair-name>
  SECURITY_GROUP_ID=<sg-...>
  SUBNET_ID=<subnet-...>

Optional environment:
  AWS_REGION=us-west-2
  AVAILABILITY_ZONE=us-west-2a
  HOST_ID=h-...                           # Reuse an already-allocated Dedicated Host.
  INSTANCE_TYPE=mac2-m2pro.metal
  AMI_ID=ami-...                         # If omitted, use latest AWS macOS AMI for the region/type architecture.
  MACOS_VERSION=tahoe                     # SSM macOS major version when AMI_ID is omitted.
  INSTANCE_PROFILE_NAME=<iam-profile>    # Recommended when using XCODE_XIP_S3.
  VOLUME_SIZE_GB=250
  NAME_PREFIX=iosworld
  SSH_USER=ec2-user
  SSH_KEY_PATH=/path/to/key.pem           # Only used when printing SSH commands.
  DRY_RUN=1                               # Print resolved config and exit before AWS mutations.
  CONFIRM_24H_MAC_HOST=YES                # Required with ALLOW_NEW_HOST=1. EC2 Mac hosts have a 24-hour minimum.
  ALLOW_NEW_HOST=1                        # Required to allocate a new host. Defaults to 0 for cost safety.
  WAIT_FOR_STATUS_OK=0                    # Set 1 to require EC2 status checks, which can lag SSH on macOS.
  SSH_READY_TIMEOUT_SECONDS=900           # Poll SSH readiness when SSH_KEY_PATH is set.
  REUSE_HOST_ONLY=1                       # Refuse to allocate a new host; requires HOST_ID.

Outputs:
  Dedicated Host ID, Instance ID, public DNS, and SSH/bootstrap commands.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

json_query() {
  local query="$1"
  shift
  aws --region "$REGION" "$@" --query "$query" --output text
}

resolve_az() {
  if [[ -n "$AVAILABILITY_ZONE" ]]; then
    printf '%s\n' "$AVAILABILITY_ZONE"
    return
  fi
  json_query 'AvailabilityZones[0].ZoneName' ec2 describe-availability-zones \
    --filters Name=state,Values=available
}

resolve_ami() {
  if [[ -n "$AMI_ID" ]]; then
    printf '%s\n' "$AMI_ID"
    return
  fi

  local arch macos_version param ami
  case "$INSTANCE_TYPE" in
    mac1.metal)
      arch="x86_64_mac"
      macos_version="${MACOS_VERSION:-sequoia}"
      ;;
    *)
      arch="arm64_mac"
      macos_version="${MACOS_VERSION:-tahoe}"
      ;;
  esac
  param="/aws/service/ec2-macos/$macos_version/$arch/latest/image_id"
  ami="$(json_query 'Parameter.Value' ssm get-parameter --name "$param" 2>/dev/null || true)"
  [[ -n "$ami" && "$ami" != "None" ]] || die "Could not resolve macOS AMI from SSM parameter: $param. Set AMI_ID explicitly or choose another MACOS_VERSION."
  printf '%s\n' "$ami"
}

allocate_host() {
  local az="$1"
  if [[ -n "$HOST_ID" ]]; then
    log "Reusing existing Dedicated Host: $HOST_ID"
    printf '%s\n' "$HOST_ID"
    return
  fi
  if [[ "$REUSE_HOST_ONLY" == "1" ]]; then
    die "REUSE_HOST_ONLY=1 but HOST_ID is not set; refusing to allocate a new Dedicated Host."
  fi
  if [[ "$ALLOW_NEW_HOST" != "1" ]]; then
    die "ALLOW_NEW_HOST is not 1 and HOST_ID is not set; refusing to allocate a new Dedicated Host."
  fi
  json_query 'HostIds[0]' ec2 allocate-hosts \
    --availability-zone "$az" \
    --auto-placement off \
    --quantity 1 \
    --instance-type "$INSTANCE_TYPE" \
    --tag-specifications "ResourceType=dedicated-host,Tags=[{Key=Name,Value=$NAME_PREFIX-host}]"
}

launch_instance() {
  local host_id="$1"
  local ami="$2"
  local launch_args=(
    ec2 run-instances
    --image-id "$ami"
    --instance-type "$INSTANCE_TYPE"
    --key-name "$KEY_NAME"
    --security-group-ids "$SECURITY_GROUP_ID"
    --subnet-id "$SUBNET_ID"
    --placement "Tenancy=host,HostId=$host_id"
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=$VOLUME_SIZE_GB,VolumeType=gp3,DeleteOnTermination=true}"
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME_PREFIX-mac}]"
  )

  if [[ -n "$INSTANCE_PROFILE_NAME" ]]; then
    launch_args+=(--iam-instance-profile "Name=$INSTANCE_PROFILE_NAME")
  fi

  json_query 'Instances[0].InstanceId' "${launch_args[@]}"
}

wait_for_instance() {
  local instance_id="$1"
  log "Waiting for instance to enter running state: $instance_id"
  aws --region "$REGION" ec2 wait instance-running --instance-ids "$instance_id"

  if [[ "$WAIT_FOR_STATUS_OK" == "1" ]]; then
    log "Waiting for EC2 status checks: $instance_id"
    aws --region "$REGION" ec2 wait instance-status-ok --instance-ids "$instance_id"
  fi
}

instance_dns() {
  local instance_id="$1"
  json_query 'Reservations[0].Instances[0].PublicDnsName' ec2 describe-instances \
    --instance-ids "$instance_id"
}

wait_for_ssh() {
  local dns="$1"
  local deadline now ssh_args

  [[ -n "$SSH_KEY_PATH" ]] || return 0
  deadline=$((SECONDS + SSH_READY_TIMEOUT_SECONDS))
  ssh_args=(-i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=10)

  log "Waiting for SSH to become reachable: $SSH_USER@$dns"
  while true; do
    if ssh "${ssh_args[@]}" "$SSH_USER@$dns" 'sw_vers -productVersion >/dev/null' >/dev/null 2>&1; then
      log "SSH is ready."
      return 0
    fi
    now=$SECONDS
    if (( now >= deadline )); then
      log "WARNING: SSH did not become reachable within ${SSH_READY_TIMEOUT_SECONDS}s. The instance may still be booting or security-group ingress may not allow this client IP."
      return 0
    fi
    sleep 15
  done
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  require_cmd aws
  [[ -n "$KEY_NAME" ]] || die "Set KEY_NAME to an EC2 key pair name."
  [[ -n "$SECURITY_GROUP_ID" ]] || die "Set SECURITY_GROUP_ID."
  [[ -n "$SUBNET_ID" ]] || die "Set SUBNET_ID."

  local az ami host_id instance_id dns ssh_prefix
  az="$(resolve_az)"
  ami="$(resolve_ami)"

  log "Region: $REGION"
  log "Availability Zone: $az"
  log "Instance type: $INSTANCE_TYPE"
  log "AMI: $ami"
  log "Subnet: $SUBNET_ID"
  log "Security group: $SECURITY_GROUP_ID"
  log "Root EBS volume: ${VOLUME_SIZE_GB}GB gp3"

  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY_RUN=1; exiting before AWS mutations."
    return
  fi

  if [[ "$REUSE_HOST_ONLY" == "1" && -z "$HOST_ID" ]]; then
    die "REUSE_HOST_ONLY=1 but HOST_ID is not set; refusing to allocate a new Dedicated Host."
  fi

  if [[ -z "$HOST_ID" && "$ALLOW_NEW_HOST" != "1" ]]; then
    die "Refusing to allocate a new EC2 Mac Dedicated Host. Set HOST_ID to reuse an existing host, or pass ALLOW_NEW_HOST=1 and CONFIRM_24H_MAC_HOST=YES."
  fi

  if [[ -z "$HOST_ID" && "$CONFIRM_24H_MAC_HOST" != "YES" ]]; then
    die "Refusing to allocate a billable EC2 Mac Dedicated Host. Re-run with ALLOW_NEW_HOST=1 CONFIRM_24H_MAC_HOST=YES after confirming the 24-hour minimum charge."
  fi

  if [[ -n "$HOST_ID" ]]; then
    log "Reusing EC2 Mac Dedicated Host"
  else
    log "Allocating EC2 Mac Dedicated Host"
  fi
  host_id="$(allocate_host "$az")"
  log "Dedicated Host ID: $host_id"

  log "Launching EC2 Mac instance"
  instance_id="$(launch_instance "$host_id" "$ami")"
  log "Instance ID: $instance_id"

  wait_for_instance "$instance_id"
  dns="$(instance_dns "$instance_id")"
  log "Public DNS: $dns"
  wait_for_ssh "$dns"

  ssh_prefix=(ssh)
  if [[ -n "$SSH_KEY_PATH" ]]; then
    ssh_prefix+=( -i "$SSH_KEY_PATH" )
  fi
  ssh_prefix+=( "$SSH_USER@$dns" )

  cat <<EOF

Provisioned.

Dedicated Host:
  $host_id

Instance:
  $instance_id

SSH:
  ${ssh_prefix[*]}

Next:
  ${ssh_prefix[*]} 'git clone https://github.com/ljang0/iOSWorld.git && cd iOSWorld && CHECK_ONLY=1 scripts/setup_mac_host.sh'

Then run the full bootstrap after Xcode is present:
  ${ssh_prefix[*]} 'cd iOSWorld && scripts/setup_mac_host.sh'

Remember: EC2 Mac Dedicated Hosts have a 24-hour minimum allocation.
Release the host after the instance is terminated and AWS host scrubbing completes.
EOF
}

main "$@"
