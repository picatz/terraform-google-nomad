// docker run -d --name timescaledb -p 5432:5432 -e POSTGRES_PASSWORD=password timescale/timescaledb:latest-pg12
variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

job "timescaledb" {
    datacenters = var.datacenters

    group "timescaledb" {
        network {
            mode = "bridge"
        }

        service {
            name = "timescaledb"
            port = "5432"

            connect {
                sidecar_service {}
            }
        }

        ephemeral_disk {
            size    = 10240 # 10 GB
            migrate = true
            sticky  = true
        }

        task "timescaledb" {
            driver = "docker"

            # Note, configuration is found at:
            # /var/lib/postgresql/data/postgresql.conf

            env {
                POSTGRES_PASSWORD = "password"
            }

            config {
                image = "timescale/timescaledb:latest-pg12"
            }
        }
    }

    group "promscale" {
        network {
            mode = "bridge"
        }

        service {
            name = "promscale"
            port = "9201"

            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "timescaledb"
                            local_bind_port  = 5432
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

        task "promscale" {
            driver = "docker"

            env {
                POSTGRES_PASSWORD = "password"

                // PROMSCALE_WEB_TELEMETRY_PATH = "/metrics"
                // PROMSCALE_DB_CONNECT_RETRIES = 10
                // PROMSCALE_LOG_LEVEL = "info"
                // PROMSCALE_DB_NAME = "timescale"
                // PROMSCALE_DB_PORT = 5432
                // PROMSCALE_DB_SSL_MODE = "allow"
                // PROMSCALE_DB_HOST="127.0.0.1"
                // PROMSCALE_DB_URI = ""
            }

            config {
                image = "timescale/promscale:latest"

                args = [
                    "-db-uri", "postgres://postgres:$POSTGRES_PASSWORD@127.0.0.1:5432/postgres?sslmode=allow",
                ]
            }
        }
    }
}
