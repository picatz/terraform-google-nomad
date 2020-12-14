variable "consul_metrics_token" {
  type        = string
  description = "The consul token to use for metrics service discovery"
}

variable "load_balancer_ip" {
  type        = string
  description = "The consul load balancer IP from prometheus service discovery"
}


job "metrics" {
    datacenters = ["dc1"]

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

        volume "prometheus" {
            type      = "host"
            source    = "prometheus"
            read_only = false
        }

        task "prometheus" {
            template {
                change_mode = "noop"
                destination = "local/prometheus.yml"

                data = <<EOH
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
      ca_file: /gcs/nomad-ca.pem
      cert_file: /gcs/nomad-client.pem
      key_file: /gcs/nomad-client-key.pem
      insecure_skip_verify: false
    params:
      format: ['prometheus']

    consul_sd_configs:
    - server: '${var.load_balancer_ip}:8501'
      token: ${var.consul_metrics_token}
      datacenter: 'dc1'
      scheme: 'https'
      tls_config:
        ca_file: '/gcs/consul-ca.pem'
        cert_file: '/gcs/consul-client.pem'
        key_file: '/gcs/consul-client-key.pem'
        insecure_skip_verify: false
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep
EOH
            }

            driver = "docker"
            user   = "root" # required from gcsfuse file permissions

            volume_mount {
                volume      = "prometheus"
                destination = "/gcs" # note: /prometheus is used for mmap files, don't mount there
                read_only   = false
            }

            config {
                image = "prom/prometheus:latest"

                volumes = [
                    "local/prometheus.yml:/etc/prometheus/prometheus.yml",
                ]
            }
        }
    }

    group "grafana" {
        network {
            mode ="bridge"
            port "grafana" {
                static = 3000
                to     = 3000
            }
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
                    }
                }
            }
        }

        ephemeral_disk {
            size    = 10240 # 10 GB
            migrate = true
            sticky  = true
        }

        volume "grafana" {
            type      = "host"
            source    = "grafana"
            read_only = false
        }

        task "grafana" {
            driver = "docker"
            user   = "root" # required from gcsfuse file permissions

            volume_mount {
                volume      = "grafana"
                destination = "/grafana"
                read_only   = false
            }

            config {
                image = "grafana/grafana:7.3.5"
            }
        }
    }
}
