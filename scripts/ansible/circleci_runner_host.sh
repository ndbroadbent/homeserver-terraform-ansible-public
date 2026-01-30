#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🔧 Configuring CircleCI Runner container..."

# Get terraform variables
EXTRA_VARS=$(get_terraform_vars "circleci_runner_container_id")

run_ansible_playbook "circleci_runner_host" "configure the container" --extra-vars "$EXTRA_VARS" "$@"

show_success "CircleCI Runner container configuration"
log "$BLUE" "🐳 Container 201 is now configured"
