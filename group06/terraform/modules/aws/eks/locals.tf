locals {
  aws_auth = <<EOF
- rolearn: arn:aws:iam::570972270133:role/eks_admins
  username: admins
  groups:
    - system:masters
- rolearn: ${aws_iam_role.workers[0].arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
EOF

  gpu_instance_types = [
    "g4dn.xlarge",
    "g4dn.2xlarge",
    "g4dn.4xlarge",
    "g4dn.8xlarge",
    "g4dn.12xlarge",
    "g4dn.16xlarge",
    "g4dn.metal",
    "p2.xlarge",
    "p2.8xlarge",
    "p2.16xlarge",
    "p3.2xlarge",
    "p3.8xlarge",
    "p3.16xlarge",
    "p3dn.24xlarge"
  ]

  application_lb = {
    for load_balancer in keys(var.load_balancers):
      load_balancer => var.load_balancers[load_balancer].load_balancer_type == "application"
  }
  network_lb = {
    for load_balancer in keys(var.load_balancers):
      load_balancer => var.load_balancers[load_balancer].load_balancer_type == "network"
  }


  vpc_cidr_blocks = distinct(concat([data.aws_vpc.vpc.cidr_block], data.aws_vpc.vpc.cidr_block_associations[*].cidr_block))
  ingress_fqdn   = try(
    trimsuffix(aws_route53_record.ingress_private["ingress"].fqdn, "."),
    aws_eks_cluster.cluster.endpoint
  )

  cluster_tags = {
    "kubernetes.io/cluster/${var.name}" = "owned"
    KubernetesCluster = var.name
  }

  ## Workers ##
  workers_defaults = {
    subnets               = var.workers_defaults.subnets            != null ? var.workers_defaults.subnets            : var.private_subnets
    instance_types        = var.workers_defaults.instance_types     != null ? var.workers_defaults.instance_types     : []
    image_id              = var.workers_defaults.image_id           != null ? var.workers_defaults.image_id           : data.aws_ami.eks_worker.image_id
    max_size              = var.workers_defaults.max_size           != null ? var.workers_defaults.max_size           : 0
    min_size              = var.workers_defaults.min_size           != null ? var.workers_defaults.min_size           : 0
    desired_capacity      = var.workers_defaults.desired_capacity   != null ? var.workers_defaults.desired_capacity   : 0
    enable_spot           = var.workers_defaults.enable_spot        != null ? var.workers_defaults.enable_spot        : false
    enable_autoscaling    = var.workers_defaults.enable_autoscaling != null ? var.workers_defaults.enable_autoscaling : false
    enabled_metrics       = var.workers_defaults.enabled_metrics    != null ? var.workers_defaults.enabled_metrics    : []
    capacity_rebalance    = var.workers_defaults.capacity_rebalance != null ? var.workers_defaults.capacity_rebalance : false
    labels                = var.workers_defaults.labels             != null ? var.workers_defaults.labels             : {}
    taints                = var.workers_defaults.taints             != null ? var.workers_defaults.taints             : {}
    tags                  = var.workers_defaults.tags               != null ? var.workers_defaults.tags               : {}
    block_device_mappings = (
      var.workers_defaults.block_device_mappings != null ?
      {for device, config in var.workers_defaults.block_device_mappings:
        device => merge(
          config,
          {
            delete_on_termination = config.delete_on_termination != null ? config.delete_on_termination : true
            encrypted             = config.encrypted             != null ? config.encrypted             : true
          }
        )
      } :
      {}
    )
  }

  workers = {for worker, config in var.workers:
    worker => {
      subnets               = config.subnets            != null ? config.subnets            : local.workers_defaults.subnets
      instance_types        = config.instance_types     != null ? config.instance_types     : local.workers_defaults.instance_types
      image_id              = config.image_id           != null ? config.image_id           : local.workers_defaults.image_id
      max_size              = config.max_size           != null ? config.max_size           : local.workers_defaults.max_size
      min_size              = config.min_size           != null ? config.min_size           : local.workers_defaults.min_size
      desired_capacity      = config.desired_capacity   != null ? config.desired_capacity   : local.workers_defaults.desired_capacity
      enable_spot           = config.enable_spot        != null ? config.enable_spot        : local.workers_defaults.enable_spot
      enable_autoscaling    = config.enable_autoscaling != null ? config.enable_autoscaling : local.workers_defaults.enable_autoscaling
      enabled_metrics       = config.enabled_metrics    != null ? config.enabled_metrics    : local.workers_defaults.enabled_metrics
      capacity_rebalance    = config.capacity_rebalance != null ? config.capacity_rebalance : local.workers_defaults.capacity_rebalance
      labels                = merge(local.workers_defaults.labels, config.labels != null ? config.labels : {})
      taints                = merge(local.workers_defaults.taints, config.taints != null ? config.taints : {})
      tags                  = merge(local.workers_defaults.tags,   config.tags   != null ? config.tags   : {})
      block_device_mappings = (
        config.block_device_mappings != null ?
        merge(
          local.workers_defaults.block_device_mappings,
          {for device, device_config in config.block_device_mappings:
            device => merge(
              device_config,
              {
                delete_on_termination = device_config.delete_on_termination != null ? device_config.delete_on_termination : true
                encrypted             = device_config.encrypted             != null ? device_config.encrypted             : true
              }
            )
          }
        ) :
        local.workers_defaults.block_device_mappings
      )
      mixed_instances_policy = (
        config.mixed_instances_policy != null ?
        merge(
          config.mixed_instances_policy,
          {
            on_demand_allocation_strategy = (
              config.mixed_instances_policy.on_demand_allocation_strategy != null ?
              config.mixed_instances_policy.on_demand_allocation_strategy :
              "prioritized"
            )
            on_demand_percentage_above_base_capacity = (
              config.mixed_instances_policy.on_demand_percentage_above_base_capacity != null ?
              config.mixed_instances_policy.on_demand_percentage_above_base_capacity :
              (
                config.enable_spot ? 0 : 100
              )
            )
            spot_allocation_strategy = (
              config.mixed_instances_policy.spot_allocation_strategy != null ?
              config.mixed_instances_policy.spot_allocation_strategy :
              "lowest-price"
            )
          }
        ) :
        {}
      )
    }
  }
}
