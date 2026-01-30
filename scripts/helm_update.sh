#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/shared/common.sh"

log "$BLUE" "📦 Checking Helm repository cache..."

HELM_REPO_CACHE_FILE=".helm-repo-update.timestamp"
HELM_REPO_HASH_FILE=".helm-repo-config.hash"
CACHE_DURATION="${1:-3600}"  # Default 1 hour cache

# Calculate current hash of helm-repos.yaml
current_hash=""
if [[ -f "helm-repos.yaml" ]]; then
    current_hash=$(shasum -a 256 helm-repos.yaml | awk '{print $1}')
fi

# Check if cache exists and config hasn't changed
cache_valid=false
if [[ -f "$HELM_REPO_CACHE_FILE" && -f "$HELM_REPO_HASH_FILE" ]]; then
    last_update=$(date -r "$HELM_REPO_CACHE_FILE" +%s)
    now=$(date +%s)
    age=$((now - last_update))
    cached_hash=$(cat "$HELM_REPO_HASH_FILE" 2>/dev/null || echo "")
    
    if [[ $age -lt $CACHE_DURATION && "$current_hash" == "$cached_hash" ]]; then
        cache_valid=true
        log "$GREEN" "✅ Helm repositories are up to date (cached, updated $((age/60)) min ago)"
    fi
fi

if [[ "$cache_valid" == "true" ]]; then
    exit 0
else
    if [[ -f "$HELM_REPO_HASH_FILE" ]]; then
        cached_hash=$(cat "$HELM_REPO_HASH_FILE" 2>/dev/null || echo "")
        if [[ "$current_hash" != "$cached_hash" ]]; then
            log "$BLUE" "📦 Updating Helm repositories (config changed)..."
        else
            log "$BLUE" "📦 Updating Helm repositories (cache expired)..."
        fi
    else
        log "$BLUE" "📦 Updating Helm repositories (no cache)..."
    fi
    
    helm repo update
    touch "$HELM_REPO_CACHE_FILE"
    echo "$current_hash" > "$HELM_REPO_HASH_FILE"
    log "$GREEN" "✅ Helm repositories updated"
    exit 0
fi 
