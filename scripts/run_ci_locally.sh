#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/shared/common.sh"

# Check if act is installed
if ! command -v act >/dev/null 2>&1; then
    log "$RED" "❌ act is not installed"
    log "$YELLOW" "Install with:"
    if [[ "$(uname)" == "Darwin" ]]; then
        log "$YELLOW" "  brew install act"
    else
        log "$YELLOW" "  curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
    fi
    exit 1
fi

# Parse command line arguments
WORKFLOW=""
JOB=""
DRY_RUN=false
VERBOSE=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--workflow)
            WORKFLOW="$2"
            shift 2
            ;;
        -j|--job)
            JOB="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -w, --workflow FILE    Run specific workflow file"
            echo "  -j, --job JOB_NAME     Run specific job"
            echo "  --dry-run              Show what would run without executing"
            echo "  -v, --verbose          Verbose output"
            echo "  -l, --list             List available workflows and jobs"
            echo "  -h, --help             Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                              # Run all workflows"
            echo "  $0 -w validate.yml              # Run validate workflow"
            echo "  $0 -j validate-and-format       # Run specific job"
            echo "  $0 --dry-run                    # Dry run all workflows"
            echo "  $0 -l                           # List workflows"
            exit 0
            ;;
        *)
            log "$RED" "❌ Unknown option: $1"
            log "$YELLOW" "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Change to project root
cd "$(dirname "$0")/.."

log "$BLUE" "🎬 Running GitHub Actions locally with act..."

# Build act command
ACT_CMD="act"

# Use faster Ubuntu image
ACT_CMD="$ACT_CMD -P ubuntu-latest=catthehacker/ubuntu:act-latest"

# Add workflow if specified
if [[ -n "$WORKFLOW" ]]; then
    ACT_CMD="$ACT_CMD -W .github/workflows/$WORKFLOW"
fi

# Add job if specified
if [[ -n "$JOB" ]]; then
    ACT_CMD="$ACT_CMD -j $JOB"
fi

# Add flags
if [[ "$DRY_RUN" == "true" ]]; then
    ACT_CMD="$ACT_CMD --dryrun"
fi

if [[ "$VERBOSE" == "true" ]]; then
    ACT_CMD="$ACT_CMD -v"
fi

if [[ "$LIST_ONLY" == "true" ]]; then
    ACT_CMD="$ACT_CMD -l"
fi

# Show command being executed
log "$BLUE" "🔧 Executing: $ACT_CMD"
echo ""

# Run act
if eval "$ACT_CMD"; then
    log "$GREEN" "✅ GitHub Actions completed successfully!"
else
    log "$RED" "❌ GitHub Actions failed"
    exit 1
fi
