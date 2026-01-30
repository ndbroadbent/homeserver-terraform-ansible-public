# Download Ubuntu 22.04 LXC template
resource "proxmox_virtual_environment_download_file" "ubuntu_22_04_lxc_template" {
  content_type        = "vztmpl"
  datastore_id        = "local"
  node_name           = "pve"
  url                 = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  overwrite           = true
  overwrite_unmanaged = true
}

# Create K3s LXC Container
resource "proxmox_virtual_environment_container" "k3s_cluster" {
  # description = "K3s Kubernetes cluster container"
  tags = ["iac", "k3s", "kubernetes"]

  node_name = "pve"
  vm_id     = var.k3s_container_id

  # Container configuration
  unprivileged = false # Privileged container required for Kubernetes

  # CPU and Memory
  cpu {
    cores = var.k3s_cores
  }

  memory {
    dedicated = var.k3s_memory
    swap      = var.k3s_swap
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
    hostname = "k3s-cluster"

    ip_config {
      ipv4 {
        address = "${module.network.main.hosts.k3s}/24"
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
    size         = var.k3s_root_disk_size
  }

  # Mount points for K3s data and storage
  mount_point {
    path      = "/var/lib/rancher/k3s"
    volume    = "/mnt/rpool/k3s/config"
    shared    = false
    backup    = true
    read_only = false
  }

  mount_point {
    path      = "/mnt/media"
    volume    = "/mnt/tank/media"
    shared    = false
    backup    = false
    read_only = false
  }

  mount_point {
    path      = "/mnt/config"
    volume    = "/mnt/rpool/config"
    shared    = false
    backup    = true
    read_only = false
  }

  mount_point {
    path      = "/mnt/rpool-storage"
    volume    = "/mnt/rpool/k3s/storage"
    shared    = false
    backup    = false
    read_only = false
  }

  mount_point {
    path      = "/mnt/tank-storage"
    volume    = "/mnt/tank/k3s/storage"
    shared    = false
    backup    = false
    read_only = false
  }

  mount_point {
    path      = "/mnt/downloads"
    volume    = "/mnt/tank/downloads"
    shared    = false
    backup    = false
    read_only = false
  }

  mount_point {
    path      = "/mnt/backups"
    volume    = "/mnt/tank/backups"
    shared    = false
    backup    = false
    read_only = false
  }

  mount_point {
    path      = "/mnt/vm-disks"
    volume    = "/mnt/tank/vm-disks"
    shared    = false
    backup    = false
    read_only = false
  }

  mount_point {
    path      = "/var/lib/rancher/k3s/agent/containerd"
    volume    = "/mnt/rpool/k3s/containerd"
    shared    = false
    backup    = false
    read_only = false
  }

  mount_point {
    path      = "/mnt/frigate"
    volume    = "/mnt/tank/k3s/frigate"
    shared    = false
    backup    = false
    read_only = false
  }

  # Container features for Kubernetes
  features {
    keyctl  = true
    nesting = true
  }

  # Advanced LXC configuration will be handled by Ansible post-creation

  # Operating system template
  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.ubuntu_22_04_lxc_template.id
    type             = "ubuntu"
  }

  # Boot configuration
  startup {
    order      = 1
    up_delay   = 30
    down_delay = 60
  }

  # Auto-start container on host boot
  start_on_boot = true

  # Ansible will start the container
  # started = false

  # Prevent accidental destruction
  protection = false

  lifecycle {
    ignore_changes = [started, description]
  }
}

