terraform {
  required_version = ">= 1.0.0"
  required_providers {
    unifi = {
      source  = "filipowm/unifi"
      version = "~> 1.0"
    }
  }
}

locals {
  config  = yamldecode(file("../../config/network.yaml"))
  devices = local.config.devices
}

module "network" {
  source   = "../modules/network"
  networks = local.config.networks
}

provider "unifi" {
  api_key = var.unifi_api_key
  api_url = "https://${module.network.main.gateway}:443"

  allow_insecure = true
}
