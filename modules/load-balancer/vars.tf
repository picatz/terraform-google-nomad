variable "and_depends_on" {
  # https://discuss.hashicorp.com/t/tips-howto-implement-module-depends-on-emulation/2305
  type    = any
  default = null
}

variable "network" {
  type = string
}

variable "name" {
  type    = string
  default = "load-balancer"
}

variable "region" {
  type = string
}

variable "target_tags" {
  type = list(string)
}

variable "service_port" {
  type = number
}

variable "protocol" {
  type    = string
  default = "tcp"
}

variable "instances" {
  type = list(string)
}

