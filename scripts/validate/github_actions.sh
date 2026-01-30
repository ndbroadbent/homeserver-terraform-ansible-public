#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Function to validate GitHub Actions workflows
validate_github_actions() {
    log "$BLUE" "🔧 Validating GitHub Actions workflows..."
    
    if [[ ! -d ".github/workflows" ]]; then
        log "$YELLOW" "⚠️  No .github/workflows directory found, skipping GitHub Actions validation"
        return 0
    fi
    
    workflow_files=()
    while IFS= read -r -d '' file; do
        workflow_files+=("$file")
    done < <(find .github/workflows \( -name "*.yml" -o -name "*.yaml" \) -type f -print0)
    
    if [[ ${#workflow_files[@]} -eq 0 ]]; then
        log "$YELLOW" "⚠️  No GitHub Actions workflow files found"
        return 0
    fi
    
    # Use actionlint if available, otherwise use yq for basic YAML validation
    if command -v actionlint >/dev/null 2>&1; then
        log "$BLUE" "   Using actionlint for comprehensive validation..."
        for workflow_file in "${workflow_files[@]}"; do
            if ! actionlint "$workflow_file"; then
                log "$RED" "   ❌ GitHub Actions validation failed for $workflow_file"
                return 1
            fi
        done
        log "$GREEN" "   ✅ All GitHub Actions workflows are valid"
    else
        log "$BLUE" "   Using yq for basic YAML validation (install actionlint for comprehensive checks)..."
        for workflow_file in "${workflow_files[@]}"; do
            if ! yq eval '.' "$workflow_file" >/dev/null 2>&1; then
                log "$RED" "   ❌ Invalid YAML in $workflow_file"
                return 1
            fi
        done
        log "$GREEN" "   ✅ All GitHub Actions workflows have valid YAML syntax"
        log "$YELLOW" "   💡 Install actionlint for comprehensive GitHub Actions validation:"
        log "$YELLOW" "      go install github.com/rhysd/actionlint/cmd/actionlint@latest"
    fi
    
    return 0
}

# Main script
log "$BLUE" "🚀 Starting GitHub Actions validation..."

# Check if yq is available
if ! command -v yq >/dev/null 2>&1; then
    log "$RED" "❌ Missing required tool: yq"
    log "$YELLOW" "Run ./scripts/setup/dev.sh to install it"
    exit 1
fi

# Validate GitHub Actions
if ! validate_github_actions; then
    log "$RED" "🚨 GitHub Actions validation failed"
    exit 1
fi

log "$GREEN" "🎉 GitHub Actions validation passed!"
exit 0
