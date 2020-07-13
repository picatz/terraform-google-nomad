resource "google_compute_instance" "vm" {
  count        = var.instances
  name         = format("%s-%d", var.name, count.index)
  machine_type = var.machine_type
  zone         = format("%s-%s", var.region, var.zone)
  tags         = var.tags

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    # https://github.com/hashicorp/terraform/issues/21717#issuecomment-502148701
    dynamic "access_config" {
      for_each = var.external_ip ? [{}] : []
      // Ephemeral external IP address
      content {}
    }
  }

  lifecycle {
    create_before_destroy = "true"
  }

  scheduling {
    preemptible       = var.enable_preemptible
    # scheduling must have automatic_restart be false when preemptible is true.
    automatic_restart = ! var.enable_preemptible
  }

  dynamic "shielded_instance_config" {
    # https://github.com/terraform-google-modules/terraform-google-vm/blob/a3d482fa2f33a61880d3cdfe2e7e86ee6b6597d0/modules/instance_template/main.tf#L51
    for_each = var.enable_shielded_vm ? [{}] : []
    content {
      enable_secure_boot          = true
      enable_vtpm                 = true
      enable_integrity_monitoring = true
    }
  }

  service_account {
    # https://developers.google.com/identity/protocols/googlescopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, var.ssh_public_key)
  }

  metadata_startup_script = var.metadata_startup_script
}
