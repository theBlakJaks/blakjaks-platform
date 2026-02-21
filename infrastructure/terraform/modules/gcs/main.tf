locals {
  buckets = {
    "blakjaks-user-documents"  = { versioning = false, public = false }
    "blakjaks-email-templates" = { versioning = false, public = false }
    "blakjaks-qr-codes"        = { versioning = false, public = false }
    "blakjaks-admin-uploads"   = { versioning = false, public = false }
    "blakjaks-backups"         = { versioning = true,  public = false }
    "blakjaks-user-avatars"    = { versioning = false, public = false }
    "blakjaks-hls-streams"     = { versioning = false, public = false }
  }
}

resource "google_storage_bucket" "buckets" {
  for_each                    = local.buckets
  name                        = each.key
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  versioning {
    enabled = each.value.versioning
  }
}

resource "google_storage_bucket_iam_member" "public_read" {
  for_each = { for k, v in local.buckets : k => v if v.public }
  bucket   = google_storage_bucket.buckets[each.key].name
  role     = "roles/storage.objectViewer"
  member   = "allUsers"
}
