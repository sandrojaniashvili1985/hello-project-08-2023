## Locals ##
locals {
  lb_security_rules_values = flatten([
    for lb in keys(var.load_balancers):
    [for rule in concat(var.load_balancers[lb].extra_security_groups.ingress_with_cidr_blocks, var.load_balancers[lb].extra_security_groups.ingress_with_source_security_group_id):
      {
        load_balancer = lb
        rule          = rule
      }
    ]
  ])

  lb_security_rules_keys = flatten([
    for lb in keys(var.load_balancers):
    [
      for rule in concat(var.load_balancers[lb].extra_security_groups.ingress_with_cidr_blocks, var.load_balancers[lb].extra_security_groups.ingress_with_source_security_group_id):
        "${lb}:${rule.from_port}:${rule.to_port}:${rule.protocol}:${lookup(rule, "source_security_group_id", join(",", lookup(rule, "cidr_blocks", [])))}"
    ]
  ])

  lb_security_rules_data = zipmap(local.lb_security_rules_keys, local.lb_security_rules_values)


  lb_targets_security_rules = concat(
    [for lb in keys(var.load_balancers):
      {for target in keys(var.load_balancers[lb].targets):
        "${lb}:${var.load_balancers[lb].targets[target].target_port}:${lower(var.load_balancers[lb].targets[target].target_protocol)}" => {
          load_balancer = lb
          port          = var.load_balancers[lb].targets[target].target_port
          protocol      = var.load_balancers[lb].targets[target].target_protocol
        }... if local.network_lb[lb]
      }
    ],
    [for lb in keys(var.load_balancers):
      {for target in keys(var.load_balancers[lb].targets):
        "${lb}:${var.load_balancers[lb].targets[target].health_check.port}:tcp" => {
          load_balancer = lb
          port          = var.load_balancers[lb].targets[target].health_check.port
          protocol      = "tcp"
        }... if local.network_lb[lb] && can(var.load_balancers[lb].targets[target].health_check.port)
      }
    ]
  )
  lb_targets_security_rules_data_merged = merge(flatten([local.lb_targets_security_rules])...)
  lb_targets_security_rules_data = {
    for rule in keys(local.lb_targets_security_rules_data_merged):
      rule => local.lb_targets_security_rules_data_merged[rule][0]
  }
}

## Security Groups ##
module "master_nodes_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> v3.0"

  create          = true
  use_name_prefix = true

  name   = "${var.name}-masters"
  vpc_id = var.vpc_id

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  ingress_with_self = [
    {
      rule        = "all-all"
      description = "All with self"
    }
  ]

  ingress_with_cidr_blocks = concat(
    var.masters_extra_security_rules.ingress_with_cidr_blocks,
    [for _ in range(var.cluster_endpoint_private_access ? 1 : 0):
      {
        rule        = "https-443-tcp"
        description = "API Private access from local VPC"
        cidr_blocks = join(",", local.vpc_cidr_blocks)
      }
    ]
  )

  ingress_with_source_security_group_id = var.masters_extra_security_rules.ingress_with_source_security_group_id

  number_of_computed_ingress_with_source_security_group_id = length(var.workers) > 0 ? 1 : 0
  computed_ingress_with_source_security_group_id           = concat(
    [for _ in range(length(var.workers) > 0 ? 1 : 0):
      {
        rule                     = "all-all"
        description              = "All with Workers"
        source_security_group_id = module.worker_nodes_sg.this_security_group_id
      }
    ]
  )

  tags = merge(
    {
      Name      = "${var.name}-masters"
      Cluster   = var.name
      Component = "Masters"
    },
    local.cluster_tags,
    var.tags
  )
}

