module "bastion" {
    source         = "./modules/vm"
    name           = "nomad-bastion"
    machine_type   = "g1-small"
    image          = "my-nomad-cluster/nomad-bastion"
    subnetwork     = module.nomad-network.subnetwork
    zone           = var.zone
    tags           = ["nomad-bastion"]
    ssh_user       = var.ssh_user
    ssh_public_key = tls_private_key.ssh_key.public_key_openssh
    external_ip    = true
}

module "server" {
    source         = "./modules/vm"
    name           = "nomad-server"
    machine_type   = "g1-small"
    image          = "my-nomad-cluster/nomad-server"
    subnetwork     = module.nomad-network.subnetwork
    zone           = var.zone
    tags           = ["nomad-server"]
    ssh_user       = var.ssh_user
    ssh_public_key = tls_private_key.ssh_key.public_key_openssh

    metadata_startup_script = local.nomad_server_bootstrap_script
}

module "client" {
    source         = "./modules/vm"
    name           = "nomad-client"
    machine_type   = "n1-standard-1"
    image          = "my-nomad-cluster/nomad-client"
    subnetwork     = module.nomad-network.subnetwork
    zone           = var.zone
    tags           = ["nomad-client"]
    ssh_user       = var.ssh_user
    ssh_public_key = tls_private_key.ssh_key.public_key_openssh

    metadata_startup_script = local.nomad_client_bootstrap_script
}