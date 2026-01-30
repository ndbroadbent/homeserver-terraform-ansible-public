# Zone-based firewall configuration
#
# Network Segmentation Strategy:
# - Main network stays in built-in "Internal" zone (trusted)
# - Cameras get their own zone (isolated)
# - Devices get their own zone (isolated)
#
# Default "Block All Traffic" handles most blocking. We only add Allow rules:
# - Allow Internal -> Cameras (for Frigate RTSP streams)
# - Allow Cameras/Devices -> Internal (return traffic only)
# - Block Cameras -> External (no internet access for cameras)

# Create Cameras zone and assign the cameras network to it
resource "unifi_firewall_zone" "cameras" {
  name     = "Cameras"
  networks = [unifi_network.cameras.id]
}

# Create Devices zone and assign the devices network to it
resource "unifi_firewall_zone" "devices" {
  name     = "Devices"
  networks = [unifi_network.devices.id]
}

# Lookup the built-in Internal zone (contains Main network)
data "unifi_firewall_zone" "internal" {
  name = "Internal"
}

# ============================================================================
# Zone Policies
# ============================================================================

# Allow Internal -> Cameras (Frigate pulls RTSP streams from cameras)
# This must be higher priority than any block rules
resource "unifi_firewall_zone_policy" "allow_internal_to_cameras" {
  name    = "Allow Internal to Cameras"
  action  = "ALLOW"
  enabled = true

  source = {
    zone_id = data.unifi_firewall_zone.internal.id
  }

  destination = {
    zone_id = unifi_firewall_zone.cameras.id
  }
}

# Allow Cameras -> Internal for return traffic only (responses to Frigate RTSP pulls)
resource "unifi_firewall_zone_policy" "allow_cameras_to_internal_return" {
  name    = "Allow Cameras to Internal (Return Traffic)"
  action  = "ALLOW"
  enabled = true

  # Only allow established/related connections (responses), not new connections
  connection_state_type = "RESPOND_ONLY"

  source = {
    zone_id = unifi_firewall_zone.cameras.id
  }

  destination = {
    zone_id = data.unifi_firewall_zone.internal.id
  }
}

# Allow Internal -> Devices (laptops need to reach printers/IoT devices)
resource "unifi_firewall_zone_policy" "allow_internal_to_devices" {
  name    = "Allow Internal to Devices"
  action  = "ALLOW"
  enabled = true

  source = {
    zone_id = data.unifi_firewall_zone.internal.id
  }

  destination = {
    zone_id = unifi_firewall_zone.devices.id
  }
}

# Allow Devices -> Internal for return traffic only
resource "unifi_firewall_zone_policy" "allow_devices_to_internal_return" {
  name    = "Allow Devices to Internal (Return Traffic)"
  action  = "ALLOW"
  enabled = true

  # Only allow established/related connections (responses), not new connections
  connection_state_type = "RESPOND_ONLY"

  source = {
    zone_id = unifi_firewall_zone.devices.id
  }

  destination = {
    zone_id = data.unifi_firewall_zone.internal.id
  }
}

# Note: The following are handled by the default "Block All Traffic" rule:
# - Cameras <-> Devices (blocked)
# - Cameras intra-zone (blocked)
# - Devices intra-zone (blocked)
# - Cameras -> Internal new connections (blocked, only return traffic allowed above)
# - Devices -> Internal new connections (blocked, only return traffic allowed above)
#
# Allowed by explicit rules above:
# - Internal -> Devices (laptops can reach printers, IoT devices)

# Lookup the built-in External zone (internet)
data "unifi_firewall_zone" "external" {
  name = "External"
}

# Block Cameras -> External (no internet access for cameras)
resource "unifi_firewall_zone_policy" "block_cameras_to_external" {
  name    = "Block Cameras to Internet"
  action  = "BLOCK"
  enabled = true

  source = {
    zone_id = unifi_firewall_zone.cameras.id
  }

  destination = {
    zone_id = data.unifi_firewall_zone.external.id
  }
}

# Lookup the built-in Gateway zone
data "unifi_firewall_zone" "gateway" {
  name = "Gateway"
}

# Port group for gateway management ports (SSH, HTTP, HTTPS)
resource "unifi_firewall_group" "gateway_mgmt_ports" {
  name    = "Gateway Management Ports"
  type    = "port-group"
  members = ["22", "80", "443"]
}

# Block Cameras -> Gateway management (SSH, HTTP, HTTPS)
# Still allows DNS (53) for normal network operations
resource "unifi_firewall_zone_policy" "block_cameras_to_gateway_mgmt" {
  name     = "Block Cameras to Gateway Management"
  action   = "BLOCK"
  enabled  = true
  protocol = "tcp"

  source = {
    zone_id = unifi_firewall_zone.cameras.id
  }

  destination = {
    zone_id       = data.unifi_firewall_zone.gateway.id
    port_group_id = unifi_firewall_group.gateway_mgmt_ports.id
  }
}

