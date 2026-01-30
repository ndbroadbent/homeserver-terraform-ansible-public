# CircleCI Runner LXC Container
resource "proxmox_virtual_environment_container" "circleci_runner" {
  tags = ["iac", "circleci", "kubernetes", "runner"]

  node_name = "pve"
  vm_id     = var.circleci_runner_container_id

  # Container configuration
  unprivileged = false # Privileged container required for Kubernetes

  # CPU and Memory - maximize for parallel jobs
  cpu {
    cores = var.circleci_runner_cores
  }

  memory {
    dedicated = var.circleci_runner_memory
    swap      = var.circleci_runner_swap
  }

  # Network configuration with static IP
  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "XX:XX:XX:XX:XX:XX"
    enabled     = true
    firewall    = false
  }

  initialization {
    hostname = "circleci-runner"

    ip_config {
      ipv4 {
        address = "${module.network.main.hosts.circleci_runner}/24"
        gateway = module.network.main.gateway
      }
    }

    dns {
      servers = [module.network.main.gateway]
    }

    user_account {
      keys = [var.user_ssh_public_key]
    }
  }

  # Root filesystem
  disk {
    datastore_id = "local-zfs"
    size         = var.circleci_runner_root_disk_size
  }

  # Mount points for k3s data and storage
  mount_point {
    path      = "/var/lib/rancher/k3s"
    volume    = "/mnt/rpool/circleci-runner/k3s-config"
    shared    = false
    backup    = true
    read_only = false
  }

  mount_point {
    path      = "/var/lib/rancher/k3s/agent/containerd"
    volume    = "/mnt/rpool/circleci-runner/containerd"
    shared    = false
    backup    = false
    read_only = false
  }

  # Mount point for CircleCI cache storage
  mount_point {
    path      = "/var/cache/circleci"
    volume    = "/mnt/rpool/circleci-runner/cache"
    shared    = false
    backup    = false
    read_only = false
  }

  # Mount point for Redis persistent data
  mount_point {
    path      = "/var/lib/redis"
    volume    = "/mnt/rpool/circleci-runner/redis-data"
    shared    = false
    backup    = true
    read_only = false
  }

  # Mount point for MinIO object storage
  mount_point {
    path      = "/var/lib/minio"
    volume    = "/mnt/rpool/circleci-runner/minio-data"
    shared    = false
    backup    = true
    read_only = false
  }

  # Mount point for OpenEBS ZFS storage provisioning
  mount_point {
    path      = "/var/openebs/sparse"
    volume    = "/mnt/rpool/circleci-runner/storage"
    shared    = false
    backup    = false
    read_only = false
  }

  # Container features for Kubernetes
  features {
    keyctl  = true
    nesting = true
  }

  # Operating system template - reuse the same Ubuntu template
  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.ubuntu_22_04_lxc_template.id
    type             = "ubuntu"
  }

  # Boot configuration
  startup {
    order      = 2
    up_delay   = 30
    down_delay = 60
  }

  # Auto-start container on host boot
  start_on_boot = true

  # Prevent accidental destruction
  protection = false

  lifecycle {
    ignore_changes = [started, description]
  }
}

