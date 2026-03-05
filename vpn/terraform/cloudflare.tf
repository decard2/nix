locals {
  services = {
    "helsinki" = {
      name = "fi"
      ip   = google_compute_instance.helsinki.network_interface[0].access_config[0].nat_ip
    }
    "warsaw" = {
      name = "pl"
      ip   = google_compute_instance.warsaw.network_interface[0].access_config[0].nat_ip
    }
    "panel" = {
      name = "@"
      ip   = google_compute_instance.remnapanel.network_interface[0].access_config[0].nat_ip
    }
    "sibeerskaya" = {
      name = "sibeerskaya"
      ip   = google_compute_instance.sibeerskaya.network_interface[0].access_config[0].nat_ip
    }
    "helsinkiGcore" = {
      name = "fi2"
      ip   = gcore_instancev2.helsinkiGcore.addresses[0].net[0].addr
    }
    "frankfurt" = {
      name = "de"
      ip   = google_compute_instance.frankfurt.network_interface[0].access_config[0].nat_ip
    }
  }
}

resource "cloudflare_dns_record" "dns" {
  for_each = local.services

  zone_id = "5780cf13c74a1ca4e6297cfcf3531e4f"
  comment = "${each.key} terraform record"
  name    = each.value.name
  content = each.value.ip
  proxied = false
  ttl     = 1
  type    = "A"
}
