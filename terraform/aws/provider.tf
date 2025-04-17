provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      environment = "production"
      project     = "cguertin14/infra"
      owner       = "cguertin14"
    }
  }
}
