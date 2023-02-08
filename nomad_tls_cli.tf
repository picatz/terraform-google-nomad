resource "tls_private_key" "nomad-cli" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "nomad-cli" {
  private_key_pem = tls_private_key.nomad-cli.private_key_pem

  // ip_addresses = [
  //   module.load_balancer.external_ip,
  //   "127.0.0.1",
  // ]

  subject {
    common_name  = "cli.global.nomad"
    organization = var.tls_organization
  }
}

resource "tls_locally_signed_cert" "nomad-cli" {
  cert_request_pem = tls_cert_request.nomad-cli.cert_request_pem

  ca_private_key_pem = tls_private_key.nomad-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad-ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "client_auth",
  ]
}
