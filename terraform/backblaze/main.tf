locals {
  bucket_prefix = "velero-backups"
}

resource "b2_bucket" "backup_bucket" {
  bucket_name = "${local.bucket_prefix}-bucket"
  bucket_type = "allPrivate"

  # Glacier-like lifecycle for the bucket.
  dynamic "lifecycle_rules" {
    for_each = ["backups/", "restores/", "kopia/"]
    content {
      file_name_prefix = lifecycle_rules.value
      # After 15 days, hide files
      days_from_uploading_to_hiding = 15
      # After 16 days (1 day later), delete files
      days_from_hiding_to_deleting = 1
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
