resource "cloudflare_zone" "cguertin_dev" {
  zone       = var.domain_cguertin
  account_id = var.account_id
  plan       = "free"
  type       = "full"
}

resource "cloudflare_record" "pi_load_balancer" {
  zone_id = cloudflare_zone.cguertin_dev.id
  name    = "lb.${var.domain_cguertin}."
  type    = "A"
  value   = var.router_ip
  ttl     = 300
  proxied = false
}

resource "cloudflare_record" "cname_dns_entry" {
  count   = length(var.domains)
  zone_id = cloudflare_zone.cguertin_dev.id
  name    = var.domains[count.index]
  type    = "CNAME"
  value   = cloudflare_record.pi_load_balancer.hostname
  ttl     = 1800
  proxied = false
}
