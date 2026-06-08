#!/usr/bin/env bash
# Convenience entrypoint for preparing a local or EC2 Mac host for iOSWorld.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/aws/bootstrap_mac_host.sh" "$@"
