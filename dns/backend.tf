terraform {
  backend "remote" {
    organization = "cguertin"
    workspaces {
      name = "infra"
    }
  }

  required_version = ">= 1.4.0"
}
