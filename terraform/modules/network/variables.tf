variable "networks" {
  description = "All layer-3 networks"
  type = map(object({
    subnet       = string
    gateway      = string
    vlan_id      = optional(number) # Only for non-default VLANs
    static_range = object({ start = string, end = string })
    dhcp_range   = object({ start = string, end = string })

    # only present on the main LAN
    metallb = optional(object({
      pool_start = string
      pool_end   = string
    }))

    hosts = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for network_name, network in var.networks :
      can(cidrhost(network.subnet, 0)) && can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", network.gateway))
    ])
    error_message = "Invalid IP addresses in network configuration."
  }
}