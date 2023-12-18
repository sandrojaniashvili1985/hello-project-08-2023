resource "aws_s3_bucket" "this" {
  for_each = local.s3

  bucket              = "${each.value.prefix}${each.value.name}"
  acl                 = length(each.value.grant) > 0 ? null : each.value.acl
  policy              = each.value.policy
  force_destroy       = each.value.force_destroy
  acceleration_status = each.value.acceleration_status ? "Enabled" : "Suspended"
  tags                = merge(
    each.value.tags,
    {
      Name = "${each.value.prefix}${each.value.name}"
    }
  )

  versioning {
    enabled    = each.value.versioning.enabled
    mfa_delete = each.value.versioning.mfa_delete
  }

  dynamic "grant" {
    iterator = grant
    for_each = toset(each.value.grant)

    content {
      id          = grant.value.id
      type        = grant.value.type
      permissions = grant.value.permissions
      uri         = grant.value.uri
    }
  }

  dynamic "logging" {
    for_each = range(each.value.logging.enabled ? 1 : 0)

    content {
      target_bucket = each.value.logging.target_bucket
      target_prefix = each.value.logging.target_prefix
    }
  }

  dynamic "cors_rule" {
    iterator = rule
    for_each = each.value.cors_rules

    content {
      allowed_methods = rule.value.allowed_methods
      allowed_origins = rule.value.allowed_origins
      allowed_headers = rule.value.allowed_headers
      expose_headers  = rule.value.expose_headers
      max_age_seconds = rule.value.max_age_seconds
    }
  }

  dynamic "server_side_encryption_configuration" {
    for_each = range(each.value.server_side_encryption != null ? 1 : 0)

    content {
      rule {
        bucket_key_enabled = each.value.server_side_encryption.bucket_key_enabled

        apply_server_side_encryption_by_default {
          sse_algorithm     = each.value.server_side_encryption.apply_server_side_encryption_by_default.sse_algorithm
          kms_master_key_id = try(aws_kms_key.this[each.key].arn, each.value.server_side_encryption.apply_server_side_encryption_by_default.kms_master_key_id)
        }
      }
    }
  }

  dynamic "lifecycle_rule" {
    iterator = rule
    for_each = each.value.lifecycle_rules

    content {
      id                                     = rule.value.id
      enabled                                = rule.value.enabled
      abort_incomplete_multipart_upload_days = rule.value.abort_incomplete_multipart_upload_days
      prefix                                 = rule.value.prefix
      tags                                   = rule.value.tags

      dynamic "transition" {
        iterator = transition
        for_each = rule.value.transitions

        content {
          date          = transition.value.date
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = range(rule.value.expiration != null ? 1 : 0)

        content {
          date                         = rule.value.expiration.date
          days                         = rule.value.expiration.days
          expired_object_delete_marker = rule.value.expiration.expired_object_delete_marker
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition

        content {
          days          = rule.value.noncurrent_version_transition.days
          storage_class = rule.value.noncurrent_version_transition.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration

        content {
          days = rule.value.noncurrent_version_expiration.days
        }
      }
    }
  }

  dynamic "replication_configuration" {
    iterator = replication
    for_each = range(length(each.value.replication) > 0 ? 1 : 0)

    content {
      role = aws_iam_role.replication[each.key].arn

      dynamic "rules" {
        iterator = replication_rule
        for_each = each.value.replication

        content {
          id                               = replication_rule.key
          status                           = replication_rule.value.enabled ? "Enabled" : "Disabled"
          priority                         = replication_rule.value.priority
          delete_marker_replication_status = replication_rule.value.delete_marker_replication_status

          dynamic "filter" {
            for_each = range(replication_rule.value.filter != null ? 1 : 0)

            content {
              prefix = try(replication_rule.value.filter.prefix, "")
              tags   = try(replication_rule.value.filter.tags,   tomap({}))
            }
          }

          dynamic "source_selection_criteria" {
            for_each = range(try(replication_rule.value.source_selection_criteria.sse_kms_encrypted_objects, false) ? 1 : 0)

            content {
              sse_kms_encrypted_objects {
                enabled = true
              }
            }
          }

          destination {
            bucket             = replication_rule.value.destination.bucket
            storage_class      = replication_rule.value.destination.storage_class
            replica_kms_key_id = replication_rule.value.destination.replica_kms_key_id != null ? replication_rule.value.destination.replica_kms_key_id : try(aws_kms_key.this[replication_rule.value.destination.bucket].id, null)
            account_id         = replication_rule.value.destination.account_id

            dynamic "access_control_translation" {
              for_each = range(replication_rule.value.destination.account_id != null ? 1 : 0)

              content {
                owner = "Destination"
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ## TODO revert after this is fixed https://github.com/hashicorp/terraform-provider-aws/issues/6193
    ignore_changes = [
      acl,
      force_destroy,
      lifecycle_rule
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.s3

  bucket                  = aws_s3_bucket.this[each.key].id
  block_public_acls       = each.value.public_access.block_public_acls
  block_public_policy     = each.value.public_access.block_public_policy
  ignore_public_acls      = each.value.public_access.ignore_public_acls
  restrict_public_buckets = each.value.public_access.restrict_public_buckets
}

resource "aws_s3_bucket_notification" "this" {
  for_each = {
    for name, config in local.s3:
      name => config
    if anytrue([
      length(config.notifications.topic) > 0,
      length(config.notifications.queue) > 0,
      length(config.notifications.lambda) > 0
    ])
  }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "topic" {
    for_each = each.value.notifications.topic

    content {
      id            = topic.key
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }

  dynamic "queue" {
    for_each = each.value.notifications.queue

    content {
      id            = queue.key
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }

  dynamic "lambda_function" {
    for_each = each.value.notifications.lambda

    content {
      id                  = lambda_function.key
      lambda_function_arn = lambda_function.value.lambda_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }
}

resource "aws_kms_key" "this" {
  for_each = {
    for name, config in local.s3:
      name => config
    if config.server_side_encryption != null && config.server_side_encryption.create_kms_key && try(config.server_side_encryption.apply_server_side_encryption_by_default.sse_algorithm, null) == "aws:kms" && try(config.server_side_encryption.apply_server_side_encryption_by_default.kms_master_key_id, null) == null
  }

  description = "Encryption key for ${each.value.prefix}${var.name}-${each.key} S3 Bucket"
  tags        = merge(
    each.value.tags,
    {
      Name = "${each.value.prefix}${var.name}-${each.key}_s3"
    }
  )
}
