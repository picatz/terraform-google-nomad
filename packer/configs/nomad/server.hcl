datacenter = "dc1"
bind_addr = "0.0.0.0"
data_dir = "/tmp/nomad-agent"

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

  ca_file   = "/nomad/config/nomad-ca.pem"
  cert_file = "/nomad/config/server.pem"
  key_file  = "/nomad/config/server-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}

consul {
  ssl        = true
  verify_ssl = true
  address    = "127.0.0.1:8501"
  ca_file    = "/consul/config/consul-ca.pem"
  cert_file  = "/consul/config/server.pem"
  key_file   = "/consul/config/server-key.pem"
  token      = "{CONSUL-TOKEN}"
}

telemetry {
  collection_interval        = "5s"
  disable_hostname           = true
  prometheus_metrics         = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
} 