module "this" {
  source  = "../../modules/aws/eks"

  name                        = var.name
  kubernetes_version          = "1.21"
  public_key                  = local.secrets["ssh"]["public"]
  availability_zones          = data.terraform_remote_state.vpc.outputs.availability_zones
  parent_route53_zone_id      = data.aws_route53_zone.domain.zone_id
  private_subnets             = data.terraform_remote_state.vpc.outputs.private_subnets
  public_subnets              = data.terraform_remote_state.vpc.outputs.public_subnets
  vpc_id                      = data.terraform_remote_state.vpc.outputs.vpc_id
  manage_aws_auth             = true
  create_private_route53_zone = false

  workers_defaults = {
    subnets               = data.terraform_remote_state.vpc.outputs.private_subnets
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

resource "local_file" "kubeconfig" {
  filename = "kubeconfig.yaml"
  content  = module.this.kube_config
}
