# Personal Tailscale Exit Node LXC Container
#
# This container runs Tailscale as an exit node for the personal tailnet.
# It's on the main network so it can access internal services.
# Uses --accept-dns=true so DNS queries use AdGuard via split DNS config.

resource "proxmox_virtual_environment_container" "tailscale_exit_node" {
  tags = ["iac", "tailscale", "exit-node"]

  node_name = "pve"
  vm_id     = var.tailscale_exit_node_container_id

  # Unprivileged container - Tailscale works fine unprivileged
  unprivileged = true

  # CPU and Memory - minimal resources needed for exit node
  cpu {
    cores = var.tailscale_exit_node_cores
  }

  memory {
    dedicated = var.tailscale_exit_node_memory
    swap      = var.tailscale_exit_node_swap
  }

  # Network configuration on main network
  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "XX:XX:XX:XX:XX:XX" # Unique MAC for Tailscale exit node
    enabled     = true
    firewall    = false
  }

  initialization {
    hostname = "tailscale-exit-node"

    ip_config {
      ipv4 {
        address = "${module.network.main.hosts.tailscale_exit_node}/24"
        gateway = module.network.main.gateway
      }
    }

    dns {
      servers = [module.network.main.gateway] # Router DNS
    }

    user_account {
      keys = [var.user_ssh_public_key]
    }
  }

  # Root filesystem - minimal size needed
  disk {
    datastore_id = "local-zfs"
    size         = var.tailscale_exit_node_root_disk_size
  }

  # Container features - nesting for systemd
  features {
    nesting = true
  }

  # TUN device passthrough required for Tailscale
  device_passthrough {
    path = "/dev/net/tun"
    mode = "0666"
  }

  # Operating system template
  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.ubuntu_22_04_lxc_template.id
    type             = "ubuntu"
  }

  # Boot configuration - start after core services
  startup {
    order      = 5
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
