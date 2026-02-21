locals {
  services = {
    "helsinki" = {
      name = "fi"
      ip   = "34.88.241.59"
    }
    "stockholm" = {
      name = "sw"
      ip   = "34.2.48.139"
    }
    "panel" = {
      name = "@"
      ip   = "34.2.52.207"
    }
    "sibeerskaya" = {
      name = "sibeerskaya"
      ip   = "35.217.45.57"
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
