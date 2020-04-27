module "load_balancer" {
  source         = "./modules/load-balancer"
  region         = var.region
  name           = "load-balancer"
  service_port   = 4646
  target_tags    = ["nomad-server"]
  network        = module.nomad-network.name
  instances      = formatlist("${format("%s-%s/nomad-server", var.region, var.zone)}-%d", range(var.server_instances))
  and_depends_on = [module.nomad-network]
}
