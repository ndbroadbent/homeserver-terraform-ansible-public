#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Check if prettier is available
if ! npx prettier --version >/dev/null 2>&1; then
    log "$RED" "❌ Prettier not found. Installing..."
    if command -v npm >/dev/null 2>&1; then
        npm install
    else
        log "$RED" "❌ npm not found. Please install Node.js and npm first."
        exit 1
    fi
fi

# Parse arguments
CHECK_ONLY=false
if [[ "$*" == *"--check"* ]]; then
    CHECK_ONLY=true
fi

# Format Terraform files
log "$BLUE" "🏗️  Terraform formatting..."
if [[ "$CHECK_ONLY" == "true" ]]; then
    log "$BLUE" "📋 Checking Terraform formatting (dry-run)..."
    if terraform fmt -check -recursive terraform/; then
        log "$GREEN" "✅ Terraform files are properly formatted"
    else
        log "$RED" "❌ Some Terraform files need formatting"
        TERRAFORM_FORMAT_FAILED=true
    fi
else
    log "$BLUE" "✨ Formatting Terraform files..."
    terraform fmt -recursive terraform/
    log "$GREEN" "✅ Terraform files have been formatted"
fi

# Format other files with Prettier
log "$BLUE" "🎨 Prettier formatting..."
if [[ "$CHECK_ONLY" == "true" ]]; then
    log "$BLUE" "📋 Checking formatting (dry-run)..."
    if npx prettier --check "**/*.{md,yml,yaml,json,js,ts,html,css,scss}" --ignore-unknown; then
        log "$GREEN" "✅ All files are properly formatted"
    else
        log "$RED" "❌ Some files need formatting. Run './scripts/validate/format.sh' to fix them."
        PRETTIER_FORMAT_FAILED=true
    fi
    
    # Exit with error if any formatting checks failed
    if [[ "${TERRAFORM_FORMAT_FAILED:-false}" == "true" ]] || [[ "${PRETTIER_FORMAT_FAILED:-false}" == "true" ]]; then
        exit 1
    fi
else
    log "$BLUE" "✨ Formatting files..."
    npx prettier --write "**/*.{md,yml,yaml,json,js,ts,html,css,scss}" --ignore-unknown
    log "$GREEN" "✅ All files have been formatted"
fi
