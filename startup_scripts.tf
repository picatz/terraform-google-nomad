# Note: Always escape potential forward-slashes in the the base64 output of the gossip key
#       if being passed to commands like sed in a startup-script. And this is obviously not perfect
#       for many reasons, but is required for the current configuration setup using a cloud-init
#       startup script.

data "template_file" "server_bootstrap_script" {
  template = file("${path.module}/templates/server.sh")

  vars = {
    project                     = var.project
    number_of_servers           = var.server_instances
    nomad_ca_cert               = tls_self_signed_cert.nomad-ca.cert_pem
    nomad_server_cert           = tls_locally_signed_cert.nomad-server.cert_pem
    nomad_server_private_key    = tls_private_key.nomad-server.private_key_pem
    nomad_gossip_secret_key     = replace(random_id.nomad-gossip-key.b64_std, "/", "\\/")
    nomad_acls_enabled          = var.nomad_acls_enabled
    consul_gossip_secret_key    = replace(random_id.consul-gossip-key.b64_std, "/", "\\/")
    consul_ca_cert              = tls_self_signed_cert.consul-ca.cert_pem
    consul_server_cert          = tls_locally_signed_cert.consul-server.cert_pem
    consul_server_private_key   = tls_private_key.consul-server.private_key_pem
    consul_acls_enabled         = var.consul_acls_enabled
    consul_acls_default_policy  = var.consul_acls_default_policy
    consul_master_token         = random_uuid.consul_master_token.result
    vault_ca_cert               = var.vault_enabled ? file(var.vault_ca_cert_path) : ""
    vault_client_cert           = var.vault_enabled ? file(var.vault_client_cert_path) : ""
    vault_client_private_key    = var.vault_enabled ? file(var.vault_client_private_key_path) : ""
    vault_enabled               = var.vault_enabled
    vault_address               = var.vault_address
    vault_token                 = var.vault_token
    vault_allow_unauthenticated = var.vault_allow_unauthenticated
  }
}

data "template_file" "client_bootstrap_script" {
  template = file("${path.module}/templates/client.sh")

  vars = {
    project                     = var.project
    nomad_ca_cert               = tls_self_signed_cert.nomad-ca.cert_pem
    nomad_client_cert           = tls_locally_signed_cert.nomad-client.cert_pem
    nomad_client_private_key    = tls_private_key.nomad-client.private_key_pem
    nomad_acls_enabled          = var.nomad_acls_enabled
    consul_gossip_secret_key    = replace(random_id.consul-gossip-key.b64_std, "/", "\\/")
    consul_ca_cert              = tls_self_signed_cert.consul-ca.cert_pem
    consul_client_cert          = tls_locally_signed_cert.consul-client.cert_pem
    consul_client_private_key   = tls_private_key.consul-client.private_key_pem
    consul_acls_enabled         = var.consul_acls_enabled
    consul_master_token         = random_uuid.consul_master_token.result
    consul_acls_default_policy  = var.consul_acls_default_policy
    vault_ca_cert               = var.vault_enabled ? file(var.vault_ca_cert_path) : ""
    vault_client_cert           = var.vault_enabled ? file(var.vault_client_cert_path) : ""
    vault_client_private_key    = var.vault_enabled ? file(var.vault_client_private_key_path) : ""
    vault_enabled               = var.vault_enabled
    vault_address               = var.vault_address
    vault_allow_unauthenticated = var.vault_allow_unauthenticated
    docker_config              = jsonencode({
      "default-runtime"  = var.docker_default_runtime,
      "no-new-privileges"= var.docker_no_new_privileges,
      "icc"              = var.docker_icc_enabled,
      "runtimes"         = {
        "runsc" = {
          "path" = "/usr/local/bin/runsc"
        }
      }
    })
  }
}
