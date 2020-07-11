output "ca_cert" {
  sensitive   = true
  description = "The TLS CA certificate used for CLI authentication."
  value       = module.nomad.ca_cert
}

output "cli_cert" {
  sensitive   = true
  description = "The TLS certificate used for CLI authentication."
  value       = module.nomad.cli_cert
}

output "cli_key" {
  sensitive   = true
  description = "The TLS private key used for CLI authentication."
  value       = module.nomad.cli_key
}

output "bastion_ssh_public_key" {
  sensitive   = true
  description = "The SSH bastion public key."
  value       = module.nomad.bastion_ssh_public_key
}

output "bastion_ssh_private_key" {
  sensitive   = true
  description = "The SSH bastion private key."
  value       = module.nomad.bastion_ssh_private_key
}

output "bastion_public_ip" {
  description = "The SSH bastion public IP."
  value       = module.nomad.bastion_public_ip
}

output "nomad_server_ip" {
  description = "The Nomad server private IP."
  value       = module.nomad.nomad_server_ip
}

output "load_balancer_ip" {
  description = "The external ip address of the load balacner"
  value       = module.nomad.load_balancer_ip
}