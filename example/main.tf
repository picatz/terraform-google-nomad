variable "project" {
    description = "The GCP project name to deploy the cluster to."
}

variable "credentials" {
    description = "The GCP project credentials to use, preferably a Terraform Service Account."
}

module "nomad" {
  source      = "picatz/nomad/google"
  version     = "1.1.2"
  project     = var.project
  credentials = var.credentials
}