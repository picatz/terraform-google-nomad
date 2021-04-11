variable "project" {
  type        = string
  description = "The Google Cloud Platform project to deploy the Nomad cluster to."
}

variable "credentials" {
  type        = string
  default     = "./account.json"
  description = "The path to the valid Google Cloud Platform credentials file (in JSON format) to use."
}

variable "region" {
  type        = string
  default     = "us-east1"
  description = "The region to deploy to."
}

variable "zone" {
  type        = string
  default     = "c"
  description = "The zone to deploy to."
}

variable "cidr_range" {
  type        = string
  default     = "192.168.2.0/24"
  description = "The CIDR to deploy with."
}

variable "server_instances" {
  type        = number
  default     = 3
  description = "The total number of Nomad servers to deploy (use odd numbers)."
}

variable "server_machine_type" {
  type        = string
  default     = "n1-standard-1"
  description = "The VM machine type for Nomad servers."
}

variable "client_instances" {
  type        = number
  default     = 5
  description = "The total number of Nomad clients to deploy."
}

variable "client_machine_type" {
  type        = string
  default     = "c2-standard-4"
  description = "The VM machine type for Nomad clients."
}

variable "bastion_enabled" {
  type        = bool
  default     = true
  description = "Enables the SSH bastion."
}

variable "bastion_machine_type" {
  type        = string
  default     = "g1-small"
  description = "The VM machine type for the SSH bastion."
}

variable "ssh_user" {
  type        = string
  default     = "ubuntu"
  description = "The user to use for SSH."
}

variable "tls_organization" {
  type        = string
  default     = "nomad-dev"
  description = "The organization name to use the TLS certificates."
}

variable "save_ssh_keypair_locally" {
  type        = bool
  default     = false
  description = "If the SSH keypair (bastion.pub, bastion) should be saved locally."
}

variable "nomad_acls_enabled" {
  type        = bool
  default     = true
  description = "If ACLs should be enabled for the Nomad cluster."
}

variable "docker_default_runtime" {
  type        = string
  default     = "runc"
  description = "The default Docker runtime to use."
}

variable "docker_no_new_privileges" {
  type        = bool
  default     = true
  description = "Set no-new-privileges by default for new containers."
}

variable "docker_icc_enabled" {
  type        = bool
  default     = false
  description = "Enables inter-container communication."
}

variable "loadbalancer_enabled" {
  type        = bool
  default     = true
  description = "Enables the GCP load balancer for the Nomad Server API to make the cluster available over the internet."
}

variable "enable_preemptible_bastion_vm" {
  type        = bool
  default     = false
  description = "Enables a preemptible SSH bastion host to save costs."
}

variable "enable_preemptible_server_vms" {
  type        = bool
  default     = false
  description = "Enables preemptible Nomad server hosts to save costs."
}

variable "enable_preemptible_client_vms" {
  type        = bool
  default     = false
  description = "Enables preemptible Nomad client hosts to save costs."
}

variable "enable_shielded_vms" {
  type        = bool
  default     = true
  description = "Enables shielded VMs for all hosts."
}

variable "consul_acls_enabled" {
  type        = bool
  default     = true
  description = "If ACLs should be enabled for the Consul cluster."
}

variable "consul_acls_default_policy" {
  type        = string
  default     = "deny"
  description = "The default policy to use for Consul ACLs (allow/deny)."
}

variable "bucket_location" {
  type    = string
  default = "US"
}

variable "dns_enabled" {
  type    = bool
  default = false
}

variable "dns_managed_zone_dns_name" {
  // example: nomad.example.com
  type    = string
  default = ""
}

variable "dns_record_set_name_prefix" {
  // example: public.$dns_managed_zone_dns_name
  type    = string
  default = "public"
}