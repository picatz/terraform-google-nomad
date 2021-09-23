variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "http_port" {
  type    = number
  default = 3100
}

variable "grpc_port" {
  type    = number
  default = 9095
}

variable "log_level" {
  type    = string
  default = "debug"
}

variable "storage" {
  type    = object({
    schema_config = object({
      configs = list(object({
        from         = string
        store        = string
        object_store = string
        schema       = string
        index        = object({
          prefix = string
          period = string
        })
      }))
    })
  })

  default = {
    schema_config = {
      configs = [
        {
          from         = "2020-05-15"
          store        = "boltdb"
          object_store = "filesystem"
          schema       = "v11"
          index        = {
            prefix = "index_"
            period = "168h"
          }
        }
      ]
    }
  }
}

// TODO: investigate if Nomad can support the optional() type function thing like Terraform provides.
variable "ingester" {
  type    = object({
    ingester = object({
      chunk_idle_period   = string
      chunk_retain_period = string
      lifecycler          = object({
        address     = string
        final_sleep = string
        ring        = object({
          kvstore = object({
            store = string
          })
          replication_factor = number
        })
      })
    })
  })

  default = {
    ingester = {
      chunk_idle_period   = "5m"
      chunk_retain_period = "30s"
      lifecycler = {
        address     = "127.0.0.1"
        final_sleep = "0s"
        ring        = {
          replication_factor = 1
          kvstore            = {
            store = "inmemory"
          }
        }
      }
    }
  }
}

variable "storage_config" {
  type = object({
    storage_config = object({
      boltdb = object({
        directory = string
      })

      filesystem = object({
        directory = string
      })
    })
  })

  default = {
    storage_config = {
      boltdb = {
        directory = "/tmp/loki/index"
      }

      filesystem = {
        directory = "/tmp/loki/chunks"
      }
    }
  }
}

variable "limits_config" {
  type = object({
    limits_config = object({
      enforce_metric_name        = bool
      reject_old_samples         = bool
      reject_old_samples_max_age = string
    })
  })

  default = {
    limits_config = {
      enforce_metric_name        = false
      reject_old_samples         = true
      reject_old_samples_max_age = "168h"
    }
  }
}

job "logs" {
    datacenters = var.datacenters

    group "loki" {
        network {
            mode = "bridge"
        }

        service {
            name = "loki-http"
            port = var.http_port

            connect {
                sidecar_service {}
            }
        }

        service {
            name = "loki-grpc"
            port = var.grpc_port

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
  http_listen_port: ${var.http_port}
  grpc_listen_port: ${var.grpc_port}

${yamlencode(var.ingester)}

${yamlencode(var.storage)}

${yamlencode(var.storage_config)}

${yamlencode(var.limits_config)}

EOH
            }

            driver = "docker"

            config {
                image = "grafana/loki:latest"

                args = [
                    "--log.level=${var.log_level}",
                    "--config.file=/etc/loki/local-config.yaml",
                ]

                volumes = [
                    "local/loki-config.yaml:/etc/loki/local-config.yaml"
                ]
            }
        }
    }
}
