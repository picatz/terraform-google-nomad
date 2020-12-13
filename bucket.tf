resource "google_storage_bucket" "nomad_client" {
  name          = format("%s-nomad-client-bucket", var.project)
  location      = var.bucket_location
  force_destroy = true
}