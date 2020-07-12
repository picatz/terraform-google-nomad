resource "google_compute_firewall" "open_port" {
  name    = var.name
  network = var.network

  allow {
    protocol = var.protocol
    ports    = ["${var.port}"]
  }

  source_tags = var.source_tags
}
