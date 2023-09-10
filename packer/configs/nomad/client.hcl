datacenter = "dc1"
log_level = "DEBUG"
data_dir = "/etc/nomad.d/data"

client {
  enabled = true

  server_join {
    retry_join     = ["provider=gce project_name={PROJECT-NAME} tag_value=server"]
    retry_max      = 12
    retry_interval = "10s"
  }

  options {
    "driver.docker.enable" = "1"
    "driver.whitelist"     = "docker"
    "user.blacklist"       = "root,ubuntu"
    // "docker.auth.config"   = "/etc/nomad.d/docker_auth_config.json"
    // "docker.auth.helper"   = "gcr"
  }

  meta {
    "runtime" = "docker"
  }

  host_volume "nomad" {
    path = "/etc/nomad.d/data"
  }
}

acl {
  enabled = {ACLs-ENABLED}
}

tls {
  http = true
  rpc  = true

  ca_file   = "/etc/nomad.d/nomad-ca.pem"
  cert_file = "/etc/nomad.d/client.pem"
  key_file  = "/etc/nomad.d/client-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}

consul {
  ssl        = true
  verify_ssl = true
  address    = "127.0.0.1:8501"
  ca_file    = "/etc/consul.d/consul-ca.pem"
  cert_file  = "/etc/consul.d/client.pem"
  key_file   = "/etc/consul.d/client-key.pem"
  token      = "{CONSUL-TOKEN}"
}

telemetry {
  collection_interval        = "5s"
  disable_hostname           = true
  prometheus_metrics         = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
}

plugin "docker" {
  config {
    endpoint = "unix:///var/run/docker.sock"

    allow_runtimes = ["runc","runsc"]

    allow_privileged = false

    // auth {
    //   config = "/etc/nomad.d/docker_auth_config.json"
    //   helper = "gcr"
    // }

    extra_labels = ["job_name", "job_id", "task_group_name", "task_name", "namespace", "node_name", "node_id"]

    gc {
      image       = true
      image_delay = "3m"
      container   = true

      dangling_containers {
        enabled        = true
        dry_run        = false
        period         = "5m"
        creation_grace = "5m"
      }
    }
  }
}