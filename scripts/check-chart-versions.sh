#!/usr/bin/env bash
# Script to check for latest versions of all Helm charts used in the homeserver

set -e

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/shared/common.sh"

log "$BLUE" "🔍 Checking latest versions for all Helm charts..."

# Update all helm repositories first
log "$BLUE" "📦 Updating Helm repositories..."
helm repo update

echo ""
log "$BLUE" "📋 Current vs Latest Chart Versions:"
echo ""

# Track if we found any errors
ERRORS_FOUND=false

# Function to get repo name from URL using helm-repos.yaml mapping
get_repo_name() {
    local repo_url="$1"
    yq ".url_mappings[\"$repo_url\"]" helm-repos.yaml
}

# Function to check chart version
check_chart() {
    local app_name="$1"
    local repo_url="$2" 
    local chart_name="$3"
    local current_version="$4"
    
    # Get repo name from URL mapping
    local repo_name
    repo_name=$(get_repo_name "$repo_url")
    
    if [[ -z "$repo_name" || "$repo_name" == "null" ]]; then
        log "$RED" "  ❌ $app_name: CRITICAL - Repo $repo_url not found in helm-repos.yaml url_mappings"
        ERRORS_FOUND=true
        return
    fi
    
    # Get latest version from repo
    local latest_version
    latest_version=$(helm search repo "$repo_name/$chart_name" --output json | jq -r '.[0].version // "unknown"')
    
    if [[ "$latest_version" == "unknown" ]]; then
        log "$RED" "  ❌ $app_name: CRITICAL - Chart $chart_name not found in repo $repo_name"
        ERRORS_FOUND=true
        return
    fi
    
    # Compare versions
    if [ "$current_version" = "$latest_version" ]; then
        log "$GREEN" "  ✅ $app_name: $current_version (latest)"
    else
        log "$YELLOW" "  📦 $app_name: $current_version → $latest_version (update available)"
    fi
}

# Read and check each application
for app_dir in k3s/apps/*/; do
    if [[ -f "$app_dir/application.yaml" ]]; then
        app_name=$(basename "$app_dir")
        
        # Parse application.yaml to get chart info
        repo_url=$(yq '.repoURL' "$app_dir/application.yaml")
        chart_name=$(yq '.chart' "$app_dir/application.yaml")
        current_version=$(yq '.version' "$app_dir/application.yaml")
        
        check_chart "$app_name" "$repo_url" "$chart_name" "$current_version"
    fi
done

echo ""
if [[ "$ERRORS_FOUND" == "true" ]]; then
    log "$RED" "❌ Critical errors found! Fix the repo/chart issues above."
    exit 1
else
    log "$GREEN" "✅ Version check complete!"
    log "$BLUE" "💡 To update a chart, edit the version in k3s/apps/<app>/application.yaml"
fi