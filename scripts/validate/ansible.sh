#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# shellcheck disable=SC1091
source "$VENV_PATH/bin/activate" 2>/dev/null || true

cd ansible
ansible-lint 2>&1 | grep -v "WARNING: PATH altered to expand ~ in it" 
