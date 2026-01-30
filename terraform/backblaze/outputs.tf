output "bucket_name" {
  description = "Name of the backup bucket"
  value       = b2_bucket.backups.bucket_name
}

output "bucket_id" {
  description = "ID of the backup bucket"
  value       = b2_bucket.backups.bucket_id
}

output "restic_key_id" {
  description = "Application key ID for restic"
  value       = b2_application_key.restic.application_key_id
  sensitive   = true
}

output "restic_key" {
  description = "Application key for restic"
  value       = b2_application_key.restic.application_key
  sensitive   = true
}
