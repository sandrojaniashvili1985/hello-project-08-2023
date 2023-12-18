## Backend ##
terraform {
  required_version = ">= 1.0.3"

  backend "s3" {
    bucket         = "tikal-hackathon-terraform-state"
    key            = "group07/vpc"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

## AWS ##
provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = merge(
      {
        "kubernetes.io/cluster/${var.name}" = "shared"
      },
      var.tags
    )
  }
}
