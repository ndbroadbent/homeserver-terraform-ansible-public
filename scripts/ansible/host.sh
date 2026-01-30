#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🖥️  Configuring Proxmox host..."

run_ansible_playbook "host" "configure host settings" "$@"

show_success "Host configuration"