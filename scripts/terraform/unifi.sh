#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🌐 Applying Terraform network configuration to Unifi..."
log "$BLUE" "📡 This will configure VLANs, firewall rules, and device settings"

if ! ./terraform/run_terraform.sh unifi apply -auto-approve; then
    log "$RED" "❌ Terraform apply failed for network configuration"
    exit 1
fi

log "$GREEN" "✅ Network configuration completed successfully!"