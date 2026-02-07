locals {
  load_balancer_url = "lb.${var.cguertin_domain}"
}

resource "cloudflare_zone" "cguertin_dev" {
  name = var.cguertin_domain
  account = {
    id = var.account_id
  }
}

resource "cloudflare_dns_record" "bsky_validation" {
  zone_id = cloudflare_zone.cguertin_dev.id
  type    = "TXT"
  name    = "_atproto"
  content = "did=did:plc:ianrdupaclcx5ojppeap74wh"
  comment = "Bluesky :)"
  ttl     = 300
  proxied = false
}

resource "cloudflare_dns_record" "pi_load_balancer" {
  zone_id = cloudflare_zone.cguertin_dev.id
  name    = "lb.${var.cguertin_domain}"
  type    = "A"
  content = var.router_ip
  ttl     = 300
  proxied = false
}

resource "cloudflare_dns_record" "cname_dns_entry" {
  depends_on = [
    cloudflare_dns_record.pi_load_balancer,
    cloudflare_zone.cguertin_dev
  ]
  for_each = toset(var.domains)
  name     = each.value
  zone_id  = cloudflare_zone.cguertin_dev.id
  type     = "CNAME"
  content  = local.load_balancer_url
  ttl      = 1800
  proxied  = false
}

resource "cloudflare_dns_record" "cname_dns_entry_proxied" {
  depends_on = [
    cloudflare_dns_record.pi_load_balancer,
    cloudflare_zone.cguertin_dev
  ]
  for_each = toset(var.proxied_domains)
  name     = each.value
  zone_id  = cloudflare_zone.cguertin_dev.id
  type     = "CNAME"
  content  = local.load_balancer_url
  ttl      = 1
  proxied  = true
}
