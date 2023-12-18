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

variable "lambda_defaults" {
  description = "Lambda functions default values"
  type        = object({
    runtime               = optional(string)
    description           = optional(string)
    env_vars              = optional(map(string))
    create_kms_key        = optional(bool)
    kms_key_arn           = optional(string)
    memory_size_in_mb     = optional(number)
    log_retention_in_days = optional(number)
    timeout               = optional(number)
    tags                  = optional(map(string))
    s3                    = optional(object({
      bucket = optional(string)
      key    = optional(string)
    }))
    permissions           = optional(map(object({
      action         = optional(string)
      principal      = string
      source_arn     = string
      source_account = optional(string)
    })))
    iam                   = optional(object({
      role_arn         = optional(string)
      manage_iam       = optional(bool)
      managed_policies = optional(list(string))
      extra_policies   = optional(map(object({
        description = optional(string)
        policy      = string
      })))
    }))
  })
  default = {}
}

variable "lambda" {
  description = "Lambda functions to create"
  type        = map(object({
    create                = optional(bool)
    name                  = optional(string)
    handler               = string
    runtime               = optional(string)
    description           = optional(string)
    env_vars              = optional(map(string))
    create_kms_key        = optional(bool)
    kms_key_arn           = optional(string)
    memory_size_in_mb     = optional(number)
    log_retention_in_days = optional(number)
    timeout               = optional(number)
    tags                  = optional(map(string))
    s3                    = optional(object({
      bucket = optional(string)
      key    = string
    }))
    permissions           = optional(map(object({
      action         = optional(string)
      principal      = string
      source_arn     = string
      source_account = optional(string)
    })))
    iam                   = optional(object({
      role_arn         = optional(string)
      manage_iam       = optional(bool)
      managed_policies = optional(list(string))
      extra_policies   = optional(map(object({
        description = optional(string)
        policy      = string
      })))
    }))
  }))
  default = {}
}
