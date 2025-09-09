data "google_client_openid_userinfo" "me" {
}

resource "google_os_login_ssh_public_key" "default" {
  user = data.google_client_openid_userinfo.me.email
  key  = file("~/.ssh/rolder-gcp.pub")
}

resource "google_compute_firewall" "remna" {
  name    = "remna"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2222", "4444", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "remnapanel" {
  name         = "remnapanel"
  machine_type = "e2-small"
  zone         = "europe-north2-c"

  # Для смены железа
  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "true"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}

resource "google_compute_instance" "stockholm" {
  name = "stockholm"
  # Установка
  # machine_type = "e2-highcpu-4"
  # Работа
  machine_type = "e2-micro"
  zone         = "europe-north2-c"

  # Для смены железа
  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "true"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}

resource "google_compute_instance" "helsinki" {
  name = "helsinki"
  # Установка
  # machine_type = "e2-highcpu-4"
  # Работа
  machine_type = "f1-micro"
  zone         = "europe-north1-c"

  # Для смены железа
  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "true"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}
