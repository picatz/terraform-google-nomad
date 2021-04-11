resource "google_storage_bucket" "containers" {
  name          = format("%s-containers", var.project)
  location      = var.bucket_location
  force_destroy = true
}