module "nomad-network" {
    source     = "./network"
    cidr_range = var.cidr_range
    region     = var.region
}