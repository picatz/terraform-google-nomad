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