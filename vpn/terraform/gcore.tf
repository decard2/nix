data "gcore_project" "default" {
  name = "Default"
}

data "gcore_region" "helsinki" {
  name = "Helsinki"
}

data "gcore_image" "debian12" {
  name       = "debian-12-generic-x64-qcow2"
  region_id  = data.gcore_region.helsinki.id
  project_id = data.gcore_project.default.id
}

resource "gcore_keypair" "rolder" {
  sshkey_name = "rolder-net"
  public_key  = file("~/.ssh/rolder-net-gcp.pub")
  project_id  = data.gcore_project.default.id
}

resource "gcore_securitygroup" "helsinkiGcore" {
  name       = "helsinkiGcore"
  project_id = data.gcore_project.default.id
  region_id  = data.gcore_region.helsinki.id

  security_group_rules {
    direction        = "egress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    port_range_min   = 1
    port_range_max   = 24
    remote_ip_prefix = "0.0.0.0/0"
  }

  security_group_rules {
    direction        = "egress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    port_range_min   = 26
    port_range_max   = 65535
    remote_ip_prefix = "0.0.0.0/0"
  }

  security_group_rules {
    direction        = "egress"
    ethertype        = "IPv4"
    protocol         = "udp"
    port_range_min   = 1
    port_range_max   = 24
    remote_ip_prefix = "0.0.0.0/0"
  }

  security_group_rules {
    direction        = "egress"
    ethertype        = "IPv4"
    protocol         = "udp"
    port_range_min   = 26
    port_range_max   = 65535
    remote_ip_prefix = "0.0.0.0/0"
  }

  security_group_rules {
    direction        = "egress"
    ethertype        = "IPv4"
    protocol         = "icmp"
    remote_ip_prefix = "0.0.0.0/0"
  }

  # Временно для установки NixOS, после можно убрать
  security_group_rules {
    direction        = "ingress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    port_range_min   = 22
    port_range_max   = 22
    remote_ip_prefix = "0.0.0.0/0"
  }

  security_group_rules {
    direction        = "ingress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    port_range_min   = 443
    port_range_max   = 443
    remote_ip_prefix = "0.0.0.0/0"
  }

  security_group_rules {
    direction        = "ingress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    port_range_min   = 2222
    port_range_max   = 2222
    remote_ip_prefix = "0.0.0.0/0"
  }

  security_group_rules {
    direction        = "ingress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    port_range_min   = 4444
    port_range_max   = 4444
    remote_ip_prefix = "0.0.0.0/0"
  }
}

resource "gcore_volume" "helsinkiGcore" {
  name       = "helsinkiGcore-boot"
  type_name  = "standard"
  size       = 20
  image_id   = data.gcore_image.debian12.id
  project_id = data.gcore_project.default.id
  region_id  = data.gcore_region.helsinki.id
}

resource "gcore_instancev2" "helsinkiGcore" {
  name = "helsinkiGcore"
  # Установка
  # flavor_id = "g2-standard-2-4"
  # Работа
  flavor_id = "g2-standard-1-2"
  keypair_name = gcore_keypair.rolder.sshkey_name
  project_id   = data.gcore_project.default.id
  region_id    = data.gcore_region.helsinki.id

  volume {
    volume_id  = gcore_volume.helsinkiGcore.id
    boot_index = 0
  }

  interface {
    name            = "external"
    type            = "external"
    security_groups = [gcore_securitygroup.helsinkiGcore.id]
  }
}
