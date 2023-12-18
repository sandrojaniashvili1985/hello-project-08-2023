locals {
  lambda_defaults = {
    runtime               = var.lambda_defaults.runtime               != null ? var.lambda_defaults.runtime               : "python3.7"
    description           = var.lambda_defaults.description           != null ? var.lambda_defaults.description           : "Lambda Function managed by Terraform"
    env_vars              = var.lambda_defaults.env_vars              != null ? var.lambda_defaults.env_vars              : {}
    create_kms_key        = var.lambda_defaults.create_kms_key        != null ? var.lambda_defaults.create_kms_key        : false
    kms_key_arn           = var.lambda_defaults.kms_key_arn
    memory_size_in_mb     = var.lambda_defaults.memory_size_in_mb     != null ? var.lambda_defaults.memory_size_in_mb     : 128
    log_retention_in_days = var.lambda_defaults.log_retention_in_days != null ? var.lambda_defaults.log_retention_in_days : 0
    timeout               = var.lambda_defaults.timeout               != null ? var.lambda_defaults.timeout               : 3
    permissions           = var.lambda_defaults.permissions           != null ? var.lambda_defaults.permissions           : tomap({})
    s3                    = (
      var.lambda_defaults.s3 != null ?
      {
        bucket = var.lambda_defaults.s3.bucket != null ? var.lambda_defaults.s3.bucket : ""
        key    = var.lambda_defaults.s3.key    != null ? var.lambda_defaults.s3.key    : ""
      } :
      {
        bucket = null
        key    = null
      }
    )
    iam                   = (
      var.lambda_defaults.iam != null ?
      {
        role_arn         = var.lambda_defaults.iam.role_arn
        manage_iam       = var.lambda_defaults.iam.manage_iam       != null ? var.lambda_defaults.iam.manage_iam       : true
        managed_policies = var.lambda_defaults.iam.managed_policies != null ? var.lambda_defaults.iam.managed_policies : tolist([])
        extra_policies   = var.lambda_defaults.iam.extra_policies   != null ? var.lambda_defaults.iam.extra_policies   : tomap({})
      } :
      {
        role_arn         = null
        manage_iam       = true
        managed_policies = tolist([])
        extra_policies   = tomap({})
      }
    )
    tags                  = (
      var.lambda_defaults.tags != null ?
      merge(
        var.tags,
        var.lambda_defaults.tags
      ) :
      var.tags
    )
  }

  lambda = {for name, config in var.lambda:
    name => {
      name                  = config.name                  != null ? config.name                  : "${var.name}_${name}"
      handler               = config.handler
      runtime               = config.runtime               != null ? config.runtime               : local.lambda_defaults.runtime
      description           = config.description           != null ? config.description           : local.lambda_defaults.description
      env_vars              = config.env_vars              != null ? config.env_vars              : local.lambda_defaults.env_vars
      create_kms_key        = config.create_kms_key        != null ? config.create_kms_key        : local.lambda_defaults.create_kms_key
      kms_key_arn           = config.kms_key_arn           != null ? config.kms_key_arn           : local.lambda_defaults.kms_key_arn
      memory_size_in_mb     = config.memory_size_in_mb     != null ? config.memory_size_in_mb     : local.lambda_defaults.memory_size_in_mb
      timeout               = config.timeout               != null ? config.timeout               : local.lambda_defaults.timeout
      log_retention_in_days = config.log_retention_in_days != null ? config.log_retention_in_days : local.lambda_defaults.log_retention_in_days
      s3                    = (
        config.s3 != null ?
        {
          bucket = config.s3.bucket != null ? config.s3.bucket : local.lambda_defaults.s3.bucket
          key    = config.s3.key    != null ? config.s3.key    : local.lambda_defaults.s3.key
        } :
        local.lambda_defaults.s3
      )
      permissions           = (
        config.permissions != null ?
        {for permission_name, permission_config in config.permissions:
          permission_name => {
            action         = permission_config.action         != null ? permission_config.action         : try(local.lambda_defaults.permissions[permission_name].action,         "lambda:InvokeFunction")
            principal      = permission_config.principal      != null ? permission_config.principal      : try(local.lambda_defaults.permissions[permission_name].principal,      null)
            source_arn     = permission_config.source_arn     != null ? permission_config.source_arn     : try(local.lambda_defaults.permissions[permission_name].source_arn,     null)
            source_account = permission_config.source_account != null ? permission_config.source_account : try(local.lambda_defaults.permissions[permission_name].source_account, null)
          }
        } :
        local.lambda_defaults.permissions
      )
      iam                   = (
        config.iam != null ?
        {
          role_arn         = config.iam.role_arn         != null ? config.iam.role_arn         : local.lambda_defaults.iam.role_arn
          manage_iam       = config.iam.manage_iam       != null ? config.iam.manage_iam       : local.lambda_defaults.iam.manage_iam
          managed_policies = config.iam.managed_policies != null ? config.iam.managed_policies : local.lambda_defaults.iam.managed_policies
          extra_policies   = config.iam.extra_policies   != null ? config.iam.extra_policies   : local.lambda_defaults.iam.extra_policies
        } :
        local.lambda_defaults.iam
      )
      tags                  = (
        config.tags != null ?
        merge(
          local.lambda_defaults.tags,
          config.tags
        ) :
        local.lambda_defaults.tags
      )
    } if config.create != false
  }

  lambda_permissions_keys   = flatten([for name, config in local.lambda:
    [for permission_name, permission_config in config.permissions:
      "${name}:${permission_name}"
    ]
  ])
  lambda_permissions_values = flatten([for name, config in local.lambda:
    [for permission_name, permission_config in config.permissions:
      {
        lambda         = name
        name           = permission_name
        action         = permission_config.action
        principal      = permission_config.principal
        source_arn     = permission_config.source_arn
        source_account = permission_config.source_account
      }
    ]
  ])
  lambda_permissions        = zipmap(local.lambda_permissions_keys, local.lambda_permissions_values)

  lambda_managed_policies_keys   = flatten([for name, config in local.lambda:
    [for policy in config.iam.managed_policies:
      "${name}:${policy}"
    if config.iam.manage_iam
    ]
  ])
  lambda_managed_policies_values = flatten([for name, config in local.lambda:
    [for policy in config.iam.managed_policies:
      {
        lambda = name
        name   = policy
      }
    if config.iam.manage_iam
    ]
  ])
  lambda_managed_policies        = zipmap(local.lambda_managed_policies_keys, local.lambda_managed_policies_values)

  lambda_extra_policies_keys   = flatten([for name, config in local.lambda:
    [for policy_name, policy_config in config.iam.extra_policies:
      "${name}:${policy_name}"
    if config.iam.manage_iam
    ]
  ])
  lambda_extra_policies_values = flatten([for name, config in local.lambda:
    [for policy_name, policy_config in config.iam.extra_policies:
      {
        lambda      = name
        name        = policy_name
        description = policy_config.description
        policy      = policy_config.policy
      }
    if config.iam.manage_iam
    ]
  ])
  lambda_extra_policies        = zipmap(local.lambda_extra_policies_keys, local.lambda_extra_policies_values)
}
