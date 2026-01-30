#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Set environment variables for non-interactive operation
export DEBIAN_FRONTEND=noninteractive
export TZ=UTC
export TERM=xterm

echo "📦 Installing Node.js dependencies..."

# Install Node.js dependencies (fail fast, no warnings)
npm install --silent --no-fund --no-audit

echo "✅ Node.js dependencies installation complete!"
