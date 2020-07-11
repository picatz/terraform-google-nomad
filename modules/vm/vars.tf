variable "image" {
    type = string
}

variable "ssh_public_key" {
    type    = string
    default = ""
}

variable "ssh_user" {
    type    = string
    default = "ubuntu"
}

variable "external_ip" {
    type = bool
    default = false
}

variable "name" {
    type = string
}

variable "subnetwork" {
    type = string
}

variable "tags" {
    type = list(string)
}

variable "instances" {
    type    = number
    default = 1
}

variable "metadata_startup_script" {
    type    = string
    default = ""
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "zone" {
  type    = string
  default = "c"
}

variable "machine_type" {
  type    = string
  default = "n1-standard-1"
}

variable "disk_size" {
  type    = number
  default = 50
}
