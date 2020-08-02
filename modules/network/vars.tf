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
    default = ["bastion", "server", "client"]
}

variable "rpc_source_tags" {
    type    = list(string)
    default = ["server", "client"]
}

variable "dns_source_tags" {
    type    = list(string)
    default = ["bastion", "server", "client"]
}

variable "server_client_source_tags" {
    type    = list(string)
    default = ["server", "client"]
}

variable "gossip_source_tags" {
    type    = list(string)
    default = ["server", "client"]
}

variable "router_asn" {
  type    = string
  default = "64514"
}