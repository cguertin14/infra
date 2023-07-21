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
  default     = "184.163.60.220"
}

variable "domains" {
  description = "The CNAME domains to create"
  type        = list(string)
  default = [
    "@",
    "vpn",
    "preview",
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
