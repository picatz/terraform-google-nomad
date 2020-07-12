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
  default     = 1
  description = "The total number of Nomad servers to deploy (use odd numbers)."
}

variable "server_machine_type" {
  type        = string
  default     = "g1-small"
  description = "The VM machine type for Nomad servers."
}

variable "client_instances" {
  type        = number
  default     = 1
  description = "The total number of Nomad clients to deploy."
}

variable "client_machine_type" {
  type        = string
  default     = "n1-standard-1"
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

variable "acls_enabled" {
  type        = bool
  default     = true
  description = "If ACLs should be enabled for the cluster."
}

variable "gvisor_enabled" {
  type        = bool
  default     = true
  description = "Enables the gVisor Docker runtime for the cluster."
}

variable "gvisor_release" {
  type        = string
  default     = "release"
  description = "The release type to use, defaults to the latest release type."
}

variable "docker_default_runtime" {
  type        = string
  default     = "runc"
  description = "The default Docker runtime to use."
}

variable "docker_rootless_enabled" {
  type        = bool
  default     = true
  description = "Enable rootless mode (experimental)."
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