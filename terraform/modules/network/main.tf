terraform {
  required_version = ">= 1.0"
}

# Use the validated networks from the variable
locals {
  networks     = var.networks
  main_network = local.networks.main
}