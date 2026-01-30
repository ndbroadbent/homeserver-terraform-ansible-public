#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/shared/common.sh"

# Get k3s IP from canonical network config
K3S_IP=$(yq '.networks.main.hosts.k3s' config/network.yaml)

# Function to sync ArgoCD root application and then all labeled apps
sync_argocd() {
    echo "🔄 Step 1: Syncing ArgoCD ApplicationSets..."
    # Sync root ApplicationSets first
    ssh root@"$K3S_IP" "argocd app sync root --async"
    
    echo "🔄 Step 2: Syncing all generated applications..."
    # Now sync all the applications created by the ApplicationSets
    ssh root@"$K3S_IP" "argocd app sync -l app.kubernetes.io/instance=root \
        --apply-out-of-sync-only --async"
}

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    log "$RED" "❌ Error: No arguments provided"
    log "$BLUE" "Usage: $0 <commit_message> [--skip-validation] OR $0 --sync"
    log "$BLUE" ""
    log "$BLUE" "Examples:"
    log "$BLUE" "  $0 'Update database configuration'"
    log "$BLUE" "  $0 'Update database configuration' --skip-validation"
    log "$BLUE" "  $0 --sync"
    log "$BLUE" ""
    log "$BLUE" "Options:"
    log "$BLUE" "  --skip-validation    Skip Helm chart validation"
    exit 1
fi

# Parse arguments
SKIP_VALIDATION=false
COMMIT_MSG=""
IS_SYNC=false

# Parse all arguments to handle flags in any order
for arg in "$@"; do
    case "$arg" in
        "--sync")
            IS_SYNC=true
            ;;
        "--skip-validation")
            SKIP_VALIDATION=true
            ;;
        *)
            if [ -z "$COMMIT_MSG" ]; then
                COMMIT_MSG="$arg"
            else
                COMMIT_MSG="$COMMIT_MSG $arg"
            fi
            ;;
    esac
done

# Check if --sync flag is provided
if [ "$IS_SYNC" = true ]; then
    log "$BLUE" "🔄 Syncing current git revision..."
    sync_argocd
    log "$GREEN" "✅ Sync complete!"
    exit 0
fi

# Remove --skip-validation from commit message if it was added
COMMIT_MSG=$(echo "$COMMIT_MSG" | sed 's/ --skip-validation$//' | sed 's/^--skip-validation //')

if [ "$SKIP_VALIDATION" = false ]; then
    log "$BLUE" "🎨 Formatting files..."
    ./scripts/validate/format.sh
    log "$BLUE" "🔍 Validating Helm charts..."
    ./scripts/validate/k3s.sh
else
    log "$BLUE" "⏭️ Skipping format and validation..."
fi

log "$BLUE" "🔄 Adding all changes..."
git add -A

log "$BLUE" "📝 Creating commit: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

log "$BLUE" "⬆️ Pushing to remote..."
git push

sync_argocd

log "$GREEN" "✅ Deploy complete!"
