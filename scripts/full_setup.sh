#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/shared/common.sh"

log "$BLUE" "🚀 Complete Homeserver Infrastructure Deployment..."

# log "$BLUE" "🔧 Setting up development environment..."
# "$(dirname "$0")/setup/dev.sh"

# Apply network configuration
./scripts/terraform/unifi.sh

# Configure Proxmox host
./scripts/ansible/host.sh

# Create VMs and containers
./scripts/terraform/proxmox.sh

# Configure k3s container
./scripts/ansible/k3s_host.sh
./scripts/ansible/k3s_lxc.sh

# Configure CircleCI Runner
./scripts/ansible/circleci_runner_host.sh
./scripts/ansible/circleci_runner_lxc.sh

# Configure Services on Raspberry Pi
./scripts/ansible/services_pi.sh

# Get k3s container IP for final message
K3S_IP=$(yq '.networks.main.hosts.k3s' config/network.yaml)

log "$GREEN" "✅ Complete homeserver infrastructure deployment finished!"
log "$BLUE" ""
log "$BLUE" "🎮 Next steps:"
log "$BLUE" "1. Access ArgoCD at: http://$K3S_IP:30080"
log "$BLUE" "2. Set up MetalLB for LoadBalancer services"
log "$BLUE" "3. Configure Traefik reverse proxy"
log "$BLUE" "4. Deploy applications via ArgoCD"
