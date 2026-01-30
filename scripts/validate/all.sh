#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🚀 Starting all validation checks..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Collect all executable shell scripts in the validate directory, excluding run_ci_locally.sh and all.sh itself
validation_scripts=()
for script in "$SCRIPT_DIR"/*.sh; do
  case "$(basename "$script")" in
    run_ci_locally.sh|all.sh) continue ;;
  esac
  [ -x "$script" ] && validation_scripts+=("$script")
done

if [[ ${#validation_scripts[@]} -eq 0 ]]; then
    log "$YELLOW" "⚠️  No validation scripts found"
    exit 0
fi

log "$BLUE" "🎯 Found ${#validation_scripts[@]} validation script(s) to run:"
for script in "${validation_scripts[@]}"; do
    log "$BLUE" "   📁 $(basename "$script")"
done

echo

# Track results
failed_scripts=()
passed_scripts=()
total_scripts=${#validation_scripts[@]}

# Run each validation script
for script in "${validation_scripts[@]}"; do
    script_name=$(basename "$script")
    log "$BLUE" "🔧 Running $script_name..."
    
    if "$script"; then
        log "$GREEN" "✅ $script_name passed"
        passed_scripts+=("$script_name")
    else
        log "$RED" "❌ $script_name failed"
        failed_scripts+=("$script_name")
    fi
    
    echo
done

# Summary
log "$BLUE" "📊 Validation Summary:"
log "$GREEN" "✅ Passed: ${#passed_scripts[@]}/$total_scripts"

if [[ ${#passed_scripts[@]} -gt 0 ]]; then
    log "$GREEN" "   📋 Passed scripts:"
    for script in "${passed_scripts[@]}"; do
        log "$GREEN" "      ✅ $script"
    done
fi

if [[ ${#failed_scripts[@]} -gt 0 ]]; then
    log "$RED" "❌ Failed: ${#failed_scripts[@]}/$total_scripts"
    log "$RED" "   📋 Failed scripts:"
    for script in "${failed_scripts[@]}"; do
        log "$RED" "      ❌ $script"
    done
    log "$RED" "❌ Some validation checks failed"
    exit 1
fi

log "$GREEN" "🎉 All validation checks passed!"
exit 0 
