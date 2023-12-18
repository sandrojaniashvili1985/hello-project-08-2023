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

variable "efs_defaults" {
  description = "Global EFS default values"
  type        = object({
    availability_zone_name          = optional(string)
    encrypted                       = optional(bool)
    create_kms_key                  = optional(bool)
    kms_key_id                      = optional(string)
    performance_mode                = optional(string)
    throughput_mode                 = optional(string)
    provisioned_throughput_in_mibps = optional(number)
    lifecycle_policy                = optional(object({
      transition_to_ia = string
    }))
    mount_targets                   = optional(object({
      subnets                  = optional(list(string))
      extra_security_groups    = optional(list(string))
      extra_rules              = optional(object({
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
    tags                            = optional(map(string))
  })
  default = {}
}

variable "efs" {
  description = "Elastic File System to create"
  type        = map(object({
    availability_zone_name          = optional(string)
    encrypted                       = optional(bool)
    create_kms_key                  = optional(bool)
    kms_key_id                      = optional(string)
    performance_mode                = optional(string)
    throughput_mode                 = optional(string)
    provisioned_throughput_in_mibps = optional(number)
    lifecycle_policy                = optional(object({
      transition_to_ia = string
    }))
    mount_targets                   = optional(object({
      subnets               = optional(list(string))
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
    tags                            = optional(map(string))
  }))
  default = {}
}
