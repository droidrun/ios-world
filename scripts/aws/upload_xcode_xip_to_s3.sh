#!/usr/bin/env bash
# Upload a user-provided, licensed Xcode .xip to private S3 for EC2 Mac setup.
set -euo pipefail

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
XCODE_XIP_PATH="${XCODE_XIP_PATH:-}"
XCODE_XIP_S3="${XCODE_XIP_S3:-}"
SSE="${SSE:-AES256}"
DRY_RUN="${DRY_RUN:-0}"
VERIFY_ONLY="${VERIFY_ONLY:-0}"

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
  XCODE_XIP_PATH=/path/to/Xcode_26.xip \
  XCODE_XIP_S3=s3://my-private-bucket/xcode/Xcode_26.xip \
    scripts/aws/upload_xcode_xip_to_s3.sh

Optional:
  AWS_REGION=us-west-2
  SSE=AES256              # Set empty to disable --sse.
  DRY_RUN=1               # Print the upload command without uploading.
  VERIFY_ONLY=1           # Only verify the private S3 object is readable.

This helper does not download Xcode from Apple. It only uploads a .xip that
you already obtained under your own Apple account or organization process.
Keep the S3 bucket private.
EOF
}

parse_s3_uri() {
  local uri="${1#s3://}"
  S3_BUCKET="${uri%%/*}"
  S3_KEY="${uri#*/}"
  [[ -n "$S3_BUCKET" && -n "$S3_KEY" && "$S3_BUCKET" != "$S3_KEY" ]] || die "Invalid S3 URI: $1"
}

verify_s3_object() {
  local args=(s3api head-object --bucket "$S3_BUCKET" --key "$S3_KEY")
  if [[ -n "$REGION" ]]; then
    args+=(--region "$REGION")
  fi
  log "Verifying private S3 object is readable."
  aws "${args[@]}" \
    --query '{Size:ContentLength,LastModified:LastModified,Encryption:ServerSideEncryption}' \
    --output table
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  command -v aws >/dev/null 2>&1 || die "Missing required command: aws"
  [[ -n "$XCODE_XIP_S3" ]] || die "Set XCODE_XIP_S3=s3://bucket/key"
  [[ "$XCODE_XIP_S3" == s3://* ]] || die "XCODE_XIP_S3 must start with s3://"
  parse_s3_uri "$XCODE_XIP_S3"

  if [[ "$VERIFY_ONLY" == "1" ]]; then
    verify_s3_object
    return
  fi

  [[ -n "$XCODE_XIP_PATH" ]] || die "Set XCODE_XIP_PATH=/path/to/Xcode.xip"
  [[ -f "$XCODE_XIP_PATH" ]] || die "Xcode .xip not found: $XCODE_XIP_PATH"

  local args=(s3 cp "$XCODE_XIP_PATH" "$XCODE_XIP_S3" --only-show-errors)
  if [[ -n "$REGION" ]]; then
    args+=(--region "$REGION")
  fi
  if [[ -n "$SSE" ]]; then
    args+=(--sse "$SSE")
  fi

  log "Uploading licensed Xcode .xip to private S3."
  log "Source: $XCODE_XIP_PATH"
  log "Target: $XCODE_XIP_S3"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY_RUN=1; upload command:"
    printf 'aws'
    printf ' %q' "${args[@]}"
    printf '\n'
    return
  fi

  aws "${args[@]}"
  verify_s3_object
  log "Upload complete. Use this on the EC2 Mac:"
  printf 'XCODE_XIP_S3=%q scripts/setup_mac_host.sh\n' "$XCODE_XIP_S3"
}

main "$@"
