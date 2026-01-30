#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🚢 Setting up K3s cluster..."

check_project_root

run_ansible_playbook "k3s_lxc" "install K3s
📦 This includes setting up the K3s container and cluster" "$@"

# Get k3s container IP
K3S_IP=$(yq '.networks.main.hosts.k3s' config/network.yaml)

show_success "K3s installation" "k3s"
log "$BLUE" "🐳 K3s cluster is now running"
log "$BLUE" "💡 ArgoCD is available at: http://$K3S_IP:30080"