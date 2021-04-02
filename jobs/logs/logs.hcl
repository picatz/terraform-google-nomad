variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "image" {
  type    = string
  default = "grafana/loki:latest"
}

job "logs" {
    datacenters = var.datacenters

    group "loki" {
        network {
            mode = "bridge"
        }

        service {
            name = "loki-http"
            port = "3100"

            connect {
                sidecar_service {}
            }
        }

        service {
            name = "loki-grpc"
            port = "9095"

            connect {
                sidecar_service {}
            }
        }

        ephemeral_disk {
            size    = 10240 # 10 GB
            migrate = true
            sticky  = true
        }

        task "loki" {
            template {
                change_mode = "restart"
                destination = "local/loki-config.yaml"
                data        = <<EOH
---
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9095

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
  - from: 2020-05-15
    store: boltdb
    object_store: filesystem
    schema: v11
    index:
      prefix: index_
      period: 168h

storage_config:
  boltdb:
    directory: /tmp/loki/index

  filesystem:
    directory: /tmp/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
EOH
            }

            driver = "docker"

            config {
                image = var.image

                args = [
                    "--log.level=debug",
                    "--config.file=/etc/loki/local-config.yaml",
                ]

                volumes = [
                    "local/loki-config.yaml:/etc/loki/local-config.yaml"
                ]
            }
        }
    }
}
