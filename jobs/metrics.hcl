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

        volume "gcs" {
            type      = "host"
            source    = "gcs"
            read_only = false
        }

        task "prometheus" {
            driver = "docker"
            user   = "root" # required from gcsfuse file permissions

            volume_mount {
                volume      = "gcs"
                destination = "/gcs"
                read_only   = false
            }

            config {
                image = "prom/prometheus:latest"
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

        volume "gcs" {
            type      = "host"
            source    = "gcs"
            read_only = false
        }

        task "grafana" {
            driver = "docker"
            user   = "root" # required from gcsfuse file permissions

            volume_mount {
                volume      = "gcs"
                destination = "/gcs"
                read_only   = false
            }

            config {
                image = "grafana/grafana:7.3.5"
            }
        }
    }
}
