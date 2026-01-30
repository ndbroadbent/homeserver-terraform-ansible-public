variable "b2_application_key_id" {
  description = "Backblaze B2 application key ID"
  type        = string
  sensitive   = true
}

variable "b2_application_key" {
  description = "Backblaze B2 application key"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "Name for the backup bucket"
  type        = string
  default     = "youruser-homeserver-backups"
}
