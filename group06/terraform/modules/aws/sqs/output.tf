output "name" {
  value = var.name
}

output "vpc" {
  value = var.vpc
}

output "tags" {
  value = var.tags
}

output "sqs" {
  value = aws_sqs_queue.this
}

output "sqs_dlq" {
  value = aws_sqs_queue.dlq
}

output "kms" {
  value = aws_kms_key.this
}
