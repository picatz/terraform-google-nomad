variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

job "ingress" {
    datacenters = var.datacenters
    type = "system"

    group "traefik" {
        count = 1

        network {
            mode = "bridge"
            port "grafana" {
                static = 3000
                to     = 3000
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

        service {
            name = "traefik-grafana"
            port = "grafana"

            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "grafana"
                            local_bind_port  = 3001
                        }
                    }
                }
            }
        }

        task "traefik" {
            template {
                change_mode = "restart"
                destination = "local/traefik.toml"
                data        = <<EOH
[entryPoints]
    [entryPoints.grafana]
      address = ":3000"
    [entryPoints.traefik]
      address = ":8081"
    [entryPoints.metrics]
      address = ":8082"

[metrics]
  [metrics.prometheus]
    addEntryPointsLabels = true

[log]
    level = "DEBUG"
    format = "json"

[accessLog]
    format = "json"

[api]
    dashboard = true
    insecure  = true

[providers]
  [providers.file]
    directory = "/local/traefik"
EOH
            }

            template {
                change_mode = "restart"
                destination = "local/traefik/conf.toml"
                data        = <<EOH
[tcp.routers]
  [tcp.routers.grafana]
    entryPoints = ["grafana"]
    rule = "HostSNI(`*`)"
    service = "grafana"

[tcp.services]
  [tcp.services.grafana.loadBalancer]
    [[tcp.services.grafana.loadBalancer.servers]]
      address = "localhost:3001"
EOH
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
