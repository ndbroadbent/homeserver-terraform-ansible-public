#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

log "$BLUE" "🔧 Setting up development environment..."

if type lefthook >/dev/null 2>&1; then
    echo "🔧 Setting up git hooks with lefthook..."
    lefthook install
    echo "✅ Git hooks setup complete!"
else
    echo "🔧 lefthook not installed. Skipping git hooks..."
fi

# Run all setup scripts
./scripts/setup/packages.sh
./scripts/setup/python_venv.sh

# Activate venv and install Python requirements
# shellcheck disable=SC1091
source "$VENV_PATH/bin/activate"
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install -r ansible/requirements.yml

./scripts/setup/helm.sh
./scripts/setup/npm.sh
./scripts/setup/verify.sh

echo ""
log "$GREEN" "🎉 Setup complete! You can now run:"
echo "   ./scripts/validate/all.sh"
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "   ./scripts/run_ci_locally.sh"
fi
