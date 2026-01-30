#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../../shared/common.sh"

log "$BLUE" "📡 Setting up Zigbee2MQTT on Raspberry Pi..."

check_project_root

run_ansible_playbook "services_pi/zigbee2mqtt" "install and configure Zigbee2MQTT" "$@"

show_success "Zigbee2MQTT installation" "services_pi"
log "$BLUE" "💡 Zigbee2MQTT web interface: http://$(yq '.networks.main.hosts.services_pi' config/network.yaml):8080"