module "worker_nodes_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> v3.0"

  create          = length(var.workers) > 0
  use_name_prefix = true

  name   = "${var.name}-workers"
  vpc_id = var.vpc_id

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  ingress_with_self = [
    {
      rule        = "all-all"
      description = "All with self"
    }
  ]

  ingress_with_cidr_blocks = [
    for rule in var.workers_extra_security_rules.ingress_with_cidr_blocks:
    {
      description = rule["description"]
      from_port   = rule["from_port"]
      to_port     = rule["to_port"]
      protocol    = rule["protocol"]
      cidr_blocks = join(",", rule["cidr_blocks"])
    }
  ]

  ingress_with_source_security_group_id = concat(
    [
      for _ in range(var.bastion_security_group_id != null ? 1 : 0):
      {
        rule                     = "ssh-tcp"
        description              = "SSH from bastion"
        source_security_group_id = var.bastion_security_group_id
      }
    ],
    [
      for rule in var.workers_extra_security_rules.ingress_with_source_security_group_id:
      {
        description              = rule["description"]
        from_port                = rule["from_port"]
        to_port                  = rule["to_port"]
        protocol                 = rule["protocol"]
        source_security_group_id = rule["source_security_group_id"]
      }
    ]
  )

  number_of_computed_ingress_with_source_security_group_id = length([for lb in keys(local.application_lb): lb if local.application_lb[lb]]) > 0 ? 2 : 1
  computed_ingress_with_source_security_group_id           = [
    {
      rule                     = "all-all"
      description              = "All with Masters"
      source_security_group_id = module.master_nodes_sg.this_security_group_id
    },
    {
      rule                     = "all-all"
      description              = "All with ingress ALB"
      source_security_group_id = module.ingress_alb_sg.this_security_group_id
    }
  ]

  tags = merge(
    {
      Name      = "${var.name}-workers"
      Cluster   = var.name
      Component = "Workers"
    },
    local.cluster_tags,
    var.tags
  )
}

module "ingress_alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> v3.0"

  create          = length([for lb in keys(local.application_lb): lb if local.application_lb[lb]]) > 0
  use_name_prefix = true

  name   = "${var.name}-ingress-alb"
  vpc_id = var.vpc_id

  number_of_computed_egress_with_source_security_group_id = 1
  computed_egress_with_source_security_group_id           = [
    {
      rule                     = "all-all"
      description              = "All with Workers"
      source_security_group_id = module.worker_nodes_sg.this_security_group_id
    }
  ]

  number_of_computed_ingress_with_source_security_group_id = 1
  computed_ingress_with_source_security_group_id           = [
    {
      rule                     = "all-all"
      description              = "All with Workers"
      source_security_group_id = module.worker_nodes_sg.this_security_group_id
    }
  ]

  tags = merge(
    {
      Name = "${var.name}-ingress-alb"
    },
    local.cluster_tags,
    var.tags
  )
}

## Ingress Security Groups ##
resource "aws_security_group" "lb" {
  for_each = var.load_balancers

  name        = "${var.name}-${each.key}"
  description = "${var.name}-${each.key}"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    local.cluster_tags,
    var.tags
  )
}

resource "aws_security_group_rule" "lb_ingress" {
  for_each = local.lb_security_rules_data

  type                     = "ingress"
  description              = each.value.rule.description
  security_group_id        = aws_security_group.lb[each.value.load_balancer].id
  from_port                = each.value.rule.from_port
  to_port                  = each.value.rule.to_port
  protocol                 = each.value.rule.protocol
  source_security_group_id = lookup(each.value.rule, "source_security_group_id", null)
  cidr_blocks              = lookup(each.value.rule, "cidr_blocks",              null)
}

resource "aws_security_group_rule" "nlb_ingress_targets" {
  for_each = local.lb_targets_security_rules_data

  type                     = "ingress"
  description              = each.key
  security_group_id        = aws_security_group.lb[each.value.load_balancer].id
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = lower(each.value.protocol) == "udp" ? "udp" : "tcp"
  cidr_blocks              = local.vpc_cidr_blocks
}

resource "aws_security_group_rule" "lb_egress" {
  for_each = var.load_balancers

  type              = "egress"
  security_group_id = aws_security_group.lb[each.key].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
