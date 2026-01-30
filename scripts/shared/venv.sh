#!/usr/bin/env bash

# Set venv path: /opt/venv in Docker, ./venv locally
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    export VENV_PATH="$VIRTUAL_ENV"
else
    export VENV_PATH="./venv"
fi
