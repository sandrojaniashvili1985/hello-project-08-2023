## Security Groups ##
module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> v3.0"

  use_name_prefix = false
  create          = var.create_bastion

  name   = "${var.name}-bastion"
  vpc_id = module.vpc.vpc_id

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  ingress_cidr_blocks = var.bastion_ssh_cidr
  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      description = "Bastion SSH"
    }
  ]

  tags = merge(
    {
      Name      = "${var.name}-bastion"
      Component = "Bastion"
    },
    var.tags
  )
}

module "vpc_endpoints_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> v3.0"

  use_name_prefix = false

  name   = "${var.name}-vpc-endpoints"
  vpc_id = module.vpc.vpc_id

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  ingress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      description = "ECR HTTPS"
    }
  ]

  tags = merge(
    {
      Name      = "${var.name}-vpc-endpoints"
      Component = "Endpoint"
    },
    var.tags
  )
}
