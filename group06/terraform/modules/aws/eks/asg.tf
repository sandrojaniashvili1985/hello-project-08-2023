## Locals ##
locals {
  worker_labels = {
    for worker, config in local.workers:
      worker => join(",", formatlist("%s=%s", keys(config.labels), values(config.labels)))
  }

  worker_taints = {
    for worker, config in local.workers:
      worker => join(",", formatlist("%s=%s", keys(config.taints), values(config.taints)))
  }

  worker_kubelet_extra_args = {
    for worker, config in local.workers:
      worker => {
        labels = "--node-labels=${local.worker_labels[worker]}"
        taints = "--register-with-taints=${local.worker_taints[worker]}"
      }
  }

  workers_user_data = {
    for worker, config in local.workers:
      worker => <<EOT
#cloud-config
runcmd:
  - >
    /etc/eks/bootstrap.sh
    --b64-cluster-ca '${aws_eks_cluster.cluster.certificate_authority[0].data}'
    --apiserver-endpoint '${aws_eks_cluster.cluster.endpoint}'
    --kubelet-extra-args '${join(" ", [local.worker_kubelet_extra_args[worker].labels, local.worker_kubelet_extra_args[worker].taints])}'
    '${aws_eks_cluster.cluster.name}'
EOT
  }
}


## Key Pair ##
resource "aws_key_pair" "key" {
  count = length(local.workers) > 0 ? 1 : 0

  key_name   = var.name
  public_key = var.public_key
}


## Workers ASG ##
resource "aws_autoscaling_group" "workers" {
  for_each = local.workers

  name                = "${var.name}-${each.key}"
  vpc_zone_identifier = each.value.subnets
  capacity_rebalance  = each.value.capacity_rebalance
  enabled_metrics     = each.value.enabled_metrics
  health_check_type   = "EC2"
  suspended_processes = ["AZRebalance"]
  target_group_arns   = compact([
    for target in keys(local.lb_targets_data):
      try(aws_lb_target_group.ingress[target].arn, "")
    if contains(var.load_balancers[local.lb_targets_data[target].load_balancer].worker_names, each.key)
  ])

  max_size         = each.value.max_size
  min_size         = each.value.min_size
  desired_capacity = each.value.desired_capacity

  dynamic "launch_template" {
    for_each = length(each.value.instance_types) > 1 || each.value.enable_spot ? [] : [""]

    content {
      id      = aws_launch_template.workers[each.key].id
      version = "$Latest"
    }
  }

  dynamic "mixed_instances_policy" {
    iterator = policy
    for_each = each.value.enable_spot ? [each.value.mixed_instances_policy]: []

    content {
      instances_distribution {
        on_demand_allocation_strategy            = try(policy.value.on_demand_allocation_strategy,            null)
        on_demand_base_capacity                  = try(policy.value.on_demand_base_capacity,                  null)
        on_demand_percentage_above_base_capacity = try(policy.value.on_demand_percentage_above_base_capacity, null)
        spot_allocation_strategy                 = try(policy.value.spot_allocation_strategy,                 null)
        spot_instance_pools                      = try(policy.value.spot_instance_pools,                      null)
        spot_max_price                           = try(policy.value.spot_max_price,                           null)

      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.workers[each.key].id
          version            = "$Latest"
        }

        dynamic "override" {
          for_each = each.value.instance_types

          content {
            instance_type = override.value
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${var.name}-${each.key}"
        propagate_at_launch = false
      },
      {
        key                 = "k8s.io/cluster-autoscaler/${each.value.enable_autoscaling ? "enabled" : "disabled"}"
        value               = "true"
        propagate_at_launch = false
      },
      {
        key                 = "k8s.io/cluster-autoscaler/${var.name}"
        value               = var.name
        propagate_at_launch = false
      }
    ],
    # Labels
    [for _key, _value in each.value.labels:
      {
        key                 = "k8s.io/cluster-autoscaler/node-template/label/${_key}"
        value               = _value,
        propagate_at_launch = false
      }
    ],
    # Taints
    [for _key, _value in each.value.taints:
      {
        key                 = "k8s.io/cluster-autoscaler/node-template/taint/${_key}"
        value               = _value,
        propagate_at_launch = false
      }
    ],
    # Tags
    [for _key, _value in merge(each.value.tags, local.cluster_tags, var.tags, data.aws_default_tags.current.tags):
      {
        key                 = _key
        value               = _value,
        propagate_at_launch = false
      }
    ]
  )
}

resource "aws_launch_template" "workers" {
  for_each = local.workers

  name                   = "${var.name}-${each.key}"
  key_name               = aws_key_pair.key[0].key_name
  image_id               = contains(local.gpu_instance_types, each.value.instance_types[0]) ? data.aws_ami.eks_gpu_worker.image_id : each.value.image_id
  instance_type          = each.value.instance_types[0]
  vpc_security_group_ids = concat(
    [for lb in keys(var.load_balancers):
      aws_security_group.lb[lb].id
      if local.network_lb[lb] && contains(var.load_balancers[lb].worker_names, each.key)
    ],
    [module.worker_nodes_sg.this_security_group_id]
  )
  ebs_optimized          = false
  user_data              = base64encode(replace(local.workers_user_data[each.key], "\r\n", "\n")) # convert windows line breaks to unix style

  iam_instance_profile {
    arn = aws_iam_instance_profile.workers[0].arn
  }

  dynamic "block_device_mappings" {
    iterator = mappings
    for_each = each.value.block_device_mappings

    content {
      device_name  = mappings.key
      no_device    = mappings.value.no_device
      virtual_name = mappings.value.virtual_name

      ebs {
        delete_on_termination = mappings.value.delete_on_termination
        encrypted             = mappings.value.encrypted
        iops                  = mappings.value.iops
        kms_key_id            = mappings.value.kms_key_id
        snapshot_id           = mappings.value.snapshot_id
        throughput            = mappings.value.throughput
        volume_size           = mappings.value.volume_size
        volume_type           = mappings.value.volume_type
      }
    }
  }

  dynamic "tag_specifications" {
    for_each = each.value.enable_spot ? range(1) : []

    content {
      resource_type = "spot-instances-request"
      tags = merge(
        {
          Name = "${var.name}-${each.key}"
        },
        data.aws_default_tags.current.tags,
        each.value.tags,
        local.cluster_tags,
        var.tags
      )
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name = "${var.name}-${each.key}"
      },
      data.aws_default_tags.current.tags,
      each.value.tags,
      local.cluster_tags,
      var.tags
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      {
        Name = "${var.name}-${each.key}"
      },
      data.aws_default_tags.current.tags,
      each.value.tags,
      local.cluster_tags,
      var.tags,
    )
  }

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    each.value.tags,
    local.cluster_tags,
    var.tags,
  )
}
