resource "google_compute_router" "nomad" {
  name    = format("%s-router", var.name)
  region  = var.region
  network = google_compute_network.nomad.name
  bgp {
    asn = var.router_asn
  }
}

resource "google_compute_router_nat" "nomad" {
  name                               = var.name
  region                             = google_compute_router.nomad.region
  router                             = google_compute_router.nomad.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}