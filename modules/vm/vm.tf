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
