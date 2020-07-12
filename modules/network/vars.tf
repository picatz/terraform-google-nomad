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

variable "http_source_tags" {
    type    = list(string)
    default = ["nomad-bastion", "nomad-server", "nomad-client"]
}

variable "rpc_source_tags" {
    type    = list(string)
    default = ["nomad-server", "nomad-client"]
}

variable "gossip_source_tags" {
    type    = list(string)
    default = ["nomad-server"]
}

variable "router_asn" {
  type    = string
  default = "64514"
}