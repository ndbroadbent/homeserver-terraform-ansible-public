#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../../shared/common.sh"

log "$BLUE" "🛡️  Setting up AdGuard Home on Raspberry Pi..."

check_project_root

run_ansible_playbook "adguard_home" "install and configure AdGuard Home" "$@"

show_success "AdGuard Home installation" "adguard"
log "$BLUE" "💡 AdGuard Home web interface: http://$(yq '.networks.main.hosts.adguard' config/network.yaml):3000"