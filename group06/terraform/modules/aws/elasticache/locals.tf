locals {
  elasticache_security_groups_default = {
    extra_security_groups = tolist([])
    extra_rules           = {
      ingress_with_cidr_blocks              = tolist([])
      ingress_with_source_security_group_id = tolist([])
    }
  }

  elasticache_defaults = {
    version                    = var.elasticache_defaults.version                    != null ? var.elasticache_defaults.version                    : "6.x"
    description                = var.elasticache_defaults.description                != null ? var.elasticache_defaults.description                : "Elasticache Cluster managed by Terraform"
    port                       = var.elasticache_defaults.port                       != null ? var.elasticache_defaults.port                       : 6379
    node_type                  = var.elasticache_defaults.node_type                  != null ? var.elasticache_defaults.node_type                  : "cache.t3.small"
    automatic_failover_enabled = var.elasticache_defaults.automatic_failover_enabled != null ? var.elasticache_defaults.automatic_failover_enabled : false
    multi_az_enabled           = var.elasticache_defaults.multi_az_enabled           != null ? var.elasticache_defaults.multi_az_enabled           : false
    availability_zones         = var.elasticache_defaults.availability_zones
    subnet_group_name          = var.elasticache_defaults.subnet_group_name          != null ? var.elasticache_defaults.subnet_group_name          : var.vpc.subnet_groups.elasticache
    apply_immediately          = var.elasticache_defaults.apply_immediately          != null ? var.elasticache_defaults.apply_immediately          : false
    auto_minor_version_upgrade = var.elasticache_defaults.auto_minor_version_upgrade != null ? var.elasticache_defaults.auto_minor_version_upgrade : true
    maintenance_window         = var.elasticache_defaults.maintenance_window         != null ? var.elasticache_defaults.maintenance_window         : "thu:02:00-thu:03:00"
    notification_topic_arn     = var.elasticache_defaults.notification_topic_arn
    auth_token                 = var.elasticache_defaults.auth_token
    kms_key_id                 = var.elasticache_defaults.kms_key_id
    create_kms_key             = var.elasticache_defaults.create_kms_key             != null ? var.elasticache_defaults.create_kms_key             : false
    transit_encryption_enabled = var.elasticache_defaults.transit_encryption_enabled != null ? var.elasticache_defaults.transit_encryption_enabled : false
    at_rest_encryption_enabled = var.elasticache_defaults.at_rest_encryption_enabled != null ? var.elasticache_defaults.at_rest_encryption_enabled : false
    snapshot_arns              = var.elasticache_defaults.snapshot_arns
    snapshot_name              = var.elasticache_defaults.snapshot_name
    snapshot_retention_limit   = var.elasticache_defaults.snapshot_retention_limit   != null ? var.elasticache_defaults.snapshot_retention_limit   : 0
    snapshot_window            = var.elasticache_defaults.snapshot_window
    parameters                 = var.elasticache_defaults.parameters                 != null ? var.elasticache_defaults.parameters                 : {}
    cluster                    = (
      var.elasticache_defaults.cluster != null ?
      {
        cluster_mode            = var.elasticache_defaults.cluster.cluster_mode            != null ? var.elasticache_defaults.cluster.cluster_mode            : false
        node_groups             = var.elasticache_defaults.cluster.node_groups             != null ? var.elasticache_defaults.cluster.node_groups             : 1
        replicas_per_node_group = var.elasticache_defaults.cluster.replicas_per_node_group != null ? var.elasticache_defaults.cluster.replicas_per_node_group : 0
      } :
      {
        cluster_mode            = false
        node_groups             = 1
        replicas_per_node_group = 0
      }
    )
    security_groups                   = (
      var.elasticache_defaults.security_groups != null ?
      {
        extra_security_groups = var.elasticache_defaults.security_groups.extra_security_groups != null ? var.elasticache_defaults.security_groups.extra_security_groups : tolist([])
        extra_rules           = (
          var.elasticache_defaults.security_groups.extra_rules != null ?
          {
            ingress_with_cidr_blocks              = var.elasticache_defaults.security_groups.extra_rules.ingress_with_cidr_blocks              != null ? var.elasticache_defaults.security_groups.extra_rules.ingress_with_cidr_blocks              : tolist([])
            ingress_with_source_security_group_id = var.elasticache_defaults.security_groups.extra_rules.ingress_with_source_security_group_id != null ? var.elasticache_defaults.security_groups.extra_rules.ingress_with_source_security_group_id : tolist([])
          } :
          local.elasticache_security_groups_default.extra_rules
        )
      } :
      local.elasticache_security_groups_default
    )
    tags                         = (
      var.elasticache_defaults.tags != null ?
      merge(
        var.tags,
        var.elasticache_defaults.tags
      ) :
      var.tags
    )
  }

  elasticache = {for name, config in var.elasticache:
    name => {
      version                    = config.version                    != null ? config.version                    : local.elasticache_defaults.version
      description                = config.description                != null ? config.description                : local.elasticache_defaults.description
      port                       = config.port                       != null ? config.port                       : local.elasticache_defaults.port
      node_type                  = config.node_type                  != null ? config.node_type                  : local.elasticache_defaults.node_type
      automatic_failover_enabled = config.automatic_failover_enabled != null ? config.automatic_failover_enabled : local.elasticache_defaults.automatic_failover_enabled
      multi_az_enabled           = config.multi_az_enabled           != null ? config.multi_az_enabled           : local.elasticache_defaults.multi_az_enabled
      availability_zones         = config.availability_zones         != null ? config.availability_zones         : local.elasticache_defaults.availability_zones
      subnet_group_name          = config.subnet_group_name          != null ? config.subnet_group_name          : local.elasticache_defaults.subnet_group_name
      apply_immediately          = config.apply_immediately          != null ? config.apply_immediately          : local.elasticache_defaults.apply_immediately
      auto_minor_version_upgrade = config.auto_minor_version_upgrade != null ? config.auto_minor_version_upgrade : local.elasticache_defaults.auto_minor_version_upgrade
      maintenance_window         = config.maintenance_window         != null ? config.maintenance_window         : local.elasticache_defaults.maintenance_window
      notification_topic_arn     = config.notification_topic_arn
      auth_token                 = config.auth_token
      kms_key_id                 = config.kms_key_id
      create_kms_key             = config.create_kms_key             != null ? config.create_kms_key             : local.elasticache_defaults.create_kms_key
      transit_encryption_enabled = config.transit_encryption_enabled != null ? config.transit_encryption_enabled : false
      at_rest_encryption_enabled = config.at_rest_encryption_enabled != null ? config.at_rest_encryption_enabled : false
      snapshot_arns              = config.snapshot_arns
      snapshot_name              = config.snapshot_name
      snapshot_retention_limit   = config.snapshot_retention_limit   != null ? config.snapshot_retention_limit   : 0
      snapshot_window            = config.snapshot_window
      parameters                 = (
        config.parameters != null ?
        merge(
          local.elasticache_defaults.parameters,
          config.parameters
        ) :
        local.elasticache_defaults.parameters
      )
      cluster                    = (
        config.cluster != null ?
        {
          cluster_mode            = config.cluster.cluster_mode            != null ? config.cluster.cluster_mode            : local.elasticache_defaults.cluster.cluster_mode
          node_groups             = config.cluster.node_groups             != null ? config.cluster.node_groups             : local.elasticache_defaults.cluster.node_groups
          replicas_per_node_group = config.cluster.replicas_per_node_group != null ? config.cluster.replicas_per_node_group : local.elasticache_defaults.cluster.replicas_per_node_group
        } :
        local.elasticache_defaults.cluster
      )
      security_groups                   = (
        config.security_groups != null ?
        {
          extra_security_groups = config.security_groups.extra_security_groups != null ? config.security_groups.extra_security_groups : local.elasticache_defaults.security_groups.extra_security_groups
          extra_rules           = (
            config.security_groups.extra_rules != null ?
            {
              ingress_with_cidr_blocks              = config.security_groups.extra_rules.ingress_with_cidr_blocks              != null ? config.security_groups.extra_rules.ingress_with_cidr_blocks              : local.elasticache_defaults.security_groups.extra_rules.ingress_with_cidr_blocks
              ingress_with_source_security_group_id = config.security_groups.extra_rules.ingress_with_source_security_group_id != null ? config.security_groups.extra_rules.ingress_with_source_security_group_id : local.elasticache_defaults.security_groups.extra_rules.ingress_with_source_security_group_id
            } :
            local.elasticache_defaults.security_groups.extra_rules
          )
        } :
        local.elasticache_defaults.security_groups
      )
      tags                         = (
        config.tags != null ?
        merge(
          var.tags,
          config.tags
        ) :
        local.elasticache_defaults.tags
      )
    } if config.create != false
  }

  elasticache_sg_rules_keys   = flatten([for name, config in local.elasticache:
    [
      [for rule in config.security_groups.extra_rules.ingress_with_cidr_blocks:
        "${name}:${rule.from_port}:${rule.to_port}:${rule.protocol}:${join(",", rule.cidr_blocks)}"
      ],
      [for rule in config.security_groups.extra_rules.ingress_with_source_security_group_id:
        "${name}:${rule.from_port}:${rule.to_port}:${rule.protocol}:${rule.source_security_group_id}"
      ]
    ]
  ])
  elasticache_sg_rules_values = flatten([for name, config in local.elasticache:
    [
      [for rule in config.security_groups.extra_rules.ingress_with_cidr_blocks:
        {
          elasticache = name
          description = rule.description
          from_port   = rule.from_port
          to_port     = rule.to_port
          protocol    = rule.protocol
          cidr_blocks = rule.cidr_blocks
        }
      ],
      [for rule in config.security_groups.extra_rules.ingress_with_source_security_group_id:
        {
          elasticache              = name
          description              = rule.description
          from_port                = rule.from_port
          to_port                  = rule.to_port
          protocol                 = rule.protocol
          source_security_group_id = rule.source_security_group_id
        }
      ]
    ]
  ])
  elasticache_sg_rules        = zipmap(local.elasticache_sg_rules_keys, local.elasticache_sg_rules_values)
}
