resource "unifi_wlan" "home" {
  name          = "Home"
  network_id    = unifi_network.main.id
  user_group_id = "default"
  ap_group_ids  = ["61bfca482b159b0506678499"] # All APs group

  security   = "wpapsk"
  passphrase = var.home_wifi_password
  wlan_band  = "both" # 2.4GHz + 5GHz
}

resource "unifi_wlan" "home_devices" {
  name          = "HomeDevices"
  network_id    = unifi_network.main.id # Default VLAN, RADIUS overrides per-device
  user_group_id = "default"
  ap_group_ids  = ["61bfca482b159b0506678499"] # All APs group

  security   = "wpapsk"
  passphrase = var.home_devices_password
  wlan_band  = "both" # 2.4GHz + 5GHz

  # RADIUS profile created manually in UniFi UI (Terraform provider is buggy)
  # This ID references the manually-created "FreeRADIUS" profile
  radius_profile_id = "692c1f4a16f3ee5e65f784c1"
}

resource "unifi_wlan" "home_guest" {
  name = "HomeGuest"
  # network_id    = unifi_network.guest.id
  network_id    = unifi_network.main.id
  user_group_id = "default"
  ap_group_ids  = ["61bfca482b159b0506678499"] # All APs group

  security   = "wpapsk"
  passphrase = var.home_guest_password
  wlan_band  = "both" # 2.4GHz + 5GHz

  is_guest = true
}
