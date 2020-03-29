variable "network" {
  type = string
}

variable "name" {
  type = string
}

variable "port" {
  type = number
}

variable "protocol" {
  type    = string
  default = "tcp"
}

variable "source_tags" {
  type    = list(string)
  default = []
}
