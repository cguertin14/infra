terraform {
  backend "remote" {
    organization = "cguertin"
    workspaces {
      name = "infra"
    }
  }

  required_version = ">= 0.14.0"
}
