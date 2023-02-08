
resource "tls_private_key" "nomad-client" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "nomad-client" {
  private_key_pem = tls_private_key.nomad-client.private_key_pem

  ip_addresses = [
    "127.0.0.1",
  ]

  dns_names = [
    "localhost",
    "client.global.nomad",
  ]

  subject {
    common_name  = "client.global.nomad"
    organization = var.tls_organization
  }
}

resource "tls_locally_signed_cert" "nomad-client" {
  cert_request_pem = tls_cert_request.nomad-client.cert_request_pem

  ca_private_key_pem = tls_private_key.nomad-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad-ca.cert_pem

  validity_period_hours = var.tls_validity_period_hours

  allowed_uses = [
    "client_auth",
  ]
}