#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🔒 Configuring Personal Tailscale Exit Node..."

check_project_root

run_ansible_playbook "tailscale_exit_node" "configure personal Tailscale exit node" "$@"

show_success "Personal Tailscale Exit Node configuration" "tailscale_exit_node"
log "$BLUE" "🔒 Personal Tailscale exit node is configured"
