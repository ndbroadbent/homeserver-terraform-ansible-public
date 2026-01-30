# Homeserver Infrastructure Management Instructions

## IMPORTANT: Infrastructure as Code Philosophy

**EVERYTHING is managed in this repository via code:**

- **Terraform**: Network configuration (UniFi), Proxmox VMs/containers
- **Ansible**: Host configuration, container setup
- **ArgoCD**: Kubernetes applications via applicationsets (ONLY for main K3s
  cluster at 10.11.12.11)
- **NO manual commands** on servers
- **NO manually created applications** - everything is defined in code
- **NO backwards compatibility** - we fix things properly, not with workarounds

**CRITICAL REMINDERS:**

- **NEVER run SSH commands to fix things** - Always update Ansible/Terraform
  instead
- **NEVER delete files/directories without listing contents first** - Use
  `ls -laR` before any `rm`
- **NEVER commit without testing locally first** - Build/test before pushing
- **Slow down and be thorough** - Check all related files, read project docs
  first

## Bash Guidelines

**IMPORTANT: Avoid commands that cause output buffering issues:**

- DO NOT pipe output through `head`, `tail`, `less`, or `more` when monitoring
  or checking command output
- DO NOT use `| head -n X` or `| tail -n X` to truncate output - these cause
  buffering problems
- Instead, let commands complete fully, or use `--max-lines` flags if the
  command supports them
- For log monitoring, prefer reading files directly rather than piping through
  filters

**When checking command output:**

- Run commands directly without pipes when possible
- If you need to limit output, use command-specific flags (e.g., `git log -n 10`
  instead of `git log | head -10`)
- Avoid chained pipes that can cause output to buffer indefinitely

## Related Source Code

- **OpenClaw**: `../openclaw` - Personal AI assistant source code

### OpenClaw Development Guidelines

When modifying openclaw source code at `../openclaw`:

1. **Read `../openclaw/CLAUDE.md` first** - Contains project-specific guidelines
2. **Use pnpm, not npm** - Install deps with `pnpm install`, build with
   `pnpm build`
3. **Test before committing** - Run `pnpm lint && pnpm build && pnpm test`
4. **Use the committer script** - `scripts/committer "<msg>" <file...>` instead
   of manual git add/commit
5. **TypeScript types have TWO locations**:
   - Type definitions in `src/config/types.*.ts`
   - Zod validation schemas in `src/config/zod-schema.ts`
   - **BOTH must be updated** when adding new config options
6. **Install node_modules locally** - Required to run tests before committing

## Service Location Map

### Proxmox Infrastructure

**Proxmox Host (10.11.12.10)**: Main hypervisor running containers and VMs

**Containers (LXC):**

- **CT 100** (stopped): homeassistant
- **CT 101** (stopped): adguard
- **CT 103** (stopped): frigate
- **CT 104** (10.11.12.104): nginxproxymanager - Reverse proxy
- **CT 111**: homepage - Dashboard
- **CT 112** (10.11.12.140): webapp - Web App on port 2368 (proxied via
  nginx on port 80)
- **CT 117** (10.11.12.35): openclaw - Personal AI assistant on port 18789
- **CT 121** (10.11.12.30): circleci-runner - CircleCI self-hosted runners
- **CT 200** (10.11.12.11): k3s-cluster - Main Kubernetes cluster

**Virtual Machines (KVM):**

- _(none currently running - Home Assistant migrated to K3s)_

**External Services (not in Proxmox):**

- **Raspberry Pi** (10.11.12.22): AdGuard Home (port 80) and Zigbee2MQTT
  (port 8080)
- **UniFi UDM** (10.11.12.1): Network controller on port 443

## Container Details and Log Locations

| Container          | IP         | Service      | Log Location                                                        | Notes                                |
| ------------------ | ---------- | ------------ | ------------------------------------------------------------------- | ------------------------------------ |
| CT 104 npm         | 10.11.12.104 | NPM          | `/data/logs/`                                                       | Nginx Proxy Manager                  |
| CT 112 webapp      | 10.11.12.140 | Web App      | `/var/log/webapp/`, `/var/log/nginx`                                | Web app on port 2368, nginx proxy on 80 |
| CT 121 circleci    | 10.11.12.30  | CircleCI K3s | `journalctl -u k3s`                                                 | Self-hosted runners cluster          |
| CT 200 k3s-cluster | 10.11.12.11  | Main K3s     | `kubectl logs` or Loki                                              | ArgoCD-managed services              |
| Raspberry Pi       | 10.11.12.22  | AdGuard/Z2M  | `/opt/AdGuardHome/data/querylog.json`, `/opt/zigbee2mqtt/data/log/` | Backup DNS + Zigbee                  |

**Quick log access examples:**

