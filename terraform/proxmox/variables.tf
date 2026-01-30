variable "proxmox_username" {
  description = "Proxmox root username"
  type        = string
  sensitive   = true
}

variable "proxmox_password" {
  description = "Proxmox root password"
  type        = string
  sensitive   = true
}


variable "k3s_container_id" {
  description = "Container ID for K3s cluster"
  type        = number
  default     = 200
}

variable "k3s_memory" {
  description = "Memory allocation for K3s container in MB"
  type        = number
  default     = 16384
}

variable "k3s_cores" {
  description = "CPU cores for K3s container"
  type        = number
  default     = 4
}

variable "k3s_swap" {
  description = "Swap allocation for K3s container in MB"
  type        = number
  default     = 2048
}

variable "k3s_root_disk_size" {
  description = "Root disk size for K3s container"
  type        = number
  default     = 128
}

variable "user_ssh_public_key" {
  description = "User SSH public key for root access"
  type        = string
  sensitive   = true
}


variable "circleci_runner_container_id" {
  description = "Container ID for CircleCI runner"
  type        = number
  default     = 121
}

variable "circleci_runner_memory" {
  description = "Memory allocation for CircleCI runner container in MB"
  type        = number
  default     = 32768 # 32GB for parallel jobs
}

variable "circleci_runner_cores" {
  description = "CPU cores for CircleCI runner container"
  type        = number
  default     = 24 # 24 cores for parallelism, leaving headroom for other services
}

variable "circleci_runner_swap" {
  description = "Swap allocation for CircleCI runner container in MB"
  type        = number
  default     = 8192 # 8GB swap
}

variable "circleci_runner_root_disk_size" {
  description = "Root disk size for CircleCI runner container"
  type        = number
  default     = 256 # 256GB for build artifacts and containers
}

variable "webapp_container_id" {
  description = "Container ID for Web App"
  type        = number
  default     = 112
}

variable "webapp_memory" {
  description = "Memory allocation for Web App container in MB"
  type        = number
  default     = 2048
}

variable "webapp_cores" {
  description = "CPU cores for Web App container"
  type        = number
  default     = 2
}

variable "webapp_swap" {
  description = "Swap allocation for Web App container in MB"
  type        = number
  default     = 512
}

variable "webapp_root_disk_size" {
  description = "Root disk size for Web App container"
  type        = number
  default     = 10
}

variable "example-company_tailscale_container_id" {
  description = "Container ID for ExampleCompany Tailscale exit node"
  type        = number
  default     = 113
}

variable "example-company_tailscale_memory" {
  description = "Memory allocation for ExampleCompany Tailscale container in MB"
  type        = number
  default     = 512
}

variable "example-company_tailscale_cores" {
  description = "CPU cores for ExampleCompany Tailscale container"
  type        = number
  default     = 1
}

variable "example-company_tailscale_swap" {
  description = "Swap allocation for ExampleCompany Tailscale container in MB"
  type        = number
  default     = 256
}

variable "example-company_tailscale_root_disk_size" {
  description = "Root disk size for ExampleCompany Tailscale container"
  type        = number
  default     = 4
}

variable "tailscale_exit_node_container_id" {
  description = "Container ID for personal Tailscale exit node"
  type        = number
  default     = 114
}

variable "tailscale_exit_node_memory" {
  description = "Memory allocation for Tailscale exit node container in MB"
  type        = number
  default     = 512
}

variable "tailscale_exit_node_cores" {
  description = "CPU cores for Tailscale exit node container"
  type        = number
  default     = 1
}

variable "tailscale_exit_node_swap" {
  description = "Swap allocation for Tailscale exit node container in MB"
  type        = number
  default     = 256
}

variable "tailscale_exit_node_root_disk_size" {
  description = "Root disk size for Tailscale exit node container"
  type        = number
  default     = 4
}

variable "data_processor_container_id" {
  description = "Container ID for data processor"
  type        = number
  default     = 116
}

variable "data_processor_memory" {
  description = "Memory allocation for data processor container in MB"
  type        = number
  default     = 16384 # 16GB for streaming large Wikidata dumps
}

variable "data_processor_cores" {
  description = "CPU cores for data processor container"
  type        = number
  default     = 8 # For parallel JSON parsing
}

variable "data_processor_swap" {
  description = "Swap allocation for data processor container in MB"
  type        = number
  default     = 4096
}

variable "data_processor_root_disk_size" {
  description = "Root disk size for data processor container"
  type        = number
  default     = 256 # 256GB for Wikidata dumps (~100GB) and processed data
}

variable "openclaw_container_id" {
  description = "Container ID for OpenClaw"
  type        = number
  default     = 117
}

variable "openclaw_memory" {
  description = "Memory allocation for OpenClaw container in MB"
  type        = number
  default     = 4096
}

variable "openclaw_cores" {
  description = "CPU cores for OpenClaw container"
  type        = number
  default     = 2
}

variable "openclaw_swap" {
  description = "Swap allocation for OpenClaw container in MB"
  type        = number
  default     = 512
}

variable "openclaw_root_disk_size" {
  description = "Root disk size for OpenClaw container"
  type        = number
  default     = 20
}

