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
  zone_id  = cloudflare_zone.educs.id
  name     = each.value
  type     = "CNAME"
  value    = cloudflare_record.pi_load_balancer.hostname
  proxied  = true
  ttl      = 1
}
