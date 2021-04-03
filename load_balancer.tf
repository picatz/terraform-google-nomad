module "load_balancer" {
  source            = "./modules/load-balancer"
  region            = var.region
  name              = "load-balancer"
  ports             = [4646,8501]
  health_check_port = 4646
  target_tags       = ["server"]
  network           = module.network.name
  instances         = formatlist("${format("%s-%s/server", var.region, var.zone)}-%d", range(var.server_instances))
  and_depends_on    = [module.network]
}

module "grafana_load_balancer" {
  source            = "./modules/load-balancer"
  region            = var.region
  name              = "grafana-load-balancer"
  ports             = [3000]
  health_check_port = 3000
  target_tags       = ["client"]
  network           = module.network.name
  instances         = formatlist("${format("%s-%s/client", var.region, var.zone)}-%d", range(var.client_instances))
  and_depends_on    = [module.network]
}
