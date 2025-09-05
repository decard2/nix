provider "google" {
  project = "rolder-471208"
}

data "google_client_openid_userinfo" "me" {
}

resource "google_os_login_ssh_public_key" "default" {
  user = data.google_client_openid_userinfo.me.email
  key  = file("~/.ssh/rolder-gcp.pub")
}

resource "google_compute_firewall" "example" {
  name    = "stockholm"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2222", "4444", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "spot_vm_instance" {
  name = "stockholm"
  # Установка
  machine_type = "e2-highcpu-4"
  # Работа
  # machine_type = "e2-custom-micro-1024"
  zone = "europe-north2-b"

  metadata = {
    enable-oslogin = "true"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
    }
  }
}
