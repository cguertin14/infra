resource "cloudflare_zone" "cguertin_dev" {
  zone       = var.cguertin_domain
  account_id = var.account_id
  plan       = "free"
  type       = "full"
}

resource "cloudflare_record" "pi_load_balancer" {
  zone_id = cloudflare_zone.cguertin_dev.id
  name    = "lb.${var.cguertin_domain}."
  type    = "A"
  value   = var.router_ip
  ttl     = 300
  proxied = false
}

resource "cloudflare_record" "cname_dns_entry" {
  depends_on = [
    cloudflare_record.pi_load_balancer,
    cloudflare_zone.cguertin_dev
  ]
  for_each = toset(var.domains)
  name     = each.value
  zone_id  = cloudflare_zone.cguertin_dev.id
  type     = "CNAME"
  value    = cloudflare_record.pi_load_balancer.hostname
  ttl      = 1800
  proxied  = false
}

resource "cloudflare_record" "cname_dns_entry_proxied" {
  depends_on = [
    cloudflare_record.pi_load_balancer,
    cloudflare_zone.cguertin_dev
  ]
  for_each = toset(var.domains)
  name     = each.value
  zone_id  = cloudflare_zone.cguertin_dev.id
  type     = "CNAME"
  value    = cloudflare_record.pi_load_balancer.hostname
  ttl      = 1
  proxied  = true
}
