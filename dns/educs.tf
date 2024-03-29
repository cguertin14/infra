resource "cloudflare_zone" "educs" {
  zone       = var.educs_domain
  account_id = var.account_id
  plan       = "free"
  type       = "full"
}

resource "cloudflare_record" "educs" {
  depends_on = [
    cloudflare_record.pi_load_balancer,
    cloudflare_zone.educs
  ]

  for_each = toset(var.educs_domains)
  name     = each.value
  zone_id  = cloudflare_zone.educs.id
  type     = "CNAME"
  value    = cloudflare_record.pi_load_balancer.hostname
  ttl      = 1800
  proxied  = false
}
