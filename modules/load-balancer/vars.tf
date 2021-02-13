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

variable "ports" {
  type = list(number)
}

variable "protocol" {
  type    = string
  default = "tcp"
}

variable "instances" {
  type = list(string)
}

variable "enabled" {
  type    = bool
  default = true
}

variable "health_check_port" {
  type = number
}