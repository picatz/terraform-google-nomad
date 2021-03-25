datacenter = "dc1"
bind_addr = "0.0.0.0"
data_dir = "/consul/data"
primary_datacenter = "dc1"

advertise_addr = "{PRIVATE-IPV4}"
advertise_addr_wan = "{PRIVATE-IPV4}"

addresses {
  https = "0.0.0.0"
}

ports {
  dns   = 8600
  http  = 8500
  https = 8501
  grpc  = 8502
}

log_level = "DEBUG"

disable_remote_exec = true
disable_update_check = true
leave_on_terminate = true

retry_join = ["provider=gce project_name={PROJECT-NAME} tag_value=server"]

server = false

connect {
  enabled = true
}

acl {
  enabled        = {ACLs-ENABLED}
  default_policy = "{ACLs-DEFAULT-POLICY}"
}

verify_outgoing         = true
verify_incoming         = true
verify_server_hostname  = true

ca_file = "/consul/config/consul-ca.pem"
cert_file = "/consul/config/client.pem"
key_file = "/consul/config/client-key.pem"

encrypt = "{GOSSIP-KEY}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true
