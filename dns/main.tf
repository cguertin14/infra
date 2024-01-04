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
  proxied = true
}

resource "cloudflare_record" "cname_dns_entry" {
  depends_on = [
    cloudflare_record.pi_load_balancer,
    cloudflare_zone.cguertin_dev
  ]
  count   = length(var.domains)
  zone_id = cloudflare_zone.cguertin_dev.id
  name    = var.domains[count.index]
  type    = "CNAME"
  value   = cloudflare_record.pi_load_balancer.hostname
  proxied = true
}
