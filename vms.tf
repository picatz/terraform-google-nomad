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

  metadata_startup_script = data.template_file.server_bootstrap_script.rendered
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

  metadata_startup_script = data.template_file.client_bootstrap_script.rendered
}