# Block Devices -> Gateway management (SSH, HTTP, HTTPS)
# Still allows DNS (53) for normal network operations
resource "unifi_firewall_zone_policy" "block_devices_to_gateway_mgmt" {
  name     = "Block Devices to Gateway Management"
  action   = "BLOCK"
  enabled  = true
  protocol = "tcp"

  source = {
    zone_id = unifi_firewall_zone.devices.id
  }

  destination = {
    zone_id       = data.unifi_firewall_zone.gateway.id
    port_group_id = unifi_firewall_group.gateway_mgmt_ports.id
  }
}

# ============================================================================
# ExampleCompany Tailscale Zone - Completely Isolated Exit Node
# ============================================================================
#
# This network is for a Tailscale exit node connected to the ExampleCompany tailnet.
# It must be completely isolated from all internal networks - can only reach
# the public internet to function as an exit node.

# Create ExampleCompany Tailscale zone
resource "unifi_firewall_zone" "example-company_tailscale" {
  name     = "ExampleCompany Tailscale"
  networks = [unifi_network.example-company_tailscale.id]
}

# Allow ExampleCompany Tailscale -> External (internet access for exit node)
resource "unifi_firewall_zone_policy" "allow_example-company_tailscale_to_external" {
  name    = "Allow ExampleCompany Tailscale to Internet"
  action  = "ALLOW"
  enabled = true

  source = {
    zone_id = unifi_firewall_zone.example-company_tailscale.id
  }

  destination = {
    zone_id = data.unifi_firewall_zone.external.id
  }
}

# Block ExampleCompany Tailscale -> Internal (no access to main network)
resource "unifi_firewall_zone_policy" "block_example-company_tailscale_to_internal" {
  name    = "Block ExampleCompany Tailscale to Internal"
  action  = "BLOCK"
  enabled = true

  source = {
    zone_id = unifi_firewall_zone.example-company_tailscale.id
  }

  destination = {
    zone_id = data.unifi_firewall_zone.internal.id
  }
}

# Block Internal -> ExampleCompany Tailscale (no access from main network)
resource "unifi_firewall_zone_policy" "block_internal_to_example-company_tailscale" {
  name    = "Block Internal to ExampleCompany Tailscale"
  action  = "BLOCK"
  enabled = true

  source = {
    zone_id = data.unifi_firewall_zone.internal.id
  }

  destination = {
    zone_id = unifi_firewall_zone.example-company_tailscale.id
  }
}

# Block ExampleCompany Tailscale -> Cameras (no access to cameras)
resource "unifi_firewall_zone_policy" "block_example-company_tailscale_to_cameras" {
  name    = "Block ExampleCompany Tailscale to Cameras"
  action  = "BLOCK"
  enabled = true

  source = {
    zone_id = unifi_firewall_zone.example-company_tailscale.id
  }

  destination = {
    zone_id = unifi_firewall_zone.cameras.id
  }
}

# Block Cameras -> ExampleCompany Tailscale (no access from cameras)
resource "unifi_firewall_zone_policy" "block_cameras_to_example-company_tailscale" {
  name    = "Block Cameras to ExampleCompany Tailscale"
  action  = "BLOCK"
  enabled = true

  source = {
    zone_id = unifi_firewall_zone.cameras.id
  }

  destination = {
    zone_id = unifi_firewall_zone.example-company_tailscale.id
  }
}

# Block ExampleCompany Tailscale -> Devices (no access to IoT devices)
resource "unifi_firewall_zone_policy" "block_example-company_tailscale_to_devices" {
  name    = "Block ExampleCompany Tailscale to Devices"
  action  = "BLOCK"
  enabled = true

  source = {
    zone_id = unifi_firewall_zone.example-company_tailscale.id
  }

  destination = {
    zone_id = unifi_firewall_zone.devices.id
  }
}

# Block Devices -> ExampleCompany Tailscale (no access from IoT devices)
resource "unifi_firewall_zone_policy" "block_devices_to_example-company_tailscale" {
  name    = "Block Devices to ExampleCompany Tailscale"
  action  = "BLOCK"
  enabled = true

  source = {
    zone_id = unifi_firewall_zone.devices.id
  }

  destination = {
    zone_id = unifi_firewall_zone.example-company_tailscale.id
  }
}

# Block ExampleCompany Tailscale -> Gateway management (SSH, HTTP, HTTPS)
# Still allows DNS (53) for normal network operations
resource "unifi_firewall_zone_policy" "block_example-company_tailscale_to_gateway_mgmt" {
  name     = "Block ExampleCompany Tailscale to Gateway Management"
  action   = "BLOCK"
  enabled  = true
  protocol = "tcp"

  source = {
    zone_id = unifi_firewall_zone.example-company_tailscale.id
  }

  destination = {
    zone_id       = data.unifi_firewall_zone.gateway.id
    port_group_id = unifi_firewall_group.gateway_mgmt_ports.id
  }
}
