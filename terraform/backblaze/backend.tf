terraform {
  backend "remote" {
    organization = "cguertin"
    workspaces {
      name = "infra-backblaze"
    }
  }
  required_version = ">= 1.4.0"
}
