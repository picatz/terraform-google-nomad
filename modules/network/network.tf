resource "google_compute_network" "default" {
  name = var.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  network = google_compute_network.default.name
  name    = var.name
  region  = var.region

  ip_cidr_range = var.cidr_range
}

resource "google_compute_firewall" "allow_icmp" {
  name    = "allow-icmp"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }
}

module "ssh" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "allow-all-ssh"
    port        = 22
    protocol    = "tcp"
}

module "nomad-http" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "nomad-http"
    port        = 4646
    protocol    = "tcp"
    source_tags = var.http_source_tags
}

module "nomad-rpc" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "nomad-rpc"
    port        = 4647
    protocol    = "tcp"
    source_tags = var.rpc_source_tags
}

module "nomad-wan-tcp" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "nomad-wan-tcp"
    port        = 4648
    protocol    = "tcp"
    source_tags = var.gossip_source_tags
}

module "nomad-wan-udp" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "nomad-wan-udp"
    port        = 4648
    protocol    = "udp"
    source_tags = var.gossip_source_tags
}

module "consul-http" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-http"
    port        = 8500
    protocol    = "tcp"
    source_tags = var.http_source_tags
}

module "consul-https" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-https"
    port        = 8501
    protocol    = "tcp"
    source_tags = var.http_source_tags
}

module "consul-grpc" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-grpc"
    port        = 8502
    protocol    = "tcp"
    source_tags = var.http_source_tags
}

module "consul-dns-tcp" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-dns-tcp"
    port        = 8600
    protocol    = "tcp"
    source_tags = var.dns_source_tags
}

module "consul-dns-udp" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-dns-udp"
    port        = 8600
    protocol    = "udp"
    source_tags = var.dns_source_tags
}

module "consul-rpc" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-rpc"
    port        = 8300
    protocol    = "tcp"
    source_tags = var.rpc_source_tags
}

module "consul-serf-wan-tcp" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-serf-wan-tcp"
    port        = 8301
    protocol    = "tcp"
    source_tags = var.gossip_source_tags
}

module "consul-serf-wan-udp" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-serf-wan-udp"
    port        = 8302
    protocol    = "udp"
    source_tags = var.gossip_source_tags
}

module "consul-serf-lan-tcp" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-serf-lan-tcp"
    port        = 8301
    protocol    = "tcp"
    source_tags = var.gossip_source_tags
}

module "consul-serf-lan-udp" {
    source      = "../open-port"
    network     = google_compute_network.default.name
    name        = "consul-serf-lan-udp"
    port        = 8301
    protocol    = "udp"
    source_tags = var.gossip_source_tags
}

resource "google_compute_firewall" "allow-all-internal-dyanmic-ports" {
  name        = "allow-all-internal-dynamic-ports"
  network     = google_compute_network.default.name
  source_tags = var.server_client_source_tags

  # https://www.nomadproject.io/docs/job-specification/network#dynamic-ports (20000-32000)
  # https://www.consul.io/docs/install/ports#ports-table                     (21000-21255)
  allow {
    protocol = "tcp"
    ports    = ["20000-32000"]
  }
}