# Ansible Configuration

This directory contains Ansible playbooks and configuration for managing the
home server infrastructure.

## Directory Structure

```
ansible/
├── hosts.yml                    # Inventory file
├── ansible.cfg                  # Ansible configuration
├── host-server/                 # Proxmox host server configuration
│   ├── playbooks/
│   │   └── host.yml             # Main host configuration playbook
│   ├── roles/                   # Custom roles
│   ├── group_vars/              # Group variables
│   └── host_vars/               # Host-specific variables
└── vms/                         # VM/Container configurations (future)
```

## Usage

### Configure Proxmox Host Server

```bash
cd ansible
ansible-playbook host-server/playbooks/host.yml
```

### Test Connection

```bash
ansible homeserver -m ping
```

## Current Configuration

The host server playbook configures:

- Screen saver disable on startup
- Proper file ownership and permissions
