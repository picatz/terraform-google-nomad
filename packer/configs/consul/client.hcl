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
  grpc      = 8502
  grpc_tls  = 8503
}

log_level = "DEBUG"

disable_remote_exec = true
disable_update_check = true
leave_on_terminate = true

retry_join = ["provider=gce project_name={PROJECT-NAME} tag_value=server"]

server = false

acl {
  enabled        = {ACLs-ENABLED}
  default_policy = "{ACLs-DEFAULT-POLICY}"
}

tls {
  defaults {
    ca_file = "/etc/consul.d/consul-ca.pem"
    cert_file = "/etc/consul.d/client.pem"
    key_file = "/etc/consul.d/client-key.pem"

    verify_incoming = true
    verify_outgoing = true
  }

  internal_rpc {
    verify_server_hostname = true
  }
}

encrypt = "{GOSSIP-KEY}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true

telemetry {
  prometheus_retention_time  = "24h"
  disable_hostname           = true
}
