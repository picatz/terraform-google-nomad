module "network" {
  source          = "./modules/network"
  cidr_range      = var.cidr_range
  region          = var.region
  bastion_enabled = var.bastion_enabled
}