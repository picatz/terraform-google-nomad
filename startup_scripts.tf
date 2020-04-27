data "template_file" "nomad_server_bootstrap_script" {
  template = file("${path.module}/templates/server.sh")

  vars = {
    project            = var.project
    number_of_servers  = var.server_instances
    ca_cert            = tls_self_signed_cert.nomad-ca.cert_pem
    server_cert        = tls_locally_signed_cert.nomad-server.cert_pem
    server_private_key = tls_private_key.nomad-server.private_key_pem
    gossip_secret_key  = replace(base64encode(random_password.gossip.result), "/", "x")
    acls_enabled       = var.acls_enabled
  }
}

data "template_file" "nomad_client_bootstrap_script" {
  template = file("${path.module}/templates/client.sh")

  vars = {
    project            = var.project
    ca_cert            = tls_self_signed_cert.nomad-ca.cert_pem
    client_cert        = tls_locally_signed_cert.nomad-client.cert_pem
    client_private_key = tls_private_key.nomad-client.private_key_pem
    acls_enabled       = var.acls_enabled
  }
}
