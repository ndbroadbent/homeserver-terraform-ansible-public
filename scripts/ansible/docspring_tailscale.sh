#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🔒 Configuring ExampleCompany Tailscale Exit Node..."

check_project_root

run_ansible_playbook "example-company_tailscale" "configure ExampleCompany Tailscale exit node" "$@"

show_success "ExampleCompany Tailscale configuration" "example-company_tailscale"
log "$BLUE" "🔒 ExampleCompany Tailscale exit node is configured"
