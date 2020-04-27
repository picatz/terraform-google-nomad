resource "local_file" "ca_file" {
  content         = tls_self_signed_cert.nomad-ca.cert_pem
  filename        = "nomad-ca.pem"
  file_permission = "0600"
}

resource "local_file" "cli_cert" {
  content         = tls_locally_signed_cert.nomad-cli.cert_pem
  filename        = "nomad-cli-cert.pem"
  file_permission = "0600"
}

resource "local_file" "cli_key" {
  content         = tls_private_key.nomad-cli.private_key_pem
  filename        = "nomad-cli-key.pem"
  file_permission = "0600"
}