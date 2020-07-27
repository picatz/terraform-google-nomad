datacenter = "dc1"
log_level = "DEBUG"
data_dir = "/tmp/nomad-agent"

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
  }

  meta {
    "runtime" = "docker"
  }
}

acl {
  enabled = {ACLs-ENABLED}
}

tls {
  http = true
  rpc  = true

  ca_file   = "/nomad/config/nomad-ca.pem"
  cert_file = "/nomad/config/client.pem"
  key_file  = "/nomad/config/client-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}

consul {
  ssl        = true
  verify_ssl = true
  address    = "127.0.0.1:8501"
  ca_file    = "/consul/config/consul-ca.pem"
  cert_file  = "/consul/config/client.pem"
  key_file   = "/consul/config/client-key.pem"
}
