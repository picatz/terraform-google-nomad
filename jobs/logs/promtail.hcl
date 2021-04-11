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
  http_listen_port: 9080
  grpc_listen_port: 9095

positions:
  filename: /nomad/positions.yaml
  ignore_invalid_yaml: true

client:
  url: http://127.0.0.1:3100/loki/api/v1/push

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