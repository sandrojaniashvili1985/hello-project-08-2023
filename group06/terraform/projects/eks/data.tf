## Remote State ##
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config  = {
    bucket = "tikal-hackathon-terraform-state"
    key    = "group07/vpc"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "admin" {
  backend = "s3"
  config  = {
    bucket = "tikal-hackathon-terraform-state"
    key    = "admin/gitlab"
    region = "eu-west-1"
  }
}

## Secrets ##
data "aws_secretsmanager_secret_version" "secret" {
  secret_id = data.terraform_remote_state.admin.outputs.group_secrets[var.name].id
}

## Route53 ##
data "aws_route53_zone" "domain" {
  name         = var.domain
  private_zone = false
}

## EKS ##
data "aws_eks_cluster" "cluster" {
  name = module.this.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.this.cluster_id
}
