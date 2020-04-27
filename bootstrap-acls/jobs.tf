provider "nomad" {
  address   = format("https://%s:4646", module.load_balancer.external_ip)
  ca_file   = local_file.ca_file.filename
  cert_file = local_file.cli_cert.filename
  key_file  = local_file.cli_key.filename
  secret_id = var.nomad_token
}
