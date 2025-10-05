locals {
  services = {
    "helsinki" = {
      name = "fi"
      ip   = "35.228.119.26"
    }
    "stockholm" = {
      name = "sw"
      ip   = "34.51.151.3"
    }
    "panel" = {
      name = "@"
      ip   = "34.51.175.21"
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
