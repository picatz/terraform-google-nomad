resource "tls_private_key" "nomad-ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "nomad-ca" {
  is_ca_certificate     = true
  validity_period_hours = 87600

  private_key_pem = tls_private_key.nomad-ca.private_key_pem

  subject {
    common_name  = "nomad-ca.local"
    organization = var.tls_organization
  }

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}
