#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main script
log "$BLUE" "🔧 Starting Terraform linting..."

# Check if terraform is installed
if ! command_exists terraform; then
    log "$RED" "❌ terraform is not installed"
    log "$YELLOW" "Install terraform: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

# Check if tflint is installed
if ! command_exists tflint; then
    log "$RED" "❌ tflint is not installed"
    log "$YELLOW" "Install tflint: https://github.com/terraform-linters/tflint#installation"
    exit 1
fi

# Find terraform directories (simplified approach)
terraform_dirs=()
if [[ -d "terraform" ]]; then
    # Find all subdirectories in terraform/ that contain .tf files
    while IFS= read -r dir; do
        if [[ -n "$dir" ]]; then
            terraform_dirs+=("$dir")
        fi
    done < <(find terraform -name "*.tf" -exec dirname {} \; 2>/dev/null | sort -u)
fi

if [[ ${#terraform_dirs[@]} -eq 0 ]]; then
    log "$YELLOW" "⚠️  No Terraform files found"
    exit 0
fi

log "$BLUE" "🎯 Found ${#terraform_dirs[@]} Terraform directory(ies) to lint"

# Step 1: Check formatting
log "$BLUE" "📝 Step 1: Checking Terraform formatting..."
format_issues=0
for dir in "${terraform_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        log "$BLUE" "   📁 Checking $dir"
        if ! terraform fmt -check -recursive "$dir" >/dev/null 2>&1; then
            log "$RED" "   ❌ Formatting issues found in $dir"
            log "$YELLOW" "   💡 Run: terraform fmt -recursive $dir"
            format_issues=$((format_issues + 1))
        else
            log "$GREEN" "   ✅ Formatting OK"
        fi
    fi
done

if [[ $format_issues -gt 0 ]]; then
    log "$RED" "❌ Terraform formatting check failed"
    exit 1
fi

log "$GREEN" "✅ Terraform formatting check passed"

# Step 2: Validate Terraform configuration
log "$BLUE" "🔍 Step 2: Validating Terraform configuration..."
validation_issues=0
for dir in "${terraform_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        log "$BLUE" "   📁 Validating $dir"
        if ! (cd "$dir" && terraform init -backend=false >/dev/null 2>&1 && terraform validate >/dev/null 2>&1); then
            log "$RED" "   ❌ Validation failed in $dir"
            validation_issues=$((validation_issues + 1))
        else
            log "$GREEN" "   ✅ Validation OK"
        fi
    fi
done

if [[ $validation_issues -gt 0 ]]; then
    log "$RED" "❌ Terraform validation failed"
    exit 1
fi

log "$GREEN" "✅ Terraform validation passed"

# Step 3: Run tflint
log "$BLUE" "🔍 Step 3: Running tflint..."
tflint_issues=0

for dir in "${terraform_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        log "$BLUE" "   📁 Linting $dir"
        if ! (cd "$dir" && tflint --no-color >/tmp/tflint-output.txt 2>&1); then
            log "$RED" "   ❌ tflint issues found in $dir:"
            sed 's/^/      /' /tmp/tflint-output.txt
            tflint_issues=$((tflint_issues + 1))
        else
            log "$GREEN" "   ✅ tflint OK"
        fi
    fi
done

if [[ $tflint_issues -gt 0 ]]; then
    log "$RED" "❌ tflint check failed"
    rm -f /tmp/tflint-output.txt
    exit 1
fi

log "$GREEN" "✅ tflint check passed"
rm -f /tmp/tflint-output.txt

# All checks passed
log "$GREEN" "📊 Terraform linting summary:"
log "$GREEN" "✅ Successfully linted all ${#terraform_dirs[@]} Terraform directory(ies)"
log "$GREEN" "🎉 All Terraform checks passed!"
exit 0 
