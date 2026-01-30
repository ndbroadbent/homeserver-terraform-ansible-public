variable "tailscale_oauth_client_id" {
  description = "Tailscale OAuth client ID"
  type        = string
  sensitive   = true
}

variable "tailscale_oauth_client_secret" {
  description = "Tailscale OAuth client secret"
  type        = string
  sensitive   = true
}

variable "pve_device_id" {
  description = "Tailscale device ID for pve (homeserver)"
  type        = string
  default     = "nCwWJpo2y821CNTRL"
}
