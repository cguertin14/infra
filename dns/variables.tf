variable "domain_cguertin" {
  description = "Personal domain URI"
  type        = string
  default     = "cguertin.dev"
}

variable "router_ip" {
  description = "Router IP address"
  type        = string
  default     = "173.179.103.20"
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
    "mesh.k8s",
    "pihole.k8s",
    "traefik.k8s",
    "network.k8s",
    "monitoring.k8s",
    "prometheus.monitoring.k8s",
    "alertmanager.monitoring.k8s",
  ]
}
