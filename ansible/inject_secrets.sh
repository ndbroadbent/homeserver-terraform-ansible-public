#!/usr/bin/env bash
# Script to inject secrets from 1Password and output processed YAML

set -e

# Check if 1Password CLI is installed
if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI (op) is not installed."
    echo "Install it with: brew install 1password-cli"
    exit 1
fi

# Check if user is signed in to 1Password
if ! op account list &> /dev/null; then
    echo "Error: Not signed in to 1Password."
    echo "Sign in with: op signin"
    exit 1
fi

# Get the directory where this script is located and cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Inject secrets and process with awk
op inject -i secrets.yml | awk -f indent_yaml.awk
