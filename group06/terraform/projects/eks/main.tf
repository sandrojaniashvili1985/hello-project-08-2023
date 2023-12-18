## Backend ##
terraform {
  required_version = ">= 1.0.3"

  required_providers {
    local = "~> 2.1"
  }

  backend "s3" {
    bucket         = "tikal-hackathon-terraform-state"
    key            = "group07/eks"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

## AWS ##
provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = var.tags
  }
}

## Kubernetes ##
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
