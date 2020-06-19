module "bastion" {
  source         = "./modules/vm"
  name           = "nomad-bastion"
  machine_type   = var.bastion_machine_type
  image          = format("%s/nomad-bastion", var.project)
  subnetwork     = module.nomad-network.subnetwork
  zone           = var.zone
  tags           = ["nomad-bastion"]
  ssh_user       = var.ssh_user
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  external_ip    = true
}

module "server" {
  source         = "./modules/vm"
  instances      = var.server_instances
  name           = "nomad-server"
  machine_type   = var.server_machine_type
  image          = format("%s/nomad-server", var.project)
  subnetwork     = module.nomad-network.subnetwork
  zone           = var.zone
  tags           = ["nomad-server"]
  ssh_user       = var.ssh_user
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh

  metadata_startup_script = data.template_file.nomad_server_bootstrap_script.rendered
}

module "client" {
  source         = "./modules/vm"
  instances      = var.client_instances
  name           = "nomad-client"
  machine_type   = var.client_machine_type
  image          = format("%s/nomad-client", var.project)
  subnetwork     = module.nomad-network.subnetwork
  zone           = var.zone
  tags           = ["nomad-client"]
  ssh_user       = var.ssh_user
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh

  metadata_startup_script = data.template_file.nomad_client_bootstrap_script.rendered
}
