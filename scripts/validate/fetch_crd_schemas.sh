#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Get k3s version from Ansible playbook
get_k3s_version() {
    local k3s_version
    k3s_version=$(yq '.[0].vars.k3s_version' ansible/playbooks/k3s_lxc.yml 2>/dev/null || echo "")
    if [[ -z "$k3s_version" ]]; then
        log "$RED" "❌ Could not determine k3s version from ansible/playbooks/k3s_lxc.yml"
        exit 1
    fi
    # Extract kubernetes version from k3s version (e.g., v1.28.5+k3s1 -> 1.28.5)
    k3s_version="${k3s_version//v/}"
    k3s_version="${k3s_version%%-*}"
    k3s_version="${k3s_version%%.*}.${k3s_version#*.}"  # This will keep the major.minor.patch
    echo "$k3s_version"
}

# Validate JSON file was downloaded successfully
validate_json_download() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]] || [[ ! -s "$file" ]]; then
        log "$RED" "❌ Failed to download $description: file is missing or empty"
        exit 1
    fi
    
    # Check if it's valid JSON and not an error message
    if ! jq empty "$file" 2>/dev/null; then
        log "$RED" "❌ Failed to download $description: invalid JSON content"
        log "$RED" "   Content: $(head -1 "$file")"
        exit 1
    fi
    # Fail if the file is just 'null', an empty object, or an empty array
    local content
    content=$(jq -c . "$file")
    if [[ "$content" == "null" || "$content" == "{}" || "$content" == "[]" ]]; then
        log "$RED" "❌ Failed to download $description: content is $content (likely missing schema)"
        exit 1
    fi
    log "$GREEN" "   ✅ Downloaded $description"
}

# Main script
log "$BLUE" "📥 Fetching CRD schemas..."

# Check required tools
if ! command -v yq >/dev/null 2>&1; then
    log "$RED" "❌ yq is required but not installed"
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    log "$RED" "❌ curl is required but not installed"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    log "$RED" "❌ jq is required but not installed"
    exit 1
fi

# Get kubernetes version
kubernetes_version=$(get_k3s_version)
log "$BLUE" "🎯 Targeting Kubernetes version: $kubernetes_version"

# Remove and recreate schema directory
schema_dir="$(dirname "$0")/crd-schemas"
rm -rf "$schema_dir"
mkdir -p "$schema_dir"

log "$BLUE" "📋 Fetching cert-manager CRDs..."

CERT_MANAGER_VERSION="v1.16.2"
CERT_MANAGER_CRDS=(
  certificaterequests:certificaterequest
  certificates:certificate
  challenges:challenge
  clusterissuers:clusterissuer
  issuers:issuer
  orders:order
)
for crd_pair in "${CERT_MANAGER_CRDS[@]}"; do
  crd_name="${crd_pair%%:*}"
  kind_name="${crd_pair##*:}"
  crd_url="https://raw.githubusercontent.com/jetstack/cert-manager/${CERT_MANAGER_VERSION}/deploy/crds/crd-${crd_name}.yaml"
  out_file="$schema_dir/${kind_name}.json"
  curl -sSL "$crd_url" \
    | yq -o=json '.spec.versions[0].schema.openAPIV3Schema' > "$out_file"
  validate_json_download "$out_file" "${kind_name^} schema"
done

log "$BLUE" "📋 Fetching external-secrets CRDs..."

# Fetch external-secrets CRDs from bundle.yaml
BUNDLE_URL="https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml"

curl -sSL "$BUNDLE_URL" \
  | yq -o=json ". as \$doc | (select(.kind == \"CustomResourceDefinition\" and .metadata.name == \"externalsecrets.external-secrets.io\") | .spec.versions[] | select(.name == \"v1beta1\") | .schema.openAPIV3Schema)" > "$schema_dir/externalsecret.json"
validate_json_download "$schema_dir/externalsecret.json" "ExternalSecret schema"

curl -sSL "$BUNDLE_URL" \
  | yq -o=json ". as \$doc | (select(.kind == \"CustomResourceDefinition\" and .metadata.name == \"clustersecretstores.external-secrets.io\") | .spec.versions[] | select(.name == \"v1beta1\") | .schema.openAPIV3Schema)" > "$schema_dir/clustersecretstore.json"
validate_json_download "$schema_dir/clustersecretstore.json" "ClusterSecretStore schema"

log "$BLUE" "📋 Fetching Traefik CRDs..."

# Fetch Traefik CRDs
curl -sSL \
    "https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressroutes.yaml" \
    | yq -o=json '.spec.versions[0].schema.openAPIV3Schema' > "$schema_dir/ingressroute.json"
validate_json_download "$schema_dir/ingressroute.json" "IngressRoute schema"

curl -sSL \
    "https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/traefik.containo.us_middlewares.yaml" \
    | yq -o=json '.spec.versions[0].schema.openAPIV3Schema' > "$schema_dir/middleware.json"
validate_json_download "$schema_dir/middleware.json" "Middleware schema"

curl -sSL \
    "https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/traefik.containo.us_tlsoptions.yaml" \
    | yq -o=json '.spec.versions[0].schema.openAPIV3Schema' > "$schema_dir/tlsoption.json"
validate_json_download "$schema_dir/tlsoption.json" "TLSOption schema"

log "$GREEN" "✅ All CRD schemas fetched successfully to $schema_dir/"
log "$GREEN" "📊 Downloaded 7 schema files" 
