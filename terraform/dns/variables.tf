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
  default     = "74.15.104.79"
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
    "ha", # home-assistant
    "photos",
    "adguard-home.k8s",
    "jellyfin.media",
    "sonarr.media",
    "radarr.media",
    "prowlarr.media",
    "qbittorrent.media",
    "sabnzbd.media",
    "auth.k8s",
    "gitops.k8s",
    "network.k8s",
    "monitoring.k8s",
    "rollout.gitops.k8s",
    "rook-ceph.k8s",
    "prometheus.monitoring.k8s",
    "alertmanager.monitoring.k8s",
  ]
}
