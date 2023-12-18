variable "name" {
  description = "Env name to be prefixed to all resources"
  type        = string
}

variable "vpc" {
  description = "VPC data"
  type        = object({
    vpc_id             = string
    availability_zones = list(string)
    subnets            = object({
      private = list(string)
      public  = optional(list(string))
    })
    subnet_groups = object({
      database    = optional(string)
      elasticache = optional(string)
    })
  })
}

variable "tags" {
  description = "Global tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "s3_defaults" {
  description = "S3 Buckets default values"
  type        = object({
    prefix                 = optional(string)
    acl                    = optional(string)
    grant                  = optional(list(object({
      id          = optional(string)
      type        = string
      permissions = list(string)
      uri         = optional(string)
    })))
    policy                 = optional(string)
    force_destroy          = optional(bool)
    acceleration_status    = optional(bool)
    public_access          = optional(object({
      block_public_acls       = optional(bool)
      block_public_policy     = optional(bool)
      ignore_public_acls      = optional(bool)
      restrict_public_buckets = optional(bool)
    }))
    cors_rules             = optional(list(object({
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = optional(list(string))
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })))
    versioning             = optional(object({
      enabled    = optional(bool)
      mfa_delete = optional(bool)
    }))
    logging                = optional(object({
      enabled       = optional(bool)
      target_bucket = optional(string)
      target_prefix = optional(string)
    }))
    server_side_encryption = optional(object({
      create_kms_key                          = optional(bool)
      bucket_key_enabled                      = optional(bool)
      apply_server_side_encryption_by_default = object({
        sse_algorithm     = optional(string)
        kms_master_key_id = optional(string)
      })
    }))
    tags                   = optional(map(string))
  })
  default = {}
}

variable "s3" {
  description = "S3 Buckets to create"
  type        = map(object({
    create                 = optional(bool)
    name                   = optional(string)
    prefix                 = optional(string)
    acl                    = optional(string)
    grant                  = optional(list(object({
      id          = optional(string)
      type        = string
      permissions = list(string)
      uri         = optional(string)
    })))
    policy                 = optional(string)
    force_destroy          = optional(bool)
    acceleration_status    = optional(bool)
    public_access          = optional(object({
      block_public_acls       = optional(bool)
      block_public_policy     = optional(bool)
      ignore_public_acls      = optional(bool)
      restrict_public_buckets = optional(bool)
    }))
    cors_rules             = optional(list(object({
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = optional(list(string))
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })))
    versioning             = optional(object({
      enabled    = optional(bool)
      mfa_delete = optional(bool)
    }))
    logging                = optional(object({
      enabled       = optional(bool)
      target_bucket = optional(string)
      target_prefix = optional(string)
    }))
    lifecycle_rules        = optional(list(object({
      enabled                                = bool
      id                                     = string
      prefix                                 = optional(string)
      tags                                   = optional(map(string))
      abort_incomplete_multipart_upload_days = optional(number)
      expiration                             = optional(object({
        date                         = optional(string)
        days                         = optional(number)
        expired_object_delete_marker = optional(bool)
      }))
      transitions                            = optional(list(object({
        date          = optional(string)
        days          = optional(number)
        storage_class = optional(string)
      })))
      noncurrent_version_transition          = optional(object({
        days          = number
        storage_class = string
      }))
      noncurrent_version_expiration          = optional(object({
        days = string
      }))
    })))
    replication            = optional(map(object({
      enabled                          = bool
      priority                         = number
      delete_marker_replication_status = optional(bool)
      destination                      = object({
        bucket             = optional(string)
        storage_class      = optional(string)
        replica_kms_key_id = optional(string)
        account_id         = optional(string)
      })
      filter                           = optional(object({
        prefix = optional(string)
        tags   = optional(map(string))
      }))
      source_selection_criteria        = optional(object({
        sse_kms_encrypted_objects = bool
      }))
    })))
    server_side_encryption = optional(object({
      create_kms_key                          = optional(bool)
      bucket_key_enabled                      = optional(bool)
      apply_server_side_encryption_by_default = object({
        sse_algorithm     = optional(string)
        kms_master_key_id = optional(string)
      })
    }))
    notifications          = optional(object({
      topic  = optional(map(object({
        topic_arn     = string
        events        = list(string)
        filter_prefix = optional(string)
        filter_suffix = optional(string)
      })))
      queue  = optional(map(object({
        queue_arn     = string
        events        = list(string)
        filter_prefix = optional(string)
        filter_suffix = optional(string)
      })))
      lambda = optional(map(object({
        lambda_arn    = string
        events        = list(string)
        filter_prefix = optional(string)
        filter_suffix = optional(string)
      })))
    }))
    tags                   = optional(map(string))
  }))
  default = {}
}
