resource "google_project_service" "compute_api" {
  project = var.project
  service = "compute.googleapis.com"
}