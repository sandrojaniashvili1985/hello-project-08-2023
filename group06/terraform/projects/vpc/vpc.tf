module "this" {
  source = "../../modules/aws/vpc"

  name           = var.name
  region         = "eu-west-1"
  create_bastion = true
  public_key     = local.secrets["ssh"]["public"]
  cidr           = "10.100.0.0/16"

  availability_zones = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c"
  ]

  public_subnets = [
    "10.100.0.0/19",
    "10.100.32.0/19",
    "10.100.64.0/19"
  ]

  private_subnets = [
    "10.100.96.0/19",
    "10.100.128.0/19",
    "10.100.160.0/19"
  ]

  database_subnets = [
    "10.100.192.0/24",
    "10.100.193.0/24",
    "10.100.194.0/24"
  ]

  elasticache_subnets = [
    "10.100.195.0/24",
    "10.100.196.0/24",
    "10.100.197.0/24"
  ]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}
