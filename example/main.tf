variable "project" {
    description = "The GCP project name to deploy the cluster to."
}

variable "credentials" {
    description = "The GCP credentials file path to use, preferably a Terraform Service Account."
}

module "nomad" {
  source           = "picatz/nomad/google"
  version          = "1.1.4"
  project          = var.project
  credentials      = var.credentials
  bastion_enabled  = false
  server_instances = 1
  client_instances = 1
}