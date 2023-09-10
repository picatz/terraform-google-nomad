datacenter = "dc1"
bind_addr = "0.0.0.0"
data_dir = "/etc/nomad.d/data"

leave_on_terminate = true

advertise {
  http = "{PRIVATE-IPV4}"
  rpc  = "{PRIVATE-IPV4}"
  serf = "{PRIVATE-IPV4}"
}

log_level = "DEBUG"

server {
  enabled = true

  server_join {
    retry_join     = ["provider=gce project_name={PROJECT-NAME} tag_value=server"]
    retry_max      = 12
    retry_interval = "10s"
  }

  bootstrap_expect = {NUMBER-OF-SERVERS}

  encrypt = "{GOSSIP-KEY}"
}

acl {
  enabled = {ACLs-ENABLED}
}

tls {
  http = true
  rpc  = true

  ca_file   = "/etc/nomad.d/nomad-ca.pem"
  cert_file = "/etc/nomad.d/server.pem"
  key_file  = "/etc/nomad.d/server-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}

consul {
  ssl        = true
  verify_ssl = true
  address    = "127.0.0.1:8501"
  ca_file    = "/etc/consul.d/consul-ca.pem"
  cert_file  = "/etc/consul.d/server.pem"
  key_file   = "/etc/consul.d/server-key.pem"
  token      = "{CONSUL-TOKEN}"
}

telemetry {
  collection_interval        = "5s"
  disable_hostname           = true
  prometheus_metrics         = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
} 