#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🥧 Configuring services on Raspberry Pi..."

check_project_root

run_ansible_playbook "services_pi" "configure Raspberry Pi services" "$@"

show_success "Raspberry Pi services configuration"