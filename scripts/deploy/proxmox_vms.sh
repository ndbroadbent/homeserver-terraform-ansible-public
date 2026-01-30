#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🚀 Deploying Proxmox VMs and Containers..."

# Ensure host is configured first
log "$BLUE" "🖥️  Ensuring host configuration is up to date..."
if ! ./scripts/ansible/host.sh "$@"; then
    log "$RED" "❌ Host configuration failed"
    exit 1
fi

# Apply Terraform
log "$BLUE" "🌐 Applying Terraform configuration..."
if ! ./terraform/run_terraform.sh proxmox apply -auto-approve; then
    log "$RED" "❌ Terraform apply failed"
    exit 1
fi

log "$BLUE" "🔧 Configuring containers and VMs..."

# Configure k3s container
if ./scripts/ansible/k3s_host.sh "$@"; then
    log "$GREEN" "✅ K3s container configured"
else
    log "$YELLOW" "⚠️  K3s container configuration failed (may not exist)"
fi

# Configure CircleCI runner container
if ./scripts/ansible/circleci_runner_host.sh "$@"; then
    log "$GREEN" "✅ CircleCI runner container configured"
else
    log "$YELLOW" "⚠️  CircleCI runner container configuration failed (may not exist)"
fi

log "$GREEN" "✅ Proxmox VM/Container deployment completed!"
