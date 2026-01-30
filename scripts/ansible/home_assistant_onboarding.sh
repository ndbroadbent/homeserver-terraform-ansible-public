#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🏠 Setting up Home Assistant onboarding..."

check_project_root

run_ansible_playbook "home_assistant_onboarding" "complete Home Assistant initial setup
📦 This creates the owner account and completes onboarding" "$@"

show_success "Home Assistant onboarding" "home-assistant"
log "$BLUE" "🏠 Home Assistant is ready at: https://ha.home.example.com"
