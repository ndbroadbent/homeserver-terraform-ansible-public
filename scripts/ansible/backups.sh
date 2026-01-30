#!/bin/bash
# Deploy restic backups to all important hosts
set -e
cd "$(dirname "$0")/../.." && ./ansible/run_playbook.sh playbooks/backups.yml "$@"
