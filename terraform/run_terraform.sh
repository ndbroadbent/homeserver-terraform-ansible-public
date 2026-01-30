#!/usr/bin/env bash
set -euo pipefail

# Default to unifi if no module specified
MODULE="${1:-unifi}"

# Validate module exists
if [[ ! -d "$(dirname "$0")/$MODULE" ]]; then
    echo "Error: Module '$MODULE' not found"
    echo "Available modules:"
    for dir in "$(dirname "$0")"/*; do
        if [[ -d "$dir" && "$(basename "$dir")" != "run_terraform.sh" ]]; then
            basename "$dir"
        fi
    done
    exit 1
fi

# Shift arguments to remove module name
if [[ $# -gt 0 ]]; then
    shift
fi

# Change to the specified module directory
cd "$(dirname "$0")/$MODULE"

# Set Ansible environment variables for Terraform
SCRIPT_DIR="$(dirname "$0")"
ANSIBLE_CONFIG="$SCRIPT_DIR/../ansible/ansible.cfg"
PATH="$SCRIPT_DIR/../venv/bin:$PATH"
export ANSIBLE_CONFIG
export PATH

# Use direnv to load environment variables and run terraform
direnv exec . terraform "$@"
