#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Set environment variables for non-interactive operation
export DEBIAN_FRONTEND=noninteractive
export TZ=UTC
export TERM=xterm

log "$BLUE" "🔧 Setting up Helm repositories..."

# Add required Helm repositories from central config
log "$BLUE" "📦 Adding Helm repositories from helm-repos.yaml..."
if [[ -f "helm-repos.yaml" ]]; then
    # Extract repository entries and add them
    yq '.repositories | to_entries | .[] | .key + " " + .value' helm-repos.yaml | while read -r repo_name repo_url; do
        log "$BLUE" "  Checking $repo_name..."
        if helm repo list | grep -q "^${repo_name}[[:space:]]"; then
            log "$GREEN" "    (already exists)"
        elif [[ "$repo_url" == oci://* ]]; then
            log "$YELLOW" "    (OCI repository - skipping helm repo add)"
        else
            log "$BLUE" "  Adding $repo_name: $repo_url"
            helm repo add "$repo_name" "$repo_url"
        fi
    done
    
    # Use shared helm update script with caching
    "$(dirname "$0")/../helm_update.sh"
else
    log "$YELLOW" "  No helm-repos.yaml found, skipping repository setup"
fi

log "$GREEN" "✅ Helm repositories setup complete!"