```bash
# Web App logs
ssh root@10.11.12.140 "tail -100 /var/log/webapp/webapp.log"

# K3s pod logs (from k3s-cluster container)
ssh root@10.11.12.11 "kubectl logs -n <namespace> <pod-name>"
```

## K3s Clusters

**IMPORTANT: There are TWO separate K3s clusters:**

1. **Main K3s Cluster (10.11.12.11)**: Runs home services, managed by ArgoCD
   - Uses the `k3s/` directory structure below
   - Deployed via ArgoCD ApplicationSets
   - Hosts: AdGuard Home, Traefik, External Secrets, etc.

2. **CircleCI K3s Cluster (10.11.12.30)**: Runs CircleCI self-hosted runners
   - NOT managed by ArgoCD
   - Configured directly via Ansible
   - Dedicated to CI/CD workloads

### Services in Main K3s Cluster (10.11.12.11)

**Core Infrastructure:**

- ArgoCD - GitOps deployment
- Traefik - Ingress controller and reverse proxy
- MetalLB - Load balancer for bare metal
- Cert-Manager - TLS certificate management
- External Secrets Operator - Secret synchronization from 1Password
- OnePassword Connect - 1Password integration
- Reloader - Auto-reload on ConfigMap/Secret changes

**Applications:**

- AdGuard Home (K3s instance) - DNS filtering at 10.11.12.14
- Authelia - Authentication portal
- Frigate - Network Video Recorder
- Gatus - Service health monitoring (status.home.example.com)
- Home Assistant - Home automation (ha.home.example.com)
- Kubernetes Dashboard - Cluster management UI
- MQTT (Mosquitto) - Message broker

**External Service Proxies (via Traefik IngressRoutes):**

- blog.home.example.com → 10.11.12.140:2368 (Web App in CT 112)
- ha.home.example.com → K3s service (Home Assistant in home-assistant
  namespace)
- adguard-pi.home.example.com → 10.11.12.22:80 (AdGuard on Pi)
- z2m.home.example.com → 10.11.12.22:8080 (Zigbee2MQTT on Pi)
- unifi.home.example.com → 10.11.12.1:443 (UniFi controller)
- proxmox.home.example.com → 10.11.12.10:8006 (Proxmox web UI)

**Observability Stack:**

- Loki - Log aggregation (loki.home.example.com)
- Grafana - Dashboards and visualization (grafana.home.example.com)
- Prometheus - Metrics collection
- Tempo - Distributed tracing

## Centralized Logging

**Architecture:**

- **Loki** runs in K3s cluster, stores logs in MinIO (S3-compatible storage)
- **Promtail** runs on infrastructure hosts, pushes logs to Loki via HTTPS
- **Grafana** provides the UI for querying logs

**Hosts with Promtail:**

- homeserver (Proxmox host) - system logs + PVE logs
- services-pi (Raspberry Pi) - system logs + AdGuard querylog + Zigbee2MQTT
- webapp - system logs + app logs + nginx logs

**Authentication:**

Promtail authenticates to Loki using HTTP Basic Auth. Credentials are stored in
1Password (`loki-push-credentials`) and injected via:

- K3s: ExternalSecret creates `loki-basic-auth` secret for Traefik middleware
- Ansible: `op inject` provides credentials to Promtail config

**Querying Logs via CLI:**

Install logcli: `brew install logcli`

**1Password item:** `loki-push-credentials` in vault `homeserver`

- Fields: `username`, `password`

```bash
# Set up authentication (use op to get credentials)
export LOKI_ADDR="https://loki.home.example.com"
export LOKI_USERNAME=$(op read 'op://homeserver/loki-push-credentials/username')
export LOKI_PASSWORD=$(op read 'op://homeserver/loki-push-credentials/password')

# List available labels
logcli labels

# List hosts sending logs
logcli labels host

# Query recent logs from a host
logcli query '{host="homeserver"}' --limit=50

# Query systemd journal logs
logcli query '{job="systemd-journal", host="homeserver"}' --limit=20

# Query with time range (last 1 hour)
logcli query '{host="services-pi"}' --since=1h

# Follow logs in real-time
logcli query '{host="webapp"}' --tail

# Query K3s pod logs by namespace
logcli query '{namespace="gatus"}' --limit=20

# Query K3s pod logs by app name
logcli query '{app="gatus"}' --limit=20

# Query all K3s pods
logcli query '{job=~".*/.*"}' --limit=50

# Search for errors across all sources
logcli query '{} |= "error"' --limit=50
```

**Deploying Promtail to hosts:**

```bash
./scripts/ansible/promtail.sh                    # All hosts
./scripts/ansible/promtail.sh --limit homeserver # Single host
```

## Offsite Backups (Restic + Backblaze B2)

**Architecture:**

