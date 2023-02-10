module "bastion" {
  instances          = var.bastion_enabled ? 1 : 0
  source             = "./modules/vm"
  name               = "nomad-bastion"
  machine_type       = var.bastion_machine_type
  image              = format("%s/bastion", var.project)
  subnetwork         = module.network.subnetwork
  region             = var.region
  zone               = var.zone
  tags               = ["bastion"]
  ssh_user           = var.ssh_user
  ssh_public_key     = tls_private_key.ssh_key.public_key_openssh
  external_ip        = true
  enable_preemptible = var.enable_preemptible_bastion_vm
  enable_shielded_vm = var.enable_shielded_vms
}

# Note: Always escape potential forward-slashes in the the base64 output of the gossip key
#       if being passed to commands like sed in a startup-script. And this is obviously not perfect
#       for many reasons, but is required for the current configuration setup using a cloud-init
#       startup script.

module "server" {
  source             = "./modules/vm"
  instances          = var.server_instances
  name               = "server"
  machine_type       = var.server_machine_type
  image              = format("%s/server", var.project)
  subnetwork         = module.network.subnetwork
  region             = var.region
  zone               = var.zone
  tags               = ["server"]
  ssh_user           = var.ssh_user
  ssh_public_key     = tls_private_key.ssh_key.public_key_openssh
  enable_preemptible = var.enable_preemptible_server_vms
  enable_shielded_vm = var.enable_shielded_vms

  metadata_startup_script = templatefile("${path.module}/templates/server.sh", {
    project                    = var.project
    number_of_servers          = var.server_instances
    nomad_ca_cert              = tls_self_signed_cert.nomad-ca.cert_pem
    nomad_server_cert          = tls_locally_signed_cert.nomad-server.cert_pem
    nomad_server_private_key   = tls_private_key.nomad-server.private_key_pem
    nomad_gossip_secret_key    = replace(random_id.nomad-gossip-key.b64_std, "/", "\\/")
    nomad_acls_enabled         = var.nomad_acls_enabled
    consul_gossip_secret_key   = replace(random_id.consul-gossip-key.b64_std, "/", "\\/")
    consul_ca_cert             = tls_self_signed_cert.consul-ca.cert_pem
    consul_server_cert         = tls_locally_signed_cert.consul-server.cert_pem
    consul_server_private_key  = tls_private_key.consul-server.private_key_pem
    consul_acls_enabled        = var.consul_acls_enabled
    consul_acls_default_policy = var.consul_acls_default_policy
    consul_master_token        = random_uuid.consul_master_token.result
  }) 
}

module "client" {
  source             = "./modules/vm"
  instances          = var.client_instances
  name               = "client"
  machine_type       = var.client_machine_type
  image              = format("%s/client", var.project)
  subnetwork         = module.network.subnetwork
  region             = var.region
  zone               = var.zone
  tags               = ["client"]
  ssh_user           = var.ssh_user
  ssh_public_key     = tls_private_key.ssh_key.public_key_openssh
  enable_preemptible = var.enable_preemptible_client_vms
  enable_shielded_vm = var.enable_shielded_vms

  metadata_startup_script = templatefile("${path.module}/templates/client.sh", {
    project                    = var.project
    nomad_ca_cert              = tls_self_signed_cert.nomad-ca.cert_pem
    nomad_client_cert          = tls_locally_signed_cert.nomad-client.cert_pem
    nomad_client_private_key   = tls_private_key.nomad-client.private_key_pem
    nomad_acls_enabled         = var.nomad_acls_enabled
    consul_gossip_secret_key   = replace(random_id.consul-gossip-key.b64_std, "/", "\\/")
    consul_ca_cert             = tls_self_signed_cert.consul-ca.cert_pem
    consul_client_cert         = tls_locally_signed_cert.consul-client.cert_pem
    consul_client_private_key  = tls_private_key.consul-client.private_key_pem
    consul_acls_enabled        = var.consul_acls_enabled
    consul_master_token        = random_uuid.consul_master_token.result
    consul_acls_default_policy = var.consul_acls_default_policy
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
  })
}
