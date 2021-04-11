resource "google_dns_record_set" "public" {
  count = var.dns_enabled ? 1 : 0
  name  = format("%s.%s.", var.dns_record_set_name_prefix, var.dns_managed_zone_dns_name)
  type  = "A"
  ttl   = 300

  managed_zone = google_dns_managed_zone.nomad.0.name

  rrdatas = [module.load_balancer.external_ip]
}

resource "google_dns_managed_zone" "nomad" {
  count    = var.dns_enabled ? 1 : 0
  name     = "nomad"
  dns_name = format("%s.", var.dns_managed_zone_dns_name)
}