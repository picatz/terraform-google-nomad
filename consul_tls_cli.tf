resource "tls_private_key" "consul-cli" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "consul-cli" {
  private_key_pem = tls_private_key.consul-cli.private_key_pem

  ip_addresses = [
    module.load_balancer.external_ip,
    "127.0.0.1",
  ]

  dns_names = [
    "localhost",
    "cli.dc1.consul",
  ]

  subject {
    common_name  = "client.global.consul"
    organization = var.tls_organization
  }
}

resource "tls_locally_signed_cert" "consul-cli" {
  cert_request_pem = tls_cert_request.consul-cli.cert_request_pem

  ca_private_key_pem = tls_private_key.consul-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul-ca.cert_pem

  validity_period_hours = var.tls_validity_period_hours

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
  ]
}