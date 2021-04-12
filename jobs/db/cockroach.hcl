variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

job "cockroach" {
  datacenters = var.datacenters

  type = "service"

  update {
    max_parallel     = 1
    stagger          = "12s"
    healthy_deadline = "3m"
  }

  constraint {
    distinct_hosts = true
  }

  group "cockroach-1" {
    network {
      mode = "bridge"
      port "metrics" {}
    }

    service {
      name = "cockroach-metrics"
      port = "metrics"
      connect {
				sidecar_service {
					proxy {
						expose {
							path {
								path = "/_status/vars"
								protocol = "http"
								listener_port = "metrics"
								local_path_port = 8080
							}
						}
					}
				}
			}
    }

    service {
      name = "cockroach"
      port = "26258"

      connect {
        sidecar_service {}
      }
    }

    service {
      name = "cockroach-1"
      port = "26258"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "cockroach-2"
              local_bind_port  = 26259
            }
            upstreams {
              destination_name = "cockroach-3"
              local_bind_port  = 26260
            }
          }
        }
      }
    }

    ephemeral_disk {
      migrate = true
      sticky  = true
      size    = 5000 # 5GB
    }

    task "cockroach" {
      driver = "docker"
      config {
        image = "cockroachdb/cockroach:latest"
        args = [
          "start",
          "--insecure",
          "--advertise-addr=localhost:26258",
          "--listen-addr=localhost:26258",
          "--http-addr=0.0.0.0:8080",
          "--join=localhost:26258,localhost:26259,localhost:26260",
          "--logtostderr=INFO",
        ]
      }
    }
  }

  group "cockroach-2" {
    network {
      mode = "bridge"
      port "metrics" {}
    }

    service {
      name = "cockroach-metrics"
      port = "metrics"
      connect {
				sidecar_service {
					proxy {
						expose {
							path {
								path = "/_status/vars"
								protocol = "http"
								listener_port = "metrics"
								local_path_port = 8080
							}
						}
					}
				}
			}
    }

    service {
      name = "cockroach"
      port = "26259"

      connect {
        sidecar_service {}
      }
    }

    service {
      name = "cockroach-2"
      port = "26259"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "cockroach-1"
              local_bind_port  = 26258
            }
            upstreams {
              destination_name = "cockroach-3"
              local_bind_port  = 26260
            }
          }
        }
      }
    }

    ephemeral_disk {
      migrate = true
      sticky  = true
      size    = 5000 # 5GB
    }

    task "cockroach" {
      driver = "docker"
      config {
        image = "cockroachdb/cockroach:latest"
        args = [
          "start",
          "--insecure",
          "--advertise-addr=localhost:26259",
          "--http-addr=0.0.0.0:8080",
          "--listen-addr=localhost:26259",
          "--join=localhost:26258,localhost:26259,localhost:26260",
          "--logtostderr=INFO",
        ]
      }
    }
  }

  group "cockroach-3" {
    network {
      mode = "bridge"
      port "metrics" {}
    }

    service {
      name = "cockroach-metrics"
      port = "metrics"
      connect {
				sidecar_service {
					proxy {
						expose {
							path {
								path = "/_status/vars"
								protocol = "http"
								listener_port = "metrics"
								local_path_port = 8080
							}
						}
					}
				}
			}
    }

    service {
        name = "cockroach"
        port = "26260"

        connect {
          sidecar_service {}
        }
    }

    service {
      name = "cockroach-3"
      port = "26260"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "cockroach-1"
              local_bind_port  = 26258
            }
            upstreams {
              destination_name = "cockroach-2"
              local_bind_port  = 26259
            }
          }
        }
      }
    }

    ephemeral_disk {
      migrate = true
      sticky  = true
      size    = 5000 # 5GB
    }

    task "cockroach" {
      driver = "docker"
      config {
        image = "cockroachdb/cockroach:latest"
        args = [
          "start",
          "--insecure",
          "--advertise-addr=localhost:26260",
          "--http-addr=0.0.0.0:8080",
          "--listen-addr=localhost:26260",
          "--join=localhost:26258,localhost:26259,localhost:26260",
          "--logtostderr=INFO",
        ]
      }
    }
  }
}