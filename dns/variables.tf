variable "cguertin_domain" {
  description = "Personal domain URI"
  type        = string
  default     = "cguertin.dev"
}

# provided via terraform cloud
variable "account_id" {
  description = "The ID of the cloudflare account"
  type        = string
}

variable "router_ip" {
  description = "Router IP address"
  type        = string
  default     = "24.202.157.237"
}

variable "proxied_domains" {
  description = "List of CF proxied domains to create"
  type        = list(string)
  default = [
    "@",
    "preview",
  ]
}

variable "domains" {
  description = "The CNAME domains to create"
  type        = list(string)
  default = [
    "plex",
    "auth.k8s",
    "gitops.k8s",
    "pihole.k8s",
    "network.k8s",
    "monitoring.k8s",
    "rollout.gitops.k8s",
    "prometheus.monitoring.k8s",
    "alertmanager.monitoring.k8s",
  ]
}
