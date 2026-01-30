#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🐳 Configuring k3s container..."

# Get terraform variables
EXTRA_VARS=$(get_terraform_vars "k3s_container_id")

run_ansible_playbook "k3s_host" "configure the k3s container" --extra-vars "$EXTRA_VARS" "$@"

show_success "k3s container configuration"
log "$BLUE" "🐳 Container 200 is now configured"