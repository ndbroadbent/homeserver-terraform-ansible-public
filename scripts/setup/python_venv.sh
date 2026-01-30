#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Set environment variables for non-interactive operation
export DEBIAN_FRONTEND=noninteractive
export TZ=UTC
export TERM=xterm

log "$BLUE" "🐍 Setting up Python virtual environment at $VENV_PATH..."

# Check if venv already exists and has ansible-lint
if [[ -d "$VENV_PATH" ]] && [[ -f "$VENV_PATH/bin/ansible-lint" ]]; then
    log "$GREEN" "✅ Python virtual environment already exists with ansible-lint"
    exit 0
fi

if command -v python3.12 >/dev/null 2>&1; then
    python3.12 -m venv "$VENV_PATH"
else
    python3 -m venv "$VENV_PATH"
fi
# shellcheck disable=SC1091
source "$VENV_PATH/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt
log "$GREEN" "✅ Python packages installed from requirements.txt"

# Install Ansible collections
log "$BLUE" "📦 Installing Ansible collections..."
cd ansible
ansible-galaxy collection install -r requirements.yml
cd ..
log "$GREEN" "✅ Ansible collections installed"

log "$GREEN" "✅ Python virtual environment setup complete!"
