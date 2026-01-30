#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🚢 Setting up CircleCI Runner LXC container..."

check_project_root

run_ansible_playbook "circleci_runner_lxc" "install CircleCI Runner
📦 This includes setting up the CircleCI Runner container" "$@"

show_success "CircleCI Runner installation" "circleci_runner"