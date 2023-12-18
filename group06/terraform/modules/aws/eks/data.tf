## Data ##
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_default_tags" "current" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_route53_zone" "parent" {
  count = anytrue([var.create_public_route53_zone, var.create_private_route53_zone]) ? 1 : 0

  zone_id  = var.parent_route53_zone_id
}

data "aws_ec2_instance_type" "gpu" {
  for_each = toset(local.gpu_instance_types)

  instance_type = each.value
}

data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.kubernetes_version}-v*"]
  }
}

data "aws_ami" "eks_gpu_worker" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-gpu-node-${var.kubernetes_version}-v*"]
  }
}
