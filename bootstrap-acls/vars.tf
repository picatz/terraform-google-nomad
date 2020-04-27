variable "nomad_token" {
  type        = string
  description = "Nomad token to use for administration."
}

variable "ca_file" {
  type    = string
  default = "../nomad-ca.pem"
}

variable "cli_cert" {
  type    = string
  default = "../nomad-cli-cert.pem"
}

variable "cli_key" {
  type    = string
  default = "../nomad-cli-key.pem"
}