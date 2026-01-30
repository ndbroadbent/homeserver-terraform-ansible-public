# Tailscale ACL configuration for home network
resource "tailscale_acl" "main" {
  acl = file("${path.module}/acl.json")
}

# DNS configuration for home network
resource "tailscale_dns_preferences" "main" {
  magic_dns = true
}

# Split DNS: route home.example.com queries to AdGuard Home
resource "tailscale_dns_split_nameservers" "home" {
  domain = "home.example.com"
  nameservers = [
    "10.11.12.14", # AdGuard Home (K3s)
  ]
}

# Search domain for home network
resource "tailscale_dns_search_paths" "main" {
  search_paths = [
    "home.example.com",
  ]
}

# Tag pve as homeserver for auto-approved routes
resource "tailscale_device_tags" "pve" {
  device_id = var.pve_device_id
  tags      = ["tag:homeserver"]
}
