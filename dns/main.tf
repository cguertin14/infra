resource "cloudflare_zone" "cguertin_dev" {
  zone = var.domain_cguertin
  plan = "free"
  type = "full"
}

resource "cloudflare_record" "pi_load_balancer" {
  zone_id = cloudflare_zone.cguertin_dev.id
  name    = "lb.${var.domain_cguertin}."
  type    = "A"
  value   = var.router_ip
  ttl     = 300
  proxied = false
}

resource "cloudflare_record" "monitoring" {
  zone_id = cloudflare_zone.cguertin_dev.id
  name    = "monitoring.k8s"
  type    = "CNAME"
  value   = cloudflare_record.pi_load_balancer.hostname
  ttl     = 1800
  proxied = false
}

resource "cloudflare_record" "gitops" {
  zone_id = cloudflare_zone.cguertin_dev.id
  name    = "gitops.k8s"
  type    = "CNAME"
  value   = cloudflare_record.pi_load_balancer.hostname
  ttl     = 1800
  proxied = false
}
