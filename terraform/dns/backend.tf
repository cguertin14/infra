terraform {
  backend "remote" {
    organization = "cguertin"
    workspaces {
      name = "infra-dns"
    }
  }

  required_version = ">= 1.4.0"
}
