resource "tls_private_key" "consul-ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "consul-ca" {
  is_ca_certificate     = true
  validity_period_hours = var.tls_validity_period_hours

  private_key_pem = tls_private_key.consul-ca.private_key_pem

  subject {
    common_name  = "consul-ca.local"
    organization = var.tls_organization
  }

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}
