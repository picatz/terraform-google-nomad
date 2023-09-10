packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

variable "account_file" {
  type    = string
  default = "${env("GOOGLE_APPLICATION_CREDENTIALS")}"
}

variable "disk_size_gb" {
  type    = string
  default = "10"
}

variable "network" {
  type    = string
  default = "default"
}

variable "project" {
  type    = string
  default = "${env("GOOGLE_PROJECT")}"
}

variable "source_image_family" {
  type    = string
  default = "ubuntu-2004-lts"
}

variable "subnetwork" {
  type    = string
  default = ""
}

variable "use_iap" {
  type    = string
  default = "false"
}

variable "use_preemptible" {
  type    = string
  default = "false"
}

variable "zone" {
  type    = string
  default = "us-east1-b"
}

source "googlecompute" "bastion" {
  account_file        = "${var.account_file}"
  disk_size           = "${var.disk_size_gb}"
  image_description   = "nomad bastion image"
  image_name          = "bastion"
  machine_type        = "n1-standard-1"
  network             = "${var.network}"
  preemptible         = "${var.use_preemptible}"
  project_id          = "${var.project}"
  source_image_family = "${var.source_image_family}"
  ssh_username        = "ubuntu"
  state_timeout       = "15m"
  subnetwork          = "${var.subnetwork}"
  use_iap             = "${var.use_iap}"
  zone                = "${var.zone}"
}

source "googlecompute" "client" {
  account_file        = "${var.account_file}"
  disk_size           = "${var.disk_size_gb}"
  image_description   = "HashiCorp Nomad and Consul client image"
  image_name          = "client"
  machine_type        = "n1-standard-1"
  network             = "${var.network}"
  preemptible         = "${var.use_preemptible}"
  project_id          = "${var.project}"
  source_image_family = "${var.source_image_family}"
  ssh_username        = "ubuntu"
  state_timeout       = "15m"
  subnetwork          = "${var.subnetwork}"
  use_iap             = "${var.use_iap}"
  zone                = "${var.zone}"
}

source "googlecompute" "server" {
  account_file        = "${var.account_file}"
  disk_size           = "${var.disk_size_gb}"
  image_description   = "HashiCorp Nomad and Consul server image"
  image_name          = "server"
  machine_type        = "n1-standard-1"
  network             = "${var.network}"
  preemptible         = "${var.use_preemptible}"
  project_id          = "${var.project}"
  source_image_family = "${var.source_image_family}"
  ssh_username        = "ubuntu"
  state_timeout       = "15m"
  subnetwork          = "${var.subnetwork}"
  use_iap             = "${var.use_iap}"
  zone                = "${var.zone}"
}

build {
  sources = [
    "source.googlecompute.bastion", 
    "source.googlecompute.client", 
    "source.googlecompute.server",
  ]

  provisioner "file" {
    destination = "/tmp/nomad-agent.hcl"
    only        = ["googlecompute.server"]
    source      = "configs/nomad/server.hcl"
  }

  provisioner "file" {
    destination = "/tmp/consul-agent.hcl"
    only        = ["googlecompute.server"]
    source      = "configs/consul/server.hcl"
  }

  provisioner "file" {
    destination = "/tmp/nomad-agent.hcl"
    only        = ["googlecompute.client"]
    source      = "configs/nomad/client.hcl"
  }

  provisioner "file" {
    destination = "/tmp/consul-agent.hcl"
    only        = ["googlecompute.client"]
    source      = "configs/consul/client.hcl"
  }

  provisioner "file" {
    destination = "/tmp/docker_auth_config.json"
    only        = ["googlecompute.client"]
    source      = "configs/nomad/docker_auth_config.json"
  }

  provisioner "file" {
    destination = "/tmp/nomad.service"
    only        = ["googlecompute.server", "googlecompute.client"]
    source      = "configs/nomad/nomad.service"
  }

  provisioner "file" {
    destination = "/tmp/consul.service"
    only        = ["googlecompute.server", "googlecompute.client"]
    source      = "configs/consul/consul.service"
  }

  provisioner "shell" {
    scripts = ["scripts/install_required_packages.sh"]
  }

  provisioner "shell" {
    only    = ["googlecompute.client"]
    scripts = ["scripts/install_docker.sh", "scripts/install_gvisor.sh"]
  }

  provisioner "shell" {
    only    = ["googlecompute.client"]
    scripts = ["scripts/install_cni_plugins.sh"]
  }

  provisioner "shell" {
    only    = ["googlecompute.server", "googlecompute.client"]
    scripts = ["scripts/install_hashicorp_apt.sh", "scripts/install_nomad.sh", "scripts/install_consul.sh"]
  }

  provisioner "shell" {
    scripts = ["scripts/install_stack_driver_agents.sh", "scripts/install_falco.sh"]
  }

  provisioner "shell" {
    only    = ["googlecompute.client"]
    scripts = ["scripts/install_docker-credential-gcr.sh"]
  }

  provisioner "shell" {
    inline = ["curl https://releases.hashicorp.com/nomad/1.6.1/nomad_1.6.1_linux_amd64.zip -o nomad.zip", "unzip nomad.zip", "sudo mv nomad /bin", "rm nomad.zip"]
    only   = ["googlecompute.bastion"]
  }
}
