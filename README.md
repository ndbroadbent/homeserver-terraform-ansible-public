# Homelab Infrastructure as Code

A complete Infrastructure as Code (IaC) setup for a self-hosted homelab running on Proxmox VE, managed with Terraform and Ansible, with Kubernetes workloads orchestrated via ArgoCD.

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| **Hypervisor** | Proxmox VE, ZFS, LXC Containers |
| **Infrastructure** | Terraform (Proxmox, UniFi, Backblaze, Tailscale) |
| **Configuration** | Ansible (roles, playbooks, dynamic inventory) |
| **Kubernetes** | K3s, ArgoCD, Helm |
| **Networking** | Traefik, MetalLB, FreeRADIUS, AdGuard Home |
| **Secrets** | 1Password Connect, External Secrets Operator |
| **Observability** | Prometheus, Grafana, Loki, Tempo, Promtail |
| **Storage** | ZFS pools, MinIO (S3-compatible), NFS |
| **Backup** | Restic, Backblaze B2 |
| **Auth** | Authelia (SSO/2FA) |

## Architecture Overview

```
┌───────────────────────────────────────────────────────────┐
│                        Proxmox VE Host                    │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │   K3s LXC     │  │  CircleCI     │  │   Other       │  │
│  │   Container   │  │  Runner LXC   │  │   LXCs        │  │
│  │               │  │               │  │               │  │
│  │ ┌───────────┐ │  │  K3s cluster  │  │  OpenClaw     │  │
│  │ │  ArgoCD   │ │  │  for CI/CD    │  │  AI Assistant │  │
│  │ ├───────────┤ │  │  workloads    │  │               │  │
│  │ │  Traefik  │ │  └───────────────┘  └───────────────┘  │
│  │ ├───────────┤ │                                        │
│  │ │  Apps     │ │  ┌─────────────────────────────────┐   │
│  │ │  - HA     │ │  │         ZFS Storage             │   │
│  │ │  - Frigate│ │  │  rpool (SSDs) │ tank (HDDs)     │   │
│  │ │  - etc    │ │  │  - OS/Config  │ - Media         │   │
│  │ └───────────┘ │  │  - K3s data   │ - Backups       │   │
│  └───────────────┘  └─────────────────────────────────┘   │
└───────────────────────────────────────────────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐      ┌──────────────────────────┐
│   UniFi UDM     │      │  Raspberry Pi            │
│   Router        │      │  - AdGuard DNS (Backup)  │
│   - VLANs       │      │  - Zigbee2MQTT           │
│   - Firewall    │      └──────────────────────────┘
└─────────────────┘
```

## Features

### GitOps Everything
- **Zero manual configuration** - all infrastructure defined in code
- **ArgoCD ApplicationSets** - automatic app discovery and deployment
- **Helm charts** - standardized application packaging

### Network Segmentation
- **VLAN isolation** - separate networks for cameras, IoT devices, guests
- **FreeRADIUS** - dynamic VLAN assignment based on MAC address
- **Firewall rules** - managed via Terraform

### Observability Stack
- **Metrics**: Prometheus with Thanos for long-term storage
- **Logs**: Loki with Promtail agents on all hosts
- **Traces**: Tempo for distributed tracing
- **Dashboards**: Grafana with pre-configured dashboards

### Security
- **1Password integration** - secrets never stored in git
- **External Secrets Operator** - Kubernetes secrets from 1Password
- **Authelia** - SSO with 2FA for services without built-in auth
- **Cert-Manager** - automatic TLS certificate management

### Smart Home
- **Home Assistant** - home automation hub
- **Frigate** - NVR with AI object detection
- **Zigbee2MQTT** - Zigbee device integration
- **MQTT** - message broker for IoT devices

### AI Assistant
- **[OpenClaw](https://github.com/openclaw/openclaw)** - personal AI assistant with Telegram integration, tool use, and extensible skills system

### Backup Strategy
- **Restic** - encrypted, deduplicated backups
- **Backblaze B2** - offsite cloud storage
- **Automated rsync** - centralized backup collection

## Directory Structure

```
.
├── ansible/                 # Ansible configuration
│   ├── inventory.py         # Dynamic inventory from network.yaml
│   ├── playbooks/           # Playbooks for each service
│   ├── roles/               # Reusable Ansible roles
│   └── secrets.yml          # 1Password secret references
├── config/
│   └── network.yaml         # Single source of truth for network config
├── k3s/
│   ├── apps/                # Helm app definitions (ArgoCD managed)
│   └── resources/           # Raw K8s manifests (Traefik routes, etc.)
├── terraform/
│   ├── proxmox/             # LXC containers and VMs
│   ├── unifi/               # Network, WLAN, firewall rules
│   ├── backblaze/           # B2 bucket configuration
│   └── tailscale/           # Tailscale ACLs and resources
└── scripts/
    ├── ansible/             # Wrapper scripts for playbooks
    ├── setup/               # Development environment setup
    └── validate/            # CI validation scripts
```

## Getting Started

### Prerequisites

- [1Password CLI](https://1password.com/downloads/command-line/) (`op`)
- [Terraform](https://terraform.io/) >= 1.0
- [Ansible](https://ansible.com/) >= 2.15
- [Helm](https://helm.sh/) >= 3.0
- Python 3.10+

### Quick Start

1. **Clone and setup:**
   ```bash
   git clone https://github.com/youruser/homeserver-terraform-ansible.git
   cd homeserver-terraform-ansible
   ./scripts/setup/dev.sh
   ```

2. **Configure your network:**
   ```bash
   # Edit config/network.yaml with your IPs and devices
   vim config/network.yaml
   ```

3. **Set up 1Password:**
   ```bash
   # Sign in to 1Password CLI
   eval $(op signin)

   # Create required secrets in your vault
   # See ansible/secrets.yml for the expected structure
   ```

4. **Deploy infrastructure:**
   ```bash
   # Create Proxmox containers
   cd terraform/proxmox && ./run_terraform.sh proxmox apply

   # Configure the K3s cluster
   ./scripts/ansible/k3s_lxc.sh

   # Deploy ArgoCD apps
   ./scripts/deploy_argocd.sh "Initial deployment"
   ```

## Tool Philosophy

| Tool | Purpose |
|------|---------|
| **Terraform** | Infrastructure creation (VMs, containers, network resources) |
| **Ansible** | Configuration management (software installation, settings) |
| **ArgoCD** | Kubernetes application deployment (GitOps) |
| **Helm** | Kubernetes application packaging |

Think of Proxmox as your own mini-AWS:
- Terraform spins up LXC containers (like EC2 instances)
- Ansible configures what runs inside them
- ArgoCD manages Kubernetes workloads

## Validation

All changes are validated before deployment:

```bash
# Run all validations
./scripts/validate/all.sh

# Or individually:
./scripts/validate/k3s.sh        # Helm lint, kubeconform, kube-linter
./scripts/validate/terraform.sh  # terraform fmt, validate, tflint
./scripts/validate/ansible.sh    # ansible-lint
```

## Contributing

This is a personal homelab setup, but feel free to fork and adapt for your own use. The architecture patterns and tooling choices should be broadly applicable.

## License

MIT License - feel free to use this as a starting point for your own homelab.
