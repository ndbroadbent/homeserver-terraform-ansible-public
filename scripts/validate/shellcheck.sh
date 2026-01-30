#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Main script
log "$BLUE" "🔧 Starting ShellCheck validation..."

# Check if shellcheck is installed
if ! command_exists shellcheck; then
    log "$RED" "❌ shellcheck is not installed"
    log "$YELLOW" "Install shellcheck: https://github.com/koalaman/shellcheck#installing"
    exit 1
fi

# Find all shell script files (portable approach without mapfile)
shell_files=()
while IFS= read -r -d '' file; do
    shell_files+=("$file")
done < <(git ls-files -z "*.sh")

if [[ ${#shell_files[@]} -eq 0 ]]; then
    log "$YELLOW" "⚠️  No shell script files found"
    exit 0
fi

log "$BLUE" "🎯 Found ${#shell_files[@]} shell script(s) to check"

# Run shellcheck on all files
log "$BLUE" "🔍 Running shellcheck..."

for file in "${shell_files[@]}"; do
    if [[ -f "$file" ]]; then
        log "$BLUE" "   📁 Checking $file"
        if ! shellcheck -x "$file" >/tmp/shellcheck-output.txt 2>&1; then
            log "$RED" "   ❌ shellcheck issues found in $file:"
            sed < /tmp/shellcheck-output.txt 's/^/      /'
            rm -f /tmp/shellcheck-output.txt
            log "$RED" "❌ shellcheck validation failed"
            exit 1
        else
            log "$GREEN" "   ✅ shellcheck OK"
        fi
    fi
done

log "$GREEN" "✅ shellcheck validation passed"
rm -f /tmp/shellcheck-output.txt

# All checks passed
log "$GREEN" "📊 ShellCheck validation summary:"
log "$GREEN" "✅ Successfully checked all ${#shell_files[@]} shell script(s)"
log "$GREEN" "🎉 All ShellCheck checks passed!"
exit 0 
