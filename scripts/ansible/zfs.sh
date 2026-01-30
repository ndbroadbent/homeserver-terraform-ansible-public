#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "💾 Configuring ZFS storage..."

check_project_root

run_ansible_playbook "zfs" "configure ZFS storage pool and datasets" "$@"

show_success "ZFS configuration"