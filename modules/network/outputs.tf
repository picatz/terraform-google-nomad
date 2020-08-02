output "name" {
  value = var.name
}

output "subnetwork" {
  value = google_compute_subnetwork.default.name
}
