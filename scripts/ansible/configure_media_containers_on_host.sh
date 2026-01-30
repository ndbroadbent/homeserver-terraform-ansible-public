#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🔧 Configuring SSH access for media containers..."

run_ansible_playbook "configure_media_containers_on_host" "set up SSH access via pct exec" "$@"

show_success "Media containers SSH configuration"
