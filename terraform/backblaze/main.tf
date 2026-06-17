locals {
  backup_bucket_prefix = "velero-backups"
}

resource "b2_bucket" "ios_backups_bucket" {
  bucket_name = "ios-backups-bucket"
  bucket_type = "allPrivate"

  # Like AWS tags
  bucket_info = {
    environment = "production"
    project     = "cguertin14/infra"
    owner       = "cguertin14"
  }

  lifecycle {
    prevent_destroy = true # Must be destroyed in the console.
  }
}

resource "b2_bucket" "backup_bucket" {
  bucket_name = "${local.backup_bucket_prefix}-bucket"
  bucket_type = "allPrivate"

  # Cost control for B2 versioned objects:
  # purge hidden versions only for Velero metadata prefixes.
  # Do not apply lifecycle rules to kopia/, where aggressive version cleanup
  # can break repository integrity and restores.
  dynamic "lifecycle_rules" {
    for_each = ["backups/", "restores/"]
    content {
      file_name_prefix             = lifecycle_rules.value
      days_from_hiding_to_deleting = 30
    }
  }

  # Like AWS tags
  bucket_info = {
    environment = "production"
    project     = "cguertin14/infra"
    owner       = "cguertin14"
  }

  lifecycle {
    prevent_destroy = true # Must be destroyed in the console.
  }
}

# NOTE: The following is commented out so that it's done manually in the console.
#       Create an application key for the bucket, with Read+Write permissions.
#       Name it "velero-backups-app-key".
#
# resource "b2_application_key" "velero_app_key" {
#   key_name  = "${local.bucket_prefix}-app-key"
#   bucket_id = b2_bucket.backup_bucket.id
#   capabilities = [
#     "listFiles",
#     "readFiles",
#     "writeFiles",
#     "deleteFiles",
#     "shareFiles",
#   ]
# }
