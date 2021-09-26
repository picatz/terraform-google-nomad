provider "grafana" {
    // GRAFANA_AUTH
    // GRAFANA_URL
}

resource "grafana_data_source" "prometheus" {
  type       = "prometheus"
  name       = "Prometheus"
  url        = "http://127.0.0.1:9090"
  is_default = true
}

resource "grafana_data_source" "loki" {
  type = "loki"
  name = "Loki"
  url  = "http://127.0.0.1:3100"
}

resource "grafana_dashboard" "nomad_clients" {
  config_json = file("nomad-clients.json")
}