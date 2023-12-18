resource "aws_sqs_queue" "this" {
  for_each = local.sqs

  name                        = "${var.name}_${each.key}"
  visibility_timeout_seconds  = each.value.visibility_timeout_seconds
  message_retention_seconds   = each.value.message_retention_seconds
  max_message_size            = each.value.max_message_size
  delay_seconds               = each.value.delay_seconds
  receive_wait_time_seconds   = each.value.receive_wait_time_seconds
  policy                      = each.value.policy
  redrive_policy              = (
    each.value.max_receive_count > 0 ?
    jsonencode({
      deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
      maxReceiveCount     = each.value.max_receive_count
    }) :
    null
  )
  fifo_queue                  = each.value.fifo_queue
  content_based_deduplication = each.value.content_based_deduplication
  kms_master_key_id           = each.value.create_kms_key && each.value.server_side_encryption ? aws_kms_key.this[each.key].id     : each.value.kms_master_key_id
  deduplication_scope         = each.value.fifo_queue ? each.value.deduplication_scope   : null
  fifo_throughput_limit       = each.value.fifo_queue ? each.value.fifo_throughput_limit : null
  tags                        = merge(
    each.value.tags,
    {
      Name = "${var.name}_${each.key}"
    }
  )
}

resource "aws_sqs_queue" "dlq" {
  for_each = {
    for queue, config in local.sqs:
      queue => config
    if config.max_receive_count > 0
  }

  name                        = "${var.name}_${each.key}${each.value.dlq_suffix}"
  visibility_timeout_seconds  = each.value.visibility_timeout_seconds
  message_retention_seconds   = each.value.message_retention_seconds
  max_message_size            = each.value.max_message_size
  delay_seconds               = each.value.delay_seconds
  receive_wait_time_seconds   = each.value.receive_wait_time_seconds
  policy                      = each.value.policy
  fifo_queue                  = each.value.fifo_queue
  content_based_deduplication = each.value.content_based_deduplication
  kms_master_key_id           = each.value.create_kms_key && each.value.server_side_encryption ? aws_kms_key.this[each.key].id     : each.value.kms_master_key_id
  deduplication_scope         = each.value.fifo_queue ? each.value.deduplication_scope   : null
  fifo_throughput_limit       = each.value.fifo_queue ? each.value.fifo_throughput_limit : null
  tags                        = merge(
    each.value.tags,
    {
      Name = "${var.name}_${each.key}${each.value.dlq_suffix}"
    }
  )
}

resource "aws_kms_key" "this" {
  for_each = {
    for queue, config in local.sqs:
      queue => config
    if config.create_kms_key && config.server_side_encryption
  }

  description = "Encryption key for ${each.key} SQS queue"
  tags        = merge(
    each.value.tags,
    {
      Name = "${var.name}_${each.key}_sqs"
    }
  )
}
