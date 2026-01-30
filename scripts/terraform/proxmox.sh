#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🖥️  Applying Terraform Proxmox configuration..."
log "$BLUE" "🚀 This will create/update VMs and containers in Proxmox"

if ! ./terraform/run_terraform.sh proxmox apply -auto-approve; then
    log "$RED" "❌ Terraform apply failed for Proxmox VMs/LXCs configuration"
    exit 1
fi

log "$GREEN" "✅ Proxmox VMs and containers deployed successfully!"