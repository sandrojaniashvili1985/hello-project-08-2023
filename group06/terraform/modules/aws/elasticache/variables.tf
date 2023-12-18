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

variable "elasticache_defaults" {
  description = "Global Elasticache default values"
  type        = object({
    version                    = optional(string)
    description                = optional(string)
    port                       = optional(number)
    node_type                  = optional(string)
    cluster                    = optional(object({
      cluster_mode            = optional(bool)
      node_groups             = optional(number)
      replicas_per_node_group = optional(number)
    }))
    automatic_failover_enabled = optional(bool)
    multi_az_enabled           = optional(bool)
    availability_zones         = optional(list(string))
    subnet_group_name          = optional(string)
    apply_immediately          = optional(bool)
    auto_minor_version_upgrade = optional(bool)
    maintenance_window         = optional(string)
    notification_topic_arn     = optional(string)
    auth_token                 = optional(string)
    create_kms_key             = optional(bool)
    kms_key_id                 = optional(string)
    transit_encryption_enabled = optional(bool)
    at_rest_encryption_enabled = optional(bool)
    final_snapshot_identifier  = optional(string)
    snapshot_arns              = optional(list(string))
    snapshot_name              = optional(string)
    snapshot_retention_limit   = optional(number)
    snapshot_window            = optional(string)
    parameters                 = optional(map(string))
    tags                       = optional(map(string))
    security_groups              = optional(object({
      extra_security_groups = optional(list(string))
      extra_rules           = optional(object({
        ingress_with_cidr_blocks              = optional(list(object({
          description = string
          from_port   = number
          to_port     = number
          protocol    = string
          cidr_blocks = list(string)
        })))
        ingress_with_source_security_group_id = optional(list(object({
          description              = string
          from_port                = number
          to_port                  = number
          protocol                 = string
          source_security_group_id = string
        })))
      }))
    }))
  })
  default = {}
}

variable "elasticache" {
  description = "Elasticache resources to create"
  type        = map(object({
    create                     = optional(bool)
    version                    = optional(string)
    description                = optional(string)
    port                       = optional(number)
    node_type                  = optional(string)
    cluster                    = optional(object({
      cluster_mode            = optional(bool)
      node_groups             = optional(number)
      replicas_per_node_group = optional(number)
    }))
    automatic_failover_enabled = optional(bool)
    multi_az_enabled           = optional(bool)
    availability_zones         = optional(list(string))
    security_group_ids         = optional(list(string))
    subnet_group_name          = optional(string)
    apply_immediately          = optional(bool)
    auto_minor_version_upgrade = optional(bool)
    maintenance_window         = optional(string)
    notification_topic_arn     = optional(string)
    auth_token                 = optional(string)
    create_kms_key             = optional(bool)
    kms_key_id                 = optional(string)
    transit_encryption_enabled = optional(bool)
    at_rest_encryption_enabled = optional(bool)
    final_snapshot_identifier  = optional(string)
    snapshot_arns              = optional(list(string))
    snapshot_name              = optional(string)
    snapshot_retention_limit   = optional(number)
    snapshot_window            = optional(string)
    parameters                 = optional(map(string))
    tags                       = optional(map(string))
    security_groups            = optional(object({
      extra_security_groups = optional(list(string))
      extra_rules           = optional(object({
        ingress_with_cidr_blocks              = optional(list(object({
          description = string
          from_port   = number
          to_port     = number
          protocol    = string
          cidr_blocks = list(string)
        })))
        ingress_with_source_security_group_id = optional(list(object({
          description              = string
          from_port                = number
          to_port                  = number
          protocol                 = string
          source_security_group_id = string
        })))
      }))
    }))
  }))
  default = {}
}
