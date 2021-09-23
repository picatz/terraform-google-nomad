variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "traefik_log_level" {
  type    = string
  default = "DEBUG"
}

variable "consul_services" {
  type = list(object({
    name = string
    port = number
  }))
  default = [
      {
          name    = "grafana"
          port    = 3000
      }
  ]
}

// TODO: consider option to optionally enable/disable the dashboard and metrics listeners

locals {
    dynamic_entry_points = [for i, service in var.consul_services : format("    [entryPoints.%s]\n      address = \"%d\"", service.name, service.port)]

    traefik_toml = <<EOT
[entryPoints]
${join("\n", local.dynamic_entry_points)}
    [entryPoints.traefik]
      address = ":8081"
    [entryPoints.metrics]
      address = ":8082"

[metrics]
  [metrics.prometheus]
    addEntryPointsLabels = true

[log]
    level = "${var.traefik_log_level}"
    format = "json"

[accessLog]
    format = "json"

[api]
    dashboard = true
    insecure  = true

[providers]
  [providers.file]
    directory = "/local/traefik"
    EOT

    dynamic_routers = [for i, service in var.consul_services : format("  [tcp.routers.%s]\n    entryPoints = [%q]\n    rule = %q\n    service = %q", service.name, service.name, "HostSNI(`*`)", service.port)]

    dynamic_services = [for i, service in var.consul_services : format("  [tcp.services.%s.loadBalancer]\n    [[tcp.services.%s.loadBalancer.servers]]\n      address = \"localhost:%d\"", service.name, service.name, service.port + 1)]

    conf = <<EOT
[tcp.routers]
${join("\n", local.dynamic_routers)}

[tcp.services]
${join("\n", local.dynamic_services)}
    EOT
}

job "ingress" {
    datacenters = var.datacenters
    type = "system"

    group "traefik" {
        count = 1

        network {
            mode = "bridge"

            dynamic "port" {
              for_each = var.consul_services
              iterator = service
              labels = [service.value.name]
              content {
                static = service.value.port
                to     = service.value.port
              }
            }

            port "dashboard" {
                static = 8081
                to     = 8081
            }

            port "metrics" {
                static = 8082
                to     = 8082
            }
        }

        dynamic "service" {
            for_each = var.consul_services
            iterator = service
            content {
              name = "traefik-${service.value.name}"
              port  = service.value.name

              connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = service.value.name
                            local_bind_port  = service.value.port + 1
                        }
                    }
                }
              }
            }
        }

        task "traefik" {
            template {
                change_mode = "restart"
                destination = "local/traefik.toml"
                data        = local.traefik_toml
            }

            template {
                change_mode = "restart"
                destination = "local/traefik/conf.toml"
                data        = local.conf
            }

            driver = "docker"

            config {
                image = "traefik:latest"

                volumes = [
                    "local/traefik.toml:/etc/traefik/traefik.toml"
                ]
            }
        }
    }
}