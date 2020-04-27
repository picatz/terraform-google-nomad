module "nomad-network" {
  source     = "./modules/network"
  cidr_range = var.cidr_range
  region     = var.region
}