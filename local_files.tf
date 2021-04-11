resource "local_file" "nomad_ca_file" {
  content         = tls_self_signed_cert.nomad-ca.cert_pem
  filename        = "nomad-ca.pem"
  file_permission = "0600"
}

resource "local_file" "nomad_cli_cert" {
  content         = tls_locally_signed_cert.nomad-cli.cert_pem
  filename        = "nomad-cli-cert.pem"
  file_permission = "0600"
}

resource "local_file" "nomad_cli_key" {
  content         = tls_private_key.nomad-cli.private_key_pem
  filename        = "nomad-cli-key.pem"
  file_permission = "0600"
}

resource "local_file" "consul_ca_file" {
  content         = tls_self_signed_cert.consul-ca.cert_pem
  filename        = "consul-ca.pem"
  file_permission = "0600"
}

resource "local_file" "consul_cli_cert" {
  content         = tls_locally_signed_cert.consul-cli.cert_pem
  filename        = "consul-cli-cert.pem"
  file_permission = "0600"
}

resource "local_file" "consul_cli_key" {
  content         = tls_private_key.consul-cli.private_key_pem
  filename        = "consul-cli-key.pem"
  file_permission = "0600"
}

