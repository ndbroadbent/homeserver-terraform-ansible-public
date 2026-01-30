terraform {
  required_version = ">= 1.0.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

module "network" {
  source   = "../modules/network"
  networks = yamldecode(file("../../config/network.yaml")).networks
}

provider "proxmox" {
  endpoint = "https://${module.network.main.hosts.proxmox}:8006"
  username = var.proxmox_username
  password = var.proxmox_password

  insecure = true
}

