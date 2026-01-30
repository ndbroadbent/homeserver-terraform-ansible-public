#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/../shared/common.sh"

# Function to validate raw Kubernetes resources with CRD schemas
validate_raw_resources() {
    log "$BLUE" "🔧 Validating raw Kubernetes resources..."
    
    # Find all raw YAML files in resources directories
    mapfile -t resource_files < <(find k3s/resources -name "*.yaml" -type f 2>/dev/null || true)
    
    if [[ ${#resource_files[@]} -eq 0 ]]; then
        log "$YELLOW" "⚠️  No raw resource files found in k3s/resources/"
        return 0
    fi
    
    log "$BLUE" "🎯 Found ${#resource_files[@]} raw resource file(s) to validate"
    
    # Build all resources using kustomize
    log "$BLUE" "🔨 Building resources with kustomize..."
    local temp_resources="/tmp/validate-raw-resources.yaml"
    rm -f "$temp_resources"
    
    # Build each subdirectory that has a kustomization.yaml
    for resource_dir in k3s/resources/*/; do
        if [[ -d "$resource_dir" ]]; then
            if [[ -f "$resource_dir/kustomization.yaml" ]]; then
                log "$BLUE" "   📁 Building $(basename "$resource_dir") with kustomize..."
                if ! kustomize build "$resource_dir" --enable-helm --load-restrictor=LoadRestrictionsNone >> "$temp_resources" 2>/tmp/kustomize-raw-errors.txt; then
                    log "$RED" "   ❌ Kustomize build failed for $(basename "$resource_dir"):"
                    sed < /tmp/kustomize-raw-errors.txt 's/^/      /'
                    rm -f "$temp_resources" /tmp/kustomize-raw-errors.txt
                    return 1
                fi
                # Add document separator after kustomize output
                echo "---" >> "$temp_resources"
            else
                log "$BLUE" "   📁 Processing $(basename "$resource_dir") raw files..."
                for yaml_file in "$resource_dir"*.yaml; do
                    if [[ -f "$yaml_file" ]]; then
                        # Ensure proper newline separation
                        {
                            cat "$yaml_file"
                            echo ""  # Add newline if missing
                            echo "---"
                        } >> "$temp_resources"
                    fi
                done
            fi
        fi
    done
    
    # Validate the combined resources with CRD schemas
    if [[ -s "$temp_resources" ]]; then
        log "$BLUE" "🔧 Schema validation with CRD schemas..."
        
        # Single-shot validation with all schemas
        if ! kubeconform -strict -summary \
            -ignore-missing-schemas \
            -kubernetes-version 1.28.5 \
            -schema-location "default" \
            -schema-location "file://$(pwd)/scripts/validate/crd-schemas/{{ .ResourceKind }}.json" \
            "$temp_resources" 2>/tmp/validate-raw-schema-errors.txt; then
            log "$RED" "❌ Schema validation failed:"
            sed < /tmp/validate-raw-schema-errors.txt 's/^/   /'
            rm -f "$temp_resources" /tmp/validate-raw-schema-errors.txt /tmp/kustomize-raw-errors.txt
            return 1
        fi
        
        log "$GREEN" "✅ Schema validation passed"
        
        # Policy validation with conftest (required)
        if ! command -v conftest >/dev/null 2>&1; then
            log "$RED" "❌ conftest is required but not installed. Failing fast."
            exit 1
        fi
        log "$BLUE" "📋 Policy validation with conftest..."
        if ! conftest test "$temp_resources" --policy "$(dirname "$0")/policy.rego" --output json > /tmp/validate-raw-policy.txt 2>&1; then
            log "$YELLOW" "⚠️  Policy issues found (non-blocking):"
            sed < /tmp/validate-raw-policy.txt 's/^/   /'
        else
            log "$GREEN" "✅ No policy issues found"
        fi
        
        log "$GREEN" "✅ Raw resources validation complete"
    fi
    
    # Cleanup
    rm -f "$temp_resources" /tmp/validate-raw-schema-errors.txt /tmp/kustomize-raw-errors.txt /tmp/validate-raw-policy.txt
    rm -rf "/tmp/policy"
    return 0
}

# Function to calculate cache key for an application
calculate_cache_key() {
    local app_file=$1
    local app_name
    app_name=$(basename "$(dirname "$app_file")")
    local app_dir
    app_dir=$(dirname "$app_file")
    local values_file
    values_file=$(yq '.values' "$app_file")
    
    # Collect all files that could affect validation
    local files_to_hash=("$app_file")
    
    # Add values file if it exists
    if [[ "$values_file" != "null" && -f "$app_dir/$values_file" ]]; then
        files_to_hash+=("$app_dir/$values_file")
    fi
    
    # Add global files that affect all apps
    if [[ -f "k3s/helm-apps-applicationset.yaml" ]]; then
        files_to_hash+=("k3s/helm-apps-applicationset.yaml")
    fi
    if [[ -f "helm-repos.yaml" ]]; then
        files_to_hash+=("helm-repos.yaml")
    fi
    if [[ -f "k3s/kustomization.yaml" ]]; then
        files_to_hash+=("k3s/kustomization.yaml")
    fi
    
    # Add exclusion files
    local exclusions_dir
    exclusions_dir="$(dirname "$0")/exclusions"
    if [[ -f "$exclusions_dir/default.txt" ]]; then
        files_to_hash+=("$exclusions_dir/default.txt")
    fi
    if [[ -f "$exclusions_dir/${app_name}.txt" ]]; then
        files_to_hash+=("$exclusions_dir/${app_name}.txt")
    fi
    
    # Calculate MD5 hash of all relevant files
    local cache_key
    cache_key=$(cat "${files_to_hash[@]}" 2>/dev/null | md5sum | cut -d' ' -f1)
    echo "$cache_key"
}

# Function to validate a single ArgoCD application
validate_app() {
    local app_file=$1
    local app_name
    app_name=$(basename "$(dirname "$app_file")")
    local chart_repo
    chart_repo=$(yq '.repoURL' "$app_file")
    local chart_name
    chart_name=$(yq '.chart' "$app_file")
    local chart_version
    chart_version=$(yq '.version' "$app_file")
    local values_file
    values_file=$(yq '.values' "$app_file")
    local app_dir
    app_dir=$(dirname "$app_file")
    
    # Check cache
    local cache_dir=".k3s-validation-cache"
    mkdir -p "$cache_dir"
    local cache_key
    cache_key=$(calculate_cache_key "$app_file")
    local cache_file="$cache_dir/${app_name}"
    
    if [[ -f "$cache_file" ]] && [[ "$(cat "$cache_file" 2>/dev/null)" == "$cache_key" ]]; then
        log "$GREEN" "🔍 $app_name (cached) ✅"
        return 0
    fi
    
    log "$BLUE" "🔍 Validating $app_name..."
    
    # Check if this is a full Application resource instead of simple metadata
    local kind
    kind=$(yq '.kind' "$app_file")
    if [[ "$kind" == "Application" ]]; then
        log "$RED" "❌ Invalid format in $app_file"
        log "$RED" "   Found full ArgoCD Application resource, but ApplicationSet expects simple metadata format"
        log "$RED" "   Expected format: name, repoURL, chart, version, namespace, values"
        return 1
    fi
    
    # Validate all required fields are present and correct types
    local missing_fields=()
    local namespace
    namespace=$(yq '.namespace' "$app_file")
    
    if [[ "$chart_repo" == "null" ]]; then
        missing_fields+=("repoURL")
    fi
    # For OCI repositories, chart field is optional (chart name is in repoURL)
    if [[ "$chart_name" == "null" && "$chart_repo" != oci://* ]]; then
        missing_fields+=("chart")
    fi
    if [[ "$chart_version" == "null" ]]; then
        missing_fields+=("version")
    fi
    if [[ "$namespace" == "null" ]]; then
        missing_fields+=("namespace")
    fi
    if [[ "$values_file" == "null" ]]; then
        missing_fields+=("values")
    fi
    
    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        log "$RED" "❌ Missing required fields in $app_file: ${missing_fields[*]}"
        log "$RED" "   Expected format: name, repoURL, chart, version, namespace, values"
        return 1
    fi
    
    # Validate field types (should be strings, not objects/arrays)
    if [[ $(yq 'type' "$app_file") != "!!map" ]]; then
        log "$RED" "❌ Invalid format in $app_file: root should be a YAML object"
        return 1
    fi
    
    # Read values from separate file
    local values_content=""
    if [[ "$values_file" != "null" && -f "$app_dir/$values_file" ]]; then
        values_content=$(cat "$app_dir/$values_file")
    fi
    
    if [[ "$chart_repo" == "null" || "$chart_name" == "null" ]]; then
        log "$YELLOW" "⚠️  Skipping $app_name (not a Helm chart)"
        return 0
    fi
    
    # Handle OCI vs traditional Helm repos
    local full_chart_name
    
    if [[ "$chart_repo" == oci://* ]] || [[ "$chart_repo" == "tccr.io/truecharts" ]]; then
        # OCI repository - use the repoURL directly, don't append chart name
        if [[ "$chart_repo" == "tccr.io/truecharts" ]]; then
            full_chart_name="oci://$chart_repo/$chart_name"
        else
            full_chart_name="$chart_repo"
        fi
        log "$BLUE" "   📊 OCI Chart: $chart_name@$chart_version from $chart_repo"
    else
        # Traditional Helm repository - map URL to repo name
        if [[ ! -f "helm-repos.yaml" ]]; then
            log "$RED" "❌ helm-repos.yaml not found. Run from project root."
            exit 1
        fi
        
        local repo_name
        repo_name=$(yq ".url_mappings[\"$chart_repo\"]" helm-repos.yaml 2>/dev/null || echo "null")
        if [[ "$repo_name" == "null" || -z "$repo_name" ]]; then
            log "$RED" "❌ Unknown repo URL: $chart_repo"
            log "$RED" "   Add mapping to helm-repos.yaml url_mappings section"
            exit 1
        fi
        
        full_chart_name="${repo_name}/${chart_name}"
        log "$BLUE" "   📊 Chart: $full_chart_name@$chart_version from $chart_repo"
    fi
    
    # Create temporary values file
    local temp_values="/tmp/validate-${app_name}-values.yaml"
    echo "$values_content" > "$temp_values"
    
    # Step 1: Helm lint with values (fetch chart first)
    log "$BLUE" "   📝 Step 1: Helm lint with values..."
    local temp_chart_dir="/tmp/validate-${app_name}-chart"
    rm -rf "$temp_chart_dir"
    
    if ! helm pull "$full_chart_name" \
        --version "$chart_version" \
        --untar \
        --untardir "$temp_chart_dir" > "/tmp/validate-${app_name}-pull.txt" 2>&1; then
        
        log "$RED" "   ❌ Helm pull failed:"
        sed < "/tmp/validate-${app_name}-pull.txt" 's/^/      /'
        rm -f "$temp_values" "/tmp/validate-${app_name}-pull.txt"
        return 1
    fi
    
    local chart_dir="$temp_chart_dir/$chart_name"
    if ! helm lint "$chart_dir" \
        --values "$temp_values" > "/tmp/validate-${app_name}-lint.txt" 2>&1; then
        
        log "$RED" "   ❌ Helm lint failed:"
        sed < "/tmp/validate-${app_name}-lint.txt" 's/^/      /'
        rm -rf "$temp_values" "$temp_chart_dir" "/tmp/validate-${app_name}-lint.txt"
        return 1
    fi
    
    # Step 2: Test Helm template rendering
    log "$BLUE" "   🎨 Step 2: Testing Helm rendering..."
    if ! helm template "$app_name" "$full_chart_name" \
        --version "$chart_version" \
        --values "$temp_values" \
        --dry-run > "/tmp/validate-${app_name}-rendered.yaml" 2>/tmp/validate-"${app_name}"-errors.txt; then
        
        log "$RED" "   ❌ Helm template rendering failed:"
        sed < "/tmp/validate-${app_name}-errors.txt" 's/^/      /'
        rm -rf "$temp_values" "$temp_chart_dir" "/tmp/validate-${app_name}-rendered.yaml" "/tmp/validate-${app_name}-errors.txt"
        return 1
    fi
    
    # Step 3: Schema validation with kubeconform
    log "$BLUE" "   🔧 Step 3: Schema validation..."
    
    if ! kubeconform -strict -summary \
        -ignore-missing-schemas \
        -kubernetes-version 1.28.5 \
        -schema-location "default" \
        -schema-location "file://$(pwd)/scripts/validate/crd-schemas/{{ .ResourceKind }}.json" \
        "/tmp/validate-${app_name}-rendered.yaml" 2>"/tmp/validate-${app_name}-schema-errors.txt"; then
        log "$RED" "   ❌ Schema validation failed:"
        sed < "/tmp/validate-${app_name}-schema-errors.txt" 's/^/      /'
        rm -rf "$temp_values" "$temp_chart_dir" "/tmp/validate-${app_name}-rendered.yaml" "/tmp/validate-${app_name}-errors.txt" "/tmp/validate-${app_name}-schema-errors.txt"
        return 1
    fi
    
    log "$GREEN" "   ✅ Schema validation passed"
    
    # Step 4: Policy linting with kube-linter (optional, non-blocking)
    log "$BLUE" "   📋 Step 4: Policy linting..."
    if command -v kube-linter >/dev/null 2>&1; then
        # Build exclusion list from default + app-specific exclusions
        local exclusions=""
        local exclusions_dir
        exclusions_dir="$(dirname "$0")/exclusions"
        
        # Load default exclusions
        if [[ -f "$exclusions_dir/default.txt" ]]; then
            local default_exclusions
            default_exclusions=$(grep -v '^#' "$exclusions_dir/default.txt" | grep -v '^$' | tr '\n' ',' | sed 's/,$//')
            exclusions="$default_exclusions"
        fi
        
        # Load app-specific exclusions
        if [[ -f "$exclusions_dir/${app_name}.txt" ]]; then
            local app_exclusions
            app_exclusions=$(grep -v '^#' "$exclusions_dir/${app_name}.txt" | grep -v '^$' | tr '\n' ',' | sed 's/,$//')
            if [[ -n "$app_exclusions" ]]; then
                if [[ -n "$exclusions" ]]; then
                    exclusions="$exclusions,$app_exclusions"
                else
                    exclusions="$app_exclusions"
                fi
            fi
        fi
        
        if ! kube-linter lint --exclude "$exclusions" "/tmp/validate-${app_name}-rendered.yaml" > "/tmp/validate-${app_name}-policy.txt" 2>&1; then
            log "$YELLOW" "   ⚠️  Policy issues found (non-blocking):"
            sed < "/tmp/validate-${app_name}-policy.txt" 's/^/      /'
        else
            log "$GREEN" "   ✅ No policy issues found"
        fi
    else
        log "$YELLOW" "   ⚠️  kube-linter not installed, skipping policy checks"
    fi
    
    # Cleanup
    rm -rf "$temp_values" "$temp_chart_dir" "/tmp/validate-${app_name}-rendered.yaml" "/tmp/validate-${app_name}-errors.txt" "/tmp/validate-${app_name}-schema-errors.txt" "/tmp/validate-${app_name}-policy.txt" "/tmp/validate-${app_name}-lint.txt" "/tmp/validate-${app_name}-pull.txt"
    
    # Cache successful validation
    echo "$cache_key" > "$cache_file"
    
    log "$GREEN" "   ✅ $app_name validation complete"
    return 0
}

# Main script
log "$BLUE" "🚀 Starting validation..."

# Check required tools
missing_tools=()
for tool in helm yq kubeconform kustomize; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing_tools+=("$tool")
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log "$RED" "❌ Missing required tools: ${missing_tools[*]}"
    log "$YELLOW" "Run ./scripts/setup/dev.sh to install them"
    exit 1
fi

# Update helm repos (cache for 1 hour)
"$(dirname "$0")/../helm_update.sh"

# Step 1: Validate raw Kubernetes resources first
if ! validate_raw_resources; then
    log "$RED" "❌ Raw resources validation failed"
    exit 1
fi

# Step 2: Validate kustomization build
log "$BLUE" "🔧 Validating kustomization build..."
if ! kustomize build k3s --enable-helm --load-restrictor=LoadRestrictionsNone > /tmp/kustomize-build.yaml 2>/tmp/kustomize-errors.txt; then
    log "$RED" "❌ Kustomization build failed:"
    sed < /tmp/kustomize-errors.txt 's/^/   /'
    rm -f /tmp/kustomize-build.yaml /tmp/kustomize-errors.txt
    exit 1
fi

log "$GREEN" "✅ Kustomization build successful"
rm -f /tmp/kustomize-build.yaml /tmp/kustomize-errors.txt

# Step 3: Find all ArgoCD application files in the new apps structure
mapfile -t app_files < <(find k3s/apps -name "application.yaml" -type f 2>/dev/null || true)

if [[ ${#app_files[@]} -eq 0 ]]; then
    log "$YELLOW" "⚠️  No ArgoCD application files found in k3s/apps/"
    log "$GREEN" "🎉 Raw resources validation passed!"
    exit 0
fi

log "$BLUE" "🎯 Found ${#app_files[@]} application(s) to validate"

# Validate each application
for app_file in "${app_files[@]}"; do
    if ! validate_app "$app_file"; then
        log "$RED" "❌ Validation failed for $(basename "$app_file" .yaml)"
        log "$RED" "🚨 Stopping validation on first failure"
        exit 1
    fi
    echo ""
done

# All validations passed
log "$GREEN" "📊 Validation Summary:"
log "$GREEN" "✅ Successfully validated all raw resources and ${#app_files[@]} applications"
log "$GREEN" "🎉 All validations passed!"
exit 0
