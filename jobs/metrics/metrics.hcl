variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "prometheus_config" {
  type    = string
  default = "prometheus.yml"
}

variable "nomad_ca" {
  type    = string
  default = "../../nomad-ca.pem"
}

variable "nomad_cli" {
  type    = string
  default = "../../nomad-cli-cert.pem"
}

variable "nomad_cli_key" {
  type    = string
  default = "../../nomad-cli-key.pem"
}

variable "consul_ca" {
  type    = string
  default = "../../consul-ca.pem"
}

variable "consul_cli" {
  type    = string
  default = "../../consul-cli-cert.pem"
}

variable "consul_cli_key" {
  type    = string
  default = "../../consul-cli-key.pem"
}

job "metrics" {
    datacenters = var.datacenters

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

        task "prometheus" {
            template {
                change_mode = "restart"
                destination = "local/prometheus.yml"
                data        = file(var.prometheus_config)
            }

            template {
                change_mode = "noop"
                destination = "local/nomad-ca.pem"
                data        = file(var.nomad_ca)
            }

            template {
                change_mode = "noop"
                destination = "local/nomad-cli-cert.pem"
                data        = file(var.nomad_cli)
            }

            template {
                change_mode = "noop"
                destination = "local/nomad-cli-key.pem"
                data        = file(var.nomad_cli_key)
            }

            template {
                change_mode = "noop"
                destination = "local/consul-ca.pem"
                data        = file(var.consul_ca)
            }

            template {
                change_mode = "noop"
                destination = "local/consul-cli-cert.pem"
                data        = file(var.consul_cli)
            }

            template {
                change_mode = "noop"
                destination = "local/consul-cli-key.pem"
                data        = file(var.consul_cli_key)
            }

            driver = "docker"

            config {
                image = "prom/prometheus:latest"

                args = [
                    "--log.level=debug",
                    "--config.file=/etc/prometheus/prometheus.yml",
                ]

                volumes = [
                    "local/prometheus.yml:/etc/prometheus/prometheus.yml",
                ]
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

        task "grafana" {
            driver = "docker"

            config {
                image = "grafana/grafana:7.3.5"
            }
        }
    }
}
