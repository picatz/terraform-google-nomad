variable "project" {
    description = "The GCP project name to deploy the cluster to."
}

variable "credentials" {
    description = "The GCP credentials file path to use, preferably a Terraform Service Account."
}

module "nomad" {
  source      = "picatz/nomad/google"
  version     = "1.1.3"
  project     = var.project
  credentials = var.credentials
}