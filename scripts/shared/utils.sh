#!/usr/bin/env bash
# Shared utility functions for all scripts

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if we're running in a Docker container
is_docker() {
    [[ -f /.dockerenv ]] || [[ -f /proc/1/cgroup ]] && grep -q docker /proc/1/cgroup
}

# Function to get the script directory
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Function to get the project root directory
get_project_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

# Function to check if script is run from project root
check_project_root() {
    if [[ ! -f "ansible/ansible.cfg" ]]; then
        log "$RED" "❌ This script must be run from the project root directory"
        exit 1
    fi
}

# Function to get Terraform variables
get_terraform_vars() {
    local vars=("$@")
    local extra_vars=""
    
    # Save current directory
    local current_dir
    current_dir=$(pwd)
    
    # Change to terraform/proxmox directory
    cd terraform/proxmox || {
        log "$RED" "❌ Failed to change to terraform/proxmox directory"
        exit 1
    }
    
    # Get each variable
    for var in "${vars[@]}"; do
        local value
        value=$(echo "var.$var" | terraform console 2>/dev/null | tr -d '"')
        if [[ -z "$value" ]]; then
            log "$RED" "❌ Failed to get Terraform variable: $var"
            cd "$current_dir" || return 1
            exit 1
        fi
        extra_vars="$extra_vars $var=$value"
    done
    
    # Return to original directory
    cd "$current_dir" || return 1
    
    # Return the extra vars string
    echo "$extra_vars"
}

# Function to run an Ansible playbook with standard logging
run_ansible_playbook() {
    local playbook_path="$1"
    local description="$2"
    shift 2
    local extra_args=("$@")
    
    # Extract playbook name from path for display
    local playbook_name
    playbook_name=$(basename "$playbook_path" .yml)
    
    log "$BLUE" "📋 Running $playbook_name playbook..."
    log "$YELLOW" "🔐 This will inject secrets from 1Password${description:+ and $description}"
    
    # Change to ansible directory
    cd ansible || {
        log "$RED" "❌ Failed to change to ansible directory"
        exit 1
    }
    
    # Run the playbook
    if ! ./run_playbook.sh "playbooks/${playbook_path}.yml" "${extra_args[@]}"; then
        log "$RED" "❌ ${playbook_name} playbook failed"
        exit 1
    fi
    
    # Return to original directory
    cd - > /dev/null || return 1
}

# Function to display success message with optional IP
show_success() {
    local service_name="$1"
    local ip_key="${2:-}"
    
    log "$GREEN" "✅ $service_name completed successfully!"
    
    if [[ -n "$ip_key" ]]; then
        local ip
        ip=$(yq ".networks.main.hosts.$ip_key" config/network.yaml)
        log "$BLUE" "💡 You can now access the service at: $ip"
    fi
} 
