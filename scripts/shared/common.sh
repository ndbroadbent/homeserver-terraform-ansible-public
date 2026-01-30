#!/usr/bin/env bash
# Common shared utilities - sources both logging and utils

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared utilities
# shellcheck disable=SC1091
source "$SCRIPT_DIR/logging.sh"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/utils.sh" 

# shellcheck disable=SC1091
source "$SCRIPT_DIR/venv.sh" 
