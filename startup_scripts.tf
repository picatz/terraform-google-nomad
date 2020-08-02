data "template_file" "server_bootstrap_script" {
  template = file("${path.module}/templates/server.sh")

  vars = {
    project                    = var.project
    number_of_servers          = var.server_instances
    nomad_ca_cert              = tls_self_signed_cert.nomad-ca.cert_pem
    nomad_server_cert          = tls_locally_signed_cert.nomad-server.cert_pem
    nomad_server_private_key   = tls_private_key.nomad-server.private_key_pem
    nomad_gossip_secret_key    = replace(base64encode(random_password.nomad-gossip-key.result), "/", "x")
    nomad_acls_enabled         = var.nomad_acls_enabled
    consul_gossip_secret_key   = replace(base64encode(random_password.consul-gossip-key.result), "/", "x")
    consul_ca_cert             = tls_self_signed_cert.consul-ca.cert_pem
    consul_server_cert         = tls_locally_signed_cert.consul-server.cert_pem
    consul_server_private_key  = tls_private_key.consul-server.private_key_pem
    consul_acls_enabled        = var.consul_acls_enabled
    consul_acls_default_policy = var.consul_acls_default_policy
    consul_master_token        = local.consul_master_token
  }
}

locals {
  docker_config = jsonencode({
    "default-runtime"=var.docker_default_runtime,
    "no-new-privileges"=var.docker_no_new_privileges,
    "icc"=var.docker_icc_enabled,
  })
}

data "template_file" "client_bootstrap_script" {
  template = file("${path.module}/templates/client.sh")

  vars = {
    project                    = var.project
    nomad_ca_cert              = tls_self_signed_cert.nomad-ca.cert_pem
    nomad_client_cert          = tls_locally_signed_cert.nomad-client.cert_pem
    nomad_client_private_key   = tls_private_key.nomad-client.private_key_pem
    nomad_acls_enabled         = var.nomad_acls_enabled
    consul_gossip_secret_key   = replace(base64encode(random_password.consul-gossip-key.result), "/", "x")
    consul_ca_cert             = tls_self_signed_cert.consul-ca.cert_pem
    consul_client_cert         = tls_locally_signed_cert.consul-client.cert_pem
    consul_client_private_key  = tls_private_key.consul-client.private_key_pem
    consul_acls_enabled        = var.consul_acls_enabled
    consul_master_token        = local.consul_master_token
    consul_acls_default_policy = var.consul_acls_default_policy
    docker_config              = local.docker_config
  }
}
