resource "google_storage_bucket" "nomad_client" {
  name          = format("%s-nomad-client", var.project)
  location      = var.bucket_location
  force_destroy = true
}

resource "google_storage_bucket_object" "shared_example" {
  name    = "example.txt"
  content = "hello world"
  bucket  = google_storage_bucket.nomad_client.name
}

resource "google_storage_bucket" "nomad_client_prometheus" {
  name          = format("%s-nomad-client-prometheus", var.project)
  location      = var.bucket_location
  force_destroy = true
}

resource "google_storage_bucket_object" "prometheus_example" {
  name    = "example.txt"
  content = "hello world"
  bucket  = google_storage_bucket.nomad_client_prometheus.name
}

resource "google_storage_bucket" "nomad_client_grafana" {
  name          = format("%s-nomad-client-grafana", var.project)
  location      = var.bucket_location
  force_destroy = true
}

resource "google_storage_bucket_object" "grafana_example" {
  name    = "example.txt"
  content = "hello world"
  bucket  = google_storage_bucket.nomad_client_grafana.name
}

data "template_file" "client_prometheus_config" {
  template = file("${path.module}/templates/prometheus.yml")

  vars = {
    consul_master_token = local.consul_master_token
  }
}

resource "google_storage_bucket_object" "prometheus_config" {
  name    = "prometheus.yml"
  content = data.template_file.client_prometheus_config.rendered
  bucket  = google_storage_bucket.nomad_client_prometheus.name
}

# nomad mtls certificates for prometheus scraping

resource "google_storage_bucket_object" "prometheus_config_nomad_ca_file" {
  name    = "nomad-ca.pem"
  content = tls_self_signed_cert.nomad-ca.cert_pem
  bucket  = google_storage_bucket.nomad_client_prometheus.name
}

resource "google_storage_bucket_object" "prometheus_config_nomad_cert_file" {
  name    = "nomad-client.pem"
  content = tls_locally_signed_cert.nomad-cli.cert_pem
  bucket  = google_storage_bucket.nomad_client_prometheus.name
}

resource "google_storage_bucket_object" "prometheus_config_nomad_key_file" {
  name    = "nomad-client-key.pem"
  content = tls_private_key.nomad-cli.private_key_pem
  bucket  = google_storage_bucket.nomad_client_prometheus.name
}

# consul mtls certificates for prometheus service discovery

resource "google_storage_bucket_object" "prometheus_config_consul_ca_file" {
  name    = "consul-ca.pem"
  content = tls_self_signed_cert.consul-ca.cert_pem
  bucket  = google_storage_bucket.nomad_client_prometheus.name
}

resource "google_storage_bucket_object" "prometheus_config_consul_cert_file" {
  name    = "consul-client.pem"
  content = tls_locally_signed_cert.consul-cli.cert_pem
  bucket  = google_storage_bucket.nomad_client_prometheus.name
}

resource "google_storage_bucket_object" "prometheus_config_consul_key_file" {
  name    = "consul-client-key.pem"
  content = tls_private_key.consul-cli.private_key_pem
  bucket  = google_storage_bucket.nomad_client_prometheus.name
}


