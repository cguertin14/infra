variable "educs_domain" {
  description = "The educs project domain URI"
  type        = string
  default     = "erabliereducoeursucre.com"
}

variable "educs_domains" {
  description = "A list of domains related to the educs project"
  type        = list(string)
  default = [
    "@",
    "www",
    "api",
  ]
}
