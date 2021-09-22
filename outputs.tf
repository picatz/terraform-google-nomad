output "nomad_ca_cert" {
  sensitive   = true
  description = "The TLS CA certificate used for CLI authentication."
  value       = tls_self_signed_cert.nomad-ca.cert_pem
}

output "nomad_cli_cert" {
  sensitive   = true
  description = "The TLS certificate used for CLI authentication."
  value       = tls_locally_signed_cert.nomad-cli.cert_pem
}

output "nomad_cli_key" {
  sensitive   = true
  description = "The TLS private key used for CLI authentication."
  value       = tls_private_key.nomad-cli.private_key_pem
}

output "consul_ca_cert" {
  sensitive   = true
  description = "The TLS CA certificate used for CLI authentication."
  value       = tls_self_signed_cert.consul-ca.cert_pem
}

output "consul_cli_cert" {
  sensitive   = true
  description = "The TLS certificate used for CLI authentication."
  value       = tls_locally_signed_cert.consul-cli.cert_pem
}

output "consul_cli_key" {
  sensitive   = true
  description = "The TLS private key used for CLI authentication."
  value       = tls_private_key.consul-cli.private_key_pem
}

output "consul_master_token" {
  sensitive   = true
  description = "The Consul master token."
  value       = random_uuid.consul_master_token.result
}

output "bastion_ssh_public_key" {
  sensitive   = true
  description = "The SSH bastion public key."
  value       = tls_private_key.ssh_key.public_key_openssh
}

output "bastion_ssh_private_key" {
  sensitive   = true
  description = "The SSH bastion private key."
  value       = tls_private_key.ssh_key.private_key_pem
}

output "bastion_public_ip" {
  description = "The SSH bastion public IP."
  value       = module.bastion.external_ip
}

output "server_internal_ip" {
  description = "The Nomad/Consul server private IP."
  value       = module.server.internal_ip
}

output "load_balancer_ip" {
  description = "The external ip address of the load balacner"
  value       = module.load_balancer.external_ip
}

output "grafana_load_balancer_ip" {
  description = "The external ip address of the grafana load balacner"
  value       = module.grafana_load_balancer.external_ip
}

output "client_internal_ips" {
  description = "The Nomad/Consul client private IP addresses."
  value       = module.client.internal_ips
}

output "server_internal_ips" {
  description = "The Nomad/Consul client private IP addresses."
  value       = module.server.internal_ips
}

output "dns_name_servers" {
  description = "Delegate your managed_zone to these virtual name servers if DNS is enabled"
  value       = var.dns_enabled ? google_dns_managed_zone.nomad.0.name_servers : []
}

output "dns_url" {
  description = "The mTLS enabled public URL using the configured DNS name"
  value       = (var.dns_enabled) ? format("https://%s", trimsuffix(google_dns_record_set.public.0.name, ".")) : ""
}