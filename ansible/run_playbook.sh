#!/usr/bin/env bash
# Script to run Ansible playbooks with 1Password secret injection

set -e

# Get the directory where this script is located and cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activate root venv if present (go up one directory to find it)
if [ -d "../venv" ]; then
    # shellcheck disable=SC1091
    source ../venv/bin/activate
fi

# Inject secrets and run the playbook
echo "Injecting secrets from 1Password and running playbook..."
./inject_secrets.sh | ansible-playbook "$@" --extra-vars "@/dev/stdin"
