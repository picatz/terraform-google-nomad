module "bastion" {
    source     = "./vm"
    name       = "nomad-bastion"
    image      = "my-nomad-cluster/nomad-bastion"
    subnetwork = module.nomad-network.subnetwork
    zone       = var.zone
    tags       = ["nomad-bastion"]

    external_ip = true
}

module "server" {
    source     = "./vm"
    name       = "nomad-server"
    image      = "my-nomad-cluster/nomad-server"
    subnetwork = module.nomad-network.subnetwork
    zone       = var.zone
    tags       = ["nomad-server"]

    metadata_startup_script = local.nomad_bootstrap_script
}

module "client" {
    source     = "./vm"
    name       = "nomad-client"
    image      = "my-nomad-cluster/nomad-client"
    subnetwork = module.nomad-network.subnetwork
    zone       = var.zone
    tags       = ["nomad-client"]

    metadata_startup_script = local.nomad_bootstrap_script
}