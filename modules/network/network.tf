resource "google_compute_network" "nomad" {
  name = var.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "nomad" {
  network = google_compute_network.nomad.name
  name    = var.name
  region  = var.region

  ip_cidr_range = var.cidr_range
}

resource "google_compute_firewall" "allow_icmp" {
  name    = "allow-icmp"
  network = google_compute_network.nomad.name

  allow {
    protocol = "icmp"
  }
}

module "nomad-ssh" {
    source   = "../open-port"
    network  = google_compute_network.nomad.name
    name     = "nomad-ssh"
    port     = 22
    protocol = "tcp"
}

module "nomad-http" {
    source      = "../open-port"
    network     = google_compute_network.nomad.name
    name        = "nomad-http"
    port        = 4646
    protocol    = "tcp"
    source_tags = var.source_tags
}

module "nomad-rpc" {
    source      = "../open-port"
    network     = google_compute_network.nomad.name
    name        = "nomad-rpc"
    port        = 4647
    protocol    = "tcp"
    source_tags = var.source_tags
}

module "nomad-wan-tcp" {
    source      = "../open-port"
    network     = google_compute_network.nomad.name
    name        = "nomad-wan-tcp"
    port        = 4648
    protocol    = "tcp"
    source_tags = var.source_tags
}

module "nomad-wan-udp" {
    source      = "../open-port"
    network     = google_compute_network.nomad.name
    name        = "nomad-wan-udp"
    port        = 4648
    protocol    = "udp"
    source_tags = var.source_tags
}
