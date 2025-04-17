terraform {
  backend "remote" {
    organization = "cguertin"
    workspaces {
      name = "infra-aws"
    }
  }
  required_version = ">= 1.4.0"
}
