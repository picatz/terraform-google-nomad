datacenter = "dc1"
bind_addr = "0.0.0.0"
data_dir = "/tmp/nomad-agent"

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