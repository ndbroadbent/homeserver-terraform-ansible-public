#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Set environment variables for non-interactive operation
export DEBIAN_FRONTEND=noninteractive
export TZ=UTC
export TERM=xterm

log "$BLUE" "🔍 Checking if all required tools are already installed..."
if ./scripts/setup/verify.sh >/dev/null 2>&1; then
    log "$GREEN" "✅ All required tools are already installed!"
    exit 0
fi

log "$BLUE" "🔧 Some required tools are missing. Setting up system packages and tools..."

# Detect OS and package manager
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Convert arch to standard naming
case $ARCH in
    x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

log "$BLUE" "📋 Detected: $OS/$ARCH"

log "$BLUE" "📦 Installing system packages and tools..."

# Try package manager first
if command -v brew >/dev/null 2>&1; then
    log "$BLUE" "🍺 Installing via Homebrew..."
    # Install Homebrew packages
    BREW_PACKAGES=(
        helm
        kubeconform
        yq
        kube-linter
        actionlint
        act
        ansible
        kustomize
        terraform
        tflint
        shellcheck
        jq
        conftest
    )

    NEEDED_PACKAGES=()
    for pkg in "${BREW_PACKAGES[@]}"; do
        if ! brew list "$pkg" >/dev/null 2>&1; then
            NEEDED_PACKAGES+=("$pkg")
        fi
    done
    if [[ ${#NEEDED_PACKAGES[@]} -gt 0 ]]; then
        log "$BLUE" "📦 Installing Homebrew packages: ${NEEDED_PACKAGES[*]}"
        brew install "${NEEDED_PACKAGES[@]}"
    else
        log "$GREEN" "✅ All Homebrew packages are already installed"
    fi
    
    log "$GREEN" "✅ Package manager installation completed successfully"
elif command -v apt-get >/dev/null 2>&1; then
    log "$BLUE" "🍺 Installing via apt-get..."
    sudo apt-get update
    sudo apt-get install -y \
        jq \
        ansible \
        shellcheck \
        python3-pip \
        curl \
        unzip

    # --- Always install yq (Mike Farah's YAML tool) ---
    if ! command -v yq >/dev/null 2>&1; then
        echo "Installing yq..."
        YQ_VERSION="v4.45.4"
        wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
        chmod +x /usr/local/bin/yq
    else
        echo "yq already installed."
    fi

    # --- Always install tflint ---
    if ! command -v tflint >/dev/null 2>&1; then
        echo "Installing tflint..."
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    else
        echo "tflint already installed."
    fi

    # --- Always install terraform ---
    if ! command -v terraform >/dev/null 2>&1; then
        echo "Installing terraform..."
        TERRAFORM_VERSION="1.8.4"
        wget -qO /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        unzip -o /tmp/terraform.zip -d /tmp/
        sudo mv /tmp/terraform /usr/local/bin/
        rm /tmp/terraform.zip
    else
        echo "terraform already installed."
    fi

    # Install helm
    if ! command -v helm >/dev/null 2>&1; then
        echo "Installing helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    else
        echo "helm already installed."
    fi

    # Install kubeconform
    if ! command -v kubeconform >/dev/null 2>&1; then
        echo "Installing kubeconform..."
        curl -L https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz | tar xz -C /tmp
        sudo mv /tmp/kubeconform /usr/local/bin/
    else
        echo "kubeconform already installed."
    fi

    # Install conftest
    if ! command -v conftest >/dev/null 2>&1; then
        echo "Installing conftest..."
        ARCH=$(dpkg --print-architecture)     # amd64, arm64 …
        LATEST=$(curl -s https://api.github.com/repos/open-policy-agent/conftest/releases/latest \
                 | grep '"tag_name":' | cut -d '"' -f4 | sed 's/^v//')
        DEB="conftest_${LATEST}_linux_${ARCH}.deb"
        URL="https://github.com/open-policy-agent/conftest/releases/download/v${LATEST}/${DEB}"
        curl -L "$URL" -o "/tmp/$DEB"
        sudo apt install -y "/tmp/$DEB"
    else
        echo "conftest already installed."
    fi

    # Install kustomize
    if ! command -v kustomize >/dev/null 2>&1; then
        echo "Installing kustomize..."
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
        sudo mv kustomize /usr/local/bin/
    else
        echo "kustomize already installed."
    fi

    # Install kube-linter
    if ! command -v kube-linter >/dev/null 2>&1; then
        echo "Installing kube-linter..."
        curl -L https://github.com/stackrox/kube-linter/releases/latest/download/kube-linter-linux.tar.gz | tar xz -C /tmp
        sudo mv /tmp/kube-linter /usr/local/bin/
    else
        echo "kube-linter already installed."
    fi

    # Install actionlint
    if ! command -v actionlint >/dev/null 2>&1; then
        echo "Installing actionlint…"
        ARCH=$(dpkg --print-architecture)
        LATEST=$(curl -s https://api.github.com/repos/rhysd/actionlint/releases/latest \
                  | grep '"tag_name":' | cut -d'"' -f4 | sed 's/^v//')
        TARBALL="actionlint_${LATEST}_linux_${ARCH}.tar.gz"
        URL="https://github.com/rhysd/actionlint/releases/download/v${LATEST}/${TARBALL}"
        curl -L "$URL" -o "/tmp/$TARBALL"
        tar -xzf "/tmp/$TARBALL" -C /tmp actionlint
        sudo mv /tmp/actionlint /usr/local/bin/
    else
        echo "actionlint already installed."
    fi

    # Install act
    if ! command -v act >/dev/null 2>&1; then
        echo "Installing act..."
        curl -L https://github.com/nektos/act/releases/latest/download/act_Linux_x86_64.tar.gz | tar xz -C /tmp
        sudo mv /tmp/act /usr/local/bin/
    else
        echo "act already installed."
    fi

    log "$GREEN" "✅ Package manager installation completed successfully"
else
    log "$RED" "❌ Package manager installation failed or not available"
    log "$RED" "❌ Please install required tools manually:"
    log "$RED" "   - helm, yq, kubeconform, kube-linter, actionlint, ansible, ansible-lint, kustomize"
    if [[ "$OS" == "darwin" ]]; then
        log "$RED" "   - act (for local CI testing)"
    fi
    exit 1
fi

log "$GREEN" "✅ System packages and tools installation complete!"
