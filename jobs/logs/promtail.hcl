
variable "http_port" {
  type    = number
  default = 9080
}

variable "grpc_port" {
  type    = number
  default = 9095
}

variable "positions_filename" {
  type    = string
  default = "/nomad/positions.yaml"
}

variable "positions_ignore_invalid_yaml" {
  type    = bool
  default = true
}

variable "client_url" {
  type    = string
  default = "http://127.0.0.1:3100/loki/api/v1/push"
}

job "promtail" {
  datacenters = ["dc1"]
  type = "system"

  group "promtail" {
    count = 1

    network {
        mode = "bridge"
    }

    service {
        name = "promtail-http"
        port = "9080"

        connect {
            sidecar_service {
                proxy {
                    upstreams {
                        destination_name = "loki-http"
                        local_bind_port  = 3100
                    }
                }
            }
        }
    }

    service {
        name = "promtail-grpc"
        port = "9095"

        connect {
            sidecar_service {}
        }
    }

    volume "nomad" {
        type      = "host"
        source    = "nomad"
        read_only = false
    }

    task "promtail" {
      driver = "docker"

      volume_mount {
        volume      = "nomad"
        destination = "/nomad"
        read_only   = false
      }

      env {
        HOSTNAME = "${attr.unique.hostname}"
      }

      template {
        data        = <<EOH
server:
  http_listen_port: ${var.http_port}
  grpc_listen_port: ${var.grpc_port}

positions:
  filename: ${var.positions_filename}
  ignore_invalid_yaml: ${var.positions_ignore_invalid_yaml}

client:
  url: ${var.client_url}

scrape_configs:
 - job_name: system
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: nomad
      host: {{ env "HOSTNAME" }}
      __path__: /nomad/alloc/*/alloc/logs/*std*.{?,??} # https://github.com/bmatcuk/doublestar
EOH
        destination = "/local/promtail.yml"
      }

      config {
        image = "grafana/promtail:latest"
        args = [
          "-config.file=/local/promtail.yml",
        ]
      }
    }
  }
}