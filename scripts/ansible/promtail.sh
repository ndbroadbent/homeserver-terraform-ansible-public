#!/bin/bash
# Deploy Promtail to all infrastructure hosts
set -e
cd "$(dirname "$0")/../.." && ./ansible/run_playbook.sh playbooks/promtail.yml "$@"
