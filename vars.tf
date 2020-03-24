variable "project" {
  type    = string
  default = "my-nomad-cluster"
}

variable "credentials" {
  type    = string
  default = "./account.json"
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "zone" {
  type    = string
  default = "c"
}

variable "cidr_range" {
  type    = string
  default = "192.168.2.0/24"
}

variable "server_instances" {
  type    = number
  default = 1
}

variable "client_instances" {
  type    = number
  default = 1
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}