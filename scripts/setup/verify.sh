#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Set environment variables for non-interactive operation
export DEBIAN_FRONTEND=noninteractive
export TZ=UTC
export TERM=xterm

echo "🧪 Verifying installations..."

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [[ ! -f "$VENV_PATH/bin/activate" ]]; then
    echo "❌ $VENV_PATH/bin/activate not found"
    exit 1
fi

# shellcheck disable=SC1091
source "$VENV_PATH/bin/activate"

# Verify installations
tools_to_check="helm yq kubeconform kube-linter actionlint ansible ansible-galaxy ansible-lint kustomize terraform tflint shellcheck conftest"
if [[ "$OS" == "darwin" ]]; then
    tools_to_check="$tools_to_check act"
fi

for tool in $tools_to_check; do
    case $tool in
        helm)
            version_output=$(helm version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        yq)
            version_output=$(yq --version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        kubeconform)
            version_output=$(kubeconform -v 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        kube-linter)
            version_output=$(kube-linter version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        actionlint)
            version_output=$(actionlint --version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        ansible)
            version_output=$(ansible --version 2>&1 | head -1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        ansible-galaxy)
            version_output=$(ansible-galaxy --version 2>&1 | head -1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        ansible-lint)
            version_output=$(ansible-lint --version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        act)
            version_output=$(act --version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        kustomize)
            version_output=$(kustomize version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        terraform)
            version_output=$(terraform version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        tflint)
            version_output=$(tflint --version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        shellcheck)
            version_output=$(shellcheck --version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        conftest)
            version_output=$(conftest --version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
        *)
            version_output=$($tool --version 2>&1) || { echo "❌ $tool: command failed"; exit 1; }
            ;;
    esac
    
    if echo "$version_output" | grep -iE '^error|^fail|not found|usage:|flag provided but not defined|command not found' > /dev/null; then
        echo "❌ $tool: $version_output"
        echo "❌ $tool failed verification. Please check installation."
        exit 1
    else
        echo "✅ $tool: $version_output"
    fi
    unset version_output
done

echo ""
echo "🎉 All tools verified successfully!"

