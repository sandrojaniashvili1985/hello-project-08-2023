variable config {
  type = any
}

variable "dependency" {
  type = any
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

data "aws_route53_zone" "domain" {
  name         = var.config.domain
  private_zone = false
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "../../modules/aws/eks"

  name                        = var.config.name
  kubernetes_version          = var.config.k8s_version
  public_key                  = var.dependency.hackinfra_gitlab_secrets.ssh.public
  availability_zones          = var.dependency.hackinfra_vpc.availability_zones
  parent_route53_zone_id      = data.aws_route53_zone.domain.zone_id
  private_subnets             = var.dependency.hackinfra_vpc.subnets.private
  public_subnets              = var.dependency.hackinfra_vpc.subnets.public
  vpc_id                      = var.dependency.hackinfra_vpc.vpc_id
  manage_aws_auth             = true
  create_private_route53_zone = false

  workers_defaults = {
    subnets               = var.dependency.hackinfra_vpc.subnets.private
    enable_autoscaling    = true
    capacity_rebalance    = false
    block_device_mappings = {
      "/dev/xvda" = {
        volume_size = 50
        volume_type = "gp2"
      }
    }
    enabled_metrics       = [
      "GroupDesiredCapacity",
      "GroupInServiceCapacity",
      "GroupPendingCapacity",
      "GroupMinSize",
      "GroupMaxSize",
      "GroupInServiceInstances",
      "GroupPendingInstances",
      "GroupStandbyInstances",
      "GroupStandbyCapacity",
      "GroupTerminatingCapacity",
      "GroupTerminatingInstances",
      "GroupTotalCapacity",
      "GroupTotalInstances"
    ]
  }

  workers                    = {
    system                   = {
      instance_types         = [
        "t3a.2xlarge"
      ]
      max_size               = 10
      min_size               = 2
      desired_capacity       = 2
      labels                 = {
        workload = "system"
      }
    }
    general-workers      = {
      instance_types         = [
        "t3a.large"
      ]
      max_size               = 25
      min_size               = 0
      desired_capacity       = 0
      labels                 = {
        workload = "general"
      }
    }
    general-workers-spot = {
      instance_types         = [
        "t3a.large",
        "t3.large",
        "t2.large"
      ]
      max_size               = 25
      min_size               = 0
      desired_capacity       = 0
      enable_spot            = true
      mixed_instances_policy = {
        spot_max_price = 0.08
      }
      labels                 = {
        workload = "general"
      }
    }
  }
}

output "cfout" {
  value = {
    name                   = module.eks.name
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
  sensitive = true
}
