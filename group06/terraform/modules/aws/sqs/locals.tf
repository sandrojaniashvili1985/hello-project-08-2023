locals {
  sqs_defaults = {
    visibility_timeout_seconds        = var.sqs_defaults.visibility_timeout_seconds        != null ? var.sqs_defaults.visibility_timeout_seconds        : 30
    message_retention_seconds         = var.sqs_defaults.message_retention_seconds         != null ? var.sqs_defaults.message_retention_seconds         : 345600
    max_message_size                  = var.sqs_defaults.max_message_size                  != null ? var.sqs_defaults.max_message_size                  : 262144
    delay_seconds                     = var.sqs_defaults.delay_seconds                     != null ? var.sqs_defaults.delay_seconds                     : 0
    receive_wait_time_seconds         = var.sqs_defaults.receive_wait_time_seconds         != null ? var.sqs_defaults.receive_wait_time_seconds         : 0
    policy                            = var.sqs_defaults.policy
    max_receive_count                 = var.sqs_defaults.max_receive_count                 != null ? var.sqs_defaults.max_receive_count                 : 0
    dlq_suffix                        = var.sqs_defaults.dlq_suffix                        != null ? var.sqs_defaults.dlq_suffix                        : "_dead_letters"
    fifo_queue                        = var.sqs_defaults.fifo_queue                        != null ? var.sqs_defaults.fifo_queue                        : false
    content_based_deduplication       = var.sqs_defaults.content_based_deduplication       != null ? var.sqs_defaults.content_based_deduplication       : false
    server_side_encryption            = var.sqs_defaults.server_side_encryption            != null ? var.sqs_defaults.server_side_encryption            : false
    create_kms_key                    = var.sqs_defaults.create_kms_key                    != null ? var.sqs_defaults.create_kms_key                    : false
    kms_master_key_id                 = var.sqs_defaults.kms_master_key_id
    kms_data_key_reuse_period_seconds = var.sqs_defaults.kms_data_key_reuse_period_seconds != null ? var.sqs_defaults.kms_data_key_reuse_period_seconds : 300
    deduplication_scope               = var.sqs_defaults.deduplication_scope               != null ? var.sqs_defaults.deduplication_scope               : "queue"
    fifo_throughput_limit             = var.sqs_defaults.fifo_throughput_limit             != null ? var.sqs_defaults.fifo_throughput_limit             : "perQueue"
    tags                              = (
      var.sqs_defaults.tags != null ?
      merge(
        var.tags,
        var.sqs_defaults.tags
      ) :
      var.tags
    )
  }

  sqs = {for name, config in var.sqs:
    name => {
      visibility_timeout_seconds        = config.visibility_timeout_seconds        != null ? config.visibility_timeout_seconds        : local.sqs_defaults.visibility_timeout_seconds
      message_retention_seconds         = config.message_retention_seconds         != null ? config.message_retention_seconds         : local.sqs_defaults.message_retention_seconds
      max_message_size                  = config.max_message_size                  != null ? config.max_message_size                  : local.sqs_defaults.max_message_size
      delay_seconds                     = config.delay_seconds                     != null ? config.delay_seconds                     : local.sqs_defaults.delay_seconds
      receive_wait_time_seconds         = config.receive_wait_time_seconds         != null ? config.receive_wait_time_seconds         : local.sqs_defaults.receive_wait_time_seconds
      policy                            = config.policy                            != null ? config.policy                            : local.sqs_defaults.policy
      max_receive_count                 = config.max_receive_count                 != null ? config.max_receive_count                 : local.sqs_defaults.max_receive_count
      dlq_suffix                        = config.dlq_suffix                        != null ? config.dlq_suffix                        : local.sqs_defaults.dlq_suffix
      fifo_queue                        = config.fifo_queue                        != null ? config.fifo_queue                        : local.sqs_defaults.fifo_queue
      content_based_deduplication       = config.content_based_deduplication       != null ? config.content_based_deduplication       : local.sqs_defaults.content_based_deduplication
      server_side_encryption            = config.server_side_encryption            != null ? config.server_side_encryption            : local.sqs_defaults.server_side_encryption
      create_kms_key                    = config.create_kms_key                    != null ? config.create_kms_key                    : local.sqs_defaults.create_kms_key
      kms_master_key_id                 = config.kms_master_key_id                 != null ? config.kms_master_key_id                 : local.sqs_defaults.kms_master_key_id
      kms_data_key_reuse_period_seconds = config.kms_data_key_reuse_period_seconds != null ? config.kms_data_key_reuse_period_seconds : local.sqs_defaults.kms_data_key_reuse_period_seconds
      deduplication_scope               = config.deduplication_scope               != null ? config.deduplication_scope               : local.sqs_defaults.deduplication_scope
      fifo_throughput_limit             = config.fifo_throughput_limit             != null ? config.fifo_throughput_limit             : local.sqs_defaults.fifo_throughput_limit
      tags                              = (
        config.tags != null ?
        merge(
          local.sqs_defaults.tags,
          config.tags
        ) :
        local.sqs_defaults.tags
      )
    }
  }
}
