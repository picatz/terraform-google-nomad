output "external_ip" {
  # value is an empty string unless external_ip is true
  value = (var.external_ip && var.instances >= 1) ? google_compute_instance.vm[0].network_interface[0].access_config[0].nat_ip : ""
}

output "internal_ip" {
  value = (var.instances >= 1) ? google_compute_instance.vm[0].network_interface[0].network_ip : ""
}
