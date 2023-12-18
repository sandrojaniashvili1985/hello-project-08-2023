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

variable "sqs_defaults" {
  description = "Global SQS default values"
  type        = object({
    visibility_timeout_seconds        = optional(number)
    message_retention_seconds         = optional(number)
    max_message_size                  = optional(number)
    delay_seconds                     = optional(number)
    receive_wait_time_seconds         = optional(number)
    policy                            = optional(string)
    max_receive_count                 = optional(number)
    dlq_suffix                        = optional(string)
    fifo_queue                        = optional(bool)
    content_based_deduplication       = optional(bool)
    server_side_encryption            = optional(bool)
    create_kms_key                    = optional(bool)
    kms_master_key_id                 = optional(string)
    kms_data_key_reuse_period_seconds = optional(number)
    deduplication_scope               = optional(string)
    fifo_throughput_limit             = optional(string)
    tags                              = optional(map(string))
  })
  default = {}
}

variable "sqs" {
  description = "SQS queues to create"
  type        = map(object({
    visibility_timeout_seconds        = optional(number)
    message_retention_seconds         = optional(number)
    max_message_size                  = optional(number)
    delay_seconds                     = optional(number)
    receive_wait_time_seconds         = optional(number)
    policy                            = optional(string)
    max_receive_count                 = optional(number)
    dlq_suffix                        = optional(string)
    fifo_queue                        = optional(bool)
    content_based_deduplication       = optional(bool)
    server_side_encryption            = optional(bool)
    create_kms_key                    = optional(bool)
    kms_master_key_id                 = optional(string)
    kms_data_key_reuse_period_seconds = optional(number)
    deduplication_scope               = optional(string)
    fifo_throughput_limit             = optional(string)
    tags                              = optional(map(string))
  }))
  default = {}
}
