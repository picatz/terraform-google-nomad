variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "consul_acl_token" {
  type    = string
}

variable "consul_lb_ip" {
  type    = string
}

variable "nomad_ca" {
  type    = string
  default = "nomad-ca.pem"
}

variable "nomad_cli" {
  type    = string
  default = "nomad-cli-cert.pem"
}

variable "nomad_cli_key" {
  type    = string
  default = "nomad-cli-key.pem"
}

variable "consul_ca" {
  type    = string
  default = "consul-ca.pem"
}

variable "consul_cli" {
  type    = string
  default = "consul-cli-cert.pem"
}

variable "consul_cli_key" {
  type    = string
  default = "consul-cli-key.pem"
}

variable "consul_targets" {
  type = list(string)
}

job "metrics" {
    datacenters = var.datacenters

    group "prometheus" {
        network {
            mode = "bridge"
        }

        service {
          name = "prometheus"
          port = "9090"

          connect {
            sidecar_service {}
          }
        }

        ephemeral_disk {
            size    = 10240 # 10 GB
            migrate = true
            sticky  = true
        }

        task "prometheus" {
            template {
                change_mode = "restart"
                destination = "local/prometheus.yml"
                data        = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 1m
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']
  - job_name: 'nomad_metrics'
    scrape_interval: 5s
    metrics_path: /v1/metrics
    scheme: https
    tls_config:
      ca_file: '/local/nomad-ca.pem'
      cert_file: '/local/nomad-cli-cert.pem'
      key_file: '/local/nomad-cli-key.pem'
      insecure_skip_verify: true
    params:
      format: ['prometheus']
    consul_sd_configs:
    - server: '${var.consul_lb_ip}:8501'
      token: '${var.consul_acl_token}'
      datacenter: 'dc1'
      scheme: 'https'
      tls_config:
        ca_file: '/local/consul-ca.pem'
        cert_file: '/local/consul-cli-cert.pem'
        key_file: '/local/consul-cli-key.pem'
        insecure_skip_verify: false
      services: ['nomad-client', 'nomad']
    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep
  - job_name: 'fuzz_metrics'
    consul_sd_configs:
    - server: '${var.consul_lb_ip}:8501'
      token: '${var.consul_acl_token}'
      datacenter: 'dc1'
      scheme: 'https'
      tls_config:
        ca_file: '/local/consul-ca.pem'
        cert_file: '/local/consul-cli-cert.pem'
        key_file: '/local/consul-cli-key.pem'
        insecure_skip_verify: false
      services: ['fuzz']
  - job_name: 'cockroach_metrics'
    metrics_path: /_status/vars
    consul_sd_configs:
    - server: '${var.consul_lb_ip}:8501'
      token: '${var.consul_acl_token}'
      datacenter: 'dc1'
      scheme: 'https'
      tls_config:
        ca_file: '/local/consul-ca.pem'
        cert_file: '/local/consul-cli-cert.pem'
        key_file: '/local/consul-cli-key.pem'
        insecure_skip_verify: false
      services: ['cockroach-metrics']
  - job_name: 'consul_metrics'
    scrape_interval: 5s
    metrics_path: /v1/agent/metrics
    scheme: https
    tls_config:
      ca_file: '/local/consul-ca.pem'
      cert_file: '/local/consul-cli-cert.pem'
      key_file: '/local/consul-cli-key.pem'
      insecure_skip_verify: true
    params:
      format: ['prometheus']
    authorization:
      credentials: '${var.consul_acl_token}'
    static_configs:
    - targets: ${jsonencode(var.consul_targets)}
EOH
            }

            template {
                change_mode = "noop"
                destination = "local/nomad-ca.pem"
                data        = file(var.nomad_ca)
            }

            template {
                change_mode = "noop"
                destination = "local/nomad-cli-cert.pem"
                data        = file(var.nomad_cli)
            }

            template {
                change_mode = "noop"
                destination = "local/nomad-cli-key.pem"
                data        = file(var.nomad_cli_key)
            }

            template {
                change_mode = "noop"
                destination = "local/consul-ca.pem"
                data        = file(var.consul_ca)
            }

            template {
                change_mode = "noop"
                destination = "local/consul-cli-cert.pem"
                data        = file(var.consul_cli)
            }

            template {
                change_mode = "noop"
                destination = "local/consul-cli-key.pem"
                data        = file(var.consul_cli_key)
            }

            driver = "docker"

            config {
                image = "prom/prometheus:latest"

                args = [
                    "--log.level=debug",
                    "--config.file=/etc/prometheus/prometheus.yml",
                ]

                volumes = [
                    "local/prometheus.yml:/etc/prometheus/prometheus.yml",
                ]
            }
        }
    }

    group "grafana" {
        network {
            mode ="bridge"
        }

        service {
            name = "grafana"
            port = "3000"

            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "prometheus"
                            local_bind_port  = 9090
                        }
                        upstreams {
                            destination_name = "loki-http"
                            local_bind_port  = 3100
                        }
                    }
                }
            }
        }

        ephemeral_disk {
            size    = 10240 # 10 GB
            migrate = true
            sticky  = true
        }

        task "grafana" {
            driver = "docker"

            config {
                image = "grafana/grafana:7.3.5"
            }
        }
    }
}