- **Centralized backup** - All hosts rsync to homeserver, then restic backs up
  to B2
- **Restic** runs only on homeserver via systemd timer
- **Backblaze B2** provides offsite cloud storage
- **1Password** stores all credentials

**Backup Flow:**

| Source                          | Method | Destination                      | Schedule                     |
| ------------------------------- | ------ | -------------------------------- | ---------------------------- |
| Pi (zigbee2mqtt)                | rsync  | `/mnt/tank/backups/services-pi/` | Every 2 hours                |
| Homeserver central dirs + media | restic | Backblaze B2                     | Daily                        |

**Retention Policy:** 7 daily, 4 weekly, 12 monthly snapshots.

**NOT backed up (reconstructible):**

- Movies/TV shows (can re-download)
- K3s cluster (managed by ArgoCD/IaC)
- Home Assistant (use HA's built-in backup or Google Drive Backup add-on)
- AdGuard Home (config managed in Ansible)

**Credentials (1Password):**

- `backblaze-restic-credentials` - Restic uses this for backups
- `ssh-key-services-pi` - Pi uses this to rsync to homeserver

**Managing Backups:**

```bash
# Deploy/update backup config
./run_playbook.sh playbooks/backups.yml      # Homeserver restic
./run_playbook.sh playbooks/zigbee2mqtt.yml  # Pi rsync backup
./run_playbook.sh playbooks/webapp.yml   # Webapp config

# Trigger manual backup
ssh root@10.11.12.10 "systemctl start restic-backup"

# Check backup status
ssh root@10.11.12.10 "systemctl status restic-backup"
ssh root@10.11.12.10 "journalctl -u restic-backup -f"

# Test rsync backups manually
ssh youruser@10.11.12.22 "sudo -u youruser /opt/zigbee2mqtt/data/backup.sh"
```

**Querying/Restoring Backups:**

```bash
# Set up environment
export B2_ACCOUNT_ID=$(op read 'op://homeserver/backblaze-restic-credentials/username')
export B2_ACCOUNT_KEY=$(op read 'op://homeserver/backblaze-restic-credentials/password')
export RESTIC_PASSWORD=$(op read 'op://homeserver/backblaze-restic-credentials/restic_password')
BUCKET=$(op read 'op://homeserver/backblaze-restic-credentials/bucket')

# List snapshots
restic -r "b2:$BUCKET:homeserver" snapshots

# Restore specific path from latest snapshot
restic -r "b2:$BUCKET:homeserver" restore latest \
  --include /mnt/tank/backups/services-pi --target /restore

# Restore entire snapshot
restic -r "b2:$BUCKET:homeserver" restore latest --target /restore
```

**Terraform (B2 infrastructure):**

```bash
cd terraform && ./run_terraform.sh backblaze plan   # Preview changes
cd terraform && ./run_terraform.sh backblaze apply  # Apply changes
```

## K3s Directory Structure (Main Cluster Only)

**k3s/apps/**: Helm application definitions managed by ArgoCD ApplicationSets

- Each app directory contains ONLY:
  - `application.yaml` - ArgoCD application configuration
  - `values.yaml` - Helm chart values
- **NO other files allowed** - Helm apps only support these two files
- Deployed by `k3s/helm-apps-applicationset.yaml`

**k3s/resources/**: Raw Kubernetes manifests organized by purpose

- `traefik-config/` - IngressRoutes, Middlewares, ServersTransports
- `external-secrets-config/` - ClusterSecretStores, per-app External Secrets
- `{app-name}-config/` - App-specific manifests (ServiceAccounts, Secrets, etc.)
- Deployed by `k3s/config-resources-applicationset.yaml`

**ArgoCD ApplicationSets:**

- `k3s/helm-apps-applicationset.yaml` - Manages all Helm applications in
  `k3s/apps/`
- `k3s/config-resources-applicationset.yaml` - Manages all raw manifests in
  `k3s/resources/`

**File Placement Rules:**

- Helm chart configuration → `k3s/apps/{app-name}/`
- Raw Kubernetes manifests → `k3s/resources/{purpose}-config/`
- Cross-namespace resources (IngressRoutes, ClusterSecretStores) →
  `k3s/resources/`
- App-specific manifests (ServiceAccounts, Secrets) →
  `k3s/resources/{app-name}-config/`

## Authelia Middleware Usage

**IMPORTANT: Do NOT add authelia middleware to IngressRoutes by default.**

Authelia is ONLY for services that lack their own authentication. Most
applications have built-in auth and don't need it.

**Services that NEED authelia middleware:**

- Kubernetes Dashboard (no built-in auth)
- Prometheus/Alertmanager (no built-in auth)
- Services explicitly configured without authentication

**Services that do NOT need authelia:**

- Frigate (has built-in user authentication)
- Home Assistant (has built-in auth)
- ArgoCD (has built-in auth)
- Grafana (has built-in auth)
- AdGuard Home (has built-in auth)

When creating IngressRoutes, only add the authelia middleware if the service
genuinely has no authentication mechanism.

## SSH Access

- **Router (Ubiquiti UDM)**: `ssh root@10.5.0.1`
- **Homeserver (Proxmox)**: `ssh root@10.11.12.10`
- **K3s Cluster Container (ArgoCD/Home Services)**: `ssh root@10.11.12.11`
- **CircleCI K3s Container (Self-hosted runners)**: `ssh root@10.11.12.30`
- **Zigbee Pi**: `ssh youruser@10.11.12.202`

## SSH Key Variables

**IMPORTANT: There are two different SSH key variables used in the
infrastructure:**

- **`host_ssh_public_key` / `host_ssh_private_key`**: SSH keys generated ON the
  homeserver (Proxmox host) that are used when the HOST needs SSH access to
  other systems (e.g., Git repositories, other servers). These are stored in
  `/root/.ssh/` on the homeserver.

- **`user_ssh_public_key`**: YOUR personal SSH public key that gets added to
  servers for remote access. This allows YOU to SSH into the infrastructure from
  your laptop/workstation.

**Usage examples:**

- Host SSH keys: Used for ArgoCD to access Git repositories, automated scripts,
  etc.
- User SSH keys: Used for you to SSH into the homeserver, containers, VMs

## Web Interfaces

- **ArgoCD**: http://10.11.12.11:30080 (admin/password from kubectl)

## Helm Chart Research Commands

**CRITICAL: Always research Helm charts thoroughly before making configuration
changes.**

**Required research steps for any Helm chart configuration:**

1. **Chart Values Structure**:

   ```bash
   helm show values <chart-repo>/<chart-name>
   ```

   Shows all configurable options with comments and examples

2. **Chart Documentation**:

   ```bash
   helm show readme <chart-repo>/<chart-name>
   ```

   Chart-specific documentation and usage examples

3. **Template Rendering**:

   ```bash
   helm template <release-name> <chart-repo>/<chart-name> --set key=value
   ```

   Shows exactly how configuration values are rendered into Kubernetes manifests

4. **Chart Metadata**:

   ```bash
   helm show chart <chart-repo>/<chart-name>
   ```

   Chart version, description, and dependencies

5. **Current Deployed Values**:
   ```bash
   helm get values <release-name> -n <namespace>
   ```
   See actual values used in deployed release

**Examples for Traefik chart research:**

```bash
# See all available configuration options
helm show values traefik/traefik | grep -A 20 -B 5 plugin

# Template with plugin config to see rendered output
helm template traefik traefik/traefik \
  --set experimental.plugins.demo.moduleName=github.com/traefik/plugindemo \
  --set experimental.plugins.demo.version=v0.2.1

# Check current Traefik deployment values
helm get values traefik -n traefik
```

**NEVER make assumptions about chart configuration - always verify with these
commands first.**

## Common Commands

### ArgoCD Management

**ALWAYS use the deploy script for all changes** - it handles everything:

```bash
# Full deploy with commit, push, and sync (RECOMMENDED)
./scripts/deploy_argocd.sh "Your commit message"

# Skip validation (faster, use when you know config is valid)
./scripts/deploy_argocd.sh "Your commit message" --skip-validation

# Sync current git revision without commit/push (only after already pushed)
./scripts/deploy_argocd.sh --sync
```

The deploy script automatically:

1. Formats files (`./scripts/validate/format.sh`)
2. Validates Helm charts (`./scripts/validate/k3s.sh`)
3. Runs `git add -A`
4. Commits with your message
5. Pushes to remote
6. Syncs ArgoCD ApplicationSets and all apps

**IMPORTANT:** Always pass a commit message - the script handles git add,
commit, and push for you. Only use `--sync` when changes are already pushed and
you just need to trigger ArgoCD sync.

**Manual commands (use only for debugging)**:

```bash
ssh root@10.11.12.11 "argocd app list"
ssh root@10.11.12.11 "argocd app sync <app-name> --prune"
ssh root@10.11.12.11 "argocd app get <app-name>"
ssh root@10.11.12.11 "argocd app diff <app-name>"
```

### Checking ArgoCD Applications (kubectl)

```bash
ssh root@10.11.12.11 "kubectl get applications -n argocd"
ssh root@10.11.12.11 "kubectl get application <app-name> -n argocd -o yaml"
```

### Debugging Failed Deployments

```bash
ssh root@10.11.12.11 "kubectl describe deployment <deployment-name>"
```

### Secrets Management

**External Secrets Operator with Per-App SecretStores:**

Each app manages its own secrets within its own namespace using a dedicated
SecretStore. This provides better isolation and follows least-privilege
principles.

**ClusterSecretStores (Shared Across All Apps):**

- `onepassword-connect` - Pulls secrets from 1Password vault "homeserver"

**Per-App SecretStore Pattern:**

1. **1Password Integration** - ExternalSecret uses `onepassword-connect`
   ClusterSecretStore to pull secrets from 1Password vault
2. **Local Secrets** - SecretStore in each app's namespace handles reading local
   Kubernetes secrets (e.g., service account tokens)
3. **Template Rendering** - ExternalSecrets apply templates and create final
   configuration secrets

**Namespace Strategy:**

- Each app has its own SecretStore in its namespace for local secret management
- Apps use the shared `onepassword-connect` ClusterSecretStore for 1Password
  integration
- All secrets and configuration live within the app's own namespace
- No cross-namespace secret access needed

**Example for AdGuard Home:**

- `adguard-credentials` - Raw username/password from 1Password (sync-wave: 0,
  namespace: adguard-home)
- `adguard-config` - Templated AdGuardHome.yaml with bcrypt password (sync-wave:
  1, namespace: adguard-home)

**1Password Vault Structure:**

- Vault: `homeserver` (ID: 1)
- Example secrets:
  - `adguard-home-login` - AdGuard Home credentials
    - `username` - Admin username
    - `password` - Admin password (plain text, bcrypt applied by External
      Secrets templates)

## Infrastructure Setup Scripts

### Host Configuration

```bash
# Configure Proxmox host (Tailscale, networking, etc.)
./scripts/ansible/host.sh

# Configure K3s cluster (install k3s, ArgoCD, AdGuard ConfigMap, etc.)
./scripts/ansible/k3s_lxc.sh
```

**IMPORTANT: The K3s AdGuard Home config is managed by Ansible, NOT ArgoCD.**

The K3s AdGuard Home uses a ConfigMap (`config-template`) that is created by the
`k3s_lxc.sh` Ansible playbook. This ConfigMap contains the AdGuardHome.yaml
configuration including DNS rewrites. ArgoCD only manages the Helm deployment,
not the config content.

To update K3s AdGuard DNS rewrites:

1. Edit `ansible/roles/adguardhome/templates/AdGuardHome.yaml.j2`
2. Run `./scripts/ansible/k3s_lxc.sh`
3. The pod will auto-restart via Reloader when ConfigMap changes

### Terraform Operations

```bash
# Apply specific Terraform configuration (from terraform/ directory)
cd terraform && ./run_terraform.sh <module> init     # Initialize Terraform
cd terraform && ./run_terraform.sh <module> plan     # Show planned changes
cd terraform && ./run_terraform.sh <module> apply    # Apply changes
cd terraform && ./run_terraform.sh <module> apply -auto-approve  # Apply without confirmation

# Examples:
cd terraform && ./run_terraform.sh unifi apply -auto-approve    # UniFi network config
cd terraform && ./run_terraform.sh proxmox apply -auto-approve  # Proxmox VMs/containers
```

**Proxmox Container Import Format:**

When importing existing Proxmox containers into Terraform, use `pve/<vmid>`
format:

```bash
# Correct format - pve/<vmid>
cd terraform && ./run_terraform.sh proxmox import proxmox_virtual_environment_container.webapp pve/112

# WRONG format - do NOT use pve/lxc/<vmid>
# terraform import ... pve/lxc/112  # This will fail!
```

### Development Environment

```bash
# Complete development environment setup (REQUIRED)
./scripts/setup/dev.sh
```

This script automatically:

- Installs all required tools (Helm, kubeconform, kube-linter, yq, kustomize)
- Sets up Python virtual environment
- Configures Helm repositories from helm-repos.yaml
- Runs validation to ensure everything works

**NEVER run manual installation commands** - always use the setup scripts.

### Validation and Testing

```bash
# Validate k3s configuration (Helm charts, raw resources)
./scripts/validate/k3s.sh

# Run all validations (k3s, terraform, ansible, etc.)
./scripts/validate/all.sh

# Run GitHub Actions locally (requires act)
./scripts/run_ci_locally.sh
```

## Local Validation Workflow

**The deploy script automatically runs validations**, but you can also run them
manually:

### 1. Setup Development Environment

```bash
# Run the dev setup script (REQUIRED)
./scripts/setup/dev.sh
```

### 2. Validation Commands

**Use the deploy script (recommended)**:

```bash
./scripts/deploy_argocd.sh "Your commit message"
```

**Or run validation manually**:

```bash
./scripts/validate/k3s.sh
```

The validation script performs:

- Helm lint with values
- Helm template rendering
- Schema validation with kubeconform
- Policy linting with kube-linter
- Raw Kubernetes resource validation
- Kustomize build validation

### 3. Required Helm Repositories

Repositories are automatically managed via `helm-repos.yaml` and installed by
the dev setup script:

```bash
./scripts/setup/dev.sh
```

### 4. Common Validation Errors

- `volumeMounts[].name: Not found` - volume mount references non-existent volume
- `Invalid value: "privileged"` - wrong field placement in chart values
- `duplicate entries for key [mountPath="/host"]` - conflicting volume mounts
- `Bidirectional mount propagation` - requires privileged containers
- `Unknown repo URL` - add mapping to helm-repos.yaml url_mappings section

**Always use the deploy script** - it catches validation errors before they
reach the cluster.

## Finding Helm Chart Versions Programmatically

When working with Helm charts, use these methods to find the latest versions:

### Traditional Helm Repositories

1. **Helm search**: `helm search repo chart-name --versions`
2. **Repository index**: Check `https://repo-url/index.yaml` for all versions
3. **Helm show**: `helm show chart repo/chart-name` for metadata

### OCI Repositories (like TrueCharts)

1. **TrueCharts website**: Check
   https://truecharts.org/charts/stable/CHART-NAME/ for version info
2. **Helm search hub**: `helm search hub chart-name` (if indexed)
3. **Registry API**: Query OCI registry endpoints (if supported)
4. **GitHub releases**: For charts hosted on GitHub, use releases API

### TrueCharts Specific

- **Chart pages**: Navigate to https://truecharts.org/charts/stable/CHART-NAME/
- **OCI registry**: `oci://tccr.io/truecharts/CHART-NAME`
- **GitHub values**:
  https://github.com/truecharts/public/blob/master/charts/stable/CHART-NAME/values.yaml
- **Common library**:
  https://github.com/truecharts/public/blob/master/charts/library/common/values.yaml

**TrueCharts Configuration Process:**

1. Check chart page: https://truecharts.org/charts/stable/CHART-NAME/
2. Get latest version number and AppVersion
3. Download chart values:
   https://github.com/truecharts/public/blob/master/charts/stable/CHART-NAME/values.yaml
4. Download common values:
   https://github.com/truecharts/public/blob/master/charts/library/common/values.yaml
5. Reference both URLs in values.yaml comments
6. Use OCI format: `oci://tccr.io/truecharts/CHART-NAME`

**Example for AdGuard Home:**

- Chart page: https://truecharts.org/charts/stable/adguard-home/
- Version: 11.5.7, AppVersion: 0.107.62
- Chart values:
  https://github.com/truecharts/public/blob/master/charts/stable/adguard-home/values.yaml
- Common values:
  https://github.com/truecharts/public/blob/master/charts/library/common/values.yaml
- Use: `oci://tccr.io/truecharts/adguard-home:11.5.7`

**Key TrueCharts Patterns:**

- Top-level `TZ: timezone` for timezone configuration
- Service structure: `service.SERVICE-NAME.enabled: true` with separate services
- Common library provides base configuration and defaults
- All charts inherit from common library values

**TrueCharts v3 Volume Mounting:**

TrueCharts removed `extraVolumes`/`extraVolumeMounts` in common-v3. Use
`persistence` entries instead:

```yaml
persistence:
  volume-name:
    enabled: true
    type: secret # or configMap, pvc, etc.
    objectName: secret-name # name of the Secret/ConfigMap
    subPath: filename.yaml # mount single file from secret
    mountPath: /path/to/file
    readOnly: true
    optional: true # prevents validation errors for External Secrets
    targetSelector: # only mount in specific containers
      main:
        main: {} # pod-name: container-name
```

**Volume Types:**

- `secret` - Mount Kubernetes Secret
- `configMap` - Mount ConfigMap
- `pvc` - Mount PersistentVolumeClaim
- `emptyDir` - Temporary storage

**Key Fields:**

- `objectName` - Name of the Kubernetes object to mount
- `subPath` - Mount single file instead of entire volume
- `optional: true` - Required for External Secrets (prevents validation errors)
- `targetSelector` - Limits mount to specific pods/containers

**CRITICAL: TrueCharts Naming Convention**

**Documentation:** https://truecharts.org/common/persistence/ and
https://truecharts.org/common/persistence/secret/

- **Default behavior**: TrueCharts expands secret names to
  `$FullName-$objectName`
- **Example**: Release `adguard-home` with `objectName: config` becomes
  `adguard-home-config`
- **External Secrets must match**: Set `target.name` to the expanded name OR use
  `expandObjectName: false`

**Advanced Fields:**

- `expandObjectName: false` - Disables automatic `$FullName-` prefixing
- `targetSelectAll: true` - Mount to all pods/containers (ignores
  targetSelector)

**Target Selector Options:**

- Empty `targetSelector` - Mount to primary pod/container only
- Specific `targetSelector` - Mount to specified pods/containers
- `targetSelectAll: true` - Mount to all pods/containers

## SSH Host Key Management

**CRITICAL: When encountering "Host key verification failed" errors:**

- **NEVER use** `StrictHostKeyChecking=no` or similar SSH arguments
- **ALWAYS fix properly** using `ssh-keyscan` to add the host key to known_hosts
- **Example**: `ssh-keyscan -H <hostname_or_ip> >> ~/.ssh/known_hosts`

This maintains security while properly managing known host keys.

## ArgoCD OCI Helm Chart Support

**CRITICAL: OCI chart configuration requires specific setup to avoid errors like
"unsupported scheme 'oci'" or "repo URL is invalid".**

Reference:
https://medium.com/@qdrddr/argocd-app-with-helm-from-oci-repo-e52066647d99

### Required Components

1. **OCI Repository Secret** (in
   `k3s/resources/argocd-config/truecharts-oci-repo.yaml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    argocd.argoproj.io/secret-type: repository
  name: truecharts-oci
  namespace: argocd
stringData:
  url: tccr.io/truecharts
  name: truecharts
  type: helm
  enableOCI: 'true'
```

2. **Application Configuration** (for OCI charts like AdGuard Home):

```yaml
---
name: adguard-home
namespace: adguard-home
repoURL: tccr.io/truecharts # NO oci:// prefix, matches secret URL
localChartPath: adguard-home # Chart path within OCI registry
chart: adguard-home # Chart name (often same as path)
version: 11.5.7
values: values.yaml
```

3. **ApplicationSet templatePatch** (handles both OCI and regular charts):

```yaml
templatePatch: |
  spec:
    sources:
      - repoURL: '{{ .repoURL }}'
        {{- if hasKey . "localChartPath" }}
        path: '{{ .localChartPath }}'
        {{- end }}
        chart: '{{ .chart }}'
        targetRevision: '{{ .version }}'
        helm:
          releaseName: '{{ .name }}'
          valueFiles:
            - $values/k3s/apps/{{ .name }}/{{ .values }}
      - repoURL: git@github.com:youruser/homeserver-terraform-ansible.git
        targetRevision: HEAD
        ref: values
```

### Key Rules for OCI Charts

1. **URL Splitting**: Split `oci://tccr.io/truecharts/adguard-home` into:
   - Secret URL: `tccr.io/truecharts` (no `oci://` prefix)
   - Application repoURL: `tccr.io/truecharts` (matches secret)
   - Application path: `adguard-home`
   - Application chart: `adguard-home`

2. **Both path AND chart required**: OCI charts need both fields in the
   Application spec

3. **Use localChartPath**: Use `localChartPath` in application.yaml (not `path`
   which is reserved by ArgoCD)

4. **hasKey check**: Always use `hasKey . "localChartPath"` in templatePatch to
   avoid templating errors

### Common Errors and Solutions

- **"unsupported scheme 'oci'"**: Missing OCI repository secret with
  `enableOCI: 'true'`
- **"repo URL is invalid"**: Missing `repoURL` in templatePatch (array
  replacement loses original fields)
- **"path vs chart conflict"**: Using both `path:` and `chart:` incorrectly in
  same source
- **Template errors**: Using `{{.path}}` instead of `{{.localChartPath}}` or
  missing `hasKey` check

This configuration allows OCI charts to work alongside traditional Helm charts
in the same ApplicationSet.

# important-instruction-reminders

Do what has been asked; nothing more, nothing less. NEVER create files unless
they're absolutely necessary for achieving your goal. ALWAYS prefer editing an
existing file to creating a new one. NEVER proactively create documentation
files (\*.md) or README files. Only create documentation files if explicitly
requested by the User.

**When deleting sections from files, NEVER leave comments saying "this was moved
somewhere else" or explaining where content went. Simply delete the section
cleanly.**

NOTE: CLAUDE.md is a symlink to this file (docs/AI_RULES.md). Always edit this
file directly, not the symlink.

## DNS Configuration Rules

**There are TWO AdGuard Home instances:**

1. **K3s AdGuard (10.11.12.14)**: Primary DNS for end-user devices (laptops,
   phones). This is the default DNS server for the network.
2. **Pi AdGuard (10.11.12.22)**: Backup DNS on Raspberry Pi.

**Both instances must have matching DNS rewrite rules.** When adding new DNS
rewrites:

- Update `ansible/roles/adguardhome/templates/AdGuardHome.yaml.j2` (Pi config)
- Run `./scripts/ansible/k3s_lxc.sh` to update the K3s AdGuard ConfigMap
- Run `./scripts/ansible/services_pi/adguard_home.sh` to update the Pi AdGuard

**IMPORTANT: Wildcard DNS does NOT match the bare domain.**

- `*.home.example.com` matches `foo.home.example.com` but NOT
  `home.example.com`
- You must add BOTH entries for a domain and its wildcard:
  ```yaml
  - domain: home.example.com
    answer: 10.11.12.12
  - domain: '*.home.example.com'
    answer: 10.11.12.12
  ```

Infrastructure and servers should use router DNS (10.11.12.1) NOT AdGuard or
public DNS.

## 1Password SSH Agent Issues

**If SSH or git operations fail with "1Password: failed to fill whole buffer" or
"communication with agent failed":**

This happens when 1Password is locked or Touch ID is not available (e.g., user
is away from computer). These errors are transient - simply wait for the user to
return and authenticate with Touch ID.

**Do NOT attempt workarounds** - just inform the user that authentication is
needed.

## RADIUS Dynamic VLAN Assignment

**FreeRADIUS runs in K3s and assigns VLANs to WiFi devices based on MAC
address.**

### Architecture

- **FreeRADIUS** (10.11.12.15) runs in the `freeradius` namespace
- **UniFi WLAN** "ExampleDevices" has RADIUS MAC Authentication enabled
- Devices connect to ExampleDevices SSID and get VLAN assigned by RADIUS
- Device config is centralized in `config/network.yaml`

### Configuration Files

| File                                              | Purpose                           |
| ------------------------------------------------- | --------------------------------- |
| `config/network.yaml`                             | Centralized device/network config |
| `ansible/roles/freeradius/templates/authorize.j2` | FreeRADIUS authorize template     |
| `terraform/unifi/wlans.tf`                        | WLAN configuration                |

### Adding a New Device to a VLAN

1. Add device to `config/network.yaml`:

   ```yaml
   devices:
     my_device:
       mac: 'XX:XX:XX:XX:XX:XX'
       network: cameras # Use network name, not VLAN ID
       ip: 10.5.20.10
       name: My Device
       note: Device description
   ```

2. Run Ansible to update FreeRADIUS ConfigMap:

   ```bash
   ./scripts/ansible/k3s_lxc.sh
   ```

3. Power cycle the device to force re-authentication

### UniFi UI Quirk: "Network" vs "VLAN ID"

**The UniFi UI shows two different things that can be confusing:**

- **"Network" column**: Shows the WLAN's default network (e.g., "Main"), NOT the
  actual network the device is on. This comes from the SSID configuration.

- **"VLAN ID" field**: Shows the actual 802.1Q VLAN tag assigned by RADIUS. This
  is what matters for traffic routing.

**Example:** A camera on ExampleDevices SSID might show:

- Network: Main (because SSID defaults to Main)
- VLAN ID: 20 (because RADIUS assigned VLAN 20)
- IP: 10.5.20.10 (from Cameras DHCP pool)

The device is actually on the Cameras network (VLAN 20), even though the UI says
"Main" in the Network column. The VLAN ID determines:

- Which subnet/DHCP pool the device uses
- Which firewall rules apply
- Traffic isolation from other VLANs

### RADIUS Profile Management

**IMPORTANT: The UniFi Terraform provider has bugs with RADIUS profiles.**

The RADIUS profile "FreeRADIUS" is managed manually in the UniFi UI, NOT via
Terraform. The Terraform provider creates malformed profiles that break the UI.

To modify the RADIUS profile:

1. Go to UniFi Network → Settings → Profiles → RADIUS
2. Edit "FreeRADIUS" profile directly in the UI

### Debugging RADIUS

Check FreeRADIUS logs:

```bash
logcli query '{namespace="freeradius"}' --limit=50 --since=10m
```

Check UDM logs for VLAN assignment:

```bash
ssh root@10.11.12.1 "tail -200 /var/log/messages | grep -i '64:57:25'"
```

Look for these key log entries:

- `DVLAN STA[mac] set dvlan[20]` - VLAN assigned by RADIUS
- `RADIUS: VLAN ID 20` - hostapd received VLAN from RADIUS
- `EVENT_STA_IP: mac / 10.5.20.x` - Device got correct IP

## API Version Rules

**ALWAYS use the latest stable API versions for Kubernetes resources:**

- **ExternalSecret**: Use `external-secrets.io/v1` NOT `v1beta1` or `v1alpha1`
- **Certificate**: Use `cert-manager.io/v1` NOT `v1beta1` or `v1alpha1`
- **Issuer/ClusterIssuer**: Use `cert-manager.io/v1` NOT `v1beta1` or `v1alpha1`
- **MetalLB IPAddressPool**: Use `metallb.io/v1beta1` NOT deprecated
  `v1beta1 AddressPool`

When creating or editing Kubernetes manifests, check the current API versions
installed in the cluster and use the latest stable version. Never use deprecated
API versions.
