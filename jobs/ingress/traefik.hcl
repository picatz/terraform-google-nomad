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
            port "http" {
                static = 8080
                to     = 8080
            }
            port "dashboard" {
                static = 8081
                to     = 8081
            }
        }

        service {
            name = "traefik"
            port = "8080"

            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "grafana"
                            local_bind_port  = 3000
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
    [entryPoints.http]
    address = ":8080"
    [entryPoints.http.http.redirections]
      [entryPoints.http.http.redirections.entryPoint]
        to = ":3000"
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
