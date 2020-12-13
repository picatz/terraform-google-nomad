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

        task "web" {
            driver = "docker"
            config {
                image = "prom/prometheus:latest"
            }
        }
    }


    group "grafana" {
        network {
            mode ="bridge"
            port "http" {
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

        task "dashboard" {
            driver = "docker"
            config {
                image = "grafana/grafana:7.3.5"
            }
        }
    }
}
