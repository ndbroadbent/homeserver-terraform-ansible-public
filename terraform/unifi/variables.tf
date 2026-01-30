variable "unifi_api_key" {
  description = "UniFi controller API key"
  type        = string
  sensitive   = true
}

variable "home_wifi_password" {
  description = "Home WiFi password"
  type        = string
  sensitive   = true
}

variable "home_devices_password" {
  description = "HomeDevices WiFi password"
  type        = string
  sensitive   = true
}

variable "home_guest_password" {
  description = "HomeGuest WiFi password"
  type        = string
  sensitive   = true
}