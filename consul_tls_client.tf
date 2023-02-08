# TODO(kent): delete once auto_encrypt is setup/verified

resource "tls_private_key" "consul-client" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "consul-client" {
  private_key_pem = tls_private_key.consul-client.private_key_pem

  ip_addresses = [
    "127.0.0.1",
  ]

  dns_names = [
    "localhost",
    "client.dc1.consul",
  ]

  subject {
    common_name  = "client.dc1.consul"
    organization = var.tls_organization
  }
}

resource "tls_locally_signed_cert" "consul-client" {
  cert_request_pem = tls_cert_request.consul-client.cert_request_pem

  ca_private_key_pem = tls_private_key.consul-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul-ca.cert_pem

  validity_period_hours = var.tls_validity_period_hours

  allowed_uses = [
    "server_auth",
    "client_auth",
  ]
}