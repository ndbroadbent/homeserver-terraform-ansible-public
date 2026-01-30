resource "unifi_network" "main" {
  name          = "Main"
  purpose       = "corporate"
  subnet        = module.network.main.subnet
  vlan_id       = 0 # Default network must be VLAN 0
  network_group = "LAN"

  # DHCP Configuration  
  dhcp_enabled = true
  dhcp_start   = module.network.main.dhcp_range.start
  dhcp_stop    = module.network.main.dhcp_range.end
  dhcp_lease   = 86400
  # AdGuard DNS (K3s primary, Pi backup)
  dhcp_dns = [
    module.network.main.hosts.adguard_k3s,
    module.network.main.hosts.services_pi
  ]

  # Domain and multicast
  domain_name   = "home"
  multicast_dns = true
  igmp_snooping = false

  # IPv6 settings
  ipv6_interface_type = "none"
  ipv6_pd_interface   = "wan"
  ipv6_pd_start       = "::2"
  ipv6_pd_stop        = "::7d1"
  ipv6_ra_enable      = true
  ipv6_ra_priority    = "high"
  dhcp_v6_start       = "::2"
  dhcp_v6_stop        = "::7d1"
}

resource "unifi_network" "cameras" {
  name          = "Cameras"
  purpose       = "corporate"
  subnet        = module.network.networks.cameras.subnet
  vlan_id       = module.network.networks.cameras.vlan_id
  network_group = "LAN"

  # DHCP Configuration
  dhcp_enabled = true
  dhcp_start   = module.network.networks.cameras.dhcp_range.start
  dhcp_stop    = module.network.networks.cameras.dhcp_range.end
  dhcp_lease   = 86400
  dhcp_dns     = [] # No DNS - cameras don't need it

  # Domain and multicast
  domain_name   = ""
  multicast_dns = false # Locked down - no discovery
  igmp_snooping = false

  # IPv6 settings
  ipv6_interface_type = "none"
  ipv6_ra_enable      = false # Locked down
}

resource "unifi_network" "devices" {
  name          = "Devices"
  purpose       = "corporate"
  subnet        = module.network.networks.devices.subnet
  vlan_id       = module.network.networks.devices.vlan_id
  network_group = "LAN"

  # DHCP Configuration
  dhcp_enabled = true
  dhcp_start   = module.network.networks.devices.dhcp_range.start
  dhcp_stop    = module.network.networks.devices.dhcp_range.end
  dhcp_lease   = 86400
  dhcp_dns = [
    module.network.main.hosts.adguard_k3s,
    module.network.main.hosts.services_pi
  ]

  # Domain and multicast
  domain_name   = "devices.home"
  multicast_dns = true # Allow device discovery (Alexa, etc.)
  igmp_snooping = false

  # IPv6 settings
  ipv6_interface_type = "none"
  ipv6_ra_enable      = false
}

# Isolated network for ExampleCompany Tailscale exit node
# This container can ONLY reach the internet - no access to internal networks
resource "unifi_network" "example-company_tailscale" {
  name          = "ExampleCompany Tailscale"
  purpose       = "corporate"
  subnet        = module.network.networks.example-company_tailscale.subnet
  vlan_id       = module.network.networks.example-company_tailscale.vlan_id
  network_group = "LAN"

  # DHCP Configuration
  dhcp_enabled = true
  dhcp_start   = module.network.networks.example-company_tailscale.dhcp_range.start
  dhcp_stop    = module.network.networks.example-company_tailscale.dhcp_range.end
  dhcp_lease   = 86400
  dhcp_dns     = ["1.1.1.1", "8.8.8.8"] # Public DNS only - no internal DNS

  # Domain and multicast - fully locked down
  domain_name   = ""
  multicast_dns = false
  igmp_snooping = false

  # IPv6 settings
  ipv6_interface_type = "none"
  ipv6_ra_enable      = false
}
