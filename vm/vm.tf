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

    access_config {
      // Ephemeral external IP address
    }
  }

  service_account {
    # https://developers.google.com/identity/protocols/googlescopes
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

  metadata_startup_script = var.metadata_startup_script
}