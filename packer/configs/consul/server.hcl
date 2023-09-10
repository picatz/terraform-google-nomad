datacenter = "dc1"
bind_addr = "0.0.0.0"
data_dir = "/etc/consul.d/data"
primary_datacenter = "dc1"

advertise_addr = "{PRIVATE-IPV4}"
advertise_addr_wan = "{PRIVATE-IPV4}"

addresses {
  https = "0.0.0.0"
}

ports {
  dns       = 8600
  http      = 8500
  https     = 8501
}

log_level = "DEBUG"

server = true
ui = true
disable_remote_exec = true
disable_update_check = true
bootstrap_expect = {NUMBER-OF-SERVERS}
leave_on_terminate = true

retry_join = ["provider=gce project_name={PROJECT-NAME} tag_value=server"]

autopilot {
  cleanup_dead_servers = true
  last_contact_threshold = "200ms"
  max_trailing_logs = 250
  server_stabilization_time = "10s"
}

connect {
  enabled = true
}

acl {
  enabled                  = {ACLs-ENABLED}
  default_policy           = "{ACLs-DEFAULT-POLICY}"
  enable_token_persistence = true
  tokens {
    master = "{CONSUL-TOKEN}"
  }
}

encrypt = "{GOSSIP-KEY}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true

tls {
  defaults {
    ca_file = "/etc/consul.d/consul-ca.pem"
    cert_file = "/etc/consul.d/server.pem"
    key_file = "/etc/consul.d/server-key.pem"

    verify_incoming = true
    verify_outgoing = true
  }

  internal_rpc {
    verify_server_hostname = true
  }
}

auto_encrypt {
  allow_tls = true
}

telemetry {
  prometheus_retention_time  = "24h"
  disable_hostname           = true
}
