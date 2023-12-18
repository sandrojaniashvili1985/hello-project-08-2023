locals {
  efs_mount_targets_default = {
    subnets               = tolist([])
    extra_security_groups = tolist([])
    extra_rules           = {
      ingress_with_cidr_blocks              = tolist([])
      ingress_with_source_security_group_id = tolist([])
    }
  }

  efs_defaults = {
    availability_zone_name          = var.efs_defaults.availability_zone_name
    kms_key_id                      = var.efs_defaults.kms_key_id
    lifecycle_policy                = var.efs_defaults.lifecycle_policy
    create_kms_key                  = var.efs_defaults.create_kms_key                  != null ? var.efs_defaults.create_kms_key                  : false
    encrypted                       = var.efs_defaults.encrypted                       != null ? var.efs_defaults.encrypted                       : false
    performance_mode                = var.efs_defaults.performance_mode                != null ? var.efs_defaults.performance_mode                : "generalPurpose"
    throughput_mode                 = var.efs_defaults.throughput_mode                 != null ? var.efs_defaults.throughput_mode                 : "bursting"
    provisioned_throughput_in_mibps = var.efs_defaults.provisioned_throughput_in_mibps != null ? var.efs_defaults.provisioned_throughput_in_mibps : 0
    mount_targets                   = (
      var.efs_defaults.mount_targets != null ?
      {
        subnets               = var.efs_defaults.mount_targets.subnets               != null ? var.efs_defaults.mount_targets.subnets               : tolist([])
        extra_security_groups = var.efs_defaults.mount_targets.extra_security_groups != null ? var.efs_defaults.mount_targets.extra_security_groups : tolist([])
        extra_rules           = (
          var.efs_defaults.mount_targets.extra_rules != null ?
          {
            ingress_with_cidr_blocks              = var.efs_defaults.mount_targets.extra_rules.ingress_with_cidr_blocks              != null ? var.efs_defaults.mount_targets.extra_rules.ingress_with_cidr_blocks              : tolist([])
            ingress_with_source_security_group_id = var.efs_defaults.mount_targets.extra_rules.ingress_with_source_security_group_id != null ? var.efs_defaults.mount_targets.extra_rules.ingress_with_source_security_group_id : tolist([])
          } :
          local.efs_mount_targets_default.extra_rules
        )
      } :
      local.efs_mount_targets_default
    )
    tags                            = (
      var.efs_defaults.tags != null ?
      merge(
        var.tags,
        var.efs_defaults.tags
      ) :
      var.tags
    )
  }

  efs = {for name, config in var.efs:
    name => {
      availability_zone_name          = config.availability_zone_name          != null ? config.availability_zone_name          : local.efs_defaults.availability_zone_name
      kms_key_id                      = config.kms_key_id                      != null ? config.kms_key_id                      : local.efs_defaults.kms_key_id
      create_kms_key                  = config.create_kms_key                  != null ? config.create_kms_key                  : local.efs_defaults.create_kms_key
      encrypted                       = config.encrypted                       != null ? config.encrypted                       : local.efs_defaults.encrypted
      performance_mode                = config.performance_mode                != null ? config.performance_mode                : local.efs_defaults.performance_mode
      throughput_mode                 = config.throughput_mode                 != null ? config.throughput_mode                 : local.efs_defaults.throughput_mode
      provisioned_throughput_in_mibps = config.provisioned_throughput_in_mibps != null ? config.provisioned_throughput_in_mibps : local.efs_defaults.provisioned_throughput_in_mibps
      lifecycle_policy                = config.lifecycle_policy                != null ? config.lifecycle_policy                : local.efs_defaults.lifecycle_policy
      mount_targets                   = (
        config.mount_targets != null ?
        {
          subnets               = config.mount_targets.subnets               != null ? config.mount_targets.subnets               : local.efs_defaults.mount_targets.subnets
          extra_security_groups = config.mount_targets.extra_security_groups != null ? config.mount_targets.extra_security_groups : local.efs_defaults.mount_targets.extra_security_groups
          extra_rules           = (
            config.mount_targets.extra_rules != null ?
            {
              ingress_with_cidr_blocks              = config.mount_targets.extra_rules.ingress_with_cidr_blocks              != null ? config.mount_targets.extra_rules.ingress_with_cidr_blocks              : local.efs_defaults.mount_targets.extra_rules.ingress_with_cidr_blocks
              ingress_with_source_security_group_id = config.mount_targets.extra_rules.ingress_with_source_security_group_id != null ? config.mount_targets.extra_rules.ingress_with_source_security_group_id : local.efs_defaults.mount_targets.extra_rules.ingress_with_source_security_group_id
            } :
            local.efs_defaults.mount_targets.extra_rules
          )
        } :
        local.efs_defaults.mount_targets
      )
      tags                            = (
        config.tags != null ?
        merge(
          local.efs_defaults.tags,
          config.tags
        ) :
        local.efs_defaults.tags
      )
    }
  }

  efs_mount_keys   = flatten([for name, config in local.efs:
    [for subnet in config.mount_targets.subnets:
      "${name}:${subnet}"
    ]
  ])
  efs_mount_values = flatten([for name, config in local.efs:
    [for subnet in config.mount_targets.subnets:
      {
        efs                   = name
        subnet_id             = subnet
        extra_security_groups = config.mount_targets.extra_security_groups
      }
    ]
  ])
  efs_mount        = zipmap(local.efs_mount_keys, local.efs_mount_values)

  efs_sg_rules_keys   = flatten([for name, config in local.efs:
    [
      [for rule in config.mount_targets.extra_rules.ingress_with_cidr_blocks:
        "${name}:${rule.from_port}:${rule.to_port}:${rule.protocol}:${join(",", rule.cidr_blocks)}"
      ],
      [for rule in config.mount_targets.extra_rules.ingress_with_source_security_group_id:
        "${name}:${rule.from_port}:${rule.to_port}:${rule.protocol}:${rule.source_security_group_id}"
      ]
    ]
  ])
  efs_sg_rules_values = flatten([for name, config in local.efs:
    [
      [for rule in config.mount_targets.extra_rules.ingress_with_cidr_blocks:
        {
          efs         = name
          description = rule.description
          from_port   = rule.from_port
          to_port     = rule.to_port
          protocol    = rule.protocol
          cidr_blocks = rule.cidr_blocks
        }
      ],
      [for rule in config.mount_targets.extra_rules.ingress_with_source_security_group_id:
        {
          efs                      = name
          description              = rule.description
          from_port                = rule.from_port
          to_port                  = rule.to_port
          protocol                 = rule.protocol
          source_security_group_id = rule.source_security_group_id
        }
      ]
    ]
  ])
  efs_sg_rules        = zipmap(local.efs_sg_rules_keys, local.efs_sg_rules_values)
}
