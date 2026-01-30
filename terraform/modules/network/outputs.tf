output "networks" {
  description = "All network configurations"
  value       = local.networks
}

output "main" {
  description = "Main network configuration"
  value       = local.main_network
}

output "cameras" {
  description = "Cameras network configuration"
  value       = local.networks.cameras
}