## VPC ##
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v3.1"

  name                  = var.name
  cidr                  = var.cidr
  secondary_cidr_blocks = var.secondary_cidr_blocks

  azs                 = var.availability_zones
  public_subnets = [
    cidrsubnet(var.cidr, 3, 0),
    cidrsubnet(var.cidr, 3, 1),
    cidrsubnet(var.cidr, 3, 2)
  ]
  private_subnets = [
    cidrsubnet(var.cidr, 3, 3),
    cidrsubnet(var.cidr, 3, 4),
    cidrsubnet(var.cidr, 3, 5)
  ]
  database_subnets = [
    cidrsubnet(var.cidr, 8, 192),
    cidrsubnet(var.cidr, 8, 193),
    cidrsubnet(var.cidr, 8, 194)
  ]
  elasticache_subnets = [
    cidrsubnet(var.cidr, 8, 195),
    cidrsubnet(var.cidr, 8, 196),
    cidrsubnet(var.cidr, 8, 197)
  ]

  create_database_internet_gateway_route = var.create_database_internet_gateway_route
  create_database_subnet_route_table     = var.create_database_subnet_route_table

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway         = true
  single_nat_gateway         = true
  one_nat_gateway_per_az     = false
  manage_default_network_acl = false

  private_subnet_tags = var.private_subnet_tags
  public_subnet_tags  = var.public_subnet_tags
  tags                = merge(
    {
      Component = "VPC"
    },
    var.tags
  )
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> v3.1"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoints_sg.this_security_group_id]

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = concat(
        module.vpc.public_route_table_ids,
        module.vpc.private_route_table_ids
      )
      tags            = var.tags
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      policy              = data.aws_iam_policy_document.ecr_endpoint_policy.json
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      policy              = data.aws_iam_policy_document.ecr_endpoint_policy.json
    }
  }

  tags = var.tags
}
