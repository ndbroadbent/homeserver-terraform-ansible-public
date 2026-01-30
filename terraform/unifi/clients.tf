# UniFi clients - generated from config/network.yaml devices section
# Network assignment is automatic based on device.network field

locals {
  # Map network names to unifi_network resource IDs
  network_ids = {
    main    = unifi_network.main.id
    cameras = unifi_network.cameras.id
    devices = unifi_network.devices.id
  }
}

resource "unifi_user" "device" {
  for_each = local.devices

  mac      = each.value.mac
  name     = each.value.name
  fixed_ip = each.value.ip
  note     = each.value.note

  # Only set network_id for non-main networks (main is default)
  network_id = each.value.network != "main" ? local.network_ids[each.value.network] : null
}
