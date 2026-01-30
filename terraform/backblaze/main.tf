terraform {
  required_version = ">= 1.0.0"
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.9"
    }
  }
}

provider "b2" {
  application_key_id = var.b2_application_key_id
  application_key    = var.b2_application_key
}

resource "b2_bucket" "backups" {
  bucket_name = var.bucket_name
  bucket_type = "allPrivate"

  lifecycle_rules {
    file_name_prefix              = ""
    days_from_hiding_to_deleting  = 1
    days_from_uploading_to_hiding = 0
  }
}

resource "b2_application_key" "restic" {
  key_name     = "restic-backup"
  bucket_id    = b2_bucket.backups.bucket_id
  capabilities = ["listBuckets", "listFiles", "readFiles", "writeFiles", "deleteFiles"]
}
