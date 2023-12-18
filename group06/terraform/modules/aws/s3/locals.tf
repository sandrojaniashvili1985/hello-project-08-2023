locals {
  s3_defaults = {
    policy                 = var.s3_defaults.policy
    cors_rules             = var.s3_defaults.cors_rules          != null ? var.s3_defaults.cors_rules          : tolist([])
    prefix                 = var.s3_defaults.prefix              != null ? var.s3_defaults.prefix              : ""
    acl                    = var.s3_defaults.acl                 != null ? var.s3_defaults.acl                 : "private"
    grant                  = var.s3_defaults.grant               != null ? var.s3_defaults.grant               : tolist([])
    force_destroy          = var.s3_defaults.force_destroy       != null ? var.s3_defaults.force_destroy       : false
    acceleration_status    = var.s3_defaults.acceleration_status != null ? var.s3_defaults.acceleration_status : false
    public_access          = (
      var.s3_defaults.public_access != null ?
      {
        block_public_acls       = var.s3_defaults.public_access.block_public_acls       != null ? var.s3_defaults.public_access.block_public_acls       : true
        block_public_policy     = var.s3_defaults.public_access.block_public_policy     != null ? var.s3_defaults.public_access.block_public_policy     : true
        ignore_public_acls      = var.s3_defaults.public_access.ignore_public_acls      != null ? var.s3_defaults.public_access.ignore_public_acls      : false
        restrict_public_buckets = var.s3_defaults.public_access.restrict_public_buckets != null ? var.s3_defaults.public_access.restrict_public_buckets : false
      } :
      {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = false
        restrict_public_buckets = false
      }
    )
    versioning             = (
      var.s3_defaults.versioning != null ?
      {
        enabled    = var.s3_defaults.versioning.enabled    != null ? var.s3_defaults.versioning.enabled    : false
        mfa_delete = var.s3_defaults.versioning.mfa_delete != null ? var.s3_defaults.versioning.mfa_delete : false
      } :
      {
        enabled    = false
        mfa_delete = false
      }
    )
    logging                = (
      var.s3_defaults.logging != null ?
      {
        enabled       = var.s3_defaults.logging.enabled != null ? var.s3_defaults.logging.enabled : false
        target_bucket = var.s3_defaults.logging.target_bucket
        target_prefix = var.s3_defaults.logging.target_prefix
      } :
      {
        enabled       = false
        target_bucket = null
        target_prefix = null
      }
    )
    server_side_encryption = (
      var.s3_defaults.server_side_encryption != null ?
      {
        create_kms_key                          = var.s3_defaults.server_side_encryption.create_kms_key     != null ? var.s3_defaults.server_side_encryption.create_kms_key     : false
        bucket_key_enabled                      = var.s3_defaults.server_side_encryption.bucket_key_enabled != null ? var.s3_defaults.server_side_encryption.bucket_key_enabled : false
        apply_server_side_encryption_by_default = {
          sse_algorithm     = var.s3_defaults.server_side_encryption.apply_server_side_encryption_by_default.sse_algorithm
          kms_master_key_id = var.s3_defaults.server_side_encryption.apply_server_side_encryption_by_default.kms_master_key_id
        }
      } :
      null
    )
    tags                   = (
      var.s3_defaults.tags != null ?
      merge(
        var.tags,
        var.s3_defaults.tags
      ) :
      var.tags
    )
  }

  s3 = {for name, config in var.s3:
    name => {
      prefix                 = config.prefix              != null ? config.prefix              : local.s3_defaults.prefix
      name                   = config.name                != null ? config.name                : "${var.name}-${name}"
      policy                 = config.policy              != null ? config.policy              : local.s3_defaults.policy
      acl                    = config.acl                 != null ? config.acl                 : local.s3_defaults.acl
      grant                  = config.grant               != null ? config.grant               : local.s3_defaults.grant
      force_destroy          = config.force_destroy       != null ? config.force_destroy       : local.s3_defaults.force_destroy
      acceleration_status    = config.acceleration_status != null ? config.acceleration_status : local.s3_defaults.acceleration_status
      replication            = config.replication         != null ? config.replication         : tomap({})
      public_access          = (
        config.public_access != null ?
        {
          block_public_acls       = config.public_access.block_public_acls       != null ? config.public_access.block_public_acls       : local.s3_defaults.public_access.block_public_acls
          block_public_policy     = config.public_access.block_public_policy     != null ? config.public_access.block_public_policy     : local.s3_defaults.public_access.block_public_policy
          ignore_public_acls      = config.public_access.ignore_public_acls      != null ? config.public_access.ignore_public_acls      : local.s3_defaults.public_access.ignore_public_acls
          restrict_public_buckets = config.public_access.restrict_public_buckets != null ? config.public_access.restrict_public_buckets : local.s3_defaults.public_access.restrict_public_buckets
        } :
        local.s3_defaults.public_access
      )
      cors_rules      = (
        config.cors_rules != null ?
        [for cors_rule in config.cors_rules:
          {
            allowed_methods = cors_rule.allowed_methods
            allowed_origins = cors_rule.allowed_origins
            max_age_seconds = cors_rule.max_age_seconds
            allowed_headers = cors_rule.allowed_headers != null ? cors_rule.allowed_headers : tolist([])
            expose_headers  = cors_rule.expose_headers  != null ? cors_rule.expose_headers  : tolist([])
          }
        ] :
        local.s3_defaults.cors_rules
      )
      lifecycle_rules = (
        config.lifecycle_rules != null ?
        [for lifecycle_rule in config.lifecycle_rules:
          {
            enabled                                = lifecycle_rule.enabled
            id                                     = lifecycle_rule.id
            prefix                                 = lifecycle_rule.prefix
            tags                                   = lifecycle_rule.tags
            abort_incomplete_multipart_upload_days = lifecycle_rule.abort_incomplete_multipart_upload_days != null ? lifecycle_rule.abort_incomplete_multipart_upload_days : null
            transitions = (
              lifecycle_rule.transitions != null ?
              [for transition in lifecycle_rule.transitions:
                {
                  date          = transition.date != null ? transition.date : null
                  days          = transition.days != null ? transition.days : null
                  storage_class = transition.storage_class
                }
              ] :
              []
            )
            expiration = (
              lifecycle_rule.expiration != null ?
              {
                date                         = lifecycle_rule.expiration.date
                days                         = lifecycle_rule.expiration.days
                expired_object_delete_marker = lifecycle_rule.expiration.expired_object_delete_marker
              } :
              null
            )
            noncurrent_version_transition = lifecycle_rule.noncurrent_version_transition != null ? lifecycle_rule.noncurrent_version_transition : tomap({})
            noncurrent_version_expiration = lifecycle_rule.noncurrent_version_expiration != null ? lifecycle_rule.noncurrent_version_expiration : tomap({})
          }
        ] :
        toset([])
      )
      notifications          = (
        config.notifications != null ?
        {
          topic  = (
            config.notifications.topic != null ?
            {for topic_name, topic_config in config.notifications.topic:
              topic_name => {
                topic_arn     = topic_config.topic_arn
                events        = topic_config.events
                filter_prefix = topic_config.filter_prefix != null ? topic_config.filter_prefix : null
                filter_suffix = topic_config.filter_suffix != null ? topic_config.filter_suffix : null
              }
            } :
            tomap({})
          )
          queue  = (
            config.notifications.queue != null ?
            {for queue_name, queue_config in config.notifications.queue:
              queue_name => {
                queue_arn     = queue_config.queue_arn
                events        = queue_config.events
                filter_prefix = queue_config.filter_prefix != null ? queue_config.filter_prefix : null
                filter_suffix = queue_config.filter_suffix != null ? queue_config.filter_suffix : null
              }
            } :
            tomap({})
          )
          lambda = (
            config.notifications.lambda != null ?
            {for lambda_name, lambda_config in config.notifications.lambda:
              lambda_name => {
                lambda_arn    = lambda_config.lambda_arn
                events        = lambda_config.events
                filter_prefix = lambda_config.filter_prefix != null ? lambda_config.filter_prefix : null
                filter_suffix = lambda_config.filter_suffix != null ? lambda_config.filter_suffix : null
              }
            } :
            tomap({})
          )
        } :
        {
          topic  = tomap({})
          queue  = tomap({})
          lambda = tomap({})
        }
      )
      versioning             = (
        config.versioning != null ?
        {
          enabled    = config.versioning.enabled    != null ? config.versioning.enabled    :  local.s3_defaults.versioning.enabled
          mfa_delete = config.versioning.mfa_delete != null ? config.versioning.mfa_delete :  local.s3_defaults.versioning.mfa_delete
        } :
        local.s3_defaults.versioning
      )
      logging                = (
        config.logging != null ?
        {
          enabled       = config.logging.enabled       != null ? config.logging.enabled       : local.s3_defaults.logging.enabled
          target_bucket = config.logging.target_bucket != null ? config.logging.target_bucket : local.s3_defaults.logging.target_bucket
          target_prefix = config.logging.target_prefix != null ? config.logging.target_prefix : local.s3_defaults.logging.target_prefix
        } :
        local.s3_defaults.logging
      )
      server_side_encryption = (
        config.server_side_encryption != null ?
        {
          create_kms_key                          = config.server_side_encryption.create_kms_key     != null ? config.server_side_encryption.create_kms_key     : local.s3_defaults.server_side_encryption.create_kms_key
          bucket_key_enabled                      = config.server_side_encryption.bucket_key_enabled != null ? config.server_side_encryption.bucket_key_enabled : local.s3_defaults.server_side_encryption.bucket_key_enabled
          apply_server_side_encryption_by_default = {
            sse_algorithm     = config.server_side_encryption.apply_server_side_encryption_by_default.sse_algorithm     != null ? config.server_side_encryption.apply_server_side_encryption_by_default.sse_algorithm     : local.s3_defaults.server_side_encryption.apply_server_side_encryption_by_default.sse_algorithm
            kms_master_key_id = config.server_side_encryption.apply_server_side_encryption_by_default.kms_master_key_id != null ? config.server_side_encryption.apply_server_side_encryption_by_default.kms_master_key_id : local.s3_defaults.server_side_encryption.apply_server_side_encryption_by_default.kms_master_key_id
          }
        } :
        local.s3_defaults.server_side_encryption
      )
      tags                   = (
        config.tags != null ?
        merge(
          local.s3_defaults.tags,
          config.tags
        ) :
        local.s3_defaults.tags
      )
    } if config.create != false
  }
}
