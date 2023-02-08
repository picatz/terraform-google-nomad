resource "tls_private_key" "nomad-server" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "nomad-server" {
  private_key_pem = tls_private_key.nomad-server.private_key_pem

  ip_addresses = [
    module.load_balancer.external_ip,
    "127.0.0.1",
  ]

  dns_names = var.dns_enabled ? [
    "localhost",
    "server.global.nomad",
    trimsuffix(google_dns_record_set.public.0.name, "."),
  ] : [
    "localhost",
    "server.global.nomad",
  ]

  subject {
    common_name  = "server.global.nomad"
    organization = var.tls_organization
  }
}

resource "tls_locally_signed_cert" "nomad-server" {
  cert_request_pem = tls_cert_request.nomad-server.cert_request_pem

  ca_private_key_pem = tls_private_key.nomad-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad-ca.cert_pem

  validity_period_hours = var.tls_validity_period_hours

  allowed_uses = [
    "server_auth",
    "client_auth",
  ]
}