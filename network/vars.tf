variable "name" {
    type    = string
    default = "nomad"
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "cidr_range" {
  type    = string
  default = "192.168.1.0/24"
}

variable "source_tags" {
    type    = list(string)
    default = ["nomad-bastion", "nomad-server", "nomad-client"]
}